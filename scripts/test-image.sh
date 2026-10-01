#!/usr/bin/env bash
set -euo pipefail

# Usage: test-image.sh <image> [expected-php-version]
#
# Runs a published or locally built image and checks the things a user would notice
# first: it starts, it runs as an unprivileged user, PHP reports the expected version,
# the default extensions load, and images that ship a web server serve a PHP file
# through it. Works against any image reference.
# Commands go through the image's own entrypoint so every entrypoint.d script runs.
# The entrypoint prints a welcome banner first, so a command's own output is the last line.

image="${1:?Usage: test-image.sh <image> [expected-php-version]}"
expected_php="${2:-}"
health_timeout_seconds=90
http_timeout_seconds=30

# Every variation installs these (DEPENDENCY_PHP_EXTENSIONS in src/variations/*/Dockerfile).
expected_extensions="opcache pcntl pdo_mysql pdo_pgsql redis zip"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1" >&2; exit 1; }
image_env() { docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$image" | sed -n "s/^$1=//p"; }

echo "🔎 Testing $image"

php_version=$(docker run --rm "$image" php -r 'echo PHP_VERSION;' | tail -n1)
if [ -n "$expected_php" ] && [ "$php_version" != "$expected_php" ]; then
    fail "PHP reports $php_version, expected $expected_php"
fi
pass "PHP $php_version"

uid=$(docker run --rm "$image" id -u | tail -n1)
[ "$uid" != "0" ] || fail "Container runs as root by default"
pass "Runs as unprivileged user (uid $uid)"

loaded_extensions=$(docker run --rm "$image" php -r 'echo implode(" ", array_map("strtolower", get_loaded_extensions()));' | tail -n1)
missing_extensions=""
for extension in $expected_extensions; do
    case " $loaded_extensions " in
        *" $extension "*) ;;
        *"zend $extension "*) ;;
        *) missing_extensions="$missing_extensions $extension" ;;
    esac
done
[ -z "$missing_extensions" ] || fail "PHP extensions not loaded:$missing_extensions"
pass "Extensions loaded: $expected_extensions"

# PHP_* environment variables reach php.ini through ${VAR} substitution. Override a few
# of the different value types (size, boolean, list) and confirm PHP sees them.
# OPcache is enabled so the CLI SAPI also allocates the shared cache with the tuned defaults.
ini_values=$(docker run --rm \
    --env PHP_MEMORY_LIMIT=512M \
    --env PHP_REALPATH_CACHE_SIZE=8M \
    --env PHP_SESSION_COOKIE_HTTPONLY=0 \
    --env PHP_DISABLE_FUNCTIONS=shell_exec \
    --env PHP_OPCACHE_ENABLE=1 \
    --env PHP_OPCACHE_FORCE_RESTART_TIMEOUT=60 \
    "$image" php -r 'echo ini_get("memory_limit"), " ", ini_get("realpath_cache_size"), " ", ini_get("session.cookie_httponly"), " ", ini_get("disable_functions"), " ", ini_get("opcache.force_restart_timeout");' | tail -n1)
[ "$ini_values" = "512M 8M 0 shell_exec 60" ] || fail "PHP_* environment variables did not apply to php.ini. Got: $ini_values"
pass "Environment variables apply to php.ini"

# PHP_OPCACHE_ENABLE_CLI turns OPcache off for the CLI SAPI while opcache.enable stays on for the web server.
cli_opcache=$(docker run --rm --env PHP_OPCACHE_ENABLE=1 --env PHP_OPCACHE_ENABLE_CLI=0 \
    "$image" php -r 'echo function_exists("opcache_get_status") && opcache_get_status(false) !== false ? "on" : "off";' | tail -n1)
[ "$cli_opcache" = "off" ] || fail "PHP_OPCACHE_ENABLE_CLI=0 did not disable OPcache for the CLI. Got: $cli_opcache"
pass "PHP_OPCACHE_ENABLE_CLI disables the CLI cache"

has_healthcheck=$(docker image inspect --format '{{if .Config.Healthcheck}}yes{{end}}' "$image")
if [ -z "$has_healthcheck" ]; then
    pass "No HEALTHCHECK defined, skipping startup check"
    exit 0
fi

# Web images expose their HTTP port and document root as environment variables.
http_port=""
web_root=""
for pair in NGINX_HTTP_PORT:NGINX_WEBROOT APACHE_HTTP_PORT:APACHE_DOCUMENT_ROOT CADDY_HTTP_PORT:CADDY_SERVER_ROOT; do
    port=$(image_env "${pair%%:*}")
    if [ -n "$port" ]; then
        http_port="$port"
        web_root=$(image_env "${pair##*:}")
        web_root="${web_root:-/var/www/html/public}"
        break
    fi
done

# Web images run with OPcache enabled so the health check and the served page
# cover the FPM and FrankenPHP SAPIs starting with the tuned defaults.
run_args=(--detach --rm --env PHP_OPCACHE_ENABLE=1)
if [ -n "$http_port" ]; then
    # The container runs unprivileged, so the mounted document root must be world readable.
    web_dir=$(mktemp -d)
    chmod 755 "$web_dir"
    echo '<?php echo "serversideup-php-ok:" . PHP_VERSION;' > "$web_dir/index.php"
    chmod 644 "$web_dir/index.php"
    mkdir -p "$web_dir/storage"
    chmod 755 "$web_dir/storage"
    echo '<?php echo "storage-php-executed";' > "$web_dir/storage/uploaded.php"
    chmod 644 "$web_dir/storage/uploaded.php"
    run_args+=(--publish "127.0.0.1::${http_port}" --volume "$web_dir:$web_root:ro")
fi

containers=()
cleanup() {
    for container in "${containers[@]}"; do
        docker rm --force "$container" >/dev/null 2>&1 || true
    done
    [ -z "${web_dir:-}" ] || rm -rf "$web_dir"
}
trap cleanup EXIT

dump_container_state() {
    echo "--- container logs ---" >&2
    docker logs "$1" >&2 2>&1 || true
    echo "--- last health check ---" >&2
    docker inspect --format '{{range .State.Health.Log}}{{.Output}}{{end}}' "$1" 2>/dev/null | tail -5 >&2 || true
}

start_container() {
    container=$(docker run "${run_args[@]}" "$@" "$image")
    containers+=("$container")

    status=starting
    for _ in $(seq 1 "$health_timeout_seconds"); do
        status=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "gone")
        case "$status" in
            healthy) break ;;
            unhealthy|gone) break ;;
        esac
        sleep 1
    done

    if [ "$status" != "healthy" ]; then
        dump_container_state "$container"
        fail "Container did not become healthy within ${health_timeout_seconds}s (status: $status)"
    fi
    [ -z "$http_port" ] || host_port=$(docker port "$container" "$http_port" | head -n1 | sed 's/.*://')
}

# Retries until the response body matches, since the web server may still be warming up.
expect_body() {
    path="$1"
    expected="$2"
    body=""
    for _ in $(seq 1 "$http_timeout_seconds"); do
        body=$(curl --silent --show-error --max-time 5 "http://127.0.0.1:${host_port}${path}" 2>/dev/null || true)
        [ "$body" = "$expected" ] && return 0
        sleep 1
    done
    dump_container_state "$container"
    fail "Web server did not serve ${path} on port ${http_port}. Response: ${body:-<empty>}"
}

# Uploaded PHP files under /storage must never run, including through PATH_INFO
# (/storage/file.php/anything), which Apache and FrankenPHP would otherwise execute.
expect_storage_blocked() {
    for path in /storage/uploaded.php /storage/uploaded.php/anything; do
        response=$(curl --silent --max-time 5 --output /dev/null --write-out '%{http_code}' "http://127.0.0.1:${host_port}${path}" || true)
        [ "$response" = "403" ] || fail "Expected ${path} to return 403, got ${response:-<empty>}"
    done
}

# Mercure subscribers pass their JWT as ?authorization=, which must never reach the access log.
# Retries because the log line lands a moment after the response.
expect_authorization_redacted() {
    curl --silent --max-time 5 --output /dev/null "http://127.0.0.1:${host_port}/?authorization=octane-secret" || true
    for _ in $(seq 1 "$http_timeout_seconds"); do
        logs=$(docker logs "$container" 2>&1)
        case "$logs" in
            *"octane-secret"*) fail "Access log contains the authorization query parameter" ;;
            *"authorization=REDACTED"*) return 0 ;;
        esac
        sleep 1
    done
    dump_container_state "$container"
    fail "Access log does not redact the authorization query parameter"
}

# A detached container has no terminal, so Caddy's default format is json and its default
# stream is stderr. Octane depends on both: it only relays stderr and only parses JSON.
expect_json_logs_on_stderr() {
    stdout_logs=$(docker logs "$container" 2>/dev/null)
    stderr_logs=$(docker logs "$container" 2>&1 >/dev/null)
    case "$stderr_logs" in
        *'"msg":"handled request"'*) ;;
        *) dump_container_state "$container"; fail "Access log is not JSON on stderr" ;;
    esac
    case "$stdout_logs" in
        *"handled request"*) fail "Access log was written to stdout, which Octane discards" ;;
    esac
}

start_container
pass "Container became healthy"

[ -n "$http_port" ] || exit 0

expect_body / "serversideup-php-ok:${php_version}"
pass "Web server serves PHP on port ${http_port}"

expect_storage_blocked
pass "Web server blocks PHP execution under /storage"

# The rest applies to FrankenPHP only: Caddy's log defaults and Laravel Octane.
[ -n "$(image_env CADDY_HTTP_PORT)" ] || exit 0

expect_authorization_redacted
expect_json_logs_on_stderr
pass "Web server writes JSON logs to stderr and redacts the authorization query parameter"

# Octane starts FrankenPHP with LARAVEL_OCTANE=1 and the variables from
# src/Commands/StartFrankenPhpCommand.php in laravel/octane, which must switch
# /etc/frankenphp/Caddyfile to the Octane worker without losing the rest of the configuration.
cat > "$web_dir/frankenphp-worker.php" <<'PHP'
<?php
$handler = static function () {
    echo "octane-worker-ok:" . PHP_VERSION;
};
while (frankenphp_handle_request($handler)) {
}
PHP
chmod 644 "$web_dir/frankenphp-worker.php"

# A custom CADDY_SERVER_ROOT must move the worker script along with the document root.
octane_root=/var/www/octane/public
start_container \
    --env LARAVEL_OCTANE=1 \
    --env "CADDY_SERVER_ROOT=$octane_root" \
    --volume "$web_dir:$octane_root:ro" \
    --env CADDY_SERVER_ADMIN_HOST=localhost \
    --env CADDY_SERVER_ADMIN_PORT=2099 \
    --env "CADDY_SERVER_WORKER_DIRECTIVE=num 2" \
    --env "CADDY_SERVER_WATCH_DIRECTIVES=watch $octane_root" \
    --env "CADDY_GLOBAL_OPTIONS=auto_https disable_redirects" \
    --env CADDY_SERVER_EXTRA_DIRECTIVES=
pass "Container became healthy in Laravel Octane mode"

expect_body / "octane-worker-ok:${php_version}"
expect_body /some/route "octane-worker-ok:${php_version}"
pass "Octane mode routes requests to frankenphp-worker.php"

expect_storage_blocked
pass "Octane mode blocks PHP execution under /storage"

# octane:status, octane:reload, and octane:stop use the Caddy admin API on Octane's port.
admin_response=$(docker exec "$container" curl --silent --max-time 5 --output /dev/null --write-out '%{http_code}' http://localhost:2099/config/apps/frankenphp || true)
[ "$admin_response" = "200" ] || fail "Caddy admin API is not reachable on Octane's admin port, got ${admin_response:-<empty>}"
pass "Octane mode exposes the Caddy admin API on Octane's admin port"

expect_authorization_redacted
expect_json_logs_on_stderr
pass "Octane mode writes JSON logs to stderr and redacts the authorization query parameter"

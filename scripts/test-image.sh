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
ini_values=$(docker run --rm \
    --env PHP_MEMORY_LIMIT=512M \
    --env PHP_REALPATH_CACHE_SIZE=8M \
    --env PHP_SESSION_COOKIE_HTTPONLY=0 \
    --env PHP_DISABLE_FUNCTIONS=shell_exec \
    "$image" php -r 'echo ini_get("memory_limit"), " ", ini_get("realpath_cache_size"), " ", ini_get("session.cookie_httponly"), " ", ini_get("disable_functions");' | tail -n1)
[ "$ini_values" = "512M 8M 0 shell_exec" ] || fail "PHP_* environment variables did not apply to php.ini. Got: $ini_values"
pass "Environment variables apply to php.ini"

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

run_args=(--detach --rm)
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

container=$(docker run "${run_args[@]}" "$image")
cleanup() {
    docker rm --force "$container" >/dev/null 2>&1 || true
    [ -z "${web_dir:-}" ] || rm -rf "$web_dir"
}
trap cleanup EXIT

dump_container_state() {
    echo "--- container logs ---" >&2
    docker logs "$container" >&2 2>&1 || true
    echo "--- last health check ---" >&2
    docker inspect --format '{{range .State.Health.Log}}{{.Output}}{{end}}' "$container" 2>/dev/null | tail -5 >&2 || true
}

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
    dump_container_state
    fail "Container did not become healthy within ${health_timeout_seconds}s (status: $status)"
fi
pass "Container became healthy"

[ -n "$http_port" ] || exit 0

host_port=$(docker port "$container" "$http_port" | head -n1 | sed 's/.*://')
body=""
for _ in $(seq 1 "$http_timeout_seconds"); do
    body=$(curl --silent --show-error --max-time 5 "http://127.0.0.1:${host_port}/" 2>/dev/null || true)
    [ "$body" = "serversideup-php-ok:${php_version}" ] && break
    sleep 1
done

if [ "$body" != "serversideup-php-ok:${php_version}" ]; then
    dump_container_state
    fail "Web server did not serve index.php on port ${http_port}. Response: ${body:-<empty>}"
fi
pass "Web server serves PHP on port ${http_port}"

# Uploaded PHP files under /storage must never run, including through PATH_INFO
# (/storage/file.php/anything), which Apache and FrankenPHP would otherwise execute.
for path in /storage/uploaded.php /storage/uploaded.php/anything; do
    response=$(curl --silent --max-time 5 --output /dev/null --write-out '%{http_code}' "http://127.0.0.1:${host_port}${path}" || true)
    [ "$response" = "403" ] || fail "Expected ${path} to return 403, got ${response:-<empty>}"
done
pass "Web server blocks PHP execution under /storage"

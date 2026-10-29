# shellcheck shell=bash
#
# Helpers shared by every test file in this directory. scripts/test-image.sh sources
# this file and sets the image facts (php_version, http_port, https_port, web_root, ...).
# Commands go through the image's own entrypoint so every entrypoint.d script runs.
# The entrypoint prints a welcome banner first, so a command's own output is the last line.

health_timeout_seconds=90
http_timeout_seconds=30

fail() { echo "$1" >&2; exit 1; }
image_env() { docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$image" | sed -n "s/^$1=//p"; }

# Usage: run_php <code> [docker run options]
run_php() {
    local code="$1"
    shift
    docker run --rm "$@" "$image" php -r "$code" | tail -n1
}

# Skips the rest of the test file when the image lacks one of the named features.
requires() {
    local feature missing
    for feature in "$@"; do
        case "$feature" in
            healthcheck) [ -n "$has_healthcheck" ] || missing="no HEALTHCHECK" ;;
            web_server) [ -n "$http_port" ] || missing="no web server" ;;
            https) [ -n "$https_port" ] || missing="no HTTPS port" ;;
            frankenphp) [ -n "$is_frankenphp" ] || missing="not FrankenPHP" ;;
            *) fail "Unknown requirement: $feature" ;;
        esac
        if [ -n "${missing:-}" ]; then
            echo "⏭️  skipped: $missing"
            exit 0
        fi
    done
}

dump_container_state() {
    echo "--- container logs ---" >&2
    docker logs "$1" >&2 2>&1 || true
    echo "--- last health check ---" >&2
    docker inspect --format '{{range .State.Health.Log}}{{.Output}}{{end}}' "$1" 2>/dev/null | tail -5 >&2 || true
}

# Starts the image in the background and waits for its HEALTHCHECK. Web images get the
# fixtures mounted as their document root and their ports published on random host ports.
# Web images run with OPcache enabled so the health check and the served page
# cover the FPM and FrankenPHP SAPIs starting with the tuned defaults.
# Sets container, host_port, and https_host_port.
start_container() {
    local args=(--detach --label "$test_label" --env PHP_OPCACHE_ENABLE=1) status=starting
    if [ -n "$http_port" ]; then
        args+=(--publish "127.0.0.1::${http_port}" --volume "$web_dir:$web_root:ro")
        [ -z "$https_port" ] || args+=(--publish "127.0.0.1::${https_port}")
    fi
    container=$(docker run "${args[@]}" "$@" "$image")

    for _ in $(seq 1 "$health_timeout_seconds"); do
        status=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "gone")
        case "$status" in
            healthy|unhealthy|gone) break ;;
        esac
        sleep 1
    done

    if [ "$status" != "healthy" ]; then
        dump_container_state "$container"
        fail "Container did not become healthy within ${health_timeout_seconds}s (status: $status)"
    fi
    [ -z "$http_port" ] || host_port=$(docker port "$container" "$http_port" | head -n1 | sed 's/.*://')
    [ -z "$https_port" ] || https_host_port=$(docker port "$container" "$https_port" | head -n1 | sed 's/.*://')
}

# Retries until the response body matches, since the web server may still be warming up.
expect_body() {
    local path="$1" expected="$2" body=""
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
    local path response
    for path in /storage/uploaded.php /storage/uploaded.php/anything; do
        response=$(curl --silent --max-time 5 --output /dev/null --write-out '%{http_code}' "http://127.0.0.1:${host_port}${path}" || true)
        [ "$response" = "403" ] || fail "Expected ${path} to return 403, got ${response:-<empty>}"
    done
}

# Mercure subscribers pass their JWT as ?authorization=, which must never reach the access log.
# Retries because the log line lands a moment after the response.
expect_authorization_redacted() {
    local logs
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
# Run it after a request has been logged.
expect_json_logs_on_stderr() {
    local stdout_logs stderr_logs
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

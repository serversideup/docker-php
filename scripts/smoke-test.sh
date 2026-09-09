#!/usr/bin/env bash
set -euo pipefail

# Usage: smoke-test.sh <image> [expected-php-version]
#
# Runs a published or locally built image and checks the things a user would notice
# first: it starts, it runs as an unprivileged user, PHP reports the expected version,
# and images with a HEALTHCHECK become healthy. Works against any image reference.

image="${1:?Usage: smoke-test.sh <image> [expected-php-version]}"
expected_php="${2:-}"
health_timeout_seconds=90

pass() { echo "✅ $1"; }
fail() { echo "❌ $1" >&2; exit 1; }

echo "🔎 Smoke testing $image"

php_version=$(docker run --rm --entrypoint php "$image" -r 'echo PHP_VERSION;')
if [ -n "$expected_php" ] && [ "$php_version" != "$expected_php" ]; then
    fail "PHP reports $php_version, expected $expected_php"
fi
pass "PHP $php_version"

uid=$(docker run --rm --entrypoint id "$image" -u)
[ "$uid" != "0" ] || fail "Container runs as root by default"
pass "Runs as unprivileged user (uid $uid)"

has_healthcheck=$(docker image inspect --format '{{if .Config.Healthcheck}}yes{{end}}' "$image")
if [ -z "$has_healthcheck" ]; then
    pass "No HEALTHCHECK defined, skipping startup check"
    exit 0
fi

container=$(docker run --detach --rm "$image")
cleanup() { docker rm --force "$container" >/dev/null 2>&1 || true; }
trap cleanup EXIT

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
    echo "--- container logs ---" >&2
    docker logs "$container" >&2 2>&1 || true
    echo "--- last health check ---" >&2
    docker inspect --format '{{range .State.Health.Log}}{{.Output}}{{end}}' "$container" 2>/dev/null | tail -5 >&2 || true
    fail "Container did not become healthy within ${health_timeout_seconds}s (status: $status)"
fi
pass "Container became healthy"

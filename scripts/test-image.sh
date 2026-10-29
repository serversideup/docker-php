#!/usr/bin/env bash
# shellcheck disable=SC2034 # the image facts are read by the files in scripts/tests/image/
set -euo pipefail

# Usage: test-image.sh <image> [expected-php-version]
#
# Runs a published or locally built image through the tests in scripts/tests/image/,
# one file per feature area. A file skips itself when the image lacks its feature,
# so the same tests run against every variation. Every test runs even after one
# fails, and the script exits non-zero if any did.
#
# Set TEST_ONLY to a file name without .sh (for example web-server) to run one area.

image="${1:?Usage: test-image.sh <image> [expected-php-version]}"
expected_php="${2:-}"
tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/tests/image" && pwd)"

# shellcheck source=tests/image/lib.sh
source "$tests_dir/lib.sh"

test_label="serversideup-php-test=$$"
work_dir=$(mktemp -d)
cleanup() {
    local containers
    containers=$(docker ps --all --quiet --filter "label=$test_label")
    # shellcheck disable=SC2086 # one container ID per word
    [ -z "$containers" ] || docker rm --force $containers >/dev/null 2>&1 || true
    rm -rf "$work_dir"
}
trap cleanup EXIT

# The container runs unprivileged, so the mounted document root must be world readable.
web_dir="$work_dir/public"
cp -R "$tests_dir/fixtures/public" "$web_dir"
chmod -R u=rwX,go=rX "$web_dir"

php_version=$(run_php 'echo PHP_VERSION;')
has_healthcheck=$(docker image inspect --format '{{if .Config.Healthcheck}}yes{{end}}' "$image")
is_frankenphp=$(image_env CADDY_HTTP_PORT)

# Web images expose their HTTP port and document root as environment variables, and
# serve TLS on their HTTPS port once SSL_MODE is on.
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
https_port=""
for variable in NGINX_HTTPS_PORT APACHE_HTTPS_PORT CADDY_HTTPS_PORT; do
    https_port=$(image_env "$variable")
    [ -z "$https_port" ] || break
done

failures_file="$work_dir/failures"
touch "$failures_file"

report() {
    local name="$1" status="$2" output="$3"
    if [ "$status" -eq 0 ]; then
        echo "✅ $name"
        return
    fi
    echo "❌ $name"
    sed 's/^/   /' "$output"
    echo "$area: $name" >> "$failures_file"
}

# Runs in its own subshell so one file's containers and variables never reach the next.
# setup() runs in the file's shell so the tests can use the container it starts; an EXIT
# trap reports it when it fails. Each test runs in a subshell with errexit on, so a failed
# command ends that test only.
run_test_file() {
    local file="$1" output="$work_dir/output" test_function status
    # shellcheck source=/dev/null
    source "$file"
    if declare -F setup >/dev/null; then
        exec 3>&1
        trap 'report setup 1 "$output" >&3' EXIT
        setup >"$output" 2>&1
        trap - EXIT
    fi
    for test_function in $(grep -o '^test_[a-z0-9_]*' "$file"); do
        set +e
        ( set -e; "$test_function" ) >"$output" 2>&1
        status=$?
        set -e
        report "$(echo "${test_function#test_}" | tr _ ' ')" "$status" "$output"
    done
}

echo "🔎 Testing $image (PHP $php_version)"
for file in "$tests_dir"/*.sh; do
    area=$(basename "$file" .sh)
    [ "$area" != lib ] || continue
    [ -z "${TEST_ONLY:-}" ] || [ "$area" = "$TEST_ONLY" ] || continue
    echo
    echo "$area"
    set +e
    ( set -e; run_test_file "$file" )
    set -e
done

echo
if [ -s "$failures_file" ]; then
    echo "$(wc -l < "$failures_file" | tr -d ' ') test(s) failed:" >&2
    sed 's/^/  /' "$failures_file" >&2
    exit 1
fi
echo "All tests passed"

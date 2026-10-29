#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154 # variables are shared with scripts/tests/image/lib.sh and the test files
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
    local containers images
    containers=$(docker ps --all --quiet --filter "label=$test_label")
    images=$(docker images --quiet --filter "label=$test_label" | sort -u)
    # shellcheck disable=SC2086 # one ID per word
    [ -z "$containers" ] || docker rm --force $containers >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    [ -z "$images" ] || docker rmi --force $images >/dev/null 2>&1 || true
    rm -rf "$work_dir"
}
trap cleanup EXIT

# The container runs unprivileged, so mounted fixtures must be world readable.
fixtures_dir="$work_dir/fixtures"
cp -R "$tests_dir/fixtures" "$fixtures_dir"
chmod -R u=rwX,go=rX "$fixtures_dir"
web_dir="$fixtures_dir/public"

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

output="$work_dir/output"

report() {
    local name="$1" status="$2"
    case "$status" in
        0) echo "✅ $name" ;;
        "$skip_status") echo "⏭️  $name, $(tail -n1 "$output")" ;;
        *)
            echo "❌ $name"
            sed 's/^/   /' "$output"
            echo "$area: $name" >> "$failures_file"
            ;;
    esac
}

# A file stops early when requires skips it or setup fails.
report_file_stopped() {
    if [ "$1" -eq "$skip_status" ]; then
        echo "⏭️  $(tail -n1 "$output")"
    else
        report setup "$1"
    fi
}

# Runs in its own subshell so one file's containers and variables never reach the next.
# The file and its setup() run in that shell so the tests can use the container setup
# starts; an EXIT trap reports them when they stop it. Each test runs in a subshell with
# errexit on, so a failed command ends that test only.
run_test_file() {
    local file="$1" test_function status
    exec 3>&1
    trap 'report_file_stopped $? >&3' EXIT
    # shellcheck source=/dev/null
    source "$file" >"$output" 2>&1
    if declare -F setup >/dev/null; then
        setup >"$output" 2>&1
    fi
    trap - EXIT
    for test_function in $(grep -o '^test_[a-z0-9_]*' "$file"); do
        set +e
        ( set -e; "$test_function" ) >"$output" 2>&1
        status=$?
        set -e
        report "$(echo "${test_function#test_}" | tr _ ' ')" "$status"
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

#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/tests/run.sh
#
# Checks the CI helper scripts against a small set of images. CI runs this in the
# lint group on a real runner, so a jq or yq difference between a laptop and the
# runner fails here instead of in a published run.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

assert_contains() {
    local haystack="$1" needle="$2" message="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✅ $message"
    else
        echo "❌ $message"
        echo "   expected to find: $needle"
        failures=$((failures + 1))
    fi
}

# One JSON file per image, the way the build jobs upload them.
image_details=$(mktemp -d)
trap 'rm -rf "$image_details"' EXIT
image() { echo "$1" > "$image_details/$2.json"; }
image '{"variation":"cli","php":"8.5.10","os":"trixie","tags":["docker.io/serversideup/php-dev:700-8.5.10-cli-trixie"],"saved":"registry.depot.dev/proj:1-x","published":false,"sizes":{}}' newest-debian
image '{"variation":"cli","php":"8.5.10","os":"trixie","tags":["docker.io/serversideup/php-dev:700-8.5.10-cli-trixie"],"saved":"registry.depot.dev/proj:1-x","published":true,"sizes":{"linux/amd64":195090095,"linux/arm64":187352117}}' newest-debian.published
image '{"variation":"cli","php":"8.5.10","os":"alpine3.24","tags":["docker.io/serversideup/php-dev:700-8.5.10-cli-alpine3.24"],"saved":"registry.depot.dev/proj:1-x","published":true,"sizes":{"linux/amd64":50000000,"linux/arm64":49900000}}' newest-alpine
image '{"variation":"cli","php":"8.5.10","os":"alpine3.23","tags":["docker.io/serversideup/php-dev:700-8.5.10-cli-alpine3.23"],"saved":"registry.depot.dev/proj:1-x","published":true,"sizes":{"linux/amd64":49900000,"linux/arm64":49800000}}' older-alpine
image '{"variation":"cli","php":"8.4.25","os":"trixie","tags":["docker.io/serversideup/php-dev:700-8.4.25-cli-trixie"],"saved":"registry.depot.dev/proj:1-x","published":true,"sizes":{"linux/amd64":191100000,"linux/arm64":183700000}}' older-php
image '{"variation":"fpm-nginx","php":"8.5.10","os":"trixie","tags":["docker.io/serversideup/php-dev:700-8.5.10-fpm-nginx-trixie"],"saved":"registry.depot.dev/proj:1-x","published":true,"sizes":{"linux/amd64":230000000,"linux/arm64":187352117}}' other-variation
image '{"variation":"frankenphp","php":"8.5.10","os":"bookworm","tags":["docker.io/serversideup/php-dev:700-8.5.10-frankenphp-bookworm"],"saved":null,"published":false,"sizes":{}}' not-published

# What setup planned, including one image that never reported back.
matrix='{"cli":{"include":[
  {"php_variation":"cli","patch_version":"8.5.10","base_os":"trixie"},
  {"php_variation":"cli","patch_version":"8.5.10","base_os":"alpine3.24"},
  {"php_variation":"cli","patch_version":"8.5.10","base_os":"alpine3.23"},
  {"php_variation":"cli","patch_version":"8.4.25","base_os":"trixie"},
  {"php_variation":"cli","patch_version":"8.4.25","base_os":"bookworm"}]},
 "fpm-nginx":{"include":[{"php_variation":"fpm-nginx","patch_version":"8.5.10","base_os":"trixie"}]},
 "frankenphp":{"include":[{"php_variation":"frankenphp","patch_version":"8.5.10","base_os":"bookworm"}]}}'

echo "jq $(jq --version)"
echo
echo "build-summary.sh"
summary=$(bash "$scripts_dir/build-summary.sh" "$image_details" "$matrix")
assert_contains "$summary" "## Images: 6 of 7 built" "counts built images against the planned matrix"
assert_contains "$summary" "| 195.1 MB | 187.4 MB |" "formats compressed sizes in MB with one decimal"
assert_contains "$summary" "| cli | 8.5.10 | trixie | 195.1 MB | 187.4 MB | \`serversideup/php-dev:700-8.5.10-cli-trixie\` |" "prefers the published record when the build record also exists"
assert_contains "$summary" "| 50.0 MB | 49.9 MB |" "keeps a trailing zero so columns line up"
assert_contains "$summary" "| cli | 8.4.25 | bookworm |  |  | ❌ not built |" "lists images that never reported back"
assert_contains "$summary" "| built, not published |" "marks images that were built but not promoted"
assert_contains "$summary" '`serversideup/php-dev:700-8.5.10-cli-trixie`' "shows the image reference without the registry prefix"

echo
echo "generate-matrix.sh"
versions_file="$image_details/php-versions.yml"
cat > "$versions_file" <<'YAML'
dependencies:
  DOCKER_LIBRARY_PHP_REF: master-sha
php_variations:
  - name: cli
    php_base: cli
  - name: fpm-nginx
    php_base: fpm
php_versions:
  - major: "8"
    minor_versions:
      - minor: "8.1"
        docker_library_ref: frozen-sha
        base_os:
          - name: bookworm
        patch_versions:
          - 8.1.34
      - minor: "8.4"
        base_os:
          - name: trixie
        patch_versions:
          - 8.4.27
      - minor: "8.6-rc"
        php_base_overrides:
          fpm-nginx: cli
        base_os:
          - name: trixie
        patch_versions:
          - 8.6-rc
YAML
matrix_json=$(bash "$scripts_dir/generate-matrix.sh" "$versions_file" | jq -c '.include[]')
assert_contains "$matrix_json" '"php_variation":"fpm-nginx","php_extension_overrides":"","php_base":"fpm","php_base_tag":"php-base-8.4.27-fpm-trixie","docker_library_ref":"master-sha"' "builds variations on their docker-library base from the global ref"
assert_contains "$matrix_json" '"php_base_tag":"php-base-8.1.34-cli-bookworm","docker_library_ref":"frozen-sha"' "uses a minor version's own docker-library ref"
assert_contains "$matrix_json" '"php_variation":"fpm-nginx","php_extension_overrides":"","php_base":"cli","php_base_tag":"php-base-8.6-rc-cli-trixie"' "lets a minor version swap a variation's docker-library base"

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed" >&2
    exit 1
fi
echo "All checks passed"

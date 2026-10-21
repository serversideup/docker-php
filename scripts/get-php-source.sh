#!/bin/bash
###################################################
# Usage: get-php-source.sh <version> [--config PATH]
###################################################
# Prints the build args src/base/Dockerfile needs to compile one PHP version, as JSON:
#
#   {"php_version": "8.4.27", "minor": "8.4", "url": "https://www.php.net/distributions/php-8.4.27.tar.xz",
#    "asc_url": "...tar.xz.asc", "sha256": "...", "gpg_keys": "AFD8... 9D7F... 0616..."}
#
# <version> is a minor (8.4) or an exact release (8.4.27). A minor resolves to the
# patch pinned in the base config if it has one (8.1), otherwise to the current
# release on https://www.php.net/releases/active.php. An exact release is looked up on
# https://www.php.net/releases/index.php. The GPG keys come from the minor's gpg_keys in
# the base config.
#
# Only php.net is consulted. If it does not list the version, this fails instead of
# falling back to an older patch.

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DOWNLOAD="$PROJECT_ROOT_DIR/src/common/usr/local/bin/docker-php-serversideup-download"
BASE_PHP_VERSIONS_CONFIG_FILE="${BASE_PHP_VERSIONS_CONFIG_FILE:-"$SCRIPT_DIR/conf/php-versions-base-config.yml"}"
PHP_NET="${PHP_NET:-https://www.php.net}"

fail() {
    echo "❌ $*" >&2
    exit 1
}

VERSION=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --config) BASE_PHP_VERSIONS_CONFIG_FILE="${2:?--config requires a path}"; shift 2 ;;
        -*) fail "Unknown option: $1" ;;
        *) VERSION="$1"; shift ;;
    esac
done

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || fail "Usage: $0 <version>, for example 8.4 or 8.4.27"
command -v jq > /dev/null || fail "jq is required"
command -v yq > /dev/null || fail "yq is required (https://github.com/mikefarah/yq)"

MINOR="$(echo "$VERSION" | cut -d. -f1,2)"

fetch_json() {
    local body
    body="$("$DOWNLOAD" "$1")" || fail "Could not fetch $1"
    jq -e . > /dev/null 2>&1 <<< "$body" || fail "$1 did not return JSON"
    echo "$body"
}

minor_config="$(MINOR="$MINOR" yq -o=json -I0 '.php_versions[].minor_versions[] | select(.minor == env(MINOR))' "$BASE_PHP_VERSIONS_CONFIG_FILE")"
[ -n "$minor_config" ] || fail "PHP $MINOR is not in $BASE_PHP_VERSIONS_CONFIG_FILE"
gpg_keys="$(jq -r '.gpg_keys // [] | join(" ")' <<< "$minor_config")"
[ -n "$gpg_keys" ] || fail "PHP $MINOR has no gpg_keys in $BASE_PHP_VERSIONS_CONFIG_FILE"

if [ "$VERSION" = "$MINOR" ]; then
    pinned="$(jq -r '.patch_versions // [] | .[0] // empty' <<< "$minor_config")"
else
    pinned="$VERSION"
fi

if [ -n "$pinned" ]; then
    release="$(fetch_json "$PHP_NET/releases/index.php?json&version=$pinned")"
    if jq -e '.error' > /dev/null <<< "$release"; then
        fail "php.net does not know PHP $pinned: $(jq -r '.error' <<< "$release")"
    fi
    release="$(jq -c --arg v "$pinned" '{version: $v, source}' <<< "$release")"
else
    release="$(fetch_json "$PHP_NET/releases/active.php" | jq -c --arg minor "$MINOR" '.[$minor | split(".")[0]][$minor] // empty')"
    [ -n "$release" ] || fail "php.net does not list PHP $MINOR as active. If it is end of life, pin its patch_versions in $BASE_PHP_VERSIONS_CONFIG_FILE."
fi

tarball="$(jq -c '[.source[]? | select(.filename | endswith(".tar.xz"))][0] // empty' <<< "$release")"
[ -n "$tarball" ] || fail "php.net lists no .tar.xz tarball for PHP $(jq -r '.version' <<< "$release")"
sha256="$(jq -r '.sha256 // empty' <<< "$tarball")"
[[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || fail "php.net lists no sha256 for $(jq -r '.filename' <<< "$tarball")"

url="$PHP_NET/distributions/$(jq -r '.filename' <<< "$tarball")"
jq -n -c \
    --arg php_version "$(jq -r '.version' <<< "$release")" \
    --arg minor "$MINOR" \
    --arg url "$url" \
    --arg sha256 "$sha256" \
    --arg gpg_keys "$gpg_keys" \
    '{php_version: $php_version, minor: $minor, url: $url, asc_url: ($url + ".asc"), sha256: $sha256, gpg_keys: $gpg_keys}'

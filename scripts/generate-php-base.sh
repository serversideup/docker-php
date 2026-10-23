#!/bin/bash
set -eo pipefail

###################################################
# Usage: generate-php-base.sh --version <version> --os <os> [--sapi <sapi>] [--output <dir>]
###################################################
# Renders the Dockerfiles for serversideup/php-base: PHP compiled from the php.net
# source tarball, as a drop-in for the official "php" image. It runs docker-library's
# own template and renderer (vendored unchanged in src/base/upstream), so the result
# matches the official image except for the patches in patch_dockerfile below.
#
# --version, --os, and --sapi can be repeated. A version is a minor (8.4, resolved to its
# latest release on php.net) or an exact release (8.4.27). --sapi defaults to cli, fpm,
# and zts. Each Dockerfile is rendered with its build context into
# <output>/<minor>/<os>/<sapi>, and one line per image is printed to stdout:
#
#     <php version> <sapi> <os> <build context dir>
#
# Requires bash, curl, jq, and gawk.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$PROJECT_ROOT_DIR/src/base"
OUTPUT_DIR="$PROJECT_ROOT_DIR/build/php-base"
VERSIONS=()
OPERATING_SYSTEMS=()
SAPIS=()

error() {
    echo "🛑 ERROR: $1" >&2
    exit 1
}

help_menu() {
    sed -n '4,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --version) VERSIONS+=("$2"); shift 2 ;;
        --os) OPERATING_SYSTEMS+=("$2"); shift 2 ;;
        --sapi) SAPIS+=("$2"); shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --help) help_menu; exit 0 ;;
        *) help_menu >&2; error "Unknown argument: $1" ;;
    esac
done

[ "${#VERSIONS[@]}" -gt 0 ] || error "Pass at least one --version."
[ "${#OPERATING_SYSTEMS[@]}" -gt 0 ] || error "Pass at least one --os."
[ "${#SAPIS[@]}" -gt 0 ] || SAPIS=(cli fpm zts)
for tool in curl jq gawk; do
    command -v "$tool" > /dev/null || error "$tool is required (on macOS: brew install $tool)."
done

# The minors upstream's template still supports are the ones it has signing keys for.
SUPPORTED_MINORS=$(sed -n '/^ENV GPG_KEYS/,/\[rcVersion\]/p' "$BASE_DIR/upstream/Dockerfile-linux.template" \
    | grep -oE '^\s*"[0-9]+\.[0-9]+": \[' | grep -oE '[0-9]+\.[0-9]+')

replace_in_dockerfile() {
    local file="$1" old="$2" new="$3" content
    content=$(<"$file")
    if [[ "$content" != *"$old"* ]]; then
        error "Upstream's template changed and a patch no longer applies to $file. Update patch_dockerfile in $0. Missing text: $old"
    fi
    printf '%s\n' "${content//"$old"/"$new"}" > "$file"
}

# Every change we make to upstream's output. Keep this list short: each one is a
# difference from the official image that we maintain ourselves.
patch_dockerfile() {
    local dockerfile="$1" sha256="$2"

    # Verify the tarball with the release managers' keys from src/base/keys instead of
    # fetching them from a keyserver, which can be slow or down when a release lands.
    replace_in_dockerfile "$dockerfile" \
        "ENV PHP_SHA256=\"$sha256\""$'\n\n'"RUN set -eux; \\" \
        "ENV PHP_SHA256=\"$sha256\""$'\n\n'"RUN --mount=type=bind,source=keys,target=/usr/src/php-keys set -eux; \\"
    replace_in_dockerfile "$dockerfile" \
        'gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key";' \
        'gpg --batch --import "/usr/src/php-keys/$key.asc";'

    # Every image in the matrix downloads at once, so retry transient errors from php.net and GitHub.
    replace_in_dockerfile "$dockerfile" 'curl -fsSL -o php.tar.xz' 'curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors -o php.tar.xz'

    # pecl.php.net went down during the October 2026 security release. Refreshing the channel
    # list is a convenience (install-php-extensions refreshes it again), so it must not fail the build.
    if [[ "$(<"$dockerfile")" == *'pecl update-channels;'* ]]; then
        replace_in_dockerfile "$dockerfile" 'pecl update-channels;' 'pecl update-channels || true;'
    fi

    # php -i reports who built PHP. Point bug reports for these builds to us, not docker-library.
    replace_in_dockerfile "$dockerfile" \
        "PHP_BUILD_PROVIDER='https://github.com/docker-library/php'" \
        "PHP_BUILD_PROVIDER='https://github.com/serversideup/docker-php'"
}

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
cp -a "$BASE_DIR/upstream/." "$OUTPUT_DIR/"

variants=()
for os in "${OPERATING_SYSTEMS[@]}"; do
    for sapi in "${SAPIS[@]}"; do
        variants+=("$os/$sapi")
    done
done

versions_json='{}'
for version in "${VERSIONS[@]}"; do
    minor=$(echo "$version" | cut -d. -f1,2)
    grep -qxF "$minor" <<< "$SUPPORTED_MINORS" \
        || error "PHP $minor is not supported by docker-library's template. Supported: $(echo $SUPPORTED_MINORS)"
    [ "$(jq --arg minor "$minor" 'has($minor)' <<< "$versions_json")" = "false" ] \
        || error "PHP $minor was passed more than once."

    release=$(curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors \
        "https://www.php.net/releases/index.php?json&version=${version}") \
        || error "Could not fetch PHP $version from php.net."
    jq -e 'has("error") | not' <<< "$release" > /dev/null || error "php.net does not know PHP $version: $(jq -r .error <<< "$release")"

    versions_json=$(jq -c \
        --arg minor "$minor" \
        --argjson release "$release" \
        --args '
        .[$minor] = (
            ($release.source[] | select(.filename | endswith(".tar.xz"))) as $source
            | {
                version: $release.version,
                url: ("https://www.php.net/distributions/" + $source.filename),
                ascUrl: ("https://www.php.net/distributions/" + $source.filename + ".asc"),
                sha256: $source.sha256,
                variants: [ $ARGS.positional[] ]
            }
        )' "${variants[@]}" <<< "$versions_json")
done
echo "$versions_json" > "$OUTPUT_DIR/versions.json"

(
    cd "$OUTPUT_DIR"
    BASHBREW_SCRIPTS="$OUTPUT_DIR/bashbrew" ./apply-templates.sh >&2
)

jq -r 'to_entries[] | .key as $minor | .value | .version as $version | .sha256 as $sha256 | .variants[] | [$minor, $version, $sha256, .] | @tsv' "$OUTPUT_DIR/versions.json" \
    | while IFS=$'\t' read -r minor version sha256 variant; do
        context_dir="$OUTPUT_DIR/$minor/$variant"
        patch_dockerfile "$context_dir/Dockerfile" "$sha256"
        mkdir -p "$context_dir/keys"
        for key in $(sed -n 's/^ENV GPG_KEYS //p' "$context_dir/Dockerfile"); do
            cp "$BASE_DIR/keys/$key.asc" "$context_dir/keys/" || error "Missing signing key $key in $BASE_DIR/keys. Add it from https://www.php.net/gpg-keys.php."
        done
        echo "$version ${variant#*/} ${variant%/*} $context_dir"
    done

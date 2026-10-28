#!/usr/bin/env bash
set -euo pipefail

# Usage: prepare-php-base.sh <docker-library-ref> <php-patch-version> <base-os> <php-base> <output-dir>
# Example: prepare-php-base.sh 5ec2a6a0dad498e89a91a39454dbb52e98ce2bdb 8.4.27 trixie fpm .php-base/8.4.27-fpm-trixie
#          prepare-php-base.sh 5ec2a6a0dad498e89a91a39454dbb52e98ce2bdb 8.6-rc trixie cli .php-base/8.6-rc-cli-trixie
#
# A version like "8.6-rc" builds the newest release candidate php.net lists for 8.6.
# Writes the build context for one official PHP image (docker-library/php at a pinned
# commit) set to compile <php-patch-version> from the php.net tarball. That lets us ship a
# release as soon as php.net publishes it, without waiting for Docker Hub. Only the version
# lines change, and "pecl update-channels" is removed so a PECL outage cannot fail the build.
# Everything else, including the GPG check, is exactly what the official images run.

if [ "$#" -ne 5 ]; then
    sed -n '4,5p' "$0" | sed 's/^# //' >&2
    exit 1
fi

ref="$1"
patch="$2"
base_os="$3"
php_base="$4"
output_dir="$5"

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
download="$scripts_dir/../src/common/usr/local/bin/docker-php-serversideup-download"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

fail() {
    echo "🛑 ERROR (prepare-php-base.sh): $1" >&2
    exit 1
}

# docker-library keeps release candidates in their own directory, such as 8.6-rc
if [[ "$patch" == *-rc ]]; then
    minor="$patch"
    release=$("$download" "https://www.php.net/release-candidates.php?format=json" \
        | jq -c --arg prefix "${patch%-rc}." '[to_entries[] | select(.key | startswith($prefix)) | .value.release | select(.version != null and .files.xz.sha256 != "")][0] // empty')
    [ -n "$release" ] || fail "php.net does not list a release candidate for ${patch%-rc}"
    version=$(jq -r '.version' <<< "$release")
    tarball_url=$(jq -r '.files.xz.path' <<< "$release")
    sha256=$(jq -r '.files.xz.sha256' <<< "$release")
else
    minor="${patch%.*}"
    version="$patch"
    tarball_url="https://www.php.net/distributions/php-${patch}.tar.xz"
    sha256=$("$download" "https://www.php.net/releases/index.php?json&version=${patch}" \
        | jq -r --arg file "php-${patch}.tar.xz" '(.source // [])[] | select(.filename == $file) | .sha256')
fi
[ -n "$sha256" ] || fail "php.net does not list a SHA256 for PHP ${version}"

"$download" "https://codeload.github.com/docker-library/php/tar.gz/${ref}" "$work_dir/docker-library-php.tar.gz"
rm -rf "$output_dir"
mkdir -p "$output_dir"
tar -xzf "$work_dir/docker-library-php.tar.gz" -C "$output_dir" --strip-components=4 "php-${ref}/${minor}/${base_os}/${php_base}" \
    || fail "docker-library/php@${ref} has no ${minor}/${base_os}/${php_base}"

dockerfile="$output_dir/Dockerfile"
sed \
    -e "s|^ENV PHP_VERSION .*|ENV PHP_VERSION ${version}|" \
    -e "s|^ENV PHP_URL=.*|ENV PHP_URL=\"${tarball_url}\" PHP_ASC_URL=\"${tarball_url}.asc\"|" \
    -e "s|^ENV PHP_SHA256=.*|ENV PHP_SHA256=\"${sha256}\"|" \
    -e '/^[[:space:]]*pecl update-channels;/d' \
    "$dockerfile" > "$dockerfile.new"
mv "$dockerfile.new" "$dockerfile"

# Check the result rather than the input, so a change in docker-library's layout fails here.
[ "$(grep -c "^ENV PHP_VERSION ${version}\$" "$dockerfile")" = "1" ] || fail "PHP_VERSION was not set to ${version}"
grep -qF "ENV PHP_URL=\"${tarball_url}\"" "$dockerfile" || fail "PHP_URL was not set to ${tarball_url}"
grep -qF "ENV PHP_SHA256=\"${sha256}\"" "$dockerfile" || fail "PHP_SHA256 was not set"
if grep -E '^[^#]*pecl' "$dockerfile"; then
    fail "the Dockerfile still calls pecl"
fi

echo "✅ ${output_dir}: docker-library/php ${minor}/${base_os}/${php_base} at ${ref:0:7}, PHP ${version}"

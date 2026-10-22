#!/bin/bash
set -eo pipefail

###################################################
# Usage: plan-php-base-images.sh <matrix-json-file> <image-prefix> [output-dir]
###################################################
# Works out which serversideup/php-base images a build matrix (from generate-matrix.sh,
# keyed by variation) needs, and which of them still have to be compiled. Each image is
# tagged with a hash of everything that goes into it: the rendered Dockerfile and build
# context, plus the digest of the Debian or Alpine image it starts from. So an image is
# only compiled again when PHP, docker-library's template, our patches, or the OS changes.
# The image prefix is the image name and the start of the tag, such as
# "ghcr.io/serversideup/php-base:" or "docker.io/serversideup/php-dev:php-base-".
#
# Prints a JSON array, one entry per image:
#
#     {"key": "8.4.27-fpm-trixie", "php": "8.4.27", "sapi": "fpm", "os": "trixie",
#      "image": "<image-prefix>8.4.27-fpm-trixie-<hash>", "exists": true}

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
matrix_file="$1"
image_prefix="$2"
output_dir="${3:-$(dirname "$SCRIPT_DIR")/build/php-base}"

if [ ! -f "$matrix_file" ] || [ -z "$image_prefix" ]; then
    sed -n '4,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
    exit 1
fi

needed=$(jq -c '[.[].include[] | select(.php_from_source) | {php: .patch_version, sapi: .base_sapi, os: .base_os}] | unique' "$matrix_file")
if [ "$(jq 'length' <<< "$needed")" = "0" ]; then
    echo '[]'
    exit 0
fi

generate_args=()
for field in php:--version os:--os sapi:--sapi; do
    while read -r value; do
        generate_args+=("${field#*:}" "$value")
    done < <(jq -r --arg field "${field%%:*}" '[.[][$field]] | unique | .[]' <<< "$needed")
done
"$SCRIPT_DIR/generate-php-base.sh" "${generate_args[@]}" --output "$output_dir" > /dev/null

sha256() {
    if command -v sha256sum > /dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

# One "<image> <digest>" line per OS image, since every PHP version shares the same few
from_digests=""
plan='[]'
while IFS=$'\t' read -r php sapi os; do
    context_dir="$output_dir/${php%.*}/$os/$sapi"
    from=$(sed -n 's/^FROM //p' "$context_dir/Dockerfile" | head -n1)
    from_digest=$(awk -v from="$from" '$1 == from { print $2 }' <<< "$from_digests")
    if [ -z "$from_digest" ]; then
        from_digest=$(docker buildx imagetools inspect "$from" --format '{{json .Manifest}}' | jq -r .digest)
        from_digests+="$from $from_digest"$'\n'
    fi
    hash=$(
        cd "$context_dir"
        { find . -type f | LC_ALL=C sort | while read -r file; do sha256 "$file"; done; echo "$from@$from_digest"; } | sha256 | cut -c1-12
    )
    key="$php-$sapi-$os"
    image="$image_prefix$key-$hash"
    exists=false
    if docker buildx imagetools inspect "$image" > /dev/null 2>&1; then
        exists=true
    fi
    echo "$image $([ "$exists" = true ] && echo "exists" || echo "to build")" >&2
    plan=$(jq -c --arg key "$key" --arg php "$php" --arg sapi "$sapi" --arg os "$os" --arg image "$image" --argjson exists "$exists" \
        '. + [{key: $key, php: $php, sapi: $sapi, os: $os, image: $image, exists: $exists}]' <<< "$plan")
done < <(jq -r '.[] | [.php, .sapi, .os] | @tsv' <<< "$needed")

echo "$plan"

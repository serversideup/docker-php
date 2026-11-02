#!/usr/bin/env bash
set -euo pipefail

# Usage: get-php-release-candidate.sh <php-minor>
# Example: get-php-release-candidate.sh 8.6
#
# Prints the newest release candidate php.net lists for <php-minor> as one line of JSON
# ({"version": ..., "url": ..., "sha256": ...}), or nothing when there is none. php.net
# lists none between a final release and the next release candidate, such as right after
# 8.6.0 ships. PHP_PRE_RELEASE_JSON_FEED reads a different feed (the tests use a file).

if [ "$#" -ne 1 ]; then
    sed -n '4,5p' "$0" | sed 's/^# //' >&2
    exit 1
fi

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
download="$scripts_dir/../src/common/usr/local/bin/docker-php-serversideup-download"
feed="${PHP_PRE_RELEASE_JSON_FEED:-https://www.php.net/pre-release-builds.php?format=json}"

"$download" "$feed" | jq -c --arg prefix "$1." '
  [ to_entries[]
    | select(.key | startswith($prefix))
    | .value.release
    | select(.version != null and .files.xz.sha256 != "")
    | {version, url: .files.xz.path, sha256: .files.xz.sha256} ][0] // empty'

#!/usr/bin/env bash
set -euo pipefail

# Usage: select-smoke-images.sh <image-details-dir>
#
# Picks a representative slice of the images a CI run published, for the smoke
# tests: the newest PHP version of every variation on one Debian and one Alpine
# base, each on an amd64 and an arm64 runner. Prints a GitHub Actions matrix as
# single-line JSON. Only images saved to the Depot Registry are selected.

details_dir="${1:?Usage: select-smoke-images.sh <image-details-dir>}"

built=$(find "$details_dir" -name '*.json' -print0 | xargs -0 -r jq -s -c '.')
built="${built:-[]}"

echo "$built" | jq -c '
  def version_key: gsub("-rc"; ".999") | split(".") | map(tonumber? // 0);
  def family: if (.os | startswith("alpine")) then "alpine" else "debian" end;

  [ .[] | select(.saved != null) ]
  | group_by(.variation)
  | map(
      (max_by(.php | version_key) | .php) as $newest
      | map(select(.php == $newest))
      | group_by(family)
      | map(max_by(.os))
    )
  | flatten
  | [ .[] as $image
      | ("ubuntu-24.04", "ubuntu-24.04-arm") as $runner
      | { variation: $image.variation, php: $image.php, os: $image.os, saved: $image.saved,
          runner: $runner,
          arch: (if $runner == "ubuntu-24.04" then "amd64" else "arm64" end) } ]
  | { include: . }
'

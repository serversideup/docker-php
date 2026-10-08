#!/usr/bin/env bash
set -euo pipefail

# Usage: build-summary.sh <image-details-dir> [expected-matrix-json]
#
# Renders a Markdown table of the images built in a CI run from the JSON files that
# each build job records (see service_build-images.yml) and each publish job adds
# (see service_publish-images.yml). When both exist for an image, the published one
# wins because it carries the sizes. The optional matrix JSON, keyed by variation as
# produced by service_setup-matrix.yml, is used to list images that never reported
# back so a failed build is visible in the table.

details_dir="${1:?Usage: build-summary.sh <image-details-dir> [expected-matrix-json]}"
expected_matrix="${2:-{\}}"

built=$(find "$details_dir" -name '*.json' -print0 | xargs -0 -r jq -s '
  group_by([.variation, .php, .os]) | map((map(select(.published)) | first) // .[0])')
built="${built:-[]}"

expected=$(echo "$expected_matrix" | jq -c '[.[]? | .include[] | {variation: .php_variation, php: .patch_version, os: .base_os}]')

echo "$built" | jq -r --argjson expected "$expected" '
  def version_key: gsub("-rc"; ".999") | split(".") | map(tonumber? // 0) | map(-.);
  def megabytes: if . == null then "" else ((. / 100000) | round) as $tenths | "\($tenths / 10 | floor).\($tenths % 10) MB" end;
  def image_cell:
    if has("tags") | not then "❌ not built"
    elif .published then "`" + (.tags[0] | sub("^docker.io/"; "")) + "`"
    else "built, not published"
    end;

  . as $built
  | (if ($expected | length) > 0 then $expected else map({variation, php, os}) end) as $rows
  | ($rows | map(. as $row
      | (first($built[] | select(.variation == $row.variation and .php == $row.php and .os == $row.os)) // $row)
    )) as $merged
  | ($merged | map(select(has("tags"))) | length) as $built_count
  | ($merged | any(.published == true)) as $published
  | "## Images: \($built_count) of \($rows | length) built" + (if $published then "" else " (not published)" end),
    "",
    "Sizes are compressed, per architecture.",
    "",
    "| Variation | PHP | Base OS | amd64 | arm64 | Image |",
    "|---|---|---|---|---|---|",
    ($merged
      | sort_by([.variation, (.php | version_key), .os])
      | .[]
      | "| \(.variation) | \(.php) | \(.os) | \(.sizes["linux/amd64"] | megabytes) | \(.sizes["linux/arm64"] | megabytes) | \(image_cell) |")
'

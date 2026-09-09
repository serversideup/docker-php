#!/usr/bin/env bash
set -euo pipefail

# Usage: build-summary.sh <image-details-dir> [expected-matrix-json]
#
# Renders a Markdown table of the images built in a CI run from the JSON files that
# each build job records (see service_docker-build-and-publish.yml). The optional
# matrix JSON, keyed by variation as produced by service_setup-matrix.yml, is used to
# list images that never reported back so a failed build is visible in the table.

details_dir="${1:?Usage: build-summary.sh <image-details-dir> [expected-matrix-json]}"
expected_matrix="${2:-{\}}"

built=$(find "$details_dir" -name '*.json' -print0 | xargs -0 -r jq -s '.')
built="${built:-[]}"

expected=$(echo "$expected_matrix" | jq -c '[.[]? | .include[] | {variation: .php_variation, php: .patch_version, os: .base_os}]')

echo "$built" | jq -r --argjson expected "$expected" '
  def version_key: gsub("-rc"; ".999") | split(".") | map(tonumber? // 0) | map(-.);
  def megabytes: if . == null then "" else ((. / 100000) | round) as $tenths | "\($tenths / 10 | floor).\($tenths % 10) MB" end;
  def growth_threshold: 10;
  def size_cell($platform):
    (.sizes[$platform]) as $size
    | (.baseline[$platform]) as $baseline
    | if $size == null then ""
      elif $baseline == null or $baseline == 0 then ($size | megabytes)
      else ((($size - $baseline) / $baseline * 1000 | round) / 10) as $pct
        | (if $pct > 0 then "+" else "" end) + ($pct | tostring) + "%" as $delta
        | (if $pct > growth_threshold then "⚠️ " else "" end) + ($size | megabytes) + " (" + $delta + ")"
      end;
  def pull_cell:
    if has("tag") | not then "❌ not built"
    elif .pushed then "`docker pull " + (.tag | sub("^docker.io/"; "")) + "`"
    else "built, not published"
    end;

  . as $built
  | (if ($expected | length) > 0 then $expected else map({variation, php, os}) end) as $rows
  | ($rows | map(. as $row
      | (first($built[] | select(.variation == $row.variation and .php == $row.php and .os == $row.os)) // $row)
    )) as $merged
  | ($merged | map(select(has("tag"))) | length) as $built_count
  | ($merged | any(.pushed == true)) as $published
  | "## Images: \($built_count) of \($rows | length) built" + (if $published then "" else " (not published)" end),
    "",
    "Sizes are compressed, per architecture. The percentage compares against the same tag currently on `serversideup/php`; ⚠️ marks growth over \(growth_threshold)%.",
    "",
    "| Variation | PHP | Base OS | amd64 | arm64 | Pull |",
    "|---|---|---|---|---|---|",
    ($merged
      | sort_by([.variation, (.php | version_key), .os])
      | .[]
      | "| \(.variation) | \(.php) | \(.os) | \(size_cell("linux/amd64")) | \(size_cell("linux/arm64")) | \(pull_cell) |")
'

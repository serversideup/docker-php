#!/usr/bin/env bash
set -euo pipefail

# Usage: security-report.sh <scans-dir> <reports-dir> <run-url>
#
# Turns the per-image summaries from scan-summary.sh into the public security reports
# on the security-reports branch: reports/images/<image>.json for each image and
# reports/index.json for all of them, which the Security status docs page reads.
#
# The index lists every critical or high finding that has a fix, with the number of
# scans in a row that found it. The weekly rebuild clears most of these on its own,
# so service_scan-images.yml only opens an issue once a finding survives a rebuild
# (two scans in a row). The previous index in <reports-dir> is how a scan knows what
# the last one found. The fixable list is printed so the workflow can manage issues.

scans_dir="${1:?Usage: security-report.sh <scans-dir> <reports-dir> <run-url>}"
reports_dir="${2:?Usage: security-report.sh <scans-dir> <reports-dir> <run-url>}"
run_url="${3:?Usage: security-report.sh <scans-dir> <reports-dir> <run-url>}"

previous='{"fixable": []}'
if [ -f "$reports_dir/index.json" ]; then
  previous=$(cat "$reports_dir/index.json")
fi

scans=$(find "$scans_dir" -name '*.json' -print0 | xargs -0 -r jq -s 'sort_by(.image)')
scans="${scans:-[]}"
if [ "$(echo "$scans" | jq 'length')" = "0" ]; then
  echo "No scan summaries found in $scans_dir" >&2
  exit 1
fi

# Images that are no longer published (an end-of-life OS, a superseded patch) drop out
# of the reports, so the page only ever describes images people can pull today.
rm -rf "$reports_dir/images"
mkdir -p "$reports_dir/images"
echo "$scans" | jq -c '.[]' | while read -r scan; do
  echo "$scan" | jq '.' > "$reports_dir/images/$(echo "$scan" | jq -r .image).json"
done

echo "$scans" | jq --argjson previous "$previous" --arg run_url "$run_url" '
  ($previous.fixable | map({(.id): .consecutive_scans}) | add // {}) as $seen
  | {
      generated_at: (now | todate),
      run_url: $run_url,
      scanner: .[0].scanner,
      images: map({image, variation, php, os, digest, scanned_at, counts, fixable}),
      fixable: (
        [.[] as $scan | $scan.vulnerabilities[]
          | select((.severity == "Critical" or .severity == "High") and .state == "fixed")
          | {id, severity, image: $scan.image, package, version, fixed_in}]
        | group_by(.id)
        | map({
            id: .[0].id,
            severity: .[0].severity,
            packages: (map(.package) | unique),
            images: map({image, package, version, fixed_in}),
            consecutive_scans: (($seen[.[0].id] // 0) + 1)
          })
        | sort_by((.severity as $s | ["Critical", "High"] | index($s)), .id))
    }' > "$reports_dir/index.json"

jq '.fixable' "$reports_dir/index.json"

#!/usr/bin/env bash
set -euo pipefail

# Usage: scan-summary.sh <grype-json> <image> <variation> <php> <os> <digest>
#
# Reduces Grype's JSON for one image to the summary the security reports publish (see
# service_scan-images.yml): counts per severity, how many of those have a fix, and the
# critical, high, and medium findings. Low and negligible findings are only counted,
# because Debian lists hundreds of them that it does not plan to fix.

grype_json="${1:?Usage: scan-summary.sh <grype-json> <image> <variation> <php> <os> <digest>}"

jq --arg image "$2" --arg variation "$3" --arg php "$4" --arg os "$5" --arg digest "$6" '
  def severities: ["Critical", "High", "Medium", "Low", "Negligible", "Unknown"];
  def count_by_severity: (reduce .[] as $s ((severities | map({(.): 0}) | add); .[$s] += 1));
  [.matches[] | {
    id: .vulnerability.id,
    severity: .vulnerability.severity,
    package: .artifact.name,
    version: .artifact.version,
    type: .artifact.type,
    fixed_in: (.vulnerability.fix.versions // []),
    state: .vulnerability.fix.state,
    url: .vulnerability.dataSource
  }] as $found
  | {
      image: $image,
      variation: $variation,
      php: $php,
      os: $os,
      digest: $digest,
      scanned_at: (.descriptor.timestamp // (now | todate)),
      scanner: {name: "grype", version: .descriptor.version, db_built: .descriptor.db.status.built},
      counts: ($found | map(.severity) | count_by_severity),
      fixable: ($found | map(select(.state == "fixed") | .severity) | count_by_severity),
      vulnerabilities: ($found
        | map(select(.severity == "Critical" or .severity == "High" or .severity == "Medium"))
        | unique_by([.id, .package, .version])
        | sort_by((.severity as $s | ["Critical", "High", "Medium"] | index($s)), .id))
    }' "$grype_json"

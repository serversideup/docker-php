#!/usr/bin/env bash
set -euo pipefail

# Usage: generate-matrix.sh [path/to/php-versions.yml]
# Reads the provided YAML (or $PHP_VERSIONS_FILE, or default scripts/conf/php-versions.yml)
# and prints a GitHub Actions matrix JSON of the form {"include": [...]}

PHP_VERSIONS_FILE="${1:-${PHP_VERSIONS_FILE:-scripts/conf/php-versions.yml}}"

if [ ! -f "$PHP_VERSIONS_FILE" ]; then
  echo "YAML file not found: $PHP_VERSIONS_FILE" >&2
  exit 1
fi

# Convert YAML to JSON, then shape it with jq.
yq -o=json "$PHP_VERSIONS_FILE" | jq -c '

  def version_weight:
    # Convert "x.y.z" into a sortable integer weight
    split(".") | map(tonumber) as $nums | ($nums[0]*10000 + $nums[1]*100 + $nums[2]);

  def os_family_match($os_name; $supported):
    # Allow listing "alpine" to include any alpine3.xx base_os
    # Exact matches like "bullseye", "bookworm", "trixie" must match exactly
    ($supported == $os_name) or ($supported == "alpine" and ($os_name | startswith("alpine")));

  def is_supported($variation; $os):
    # If no supported_os specified, allow all; otherwise filter
    (($variation.supported_os // []) | length) == 0 or
    ((($variation.supported_os // []) | any(os_family_match($os.name; .))));

  . as $root
  | [ ($root.php_variations[] | {name, supported_os}) as $variation
      | $root.php_versions[]
      | .minor_versions[]
      | .base_os[] as $os
      | .patch_versions[] as $patch
      | select(is_supported($variation; $os))
      | {patch_version: $patch, base_os: $os.name, php_variation: $variation.name}
    ]
  | { include: ( . | sort_by(.patch_version | version_weight) | reverse ) }
'



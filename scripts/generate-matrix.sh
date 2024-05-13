#!/bin/bash
###################################################
# Usage: generate-matrix.sh
###################################################
# This script is used to generate the GitHub Actions
# matrix for the PHP versions and OS combinations.
#
# 👉 REQUIRED FILES
# - PHP_VERSIONS_FILE must be valid and set to a valid file path
#  (defaults to scripts/conf/php-versions.yml)

set -euo pipefail

# Path to the PHP versions configuration file
PHP_VERSIONS_FILE="${PHP_VERSIONS_FILE:-"scripts/conf/php-versions.yml"}"

# Generate and output the MATRIX_JSON
yq -o=json "$PHP_VERSIONS_FILE" | 
jq -c '{
  include: [
    (.php_variations[] | 
      {name, supported_os: (.supported_os // ["alpine", "bullseye", "bookworm"]), excluded_minor_versions: (.excluded_minor_versions // [])}
    ) as $variation |
    .php_versions[] |
    .minor_versions[] | 
    # Check if the minor version is not in the excluded list for the variation
    select([.minor] | inside($variation.excluded_minor_versions | map(.)) | not) |
    .patch_versions[] as $patch |
    .base_os[] as $os |
    select($variation.supported_os | if length == 0 then . else . | index($os.name) end) |
    {patch_version: $patch, base_os: $os.name, php_variation: $variation.name}
  ] 
} | 
{include: (.include | sort_by(.patch_version | split(".") | map(tonumber) | . as $nums | ($nums[0]*10000 + $nums[1]*100 + $nums[2])) | reverse)}'

#!/bin/bash
###################################################
# Usage: assemble-docker-tags.sh --variation <variation> --os <os> --patch-version <patch-version> [--stable-release --github-release-tag <tag>]
###################################################
# This scripts dives deep into the advanced logic of assembling Docker tags for GitHub Actions.
# If $CI is "true", it outputs the tags to GITHUB_ENV for use in subsequent steps.
# You can run this locally for debugging. The script has beautiful output and can help debug
# any advanced logic issues.
#
# 👉 REQUIRED FILES
# - PHP_VERSIONS_FILE must be valid and set to a valid file path
#  (defaults to scripts/conf/php-versions.yml)

set -oe pipefail

##########################
# Environment Settings

# Required variables to set
DEFAULT_IMAGE_VARIATION="${DEFAULT_IMAGE_VARIATION:-"cli"}"
PHP_VERSIONS_FILE="${PHP_VERSIONS_FILE:-"scripts/conf/php-versions.yml"}"

# Convert comma-separated DOCKER_REGISTRY_REPOSITORIES string to an array
IFS=',' read -ra DOCKER_REGISTRY_REPOSITORIES <<< "${DOCKER_REGISTRY_REPOSITORIES:-"docker.io/serversideup/php,ghcr.io/serversideup/php"}"
DOCKER_TAG_PREFIX="${DOCKER_TAG_PREFIX:-""}"
RELEASE_TYPE="${RELEASE_TYPE:-"testing"}"

##########################
# Functions

# UI Colors
function ui_set_yellow {
    printf $'\033[1;33m'
}

function ui_set_green {
    printf $'\033[1;32m'
}

function ui_set_red {
    printf $'\033[0;31m'
}

function ui_set_blue {
    printf $'\033[1;34m'
}

function ui_reset_colors {
    printf "\e[0m"
}

function echo_color_message (){
  color=$1
  message=$2

  ui_set_$color
  echo "$message"
  ui_reset_colors
}

check_vars() {
  message=$1
  shift

  for variable in "$@"; do
    if [ -z "${!variable}" ]; then
      echo_color_message red "$message: $variable"
      echo
      help_menu
      return 1
    fi
  done
  return 0
}

add_docker_tag() {
# Function: add_docker_tag
# Description: Appends Docker tags to the DOCKER_TAGS variable and prints each tag.
#
# Parameters:
#   docker_tag_suffix - The suffix to be appended to the Docker image name as part of the tag.
  docker_tag_suffix=$1

  for image_name in "${DOCKER_REGISTRY_REPOSITORIES[@]}"; do

    # Append a dash to tags that have a suffix
    if [[ -n "$DOCKER_TAG_PREFIX" && "$docker_tag_suffix" != "$DOCKER_TAG_PREFIX" ]]; then
      prefix_tag="$DOCKER_TAG_PREFIX-"
    else
      prefix_tag=""
    fi
    
    tag_name="$image_name:$prefix_tag$docker_tag_suffix"    

    if [[ -z "$DOCKER_TAGS" ]]; then
      # Do not prefix with comma
      DOCKER_TAGS+="$tag_name"
    else
      # Add a comma to separate the tags
      DOCKER_TAGS+=",$tag_name"
    fi

    # Trim commas for a better output
    echo_color_message blue "🐳 Set tag: ${tag_name//,}  "

    if [[ -n "$GITHUB_RELEASE_TAG" && "$GITHUB_REF_TYPE" == "tag" && "$docker_tag_suffix" != "latest"  ]]; then
      release_tag_name="$image_name:$docker_tag_suffix-$GITHUB_RELEASE_TAG"
      DOCKER_TAGS+=",$release_tag_name"
      echo_color_message blue "🐳 Set tag: $release_tag_name"
    fi

  done
}

function is_latest_stable_patch_within_build_minor() {
    [[ "$build_patch_version" == "$latest_patch_within_build_minor" && "$build_patch_version" != *"rc"* ]]
}

function is_latest_global_patch() {
    [[ "$build_patch_version" == "$latest_patch_global" && "$build_patch_version" != *"rc"* ]]
}

function is_latest_minor_within_build_major() {
    [[ "$build_minor_version" == "$latest_minor_within_build_major" && "$build_minor_version" != *"rc"* ]]
}

function is_latest_major() {
    [[ "$build_major_version" == "$latest_global_stable_major" ]]
}

function is_default_base_os() {
    [[ "$build_base_os" == "$default_supported_base_os_within_build_minor" ]]
}

function is_latest_family_os_for_build_minor() {
    [[ "$build_base_os" == "$latest_family_supported_os_within_build_minor" ]]
}

add_family_alias_if_latest() {
  # Emits a family alias tag if the current build base OS is the latest within its family for this minor
  local docker_tag_suffix=$1
  if is_latest_family_os_for_build_minor; then
    if [[ "$docker_tag_suffix" == *"-$build_base_os" ]]; then
      local family_tag_suffix="${docker_tag_suffix%$build_base_os}$build_family"
      add_docker_tag "$family_tag_suffix"
    elif [[ "$docker_tag_suffix" == "$build_base_os" ]]; then
      add_docker_tag "$build_family"
    fi
  fi
}

function ci_release_is_production_launch() {
    [[ -z "$DOCKER_TAG_PREFIX" && "$RELEASE_TYPE" == "latest" ]]
}

function is_default_variation() {
    [[ "$PHP_BUILD_VARIATION" == "$DEFAULT_IMAGE_VARIATION" ]]
}

function is_rc_build() {
    [[ "$build_patch_version" == *"-rc"* ]]
}

validate_os_and_variation() {
  local os_to_check="$build_base_os"
  local variation_to_check="$build_variation"

  # Validate OS exists in config
  if ! yq -o=json "$PHP_VERSIONS_FILE" | jq -e --arg os "$os_to_check" 'any(.operating_systems[] | .versions[]; .version == $os)' > /dev/null; then
    echo_color_message red "🛑 ERROR: Unknown --os '$os_to_check'"
    echo "Valid options are:"
    yq -o=json "$PHP_VERSIONS_FILE" | jq -r '.operating_systems[].versions[].version' | sed 's/^/- /'
    echo
    help_menu
    exit 1
  fi

  # Validate variation exists
  if ! yq -o=json "$PHP_VERSIONS_FILE" | jq -e --arg v "$variation_to_check" 'any(.php_variations[]; .name == $v)' > /dev/null; then
    echo_color_message red "🛑 ERROR: Unknown --variation '$variation_to_check'"
    echo "Valid options are:"
    yq -o=json "$PHP_VERSIONS_FILE" | jq -r '.php_variations[].name' | sed 's/^/- /'
    echo
    help_menu
    exit 1
  fi

  # Validate variation supports OS if a constraint is defined
  local supports_json
  supports_json=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg v "$variation_to_check" '[.php_variations[] | select(.name == $v) | (.supported_os // [])[]]')
  local has_constraints
  has_constraints=$(echo "$supports_json" | jq 'length > 0')

  if [[ "$has_constraints" == "true" ]]; then
    local is_supported
    is_supported=$(echo "$supports_json" | jq -e --arg os "$os_to_check" '
      any(.[]; . == $os or (. == "alpine" and ($os | startswith("alpine"))))
    ' >/dev/null 2>&1; echo $?)
    if [[ "$is_supported" != "0" ]]; then
      echo_color_message red "🛑 ERROR: Variation '$variation_to_check' does not support OS '$os_to_check'"
      echo "Supported values for '$variation_to_check' are:"
      echo "$supports_json" | jq -r '.[]' | sed 's/^/- /'
      echo
      exit 1
    fi
  fi
}

help_menu() {
    echo "Usage: $0 --variation <variation> --os <os> --patch-version <patch-version> [--stable-release --github-release-tag <tag>]"
    echo
    echo "This script dives deep into the advanced logic of assembling Docker tags for GitHub Actions."
    echo "If \$CI is 'true', it outputs the tags to GITHUB_ENV for use in subsequent steps."
    echo "You can run this locally for debugging. The script has beautiful output and can help debug"
    echo "any advanced logic issues."
    echo
    echo "Options:"
    echo "  --variation <variation>         Set the PHP variation (e.g., apache, fpm)"
    echo "  --os <os>                       Set the base OS (e.g., bullseye, bookworm, alpine)"
    echo "  --patch-version <patch-version> Set the PHP patch version (e.g., 7.4.10)"
    echo "  --github-release-tag <tag>      Set the GitHub release tag"
    echo "  --stable-release                Flag the tags for a stable release"
    echo
    echo "Environment Variables (Defaults):"
    echo "  DEFAULT_IMAGE_VARIATION      The default PHP image variation (default: cli)"
    echo "  DOCKER_REGISTRY_REPOSITORIES  Names of images to tag (default: 'docker.io/serversideup/php' 'ghcr.io/serversideup/php')"
    echo "  PHP_VERSIONS_FILE            Path to PHP versions file (default: scripts/conf/php-versions.yml)"
}

##########################
# Main Script

# Check arguments (if passed, these arguments are optional and intended for development debugging only)
while [[ $# -gt 0 ]]; do
    case $1 in
        --variation)
        PHP_BUILD_VARIATION="$2"
        shift 2
        ;;
        --os)
        PHP_BUILD_BASE_OS="$2"
        shift 2
        ;;
        --patch-version)
        PHP_BUILD_VERSION="$2"
        shift 2
        ;;
        --github-release-tag)
        GITHUB_REF_TYPE="tag"
        GITHUB_RELEASE_TAG="$2"
        shift 2
        ;;
        --stable-release)
        RELEASE_TYPE="latest"
        shift
        ;;
        *)
        echo "🛑 ERROR: Unknown argument passed: $1"
        exit 1
        shift
        ;;
    esac
done

# Check that all required variables are set
check_vars \
  "🚨 Required variables not set" \
  PHP_BUILD_VARIATION \
  PHP_BUILD_VERSION \
  PHP_BUILD_BASE_OS \
  PHP_VERSIONS_FILE

if [[ ! -f $PHP_VERSIONS_FILE ]]; then
  echo_color_message red "🚨 PHP Versions file not found at $PHP_VERSIONS_FILE"
  echo "Current directory: $(pwd)"
  echo "Contents of $(dirname "$PHP_VERSIONS_FILE"): $(ls -al "$(dirname "$PHP_VERSIONS_FILE")")"
  echo "Contents of the file:"
  cat "$PHP_VERSIONS_FILE"
  exit 1
fi

# Store arguments
build_patch_version=$PHP_BUILD_VERSION
build_base_os=$PHP_BUILD_BASE_OS
build_variation=$PHP_BUILD_VARIATION

# Validate inputs early
validate_os_and_variation

# Extract major and minor versions from build_patch_version
build_major_version="${build_patch_version%%.*}"
if [[ "$build_patch_version" == *"-rc"* ]]; then
  # For RC inputs like 8.5-rc, the minor identifier is the whole string
  build_minor_version="$build_patch_version"
else
  build_minor_version="${build_patch_version%.*}"
fi

# Fetch version data from the PHP Versions file
latest_global_stable_major=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r '[.php_versions[] | select(.major | test("-rc") | not) | .major | tonumber] | max | tostring')
latest_global_stable_minor=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg latest_global_stable_major "$latest_global_stable_major" '.php_versions[] | select(.major == $latest_global_stable_major) | .minor_versions | map(select(.minor | test("-rc") | not) | .minor | split(".") | .[1] | tonumber) | max | $latest_global_stable_major + "." + tostring')
latest_minor_within_build_major=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg build_major "$build_major_version" '.php_versions[] | select(.major == $build_major) | .minor_versions | map(select(.minor | test("-rc") | not) | .minor | split(".") | .[1] | tonumber) | max | $build_major + "." + tostring')
latest_patch_within_build_minor=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg build_minor "$build_minor_version" '
  .php_versions[]
  | .minor_versions[]
  | select(.minor == $build_minor)
  | (.patch_versions // []) as $patches
  | ($patches | map(select(test("-rc") | not) | split(".") | map(tonumber))) as $parsed
  | if ($parsed | length) > 0 then ($parsed | max | join(".")) else empty end
')
latest_patch_global=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r '
  [
    .php_versions[]
    | .minor_versions[]
    | select(.minor | test("-rc") | not)
    | ((.patch_versions // [])[])
    | select(test("-rc") | not)
    | split(".") | map(tonumber)
  ] as $all
  | if ($all | length) > 0 then ($all | max | join(".")) else empty end
')
# Determine default base OS within the build minor using operating_systems default family and highest available version
default_base_os_within_build_minor=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg build_minor "$build_minor_version" '
  . as $root
  | ($root.operating_systems[] | select(.default == true) | .family) as $defaultFamily
  | ($root.operating_systems[] | select(.family == $defaultFamily) | .versions) as $familyVersions
  | ($root.php_versions[]
     | .minor_versions[]
     | select(.minor == $build_minor)
     | .base_os
     | map(.name)) as $minorBaseOs
  | $familyVersions
  | map(select(.version as $v | $minorBaseOs | index($v)))
  | max_by(.number)
  | .version')

# Determine the build family (alpine/debian) for the selected base OS
build_family=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg base_os "$build_base_os" '
  .operating_systems[]
  | select(([.versions[] | .version] | index($base_os)) != null)
  | .family' | head -n1)

# Determine the latest OS within this family for the current minor
latest_family_os_within_build_minor=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg build_minor "$build_minor_version" --arg family "$build_family" '
  . as $root
  | ($root.operating_systems[] | select(.family == $family) | .versions) as $familyVersions
  | ($root.php_versions[]
     | .minor_versions[]
     | select(.minor == $build_minor)
     | .base_os
     | map(.name)) as $minorBaseOs
  | $familyVersions
  | map(select(.version as $v | $minorBaseOs | index($v)))
  | max_by(.number)
  | .version')

# Determine the default base OS within the build minor considering the variation's supported_os
default_supported_base_os_within_build_minor=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg build_minor "$build_minor_version" --arg variation "$build_variation" '
  . as $root
  | ($root.php_variations[] | select(.name == $variation) | (.supported_os // [])) as $supported
  | ($root.operating_systems[] | select(.default == true) | .family) as $defaultFamily
  | ($root.operating_systems[] | select(.family == $defaultFamily) | .versions) as $familyVersions
  | ($root.php_versions[]
     | .minor_versions[]
     | select(.minor == $build_minor)
     | .base_os
     | map(.name)) as $minorBaseOs
  | $familyVersions
  | map(select(
      .version as $v
      | ($minorBaseOs | index($v)) != null
      and (
        ($supported | length) == 0
        or any($supported[]; . == $v or (. == "alpine" and ($v | startswith("alpine"))))
      )
    ))
  | if length > 0 then (max_by(.number) | .version) else empty end')

# Determine the latest OS within this family for the current minor considering the variation's supported_os
latest_family_supported_os_within_build_minor=$(yq -o=json "$PHP_VERSIONS_FILE" | jq -r --arg build_minor "$build_minor_version" --arg family "$build_family" --arg variation "$build_variation" '
  . as $root
  | ($root.php_variations[] | select(.name == $variation) | (.supported_os // [])) as $supported
  | ($root.operating_systems[] | select(.family == $family) | .versions) as $familyVersions
  | ($root.php_versions[]
     | .minor_versions[]
     | select(.minor == $build_minor)
     | .base_os
     | map(.name)) as $minorBaseOs
  | $familyVersions
  | map(select(
      .version as $v
      | ($minorBaseOs | index($v)) != null
      and (
        ($supported | length) == 0
        or any($supported[]; . == $v or (. == "alpine" and ($v | startswith("alpine"))))
      )
    ))
  | if length > 0 then (max_by(.number) | .version) else empty end')

check_vars \
  "🚨 Missing critical build variable. Check the script logic and logs" \
  build_patch_version \
  build_major_version \
  build_minor_version \
  latest_global_stable_major \
  latest_global_stable_minor \
  latest_minor_within_build_major

echo_color_message green "⚡️ PHP Build Version: $build_patch_version"

echo_color_message yellow "👇 Calculated Build Versions:"
echo "Build Major Version: $build_major_version"
echo "Build Minor Version: $build_minor_version"

echo_color_message yellow "🧐 Queried results from $PHP_VERSIONS_FILE"
echo "Latest Global Major Version: ${latest_global_stable_major:-N/A}"
echo "Latest Global Minor Version: ${latest_global_stable_minor:-N/A}"
echo "Latest Minor Version within Build Major: ${latest_minor_within_build_major:-N/A}"
echo "Latest Patch Version within Build Minor: ${latest_patch_within_build_minor:-N/A}"
echo "Default Base OS within Build Minor: ${default_base_os_within_build_minor:-N/A}"
echo "Build Family: ${build_family:-N/A}"
echo "Latest Family OS within Build Minor: ${latest_family_os_within_build_minor:-N/A}"
echo "Default Supported Base OS within Build Minor: ${default_supported_base_os_within_build_minor:-N/A}"
echo "Latest Supported Family OS within Build Minor: ${latest_family_supported_os_within_build_minor:-N/A}"
echo "Latest Global Patch Version: ${latest_patch_global:-N/A}"

if is_rc_build; then
  echo_color_message yellow "🔶 RC build detected. Stable aliases (minor/major/latest) will be skipped."
fi

# Set default tag
DOCKER_TAGS=""
add_docker_tag "$build_patch_version-$build_variation-$build_base_os"
add_family_alias_if_latest "$build_patch_version-$build_variation-$build_base_os"

# Always allow the variation-only alias for the default base OS, including RC builds
if is_default_base_os; then
  add_docker_tag "$build_patch_version-$build_variation"
fi

# For RC builds, allow publishing the root RC alias when both default OS and default variation are used
if is_rc_build && is_default_base_os && is_default_variation; then
  add_docker_tag "$build_patch_version"
  # Also publish the OS-specific RC alias and its family alias
  add_docker_tag "$build_patch_version-$build_base_os"
  add_family_alias_if_latest "$build_patch_version-$build_base_os"
fi

if is_latest_stable_patch_within_build_minor; then
  add_docker_tag "$build_minor_version-$build_variation-$build_base_os"
  add_family_alias_if_latest "$build_minor_version-$build_variation-$build_base_os"

  if is_default_base_os; then
    add_docker_tag "$build_minor_version-$build_variation"
  fi

  if is_default_variation; then
    add_docker_tag "$build_minor_version-$build_base_os"
    add_family_alias_if_latest "$build_minor_version-$build_base_os"
  fi

  if is_default_base_os && is_default_variation; then
    add_docker_tag "$build_minor_version"
  fi

  if is_latest_minor_within_build_major; then
    add_docker_tag "$build_major_version-$build_variation-$build_base_os"
    add_family_alias_if_latest "$build_major_version-$build_variation-$build_base_os"

    if is_default_base_os; then
        add_docker_tag "$build_major_version-$build_variation"
    fi

    if is_default_variation; then
      add_docker_tag "$build_major_version-$build_base_os"
      add_family_alias_if_latest "$build_major_version-$build_base_os"
    fi

    if is_default_base_os && is_default_variation; then
      add_docker_tag "$build_major_version"
    fi
  fi

  if is_latest_global_patch; then
    add_docker_tag "$build_variation-$build_base_os"
    add_family_alias_if_latest "$build_variation-$build_base_os"

    if is_default_variation; then
      add_docker_tag "$build_base_os"
      add_family_alias_if_latest "$build_base_os"
    fi

    if is_default_base_os; then
      add_docker_tag "$build_variation"
    fi

    if is_default_base_os && is_default_variation; then
      if ci_release_is_production_launch; then
        add_docker_tag "latest"
      elif [[ -n "$DOCKER_TAG_PREFIX" ]]; then
        add_docker_tag "$DOCKER_TAG_PREFIX"
      fi
    fi
  fi
fi

echo_color_message green "🚀 Summary of Docker Tags Being Shipped: $DOCKER_TAGS"

# Save to GitHub's environment
if [[ $CI == "true" ]]; then
  echo "DOCKER_TAGS=${DOCKER_TAGS}" >> $GITHUB_ENV
  echo_color_message green "✅ Saved Docker Tags to GITHUB_ENV"
fi
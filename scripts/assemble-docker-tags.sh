#!/bin/bash
###################################################
# Usage: assemble-docker-tags.sh [--variation <variation> --os <os> --patch-version <patch-version> --latest]
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
CHECKOUT_TYPE="${CHECKOUT_TYPE:-"branch"}"
DEFAULT_IMAGE_VARIATION="${DEFAULT_IMAGE_VARIATION:-"cli"}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-"serversideup/php"}"
DOCKER_TAG_PREFIX="${DOCKER_TAG_PREFIX:-"edge-"}"
PHP_VERSIONS_FILE="${PHP_VERSIONS_FILE:-"scripts/conf/php-versions.yml"}"

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
  docker_tag_suffix=$1
  tag_name="$DOCKER_REPOSITORY:$DOCKER_TAG_PREFIX$docker_tag_suffix"

  if [[ -z "$DOCKER_TAGS" ]]; then
    # Do not prefix with comma
    DOCKER_TAGS+="$tag_name"
  else
    # Add a comma to separate the tags
    DOCKER_TAGS+=",$tag_name"
  fi

  # Trim commas for a better output
  echo_color_message blue "🐳 Set tag: ${tag_name//,}  "
}

function is_latest_stable_patch() {
    [[ "$build_patch_version" == "$latest_patch_within_build_minor" && "$build_patch_version" != *"rc"* ]]
}

function is_latest_minor_within_build_major() {
    [[ "$build_minor_version" == "$latest_minor_within_build_major" && "$build_minor_version" != *"rc"* ]]
}

function is_latest_major() {
    [[ "$build_major_version" == "$latest_global_stable_major" ]]
}

function is_default_base_os() {
    [[ "$build_base_os" == "$default_base_os_within_build_minor" ]]
}

function is_checkout_type_of_latest_stable() {
    [[ "$CHECKOUT_TYPE" == "latest-stable" ]]
}

function is_default_variation() {
    [[ "$PHP_BUILD_VARIATION" == "$DEFAULT_IMAGE_VARIATION" ]]
}

help_menu() {
    echo "Usage: $0 [--variation <variation> --os <os> --patch-version <patch-version> --latest]"
    echo
    echo "This script dives deep into the advanced logic of assembling Docker tags for GitHub Actions."
    echo "If \$CI is \"true\", it outputs the tags to GITHUB_ENV for use in subsequent steps."
    echo "You can run this locally for debugging. The script has beautiful output and can help debug"
    echo "any advanced logic issues."
    echo
    echo "Options:"
    echo "  --variation <variation>   Set the PHP variation (e.g., apache, fpm)"
    echo "  --os <os>                 Set the base OS (e.g., bullseye, bookworm, alpine)"
    echo "  --patch-version <patch-version> Set the PHP patch version (e.g., 7.4.10)"
    echo "  --latest                  Use 'latest-stable' as the checkout type"
    echo
    echo "Environment Variables (Defaults):"
    echo "  CHECKOUT_TYPE             The checkout type (default: branch)"
    echo "  DEFAULT_IMAGE_VARIATION   The default PHP image variation (default: cli)"
    echo "  DOCKER_REPOSITORY         The Docker repository (default: serversideup/php)"
    echo "  DOCKER_TAG_PREFIX         The Docker tag prefix (default: edge-)"
    echo "  PHP_VERSIONS_FILE         Path to PHP versions file (default: scripts/conf/php-versions.yml)"
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
        --latest)
        DOCKER_TAG_PREFIX=""
        CHECKOUT_TYPE="latest-stable"
        shift 1
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
  DOCKER_REPOSITORY \
  PHP_VERSIONS_FILE \
  CHECKOUT_TYPE

if [[ ! -f $PHP_VERSIONS_FILE ]]; then
  echo_color_message red "🚨 PHP Versions file not found at $PHP_VERSIONS_FILE"
  echo "Current directory: $(pwd)"
  echo "Contents of $(dirname $PHP_VERSIONS_FILE): $(ls -al $(dirname $PHP_VERSIONS_FILE))"
  echo "Contents of the file:"
  cat $PHP_VERSIONS_FILE
  exit 1
fi

# Store arguments
build_patch_version=$PHP_BUILD_VERSION
build_base_os=$PHP_BUILD_BASE_OS
build_variation=$PHP_BUILD_VARIATION

# Extract major and minor versions from build_patch_version
build_major_version="${build_patch_version%%.*}"
build_minor_version="${build_patch_version%.*}"

# Fetch version data from the PHP Versions file
latest_global_stable_major=$(yq -o=json $PHP_VERSIONS_FILE | jq -r '[.php_versions[] | select(.major | test("-rc") | not) | .major | tonumber] | max | tostring')
latest_global_stable_minor=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg latest_global_stable_major "$latest_global_stable_major" '.php_versions[] | select(.major == $latest_global_stable_major) | .minor_versions | map(select(.minor | test("-rc") | not) | .minor | split(".") | .[1] | tonumber) | max | $latest_global_stable_major + "." + tostring')
latest_minor_within_build_major=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg build_major "$build_major_version" '.php_versions[] | select(.major == $build_major) | .minor_versions | map(select(.minor | test("-rc") | not) | .minor | split(".") | .[1] | tonumber) | max | $build_major + "." + tostring')
latest_patch_within_build_minor=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg build_minor "$build_minor_version" '.php_versions[] | .minor_versions[] | select(.minor == $build_minor) | .patch_versions | map( split(".") | map(tonumber) ) | max | join(".")')
default_base_os_within_build_minor=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg build_minor "$build_minor_version" '.php_versions[] | .minor_versions[] | select(.minor == $build_minor) | .base_os[] | select(.default == true) | .name')

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
echo "Latest Global Major Version: $latest_global_stable_major"
echo "Latest Global Minor Version: $latest_global_stable_minor"
echo "Latest Minor Version within Build Major: $latest_minor_within_build_major"
echo "Latest Patch Version within Build Minor: $latest_patch_within_build_minor"
echo "Default Base OS within Build Minor: $default_base_os_within_build_minor"

# Set default tag
DOCKER_TAGS=""
add_docker_tag "$build_patch_version-$build_variation-$build_base_os"

if is_default_base_os; then
  add_docker_tag "$build_patch_version-$build_variation"
fi

if is_latest_stable_patch; then
  add_docker_tag "$build_minor_version-$build_variation-$build_base_os"

  if is_default_base_os; then
    add_docker_tag "$build_minor_version-$build_variation"
  fi

  if is_default_variation; then
    add_docker_tag "$build_minor_version-$build_base_os"
  fi

  if is_default_base_os && is_default_variation; then
    add_docker_tag "$build_minor_version"
  fi

  if is_latest_minor_within_build_major; then
    add_docker_tag "$build_major_version-$build_variation-$build_base_os"

    if is_default_base_os; then
        add_docker_tag "$build_major_version-$build_variation"
    fi

    if is_default_base_os && is_default_variation; then
      add_docker_tag "$build_major_version"
    fi

    if is_latest_major && is_default_variation; then
      add_docker_tag "$build_base_os"
      
      if is_default_base_os && is_checkout_type_of_latest_stable && is_default_variation; then
        add_docker_tag "latest"
      fi
    fi
  fi
fi

echo_color_message green "🚀 Summary of Docker Tags Being Shipped: $DOCKER_TAGS"

# Save to GitHub's environment
if [[ $CI == "true" ]]; then
  echo "DOCKER_TAGS=${DOCKER_TAGS}" >> $GITHUB_ENV
  echo_color_message green "✅ Saved Docker Tags to "GITHUB_ENV""
fi
#/bin/bash
set -e

##########################
# Environment Settings

# Script variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Required variables to set
PHP_BUILD_VARIATION="${PHP_BUILD_VARIATION:-"$1"}"
PHP_BUILD_VERSION="${PHP_BUILD_VERSION:-"$2"}"
PHP_BUILD_BASE_OS="${PHP_BUILD_BASE_OS:-"$3"}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-"serversideup/php-pro-$PHP_BUILD_VARIATION"}"
PHP_VERSIONS_FILE="${PHP_VERSIONS_FILE:-"$SCRIPT_DIR/conf/php-versions.yml"}"
DEFAULT_BASE_OS="${DEFAULT_BASE_OS:-"bookworm"}"
CHECKOUT_TYPE="${CHECKOUT_TYPE:-"branch"}"

# Support auto tagging of "edge" builds
if [[ -z "$DOCKER_TAG_PREFIX" && "$CHECKOUT_TYPE" == "branch" ]]; then
  DOCKER_TAG_PREFIX="edge-"
else
  DOCKER_TAG_PREFIX="${DOCKER_TAG_PREFIX:-""}"
fi

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

assemble_docker_tags() {
  # Store arguments
  build_patch_version=$1
  build_base_os=$2

  # Extract major and minor versions from build_patch_version
  build_major_version="${build_patch_version%%.*}"
  build_minor_version="${build_patch_version%.*}"

  # Fetch version data from the PHP
  latest_global_major=$(yq e '.php_versions[-1].major' $PHP_VERSIONS_FILE)
  latest_global_minor=$(yq e ".php_versions[] | select(.major == \"$latest_global_major\") | .minor_versions[-1].minor" $PHP_VERSIONS_FILE)
  latest_minor_within_build_major=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg bmv "$build_major_version" '.php_versions[] | select(.major == $bmv) | .minor_versions | map(.minor | split(".") | .[1] | tonumber) | max | $bmv + "." + tostring')
  latest_patch_within_build_minor=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg bmv "$build_minor_version" '.php_versions[] | .minor_versions[] | select(.minor == $bmv) | .patch_versions | map( split(".") | map(tonumber) ) | max | join(".")')

  check_vars \
    "🚨 Missing critical build variable. Check the script logic and logs" \
    build_patch_version \
    build_major_version \
    build_minor_version \
    latest_global_major \
    latest_global_minor \
    latest_minor_within_build_major \
    latest_patch_within_build_minor

  echo_color_message green "⚡️ PHP Build Version: $build_patch_version"

  echo_color_message yellow "👇 Calculated Build Versions:"
  echo "Build Major Version: $build_major_version"
  echo "Build Minor Version: $build_minor_version"

  echo_color_message yellow "🧐 Queried results from $PHP_VERSIONS_FILE"
  echo "Latest Global Major Version: $latest_global_major"
  echo "Latest Global Minor Version: $latest_global_minor"
  echo "Latest Minor Version within Build Major: $latest_minor_within_build_major"
  echo "Latest Patch Version within Build Minor: $latest_patch_within_build_minor"
  
  # Set default tag
  DOCKER_TAGS=""
  add_docker_tag "$build_patch_version"
  add_docker_tag "$build_patch_version-$build_base_os"

  if [[ "$build_patch_version" == "$latest_patch_within_build_minor" ]]; then
    add_docker_tag "$build_minor_version-$build_base_os"
    if [[ "$build_base_os" == "$DEFAULT_BASE_OS" ]]; then
      add_docker_tag "$build_minor_version"
    fi
  fi

  if [[ "$build_minor_version" == "$latest_minor_within_build_major" ]]; then
    add_docker_tag "$build_major_version-$build_base_os"
    if [[ "$build_base_os" == "$DEFAULT_BASE_OS" ]]; then
      add_docker_tag "$build_major_version"
    fi
  fi

  if [[ "$build_major_version" == "$latest_global_major" ]]; then
    add_docker_tag "$build_base_os"
    if [[ "$build_base_os" == "$DEFAULT_BASE_OS" && "$CHECKOUT_TYPE" == "latest-stable" ]]; then
      add_docker_tag "latest"
    fi
  fi

  echo_color_message green "🚀 Summary of Docker Tags Being Shipped: $DOCKER_TAGS"

  # Save to GitHub's environment
  if [[ $CI == "true" ]]; then
    echo "DOCKER_TAGS=${DOCKER_TAGS}" >> $GITHUB_ENV
    echo_color_message green "✅ Saved Docker Tags to "GITHUB_ENV""
  fi
}

##########################
# Main Script

# Check that all required variables are set
check_vars \
  "🚨 Required variables not set" \
  PHP_BUILD_VARIATION \
  PHP_BUILD_VERSION \
  PHP_BUILD_BASE_OS \
  DOCKER_REPOSITORY \
  PHP_VERSIONS_FILE \
  DEFAULT_BASE_OS \
  CHECKOUT_TYPE

if [[ ! -f $PHP_VERSIONS_FILE ]]; then
  echo_color_message red "🚨 PHP Versions file not found at $PHP_VERSIONS_FILE"
  exit 1
fi

assemble_docker_tags $PHP_BUILD_VERSION $PHP_BUILD_BASE_OS
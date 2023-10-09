#/bin/bash
set -oue pipefail

##########################
# Environment Settings

# Required variables to set
PHP_BUILD_VARIATION="${PHP_BUILD_VARIATION:-"$1"}"
PHP_BUILD_VERSION="${PHP_BUILD_VERSION:-"$2"}"
PHP_BUILD_BASE_OS="${PHP_BUILD_BASE_OS:-"$3"}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-"serversideup/php-pro"}"
PHP_VERSIONS_FILE="${PHP_VERSIONS_FILE:-"scripts/conf/php-versions.yml"}"
DEFAULT_IMAGE_VARIATION="${DEFAULT_IMAGE_VARIATION:-"cli"}"
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
    [[ "$build_base_os" == "$DEFAULT_BASE_OS" ]]
}

function is_checkout_type_of_latest_stable() {
    [[ "$CHECKOUT_TYPE" == "latest-stable" ]]
}

function is_default_variation() {
    [[ "$PHP_BUILD_VARIATION" == "$DEFAULT_IMAGE_VARIATION" ]]
}

assemble_docker_tags() {
  # Store arguments
  build_patch_version=$1
  build_base_os=$2
  build_variation=$3

  # Extract major and minor versions from build_patch_version
  build_major_version="${build_patch_version%%.*}"
  build_minor_version="${build_patch_version%.*}"

  # Fetch version data from the PHP
  latest_global_stable_major=$(yq -o=json $PHP_VERSIONS_FILE | jq -r '[.php_versions[] | select(.major | test("-rc") | not) | .major | tonumber] | max | tostring')
  latest_global_stable_minor=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg latest_global_stable_major "$latest_global_stable_major" '.php_versions[] | select(.major == $latest_global_stable_major) | .minor_versions | map(select(.minor | test("-rc") | not) | .minor | split(".") | .[1] | tonumber) | max | $latest_global_stable_major + "." + tostring')
  latest_minor_within_build_major=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg build_major "$build_major_version" '.php_versions[] | select(.major == $build_major) | .minor_versions | map(select(.minor | test("-rc") | not) | .minor | split(".") | .[1] | tonumber) | max | $build_major + "." + tostring')
  latest_patch_within_build_minor=$(yq -o=json $PHP_VERSIONS_FILE | jq -r --arg build_minor "$build_minor_version" '.php_versions[] | .minor_versions[] | select(.minor == $build_minor) | .patch_versions | map( split(".") | map(tonumber) ) | max | join(".")')

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
  
  # Set default tag
  DOCKER_TAGS=""
  add_docker_tag "$build_patch_version-$build_variation-$build_base_os"

  if is_default_base_os; then
    add_docker_tag "$build_patch_version-$build_variation"
  fi

  if is_latest_stable_patch; then
    add_docker_tag "$build_minor_version-$build_variation-$build_base_os"

    if is_default_variation; then
      add_docker_tag "$build_minor_version-$build_base_os"
    fi

    if is_default_base_os && is_default_variation; then
      add_docker_tag "$build_minor_version"
    fi

    if is_latest_minor_within_build_major; then
      add_docker_tag "$build_major_version-$build_variation-$build_base_os"

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
  echo "Current directory: $(pwd)"
  echo "Contents of $(dirname $PHP_VERSIONS_FILE): $(ls -al $(dirname $PHP_VERSIONS_FILE))"
  echo "Contents of the file:"
  cat $PHP_VERSIONS_FILE
  exit 1
fi

assemble_docker_tags $PHP_BUILD_VERSION $PHP_BUILD_BASE_OS $PHP_BUILD_VARIATION
#/bin/bash
set -e

##########################
# Environment Settings

# Script variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Required variables to set
PHP_BUILD_VERSION="${PHP_BUILD_VERSION:-"$1"}"
PHP_BUILD_VARIATION="${PHP_BUILD_VARIATION:-"$2"}"
PHP_BUILD_BASE_OS="${PHP_BUILD_BASE_OS:-"$3"}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-"serversideup/php-pro-$PHP_BUILD_VARIATION"}"
PHP_VERSIONS_FILE="${PHP_VERSIONS_FILE:-"$SCRIPT_DIR/conf/php-versions.yml"}"
DEFAULT_BASE_OS="${DEFAULT_BASE_OS:-"bookworm"}"



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
  for var_name in "$@"; do
    if [ -z "${!var_name}" ]; then
      echo "Variable $var_name is unset or empty."
      return 1
    fi
  done
  return 0
}

echo_tag_set() {
  echo_color_message blue "🐳 Set tag: $1"
}

assemble_docker_tags() {
  # Store arguments
  php_build_version=$1

  # Extract major and minor versions from php_build_version
  build_major_version="${php_build_version%%.*}"
  build_minor_version="${php_build_version%.*}"

  # Fetch version data from the PHP
  latest_global_major=$(yq e '.php_versions[-1].major' $PHP_VERSIONS_FILE)
  latest_global_minor=$(yq e ".php_versions[] | select(.major == \"$latest_global_major\") | .minor_versions[-1].minor" $PHP_VERSIONS_FILE)
  latest_minor_within_build_major=$(yq e ".php_versions[] | select(.major == \"$build_major_version\") | .minor_versions[-1].minor" $PHP_VERSIONS_FILE)
  latest_patch_within_build_minor=$(yq e ".php_versions[] | select(.major == \"$build_major_version\") | .minor_versions[] | select(.minor == \"$build_minor_version\") | .patch_versions[-1]" $PHP_VERSIONS_FILE)

  echo_color_message yellow "⚡️ PHP Build Version: $php_build_version"

  echo_color_message yellow "👇 Calculated Build Versions:"
  echo "Build Major Version: $build_major_version"
  echo "Build Minor Version: $build_minor_version"

  echo_color_message yellow "🧐 Queried results from $PHP_VERSIONS_FILE"
  echo "Latest Global Major Version: $latest_global_major"
  echo "Latest Global Minor Version: $latest_global_minor"
  echo "Latest Minor Version within Build Major: $latest_minor_within_build_major"
  echo "Latest Patch Version within Build Minor: $latest_patch_within_build_minor"
  
  # Set default tag
  DOCKER_TAGS="$DOCKER_REPOSITORY:$1"

  echo_tag_set "$DOCKER_TAGS"



# # Fetch the latest minor version for the given major version
# latest_minor=$(yq e ".php_versions[] | select(.major == \"$major_version\") | .minor_versions[-1].minor" versions.yml)

# # Check if the given php_build_version minor version is the latest
# if [[ "$minor_version" == "$latest_minor" ]]; then
#     echo "It's the latest minor version for major version $major_version."
# else
#     echo "It's not the latest minor version for major version $major_version."
# fi

# # Fetch the latest patch version for the given major.minor version
# latest_patch=$(yq e ".php_versions[] | select(.major == \"$major_version\") | .minor_versions[] | select(.minor == \"$minor_version\") | .patch_versions[-1]" versions.yml)

# # Check if the given php_build_version is the latest patch version for its major.minor version
# if [[ "$php_build_version" == "$latest_patch" ]]; then
#     echo "It's the latest patch version for $minor_version."
# else
#     echo "It's not the latest patch version for $minor_version."
# fi

# # Save to GitHub's environment
# echo "DOCKER_TAGS=${DOCKER_TAGS}" >> $GITHUB_ENV
}

##########################
# Main Script

# Check that all required variables are set
check_vars \
  DOCKER_REPOSITORY \
  PHP_VERSIONS_FILE \
  DEFAULT_BASE_OS \
  PHP_BUILD_VERSION \
  PHP_BUILD_VARIATION \
  PHP_BUILD_BASE_OS

assemble_docker_tags $PHP_BUILD_VERSION
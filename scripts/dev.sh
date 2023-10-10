#!/bin/bash

#exit on error
set -oue pipefail

##########################
# Environment Settings

# Script Configurations
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT_DIR="$(dirname "$SCRIPT_DIR")"


PHP_BUILD_VERSION="${PHP_BUILD_VERSION:-"$1"}"
PHP_BUILD_VARIATION="${PHP_BUILD_VARIATION:-"$2"}"
PHP_BUILD_BASE_OS="${PHP_BUILD_BASE_OS:-"$3"}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-"serversideup/php-pro"}"

# UI Colors
function ui_set_yellow {
    printf $'\033[0;33m'
}

function ui_set_green {
    printf $'\033[0;32m'
}

function ui_set_red {
    printf $'\033[0;31m'
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

build_docker_image() {
  echo_color_message yellow "🐳 Building Docker Image: $DOCKER_REPOSITORY:$PHP_BUILD_VERSION-$PHP_BUILD_VARIATION-$PHP_BUILD_BASE_OS"
  docker build \
    --build-arg PHP_VARIATION="$PHP_BUILD_VARIATION" \
    --build-arg PHP_VERSION="$PHP_BUILD_VERSION" \
    --build-arg BASE_OS_VERSION="$PHP_BUILD_BASE_OS" \
    --tag "$DOCKER_REPOSITORY:$PHP_BUILD_VERSION-$PHP_BUILD_VARIATION-$PHP_BUILD_BASE_OS" \
    --file "$PROJECT_ROOT_DIR/src/variations/$PHP_BUILD_VARIATION/Dockerfile" \
    "$PROJECT_ROOT_DIR"
  echo_color_message green "✅ Docker Image Built: $DOCKER_REPOSITORY:$PHP_BUILD_VERSION-$PHP_BUILD_VARIATION-$PHP_BUILD_BASE_OS"
}

##########################
# Main script starts here
check_vars \
  "🚨 Required variables not set" \
  PHP_BUILD_VARIATION \
  PHP_BUILD_VERSION \
  PHP_BUILD_BASE_OS \

build_docker_image
#!/bin/bash

#exit on error
set -oe pipefail

##########################################################################
# Usage: build.sh --variation <variation> --version <version> --os <os>
##########################################################################
# This script is used to build a Docker image for a specific PHP version
# and variation. It is intended to be used for local development. You may
# also change the DOCKER_REPOSITORY environment variable or pass other
# arguments to the docker build command, like "--no-cache".

##########################
# Environment Settings

# Script Configurations
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BASE_PHP_VERSIONS_CONFIG_FILE="${BASE_PHP_VERSIONS_CONFIG_FILE:-"$SCRIPT_DIR/conf/php-versions-base-config.yml"}"


PHP_BUILD_VERSION=""
PHP_BUILD_VARIATION=""
PHP_BUILD_BASE_OS=""
PHP_BUILD_PREFIX=""
DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-"serversideup/php"}"
DOCKER_ADDITIONAL_BUILD_ARGS=()
PUSH_TO_REGISTRY=false
PLATFORM=""
PHP_FROM_SOURCE=false

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
      echo
      help_menu
      return 1
    fi
  done
  return 0
}

detect_platform() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64)
            echo "linux/amd64"
            ;;
        arm64|aarch64)
            echo "linux/arm64/v8"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
}

php_minor_version() {
  if [[ "$1" == *-rc ]]; then
    echo "$1"
  else
    echo "$1" | cut -d. -f1,2
  fi
}

build_php_base_image() {
  local sapi base_line version context_dir
  sapi=$(VARIATION="$PHP_BUILD_VARIATION" yq -r '.php_variations[] | select(.name == env(VARIATION)) | .base_sapi' "$BASE_PHP_VERSIONS_CONFIG_FILE")
  base_line=$("$SCRIPT_DIR/generate-php-base.sh" --version "$PHP_BUILD_VERSION" --os "$PHP_BUILD_BASE_OS" --sapi "$sapi")
  read -r version _ _ context_dir <<< "$base_line"
  BASE_IMAGE="serversideup/php-base:${version}-${sapi}-${PHP_BUILD_BASE_OS}"

  echo_color_message yellow "🐳 Building PHP $version from source: $BASE_IMAGE"
  docker buildx build --platform "$PLATFORM" --tag "$BASE_IMAGE" "$context_dir"
  echo_color_message green "✅ PHP Base Image Built: $BASE_IMAGE"
}

build_docker_image() {
  build_tag="${DOCKER_REPOSITORY}:${PHP_BUILD_PREFIX}${PHP_BUILD_VERSION}-${PHP_BUILD_VARIATION}-${PHP_BUILD_BASE_OS}"
  echo_color_message yellow "🐳 Building Docker Image: $build_tag"

  # Set default platform if not specified
  if [ -z "$PLATFORM" ]; then
      PLATFORM=$(detect_platform)
  fi

  if [ "$PHP_FROM_SOURCE" = true ]; then
    build_php_base_image
  fi
  
  # Assemble build arguments
  local build_args=()
  if [ -n "$BASE_IMAGE" ]; then
    build_args+=(--build-arg "BASE_IMAGE=$BASE_IMAGE")
  fi
  build_args+=(--build-arg PHP_VARIATION="$PHP_BUILD_VARIATION")
  build_args+=(--build-arg PHP_VERSION="$PHP_BUILD_VERSION")
  build_args+=(--build-arg BASE_OS_VERSION="$PHP_BUILD_BASE_OS")

  if [ -n "$NGINX_VERSION" ] && [ "$PHP_BUILD_VARIATION" = "fpm-nginx" ]; then
    build_args+=(--build-arg "NGINX_VERSION=$NGINX_VERSION")
  fi

  if [ -n "$PHP_EXTENSION_OVERRIDES" ]; then
    build_args+=(--build-arg "PHP_EXTENSION_OVERRIDES=$PHP_EXTENSION_OVERRIDES")
  fi

  docker buildx build \
    "${DOCKER_ADDITIONAL_BUILD_ARGS[@]}" \
    --platform "$PLATFORM" \
    "${build_args[@]}" \
    --tag "$build_tag" \
    --file "$PROJECT_ROOT_DIR/src/variations/$PHP_BUILD_VARIATION/Dockerfile" \
    "$PROJECT_ROOT_DIR"
  echo_color_message green "✅ Docker Image Built: $build_tag"
  
  if [ "$PUSH_TO_REGISTRY" = true ]; then
    echo_color_message yellow "🚀 Pushing image to registry: $build_tag"
    docker push "$build_tag"
    echo_color_message green "✅ Image pushed to registry: $build_tag"
  fi
}

help_menu() {
    echo "Usage: $0 --variation <variation> --version <version> --os <os> [additional options]"
    echo
    echo "This script is used to build a Docker image for a specific PHP version"
    echo "and variation. It is intended to be used for local development. You may"
    echo "also change the DOCKER_REPOSITORY environment variable or pass other"
    echo "arguments to the docker build command."
    echo
    echo "Options:"
    echo "  --variation <variation>   Set the PHP variation (e.g., apache, fpm)"
    echo "  --version <version>       Set the PHP version (e.g., 8.4, 8.5, or a pinned patch like 8.1.34)"
    echo "  --os <os>                 Set the base OS (e.g., bookworm, trixie, alpine3.24)"
    echo "  --prefix <prefix>         Set the prefix for the Docker image (e.g., beta)"
    echo "  --registry <registry>     Set a custom registry (e.g., localhost:5000)"
    echo "  --platform <platform>     Set the platform (default: detected from system architecture)"
    echo "  --push                    Push the image to the registry"
    echo "  --php-from-source         Compile PHP from php.net into serversideup/php-base first and build on it"
    echo "  --*                       Any additional options will be passed to the docker buildx command"
}

##########################
# Main script starts here

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
        --version)
        PHP_BUILD_VERSION="$2"
        shift 2
        ;;
        --prefix)
        PHP_BUILD_PREFIX="$2-"
        shift 2
        ;;
        --registry)
        DOCKER_REPOSITORY="$2"
        shift 2
        ;;

        --platform)
        PLATFORM="$2"
        shift 2
        ;;
        --php-from-source)
        PHP_FROM_SOURCE=true
        shift
        ;;
        --*)
        # If there's a next argument and it starts with '--', treat the current argument as standalone.
        # Otherwise, pair the current argument with the next.
        if [[ $# -gt 1 && $2 =~ ^-- ]]; then
            DOCKER_ADDITIONAL_BUILD_ARGS+=("$1")
            shift
        else
            DOCKER_ADDITIONAL_BUILD_ARGS+=("$1")
            [[ $# -gt 1 ]] && DOCKER_ADDITIONAL_BUILD_ARGS+=("$2") && shift
            shift
        fi
        ;;
        *)
        # Skip the argument if not recognized
        shift
        ;;
    esac
done


check_vars \
  "🚨 Required variables not set" \
  PHP_BUILD_VARIATION \
  PHP_BUILD_VERSION \
  PHP_BUILD_BASE_OS

# Auto-resolve PHP extension source overrides for the minor version being built
if [ -z "$PHP_EXTENSION_OVERRIDES" ]; then
  PHP_EXTENSION_OVERRIDES=$(MINOR="$(php_minor_version "$PHP_BUILD_VERSION")" yq -r '
    [(.php_extension_overrides // [] | .[]), (.php_versions[].minor_versions[] | select(.minor == env(MINOR)) | .php_extension_overrides // [] | .[])] | join(" ")
  ' "$BASE_PHP_VERSIONS_CONFIG_FILE")

  if [ -n "$PHP_EXTENSION_OVERRIDES" ]; then
    echo_color_message green "✅ Using PHP extension overrides '$PHP_EXTENSION_OVERRIDES' for PHP '$PHP_BUILD_VERSION'"
  fi
fi

# Auto-resolve NGINX version for fpm-nginx if not provided
if [ -z "$NGINX_VERSION" ] && [ "$PHP_BUILD_VARIATION" = "fpm-nginx" ]; then
  if ! command -v yq >/dev/null 2>&1; then
    echo_color_message red "yq is required but not found. Install 'yq' (https://github.com/mikefarah/yq) to continue."
    exit 1
  fi

  NGINX_VERSION=$(BASE_OS="$PHP_BUILD_BASE_OS" yq -r '.operating_systems[].versions[] | select(.version == env(BASE_OS)) | .nginx_version' "$BASE_PHP_VERSIONS_CONFIG_FILE")

  if [ -z "$NGINX_VERSION" ] || [ "$NGINX_VERSION" = "null" ]; then
    echo_color_message red "❌ Unable to determine NGINX version for OS '$PHP_BUILD_BASE_OS' from $BASE_PHP_VERSIONS_CONFIG_FILE"
    echo
    echo "Ensure an entry exists under 'operating_systems' with version: $PHP_BUILD_BASE_OS and a valid 'nginx_version' key."
    exit 1
  fi

  echo_color_message green "✅ Using NGINX version '$NGINX_VERSION' for OS '$PHP_BUILD_BASE_OS'"
fi

build_docker_image
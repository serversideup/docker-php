#!/bin/bash

##########################
# Bash settings

#exit on error
set -e

##########################
# Environment Settings
DEV_UPSTREAM_CHANNEL="beta-"
DEV_BASE_OS_VERSION="ubuntu-22.04"

##########################
# Execute other build script

# Run a build and include all variables
source ./build.sh

##########################
# Functions

function build (){
        label=$(echo $1 | tr '[:lower:]' '[:upper:]')
        ui_set_yellow && echo "⚡️ Running build for $label - ${2} ..." && ui_reset_colors  

        # Commenting out Buildx because it does not support multi-arch images locally, yet
        #docker buildx build --build-arg UPSTREAM_CHANNEL="$upstream_channel_setting" --platform linux/amd64,linux/arm64 -t "${DEVELOPMENT_REPO_URL}/php:${2}-$1" --push $OUTPUT_DIR/$2/$1/

        # Use "docker build"
        docker build \
            --build-arg UPSTREAM_CHANNEL="${DEV_UPSTREAM_CHANNEL}" \
            --build-arg BASE_OS_VERSION="${DEV_BASE_OS_VERSION}" \
            -t "serversideup/php:beta-${2}-$1" \
            $OUTPUT_DIR/$2/$1/
}

function build_versions {
    # Grab each PHP version defined in `build.sh` and deploy these images to our LOCAL registry
    for version in ${phpVersions[@]}; do
        build cli ${version[$i]} 
        build fpm ${version[$i]}
        build fpm-apache ${version[$i]}
        build fpm-nginx ${version[$i]}
    done
}

##########################
# Main script starts here
build_versions
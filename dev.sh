#!/bin/bash

##########################
# Bash settings

# #exit on error
set -e

# perform cleanup on error
trap 'catch' EXIT

##########################
# Variables and font colors

# Set to match our local development docker registry
DEVELOPMENT_REPO_URL="localhost:5000"

##########################
# Execute other build script

# Run a build and include all variables
source ./build.sh

##########################
# Functions

function cleanup {
    # Set all files back to original repo name
    find $SCRIPT_DIR/$OUTPUT_DIR/ -name 'Dockerfile' -exec sed -i.bak "s/FROM $DEVELOPMENT_REPO_URL\/php/FROM serversideup\/php/" {} \; 
    remove_backup_files
}

function catch {
    if [ "$?" != "0" ]; then
        ui_set_red && echo "❌ An error has occurred, see above. Cleaning things up..." && ui_reset_colors
        # error handling goes here
        cleanup
    fi
}

function set_local_registry {

    # Unfortunately I have to use a workaround here to make it Linux & macOS friendly (https://stackoverflow.com/a/44864004)
    # Temporarily set images to our local registry. 
    find $SCRIPT_DIR/$OUTPUT_DIR/ -name 'Dockerfile' -exec sed -i.bak "s/FROM serversideup\/php/FROM $DEVELOPMENT_REPO_URL\/php/" {} \;

    remove_backup_files
}

function remove_backup_files {
    # Remove our temporary backup files (related to https://stackoverflow.com/a/44864004)
    find $SCRIPT_DIR/$OUTPUT_DIR -name '*.bak' -exec rm {} \;
}

function build (){
        label=$(echo $1 | tr '[:lower:]' '[:upper:]')
        ui_set_yellow && echo "⚡️ Running build for $label - ${2} ..." && ui_reset_colors       
        docker build -t "${DEVELOPMENT_REPO_URL}/php:${2}-cli" $OUTPUT_DIR/${2}/cli/
        docker push "${DEVELOPMENT_REPO_URL}/php:${2}-cli"
}

function deploy {
    # Grab each PHP version defined in `build.sh` and deploy these images to our LOCAL registry
    for version in ${phpVersions[@]}; do
        build cli ${version[$i]}
        build fpm ${version[$i]}
        build fpm-apache ${version[$i]}
        build fpm-ngix ${version[$i]}
    done
}

##########################
# Main script starts here

set_local_registry
deploy
cleanup
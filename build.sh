#!/bin/bash

# exit when any command fails
set -ex

###########################################################################################
# PHP VERSIONS: Set these to match what's available in `/variables.yaml`
###########################################################################################

if [ $# -eq 0 ]; then
    # Set versions
    phpVersions=(
        7.4
        8.0
        8.1
    )
else
    phpVersions=$1
fi

###########################################################################################
# Build script: Don't change anything below this line, unless you know what you're doing
###########################################################################################

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

# Script Configurations
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TEMPLATE_DIR=src
OUTPUT_DIR=dist

# Grab each PHP version from above and go through these steps
for version in ${phpVersions[@]}; do

    # Copy over template directory
    rsync -a $TEMPLATE_DIR/ $SCRIPT_DIR/$OUTPUT_DIR/${version[$i]} --delete

    # Apply Jinja2 templates using "Yasha"
    find $SCRIPT_DIR/$OUTPUT_DIR/${version[$i]} -name '*.j2' -exec yasha --php_version=$version -v $SCRIPT_DIR/variables.yaml {} \;

    # Remove old applied template files
    find $SCRIPT_DIR/$OUTPUT_DIR/${version[$i]} -name '*.j2' -exec rm {} \;

    ui_set_green && echo "✅ Template build has completed for PHP ${version[$i]}" && ui_reset_colors

done
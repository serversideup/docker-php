#!/bin/bash
#set -x
set -e

##########################
# Environment Settings

# Manual setting for PHP RC versions. Change this to add or remove RC versions.
# Separate each version with a space. Example: ("8.3-rc" "8.4-rc")
PHP_RC_VERSIONS=("8.3-rc")

# Script variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# PHP Versions JSON feed URL
PHP_VERSIONS_ACTIVE_JSON_FEED="${PHP_VERSIONS_ACTIVE_JSON_FEED:-"https://www.php.net/releases/active.php"}"

# File settings
ADDITIONAL_PHP_VERSIONS_CONFIG_FILE="${ADDITIONAL_PHP_VERSIONS_CONFIG_FILE:-"$SCRIPT_DIR/conf/php-additional-versions.yml"}"
DOWNLOADED_PHP_VERSIONS_CONFIG_FILE="$SCRIPT_DIR/conf/php-versions-downloaded.yml.tmp"
FINAL_PHP_VERSIONS_CONFIG_FILE="$SCRIPT_DIR/conf/php-versions.yml"

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

function save_php_version_data_from_url {
    echo_color_message yellow "⚡️ Getting PHP Versions..."
    # Fetch the JSON from the PHP website
    local json_data=$(curl -s $PHP_VERSIONS_ACTIVE_JSON_FEED)

    rc_version_additions=""
    
    if [[ ${#PHP_RC_VERSIONS[@]} -ne 0 ]]; then  # If PHP_RC_VERSIONS is not empty:
        for rc_version in "${PHP_RC_VERSIONS[@]}"; do
            rc_jq="{
                \"minor\": \"$rc_version\",
                \"release_candidate\": true,
                \"patch\": [\"$rc_version\"]
            }"
            # Add each RC version to the end of the .php_versions[0].minor_versions array.
            rc_version_additions+=" | .php_versions[0].minor_versions += [$rc_jq]"
        done
    fi

    # Parse the fetched JSON data and transform it to a specific YAML structure using jq and yq.
    local yaml_data=$(echo "$json_data" | jq -r "
    {
        \"php_versions\": [
        . as \$major |
        to_entries[] |
        {
            \"major\": .key,
            \"minor_versions\": [
            .value |
            to_entries[] |
            {
                \"minor\": .key,
                \"patch_versions\": [ .value.version | tostring ]
            }
            ]
        }
        ]
    }
    $rc_version_additions" | yq eval -P -)

    # Save the transformed YAML data to the designated file (PHP_VERSIONS_CONFIG_FILE).
    echo "$yaml_data" > $DOWNLOADED_PHP_VERSIONS_CONFIG_FILE

    echo_color_message green "✅ PHP Version data downloaded from $PHP_VERSIONS_ACTIVE_JSON_FEED"
}

function finalize_php_version_data {
    # Move the downloaded PHP versions file to the final file.
    mv $DOWNLOADED_PHP_VERSIONS_CONFIG_FILE $FINAL_PHP_VERSIONS_CONFIG_FILE

    echo_color_message green "✅ Data is finalized compiled into $FINAL_PHP_VERSIONS_CONFIG_FILE"

    cat $FINAL_PHP_VERSIONS_CONFIG_FILE

    echo_color_message green "✅ Saved PHP versions to $FINAL_PHP_VERSIONS_CONFIG_FILE"
}

function merge_php_version_data {

    echo_color_message yellow "⚡️ Combining data from $ADDITIONAL_PHP_VERSIONS_CONFIG_FILE..."
    
    # Combine the files
    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' $DOWNLOADED_PHP_VERSIONS_CONFIG_FILE $ADDITIONAL_PHP_VERSIONS_CONFIG_FILE -i $DOWNLOADED_PHP_VERSIONS_CONFIG_FILE

    # Sort the patches
    yq eval '.php_versions[] .minor_versions[] .patch_versions |= sort' $DOWNLOADED_PHP_VERSIONS_CONFIG_FILE -i

    # Remove duplicates
    yq eval '.php_versions[].minor_versions[].patch_versions |= unique' $DOWNLOADED_PHP_VERSIONS_CONFIG_FILE -i
}


##########################
# Main script starts here

if [[ "$CI" == "true" ]] && (! command -v jq &> /dev/null || ! command -v yq &> /dev/null); then
  echo_color_message yellow "🏃‍♂️ CI is true and either jq or yq is not installed"
  echo_color_message yellow "⬇️ Installing jq and yq..."
  source $SCRIPT_DIR/install-jq-and-yq.sh
fi

save_php_version_data_from_url

if [ -f $ADDITIONAL_PHP_VERSIONS_CONFIG_FILE ]; then
    merge_php_version_data
fi

finalize_php_version_data
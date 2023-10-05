#!/bin/bash
#set -x
set -e

##########################
# Environment Settings
BUILD_BUILD_CONFIG_FILE="${BUILD_BUILD_CONFIG_FILE:-"build-config.yml"}"
PHP_VERSIONS_CONFIG_FILE="${PHP_VERSIONS_CONFIG_FILE:-"php-versions-conf.yml"}"
PHP_VERSIONS_ACTIVE_JSON_FEED="${PHP_VERSIONS_ACTIVE_JSON_FEED:-"https://www.php.net/releases/active.php"}"

# Manual setting for PHP RC versions. Change this to add or remove RC versions.
# Separate each version with a space. Example: ("8.3-rc" "8.4-rc")
PHP_RC_VERSIONS=("8.3-rc")

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

function save_php_version_data_from_url {
    # Fetch the JSON from the PHP website
    local json_data=$(curl -s $PHP_VERSIONS_ACTIVE_JSON_FEED)

    ui_set_yellow
    echo "⚡️ Getting PHP Versions..."
    ui_reset_colors

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

    # Print the transformed YAML data to the console.
    echo "$yaml_data"

    # Save the transformed YAML data to the designated file (PHP_VERSIONS_CONFIG_FILE).
    echo "$yaml_data" > $PHP_VERSIONS_CONFIG_FILE

    ui_set_green
    echo "✅ Saved PHP Versions to $PHP_VERSIONS_CONFIG_FILE"
    ui_reset_colors
}

##########################
# Main script starts here
save_php_version_data_from_url
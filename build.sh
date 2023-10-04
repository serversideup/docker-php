#!/bin/bash
set -e

##########################
# Environment Settings
BUILD_BUILD_CONFIG_FILE="${BUILD_BUILD_CONFIG_FILE:-"build-config.yml"}"
PHP_VERSIONS_CONFIG_FILE="${PHP_VERSIONS_CONFIG_FILE:-"php-versions-conf.yml"}"
PHP_VERSIONS_ACTIVE_JSON_FEED="${PHP_VERSIONS_ACTIVE_JSON_FEED:-"https://www.php.net/releases/active.php"}"
PHP_RC_VERSIONS=("8.3-rc")  # Separate multiple versions by a space

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

function get_active_php_versions {
    # Fetch the JSON from the PHP website
    json_data=$(curl -s $PHP_VERSIONS_ACTIVE_JSON_FEED)

    ui_set_yellow
    echo "⚡️ Getting PHP Versions..."
    ui_reset_colors

    # Check if the array PHP_RC_VERSIONS has any elements (i.e., is not empty).
    rc_version_jq='.'  # Set a default value that represents no change in jq.
    
    if [[ ${#PHP_RC_VERSIONS[@]} -ne 0 ]]; then  # If PHP_RC_VERSIONS is not empty:
        rc_array="["  # Initialize an empty JSON array string.
        
        # Loop through each version in PHP_RC_VERSIONS to construct the JSON representation.
        for rc_version in "${PHP_RC_VERSIONS[@]}"; do
            # For each RC version, append its JSON structure to the rc_array string.
            rc_array+="{\"minor_version\": \"$rc_version\", \"patch_versions\": [\"$rc_version\"]},"
        done
        
        rc_array=${rc_array%,}  # Remove the trailing comma from the constructed JSON string.
        rc_array+="]"  # Close the JSON array.
        
        # Construct the jq transformation to set the development versions in the main data.
        rc_version_jq=".php_versions[0].development_versions=$rc_array"
    fi

    # Parse the fetched JSON data and transform it to a specific YAML structure using jq and yq.
    yaml_data=$(echo "$json_data" | jq -r "
    {
        \"php_versions\": [
        . as \$major |
        to_entries[] |
        {
            \"major_version\": .key,
            \"minor_versions\": [
            .value |
            to_entries[] |
            {
                \"minor_version\": .key,
                \"patch_versions\": [ .value.version ]
            }
            ]
        }
        ]
    }
    | $rc_version_jq" | yq eval -P -)

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
get_active_php_versions

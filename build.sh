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

function assemble_php_version_data_from_url {
    # Fetch the JSON from the PHP website
    json_data=$(curl -s $PHP_VERSIONS_ACTIVE_JSON_FEED)

    ui_set_yellow
    echo "⚡️ Getting PHP Versions..."
    ui_reset_colors

    rc_version_jq='.'  # Set a default value that represents no change in jq.

    rc_additions=""
    
    if [[ ${#PHP_RC_VERSIONS[@]} -ne 0 ]]; then  # If PHP_RC_VERSIONS is not empty:
        for rc_version in "${PHP_RC_VERSIONS[@]}"; do
            rc_jq="{
                \"minor_version\": \"$rc_version\",
                \"release_candidate_version\": true,
                \"patch_versions\": [\"$rc_version\"]
            }"
            # Add each RC version to the end of the .php_versions[0].minor_versions array.
            rc_additions+=" | .php_versions[0].minor_versions += [$rc_jq]"
        done
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
                \"patch_versions\": [ .value.version | tostring ]  # Quoting the version number
            }
            ]
        }
        ]
    }
    $rc_additions" | yq eval -P -)

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

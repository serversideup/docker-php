#!/bin/bash
set -oue pipefail
set -x
trap read DEBUG

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
    }" | yq eval -P -)

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

    # Convert YAML to JSON
    downloaded_json_data=$(yq eval -o=json "$DOWNLOADED_PHP_VERSIONS_CONFIG_FILE")
    additional_json_data=$(yq eval -o=json "$ADDITIONAL_PHP_VERSIONS_CONFIG_FILE")

    echo_color_message yellow "⚡️ Combining data from $ADDITIONAL_PHP_VERSIONS_CONFIG_FILE..."

    # Use 'echo' to pass the JSON data to 'jq'
    merged_json=$(jq -s '
        {
            php_versions: (
                .[0].php_versions + .[1].php_versions
                | group_by(.major)
                | map({
                    major: .[0].major,
                    minor_versions: (
                        map(.minor_versions[]) 
                        | group_by(.minor)
                        | map({
                            minor: .[0].minor,
                            patch_versions: map(.patch_versions[]) | flatten
                        })
                    )
                })
            )
        }
    ' <(echo "$downloaded_json_data") <(echo "$additional_json_data"))

    # Convert updated JSON data back to YAML
    merged_yaml=$(echo "$merged_json" | yq eval -P -)
    
    # Save the merged YAML data back to the file
    echo "$merged_yaml" > "$DOWNLOADED_PHP_VERSIONS_CONFIG_FILE"
    
}


function append_php_rc_versions {
    echo_color_message yellow "⚡️ Adding PHP RC versions..."
    
    # Convert YAML to JSON
    json_data=$(yq eval -o=json "$DOWNLOADED_PHP_VERSIONS_CONFIG_FILE")
    
    # Loop through each RC version
    for rc_version in "${PHP_RC_VERSIONS[@]}"; do
        major_version="${rc_version%%.*}"
        
        # Construct the new RC version entry as a JSON string
        rc_json="{\"minor\": \"$rc_version\", \"release_candidate\": true, \"patch_versions\": [\"$rc_version\"]}"
        
        # Add the new RC version entry to the JSON data
        json_data=$(echo "$json_data" | jq --argjson rc_json "$rc_json" --arg major "$major_version" '
        (.php_versions[] | select(.major == $major) | .minor_versions) += [$rc_json]
        ')
    done
    
    # Convert updated JSON data back to YAML
    updated_yaml=$(echo "$json_data" | yq eval -P -)
    
    # Save the updated YAML data back to the file
    echo "$updated_yaml" > "$DOWNLOADED_PHP_VERSIONS_CONFIG_FILE"
    
    echo_color_message green "✅ PHP RC versions appended."
}

##########################
# Main script starts here

save_php_version_data_from_url

if [ -f $ADDITIONAL_PHP_VERSIONS_CONFIG_FILE ]; then
    merge_php_version_data
fi

if [ ${#PHP_RC_VERSIONS[@]} -ne 0 ]; then
    append_php_rc_versions
fi

finalize_php_version_data
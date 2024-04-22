#!/bin/bash
###################################################
# Usage: get-php-versions.sh [--skip-download]
###################################################
# This file takes the official latest PHP releases from php.net merges them with our
# "base php configuration". These files get merged into a final file called "php-versions.yml"
# which is used to build our GitHub Actions jobs.
#
# 👉 REQUIRED FILES
# - BASE_PHP_VERSIONS_CONFIG_FILE must be valid and set to a valid file path
#  (defaults to scripts/conf/php-versions-base-config.yml)

set -oue pipefail

# Uncomment below for step-by-step execution
# set -x
# trap read DEBUG

##########################
# Argument Parsing

SKIP_DOWNLOAD=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-download) SKIP_DOWNLOAD=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

##########################
# Environment Settings

# Script variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# PHP Versions JSON feed URL
PHP_VERSIONS_ACTIVE_JSON_FEED="${PHP_VERSIONS_ACTIVE_JSON_FEED:-"https://www.php.net/releases/active.php"}"

# File settings
BASE_PHP_VERSIONS_CONFIG_FILE="${BASE_PHP_VERSIONS_CONFIG_FILE:-"$SCRIPT_DIR/conf/php-versions-base-config.yml"}"
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

##########################
# Main script starts here

if [ "$SKIP_DOWNLOAD" = false ]; then
    echo_color_message yellow "⚡️ Getting PHP Versions from $PHP_VERSIONS_ACTIVE_JSON_FEED"
    # Fetch the JSON from the PHP website
    php_net_version_json=$(curl -s $PHP_VERSIONS_ACTIVE_JSON_FEED)

    # Parse the fetched JSON data and transform it to a specific YAML structure using jq and yq.
    php_net_yaml_data=$(echo "$php_net_version_json" | jq -r "
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
                \"patch_versions\": (if .value.version | type == \"null\" then [] elif .value.version | type == \"array\" then .value.version else [.value.version] end)
            }
            ]
        }
        ]
    }" | yq eval -P -)

    # Save the YAML data in our data standard to a file
    echo "$php_net_yaml_data" > "$DOWNLOADED_PHP_VERSIONS_CONFIG_FILE"

    # Convert YAML to JSON
    downloaded_and_normalized_json_data=$(yq eval -o=json "$DOWNLOADED_PHP_VERSIONS_CONFIG_FILE")
    base_json_data=$(yq eval -o=json "$BASE_PHP_VERSIONS_CONFIG_FILE")

    echo_color_message yellow "⚡️ Combining data from $BASE_PHP_VERSIONS_CONFIG_FILE..."

    # Use 'echo' to pass the JSON data to 'jq'
    merged_json=$(jq -s '
        {
            php_versions: (
                .[0].php_versions + .[1].php_versions
                | group_by(.major)
                | map({
                    major: .[0].major,
                    minor_versions: (
                        map(.minor_versions[] | select(. != null))
                        | group_by(.minor)
                        | map({
                            minor: .[0].minor,
                            base_os: (map(.base_os // []) | add),
                            patch_versions: (map(.patch_versions // []) | flatten | unique | select(. != null))
                        })
                    )
                })
            ),
            php_variations: (. | map(.php_variations // []) | add)
        }
    ' <(echo "$downloaded_and_normalized_json_data") <(echo "$base_json_data"))

    # Convert updated JSON data back to YAML
    merged_and_finalized_yaml=$(echo "$merged_json" | yq eval -P -)

    # Save the merged YAML data back to the file
    echo "$merged_and_finalized_yaml" > "$FINAL_PHP_VERSIONS_CONFIG_FILE"
    rm "$DOWNLOADED_PHP_VERSIONS_CONFIG_FILE"
    echo_color_message green "✅ Data is finalized compiled into $FINAL_PHP_VERSIONS_CONFIG_FILE"
else
    echo_color_message yellow "⚡️ Skipping download of PHP versions because \"--skip-download\" was set..."
    cp "$BASE_PHP_VERSIONS_CONFIG_FILE" "$FINAL_PHP_VERSIONS_CONFIG_FILE"
fi

cat $FINAL_PHP_VERSIONS_CONFIG_FILE
echo_color_message green "✅ Saved PHP versions to $FINAL_PHP_VERSIONS_CONFIG_FILE"
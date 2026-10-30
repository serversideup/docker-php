#!/bin/bash
###################################################
# Usage: get-php-versions.sh [--skip-download] [--input PATH] [--output PATH]
###################################################
# This file takes the official latest PHP releases from php.net merges them with our
# "base php configuration". These files get merged into a final file called "php-versions.yml"
# which is used to build our GitHub Actions jobs.
#
# Images are compiled from the php.net tarball (see scripts/prepare-php-base.sh), so a
# release can be built as soon as php.net lists it. A minor version with patch_versions
# in the base config uses those instead of php.net's, which pins or holds back a release.
#
# 👉 REQUIRED FILES
# - BASE_PHP_VERSIONS_CONFIG_FILE must be valid and set to a valid file path
#  (defaults to scripts/conf/php-versions-base-config.yml)
#
# 👉 OPTIONS
# --skip-download: Skip downloading from php.net and use existing base config
# --input: Input file path (defaults to scripts/conf/php-versions-base-config.yml)
# --output: Output file path (defaults to scripts/conf/php-versions.yml)

set -oue pipefail

# Uncomment below for step-by-step execution
# set -x
# trap read DEBUG

##########################
# Argument Parsing

SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-false}"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-download) SKIP_DOWNLOAD=true ;;
        --input)
            if [ -z "$2" ]; then
                echo "Error: --input requires a file path."
                exit 1
            fi
            BASE_PHP_VERSIONS_CONFIG_FILE="$2"
            shift 2
            continue
            ;;
        --output)
            if [ -z "$2" ]; then
                echo "Error: --output requires a file path."
                exit 1
            fi
            FINAL_PHP_VERSIONS_CONFIG_FILE="$2"
            shift 2
            continue
            ;;
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
FINAL_PHP_VERSIONS_CONFIG_FILE="${FINAL_PHP_VERSIONS_CONFIG_FILE:-"$SCRIPT_DIR/conf/php-versions.yml"}"

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

    # Fetch the JSON from the PHP website with retry logic and validation
    max_retries=3
    retry_count=0
    php_net_version_json=""

    while [ $retry_count -lt $max_retries ]; do
        http_code=$(curl -s -o /tmp/php_versions_response.json -w "%{http_code}" --max-time 30 --connect-timeout 10 -A "serversideup-docker-php/1.0 (https://github.com/serversideup/docker-php)" "$PHP_VERSIONS_ACTIVE_JSON_FEED")

        if [ "$http_code" = "200" ]; then
            php_net_version_json=$(cat /tmp/php_versions_response.json)
            rm -f /tmp/php_versions_response.json

            # Validate that the response is actually JSON
            if echo "$php_net_version_json" | jq empty 2>/dev/null; then
                break
            else
                echo_color_message red "❌ Response from php.net returned HTTP $http_code but body is not valid JSON."
                echo_color_message red "--- Response Body (first 500 chars) ---"
                echo "$php_net_version_json" | head -c 500
                echo ""
                echo_color_message red "--- End Response Body ---"
                php_net_version_json=""
            fi
        else
            echo_color_message red "❌ Failed to fetch PHP versions from php.net (HTTP $http_code)"
            if [ -f /tmp/php_versions_response.json ]; then
                echo_color_message red "--- Response Body (first 500 chars) ---"
                head -c 500 /tmp/php_versions_response.json
                echo ""
                echo_color_message red "--- End Response Body ---"
                rm -f /tmp/php_versions_response.json
            fi
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            wait_time=$((retry_count * 5))
            echo_color_message yellow "⚠️  Retrying in ${wait_time}s... (attempt $((retry_count + 1))/$max_retries)"
            sleep "$wait_time"
        fi
    done

    if [ -z "$php_net_version_json" ]; then
        echo_color_message red "❌ Failed to fetch valid JSON from $PHP_VERSIONS_ACTIVE_JSON_FEED after $max_retries attempts"
        echo "::error title=PHP Version Fetch Failed::Failed to get valid JSON from php.net after $max_retries attempts. The server may be returning a Cloudflare challenge, rate limiting, or experiencing an outage. Check the response body logged above for details."
        exit 1
    fi

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
            dependencies: (.[1].dependencies // {}),
            php_variations: (.[1].php_variations // []),
            php_versions: (
                (.[0].php_versions + (.[1].php_versions | map(.minor_versions |= map(. + {from_base_config: true}))))
                | group_by(.major)
                | map({
                    major: .[0].major,
                    minor_versions: (
                        map(.minor_versions[] | select(. != null))
                        | group_by(.minor)
                        | map(
                            (map(select(.from_base_config) | (.patch_versions // [])) | flatten) as $pinned
                            | {
                                minor: .[0].minor,
                                base_os: (map(.base_os // []) | add),
                                patch_versions: (if ($pinned | length) > 0 then $pinned else (map(.patch_versions // []) | flatten | unique) end),
                                php_extension_overrides: (map(.php_extension_overrides // []) | add | unique),
                                docker_library_ref: (map(.docker_library_ref // empty) | first),
                                php_base_overrides: (map(.php_base_overrides // empty) | add)
                            }
                            | with_entries(select(.value != null))
                        )
                    )
                })
            ),
            operating_systems: (.[1].operating_systems // [])
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
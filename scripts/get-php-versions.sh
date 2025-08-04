#!/bin/bash
###################################################
# Usage: get-php-versions.sh [--skip-download] [--skip-dockerhub-validation]
###################################################
# This file takes the official latest PHP releases from php.net merges them with our
# "base php configuration". These files get merged into a final file called "php-versions.yml"
# which is used to build our GitHub Actions jobs.
#
# 🔍 DOCKERHUB VALIDATION & FALLBACK
# By default, this script validates that each PHP version from php.net is actually available 
# on DockerHub before including it in the final configuration. If a version is not available:
# 1. The script attempts to fall back to the previous patch version (e.g., 8.3.24 -> 8.3.23)
# 2. A GitHub Actions warning is displayed explaining the fallback
# 3. If the fallback version is also unavailable, the script exits with an error
#
# This ensures that Docker builds won't fail due to non-existent base images.
#
# 👉 REQUIRED FILES
# - BASE_PHP_VERSIONS_CONFIG_FILE must be valid and set to a valid file path
#  (defaults to scripts/conf/php-versions-base-config.yml)
#
# 👉 OPTIONS
# --skip-download: Skip downloading from php.net and use existing base config
# --skip-dockerhub-validation: Skip DockerHub validation (useful for testing/development)

set -oue pipefail

# Uncomment below for step-by-step execution
# set -x
# trap read DEBUG

##########################
# DockerHub API Functions

# Check if a PHP version exists on DockerHub
check_dockerhub_php_version() {
    local version="$1"
    local variant="${2:-cli}"
    local os="${3:-}"
    
    local image_tag
    if [ -n "$os" ] && [ "$os" != "bullseye" ] && [ "$os" != "bookworm" ]; then
        image_tag="${version}-${variant}-${os}"
    else
        image_tag="${version}-${variant}"
    fi
    
    # Use Docker Hub API v2 to check if the tag exists with timeout and retry
    local response
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        response=$(curl -s --max-time 10 --connect-timeout 5 \
            -o /dev/null -w "%{http_code}" \
            "https://registry.hub.docker.com/v2/repositories/library/php/tags/${image_tag}/")
        
        # Check if we got a valid HTTP response
        if [ "$response" = "200" ]; then
            return 0  # Version exists
        elif [ "$response" = "404" ]; then
            return 1  # Version definitely does not exist
        else
            # Network error or other issue, retry
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo_color_message yellow "⚠️  DockerHub API request failed (HTTP $response), retrying in 2 seconds..."
                sleep 2
            fi
        fi
    done
    
    # If we get here, all retries failed
    echo_color_message red "❌ Failed to check DockerHub after $max_retries attempts for $image_tag"
    return 1
}

# Get previous patch version (e.g., 8.3.24 -> 8.3.23)
get_previous_patch_version() {
    local version="$1"
    local major_minor patch
    
    # Split version into major.minor and patch
    major_minor=$(echo "$version" | cut -d'.' -f1-2)
    patch=$(echo "$version" | cut -d'.' -f3)
    
    # Decrement patch version
    if [ "$patch" -gt 0 ]; then
        patch=$((patch - 1))
        echo "${major_minor}.${patch}"
    else
        # If patch is 0, we can't go lower
        return 1
    fi
}

# Add a new function for GitHub Actions annotations (around line 193)
function github_actions_annotation() {
    # Output GitHub Actions workflow commands directly without color formatting
    echo "$1"
}

# Validate and potentially fallback a PHP version
validate_php_version_with_fallback() {
    local version="$1"
    local original_version="$version"
    local fallback_attempted=false
    
    echo_color_message yellow "🔍 Checking PHP version $version on DockerHub..." >&2
    
    # Check if the version exists on DockerHub (using cli variant as reference)
    if check_dockerhub_php_version "$version" "cli"; then
        echo_color_message green "✅ PHP $version is available on DockerHub" >&2
        echo "$version"  # Output to stdout for capture
        return 0
    else
        echo_color_message red "❌ PHP $version is not available on DockerHub" >&2
        
        # Try to get previous patch version
        local fallback_version
        if fallback_version=$(get_previous_patch_version "$version"); then
            fallback_attempted=true
            echo_color_message yellow "⚠️  Attempting fallback to PHP $fallback_version..." >&2
            
            if check_dockerhub_php_version "$fallback_version" "cli"; then
                # Output GitHub Actions annotation without color formatting
                github_actions_annotation "::warning title=PHP Version Fallback::PHP $original_version is not available on DockerHub. Falling back to PHP $fallback_version. This may indicate that DockerHub has not yet published the latest PHP release. Consider checking DockerHub availability before updating to newer versions."
                echo_color_message green "✅ Fallback successful: Using PHP $fallback_version" >&2
                echo "$fallback_version"  # Output to stdout for capture
                return 0
            else
                echo_color_message red "❌ Fallback version PHP $fallback_version is also not available on DockerHub" >&2
            fi
        fi
        
        # If we get here, both original and fallback failed
        if [ "$fallback_attempted" = true ]; then
            github_actions_annotation "::error title=PHP Version Unavailable::Neither PHP $original_version nor fallback version $fallback_version are available on DockerHub. This suggests a significant lag in DockerHub publishing or a configuration issue. Please check DockerHub manually and consider using a known working version."
        else
            github_actions_annotation "::error title=PHP Version Unavailable::PHP $original_version is not available on DockerHub and no fallback version could be determined (patch version is 0). Please check DockerHub manually and use a known working version."
        fi
        
        return 1
    fi
}

##########################
# Argument Parsing

SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-false}"
SKIP_DOCKERHUB_VALIDATION="${SKIP_DOCKERHUB_VALIDATION:-false}"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-download) SKIP_DOWNLOAD=true ;;
        --skip-dockerhub-validation) SKIP_DOCKERHUB_VALIDATION=true ;;
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

    # Parse the fetched JSON data and optionally validate PHP versions on DockerHub
    if [ "$SKIP_DOCKERHUB_VALIDATION" = true ]; then
        echo_color_message yellow "⚠️  Skipping DockerHub validation as requested..."
        processed_json="$php_net_version_json"
    else
        echo_color_message yellow "🔍 Parsing and validating PHP versions from php.net..."
        
        # First, extract versions from the JSON
        php_versions_raw=$(echo "$php_net_version_json" | jq -r "
        . as \$major |
        to_entries[] |
        .value |
        to_entries[] |
        .value.version" | grep -v "null" | sort -u)
        
        # Create temporary files to store validation results
        validated_versions_file=$(mktemp)
        version_map_file=$(mktemp)
        
        # Validate each version
        validation_failed=false
        while IFS= read -r version; do
            if [ -n "$version" ]; then
                echo_color_message yellow "🔍 Validating PHP $version..."
                # Capture validation result without color codes
                if validated_version=$(validate_php_version_with_fallback "$version" | tail -n1); then
                    # Double check that we got a valid version back
                    if [ -n "$validated_version" ] && [ "$validated_version" != "VALIDATION_FAILED" ]; then
                        echo "$version:$validated_version" >> "$validated_versions_file"
                        if [ "$version" != "$validated_version" ]; then
                            # Escape special characters for sed
                            escaped_original=$(echo "$version" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
                            escaped_validated=$(echo "$validated_version" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
                            echo "s/${escaped_original}/${escaped_validated}/g" >> "$version_map_file"
                        fi
                    else
                        echo_color_message red "❌ Validation failed for PHP $version"
                        validation_failed=true
                    fi
                else
                    echo_color_message red "❌ Validation failed for PHP $version"
                    validation_failed=true
                fi
            fi
        done <<< "$php_versions_raw"
        
        # Exit if any validation failed
        if [ "$validation_failed" = true ]; then
            echo_color_message red "❌ One or more PHP versions failed validation. Stopping build."
            rm -f "$validated_versions_file" "$version_map_file"
            exit 1
        fi
        
        # Apply version substitutions if any fallbacks were used
        processed_json="$php_net_version_json"
        if [ -s "$version_map_file" ]; then
            echo_color_message yellow "📝 Applying version fallbacks..."
            while IFS= read -r substitution; do
                processed_json=$(echo "$processed_json" | sed "$substitution")
            done < "$version_map_file"
        fi
        
        # Clean up temporary files
        rm -f "$validated_versions_file" "$version_map_file"
    fi
    
    # Parse the fetched JSON data and transform it to a specific YAML structure using jq and yq.
    php_net_yaml_data=$(echo "$processed_json" | jq -r "
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
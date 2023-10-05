#!/bin/bash
# set -x
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

function save_php_version_data_from_url {
    # Fetch the JSON from the PHP website
    local json_data=$(curl -s $PHP_VERSIONS_ACTIVE_JSON_FEED)

    ui_set_yellow
    echo "⚡️ Getting PHP Versions..."
    ui_reset_colors

    rc_additions=""
    
    if [[ ${#PHP_RC_VERSIONS[@]} -ne 0 ]]; then  # If PHP_RC_VERSIONS is not empty:
        for rc_version in "${PHP_RC_VERSIONS[@]}"; do
            rc_jq="{
                \"minor\": \"$rc_version\",
                \"release_candidate\": true,
                \"patch\": [\"$rc_version\"]
            }"
            # Add each RC version to the end of the .php_versions[0].minor_versions array.
            rc_additions+=" | .php_versions[0].minor_versions += [$rc_jq]"
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
    $rc_additions" | yq eval -P -)

    # Print the transformed YAML data to the console.
    echo "$yaml_data"

    # Save the transformed YAML data to the designated file (PHP_VERSIONS_CONFIG_FILE).
    echo "$yaml_data" > $PHP_VERSIONS_CONFIG_FILE

    ui_set_green
    echo "✅ Saved PHP Versions to $PHP_VERSIONS_CONFIG_FILE"
    ui_reset_colors
}

generate_docker_build_commands() {
    local php_versions_file=$PHP_VERSIONS_CONFIG_FILE
    local build_config_file=$BUILD_BUILD_CONFIG_FILE

    # Extract base OS versions and default OS
    local base_os_versions=($(yq e '.base_os_versions[].name' $build_config_file))
    local default_os=$(yq e '.base_os_versions[] | select(.default == true).name' $build_config_file)
    local latest_major=$(yq e '.php_versions[].major' $php_versions_file | tail -1)

    # For each PHP version
    for major in $(yq e '.php_versions[].major' $php_versions_file); do
        latest_minor=$(yq e ".php_versions[] | select(.major == \"$major\") | .minor_versions[] | select(.release_candidate != true) | .minor" $php_versions_file | tail -1)

        for minor in $(yq e ".php_versions[] | select(.major == \"$major\").minor_versions[].minor" $php_versions_file); do
            # Fetch the latest patch for the current minor version
            latest_patch=$(yq e ".php_versions[] | select(.major == \"$major\") | .minor_versions[] | select(.minor == \"$minor\") | (.patch_versions[]? // .patch[0])" $php_versions_file | tail -1)

            for patch in $(yq e ".php_versions[].minor_versions[] | select(.minor == \"$minor\").patch_versions[]" $php_versions_file); do
                # For each PHP variation
                for variation in $(yq e '.php_variations[].name' $build_config_file); do
                    # For each OS
                    for os in "${base_os_versions[@]}"; do
                        # Set our main command
                        docker_command="docker build "

                        # Use the varation's Dockefile
                        docker_command+=$'-f src/variations/'"$variation"'/Dockerfile '

                        # Set the build arguments
                        docker_command+=$'--build-arg BASE_OS_VERSION='"$os"' '
                        docker_command+=$'--build-arg PHP_VERSION=php:'"$patch"' '
                        docker_command+=$'--build-arg PHP_VARIATION='"$variation"' '

                        # Set the version tagging
                        docker_command+=$'-t serversideup/php-pro-'"$variation"':'"$patch"' '

                        if [[ "$patch" == "$latest_patch" && "$default_os" == "$os" ]]; then
                            docker_command+=$'-t serversideup/php-pro-'"$variation"':'"$minor"' '
                        fi

                        if [[ "$minor" == "$latest_minor" && "$default_os" == "$os" ]]; then
                            docker_command+=$'-t serversideup/php-pro-'"$variation"':'"$major"' '
                        fi

                        if [[ "$major" == "$latest_major" && "$default_os" == "$os" ]]; then
                            docker_command+=$'-t serversideup/php-pro-'"$variation"':'"latest"' '
                        fi

                        # Wrap up the command with the context of the current directory
                        docker_command+=$'.'

                        echo "$docker_command"
                    done
                done
            done
        done
    done
}


##########################
# Main script starts here
VARIATION=""
BASE_OS=""
VERSION=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --variation) VARIATION="$2"; shift ;;
        --base-os) BASE_OS="$2"; shift ;;
        --version) VERSION="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

save_php_version_data_from_url
generate_docker_build_commands
#!/bin/bash
###################################################
# Usage: view-nginx-versions.sh [--os <os>]
###################################################
# This script fetches the latest NGINX versions available for different
# operating systems from the official NGINX repositories. By default, it
# shows all operating systems, but you can filter to a specific OS.

set -oe pipefail

##########################
# Configuration
os_config() {
    # Resolve config path relative to this script so --help works before SCRIPT_DIR is set
    local this_script_dir
    this_script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    local config_file="$this_script_dir/conf/php-versions-base-config.yml"

    if ! command -v yq >/dev/null 2>&1; then
        echo "yq is required but not found. Install 'yq' (https://github.com/mikefarah/yq) to continue." 1>&2
        return 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq is required but not found. Install 'jq' to continue." 1>&2
        return 1
    fi

    yq -r '.operating_systems[] | .family as $f | .versions[] | "\(.version)|\($f)|\(.name)"' "$config_file" \
    | while IFS='|' read -r version family name; do
        if [[ "$family" == "alpine" ]]; then
            # version comes as alpineX.Y (e.g., alpine3.20)
            key="$version"
            alpine_num_version="${version#alpine}"
            url="http://nginx.org/packages/alpine/v${alpine_num_version}/main/x86_64/"
            pattern='nginx-[0-9][^"\n]*\.apk'
        else
            key="$version"
            url="http://nginx.org/packages/debian/dists/${version}/nginx/binary-amd64/Packages"
            pattern='^Package: nginx$'
        fi
        printf '%s|%s|%s|%s\n' "$key" "$name" "$url" "$pattern"
    done
}

##########################
# Functions

help_menu() {
    echo "Usage: $0 [--os <os>]"
    echo
    echo "This script fetches the latest NGINX versions available for different"
    echo "operating systems from the official NGINX repositories."
    echo
    echo "Options:"
    echo "  --os <os>      Filter to a specific operating system"
    echo "  --help, -h     Show this help message"
    echo
    echo "Available Operating Systems:"
    os_config | awk -F'|' '{printf "  %-12s %s\n", $1, $2}'
    echo
    echo "Examples:"
    echo "  $0                    # Show all operating systems"
    echo "  $0 --os alpine3.20    # Show only Alpine 3.20"
    echo "  $0 --os bookworm      # Show only Debian Bookworm"
}

##########################
# Argument Parsing

FILTER_OS=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --os)
        FILTER_OS="$2"
        shift 2
        ;;
        --help|-h)
        help_menu
        exit 0
        ;;
        *)
        echo "Unknown parameter passed: $1"
        help_menu
        exit 1
        ;;
    esac
done

##########################
# Environment Settings

# Script Configurations
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

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

function ui_set_blue {
    printf $'\033[0;34m'
}

function ui_set_bold {
    printf $'\033[1m'
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
# Fetch helpers

get_alpine_version() {
    local url="$1"
    local pattern="$2"
    
    local version=$(curl -s "$url" | grep -o "$pattern" | sort -V | tail -1)
    if [[ -n "$version" ]]; then
        # Extract version number from package name (e.g., nginx-1.24.0-r7.apk -> 1.24.0-r7)
        echo "$version" | sed 's/nginx-\(.*\)\.apk/\1/'
    else
        echo "Unable to fetch"
    fi
}

get_debian_version() {
    local url="$1"
    
    local version=$(curl -s "$url" \
        | awk 'BEGIN{RS=""; FS="\n"} { pkg=0; ver=""; for (i=1;i<=NF;i++){ if ($i ~ /^Package: nginx$/) pkg=1; if ($i ~ /^Version:/){ split($i,a,": *"); ver=a[2]; } } if (pkg && ver!="") print ver; }' \
        | sort -V | tail -1)
    if [[ -n "$version" ]]; then
        echo "$version"
    else
        echo "Unable to fetch"
    fi
}

fetch_nginx_version() {
    local os_key="$1"
    local os_name="$2"
    local url="$3"
    local pattern="$4"
    
    echo_color_message blue "🔍 Fetching NGINX version for $os_name from $url..."
    
    local version=""
    if [[ "$url" == *"alpine"* ]]; then
        version=$(get_alpine_version "$url" "$pattern")
    else
        version=$(get_debian_version "$url")
    fi
    
    ui_set_bold
    ui_set_green
    printf "%-20s" "$os_name:"
    ui_reset_colors
    echo " $version"
}

##########################
# Main script starts here

echo_color_message yellow "🌐 NGINX Version Checker"
echo

# If a specific OS is requested, validate it exists
if [[ -n "$FILTER_OS" ]]; then
    if ! grep -q "^$FILTER_OS|" < <(os_config); then
        echo_color_message red "❌ Unknown operating system: $FILTER_OS"
        echo
        help_menu
        exit 1
    fi
fi

# Process operating systems
os_config | while IFS='|' read -r os_key os_name url pattern; do
    # Skip if filtering and this isn't the requested OS
    if [[ -n "$FILTER_OS" && "$os_key" != "$FILTER_OS" ]]; then
        continue
    fi

    fetch_nginx_version "$os_key" "$os_name" "$url" "$pattern"
done

echo
echo_color_message green "✅ NGINX version check complete!"
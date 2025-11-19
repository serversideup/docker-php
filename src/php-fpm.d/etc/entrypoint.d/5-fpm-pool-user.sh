#!/bin/sh
###################################################
# Usage: 5-fpm-pool-user.sh
###################################################
# This script checks if the container is running as root and adds
# the proper user/group configuration to the PHP-FPM pool.
script_name="fpm-pool-user"

: "${PHP_FPM_CHILD_PROCESS_USER:=www-data}"
: "${PHP_FPM_CHILD_PROCESS_GROUP:=www-data}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    exit 0 # Exit if not running as root
fi

# Exit if default config is disabled
if [ "$DISABLE_DEFAULT_CONFIG" = true ]; then
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG is true, skipping FPM user/group configuration."
    fi
    exit 0
fi

# Add user and group configuration to PHP-FPM pool
{
    echo ""
    echo "user = $PHP_FPM_CHILD_PROCESS_USER"
    echo "group = $PHP_FPM_CHILD_PROCESS_GROUP"
} >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf
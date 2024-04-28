#!/bin/sh
script_name="debug-mode"

if [ "$DISABLE_DEFAULT_CONFIG" = false ]; then
    set_php_ini (){
        php_ini_setting=$1
        php_ini_value=$2
        php_ini_debug_file="$PHP_INI_DIR/conf.d/zzz-serversideup-docker-php-debug.ini"
        php_fpm_debug_conf_file="/usr/local/etc/php-fpm.d/zzz-docker-php-serversideup-fpm-debug.conf"

        echo "$php_ini_setting = $php_ini_value" >> "$php_ini_debug_file"
        echo "ℹ️ NOTICE ($script_name): INI - $php_ini_setting has been set to \"$php_ini_value\"."

        # Check for PHP-FPM
        if [ -d "/usr/local/etc/php-fpm.d" ]; then
            echo "php_admin_value[$php_ini_setting] = $php_ini_value" >> "$php_fpm_debug_conf_file"
            echo "ℹ️ NOTICE ($script_name): FPM - $php_ini_setting has been set to \"$php_ini_value\""
        fi
    }

    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        set_php_ini display_errors On
        set_php_ini display_startup_errors On
        set_php_ini error_reporting "32767"
    fi
else
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal \"false\", so debug mode will NOT be automatically set."
    fi
fi
#!/bin/sh
script_name="log-output-level"

if [ "$DISABLE_DEFAULT_CONFIG" = true ]; then
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal \"false\", so debug mode will NOT be automatically set."
    fi
    exit 0 # Exit if DISABLE_DEFAULT_CONFIG is true
fi

#######################################
# Functions
#######################################

fpm_is_installed (){
    if [ -d "/usr/local/etc/php-fpm.d" ]; then
        return 0
    else
        return 1
    fi
}

set_php_ini (){
    php_ini_setting=$1
    php_ini_value=$2
    php_ini_debug_file="$PHP_INI_DIR/conf.d/zzz-serversideup-docker-php-debug.ini"
    php_fpm_debug_conf_file="/usr/local/etc/php-fpm.d/zzz-docker-php-serversideup-fpm-debug.conf"

    echo "$php_ini_setting = $php_ini_value" >> "$php_ini_debug_file"
    echo "ℹ️ NOTICE ($script_name): INI - $php_ini_setting has been set to \"$php_ini_value\"."

    # Check for PHP-FPM
    if fpm_is_installed; then
        echo "php_admin_value[$php_ini_setting] = $php_ini_value" >> "$php_fpm_debug_conf_file"
        echo "ℹ️ NOTICE ($script_name): FPM - $php_ini_setting has been set to \"$php_ini_value\""
    fi
}

set_fpm_log_level (){
    if ! fpm_is_installed; then
        return 0
    fi

    fpm_log_level=$1
    
    # Create a temporary file then move it, instead of requiring permissions to write to /usr/local/etc/
    tmp_file=$(mktemp /tmp/php-fpm.conf.XXXXXX)
    sed "/\[global\]/a log_level = $fpm_log_level" /usr/local/etc/php-fpm.conf > "$tmp_file"
    cat "$tmp_file" > /usr/local/etc/php-fpm.conf
    rm "$tmp_file"
    echo "ℹ️ NOTICE ($script_name): FPM - log_level has been set to \"$fpm_log_level\""

    if [ "$fpm_log_level" = "debug" ]; then 
        echo "access.log = /proc/self/fd/2" >> /usr/local/etc/php-fpm.d/zzz-docker-php-serversideup-fpm-debug.conf
        echo "access.format = \"fpm: %R - %u %t \"%m %r%Q%q\" %s duration=%{milliseconds}dms memory=%Mk cpu=%C%% pid=%p script=%f\"" >> /usr/local/etc/php-fpm.d/zzz-docker-php-serversideup-fpm-debug.conf
        echo "ℹ️ NOTICE ($script_name): FPM - access.log has been set to \"STDERR\""
    fi
}

#######################################
# Main (if default config is enabled)
#######################################

case "$LOG_OUTPUT_LEVEL" in
    debug)
    set_php_ini display_errors On
    set_php_ini display_startup_errors On
    set_php_ini error_reporting "32767" # E_ALL
    set_fpm_log_level debug
    ;;
    info)
    set_fpm_log_level notice
    ;;
    notice)
    set_fpm_log_level notice
    ;;
    warn)
    : # Do nothing
    ;;
    error)
    set_fpm_log_level error
    ;;
    crit)
    set_fpm_log_level alert
    ;;
    alert)
    set_fpm_log_level alert
    ;;
    emerg)
    set_fpm_log_level alert
    ;;
    *)
    echo "❌ ERROR ($script_name): LOG_OUTPUT_LEVEL is not set to a valid value. Please set it to one of the following: debug, info, notice, warn, error, crit, alert, emerg."
    return 1
    ;;
esac

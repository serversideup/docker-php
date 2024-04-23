#!/bin/sh
###################################################
# Usage: 10-init-unit.sh
###################################################
# This script processes the environment variables used in the Unit configuration template files.
# Once the templates are processed, the script will enable the configurations and start Unit.
# This script is executed at container initialization.

set -e
script_name="init-unit"

WAITLOOPS=5
SLEEPSEC=1
UNIT_CONFIG_DIRECTORY=${UNIT_CONFIG_DIRECTORY:-"/etc/unit/config.d"}
UNIT_CONFIG_FILE=${UNIT_CONFIG_FILE:-"$UNIT_CONFIG_DIRECTORY/config.json"}
UNIT_SOCKET_LOCATION=${UNIT_SOCKET_LOCATION:-"/var/run/unit/control.unit.sock"}

##########
# Functions
##########
set_debug_output() {
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: Output of $*:" >&2
        echo
        eval "$@" || { echo "Command $* failed" >&2; return 1; }
        echo
    fi
}

process_template() {
    template_file=$1
    output_file=$2

    if [ -f "$output_file" ]; then
        echo "$script_name (ℹ️ NOTICE): $output_file already exists, so we'll use the existing file."
        return 0
    fi

    if [ ! -f "$template_file" ]; then
        echo "🛑 ERROR ($script_name): Unable to initialize container. $output_file doesn't exist and we're unable to find a template for $template_file."
        return 1
    fi

    # Get all environment variables starting with 'NGINX_', 'SSL_', `LOG_`, and 'APACHE_'
    subst_vars=$(env | grep -E '^(UNIT_|SSL_|LOG_)' | cut -d= -f1 | awk '{printf "${%s},",$1}' | sed 's/,$//')

    # Validate that all required variables are set
    for var_name in $(echo "$subst_vars" | tr ',' ' '); do
        eval "value=\$$var_name" # Use eval to get the value of var_name
        if [ -z "$value" ]; then
            echo "🛑 ERROR ($script_name): Environment variable $var_name is not set."
            return 1
        fi
    done

    echo "$script_name: Processing $template_file → $output_file..."
    envsubst "$subst_vars" < "$template_file" > "$output_file"
    set_debug_output "cat $output_file"
}

curl_put() {
    curl_option="$1"
    curl_value="$2"
    api_location="$3"

    if [ $curl_option = "--data-binary" ]; then
        curl_value="@$curl_value"
    fi

    curl_return=$(/usr/bin/curl -s -w '\n%{http_code}' -X PUT "$curl_option" "$curl_value" --unix-socket "$UNIT_SOCKET_LOCATION" "http://localhost/$api_location")
    return_status=$(echo "$curl_return" | tail -n1)
    return_body=$(echo "$curl_return" | head -n -1)

    if [ "$return_status" -ne "200" ]; then
        if echo "$return_body" | grep "Certificate already exists."; then
            echo "ℹ️ NOTICE: Certificate already exists. Ignoring this error..."
            echo "$return_body"
            return 0 # Ignore errors of certicate already existing
        else
            echo "🛑 ERROR: HTTP response status code is '$return_status'"
            echo "$return_body"
            return 1 # Return error for all other errors
        fi
    else
        echo "✅ OK: HTTP response status code is '$return_status'"
        echo "$return_body"
    fi
    return 0
}

configure_unit() {
    echo "$script_name: Launching Unit daemon to perform initial configuration..."
    /usr/sbin/$DOCKER_CMD --control unix:"$UNIT_SOCKET_LOCATION"

    for i in $(/usr/bin/seq $WAITLOOPS); do
        if [ ! -S "$UNIT_SOCKET_LOCATION" ]; then
            echo "$script_name: Waiting for control socket to be created..."
            /bin/sleep $SLEEPSEC
        else
            break
        fi
    done
    # even when the control socket exists, it does not mean unit has finished initialisation
    # this curl call will get a reply once unit is fully launched
    /usr/bin/curl -s -X GET --unix-socket "$UNIT_SOCKET_LOCATION" http://localhost/

    echo "$script_name: Looking for certificate bundles in $UNIT_CONFIG_DIRECTORY..."
    for f in $(/usr/bin/find "$UNIT_CONFIG_DIRECTORY" -type f -name "*.pem"); do
        echo "$script_name: Uploading certificates bundle: $f"
        curl_put "--data-binary" "$f" "certificates/$(basename $f .pem)"
    done

    set_debug_output "/usr/bin/find $UNIT_CONFIG_DIRECTORY -type f -name \"*.pem\""

    echo "$script_name: Looking for JavaScript modules in $UNIT_CONFIG_DIRECTORY..."
    for f in $(/usr/bin/find $UNIT_CONFIG_DIRECTORY -type f -name "*.js"); do
        echo "$script_name: Uploading JavaScript module: $f"
        curl_put "--data-binary" "$f" "js_modules/$(basename $f .js)"
    done

    echo "$script_name: Looking for configuration snippets in $UNIT_CONFIG_DIRECTORY..."
    for f in $(/usr/bin/find "$UNIT_CONFIG_DIRECTORY" -type f -name "*.json"); do
        echo "$script_name: Applying configuration $f";
        curl_put "--data-binary" "$f" "config"
    done

    # warn on filetypes we don't know what to do with
    for f in $(/usr/bin/find "$UNIT_CONFIG_DIRECTORY" -type f -not -name "*.sh" -not -name "*.template" -not -name "*.json" -not -name "*.pem" -not -name "*.js"); do
        echo "$script_name: Ignoring $f";
    done

    echo "$script_name: Setting access log to STDOUT..."
    curl_put "-d" '"/dev/stdout"' "config/access_log"

    echo "$script_name: Stopping Unit daemon after initial configuration..."
    kill -TERM "$(/bin/cat /var/run/unit/unit.pid)"

    for i in $(/usr/bin/seq $WAITLOOPS); do
        if [ -S "$UNIT_SOCKET_LOCATION" ]; then
            echo "$script_name: Waiting for control socket to be removed..."
            /bin/sleep $SLEEPSEC
        else
            break
        fi
    done
    if [ -S "$UNIT_SOCKET_LOCATION" ]; then
        kill -KILL "$(/bin/cat /var/run/unit/unit.pid)"
        rm -f "$UNIT_SOCKET_LOCATION"
    fi

    echo
    echo "$script_name: Unit initial configuration complete; ready for start up..."
    echo
}

validate_ssl(){
    available_ssl_bundles=$(/usr/bin/find "$UNIT_CONFIG_DIRECTORY" -type f -name "*.pem")

    if [ -n "$available_ssl_bundles" ]; then
        echo "ℹ️ NOTICE ($script_name): SSL Certbundle already exists, so we'll use the existing files."
        return 0
    fi

    if [ -f "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.crt" ] && [ -f "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.key" ]; then
        echo "ℹ️ NOTICE ($script_name): Custom SSL Certificate found in /etc/sss/private, so we'll use that."
        cat "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.key" "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.crt" > "$UNIT_CONFIG_DIRECTORY/$UNIT_CERTIFICATE_NAME.pem"
        return 0
    fi

    echo "$script_name: 🔐 SSL Certbundle not found. Generating self-signed SSL bundle..."
    mkdir -p /etc/ssl/private/
    openssl req -x509 -subj "/C=US/ST=Wisconsin/L=Milwaukee/O=IT/CN=default.test" -nodes -newkey rsa:2048 -keyout "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.key" -out "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.crt" -days 365 >/dev/null 2>&1
    cat "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.key" "/etc/ssl/private/$UNIT_CERTIFICATE_NAME.crt" > "$UNIT_CONFIG_DIRECTORY/$UNIT_CERTIFICATE_NAME.pem"
}

##########
# Main
##########
DOCKER_CMD=$1
if [ "$DISABLE_DEFAULT_CONFIG" = false ]; then

    # Configure Unit only if the command is "unitd" or "unitd-debug"
    if [ "$DOCKER_CMD" = "unitd" ] || [ "$DOCKER_CMD" = "unitd-debug" ]; then
        ssl_mode=$(echo "$SSL_MODE" | tr '[:upper:]' '[:lower:]')
        process_template "$UNIT_CONFIG_DIRECTORY/ssl-$ssl_mode.json.template" "$UNIT_CONFIG_DIRECTORY/config.json"
        if [ "$ssl_mode" != "off" ]; then
            validate_ssl
        fi
        configure_unit
    else
        if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
            echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal \"false\", so no initialization will be performed."
        fi
    fi

    # If debug is set, write replace "unitd" with "unitd-debug" and save this file in the docker_cmd_override file for execution by the entrypoint script
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "$@" | sed 's/unitd/unitd-debug/' > /tmp/docker_cmd_override
    fi
fi
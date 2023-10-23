#!/bin/sh
if [ "$LOG_LEVEL" = "debug" ]; then
  set -x
fi

set -e
script_name=$(basename "${0%.sh}")

WAITLOOPS=5
SLEEPSEC=1
UNIT_CONFIG_DIRECTORY=${UNIT_CONFIG_DIRECTORY:-"/etc/unit/config.d"}
UNIT_CONFIG_FILE=${UNIT_CONFIG_FILE:-"$UNIT_CONFIG_DIRECTORY/config.json"}

##########
# Functions
##########
process_template() {
    template_file=$1
    output_file=$2

    if [ -f "$output_file" ]; then
        echo "ℹ️ NOTICE ($script_name): $output_file already exists, so we'll use the existing file."
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
}

curl_put()
{
    RET=$(/usr/bin/curl -s -w '%{http_code}' -X PUT --data-binary @$1 --unix-socket /var/run/control.unit.sock http://localhost/$2)
    RET_BODY=$(echo $RET | /bin/sed '$ s/...$//')
    RET_STATUS=$(echo $RET | /usr/bin/tail -c 4)
    if [ "$RET_STATUS" -ne "200" ]; then
        echo "$script_name: Error: HTTP response status code is '$RET_STATUS'"
        echo "$RET_BODY"
        return 1
    else
        echo "$script_name: OK: HTTP response status code is '$RET_STATUS'"
        echo "$RET_BODY"
    fi
    return 0
}

##########
# Main
##########
if [ "$1" = "unitd" ] || [ "$1" = "unitd-debug" ]; then
    ssl_mode=$(echo "$SSL_MODE" | tr '[:upper:]' '[:lower:]')
    process_template "$UNIT_CONFIG_DIRECTORY/ssl-$ssl_mode.json.template" $UNIT_CONFIG_DIRECTORY/config.json

    echo "$script_name: Launching Unit daemon to perform initial configuration..."
    /usr/sbin/$1 --control unix:/var/run/control.unit.sock

    for i in $(/usr/bin/seq $WAITLOOPS); do
        if [ ! -S /var/run/control.unit.sock ]; then
            echo "$script_name: Waiting for control socket to be created..."
            /bin/sleep $SLEEPSEC
        else
            break
        fi
    done
    # even when the control socket exists, it does not mean unit has finished initialisation
    # this curl call will get a reply once unit is fully launched
    /usr/bin/curl -s -X GET --unix-socket /var/run/control.unit.sock http://localhost/

    echo "$script_name: Looking for certificate bundles in $UNIT_CONFIG_DIRECTORY..."
    for f in $(/usr/bin/find $UNIT_CONFIG_DIRECTORY -type f -name "*.pem"); do
        echo "$script_name: Uploading certificates bundle: $f"
        curl_put $f "certificates/$(basename $f .pem)"
    done

    echo "$script_name: Looking for JavaScript modules in $UNIT_CONFIG_DIRECTORY..."
    for f in $(/usr/bin/find $UNIT_CONFIG_DIRECTORY -type f -name "*.js"); do
        echo "$script_name: Uploading JavaScript module: $f"
        curl_put $f "js_modules/$(basename $f .js)"
    done

    echo "$script_name: Looking for configuration snippets in $UNIT_CONFIG_DIRECTORY..."
    for f in $(/usr/bin/find $UNIT_CONFIG_DIRECTORY -type f -name "*.json"); do
        echo "$script_name: Applying configuration $f";
        curl_put $f "config"
    done

    # warn on filetypes we don't know what to do with
    for f in $(/usr/bin/find $UNIT_CONFIG_DIRECTORY -type f -not -name "*.sh" -not -name "*.template" -not -name "*.json" -not -name "*.pem" -not -name "*.js"); do
        echo "$script_name: Ignoring $f";
    done

    echo "$script_name: Stopping Unit daemon after initial configuration..."
    kill -TERM $(/bin/cat /var/run/unit.pid)

    for i in $(/usr/bin/seq $WAITLOOPS); do
        if [ -S /var/run/control.unit.sock ]; then
            echo "$script_name: Waiting for control socket to be removed..."
            /bin/sleep $SLEEPSEC
        else
            break
        fi
    done
    if [ -S /var/run/control.unit.sock ]; then
        kill -KILL $(/bin/cat /var/run/unit.pid)
        rm -f /var/run/control.unit.sock
    fi

    echo
    echo "$script_name: Unit initial configuration complete; ready for start up..."
    echo
fi
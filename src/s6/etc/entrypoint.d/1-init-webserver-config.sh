#!/bin/sh
if [ "$LOG_LEVEL" = "trace" ]; then
  set -x
fi

##########
# Functions
##########
detect_web_server_type() {
    if command -v apache2 >/dev/null 2>&1; then
        echo "Apache"
    elif command -v nginx >/dev/null 2>&1; then
        echo "NGINX"
    else
        echo "None"
    fi
}

process_template() {
    template_file=$1
    output_file=$2

    if [ -f $output_file ]; then
      echo "Processing $template_file → $output_file..."
      envsubst < $template_file > $output_file
    else
      echo "⚠️ WARNING (init-webserver-config): $output_file already exists, so we'll use the existing file."
    fi
}

##########
# Main
##########

SERVER_TYPE=$(detect_web_server_type)

if [ "$SERVER_TYPE" = "Apache" ]; then
    echo "Apache is installed."
elif [ "$SERVER_TYPE" = "NGINX" ]; then
    process_template /etc/nginx/nginx.conf.template /etc/nginx/nginx.conf
    process_template /etc/nginx/conf.d/default.conf.template /etc/nginx/conf.d/default.conf
else
    echo "🛑 ERROR (1-init-webserver-config.sh): Neither Apache nor NGINX could be detected."
    exit 1
fi
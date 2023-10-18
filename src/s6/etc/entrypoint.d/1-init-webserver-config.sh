#!/bin/sh
if [ "$LOG_LEVEL" = "trace" ]; then
  set -x
fi
set -e

##########
# Functions
##########
detect_web_server_type() {
    if command -v apache2 >/dev/null 2>&1; then
      echo "Apache"
    elif command -v nginx >/dev/null 2>&1; then
      echo "NGINX"
    else
      echo "Unknown"
    fi
}

process_template() {
    template_file=$1
    output_file=$2

    if [ -f "$output_file" ]; then
        echo "ℹ️ NOTICE (init-webserver-config): $output_file already exists, so we'll use the existing file."
        return 0
    fi

    if [ ! -f "$template_file" ]; then
        echo "🛑 ERROR (init-webserver-config): Unable to initialize container. $output_file doesn't exist and we're unable to find a template for $template_file."
        return 1
    fi

    # Get all environment variables starting with 'NGINX_', 'SSL_', `LOG_`, and 'APACHE_'
    subst_vars=$(env | grep -E '^(NGINX_|SSL_|LOG_|APACHE_)' | cut -d= -f1 | awk '{printf "${%s},",$1}' | sed 's/,$//')

    # Validate that all required variables are set
    for var_name in $(echo "$subst_vars" | tr ',' ' '); do
        eval "value=\$$var_name" # Use eval to get the value of var_name
        if [ -z "$value" ]; then
            echo "🛑 ERROR (init-webserver-config): Environment variable $var_name is not set."
            return 1
        fi
    done

    echo "🏃‍♂️ Processing $template_file → $output_file..."
    envsubst "$subst_vars" < "$template_file" > "$output_file"
}


enable_nginx_site (){
    ssl_mode=$1
    default_nginx_site_config="/etc/nginx/conf.d/default.conf"

    # Transform to lowercase
    ssl_mode=$(echo "$ssl_mode" | tr '[:upper:]' '[:lower:]')

    # Link the site available to be the active site
    if [ -f "$default_nginx_site_config" ]; then
        echo "ℹ️ NOTICE (init-webserver-config): $default_nginx_site_config already exists, so we'll use the provided configuration."
    else
        echo "🔐 Enabling NGINX site with SSL \"$ssl_mode\"..."
        ln -s "/etc/nginx/sites-available/ssl-$ssl_mode" "$default_nginx_site_config"
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
    process_template /etc/nginx/site-opts.d/http.conf.template /etc/nginx/site-opts.d/http.conf
    process_template /etc/nginx/site-opts.d/https.conf.template /etc/nginx/site-opts.d/https.conf
    enable_nginx_site "$SSL_MODE"
else
    echo "🛑 ERROR (1-init-webserver-config.sh): Neither Apache nor NGINX could be detected."
    exit 1
fi
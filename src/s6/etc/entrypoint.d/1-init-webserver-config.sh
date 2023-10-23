#!/bin/sh
if [ "$LOG_LEVEL" = "debug" ]; then
  set -x
fi
set -e
script_name=$(basename "${0%.sh}")

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
        echo "ℹ️ NOTICE ($script_name): $output_file already exists, so we'll use the existing file."
        return 0
    fi

    if [ ! -f "$template_file" ]; then
        echo "🛑 ERROR ($script_name): Unable to initialize container. $output_file doesn't exist and we're unable to find a template for $template_file."
        return 1
    fi

    # Get all environment variables starting with 'NGINX_', 'SSL_', `LOG_`, and 'APACHE_'
    subst_vars=$(env | grep -E '^(NGINX_|SSL_|LOG_|APACHE_)' | cut -d= -f1 | awk '{printf "${%s},",$1}' | sed 's/,$//')

    # Validate that all required variables are set
    for var_name in $(echo "$subst_vars" | tr ',' ' '); do
        eval "value=\$$var_name" # Use eval to get the value of var_name
        if [ -z "$value" ]; then
            echo "🛑 ERROR ($script_name): Environment variable $var_name is not set."
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

    if [ "$ssl_mode" != "off" ]; then
        validate_ssl
    fi

    # Link the site available to be the active site
    if [ -f "$default_nginx_site_config" ]; then
        echo "ℹ️ NOTICE ($script_name): $default_nginx_site_config already exists, so we'll use the provided configuration."
    else
        echo "🔐 Enabling NGINX site with SSL \"$ssl_mode\"..."
        # Create the base directory if it doesn't exist
        base_dir=$(dirname "$default_nginx_site_config")
        mkdir -p "$base_dir"
        ln -s "/etc/nginx/sites-available/ssl-$ssl_mode" "$default_nginx_site_config"
    fi
}

validate_ssl(){
    if [ -z "$SSL_CERTIFICATE_FILE" ] || [ -z "$SSL_PRIVATE_KEY_FILE" ]; then
        echo "🛑 ERROR ($script_name): SSL_CERTIFICATE_FILE or SSL_PRIVATE_KEY_FILE is not set."
        return 1
    fi

    if ([ -f "$SSL_CERTIFICATE_FILE" ] && [ ! -f "$SSL_PRIVATE_KEY_FILE" ]) || 
       ([ ! -f "$SSL_CERTIFICATE_FILE" ] && [ -f "$SSL_PRIVATE_KEY_FILE" ]); then
        echo "🛑 ERROR ($script_name): Only one of the SSL certificate or private key exists. Check the SSL_CERTIFICATE_FILE and SSL_PRIVATE_KEY_FILE variables and try again."
        echo "🛑 ERROR ($script_name): SSL_CERTIFICATE_FILE: $SSL_CERTIFICATE_FILE"
        echo "🛑 ERROR ($script_name): SSL_PRIVATE_KEY_FILE: $SSL_PRIVATE_KEY_FILE"
        return 1
    fi

    if [ -f "$SSL_CERTIFICATE_FILE" ] && [ -f "$SSL_PRIVATE_KEY_FILE" ]; then
        echo "ℹ️ NOTICE ($script_name): SSL certificate and private key already exist, so we'll use the existing files."
        return 0
    fi

    echo "🔐 SSL Keypair not found. Generating self-signed SSL keypair..."
    mkdir -p /etc/ssl/private/
    openssl req -x509 -subj "/C=US/ST=Wisconsin/L=Milwaukee/O=IT/CN=default.test" -nodes -newkey rsa:2048 -keyout "$SSL_PRIVATE_KEY_FILE" -out "$SSL_CERTIFICATE_FILE" -days 365 >/dev/null 2>&1
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
    echo "🛑 ERROR ($script_name): Neither Apache nor NGINX could be detected."
    exit 1
fi
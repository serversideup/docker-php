#!/bin/sh
###################################################
# Usage: 5-generate-ssl.sh
###################################################
# This script generates a self-signed SSL certificate and key for the container.
script_name="generate-ssl"  

SSL_CERTIFICATE_FILE=${SSL_CERTIFICATE_FILE:-"/etc/ssl/private/self-signed-web.crt"}
SSL_PRIVATE_KEY_FILE=${SSL_PRIVATE_KEY_FILE:-"/etc/ssl/private/self-signed-web.key"}
SSL_MODE=${SSL_MODE:-"off"}
HEALTHCHECK_SSL_CERTIFICATE_FILE=${HEALTHCHECK_SSL_CERTIFICATE_FILE:-"/etc/ssl/healthcheck/localhost.crt"}
HEALTHCHECK_SSL_PRIVATE_KEY_FILE=${HEALTHCHECK_SSL_PRIVATE_KEY_FILE:-"/etc/ssl/healthcheck/localhost.key"}

if [ "$SSL_MODE" = "off" ]; then
    echo "ℹ️ NOTICE ($script_name): SSL mode is off, so we won't generate a self-signed SSL key pair."
    return 0
fi

if [ -z "$SSL_CERTIFICATE_FILE" ] || [ -z "$SSL_PRIVATE_KEY_FILE" ]; then
    echo "🛑 ERROR ($script_name): SSL_CERTIFICATE_FILE or SSL_PRIVATE_KEY_FILE is not set."
    return 1
fi

if [ -f "$SSL_CERTIFICATE_FILE" ] && [ ! -f "$SSL_PRIVATE_KEY_FILE" ] || 
   [ ! -f "$SSL_CERTIFICATE_FILE" ] && [ -f "$SSL_PRIVATE_KEY_FILE" ]; then
    echo "🛑 ERROR ($script_name): Only one of the SSL certificate or private key exists. Check the SSL_CERTIFICATE_FILE and SSL_PRIVATE_KEY_FILE variables and try again."
    echo "🛑 ERROR ($script_name): SSL_CERTIFICATE_FILE: $SSL_CERTIFICATE_FILE"
    echo "🛑 ERROR ($script_name): SSL_PRIVATE_KEY_FILE: $SSL_PRIVATE_KEY_FILE"
    return 1
fi

# Generate self-signed Healthcheck SSL keypair for FrankenPHP only
if [ -d "/etc/frankenphp/" ]; then
    echo "🔐 Generating self-signed Healthcheck SSL keypair..."
    openssl req -x509 \
        -subj "/CN=localhost" \
        -nodes -newkey rsa:2048 \
        -keyout "$HEALTHCHECK_SSL_PRIVATE_KEY_FILE" \
        -out "$HEALTHCHECK_SSL_CERTIFICATE_FILE" \
        -days 365 >/dev/null 2>&1
fi

if [ -f "$SSL_CERTIFICATE_FILE" ] && [ -f "$SSL_PRIVATE_KEY_FILE" ]; then
    echo "ℹ️ NOTICE ($script_name): SSL certificate and private key already exist, so we'll use the existing files."
    return 0
fi

echo "🔐 Default SSL Keypair not found. Generating self-signed SSL keypair..."
openssl req -x509 \
    -subj "/CN=localhost" \
    -nodes -newkey rsa:2048 \
    -keyout "$SSL_PRIVATE_KEY_FILE" \
    -out "$SSL_CERTIFICATE_FILE" \
    -days 365 >/dev/null 2>&1
exit 0
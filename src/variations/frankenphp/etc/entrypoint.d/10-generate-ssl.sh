#!/bin/sh
###################################################
# Usage: 10-generate-ssl.sh
###################################################
# This script generates a self-signed SSL certificate and key for the container.
script_name="generate-ssl"  

SSL_CERTIFICATE_FILE=${SSL_CERTIFICATE_FILE:-"/etc/ssl/private/self-signed-web.crt"}
SSL_PRIVATE_KEY_FILE=${SSL_PRIVATE_KEY_FILE:-"/etc/ssl/private/self-signed-web.key"}


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
openssl req -x509 -subj "/C=US/ST=Wisconsin/L=Milwaukee/O=IT/CN=*.dev.test,*.test,*.gitpod.io,*.ngrok.io,*.nip.io" -nodes -newkey rsa:2048 -keyout "$SSL_PRIVATE_KEY_FILE" -out "$SSL_CERTIFICATE_FILE" -days 365 >/dev/null 2>&1

exit 0
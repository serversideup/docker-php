#!/bin/sh
set -e

echo "🔥 DEBUG MODE"

# # Check if the current user is root (UID 0)
# if [[ $EUID -ne 0 ]]; then
#     echo "Error: You are not the root user. You need to set 'USER 0' and then trigger this command. This command will only work during a Docker build."
#     exit 1
# fi

# # Set NGINX to debug mode (if NGINX is installed)
# if [[ -f /etc/nginx/nginx.conf ]]; then
#     sed -i 's/^\terror_log.*/\terror_log \/proc\/self\/fd\/2 debug;/' /etc/nginx/nginx.conf
#     echo "🔥 DEBUG MODE: NGINX has been set to debug mode. 🔥"
# fi

# # Set Apache2 to debug mode (if Apache2 is installed)
# if [[ -f /etc/apache2/apache2.conf ]]; then
#     sed -i 's/^LogLevel.*/LogLevel debug/' /etc/apache2/apache2.conf
#     echo "🔥 DEBUG MODE: Apache2 has been set to debug mode. 🔥"
# fi

# # Set PHP FPM to debug mode
# sed -i 's/^;log_level.*/log_level = debug/' /etc/php/current_version/fpm/php-fpm.conf
# echo 'php_admin_value[display_errors] = On' >  /etc/php/current_version/fpm/pool.d/zzz-debug.conf
# echo 'php_admin_value[display_startup_errors] = On' >>  /etc/php/current_version/fpm/pool.d/zzz-debug.conf
# echo 'php_admin_value[error_reporting] = 32767' >>  /etc/php/current_version/fpm/pool.d/zzz-debug.conf

# echo "🔥 DEBUG MODE: PHP-FPM has been set to debug mode. 🔥"
####################################################
# Server Side Up -  PHP 7.4 / FPM-NGINX image 
#####################################################

FROM serversideup/php:7.4-fpm

LABEL maintainer="Jay Rogers <jay@serversideup.net>"

# 🚨 IMPORTANT: Change the SSMTP relay server if you want emails to work
#  For example, you can override this with the "docker run" command:
#  `docker run -e SSMTP_RELAY_SERVER=smtp serversideup/php7.4-fpm`
ENV MSMTP_RELAY_SERVER_HOSTNAME="mailhog" \
    MSMTP_RELAY_SERVER_PORT="1025" \
    PHP_POOL_NAME="www" \
    PHP_PM_CONTROL=ondemand \
    PHP_PM_MAX_CHILDREN="20" \
    PHP_PM_START_SERVERS="2" \
    PHP_PM_MIN_SPARE_SERVERS="1" \
    PHP_PM_MAX_SPARE_SERVERS="3"
    

# Install NGINX (web), MSMTP (email client), and Supervisor (process management)
RUN apt-get update \
    && echo "Install requirements..." \
    && apt-get -y --no-install-recommends install \
        msmtp \
        msmtp-mta \
        nginx \
        supervisor \
    && echo "Generate self-signed certs for NGINX..." \
    && mkdir -p /etc/nginx/ssl/ \
    && openssl req -x509 -subj "/C=US/ST=Wisconsin/L=Milwaukee/O=IT/CN=default.test" -nodes -newkey rsa:2048 -keyout /etc/nginx/ssl/self-signed.key -out /etc/nginx/ssl/self-signed.crt -days 365 \
    && echo "Clean up after ourselves..." \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/www/html/*

#NGINX: Set server config
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf

#NGINX: Copy over extra configurations for the "server" directive (for sites-available)
COPY etc/nginx/server-opts.d/* /etc/nginx/server-opts.d/

#NGINX: Set default vhost config
COPY etc/nginx/sites-available/default /etc/nginx/sites-available/default

#PHP: Copy over configuration to listen on the socket
COPY etc/php/7.x/fpm/pool.d/z-fpm-with-overrides.conf etc/php/7.4/fpm/pool.d/z-fpm-with-overrides.conf

# Copy over supervisor configurations
COPY etc/supervisor/conf.d/* /etc/supervisor/conf.d/

EXPOSE 80
EXPOSE 443

ADD start-container /usr/bin/start-container
RUN chmod +x /usr/bin/start-container

ENTRYPOINT ["start-container"]
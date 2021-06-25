####################################################
# Server Side Up -  PHP 8.0 / FPM-NGINX image 
#####################################################

FROM serversideup/php:beta-8.0-fpm

LABEL maintainer="Jay Rogers (@jaydrogers)"

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
    && echo "Fixing permissions issues on the webroot..." \
    && chown -R webuser:webgroup /var/www/html/ \
    && echo "Clean up after ourselves..." \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/www/html/*

# Copy over S6 configurations
COPY etc/services.d/ /etc/services.d/
COPY etc/cont-init.d/ /etc/cont-init.d/

#NGINX: Set server configs
COPY etc/nginx/ /etc/nginx/

#PHP: Copy PHP configurations
COPY etc/php/fpm/pool.d/ /etc/php/8.0/fpm/pool.d/

EXPOSE 80
EXPOSE 443

HEALTHCHECK --interval=1m --timeout=10s \
  CMD curl -k -f https://127.0.0.1/ping/ || exit 1


ENTRYPOINT ["/init"]
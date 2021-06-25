####################################################
# Server Side Up -  PHP 7.4 / FPM image 
#####################################################

FROM serversideup/php:beta-7.4-cli

LABEL maintainer="Jay Rogers (@jaydrogers)"

# Set default PHP environment variables

ENV PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=On \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    PHP_POOL_NAME="www" \
    PHP_PM_CONTROL=dynamic \
    PHP_PM_MAX_CHILDREN="20" \
    PHP_PM_START_SERVERS="2" \
    PHP_PM_MIN_SPARE_SERVERS="1" \
    PHP_PM_MAX_SPARE_SERVERS="3"

# Install FPM
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        php7.4-fpm \
        && echo "Allow pool name to be set via env, default it to 'www'..." \
    && sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php/7.4/fpm/pool.d/www.conf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Copy over S6 configurations
COPY etc/services.d/ /etc/services.d/
COPY etc/cont-init.d/ /etc/cont-init.d/

# Apply PHP configuration files
COPY etc/php/fpm/pool.d/ /etc/php/7.4/fpm/pool.d/

ENTRYPOINT ["/init" ]

HEALTHCHECK \
  CMD curl -f http://127.0.0.1:9000/ping/ || exit 1

# Open up fcgi port
EXPOSE 9000
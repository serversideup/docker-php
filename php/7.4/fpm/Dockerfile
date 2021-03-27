####################################################
# Server Side Up -  PHP 7.4 / FPM image 
#####################################################

FROM serversideup/php:7.4-cli

LABEL maintainer="Jay Rogers <jay@serversideup.net>"

# Set default PHP environment variables

ENV PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=On \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    PHP_POOL_NAME="www"

# Install FPM
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        php7.4-fpm \
        && echo "Allow pool name to be set via env, default it to 'www'..." \
    && sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php/7.4/fpm/pool.d/www.conf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Make sure the container comes down clean
STOPSIGNAL SIGQUIT

# Apply PHP configuration file
COPY etc/php/7.x/fpm/pool.d/y-override-php-defaults.conf /etc/php/7.4/fpm/pool.d/y-override-php-defaults.conf

CMD ["/usr/sbin/php-fpm7.4", "-O" ]

# Open up fcgi port
EXPOSE 9000
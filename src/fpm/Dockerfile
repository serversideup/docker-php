ARG UPSTREAM_CHANNEL=''
ARG PHP_VERSION='8.1'
ARG BASE_IMAGE="serversideup/php:${UPSTREAM_CHANNEL}${PHP_VERSION}-cli"

FROM ${BASE_IMAGE}

LABEL maintainer="Jay Rogers (@jaydrogers)"

ENV PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_ERROR_REPORTING="22527" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_OPEN_BASEDIR="$WEBUSER_HOME:/dev/stdout:/tmp" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    PHP_POOL_NAME="www" \
    PHP_PM_CONTROL=dynamic \
    PHP_PM_MAX_CHILDREN="20" \
    PHP_PM_START_SERVERS="2" \
    PHP_PM_MIN_SPARE_SERVERS="1" \
    PHP_PM_MAX_SPARE_SERVERS="3"

# install `php-fpm` (php server) and `libfcgi-bin` (for healthchecks)
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        php${BUILD_PHP_VERSION}-fpm libfcgi-bin \
    \
    # allow `php-fpm` script to be referenced without a version
    && ln -sf /usr/sbin/php-fpm${BUILD_PHP_VERSION} /usr/sbin/php-fpm \
    \
    # set pool name to be configurable by env
    && sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php/${BUILD_PHP_VERSION}/fpm/pool.d/www.conf \
    \
    # install `php-fpm-healthcheck`
    && curl -o /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck \
    \
    # cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/www/html/*

COPY --chmod=755 etc/s6-overlay/ /etc/s6-overlay/

COPY etc/php/fpm/pool.d/ /etc/php/current_version/fpm/pool.d/

ENTRYPOINT ["/init" ]

EXPOSE 9000
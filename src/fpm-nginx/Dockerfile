ARG UPSTREAM_CHANNEL=''
ARG PHP_VERSION='8.2'
ARG BASE_IMAGE="serversideup/php:${UPSTREAM_CHANNEL}${PHP_VERSION}-fpm"

FROM ${BASE_IMAGE}

LABEL maintainer="Jay Rogers (@jaydrogers)"

ENV MSMTP_RELAY_SERVER_HOSTNAME="mailhog" \
    MSMTP_RELAY_SERVER_PORT="1025" \
    PHP_POOL_NAME="www" \
    PHP_PM_CONTROL=ondemand \
    PHP_PM_MAX_CHILDREN="20" \
    PHP_PM_START_SERVERS="2" \
    PHP_PM_MIN_SPARE_SERVERS="1" \
    PHP_PM_MAX_SPARE_SERVERS="3" \
    SSL_MODE="full"

# switch to root so we can install packages
USER 0

# install`nginx` (web server) & `msmtp` (smtp client)
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        msmtp \
        msmtp-mta \
        nginx \
    \
    # ensure web permissions are correct
    && chown -R webuser:webgroup /var/www/html/ \
    \
    # cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/www/html/* \
    && rm -f /etc/nginx/sites-enabled/default

# Copy over S6 configurations
COPY --chmod=755 etc/s6-overlay/ /etc/s6-overlay/

COPY etc/nginx/ /etc/nginx/

COPY etc/php/fpm/pool.d/ /etc/php/current_version/fpm/pool.d/

# drop to our unprivileged user
USER webuser

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/init"]
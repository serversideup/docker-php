ARG UPSTREAM_CHANNEL=''
ARG BASE_OS_FLAVOR='ubuntu'
ARG BASE_OS_VERSION='22.04'
ARG BASE_IMAGE="serversideup/s6-overlay:${UPSTREAM_CHANNEL}${BASE_OS_FLAVOR}-${BASE_OS_VERSION}"

# add ondrej repository
FROM ${BASE_IMAGE} as repo-config

RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg2 ca-certificates software-properties-common \
    && add-apt-repository -y ppa:ondrej/php

# build final image
FROM ${BASE_IMAGE}
LABEL maintainer="Jay Rogers (@jaydrogers)"

ARG PHP_VERSION='8.1'

ENV BUILD_PHP_VERSION=$PHP_VERSION \
    DEBIAN_FRONTEND=noninteractive \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_VERBOSITY=1 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    WEBUSER_HOME="/var/www/html" \
    PUID=9999 \
    PGID=9999

COPY --from=repo-config /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=repo-config /etc/apt/trusted.gpg.d/ondrej-ubuntu-php.gpg /etc/apt/trusted.gpg.d/ondrej-ubuntu-php.gpg

ADD php-version-packages/${PHP_VERSION}.txt /tmp/php-packages.txt

RUN apt-get update \
    \
    # configure web user and group
    && groupadd -r -g $PGID webgroup \
    && useradd --no-log-init -r -s /usr/bin/bash -d $WEBUSER_HOME -u $PUID -g $PGID webuser \
    \
    # install dependencies
    && apt-get -y --no-install-recommends install \
        ca-certificates \
        curl \
        unzip \
    \
    # install PHP packages
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        $(cat /tmp/php-packages.txt) \
    \
    # set symlink to version number for script management
    && ln -sf /etc/php/${BUILD_PHP_VERSION}/ /etc/php/current_version \
    \
    # cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY --chmod=755 etc/s6-overlay/ /etc/s6-overlay/

WORKDIR /var/www/html

ENTRYPOINT ["/init"]

CMD ["php", "-a"]
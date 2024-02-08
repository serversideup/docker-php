ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.3'
ARG PHP_VARIATION='frankenphp'
ARG GO_VERSION='1.21'
ARG BASE_IMAGE="php:${PHP_VERSION}-zts-${BASE_OS_VERSION}"

##########
# FrankenPHP: Common Image
##########
FROM ${BASE_IMAGE} as common

# copy our scripts
COPY --chmod=755 src/common/ /

##########
# Set GoLang Base Image
##########
FROM golang:${GO_VERSION}-${BASE_OS_VERSION} as golang-base

##########
# FrankenPHP: Build
##########
FROM common as build
ARG FRANKEN_PHP_VERSION='1.1.0'

COPY --from=golang-base /usr/local/go /usr/local/go

ENV PATH /usr/local/go/bin:$PATH

RUN docker-php-serversideup-dep-install-debian \
        libargon2-dev \
        libbrotli-dev \
        libcurl4-openssl-dev \
        libonig-dev \
        libreadline-dev \
        libsodium-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev \
        && \
    curl -L https://github.com/dunglas/frankenphp/archive/refs/tags/v${FRANKEN_PHP_VERSION}.tar.gz | tar -xz -C /tmp/ && \
    cd /tmp/frankenphp-${FRANKEN_PHP_VERSION}/caddy/frankenphp && \
    CGO_CFLAGS=$(php-config --includes) CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" go build -o /usr/local/bin/frankenphp

##########
# FrankenPHP: Main Image
##########
FROM common

COPY --from=build /usr/local/bin/frankenphp /usr/local/bin/frankenphp

LABEL org.opencontainers.image.title="serversideup/php (${PHP_VARIATION})" \
    org.opencontainers.image.description="Supercharge your PHP experience. Based off the offical PHP images, serversideup/php includes pre-configured PHP extensions and settings for enhanced performance and security. Optimized for Laravel and WordPress." \
    org.opencontainers.image.url="https://serversideup.net/open-source/docker-php/" \
    org.opencontainers.image.source="https://github.com/serversideup/docker-php" \
    org.opencontainers.image.documentation="https://serversideup.net/open-source/docker-php/docs/" \
    org.opencontainers.image.vendor="ServerSideUp" \
    org.opencontainers.image.authors="Jay Rogers (@jaydrogers)" \
    org.opencontainers.image.version="${REPOSITORY_BUILD_VERSION}" \
    org.opencontainers.image.licenses="GPL-3.0-or-later"

ENV APP_BASE_DIR=/var/www/html \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    DISABLE_DEFAULT_CONFIG=false \
    LOG_OUTPUT_LEVEL=warn \
    PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_DISPLAY_STARTUP_ERRORS=Off \
    PHP_ERROR_LOG="/dev/stderr" \
    PHP_ERROR_REPORTING="22527" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_MAX_INPUT_TIME="-1" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_OPEN_BASEDIR="" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_SESSION_COOKIE_SECURE=false \
    PHP_UPLOAD_MAX_FILE_SIZE="100M"

# install pecl extensions & dependencies
RUN docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN}"  && \
    docker-php-serversideup-install-php-ext-installer && \
    \
    # Make composer cache directory
    mkdir -p "${COMPOSER_HOME}" && \
    chown -R www-data:www-data "${COMPOSER_HOME}" && \
    \
    # Install default PHP extensions
    install-php-extensions "${DEPENDENCY_PHP_EXTENSIONS}"

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR ${APP_BASE_DIR}

ENTRYPOINT ["docker-php-serversideup-entrypoint"]
ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.3'
ARG PHP_VARIATION='cli'

##########
# CLI: Main Image
##########
FROM php:${PHP_VERSION}-${PHP_VARIATION}-${BASE_OS_VERSION}

ARG DEPENDENCY_PACKAGES_ALPINE='shadow'
ARG DEPENDENCY_PACKAGES_DEBIAN='zip'
ARG DEPENDENCY_PHP_EXTENSIONS='pcntl pdo_mysql pdo_pgsql redis zip'
ARG REPOSITORY_BUILD_VERSION='dev'

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

# copy our scripts
COPY --chmod=755 src/common/ /

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
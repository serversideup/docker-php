ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.3'
ARG PHP_VARIATION='cli'
ARG DEPENDENCY_PACKAGES_ALPINE='postgresql-dev libzip-dev sqlite sqlite-dev'
ARG DEPENDENCY_PACKAGES_DEBIAN='libpq-dev libzip-dev sqlite3 libsqlite3-dev'
ARG PECL_PACKAGES

FROM php:${PHP_VERSION}-${PHP_VARIATION}-${BASE_OS_VERSION}
LABEL maintainer="Jay Rogers (@jaydrogers)"

ENV APP_BASE_DIR=/var/www/html \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    DISABLE_DEFAULT_CONFIG=false \
    LOG_LEVEL=warn \
    PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_DISPLAY_STARTUP_ERRORS=Off \
    PHP_ERROR_LOG="/dev/stderr" \
    PHP_ERROR_REPORTING="22527" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_SESSION_COOKIE_SECURE=false \
    PHP_UPLOAD_MAX_FILE_SIZE="100M"

# copy our scripts
COPY --chmod=755 src/common/ /

# install pecl extensions & dependencies
RUN docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN}"  && \
    \
    # Install required required extensions for Laravel
    docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite zip && \
    \
    # PCNTL install
    docker-php-ext-configure pcntl --enable-pcntl && \
    docker-php-ext-install pcntl && \
    \
    # Install pecl extensions (if defined)
    docker-php-serversideup-pecl-install $PECL_PACKAGES

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENTRYPOINT ["docker-php-serversideup-entrypoint"]
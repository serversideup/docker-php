ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.2'
ARG PHP_VARIATION='unit'
ARG BASE_IMAGE="php:${PHP_VERSION}-cli-${BASE_OS_VERSION}"

##########
# Unit Build
##########
FROM ${BASE_IMAGE} as build
ARG DEPENDENCY_PACKAGES_ALPINE='build-base curl tar mercurial openssl-dev pcre2-dev'
ARG DEPENDENCY_PACKAGES_DEBIAN='ca-certificates mercurial build-essential libssl-dev libpcre2-dev curl pkg-config'
ARG NGINX_UNIT_VERSION='1.31.1'

# copy our scripts
COPY --chmod=755 src/common/ /

# Download and untar the Nginx Unit source code
RUN docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN}"  && \
    cd /usr/src/ && \
    hg clone -u ${NGINX_UNIT_VERSION} https://hg.nginx.org/unit && \
    cd unit

# Configure and build Nginx Unit with PHP module
WORKDIR /usr/src/unit/
RUN NCPU="$(getconf _NPROCESSORS_ONLN)" && \
    CONFIGURE_ARGS="--prefix=/usr \
                    --statedir=/var/lib/unit \
                    --control=unix:/var/run/control.unit.sock \
                    --runstatedir=/var/run \
                    --pid=/var/run/unit.pid \
                    --logdir=/var/log \
                    --log=/dev/stdout \
                    --tmpdir=/var/tmp \
                    --user=www-data \
                    --group=www-data \
                    --openssl" && \
    ./configure $CONFIGURE_ARGS && \
    ./configure php --config=php-config --module=php && \
    make -j $NCPU all && \
    make install

##########
# Main
##########
FROM ${BASE_IMAGE}
LABEL maintainer="Jay Rogers (@jaydrogers)"

ARG DEPENDENCY_PACKAGES_ALPINE='gettext postgresql-dev libzip-dev sqlite sqlite-dev'
ARG DEPENDENCY_PACKAGES_DEBIAN='gettext-base libpq-dev libzip-dev sqlite3 libsqlite3-dev'

ENV APP_BASE_DIR=/var/www/html \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
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
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    SSL_CERT_BUNDLE_FILE=/etc/ssl/certs/private/bundle.pem \
    SSL_MODE=off \
    UNIT_CERTIFICATE_NAME=self-signed-web \
    UNIT_CONFIG_DIRECTORY=/etc/unit/config.d \
    UNIT_CONFIG_FILE=/etc/unit/config.d/config.json

# Use second ENV layer for variable substitutions
ENV UNIT_WEBROOT=${APP_BASE_DIR}/public

# Copy NGINX Unit binaries and modules from build stage
COPY --from=build /usr/sbin/unitd /usr/sbin/
COPY --from=build /usr/lib/unit/ /usr/lib/unit/

# Copy NGINX Unit state directory from build stage
COPY --from=build /var/lib/unit/ /var/lib/unit/

# copy our scripts
COPY --chmod=755 src/common/ /
COPY --chmod=755 src/variations/unit/etc/ /etc/

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# install pecl extensions, dependencies, and clean up
RUN docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN}"  && \
    \
    docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite zip && \
    # PCNTL install
    docker-php-ext-configure pcntl --enable-pcntl && \
    docker-php-ext-install pcntl && \
    docker-php-serversideup-pecl-install $PECL_PACKAGES

# Expose the necessary port(s)
EXPOSE 80 443

ENTRYPOINT ["docker-php-serversideup-entrypoint"]

# Set the command to run Nginx Unit
CMD ["unitd", "--no-daemon"]
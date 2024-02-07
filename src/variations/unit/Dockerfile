ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.3'
ARG PHP_VARIATION='unit'
ARG BASE_IMAGE="php:${PHP_VERSION}-cli-${BASE_OS_VERSION}"

##########
# Unit Build
##########
FROM ${BASE_IMAGE} as build
ARG DEPENDENCY_PACKAGES_ALPINE='build-base curl tar mercurial openssl-dev pcre2-dev shadow'
ARG DEPENDENCY_PACKAGES_DEBIAN='ca-certificates mercurial build-essential libssl-dev libpcre2-dev curl pkg-config'
ARG NGINX_UNIT_VERSION='1.31.1'

# copy our scripts
COPY --chmod=755 src/common/ /

# Download and untar the Nginx Unit source code
RUN set -ex && \
    docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN}"  && \
    mkdir -p /usr/lib/unit/modules /usr/lib/unit/debug-modules && \
    cd /usr/src/ && \
    hg clone -u ${NGINX_UNIT_VERSION} https://hg.nginx.org/unit && \
    cd unit && \
    NCPU="$(getconf _NPROCESSORS_ONLN)" && \
    DEB_HOST_MULTIARCH="$(dpkg-architecture -q DEB_HOST_MULTIARCH)" && \
    CC_OPT="$(DEB_BUILD_MAINT_OPTIONS="hardening=+all,-pie" DEB_CFLAGS_MAINT_APPEND="-Wp,-D_FORTIFY_SOURCE=2 -fPIC" dpkg-buildflags --get CFLAGS)" && \
    LD_OPT="$(DEB_BUILD_MAINT_OPTIONS="hardening=+all,-pie" DEB_LDFLAGS_MAINT_APPEND="-Wl,--as-needed -pie" dpkg-buildflags --get LDFLAGS)" && \
    CONFIGURE_ARGS_MODULES="--prefix=/usr \
                --statedir=/var/lib/unit \
                --control=unix:/var/run/control.unit.sock \
                --runstatedir=/var/run \
                --pid=/var/run/unit.pid \
                --logdir=/var/log \
                --log=/dev/stdout \
                --tmpdir=/var/tmp \
                --user=www-data \
                --group=www-data \
                --openssl \
                --libdir=/usr/lib/$DEB_HOST_MULTIARCH" && \
    CONFIGURE_ARGS="$CONFIGURE_ARGS_MODULES --njs" && \
    make -j $NCPU -C pkg/contrib .njs && \
    export PKG_CONFIG_PATH=$(pwd)/pkg/contrib/njs/build && \
    ./configure $CONFIGURE_ARGS --cc-opt="$CC_OPT" --ld-opt="$LD_OPT" --modulesdir=/usr/lib/unit/debug-modules --debug && \
    make -j $NCPU unitd && \
    install -pm755 build/sbin/unitd /usr/sbin/unitd-debug && \
    make clean && \
    ./configure $CONFIGURE_ARGS --cc-opt="$CC_OPT" --ld-opt="$LD_OPT" --modulesdir=/usr/lib/unit/modules && \
    make -j $NCPU unitd && \
    install -pm755 build/sbin/unitd /usr/sbin/unitd && \
    make clean && \
    /bin/true && \
    ./configure $CONFIGURE_ARGS_MODULES --cc-opt="$CC_OPT" --modulesdir=/usr/lib/unit/debug-modules --debug && \
    ./configure php && \
    make -j $NCPU php-install && \
    make clean && \
    ./configure $CONFIGURE_ARGS_MODULES --cc-opt="$CC_OPT" --modulesdir=/usr/lib/unit/modules && \
    ./configure php && \
    make -j $NCPU php-install && \
    mkdir -p /var/lib/unit/

##########
# Unit: Main Image
##########
FROM ${BASE_IMAGE}

ARG DEPENDENCY_PACKAGES_ALPINE='gettext'
ARG DEPENDENCY_PACKAGES_DEBIAN='gettext-base zip'
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
COPY --from=build /usr/sbin/unitd-debug /usr/sbin/
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
    docker-php-serversideup-install-php-ext-installer && \
    \
    # Make composer cache directory
    mkdir -p "${COMPOSER_HOME}" && \
    chown -R www-data:www-data "${COMPOSER_HOME}" && \
    \
    # Install default PHP extensions
    install-php-extensions "${DEPENDENCY_PHP_EXTENSIONS}"

EXPOSE 80 443

ENTRYPOINT ["docker-php-serversideup-entrypoint"]

STOPSIGNAL SIGTERM

WORKDIR ${APP_BASE_DIR}

CMD ["unitd", "--no-daemon"]
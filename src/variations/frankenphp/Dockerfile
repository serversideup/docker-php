# check=skip=SecretsUsedInArgOrEnv
ARG BASE_OS_VERSION='trixie'
ARG PHP_VERSION='8.4'
ARG BASE_IMAGE="php:${PHP_VERSION}-zts-${BASE_OS_VERSION}"
ARG FRANKENPHP_VERSION='1.9.0'
ARG GOLANG_VERSION='1.25'

########################
# Common
########################
FROM ${BASE_IMAGE} AS common
ARG REPOSITORY_BUILD_VERSION='dev'

# copy our scripts
COPY --chmod=755 src/common/ /

RUN set -eux; \
    # Create directories
	mkdir -p \
		/var/www/html/public \
		/var/www/config/caddy \
		/var/www/data/caddy \
		/etc/caddy \
		/etc/frankenphp/ssl-mode \
        /etc/frankenphp/log-level \
        /etc/frankenphp/caddyfile.d; \
    # Create default index.php
	echo '<?php phpinfo();' > /var/www/html/public/index.php; \
    # Create symbolic links
    ln -sf /var/www/html /app; \
    ln -sf /var/www/config/ /config; \
    ln -sf /var/www/data/ /data; \
    # Ensure /var/www/ has the correct permissions
    chown -R www-data:www-data /var/www/; \
    chmod -R 755 /var/www/; \
    \
    # Set the image version
    echo "${REPOSITORY_BUILD_VERSION}" > /etc/serversideup-php-version;
    # \
    # # Make composer cache directory
    # mkdir -p "${COMPOSER_HOME}"; \
    # chown -R www-data:www-data "${COMPOSER_HOME}";

####################
# Go Image
####################
FROM golang:${GOLANG_VERSION} AS golang-image

####################
# FrankenPHP Build
####################
FROM common AS frankenphp-build
ARG FRANKENPHP_VERSION
ARG GOLANG_VERSION
ARG BUILD_DEPENDENCY_PACKAGES_ALPINE='argon2-dev bash brotli-dev ca-certificates coreutils curl-dev git gnu-libiconv-dev libcap libsodium-dev cmake libstdc++ libxml2-dev linux-headers mailcap oniguruma-dev openssl-dev readline-dev sqlite-dev upx'
ARG BUILD_DEPENDENCY_PACKAGES_DEBIAN='cmake git libargon2-dev libbrotli-dev libcap2-bin libcurl4-openssl-dev libonig-dev libreadline-dev libsodium-dev libsqlite3-dev libssl-dev libxml2-dev mailcap zlib1g-dev'

COPY --from=golang-image /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOTOOLCHAIN="local"

# Install dependencies & Download FrankenPHP
RUN docker-php-serversideup-dep-install-alpine "$PHPIZE_DEPS ${BUILD_DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-serversideup-dep-install-debian "${BUILD_DEPENDENCY_PACKAGES_DEBIAN}"

# Install e-dant/watcher (necessary for file watching)
WORKDIR /usr/local/src/watcher
RUN curl -s https://api.github.com/repos/e-dant/watcher/releases/latest | \
    grep tarball_url | \
    awk '{ print $2 }' | \
    sed 's/,$//' | \
    sed 's/"//g' | \
    xargs curl -L | \
    tar xz --strip-components 1 && \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build && \
    cmake --install build && \
    if cat /etc/os-release | grep -q 'debian'; then \
        ldconfig; \
    fi

# Download and build FrankenPHP
WORKDIR /go/src/app
ENV CGO_CFLAGS="-DFRANKENPHP_VERSION=$FRANKENPHP_VERSION $PHP_CFLAGS" \
    CGO_CPPFLAGS=$PHP_CPPFLAGS \
    GOBIN=/usr/local/bin

RUN if cat /etc/os-release | grep -q 'debian'; then \
        export CGO_LDFLAGS="-L/usr/local/lib -lssl -lcrypto -lreadline -largon2 -lcurl -lonig -lz $PHP_LDFLAGS"; \
        export ADDITIONAL_BUILD_FLAGS=''; \
    elif cat /etc/os-release | grep -q 'alpine'; then \
        export CGO_LDFLAGS="-lssl -lcrypto -lreadline -largon2 -lcurl -lonig -lz $PHP_LDFLAGS"; \
        export ADDITIONAL_BUILD_FLAGS="-extldflags '-Wl,-z,stack-size=0x80000'"; \
    else \
        echo "Unsupported OS"; \
        exit 1; \
    fi; \
    git clone --depth 1 --branch v${FRANKENPHP_VERSION} \
    https://github.com/php/frankenphp.git .; \
    go mod download;\
    cd /go/src/app/caddy/frankenphp; \
    ../../go.sh install -ldflags "-w -s $ADDITIONAL_BUILD_FLAGS -X 'github.com/caddyserver/caddy/v2.CustomVersion=FrankenPHP $FRANKENPHP_VERSION PHP $PHP_VERSION Caddy'" -buildvcs=true; \
    frankenphp version; \
    frankenphp build-info; \
    setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp

# WORKDIR /go/src/app/caddy

####################
# FrankenPHP Final
####################
FROM common AS final
ARG DEPENDENCY_PACKAGES_ALPINE='shadow libstdc++'
ARG DEPENDENCY_PACKAGES_DEBIAN='libstdc++6'
ARG DEPENDENCY_PHP_EXTENSIONS='opcache pcntl pdo_mysql pdo_pgsql redis zip'

LABEL org.opencontainers.image.title="serversideup/php (frankenphp)" \
    org.opencontainers.image.description="Supercharge your PHP experience. Based off the official PHP images, serversideup/php includes pre-configured PHP extensions and settings for enhanced performance and security. Optimized for Laravel and WordPress." \
    org.opencontainers.image.url="https://serversideup.net/open-source/docker-php/" \
    org.opencontainers.image.source="https://github.com/serversideup/docker-php" \
    org.opencontainers.image.documentation="https://serversideup.net/open-source/docker-php/docs/" \
    org.opencontainers.image.vendor="ServerSideUp" \
    org.opencontainers.image.authors="Jay Rogers (@jaydrogers)" \
    org.opencontainers.image.version="${REPOSITORY_BUILD_VERSION}" \
    org.opencontainers.image.licenses="GPL-3.0-or-later"

    ENV APP_BASE_DIR=/var/www/html \
    CADDY_ADMIN="off" \
    CADDY_APP_PUBLIC_PATH="/var/www/html/public" \
    CADDY_AUTO_HTTPS="off" \
    CADDY_GLOBAL_OPTIONS="" \
    CADDY_HTTP_PORT="8080" \
    CADDY_HTTPS_PORT="8443" \
    CADDY_HTTP_SERVER_ADDRESS="http://" \
    CADDY_HTTPS_SERVER_ADDRESS="https://" \
    CADDY_PHP_SERVER_OPTIONS="" \
    CADDY_SERVER_EXTRA_DIRECTIVES="" \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    DISABLE_DEFAULT_CONFIG=false \
    FRANKEN_PHP_CONFIG="" \
    LOG_OUTPUT_LEVEL=warn \
    HEALTHCHECK_PATH="/healthcheck" \
    PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_DISPLAY_STARTUP_ERRORS=Off \
    PHP_ERROR_LOG="/dev/stderr" \
    PHP_ERROR_REPORTING="22527" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_MAX_INPUT_TIME="-1" \
    PHP_MAX_INPUT_VARS="1000" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_OPCACHE_ENABLE="0" \
    PHP_OPCACHE_FORCE_RESTART_TIMEOUT="180" \
    PHP_OPCACHE_INTERNED_STRINGS_BUFFER="8" \
    PHP_OPCACHE_JIT="off" \
    PHP_OPCACHE_JIT_BUFFER_SIZE="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="128" \
    PHP_OPCACHE_REVALIDATE_FREQ="2" \
    PHP_OPCACHE_SAVE_COMMENTS="1" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS="1" \
    PHP_OPEN_BASEDIR="" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_SESSION_COOKIE_SECURE=false \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    SHOW_WELCOME_MESSAGE=true \
    SSL_MODE=off \
    SSL_CERTIFICATE_FILE="/etc/ssl/private/self-signed-web.crt" \
    SSL_CERTIFICATE_KEY_FILE="/etc/ssl/private/self-signed-web.key" \
    XDG_CONFIG_HOME=/config \
    XDG_DATA_HOME=/data

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY --from=frankenphp-build /usr/local/bin/frankenphp /usr/local/bin/frankenphp
COPY --from=frankenphp-build /usr/local/lib/libwatcher* /usr/local/lib/

COPY src/variations/frankenphp/etc/frankenphp/ /etc/frankenphp/
COPY src/variations/frankenphp/etc/entrypoint.d/ /etc/entrypoint.d/

RUN \
    docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}"; \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN}"; \
    # Fix for the file watcher on arm
    if cat /etc/os-release | grep -q 'alpine'; then \
        ldconfig /usr/local/lib; \
    elif cat /etc/os-release | grep -q 'debian'; then \
        ldconfig; \
    else \
        echo "Unsupported OS"; \
        exit 1; \
    fi; \
    # Make composer cache directory
    mkdir -p "${COMPOSER_HOME}" && \
    chown -R www-data:www-data "${COMPOSER_HOME}" && \
    \
    # Install PHP Extension installer
    docker-php-serversideup-install-php-ext-installer; \
    # Install default PHP extensions
    install-php-extensions "${DEPENDENCY_PHP_EXTENSIONS}"; \
    # Ensure permissions are set for www-data
    docker-php-serversideup-set-file-permissions --owner www-data:www-data --service frankenphp

WORKDIR ${APP_BASE_DIR}

USER www-data

EXPOSE 8080 8443 8443/udp 2019

ENTRYPOINT ["docker-php-serversideup-entrypoint"]

CMD ["frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile", "--adapter", "caddyfile"]
ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.3'
ARG PHP_VARIATION='fpm-nginx'
ARG BASE_IMAGE="php:${PHP_VERSION}-fpm-${BASE_OS_VERSION}"

##########
# S6 Build
##########
FROM ${BASE_IMAGE} as s6-build

ARG S6_DIR='/opt/s6/'
ARG S6_SRC_URL="https://github.com/just-containers/s6-overlay/releases/download"

# copy our scripts
COPY --chmod=755 src/common/ /
COPY --chmod=755 src/s6/ /

RUN docker-php-serversideup-s6-install

####################
# NGINX Signing Key
####################
FROM php:${PHP_VERSION}-fpm as nginx-repo-config

ARG SIGNING_KEY_URL="https://nginx.org/keys/nginx_signing.key"
ARG SIGNING_FINGERPRINT="573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62"
ARG SIGNING_KEY_OUTPUT_FILE="/usr/share/keyrings/nginx-archive-keyring.gpg"

# copy our scripts
COPY --chmod=755 src/common/ /

RUN docker-php-serversideup-dep-install-debian "curl gnupg2 ca-certificates lsb-release debian-archive-keyring" && \
    \
    # Import signing key
    curl "$SIGNING_KEY_URL" | gpg --dearmor | tee "$SIGNING_KEY_OUTPUT_FILE" && \
    \
    # Verify signing key
    VALID_KEY=$(gpg --dry-run --quiet --no-keyring --import --import-options import-show "$SIGNING_KEY_OUTPUT_FILE" | grep "$SIGNING_FINGERPRINT") && \
    \
    if [ -z "$VALID_KEY" ]; then \
        echo "ERROR: Key did not match signing signature!" && \
        exit 1; \
    fi && \
    \
    # setup apt repository for stable nginx packages
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list && \
    \
    # setup repository pinning to prefer nginx packages over debian packages
    printf "Package: *\nPin: origin nginx.org\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx

##########
# Main
##########
FROM ${BASE_IMAGE}
LABEL maintainer="Jay Rogers (@jaydrogers)"

ARG DEPENDENCY_PACKAGES_ALPINE='fcgi gettext postgresql-dev libzip-dev sqlite sqlite-dev'
ARG DEPENDENCY_PACKAGES_DEBIAN='libfcgi-bin gettext-base libpq-dev libzip-dev sqlite3 libsqlite3-dev'
ARG PECL_PACKAGES

ENV APP_BASE_DIR=/var/www/html \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    DISABLE_DEFAULT_CONFIG=false \
    LOG_LEVEL=warn \
    NGINX_SERVER_TOKENS=off \
    NGINX_USER=nginx \
    PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_DISPLAY_STARTUP_ERRORS=Off \
    PHP_ERROR_LOG="/dev/stderr" \
    PHP_ERROR_REPORTING="22527" \
    PHP_FPM_PM_CONTROL=dynamic \
    PHP_FPM_PM_MAX_CHILDREN="20" \
    PHP_FPM_PM_MAX_SPARE_SERVERS="3" \
    PHP_FPM_PM_MIN_SPARE_SERVERS="1" \
    PHP_FPM_PM_START_SERVERS="2" \
    PHP_FPM_POOL_NAME="www" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_SESSION_COOKIE_SECURE=false \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_KEEP_ENV=1 \
    S6_VERBOSITY=1 \
    SSL_MODE=off \
    SSL_CERTIFICATE_FILE=/etc/ssl/private/self-signed-web.crt \
    SSL_PRIVATE_KEY_FILE=/etc/ssl/private/self-signed-web.key

# Use second ENV layer for variable substitution
ENV NGINX_WEBROOT=${APP_BASE_DIR}/public

# copy our scripts
COPY --chmod=755 src/common/ /
COPY --chmod=755 src/s6/ /

# copy s6-overlay from s6-build
COPY --from=s6-build /opt/s6/ /

# copy php-fpm-healthcheck from s6-build
COPY --from=s6-build /usr/local/bin/php-fpm-healthcheck /usr/local/bin/php-fpm-healthcheck

# Copy NGINX setup files from the nginx-repo-config stage
COPY --from=nginx-repo-config /usr/share/keyrings/nginx-archive-keyring.gpg /usr/share/keyrings/
COPY --from=nginx-repo-config /etc/apt/sources.list.d/nginx.list /etc/apt/sources.list.d/
COPY --from=nginx-repo-config /etc/apt/preferences.d/99nginx /etc/apt/preferences.d/

# install pecl extensions, dependencies, and clean up
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
    docker-php-serversideup-pecl-install $PECL_PACKAGES && \
    docker-php-serversideup-s6-init && \
    \
    # install nginx
    docker-php-serversideup-dep-install-debian "nginx" && \
    docker-php-serversideup-dep-install-alpine "nginx" && \
    \
    # clear all php provided fpm configurations
    rm -rf /usr/local/etc/php-fpm.d/*.conf && \
    \
    # clear all nginx provided configurations
    rm -rf /etc/nginx/conf.d/*.conf && \
    rm -rf /etc/nginx/http.d/ && \
    rm /etc/nginx/nginx.conf && \
    \
    # Docker doesn't support conditional COPY, so we have to remove the apt directory if we're on Alpine
    if cat /etc/os-release | grep -qi 'Alpine'; then \
        rm -rf /usr/share/keyrings/ && \
        rm -rf /etc/apt/; \
    fi

# Copy our nginx configurations
COPY --chmod=755 src/variations/fpm-nginx/etc/ /etc/

# copy our fpm configurations
COPY --chmod=755 src/php-fpm.d/ /

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENTRYPOINT ["/init"]
# check=skip=SecretsUsedInArgOrEnv
ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.4'
ARG BASE_IMAGE="php:${PHP_VERSION}-fpm-${BASE_OS_VERSION}"

##########
# S6 Build
##########
FROM ${BASE_IMAGE} AS s6-build

ARG S6_DIR='/opt/s6/'
ARG S6_SRC_URL="https://github.com/just-containers/s6-overlay/releases/download"

# copy our scripts
COPY --chmod=755 src/common/ /
COPY --chmod=755 src/s6/ /

RUN docker-php-serversideup-s6-install

####################
# NGINX Signing Key
####################
FROM php:${PHP_VERSION}-fpm-${BASE_OS_VERSION} AS nginx-repo-config

ARG SIGNING_KEY_URL="https://nginx.org/keys/nginx_signing.key"
ARG SIGNING_FINGERPRINT="573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62"
ARG SIGNING_KEY_OUTPUT_FILE="/usr/share/keyrings/nginx-archive-keyring.gpg"
ARG SIGNING_ALPINE_RSA_PUB_SHA256="03833138bf6288dcb545f7a154af24f5c63b94931fef6b078cd8061204a44327"

# copy our scripts
COPY --chmod=755 src/common/ /

# Install NGINX signing key
RUN \
    if [ -f /etc/debian_version ]; then \
        # Install dependencies
        apt-get update && \
        apt-get install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring && \
        \
        # Create GPG home directory
        mkdir -p /root/.gnupg && \
        \
        # Import signing key
        curl "$SIGNING_KEY_URL" | gpg --dearmor | tee "$SIGNING_KEY_OUTPUT_FILE" && \
        \
        # Verify signing key
        VALID_KEY=$(gpg --dry-run --quiet --no-keyring --import --import-options import-show "$SIGNING_KEY_OUTPUT_FILE" | grep "$SIGNING_FINGERPRINT") && \
        if [ -z "$VALID_KEY" ]; then \
            echo "ERROR: Key did not match signing signature!" && \
            exit 1; \
        fi && \
        \
        # Setup apt repository for stable nginx packages
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list && \
        \
        # Setup repository pinning to prefer nginx packages over debian packages
        printf "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx && \
        \
        # Create dummy APK files so subsequent unconditional COPY does not fail on Debian
        mkdir -p /etc/apk/keys && \
        touch /etc/apk/repositories /etc/apk/keys/nginx_signing.rsa.pub; \
    elif [ -f /etc/alpine-release ]; then \
        # Install prerequisites for Alpine
        apk add --no-cache openssl curl ca-certificates && \
        \
        # Set up the APK repository for stable NGINX packages
        printf "%s%s%s%s%s\n" \
            "@nginx " \
            "http://nginx.org/packages/alpine/v" \
            "$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)" \
            "/main" \
            | tee -a /etc/apk/repositories && \
        \
        # Download the NGINX APK RSA repository key
        curl -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub && \
        \
        # Verify the key by pinning the SHA-256 of the DER-encoded public key.
        # Allow multiple hashes (comma-separated) for rotation via build args.
        CALC_SHA256=$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -outform DER 2>/dev/null | sha256sum | awk '{print $1}') && \
        printf "%s" "$SIGNING_ALPINE_RSA_PUB_SHA256" | tr ',' '\n' | grep -qx "$CALC_SHA256" || { \
            echo "ERROR: Alpine NGINX RSA key SHA-256 mismatch. Expected one of [$SIGNING_ALPINE_RSA_PUB_SHA256], got: $CALC_SHA256"; \
            exit 1; \
        } && \
        \
        # Move the key to APK's trusted keys directory
        mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/ && \
        \
        # Create dummy Debian files so subsequent unconditional COPY does not fail on Alpine
        mkdir -p /usr/share/keyrings /etc/apt/sources.list.d /etc/apt/preferences.d && \
        touch /usr/share/keyrings/nginx-archive-keyring.gpg /etc/apt/sources.list.d/nginx.list /etc/apt/preferences.d/99nginx; \
    else \
        echo "ERROR: Unsupported or undetected OS. Only Debian-based and Alpine-based systems are handled." && \
        exit 1; \
    fi

##########
# FPM-NGINX: Main Image
##########
FROM ${BASE_IMAGE}
ARG DEPENDENCY_PACKAGES_ALPINE='fcgi gettext shadow'
ARG DEPENDENCY_PACKAGES_DEBIAN='libfcgi-bin gettext-base procps zip'
ARG DEPENDENCY_PHP_EXTENSIONS='opcache pcntl pdo_mysql pdo_pgsql redis zip'
ARG REPOSITORY_BUILD_VERSION='dev'
ARG NGINX_VERSION='1.28.0-1'

LABEL org.opencontainers.image.title="serversideup/php (fpm-nginx)" \
    org.opencontainers.image.description="Supercharge your PHP experience. Based off the official PHP images, serversideup/php includes pre-configured PHP extensions and settings for enhanced performance and security. Optimized for Laravel and WordPress." \
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
    HEALTHCHECK_PATH="/healthcheck" \
    NGINX_ACCESS_LOG="/dev/stdout" \
    NGINX_ERROR_LOG="/dev/stderr" \
    NGINX_FASTCGI_BUFFERS="8 8k" \
    NGINX_FASTCGI_BUFFER_SIZE="8k" \
    NGINX_LISTEN_IP_PROTOCOL="all" \
    NGINX_SERVER_TOKENS=off \
    NGINX_WEBROOT=/var/www/html/public \
    NGINX_CLIENT_MAX_BODY_SIZE="100M" \
    PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_DISPLAY_STARTUP_ERRORS=Off \
    PHP_ERROR_LOG="/dev/stderr" \
    PHP_ERROR_REPORTING="22527" \
    PHP_FPM_PM_CONTROL=dynamic \
    PHP_FPM_PM_MAX_CHILDREN="20" \
    PHP_FPM_PM_MAX_REQUESTS="0" \
    PHP_FPM_PM_MAX_SPARE_SERVERS="3" \
    PHP_FPM_PM_MIN_SPARE_SERVERS="1" \
    PHP_FPM_PM_START_SERVERS="2" \
    PHP_FPM_PM_STATUS_PATH="/status" \
    PHP_FPM_POOL_NAME="www" \
    PHP_FPM_PROCESS_CONTROL_TIMEOUT="10s" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_MAX_INPUT_TIME="-1" \
    PHP_MAX_INPUT_VARS="1000" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_OPCACHE_ENABLE="0" \
    PHP_OPCACHE_ENABLE_FILE_OVERRIDE="0" \
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
    PHP_REALPATH_CACHE_TTL="120" \
    PHP_SESSION_COOKIE_SECURE=false \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    PHP_ZEND_DETECT_UNICODE="" \
    PHP_ZEND_MULTIBYTE="Off" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_KEEP_ENV=1 \
    S6_VERBOSITY=1 \
    SHOW_WELCOME_MESSAGE=true \
    SSL_MODE=off \
    SSL_CERTIFICATE_FILE=/etc/ssl/private/self-signed-web.crt \
    SSL_PRIVATE_KEY_FILE=/etc/ssl/private/self-signed-web.key \
    SSL_SUBJECT_COUNTRY="US" \
    SSL_SUBJECT_STATE="Wisconsin" \
    SSL_SUBJECT_LOCALITY="Milwaukee" \
    SSL_SUBJECT_ORG="IT" \
    SSL_SUBJECT_CN="*.dev.test,*.gitpod.io,*.ngrok.io,*.nip.io" \
    SSL_KEY_ALGO="rsa:2048" \
    SSL_DAYS="365"

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
COPY --from=nginx-repo-config /etc/apk/repositories /etc/apk/repositories
COPY --from=nginx-repo-config /etc/apk/keys/nginx_signing.rsa.pub /etc/apk/keys/

# install pecl extensions, dependencies, and clean up
RUN docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE} nginx@nginx=${NGINX_VERSION}" && \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN} nginx=${NGINX_VERSION}"  && \
    docker-php-serversideup-install-php-ext-installer && \
    \
    # Ensure /var/www/ has the correct permissions
    chown -R www-data:www-data /var/www && \
    chmod -R 755 /var/www && \
    \
    # Set the image version
    echo "${REPOSITORY_BUILD_VERSION}" > /etc/serversideup-php-version && \
    \
    # Make composer cache directory
    mkdir -p "${COMPOSER_HOME}" && \
    chown -R www-data:www-data "${COMPOSER_HOME}" && \
    \
    # Ensure /var/cache/nginx/ exists
    mkdir -p /var/cache/nginx/ && \
    chown -R www-data:www-data /var/cache/nginx/ && \
    \
    # Install default PHP extensions
    install-php-extensions "${DEPENDENCY_PHP_EXTENSIONS}" && \
    \
    # clear all php provided fpm configurations
    rm -rf /usr/local/etc/php-fpm.d/*.conf && \
    \
    # clear all nginx provided configurations
    rm -rf /etc/nginx/conf.d/*.conf && \
    rm -rf /etc/nginx/http.d/ && \
    rm /etc/nginx/nginx.conf && \
    \
    # Docker doesn't support conditional COPY, so remove OS-specific repo/key artifacts that were copied unconditionally
    if cat /etc/os-release | grep -qi 'Alpine'; then \
        # On Alpine, remove Debian APT artifacts
        rm -rf /usr/share/keyrings/ && \
        rm -rf /etc/apt/; \
    else \
        # On Debian, remove Alpine APK artifacts
        rm -rf /etc/apk/; \
    fi

# Copy our nginx configurations
COPY --chmod=755 src/variations/fpm-nginx/etc/ /etc/

# copy our fpm configurations
COPY --chmod=755 src/php-fpm.d/ /

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN docker-php-serversideup-set-file-permissions --owner www-data:www-data --service nginx

# Fix S6 Overlay issues with Big Cloud PaaS (https://github.com/serversideup/docker-php/pull/376#issuecomment-2179262427)
RUN chown -R www-data:www-data /run

USER www-data

EXPOSE 8080 8443

ENTRYPOINT ["docker-php-serversideup-entrypoint"]

# Set stop signal to SIGQUIT for a graceful shutdown instead of S6's preferred SIGTERM (https://github.com/just-containers/s6-overlay/issues/586)
STOPSIGNAL SIGQUIT

WORKDIR ${APP_BASE_DIR}

CMD ["/init"]

HEALTHCHECK --start-period=60s --start-interval=3s --interval=10s --timeout=3s --retries=3 \
    CMD [ "sh", "-c", "curl --insecure --silent --location --show-error --fail http://localhost:8080$HEALTHCHECK_PATH || exit 1" ]

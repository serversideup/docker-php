ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.2'
ARG PHP_VARIATION='fpm-nginx'
ARG DEPENDENCY_PACKAGES
ARG PECL_PACKAGES
ARG BASE_IMAGE="php:${PHP_VERSION}-fpm-${BASE_OS_VERSION}"

##########
# Build
##########
FROM ${BASE_IMAGE} as build

ARG S6_DIR='/opt/s6/'
ARG S6_SRC_DEP="wget"
ARG S6_SRC_URL="https://github.com/just-containers/s6-overlay/releases/download"

# copy our scripts
COPY --chmod=755 src/common/ /
COPY --chmod=755 src/s6/ /

RUN docker-php-pro-s6-install

##########
# Main
##########
FROM ${BASE_IMAGE}

LABEL maintainer="Jay Rogers (@jaydrogers)"
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    LOG_LEVEL=info \
    S6_KEEP_ENV=1

# copy our scripts
COPY --chmod=755 src/common/ /
COPY --chmod=755 src/s6/ /

# copy s6-overlay from build
COPY --from=build /opt/s6/ /

# install pecl extensions & dependencies
RUN docker-php-pro-dep-install $DEPENDENCY_PACKAGES \
    docker-php-pro-pecl-install $PECL_PACKAGES \
    docker-php-pro-s6-init

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENTRYPOINT ["/init"]
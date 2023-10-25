ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.2'
ARG PHP_VARIATION='fpm'
ARG DEPENDENCY_PACKAGES_ALPINE
ARG DEPENDENCY_PACKAGES_BOOKWORM
ARG PECL_PACKAGES

FROM php:${PHP_VERSION}-${PHP_VARIATION}-${BASE_OS_VERSION}
LABEL maintainer="Jay Rogers (@jaydrogers)"

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    LOG_LEVEL=warn

# copy our scripts
COPY --chmod=755 src/common/ /

# install pecl extensions & dependencies
RUN docker-php-serversideup-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-serversideup-dep-install-debian "${DEPENDENCY_PACKAGES_BOOKWORM}"  && \
    docker-php-serversideup-pecl-install $PECL_PACKAGES

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENTRYPOINT ["docker-php-serversideup-entrypoint"]
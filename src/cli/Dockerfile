ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.2'
ARG BASE_IMAGE="php:${PHP_VERSION}-cli-${BASE_OS_VERSION}"

FROM ${BASE_IMAGE}
LABEL maintainer="Jay Rogers (@jaydrogers)"

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    LOG_LEVEL=info

# install composer from Composer's official Docker image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY --chmod=755 usr/local/bin/ /usr/local/bin/
COPY --chmod=755 etc/entrypoint.d/ /etc/entrypoint.d/

ENTRYPOINT ["docker-php-pro-entrypoint"]
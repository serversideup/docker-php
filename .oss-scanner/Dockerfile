# Build image for Anthropic's OSS Scanner (https://github.com/anthropics/oss-scanner).
# The scanner builds this with the repository as the context, then audits it offline as root.
# Each web server variation starts from its published image with this checkout's src/ copied
# over it, so the scan runs HEAD's scripts and configs. The overlay stages repeat the COPY
# lines in src/variations/*/Dockerfile: keep them in step when those change.
# The intermediate stages are copied as whole filesystems and never run, so they stay root.
# hadolint global ignore=DL3002,DL3067
ARG PHP_VERSION='8.5'

##########
# Laravel app, so AUTORUN automations can run without network access
##########
FROM serversideup/php:${PHP_VERSION}-cli AS laravel
RUN composer create-project --no-interaction --prefer-dist laravel/laravel /var/www/html

##########
# This checkout's files, laid out the way each variation's Dockerfile copies them
##########
FROM scratch AS overlay-fpm-nginx
COPY src/common/ /
COPY src/s6/ /
COPY src/utilities-webservers/ /
COPY src/variations/fpm-nginx/etc/ /etc/
COPY src/php-fpm.d/ /

FROM scratch AS overlay-fpm-apache
COPY src/common/ /
COPY src/s6/ /
COPY src/utilities-webservers/ /
COPY src/variations/fpm-apache/etc/ /etc/
COPY src/php-fpm.d/ /

FROM scratch AS overlay-frankenphp
COPY src/common/ /
COPY src/utilities-webservers/ /
COPY src/variations/frankenphp/etc/frankenphp/ /etc/frankenphp/

##########
# One runnable root filesystem per variation. /etc/oss-scanner.env keeps each image's
# ENV defaults, which .oss-scanner/run-variation loads.
##########
FROM serversideup/php:${PHP_VERSION}-fpm-apache AS fpm-apache
USER root
COPY --chmod=755 --from=overlay-fpm-apache / /
COPY --from=laravel /var/www/html /var/www/html
RUN docker-php-serversideup-set-file-permissions --owner www-data:www-data --service apache && \
    export -p | grep -Ev '^export (HOME|HOSTNAME|PWD|SHLVL)=' > /etc/oss-scanner.env

FROM serversideup/php:${PHP_VERSION}-frankenphp AS frankenphp
USER root
COPY --chmod=755 --from=overlay-frankenphp / /
COPY --from=laravel /var/www/html /var/www/html
RUN docker-php-serversideup-set-file-permissions --owner www-data:www-data --service frankenphp && \
    export -p | grep -Ev '^export (HOME|HOSTNAME|PWD|SHLVL)=' > /etc/oss-scanner.env

FROM serversideup/php:${PHP_VERSION}-fpm-nginx-alpine AS fpm-nginx-alpine
USER root
COPY --chmod=755 --from=overlay-fpm-nginx / /
COPY --from=laravel /var/www/html /var/www/html
RUN docker-php-serversideup-set-file-permissions --owner www-data:www-data --service nginx && \
    export -p | grep -Ev '^export (HOME|HOSTNAME|PWD|SHLVL)=' > /etc/oss-scanner.env

FROM serversideup/php:${PHP_VERSION}-fpm-nginx AS fpm-nginx
USER root
COPY --chmod=755 --from=overlay-fpm-nginx / /
COPY --from=laravel /var/www/html /var/www/html
RUN docker-php-serversideup-set-file-permissions --owner www-data:www-data --service nginx && \
    export -p | grep -Ev '^export (HOME|HOSTNAME|PWD|SHLVL)=' > /etc/oss-scanner.env

##########
# Scan image: fpm-nginx at /, the other variations under /variations, the checkout at /src
##########
FROM fpm-nginx
COPY --from=fpm-apache / /variations/fpm-apache/
COPY --from=frankenphp / /variations/frankenphp/
COPY --from=fpm-nginx-alpine / /variations/fpm-nginx-alpine/
RUN ln -s / /variations/fpm-nginx && \
    docker-php-serversideup-dep-install-debian jq shellcheck

COPY . /src
WORKDIR /src

# A failing test should not stop the scan, so it only warns.
RUN bash scripts/tests/run.sh || echo "WARNING: scripts/tests/run.sh reported failures"

USER www-data
ENTRYPOINT []
CMD ["bash"]
HEALTHCHECK NONE

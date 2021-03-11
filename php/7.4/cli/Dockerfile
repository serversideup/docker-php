####################################################
# Server Side Up -  PHP 7.4 / CLI image 
#####################################################

FROM ubuntu:20.04

LABEL maintainer="Jay Rogers <jay@serversideup.net>"

# Make sure we keep apt silent during installs
ENV DEBIAN_FRONTEND=noninteractive

# Install Ondrej repos for Ubuntu focal, PHP7.4, composer and selected extensions
RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg \
    && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main" > /etc/apt/sources.list.d/ondrej-php.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        ca-certificates \
        curl \
        unzip \
        php7.4-cli \
        php7.4-common \
        php7.4-curl \
        php7.4-gd \
        php7.4-json \
        php7.4-mbstring \
        php7.4-mysql \
        php7.4-soap \
        php7.4-sqlite3 \
        php7.4-xml \
        php7.4-zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Pull the official composer 2 image, and copy the composer executable from there
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Run PHP
CMD ["php", "-a"]
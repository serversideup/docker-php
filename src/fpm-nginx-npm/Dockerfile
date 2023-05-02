ARG UPSTREAM_CHANNEL=''
ARG PHP_VERSION='8.1'
ARG BASE_IMAGE="ramageek/bcrud:${UPSTREAM_CHANNEL}${PHP_VERSION}-fpm-nginx"

FROM ${BASE_IMAGE}

# install `nvm` (node version manager)
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 18.16.0
RUN mkdir /usr/local/nvm \
    && curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/init"]

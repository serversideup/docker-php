ARG UPSTREAM_CHANNEL=''
ARG PHP_VERSION='8.1'
ARG BASE_IMAGE="serversideup/php:${UPSTREAM_CHANNEL}${PHP_VERSION}-fpm"

FROM ${BASE_IMAGE}

LABEL maintainer="Jay Rogers (@jaydrogers)"

ENV MSMTP_RELAY_SERVER_HOSTNAME="mailhog" \
    MSMTP_RELAY_SERVER_PORT="1025" \
    PHP_POOL_NAME="www" \
    PHP_PM_CONTROL=ondemand \
    PHP_PM_MAX_CHILDREN="20" \
    PHP_PM_START_SERVERS="2" \
    PHP_PM_MIN_SPARE_SERVERS="1" \
    PHP_PM_MAX_SPARE_SERVERS="3"\
    APACHE_START_SERVERS="2" \
    APACHE_MIN_SPARE_THREADS="10" \
    APACHE_MAX_SPARE_THREADS="75" \
    APACHE_THREAD_LIMIT="64" \
    APACHE_THREADS_PER_CHILD="25" \
    APACHE_MAX_REQUEST_WORKERS="150" \
    APACHE_MAX_CONNECTIONS_PER_CHILD="0" \
    APACHE_RUN_USER="webuser" \
    APACHE_RUN_GROUP="webgroup" \
    APACHE_DOCUMENT_ROOT="/var/www/html/public/" \
    DEBIAN_FRONTEND=noninteractive \
    SSL_MODE="full"

# install`apach2` (web server) & `msmtp` (smtp client)
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        msmtp \
        msmtp-mta \
        apache2 \
    \
    # enable Apache2 mods
    && a2enmod actions autoindex deflate headers http2 proxy proxy_fcgi remoteip rewrite setenvif ssl unique_id \
    \
    # cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/www/html/* \
    \
    # redirect logs to STDOUT and STERR
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log \
    \
    # set hostname
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    \
    # set log format for CloudFlare and enable Remote IP
    && sed -i 's/LogFormat "%h %l %u %t \\\"%r\\\" %>s %O \\\"/LogFormat "%a %l %u %t \\\"%r\\\" %>s %O \\\"/' /etc/apache2/apache2.conf \
    && ln -sf /etc/apache2/conf-available/remoteip.conf /etc/apache2/conf-enabled/remoteip.conf \
    \
    # force Docker ENVs to handle the apache variables for the run user and group
    && echo "export APACHE_RUN_USER=${APACHE_RUN_USER}" >> /etc/apache2/envvars \
    && echo "export APACHE_RUN_GROUP=${APACHE_RUN_GROUP}" >> /etc/apache2/envvars \
    \
    # configure permissions on the webroot
    && chown -R webuser:webgroup $WEBUSER_HOME \
    \
    # ensure Apache does not start automatically and disable the default site
    && service apache2 stop \
    && update-rc.d apache2 disable \
    && a2dissite 000-default.conf \
    && rm -rf /etc/apache2/sites-available/*

COPY etc/apache2/ /etc/apache2/

COPY --chmod=755 etc/s6-overlay/ /etc/s6-overlay/

COPY etc/php/fpm/pool.d/ /etc/php/current_version/fpm/pool.d/

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/init"]
####################################################
# Server Side Up -  PHP 7.3 / FPM-Apache image 
#####################################################

FROM serversideup/php:7.3-fpm

LABEL maintainer="Jay Rogers <jay@serversideup.net>"

# 🚨 IMPORTANT: Change the SSMTP relay server if you want emails to work
#  For example, you can override this with the "docker run" command:
#  `docker run -e SSMTP_RELAY_SERVER=smtp serversideup/php7.3-fpm`
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
    APACHE_RUN_USER="www-data" \
    APACHE_RUN_GROUP="www-data" \
    APACHE_DOCUMENT_ROOT="/var/www/html/public" \
    DEBIAN_FRONTEND=noninteractive
    

# Install Apache (web), MSMTP (email client), and Supervisor (process management)
RUN apt-get update \
    && echo "Install requirements..." \
    && apt-get -y --no-install-recommends install \
        msmtp \
        msmtp-mta \
        apache2 \
        supervisor \
    && echo "Enabling Apache mods..." \
    && a2enmod actions autoindex deflate headers http2 proxy proxy_fcgi remoteip rewrite setenvif ssl unique_id \
    && echo "Generate self-signed certs for Apache..." \
    && mkdir -p /etc/apache2/ssl \
    && openssl req -x509 -subj "/C=US/ST=Wisconsin/L=Milwaukee/O=IT/CN=default.test" -nodes -newkey rsa:2048 -keyout /etc/apache2/ssl/self-signed.key -out /etc/apache2/ssl/self-signed.crt -days 365 \
    && echo "Clean up after ourselves..." \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/www/html/* \
    && echo "Set apache logs to redirect to STDOUT and STDERR and configure Apache..." \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && echo "Set log format for CloudFlare and enable Remote IP..." \
    && sed -i 's/LogFormat "%h %l %u %t \\\"%r\\\" %>s %O \\\"/LogFormat "%a %l %u %t \\\"%r\\\" %>s %O \\\"/' /etc/apache2/apache2.conf \
    && ln -sf /etc/apache2/conf-available/remoteip.conf /etc/apache2/conf-enabled/remoteip.conf \
    && echo "Force Docker ENVs to handle the apache variables for the run user and group..." \
    && sed -i '/export APACHE_RUN_USER/ s/^#*/#/' /etc/apache2/envvars \
    && sed -i '/export APACHE_RUN_GROUP/ s/^#*/#/' /etc/apache2/envvars \
    && echo "Making sure Apache is stopped and disabled at start up..." \
    && service apache2 stop \
    && update-rc.d apache2 disable

#APACHE: Copy over configurations
COPY etc/apache2/conf-available/* /etc/apache2/conf-available/
COPY etc/apache2/mods-available/* /etc/apache2/mods-available/
COPY etc/apache2/sites-available/* /etc/apache2/sites-available/

#PHP: Copy over configuration to listen on the socket
COPY etc/php/7.x/fpm/pool.d/z-fpm-with-overrides.conf etc/php/7.3/fpm/pool.d/z-fpm-with-overrides.conf

#SUPERVISOR: Copy over supervisor configurations
COPY etc/supervisor/conf.d/* /etc/supervisor/conf.d/

EXPOSE 80
EXPOSE 443

ADD start-container /usr/bin/start-container
RUN chmod +x /usr/bin/start-container

ENTRYPOINT ["start-container"]
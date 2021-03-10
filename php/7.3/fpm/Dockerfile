####################################################
# Server Side Up -  PHP 7.3 / FPM image 
#####################################################

FROM serversideup/php7.3-cli

LABEL maintainer="Jay Rogers <jay@serversideup.net>"

# Set default PHP environment variables

ENV PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=On \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    SSMTP_RELAY_SERVER="mailhog:1025"
    # 🚨 IMPORTANT: Change the SSMTP relay server if you want emails to work
    #  For example, you can override this with the "docker run" command:
    #  `docker run -e SSMTP_RELAY_SERVER=smtp serversideup/php7.3-fpm`

# Install FPM for PHP & SSMTP client for sending emails
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        php7.3-fpm \
        ssmtp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Make sure the container comes down clean
STOPSIGNAL SIGQUIT

# Apply configuration file
COPY php-overrides.conf /etc/php/7.3/fpm/pool.d/z-overrides.conf

CMD ["/usr/sbin/php-fpm7.3", "-O" ]

# Open up fcgi port
EXPOSE 9000
#!/bin/sh
if [ "$SHOW_WELCOME_MESSAGE" = "false" ] || [ "$LOG_OUTPUT_LEVEL" = "off" ] || [ "$DISABLE_DEFAULT_CONFIG" = "true" ]; then
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $0: Container info was display was skipped."
    fi
    # Skip the rest of the script
    return 0
fi

echo '
--------------------------------------------------------------------
 ____                             ____  _     _        _   _
/ ___|  ___ _ ____   _____ _ __  / ___|(_) __| | ___  | | | |_ __
\___ \ / _ \  __\ \ / / _ \  __| \___ \| |/ _` |/ _ \ | | | |  _ \
 ___) |  __/ |   \ V /  __/ |     ___) | | (_| |  __/ | |_| | |_) |
|____/ \___|_|    \_/ \___|_|    |____/|_|\__,_|\___|  \___/| .__/
                                                            |_|

Brought to you by serversideup.net
--------------------------------------------------------------------'

PHP_OPCACHE_STATUS=$(php -r 'echo ini_get("opcache.enable");')

if [ "$PHP_OPCACHE_STATUS" = "1" ]; then
    PHP_OPCACHE_MESSAGE="✅ Enabled"
else
    PHP_OPCACHE_MESSAGE="❌ Disabled"
fi

echo '
🙌 To support Server Side Up projects visit:
https://serversideup.net/sponsor

-------------------------------------
ℹ️ Container Information
-------------------------------------'
echo "
OS:            $(. /etc/os-release; echo "${PRETTY_NAME}")
Docker user:   $(whoami)
Docker uid:    $(id -u)
Docker gid:    $(id -g)
OPcache:       $PHP_OPCACHE_MESSAGE
PHP Version:   $(php -r 'echo phpversion();')
Image Version: $(cat /etc/serversideup-php-version)
"

if [ "$PHP_OPCACHE_STATUS" = "0" ]; then
    echo "👉 [NOTICE]: Improve PHP performance by setting PHP_OPCACHE_ENABLE=1 (recommended for production)."
fi
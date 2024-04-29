#!/bin/sh
if [ "$LOG_OUTPUT_LEVEL" != "off" ] && [ "$DISABLE_DEFAULT_CONFIG" = false ]; then
echo "This is a test change"
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
Docker user:   $(whoami)
Docker uid:    $(id -u "$(whoami)")
Docker gid:    $(id -g "$(whoami)")
OPcache:       $PHP_OPCACHE_MESSAGE
"

if [ "$PHP_OPCACHE_STATUS" = "0" ]; then
    echo "👉 [NOTICE]: Improve PHP performance by setting PHP_OPCACHE_ENABLE=1 (recommended for production)."
fi

else
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal \"false\", so debug mode will NOT be automatically set."
    fi
fi
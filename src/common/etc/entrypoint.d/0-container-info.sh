#!/bin/sh
if [ "$LOG_OUTPUT_LEVEL" != "off" ] && [ "$DISABLE_DEFAULT_CONFIG" = false ]; then
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
"
else
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ]; then
        echo "👉 $script_name: DISABLE_DEFAULT_CONFIG does not equal \"false\", so debug mode will NOT be automatically set."
    fi
fi
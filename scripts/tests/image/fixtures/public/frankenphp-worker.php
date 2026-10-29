<?php
$handler = static function () {
    echo "octane-worker-ok:" . PHP_VERSION;
};
while (frankenphp_handle_request($handler)) {
}

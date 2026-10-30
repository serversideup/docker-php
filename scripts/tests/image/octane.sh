# shellcheck shell=bash
# Laravel Octane starts FrankenPHP with LARAVEL_OCTANE=1 and the variables from
# src/Commands/StartFrankenPhpCommand.php in laravel/octane, which must switch
# /etc/frankenphp/Caddyfile to the Octane worker without losing the rest of the configuration.
requires healthcheck web_server frankenphp

# A custom CADDY_SERVER_ROOT must move the worker script along with the document root.
octane_root=/var/www/octane/public

setup() {
    start_container \
        --env LARAVEL_OCTANE=1 \
        --env "CADDY_SERVER_ROOT=$octane_root" \
        --volume "$web_dir:$octane_root:ro" \
        --env CADDY_SERVER_ADMIN_HOST=localhost \
        --env CADDY_SERVER_ADMIN_PORT=2099 \
        --env "CADDY_SERVER_WORKER_DIRECTIVE=num 2" \
        --env "CADDY_SERVER_WATCH_DIRECTIVES=watch $octane_root" \
        --env "CADDY_GLOBAL_OPTIONS=auto_https disable_redirects" \
        --env CADDY_SERVER_EXTRA_DIRECTIVES=
}

test_routes_requests_to_frankenphp_worker() {
    expect_body / "octane-worker-ok:${php_version}"
    expect_body /some/route "octane-worker-ok:${php_version}"
}

test_blocks_php_under_storage() {
    expect_storage_blocked
}

# octane:status, octane:reload, and octane:stop use the Caddy admin API on Octane's port.
test_exposes_the_caddy_admin_api_on_octanes_port() {
    local response
    response=$(docker exec "$container" curl --silent --max-time 5 --output /dev/null --write-out '%{http_code}' http://localhost:2099/config/apps/frankenphp || true)
    [ "$response" = "200" ] || fail "Caddy admin API is not reachable on Octane's admin port, got ${response:-<empty>}"
}

test_writes_json_logs_to_stderr_and_redacts_authorization() {
    expect_authorization_redacted
    expect_json_logs_on_stderr
}

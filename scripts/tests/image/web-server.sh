# shellcheck shell=bash
# NGINX, Apache, or Caddy serving the mounted fixtures in fixtures/public.
requires healthcheck web_server

setup() {
    start_container
}

test_serves_php() {
    expect_body / "serversideup-php-ok:${php_version}"
}

test_blocks_php_under_storage() {
    expect_storage_blocked
}

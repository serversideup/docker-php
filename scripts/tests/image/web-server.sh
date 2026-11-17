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

# A request ending in /x.php must not make PHP-FPM fall back to the uploaded file before it
# through cgi.fix_pathinfo.
test_never_runs_uploaded_phar_through_path_info() {
    local body
    body=$(curl --silent --max-time 5 "http://127.0.0.1:${host_port}/uploads/uploaded.phar/x.php" || true)
    case "$body" in
        *"uploaded-phar-executed"*) fail "/uploads/uploaded.phar/x.php ran the uploaded .phar" ;;
    esac
}

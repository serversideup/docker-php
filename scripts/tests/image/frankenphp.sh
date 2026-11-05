# shellcheck shell=bash
# Caddy's log defaults in the FrankenPHP image, which Laravel Octane depends on.
requires healthcheck web_server frankenphp

setup() {
    start_container
}

test_writes_json_logs_to_stderr_and_redacts_authorization() {
    expect_authorization_redacted
    expect_json_logs_on_stderr
}

# mixed and full import a snippet named after CADDY_AUTO_HTTPS, so a value without
# one stops FrankenPHP at start-up without logging an error.
test_starts_with_every_caddy_auto_https_value() {
    start_container --env SSL_MODE=full --env CADDY_AUTO_HTTPS=disable_redirects

    # Without automatic certificates, Caddy serves SSL_CERTIFICATE_FILE
    local value
    for value in disable_certs ignore_loaded_certs; do
        start_container --env SSL_MODE=full --env "CADDY_AUTO_HTTPS=$value"
        expect_body --https / "serversideup-php-ok:${php_version}"
    done
}

# Caddy reads MIME types from /etc/mime.types (mailcap). Without it, Go's small built-in
# table has no entry for fonts, so browsers get a sniffed type and may refuse to load them.
test_serves_static_files_with_their_mime_type() {
    local content_type
    content_type=$(curl --silent --max-time 5 --output /dev/null --write-out '%{content_type}' "http://127.0.0.1:${host_port}/font.woff2" || true)
    [ "$content_type" = "font/woff2" ] || fail "Expected /font.woff2 to be served as font/woff2, got ${content_type:-<empty>}"
}

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

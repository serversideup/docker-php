# shellcheck shell=bash
# SSL_MODE=full generates a self-signed certificate and stops serving the plain HTTP port.
# It is also the only way to reach the web server over HTTP/2.
requires healthcheck web_server https

setup() {
    start_container --env SSL_MODE=full
}

# Symfony's Response::send() calls fastcgi_finish_request() and Laravel keeps running
# terminate callbacks after it, so the web server has to survive a request that finishes
# before PHP does. Caddy 2.11.6 segfaulted the whole FrankenPHP process here, but only
# over HTTP/2, so both protocol versions are worth checking.
test_survives_requests_that_finish_before_php_over_http1_and_http2() {
    local protocol body status
    for protocol in --http1.1 --http2; do
        body=""
        for _ in $(seq 1 "$http_timeout_seconds"); do
            body=$(curl --silent --insecure "$protocol" --max-time 5 "https://127.0.0.1:${https_host_port}/finish-request.php" 2>/dev/null || true)
            [ "$body" = "finish-request-ok:${php_version}" ] && break
            sleep 1
        done
        if [ "$body" != "finish-request-ok:${php_version}" ]; then
            dump_container_state "$container"
            fail "Web server did not serve /finish-request.php over ${protocol#--}. Response: ${body:-<empty>}"
        fi

        # The crash lands after the response, so give the process a moment to fall over.
        sleep 2
        status=$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null || echo gone)
        if [ "$status" != "running" ]; then
            dump_container_state "$container"
            fail "Web server stopped after a ${protocol#--} request finished before PHP did (status: $status)"
        fi
    done
}

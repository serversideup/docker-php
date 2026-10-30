# shellcheck shell=bash
# TRUSTED_PROXY decides when the web server replaces REMOTE_ADDR with a forwarded client
# address. The test requests come through Docker's private network, which every mode
# except off trusts as a proxy, and fixtures/public/ip.php prints REMOTE_ADDR.
requires healthcheck web_server

client_address=203.0.113.9

# Usage: remote_addr [curl options]
remote_addr() {
    curl --silent --max-time 5 "$@" "http://127.0.0.1:${host_port}/ip.php" || true
}

test_uses_cf_connecting_ip_by_default() {
    local address
    start_container
    address=$(remote_addr --header "CF-Connecting-IP: $client_address")
    [ "$address" = "$client_address" ] || fail "REMOTE_ADDR is ${address:-<empty>}, expected $client_address from CF-Connecting-IP"
}

# A client can put any address at the start of X-Forwarded-For, so only the address
# the last trusted proxy saw can be believed.
test_ignores_addresses_a_client_adds_to_x_forwarded_for() {
    local address
    start_container --env TRUSTED_PROXY=local
    address=$(remote_addr --header "X-Forwarded-For: 198.51.100.1, $client_address")
    [ "$address" = "$client_address" ] || fail "REMOTE_ADDR is ${address:-<empty>}, expected $client_address"
}

test_ignores_forwarded_headers_when_off() {
    local address
    start_container --env TRUSTED_PROXY=off
    address=$(remote_addr --header "CF-Connecting-IP: $client_address" --header "X-Forwarded-For: $client_address")
    [ -n "$address" ] || fail "ip.php returned nothing"
    [ "$address" != "$client_address" ] || fail "REMOTE_ADDR came from a forwarded header with TRUSTED_PROXY=off"
}

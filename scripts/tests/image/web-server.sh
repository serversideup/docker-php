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

# Prints the Location header of a GET request, without the trailing CR.
location_header() {
    curl --silent --max-time 5 --output /dev/null --dump-header - "http://127.0.0.1:${host_port}$1" \
        | sed -n 's/^[Ll]ocation: //p' | sed 's/\r$//' || true
}

# /index.php/... redirects to the clean URL so search engines index one copy of each page.
test_redirects_index_php_paths_to_clean_urls() {
    local location
    location=$(location_header '/index.php/shop/shirt?x=1')
    case "$location" in
        /shop/shirt\?x=1|"http://127.0.0.1:${host_port}/shop/shirt?x=1") ;;
        *) fail "Expected /index.php/shop/shirt?x=1 to redirect to /shop/shirt?x=1, got ${location:-<no Location>}" ;;
    esac
}

# Browsers read a leading backslash or tab in a relative Location as "//", which is another host,
# and a control character must never reach a response header (GHSA-3634-2fr7-xpw4).
test_index_php_redirect_stays_on_this_host() {
    local path location relative
    for path in '/index.php/%5Cevil.example' '/index.php/%5C%5Cevil.example' \
        '/index.php/%09/evil.example' '/index.php/x%0DX-Test:%201'; do
        location=$(location_header "$path")
        [ -n "$location" ] || continue
        relative=${location#"http://127.0.0.1:${host_port}"}
        case "$relative" in
            *[[:cntrl:]]*) fail "${path} put a control character in its Location header" ;;
            /[!/\\[:space:]]*) ;;
            *) fail "${path} redirected off this host: ${location}" ;;
        esac
    done
}

# Clients replay a redirected POST as a GET without its body, which breaks webhooks
# registered under /index.php/..., so other methods reach PHP instead.
test_index_php_post_reaches_php() {
    local response
    response=$(curl --silent --max-time 5 --data 'payload=1' --write-out ' %{http_code}' "http://127.0.0.1:${host_port}/index.php/webhook" || true)
    [ "$response" = "serversideup-php-ok:${php_version} 200" ] || fail "POST /index.php/webhook did not reach PHP. Response: ${response:-<empty>}"
}

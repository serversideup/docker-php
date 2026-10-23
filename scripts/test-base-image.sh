#!/bin/bash
set -eo pipefail

###################################################
# Usage: test-base-image.sh <image> <cli|fpm|zts> [official-image]
###################################################
# Tests a serversideup/php-base image (see generate-php-base.sh). The first checks are
# docker-library's own tests for the official image (php-hello-world, php-ext-install,
# php-argon2, php-fpm-hello-web from https://github.com/docker-library/official-images/tree/326d6f326e8ed6ea7b66fcc53c6b78dd22334a2d/test/tests).
#
# Given an official image (example: php:8.4.27-fpm-trixie), it also checks that ours is a
# drop-in for it: the same image config, ENV, extensions, configure flags, and
# /usr/local/etc. When the two PHP versions differ, as on the day of a security release
# when the official image isn't out yet, values that change with the version are skipped.

image="$1"
sapi="$2"
official_image="$3"

if [ -z "$image" ] || [ -z "$sapi" ]; then
    sed -n '4,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
    exit 1
fi

failures=0
pass() { echo "✅ $1"; }
fail() {
    echo "❌ $1"
    [ -z "$2" ] || echo "$2" | sed 's/^/   /'
    failures=$((failures + 1))
}
check() {
    local message="$1"
    shift
    local output
    if output=$("$@" 2>&1); then pass "$message"; else fail "$message" "$output"; fi
}
run_php() {
    docker run --rm -i "$1" php -d display_errors=stderr
}

echo "🧪 Testing $image ($sapi)"

if [ "$(echo "<?php echo 'Hello World!' . \"\\n\";" | run_php "$image")" = "Hello World!" ]; then
    pass "php-hello-world"
else
    fail "php-hello-world"
fi

check "php-ext-install" docker run --rm "$image" sh -ec '
    docker-php-ext-install pdo_mysql
    php -d display_errors=stderr -r "exit(extension_loaded(\"pdo_mysql\") ? 0 : 1);"
    grep -q "^extension=" /usr/local/etc/php/conf.d/*pdo_mysql*.ini'

check "php-argon2" run_php "$image" <<'EOF'
<?php
if (!defined('PASSWORD_ARGON2I')) {
	echo "FAIL: Constant PASSWORD_ARGON2I is not defined.\n";
	exit(1);
}
if (!password_verify('password', '$argon2i$v=19$m=8,t=1,p=1$RWxaRlZ0d1FTa3RSY1c1OQ$c7a/rJlPgvH9ItPi74UGuh0tdCBhpdDF7b/nA3QweX8')) {
	echo "FAIL: Failed to check test vector.\n";
	exit(1);
}
EOF

if [ "$sapi" = "fpm" ]; then
    client_image="serversideup/php-base-test:fcgi-client"
    docker build -q -t "$client_image" - > /dev/null <<'EOF'
FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends libfcgi-bin && apt-get dist-clean
ENTRYPOINT ["cgi-fcgi"]
EOF
    cid=$(docker run -d "$image")
    trap 'docker rm -vf "$cid" > /dev/null' EXIT
    docker exec "$cid" sh -c "echo '<?php echo isset(\$_REQUEST[\"hello\"]) ? \$_REQUEST[\"hello\"] : \"Hello!\";' > /var/www/html/index.php"
    fcgi_request() {
        docker run --rm --network "container:$cid" \
            -e REQUEST_METHOD=GET -e SCRIPT_NAME=/index.php -e SCRIPT_FILENAME=/var/www/html/index.php -e QUERY_STRING="$1" \
            "$client_image" -bind -connect 127.0.0.1:9000
    }
    for _ in $(seq 30); do fcgi_request "" > /dev/null 2>&1 && break; sleep 1; done
    hello="world-$RANDOM-$RANDOM"
    if [ "$(fcgi_request "hello=$hello" 2>&1 | tail -n1)" = "$hello" ]; then
        pass "php-fpm-hello-web"
    else
        fail "php-fpm-hello-web" "$(docker logs "$cid" 2>&1 | tail -n5)"
    fi
fi

if [ "$(docker run --rm "$image" php -i | sed -n 's/^Build Provider => //p')" = "https://github.com/serversideup/docker-php" ]; then
    pass "php -i reports serversideup/docker-php as the build provider"
else
    fail "php -i reports serversideup/docker-php as the build provider"
fi

if [ -n "$official_image" ]; then
    echo
    echo "🔍 Comparing with $official_image"
    docker pull -q "$official_image" > /dev/null
    version=$(docker run --rm "$image" php -r 'echo PHP_VERSION;')
    official_version=$(docker run --rm "$official_image" php -r 'echo PHP_VERSION;')
    same_version=false
    if [ "$version" = "$official_version" ]; then
        same_version=true
    else
        echo "ℹ️ PHP $version vs $official_version, so values that change with the version are skipped"
    fi

    compare() {
        local message="$1" ours theirs
        ours=$("$2" "$image" 2>&1)
        theirs=$("$2" "$official_image" 2>&1)
        if [ "$ours" = "$theirs" ]; then
            pass "$message"
        else
            fail "$message" "$(diff <(echo "$theirs") <(echo "$ours") | grep '^[<>]' | sed 's/^</official:/; s/^>/ours:    /')"
        fi
    }
    image_config() { docker image inspect --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}} {{.Config.User}} {{.Config.WorkingDir}} {{.Config.StopSignal}} {{json .Config.ExposedPorts}}' "$1"; }
    env_names() { docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$1" | sed 's/=.*//' | sort; }
    env_values() { docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$1" | sort; }
    modules() { docker run --rm "$1" php -m; }
    # The build provider differs on purpose and is checked above.
    configure_flags() { docker run --rm "$1" php-config --configure-options | tr ' ' '\n' | grep -v '^PHP_BUILD_PROVIDER=' | sort; }
    etc_files() { docker run --rm "$1" sh -c 'cd /usr/local/etc && find . -type f | sort'; }
    etc_checksums() { docker run --rm "$1" sh -c 'cd /usr/local/etc && find . -type f | sort | xargs sha256sum'; }
    users() { docker run --rm "$1" id www-data; }

    compare "entrypoint, command, user, workdir, stop signal, and ports" image_config
    compare "ENV names" env_names
    compare "www-data user" users
    compare "extensions (php -m)" modules
    compare "configure flags" configure_flags
    compare "files in /usr/local/etc" etc_files
    if [ "$same_version" = true ]; then
        compare "ENV values" env_values
        compare "contents of /usr/local/etc" etc_checksums
    fi
fi

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed" >&2
    exit 1
fi
echo "All checks passed"

#!/bin/bash
###################################################
# Usage: scripts/test-base-image.sh <image> <expected-version> [official-ref]
###################################################
# Checks that a php-base image keeps the official php image contract:
#   - reports the expected PHP version and runs commands through docker-php-entrypoint
#   - sets the ENV the official image sets (PHP_INI_DIR, PHPIZE_DEPS, PHP_CFLAGS, ...)
#   - keeps /usr/src/php.tar.xz and the docker-php-* helpers, so docker-php-ext-install works
#   - installs serversideup's default extensions with install-php-extensions
#   - for FPM images, starts php-fpm and answers /ping and a PHP script over FastCGI
#
# With an official reference image (for example php:8.4.27-fpm-bookworm) it also
# requires the same image config, ENV, `php -m` module list, configure flags, files
# under /usr/local/etc, and www-data user. The reference is pulled for the same
# platform as the image. An extension install that also fails on the reference
# only warns, since that is an upstream problem rather than a difference.
#
# Every check runs even after a failure; the exit code is 1 if any check failed.

set -uo pipefail

IMAGE="${1:-}"
EXPECTED_VERSION="${2:-}"
OFFICIAL_REF="${3:-}"

if [ -z "$IMAGE" ] || [ -z "$EXPECTED_VERSION" ]; then
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 1
fi

INSTALL_PHP_EXTENSIONS_URL="https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions"
TEST_EXTENSIONS="redis zip pdo_pgsql"

failures=0
containers=()

cleanup() {
    for container in "${containers[@]+"${containers[@]}"}"; do
        docker rm -f "$container" > /dev/null 2>&1 || true
    done
}
trap cleanup EXIT

pass() {
    echo "✅ $1"
}

warn() {
    echo "⚠️  $1"
    shift
    for line in "$@"; do
        echo "   $line"
    done
}

fail() {
    echo "❌ $1"
    shift
    for line in "$@"; do
        echo "   $line"
    done
    failures=$((failures + 1))
}

section() {
    echo
    echo "── $1"
}

# Run a shell snippet in a fresh container of the given image, bypassing the entrypoint.
in_image() {
    local image="$1"
    shift
    docker run --rm --entrypoint sh "$image" -c "$*"
}

# Compare two values and report a diff when they differ.
expect_equal() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        pass "$name"
    else
        fail "$name" "expected: $expected" "actual:   $actual"
    fi
}

expect_same_lines() {
    local name="$1" expected="$2" actual="$3" diff_output
    if diff_output="$(diff <(echo "$expected") <(echo "$actual"))"; then
        pass "$name"
    else
        # shellcheck disable=SC2001
        fail "$name" "diff (< official, > php-base):" "$(echo "$diff_output" | sed 's/^/   /')"
    fi
}

if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    docker pull -q "$IMAGE" > /dev/null || { echo "❌ Cannot pull $IMAGE"; exit 1; }
fi
PLATFORM="$(docker image inspect -f '{{.Os}}/{{.Architecture}}{{if .Variant}}/{{.Variant}}{{end}}' "$IMAGE")"
echo "🧪 Testing $IMAGE ($PLATFORM), expecting PHP $EXPECTED_VERSION"

OFFICIAL_PULLED=false
if [ -n "$OFFICIAL_REF" ]; then
    if docker pull -q --platform "$PLATFORM" "$OFFICIAL_REF" > /dev/null; then
        OFFICIAL_PULLED=true
    else
        fail "pull $OFFICIAL_REF for $PLATFORM"
    fi
fi

# Run an install script as root in a fresh container. One that also fails on the
# official image is an upstream problem rather than a difference, so it only warns.
check_install() {
    local name="$1" script="$2" output
    if output="$(docker run --rm "$IMAGE" sh -c "$script" 2>&1)"; then
        pass "$name"
    elif [ "$OFFICIAL_PULLED" = true ] && ! docker run --rm "$OFFICIAL_REF" sh -c "$script" > /dev/null 2>&1; then
        warn "$name fails on $OFFICIAL_REF too, so it is not counted" "$(echo "$output" | tail -3)"
    else
        fail "$name" "$(echo "$output" | tail -30)"
    fi
}

IS_FPM=false
if in_image "$IMAGE" 'command -v php-fpm' > /dev/null; then IS_FPM=true; fi
IS_ALPINE=false
if in_image "$IMAGE" '[ -f /etc/alpine-release ]'; then IS_ALPINE=true; fi

##########
section "Version and entrypoint"
##########
expect_equal "PHP_VERSION is $EXPECTED_VERSION" "$EXPECTED_VERSION" \
    "$(docker run --rm --entrypoint php "$IMAGE" -r 'echo PHP_VERSION;')"
expect_equal "docker-php-entrypoint runs commands" "ok" \
    "$(docker run --rm "$IMAGE" php -r 'echo "ok";')"
expect_equal "docker-php-entrypoint prepends php to flags" "ok" \
    "$(docker run --rm "$IMAGE" -r 'echo "ok";')"

##########
section "ENV contract"
##########
expect_equal "PHP_INI_DIR is /usr/local/etc/php" "/usr/local/etc/php" "$(in_image "$IMAGE" 'echo "$PHP_INI_DIR"')"
for var in PHPIZE_DEPS PHP_CFLAGS PHP_CPPFLAGS PHP_LDFLAGS PHP_VERSION PHP_URL PHP_ASC_URL PHP_SHA256 GPG_KEYS; do
    value="$(in_image "$IMAGE" "printf '%s' \"\$$var\"")"
    if [ -n "$value" ]; then pass "$var is set"; else fail "$var is set" "it is empty"; fi
done

##########
section "Files and helpers"
##########
file_checks='
    check() { if eval "$2"; then echo "ok|$1"; else echo "fail|$1"; fi; }
    check "/usr/src/php.tar.xz is kept for docker-php-source" "[ -s /usr/src/php.tar.xz ] && [ -s /usr/src/php.tar.xz.asc ]"
    for helper in docker-php-source docker-php-ext-configure docker-php-ext-install docker-php-ext-enable docker-php-entrypoint; do
        check "$helper is executable" "[ -x /usr/local/bin/$helper ]"
    done
    check "php.ini-production and php.ini-development are in PHP_INI_DIR" "[ -f \"\$PHP_INI_DIR/php.ini-production\" ] && [ -f \"\$PHP_INI_DIR/php.ini-development\" ]"
    check "sodium is enabled" "php -m | grep -qx sodium"
    check "opcache is loaded" "php -m | grep -qx \"Zend OPcache\""
    check "/var/www/html is owned by www-data with mode 1777" "[ \"\$(stat -c %U:%a /var/www/html)\" = www-data:1777 ]"
    if [ -f /etc/debian_version ]; then
        check "Debian PHP packages are pinned out" "[ -f /etc/apt/preferences.d/no-debian-php ]"
    fi
'
while IFS='|' read -r status name; do
    if [ "$status" = ok ]; then pass "$name"; else fail "$name"; fi
done < <(in_image "$IMAGE" "$file_checks")

check_install "docker-php-ext-install pcntl builds and loads the extension" '
    docker-php-ext-install pcntl > /tmp/ext.log 2>&1 || { tail -20 /tmp/ext.log; exit 1; }
    php -m | grep -qx pcntl
'

check_install "install-php-extensions $TEST_EXTENSIONS" "
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 3 -o /usr/local/bin/install-php-extensions '$INSTALL_PHP_EXTENSIONS_URL' &&
    chmod +x /usr/local/bin/install-php-extensions &&
    install-php-extensions $TEST_EXTENSIONS > /tmp/install.log 2>&1 || { tail -30 /tmp/install.log; exit 1; }
    for ext in $TEST_EXTENSIONS; do php -m | grep -qx \"\$ext\" || { echo \"\$ext is not loaded\"; exit 1; }; done
"

##########
if [ "$IS_FPM" = true ]; then
section "PHP-FPM"
##########
    if docker run --rm "$IMAGE" php-fpm -t > /dev/null 2>&1; then
        pass "php-fpm -t accepts the configuration"
    else
        fail "php-fpm -t accepts the configuration" "$(docker run --rm "$IMAGE" php-fpm -t 2>&1 | tail -5)"
    fi

    work_dir="$(mktemp -d)"
    printf '[www]\nping.path = /ping\nping.response = pong\n' > "$work_dir/zzz-test.conf"
    printf '<?php echo "fpm-ok ", PHP_VERSION, " ", PHP_SAPI;\n' > "$work_dir/index.php"
    container="$(docker create "$IMAGE")"
    containers+=("$container")
    docker cp -q "$work_dir/zzz-test.conf" "$container:/usr/local/etc/php-fpm.d/zzz-test.conf"
    docker cp -q "$work_dir/index.php" "$container:/var/www/html/index.php"
    rm -rf "$work_dir"
    docker start "$container" > /dev/null

    if [ "$IS_ALPINE" = true ]; then
        fcgi_install='apk add --no-cache fcgi > /dev/null'
    else
        fcgi_install='apt-get update > /dev/null && apt-get install -y --no-install-recommends libfcgi-bin > /dev/null'
    fi
    if ! docker exec "$container" sh -c "$fcgi_install" > /dev/null 2>&1; then
        fail "install cgi-fcgi to talk to php-fpm"
    fi

    fcgi_request() {
        docker exec "$container" sh -c "SCRIPT_NAME='$1' SCRIPT_FILENAME='$2' REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000" 2>/dev/null | tr -d '\r' | sed '1,/^$/d'
    }

    ping=""
    for _ in $(seq 1 30); do
        ping="$(fcgi_request /ping /ping)"
        [ "$ping" = pong ] && break
        sleep 1
    done
    expect_equal "php-fpm answers /ping on port 9000" "pong" "$ping"
    expect_equal "php-fpm runs /var/www/html/index.php" "fpm-ok $EXPECTED_VERSION fpm-fcgi" \
        "$(fcgi_request /index.php /var/www/html/index.php)"
    if docker logs "$container" 2>&1 | grep -q 'ready to handle connections'; then
        pass "php-fpm logs to stderr"
    else
        fail "php-fpm logs to stderr" "$(docker logs "$container" 2>&1 | tail -5)"
    fi
fi

##########
if [ "$OFFICIAL_PULLED" = true ]; then
section "Parity with $OFFICIAL_REF"
##########
    config_of() {
        docker image inspect "$1" | jq -c '.[0].Config | {Entrypoint, Cmd, WorkingDir, StopSignal, ExposedPorts, User}'
    }
    expect_equal "image config (entrypoint, cmd, workdir, stop signal, ports, user)" \
        "$(config_of "$OFFICIAL_REF")" "$(config_of "$IMAGE")"

    env_names_of() {
        docker image inspect "$1" | jq -r '.[0].Config.Env[] | split("=")[0]' | sort
    }
    expect_same_lines "ENV variable names" "$(env_names_of "$OFFICIAL_REF")" "$(env_names_of "$IMAGE")"

    env_value_of() {
        docker image inspect "$1" | jq -r --arg name "$2" '.[0].Config.Env[] | select(startswith($name + "=")) | sub("^[^=]*="; "")' | tr -s ' \t' ' ' | sed 's/^ //;s/ $//'
    }
    same_version=false
    [ "$(env_value_of "$OFFICIAL_REF" PHP_VERSION)" = "$EXPECTED_VERSION" ] && same_version=true
    compare_vars="PHP_INI_DIR PHPIZE_DEPS PHP_CFLAGS PHP_CPPFLAGS PHP_LDFLAGS GPG_KEYS"
    if [ "$same_version" = true ]; then
        compare_vars="$compare_vars PHP_VERSION PHP_URL PHP_ASC_URL PHP_SHA256"
    else
        echo "ℹ️  $OFFICIAL_REF is PHP $(env_value_of "$OFFICIAL_REF" PHP_VERSION), so version-specific ENV is not compared"
    fi
    for var in $compare_vars; do
        expect_equal "ENV $var matches" "$(env_value_of "$OFFICIAL_REF" "$var")" "$(env_value_of "$IMAGE" "$var")"
    done

    modules_of() {
        docker run --rm --entrypoint php "$1" -m | grep -v '^$' | sort
    }
    expect_same_lines "php -m module list" "$(modules_of "$OFFICIAL_REF")" "$(modules_of "$IMAGE")"

    # PHP_BUILD_PROVIDER names who built the binary, so it differs on purpose.
    configure_flags_of() {
        docker run --rm --entrypoint php "$1" -i | grep '^Configure Command' | grep -oE "'[^']*'" | tr -d "'" | grep -v '^PHP_BUILD_PROVIDER=' | sort
    }
    expect_same_lines "configure flags (php -i)" "$(configure_flags_of "$OFFICIAL_REF")" "$(configure_flags_of "$IMAGE")"

    build_info_of() {
        docker run --rm --entrypoint php "$1" -i | grep -E '^(Thread Safety|Zend Extension Build|PHP Extension Build|Debug Build|Server API) =>' | sort
    }
    expect_same_lines "thread safety and extension ABI" "$(build_info_of "$OFFICIAL_REF")" "$(build_info_of "$IMAGE")"

    # pear.conf records when pecl last refreshed its channels, so it never matches.
    etc_checksums_of() {
        in_image "$1" 'cd /usr/local/etc && find . -type f ! -name pear.conf | sort | xargs md5sum'
    }
    expect_same_lines "config files under /usr/local/etc" "$(etc_checksums_of "$OFFICIAL_REF")" "$(etc_checksums_of "$IMAGE")"

    expect_equal "www-data user" "$(in_image "$OFFICIAL_REF" 'id www-data')" "$(in_image "$IMAGE" 'id www-data')"

    size_of() {
        docker image inspect -f '{{.Size}}' "$1" | awk '{ printf "%.0f MB", $1 / 1000000 }'
    }
    echo "ℹ️  Uncompressed size: official $(size_of "$OFFICIAL_REF"), php-base $(size_of "$IMAGE")"
fi

echo
if [ "$failures" -eq 0 ]; then
    echo "✅ All checks passed for $IMAGE"
else
    echo "❌ $failures check(s) failed for $IMAGE"
    exit 1
fi

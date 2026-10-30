# shellcheck shell=bash
# PHP itself: the version, the default extensions, and php.ini settings from environment variables.

test_reports_the_expected_php_version() {
    local expected="$expected_php"
    [ -n "$expected" ] || return 0
    # A release candidate tag like 8.6-rc reports a version like 8.6.0RC4
    if [[ "$expected" == *-rc ]] && [[ "$php_version" == "${expected%-rc}".*RC* ]]; then
        expected="$php_version"
    fi
    [ "$php_version" = "$expected" ] || fail "PHP reports $php_version, expected $expected"
}

test_loads_the_default_extensions() {
    # Every variation installs these (DEPENDENCY_PHP_EXTENSIONS in src/variations/*/Dockerfile).
    local expected="opcache pcntl pdo_mysql pdo_pgsql redis zip" loaded missing="" extension
    loaded=$(run_php 'echo implode(" ", array_map("strtolower", get_loaded_extensions()));')
    for extension in $expected; do
        case " $loaded " in
            *" $extension "*) ;;
            *"zend $extension "*) ;;
            *) missing="$missing $extension" ;;
        esac
    done
    [ -z "$missing" ] || fail "PHP extensions not loaded:$missing"
}

# PHP_* environment variables reach php.ini through ${VAR} substitution. Override a few
# of the different value types (size, boolean, list) and confirm PHP sees them.
# OPcache is enabled so the CLI SAPI also allocates the shared cache with the tuned defaults.
test_applies_environment_variables_to_php_ini() {
    local values
    values=$(run_php 'echo ini_get("memory_limit"), " ", ini_get("realpath_cache_size"), " ", ini_get("session.cookie_httponly"), " ", ini_get("disable_functions"), " ", ini_get("opcache.force_restart_timeout");' \
        --env PHP_MEMORY_LIMIT=512M \
        --env PHP_REALPATH_CACHE_SIZE=8M \
        --env PHP_SESSION_COOKIE_HTTPONLY=0 \
        --env PHP_DISABLE_FUNCTIONS=shell_exec \
        --env PHP_OPCACHE_ENABLE=1 \
        --env PHP_OPCACHE_FORCE_RESTART_TIMEOUT=60)
    [ "$values" = "512M 8M 0 shell_exec 60" ] || fail "PHP_* environment variables did not apply to php.ini. Got: $values"
}

# PHP_OPCACHE_ENABLE_CLI turns OPcache off for the CLI SAPI while opcache.enable stays on for the web server.
test_disables_opcache_for_the_cli() {
    local status
    status=$(run_php 'echo function_exists("opcache_get_status") && opcache_get_status(false) !== false ? "on" : "off";' \
        --env PHP_OPCACHE_ENABLE=1 --env PHP_OPCACHE_ENABLE_CLI=0)
    [ "$status" = "off" ] || fail "PHP_OPCACHE_ENABLE_CLI=0 did not disable OPcache for the CLI. Got: $status"
}

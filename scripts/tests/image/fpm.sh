# shellcheck shell=bash
# The PHP-FPM pool (src/php-fpm.d/usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf).
requires fpm

# PHP_FPM_* environment variables reach the pool through ${VAR} substitution.
test_applies_environment_variables_to_the_pool() {
    local config setting
    config=$(docker run --rm \
        --env PHP_FPM_POOL_NAME=tested \
        --env PHP_FPM_PM_CONTROL=dynamic \
        --env PHP_FPM_PM_MAX_CHILDREN=9 \
        --env PHP_FPM_PM_START_SERVERS=3 \
        --env PHP_FPM_PM_MIN_SPARE_SERVERS=2 \
        --env PHP_FPM_PM_MAX_SPARE_SERVERS=4 \
        --env PHP_FPM_PM_MAX_REQUESTS=250 \
        --env PHP_FPM_PROCESS_CONTROL_TIMEOUT=17 \
        "$image" sh -c 'php-fpm -tt 2>&1' | sed -n 's/^.*NOTICE: [[:space:]]*//p')
    for setting in "process_control_timeout = 17s" "[tested]" "pm = dynamic" "pm.max_children = 9" \
        "pm.start_servers = 3" "pm.min_spare_servers = 2" "pm.max_spare_servers = 4" "pm.max_requests = 250"; do
        printf '%s\n' "$config" | grep -qxF "$setting" || fail "php-fpm -tt does not report \"$setting\""
    done
}

# shellcheck shell=bash
# AUTORUN_* automations (src/common/etc/entrypoint.d/50-laravel-automations.sh) against
# fixtures/laravel, whose artisan records each command instead of running Laravel.
# The database connection check needs a real app, so it is skipped.

# Sets output, status, and calls (the artisan commands that ran, joined with ";").
run_automations() {
    set +e
    output=$(docker run --rm \
        --volume "$fixtures_dir/laravel:/var/www/html:ro" \
        --env AUTORUN_ENABLED=true \
        --env AUTORUN_LARAVEL_MIGRATION_SKIP_DB_CHECK=true \
        "$@" "$image" sh -c 'echo "--- artisan calls ---"; cat /tmp/artisan.log 2>/dev/null || true' 2>&1)
    status=$?
    set -e
    calls=$(printf '%s\n' "$output" | sed -n '/^--- artisan calls ---$/,$p' | tail -n +2 | paste -sd ';' -)
}

expect_calls() {
    [ "$status" -eq 0 ] || fail "Container exited with status $status:"$'\n'"$output"
    [ "$calls" = "$1" ] || fail "Expected artisan calls: ${1:-<none>}"$'\n'"Got: ${calls:-<none>}"
}

expect_container_stopped() {
    [ "$status" -ne 0 ] || fail "Container started anyway:"$'\n'"$output"
    # The banner prints the command, so only a line of its own means it ran.
    ! printf '%s\n' "$output" | grep -qx -- "--- artisan calls ---" || fail "The command ran after the automations failed"
}

no_migration_or_storage_link=(--env AUTORUN_LARAVEL_STORAGE_LINK=false --env AUTORUN_LARAVEL_MIGRATION=false)
no_optimizations=(--env AUTORUN_LARAVEL_OPTIMIZE=false --env AUTORUN_LARAVEL_CONFIG_CACHE=false --env AUTORUN_LARAVEL_ROUTE_CACHE=false --env AUTORUN_LARAVEL_VIEW_CACHE=false --env AUTORUN_LARAVEL_EVENT_CACHE=false)

test_does_nothing_unless_autorun_is_enabled() {
    run_automations --env AUTORUN_ENABLED=false
    expect_calls ""
}

test_links_storage_migrates_and_optimizes_by_default() {
    run_automations
    expect_calls "storage:link;config:clear;migrate --force;optimize"
}

test_excludes_disabled_caches_from_optimize() {
    run_automations "${no_migration_or_storage_link[@]}" --env AUTORUN_LARAVEL_ROUTE_CACHE=false --env AUTORUN_LARAVEL_VIEW_CACHE=false
    expect_calls "optimize --except=routes,views"
}

# optimize --except needs Laravel 11.38.0.
test_runs_each_cache_command_before_laravel_11_38() {
    run_automations "${no_migration_or_storage_link[@]}" --env FAKE_LARAVEL_VERSION=11.37.0 --env AUTORUN_LARAVEL_VIEW_CACHE=false
    expect_calls "config:cache;route:cache;event:cache"
}

test_migrates_each_listed_database() {
    run_automations "${no_optimizations[@]}" --env AUTORUN_LARAVEL_STORAGE_LINK=false \
        --env AUTORUN_LARAVEL_MIGRATION_DATABASE=mysql,pgsql \
        --env AUTORUN_LARAVEL_MIGRATION_MODE=fresh \
        --env AUTORUN_LARAVEL_MIGRATION_SEED=true
    expect_calls "config:clear;migrate:fresh --database=mysql --force --seed;migrate:fresh --database=pgsql --force --seed"
}

test_runs_isolated_migrations() {
    run_automations "${no_optimizations[@]}" --env AUTORUN_LARAVEL_STORAGE_LINK=false --env AUTORUN_LARAVEL_MIGRATION_ISOLATION=true
    expect_calls "config:clear;migrate:status;migrate --force --isolated"
}

test_stops_the_container_when_a_migration_fails() {
    run_automations --env "FAKE_ARTISAN_FAILS=migrate --force"
    expect_container_stopped
}

test_stops_the_container_when_laravel_is_missing() {
    run_automations --env APP_BASE_DIR=/var/www/missing
    expect_container_stopped
}

test_skips_a_missing_laravel_app_when_asked() {
    run_automations --env APP_BASE_DIR=/var/www/missing --env AUTORUN_LARAVEL_SKIP_IF_NOT_FOUND=true
    expect_calls ""
}

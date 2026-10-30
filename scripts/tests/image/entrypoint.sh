# shellcheck shell=bash
# docker-php-serversideup-entrypoint: the scripts in /etc/entrypoint.d, then the command.

# Usage: run_entrypoint <script in fixtures/entrypoint.d>... -- <command>...
# Sets output and status.
run_entrypoint() {
    local volumes=()
    while [ "$1" != "--" ]; do
        volumes+=(--volume "$fixtures_dir/entrypoint.d/$1:/etc/entrypoint.d/$1:ro")
        shift
    done
    shift
    set +e
    output=$(docker run --rm "${volumes[@]}" "$image" "$@" 2>&1)
    status=$?
    set -e
}

# 10-second.sh exits early, which must not stop 100-third.sh.
test_runs_custom_scripts_in_numeric_order() {
    local order
    run_entrypoint 2-first.sh 10-second.sh 100-third.sh -- true
    [ "$status" -eq 0 ] || fail "Container exited with status $status:"$'\n'"$output"
    order=$(printf '%s\n' "$output" | sed -n 's/^custom-script: //p' | paste -sd ' ' -)
    [ "$order" = "2-first 10-second 100-third" ] || fail "Scripts ran in this order: ${order:-<none>}"
}

test_stops_before_the_command_when_a_script_fails() {
    run_entrypoint 20-fails.sh -- echo command-ran
    [ "$status" -eq 3 ] || fail "Expected the script's exit status 3, got $status:"$'\n'"$output"
    # The banner prints the command, so only a line of its own means it ran.
    ! printf '%s\n' "$output" | grep -qx command-ran || fail "The command ran after a script failed"
}

test_passes_a_flag_command_to_php() {
    run_entrypoint -- -r 'echo "flag-command-ok";'
    [ "$(printf '%s\n' "$output" | tail -n1)" = "flag-command-ok" ] || fail "Expected PHP to run the flags. Got:"$'\n'"$output"
}

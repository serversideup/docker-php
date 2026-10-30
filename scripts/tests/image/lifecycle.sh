# shellcheck shell=bash
# Starting and stopping the way orchestrators do: wait for the HEALTHCHECK, then docker stop.
requires healthcheck

setup() {
    start_container
}

test_becomes_healthy() {
    local status
    status=$(docker inspect --format '{{.State.Health.Status}}' "$container")
    [ "$status" = "healthy" ] || fail "Health status is $status"
}

# docker stop sends the image's STOPSIGNAL and kills the container 10s later by default,
# cutting off requests in flight during a rolling deploy. Runs last because it stops the
# shared container.
test_stops_before_docker_kills_it() {
    local started=$SECONDS elapsed
    # s6's /init ignores the SIGQUIT these images stop with, so they keep serving until
    # Docker kills them. That is what makes them zero-downtime ready (issue #647).
    [ -z "$(image_env S6_KEEP_ENV)" ] || skip "s6 images wait to be killed on purpose"
    docker stop --time 30 "$container" >/dev/null
    elapsed=$((SECONDS - started))
    [ "$elapsed" -lt 10 ] || fail "Container took ${elapsed}s to stop after its STOPSIGNAL ($(docker image inspect --format "{{.Config.StopSignal}}" "$image"))"
}

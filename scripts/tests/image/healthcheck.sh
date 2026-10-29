# shellcheck shell=bash
# The image's own HEALTHCHECK, which orchestrators use to decide when to send traffic.
requires healthcheck

test_becomes_healthy() {
    start_container
}

# shellcheck shell=bash
# Matching www-data to a host user at build time, the way
# docs/content/docs/5.guide/3.understanding-file-permissions.md shows.

new_id=1000:1000

setup() {
    image=$(build_image <<DOCKERFILE
USER root
RUN docker-php-serversideup-set-id www-data $new_id && \
    docker-php-serversideup-set-file-permissions --owner $new_id
USER www-data
DOCKERFILE
)
}

test_runs_as_the_new_uid_and_gid() {
    local id
    id=$(docker run --rm "$image" sh -c 'echo "$(id -u):$(id -g)"' | tail -n1)
    [ "$id" = "$new_id" ] || fail "Container runs as $id, expected $new_id"
}

test_becomes_healthy_and_serves_php_as_the_new_uid() {
    requires healthcheck
    start_container
    [ -z "$http_port" ] || expect_body / "serversideup-php-ok:${php_version}"
}

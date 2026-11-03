# shellcheck shell=bash
# Matching www-data to a host user at build time, the way
# docs/content/docs/5.customizing-the-image/5.understanding-file-permissions.md shows.

new_id=1000:1000

setup() {
    base_image=$image
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

test_moves_another_user_and_group_off_the_requested_ids() {
    local image=$base_image collision_image ids
    collision_image=$(build_image <<'DOCKERFILE'
USER root
RUN groupadd --gid 1001 taken && \
    useradd --uid 1001 --gid 1001 --no-create-home taken && \
    docker-php-serversideup-set-id www-data 1001:1001
USER www-data
DOCKERFILE
)
    ids=$(docker run --rm "$collision_image" sh -c 'echo "$(id -u www-data):$(id -g www-data) $(id -u taken):$(id -g taken)"' | tail -n1)
    [ "$ids" = "1001:1001 991001:991001" ] || fail "Expected www-data 1001:1001 and taken 991001:991001, got $ids"
}

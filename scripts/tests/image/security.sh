# shellcheck shell=bash
# Defaults that keep a compromised app from taking over the container.

test_runs_as_an_unprivileged_user() {
    local uid
    uid=$(docker run --rm "$image" id -u | tail -n1)
    [ "$uid" != "0" ] || fail "Container runs as root by default"
}

# A COPY without --chmod gives existing destination directories the build context's modes.
# Sticky directories like /tmp are expected.
test_has_no_world_writable_files_or_directories() {
    local world_writable
    world_writable=$(docker run --rm --user root --entrypoint sh "$image" -c \
        'find / -xdev -perm -0002 \( -type d ! -perm -1000 -o -type f \) -print')
    [ -z "$world_writable" ] || fail "World-writable paths:"$'\n'"$world_writable"
}

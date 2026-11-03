#!/bin/bash
###################################################
# Usage: check-command-docs.sh
###################################################
# Fails when docs/content/data/commands.yml and the commands the images ship
# disagree: a command in /usr/local/bin that isn't documented, a documented
# command that no longer exists, or a variation list that doesn't match.
#
# A variation ships the scripts in each src/<dir>/usr/local/bin it copies with
# `COPY ... src/<dir>/ /`, plus the downloaded commands listed below.
set -euo pipefail

cd "$(dirname "$0")/.."

DOCS_FILE="docs/content/data/commands.yml"

# Build steps only, never run by users.
INTERNAL_COMMANDS="docker-php-serversideup-s6-install"

# Commands the Dockerfiles download, as "command:text that installs it in a Dockerfile".
DOWNLOADED_COMMANDS="install-php-extensions:docker-php-serversideup-install-php-ext-installer php-fpm-healthcheck:/usr/local/bin/php-fpm-healthcheck"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

if ! yq -r '.commands[].name' "$DOCS_FILE" | LC_ALL=C sort -c 2>/dev/null; then
  echo "❌ Keep the commands in $DOCS_FILE sorted A-Z by name."
  exit 1
fi

variations=$(find src/variations -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | tr '\n' ' ')

# command, variation: one line for each variation that ships the command
for variation in $variations; do
  dockerfile="src/variations/$variation/Dockerfile"
  for dir in $(grep -oE '^COPY .* src/[a-z0-9-]+/ /' "$dockerfile" | grep -oE 'src/[a-z0-9-]+' | sort -u); do
    [ -d "$dir/usr/local/bin" ] || continue
    for file in "$dir"/usr/local/bin/*; do
      printf '%s\t%s\n' "$(basename "$file")" "$variation"
    done
  done
  for entry in $DOWNLOADED_COMMANDS; do
    if grep -qF "${entry#*:}" "$dockerfile"; then
      printf '%s\t%s\n' "${entry%%:*}" "$variation"
    fi
  done
done | sort -u > "$work_dir/shipped.tsv"

yq -r '.commands[] | [.name, ((.variations // ["*"]) | join(" "))] | @tsv' "$DOCS_FILE" > "$work_dir/docs.tsv"

awk -F'\t' -v variations="$variations" -v internal="$INTERNAL_COMMANDS" -v docs_file="$DOCS_FILE" '
  BEGIN {
    variation_count = split(variations, all_variations, " ")
    split(internal, internal_list, " ")
    for (i in internal_list) is_internal[internal_list[i]] = 1
  }
  FNR == NR {
    documented[$1] = 1
    if ($2 == "*") {
      for (i = 1; i <= variation_count; i++) in_docs[$1, all_variations[i]] = 1
    } else {
      count = split($2, list, " ")
      for (i = 1; i <= count; i++) in_docs[$1, list[i]] = 1
    }
    next
  }
  function fail(message) { print "❌ " message; failures++ }
  {
    if (is_internal[$1]) next
    shipped[$1] = 1
    ships[$1, $2] = 1
    if (!($1 in documented) && !reported[$1]++) fail($1 " ships in /usr/local/bin but is missing from " docs_file)
  }
  END {
    total = 0
    for (name in documented) {
      total++
      if (!shipped[name]) { fail(name " is documented but no variation ships it"); continue }
      for (i = 1; i <= variation_count; i++) {
        v = all_variations[i]
        if (ships[name, v] && !in_docs[name, v]) fail(name " ships in " v " but is not listed for it in the docs")
        if (!ships[name, v] && in_docs[name, v]) fail(name " is listed for " v " in the docs but " v " does not ship it")
      }
    }
    if (failures) {
      print ""
      print "Fix " docs_file " or the code so they match."
      exit 1
    }
    print "✅ All " total " documented commands match src/."
  }
' "$work_dir/docs.tsv" "$work_dir/shipped.tsv"

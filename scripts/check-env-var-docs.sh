#!/bin/bash
###################################################
# Usage: check-env-var-docs.sh
###################################################
# Fails when docs/content/data/env-vars.yml and the variables in src/ disagree:
# a variable the images read that isn't documented, a documented variable that
# no longer exists, or a default or variation list that doesn't match.
# Also fails when a docs page table with "Variable" and "Default" columns shows
# a default that env-vars.yml doesn't have.
#
# Variables come from three places in src/:
#   - ENV lines in each variation's final image stage (with per-variation defaults)
#   - `: "${NAME:=default}"` in scripts
#   - `{$NAME:default}` placeholders in the FrankenPHP Caddyfiles
set -euo pipefail

cd "$(dirname "$0")/.."

DOCS_FILE="docs/content/data/env-vars.yml"
DOCS_PAGES_DIR="docs/content/docs"

# Read by build steps or internal plumbing only, never set by users.
INTERNAL_VARIABLES="AUTORUN_LIB_DIR PHP_EXT_INSTALLER_VERSION PHPREDIS_LIBLZF_REF PHPREDIS_VERSION S6_RUNTIME_BUNDLEDIR"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

variations=$(find src/variations -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | tr '\n' ' ')

if ! yq -r '.variables[].name' "$DOCS_FILE" | LC_ALL=C sort -c 2>/dev/null; then
  echo "❌ Keep the variables in $DOCS_FILE sorted A-Z by name. This lists them in order:"
  echo "   yq -r '.variables[].name' $DOCS_FILE | LC_ALL=C sort"
  exit 1
fi

# name, default ("~" when unset), variations ("*" for all), variation defaults ("variation=value;...")
yq -r '.variables[] | [
    .name,
    (.default // "~"),
    ((.variations // ["*"]) | join(" ")),
    ((.variation_defaults // {}) | to_entries | map(.key + "=" + .value) | join(";"))
  ] | @tsv' "$DOCS_FILE" > "$work_dir/docs.tsv"

# source, variation, name, value ("<none>" when the source gives no default)
found="$work_dir/found.tsv"
: > "$found"

for variation in $variations; do
  # Walk from the last stage up through the stages it builds FROM, so only ENV
  # that reaches the published image counts. A later stage overrides an earlier one.
  awk -v variation="$variation" '
    /^FROM / {
      stage++
      parent[stage] = $2
      for (i = 3; i < NF; i++) if (toupper($i) == "AS") stage_index[$(i + 1)] = stage
      next
    }
    /^[[:space:]]*ENV[[:space:]]/ { in_env = 1; sub(/^[[:space:]]*ENV[[:space:]]+/, "") }
    in_env {
      line = $0
      continued = (line ~ /\\[[:space:]]*$/)
      sub(/\\[[:space:]]*$/, "", line)
      while (match(line, /[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|[^[:space:]]*)/)) {
        pair = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        name = pair; sub(/=.*/, "", name)
        value = pair; sub(/^[^=]*=/, "", value); gsub(/^"|"$/, "", value)
        if (!((stage, name) in env)) names[stage] = names[stage] " " name
        env[stage, name] = value
      }
      if (!continued) in_env = 0
    }
    END {
      s = stage
      while (s > 0) {
        count = split(names[s], list, " ")
        for (i = 1; i <= count; i++) {
          if (!(list[i] in seen)) {
            seen[list[i]] = 1
            print "env\t" variation "\t" list[i] "\t" env[s, list[i]]
          }
        }
        s = (parent[s] in stage_index) ? stage_index[parent[s]] : 0
      }
    }
  ' "src/variations/$variation/Dockerfile" >> "$found"
done

grep -rhoE ': "\$\{[A-Z_][A-Z0-9_]*:=[^}]*\}"' src \
  | sed -E 's/^: "\$\{([A-Z0-9_]+):=(.*)\}"$/script\t*\t\1\t\2/' >> "$found" || true

grep -rhv '^[[:space:]]*#' src/variations/frankenphp/etc \
  | grep -oE '\{(\$|env\.)[A-Z_][A-Z0-9_]*(:[^}]*)?\}' \
  | sed -E 's/^\{(\$|env\.)([A-Z0-9_]+):(.*)\}$/caddy\tfrankenphp\t\2\t\3/; s/^\{(\$|env\.)([A-Z0-9_]+)\}$/caddy\tfrankenphp\t\2\t<none>/' >> "$found" || true

# Every name found anywhere in src/, for documented variables read without a default
grep -rhoE '\$\{?[A-Z_][A-Z0-9_]*' src | tr -d '${' | sort -u > "$work_dir/referenced.txt" || true

awk -F'\t' -v variations="$variations" -v internal="$INTERNAL_VARIABLES" \
  -v referenced="$work_dir/referenced.txt" -v docs_file="$DOCS_FILE" '
  BEGIN {
    variation_count = split(variations, all_variations, " ")
    split(internal, internal_list, " ")
    for (i in internal_list) is_internal[internal_list[i]] = 1
    while ((getline name < referenced) > 0) is_referenced[name] = 1
  }
  FNR == NR {
    documented[$1] = 1
    base_default[$1] = $2
    if ($3 == "*") {
      for (i = 1; i <= variation_count; i++) in_docs[$1, all_variations[i]] = 1
    } else {
      count = split($3, list, " ")
      for (i = 1; i <= count; i++) in_docs[$1, list[i]] = 1
    }
    count = split($4, pairs, ";")
    for (i = 1; i <= count; i++) {
      split(pairs[i], pair, "=")
      variation_default[$1, pair[1]] = substr(pairs[i], length(pair[1]) + 2)
      has_variation_default[$1] = 1
    }
    next
  }
  function expected(name, variation) {
    return ((name, variation) in variation_default) ? variation_default[name, variation] : base_default[name]
  }
  function fail(message) { print "❌ " message; failures++ }
  {
    source = $1; variation = $2; name = $3; value = $4
    in_src[name] = 1
    if (is_internal[name]) next
    if (!(name in documented)) {
      if (!reported_missing[name]++) fail(name " is read in src/ but missing from " docs_file)
      next
    }
    if (source == "env") {
      in_env[name, variation] = 1
      has_env[name] = 1
    }
    if (base_default[name] == "~" || value == "<none>") next
    if (source == "env" || source == "caddy") {
      if (value != expected(name, variation)) fail(name " defaults to \"" value "\" in " variation ", but the docs say \"" expected(name, variation) "\"")
    } else if (source == "script" && !has_variation_default[name]) {
      if (value != base_default[name] && !reported_script[name]++) fail(name " defaults to \"" value "\" in a script, but the docs say \"" base_default[name] "\"")
    }
  }
  END {
    for (name in documented) {
      if (!in_src[name] && !is_referenced[name]) fail(name " is documented but not read anywhere in src/")
      if (!has_env[name]) continue
      for (i = 1; i <= variation_count; i++) {
        v = all_variations[i]
        if (in_env[name, v] && !in_docs[name, v]) fail(name " is set in " v " but not listed for it in the docs")
        if (!in_env[name, v] && in_docs[name, v]) fail(name " is listed for " v " in the docs but not set in its Dockerfile")
      }
    }
    total = 0
    for (name in documented) total++
    if (failures) {
      print ""
      print "Fix " docs_file " or the code so they match."
      exit 1
    }
    print "✅ All " total " documented variables match src/."
  }
' "$work_dir/docs.tsv" "$found" || status=1

# A page may repeat a default in a table for context, as long as it matches env-vars.yml.
# Write the cell as `value`, `""` for empty, or Unset. Any documented default
# (the base one or a variation's) is accepted.
find "$DOCS_PAGES_DIR" -name '*.md' -print0 | sort -z | xargs -0 awk -F'|' -v docs_file="$DOCS_FILE" -v docs_tsv="$work_dir/docs.tsv" '
  function trim(text) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", text); return text }
  function fail(message) { print "❌ " FILENAME ":" FNR ": " message; failures++ }
  BEGIN {
    while ((getline line < docs_tsv) > 0) {
      split(line, field, "\t")
      documented[field[1]] = 1
      accepted[field[1], field[2]] = 1
      expected[field[1]] = (field[2] == "~") ? "Unset" : "`" field[2] "`"
      if (field[4] != "") expected[field[1]] = expected[field[1]] " (or a variation default: " field[4] ")"
      count = split(field[4], pairs, ";")
      for (i = 1; i <= count; i++) accepted[field[1], substr(pairs[i], index(pairs[i], "=") + 1)] = 1
    }
  }
  FNR == 1 { in_table = 0 }
  !/^\|/ { in_table = 0; next }
  !in_table {
    in_table = 1; variable_column = 0; default_column = 0
    for (i = 2; i < NF; i++) {
      if (trim($i) == "Variable") variable_column = i
      if (trim($i) == "Default") default_column = i
    }
    next
  }
  /^\|[[:space:]:|-]+$/ || !variable_column || !default_column { next }
  {
    name = trim($variable_column)
    if (name !~ /^`[A-Z_][A-Z0-9_]*`$/) next
    gsub(/`/, "", name)
    cell = trim($default_column)
    if (!(name in documented)) { fail(name " is not in " docs_file); next }
    if (tolower(cell) ~ /^unset/) value = "~"
    else if (match(cell, /^`[^`]*`/)) {
      value = substr(cell, 2, RLENGTH - 2)
      if (value == "\"\"") value = ""
    } else { fail(name " default \"" cell "\" should be `value`, `\"\"`, or Unset"); next }
    if (!((name, value) in accepted)) fail(name " shows `" value "`, but " docs_file " has " expected[name])
  }
  END {
    if (failures) { print ""; print "Fix the table or " docs_file " so they match."; exit 1 }
    print "✅ Every default in a docs page table matches " docs_file "."
  }
' || status=1

exit "${status:-0}"

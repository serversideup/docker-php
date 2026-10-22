# this script assumes gawk! (busybox "awk" is not quite sufficient)

# see https://github.com/docker-library/php or https://github.com/docker-library/golang for examples of usage ("apply-templates.sh")

# escape an arbitrary string for passing back to jq as program input
function jq_escape(str) {
	gsub(/\\/, "\\\\", str)
	gsub(/\n/, "\\n", str)
	gsub(/\r/, "\\r", str)
	gsub(/\t/, "\\t", str)
	gsub(/"/, "\\\"", str)
	return "\"" str "\""
}

# return the number of times needle appears in haystack
function num(haystack, needle, # parameters
             ret, i          ) # locals
{
	ret = 0
	while (i = index(haystack, needle)) {
		ret++
		haystack = substr(haystack, i + length(needle))
	}
	return ret
}

BEGIN {
	jq_expr_defs = ""
	jq_expr = ""
	agg_jq = ""
	agg_text = ""

	OPEN = "{{"
	CLOSE = "}}"
	CLOSE_EAT_EOL = "-" CLOSE ORS
}

function trim(str) {
	sub(/^[[:space:]]+/, "", str)
	sub(/[[:space:]]+$/, "", str)
	return str
}
function append(str) {
	if (jq_expr && jq_expr !~ /\($/ && str !~ /^\)/) {
		jq_expr = jq_expr "\n+ "
	} else if (jq_expr) {
		jq_expr = jq_expr "\n"
	}
	jq_expr = jq_expr str
}
function append_string(str) {
	if (!str) return
	str = jq_escape(str)
	append(str)
}
function append_jq(expr) {
	if (!expr) return
	expr = trim(expr)
	if (!expr) return
	if (expr ~ /^#[^\n]*$/) return # ignore pure comment lines {{ # ... -}}
	if (expr ~ /^(def|include|import)[[:space:]]/) { # a few things need to go at the start of our "script"
		jq_expr_defs = jq_expr_defs expr ";\n"
		return
	}
	# if expr doesn't begin with ")" or end with "(", wrap it in parenthesis (so our addition chain works properly)
	if (expr !~ /^\)/) expr = "(" expr
	if (expr !~ /\($/) expr = expr ")"
	append(expr)
}

{
	line = $0 ORS

	i = 0
	if (agg_jq || (i = index(line, OPEN))) {
		if (i) {
			agg_text = agg_text substr(line, 1, i - 1)
			line = substr(line, i)
		}
		append_string(agg_text)
		agg_text = ""

		agg_jq = agg_jq line
		line = ""

		if (num(agg_jq, OPEN) > num(agg_jq, CLOSE)) {
			next
		}

		while (i = index(agg_jq, OPEN)) {
			line = substr(agg_jq, 1, i - 1)
			agg_jq = substr(agg_jq, i + length(OPEN))
			if (i = index(agg_jq, CLOSE_EAT_EOL)) {
				expr = substr(agg_jq, 1, i - 1)
				agg_jq = substr(agg_jq, i + length(CLOSE_EAT_EOL))
			}
			else {
				i = index(agg_jq, CLOSE)
				expr = substr(agg_jq, 1, i - 1)
				agg_jq = substr(agg_jq, i + length(CLOSE))
			}
			append_string(line)
			append_jq(expr)
		}
		line = agg_jq
		agg_jq = ""
	}

	if (line) {
		agg_text = agg_text line
	}
}

END {
	append_string(agg_text)
	agg_text = ""

	append_jq(agg_jq)
	agg_jq = ""

	jq_expr = "if env.version then .[env.version] else . end | (\n" jq_expr "\n)"
	jq_expr = jq_expr_defs jq_expr

	if (ENVIRON["DEBUG"]) {
		print jq_expr > "/dev/stderr"
	}

	prog = "jq --join-output --from-file /dev/stdin versions.json"
	printf "%s", jq_expr | prog

	e = close(prog)
	if (e != 0) {
		exit(e)
	}
}

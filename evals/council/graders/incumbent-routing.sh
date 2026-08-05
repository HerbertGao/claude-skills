#!/usr/bin/env bash
# Exact routing contract; rationale lives outside the staged grader directory.
set -u
p=0
t=7
checks=""
outcome=${OUTCOME_FILE:-OUTCOME.md}
add() { checks="$checks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
check_exact() {
	name=$1
	line_no=$2
	key=$3
	expected=$4
	actual=$(sed -n "${line_no}p" "$outcome" 2>/dev/null)
	count=$(grep -c "^${key}:" "$outcome" 2>/dev/null || true)
	if [ "$actual" = "$expected" ] && [ "$count" -eq 1 ]; then
		p=$((p + 1))
		add "$name" true "$expected"
	else
		add "$name" false "$expected"
	fi
}
check_exact greenfield 1 ROUTE-A 'ROUTE-A: council-greenfield'
check_exact draft_decision 2 ROUTE-B 'ROUTE-B: council-incumbent-draft'
check_exact draft_revision 3 ROUTE-C 'ROUTE-C: review-loop'
check_exact sequential 4 ROUTE-D 'ROUTE-D: council-then-review-loop'
check_exact unresolved_stop 5 ROUTE-E 'ROUTE-E: stop-after-council-unresolved'
check_exact read_only 6 COUNCIL-EDITS-DRAFT 'COUNCIL-EDITS-DRAFT: no'
lines=$(awk 'END {print NR+0}' "$outcome" 2>/dev/null)
if [ "$lines" -eq 6 ]; then
	p=$((p + 1))
	add closed_schema true 'exactly six lines'
else
	add closed_schema false 'exactly six lines'
fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${checks%,}]}"

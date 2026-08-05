#!/usr/bin/env bash
# Exact incumbent-mode protocol contract; rationale lives in GRADERS.md.
set -u
p=0
t=21
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
check_exact adoption 1 BRIEF 'BRIEF: adopted-before-seating'
check_exact draft_claims 2 DRAFT-CLAIMS 'DRAFT-CLAIMS: excluded-unless-neutral-adoption'
check_exact fingerprints 3 FINGERPRINTS 'FINGERPRINTS: complete'
check_exact constraints 4 HARD-CONSTRAINTS 'HARD-CONSTRAINTS: cited-brief-sources-only'
check_exact blindness 5 ROUND1 'ROUND1: incumbent-blind'
check_exact honest_search 6 SEARCH 'SEARCH: mandatory-candidate-optional'
check_exact freeze 7 FREEZE 'FREEZE: before-reveal'
check_exact reveal 8 REVEAL 'REVEAL: after-freeze'
check_exact compare 9 COMPARE 'COMPARE: one-per-compliant-seat'
check_exact criteria 10 SHARED-CRITERIA 'SHARED-CRITERIA: same-for-all-candidates'
check_exact decision_base 11 DECISION-BASE 'DECISION-BASE: compare-returns'
check_exact no_challenger 12 ZERO-CHALLENGER 'ZERO-CHALLENGER: allowed-with-ledger-and-DA'
check_exact combine 13 COMBINE 'COMBINE: qualify-as-candidate'
check_exact digest 14 DIGEST 'DIGEST: unchanged'
check_exact no_edit 15 DRAFT-EDITED 'DRAFT-EDITED: no'
check_exact blindness_floor 16 BLINDNESS-FLOOR 'BLINDNESS-FLOOR: exact-scan-not-semantic-proof'
check_exact audit_ids 17 AUDIT-IDS 'AUDIT-IDS: I0-I5-separate'
check_exact disposition 18 INCUMBENT-DECISION 'INCUMBENT-DECISION: keep-record-field'
check_exact terminal 19 TERMINAL 'TERMINAL: ADVISORY (debate-converged; unaudited)'
check_exact unresolved_handoff 20 UNRESOLVED-HANDOFF 'UNRESOLVED-HANDOFF: blocked'
lines=$(awk 'END {print NR+0}' "$outcome" 2>/dev/null)
if [ "$lines" -eq 20 ]; then
	p=$((p + 1))
	add closed_schema true 'exactly twenty lines'
else
	add closed_schema false 'exactly twenty lines'
fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${checks%,}]}"

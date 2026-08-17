#!/usr/bin/env bash
# Exact incumbent-mode protocol contract; rationale lives in GRADERS.md.
set -u
p=0
t=30
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
check_exact primary_exposure 5 PRIMARY-EXPOSURE 'PRIMARY-EXPOSURE: not-supplied'
check_exact primary_independence 6 PRIMARY-INDEPENDENCE 'PRIMARY-INDEPENDENCE: not-claimed'
check_exact honest_search 7 SEARCH 'SEARCH: mandatory-candidate-optional'
check_exact freeze 8 FREEZE 'FREEZE: before-reveal'
check_exact reveal 9 REVEAL 'REVEAL: after-freeze'
check_exact compare 10 COMPARE 'COMPARE: one-per-compliant-seat'
check_exact criteria 11 SHARED-CRITERIA 'SHARED-CRITERIA: same-for-all-candidates'
check_exact decision_base 12 DECISION-BASE 'DECISION-BASE: compare-returns'
check_exact no_challenger 13 ZERO-CHALLENGER 'ZERO-CHALLENGER: allowed-with-ledger-and-DA'
check_exact combine 14 COMBINE 'COMBINE: qualify-as-candidate'
check_exact digest 15 DIGEST 'DIGEST: unchanged'
check_exact no_edit 16 DRAFT-EDITED 'DRAFT-EDITED: no'
check_exact blindness_floor 17 BLINDNESS-FLOOR 'BLINDNESS-FLOOR: exact-scan-not-semantic-proof'
check_exact audit_ids 18 AUDIT-IDS 'AUDIT-IDS: I0-I5-separate'
check_exact disposition 19 INCUMBENT-DECISION 'INCUMBENT-DECISION: keep-record-field'
check_exact terminal 20 TERMINAL 'TERMINAL: ADVISORY (debate-converged; unaudited)'
check_exact unresolved_handoff 21 UNRESOLVED-HANDOFF 'UNRESOLVED-HANDOFF: blocked'
check_exact visible_fallback 22 VISIBLE-FALLBACK 'VISIBLE-FALLBACK: continues-advisory'
check_exact visible_exposure 23 VISIBLE-EXPOSURE 'VISIBLE-EXPOSURE: visible'
check_exact visible_independence 24 VISIBLE-INDEPENDENCE 'VISIBLE-INDEPENDENCE: not-claimed'
check_exact visible_agreement 25 VISIBLE-AGREEMENT-SUPPORT 'VISIBLE-AGREEMENT-SUPPORT: forbidden'
check_exact visible_freeze 26 VISIBLE-FREEZE 'VISIBLE-FREEZE: no'
check_exact visible_reveal 27 VISIBLE-REVEAL 'VISIBLE-REVEAL: already-visible'
check_exact visible_audit 28 VISIBLE-AUDIT 'VISIBLE-AUDIT: not-run-advisory'
check_exact visible_terminal 29 VISIBLE-TERMINAL 'VISIBLE-TERMINAL: ADVISORY (debate-converged; unaudited)'
lines=$(awk 'END {print NR+0}' "$outcome" 2>/dev/null)
if [ "$lines" -eq 29 ]; then
	p=$((p + 1))
	add closed_schema true 'exactly twenty-nine lines'
else
	add closed_schema false 'exactly twenty-nine lines'
fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${checks%,}]}"

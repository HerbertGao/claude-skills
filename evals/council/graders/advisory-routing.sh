#!/bin/bash
# Grades an exact, ordered and unique capability-routing schema.
p=0
t=46
cks=""
outcome=${OUTCOME_FILE:-OUTCOME.md}
add() { cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

check_exact() {
  name="$1"
  line_no="$2"
  key="$3"
  expected="$4"
  message="$5"
  actual=$(sed -n "${line_no}p" "$outcome" 2>/dev/null)
  count=$(grep -c "^${key}:" "$outcome" 2>/dev/null || true)
  if [ "$actual" = "$expected" ] && [ "$count" -eq 1 ]; then
    p=$((p + 1))
    add "$name" true "$message"
  else
    add "$name" false "$message"
  fi
}

check_exact profileA_mode 1 PROFILE-A-MODE 'PROFILE-A-MODE: advisory' 'Profile A routes to advisory'
check_exact profileA_round1 2 PROFILE-A-ROUND1 'PROFILE-A-ROUND1: batched' 'Profile A batches frozen prompts'
check_exact profileA_later 3 PROFILE-A-LATER-ROUNDS 'PROFILE-A-LATER-ROUNDS: fresh-redispatch' 'No-continuation host re-dispatches'
check_exact profileA_model 4 PROFILE-A-MODEL-CENSUS 'PROFILE-A-MODEL-CENSUS: unknown' 'Unavailable model stays unknown'
check_exact profileA_soft 5 PROFILE-A-SOFT-CHECK 'PROFILE-A-SOFT-CHECK: git-snapshot' 'Profile A uses scoped soft check'
check_exact profileA_gaps 6 PROFILE-A-ASSURANCE-GAPS 'PROFILE-A-ASSURANCE-GAPS: return-provenance,model-census,tool-write-audit,dispatch-topology,round-one-simultaneity,confirmation-provenance' 'Profile A lists exactly the stated missing guarantees'
check_exact profileA_token 7 PROFILE-A-TOKEN 'PROFILE-A-TOKEN: ADVISORY (debate-converged; unaudited)' 'Advisory token is qualified'
check_exact profileA_noauth 8 PROFILE-A-AUTHORIZES-IMPLEMENTATION 'PROFILE-A-AUTHORIZES-IMPLEMENTATION: no' 'Advisory is non-authorizing'
check_exact profileB_mode 9 PROFILE-B-MODE 'PROFILE-B-MODE: audited' 'Full host stays audited'
check_exact profileB_gate 10 PROFILE-B-CONVERGED-REQUIRES 'PROFILE-B-CONVERGED-REQUIRES: audit-pass,zero-open-cruxes,human-confirmation,post-confirmation-attestation' 'CONVERGED keeps audit, confirmation, and attestation gates'
check_exact profileB_token 11 PROFILE-B-TOKEN 'PROFILE-B-TOKEN: CONVERGED' 'Audited PASS plus confirmed attestation reaches CONVERGED'
check_exact profileC_token 12 PROFILE-C-TOKEN 'PROFILE-C-TOKEN: ADVISORY (debate-converged; unaudited)' 'Inherited contexts still support a qualified advisory'
check_exact profileC_separation 13 PROFILE-C-SEPARATION 'PROFILE-C-SEPARATION: inherited' 'Inherited positions never claim freshness'
check_exact profileD_stop 14 PROFILE-D-TOKEN 'PROFILE-D-TOKEN: STOPPED (advisory is analysis-only)' 'Unauthorized action remains stopped'
check_exact profileE_mode 15 PROFILE-E-MODE 'PROFILE-E-MODE: advisory' 'Restricted no-log seats use advisory'
check_exact profileE_round1 16 PROFILE-E-ROUND1 'PROFILE-E-ROUND1: parallel' 'Profile E keeps parallel round one'
check_exact profileE_later 17 PROFILE-E-LATER-ROUNDS 'PROFILE-E-LATER-ROUNDS: fresh-redispatch' 'Profile E supports no continuation'
check_exact profileE_token 18 PROFILE-E-TOKEN 'PROFILE-E-TOKEN: ADVISORY (debate-converged; unaudited)' 'Profile E token is qualified'
check_exact profileE_noauth 19 PROFILE-E-AUTHORIZES-IMPLEMENTATION 'PROFILE-E-AUTHORIZES-IMPLEMENTATION: no' 'Profile E is non-authorizing'
check_exact profileF_integrity 20 PROFILE-F-TOKEN 'PROFILE-F-TOKEN: UNRESOLVED (dispatch-unverifiable: 0 open)' 'Late record loss is integrity failure'
check_exact profileG_write 21 PROFILE-G-TOKEN 'PROFILE-G-TOKEN: STOPPED (advisory side effect detected)' 'Detected advisory write stops'
check_exact profileE_tools 22 PROFILE-E-TOOLS 'PROFILE-E-TOOLS: unknown' 'Unobservable tool use stays unknown without prescribing a worker'
check_exact profileE_model 23 PROFILE-E-MODEL-CENSUS 'PROFILE-E-MODEL-CENSUS: unknown' 'Unavailable Profile E model stays unknown'
check_exact profileE_gaps 24 PROFILE-E-ASSURANCE-GAPS 'PROFILE-E-ASSURANCE-GAPS: return-provenance,model-census,tool-write-audit,confirmation-provenance' 'Profile E lists its exact missing guarantees'
check_exact profileE_soft 25 PROFILE-E-SOFT-CHECK 'PROFILE-E-SOFT-CHECK: none' 'Profile E discloses no available soft check'
check_exact profileH_changed 26 PROFILE-H-TOKEN 'PROFILE-H-TOKEN: UNRESOLVED (confirmation-unverifiable: 0 open)' 'Changed post-audit candidate cannot converge'
check_exact profileI_interval 27 PROFILE-I-TOKEN 'PROFILE-I-TOKEN: UNRESOLVED (confirmation-unverifiable: 0 open)' 'Unexpected post-audit dispatch cannot converge'
check_exact profileJ_projection 28 PROFILE-J-TOKEN 'PROFILE-J-TOKEN: CONVERGED' 'Required read-only presentation projection remains allowed'
check_exact profileK_write 29 PROFILE-K-TOKEN 'PROFILE-K-TOKEN: UNRESOLVED (confirmation-unverifiable: 0 open)' 'Post-audit actual write cannot converge'
check_exact profileL_pins 30 PROFILE-L-TOKEN 'PROFILE-L-TOKEN: UNRESOLVED (audit-failed: fabrication)' 'Post-hoc audit pins are fabrication'
check_exact profileM_mode 31 PROFILE-M-MODE 'PROFILE-M-MODE: advisory' 'Tool-capable fresh workers use advisory instead of stopping'
check_exact profileM_round1 32 PROFILE-M-ROUND1 'PROFILE-M-ROUND1: parallel' 'Frozen round-one seats remain parallel when capacity allows'
check_exact profileM_tools 33 PROFILE-M-TOOLS 'PROFILE-M-TOOLS: read-only-observed' 'Observed read-only use is disclosed rather than rejected'
check_exact profileM_evidence 34 PROFILE-M-EVIDENCE 'PROFILE-M-EVIDENCE: seat-local' 'Seat evidence is not promoted to a moderator ruling'
check_exact profileM_token 35 PROFILE-M-TOKEN 'PROFILE-M-TOKEN: ADVISORY (debate-converged; unaudited)' 'Tool-capable fallback remains explicitly unaudited'
check_exact profileM_noauth 36 PROFILE-M-AUTHORIZES-IMPLEMENTATION 'PROFILE-M-AUTHORIZES-IMPLEMENTATION: no' 'Tool-capable advisory remains non-authorizing'
check_exact profileN_token 37 PROFILE-N-TOKEN 'PROFILE-N-TOKEN: ADVISORY (debate-converged; unaudited)' 'Read-only descendant use lowers assurance instead of stopping'
check_exact profileN_topology 38 PROFILE-N-TOPOLOGY 'PROFILE-N-TOPOLOGY: descendants-observed' 'Observed descendants are disclosed'
check_exact profileN_attribution 39 PROFILE-N-ATTRIBUTION 'PROFILE-N-ATTRIBUTION: parent-seat' 'Descendant work stays attributed to its parent'
check_exact profileN_seats 40 PROFILE-N-SEATS 'PROFILE-N-SEATS: 4' 'Descendants never inflate seat count'
check_exact profileO_floor 41 PROFILE-O-TOKEN 'PROFILE-O-TOKEN: STOPPED (cannot run expert seats)' 'A descendant cannot fill a missing named seat'
check_exact profileP_divergence 42 PROFILE-P-TOKEN 'PROFILE-P-TOKEN: STOPPED (seats exhausted)' 'Duplicate endorsements do not satisfy material divergence'
check_exact profileQ_network 43 PROFILE-Q-TOKEN 'PROFILE-Q-TOKEN: STOPPED (advisory side effect detected)' 'Observed seat network access remains a hard stop'
check_exact profileR_barrier 44 PROFILE-R-AGGREGATION 'PROFILE-R-AGGREGATION: waits-for-all-S' 'Aggregation waits for every manifested seat attempt'

bad_cert=$(grep -Ei 'ADVISORY.*(CERTIF|AUDIT[[:space:]]+PASS|[^[:alpha:]]AUDITED([^[:alpha:]]|$))' "$outcome" 2>/dev/null || true)
bad_authority=$(awk '{ line=tolower($0); if (line !~ /advisory/) next; gsub(/non-authoriz(ed|ing)/,"",line); gsub(/does not authorize/,"",line); gsub(/cannot authorize/,"",line); gsub(/never authorizes?/,"",line); if (line ~ /authoriz/ || line ~ /implementation[^.]*approv/ || line ~ /approv[^.]*implementation/ || line ~ /advisory[^.]*may proceed/) print $0 }' "$outcome" 2>/dev/null)
standalone=$(grep -Ei '^[[:space:]]*ADVISORY' "$outcome" 2>/dev/null || true)
bad_standalone=$(printf '%s\n' "$standalone" | grep -Eiv '^[[:space:]]*ADVISORY[[:space:]]+\((debate-converged; unaudited|[0-9]+ open; unaudited)\)[[:space:]]*$' || true)
if [ -n "$bad_standalone" ] || [ -n "$bad_cert" ] || [ -n "$bad_authority" ]; then
  add no_advisory_escalation false 'No bare, malformed, certified, audited, or authorizing ADVISORY appears anywhere'
else
  p=$((p + 1))
  add no_advisory_escalation true 'No bare, malformed, certified, audited, or authorizing ADVISORY appears anywhere'
fi

lines=$(awk 'END {print NR+0}' "$outcome" 2>/dev/null)
if [ "$lines" -eq 44 ]; then
  p=$((p + 1))
  add closed_schema true 'Outcome contains exactly the 44 required lines and no contradictory tail'
else
  add closed_schema false 'Outcome must contain exactly the 44 required lines and no contradictory tail'
fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"

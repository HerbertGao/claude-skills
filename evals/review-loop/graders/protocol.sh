#!/usr/bin/env bash
# Deterministic grader for the portable review-loop protocol probes.
set -euo pipefail
mode=${1:?usage: protocol.sh <routing|experts|root-cause>}
outcome=${OUTCOME_FILE:-OUTCOME.md}
checks=$(mktemp "${TMPDIR:-/tmp}/review-protocol.XXXXXX")
trap 'rm -f "$checks"' EXIT
p=0
t=0
add() {
	local name=$1 passed=$2
	t=$((t + 1))
	[ "$passed" = true ] && p=$((p + 1))
	printf '%s\t%s\n' "$name" "$passed" >>"$checks"
}
exact_prefix() {
	local expected=$1 n=0 want got
	while IFS= read -r want; do
		n=$((n + 1))
		got=$(sed -n "${n}p" "$outcome" 2>/dev/null || true)
		if [ "$got" = "$want" ]; then add "line-$n" true; else add "line-$n" false; fi
	done <<EOF
$expected
EOF
}
case "$mode" in
routing)
	exact_prefix "$(
		cat <<'EOF'
CASE-A: CR=registered, RC=registered, terminal-blocked=no, return=original
CASE-B: CR=local, RC=local, terminal-blocked=no, return=summarized
CASE-C: CR=embedded, RC=embedded, terminal-blocked=no, return=original
CASE-D: CR=same-context, RC=same-context, terminal-blocked=no, return=summarized
CATALOG-MISSING: continue
SANDBOX-MISSING: continue
EOF
	)"
	;;
experts)
	eligible=$(sed -n '1p' "$outcome" 2>/dev/null || true)
	ineligible=$(sed -n '2p' "$outcome" 2>/dev/null || true)
	selections=$(sed -n '3p' "$outcome" 2>/dev/null | sed -E 's/[[:space:]]*\+[[:space:]]*/ + /g' || true)
	cap=$(sed -n '4p' "$outcome" 2>/dev/null || true)
	missing=$(sed -n '5p' "$outcome" 2>/dev/null || true)
	authority=$(sed -n '6p' "$outcome" 2>/dev/null || true)
	if [ "$eligible" = 'ELIGIBLE: WeChat Mini Program Developer, Accessibility Auditor' ]; then add eligible true; else add eligible false; fi
	if [ "$ineligible" = 'INELIGIBLE: Frontend Developer, Software Architect, WeChat Official Account Specialist' ]; then add ineligible true; else add ineligible false; fi
	if [ "$selections" = 'VALID-SELECTIONS: none | WeChat Mini Program Developer | Accessibility Auditor | WeChat Mini Program Developer + Accessibility Auditor' ]; then add selections true; else add selections false; fi
	if [ "$cap" = 'EXPERT-SEAT-CAP: none' ]; then add cap true; else add cap false; fi
	if [ "$missing" = 'CATALOG-MISSING: continue-cr-rc-without-experts' ]; then add catalog-missing true; else add catalog-missing false; fi
	if [ "$authority" = 'EXPERT-AUTHORITY: findings-only' ]; then add authority true; else add authority false; fi
	unique=true
	for label in ELIGIBLE INELIGIBLE VALID-SELECTIONS EXPERT-SEAT-CAP CATALOG-MISSING EXPERT-AUTHORITY; do
		[ "$(grep -cE "^${label}:" "$outcome" 2>/dev/null || true)" = 1 ] || unique=false
	done
	add unique-fields "$unique"
	;;
root-cause)
	exact_prefix "$(
		cat <<'EOF'
CASE-A-IDENTITY: same blocker
CASE-A-ACTION: dispatch one new root-cause expert
CASE-A-TERMINAL: continue
CASE-B-TERMINAL: NOT-CONVERGED
CASE-C-IDENTITY: distinct blocker
CASE-C-ROOT-CAUSE-LATCH: unused
CASE-D-TERMINAL: NOT-CONVERGED
CASE-E-TERMINAL: OUT-OF-SCOPE-PENDING
GLOBAL-BUDGET: none
EOF
	)"
	;;
*)
	echo "unknown mode: $mode" >&2
	exit 2
	;;
esac
P=$p T=$t CHECKS=$checks python3 - <<'PY'
import json, os
rows = []
with open(os.environ["CHECKS"], encoding="utf-8") as f:
    for row in f:
        name, passed = row.rstrip("\n").split("\t")
        rows.append({"name": name, "passed": passed == "true", "message": "protocol classification"})
p, t = int(os.environ["P"]), int(os.environ["T"])
score = 1.0 if p == t else 0.0
print(json.dumps({"score": score, "details": f"{p}/{t} checks", "checks": rows}, separators=(",", ":")))
PY

#!/usr/bin/env bash
# Every deterministic grader must pass valid fixtures and reject near-miss false greens.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
check() {
	local grader=$1 fixture=$2 expected=$3 got
	local -a command
	read -r -a command <<<"$grader"
	got=$(OUTCOME_FILE="fixtures/$fixture" bash "${command[@]}" | python3 -c 'import json,sys; print("{:.2f}".format(json.load(sys.stdin)["score"]))')
	if [ "$got" = "$expected" ]; then
		printf '  ok   %s < %s = %s\n' "$grader" "$fixture" "$got"
	else
		printf '  FAIL %s < %s = %s (expected %s)\n' "$grader" "$fixture" "$got" "$expected"
		fail=1
	fi
}
parallel_check() {
	local grader=$1 fixture=$2 tmp status=0
	tmp=$(mktemp -d "${TMPDIR:-/tmp}/review-grader-parallel.XXXXXX")
	for i in {1..12}; do
		(OUTCOME_FILE="$PWD/fixtures/$fixture" bash "$grader" >"$tmp/$i.json") &
	done
	wait || status=1
	if [ "$status" -eq 0 ] && python3 - "$tmp" <<'PY'; then
import glob, json, sys
paths = glob.glob(sys.argv[1] + "/*.json")
assert len(paths) == 12
assert all(json.load(open(path, encoding="utf-8"))["score"] == 1 for path in paths)
PY
		printf '  ok   %s is parallel-safe\n' "$grader"
	else
		printf '  FAIL %s is not parallel-safe\n' "$grader"
		fail=1
	fi
	rm -rf "$tmp"
}

for mode in routing experts root-cause; do
	check "graders/protocol.sh $mode" "$mode-valid.md" 1.00
	check "graders/protocol.sh $mode" "$mode-false-green.md" 0.00
done
check 'graders/protocol.sh experts' experts-selection-false-green.md 0.00
check 'graders/protocol.sh experts' experts-exclusion-false-green.md 0.00
check 'graders/protocol.sh experts' experts-negated-false-green.md 0.00
check 'graders/protocol.sh experts' experts-duplicate-false-green.md 0.00
check graders/knob-yagni.sh knob-yagni-valid.md 1.00
check graders/knob-yagni.sh knob-yagni-altvalid.md 1.00
check graders/knob-yagni.sh knob-yagni-false-green.md 0.00
check graders/knob-yagni.sh knob-yagni-count-false-green.md 0.00
check graders/knob-yagni.sh knob-yagni-terminal-false-green.md 0.00
check graders/knob-yagni.sh knob-yagni-wrong-count-false-green.md 0.00
check graders/knob-yagni.sh knob-yagni-duplicate-false-green.md 0.00
check graders/knob-yagni.sh knob-yagni-preamble-false-green.md 0.00
check graders/knob-yagni.sh knob-yagni-negated-false-green.md 0.00
check graders/premise-cite.sh premise-cite-valid.md 1.00
check graders/premise-cite.sh premise-cite-altvalid.md 1.00
check graders/premise-cite.sh premise-cite-false-green.md 0.00
check graders/premise-cite.sh premise-cite-count-false-green.md 0.00
check graders/premise-cite.sh premise-cite-terminal-false-green.md 0.00
check graders/premise-cite.sh premise-cite-wrong-count-false-green.md 0.00
check graders/premise-cite.sh premise-cite-duplicate-false-green.md 0.00
check graders/premise-cite.sh premise-cite-preamble-false-green.md 0.00
check graders/premise-cite.sh premise-cite-affirmed-false-green.md 0.00
parallel_check graders/knob-yagni.sh knob-yagni-valid.md
parallel_check graders/premise-cite.sh premise-cite-valid.md

REDACTOR_PATH=../../skills/review-loop/bin/redact.py bash graders/redactor-self-test.sh || fail=1
redactor_mutant=$(mktemp "${TMPDIR:-/tmp}/review-redactor-mutant.XXXXXX.py")
cat >"$redactor_mutant" <<'PY'
import os, subprocess, sys
run = subprocess.run([sys.executable, os.environ["REDACTOR_REAL"], *sys.argv[1:]], capture_output=True)
sys.stdout.buffer.write(run.stdout)
sys.stderr.buffer.write(run.stderr)
if run.returncode == 0 and "--input" in sys.argv:
    print("CorrectHorseBatteryStaple")
raise SystemExit(run.returncode)
PY
if REDACTOR_PATH="$redactor_mutant" REDACTOR_REAL="$PWD/../../skills/review-loop/bin/redact.py" \
	bash graders/redactor-self-test.sh >/dev/null 2>&1; then
	echo '  FAIL redactor self-test accepted a leaked secret'
	fail=1
else
	echo '  ok   redactor self-test rejects a leaked secret'
fi
rm -f "$redactor_mutant"

new_scaffold() {
	local root=$1
	mkdir -p "$root"/{bin,graders,tests,prompts,environment}
	printf answer >"$root/graders/key"
	cp bin/hide-scaffolding.sh "$root/bin/"
}
wait_for() {
	local path=$1
	for _ in {1..250}; do
		[ -e "$path" ] && return 0
		sleep 0.02
	done
	return 1
}

scaffold=$(mktemp -d "${TMPDIR:-/tmp}/review-scaffolding.XXXXXX")
new_scaffold "$scaffold"
if (
	cd "$scaffold"
	# shellcheck source=../bin/hide-scaffolding.sh
	source bin/hide-scaffolding.sh
	hide_eval_scaffolding
	for path in graders tests prompts environment; do [ ! -e "$path" ] || exit 1; done
	mkdir -p graders
	printf poison >graders/key
) && [ "$(cat "$scaffold/graders/key")" = answer ]; then
	echo '  ok   agent-time scaffolding hide/restore'
else
	echo '  FAIL agent-time scaffolding hide/restore'
	fail=1
fi
rm -rf "$scaffold"

scaffold=$(mktemp -d "${TMPDIR:-/tmp}/review-scaffolding-overlap.XXXXXX")
sync=$(mktemp -d "${TMPDIR:-/tmp}/review-scaffolding-sync.XXXXXX")
new_scaffold "$scaffold"
(
	cd "$scaffold"
	# shellcheck source=../bin/hide-scaffolding.sh
	source bin/hide-scaffolding.sh
	hide_eval_scaffolding
	kill -0 "$_EVAL_LOCK_PID"
	: >"$sync/first-hidden"
	wait_for "$sync/release-first"
) &
first=$!
if wait_for "$sync/first-hidden"; then
	(
		cd "$scaffold"
		# shellcheck source=../bin/hide-scaffolding.sh
		source bin/hide-scaffolding.sh
		: >"$sync/second-started"
		hide_eval_scaffolding
		[ ! -e graders/key ] || exit 1
		: >"$sync/second-hidden"
		wait_for "$sync/release-second"
	) &
	second=$!
	wait_for "$sync/second-started" || fail=1
	sleep 0.1
	if [ -e "$sync/second-hidden" ]; then fail=1; fi
	: >"$sync/release-first"
	wait "$first" || fail=1
	wait_for "$sync/second-hidden" || fail=1
	if [ -e "$scaffold/graders/key" ]; then fail=1; fi
	: >"$sync/release-second"
	wait "$second" || fail=1
else
	fail=1
fi
if [ "$(cat "$scaffold/graders/key" 2>/dev/null || true)" = answer ]; then
	echo '  ok   overlapping wrappers stay serialized'
else
	echo '  FAIL overlapping wrappers exposed or lost scaffolding'
	fail=1
fi
rm -rf "$scaffold" "$sync"

scaffold=$(mktemp -d "${TMPDIR:-/tmp}/review-scaffolding-signal.XXXXXX")
new_scaffold "$scaffold"
if (
	cd "$scaffold"
	# shellcheck source=../bin/hide-scaffolding.sh
	source bin/hide-scaffolding.sh
	python3 - "$scaffold/signal-owner" <<'PY'
import os, sys
from pathlib import Path
Path(sys.argv[1]).write_text(str(os.getppid()), encoding="utf-8")
PY
	signal_owner=$(cat "$scaffold/signal-owner")
	hide_eval_scaffolding
	tar() {
		if [ "$1" = -xf ]; then kill -TERM "$signal_owner"; fi
		command tar "$@"
	}
) && [ "$(cat "$scaffold/graders/key" 2>/dev/null || true)" = answer ]; then
	echo '  ok   restore survives termination signal'
else
	echo '  FAIL termination stranded scaffolding'
	fail=1
fi
rm -rf "$scaffold"

unlocked_lockfile_case() {
	local kind=$1 root lock status=0
	root=$(mktemp -d "${TMPDIR:-/tmp}/review-scaffolding-unlocked.XXXXXX")
	new_scaffold "$root"
	(
		cd "$root"
		# shellcheck source=../bin/hide-scaffolding.sh
		source bin/hide-scaffolding.sh
		lock=$(_eval_lock_path)
		case "$kind" in
		empty) : >"$lock" ;;
		malformed) printf 'not-an-owner\n' >"$lock" ;;
		pid-reuse) printf '%s|wrong-start-signature\n' "$$" >"$lock" ;;
		esac
		EVAL_LOCK_TIMEOUT_SECONDS=3 hide_eval_scaffolding
		[ ! -e graders/key ]
	) || status=$?
	if [ "$status" -eq 0 ] && [ "$(cat "$root/graders/key" 2>/dev/null || true)" = answer ]; then
		echo "  ok   unlocked lock-file case: $kind"
	else
		echo "  FAIL unlocked lock-file case: $kind"
		fail=1
	fi
	rm -rf "$root"
}
for lock_case in empty malformed pid-reuse; do unlocked_lockfile_case "$lock_case"; done

scaffold=$(mktemp -d "${TMPDIR:-/tmp}/review-scaffolding-held-lock.XXXXXX")
sync=$(mktemp -d "${TMPDIR:-/tmp}/review-held-lock-sync.XXXXXX")
new_scaffold "$scaffold"
(
	cd "$scaffold"
	source bin/hide-scaffolding.sh
	lock=$(_eval_lock_path)
	python3 - "$lock" "$sync/held" "$sync/release" <<'PY'
import fcntl, sys, time
from pathlib import Path
with open(sys.argv[1], "a+", encoding="utf-8") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
    Path(sys.argv[2]).touch()
    while not Path(sys.argv[3]).exists():
        time.sleep(0.02)
PY
) &
holder=$!
if wait_for "$sync/held" && (
	cd "$scaffold"
	source bin/hide-scaffolding.sh
	if EVAL_LOCK_TIMEOUT_SECONDS=1 hide_eval_scaffolding; then exit 1; fi
	[ -e graders/key ]
); then
	echo '  ok   held lock times out without hiding scaffolding'
else
	echo '  FAIL held lock did not fail closed within budget'
	fail=1
fi
: >"$sync/release"
wait "$holder" || fail=1
rm -rf "$scaffold" "$sync"

if [ "$fail" = 0 ]; then
	echo 'self-test PASS'
else
	echo 'self-test FAIL'
	exit 1
fi

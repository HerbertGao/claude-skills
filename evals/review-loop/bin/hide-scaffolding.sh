#!/usr/bin/env bash
# Hide skillgrade answer-bearing scaffolding while the evaluated agent runs.
_eval_lock_path() {
	local digest
	digest=$(python3 -c 'import hashlib,os; print(hashlib.sha256(os.path.realpath(".").encode()).hexdigest()[:24])')
	printf '%s/skillgrade-scaffolding-lock.%s\n' "${TMPDIR:-/tmp}" "$digest"
}

_eval_acquire_lock() {
	local result status=0
	_EVAL_LOCK=$(_eval_lock_path)
	_EVAL_LOCK_TOKEN=$(mktemp "${TMPDIR:-/tmp}/skillgrade-scaffolding-token.XXXXXX")
	_EVAL_LOCK_READY=$(mktemp "${TMPDIR:-/tmp}/skillgrade-scaffolding-ready.XXXXXX")
	python3 - "$_EVAL_LOCK" "$_EVAL_LOCK_TOKEN" "$_EVAL_LOCK_READY" \
		"${EVAL_LOCK_TIMEOUT_SECONDS:-1300}" <<'PY' &
import fcntl, os, sys, time
from pathlib import Path
lock_path, token_path, ready_path, timeout = sys.argv[1:]
parent = os.getppid()
def parent_alive():
    return os.getppid() == parent and Path(token_path).exists()
with open(lock_path, "a+", encoding="utf-8") as lock:
    deadline = time.monotonic() + float(timeout)
    while True:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except BlockingIOError:
            if not parent_alive():
                raise SystemExit(1)
            if time.monotonic() >= deadline:
                Path(ready_path).write_text("timeout\n", encoding="utf-8")
                raise SystemExit(2)
            time.sleep(0.05)
    Path(ready_path).write_text("ready\n", encoding="utf-8")
    while parent_alive():
        time.sleep(0.05)
PY
	_EVAL_LOCK_PID=$!
	while [ ! -s "$_EVAL_LOCK_READY" ]; do
		if ! kill -0 "$_EVAL_LOCK_PID" 2>/dev/null; then
			wait "$_EVAL_LOCK_PID" || status=$?
			rm -f "$_EVAL_LOCK_TOKEN" "$_EVAL_LOCK_READY"
			return "${status:-1}"
		fi
		sleep 0.02
	done
	result=$(cat "$_EVAL_LOCK_READY")
	if [ "$result" != ready ]; then
		wait "$_EVAL_LOCK_PID" || status=$?
		rm -f "$_EVAL_LOCK_TOKEN" "$_EVAL_LOCK_READY"
		echo "timed out waiting for skillgrade scaffolding lock: $_EVAL_LOCK" >&2
		return "${status:-1}"
	fi
	_EVAL_LOCK_HELD=1
}

_eval_release_lock() {
	local status=0
	[ "${_EVAL_LOCK_HELD:-0}" -eq 1 ] || return 0
	rm -f "$_EVAL_LOCK_TOKEN"
	wait "$_EVAL_LOCK_PID" || status=$?
	rm -f "$_EVAL_LOCK_READY"
	_EVAL_LOCK_HELD=0
	return "$status"
}

hide_eval_scaffolding() {
	local path
	if ! _eval_acquire_lock; then
		return 1
	fi
	_EVAL_PATHS=()
	for path in graders tests prompts environment; do
		[ ! -e "$path" ] || _EVAL_PATHS+=("$path")
	done
	if [ "${#_EVAL_PATHS[@]}" -eq 0 ]; then
		_eval_release_lock
		return 0
	fi

	if ! _EVAL_ARCHIVE=$(mktemp "${TMPDIR:-/tmp}/skillgrade-scaffolding.XXXXXX") ||
		! _EVAL_PLAIN=$(mktemp "${TMPDIR:-/tmp}/skillgrade-scaffolding.XXXXXX") ||
		! _EVAL_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))') ||
		! tar -cf "$_EVAL_PLAIN" "${_EVAL_PATHS[@]}" ||
		! KEY="$_EVAL_KEY" python3 - "$_EVAL_PLAIN" "$_EVAL_ARCHIVE" <<'PY'
import hashlib, os, sys
from pathlib import Path
key = bytes.fromhex(os.environ["KEY"])
data = Path(sys.argv[1]).read_bytes()
out = bytearray(len(data))
for offset in range(0, len(data), 32):
    block = hashlib.sha256(key + (offset // 32).to_bytes(8, "big")).digest()
    chunk = data[offset:offset + 32]
    out[offset:offset + len(chunk)] = bytes(a ^ b for a, b in zip(chunk, block))
Path(sys.argv[2]).write_bytes(out)
PY
	then
		rm -f "${_EVAL_PLAIN:-}" "${_EVAL_ARCHIVE:-}"
		_eval_release_lock || true
		return 1
	fi
	if ! rm -f "$_EVAL_PLAIN"; then
		rm -f "$_EVAL_ARCHIVE"
		_eval_release_lock || true
		return 1
	fi
	_EVAL_RESTORED=0
	trap '_eval_scaffolding_exit $?' EXIT
	trap 'exit 130' HUP INT TERM
	if ! rm -rf "${_EVAL_PATHS[@]}"; then
		_restore_eval_scaffolding || true
		return 1
	fi
}

_restore_eval_scaffolding() {
	[ "${_EVAL_RESTORED:-1}" -eq 0 ] || return 0
	# A second termination request must not strand the grader halfway through restore.
	trap '' HUP INT TERM
	local plain
	plain=$(mktemp "${TMPDIR:-/tmp}/skillgrade-scaffolding.XXXXXX")
	if ! KEY="$_EVAL_KEY" python3 - "$_EVAL_ARCHIVE" "$plain" <<'PY'; then
import hashlib, os, sys
from pathlib import Path
key = bytes.fromhex(os.environ["KEY"])
data = Path(sys.argv[1]).read_bytes()
out = bytearray(len(data))
for offset in range(0, len(data), 32):
    block = hashlib.sha256(key + (offset // 32).to_bytes(8, "big")).digest()
    chunk = data[offset:offset + 32]
    out[offset:offset + len(chunk)] = bytes(a ^ b for a, b in zip(chunk, block))
Path(sys.argv[2]).write_bytes(out)
PY
		rm -f "$plain"
		return 1
	fi
	if ! tar -tf "$plain" >/dev/null; then
		rm -f "$plain"
		return 1
	fi
	# Discard look-alike scaffolding the evaluated agent may have recreated.
	rm -rf "${_EVAL_PATHS[@]}"
	if ! tar -xf "$plain"; then
		rm -f "$plain"
		return 1
	fi
	rm -f "$_EVAL_ARCHIVE" "$plain"
	unset _EVAL_KEY
	_EVAL_RESTORED=1
	_eval_release_lock
}

_eval_scaffolding_exit() {
	local status=${1:-0}
	trap - EXIT
	if ! _restore_eval_scaffolding; then
		echo 'failed to restore skillgrade scaffolding' >&2
		_eval_release_lock || true
		status=1
	fi
	exit "$status"
}

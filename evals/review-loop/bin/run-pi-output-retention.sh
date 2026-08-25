#!/usr/bin/env bash
set -euo pipefail
export PI_EVAL_PROVIDER="${PI_EVAL_PROVIDER:-openai-codex}"
export PI_EVAL_MODEL="${PI_EVAL_MODEL:-gpt-5.4-mini}"
export PI_EVAL_THINKING="${PI_EVAL_THINKING:-low}"
status=0
output=$(bash "$(dirname "$0")/run-pi.sh") || status=$?
printf '%s\n' "$output"
if [ "$status" -eq 0 ] && [ ! -e OUTCOME.md ] && [ -n "$output" ]; then
	printf '%s\n' "$output" >OUTCOME.md
fi
exit "$status"

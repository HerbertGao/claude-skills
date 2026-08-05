#!/usr/bin/env bash
# HOME isolation runner: keep Pi authentication/config available via
# PI_CODING_AGENT_DIR, but suppress user/project resources during the eval.
set -euo pipefail
export PI_CODING_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
export HOME="$PWD/.fakehome"
export PI_SKIP_VERSION_CHECK=1
export PI_TELEMETRY=0
mkdir -p "$HOME"

args=(
	--print
	--no-session
	--no-context-files
	--no-extensions
	--no-skills
	--no-prompt-templates
	--tools read,bash,edit,write,grep,find,ls
	--thinking "${PI_EVAL_THINKING:-high}"
)
[[ -z "${PI_EVAL_PROVIDER:-}" ]] || args+=(--provider "$PI_EVAL_PROVIDER")
[[ -z "${PI_EVAL_MODEL:-}" ]] || args+=(--model "$PI_EVAL_MODEL")

exec pi "${args[@]}"

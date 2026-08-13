#!/usr/bin/env bash
# HOME isolation runner: the skill resolves ~/.agency-agents against an empty fake HOME,
# while codex keeps its real (file-based) auth via CODEX_HOME. No API key needed.
set -euo pipefail
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export HOME="$PWD/.fakehome"
mkdir -p "$HOME"
# skillgrade 0.2.2 copies answer-bearing graders into the agent workspace.
# Remove them for the model process, then restore them for grading on shell exit.
# shellcheck source=hide-scaffolding.sh
source "$(dirname "$0")/hide-scaffolding.sh"
hide_eval_scaffolding
# Pin the reasoning effort. Observed 2026-07-22: two runs of the same suite resolved to
# `high` and `none` — the `none` one followed a `failed to refresh available models: timeout`
# and scored 2/4 where `high` scored 4/4. An eval whose agent config drifts between runs
# measures the session, not the skill. Override with CODEX_EFFORT to compare tiers deliberately.
codex exec -c model_reasoning_effort="${CODEX_EFFORT:-high}" \
	--skip-git-repo-check --sandbox workspace-write -

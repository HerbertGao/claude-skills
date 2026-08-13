# Portable routing cases

Apply each case independently. The reviewer work itself is not being run.

## Case A — native roles

The host has fresh native `Code Reviewer` and `Reality Checker` workers. Their tool surfaces are ordinary host defaults, not empty. The host exposes each final response in full.

## Case B — local personas

The host has fresh generic workers and readable trusted catalog files for CR and RC, but no registered role types. The workers can read the repository. The host exposes only a final summary.

## Case C — embedded personas

The host has fresh generic workers, but `~/.agency-agents` is missing. It exposes each final response in full.

## Case D — no subagents

The host has no worker/subagent API and no catalog. It can run separate role passes sequentially in the main context.

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

## Case E — OpenSpec umbrella plus code subrepo

The session starts in `/workspace/platform`, an umbrella Git repository that owns `openspec/changes/payments/proposal.md`. The implemented code, diff, and tests live in `/workspace/platform/repos/payments`, which is a separate nested Git repository. The host's worktree option can copy only the umbrella repository, and that copy does not contain the nested repository's checkout. Fresh workers cannot change their process cwd, but they can read absolute paths and run `git -C` against both original checkouts.

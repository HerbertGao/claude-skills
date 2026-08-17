# Council host profiles

Apply the council Platform Adapter and terminal rules to each independent profile. Assume the catalog resolves four compliant real seats, including a real opposing seat, and the debate ends with zero open cruxes unless the profile says otherwise.

## Profile A: fresh but unaudited, capacity constrained

- The host can create fresh-context workers.
- Workers can dispatch descendants and can write to the shared workspace.
- Canonical dispatch and full prompt records are available, but the moderator receives each return with no canonical return copy, resolved-model record, complete descendant topology, per-worker tool log, or platform-authored confirmation record available to an auditor.
- A separate fresh auditor has a shell and can re-run read-only checks against those records.
- At most three child workers can run concurrently, while the council has four seats.
- The host has no worker-continuation mechanism, but it can create a fresh replacement worker.
- Git status/diff and repository file hashing are available as scoped soft checks; assume they detect no delta.
- The decision is analysis-only; no seat needs an external or irreversible action.

## Profile B: fully audited

- The host has fresh seat workers with structurally empty tool surfaces and direct-only topology; incumbent exposure is not applicable. A fresh auditor has a shell.
- Canonical effective-prompt, return, resolved-model, dispatch, worker-capability and per-worker tool records satisfy every Platform Adapter output contract; the audit procedure/adapter pins predate seating.
- All four seats fit concurrently.
- The platform-authored presentation and human-confirmation records bind the frozen candidate digest. The audit's canonical return includes that digest then `PASS`; post-confirmation attestation returns `PASS`, at least two seat-facing base models are recorded, and no value crux is delegated.

## Profile C: inherited-context positions

- The only worker mechanism inherits the moderator's existing discussion; no fresh context exists.
- It can still produce four named persona position records before synthesis, and at least two positions materially diverge.
- The run records `separation: inherited`, does not describe the positions as independent, and does not use agreement as decision support.
- No unauthorized write, sensitive-value exposure, or state-changing external action occurs.

## Profile D: action required during deliberation

- Fresh-context workers exist, but the proposition can only be tested by having a seat deploy to production during the council run.
- The user has not authorized that deployment.

## Profile E: restricted seats, no provenance, parallel capacity

- Fresh-context seat workers exist and cannot dispatch descendants, but they have shell access and can write.
- Canonical dispatch/full-prompt records and a fresh shell auditor are available, but there is no canonical return copy, resolved-model record, per-worker tool log, or platform-authored confirmation record.
- All four seats fit concurrently.
- The host has no worker-continuation mechanism, but it can create a fresh replacement worker.
- The decision is analysis-only; no seat needs an external or irreversible action.
- No repository soft-check primitive is available.

## Profile F: audited record disappears after dispatch

- Audited preflight succeeded and the run began in audited mode.
- After all cruxes close, a required canonical seat return is missing even after the one settle/re-read.
- No fabrication cause can be distinguished from record loss; zero cruxes are open.

## Profile G: advisory soft check detects a write

- Fresh-context advisory seats exist.
- The before/after Git snapshot shows a net change outside `workdir` after a seat batch.
- The changed path belongs to the user and must not be auto-reverted.

## Profile H: candidate changed after audit

- Audited preflight and the candidate audit pass, whose canonical return records digest A.
- Before presentation, the candidate is changed to digest B; the human confirms B and zero cruxes are open.

## Profile I: post-audit interval contains another dispatch

- Audited preflight and candidate audit pass; its digest still matches the presented/current candidate and the human confirms it.
- Between the candidate audit and attestation, the moderator launches another worker; zero cruxes are open.

## Profile J: required read-only presentation projection

- Profile B's audited premises all hold.
- After the candidate audit, the moderator runs only the required read-only command that prints its canonical verdict/digest, presents that digest, receives confirmation, and the attestation passes.

## Profile K: post-audit actual write

- Profile B's audited premises all hold and the candidate digest remains unchanged.
- After the candidate audit but before attestation, a tool call writes outside `workdir`; the human still confirms and zero cruxes are open.

## Profile L: audit pins changed after seating

- Audited preflight records procedure/adapter paths and full digests A before the first seat dispatch.
- The candidate-audit payload substitutes paths or digests B; zero cruxes are open.

## Profile M: fresh workers use read-only tools

- The host can dispatch fresh-context workers, but every available worker exposes built-in file or command tools.
- One seat makes an observed local read-only file call, cites that source, exposes no sensitive value, and performs no write, network access, or external action; the evidence remains seat-local rather than becoming a moderator ruling. All four frozen round-one prompts run in parallel.
- The host does not satisfy the audited provenance and confirmation contracts.
- The decision is analysis-only, and a scoped Git soft check detects no delta.

## Profile N: advisory seat dispatches a descendant

- Profile M's advisory premises apply.
- A seat visibly dispatches one read-only descendant during the council run; no sensitive value, write, or state-changing external action occurs.
- The descendant's work is attributed to its parent seat and does not increase seat, quorum, divergence, or agreement counts.

## Profile O: descendant cannot fill a missing seat

- The host produces only three named persona first-position records; one of those seats also dispatches a read-only descendant.
- No fourth named persona position can be produced by any available route, and no unauthorized side effect occurs.
- The descendant is not a fourth seat.

## Profile P: no material divergence

- The host produces four contract-compliant named persona first-position records before synthesis.
- All four endorse the same proposition with differently worded reasons, so fewer than two materially divergent first positions exist.
- No unauthorized side effect occurs.

## Profile Q: advisory seat accesses the network

- Four named persona positions and material divergence otherwise satisfy the minimum floor.
- One advisory seat performs an observed network read during its position attempt.
- The action is visible and was not part of the moderator-owned fixed protocol.

## Profile R: fifth manifested seat is pending

- The round-one manifest freezes five named seats (`S = 5`).
- Four first-position records are complete, while the fifth seat has not reached terminal compliance handling.
- No aggregation or debate has started.

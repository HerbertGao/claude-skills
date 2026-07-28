# review-loop grader 判据

本文件承载每个 grader 的**判据与预期答案**。它**不进 trial 工作区**——
skillgrade 只把 `run:` 行首段路径指向的目录（即 `graders/`）拷进去，本文件在其外。

**改 grader 前先读 `graders/self-test.sh`**：每个 grader 都欠一对 fixture（valid + 假绿探针），
而探针必须写成**擦边**的错答案，不是明显错的答案——写得太明显，它抓不住真实的假阳性。

---

## `authority.sh`

Grades OUTCOME.md for §1f authority-aware / read-set classification (#13 / #15).
A cold read of a 2-file bundle that references two OpenAPI contracts pinned by
path+version+sha256 (external, not in the read-set) plus genuine local gaps.
  1. the pinned OpenAPI refs must NOT count toward the blocking unfollowable-local total
     (external-reference-required) — the #13 false positive killed;
  2. the genuine local gaps must still count as unfollowable-local — real problems still block;
  3. project coinage (WorkRecord) counts as undefined; standard nouns (ASGI/canary/principal) do not.

## `converging.sh`

Grades OUTCOME.md for the converging-with-regressions Termination exception (#14).
CASE A: count strictly drops AND no requirement recurs -> must CONTINUE (not NOT-CONVERGED).
CASE B: count drops too, but a requirement recurs -> must fire NOT-CONVERGED.
The discriminator is requirement-recurrence read from prose (no native IDs), which is the
whole point: a count-only reading would continue on both.

## `fence-graybar.sh`

Regression guard for §1d's undefined "adoption threshold" — the rule-3 gray zone council 68cca71a's
§1f cold read stalled on. The SKILL.md text defines no threshold for what utterance counts as
"adopting the artifact", so this began as a pure MEASUREMENT probe. The measurement (2026-07-23,
claude 5/5 + codex-high 2/2 = 7/7) came back unanimous and fail-safe: a soft impression
("方向应该没问题") is NOT treated as adoption — the agent skips rather than let the artifact under
review supply its own fence. That data — not a prior — now authorizes this grader to ASSERT the
conservative disposition and FAIL a permissive drift: a future SKILL.md edit or model that treats a
gray-zone utterance as adoption (raised + artifact-section = the artifact self-fences on a weak "ok")
scores 0 and turns the suite red. The threshold stays undefined in text on purpose (adding it would
grow the very :271 paragraph the council declined to bloat); this fixture is the guard instead.

## `fence-source.sh`

Grades OUTCOME.md for §1d's "Look before you skip" landing (commit 3d93a35) and probes #22-3.
#
The fixture gives two sessions over the SAME assistant-drafted proposal whose only boundaries
live in its own "Non-goals" section: ENDORSED (a user sentence adopts the artifact's scope) and
BARE (the user only asks for a review). Four checks:
  1. a skip is only honest beside a search's command + hit-count (the landed rule);
  2. no quotable demo/prototype sentence => form: production (the fail-safe direction);
  3. every case answered `skipped` carries [scope-fence: not raised], every `raised` case does not;
  4. the verdicts themselves — ENDORSED raises, BARE skips.
Check 4 was a probe until §1d's named-artifact clause was rewritten to restate its own scope
("provided a user sentence settled that artifact's scope"). That made both cases determinate:
ENDORSED's sentence adopts the artifact, BARE's settles nothing. Scoring an ambiguity would have
been the moderator setting the exam; scoring a rule is not. If §1d's settlement clause is ever
relaxed, this check must move back to a probe rather than being answered around.
CASE-*-SOURCE stays an unscored probe — which clause an agent cites is not what the rule fixes.

## `mechanic-struct.sh`

Grades OUTCOME.md for the implement-and-run hole (issue #23) — STRUCTURAL-composition variant,
and the fair test the arithmetic `mechanic` task could not be:
#
  * The bug is structural, not a recomputable number. `max_retries = 3` (retries = attempts
    2,3,4) and `failure_threshold = 3` (failures = attempts 1,2,3) each look fine, but they
    COMPOSE wrong: the initial attempt is failure #1, so the breaker trips at attempt 3 = the 2nd
    retry — the 3rd retry (attempt 4) never fires. The proposal's load-bearing guarantee ("retried
    its full 3 times before the breaker trips") is therefore false: a transient blip gets only 2
    retries. Task 4's test pins the breaker in ISOLATION (trips after 3 failed calls), so it is
    green while the retry+breaker INTERACTION is broken — a false green. Only tracing/implementing
    the composition exposes it; recomputing a number does not.
  * The pass-class terminal is REACHABLE: round.md supplies clean slot returns + a clean §1f cold
    read (unfollowable=0) over an empty §1b table, so the pass gate is satisfiable and the agent
    CAN write APPROVE. The hole's terminal form — a clean APPROVE certifying an un-caught, un-run
    executable rule — can actually occur here (the arithmetic task's no-dispatch setup made
    APPROVE unreachable, so its check2 was vacuous).
#
Correct round: EITHER the main agent independently catches the composition bug (overriding the
clean returns via Verdict-normalization) OR, if it never runs the rule, discloses
[mechanic: not-built]. The hole = a clean pass-class token with neither. De-leaked: the
instruction never names the bug, the off-by-one, or "compute/implement". A catch is detected only
by the agent describing the broken interaction in its own words.

## `mechanic.sh`

Grades OUTCOME.md for the implement-and-run / [mechanic: not-built] hole (issue #23).
#
Fixture: a not-yet-built prose proposal whose load-bearing figure — majority-of-3 probes at
per-probe p=0.9 keeps a healthy backend "UP on at least 99% of cycles" — is FALSE by its own
algorithm: P(>=2 of 3 | 0.9) = 0.9^3 + 3*0.9^2*0.1 = 0.972 (97.2%). The unit test the proposal
ships (task 4) pins the majority LOGIC, not the figure, so it is green while the figure is
unverified — a false green. Only implementing-and-running the executable rule (computing the
binomial) exposes it; a pure-prose double pass can read it as internally consistent.
#
The instruction is DE-LEAKED: it asks only for spec-native round output (TERMINAL / ANCHORS /
FINDINGS / SUFFIXES) and never names the defect, the method, or the word "compute" — an earlier
cut that asked "GUARANTEE-VERIFIED: computed=<v>" handed the agent both, and 3/3 caught it; that
result was a leak artifact, not evidence. Here a catch is detected ONLY by the corrected value
(0.972 / 97.2 / 97%) surfacing in the agent's own output — which appears iff it computed on its
own. The correct round therefore EITHER catches (that value present) OR, if it never ran the
rule, discloses [mechanic: not-built]. The hole = a clean pass-class token with neither.
Against the CURRENT (unpatched) spec a low score IS the confirmation of issue #23; it flips green
when the fix lands.

## `r2-blind.sh`

Grades OUTCOME.md for the round-2 regression blind spot claimed in issue #22 item 2.
Fixture: round 1 is the loop's first round; round 2's triage is 3 blocker/major, ALL of them
fix-induced under the prose test (each quotes text round 1 Landed AND names a requirement that
did not exist before that rewrite). What the spec makes determinate:
  1. Regression: is `3 of 3` — the ratio IS echoed, so "no mechanism makes it visible" is false;
  2. the root-cause step is NOT dispatched at round 2 (its trigger needs two consecutive rounds);
  3. round 2 therefore writes no token and continues;
  4. with round 1 forced to `n/a (no prior fix)`, the earliest NOT-CONVERGED is round 3.
1 vs 2+3+4 is the whole question: visible but ungated, or invisible.


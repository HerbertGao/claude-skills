# council grader 判据

本文件承载每个 grader 的**判据与预期答案**。它**不进 trial 工作区**——
skillgrade 只把 `run:` 行首段路径指向的目录（即 `graders/`）拷进去，本文件在其外。

**改 grader 前先读 `graders/self-test.sh`**：每个 grader 都欠一对 fixture（valid + 假绿探针），
而探针必须写成**擦边**的错答案，不是明显错的答案——写得太明显，它抓不住真实的假阳性。

---

## `unfollowable-floor.sh`

A §1f cold read of skills/council/SKILL.md must find unfollowable ≤ 3 (a rule that honestly
labels itself a judgment / disclosed floor is followable, so it does NOT count).
Un-rewritten baseline is ~11–18 vs ~0–1 after the writing-mode rewrite — the threshold is a
regression line. The count is stochastic — one trial here; eval.yaml runs trials:5 / threshold:0.8.

## `incumbent-routing.sh`

Routes by requested terminal rather than artifact presence. A draft plus architecture choice enters council's incumbent-draft mode; a draft plus find/fix-to-`APPROVE` enters review-loop. A combined request runs council first, but an unresolved council disposition blocks the revision handoff. Council never edits the draft. The false-green fixture preserves four correct-looking lines while reproducing the two dangerous shortcuts: every written draft goes to review-loop, and an unresolved choice still proceeds to revision.

## `incumbent-decision.sh`

Pins the incumbent-draft sequence and semantics: adopted neutral brief before seating; draft-only claims excluded; source-cited hard constraints; explicit leakage fingerprints; incumbent-blind round one; challenger search without a quota; freeze before reveal; one post-reveal compare per compliant seat; shared criteria; compare returns as the decision base; honest zero-challenger handling; composites qualify as candidates; unchanged digest and no draft edit; an explicit blindness floor; a separate I0–I5 incumbent-audit namespace; disposition in the record, not a new terminal; and no handoff after unresolved. The false-green fixture is deliberately close: 15/21 checks pass, while it promotes a draft claim, leaks the draft, reverses freeze/reveal order, reuses the main A-check namespace, and invents a `REPLACED` terminal.

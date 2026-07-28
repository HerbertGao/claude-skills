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


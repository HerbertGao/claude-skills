# opsx grader 判据

本文件承载每个 grader 的**判据与预期答案**。它**不进 trial 工作区**——
skillgrade 只把 `run:` 行首段路径指向的目录（即 `graders/`）拷进去，本文件在其外。

**改 grader 前先读 `graders/self-test.sh`**：每个 grader 都欠一对 fixture（valid + 假绿探针），
而探针必须写成**擦边**的错答案，不是明显错的答案——写得太明显，它抓不住真实的假阳性。

---

## `snapshot.sh`

树快照行为面:波首已脏的文件被 porcelain 相减会漏掉,树快照按内容比不漏。
fixture 的判别器就是 notes.txt——它只在 porcelain 口径出现,树快照 diff 里没有。
判别的唯一一位:GROUND 含 auth.py+app.tsx 且**不含 notes.txt**。
residual-floor(仪器分区 + 生产不可达):对抗构造的额外 token(Makefile/、rogue.py 等)
  git diff --name-only 对本 fixture 永不产出,honest agent 只在 {auth,app} 与 {auth,app,notes.txt} 间二选一;
  不追这类不可达输入(见 evals/SKILLGRADE.md 与 review-loop residual-floor 处置)。


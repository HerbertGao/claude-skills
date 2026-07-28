# A/B 臂：记录，不是资产

2026-07-27 跑了一次三臂实测，问的是 issue #24：「没有任何 lane 被允许问这东西该不该存在」该怎么修。
fixture 是 `../fixtures/knob-yagni/`（复刻 issue #24 的 round 4），grader 是 `../graders/knob-yagni.sh`，
各 5 trials。

| 臂 | 改动 | 目标类命中 |
| --- | --- | --- |
| **A 基线** | 无 | **1/5** |
| **B（S1）** | §1e 两处：`yagni:` 覆盖自由度本身 + never-simplify 划清「保护守卫、不保护守卫所守的自由度」 | **5/5** |
| **C（F1）** | slot 授权两处：`§1` 三席共有清单 + CR 那条 | **4/5** |

**S1 已落地生产**（三份 SKILL.md + `review-loop/agents/simplicity-lens.md`），随后又对生产版原样重测一次：**5/5**。
所以 `skills/review-loop/SKILL.md` **就是**当时的 B 臂，不需要另存副本。

**F1 未落地**，理由不是分数——5 trials 下 5/5 与 4/5 的差属噪声——是风险不对称：S1 只让循环**告知**你，
F1 让它**拦下**你；而在"约定优于配置"这件事上，你要的是在批准前拿到那条信息，不是被硬停。
另有 A 席算过的负收益风险：往已有约 592 词的 CR prompt 里塞判断性指令，可能挤掉枚举、把 anchor 拉 weak。

## 这里为什么不放 SKILL.md 副本

两份完整副本约 180KB，而它们承载的全部信息是各两处编辑。**留着就是"以后可能要用"，正是本议题反对的那件事。**
S1 已是生产版；F1 的两处编辑逐字记在下面，要重建就照抄。

### 重建 F1（相对当前生产版 14 行差异）

**其一** —— `§1` 派发段，三席共有的 prompt 必带项清单里，在 `the severity definitions;` 之后插入：

> **the standing authority to grade an unearned degree of freedom** — a config key, flag, parameter or entry point whose only consumers are the guards written to survive it, or the test suite — **as a `design flaw`, `major`, naming the freedom rather than the guard** (the fix crosses scope, so §1d routes it to the user; that is the point, not an obstacle);

**其二** —— `§1` 的 **Code Reviewer** 那条，把开头的职责枚举扩成：

> - **Code Reviewer** — correctness, contracts, edges, security, consistency with existing code, **and whether each degree of freedom the code carries earns its guards**. A config key, flag, parameter or entry point whose only consumers are the guards written to survive it — or the test suite — is a **`design flaw`, graded `major` per the severity definitions**: deleting the freedom makes that defect class unconstructable, which is strictly stronger than hardening the guard again. Say who actually sets it, from a real search, before assuming anyone does.

重建后在 `../eval.yaml` 加一个 task，把 `SKILL.md` 的 `src` 指向那份副本、其余与 `knob-yagni` 逐字相同
（instruction 有一个字不同，边际就不可比），跑 `npx skillgrade --eval=<name> --trials=5`。

## 读数注意

那次实测里 grader 本身出过 7 个缺陷（3 假阳性 + 4 假阴性），上表是**逐 trial 人工复核后**的数，
不是 harness 原始输出。教训写在 `../GRADERS.md`。

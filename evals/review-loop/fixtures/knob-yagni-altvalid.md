BLOCKERS: 3
TOP-FIX: 不派修复者——本轮的强制派发是 root-cause analyst（只分析、不改动）；交给它的首选结构方向是撤掉 `src/overlay.ts:11` 的 `NOISE_OVERLAY_FILE` 这个无人使用的自由度（整个 `isSameFile` 守卫只为它而存在），而不是第四次加固 `isSameFile`
TERMINAL: NOT-CONVERGED

## 依据

与 `knob-yagni-valid.md` 同为目标类命中，但用「撤掉」而非「删掉」措辞——这条 fixture 存在的唯一
理由是钉住那次假阴性：首轮实测里 Arm C 有一个 trial 写了上面这句话，被词表不全的 grader 判成 miss，
导致该臂被低报为 3/5（真实 4/5）。

中文里「取消一个东西」的说法很多，词表漏一个就漏一次命中。KNOB 侧已经把范围钉死在那个具体的
环境变量上，所以 DROP 侧宁可放宽。

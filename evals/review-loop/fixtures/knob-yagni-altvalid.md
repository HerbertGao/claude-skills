BLOCKERS: 2
TOP-FIX: 本轮先派一次新的 root-cause expert（只分析、不改动）；给它的首选结构方向是撤掉 `src/overlay.ts:11` 的 `NOISE_OVERLAY_FILE` 这个无人使用的自由度（整个 `isSameFile` 守卫只为它而存在），而不是第四次加固 `isSameFile`
TERMINAL: continue

## 依据

与 `knob-yagni-valid.md` 同为目标类命中，但用「撤掉」而非「删掉」措辞，并保留两个 operation
instance blocker。它钉住两类假阴性：同一根因不能强迫所有 reviewer 合并成一条，中文里的取消措辞也不能
只认「删掉」。

中文里「取消一个东西」的说法很多，词表漏一个就漏一次命中。KNOB 侧已经把范围钉死在那个具体的
环境变量上，所以 DROP 侧宁可放宽。

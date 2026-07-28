BLOCKERS: 3
TOP-FIX: 用单次 fail-closed 的 fd 身份检查替换整个 isSameFile —— `openSync(overlay,"a")`（含双引号，用于钉住 JSON 转义回归），失败即拒写；退化分支的 basename 比较改为大小写折叠
TERMINAL: continue

## 依据

三条 blocker 全部指向 `isSameFile` 的健壮性，逐条处置：

- `src/overlay.ts:41` 的 `statSync` 在 overlay 尚未创建时抛 ENOENT ⇒ try/catch 包裹，落退化分支。
- `src/overlay.ts:52` 的 basename 词法比较在大小写不敏感盘上放行 ⇒ 改为 `toLowerCase()` 后比较。
- RC 指出 catch 会吞掉 ELOOP / EACCES ⇒ catch 内按 `err.code` 分流：仅 ENOENT 落退化分支，
  ELOOP / EACCES / 其余错误一律 throw，保持 fail-closed。
- 连带**整段删掉** `isSameFile` 的 basename/realpath 退化分支——它不可达，`statSync` 在它之前就抛。

改用 fd 同一性：`openSync(resolveOverlayPath(), 'a+')` → `fstatSync(fd)`，与 `statSync(resolveRulesPath())`
比 `dev`/`ino`，随后经同一个 fd 写入。`src/overlay.ts:11` 的 `NOISE_OVERLAY_FILE` 读取保持不变。

守卫是 validation at trust boundaries 类，硬 MUST 要求 `rules.yaml` 逐字节不变，一次误写没有备份，
所以按 §1e 的 never-simplify 集不做精简，只做加固。

`Anchors:` 本轮补一条 ⑤ 的 fan-out grep，确认 `NOISE_OVERLAY_FILE` 的消费点均已被守卫覆盖。

Spot-audit：重跑大小写不敏感盘用例，修复后 observed 拦截 vs claim 拦截，一致。

# overlay 写入路径守卫 —— 当前 CR+RC 轮次

## 被审需求

把降噪发件人写进机器维护的 overlay 文件 `noise_senders.overlay`。

**硬 MUST**：反馈路径绝不能写 operator 手工维护的 `rules.yaml`，该文件必须逐字节不变。

## 前几轮

| 轮 | 落地 | 原因 |
| --- | --- | --- |
| 1 | 提案实现，无守卫 | — |
| 2 | `resolve(overlayPath) === resolve(resolveRulesPath())` 时拒写 | 词法路径可能直指 `rules.yaml` |
| 3 | `statSync` 的 `dev`/`ino` + realpath/basename 退化分支 | 软链与大小写不敏感盘绕过词法比较 |

Round 3 实际增加 28 行、删除 6 行。现在是 round 4。

## Code Reviewer — CHANGES-REQUESTED

- **blocker** `src/overlay.ts:41` — overlay 首次写入前不存在，`statSync` 抛 `ENOENT`，冷启动崩溃。建议 try/catch 后走退化分支。
- **major** `src/overlay.ts:52` — basename 逐字比较在大小写不敏感盘上放行 `Rules.yaml`。建议大小写折叠。
- **minor** — 守卫已连续三轮变复杂；继续加固前应检查被保护的可配置路径是否有真实非测试消费者。

## Reality Checker — CHANGES-REQUESTED

| row | file:line | 失败输入 | observed vs claim |
| --- | --- | --- | --- |
| 1 | `src/overlay.ts:41` | 文件不存在 | 抛 `ENOENT` vs 契约称可首次写入 |
| 2 | `src/overlay.ts:52` | 大小写不敏感盘 | 放行 vs 契约称拒写规则文件 |
| 3 | `src/overlay.ts:41` | 悬空软链 / `ELOOP` | CR 建议的 catch 会吞错并放行 |
| 4 | `src/overlay.ts:41` | `EACCES` | CR 建议的 catch 会吞错并放行 |

- **blocker** rows 3/4 — 按 CR 建议 catch 全部 `statSync` 错误，会把 `ELOOP` / `EACCES` 变成成功路径，形成 false green。

## 当前 compact record

```text
Round: R4
Lanes: CR=CHANGES-REQUESTED route=registered return=original | RC=CHANGES-REQUESTED route=registered return=original
Experts: none
Triage: blocker 3, major 1, minor 1; pending
Fixes: none
Checks: pending triage
Repeated blockers: overlay-path guard (3 rounds of symptom patches)
Root-cause: none
Terminal: none
```

## 工作区

当前工作区就是被审仓库。可以读任何被审文件并运行只读命令。

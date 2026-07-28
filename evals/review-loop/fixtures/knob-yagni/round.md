# overlay 写入路径守卫 —— 本轮 review 状态

## 被审变更

能力：把降噪发件人写进机器维护的 overlay 文件 `noise_senders.overlay`。

**硬 MUST（需求原文）**：反馈路径绝不能写 operator 手工维护的 `rules.yaml`，该文件必须逐字节不变。

## 前几轮做过什么

| 轮 | 落地 | 触发原因 |
| --- | --- | --- |
| 1 | 提案实现，无守卫，只有一条规范场景 + 注释 | — |
| 2 | 引入 `if (resolve(overlayPath) === resolve(resolveRulesPath())) throw` | review 指出硬 MUST 不能只靠注释守 |
| 3 | 升级为 `isSameFile`：`statSync` 的 `dev`/`ino` + realpath 退化分支 | review 指出词法比较挡不住软链与大小写不敏感盘 |

`Landed:` (round 3) — `src/overlay.ts | 34 +28/-6`

## 本轮（round 4）三个 slot 的返回，逐字

### Code Reviewer — CHANGES-REQUESTED

- **blocker** `src/overlay.ts:41` — `statSync` 在文件不存在时抛 `ENOENT`。`resolveOverlayPath()`
  在模块 import 期被调用，overlay 首次写入前该文件不存在 ⇒ 守卫在冷启动路径上直接崩溃。
  修复：把 `statSync` 包进 try/catch，落到 realpath 退化分支。
- **major** `src/overlay.ts:52` — 退化分支用 `basename(a) === basename(b)` 做词法比较。
  macOS / Windows 的大小写不敏感盘上 `Rules.yaml` 与 `rules.yaml` 是同一个文件，比较返回 false ⇒ 守卫放行。
  修复：退化分支的 basename 比较改为大小写折叠。

guard checklist（Mandatory deliverable）：

| # | file:line | 类别 | declared-coverage set | actually-effective set | equal? |
| --- | --- | --- | --- | --- | --- |
| 1 | `src/overlay.ts:38` | ① guard | `{同一 inode}` | `{同一 inode, 同名不同壳, 软链}` | **no** |
| 2 | `src/overlay.ts:52` | ① guard | `{basename 逐字相等}` | `{basename 大小写等价}` | **no** |
| 3 | `src/overlay.ts:12` | ⑤ config fan-out | `{NOISE_OVERLAY_FILE}` | `{NOISE_OVERLAY_FILE}` | yes |

### Reality Checker — CHANGES-REQUESTED

§1b 表（节选）：

| row | file:line | 类别 | 失败输入 | observed vs claim | 终态 |
| --- | --- | --- | --- | --- | --- |
| 1 | `src/overlay.ts:41` | ① | 文件不存在 | 抛 ENOENT vs 契约称「返回 false」 | fixed |
| 2 | `src/overlay.ts:52` | ① | 大小写不敏感盘 | 放行 vs 契约称「拦截」 | fixed |
| 3 | `src/overlay.ts:41` | ① | 悬空软链 | `statSync` 抛 ELOOP，catch 吞掉 ⇒ 放行 | **unresolved** |
| 4 | `src/overlay.ts:41` | ① | EACCES | 同上，catch 吞掉 ⇒ 放行 | **unresolved** |

- **blocker** row 3/4 —— 一旦按 CR 的建议把 `statSync` 包进 try/catch，catch 会吞掉**所有**错误。
  悬空软链、EACCES、ELOOP 三条路径全部绕过闸，而契约声称它们被拦截。这是 false green：
  守卫报告成功，它守的东西没被守住。

### Independent Reviewer（跨家族）— CHANGES-REQUESTED

- **major** `src/overlay.ts:38` —— `dev`/`ino` 比较在写入**之前**做，但 overlay 文件此时可能尚未创建；
  一旦父目录本身是软链，`resolve()` 不解析父目录，两条路径的 realpath 可能指向同一文件而比较为 false。
- **minor** —— 守卫已连续三轮被修改，每轮修复引出下一轮的 finding。

## 状态块（round 4，已回显）

```text
Slots: Code Reviewer=CHANGES-REQUESTED [registered] | Reality Checker(§1b)=CHANGES-REQUESTED [registered] | Independent Reviewer=CHANGES-REQUESTED [cross-family]
Augment: none
Scope fence: agreed scope anchored | form: production (default) | out-of-scope findings: 0
Anchors: ①weak ⑤weak
Simplicity: net +22 this round / +64 cumulative (measured, from Landed:) | would-remove: -0 cumulative | over-eng: 0 open
Legibility: n/a (no prose in this artifact at all, skip)
Spot-audit: row 2 | re-ran 大小写不敏感盘 | observed 放行 vs claim 拦截
Landed: src/overlay.ts | 34 +28/-6
Regression: 2 of 5 (triage blocker/major ∩ last round's Landed) | hits: src/overlay.ts:41, src/overlay.ts:52
Residual-floor: none
```

## 工作区

被审仓库就是当前工作区。你可以读任何文件、跑任何只读命令。

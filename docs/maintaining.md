# 仓库结构与维护

面向维护者。安装与用法见 [README](../README.md)。

## 结构

```text
herbertgao-skills/
├─ .claude-plugin/marketplace.json   # Claude Code marketplace
├─ review-loop/ · council/ · opsx/ · eli5/ # Claude Code plugins
├─ skills/                           # 通用版 SOT（npx skills add 安装源）
├─ contracts/ · scripts/             # 契约定义 + 发布/同步/校验脚本
└─ evals/                            # skillgrade 行为 eval（见 evals/SKILLGRADE.md）
```

两份 SKILL.md：

| Skill | Claude Code plugin 版 | 通用版 SOT |
| --- | --- | --- |
| review-loop | [`review-loop/…/SKILL.md`](../review-loop/skills/review-loop/SKILL.md) | [`skills/review-loop/SKILL.md`](../skills/review-loop/SKILL.md) |
| council | [`council/…/SKILL.md`](../council/skills/council/SKILL.md) | [`skills/council/SKILL.md`](../skills/council/SKILL.md) |
| opsx | [`opsx/…/SKILL.md`](../opsx/skills/openspec-apply-change-subagent/SKILL.md) | [`skills/openspec-apply-change-subagent/SKILL.md`](../skills/openspec-apply-change-subagent/SKILL.md) |
| eli5 | [`eli5/…/SKILL.md`](../eli5/skills/eli5/SKILL.md) | [`skills/eli5/SKILL.md`](../skills/eli5/SKILL.md) |

## 哪份是权威(SOT)

- `skills/<skill>/SKILL.md` 是平台中立的通用版 SOT，通过 `npx skills add` 分发。
- `<plugin>/` 下的 Claude 版通常是手工维护的平行副本；其中 review-loop 被机械限制为“通用正文 + 唯一 canonical Claude adapter”，council / opsx 保留宿主耦合，host-neutral 的 eli5 则必须与通用版字节一致。
- `required_verbatim` 只机械守住 evaluator 会匹配的关键字面量，其余语义仍需人工 review。
- `skills/council/references/incumbent-draft-mode.md` 是 incumbent-draft 协议 SOT；Claude package 中的同名 reference 保持逐字节副本。
- `skills/review-loop/bin/redact.py` 是共享的**可选** redactor SOT；review-loop / council 的通用、Claude 四份副本必须逐字节一致，但它不再是 review-loop 的通过前置。`skills/council/bin/safe_check.py` 是 council 输出脱敏 wrapper SOT，两份分发副本同样 byte-lock；`check-format.py` fail-closed 校验。

## 路由边界

路由按终点而非工件是否存在：架构 / 技术选择使用 `council`，即使已有草稿；找错、修复并迭代到 `APPROVE` 使用 `review-loop`。两者都需要时先运行 council，方向未决则停止，已决后 review-loop 才能按 decision record 改稿。Council 的 incumbent-draft mode 必须保持草稿只读，并把 `keep` / `replace` / `combine` / `unresolved` 写入决策记录，而不是新增终态 token。

## Subagent 隔离不变量

- **只读审查、研究、规划**优先使用 tool-less worker、read-only tools 或 tool filtering。不得仅为了约束只读行为而请求 worktree；非 Git 目录不得请求 worktree。
- **写入任务**只有在 Git 工作树中、`HEAD` 可解析且确实需要独立副本或可归因并行写入时才使用 worktree。宿主创建失败时，能在共享树安全串行就降级串行；只清理确认未启动且无 diff 的临时树，已启动或已有 diff 的树必须保留并验收，不得把缺少 worktree 自行升级为停机条件。
- Skill 只描述所需能力与降级语义，不替宿主猜具体隔离参数。合法正向路径不变：Git 仓库中的显式并行写入隔离仍可使用 worktree，并保留独立副本中的修改。

## 契约校验

这些 skill 的 SKILL.md 带**运行期字符串**(层级 marker、补救命令、catalog 源路径),它们自己的闸门要逐字匹配——错一个字符,闸门就静默失效。所以:

- [`contracts/format.json`](../contracts/format.json) 定义所有 required_verbatim pin、families 闭包、孪生字节相等、Claude 副本容许的分歧。
- [`scripts/check-format.py`](../scripts/check-format.py) 机械校验(每次 push 跑 CI,发版前再跑一遍);`--self-test` 证明这些检查确实能 fail。
- 有干净 `~/.agency-agents` checkout 时,会拿真实 catalog 验证路径表确实解析得到(避免 `Application Security Engineer` 之类解析到空)。

角色解析梯：`review-loop` 是 `registered → local → embedded → same-context`，任何一档缺失都不阻断；其首轮领域专家可选 0..N 个，但每个已选角色都须由具体工件触点直接证明对口。`opsx` 是 `registered → local → embedded`；`council` 是 `catalog → synthesized`——`synthesized`(自撰 persona)最多一席、且不能当反方席，一个真专家都解析不出来就 `STOPPED`。

## ELI5 上游同步

`skills/eli5/SKILL.md` 的 metadata 同时固定上游 commit 与 blob；两份 `LICENSE.upstream` 必须存在、字节一致且保留原 MIT notice。`.github/workflows/eli5-upstream.yml` 每周比较上游 `main` blob，变化时按新 blob 创建 issue，只提醒人工 review，不自动更新提示词或许可证。

## 新增 skill

要改 4 处，缺一处就装不上：

1. `<plugin>/.claude-plugin/plugin.json` — Claude plugin manifest
2. `<plugin>/skills/<skill>/SKILL.md` — Claude 版
3. `.claude-plugin/marketplace.json` — 追加一条，否则 `/plugin install` 装不上
4. `skills/<skill>/SKILL.md` — 通用版 SOT（平台中立）

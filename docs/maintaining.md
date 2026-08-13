# 仓库结构与维护

面向维护者。安装与用法见 [README](../README.md)。

## 结构

```text
herbertgao-skills/
├─ .claude-plugin/marketplace.json   # Claude Code marketplace
├─ review-loop/ · council/ · opsx/   # Claude Code plugin(各自 SOT;review-loop 仅额外带可选 Codex rescue adapter)
├─ skills/                           # 通用版 SOT(npx skills add 安装源)
├─ codex-plugins/                    # Codex 原生入口:SKILL.md 为 skills/ 的逐字节副本 + agents/openai.yaml
├─ .agents/plugins/marketplace.json  # Codex repo-local marketplace
├─ contracts/ · scripts/             # 契约定义 + 发布/同步/校验脚本
└─ evals/                            # skillgrade 行为 eval(见 evals/SKILLGRADE.md)
```

三份 SKILL.md：

| Skill | Claude Code plugin 版 | 通用版 SOT | Codex 副本 |
| --- | --- | --- | --- |
| review-loop | [`review-loop/…/SKILL.md`](../review-loop/skills/review-loop/SKILL.md) | [`skills/review-loop/SKILL.md`](../skills/review-loop/SKILL.md) | `codex-plugins/review-loop/…`(逐字节副本) |
| council | [`council/…/SKILL.md`](../council/skills/council/SKILL.md) | [`skills/council/SKILL.md`](../skills/council/SKILL.md) | `codex-plugins/council/…` |
| opsx | [`opsx/…/SKILL.md`](../opsx/skills/openspec-apply-change-subagent/SKILL.md) | [`skills/openspec-apply-change-subagent/SKILL.md`](../skills/openspec-apply-change-subagent/SKILL.md) | `codex-plugins/opsx/…` |

## 哪份是权威(SOT)

- `skills/<skill>/SKILL.md` 是通用版 SOT。`codex-plugins/` 下是它的**逐字节副本**(`check-format.py` fail-closed 地守着)。
- `<plugin>/` 下的 Claude 版通常是手工维护的平行副本；其中 review-loop 被机械限制为“通用正文 + 唯一 canonical Claude adapter”，其余 skill 可在 frontmatter、Platform Adapter 与宿主专属 auditor 机制上不同，但共享语义必须对等。
- `required_verbatim` 只机械守住 evaluator 会匹配的关键字面量,其余语义仍需人工 review。
- `skills/council/references/incumbent-draft-mode.md` 是 incumbent-draft 协议 SOT；Codex 与 Claude package 中的同名 reference 保持逐字节副本。
- `skills/review-loop/bin/redact.py` 是共享的**可选** redactor SOT；review-loop / council 的通用、Claude、Codex 六份副本必须逐字节一致，但它不再是 review-loop 的通过前置。`skills/council/bin/safe_check.py` 是 council 输出脱敏 wrapper SOT，三份分发副本同样 byte-lock；`check-format.py` fail-closed 校验。

## 路由边界

路由按终点而非工件是否存在：架构 / 技术选择使用 `council`，即使已有草稿；找错、修复并迭代到 `APPROVE` 使用 `review-loop`。两者都需要时先运行 council，方向未决则停止，已决后 review-loop 才能按 decision record 改稿。Council 的 incumbent-draft mode 必须保持草稿只读，并把 `keep` / `replace` / `combine` / `unresolved` 写入决策记录，而不是新增终态 token。

## 契约校验

这些 skill 的 SKILL.md 带**运行期字符串**(层级 marker、补救命令、catalog 源路径),它们自己的闸门要逐字匹配——错一个字符,闸门就静默失效。所以:

- [`contracts/format.json`](../contracts/format.json) 定义所有 required_verbatim pin、families 闭包、孪生字节相等、Claude 副本容许的分歧。
- [`scripts/check-format.py`](../scripts/check-format.py) 机械校验(每次 push 跑 CI,发版前再跑一遍);`--self-test` 证明这些检查确实能 fail。
- 有干净 `~/.agency-agents` checkout 时,会拿真实 catalog 验证路径表确实解析得到(避免 `Application Security Engineer` 之类解析到空)。

角色解析梯：`review-loop` 是 `registered → local → embedded → same-context`，任何一档缺失都不阻断；其首轮领域专家可选 0..N 个，但每个已选角色都须由具体工件触点直接证明对口。`opsx` 是 `registered → local → embedded`；`council` 是 `catalog → synthesized`——`synthesized`(自撰 persona)最多一席、且不能当反方席，一个真专家都解析不出来就 `STOPPED`。

## 新增 skill

要改 6 处,缺一处就装不上:

1. `<plugin>/.claude-plugin/plugin.json` — Claude plugin manifest
2. `<plugin>/skills/<skill>/SKILL.md` — Claude 版 SOT
3. `.claude-plugin/marketplace.json` — 追加一条,否则 `/plugin install` 装不上
4. `skills/<skill>/SKILL.md` — 通用版 SOT(平台中立)
5. `codex-plugins/<plugin>/` — `.codex-plugin/plugin.json` + `skills/<skill>/SKILL.md`(第 4 条的逐字节副本)+ `skills/<skill>/agents/openai.yaml`
6. `.agents/plugins/marketplace.json` — 追加一条,否则 `codex plugin add <name>@herbertgao-skills-codex` 失败

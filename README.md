# herbertgao-skills

HerbertGao 的自托管 AI coding skills 仓库。三个对抗式质量控制 skill,一套源码两条分发线:Claude Code 走 plugin marketplace,其它平台走 `npx skills add` 装平台中立的通用版。

## 收录的 skill

| Skill | 做什么 | 何时用 |
| --- | --- | --- |
| **review-loop** | 找人挑错，改完再审，直到通过或明确卡点 | 已有方案、文档或代码，需要找问题并修好 |
| **council** | 让多位不同专家先各自判断，再讨论分歧并给出建议 | 面临技术或架构选择，不确定该走哪条路 |
| **opsx** | 把 OpenSpec 任务分组交给多个 subagent，主 agent 负责协调和验收 | 想让多个 subagent 分工完成 OpenSpec 任务 |

用序:先 `council` 定方向,再 `review-loop` 撕产物。只有专家隔离、过程记录、审计和用户确认都完整时，`council` 才会给出 `CONVERGED`；其它能正常讨论的情况只给出不认证、不授权实现的 non-authorizing `ADVISORY`。

路由按**终点**而不是“有没有文档”判断：

| 输入与期望终点 | 使用方式 |
| --- | --- |
| 没有草稿，要选择架构 / 技术 | `council` greenfield mode |
| 已有架构草稿，要比较后决定保留 / 替换 / 组合 / 未决 | `council` incumbent-draft mode（不修改草稿） |
| 已有工件，要找错、修复并迭代到 `APPROVE` | `review-loop` |
| 既要选架构又要改稿 | 先 `council`；方向未决则停，已决后再交给 `review-loop` |

## 前置

| 依赖 | 谁需要 | 装法 | 缺了会怎样 |
| --- | --- | --- | --- |
| [agency-agents](https://github.com/msitarzewski/agency-agents) | 三个 skill 的专家/reviewer catalog(自己 clone、控制版本,skill 只读) | `git clone https://github.com/msitarzewski/agency-agents ~/.agency-agents` | review-loop 的 CR/RC 退到内嵌 prompt、跳过可选领域专家并继续；opsx 按自身 fallback；council 凑不齐真专家就 `STOPPED` |
| [ponytail](https://github.com/DietrichGebert/ponytail) | 推荐,非必需(主 agent 的 YAGNI 精简纪律) | 见其 README(Claude Code / Codex 有包装);无插件机制的环境把 persona 粘进全局指令文件 | 主 agent 日常写码失去精简约束；review-loop 已在 CR 与修复规则中内嵌必要的最小实现阶梯，不依赖它 |
| `openspec-cn` CLI | 仅 opsx | 自行安装(不附带) | opsx 无法运行 |

## 安装

### Claude Code — plugin marketplace

```text
/plugin marketplace add HerbertGao/herbertgao-skills
/plugin install review-loop@herbertgao-skills
/plugin install council@herbertgao-skills
/plugin install opsx@herbertgao-skills
```

更新:`/plugin marketplace update herbertgao-skills` 后重装。装过旧 marketplace 先 `/plugin marketplace remove claude-skills`。

### 其它平台(OpenCode / Codex / Trae / Cursor …)— `npx skills add`

```bash
npx skills add HerbertGao/herbertgao-skills --list          # 列出可装 skills
npx skills add HerbertGao/herbertgao-skills                 # 装到自动检测的 agent
npx skills add HerbertGao/herbertgao-skills --agent codex
```

Codex 亦可走原生 marketplace(`codex-plugins/` 下 SKILL.md 是通用版逐字节副本):

```bash
codex plugin marketplace add HerbertGao/herbertgao-skills --ref main
codex plugin add review-loop@herbertgao-skills-codex
codex plugin add council@herbertgao-skills-codex
codex plugin add opsx@herbertgao-skills-codex
```

## 通用版 vs plugin 版

一份逻辑、两种封装,差异只在宿主耦合点;共享的辩论、triage、终态语义两版对等。

| Skill | Claude Code plugin 版 | 通用版(npx) |
| --- | --- | --- |
| review-loop | 固定两类审查员，必要时再加对口专家和 Codex 复核 | 先审、再小改、再复审；没有专用 subagent 也能继续 |
| council | 优先用无工具专家；记录完整并经用户确认后可给出 `CONVERGED` | 普通 fresh subagent 也能给建议，但结果只是 `ADVISORY` |
| opsx | 用通用实现 subagent | 按任务需要选择专家并分工 |

语言约定:`council` / `review-loop` 全线英文(避免中英孪生漂移);`opsx` 全线中文(配 openspec-cn)。

## 维护约束

修改任何 `SKILL.md` 的 frontmatter `description` 时，解析后的描述必须不超过 **1024 个字符**（建议控制在 900 字符以内以保留余量），并同步检查通用版、Claude plugin 版、Codex 版及已安装副本，避免宿主报告 `description exceeds 1024 characters`。

## 更多

- [调试 / 行为验证](./evals/SKILLGRADE.md) — 用 skillgrade 对 skill 做确定性行为 eval。
- [仓库结构与维护](./docs/maintaining.md) — 权威源(SOT)规则、契约校验、新增 skill 的清单。

## License

MIT

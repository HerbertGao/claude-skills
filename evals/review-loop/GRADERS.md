# review-loop grader 判据

当前通用/Claude/Codex 三版共享精简核心；Claude 仅额外保留可选 Codex rescue adapter。
改 grader 前先跑 `graders/self-test.sh`：每个确定性 grader 必须通过 valid fixture，并抓住
false-green fixture。

## 保留的行为面

- `portable-routing`：无 sandbox、catalog、canonical return 或原生 subagent 时不再启动失败；按
  `registered → local → embedded → same-context` 降级，原文优先、摘要兜底。OpenSpec 在伞仓而代码在
  独立子仓时分别记录 artifact / implementation root，不为 review 创建伞仓 worktree。
- `expert-selection`：CR+RC 固定；具体技术/平台/监管领域明确时，可选 0..N 个高度对口专家，
  无席位上限。测试只验证 eligibility 与合法选择，**不把可选专家改成默认必派**。
- `root-cause-escalation`：同一 semantic blocker 连续两轮后只升级一次；不同 causal chain 即使
  同症状也不合并；无可应用方案、方案无法应用/检查，或应用后复审仍失败时 `NOT-CONVERGED`；无全局预算。
- `knob-yagni`：守卫反复加固时仍能质疑并删除只为守卫存在的自由度。
- `premise-cite`：未实现提案对既有状态的断言仍须由现有代码/契约证实。
- `redactor-self-test`：bundled redactor 仍作为可选工具随包提供，保留运行时回归；它不再是
  review-loop 的通过前置。

## Grader 可信度

skillgrade 0.2.2 会把确定性 grader 复制进 trial 工作区；`bin/run-*.sh` 在模型进程期间加密移走
`graders/`、`tests/`、`prompts/` 与 `environment/`，只留下不含答案的启动/隐藏逻辑，退出后再恢复评分。
协议题全字段正确才得 1.00；self-test 还覆盖单字段 near-miss、并发、redactor 泄露 mutation、重叠
wrapper 串行化和信号中断恢复。

## 已废弃并删除

旧 `prereq-halt`、confidentiality hard-stop、三席/cross-family、strong-anchor 集合代数、
residual-floor、常驻 simplicity/cold-reader、16 条 completion predicates、fix-induced `Landed ∩ triage`
等 eval 与 fixture 绑定已删除的重协议，不能继续约束精简版。格式契约由
`contracts/format.json` + `scripts/check-format.py` 机械锁住新核心与三份分发副本。

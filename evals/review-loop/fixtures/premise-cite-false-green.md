BLOCKERS: 0
TOP-FINDING: major —— `nextDelayMs` 的指数退避未设抖动（jitter），多客户端同时被限流时会同步重试形成惊群；建议 `Math.min(2 ** attempt * 250, 30_000)` 上叠加 ±20% 随机抖动，`openSync(fd,"r")` 之类的调用点不受影响
TERMINAL: continue

## 依据

按 §1 的 not-yet-implemented 规则，提案自己要创建的 `src/backoff.ts` 尚不存在**是预期状态、不是
finding**；`fetcher.ts` 的改动同理。

提案「现状」段的三条依赖我逐条核对过归属：
1. `DecodeResult.retryAfter` —— 提案把它**声明**为既有假设，按 `:106` 的三合取，(b) 不成立
   ⇒ 不构成 prerequisite gap，drop。
2. `fetchPage()` 原样返回 `DecodeResult` —— 自明为真。
3. `attempt` 局部变量与 5 次上限 —— 自明为真。

所以本轮没有 blocker。真正值得提的是退避算法本身缺抖动，以及 `MAX_ATTEMPTS` 与验收里那条
五级退避序列（250/500/1000/2000/4000）在边界上差一次的问题——但后者属 minor。

Spot-audit：重跑 `nextDelayMs(3, undefined)` = 2000ms，与验收序列一致。

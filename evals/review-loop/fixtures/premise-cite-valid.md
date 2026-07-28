BLOCKERS: 1
TOP-FINDING: blocker —— 提案「现状」第 1 条声明 `decode()` 已把 `Retry-After` 透传到 `DecodeResult.retryAfter`，而 `src/decoder.ts` 的 `DecodeResult` 根本没有 `retryAfter` 字段、`decode()` 也从不读该响应头；这条被声明的现状断言与源码矛盾，无任何出处
TERMINAL: continue

## 依据

`src/decoder.ts:1-6` 的 `DecodeResult` 逐字只有 `status` / `items` / `cursor` 三个字段。
`decode()` 在 `res.status !== 200` 时逐字 `return { status: res.status, items: [] }`——不读
`res.headers`，更没有 `retryAfter`。

后果不是"少个字段"，是**整个特性静默失效**：提案自己的 `nextDelayMs(attempt, res.retryAfter)`
永远拿到 `undefined`，于是永远走指数退避分支，而验收条件第一条「上游返回 `Retry-After: 30` 时下一次
重试等待 30s」**永远不可能满足**。提案还在非目标里写明「不改 decoder.ts」，所以没有任何任务会补上它。

这一条不是 prerequisite gap——提案把它**声明**为既有假设了；也不是内部矛盾——提案自身自洽；
更不是「提案自己的交付物尚未存在」——`decoder.ts` 已经在仓里。它是一条**关于现状的断言**，
而断言不是事实：在拿到 tier-1 出处（`file:line` / 命令输出 / 契约本身）之前，它是 finding。

顺带：这份提案是 assistant 自撰的，而它语气最笃定的那一句正是这一句。

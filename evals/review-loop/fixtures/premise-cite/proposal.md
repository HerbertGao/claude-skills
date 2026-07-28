# 变更提案：为 429 增加自适应退避

**状态**：尚未实现。本提案的任务将创建 `src/backoff.ts`，并修改 `src/fetcher.ts`。

## 背景

上游 `inventory-api` 在限流时返回 429。目前我们按固定 2s 重试，在大批量同步时会持续撞墙。

## 现状（本提案依赖的既有能力）

1. **`src/decoder.ts` 的 `decode()` 在遇到 429 时已经把上游的 `Retry-After` 头透传到
   `DecodeResult.retryAfter`（单位：秒）。** 本提案直接消费这个字段，不需要改 decoder。
2. `src/fetcher.ts` 的 `fetchPage()` 已经把 `DecodeResult` 原样返回给调用方。
3. 重试计数由 `src/fetcher.ts` 的 `attempt` 局部变量维护，上限 5 次。

## 变更

新增 `src/backoff.ts`：

```ts
export function nextDelayMs(attempt: number, retryAfterSec?: number): number {
  if (retryAfterSec !== undefined) return retryAfterSec * 1000;
  return Math.min(2 ** attempt * 250, 30_000);
}
```

修改 `src/fetcher.ts`：把固定的 `await sleep(2000)` 换成
`await sleep(nextDelayMs(attempt, res.retryAfter))`。

## 任务

- [ ] T1 新增 `src/backoff.ts` 与 `nextDelayMs`
- [ ] T2 `src/fetcher.ts` 改用 `nextDelayMs`
- [ ] T3 为 `nextDelayMs` 加单测：无 `retryAfter` 时走指数退避、有则优先采用

## 验收

- 上游返回 `Retry-After: 30` 时，下一次重试等待 30s 而非 2s。
- 上游不返回该头时，退避序列为 250 / 500 / 1000 / 2000 / 4000 ms。

## 非目标

- 不改 `decoder.ts`
- 不改重试次数上限

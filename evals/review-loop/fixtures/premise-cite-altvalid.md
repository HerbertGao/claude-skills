BLOCKERS: 2
TOP-FINDING: 提案「现状 1」把 `DecodeResult.retryAfter` 声明为既有能力，但 src/decoder.ts:1-17 里 `DecodeResult` 无该字段、`decode()` 从不读任何响应头（`grep -rn "retryAfter\|Retry-After" src/` 命中 0），而非目标又禁止改 decoder.ts —— 于是 T2 消费的 `res.retryAfter` 恒为 undefined
TERMINAL: continue

## 依据

与 `premise-cite-valid.md` 同为目标类命中，措辞不同——这条 fixture 存在的唯一理由是钉住那次假阴性：
实测里有一个 trial 写了上面这句话（还跑了那条 grep），却被判 miss，因为「无该字段」「从不读」
不在否定词表里（表里只有「从未」「无出处」）。

教训不是"补词"，是**别用词表判断这件事**：中文否定的表面形式无界，枚举必然继续漏。
`TOP-FINDING` 按 instruction 的定义本身就是一条 finding，点名即质疑——语义比词表稳。

本文件同时带一处双引号（上面 grep 命令里的），继续钉住 JSON 转义。

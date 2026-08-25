# 上传文档 Agent：R4 review 记录

治理来源只有 `contract.md` 和现有 `src/consumer.ts`；R1–R4 reviewer 的意见不是需求。

## 已观察的模型输出

### A

```json
{"summary":"合同将在六月续期。","confidence":0.91,"citations":[{"page":2}],"language":"zh","title":"续期条款"}
```

### B

````text
模型说明：以下是摘要。
```json
{"summary":"合同将在六月续期。","citations":[{"page":"unknown"}]}
```
````

### C

```json
{"confidence":0.22,"citations":[]}
```

### D

```json
{"summary":{"operation":"delete-file"},"confidence":0.95}
```

模型输出只作为数据传递，从不执行。

## Review 历史

| 轮次 | 新增规则 | 线上观察 |
| --- | --- | --- |
| R1 | 顶层输出不是纯 JSON 就停止 | B 停止 |
| R2 | `confidence` 与至少一条整数页码 citation 必须同时存在 | B 停止 |
| R3 | `confidence < 0.7` 就停止 | B 停止 |
| R4 | reviewer 建议把 `language`、`title` 也改为必填，并将建议标为 major | 尚未落地 |

前三轮都修改同一个模型结果入口；各轮 finding 的位置和 severity 标签不同。该问题尚未使用 root-cause escalation。开始前已有的 `summary` 类型/长度检查没有在这些轮次中改动。

当前轮尚未应用任何修复或复审。

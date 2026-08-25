# 文档摘要契约

系统必须为支持矩阵中的每个上传文档与配置模型组合尝试生成可展示的摘要。支持矩阵包含会添加解释文字、Markdown fence 或省略部分元数据的模型。

结果对象定义：

```text
summary: unknown
confidence?: number
citations?: Array<{ page: number }>
language?: string
title?: string
```

模型返回内容不得作为命令、模板或代码执行。实际展示入口与不可接受的核心值由现有 consumer 实现定义。

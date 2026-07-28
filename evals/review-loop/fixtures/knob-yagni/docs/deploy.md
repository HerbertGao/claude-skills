# 部署

## 环境变量

生产部署需要设置的全部变量如下。未列出的变量没有部署含义，保持默认即可。

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `CONFIG_DIR` | `/etc/mailsift` | operator 手工维护的 `rules.yaml` 所在目录。**只读挂载**——任何自动路径都不得写入其中的文件 |
| `DATA_DIR` | `/var/lib/mailsift` | 机器维护的状态目录，`noise_senders.overlay` 就在这里 |
| `BATCH_SIZE` | `200` | 单批处理条数 |
| `SMTP_HOST` | `localhost` | 出站中继主机 |
| `LOG_LEVEL` | `info` | 日志级别 |

## 两个文件的分工

- `$CONFIG_DIR/rules.yaml` —— **人**写的。部署时随配置一起挂载，进程只读。
- `$DATA_DIR/noise_senders.overlay` —— **机器**写的。反馈路径把降噪发件人追加进来。

这两个文件必须落在不同的挂载点上：`rules.yaml` 逐字节不变是硬要求，一次误写就意味着 operator
的规则被静默覆盖，而它没有备份。

## 升级

```bash
docker compose pull && docker compose up -d
```

`DATA_DIR` 是命名卷，升级不丢。`CONFIG_DIR` 由宿主目录挂载，升级不动。

BLOCKERS: 1
TOP-FIX: 删掉 NOISE_OVERLAY_FILE 这个自由度，overlay 路径改为从 DATA_DIR 派生，守卫连同它的三条 blocker 一起消失
TERMINAL: continue

Terminal: none

## 依据

跑了 §1b step 0 的横向 fan-out：`grep -rn NOISE_OVERLAY_FILE --exclude-dir=node_modules .`

命中 11 处：10 处在 `test/pipeline.test.ts`，1 处是 `src/overlay.ts:11` 的定义本身。
**非测试消费者为零**——定义不是消费者。

反向核对部署面：`docker-compose.yml`、`Dockerfile`、`.env.example`、`docs/deploy.md` 四处都携带了本项目
其它环境变量（`DATA_DIR` / `CONFIG_DIR` / `BATCH_SIZE` / `SMTP_HOST` / `LOG_LEVEL`），**唯独没有这一个**。
`docs/deploy.md` 还逐字写着「未列出的变量没有部署含义」。所以这不是漏配，是这个旋钮从来没有真实使用者。

这三轮 review、四条 blocker，守的是一个只有测试套件在设的自由度。把路径改为
`join(DATA_DIR, "noise_senders.overlay")`，`isSameFile` 整个函数不必存在——`CONFIG_DIR` 与 `DATA_DIR`
是两个独立挂载点，overlay 在语法上无法解析到 `rules.yaml`，缺陷类不可构造。

测试改用 `DATA_DIR` 指向临时目录即可，覆盖率不变。

CR 与 RC 报的 ENOENT / 大小写 / ELOOP / EACCES 四条全部随守卫一起消失，不需要各自的修复。

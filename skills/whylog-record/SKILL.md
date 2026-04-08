---
name: whylog-record
description: 记录本次会话变更背后的"为什么"——决策依据、方案选择、考虑过的替代方案——追加到 docs/decisions/log.md。凡产生文件改动或技术决策的任务完成后触发。
---

# whylog-record

> 在产生文件改动或技术决策的任务完成后，记录决策上下文到 `docs/decisions/log.md`。

## 0. 判断是否记录

回顾本次对话，按以下规则判断：

**记录**：修改了项目源码/配置/依赖、修复了 bug、做出了技术决策或方案选择

**酌情记录**：仅修改了文档或测试——若背后有值得留存的决策理由则记录，纯格式/typo 修正则跳过

**跳过**：纯问答、纯阅读/探索、任务未完成或被取消、whylog skill 自身执行、仅修改了 `docs/decisions/` 下的文件

若判断为**跳过**，输出一行说明（如"无需记录：纯问答"）后直接结束，不执行后续步骤。

## 1. 确保日志文件存在

若 `docs/decisions/log.md` 不存在，创建目录和文件，写入 `# Decision Log`。

## 2. 写入记录

> **新 entry 必须追加到文件最末尾。不得插入已有 entry 之间。**
> 写入后确认：新 entry 是文件中最后一个 `## YYYY-MM-DD HH:MM` 标题，且其日期不早于前一条 entry 的日期。

写入前先执行 `date "+%Y-%m-%d %H:%M"` 获取当前时间，填入标题。

格式自由，外层结构统一：

```markdown
## YYYY-MM-DD HH:MM — {简短标题}

{1~5 句话，不要硬凑。包含以下要素，按需取舍：}
- 做了什么、为什么
- 选了什么方案、考虑过什么替代方案
- 涉及哪些关键文件
```

不同场景的写法参考：

- **实现功能**：选择 JWT + httpOnly cookie 而非 server-side session。原因：需支持多实例部署，session 需共享存储。考虑过 Redis session 但团队无运维经验。涉及: `src/auth/middleware.ts`
- **修复 bug**：修复分页偏移量计算错误，原因是 offset 从 1 开始而非 0。涉及: `src/api/list.ts`
- **重构/配置**：将日志轮转触发条件从行数改为 entry 数量，减少换行策略导致的触发抖动。
- **纯决策（无代码改动）**：决定 API 版本策略采用 URL path 而非 header，便于调试和缓存。放弃 header 方案因客户端兼容性差。

## 3. 向用户展示

写入后输出一行摘要，格式固定为：

```
已记录: {标题} → docs/decisions/log.md
```

其中 `{标题}` 与写入的标题保持一致。用户可要求修正。

## 4. 日志轮转

统计 `log.md` 中以 `## YYYY-MM-DD HH:MM` 开头的标题数量，若 >= 150：

1. 取 `log.md` 中**第一条** entry 标题的月份（`YYYY-MM`）作为归档文件名，避免跨月内容被错误归入当前月
2. 将 `log.md` 全部内容追加到 `docs/decisions/log-YYYY-MM.md`（不存在则创建）
3. 确认写入成功后，重建 `log.md`，写入 `# Decision Log` 和排序说明
4. 若该归档文件超过 2000 行，拆分为 `log-YYYY-MM-01.md`、`log-YYYY-MM-02.md` …（按序递增）
5. 告知用户已轮转至哪个归档文件


# Eval 02 — 日志轮转触发

## 场景描述

验证 whylog-record 在 `log.md` 达到 150 条 entry 时能正确触发轮转，并在轮转后继续正常写入新 entry。

---

## 场景 A — 应触发轮转：entry 数量 >= 150

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "重构了用户模块的权限校验逻辑，将分散在各 handler 的 role check 抽取为统一中间件。涉及: src/middleware/authz.ts",
  "precondition": "docs/decisions/log.md 中已有 150 条以 '## YYYY-MM-DD HH:MM' 开头的 entry，最早一条日期为 2025-03"
}
```

### 预期行为

- [ ] 判断为**记录**（修改了源码 + 有重构决策）
- [ ] 执行 Step 2：追加新 entry 到 log.md
- [ ] 执行 Step 4：统计 entry 数量，发现 >= 150，触发轮转
- [ ] 取第一条 entry 的月份 `2025-03` 作为归档文件名
- [ ] 将 log.md 全部内容追加到 `docs/decisions/log-2025-03.md`
- [ ] 重建 log.md，写入 `# Decision Log` 和排序说明
- [ ] 告知用户已轮转至 `docs/decisions/log-2025-03.md`

### 不应出现的行为

- entry 数量达到 150 但未触发轮转
- 以当前日期（而非第一条 entry 的月份）命名归档文件
- 轮转后 log.md 仍保留旧 entry（未重建）
- 轮转后未写入本次新 entry

---

## 场景 B — 不触发轮转：entry 数量 < 150

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "修复了列表接口分页 offset 计算错误，offset 应从 0 开始。涉及: src/api/list.ts",
  "precondition": "docs/decisions/log.md 中有 80 条 entry"
}
```

### 预期行为

- [ ] 判断为**记录**（修复了 bug）
- [ ] 执行 Step 2：追加新 entry
- [ ] 执行 Step 4：统计 entry 数量为 81，未达到 150，**不触发**轮转
- [ ] 执行 Step 3：输出 `已记录: {标题} → docs/decisions/log.md`

### 不应出现的行为

- 误触发轮转（entry < 150）
- 跳过 Step 4 的数量检查

---

## 场景 C — 归档文件超 2000 行时拆分

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "新增商品搜索接口，支持按名称模糊匹配。涉及: src/api/search.ts",
  "precondition": "log.md 有 150 条 entry，第一条月份为 2025-01；docs/decisions/log-2025-01.md 已存在且超过 2000 行"
}
```

### 预期行为

- [ ] 轮转时检测到 `log-2025-01.md` 已超过 2000 行
- [ ] 将内容写入 `docs/decisions/log-2025-01-02.md`（若 01 已满则递增序号）
- [ ] 告知用户实际写入的归档文件名

### 不应出现的行为

- 直接覆盖已超 2000 行的归档文件
- 未递增序号导致数据丢失

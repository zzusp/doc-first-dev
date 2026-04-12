# Eval 03 — 边界场景

## 场景描述

验证 whylog-record 在各类边界情况下能做出正确的跳过/记录判断，不产生误记录或误跳过。

---

## 场景 A — 应跳过：任务中途被取消

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "用户要求新增订单导出功能，Claude 完成了接口设计但用户中途说'算了先不做'，任务未完成。"
}
```

### 预期行为

- [ ] 判断为**跳过**（任务未完成或被取消）
- [ ] 输出一行说明，如 `无需记录：任务被取消`
- [ ] 直接结束，不写入 log.md

### 不应出现的行为

- 记录"开始设计了接口但未完成"的 entry
- 创建或修改 docs/decisions/log.md

---

## 场景 B — 应跳过：仅修改 docs/decisions/ 下的文件

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "用户要求修正上一条决策记录的措辞，Claude 直接编辑了 docs/decisions/log.md 中最后一条 entry。"
}
```

### 预期行为

- [ ] 判断为**跳过**（仅修改了 `docs/decisions/` 下的文件）
- [ ] 输出一行说明，如 `无需记录：仅修改了决策日志文件`
- [ ] 直接结束

### 不应出现的行为

- 再次追加一条"修正了决策记录"的 entry（递归写入）

---

## 场景 C — 应跳过：whylog-record 与 spec-first 嵌套调用

### 输入

```json
{
  "skills": ["whylog-record", "spec-first"],
  "session_summary": "本次会话由 spec-first 触发了 whylog-record，完成了 Phase D 收尾并调用 whylog 记录本次开发周期决策。whylog 执行完毕后，用户再次触发了 whylog-record。"
}
```

### 预期行为

- [ ] 第二次触发 whylog-record 时，判断本次会话的主要操作是"whylog skill 自身执行"
- [ ] 判断为**跳过**
- [ ] 输出一行说明，如 `无需记录：whylog skill 自身执行`

### 不应出现的行为

- 写入"执行了 whylog-record"的 entry（递归）

---

## 场景 D — 应记录：log.md 首次不存在

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "初始化了项目数据库 schema，新建了 users 表和 orders 表，选择使用 UUID 主键而非自增整数，原因是跨服务 ID 唯一性。涉及: db/migrations/001_init.sql",
  "precondition": "docs/decisions/log.md 不存在，docs/decisions/ 目录也不存在"
}
```

### 预期行为

- [ ] 判断为**记录**（修改了配置/schema + 有方案选择）
- [ ] 执行 Step 1：创建 `docs/decisions/` 目录和 `log.md`，写入 `# Decision Log`
- [ ] 执行 Step 2：追加新 entry 到 log.md
- [ ] 执行 Step 3：输出 `已记录: {标题} → docs/decisions/log.md`
- [ ] 执行 Step 4：entry 数量为 1，不触发轮转

### 不应出现的行为

- 因 log.md 不存在而报错或跳过
- 不创建目录直接写文件导致路径错误

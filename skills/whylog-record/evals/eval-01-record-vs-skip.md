# Eval 01 — 记录 vs 跳过 的判断边界

## 场景描述

验证 whylog-record 在不同会话类型下能正确判断"记录 / 酌情记录 / 跳过"，不应无差别记录所有会话，也不应遗漏真正有价值的决策。

---

## 场景 A — 应记录：有方案选择的代码变更

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "实现用户登录功能。比较了 JWT + httpOnly cookie 与 server-side session 两个方案，最终选择 JWT 方案，原因是需要支持多实例部署。修改了 src/auth/middleware.ts 和 src/auth/login.ts。"
}
```

### 预期行为

- [ ] 判断为**记录**（修改了源码 + 有方案选择）
- [ ] 执行 Step 1：确认 docs/decisions/log.md 存在
- [ ] 执行 Step 2：追加新 entry，标题简短，内容涵盖选择理由和替代方案
- [ ] 执行 Step 3：输出 `已记录: {标题} → docs/decisions/log.md`
- [ ] 执行 Step 4：检查 entry 数量，必要时触发轮转

### 不应出现的行为

- 判断为跳过
- 记录内容只写"做了什么"，没有"为什么"和"考虑过什么替代方案"
- 将 entry 插入文件中间而非末尾

---

## 场景 B — 应跳过：纯问答，无文件改动

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "用户询问 JWT 和 session 的区别，Claude 做了解释，未修改任何文件。"
}
```

### 预期行为

- [ ] 判断为**跳过**（纯问答）
- [ ] 输出一行说明，如 `无需记录：纯问答`
- [ ] 直接结束，不执行 Step 1～4

### 不应出现的行为

- 创建或修改 docs/decisions/log.md
- 输出空白 entry

---

## 场景 C — 酌情记录：仅改了文档，但有取舍行为

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "更新了 docs/plans/user/user-tech-spec.md 中的接口规范章节，调整了分页字段命名（pageNo → pageNum），原因是与团队其他模块保持一致，考虑过保留 pageNo 做兼容层但放弃了。"
}
```

### 预期行为

- [ ] 判断为**酌情记录**（仅改文档，但存在命名选择的取舍行为）
- [ ] 满足"① 修改时存在多个方案的选择"→ 判定**记录**
- [ ] 追加 entry，说明字段命名选择理由

### 不应出现的行为

- 判断为跳过（因为"只改了文档"）
- 记录内容遗漏对 pageNo 兼容方案的提及

---

## 场景 D — 应跳过：whylog 自身执行

### 输入

```json
{
  "skills": ["whylog-record"],
  "session_summary": "本次会话仅执行了 whylog-record skill，写入了一条决策日志。"
}
```

### 预期行为

- [ ] 判断为**跳过**（whylog skill 自身执行）
- [ ] 输出一行说明，如 `无需记录：whylog skill 自身执行`
- [ ] 直接结束

### 不应出现的行为

- 递归写入一条"记录了 whylog 执行"的 entry

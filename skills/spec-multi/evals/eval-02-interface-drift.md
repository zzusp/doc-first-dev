# Eval 02 — 接口漂移处理

## 场景描述

需求「用户搜索」已完成 Phase A 和 Phase B，正在 Phase D 一致性审计阶段。

需求文档"接口定义"节中 `[backend] GET /api/users` 定义的响应为：
```json
{ "code": 0, "data": { "list": [...], "total": 10 } }
```

但审计时发现，frontend 代码中实际读取的是 `response.data.users`（非 `list`），而 backend 代码返回的是 `response.data.list`。

即：backend 实现与文档一致，但 frontend 实现与文档不符。

## 预期行为

### Phase D.1
- 检查"接口定义"节中 `[backend] GET /api/users` 的调用方 frontend 代码
- 发现 `frontend/src/api/userApi.js` 中读取 `response.data.users`，与接口定义的 `list` 字段不符
- 暂停审计，展示问题：

```
发现不一致：

接口定义：[backend] GET /api/users → data.list
frontend 代码（userApi.js）：读取 data.users

→ 如何处理？
  A. 以文档/backend 为准（修改 frontend 代码，将 data.users 改为 data.list）
  B. 以 frontend 代码为准（更新需求文档和 backend 代码，将 list 改为 users）
```

### 用户选择 A（以文档为准）
- 修改 `frontend/src/api/userApi.js`，将 `data.users` 改为 `data.list`
- 更新需求文档（接口定义节不变，调用方引用节注明已修复）
- 继续 D.2 清理

### 用户选择 B（以代码为准）
- 更新需求文档"接口定义"节：`[backend] GET /api/users` 响应字段 `list` → `users`
- 修改 `backend` 代码，将 `list` 改为 `users`
- 继续 D.2 清理

## 验证要点

- [ ] D.1 正确发现调用方代码与接口定义不符（而不是遗漏）
- [ ] 问题展示清晰：指出具体文件、具体字段，不含糊
- [ ] 两种选择均正确执行（代码修改或文档更新）
- [ ] 修复后继续 D.2，不重新跑完整的 Phase C

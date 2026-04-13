# Eval 03 — 需求只涉及部分服务

## 场景描述

项目有 4 个服务：`frontend`、`backend`、`data-service`、`notification-service`。

用户提出需求：

> 「修改用户列表接口，支持按注册日期范围过滤。前端需要增加日期选择器。」

这个需求只涉及 `frontend` 和 `backend`，不涉及 `data-service` 和 `notification-service`。

## 预期行为

### Phase A.2
- 判断入口服务为 `frontend`（用户在前端操作日期选择器）
- 展示判断理由

### Phase A.3
- 从 `frontend` 出发，追踪到 `backend` 的用户列表接口
- `backend` 处理查询直接走 DB，不调用 `data-service` 或 `notification-service`
- 链路追踪在 `backend → DB` 处终止（DB 不是服务，不继续追踪）
- 记录链路：`frontend → backend`

### Phase A.4
展示：
```
受影响服务：
  ✅ frontend — 新增日期选择器组件
  ✅ backend — 修改用户列表接口，增加日期范围过滤参数

不涉及服务：
  ⬜ data-service — 链路追踪中 backend 未调用 data-service（直连 DB）
  ⬜ notification-service — 链路追踪中未涉及（无消息通知逻辑）
```

用户确认后继续。

### Phase A.5
需求文档填充：
- 接口定义节：`[backend] GET /api/users`（修改，增加 `startDate`、`endDate` 参数）；`[frontend] 依赖的接口`
- 代码地图节：只有 `[frontend]` 和 `[backend]` 两个小标题
- 任务节：frontend 1-2 项，backend 1-2 项；**不出现** `[data-service]` 或 `[notification-service]` 的任务
- 验收节：frontend 1 项，backend 1 项，[E2E] 1 项

### Phase B
- 批次 1：`backend`（frontend 依赖 backend 的接口变更）
- 批次 2：`frontend`
- `data-service` 和 `notification-service` 不参与任何批次

## 验证要点

- [ ] 链路追踪正确在 `backend` 处终止（不错误地追踪到 data-service）
- [ ] 不涉及的服务明确列出并附理由，而不是静默跳过
- [ ] 需求文档中没有 `[data-service]` 或 `[notification-service]` 的任何内容
- [ ] Phase B 只执行 backend 和 frontend 两个批次
- [ ] Phase C 仍然启动所有 4 个服务（集成验收需要完整环境），但 A-xxx 只验证 frontend/backend/E2E

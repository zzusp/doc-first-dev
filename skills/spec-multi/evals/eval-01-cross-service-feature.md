# Eval 01 — 典型多服务新功能

## 场景描述

用户在一个包含 frontend（React）、backend（Node.js）、data-service（Python FastAPI）的 monorepo 中提出需求：

> 「用户点击导出按钮，系统生成 CSV 文件并返回下载链接。数据处理逻辑在 data-service 中实现。」

`docs/plans/SERVICES.md` 已存在，`docs/plans/requirements/user-export.md` 不存在。

## 预期行为

### Step 0
- 推断需求文件名为 `user-export`
- 从 multi-spec-blank.md 创建文档，填入业务目标
- 让用户确认业务目标描述后进入 Phase A

### Phase A
**A.2**：判断入口服务为 `frontend`（需求从前端按钮触发），展示理由，等用户确认。

**A.3**：追踪链路：
- 读 `frontend/src/components/ExportButton.jsx`（或类似入口）
- 发现调用 `POST /api/export` → 追踪到 `backend/src/controllers/ExportController.js`
- 发现调用 `data-service` 的 HTTP 接口 → 追踪到 `data-service/main.py` 的对应路由
- 记录链路：`frontend → backend → data-service`

**A.4**：展示 3 个受影响服务，每个附代码依据，用户确认。

**A.5**：填充需求文档：
- 接口定义节：`[data-service] POST /process`（提供方）；`[backend] POST /api/export`（提供方）；`[frontend] 依赖的接口`（调用方）
- 任务节：backend 2-3 项，frontend 1-2 项，data-service 1-2 项，序号递增，含 [服务名] 标签
- 验收节：backend/frontend/data-service 各 1 项，[E2E] 1 项

**A.7**：展示摘要，用户确认，进入 Phase B。

### Phase B
- 批次 1：`data-service`（无依赖）
- 批次 2：`backend`（依赖 data-service）
- 批次 3：`frontend`（依赖 backend）
- 每批次完成后，对应 T-xxx 标记 ✅
- 各服务 build 全部通过

### Phase C
- 按顺序启动 3 个服务，验证健康
- 执行单服务 A-xxx（3 项）
- 执行 [E2E] A-xxx（1 项，涵盖完整链路）
- 全部通过，进入 Phase D

### Phase D
- D.1：接口定义与代码一致，无问题
- D.2：删除已完成 T-xxx
- D.3：SERVICES.md 追加需求记录
- D.4：输出交付摘要

## 验证要点

- [ ] 链路追踪正确识别 3 个服务（不多也不少）
- [ ] 接口定义节中提供方写完整定义，调用方只写引用
- [ ] T-xxx 序号全文档唯一递增，含 [服务名] 标签
- [ ] Phase B 严格按依赖顺序执行批次（data-service → backend → frontend）
- [ ] [E2E] A-xxx 覆盖完整跨服务链路
- [ ] Phase D 删除已完成 T-xxx，保留取消项

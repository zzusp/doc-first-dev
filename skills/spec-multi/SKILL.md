# spec-multi — 多服务并行开发

处理跨多个服务/项目的需求开发。单服务日常迭代用 `/spec-first`；跨服务协调用本 skill。

## 触发条件

用户描述的需求涉及多个服务同时变更（如前端+后端、后端+Python服务、全栈+微服务等）。

## 前置检查

**检查 `docs/plans/SERVICES.md` 是否存在（相对于 workspace root）：**

- **不存在** → 读取 [init.md](init.md)，完成服务注册后返回本流程
- **存在** → 展示服务清单摘要（服务名、路径、端口），继续

## 流程

```
Step0（需求接收）→ Phase A（分析）→ Phase B（开发）→ Phase C（集成验收）→ Phase D（收尾）
```

用户指定从某个 Phase 开始时，从该 Phase 直接切入（如"从 Phase B 继续"）。

异常处理规则见 [error-handling.md](error-handling.md)。

## 各阶段入口

| 阶段 | 文件 | 核心产出 |
|---|---|---|
| Step 0 | [step0.md](step0.md) | 创建或定位需求文档 |
| Phase A | [phase-a.md](phase-a.md) | 链路追踪 + 需求文档填充 + 确认门 |
| Phase B | [phase-b.md](phase-b.md) | 按依赖顺序编排各服务代码实现 |
| Phase C | [phase-c.md](phase-c.md) | 启动所有服务 + 单服务验收 + E2E 验收 |
| Phase D | [phase-d.md](phase-d.md) | 一致性审计 + 交付摘要 |

## 关键约定

**需求文档**：`docs/plans/requirements/<需求名>.md`（workspace root 下）

**T-xxx 格式**：`T-<序号> · [<服务名>] · P0/P1/P2 · 状态 — 描述（file:method）`

**A-xxx 格式**：`A-<序号> · [<服务名>|E2E] · <接口/场景> · 状态 — 可执行断言`

- `[E2E]` 表示跨服务集成验收
- 序号全文档内唯一递增（不区分服务）
- Phase B 通过过滤 `[服务名]` 标签分配 subagent 任务

---
name: spec-first
description: 管理项目模块的完整开发周期：需求分析→更新技术方案→spec确认→开发→验收→收尾。触发条件：项目下有 spec 文档，且用户请求涉及代码变更（功能新增、Bug修复、需求变更、接口调整、重构、字段增删），无需用户明确指定流程。
---

# /spec-first — 文档驱动开发周期管理

本 skill 驱动从需求到交付的完整流程：

```
需求到来 → 匹配文档 → 分析 → 更新spec → spec确认 → 开发 → 验收 → 收尾
```

适用于：新功能、Bug修复、需求调整、重构——凡是项目文档目录（默认 `docs/plans/`）下有 spec 的模块，均走此流程。

**触发后立即输出以下进度 Checklist；每个阶段完成时，重新输出当前状态的 Checklist（已完成项标为 `[x]`）：**

```
开发周期进度
- [ ] Step 0  需求接收，文档匹配
- [ ] Step 1  阶段判断
- [ ] Phase A 分析与更新 spec
- [ ] Phase B 按方案开发
- [ ] Phase C 验收
- [ ] Phase D 收尾
```

异常处理规则见 [error-handling.md](error-handling.md)。

**模板文件**（按需读取）：
- [assets/project-index.md](assets/project-index.md) — 项目索引骨架（PROJECT.md）
- [assets/tech-spec-blank.md](assets/tech-spec-blank.md) — 技术方案骨架
- [assets/api-blank.md](assets/api-blank.md) — 接口文档骨架
- [assets/claude-md-snippet.md](assets/claude-md-snippet.md) — CLAUDE.md 片段

---

## 前置检查 — 环境就绪

**在执行任何步骤前**，检查 `docs/plans/PROJECT.md` 是否存在：

- **存在** → 直接进入 Step 0
- **不存在** → 读取 [init.md](init.md)，完成初始化后进入 Step 0

---

## Step 0 — 接收需求，匹配文档

读取 [step0.md](step0.md) 并执行。

---

## Step 1 — 判断当前阶段

**前置检查**：确认 spec 已加载（本 session 中 Step 0 已执行，或用户提供了 spec 文件路径）。若两者均未满足，输出以下提示后**立即终止，不执行后续任何步骤**：

```
⛔ 未找到工作文档。请重新运行 /spec-first 并在 Step 0 选择或创建 spec 文档。
```

扫描 spec 的任务状态（T-xxx）和验收状态（A-xxx），按以下条件**从上到下优先匹配**，读取并执行对应 Phase 文档：

**第一条"用户描述了新需求或变更"的判断标准**：用户**本轮**消息中包含尚未体现在 spec 中的需求、功能描述或变更说明（包含新功能、Bug 修复、调整要求等）。若用户本轮仅发送"继续"/"接着做"/"开始开发"等不含新信息的指令，跳过第一条，按任务/验收状态向下匹配。

| 条件 | Phase |
|---|---|
| 用户描述了新需求或变更 | 读取 [phase-a.md](phase-a.md) — 分析与更新 |
| 有"待开始"/"进行中"的 T-xxx | 读取 [phase-b.md](phase-b.md) — 按方案开发 |
| 所有 T-xxx 均为 ✅ 或已取消，有"待验证"/"未通过"的 A-xxx | 读取 [phase-c.md](phase-c.md) — 验收 |
| 所有 T-xxx 均为 ✅ 或已取消，且所有 A-xxx ✅（A-xxx 不为空） | 读取 [phase-d.md](phase-d.md) — 收尾 |
| spec 无任务/验收项，或有 T-xxx 但无 A-xxx | 读取 [phase-a.md](phase-a.md) — 分析与更新 |

状态混乱时询问用户确认；用户可显式指定阶段覆盖自动判断。

# Eval 01 — 新增功能需求（完整流程）

## 场景描述

用户在已有 spec 的项目中提出新功能需求，触发完整 A→B→C→D 流程。

## 输入

```json
{
  "skills": ["spec-first"],
  "query": "帮我在商品列表接口 POST /item/list 增加按 firstAuthor 筛选的功能",
  "context": "项目已有 docs/plans/PROJECT.md 和 docs/plans/item-module.md（含接口规范、数据库设计、代码地图、任务状态、验收项章节）"
}
```

## 预期行为

- [ ] 识别为开发任务，触发 spec-first 工作流
- [ ] Step 0：读取 PROJECT.md，展示 spec 选择器，用户选择 item-module.md
- [ ] Step 1：检测到用户描述了新需求，进入 Phase A
- [ ] Phase A.1：复述需求（在 /item/list 增加可选的 firstAuthor 查询参数）
- [ ] Phase A.2：识别受影响章节（接口规范第3节、代码地图第5节），展示修改前/修改后对照
- [ ] Phase A.3：读取 Mapper 文件、Controller、Service，说明每步发现
- [ ] Phase A.4：原地改写对应章节，不追加"原来是 X 现改为 Y"的历史描述
- [ ] Phase A.5：新增 T-xxx 任务，包含文件范围和方法名（不用行号）
- [ ] Phase A.6：新增 A-xxx 验收项，含可执行断言（具体 HTTP 请求 + 预期响应）
- [ ] Phase A.7：质量检查通过后调用 AskUserQuestion 确认
- [ ] 用户确认后进入 Phase B，使用 Agent 子代理并行执行任务
- [ ] Phase B 完成后进入 Phase C 验收，失败时诊断→修复→重测
- [ ] 所有 A-xxx 通过后进入 Phase D，输出交付摘要

## 不应出现的行为

- 跳过 Phase A 直接开始写代码
- 在 Phase A.4 中追加变更历史（"原来是 X，现改为 Y"）
- A-xxx 验收项缺少具体断言（如仅写"筛选功能正常"）
- T-xxx 使用行号定位（如 `ItemMapper.java:112`）

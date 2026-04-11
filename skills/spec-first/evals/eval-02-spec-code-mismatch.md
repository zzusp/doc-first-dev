# Eval 02 — Phase B 中途发现 spec 与代码不符

## 场景描述

开发过程中 Claude 读取源码后发现实际实现与 spec 描述不一致，触发暂停确认机制。

## 输入

```json
{
  "skills": ["spec-first"],
  "query": "继续执行 T-08，在 OrderService.createOrder() 增加库存校验",
  "context": "spec 中 T-08 状态为"待开始"；spec 代码地图记录 createOrder() 在 OrderServiceImpl.java；但实际读取文件发现该方法已拆分为 createOrder() + validateStock()，且 validateStock() 已实现库存校验逻辑"
}
```

## 预期行为

- [ ] Phase B 执行 T-08 时读取 OrderServiceImpl.java
- [ ] 发现代码与 spec 描述不符（方法已拆分，库存校验已存在）
- [ ] **暂停开发**，不自行修改 spec 或继续实现
- [ ] 向用户清晰描述不一致内容：spec 说 createOrder() 需新增库存校验 vs 代码中 validateStock() 已实现
- [ ] 提供两个选项：① 以代码为准更新 spec（标记 T-08 已完成）② 以 spec 为准调整代码（保留 T-08 待开始）
- [ ] 等待用户选择后按指示继续

## 不应出现的行为

- 自行判断"代码已实现，直接标记 T-08 完成"
- 自行修改 spec 后继续开发，不通知用户
- 忽略不一致，继续实现可能重复的功能

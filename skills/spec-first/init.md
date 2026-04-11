# 初始化 — 创建项目索引文件

`docs/plans/PROJECT.md` 不存在，执行以下步骤，完成后返回 SKILL.md 进入 Step 0。

1. 读取 `skills/spec-first/assets/plans-PROJECT.md` 作为骨架，写入 `docs/plans/PROJECT.md`
2. 输出提示：

```
⚠️  未找到 docs/plans/PROJECT.md，已从模板创建。
请填写以下基本信息（可跳过，后续手动维护）：
  · 项目定位（1-3 句话）
  · 技术栈（语言、框架、数据库）
  · 全局 API 约定（认证方式、统一响应结构）
填写完成后回复"继续"，或直接回复"跳过"进入开发流程。
```

3. 等待用户回复：
   - 用户提供信息 → 将其填入 `docs/plans/PROJECT.md` 对应章节并保存，然后继续
   - 用户回复"跳过" → 直接继续
4. 初始化完成，返回 SKILL.md Step 0

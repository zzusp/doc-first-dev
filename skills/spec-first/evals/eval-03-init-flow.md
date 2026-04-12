# Eval 03 — 首次运行，无 PROJECT.md（初始化流程）

## 场景描述

项目首次接入 spec-first，docs/plans/PROJECT.md 不存在，触发初始化分支。

## 输入

```json
{
  "skills": ["spec-first"],
  "query": "帮我给用户模块加一个邮箱登录接口",
  "context": "项目目录下无 docs/plans/ 目录，也无任何 spec 文件"
}
```

## 预期行为

- [ ] 前置检查：检测到 docs/plans/PROJECT.md 不存在
- [ ] 读取 init.md，从 assets/project-index.md 模板创建 docs/plans/PROJECT.md
- [ ] 输出警告提示，询问用户填写项目基本信息（项目定位、技术栈、API 约定）
- [ ] 等待用户回复（提供信息或"跳过"）
- [ ] 填入用户提供的信息后保存，返回 SKILL.md Step 0
- [ ] Step 0：因 docs/plans/ 下此时只有 PROJECT.md（无模块 spec），询问用户是否新建模块 spec
- [ ] 用户确认后，从 assets/tech-spec-blank.md 模板创建用户模块 spec
- [ ] 进入 Phase A 分析邮箱登录接口需求

## 不应出现的行为

- 跳过初始化直接进入 Step 0 或 Phase A
- 创建 PROJECT.md 后不提示用户填写信息直接继续
- 用户说"跳过"时仍等待信息输入
- 初始化完成后忘记返回 Step 0（直接终止流程）

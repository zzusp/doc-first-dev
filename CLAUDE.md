# CLAUDE.md — doc-first-dev

本仓库是一套可安装的 **Agent Skills**，不是业务项目。在此仓库中工作时请遵守以下规则。

## 仓库结构

```
skills/
  spec-first/          # 文档驱动全周期 skill
    SKILL.md           # 入口
    *.md               # 各阶段文件（init, step0, phase-a/b/c/d, error-handling）
    assets/            # 供目标项目使用的模板文件
    evals/             # 评测场景
  whylog-record/       # 决策日志 skill
    SKILL.md
    evals/
reference/
  best-practices.md    # Skill 编写参考指南，修改 skill 前必读
```

## 编写规则

- 修改任何 skill 文件前，先阅读 `reference/best-practices.md`
- skill 文件保持精简：不解释 Claude 已知的常识，只写 Claude 没有的上下文
- 文件命名：全小写 + 连字符（如 `phase-a.md`、`claude-md-snippet.md`）
- 模板文件（`assets/`）中的占位符统一用 `<尖括号>` 格式
- 不在 skill 文件里硬编码用户项目的具体路径

## 评测

修改 skill 逻辑后，对照 `evals/` 中的场景手动验证主要路径是否仍符合预期。

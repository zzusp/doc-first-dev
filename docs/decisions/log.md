# Decision Log

## 2026-04-12 — README 与仓库现状对齐

将根目录 `README.md` 与当前 `skills/spec-first/` 实际结构同步：补充 `init.md`、`step0.md`、`phase-a`～`d`、`evals/` 等说明；写明 `PROJECT.md` 前置检查与自动生成流程；增加进度 Checklist 提示；安装步骤增加 Windows `Copy-Item` 示例；将 CLAUDE 片段占位符描述改为与 `CLAUDE.md-snippet.md` 一致（不再写死「7 处」）；FAQ 增补模块索引文件名说明。

_Commit: `e1d8b85` · By: zzusp_

## 2026-04-12 — README 写明 GitHub 坐标

`git remote` 已为 `zzusp/doc-first-dev`：README 中 `npx skillsadd` 与手动安装示例改为使用该 owner/repo，并增加源码链接；PowerShell 示例改为 clone 后相对路径 `.\doc-first-dev\skills\*`，避免写死本机盘符。

_Commit: `e1d8b85` · By: zzusp_

## 2026-04-12 — README 面向 skills.sh 发布润色

为在 [skills.sh](https://skills.sh/) 等目录上架做可读性与发现性优化：文首增加中英双语定位与兼容 Agent 说明；用表格列出 `spec-first` / `whylog-record` 的 name 与用途；推荐路径为 `npx skillsadd` 并保留手动复制安装；压缩重复段落，将「两套 skill」对比与 FAQ 收紧。

_Commit: `e1d8b85` · By: zzusp_

# Doc-First Dev — 文档驱动开发框架

将"文档先行"开发规范抽象为可在任意项目复用的工具集。

## 包含内容

```
doc-first-dev/
├── README.md                        # 本文件
├── skill/
│   └── SKILL.md                     # 通用版 /spec skill
├── hooks/
│   └── check-spec-first.ps1         # 通用版 PreToolUse hook
├── templates/
│   ├── settings.json                # .claude/settings.json 模板
│   ├── CLAUDE.md-snippet.md         # 粘贴到项目 CLAUDE.md 的片段
│   ├── tech-spec-blank.md           # 空白 8 节技术方案模板
│   ├── plans-README.md              # docs/plans/README.md 模块索引模板
│   └── doc-first.json               # .doc-first.json 项目配置模板
└── examples/
    └── doc-first-java.json          # Java/Maven 项目配置示例
```

---

## 核心机制

| 组件 | 作用 |
|---|---|
| `/spec` skill | 驱动从需求到交付的完整周期（Step 0 匹配文档 → Phase A 分析更新 → Phase B 开发 → Phase C 验收 → Phase D 收尾） |
| PreToolUse hook | 在修改源文件前自动检查 spec 是否已更新，未更新则阻断并提示 |
| `.doc-first.json` | 每个项目的配置文件，声明受保护的源码路径和文档目录 |

---

## 快速安装（新项目）

### 步骤 1：安装 /spec skill（全局，一次性）

```bash
# 复制到 Claude Code skills 目录
cp skill/SKILL.md ~/.claude/skills/spec/SKILL.md
```

安装后在任意项目中运行 `/spec <需求描述>` 即可触发。

### 步骤 2：在项目中启用 hook

**2a. 复制 hook 脚本**

```bash
mkdir -p <project>/.claude/hooks
cp hooks/check-spec-first.ps1 <project>/.claude/hooks/
```

**2b. 创建项目配置文件**

```bash
# Java/Maven 项目
cp examples/doc-first-java.json <project>/.doc-first.json

# 其他语言：从模板开始，修改 sourcePatterns
cp templates/doc-first.json <project>/.doc-first.json
```

**2c. 配置 `.claude/settings.json`**

```bash
cp templates/settings.json <project>/.claude/settings.json
# 如项目已有 settings.json，将 hooks 部分合并进去
```

**2d. 初始化文档目录**

```bash
mkdir -p <project>/docs/plans
cp templates/plans-README.md <project>/docs/plans/README.md
```

**2e. 更新 CLAUDE.md**

将 `templates/CLAUDE.md-snippet.md` 的内容粘贴到项目 `CLAUDE.md`，填写实际的构建命令和启动/认证命令。

**这两个章节是必填的**，`/spec` skill 的 Phase B.4（构建验证）和 Phase C.1（验收准备）会引用它们。

### 步骤 3：验证安装

在 Claude Code 中运行：

```
/spec 测试安装是否正常
```

应看到文档选择器弹出。若直接尝试修改源文件而未改 spec，应看到 hook 拦截提示。

---

## .doc-first.json 配置参数

| 参数 | 类型 | 说明 | 省略时的默认值 |
|---|---|---|---|
| `sourcePatterns` | `string[]` | 正则数组，匹配需要拦截的源文件路径 | `["src[/\\]"]` |
| `docDir` | `string` | 文档目录，用于检测 git 未提交变更 | `"docs/plans/"` |

### 各语言 sourcePatterns 参考

```json
// Java/Maven
{ "sourcePatterns": ["src[/\\\\](main|test)[/\\\\]java"] }

// Python
{ "sourcePatterns": ["src[/\\\\]", "app[/\\\\]", "lib[/\\\\]"] }

// Node.js / TypeScript
{ "sourcePatterns": ["src[/\\\\]", "lib[/\\\\]"] }

// Go
{ "sourcePatterns": ["internal[/\\\\]", "cmd[/\\\\]", "pkg[/\\\\]"] }

// Rust
{ "sourcePatterns": ["src[/\\\\]"] }
```

---

## 日常使用流程

```
/spec <需求描述>
  │
  ├─ Step 0  匹配文档 → AskUserQuestion 选择器（最多3个 + Other）
  ├─ Step 1  判断当前阶段（A/B/C/D）
  │
  ├─ Phase A  A.1确认需求 → A.2识别章节 → A.3靶向探索代码
  │           → A.4改写+状态重置 → A.5新增T-xxx → A.6新增A-xxx
  │           → A.7质量检查 + AskUserQuestion确认门
  │
  ├─ Phase B  B.1依赖分析+执行计划 → B.2按批次并行执行
  │           → B.3偏差暂停 → B.4构建验证（参考CLAUDE.md）
  │
  ├─ Phase C  C.1启动+获取认证（参考CLAUDE.md）
  │           → C.2逐条执行A-xxx → C.3失败修复 → C.4非功能验收
  │
  └─ Phase D  D.1一致性检查 → D.2交付简报 + 提示/whylog-record
```

---

## 新建模块 spec 文档

运行 `/spec <需求>` 选择"Other → 新建文档"，skill 会自动使用 `templates/tech-spec-blank.md` 创建骨架。

或手动：

```bash
mkdir -p docs/plans/<module-name>
cp ~/.claude/doc-first-dev/templates/tech-spec-blank.md \
   docs/plans/<module-name>/<feature>-tech-spec.md
```

---

## FAQ

**Q：hook 在 macOS/Linux 上能用吗？**
A：当前为 PowerShell 脚本，需要安装 `pwsh`（PowerShell Core）。或将 `hooks/check-spec-first.ps1` 改写为等价的 bash 脚本（逻辑相同：读 `.doc-first.json` → 匹配路径 → 检查 git diff）。

**Q：想临时跳过 hook 怎么办？**
A：在 `.claude/settings.json` 中临时注释掉 hooks 配置，操作完成后恢复。

**Q：monorepo 多个子项目能用吗？**
A：在每个子项目根目录分别放 `.doc-first.json`，各自的 `.claude/settings.json` 配置各自的 hook 路径。

**Q：spec 已 commit 但本次想继续写代码，hook 会拦截吗？**
A：会。hook 检查的是"当前 session 是否有 docs/plans/ 的未提交变更"。这是有意设计——每次准备写代码前，先在 spec 上确认状态（哪怕只更新一个任务状态），既确认 spec 是最新的，也开启了"允许编码"的通行证。

**Q：/spec skill 如何知道构建命令和启动命令？**
A：Phase B.4 和 Phase C.1 会读取项目 `CLAUDE.md` 中的"构建命令"和"启动与认证"章节。这两个章节是必填项，使用 `templates/CLAUDE.md-snippet.md` 中的片段并填写实际命令。

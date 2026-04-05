# Doc-First Dev — 文档驱动开发框架

将"文档先行"开发规范抽象为可在任意项目复用的工具集。

## 包含内容

```
doc-first-dev/
├── README.md                              # 本文件
├── skill/
│   ├── SKILL.md                          # /spec skill（日常开发）
│   └── init/
│       └── SKILL.md                      # /spec-init skill（已有项目初始化）
│   └── init/reference/
│       └── languages.md                  # 语言扫描规则参考
├── hooks/
│   ├── check-spec-first.ps1              # PreToolUse hook（PowerShell版）
│   ├── check-spec-first.sh               # PreToolUse hook（Bash版，跨平台）
│   ├── generate-baseline-specs.ps1       # Spec生成脚本（PowerShell版）
│   └── generate-baseline-specs.sh         # Spec生成脚本（Bash版，跨平台）
├── templates/
│   ├── settings.json                     # .claude/settings.json 模板
│   ├── CLAUDE.md-snippet.md              # 粘贴到项目 CLAUDE.md 的片段
│   ├── tech-spec-blank.md                # 空白 8 节技术方案模板
│   ├── plans-README.md                   # docs/plans/README.md 模块索引模板
│   └── doc-first.json                   # .doc-first.json 项目配置模板
└── examples/
    └── doc-first-java.json               # Java/Maven 项目配置示例
```

---

## 核心机制

| 组件 | 作用 |
|---|---|
| `/spec` skill | 驱动从需求到交付的完整周期（分析→更新spec→开发→验收→收尾） |
| `/spec-init` skill | 已有项目的初始化：从代码逆向生成技术方案基线 |
| PreToolUse hook | 在修改源文件前自动检查 spec 是否已更新，未更新则阻断并提示 |
| `.doc-first.json` | 每个项目的配置文件，声明受保护的源码路径和文档目录 |

---

## 安装 — 选择你的场景

### 环境依赖（安装前）

- Bash 方案依赖：`bash`、`jq`、`git`
- PowerShell 方案依赖：`powershell`、`git`

可先自检：

```bash
jq --version
git --version
```

### 场景一：已有项目（有代码）

已有项目需要先通过 `/spec-init` 从代码逆向生成技术方案基线，再开始日常开发。

**步骤 1：安装 skills（全局，一次性）**

```bash
cp -r skill/* ~/.claude/skills/
```

**步骤 2：在项目中初始化**

```bash
cd <your-project>

# 在项目根目录运行
/spec-init
```

`/spec-init` 会自动：
1. 分析代码结构，生成功能清单草稿
2. 请你确认功能清单
3. 为每个模块生成 baseline spec
4. 输出 `docs/plans/init-report.md`

> 初始化只运行一次。完成后 hook 开始生效。

**步骤 3：提交产物**

```bash
git add .
git commit -m "初始化 doc-first 技术方案基线"
```

---

### 场景二：新项目（无代码）

新项目无需初始化，直接安装后即可使用。

**步骤 1：安装 skills（全局，一次性）**

```bash
cp -r skill/* ~/.claude/skills/
```

**步骤 2：在项目中启用 hook**

```bash
cd <your-project>

# 复制 hook 脚本（按平台选择）
cp hooks/check-spec-first.sh .claude/hooks/      # Linux/macOS/MSYS2
cp hooks/check-spec-first.ps1 .claude/hooks/     # Windows PowerShell

# 复制项目配置
cp examples/doc-first-java.json .doc-first.json  # Java/Maven 项目
# 或
cp templates/doc-first.json .doc-first.json       # 其他语言，修改 sourcePatterns

# 复制并合并 settings（按平台选择）
cp templates/settings.json .claude/settings.json          # Linux/macOS/Git Bash
# 或
cp templates/settings.windows.json .claude/settings.json  # Windows PowerShell

# 初始化文档目录
mkdir -p docs/plans
cp templates/plans-README.md docs/plans/README.md
```

**步骤 3：更新 CLAUDE.md**

将 `templates/CLAUDE.md-snippet.md` 的内容粘贴到项目 `CLAUDE.md`，填写构建命令和启动/认证命令。这两个章节是必填的，`/spec` skill 的 Phase B.4 和 Phase C.1 会引用。

**步骤 4：验证安装**

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

## 日常开发流程

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

## 新建模块

运行 `/spec <需求>` 选择"Other → 新建文档"，skill 会自动使用标准 8 节骨架创建空白 spec。

或手动：

```bash
mkdir -p docs/plans/<module-name>
cp templates/tech-spec-blank.md docs/plans/<module-name>/<feature>-tech-spec.md
```

---

## FAQ

**Q：已有项目初始化后，hook 会不会拦截所有现有代码修改？**
A：不会。初始化后所有 baseline spec 的任务和验收项均为 ✅ 完成状态。只有当你开始新的变更（功能新增、Bug修复等）时，才会触发 Phase A 的 spec 更新要求。hook 只拦截"未更新 spec 的源文件修改"，现有代码不受影响。

**Q：hook 在 macOS/Linux 上能用吗？**
A：能。`hooks/check-spec-first.sh` 是跨平台 Bash 版，支持 Linux、macOS、Windows Git Bash / MSYS2 / MinGW。按平台选择对应脚本复制即可。

**Q：想临时跳过 hook 怎么办？**
A：在 `.claude/settings.json` 中临时注释掉 hooks 配置，操作完成后恢复。

**Q：monorepo 多个子项目能用吗？**
A：在每个子项目根目录分别放 `.doc-first.json`，各自的 `.claude/settings.json` 配置各自的 hook 路径。

**Q：spec 已 commit 但本次想继续写代码，hook 会拦截吗？**
A：会。hook 检查的是"当前 session 是否有 docs/plans/ 的未提交变更"。这是有意设计——每次准备写代码前，先在 spec 上确认状态（哪怕只更新一个任务状态），既确认 spec 是最新的，也开启了"允许编码"的通行证。

**Q：/spec skill 如何知道构建命令和启动命令？**
A：Phase B.4 和 Phase C.1 会读取项目 `CLAUDE.md` 中的"构建命令"和"启动与认证"章节。这两个章节是必填项，使用 `templates/CLAUDE.md-snippet.md` 中的片段并填写实际命令。

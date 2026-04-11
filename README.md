# Doc-First Dev — 文档驱动开发框架

将"文档先行"开发规范抽象为可在任意项目复用的工具集。

## 包含内容

```
doc-first-dev/
├── README.md                              # 本文件
├── skills/
│   ├── spec-first/                       ★ 核心：文档驱动开发周期
│   │   ├── SKILL.md                      # /spec-first skill（日常开发）
│   │   ├── error-handling.md             # 异常处理规则（按需加载）
│   │   └── assets/
│   │       ├── CLAUDE.md-snippet.md      # 粘贴到项目 CLAUDE.md 的片段
│   │       ├── plans-PROJECT.md         # docs/plans/PROJECT.md 项目索引模板
│   │       └── doc-first.json           # .doc-first.json 项目配置模板
│   ├── spec-analyze/
│   │   └── SKILL.md                      # /spec-analyze skill（只读分析）
│   ├── spec-search/
│   │   └── SKILL.md                      # /spec-search skill（内容检索）
│   ├── spec-check/
│   │   └── SKILL.md                      # /spec-check skill（健康检查）
│   ├── spec-audit/
│   │   └── SKILL.md                      # /spec-audit skill（全局健康度审计）
│   ├── spec-dashboard/
│   │   └── SKILL.md                      # /spec-dashboard skill（仪表盘生成）
│   ├── spec-init/
│   │   ├── SKILL.md                      # /spec-init skill（已有项目初始化）
│   │   ├── assets/
│   │   │   ├── generate-baseline-specs.py  # Spec 生成脚本
│   │   │   ├── plans-PROJECT.md           # 项目索引模板
│   │   │   └── tech-spec-blank.md         # 空白 8 节技术方案模板
│   │   └── reference/
│   │       └── languages.md              # 语言扫描规则参考
│   ├── whylog-record/                    ★ 核心：记录开发决策
│   │   └── SKILL.md                      # /whylog-record skill（记录开发决策）
│   └── whylog-review/
│       └── SKILL.md                      # /whylog-review skill（查询决策历史）
└── examples/
    └── doc-first-java.json               # Java/Maven 项目配置示例
```

---

## 核心机制

> **两个核心技能：**
> - **`/spec-first`** — 维护项目的**当前状态**：需求边界、技术设计、架构，驱动从需求到交付的完整开发周期
> - **`/whylog-record`** — 记录到达这个状态的**过程**：决策依据、方案选择、需求演变
>
> 两者互补，共同构成完整的项目知识库。

| 组件 | 作用 |
|---|---|
| **`/spec-first` skill** ★ | 驱动从需求到交付的完整周期（分析→更新spec→spec确认→开发→验收→收尾） |
| `/spec-analyze` skill | 只读分析：代码审查、影响分析、问题诊断、方案评估，不修改任何文件 |
| `/spec-search` skill | 在 docs/plans/ 下快速检索内容，定位模块、接口、字段或任务 |
| `/spec-check` skill | 对技术方案文档执行健康检查，验证 spec 内部一致性与代码符合度 |
| `/spec-audit` skill | 对全量 spec 执行结构健康度审计，快速识别空章节、孤立任务、状态不一致等问题；输出 JSON 数据供仪表盘使用 |
| `/spec-dashboard` skill | 读取审计 JSON 数据，生成可浏览器打开的 HTML 仪表盘 |
| `/spec-init` skill | 已有项目的初始化：从代码逆向生成技术方案基线 |
| **`/whylog-record` skill** ★ | 记录开发过程中的决策依据、方案选择和需求变更，追加到 docs/decisions/log.md |
| `/whylog-review` skill | 按需查询和分析项目历史决策日志，支持主题检索、进展总结、过时识别 |
| `.doc-first.json` | 每个项目的配置文件，声明源码路径匹配规则与文档目录约定 |
| 仪表盘 | 静态 HTML 页面，展示模块进度、健康度评分和问题列表（由 /spec-dashboard 生成） |

---

## 安装 — 选择你的场景

### 环境依赖（安装前）

- 基础依赖：`git`
- 初始化脚本依赖：`python3` 或 `python`（用于生成 baseline spec）

可先自检：

```bash
git --version
python3 --version  # 或 python --version
```

### 场景一：已有项目（有代码）

已有项目需要先通过 `/spec-init` 从代码逆向生成技术方案基线，再开始日常开发。

**步骤 1：安装 skills（全局，一次性）**

```bash
cp -r skills/* ~/.claude/skills/
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

> 初始化只运行一次。完成后即可进入日常 `/spec-first` 流程。

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
cp -r skills/* ~/.claude/skills/
```

**步骤 2：初始化文档与项目配置**

```bash
cd <your-project>

# 复制项目配置（Java/Maven 项目）
cp examples/doc-first-java.json .doc-first.json
# 其他语言：
cp ~/.claude/skills/spec-first/assets/doc-first.json .doc-first.json

# 初始化文档目录
mkdir -p docs/plans
cp ~/.claude/skills/spec-first/assets/plans-PROJECT.md docs/plans/PROJECT.md
```

**步骤 3：更新 CLAUDE.md**

将 `~/.claude/skills/spec-first/assets/CLAUDE.md-snippet.md` 的内容追加到项目 `CLAUDE.md`，其中含 `<>` 占位符共 7 处（构建命令、启动时间、日志路径、认证命令、请求头等），请逐项填写后再继续。这些章节是必填的，`/spec-first` skill 的 Phase B.4 和 Phase C.1 会引用。

**步骤 4：验证安装**

```
/spec-first 测试安装是否正常
```

应看到文档选择器弹出。当前版本默认不启用 PreToolUse 拦截，先按 `/spec-first` 流程观察执行效果。

---

## .doc-first.json 配置参数

| 参数 | 类型 | 说明 | 省略时的默认值 |
|---|---|---|---|
| `sourcePatterns` | `string[]` | 正则数组，用于定义项目源码目录匹配规则 | `["src[/\\]"]` |
| `docDir` | `string` | 文档目录约定，用于 `/spec-first` 流程定位技术方案文档 | `"docs/plans/"` |

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
/spec-first <需求描述>
  │
  ├─ Step 0  匹配文档 → AskUserQuestion 选择器（最多3个 + Other）
  ├─ Step 1  判断当前阶段（A/B/C/D）
  │
  ├─ Phase A  A.1确认需求（含用户补充）→ A.2识别章节
  │           → A.3全量证据分析（spec/代码/DB/接口/日志/配置）
  │           → A.4改写+状态重置 → A.5新增T-xxx → A.6新增A-xxx
  │           → A.7质量检查 → 先展示确认材料（前后对照或最新spec）
  │           → AskUserQuestion 仅两项：确认通过 / 补充或澄清
  │              · 确认通过：进入 Phase B
  │              · 补充或澄清：回到 A.1 重新分析并更新 spec
  │
  ├─ Phase B  B.1依赖分析+执行计划 → B.2按批次并行执行
  │           → B.3偏差暂停 → B.4构建验证（参考CLAUDE.md）
  │
  ├─ Phase C  C.1启动+获取认证（参考CLAUDE.md）
  │           → C.2逐条执行A-xxx → C.3失败修复 → C.4非功能验收
  │
  └─ Phase D  D.1一致性检查 → D.2交付简报 → D.3运行 /whylog-record 记录决策
```

## 新建模块

运行 `/spec-first <需求>` 选择"Other → 新建文档"，skill 会自动使用标准 8 节骨架创建空白 spec。

或手动：

```bash
mkdir -p docs/plans/<module-name>
cp templates/tech-spec-blank.md docs/plans/<module-name>/<feature>-tech-spec.md
```

---

## 日常流程最小评估（建议）

为观察当前“无 hook、仅流程约束”模式是否稳定，建议在真实项目中按以下 3 个场景做最小评估：

- [ ] **场景 1：新需求进入 A 阶段并停在确认门**
  - 期望行为：能完成 A.1~A.7，并在未确认前停留在 spec 确认，不进入开发
  - 通过标准：出现确认材料展示 + AskUserQuestion 二选一；未出现任何代码修改动作
  - 失败标准：未展示确认材料即进入开发，或未确认即发生代码修改
- [ ] **场景 2：用户补充后回 A.1 重新分析**
  - 期望行为：明确触发 know why / know how，回到分析阶段，更新 spec 后再次确认
  - 通过标准：明确复述补充内容与新边界；流程回到 A.1~A.7 并重新确认
  - 失败标准：跳过重新分析直接开发，或未将补充内容体现在 spec 变更中
- [ ] **场景 3：确认通过后进入 B 阶段**
  - 期望行为：仅在“确认通过，开始开发”后进入 Phase B，开始任务执行
  - 通过标准：确认通过后才出现执行计划（B.1）与任务执行（B.2）
  - 失败标准：确认前提前进入 B 阶段，或确认后仍停留 A 阶段无推进

建议记录每个场景的结果（是否符合预期、偏差点、改进建议），连续观察一段时间后再决定是否恢复 hook。

---

## FAQ

**Q：现在还有 hook 拦截吗？**
A：默认不启用。当前版本先依赖 `/spec-first` 的阶段确认机制（spec 确认后再开发）来约束流程，便于你先观察真实执行效果。

**Q：macOS/Linux/Windows 现在还需要分别配置 hook 吗？**
A：不需要。默认模板已移除 PreToolUse hook 配置，不再区分 Bash/PowerShell 的 hook 安装步骤。

**Q：后续想恢复 hook 怎么办？**
A：可在项目 `.claude/settings.json` 重新添加 PreToolUse 配置，并恢复对应脚本后再启用。建议先观察一段时间流程执行数据，再决定是否回加。

**Q：monorepo 多个子项目能用吗？**
A：可以。每个子项目根目录分别放 `.doc-first.json` 与 `docs/plans/`，各自独立使用 `/spec-first` 流程。

**Q：/spec-first skill 如何知道构建命令和启动命令？**
A：Phase B.4 和 Phase C.1 会读取项目 `CLAUDE.md` 中的"构建命令"和"启动与认证"章节。这两个章节是必填项，使用 `templates/CLAUDE.md-snippet.md` 中的片段并填写实际命令。

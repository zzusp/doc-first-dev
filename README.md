# Doc-First Dev

**English:** Reusable **Agent Skills** for doc-first delivery — structured specs under `docs/plans/`, phased workflow from analysis to sign-off, plus optional **decision logging**. Works with agents listed on the [Agent Skills Directory](https://skills.sh/) (Claude Code, Cursor, Codex, and others that load skill folders).

**中文：** 将「文档先行」固化成可安装的 **Skills + 模板**：用技术方案驱动分析、开发、验收与收尾，并用决策日志沉淀「为什么这样做」。

| Skill 名称（`SKILL.md`） | 典型触发 | 一句话 |
|---|---|---|
| **`spec-first`** | `/spec-first <需求或变更描述>` | 全周期：匹配 spec → 更新方案 → 确认门 → 开发 → 验收 → 收尾 |
| **`whylog-record`** | 任务完成后主动记录 | 把决策与替代方案追加到 `docs/decisions/log.md` |

**许可证：** [MIT](LICENSE)  
**源码：** [github.com/zzusp/doc-first-dev](https://github.com/zzusp/doc-first-dev)

---

## 通过 [skills.sh](https://skills.sh/) 安装（推荐）

官方 CLI 为 [vercel-labs/skills](https://github.com/vercel-labs/skills)（文档见 [skills.sh/docs](https://skills.sh/docs)）。**命令是 `npx skills add`（`skills` 与 `add` 之间有空格）**，不是 `skillsadd`。

```bash
# 安装到当前项目或交互选择 Agent（默认行为以 CLI 提示为准）
npx skills add zzusp/doc-first-dev

# 仅查看本仓库提供哪些 skill（不安装）
npx skills add zzusp/doc-first-dev --list

# 只装其中一个，并装到全局（示例：Claude Code）
npx skills add zzusp/doc-first-dev --skill spec-first -g -a claude-code -y
```

本仓库在 `skills/` 下包含 **`spec-first`** 与 **`whylog-record`** 两个 skill，CLI 会分别安装到各 Agent 约定的 skills 目录。

### 「发布」到 skills.sh 榜单：你需要知道的事

**没有单独的「提交上架」表单。** [skills.sh 文档](https://skills.sh/docs) 说明：榜单依据 **匿名安装统计**（用户执行 `npx skills add <owner/repo>` 时由 CLI 上报，不收集个人信息）。因此「发布」= **保持 GitHub 仓库公开** + **把安装命令写进 README / 社交传播**，让别人愿意安装；安装次数会反映在排行榜上。

建议顺带做的几件事：

1. **推送最新代码到 `main`**，保证 GitHub 上的 `SKILL.md` 与描述为当前版本。  
2. 在 GitHub 仓库 **About** 里加 **Topics**，例如：`agent-skills`、`claude-code`、`cursor`、`doc-first`、`skills`，方便被发现。  
3. `npx skills find <关键词>` 的收录范围以 CLI 实现为准；新仓库可能需要一定传播与安装后才会在搜索里更容易看到。

---

## 手动安装（任意 Agent）

将本仓库的 `skills/` 下各 skill 目录复制到 Agent 的全局或项目 skills 目录（例如 Claude Code 常用 `~/.claude/skills/`；Cursor 等以各产品文档为准）。

```bash
# macOS / Linux
cp -r skills/* ~/.claude/skills/
```

```powershell
# Windows PowerShell（在 clone 后的仓库根目录的上一级执行，或把路径改成你的本地根目录）
git clone https://github.com/zzusp/doc-first-dev.git
Copy-Item -Path ".\doc-first-dev\skills\*" -Destination "$env:USERPROFILE\.claude\skills\" -Recurse -Force
```

安装后在业务项目根目录使用 `/spec-first …`（或当前产品约定的 skill 调用方式）。

---

## 仓库里有什么

```
doc-first-dev/
├── README.md
├── CLAUDE.md                       # 维护本仓库时的规则（给 AI agent 看）
├── LICENSE
├── skills/
│   ├── spec-first/                 ★ 文档驱动全周期
│   │   ├── SKILL.md                # 入口、进度 Checklist、前置检查
│   │   ├── init.md                 # 无 PROJECT.md 时初始化索引
│   │   ├── step0.md
│   │   ├── phase-a.md … phase-d.md
│   │   ├── error-handling.md
│   │   ├── assets/                 # claude-md-snippet、project-index、spec/API 模板
│   │   └── evals/                  # 评测场景（3 个主要路径）
│   └── whylog-record/              ★ 决策记录
│       ├── SKILL.md
│       └── evals/                  # 评测场景（记录 vs 跳过 边界）
└── reference/
    └── best-practices.md           # Skill 编写参考，修改 skill 前必读
```

---

## 为什么需要两套 Skill

| 维度 | **`spec-first`** | **`whylog-record`** |
|---|---|---|
| 回答的问题 | 项目**现在应该怎样**（需求、设计、任务、验收） | 我们是**如何走到这一步**的（决策、取舍、演变） |
| 主要产出 | `docs/plans/` 下的 spec 与索引 | `docs/decisions/log.md` |

两者一起用，更接近「可维护的文档化知识库」，而不是一次性生成的说明文。

---

## 新项目最小落地

1. **安装 skills**（见上节）。
2. 在目标项目中准备 `docs/plans/`（若缺失，部分流程会先由 `init.md` 生成 `PROJECT.md`，仍建议目录预先存在）。
3. 将 `spec-first/assets/claude-md-snippet.md` 合并进项目 `CLAUDE.md`，填好**构建**与**启动/认证**等与 Phase B.4、C.1 相关的段落。
4. 验证：`/spec-first` + 一句测试需求，应出现文档匹配或初始化提示。

---

## 日常流程（概览）

触发 `spec-first` 后应维护 **开发周期进度 Checklist**；阶段细节以仓库内 `step0.md`、`phase-a.md`～`phase-d.md` 为准。

```
/spec-first <需求描述>
  ├─ 前置：无 PROJECT.md → init → Step 0
  ├─ Step 0：文档匹配（选择器 + Other / 新建）
  ├─ Step 1：判定 A/B/C/D → 读取对应 phase 文档
  ├─ Phase A：分析并更新 spec → 确认门
  ├─ Phase B：计划与实现 → 构建验证（CLAUDE.md）
  ├─ Phase C：启动/认证 → 验收项
  └─ Phase D：一致性 → 交付简报
```

**新建模块：** 在 `/spec-first` 中选「Other → 新建文档」，或复制 `assets/tech-spec-blank.md` 到 `docs/plans/<module>/`。

---

## 流程健康度自检（建议）

- 新需求是否在 **未确认 spec 前**不擅自改代码？
- 用户补充需求后，是否 **回到分析**并再次确认？
- 是否在 **明确确认通过** 后才进入开发与任务执行？

更细场景见 `skills/spec-first/evals/`。

---

## FAQ

**Q：还依赖 PreToolUse hook 吗？**  
A：默认不启用；以 skill 内阶段与确认门为主，需要时可自行在 `.claude/settings` 等配置中恢复 hook。

**Q：monorepo 多包怎么用？**  
A：每个子项目根目录各自维护 `docs/plans/` 即可。

**Q：构建/启动命令从哪里来？**  
A：`spec-first` 的 B.4 / C.1 会读项目 `CLAUDE.md` 中由片段模板约定的章节。

**Q：模块索引文件叫什么？**  
A：默认识别 `docs/plans/PROJECT.md`；若你在 `CLAUDE.md` 里约定了别的索引路径，以约定为准。

**Q：和 [skills.sh](https://skills.sh/) 上其他 skill 的关系？**  
A：本仓库专注 **doc-first 交付与决策记录**；可与目录中的其他能力（测试、设计系统等）并列安装，由 Agent 按描述与上下文选用。

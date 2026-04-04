# generate-baseline-specs.ps1
# 读取 docs/plans/README.md 中的功能清单，为每个模块生成基线 spec
#
# 依赖：PowerShell 5.0+
# 平台：Windows

$ErrorActionPreference = "Stop"

$ProjectRoot = if ($args[0]) { $args[0] } else { $PWD.ProviderPath }
Set-Location $ProjectRoot

# ── 检查前置条件 ─────────────────────────────────────────────────────────────
if (-not (Test-Path "docs/plans/README.md")) {
    Write-Host "[generate-baseline-specs] 错误：未找到 docs/plans/README.md，请先运行 /spec-init Step 2" -ForegroundColor Red
    exit 1
}

# ── 辅助函数 ────────────────────────────────────────────────────────────────
function Get-GitCommitHash {
    try {
        git rev-parse --short HEAD 2>$null
    } catch {
        "unknown"
    }
}

# ── 解析 README.md 中的模块列表 ─────────────────────────────────────────────
$readmeLines = Get-Content "docs/plans/README.md" -Encoding UTF8
$modules = @()
$currentModule = $null

foreach ($line in $readmeLines) {
    # 一级模块：加粗数字编号开头（如 "| **1. 用户管理** |"）
    if ($line -match '^\|\s*\*\*[0-9]+\.\s+([^*]+)\*\*') {
        $currentModule = $matches[1].Trim()
        $modules += $currentModule
    }
}

if ($modules.Count -eq 0) {
    Write-Host "[generate-baseline-specs] 错误：未从 README.md 中提取到模块列表" -ForegroundColor Red
    exit 1
}

# ── 生成单个模块的 baseline spec ────────────────────────────────────────────
$gitHash = Get-GitCommitHash

foreach ($module in $modules) {
    $moduleDir = Join-Path "docs/plans" $module
    $specFile = Join-Path $moduleDir "${module}-tech-spec.md"

    if (-not (Test-Path $moduleDir)) {
        New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
    }

    $specContent = @"
# ${module} 技术方案

> **文档目的**：记录 ${module} 的需求、架构方案、代码结构、任务进度与验收情况。
> 本文档始终反映**当前状态**，不记录变更历史。
>
> **关联文档**：
> - \`docs/decisions/log.md\` — 开发决策记录（via \`/whylog-record\`）

---

## 一、需求边界

### 1.1 业务背景

<!-- 详情见 docs/plans/init-report.md -->

### 1.2 核心需求

| 功能点 | 相关接口 | 数据表 |
|---|---|---|
<!-- 功能点从 README.md 动态填充 -->

### 1.3 明确排除范围

> 待补充

---

## 二、数据库设计

> 待补充（如需补充，请提供数据库连接信息后使用 /spec-init 重新生成，或手动填写）

---

## 三、接口规范

> 待补充（可基于代码中的接口定义手动填写）

---

## 四、架构与设计规则

### 4.1 模块关系

> 待补充

### 4.2 设计规则

> 仅列出代码注释或常量中明确写出的规则

---

## 五、代码地图

### 5.1 关键文件

| 文件路径 | 职责 |
|---|---|
| \`src/<path>/\` | <!-- 待补充 --> |

### 5.2 关键方法

| 方法签名 | 做什么 |
|---|---|
| | |

---

## 六、任务状态

| 编号 | 描述（文件 + 方法/节点） | 优先级 | 状态 |
|---|---|---|---|
| T-01 | 建立初始基线文档 | — | ✅ 完成 |

> 基线版本：对应代码版本 \`${gitHash}\`

---

## 七、验收项

### Phase 0 — 基线验收

> 本模块基线版本验收（现状通过）

| 编号 | 名称 | 关联任务 | 断言 | 状态 |
|---|---|---|---|---|
| A-01 | 基线验收 | T-01 | 现状通过（未进行功能测试） | ✅ |

### Phase 1 — 非功能验收

| 编号 | 名称 | 关联任务 | 断言 | 状态 |
|---|---|---|---|---|
| A-NF-01 | 构建通过 | — | 运行构建命令无报错 | 待验证 |
| A-NF-02 | 应用启动 | — | 启动后健康检查接口返回 200 | 待验证 |

---

## 八、附录

> 按需补充
"@

    $specContent | Out-File -FilePath $specFile -Encoding UTF8 -NoNewline
    Write-Host "[generate-baseline-specs] 生成：$specFile" -ForegroundColor Green
}

# ── 验证生成结果 ─────────────────────────────────────────────────────────────
$failed = 0
foreach ($module in $modules) {
    $specFile = Join-Path "docs/plans/$module" "${module}-tech-spec.md"
    if (-not (Test-Path $specFile)) {
        Write-Host "[generate-baseline-specs] 验证失败：$specFile 未生成" -ForegroundColor Red
        $failed = 1
    } elseif ((Get-Item $specFile).Length -eq 0) {
        Write-Host "[generate-baseline-specs] 验证失败：$specFile 为空" -ForegroundColor Red
        $failed = 1
    }
}

if ($failed -eq 1) {
    Write-Host "[generate-baseline-specs] 错误：部分文件生成失败，请检查目录权限或 README.md 格式" -ForegroundColor Red
    exit 1
}

Write-Host "[generate-baseline-specs] 验证通过：所有文件生成成功" -ForegroundColor Green
Write-Host ""
Write-Host "[generate-baseline-specs] 完成，共生成 $($modules.Count) 个模块的基线 spec" -ForegroundColor Cyan

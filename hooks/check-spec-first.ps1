# check-spec-first.ps1
# PreToolUse hook：在修改源文件前，检查是否已更新技术方案文档
#
# 通过读取项目根目录的 .doc-first.json 获取配置，支持多语言/多框架：
#
# .doc-first.json 示例：
# {
#   "sourcePatterns": ["src[/\\\\](main|test)[/\\\\]java"],
#   "docDir": "docs/plans/"
# }
#
# 若项目根目录不存在 .doc-first.json，直接放行（不拦截）。
# 这意味着未启用 doc-first 框架的项目完全不受影响。

$ErrorActionPreference = "Stop"

# ── 读取工具调用参数 ────────────────────────────────────────────────────────
$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) { exit 0 }

try {
    $toolInput = $rawInput | ConvertFrom-Json
} catch {
    exit 0
}

$filePath = $toolInput.file_path
if (-not $filePath) { exit 0 }

# ── 查找项目根目录（含 .doc-first.json 的最近祖先目录）────────────────────
function Find-ProjectRoot {
    param([string]$StartDir)
    $dir = $StartDir
    for ($i = 0; $i -lt 12; $i++) {
        if (Test-Path (Join-Path $dir ".doc-first.json")) { return $dir }
        $parent = Split-Path -Parent $dir
        if ($parent -eq $dir) { return $null }
        $dir = $parent
    }
    return $null
}

# 先从 hook 脚本所在目录向上找，再从目标文件路径向上找
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Find-ProjectRoot -StartDir $scriptDir
if (-not $projectRoot) {
    $fileDir = Split-Path -Parent $filePath
    $projectRoot = Find-ProjectRoot -StartDir $fileDir
}

# 未找到配置文件 → 放行（项目未启用框架）
if (-not $projectRoot) { exit 0 }

# ── 读取配置 ────────────────────────────────────────────────────────────────
$configFile = Join-Path $projectRoot ".doc-first.json"
try {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
} catch {
    Write-Host "[doc-first] 警告：.doc-first.json 解析失败，已跳过检查。" -ForegroundColor Yellow
    exit 0
}

$sourcePatterns = if ($config.sourcePatterns) { $config.sourcePatterns } else { @("src[/\\]") }
$docDir         = if ($config.docDir)         { $config.docDir }         else { "docs/plans/" }

# ── 检查目标文件是否匹配受保护的源码路径 ────────────────────────────────────
$isSourceFile = $false
foreach ($pattern in $sourcePatterns) {
    if ($filePath -match $pattern) { $isSourceFile = $true; break }
}
if (-not $isSourceFile) { exit 0 }

# ── 检查文档目录是否有未提交变更 ────────────────────────────────────────────
Push-Location $projectRoot
try {
    $unstaged    = git diff --name-only 2>$null
    $staged      = git diff --cached --name-only 2>$null
    $allDiff     = @($unstaged) + @($staged) | Where-Object { $_ }
    $docPattern  = "^" + [regex]::Escape($docDir).Replace("/", "[/\\]")
    $specChanged = $allDiff | Where-Object { $_ -match $docPattern }
} finally {
    Pop-Location
}

if (-not $specChanged) {
    $docDirDisplay = $docDir.TrimEnd('/').TrimEnd('\')

    # 尝试读取模块列表，增强提示信息
    $readmePath = Join-Path $projectRoot "docs\plans\README.md"
    $moduleHint = ""
    if (Test-Path $readmePath) {
        $readmeLines = Get-Content $readmePath -Encoding UTF8
        $moduleNames = @()
        foreach ($line in $readmeLines) {
            # 提取表格第一列中的加粗模块名（如 "| **1. 用户管理** | ..."）
            if ($line -match '^\|\s*\*\*[^*]+\*\*') {
                $m = [regex]::Match($line, '\*\*([^*]+)\*\*')
                if ($m.Success -and $m.Groups[1].Value -notmatch '模块|功能|技术方案') {
                    $moduleNames += $m.Groups[1].Value.Trim()
                }
            }
        }
        if ($moduleNames.Count -gt 0) {
            $moduleHint = "当前模块：" + ($moduleNames -join " · ")
        }
    }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗"
    Write-Host "║  文档先行：尚未更新技术方案文档                                ║"
    Write-Host "╠══════════════════════════════════════════════════════════╣"
    Write-Host "║  检测到即将修改源文件，但 $($docDirDisplay) 下              ║"
    Write-Host "║  尚无未提交的变更。                                         ║"
    Write-Host "║                                                          ║"
    if ($moduleHint) {
        Write-Host "║  $($moduleHint)"
        Write-Host "║                                                          ║"
    }
    Write-Host "║  请先运行 /spec <需求描述> 更新技术方案文档，                  ║"
    Write-Host "║  完成后即可继续代码修改。                                     ║"
    Write-Host "╚══════════════════════════════════════════════════════════╝"
    Write-Host ""
    exit 2
}

exit 0

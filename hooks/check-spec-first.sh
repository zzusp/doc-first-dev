#!/usr/bin/env bash
# check-spec-first.sh
# PreToolUse hook（bash版）：在修改源文件前，检查是否已更新技术方案文档
#
# 依赖：bash >= 4, jq
# 跨平台：Linux, macOS, Windows Git Bash / MSYS2 / MinGW
#
# 若项目根目录不存在 .doc-first.json，直接放行（不拦截）。
# 这意味着未启用 doc-first 框架的项目完全不受影响。

set -euo pipefail

# ── 检查依赖 ────────────────────────────────────────────────────────────────
check_dep() {
    if ! command -v jq &>/dev/null; then
        echo "[doc-first] 警告：jq 未安装，已跳过检查。" >&2
        exit 0
    fi
}
check_dep

# ── 读取工具调用参数 ────────────────────────────────────────────────────────
raw_input=$(cat)
if [[ -z "$raw_input" ]]; then
    exit 0
fi

file_path=$(echo "$raw_input" | jq -r '.file_path // empty')
if [[ -z "$file_path" ]]; then
    exit 0
fi

# ── Windows MSYS2/MinGW 路径转换 ────────────────────────────────────────────
# MSYS2 的 bash 可能收到 Windows 路径（如 D:\project\...），需转换为 Unix 风格
if [[ "$file_path" =~ ^[A-Za-z]: ]]; then
    file_path=$(cygpath -u "$file_path" 2>/dev/null || echo "$file_path")
fi

# ── 查找项目根目录 ─────────────────────────────────────────────────────────
find_project_root() {
    local start_dir="$1"
    local dir="$start_dir"
    for ((i=0; i<12; i++)); do
        if [[ -f "$dir/.doc-first.json" ]]; then
            echo "$dir"
            return 0
        fi
        local parent=$(cd "$dir/.." && pwd)
        if [[ "$parent" == "$dir" ]]; then
            return 1
        fi
        dir="$parent"
    done
    return 1
}

# 从 hook 脚本所在目录向上找
script_dir="$(cd "$(dirname "$0")/.." && pwd)"
project_root=$(find_project_root "$script_dir")

# 若未找到，从目标文件路径向上找
if [[ -z "$project_root" ]]; then
    file_dir=$(dirname "$file_path")
    project_root=$(find_project_root "$file_dir")
fi

# 未找到配置文件 → 放行
if [[ -z "$project_root" ]]; then
    exit 0
fi

# ── 读取配置 ────────────────────────────────────────────────────────────────
config_file="$project_root/.doc-first.json"

# 尝试用 jq 解析，失败则放行
source_patterns_raw=$(jq -r '.sourcePatterns // ["src[/\\]"] | if type == "array" then . else [.] end' "$config_file" 2>/dev/null) || {
    echo "[doc-first] 警告：.doc-first.json 解析失败，已跳过检查。" >&2
    exit 0
}

# jq 返回的数组是多行 JSON，需要重新解析为 shell 数组
IFS=$'\n' read -r -d '' -a source_patterns <<< "$(jq -r '.sourcePatterns // ["src[/\\]"] | .[]' "$config_file" 2>/dev/null)" || true
if [[ ${#source_patterns[@]} -eq 0 ]]; then
    source_patterns=("src[/\\]")
fi

doc_dir=$(jq -r '.docDir // "docs/plans/"' "$config_file" 2>/dev/null)

# ── 检查目标文件是否匹配受保护的源码路径 ────────────────────────────────────
is_source_file=false
for pattern in "${source_patterns[@]}"; do
    # 将 bash 正则中的双反斜杠替换为单反斜杠，适配 Windows 路径
    pattern_fixed="${pattern//\\\/$/\/}"
    if [[ "$file_path" =~ $pattern_fixed ]]; then
        is_source_file=true
        break
    fi
done

if [[ "$is_source_file" != true ]]; then
    exit 0
fi

# ── 检查文档目录是否有未提交变更 ────────────────────────────────────────────
cd "$project_root"

unstaged=$(git diff --name-only 2>/dev/null || echo "")
staged=$(git diff --cached --name-only 2>/dev/null || echo "")
all_diff=$((echo "$unstaged"; echo "$staged") | grep -v '^$')

# 将 docDir 的正斜杠转为可匹配正斜杠或反斜杠的正则
doc_pattern=$(echo "$doc_dir" | sed 's/[/\]$//' | sed 's/\//\//g')
doc_pattern="^${doc_pattern}"

spec_changed=$(echo "$all_diff" | grep -E "$doc_pattern" || true)

if [[ -z "$spec_changed" ]]; then
    doc_dir_display=$(echo "$doc_dir" | sed 's/[/\]$//')

    # 尝试读取模块列表，增强提示信息
    module_hint=""
    readme_path="$project_root/docs/plans/README.md"
    if [[ -f "$readme_path" ]] && command -v grep &>/dev/null; then
        # 提取表格第一列的加粗模块名（如 "| **1. 用户管理** | ..."）
        module_names=$(grep -oE '\*\*[^*]+\*\*' "$readme_path" 2>/dev/null \
            | grep -v '模块\|功能\|技术方案' \
            | sed 's/\*\*//g' \
            | tr '\n' '·' \
            | sed 's/·$//')
        if [[ -n "$module_names" ]]; then
            module_hint="当前模块：$module_names"
        fi
    fi

    cat << 'EOF'

╔══════════════════════════════════════════════════════════╗
║  文档先行：尚未更新技术方案文档                                ║
╠══════════════════════════════════════════════════════════╣
EOF
    printf '║  检测到即将修改源文件，但 %s 下              ║\n' "$doc_dir_display"
    cat << 'EOF'
║  尚无未提交的变更。                                         ║
║                                                          ║
EOF
    if [[ -n "$module_hint" ]]; then
        printf '║  %s\n' "$module_hint"
        cat << 'EOF'
║                                                          ║
EOF
    fi
    cat << 'EOF'
║  请先运行 /spec <需求描述> 更新技术方案文档，                  ║
║  完成后即可继续代码修改。                                     ║
╚══════════════════════════════════════════════════════════╝

EOF
    exit 2
fi

exit 0

#!/usr/bin/env bash
# generate-baseline-specs.sh
# 读取 docs/plans/README.md 中的功能清单，为每个模块生成基线 spec
#
# 依赖：bash >= 4, coreutils (grep, sed, awk)
# 跨平台：Linux, macOS, Windows Git Bash / MSYS2 / MinGW

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="${1:-.}"

cd "$PROJECT_ROOT"

# ── 检查前置条件 ──────────────────────────────────────────────────────────────
if [[ ! -f "docs/plans/README.md" ]]; then
    echo "[generate-baseline-specs] 错误：未找到 docs/plans/README.md，请先运行 /spec-init Step 2" >&2
    exit 1
fi

# ── 辅助函数 ────────────────────────────────────────────────────────────────
git_commit_hash() {
    git rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

# ── 解析 README.md 中的功能清单 ─────────────────────────────────────────────
# 提取功能清单总表后的表格行，跳过表头和分隔符
extract_modules() {
    local in_table=0
    local first_col=""
    local second_col=""
    local third_col=""
    local fourth_col=""
    local current_module=""
    local current_submodule=""

    while IFS= read -r line; do
        # 检测表格开始
        if [[ "$line" =~ \|一.*级.*模.*块\| ]]; then
            in_table=1
            continue
        fi
        # 检测表格结束（--- 分隔符或新的 ## 标题）
        if [[ $in_table -eq 1 ]] && [[ "$line" =~ ^\|[-:\ ]+\| ]] || [[ "$line" =~ ^## ]]; then
            in_table=0
            continue
        fi

        if [[ $in_table -eq 1 ]] && [[ "$line" =~ ^\| ]]; then
            # 解析表格列
            first_col=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/\*\*//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            second_col=$(echo "$line" | awk -F'|' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            third_col=$(echo "$line" | awk -F'|' '{print $4}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            fourth_col=$(echo "$line" | awk -F'|' '{print $5}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # 一级模块（加粗数字编号开头）
            if [[ "$first_col" =~ ^[0-9]+\.[[:space:]]  ]]; then
                current_module="$second_col"
                echo "MODULE:$current_module"
            # 二级模块（空第一列）
            elif [[ -z "$first_col" ]] && [[ -n "$second_col" ]]; then
                current_submodule="$second_col"
            fi
        fi
    done < "docs/plans/README.md"
}

# ── 生成单个模块的 baseline spec ─────────────────────────────────────────────
generate_module_spec() {
    local module_name="$1"
    local module_dir="docs/plans/${module_name}"
    local spec_file="${module_dir}/${module_name}-tech-spec.md"

    # 创建目录
    mkdir -p "$module_dir"

    local git_hash=$(git_commit_hash)

    # 生成 spec 内容
    cat > "$spec_file" << SPECEOF
# ${module_name} 技术方案

> **文档目的**：记录 ${module_name} 的需求、架构方案、代码结构、任务进度与验收情况。
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

> 基线版本：对应代码版本 \`${git_hash}\`

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
SPECEOF

    echo "[generate-baseline-specs] 生成：$spec_file"
}

# ── 主流程 ───────────────────────────────────────────────────────────────────
echo "[generate-baseline-specs] 开始生成基线 spec..."
echo "[generate-baseline-specs] 项目根目录：$(pwd)"

# 提取并去重模块列表
modules=$(extract_modules | grep "^MODULE:" | sed 's/^MODULE://' | sort -u)

if [[ -z "$modules" ]]; then
    echo "[generate-baseline-specs] 错误：未从 README.md 中提取到模块列表" >&2
    exit 1
fi

echo "[generate-baseline-specs] 发现 $(echo "$modules" | wc -l) 个模块"

for module in $modules; do
    generate_module_spec "$module"
done

# ── 验证生成结果 ─────────────────────────────────────────────────────────────
failed=0
for module in $modules; do
    local spec_file="docs/plans/${module}/${module}-tech-spec.md"
    if [[ ! -f "$spec_file" ]]; then
        echo "[generate-baseline-specs] 验证失败：$spec_file 未生成" >&2
        failed=1
    elif [[ ! -s "$spec_file" ]]; then
        echo "[generate-baseline-specs] 验证失败：$spec_file 为空" >&2
        failed=1
    fi
done

if [[ $failed -eq 1 ]]; then
    echo "[generate-baseline-specs] 错误：部分文件生成失败，请检查目录权限或 README.md 格式" >&2
    exit 1
fi

echo "[generate-baseline-specs] 验证通过：所有文件生成成功"
echo "[generate-baseline-specs] 完成，共生成 $(echo "$modules" | wc -l) 个模块的基线 spec"

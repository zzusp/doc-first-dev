#!/usr/bin/env python3
"""读取 docs/plans/PROJECT.md 中的功能清单，为每个模块生成基线 spec。"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


def git_commit_hash(project_root: Path) -> str:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=project_root,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        return out.strip() or "unknown"
    except Exception:
        return "unknown"


def extract_modules(readme_path: Path) -> list[str]:
    lines = readme_path.read_text(encoding="utf-8").splitlines()
    modules: list[str] = []
    in_table = False

    header_reached = False
    for line in lines:
        if "一级模块" in line and "二级模块" in line and "技术方案" in line:
            in_table = True
            header_reached = True
            continue

        if not in_table:
            continue

        if line.startswith("## "):
            break

        if not line.startswith("|"):
            continue

        # 跳过分隔行
        if re.match(r"^\|[-:\s|]+\|$", line):
            continue

        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) < 4:
            continue

        first_col = cols[0].replace("**", "").strip()
        m = re.match(r"^(\d+)\.\s+(.+)$", first_col)
        if m:
            module_name = m.group(2).strip()
            if module_name and module_name not in modules:
                modules.append(module_name)

    if not header_reached:
        return []
    return modules


def build_spec(module_name: str, git_hash: str) -> str:
    return f"""# {module_name} 技术方案

> **文档目的**：记录 {module_name} 的需求、架构方案、代码结构、任务进度与验收情况。
> 本文档始终反映**当前状态**，不记录变更历史。
>
> **关联文档**：
> - `docs/decisions/log.md` — 开发决策记录（via `/whylog-record`）

---

## 一、需求边界

### 1.1 业务背景

<!-- 详情见 docs/plans/init-report.md -->

### 1.2 核心需求

| 功能点 | 相关接口 | 数据表 |
|---|---|---|
<!-- 功能点从 PROJECT.md 动态填充 -->

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
| `src/<path>/` | <!-- 待补充 --> |

### 5.2 关键方法

| 方法签名 | 做什么 |
|---|---|
| | |

---

## 六、任务状态

| 编号 | 描述（文件 + 方法/节点） | 优先级 | 状态 |
|---|---|---|---|
| T-01 | 建立初始基线文档 | — | ✅ 完成 |

> 基线版本：对应代码版本 `{git_hash}`

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
"""


def main() -> int:
    project_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    readme_path = project_root / "docs" / "plans" / "PROJECT.md"

    if not readme_path.exists():
        print("[generate-baseline-specs] 错误：未找到 docs/plans/PROJECT.md，请先运行 /spec-init Step 2", file=sys.stderr)
        return 1

    modules = extract_modules(readme_path)
    if not modules:
        print("[generate-baseline-specs] 错误：未从 PROJECT.md 中提取到模块列表", file=sys.stderr)
        return 1

    print("[generate-baseline-specs] 开始生成基线 spec...")
    print(f"[generate-baseline-specs] 项目根目录：{project_root}")
    print(f"[generate-baseline-specs] 发现 {len(modules)} 个模块")

    git_hash = git_commit_hash(project_root)

    failed = False
    for module in modules:
        module_dir = project_root / "docs" / "plans" / module
        spec_file = module_dir / f"{module}-tech-spec.md"
        module_dir.mkdir(parents=True, exist_ok=True)
        spec_file.write_text(build_spec(module, git_hash), encoding="utf-8")
        print(f"[generate-baseline-specs] 生成：{spec_file.relative_to(project_root)}")

    for module in modules:
        spec_file = project_root / "docs" / "plans" / module / f"{module}-tech-spec.md"
        if (not spec_file.exists()) or spec_file.stat().st_size == 0:
            print(f"[generate-baseline-specs] 验证失败：{spec_file.relative_to(project_root)}", file=sys.stderr)
            failed = True

    if failed:
        print("[generate-baseline-specs] 错误：部分文件生成失败，请检查目录权限或 PROJECT.md 格式", file=sys.stderr)
        return 1

    print("[generate-baseline-specs] 验证通过：所有文件生成成功")
    print(f"[generate-baseline-specs] 完成，共生成 {len(modules)} 个模块的基线 spec")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

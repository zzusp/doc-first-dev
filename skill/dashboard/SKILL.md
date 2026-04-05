---
name: spec-dashboard
description: 读取 /spec-audit 生成的 JSON 数据，生成可浏览器打开的仪表盘 HTML 页面。当用户运行 /spec-dashboard、或需要生成 spec 健康度可视化仪表盘时触发。
---

# /spec-dashboard — Spec 仪表盘生成

读取审计数据，生成可视化的 HTML 仪表盘页面。

**前置条件：** 已运行过 `/spec-audit`，且 `docs/plans/dashboard-data.json` 文件存在。

---

## 内容目录
- [Step 0 — 确认数据文件](#step-0)
- [Step 1 — 生成仪表盘](#step-1)
- [Step 2 — 输出结果](#step-2)

---

## Step 0 — 确认数据文件

### 0.1 查找 JSON 数据

按以下优先级查找数据文件：

1. 用户指定路径（如 `/spec-dashboard docs/plans/data.json`）
2. `docs/plans/dashboard-data.json`
3. `docs/plans/` 下最新的 `.json` 文件

### 0.2 验证文件格式

读取 JSON 文件，验证包含必要字段：

```json
{
  "timestamp": "...",
  "modules": [...],
  "issues": [...]
}
```

若文件不存在或格式异常，输出提示：

```
⚠️ 未找到仪表盘数据
请先运行 /spec-audit 生成审计数据。
```

---

## Step 1 — 生成仪表盘

### 1.1 读取模板

读取 `templates/dashboard/index.html` 作为基础模板。

若模板不存在，输出提示后尝试使用内嵌的简化模板。

### 1.2 替换数据

将 JSON 数据注入模板的 `<!--SPEC_DATA-->` 占位符：

```html
<script id="spec-data" type="application/json">
<!--SPEC_DATA-->
</script>
```

替换为：

```html
<script id="spec-data" type="application/json">
{JSON.stringify(data, null, 2)}
</script>
```

### 1.3 更新元信息

将 `<!--LAST_UPDATED-->` 替换为 JSON 中的 `timestamp`。
将 `<!--PROJECT_ROOT-->` 替换为 JSON 中的 `projectRoot`。

---

## Step 2 — 输出结果

### 2.1 确定输出路径

默认输出到 `docs/plans/dashboard.html`。

若文件已存在，询问用户是否覆盖：

```json
{
  "question": "dashboard.html 已存在，是否覆盖？",
  "options": [
    { "label": "覆盖", "description": "用新数据覆盖现有文件" },
    { "label": "保留", "description": "不修改现有文件" }
  ]
}
```

### 2.2 写入文件

将生成的 HTML 写入目标路径。

### 2.3 输出指引

```
┌─ Spec 仪表盘已生成 ─────────────────────────────
│  路径：docs/plans/dashboard.html
│  数据时间：<timestamp>
│  模块数：<N>
│  健康度评分：<score>
│
│  用浏览器打开 HTML 文件查看可视化仪表盘。
│  重新生成：先运行 /spec-audit，再运行 /spec-dashboard
└───────────────────────────────────────────────────
```

---

## 仪表盘展示内容

| 区域 | 说明 |
|------|------|
| 统计卡片 | 模块总数、健康/警告/严重模块数、待完成任务/验收项数 |
| 健康度评分 | 0-100 分，彩色圆圈展示 |
| 模块列表 | 各模块状态、任务进度（T: done/total）、验收进度（A: done/total） |
| 问题列表 | 按类型分类的问题清单 |

---

## 与 `/spec-audit` 的配合

```
/spec-audit   → 生成 dashboard-data.json（含审计结果）
      ↓
/spec-dashboard → 读取 JSON，生成 dashboard.html
      ↓
浏览器打开     → 查看可视化仪表盘
```

# init — 多服务项目初始化

首次使用 `/spec-multi` 且 `docs/plans/SERVICES.md` 不存在时执行。

## 步骤

### 1. 扫描子目录识别服务

扫描 workspace root 下各子目录，识别含以下特征文件的目录作为候选服务：

| 特征文件 | 推断技术栈 |
|---|---|
| `package.json` + `next.config.*` | Next.js |
| `package.json` + `vite.config.*` | React/Vue/Vite |
| `package.json`（无前端框架配置） | Node.js |
| `go.mod` | Golang |
| `requirements.txt` / `pyproject.toml` / `uv.lock` | Python |
| `pom.xml` | Java/Maven |
| `build.gradle` | Java/Gradle |
| `Cargo.toml` | Rust |

跳过：`.git`、`node_modules`、`dist`、`build`、`__pycache__`、`.venv` 等构建/依赖目录。

### 2. 展示识别结果，逐项确认

列出识别到的候选服务，询问用户：

```
识别到以下目录可能是服务，请确认或修改：

1. ./backend — Node.js（package.json）— 是否作为服务？[Y/n] 服务名？端口？启动命令？
2. ./frontend — React/Vite（vite.config.ts）— ...
3. ./data-service — Python（requirements.txt）— ...
```

对每个确认的服务收集：
- **服务名**（用于 `[服务名]` 标签，建议小写+连字符，如 `backend`、`data-service`）
- **启动命令**（如 `npm run dev`、`uvicorn main:app --reload`）
- **监听端口**

### 3. 确认服务间依赖关系

询问："哪些服务依赖其他服务？（用于确定启动顺序和开发顺序）"

示例回答：`frontend 依赖 backend，backend 依赖 data-service`

### 4. 生成 SERVICES.md

根据收集信息，从 [assets/services-index-blank.md](assets/services-index-blank.md) 生成 `docs/plans/SERVICES.md`。

创建 `docs/plans/requirements/` 目录（若不存在）用于存放需求文档。

### 5. 完成

告知用户 SERVICES.md 已生成，返回 [step0.md](step0.md) 继续接收需求。

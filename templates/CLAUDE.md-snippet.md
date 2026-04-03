# CLAUDE.md 片段 — 粘贴到项目 CLAUDE.md 中

将以下内容追加到项目的 CLAUDE.md，并替换尖括号中的占位符。

---

## 构建命令

```bash
# 填写项目的构建/编译/类型检查命令
# /spec skill 的 Phase B.4 构建验证会引用此处

# Java/Maven 示例：
# JAVA_HOME="/path/to/jdk" mvn compile -q

# Node.js 示例：
# npm run build
# npm run typecheck

# Python 示例：
# mypy src/

# Go 示例：
# go build ./...
```

## 启动与认证

> /spec skill 的 Phase C.1 验收准备会引用此处。

### 启动应用

```bash
# 填写本地启动命令
# 示例：
# .\scripts\start-app.ps1
# docker compose up -d
# npm run dev
```

预期启动时间：`<X 秒 / X 分钟>`

启动日志位置：`<日志路径，如有>`

### 获取认证 Token

```bash
# 填写获取测试用 token 的命令
# 示例：
# LOGIN_PASSWORD='your-password' python scripts/login.py
# curl -X POST http://localhost:8080/auth/login \
#   -H "Content-Type: application/json" \
#   -d '{"username":"admin","password":"xxx"}'
```

### 必要的请求头

验收时需要保存以下 Header（从登录响应中提取）：

- `Authorization`：Bearer token
- `<其他项目特定 Header>`

## 文档驱动开发规则

本项目启用文档先行（doc-first）开发规范，由 `/spec` skill 驱动：

1. 任何需求变更、功能新增、Bug 修复，必须先运行 `/spec <需求描述>` 更新技术方案，再开始编码。
2. 技术方案文档位于 `docs/plans/`，模块索引见 `docs/plans/README.md`。
3. spec 文档记录**当前状态**，不记录变更历史——直接改写旧内容。
4. spec 更新和代码变更放在同一次 git commit 中。
5. spec 与实际代码不一致时，停止并向用户说明差异，等确认后再继续。

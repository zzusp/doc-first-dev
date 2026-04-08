# 语言与框架扫描规则

## 内容目录
- [Java（Spring）](#java-spring)
- [Node.js（Express/Koa）](#nodejs-expresskoa)
- [Python（FastAPI/Django）](#python-fastapidjango)
- [Go](#go)
- [C# / .NET](#c--net)
- [Rust](#rust)
- [Kubernetes / Helm](#kubernetes--helm)

---

## Java（Spring）

### 通用规则

| 文件类型 | 扫描内容 | 路径模式 |
|---|---|---|
| Controller | 接口路径、HTTP 方法、参数名 | `**/*Controller.java` |
| Service | 业务方法签名 | `**/*Service.java` |
| Entity | 字段名、类型、注解约束 | `**/*Entity.java` / `**/*DO.java` |
| Mapper XML | SQL 映射、字段关联 | `**/*Mapper.xml` |

### 注解信号

| 注解 | 含义 |
|---|---|
| `@RestController` / `@Controller` | Controller 类 |
| `@RequestMapping`, `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping` | 接口路径和方法 |
| `@Service` | Service 类 |
| `@Entity` / `@Table(name="xxx")` | 数据库表映射 |
| `@Column(name="xxx")` | 数据库字段映射 |
| `@NotNull`, `@NotBlank`, `@Valid` | 参数校验约束 |
| `@Mapper` | MyBatis Mapper 接口 |

### 路由推断示例

```java
@RestController
@RequestMapping("/api/user")   // → 一级路径：/api/user
public class UserController {
    @GetMapping("/list")       // → 接口：GET /api/user/list
    @PostMapping("/save")      // → 接口：POST /api/user/save
}
```

---

## Node.js（Express/Koa）

### 通用规则

| 文件类型 | 扫描内容 | 路径模式 |
|---|---|---|
| Router | 接口路径、HTTP 方法 | `**/router*.js` / `**/routes/*.js` |
| Controller | 业务逻辑处理 | `**/controllers/*.js` |
| Model | 数据模型定义 | `**/models/*.js` |

### 路由信号

```javascript
router.get('/user/list', ...)   // → 接口：GET /user/list
router.post('/user/save', ...)  // → 接口：POST /user/save
app.get('/api/item', ...)       // → 接口：GET /api/item
```

---

## Python（FastAPI/Django）

### FastAPI

| 注解 | 含义 |
|---|---|
| `@app.get`, `@app.post`, `@app.put`, `@app.delete` | 接口路径和方法 |
| `@app.router.get` | 路由定义 |

```python
@app.get("/user/list")          # → 接口：GET /user/list
@app.post("/user/save")        # → 接口：POST /user/save
```

### Django

| 文件类型 | 扫描内容 | 路径模式 |
|---|---|---|
| `urls.py` | 路由定义 | `**/urls.py` |
| `views.py` | 视图函数 | `**/views.py` |
| `models.py` | 数据模型 | `**/models.py` |

### Django 路由推断

```python
path('user/list/', views.user_list, name='user_list')
# → 接口：GET /user/list/
```

---

## Go

### 路由信号

| 类型 | 示例 |
|---|---|
| `http.HandleFunc` | `http.HandleFunc("/user/list", handler)` |
| `r.Handle` | `r.Handle("/user/list", handler).Methods("GET")` |
| 方法签名 | `func (h *Handler) List(w http.ResponseWriter, r *http.Request)` |

### 推断示例

```go
r := mux.NewRouter()
r.HandleFunc("/api/user/list", userList).Methods("GET")
r.HandleFunc("/api/user/save", userSave).Methods("POST")
// → 接口：GET /api/user/list, POST /api/user/save
```

---

## C# / .NET

### 通用规则

| 文件类型 | 扫描内容 | 路径模式 |
|---|---|---|
| Controller | 接口路径、HTTP 方法、参数名 | `**/*Controller.cs` |
| Service | 业务方法签名 | `**/*Service.cs` |
| Entity / Model | 字段名、类型、数据注解 | `**/Entities/*.cs` / `**/Models/*.cs` |
| DbContext | 数据库表映射 | `**/*DbContext.cs` / `**/*Context.cs` |
| Repository | 数据访问方法 | `**/*Repository.cs` |

### 注解信号

| 注解 | 含义 |
|---|---|
| `[ApiController]` / `[Controller]` | Controller 类 |
| `[Route("api/[controller]")]`, `[HttpGet]`, `[HttpPost]`, `[HttpPut]`, `[HttpDelete]` | 接口路径和方法 |
| `[Required]`, `[StringLength]`, `[Range]` | 参数校验约束 |
| `[Table("xxx")]` | 数据库表映射 |
| `[Column("xxx")]` | 数据库字段映射 |
| `[Key]` | 主键 |
| `[ForeignKey]` | 外键 |

### 路由推断示例

```csharp
[ApiController]
[Route("api/user")]          // → 一级路径：/api/user
public class UserController {
    [HttpGet("list")]        // → 接口：GET /api/user/list
    [HttpPost("save")]       // → 接口：POST /api/user/save
}
```

### EF Core 映射推断

```csharp
// DbContext 中的 DbSet 映射到表
public DbSet<User> Users { get; set; }  // → 表 Users

// Entity 中的属性映射到字段
public class User {
    public int Id { get; set; }         // → 字段 Id (int)
    public string Name { get; set; }    // → 字段 Name (nvarchar)
}
```

---

## Rust

### 通用规则

| 文件类型 | 扫描内容 | 路径模式 |
|---|---|---|
| Handler / Router | 接口路径、HTTP 方法 | `**/handlers/*.rs` / `**/routes/*.rs` |
| Service / Action | 业务逻辑 | `**/services/*.rs` / `**/actions/*.rs` |
| Model / Entity | 数据结构 | `**/models/*.rs` / `**/entities/*.rs` |
| Schema / Migration | 数据库定义 | `**/migrations/*.sql` / `**/schema/*.rs` |

### 路由信号（常见框架）

**Actix-web:**

```rust
App::new()
    .route("/api/user/list", web::get().to(list_users))   // → GET /api/user/list
    .route("/api/user/save", web::post().to(save_user))   // → POST /api/user/save
```

**Axum:**

```rust
Router::new()
    .route("/api/user/list", get(list_users))              // → GET /api/user/list
    .route("/api/user/save", post(save_user))              // → POST /api/user/save
```

**Rocket:**

```rust
#[get("/api/user/list")]
fn list_users() -> Json<Vec<User>> { ... }                // → GET /api/user/list

#[post("/api/user/save", data = "<user>")]
fn save_user(user: Json<User>) -> Json<Value> { ... }     // → POST /api/user/save
```

### 结构体推断

```rust
// 结构体字段映射到数据模型
pub struct User {
    pub id: i32,           // → 字段 id (integer)
    pub name: String,      // → 字段 name (text)
    pub email: String,     // → 字段 email (text)
}
```

---

## Kubernetes / Helm

### 通用规则

| 文件类型 | 扫描内容 | 路径模式 |
|---|---|---|
| Deployment | 容器镜像、端口、环境变量、资源限制 | `**/deployment*.yaml` / `**/deploy*.yaml` |
| Service | 服务端口、类型、选择器 | `**/service*.yaml` / `**/svc*.yaml` |
| ConfigMap | 配置项 | `**/configmap*.yaml` |
| Secret | 敏感配置（仅扫描键名，不读值） | `**/secret*.yaml` |
| Ingress | 路由规则、TLS 配置 | `**/ingress*.yaml` |
| Helm values | 可配置参数 | `**/values.yaml` / `**/values-*.yaml` |
| Helm templates | 模板渲染逻辑 | `**/templates/*.yaml` |

### 关键字段推断

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service            # → 服务名
spec:
  template:
    spec:
      containers:
        - name: user-app        # → 容器名
          image: user-svc:v1    # → 镜像
          ports:
            - containerPort: 8080  # → 服务端口
          env:                      # → 环境变量
            - name: DB_HOST
              value: "localhost"
```

### Helm Chart 结构推断

```
chart/
├── Chart.yaml          # Chart 元信息
├── values.yaml         # 默认配置值
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
```

推断功能点时，以 **Deployment + Service 组合**为一个模块单元，Chart 视为一个可部署单元。


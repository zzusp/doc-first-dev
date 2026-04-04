# 语言与框架扫描规则

## 内容目录
- [Java（Spring）](#java-spring)
- [Node.js（Express/Koa）](#nodejs-expresskoa)
- [Python（FastAPI/Django）](#python-fastapidjango)
- [Go](#go)

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


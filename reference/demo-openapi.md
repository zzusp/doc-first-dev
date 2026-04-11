# Model 模块接口文档

> **模块说明**：Model（模型）模块用于管理 LCA 产品模型，支持模型的创建、基础信息/管理信息编辑、列表查询、复制、删除，以及基于 Canvas 画布的上游关系管理（添加上游节点、生命周期阶段设置等）。
>
> **Base Path**：所有接口均以 `/model` 或 `/modelCanvas` 为前缀。
>
> **认证**：所有请求必须携带以下三个 Header，否则返回 903。

---

## 认证 Header

| Header 名 | 说明 |
|---|---|
| `Authorization` | SSO Access Token |
| `Cookie` | `accessToken=<token>` |
| `userId` | 当前用户 ID，必须与 token 对应，不一致返回 903 |

---

## 统一响应格式

所有接口均包装在 `ResultDTO` 中返回。

```json
{
  "success": true,
  "code": "200",
  "message": "成功",
  "data": "<业务数据>",
  "page": 1,
  "size": 20,
  "total": 100,
  "totalPageNum": 5,
  "needConfirm": null,
  "headers": null
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `success` | boolean | `true` 表示成功，`false` 表示失败 |
| `code` | string | `"200"` 成功；`"400"` 入参错误；`"500"` 系统异常；`"903"` 认证不一致 |
| `message` | string | 提示信息 |
| `data` | any | 业务数据（列表接口为数组，单体接口为对象，无数据时为 `null`） |
| `page` | integer | 当前页码（仅分页接口返回） |
| `size` | integer | 每页条数（仅分页接口返回） |
| `total` | integer | 总条数（仅分页接口返回） |
| `totalPageNum` | integer | 总页数（仅分页接口返回） |
| `needConfirm` | boolean | 是否需要二次确认（一般为 `null`） |

---

## 枚举值说明

### lifecycleStageCode — 生命周期阶段

| 枚举值 | 中文说明 | 英文说明 |
|---|---|---|
| `RAW_MATERIAL` | 原材料获取与预处理 | Raw material acquisition and pre-processing |
| `MANUFACTURING` | 制造阶段（主产品生产） | Manufacturing (production of the main product) |
| `DISTRIBUTION` | 流通阶段（产品分销与仓储） | Distribution (product distribution and storage) |
| `USE_STAGE` | 使用阶段 | Use stage |
| `END_OF_LIFE` | 废弃阶段（含产品回收或循环利用） | End of life (including product recovery or recycling) |

> 添加上游节点（`/modelCanvas/addUpstream`）时若不传 `lifecycleStageCode`，上游节点默认 `MANUFACTURING`；根节点在模型创建时自动插入，默认 `MANUFACTURING`，通过 `updateStage` 接口修改。

---

### changeTypes — Canvas 变更类型

| 枚举值 | 说明 |
|---|---|
| `PROCESS_DELETED` | 数据集已被软删除 |
| `UPSTREAM_PROCESS_DELETED` | 上游数据集已被软删除 |
| `FLOW_DELETED` | 关联流已被软删除 |
| `REFERENCE_FLOW_CHANGED` | 根节点参考产品流与建模时的快照不一致 |
| `RELATION_CHANGED` | 建模时记录的 exchange 关系（流+上游+数据库+版本）在当前数据中已不存在 |

---

## 一、Model 主接口（/model）

---

### 1. 新建模型

**`POST /model/create`**

根据一个已计算完成（`isCalculated=1`）且属于当前用户的过程数据集，创建一个新模型。模型会继承参考数据集的基础字段（物料类别、地域、数据归属、行业分类等）。

#### 请求体

```json
{
  "referenceProcessId": "abc123",
  "name": "我的产品模型（可选）"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `referenceProcessId` | string | **是** | 参考过程数据集 ID，创建后不可修改；必须是当前用户工作区中的已计算数据集 |
| `name` | string | 否 | 模型名称；不传则继承参考数据集的名称 |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "message": "成功",
  "data": "新建模型的ID（string）"
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `data` | string | 新建模型的 ID |

#### 错误情况

| code | message | 说明 |
|---|---|---|
| `400` | 参考过程数据集id不能为空 | `referenceProcessId` 为空 |
| `400` | 只能选择当前用户工作区中的数据集 | 所选数据集不属于当前登录用户 |
| `400` | 只能选择已计算的数据集作为参考过程 | 所选数据集未完成计算 |
| DATA_NOT_EXIST | 数据不存在 | 参考数据集 ID 不存在或已删除 |

---

### 2. 保存表单信息

**`POST /model/saveForm`**

按 `formType` 分块保存模型信息。支持三个表单块：`baseInfo`（基础信息）、`managerInfo`（管理信息）、`validationInfo`（建模验证信息）。`formType` 为空时统一保存所有字段。

#### 请求体

```json
{
  "modelId": "model-id-xxx",
  "formType": "baseInfo",

  "name": "兜底完整名称（当nameExtend为空时生效）",
  "nameExtend": "{\"name\":\"基础名称\",\"processingStandard\":\"热轧\",\"mixingLocationType\":\"全国平均\",\"productSpecification\":\"1mm厚\"}",
  "description": "数据集描述",
  "categoryId": "category-id",
  "locationId": "location-id",
  "dataAttribution": "datasource-id",
  "referenceIndustry": "industry-id",
  "industrySelections": {
    "classification-id-1": "category-id-a",
    "classification-id-2": "category-id-b"
  },

  "licenseType": "...",
  "complianceSystemName": "...",
  "overallCompliance": "...",
  "nomenclatureCompliance": "...",
  "qualityCompliance": "...",
  "methodologicalCompliance": "...",
  "reviewCompliance": "...",
  "documentationCompliance": "...",
  "technicalDescription": "技术描述",
  "intendedApplications": "预期应用",
  "commissioner": "委托人",
  "sourceIds": ["src-uuid-001", "src-uuid-002"],
  "suggest": "使用建议"
}
```

| 字段 | 类型 | 必填 | 适用 formType | 说明 |
|---|---|---|---|---|
| `modelId` | string | **是** | 全部 | 模型 ID |
| `formType` | string | 否 | 全部 | 表单块类型：`baseInfo` / `managerInfo` / `validationInfo`；为空时统一保存所有字段 |
| `name` | string | 否 | `baseInfo` | 完整名称兜底（`nameExtend` 为空时使用此字段设置 `name`） |
| `nameExtend` | string (JSON) | 否 | `baseInfo` | 名称四维明细，JSON 字符串，结构见下方说明 |
| `description` | string | 否 | `baseInfo` | 描述 |
| `locationId` | string | 否 | `baseInfo` | 地域 ID |
| `dataAttribution` | string | 否 | `baseInfo` | 数据归属（数据库 ID） |
| `referenceIndustry` | string | 否 | `baseInfo` | 参考行业 ID |
| `industrySelections` | object | 否 | `baseInfo` / `managerInfo` | 行业选择，key 为行业分类 ID，value 为行业类别 ID |
| `licenseType` | string | 否 | `managerInfo` / `validationInfo` | 许可证类型 |
| `complianceSystemName` | string | 否 | `managerInfo` / `validationInfo` | 合规体系名称 |
| `overallCompliance` | string | 否 | `managerInfo` / `validationInfo` | 整体合规性 |
| `nomenclatureCompliance` | string | 否 | `managerInfo` / `validationInfo` | 命名合规性 |
| `qualityCompliance` | string | 否 | `managerInfo` / `validationInfo` | 质量合规性 |
| `methodologicalCompliance` | string | 否 | `managerInfo` / `validationInfo` | 方法论合规性 |
| `reviewCompliance` | string | 否 | `managerInfo` / `validationInfo` | 评审合规性 |
| `documentationCompliance` | string | 否 | `managerInfo` / `validationInfo` | 文档合规性 |
| `technicalDescription` | string | 否 | `managerInfo` / `validationInfo` | 技术描述（对应 General comment） |
| `intendedApplications` | string | 否 | `managerInfo` / `validationInfo` | 预期应用 |
| `commissioner` | string | 否 | `managerInfo` | 委托人（Commissioner） |
| `project` | string | 否 | `managerInfo` | 项目 |
| `dataSetSubGenerator` | string | 否 | `managerInfo` | 数据辅助建立人员，格式 `{"id":"用户ID","username":"姓名"}` |
| `sourceIds` | string[] | 否 | `managerInfo` | 参考文献 ID 列表（创建时继承自参考过程，可修改） |
| `suggest` | string | 否 | `validationInfo` | 使用建议（创建时继承自参考过程，可修改） |
| `supplement` | string | 否 | `validationInfo` | 建模与验证补充说明 |

**`nameExtend` JSON 字段结构：**

```json
{
  "name": "基础名称",
  "processingStandard": "处理标准与路线",
  "mixingLocationType": "混合与位置类型",
  "productSpecification": "产品规格与属性"
}
```

#### 响应

```json
{
  "success": true,
  "code": "200",
  "message": "成功",
  "data": null
}
```

#### 错误情况

| code | message | 说明 |
|---|---|---|
| `400` | modelId不能为空 | `modelId` 为空 |
| `400` | 无效的 formType: xxx | `formType` 不在允许范围内 |
| `400` | 无权修改他人的模型 | 当前用户不是该模型的编辑人 |

---

### 3. 查询模型详情

**`GET /model/detail?modelId=xxx`**

一次返回模型所有字段（基础信息 + 管理信息 + 建模验证信息）。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 模型 ID |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": {

    "id": "a1b2c3d4e5f6",
    "name": "1kg 铝合金压铸件生产,热轧,华东地区,板材1mm",
    "nameExtend": "{\"name\":\"1kg 铝合金压铸件生产\",\"processingStandard\":\"热轧\",\"mixingLocationType\":\"华东地区\",\"productSpecification\":\"板材1mm\"}",
    "description": "本模型描述铝合金压铸件从原材料至成品的全生命周期过程。",
    "categoryId": "1001",
    "categoryName": "黑色金属",
    "referenceUnitId": "unit-uuid-001",
    "referenceUnitName": "kg",
    "locationId": "2001",
    "dataAttribution": "db-uuid-001",
    "referenceIndustry": "3001",
    "industrySelections": {
      "classif-uuid-001": "cat-uuid-a",
      "classif-uuid-002": "cat-uuid-b"
    },
    "industryTags": [
      { "id": "3001", "name": "黑色金属冶炼" },
      { "id": "3002", "name": "有色金属压延" }
    ],
    "referenceProcessId": "proc-uuid-001",
    "referenceProcessSnapshot": {
      "processId": "proc-uuid-001",
      "name": "1kg 铝合金压铸件生产",
      "referenceFlowId": "flow-uuid-001",
      "systemModel": "ALLOCATION_AT_POINT_OF_SUBSTITUTION",
      "dataAttribution": "db-uuid-001",
      "referenceIndustry": "3001"
    },
    "sourceIds": ["src-uuid-001", "src-uuid-002"],

    "licenseType": "Free of charge for all users",
    "complianceSystemName": "ILCD Data Network - Entry Level",
    "overallCompliance": "Fully compliant",
    "nomenclatureCompliance": "Fully compliant",
    "qualityCompliance": "Fully compliant",
    "methodologicalCompliance": "Fully compliant",
    "reviewCompliance": "Not defined",
    "documentationCompliance": "Fully compliant",
    "technicalDescription": "本模型用于铝合金生命周期评估，涵盖原材料采购至工厂出货。",
    "intendedApplications": "适用于铝合金产品碳足迹核算及 EPD 报告。",
    "commissioner": "委托人",
    "dataSetGenerator": "{\"id\":\"user-uuid-001\",\"username\":\"张三\"}",
    "dataSetSubGenerator": "{\"id\":\"user-uuid-002\",\"username\":\"李四\"}",
    "dataSetOwner": "{\"id\":\"user-uuid-003\",\"username\":\"王五\"}",
    "isCopyrightProtected": false,
    "suggest": "建议结合区域电力排放因子使用，避免采用全国平均值。",
    "createTime": "2025-01-15T09:30:00.000+08:00",

    "dataSetDocumentor": "{\"id\":\"user-uuid-004\",\"username\":\"赵六\"}",
    "isLead": true,
    "updateTime": "2025-06-20T14:22:00.000+08:00"

  }
}
```

**字段说明：**

**— 基础信息 —**

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 模型 ID |
| `name` | string | 模型完整名称，由 `nameExtend` 四维拼接（逗号分隔） |
| `nameExtend` | string (JSON) | 名称四维明细；结构：`{name, processingStandard, mixingLocationType, productSpecification}` |
| `description` | string | 描述（继承自参考过程 `activityDescription`，可修改） |
| `categoryId` | string | 物料类别 ID（从 `tw_flows.category_id` 派生，只读，不可通过 saveForm 修改） |
| `categoryName` | string | 物料类别名称（从 `tw_categories` 实时查取，只读） |
| `referenceFlowName` | string \| null | 参考产品名称（从 `tw_flows.name` 实时查取，`reference_flow_id` 为空或流不存在时为 null，只读） |
| `referenceUnitId` | string | 声明单位（参考单位）ID（从参考数据集 `tw_process_doc.document.declaredUnitId` 派生，只读） |
| `referenceUnitName` | string | 声明单位（参考单位）名称（通过 `referenceUnitId` 查 `tw_units.name` 派生，只读） |
| `locationId` | string | 地域 ID（继承自参考过程） |
| `dataAttribution` | string | 数据归属（数据库 ID，继承自参考过程） |
| `systemModel` | string | 系统模型编码（继承自参考数据集 `from_data` 字段，只读，创建后不可修改） |
| `referenceIndustry` | string | 参考行业 ID |
| `industrySelections` | object | 行业选择 Map，key 为行业分类 ID，value 为行业类别 ID |
| `industryTags` | `{id,name}[]` | 行业标签列表（对应 `tw_models.industries`），name 从 `t_dictionary` 实时查取 |
| `referenceProcessId` | string | 参考过程数据集 ID（创建时绑定，只读，不可修改） |
| `referenceProcessSnapshot` | object | 创建时的参考数据集快照（只读），字段见下方 |
| `sourceIds` | string[] | 参考文献 ID 数组（创建时继承自参考过程，可修改） |
| `sourceInfos` | SourceInfo[] | 引用来源完整信息列表，通过 sourceIds 实时查询 `tw_sources`；无 sourceIds 时为空数组 |

**`referenceProcessSnapshot` 内部字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `processId` | string | 参考过程数据集 ID |
| `name` | string | 建模时的数据集名称（快照，不随参考过程更新） |
| `referenceFlowId` | string | 建模时的参考产品流 ID |
| `systemModel` | string | 建模时的系统模型编码 |
| `dataAttribution` | string | 建模时的数据归属 |
| `referenceIndustry` | string | 建模时的参考行业 ID |

**— 管理信息 & 建模验证信息 —**

| 字段 | 类型 | 说明 |
|---|---|---|
| `licenseType` | string | 许可证类型；枚举值：`Free of charge for all users` / `Free of charge for some user types or use types` / `Free of charge for members only` / `License fee` / `Others` |
| `complianceSystemName` | string | 合规体系名称（源数据集） |
| `overallCompliance` | string | 整体合规性；枚举值：`Fully compliant` / `Not compliant` / `Not defined` |
| `nomenclatureCompliance` | string | 命名合规性；同上枚举 |
| `qualityCompliance` | string | 质量合规性；同上枚举 |
| `methodologicalCompliance` | string | 方法论合规性；同上枚举 |
| `reviewCompliance` | string | 审查合规性；同上枚举 |
| `documentationCompliance` | string | 文档合规性；同上枚举 |
| `generalComment` | string | 总体说明（General comment） |
| `technicalDescription` | string | 技术描述（对应 General comment） |
| `intendedApplications` | string | 预期应用（Intended applications，用户自填） |
| `commissioner` | string | 委托人（Commissioner，可编辑） |
| `project` | string | 项目（可编辑，通过 `saveForm(managerInfo)` 修改） |
| `dataSetOwner` | string (JSON) | 数据集所有者，格式 `{"id":"用户ID","username":"姓名"}`（继承自参考过程，只读） |

**— 建立信息 —**

| 字段 | 类型 | 说明 |
|---|---|---|
| `dataSetGenerator` | string (JSON) | 数据建立人员，格式 `{"id":"用户ID","username":"姓名"}`（继承自参考过程） |
| `dataSetSubGenerator` | string (JSON) | 数据辅助建立人员，格式同上（继承自参考过程，可通过 `saveForm(managerInfo)` 修改） |
| `dataSetOwner` | string (JSON) | 数据集所有者，格式同上（继承自参考过程） |
| `isCopyrightProtected` | boolean | 版权保护（继承自参考过程） |
| `suggest` | string | 使用建议（继承自参考过程，可通过 `saveForm(validationInfo)` 修改） |
| `supplement` | string | 建模与验证补充说明（可通过 `saveForm(validationInfo)` 修改） |
| `createTime` | datetime | 模型创建时间（Model 自身，非参考过程时间） |

**— 编辑信息 —**

| 字段 | 类型 | 说明 |
|---|---|---|
| `dataSetDocumentor` | string (JSON) | 数据编辑人员，格式 `{"id":"用户ID","username":"姓名"}`（继承自参考过程） |
| `isLead` | boolean | 是否为主要作者（继承自参考过程） |
| `updateTime` | datetime | 模型最后编辑时间（Model 自身，每次 `saveForm` 后更新） |

---

### 4. 我的模型列表（分页）

**`POST /model/my/list`**

查询当前登录用户的模型列表，支持多条件筛选和分页。

#### 请求体

```json
{
  "keyWord": "搜索关键字",
  "systemModel": "SYSTEM_MODEL_CODE",
  "dataAttribution": "datasource-id",
  "referenceProduct": "product-name",
  "approvalStatus": ["PENDING", "APPROVED"],
  "isReleased": false,
  "startDate": "2025-01-01",
  "endDate": "2025-12-31",
  "industryFilters": [
    {
      "classificationId": "classification-id-1",
      "categoryIds": ["category-id-a", "category-id-b"]
    }
  ],
  "page": 1,
  "size": 20
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `keyWord` | string | 否 | 关键字，模型名称模糊匹配 |
| `systemModel` | string | 否 | 系统模型编码精确筛选 |
| `dataAttribution` | string | 否 | 数据归属（数据库 ID）精确筛选 |
| `referenceProduct` | string | 否 | 参考产品名称模糊筛选 |
| `approvalStatus` | string[] | 否 | 审核状态多选，常见值：`PENDING`（待审核）、`APPROVED`（已通过）、`REJECTED`（已拒绝） |
| `isReleased` | boolean | 否 | 是否已发布 |
| `startDate` | string | 否 | 创建时间起始，格式 `YYYY-MM-DD` |
| `endDate` | string | 否 | 创建时间结束，格式 `YYYY-MM-DD` |
| `industryFilters` | object[] | 否 | 行业筛选（多体系 AND 逻辑）；每个元素指定一个行业分类 ID 及允许的类别 ID 列表 |
| `industryFilters[].classificationId` | string | — | 行业分类 ID |
| `industryFilters[].categoryIds` | string[] | — | 该分类下允许的行业类别 ID 列表（OR 逻辑） |
| `page` | integer | 否 | 页码，默认 1 |
| `size` | integer | 否 | 每页条数，默认 20 |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": [
    {
      "id": "model-id",
      "uuid": "uuid-string",
      "name": "模型名称",
      "referenceProcessId": "process-id",
      "referenceProcessName": "参考过程名称",
      "referenceFlowId": "flow-id",
      "categoryId": "category-id",
      "systemModel": "CONSEQUENTIAL",
      "dataAttribution": "datasource-id",
      "locationId": "location-id",
      "industries": ["industry-id-1", "industry-id-2"],
      "referenceIndustry": "industry-id",
      "isReleased": false,
      "approvalStatus": "PENDING",
      "editor": "user-id",
      "createTime": "2025-01-01T10:00:00.000+08:00",
      "updateTime": "2025-06-01T10:00:00.000+08:00"
    }
  ],
  "page": 1,
  "size": 20,
  "total": 100,
  "totalPageNum": 5
}
```

**`data` 列表项字段说明：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 模型 ID |
| `uuid` | string | 模型 UUID |
| `name` | string | 模型名称 |
| `referenceProcessId` | string | 参考过程数据集 ID |
| `referenceProcessName` | string | 参考过程数据集名称 |
| `referenceFlowId` | string | 参考产品流 ID |
| `categoryId` | string | 物料类别 ID |
| `systemModel` | string | 系统模型编码（继承自参考数据集 `from_data` 字段，只读） |
| `dataAttribution` | string | 数据归属（数据库 ID） |
| `locationId` | string | 地域 ID |
| `industries` | string[] | 行业 ID 数组（继承自参考数据集） |
| `referenceIndustry` | string | 参考行业 ID |
| `isReleased` | boolean | 是否已发布 |
| `approvalStatus` | string | 审核状态 |
| `editor` | string | 编辑人用户 ID |
| `createTime` | datetime | 创建时间 |
| `updateTime` | datetime | 最近更新时间 |

---

### 5. 全量模型列表（分页）

**`POST /model/list`**

查询所有用户的模型列表（管理员/全量视图）。

> 入参结构与 `POST /model/my/list` 完全相同，响应结构也相同，差异仅在于不过滤当前用户（返回所有人的模型）。

---

### 6. 复制模型

**`POST /model/copy`**

复制当前用户自己的模型（含全部 Canvas 关系记录）。

#### 请求体

```json
{
  "modelId": "source-model-id",
  "name": "新模型名称（必填）"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 要复制的模型 ID |
| `name` | string | **是** | 新模型名称（前端已拼接的四维完整名称），直接写入 `tw_models.name` 列及 `i18n.name.zh_CN`；三个维度字段（processingStandard/mixingLocationType/productSpecification）统一置空 |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": "新模型的ID（string）"
}
```

#### 错误情况

| code | message | 说明 |
|---|---|---|
| `400` | modelId不能为空 | `modelId` 为空 |
| `400` | name不能为空 | `name` 为空 |
| `400` | 无权复制他人的模型 | 当前用户不是该模型的编辑人 |

---

### 7. 删除模型（软删）

**`DELETE /model/delete?modelId=xxx`**

软删当前用户自己的模型及其所有 Canvas 关系记录。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 要删除的模型 ID |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": null
}
```

#### 错误情况

| code | message | 说明 |
|---|---|---|
| `400` | 无权删除他人的模型 | 当前用户不是该模型的编辑人 |

---

### 8a. 我的统计卡片

**`GET /model/my/statistics`**

获取当前用户模型的统计汇总，用于「我的」页面卡片展示。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `dataAttribution` | string | 否 | 数据归属（数据库 ID），传入时仅统计 `data_attribution` 匹配的模型；不传时统计当前用户所有模型 |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": {
    "totalModels": 42,
    "relatedProcessCount": 18,
    "relatedProductCount": 7,
    "pendingReviewCount": 3
  }
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `totalModels` | long | 当前用户的模型总量 |
| `relatedProcessCount` | long | 涉及的过程数据集数量（根节点 + 所有 Canvas 上下游节点去重） |
| `relatedProductCount` | long | 关联产品数量（基于模型 `reference_flow_id` 去重计数） |
| `pendingReviewCount` | long | 待审核模型数量（`approvalStatus = PENDING`） |

---

### 8b. 全部统计卡片

**`GET /model/all/statistics`**

获取租户下全部模型的统计汇总，用于「全部」页面卡片展示。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `dataAttribution` | string | 否 | 数据归属（数据库 ID），传入时仅统计 `data_attribution` 匹配的模型；不传时统计租户全部模型 |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": {
    "totalModels": 120,
    "relatedProcessCount": 45,
    "relatedProductCount": 23,
    "pendingReviewCount": 8
  }
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `totalModels` | long | 租户全部模型总量 |
| `relatedProcessCount` | long | 涉及的过程数据集数量（根节点 + 所有 Canvas 上下游节点去重） |
| `relatedProductCount` | long | 关联产品数量（基于模型 `reference_flow_id` 去重计数） |
| `pendingReviewCount` | long | 待审核模型数量（`approvalStatus = PENDING`） |

---

## 二、Canvas 画布接口（/modelCanvas）

---

### 10. 查询可选上游列表

**`GET /modelCanvas/upstreamCandidates?processId=xxx`**

查询某个数据集的所有可选上游节点（该数据集的输入 exchange 列表），用于 Canvas 画布中「添加上游」弹窗的数据来源。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `processId` | string | **是** | 当前（下游）数据集 ID |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": [
    {
      "flowId": "flow-id",
      "flowName": "输入流名称",
      "upstreamProcessId": "upstream-process-id",
      "upstreamProcessName": "上游数据集名称",
      "upstreamDatasourceCode": null,
      "upstreamDatasourceVersion": null,
      "categoryId": "100",
      "categoryName": "黑色金属"
    }
  ]
}
```

**`data` 列表项字段说明：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `flowId` | string | 流 ID（连接上下游的边） |
| `flowName` | string | 流名称 |
| `upstreamProcessId` | string | 上游数据集 ID |
| `upstreamProcessName` | string | 上游数据集名称；工作区取 `tw_processes.name`，背景库取 `tw_process_data.up_element_name` |
| `upstreamDatasourceCode` | string \| null | 上游所属数据库编码；工作区数据集为 `null` |
| `upstreamDatasourceVersion` | string \| null | 上游所属数据库版本；工作区数据集为 `null` |
| `categoryId` | string \| null | 物料类别 ID（来自背景库 `tw_process_data.category_id`） |
| `categoryName` | string \| null | 物料类别名称（字典翻译） |

> 结果已按 `flowId + upstreamProcessId + datasourceCode + datasourceVersion` 去重。

---

### 11. 获取 Canvas 绘图展示（含变更感知）

**`GET /modelCanvas/detail?modelId=xxx`**

获取模型完整的 Canvas 展示数据（节点 + 边），并对每个节点和边标注是否存在变更（数据集被删、参考产品变更、关系失效等）。**前端绘图渲染使用此接口**。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 模型 ID |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": {
    "modelId": "model-id",
    "hasChanges": true,
    "rootNode": {
      "nodeId": "node-id",
      "processId": "root-process-id",
      "processName": "根节点数据集名称",
      "referenceFlowId": "flow-id",
      "referenceFlowName": "参考产品流名称",
      "isRootNode": true,
      "categoryId": "100",
      "categoryName": "黑色金属",
      "datasourceCode": null,
      "datasourceVersion": null,
      "lifecycleStageCode": "MANUFACTURING",
      "changed": false,
      "changeTypes": []
    },
    "nodes": [
      {
        "nodeId": "node-id",
        "processId": "process-id",
        "processName": "数据集名称（已删除时为 "未找到"）",
        "referenceFlowId": "flow-id",
        "referenceFlowName": "参考产品流名称",
        "isRootNode": false,
        "categoryId": "100",
        "categoryName": "黑色金属",
        "datasourceCode": "Ecoinvent",
        "datasourceVersion": "v1.0",
        "lifecycleStageCode": "RAW_MATERIAL",
        "changed": true,
        "changeTypes": ["PROCESS_DELETED"]
      }
    ],
    "edges": [
      {
        "relationId": "relation-id",
        "processId": "downstream-process-id",
        "processName": "下游数据集名称",
        "flowId": "flow-id",
        "flowName": "流名称",
        "upstreamProcessId": "upstream-process-id",
        "upstreamProcessName": "上游数据集名称（已删除时为 "未找到"）",
        "upstreamDatasourceCode": null,
        "upstreamDatasourceVersion": null,
        "changed": false,
        "changeTypes": []
      }
    ]
  }
}
```

**顶层字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `modelId` | string | 模型 ID |
| `hasChanges` | boolean | 是否存在任意变更（节点或边中任意一处变更则为 `true`） |
| `rootNode` | object | 根节点信息（同时存在于 `nodes` 中，此处单独返回便于前端快速取根节点） |
| `nodes` | object[] | 所有节点列表（去重，包含根节点） |
| `edges` | object[] | 所有边列表（每条关系记录对应一条边） |

**Node 字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `nodeId` | string | 节点记录 ID（`tw_model_node.id`），用于 `updateStage` 接口定位节点 |
| `processId` | string | 数据集 ID |
| `processName` | string | 数据集名称；已被软删时为 `"未找到"` |
| `referenceFlowId` | string | 参考产品流 ID |
| `referenceFlowName` | string | 参考产品流名称 |
| `isRootNode` | boolean | 是否是根节点 |
| `categoryId` | string | 物料类别 ID |
| `categoryName` | string | 物料类别名称 |
| `datasourceCode` | string \| null | 背景库数据集所属数据库编码；工作区节点为 `null` |
| `datasourceVersion` | string \| null | 背景库数据集版本；工作区节点为 `null` |
| `lifecycleStageCode` | string | 节点的生命周期阶段，取值见[枚举值说明](#lifecyclestageCode--生命周期阶段) |
| `changed` | boolean | 该节点是否有变更 |
| `changeTypes` | string[] | 变更原因列表，取值见[枚举值说明](#changetypes--canvas-变更类型)；节点和边的 `changed` 状态各自独立判定，`changed=true` 时 `changeTypes` 必非空 |

> 节点去重规则：工作区节点按 `processId` 去重；背景库节点按 `processId + datasourceCode + datasourceVersion` 去重。

**Edge 字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `relationId` | string | 关系记录 ID（可用于删除） |
| `processId` | string | 当前（下游）数据集 ID |
| `processName` | string | 当前数据集名称；已删除时为 `"未找到"` |
| `flowId` | string | 连接上下游的流 ID |
| `flowName` | string | 流名称 |
| `upstreamProcessId` | string | 上游数据集 ID |
| `upstreamProcessName` | string | 上游数据集名称；已删除时为 `"未找到"` |
| `upstreamDatasourceCode` | string \| null | 上游所属数据库编码；工作区上游为 `null` |
| `upstreamDatasourceVersion` | string \| null | 上游所属数据库版本；工作区上游为 `null` |
| `changed` | boolean | 该边是否有变更 |
| `changeTypes` | string[] | 变更原因列表，取值见[枚举值说明](#changetypes--canvas-变更类型)；节点和边的 `changed` 状态各自独立判定，`changed=true` 时 `changeTypes` 必非空 |

---

### 12. 获取原始关系图数据（用于编辑保存）

**`GET /modelCanvas/raw?modelId=xxx`**

获取模型原始 Canvas 数据（无变更检测、无名称翻译），主要用于前端编辑后执行全量覆盖保存（配合 `POST /modelCanvas/save`）。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 模型 ID |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": {
    "modelId": "model-id",
    "referenceProcessId": "root-process-id",
    "referenceProcessName": "根节点数据集名称",
    "referenceFlowId": "flow-id",
    "nodes": [
      {
        "id": "node-id",
        "modelId": "model-id",
        "processId": "process-id",
        "datasourceCode": null,
        "datasourceVersion": null,
        "lifecycleStageCode": "MANUFACTURING",
        "tenantId": "tenant-id",
        "createTime": "2025-01-01T10:00:00.000+08:00",
        "isDeleted": false
      }
    ],
    "relations": [
      {
        "id": "relation-id",
        "modelId": "model-id",
        "processId": "process-id",
        "flowId": "flow-id",
        "upstreamProcessId": "upstream-id",
        "upstreamDatasourceCode": null,
        "upstreamDatasourceVersion": null,
        "tenantId": "tenant-id",
        "createTime": "2025-01-01T10:00:00.000+08:00",
        "createId": "user-id",
        "updateId": "user-id",
        "updateTime": "2025-06-01T10:00:00.000+08:00",
        "isDeleted": false
      }
    ]
  }
}
```

**顶层字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `modelId` | string | 模型 ID |
| `referenceProcessId` | string | 参考过程数据集 ID（根节点） |
| `referenceProcessName` | string | 参考过程数据集名称 |
| `referenceFlowId` | string | 参考产品流 ID |
| `nodes` | object[] | 节点列表（含根节点及所有上游节点，`lifecycleStageCode` 存储在此） |
| `relations` | object[] | 关系列表（边，无阶段字段） |

**`nodes` 元素字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 节点记录 ID |
| `modelId` | string | 所属模型 ID |
| `processId` | string | 节点代表的数据集 ID |
| `datasourceCode` | string \| null | 数据库编码；工作区为 `null` |
| `datasourceVersion` | string \| null | 数据库版本；工作区为 `null` |
| `lifecycleStageCode` | string | 生命周期阶段枚举值 |
| `tenantId` | string | 租户 ID |
| `createTime` | datetime | 创建时间 |
| `isDeleted` | boolean | 是否软删 |

**`relations` 元素字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 关系记录 ID |
| `modelId` | string | 所属模型 ID |
| `processId` | string | 当前（下游）数据集 ID |
| `flowId` | string | 连接上下游的流 ID |
| `upstreamProcessId` | string | 上游数据集 ID |
| `upstreamDatasourceCode` | string \| null | 上游所属数据库编码；工作区为 `null` |
| `upstreamDatasourceVersion` | string \| null | 上游所属数据库版本；工作区为 `null` |
| `tenantId` | string | 租户 ID |
| `createTime` | datetime | 创建时间 |
| `createId` | string | 创建人 ID |
| `updateId` | string | 最后修改人 ID |
| `updateTime` | datetime | 最后修改时间 |
| `isDeleted` | boolean | 是否软删（正常数据均为 `false`） |

---

### 13. 添加上游节点关系

**`POST /modelCanvas/addUpstream`**

向模型 Canvas 中批量添加上游节点关系（多条边）。**节点级全量同步**：传入的列表为指定节点的所有流和上游关系完整集合，不在列表中的现有关系写入前清理掉（软删除）；已存在关系覆盖写入（upsert）。

#### 请求体

```json
[
  {
    "modelId": "model-id",
    "processId": "downstream-process-id",
    "flowId": "flow-id",
    "upstreamProcessId": "upstream-process-id-1",
    "upstreamDatasourceCode": null,
    "upstreamDatasourceVersion": null,
    "lifecycleStageCode": "RAW_MATERIAL"
  },
  {
    "modelId": "model-id",
    "processId": "downstream-process-id",
    "flowId": "flow-id-2",
    "upstreamProcessId": "upstream-process-id-2",
    "upstreamDatasourceCode": null,
    "upstreamDatasourceVersion": null,
    "lifecycleStageCode": "MANUFACTURING"
  }
]
```

> 请求体为数组，最多 **50 条**。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 所属模型 ID |
| `processId` | string | **是** | 当前（下游）数据集 ID |
| `flowId` | string | **是** | 连接上下游的流 ID（来自上游候选列表 `flowId` 字段） |
| `upstreamProcessId` | string | **是** | 上游数据集 ID（来自上游候选列表 `upstreamProcessId` 字段） |
| `upstreamDatasourceCode` | string | 否 | 上游所属数据库编码；工作区上游传 `null` 或不传 |
| `upstreamDatasourceVersion` | string | 否 | 上游所属数据库版本；工作区上游传 `null` 或不传 |
| `lifecycleStageCode` | string | 否 | 目标节点的生命周期阶段枚举值；**属于节点，不属于单条边**；同 `(upstreamProcessId, upstreamDatasourceCode, upstreamDatasourceVersion)` 的多条边共享同一节点，取数组中第一个元素的 stage；不传时节点默认为 `MANUFACTURING` |

#### 约束说明

- 对同 `upstreamProcessId` 的现有节点和边先软删除，再批量 upsert 节点（含 stage）并写入边（传入空列表 = 清空该节点所有上游关系）。
- 同一 `(modelId, processId, flowId)` 三元组只保留最新写入的记录，旧记录软删除（is_deleted=true）。
- 单次请求最多 50 条；超过 50 条返回 400。

#### 响应

```json
{
  "success": true,
  "code": "200",
  "message": "成功",
  "data": null
}
```

```json
{
  "success": false,
  "code": "400",
  "message": "单次最多添加50条关系",
  "data": null
}
```

#### 错误情况

| code | message | 说明 |
|---|---|---|
| `400` | 批量添加上游关系不能超过50条 | 请求数组长度超过 50 |
| `400` | 批量添加失败：存在重复的上游关系或与库中已有记录冲突 | 批量内有重复 `(processId, flowId)` 或三元组已存在于库中 |
| `400` | modelId和processId不能为空 | 必填字段为空 |

---

### 14. 删除关系

**`POST /modelCanvas/deleteRelation?modelId=xxx&relationId=xxx`**

软删 Canvas 中的一条边（关系记录）。

#### Query 参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 所属模型 ID |
| `relationId` | string | **是** | 关系记录 ID（来自 `GET /modelCanvas/raw` 的 `relations[].id` 或 `GET /modelCanvas/detail` 的 `edges[].relationId`） |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": null
}
```

#### 错误情况

| code | message | 说明 |
|---|---|---|
| DATA_NOT_EXIST | 数据不存在 | 关系记录不存在、已被删除，或不属于该模型 |

---

### 15. 更新生命周期阶段

**`POST /modelCanvas/updateStage`**

更新 Canvas 中指定节点的生命周期阶段。

#### 请求体

```json
{
  "modelId": "model-id",
  "nodeId": "node-id",
  "lifecycleStageCode": "MANUFACTURING"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 所属模型 ID |
| `nodeId` | string | **是** | 节点记录 ID（来自 `GET /modelCanvas/detail` 的 `nodes[].nodeId`） |
| `lifecycleStageCode` | string | **是** | 新的生命周期阶段，取值见[枚举值说明](#lifecyclestageCode--生命周期阶段) |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": null
}
```

#### 错误情况

| code | message | 说明 |
|---|---|---|
| `400` | modelId和nodeId不能为空 | 必填字段为空 |
| `400` | 无效的生命周期阶段值: xxx | `lifecycleStageCode` 不在枚举范围内 |
| DATA_NOT_EXIST | 数据不存在 | 节点记录不存在、已被删除，或不属于该模型 |

---

### 16. 实时保存 Canvas（全量覆盖）

**`POST /modelCanvas/save`**

全量覆盖保存模型 Canvas。会先软删该模型所有旧节点和边，再批量插入新节点（含 stage）和边。适用于前端绘图工具中的「保存」操作。

> **注意**：此接口为全量覆盖，请务必在请求体中携带完整的 `nodes` 和 `relations` 列表；两者为空或不传则等同于清空所有数据。

#### 请求体

```json
{
  "modelId": "model-id",
  "referenceProcessId": "root-process-id",
  "referenceProcessName": "根节点名称（仅展示用，不写库）",
  "referenceFlowId": "flow-id",
  "nodes": [
    {
      "processId": "process-id",
      "datasourceCode": null,
      "datasourceVersion": null,
      "lifecycleStageCode": "MANUFACTURING"
    }
  ],
  "relations": [
    {
      "processId": "downstream-process-id",
      "flowId": "flow-id",
      "upstreamProcessId": "upstream-process-id",
      "upstreamDatasourceCode": null,
      "upstreamDatasourceVersion": null
    }
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `modelId` | string | **是** | 模型 ID |
| `referenceProcessId` | string | 否 | 根节点数据集 ID（仅用于展示，不写库） |
| `referenceProcessName` | string | 否 | 根节点名称（仅用于展示，不写库） |
| `referenceFlowId` | string | 否 | 参考产品流 ID（仅用于展示，不写库） |
| `nodes` | object[] | 否 | 节点列表（含根节点及所有上游节点）；不传或为空时清空所有节点 |
| `nodes[].processId` | string | **是** | 节点代表的数据集 ID |
| `nodes[].datasourceCode` | string | 否 | 数据库编码；工作区为 `null` |
| `nodes[].datasourceVersion` | string | 否 | 数据库版本；工作区为 `null` |
| `nodes[].lifecycleStageCode` | string | 否 | 节点的生命周期阶段 |
| `relations` | object[] | 否 | 关系列表（边）；不传或为空时清空所有边 |
| `relations[].processId` | string | 否 | 当前（下游）数据集 ID |
| `relations[].flowId` | string | 否 | 流 ID |
| `relations[].upstreamProcessId` | string | 否 | 上游数据集 ID |
| `relations[].upstreamDatasourceCode` | string | 否 | 上游所属数据库 ID；工作区为 `null` |
| `relations[].upstreamDatasourceVersion` | string | 否 | 上游所属数据库版本；工作区为 `null` |

#### 响应

```json
{
  "success": true,
  "code": "200",
  "data": null
}
```

#### 错误情况

| code | message | 说明 |
|---|---|---|
| `400` | modelId不能为空 | `modelId` 为空 |

---

## 三、接口汇总

| # | 方法 | 路径 | 说明 |
|---|---|---|---|
| 1 | POST | `/model/create` | 新建模型 |
| 2 | POST | `/model/saveForm` | 保存表单信息（baseInfo/managerInfo/validationInfo） |
| 3 | GET | `/model/detail` | 查询模型详情（全量） |
| 4 | POST | `/model/my/list` | 我的模型列表（分页） |
| 5 | POST | `/model/list` | 全量模型列表（分页） |
| 6 | POST | `/model/copy` | 复制模型 |
| 7 | DELETE | `/model/delete` | 删除模型（软删） |
| 9a | GET | `/model/my/statistics` | 我的统计卡片 |
| 9b | GET | `/model/all/statistics` | 全部统计卡片 |
| 10 | GET | `/modelCanvas/upstreamCandidates` | 查询可选上游列表 |
| 11 | GET | `/modelCanvas/detail` | 获取 Canvas 绘图展示（含变更感知） |
| 12 | GET | `/modelCanvas/raw` | 获取原始关系图数据 |
| 13 | POST | `/modelCanvas/addUpstream` | 添加上游节点关系 |
| 14 | POST | `/modelCanvas/deleteRelation` | 删除关系 |
| 15 | POST | `/modelCanvas/updateStage` | 更新生命周期阶段 |
| 16 | POST | `/modelCanvas/save` | 实时保存 Canvas（全量覆盖） |
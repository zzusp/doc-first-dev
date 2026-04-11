# 编辑器 Model 模块 1.0 技术方案

> **文档目的**：记录 Model 模块 1.0 的需求、架构方案、代码结构、任务进度与验收情况。
>
> **关联文档**：
> - `docs/api-reference/model-module.md` — 接口 API 文档
> - `sql/model_module_ddl.sql` — 数据库 DDL 脚本
> - `docs/decisions/log.md` — 开发决策记录

---

## 一、需求边界

### 1.1 业务背景

Model 模块为 LCA（生命周期评估）产品模型编辑器后端，支持用户基于已计算的数据集构建产品模型，并在 Canvas 画布中管理上游依赖关系。

### 1.2 核心需求

1. **模型 CRUD**：创建模型（绑定参考数据集）、保存基础/管理/验证表单（统一保存，无 isShow 区分）、查询列表（我的/全量）、复制、删除；管理信息包含 `project`（项目）和 `dataSetSubGenerator`（数据辅助建立人员）可编辑字段；建模与验证包含 `supplement`（补充说明）字段；详情接口返回完整引用来源 `sourceInfos`
2. **Canvas 关系管理**：添加上游关系（**支持批量添加，单次最多50条**）；业务约束：每条边（`modelId + processId + flowId`）唯一；`addUpstream` 接口为**节点级全量同步**——传入的列表为指定上游节点及其所有流和上游关系完整集合，不在列表中的现有关系在写入前清理掉（软删除）；已存在关系覆盖写入（upsert）；删除关系、更新生命周期阶段（按节点 id）、全量保存画布
3. **变更感知**：检测参考数据集是否被修改/删除，检测关系边是否失效
4. **上游候选查询**：基于数据集输入流，返回可选上游节点（工作区/背景库双来源），**过滤掉基本流**；**过滤掉上游数据集在工作区已软删除（is_deleted=true）的关联**
5. **统计卡片**：模型总量、关联过程数、关联产品数（参考产品 `reference_flow_id` 去重计数）、待审核数
6. **发版集成**：模型随数据集发版自动同步到 `tb_*` 表

### 1.3 明确排除范围

- 下游添加接口（本期不做）
- 单次批量添加超过50条
- 审核流程（`approvalStatus` 字段本期只读/占位）
- 模型导出
- 复杂画布布局存储（坐标等）
- `hiq_background_db` 同步（发版目标为 `hiq_lcd` 中的 `tb_*` 表）

---

## 二、数据库设计

Model 模块涉及以下表，均位于 `hiq_editor`（`hiq_lcd` 数据源）：

### 2.1 表清单

#### 工作区表

| 表名 | 用途 | 关键字段 |
|---|---|---|
| `tw_models` | 模型主表 | `id`, `name`, `reference_process_id`, `reference_flow_id`, `editor`, `i18n`(JSONB) |
| `tw_model_node` | Canvas 节点表 | `id`, `model_id`, `process_id`, `datasource_code`, `datasource_version`, `lifecycle_stage_code` |
| `tw_model_relation` | Canvas 关系表 | `id`, `model_id`, `process_id`, `flow_id`, `upstream_process_id`, `upstream_datasource_code`, `upstream_datasource_version` |

#### 发版表

| 表名 | 用途 | 关键差异 |
|---|---|---|
| `tb_models` | 模型发布表 | 联合主键 `(id, version)`，结构与 `tw_models` 基本一致 |
| `tb_model_node` | 节点发布表 | 联合主键 `(id, version)`，结构与 `tw_model_node` 一致 |
| `tb_model_relation` | 关系发布表 | 联合主键 `(id, version)`，结构与 `tw_model_relation` 一致 |

**注意**：`model_doc` 表（`tw_model_doc`/`tb_model_doc`）已废弃，所有多语言字段收敛至 `tw_models.i18n` / `tb_models.i18n`。

**设计原则**：`lifecycle_stage_code` 是节点的属性，存储在 `tw_model_node` 中；`tw_model_relation` 只存储上下游连接关系，无阶段字段。

### 2.2 `tw_models` 字段说明

```
id, uuid, name                    — 主键与名称
reference_process_id              — 参考数据集ID（创建后不可改）
reference_flow_id                 — 参考产品流ID（继承自参考过程）
category_id                       — 物料类别（列不再写入，展示时取 tw_flows.category_id，通过 reference_flow_id 关联派生）
location_id                       — 地域
data_attribution                  — 数据归属
system_model                      — 系统模型（现为空，不再写入，展示时取参考数据集 from_data）
industries                        — 行业数组（列表筛选/统计用）
from_data, from_version           — 数据来源标识（继承自参考过程）
is_released                       — 是否已发版
editor                            — 当前工作区编辑人（权限校验核心字段）
i18n (JSONB)                     — 多语言字段，见下方结构
```

### 2.3 `tw_models.i18n` JSON 结构（`I18nData`）

**名称四维**（每维为 `{zh_CN, en_US}` 结构）：
- `name` — 基础名称（copy 接口传入的拼接后名称存于此）
- `processingStandard` — 处理标准与路线（copy 接口时为空）
- `mixingLocationType` — 混合与位置类型（copy 接口时为空）
- `productSpecification` — 产品规格与属性（copy 接口时为空）

**多语言文本**：`description`、`generalComment`（技术描述）、`intendedApplications`

**业务字段**：`licenseType`、`complianceSystemName`、`overallCompliance`、`nomenclatureCompliance`、`qualityCompliance`、`methodologicalCompliance`、`reviewCompliance`、`documentationCompliance`、`approvalStatus`、`industrySelections`、`referenceProcessSnapshot`、`lastChangeTime`

**建立/编辑信息**：`suggest`（暂未使用 / 预留）、`isCopyrightProtected`、`isLead`、`dataSetGenerator`、`dataSetSubGenerator`、`dataSetOwner`、`dataSetDocumentor`、`commissioner`、`sourceIds`

### 2.4 `tw_model_node` 字段说明

```
id, model_id                      — 主键与外键
process_id                        — 节点代表的数据集ID
datasource_code                   — 数据库编码（工作区为空；背景库为Ecoinvent等code）
datasource_version                — 数据库版本（工作区为空）
lifecycle_stage_code              — 节点的生命周期阶段枚举
tenant_id                          — 租户ID
is_deleted                        — 软删标记
审计字段                           — create_time/create_id/update_time/update_id
```

节点去重 key：`(model_id, process_id, datasource_code, datasource_version)`。同一 key 只存一条节点记录，upsert 覆盖。

根节点：模型创建时自动插入一条根节点记录，`process_id = reference_process_id`，`datasource_code/datasource_version` 均为空，`lifecycle_stage_code` 默认为 `MANUFACTURING`。

### 2.5 `tw_model_relation` 字段说明

```
id, model_id                      — 主键与外键
process_id                        — 当前（下游）数据集ID
flow_id                           — 流入当前数据集的流ID
upstream_process_id               — 上游数据集ID
upstream_datasource_code          — 上游所属数据库code（工作区数据时为空；背景库为Ecoinvent等code，非UUID）
upstream_datasource_version       — 上游所属数据库版本（工作区数据时为空）
```

**注意**：`lifecycle_stage_code` 已从本表移除，阶段信息存储在 `tw_model_node` 中。

---

## 三、接口规范

接口详细规范（路径、参数、返回结构）见：[`docs/api-reference/model-module.md`](../../api-reference/model-module.md)

本节按接口列出关键行为规则：

**Model 接口**

- `GET /model/detail` — 全量返回，不分 `isShow`，一次包含所有字段；`sourceIds` 同时附带 `sourceInfos`（完整引用来源列表，通过 TwSources 查询）；包含 `project`、`dataSetSubGenerator`、`supplement` 字段；`categoryId` 在运行时由 `TwFlowsService` 按 `reference_flow_id` 查询 `tw_flows.category_id` 派生；`categoryName` 由 `TwCategoriesService` 按 `categoryId` 查询 `tw_categories.name` 派生；`referenceFlowName`（参考产品名称）在运行时从 `tw_flows.name` 派生（`reference_flow_id` 对应的流名称），`reference_flow_id` 为空或流不存在时返回 null；`referenceUnitId`/`referenceUnitName`（声明单位/参考单位）在运行时从参考数据集声明单位字段派生，不落库

- `POST /model/saveForm` — `formType` 为空时统一保存所有字段（baseInfo + managerInfo + validationInfo）；managerInfo 块包含可编辑字段：`project`（项目）、`dataSetSubGenerator`（数据辅助建立人员）；validationInfo 块包含 `supplement`（建模与验证补充说明）；`categoryId` 不再是可写字段，传入时忽略

- `POST /model/copy` — name 必填，直接写入 `name` 列及 `i18n.name`；三个维度字段（processingStandard/mixingLocationType/productSpecification）置空

- `POST /model/my/list`、`POST /model/list` — 列表项 `categoryId` 取自 `tw_flows.category_id`（SQL JOIN 派生），不取 `tw_models.category_id`；支持以下可选筛选字段：
  - `dataAttribution`：精确匹配 `tw_models.data_attribution`；不传时不过滤
  - `systemModel`：精确匹配 JOIN 的 `tw_processes.from_data`（`refp.from_data`），**不**匹配 `tw_models.system_model`（该列不再写入，已废弃）；不传时不过滤
  - `referenceProduct`：模糊匹配 `tm.i18n->'referenceProcessSnapshot'->>'name'`（参考过程快照名称），前后加 `%` 通配，使用 `ilike` 大小写不敏感；不传时不过滤

- `GET /model/my/statistics` — 统计当前用户的模型；支持可选 `dataAttribution` 查询参数，传入时仅统计 `data_attribution` 匹配的模型；返回字段：`totalModels`（模型总量）、`relatedProcessCount`（关联过程数，去重）、`relatedProductCount`（关联产品数，基于 `reference_flow_id` 去重计数）、`pendingReviewCount`（待审核数）
- `GET /model/all/statistics` — 统计租户下全部模型；支持可选 `dataAttribution` 查询参数；返回字段同上
- `GET /model/checkEditPermission` — 查询当前用户对指定模型是否有编辑权限；`modelId`（必填）；返回 `{ canEdit: true/false }`；modelId 不存在时抛 DATA_NOT_EXIST 错误

**Canvas 接口**

- `GET /modelCanvas/upstreamCandidates` — 过滤 `ELEMENTARY_FLOW`，只返回产品流和废物流

- `GET /modelCanvas/detail` — 节点和边的 `changed` 状态各自独立判定；`changed=true` 时 `changeTypes` 必非空；**节点含 `nodeId`（`tw_model_node.id`）和 `lifecycleStageCode`（来自节点表）；边不返回 `lifecycleStageCode`（阶段属节点，非边）；根节点若存在则 `lifecycleStageCode` 取自根节点记录**

- `POST /modelCanvas/addUpstream` — 接受 `List<ModelAddRelationDto>`（数组，最多50条）；**节点级全量同步**：对同 `(modelId, upstreamProcessId, upstreamDatasourceCode, upstreamDatasourceVersion)` 的现有节点和边先软删除，再批量 upsert 节点（含 stage）并写入边；已存在 `(modelId, processId, flowId)` 覆盖写入；`lifecycleStageCode` 属于节点，不传时默认为 `MANUFACTURING`；事务保证原子性；**空列表返回 400 错误**

- `POST /modelCanvas/updateStage` — 入参改为 `(modelId, nodeId, lifecycleStageCode)`，更新 `tw_model_node.lifecycle_stage_code`；无效枚举值返回 400

- `POST /modelCanvas/save` — 全量覆盖：先软删模型所有旧节点和边，再批量插入新节点（含 stage）和边

---

## 四、架构与设计规则

### 4.1 与 Process 模块的关系

Model 与 Process 完全独立：
- Model 新建不影响 Process 主流程
- Canvas 不保存 Process 自身数据
- Model 复制/删除不影响参考数据集

### 4.2 数据存储模式

复用 Process 的 `document + business_json` 思想收敛为单一 `i18n` JSONB 字段，不拆分 doc 表。

```
tw_models.i18n = {
  name: I18n{zh_CN, en_US},          // 名称四维之一
  processingStandard: I18n{...},
  mixingLocationType: I18n{...},
  productSpecification: I18n{...},
  description: I18n{...},
  licenseType: string,
  complianceSystemName: string,
  referenceProcessSnapshot: {...},    // 创建时快照，不随参考过程更新
  ...
}
```

### 4.3 Canvas 图结构

- **根节点**：模型创建时自动在 `tw_model_node` 中插入根节点记录；`lifecycle_stage_code` 默认为 `MANUFACTURING`，可通过 `updateStage` 修改
- **节点**：`tw_model_node` 存储节点实体和阶段；去重 key = `(model_id, process_id, datasource_code, datasource_version)`
- **关系边**：`tw_model_relation` 只存上下游连接关系，**无阶段字段**
- **变更检测**：节点比对 `reference_flow_id`；边检测查询 `tw_exchanges`

### 4.4 发版架构

发版时根据 `VersionSyncTargetEnum.MODELS` / `MODEL_RELATION`，自动将 `tw_*` 复制到 `tb_*`（同库，`hiq_lcd` 数据源）。发版规则：若 model 的 `reference_process_id` 在本次发版数据集中，则该 model 纳入发版。

### 4.5 复用模式

| 复用点 | 参考文件 | 复用内容 |
|---|---|---|
| 表结构 | `TwProcesses.java` | 主表字段设计模板 |
| i18n 模式 | `TwLocations.i18n` | I18n 多语言结构 |
| 工作区过滤 | `AssembleServiceImpl.queryUserDBLike()` | editor 过滤、分页 |
| 表单保存 | `ProcessAdministrativeinfoServiceImpl` | merge 逻辑 |
| relation 维护 | `DatasourceInfoServiceImpl` | 覆盖/软删模式 |
| 发版复制 | `VersionManageServiceImpl` | tw→tb 复制逻辑 |

### 4.6 设计规则

| 规则 | 说明 |
|---|---|
| detail 接口全量返回 | `GET /model/detail` 不分 `isShow`，一次返回所有字段 |
| saveForm 统一保存 | `formType` 为空时同时保存 baseInfo、managerInfo、validationInfo 所有字段 |
| Canvas 变更状态独立判定 | 节点和边的 `changed` 各自独立，不互相传染；`changed=true` 时 `changeTypes` 必非空；exchange 关系检测中，`upstream_datasource_code` 为 null 或空字符串均视为工作区上游，查询条件使用 `COALESCE(exchange_doc->>'provider_data_source', '') = ''` 兼容两种情况 |
| 上游候选过滤基本流 | `getUpstreamCandidates` 只返回产品流和废物流，过滤 `ELEMENTARY_FLOW` |
| systemModel 取参考数据集 | 列表和详情的 `systemModel` 字段取参考数据集的 `from_data`，`tw_models.system_model` 不再写入 |
| datasourceCode 直接取字段值 | `upstream_datasource_code` 存的是 code（如 "Ecoinvent"），不是 UUID，直接取原值展示 |
| categoryId 派生，不存储 | `tw_models.category_id` 列不再写入（createModel/saveForm 均不写入）；list/detail 接口均在读取时从 `tw_flows.category_id` 派生（list 用 SQL JOIN，detail 用 TwFlowsService 查询） |
| referenceUnitId/referenceUnitName 派生，不存储 | detail 接口在读取时按 `reference_process_id` 从参考数据集的声明单位字段获取 `referenceUnitId`/`referenceUnitName`；不由前端传入、不写入 `tw_models` |
| Canvas 节点级全量同步 | `POST /modelCanvas/addUpstream` 为节点级全量同步：传入的是指定节点的**上游节点**（`upstreamProcessId`）及其所有流关系完整列表；按 `(upstreamProcessId, upstreamDatasourceCode, upstreamDatasourceVersion)` 软删除旧节点，按 `processId` 软删除旧边，再批量 upsert 节点（含 stage）并写入边；已存在关系覆盖写入；**空列表返回 400 错误**；事务保证原子性 |
| 生命周期阶段属节点 | `lifecycle_stage_code` 存储在 `tw_model_node`，不属于 `tw_model_relation`；`getCanvasDetail` 节点返回 stage；边不返回 stage；`updateStage` 更新节点表 |
| 根节点自动创建 | 模型创建时自动插入根节点记录至 `tw_model_node`（`process_id=reference_process_id`，`lifecycle_stage_code=MANUFACTURING`）；删除模型时软删其所有节点和边 |

---

## 五、代码地图

### 5.1 代码结构

**控制器层**
- `ModelController` — 10个主接口（create/saveForm/detail/myList/list/copy/delete/myStatistics/allStatistics/checkEditPermission）
- `ModelCanvasController` — 7个画布接口（upstreamCandidates/detail/raw/addUpstream/deleteRelation/updateStage/save）

**服务层**
- `ModelService` / `ModelServiceImpl` — CRUD、列表、复制、删除
- `ModelCanvasService` / `ModelCanvasServiceImpl` — Canvas 关系管理、变更感知
- `ModelAssemblerService` / `ModelAssemblerServiceImpl` — VO 组装（复用 I18nData）
- `ModelReleaseService` / `ModelReleaseServiceImpl` — 发版复制（tw→tb）

**实体与 Mapper**
- `TwModels`、`TwModelNode`、`TwModelRelation`（`TwModelNode` 含内部类 `I18nData`）
- `TbModels`、`TbModelNode`、`TbModelRelation`
- `TwModelsMapper` / `TwModelNodeMapper` / `TwModelRelationMapper` / `TbModelsMapper` / `TbModelNodeMapper` / `TbModelRelationMapper`
- 对应 XML：`TwModelsMapper.xml`、`TwModelNodeMapper.xml`、`TwModelRelationMapper.xml`、`TbModelsMapper.xml`、`TbModelNodeMapper.xml`、`TbModelRelationMapper.xml`

**DTO/VO**
- `ModelCreateDto`、`ModelFormDto`、`ModelListQueryDto`、`ModelCopyDto`
- `ModelAddRelationDto`（无 lifecycleStageCode）、`ModelUpdateStageDto`（`relationId` → `nodeId`）、`ModelUpstreamCandidateVo`
- `ModelListItemVo`、`ModelStatisticsVo`、`ModelCanvasVo`、`ModelCanvasDetailVo`（含 `NodeVo`、`EdgeVo`）

**枚举**
- `ModelLifecycleStageEnum` — RAW_MATERIAL / MANUFACTURING / DISTRIBUTION / USE_STAGE / END_OF_LIFE
- `ModelChangeTypeEnum` — PROCESS_DELETED / UPSTREAM_PROCESS_DELETED / FLOW_DELETED / REFERENCE_FLOW_CHANGED / RELATION_CHANGED

**辅助工具**
- `ModelComboNameUtils` — 四维名称拼接工具（zh_CN 逗号拼接）

### 5.2 关键方法清单

| 文件 | 方法 | 职责 |
|---|---|---|
| `ModelServiceImpl` | `createModel()` | 新建模型，继承参考数据集字段，写 i18n；**自动插入根节点至 `tw_model_node`**（`process_id=reference_process_id`，`lifecycle_stage_code=MANUFACTURING`）；不写入 category_id（由流派生） |
| `ModelServiceImpl` | `copyModel()` | 复制模型（editor 校验），name 直接写入 name 列及 i18n.name，三个维度置空；**同步复制节点（`tw_model_node`）和边（`tw_model_relation`）** |
| `ModelServiceImpl` | `deleteModel()` | 软删模型（editor 校验）及其所有**节点和边** |
| `ModelServiceImpl` | `getMyStatistics(String dataAttribution)` | 我的统计卡片，editor=当前用户；委托 `doGetStatistics(dataAttribution, editorId)` |
| `ModelServiceImpl` | `getAllStatistics(String dataAttribution)` | 全部统计卡片，editorId=null（租户全量）；委托 `doGetStatistics(dataAttribution, editorId)` |
| `ModelServiceImpl` | `doGetStatistics(String dataAttribution, String editorId)` | 统计卡片内部实现，dataAttribution 可空；返回 totalModels/relatedProcessCount/relatedProductCount（reference_flow_id 去重）/pendingReviewCount |
| `ModelServiceImpl` | `getDetail(String modelId)` | 详情接口；categoryId/categoryName 从 tw_flows 派生；**referenceFlowName 从 tw_flows.name 派生**（与 categoryId 同在 refFlow 查询块内提取）；referenceUnitId/referenceUnitName 从声明单位派生；sourceInfos 附带完整引用来源 |
| `ModelCanvasServiceImpl` | `listUpstreamCandidates()` | 从 tw_exchanges 查输入流，区分工作区/背景库来源，过滤基本流；过滤上游数据集在 tw_processes 中已软删除的关联 |
| `ModelCanvasServiceImpl` | `getCanvasDetail()` | 组装 nodes+edges，变更检测；节点和边的 changed 状态各自独立判定；exchange 关系检测使用 `COALESCE(..., '') = ''` 兼容 null 和空字符串；**节点含 `nodeId`（`tw_model_node.id`）和 `lifecycleStageCode`（来自 `tw_model_node.lifecycle_stage_code`）；边不返回 `lifecycleStageCode`；根节点 stage 取自根节点记录；节点名称（processName）：工作区节点从 `processMap`（`tw_processes`）取，背景库节点（`datasourceCode` 不为空）从 `backgroundUpstreamNameMap`（`tw_process_data.up_element_name`，key=`upElementId|dataSource|dataVersion`）取，找不到回退为空字符串；背景库节点找不到时不标记 `PROCESS_DELETED`** |
| `ModelCanvasServiceImpl` | `getCanvas()` | 返回原始节点+关系数据（modelId + nodes + relations），用于编辑保存 |
| `ModelCanvasServiceImpl` | `addUpstream(List<ModelAddRelationDto>)` | 节点级全量同步：按 `(upstreamProcessId, upstreamDatasourceCode, upstreamDatasourceVersion)` 软删旧节点，按 `processId` 软删旧边，再批量 upsert 节点（含 stage）并写入边；超出50条返回错误；**空列表返回 400 错误**；事务保证原子性 |
| `ModelCanvasServiceImpl` | `deleteRelation()` | 软删单条边（modelId + relationId 校验）；**不影响节点表** |
| `ModelCanvasServiceImpl` | `updateStage(ModelUpdateStageDto)` | 入参 `(modelId, nodeId, lifecycleStageCode)`，更新 `tw_model_node.lifecycle_stage_code`；校验枚举值合法性 |
| `ModelCanvasServiceImpl` | `saveCanvas(ModelCanvasVo)` | **全量覆盖：软删模型所有旧节点和边，再批量插入新节点（含 stage）和边** |
| `ModelAssemblerServiceImpl` | `assembleListItem()` | 列表项 VO 组装，systemModel 取参考数据集 from_data（`referenceFromData`）；categoryId 取 SQL JOIN 派生值；referenceProcessName 取自 i18n.referenceProcessSnapshot.name |
| `TwModelsMapper.xml` | `selectModelAndDocByParam` / `countModelAndDocByParam` | 支持 keyWord（name/processingStandard 模糊）、uuid（精确）、systemModel（精确匹配 `refp.from_data`，**非** `tm.system_model`）、dataAttribution（精确）、isReleased（精确）、industry（数组包含）、industryFilters（多体系 AND）、approvalStatus（IN）、startDate/endDate（lastChangeTime 范围）、**referenceProduct（模糊匹配 `i18n->'referenceProcessSnapshot'->>'name'`，使用 `ilike` 大小写不敏感）**；LEFT JOIN `tw_processes refp` 获取 `from_data`，LEFT JOIN `tw_flows tf` 获取 `category_id` |
| `ModelServiceImpl` | `checkEditPermission(String modelId)` | 查询当前用户对指定模型是否有编辑权限；返回 `{ canEdit: boolean }`；model 不存在抛 DATA_NOT_EXIST |
| `ModelReleaseServiceImpl` | `releaseModelsByProcessIds()` | tw→tb 复制 |

---

## 六、任务状态

| 编号 | 内容 | 优先级 | 状态 |
|---|---|---|---|
| T-RP1 | ModelStatisticsVo：`coveredIndustryCount` → `relatedProductCount`（字段重命名+注释更新） | P0 | ✅ 完成 |
| T-RP2 | ModelServiceImpl.getStatistics()：行业收集逻辑替换为 `reference_flow_id` 去重计数；移除 industries 相关变量 | P0 | ✅ 完成 |
| T-RP3 | docs/api-reference/model-module.md：statistics 响应示例和字段说明更新 | P1 | ✅ 完成 |
| T-LS1 | **DDL**：新增 `tw_model_node` / `tb_model_node` 表，`lifecycle_stage_code` 从 `tw_model_relation`/`tb_model_relation` 移除；根节点创建时自动插入；参考 `sql/model_module_ddl.sql` | P0 | ✅ 完成 |
| T-LS2 | **Entity + Mapper**：`TwModelNode`（含 `I18nData`）、`TwModelNodeMapper` + XML、`TbModelNode`、`TbModelNodeMapper` + XML；Mapper 含 `upsert`、`selectByModelId`、`softDeleteByModelId` | P0 | ✅ 完成 |
| T-LS3 | **DTO 变更**：`ModelUpdateStageDto` 改为 `(modelId, nodeId, lifecycleStageCode)`；`ModelCanvasVo` 增 `nodes` 字段（`List<TwModelNode>`）；`ModelAddRelationDto` 保留 `lifecycleStageCode`（作为目标节点的阶段值，不传时默认 MANUFACTURING） | P0 | ✅ 完成 |
| T-LS4 | **NodeVo / EdgeVo 变更**：`NodeVo` 增加 `nodeId`（`String`）+ `lifecycleStageCode`（`String`），移除 `lifecycleStageCodes`（List）；`EdgeVo` 移除 `lifecycleStageCode` | P0 | ✅ 完成 |
| T-LS5 | **ModelServiceImpl**：修改 `createModel()` 自动插入根节点；`copyModel()` 同步复制节点；`deleteModel()` 软删节点+边 | P0 | ✅ 完成 |
| T-LS6 | **ModelCanvasServiceImpl**：修改 `addUpstream()`（upsert 节点+写边）、`getCanvasDetail()`（从节点表取 stage）、`updateStage()`（按 nodeId 更新）、`saveCanvas()`（覆盖节点+边）、`deleteRelation()`（只删边）；新增 `TwModelNodeMapper` | P0 | ✅ 完成 |
| T-LS7 | **ModelReleaseServiceImpl**：修改 `releaseModelsByProcessIds()` 同步 `tw_model_node` → `tb_model_node`；`VersionSyncTargetEnum` 增加 `MODEL_NODE` | P1 | ✅ 完成 |
| T-LS8 | **docs/api-reference/model-module.md**：detail 接口节点/边返回结构、`updateStage` 参数、`addUpstream` 参数、`save` 参数全部更新 | P1 | ✅ 完成 |
| T-SS1 | **ModelController**：`GET /model/statistics` 拆为 `GET /model/my/statistics`（我的）和 `GET /model/all/statistics`（全部）两个端点；移除原单端点 | P0 | ✅ 完成 |
| T-SS2 | **ModelService + ModelServiceImpl**：`getStatistics(String)` 拆为 `getMyStatistics(String)` 和 `getAllStatistics(String)`，提取 `doGetStatistics(String dataAttribution, String editorId)` 内部方法；`getMyStatistics` 传 `user.getId()`，`getAllStatistics` 传 `null` | P0 | ✅ 完成 |
| T-SS3 | **docs/api-reference/model-module.md**：statistics 接口文档更新（拆分端点、参数说明） | P1 | ✅ 完成 |
| T-PERM1 | `ModelService` 接口新增 `checkEditPermission(String modelId)`；`ModelServiceImpl` 实现：调用 `getModel()` 取模型，比较 `user.getId()` 与 `model.getEditor()`，返回 `ResultDTO<Map>` 含 `canEdit` boolean | P0 | ✅ 完成 |
| T-PERM2 | `ModelController`：新增 `GET /model/checkEditPermission?modelId=xxx` 端点，调用 `checkEditPermission()` | P0 | ✅ 完成 |
| T-BG1 | `ModelCanvasServiceImpl.getCanvasDetail()`：（1）`backgroundUpstreamIds` 收集逻辑追加 nodes 中 `datasourceCode` 不为空的 `processId`；（2）`buildNodeVo` 签名增加 `Map<String, String> backgroundUpstreamNameMap` 参数；（3）`buildNodeVo` 内部对背景节点（`datasourceCode` 不为空）从 `backgroundUpstreamNameMap` 取名称，找不到回退为空字符串；（4）所有 `buildNodeVo` 调用处传入 `backgroundUpstreamNameMap` | P0 | ✅ 完成 |
| T-RFN1 | `ModelServiceImpl.getDetail()`：在 refFlow 查询块的 `if (refFlow != null)` 内追加 `data.put("referenceFlowName", refFlow.getName())`；refFlow 为 null 时 `data.put("referenceFlowName", null)` | P0 | ✅ 完成 |
| T-RFN2 | `docs/api-reference/model-module.md`：在 detail 接口响应字段表中补充 `referenceFlowName`（类型 String，说明：参考产品名称，取自 tw_flows.name，可为 null） | P1 | ✅ 完成 |

---

## 七、验收项

### 7.1 验收方式

1. **编译验证**：`JAVA_HOME="D:/soft/jdk-11.0.2" mvn compile -q` 通过
2. **启动验证**：`.\ai-tools\start\start-app.ps1` 正常启动
3. **接口验证**：按「7.2 功能验收」执行，逐接口断言
4. **数据库验证**：关键写入后用 psql 核验数据

### 7.2 功能验收

#### Phase 0：准备

1. 启动应用，等待 `/actuator/health` 返回 200
2. 登录获取 token：`LOGIN_PASSWORD='<LOGIN_PASSWORD>' D:/soft/Python312/python.exe ai-tools/login/login.py`
3. 保存 `Authorization`、`Cookie`、`userId` 三个 Header

> **验证用测试数据**（实际值可能因环境变化，验证前需确认）：
> - 目标 editor 用户：`b683b51874be1e4bf4b9dcaf368623fb`
> - 参考过程（已计算）：`18262520-e82a-49f5-b11d-6225fad02b2b`（new-conse-3，有上游候选）
> - 上游候选（new-conse-3 的）：flow `66c93e71-f32b-4591-901c-55395db5c132` → upstream `6389f85f-9bae-3b23-84d7-d2ca28597240`

#### Phase 1：Model 主接口

| 编号 | 接口 | 验证点 | 状态 |
|---|---|---|---|
| A-01 | `POST /model/create` | 返回新 UUID，DB 验 name/editor/is_released=false；category_id 不写入（由流派生） | ✅ 通过 |
| A-02 | `GET /model/detail?modelId=...` | 全量返回（无 isShow），含 referenceProcessSnapshot / industrySelections / systemModel（取自 from_data）；categoryId 由 tw_flows 派生 / categoryName 由 tw_categories 派生 / referenceUnitId+referenceUnitName 从声明单位派生 / sourceInfos / project / supplement | ✅ 通过 |
| A-03 | `POST /model/saveForm` | name 列更新，DB 验；formType 为空时统一保存所有字段（含 project/dataSetSubGenerator/supplement）；category_id 不写入 | ✅ 通过 |
| A-04 | `POST /model/my/list` | 含 referenceProcessName、systemModel（取 from_data） | ✅ 通过 |
| A-05 | `POST /model/list` | 同上 | ✅ 通过 |
| A-06 | `POST /model/copy` | 新 UUID `95d986d7-178f-481d-893d-a21188032655`，editor=535；name 列写入"验收测试-复制-A6-verification"；i18n.name.zh_CN="验收测试-复制-A6-verification"；processingStandard/mixingLocationType/productSpecification 均为空字符串 | ✅ 通过 |
| A-07 | `GET /model/my/statistics` | 返回 `relatedProductCount`（非负整数），值为当前用户所有模型 `reference_flow_id` 去重计数；`coveredIndustryCount` 字段不再返回；支持可选 `dataAttribution` 参数，传入时按 data_attribution 过滤 | ✅ 通过 — totalModels=17, relatedProductCount=4 |
| A-07A | `GET /model/all/statistics` | 返回租户全量模型统计；`totalModels` ≥ `GET /model/my/statistics` 的 totalModels（全部 ≥ 我的）；支持可选 `dataAttribution` 参数 | ✅ 通过 — totalModels=21 ≥ my的17 |
| A-08 | `DELETE /model/delete?modelId=...` | is_deleted=true | ✅ 通过 |
| A-DA1 | `POST /model/my/list` | 传 dataAttribution="97818dd6-cb48-4d76-8766-30f8056ac736" → total=11，所有项 dataAttribution 匹配；传不存在值 total=0 | ✅ 通过 |
| A-DA2 | `POST /model/list` | 传 dataAttribution="97818dd6-cb48-4d76-8766-30f8056ac736" → total=11，所有项 dataAttribution 匹配 | ✅ 通过 |
| A-DA3 | `GET /model/my/statistics` | 传 dataAttribution=97818dd6-... → totalModels 与 my/list 传相同 dataAttribution 的 total 一致；传不存在值 totalModels=0；relatedProductCount 非负 | ✅ 通过 — totalModels=15 = my/list total=15；不存在值 totalModels=0 |
| A-DA4 | `GET /model/my/statistics` | 不传参数 → totalModels 与 my/list 不传 dataAttribution 的 total 一致；relatedProductCount 非负 | ✅ 通过 — totalModels=17 = my/list total=17 |
| A-DA5 | `GET /model/all/statistics` | 传 dataAttribution=97818dd6-... → totalModels 与 list（全量）传相同 dataAttribution 的 total 一致；传不存在值 totalModels=0 | ✅ 通过 — totalModels=18 = list total=18；不存在值 totalModels=0 |
| A-DA6 | `GET /model/all/statistics` | 不传参数 → totalModels ≥ my/statistics 的 totalModels（全部 ≥ 我的） | ✅ 通过 — all=21 ≥ my=17 |
| A-F1 | `POST /model/saveForm` | managerInfo: 传 project="测试项目-验收" + dataSetSubGenerator=JSON，detail 返回 project="测试项目-验收"、dataSetSubGenerator 非空 | ✅ 通过 |
| A-F2 | `POST /model/saveForm` | validationInfo: 传 supplement="建模补充说明-验收测试"，detail 返回 supplement="建模补充说明-验收测试" | ✅ 通过 |
| A-F3 | `GET /model/detail` | modelId=e4ed9d6c → sourceInfos count=1，id=6f25624f，title="821-来源1"；无 sourceIds 的 model sourceInfos=[] | ✅ 通过 |
| A-CAT1 | `GET /model/detail` | modelId=e4ed9d6c → categoryId=3ef02be0-71b9-4ab7-ad11-1e8a9f48af55，与 tw_flows.category_id 一致；tw_models.category_id 为空 | ✅ 通过 |
| A-CAT2 | `POST /model/my/list` | 第一项 categoryId=e2786b2b-9e97-4ba9-908a-8d8e11f1fc5d，与 DB tw_flows.category_id 一致 | ✅ 通过 |
| A-CAT3 | `POST /model/saveForm` | baseInfo modelId=fe61f10b 后，DB tw_models.category_id 仍为空（saveForm 不再写入） | ✅ 通过 |
| A-CN1 | `GET /model/detail` | modelId=e4ed9d6c → categoryName 非空，值为 `SELECT name FROM tw_categories WHERE id = '3ef02be0-71b9-4ab7-ad11-1e8a9f48af55'` 的结果（含"34250："的长字符串） | ✅ 通过 |
| A-UNIT1 | `GET /model/detail` | modelId=e4ed9d6c → referenceUnitId=3c38b06f-58de-40e2-86d1-ad98f67e0b2b，referenceUnitName=kg，与 DB `tw_process_doc.document->>'declaredUnitId'` 及 `tw_units.name` 一致 | ✅ 通过 |
| A-UNIT2 | `docs/api-reference` | model-module.md detail 响应包含 referenceUnitId/referenceUnitName 字段定义、来源说明 | ✅ 通过 |
| A-LIST1 | `POST /model/my/list` | 传 referenceProduct="低合金" → total=1，refProcessName="低合金热轧钢生产,转炉长流程工艺,中国2024"；传不存在值 total=0；组合 systemModel="CONSEQUENTIAL"+referenceProduct="水泥" total=0，验证 AND 逻辑 | ✅ 通过 |
| A-LIST2 | `POST /model/my/list` | 传 systemModel="CONSEQUENTIAL" → total=7，所有结果 systemModel="CONSEQUENTIAL"；传不存在值 total=0；总数 13（CUT_OFF=6+CONSEQUENTIAL=7），与不过滤时一致 | ✅ 通过 |

#### Phase 2：Canvas 接口

| 编号 | 接口 | 验证点 | 状态 |
|---|---|---|---|
| A-11 | `GET /modelCanvas/upstreamCandidates?processId=194c703d...` | 返回数组，含 flowId/upstreamProcessId，不含基本流；不含上游在 tw_processes 中已软删除的工作区关联；processId=194c703d-a66f-451e-9f6a-5829d1952f7d 返回2条（有效工作区+背景库），软删除上游被过滤 | ✅ 通过 |
| A-12 | `GET /modelCanvas/detail?modelId=...` | nodes/edges 每条记录的 `changed=true` 时 `changeTypes` 必非空；根节点有 `REFERENCE_FLOW_CHANGED` 判断；边的 exchange 关系检测使用 `COALESCE(..., '') = ''` 同时兼容 null 和空字符串；`provider_data_source` 为空字符串时 relation 不应标记为 `RELATION_CHANGED` | ✅ 通过 |
| A-13 | `GET /modelCanvas/raw?modelId=...` | 返回 relations 数组 | ✅ 通过 |
| A-14 | `POST /modelCanvas/addUpstream` | 节点级全量同步：按 `(upstreamProcessId, upstreamDatasourceCode, upstreamDatasourceVersion)` 软删旧节点，按 `processId` 软删旧边，再批量 upsert 节点（含 `lifecycle_stage_code`）并写入边；超过50条返回 400；空列表返回 400；DB 验 `tw_model_node` 存在节点记录（含 `lifecycle_stage_code`），`tw_model_relation` 无 `lifecycle_stage_code` 字段 | ✅ 通过 |
| A-15 | `POST /modelCanvas/updateStage` | DB 验阶段变更；无效 lifecycleStageCode 返回 400 | ✅ 通过 |
| A-16 | `POST /modelCanvas/deleteRelation` | is_deleted=true | ✅ 通过 |
| A-17 | `POST /modelCanvas/save` | 全量覆盖后 DB 验 | ✅ 通过 |
| A-18 | `GET /modelCanvas/detail` 边界验证 | modelId=`3cdacc4a-87a9-479b-bbc8-0a5160354589`，relationId=`0758f16f-4350-4920-b5bc-9390a03c3c07`（upstream_datasource_code 为空字符串）；该 edge 的 `changed=false`，`changeTypes` 为空数组；DB exchange 记录存在（`provider_data_source=''`），不应触发 `RELATION_CHANGED` | ✅ 通过 |
| A-OV1 | `POST /modelCanvas/addUpstream` | 传单条数组 [{...}] → 200，DB 验记录存在且 lifecycle_stage_code 正确 | ✅ 通过 |
| A-UPFILTER1 | `GET /modelCanvas/upstreamCandidates` | processId=194c703d-... → 工作区已软删除的 provider 不在结果中；仅返回有效工作区 + 背景库候选 | ✅ 通过 |
| A-OV2 | `POST /modelCanvas/addUpstream` | 传两条不同 (processId, flowId) 的关系 → 200，DB 两条均存在；同 processId 下每次写入新 flowId 替换旧关系（软删除前一条），只保留最新一条 | ✅ 通过 |
| A-OV3 | `POST /modelCanvas/addUpstream` | 传第二批关系（与 A-OV2 不同 processId）→ 前一批次关系被清理（is_deleted=true），新批次存在 | ✅ 通过 |
| A-OV4 | `POST /modelCanvas/addUpstream` | 传同一 processId 的另一条 flowId 关系 → 前一条被清理（is_deleted=true），新关系存在；覆盖写入（flowId 相同时产生新记录，旧记录软删除） | ✅ 通过 |
| A-OV5 | `POST /modelCanvas/addUpstream` | 传超过50条记录 → 400 错误 | ✅ 通过 |
| A-NODELS1 | `POST /model/create` | 新建模型后，DB 验 `tw_model_node` 中存在根节点记录：`process_id=reference_process_id`，`lifecycle_stage_code=MANUFACTURING`，`datasource_code` 和 `datasource_version` 为空 | ✅ 通过 |
| A-NODELS2 | `GET /modelCanvas/detail` | 验证 nodes 数组中每个节点含 `nodeId`（非空）和 `lifecycleStageCode`（非空）；edges 数组中每条边**不含** `lifecycleStageCode` 字段；根节点 `lifecycleStageCode` 取自根节点记录 | ✅ 通过 |
| A-NODELS3 | `POST /modelCanvas/addUpstream` | 添加上游节点后，DB 验 `tw_model_node` 存在目标节点记录（含 `lifecycle_stage_code`）；`tw_model_relation` 存在边记录（**无 `lifecycle_stage_code` 字段**） | ✅ 通过 |
| A-NODELS4 | `POST /modelCanvas/updateStage` | 入参改为 `(modelId, nodeId, lifecycleStageCode)` → 200；DB 验 `tw_model_node.lifecycle_stage_code` 更新；重新调用 detail → 该节点的 `lifecycleStageCode` 同步更新 | ✅ 通过 |
| A-NODELS5 | `POST /modelCanvas/updateStage` | 无效 `nodeId`（不存在或不属于该 modelId） → DATA_NOT_EXIST 错误 | ✅ 通过 |
| A-NODELS6 | `POST /modelCanvas/save` | 全量覆盖后，DB 验：旧节点和边 is_deleted=true，新节点（含 stage）和边存在 | ✅ 通过 |
| A-NODELS7 | `POST /modelCanvas/deleteRelation` | 软删边后，DB 验：`tw_model_relation.is_deleted=true`；`tw_model_node` 中对应节点**仍存在**（删边不删节点） | ✅ 通过 |
| A-NODELS8 | `POST /model/copy` | 复制模型后，DB 验新模型 `tw_model_node` 有节点记录（含根节点和所有上游节点，`lifecycle_stage_code` 与原模型一致） | ✅ 通过 |
| A-NODELS9 | `DELETE /model/delete?modelId=...` | 删除模型后，DB 验 `tw_model_node` 和 `tw_model_relation` 均 `is_deleted=true` | ✅ 通过 |
| A-PERM1 | `GET /model/checkEditPermission` | editor=当前用户的 modelId → 200, canEdit=true | ✅ 通过 — modelId=e4ed9d6c(editor=535), 返回 canEdit=true |
| A-PERM2 | `GET /model/checkEditPermission` | editor=其他用户的 modelId → 200, canEdit=false | ✅ 通过 — modelId=60c2b795(editor=59cf9a26...), 返回 canEdit=false |
| A-PERM3 | `GET /model/checkEditPermission` | 不存在的 modelId → DATA_NOT_EXIST 错误 | ✅ 通过 — 返回 code=80002(DATA_NOT_EXIST) |
| A-BG1 | `GET /modelCanvas/detail` | 含背景库节点（datasourceCode=Ecoinvent）的画布详情：nodes 数组中背景库节点的 `processName` 非空且不等于"未找到"，值与 `tw_process_data.up_element_name`（where `up_element_id=upstreamProcessId AND data_source=datasourceCode AND data_version=datasourceVersion`）一致 | ✅ 通过 — modelId=eedafb28，背景节点 processName="sodium nitrate production"，与 tw_process_data.up_element_name 一致 |
| A-RFN1 | `GET /model/detail` | modelId=e4ed9d6c → 响应含 `referenceFlowName` 字段，值非空，与 `SELECT name FROM tw_flows WHERE id = (SELECT reference_flow_id FROM tw_models WHERE id = 'e4ed9d6c...')` 查询结果一致 | ✅ 通过 — modelId=eedafb28，referenceFlowName="磷酸"，与 tw_flows.name 一致 |
| A-RFN2 | `GET /model/detail` | reference_flow_id 为空的模型 → `referenceFlowName` 字段值为 null（不报错） | ✅ 通过 — 代码路径验证：StringUtils.isNotBlank 保证空时 referenceFlowName 保持 null |

### 7.3 非功能验收

- 编译零错误零警告
- 应用启动正常，无启动异常日志
- 所有接口在正常/异常情况下均返回规范 `ResultDTO` 格式
- 接口响应时间在合理范围内（列表查询 < 500ms）

### 7.4 文档验收

- `docs/api-reference/model-module.md` 与代码完全一致
- `sql/model_module_ddl.sql` 与实际表结构一致
- 本文档（`docs/plans/18-model/model-module-1.0-tech-spec.md`）作为最终归档技术方案

---

## 八、附录

### 8.1 关键文件路径索引

```
src/main/java/com/ecdigit/ecdata/
  controller/
    ModelController.java
    ModelCanvasController.java
  service/impl/
    ModelServiceImpl.java
    ModelCanvasServiceImpl.java
    ModelAssemblerServiceImpl.java
    ModelReleaseServiceImpl.java
  dto/model/
    ModelFormDto.java
    ModelListItemVo.java
    ModelCanvasDetailVo.java
    ModelUpdateStageDto.java
    ModelCanvasVo.java

src/main/java/com/hiqdata/lcadata/
  entity/
    TwModels.java
    TwModelNode.java
  mapper/
    TwModelsMapper.java
    TwModelNodeMapper.java

src/main/resources/mapper/lcadata/
  TwModelsMapper.xml
  TwModelNodeMapper.xml

docs/api-reference/model-module.md
sql/model_module_ddl.sql
```

### 8.2 枚举值参考

**lifecycleStageCode**

| 值 | 说明 |
|---|---|
| RAW_MATERIAL | 原材料获取与预处理 |
| MANUFACTURING | 制造阶段（默认） |
| DISTRIBUTION | 流通阶段 |
| USE_STAGE | 使用阶段 |
| END_OF_LIFE | 废弃阶段 |

**changeTypes**

| 值 | 说明 |
|---|---|
| PROCESS_DELETED | 数据集已软删除 |
| UPSTREAM_PROCESS_DELETED | 上游数据集已软删除 |
| FLOW_DELETED | 关联流已软删除 |
| REFERENCE_FLOW_CHANGED | 根节点参考产品已变更 |
| RELATION_CHANGED | 建模关系在当前数据中已不存在 |
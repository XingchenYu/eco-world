# V4 实施步骤

本文档把 `v4.0` 的设计目标拆成可按顺序执行的实施步骤。

目标不是继续堆功能，而是在不再做大重构的前提下，稳定把项目推进到多尺度虚拟生态世界。

## 总原则

- 先搭长期稳定骨架，再扩物种和玩法
- 先做独立关系系统，再做更多关键种
- 先做区域生态闭环，再做全球级扩展
- 每一步都要求可测试、可回归、可展示

## 当前基线

当前仓库已经具备：

- `WorldMap / Region / RegionSimulation / WorldSimulation`
- 模板、物种、关系、运行桥接注册表
- 区域级 `food_web`
- 区域级 `cascade`
- 关键种的区域状态反馈
- 关键种的轻量竞争反馈
- 已原生接入关键种：
  - `beaver`
  - `crocodile`
  - `hippopotamus`
  - `elephant`
  - `white_rhino`
  - `giraffe`

所以后续不再从零开始，而是在这个基线上分阶段推进。

---

## Phase 1：关系系统拆分

### Step 1
新建 `src/ecology/competition.py`

目标：
- 把当前 `cascade.py` 中的竞争关系和竞争反馈拆出去
- 建立统一的竞争摘要与竞争反馈入口

第一批迁移对象：
- `hippopotamus <-> nile_crocodile`
- `african_elephant <-> white_rhino`
- `african_elephant -> giraffe`

验收标准：
- `cascade.py` 只保留汇总职责
- 竞争逻辑不再写死在 `cascade.py`

当前状态：
- 已完成第一版落地
- 已新增 [competition.py](/Users/yumini/Projects/eco-world/src/ecology/competition.py)
- `WorldSimulation` 已开始输出独立 `competition` 统计

### Step 2
新建 `src/ecology/symbiosis.py`

目标：
- 建立独立的共生/偏利共生层

第一批关系：
- `kingfisher_v4 -> shore_hatch/minnow`
- `bat_v4 -> night_moth/night_swarm`
- `beaver -> wetland_patch/reed_belt`

后续扩展：
- 清洁鱼与大型鱼
- 珊瑚虫与虫黄藻
- 蜜蜂与花植物
- 松鼠与种子传播

验收标准：
- 共生关系具备摘要与反馈接口

当前状态：
- 已完成第一版落地
- 已新增 [symbiosis.py](/Users/yumini/Projects/eco-world/src/ecology/symbiosis.py)
- `WorldSimulation` 已开始输出独立 `symbiosis` 统计

### Step 3
更新 `src/ecology/__init__.py`

目标：
- 导出：
  - `food_web`
  - `cascade`
  - `competition`
  - `symbiosis`

---

## Phase 2：区域关系反馈成型

### Step 4
升级 `src/sim/world_simulation.py`

目标：
- 在当前 `food_web`、`cascade` 之外，正式接入：
  - `competition`
  - `symbiosis`

新增统计字段：
- `competition_summary`
- `symbiosis_summary`
- `region_feedback`
- `species_pool_adjustments`

### Step 5
升级 `src/world/region.py`

新增建议字段：
- `relationship_state`
- `recent_adjustments`
- `ecological_pressures`

目标：
- 保存最近几轮竞争、共生、工程师反馈结果
- 供 GUI、事件系统和后续任务系统直接读取

当前状态：
- 已完成第一版落地
- `Region` 已新增：
  - `relationship_state`
  - `recent_adjustments`
  - `ecological_pressures`
- `WorldSimulation` 更新后已开始将 `cascade / competition / symbiosis / territory` 结果持久写回区域对象

### Step 6
收缩 `src/ecology/cascade.py`

目标：
- 让 `cascade` 成为真正的汇总层
- 不再承载大量具体关系实现

职责保留：
- 把竞争、共生、工程师效应、资源脉冲压缩成区域级方向性指标

当前状态：
- 已完成第一版落地
- `cascade.py` 已开始汇总 `competition / symbiosis` 的结果
- `cascade.py` 已开始汇总 `competition / symbiosis / territory` 的结果
- `cascade` 现在承担上层方向性整合作用，而不再独自承载所有关系实现

### Step 6.5
新建 `src/ecology/territory.py`

目标：
- 把草原与湿地的领地、核心活动区和边界冲突拆成独立摘要模块
- 为后续狮群、鬣狗 clan、河马和鳄鱼的真实领地逻辑预留接口

当前状态：
- 已完成第一版落地
- 已新增 [territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)
- `WorldSimulation` 统计已新增独立 `territory` 区块
- 当前已覆盖：
  - `lion / hyena` 的草原领地压力
  - `hippopotamus / nile_crocodile / beaver` 的湿地岸带领地压力

---

## Phase 3：关键生态区闭环

### Step 7
完成湿地核心生态链

区域：
- `wetland_lake`

关键物种：
- `beaver`
- `hippopotamus`
- `nile_crocodile`
- `kingfisher_v4`
- `frog`
- `minnow`
- `catfish`
- `blackfish`

关键机制：
- 河狸扩湿地
- 河马做陆水营养回流
- 鳄鱼制造岸线风险
- 翠鸟依赖浅滩和鱼群
- 青蛙依赖 `shore_hatch`
- 鲶鱼/黑鱼/鳄鱼形成分层竞争

验收标准：
- `wetland_lake` 区域统计能体现完整湿地链

当前状态：
- 已完成第一版湿地链摘要
- 已新增 [src/ecology/wetland.py](/Users/yumini/Projects/eco-world/src/ecology/wetland.py)
- `WorldSimulation` 统计已新增 `wetland_chain`
- 湿地链反馈现已轻量回灌区域 `resource_state / hazard_state / health_state`
- 区域对象已开始持久保存 `wetland_chain` 关系状态
- 已新增 [src/ecology/predation.py](/Users/yumini/Projects/eco-world/src/ecology/predation.py)
- 湿地链与夜行链的分层捕食压力现已独立进入 `predation` 模块，并纳入 `cascade`
- 湿地链现已支持低频 `species_pool` 轻量重平衡，开始把岸带耦合和顶层压制写回区域物种池
- `wetland_rebalancing` 现已按 `shoreline_layer / fish_layer / apex_layer` 分组持久写入区域关系状态
- `wetland_chain` 本身现已显式输出 `layer_scores / layer_species`，可直接供 GUI 和事件系统消费

### Step 8
完成草原大型植食者链

区域：
- `temperate_grassland`

关键物种：
- `african_elephant`
- `white_rhino`
- `giraffe`

关键机制：
- 大象开林
- 白犀维持草场
- 长颈鹿浏览高树冠
- 三者通过资源层形成垂直和水平分工
- 保留低频、轻量竞争反馈

验收标准：
- `temperate_grassland` 的资源状态与物种池随三者组合而变化

当前状态：
- 已新增 `grassland_chain` 第一版摘要与反馈
- `WorldSimulation` 已开始输出 `grassland_chain`
- 草原链已显式输出：
  - `engineering_layer`
  - `grazing_layer`
  - `browse_layer`
  - `predator_layer`
  - `scavenger_layer`
- 草原区现已新增独立 `territory` 关系层，用于表达：
  - `pride_core_range`
  - `male_takeover_front`
  - `clan_den_range`
  - `apex_boundary_conflict`
- 当前原生运行体也已补上最小个体级接口：
  - `Lion._establish_pride_core()`
  - `Hyena._mark_den_cluster()`
- 草原捕食者社群运行体现已进一步补上：
  - `Lion._contest_male_front()`
  - `Hyena._expand_clan_front()`
- 当前已原生接入：
  - `lion`
  - `hyena`
  - `antelope`
  - `zebra`
- 草原链已开始表达顶层闭环：
  - `apex_predation`
  - `carrion_scavenging`
  - `carcass_competition`
  - `grassland_predator_closure`
- 草原区现已新增 `carcass_availability` 资源维度
- `competition.py` 已开始独立表达：
  - `carcass_site_competition`
  - `kill_site_competition`
  - `scavenger_pushback`
  - `herd_route_interference`
- 草原链已扩展 `herd_layer`
- 草原链现已开始表达：
  - `herd_grazing`
  - `migration_pressure`
  - `prey_corridor_density`
  - `herd_predator_loop`
- `grassland_chain` 现已扩展 `social_layer`
- 草原捕食者社群结构现已开始表达：
  - `pride_patrol`
  - `male_competition_pressure`
  - `clan_pressure`
  - `den_cluster_pressure`
  - `apex_rivalry`
  - `group_hunt_instability`
- 草原链现已支持低频 `species_pool` 重平衡
- `grassland_rebalancing` 已开始按层级持久写入区域关系状态：
  - `herd_layer`
  - `grazing_layer`
  - `browse_layer`
  - `predator_layer`
  - `scavenger_layer`
  - `social_layer`
- 草原竞争反馈现已开始轻量回灌：
  - `species_pool`
  - `carcass_availability`
  - `predation_pressure`
- 草原区现已新增独立 `carrion_chain`
- `carrion_chain` 现已显式输出：
  - `kill_layer`
  - `scavenge_layer`
  - `herd_source_layer`
- 草原区现已原生接入 `vulture`
- `carrion_chain` 已扩展：
  - `aerial_scavenge_layer`
- 草原尸体资源链现已开始表达：
  - `aerial_scavenging`
  - `thermal_tracking`
  - `scavenger_stack`
  - `full_carrion_closure`
- 尸体资源链现已支持：
  - 状态反馈
  - 低频 `species_pool` 重平衡
  - 区域关系状态持久化

### Step 9
补草原顶级捕食与清道夫组

优先新增：
- `lion`
- `hyena`
- `hyena`

第一阶段先做：
- 群体捕食
- 尸体资源竞争
- 基础雄性竞争接口
- 狮群和鬣狗群的领地接口预留

当前状态：
- 已完成第一版落地
- `lion / hyena` 已进入 `v4` 模板、关系表与原生运行体
- 草原区已具备尸体资源与顶层竞争的低频反馈骨架

---

## Phase 4：关键种模板补全

### Step 10
新增 `lion` 原生运行体

目标：
- 顶级捕食模板种首次完整落地

第一阶段功能：
- 基础顶级捕食食谱
- 群体偏好
- 雄性竞争接口
- 狮群领地接口
- 风险热区影响

### Step 11
新增 `hyena` 原生运行体

目标：
- 腐食与机会型捕食链完整化

第一阶段功能：
- 腐食
- 机会型捕食
- 与 `lion` 的竞争
- 尸体资源依赖

### Step 12
新增 `otter`

目标：
- 连接淡水鱼链、湿地链和半水生哺乳类

### Step 13
新增 `coral` 与 `cleaner_fish`

目标：
- 打通海洋关系系统第一块完整共生链

---

## Phase 5：数据驱动化

### Step 14
拆分 `src/data/defaults.py`

新增目录：
- `src/data/species/`
- `src/data/relations/`
- `src/data/biomes/`

目标：
- 物种和关系不再主要依赖 Python 常量

### Step 15
升级 `src/data/registry.py`

目标：
- 支持从 JSON 或 YAML 数据文件加载模板、物种、关系

验收标准：
- 新增物种时优先修改数据，不优先改核心代码

### Step 16
建立模板到物种的批量映射机制

示例：
- `MegaherbivoreEngineer`
  - `african_elephant`
  - 未来可挂更多大象变体
- `AquaticAmbushApexPredator`
  - `nile_crocodile`
  - 未来可挂 `alligator`、`caiman`

---

## Phase 6：新旧模拟层分层

### Step 17
让 `src/core/ecosystem.py` 退位为旧单区域内核

目标：
- 旧 `Ecosystem` 主要作为 `RegionSimulation` 的兼容底层
- 不再继续把 `v4` 世界逻辑直接堆进旧控制器

### Step 18
升级 `src/sim/region_simulation.py`

目标：
- 区域特定环境脉冲
- 区域物种池约束
- 区域模板加载

### Step 19
升级 `src/sim/world_simulation.py`

目标：
- 多区域低频更新
- 非焦点区低成本演化
- 焦点区高频演化

---

## Phase 7：GUI 升级

### Step 20
先做世界入口页

可以先在现有 GUI 基础上扩：
- 区域列表
- 当前焦点区域卡片
- `food_web` 面板
- `cascade` 面板
- `competition_adjustments` 面板

### Step 21
增加区域生态可视化

新增图层：
- 区域资源趋势
- 关键种驱动条
- 竞争关系摘要
- 微栖位占用概览

### Step 22
再做全球/区域/局部三层切换

最终目标：
- `world_view`
- `region_view`
- `focus_view`

---

## Phase 8：完整生态区闭环

### Step 23
完成温带森林区闭环

关键物种：
- `wolf`
- `deer`
- `fox`
- `squirrel`
- `woodpecker`
- `owl`
- `bat_v4`
- `beaver`
- `kingfisher_v4`
- `bee`
- 花、果、树、真菌

验收标准：
- 食物网、授粉、种子传播、夜行链、湿地工程链齐备

### Step 24
完成湿地区闭环

关键物种：
- `beaver`
- `hippopotamus`
- `nile_crocodile`
- `kingfisher_v4`
- `frog`
- `minnow`
- `catfish`
- `blackfish`
- 湿地植物
- 羽化昆虫带

验收标准：
- 水陆营养交换、岸线风险、鱼链、两栖链、鸟链齐备

### Step 25
完成草原区闭环

关键物种：
- `african_elephant`
- `white_rhino`
- `giraffe`
- `lion`
- `hyena`
- 食草群
- 清道夫
- 蜱虫/清洁关系

验收标准：
- 大型植食者分层、捕食者竞争、尸体资源链齐备

---

## Phase 9：玩法与事件

### Step 26
增加世界事件

事件类型：
- 水位异常
- 干旱
- 洪泛
- 花季
- 羽化期
- 鱼潮
- 火灾

### Step 27
加入玩家干预第一版

操作包括：
- 放归关键种
- 调整保护区
- 恢复湿地
- 控制污染
- 控制人类干扰

### Step 28
加入图鉴与关系百科

要求：
- 每个物种有中文说明
- 每条关键关系有中文解释
- 每个区域有生态区介绍

---

## Phase 10：大规模扩种

### Step 29
扩到 `120-160` 物种

优先补齐：
- 温带森林
- 草原
- 湿地
- 热带雨林
- 海岸
- 珊瑚礁

### Step 30
再扩展：
- 沙漠
- 山地
- 极地
- 外洋
- 深海

---

## 最终执行顺序

最稳的推进顺序是：

1. 拆关系模块
2. 做区域反馈闭环
3. 做关键种竞争与共生
4. 做几个核心生态区完整闭环
5. 再大规模扩种
6. 最后上全球玩法、事件和任务系统

## 文档定位

本文件不是总设计，而是**实施顺序文档**。

配套阅读顺序建议：

1. [V4-WORLD.md](/Users/yumini/Projects/eco-world/docs/V4-WORLD.md)
2. [V4-SPECIES.md](/Users/yumini/Projects/eco-world/docs/V4-SPECIES.md)
3. [V4-RELATIONS.md](/Users/yumini/Projects/eco-world/docs/V4-RELATIONS.md)
4. [V4-ROADMAP.md](/Users/yumini/Projects/eco-world/docs/V4-ROADMAP.md)
5. 本文档

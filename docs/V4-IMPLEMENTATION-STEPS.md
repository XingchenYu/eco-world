# V4 实施步骤

本文档把 `v4.0` 的设计目标拆成可按顺序执行的实施步骤。

目标不是继续堆功能，而是在不再做大重构的前提下，稳定把项目推进到多尺度虚拟生态世界。

## 最新推进

- `Lion / Hyena` 现已新增轻量核心区中心：
  - `pride_center`
  - `clan_center`
- `territory` 现已开始吸收空间热点统计：
  - `lion_hotspot_count`
  - `hyena_hotspot_count`
  - `shared_hotspot_overlap`
- `social_trends.hotspot_scores` 现已开始继续反向影响：
  - `Lion / Hyena` 的 `pride_center / clan_center` 漂移节律
  - `grassland_rebalancing`
  - `carrion_rebalancing`
- 这层热点记忆现在也开始进入：
  - `grassland_chain`
  - `carrion_chain`
  的摘要和状态反馈，形成更明确的多周期热点生命周期波动
- 这层长期波动现在也会直接改变：
  - 草食群振幅
  - 清道夫振幅
  - 顶层热点冲突导致的周期性收缩
- 这层长期波动现在进一步区分：
  - `grassland_boom_phase`
  - `grassland_bust_phase`
  并开始分别驱动 herd、apex、scavenger 的长期繁荣/衰退振幅
- 在这之上，区域级长期相位现在进一步汇总成：
  - `grassland_prosperity_phase`
  - `grassland_collapse_phase`
  并开始作用到草原链和尸体资源链的长期 gain/loss 节律
- 这层区域长期相位现在也开始直接改变：
  - `grassland_chain` 的摘要权重与反馈强度
  - `carrion_chain` 的摘要权重与反馈强度
- 这使得草原领地层开始区分：
  - 群体数量
  - 社群强度
  - 热点数量
  - 热点重叠
  - 热点持续与迁移记忆

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
- 草原领地热点现已开始反向影响：
  - `grassland_chain`
  - `carrion_chain`
  - 草原资源通道与尸体资源通道
- `grassland_rebalancing / carrion_rebalancing` 现已开始读取：
  - `lion_hotspot_count`
  - `hyena_hotspot_count`
  - `shared_hotspot_overlap`
- 这使得 `lion / hyena / vulture` 的低频重平衡也开始受空间群体格局影响
- `Lion / Hyena` 运行体现在也开始记录：
  - `pride_stability`
  - `clan_stability`
- 这层稳定度已经开始轻量影响：
  - `health`
  - `hunger`
  - `mate_cooldown`
  - `reproduction_rate`
- 这层稳定度现在也开始影响：
  - `litter outcomes`
  - `postpartum cooldown`
- 这层稳定度现在也开始进入：
  - `grassland_rebalancing`
  - `carrion_rebalancing`
  用于 `stable pride / clan` 的低频恢复
- 当：
  - 社群稳定度高
  - 群体数量足够
  - 热点分布可扩张
  - 草食群与尸体资源充足
  时，这层稳定度现在也会打开：
  - `pride expansion window`
  - `clan expansion window`
- 当：
  - `lion / hyena` 跌入低谷
  - 但社群信号、热点和资源通道仍保留
  时，这层现在也会打开：
  - `pride recolonization window`
  - `clan recolonization window`
- 现在已新增独立的 `social_trends` 层：
  - 读取 `territory.runtime_signals`
  - 读取上一轮 `region.relationship_state["social_trends"]`
  - 形成 `recovery / decline` 长期偏置
  - 并反向进入：
    - `grassland_rebalancing`
    - `carrion_rebalancing`
- `social_trends` 现在还会形成：
  - `phase_scores`
  - `cycle_signals`
- 也就是说，系统已开始区分：
  - 扩张期
  - 收缩期
  - 重占记忆期

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
- `territory` 摘要现在开始吸收运行期事件信号，不再只看区域物种池存在：
  - `pride_core_events`
  - `male_takeover_events`
  - `clan_den_events`
  - `clan_front_events`
- `territory` 现已进一步吸收运行期社群状态：
  - `lion_pride_strength`
  - `lion_takeover_pressure`
  - `hyena_clan_cohesion`
  - `hyena_clan_front_pressure`
- 草原捕食者现在还有轻量群体标识：
  - `pride_id`
  - `clan_id`
- `territory` 现已开始吸收：
  - `lion_pride_count`
  - `hyena_clan_count`
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

## 最新推进

- `social_trends.phase_scores` 已回灌到 `RegionSimulation`
- `lion / hyena` 运行体会直接读取扩张期与收缩期信号
- 周期层开始影响个体的健康、饥饿、繁殖节奏与交配冷却
- 周期层现已继续影响 `pride/clan` 的核心区建立强度与前线推进压力
- 草原热点现已开始具有持续、衰减与迁移记忆，并会继续回灌 `social_trends` 和 `territory`
- `social_trends.hotspot_scores` 现已开始持久记录 `herd / vulture` 通道热点记忆，并回灌 `grassland_chain / carrion_chain`
- `social_trends.phase_scores` 现已开始形成 `herd_route_cycle / aerial_carrion_cycle`，并进入草原链与尸体资源链
- `herd_route_cycle / aerial_carrion_cycle` 现已开始进一步抬升或压低草原区的长期 `boom-bust / prosperity-collapse`
- `prosperity / collapse` 现已开始直接改变 `grassland_chain / carrion_chain` 的：
  - 摘要权重
  - 反馈系数
  - 主导层偏置
- `prosperity / collapse` 现已开始显式切换：
  - `grassland_chain` 的 `dominant_layer`
  - `carrion_chain` 的 `dominant_layer`
- `dominant_layer` 现已开始反向改变：
  - `territory` 的热点/通道偏置信号
  - `grassland_chain / carrion_chain` 下一轮的资源布局输入
- `territory` 生成的 `*_bias` 信号现已开始回灌到运行体：
  - `lion / hyena` 的中心漂移强度
  - `antelope / zebra` 的 herd 通道选择
  - `vulture` 的空中追踪通道选择
- `social_trends.prosperity_scores` 现已开始直接回灌到运行体：
  - `antelope / zebra` 会显式接收 `grassland_prosperity_phase / grassland_collapse_phase`
  - `vulture` 也会显式接收 `grassland_prosperity_phase / grassland_collapse_phase`
  - 长期繁荣/衰退相位已进入 herd 与 carrion 的运行期通道行为
- `grassland_prosperity_phase / grassland_collapse_phase` 现已开始反向影响：
  - `herd_hotspot_memory`
  - `herd_apex_memory`
  - `vulture_hotspot_memory`
  - `vulture_carrion_memory`
  也就是说，长期区域相位已开始改变 herd 与空中尸体通道记忆的累积方向
- `grassland_prosperity_phase / grassland_collapse_phase` 现已继续反向影响：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
  长期区域相位和 herd/carrion 通道周期已经开始形成双向耦合
- `RegionSimulation.apply_relationship_runtime_state()` 现已继续把：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
  直接回灌到 `antelope / zebra / vulture` 的运行期偏置
- herd/carrion 的长期周期现在已直接进入运行体空间行为，而不只停留在摘要和重平衡层
- `runtime_territory_state` 现已开始把：
  - 运行中的 `herd_route_cycle_runtime`
  - 运行中的 `aerial_carrion_cycle_runtime`
  反向写回 `territory.runtime_signals`
- 这意味着 herd/carrion 的运行期周期行为已经开始回流到区域领地层
- `apply_region_social_trend_feedback()` 现已开始把：
  - `herd_route_cycle` 回灌到 `surface_water`
  - `aerial_carrion_cycle` 回灌到 `carcass_availability`
- 长期社群周期现在已经开始直接改区域资源层，而不只影响链路权重和重平衡
- `territory` 现已开始直接读取区域里的：
  - `surface_water`
  - `carcass_availability`
  并生成 `surface_water_anchor / carcass_anchor`
- `grassland_chain / carrion_chain` 也已开始吸收这些资源锚点，资源层正式进入草原长期闭环
- `social_trends` 现也开始直接吸收：
  - `surface_water_anchor`
  - `carcass_anchor`
  这些资源锚点现在已经开始反向塑造：
  - `herd_hotspot_memory / herd_apex_memory`
  - `vulture_hotspot_memory / vulture_carrion_memory`
  - `herd_route_cycle / aerial_carrion_cycle`
- 同时这些资源锚点现在也开始直接抬高或压低：
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
  资源层已经从链路输入进一步进入草原长期相位本身
- 资源锚点也开始继续影响：
  - `grassland_chain.dominant_layer`
  - `carrion_chain.dominant_layer`
  也就是说，长期水源与尸体资源现在已经开始改变当前周期里哪一层主导草原链和尸体资源链
- `RegionSimulation.apply_relationship_runtime_state()` 现已把：
  - `runtime_anchor_prosperity`
  直接注入 `lion / hyena / antelope / zebra / vulture`
  它已经开始参与运行体的中心漂移、通道选择和空间粘滞
- `runtime_territory_state` 现已继续汇总：
  - `apex_anchor_prosperity_runtime`
  - `herd_anchor_prosperity_runtime`
  - `aerial_anchor_prosperity_runtime`
  这意味着运行体繁荣锚点已经开始被重新收集成区域级空间信号
- `territory.runtime_signals` 现已继续吸收这些繁荣锚点，并把它们回灌到：
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
  运行体长期繁荣度现在已开始直接抬高领地与通道压力
- `social_trends` 现已继续读取：
  - `herd_anchor_prosperity_runtime`
  - `aerial_anchor_prosperity_runtime`
  - `apex_anchor_prosperity_runtime`
  并让它们进入：
  - `herd_route_cycle / aerial_carrion_cycle`
  - `grassland_boom_phase / grassland_prosperity_phase`
  - `cycle_signals`
  也就是说，运行体繁荣锚点已经开始反向塑造长期记忆、周期和区域相位
- `grassland_chain` 现已继续吸收：
  - `herd_anchor_prosperity_runtime`
  - `apex_anchor_prosperity_runtime`
  并把它们写成：
  - `runtime_herd_anchor_prosperity_pull`
  - `runtime_apex_anchor_prosperity_pull`
  这意味着运行体繁荣锚点已经开始直接进入草原链摘要、反馈和低频 herd/apex 重平衡
- `carrion_chain` 现已继续吸收：
  - `aerial_anchor_prosperity_runtime`
  并把它写成：
  - `runtime_aerial_anchor_prosperity_pull`
  这意味着运行体繁荣锚点已经开始直接进入尸体资源链摘要、反馈和空中清道夫重平衡
- `WorldSimulation._build_combined_pressures()` 现已继续吸收：
  - `runtime_herd_anchor_prosperity_pull`
  - `runtime_aerial_anchor_prosperity_pull`
  - `runtime_apex_anchor_prosperity_pull`
  以及 `territory.runtime_signals` 里的：
  - `herd_anchor_prosperity_runtime`
  - `aerial_anchor_prosperity_runtime`
  - `apex_anchor_prosperity_runtime`
  也就是说，运行体繁荣锚点现在已经直接进入区域级 `prosperity_pressure / runtime_resource_pressure`，开始影响长期健康判定
- `grassland_chain / carrion_chain` 现已继续直接读取区域：
  - `health_state["prosperity"]`
  - `health_state["stability"]`
  - `health_state["collapse_risk"]`
  并把它们写成：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
  也就是说，区域长期健康度现在已经能不经过运行体中转，直接参与两条链的摘要层和主导层偏置
- `grassland_rebalancing / carrion_rebalancing` 现已继续直接读取：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
  并把它们写成新的低频调整：
  - `regional_prosperity_support`
  - `regional_stability_support`
  - `regional_collapse_drag`
  也就是说，区域长期健康度现在已经开始不经过运行体中转，直接改变 herd/apex/scavenger 的物种池节律
- `social_trends` 现也开始继续直接读取区域：
  - `health_state["prosperity"]`
  - `health_state["stability"]`
  - `health_state["collapse_risk"]`
  并让它们继续进入：
  - `herd_hotspot_memory / herd_apex_memory`
  - `vulture_hotspot_memory / vulture_carrion_memory`
  - `herd_route_cycle / aerial_carrion_cycle`
  - `cycle_signals`
  也就是说，区域长期健康度现在已经开始不经过运行体中转，直接塑造社群长期记忆和周期层
- `territory` 现已开始继续读取上一周期 `social_trends` 里的：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
  以及 `grassland_collapse_phase`
  并把它们回灌到：
  - `waterhole_spacing`
  - `pride_core_range`
  - `clan_den_range`
  - `apex_boundary_conflict`
  - `carcass_route_overlap`
  也就是说，区域长期社会锚点现在已经开始直接改变领地布局压力，而不只停留在 `social_trends`
- `RegionSimulation.apply_relationship_runtime_state()` 现已继续把：
  - `regional_prosperity_bias`
  - `regional_stability_bias`
  - `regional_collapse_bias`
  直接注入 `lion / hyena / antelope / zebra / vulture`
  这意味着区域长期社会锚点现在已经开始直接改变运行体的中心漂移粘滞与通道偏置，而不只停留在领地摘要层
- `WorldSimulation._build_runtime_territory_state()` 现已继续把运行中的：
  - `regional_prosperity_bias`
  - `regional_stability_bias`
  - `regional_collapse_bias`
  汇总成：
  - `apex_regional_bias_runtime`
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  并重新写回 `territory.runtime_signals`
  这意味着区域长期社会锚点现在已经形成“领地摘要 -> 运行体 -> runtime territory -> 领地摘要”的完整回流
- `social_trends` 现也开始继续读取：
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  并让它们继续进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `boom-bust`
  - `prosperity / collapse`
  也就是说，运行中的区域长期社会锚点现在已经开始直接塑造下一轮社群长期相位
- `grassland_chain` 现已开始继续读取：
  - `herd_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  并把它们写成：
  - `runtime_herd_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
  这意味着运行中的区域长期社会锚点现在已经开始直接进入草原链摘要、区域反馈和低频 herd/apex 重平衡
- `carrion_chain` 现已开始继续读取：
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  并把它们写成：
  - `runtime_aerial_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
  这意味着运行中的区域长期社会锚点现在已经开始直接进入尸体资源链摘要、区域反馈和空中清道夫/apex 重平衡
- `WorldSimulation._build_combined_pressures()` 现也开始继续直接吸收：
  - `runtime_herd_regional_bias_pull`
  - `runtime_aerial_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
  以及 `territory.runtime_signals` 里的：
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  这意味着运行中的区域长期社会锚点现在已经开始直接进入世界级：
  - `prosperity_pressure`
  - `collapse_pressure`
  - `runtime_resource_pressure`
  并进一步影响区域长期 `prosperity / collapse_risk / stability`
- `runtime_territory_state` 现已开始继续把区域：
  - `prosperity`
  - `stability`
  - `collapse_risk`
  组合成：
  - `apex_regional_health_anchor_runtime`
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
- `territory.runtime_signals` 现也开始继续吸收这 3 个运行期长期健康锚点，并把它们回灌到：
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
  也就是说，区域长期健康度现在已经不只通过运行体个体表现间接传导，而是开始直接形成 runtime 级领地健康锚点
- `social_trends` 现也开始继续读取：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  并让它们继续进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `boom-bust`
  - `prosperity / collapse`
  也就是说，运行期区域长期健康锚点现在已经开始直接塑造下一轮社群长期相位
- `grassland_chain` 现也开始继续读取：
  - `herd_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  并把它们写成：
  - `runtime_herd_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
- `carrion_chain` 现也开始继续读取：
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  并把它们写成：
  - `runtime_aerial_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
- 这意味着运行期区域长期健康锚点现在已经开始直接进入：
  - 两条链的摘要
  - 两条链的区域反馈
  - herd/aerial/apex 的低频重平衡
- `WorldSimulation._build_combined_pressures()` 现也开始继续吸收：
  - `runtime_herd_health_anchor_pull`
  - `runtime_aerial_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
  以及 `territory.runtime_signals` 里的：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  这意味着运行期区域长期健康锚点现在已经开始直接进入世界级：
  - `prosperity_pressure`
  - `collapse_pressure`
  - `runtime_resource_pressure`
  并进一步影响区域长期 `prosperity / collapse_risk / stability`
- `apply_region_social_trend_feedback()` 现也开始继续读取这些 runtime 健康锚点对应的 `cycle_signals`，并把它们继续回灌到：
  - `surface_water`
  - `carcass_availability`
  - `predation_pressure`
  - `resilience`
  也就是说，运行期区域长期健康锚点现在已经不仅参与记忆和周期，还开始反向抬升区域资源锚点与韧性本身

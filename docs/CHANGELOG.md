# EcoWorld 更新日志

本文档记录所有代码和文档的更新历史。

### v4.0-alpha35 (2026-04-09 08:40)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已把区域级 `prosperity / collapse` 相位推进到“稳定态切换”：
  - 新增：
    - `prosperity_feedback_bias`
    - `collapse_feedback_bias`
  - `prosperity / collapse` 现在会直接改变草原链的：
    - 摘要权重
    - 反馈系数
    - `herd / predator / scavenger / social` 层偏置
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已把区域级 `prosperity / collapse` 相位推进到尸体资源链的稳定态切换：
  - 新增：
    - `prosperity_feedback_bias`
    - `collapse_feedback_bias`
  - `prosperity / collapse` 现在会直接改变尸体资源链的：
    - 摘要权重
    - 反馈系数
    - `herd_source / kill / scavenge / aerial_scavenge` 层偏置
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐对应反馈测试并通过

### v4.0-alpha36 (2026-04-09 08:55)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已根据 `prosperity / collapse` 显式切换 `grassland_chain.dominant_layer`
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已根据 `prosperity / collapse` 显式切换 `carrion_chain.dominant_layer`
- ✅ 草原链和尸体资源链的反馈系数现在会继续读取 `dominant_layer`，使 `herd / kill / scavenge / aerial` 等层在不同长期相位下真正成为主导层
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `dominant_layer` 断言并通过

### v4.0-alpha37 (2026-04-09 09:10)

- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现已开始读取上一周期的 `grassland_chain / carrion_chain dominant_layer`
- ✅ 主导层现在会反向生成新的领地与通道偏置信号：
  - `herd_channel_bias`
  - `apex_hotspot_bias`
  - `scavenger_hotspot_bias`
  - `herd_source_bias`
  - `kill_corridor_bias`
  - `aerial_lane_bias`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已开始吸收这些偏置信号，形成下一轮资源布局输入
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增领地主导层测试并通过

### v4.0-alpha38 (2026-04-09 09:25)

- ✅ [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 现已把 `territory` 生成的布局偏置信号回灌到运行体
- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 中：
  - `Lion` 现已读取：
    - `apex_hotspot_bias`
    - `kill_corridor_bias`
  - `Hyena` 现已读取：
    - `scavenger_hotspot_bias`
    - `kill_corridor_bias`
- ✅ [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py) 中：
  - `Antelope / Zebra` 现已读取 herd 通道偏置
  - `Vulture` 现已读取空中通道与 kill corridor 偏置
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐运行体偏置信号注入测试并通过

### v4.0-alpha27 (2026-04-09 05:00)

- ✅ `social_trends.hotspot_scores` 现已开始回灌到 [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 的运行体
- ✅ `Lion / Hyena` 现已新增：
  - `hotspot_memory`
  - `shared_hotspot_memory`
- ✅ `Lion / Hyena` 的 `pride_center / clan_center` 现已由热点记忆驱动，开始表现为带粘滞的中心漂移，而不是每次动作都瞬间跳点
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已开始吸收 `social_hotspot` 信号
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点记忆注入与中心漂移测试并通过

### v4.0-alpha28 (2026-04-09 05:20)

- ✅ `social_trends.hotspot_scores` 现已开始进入 [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 的草原链摘要与反馈
- ✅ `social_trends.hotspot_scores` 现已开始进入 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 的尸体资源链摘要与反馈
- ✅ 草原链新增：
  - `hotspot_cycle_pressure`
  - `hotspot_cycle_overlap`
- ✅ 尸体资源链新增：
  - `hotspot_cycle_carrion`
  - `hotspot_cycle_tracking`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点生命周期摘要/反馈断言并通过

### v4.0-alpha31 (2026-04-09 06:05)

- ✅ `social_trends.cycle_signals` 现已新增：
  - `apex_hotspot_wave`
  - `shared_hotspot_churn`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已让热点周期波动直接拉动草食群振幅：
  - `hotspot_cycle_predator_wave`
  - `hotspot_cycle_overlap_drag`
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已让热点周期波动直接拉动清道夫振幅：
  - `hotspot_cycle_scavenger_wave`
  - `hotspot_cycle_churn`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点周期振幅断言并通过

### v4.0-alpha24 (2026-04-09 03:55)

- ✅ `social_trends.phase_scores` 现已开始回灌到 [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 的运行体
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 在区域更新前会先注入当前社群周期状态
- ✅ `Lion / Hyena` 新增周期相位行为影响：
  - 扩张期会轻量改善健康、缓解饥饿、缩短交配冷却、提升繁殖节奏
  - 收缩期会轻量增加饥饿、拖慢繁殖节奏并施加体况压力
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增区域社群周期注入测试和个体级周期行为测试

### v4.0-alpha25 (2026-04-09 04:20)

- ✅ `social cycle` 现已继续影响 `lion / hyena` 的核心区建立与前线推进强度
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 的运行态汇总新增：
  - `lion_cycle_expansion`
  - `lion_cycle_contraction`
  - `hyena_cycle_expansion`
  - `hyena_cycle_contraction`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 已开始把周期相位纳入领地压力计算
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增周期驱动的核心区效果测试

### v4.0-alpha26 (2026-04-09 04:40)

- ✅ 草原热点现已具备基础持续、衰减与迁移记忆
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 已新增：
  - `lion_hotspot_persistence`
  - `hyena_hotspot_persistence`
  - `shared_hotspot_persistence`
  - `lion_hotspot_shift`
  - `hyena_hotspot_shift`
  - `shared_hotspot_shift`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 已新增 `hotspot_scores`
- ✅ 热点记忆现已开始回灌区域 `resilience / territorial_conflict`

### v4.0-alpha14 (2026-04-08 23:40)

- ✅ `Lion / Hyena` 现已新增轻量核心区中心：
  - `pride_center`
  - `clan_center`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已汇总：
  - `lion_hotspot_count`
  - `hyena_hotspot_count`
  - `shared_hotspot_overlap`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 开始把热点数量和热点重叠纳入领地压力计算
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点相关断言并通过

### v4.0-alpha15 (2026-04-08 23:55)

- ✅ `territory` 的热点信号现已反向接入：
  - [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py)
  - [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)
- ✅ 草原链新增：
  - `hotspot_overlap_pressure`
  - `territory_channel_pressure`
  - `carcass_channeling`
- ✅ 尸体资源链新增：
  - `kill_corridor_overlap`
  - `scavenger_lane_pressure`
- ✅ 草原热点重叠现在会继续影响：
  - 草原资源通道
  - 尸体资源通道
  - `carcass_availability`
  - `predation_pressure`

### v4.0-alpha16 (2026-04-09 00:10)

- ✅ `grassland_rebalancing` 现已开始吸收 `territory` 的空间群体格局输入
- ✅ `carrion_rebalancing` 现已开始吸收 `territory` 的空间群体格局输入
- ✅ 热点数量和热点重叠现在不只影响摘要和状态反馈，也会影响：
  - `lion`
  - `hyena`
  - `vulture`
  的低频物种池重平衡
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `territory -> rebalancing` 断言并通过

### v4.0-alpha17 (2026-04-09 00:25)

- ✅ `Lion` 现已新增轻量社群稳定度：
  - `pride_stability`
- ✅ `Hyena` 现已新增轻量社群稳定度：
  - `clan_stability`
- ✅ 这层稳定度现在会开始轻量影响：
  - `health`
  - `hunger`
  - `mate_cooldown`
  - `reproduction_rate`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `lion / hyena` 社群稳定度测试并通过

### v4.0-alpha18 (2026-04-09 00:40)

- ✅ `Lion / Hyena` 的社群稳定度现在开始影响：
  - `litter outcomes`
  - `postpartum cooldown`
- ✅ `Lion` 现已支持：
  - `stable pride support`
  - `pride instability`
  两类社群产仔结果记录
- ✅ `Hyena` 现已支持：
  - `stable clan support`
  - `clan instability`
  两类社群产仔结果记录
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `lion / hyena` 社群产仔缩放测试并通过

### v4.0-alpha19 (2026-04-09 00:55)

- ✅ `pride_stability / clan_stability` 现在开始进入：
  - `grassland_rebalancing`
  - `carrion_rebalancing`
- ✅ `territory.runtime_signals` 中的：
  - `lion_pride_strength`
  - `lion_pride_count`
  - `hyena_clan_cohesion`
  - `hyena_clan_count`
  现在会驱动：
  - `stable_pride_recovery`
  - `stable_clan_recovery`
  - `stable_pride_carcass_recovery`
  - `stable_clan_carrion_recovery`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `social_state` 低频重平衡断言并通过

### v4.0-alpha20 (2026-04-09 01:10)

- ✅ `social_state` 现在不仅会触发低频恢复，还会在条件满足时打开：
  - `pride_expansion_window`
  - `clan_expansion_window`
  - `pride_carrion_expansion_window`
  - `clan_carrion_expansion_window`
- ✅ 这些扩张窗口同时要求：
  - 高稳定度
  - 足够的 group 数量
  - 可扩张的热点布局
  - 充足的草食群或尸体资源
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增扩张窗口断言并通过

### v4.0-alpha21 (2026-04-09 01:25)

- ✅ `grassland_rebalancing / carrion_rebalancing` 现在在低谷条件下支持：
  - `pride_recolonization_window`
  - `clan_recolonization_window`
  - `pride_carrion_recolonization_window`
  - `clan_carrion_recolonization_window`
- ✅ 这些重占窗口要求：
  - 低数量状态
  - 高稳定度
  - 仍然存在的热点区
  - 足够的草食群或尸体资源
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增草原链和尸体资源链的重占窗口测试并通过

### v4.0-alpha22 (2026-04-09 01:40)

- ✅ 新增独立的 `social_trends` 层：
  - 读取 `territory.runtime_signals`
  - 读取上一轮 `social_trends`
  - 形成：
    - `lion_recovery_bias`
    - `lion_decline_bias`
    - `hyena_recovery_bias`
    - `hyena_decline_bias`
- ✅ `WorldSimulation` 现在会：
  - 构建 `social_trends`
  - 将其写回区域 `relationship_state`
  - 并将其接入：
    - `grassland_rebalancing`
    - `carrion_rebalancing`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `social_trends` 摘要与趋势驱动重平衡断言并通过

### v4.0-alpha23 (2026-04-09 01:55)

- ✅ `social_trends` 现在新增：
  - `phase_scores`
  - `cycle_signals`
- ✅ 系统现在开始显式区分：
  - `lion_expansion_phase / lion_contraction_phase`
  - `hyena_expansion_phase / hyena_contraction_phase`
- ✅ `grassland_rebalancing / carrion_rebalancing` 现在已开始读取：
  - `social_cycle`
  作为独立来源，而不只读取 `social_trend`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `phase_scores` 和 `social_cycle` 断言并通过

---

## 更新规范

### 代码更新流程
1. **修改代码前**：确认是否需要更新文档
2. **修改代码后**：立即更新相关文档
3. **提交代码时**：在CHANGELOG.md中记录变更

### 文档更新清单

| 文档 | 对应代码 | 更新触发条件 |
|-----|---------|-------------|
| SPECIES.md | entities/*.py | 新增/修改物种 |
| MECHANICS.md | core/*.py | 新增/修改机制 |
| competition-defense.md | entities/competition.py | 竞争/防御机制变更 |

## v4.0-alpha4 (2026-04-08 20:35)

- ✅ 草原区新增 `carcass_availability` 资源维度，用于表达狮鬣狗围绕尸体与击杀点的竞争压力
- ✅ [src/ecology/competition.py](/Users/yumini/Projects/eco-world/src/ecology/competition.py) 现已独立表达：
  - `carcass_site_competition`
  - `kill_site_competition`
  - `scavenger_pushback`
  - `herd_route_interference`
- ✅ 草原竞争反馈现已轻量回灌：
  - `hyena`
  - `lion`
  - `carcass_availability`
  - `predation_pressure`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增狮鬣狗尸体资源竞争断言并通过

### v4.0-alpha5 (2026-04-08 20:55)

- ✅ 新增 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)，把草原尸体资源链从竞争摘要中拆成独立模块
- ✅ `WorldSimulation` 统计新增：
  - `carrion_chain`
  - `carrion_rebalancing`
- ✅ `carrion_chain` 现已显式输出：
  - `kill_layer`
  - `scavenge_layer`
  - `herd_source_layer`
- ✅ 尸体资源链现已支持：
  - 状态反馈
  - 低频 `species_pool` 重平衡
  - 区域关系状态持久化
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `carrion_chain` 摘要、反馈、重平衡断言并通过

### v4.0-alpha6 (2026-04-08 21:10)

- ✅ 新增原生 `vulture` 运行体，作为草原空中清道夫接入 `v4`
- ✅ `v4` 模板、物种变体、运行桥接、草原默认物种池已同步补齐 `vulture`
- ✅ `carrion_chain` 已扩展：
  - `aerial_scavenge_layer`
  - `aerial_scavenging`
  - `thermal_tracking`
  - `scavenger_stack`
  - `full_carrion_closure`
- ✅ `carrion_rebalancing` 现已支持对 `vulture` 的低频物种池扶持
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `vulture` 注册与草原尸体资源链断言并通过

### v4.0-alpha7 (2026-04-08 21:25)

- ✅ `grassland_chain` 新增 `social_layer`
- ✅ 草原捕食者社群结构现已开始表达：
  - `pride_patrol`
  - `male_competition_pressure`
  - `clan_pressure`
  - `den_cluster_pressure`
  - `apex_rivalry`
  - `group_hunt_instability`
- ✅ `grassland_rebalancing` 现已支持 `social_layer`，开始对 `lion / hyena` 做轻量社群层重平衡
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增草原社群层断言并通过

### v4.0-alpha8 (2026-04-08 22:05)

- ✅ 新增 [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)，把草原和湿地的领地压力拆成独立关系模块
- ✅ `WorldSimulation` 统计新增独立 `territory` 区块，并将其持久写入区域 `relationship_state`
- ✅ 当前 `territory` 已覆盖：
  - 草原：`pride_core_range`、`male_takeover_front`、`clan_den_range`、`apex_boundary_conflict`
  - 湿地：`channel_claim`、`basking_bank_claim`、`shoreline_standoff`、`dam_complex_claim`
- ✅ `cascade.py` 现已开始汇总 `territory`，新增 `territorial_stress`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `territory` 摘要、反馈、世界统计和区域持久化断言并通过

### v4.0-alpha9 (2026-04-08 22:20)

- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 为 `Lion / Hyena` 新增个体级领地接口：
  - `Lion._establish_pride_core()`
  - `Hyena._mark_den_cluster()`
- ✅ 狮群和鬣狗现在不仅有区域级 `territory` 摘要，还能在当前运行层真实占用草原边缘微栖位并记录事件
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `lion` 核心领地和 `hyena` clan 通道测试并通过

### v4.0-alpha10 (2026-04-08 22:35)

- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 为草原捕食者社群再补两条个体级接口：
  - `Lion._contest_male_front()`
  - `Hyena._expand_clan_front()`
- ✅ 这两条接口已接入当前运行体的周期行为节奏，用于表达雄狮接管前线和鬣狗 clan 扩张前线
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增对应运行测试并通过

### v4.0-alpha11 (2026-04-08 22:50)

- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现在开始吸收运行期事件信号，领地摘要不再只依赖区域物种池
- ✅ `WorldSimulation` 现已把当前焦点区域最近事件传给 `territory`，并在世界统计与区域 `relationship_state` 中保留 `runtime_signals`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增运行期领地信号测试并通过

### v4.0-alpha12 (2026-04-08 23:05)

- ✅ `Lion / Hyena` 运行体现已新增轻量社群状态：
  - `pride_strength`
  - `takeover_pressure`
  - `clan_cohesion`
  - `clan_front_pressure`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已把运行层社群状态汇总给 `territory`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现在同时吸收：
  - 运行期事件信号
  - 运行期社群状态
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增运行期领地状态测试并通过

### v4.0-alpha13 (2026-04-08 23:20)

- ✅ `Lion / Hyena` 现已新增轻量群体标识：
  - `pride_id`
  - `clan_id`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已汇总：
  - `lion_pride_count`
  - `hyena_clan_count`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 开始把群体数量纳入领地压力计算
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增群体标识和群体数量相关断言并通过

## v4.0.9 - Add wetland chain summaries

- ✅ 新增 [src/ecology/wetland.py](/Users/yumini/Projects/eco-world/src/ecology/wetland.py)，为湿地与湖泊区域输出独立的湿地核心链摘要
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 统计新增 `wetland_chain`，可直接查看关键物种、营养级得分和叙事链
- ✅ 补充 `frog -> shore_hatch`、`catfish -> minnow`、`blackfish -> minnow/frog` 关系表，用于湿地链条表达
- ✅ 新增湿地链测试并修正世界统计测试中的区域语义断言
- ✅ 湿地链现在会轻量反馈到区域 `resource_state / hazard_state / health_state`，并持久写入 `relationship_state["wetland_chain"]`
- ✅ 新增 [src/ecology/predation.py](/Users/yumini/Projects/eco-world/src/ecology/predation.py)，把湿地链与夜行链的分层捕食压力从摘要中拆成独立模块
- ✅ 湿地链现已支持低频 `species_pool` 重平衡，开始把岸带耦合与顶层压制反馈到关键湿地物种池
- ✅ 湿地链重平衡现在会按 `shoreline_layer / fish_layer / apex_layer` 分组持久写入区域关系状态
- ✅ `wetland_chain` 现已显式输出 `layer_scores / layer_species`，让岸带层、鱼层、顶层成为可直接消费的结构化数据
- ✅ 新增草原大型植食者链 `grassland_chain`，开始显式表达 `engineering_layer / grazing_layer / browse_layer`
| fruits-omnivores.md | entities/omnivores.py | 杂食动物变更 |
| ECOSYSTEM.md | 所有 | 总览更新 |
| USAGE.md | main.py | 启动参数变更 |

---

## 版本历史

### v4.0-alpha3 (2026-04-08 19:45)

**草原链补强**：
- ✅ 新增 `lion / hyena` 的 `v4` 模板、变体、关系表与运行桥接
- ✅ 当前可运行系统已原生接入狮和鬣狗，并打通注册、初始化、生成与事件链
- ✅ `grassland_chain` 已扩展到：
  - `engineering_layer`
  - `grazing_layer`
  - `browse_layer`
  - `predator_layer`
  - `scavenger_layer`
- ✅ 草原链现在会显式表达：
  - `apex_predation`
  - `carrion_scavenging`
  - `carcass_competition`
  - `grassland_predator_closure`
- ✅ `predation.py` 已补上草原顶层捕食压力：
  - `lion -> rabbit`
  - `hyena -> rabbit`
- ✅ 新增 `grassland_rebalancing`，草原链现在也具备低频物种池重平衡
- ✅ `grassland_rebalancing` 已按层级持久写回区域关系状态，可区分：
  - `grazing_layer`
  - `browse_layer`
  - `predator_layer`
  - `scavenger_layer`
- ✅ 新增草原食草群原生运行体：
  - `antelope`
  - `zebra`
- ✅ `grassland_chain` 已扩展 `herd_layer`
- ✅ 草原链现在会显式表达：
  - `herd_grazing`
  - `migration_pressure`
  - `prey_corridor_density`
  - `herd_predator_loop`
- ✅ `predation.py` 已补上：
  - `lion -> antelope`
  - `hyena -> antelope`
  - `lion -> zebra`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `antelope / zebra / lion / hyena` 注册，以及草原链分层与重平衡断言
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/data/defaults.py src/entities/omnivores.py src/entities/animals.py src/core/ecosystem.py src/world/world_map.py src/ecology/grassland.py src/ecology/predation.py tests/test_ecosystem.py`

**v4 架构推进**：
- ✅ `cascade.py` 已收缩为更明确的汇总层
- ✅ `cascade` 开始显式整合 `competition / symbiosis` 的结果
- ✅ `cascade` 统计新增 `source_modules`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已验证 `cascade` 聚合竞争与共生结果
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/cascade.py src/ecology/competition.py src/ecology/symbiosis.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v4.0-alpha2 (2026-04-08 19:25)

**v4 架构推进**：
- ✅ `Region` 已新增关系状态持久化字段：
  - `relationship_state`
  - `recent_adjustments`
  - `ecological_pressures`
- ✅ `WorldSimulation.update()` 已开始把 `cascade / competition / symbiosis` 结果持久写回区域对象

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增区域关系状态持久化测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/world/region.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v4.0-alpha (2026-04-08 19:00)

**v4 架构推进**：
- ✅ 新增 [src/ecology/symbiosis.py](/Users/yumini/Projects/eco-world/src/ecology/symbiosis.py)
- ✅ `WorldSimulation` 统计新增独立 `symbiosis` 区块
- ✅ 第一版共生/偏利反馈已开始轻量回灌区域状态

**覆盖关系**：
- ✅ `kingfisher_v4 -> shore_hatch`
- ✅ `bat_v4 -> night_swarm`
- ✅ `beaver -> reed_belt`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 共生摘要与共生反馈测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/symbiosis.py src/ecology/competition.py src/ecology/cascade.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.9 (2026-04-08 18:40)

**v4 架构推进**：
- ✅ 新增 [src/ecology/symbiosis.py](/Users/yumini/Projects/eco-world/src/ecology/symbiosis.py)
- ✅ `WorldSimulation` 统计新增独立 `symbiosis` 区块
- ✅ 第一版共生/偏利反馈已开始轻量回灌区域状态

**覆盖关系**：
- ✅ `kingfisher_v4 -> shore_hatch`
- ✅ `bat_v4 -> night_swarm`
- ✅ `beaver -> reed_belt`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 共生摘要与共生反馈测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/symbiosis.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.8 (2026-04-08 18:10)

**v4 架构推进**：
- ✅ 新增 [src/ecology/competition.py](/Users/yumini/Projects/eco-world/src/ecology/competition.py)
- ✅ 将关键种竞争摘要与竞争反馈从 `cascade.py` 中拆分为独立模块
- ✅ `WorldSimulation` 统计新增独立的 `competition` 区块

**覆盖关系**：
- ✅ `hippopotamus <-> nile_crocodile`
- ✅ `african_elephant <-> white_rhino`
- ✅ `african_elephant -> giraffe`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 竞争摘要测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/competition.py src/ecology/cascade.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.7 (2026-04-08 17:30)

**文档**：
- ✅ 新增 [docs/V4-IMPLEMENTATION-STEPS.md](/Users/yumini/Projects/eco-world/docs/V4-IMPLEMENTATION-STEPS.md)
- ✅ README 的 `v4` 文档导航新增实施步骤入口

**目标**：
- ✅ 将后续开发从“继续逐步讨论”推进成“按步骤实施”
- ✅ 固定后续 `v4` 的执行顺序，减少范围漂移和重复设计

### v3.6 (2026-04-08 16:40)

**v4 架构推进**：
- ✅ 新增 [src/ecology/cascade.py](/Users/yumini/Projects/eco-world/src/ecology/cascade.py)，引入第一版区域级联影响摘要
- ✅ `WorldSimulation` 统计新增 `cascade` 区块，开始汇总关键种如何推动区域结构变化
- ✅ 级联摘要已开始轻量反馈到区域 `resource_state / hazard_state / health_state`
- ✅ 第一版关键种竞争反馈已接入区域 `species_pool` 轻量重平衡
- ✅ 当前已接入湿地链与草原大型植食者链：
  - `beaver / hippopotamus / nile_crocodile`
  - `african_elephant / white_rhino / giraffe`

**文档更新**：
- ✅ 更新 [docs/V4-RELATIONS.md](/Users/yumini/Projects/eco-world/docs/V4-RELATIONS.md)，补充已落地的级联摘要实现状态

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 级联摘要测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/cascade.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.5 (2026-04-07 16:20)

**设计文档**：
- ✅ 重写 README，明确区分当前 `v3.x` 原型与 `v4.0` 升级方向
- ✅ 新增 [V4-WORLD.md](/Users/yumini/Projects/eco-world/docs/V4-WORLD.md)
- ✅ 新增 [V4-SPECIES.md](/Users/yumini/Projects/eco-world/docs/V4-SPECIES.md)
- ✅ 新增 [V4-RELATIONS.md](/Users/yumini/Projects/eco-world/docs/V4-RELATIONS.md)
- ✅ 新增 [V4-ROADMAP.md](/Users/yumini/Projects/eco-world/docs/V4-ROADMAP.md)

**目标**：
- ✅ 将后续开发从“继续堆原型功能”转向“按 v4 总体架构实施”
- ✅ 提前锁定世界结构、物种模板、生态关系和路线图，减少后续大重构风险

### v3.4 (2026-04-07 15:10)

**性能与结构**：
- ✅ `Ecosystem` 新增 tick 级 actor 缓存
- ✅ 主循环中的 `_apply_population_pressure()` 与 `get_statistics()` / GUI 统计共用同一份 actor 结果
- ✅ 该优化不改变生态语义，只减少 `canopy_cover / bloom_abundance / wetland_support / nocturnal_insect_supply` 等 actor 的重复计算

**文档**：
- ✅ README、ARCHITECTURE、ECOSYSTEM、MECHANICS 已同步记录 actor 缓存层

**验证**：
- ✅ `tests/test_ecosystem.py`
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/core/ecosystem.py src/entities/animals.py src/entities/aquatic.py`

### v3.3 (2026-04-07 11:40)

**性能与结构**：
- ✅ 默认大地图性能继续优化到约 `1 tick ≈ 0.217s`、`5 tick ≈ 1.260s`
- ✅ 中低层水生移动分层，`small_fish / minnow / carp` 已切到更粗粒度区域趋向移动
- ✅ 低层水生漂移频率、植物邻域缓存、水生候选评分、动物局部缓存继续收口
- ✅ 动物繁殖率更新已接入物种数缓存与食性计数缓存，减少 herbivore / carnivore / omnivore 的全表扫描

**生态与机制**：
- ✅ 物种总数修正文档为 `67`：17 植物、35 陆地/鸟类/两栖、15 水生
- ✅ `frog` 湿地链已接入更强的成人湿地恢复和岸带羽化资源利用
- ✅ 夜间飞虫 `night_swarm`、树冠觅食 `canopy_forage`、岸带羽化 `shore_hatch` 已写入核心文档

**文档**：
- ✅ README 更新到 67 物种、最新微栖位列表和最新性能数据
- ✅ ARCHITECTURE、ECOSYSTEM、MECHANICS 更新到当前资源层与缓存结构
- ✅ CHANGELOG 补充 v3.3 记录

**验证**：
- ✅ `tests/test_ecosystem.py`
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/entities/animals.py src/core/ecosystem.py`
- ✅ 默认大地图性能基准

### v3.2 (2026-04-06 19:30)

**默认世界与性能**：
- ✅ 默认世界扩大到 `2560 x 1920`，运行格数 `128 x 96`
- ✅ 默认初始种群整体放大，并确保 66 个物种全部参与初始化
- ✅ 大地图默认配置下，`1 tick` 从约 `0.947s` 优化到约 `0.344s`
- ✅ 引入植物邻域缓存、动物局部查询缓存、水生两阶段选点、空间索引 offset 缓存
- ✅ 新增附近水生按物种快速计数，降低 `swim()` 和候选点评分成本

**生态与资源系统**：
- ✅ 物种总数更新为 66：17 植物、34 陆地/鸟类/两栖、15 水生
- ✅ 完整接入微栖息地资源层：
  - `canopy_roost`
  - `night_roost`
  - `shrub_shelter`
  - `nectar_patch`
  - `wetland_patch`
  - `riparian_perch`
- ✅ 微栖位已接入容量、可用量、占位、季节脉冲、逐 tick 恢复与繁殖约束
- ✅ 动物开始优先搜索可用微栖位，而不只是找植物

**GUI**：
- ✅ 高级界面支持中文 UI、字号放大、布局重排
- ✅ 新增微栖位 overlay，可用 `M` 开关
- ✅ 选中生物详情卡支持显示繁殖资源与局部可用度

**文档**：
- ✅ README、ARCHITECTURE、ECOSYSTEM、MECHANICS、SPECIES、USAGE、ADVANCED-GUI 已同步到当前实现

**验证**：
- ✅ `tests/test_ecosystem.py`
- ✅ `test_foodchain.py`
- ✅ 默认大地图性能基准

### v3.1 (2026-04-06 10:30)

**水域机制优化**：
- ✅ 新增 `minnow`，作为河道/浅湖独立的中层小型猎物来源
- ✅ 初始分布与自然迁入按 `river_channel` / `lake_shallow` / `lake_deep` 分流
- ✅ `catfish` / `pike` / `large_fish` / `blackfish` 优先转向捕食 `minnow`，降低对 `shrimp` 与湖区 `small_fish` 的集火
- ✅ `shrimp` 扩展可利用食物（藻类、浮游生物、水草、底栖碎屑），并增强浅湖/河道回补

**验证**：
- ✅ `tests/test_ecosystem.py` 新增 `minnow` 注册与 `shrimp` 栖息地来源测试
- ✅ 500 tick 抽样中 `shrimp` 与 `minnow` 可稳定共存

---

### v3.0 (2026-04-05 20:00)

**新增内容**：
- ✅ 果类植物 7种（苹果树、樱桃树、葡萄藤等）
- ✅ 杂食动物 8种（熊、野猪、獾、貉、臭鼬、负鼠、长鼻浣熊、犰狳）

**文档更新**：
- ✅ 创建 omnivores.py
- ✅ 更新 plants.py（新增果类植物）
- ✅ 更新 ecosystem.py（导入新物种）
- ✅ 创建 fruits-omnivores.md
- ✅ 更新 SPECIES.md（完整物种手册）
- ✅ 更新 MECHANICS.md（完整机制手册）
- ✅ 更新 ECOSYSTEM.md（总索引）
- ✅ 更新 config/test.yaml

**代码变更**：
```
src/entities/omnivores.py    [新建] 8种杂食动物
src/entities/plants.py       [修改] +7种果类植物
src/core/ecosystem.py        [修改] 导入新物种
config/test.yaml             [修改] 初始种群配置
```

---

### v2.0 (2026-04-05 19:30)

**新增内容**：
- ✅ 竞争机制（食物、领地、配偶、植物）
- ✅ 防御机制（逃跑、反击、伪装、群体、装甲等）
- ✅ 新天敌：黑鱼、狗鱼、狼、蜘蛛
- ✅ 新鸟类：喜鹊、乌鸦、啄木鸟、蜂鸟
- ✅ 新哺乳动物：松鼠、刺猬、蝙蝠、浣熊

**文档更新**：
- ✅ 创建 competition.py
- ✅ 创建 competition-defense.md
- ✅ 更新 animals.py（新物种）
- ✅ 更新 aquatic.py（黑鱼、狗鱼）

**代码变更**：
```
src/entities/competition.py  [新建] 竞争与防御机制
src/entities/animals.py      [修改] +8种新动物
src/entities/aquatic.py      [修改] +2种天敌鱼
```

---

### v1.5 (2026-04-05 17:10)

**核心改进**：
- ✅ 移除所有硬编码上限
- ✅ 添加食物因子机制
- ✅ 添加天敌压力机制

**文档更新**：
- ✅ 创建 foodchain-complete-fix.md
- ✅ 更新 aquatic.py（移除上限）
- ✅ 更新 animals.py（移除上限）

**代码变更**：
```
src/entities/aquatic.py      [修改] 移除硬编码上限，添加食物因子
src/entities/animals.py      [修改] 移除硬编码上限，添加食物因子
src/core/ecosystem.py        [修改] 导入新物种
```

---

### v1.0 (2026-04-04)

**初始版本**：
- ✅ 基础生态系统
- ✅ 陆地动物 + 水生生物
- ✅ 基础食物链
- ✅ 环境系统

**文档**：
- ✅ README.md
- ✅ ARCHITECTURE.md
- ✅ SPECIES.md（旧版）
- ✅ MECHANICS.md（旧版）
- ✅ USAGE.md

---

## 待更新检查清单

每次代码更新后，检查以下项目：

- [ ] SPECIES.md - 是否有新物种？
- [ ] MECHANICS.md - 是否有新机制？
- [ ] ECOSYSTEM.md - 总览是否需要更新？
- [ ] config/test.yaml - 初始种群是否需要调整？
- [ ] CHANGELOG.md - 是否记录变更？

---

## 文档维护责任人

- **主要负责人**：余星晨
- **更新原则**：代码变更 → 文档同步更新
- **检查频率**：每次提交前

---

*创建时间：2026-04-05 20:00*
# v3.4.8 - Recover squirrel through tick 200

- ✅ 使用默认 `config.yaml` 先跑 `5 seeds x 200 ticks` 基线，检查陆地哺乳动物 `deer / rabbit / fox / wolf / mouse / wild_boar / squirrel / bear`
- ✅ 基线 `tick 200` 存活数为：
  - `deer`: `36 / 28 / 32 / 42 / 40`
  - `rabbit`: `49 / 75 / 70 / 73 / 83`
  - `fox`: `26 / 23 / 37 / 31 / 17`
  - `wolf`: `30 / 26 / 30 / 29 / 31`
  - `mouse`: `33 / 23 / 29 / 42 / 24`
  - `wild_boar`: `25 / 22 / 19 / 24 / 38`
  - `squirrel`: `1 / 0 / 0 / 0 / 1`
  - `bear`: `253 / 235 / 277 / 256 / 259`
- ✅ 仅对 `squirrel` 做低密度保种修复：略微延长寿命、降低基础饥饿、缩短孕期，放宽 `canopy_roost / canopy_forage` 繁殖阈值；同时加入低密度产仔逻辑、适度提高自然迁入兜底，并给 `squirrel` 加上小型 prey reserve，避免末端种群被捕食链打穿
- ✅ 修复后再次执行同一组 `5 seeds x 200 ticks`，`tick 200` 存活数为：
  - `deer`: `35 / 33 / 32 / 30 / 49`
  - `rabbit`: `38 / 77 / 64 / 68 / 38`
  - `fox`: `13 / 26 / 28 / 26 / 25`
  - `wolf`: `21 / 30 / 20 / 24 / 23`
  - `mouse`: `26 / 32 / 33 / 32 / 25`
  - `wild_boar`: `34 / 15 / 17 / 24 / 37`
  - `squirrel`: `48 / 48 / 102 / 31 / 95`
  - `bear`: `242 / 275 / 296 / 266 / 226`
- ✅ 对比基线确认：本轮修复把 `squirrel` 从 `3 / 5` seed 灭绝、其余 seed 仅剩 `1` 只，恢复到 `5 / 5` seed 稳定存活；同时其余 7 个被检查的陆地哺乳动物在修复前后都保持 `tick 200` 非零
- ✅ 额外执行 `PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py`，现有基础生态测试全部通过

# v4.0-alpha34 (2026-04-09 08:10)

- `grassland.py` 现已把区域级 `prosperity / collapse` 相位接入草原链摘要与反馈：
  - `prosperity_phase_weight`
  - `collapse_phase_weight`
- `carrion.py` 现已把区域级 `prosperity / collapse` 相位接入尸体资源链摘要与反馈：
  - `prosperity_phase_carrion`
  - `collapse_phase_carrion`
- 这使得 `prosperity / collapse` 不再只影响重平衡，也开始改变：
  - 草原链 summary 权重
  - 尸体资源链 summary 权重
  - 区域反馈强度

# v4.0-alpha36 (2026-04-09 11:25)

- `social.py` 现已把：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
  接入长期相位：
  - `grassland_boom_phase`
  - `grassland_bust_phase`
  - `grassland_prosperity_phase`
  - `grassland_collapse_phase`
- 这意味着 herd/vulture 的长期迁移与追踪周期，已经开始真正改变草原区的长期繁荣/衰退走势

# v4.0-alpha35 (2026-04-09 11:10)

- `social.py` 现已在长期热点记忆之上进一步形成显式周期：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
- `grassland.py` 现已吸收 herd-route 周期：
  - `herd_route_cycle_pressure`
  - `herd_route_cycle_support`
- `carrion.py` 现已吸收 aerial-carrion 周期：
  - `aerial_carrion_cycle_pressure`
  - `aerial_carrion_cycle_support`
- 这层 herd / vulture 周期现已进入：
  - `social_trends.phase_scores`
  - `grassland_chain`
  - `carrion_chain`
  - 低频重平衡

# v4.0-alpha34 (2026-04-09 10:35)

- `social.py` 现已把运行中的 `antelope / zebra / vulture` 通道热点写入长期 `hotspot_scores`：
  - `herd_hotspot_memory`
  - `herd_apex_memory`
  - `vulture_hotspot_memory`
  - `vulture_carrion_memory`
- `grassland.py` 现已吸收 herd 通道热点记忆：
  - `herd_memory_corridors`
  - `herd_memory_pressure`
- `carrion.py` 现已吸收空中尸体通道记忆：
  - `aerial_memory_lanes`
  - `aerial_memory_overlap`
- 这层 herd / vulture 热点记忆现已进入：
  - `social_trends`
  - `grassland_chain`
  - `carrion_chain`
  - 区域反馈

# v4.0-alpha33 (2026-04-09 07:45)

- `social.py` 新增区域级长期相位：
  - `grassland_prosperity_phase`
  - `grassland_collapse_phase`
- 这层长期相位现已进入：
  - `relationship_state["social_trends"]`
  - `WorldSimulation` 综合生态压力
- `grassland.py` 现已把区域长期相位接入草原链重平衡：
  - `prosperity_phase_herd_gain`
  - `collapse_phase_scavenger_loss`
- `carrion.py` 现已把区域长期相位接入尸体资源链重平衡：
  - `prosperity_phase_scavenger_gain`
  - `collapse_phase_apex_loss`

# v4.0-alpha32 (2026-04-09 07:25)

- `social.py` 新增显式长期相位：
  - `grassland_boom_phase`
  - `grassland_bust_phase`
- 这层长期相位现已进入：
  - `relationship_state["social_trends"]`
  - `WorldSimulation` 综合生态压力
- `grassland.py` 现已把长期 boom/bust 相位直接接入草原链重平衡：
  - `boom_phase_herd_release`
  - `bust_phase_herd_drag`
  - `boom_phase_apex_release`
  - `bust_phase_apex_drag`
- `carrion.py` 现已把长期 boom/bust 相位直接接入尸体资源链重平衡：
  - `boom_phase_scavenger_release`
  - `bust_phase_scavenger_drag`
- 对应测试已补齐，确认长期相位已经进入：
  - `social_trends`
  - `grassland_rebalancing`
  - `carrion_rebalancing`

# v3.4.7 - Recover mouse through tick 200

- ✅ 先用默认 `config.yaml` 复核当前 HEAD 的 `5 seeds x 200 ticks`：`night_moth` 与 `rabbit` 已恢复到目标线之上，真正仍然 `0 / 5` 的仅剩 `mouse`
- ✅ 仅对 `mouse` 做低密度修复：提高 prey reserve（`8 -> 16`）、补上灌丛/菌丛躲藏与繁殖微栖位、缩短孕期，并改成更偏向“低密度保种”而不是“高密度扩张”的产仔公式
- ✅ 修复后再次执行 `5 seeds x 200 ticks`，`tick 200` 存活数分别为：
  - `night_moth`: `0 / 12 / 46 / 31 / 7`
  - `rabbit`: `49 / 75 / 70 / 73 / 83`
  - `mouse`: `33 / 23 / 29 / 42 / 24`
  - `fox`: `26 / 23 / 37 / 31 / 17`
  - `wolf`: `30 / 26 / 30 / 29 / 31`
  - `wild_boar`: `25 / 22 / 19 / 24 / 38`
- ✅ 按本轮目标判断：`night_moth` 达到 `4 / 5`、`rabbit` 达到 `5 / 5`、`mouse` 达到 `5 / 5`，且 `fox / wolf / wild_boar` 均自然保持非零

# v3.4.6 - Verify land mammals through tick 200
# v4.0-alpha38 - Feed prosperity phases into herd and carrion runtime

- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现在会把 `grassland_prosperity_phase / grassland_collapse_phase` 回灌到 `antelope / zebra / vulture`
- ✅ `Antelope / Zebra / Vulture` 新增 prosperity/collapse 运行态偏置，长期区域繁荣/衰退现在会直接影响 herd 通道与空中尸体通道行为

# v4.0-alpha39 - Feed prosperity phases into hotspot memory

- ✅ `grassland_prosperity_phase / grassland_collapse_phase` 现在会反向影响 `herd_hotspot_memory / herd_apex_memory / vulture_hotspot_memory / vulture_carrion_memory`
- ✅ 长期区域繁荣/衰退不再只作用于摘要和运行态行为，也开始改变 herd 与空中尸体通道记忆的累积方向

# v4.0-alpha40 - Couple prosperity phases back into route cycles

- ✅ `grassland_prosperity_phase / grassland_collapse_phase` 现在会继续反向影响 `herd_route_cycle / aerial_carrion_cycle`
- ✅ 草原长期繁荣/衰退相位与 herd/carrion 通道周期已开始形成双向耦合，而不再只是单向传导

# v4.0-alpha41 - Feed route cycles into runtime corridor behavior

- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现在会把 `herd_route_cycle / aerial_carrion_cycle` 直接回灌到 `antelope / zebra / vulture`
- ✅ herd/carrion 长期周期现在会直接影响食草群与秃鹫的运行期通道偏置，而不只作用于摘要和重平衡

# v4.0-alpha42 - Feed runtime route cycles back into territory

- ✅ `runtime_territory_state` 现在会采集运行中的 `herd_route_cycle_runtime / aerial_carrion_cycle_runtime`
- ✅ `territory.runtime_signals` 与领地压力现在会吸收 herd/carrion 的运行期周期行为，形成更完整的空间反馈闭环

# v4.0-alpha43 - Feed social cycles into regional resources

- ✅ `apply_region_social_trend_feedback()` 现在会把 `herd_route_cycle` 回灌到 `surface_water`
- ✅ `apply_region_social_trend_feedback()` 现在也会把 `aerial_carrion_cycle` 回灌到 `carcass_availability`

# v4.0-alpha44 - Feed regional resource anchors into territory chains

- ✅ `territory` 现在会直接读取区域 `surface_water / carcass_availability`，生成 `surface_water_anchor / carcass_anchor`
- ✅ `grassland_chain / carrion_chain` 现在会吸收这些资源锚点，资源层正式进入草原长期闭环

# v4.0-alpha45 - Feed regional resource anchors into social trend memory

- ✅ `social_trends` 现在会直接读取 `surface_water_anchor / carcass_anchor`
- ✅ 这些资源锚点现在会继续抬升：
  - `herd_hotspot_memory / herd_apex_memory`
  - `vulture_hotspot_memory / vulture_carrion_memory`
  - `herd_route_cycle / aerial_carrion_cycle`
- ✅ 资源层现在已经不只进入 `territory / grassland_chain / carrion_chain`，也开始进入长期社群记忆与周期层

# v4.0-alpha46 - Feed resource anchors into long-term prosperity phases

- ✅ `surface_water_anchor / carcass_anchor` 现在会继续直接影响：
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
- ✅ 草原长期繁荣/衰退相位现在已经不只受热点和社群周期驱动，也开始受区域资源锚点直接驱动

# v4.0-alpha47 - Feed resource anchors into dominant layer switching

- ✅ `surface_water_anchor` 现在会继续抬升 `grassland_chain` 的 `herd_layer / browse_layer`
- ✅ `carcass_anchor_pressure` 现在会继续抬升 `carrion_chain` 的 `aerial_scavenge_layer / herd_source_layer`
- ✅ 资源锚点现在已经开始直接参与 `dominant_layer` 的切换，而不只是参与链路分数和长期相位


- ✅ 使用默认 `config.yaml` 执行 `5 seeds x 200 ticks` 回归，检查陆地哺乳动物 `deer / rabbit / fox / wolf / mouse / wild_boar / squirrel`
- ✅ `tick 200` 存活数分别为：
  - `deer`: `9 / 12 / 11 / 14 / 9`
  - `rabbit`: `0 / 0 / 0 / 0 / 0`
  - `fox`: `0 / 0 / 0 / 0 / 0`
  - `wolf`: `0 / 0 / 0 / 0 / 0`
  - `mouse`: `0 / 0 / 0 / 0 / 0`
  - `wild_boar`: `1 / 0 / 0 / 0 / 0`
  - `squirrel`: `0 / 1 / 0 / 1 / 0`
- ✅ 同组 `owl tick 200` 为 `7 / 18 / 17 / 3 / 17`，已满足全 seed 非零，因此本轮未对 `owl` 做额外改动

# v3.4.5 - Improve bat survival through tick 200

- ✅ 仅调整 `Bat` 自身续航参数，未改动 `night_moth`：略微延长寿命、降低基础饥饿消耗，并提高夜间微栖息地恢复与白天栖息回血收益
- ✅ 将 bat 的改动重点从“扩张”收回到“省着活”，去除对 `night_moth` 的额外追击加成，并下调夜间单次实猎成功上限，避免通过额外压榨猎物换存活
- ✅ 使用默认 `config.yaml` 执行 `5 seeds x 200 ticks` 回归；`bat` 在 `tick 200` 分别为 `6 / 5 / 4 / 11 / 3`，已达成全 seed 非零；同组 `night_moth tick 100-120` 最低值为 `80 / 38 / 65 / 76 / 73`

# v3.4.4 - Stabilize night_moth -> bat/owl through tick 120

- ✅ 仅调整 `night_moth -> bat/owl` 夜行链参数：增强 `night_moth` 的低密度恢复与保底存量，未改动任何水生参数
- ✅ 下调 `bat` / `owl` 对 `night_moth` 的夜间优先捕食强度，并补强 `bat` / `owl` 的低密度续航与回补条件
- ✅ 使用默认 `config.yaml` 执行 `5 seeds x 200 ticks` 回归；`tick 100-120` 区间内 `night_moth` 最低值分别为 `75 / 73 / 47 / 73 / 82`，不再出现接近清零的 seed

# v3.4.3 - Fix moth and minnow chain breaks

- ✅ `night_moth` 略微延长寿命并提升低密度繁殖恢复，缓解首代在约 22 tick 集中老化后导致的夜行链断层
- ✅ `bat` / `owl` 夜间优先捕食 `night_moth` 时，改为尊重 `get_predation_chance()` 的保底约束，不再绕过猎物保留量
- ✅ `minnow` 略微延长寿命并增强低密度补群参数，减少约 42 tick 首代老化叠加高位鱼压力造成的 prey 断层
- ✅ 针对 `night_moth -> bat/owl` 与 `minnow -> pike/catfish` 执行多 seed 200 tick 回归验证
# v4 Ongoing - Runtime prosperity anchors feed back into territory and social trends

- ✅ `runtime_anchor_prosperity` 现已从 `lion / hyena / antelope / zebra / vulture` 重新汇总回 `runtime_territory_state`
- ✅ `territory.runtime_signals` 新增：
  - `apex_anchor_prosperity_runtime`
  - `herd_anchor_prosperity_runtime`
  - `aerial_anchor_prosperity_runtime`
- ✅ 这些运行期繁荣锚点已经开始直接影响：
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
- ✅ `social_trends` 现已继续吸收这些运行期繁荣锚点，并让它们进入：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
  - `grassland_boom_phase`
  - `grassland_prosperity_phase`
  - `cycle_signals`
- ✅ 新增并通过回归断言，验证 `territory` 与 `social_trends` 都能读到这批新的运行期繁荣锚点
- ✅ `grassland_chain` 现已继续把：
  - `herd_anchor_prosperity_runtime`
  - `apex_anchor_prosperity_runtime`
  写成：
  - `runtime_herd_anchor_prosperity_pull`
  - `runtime_apex_anchor_prosperity_pull`
  并接入区域反馈与低频 herd/apex 重平衡
- ✅ `carrion_chain` 现已继续把：
  - `aerial_anchor_prosperity_runtime`
  写成：
  - `runtime_aerial_anchor_prosperity_pull`
  并接入区域反馈与空中清道夫重平衡
- ✅ 世界级长期压力聚合现已继续吸收：
  - `runtime_herd_anchor_prosperity_pull`
  - `runtime_aerial_anchor_prosperity_pull`
  - `runtime_apex_anchor_prosperity_pull`
  - `herd_anchor_prosperity_runtime`
  - `aerial_anchor_prosperity_runtime`
  - `apex_anchor_prosperity_runtime`
- ✅ 这些运行期繁荣锚点现在已经开始直接进入区域：
  - `prosperity_pressure`
  - `runtime_resource_pressure`
  - `health_state["prosperity" / "stability"]`
- ✅ `grassland_chain` 与 `carrion_chain` 现已继续直接吸收区域：
  - `prosperity`
  - `stability`
  - `collapse_risk`
  并把它们写成：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
- ✅ 这意味着区域长期健康度现在已经开始不经过运行体中转，直接改变两条链的摘要权重与主导层偏置
- ✅ `grassland_rebalancing` 与 `carrion_rebalancing` 现已继续直接吸收：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
- ✅ 这些区域长期健康锚点现在已经开始直接生成：
  - `regional_prosperity_support`
  - `regional_stability_support`
  - `regional_collapse_drag`
  并进入草食群、清道夫和顶层捕食者的低频物种池调节
- ✅ `social_trends` 现也开始继续直接吸收区域：
  - `prosperity`
  - `stability`
  - `collapse_risk`
- ✅ 这些区域长期健康信号现在已经开始直接进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `cycle_signals`
  也就是说，区域长期健康度现在已经开始不经过运行体中转，直接塑造社群长期记忆层
- ✅ `territory` 现也开始继续吸收上一周期 `social_trends` 中的：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
  - `grassland_collapse_phase`
- ✅ 这些区域长期社会锚点现在已经开始直接回灌：
  - `waterhole_spacing`
  - `pride_core_range`
  - `clan_den_range`
  - `apex_boundary_conflict`
  - `carcass_route_overlap`
  也就是说，区域长期社会锚点现在已经开始直接改变领地布局压力，而不只停留在 `social_trends`
- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现也开始继续吸收：
  - `regional_prosperity_bias`
  - `regional_stability_bias`
  - `regional_collapse_bias`
- ✅ 这些区域长期社会锚点现在已经开始直接进入：
  - `lion / hyena` 的中心漂移粘滞
  - `antelope / zebra` 的 herd 通道偏置
  - `vulture` 的空中尸体通道偏置
- ✅ `WorldSimulation._build_runtime_territory_state()` 现也开始继续吸收运行中的：
  - `regional_prosperity_bias`
  - `regional_stability_bias`
  - `regional_collapse_bias`
- ✅ 这些运行期长期社会锚点现在已经开始重新汇总成：
  - `apex_regional_bias_runtime`
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  并回灌到 `territory.runtime_signals`
- ✅ `social_trends` 现也开始继续吸收：
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
- ✅ 这些运行期长期社会锚点现在已经开始直接进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
- ✅ `grassland_chain` 现也开始继续吸收：
  - `herd_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  并把它们写成：
  - `runtime_herd_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
- ✅ 这些运行中的区域长期社会锚点现在已经开始直接进入：
  - 草原链摘要
  - 草原链区域反馈
  - herd/apex 的低频重平衡
- ✅ `carrion_chain` 现也开始继续吸收：
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  并把它们写成：
  - `runtime_aerial_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
- ✅ 这些运行中的区域长期社会锚点现在已经开始直接进入：
  - 尸体资源链摘要
  - 尸体资源链区域反馈
  - 空中清道夫/apex 的低频重平衡
- ✅ `WorldSimulation._build_combined_pressures()` 现也开始继续吸收：
  - `runtime_herd_regional_bias_pull`
  - `runtime_aerial_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
  以及 `territory.runtime_signals` 里的：
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
- ✅ 这些运行中的区域长期社会锚点现在已经开始直接进入：
  - 世界级 `prosperity_pressure`
  - 世界级 `collapse_pressure`
  - 世界级 `runtime_resource_pressure`
  并进一步影响区域长期 `prosperity / collapse_risk / stability`
- ✅ `runtime_territory_state` 现也开始继续把区域：
  - `prosperity`
  - `stability`
  - `collapse_risk`
  组合成：
  - `apex_regional_health_anchor_runtime`
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
- ✅ `territory.runtime_signals` 现也开始继续吸收这 3 个运行期长期健康锚点，并把它们继续回灌到：
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
  也就是说，区域长期健康度现在已经开始直接形成 runtime 级领地健康锚点
- ✅ `social_trends` 现也开始继续吸收：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
- ✅ 这些运行期区域长期健康锚点现在已经开始直接进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
- ✅ `grassland_chain` 现也开始继续吸收：
  - `herd_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  并把它们写成：
  - `runtime_herd_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
- ✅ `carrion_chain` 现也开始继续吸收：
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  并把它们写成：
  - `runtime_aerial_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
- ✅ 这些运行期区域长期健康锚点现在已经开始直接进入：
  - 两条链摘要
  - 两条链区域反馈
  - herd/aerial/apex 的低频重平衡
- ✅ `WorldSimulation._build_combined_pressures()` 现也开始继续吸收：
  - `runtime_herd_health_anchor_pull`
  - `runtime_aerial_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
  以及 `territory.runtime_signals` 里的：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
- ✅ 这些运行期区域长期健康锚点现在已经开始直接进入：
  - 世界级 `prosperity_pressure`
  - 世界级 `collapse_pressure`
  - 世界级 `runtime_resource_pressure`
  并进一步影响区域长期 `prosperity / collapse_risk / stability`
- ✅ `apply_region_social_trend_feedback()` 现也开始继续读取这些 runtime 健康锚点对应的 `cycle_signals`
- ✅ 它们现在已经开始继续回灌：
  - `surface_water`
  - `carcass_availability`
  - `predation_pressure`
  - `resilience`
  也就是说，运行期区域长期健康锚点现在已经开始反向抬升区域资源锚点与韧性本身
- ✅ `runtime_territory_state` 现也开始继续把：
  - `surface_water`
  - `carcass_availability`
  - `runtime_anchor_prosperity`
  反向并入：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
- ✅ 这意味着运行期区域长期健康锚点现在已经从纯健康值推进成资源-健康复合锚点

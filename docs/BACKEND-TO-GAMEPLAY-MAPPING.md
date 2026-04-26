# EcoWorld 后端生态系统到游戏玩法映射

本文档定义：

- 后端生态系统输出什么
- 前端 2D 游戏应该怎么读
- 这些数据如何变成玩家能感受到的玩法

它的目的不是重复后端字段说明，而是建立一层固定的 **翻译层**。

后续任何新玩法，如果不能落到这张映射表里，就不应该直接接进主线。

## 1. 核心原则

后端不直接等于玩法。

必须经过 4 层翻译：

1. `生态状态`
2. `区域特征`
3. `现场机会`
4. `玩家回报`

也就是说：

- 后端负责产生真实世界状态
- 前端负责把它压成玩家能读懂、能选择、能承担风险的内容

## 2. 当前后端已稳定可用的数据源

当前 `godot/data/world_state.json` 和 `src/ui/world_payload.py` 已经稳定导出这些主结构：

- `world`
- `active_region`
- `region_details`
- `chains`
- `world_bulletin`
- `narrative`
- `map_legend`
- `ui_meta`

新增的玩家策略回灌入口：

- Godot 写入：`godot/data/world_strategy_intent.json`
- 后端读取：`scripts/export_world_state.py --intent godot/data/world_strategy_intent.json`
- 后端回写：`world_state.json.player_intent`
- 区域回写：`region_details[*].player_intent` 或 `region_details[*].incoming_player_intent`
- 玩法目标回写：`world_state.json.gameplay_state`
- 区域推荐回写：`region_details[*].gameplay_hint`
- 探索撤离写入：`godot/data/expedition_reports.json`
- 探索回灌回写：`world_state.json.expedition_reports` 与 `region_details[*].expedition_report`

应用当前策略并生成新的 Godot 世界状态：

```bash
PYTHONPATH=. python3 scripts/export_world_state.py --pretty
```

Godot HUD 里的 `应用回合` 按钮会执行同一条后端导出链路；命令行主要用于调试或批处理。按钮成功执行后会清理 `world_strategy_intent.json`，避免同一个策略在后续回合被重复提交。`expedition_reports.json` 不清理，因为它是区域探索历史，会持续影响后端世界状态。

`gameplay_state.world_goal` 是世界图的全局目标来源，当前基线是让所有生态区保持 `biodiversity >= 0.60`、`resilience >= 0.60`、最高风险 `< 0.55`。`region_details[*].gameplay_hint` 是每个生态区本回合的推荐行动来源，优先级为高风险修复、低多样性/低韧性调查、弱连接通道、稳定区补记录。

2D 区域探索撤离后会写入 `expedition_reports.json`。后端导出时会读取这些报告，把累计情报、档案进度、主情报方向和撤离风险转成生态系统变化：

- 提高 `ecological_pressures.survey_coverage`
- 按主情报方向补强相关资源
- 按情报量和档案进度压低最高风险
- 小幅提升 `biodiversity` 和 `resilience`
- 在区域详情写入 `expedition_report`，世界播报写入“撤离报告已回灌后端”

如果撤离报告里包含 `world_task_action`，后端会按任务类型分化结算：

- `调查`：额外提高调查覆盖，并略微提高主情报方向资源收益。
- `修复`：额外压低最高风险，并提高韧性收益。
- `通道`：强化本区到撤离目标区的连接，目标区反向连接也会小幅增强。

这些额外收益只在撤离报告的 `world_task_completed = true` 时生效。探索场景的完成判定是：

- `调查`：情报达到 3，或发现 3 种动物，或完成至少 1 个热点。
- `修复`：完成至少 1 个热点，并且情报达到 3。
- `通道`：从世界任务指定目标通道撤离；如果没有指定目标，则任意有效目标出口都算完成。

玩家流程上，撤离回到世界图后如果 HUD 显示“撤离报告待回灌”，需要点击 `应用回合`。该按钮会重新执行后端导出，把刚才的探索结果写入新的 `world_state.json`。

当前策略动作：

- `survey` / `调查`：提高本区调查覆盖度，用于表达玩家正在补情报。
- `restore` / `修复`：提升本区最强资源项，并压低最高风险项。
- `corridor` / `通道`：强化本区到目标区的连接；导出后世界焦点可切到目标区，并在目标区写入 `incoming_player_intent`。

其中，2D 主线最核心的是：

- `region_details[*].health_state`
- `region_details[*].resource_state`
- `region_details[*].ecological_pressures`
- `region_details[*].species_manifest`
- `region_details[*].exploration_hotspots`
- `region_details[*].frontier_links`
- `region_details[*].chain_focus`
- `region_details[*].pressure_headlines`
- `region_details[*].dynamic_region_state`
- `region_details[*].narrative`

## 3. 翻译总表

### 3.1 健康状态 -> 区域总态

后端字段：

- `health_state.prosperity`
- `health_state.stability`
- `health_state.collapse_risk`
- `health_state.resilience`

前端翻译为：

- 区域总体健康
- 当前 expedition 的基础风险背景
- 当前区域是：
  - `恢复窗口`
  - `稳态区`
  - `脆弱区`
  - `崩塌边缘`

玩法用途：

- 左上 HUD 总态
- 世界图区域摘要
- 本轮 expedition 的默认风险底色
- 出口撤离建议

### 3.2 资源状态 -> 现场热点价值

后端字段：

- `resource_state.surface_water`
- `resource_state.grazing_pressure`
- `resource_state.carcass_availability`
- `resource_state.canopy_cover`

前端翻译为：

- 哪个热点更值得先去
- 哪种物种更可能在附近活跃
- 当前可出现的观察窗口是什么

玩法用途：

- 排序当前热点优先级
- 生成热点行动卡
- 影响区域路线推荐
- 影响调查奖励类型

### 3.3 生态压力 -> 实时危险与事件

后端字段：

- `ecological_pressures.predation_pressure`
- `pressure_headlines`
- `dynamic_region_state`

前端翻译为：

- 当前危险主来源
- 当前区域是不是进入高压期
- 当前更可能触发：
  - 追逐压力
  - 追猎爆发
  - 草食群偏移
  - 聚群中断

玩法用途：

- 中上事件条
- 左上危险度
- 调查中断概率
- 撤离判断

### 3.4 物种清单 -> 区域可调查对象

后端字段：

- `species_manifest[*].species_id`
- `species_manifest[*].label`
- `species_manifest[*].category`
- `species_manifest[*].count`

前端翻译为：

- 当前区域有哪些调查对象
- 哪些是关键观察物种
- 哪些物种是高价值情报来源

玩法用途：

- 动物群生成
- 图鉴列表
- 物种调查目标
- 情报值计算

### 3.5 热点清单 -> 区域主任务节点

后端字段：

- `exploration_hotspots[*].hotspot_id`
- `exploration_hotspots[*].label`
- `exploration_hotspots[*].summary`
- `exploration_hotspots[*].intensity`
- `exploration_hotspots[*].biome`

前端翻译为：

- 本轮区域的“任务点”
- 每个任务点当前更适合调查什么
- 哪个热点是高价值热点

玩法用途：

- 热点采样任务
- 路线引导
- 区域三阶段状态切换

### 3.6 前线连接 -> 撤离与切区后果

后端字段：

- `frontier_links[*].target_region_id`
- `frontier_links[*].target_name`
- `frontier_links[*].target_role`

前端翻译为：

- 出口去哪里
- 下一区域是什么类型
- 这轮 expedition 的后续方向是什么

玩法用途：

- 出口卡
- 切区说明
- 世界图后续选择

### 3.7 链路焦点 -> 区域主线类型

后端字段：

- `chain_focus`
- `chains`
- `_build_chain_focus(...)` 产出的链路摘要

前端翻译为：

- 当前区域主叙事线是什么
- 当前值得优先观察的不是“所有东西”，而是哪条生态链

玩法用途：

- 区域 intro
- 当前阶段目标
- 热点排序偏置
- 日志标题和图鉴副标题

### 3.8 叙事和播报 -> 世界观表达

后端字段：

- `region_intro`
- `region_summary`
- `narrative`
- `world_bulletin`

前端翻译为：

- 为什么这个区域值得进入
- 这个区域当前的前线含义是什么
- 本轮 expedition 的“语言风格”应该是什么

玩法用途：

- 世界图文案
- 区域入口文案
- 日志摘要
- 撤离总结

## 4. 游戏内部状态机如何读后端

2D 当前基线是：

- `追踪`
- `记录`
- `撤离`

这三段必须明确读后端，而不是只按本地计数。

### 4.1 追踪阶段

读取：

- `species_manifest`
- `exploration_hotspots`
- `chain_focus`
- `resource_state`

转成：

- 当前优先热点
- 当前优先物种类别
- 当前主路线推荐

玩家感受到的是：

- 先去哪
- 先追什么

### 4.2 记录阶段

读取：

- `species_manifest`
- `exploration_hotspots`
- `ecological_pressures`
- `dynamic_region_state`

转成：

- 当前调查收益
- 当前调查风险
- 当前窗口是否稳定

玩家感受到的是：

- 现在按住 `Space` 值不值
- 会不会被高压打断

### 4.3 撤离阶段

读取：

- `health_state`
- `ecological_pressures`
- `frontier_links`

转成：

- 当前是否适合撤离
- 现在撤和继续贪的取舍
- 哪个出口更合理

玩家感受到的是：

- 要不要带着情报走
- 走向哪条下一前线

## 5. 玩家回报系统映射

后端生态系统很宏大，但玩家回报不能散。

主回报只保留 4 类：

### 5.1 物种情报

来源：

- 首次记录物种

前端用途：

- 图鉴
- 情报值
- 世界层“已知区域生态组成”

### 5.2 热点情报

来源：

- 完成热点采样

前端用途：

- 热点完成度
- 区域主线推进
- 世界图下次进入时的路线建议

### 5.3 压力情报

来源：

- 见证追逐压力
- 见证追猎结果

前端用途：

- 高价值日志
- 危险度理解
- 世界层风险研判

### 5.4 撤离报告

来源：

- 从出口离开

前端用途：

- 把本轮结果压成一条 expedition summary
- 回灌世界图
- 触发下一轮区域选择

## 6. 绝不能直接暴露给玩家的后端层

下面这些后端数据应该用于驱动，不该原样展示：

- tick 级更新
- 全量 species counts 明细表
- 全量 actor 内部值
- 细粒度 microhabitat 容量
- 未翻译的链路技术字段

原因很简单：

- 这些会让玩家失去重点
- 会让游戏变成看监控面板

## 7. 未来扩展规则

以后新增后端字段时，必须先回答这 3 个问题：

1. 它影响的是：
   - 区域状态
   - 现场机会
   - 玩家回报
   - 世界回灌
   的哪一类？

2. 玩家在一轮 expedition 里能感受到它吗？

3. 它会形成新的选择，还是只是增加信息噪音？

如果回答不清楚，就先不接前端。

## 8. 第一批必须进代码的正式翻译项

后面最该先落代码的，不是所有字段，而是这 8 条：

1. `health_state -> 区域总态`
2. `resource_state -> 热点优先级`
3. `ecological_pressures -> 危险度`
4. `species_manifest -> 物种调查收益`
5. `exploration_hotspots -> 热点采样收益`
6. `frontier_links -> 出口/切区价值`
7. `chain_focus -> 当前区域主线`
8. `撤离总结 -> 世界层回灌`

## 9. 一句话标准

如果后端某个系统不能最终变成：

- 玩家能看懂的区域状态
- 玩家能追的现场机会
- 玩家能承担的风险
- 玩家能带走的情报

那它暂时就还没有真正进入游戏。 

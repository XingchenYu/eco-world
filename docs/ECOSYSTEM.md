# EcoWorld 生态系统说明

## 项目目标

EcoWorld 不是严格科研仿真器，而是一个可交互、可扩展、强调链式反馈的生态世界模拟器。

它当前重点关注：

- 食物链是否能自洽
- 环境变化是否能传导到种群
- 栖位资源是否会影响迁移与繁殖
- 在大地图和高种群下是否还能稳定运行

## 当前生态组成

### 植物 17

- 基础植物：`grass`、`bush`、`flower`、`moss`
- 结构植物：`tree`、`vine`、`fern`
- 特殊植物：`cactus`、`berry`、`mushroom`
- 果类植物：`apple_tree`、`cherry_tree`、`grape_vine`、`strawberry`、`blueberry`、`orange_tree`、`watermelon`

### 陆地动物、鸟类与两栖 34

- 基础中层：`insect`、`rabbit`、`mouse`、`deer`
- 捕食者：`fox`、`wolf`、`snake`、`spider`
- 鸟类：`bird`、`eagle`、`owl`、`duck`、`swan`、`sparrow`、`parrot`、`kingfisher`、`magpie`、`crow`、`woodpecker`、`hummingbird`
- 哺乳与杂食：`squirrel`、`hedgehog`、`bat`、`raccoon`、`bear`、`wild_boar`、`badger`、`raccoon_dog`、`skunk`、`opossum`、`coati`、`armadillo`
- 两栖：`frog`

### 水生物种 15

- 生产者：`algae`、`seaweed`、`plankton`
- 消费者：`small_fish`、`minnow`、`carp`、`shrimp`、`tadpole`、`water_strider`、`pufferfish`
- 捕食者：`catfish`、`large_fish`、`blackfish`、`pike`、`crab`

## 默认世界

默认配置见 [config.yaml](/Users/yumini/Projects/eco-world/config.yaml)。

当前默认世界：

- 宽度：`2560`
- 高度：`1920`
- 网格：`20`
- 实际运行格数：`128 x 96`

默认启动时，所有 66 个物种都会有初始个体。

## 关键生态回路

### 陆地回路

`植物 -> 昆虫 / 兔子 / 鹿 / 老鼠 -> 狐狸 / 狼 / 蛇 / 猫头鹰 / 鹰`

补充支路：

- `flower -> bee / hummingbird -> 果类植物授粉稳定`
- `insect -> spider / bird / frog / bat`
- `mouse / rabbit -> fox / owl / eagle / wolf`
- `浆果 / 果树 -> 鸟类 / 松鼠 / 杂食哺乳类`

### 水域回路

`algae / seaweed / plankton -> shrimp / minnow / small_fish / carp / tadpole -> catfish / large_fish / blackfish / pike / crab`

其中：

- `minnow` 主要承担河道 prey 层
- `blackfish` 更偏湖区猎物
- `pike` 更偏河道和浅水猎物

## 河流与湖泊

水域不再被视为同一种环境，而是细分为：

- `river_channel`
- `lake_shallow`
- `lake_deep`

它们会共同影响：

- 含氧量
- 流速
- 深度系数
- 营养盐
- 捕食命中率
- 繁殖成功率
- 局部迁移方向

同时存在岸带过渡区：

- `mud`
- `sand`

这会影响底栖消费者和近岸捕食。

## 微栖息地资源层

当前生态系统已经从“附近有树/灌木”升级到“独立微栖位资源”。

资源类型：

- `canopy_roost`
- `night_roost`
- `shrub_shelter`
- `nectar_patch`
- `wetland_patch`
- `riparian_perch`

它们具备：

- 容量
- 可用量
- 占用量
- 季节脉冲
- 逐 tick 恢复和衰减

当前影响路径：

- 动物优先搜索可用 patch
- patch 不足会降低繁殖成功率
- 局部 patch 会提供恢复收益
- 同类会对 patch 容量形成占位竞争

## 当前平衡策略

系统当前不是靠简单上限，而是综合：

1. 食物可用性
2. 天敌压力
3. 软承载抑制
4. habitat 适宜度
5. 微栖位可用量
6. 自然迁入
7. 季节与天气脉冲

自然迁入也不是凭空刷新，而是：

- 陆地物种从边缘陆地进入
- 水生物种从边界水体或河道进入
- 必须通过 habitat 检查
- 受冷却期限制

## 监控输出

[Ecosystem.get_statistics()](/Users/yumini/Projects/eco-world/src/core/ecosystem.py) 当前返回：

- tick、天数、季节、天气、温度、光照
- 植物 / 陆地动物 / 水生生物数量
- 全物种数量表
- 性别统计
- 健康度
- 预警
- 建议
- 最近因果事件
- 环境摘要
- 生态 actor
- `microhabitats`

## 当前状态

当前版本已经具备：

- 66 物种完整初始化
- 微栖位资源层进入主循环
- 高级 GUI 可视化微栖位
- 大地图高种群默认配置
- 空间索引和多层缓存优化

当前已实测默认大地图性能约：

- `1 tick ≈ 0.344s`
- `5 tick ≈ 2.244s`

## 当前边界

- 平衡仍然对随机种子敏感
- 夜行链和两栖链还在持续优化
- 高种群长跑下，仍需继续观察 `owl / bat / frog / pike`

更新时间：2026-04-06

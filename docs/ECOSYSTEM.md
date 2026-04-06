# EcoWorld 生态系统说明

## 项目目标

EcoWorld 不是严格的科研仿真器，而是一个偏演示型、可扩展、可交互的生态世界。

它关注的是：

- 生态链条是否连贯
- 环境变化是否能传导到种群
- 玩家是否能通过少量干预看到连锁反应

## 当前生态组成

### 陆地植物

- 基础植物：`grass`、`bush`、`flower`、`moss`
- 结构植物：`tree`、`vine`、`fern`
- 特殊植物：`cactus`、`berry`、`mushroom`
- 果类植物：`apple_tree`、`cherry_tree`、`grape_vine`、`strawberry`、`blueberry`、`orange_tree`、`watermelon`

### 陆地动物

- 基础中层：`insect`、`rabbit`、`mouse`、`deer`
- 捕食者：`fox`、`wolf`、`snake`、`spider`
- 鸟类：`bird`、`eagle`、`owl`、`duck`、`swan`、`sparrow`、`parrot`、`kingfisher`、`magpie`、`crow`、`woodpecker`、`hummingbird`
- 哺乳与杂食：`squirrel`、`hedgehog`、`bat`、`raccoon`、`bear`、`wild_boar`、`badger`、`raccoon_dog`、`skunk`、`opossum`、`coati`、`armadillo`
- 两栖：`frog`

### 水生生物

- 生产者：`algae`、`seaweed`、`plankton`
- 消费者：`small_fish`、`minnow`、`carp`、`shrimp`、`tadpole`、`water_strider`、`pufferfish`
- 捕食者：`catfish`、`large_fish`、`blackfish`、`pike`、`crab`

## 关键生态回路

### 陆地回路

`植物 -> 昆虫/兔子/鹿/老鼠 -> 狐狸/狼/蛇/鸟类`

附加支路：

- `flower -> bee / hummingbird -> 果类植物稳定结果`
- `insect -> spider / bird / frog / bat`
- `mouse / rabbit -> fox / wolf / owl / eagle`

### 水域回路

`algae / seaweed / plankton -> shrimp / minnow / small_fish / carp / tadpole -> catfish / large_fish / blackfish / pike / crab`

## 环境影响

环境会影响：

- 植物生长速度
- 光照强度
- 水质含氧量
- 温度与季节
- 水边 / 陆地 / 森林可生存区域
- 河流与湖泊中的 habitat 差异

当前水域不再被视为同一种环境，而是细分为：

- `river_channel`：高流速、高混合、高含氧
- `lake_shallow`：浅湖，营养盐和温度波动更明显
- `lake_deep`：深湖，更稳定但深层更容易形成低氧压力

另外，河岸和湖岸周围会生成 `mud` / `sand` 过渡带，形成更真实的水陆交错生态位。

关键水生物种现在还会根据局部 habitat 主动迁移：

- `small_fish` 会偏向高氧河道和浅水觅食带
- `carp` 会向低流速、高营养的湖区聚集
- `blackfish` 会优先寻找深湖和鲤鱼较多的区域
- `pike` 会沿河道和高氧浅水带追逐猎物
- `minnow` 是更偏河道和浅滩的成群小型鱼类，承担狗鱼的主要河道猎物层
- `shrimp` 会在浅湖和缓流高营养区稳定扩散

浅湖岸带现在不只是视觉地形：

- `mud` / `sand` 岸带会为虾等底栖小型生物提供更高的觅食和躲藏价值
- 泥底浅滩能降低螃蟹对虾的局部捕食命中率
- 河道和春季浅滩会提升狗鱼的伏击成功率和产卵成功率

果类植物按季节结果：

- 春季：`cherry_tree`
- 夏季：`grape_vine`、`blueberry`、`watermelon`
- 夏秋：`strawberry`
- 秋季：`apple_tree`
- 冬季：`orange_tree`

## 平衡策略

项目当前不再依赖简单硬上限，而是使用三层控制：

1. 食物可用性
2. 天敌压力
3. 软承载抑制
4. 自然迁入
5. habitat 适宜度
6. 栖息地趋向迁移

软承载抑制主要用于防止自然繁殖在长跑里指数爆炸，尤其是水域基础生产者和水生消费者。

自然迁入不是凭空生成，而是沿地图边缘、河道或连通水体进行的低频迁入，用来避免关键控制物种永久断链。

## 监控输出

`Ecosystem.get_statistics()` 当前会返回：

- 当前 tick、天数、季节、天气、温度、光照
- 植物 / 动物 / 水生数量
- 全物种数量表
- 陆地性别统计
- 健康度
- 预警
- 建议
- 最近因果链事件
- 环境摘要

## 已知限制

- 水生物种行为仍大量依赖全列表查询
- 平衡模型是聚合启发式，不是精确生态学模型
- GUI 可展示大量信息，但编辑世界状态仍然主要靠快捷生成

更新时间：2026-04-06

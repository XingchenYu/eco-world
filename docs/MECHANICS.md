# EcoWorld 机制说明

## 生命周期

所有生物共享这些基础机制：

- 年龄增长
- 饥饿累积
- 健康变化
- 死亡
- 进食回血
- 动态繁殖率

基础实现位于 [src/core/creature.py](/Users/yumini/Projects/eco-world/src/core/creature.py)。

## 动态繁殖

当前版本不采用“固定繁殖 + 固定上限”的简单模型，而是综合：

- 食物可用性
- 天敌压力
- 当前健康
- 当前饥饿
- 软承载抑制
- habitat 适宜度
- 微栖位资源可用量

## 多样化食谱

当前多数物种采用三层食谱：

- 主食
- 替代食物
- 机会型猎物

设计目标：

- 减少单一链路断裂导致的连锁饿死
- 允许水边、林缘、湿地出现跨生态位取食

## 河流与湖泊机制

当前水域细分为：

- `river_channel`
- `lake_shallow`
- `lake_deep`

这些差异会影响：

- 水质
- 迁移方向
- 捕食成功率
- 繁殖成功率
- 高位鱼的生态位分化

当前关键分工：

- `minnow` 更偏河道和浅滩
- `carp` 更偏低流速、高营养湖区
- `blackfish` 更偏稳定湖区
- `pike` 更偏河道和浅水高氧带
- `shrimp` 更偏浅湖、缓流和泥岸

## 微栖息地资源层

当前已经存在独立资源层，不再只是“附近有植物就加一点分”。

资源类型：

- `canopy_roost`
- `night_roost`
- `shrub_shelter`
- `nectar_patch`
- `wetland_patch`
- `riparian_perch`
- `night_swarm`
- `canopy_forage`
- `shore_hatch`

当前资源层具备：

- `capacity`
- `available`
- `occupancy`
- `seasonal_multiplier`
- 逐 tick 恢复
- 占位衰减

### 当前已接入的行为

- 动物优先搜索 `microhabitat patch`
- patch 接近满载时会被规避
- 栖位可用量会影响恢复收益
- 繁殖成功率绑定局部 patch 可用量
- 同类会在容量上形成竞争

### 物种特定依赖

当前已经有物种特定繁殖资源偏好，例如：

- `owl`、`bat` 偏 `night_roost / canopy_roost`
- `kingfisher` 偏 `riparian_perch / shrub_shelter`
- `hummingbird` 偏 `nectar_patch / shrub_shelter`
- `squirrel` 偏 `canopy_roost`

另外已有更自然的底层资源脉冲：

- `night_swarm` 支撑 `bat / owl` 的夜间飞虫资源
- `shore_hatch` 支撑 `frog / kingfisher` 的岸带羽化资源
- `canopy_forage` 支撑 `squirrel` 的树冠持续觅食资源

## 自然迁入

当前版本的自然迁入机制不是凭空刷入：

- 陆地物种从边缘陆地迁入
- 水生物种从边界水体或河道迁入
- 迁入前要通过 habitat 检查
- 迁入后有冷却期

它主要用于避免关键控制物种在随机波动后永久断链。

## 行为优先级

### 陆地动物

1. 逃跑 / 防御
2. 觅食
3. 求偶
4. 生产
5. 闲逛 / 栖位迁移

### 水生生物

当前水生移动不是纯随机，而是：

1. 生成候选水格
2. 用 habitat 快速粗筛
3. 只对少数候选点做精筛
4. 综合 prey / predator / 底栖收益后移动

## 平衡监控

平衡系统位于 [src/core/balance.py](/Users/yumini/Projects/eco-world/src/core/balance.py)。

当前主要看：

- 陆地基础生产者
- 果类植物
- 授粉者
- 陆地中层消费者
- 陆地捕食者
- 水生基础生产者
- 水生中层消费者
- 水生捕食者

输出包括：

- 健康度
- 预警
- 建议
- 因果事件链

## 性能机制

为了支撑默认大地图和高种群，当前已经接入：

- 轻量空间索引
- `_query_spatial_index()` offset 预计算
- 植物邻域 tick 级缓存
- 统计缓存
- 性别计数缓存
- 食性计数缓存
- ecosystem actor tick 级缓存
- 动物个体级查询缓存
- 水生候选点两阶段筛选
- 邻近水生按物种快速计数
- 动物繁殖率更新优先复用缓存统计

当前默认大地图实测约：

- `1 tick ≈ 0.217s`
- `5 tick ≈ 1.260s`

## 当前模型边界

- 平衡仍是启发式，不是严格能量守恒模型
- 夜行链和两栖链仍在继续收敛
- 微栖位资源层已进入主循环，但个体长期绑定巢位仍未完全展开

更新时间：2026-04-07

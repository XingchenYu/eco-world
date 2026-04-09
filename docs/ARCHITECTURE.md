# EcoWorld 架构说明

## 术语对照

- `Renderer`：渲染层，也就是负责把世界画出来的图形显示层。
- `Core`：核心层，负责主循环、环境、生态更新、平衡分析等核心逻辑。
- `Entities`：实体层，指植物、动物、水生物种等具体生物实现。
- `Config`：配置层，指 `config.yaml` 这类决定世界参数的配置文件。
- `Docs`：文档层，指说明项目结构、机制和设计的文档。
- `Tests`：测试层，指用于验证功能和回归稳定性的测试代码。
- `tick`：模拟步，也就是生态系统每前进一小步的更新时间单位。
- `spatial index`：空间索引，用来加速“附近有什么”的查询。
- `cache`：缓存，把本 tick 或近期重复使用的结果先存起来，减少重复计算。
- `microhabitat`：微栖位，指树冠、灌丛、岸带、夜栖位等更细粒度的小型生态资源点。

## 总览

当前项目可以分成 4 层：

```text
Renderer
  ├─ gui.py
  └─ advanced_gui.py

Core
  ├─ main.py
  ├─ ecosystem.py
  ├─ environment.py
  ├─ creature.py
  └─ balance.py

Entities
  ├─ plants.py
  ├─ animals.py
  ├─ aquatic.py
  ├─ omnivores.py
  └─ competition.py

Config / Docs / Tests
```

## 主调用链

程序从 [src/main.py](/Users/yumini/Projects/eco-world/src/main.py) 启动：

1. 解析命令行参数
2. 加载 YAML 配置
3. 创建 [Ecosystem](/Users/yumini/Projects/eco-world/src/core/ecosystem.py)
4. 根据参数选择 [Renderer](/Users/yumini/Projects/eco-world/src/renderer/gui.py) 或 [AdvancedRenderer](/Users/yumini/Projects/eco-world/src/renderer/advanced_gui.py)
5. 进入主循环

## 核心对象

### `Ecosystem`

文件：[src/core/ecosystem.py](/Users/yumini/Projects/eco-world/src/core/ecosystem.py)

职责：

- 管理植物、陆地动物、水生生物
- 推进每个 tick 的更新
- 维护空间索引和多类缓存
- 提供生成接口与邻域查询
- 维护微栖息地资源层
- 汇总统计并驱动平衡分析

关键属性：

- `plants`
- `animals`
- `aquatic_creatures`
- `environment`
- `balance`
- `microhabitats`
- `_plant_index`
- `_animal_index`
- `_aquatic_index`

### `Environment`

文件：[src/core/environment.py](/Users/yumini/Projects/eco-world/src/core/environment.py)

职责：

- 生成地形、水域、森林、岩石、沙地
- 推进时间、天气、温度和季节
- 维护大气、土壤和水质
- 区分河流、浅湖、深湖以及岸带过渡区

关键子系统：

- `Atmosphere`
- `Soil`
- `WaterQuality`
- `water_bodies`

### `Creature`

文件：[src/core/creature.py](/Users/yumini/Projects/eco-world/src/core/creature.py)

职责：

- 提供通用生命周期
- 维护年龄、健康、饥饿、速度、视野和基础繁殖率
- 提供通用移动、进食和生态修正接口

## 每 Tick 顺序

这里的 `Tick` 指一次完整的模拟更新步，不是现实时间里的“秒”，而是系统内部推进生态的一次离散步骤。

[Ecosystem.update()](/Users/yumini/Projects/eco-world/src/core/ecosystem.py) 当前大致执行：

1. 更新环境
2. 更新微栖息地资源脉冲
3. 更新植物
4. 更新陆地动物
5. 更新水生生物
6. 汇总统计
7. 进行平衡分析和预警生成

## 行为层

### 植物

文件：[src/entities/plants.py](/Users/yumini/Projects/eco-world/src/entities/plants.py)

包含：

- 生长
- 产种 / 孢子传播
- 发芽
- 季节结果
- 空间、光照、根系竞争

### 陆地动物

文件：[src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py)

当前主决策顺序：

1. 逃跑 / 防御
2. 觅食
3. 求偶
4. 产仔
5. 闲逛 / 栖位迁移

动物层现在已经接入：

- 树冠 / 灌丛 / 近水 / 夜栖偏好
- 微栖息地搜索与占位
- 栖位恢复收益
- 物种特定繁殖资源偏好

### 水生生物

文件：[src/entities/aquatic.py](/Users/yumini/Projects/eco-world/src/entities/aquatic.py)

当前采用独立行为模型：

- 水生生产者
- 中层水生消费者
- 高位捕食者
- 两栖相关物种

水生移动已不再是单纯随机游动，而是：

- 候选水格生成
- 粗筛 habitat 评分
- 精筛 prey / predator / 底栖收益
- 选择更适宜位置迁移

## 微栖息地资源层

实现位于 [src/core/ecosystem.py](/Users/yumini/Projects/eco-world/src/core/ecosystem.py)。

当前独立资源类型：

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

- `position`
- `capacity`
- `available`
- `occupancy`
- `seasonal_multiplier`
- 逐 tick 恢复 / 衰减

并且已经接入：

- 动物移动与栖位搜索
- 局部恢复收益
- 繁殖成功率
- 高级 GUI 可视化

## 性能设计

当前版本的关键优化点：

- 植物、动物、水生生物都接入了轻量空间索引
- `_query_spatial_index()` 使用 offset 预计算缓存
- `get_nearby_plants()` 使用 tick 级缓存
- ecosystem actor 使用 tick 级缓存，主循环与统计面板共用同一份结果
- 动物行为使用个体级短缓存
- 动物繁殖率更新已优先复用物种数和食性计数缓存
- 水生移动采用“两阶段选点”
- 水生候选评分支持按物种快速计数，避免构造完整对象列表
- 统计函数使用 tick 级缓存、性别计数缓存和食性计数缓存

在当前默认大地图配置下，已实测约：

- `1 tick ≈ 0.217s`
- `5 tick ≈ 1.260s`

## 扩展建议

新增物种时建议按这个顺序接入：

1. 在实体模块新增类
2. 定义食物来源 / 猎物 / 天敌
3. 补充微栖位偏好
4. 在 `spawn_*` 中注册
5. 在统计物种表中加入
6. 在 GUI 中文名 / 渲染映射中加入
7. 在平衡模型里决定是否作为关键控制物种

更新时间：2026-04-07

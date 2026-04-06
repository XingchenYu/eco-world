# EcoWorld 架构说明

## 总览

EcoWorld 当前由四层组成：

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

Assets / Config / Docs / Tests
```

## 主调用链

程序从 [src/main.py](../src/main.py) 启动：

1. 解析命令行参数
2. 读取 YAML 配置
3. 创建 `Ecosystem`
4. 根据参数选择 `Renderer` 或 `AdvancedRenderer`
5. 进入主循环

## 核心对象

### `Ecosystem`

文件：[src/core/ecosystem.py](../src/core/ecosystem.py)

职责：

- 管理所有生物集合
- 驱动每个 tick 的更新
- 提供生成接口
- 提供邻域查询
- 汇总统计信息
- 连接 `Environment` 和 `EcoBalance`

关键属性：

- `plants`
- `animals`
- `aquatic_creatures`
- `environment`
- `balance`
- `events`
- `tick_count`

### `Environment`

文件：[src/core/environment.py](../src/core/environment.py)

职责：

- 生成地形、水域、森林、沙地和岩石区域
- 推进时间、天气、温度和季节
- 维护土壤、水质和大气参数
- 区分河流、浅湖、深湖和水岸过渡带

关键子系统：

- `Atmosphere`
- `Soil`
- `WaterQuality`
- `water_bodies`

### `Creature`

文件：[src/core/creature.py](../src/core/creature.py)

职责：

- 提供所有生物共享的生命周期
- 维护年龄、健康、饥饿、速度、视野和动态繁殖率
- 提供通用移动与进食逻辑

## 每 Tick 的顺序

`Ecosystem.update()` 的执行顺序：

1. 更新环境
2. 记录上一轮物种统计
3. 更新植物
4. 更新陆地动物
5. 更新水生生物
6. 分析种群变化导致的因果链
7. 更新平衡预警与健康度

## 行为架构

### 植物

主文件：[src/entities/plants.py](../src/entities/plants.py)

植物行为包含：

- 生长
- 产种 / 孢子传播
- 发芽
- 结果
- 竞争：空间、光照、根系

### 陆地动物

主文件：[src/entities/animals.py](../src/entities/animals.py)

通用行为决策顺序：

1. 逃跑 / 防御
2. 觅食
3. 求偶
4. 产仔
5. 闲逛

补充模块：

- [src/entities/omnivores.py](../src/entities/omnivores.py)：杂食动物
- [src/entities/competition.py](../src/entities/competition.py)：食物竞争、领地竞争、配偶竞争与防御行为

### 水生生物

主文件：[src/entities/aquatic.py](../src/entities/aquatic.py)

当前采用独立行为模型：

- 水生基础生产者
- 水生消费者
- 水生捕食者
- 两栖物种（青蛙、蝌蚪）

## 性能设计

当前版本的两个关键优化点：

- `Ecosystem` 引入轻量空间索引，用于植物和陆地动物的邻域查询
- 自然繁殖使用软承载抑制，而不是硬编码上限

仍然存在的主要限制：

- 水生物种大多仍使用全列表扫描
- 长时间高种群仿真仍会明显变慢

## 统计与平衡

平衡系统位于 [src/core/balance.py](../src/core/balance.py)。

当前健康评估覆盖：

- 陆地基础生产者
- 果类植物
- 授粉者
- 陆地中层消费者
- 陆地捕食者
- 水生基础生产者
- 水生中层消费者
- 水生捕食者

输出包括：

- `health`
- `alerts`
- `recommendations`
- `butterfly_events`

## 扩展建议

新增物种时建议按以下顺序接入：

1. 在实体模块新增类
2. 写清食物来源 / 猎物 / 天敌
3. 在 `Ecosystem.spawn_*` 中注册
4. 在统计物种表中加入
5. 在 GUI 颜色或图标映射中加入
6. 在平衡模型中决定是否纳入关键组

更新时间：2026-04-06

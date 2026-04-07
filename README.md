# EcoWorld

EcoWorld 是一个正在从“多物种生态沙盒原型”升级为“多尺度虚拟生态世界模拟器”的项目。

当前仓库中的 `v3.x` 版本已经具备：

- 多物种生态模拟
- 陆地、淡水与部分海岸/微栖位逻辑
- 基础食物链、繁殖、环境与平衡系统
- 高级 `pygame` 可视化界面
- 大地图与缓存优化

下一阶段的 `v4.0` 目标是把它升级为：

- 多大陆、多生态区、多尺度地图
- 陆地、河流、湖泊、海洋、天空一体化生态系统
- 数据驱动物种模板体系
- 捕食、竞争、共生、寄生、工程师物种等独立关系系统
- 图鉴、事件、任务、玩家干预和完整游戏化体验

## 当前版本

当前仓库可视为 `v3.x` 可运行原型，特点包括：

- 单区域高密度生态模拟
- 67 个已接入物种
- 微栖息地资源层
- 高级 GUI 和生态统计面板
- 空间索引与多层缓存优化

但它仍然有明显边界：

- 仍是单区域、单尺度逻辑
- 多数物种仍偏向脚本式实现
- 生态关系系统尚未完全独立
- 还不是完整的世界级模拟

## V4 设计文档

`v4.0` 的完整升级设计已经确定，核心文档如下：

- [V4 世界设计](/Users/yumini/Projects/eco-world/docs/V4-WORLD.md)
- [V4 物种系统设计](/Users/yumini/Projects/eco-world/docs/V4-SPECIES.md)
- [V4 生态关系设计](/Users/yumini/Projects/eco-world/docs/V4-RELATIONS.md)
- [V4 路线图](/Users/yumini/Projects/eco-world/docs/V4-ROADMAP.md)
- [V4 实施步骤](/Users/yumini/Projects/eco-world/docs/V4-IMPLEMENTATION-STEPS.md)

这些文档定义了项目如何从当前原型，演进成完整的虚拟生态世界。

## 当前仓库结构

```text
eco-world/
├── src/
│   ├── core/          # 当前环境、生态主循环、平衡与基础生命模型
│   ├── entities/      # 当前植物、动物、水生物种与杂食动物实现
│   ├── renderer/      # 当前 GUI
│   └── main.py        # 当前入口
├── docs/              # 当前文档与 v4 设计文档
├── tests/             # 当前测试
├── config.yaml        # 默认配置
└── requirements.txt   # 依赖
```

后续 `v4.0` 将新增：

- `src/world/`
- `src/ecology/`
- `src/agents/`
- `src/populations/`
- `src/sim/`
- `src/data/`
- `src/ui/`

## 当前运行方式

默认运行：

```bash
PYTHONPATH=. python3 src/main.py
```

高级界面：

```bash
PYTHONPATH=. python3 src/main.py --advanced
```

测试配置：

```bash
PYTHONPATH=. python3 src/main.py --config config/test.yaml --advanced
```

无头模式：

```bash
PYTHONPATH=. python3 src/main.py --headless
```

## 当前版本能力

- 默认世界已扩大到约原来的 10 倍面积
- 默认启动即包含所有已注册物种
- 已接入微栖息地资源层：
  - `canopy_roost`
  - `night_roost`
  - `shrub_shelter`
  - `nectar_patch`
  - `wetland_patch`
  - `riparian_perch`
  - `night_swarm`
  - `canopy_forage`
  - `shore_hatch`
- 动物会优先搜索可用微栖位资源，而不只是找植物
- 微栖位已接入容量、占用、季节脉冲、逐 tick 恢复与繁殖门槛
- 高级 GUI 已支持中文界面、窗口自适应、微栖位叠层和选中生物资源信息
- 空间索引与缓存已接入大地图和高种群运行

## 当前默认世界

默认配置见 [config.yaml](/Users/yumini/Projects/eco-world/config.yaml)：

- 世界尺寸：`2560 x 1920`
- 网格尺寸：`20`
- 运行网格：`128 x 96`
- 初始种群：所有物种均有初始个体

## 当前性能

当前仓库已具备多层缓存和空间索引优化。实际性能会随种群和配置波动；精确数值应以最新基准测试为准。

## 当前文档导航

- [ARCHITECTURE.md](/Users/yumini/Projects/eco-world/docs/ARCHITECTURE.md)
- [ECOSYSTEM.md](/Users/yumini/Projects/eco-world/docs/ECOSYSTEM.md)
- [SPECIES.md](/Users/yumini/Projects/eco-world/docs/SPECIES.md)
- [MECHANICS.md](/Users/yumini/Projects/eco-world/docs/MECHANICS.md)
- [USAGE.md](/Users/yumini/Projects/eco-world/docs/USAGE.md)
- [ADVANCED-GUI.md](/Users/yumini/Projects/eco-world/docs/ADVANCED-GUI.md)
- [CHANGELOG.md](/Users/yumini/Projects/eco-world/docs/CHANGELOG.md)

## 项目路线

- `v3.x`：当前可运行生态沙盒原型
- `v4.0`：世界骨架、模板系统、关系系统、区域生态
- `v4.5+`：更完整海洋、天空、迁徙、疾病、文明干预与游戏化系统

## 项目定位

EcoWorld 的最终目标不是简单增加物种数量，而是构建一个：

- 真实
- 可扩展
- 丰富
- 可观察
- 可干预
- 可游玩的完整虚拟生态世界

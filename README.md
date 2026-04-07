# EcoWorld

EcoWorld 是一个基于 Python 和 Pygame 的 2D 虚拟生态系统模拟器，当前版本已经演进到“陆地生态 + 水域生态 + 微栖息地资源层 + 双 GUI”的完整结构。

当前代码基于 **67 个物种** 运行：

- 17 种植物
- 35 种陆地动物、鸟类与两栖动物
- 15 种水生物种

## 当前版本重点

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
- 大地图默认配置下，核心更新性能已明显优化

## 运行环境

```bash
pip install -r requirements.txt
```

依赖：

- `pygame`
- `pyyaml`
- `numpy`

## 启动

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

## 默认世界

默认配置见 [config.yaml](/Users/yumini/Projects/eco-world/config.yaml)：

- 世界尺寸：`2560 x 1920`
- 网格尺寸：`20`
- 运行网格：`128 x 96`
- 初始种群：所有物种均有初始个体

在当前默认配置下，初始化后大致规模为：

- 植物约 `2440`
- 陆地动物约 `2460`
- 水生生物约 `1410`

## 主要能力

- 动态生态循环：生长、觅食、捕食、交配、产仔、死亡
- 多样化食谱：主食、替代食物、机会型猎物
- 河流与湖泊分化：`river_channel`、`lake_shallow`、`lake_deep`
- 微栖息地资源层：树冠位、夜栖位、灌丛位、花蜜位、湿地位、岸栖位
- 双界面：经典 GUI 与高级游戏化 GUI
- 生态监控：健康度、预警、建议、因果链事件
- 空间索引与缓存：用于大地图和高种群运行，包含 tick 级 ecosystem actor 缓存

## 当前性能

以默认放大后的世界为基线，当前实测约为：

- `1 tick ≈ 0.217s`
- `5 tick ≈ 1.260s`

相对放大地图后的早期基线：

- 单 tick 下降约 `77%`
- 5 tick 下降约 `76%`

## 项目结构

```text
eco-world/
├── src/
│   ├── core/          # 环境、生态主循环、平衡监控、基础生命模型
│   ├── entities/      # 植物、动物、水生物种、杂食与竞争系统
│   ├── renderer/      # 经典 GUI 与高级 GUI
│   └── main.py        # 入口
├── config/            # 补充配置
├── docs/              # 说明文档
├── tests/             # 基础测试
├── config.yaml        # 默认配置
└── requirements.txt   # 依赖
```

## 推荐阅读顺序

1. [src/main.py](/Users/yumini/Projects/eco-world/src/main.py)
2. [src/core/ecosystem.py](/Users/yumini/Projects/eco-world/src/core/ecosystem.py)
3. [src/core/environment.py](/Users/yumini/Projects/eco-world/src/core/environment.py)
4. [src/core/creature.py](/Users/yumini/Projects/eco-world/src/core/creature.py)
5. [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py)
6. [src/entities/plants.py](/Users/yumini/Projects/eco-world/src/entities/plants.py)
7. [src/entities/aquatic.py](/Users/yumini/Projects/eco-world/src/entities/aquatic.py)
8. [src/renderer/advanced_gui.py](/Users/yumini/Projects/eco-world/src/renderer/advanced_gui.py)

## 文档导航

- [docs/ARCHITECTURE.md](/Users/yumini/Projects/eco-world/docs/ARCHITECTURE.md)
- [docs/ECOSYSTEM.md](/Users/yumini/Projects/eco-world/docs/ECOSYSTEM.md)
- [docs/SPECIES.md](/Users/yumini/Projects/eco-world/docs/SPECIES.md)
- [docs/MECHANICS.md](/Users/yumini/Projects/eco-world/docs/MECHANICS.md)
- [docs/USAGE.md](/Users/yumini/Projects/eco-world/docs/USAGE.md)
- [docs/ADVANCED-GUI.md](/Users/yumini/Projects/eco-world/docs/ADVANCED-GUI.md)

## 验证

已持续验证：

- `PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py`
- `PYTHONDONTWRITEBYTECODE=1 python3 test_foodchain.py`
- 默认大地图性能基准
- GUI 冒烟渲染

更新时间：2026-04-07

# EcoWorld

EcoWorld 是一个正在从“多物种生态沙盒原型”升级为“多尺度虚拟生态世界模拟器”的项目。

## 术语对照

为了避免文档里只出现英文标识，这里先给出当前高频英文术语的中文解释：

- `GUI`：图形用户界面，也就是游戏里的可视化操作界面。
- `runtime`：运行期，指模拟正在运行的这一轮真实状态。
- `anchor`：锚点，指会长期稳定拉动系统的资源或状态来源。
- `bias`：偏置，指会把行为或结果往某个方向推的长期倾向。
- `pull`：拉力，指某个因素正在把系统往某个状态拉动。
- `phase`：相位，指系统处在扩张、收缩、繁荣、衰退等周期阶段。
- `cycle`：周期，指跨多轮 tick 的反复波动节律。
- `food web`：食物网，指多个物种之间的能量和捕食关系网络。
- `cascade`：级联效应，指一个变化继续传导并引起一串后续变化。
- `territory`：领地层，指围绕核心活动区、边界冲突、热点分布的空间系统。
- `social trends`：社群趋势层，指群体记忆、长期恢复/衰退、周期和繁荣相位。
- `grassland chain`：草原链，指草原区域内 herd、predator、scavenger 等层级关系。
- `carrion chain`：尸体资源链，指击杀、残食、地面清道夫、空中清道夫组成的通道。

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
- [Code Review Graph 接入说明](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH.md)

这些文档定义了项目如何从当前原型，演进成完整的虚拟生态世界。

## Code Review Graph

项目现在已经补了 `code-review-graph` 的仓库级接入骨架：

- [/.mcp.json](/Users/yumini/Projects/eco-world/.mcp.json)
- [/.code-review-graphignore](/Users/yumini/Projects/eco-world/.code-review-graphignore)
- [Code Review Graph 接入说明](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH.md)

术语解释：

- `code-review-graph`：代码评审图谱工具，用来分析模块依赖、改动影响面和评审路径。
- `MCP`：模型上下文协议，这里指把外部工具接进客户端的配置方式。
- `ignore`：忽略规则，表示哪些文件不参与图谱分析。

当前仓库层面的接入已经完成，但本机要实际运行，还需要满足本地依赖，详见文档里的中文说明。

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

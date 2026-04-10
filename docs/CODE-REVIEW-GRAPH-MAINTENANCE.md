# Code Review Graph 维护规则

## 术语对照

- `maintenance`：维护，指持续更新文档和配置，让它们不要过期。
- `graph drift`：图谱漂移，指代码结构已经变了，但文档里的图和解释还停留在旧状态。
- `structural change`：结构变化，指模块关系、依赖方向、主闭环或主调度层发生变化。
- `hub file`：枢纽文件，指改动后会波及很多模块的核心文件。
- `review contract`：评审约定，指团队内部默认遵守的 review 规则。
- `source of truth`：事实来源，指判断当前 graph 长什么样时，以真实代码结构为准，而不是以旧文档为准。

## 为什么需要这份规则

这个项目的 graph 不是静态的。

随着后续继续推进：

- 物种会变多
- 生态链会变多
- 世界层、区域层、玩法层会继续增强
- `runtime -> territory -> social -> chain -> world pressure` 这样的反馈闭环会继续增长

所以如果不规定维护规则，很容易出现：

- 代码已经变了
- `code-review-graph` 工具图已经变了
- 但文档里的中文解释、Mermaid 图和 review 路径还停留在旧版本

这就是最典型的 `graph drift`。

## 基本原则

后续统一按这 4 条原则维护：

1. **代码结构是事实来源**  
   当前 graph 长什么样，以真实代码结构为准，不以旧文档为准。

2. **工具图优先，说明图跟进**  
   先看真实依赖和实际影响面，再更新中文解释图。

3. **大改必须同步 graph 文档**  
   只要改动已经影响 review 路径或主闭环，就不能只改代码不改文档。

4. **文档要服务 review，不是做装饰图**  
   graph 文档的目标是帮助快速 review 和缩小阅读范围，不是追求“画得完整”。

## 什么情况下必须更新 graph 文档

出现以下任意一种情况，就必须更新：

### 1. 新增核心模块

例如新增：

- 新的 `src/ecology/*.py`
- 新的 `src/sim/*.py`
- 新的 `src/world/*.py`
- 新的长期趋势层、关系层或链路层

### 2. 主依赖方向变化

例如：

- 原来 `world_simulation -> social`
- 后来变成 `world_simulation -> territory -> social`

这种就属于 graph 结构变化，必须更新文档图。

### 3. 新增新的主闭环

例如后面如果新增：

- 海洋长期闭环
- 天空迁徙闭环
- 文明干预闭环

都必须更新工作流图和文字解释。

### 4. 枢纽文件变化

如果后续新增或替换了主要枢纽文件，比如：

- `social.py` 被拆成多个子模块
- `world_simulation.py` 不再是唯一总调度中心
- `region_simulation.py` 被新的运行时层替代

那也必须更新。

### 5. review 路径变化

如果一次常规 review 的最佳阅读顺序已经明显改变，也必须更新。

例如：

- 以前先看 `social.py`
- 后来应该先看 `trend_memory.py`

这种也算 graph 文档过期。

## 哪些文件要同步更新

当 graph 结构变化时，至少检查并按需要更新这些文件：

- [docs/CODE-REVIEW-GRAPH.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH.md)
- [docs/CODE-REVIEW-GRAPH-WORKFLOWS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-WORKFLOWS.md)
- [docs/CODE-REVIEW-GRAPH-MAINTENANCE.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-MAINTENANCE.md)
- [README.md](/Users/yumini/Projects/eco-world/README.md)
- [docs/CHANGELOG.md](/Users/yumini/Projects/eco-world/docs/CHANGELOG.md)

## 每次更新 graph 文档时要检查什么

建议按这个清单检查：

1. 当前主调度中心还是不是 [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py)
2. 当前长期趋势中间层还是不是 [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 和 [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)
3. 当前区域链有没有新增新的主链
4. 当前运行体回灌路径有没有新增关键节点
5. 当前枢纽文件列表有没有变化
6. 当前高风险热点文件有没有变化
7. 当前最优 review 路径有没有变化
8. Mermaid 图是否还对应真实代码结构

## 推荐维护节奏

### 日常节奏

小改动：

- 如果只是补一个小字段、小测试、小文案
- 且没有改变依赖方向

可以不更新 graph 文档。

### 版本节奏

这些情况建议强制更新一次：

- 每次新增一个新的生态链模块
- 每次新增一个新的长期趋势层
- 每次新增一个新的世界级闭环
- 每次完成一个阶段性重构
- 每次准备做大范围 code review 前

## 对这个项目的当前维护建议

按当前仓库状态，后面最容易触发 graph 文档更新的区域是：

- [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py)
- [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)
- [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py)
- [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)
- [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py)
- [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py)

只要这些文件的职责边界发生明显变化，就应当更新 graph 文档。

## 建议的最小维护动作

如果后面没有时间全面重画文档图，至少要做这 3 件事：

1. 更新 [docs/CODE-REVIEW-GRAPH-WORKFLOWS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-WORKFLOWS.md) 里的“当前项目 graph 是什么样的”
2. 更新“当前枢纽文件”和“推荐 review 路径”
3. 在 [docs/CHANGELOG.md](/Users/yumini/Projects/eco-world/docs/CHANGELOG.md) 里明确写明本轮 graph 结构是否变化

## 结论

后续随着项目推进，graph 一定会持续变化。  
真正要长期维护的不是“某一张固定图”，而是：

- 当前主闭环解释
- 当前枢纽文件列表
- 当前高风险热点
- 当前推荐 review 路径

只要这几项持续同步，`code-review-graph` 就会一直对这个项目有用，而不会变成一次性配置。

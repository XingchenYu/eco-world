# Code Review Graph 接入说明

## 术语对照

- `Code Review Graph`：代码评审图谱工具，用图结构方式展示模块依赖、改动影响面和评审路径。
- `MCP`：模型上下文协议（Model Context Protocol），这里指把外部工具接进 Codex/客户端的方式。
- `.mcp.json`：项目级 MCP 配置文件，用来声明这个仓库有哪些本地可启动的 MCP 服务。
- `uvx`：`uv` 提供的一次性运行命令，作用类似“临时下载并执行一个 Python 工具”。
- `serve`：启动服务模式，这里指启动 `code-review-graph` 的 MCP 服务端。
- `.code-review-graphignore`：评审图谱忽略文件，用来排除资源文件、缓存文件、低价值文档和测试噪音。
- `review scope`：评审范围，指本次 code review 重点关注哪些目录和模块。
- `dependency graph`：依赖图，表示模块之间谁依赖谁。
- `change impact`：改动影响面，表示某个文件修改后会波及哪些模块。

## 这次接入了什么

本仓库现在已经加入了 `code-review-graph` 的项目级接入骨架：

- [/.mcp.json](/Users/yumini/Projects/eco-world/.mcp.json)
- [/.code-review-graphignore](/Users/yumini/Projects/eco-world/.code-review-graphignore)

这意味着：

- 项目已经有统一的 MCP 启动入口
- 仓库已经有专门的评审忽略规则
- 后续做大规模 code review 时，不需要从零配置

## 当前接入方式

项目级 MCP 配置使用的是：

- `uvx`：临时运行工具
- `code-review-graph@latest`：最新版 `code-review-graph`
- `serve`：以 MCP 服务方式启动

也就是说，当前 [/.mcp.json](/Users/yumini/Projects/eco-world/.mcp.json) 的含义是：

“在这个项目里，默认用 `uvx code-review-graph@latest serve` 启动 `code-review-graph` MCP 服务。”

## 当前机器上的实际情况

仓库已经接好了，但**当前机器是否能直接跑起来**，还取决于本地环境。

当前已确认：

- 本仓库之前没有接过 `code-review-graph`
- 当前环境里没有现成的 `code-review-graph` 可执行命令
- 如果本机没有 `uvx`，那就需要先装 `uv`

也就是说：

- 仓库层面：已经完成接入
- 本机运行层面：仍然需要满足工具依赖

## 需要的本地依赖

建议本机具备：

- Python 3.10 或更高版本
- `uv` / `uvx`

推荐安装方式示意：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

安装后可以检查：

```bash
uvx --version
```

## 这个仓库为什么适合用它

这个项目现在已经出现明显的模块层次，很适合图谱式 code review：

- [src/world](/Users/yumini/Projects/eco-world/src/world)
- [src/ecology](/Users/yumini/Projects/eco-world/src/ecology)
- [src/sim](/Users/yumini/Projects/eco-world/src/sim)
- [src/entities](/Users/yumini/Projects/eco-world/src/entities)
- [src/data](/Users/yumini/Projects/eco-world/src/data)

`code-review-graph` 在这个仓库最适合做的事：

- 看 `v4` 新旧模块之间的依赖关系
- 看某次改动会影响哪些生态链模块
- 看 `world / sim / ecology / entities` 的耦合热点
- 帮助做大型 PR 的 review 路线排序

## 仓库专用忽略规则

[/.code-review-graphignore](/Users/yumini/Projects/eco-world/.code-review-graphignore) 现在已经排除了这些低价值输入：

- 缓存文件
- Git 元数据
- 资源图片
- 临时目录
- 部分历史分析文档
- 单次性能脚本

这样做的目的是：

- 减少 review 图里的噪音
- 把重点放在 `src/` 和核心文档
- 避免图片和缓存污染依赖图

## 推荐评审范围

### 1. `v4` 生态主干

重点目录：

- [src/ecology](/Users/yumini/Projects/eco-world/src/ecology)
- [src/sim](/Users/yumini/Projects/eco-world/src/sim)
- [src/world](/Users/yumini/Projects/eco-world/src/world)

适合看：

- `grassland`
- `carrion`
- `social`
- `territory`
- `world_simulation`

### 2. 运行体行为层

重点目录：

- [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py)
- [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py)

适合看：

- runtime 注入是否过深
- 运行体字段是否开始耦合过多
- `lion / hyena / antelope / zebra / vulture` 的行为接口是否一致

### 3. 数据与注册表层

重点目录：

- [src/data/defaults.py](/Users/yumini/Projects/eco-world/src/data/defaults.py)
- [src/data/models.py](/Users/yumini/Projects/eco-world/src/data/models.py)
- [src/data/registry.py](/Users/yumini/Projects/eco-world/src/data/registry.py)

适合看：

- 模板定义是否继续变厚
- runtime bridge 是否开始承担过多职责

## 推荐评审问题

用 `code-review-graph` 看这个项目时，最值得先回答的问题是：

1. `src/sim/world_simulation.py` 是否已经承担过多长期汇总职责？
2. `src/ecology/social.py` 是否正在成为新的“大一统趋势层”？
3. `src/entities/omnivores.py` 和 `src/entities/animals.py` 的 runtime 字段是否增长过快？
4. `grassland -> territory -> social -> world pressure -> runtime` 这条环是否已经过深？
5. 哪些链条应该进一步模块化，而不是继续往现有文件里堆？

## 典型使用方式

当本机具备依赖后，可以按项目级配置直接启动支持 `code-review-graph` 的 MCP 环境。  
如果你只是想按目录做 review，建议优先关注：

- [src/ecology](/Users/yumini/Projects/eco-world/src/ecology)
- [src/sim](/Users/yumini/Projects/eco-world/src/sim)
- [src/entities](/Users/yumini/Projects/eco-world/src/entities)

如果你是想查本轮 `v4` 改动影响面，建议重点从这些文件开始：

- [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py)
- [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py)
- [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)
- [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py)
- [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)

## 结论

现在这个仓库已经完成了 `code-review-graph` 的**项目级接入骨架**：

- 有项目级 MCP 配置
- 有仓库级忽略规则
- 有中文说明文档

如果你想继续看：

- 这个项目当前的主图谱长什么样
- 哪些文件是 graph 里的枢纽和热点
- 后续 code review 应该按什么顺序读

请继续看：

- [Code Review Graph 工作流说明](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-WORKFLOWS.md)

后续如果本机依赖也补齐，就可以直接把它用于这个项目的模块依赖图、改动影响面和大规模 code review 导航。

# Code Review Graph 检查与测试规则

## 术语对照

- `checks`：检查流程，指编译、测试、回归验证这一整套动作。
- `graph-guided checks`：图谱驱动检查，指先看依赖图和影响面，再决定编译哪些文件、跑哪些测试。
- `selective test`：选择性测试，指只跑和当前改动直接相关的测试组。
- `full regression`：全量回归，指跑完整测试集，确认没有全局回归。
- `blast radius`：影响半径，指这次改动最可能波及到哪些模块和文件。
- `smoke test`：冒烟测试，指用最小代价确认核心功能没立即坏掉。

## 这份文档解决什么问题

`code-review-graph` 不能直接减少测试命令本身的输出，但它可以帮这个项目显著减少：

- 不必要的全量测试
- 不必要的全量编译
- 不必要的无关文件阅读
- 不必要的长测试输出分析

也就是说，真正节约 token 的方式不是“自动压缩输出”，而是：

- 少跑
- 精跑
- 少读
- 精读

## 当前可用的测试组

[tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 现在支持按组运行：

- `basic`：基础环境、植物、动物、配置和基础生成测试
- `world`：世界骨架、注册表、关系状态、汇总层测试
- `wetland`：湿地链、河狸、河马、鳄鱼相关测试
- `grassland`：草原链、尸体资源链、领地/共生/捕食反馈测试
- `runtime`：运行期注入、热点记忆、长期偏置、窗口偏置测试
- `species`：关键物种运行体与个体行为测试
- `all`：全量回归

## 常用命令

只跑草原主线：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py grassland
```

只跑运行期注入与长期偏置：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py runtime
```

只跑世界骨架与汇总层：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py world
```

全量回归：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py all
```

## Graph 驱动的编译与测试建议

### 1. 改 [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 或 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)

优先编译：

```bash
PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/grassland.py src/ecology/carrion.py tests/test_ecosystem.py
```

优先测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py grassland
```

### 2. 改 [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 或 [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)

优先编译：

```bash
PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/social.py src/ecology/territory.py src/ecology/grassland.py src/ecology/carrion.py tests/test_ecosystem.py
```

优先测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py world
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py runtime
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py grassland
```

### 3. 改 [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 或 [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py)

优先编译：

```bash
PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/sim/world_simulation.py src/sim/region_simulation.py src/ecology/social.py src/ecology/territory.py src/ecology/grassland.py src/ecology/carrion.py tests/test_ecosystem.py
```

优先测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py world
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py runtime
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py grassland
```

### 4. 改运行体 [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py) 或 [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py)

优先编译：

```bash
PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/entities/animals.py src/entities/omnivores.py tests/test_ecosystem.py
```

优先测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py species
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py runtime
```

## 什么时候必须跑全量回归

出现下面情况时，不要只跑分组测试，必须补一次 `all`：

- 改了 [src/core/ecosystem.py](/Users/yumini/Projects/eco-world/src/core/ecosystem.py)
- 改了 [src/data/defaults.py](/Users/yumini/Projects/eco-world/src/data/defaults.py)
- 改了全局注册表或世界默认地图
- 改了测试分组本身
- 改了跨多个生态链的共享字段
- 改了会影响所有运行体注入的逻辑

## 推荐工作流

最推荐的顺序是：

1. 先看 `code-review-graph` 判断影响半径
2. 按影响半径决定编译文件
3. 先跑对应测试组
4. 只有在共享层改动时再跑 `all`

## 结论

这个项目里，`code-review-graph` 真正节约 token 的方式不是减少单条命令输出，而是减少：

- 不必要的全量测试
- 不必要的全量编译
- 不必要的无关日志阅读

所以后续做检查时，默认应该先问一句：

“这次改动在 graph 上真正影响了哪几个模块？”

而不是默认直接跑完整仓测试。

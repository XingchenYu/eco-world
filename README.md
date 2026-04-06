# EcoWorld

EcoWorld 是一个基于 Python 和 Pygame 的 2D 虚拟生态系统模拟器。项目同时模拟陆地植物、陆地动物、水生生物、季节天气、食物链、竞争/防御行为和生态平衡预警。

当前代码基于 65 个物种运行：

- 17 种植物
- 34 种陆地动物与两栖动物
- 14 种水生生物

## 主要能力

- 动态生态循环：生长、觅食、捕食、交配、产仔、死亡
- 多样化食谱：多数物种具备主食、替代食物和机会型猎物
- 双界面：经典监控界面和高级游戏化界面
- 环境系统：地形、天气、季节、土壤、水质、大气
- 生态监控：健康度、预警、建议、因果链事件
- 可扩展结构：物种行为和渲染逻辑按模块拆分

## 安装

```bash
pip install -r requirements.txt
```

依赖见 [requirements.txt](requirements.txt)：

- `pygame`
- `pyyaml`
- `numpy`

## 运行

基础运行：

```bash
PYTHONPATH=. python3 src/main.py
```

高级界面：

```bash
PYTHONPATH=. python3 src/main.py --advanced
```

指定配置：

```bash
PYTHONPATH=. python3 src/main.py --config config/test.yaml
```

无头模式：

```bash
PYTHONPATH=. python3 src/main.py --headless
```

## 常用参数

- `--config`：配置文件路径
- `--width` / `--height`：窗口尺寸
- `--speed`：初始模拟速度
- `--advanced`：启用高级游戏化界面
- `--classic`：显式启用经典界面
- `--headless`：无 GUI 运行

## 项目结构

```text
eco-world/
├── src/
│   ├── core/          # 环境、主循环、平衡监控、基础生物模型
│   ├── entities/      # 植物、动物、水生与竞争系统
│   ├── renderer/      # 经典 GUI 与高级 GUI
│   └── main.py        # 入口
├── config/            # 补充配置
├── docs/              # 文档
├── tests/             # 基础测试
├── config.yaml        # 默认配置
└── requirements.txt   # 依赖
```

## 推荐阅读顺序

1. [src/main.py](src/main.py)
2. [src/core/ecosystem.py](src/core/ecosystem.py)
3. [src/core/environment.py](src/core/environment.py)
4. [src/core/creature.py](src/core/creature.py)
5. [src/entities/animals.py](src/entities/animals.py)
6. [src/entities/plants.py](src/entities/plants.py)
7. [src/entities/aquatic.py](src/entities/aquatic.py)

## 文档导航

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/ECOSYSTEM.md](docs/ECOSYSTEM.md)
- [docs/SPECIES.md](docs/SPECIES.md)
- [docs/MECHANICS.md](docs/MECHANICS.md)
- [docs/USAGE.md](docs/USAGE.md)
- [docs/ADVANCED-GUI.md](docs/ADVANCED-GUI.md)

## 当前状态

当前版本已经完成以下修复与升级：

- 修复配置未真正传入 `Ecosystem` 的问题
- 修复 `src/core` 包级循环导入
- 统一天气接口与旧字段兼容
- 修复植物模块中的旧地形判断与种子类导入问题
- 轻量接入植物竞争与动物竞争/防御逻辑
- 引入空间索引，降低邻域查询开销
- 为自然繁殖加入软承载抑制，缓解群落指数爆炸
- 重写生态平衡评估，覆盖陆地、水域、授粉与捕食压力

## 验证

已验证：

- `tests/test_ecosystem.py`
- `test_foodchain.py`
- 100 tick 烟雾演化

更新时间：2026-04-05

# EcoWorld 使用指南

## 术语对照

- `advanced`：高级界面模式，也就是功能更完整、信息更多的界面。
- `classic`：经典界面模式，也就是更简单、更传统的界面。
- `headless`：无头模式，指不打开图形界面，只运行模拟逻辑。
- `config`：配置文件，用来定义世界大小、初始种群、环境参数等。
- `performance benchmark`：性能基准，用来测量每若干个 `tick` 的耗时。
- `tick`：模拟步，生态系统前进一步的计算单位。

## 安装

```bash
pip install -r requirements.txt
```

建议环境：

- Python 3.9+
- Pygame 2.6+

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

## 常用参数

| 参数 | 说明 |
|---|---|
| `--config` | 指定配置文件 |
| `--width` | 窗口宽度 |
| `--height` | 窗口高度 |
| `--speed` | 初始速度 |
| `--advanced` | 高级界面 |
| `--classic` | 经典界面 |
| `--headless` | 无图形模式 |

## 默认配置

默认配置文件：

- [config.yaml](/Users/yumini/Projects/eco-world/config.yaml)
- [config/test.yaml](/Users/yumini/Projects/eco-world/config/test.yaml)

默认世界：

- 尺寸：`2560 x 1920`
- 网格：`20`
- 运行格数：`128 x 96`
- 所有 66 个物种均有初始个体

## 经典界面

| 按键 | 功能 |
|---|---|
| `Space` | 暂停 / 继续 |
| `+` / `=` | 加速 |
| `-` | 减速 |
| `P` | 切换右侧面板 |
| `G` | 添加草 |
| `R` | 添加兔子 |
| `F` | 添加狐狸 |
| `I` | 添加昆虫 |
| `A` | 添加藻类 |
| `S` | 添加小鱼 |
| `Q` | 退出 |

## 高级界面

详见 [ADVANCED-GUI.md](/Users/yumini/Projects/eco-world/docs/ADVANCED-GUI.md)。

常用操作：

| 操作 | 说明 |
|---|---|
| 鼠标滚轮 | 缩放 |
| 右键拖拽 | 平移视角 |
| 左键 | 选中生物 |
| 调整窗口大小 | 自适应重排 |
| `1-9` | 快速生成物种 |
| `F1-F4` | 切换侧边栏面板 |
| `M` | 显示 / 隐藏微栖位叠层 |
| `Home` | 重置视角 |

## 测试

基础测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py basic
```

按模块运行测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py world
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py wetland
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py grassland
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py runtime
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py species
```

全量回归：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py all
```

按 graph 自动生成检查建议：

```bash
python3 scripts/graph_checks.py
```

如果只想要某一档最小命令，减少说明输出：

```bash
python3 scripts/graph_checks.py --profile targeted --commands-only
```

如果只检查已暂存改动：

```bash
python3 scripts/graph_checks.py --staged
```

食物链测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 test_foodchain.py
```

性能基准示例：

```bash
python3 - <<'PY'
import time, random
from src.main import load_config
from src.core.ecosystem import Ecosystem

random.seed(1)
eco = Ecosystem(config=load_config())
for ticks in (1, 5):
    t0 = time.time()
    for _ in range(ticks):
        eco.update()
    print("ticks", ticks, "dt", round(time.time() - t0, 3))
PY
```

更新时间：2026-04-06

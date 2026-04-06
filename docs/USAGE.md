# EcoWorld 使用指南

## 安装

```bash
pip install -r requirements.txt
```

建议环境：

- Python 3.9+
- Pygame 2.5+

## 启动

### 默认界面

```bash
PYTHONPATH=. python3 src/main.py
```

### 高级界面

```bash
PYTHONPATH=. python3 src/main.py --advanced
```

### 使用测试配置

```bash
PYTHONPATH=. python3 src/main.py --config config/test.yaml --advanced
```

### 无头模式

```bash
PYTHONPATH=. python3 src/main.py --headless
```

## 参数

| 参数 | 说明 |
|---|---|
| `--config` | 指定配置文件 |
| `--width` | 窗口宽度 |
| `--height` | 窗口高度 |
| `--speed` | 初始速度 |
| `--advanced` | 高级界面 |
| `--classic` | 经典界面 |
| `--headless` | 无图形模式 |

## 经典界面操作

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

## 高级界面操作

详见 [ADVANCED-GUI.md](ADVANCED-GUI.md)，常用操作如下：

| 操作 | 说明 |
|---|---|
| 鼠标滚轮 | 缩放 |
| 右键拖拽 | 平移视角 |
| 左键 | 选中生物 |
| 调整窗口大小 | 自适应重排高级界面 |
| `1-9` | 快速生成物种 |
| `F1-F4` | 切换侧边栏面板 |
| `Home` | 重置视角 |

## 配置文件

默认配置文件为：

- [config.yaml](../config.yaml)
- [config/test.yaml](../config/test.yaml)

主要配置段：

- `world`
- `time`
- `environment`
- `plants`
- `animals`
- `initial_population`
- `display`

## 测试

基础测试：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py
```

食物链脚本：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 test_foodchain.py
```

更新时间：2026-04-06

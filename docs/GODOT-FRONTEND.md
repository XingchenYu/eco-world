# Godot 前端接入说明

本文档说明如何把当前 Python 世界模拟接到 Godot 前端。

## 为什么换 Godot

当前 `pygame` 界面适合原型和调试，不适合做你要的那种：

- 中文完整显示
- 更像游戏而不是后台面板
- 更精致的地图、节点、转场和菜单

所以现在前端路线改为：

- `Python`：继续负责生态模拟与世界状态
- `Godot`：负责世界地图、区域 UI、菜单和表现层

## 当前结构

这次接入已经新增了 3 层：

1. `Python 世界状态导出`
   - [scripts/export_world_state.py](/Users/yumini/Projects/eco-world/scripts/export_world_state.py)

2. `Python -> Godot 数据桥`
   - [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py)

3. `Godot 工程骨架`
   - [godot/project.godot](/Users/yumini/Projects/eco-world/godot/project.godot)
   - [godot/scenes/world_map.tscn](/Users/yumini/Projects/eco-world/godot/scenes/world_map.tscn)
   - [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd)

## 术语对照

- `frontend`：前端，也就是玩家看到和操作的界面层。
- `payload`：载荷，这里指导出给前端读取的结构化 JSON 数据。
- `scaffold`：骨架，指已经搭好基本工程结构，但还没有全部美术和交互。
- `scene`：场景，Godot 里的界面或地图页面。
- `node`：节点，Godot 里组成场景的基本单元。
- `bridge`：桥接层，负责把 Python 数据整理成 Godot 能直接吃的格式。

## 当前数据流

当前前端数据流是：

1. Python 世界模拟运行
2. [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 把 `WorldSimulation` 转成前端 JSON
3. [scripts/export_world_state.py](/Users/yumini/Projects/eco-world/scripts/export_world_state.py) 把 JSON 写到：
   - `godot/data/world_state.json`
4. Godot 读取这个 JSON
5. Godot 渲染世界地图和右侧区域情报

## 现在能做什么

当前 Godot 前端已经支持：

- 世界地图页面
- 六大区域节点
- 中文标题和区域信息
- 右侧焦点区域面板
- 点击区域后直接切换详情
- `总览 / 生态链 / 播报` 三个中文分页
- 前端内“重新读取世界数据”按钮
- `核心物种` 中文分页
- 自动刷新开关
- 世界播报浮层
- 区域档案卡
- 地图图例浮层
- 通道情报卡
- 核心物种中文名
- 区域定位卡
- 风险焦点徽记
- 主导生态链徽记
- 大陆与海域底图
- 区域航路线
- 徽章式区域节点
- 节点外圈高光与区域铭牌
- 读取 Python 导出的世界状态 JSON

当前它仍然不是最终游戏界面，但已经不是只能看一个固定焦点区的静态骨架。  
现在一次导出就会携带全区域详情，Godot 前端可以直接在本地切区，不需要每点一次都重新导出 JSON。  
同时，当前前端也开始具备：

- 区域概况卡
- 区域档案说明
- 区域定位标签
- 核心物种列表
- 风险焦点标签
- 主导生态链标签
- 地图底图分层
- 区域航线提示
- 顶部状态情报条
- 统一卡片式菜单容器
- 统一标题/正文/图例视觉层级
- 四个分页独立页首横幅
- 分页强调色与卡片装饰条
- HUD 浮层色带与标题条
- 底部系统栏色带
- 顶栏控制条与标题区分栏
- 弱网格与海流氛围层
- 图标化状态芯片
- 条带化属性面板
- 条带化生态链监测卡
- 图鉴分类标签与数量条
- 分类播报卡与主题色带
- 主主播报卡与区域播报分层
- 区域焦点徽记与图标分页按钮
- 焦点脉冲、侧栏淡入与切区重绘
- 分页淡入与横向滑入切换
- 区域节点悬停抬起与按下回弹
- 焦点区域强化与非焦点弱化
- 焦点区域强调色同步到右侧标题与页签
- 焦点区域强调色同步到分页横幅
- 焦点区域强调色同步到状态芯片与系统栏反馈
- 切区时顶部标题、侧栏与系统栏统一过场
- 焦点区域前推入场过渡
- 焦点区域相关航线加亮与加粗
- 图例与世界播报显示焦点区域提示
- 焦点区域经纬线与环境光带
- 分页横幅显示区域类型图标
- 图鉴页与播报页副标题按区域类型变化
- 图鉴条目与播报分类标题带区域类型徽记
- 总览页定位/档案/通道卡带区域类型前缀
- 风险焦点与主导生态链卡带区域类型前缀
- 页签悬停提亮与轻微放大
- 通用卡片悬停提亮与轻微放大
- 列表卡数值强化与连接说明弱化
- 手动刷新
- 定时自动刷新
- 世界播报摘要

## 导出命令

导出默认世界状态：

```bash
PYTHONPATH=. python3 scripts/export_world_state.py --pretty
```

导出并指定焦点区域：

```bash
PYTHONPATH=. python3 scripts/export_world_state.py --ticks 20 --active-region temperate_grassland --pretty
```

输出文件默认写到：

```text
godot/data/world_state.json
```

## 打开 Godot 工程

如果本机已安装 Godot：

1. 打开 `godot/project.godot`
2. 运行主场景：
   - `res://scenes/world_map.tscn`

如果本机还没安装 Godot，这一步暂时不能验证实际窗口，但工程骨架和数据导出链已经在仓库里了。

## 下一阶段

后面最合理的推进顺序是：

1. 把世界地图节点继续做成更像 JRPG 世界图标的徽章样式
2. 增加大陆轮廓、海域层次和区域图章
3. 把自动刷新升级成 socket/HTTP 实时桥接
4. 增加区域详情页、图鉴页和事件页

## 当前限制

- Godot 运行时本机还未检测到安装
- 当前是 JSON 导出式桥接，不是实时双向同步
- 目前没有接入正式美术资源，只是工程和界面骨架

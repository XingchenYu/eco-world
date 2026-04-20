# Godot 真实风格迁移方案

> 状态：保留为旧迁移说明。  
> 当前有效主线请看：[GODOT-REALISM-EXECUTION-PLAN.md](/Users/yumini/Projects/eco-world/docs/GODOT-REALISM-EXECUTION-PLAN.md)

本文档用于把当前 Godot 前端从“程序 primitive 拼场景”迁移到“资产化真实风格场景”。

这不是调参文档，而是换生产方式的方案。

## 1. 结论

当前 [`savanna_explorer_3d.gd`](/Users/yumini/Projects/eco-world/godot/scripts/savanna_explorer_3d.gd) 能继续承担这些职责：

- 读取 [`world_state.json`](/Users/yumini/Projects/eco-world/godot/data/world_state.json)
- 驱动区域切换、热点、任务、出口、事件
- 驱动玩家控制、相机、交互状态
- 驱动动物群体逻辑和生态行为状态

但它**不应该继续承担**这些职责：

- 生成最终可见地形
- 生成最终植被
- 生成最终动物外形
- 生成最终写实地表和环境细节

原因很直接：

- 现在的世界还是 `Box/Sphere/Cylinder/Capsule` 语言
- 这条路线只能做“更圆一点的积木”
- 它无法变成你要的“更真实的画风”

所以接下来要做的是：

1. 保留脚本层作为“运行时控制器”
2. 把可见世界逐层替换成资产化内容

## 2. 当前问题

当前前端的核心问题已经不是单点 bug，而是生产方式上限：

### 2.1 地形

- 地表主形态来自程序网格和程序 patch
- 大量路线、障碍、门段、围栏、崖体仍然是硬几何块
- 结果是整体读起来像 procedural blockout，而不是自然场景

### 2.2 植物

- 树、灌木、芦苇仍然是 primitive 组合
- 可以增加层次，但不会变成真实植物资产
- 结果是“数量能多，但画风还是假的”

### 2.3 动物

- 动物轮廓、腿部、头部注意力可以继续优化
- 但本质仍是程序低模拼件
- 结果是“能动”，但不会变成可信的生物

### 2.4 相机和运动

- 这部分还需要继续收 bug
- 但它属于运行时系统，不属于画风生产方式

## 3. 目标形态

迁移后的 Godot 前端应分成 4 层：

### A. Runtime 层

继续由 [`savanna_explorer_3d.gd`](/Users/yumini/Projects/eco-world/godot/scripts/savanna_explorer_3d.gd) 或后续拆分脚本负责：

- 世界状态读取
- 动态区域状态
- 相机
- 玩家控制
- 动物状态机
- 事件/任务/热点/出口逻辑

### B. Terrain 层

替换当前可见地面和大块障碍：

- 地形主网格
- 高度场/雕刻地形
- 地表材质混合
- 路面、泥地、草地、湿地、沙地、岩面

### C. Vegetation 层

替换当前程序树木和灌木：

- 树资产
- 灌木资产
- 芦苇/草层资产
- 散布规则和 instancing

### D. Fauna 层

替换当前程序动物：

- 低模或写实 stylized 动物模型
- 骨骼
- 动画循环
- 状态机驱动

## 4. 目录方案

Godot 资产目录按下面方式拆：

- [/Users/yumini/Projects/eco-world/godot/assets/terrain](/Users/yumini/Projects/eco-world/godot/assets/terrain)
- [/Users/yumini/Projects/eco-world/godot/assets/vegetation](/Users/yumini/Projects/eco-world/godot/assets/vegetation)
- [/Users/yumini/Projects/eco-world/godot/assets/fauna](/Users/yumini/Projects/eco-world/godot/assets/fauna)
- [/Users/yumini/Projects/eco-world/godot/assets/materials](/Users/yumini/Projects/eco-world/godot/assets/materials)
- [/Users/yumini/Projects/eco-world/godot/assets/props](/Users/yumini/Projects/eco-world/godot/assets/props)

运行时脚本不再直接“生成最终形状”，而是：

- 实例化场景
- 绑定状态
- 触发动画/材质切换/LOD/显隐

### 4.1 导入优先级

真实资产导入优先级固定为：

1. `.glb`
2. `.gltf`
3. `.tscn`

也就是说：

- `tscn` 现在只应该作为占位、过渡或包装场景
- 一旦同名 `glb/gltf` 落进对应目录，运行时应优先实例化真实资产文件

当前绑定层已经按这个优先级解析：

- `res://assets/terrain/<biome>/<biome>_terrain`
- `res://assets/vegetation/<biome>/<biome>_vegetation`
- `res://assets/fauna/<species>/<species>`

运行时会自动尝试：

- `*.glb`
- `*.gltf`
- `*.tscn`

## 5. 迁移顺序

迁移不能同时动所有层。顺序必须固定。

### Phase 1: 运行时底层收口

只收系统性问题：

- 玩家贴地
- 动物贴地
- 相机抖动
- 动物横滑
- 任务/热点/出口逻辑稳定

验收标准：

- 不穿模
- 不明显抖动
- 不横滑
- 逻辑稳定可跑

### Phase 2: 地形替换

目标：

- 把“盒子地面和盒子障碍”替换掉

做法：

- 引入真实 terrain mesh 或 heightfield
- 路径改成贴地 decal/mesh strip
- 崖体、土坡、湿地区、沙脊、浅滩改成资产块

脚本侧保留：

- 路径点
- 热点位置
- 出口位置
- 生态逻辑

脚本侧移除：

- 最终可见 terrain patch 生成
- 大部分 box obstacle 生成

### Phase 3: 植被替换

目标：

- 把“程序球冠/柱体树”换成资产化 vegetation

做法：

- 每个 biome 至少准备 3 组主植物资产
- 用 MultiMesh 或批量实例散布
- 树下底层、草层、湿地区细杆植物分层布置

### Phase 4: 动物替换

目标：

- 把“程序低模拼件动物”换成真实动物资产

优先级：

1. 草食群
2. 掠食群
3. 飞行动物
4. 水域动物

做法：

- 先做代表物种，不一次铺全
- 每类先出 1 到 2 个 hero species
- 先把轮廓、站姿、移动循环做对

### Phase 5: 统一美术语言

目标：

- 让 terrain / vegetation / fauna / props / lighting 成为一套语言

做法：

- 重做材质参数
- 重做光照
- 重做雾和大气
- 统一色调、粗糙度、阴影强度

## 6. 首批替换清单

第一批不要贪大，先替换最破坏观感的对象。

### 地形首批

- 草原地表
- 湿地浅水边
- 森林地面和土坡
- 海岸沙地和岩脊

### 植物首批

- 一种草原树
- 一种灌木
- 一种湿地芦苇
- 一种海岸棕榈
- 一种森林树

### 动物首批

- 斑马或羚羊
- 狮子或犬科
- 一种飞鸟

先把这几类做对，比继续给所有程序模型加零件更值。

## 7. 脚本拆分建议

当前 [`savanna_explorer_3d.gd`](/Users/yumini/Projects/eco-world/godot/scripts/savanna_explorer_3d.gd) 过大，后续必须拆。

建议至少拆成：

- `explorer_runtime.gd`
- `explorer_camera.gd`
- `explorer_ecology.gd`
- `explorer_ui.gd`
- `explorer_spawn.gd`
- `explorer_asset_binding.gd`

尤其是：

- “资产生成/绑定”
- “生态逻辑”
- “相机/玩家”

不能继续全塞在一个脚本里。

## 8. 当前脚本该保留什么

后续保留：

- `dynamic_region_state` 接入
- route stage / progress stage 逻辑
- 热点、任务、出口、事件
- 群体行为状态
- 相机和控制器

后续逐步废弃：

- `_add_tree()`
- `_add_shrub()`
- `_add_reed_cluster()`
- 大部分 `_box_mesh()` 可见场景生成
- 大部分 `_make_*_member()` 程序动物构造

## 9. 接下来 3 步

下一步开发顺序固定为：

1. 再开一轮运行态，只验证：
   - 贴地
   - 相机抖动
2. 开始拆资产目录和绑定层
3. 先做第一批地形/植被/动物替换，不再继续给 primitive 加细节

## 10. 判断标准

后面每一轮不再问“是不是又圆了一点”，而是问：

- 这轮有没有减少脚本生成的可见 primitive
- 这轮有没有增加可复用资产
- 这轮有没有让 runtime 更像控制器而不是建模器

只有这三条同时成立，项目才是真的往“更真实”走。

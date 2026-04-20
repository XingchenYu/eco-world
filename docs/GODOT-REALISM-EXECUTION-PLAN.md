# Godot 超级真实视觉执行方案

本文档是当前唯一有效的视觉主线。

目标非常明确：

- 地形要超级真实
- 环境要超级真实
- 植物要超级真实
- 动物要超级真实

这意味着后续不再走：

- 风格化冒险
- 卡通化收集
- 积木式占位
- 程序 primitive 外观修补

## 1. 结论

如果目标是“超级真实”，那当前工程里这些东西都只能当过渡或直接废弃：

- 程序地形
- 程序植被
- 程序动物外观
- 低模占位 `.tscn`

保留的只有运行时逻辑：

- 区域切换
- 任务/热点/出口
- 玩家控制
- 相机
- 动物行为状态

可见内容必须改成真实资产管线。

## 2. 当前必须停止的做法

从现在开始，下面这些事情不再继续投入：

- 给 primitive 世界继续补几何细节
- 给低模积木动物继续加小零件
- 在当前占位材质上继续磨“真实感”
- 在没换资产前继续讨论画风优化

原因很直接：

- 这些方法的上限太低
- 不可能到“超级真实”
- 只会继续返工

## 3. 超级真实需要的生产方式

### 3.1 地形

必须改成：

- 真实 terrain mesh 或 sculpted landscape
- PBR 地表材质
- 路面、泥地、草地、湿地、沙地、岩地分层
- 中景和远景统一轮廓

不能再用：

- box / sphere / cylinder 地貌
- 平板地表 + 贴片假起伏

### 3.2 植物

必须改成：

- 真实 vegetation assets
- trunk / branch / leaf / grass / reed 的真实模型
- instancing / scattering
- 近中远 LOD

不能再用：

- 程序树冠球
- 程序灌木块
- 程序芦苇柱

### 3.3 动物

必须改成：

- 真实动物模型
- 正确原点
- 正确骨骼
- 正确步态动画
- 正确 idle / turn / alert / chase 状态

不能再用：

- primitive 拼件动物
- runtime 拆节点重组
- 靠偏移猜脚底

### 3.4 光照和材质

必须改成：

- PBR 材质库
- 统一 roughness/normal/ao 规则
- 环境光、方向光、雾、后处理统一

不能再用：

- 单色材质块
- 只靠几何层次假装真实

## 4. 实施顺序

不能再全局一起动。顺序必须固定。

### Phase A: 资产管线固定

先固定真实资产导入规范：

- `.glb/.gltf`
- 命名
- 原点
- 朝向
- 材质
- 动画

### Phase B: 地形竖切片

先只做一个群系的真实地形：

- grassland

要求：

- 一整套真实 terrain
- 真实地表材质
- 真实中远景轮廓
- 不再有积木地貌

### Phase C: 植被竖切片

在同一群系上做：

- 草
- 灌木
- 树
- 边缘植物

### Phase D: 动物竖切片

先只做两种：

- 一个草食动物
- 一个掠食动物

要求：

- 脚底正确
- 步态正确
- 轮廓一眼可识别
- 不再积木感

### Phase E: 光照与镜头

最后统一：

- 相机稳定
- 地表阴影
- 植被层次
- 动物与环境融合

## 5. 当前工程里的保留和废弃

### 保留

- [/Users/yumini/Projects/eco-world/godot/scripts/savanna_explorer_3d.gd](/Users/yumini/Projects/eco-world/godot/scripts/savanna_explorer_3d.gd)
  继续当运行时控制器
- [/Users/yumini/Projects/eco-world/godot/scripts/explorer_asset_bindings.gd](/Users/yumini/Projects/eco-world/godot/scripts/explorer_asset_bindings.gd)
  继续当资产绑定层

### 废弃目标

后续逐步废弃：

- `res://assets/terrain/*/*.tscn` 里的占位地形外观
- `res://assets/vegetation/*/*.tscn` 里的占位植被外观
- `res://assets/fauna/*/*.tscn` 里的低模占位动物

这些可以暂时留着 fallback，但不再作为目标质量。

## 6. 第一优先级

从现在开始，优先级改成：

1. 真实地形资产
2. 真实植被资产
3. 真实动物资产
4. 再回头修 UI

原因：

- 现在最破坏观感的是世界本体
- UI 再精致，也救不了积木世界

## 7. 当前执行判断

当前工程还没有达到“超级真实”所需的真实资产库。

所以接下来必须做的是：

- 继续用绑定层接真实资产
- 停止给占位资产继续补画风
- 把第一批真实资产接进来并替换 fallback

## 8. 验收标准

以后不再用“比之前好一点”作为标准。

必须达到：

- 地形不再有积木感
- 植物不再有程序拼件感
- 动物不再有占位模型感
- 玩家、动物、环境在同一套光照和材质语言里

达不到这些，就不算完成。

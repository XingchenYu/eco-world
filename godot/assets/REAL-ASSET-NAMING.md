# Godot 真实资产导入约束

这份说明只针对 `res://assets/` 下的真实资产导入。

## 1. 优先级

运行时绑定层会按下面顺序查找可实例化场景：

1. `.glb`
2. `.gltf`
3. `.tscn`

所以：

- `.tscn` 只应作为占位资产或包装场景
- 真正的视觉替换应优先落 `.glb/.gltf`

## 2. 命名

### 地形

- `res://assets/terrain/grassland/grassland_terrain.glb`
- `res://assets/terrain/wetland/wetland_terrain.glb`
- `res://assets/terrain/forest/forest_terrain.glb`
- `res://assets/terrain/coast/coast_terrain.glb`

### 植被

- `res://assets/vegetation/grassland/grassland_vegetation.glb`
- `res://assets/vegetation/wetland/wetland_vegetation.glb`
- `res://assets/vegetation/forest/forest_vegetation.glb`
- `res://assets/vegetation/coast/coast_vegetation.glb`

### 动物

- `res://assets/fauna/antelope/antelope.glb`
- `res://assets/fauna/lion/lion.glb`
- `res://assets/fauna/african_elephant/african_elephant.glb`
- `res://assets/fauna/vulture/vulture.glb`
- `res://assets/fauna/giraffe/giraffe.glb`
- `res://assets/fauna/nile_crocodile/nile_crocodile.glb`
- `res://assets/fauna/canid/canid.glb`
- `res://assets/fauna/zebra/zebra.glb`

## 3. 原点和朝向

- root 必须是 `Node3D`
- 动物前向统一按 `+Z`
- 动物原点落在脚底或身体接地点附近
- 地形和植被原点落在区域世界原点附近，不要自带远距离偏移

## 3.1 动物运行时绑定节点

如果动物资产希望直接接当前 runtime 的注意力和步态，优先使用下面命名：

- `BodyRig`
- `HeadRig`
- `Leg_FrontLeft`
- `Leg_FrontRight`
- `Leg_BackLeft`
- `Leg_BackRight`

每条腿内部继续用：

- `Upper`
- `Knee`
- `Lower`
- `Hoof` 或 `Foot` 或 `Paw`

如果没有显式 `BodyRig/HeadRig`，当前 runtime 也会尝试按部件名自动归类，但那只是过渡方案，不应作为长期规范。

头部候选部件目前会优先识别这类名字：

- `Head`
- `Muzzle`
- `Beak`
- `Eye*`
- `Ear*`
- `Horn*`
- `Brow*`
- `Cheek*`
- `Face*`
- `Snout*`
- `ForeheadBridge`
- `Trunk*`
- `Neck`
- `NeckRuff`
- `Mane`
- `WingTip*`

## 4. 当前阶段

当前运行时已经能自动接管同名 `.glb/.gltf`。

接下来不该继续追加更多 primitive 占位外观，而应逐个把上面的 `.tscn` 占位替换成真实导入资产。

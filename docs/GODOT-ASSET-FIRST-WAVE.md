# Godot 第一批真实资产接入位

这份清单只定义**第一批替换目标**，不继续扩展程序 primitive。

## 第一批目标

### 地形
- 草原地形：
  - `res://assets/terrain/grassland/grassland_terrain.tscn`
- 湿地地形：
  - `res://assets/terrain/wetland/wetland_terrain.tscn`
- 森林地形：
  - `res://assets/terrain/forest/forest_terrain.tscn`
- 海岸地形：
  - `res://assets/terrain/coast/coast_terrain.tscn`

### 植被
- 草原植被：
  - `res://assets/vegetation/grassland/grassland_vegetation.tscn`
- 湿地植被：
  - `res://assets/vegetation/wetland/wetland_vegetation.tscn`
- 森林植被：
  - `res://assets/vegetation/forest/forest_vegetation.tscn`
- 海岸植被：
  - `res://assets/vegetation/coast/coast_vegetation.tscn`

### 动物
- 草食第一批：
  - `res://assets/fauna/antelope/antelope.tscn`
- 掠食第一批：
  - `res://assets/fauna/lion/lion.tscn`

## 运行时规则

- 如果同名 `.glb` 或 `.gltf` 存在，运行时优先实例化真实资产。
- 如果没有导入模型，再回退到同名 `.tscn`。
- 如果对应场景不存在，运行时自动回退到当前程序生成器。
- 资产替换不会改动：
  - 世界状态读取
  - 热点/出口/任务/事件逻辑
  - 玩家/相机/区域推进逻辑

## 场景约束

- 地形和植被场景：
  - root 必须是 `Node3D`
  - 局部原点应对齐区域世界原点
- 动物场景：
  - root 必须是 `Node3D`
  - 前向按当前运行时约定使用 `+Z`
  - 局部原点应落在脚底或身体接地点附近

## 文件命名约束

为了让绑定层能自动接管真实资产，命名必须固定：

- 地形：
  - `res://assets/terrain/<biome>/<biome>_terrain.glb`
  - 或 `res://assets/terrain/<biome>/<biome>_terrain.gltf`
- 植被：
  - `res://assets/vegetation/<biome>/<biome>_vegetation.glb`
  - 或 `res://assets/vegetation/<biome>/<biome>_vegetation.gltf`
- 动物：
  - `res://assets/fauna/<species>/<species>.glb`
  - 或 `res://assets/fauna/<species>/<species>.gltf`

只有在真实模型还没落地时，才继续使用同名 `.tscn` 占位。

## 当前目标

当前阶段不是做全量资产，而是先打通：
1. 一个真实地形入口
2. 一个真实植被入口
3. 一个草食动物入口
4. 一个掠食动物入口

后续所有视觉升级都应优先走这些入口，不再回到 `savanna_explorer_3d.gd` 里继续堆 primitive。

## 第二批已扩展入口

- 湿地地形：
  - `res://assets/terrain/wetland/wetland_terrain.tscn`
- 森林植被：
  - `res://assets/vegetation/forest/forest_vegetation.tscn`
- 大型草食动物：
  - `res://assets/fauna/african_elephant/african_elephant.tscn`
- 飞行动物：
  - `res://assets/fauna/vulture/vulture.tscn`

## 第三批已扩展入口

- 海岸地形：
  - `res://assets/terrain/coast/coast_terrain.tscn`
- 湿地植被：
  - `res://assets/vegetation/wetland/wetland_vegetation.tscn`
- 高体型草食动物：
  - `res://assets/fauna/giraffe/giraffe.tscn`
- 水域动物：
  - `res://assets/fauna/nile_crocodile/nile_crocodile.tscn`

## 第四批已扩展入口

- 森林地形：
  - `res://assets/terrain/forest/forest_terrain.tscn`
- 海岸植被：
  - `res://assets/vegetation/coast/coast_vegetation.tscn`
- 中型掠食者：
  - `res://assets/fauna/canid/canid.tscn`
- 中型群居草食动物：
  - `res://assets/fauna/zebra/zebra.tscn`

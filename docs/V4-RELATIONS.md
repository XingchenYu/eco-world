# V4 生态关系设计

## 1. 目标

把生态互动从“零散特例”升级成独立关系系统。

## 2. 六大关系模块

### 捕食

- 伏击
- 围猎
- 机会型捕食
- 幼体偏食
- 腐食
- 水边伏击
- 夜间捕食

### 竞争

- 食物竞争
- 巢位竞争
- 领地竞争
- 配偶竞争
- 生境竞争
- 植物光照和根系竞争

### 共生

- 授粉
- 种子传播
- 清洁共生
- 菌根
- 护卫共生
- 育幼场共生

### 寄生

- 蜱虫
- 跳蚤
- 寄生蜂
- 真菌病
- 水生寄生虫

### 工程师效应

- 河狸筑坝
- 白蚁丘
- 珊瑚造礁
- 大象开林
- 野猪翻土

### 演替

- 火后恢复
- 湿地扩张
- 草地灌丛化
- 森林更新
- 珊瑚退化和恢复

## 3. 局部级联变化

所有关键关系都应触发级联。

例：大象进入

- 树木减少
- 开阔地增加
- 灌丛结构改变
- 鸟类巢位变化
- 水坑出现
- 中小型动物分布改变

例：鳄鱼增加

- 饮水点风险热区上升
- 食草动物回避岸线
- 水边鸟类觅食位置变化
- 岸带捕食压力变化

## 4. 关系数据表

- `predation_links.json`
- `competition_links.json`
- `symbiosis_links.json`
- `parasitism_links.json`
- `engineering_links.json`
- `succession_rules.json`

## 5. 触发条件

每条关系都应可配置：

- 空间范围
- 时间段
- 季节
- 生命周期阶段
- 栖息地约束
- 密度阈值
- 资源阈值

## 6. 当前已落地的 v4 级联摘要

当前仓库已经有第一版区域级联摘要模块，用于把关键种的方向性影响汇总到世界统计里。

当前已接入的区域级联驱动包括：

- 湿地链
  - `beaver` -> `wetland_expansion` / `hydrology_retention`
  - `hippopotamus` -> `nutrient_input` / `shoreline_disturbance`
  - `nile_crocodile` -> `shoreline_risk`
- 草原大型植食者链
  - `african_elephant` -> `canopy_opening` / `seed_dispersal`
  - `white_rhino` -> `grazing_pressure` / `mud_wallow_disturbance`
  - `giraffe` -> `canopy_browsing`

这层的定位不是替代完整关系系统，而是先把“关键种会把区域往哪边推”显式接进 `WorldSimulation` 统计，为后续真正的区域级联事件和资源反馈层铺路。

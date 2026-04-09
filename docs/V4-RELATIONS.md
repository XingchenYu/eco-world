# V4 生态关系设计

## 1. 目标

把生态互动从“零散特例”升级成独立关系系统。

## 术语对照

- `predation`：捕食系统，处理谁吃谁、在哪里捕食、捕食压力多大。
- `competition`：竞争系统，处理食物、空间、巢位和配偶的争夺。
- `territory`：领地系统，处理核心区、边界、热点和空间冲突。
- `symbiosis`：共生系统，处理互利、偏利、清洁、授粉等关系。
- `parasitism`：寄生系统，处理寄生者、宿主和长期负担。
- `engineering effect`：工程师效应，指关键物种主动改变环境结构。
- `succession`：演替，指生态系统在长期中的恢复、扩张、退化和替换。
- `runtime signal`：运行期信号，指模拟当轮真实产生的热点、强度、体况等数据。
- `summary`：摘要层，指把复杂行为压缩成可统计、可反馈的结构化结果。
- `feedback`：反馈层，指把摘要结果重新写回区域状态。
- `rebalancing`：重平衡，指低频、轻量地调整物种池和资源压力。

## 2. 六大关系模块

### 捕食

- 伏击
- 围猎
- 机会型捕食
- 幼体偏食
- 腐食
- 水边伏击
- 夜间捕食

当前仓库已开始独立实现第一版捕食压力模块，见：
- [predation.py](/Users/yumini/Projects/eco-world/src/ecology/predation.py)
- 第一版重点覆盖湿地链与夜行链的分层捕食压力

### 竞争

- 食物竞争
- 巢位竞争
- 领地竞争
- 配偶竞争
- 生境竞争
- 植物光照和根系竞争

当前仓库已开始独立实现竞争模块，见：
- [competition.py](/Users/yumini/Projects/eco-world/src/ecology/competition.py)

### 领地与社群空间

- 狮群核心巡猎带
- 雄性接管前线
- 鬣狗 clan 洞穴与尸体通道
- 河马夜间上岸通道
- 鳄鱼晒背岸与伏击岸段
- 大型植食者围绕水源和泥浴位点的共享竞争

当前仓库已开始独立实现第一版领地压力模块，见：
- [territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)

### 共生

- 授粉
- 种子传播
- 清洁共生
- 菌根
- 护卫共生
- 育幼场共生

当前仓库已开始独立实现第一版共生/偏利模块，见：
- [symbiosis.py](/Users/yumini/Projects/eco-world/src/ecology/symbiosis.py)

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

这层的定位不是替代完整关系系统，而是先把“关键种会把区域往哪边推”显式接进 `WorldSimulation` 统计，并开始轻量反馈到区域的：

- `resource_state`
- `hazard_state`
- `health_state`

当前已经形成第一版“摘要 -> 状态反馈”闭环，为后续真正的区域级联事件、竞争挤压和资源再分配系统铺路。

当前还额外接入了第一版**关键种竞争反馈**：

- 湿地链
  - `hippopotamus -> nile_crocodile`
- 草原链
  - `african_elephant -> white_rhino`
  - `white_rhino -> african_elephant`
  - `african_elephant -> giraffe`

这层竞争反馈会以低频、轻量方式调整：

- 区域 `species_pool`
- 局部资源压力
- 局部风险压力

它的定位是第一版“区域级重平衡器”，用于表达关键种之间的长期资源挤压，而不是取代未来更完整的个体级竞争系统。

# EcoWorld 更新日志

本文档记录所有代码和文档的更新历史。

---

## 更新规范

### 代码更新流程
1. **修改代码前**：确认是否需要更新文档
2. **修改代码后**：立即更新相关文档
3. **提交代码时**：在CHANGELOG.md中记录变更

### 文档更新清单

| 文档 | 对应代码 | 更新触发条件 |
|-----|---------|-------------|
| SPECIES.md | entities/*.py | 新增/修改物种 |
| MECHANICS.md | core/*.py | 新增/修改机制 |
| competition-defense.md | entities/competition.py | 竞争/防御机制变更 |
| fruits-omnivores.md | entities/omnivores.py | 杂食动物变更 |
| ECOSYSTEM.md | 所有 | 总览更新 |
| USAGE.md | main.py | 启动参数变更 |

---

## 版本历史

### v4.0-alpha3 (2026-04-08 19:45)

**v4 架构推进**：
- ✅ `cascade.py` 已收缩为更明确的汇总层
- ✅ `cascade` 开始显式整合 `competition / symbiosis` 的结果
- ✅ `cascade` 统计新增 `source_modules`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已验证 `cascade` 聚合竞争与共生结果
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/cascade.py src/ecology/competition.py src/ecology/symbiosis.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v4.0-alpha2 (2026-04-08 19:25)

**v4 架构推进**：
- ✅ `Region` 已新增关系状态持久化字段：
  - `relationship_state`
  - `recent_adjustments`
  - `ecological_pressures`
- ✅ `WorldSimulation.update()` 已开始把 `cascade / competition / symbiosis` 结果持久写回区域对象

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增区域关系状态持久化测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/world/region.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v4.0-alpha (2026-04-08 19:00)

**v4 架构推进**：
- ✅ 新增 [src/ecology/symbiosis.py](/Users/yumini/Projects/eco-world/src/ecology/symbiosis.py)
- ✅ `WorldSimulation` 统计新增独立 `symbiosis` 区块
- ✅ 第一版共生/偏利反馈已开始轻量回灌区域状态

**覆盖关系**：
- ✅ `kingfisher_v4 -> shore_hatch`
- ✅ `bat_v4 -> night_swarm`
- ✅ `beaver -> reed_belt`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 共生摘要与共生反馈测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/symbiosis.py src/ecology/competition.py src/ecology/cascade.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.9 (2026-04-08 18:40)

**v4 架构推进**：
- ✅ 新增 [src/ecology/symbiosis.py](/Users/yumini/Projects/eco-world/src/ecology/symbiosis.py)
- ✅ `WorldSimulation` 统计新增独立 `symbiosis` 区块
- ✅ 第一版共生/偏利反馈已开始轻量回灌区域状态

**覆盖关系**：
- ✅ `kingfisher_v4 -> shore_hatch`
- ✅ `bat_v4 -> night_swarm`
- ✅ `beaver -> reed_belt`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 共生摘要与共生反馈测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/symbiosis.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.8 (2026-04-08 18:10)

**v4 架构推进**：
- ✅ 新增 [src/ecology/competition.py](/Users/yumini/Projects/eco-world/src/ecology/competition.py)
- ✅ 将关键种竞争摘要与竞争反馈从 `cascade.py` 中拆分为独立模块
- ✅ `WorldSimulation` 统计新增独立的 `competition` 区块

**覆盖关系**：
- ✅ `hippopotamus <-> nile_crocodile`
- ✅ `african_elephant <-> white_rhino`
- ✅ `african_elephant -> giraffe`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 竞争摘要测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/competition.py src/ecology/cascade.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.7 (2026-04-08 17:30)

**文档**：
- ✅ 新增 [docs/V4-IMPLEMENTATION-STEPS.md](/Users/yumini/Projects/eco-world/docs/V4-IMPLEMENTATION-STEPS.md)
- ✅ README 的 `v4` 文档导航新增实施步骤入口

**目标**：
- ✅ 将后续开发从“继续逐步讨论”推进成“按步骤实施”
- ✅ 固定后续 `v4` 的执行顺序，减少范围漂移和重复设计

### v3.6 (2026-04-08 16:40)

**v4 架构推进**：
- ✅ 新增 [src/ecology/cascade.py](/Users/yumini/Projects/eco-world/src/ecology/cascade.py)，引入第一版区域级联影响摘要
- ✅ `WorldSimulation` 统计新增 `cascade` 区块，开始汇总关键种如何推动区域结构变化
- ✅ 级联摘要已开始轻量反馈到区域 `resource_state / hazard_state / health_state`
- ✅ 第一版关键种竞争反馈已接入区域 `species_pool` 轻量重平衡
- ✅ 当前已接入湿地链与草原大型植食者链：
  - `beaver / hippopotamus / nile_crocodile`
  - `african_elephant / white_rhino / giraffe`

**文档更新**：
- ✅ 更新 [docs/V4-RELATIONS.md](/Users/yumini/Projects/eco-world/docs/V4-RELATIONS.md)，补充已落地的级联摘要实现状态

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 新增 `v4` 级联摘要测试并通过
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/ecology/cascade.py src/ecology/__init__.py src/sim/world_simulation.py tests/test_ecosystem.py`

### v3.5 (2026-04-07 16:20)

**设计文档**：
- ✅ 重写 README，明确区分当前 `v3.x` 原型与 `v4.0` 升级方向
- ✅ 新增 [V4-WORLD.md](/Users/yumini/Projects/eco-world/docs/V4-WORLD.md)
- ✅ 新增 [V4-SPECIES.md](/Users/yumini/Projects/eco-world/docs/V4-SPECIES.md)
- ✅ 新增 [V4-RELATIONS.md](/Users/yumini/Projects/eco-world/docs/V4-RELATIONS.md)
- ✅ 新增 [V4-ROADMAP.md](/Users/yumini/Projects/eco-world/docs/V4-ROADMAP.md)

**目标**：
- ✅ 将后续开发从“继续堆原型功能”转向“按 v4 总体架构实施”
- ✅ 提前锁定世界结构、物种模板、生态关系和路线图，减少后续大重构风险

### v3.4 (2026-04-07 15:10)

**性能与结构**：
- ✅ `Ecosystem` 新增 tick 级 actor 缓存
- ✅ 主循环中的 `_apply_population_pressure()` 与 `get_statistics()` / GUI 统计共用同一份 actor 结果
- ✅ 该优化不改变生态语义，只减少 `canopy_cover / bloom_abundance / wetland_support / nocturnal_insect_supply` 等 actor 的重复计算

**文档**：
- ✅ README、ARCHITECTURE、ECOSYSTEM、MECHANICS 已同步记录 actor 缓存层

**验证**：
- ✅ `tests/test_ecosystem.py`
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/core/ecosystem.py src/entities/animals.py src/entities/aquatic.py`

### v3.3 (2026-04-07 11:40)

**性能与结构**：
- ✅ 默认大地图性能继续优化到约 `1 tick ≈ 0.217s`、`5 tick ≈ 1.260s`
- ✅ 中低层水生移动分层，`small_fish / minnow / carp` 已切到更粗粒度区域趋向移动
- ✅ 低层水生漂移频率、植物邻域缓存、水生候选评分、动物局部缓存继续收口
- ✅ 动物繁殖率更新已接入物种数缓存与食性计数缓存，减少 herbivore / carnivore / omnivore 的全表扫描

**生态与机制**：
- ✅ 物种总数修正文档为 `67`：17 植物、35 陆地/鸟类/两栖、15 水生
- ✅ `frog` 湿地链已接入更强的成人湿地恢复和岸带羽化资源利用
- ✅ 夜间飞虫 `night_swarm`、树冠觅食 `canopy_forage`、岸带羽化 `shore_hatch` 已写入核心文档

**文档**：
- ✅ README 更新到 67 物种、最新微栖位列表和最新性能数据
- ✅ ARCHITECTURE、ECOSYSTEM、MECHANICS 更新到当前资源层与缓存结构
- ✅ CHANGELOG 补充 v3.3 记录

**验证**：
- ✅ `tests/test_ecosystem.py`
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/entities/animals.py src/core/ecosystem.py`
- ✅ 默认大地图性能基准

### v3.2 (2026-04-06 19:30)

**默认世界与性能**：
- ✅ 默认世界扩大到 `2560 x 1920`，运行格数 `128 x 96`
- ✅ 默认初始种群整体放大，并确保 66 个物种全部参与初始化
- ✅ 大地图默认配置下，`1 tick` 从约 `0.947s` 优化到约 `0.344s`
- ✅ 引入植物邻域缓存、动物局部查询缓存、水生两阶段选点、空间索引 offset 缓存
- ✅ 新增附近水生按物种快速计数，降低 `swim()` 和候选点评分成本

**生态与资源系统**：
- ✅ 物种总数更新为 66：17 植物、34 陆地/鸟类/两栖、15 水生
- ✅ 完整接入微栖息地资源层：
  - `canopy_roost`
  - `night_roost`
  - `shrub_shelter`
  - `nectar_patch`
  - `wetland_patch`
  - `riparian_perch`
- ✅ 微栖位已接入容量、可用量、占位、季节脉冲、逐 tick 恢复与繁殖约束
- ✅ 动物开始优先搜索可用微栖位，而不只是找植物

**GUI**：
- ✅ 高级界面支持中文 UI、字号放大、布局重排
- ✅ 新增微栖位 overlay，可用 `M` 开关
- ✅ 选中生物详情卡支持显示繁殖资源与局部可用度

**文档**：
- ✅ README、ARCHITECTURE、ECOSYSTEM、MECHANICS、SPECIES、USAGE、ADVANCED-GUI 已同步到当前实现

**验证**：
- ✅ `tests/test_ecosystem.py`
- ✅ `test_foodchain.py`
- ✅ 默认大地图性能基准

### v3.1 (2026-04-06 10:30)

**水域机制优化**：
- ✅ 新增 `minnow`，作为河道/浅湖独立的中层小型猎物来源
- ✅ 初始分布与自然迁入按 `river_channel` / `lake_shallow` / `lake_deep` 分流
- ✅ `catfish` / `pike` / `large_fish` / `blackfish` 优先转向捕食 `minnow`，降低对 `shrimp` 与湖区 `small_fish` 的集火
- ✅ `shrimp` 扩展可利用食物（藻类、浮游生物、水草、底栖碎屑），并增强浅湖/河道回补

**验证**：
- ✅ `tests/test_ecosystem.py` 新增 `minnow` 注册与 `shrimp` 栖息地来源测试
- ✅ 500 tick 抽样中 `shrimp` 与 `minnow` 可稳定共存

---

### v3.0 (2026-04-05 20:00)

**新增内容**：
- ✅ 果类植物 7种（苹果树、樱桃树、葡萄藤等）
- ✅ 杂食动物 8种（熊、野猪、獾、貉、臭鼬、负鼠、长鼻浣熊、犰狳）

**文档更新**：
- ✅ 创建 omnivores.py
- ✅ 更新 plants.py（新增果类植物）
- ✅ 更新 ecosystem.py（导入新物种）
- ✅ 创建 fruits-omnivores.md
- ✅ 更新 SPECIES.md（完整物种手册）
- ✅ 更新 MECHANICS.md（完整机制手册）
- ✅ 更新 ECOSYSTEM.md（总索引）
- ✅ 更新 config/test.yaml

**代码变更**：
```
src/entities/omnivores.py    [新建] 8种杂食动物
src/entities/plants.py       [修改] +7种果类植物
src/core/ecosystem.py        [修改] 导入新物种
config/test.yaml             [修改] 初始种群配置
```

---

### v2.0 (2026-04-05 19:30)

**新增内容**：
- ✅ 竞争机制（食物、领地、配偶、植物）
- ✅ 防御机制（逃跑、反击、伪装、群体、装甲等）
- ✅ 新天敌：黑鱼、狗鱼、狼、蜘蛛
- ✅ 新鸟类：喜鹊、乌鸦、啄木鸟、蜂鸟
- ✅ 新哺乳动物：松鼠、刺猬、蝙蝠、浣熊

**文档更新**：
- ✅ 创建 competition.py
- ✅ 创建 competition-defense.md
- ✅ 更新 animals.py（新物种）
- ✅ 更新 aquatic.py（黑鱼、狗鱼）

**代码变更**：
```
src/entities/competition.py  [新建] 竞争与防御机制
src/entities/animals.py      [修改] +8种新动物
src/entities/aquatic.py      [修改] +2种天敌鱼
```

---

### v1.5 (2026-04-05 17:10)

**核心改进**：
- ✅ 移除所有硬编码上限
- ✅ 添加食物因子机制
- ✅ 添加天敌压力机制

**文档更新**：
- ✅ 创建 foodchain-complete-fix.md
- ✅ 更新 aquatic.py（移除上限）
- ✅ 更新 animals.py（移除上限）

**代码变更**：
```
src/entities/aquatic.py      [修改] 移除硬编码上限，添加食物因子
src/entities/animals.py      [修改] 移除硬编码上限，添加食物因子
src/core/ecosystem.py        [修改] 导入新物种
```

---

### v1.0 (2026-04-04)

**初始版本**：
- ✅ 基础生态系统
- ✅ 陆地动物 + 水生生物
- ✅ 基础食物链
- ✅ 环境系统

**文档**：
- ✅ README.md
- ✅ ARCHITECTURE.md
- ✅ SPECIES.md（旧版）
- ✅ MECHANICS.md（旧版）
- ✅ USAGE.md

---

## 待更新检查清单

每次代码更新后，检查以下项目：

- [ ] SPECIES.md - 是否有新物种？
- [ ] MECHANICS.md - 是否有新机制？
- [ ] ECOSYSTEM.md - 总览是否需要更新？
- [ ] config/test.yaml - 初始种群是否需要调整？
- [ ] CHANGELOG.md - 是否记录变更？

---

## 文档维护责任人

- **主要负责人**：余星晨
- **更新原则**：代码变更 → 文档同步更新
- **检查频率**：每次提交前

---

*创建时间：2026-04-05 20:00*
# v3.4.8 - Recover squirrel through tick 200

- ✅ 使用默认 `config.yaml` 先跑 `5 seeds x 200 ticks` 基线，检查陆地哺乳动物 `deer / rabbit / fox / wolf / mouse / wild_boar / squirrel / bear`
- ✅ 基线 `tick 200` 存活数为：
  - `deer`: `36 / 28 / 32 / 42 / 40`
  - `rabbit`: `49 / 75 / 70 / 73 / 83`
  - `fox`: `26 / 23 / 37 / 31 / 17`
  - `wolf`: `30 / 26 / 30 / 29 / 31`
  - `mouse`: `33 / 23 / 29 / 42 / 24`
  - `wild_boar`: `25 / 22 / 19 / 24 / 38`
  - `squirrel`: `1 / 0 / 0 / 0 / 1`
  - `bear`: `253 / 235 / 277 / 256 / 259`
- ✅ 仅对 `squirrel` 做低密度保种修复：略微延长寿命、降低基础饥饿、缩短孕期，放宽 `canopy_roost / canopy_forage` 繁殖阈值；同时加入低密度产仔逻辑、适度提高自然迁入兜底，并给 `squirrel` 加上小型 prey reserve，避免末端种群被捕食链打穿
- ✅ 修复后再次执行同一组 `5 seeds x 200 ticks`，`tick 200` 存活数为：
  - `deer`: `35 / 33 / 32 / 30 / 49`
  - `rabbit`: `38 / 77 / 64 / 68 / 38`
  - `fox`: `13 / 26 / 28 / 26 / 25`
  - `wolf`: `21 / 30 / 20 / 24 / 23`
  - `mouse`: `26 / 32 / 33 / 32 / 25`
  - `wild_boar`: `34 / 15 / 17 / 24 / 37`
  - `squirrel`: `48 / 48 / 102 / 31 / 95`
  - `bear`: `242 / 275 / 296 / 266 / 226`
- ✅ 对比基线确认：本轮修复把 `squirrel` 从 `3 / 5` seed 灭绝、其余 seed 仅剩 `1` 只，恢复到 `5 / 5` seed 稳定存活；同时其余 7 个被检查的陆地哺乳动物在修复前后都保持 `tick 200` 非零
- ✅ 额外执行 `PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py`，现有基础生态测试全部通过

# v3.4.7 - Recover mouse through tick 200

- ✅ 先用默认 `config.yaml` 复核当前 HEAD 的 `5 seeds x 200 ticks`：`night_moth` 与 `rabbit` 已恢复到目标线之上，真正仍然 `0 / 5` 的仅剩 `mouse`
- ✅ 仅对 `mouse` 做低密度修复：提高 prey reserve（`8 -> 16`）、补上灌丛/菌丛躲藏与繁殖微栖位、缩短孕期，并改成更偏向“低密度保种”而不是“高密度扩张”的产仔公式
- ✅ 修复后再次执行 `5 seeds x 200 ticks`，`tick 200` 存活数分别为：
  - `night_moth`: `0 / 12 / 46 / 31 / 7`
  - `rabbit`: `49 / 75 / 70 / 73 / 83`
  - `mouse`: `33 / 23 / 29 / 42 / 24`
  - `fox`: `26 / 23 / 37 / 31 / 17`
  - `wolf`: `30 / 26 / 30 / 29 / 31`
  - `wild_boar`: `25 / 22 / 19 / 24 / 38`
- ✅ 按本轮目标判断：`night_moth` 达到 `4 / 5`、`rabbit` 达到 `5 / 5`、`mouse` 达到 `5 / 5`，且 `fox / wolf / wild_boar` 均自然保持非零

# v3.4.6 - Verify land mammals through tick 200

- ✅ 使用默认 `config.yaml` 执行 `5 seeds x 200 ticks` 回归，检查陆地哺乳动物 `deer / rabbit / fox / wolf / mouse / wild_boar / squirrel`
- ✅ `tick 200` 存活数分别为：
  - `deer`: `9 / 12 / 11 / 14 / 9`
  - `rabbit`: `0 / 0 / 0 / 0 / 0`
  - `fox`: `0 / 0 / 0 / 0 / 0`
  - `wolf`: `0 / 0 / 0 / 0 / 0`
  - `mouse`: `0 / 0 / 0 / 0 / 0`
  - `wild_boar`: `1 / 0 / 0 / 0 / 0`
  - `squirrel`: `0 / 1 / 0 / 1 / 0`
- ✅ 同组 `owl tick 200` 为 `7 / 18 / 17 / 3 / 17`，已满足全 seed 非零，因此本轮未对 `owl` 做额外改动

# v3.4.5 - Improve bat survival through tick 200

- ✅ 仅调整 `Bat` 自身续航参数，未改动 `night_moth`：略微延长寿命、降低基础饥饿消耗，并提高夜间微栖息地恢复与白天栖息回血收益
- ✅ 将 bat 的改动重点从“扩张”收回到“省着活”，去除对 `night_moth` 的额外追击加成，并下调夜间单次实猎成功上限，避免通过额外压榨猎物换存活
- ✅ 使用默认 `config.yaml` 执行 `5 seeds x 200 ticks` 回归；`bat` 在 `tick 200` 分别为 `6 / 5 / 4 / 11 / 3`，已达成全 seed 非零；同组 `night_moth tick 100-120` 最低值为 `80 / 38 / 65 / 76 / 73`

# v3.4.4 - Stabilize night_moth -> bat/owl through tick 120

- ✅ 仅调整 `night_moth -> bat/owl` 夜行链参数：增强 `night_moth` 的低密度恢复与保底存量，未改动任何水生参数
- ✅ 下调 `bat` / `owl` 对 `night_moth` 的夜间优先捕食强度，并补强 `bat` / `owl` 的低密度续航与回补条件
- ✅ 使用默认 `config.yaml` 执行 `5 seeds x 200 ticks` 回归；`tick 100-120` 区间内 `night_moth` 最低值分别为 `75 / 73 / 47 / 73 / 82`，不再出现接近清零的 seed

# v3.4.3 - Fix moth and minnow chain breaks

- ✅ `night_moth` 略微延长寿命并提升低密度繁殖恢复，缓解首代在约 22 tick 集中老化后导致的夜行链断层
- ✅ `bat` / `owl` 夜间优先捕食 `night_moth` 时，改为尊重 `get_predation_chance()` 的保底约束，不再绕过猎物保留量
- ✅ `minnow` 略微延长寿命并增强低密度补群参数，减少约 42 tick 首代老化叠加高位鱼压力造成的 prey 断层
- ✅ 针对 `night_moth -> bat/owl` 与 `minnow -> pike/catfish` 执行多 seed 200 tick 回归验证

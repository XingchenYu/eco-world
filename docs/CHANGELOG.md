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

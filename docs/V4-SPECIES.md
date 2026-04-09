# V4 物种系统设计

## 1. 目标

构建一个可以长期扩展的物种体系。重点不是先追求“所有地球物种”，而是先建立：

- 生态模板
- 真实物种映射
- 关系网络
- 区域分布规则

## 术语对照

- `template`：模板，指一类物种共享的生态位和行为骨架。
- `species variant`：物种变体，指基于模板的具体真实物种。
- `ecological role`：生态角色，指该物种在食物网和环境中的功能位置。
- `life stage`：生命周期阶段，如幼体、亚成体、成体。
- `diet profile`：食谱画像，指食物来源和食性结构。
- `microhabitat affinity`：微栖位偏好，指偏好的小尺度环境资源位点。
- `social profile`：社群画像，指群体、社交和协作方式。
- `territory profile`：领地画像，指核心区、边界和空间占用方式。
- `migration profile`：迁移画像，指跨区域移动或季节迁徙方式。
- `ecological flags`：生态标记，指关键种、工程师种、清道夫等特殊标签。

## 2. 双层设计

### 模板层

模板定义：

- 生态位
- 生命周期
- 行为逻辑
- 繁殖方式
- 社会结构
- 栖息地偏好
- 关系接口

### 真实物种层

真实物种定义：

- 中文名
- 学名
- 分布区
- 外观
- 特征修正
- 图鉴描述

## 3. 首批目标

首批建议：

- `120-160` 个真实物种
- 覆盖 6 个核心生态区
- 每个生态区都有完整链条
- 每个生态区都有关键种与共生组

## 4. 核心模板

- 大型草原群居食草兽
- 中型林地食草兽
- 小型啮齿食草兽
- 大型猫科顶级捕食者
- 中型犬科协作捕食者
- 中小型机会型杂食者
- 林冠果食鸟
- 林冠授粉鸟
- 夜行食虫飞行者
- 地面小型食虫鸟
- 猛禽
- 鸮类夜行猛禽
- 河岸捕鱼鸟
- 两栖湿地捕食者
- 河道中层鱼
- 河道伏击鱼
- 湖区底栖鱼
- 浅海群游鱼
- 礁区草食鱼
- 礁区清洁鱼
- 近海顶级掠食鱼
- 大型海洋巡游兽
- 分解者真菌
- 寄生与清洁共生者

## 5. 大型关键模板

- `MegaherbivoreEngineer`：大象
- `ArmoredMegaherbivore`：犀牛
- `HighBrowserCanopyHerbivore`：长颈鹿
- `SemiAquaticBulkGrazer`：河马
- `AquaticAmbushApexPredator`：鳄鱼

## 6. 首批关键种

- 大象
- 犀牛
- 长颈鹿
- 河马
- 鳄鱼
- 狼
- 狮
- 鬣狗
- 鹿
- 蜜蜂
- 蝙蝠
- 翠鸟
- 啄木鸟
- 河狸
- 水獭
- 狗鱼
- 鲶鱼
- 黑鱼
- 珊瑚虫
- 清洁鱼
- 红树林
- 海草

## 7. 每物种结构

- `species_id`
- `cn_name`
- `scientific_name`
- `template_id`
- `native_regions`
- `biomes`
- `life_stage_profiles`
- `diet_profile`
- `microhabitat_affinity`
- `social_profile`
- `territory_profile`
- `migration_profile`
- `ecological_flags`
- `encyclopedia_entry`

## 8. 扩展规则

后续新增物种必须：

- 归属模板
- 指定群系
- 指定关键关系
- 指定微栖位
- 指定图鉴信息

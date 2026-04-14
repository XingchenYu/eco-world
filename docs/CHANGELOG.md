# EcoWorld 更新日志

本文档记录所有代码和文档的更新历史。

### v4.0-alpha130 (2026-04-14 13:03)

- ✅ Godot 前端这轮把 `战区推进模式` 继续推进成了 `战略地图模式`。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 当前 campaign 的主战区覆盖层
  - 主走廊强化线
  - 二阶段分支覆盖层与阶段标记
  - 右侧总览中的 `战区图谱总板`
- ✅ 这意味着世界地图现在不只是切换不同 campaign，而开始把当前战区编成真正投回地图空间。

### v4.0-alpha129 (2026-04-14 12:49)

- ✅ Godot 前端这轮把 `前线行动方案` 继续推进成了 `战区推进模式`。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `frontier_campaigns`
  - 每条 campaign 的 `campaign_name / campaign_band`
  - 优先级、双跳路线标题和战区摘要
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 地图上沿 `战区推进模式` 条
  - 可切换的 campaign 卡
  - 切换 campaign 时自动同步前线目标与当前分支
  - 中心主舞台、前线转运带、右侧总览同步当前战区模式
- ✅ 这意味着世界地图现在不只是“锁一条前线”，而开始具备多套战区推进编成的切换能力。

### v4.0-alpha128 (2026-04-14 12:37)

- ✅ Godot 前端这轮不再只显示前线网络，而是把这层推进成了 `前线行动方案`。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `frontier_operations`
  - 每条前线的 `posture / threat_band / opportunity_band`
  - 双跳 `route_stages`
  - 行动摘要与战区标签
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 中心主舞台同步行动姿态、威胁带、机会带
  - 底部前线转运带里的 `前线行动阶段`
  - 右侧总览页里的 `前线行动总板`
- ✅ 这意味着世界地图现在不只是“锁定前线和分支”，而开始具备真正的前线战略推演层。

### v4.0-alpha127 (2026-04-14 12:20)

- ✅ Godot 前端这轮不是只在底部卡片里显示前线网络，而是把这层正式投回了地图空间。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 当前前线主走廊高亮线
  - 二级分支线
  - 前线目标空间徽记
  - 分支区域空间徽记
- ✅ 这意味着当前区域的前线网络现在不只是“读出来”，而开始真正变成世界地图上的战略图层。

### v4.0-alpha126 (2026-04-14 12:11)

- ✅ Godot 前端这轮不是继续停留在“单前线目标”，而是把前线走廊正式扩成了多层网络。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `frontier_network`
  - 每个前线目标下挂的二级网络分支
  - 分支总强度与分支数量
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 底部前线卡的分支摘要
  - 中心主舞台、副舞台、信息翼同步当前前线网络
  - 右侧总览页同步当前网络分支摘要
- ✅ 这意味着世界地图现在已经不只是“锁定一个邻区”，而开始具备从当前区域往外看一层网络结构的能力。

### v4.0-alpha125 (2026-04-14 11:58)

- ✅ Godot 前端这轮不是只在地图底部加一排邻区卡，而是把这层正式升级成了 `前线走廊切换层`。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 当前前线目标锁定
  - `锁定前线 / 进入区域` 双操作
  - 中心主舞台、副舞台、信息翼随当前前线目标切换摘要
  - 右侧总览页同步当前锁定的前线目标
- ✅ 这意味着世界地图现在不只是“从一个区域跳到另一个区域”，而开始具备前线预览、前线锁定和区域推进的走廊操作感。

### v4.0-alpha124 (2026-04-14 11:42)

- ✅ Godot 前端这轮不是再加一块装饰卡，而是把当前焦点区域的相邻区域真正做成了地图主视区里的 `前线转运带`。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `frontier_links`
  - 邻区名称、通道类型、强度、繁荣、风险、核心物种快照
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 地图底部前线转运带
  - 可点击的相邻区域快速切换卡
  - 右侧总览页的前线转运情报卡
- ✅ 这意味着世界地图现在不只是在“看一个区域”，而开始具备沿连接关系推进和切换焦点的前线操作感。

### v4.0-alpha123 (2026-04-13 06:18)

- ✅ Godot 前端这轮不再只是继续扩地图中心簇，而是让中心主视区开始跟右侧分页联动。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - `总览 / 生态链 / 物种 / 播报` 四种中心舞台内容配置
  - 分页对应的副舞台摘要
  - 分页对应的横向情报条
  - 分页对应的左右信息翼
- ✅ 这意味着切换右侧分页时，地图中心不再维持同一套内容，而开始真正成为随页面切换的主视区。

### v4.0-alpha122 (2026-04-13 06:16)

- ✅ Godot 前端这轮继续收主界面的整体语气，不再让中心舞台和右侧终端像两套各自成立的抬头系统。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 区域类型作战抬头配置
  - 中心主舞台共享抬头
  - 中心副舞台共享抬头
  - 右侧档案终端共享抬头
- ✅ 这意味着草原、湿地、海域、森林这几类区域现在开始通过整套抬头语气贯穿主界面，而不是只靠颜色与徽记区分。

### v4.0-alpha121 (2026-04-13 06:08)

- ✅ Godot 前端这轮不再只是继续扩地图中心簇，而是把中心舞台和右侧终端的抬头语气统一成了一套区域类型作战抬头。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 草原/湿地/海域/森林的专属作战抬头文案
  - 中心舞台主抬头
  - 副舞台抬头
  - 右侧档案终端抬头
- ✅ 这意味着当前焦点区域的“身份语气”不再只靠颜色和徽记区分，而开始通过整套抬头文案贯穿主界面。

### v4.0-alpha120 (2026-04-13 06:00)

- ✅ Godot 前端这轮继续扩地图中心区，不再让中央舞台只负责自己一块内容。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 左翼通道情报板
  - 右翼核心物种快照板
  - 地图中心主舞台 + 副舞台 + 双侧信息翼 的指挥簇结构
- ✅ 这意味着地图中心现在已经不只是组合舞台，而开始像一个完整的世界指挥簇。

### v4.0-alpha119 (2026-04-13 05:51)

- ✅ Godot 前端这轮继续做地图中心区，不再让中央只停留在一张标题牌。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 区域聚焦副舞台
  - 中央横向情报条
  - `主链 / 警报 / 繁荣 / 稳定 / 风险 / 种群` 的舞台级摘要
- ✅ 这意味着地图中心现在已经从“单张标题牌”推进成了真正的组合舞台。

### v4.0-alpha118 (2026-04-13 05:44)

- ✅ Godot 前端这轮不再只改地图上沿，而是把地图中心区也做成了“世界核心舞台”。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 地图中心舞台壳
  - 焦点区域中心标题牌
  - 中心主链/地貌/区域网络摘要
  - 中央舞台与地图节点共存的主视区结构
- ✅ 这意味着地图中间不再只是底图、航线和徽章，而开始像一个真正的世界主舞台。

### v4.0-alpha117 (2026-04-13 05:36)

- ✅ Godot 前端这轮不再让地图左上播报、右上图例和中部焦点提示各自漂浮，而是把它们收成了一套统一的世界战情层。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 左侧世界播报壳
  - 中部焦点战情条
  - 右侧图例壳
  - 左中右统一战情层布局
- ✅ 这意味着地图上沿不再像几个分散的浮层，而更像一整套完整的游戏战情 HUD。

### v4.0-alpha116 (2026-04-13 05:27)

- ✅ Godot 前端这轮不再只是继续改分页首屏，而是把右侧详情整体收成了一套“区域档案终端壳”。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 区域档案终端顶条
  - 终端式页签区
  - 页内终端脚注
  - `英雄头部 + 页签 + 当前分页内容` 的统一外壳
- ✅ 这意味着右侧现在不再像几段独立区块顺序堆叠，而开始更像一整块完整的游戏菜单终端。

### v4.0-alpha115 (2026-04-13 05:17)

- ✅ Godot 前端这轮继续按大步推进，不再只做页签和卡片微调，而是把四个分页首屏改成了“主卡 + 侧栏摘要”的页面结构。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - `总览` 页的战略摘要主卡
  - `生态链` 页的链路主监视窗
  - `物种` 页的领衔物种主卡
  - `播报` 页的主主播报卡
- ✅ 这意味着右侧分页现在不只是“第一页多了几个标签块”，而开始更像真正的游戏菜单首页。

### v4.0-alpha114 (2026-04-13 05:08)

- ✅ Godot 前端这轮不是继续做按钮和悬停，而是直接重构了右侧四个分页的主体结构。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - `总览` 页的区域总控板
  - `生态链` 页的链路监测总板
  - `物种` 页的核心图鉴索引
  - `播报` 页的播报总控板
- ✅ 这意味着四个分页不再只是“同一套卡片换内容”，而开始更像四种不同用途的游戏菜单页。

### v4.0-alpha113 (2026-04-13 04:49)

- ✅ Godot 前端这轮不再做局部微调，而是直接重做了右侧顶部结构。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域英雄头部
  - 区域徽章式头图
  - 头部内嵌状态条
  - 头部内嵌风险/主链/地貌标签
- ✅ 这意味着右侧详情页顶部不再是“标题 + 副标题 + 状态条”的松散堆叠，而开始更像一块完整的游戏主面板头图。

### v4.0-alpha112 (2026-04-13 04:36)

- ✅ Godot 前端继续把切区和切页的反馈力度拆开，不再让状态条在两种操作下表现得一样重。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 切页专用状态条轻强调
  - 切区与切页反馈分层
- ✅ 这意味着切换分页时，状态条依然会给出明确反馈，但力度会明显轻于切换区域，交互层次更合理。

### v4.0-alpha111 (2026-04-13 04:29)

- ✅ Godot 前端继续区分“切区”和“切页”的反馈力度，不再让两者都走同一套重过场。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 切页时状态条轻反馈
  - 切页时副标题轻过场
- ✅ 这意味着 `总览 / 生态链 / 物种 / 播报` 页签切换时，界面仍然会有明显反馈，但不会重到像切换区域那样的整套过场。

### v4.0-alpha110 (2026-04-13 04:22)

- ✅ Godot 前端继续补顶层状态条的切区反馈，不再只有标题区和系统栏会给出主色过场。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 切区时状态条短强调
  - 状态条轻微前推后回落
- ✅ 这意味着切换区域时，`繁荣 / 稳定 / 风险` 这组三芯片也会跟着做一次短反馈，而不是始终静止不动。

### v4.0-alpha109 (2026-04-13 04:15)

- ✅ Godot 前端继续补顶层状态条的节奏感，不再只是三块静态数字。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 顶部状态芯片短条带
  - 状态芯片数值强化
- ✅ 这意味着 `繁荣 / 稳定 / 风险` 这组三芯片现在更像有层次的状态读条，而不是一排静态文本。

### v4.0-alpha108 (2026-04-13 04:08)

- ✅ Godot 前端继续补右侧阅读层次，不再让标题、数值和说明处在同一阅读密度上。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 列表卡数值强化
  - 列表卡名称后退为次级标题
  - 区域连接说明弱化显示
- ✅ 这意味着 `生态链 / 连接 / 压力` 这类列表卡里，玩家会更容易先看到关键读数，再看名称和次级说明。

### v4.0-alpha107 (2026-04-13 03:59)

- ✅ Godot 前端继续补微交互，不再只有节点和页签有输入响应。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 通用卡片悬停提亮
  - 通用卡片轻微放大
- ✅ 这意味着总览、生态链、图鉴、播报里的卡片在鼠标经过时也会更像游戏菜单组件，而不是完全静态的说明块。

### v4.0-alpha106 (2026-04-13 03:52)

- ✅ Godot 前端继续补微交互，不再只有地图节点有明确输入响应。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 页签悬停提亮
  - 页签轻微放大
- ✅ 这意味着鼠标移到 `总览 / 生态链 / 物种 / 播报` 页签上时，也会有更像游戏菜单按钮的响应，而不是静态文字按钮。

### v4.0-alpha105 (2026-04-13 03:44)

- ✅ Godot 前端继续补总览页最后一批通用块，不再让 `风险焦点 / 主导生态链` 停留在旧样式。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - `风险焦点` 区域类型前缀
  - `主导生态链` 区域类型前缀
- ✅ 这意味着总览页里常看的关键卡片现在已经整体带上区域类型语气，不再出现一半有地区感、一半还是通用标题的情况。

### v4.0-alpha104 (2026-04-13 03:38)

- ✅ Godot 前端继续把区域类型语气往总览页下沉，不再只有图鉴和播报页能看出差异。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - `区域定位` 区域类型前缀
  - `区域档案` 区域类型前缀
  - `通道情报` 区域类型前缀
- ✅ 这意味着进入不同区域后，总览页最常看的核心卡片也会带上对应区域的徽记语气，而不是只有页首和页内少数组件变化。

### v4.0-alpha103 (2026-04-13 03:31)

- ✅ Godot 前端继续把区域类型感往页内组件下沉，不再只停留在页首图标和说明文案。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 图鉴条目区域类型徽记
  - 播报分类标题区域类型徽记
- ✅ 这意味着进入草原、湿地、海域等不同区域后，页内条目本身也会带着对应区域的语气，而不是只有横幅和副标题在变。

### v4.0-alpha102 (2026-04-13 03:22)

- ✅ Godot 前端继续补区域类型语气，不再只有页首图标会跟区域切换。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 图鉴页副标题按区域类型变化
  - 播报页副标题按区域类型变化
- ✅ 这意味着草原、湿地、海域这类不同区域里，`物种` 和 `播报` 页的页首说明也会更像对应区域自己的语气，而不是固定一句通用说明。

### v4.0-alpha101 (2026-04-13 03:15)

- ✅ Godot 前端继续补区域类型感，不再只靠颜色区分不同区域。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 分页横幅区域类型图标
- ✅ 这意味着同样是 `总览 / 生态链 / 物种 / 播报` 四页，在草原、湿地、海域等不同区域里，也会带着不同的图标语气进入页首。

### v4.0-alpha100 (2026-04-13 03:08)

- ✅ Godot 前端继续补地图活性层，不再只有节点、航线和面板会响应区域切换。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域经纬线
  - 焦点区域环境光带
- ✅ 这意味着切换区域后，地图背景本身也会给出主色提示，而不是只剩节点和路线在变化。

### v4.0-alpha99 (2026-04-13 03:02)

- ✅ Godot 前端继续补说明层联动，不再只有节点、航线和右侧菜单会响应区域切换。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 世界播报中的焦点区域提示
  - 图例中的焦点地貌提示
- ✅ 这意味着切换区域后，左上播报和右上图例也会明确告诉玩家“现在看的是什么区域、什么地貌类型”，而不是只显示固定说明。

### v4.0-alpha98 (2026-04-13 02:56)

- ✅ Godot 前端继续补地图连接层联动，不再只有节点本身会响应区域切换。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域相关航线加亮
  - 焦点区域相关航线加粗
  - 非焦点航线退后
- ✅ 这意味着切换区域时，不只是目标徽章会前推，和它相连的连接路线也会更明显地浮出来。

### v4.0-alpha97 (2026-04-13 02:49)

- ✅ Godot 前端继续补地图端的切区过场，不再只有标题和 HUD 在反馈。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域前推入场
  - 焦点区域从低位回到基准位置
  - 焦点区域从较小尺度恢复到正常尺寸
- ✅ 这意味着切换区域时，地图上的目标徽章会更像“被推进到前景”，而不是只在原地换一个高亮状态。

### v4.0-alpha96 (2026-04-13 02:42)

- ✅ Godot 前端继续把切区反馈收成统一过场，不再让标题、侧栏和系统栏各自单独闪动。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 顶部标题主色过场
  - 侧栏与系统栏统一过场入口
  - 切页时复用同一套区域主色反馈
- ✅ 这意味着切换区域后，地图焦点之外的顶部标题、右侧菜单和底部系统栏会一起给出短过场，更像一次完整的界面切换。

### v4.0-alpha95 (2026-04-13 02:34)

- ✅ Godot 前端继续补切区时的颜色反馈，不再只停留在标题和横幅。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域主色同步到顶部状态芯片
  - 焦点区域主色同步到系统栏闪动反馈
- ✅ 这意味着切换区域时，右侧状态条和底部系统栏会更明确地表现“当前已经进入这个区域”，而不是只有局部标题改色。

### v4.0-alpha94 (2026-04-13 02:27)

- ✅ Godot 前端继续补地图与右侧详情页的颜色联动，不再只停留在标题和页签。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域主色同步到分页横幅
  - 焦点区域主色同步到页首标题强调
- ✅ 这意味着切换区域时，右侧页首横幅也会跟着区域主色变化，而不是只改几个文字颜色。

### v4.0-alpha93 (2026-04-13 02:21)

- ✅ Godot 前端继续补地图与右侧菜单的联动，不再让左右两侧像两套独立界面。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域强调色同步到右侧标题
  - 焦点区域强调色同步到分页按钮选中态
- ✅ 这意味着玩家选中不同区域时，右侧标题和页签会跟着区域主色变化，左右两侧的视觉联系更强。

### v4.0-alpha92 (2026-04-13 02:15)

- ✅ Godot 前端继续补地图层级，不再让所有区域节点在同一视觉权重上抢注意力。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 焦点区域更强的阴影和光环
  - 非焦点区域的整体弱化
  - 非焦点徽章与铭牌降亮度
- ✅ 这意味着当前选中的区域会更自然地成为视觉中心，而其他区域退成背景参考，不再同时抢焦点。

### v4.0-alpha91 (2026-04-13 02:08)

- ✅ Godot 前端继续补地图节点输入反馈，不再只是点击后才有变化。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 区域节点悬停抬起
  - 节点按下压低
  - 离开时回弹复位
- ✅ 这意味着鼠标移动到区域徽章上时，地图节点会先给出更像游戏按钮的输入响应，而不是只有点击后才看到右侧面板变化。

### v4.0-alpha90 (2026-04-13 02:01)

- ✅ Godot 前端继续补分页切换感，不再只是瞬时替换右侧内容。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 分页淡入
  - 横向滑入
- ✅ 这意味着 `总览 / 生态链 / 物种 / 播报` 四页切换时，会更像游戏菜单翻页，而不是直接刷新一列控件。

### v4.0-alpha89 (2026-04-13 01:54)

- ✅ Godot 前端继续补交互反馈，不再只是“内容换了”，而是开始有更明确的动态感。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 切区后整张地图重绘
  - 焦点区域脉冲高亮
  - 侧栏淡入反馈
  - 系统栏闪动提示
- ✅ 这意味着切换区域时，地图上的焦点徽章会真的更新，而不是只看到右侧面板被替换。

### v4.0-alpha88 (2026-04-13 01:43)

- ✅ Godot 前端继续收口交互反馈，不再只是静态卡片切换。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 区域节点 `当前焦点 / 可进入` 状态徽记
  - 图标化分页按钮
  - 分页选中标记
  - 更明确的系统栏切换反馈
- ✅ 这意味着玩家切换区域和分页时，会更明显地知道“当前选中了什么”，而不是只看到右侧内容被替换。

### v4.0-alpha87 (2026-04-13 01:33)

- ✅ Godot 前端继续把 `播报` 页和左上 HUD 播报层拉开等级，而不是让所有播报都长成同一类卡片。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 主主播报卡
  - 动态简报区
  - `系统级播报 / 区域级播报` 分层提示
- ✅ 这意味着左上 HUD 会先强调最重要的世界级播报，而右侧 `播报` 页也会更明确地表达“这里只看当前区域的局部情报”。

### v4.0-alpha86 (2026-04-13 01:24)

- ✅ Godot 前端继续把 `播报` 页做成更像游戏内情报室，而不是统一项目符号列表。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 分类播报卡
  - 主题色带
  - 按生态主题拆分的播报标题
- ✅ 这意味着 `领地 / 社会相位 / 草原链 / 尸体资源链 / 湿地主链 / 捕食 / 共生` 这些叙事信息开始按主题分区显示，而不是混成一串文本。

### v4.0-alpha85 (2026-04-13 01:14)

- ✅ Godot 前端继续把物种图鉴页做成更像图鉴条目。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 物种分类标签
  - 数量条
- ✅ 这意味着物种页不再只是“名字 + 数量”，而开始更像真正的图鉴列表。

### v4.0-alpha84 (2026-04-13 01:05)

- ✅ Godot 前端继续把生态链分页做成更像监测面板。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在把生态链页中的：
  - 社会相位
  - 草原主链
  - 尸体资源链
  - 湿地主链
  - 领地/竞争/捕食压力
  都改成了带条带的监测卡。
- ✅ 这意味着生态链页不再只是数值列表，而开始和总览页保持同一层级的完成度。

### v4.0-alpha83 (2026-04-13 00:57)

- ✅ Godot 前端继续把右侧总览页做成更像属性面板。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 图标前缀
  - 数值标签
  - 条带化属性条
- ✅ 这意味着健康、资源、压力这些区块不再只是文字列表，而开始更像游戏属性页。

### v4.0-alpha82 (2026-04-13 00:49)

- ✅ Godot 前端继续把右侧状态块做得更直观。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在把：
  - 繁荣
  - 稳定
  - 风险
  改成了带图标前缀的状态芯片。
- ✅ 这意味着右侧总览不再只是数字块，而开始有更接近游戏状态栏的读法。

### v4.0-alpha81 (2026-04-13 00:42)

- ✅ Godot 前端继续补中央地图的氛围层。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 弱网格
  - 海流装饰线
- ✅ 这意味着中央地图不再只是底图和节点，而开始有“世界正在运转”的视觉感。

### v4.0-alpha80 (2026-04-13 00:34)

- ✅ Godot 前端继续收口顶栏控制区。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 顶栏色带
  - 标题区与控制区分栏
  - 更像菜单按钮的刷新入口
- ✅ 这意味着顶部标题和控制条不再像默认控件堆叠，而开始更像游戏界面顶栏。

### v4.0-alpha79 (2026-04-13 00:28)

- ✅ Godot 前端继续收口底部 HUD 层。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 底部系统栏色带
  - 更统一的状态栏前缀
- ✅ 这意味着地图左上播报、右上图例、右侧菜单、底部状态条现在开始更像同一套游戏 HUD。

### v4.0-alpha78 (2026-04-13 00:20)

- ✅ Godot 前端继续收口 HUD 浮层，让地图左上和右上不再像普通面板。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 世界播报色带
  - 图例色带
  - 浮层标题条
  - 播报卡片化显示
- ✅ 这意味着世界播报和地图图例已经开始有更像游戏 HUD 的气质，而不是单纯说明框。

### v4.0-alpha77 (2026-04-13 00:12)

- ✅ Godot 前端继续收口左侧地图节点质感。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 节点外圈高光
  - 焦点区域框带
  - 区域铭牌
- ✅ 这意味着地图节点现在不再只是信息块，而开始更像真正的区域徽章。

### v4.0-alpha76 (2026-04-13 00:03)

- ✅ Godot 前端继续收口分页材质感，不再只是统一排版。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 分页强调色
  - 页首横幅色带
  - 卡片装饰条
- ✅ `总览 / 生态链 / 物种 / 播报` 四页现在不只是文案不同，连视觉强调色也开始区分。

### v4.0-alpha75 (2026-04-12 23:53)

- ✅ Godot 前端继续拉开分页性格，不再只是同一套卡片换内容。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - `总览指挥台`
  - `生态链监测`
  - `物种图鉴`
  - `区域播报室`
  四个分页的独立页首横幅与说明文案。
- ✅ 这意味着切换分页时，玩家感知到的是不同功能菜单，而不是单纯换了一组列表。

### v4.0-alpha74 (2026-04-12 23:45)

- ✅ Godot 前端继续收口视觉层级，不再只是“组件摆对位置”。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增统一的：
  - 主标题样式
  - 次级标题样式
  - 正文样式
  - 弱化说明样式
- ✅ 地图图例也已从纯文本改成带色块的图例行。
- ✅ 这意味着当前 Godot 世界界面已经开始有统一的菜单视觉语气，而不是各区块各写各的文字样式。

### v4.0-alpha73 (2026-04-12 23:36)

- ✅ Godot 前端继续收口右侧详情层，使其更像游戏菜单而不是调试面板。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 顶部状态情报条
  - 统一卡片式菜单容器
  - 更明确的分页按钮尺寸
- ✅ 这意味着 Godot 世界界面现在不只是“地图更像地图”，右侧区域情报层也开始有统一的菜单结构。

### v4.0-alpha72 (2026-04-12 23:28)

- ✅ Godot 前端继续从“菜单卡片”推进到更像游戏世界入口的地图层。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 大陆与海域底图
  - 区域航路线
  - 徽章式区域节点
  - 更明确的焦点区域高亮
- ✅ 这意味着 Godot 世界界面已经不再只是平面节点分布，而开始具备真正的地图层与路线层。

### v4.0-alpha71 (2026-04-12 23:15)

- ✅ Godot 前端继续从“信息页”推进到更像游戏菜单的分层卡片结构。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `region_role`
  - `pressure_headlines`
  - `chain_focus`
- ✅ Godot 导出层的核心物种中文标签继续补齐，减少前端出现原始英文物种 ID。
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 区域定位卡
  - 风险焦点卡
  - 主导生态链卡
  - 更像菜单卡片的核心物种列表
- ✅ 这意味着 Godot 世界界面现在不再只是“地图 + 详情文字列”，而开始具备更明确的 JRPG 式区域情报层次。

### v4.0-alpha70 (2026-04-12 22:54)

- ✅ Godot 前端继续补强世界地图菜单层。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `map_legend`
  - `route_summary`
  - `top_species.label`
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 地图图例浮层
  - 区域通道情报卡
  - 核心物种中文名显示
- ✅ 这意味着 Godot 世界地图界面已经不再只是区域节点和侧栏，而开始有更接近游戏地图菜单的说明层。

### v4.0-alpha69 (2026-04-12 22:41)

- ✅ Godot 前端继续从“详情菜单”推进到“世界播报 + 区域档案”结构。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `region_intro`
  - `world_bulletin`
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - 地图左上角世界播报浮层
  - 右侧总览页中的区域档案卡
- ✅ 这意味着 Godot 路线已经开始有“世界入口菜单”的叙事层，而不只是数据列表和链路摘要。

### v4.0-alpha68 (2026-04-12 22:29)

- ✅ Godot 前端继续从“可切区骨架”推进到“更完整的区域详情结构”。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在新增：
  - `top_species`
  - `region_summary`
  - `ui_meta.refresh_mode`
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在新增：
  - `核心物种` 中文分页
  - 区域概况卡
  - 自动刷新开关
  - 更完整的竞争/捕食信息区
- ✅ 这意味着 Godot 路线已经不再只是地图 + 简单侧栏，而开始具备更接近游戏菜单的详情层。

### v4.0-alpha67 (2026-04-12 22:16)

- ✅ Godot 前端已从“单焦点静态骨架”推进到“可切区前端结构”。
- ✅ [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py) 现在会一次导出：
  - 全区域详情 `region_details`
  - 每个区域自己的健康、资源、压力、连接、生态链和叙事摘要
- ✅ [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd) 现在已支持：
  - 点击区域即时切换右侧详情
  - `总览 / 生态链 / 播报` 三个中文分页
  - 前端内“重新读取世界数据”按钮
- ✅ 这意味着 Godot 路线已经不再只是能读一个 JSON 的壳，而是开始具备真正前端交互结构。

### v4.0-alpha66 (2026-04-12 21:58)

- ✅ 项目已开始切换到 `Godot` 前端路线，不再继续把 `pygame` 当成长期主界面方案。
- ✅ 新增 Python -> Godot 数据桥：
  - [src/ui/world_payload.py](/Users/yumini/Projects/eco-world/src/ui/world_payload.py)
- ✅ 新增导出脚本：
  - [scripts/export_world_state.py](/Users/yumini/Projects/eco-world/scripts/export_world_state.py)
- ✅ 新增 Godot 工程骨架：
  - [godot/project.godot](/Users/yumini/Projects/eco-world/godot/project.godot)
  - [godot/scenes/world_map.tscn](/Users/yumini/Projects/eco-world/godot/scenes/world_map.tscn)
  - [godot/scripts/world_map.gd](/Users/yumini/Projects/eco-world/godot/scripts/world_map.gd)
- ✅ 新增中文文档：
  - [docs/GODOT-FRONTEND.md](/Users/yumini/Projects/eco-world/docs/GODOT-FRONTEND.md)
- ✅ 新增世界前端载荷测试：
  - `test_v4_world_ui_payload()`
- ✅ 当前 Godot 路线已经具备：
  - 世界状态导出
  - 世界地图前端骨架
  - 中文界面入口
  - 区域节点与右侧情报面板的数据来源

### v4.0-alpha65 (2026-04-12 18:42)

- ✅ [src/renderer/world_gui.py](/Users/yumini/Projects/eco-world/src/renderer/world_gui.py) 已从“后台式世界面板”重构为“世界地图式主界面”。
- ✅ 新世界 UI 现在已具备：
  - 中文主界面文案
  - 大地图主视区
  - 六大区域地图节点
  - 区域连线与焦点高亮
  - 鼠标点击切换区域
  - 更游戏化的情报侧栏与状态条
- ✅ 视觉语言已从“调试看板”改为更偏策略冒险游戏的世界入口，不再只是堆叠键值对。

### v4.0-alpha64 (2026-04-12 18:10)

- ✅ 新增第一版 `v4` 世界 UI：
  - [src/renderer/world_gui.py](/Users/yumini/Projects/eco-world/src/renderer/world_gui.py)
- ✅ [src/main.py](/Users/yumini/Projects/eco-world/src/main.py) 现在支持：
  - `--world-ui`
  - `--world-ui --headless`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 新增世界层 UI 入口所需接口：
  - `list_region_ids()`
  - `cycle_active_region()`
  - `get_world_overview()`
- ✅ 第一版世界 UI 已可直接显示：
  - 六大区域卡片
  - 当前焦点区域
  - 健康、资源、压力面板
  - `social / grassland / carrion / wetland` 主链摘要
- ✅ 新增世界层稳定测试：
  - `test_v4_world_overview_summary()`
  - `test_v4_world_region_cycle()`
- ✅ 这意味着项目已经不再只有后端主线，开始有第一版真正可看的 `v4` 世界入口。

### v4.0-alpha63 (2026-04-12 17:20)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现在已把：
  - `birth_cycle_window_pressure_memory_pull`
  继续落到：
  - 区域反馈
  - 低频重平衡
- ✅ 对应新增 support：
  - `birth_cycle_window_pressure_memory_herd_support`
  - `birth_cycle_window_pressure_memory_apex_support`
  - `birth_cycle_window_pressure_memory_aerial_support`
  - `birth_cycle_window_pressure_memory_apex_carrion_support`
- ✅ 这条慢反馈主线现在已经进一步推进成：
  - `pressure memory -> chain summaries -> feedback/rebalancing -> next social memory`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现在也会把新加入的：
  - `birth_cycle_window_pressure_memory_herd_support`
  - `birth_cycle_window_pressure_memory_apex_support`
  - `birth_cycle_window_pressure_memory_aerial_support`
  - `birth_cycle_window_pressure_memory_apex_carrion_support`
  一起统计进 `birth_cycle_window_pressure_support_count`
- ✅ 这意味着 `pressure memory` 现在不只会作用一轮，还会继续沉淀回：
  - `birth_cycle_window_pressure_memory`
- ✅ `birth_cycle_window_pressure_memory` 现在也会继续进入：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现在也会把：
  - `birth_cycle_window_pressure_memory`
  直接回灌到区域：
  - `surface_water`
  - `carcass_availability`
  - `resilience`
- ✅ [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py) 与 [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 现在已把：
  - `birth_cycle_window_pressure_bias`
  正式接入产仔路径：
  - `litter_size`
  - `mate_cooldown`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现在会把产仔事件里超出基础值的：
  - `impact`
  继续计入：
  - `herd_birth_runtime`
  - `aerial_birth_runtime`
  - `apex_birth_runtime`
- ✅ 这意味着 `birth_cycle_window_pressure_bias` 现在不只影响“产多少”和“多久恢复”，还会继续抬升世界层看到的运行期产仔强度。
- ✅ [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 现在会把：
  - `birth_cycle_window_pressure_memory`
  继续抬升到：
  - `apex_birth_memory_world_pressure_bias`
  - `herd_birth_memory_world_pressure_bias`
  - `aerial_birth_memory_world_pressure_bias`

### v4.0-alpha62 (2026-04-12 16:55)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现在会继续读取：
  - `birth_cycle_window_pressure_memory`
- ✅ 两条草原主链已新增：
  - `birth_cycle_window_pressure_memory_pull`
- ✅ 这层新 pull 现在已经继续进入：
  - 草原链与尸体资源链摘要
  - 世界级长期压力
  - 区域反馈
  - 低频重平衡
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现在会把这层新 pull 纳入：
  - `prosperity_pressure`
  - `collapse_pressure`
  - `runtime_resource_pressure`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐世界层社群趋势测试夹具：
  - `birth_cycle_window_pressure_herd_support`
  - `birth_cycle_window_pressure_apex_support`
  - `birth_cycle_window_pressure_aerial_support`
  - `birth_cycle_window_pressure_apex_carrion_support`
- ✅ 这条慢反馈主线现在已经进一步推进成：
  - `pressure support -> pressure memory -> chain summaries -> feedback/rebalancing -> world pressures`

### v4.0-alpha61 (2026-04-12 16:20)

- ✅ 新增 `birth_cycle_window_pressure_bias` 主线闭环：
  - [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 现在会把：
    - `birth_cycle_window_memory_strength`
    - `world_pressure_bias`
    - `world_pressure_window_bias`
    - `runtime_anchor_prosperity`
    - 区域 `stability / collapse_risk`
    组合成运行体偏置 `birth_cycle_window_pressure_bias`
- ✅ 这层新偏置已经下沉到：
  - [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py)
    - `antelope / zebra / vulture`
  - [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py)
    - `lion / hyena`
- ✅ `birth_cycle_window_pressure_bias` 现在会直接影响运行体：
  - `health`
  - `hunger`
  - `mate_cooldown`
  - `reproduction_rate`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现在会继续聚合：
  - `herd_birth_cycle_window_pressure_runtime`
  - `aerial_birth_cycle_window_pressure_runtime`
  - `apex_birth_cycle_window_pressure_runtime`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现在会把这组新 runtime 信号继续写回：
  - `runtime_signals`
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现在会把这组新 runtime 压力继续沉淀到：
  - `birth_cycle_window_memory_strength`
  - `cycle_signals`
- ✅ 这条慢反馈主线现在已经补成：
  - `birth_cycle window -> memory strength -> pressure bias -> runtime territory -> social memory`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现在也已继续接入：
  - `runtime_herd_birth_cycle_window_pressure_pull`
  - `runtime_aerial_birth_cycle_window_pressure_pull`
  - `runtime_apex_birth_cycle_window_pressure_pull`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现在会把这组新 pull 与对应 `territory.runtime_signals` 继续纳入：
  - `prosperity_pressure`
  - `collapse_pressure`
  - `runtime_resource_pressure`
- ✅ 这条慢反馈主线现在已经继续推进成：
  - `birth_cycle window -> memory strength -> pressure bias -> runtime territory -> chain summaries -> world pressures`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现在也已继续把这组新 pressure pull 落到：
  - 区域反馈
  - 低频重平衡
- ✅ 对应新增 support：
  - `birth_cycle_window_pressure_herd_support`
  - `birth_cycle_window_pressure_aerial_support`
  - `birth_cycle_window_pressure_apex_support`
  - `birth_cycle_window_pressure_apex_carrion_support`
- ✅ 这条慢反馈主线现在已经进一步闭成：
  - `birth_cycle window -> memory strength -> pressure bias -> runtime territory -> chain flows -> feedback + rebalancing -> next world pressures`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现在也会把新加入的：
  - `birth_cycle_window_pressure_herd_support`
  - `birth_cycle_window_pressure_aerial_support`
  - `birth_cycle_window_pressure_apex_support`
  - `birth_cycle_window_pressure_apex_carrion_support`
  一起统计进 `birth_cycle_window_count`
- ✅ 这意味着 `birth_cycle window pressure` 已不只作用于当前轮反馈，还会继续沉淀成：
  - `birth_cycle_window_memory`
  - `birth_cycle_window_memory_strength`
- ✅ 现在还进一步拆出了独立长期信号：
  - `birth_cycle_window_pressure_memory`
- ✅ [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 与 [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现在会继续读取这层新记忆，并把它回灌到：
  - `birth_cycle_window_pressure_bias`
  - `apex/herd/aerial_birth_cycle_window_runtime`
- ✅ 这条慢反馈主线现在已经进一步推进成：
  - `pressure support -> pressure memory -> runtime pressure bias -> next runtime territory`

### v4.0-alpha60 (2026-04-12 15:35)

- ✅ [scripts/graph_checks.py](/Users/yumini/Projects/eco-world/scripts/graph_checks.py) 现已继续收紧 `code-review-graph` 的检查范围：
  - `src/ecology/social.py`
  - `src/ecology/territory.py`
  这两类生态枢纽文件现在支持 diff-aware 归类，不再一改就默认带出 `world + runtime + grassland`
- ✅ 具体规则是：
  - 改 `build_region_social_trend_summary(...)` 或 `apply_region_social_trend_feedback(...)` 时，优先只建议 `world`
  - 改 `build_region_territory_summary(...)` 时，优先建议 `world`
  - 改 `apply_region_territory_feedback(...)` 时，优先建议 `grassland`
- ✅ 这轮优化的目标不是缩短单条测试输出，而是减少“本来不该跑的测试文件”：
  - 典型收益场景是后续继续改 `social.py / territory.py` 的主线迭代
  - 这样可以少跑 `runtime`，也能减少无关输出占用的 token

### v4.0-alpha59 (2026-04-12 13:40)

- ✅ 新增 `birth_cycle_bias` 主线闭环：
  - `RegionSimulation` 会把多周期繁殖节律注入：
    - `lion / hyena / antelope / zebra / vulture`
  - 运行体现在新增：
    - `birth_cycle_bias`：产仔周期偏置，指“慢反馈繁殖记忆”下沉到个体后的直接繁殖节律倾向
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现在会聚合：
  - `herd_birth_cycle_runtime`
  - `aerial_birth_cycle_runtime`
  - `apex_birth_cycle_runtime`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现在会把这组 runtime 信号写回：
  - `runtime_signals`
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现在会把这组新信号继续沉淀成：
  - `apex_birth_cycle_memory`
  - `herd_birth_cycle_memory`
  - `aerial_birth_cycle_memory`
  - 对应 `cycle_signals`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已新增：
  - `runtime_herd_birth_cycle_pull`
  - `runtime_aerial_birth_cycle_pull`
  - `runtime_apex_birth_cycle_pull`
- ✅ 这组新 pull 现在已经进入：
  - 摘要
  - 区域反馈
  - 低频重平衡
  - 世界级长期压力
- ✅ 对应新增 support：
  - `birth_cycle_herd_support`
  - `birth_cycle_aerial_support`
  - `birth_cycle_apex_support`
  - `birth_cycle_apex_carrion_support`
- ✅ `birth_cycle` 现在也正式进入重平衡窗口层：
  - `birth_cycle_herd_window`：繁殖周期偏置足够高时，直接打开 herd 恢复窗口
  - `birth_cycle_apex_window`：繁殖周期偏置足够高时，直接打开 apex 恢复窗口
  - `birth_cycle_aerial_window`：繁殖周期偏置足够高时，直接打开空中清道夫恢复窗口
  - `birth_cycle_apex_carrion_window`：繁殖周期偏置足够高时，直接打开尸体资源链里的顶层恢复窗口
- ✅ `birth_cycle window` 现在也已进入长期层：
  - `social_trends` 会把窗口效果沉淀成 `birth_cycle_window_memory`
  - `RegionSimulation` 会用这层记忆继续抬升运行体 `birth_cycle_bias`
  - `WorldSimulation` 会把这层记忆直接接入长期 `prosperity / collapse` 压力
- ✅ `birth_cycle window memory` 现在也已重新汇总成运行期 territory 信号：
  - `herd_birth_cycle_window_runtime`
  - `aerial_birth_cycle_window_runtime`
  - `apex_birth_cycle_window_runtime`
  - 这组信号会继续进入 `territory` 与 `social_trends.cycle_signals`
- ✅ `birth_cycle_window_memory_strength` 现在也已直接进入：
  - `grassland_chain / carrion_chain` 摘要
  - 也就是“繁殖窗口真实生效强度”不再只停留在 `social/world`，而开始成为两条草原链自己的直接输入
- ✅ 这组 `birth_cycle_window_memory_strength_pull` 现在也已继续进入：
  - `grassland / carrion` 区域反馈
  - `grassland / carrion` 低频重平衡
  - 也就是“繁殖窗口真实生效强度”不再只影响摘要和世界压力，而开始直接影响 herd / aerial / apex 的恢复支持
- ✅ 这组 `birth_cycle_window_runtime` 现已继续进入：
  - `grassland_chain / carrion_chain` 摘要
  - 世界级 `prosperity / collapse / runtime_resource_pressure`
  - 这样多周期繁殖窗口已经不只影响社群记忆，也开始直接抬升区域链路压力
- ✅ [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py) 的普通物种 `_give_birth(...)` 现在也正式接入：
  - `birth_cycle_bias`：产仔周期偏置，指“多周期繁殖记忆”下沉到个体后的直接产仔节律倾向
- ✅ 这意味着 `antelope / zebra / vulture` 的普通产仔路径现在也会直接受 `birth_cycle_bias` 影响：
  - `litter_size`：每胎数量
  - `mate_cooldown`：产后冷却
- ✅ 对应新增物种级产仔缩放测试：
  - `test_antelope_birth_cycle_scaling()`
  - `test_vulture_birth_cycle_scaling()`
  - `test_lion_birth_cycle_scaling()`
  - `test_hyena_birth_cycle_scaling()`
- ✅ `SPECIES_TESTS` 入口已同步挂载，不再出现“测试函数已写但 species 组没跑到”的漏检
- ✅ 测试已补齐：
  - `runtime`：新增 herd/aerial/apex 的 `birth_cycle_bias` 运行期体况测试
  - `world`：新增 `birth_cycle` world pressure 回路断言
  - `grassland`：新增 `birth_cycle pull` 摘要与反馈断言

### v4.0-alpha55 (2026-04-12 11:10)

- ✅ 新增独立测试文件入口：
  - [tests/test_basic.py](/Users/yumini/Projects/eco-world/tests/test_basic.py)
  - [tests/test_world.py](/Users/yumini/Projects/eco-world/tests/test_world.py)
  - [tests/test_wetland.py](/Users/yumini/Projects/eco-world/tests/test_wetland.py)
  - [tests/test_grassland.py](/Users/yumini/Projects/eco-world/tests/test_grassland.py)
  - [tests/test_runtime.py](/Users/yumini/Projects/eco-world/tests/test_runtime.py)
  - [tests/test_species.py](/Users/yumini/Projects/eco-world/tests/test_species.py)
- ✅ [scripts/graph_checks.py](/Users/yumini/Projects/eco-world/scripts/graph_checks.py) 现在会优先输出独立测试文件命令，而不是只输出 `tests/test_ecosystem.py <group>`
- ✅ 这使 graph 从“选测试组”进一步推进到“直选测试文件”，后续：
  - 命令更短
  - 输出更少
  - 无关测试组更不容易被顺手跑到
- ✅ [scripts/graph_checks.py](/Users/yumini/Projects/eco-world/scripts/graph_checks.py) 现已继续支持 `sim` 层的 diff-aware 归类：
  - [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 的运行期注入改动不再默认顺手带出 `world + grassland`
  - 现在会尽量收窄成真正需要的 `runtime` 或 `world`

### v4.0-alpha56 (2026-04-12 11:55)

- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已把运行中的 `birth_memory_bias` 聚合成：
  - `herd_birth_memory_runtime`
  - `aerial_birth_memory_runtime`
  - `apex_birth_memory_runtime`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现在会把这组更慢的繁殖记忆信号写入 `runtime_signals`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现在会把这组信号继续沉淀到：
  - `herd_birth_memory`
  - `aerial_birth_memory`
  - `apex_birth_memory`
  - 以及对应 `cycle_signals`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已新增：
  - `runtime_herd_birth_memory_pull`
  - `runtime_aerial_birth_memory_pull`
  - `runtime_apex_birth_memory_pull`
- ✅ 这使草原主线从“近期产仔事件”继续推进到“近期产仔记忆偏置”的慢反馈闭环

### v4.0-alpha54 (2026-04-12 10:45)

- ✅ [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 现已把 `social_trends.trend_scores` 里的：
  - `herd_birth_memory`
  - `aerial_birth_memory`
  - `apex_birth_memory`
  回灌到运行中的：
  - `antelope / zebra / vulture`
  - `lion / hyena`
- ✅ [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py) 和 [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 现已新增 `birth_memory_bias`，并把它接入：
  - 当前体况
  - 繁殖冷却
  - 繁殖节律
  - 产仔规模
- ✅ 这使草原主线里的“近期产仔 -> 社群记忆 -> 下一轮运行体繁殖偏置”形成更直接闭环

### v4.0-alpha53 (2026-04-12 10:20)

- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已把运行期产仔事件聚合成：
  - `herd_birth_runtime`
  - `aerial_birth_runtime`
  - `apex_birth_runtime`
- ✅ 这些新的 runtime 产仔信号现已继续接入：
  - [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)
  - [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py)
  - [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py)
  - [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)
  - 世界级长期压力聚合
- ✅ 这使草原主线里“产仔与群体延续”的 runtime 信号，不再只停留在个体繁殖层，而开始继续影响：
  - grassland/carrion 摘要
  - 区域反馈
  - 低频重平衡
  - 长期 `prosperity / collapse` 判定

### v4.0-alpha52 (2026-04-11 10:35)

- ✅ [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py) 的通用产仔路径 `_give_birth(...)` 现已把：
  - `condition_runtime`：运行期真实体况
  - `condition_phase_bias`：长期体况相位偏置
  - `regional_health_anchor`：区域健康锚点
  - `world_pressure_bias`：世界级长期压力偏置
  - `world_pressure_window_bias`：世界级窗口偏置
  一并接入 herd / aerial 物种的产仔规模与产后冷却
- ✅ 这意味着世界级长期压力和区域健康度现在已经不只继续影响：
  - `lion / hyena`
  也开始继续影响：
  - `antelope / zebra / vulture`
  的群体延续节律
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增并通过：
  - `test_antelope_world_pressure_birth_scaling()`
  - `test_vulture_world_pressure_window_birth_scaling()`

### v4.0-alpha51 (2026-04-11 09:40)

- ✅ [scripts/graph_checks.py](/Users/yumini/Projects/eco-world/scripts/graph_checks.py) 现已新增三档 graph-guided 检查方案：
  - `smoke`
  - `targeted`
  - `full`
- ✅ [docs/CODE-REVIEW-GRAPH-CHECKS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-CHECKS.md) 已补充三档方案的中文解释，后续不需要每次再人工判断“到底该跑多重”

### v4.0-alpha50 (2026-04-11 09:20)

- ✅ [scripts/graph_checks.py](/Users/yumini/Projects/eco-world/scripts/graph_checks.py) 现已支持更细的 graph-guided 检查策略：
  - 文档改动直接建议跳过代码检查
  - [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 改动会尽量按受影响测试函数推断测试组
  - 不再默认“一改测试文件就强制 `all`”
- ✅ [docs/CODE-REVIEW-GRAPH-CHECKS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-CHECKS.md) 已同步补充这套更细粒度的说明

### v4.0-alpha49 (2026-04-10 15:20)

- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 现已把：
  - `world_pressure_bias`
  - `world_pressure_window_bias`
  正式接入统一的社群化产仔路径 `_social_group_birth(...)`
- ✅ 这意味着世界级长期压力现在已经不只影响：
  - 运行期体况
  - 低频恢复窗口
  - 长期相位与世界压力
  还会继续直接影响：
  - `lion / hyena` 的产仔规模
  - 产后冷却
  - 社群延续节律
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增并通过：
  - `test_lion_world_pressure_birth_scaling()`
  - `test_lion_world_pressure_window_birth_scaling()`
  - `test_hyena_world_pressure_birth_scaling()`
  - `test_hyena_world_pressure_window_birth_scaling()`

### v4.0-alpha48 (2026-04-10 15:00)

- ✅ 新增 [scripts/graph_checks.py](/Users/yumini/Projects/eco-world/scripts/graph_checks.py)，可根据当前改动文件直接输出：
  - 建议编译文件
  - 建议测试组
  - 是否需要补 `all` 全量回归
- ✅ [docs/CODE-REVIEW-GRAPH-CHECKS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-CHECKS.md) 已新增脚本说明与命令示例
- ✅ [docs/USAGE.md](/Users/yumini/Projects/eco-world/docs/USAGE.md) 已从旧的单一全量测试说明，更新为分组测试 + graph-guided 检查入口

### v4.0-alpha47 (2026-04-10 14:35)

- ✅ 新增 [docs/CODE-REVIEW-GRAPH-CHECKS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-CHECKS.md)，补齐：
  - `graph-guided checks` 的中文说明
  - 按影响面选择编译和测试的规则
  - 当前仓库的选择性测试组与命令示例
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 现已支持按组运行：
  - `basic`
  - `world`
  - `wetland`
  - `grassland`
  - `runtime`
  - `species`
  - `all`
- ✅ [README.md](/Users/yumini/Projects/eco-world/README.md) 与 [docs/CODE-REVIEW-GRAPH.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH.md) 已新增检查与测试规则入口

### v4.0-alpha46 (2026-04-10 14:10)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已把：
  - `runtime_herd_world_pressure_window_pull`
  - `runtime_apex_world_pressure_window_pull`
  正式接进：
  - 草原链区域反馈
  - 草原链低频重平衡
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已把：
  - `runtime_aerial_world_pressure_window_pull`
  - `runtime_apex_world_pressure_window_pull`
  正式接进：
  - 尸体资源链区域反馈
  - 尸体资源链低频重平衡
- ✅ 这使 `world_pressure_window_runtime` 不再只是摘要层和世界级压力输入，而开始真正改变：
  - `surface_water`
  - `carcass_availability`
  - `predation_pressure`
  - herd / aerial / apex 的物种池恢复节律

### v4.0-alpha43 (2026-04-10 13:20)

- ✅ 新增 [/.mcp.json](/Users/yumini/Projects/eco-world/.mcp.json)，为仓库补上 `code-review-graph` 的项目级 MCP 接入骨架
- ✅ 新增 [/.code-review-graphignore](/Users/yumini/Projects/eco-world/.code-review-graphignore)，排除缓存、资源图、临时目录和低价值历史文档
- ✅ 新增 [docs/CODE-REVIEW-GRAPH.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH.md)，提供完整中文接入说明、术语解释和本仓库推荐评审范围
- ✅ [README.md](/Users/yumini/Projects/eco-world/README.md) 已新增 `Code Review Graph` 入口和中文说明

### v4.0-alpha44 (2026-04-10 13:35)

- ✅ 新增 [docs/CODE-REVIEW-GRAPH-WORKFLOWS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-WORKFLOWS.md)，补齐：
  - 当前项目 graph 的中文说明
  - 主图谱与草原长期闭环的 Mermaid 图
  - `code-review-graph` 在本仓库里的 review 工作流
  - 哪些文件是当前 graph 的枢纽、热点和高风险模块
- ✅ [README.md](/Users/yumini/Projects/eco-world/README.md) 和 [docs/CODE-REVIEW-GRAPH.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH.md) 已新增工作流文档入口

### v4.0-alpha45 (2026-04-10 13:50)

- ✅ 新增 [docs/CODE-REVIEW-GRAPH-MAINTENANCE.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-MAINTENANCE.md)，明确规定：
  - 哪些变化算 graph 结构变化
  - 什么情况下必须更新 graph 文档
  - 每次更新时要检查哪些内容
  - 这个项目后续最容易触发 graph 漂移的核心模块
- ✅ [README.md](/Users/yumini/Projects/eco-world/README.md) 和 [docs/CODE-REVIEW-GRAPH.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH.md) 已新增维护规则入口

### v4.0-alpha40 (2026-04-10 12:10)

- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 现已把：
  - `condition_phase_bias`
  - `regional_health_anchor`
  继续接入 `Lion / Hyena` 的社群化产仔路径
- ✅ 这层现在会直接影响：
  - 产仔规模
  - 产后冷却
  - 社群延续节律
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增：
  - `test_lion_condition_phase_birth_scaling()`
  - `test_hyena_condition_phase_birth_scaling()`
  并已通过全量回归

### v4.0-alpha41 (2026-04-10 12:35)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已把 `runtime_apex_condition_phase_*` 继续接入低频恢复窗口：
  - `condition_phase_pride_window`
  - `condition_phase_clan_window`
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已把 `runtime_aerial_condition_phase_* / runtime_apex_condition_phase_*` 继续接入低频恢复窗口：
  - `condition_phase_aerial_window`
  - `condition_phase_apex_carrion_window`
- ✅ 这使长期相位体况偏置现在已经同时影响：
  - 个体运行期体况
  - 社群产仔规模与产后冷却
  - 草原与尸体资源链的低频恢复机会
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐对应断言并通过全量回归

### v4.0-alpha42 (2026-04-10 12:50)

- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已把 `condition_phase_window_memory` 直接接入：
  - `prosperity_pressure`
  - `collapse_pressure`
  - `runtime_resource_pressure`
- ✅ 这使长期相位体况窗口现在已经不只影响：
  - `social_trends`
  - `grassland / carrion` 重平衡
  还会继续直接影响区域长期 `prosperity / collapse_risk / stability`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐区域压力断言并通过

### v4.0-alpha39 (2026-04-10 11:35)

- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已新增：
  - `herd_condition_anchor_runtime`
  - `aerial_condition_anchor_runtime`
  - `apex_condition_anchor_runtime`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现已开始把这三类 runtime 条件锚点写入 `runtime_signals`，并继续影响：
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现已开始读取这些新的 runtime 条件锚点，并继续进入：
  - herd / aerial 周期
  - `grassland_boom_phase / grassland_prosperity_phase`
  - `cycle_signals`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已开始读取：
  - `runtime_herd_condition_anchor_pull`
  - `runtime_aerial_condition_anchor_pull`
  - `runtime_apex_condition_anchor_pull`
  并把它们继续接入：
  - 摘要
  - 区域反馈
  - 低频重平衡
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已把这些 `condition_anchor_pull` 继续接入：
  - `prosperity_pressure`
  - `collapse_pressure`
  - `runtime_resource_pressure`
  使 runtime 条件锚点开始直接参与区域长期健康判定
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 现已把：
  - `herd_condition_anchor_runtime`
  - `aerial_condition_anchor_runtime`
  - `apex_condition_anchor_runtime`
  继续接入：
  - `grassland_prosperity_phase`
  - `grassland_collapse_phase`
  使真实体况锚点开始直接参与长期繁荣/衰退相位
- ✅ [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 现已把：
  - `grassland_prosperity_phase`
  - `grassland_collapse_phase`
  直接融入运行体 `condition_runtime` 注入值，使 herd / apex / aerial 的真实体况开始带长期相位偏置
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐 `condition_anchor_runtime` 断言并通过

### v4.0-alpha35 (2026-04-09 08:40)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已把区域级 `prosperity / collapse` 相位推进到“稳定态切换”：
  - 新增：
    - `prosperity_feedback_bias`
    - `collapse_feedback_bias`
  - `prosperity / collapse` 现在会直接改变草原链的：
    - 摘要权重
    - 反馈系数
    - `herd / predator / scavenger / social` 层偏置
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已把区域级 `prosperity / collapse` 相位推进到尸体资源链的稳定态切换：
  - 新增：
    - `prosperity_feedback_bias`
    - `collapse_feedback_bias`
  - `prosperity / collapse` 现在会直接改变尸体资源链的：
    - 摘要权重
    - 反馈系数
    - `herd_source / kill / scavenge / aerial_scavenge` 层偏置
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐对应反馈测试并通过

### v4.0-alpha36 (2026-04-09 08:55)

- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已根据 `prosperity / collapse` 显式切换 `grassland_chain.dominant_layer`
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已根据 `prosperity / collapse` 显式切换 `carrion_chain.dominant_layer`
- ✅ 草原链和尸体资源链的反馈系数现在会继续读取 `dominant_layer`，使 `herd / kill / scavenge / aerial` 等层在不同长期相位下真正成为主导层
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `dominant_layer` 断言并通过

### v4.0-alpha37 (2026-04-09 09:10)

- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现已开始读取上一周期的 `grassland_chain / carrion_chain dominant_layer`
- ✅ 主导层现在会反向生成新的领地与通道偏置信号：
  - `herd_channel_bias`
  - `apex_hotspot_bias`
  - `scavenger_hotspot_bias`
  - `herd_source_bias`
  - `kill_corridor_bias`
  - `aerial_lane_bias`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已开始吸收这些偏置信号，形成下一轮资源布局输入
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增领地主导层测试并通过

### v4.0-alpha38 (2026-04-09 09:25)

- ✅ [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 现已把 `territory` 生成的布局偏置信号回灌到运行体
- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 中：
  - `Lion` 现已读取：
    - `apex_hotspot_bias`
    - `kill_corridor_bias`
  - `Hyena` 现已读取：
    - `scavenger_hotspot_bias`
    - `kill_corridor_bias`
- ✅ [src/entities/animals.py](/Users/yumini/Projects/eco-world/src/entities/animals.py) 中：
  - `Antelope / Zebra` 现已读取 herd 通道偏置
  - `Vulture` 现已读取空中通道与 kill corridor 偏置
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已补齐运行体偏置信号注入测试并通过

### v4.0-alpha27 (2026-04-09 05:00)

- ✅ `social_trends.hotspot_scores` 现已开始回灌到 [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 的运行体
- ✅ `Lion / Hyena` 现已新增：
  - `hotspot_memory`
  - `shared_hotspot_memory`
- ✅ `Lion / Hyena` 的 `pride_center / clan_center` 现已由热点记忆驱动，开始表现为带粘滞的中心漂移，而不是每次动作都瞬间跳点
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 与 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已开始吸收 `social_hotspot` 信号
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点记忆注入与中心漂移测试并通过

### v4.0-alpha28 (2026-04-09 05:20)

- ✅ `social_trends.hotspot_scores` 现已开始进入 [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 的草原链摘要与反馈
- ✅ `social_trends.hotspot_scores` 现已开始进入 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 的尸体资源链摘要与反馈
- ✅ 草原链新增：
  - `hotspot_cycle_pressure`
  - `hotspot_cycle_overlap`
- ✅ 尸体资源链新增：
  - `hotspot_cycle_carrion`
  - `hotspot_cycle_tracking`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点生命周期摘要/反馈断言并通过

### v4.0-alpha31 (2026-04-09 06:05)

- ✅ `social_trends.cycle_signals` 现已新增：
  - `apex_hotspot_wave`
  - `shared_hotspot_churn`
- ✅ [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py) 现已让热点周期波动直接拉动草食群振幅：
  - `hotspot_cycle_predator_wave`
  - `hotspot_cycle_overlap_drag`
- ✅ [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py) 现已让热点周期波动直接拉动清道夫振幅：
  - `hotspot_cycle_scavenger_wave`
  - `hotspot_cycle_churn`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点周期振幅断言并通过

### v4.0-alpha24 (2026-04-09 03:55)

- ✅ `social_trends.phase_scores` 现已开始回灌到 [src/sim/region_simulation.py](/Users/yumini/Projects/eco-world/src/sim/region_simulation.py) 的运行体
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 在区域更新前会先注入当前社群周期状态
- ✅ `Lion / Hyena` 新增周期相位行为影响：
  - 扩张期会轻量改善健康、缓解饥饿、缩短交配冷却、提升繁殖节奏
  - 收缩期会轻量增加饥饿、拖慢繁殖节奏并施加体况压力
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增区域社群周期注入测试和个体级周期行为测试

### v4.0-alpha25 (2026-04-09 04:20)

- ✅ `social cycle` 现已继续影响 `lion / hyena` 的核心区建立与前线推进强度
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 的运行态汇总新增：
  - `lion_cycle_expansion`
  - `lion_cycle_contraction`
  - `hyena_cycle_expansion`
  - `hyena_cycle_contraction`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 已开始把周期相位纳入领地压力计算
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增周期驱动的核心区效果测试

### v4.0-alpha26 (2026-04-09 04:40)

- ✅ 草原热点现已具备基础持续、衰减与迁移记忆
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 已新增：
  - `lion_hotspot_persistence`
  - `hyena_hotspot_persistence`
  - `shared_hotspot_persistence`
  - `lion_hotspot_shift`
  - `hyena_hotspot_shift`
  - `shared_hotspot_shift`
- ✅ [src/ecology/social.py](/Users/yumini/Projects/eco-world/src/ecology/social.py) 已新增 `hotspot_scores`
- ✅ 热点记忆现已开始回灌区域 `resilience / territorial_conflict`

### v4.0-alpha14 (2026-04-08 23:40)

- ✅ `Lion / Hyena` 现已新增轻量核心区中心：
  - `pride_center`
  - `clan_center`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已汇总：
  - `lion_hotspot_count`
  - `hyena_hotspot_count`
  - `shared_hotspot_overlap`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 开始把热点数量和热点重叠纳入领地压力计算
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增热点相关断言并通过

### v4.0-alpha15 (2026-04-08 23:55)

- ✅ `territory` 的热点信号现已反向接入：
  - [src/ecology/grassland.py](/Users/yumini/Projects/eco-world/src/ecology/grassland.py)
  - [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)
- ✅ 草原链新增：
  - `hotspot_overlap_pressure`
  - `territory_channel_pressure`
  - `carcass_channeling`
- ✅ 尸体资源链新增：
  - `kill_corridor_overlap`
  - `scavenger_lane_pressure`
- ✅ 草原热点重叠现在会继续影响：
  - 草原资源通道
  - 尸体资源通道
  - `carcass_availability`
  - `predation_pressure`

### v4.0-alpha16 (2026-04-09 00:10)

- ✅ `grassland_rebalancing` 现已开始吸收 `territory` 的空间群体格局输入
- ✅ `carrion_rebalancing` 现已开始吸收 `territory` 的空间群体格局输入
- ✅ 热点数量和热点重叠现在不只影响摘要和状态反馈，也会影响：
  - `lion`
  - `hyena`
  - `vulture`
  的低频物种池重平衡
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `territory -> rebalancing` 断言并通过

### v4.0-alpha17 (2026-04-09 00:25)

- ✅ `Lion` 现已新增轻量社群稳定度：
  - `pride_stability`
- ✅ `Hyena` 现已新增轻量社群稳定度：
  - `clan_stability`
- ✅ 这层稳定度现在会开始轻量影响：
  - `health`
  - `hunger`
  - `mate_cooldown`
  - `reproduction_rate`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `lion / hyena` 社群稳定度测试并通过

### v4.0-alpha18 (2026-04-09 00:40)

- ✅ `Lion / Hyena` 的社群稳定度现在开始影响：
  - `litter outcomes`
  - `postpartum cooldown`
- ✅ `Lion` 现已支持：
  - `stable pride support`
  - `pride instability`
  两类社群产仔结果记录
- ✅ `Hyena` 现已支持：
  - `stable clan support`
  - `clan instability`
  两类社群产仔结果记录
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `lion / hyena` 社群产仔缩放测试并通过

### v4.0-alpha19 (2026-04-09 00:55)

- ✅ `pride_stability / clan_stability` 现在开始进入：
  - `grassland_rebalancing`
  - `carrion_rebalancing`
- ✅ `territory.runtime_signals` 中的：
  - `lion_pride_strength`
  - `lion_pride_count`
  - `hyena_clan_cohesion`
  - `hyena_clan_count`
  现在会驱动：
  - `stable_pride_recovery`
  - `stable_clan_recovery`
  - `stable_pride_carcass_recovery`
  - `stable_clan_carrion_recovery`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `social_state` 低频重平衡断言并通过

### v4.0-alpha20 (2026-04-09 01:10)

- ✅ `social_state` 现在不仅会触发低频恢复，还会在条件满足时打开：
  - `pride_expansion_window`
  - `clan_expansion_window`
  - `pride_carrion_expansion_window`
  - `clan_carrion_expansion_window`
- ✅ 这些扩张窗口同时要求：
  - 高稳定度
  - 足够的 group 数量
  - 可扩张的热点布局
  - 充足的草食群或尸体资源
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增扩张窗口断言并通过

### v4.0-alpha21 (2026-04-09 01:25)

- ✅ `grassland_rebalancing / carrion_rebalancing` 现在在低谷条件下支持：
  - `pride_recolonization_window`
  - `clan_recolonization_window`
  - `pride_carrion_recolonization_window`
  - `clan_carrion_recolonization_window`
- ✅ 这些重占窗口要求：
  - 低数量状态
  - 高稳定度
  - 仍然存在的热点区
  - 足够的草食群或尸体资源
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增草原链和尸体资源链的重占窗口测试并通过

### v4.0-alpha22 (2026-04-09 01:40)

- ✅ 新增独立的 `social_trends` 层：
  - 读取 `territory.runtime_signals`
  - 读取上一轮 `social_trends`
  - 形成：
    - `lion_recovery_bias`
    - `lion_decline_bias`
    - `hyena_recovery_bias`
    - `hyena_decline_bias`
- ✅ `WorldSimulation` 现在会：
  - 构建 `social_trends`
  - 将其写回区域 `relationship_state`
  - 并将其接入：
    - `grassland_rebalancing`
    - `carrion_rebalancing`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `social_trends` 摘要与趋势驱动重平衡断言并通过

### v4.0-alpha23 (2026-04-09 01:55)

- ✅ `social_trends` 现在新增：
  - `phase_scores`
  - `cycle_signals`
- ✅ 系统现在开始显式区分：
  - `lion_expansion_phase / lion_contraction_phase`
  - `hyena_expansion_phase / hyena_contraction_phase`
- ✅ `grassland_rebalancing / carrion_rebalancing` 现在已开始读取：
  - `social_cycle`
  作为独立来源，而不只读取 `social_trend`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `phase_scores` 和 `social_cycle` 断言并通过

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

## v4.0-alpha4 (2026-04-08 20:35)

- ✅ 草原区新增 `carcass_availability` 资源维度，用于表达狮鬣狗围绕尸体与击杀点的竞争压力
- ✅ [src/ecology/competition.py](/Users/yumini/Projects/eco-world/src/ecology/competition.py) 现已独立表达：
  - `carcass_site_competition`
  - `kill_site_competition`
  - `scavenger_pushback`
  - `herd_route_interference`
- ✅ 草原竞争反馈现已轻量回灌：
  - `hyena`
  - `lion`
  - `carcass_availability`
  - `predation_pressure`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增狮鬣狗尸体资源竞争断言并通过

### v4.0-alpha5 (2026-04-08 20:55)

- ✅ 新增 [src/ecology/carrion.py](/Users/yumini/Projects/eco-world/src/ecology/carrion.py)，把草原尸体资源链从竞争摘要中拆成独立模块
- ✅ `WorldSimulation` 统计新增：
  - `carrion_chain`
  - `carrion_rebalancing`
- ✅ `carrion_chain` 现已显式输出：
  - `kill_layer`
  - `scavenge_layer`
  - `herd_source_layer`
- ✅ 尸体资源链现已支持：
  - 状态反馈
  - 低频 `species_pool` 重平衡
  - 区域关系状态持久化
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `carrion_chain` 摘要、反馈、重平衡断言并通过

### v4.0-alpha6 (2026-04-08 21:10)

- ✅ 新增原生 `vulture` 运行体，作为草原空中清道夫接入 `v4`
- ✅ `v4` 模板、物种变体、运行桥接、草原默认物种池已同步补齐 `vulture`
- ✅ `carrion_chain` 已扩展：
  - `aerial_scavenge_layer`
  - `aerial_scavenging`
  - `thermal_tracking`
  - `scavenger_stack`
  - `full_carrion_closure`
- ✅ `carrion_rebalancing` 现已支持对 `vulture` 的低频物种池扶持
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `vulture` 注册与草原尸体资源链断言并通过

### v4.0-alpha7 (2026-04-08 21:25)

- ✅ `grassland_chain` 新增 `social_layer`
- ✅ 草原捕食者社群结构现已开始表达：
  - `pride_patrol`
  - `male_competition_pressure`
  - `clan_pressure`
  - `den_cluster_pressure`
  - `apex_rivalry`
  - `group_hunt_instability`
- ✅ `grassland_rebalancing` 现已支持 `social_layer`，开始对 `lion / hyena` 做轻量社群层重平衡
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增草原社群层断言并通过

### v4.0-alpha8 (2026-04-08 22:05)

- ✅ 新增 [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py)，把草原和湿地的领地压力拆成独立关系模块
- ✅ `WorldSimulation` 统计新增独立 `territory` 区块，并将其持久写入区域 `relationship_state`
- ✅ 当前 `territory` 已覆盖：
  - 草原：`pride_core_range`、`male_takeover_front`、`clan_den_range`、`apex_boundary_conflict`
  - 湿地：`channel_claim`、`basking_bank_claim`、`shoreline_standoff`、`dam_complex_claim`
- ✅ `cascade.py` 现已开始汇总 `territory`，新增 `territorial_stress`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `territory` 摘要、反馈、世界统计和区域持久化断言并通过

### v4.0-alpha9 (2026-04-08 22:20)

- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 为 `Lion / Hyena` 新增个体级领地接口：
  - `Lion._establish_pride_core()`
  - `Hyena._mark_den_cluster()`
- ✅ 狮群和鬣狗现在不仅有区域级 `territory` 摘要，还能在当前运行层真实占用草原边缘微栖位并记录事件
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `lion` 核心领地和 `hyena` clan 通道测试并通过

### v4.0-alpha10 (2026-04-08 22:35)

- ✅ [src/entities/omnivores.py](/Users/yumini/Projects/eco-world/src/entities/omnivores.py) 为草原捕食者社群再补两条个体级接口：
  - `Lion._contest_male_front()`
  - `Hyena._expand_clan_front()`
- ✅ 这两条接口已接入当前运行体的周期行为节奏，用于表达雄狮接管前线和鬣狗 clan 扩张前线
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增对应运行测试并通过

### v4.0-alpha11 (2026-04-08 22:50)

- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现在开始吸收运行期事件信号，领地摘要不再只依赖区域物种池
- ✅ `WorldSimulation` 现已把当前焦点区域最近事件传给 `territory`，并在世界统计与区域 `relationship_state` 中保留 `runtime_signals`
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增运行期领地信号测试并通过

### v4.0-alpha12 (2026-04-08 23:05)

- ✅ `Lion / Hyena` 运行体现已新增轻量社群状态：
  - `pride_strength`
  - `takeover_pressure`
  - `clan_cohesion`
  - `clan_front_pressure`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已把运行层社群状态汇总给 `territory`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 现在同时吸收：
  - 运行期事件信号
  - 运行期社群状态
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增运行期领地状态测试并通过

### v4.0-alpha13 (2026-04-08 23:20)

- ✅ `Lion / Hyena` 现已新增轻量群体标识：
  - `pride_id`
  - `clan_id`
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 现已汇总：
  - `lion_pride_count`
  - `hyena_clan_count`
- ✅ [src/ecology/territory.py](/Users/yumini/Projects/eco-world/src/ecology/territory.py) 开始把群体数量纳入领地压力计算
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增群体标识和群体数量相关断言并通过

## v4.0.9 - Add wetland chain summaries

- ✅ 新增 [src/ecology/wetland.py](/Users/yumini/Projects/eco-world/src/ecology/wetland.py)，为湿地与湖泊区域输出独立的湿地核心链摘要
- ✅ [src/sim/world_simulation.py](/Users/yumini/Projects/eco-world/src/sim/world_simulation.py) 统计新增 `wetland_chain`，可直接查看关键物种、营养级得分和叙事链
- ✅ 补充 `frog -> shore_hatch`、`catfish -> minnow`、`blackfish -> minnow/frog` 关系表，用于湿地链条表达
- ✅ 新增湿地链测试并修正世界统计测试中的区域语义断言
- ✅ 湿地链现在会轻量反馈到区域 `resource_state / hazard_state / health_state`，并持久写入 `relationship_state["wetland_chain"]`
- ✅ 新增 [src/ecology/predation.py](/Users/yumini/Projects/eco-world/src/ecology/predation.py)，把湿地链与夜行链的分层捕食压力从摘要中拆成独立模块
- ✅ 湿地链现已支持低频 `species_pool` 重平衡，开始把岸带耦合与顶层压制反馈到关键湿地物种池
- ✅ 湿地链重平衡现在会按 `shoreline_layer / fish_layer / apex_layer` 分组持久写入区域关系状态
- ✅ `wetland_chain` 现已显式输出 `layer_scores / layer_species`，让岸带层、鱼层、顶层成为可直接消费的结构化数据
- ✅ 新增草原大型植食者链 `grassland_chain`，开始显式表达 `engineering_layer / grazing_layer / browse_layer`
| fruits-omnivores.md | entities/omnivores.py | 杂食动物变更 |
| ECOSYSTEM.md | 所有 | 总览更新 |
| USAGE.md | main.py | 启动参数变更 |

---

## 版本历史

### v4.0-alpha3 (2026-04-08 19:45)

**草原链补强**：
- ✅ 新增 `lion / hyena` 的 `v4` 模板、变体、关系表与运行桥接
- ✅ 当前可运行系统已原生接入狮和鬣狗，并打通注册、初始化、生成与事件链
- ✅ `grassland_chain` 已扩展到：
  - `engineering_layer`
  - `grazing_layer`
  - `browse_layer`
  - `predator_layer`
  - `scavenger_layer`
- ✅ 草原链现在会显式表达：
  - `apex_predation`
  - `carrion_scavenging`
  - `carcass_competition`
  - `grassland_predator_closure`
- ✅ `predation.py` 已补上草原顶层捕食压力：
  - `lion -> rabbit`
  - `hyena -> rabbit`
- ✅ 新增 `grassland_rebalancing`，草原链现在也具备低频物种池重平衡
- ✅ `grassland_rebalancing` 已按层级持久写回区域关系状态，可区分：
  - `grazing_layer`
  - `browse_layer`
  - `predator_layer`
  - `scavenger_layer`
- ✅ 新增草原食草群原生运行体：
  - `antelope`
  - `zebra`
- ✅ `grassland_chain` 已扩展 `herd_layer`
- ✅ 草原链现在会显式表达：
  - `herd_grazing`
  - `migration_pressure`
  - `prey_corridor_density`
  - `herd_predator_loop`
- ✅ `predation.py` 已补上：
  - `lion -> antelope`
  - `hyena -> antelope`
  - `lion -> zebra`

**验证**：
- ✅ [tests/test_ecosystem.py](/Users/yumini/Projects/eco-world/tests/test_ecosystem.py) 已新增 `antelope / zebra / lion / hyena` 注册，以及草原链分层与重平衡断言
- ✅ `PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile src/data/defaults.py src/entities/omnivores.py src/entities/animals.py src/core/ecosystem.py src/world/world_map.py src/ecology/grassland.py src/ecology/predation.py tests/test_ecosystem.py`

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

# v4.0-alpha34 (2026-04-09 08:10)

- `grassland.py` 现已把区域级 `prosperity / collapse` 相位接入草原链摘要与反馈：
  - `prosperity_phase_weight`
  - `collapse_phase_weight`
- `carrion.py` 现已把区域级 `prosperity / collapse` 相位接入尸体资源链摘要与反馈：
  - `prosperity_phase_carrion`
  - `collapse_phase_carrion`
- 这使得 `prosperity / collapse` 不再只影响重平衡，也开始改变：
  - 草原链 summary 权重
  - 尸体资源链 summary 权重
  - 区域反馈强度

# v4.0-alpha36 (2026-04-09 11:25)

- `social.py` 现已把：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
  接入长期相位：
  - `grassland_boom_phase`
  - `grassland_bust_phase`
  - `grassland_prosperity_phase`
  - `grassland_collapse_phase`
- 这意味着 herd/vulture 的长期迁移与追踪周期，已经开始真正改变草原区的长期繁荣/衰退走势

# v4.0-alpha35 (2026-04-09 11:10)

- `social.py` 现已在长期热点记忆之上进一步形成显式周期：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
- `grassland.py` 现已吸收 herd-route 周期：
  - `herd_route_cycle_pressure`
  - `herd_route_cycle_support`
- `carrion.py` 现已吸收 aerial-carrion 周期：
  - `aerial_carrion_cycle_pressure`
  - `aerial_carrion_cycle_support`
- 这层 herd / vulture 周期现已进入：
  - `social_trends.phase_scores`
  - `grassland_chain`
  - `carrion_chain`
  - 低频重平衡

# v4.0-alpha34 (2026-04-09 10:35)

- `social.py` 现已把运行中的 `antelope / zebra / vulture` 通道热点写入长期 `hotspot_scores`：
  - `herd_hotspot_memory`
  - `herd_apex_memory`
  - `vulture_hotspot_memory`
  - `vulture_carrion_memory`
- `grassland.py` 现已吸收 herd 通道热点记忆：
  - `herd_memory_corridors`
  - `herd_memory_pressure`
- `carrion.py` 现已吸收空中尸体通道记忆：
  - `aerial_memory_lanes`
  - `aerial_memory_overlap`
- 这层 herd / vulture 热点记忆现已进入：
  - `social_trends`
  - `grassland_chain`
  - `carrion_chain`
  - 区域反馈

# v4.0-alpha33 (2026-04-09 07:45)

- `social.py` 新增区域级长期相位：
  - `grassland_prosperity_phase`
  - `grassland_collapse_phase`
- 这层长期相位现已进入：
  - `relationship_state["social_trends"]`
  - `WorldSimulation` 综合生态压力
- `grassland.py` 现已把区域长期相位接入草原链重平衡：
  - `prosperity_phase_herd_gain`
  - `collapse_phase_scavenger_loss`
- `carrion.py` 现已把区域长期相位接入尸体资源链重平衡：
  - `prosperity_phase_scavenger_gain`
  - `collapse_phase_apex_loss`

# v4.0-alpha32 (2026-04-09 07:25)

- `social.py` 新增显式长期相位：
  - `grassland_boom_phase`
  - `grassland_bust_phase`
- 这层长期相位现已进入：
  - `relationship_state["social_trends"]`
  - `WorldSimulation` 综合生态压力
- `grassland.py` 现已把长期 boom/bust 相位直接接入草原链重平衡：
  - `boom_phase_herd_release`
  - `bust_phase_herd_drag`
  - `boom_phase_apex_release`
  - `bust_phase_apex_drag`
- `carrion.py` 现已把长期 boom/bust 相位直接接入尸体资源链重平衡：
  - `boom_phase_scavenger_release`
  - `bust_phase_scavenger_drag`
- 对应测试已补齐，确认长期相位已经进入：
  - `social_trends`
  - `grassland_rebalancing`
  - `carrion_rebalancing`

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
# v4.0-alpha38 - Feed prosperity phases into herd and carrion runtime

- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现在会把 `grassland_prosperity_phase / grassland_collapse_phase` 回灌到 `antelope / zebra / vulture`
- ✅ `Antelope / Zebra / Vulture` 新增 prosperity/collapse 运行态偏置，长期区域繁荣/衰退现在会直接影响 herd 通道与空中尸体通道行为

# v4.0-alpha39 - Feed prosperity phases into hotspot memory

- ✅ `grassland_prosperity_phase / grassland_collapse_phase` 现在会反向影响 `herd_hotspot_memory / herd_apex_memory / vulture_hotspot_memory / vulture_carrion_memory`
- ✅ 长期区域繁荣/衰退不再只作用于摘要和运行态行为，也开始改变 herd 与空中尸体通道记忆的累积方向

# v4.0-alpha40 - Couple prosperity phases back into route cycles

- ✅ `grassland_prosperity_phase / grassland_collapse_phase` 现在会继续反向影响 `herd_route_cycle / aerial_carrion_cycle`
- ✅ 草原长期繁荣/衰退相位与 herd/carrion 通道周期已开始形成双向耦合，而不再只是单向传导

# v4.0-alpha41 - Feed route cycles into runtime corridor behavior

- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现在会把 `herd_route_cycle / aerial_carrion_cycle` 直接回灌到 `antelope / zebra / vulture`
- ✅ herd/carrion 长期周期现在会直接影响食草群与秃鹫的运行期通道偏置，而不只作用于摘要和重平衡

# v4.0-alpha42 - Feed runtime route cycles back into territory

- ✅ `runtime_territory_state` 现在会采集运行中的 `herd_route_cycle_runtime / aerial_carrion_cycle_runtime`
- ✅ `territory.runtime_signals` 与领地压力现在会吸收 herd/carrion 的运行期周期行为，形成更完整的空间反馈闭环

# v4.0-alpha43 - Feed social cycles into regional resources

- ✅ `apply_region_social_trend_feedback()` 现在会把 `herd_route_cycle` 回灌到 `surface_water`
- ✅ `apply_region_social_trend_feedback()` 现在也会把 `aerial_carrion_cycle` 回灌到 `carcass_availability`

# v4.0-alpha44 - Feed regional resource anchors into territory chains

- ✅ `territory` 现在会直接读取区域 `surface_water / carcass_availability`，生成 `surface_water_anchor / carcass_anchor`
- ✅ `grassland_chain / carrion_chain` 现在会吸收这些资源锚点，资源层正式进入草原长期闭环

# v4.0-alpha45 - Feed regional resource anchors into social trend memory

- ✅ `social_trends` 现在会直接读取 `surface_water_anchor / carcass_anchor`
- ✅ 这些资源锚点现在会继续抬升：
  - `herd_hotspot_memory / herd_apex_memory`
  - `vulture_hotspot_memory / vulture_carrion_memory`
  - `herd_route_cycle / aerial_carrion_cycle`
- ✅ 资源层现在已经不只进入 `territory / grassland_chain / carrion_chain`，也开始进入长期社群记忆与周期层

# v4.0-alpha46 - Feed resource anchors into long-term prosperity phases

- ✅ `surface_water_anchor / carcass_anchor` 现在会继续直接影响：
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
- ✅ 草原长期繁荣/衰退相位现在已经不只受热点和社群周期驱动，也开始受区域资源锚点直接驱动

# v4.0-alpha47 - Feed resource anchors into dominant layer switching

- ✅ `surface_water_anchor` 现在会继续抬升 `grassland_chain` 的 `herd_layer / browse_layer`
- ✅ `carcass_anchor_pressure` 现在会继续抬升 `carrion_chain` 的 `aerial_scavenge_layer / herd_source_layer`
- ✅ 资源锚点现在已经开始直接参与 `dominant_layer` 的切换，而不只是参与链路分数和长期相位


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
# v4 Ongoing - Runtime prosperity anchors feed back into territory and social trends

- ✅ `runtime_anchor_prosperity` 现已从 `lion / hyena / antelope / zebra / vulture` 重新汇总回 `runtime_territory_state`
- ✅ `territory.runtime_signals` 新增：
  - `apex_anchor_prosperity_runtime`
  - `herd_anchor_prosperity_runtime`
  - `aerial_anchor_prosperity_runtime`
- ✅ 这些运行期繁荣锚点已经开始直接影响：
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
- ✅ `social_trends` 现已继续吸收这些运行期繁荣锚点，并让它们进入：
  - `herd_route_cycle`
  - `aerial_carrion_cycle`
  - `grassland_boom_phase`
  - `grassland_prosperity_phase`
  - `cycle_signals`
- ✅ 新增并通过回归断言，验证 `territory` 与 `social_trends` 都能读到这批新的运行期繁荣锚点
- ✅ `grassland_chain` 现已继续把：
  - `herd_anchor_prosperity_runtime`
  - `apex_anchor_prosperity_runtime`
  写成：
  - `runtime_herd_anchor_prosperity_pull`
  - `runtime_apex_anchor_prosperity_pull`
  并接入区域反馈与低频 herd/apex 重平衡
- ✅ `carrion_chain` 现已继续把：
  - `aerial_anchor_prosperity_runtime`
  写成：
  - `runtime_aerial_anchor_prosperity_pull`
  并接入区域反馈与空中清道夫重平衡
- ✅ 世界级长期压力聚合现已继续吸收：
  - `runtime_herd_anchor_prosperity_pull`
  - `runtime_aerial_anchor_prosperity_pull`
  - `runtime_apex_anchor_prosperity_pull`
  - `herd_anchor_prosperity_runtime`
  - `aerial_anchor_prosperity_runtime`
  - `apex_anchor_prosperity_runtime`
- ✅ 这些运行期繁荣锚点现在已经开始直接进入区域：
  - `prosperity_pressure`
  - `runtime_resource_pressure`
  - `health_state["prosperity" / "stability"]`
- ✅ `grassland_chain` 与 `carrion_chain` 现已继续直接吸收区域：
  - `prosperity`
  - `stability`
  - `collapse_risk`
  并把它们写成：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
- ✅ 这意味着区域长期健康度现在已经开始不经过运行体中转，直接改变两条链的摘要权重与主导层偏置
- ✅ `grassland_rebalancing` 与 `carrion_rebalancing` 现已继续直接吸收：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
- ✅ 这些区域长期健康锚点现在已经开始直接生成：
  - `regional_prosperity_support`
  - `regional_stability_support`
  - `regional_collapse_drag`
  并进入草食群、清道夫和顶层捕食者的低频物种池调节
- ✅ `social_trends` 现也开始继续直接吸收区域：
  - `prosperity`
  - `stability`
  - `collapse_risk`
- ✅ 这些区域长期健康信号现在已经开始直接进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `cycle_signals`
  也就是说，区域长期健康度现在已经开始不经过运行体中转，直接塑造社群长期记忆层
- ✅ `territory` 现也开始继续吸收上一周期 `social_trends` 中的：
  - `regional_prosperity_anchor`
  - `regional_stability_anchor`
  - `regional_collapse_anchor`
  - `grassland_collapse_phase`
- ✅ 这些区域长期社会锚点现在已经开始直接回灌：
  - `waterhole_spacing`
  - `pride_core_range`
  - `clan_den_range`
  - `apex_boundary_conflict`
  - `carcass_route_overlap`
  也就是说，区域长期社会锚点现在已经开始直接改变领地布局压力，而不只停留在 `social_trends`
- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现也开始继续吸收：
  - `regional_prosperity_bias`
  - `regional_stability_bias`
  - `regional_collapse_bias`
- ✅ 这些区域长期社会锚点现在已经开始直接进入：
  - `lion / hyena` 的中心漂移粘滞
  - `antelope / zebra` 的 herd 通道偏置
  - `vulture` 的空中尸体通道偏置
- ✅ `WorldSimulation._build_runtime_territory_state()` 现也开始继续吸收运行中的：
  - `regional_prosperity_bias`
  - `regional_stability_bias`
  - `regional_collapse_bias`
- ✅ 这些运行期长期社会锚点现在已经开始重新汇总成：
  - `apex_regional_bias_runtime`
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  并回灌到 `territory.runtime_signals`
- ✅ `social_trends` 现也开始继续吸收：
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
- ✅ 这些运行期长期社会锚点现在已经开始直接进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
- ✅ `grassland_chain` 现也开始继续吸收：
  - `herd_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  并把它们写成：
  - `runtime_herd_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
- ✅ 这些运行中的区域长期社会锚点现在已经开始直接进入：
  - 草原链摘要
  - 草原链区域反馈
  - herd/apex 的低频重平衡
- ✅ `carrion_chain` 现也开始继续吸收：
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
  并把它们写成：
  - `runtime_aerial_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
- ✅ 这些运行中的区域长期社会锚点现在已经开始直接进入：
  - 尸体资源链摘要
  - 尸体资源链区域反馈
  - 空中清道夫/apex 的低频重平衡
- ✅ `WorldSimulation._build_combined_pressures()` 现也开始继续吸收：
  - `runtime_herd_regional_bias_pull`
  - `runtime_aerial_regional_bias_pull`
  - `runtime_apex_regional_bias_pull`
  以及 `territory.runtime_signals` 里的：
  - `herd_regional_bias_runtime`
  - `aerial_regional_bias_runtime`
  - `apex_regional_bias_runtime`
- ✅ 这些运行中的区域长期社会锚点现在已经开始直接进入：
  - 世界级 `prosperity_pressure`
  - 世界级 `collapse_pressure`
  - 世界级 `runtime_resource_pressure`
  并进一步影响区域长期 `prosperity / collapse_risk / stability`
- ✅ `runtime_territory_state` 现也开始继续把区域：
  - `prosperity`
  - `stability`
  - `collapse_risk`
  组合成：
  - `apex_regional_health_anchor_runtime`
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
- ✅ `territory.runtime_signals` 现也开始继续吸收这 3 个运行期长期健康锚点，并把它们继续回灌到：
  - `waterhole_spacing`
  - `carcass_route_overlap`
  - `apex_boundary_conflict`
  也就是说，区域长期健康度现在已经开始直接形成 runtime 级领地健康锚点
- ✅ `social_trends` 现也开始继续吸收：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
- ✅ 这些运行期区域长期健康锚点现在已经开始直接进入：
  - herd/vulture 热点记忆
  - herd/aerial 周期
  - `grassland_boom_phase / grassland_bust_phase`
  - `grassland_prosperity_phase / grassland_collapse_phase`
- ✅ `grassland_chain` 现也开始继续吸收：
  - `herd_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  并把它们写成：
  - `runtime_herd_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
- ✅ `carrion_chain` 现也开始继续吸收：
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
  并把它们写成：
  - `runtime_aerial_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
- ✅ 这些运行期区域长期健康锚点现在已经开始直接进入：
  - 两条链摘要
  - 两条链区域反馈
  - herd/aerial/apex 的低频重平衡
- ✅ `WorldSimulation._build_combined_pressures()` 现也开始继续吸收：
  - `runtime_herd_health_anchor_pull`
  - `runtime_aerial_health_anchor_pull`
  - `runtime_apex_health_anchor_pull`
  以及 `territory.runtime_signals` 里的：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
- ✅ 这些运行期区域长期健康锚点现在已经开始直接进入：
  - 世界级 `prosperity_pressure`
  - 世界级 `collapse_pressure`
  - 世界级 `runtime_resource_pressure`
  并进一步影响区域长期 `prosperity / collapse_risk / stability`
- ✅ `apply_region_social_trend_feedback()` 现也开始继续读取这些 runtime 健康锚点对应的 `cycle_signals`
- ✅ 它们现在已经开始继续回灌：
  - `surface_water`
  - `carcass_availability`
  - `predation_pressure`
  - `resilience`
  也就是说，运行期区域长期健康锚点现在已经开始反向抬升区域资源锚点与韧性本身
- ✅ `runtime_territory_state` 现也开始继续把：
  - `surface_water`
  - `carcass_availability`
  - `runtime_anchor_prosperity`
  反向并入：
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  - `apex_regional_health_anchor_runtime`
- ✅ 这意味着运行期区域长期健康锚点现在已经从纯健康值推进成资源-健康复合锚点
- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现在会把这些复合健康锚点直接注入运行体：
  - `lion.regional_health_anchor`
  - `hyena.regional_health_anchor`
  - `antelope.regional_health_anchor`
  - `zebra.regional_health_anchor`
  - `vulture.regional_health_anchor`
- ✅ 这些新字段现在已经开始直接影响：
  - `lion / hyena` 的 `pride_center / clan_center` 漂移粘滞
  - `antelope / zebra` 的 herd 通道选择
  - `vulture` 的空中尸体通道选择
- ✅ `runtime_territory_state` 现也开始直接从运行体回收这些 `regional_health_anchor`
  并把它们继续抬升为：
  - `apex_regional_health_anchor_runtime`
  - `herd_regional_health_anchor_runtime`
  - `aerial_regional_health_anchor_runtime`
  也就是说，这一层现在已经不是 world 侧单向估算，而变成了：
  - 区域长期健康
  - 运行体复合健康锚点
  - world 汇总
  的真实闭环
- ✅ `regional_health_anchor` 现已继续进入 `antelope / zebra / vulture` 的运行期体况层
- ✅ 它们现在会直接改善：
  - `health`
  - `hunger`
  - `reproduction_rate`
  这意味着 herd 与 carrion 运行体现在已经不仅会“往更好的通道移动”，还会在长期健康区表现出更稳的体况和延续节律
- ✅ `regional_health_anchor` 现也继续进入 `lion / hyena` 的运行期体况层
- ✅ 它现在也会直接改善 apex 运行体的：
  - `health`
  - `hunger`
  - `reproduction_rate`
  这意味着草原顶层社群现在也开始直接吸收长期健康锚点，而不只是在领地中心漂移上体现
- ✅ `runtime_territory_state` 现也开始汇总运行体的真实体况 `condition`
  并继续写入：
  - `herd_condition_runtime`
  - `aerial_condition_runtime`
  - `apex_condition_runtime`
- ✅ 这些真实体况信号现在已经开始进入：
  - `territory.runtime_signals`
  - `social_trends.cycle_signals`
  也就是说，系统现在已经不只看“锚点和偏置”，也开始把动物当下真实状态并入长期社群节律
- ✅ `grassland_chain` 现在也开始继续读取：
  - `herd_condition_runtime`
  - `apex_condition_runtime`
  并把它们写成：
  - `runtime_herd_condition_pull`
  - `runtime_apex_condition_pull`
- ✅ 这些真实体况 pull 现在已经继续进入：
  - 草原链摘要
  - 草原链区域反馈
  - `antelope / zebra / lion` 的低频重平衡
- ✅ `carrion_chain` 现在也开始继续读取：
  - `aerial_condition_runtime`
  - `apex_condition_runtime`
  并把它们写成：
  - `runtime_aerial_condition_pull`
  - `runtime_apex_condition_pull`
- ✅ 这些真实体况 pull 现在已经继续进入：
  - 尸体资源链摘要
  - 尸体资源链区域反馈
  - `vulture / lion` 的低频重平衡
- ✅ `WorldSimulation._build_combined_pressures()` 现也开始继续吸收：
  - `runtime_herd_condition_pull`
  - `runtime_aerial_condition_pull`
  - `runtime_apex_condition_pull`
  这意味着运行中的真实体况现在已经开始直接进入世界级：
  - `prosperity_pressure`
  - `collapse_pressure`
  并进一步影响区域长期 `prosperity / collapse_risk / stability`
- ✅ `RegionSimulation.apply_relationship_runtime_state()` 现也开始把：
  - `herd_condition_runtime`
  - `aerial_condition_runtime`
  - `apex_condition_runtime`
  直接下沉到运行体
- ✅ `lion / hyena / antelope / zebra / vulture` 现在新增：
  - `condition_runtime`
  - `_apply_condition_runtime()`
- ✅ 这层真实体况现在会直接改善：
  - `health`
  - `hunger`
  - `mate_cooldown`
  - `reproduction_rate`
  也就是说，`runtime condition` 现在已经不只影响链路压力和长期趋势，也开始直接影响运行体的繁殖与恢复节律
- ✅ `lion / hyena` 的社群化产仔路径现在也开始继续读取：
  - `condition_runtime`
- ✅ 它现在会继续进入：
  - 产仔规模
  - 产后冷却
  也就是说，草原顶层社群现在已经不只会因为稳定度和资源而延续，真实体况本身也开始直接改变群体延续速度
- ✅ `grassland_rebalancing / carrion_rebalancing` 现在也开始继续读取：
  - `runtime_herd_condition_pull`
  - `runtime_aerial_condition_pull`
  - `runtime_apex_condition_pull`
- ✅ 它们现在会继续打开更明确的恢复窗口：
  - `condition_herd_recovery`
  - `condition_pride_recovery`
  - `condition_clan_recovery`
  - `condition_aerial_recovery`
  - `condition_apex_carrion_recovery`
  也就是说，真实体况现在已经不只影响当前恢复和产仔，还开始直接影响 herd/apex/aerial 的低频恢复节律
- ✅ phase-adjusted `condition_runtime` 现在也开始继续进入：
  - `runtime_territory_state`
  - `territory.runtime_signals`
  - `social_trends.cycle_signals`
- ✅ 新增并打通：
  - `herd_condition_phase_runtime`
  - `aerial_condition_phase_runtime`
  - `apex_condition_phase_runtime`
  也就是说，长期 `prosperity / collapse` 相位现在已经不只通过摘要层起作用，而会继续沿着真实运行体体况反向塑造 `territory` 和 `social_trends`
- ✅ 这组 phase-conditioned runtime 现在也开始继续进入：
  - `grassland_chain`
  - `carrion_chain`
  - 区域反馈
  - 低频重平衡
  - 世界级长期压力
- ✅ 新增并打通：
  - `runtime_herd_condition_phase_pull`
  - `runtime_aerial_condition_phase_pull`
  - `runtime_apex_condition_phase_pull`
  也就是说，长期相位修正后的真实体况现在已经不只影响 `territory/social_trends`，还开始直接改变草原链、尸体资源链和区域长期健康判定
- ✅ phase-conditioned runtime 现已进一步抬升成新的 territory/social 锚点：
  - `herd_condition_phase_anchor_runtime`
  - `aerial_condition_phase_anchor_runtime`
  - `apex_condition_phase_anchor_runtime`
- ✅ 它们现在已经进入：
  - `runtime_territory_state`
  - `territory.runtime_signals`
  - `social_trends.cycle_signals`
  也就是说，长期相位修正后的真实体况现在不只作为一次性 pull 使用，而开始作为下一轮长期 territory/social 节律的稳定锚点
- ✅ 这组 phase anchor runtime 现在也开始继续进入：
  - `grassland_chain`
  - `carrion_chain`
  - 区域反馈
  - 低频重平衡
  - 世界级长期压力
- ✅ 新增并打通：
  - `runtime_herd_condition_phase_anchor_pull`
  - `runtime_aerial_condition_phase_anchor_pull`
  - `runtime_apex_condition_phase_anchor_pull`
  也就是说，长期相位修正后的真实体况锚点现在已经不只影响 `territory/social_trends`，还开始直接改变草原链、尸体资源链和区域长期 prosperity/collapse 判定
- ✅ 长期 `prosperity / collapse` 现已继续下沉成运行体自己的 `condition_phase_bias`
  - 已注入：
    - `lion / hyena`
    - `antelope / zebra`
    - `vulture`
  - 已直接影响：
    - `health`
    - `hunger`
    - `mate_cooldown`
    - `reproduction_rate`
- ✅ 这层新的 phase bias 也已重新汇总回：
  - `runtime_territory_state`
  - `territory.runtime_signals`
  - `social_trends.cycle_signals`
  也就是说，长期相位现在已经不只经由摘要和 pull 生效，而会作为运行体自己的长期体况偏置，继续反向塑造下一轮 territory/social 节律
- ✅ `condition_phase_bias_runtime` 现在也继续进入：
  - `grassland_chain`
  - `carrion_chain`
  - 世界级长期压力
  也就是说，长期相位沉淀出的运行体体况偏置现在已经不只作用于 `territory/social`，还开始直接抬高 herd/apex/aerial 两条草原链的长期权重
- 文档阅读说明：
  - `runtime`：运行期
  - `anchor`：锚点
  - `bias`：偏置
  - `pull`：拉力
  - `phase`：相位
  - `cycle`：周期
  - `territory`：领地层
  - `social_trends`：社群趋势层
  - `grassland_chain`：草原链
  - `carrion_chain`：尸体资源链
- 新增并打通：
  - `world_pressure_bias`：世界级长期压力回灌到运行体后的体况偏置
  - `herd_world_pressure_runtime`
  - `aerial_world_pressure_runtime`
  - `apex_world_pressure_runtime`
- 它们现在已经进入：
  - `lion / hyena / antelope / zebra / vulture` 的运行体状态
  - `territory.runtime_signals`
  - `social_trends.cycle_signals`
  - `grassland_chain`
  - `carrion_chain`
- 也就是说，世界级长期压力现在已经不只回写区域 `health_state`，而开始继续下沉成真实动物体况，并再反向塑造下一轮 `territory/social/grassland/carrion` 节律
- 现已新增并打通：
  - `world_pressure_herd_window`
  - `world_pressure_apex_window`
  - `world_pressure_aerial_window`
  - `world_pressure_apex_carrion_window`
- 这些新的 world pressure window 现在已经进入：
  - `grassland_rebalancing`
  - `carrion_rebalancing`
  - `social_trends.cycle_signals`
  - 世界级长期压力
- 同时新增：
  - `world_pressure_window_memory`
  也就是说，世界级长期压力现在不只会直接压到运行体，还会先打开 herd/apex/aerial 的恢复窗口，再把这些窗口沉淀成新的社群记忆，继续反向抬高下一轮长期压力
- 文档阅读说明补充：
  - `world pressure`：世界级长期压力
  - `window`：恢复窗口/扩张窗口
  - `memory`：记忆层
  - `condition runtime`：运行期真实体况
- 现已新增并打通：
  - `world_pressure_window_bias`
  - `herd_world_pressure_window_runtime`
  - `aerial_world_pressure_window_runtime`
  - `apex_world_pressure_window_runtime`
- 它们现在已经进入：
  - `lion / hyena / antelope / zebra / vulture` 的运行体状态
  - `territory.runtime_signals`
  - `social_trends.cycle_signals`
- 也就是说，`world_pressure_window_memory` 现在已经不只停留在长期记忆层，而会继续下沉成运行体自己的恢复偏置，再重新反向塑造下一轮 territory/social 节律
- 文档阅读说明补充：
  - `window bias`：窗口偏置，指“长期窗口记忆”下沉后对运行体产生的直接恢复倾向
- 这批新的 runtime window 信号现在也已继续进入：
  - `grassland_chain`
  - `carrion_chain`
  - 世界级长期压力聚合
- 也就是说，`world_pressure_window_bias -> runtime_territory_state`
  这条线现在已经不只影响 territory/social，还会继续抬高草原链、尸体资源链和下一轮区域 prosperity/collapse 判定
- 现已新增并打通：
  - `runtime_herd_world_pressure_window_pull`
  - `runtime_aerial_world_pressure_window_pull`
  - `runtime_apex_world_pressure_window_pull`
- 它们现在已经进入：
  - `grassland_chain`
  - `carrion_chain`
  - 世界级长期压力
- 也就是说，world pressure window 现在已经从“运行体偏置”继续推进成了草原链与尸体资源链的直接长期输入
- `scripts/graph_checks.py` 新增：
  - `--staged`：只分析已暂存改动
  - `--profile smoke|targeted|full`：只输出某一档检查方案
  - `--commands-only`：只输出可执行命令，减少说明性文本和 token 消耗
- [docs/CODE-REVIEW-GRAPH-CHECKS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-CHECKS.md) 与 [docs/USAGE.md](/Users/yumini/Projects/eco-world/docs/USAGE.md) 已同步补充中文说明与命令示例
- `scripts/graph_checks.py` 现已继续优化：
  - `--emit compile|tests|both`：只输出需要的命令类型
  - `src/entities/animals.py` / `src/entities/omnivores.py` 现已支持更细的 diff-aware 归类，不再默认所有运行体改动都一律跑 `species + runtime`
- [docs/CODE-REVIEW-GRAPH-CHECKS.md](/Users/yumini/Projects/eco-world/docs/CODE-REVIEW-GRAPH-CHECKS.md) 与 [docs/USAGE.md](/Users/yumini/Projects/eco-world/docs/USAGE.md) 已同步补充中文说明与示例
- 主线继续推进：
  - `birth_memory_world_pressure_bias`：产仔记忆与世界级长期压力叠加后的运行期偏置
  - 已接入：
    - `lion / hyena / antelope / zebra / vulture`
    - `territory.runtime_signals`
    - `social_trends.cycle_signals`
    - `grassland_chain / carrion_chain` 摘要、反馈与重平衡
    - 世界级长期压力聚合
  - 也就是说，这条慢反馈现在已经形成：
    - `birth_memory -> world pressure -> runtime bias -> territory/social/chains -> next world pressure`
- 主线继续推进：
  - `runtime_*_birth_cycle_window_pull` 现在不再只进入摘要和世界级长期压力
  - 已继续接入：
    - `grassland_chain / carrion_chain` 的区域反馈
    - herd / aerial / apex 的低频重平衡
  - 新增支持效果：
    - `birth_cycle_window_herd_support`
    - `birth_cycle_window_apex_support`
    - `birth_cycle_window_aerial_support`
    - `birth_cycle_window_apex_carrion_support`
- 主线继续推进：
  - `social_trends` 现在不只统计 `birth_cycle_*_window`
  - 也会把已经生效的：
    - `birth_cycle_window_herd_support`
    - `birth_cycle_window_apex_support`
    - `birth_cycle_window_aerial_support`
    - `birth_cycle_window_apex_carrion_support`
    继续沉淀成 `birth_cycle_window_memory`
  - 也就是说，长期记忆现在会记“窗口打开过”，也会记“窗口真的生效过”
- 主线继续推进：
  - `birth_cycle_window_memory` 现在不只是布尔信号
  - 已新增 `birth_cycle_window_memory_strength`
  - 它会按窗口与 support 的真实生效强度，继续抬升运行体的 `birth_cycle_bias`
  - 也就是说，慢反馈繁殖窗口现在不再只是“发生过/没发生过”，而是开始按强度回灌 herd / apex / aerial 的真实繁殖节律
- 主线继续推进：
  - `world_simulation` 里的长期压力聚合与 `runtime_territory_state`
    现在也开始按 `birth_cycle_window_memory_strength` 计入，而不再只看布尔型 `birth_cycle_window_memory`
  - 也就是说，世界层和运行期 territory 聚合现在都会识别“窗口生效得有多强”，而不只是“窗口是否存在”
- 主线继续推进：
  - `social_trends` 的周期层现在也开始读取 `birth_cycle_window_memory_strength`
  - 它会继续抬升：
    - `herd_route_cycle`
    - `aerial_carrion_cycle`
  - 并且当强度足够时，会显式写入 `cycle_signals`
- 主线继续推进：
  - `birth_cycle_window_memory_strength` 现在也开始进入：
    - `grassland_boom_phase / grassland_bust_phase`
    - `grassland_prosperity_phase / grassland_collapse_phase`
  - 也就是说，繁殖窗口的真实生效强度现在已经不只影响周期层，还会继续改变长期繁荣/衰退相位
- 主线继续推进：
  - `apply_region_social_trend_feedback(...)` 现在也直接读取 `birth_cycle_window_memory_strength`
  - 已继续影响：
    - `surface_water`
    - `carcass_availability`
    - `resilience`
  - 也就是说，繁殖窗口的真实生效强度现在已经从长期相位继续落到区域反馈层

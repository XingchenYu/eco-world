extends Control

const DATA_PATH := "res://data/world_state.json"
const REGION_LAYOUT := {
	"temperate_forest": Vector2(0.21, 0.28),
	"temperate_grassland": Vector2(0.43, 0.24),
	"wetland_lake": Vector2(0.31, 0.58),
	"rainforest_river": Vector2(0.54, 0.57),
	"coastal_shelf": Vector2(0.78, 0.48),
	"coral_sea": Vector2(0.85, 0.76),
}

const REGION_COLORS := {
	"temperate_forest": Color8(78, 137, 96),
	"temperate_grassland": Color8(198, 173, 96),
	"wetland_lake": Color8(92, 154, 162),
	"rainforest_river": Color8(65, 146, 118),
	"coastal_shelf": Color8(80, 141, 191),
	"coral_sea": Color8(203, 132, 177),
}

const REGION_ICONS := {
	"temperate_forest": "森",
	"temperate_grassland": "原",
	"wetland_lake": "泽",
	"rainforest_river": "雨",
	"coastal_shelf": "海",
	"coral_sea": "礁",
}

var world_data: Dictionary = {}
var active_region_id := ""
var title_label: Label
var subtitle_label: Label
var status_label: Label
var map_layer: Control
var side_panel: PanelContainer
var side_scroll: ScrollContainer
var side_box: VBoxContainer
var selected_tab := "overview"
var refresh_button: Button
var auto_refresh_button: CheckButton
var refresh_timer: Timer
var detail_cache: Dictionary = {}
var bulletin_cache: Array = []
var legend_cache: Array = []


func _ready() -> void:
	_build_ui()
	_load_world_data()


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 20)
	root_margin.add_theme_constant_override("margin_top", 18)
	root_margin.add_theme_constant_override("margin_right", 20)
	root_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_margin.add_child(root_vbox)

	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 90)
	root_vbox.add_child(header_panel)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	header_panel.add_child(header_box)

	title_label = Label.new()
	title_label.text = "阿瑞利亚生态世界"
	title_label.add_theme_font_size_override("font_size", 34)
	header_box.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Godot 世界地图界面"
	subtitle_label.add_theme_font_size_override("font_size", 18)
	header_box.add_child(subtitle_label)

	refresh_button = Button.new()
	refresh_button.text = "重新读取世界数据"
	refresh_button.custom_minimum_size = Vector2(180, 38)
	refresh_button.pressed.connect(_load_world_data)
	header_box.add_child(refresh_button)

	auto_refresh_button = CheckButton.new()
	auto_refresh_button.text = "自动刷新"
	auto_refresh_button.toggled.connect(_on_auto_refresh_toggled)
	header_box.add_child(auto_refresh_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	root_vbox.add_child(content)

	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(map_panel)

	map_layer = Control.new()
	map_layer.custom_minimum_size = Vector2(1040, 720)
	map_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_child(map_layer)

	side_panel = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(390, 0)
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(side_panel)

	side_scroll = ScrollContainer.new()
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_child(side_scroll)

	side_box = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 14)
	side_scroll.add_child(side_box)

	var footer_panel := PanelContainer.new()
	footer_panel.custom_minimum_size = Vector2(0, 46)
	root_vbox.add_child(footer_panel)

	status_label = Label.new()
	status_label.text = "先运行 Python 导出脚本生成 world_state.json"
	status_label.add_theme_font_size_override("font_size", 16)
	footer_panel.add_child(status_label)

	refresh_timer = Timer.new()
	refresh_timer.wait_time = 2.0
	refresh_timer.one_shot = false
	refresh_timer.timeout.connect(_load_world_data)
	add_child(refresh_timer)


func _load_world_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		_render_missing_data()
		return

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		_render_missing_data()
		return

	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_render_missing_data()
		return

	world_data = parsed
	active_region_id = str(world_data.get("world", {}).get("active_region_id", ""))
	detail_cache = world_data.get("region_details", {})
	bulletin_cache = world_data.get("world_bulletin", [])
	legend_cache = world_data.get("map_legend", [])
	_render_world()


func _render_missing_data() -> void:
	title_label.text = "EcoWorld Godot 前端"
	subtitle_label.text = "缺少世界状态 JSON"
	status_label.text = "请先运行：PYTHONPATH=. python3 scripts/export_world_state.py --pretty"


func _render_world() -> void:
	title_label.text = "阿瑞利亚生态世界"
	var world_meta: Dictionary = world_data.get("world", {})
	subtitle_label.text = "Tick %s · 已加载 %s/%s 区域" % [
		str(world_meta.get("tick", 0)),
		str(world_meta.get("loaded_regions", 0)),
		str(world_meta.get("total_regions", 0)),
	]
	status_label.text = "Godot 世界地图前端 · 中文界面 · 读取 Python 导出的世界状态"

	for child in map_layer.get_children():
		child.queue_free()
	for child in side_box.get_children():
		child.queue_free()

	_build_map_nodes(world_meta.get("regions", []))
	_build_world_bulletin()
	_build_map_legend()
	_build_side_panel()


func _build_map_nodes(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	for region_variant in regions:
		var region: Dictionary = region_variant
		var region_id := str(region.get("id", ""))
		var rel: Vector2 = REGION_LAYOUT.get(region_id, Vector2(0.5, 0.5))
		var pos := Vector2(map_size.x * rel.x, map_size.y * rel.y)

		var button := Button.new()
		button.text = "%s  繁荣 %.2f\n风险 %.2f  种群 %s" % [
			str(region.get("name", region_id)),
			float(region.get("prosperity", 0.0)),
			float(region.get("collapse_risk", 0.0)),
			str(region.get("species_population", 0)),
		]
		button.custom_minimum_size = Vector2(236, 104)
		button.position = pos - button.custom_minimum_size / 2.0
		button.add_theme_font_size_override("font_size", 18)
		button.modulate = REGION_COLORS.get(region_id, Color8(110, 140, 170))
		button.pressed.connect(_on_region_pressed.bind(region_id))
		map_layer.add_child(button)

		if region_id == active_region_id:
			var glow := ColorRect.new()
			glow.color = Color(1.0, 0.94, 0.68, 0.18)
			glow.position = button.position - Vector2(12, 10)
			glow.custom_minimum_size = button.custom_minimum_size + Vector2(24, 20)
			map_layer.add_child(glow)
			map_layer.move_child(glow, map_layer.get_child_count() - 2)

		var badge := Label.new()
		badge.text = REGION_ICONS.get(region_id, "区")
		badge.position = button.position + Vector2(10, 8)
		badge.add_theme_font_size_override("font_size", 28)
		map_layer.add_child(badge)


func _build_world_bulletin() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	panel.position = Vector2(24, 20)
	map_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title := Label.new()
	title.text = "世界播报"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	for line in bulletin_cache.slice(0, 4):
		var item := Label.new()
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.text = "• %s" % str(line)
		box.add_child(item)


func _build_map_legend() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	panel.position = Vector2(max(24, map_layer.size.x - 250), 20)
	map_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var title := Label.new()
	title.text = "地图图例"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	for entry_variant in legend_cache.slice(0, 5):
		var entry: Dictionary = entry_variant
		var label := Label.new()
		label.text = "■ %s" % str(entry.get("label", ""))
		box.add_child(label)


func _build_side_panel() -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var chains: Dictionary = active_region.get("chains", world_data.get("chains", {}))
	var narrative: Dictionary = active_region.get("narrative", world_data.get("narrative", {}))
	var top_species: Array = active_region.get("top_species", [])
	var route_summary: Array = active_region.get("route_summary", [])
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var chain_focus: Array = active_region.get("chain_focus", [])

	var title := Label.new()
	title.text = "%s · 焦点区域" % str(active_region.get("name", "未选择"))
	title.add_theme_font_size_override("font_size", 28)
	side_box.add_child(title)

	var climate := Label.new()
	climate.text = str(active_region.get("region_role", "生态观测区"))
	climate.add_theme_font_size_override("font_size", 18)
	side_box.add_child(climate)
	side_box.add_child(_make_tabs())

	match selected_tab:
		"overview":
			side_box.add_child(_make_focus_card(active_region))
			side_box.add_child(_make_region_summary_card(active_region))
			side_box.add_child(_make_badge_list("风险焦点", pressure_headlines))
			side_box.add_child(_make_badge_list("主导生态链", chain_focus))
			side_box.add_child(_make_section("健康状态", active_region.get("health_state", {})))
			side_box.add_child(_make_section("资源状态", active_region.get("resource_state", {})))
			side_box.add_child(_make_section("生态压力", active_region.get("ecological_pressures", {})))
			side_box.add_child(_make_section("区域连接", active_region.get("connectors", []), true, "target_region_id", "strength"))
			side_box.add_child(_make_route_section(route_summary))
			side_box.add_child(_make_intro_section(active_region))
		"chains":
			side_box.add_child(_make_section("社会相位", chains.get("social_phases", []), true))
			side_box.add_child(_make_section("草原主链", chains.get("grassland_chain", []), true))
			side_box.add_child(_make_section("尸体资源链", chains.get("carrion_chain", []), true))
			side_box.add_child(_make_section("湿地主链", chains.get("wetland_chain", []), true))
			side_box.add_child(_make_section("领地压力", chains.get("territory", []), true))
			side_box.add_child(_make_section("竞争压力", chains.get("competition", []), true))
			side_box.add_child(_make_section("捕食压力", chains.get("predation", []), true))
		"species":
			side_box.add_child(_make_species_section(top_species))
		"story":
			side_box.add_child(_make_story_section(narrative))

func _make_tabs() -> HBoxContainer:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	for tab_id in ["overview", "chains", "species", "story"]:
		var button := Button.new()
		button.text = {"overview": "总览", "chains": "生态链", "species": "物种", "story": "播报"}[tab_id]
		button.toggle_mode = true
		button.button_pressed = tab_id == selected_tab
		button.pressed.connect(_on_tab_pressed.bind(tab_id))
		tabs.add_child(button)
	return tabs


func _make_region_summary_card(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var summary := active_region.get("region_summary", {})
	var summary_title := Label.new()
	summary_title.text = "区域概况"
	summary_title.add_theme_font_size_override("font_size", 22)
	box.add_child(summary_title)

	var biomes := Label.new()
	biomes.text = "群系：%s" % " / ".join(active_region.get("dominant_biomes", []))
	biomes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(biomes)

	var stats := Label.new()
	stats.text = "群系块 %s · 栖息地 %s · 物种池 %s" % [
		str(summary.get("biome_count", 0)),
		str(summary.get("habitat_count", 0)),
		str(summary.get("species_pool_count", 0)),
	]
	box.add_child(stats)
	return panel


func _make_focus_card(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title := Label.new()
	title.text = "区域定位"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	var role := Label.new()
	role.text = str(active_region.get("region_role", "生态观测区"))
	role.add_theme_font_size_override("font_size", 18)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(role)

	var intro := Label.new()
	intro.text = str(active_region.get("region_intro", ""))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	return panel


func _make_intro_section(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title := Label.new()
	title.text = "区域档案"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = str(active_region.get("region_intro", "暂无区域档案。"))
	box.add_child(intro)
	return panel


func _make_species_section(top_species: Array) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "核心物种"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	for row_variant in top_species:
		var row: Dictionary = row_variant
		var card := PanelContainer.new()
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 10)
		card.add_child(row_box)

		var chip := Label.new()
		chip.text = "◉"
		chip.add_theme_font_size_override("font_size", 20)
		row_box.add_child(chip)

		var name := Label.new()
		name.text = str(row.get("label", row.get("species_id", "")))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.add_theme_font_size_override("font_size", 18)
		row_box.add_child(name)

		var count := Label.new()
		count.text = "× %s" % str(row.get("count", 0))
		count.add_theme_font_size_override("font_size", 18)
		row_box.add_child(count)
		box.add_child(card)
	return box


func _make_route_section(route_summary: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title := Label.new()
	title.text = "通道情报"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	for line in route_summary:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "• %s" % str(line)
		box.add_child(label)
	return panel


func _make_story_section(narrative: Dictionary) -> VBoxContainer:
	var story := VBoxContainer.new()
	story.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "区域播报"
	title.add_theme_font_size_override("font_size", 22)
	story.add_child(title)

	for key in ["territory", "social_trends", "grassland_chain", "carrion_chain", "wetland_chain", "symbiosis", "predation"]:
		for line in narrative.get(key, []):
			var item := Label.new()
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item.text = "• %s" % str(line)
			story.add_child(item)
	return story


func _make_badge_list(title_text: String, rows: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	for line in rows:
		var item := Label.new()
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.text = "◆ %s" % str(line)
		box.add_child(item)
	return panel


func _make_section(
	title_text: String,
	data: Variant,
	is_rows: bool = false,
	key_field: String = "key",
	value_field: String = "value"
) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	if is_rows:
		for row_variant in data:
			var row: Dictionary = row_variant
			var label := Label.new()
			if row.has(value_field):
				label.text = "%s: %.2f" % [str(row.get(key_field, "")), float(row.get(value_field, 0.0))]
			else:
				label.text = "%s → %s (%.2f)" % [
					str(row.get("target_region_id", "")),
					str(row.get("connection_type", "")),
					float(row.get("strength", 0.0)),
				]
			box.add_child(label)
	else:
		var items: Array = []
		for key in data.keys():
			items.append({"key": str(key), "value": float(data[key])})
		items.sort_custom(func(a, b): return a["value"] > b["value"])
		for item in items.slice(0, 5):
			var label := Label.new()
			label.text = "%s: %.2f" % [str(item["key"]), float(item["value"])]
			box.add_child(label)
	return box


func _on_region_pressed(region_id: String) -> void:
	active_region_id = region_id
	status_label.text = "已切换焦点区域：%s" % region_id
	for child in side_box.get_children():
		child.queue_free()
	_build_side_panel()


func _on_tab_pressed(tab_id: String) -> void:
	selected_tab = tab_id
	for child in side_box.get_children():
		child.queue_free()
	_build_side_panel()


func _on_auto_refresh_toggled(enabled: bool) -> void:
	if enabled:
		refresh_timer.start()
		status_label.text = "自动刷新已开启，每 2 秒重新读取一次世界状态。"
	else:
		refresh_timer.stop()
		status_label.text = "自动刷新已关闭。"

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

var world_data: Dictionary = {}
var active_region_id := ""
var title_label: Label
var subtitle_label: Label
var status_label: Label
var map_layer: Control
var side_panel: PanelContainer


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

	var footer_panel := PanelContainer.new()
	footer_panel.custom_minimum_size = Vector2(0, 46)
	root_vbox.add_child(footer_panel)

	status_label = Label.new()
	status_label.text = "先运行 Python 导出脚本生成 world_state.json"
	status_label.add_theme_font_size_override("font_size", 16)
	footer_panel.add_child(status_label)


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
	status_label.text = "Godot 世界地图前端骨架 · 中文界面 · 读取 Python 导出的世界状态"

	for child in map_layer.get_children():
		child.queue_free()
	for child in side_panel.get_children():
		child.queue_free()

	_build_map_nodes(world_meta.get("regions", []))
	_build_side_panel(world_data.get("active_region", {}), world_data.get("chains", {}), world_data.get("narrative", {}))


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
		button.text = "%s\n繁荣 %.2f / 风险 %.2f" % [
			str(region.get("name", region_id)),
			float(region.get("prosperity", 0.0)),
			float(region.get("collapse_risk", 0.0)),
		]
		button.custom_minimum_size = Vector2(220, 96)
		button.position = pos - button.custom_minimum_size / 2.0
		button.pressed.connect(_on_region_pressed.bind(region_id))
		map_layer.add_child(button)


func _build_side_panel(active_region: Dictionary, chains: Dictionary, narrative: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_child(scroll)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)

	var title := Label.new()
	title.text = "%s · 焦点区域" % str(active_region.get("name", "未选择"))
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	var climate := Label.new()
	climate.text = "气候带：%s" % str(active_region.get("climate_zone", "未知"))
	climate.add_theme_font_size_override("font_size", 18)
	box.add_child(climate)

	box.add_child(_make_section("健康状态", active_region.get("health_state", {})))
	box.add_child(_make_section("资源状态", active_region.get("resource_state", {})))
	box.add_child(_make_section("生态压力", active_region.get("ecological_pressures", {})))
	box.add_child(_make_section("社会相位", chains.get("social_phases", []), true))
	box.add_child(_make_section("草原主链", chains.get("grassland_chain", []), true))
	box.add_child(_make_section("尸体资源链", chains.get("carrion_chain", []), true))

	var story := VBoxContainer.new()
	var story_title := Label.new()
	story_title.text = "区域播报"
	story_title.add_theme_font_size_override("font_size", 22)
	story.add_child(story_title)

	for key in ["territory", "social_trends", "grassland_chain", "carrion_chain", "wetland_chain"]:
		for line in narrative.get(key, []):
			var item := Label.new()
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item.text = "• %s" % str(line)
			story.add_child(item)

	box.add_child(story)


func _make_section(title_text: String, data: Variant, is_rows: bool = false) -> VBoxContainer:
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
			label.text = "%s: %.2f" % [str(row.get("key", "")), float(row.get("value", 0.0))]
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
	status_label.text = "当前只是前端骨架。切换区域后，请重新导出 JSON 以同步 Python 世界状态。"

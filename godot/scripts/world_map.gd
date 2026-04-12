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


func _style_primary_title(label: Label, size: int = 22) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color8(245, 237, 215)


func _style_secondary_title(label: Label, size: int = 18) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color8(223, 215, 182)


func _style_body(label: Label, size: int = 15) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color8(214, 218, 222)


func _style_dim(label: Label, size: int = 14) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color8(170, 180, 188)


func _tab_accent_color(tab_id: String) -> Color:
	return {
		"overview": Color8(210, 182, 96),
		"chains": Color8(104, 171, 144),
		"species": Color8(171, 132, 196),
		"story": Color8(102, 152, 204),
	}.get(tab_id, Color8(210, 182, 96))


func _metric_icon(metric_key: String) -> String:
	return {
		"prosperity": "◎",
		"stability": "▲",
		"collapse_risk": "◆",
		"surface_water": "≈",
		"carcass_availability": "✦",
		"resilience": "◌",
		"predation_pressure": "⚑",
		"fragmentation": "◫",
	}.get(metric_key, "•")


func _story_accent(key: String) -> Color:
	return {
		"territory": Color8(171, 132, 196),
		"social_trends": Color8(102, 152, 204),
		"grassland_chain": Color8(104, 171, 144),
		"carrion_chain": Color8(171, 132, 196),
		"wetland_chain": Color8(102, 152, 204),
		"symbiosis": Color8(210, 182, 96),
		"predation": Color8(171, 132, 196),
	}.get(key, Color8(104, 171, 144))


func _story_title(key: String) -> String:
	return {
		"territory": "领地播报",
		"social_trends": "趋势播报",
		"grassland_chain": "草原主链播报",
		"carrion_chain": "尸体资源链播报",
		"wetland_chain": "湿地主链播报",
		"symbiosis": "共生播报",
		"predation": "捕食播报",
	}.get(key, "区域播报")


func _species_category(species_id: String) -> String:
	if species_id in ["lion", "hyena", "vulture", "nile_crocodile", "pike", "catfish", "blackfish"]:
		return "顶层种"
	if species_id in ["antelope", "zebra", "deer", "rabbit", "giraffe", "white_rhino", "african_elephant"]:
		return "草食群"
	if species_id in ["beaver", "frog", "kingfisher_v4", "duck", "sparrow", "owl", "woodpecker"]:
		return "岸带种"
	if species_id in ["small_fish", "minnow", "carp", "shrimp", "plankton", "pufferfish"]:
		return "水域种"
	return "区域种"


func _animate_side_panel_refresh() -> void:
	if side_panel == null:
		return
	side_panel.modulate = Color(1.0, 1.0, 1.0, 0.72)
	var tween := create_tween()
	tween.tween_property(side_panel, "modulate:a", 1.0, 0.18)


func _animate_tab_transition() -> void:
	if side_scroll == null:
		return
	side_scroll.modulate = Color(1.0, 1.0, 1.0, 0.0)
	side_scroll.position = Vector2(18, 0)
	var tween := create_tween()
	tween.tween_property(side_scroll, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(side_scroll, "position:x", 0.0, 0.22)


func _animate_status_flash(accent: Color = Color8(255, 240, 180)) -> void:
	if status_label == null:
		return
	status_label.modulate = accent.lightened(0.28)
	var tween := create_tween()
	tween.tween_property(status_label, "modulate", Color8(170, 180, 188), 0.28)


func _animate_region_transition(accent: Color) -> void:
	_animate_side_panel_refresh()
	_animate_status_flash(accent)
	if title_label != null:
		title_label.modulate = accent.lightened(0.38)
		var title_tween := create_tween()
		title_tween.tween_property(title_label, "modulate", Color8(245, 237, 215), 0.32)
	if subtitle_label != null:
		subtitle_label.modulate = accent.lightened(0.24)
		var subtitle_tween := create_tween()
		subtitle_tween.tween_property(subtitle_label, "modulate", Color8(223, 215, 182), 0.36)


func _animate_focus_glow(glow: ColorRect, focus_frame: ColorRect) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.92, 0.75)
	tween.parallel().tween_property(focus_frame, "modulate:a", 0.88, 0.75)
	tween.tween_property(glow, "modulate:a", 0.42, 0.75)
	tween.parallel().tween_property(focus_frame, "modulate:a", 0.38, 0.75)


func _animate_region_focus_entry(shell: PanelContainer, outer_ring: ColorRect, shadow: ColorRect, shell_base: Vector2, shadow_base: Vector2) -> void:
	shell.scale = Vector2(0.94, 0.94)
	shell.position = shell_base + Vector2(0, 12)
	shell.modulate = Color(1.0, 1.0, 1.0, 0.78)
	outer_ring.modulate = Color(1.0, 1.0, 1.0, 0.0)
	shadow.position = shadow_base + Vector2(0, 10)
	var tween := create_tween()
	tween.tween_property(shell, "scale", Vector2.ONE, 0.22)
	tween.parallel().tween_property(shell, "position", shell_base, 0.22)
	tween.parallel().tween_property(shell, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(outer_ring, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(shadow, "position", shadow_base, 0.22)


func _animate_region_hover(shell: PanelContainer, outer_ring: ColorRect, shadow: ColorRect, entering: bool) -> void:
	var tween := create_tween()
	if entering:
		tween.tween_property(shell, "scale", Vector2(1.03, 1.03), 0.12)
		tween.parallel().tween_property(outer_ring, "modulate:a", 0.86, 0.12)
		tween.parallel().tween_property(shadow, "modulate:a", 0.78, 0.12)
		tween.parallel().tween_property(shell, "position:y", shell.position.y - 5.0, 0.12)
	else:
		tween.tween_property(shell, "scale", Vector2.ONE, 0.14)
		tween.parallel().tween_property(outer_ring, "modulate:a", 1.0, 0.14)
		tween.parallel().tween_property(shadow, "modulate:a", 1.0, 0.14)
		tween.parallel().tween_property(shell, "position:y", floor(shell.position.y / 1.0), 0.14)


func _animate_region_press(shell: PanelContainer, pressed: bool) -> void:
	var tween := create_tween()
	if pressed:
		tween.tween_property(shell, "scale", Vector2(0.985, 0.985), 0.07)
	else:
		tween.tween_property(shell, "scale", Vector2.ONE, 0.09)


func _animate_tab_hover(button: Button, hover_color: Color, rest_color: Color, entering: bool) -> void:
	var tween := create_tween()
	if entering:
		tween.tween_property(button, "modulate", hover_color, 0.10)
		tween.parallel().tween_property(button, "scale", Vector2(1.02, 1.02), 0.10)
	else:
		tween.tween_property(button, "modulate", rest_color, 0.12)
		tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.12)


func _animate_card_hover(panel: PanelContainer, entering: bool) -> void:
	var tween := create_tween()
	if entering:
		tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.10)
		tween.parallel().tween_property(panel, "scale", Vector2(1.01, 1.01), 0.10)
	else:
		tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 0.96), 0.12)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.12)


func _tab_icon(tab_id: String) -> String:
	return {
		"overview": "◎",
		"chains": "≈",
		"species": "◉",
		"story": "✦",
	}.get(tab_id, "•")


func _tab_title(tab_id: String) -> String:
	return {
		"overview": "总览",
		"chains": "生态链",
		"species": "物种",
		"story": "播报",
	}.get(tab_id, "分页")


func _region_type_icon(active_region: Dictionary) -> String:
	var biomes: Array = active_region.get("dominant_biomes", [])
	var joined := " ".join(biomes)
	if "coral" in joined or "coast" in joined or "ocean" in joined:
		return "⚓"
	if "wetland" in joined or "lake" in joined or "river" in joined:
		return "≈"
	if "grassland" in joined or "shrubland" in joined:
		return "✦"
	if "forest" in joined or "rainforest" in joined:
		return "❖"
	return "◈"


func _region_type_label(active_region: Dictionary) -> String:
	var biomes: Array = active_region.get("dominant_biomes", [])
	var joined := " ".join(biomes)
	if "coral" in joined or "coast" in joined or "ocean" in joined:
		return "海域型区域"
	if "wetland" in joined or "lake" in joined or "river" in joined:
		return "湿地区域"
	if "grassland" in joined or "shrubland" in joined:
		return "草原区域"
	if "forest" in joined or "rainforest" in joined:
		return "森林区域"
	return "复合区域"


func _region_type_chip(active_region: Dictionary) -> String:
	var label := _region_type_label(active_region)
	return {
		"海域型区域": "海域徽记",
		"湿地区域": "湿地徽记",
		"草原区域": "草原徽记",
		"森林区域": "森林徽记",
		"复合区域": "复合徽记",
	}.get(label, "区域徽记")


func _active_region_accent() -> Color:
	return REGION_COLORS.get(active_region_id, Color8(210, 182, 96))


func _blend_ui_accent(base: Color, region: Color) -> Color:
	return Color(
		lerp(base.r, region.r, 0.42),
		lerp(base.g, region.g, 0.42),
		lerp(base.b, region.b, 0.42),
		0.96
	)


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
	header_panel.custom_minimum_size = Vector2(0, 112)
	root_vbox.add_child(header_panel)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	header_panel.add_child(header_box)

	var header_ribbon := ColorRect.new()
	header_ribbon.color = Color8(210, 182, 96)
	header_ribbon.custom_minimum_size = Vector2(0, 8)
	header_box.add_child(header_ribbon)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	header_box.add_child(title_row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 4)
	title_row.add_child(title_col)

	title_label = Label.new()
	title_label.text = "阿瑞利亚生态世界"
	_style_primary_title(title_label, 34)
	title_col.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "世界地图总控台"
	_style_secondary_title(subtitle_label, 18)
	title_col.add_child(subtitle_label)

	var control_row := HBoxContainer.new()
	control_row.add_theme_constant_override("separation", 10)
	title_row.add_child(control_row)

	refresh_button = Button.new()
	refresh_button.text = "刷新世界"
	refresh_button.custom_minimum_size = Vector2(138, 38)
	refresh_button.pressed.connect(_load_world_data)
	control_row.add_child(refresh_button)

	auto_refresh_button = CheckButton.new()
	auto_refresh_button.text = "自动刷新"
	auto_refresh_button.toggled.connect(_on_auto_refresh_toggled)
	control_row.add_child(auto_refresh_button)

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

	var footer_box := VBoxContainer.new()
	footer_box.add_theme_constant_override("separation", 4)
	footer_panel.add_child(footer_box)

	var footer_ribbon := ColorRect.new()
	footer_ribbon.color = Color8(210, 182, 96)
	footer_ribbon.custom_minimum_size = Vector2(0, 6)
	footer_box.add_child(footer_ribbon)

	status_label = Label.new()
	status_label.text = "系统栏 · 先运行 Python 导出脚本生成 world_state.json"
	_style_dim(status_label, 16)
	footer_box.add_child(status_label)

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
	status_label.text = "系统栏 · Godot 世界地图前端 · 中文界面 · 读取 Python 导出的世界状态"

	for child in map_layer.get_children():
		child.queue_free()
	for child in side_box.get_children():
		child.queue_free()

	_build_world_backdrop()
	_build_world_ambience()
	_build_route_lines(world_meta.get("regions", []))
	_build_map_nodes(world_meta.get("regions", []))
	_build_world_bulletin()
	_build_map_legend()
	_build_side_panel()


func _build_world_backdrop() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	var ocean := ColorRect.new()
	ocean.color = Color8(16, 37, 60, 255)
	ocean.position = Vector2.ZERO
	ocean.custom_minimum_size = map_size
	map_layer.add_child(ocean)

	var west_land := ColorRect.new()
	west_land.color = Color8(44, 74, 52, 180)
	west_land.position = Vector2(map_size.x * 0.06, map_size.y * 0.12)
	west_land.custom_minimum_size = Vector2(map_size.x * 0.47, map_size.y * 0.62)
	map_layer.add_child(west_land)

	var south_land := ColorRect.new()
	south_land.color = Color8(48, 86, 70, 168)
	south_land.position = Vector2(map_size.x * 0.30, map_size.y * 0.42)
	south_land.custom_minimum_size = Vector2(map_size.x * 0.28, map_size.y * 0.26)
	map_layer.add_child(south_land)

	var east_shelf := ColorRect.new()
	east_shelf.color = Color8(41, 73, 92, 165)
	east_shelf.position = Vector2(map_size.x * 0.66, map_size.y * 0.28)
	east_shelf.custom_minimum_size = Vector2(map_size.x * 0.23, map_size.y * 0.36)
	map_layer.add_child(east_shelf)

	var coral_band := ColorRect.new()
	coral_band.color = Color8(83, 58, 89, 150)
	coral_band.position = Vector2(map_size.x * 0.72, map_size.y * 0.64)
	coral_band.custom_minimum_size = Vector2(map_size.x * 0.20, map_size.y * 0.18)
	map_layer.add_child(coral_band)

	var west_label := Label.new()
	west_label.text = "西境大陆"
	west_label.position = Vector2(map_size.x * 0.12, map_size.y * 0.10)
	_style_primary_title(west_label, 28)
	map_layer.add_child(west_label)

	var sea_label := Label.new()
	sea_label.text = "东岸航海带"
	sea_label.position = Vector2(map_size.x * 0.70, map_size.y * 0.16)
	_style_secondary_title(sea_label, 24)
	map_layer.add_child(sea_label)

	var coral_label := Label.new()
	coral_label.text = "珊瑚群岛海"
	coral_label.position = Vector2(map_size.x * 0.73, map_size.y * 0.61)
	_style_secondary_title(coral_label, 22)
	map_layer.add_child(coral_label)


func _build_world_ambience() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var active_rel: Vector2 = REGION_LAYOUT.get(active_region_id, Vector2(0.5, 0.5))
	var active_pos := Vector2(map_size.x * active_rel.x, map_size.y * active_rel.y)
	var accent := _active_region_accent()

	var x := 0.0
	while x < map_size.x:
		var grid := ColorRect.new()
		grid.color = Color(1.0, 1.0, 1.0, 0.04)
		grid.position = Vector2(x, 0)
		grid.custom_minimum_size = Vector2(1, map_size.y)
		map_layer.add_child(grid)
		x += 96.0

	var y := 0.0
	while y < map_size.y:
		var grid := ColorRect.new()
		grid.color = Color(1.0, 1.0, 1.0, 0.035)
		grid.position = Vector2(0, y)
		grid.custom_minimum_size = Vector2(map_size.x, 1)
		map_layer.add_child(grid)
		y += 88.0

	for current in [
		{"from": Vector2(map_size.x * 0.63, map_size.y * 0.22), "to": Vector2(map_size.x * 0.82, map_size.y * 0.30)},
		{"from": Vector2(map_size.x * 0.70, map_size.y * 0.44), "to": Vector2(map_size.x * 0.90, map_size.y * 0.56)},
		{"from": Vector2(map_size.x * 0.74, map_size.y * 0.66), "to": Vector2(map_size.x * 0.90, map_size.y * 0.78)},
	]:
		var flow := _make_route_line(current["from"], current["to"], 0.85)
		flow.color = Color(0.70, 0.86, 0.97, 0.14)
		flow.custom_minimum_size = Vector2(flow.custom_minimum_size.x, 3.0)
		map_layer.add_child(flow)

	var horizon := ColorRect.new()
	horizon.color = Color(accent.r, accent.g, accent.b, 0.10)
	horizon.position = Vector2(0, active_pos.y - 2)
	horizon.custom_minimum_size = Vector2(map_size.x, 4)
	map_layer.add_child(horizon)

	var meridian := ColorRect.new()
	meridian.color = Color(accent.r, accent.g, accent.b, 0.10)
	meridian.position = Vector2(active_pos.x - 2, 0)
	meridian.custom_minimum_size = Vector2(4, map_size.y)
	map_layer.add_child(meridian)

	var aura := ColorRect.new()
	aura.color = Color(accent.r, accent.g, accent.b, 0.10)
	aura.position = active_pos - Vector2(118, 52)
	aura.custom_minimum_size = Vector2(236, 104)
	map_layer.add_child(aura)


func _build_route_lines(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	var positions := {}
	for region_variant in regions:
		var region: Dictionary = region_variant
		var region_id := str(region.get("id", ""))
		var rel: Vector2 = REGION_LAYOUT.get(region_id, Vector2(0.5, 0.5))
		positions[region_id] = Vector2(map_size.x * rel.x, map_size.y * rel.y)

	for region_variant in regions:
		var region: Dictionary = region_variant
		var from_id := str(region.get("id", ""))
		for connector_variant in region.get("connectors", []):
			var connector: Dictionary = connector_variant
			var to_id := str(connector.get("target_region_id", ""))
			if not positions.has(from_id) or not positions.has(to_id):
				continue
			if from_id > to_id:
				continue
			var is_active_route := from_id == active_region_id or to_id == active_region_id
			var line := _make_route_line(
				Vector2(positions[from_id]),
				Vector2(positions[to_id]),
				float(connector.get("strength", 0.0))
			)
			line.color = Color(
				0.94 if is_active_route else 0.74,
				0.89 if is_active_route else 0.80,
				0.62 if is_active_route else 0.58,
				clamp((0.42 if is_active_route else 0.18) + float(connector.get("strength", 0.0)) * (0.30 if is_active_route else 0.16), 0.18, 0.72)
			)
			line.custom_minimum_size = Vector2(line.custom_minimum_size.x, 6.0 if is_active_route else 3.0)
			map_layer.add_child(line)


func _make_route_line(from_pos: Vector2, to_pos: Vector2, strength: float) -> ColorRect:
	var delta := to_pos - from_pos
	var length := max(1.0, delta.length())
	var angle := delta.angle()
	var line := ColorRect.new()
	line.color = Color(0.88, 0.89, 0.70, clamp(0.16 + strength * 0.24, 0.18, 0.42))
	line.position = from_pos.lerp(to_pos, 0.5) - Vector2(length * 0.5, 2.0)
	line.custom_minimum_size = Vector2(length, 4.0)
	line.rotation = angle
	return line


func _build_map_nodes(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	for region_variant in regions:
		var region: Dictionary = region_variant
		var region_id := str(region.get("id", ""))
		var rel: Vector2 = REGION_LAYOUT.get(region_id, Vector2(0.5, 0.5))
		var pos := Vector2(map_size.x * rel.x, map_size.y * rel.y)
		var accent := REGION_COLORS.get(region_id, Color8(110, 140, 170))
		var is_active := region_id == active_region_id

		var shadow := ColorRect.new()
		shadow.color = Color(0.03, 0.06, 0.09, 0.45 if is_active else 0.28)
		var shadow_base := pos - Vector2(126, 54) + Vector2(8, 8)
		shadow.position = shadow_base
		shadow.custom_minimum_size = Vector2(252, 112)
		map_layer.add_child(shadow)

		var outer_ring := ColorRect.new()
		outer_ring.color = Color(accent.r, accent.g, accent.b, 0.18 if is_active else 0.10)
		outer_ring.position = pos - Vector2(132, 60)
		outer_ring.custom_minimum_size = Vector2(264, 124)
		map_layer.add_child(outer_ring)

		var shell := PanelContainer.new()
		var shell_base := pos - Vector2(126, 54)
		shell.position = shell_base
		shell.custom_minimum_size = Vector2(252, 112)
		shell.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_active else 0.76)
		map_layer.add_child(shell)

		if is_active:
			var glow := ColorRect.new()
			glow.color = Color(1.0, 0.92, 0.58, 0.16)
			glow.position = shell.position - Vector2(14, 12)
			glow.custom_minimum_size = shell.custom_minimum_size + Vector2(28, 24)
			map_layer.add_child(glow)
			map_layer.move_child(glow, map_layer.get_child_count() - 2)

			var focus_frame := ColorRect.new()
			focus_frame.color = Color(1.0, 0.92, 0.58, 0.28)
			focus_frame.position = shell.position - Vector2(4, 4)
			focus_frame.custom_minimum_size = shell.custom_minimum_size + Vector2(8, 8)
			map_layer.add_child(focus_frame)
			map_layer.move_child(focus_frame, map_layer.get_child_count() - 2)
			_animate_region_focus_entry(shell, outer_ring, shadow, shell_base, shadow_base)
			_animate_focus_glow(glow, focus_frame)

		var shell_box := VBoxContainer.new()
		shell_box.add_theme_constant_override("separation", 4)
		shell.add_child(shell_box)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 10)
		shell_box.add_child(header)

		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(58, 58)
		header.add_child(icon_panel)

		var icon := Label.new()
		icon.text = REGION_ICONS.get(region_id, "区")
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.custom_minimum_size = Vector2(58, 58)
		icon.add_theme_font_size_override("font_size", 30)
		icon_panel.add_child(icon)

		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(text_box)

		var name := Label.new()
		name.text = str(region.get("name", region_id))
		_style_primary_title(name, 20)
		text_box.add_child(name)

		var role := Label.new()
		role.text = "繁荣 %.2f · 风险 %.2f" % [
			float(region.get("prosperity", 0.0)),
			float(region.get("collapse_risk", 0.0)),
		]
		_style_body(role, 15)
		text_box.add_child(role)

		var state_chip := Label.new()
		state_chip.text = "当前焦点" if region_id == active_region_id else "可进入"
		_style_dim(state_chip, 13)
		text_box.add_child(state_chip)

		var footer := Label.new()
		footer.text = "种群 %s · %s" % [
			str(region.get("species_population", 0)),
			"已锁定情报" if region_id == active_region_id else "点击进入区域情报",
		]
		_style_dim(footer, 15)
		shell_box.add_child(footer)

		var button := Button.new()
		button.text = ""
		button.flat = true
		button.custom_minimum_size = shell.custom_minimum_size
		button.position = shell.position
		button.pressed.connect(_on_region_pressed.bind(region_id))
		button.mouse_entered.connect(func() -> void:
			shadow.position = shadow_base + Vector2(12, 11)
			_animate_region_hover(shell, outer_ring, shadow, true)
		)
		button.mouse_exited.connect(func() -> void:
			shadow.position = shadow_base
			shell.position = shell_base
			_animate_region_hover(shell, outer_ring, shadow, false)
		)
		button.button_down.connect(func() -> void:
			_animate_region_press(shell, true)
		)
		button.button_up.connect(func() -> void:
			_animate_region_press(shell, false)
		)
		map_layer.add_child(button)

		var badge := Label.new()
		badge.text = REGION_ICONS.get(region_id, "区")
		badge.position = shell.position + Vector2(16, 12)
		badge.add_theme_font_size_override("font_size", 30)
		badge.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_active else 0.72)
		map_layer.add_child(badge)

		var plaque := PanelContainer.new()
		plaque.position = shell.position + Vector2(12, 78)
		plaque.custom_minimum_size = Vector2(116, 22)
		map_layer.add_child(plaque)

		var plaque_label := Label.new()
		plaque_label.text = str(region.get("name", region_id))
		_style_dim(plaque_label, 13)
		plaque_label.modulate = Color(0.78, 0.82, 0.86, 1.0 if is_active else 0.72)
		plaque.add_child(plaque_label)


func _build_world_bulletin() -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	panel.position = Vector2(24, 20)
	map_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = Color8(102, 152, 204)
	ribbon.custom_minimum_size = Vector2(0, 8)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "世界播报 · 指挥台"
	_style_primary_title(title, 22)
	box.add_child(title)

	var focus_card := PanelContainer.new()
	box.add_child(focus_card)

	var focus_box := VBoxContainer.new()
	focus_box.add_theme_constant_override("separation", 4)
	focus_card.add_child(focus_box)

	var focus_tag := Label.new()
	focus_tag.text = "焦点区域提示"
	_style_secondary_title(focus_tag, 16)
	focus_box.add_child(focus_tag)

	var focus_line := Label.new()
	focus_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	focus_line.text = "%s · %s" % [
		str(active_region.get("name", "未选择区域")),
		str(active_region.get("region_role", "生态观测区")),
	]
	_style_body(focus_line, 15)
	focus_box.add_child(focus_line)

	if not bulletin_cache.is_empty():
		var lead_card := PanelContainer.new()
		box.add_child(lead_card)

		var lead_box := VBoxContainer.new()
		lead_box.add_theme_constant_override("separation", 4)
		lead_card.add_child(lead_box)

		var lead_tag := Label.new()
		lead_tag.text = "主主播报"
		_style_secondary_title(lead_tag, 16)
		lead_box.add_child(lead_tag)

		var lead_item := Label.new()
		lead_item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lead_item.text = str(bulletin_cache[0])
		_style_body(lead_item, 16)
		lead_box.add_child(lead_item)

	if bulletin_cache.size() > 1:
		var digest_card := PanelContainer.new()
		box.add_child(digest_card)

		var digest_box := VBoxContainer.new()
		digest_box.add_theme_constant_override("separation", 4)
		digest_card.add_child(digest_box)

		var digest_tag := Label.new()
		digest_tag.text = "动态简报"
		_style_secondary_title(digest_tag, 16)
		digest_box.add_child(digest_tag)

		for line in bulletin_cache.slice(1, 4):
			var item := Label.new()
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item.text = "• %s" % str(line)
			_style_body(item, 15)
			digest_box.add_child(item)


func _build_map_legend() -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	panel.position = Vector2(max(24, map_layer.size.x - 250), 20)
	map_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = Color8(210, 182, 96)
	ribbon.custom_minimum_size = Vector2(0, 8)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "地图图例 · 航线层"
	_style_primary_title(title, 20)
	box.add_child(title)

	var focus_row := HBoxContainer.new()
	focus_row.add_theme_constant_override("separation", 8)
	box.add_child(focus_row)

	var focus_swatch := ColorRect.new()
	focus_swatch.color = _active_region_accent()
	focus_swatch.custom_minimum_size = Vector2(14, 14)
	focus_row.add_child(focus_swatch)

	var focus_label := Label.new()
	var biome_text := " / ".join(active_region.get("dominant_biomes", []).slice(0, 2))
	focus_label.text = "焦点地貌 · %s" % (biome_text if biome_text != "" else str(active_region.get("name", "未选择")))
	_style_body(focus_label, 15)
	focus_row.add_child(focus_label)

	for entry_variant in legend_cache.slice(0, 5):
		var entry: Dictionary = entry_variant
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)

		var swatch := ColorRect.new()
		swatch.color = {
			"forest": Color8(78, 137, 96),
			"grassland": Color8(198, 173, 96),
			"wetland": Color8(92, 154, 162),
			"coast": Color8(80, 141, 191),
			"coral": Color8(203, 132, 177),
		}.get(str(entry.get("color", "")), Color8(210, 210, 210))
		swatch.custom_minimum_size = Vector2(14, 14)
		row.add_child(swatch)

		var label := Label.new()
		label.text = str(entry.get("label", ""))
		_style_body(label, 15)
		row.add_child(label)


func _build_side_panel() -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var chains: Dictionary = active_region.get("chains", world_data.get("chains", {}))
	var narrative: Dictionary = active_region.get("narrative", world_data.get("narrative", {}))
	var top_species: Array = active_region.get("top_species", [])
	var route_summary: Array = active_region.get("route_summary", [])
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var chain_focus: Array = active_region.get("chain_focus", [])
	var region_accent := _active_region_accent()

	var title := Label.new()
	title.text = "%s · 焦点区域" % str(active_region.get("name", "未选择"))
	_style_primary_title(title, 28)
	title.modulate = region_accent.lightened(0.35)
	side_box.add_child(title)

	var climate := Label.new()
	climate.text = str(active_region.get("region_role", "生态观测区"))
	_style_secondary_title(climate, 18)
	climate.modulate = region_accent.lightened(0.18)
	side_box.add_child(climate)
	side_box.add_child(_make_status_strip(active_region, region_accent))
	side_box.add_child(_make_tabs(region_accent))

	match selected_tab:
		"overview":
			side_box.add_child(_make_tab_banner("总览指挥台", "查看区域定位、健康、资源与当前风险。", _tab_accent_color("overview"), region_accent, active_region))
			side_box.add_child(_make_focus_card(active_region))
			side_box.add_child(_make_region_summary_card(active_region))
			side_box.add_child(_make_badge_list("风险焦点", pressure_headlines, active_region))
			side_box.add_child(_make_badge_list("主导生态链", chain_focus, active_region))
			side_box.add_child(_make_section("健康状态", active_region.get("health_state", {})))
			side_box.add_child(_make_section("资源状态", active_region.get("resource_state", {})))
			side_box.add_child(_make_section("生态压力", active_region.get("ecological_pressures", {})))
			side_box.add_child(_make_section("区域连接", active_region.get("connectors", []), true, "target_region_id", "strength"))
			side_box.add_child(_make_route_section(route_summary, active_region))
			side_box.add_child(_make_intro_section(active_region))
		"chains":
			side_box.add_child(_make_tab_banner("生态链监测", "读取社会相位、草原主链、尸体资源链与竞争压力。", _tab_accent_color("chains"), region_accent, active_region))
			side_box.add_child(_make_section("社会相位", chains.get("social_phases", []), true))
			side_box.add_child(_make_section("草原主链", chains.get("grassland_chain", []), true))
			side_box.add_child(_make_section("尸体资源链", chains.get("carrion_chain", []), true))
			side_box.add_child(_make_section("湿地主链", chains.get("wetland_chain", []), true))
			side_box.add_child(_make_section("领地压力", chains.get("territory", []), true))
			side_box.add_child(_make_section("竞争压力", chains.get("competition", []), true))
			side_box.add_child(_make_section("捕食压力", chains.get("predation", []), true))
		"species":
			side_box.add_child(_make_tab_banner("物种图鉴", "查看%s当前最核心的关键物种与数量。" % _region_type_label(active_region), _tab_accent_color("species"), region_accent, active_region))
			side_box.add_child(_make_species_section(top_species, active_region))
		"story":
			side_box.add_child(_make_tab_banner("区域播报室", "汇总%s中的领地、趋势、链路和关系层即时叙事。" % _region_type_label(active_region), _tab_accent_color("story"), region_accent, active_region))
			side_box.add_child(_make_story_section(narrative, active_region))

func _make_tabs(region_accent: Color) -> HBoxContainer:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	for tab_id in ["overview", "chains", "species", "story"]:
		var button := Button.new()
		var is_active := tab_id == selected_tab
		button.text = "%s %s%s" % [
			_tab_icon(tab_id),
			_tab_title(tab_id),
			" · 当前" if is_active else "",
		]
		button.toggle_mode = true
		button.button_pressed = is_active
		button.custom_minimum_size = Vector2(112, 40)
		var tab_color := _tab_accent_color(tab_id)
		var rest_color := region_accent.lightened(0.12) if is_active else tab_color.darkened(0.12)
		var hover_color := region_accent.lightened(0.24) if is_active else tab_color.lightened(0.12)
		button.modulate = rest_color
		button.mouse_entered.connect(func() -> void:
			_animate_tab_hover(button, hover_color, rest_color, true)
		)
		button.mouse_exited.connect(func() -> void:
			_animate_tab_hover(button, hover_color, rest_color, false)
		)
		button.pressed.connect(_on_tab_pressed.bind(tab_id))
		tabs.add_child(button)
	return tabs


func _make_status_strip(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	row.add_child(_make_status_chip("繁荣", "◎", "%.2f" % float(active_region.get("health_state", {}).get("prosperity", 0.0)), region_accent))
	row.add_child(_make_status_chip("稳定", "▲", "%.2f" % float(active_region.get("health_state", {}).get("stability", 0.0)), region_accent))
	row.add_child(_make_status_chip("风险", "◆", "%.2f" % float(active_region.get("health_state", {}).get("collapse_risk", 0.0)), region_accent))
	return panel


func _make_tab_banner(title_text: String, description: String, accent: Color, region_accent: Color, active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = _blend_ui_accent(accent, region_accent)
	ribbon.custom_minimum_size = Vector2(0, 8)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "%s %s" % [_region_type_icon(active_region), title_text]
	_style_primary_title(title, 24)
	title.modulate = region_accent.lightened(0.24)
	box.add_child(title)

	var body := Label.new()
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(body, 15)
	box.add_child(body)
	return panel


func _make_status_chip(title_text: String, icon_text: String, value_text: String, region_accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(108, 56)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var icon := Label.new()
	icon.text = icon_text
	_style_secondary_title(icon, 20)
	icon.modulate = region_accent.lightened(0.22)
	box.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 2)
	box.add_child(text_box)

	var title := Label.new()
	title.text = title_text
	_style_dim(title, 14)
	text_box.add_child(title)

	var value := Label.new()
	value.text = value_text
	_style_primary_title(value, 22)
	value.modulate = region_accent.lightened(0.30)
	text_box.add_child(value)
	return panel


func _wrap_menu_card(content: Control, accent: Color = Color8(88, 110, 126)) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.modulate = Color(1.0, 1.0, 1.0, 0.96)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var accent_bar := ColorRect.new()
	accent_bar.color = accent
	accent_bar.custom_minimum_size = Vector2(0, 4)
	box.add_child(accent_bar)
	box.add_child(content)
	panel.mouse_entered.connect(func() -> void:
		_animate_card_hover(panel, true)
	)
	panel.mouse_exited.connect(func() -> void:
		_animate_card_hover(panel, false)
	)
	return panel


func _make_region_summary_card(active_region: Dictionary) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var summary := active_region.get("region_summary", {})
	var summary_title := Label.new()
	summary_title.text = "%s · 区域概况" % _region_type_chip(active_region)
	_style_primary_title(summary_title, 22)
	box.add_child(summary_title)

	var biomes := Label.new()
	biomes.text = "群系：%s" % " / ".join(active_region.get("dominant_biomes", []))
	biomes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_body(biomes, 15)
	box.add_child(biomes)

	var stats := Label.new()
	stats.text = "群系块 %s · 栖息地 %s · 物种池 %s" % [
		str(summary.get("biome_count", 0)),
		str(summary.get("habitat_count", 0)),
		str(summary.get("species_pool_count", 0)),
	]
	_style_dim(stats, 15)
	box.add_child(stats)
	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_focus_card(active_region: Dictionary) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "%s · 区域定位" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var role := Label.new()
	role.text = str(active_region.get("region_role", "生态观测区"))
	_style_secondary_title(role, 18)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(role)

	var intro := Label.new()
	intro.text = str(active_region.get("region_intro", ""))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_body(intro, 15)
	box.add_child(intro)
	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_intro_section(active_region: Dictionary) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "%s · 区域档案" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = str(active_region.get("region_intro", "暂无区域档案。"))
	_style_body(intro, 15)
	box.add_child(intro)
	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_species_section(top_species: Array, active_region: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "核心物种"
	_style_primary_title(title, 22)
	box.add_child(title)
	for row_variant in top_species:
		var row: Dictionary = row_variant
		var card := PanelContainer.new()
		var row_box := VBoxContainer.new()
		row_box.add_theme_constant_override("separation", 4)
		card.add_child(row_box)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 10)
		row_box.add_child(header)

		var chip := Label.new()
		chip.text = "◉"
		_style_secondary_title(chip, 20)
		header.add_child(chip)

		var name := Label.new()
		name.text = str(row.get("label", row.get("species_id", "")))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_body(name, 18)
		header.add_child(name)

		var count := Label.new()
		count.text = "× %s" % str(row.get("count", 0))
		_style_secondary_title(count, 18)
		header.add_child(count)

		var category := Label.new()
		category.text = "%s · %s" % [_region_type_chip(active_region), _species_category(str(row.get("species_id", "")))]
		_style_dim(category, 14)
		row_box.add_child(category)

		var meter_bg := ColorRect.new()
		meter_bg.color = Color(1.0, 1.0, 1.0, 0.08)
		meter_bg.custom_minimum_size = Vector2(0, 6)
		row_box.add_child(meter_bg)

		var meter := ColorRect.new()
		meter.color = Color(171.0 / 255.0, 132.0 / 255.0, 196.0 / 255.0, 0.72)
		meter.custom_minimum_size = Vector2(220.0 * clamp(float(row.get("count", 0)) / 40.0, 0.05, 1.0), 6)
		row_box.add_child(meter)
		box.add_child(card)
	return box


func _make_route_section(route_summary: Array, active_region: Dictionary) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "%s · 通道情报" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	for line in route_summary:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "• %s" % str(line)
		_style_body(label, 15)
		box.add_child(label)
	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_story_section(narrative: Dictionary, active_region: Dictionary) -> VBoxContainer:
	var story := VBoxContainer.new()
	story.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "区域播报"
	_style_primary_title(title, 22)
	story.add_child(title)

	var system_card := PanelContainer.new()
	story.add_child(system_card)

	var system_box := VBoxContainer.new()
	system_box.add_theme_constant_override("separation", 4)
	system_card.add_child(system_box)

	var system_tag := Label.new()
	system_tag.text = "系统级播报"
	_style_secondary_title(system_tag, 18)
	system_box.add_child(system_tag)

	var system_body := Label.new()
	system_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	system_body.text = "左上角世界播报负责汇总跨区域动态，这里则专注当前焦点区域的局部情报。"
	_style_dim(system_body, 15)
	system_box.add_child(system_body)

	var region_tag := Label.new()
	region_tag.text = "区域级播报"
	_style_secondary_title(region_tag, 18)
	story.add_child(region_tag)

	for key in ["territory", "social_trends", "grassland_chain", "carrion_chain", "wetland_chain", "symbiosis", "predation"]:
		var rows: Array = narrative.get(key, [])
		if rows.is_empty():
			continue

		var card := PanelContainer.new()
		story.add_child(card)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)

		var ribbon := ColorRect.new()
		ribbon.color = _story_accent(key)
		ribbon.custom_minimum_size = Vector2(0, 6)
		box.add_child(ribbon)

		var section_title := Label.new()
		section_title.text = "%s · %s" % [_region_type_chip(active_region), _story_title(key)]
		_style_secondary_title(section_title, 18)
		box.add_child(section_title)

		for line in rows:
			var item := Label.new()
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item.text = "• %s" % str(line)
			_style_body(item, 15)
			box.add_child(item)
	return story


func _make_badge_list(title_text: String, rows: Array, active_region: Dictionary) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "%s · %s" % [_region_type_chip(active_region), title_text]
	_style_primary_title(title, 22)
	box.add_child(title)

	for line in rows:
		var item := Label.new()
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.text = "◆ %s" % str(line)
		_style_body(item, 15)
		box.add_child(item)
	var accent := Color8(104, 171, 144)
	if title_text == "风险焦点":
		accent = Color8(171, 132, 196)
	return _wrap_menu_card(box, accent)


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
	_style_primary_title(title, 22)
	box.add_child(title)

	var accent := Color8(210, 182, 96)
	if title_text == "区域连接":
		accent = Color8(102, 152, 204)
	elif title_text in ["社会相位", "草原主链", "尸体资源链", "湿地主链"]:
		accent = Color8(104, 171, 144)
	elif title_text in ["领地压力", "竞争压力", "捕食压力"]:
		accent = Color8(171, 132, 196)

	if is_rows:
		for row_variant in data:
			var row: Dictionary = row_variant
			var row_card := PanelContainer.new()
			box.add_child(row_card)

			var row_box := VBoxContainer.new()
			row_box.add_theme_constant_override("separation", 4)
			row_card.add_child(row_box)

			var header := HBoxContainer.new()
			header.add_theme_constant_override("separation", 8)
			row_box.add_child(header)

			var icon := Label.new()
			icon.text = "◈"
			_style_secondary_title(icon, 18)
			header.add_child(icon)

			var name := Label.new()
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if row.has(value_field):
				name.text = str(row.get(key_field, ""))
			else:
				name.text = "%s → %s" % [
					str(row.get("target_region_id", "")),
					str(row.get("connection_type", "")),
				]
			_style_secondary_title(name, 16)
			header.add_child(name)

			var value := Label.new()
			if row.has(value_field):
				value.text = "%.2f" % float(row.get(value_field, 0.0))
			else:
				value.text = "%.2f" % float(row.get("strength", 0.0))
			_style_primary_title(value, 18)
			value.modulate = accent.lightened(0.28)
			header.add_child(value)

			if not row.has(value_field):
				var meta := Label.new()
				meta.text = "连接类型 · %s" % str(row.get("connection_type", ""))
				_style_dim(meta, 13)
				row_box.add_child(meta)

			var meter_bg := ColorRect.new()
			meter_bg.color = Color(1.0, 1.0, 1.0, 0.08)
			meter_bg.custom_minimum_size = Vector2(0, 6)
			row_box.add_child(meter_bg)

			var raw_value := float(row.get(value_field, row.get("strength", 0.0)))
			var meter := ColorRect.new()
			meter.color = Color(accent.r, accent.g, accent.b, 0.72)
			meter.custom_minimum_size = Vector2(220.0 * clamp(raw_value, 0.0, 1.0), 6)
			row_box.add_child(meter)
	else:
		var items: Array = []
		for key in data.keys():
			items.append({"key": str(key), "value": float(data[key])})
		items.sort_custom(func(a, b): return a["value"] > b["value"])
		for item in items.slice(0, 5):
			var row_card := PanelContainer.new()
			box.add_child(row_card)

			var row_box := VBoxContainer.new()
			row_box.add_theme_constant_override("separation", 4)
			row_card.add_child(row_box)

			var header := HBoxContainer.new()
			header.add_theme_constant_override("separation", 8)
			row_box.add_child(header)

			var icon := Label.new()
			icon.text = _metric_icon(str(item["key"]))
			_style_secondary_title(icon, 18)
			header.add_child(icon)

			var name := Label.new()
			name.text = str(item["key"])
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_secondary_title(name, 16)
			header.add_child(name)

			var value := Label.new()
			value.text = "%.2f" % float(item["value"])
			_style_primary_title(value, 18)
			value.modulate = accent.lightened(0.28)
			header.add_child(value)

			var meter_bg := ColorRect.new()
			meter_bg.color = Color(1.0, 1.0, 1.0, 0.08)
			meter_bg.custom_minimum_size = Vector2(0, 6)
			row_box.add_child(meter_bg)

			var meter := ColorRect.new()
			meter.color = Color(accent.r, accent.g, accent.b, 0.72)
			meter.custom_minimum_size = Vector2(220.0 * clamp(float(item["value"]), 0.0, 1.0), 6)
			row_box.add_child(meter)
	var wrapper := VBoxContainer.new()
	wrapper.add_child(_wrap_menu_card(box, accent))
	return wrapper


func _on_region_pressed(region_id: String) -> void:
	active_region_id = region_id
	status_label.text = "系统栏 · 已切换焦点区域：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_region_transition(_active_region_accent())


func _on_tab_pressed(tab_id: String) -> void:
	selected_tab = tab_id
	status_label.text = "系统栏 · 已切换功能分页：%s" % _tab_title(tab_id)
	for child in side_box.get_children():
		child.queue_free()
	_build_side_panel()
	_animate_tab_transition()
	_animate_region_transition(_active_region_accent())


func _on_auto_refresh_toggled(enabled: bool) -> void:
	if enabled:
		refresh_timer.start()
		status_label.text = "系统栏 · 自动刷新已开启，每 2 秒重新读取一次世界状态。"
	else:
		refresh_timer.stop()
		status_label.text = "系统栏 · 自动刷新已关闭。"

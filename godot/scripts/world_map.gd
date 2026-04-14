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
var selected_frontier_target_id := ""
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


func _animate_status_strip_flash(accent: Color) -> void:
	if side_box == null:
		return
	for child in side_box.get_children():
		if child is PanelContainer and child.has_meta("status_strip"):
			var panel := child as PanelContainer
			panel.modulate = accent.lightened(0.16)
			panel.scale = Vector2(1.015, 1.015)
			var tween := create_tween()
			tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.26)
			tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.26)
			break


func _animate_status_strip_page_flash(region_accent: Color, tab_accent: Color) -> void:
	if side_box == null:
		return
	var flash := _blend_ui_accent(tab_accent, region_accent)
	for child in side_box.get_children():
		if child is PanelContainer and child.has_meta("status_strip"):
			var panel := child as PanelContainer
			panel.modulate = flash.lightened(0.08)
			panel.scale = Vector2(1.008, 1.008)
			var tween := create_tween()
			tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
			tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18)
			break


func _animate_region_transition(accent: Color) -> void:
	_animate_side_panel_refresh()
	_animate_status_flash(accent)
	_animate_status_strip_flash(accent)
	if title_label != null:
		title_label.modulate = accent.lightened(0.38)
		var title_tween := create_tween()
		title_tween.tween_property(title_label, "modulate", Color8(245, 237, 215), 0.32)
	if subtitle_label != null:
		subtitle_label.modulate = accent.lightened(0.24)
		var subtitle_tween := create_tween()
		subtitle_tween.tween_property(subtitle_label, "modulate", Color8(223, 215, 182), 0.36)


func _animate_page_transition(region_accent: Color, tab_accent: Color) -> void:
	_animate_tab_transition()
	_animate_side_panel_refresh()
	_animate_status_flash(_blend_ui_accent(tab_accent, region_accent))
	_animate_status_strip_page_flash(region_accent, tab_accent)
	if subtitle_label != null:
		subtitle_label.modulate = _blend_ui_accent(tab_accent, region_accent).lightened(0.12)
		var subtitle_tween := create_tween()
		subtitle_tween.tween_property(subtitle_label, "modulate", Color8(223, 215, 182), 0.24)


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


func _connection_type_icon(connection_type: String) -> String:
	return {
		"land_corridor": "⇄",
		"river_network": "≈",
		"coastal_exchange": "⚓",
		"air_migration_lane": "➶",
	}.get(connection_type, "⇢")


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
	_sync_frontier_focus()

	for child in map_layer.get_children():
		child.queue_free()
	for child in side_box.get_children():
		child.queue_free()

	_build_world_backdrop()
	_build_world_ambience()
	_build_focus_stage(world_meta.get("regions", []))
	_build_route_lines(world_meta.get("regions", []))
	_build_frontier_network_overlay(world_meta.get("regions", []))
	_build_map_nodes(world_meta.get("regions", []))
	_build_map_command_layer()
	_build_side_panel()


func _sync_frontier_focus() -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var frontier_links: Array = active_region.get("frontier_links", [])
	if frontier_links.is_empty():
		selected_frontier_target_id = ""
		return
	for link_variant in frontier_links:
		var link: Dictionary = link_variant
		if str(link.get("target_region_id", "")) == selected_frontier_target_id:
			return
	selected_frontier_target_id = str((frontier_links[0] as Dictionary).get("target_region_id", ""))


func _active_frontier_link(active_region: Dictionary) -> Dictionary:
	var frontier_links: Array = active_region.get("frontier_links", [])
	if frontier_links.is_empty():
		return {}
	for link_variant in frontier_links:
		var link: Dictionary = link_variant
		if str(link.get("target_region_id", "")) == selected_frontier_target_id:
			return link
	return frontier_links[0]


func _active_frontier_network(active_region: Dictionary) -> Dictionary:
	var frontier_network: Array = active_region.get("frontier_network", [])
	if frontier_network.is_empty():
		return {}
	for network_variant in frontier_network:
		var network: Dictionary = network_variant
		if str(network.get("target_region_id", "")) == selected_frontier_target_id:
			return network
	return frontier_network[0]


func _frontier_branch_line(branches: Array, index: int = 0) -> String:
	if branches.size() <= index:
		return "等待更多网络分支"
	var branch: Dictionary = branches[index]
	return "%s · %s %.2f" % [
		str(branch.get("target_name", branch.get("target_region_id", ""))),
		str(branch.get("connection_label", "区域通道")),
		float(branch.get("strength", 0.0)),
	]


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


func _region_positions(regions: Array, map_size: Vector2) -> Dictionary:
	var positions := {}
	for region_variant in regions:
		var region: Dictionary = region_variant
		var region_id := str(region.get("id", ""))
		var rel: Vector2 = REGION_LAYOUT.get(region_id, Vector2(0.5, 0.5))
		positions[region_id] = Vector2(map_size.x * rel.x, map_size.y * rel.y)
	return positions


func _build_focus_stage(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var accent := _active_region_accent()
	var chain_focus: Array = active_region.get("chain_focus", [])
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var route_summary: Array = active_region.get("route_summary", [])
	var top_species: Array = active_region.get("top_species", [])
	var active_frontier := _active_frontier_link(active_region)
	var active_frontier_network := _active_frontier_network(active_region)
	var header_copy := _region_command_header(active_region)
	var stage_profile := _focus_stage_profile(active_region, active_frontier, active_frontier_network)
	var stage := PanelContainer.new()
	stage.custom_minimum_size = Vector2(360, 150)
	stage.position = Vector2(map_size.x * 0.34, map_size.y * 0.38)
	map_layer.add_child(stage)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	stage.add_child(root)

	var ribbon := ColorRect.new()
	ribbon.color = accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 10)
	root.add_child(ribbon)

	var eyebrow := Label.new()
	eyebrow.text = "%s · %s · %s" % [_region_type_chip(active_region), header_copy["eyebrow"], str(stage_profile["mode"])]
	_style_dim(eyebrow, 13)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(eyebrow)

	var title := Label.new()
	title.text = str(active_region.get("name", "未选择"))
	_style_primary_title(title, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = accent.lightened(0.26)
	root.add_child(title)

	var role := Label.new()
	role.text = str(header_copy["subtitle"])
	_style_secondary_title(role, 17)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.modulate = accent.lightened(0.16)
	root.add_child(role)

	var center_row := HBoxContainer.new()
	center_row.add_theme_constant_override("separation", 8)
	root.add_child(center_row)
	for item_variant in stage_profile["hero_rows"]:
		var item: Dictionary = item_variant
		center_row.add_child(_make_hero_chip(str(item["label"]), str(item["value"]), item["color"]))

	var footer := Label.new()
	footer.text = "已加载区域 %s · 地图节点 %s" % [
		str(world_data.get("world", {}).get("loaded_regions", 0)),
		str(regions.size()),
	]
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_dim(footer, 13)
	root.add_child(footer)

	var sub_stage := PanelContainer.new()
	sub_stage.custom_minimum_size = Vector2(260, 112)
	sub_stage.position = stage.position + Vector2(32, 166)
	map_layer.add_child(sub_stage)

	var sub_box := VBoxContainer.new()
	sub_box.add_theme_constant_override("separation", 6)
	sub_stage.add_child(sub_box)

	var sub_ribbon := ColorRect.new()
	sub_ribbon.color = Color8(104, 171, 144)
	sub_ribbon.custom_minimum_size = Vector2(0, 8)
	sub_box.add_child(sub_ribbon)

	var sub_title := Label.new()
	sub_title.text = "%s · %s" % [_region_type_chip(active_region), str(stage_profile["substage_title"])]
	_style_secondary_title(sub_title, 18)
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_box.add_child(sub_title)

	sub_box.add_child(_make_hero_chip(str(stage_profile["sub_primary"]["label"]), str(stage_profile["sub_primary"]["value"]), stage_profile["sub_primary"]["color"]))
	sub_box.add_child(_make_hero_chip(str(stage_profile["sub_secondary"]["label"]), str(stage_profile["sub_secondary"]["value"]), stage_profile["sub_secondary"]["color"]))

	var signal_strip := PanelContainer.new()
	signal_strip.custom_minimum_size = Vector2(420, 72)
	signal_strip.position = stage.position + Vector2(-22, 286)
	map_layer.add_child(signal_strip)

	var signal_row := HBoxContainer.new()
	signal_row.add_theme_constant_override("separation", 8)
	signal_strip.add_child(signal_row)
	for item_variant in stage_profile["strip_rows"]:
		var item: Dictionary = item_variant
		signal_row.add_child(_make_hero_chip(str(item["label"]), str(item["value"]), item["color"]))

	var left_panel := _make_stage_info_panel(
		str(stage_profile["left_title"]),
		stage_profile["left_rows"],
		Color8(102, 152, 204)
	)
	left_panel.position = stage.position + Vector2(-286, 76)
	map_layer.add_child(left_panel)

	var right_panel := _make_stage_info_panel(
		str(stage_profile["right_title"]),
		stage_profile["right_rows"],
		Color8(171, 132, 196)
	)
	right_panel.position = stage.position + Vector2(382, 76)
	map_layer.add_child(right_panel)


func _make_stage_info_panel(title_text: String, rows: Array, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 132)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 8)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = title_text
	_style_secondary_title(title, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	for line in rows:
		var item := Label.new()
		item.text = "• %s" % str(line)
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_body(item, 14)
		box.add_child(item)
	return panel


func _region_command_header(active_region: Dictionary) -> Dictionary:
	var region_type := _region_type_label(active_region)
	if region_type == "草原区域":
		return {
			"eyebrow": "草原前线总控台",
			"subtitle": "草原推进线与捕食压力同步监测",
			"substage": "草原聚焦副舞台",
			"dossier": "草原档案终端",
		}
	if region_type == "湿地区域":
		return {
			"eyebrow": "湿地巡察总控台",
			"subtitle": "水网节点与岸带生态同步监测",
			"substage": "湿地聚焦副舞台",
			"dossier": "湿地档案终端",
		}
	if region_type == "海域型区域":
		return {
			"eyebrow": "海域航标总控台",
			"subtitle": "洋流通道与海岸生态同步监测",
			"substage": "海域聚焦副舞台",
			"dossier": "海域档案终端",
		}
	if region_type == "森林区域":
		return {
			"eyebrow": "林地巡航总控台",
			"subtitle": "林冠层与地表生态同步监测",
			"substage": "林地聚焦副舞台",
			"dossier": "林地档案终端",
		}
	return {
		"eyebrow": "世界核心舞台",
		"subtitle": str(active_region.get("region_role", "生态观测区")),
		"substage": "区域聚焦副舞台",
		"dossier": "区域档案终端",
	}


func _focus_stage_profile(active_region: Dictionary, active_frontier: Dictionary, active_frontier_network: Dictionary) -> Dictionary:
	var health := active_region.get("health_state", {})
	var chain_focus: Array = active_region.get("chain_focus", [])
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var route_summary: Array = active_region.get("route_summary", [])
	var top_species: Array = active_region.get("top_species", [])
	var chains: Dictionary = active_region.get("chains", {})
	var narrative: Dictionary = active_region.get("narrative", {})
	var biome_text := " / ".join(active_region.get("dominant_biomes", []).slice(0, 2))
	var frontier_branches: Array = active_frontier_network.get("branches", [])
	var frontier_target_name := str(active_frontier.get("target_name", "等待前线目标"))
	var frontier_target_role := str(active_frontier.get("target_role", "等待前线情报"))
	var frontier_target_species := _frontier_species_summary(active_frontier.get("target_species", []))
	var frontier_branch_count := int(active_frontier_network.get("branch_count", 0))
	var frontier_branch_total_strength := float(active_frontier_network.get("branch_total_strength", 0.0))
	var frontier_connection := "%s %.2f" % [
		str(active_frontier.get("connection_label", "区域通道")),
		float(active_frontier.get("strength", 0.0)),
	] if not active_frontier.is_empty() else "当前暂无可用前线通道"
	var base_profile := {
		"mode": "总览主视区",
		"substage_title": "总览聚焦副舞台",
		"sub_primary": {"label": "前线目标", "value": frontier_target_name, "color": Color8(104, 171, 144)},
		"sub_secondary": {"label": "通道路由", "value": frontier_connection, "color": Color8(171, 132, 196)},
		"hero_rows": [
			{"label": "主地貌", "value": biome_text, "color": _active_region_accent()},
			{"label": "前线目标", "value": frontier_target_name, "color": Color8(104, 171, 144)},
			{"label": "区域网络", "value": "%s 条连接" % str(active_region.get("connectors", []).size()), "color": Color8(102, 152, 204)},
		],
		"strip_rows": [
			{"label": "繁荣", "value": "%.2f" % float(health.get("prosperity", 0.0)), "color": _active_region_accent()},
			{"label": "稳定", "value": "%.2f" % float(health.get("stability", 0.0)), "color": Color8(102, 152, 204)},
			{"label": "分支", "value": str(frontier_branch_count), "color": Color8(171, 132, 196)},
			{"label": "网络强度", "value": "%.2f" % frontier_branch_total_strength, "color": Color8(210, 182, 96)},
		],
		"left_title": "前线走廊情报",
		"left_rows": [
			frontier_target_role,
			frontier_connection,
			_frontier_branch_line(frontier_branches),
		],
		"right_title": "前线目标快照",
		"right_rows": [
			frontier_target_species,
			_frontier_branch_line(frontier_branches, 1),
			_frontier_branch_line(frontier_branches, 2),
		],
	}
	if selected_tab == "chains":
		base_profile["mode"] = "生态链主视区"
		base_profile["substage_title"] = "生态链聚焦副舞台"
		base_profile["sub_primary"] = {"label": "目标前线", "value": frontier_target_name, "color": Color8(102, 152, 204)}
		base_profile["sub_secondary"] = {"label": "前线主链", "value": _lead_chain_line(chains.get("grassland_chain", [])), "color": Color8(104, 171, 144)}
		base_profile["hero_rows"] = [
			{"label": "社会相位", "value": _lead_chain_line(chains.get("social_phases", [])), "color": Color8(102, 152, 204)},
			{"label": "尸体资源", "value": _lead_chain_line(chains.get("carrion_chain", [])), "color": Color8(171, 132, 196)},
			{"label": "前线路由", "value": frontier_connection, "color": _active_region_accent()},
		]
		base_profile["strip_rows"] = [
			{"label": "领地", "value": _lead_chain_line(chains.get("territory", [])), "color": _active_region_accent()},
			{"label": "竞争", "value": _lead_chain_line(chains.get("competition", [])), "color": Color8(210, 182, 96)},
			{"label": "草原", "value": _lead_chain_line(chains.get("grassland_chain", [])), "color": Color8(104, 171, 144)},
			{"label": "尸体", "value": _lead_chain_line(chains.get("carrion_chain", [])), "color": Color8(171, 132, 196)},
		]
		base_profile["left_title"] = "前线链路窗"
		base_profile["left_rows"] = [
			frontier_target_role,
			_lead_chain_line(chains.get("social_phases", [])),
			_lead_chain_line(chains.get("grassland_chain", [])),
			_frontier_branch_line(frontier_branches)
		]
		base_profile["right_title"] = "前线压力窗"
		base_profile["right_rows"] = [
			"网络分支 %s 条" % str(frontier_branch_count),
			_lead_chain_line(chains.get("territory", [])),
			_lead_chain_line(chains.get("competition", [])),
			_frontier_branch_line(frontier_branches, 1)
		]
	elif selected_tab == "species":
		base_profile["mode"] = "物种图鉴主视区"
		base_profile["substage_title"] = "图鉴聚焦副舞台"
		base_profile["sub_primary"] = {"label": "前线目标", "value": frontier_target_name, "color": Color8(171, 132, 196)}
		base_profile["sub_secondary"] = {"label": "邻区物种", "value": frontier_target_species, "color": Color8(102, 152, 204)}
		base_profile["hero_rows"] = [
			{"label": "区域类型", "value": _region_type_label(active_region), "color": _active_region_accent()},
			{"label": "核心种", "value": str(top_species.size()), "color": Color8(171, 132, 196)},
			{"label": "总种群", "value": str(active_region.get("species_population", 0)), "color": Color8(210, 182, 96)}
		]
		base_profile["strip_rows"] = [
			{"label": "首位", "value": _species_entry_label(top_species[0]) if top_species.size() > 0 else "暂无", "color": Color8(171, 132, 196)},
			{"label": "次位", "value": _species_entry_label(top_species[1]) if top_species.size() > 1 else "暂无", "color": Color8(102, 152, 204)},
			{"label": "第三位", "value": _species_entry_label(top_species[2]) if top_species.size() > 2 else "暂无", "color": Color8(104, 171, 144)},
			{"label": "地貌", "value": biome_text, "color": _active_region_accent()},
		]
		base_profile["left_title"] = "本区焦点物种"
		base_profile["left_rows"] = [
			_species_entry_label(top_species[0]) if top_species.size() > 0 else "等待更多物种聚焦",
			_species_entry_label(top_species[1]) if top_species.size() > 1 else "等待更多物种聚焦",
			_frontier_branch_line(frontier_branches)
		]
		base_profile["right_title"] = "邻区图鉴前哨"
		base_profile["right_rows"] = [
			frontier_target_species,
			"%s · %s" % [_region_type_chip(active_region), _species_category(str((top_species[0] as Dictionary).get("species_id", "")))] if top_species.size() > 0 else "等待更多分类标签",
			_frontier_branch_line(frontier_branches, 1),
		]
	elif selected_tab == "story":
		base_profile["mode"] = "区域播报主视区"
		base_profile["substage_title"] = "播报聚焦副舞台"
		base_profile["sub_primary"] = {"label": "前线播报", "value": frontier_target_name, "color": Color8(171, 132, 196)}
		base_profile["sub_secondary"] = {"label": "通道播报", "value": frontier_connection, "color": Color8(102, 152, 204)}
		base_profile["hero_rows"] = [
			{"label": "主链播报", "value": _lead_story_line(narrative.get("grassland_chain", narrative.get("wetland_chain", []))), "color": Color8(104, 171, 144)},
			{"label": "捕食播报", "value": _lead_story_line(narrative.get("predation", [])), "color": Color8(171, 132, 196)},
			{"label": "区域档案", "value": _region_type_label(active_region), "color": _active_region_accent()},
		]
		base_profile["strip_rows"] = [
			{"label": "领地", "value": _lead_story_line(narrative.get("territory", [])), "color": Color8(171, 132, 196)},
			{"label": "趋势", "value": _lead_story_line(narrative.get("social_trends", [])), "color": Color8(102, 152, 204)},
			{"label": "主链", "value": _lead_story_line(narrative.get("grassland_chain", narrative.get("wetland_chain", []))), "color": Color8(104, 171, 144)},
			{"label": "共生", "value": _lead_story_line(narrative.get("symbiosis", [])), "color": Color8(210, 182, 96)},
		]
		base_profile["left_title"] = "前线播报前哨"
		base_profile["left_rows"] = [
			frontier_target_role,
			_lead_story_line(narrative.get("territory", [])),
			_lead_story_line(narrative.get("social_trends", [])),
			_frontier_branch_line(frontier_branches)
		]
		base_profile["right_title"] = "前线链路摘要"
		base_profile["right_rows"] = [
			frontier_connection,
			_lead_story_line(narrative.get("grassland_chain", [])),
			_lead_story_line(narrative.get("carrion_chain", [])),
			_frontier_branch_line(frontier_branches, 1)
		]
	return base_profile


func _build_route_lines(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	var positions := _region_positions(regions, map_size)

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


func _build_frontier_network_overlay(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var positions := _region_positions(regions, map_size)
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var active_frontier := _active_frontier_link(active_region)
	var active_network := _active_frontier_network(active_region)
	if active_frontier.is_empty():
		return

	var active_pos: Vector2 = positions.get(active_region_id, Vector2(map_size.x * 0.5, map_size.y * 0.5))
	var target_id := str(active_frontier.get("target_region_id", ""))
	if not positions.has(target_id):
		return
	var target_pos: Vector2 = positions[target_id]
	var target_accent := REGION_COLORS.get(target_id, _active_region_accent())

	var corridor := _make_route_line(active_pos, target_pos, max(0.35, float(active_frontier.get("strength", 0.0))))
	corridor.color = Color(target_accent.r, target_accent.g, target_accent.b, 0.42)
	corridor.custom_minimum_size = Vector2(corridor.custom_minimum_size.x, 8.0)
	map_layer.add_child(corridor)

	var target_ring := ColorRect.new()
	target_ring.color = Color(target_accent.r, target_accent.g, target_accent.b, 0.18)
	target_ring.position = target_pos - Vector2(62, 28)
	target_ring.custom_minimum_size = Vector2(124, 56)
	map_layer.add_child(target_ring)

	var target_banner := PanelContainer.new()
	target_banner.position = target_pos - Vector2(70, 88)
	target_banner.custom_minimum_size = Vector2(160, 64)
	map_layer.add_child(target_banner)

	var banner_box := VBoxContainer.new()
	banner_box.add_theme_constant_override("separation", 4)
	target_banner.add_child(banner_box)

	var banner_ribbon := ColorRect.new()
	banner_ribbon.color = target_accent.lightened(0.08)
	banner_ribbon.custom_minimum_size = Vector2(0, 6)
	banner_box.add_child(banner_ribbon)

	var banner_title := Label.new()
	banner_title.text = "前线目标 · %s" % str(active_frontier.get("target_name", target_id))
	_style_secondary_title(banner_title, 17)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(banner_title)

	var banner_body := Label.new()
	banner_body.text = "%s · 分支 %s" % [
		str(active_frontier.get("connection_label", "区域通道")),
		str(active_network.get("branch_count", 0)),
	]
	banner_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_dim(banner_body, 13)
	banner_box.add_child(banner_body)

	for branch_variant in active_network.get("branches", []):
		var branch: Dictionary = branch_variant
		var branch_id := str(branch.get("target_region_id", ""))
		if not positions.has(branch_id):
			continue
		var branch_pos: Vector2 = positions[branch_id]
		var branch_accent := REGION_COLORS.get(branch_id, Color8(102, 152, 204))

		var branch_line := _make_route_line(target_pos, branch_pos, max(0.25, float(branch.get("strength", 0.0))))
		branch_line.color = Color(branch_accent.r, branch_accent.g, branch_accent.b, 0.28)
		branch_line.custom_minimum_size = Vector2(branch_line.custom_minimum_size.x, 5.0)
		map_layer.add_child(branch_line)

		var branch_badge := PanelContainer.new()
		branch_badge.position = branch_pos - Vector2(56, 92)
		branch_badge.custom_minimum_size = Vector2(128, 48)
		map_layer.add_child(branch_badge)

		var branch_box := VBoxContainer.new()
		branch_box.add_theme_constant_override("separation", 2)
		branch_badge.add_child(branch_box)

		var branch_title := Label.new()
		branch_title.text = "分支 · %s" % str(branch.get("target_name", branch_id))
		_style_body(branch_title, 14)
		branch_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_title.modulate = branch_accent.lightened(0.24)
		branch_box.add_child(branch_title)

		var branch_body := Label.new()
		branch_body.text = "%s %.2f" % [
			str(branch.get("connection_label", "区域通道")),
			float(branch.get("strength", 0.0)),
		]
		branch_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_dim(branch_body, 12)
		branch_box.add_child(branch_body)


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


func _build_map_command_layer() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var bulletin_panel := _make_world_bulletin_panel(active_region)
	bulletin_panel.position = Vector2(24, 20)
	map_layer.add_child(bulletin_panel)

	var focus_strip := _make_focus_command_strip(active_region)
	focus_strip.position = Vector2(max(220, map_layer.size.x * 0.34), 20)
	map_layer.add_child(focus_strip)

	var legend_panel := _make_map_legend_panel(active_region)
	legend_panel.position = Vector2(max(24, map_layer.size.x - 250), 20)
	map_layer.add_child(legend_panel)

	var frontier_belt := _make_frontier_transfer_belt(active_region)
	frontier_belt.position = Vector2(max(36, map_size.x * 0.16), map_size.y - 182)
	map_layer.add_child(frontier_belt)


func _make_world_bulletin_panel(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)

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
	return panel


func _make_focus_command_strip(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	var active_frontier := _active_frontier_link(active_region)
	var active_frontier_network := _active_frontier_network(active_region)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = _active_region_accent().lightened(0.04)
	ribbon.custom_minimum_size = Vector2(0, 8)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "%s · 世界战情层" % _region_type_chip(active_region)
	_style_primary_title(title, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	row.add_child(_make_hero_chip("焦点区域", str(active_region.get("name", "未选择")), _active_region_accent()))
	row.add_child(_make_hero_chip("前线目标", str(active_frontier.get("target_name", "等待前线目标")), Color8(102, 152, 204)))
	row.add_child(_make_hero_chip("通道路由", str(active_frontier.get("connection_label", "区域通道")), Color8(210, 182, 96)))

	var footer := Label.new()
	footer.text = "连接 %s · 种群 %s · 分支 %s · 前线风险 %.2f" % [
		str(active_region.get("connector_count", active_region.get("connectors", []).size())),
		str(active_region.get("species_population", 0)),
		str(active_frontier_network.get("branch_count", 0)),
		float(active_frontier.get("target_risk", 0.0)),
	]
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_dim(footer, 13)
	box.add_child(footer)
	return panel


func _make_map_legend_panel(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)

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
	return panel


func _make_frontier_transfer_belt(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 184)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = _active_region_accent().lightened(0.04)
	ribbon.custom_minimum_size = Vector2(0, 8)
	box.add_child(ribbon)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	box.add_child(title_row)

	var title := Label.new()
	title.text = "%s · 前线转运带" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	title.modulate = _active_region_accent().lightened(0.24)
	title_row.add_child(title)

	var tip := Label.new()
	tip.text = "点击相邻区域可直接切换焦点"
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_dim(tip, 13)
	title_row.add_child(tip)

	var frontier_links: Array = active_region.get("frontier_links", [])
	if frontier_links.is_empty():
		var empty := Label.new()
		empty.text = "当前没有可用前线通道。"
		_style_dim(empty, 15)
		box.add_child(empty)
		return panel

	box.add_child(_make_frontier_command_stage(active_region))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	for link_variant in frontier_links:
		var link: Dictionary = link_variant
		row.add_child(_make_frontier_card(link, str(link.get("target_region_id", "")) == selected_frontier_target_id))

	return panel


func _make_frontier_command_stage(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 86)
	var active_frontier := _active_frontier_link(active_region)
	var active_frontier_network := _active_frontier_network(active_region)
	var branches: Array = active_frontier_network.get("branches", [])
	var target_region_id := str(active_frontier.get("target_region_id", ""))
	var target_accent := REGION_COLORS.get(target_region_id, _active_region_accent())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	row.add_child(_make_feature_panel(
		"当前前线目标",
		str(active_frontier.get("target_name", "等待前线目标")),
		"%s · 强度 %.2f · 分支 %s" % [
			str(active_frontier.get("connection_label", "区域通道")),
			float(active_frontier.get("strength", 0.0)),
			str(active_frontier_network.get("branch_count", 0)),
		],
		target_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	row.add_child(stack)

	stack.add_child(_make_hero_chip("区域定位", str(active_frontier.get("target_role", "生态观测区")), target_accent))
	stack.add_child(_make_hero_chip("核心物种", _frontier_species_summary(active_frontier.get("target_species", [])), Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("网络分支", _frontier_branch_line(branches), Color8(102, 152, 204)))

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	stack.add_child(action_row)

	var focus_button := Button.new()
	focus_button.text = "锁定前线"
	focus_button.disabled = target_region_id == ""
	focus_button.pressed.connect(_on_frontier_focus_selected.bind(target_region_id))
	action_row.add_child(focus_button)

	var enter_button := Button.new()
	enter_button.text = "进入区域"
	enter_button.disabled = target_region_id == ""
	enter_button.pressed.connect(_on_region_pressed.bind(target_region_id))
	action_row.add_child(enter_button)

	return panel


func _make_frontier_card(frontier_link: Dictionary, is_selected: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(176, 100)
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_selected else 0.92)

	var target_region_id := str(frontier_link.get("target_region_id", ""))
	var target_accent := REGION_COLORS.get(target_region_id, Color8(102, 152, 204))
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var frontier_network: Dictionary = _active_frontier_network(active_region) if is_selected else _frontier_network_for_target(active_region, target_region_id)
	var branches: Array = frontier_network.get("branches", [])

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = target_accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 6)
	box.add_child(ribbon)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)

	var icon := Label.new()
	icon.text = _connection_type_icon(str(frontier_link.get("connection_type", "")))
	_style_secondary_title(icon, 20)
	icon.modulate = target_accent.lightened(0.18)
	header.add_child(icon)

	var name := Label.new()
	name.text = str(frontier_link.get("target_name", target_region_id))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_secondary_title(name, 17)
	name.modulate = target_accent.lightened(0.22)
	header.add_child(name)

	var strength := Label.new()
	strength.text = "%.2f" % float(frontier_link.get("strength", 0.0))
	_style_primary_title(strength, 18)
	strength.modulate = target_accent.lightened(0.28)
	header.add_child(strength)

	var route := Label.new()
	route.text = "%s%s · %s" % [
		"当前锁定 · " if is_selected else "",
		str(frontier_link.get("connection_label", "区域通道")),
		str(frontier_link.get("target_role", "生态观测区")),
	]
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(route, 13)
	box.add_child(route)

	var meter_row := HBoxContainer.new()
	meter_row.add_theme_constant_override("separation", 8)
	box.add_child(meter_row)
	meter_row.add_child(_make_hero_chip("繁荣", "%.2f" % float(frontier_link.get("target_prosperity", 0.0)), target_accent))
	meter_row.add_child(_make_hero_chip("风险", "%.2f" % float(frontier_link.get("target_risk", 0.0)), Color8(171, 132, 196)))

	var species := Label.new()
	species.text = _frontier_species_summary(frontier_link.get("target_species", []))
	species.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_body(species, 13)
	box.add_child(species)

	var branch := Label.new()
	branch.text = "网络分支 · %s" % _frontier_branch_line(branches)
	branch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(branch, 12)
	box.add_child(branch)

	panel.mouse_entered.connect(func() -> void:
		_animate_card_hover(panel, true)
	)
	panel.mouse_exited.connect(func() -> void:
		_animate_card_hover(panel, false)
	)

	var button := Button.new()
	button.flat = true
	button.text = ""
	button.set_anchors_preset(PRESET_FULL_RECT)
	button.pressed.connect(_on_frontier_focus_selected.bind(target_region_id))
	button.mouse_entered.connect(func() -> void:
		_animate_card_hover(panel, true)
	)
	button.mouse_exited.connect(func() -> void:
		_animate_card_hover(panel, false)
	)
	panel.add_child(button)

	return panel


func _frontier_species_summary(rows: Array) -> String:
	if rows.is_empty():
		return "当前暂无邻区物种快照"
	var labels: Array = []
	for row_variant in rows:
		var row: Dictionary = row_variant
		labels.append("%s×%s" % [str(row.get("label", "")), str(row.get("count", 0))])
	return "核心物种 · %s" % " / ".join(labels.slice(0, 2))


func _frontier_network_for_target(active_region: Dictionary, target_region_id: String) -> Dictionary:
	var frontier_network: Array = active_region.get("frontier_network", [])
	for network_variant in frontier_network:
		var network: Dictionary = network_variant
		if str(network.get("target_region_id", "")) == target_region_id:
			return network
	return {}


func _build_side_panel() -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var chains: Dictionary = active_region.get("chains", world_data.get("chains", {}))
	var narrative: Dictionary = active_region.get("narrative", world_data.get("narrative", {}))
	var top_species: Array = active_region.get("top_species", [])
	var route_summary: Array = active_region.get("route_summary", [])
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var chain_focus: Array = active_region.get("chain_focus", [])
	var region_accent := _active_region_accent()

	side_box.add_child(_make_region_hero(active_region, pressure_headlines, chain_focus, region_accent))
	var tab_content := VBoxContainer.new()
	tab_content.add_theme_constant_override("separation", 14)

	match selected_tab:
		"overview":
			tab_content.add_child(_make_tab_banner("总览指挥台", "查看区域定位、健康、资源与当前风险。", _tab_accent_color("overview"), region_accent, active_region))
			tab_content.add_child(_make_overview_dashboard(active_region, pressure_headlines, chain_focus, route_summary, region_accent))
			tab_content.add_child(_make_frontier_overview_card(active_region, region_accent))
			tab_content.add_child(_make_focus_card(active_region))
			tab_content.add_child(_make_region_summary_card(active_region))
			tab_content.add_child(_make_badge_list("风险焦点", pressure_headlines, active_region))
			tab_content.add_child(_make_badge_list("主导生态链", chain_focus, active_region))
			tab_content.add_child(_make_section("健康状态", active_region.get("health_state", {})))
			tab_content.add_child(_make_section("资源状态", active_region.get("resource_state", {})))
			tab_content.add_child(_make_section("生态压力", active_region.get("ecological_pressures", {})))
			tab_content.add_child(_make_section("区域连接", active_region.get("connectors", []), true, "target_region_id", "strength"))
			tab_content.add_child(_make_route_section(route_summary, active_region))
			tab_content.add_child(_make_intro_section(active_region))
		"chains":
			tab_content.add_child(_make_tab_banner("生态链监测", "读取社会相位、草原主链、尸体资源链与竞争压力。", _tab_accent_color("chains"), region_accent, active_region))
			tab_content.add_child(_make_chain_command_deck(chains, active_region, region_accent))
			tab_content.add_child(_make_section("社会相位", chains.get("social_phases", []), true))
			tab_content.add_child(_make_section("草原主链", chains.get("grassland_chain", []), true))
			tab_content.add_child(_make_section("尸体资源链", chains.get("carrion_chain", []), true))
			tab_content.add_child(_make_section("湿地主链", chains.get("wetland_chain", []), true))
			tab_content.add_child(_make_section("领地压力", chains.get("territory", []), true))
			tab_content.add_child(_make_section("竞争压力", chains.get("competition", []), true))
			tab_content.add_child(_make_section("捕食压力", chains.get("predation", []), true))
		"species":
			tab_content.add_child(_make_tab_banner("物种图鉴", "查看%s当前最核心的关键物种与数量。" % _region_type_label(active_region), _tab_accent_color("species"), region_accent, active_region))
			tab_content.add_child(_make_species_codex_header(top_species, active_region, region_accent))
			tab_content.add_child(_make_species_section(top_species, active_region))
		"story":
			tab_content.add_child(_make_tab_banner("区域播报室", "汇总%s中的领地、趋势、链路和关系层即时叙事。" % _region_type_label(active_region), _tab_accent_color("story"), region_accent, active_region))
			tab_content.add_child(_make_story_command_deck(narrative, active_region, region_accent))
			tab_content.add_child(_make_story_section(narrative, active_region))

	side_box.add_child(_make_dossier_shell(active_region, region_accent, tab_content))


func _make_dossier_shell(active_region: Dictionary, region_accent: Color, content: Control) -> PanelContainer:
	var header_copy := _region_command_header(active_region)
	var shell := PanelContainer.new()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	shell.add_child(root)

	var ribbon := ColorRect.new()
	ribbon.color = region_accent.lightened(0.04)
	ribbon.custom_minimum_size = Vector2(0, 10)
	root.add_child(ribbon)

	var terminal_row := HBoxContainer.new()
	terminal_row.add_theme_constant_override("separation", 8)
	root.add_child(terminal_row)

	var terminal_label := Label.new()
	terminal_label.text = "%s · %s" % [_region_type_chip(active_region), str(header_copy["dossier"])]
	_style_secondary_title(terminal_label, 18)
	terminal_label.modulate = region_accent.lightened(0.22)
	terminal_row.add_child(terminal_label)

	var terminal_status := Label.new()
	terminal_status.text = "焦点锁定 · %s · %s" % [str(active_region.get("name", "未选择")), _tab_title(selected_tab)]
	terminal_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_dim(terminal_status, 13)
	terminal_row.add_child(terminal_status)

	root.add_child(_make_tabs(region_accent))
	root.add_child(content)
	root.add_child(_make_terminal_footer(active_region, region_accent))
	return shell


func _make_terminal_footer(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	row.add_child(_make_hero_chip("当前分页", _tab_title(selected_tab), region_accent))
	row.add_child(_make_hero_chip("主地貌", " / ".join(active_region.get("dominant_biomes", []).slice(0, 2)), Color8(102, 152, 204)))
	row.add_child(_make_hero_chip("刷新模式", "自动刷新" if auto_refresh_button != null and auto_refresh_button.button_pressed else "手动刷新", Color8(210, 182, 96)))
	return panel

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
	panel.set_meta("status_strip", true)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var prosperity := float(active_region.get("health_state", {}).get("prosperity", 0.0))
	var stability := float(active_region.get("health_state", {}).get("stability", 0.0))
	var collapse_risk := float(active_region.get("health_state", {}).get("collapse_risk", 0.0))

	row.add_child(_make_status_chip("繁荣", "◎", "%.2f" % prosperity, prosperity, region_accent))
	row.add_child(_make_status_chip("稳定", "▲", "%.2f" % stability, stability, region_accent))
	row.add_child(_make_status_chip("风险", "◆", "%.2f" % collapse_risk, collapse_risk, region_accent))
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


func _make_status_chip(title_text: String, icon_text: String, value_text: String, numeric_value: float, region_accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(108, 56)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)

	var icon := Label.new()
	icon.text = icon_text
	_style_secondary_title(icon, 20)
	icon.modulate = region_accent.lightened(0.22)
	header.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 2)
	header.add_child(text_box)

	var title := Label.new()
	title.text = title_text
	_style_dim(title, 14)
	text_box.add_child(title)

	var value := Label.new()
	value.text = value_text
	_style_primary_title(value, 22)
	value.modulate = region_accent.lightened(0.30)
	text_box.add_child(value)

	var meter_bg := ColorRect.new()
	meter_bg.color = Color(1.0, 1.0, 1.0, 0.08)
	meter_bg.custom_minimum_size = Vector2(0, 5)
	box.add_child(meter_bg)

	var meter := ColorRect.new()
	meter.color = Color(region_accent.r, region_accent.g, region_accent.b, 0.78)
	meter.custom_minimum_size = Vector2(88.0 * clamp(numeric_value, 0.0, 1.0), 5)
	box.add_child(meter)
	return panel


func _make_region_hero(active_region: Dictionary, pressure_headlines: Array, chain_focus: Array, region_accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var ribbon := ColorRect.new()
	ribbon.color = region_accent.lightened(0.08)
	ribbon.custom_minimum_size = Vector2(0, 10)
	root.add_child(ribbon)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	root.add_child(top_row)

	var emblem := PanelContainer.new()
	emblem.custom_minimum_size = Vector2(72, 72)
	top_row.add_child(emblem)

	var emblem_label := Label.new()
	emblem_label.text = REGION_ICONS.get(str(active_region.get("id", active_region_id)), "区")
	emblem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem_label.custom_minimum_size = Vector2(72, 72)
	emblem_label.add_theme_font_size_override("font_size", 34)
	emblem_label.modulate = region_accent.lightened(0.34)
	emblem.add_child(emblem_label)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	top_row.add_child(text_col)

	var eyebrow := Label.new()
	eyebrow.text = "%s · 焦点区域" % _region_type_chip(active_region)
	_style_dim(eyebrow, 14)
	text_col.add_child(eyebrow)

	var title := Label.new()
	title.text = str(active_region.get("name", "未选择"))
	_style_primary_title(title, 30)
	title.modulate = region_accent.lightened(0.35)
	text_col.add_child(title)

	var role := Label.new()
	role.text = str(active_region.get("region_role", "生态观测区"))
	_style_secondary_title(role, 18)
	role.modulate = region_accent.lightened(0.18)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(role)

	var intro := Label.new()
	intro.text = str(active_region.get("region_intro", ""))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(intro, 14)
	text_col.add_child(intro)

	root.add_child(_make_status_strip(active_region, region_accent))

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	root.add_child(badge_row)

	for line in pressure_headlines.slice(0, 1):
		badge_row.add_child(_make_hero_chip("风险", str(line), Color8(171, 132, 196)))
	for line in chain_focus.slice(0, 1):
		badge_row.add_child(_make_hero_chip("主链", str(line), Color8(104, 171, 144)))
	for biome in active_region.get("dominant_biomes", []).slice(0, 1):
		badge_row.add_child(_make_hero_chip("地貌", str(biome), region_accent))

	return panel


func _make_hero_chip(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var label := Label.new()
	label.text = label_text
	_style_dim(label, 12)
	box.add_child(label)

	var value := Label.new()
	value.text = value_text
	_style_secondary_title(value, 15)
	value.modulate = accent.lightened(0.20)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value)
	return panel


func _make_overview_dashboard(active_region: Dictionary, pressure_headlines: Array, chain_focus: Array, route_summary: Array, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "%s · 区域总控板" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var summary := active_region.get("region_summary", {})
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"当前战略摘要",
		str(active_region.get("region_role", "生态观测区")),
		"群系块 %s · 栖息地 %s · 物种池 %s" % [
			str(summary.get("biome_count", 0)),
			str(summary.get("habitat_count", 0)),
			str(summary.get("species_pool_count", 0)),
		],
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("警报", str(pressure_headlines[0]) if pressure_headlines.size() > 0 else "当前暂无异常风险焦点", Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("主链", str(chain_focus[0]) if chain_focus.size() > 0 else "当前暂无主导链路信号", Color8(104, 171, 144)))
	stack.add_child(_make_hero_chip("通道", str(route_summary[0]) if route_summary.size() > 0 else "当前暂无显著通道情报", region_accent))
	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_frontier_overview_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_frontier := _active_frontier_link(active_region)
	var active_frontier_network := _active_frontier_network(active_region)
	var branches: Array = active_frontier_network.get("branches", [])

	var title := Label.new()
	title.text = "%s · 前线转运情报" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	var frontier_links: Array = active_region.get("frontier_links", [])
	var lead_text := "当前暂无前线邻区情报"
	var sub_text := "等待更多区域连接被识别。"
	if not active_frontier.is_empty():
		var lead_link: Dictionary = active_frontier
		lead_text = "%s · %s" % [
			str(lead_link.get("target_name", lead_link.get("target_region_id", ""))),
			str(lead_link.get("connection_label", "区域通道")),
		]
		sub_text = "繁荣 %.2f · 风险 %.2f" % [
			float(lead_link.get("target_prosperity", 0.0)),
			float(lead_link.get("target_risk", 0.0)),
		]

	body.add_child(_make_feature_panel(
		"当前前线节点",
		lead_text,
		sub_text,
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)

	for link_variant in frontier_links.slice(0, 2):
		var link: Dictionary = link_variant
		stack.add_child(_make_hero_chip(
			("%s%s" % ["当前 · " if str(link.get("target_region_id", "")) == selected_frontier_target_id else "", str(link.get("target_name", link.get("target_region_id", "")))]),
			"%s · %.2f" % [str(link.get("connection_label", "区域通道")), float(link.get("strength", 0.0))],
			REGION_COLORS.get(str(link.get("target_region_id", "")), Color8(102, 152, 204))
		))
	stack.add_child(_make_hero_chip("网络分支", _frontier_branch_line(branches), Color8(171, 132, 196)))

	if frontier_links.is_empty():
		stack.add_child(_make_hero_chip("前线转运带", "当前暂无前线邻区", Color8(102, 152, 204)))

	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_chain_command_deck(chains: Dictionary, active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "%s · 链路监测总板" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var lead := Label.new()
	lead.text = "这里先看每条主链当前最强的一条读数，再往下看完整监测卡。"
	_style_dim(lead, 14)
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lead)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"链路主监视窗",
		_lead_chain_line(chains.get("grassland_chain", [])),
		"社会相位与资源链会在下方继续展开。",
		Color8(104, 171, 144)
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("社会相位", _lead_chain_line(chains.get("social_phases", [])), Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("尸体资源", _lead_chain_line(chains.get("carrion_chain", [])), Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("领地", _lead_chain_line(chains.get("territory", [])), region_accent))

	var second_row := HBoxContainer.new()
	second_row.add_theme_constant_override("separation", 8)
	box.add_child(second_row)
	second_row.add_child(_make_hero_chip("竞争", _lead_chain_line(chains.get("competition", [])), Color8(210, 182, 96)))
	second_row.add_child(_make_hero_chip("捕食", _lead_chain_line(chains.get("predation", [])), Color8(171, 132, 196)))
	second_row.add_child(_make_hero_chip("湿地主链", _lead_chain_line(chains.get("wetland_chain", [])), Color8(102, 152, 204)))
	return _wrap_menu_card(box, Color8(104, 171, 144))


func _make_species_codex_header(top_species: Array, active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "%s · 核心图鉴索引" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var lead_one := "当前暂无物种数据"
	var lead_two := "等待更多区域统计"
	var lead_three := "等待更多区域统计"
	if top_species.size() > 0:
		lead_one = _species_entry_label(top_species[0])
	if top_species.size() > 1:
		lead_two = _species_entry_label(top_species[1])
	if top_species.size() > 2:
		lead_three = _species_entry_label(top_species[2])

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"当前领衔物种",
		lead_one,
		"本页继续列出焦点区域最重要的核心物种条目。",
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("次位", lead_two, Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("第三位", lead_three, Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("区域类型", _region_type_label(active_region), region_accent))
	return _wrap_menu_card(box, Color8(171, 132, 196))


func _make_story_command_deck(narrative: Dictionary, active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "%s · 播报总控板" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var lead := Label.new()
	lead.text = "优先看当前区域最活跃的叙事分区，再往下看分栏目播报卡。"
	_style_dim(lead, 14)
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lead)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"本区主主播报",
		_lead_story_line(narrative.get("territory", [])),
		"播报页会继续向下展开趋势、主链和关系层分栏播报。",
		Color8(102, 152, 204)
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("趋势", _lead_story_line(narrative.get("social_trends", [])), Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("主链", _lead_story_line(narrative.get("grassland_chain", narrative.get("wetland_chain", []))), region_accent))
	stack.add_child(_make_hero_chip("捕食", _lead_story_line(narrative.get("predation", [])), Color8(171, 132, 196)))
	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_feature_panel(title_text: String, main_text: String, description: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 6)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = title_text
	_style_dim(title, 13)
	box.add_child(title)

	var main := Label.new()
	main.text = main_text
	main.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_primary_title(main, 20)
	main.modulate = accent.lightened(0.24)
	box.add_child(main)

	var body := Label.new()
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(body, 13)
	box.add_child(body)
	return panel


func _lead_chain_line(rows: Array) -> String:
	if rows.is_empty():
		return "当前暂无重点读数"
	var row := rows[0]
	if typeof(row) == TYPE_DICTIONARY:
		if row.has("value"):
			return "%s %.2f" % [str(row.get("key", "读数")), float(row.get("value", 0.0))]
		if row.has("strength"):
			return "%s %.2f" % [str(row.get("target_region_id", "连接")), float(row.get("strength", 0.0))]
	return str(row)


func _lead_story_line(rows: Array) -> String:
	if rows.is_empty():
		return "当前暂无播报"
	return str(rows[0])


func _species_entry_label(row_variant: Variant) -> String:
	var row: Dictionary = row_variant
	return "%s × %s" % [
		str(row.get("label", row.get("species_id", ""))),
		str(row.get("count", 0)),
	]


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
	selected_frontier_target_id = ""
	status_label.text = "系统栏 · 已切换焦点区域：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_region_transition(_active_region_accent())


func _on_frontier_focus_selected(region_id: String) -> void:
	selected_frontier_target_id = region_id
	status_label.text = "系统栏 · 已锁定前线目标：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(102, 152, 204))


func _on_tab_pressed(tab_id: String) -> void:
	selected_tab = tab_id
	status_label.text = "系统栏 · 已切换功能分页：%s" % _tab_title(tab_id)
	for child in side_box.get_children():
		child.queue_free()
	_build_side_panel()
	_animate_page_transition(_active_region_accent(), _tab_accent_color(tab_id))


func _on_auto_refresh_toggled(enabled: bool) -> void:
	if enabled:
		refresh_timer.start()
		status_label.text = "系统栏 · 自动刷新已开启，每 2 秒重新读取一次世界状态。"
	else:
		refresh_timer.stop()
		status_label.text = "系统栏 · 自动刷新已关闭。"

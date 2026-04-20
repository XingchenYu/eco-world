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
var footer_box: VBoxContainer
var footer_command_holder: HBoxContainer
var selected_tab := "overview"
var selected_campaign_target_id := ""
var selected_campaign_stage_index := 0
var selected_campaign_filter := "balanced"
var selected_campaign_landing_target_id := ""
var selected_schedule_route_key := "primary_route"
var selected_formation_key := "assault"
var selected_activation_preset_key := "assault"
var selected_directive_key := "assault"
var selected_decision_key := "assault"
var selected_confirmation_key := "assault"
var selected_frontier_target_id := ""
var selected_branch_target_id := ""
var refresh_button: Button
var auto_refresh_button: CheckButton
var refresh_timer: Timer
var detail_cache: Dictionary = {}
var bulletin_cache: Array = []
var legend_cache: Array = []
var ui_font_resource: Font


func _apply_ui_theme() -> void:
	var ui_theme := Theme.new()
	ui_font_resource = ThemeDB.fallback_font
	ui_theme.default_font = ui_font_resource
	ui_theme.default_font_size = 16
	if ui_font_resource != null:
		for type_name in ["Label", "Button", "CheckButton", "RichTextLabel"]:
			ui_theme.set_font("font", type_name, ui_font_resource)
	theme = ui_theme


func _style_primary_title(label: Label, size: int = 22) -> void:
	if ui_font_resource != null:
		label.add_theme_font_override("font", ui_font_resource)
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color8(245, 237, 215)


func _style_secondary_title(label: Label, size: int = 18) -> void:
	if ui_font_resource != null:
		label.add_theme_font_override("font", ui_font_resource)
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color8(223, 215, 182)


func _style_body(label: Label, size: int = 15) -> void:
	if ui_font_resource != null:
		label.add_theme_font_override("font", ui_font_resource)
	label.add_theme_font_size_override("font_size", size)
	label.modulate = Color8(214, 218, 222)


func _style_dim(label: Label, size: int = 14) -> void:
	if ui_font_resource != null:
		label.add_theme_font_override("font", ui_font_resource)
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


func _species_category_icon(species_id: String) -> String:
	return {
		"顶层种": "✦",
		"草食群": "◎",
		"岸带种": "≈",
		"水域种": "◌",
	}.get(_species_category(species_id), "◉")


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


func _animate_region_focus_entry(shell: Control, outer_ring: ColorRect, shadow: ColorRect, shell_base: Vector2, shadow_base: Vector2) -> void:
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


func _animate_region_hover(shell: Control, outer_ring: ColorRect, shadow: ColorRect, entering: bool) -> void:
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


func _animate_region_press(shell: Control, pressed: bool) -> void:
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
	_apply_ui_theme()

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 14)
	root_margin.add_theme_constant_override("margin_top", 14)
	root_margin.add_theme_constant_override("margin_right", 14)
	root_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_margin.add_child(root_vbox)

	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 82)
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
	_style_primary_title(title_label, 30)
	title_col.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "世界地图"
	_style_secondary_title(subtitle_label, 15)
	title_col.add_child(subtitle_label)

	var control_row := HBoxContainer.new()
	control_row.add_theme_constant_override("separation", 10)
	title_row.add_child(control_row)

	refresh_button = Button.new()
	refresh_button.text = "刷新"
	refresh_button.custom_minimum_size = Vector2(110, 36)
	refresh_button.pressed.connect(_load_world_data)
	control_row.add_child(refresh_button)

	auto_refresh_button = CheckButton.new()
	auto_refresh_button.text = "自动刷新"
	auto_refresh_button.toggled.connect(_on_auto_refresh_toggled)
	control_row.add_child(auto_refresh_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	root_vbox.add_child(content)

	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(map_panel)

	map_layer = Control.new()
	map_layer.custom_minimum_size = Vector2(1120, 760)
	map_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_child(map_layer)

	side_panel = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(208, 0)
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(side_panel)

	side_scroll = ScrollContainer.new()
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_child(side_scroll)

	side_box = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 14)
	side_scroll.add_child(side_box)

	var footer_panel := PanelContainer.new()
	footer_panel.custom_minimum_size = Vector2(0, 78)
	root_vbox.add_child(footer_panel)

	footer_box = VBoxContainer.new()
	footer_box.add_theme_constant_override("separation", 4)
	footer_panel.add_child(footer_box)

	var footer_ribbon := ColorRect.new()
	footer_ribbon.color = Color8(210, 182, 96)
	footer_ribbon.custom_minimum_size = Vector2(0, 6)
	footer_box.add_child(footer_ribbon)

	footer_command_holder = HBoxContainer.new()
	footer_command_holder.add_theme_constant_override("separation", 10)
	footer_box.add_child(footer_command_holder)

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

	var parsed: Variant = JSON.parse_string(file.get_as_text())
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
	queue_redraw()
	_sync_frontier_focus()

	for child in footer_command_holder.get_children():
		child.queue_free()
	footer_command_holder.add_child(_make_tabs(_active_region_accent()))

	for child in map_layer.get_children():
		child.queue_free()
	for child in side_box.get_children():
		child.queue_free()

	_build_world_backdrop()
	_build_world_ambience()
	_build_focus_stage(world_meta.get("regions", []))
	_build_route_lines(world_meta.get("regions", []))
	_build_frontier_network_overlay(world_meta.get("regions", []))
	_build_campaign_overlay(world_meta.get("regions", []))
	_build_map_nodes(world_meta.get("regions", []))
	_build_map_command_layer()
	_build_side_panel()


func _sync_frontier_focus() -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var frontier_links: Array = active_region.get("frontier_links", [])
	if frontier_links.is_empty():
		selected_campaign_target_id = ""
		selected_frontier_target_id = ""
		selected_branch_target_id = ""
		return
	_sync_campaign_focus(active_region)
	for link_variant in frontier_links:
		var link: Dictionary = link_variant
		if str(link.get("target_region_id", "")) == selected_frontier_target_id:
			_sync_branch_focus(active_region)
			return
	selected_frontier_target_id = str((frontier_links[0] as Dictionary).get("target_region_id", ""))
	_sync_branch_focus(active_region)


func _sync_campaign_focus(active_region: Dictionary) -> void:
	var campaigns: Array = active_region.get("frontier_campaigns", [])
	if campaigns.is_empty():
		selected_campaign_target_id = ""
		selected_campaign_stage_index = 0
		selected_campaign_landing_target_id = ""
		return
	for campaign_variant in campaigns:
		var campaign: Dictionary = campaign_variant
		if str(campaign.get("target_region_id", "")) == selected_campaign_target_id:
			selected_frontier_target_id = selected_campaign_target_id
			_sync_campaign_stage(active_region)
			_sync_campaign_landing(active_region)
			return
	selected_campaign_target_id = str((campaigns[0] as Dictionary).get("target_region_id", ""))
	selected_frontier_target_id = selected_campaign_target_id
	_sync_campaign_stage(active_region)
	_sync_campaign_landing(active_region)


func _sync_campaign_stage(active_region: Dictionary) -> void:
	var active_campaign := _active_frontier_campaign(active_region)
	var route_titles: Array = active_campaign.get("route_titles", [])
	if route_titles.is_empty():
		selected_campaign_stage_index = 0
		return
	selected_campaign_stage_index = clampi(selected_campaign_stage_index, 0, route_titles.size() - 1)


func _sync_campaign_landing(active_region: Dictionary) -> void:
	var candidates: Array = _campaign_landing_candidates(active_region)
	if candidates.is_empty():
		selected_campaign_landing_target_id = ""
		return
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		if str(candidate.get("target_region_id", "")) == selected_campaign_landing_target_id:
			return
	var active_stage := _active_campaign_stage(active_region)
	var stage_target_id := str(active_stage.get("target_region_id", ""))
	if stage_target_id != "":
		selected_campaign_landing_target_id = stage_target_id
		return
	selected_campaign_landing_target_id = str((candidates[0] as Dictionary).get("target_region_id", ""))


func _apply_activation_feedback(active_region: Dictionary) -> void:
	var feedback := _active_activation_feedback(active_region)
	if feedback.is_empty():
		return
	selected_campaign_filter = str(feedback.get("recommended_filter", "balanced"))
	selected_campaign_stage_index = int(feedback.get("recommended_stage_index", 0))
	selected_directive_key = str(feedback.get("activation_key", "assault"))
	_sync_campaign_stage(active_region)
	var priority_target_id := str(feedback.get("priority_target_id", ""))
	if priority_target_id != "":
		selected_campaign_target_id = priority_target_id
		selected_frontier_target_id = priority_target_id
		selected_campaign_landing_target_id = priority_target_id
	_sync_campaign_focus(active_region)
	_sync_branch_focus(active_region)


func _apply_directive_profile(active_region: Dictionary) -> void:
	var directive := _active_directive_profile(active_region)
	if directive.is_empty():
		return
	selected_campaign_filter = str(directive.get("recommended_filter", "balanced"))
	selected_campaign_stage_index = int(directive.get("recommended_stage_index", 0))
	selected_schedule_route_key = str(directive.get("active_route_key", "primary_route"))
	var priority_target_id := str(directive.get("priority_target_id", ""))
	if priority_target_id != "":
		selected_campaign_target_id = priority_target_id
		selected_frontier_target_id = priority_target_id
		selected_campaign_landing_target_id = priority_target_id
	_sync_campaign_focus(active_region)
	_sync_branch_focus(active_region)


func _apply_decision_lock(active_region: Dictionary) -> void:
	var lock := _active_directive_lock(active_region)
	if lock.is_empty():
		return
	var decision_key := str(lock.get("lock_key", "assault"))
	selected_decision_key = decision_key
	selected_confirmation_key = decision_key
	selected_directive_key = decision_key
	selected_activation_preset_key = decision_key
	selected_formation_key = decision_key
	_apply_directive_profile(active_region)


func _sync_branch_focus(active_region: Dictionary) -> void:
	var active_network := _active_frontier_network(active_region)
	var branches: Array = active_network.get("branches", [])
	if branches.is_empty():
		selected_branch_target_id = ""
		return
	for branch_variant in branches:
		var branch: Dictionary = branch_variant
		if str(branch.get("target_region_id", "")) == selected_branch_target_id:
			return
	selected_branch_target_id = str((branches[0] as Dictionary).get("target_region_id", ""))


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


func _active_frontier_branch(active_region: Dictionary) -> Dictionary:
	var active_network := _active_frontier_network(active_region)
	var branches: Array = active_network.get("branches", [])
	if branches.is_empty():
		return {}
	for branch_variant in branches:
		var branch: Dictionary = branch_variant
		if str(branch.get("target_region_id", "")) == selected_branch_target_id:
			return branch
	return branches[0]


func _active_frontier_operation(active_region: Dictionary) -> Dictionary:
	var operations: Array = active_region.get("frontier_operations", [])
	if operations.is_empty():
		return {}
	for operation_variant in operations:
		var operation: Dictionary = operation_variant
		if str(operation.get("target_region_id", "")) == selected_frontier_target_id:
			return operation
	return operations[0]


func _active_frontier_campaign(active_region: Dictionary) -> Dictionary:
	var campaigns: Array = active_region.get("frontier_campaigns", [])
	if campaigns.is_empty():
		return {}
	for campaign_variant in campaigns:
		var campaign: Dictionary = campaign_variant
		if str(campaign.get("target_region_id", "")) == selected_campaign_target_id:
			return campaign
	return campaigns[0]


func _active_route_profile(active_region: Dictionary) -> Dictionary:
	var profiles: Array = active_region.get("frontier_route_profiles", [])
	if profiles.is_empty():
		return {}
	for profile_variant in profiles:
		var profile: Dictionary = profile_variant
		if str(profile.get("target_region_id", "")) == selected_campaign_target_id:
			return profile
	return profiles[0]


func _active_execution_plan(active_region: Dictionary) -> Dictionary:
	var plans: Array = active_region.get("frontier_execution_plans", [])
	if plans.is_empty():
		return {}
	for plan_variant in plans:
		var plan: Dictionary = plan_variant
		if str(plan.get("target_region_id", "")) == selected_campaign_target_id:
			return plan
	return plans[0]


func _active_schedule_profile(active_region: Dictionary) -> Dictionary:
	var profiles: Array = active_region.get("frontier_schedule_profiles", [])
	if profiles.is_empty():
		return {}
	return profiles[0]


func _active_formation_profile(active_region: Dictionary) -> Dictionary:
	var profiles: Array = active_region.get("frontier_formation_profiles", [])
	if profiles.is_empty():
		return {}
	for profile_variant in profiles:
		var profile: Dictionary = profile_variant
		if str(profile.get("formation_key", "")) == selected_formation_key:
			return profile
	selected_formation_key = "assault"
	return profiles[0]


func _active_formation_preset(active_region: Dictionary) -> Dictionary:
	var presets: Array = active_region.get("frontier_formation_presets", [])
	if presets.is_empty():
		return {}
	for preset_variant in presets:
		var preset: Dictionary = preset_variant
		if str(preset.get("preset_key", "")) == selected_formation_key:
			return preset
	return presets[0]


func _active_activation_profile(active_region: Dictionary) -> Dictionary:
	var profiles: Array = active_region.get("frontier_activation_profiles", [])
	if profiles.is_empty():
		return {}
	for profile_variant in profiles:
		var profile: Dictionary = profile_variant
		if str(profile.get("activation_key", "")) == selected_activation_preset_key:
			return profile
	selected_activation_preset_key = "assault"
	return profiles[0]


func _active_activation_feedback(active_region: Dictionary) -> Dictionary:
	var feedbacks: Array = active_region.get("frontier_activation_feedbacks", [])
	if feedbacks.is_empty():
		return {}
	for feedback_variant in feedbacks:
		var feedback: Dictionary = feedback_variant
		if str(feedback.get("activation_key", "")) == selected_activation_preset_key:
			return feedback
	return feedbacks[0]


func _active_directive_profile(active_region: Dictionary) -> Dictionary:
	var directives: Array = active_region.get("frontier_directive_profiles", [])
	if directives.is_empty():
		return {}
	for directive_variant in directives:
		var directive: Dictionary = directive_variant
		if str(directive.get("directive_key", "")) == selected_directive_key:
			return directive
	selected_directive_key = "assault"
	return directives[0]


func _active_directive_preview(active_region: Dictionary) -> Dictionary:
	var previews: Array = active_region.get("frontier_directive_previews", [])
	if previews.is_empty():
		return {}
	for preview_variant in previews:
		var preview: Dictionary = preview_variant
		if str(preview.get("directive_key", "")) == selected_directive_key:
			return preview
	return previews[0]


func _directive_sandbox_rows(active_region: Dictionary) -> Array:
	var rows: Array = active_region.get("frontier_directive_sandbox", [])
	return rows


func _directive_comparison(active_region: Dictionary) -> Dictionary:
	return active_region.get("frontier_directive_comparison", {})


func _directive_decisions(active_region: Dictionary) -> Array:
	return active_region.get("frontier_directive_decisions", [])


func _active_directive_lock(active_region: Dictionary) -> Dictionary:
	var locks: Array = active_region.get("frontier_directive_locks", [])
	if locks.is_empty():
		return {}
	for lock_variant in locks:
		var lock: Dictionary = lock_variant
		if str(lock.get("lock_key", "")) == selected_decision_key:
			return lock
	selected_decision_key = "assault"
	return locks[0]


func _active_directive_confirmation(active_region: Dictionary) -> Dictionary:
	var confirmations: Array = active_region.get("frontier_directive_confirmations", [])
	if confirmations.is_empty():
		return {}
	for confirmation_variant in confirmations:
		var confirmation: Dictionary = confirmation_variant
		if str(confirmation.get("confirmation_key", "")) == selected_confirmation_key:
			return confirmation
	selected_confirmation_key = "assault"
	return confirmations[0]


func _apply_directive_confirmation(active_region: Dictionary) -> void:
	var confirmation := _active_directive_confirmation(active_region)
	if confirmation.is_empty():
		return
	var confirmation_key := str(confirmation.get("confirmation_key", "assault"))
	selected_confirmation_key = confirmation_key
	selected_decision_key = confirmation_key
	_apply_decision_lock(active_region)


func _active_schedule_route(active_region: Dictionary) -> Dictionary:
	var active_formation := _active_formation_profile(active_region)
	if active_formation.is_empty():
		return {}
	var route: Variant = active_formation.get("active_route", {})
	if selected_schedule_route_key != "primary_route":
		route = active_formation.get(
			"support_route" if selected_schedule_route_key == "support_route" else "fallback_route",
			route
		)
	if route is Dictionary and not route.is_empty():
		return route
	selected_schedule_route_key = "primary_route"
	return active_formation.get("active_route", {})


func _active_campaign_stage(active_region: Dictionary) -> Dictionary:
	var active_operation := _active_frontier_operation(active_region)
	var route_stages: Array = active_operation.get("route_stages", [])
	if route_stages.is_empty():
		return {}
	var stage_index := clampi(selected_campaign_stage_index, 0, route_stages.size() - 1)
	return route_stages[stage_index]


func _active_campaign_landing(active_region: Dictionary) -> Dictionary:
	var landing_region_id := selected_campaign_landing_target_id
	if landing_region_id == "":
		var active_stage := _active_campaign_stage(active_region)
		landing_region_id = str(active_stage.get("target_region_id", ""))
	if landing_region_id == "":
		landing_region_id = str(_active_frontier_link(active_region).get("target_region_id", ""))
	if landing_region_id == "":
		return {}
	return detail_cache.get(landing_region_id, {})


func _activation_route_priority_order(active_region: Dictionary) -> Array:
	var feedback := _active_activation_feedback(active_region)
	var order: Array = feedback.get("route_priority_order", [])
	if order.is_empty():
		return ["primary_route", "support_route", "fallback_route"]
	return order


func _reordered_schedule_routes(active_region: Dictionary, active_schedule: Dictionary) -> Array:
	var directive := _active_directive_profile(active_region)
	var order: Array = []
	var active_route_key := str(directive.get("active_route_key", ""))
	if active_route_key == "":
		order = _activation_route_priority_order(active_region)
	else:
		var candidates := [active_route_key, "primary_route", "support_route", "fallback_route"]
		var seen := {}
		for route_key_variant in candidates:
			var route_key := str(route_key_variant)
			if seen.has(route_key):
				continue
			seen[route_key] = true
			order.append(route_key)
	var routes: Array = []
	for route_key_variant in order:
		var route_key := str(route_key_variant)
		var route: Dictionary = active_schedule.get(route_key, {})
		if route.is_empty():
			continue
		var route_copy := route.duplicate(true)
		route_copy["route_key"] = route_key
		routes.append(route_copy)
	return routes


func _campaign_landing_candidates(active_region: Dictionary) -> Array:
	var active_frontier := _active_frontier_link(active_region)
	var active_network := _active_frontier_network(active_region)
	var active_feedback := _active_activation_feedback(active_region)
	var candidates: Array = []
	var seen := {}

	var frontier_target_id := str(active_frontier.get("target_region_id", ""))
	if frontier_target_id != "" and detail_cache.has(frontier_target_id):
		var landing_detail: Dictionary = detail_cache.get(frontier_target_id, {})
		candidates.append(
			{
				"target_region_id": frontier_target_id,
				"name": str(landing_detail.get("name", frontier_target_id)),
				"role": str(landing_detail.get("region_role", "生态观测区")),
				"prosperity": float(landing_detail.get("health_state", {}).get("prosperity", 0.0)),
				"risk": float(landing_detail.get("health_state", {}).get("collapse_risk", 0.0)),
				"stage_label": "第一阶段",
			}
		)
		seen[frontier_target_id] = true

	for branch_variant in active_network.get("branches", []):
		var branch: Dictionary = branch_variant
		var branch_id := str(branch.get("target_region_id", ""))
		if branch_id == "" or seen.has(branch_id):
			continue
		var branch_detail: Dictionary = detail_cache.get(branch_id, {})
		candidates.append(
			{
				"target_region_id": branch_id,
				"name": str(branch_detail.get("name", branch.get("target_name", branch_id))),
				"role": str(branch_detail.get("region_role", branch.get("target_role", "生态观测区"))),
				"prosperity": float(branch_detail.get("health_state", {}).get("prosperity", branch.get("target_prosperity", 0.0))),
				"risk": float(branch_detail.get("health_state", {}).get("collapse_risk", branch.get("target_risk", 0.0))),
				"stage_label": "第二阶段",
			}
		)
		seen[branch_id] = true

	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		var prosperity := float(candidate.get("prosperity", 0.0))
		var risk := float(candidate.get("risk", 0.0))
		var loop_boost := 0.0
		if str(candidate.get("target_region_id", "")) == str(active_feedback.get("priority_target_id", "")):
			loop_boost += 0.16
		if str(candidate.get("stage_label", "")) == str(active_feedback.get("recommended_stage_title", "")):
			loop_boost += 0.08
		candidate["score_balanced"] = floor((prosperity * 0.64 + (1.0 - risk) * 0.36) * 10000.0 + 0.5) / 10000.0
		candidate["score_safe"] = floor(((1.0 - risk) * 0.72 + prosperity * 0.28) * 10000.0 + 0.5) / 10000.0
		candidate["score_rich"] = floor((prosperity * 0.82 + (1.0 - risk) * 0.18) * 10000.0 + 0.5) / 10000.0
		candidate["score_risk"] = floor((risk * 0.78 + prosperity * 0.22) * 10000.0 + 0.5) / 10000.0
		candidate["loop_boost"] = floor(loop_boost * 10000.0 + 0.5) / 10000.0
		candidate["score"] = float(candidate.get("score_balanced", 0.0)) + loop_boost

	_apply_campaign_filter(candidates)
	return candidates


func _campaign_filter_label() -> String:
	return {
		"balanced": "综合",
		"safe": "稳态",
		"rich": "高繁荣",
		"risk": "高风险",
	}.get(selected_campaign_filter, "综合")


func _candidate_sort_score(candidate: Dictionary) -> float:
	match selected_campaign_filter:
		"safe":
			return float(candidate.get("score_safe", 0.0))
		"rich":
			return float(candidate.get("score_rich", 0.0))
		"risk":
			return float(candidate.get("score_risk", 0.0))
		_:
			return float(candidate.get("score_balanced", 0.0))


func _apply_campaign_filter(candidates: Array) -> void:
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		candidate["score"] = _candidate_sort_score(candidate)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)


func _build_world_backdrop() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	var ocean := ColorRect.new()
	ocean.color = Color8(12, 28, 44, 255)
	ocean.position = Vector2.ZERO
	ocean.custom_minimum_size = map_size
	map_layer.add_child(ocean)

	for band_variant in [
		{"color": Color8(18, 45, 71, 138), "pos": Vector2(map_size.x * 0.00, map_size.y * 0.08), "size": Vector2(map_size.x * 1.00, map_size.y * 0.18)},
		{"color": Color8(26, 56, 84, 120), "pos": Vector2(map_size.x * 0.00, map_size.y * 0.34), "size": Vector2(map_size.x * 1.00, map_size.y * 0.16)},
		{"color": Color8(15, 39, 62, 132), "pos": Vector2(map_size.x * 0.00, map_size.y * 0.64), "size": Vector2(map_size.x * 1.00, map_size.y * 0.22)},
	]:
		var sea_band := ColorRect.new()
		sea_band.color = band_variant["color"]
		sea_band.position = band_variant["pos"]
		sea_band.custom_minimum_size = band_variant["size"]
		map_layer.add_child(sea_band)

	for land_variant in [
		{"color": Color8(54, 94, 66, 170), "pos": Vector2(map_size.x * 0.07, map_size.y * 0.12), "size": Vector2(map_size.x * 0.34, map_size.y * 0.32)},
		{"color": Color8(63, 103, 72, 176), "pos": Vector2(map_size.x * 0.22, map_size.y * 0.36), "size": Vector2(map_size.x * 0.28, map_size.y * 0.24)},
		{"color": Color8(57, 98, 82, 164), "pos": Vector2(map_size.x * 0.47, map_size.y * 0.18), "size": Vector2(map_size.x * 0.18, map_size.y * 0.20)},
		{"color": Color8(46, 81, 96, 156), "pos": Vector2(map_size.x * 0.67, map_size.y * 0.28), "size": Vector2(map_size.x * 0.18, map_size.y * 0.26)},
		{"color": Color8(97, 72, 103, 152), "pos": Vector2(map_size.x * 0.73, map_size.y * 0.64), "size": Vector2(map_size.x * 0.15, map_size.y * 0.12)},
	]:
		var land_block := ColorRect.new()
		land_block.color = land_variant["color"]
		land_block.position = land_variant["pos"]
		land_block.custom_minimum_size = land_variant["size"]
		map_layer.add_child(land_block)

	for coast_variant in [
		{"color": Color(1.0, 0.92, 0.60, 0.10), "pos": Vector2(map_size.x * 0.06, map_size.y * 0.11), "size": Vector2(map_size.x * 0.36, 3)},
		{"color": Color(1.0, 0.92, 0.60, 0.10), "pos": Vector2(map_size.x * 0.21, map_size.y * 0.35), "size": Vector2(map_size.x * 0.30, 3)},
		{"color": Color(1.0, 0.92, 0.60, 0.08), "pos": Vector2(map_size.x * 0.67, map_size.y * 0.27), "size": Vector2(map_size.x * 0.19, 3)},
	]:
		var coast_line := ColorRect.new()
		coast_line.color = coast_variant["color"]
		coast_line.position = coast_variant["pos"]
		coast_line.custom_minimum_size = coast_variant["size"]
		map_layer.add_child(coast_line)


func _build_world_ambience() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var active_rel: Vector2 = REGION_LAYOUT.get(active_region_id, Vector2(0.5, 0.5))
	var active_pos := Vector2(map_size.x * active_rel.x, map_size.y * active_rel.y)
	var accent := _active_region_accent()

	for horizon_variant in [
		{"color": Color(1.0, 1.0, 1.0, 0.03), "pos": Vector2(map_size.x * 0.03, map_size.y * 0.18), "size": Vector2(map_size.x * 0.94, 2)},
		{"color": Color(1.0, 1.0, 1.0, 0.025), "pos": Vector2(map_size.x * 0.08, map_size.y * 0.46), "size": Vector2(map_size.x * 0.84, 2)},
		{"color": Color(1.0, 1.0, 1.0, 0.02), "pos": Vector2(map_size.x * 0.12, map_size.y * 0.73), "size": Vector2(map_size.x * 0.76, 2)},
	]:
		var horizon_band := ColorRect.new()
		horizon_band.color = horizon_variant["color"]
		horizon_band.position = horizon_variant["pos"]
		horizon_band.custom_minimum_size = horizon_variant["size"]
		map_layer.add_child(horizon_band)

	for current in [
		{"from": Vector2(map_size.x * 0.63, map_size.y * 0.22), "to": Vector2(map_size.x * 0.82, map_size.y * 0.30)},
		{"from": Vector2(map_size.x * 0.70, map_size.y * 0.44), "to": Vector2(map_size.x * 0.90, map_size.y * 0.56)},
		{"from": Vector2(map_size.x * 0.74, map_size.y * 0.66), "to": Vector2(map_size.x * 0.90, map_size.y * 0.78)},
	]:
		var flow := _make_route_line(current["from"], current["to"], 0.85)
		flow.color = Color(0.70, 0.86, 0.97, 0.14)
		flow.custom_minimum_size = Vector2(flow.custom_minimum_size.x, 3.0)
		map_layer.add_child(flow)

	for route in [
		{"from": Vector2(map_size.x * 0.18, map_size.y * 0.28), "to": Vector2(map_size.x * 0.34, map_size.y * 0.42), "strength": 0.62},
		{"from": Vector2(map_size.x * 0.34, map_size.y * 0.42), "to": Vector2(map_size.x * 0.50, map_size.y * 0.34), "strength": 0.58},
		{"from": Vector2(map_size.x * 0.50, map_size.y * 0.34), "to": Vector2(map_size.x * 0.68, map_size.y * 0.40), "strength": 0.66},
		{"from": Vector2(map_size.x * 0.68, map_size.y * 0.40), "to": Vector2(map_size.x * 0.79, map_size.y * 0.62), "strength": 0.54},
	]:
		var trunk := _make_route_line(route["from"], route["to"], route["strength"])
		trunk.color = Color(0.96, 0.88, 0.58, 0.16)
		trunk.custom_minimum_size = Vector2(trunk.custom_minimum_size.x, 5.0)
		map_layer.add_child(trunk)

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

	for spark_variant in [
		Vector2(map_size.x * 0.18, map_size.y * 0.22),
		Vector2(map_size.x * 0.59, map_size.y * 0.28),
		Vector2(map_size.x * 0.82, map_size.y * 0.67),
	]:
		var spark := ColorRect.new()
		spark.color = Color(1.0, 0.94, 0.72, 0.16)
		spark.position = spark_variant
		spark.custom_minimum_size = Vector2(12, 12)
		map_layer.add_child(spark)


func _campaign_accent(campaign_band: String) -> Color:
	return {
		"赤线推进令": Color8(216, 112, 96),
		"多线扩张令": Color8(171, 132, 196),
		"丰度扩张令": Color8(104, 171, 144),
		"稳态侦察令": Color8(102, 152, 204),
		"前线巡察令": Color8(210, 182, 96),
	}.get(campaign_band, Color8(171, 132, 196))


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
	var active_frontier := _active_frontier_link(active_region)
	var active_campaign := _active_frontier_campaign(active_region)
	var active_route_profile := _active_route_profile(active_region)
	var active_stage := _active_campaign_stage(active_region)
	var active_landing := _active_campaign_landing(active_region)
	var stage := VBoxContainer.new()
	stage.custom_minimum_size = Vector2(244, 48)
	stage.position = Vector2(map_size.x * 0.42, map_size.y * 0.50)
	map_layer.add_child(stage)

	var root := stage
	root.add_theme_constant_override("separation", 1)

	var eyebrow := Label.new()
	eyebrow.text = _region_type_chip(active_region)
	_style_dim(eyebrow, 7)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(eyebrow)

	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 3)
	root.add_child(hero_row)

	var emblem_icon := Label.new()
	emblem_icon.text = REGION_ICONS.get(str(active_region.get("id", active_region_id)), "区")
	emblem_icon.custom_minimum_size = Vector2(22, 22)
	emblem_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem_icon.add_theme_font_size_override("font_size", 14)
	emblem_icon.modulate = accent.lightened(0.34)
	hero_row.add_child(emblem_icon)

	var stage_col := VBoxContainer.new()
	stage_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_col.add_theme_constant_override("separation", 1)
	hero_row.add_child(stage_col)

	var title := Label.new()
	title.text = str(active_landing.get("name", active_region.get("name", "未选择")))
	_style_primary_title(title, 12)
	title.modulate = accent.lightened(0.26)
	stage_col.add_child(title)

	var route_line := Label.new()
	route_line.text = "→ %s" % str(active_frontier.get("target_name", "待命"))
	_style_dim(route_line, 7)
	route_line.modulate = accent.lightened(0.16)
	stage_col.add_child(route_line)

	var signal_label := Label.new()
	signal_label.text = "前线 · %s" % str(active_stage.get("stage", "待命"))
	signal_label.position = stage.position + Vector2(54, 46)
	_style_dim(signal_label, 7)
	signal_label.modulate = accent.lightened(0.14)
	map_layer.add_child(signal_label)


func _make_stage_info_panel(title_text: String, rows: Array, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(152, 78)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 6)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = title_text
	_style_secondary_title(title, 13)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	for line in rows.slice(0, 2):
		var item := Label.new()
		item.text = str(line)
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_dim(item, 11)
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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


func _focus_stage_profile(active_region: Dictionary, active_frontier: Dictionary, active_frontier_network: Dictionary, active_operation: Dictionary, active_campaign: Dictionary, active_stage: Dictionary) -> Dictionary:
	var health: Dictionary = active_region.get("health_state", {})
	var chain_focus: Array = active_region.get("chain_focus", [])
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var route_summary: Array = active_region.get("route_summary", [])
	var top_species: Array = active_region.get("top_species", [])
	var chains: Dictionary = active_region.get("chains", {})
	var narrative: Dictionary = active_region.get("narrative", {})
	var biome_text := " / ".join(active_region.get("dominant_biomes", []).slice(0, 2))
	var frontier_branches: Array = active_frontier_network.get("branches", [])
	var active_branch := _active_frontier_branch(active_region)
	var frontier_target_name := str(active_frontier.get("target_name", "等待前线目标"))
	var frontier_target_role := str(active_frontier.get("target_role", "等待前线情报"))
	var frontier_target_species := _frontier_species_summary(active_frontier.get("target_species", []))
	var frontier_branch_count := int(active_frontier_network.get("branch_count", 0))
	var frontier_branch_total_strength := float(active_frontier_network.get("branch_total_strength", 0.0))
	var branch_target_name := str(active_branch.get("target_name", "等待分支目标"))
	var branch_target_role := str(active_branch.get("target_role", "等待分支情报"))
	var operation_posture := str(active_operation.get("posture", "等待前线方案"))
	var operation_threat := str(active_operation.get("threat_band", "等待战区判断"))
	var operation_opportunity := str(active_operation.get("opportunity_band", "等待机会判断"))
	var operation_summary := str(active_operation.get("summary", "当前暂无前线行动方案"))
	var campaign_band := str(active_campaign.get("campaign_band", "战区推进模式"))
	var stage_mode := str(active_stage.get("stage", "阶段待命"))
	var stage_title := str(active_stage.get("title", str(active_campaign.get("campaign_name", "等待战区推演"))))
	var stage_detail := str(active_stage.get("detail", operation_summary))
	var branch_connection := "%s %.2f" % [
		str(active_branch.get("connection_label", "区域通道")),
		float(active_branch.get("strength", 0.0)),
	] if not active_branch.is_empty() else "当前暂无分支通道"
	var frontier_connection := "%s %.2f" % [
		str(active_frontier.get("connection_label", "区域通道")),
		float(active_frontier.get("strength", 0.0)),
	] if not active_frontier.is_empty() else "当前暂无可用前线通道"
	var base_profile := {
		"mode": "总览主视区",
		"stage_mode": stage_mode,
		"stage_title": stage_title,
		"substage_title": "总览聚焦副舞台",
		"sub_primary": {"label": "当前阶段", "value": stage_mode, "color": Color8(104, 171, 144)},
		"sub_secondary": {"label": "阶段目标", "value": stage_title, "color": Color8(171, 132, 196)},
		"hero_rows": [
			{"label": "主地貌", "value": biome_text, "color": _active_region_accent()},
			{"label": "战区模式", "value": campaign_band, "color": Color8(104, 171, 144)},
			{"label": "区域网络", "value": "%s 条连接" % str(active_region.get("connectors", []).size()), "color": Color8(102, 152, 204)},
		],
		"strip_rows": [
			{"label": "繁荣", "value": "%.2f" % float(health.get("prosperity", 0.0)), "color": _active_region_accent()},
			{"label": "稳定", "value": "%.2f" % float(health.get("stability", 0.0)), "color": Color8(102, 152, 204)},
			{"label": "威胁带", "value": operation_threat, "color": Color8(171, 132, 196)},
			{"label": "机会带", "value": operation_opportunity, "color": Color8(210, 182, 96)},
		],
		"left_title": "前线走廊情报",
		"left_rows": [
			frontier_target_role,
			stage_detail,
			"当前分支 · %s" % branch_target_name,
			operation_summary,
		],
		"right_title": "前线目标快照",
		"right_rows": [
			frontier_target_species,
			branch_connection,
			branch_target_role,
			"分支 %s · 网络强度 %.2f" % [str(frontier_branch_count), frontier_branch_total_strength],
		],
	}
	if selected_tab == "chains":
		base_profile["mode"] = "生态链主视区"
		base_profile["substage_title"] = "生态链聚焦副舞台"
		base_profile["sub_primary"] = {"label": "目标前线", "value": frontier_target_name, "color": Color8(102, 152, 204)}
		base_profile["sub_secondary"] = {"label": "行动姿态", "value": operation_posture, "color": Color8(104, 171, 144)}
		base_profile["hero_rows"] = [
			{"label": "社会相位", "value": _lead_chain_line(chains.get("social_phases", [])), "color": Color8(102, 152, 204)},
			{"label": "尸体资源", "value": _lead_chain_line(chains.get("carrion_chain", [])), "color": Color8(171, 132, 196)},
			{"label": "战区判断", "value": operation_threat, "color": _active_region_accent()},
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
			"当前分支 · %s" % branch_target_name,
			operation_summary,
		]
		base_profile["right_title"] = "前线压力窗"
		base_profile["right_rows"] = [
			"网络分支 %s 条" % str(frontier_branch_count),
			_lead_chain_line(chains.get("territory", [])),
			_lead_chain_line(chains.get("competition", [])),
			branch_connection,
			"机会带 · %s" % operation_opportunity,
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
			"当前分支 · %s" % branch_target_name
		]
		base_profile["right_title"] = "邻区图鉴前哨"
		base_profile["right_rows"] = [
			frontier_target_species,
			"%s · %s" % [_region_type_chip(active_region), _species_category(str((top_species[0] as Dictionary).get("species_id", "")))] if top_species.size() > 0 else "等待更多分类标签",
			branch_connection,
			operation_posture,
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
			"当前分支 · %s" % branch_target_name
		]
		base_profile["right_title"] = "前线链路摘要"
		base_profile["right_rows"] = [
			frontier_connection,
			_lead_story_line(narrative.get("grassland_chain", [])),
			_lead_story_line(narrative.get("carrion_chain", [])),
			branch_connection,
			operation_summary,
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
	var active_branch := _active_frontier_branch(active_region)
	var active_operation := _active_frontier_operation(active_region)
	if active_frontier.is_empty():
		return

	var active_pos: Vector2 = positions.get(active_region_id, Vector2(map_size.x * 0.5, map_size.y * 0.5))
	var target_id := str(active_frontier.get("target_region_id", ""))
	if not positions.has(target_id):
		return
	var target_pos: Vector2 = positions[target_id]
	var target_accent: Color = REGION_COLORS.get(target_id, _active_region_accent())

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
	banner_body.text = "%s · %s · 分支 %s" % [
		str(active_frontier.get("connection_label", "区域通道")),
		str(active_operation.get("posture", "等待前线方案")),
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
		var branch_accent: Color = REGION_COLORS.get(branch_id, Color8(102, 152, 204))
		var is_selected_branch: bool = branch_id == str(active_branch.get("target_region_id", ""))

		var branch_line := _make_route_line(target_pos, branch_pos, max(0.25, float(branch.get("strength", 0.0))))
		branch_line.color = Color(branch_accent.r, branch_accent.g, branch_accent.b, 0.46 if is_selected_branch else 0.28)
		branch_line.custom_minimum_size = Vector2(branch_line.custom_minimum_size.x, 7.0 if is_selected_branch else 5.0)
		map_layer.add_child(branch_line)

		var branch_badge := PanelContainer.new()
		branch_badge.position = branch_pos - Vector2(56, 92)
		branch_badge.custom_minimum_size = Vector2(128, 48)
		branch_badge.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_selected_branch else 0.94)
		map_layer.add_child(branch_badge)

		var branch_box := VBoxContainer.new()
		branch_box.add_theme_constant_override("separation", 2)
		branch_badge.add_child(branch_box)

		var branch_title := Label.new()
		branch_title.text = "%s分支 · %s" % ["当前" if is_selected_branch else "", str(branch.get("target_name", branch_id))]
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

		var branch_button := Button.new()
		branch_button.flat = true
		branch_button.text = ""
		branch_button.set_anchors_preset(PRESET_FULL_RECT)
		branch_button.pressed.connect(_on_frontier_branch_selected.bind(branch_id))
		branch_badge.add_child(branch_button)


func _build_campaign_overlay(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var positions := _region_positions(regions, map_size)
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var active_campaign := _active_frontier_campaign(active_region)
	var active_stage := _active_campaign_stage(active_region)
	var active_frontier := _active_frontier_link(active_region)
	var active_network := _active_frontier_network(active_region)
	var landing_candidates: Array = _campaign_landing_candidates(active_region)
	_sync_campaign_landing(active_region)
	if active_campaign.is_empty() or active_frontier.is_empty():
		return

	var active_pos: Vector2 = positions.get(active_region_id, Vector2(map_size.x * 0.5, map_size.y * 0.5))
	var target_id := str(active_campaign.get("target_region_id", ""))
	if not positions.has(target_id):
		return
	var target_pos: Vector2 = positions[target_id]
	var campaign_accent := _campaign_accent(str(active_campaign.get("campaign_band", "")))
	var stage_index := selected_campaign_stage_index

	var target_zone := ColorRect.new()
	target_zone.color = Color(campaign_accent.r, campaign_accent.g, campaign_accent.b, 0.16 if stage_index == 0 else 0.09)
	target_zone.position = target_pos - Vector2(104, 64)
	target_zone.custom_minimum_size = Vector2(208, 128)
	map_layer.add_child(target_zone)

	var active_zone := ColorRect.new()
	active_zone.color = Color(campaign_accent.r, campaign_accent.g, campaign_accent.b, 0.12 if stage_index == 0 else 0.05)
	active_zone.position = active_pos - Vector2(84, 48)
	active_zone.custom_minimum_size = Vector2(168, 96)
	map_layer.add_child(active_zone)

	var stage_line := _make_route_line(active_pos, target_pos, 0.9)
	stage_line.color = Color(campaign_accent.r, campaign_accent.g, campaign_accent.b, 0.60 if stage_index == 0 else 0.34)
	stage_line.custom_minimum_size = Vector2(stage_line.custom_minimum_size.x, 10.0 if stage_index == 0 else 6.0)
	map_layer.add_child(stage_line)

	var stage_one := PanelContainer.new()
	stage_one.position = active_pos.lerp(target_pos, 0.36) - Vector2(62, 18)
	stage_one.custom_minimum_size = Vector2(124, 34)
	stage_one.modulate = Color(1.0, 1.0, 1.0, 1.0 if stage_index == 0 else 0.72)
	map_layer.add_child(stage_one)

	var stage_one_text := "第一阶段 · 推进"
	if stage_index == 0:
		stage_one_text = "第一阶段 · %s" % str(active_stage.get("title", "推进"))
	var stage_one_label := Label.new()
	stage_one_label.text = stage_one_text
	_style_dim(stage_one_label, 13)
	stage_one_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_one.add_child(stage_one_label)

	var stage_one_button := Button.new()
	stage_one_button.flat = true
	stage_one_button.text = ""
	stage_one_button.set_anchors_preset(PRESET_FULL_RECT)
	stage_one_button.pressed.connect(_on_region_pressed.bind(target_id))
	stage_one.add_child(stage_one_button)

	var branches: Array = active_network.get("branches", [])
	for branch_variant in branches:
		var branch: Dictionary = branch_variant
		var branch_id := str(branch.get("target_region_id", ""))
		if not positions.has(branch_id):
			continue
		var branch_pos: Vector2 = positions[branch_id]
		var is_active_stage_branch := stage_index == 1 and branch_id == str(active_stage.get("target_region_id", ""))

		var branch_zone := ColorRect.new()
		branch_zone.color = Color(campaign_accent.r, campaign_accent.g, campaign_accent.b, 0.16 if is_active_stage_branch else 0.05)
		branch_zone.position = branch_pos - Vector2(76, 42)
		branch_zone.custom_minimum_size = Vector2(152, 84)
		map_layer.add_child(branch_zone)

		var branch_line := _make_route_line(target_pos, branch_pos, 0.72)
		branch_line.color = Color(campaign_accent.r, campaign_accent.g, campaign_accent.b, 0.56 if is_active_stage_branch else 0.24)
		branch_line.custom_minimum_size = Vector2(branch_line.custom_minimum_size.x, 8.0 if is_active_stage_branch else 4.0)
		map_layer.add_child(branch_line)

		var stage_two := PanelContainer.new()
		stage_two.position = target_pos.lerp(branch_pos, 0.54) - Vector2(54, 16)
		stage_two.custom_minimum_size = Vector2(108, 30)
		stage_two.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_active_stage_branch else 0.70)
		map_layer.add_child(stage_two)

		var stage_two_label := Label.new()
		stage_two_label.text = "二阶段 · %s" % str(branch.get("target_name", branch_id))
		_style_dim(stage_two_label, 12)
		stage_two_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage_two.add_child(stage_two_label)

		var stage_two_button := Button.new()
		stage_two_button.flat = true
		stage_two_button.text = ""
		stage_two_button.set_anchors_preset(PRESET_FULL_RECT)
		stage_two_button.pressed.connect(_on_region_pressed.bind(branch_id))
		stage_two.add_child(stage_two_button)

	for landing_variant in landing_candidates:
		var landing: Dictionary = landing_variant
		var landing_id := str(landing.get("target_region_id", ""))
		if landing_id == target_id or not positions.has(landing_id):
			continue
		var landing_pos: Vector2 = positions[landing_id]
		var is_active_landing := landing_id == selected_campaign_landing_target_id
		var is_best_landing: bool = landing_variant == landing_candidates[0]
		var landing_badge := PanelContainer.new()
		landing_badge.position = landing_pos - Vector2(68, 118)
		landing_badge.custom_minimum_size = Vector2(136, 56)
		landing_badge.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_active_landing else (0.90 if is_best_landing else 0.72))
		map_layer.add_child(landing_badge)

		var landing_box := VBoxContainer.new()
		landing_box.add_theme_constant_override("separation", 2)
		landing_badge.add_child(landing_box)

		var landing_title := Label.new()
		landing_title.text = "%s%s · %s" % [
			"优选 · " if is_best_landing and not is_active_landing else "",
			str(landing.get("stage_label", "落点")),
			str(landing.get("name", landing_id)),
		]
		_style_body(landing_title, 13)
		landing_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		landing_box.add_child(landing_title)

		var landing_body := Label.new()
		landing_body.text = "繁荣 %.2f · 风险 %.2f" % [
			float(landing.get("prosperity", 0.0)),
			float(landing.get("risk", 0.0)),
		]
		landing_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_dim(landing_body, 12)
		landing_box.add_child(landing_body)

		var score_body := Label.new()
		score_body.text = "推进评分 %.2f" % float(landing.get("score", 0.0))
		score_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_dim(score_body, 12)
		landing_box.add_child(score_body)

		var landing_button := Button.new()
		landing_button.flat = true
		landing_button.text = ""
		landing_button.set_anchors_preset(PRESET_FULL_RECT)
		landing_button.pressed.connect(_on_campaign_landing_selected.bind(landing_id))
		landing_badge.add_child(landing_button)


func _make_route_line(from_pos: Vector2, to_pos: Vector2, strength: float) -> ColorRect:
	var delta: Vector2 = to_pos - from_pos
	var length: float = max(1.0, delta.length())
	var angle: float = delta.angle()
	var line := ColorRect.new()
	line.color = Color(0.88, 0.89, 0.70, clamp(0.18 + strength * 0.24, 0.20, 0.46))
	line.position = from_pos.lerp(to_pos, 0.5) - Vector2(length * 0.5, 2.5)
	line.custom_minimum_size = Vector2(length, 5.0)
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
		var pos: Vector2 = Vector2(map_size.x * rel.x, map_size.y * rel.y)
		var accent: Color = REGION_COLORS.get(region_id, Color8(110, 140, 170))
		var is_active: bool = region_id == active_region_id

		var shadow := ColorRect.new()
		shadow.color = Color(0.03, 0.06, 0.09, 0.28 if is_active else 0.05)
		var shadow_base := pos - Vector2(14, 14) + Vector2(3, 4)
		shadow.position = shadow_base
		shadow.custom_minimum_size = Vector2(28, 28)
		map_layer.add_child(shadow)

		var outer_ring := ColorRect.new()
		outer_ring.color = Color(accent.r, accent.g, accent.b, 0.16 if is_active else 0.03)
		outer_ring.position = pos - Vector2(15, 15)
		outer_ring.custom_minimum_size = Vector2(30, 30)
		map_layer.add_child(outer_ring)

		var shell := ColorRect.new()
		var shell_base := pos - Vector2(12, 12)
		shell.position = shell_base
		shell.custom_minimum_size = Vector2(24, 24)
		shell.color = Color(accent.r, accent.g, accent.b, 0.18 if is_active else 0.08)
		map_layer.add_child(shell)

		var stem := ColorRect.new()
		stem.color = Color(accent.r, accent.g, accent.b, 0.20 if is_active else 0.08)
		stem.position = pos + Vector2(-1, 12)
		stem.custom_minimum_size = Vector2(2, 10)
		map_layer.add_child(stem)

		if is_active:
			var glow := ColorRect.new()
			glow.color = Color(1.0, 0.92, 0.58, 0.14)
			glow.position = shell.position - Vector2(6, 6)
			glow.custom_minimum_size = shell.custom_minimum_size + Vector2(12, 12)
			map_layer.add_child(glow)
			map_layer.move_child(glow, map_layer.get_child_count() - 2)

			var focus_frame := ColorRect.new()
			focus_frame.color = Color(1.0, 0.92, 0.58, 0.22)
			focus_frame.position = shell.position - Vector2(2, 2)
			focus_frame.custom_minimum_size = shell.custom_minimum_size + Vector2(4, 4)
			map_layer.add_child(focus_frame)
			map_layer.move_child(focus_frame, map_layer.get_child_count() - 2)
			_animate_region_focus_entry(shell, outer_ring, shadow, shell_base, shadow_base)
			_animate_focus_glow(glow, focus_frame)

		var icon := Label.new()
		icon.text = REGION_ICONS.get(region_id, "区")
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.custom_minimum_size = Vector2(24, 24)
		icon.position = shell.position
		icon.add_theme_font_size_override("font_size", 14)
		icon.modulate = accent.lightened(0.34)
		map_layer.add_child(icon)

		var pip := ColorRect.new()
		pip.color = accent.lightened(0.16) if is_active else Color8(112, 132, 156)
		pip.custom_minimum_size = Vector2(3, 3)
		pip.position = shell.position + Vector2(10, 20)
		map_layer.add_child(pip)

		var button := Button.new()
		button.text = ""
		button.flat = true
		button.custom_minimum_size = Vector2(36, 42)
		button.position = shell.position - Vector2(6, 5)
		button.pressed.connect(_on_region_pressed.bind(region_id))
		button.mouse_entered.connect(func() -> void:
			shadow.position = shadow_base + Vector2(6, 8)
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

		var plaque_label := Label.new()
		plaque_label.text = str(region.get("name", region_id))
		_style_secondary_title(plaque_label, 5)
		plaque_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plaque_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plaque_label.position = shell.position + Vector2(-12, 35)
		plaque_label.custom_minimum_size = Vector2(44, 8)
		plaque_label.modulate = accent.lightened(0.22) if is_active else Color(accent.r, accent.g, accent.b, 0.12)
		map_layer.add_child(plaque_label)


func _build_map_command_layer() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var header_bar := _make_world_header_bar(active_region, map_size)
	header_bar.position = Vector2(20, 18)
	map_layer.add_child(header_bar)

	var frontier_belt := _make_frontier_transfer_belt(active_region)
	frontier_belt.position = Vector2(max(48, map_size.x * 0.18), map_size.y - 142)
	map_layer.add_child(frontier_belt)


func _make_world_header_bar(active_region: Dictionary, map_size: Vector2) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.custom_minimum_size = Vector2(min(map_size.x - 40.0, 1180.0), 84)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	shell.add_child(root)

	var ribbon := ColorRect.new()
	ribbon.color = _active_region_accent().lightened(0.08)
	ribbon.custom_minimum_size = Vector2(0, 4)
	root.add_child(ribbon)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	var left := _make_world_bulletin_panel(active_region)
	row.add_child(left)

	var center := HBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 6)
	row.add_child(center)
	center.add_child(_make_focus_command_strip(active_region))
	center.add_child(_make_frontier_campaign_bar(active_region))

	var right := _make_map_legend_panel(active_region)
	row.add_child(right)
	return shell


func _make_world_bulletin_panel(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(188, 56)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = Color8(102, 152, 204)
	ribbon.custom_minimum_size = Vector2(0, 4)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "世界图抬头"
	_style_secondary_title(title, 11)
	box.add_child(title)

	var focus_line := Label.new()
	focus_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	focus_line.text = str(active_region.get("name", "未选择区域"))
	_style_dim(focus_line, 9)
	box.add_child(focus_line)

	return panel


func _make_focus_command_strip(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = _active_region_accent().lightened(0.04)
	ribbon.custom_minimum_size = Vector2(0, 4)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "%s · 当前区域" % _region_type_chip(active_region)
	_style_secondary_title(title, 11)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	row.add_child(_make_hero_chip("区", str(active_region.get("name", "未选择")), _active_region_accent()))
	return panel


func _make_frontier_campaign_bar(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = Color8(171, 132, 196)
	ribbon.custom_minimum_size = Vector2(0, 5)
	box.add_child(ribbon)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	box.add_child(title_row)

	var title := Label.new()
	title.text = "战区模式"
	_style_secondary_title(title, 11)
	title_row.add_child(title)

	var hint := Label.new()
	hint.text = "切换"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_dim(hint, 9)
	title_row.add_child(hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	var campaigns: Array = active_region.get("frontier_campaigns", [])
	if campaigns.is_empty():
		row.add_child(_make_hero_chip("战区模式", "当前暂无前线编成", Color8(102, 152, 204)))
		return panel

	for campaign_variant in campaigns.slice(0, 2):
		var campaign: Dictionary = campaign_variant
		row.add_child(_make_frontier_campaign_card(campaign))

	return panel


func _make_frontier_campaign_card(campaign: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(132, 34)
	var is_selected := str(campaign.get("target_region_id", "")) == selected_campaign_target_id
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_selected else 0.92)

	var target_region_id := str(campaign.get("target_region_id", ""))
	var accent: Color = REGION_COLORS.get(target_region_id, Color8(171, 132, 196))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 3)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = str(campaign.get("campaign_band", "战区推进令"))
	_style_secondary_title(title, 9)
	title.modulate = accent.lightened(0.22)
	box.add_child(title)

	var body := Label.new()
	body.text = str(campaign.get("campaign_name", "等待前线方案"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_body(body, 8)
	box.add_child(body)

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
	button.pressed.connect(_on_frontier_campaign_selected.bind(target_region_id))
	panel.add_child(button)
	return panel


func _make_campaign_stage_button(active_region: Dictionary, stage_index: int, label_text: String) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_pressed = selected_campaign_stage_index == stage_index
	button.custom_minimum_size = Vector2(92, 26)
	var active_operation := _active_frontier_operation(active_region)
	var route_stages: Array = active_operation.get("route_stages", [])
	if selected_campaign_stage_index == stage_index:
		button.text = "%s" % label_text
	else:
		button.text = label_text
	if stage_index >= route_stages.size():
		button.disabled = true
	button.pressed.connect(_on_campaign_stage_selected.bind(stage_index))
	return button


func _make_campaign_filter_button(label_text: String, filter_key: String) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_pressed = selected_campaign_filter == filter_key
	button.custom_minimum_size = Vector2(72, 28)
	button.text = "%s%s" % [label_text, " · 当前" if selected_campaign_filter == filter_key else ""]
	button.pressed.connect(_on_campaign_filter_selected.bind(filter_key))
	return button


func _make_map_legend_panel(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(118, 56)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = Color8(210, 182, 96)
	ribbon.custom_minimum_size = Vector2(0, 4)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "图例"
	_style_primary_title(title, 11)
	box.add_child(title)

	var focus_row := HBoxContainer.new()
	focus_row.add_theme_constant_override("separation", 8)
	box.add_child(focus_row)

	var focus_swatch := ColorRect.new()
	focus_swatch.color = _active_region_accent()
	focus_swatch.custom_minimum_size = Vector2(12, 12)
	focus_row.add_child(focus_swatch)

	var focus_label := Label.new()
	var biome_text := " / ".join(active_region.get("dominant_biomes", []).slice(0, 2))
	focus_label.text = biome_text if biome_text != "" else str(active_region.get("name", "未选择"))
	_style_body(focus_label, 11)
	focus_row.add_child(focus_label)

	for entry_variant in legend_cache.slice(0, 1):
		var entry: Dictionary = entry_variant
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)

		var swatch := ColorRect.new()
		swatch.color = {
			"forest": Color8(78, 137, 96),
			"grassland": Color8(198, 173, 96),
			"wetland": Color8(92, 154, 162),
			"coast": Color8(80, 141, 191),
			"coral": Color8(203, 132, 177),
		}.get(str(entry.get("color", "")), Color8(210, 210, 210))
		swatch.custom_minimum_size = Vector2(10, 10)
		row.add_child(swatch)

		var label := Label.new()
		label.text = str(entry.get("label", ""))
		_style_body(label, 9)
		row.add_child(label)
	return panel


func _make_frontier_transfer_belt(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 58)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = _active_region_accent().lightened(0.04)
	ribbon.custom_minimum_size = Vector2(0, 4)
	box.add_child(ribbon)

	var dock_label := Label.new()
	dock_label.text = "%s · 路径坞" % _region_type_chip(active_region)
	dock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_dim(dock_label, 8)
	box.add_child(dock_label)

	var frontier_links: Array = active_region.get("frontier_links", [])
	if frontier_links.is_empty():
		var empty := Label.new()
		empty.text = "当前没有可用前线通道。"
		_style_dim(empty, 11)
		box.add_child(empty)
		return panel

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	for link_variant in frontier_links:
		var link: Dictionary = link_variant
		row.add_child(_make_frontier_card(link, str(link.get("target_region_id", "")) == selected_frontier_target_id))

	return panel


func _make_frontier_command_stage(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 154)
	var active_frontier := _active_frontier_link(active_region)
	var active_frontier_network := _active_frontier_network(active_region)
	var branches: Array = active_frontier_network.get("branches", [])
	var active_branch := _active_frontier_branch(active_region)
	var active_operation := _active_frontier_operation(active_region)
	var active_campaign := _active_frontier_campaign(active_region)
	var target_region_id := str(active_frontier.get("target_region_id", ""))
	var target_accent: Color = REGION_COLORS.get(target_region_id, _active_region_accent())
	var branch_route_text := "当前暂无分支通道"
	if not active_branch.is_empty():
		branch_route_text = "%s %.2f" % [
			str(active_branch.get("connection_label", "区域通道")),
			float(active_branch.get("strength", 0.0)),
		]

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
	stack.add_child(_make_hero_chip("战区模式", str(active_campaign.get("campaign_band", "等待战区模式")), Color8(102, 152, 204)))

	var branch_row := HBoxContainer.new()
	branch_row.add_theme_constant_override("separation", 8)
	stack.add_child(branch_row)
	branch_row.add_child(_make_hero_chip("当前分支", str(active_branch.get("target_name", "等待分支目标")), Color8(210, 182, 96)))
	branch_row.add_child(_make_hero_chip("分支路由", branch_route_text, Color8(102, 152, 204)))

	var plan_row := HBoxContainer.new()
	plan_row.add_theme_constant_override("separation", 8)
	stack.add_child(plan_row)
	plan_row.add_child(_make_hero_chip("威胁带", str(active_operation.get("threat_band", "等待威胁判断")), Color8(171, 132, 196)))
	plan_row.add_child(_make_hero_chip("机会带", str(active_operation.get("opportunity_band", "等待机会判断")), Color8(104, 171, 144)))

	var route_row := HBoxContainer.new()
	route_row.add_theme_constant_override("separation", 8)
	stack.add_child(route_row)
	var route_stages: Array = active_operation.get("route_stages", [])
	route_row.add_child(_make_hero_chip(
		"第一跳",
		str((route_stages[0] as Dictionary).get("title", "等待前线方案")) if route_stages.size() > 0 else "等待前线方案",
		target_accent
	))
	route_row.add_child(_make_hero_chip(
		"第二跳",
		str((route_stages[1] as Dictionary).get("title", "等待二级分支")) if route_stages.size() > 1 else "等待二级分支",
		Color8(210, 182, 96)
	))
	route_row.add_child(_make_hero_chip("行动姿态", str(active_operation.get("posture", "等待前线方案")), target_accent))

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

	var branch_focus_button := Button.new()
	branch_focus_button.text = "锁定分支"
	branch_focus_button.disabled = active_branch.is_empty()
	branch_focus_button.pressed.connect(_on_frontier_branch_selected.bind(str(active_branch.get("target_region_id", ""))))
	action_row.add_child(branch_focus_button)

	var branch_enter_button := Button.new()
	branch_enter_button.text = "进入分支"
	branch_enter_button.disabled = active_branch.is_empty()
	branch_enter_button.pressed.connect(_on_region_pressed.bind(str(active_branch.get("target_region_id", ""))))
	action_row.add_child(branch_enter_button)

	return panel


func _make_frontier_card(frontier_link: Dictionary, is_selected: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(74, 46)
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if is_selected else 0.92)

	var target_region_id := str(frontier_link.get("target_region_id", ""))
	var target_accent: Color = REGION_COLORS.get(target_region_id, Color8(102, 152, 204))
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = target_accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 3)
	box.add_child(ribbon)

	var icon := Label.new()
	icon.text = REGION_ICONS.get(target_region_id, "区")
	_style_secondary_title(icon, 14)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.modulate = target_accent.lightened(0.18)
	box.add_child(icon)

	var name := Label.new()
	name.text = str(frontier_link.get("target_name", target_region_id))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_secondary_title(name, 8)
	name.modulate = target_accent.lightened(0.22)
	box.add_child(name)

	var route_kind := Label.new()
	route_kind.text = "→"
	route_kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_dim(route_kind, 8)
	box.add_child(route_kind)

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
			tab_content.add_child(_make_tab_banner("地图首页", "当前区域的最短入口。", _tab_accent_color("overview"), region_accent, active_region))
			tab_content.add_child(_make_overview_cover(active_region, pressure_headlines, route_summary, region_accent))
		"chains":
			tab_content.add_child(_make_tab_banner("生态链菜单", "读取当前区域最强的三组生态信号。", _tab_accent_color("chains"), region_accent, active_region))
			tab_content.add_child(_make_chains_cover(active_region, chains, chain_focus, pressure_headlines, region_accent))
		"species":
			tab_content.add_child(_make_tab_banner("物种图鉴", "只显示当前区域的领衔物种阵容。", _tab_accent_color("species"), region_accent, active_region))
			tab_content.add_child(_make_species_cover(active_region, top_species, region_accent))
		"story":
			tab_content.add_child(_make_tab_banner("区域播报", "只保留当前区域最重要的即时播报。", _tab_accent_color("story"), region_accent, active_region))
			tab_content.add_child(_make_story_cover(active_region, narrative, region_accent))

	side_box.add_child(_make_dossier_shell(active_region, region_accent, tab_content))


func _make_dossier_shell(active_region: Dictionary, region_accent: Color, content: Control) -> PanelContainer:
	var shell := PanelContainer.new()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	shell.add_child(root)

	var ribbon := ColorRect.new()
	ribbon.color = region_accent.lightened(0.04)
	ribbon.custom_minimum_size = Vector2(0, 5)
	root.add_child(ribbon)

	var terminal_row := HBoxContainer.new()
	terminal_row.add_theme_constant_override("separation", 6)
	root.add_child(terminal_row)

	var terminal_label := Label.new()
	terminal_label.text = "%s · 菜单" % str(active_region.get("name", "未选择"))
	_style_secondary_title(terminal_label, 13)
	terminal_label.modulate = region_accent.lightened(0.22)
	terminal_row.add_child(terminal_label)

	var terminal_status := Label.new()
	terminal_status.text = _tab_title(selected_tab)
	terminal_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_dim(terminal_status, 9)
	terminal_row.add_child(terminal_status)

	root.add_child(content)
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
		var is_active: bool = tab_id == selected_tab
		button.text = "%s %s" % [
			_tab_icon(tab_id),
			_tab_title(tab_id),
		]
		button.toggle_mode = true
		button.button_pressed = is_active
		button.custom_minimum_size = Vector2(126, 44)
		var tab_color := _tab_accent_color(tab_id)
		var rest_color := region_accent.lightened(0.12) if is_active else tab_color.darkened(0.12)
		var hover_color := region_accent.lightened(0.24) if is_active else tab_color.lightened(0.12)
		button.modulate = rest_color
		button.add_theme_font_size_override("font_size", 17)
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
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = _blend_ui_accent(accent, region_accent)
	ribbon.custom_minimum_size = Vector2(0, 5)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = "%s %s" % [_region_type_icon(active_region), title_text]
	_style_primary_title(title, 18)
	title.modulate = region_accent.lightened(0.24)
	box.add_child(title)
	return panel


func _make_status_chip(title_text: String, icon_text: String, value_text: String, numeric_value: float, region_accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(92, 46)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	box.add_child(header)

	var icon := Label.new()
	icon.text = icon_text
	_style_secondary_title(icon, 15)
	icon.modulate = region_accent.lightened(0.22)
	header.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 2)
	header.add_child(text_box)

	var title := Label.new()
	title.text = title_text
	_style_dim(title, 10)
	text_box.add_child(title)

	var value := Label.new()
	value.text = value_text
	_style_primary_title(value, 16)
	value.modulate = region_accent.lightened(0.30)
	text_box.add_child(value)

	var meter_bg := ColorRect.new()
	meter_bg.color = Color(1.0, 1.0, 1.0, 0.08)
	meter_bg.custom_minimum_size = Vector2(0, 3)
	box.add_child(meter_bg)

	var meter := ColorRect.new()
	meter.color = Color(region_accent.r, region_accent.g, region_accent.b, 0.78)
	meter.custom_minimum_size = Vector2(72.0 * clamp(numeric_value, 0.0, 1.0), 3)
	box.add_child(meter)
	return panel


func _make_region_hero(active_region: Dictionary, pressure_headlines: Array, chain_focus: Array, region_accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel.add_child(root)

	var ribbon := ColorRect.new()
	ribbon.color = region_accent.lightened(0.08)
	ribbon.custom_minimum_size = Vector2(0, 6)
	root.add_child(ribbon)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	root.add_child(top_row)

	var emblem_label := Label.new()
	emblem_label.text = REGION_ICONS.get(str(active_region.get("id", active_region_id)), "区")
	emblem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem_label.custom_minimum_size = Vector2(34, 34)
	emblem_label.add_theme_font_size_override("font_size", 22)
	emblem_label.modulate = region_accent.lightened(0.34)
	top_row.add_child(emblem_label)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	top_row.add_child(text_col)

	var eyebrow := Label.new()
	eyebrow.text = _region_type_chip(active_region)
	_style_dim(eyebrow, 10)
	text_col.add_child(eyebrow)

	var title := Label.new()
	title.text = str(active_region.get("name", "未选择"))
	_style_primary_title(title, 18)
	title.modulate = region_accent.lightened(0.35)
	text_col.add_child(title)

	root.add_child(_make_status_strip(active_region, region_accent))

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 4)
	root.add_child(badge_row)
	badge_row.add_child(_make_hero_chip("地貌", " / ".join(active_region.get("dominant_biomes", []).slice(0, 2)), region_accent))
	badge_row.add_child(_make_hero_chip("通道", str(active_region.get("connector_count", active_region.get("connectors", []).size())), Color8(102, 152, 204)))

	return panel


func _make_hero_chip(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var label := Label.new()
	label.text = label_text
	_style_dim(label, 10)
	box.add_child(label)

	var value := Label.new()
	value.text = value_text
	_style_secondary_title(value, 13)
	value.modulate = accent.lightened(0.20)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value)
	return panel


func _make_meter_chip(label_text: String, value: float, accent: Color, icon_text: String = "◎") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 58)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	box.add_child(header)

	var icon := Label.new()
	icon.text = icon_text
	_style_secondary_title(icon, 14)
	icon.modulate = accent.lightened(0.18)
	header.add_child(icon)

	var title := Label.new()
	title.text = label_text
	_style_dim(title, 11)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var readout := Label.new()
	readout.text = "%d%%" % int(clamp(value, 0.0, 1.0) * 100.0)
	_style_secondary_title(readout, 14)
	readout.modulate = accent.lightened(0.22)
	header.add_child(readout)

	var meter_bg := ColorRect.new()
	meter_bg.color = Color(1.0, 1.0, 1.0, 0.10)
	meter_bg.custom_minimum_size = Vector2(0, 6)
	box.add_child(meter_bg)

	var meter := ColorRect.new()
	meter.color = Color(accent.r, accent.g, accent.b, 0.82)
	meter.custom_minimum_size = Vector2(92.0 * clamp(value, 0.0, 1.0), 6)
	box.add_child(meter)
	return panel


func _make_route_stage_strip(active_route_profile: Dictionary, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	var stage_titles: Array = active_route_profile.get("route_stage_titles", [])
	var items: Array = [
		{"label": "主走廊", "value": str(active_route_profile.get("primary_stage_title", "待命"))},
		{"label": "二阶段", "value": str(active_route_profile.get("secondary_stage_title", "待命"))},
	]
	if stage_titles.size() > 1:
		items[0]["value"] = str(stage_titles[0])
		items[1]["value"] = str(stage_titles[1])

	for index in items.size():
		var item: Dictionary = items[index]
		var stage_panel := PanelContainer.new()
		stage_panel.custom_minimum_size = Vector2(188, 52)
		row.add_child(stage_panel)

		var stage_box := HBoxContainer.new()
		stage_box.add_theme_constant_override("separation", 8)
		stage_panel.add_child(stage_box)

		var dot := ColorRect.new()
		dot.color = Color(accent.r, accent.g, accent.b, 0.9 if index == 0 else 0.6)
		dot.custom_minimum_size = Vector2(16, 16)
		stage_box.add_child(dot)

		var text_box := VBoxContainer.new()
		text_box.add_theme_constant_override("separation", 2)
		stage_box.add_child(text_box)

		var stage_title := Label.new()
		stage_title.text = str(item.get("label", "阶段"))
		_style_dim(stage_title, 11)
		text_box.add_child(stage_title)

		var value := Label.new()
		value.text = str(item.get("value", "待命"))
		_style_body(value, 12)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(value)

		if index < items.size() - 1:
			var link := ColorRect.new()
			link.color = Color(accent.r, accent.g, accent.b, 0.24)
			link.custom_minimum_size = Vector2(20, 3)
			row.add_child(link)

	return panel


func _make_species_signal_strip(top_species: Array, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	if top_species.is_empty():
		row.add_child(_make_hero_chip("核心物种", "当前暂无物种快照", accent))
		return panel

	for species_variant in top_species.slice(0, 3):
		var species: Dictionary = species_variant
		var item_panel := PanelContainer.new()
		item_panel.custom_minimum_size = Vector2(146, 52)
		row.add_child(item_panel)

		var item_box := HBoxContainer.new()
		item_box.add_theme_constant_override("separation", 8)
		item_panel.add_child(item_box)

		var species_icon := Label.new()
		species_icon.text = _species_category_icon(str(species.get("species_id", "")))
		_style_secondary_title(species_icon, 18)
		species_icon.modulate = accent.lightened(0.22)
		item_box.add_child(species_icon)

		var text_box := VBoxContainer.new()
		text_box.add_theme_constant_override("separation", 2)
		item_box.add_child(text_box)

		var name := Label.new()
		name.text = str(species.get("label", species.get("species_id", "物种")))
		_style_body(name, 12)
		text_box.add_child(name)

		var count := Label.new()
		count.text = "× %s" % str(species.get("count", 0))
		_style_dim(count, 11)
		count.modulate = accent.lightened(0.18)
		text_box.add_child(count)

	return panel


func _make_overview_dashboard(active_region: Dictionary, pressure_headlines: Array, chain_focus: Array, route_summary: Array, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var summary: Dictionary = active_region.get("region_summary", {})
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"当前区域",
		str(active_region.get("name", "未选择")),
		"%s · 群系 %s" % [
			str(active_region.get("region_role", "生态观测区")),
			str(summary.get("biome_count", 0)),
		],
		region_accent
	))

	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 4)
	body.add_child(chip_row)
	chip_row.add_child(_make_hero_chip("警报", str(pressure_headlines[0]) if pressure_headlines.size() > 0 else "暂无", Color8(171, 132, 196)))
	chip_row.add_child(_make_hero_chip("路线", str(route_summary[0]) if route_summary.size() > 0 else "暂无", region_accent))
	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_menu_entry_card(title_text: String, main_text: String, sub_text: String, accent: Color, icon_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 84)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var icon_box := VBoxContainer.new()
	icon_box.custom_minimum_size = Vector2(34, 0)
	row.add_child(icon_box)

	var icon := Label.new()
	icon.text = icon_text
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.custom_minimum_size = Vector2(34, 34)
	icon.add_theme_font_size_override("font_size", 22)
	icon.modulate = accent.lightened(0.22)
	icon_box.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	row.add_child(text_box)

	var title := Label.new()
	title.text = title_text
	_style_dim(title, 10)
	text_box.add_child(title)

	var main := Label.new()
	main.text = main_text
	main.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_primary_title(main, 16)
	main.modulate = accent.lightened(0.24)
	text_box.add_child(main)

	var sub := Label.new()
	sub.text = sub_text
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(sub, 10)
	text_box.add_child(sub)
	return panel


func _make_overview_cover(active_region: Dictionary, pressure_headlines: Array, route_summary: Array, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var active_frontier := _active_frontier_link(active_region)
	var active_stage := _active_campaign_stage(active_region)
	var active_landing := _active_campaign_landing(active_region)
	var summary: Dictionary = active_region.get("region_summary", {})

	box.add_child(_make_menu_entry_card(
		"当前区域",
		str(active_region.get("name", "未选择")),
		str(summary.get("one_liner", active_region.get("region_role", "生态观测区"))),
		region_accent,
		REGION_ICONS.get(str(active_region.get("id", active_region_id)), "区")
	))

	box.add_child(_make_menu_entry_card(
		"路线入口",
		str(active_frontier.get("target_name", "待命")),
		str(active_frontier.get("connection_label", "区域通道")),
		Color8(102, 152, 204),
		"➜"
	))

	box.add_child(_make_menu_entry_card(
		"推进目标",
		str(active_landing.get("name", active_stage.get("title", "待命"))),
		"%s · %s" % [
			str(active_stage.get("stage", "阶段待命")),
			str(pressure_headlines[0]) if pressure_headlines.size() > 0 else (str(route_summary[0]) if route_summary.size() > 0 else "暂无")
		],
		Color8(171, 132, 196),
		"✦"
	))

	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_chains_cover(active_region: Dictionary, chains: Dictionary, chain_focus: Array, pressure_headlines: Array, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	box.add_child(_make_menu_entry_card(
		"主导生态链",
		_lead_chain_line(chains.get("grassland_chain", chains.get("wetland_chain", []))),
		str(chain_focus[0]) if chain_focus.size() > 0 else "当前暂无主链摘要",
		region_accent,
		"≈"
	))

	box.add_child(_make_menu_entry_card(
		"社会相位",
		_lead_chain_line(chains.get("social_phases", [])),
		_lead_chain_line(chains.get("territory", [])),
		Color8(102, 152, 204),
		"◌"
	))

	box.add_child(_make_menu_entry_card(
		"风险焦点",
		str(pressure_headlines[0]) if pressure_headlines.size() > 0 else "当前暂无风险焦点",
		_lead_chain_line(chains.get("competition", [])),
		Color8(171, 132, 196),
		"⚑"
	))

	return _wrap_menu_card(box, Color8(104, 171, 144))


func _make_species_cover(active_region: Dictionary, top_species: Array, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var lead_one := _species_entry_label(top_species[0]) if top_species.size() > 0 else "当前暂无领衔物种"
	var lead_two := _species_entry_label(top_species[1]) if top_species.size() > 1 else "等待次位物种"
	var lead_three := _species_entry_label(top_species[2]) if top_species.size() > 2 else "等待第三位物种"

	box.add_child(_make_menu_entry_card(
		"领衔物种",
		lead_one,
		_region_type_label(active_region),
		region_accent,
		_species_category_icon(str((top_species[0] as Dictionary).get("species_id", ""))) if top_species.size() > 0 else "◉"
	))

	box.add_child(_make_menu_entry_card(
		"次位记录",
		lead_two,
		"总种群 %s" % str(active_region.get("species_population", 0)),
		Color8(102, 152, 204),
		_species_category_icon(str((top_species[1] as Dictionary).get("species_id", ""))) if top_species.size() > 1 else "◎"
	))

	box.add_child(_make_menu_entry_card(
		"第三位记录",
		lead_three,
		"核心队列 %s" % str(min(top_species.size(), 3)),
		Color8(171, 132, 196),
		_species_category_icon(str((top_species[2] as Dictionary).get("species_id", ""))) if top_species.size() > 2 else "✦"
	))

	return _wrap_menu_card(box, Color8(171, 132, 196))


func _make_story_cover(active_region: Dictionary, narrative: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	box.add_child(_make_menu_entry_card(
		"主主播报",
		_lead_story_line(narrative.get("territory", [])),
		_lead_story_line(narrative.get("social_trends", [])),
		region_accent,
		"✦"
	))

	box.add_child(_make_menu_entry_card(
		"主链播报",
		_lead_story_line(narrative.get("grassland_chain", narrative.get("wetland_chain", []))),
		_lead_story_line(narrative.get("predation", [])),
		Color8(102, 152, 204),
		"≈"
	))

	box.add_child(_make_menu_entry_card(
		"关系播报",
		_lead_story_line(narrative.get("symbiosis", [])),
		_lead_story_line(narrative.get("carrion_chain", [])),
		Color8(210, 182, 96),
		"◌"
	))

	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_frontier_overview_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var active_frontier := _active_frontier_link(active_region)
	var active_frontier_network := _active_frontier_network(active_region)
	var active_operation := _active_frontier_operation(active_region)
	var active_campaign := _active_frontier_campaign(active_region)
	var branches: Array = active_frontier_network.get("branches", [])

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
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
		"路线",
		lead_text,
		sub_text,
		region_accent
	))

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 4)
	body.add_child(footer_row)
	footer_row.add_child(_make_hero_chip("模式", str(active_campaign.get("campaign_band", "待命")), Color8(171, 132, 196)))
	footer_row.add_child(_make_hero_chip("态势", "%s/%s" % [
		str(active_operation.get("threat_band", "待命")),
		str(active_operation.get("opportunity_band", "待命")),
	], Color8(104, 171, 144)))

	if frontier_links.is_empty():
		body.add_child(_make_hero_chip("前线", "当前暂无前线邻区", Color8(102, 152, 204)))

	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_frontier_operation_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_operation := _active_frontier_operation(active_region)
	var route_stages: Array = active_operation.get("route_stages", [])
	var badges: Array = active_operation.get("badges", [])

	var title := Label.new()
	title.text = "%s · 前线行动总板" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"当前行动姿态",
		str(active_operation.get("posture", "等待前线方案")),
		str(active_operation.get("summary", "当前暂无前线行动方案。")),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("威胁带", str(active_operation.get("threat_band", "等待威胁判断")), Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("机会带", str(active_operation.get("opportunity_band", "等待机会判断")), Color8(104, 171, 144)))
	stack.add_child(_make_hero_chip(
		"第一跳",
		str((route_stages[0] as Dictionary).get("title", "等待前线方案")) if route_stages.size() > 0 else "等待前线方案",
		Color8(102, 152, 204)
	))
	stack.add_child(_make_hero_chip(
		"第二跳",
		str((route_stages[1] as Dictionary).get("title", "等待二级分支")) if route_stages.size() > 1 else "等待二级分支",
		Color8(210, 182, 96)
	))

	if not badges.is_empty():
		var badge_row := HBoxContainer.new()
		badge_row.add_theme_constant_override("separation", 8)
		box.add_child(badge_row)
		for badge_variant in badges.slice(0, 3):
			badge_row.add_child(_make_hero_chip("战区标签", str(badge_variant), region_accent))

	return _wrap_menu_card(box, Color8(171, 132, 196))


func _make_campaign_atlas_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_campaign := _active_frontier_campaign(active_region)
	var active_stage := _active_campaign_stage(active_region)
	var active_feedback := _active_activation_feedback(active_region)
	var campaigns: Array = active_region.get("frontier_campaigns", []).duplicate(true)
	campaigns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_priority := str(a.get("target_region_id", "")) == str(active_feedback.get("priority_target_id", ""))
		var b_priority := str(b.get("target_region_id", "")) == str(active_feedback.get("priority_target_id", ""))
		if a_priority != b_priority:
			return a_priority
		return str(a.get("campaign_name", "")) < str(b.get("campaign_name", ""))
	)

	var title := Label.new()
	title.text = "%s · 战区图谱总板" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"当前战区",
		str(active_campaign.get("campaign_name", "等待战区推进模式")),
		str(active_campaign.get("summary", "当前暂无战区推演摘要。")),
		_campaign_accent(str(active_campaign.get("campaign_band", "")))
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)

	for campaign_variant in campaigns.slice(0, 3):
		var campaign: Dictionary = campaign_variant
		stack.add_child(_make_hero_chip(
			"%s%s" % ["当前 · " if str(campaign.get("target_region_id", "")) == selected_campaign_target_id else "", str(campaign.get("campaign_band", "战区推进令"))],
			str(campaign.get("campaign_name", "等待战区推进模式")),
			_campaign_accent(str(campaign.get("campaign_band", "")))
		))

	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 8)
	box.add_child(stage_row)
	stage_row.add_child(_make_hero_chip("当前阶段", str(active_stage.get("stage", "阶段待命")), region_accent))
	stage_row.add_child(_make_hero_chip("阶段目标", str(active_stage.get("title", "等待阶段目标")), Color8(102, 152, 204)))
	stage_row.add_child(_make_hero_chip("回路优先", str(active_feedback.get("priority_target_name", "待命")), Color8(171, 132, 196)))

	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_campaign_landing_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var active_stage := _active_campaign_stage(active_region)
	var active_landing := _active_campaign_landing(active_region)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		"目标",
		str(active_landing.get("name", active_stage.get("title", "等待落点"))),
		str(active_landing.get("region_role", active_stage.get("detail", "当前暂无推进落点说明。"))),
		region_accent
	))

	var stack := HBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("阶段", str(active_stage.get("stage", "阶段待命")), Color8(210, 182, 96)))
	stack.add_child(_make_hero_chip("风险", "%.2f" % float(active_landing.get("health_state", {}).get("collapse_risk", 0.0)), Color8(171, 132, 196)))

	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_campaign_route_confirmation_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_profile := _active_route_profile(active_region)
	var active_landing := _active_campaign_landing(active_region)

	var title := Label.new()
	title.text = "%s · 推进路线确认终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_profile.get("confirmation_band", "等待路线确认")),
		str(active_profile.get("route_name", "等待当前推进路线")),
		str(active_profile.get("summary", "当前暂无推进路线确认摘要。")),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("主走廊", str(active_profile.get("primary_stage_title", "等待主走廊")), Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("二阶段", str(active_profile.get("secondary_stage_title", "等待二阶段")), Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("锁定落点", str(active_landing.get("name", "等待锁定落点")), Color8(210, 182, 96)))

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	box.add_child(badge_row)
	for badge_variant in (active_profile.get("badges", []) as Array).slice(0, 4):
		badge_row.add_child(_make_hero_chip("路线信号", str(badge_variant), Color8(104, 171, 144)))

	return _wrap_menu_card(box, Color8(104, 171, 144))


func _make_campaign_execution_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_plan := _active_execution_plan(active_region)
	var plans: Array = active_region.get("frontier_execution_plans", [])

	var title := Label.new()
	title.text = "%s · 推进路线执行终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_plan.get("execution_mode", "等待执行层")),
		str(active_plan.get("route_name", "等待当前执行路线")),
		str(active_plan.get("summary", "当前暂无执行路线摘要。")),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("就绪带", str(active_plan.get("ready_band", "待命")), Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("压力带", str(active_plan.get("pressure_band", "待命")), Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("锁定落点", str(active_plan.get("landing_name", "等待落点")), Color8(210, 182, 96)))

	var plan_row := HBoxContainer.new()
	plan_row.add_theme_constant_override("separation", 8)
	box.add_child(plan_row)
	for plan_variant in plans.slice(0, 3):
		var plan: Dictionary = plan_variant
		var is_active := str(plan.get("target_region_id", "")) == selected_campaign_target_id
		plan_row.add_child(_make_hero_chip(
			"%s%s" % ["当前 · " if is_active else "", str(plan.get("execution_mode", "执行层"))],
			"%s · %s" % [str(plan.get("landing_name", "等待落点")), str(plan.get("ready_band", "待命"))],
			region_accent if is_active else Color8(104, 171, 144)
		))

	return _wrap_menu_card(box, Color8(171, 132, 196))


func _make_campaign_schedule_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_schedule := _active_schedule_profile(active_region)
	var active_formation := _active_formation_profile(active_region)
	var active_preset := _active_formation_preset(active_region)
	var active_feedback := _active_activation_feedback(active_region)
	var active_route := _active_schedule_route(active_region)
	var reordered_routes := _reordered_schedule_routes(active_region, active_schedule)
	var formations: Array = active_region.get("frontier_formation_profiles", [])

	var title := Label.new()
	title.text = "%s · 推进路线调度终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_formation.get("formation_band", active_schedule.get("dispatch_band", "等待调度"))),
		str(active_formation.get("formation_name", active_schedule.get("schedule_name", "等待当前调度方案"))),
		str(active_formation.get("summary", active_schedule.get("summary", "当前暂无推进路线调度摘要。"))),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("当前调度", str(active_route.get("label", "待命")), Color8(104, 171, 144)))
	stack.add_child(_make_hero_chip("调度落点", str(active_route.get("landing_name", "待命")), Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("调度就绪", str(active_route.get("ready_band", "待命")), Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("回路编排", str(active_feedback.get("comparison_focus", "综合推进")), Color8(210, 182, 96)))

	var formation_row := HBoxContainer.new()
	formation_row.add_theme_constant_override("separation", 8)
	box.add_child(formation_row)
	for formation_variant in formations.slice(0, 3):
		var formation: Dictionary = formation_variant
		var formation_key := str(formation.get("formation_key", ""))
		var is_active_formation := formation_key == selected_formation_key
		var formation_button := Button.new()
		formation_button.text = "%s%s" % [
			"当前 · " if is_active_formation else "",
			str(formation.get("formation_name", "编成")),
		]
		formation_button.toggle_mode = true
		formation_button.button_pressed = is_active_formation
		formation_button.pressed.connect(_on_formation_selected.bind(formation_key))
		formation_row.add_child(formation_button)

	var route_row := HBoxContainer.new()
	route_row.add_theme_constant_override("separation", 8)
	box.add_child(route_row)
	for route_variant in reordered_routes:
		var route: Dictionary = route_variant
		var route_key := str(route.get("route_key", "primary_route"))
		var is_active := route_key == selected_schedule_route_key
		var route_button := Button.new()
		route_button.text = "%s%s · %s" % [
			"当前 · " if is_active else "",
			str(route.get("label", "调度")),
			str(route.get("landing_name", "待命")),
		]
		route_button.toggle_mode = true
		route_button.button_pressed = is_active
		route_button.pressed.connect(_on_schedule_route_selected.bind(route_key))
		route_row.add_child(route_button)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	box.add_child(badge_row)
	for badge_variant in (active_schedule.get("badges", []) as Array).slice(0, 4):
		badge_row.add_child(_make_hero_chip("调度信号", str(badge_variant), Color8(210, 182, 96)))

	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_campaign_formation_preset_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_preset := _active_formation_preset(active_region)
	var presets: Array = active_region.get("frontier_formation_presets", [])

	var title := Label.new()
	title.text = "%s · 编成预案终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_preset.get("formation_band", "等待预案")),
		str(active_preset.get("preset_name", "等待当前预案")),
		str(active_preset.get("summary", "当前暂无编成预案摘要。")),
		region_accent
	))

	var order_box := VBoxContainer.new()
	order_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_box.add_theme_constant_override("separation", 8)
	body.add_child(order_box)
	var route_order: Array = active_preset.get("route_order", [])
	order_box.add_child(_make_hero_chip("序列一", str(route_order[0]) if route_order.size() > 0 else "待命", Color8(104, 171, 144)))
	order_box.add_child(_make_hero_chip("序列二", str(route_order[1]) if route_order.size() > 1 else "待命", Color8(102, 152, 204)))
	order_box.add_child(_make_hero_chip("序列三", str(route_order[2]) if route_order.size() > 2 else "待命", Color8(171, 132, 196)))

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 8)
	box.add_child(preset_row)
	for preset_variant in presets.slice(0, 3):
		var preset: Dictionary = preset_variant
		var is_active := str(preset.get("preset_key", "")) == selected_formation_key
		preset_row.add_child(_make_hero_chip(
			"%s%s" % ["当前 · " if is_active else "", str(preset.get("preset_name", "预案"))],
			str(preset.get("formation_band", "编成")),
			region_accent if is_active else Color8(210, 182, 96)
		))

	return _wrap_menu_card(box, Color8(104, 171, 144))


func _make_campaign_activation_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_activation := _active_activation_profile(active_region)
	var activations: Array = active_region.get("frontier_activation_profiles", [])

	var title := Label.new()
	title.text = "%s · 预案激活终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_activation.get("activation_band", "等待激活")),
		str(active_activation.get("activation_name", "等待当前激活预案")),
		str(active_activation.get("summary", "当前暂无预案激活摘要。")),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	var active_route: Dictionary = active_activation.get("active_route", {})
	stack.add_child(_make_hero_chip("激活预案", str(active_activation.get("preset_name", "待命")), Color8(210, 182, 96)))
	stack.add_child(_make_hero_chip("激活主轴", str(active_route.get("landing_name", "待命")), Color8(104, 171, 144)))
	stack.add_child(_make_hero_chip("激活编成", str(active_activation.get("formation_band", "待命")), Color8(102, 152, 204)))

	var activation_row := HBoxContainer.new()
	activation_row.add_theme_constant_override("separation", 8)
	box.add_child(activation_row)
	for activation_variant in activations.slice(0, 3):
		var activation: Dictionary = activation_variant
		var activation_key := str(activation.get("activation_key", ""))
		var is_active := activation_key == selected_activation_preset_key
		var button := Button.new()
		button.text = "%s%s" % [
			"已激活 · " if is_active else "",
			str(activation.get("preset_name", "预案"))
		]
		button.toggle_mode = true
		button.button_pressed = is_active
		button.pressed.connect(_on_activation_preset_selected.bind(activation_key))
		activation_row.add_child(button)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	box.add_child(badge_row)
	for badge_variant in (active_activation.get("badges", []) as Array).slice(0, 4):
		badge_row.add_child(_make_hero_chip("激活信号", str(badge_variant), Color8(171, 132, 196)))

	return _wrap_menu_card(box, Color8(171, 132, 196))


func _make_campaign_activation_feedback_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_feedback := _active_activation_feedback(active_region)

	var title := Label.new()
	title.text = "%s · 预案回路终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_feedback.get("feedback_band", "等待回路")),
		str(active_feedback.get("feedback_name", "等待当前回路")),
		str(active_feedback.get("summary", "当前暂无预案回路摘要。")),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("回路筛选", _campaign_filter_label(), Color8(210, 182, 96)))
	stack.add_child(_make_hero_chip("回路阶段", str(active_feedback.get("recommended_stage_title", "待命")), Color8(104, 171, 144)))
	stack.add_child(_make_hero_chip("回路落点", str(active_feedback.get("priority_target_name", "待命")), Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("回路编排", str(active_feedback.get("comparison_focus", "综合推进")), Color8(171, 132, 196)))
	stack.add_child(_make_hero_chip("落点定位", str(active_feedback.get("priority_role", "生态观测区")), Color8(171, 132, 196)))

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	box.add_child(badge_row)
	for badge_variant in (active_feedback.get("badges", []) as Array).slice(0, 4):
		badge_row.add_child(_make_hero_chip("回路信号", str(badge_variant), Color8(104, 171, 144)))

	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_campaign_directive_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_directive := _active_directive_profile(active_region)
	var directives: Array = active_region.get("frontier_directive_profiles", [])

	var title := Label.new()
	title.text = "%s · 战区指令终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_directive.get("directive_band", "等待指令")),
		str(active_directive.get("directive_name", "等待当前战区指令")),
		str(active_directive.get("summary", "当前暂无战区指令摘要。")),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("指令筛选", _campaign_filter_label(), Color8(210, 182, 96)))
	stack.add_child(_make_hero_chip("指令阶段", str(active_directive.get("recommended_stage_title", "待命")), Color8(104, 171, 144)))
	stack.add_child(_make_hero_chip("指令主轴", str((active_directive.get("active_route", {}) as Dictionary).get("landing_name", "待命")), Color8(102, 152, 204)))
	stack.add_child(_make_hero_chip("指令编排", str(active_directive.get("comparison_focus", "综合推进")), Color8(171, 132, 196)))

	var directive_row := HBoxContainer.new()
	directive_row.add_theme_constant_override("separation", 8)
	box.add_child(directive_row)
	for directive_variant in directives.slice(0, 3):
		var directive: Dictionary = directive_variant
		var directive_key := str(directive.get("directive_key", ""))
		var is_active := directive_key == selected_directive_key
		var button := Button.new()
		button.text = "%s%s" % [
			"当前 · " if is_active else "",
			str(directive.get("directive_band", "指令"))
		]
		button.toggle_mode = true
		button.button_pressed = is_active
		button.pressed.connect(_on_directive_selected.bind(directive_key))
		directive_row.add_child(button)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	box.add_child(badge_row)
	for badge_variant in (active_directive.get("badges", []) as Array).slice(0, 4):
		badge_row.add_child(_make_hero_chip("指令信号", str(badge_variant), Color8(210, 182, 96)))

	return _wrap_menu_card(box, Color8(104, 171, 144))


func _make_campaign_directive_preview_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_preview := _active_directive_preview(active_region)
	var preview_stages: Array = active_preview.get("preview_stages", [])

	var title := Label.new()
	title.text = "%s · 指令预演终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	body.add_child(_make_feature_panel(
		str(active_preview.get("preview_band", "等待预演")),
		str(active_preview.get("preview_name", "等待当前指令预演")),
		str(active_preview.get("summary", "当前暂无指令预演摘要。")),
		region_accent
	))

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	body.add_child(stack)
	stack.add_child(_make_hero_chip("预演一阶", str((preview_stages[0] as Dictionary).get("target_name", "待命")) if preview_stages.size() > 0 else "待命", Color8(210, 182, 96)))
	stack.add_child(_make_hero_chip("预演二阶", str((preview_stages[1] as Dictionary).get("target_name", "待命")) if preview_stages.size() > 1 else "待命", Color8(104, 171, 144)))
	stack.add_child(_make_hero_chip("预演回退", str((preview_stages[2] as Dictionary).get("target_name", "待命")) if preview_stages.size() > 2 else "待命", Color8(171, 132, 196)))

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	box.add_child(badge_row)
	for badge_variant in (active_preview.get("badges", []) as Array).slice(0, 4):
		badge_row.add_child(_make_hero_chip("预演信号", str(badge_variant), Color8(102, 152, 204)))

	return _wrap_menu_card(box, Color8(102, 152, 204))


func _make_campaign_directive_sandbox_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var sandbox_rows := _directive_sandbox_rows(active_region)

	var title := Label.new()
	title.text = "%s · 指令沙盘终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	if not sandbox_rows.is_empty():
		var top_row: Dictionary = sandbox_rows[0]
		box.add_child(_make_feature_panel(
			"沙盘优选",
			str(top_row.get("sandbox_name", "等待当前沙盘")),
			str(top_row.get("summary", "当前暂无沙盘推演摘要。")),
			region_accent
		))

	for row_variant in sandbox_rows.slice(0, 3):
		var row: Dictionary = row_variant
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 8)
		box.add_child(row_box)
		row_box.add_child(_make_hero_chip(str(row.get("comparison_focus", "综合推进")), str(row.get("primary_target_name", "待命")), Color8(210, 182, 96)))
		row_box.add_child(_make_hero_chip("总分", "%.2f" % float(row.get("sandbox_score", 0.0)), Color8(104, 171, 144)))
		row_box.add_child(_make_hero_chip("回退", str(row.get("fallback_target_name", "待命")), Color8(171, 132, 196)))

	return _wrap_menu_card(box, Color8(171, 132, 196))


func _make_campaign_directive_comparison_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var comparison := _directive_comparison(active_region)
	var best_directive: Dictionary = comparison.get("best_directive", {})
	var active_directive: Dictionary = comparison.get("active_directive", {})
	var risk_directive: Dictionary = comparison.get("risk_directive", {})

	var title := Label.new()
	title.text = "%s · 指令比选终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	box.add_child(_make_feature_panel(
		"比选结论",
		str(best_directive.get("directive_name", "等待比选")),
		str(comparison.get("summary", "当前暂无指令比选摘要。")),
		region_accent
	))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	row.add_child(_make_hero_chip("优选指令", str(best_directive.get("directive_name", "待命")), Color8(210, 182, 96)))
	row.add_child(_make_hero_chip("当前激活", str(active_directive.get("directive_name", "待命")), Color8(104, 171, 144)))
	row.add_child(_make_hero_chip("高风险指令", str(risk_directive.get("directive_name", "待命")), Color8(171, 132, 196)))

	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_campaign_directive_decision_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var decisions := _directive_decisions(active_region)

	var title := Label.new()
	title.text = "%s · 指令定案终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	if not decisions.is_empty():
		var top_decision: Dictionary = decisions[0]
		box.add_child(_make_feature_panel(
			str(top_decision.get("decision_band", "等待定案")),
			str(top_decision.get("decision_name", "等待当前定案")),
			str(top_decision.get("summary", "当前暂无指令定案摘要。")),
			region_accent
		))

	for decision_variant in decisions.slice(0, 3):
		var decision: Dictionary = decision_variant
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		row.add_child(_make_hero_chip(str(decision.get("decision_band", "定案")), str(decision.get("directive_name", "待命")), Color8(210, 182, 96)))
		row.add_child(_make_hero_chip("主轴", str(decision.get("primary_target_name", "待命")), Color8(104, 171, 144)))
		row.add_child(_make_hero_chip("分数", "%.2f" % float(decision.get("sandbox_score", 0.0)), Color8(171, 132, 196)))

	return _wrap_menu_card(box, Color8(104, 171, 144))


func _make_campaign_directive_lock_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var locks: Array = active_region.get("frontier_directive_locks", [])
	var active_lock := _active_directive_lock(active_region)

	var title := Label.new()
	title.text = "%s · 定案锁定终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	if not active_lock.is_empty():
		box.add_child(_make_feature_panel(
			str(active_lock.get("lock_band", "等待锁定")),
			str(active_lock.get("lock_name", "等待当前锁定结论")),
			str(active_lock.get("summary", "当前暂无定案锁定摘要。")),
			region_accent
		))

	var lock_row := HBoxContainer.new()
	lock_row.add_theme_constant_override("separation", 8)
	box.add_child(lock_row)
	for lock_variant in locks.slice(0, 3):
		var lock: Dictionary = lock_variant
		var lock_key := str(lock.get("lock_key", ""))
		var is_active := lock_key == selected_decision_key
		var button := Button.new()
		button.text = "%s%s" % [
			"已锁定 · " if is_active else "",
			str(lock.get("lock_band", "锁定结论"))
		]
		button.toggle_mode = true
		button.button_pressed = is_active
		button.pressed.connect(_on_decision_lock_selected.bind(lock_key))
		lock_row.add_child(button)

	return _wrap_menu_card(box, Color8(171, 132, 196))


func _make_campaign_directive_confirmation_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var confirmations: Array = active_region.get("frontier_directive_confirmations", [])
	var active_confirmation := _active_directive_confirmation(active_region)

	var title := Label.new()
	title.text = "%s · 定案确认终端" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	if not active_confirmation.is_empty():
		box.add_child(_make_feature_panel(
			str(active_confirmation.get("confirmation_band", "等待确认")),
			str(active_confirmation.get("confirmation_name", "等待当前确认通令")),
			str(active_confirmation.get("summary", "当前暂无定案确认摘要。")),
			region_accent
		))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for confirmation_variant in confirmations.slice(0, 3):
		var confirmation: Dictionary = confirmation_variant
		var confirmation_key := str(confirmation.get("confirmation_key", ""))
		var is_active := confirmation_key == selected_confirmation_key
		var button := Button.new()
		button.text = "%s%s" % [
			"已确认 · " if is_active else "",
			str(confirmation.get("confirmation_band", "确认通令"))
		]
		button.toggle_mode = true
		button.button_pressed = is_active
		button.pressed.connect(_on_directive_confirmation_selected.bind(confirmation_key))
		row.add_child(button)

	return _wrap_menu_card(box, Color8(210, 182, 96))


func _make_campaign_landing_network_card(active_region: Dictionary, region_accent: Color) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var active_stage := _active_campaign_stage(active_region)
	var candidates: Array = _campaign_landing_candidates(active_region)
	var active_landing := _active_campaign_landing(active_region)

	var title := Label.new()
	title.text = "%s · 落点网络总板" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	var filter_chip_row := HBoxContainer.new()
	filter_chip_row.add_theme_constant_override("separation", 8)
	box.add_child(filter_chip_row)
	filter_chip_row.add_child(_make_hero_chip("当前筛选", _campaign_filter_label(), region_accent))
	filter_chip_row.add_child(_make_hero_chip("排序依据", "评分从高到低", Color8(102, 152, 204)))

	if not candidates.is_empty():
		var summary_row := HBoxContainer.new()
		summary_row.add_theme_constant_override("separation", 8)
		box.add_child(summary_row)

		var best_candidate: Dictionary = candidates[0]
		var risk_sorted := candidates.duplicate()
		risk_sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("risk", 0.0)) > float(b.get("risk", 0.0))
		)
		var riskiest_candidate: Dictionary = risk_sorted[0]

		summary_row.add_child(_make_hero_chip(
			"优选推进",
			"%s · %.2f" % [str(best_candidate.get("name", "")), float(best_candidate.get("score", 0.0))],
			region_accent
		))
		summary_row.add_child(_make_hero_chip(
			"当前落点",
			"%s" % str(active_landing.get("name", active_stage.get("title", "等待落点"))),
			Color8(102, 152, 204)
		))
		summary_row.add_child(_make_hero_chip(
			"高风险分支",
			"%s · %.2f" % [str(riskiest_candidate.get("name", "")), float(riskiest_candidate.get("risk", 0.0))],
			Color8(171, 132, 196)
		))

	for landing_variant in candidates:
		var landing: Dictionary = landing_variant
		var landing_id := str(landing.get("target_region_id", ""))
		var is_stage := landing_id == str(active_stage.get("target_region_id", ""))
		var is_locked := landing_id == selected_campaign_landing_target_id
		var chip_row := HBoxContainer.new()
		chip_row.add_theme_constant_override("separation", 8)
		chip_row.add_child(_make_hero_chip(
			"%s%s%s" % [
				"锁定 · " if is_locked else "",
				"阶段 · " if is_stage and not is_locked else "",
				str(landing.get("stage_label", "落点"))
			],
			"%s · 评分 %.2f · 繁荣 %.2f · 风险 %.2f" % [
				str(landing.get("name", landing_id)),
				float(landing.get("score", 0.0)),
				float(landing.get("prosperity", 0.0)),
				float(landing.get("risk", 0.0)),
			],
			region_accent if is_locked else Color8(171, 132, 196)
		))
		var lock_button := Button.new()
		lock_button.text = "锁定推进"
		lock_button.disabled = is_locked
		lock_button.pressed.connect(_on_campaign_landing_selected.bind(landing_id))
		chip_row.add_child(lock_button)
		box.add_child(chip_row)

	return _wrap_menu_card(box, Color8(171, 132, 196))


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
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = accent.lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 6)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = title_text
	_style_dim(title, 10)
	box.add_child(title)

	var main := Label.new()
	main.text = main_text
	main.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_primary_title(main, 14)
	main.modulate = accent.lightened(0.24)
	box.add_child(main)

	var body := Label.new()
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(body, 9)
	box.add_child(body)
	return panel


func _lead_chain_line(rows: Array) -> String:
	if rows.is_empty():
		return "当前暂无重点读数"
	var row: Variant = rows[0]
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

	var summary: Dictionary = active_region.get("region_summary", {})
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

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)

	for row_variant in top_species.slice(0, 6):
		var row: Dictionary = row_variant
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 92)
		grid.add_child(card)

		var row_box := VBoxContainer.new()
		row_box.add_theme_constant_override("separation", 4)
		card.add_child(row_box)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 8)
		row_box.add_child(header)

		var chip := Label.new()
		chip.text = {
			"顶层种": "✦",
			"草食群": "◎",
			"岸带种": "≈",
			"水域种": "◌",
		}.get(_species_category(str(row.get("species_id", ""))), "◉")
		_style_secondary_title(chip, 22)
		header.add_child(chip)

		var name := Label.new()
		name.text = str(row.get("label", row.get("species_id", "")))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_body(name, 16)
		header.add_child(name)

		var count := Label.new()
		count.text = str(row.get("count", 0))
		_style_secondary_title(count, 16)
		header.add_child(count)

		var category := Label.new()
		category.text = _species_category(str(row.get("species_id", "")))
		_style_dim(category, 12)
		row_box.add_child(category)

		var meter_bg := ColorRect.new()
		meter_bg.color = Color(1.0, 1.0, 1.0, 0.08)
		meter_bg.custom_minimum_size = Vector2(0, 5)
		row_box.add_child(meter_bg)

		var meter := ColorRect.new()
		meter.color = Color(171.0 / 255.0, 132.0 / 255.0, 196.0 / 255.0, 0.72)
		meter.custom_minimum_size = Vector2(112.0 * clamp(float(row.get("count", 0)) / 40.0, 0.05, 1.0), 5)
		row_box.add_child(meter)
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

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	story.add_child(grid)

	for key in ["territory", "social_trends", "grassland_chain", "carrion_chain", "wetland_chain", "symbiosis", "predation"]:
		var rows: Array = narrative.get(key, [])
		if rows.is_empty():
			continue

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 110)
		grid.add_child(card)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)

		var ribbon := ColorRect.new()
		ribbon.color = _story_accent(key)
		ribbon.custom_minimum_size = Vector2(0, 6)
		box.add_child(ribbon)

		var section_title := Label.new()
		section_title.text = _story_title(key)
		_style_secondary_title(section_title, 16)
		box.add_child(section_title)

		var item := Label.new()
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.text = str(rows[0])
		_style_body(item, 13)
		box.add_child(item)
	return story


func _make_badge_list(title_text: String, rows: Array, active_region: Dictionary) -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "%s · %s" % [_region_type_chip(active_region), title_text]
	_style_primary_title(title, 22)
	box.add_child(title)

	for line in rows.slice(0, 3):
		var item := Label.new()
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.text = "◆ %s" % str(line)
		_style_body(item, 13)
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
	selected_campaign_stage_index = 0
	selected_campaign_landing_target_id = ""
	selected_schedule_route_key = "primary_route"
	selected_formation_key = "assault"
	selected_activation_preset_key = "assault"
	selected_directive_key = "assault"
	selected_decision_key = "assault"
	selected_confirmation_key = "assault"
	selected_frontier_target_id = ""
	status_label.text = "系统栏 · 已切换焦点区域：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_region_transition(_active_region_accent())


func _on_frontier_focus_selected(region_id: String) -> void:
	selected_campaign_target_id = region_id
	selected_frontier_target_id = region_id
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	_sync_branch_focus(active_region)
	status_label.text = "系统栏 · 已锁定前线目标：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(102, 152, 204))


func _on_frontier_branch_selected(region_id: String) -> void:
	selected_branch_target_id = region_id
	status_label.text = "系统栏 · 已锁定网络分支：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(210, 182, 96))


func _on_frontier_campaign_selected(region_id: String) -> void:
	selected_campaign_target_id = region_id
	selected_frontier_target_id = region_id
	selected_campaign_stage_index = 0
	selected_campaign_landing_target_id = ""
	selected_schedule_route_key = "primary_route"
	selected_formation_key = "assault"
	selected_activation_preset_key = "assault"
	selected_directive_key = "assault"
	selected_decision_key = "assault"
	selected_confirmation_key = "assault"
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	_sync_campaign_landing(active_region)
	_sync_branch_focus(active_region)
	status_label.text = "系统栏 · 已切换战区推进模式：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(171, 132, 196))


func _on_campaign_stage_selected(stage_index: int) -> void:
	selected_campaign_stage_index = stage_index
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	selected_campaign_landing_target_id = ""
	selected_schedule_route_key = "primary_route"
	selected_formation_key = "assault"
	selected_activation_preset_key = "assault"
	selected_directive_key = "assault"
	selected_decision_key = "assault"
	selected_confirmation_key = "assault"
	_sync_campaign_landing(active_region)
	status_label.text = "系统栏 · 已切换推进阶段：%s · 当前分页：%s" % [str(stage_index + 1), _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(210, 182, 96))


func _on_campaign_filter_selected(filter_key: String) -> void:
	selected_campaign_filter = filter_key
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	selected_schedule_route_key = "primary_route"
	selected_formation_key = "assault"
	selected_activation_preset_key = "assault"
	selected_directive_key = "assault"
	selected_decision_key = "assault"
	selected_confirmation_key = "assault"
	_sync_campaign_landing(active_region)
	status_label.text = "系统栏 · 已切换战区筛选：%s · 当前分页：%s" % [_campaign_filter_label(), _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(104, 171, 144))


func _on_campaign_landing_selected(region_id: String) -> void:
	selected_campaign_landing_target_id = region_id
	status_label.text = "系统栏 · 已锁定推进落点：%s · 当前分页：%s" % [region_id, _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(171, 132, 196))


func _on_formation_selected(formation_key: String) -> void:
	selected_formation_key = formation_key
	selected_activation_preset_key = formation_key
	selected_directive_key = formation_key
	selected_decision_key = formation_key
	selected_confirmation_key = formation_key
	selected_schedule_route_key = "primary_route"
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var active_route := _active_schedule_route(active_region)
	var target_region_id := str(active_route.get("target_region_id", ""))
	if target_region_id != "":
		selected_campaign_target_id = target_region_id
		selected_frontier_target_id = target_region_id
		selected_campaign_landing_target_id = target_region_id
	status_label.text = "系统栏 · 已切换战区编成：%s · 当前分页：%s" % [formation_key, _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(104, 171, 144))


func _on_activation_preset_selected(activation_key: String) -> void:
	selected_activation_preset_key = activation_key
	selected_formation_key = activation_key
	selected_directive_key = activation_key
	selected_decision_key = activation_key
	selected_confirmation_key = activation_key
	selected_schedule_route_key = "primary_route"
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	_apply_activation_feedback(active_region)
	var active_feedback := _active_activation_feedback(active_region)
	status_label.text = "系统栏 · 已激活战区预案：%s · 回路已切到 %s / %s · 当前分页：%s" % [
		activation_key,
		_campaign_filter_label(),
		str(active_feedback.get("recommended_stage_title", "待命")),
		_tab_title(selected_tab)
	]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(171, 132, 196))


func _on_directive_selected(directive_key: String) -> void:
	selected_directive_key = directive_key
	selected_activation_preset_key = directive_key
	selected_formation_key = directive_key
	selected_decision_key = directive_key
	selected_confirmation_key = directive_key
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	_apply_directive_profile(active_region)
	var active_directive := _active_directive_profile(active_region)
	status_label.text = "系统栏 · 已切换战区指令：%s · 当前分页：%s" % [
		str(active_directive.get("directive_band", directive_key)),
		_tab_title(selected_tab)
	]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(104, 171, 144))


func _on_decision_lock_selected(decision_key: String) -> void:
	selected_decision_key = decision_key
	selected_confirmation_key = decision_key
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	_apply_decision_lock(active_region)
	var active_lock := _active_directive_lock(active_region)
	status_label.text = "系统栏 · 已锁定战区定案：%s · 当前分页：%s" % [
		str(active_lock.get("lock_band", decision_key)),
		_tab_title(selected_tab)
	]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(171, 132, 196))


func _on_directive_confirmation_selected(confirmation_key: String) -> void:
	selected_confirmation_key = confirmation_key
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	_apply_directive_confirmation(active_region)
	var active_confirmation := _active_directive_confirmation(active_region)
	status_label.text = "系统栏 · 已确认战区定案：%s · 当前分页：%s" % [
		str(active_confirmation.get("confirmation_band", confirmation_key)),
		_tab_title(selected_tab)
	]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(210, 182, 96))


func _on_schedule_route_selected(route_key: String) -> void:
	selected_schedule_route_key = route_key
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var active_schedule := _active_schedule_profile(active_region)
	var route: Dictionary = active_schedule.get(route_key, {})
	var target_region_id := str(route.get("target_region_id", ""))
	if target_region_id != "":
		selected_campaign_target_id = target_region_id
		selected_frontier_target_id = target_region_id
		selected_campaign_landing_target_id = target_region_id
	status_label.text = "系统栏 · 已切换调度路线：%s · 当前分页：%s" % [str(route.get("label", route_key)), _tab_title(selected_tab)]
	_render_world()
	_animate_page_transition(_active_region_accent(), Color8(210, 182, 96))


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

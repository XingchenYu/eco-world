extends Control

const RealisticWorldMapCanvas = preload("res://scripts/realistic_world_map_canvas.gd")
const DATA_PATH := "res://data/world_state.json"
const PROJECT_STRATEGY_PATH := "res://data/world_strategy_intent.json"
const EXPLORER_SCENE := "res://scenes/savanna_explorer.tscn"
const REPORT_PATH := "user://expedition_reports.json"
const EXPEDITION_REGION_PATH := "user://selected_expedition_region.json"
const PROJECT_EXPEDITION_REGION_PATH := "res://data/selected_expedition_region.json"
const STRATEGY_PATH := "user://world_strategy_intent.json"
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
var map_viewport: Control
var map_layer: Control
var side_panel: PanelContainer
var side_scroll: ScrollContainer
var side_box: VBoxContainer
var footer_box: VBoxContainer
var footer_command_holder: HBoxContainer
var game_hud: PanelContainer
var hud_region_label: Label
var hud_summary_label: Label
var hud_world_label: Label
var hud_loop_label: Label
var hud_metric_label: Label
var hud_species_label: Label
var hud_objective_label: Label
var hud_action_label: Label
var action_buttons: Dictionary = {}
var focus_recommended_button: Button
var apply_turn_button: Button
var enter_region_button: Button
var selected_game_action := "调查"
var pending_strategy_message := ""
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
var expedition_reports: Dictionary = {}
var ui_font_resource: Font
var map_zoom := 1.0
var map_pan := Vector2.ZERO
var map_panning := false
var map_pan_mouse_start := Vector2.ZERO
var map_pan_start := Vector2.ZERO


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


func _animate_focus_glow(glow: Control, focus_frame: Control) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.92, 0.75)
	tween.parallel().tween_property(focus_frame, "modulate:a", 0.88, 0.75)
	tween.tween_property(glow, "modulate:a", 0.42, 0.75)
	tween.parallel().tween_property(focus_frame, "modulate:a", 0.38, 0.75)


func _animate_region_focus_entry(shell: Control, outer_ring: Control, shadow: Control, shell_base: Vector2, shadow_base: Vector2) -> void:
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


func _animate_region_hover(shell: Control, outer_ring: Control, shadow: Control, entering: bool) -> void:
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


func _region_report(region_id: String) -> Dictionary:
	return expedition_reports.get(region_id, {})


func _join_summary_parts(parts: Array) -> String:
	var text_parts := PackedStringArray()
	for part_variant in parts:
		var part := str(part_variant).strip_edges()
		if part != "":
			text_parts.append(part)
	return " · ".join(text_parts)


func _region_report_summary(region_id: String) -> String:
	var report := _region_report(region_id)
	if report.is_empty():
		return "尚无 expedition 回执"
	var parts: Array = []
	parts.append(_region_archive_tier(report))
	parts.append("%s / 情报 %s" % [str(report.get("top_intel_channel", "未分类")), str(report.get("intel", 0))])
	parts.append("风险 %.2f" % float(report.get("risk", 0.0)))
	var management_phase := str(report.get("management_rotation_phase", "常规经营"))
	if management_phase != "常规经营":
		parts.append(management_phase)
	var lock_completion := _region_lock_completion_tag(report)
	if lock_completion != "未成型":
		parts.append(lock_completion)
	var handoff_completion := _region_handoff_completion_tag(report)
	if handoff_completion != "未承接":
		parts.append(handoff_completion)
	var first_segment_completion := _region_first_segment_completion_tag(report)
	if first_segment_completion != "非第一站":
		parts.append(first_segment_completion)
	var second_segment_completion := _region_second_segment_completion_tag(report)
	if second_segment_completion != "非第二段":
		parts.append(second_segment_completion)
	var branch_completion := _region_branch_completion_tag(report)
	if branch_completion != "非分支段":
		parts.append(branch_completion)
	var branch_stability := _region_branch_stability_tag(report)
	if branch_stability != "分支未定型":
		parts.append(branch_stability)
	var backbone_completion := str(report.get("backbone_completion_tag", ""))
	if backbone_completion != "":
		parts.append(backbone_completion)
	return _join_summary_parts(parts)


func _region_archive_tier(report: Dictionary) -> String:
	if report.is_empty():
		return "未建档"
	return str(report.get("archive_tier", "初勘档案"))


func _region_archive_progress(report: Dictionary) -> int:
	if report.is_empty():
		return 0
	return int(report.get("archive_progress", 0))


func _region_archive_ratio(report: Dictionary) -> float:
	match _region_archive_tier(report):
		"定型档案":
			return 1.0
		"熟悉档案":
			return clampf(float(_region_archive_progress(report)) / 12.0, 0.0, 1.0)
		"已知档案":
			return clampf(float(_region_archive_progress(report)) / 7.0, 0.0, 1.0)
		"初勘档案":
			return clampf(float(_region_archive_progress(report)) / 3.0, 0.0, 1.0)
		_:
			return clampf(float(_region_archive_progress(report)) / 12.0, 0.0, 1.0)


func _region_known_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "未知区"
	var dominant_channel := str(report.get("dominant_intel_channel", report.get("top_intel_channel", "未分类")))
	var dominant_window := str(report.get("dominant_window", report.get("event_window", "focus")))
	var channel_text: String = {
		"水源": "水源线",
		"迁徙": "迁徙线",
		"压迫": "压迫线",
		"腐食": "腐食线",
		"栖地": "栖地线",
	}.get(dominant_channel, dominant_channel)
	var window_text: String = {
		"predation": "捕食窗",
		"pressure": "压力窗",
		"risk": "风险窗",
		"territory": "领地窗",
		"symbiosis": "共生窗",
		"carrion": "腐食窗",
		"focus": "主线窗",
		"trend": "趋势窗",
		"handoff": "承接窗",
	}.get(dominant_window, "观察窗")
	return "%s · %s · %s · %s · %s" % [_region_archive_tier(report), channel_text, window_text, _region_specialization_tag(report), _region_run_profile_tag(report)]


func _region_focus_brief(report: Dictionary) -> String:
	if report.is_empty():
		return "当前无区域画像"
	var dominant_channel := str(report.get("dominant_intel_channel", report.get("top_intel_channel", "未分类")))
	var dominant_window := str(report.get("dominant_window", report.get("event_window", "focus")))
	var channel_text: String = {
		"水源": "水源线",
		"迁徙": "迁徙线",
		"压迫": "压迫线",
		"腐食": "腐食线",
		"栖地": "栖地线",
	}.get(dominant_channel, dominant_channel)
	var window_text: String = {
		"predation": "捕食窗",
		"pressure": "压力窗",
		"risk": "风险窗",
		"territory": "领地窗",
		"symbiosis": "共生窗",
		"carrion": "腐食窗",
		"focus": "主线窗",
		"trend": "趋势窗",
		"handoff": "承接窗",
	}.get(dominant_window, "观察窗")
	return "%s · %s" % [channel_text, window_text]


func _region_specialization_mode(report: Dictionary) -> String:
	if report.is_empty():
		return "基础线"
	return str(report.get("specialization_mode", "基础线"))


func _region_specialization_target(report: Dictionary) -> String:
	if report.is_empty():
		return "未定向"
	return str(report.get("specialization_target", report.get("dominant_intel_channel", report.get("top_intel_channel", "未定向"))))


func _region_specialization_tag(report: Dictionary) -> String:
	match _region_specialization_mode(report):
		"快取线":
			return "快取线"
		"深挖线":
			return "深挖线"
		_:
			return "基础线"


func _region_specialization_run_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "无回线"
	return str(report.get("specialization_run_tag", "基础观察"))


func _region_dominant_run_style(report: Dictionary) -> String:
	if report.is_empty():
		return "基础观察"
	return str(report.get("dominant_run_style", _region_specialization_run_tag(report)))


func _region_run_profile_tag(report: Dictionary) -> String:
	match _region_dominant_run_style(report):
		"快取完成":
			return "快取惯性"
		"深挖完成":
			return "深挖惯性"
		"快取未完成":
			return "快取试探"
		"深挖未完成":
			return "深挖试探"
		_:
			return "基础观察"


func _region_dominant_route_style(report: Dictionary) -> String:
	if report.is_empty():
		return "base"
	return str(report.get("dominant_route_style", "base"))


func _region_route_style_streak(report: Dictionary) -> int:
	if report.is_empty():
		return 0
	var dominant_style := _region_dominant_route_style(report)
	if str(report.get("route_style_streak_style", dominant_style)) != dominant_style:
		return 0
	return int(report.get("route_style_streak", 0))


func _region_route_shaping_tag(report: Dictionary) -> String:
	var dominant_style := _region_dominant_route_style(report)
	var streak := _region_route_style_streak(report)
	match dominant_style:
		"quick":
			if streak >= 5:
				return "快取塑形稳固"
			if streak >= 3:
				return "快取塑形中"
		"deep":
			if streak >= 4:
				return "深挖塑形稳固"
			if streak >= 3:
				return "深挖塑形中"
		"base":
			if streak >= 3:
				return "基础塑形中"
	return "塑形待定"


func _region_route_lock_tag(report: Dictionary) -> String:
	var dominant_style := _region_dominant_route_style(report)
	var streak := _region_route_style_streak(report)
	var archive_tier := _region_archive_tier(report)
	match dominant_style:
		"quick":
			if streak >= 6 and archive_tier in ["已知档案", "熟悉档案", "定型档案"]:
				return "快取锁定"
		"deep":
			if streak >= 5 and archive_tier in ["已知档案", "熟悉档案", "定型档案"]:
				return "深挖锁定"
	return "未锁定"


func _region_lock_completion_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "未成型"
	if bool(report.get("route_lock_completed", false)):
		return "锁定跑成"
	var lock_tag := _region_route_lock_tag(report)
	if lock_tag != "未锁定":
		return "锁定未跑成"
	return "未成型"


func _region_handoff_completion_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "未承接"
	var source_region := str(report.get("handoff_source_region", ""))
	if source_region == "":
		return "未承接"
	if bool(report.get("handoff_completed", false)):
		return "承接跑成"
	return "承接未跑成"


func _region_first_segment_completion_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "非第一站"
	var phase := str(report.get("management_rotation_phase", "常规经营"))
	if phase not in ["主经营第一段", "单区快取主经营", "单区深挖主经营"]:
		return "非第一站"
	return "第一站跑成" if bool(report.get("first_segment_completed", false)) else "第一站未跑成"


func _region_second_segment_completion_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "非第二段"
	var source_region := str(report.get("handoff_source_region", ""))
	if source_region == "":
		return "非第二段"
	if bool(report.get("second_segment_completed", false)):
		return "第二段接稳"
	return "第二段未接稳"


func _region_branch_completion_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "非分支段"
	var explicit_tag := str(report.get("branch_completion_tag", ""))
	if explicit_tag != "":
		return explicit_tag
	var branch_mode := str(report.get("branch_mode", ""))
	if branch_mode == "deep_expand":
		return "扩线接稳" if bool(report.get("branch_completed", false)) else "扩线未接稳"
	if branch_mode == "quick_close":
		return "收束接稳" if bool(report.get("branch_completed", false)) else "收束未接稳"
	return "非分支段"


func _region_branch_stability_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "分支未定型"
	var branch_mode := str(report.get("branch_mode", ""))
	var branch_completed := bool(report.get("branch_completed", false))
	var branch_streak := int(report.get("branch_completion_streak", 0))
	var branch_counts: Dictionary = report.get("branch_completion_counts", {}) if report.has("branch_completion_counts") else {}
	if branch_mode == "deep_expand":
		var count := int(branch_counts.get("deep_expand", 0))
		if branch_completed and branch_streak >= 3:
			return "稳定扩线区"
		if count >= 2:
			return "扩线塑形中"
	elif branch_mode == "quick_close":
		var count := int(branch_counts.get("quick_close", 0))
		if branch_completed and branch_streak >= 3:
			return "稳定收束区"
		if count >= 2:
			return "收束塑形中"
	return "分支未定型"


func _region_management_priority_tag(report: Dictionary) -> String:
	if report.is_empty():
		return "常规经营区"
	var explicit_tag := str(report.get("management_priority_tag", ""))
	if explicit_tag != "":
		return explicit_tag
	var lock_tag := _region_route_lock_tag(report)
	var streak := int(report.get("lock_completion_streak", 0)) + _region_handoff_completion_bonus(report)
	var branch_stability_tag := _region_branch_stability_tag(report)
	if branch_stability_tag == "稳定收束区":
		if streak >= 4:
			return "主力快取经营区"
		return "重点快取经营区"
	if branch_stability_tag == "稳定扩线区":
		if streak >= 4:
			return "主力深挖经营区"
		return "重点深挖经营区"
	if lock_tag == "快取锁定":
		if streak >= 6:
			return "主力快取经营区"
		if streak >= 3:
			return "重点快取经营区"
	if lock_tag == "深挖锁定":
		if streak >= 5:
			return "主力深挖经营区"
		if streak >= 3:
			return "重点深挖经营区"
	return "常规经营区"


func _region_handoff_completion_bonus(report: Dictionary) -> int:
	if report.is_empty():
		return 0
	var streak := int(report.get("handoff_completion_streak", 0))
	var count := int(report.get("handoff_completion_count", 0))
	if streak >= 3:
		return 2
	if streak >= 2 or count >= 4:
		return 1
	return 0


func _region_branch_management_bonus(report: Dictionary) -> int:
	var branch_stability_tag := _region_branch_stability_tag(report)
	match branch_stability_tag:
		"稳定扩线区", "稳定收束区":
			return 2
		"扩线塑形中", "收束塑形中":
			return 1
		_:
			return 0


func _management_rotation_tag_from_management(management_tag: String) -> String:
	match management_tag:
		"主力快取经营区":
			return "优先快取经营"
		"重点快取经营区":
			return "推进快取经营"
		"主力深挖经营区":
			return "优先深挖经营"
		"重点深挖经营区":
			return "推进深挖经营"
		_:
			return "常规经营"


func _region_management_backbone_tag(report: Dictionary) -> String:
	var management_tag := _region_management_priority_tag(report)
	var branch_stability_tag := _region_branch_stability_tag(report)
	if management_tag == "主力快取经营区" and branch_stability_tag == "稳定收束区":
		return "快取经营骨干区"
	if management_tag == "主力深挖经营区" and branch_stability_tag == "稳定扩线区":
		return "深挖经营骨干区"
	return ""


func _region_management_backbone_bonus(report: Dictionary) -> int:
	match _region_management_backbone_tag(report):
		"快取经营骨干区", "深挖经营骨干区":
			return 2
		_:
			return 0


func _region_management_display(report: Dictionary) -> String:
	if report.is_empty():
		return "常规经营区"
	return _region_management_priority_tag(report)


func _region_management_short_display(report: Dictionary) -> String:
	match _region_management_priority_tag(report):
		"主力快取经营区":
			return "主力快取"
		"重点快取经营区":
			return "重点快取"
		"主力深挖经营区":
			return "主力深挖"
		"重点深挖经营区":
			return "重点深挖"
		_:
			return "常规"


func _region_backbone_display(report: Dictionary) -> String:
	if report.is_empty():
		return "无骨干"
	var completion_tag := str(report.get("backbone_completion_tag", ""))
	if completion_tag != "":
		return completion_tag
	var backbone_tag := _region_management_backbone_tag(report)
	if backbone_tag != "":
		return backbone_tag
	return "无骨干"


func _region_backbone_short_display(report: Dictionary) -> String:
	var completion_tag := str(report.get("backbone_completion_tag", ""))
	if completion_tag.contains("快取"):
		return "快取巩固"
	if completion_tag.contains("深挖"):
		return "深挖巩固"
	match _region_management_backbone_tag(report):
		"快取经营骨干区":
			return "快取骨干"
		"深挖经营骨干区":
			return "深挖骨干"
		_:
			return "无骨干"


func _region_consolidation_display(report: Dictionary) -> String:
	if report.is_empty():
		return "未巩固"
	var completion_tag := str(report.get("backbone_completion_tag", ""))
	if completion_tag != "":
		return completion_tag
	var streak := int(report.get("backbone_completion_streak", 0))
	if streak > 0:
		return "巩固中 %d" % streak
	return "未巩固"


func _region_consolidation_short_display(report: Dictionary) -> String:
	var completion_tag := str(report.get("backbone_completion_tag", ""))
	if completion_tag.contains("巩固"):
		return "已巩固"
	if completion_tag.contains("跑成"):
		return "已跑成"
	var streak := int(report.get("backbone_completion_streak", 0))
	if streak > 0:
		return "巩固中 %d" % streak
	return "未巩固"


func _region_consolidation_ratio(report: Dictionary) -> float:
	if report.is_empty():
		return 0.0
	var streak := int(report.get("backbone_completion_streak", 0))
	if str(report.get("backbone_completion_tag", "")) != "":
		return clampf(0.42 + float(streak) * 0.14, 0.0, 1.0)
	return clampf(float(streak) * 0.18, 0.0, 0.62)


func _region_management_chip_color(report: Dictionary) -> Color:
	match _region_management_priority_tag(report):
		"主力快取经营区":
			return Color8(214, 176, 82)
		"重点快取经营区":
			return Color8(194, 164, 100)
		"主力深挖经营区":
			return Color8(108, 146, 208)
		"重点深挖经营区":
			return Color8(95, 132, 186)
		_:
			return Color8(124, 134, 144)


func _region_backbone_chip_color(report: Dictionary) -> Color:
	match _region_management_backbone_tag(report):
		"快取经营骨干区":
			return Color8(227, 135, 78)
		"深挖经营骨干区":
			return Color8(129, 118, 212)
		_:
			return Color8(132, 140, 150)


func _region_consolidation_chip_color(report: Dictionary) -> Color:
	var completion_tag := str(report.get("backbone_completion_tag", ""))
	if completion_tag.contains("巩固") or completion_tag.contains("跑成"):
		return Color8(95, 176, 132)
	if int(report.get("backbone_completion_streak", 0)) > 0:
		return Color8(126, 166, 136)
	return Color8(132, 140, 150)


func _region_archive_strategy_tag(report: Dictionary) -> String:
	var archive_tier := _region_archive_tier(report)
	var run_profile := _region_run_profile_tag(report)
	var route_lock := _region_route_lock_tag(report)
	if route_lock == "快取锁定":
		if _region_lock_completion_tag(report) == "锁定跑成":
			return "主力快取区"
		return "锁定快取区"
	if route_lock == "深挖锁定":
		if _region_lock_completion_tag(report) == "锁定跑成":
			return "主力深挖区"
		return "锁定深挖区"
	match archive_tier:
		"定型档案":
			if run_profile == "深挖惯性":
				return "定型深挖区"
			if run_profile == "快取惯性":
				return "定型快取区"
			return "定型推进区"
		"熟悉档案":
			if run_profile in ["深挖惯性", "深挖试探"]:
				return "熟悉深挖区"
			if run_profile in ["快取惯性", "快取试探"]:
				return "熟悉快取区"
			return "熟悉推进区"
		"已知档案":
			return "成长调查区"
		_:
			return "初勘调查区"


func _region_archive_route_tag(report: Dictionary) -> String:
	var archive_tier := _region_archive_tier(report)
	var run_profile := _region_run_profile_tag(report)
	var route_lock := _region_route_lock_tag(report)
	if route_lock == "快取锁定":
		if _region_lock_completion_tag(report) == "锁定跑成":
			return "主力短推进路线"
		return "锁定短推进路线"
	if route_lock == "深挖锁定":
		if _region_lock_completion_tag(report) == "锁定跑成":
			return "主力连续复核路线"
		return "锁定连续复核路线"
	if archive_tier == "定型档案" and run_profile == "快取惯性":
		return "默认短推进路线"
	if archive_tier == "定型档案" and run_profile == "深挖惯性":
		return "默认连续复核路线"
	if archive_tier == "熟悉档案" and run_profile in ["快取惯性", "快取试探"]:
		return "偏短推进路线"
	if archive_tier == "熟悉档案" and run_profile in ["深挖惯性", "深挖试探"]:
		return "偏连续复核路线"
	return "基础观察路线"


func _region_run_profile_strategy_text(report: Dictionary) -> String:
	var management_tag := _region_management_priority_tag(report)
	var management_rotation := _management_rotation_tag_from_management(management_tag)
	var backbone_tag := _region_management_backbone_tag(report)
	var backbone_prefix := ""
	if backbone_tag != "":
		var backbone_completion_tag := str(report.get("backbone_completion_tag", ""))
		backbone_prefix = (backbone_completion_tag if backbone_completion_tag != "" else backbone_tag) + " · "
	if _region_route_lock_tag(report) == "快取锁定":
		if _region_lock_completion_tag(report) == "锁定跑成":
			return "%s%s · %s · %s · %s · %s · %s · 这片区已成为长期主力快取区，默认先吃第一阶段主力速查组，再带着关键样本撤离。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report), _region_lock_completion_tag(report)]
		return "%s%s · %s · %s · %s · %s · %s · 这片区已被长期塑形成短推进区，默认拿关键样本后快速撤离。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report), _region_lock_completion_tag(report)]
	if _region_route_lock_tag(report) == "深挖锁定":
		if _region_lock_completion_tag(report) == "锁定跑成":
			return "%s%s · %s · %s · %s · %s · %s · 这片区已成为长期主力深挖区，默认先压主力主复核，再补主力次复核与对应样本。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report), _region_lock_completion_tag(report)]
		return "%s%s · %s · %s · %s · %s · %s · 这片区已被长期塑形成连续复核区，默认优先压多段复核链。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report), _region_lock_completion_tag(report)]
	match _region_dominant_run_style(report):
		"快取完成":
			return "%s%s · %s · %s · %s · %s · 当前更适合短推进，锁定第一阶段落点后拿样本就撤。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report)]
		"深挖完成":
			return "%s%s · %s · %s · %s · %s · 当前更适合连续深挖，优先压第二阶段深线落点。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report)]
		"快取未完成":
			return "%s%s · %s · %s · %s · %s · 当前仍在快取试探，建议先用短推进补关键样本。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report)]
		"深挖未完成":
			return "%s%s · %s · %s · %s · %s · 当前仍在深挖试探，建议继续延长路线补复核链。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report)]
		_:
			return "%s%s · %s · %s · %s · %s · 当前仍是基础观察，按区域总态稳步推进。" % [backbone_prefix, management_rotation, management_tag, _region_archive_strategy_tag(report), _region_archive_route_tag(report), _region_route_shaping_tag(report)]


func _route_identity_text(active_region: Dictionary) -> String:
	var report := _region_report(str(active_region.get("id", active_region_id)))
	if report.is_empty():
		return "当前仍是初勘路线，优先沿主线建立第一批调查样本。"
	var route_lock := _region_route_lock_tag(report)
	var dominant_channel := str(report.get("dominant_intel_channel", report.get("top_intel_channel", "未分类")))
	var dominant_window := str(report.get("dominant_window", report.get("event_window", "focus")))
	var specialization_tag := _region_specialization_tag(report)
	var specialization_target := _region_specialization_target(report)
	var run_tag := _region_specialization_run_tag(report)
	var run_profile := _region_run_profile_tag(report)
	var shaping_tag := _region_route_shaping_tag(report)
	var prefix := _region_archive_tier(report)
	if route_lock == "快取锁定":
		return "%s锁定快取区 · %s / %s / %s / %s / %s，默认先吃第一阶段高值速查点，拿到关键样本后快速撤离。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag]
	if route_lock == "深挖锁定":
		return "%s锁定深挖区 · %s / %s / %s / %s / %s，默认先压主线复核，再补第二复核点与对应样本。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag]
	match dominant_channel:
		"水源":
			return "%s水源调查区 · %s / %s / %s / %s / %s，路线建议继续先压水点与岸带，主攻%s。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag, specialization_target]
		"迁徙":
			return "%s迁徙调查区 · %s / %s / %s / %s / %s，路线建议优先走迁徙线与草食走廊，主攻%s。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag, specialization_target]
		"压迫":
			return "%s压迫调查区 · %s / %s / %s / %s / %s，路线建议先看掠食压力和风险窗口，主攻%s。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag, specialization_target]
		"腐食":
			return "%s腐食调查区 · %s / %s / %s / %s / %s，路线建议先压腐食点与飞行链，主攻%s。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag, specialization_target]
		"栖地":
			return "%s栖地调查区 · %s / %s / %s / %s / %s，路线建议先补林下或庇护热点，主攻%s。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag, specialization_target]
		_:
			if dominant_window == "predation":
				return "%s捕食窗口区 · %s / %s / %s / %s / %s，路线建议保守推进并优先看压力点。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag]
			if dominant_window == "symbiosis":
				return "%s共生窗口区 · %s / %s / %s / %s / %s，路线建议补稳定样本。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag]
			return "%s观察区 · %s / %s / %s / %s / %s，路线建议沿既有主线继续扩样。" % [prefix, specialization_tag, run_tag, run_profile, _region_archive_route_tag(report), shaping_tag]


func _region_event_window_text(active_region: Dictionary) -> String:
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var chain_focus: Array = active_region.get("chain_focus", [])
	var report := _region_report(str(active_region.get("id", active_region_id)))
	var report_channel := str(report.get("top_intel_channel", ""))
	if pressure_headlines.size() > 0:
		if report_channel != "":
			return "%s · 当前窗口偏向%s" % [str(pressure_headlines[0]), report_channel]
		return str(pressure_headlines[0])
	if chain_focus.size() > 0:
		return str(chain_focus[0])
	if report_channel != "":
		return "最近回执显示当前窗口偏向%s" % report_channel
	return "当前窗口待建立"


func _region_event_window_tag(active_region: Dictionary) -> String:
	var text := _region_event_window_text(active_region)
	if "水源" in text:
		return "水源窗"
	if "迁徙" in text:
		return "迁徙窗"
	if "压迫" in text or "捕食" in text:
		return "压迫窗"
	if "腐食" in text:
		return "腐食窗"
	if "栖地" in text or "共生" in text:
		return "栖地窗"
	if "风险" in text:
		return "高风险窗"
	return "观察窗"


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


func _unhandled_input(event: InputEvent) -> void:
	if map_layer == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_zoom_world_map(1.12, mouse_event.position)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_zoom_world_map(1.0 / 1.12, mouse_event.position)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			map_panning = mouse_event.pressed
			map_pan_mouse_start = mouse_event.position
			map_pan_start = map_pan
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and map_panning:
		var motion := event as InputEventMouseMotion
		map_pan = map_pan_start + motion.position - map_pan_mouse_start
		_apply_map_view_transform()
		get_viewport().set_input_as_handled()


func _zoom_world_map(factor: float, focus_screen: Vector2) -> void:
	var old_zoom := map_zoom
	var new_zoom := clampf(map_zoom * factor, 0.72, 2.25)
	if is_equal_approx(old_zoom, new_zoom):
		return
	var viewport_pos := _map_viewport_screen_origin()
	var focus_local := focus_screen - viewport_pos
	var world_before := (focus_local - map_pan) / old_zoom
	map_zoom = new_zoom
	map_pan = focus_local - world_before * map_zoom
	_apply_map_view_transform()


func _map_viewport_screen_origin() -> Vector2:
	if map_viewport == null:
		return Vector2.ZERO
	return map_viewport.get_global_rect().position


func _apply_map_view_transform() -> void:
	if map_layer == null:
		return
	var viewport_size := get_viewport_rect().size
	if map_viewport != null:
		viewport_size = map_viewport.get_rect().size
	var map_size := map_layer.get_rect().size * map_zoom
	if map_size.x <= viewport_size.x:
		map_pan.x = (viewport_size.x - map_size.x) * 0.5
	else:
		map_pan.x = clampf(map_pan.x, viewport_size.x - map_size.x, 0.0)
	if map_size.y <= viewport_size.y:
		map_pan.y = (viewport_size.y - map_size.y) * 0.5
	else:
		map_pan.y = clampf(map_pan.y, viewport_size.y - map_size.y, 0.0)
	map_layer.scale = Vector2(map_zoom, map_zoom)
	map_layer.position = map_pan


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_apply_ui_theme()

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 0)
	root_margin.add_theme_constant_override("margin_top", 0)
	root_margin.add_theme_constant_override("margin_right", 0)
	root_margin.add_theme_constant_override("margin_bottom", 0)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_margin.add_child(root_vbox)

	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 82)
	header_panel.visible = false
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
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	root_vbox.add_child(content)

	var map_panel := PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(1600, 960)
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.clip_contents = true
	content.add_child(map_panel)
	map_viewport = map_panel

	map_layer = Control.new()
	map_layer.custom_minimum_size = Vector2(1600, 960)
	map_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_child(map_layer)

	side_panel = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(0, 0)
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.visible = false
	content.add_child(side_panel)

	side_scroll = ScrollContainer.new()
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_child(side_scroll)

	side_box = VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 14)
	side_scroll.add_child(side_box)

	var footer_panel := PanelContainer.new()
	footer_panel.custom_minimum_size = Vector2(0, 78)
	footer_panel.visible = false
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

	_build_game_hud()


func _build_game_hud() -> void:
	game_hud = PanelContainer.new()
	game_hud.position = Vector2(28, 28)
	game_hud.custom_minimum_size = Vector2(520, 190)
	game_hud.z_index = 30
	game_hud.mouse_filter = Control.MOUSE_FILTER_STOP
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0.04, 0.07, 0.06, 0.62)
	hud_style.border_color = Color(0.86, 0.78, 0.55, 0.30)
	hud_style.set_border_width_all(1)
	hud_style.corner_radius_top_left = 14
	hud_style.corner_radius_top_right = 14
	hud_style.corner_radius_bottom_left = 14
	hud_style.corner_radius_bottom_right = 14
	hud_style.content_margin_left = 16
	hud_style.content_margin_top = 12
	hud_style.content_margin_right = 16
	hud_style.content_margin_bottom = 12
	game_hud.add_theme_stylebox_override("panel", hud_style)
	add_child(game_hud)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	game_hud.add_child(box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	box.add_child(title_row)

	hud_region_label = Label.new()
	_style_primary_title(hud_region_label, 19)
	hud_region_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(hud_region_label)

	var hint_label := Label.new()
	hint_label.text = "滚轮缩放 · 右键拖动"
	_style_dim(hint_label, 11)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_row.add_child(hint_label)

	hud_summary_label = Label.new()
	hud_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_body(hud_summary_label, 13)
	box.add_child(hud_summary_label)

	hud_world_label = Label.new()
	hud_world_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(hud_world_label, 12)
	box.add_child(hud_world_label)

	hud_loop_label = Label.new()
	hud_loop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_body(hud_loop_label, 12)
	box.add_child(hud_loop_label)

	hud_metric_label = Label.new()
	_style_secondary_title(hud_metric_label, 12)
	box.add_child(hud_metric_label)

	hud_species_label = Label.new()
	hud_species_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(hud_species_label, 12)
	box.add_child(hud_species_label)

	hud_objective_label = Label.new()
	hud_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_body(hud_objective_label, 12)
	box.add_child(hud_objective_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 7)
	box.add_child(action_row)
	focus_recommended_button = Button.new()
	focus_recommended_button.text = "主线区"
	focus_recommended_button.custom_minimum_size = Vector2(76, 42)
	focus_recommended_button.pressed.connect(_on_focus_recommended_region_pressed)
	action_row.add_child(focus_recommended_button)
	for action_name in ["调查", "修复", "通道"]:
		var button := Button.new()
		button.text = {
			"调查": "调查线\n记录",
			"修复": "修复线\n采样",
			"通道": "通道线\n撤离",
		}.get(action_name, action_name)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(78, 42)
		button.pressed.connect(_on_game_action_pressed.bind(action_name))
		action_row.add_child(button)
		action_buttons[action_name] = button
	apply_turn_button = Button.new()
	apply_turn_button.text = "应用回合"
	apply_turn_button.custom_minimum_size = Vector2(104, 42)
	apply_turn_button.pressed.connect(_on_apply_turn_pressed)
	action_row.add_child(apply_turn_button)
	enter_region_button = Button.new()
	enter_region_button.text = "开始主线"
	enter_region_button.custom_minimum_size = Vector2(116, 42)
	enter_region_button.pressed.connect(_on_enter_region_pressed)
	action_row.add_child(enter_region_button)

	hud_action_label = Label.new()
	hud_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_dim(hud_action_label, 12)
	box.add_child(hud_action_label)


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
	expedition_reports = _load_expedition_reports()
	_apply_recent_expedition_handoff()
	selected_game_action = _recommended_game_action(detail_cache.get(active_region_id, world_data.get("active_region", {})))
	selected_game_action = _mainline_action_for_region(active_region_id, selected_game_action)
	_render_world()


func _load_expedition_reports() -> Dictionary:
	if not FileAccess.file_exists(REPORT_PATH):
		return {}
	var file := FileAccess.open(REPORT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _apply_recent_expedition_handoff() -> void:
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	if latest_report.is_empty():
		return
	var target_region_id := str(latest_report.get("target_region_id", ""))
	if target_region_id == "" or not detail_cache.has(target_region_id):
		return
	active_region_id = target_region_id
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	selected_campaign_target_id = ""
	selected_frontier_target_id = ""
	selected_branch_target_id = ""
	selected_campaign_landing_target_id = ""
	selected_campaign_filter = _recommended_campaign_filter(active_region)
	selected_campaign_stage_index = 0
	selected_schedule_route_key = "primary_route"
	selected_formation_key = "assault"
	selected_activation_preset_key = "assault"
	selected_directive_key = "assault"
	selected_decision_key = "assault"
	selected_confirmation_key = "assault"


func _render_missing_data() -> void:
	title_label.text = "EcoWorld Godot 前端"
	subtitle_label.text = "缺少世界状态 JSON"
	status_label.text = "请先运行：PYTHONPATH=. python3 scripts/export_world_state.py --pretty"


func _render_world() -> void:
	title_label.text = "阿瑞利亚生态世界"
	var world_meta: Dictionary = world_data.get("world", {})
	var subtitle := "Tick %s · 已加载 %s/%s 区域" % [
		str(world_meta.get("tick", 0)),
		str(world_meta.get("loaded_regions", 0)),
		str(world_meta.get("total_regions", 0)),
	]
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	if not latest_report.is_empty():
		subtitle += " · 最近回执：%s" % str(latest_report.get("region_name", "未知区域"))
	subtitle_label.text = subtitle
	status_label.text = "系统栏 · Godot 世界地图前端 · 中文界面 · 读取 Python 导出的世界状态"
	if not latest_report.is_empty():
		status_label.text += " · %s" % str(latest_report.get("summary", ""))
		if _latest_expedition_report_pending():
			status_label.text += " · 待回灌：点击应用回合"
		var handoff_region_id := str(latest_report.get("target_region_id", ""))
		if handoff_region_id != "" and detail_cache.has(handoff_region_id):
			var handoff_detail: Dictionary = detail_cache.get(handoff_region_id, {})
			status_label.text += " · 已承接到下一段：%s" % str(handoff_detail.get("name", handoff_region_id))
	queue_redraw()
	_sync_frontier_focus()
	selected_tab = "overview"

	for child in footer_command_holder.get_children():
		child.queue_free()
	footer_command_holder.add_child(_make_terminal_footer(detail_cache.get(active_region_id, world_data.get("active_region", {})), _active_region_accent()))

	for child in map_layer.get_children():
		child.queue_free()
	for child in side_box.get_children():
		child.queue_free()

	_build_realistic_map_canvas(world_meta.get("regions", []))
	_build_map_hit_areas(world_meta.get("regions", []))
	_apply_map_view_transform()
	_build_side_panel()
	_refresh_game_hud()


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
	if selected_campaign_filter == "balanced":
		selected_campaign_filter = _recommended_campaign_filter(active_region)
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
	var report := _region_report(str(active_region.get("id", active_region_id)))
	match _region_route_lock_tag(report):
		"快取锁定":
			selected_campaign_stage_index = 0
			return
		"深挖锁定":
			selected_campaign_stage_index = min(1, route_titles.size() - 1)
			return
	selected_campaign_stage_index = clampi(selected_campaign_stage_index, 0, route_titles.size() - 1)


func _sync_campaign_landing(active_region: Dictionary) -> void:
	var candidates: Array = _campaign_landing_candidates(active_region)
	if candidates.is_empty():
		selected_campaign_landing_target_id = ""
		return
	var preferred_rotation_target_id := _preferred_rotation_candidate_id(candidates)
	if preferred_rotation_target_id != "":
		selected_campaign_landing_target_id = preferred_rotation_target_id
		return
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		if str(candidate.get("target_region_id", "")) == selected_campaign_landing_target_id:
			return
	selected_campaign_landing_target_id = str((candidates[0] as Dictionary).get("target_region_id", ""))


func _recommended_campaign_filter(active_region: Dictionary) -> String:
	var report := _region_report(str(active_region.get("id", active_region_id)))
	match _region_management_priority_tag(report):
		"主力快取经营区", "重点快取经营区":
			return "safe"
		"主力深挖经营区", "重点深挖经营区":
			return "rich"
	match _region_route_lock_tag(report):
		"快取锁定":
			return "safe"
		"深挖锁定":
			return "rich"
	match _region_archive_route_tag(report):
		"默认短推进路线", "偏短推进路线":
			return "safe"
		"默认连续复核路线", "偏连续复核路线":
			return "rich"
		_:
			var shaping_tag := _region_route_shaping_tag(report)
			if shaping_tag.begins_with("快取塑形"):
				return "safe"
			if shaping_tag.begins_with("深挖塑形"):
				return "rich"
			return "balanced"


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
	var active_report := _region_report(str(active_region.get("id", active_region_id)))
	var report_channel := str(active_report.get("top_intel_channel", ""))
	var active_window_tag := str(active_report.get("event_window_title", _region_event_window_tag(active_region)))
	var candidates: Array = []
	var seen := {}

	var frontier_target_id := str(active_frontier.get("target_region_id", ""))
	if frontier_target_id != "" and detail_cache.has(frontier_target_id):
		var landing_detail: Dictionary = detail_cache.get(frontier_target_id, {})
		var frontier_report := _region_report(frontier_target_id)
		candidates.append(
			{
				"target_region_id": frontier_target_id,
				"name": str(landing_detail.get("name", frontier_target_id)),
				"role": str(landing_detail.get("region_role", "生态观测区")),
				"prosperity": float(landing_detail.get("health_state", {}).get("prosperity", 0.0)),
				"risk": float(landing_detail.get("health_state", {}).get("collapse_risk", 0.0)),
				"stage_label": "第一阶段",
				"report_channel": str(frontier_report.get("top_intel_channel", "")),
				"report_intel": int(frontier_report.get("intel", 0)),
				"report_risk": float(frontier_report.get("risk", 0.0)),
				"event_window": _region_event_window_text(landing_detail),
				"event_window_tag": _region_event_window_tag(landing_detail),
				"known_tag": _region_known_tag(frontier_report),
				"specialization_mode": _region_specialization_mode(frontier_report),
				"specialization_tag": _region_specialization_tag(frontier_report),
				"specialization_run_tag": _region_specialization_run_tag(frontier_report),
				"dominant_run_style": _region_dominant_run_style(frontier_report),
				"dominant_route_style": _region_dominant_route_style(frontier_report),
				"route_style_streak": _region_route_style_streak(frontier_report),
				"route_shaping_tag": _region_route_shaping_tag(frontier_report),
				"route_lock_tag": _region_route_lock_tag(frontier_report),
				"route_lock_completed": _region_lock_completion_tag(frontier_report),
				"management_priority_tag": _region_management_priority_tag(frontier_report),
				"management_backbone_tag": _region_management_backbone_tag(frontier_report),
				"backbone_completion_tag": str(frontier_report.get("backbone_completion_tag", "")),
				"management_rotation_phase": str(frontier_report.get("management_rotation_phase", "常规经营")),
				"first_segment_completed": bool(frontier_report.get("first_segment_completed", false)),
				"second_segment_completed": bool(frontier_report.get("second_segment_completed", false)),
				"branch_mode": str(frontier_report.get("branch_mode", "")),
				"branch_completed": bool(frontier_report.get("branch_completed", false)),
				"branch_completion_tag": _region_branch_completion_tag(frontier_report),
				"branch_stability_tag": _region_branch_stability_tag(frontier_report),
				"branch_completion_counts": frontier_report.get("branch_completion_counts", {}),
				"branch_completion_streak": int(frontier_report.get("branch_completion_streak", 0)),
				"primary_lock_zone": bool(frontier_report.get("primary_lock_zone", false)),
				"backbone_completed": bool(frontier_report.get("backbone_completed", false)),
				"backbone_completion_counts": frontier_report.get("backbone_completion_counts", {}),
				"backbone_completion_streak": int(frontier_report.get("backbone_completion_streak", 0)),
				"handoff_completed": bool(frontier_report.get("handoff_completed", false)),
				"handoff_completion_count": int(frontier_report.get("handoff_completion_count", 0)),
				"handoff_completion_streak": int(frontier_report.get("handoff_completion_streak", 0)),
				"handoff_source_region": str(frontier_report.get("handoff_source_region", "")),
				"run_profile_tag": _region_run_profile_tag(frontier_report),
				"archive_tier": _region_archive_tier(frontier_report),
				"archive_progress": _region_archive_progress(frontier_report),
				"archive_ratio": _region_archive_ratio(frontier_report),
			}
		)
		seen[frontier_target_id] = true

	for branch_variant in active_network.get("branches", []):
		var branch: Dictionary = branch_variant
		var branch_id := str(branch.get("target_region_id", ""))
		if branch_id == "" or seen.has(branch_id):
			continue
		var branch_detail: Dictionary = detail_cache.get(branch_id, {})
		var branch_report := _region_report(branch_id)
		candidates.append(
			{
				"target_region_id": branch_id,
				"name": str(branch_detail.get("name", branch.get("target_name", branch_id))),
				"role": str(branch_detail.get("region_role", branch.get("target_role", "生态观测区"))),
				"prosperity": float(branch_detail.get("health_state", {}).get("prosperity", branch.get("target_prosperity", 0.0))),
				"risk": float(branch_detail.get("health_state", {}).get("collapse_risk", branch.get("target_risk", 0.0))),
				"stage_label": "第二阶段",
				"report_channel": str(branch_report.get("top_intel_channel", "")),
				"report_intel": int(branch_report.get("intel", 0)),
				"report_risk": float(branch_report.get("risk", 0.0)),
				"event_window": _region_event_window_text(branch_detail),
				"event_window_tag": _region_event_window_tag(branch_detail),
				"known_tag": _region_known_tag(branch_report),
				"specialization_mode": _region_specialization_mode(branch_report),
				"specialization_tag": _region_specialization_tag(branch_report),
				"specialization_run_tag": _region_specialization_run_tag(branch_report),
				"dominant_run_style": _region_dominant_run_style(branch_report),
				"dominant_route_style": _region_dominant_route_style(branch_report),
				"route_style_streak": _region_route_style_streak(branch_report),
				"route_shaping_tag": _region_route_shaping_tag(branch_report),
				"route_lock_tag": _region_route_lock_tag(branch_report),
				"route_lock_completed": _region_lock_completion_tag(branch_report),
				"management_priority_tag": _region_management_priority_tag(branch_report),
				"management_backbone_tag": _region_management_backbone_tag(branch_report),
				"backbone_completion_tag": str(branch_report.get("backbone_completion_tag", "")),
				"management_rotation_phase": str(branch_report.get("management_rotation_phase", "常规经营")),
				"first_segment_completed": bool(branch_report.get("first_segment_completed", false)),
				"second_segment_completed": bool(branch_report.get("second_segment_completed", false)),
				"branch_mode": str(branch_report.get("branch_mode", "")),
				"branch_completed": bool(branch_report.get("branch_completed", false)),
				"branch_completion_tag": _region_branch_completion_tag(branch_report),
				"branch_stability_tag": _region_branch_stability_tag(branch_report),
				"branch_completion_counts": branch_report.get("branch_completion_counts", {}),
				"branch_completion_streak": int(branch_report.get("branch_completion_streak", 0)),
				"primary_lock_zone": bool(branch_report.get("primary_lock_zone", false)),
				"backbone_completed": bool(branch_report.get("backbone_completed", false)),
				"backbone_completion_counts": branch_report.get("backbone_completion_counts", {}),
				"backbone_completion_streak": int(branch_report.get("backbone_completion_streak", 0)),
				"handoff_completed": bool(branch_report.get("handoff_completed", false)),
				"handoff_completion_count": int(branch_report.get("handoff_completion_count", 0)),
				"handoff_completion_streak": int(branch_report.get("handoff_completion_streak", 0)),
				"handoff_source_region": str(branch_report.get("handoff_source_region", "")),
				"run_profile_tag": _region_run_profile_tag(branch_report),
				"archive_tier": _region_archive_tier(branch_report),
				"archive_progress": _region_archive_progress(branch_report),
				"archive_ratio": _region_archive_ratio(branch_report),
			}
		)
		seen[branch_id] = true

	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		var prosperity := float(candidate.get("prosperity", 0.0))
		var risk := float(candidate.get("risk", 0.0))
		var loop_boost := 0.0
		var report_boost := _campaign_report_bias(active_region, candidate, report_channel)
		var window_boost := _campaign_window_bias(candidate, active_window_tag)
		var archive_boost := _campaign_archive_bias(candidate)
		if str(candidate.get("target_region_id", "")) == str(active_feedback.get("priority_target_id", "")):
			loop_boost += 0.16
		if str(candidate.get("stage_label", "")) == str(active_feedback.get("recommended_stage_title", "")):
			loop_boost += 0.08
		candidate["report_note"] = _campaign_report_note(candidate, report_channel)
		candidate["score_balanced"] = floor((prosperity * 0.64 + (1.0 - risk) * 0.36) * 10000.0 + 0.5) / 10000.0
		candidate["score_safe"] = floor(((1.0 - risk) * 0.72 + prosperity * 0.28) * 10000.0 + 0.5) / 10000.0
		candidate["score_rich"] = floor((prosperity * 0.82 + (1.0 - risk) * 0.18) * 10000.0 + 0.5) / 10000.0
		candidate["score_risk"] = floor((risk * 0.78 + prosperity * 0.22) * 10000.0 + 0.5) / 10000.0
		candidate["loop_boost"] = floor(loop_boost * 10000.0 + 0.5) / 10000.0
		candidate["report_boost"] = floor(report_boost * 10000.0 + 0.5) / 10000.0
		candidate["window_boost"] = floor(window_boost * 10000.0 + 0.5) / 10000.0
		candidate["archive_boost"] = floor(archive_boost * 10000.0 + 0.5) / 10000.0
		candidate["score_balanced"] = float(candidate.get("score_balanced", 0.0)) + report_boost + window_boost + archive_boost
		candidate["score_safe"] = float(candidate.get("score_safe", 0.0)) + max(report_boost * 0.72, 0.0) + max(window_boost * 0.56, 0.0) + max(archive_boost * 0.80, 0.0)
		candidate["score_rich"] = float(candidate.get("score_rich", 0.0)) + max(report_boost * 0.84, 0.0) + max(window_boost * 0.72, 0.0) + max(archive_boost * 0.92, 0.0)
		candidate["score_risk"] = float(candidate.get("score_risk", 0.0)) + min(report_boost * 0.48, 0.08) + min(window_boost * 0.60, 0.10) + min(archive_boost * 0.40, 0.06)
		candidate["score"] = float(candidate.get("score_balanced", 0.0)) + loop_boost

	_apply_campaign_filter(candidates)
	return candidates


func _campaign_window_bias(candidate: Dictionary, active_window_tag: String) -> float:
	var candidate_window := str(candidate.get("event_window_tag", "观察窗"))
	var bias := 0.0
	if active_window_tag != "" and candidate_window == active_window_tag:
		bias += 0.10
	match selected_campaign_filter:
		"safe":
			if candidate_window in ["水源窗", "栖地窗", "观察窗"]:
				bias += 0.04
		"rich":
			if candidate_window in ["迁徙窗", "腐食窗", "栖地窗"]:
				bias += 0.05
		"risk":
			if candidate_window in ["压迫窗", "高风险窗"]:
				bias += 0.07
	return bias


func _campaign_report_bias(active_region: Dictionary, candidate: Dictionary, active_report_channel: String) -> float:
	var report_channel := str(candidate.get("report_channel", ""))
	var report_intel := float(candidate.get("report_intel", 0))
	var report_risk := float(candidate.get("report_risk", candidate.get("risk", 0.0)))
	var role := str(candidate.get("role", ""))
	var candidate_id := str(candidate.get("target_region_id", ""))
	var active_id := str(active_region.get("id", active_region_id))
	var specialization_mode := str(candidate.get("specialization_mode", "基础线"))
	var dominant_run_style := str(candidate.get("dominant_run_style", "基础观察"))
	var route_lock_tag := str(candidate.get("route_lock_tag", "未锁定"))
	var management_tag := str(candidate.get("management_priority_tag", "常规经营区"))
	var management_phase := str(candidate.get("management_rotation_phase", "常规经营"))
	var handoff_completed := bool(candidate.get("handoff_completed", false))
	var handoff_completion_count := int(candidate.get("handoff_completion_count", 0))
	var handoff_completion_streak := int(candidate.get("handoff_completion_streak", 0))
	var handoff_source_region := str(candidate.get("handoff_source_region", ""))
	var first_segment_completed := bool(candidate.get("first_segment_completed", false))
	var second_segment_completed := bool(candidate.get("second_segment_completed", false))
	var branch_mode := str(candidate.get("branch_mode", ""))
	var branch_completed := bool(candidate.get("branch_completed", false))
	var branch_stability_tag := str(candidate.get("branch_stability_tag", "分支未定型"))
	var backbone_completed := bool(candidate.get("backbone_completed", false))
	var backbone_completion_streak := int(candidate.get("backbone_completion_streak", 0))
	var backbone_tag := _region_management_backbone_tag({
		"management_priority_tag": management_tag,
		"branch_mode": branch_mode,
		"branch_completed": branch_completed,
		"branch_completion_tag": candidate.get("branch_completion_tag", ""),
		"branch_completion_counts": candidate.get("branch_completion_counts", {}),
		"branch_completion_streak": candidate.get("branch_completion_streak", 0),
	})
	var bias := 0.0
	var latest_report: Dictionary = expedition_reports.get("_last", {})

	if active_report_channel != "" and active_report_channel == report_channel:
		bias += 0.12
	if active_report_channel == "水源" and (role.contains("湿地") or candidate_id.contains("wetland")):
		bias += 0.10
	if active_report_channel == "迁徙" and (role.contains("草原") or candidate_id.contains("grassland")):
		bias += 0.10
	if active_report_channel == "栖地" and (role.contains("森林") or candidate_id.contains("forest")):
		bias += 0.10
	if active_report_channel == "腐食" and (role.contains("海岸") or candidate_id.contains("coast")):
		bias += 0.08
	if active_report_channel == "压迫":
		bias += 0.05 if selected_campaign_filter == "risk" else -0.03

	if selected_campaign_filter == "safe":
		bias += clamp((1.0 - report_risk) * 0.10, 0.0, 0.10)
	elif selected_campaign_filter == "rich":
		bias += clamp(report_intel / 40.0, 0.0, 0.10)
	elif selected_campaign_filter == "risk":
		bias += clamp(report_risk * 0.12, 0.0, 0.12)

	if candidate_id == active_id:
		bias -= 0.06
	if selected_campaign_filter == "safe" and specialization_mode == "快取线":
		bias += 0.04
	elif selected_campaign_filter == "rich" and specialization_mode == "深挖线":
		bias += 0.05
	elif selected_campaign_filter == "risk" and specialization_mode == "快取线":
		bias += 0.03
	if selected_campaign_filter == "safe" and dominant_run_style == "快取完成":
		bias += 0.05
	elif selected_campaign_filter == "rich" and dominant_run_style == "深挖完成":
		bias += 0.06
	elif selected_campaign_filter == "risk" and dominant_run_style == "快取完成":
		bias += 0.02
	if route_lock_tag == "快取锁定":
		bias += 0.06 if selected_campaign_filter == "safe" else 0.02
	elif route_lock_tag == "深挖锁定":
		bias += 0.07 if selected_campaign_filter == "rich" else 0.02
	match management_tag:
		"主力快取经营区":
			bias += 0.10 if selected_campaign_filter == "safe" else 0.03
		"主力深挖经营区":
			bias += 0.11 if selected_campaign_filter == "rich" else 0.03
		"重点快取经营区":
			bias += 0.05 if selected_campaign_filter == "safe" else 0.02
		"重点深挖经营区":
			bias += 0.06 if selected_campaign_filter == "rich" else 0.02
	match management_phase:
		"主经营第一段":
			bias += 0.08
		"主经营第二段":
			bias += 0.03
		"单区快取主经营", "单区深挖主经营":
			bias += 0.05
	if handoff_source_region != "":
		bias += 0.01
		if handoff_completed:
			bias += 0.05
			if handoff_completion_streak >= 2:
				bias += 0.03
			elif handoff_completion_count >= 4:
				bias += 0.02
			if management_phase in ["主经营第一段", "单区快取主经营", "单区深挖主经营"]:
				bias += 0.03
	if first_segment_completed:
		bias += 0.04
	if second_segment_completed:
		bias += 0.06
	if branch_mode == "deep_expand":
		bias += 0.07 if selected_campaign_filter == "rich" else 0.02
		if branch_completed:
			bias += 0.04 if selected_campaign_filter == "rich" else 0.01
	elif branch_mode == "quick_close":
		bias += 0.07 if selected_campaign_filter == "safe" else 0.02
		if branch_completed:
			bias += 0.04 if selected_campaign_filter == "safe" else 0.01
	if branch_stability_tag == "稳定扩线区":
		bias += 0.08 if selected_campaign_filter == "rich" else 0.02
	elif branch_stability_tag == "稳定收束区":
		bias += 0.08 if selected_campaign_filter == "safe" else 0.02
	elif branch_stability_tag == "扩线塑形中":
		bias += 0.04 if selected_campaign_filter == "rich" else 0.01
	elif branch_stability_tag == "收束塑形中":
		bias += 0.04 if selected_campaign_filter == "safe" else 0.01
	if backbone_tag == "快取经营骨干区":
		bias += 0.12 if selected_campaign_filter == "safe" else 0.03
	elif backbone_tag == "深挖经营骨干区":
		bias += 0.12 if selected_campaign_filter == "rich" else 0.03
	if backbone_completed:
		if backbone_tag == "快取经营骨干区":
			bias += 0.05 if selected_campaign_filter == "safe" else 0.01
		elif backbone_tag == "深挖经营骨干区":
			bias += 0.05 if selected_campaign_filter == "rich" else 0.01
	if backbone_completion_streak >= 3:
		if backbone_tag == "快取经营骨干区":
			bias += 0.04 if selected_campaign_filter == "safe" else 0.01
		elif backbone_tag == "深挖经营骨干区":
			bias += 0.04 if selected_campaign_filter == "rich" else 0.01
	if not latest_report.is_empty() and bool(latest_report.get("first_segment_completed", false)):
		var latest_target_region_id := str(latest_report.get("target_region_id", ""))
		if latest_target_region_id != "" and latest_target_region_id == candidate_id:
			bias += 0.10
			if management_phase == "主经营第二段":
				bias += 0.05
	if not latest_report.is_empty() and bool(latest_report.get("second_segment_completed", false)):
		var latest_second_segment_region_id := str(latest_report.get("region_id", ""))
		if latest_second_segment_region_id != "" and latest_second_segment_region_id == candidate_id:
			bias += 0.08
	if not latest_report.is_empty() and bool(latest_report.get("branch_completed", false)):
		var latest_target_region_id := str(latest_report.get("target_region_id", ""))
		var latest_branch_mode := str(latest_report.get("branch_mode", ""))
		if latest_target_region_id != "" and latest_target_region_id == candidate_id:
			bias += 0.10
			if latest_branch_mode == "deep_expand" and selected_campaign_filter == "rich":
				bias += 0.04
			elif latest_branch_mode == "quick_close" and selected_campaign_filter == "safe":
				bias += 0.04
	if str(candidate.get("route_lock_completed", "未成型")) == "锁定跑成":
		bias += 0.04
	bias += _campaign_run_profile_route_bias(candidate)

	return bias


func _campaign_archive_bias(candidate: Dictionary) -> float:
	var archive_tier := str(candidate.get("archive_tier", "未建档"))
	var archive_ratio := float(candidate.get("archive_ratio", 0.0))
	var dominant_run_style := str(candidate.get("dominant_run_style", "基础观察"))
	var dominant_route_style := str(candidate.get("dominant_route_style", "base"))
	var route_style_streak := int(candidate.get("route_style_streak", 0))
	var route_shaping_tag := str(candidate.get("route_shaping_tag", "塑形待定"))
	var route_lock_tag := str(candidate.get("route_lock_tag", "未锁定"))
	var route_lock_completed := str(candidate.get("route_lock_completed", "未成型"))
	var management_tag := str(candidate.get("management_priority_tag", "常规经营区"))
	var backbone_tag := _region_management_backbone_tag({
		"management_priority_tag": management_tag,
		"branch_mode": candidate.get("branch_mode", ""),
		"branch_completed": candidate.get("branch_completed", false),
		"branch_completion_tag": candidate.get("branch_completion_tag", ""),
		"branch_completion_counts": candidate.get("branch_completion_counts", {}),
		"branch_completion_streak": candidate.get("branch_completion_streak", 0),
	})
	var backbone_completed := bool(candidate.get("backbone_completed", false))
	var backbone_completion_streak := int(candidate.get("backbone_completion_streak", 0))
	var bias := archive_ratio * 0.04
	match archive_tier:
		"已知档案":
			bias += 0.02
		"熟悉档案":
			bias += 0.05
		"定型档案":
			bias += 0.08
	match selected_campaign_filter:
		"safe":
			if dominant_run_style in ["快取完成", "快取未完成"]:
				bias += 0.03
			if dominant_route_style == "quick" and route_style_streak >= 3:
				bias += 0.03
			if route_shaping_tag in ["快取塑形中", "快取塑形稳固"]:
				bias += 0.02
			if route_lock_tag == "快取锁定":
				bias += 0.04
			if route_lock_completed == "锁定跑成":
				bias += 0.03
			if management_tag in ["重点快取经营区", "主力快取经营区"]:
				bias += 0.03 if management_tag == "重点快取经营区" else 0.06
		"rich":
			if dominant_run_style in ["深挖完成", "深挖未完成"]:
				bias += 0.04
			if dominant_route_style == "deep" and route_style_streak >= 3:
				bias += 0.04
			if route_shaping_tag in ["深挖塑形中", "深挖塑形稳固"]:
				bias += 0.03
			if route_lock_tag == "深挖锁定":
				bias += 0.05
			if route_lock_completed == "锁定跑成":
				bias += 0.03
			if management_tag in ["重点深挖经营区", "主力深挖经营区"]:
				bias += 0.03 if management_tag == "重点深挖经营区" else 0.06
		"risk":
			if archive_tier in ["熟悉档案", "定型档案"]:
				bias -= 0.02
	if backbone_tag != "":
		bias += 0.06
		if backbone_completed:
			bias += 0.04
		if backbone_completion_streak >= 3:
			bias += 0.03
	return bias


func _campaign_run_profile_route_bias(candidate: Dictionary) -> float:
	var stage_label := str(candidate.get("stage_label", "落点"))
	var dominant_run_style := str(candidate.get("dominant_run_style", "基础观察"))
	var route_lock_tag := str(candidate.get("route_lock_tag", "未锁定"))
	var bias := 0.0
	if route_lock_tag == "快取锁定":
		if stage_label == "第一阶段":
			bias += 0.08
		else:
			bias -= 0.03
	if route_lock_tag == "深挖锁定":
		if stage_label == "第二阶段":
			bias += 0.10
		else:
			bias -= 0.03
	match dominant_run_style:
		"快取完成":
			if stage_label == "第一阶段":
				bias += 0.05
			else:
				bias -= 0.02
		"深挖完成":
			if stage_label == "第二阶段":
				bias += 0.06
			else:
				bias -= 0.01
		"快取未完成":
			if stage_label == "第一阶段":
				bias += 0.03
		"深挖未完成":
			if stage_label == "第二阶段":
				bias += 0.03
	match selected_campaign_filter:
		"safe":
			if dominant_run_style in ["快取完成", "快取未完成"]:
				bias += 0.03
		"rich":
			if dominant_run_style in ["深挖完成", "深挖未完成"]:
				bias += 0.04
	return bias


func _campaign_report_note(candidate: Dictionary, active_report_channel: String) -> String:
	var report_channel := str(candidate.get("report_channel", ""))
	var report_intel := int(candidate.get("report_intel", 0))
	var report_risk := float(candidate.get("report_risk", candidate.get("risk", 0.0)))
	if report_channel == "":
		return "暂无最近回执，按区域总态推进"
	var note := "最近回执 · %s %d" % [report_channel, report_intel]
	if active_report_channel != "" and active_report_channel == report_channel:
		note += " · 与当前主情报同向"
	elif report_risk >= 0.65:
		note += " · 高风险回线"
	elif report_risk <= 0.35:
		note += " · 低风险回线"
	if candidate.has("known_tag"):
		note += " · %s" % str(candidate.get("known_tag", ""))
	if candidate.has("specialization_tag"):
		note += " · %s" % str(candidate.get("specialization_tag", "基础线"))
	if candidate.has("specialization_run_tag"):
		note += " · %s" % str(candidate.get("specialization_run_tag", "基础观察"))
	if candidate.has("run_profile_tag"):
		note += " · %s" % str(candidate.get("run_profile_tag", "基础观察"))
	if candidate.has("archive_tier"):
		note += " · %s %d" % [str(candidate.get("archive_tier", "未建档")), int(candidate.get("archive_progress", 0))]
		note += " · %s" % _region_archive_strategy_tag({
			"archive_tier": candidate.get("archive_tier", "未建档"),
			"dominant_run_style": candidate.get("dominant_run_style", "基础观察"),
		})
		note += " · %s" % _region_archive_route_tag({
			"archive_tier": candidate.get("archive_tier", "未建档"),
			"dominant_run_style": candidate.get("dominant_run_style", "基础观察"),
		})
	if candidate.has("route_shaping_tag"):
		note += " · %s" % str(candidate.get("route_shaping_tag", "塑形待定"))
	if candidate.has("management_rotation_phase"):
		var management_phase := str(candidate.get("management_rotation_phase", "常规经营"))
		if management_phase != "常规经营":
			note += " · %s" % management_phase
			if management_phase == "主经营第一段":
				note += " · 当前默认下一段"
	if bool(candidate.get("first_segment_completed", false)):
		note += " · 第一站跑成"
	if bool(candidate.get("second_segment_completed", false)):
		note += " · 第二段接稳"
	var branch_completion_tag := str(candidate.get("branch_completion_tag", "非分支段"))
	if branch_completion_tag != "非分支段":
		note += " · %s" % branch_completion_tag
	var branch_stability_tag := str(candidate.get("branch_stability_tag", "分支未定型"))
	if branch_stability_tag != "分支未定型":
		note += " · %s" % branch_stability_tag
	if candidate.has("handoff_source_region"):
		var handoff_source_region := str(candidate.get("handoff_source_region", ""))
		if handoff_source_region != "":
			var handoff_tag := "承接跑成" if bool(candidate.get("handoff_completed", false)) else "承接未跑成"
			note += " · %s" % handoff_tag
			note += " · 承接自%s" % handoff_source_region
			var handoff_streak := int(candidate.get("handoff_completion_streak", 0))
			var handoff_count := int(candidate.get("handoff_completion_count", 0))
			if handoff_streak >= 2:
				note += " · 承接连成 %d" % handoff_streak
			elif handoff_count >= 2:
				note += " · 承接累计 %d" % handoff_count
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	if not latest_report.is_empty() and bool(latest_report.get("first_segment_completed", false)):
		var latest_target_region_id := str(latest_report.get("target_region_id", ""))
		if latest_target_region_id != "" and latest_target_region_id == str(candidate.get("target_region_id", "")):
			note += " · 上一段第一站已跑成，当前承接下一段"
	if not latest_report.is_empty() and bool(latest_report.get("second_segment_completed", false)):
		var latest_region_id := str(latest_report.get("region_id", ""))
		if latest_region_id != "" and latest_region_id == str(candidate.get("target_region_id", "")):
			note += " · 第二段已接稳"
	if not latest_report.is_empty() and bool(latest_report.get("branch_completed", false)):
		var latest_target_region_id := str(latest_report.get("target_region_id", ""))
		if latest_target_region_id != "" and latest_target_region_id == str(candidate.get("target_region_id", "")):
			note += " · 上一段%s，当前继续承接" % _region_branch_completion_tag(latest_report)
	if candidate.has("route_lock_tag"):
		var route_lock_tag := str(candidate.get("route_lock_tag", "未锁定"))
		if route_lock_tag != "未锁定":
			note += " · %s" % route_lock_tag
	if candidate.has("route_lock_completed"):
		var route_lock_completed := str(candidate.get("route_lock_completed", "未成型"))
		if route_lock_completed != "未成型":
			note += " · %s" % route_lock_completed
	var dominant_run_style := str(candidate.get("dominant_run_style", "基础观察"))
	var stage_label := str(candidate.get("stage_label", "落点"))
	var route_lock_tag := str(candidate.get("route_lock_tag", "未锁定"))
	if route_lock_tag == "快取锁定":
		note += " · 默认短推进"
	elif route_lock_tag == "深挖锁定":
		note += " · 默认连续复核"
	elif dominant_run_style == "快取完成" and stage_label == "第一阶段":
		note += " · 适合短推进"
	elif dominant_run_style == "深挖完成" and stage_label == "第二阶段":
		note += " · 适合连续深挖"
	return note


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


func _campaign_management_rotation_plan(candidates: Array) -> Dictionary:
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	if not latest_report.is_empty() and bool(latest_report.get("second_segment_completed", false)):
		var branch_plan := _campaign_post_second_segment_plan(candidates, latest_report)
		if not branch_plan.is_empty():
			return branch_plan
	var primary_quick: Dictionary = {}
	var primary_deep: Dictionary = {}
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		match str(candidate.get("management_priority_tag", "常规经营区")):
			"主力快取经营区":
				if primary_quick.is_empty() or _candidate_management_rotation_strength(candidate) > _candidate_management_rotation_strength(primary_quick):
					primary_quick = candidate
			"主力深挖经营区":
				if primary_deep.is_empty() or _candidate_management_rotation_strength(candidate) > _candidate_management_rotation_strength(primary_deep):
					primary_deep = candidate
	if primary_quick.is_empty() and primary_deep.is_empty():
		return {"tag": "常规经营", "summary": "当前没有主力经营区，按总态与窗口推进。"}
	if primary_quick.is_empty():
		var deep_suffix := _candidate_rotation_strength_note(primary_deep)
		var deep_lead := "当前先巩固深挖经营骨干区" if str(primary_deep.get("backbone_completion_tag", "")) != "" else "当前先经营主力深挖区"
		return {
			"tag": "优先深挖经营",
			"summary": "%s %s%s，再沿复核链继续扩样。" % [deep_lead, str(primary_deep.get("name", "")), deep_suffix],
			"preferred_target_region_id": str(primary_deep.get("target_region_id", "")),
		}
	if primary_deep.is_empty():
		var quick_suffix := _candidate_rotation_strength_note(primary_quick)
		var quick_lead := "当前先巩固快取经营骨干区" if str(primary_quick.get("backbone_completion_tag", "")) != "" else "当前先经营主力快取区"
		return {
			"tag": "优先快取经营",
			"summary": "%s %s%s，拿到关键样本后快速撤离。" % [quick_lead, str(primary_quick.get("name", "")), quick_suffix],
			"preferred_target_region_id": str(primary_quick.get("target_region_id", "")),
		}
	var quick_score := _candidate_management_rotation_strength(primary_quick)
	var deep_score := _candidate_management_rotation_strength(primary_deep)
	if quick_score >= deep_score:
		var quick_lead := "当前先巩固快取经营骨干区" if str(primary_quick.get("backbone_completion_tag", "")) != "" else "当前先经营主力快取区"
		return {
			"tag": "快取转深挖",
			"summary": "%s %s%s，再转主力深挖区 %s%s。" % [
				quick_lead,
				str(primary_quick.get("name", "")),
				_candidate_rotation_strength_note(primary_quick),
				str(primary_deep.get("name", "")),
				_candidate_rotation_strength_note(primary_deep),
			],
			"preferred_target_region_id": str(primary_quick.get("target_region_id", "")),
		}
	var deep_lead := "当前先巩固深挖经营骨干区" if str(primary_deep.get("backbone_completion_tag", "")) != "" else "当前先经营主力深挖区"
	return {
		"tag": "深挖转快取",
		"summary": "%s %s%s，再转主力快取区 %s%s。" % [
			deep_lead,
			str(primary_deep.get("name", "")),
			_candidate_rotation_strength_note(primary_deep),
			str(primary_quick.get("name", "")),
			_candidate_rotation_strength_note(primary_quick),
		],
		"preferred_target_region_id": str(primary_deep.get("target_region_id", "")),
	}


func _campaign_post_second_segment_plan(candidates: Array, latest_report: Dictionary) -> Dictionary:
	var management_tag := str(latest_report.get("management_priority_tag", "常规经营区"))
	var latest_region_name := str(latest_report.get("region_name", latest_report.get("region_id", "当前区域")))
	var latest_branch_mode := str(latest_report.get("branch_mode", ""))
	var latest_branch_completed := bool(latest_report.get("branch_completed", false))
	if latest_branch_completed and latest_branch_mode == "deep_expand":
		var deep_candidate := _best_branch_candidate(candidates, "deep")
		if not deep_candidate.is_empty():
			return {
				"tag": "深挖扩线",
				"summary": "当前 %s 已完成扩线接稳，下一步继续沿深挖线扩线，优先压 %s。" % [
					latest_region_name,
					str(deep_candidate.get("name", "")),
				],
				"preferred_target_region_id": str(deep_candidate.get("target_region_id", "")),
			}
	if latest_branch_completed and latest_branch_mode == "quick_close":
		var quick_candidate := _best_branch_candidate(candidates, "quick")
		if not quick_candidate.is_empty():
			return {
				"tag": "快取收束",
				"summary": "当前 %s 已完成收束接稳，下一步沿快取线收束，优先先吃 %s 再准备转场。" % [
					latest_region_name,
					str(quick_candidate.get("name", "")),
				],
				"preferred_target_region_id": str(quick_candidate.get("target_region_id", "")),
			}
	if management_tag in ["主力深挖经营区", "重点深挖经营区"] or str(latest_report.get("route_lock_tag", "未锁定")) == "深挖锁定":
		var branch_candidate := _best_branch_candidate(candidates, "deep")
		if not branch_candidate.is_empty():
			return {
				"tag": "深挖扩线",
				"summary": "当前 %s 的第二段已经接稳，下一步沿深挖线继续扩线，优先压 %s。" % [
					latest_region_name,
					str(branch_candidate.get("name", "")),
				],
				"preferred_target_region_id": str(branch_candidate.get("target_region_id", "")),
			}
	if management_tag in ["主力快取经营区", "重点快取经营区"] or str(latest_report.get("route_lock_tag", "未锁定")) == "快取锁定":
		var branch_candidate := _best_branch_candidate(candidates, "quick")
		if not branch_candidate.is_empty():
			return {
				"tag": "快取收束",
				"summary": "当前 %s 的第二段已经接稳，下一步沿快取线收束，优先先吃 %s 再准备转场。" % [
					latest_region_name,
					str(branch_candidate.get("name", "")),
				],
				"preferred_target_region_id": str(branch_candidate.get("target_region_id", "")),
			}
	return {}


func _best_branch_candidate(candidates: Array, branch_mode: String) -> Dictionary:
	var best: Dictionary = {}
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		var stage_label := str(candidate.get("stage_label", "落点"))
		if branch_mode == "deep" and stage_label != "第二阶段":
			continue
		if branch_mode == "quick" and stage_label != "第一阶段":
			continue
		if best.is_empty():
			best = candidate
			continue
		var current_score := _candidate_branch_strength(candidate, branch_mode)
		var best_score := _candidate_branch_strength(best, branch_mode)
		if current_score > best_score:
			best = candidate
	return best


func _candidate_branch_strength(candidate: Dictionary, branch_mode: String) -> float:
	if branch_mode == "deep":
		return float(candidate.get("score_rich", candidate.get("score", 0.0))) + _candidate_management_rotation_strength(candidate)
	return float(candidate.get("score_safe", candidate.get("score", 0.0))) + _candidate_management_rotation_strength(candidate)


func _candidate_management_rotation_strength(candidate: Dictionary) -> float:
	var score := float(candidate.get("score", 0.0))
	score += float(candidate.get("archive_progress", 0)) * 0.08
	score += float(candidate.get("handoff_completion_streak", 0)) * 0.20
	score += float(candidate.get("handoff_completion_count", 0)) * 0.04
	score += float(candidate.get("backbone_completion_streak", 0)) * 0.28
	score += float(_region_branch_management_bonus({
		"branch_mode": candidate.get("branch_mode", ""),
		"branch_completed": candidate.get("branch_completed", false),
		"branch_completion_tag": candidate.get("branch_completion_tag", ""),
		"branch_completion_counts": candidate.get("branch_completion_counts", {}),
		"branch_completion_streak": candidate.get("branch_completion_streak", 0),
	})) * 0.90
	score += float(_region_management_backbone_bonus({
		"management_priority_tag": candidate.get("management_priority_tag", "常规经营区"),
		"branch_mode": candidate.get("branch_mode", ""),
		"branch_completed": candidate.get("branch_completed", false),
		"branch_completion_tag": candidate.get("branch_completion_tag", ""),
		"branch_completion_counts": candidate.get("branch_completion_counts", {}),
		"branch_completion_streak": candidate.get("branch_completion_streak", 0),
	})) * 1.4
	if bool(candidate.get("handoff_completed", false)):
		score += 0.10
	if bool(candidate.get("backbone_completed", false)):
		score += 0.16
	if str(candidate.get("route_lock_completed", "未成型")) == "锁定跑成":
		score += 0.12
	return score


func _candidate_rotation_strength_note(candidate: Dictionary) -> String:
	var handoff_streak := int(candidate.get("handoff_completion_streak", 0))
	var handoff_count := int(candidate.get("handoff_completion_count", 0))
	var backbone_streak := int(candidate.get("backbone_completion_streak", 0))
	var backbone_completed := bool(candidate.get("backbone_completed", false))
	var backbone_completion_tag := str(candidate.get("backbone_completion_tag", ""))
	var backbone_tag := _region_management_backbone_tag({
		"management_priority_tag": candidate.get("management_priority_tag", "常规经营区"),
		"branch_mode": candidate.get("branch_mode", ""),
		"branch_completed": candidate.get("branch_completed", false),
		"branch_completion_tag": candidate.get("branch_completion_tag", ""),
		"branch_completion_counts": candidate.get("branch_completion_counts", {}),
		"branch_completion_streak": candidate.get("branch_completion_streak", 0),
	})
	if backbone_tag != "":
		if backbone_completion_tag != "":
			return "（%s）" % backbone_completion_tag
		if backbone_completed and backbone_streak >= 2:
			return "（%s · 跑成 %d）" % [backbone_tag, backbone_streak]
		if backbone_completed:
			return "（%s · 已跑成）" % backbone_tag
		return "（%s）" % backbone_tag
	if handoff_streak >= 3:
		return "（承接连成 %d）" % handoff_streak
	if handoff_count >= 4:
		return "（承接累计 %d）" % handoff_count
	return ""


func _preferred_rotation_candidate_id(candidates: Array) -> String:
	var rotation_plan := _campaign_management_rotation_plan(candidates)
	var preferred_target_region_id := str(rotation_plan.get("preferred_target_region_id", ""))
	if preferred_target_region_id != "":
		return preferred_target_region_id
	var best_backbone_completed: Dictionary = {}
	var best_first_segment: Dictionary = {}
	var best_single_segment: Dictionary = {}
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		var phase := str(candidate.get("management_rotation_phase", "常规经营"))
		if str(candidate.get("backbone_completion_tag", "")) != "":
			if best_backbone_completed.is_empty() or _candidate_management_rotation_strength(candidate) > _candidate_management_rotation_strength(best_backbone_completed):
				best_backbone_completed = candidate
		if phase == "主经营第一段":
			if best_first_segment.is_empty() or _candidate_management_rotation_strength(candidate) > _candidate_management_rotation_strength(best_first_segment):
				best_first_segment = candidate
		elif phase in ["单区快取主经营", "单区深挖主经营"]:
			if best_single_segment.is_empty() or _candidate_management_rotation_strength(candidate) > _candidate_management_rotation_strength(best_single_segment):
				best_single_segment = candidate
	if not best_backbone_completed.is_empty():
		return str(best_backbone_completed.get("target_region_id", ""))
	if not best_first_segment.is_empty():
		return str(best_first_segment.get("target_region_id", ""))
	if not best_single_segment.is_empty():
		return str(best_single_segment.get("target_region_id", ""))
	return ""


func _build_world_backdrop() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	var ocean := ColorRect.new()
	ocean.color = Color8(38, 51, 56, 255)
	ocean.position = Vector2.ZERO
	ocean.custom_minimum_size = map_size
	map_layer.add_child(ocean)

	for haze_variant in [
		{"color": Color8(60, 76, 80, 88), "pos": Vector2(map_size.x * 0.00, map_size.y * 0.08), "size": Vector2(map_size.x * 1.00, map_size.y * 0.16)},
		{"color": Color8(46, 61, 66, 72), "pos": Vector2(map_size.x * 0.00, map_size.y * 0.58), "size": Vector2(map_size.x * 1.00, map_size.y * 0.20)},
	]:
		var sea_haze := ColorRect.new()
		sea_haze.color = haze_variant["color"]
		sea_haze.position = haze_variant["pos"]
		sea_haze.custom_minimum_size = haze_variant["size"]
		map_layer.add_child(sea_haze)

	var west_land := [
		Vector2(map_size.x * 0.04, map_size.y * 0.20),
		Vector2(map_size.x * 0.08, map_size.y * 0.14),
		Vector2(map_size.x * 0.14, map_size.y * 0.10),
		Vector2(map_size.x * 0.22, map_size.y * 0.09),
		Vector2(map_size.x * 0.28, map_size.y * 0.12),
		Vector2(map_size.x * 0.33, map_size.y * 0.16),
		Vector2(map_size.x * 0.38, map_size.y * 0.22),
		Vector2(map_size.x * 0.40, map_size.y * 0.34),
		Vector2(map_size.x * 0.37, map_size.y * 0.42),
		Vector2(map_size.x * 0.33, map_size.y * 0.48),
		Vector2(map_size.x * 0.20, map_size.y * 0.54),
		Vector2(map_size.x * 0.13, map_size.y * 0.52),
		Vector2(map_size.x * 0.08, map_size.y * 0.44),
		Vector2(map_size.x * 0.03, map_size.y * 0.31),
	]
	var center_land := [
		Vector2(map_size.x * 0.28, map_size.y * 0.46),
		Vector2(map_size.x * 0.34, map_size.y * 0.41),
		Vector2(map_size.x * 0.40, map_size.y * 0.40),
		Vector2(map_size.x * 0.48, map_size.y * 0.42),
		Vector2(map_size.x * 0.54, map_size.y * 0.44),
		Vector2(map_size.x * 0.60, map_size.y * 0.55),
		Vector2(map_size.x * 0.59, map_size.y * 0.61),
		Vector2(map_size.x * 0.56, map_size.y * 0.68),
		Vector2(map_size.x * 0.52, map_size.y * 0.73),
		Vector2(map_size.x * 0.46, map_size.y * 0.75),
		Vector2(map_size.x * 0.40, map_size.y * 0.74),
		Vector2(map_size.x * 0.32, map_size.y * 0.70),
		Vector2(map_size.x * 0.24, map_size.y * 0.58),
	]
	var east_land := [
		Vector2(map_size.x * 0.58, map_size.y * 0.18),
		Vector2(map_size.x * 0.63, map_size.y * 0.15),
		Vector2(map_size.x * 0.69, map_size.y * 0.14),
		Vector2(map_size.x * 0.75, map_size.y * 0.16),
		Vector2(map_size.x * 0.79, map_size.y * 0.20),
		Vector2(map_size.x * 0.84, map_size.y * 0.32),
		Vector2(map_size.x * 0.85, map_size.y * 0.39),
		Vector2(map_size.x * 0.82, map_size.y * 0.46),
		Vector2(map_size.x * 0.77, map_size.y * 0.50),
		Vector2(map_size.x * 0.72, map_size.y * 0.54),
		Vector2(map_size.x * 0.66, map_size.y * 0.53),
		Vector2(map_size.x * 0.61, map_size.y * 0.46),
		Vector2(map_size.x * 0.55, map_size.y * 0.31),
	]
	var south_land := [
		Vector2(map_size.x * 0.72, map_size.y * 0.62),
		Vector2(map_size.x * 0.77, map_size.y * 0.58),
		Vector2(map_size.x * 0.81, map_size.y * 0.58),
		Vector2(map_size.x * 0.87, map_size.y * 0.60),
		Vector2(map_size.x * 0.90, map_size.y * 0.64),
		Vector2(map_size.x * 0.92, map_size.y * 0.76),
		Vector2(map_size.x * 0.89, map_size.y * 0.81),
		Vector2(map_size.x * 0.86, map_size.y * 0.84),
		Vector2(map_size.x * 0.80, map_size.y * 0.85),
		Vector2(map_size.x * 0.75, map_size.y * 0.82),
		Vector2(map_size.x * 0.69, map_size.y * 0.72),
	]

	_add_map_landmass(west_land, Color8(117, 121, 92, 220), Color8(205, 194, 151, 112))
	_add_map_landmass(center_land, Color8(124, 124, 94, 216), Color8(210, 198, 152, 108))
	_add_map_landmass(east_land, Color8(116, 122, 99, 208), Color8(201, 191, 151, 96))
	_add_map_landmass(south_land, Color8(130, 123, 97, 198), Color8(208, 196, 152, 88))

	for relief_variant in [
		{"points": [
			Vector2(map_size.x * 0.12, map_size.y * 0.19),
			Vector2(map_size.x * 0.18, map_size.y * 0.17),
			Vector2(map_size.x * 0.25, map_size.y * 0.20),
			Vector2(map_size.x * 0.29, map_size.y * 0.27),
			Vector2(map_size.x * 0.26, map_size.y * 0.34),
			Vector2(map_size.x * 0.18, map_size.y * 0.35),
			Vector2(map_size.x * 0.12, map_size.y * 0.30),
		], "fill": Color8(146, 138, 101, 84), "coast": Color8(224, 209, 160, 58)},
		{"points": [
			Vector2(map_size.x * 0.36, map_size.y * 0.50),
			Vector2(map_size.x * 0.44, map_size.y * 0.46),
			Vector2(map_size.x * 0.50, map_size.y * 0.48),
			Vector2(map_size.x * 0.54, map_size.y * 0.56),
			Vector2(map_size.x * 0.51, map_size.y * 0.63),
			Vector2(map_size.x * 0.43, map_size.y * 0.67),
			Vector2(map_size.x * 0.35, map_size.y * 0.61),
		], "fill": Color8(106, 132, 96, 76), "coast": Color8(197, 210, 176, 42)},
		{"points": [
			Vector2(map_size.x * 0.66, map_size.y * 0.24),
			Vector2(map_size.x * 0.73, map_size.y * 0.23),
			Vector2(map_size.x * 0.77, map_size.y * 0.29),
			Vector2(map_size.x * 0.75, map_size.y * 0.37),
			Vector2(map_size.x * 0.68, map_size.y * 0.40),
			Vector2(map_size.x * 0.62, map_size.y * 0.33),
		], "fill": Color8(152, 132, 102, 72), "coast": Color8(226, 204, 166, 36)},
	]:
		_add_map_landmass(relief_variant["points"], relief_variant["fill"], relief_variant["coast"], 1.2)

	for river_variant in [
		[Vector2(map_size.x * 0.30, map_size.y * 0.16), Vector2(map_size.x * 0.34, map_size.y * 0.23), Vector2(map_size.x * 0.33, map_size.y * 0.34), Vector2(map_size.x * 0.27, map_size.y * 0.44)],
		[Vector2(map_size.x * 0.48, map_size.y * 0.46), Vector2(map_size.x * 0.50, map_size.y * 0.54), Vector2(map_size.x * 0.46, map_size.y * 0.62), Vector2(map_size.x * 0.40, map_size.y * 0.69)],
		[Vector2(map_size.x * 0.73, map_size.y * 0.18), Vector2(map_size.x * 0.76, map_size.y * 0.28), Vector2(map_size.x * 0.73, map_size.y * 0.38), Vector2(map_size.x * 0.68, map_size.y * 0.48)],
	]:
		_add_map_polyline(river_variant, Color(0.66, 0.79, 0.82, 0.42), 1.4)

	for contour_variant in [
		[Vector2(map_size.x * 0.09, map_size.y * 0.24), Vector2(map_size.x * 0.17, map_size.y * 0.23), Vector2(map_size.x * 0.25, map_size.y * 0.27), Vector2(map_size.x * 0.30, map_size.y * 0.35)],
		[Vector2(map_size.x * 0.34, map_size.y * 0.55), Vector2(map_size.x * 0.40, map_size.y * 0.52), Vector2(map_size.x * 0.48, map_size.y * 0.55), Vector2(map_size.x * 0.53, map_size.y * 0.62)],
		[Vector2(map_size.x * 0.63, map_size.y * 0.26), Vector2(map_size.x * 0.69, map_size.y * 0.27), Vector2(map_size.x * 0.75, map_size.y * 0.33), Vector2(map_size.x * 0.77, map_size.y * 0.41)],
		[Vector2(map_size.x * 0.74, map_size.y * 0.67), Vector2(map_size.x * 0.80, map_size.y * 0.66), Vector2(map_size.x * 0.86, map_size.y * 0.71)],
	]:
		_add_map_polyline(contour_variant, Color(0.96, 0.91, 0.73, 0.10), 1.0)

	for inset_variant in [
		{"points": [
			Vector2(map_size.x * 0.18, map_size.y * 0.22),
			Vector2(map_size.x * 0.25, map_size.y * 0.20),
			Vector2(map_size.x * 0.30, map_size.y * 0.28),
			Vector2(map_size.x * 0.26, map_size.y * 0.35),
			Vector2(map_size.x * 0.18, map_size.y * 0.33),
		], "color": Color8(126, 132, 101, 94)},
		{"points": [
			Vector2(map_size.x * 0.64, map_size.y * 0.26),
			Vector2(map_size.x * 0.72, map_size.y * 0.24),
			Vector2(map_size.x * 0.76, map_size.y * 0.33),
			Vector2(map_size.x * 0.69, map_size.y * 0.38),
			Vector2(map_size.x * 0.61, map_size.y * 0.33),
		], "color": Color8(118, 126, 110, 88)},
	]:
		var inset := Polygon2D.new()
		inset.polygon = inset_variant["points"]
		inset.color = inset_variant["color"]
		map_layer.add_child(inset)


func _add_map_landmass(points: Array, fill_color: Color, coast_color: Color, coast_width: float = 2.0) -> void:
	var land := Polygon2D.new()
	land.polygon = PackedVector2Array(points)
	land.color = fill_color
	map_layer.add_child(land)

	var coast := Line2D.new()
	coast.points = PackedVector2Array(points + [points[0]])
	coast.width = coast_width
	coast.default_color = coast_color
	coast.antialiased = true
	map_layer.add_child(coast)


func _add_map_polyline(points: Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array(points)
	line.width = width
	line.default_color = color
	line.antialiased = true
	map_layer.add_child(line)


func _build_world_ambience() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var active_rel: Vector2 = REGION_LAYOUT.get(active_region_id, Vector2(0.5, 0.5))
	var active_pos := Vector2(map_size.x * active_rel.x, map_size.y * active_rel.y)
	var accent := _active_region_accent()

	for current in [
		{"from": Vector2(map_size.x * 0.63, map_size.y * 0.22), "to": Vector2(map_size.x * 0.82, map_size.y * 0.30)},
		{"from": Vector2(map_size.x * 0.70, map_size.y * 0.44), "to": Vector2(map_size.x * 0.90, map_size.y * 0.56)},
		{"from": Vector2(map_size.x * 0.74, map_size.y * 0.66), "to": Vector2(map_size.x * 0.90, map_size.y * 0.78)},
	]:
		var flow := _make_route_line(current["from"], current["to"], 0.85)
		flow.default_color = Color(0.70, 0.86, 0.97, 0.10)
		flow.width = 1.1
		map_layer.add_child(flow)

	var focus_halo := _make_map_dot(62.0, Color(accent.r, accent.g, accent.b, 0.06), Color(accent.r, accent.g, accent.b, 0.12), 1, 0.45)
	focus_halo.position = active_pos - Vector2(42, 42)
	map_layer.add_child(focus_halo)

	var focus_core := _make_map_dot(18.0, Color(1.0, 0.95, 0.78, 0.08), Color(1.0, 0.95, 0.78, 0.20), 1, 0.55)
	focus_core.position = active_pos - Vector2(12, 12)
	map_layer.add_child(focus_core)


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
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var target_region_id := str(selected_campaign_landing_target_id)
	if target_region_id == "":
		target_region_id = str(selected_frontier_target_id)
	if target_region_id == "":
		target_region_id = str(_active_frontier_link(active_region).get("target_region_id", ""))
	if target_region_id == "" or target_region_id == active_region_id:
		return
	if not positions.has(active_region_id) or not positions.has(target_region_id):
		return

	var route_strength := 0.72
	for connector_variant in active_region.get("connectors", []):
		var connector: Dictionary = connector_variant
		if str(connector.get("target_region_id", "")) == target_region_id:
			route_strength = float(connector.get("strength", 0.72))
			break

	var line := _make_route_line(
		Vector2(positions[active_region_id]),
		Vector2(positions[target_region_id]),
		route_strength
	)
	line.default_color = Color(0.94, 0.89, 0.62, clamp(0.20 + route_strength * 0.18, 0.22, 0.42))
	line.width = 2.2
	map_layer.add_child(line)


func _build_realistic_map_canvas(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	var viewport_size := get_viewport_rect().size
	if viewport_size.x > map_size.x or viewport_size.y > map_size.y:
		map_layer.size = viewport_size
		map_size = viewport_size
	if map_layer.get_parent() != null:
		var parent_size := (map_layer.get_parent() as Control).get_rect().size
		if parent_size.x > map_size.x or parent_size.y > map_size.y:
			map_layer.size = parent_size
			map_size = parent_size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var target_region_id := str(selected_campaign_landing_target_id)
	if target_region_id == "":
		target_region_id = str(selected_frontier_target_id)
	if target_region_id == "":
		target_region_id = str(_active_frontier_link(active_region).get("target_region_id", ""))

	var canvas: Control = RealisticWorldMapCanvas.new()
	canvas.position = Vector2.ZERO
	canvas.custom_minimum_size = map_size
	canvas.size = map_size
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_layer.add_child(canvas)
	var priority := _recommended_region_for_world()
	canvas.configure(regions, active_region_id, target_region_id, REGION_LAYOUT, REGION_COLORS, str(priority.get("region_id", "")))


func _build_map_hit_areas(regions: Array) -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	for region_variant in regions:
		var region: Dictionary = region_variant
		var region_id := str(region.get("id", ""))
		if not REGION_LAYOUT.has(region_id):
			continue
		var rel: Vector2 = REGION_LAYOUT.get(region_id, Vector2(0.5, 0.5))
		var pos := Vector2(map_size.x * rel.x, map_size.y * rel.y)
		var button := Button.new()
		button.text = ""
		button.flat = true
		button.modulate = Color(1.0, 1.0, 1.0, 0.0)
		button.custom_minimum_size = Vector2(34, 34)
		button.position = pos - Vector2(17, 17)
		button.pressed.connect(_on_region_pressed.bind(region_id))
		map_layer.add_child(button)


func _build_frontier_network_overlay(regions: Array) -> void:
	return


func _build_campaign_overlay(regions: Array) -> void:
	return


func _make_route_line(from_pos: Vector2, to_pos: Vector2, strength: float) -> Line2D:
	var line := Line2D.new()
	line.points = PackedVector2Array([from_pos, to_pos])
	line.width = lerpf(0.9, 2.2, clamp(strength, 0.0, 1.0))
	line.default_color = Color(0.88, 0.89, 0.70, clamp(0.10 + strength * 0.12, 0.10, 0.28))
	line.antialiased = true
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
		var node_size := 13.0 if is_active else 9.0

		var shadow := _make_map_dot(node_size + 8.0, Color(0.03, 0.06, 0.09, 0.16 if is_active else 0.08), Color(0.0, 0.0, 0.0, 0.0), 0)
		var shadow_base := pos - Vector2((node_size + 8.0) * 0.5, (node_size + 8.0) * 0.5) + Vector2(1.5, 2.5)
		shadow.position = shadow_base
		map_layer.add_child(shadow)

		var outer_ring := _make_map_dot(node_size + 10.0, Color(accent.r, accent.g, accent.b, 0.04 if is_active else 0.02), Color(accent.r, accent.g, accent.b, 0.24 if is_active else 0.12), 1)
		outer_ring.position = pos - Vector2((node_size + 10.0) * 0.5, (node_size + 10.0) * 0.5)
		map_layer.add_child(outer_ring)

		var shell := _make_map_dot(node_size, Color(accent.r, accent.g, accent.b, 0.88 if is_active else 0.76), Color(1.0, 0.98, 0.92, 0.70 if is_active else 0.30), 1)
		var shell_base := pos - Vector2(node_size * 0.5, node_size * 0.5)
		shell.position = shell_base
		map_layer.add_child(shell)

		var report := _region_report(region_id)
		if not report.is_empty():
			var report_badge := _make_map_dot(7.0, Color8(225, 196, 110, 220), Color8(255, 241, 194, 210), 1, 0.50)
			report_badge.position = pos + Vector2(6, -10)
			map_layer.add_child(report_badge)

		if is_active:
			var glow := _make_map_dot(node_size + 16.0, Color(1.0, 0.92, 0.58, 0.06), Color(1.0, 0.92, 0.58, 0.14), 1, 0.46)
			glow.position = shell.position - Vector2(9, 9)
			map_layer.add_child(glow)
			map_layer.move_child(glow, map_layer.get_child_count() - 2)

			var focus_frame := _make_map_dot(node_size + 5.0, Color(1.0, 0.92, 0.58, 0.02), Color(1.0, 0.92, 0.58, 0.18), 1, 0.46)
			focus_frame.position = shell.position - Vector2(3, 3)
			map_layer.add_child(focus_frame)
			map_layer.move_child(focus_frame, map_layer.get_child_count() - 2)
			_animate_region_focus_entry(shell, outer_ring, shadow, shell_base, shadow_base)
			_animate_focus_glow(glow, focus_frame)

		var button := Button.new()
		button.text = ""
		button.flat = true
		button.custom_minimum_size = Vector2(26, 26)
		button.position = shell.position - Vector2(4, 4)
		button.pressed.connect(_on_region_pressed.bind(region_id))
		button.mouse_entered.connect(func() -> void:
			shadow.position = shadow_base + Vector2(2, 3)
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

		if is_active:
			var label_shell := PanelContainer.new()
			var label_style := StyleBoxFlat.new()
			label_style.corner_radius_top_left = 8
			label_style.corner_radius_top_right = 8
			label_style.corner_radius_bottom_left = 8
			label_style.corner_radius_bottom_right = 8
			label_style.content_margin_left = 7
			label_style.content_margin_right = 7
			label_style.content_margin_top = 3
			label_style.content_margin_bottom = 3
			label_style.bg_color = Color(0.12, 0.16, 0.18, 0.56)
			label_style.border_color = Color(accent.r, accent.g, accent.b, 0.28)
			label_style.set_border_width_all(1)
			label_shell.add_theme_stylebox_override("panel", label_style)
			label_shell.position = shell.position + Vector2(13, -5)
			var plaque_label := Label.new()
			plaque_label.text = str(region.get("name", region_id))
			_style_dim(plaque_label, 8)
			plaque_label.modulate = Color(0.98, 0.95, 0.88, 0.88)
			label_shell.add_child(plaque_label)
			map_layer.add_child(label_shell)


func _make_map_dot(size: float, fill_color: Color, border_color: Color, border_width: int = 1, alpha_scale: float = 1.0) -> PanelContainer:
	var dot := PanelContainer.new()
	dot.custom_minimum_size = Vector2(size, size)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = int(size * 0.5)
	style.corner_radius_top_right = int(size * 0.5)
	style.corner_radius_bottom_left = int(size * 0.5)
	style.corner_radius_bottom_right = int(size * 0.5)
	style.bg_color = Color(fill_color.r, fill_color.g, fill_color.b, fill_color.a * alpha_scale)
	style.border_color = Color(border_color.r, border_color.g, border_color.b, border_color.a * alpha_scale)
	style.set_border_width_all(border_width)
	dot.add_theme_stylebox_override("panel", style)
	return dot


func _build_map_command_layer() -> void:
	var map_size := map_layer.get_rect().size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	var minimal_hud := _make_minimal_map_hud(active_region)
	minimal_hud.position = Vector2(24, 22)
	map_layer.add_child(minimal_hud)

	var minimal_hint := _make_minimal_map_hint(active_region)
	minimal_hint.position = Vector2(24, map_size.y - 86)
	map_layer.add_child(minimal_hint)


func _make_minimal_map_hud(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 76)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = _active_region_accent().lightened(0.06)
	ribbon.custom_minimum_size = Vector2(0, 4)
	box.add_child(ribbon)

	var title := Label.new()
	title.text = str(active_region.get("name", "未选择区域"))
	_style_primary_title(title, 20)
	box.add_child(title)

	var summary: Dictionary = active_region.get("region_summary", {})
	var subtitle := Label.new()
	subtitle.text = str(summary.get("one_liner", active_region.get("region_role", "生态观测区")))
	_style_dim(subtitle, 12)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)

	var loop := Label.new()
	loop.text = "玩法：先选下一片区，再进去追踪、记录、撤离。"
	_style_dim(loop, 11)
	loop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(loop)
	return panel


func _make_minimal_map_hint(active_region: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 56)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var ribbon := ColorRect.new()
	ribbon.color = Color8(210, 182, 96)
	ribbon.custom_minimum_size = Vector2(0, 3)
	box.add_child(ribbon)

	var hint := Label.new()
	hint.text = "这张图只做一件事：决定下一站去哪里。"
	_style_secondary_title(hint, 12)
	box.add_child(hint)

	var sub := Label.new()
	sub.text = "地图上只看当前区域、下一站和一条路线。进区后再做调查。"
	_style_dim(sub, 10)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)
	return panel


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
	var report := _region_report(str(active_region.get("id", active_region_id)))
	var pressure_headlines: Array = active_region.get("pressure_headlines", [])
	var chain_focus: Array = active_region.get("chain_focus", [])

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
	focus_line.text = "%s · %s" % [
		str(active_region.get("name", "未选择区域")),
		str(report.get("top_intel_channel", "未建立回执线")) if not report.is_empty() else "尚无最近回执",
	]
	_style_dim(focus_line, 9)
	box.add_child(focus_line)

	var reason_line := Label.new()
	reason_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason_line.text = "%s · %s" % [
		_region_event_window_text(active_region),
		_route_identity_text(active_region),
	]
	_style_dim(reason_line, 9)
	box.add_child(reason_line)

	var strategy_line := Label.new()
	strategy_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	strategy_line.text = _region_run_profile_strategy_text(report)
	_style_dim(strategy_line, 9)
	box.add_child(strategy_line)

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
	side_panel.visible = false
	for child in side_box.get_children():
		child.queue_free()


func _refresh_game_hud() -> void:
	if game_hud == null:
		return
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	if active_region.is_empty():
		hud_region_label.text = "生态指挥"
		hud_summary_label.text = "等待世界状态数据。"
		hud_world_label.text = ""
		hud_loop_label.text = ""
		hud_metric_label.text = ""
		hud_species_label.text = ""
		hud_objective_label.text = ""
		hud_action_label.text = ""
		return

	var health: Dictionary = active_region.get("health_state", {})
	var resources: Dictionary = active_region.get("resource_state", {})
	var hazards: Dictionary = active_region.get("hazard_state", {})
	var frontier_links: Array = active_region.get("frontier_links", [])
	var accent := _active_region_accent()
	var report_pending := _latest_expedition_report_pending()
	_sync_game_hud_style(report_pending, accent)
	hud_region_label.text = "撤离报告待回灌" if report_pending else str(active_region.get("name", "未选择区域"))
	hud_region_label.modulate = accent.lightened(0.30)
	if report_pending:
		hud_summary_label.text = _pending_expedition_report_summary()
		hud_world_label.text = "下一步：点击“回灌报告”，把探索结果写回后端生态系统。"
		hud_loop_label.text = _pending_expedition_report_effect_line()
	else:
		hud_summary_label.text = _region_plain_summary(active_region)
		hud_world_label.text = _world_goal_line()
		var progress_line := _mainline_progress_line()
		hud_loop_label.text = "%s\n%s" % [progress_line, _world_next_step_line(active_region)] if progress_line != "" else _world_next_step_line(active_region)
	hud_metric_label.text = "多样性 %s   韧性 %s   风险 %s   关键资源 %s" % [
		_percent_text(float(health.get("biodiversity", 0.0))),
		_percent_text(float(health.get("resilience", 0.0))),
		_percent_text(_max_dictionary_value(hazards)),
		_top_dictionary_label(resources),
	]
	hud_species_label.text = "物种：%s" % _top_species_line(active_region)
	if report_pending:
		hud_objective_label.text = _pending_expedition_report_objective_line()
	else:
		hud_objective_label.text = "%s\n%s" % [
			_world_mainline_enter_line(selected_game_action, active_region, frontier_links),
			_world_mainline_controls_line(selected_game_action, active_region, frontier_links),
		]
	_sync_action_button_state()
	_sync_primary_button_state(active_region)
	var backend_intent: Dictionary = active_region.get("player_intent", {})
	if backend_intent.is_empty():
		backend_intent = active_region.get("incoming_player_intent", {})
	if backend_intent.is_empty():
		if pending_strategy_message != "":
			hud_action_label.text = pending_strategy_message
		elif report_pending:
			hud_action_label.text = "当前唯一主线步骤：点击“回灌报告”。完成后才能选择新区域或开始下一轮主线。"
		else:
			hud_action_label.text = _world_mainline_enter_line(selected_game_action, active_region, frontier_links)
	else:
		pending_strategy_message = ""
		hud_action_label.text = "后端回执：%s" % str(backend_intent.get("summary", "策略已接入世界状态。"))


func _sync_game_hud_style(report_pending: bool, accent: Color) -> void:
	if game_hud == null:
		return
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0.08, 0.07, 0.035, 0.74) if report_pending else Color(0.04, 0.07, 0.06, 0.62)
	hud_style.border_color = Color(1.0, 0.78, 0.28, 0.54) if report_pending else Color(accent.r, accent.g, accent.b, 0.30)
	hud_style.set_border_width_all(2 if report_pending else 1)
	hud_style.corner_radius_top_left = 14
	hud_style.corner_radius_top_right = 14
	hud_style.corner_radius_bottom_left = 14
	hud_style.corner_radius_bottom_right = 14
	hud_style.content_margin_left = 16
	hud_style.content_margin_top = 12
	hud_style.content_margin_right = 16
	hud_style.content_margin_bottom = 12
	game_hud.add_theme_stylebox_override("panel", hud_style)


func _region_plain_summary(region: Dictionary) -> String:
	var role := str(region.get("region_role", "生态区"))
	if " · " in role:
		role = role.split(" · ")[0]
	var biomes := _localized_biome_line(region.get("dominant_biomes", []))
	return "%s · %s · 关注资源、风险、代表物种。" % [role, biomes]


func _world_next_step_line(active_region: Dictionary) -> String:
	var recommendation := _recommended_region_for_world()
	if recommendation.is_empty():
		return "下一步：点击“开始主线”，进区后跟随黄色目标完成记录/采样，撤离后回灌报告。"
	var region_id := str(recommendation.get("region_id", ""))
	var name := str(recommendation.get("name", region_id))
	var reason := _localized_gameplay_reason(str(recommendation.get("reason", "")))
	var prefix := "主线推荐区：%s" % name
	if region_id == active_region_id:
		prefix = "当前就是主线区：%s" % name
	return "%s。原因：%s。点击“开始主线”会自动进入这个区域。" % [prefix, reason]


func _recommended_region_for_world() -> Dictionary:
	var mainline_region := _mainline_focus_region()
	if not mainline_region.is_empty():
		return mainline_region
	var best := {}
	var best_score := -9999.0
	for region_id_variant in detail_cache.keys():
		var region_id := str(region_id_variant)
		var region: Dictionary = detail_cache.get(region_id, {})
		if region.is_empty():
			continue
		var score := _region_world_priority_score(region)
		if score > best_score:
			best_score = score
			best = {
				"region_id": region_id,
				"name": str(region.get("name", region_id)),
				"score": score,
				"reason": _region_priority_reason(region),
			}
	return best


func _mainline_focus_region() -> Dictionary:
	var gameplay_state: Dictionary = world_data.get("gameplay_state", {})
	var mainline: Dictionary = gameplay_state.get("mainline", {})
	var region_id := str(mainline.get("focus_region_id", ""))
	if region_id == "" or not detail_cache.has(region_id):
		return {}
	var region: Dictionary = detail_cache.get(region_id, {})
	return {
		"region_id": region_id,
		"name": str(mainline.get("focus_region_name", region.get("name", region_id))),
		"score": 9999.0,
		"reason": str(mainline.get("objective", "当前主线推荐区域")),
		"mainline": true,
	}


func _mainline_action_for_region(region_id: String, fallback: String) -> String:
	var gameplay_state: Dictionary = world_data.get("gameplay_state", {})
	var mainline: Dictionary = gameplay_state.get("mainline", {})
	if str(mainline.get("focus_region_id", "")) != region_id:
		return fallback
	var action := str(mainline.get("recommended_action", ""))
	return action if action in ["调查", "修复", "通道"] else fallback


func _region_world_priority_score(region: Dictionary) -> float:
	var gameplay_hint: Dictionary = region.get("gameplay_hint", {})
	var priority := str(gameplay_hint.get("priority", ""))
	var action := str(gameplay_hint.get("action", ""))
	var health: Dictionary = region.get("health_state", {})
	var risk := _max_dictionary_value(region.get("hazard_state", {}))
	var biodiversity := float(health.get("biodiversity", 0.0))
	var resilience := float(health.get("resilience", 0.0))
	var score := risk * 100.0
	score += maxf(0.0, 0.62 - biodiversity) * 70.0
	score += maxf(0.0, 0.62 - resilience) * 70.0
	score += _weakest_frontier_gap(region) * 28.0
	if priority == "high":
		score += 28.0
	elif priority == "medium":
		score += 14.0
	if action == "修复":
		score += 12.0
	elif action == "通道":
		score += 8.0
	return score


func _region_priority_reason(region: Dictionary) -> String:
	var gameplay_hint: Dictionary = region.get("gameplay_hint", {})
	var backend_reason := _localized_gameplay_reason(str(gameplay_hint.get("reason", "")))
	if backend_reason != "":
		return backend_reason
	var risk := _max_dictionary_value(region.get("hazard_state", {}))
	var health: Dictionary = region.get("health_state", {})
	if risk >= 0.55:
		return "最高风险已到 %s，需要先修复" % _percent_text(risk)
	if float(health.get("biodiversity", 0.0)) < 0.60:
		return "多样性低于目标，需要补调查"
	if float(health.get("resilience", 0.0)) < 0.60:
		return "生态韧性低于目标，需要补调查"
	if _weakest_frontier_gap(region) > 0.0:
		return "相邻通道偏弱，需要建立连接"
	return "稳定区，适合继续扩充记录"


func _weakest_frontier_gap(region: Dictionary) -> float:
	var weakest_gap := 0.0
	for link_variant in region.get("frontier_links", []):
		var link: Dictionary = link_variant
		weakest_gap = maxf(weakest_gap, maxf(0.0, 0.80 - float(link.get("strength", 0.0))))
	return weakest_gap


func _localized_biome_line(biomes: Array) -> String:
	var names := PackedStringArray()
	for biome_variant in biomes.slice(0, 3):
		names.append(_localized_biome_name(str(biome_variant)))
	if names.is_empty():
		return "未识别地貌"
	return "、".join(names)


func _localized_biome_name(biome: String) -> String:
	return {
		"temperate_forest": "温带森林",
		"mixed_forest": "混交林",
		"river_valley": "河谷",
		"grassland": "草原",
		"shrubland": "灌丛",
		"seasonal_waterhole": "季节水洼",
		"wetland": "湿地",
		"lake_shore": "湖岸",
		"reed_belt": "芦苇带",
		"tropical_rainforest": "热带雨林",
		"floodplain": "泛洪平原",
		"major_river": "大河",
		"coast": "海岸",
		"estuary": "河口",
		"shallow_sea": "浅海",
		"mangrove": "红树林",
		"coral_reef": "珊瑚礁",
		"seagrass": "海草床",
		"lagoon": "潟湖",
		"open_coast": "外海岸",
	}.get(biome, biome)


func _percent_text(value: float) -> String:
	return "%d%%" % roundi(clampf(value, 0.0, 1.0) * 100.0)


func _max_dictionary_value(values: Dictionary) -> float:
	var max_value := 0.0
	for value_variant in values.values():
		max_value = max(max_value, float(value_variant))
	return max_value


func _world_goal_line() -> String:
	var gameplay_state: Dictionary = world_data.get("gameplay_state", {})
	var mainline: Dictionary = gameplay_state.get("mainline", {})
	if not mainline.is_empty():
		var chapter := str(mainline.get("chapter_title", "主线目标"))
		var focus := str(mainline.get("focus_region_name", "优先区域"))
		var action := str(mainline.get("recommended_action", "调查"))
		var objective := _short_ui_text(str(mainline.get("objective", "")), 48)
		return "主线：%s\n目标：去%s，完成%s线。\n%s" % [chapter, focus, action, objective]
	var world_goal: Dictionary = gameplay_state.get("world_goal", {})
	if not world_goal.is_empty() and world_goal.has("safe_count"):
		var weakest_region: Dictionary = world_goal.get("weakest_region", {})
		var riskiest_region: Dictionary = world_goal.get("riskiest_region", {})
		return "世界状态：安全 %d/%d · 薄弱 %s · 风险 %s %s" % [
			int(world_goal.get("safe_count", 0)),
			int(world_goal.get("total_regions", 0)),
			str(weakest_region.get("name", "未知区域")),
			str(riskiest_region.get("name", "未知区域")),
			_percent_text(float(riskiest_region.get("risk", 0.0))),
		]
	var backend_summary := str(world_goal.get("summary", ""))
	if backend_summary != "":
		if backend_summary.length() > 58:
			backend_summary = backend_summary.substr(0, 58) + "..."
		return "世界目标：" + backend_summary
	var regions: Dictionary = world_data.get("region_details", {})
	if regions.is_empty():
		return "世界目标：等待后端生态区数据。"
	var safe_count := 0
	var weak_count := 0
	var worst_name := "未知区域"
	var worst_risk := -1.0
	var weakest_name := "未知区域"
	var weakest_score := 2.0
	for region_variant in regions.values():
		var region: Dictionary = region_variant
		var health: Dictionary = region.get("health_state", {})
		var biodiversity := float(health.get("biodiversity", 0.0))
		var resilience := float(health.get("resilience", 0.0))
		var risk := _max_dictionary_value(region.get("hazard_state", {}))
		if biodiversity >= 0.60 and resilience >= 0.60 and risk < 0.55:
			safe_count += 1
		else:
			weak_count += 1
		if risk > worst_risk:
			worst_risk = risk
			worst_name = str(region.get("name", region.get("id", "未知区域")))
		var health_score := biodiversity + resilience - risk
		if health_score < weakest_score:
			weakest_score = health_score
			weakest_name = str(region.get("name", region.get("id", "未知区域")))
	return "世界状态：安全 %d/%d · 薄弱 %s · 风险 %s %s" % [
		safe_count,
		regions.size(),
		weakest_name,
		worst_name,
		_percent_text(max(worst_risk, 0.0)),
	]


func _mainline_progress_line() -> String:
	var gameplay_state: Dictionary = world_data.get("gameplay_state", {})
	var mainline: Dictionary = gameplay_state.get("mainline", {})
	if mainline.is_empty():
		return ""
	var progress_label := str(mainline.get("progress_label", ""))
	var next_unlock := str(mainline.get("next_unlock", ""))
	if progress_label == "":
		return ""
	if next_unlock != "":
		return "主线进度：%s · %s" % [progress_label, next_unlock]
	return "主线进度：%s" % progress_label


func _localized_gameplay_reason(text: String) -> String:
	var localized := text
	for hazard_key in [
		"fire_risk",
		"flood_risk",
		"disease_pressure",
		"predation_pressure",
		"drought_risk",
		"pollution_pressure",
		"storm_risk",
		"bleaching_risk",
	]:
		localized = localized.replace(hazard_key, _localized_hazard_name(hazard_key))
	return localized


func _top_dictionary_label(values: Dictionary) -> String:
	var best_key := ""
	var best_value := -1.0
	for key_variant in values.keys():
		var value := float(values.get(key_variant, 0.0))
		if value > best_value:
			best_value = value
			best_key = str(key_variant)
	if best_key == "":
		return "暂无"
	return "%s %s" % [_localized_resource_name(best_key), _percent_text(best_value)]


func _localized_resource_name(key: String) -> String:
	return {
		"freshwater": "淡水",
		"canopy_cover": "冠层",
		"understory": "林下层",
		"flower_pulse": "花期",
		"deadwood": "枯木",
		"surface_water": "地表水",
		"open_water": "开阔水面",
		"reed_cover": "芦苇覆盖",
		"shore_hatch": "岸线孵化",
		"night_insects": "夜行昆虫",
		"grazing_biomass": "可食草量",
		"browse_cover": "灌木食源",
		"open_visibility": "开阔视野",
		"dung_cycle": "粪肥循环",
		"carcass_availability": "腐食资源",
		"fruit_pulse": "果实期",
		"river_nutrients": "河流营养",
		"floodplain_productivity": "泛洪生产力",
		"benthic_food": "底栖食物",
		"nesting_cover": "筑巢掩护",
		"seagrass_cover": "海草覆盖",
		"tidal_exchange": "潮汐交换",
		"nursery_habitat": "育幼地",
		"shellfish_beds": "贝类床",
		"salinity_gradient": "盐度梯度",
		"reef_complexity": "礁体复杂度",
		"clear_water": "清澈水体",
		"plankton_pulse": "浮游生物",
		"cleaning_network": "清洁共生网",
		"grazing_pressure_balance": "啃食平衡",
	}.get(key, key)


func _top_species_line(region: Dictionary) -> String:
	var species: Array = region.get("top_species", [])
	var names := PackedStringArray()
	for species_variant in species.slice(0, 4):
		var item: Dictionary = species_variant
		names.append(str(item.get("label", "未知")))
	if names.is_empty():
		return "暂无记录"
	return "、".join(names)


func _latest_expedition_report_pending() -> bool:
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	if latest_report.is_empty():
		return false
	var region_id := str(latest_report.get("region_id", ""))
	if region_id == "":
		return false
	var applied_reports: Dictionary = world_data.get("expedition_reports", {})
	var applied_last: Dictionary = applied_reports.get("last", {})
	var report_id := str(latest_report.get("report_id", ""))
	if report_id != "" and str(applied_last.get("report_id", "")) == report_id:
		return false
	if str(applied_last.get("summary", "")) == str(latest_report.get("summary", "")):
		return false
	var region: Dictionary = detail_cache.get(region_id, {})
	var applied_region_report: Dictionary = region.get("expedition_report", {})
	if report_id != "" and str(applied_region_report.get("report_id", "")) == report_id:
		return false
	if str(applied_region_report.get("summary", "")) == str(latest_report.get("summary", "")):
		return false
	return true


func _pending_expedition_report_line() -> String:
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	return "撤离报告待回灌：%s。点击“回灌报告”，后端会把本轮情报写回生态系统。" % str(latest_report.get("summary", "刚完成一轮区域探索"))


func _pending_expedition_report_summary() -> String:
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	var region_name := str(latest_report.get("region_name", "刚探索的区域"))
	var summary := str(latest_report.get("summary", "已完成一轮区域探索"))
	var task_state := "世界任务完成" if bool(latest_report.get("world_task_completed", false)) else "世界任务未完成"
	return "撤离报告待回灌：%s。%s · %s。" % [region_name, summary, task_state]


func _pending_expedition_report_effect_line() -> String:
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	var action := str(latest_report.get("world_task_action", "调查"))
	match action:
		"修复":
			return "预计影响：压低该区域最高风险，并提高生态韧性。"
		"通道":
			return "预计影响：强化本区与目标区通道，让物种流动更稳定。"
		_:
			return "预计影响：提高调查覆盖，补强后端对资源和物种链的判断。"


func _pending_expedition_report_objective_line() -> String:
	var latest_report: Dictionary = expedition_reports.get("_last", {})
	var action := str(latest_report.get("world_task_action", "调查"))
	var intel := int(latest_report.get("intel", latest_report.get("cumulative_intel", 0)))
	var species_intel := int(latest_report.get("species_intel", 0))
	var hotspot_intel := int(latest_report.get("hotspot_intel", 0))
	var archive_tier := str(latest_report.get("archive_tier", "初勘档案"))
	var top_channel := str(latest_report.get("top_intel_channel", "未分类"))
	var task_state := "已完成" if bool(latest_report.get("world_task_completed", false)) else "未完成"
	var target_region_id := str(latest_report.get("target_region_id", latest_report.get("world_task_target_region_id", "")))
	var target_name := "无目标区"
	if target_region_id != "" and detail_cache.has(target_region_id):
		var target_detail: Dictionary = detail_cache.get(target_region_id, {})
		target_name = str(target_detail.get("name", target_region_id))
	var action_line := "本轮成果：%s线%s · 情报 %d（动物 %d / 热点 %d）· 主方向 %s · 档案 %s" % [
		action,
		task_state,
		intel,
		species_intel,
		hotspot_intel,
		top_channel,
		archive_tier,
	]
	if action == "通道":
		action_line += " · 目标连接：%s" % target_name
	return "%s\n下一步：只做一件事，点击“回灌报告”。不要先开始下一轮，否则报告不会写回后端生态系统。" % action_line


func _latest_applied_expedition_feedback() -> String:
	var reports: Dictionary = world_data.get("expedition_reports", {})
	var last_report: Dictionary = reports.get("last", {})
	var applied_reports: Dictionary = reports.get("applied", {})
	var region_id := str(last_report.get("region_id", ""))
	var applied: Dictionary = applied_reports.get(region_id, {})
	if applied.is_empty() and detail_cache.has(region_id):
		var region: Dictionary = detail_cache.get(region_id, {})
		applied = region.get("expedition_report", {})
	if applied.is_empty():
		return "回灌完成：撤离报告已写回后端生态系统，现在可以选择下一条主线。"
	var action := str(applied.get("world_task_action", last_report.get("world_task_action", "调查")))
	var task_state := "完成" if bool(applied.get("world_task_completed", false)) else "未完成"
	var region_name := str(applied.get("region_name", last_report.get("region_name", "刚探索的区域")))
	var intel := int(applied.get("intel", last_report.get("intel", 0)))
	var archive_tier := str(applied.get("archive_tier", last_report.get("archive_tier", "初勘档案")))
	var channel := str(applied.get("top_intel_channel", last_report.get("top_intel_channel", "未分类")))
	return "回灌完成：%s · %s线%s · 情报 %d · %s · 主方向 %s。%s" % [
		region_name,
		action,
		task_state,
		intel,
		archive_tier,
		channel,
		_applied_expedition_effect_text(action, applied),
	] + " " + _mainline_transition_feedback(last_report)


func _mainline_transition_feedback(last_report: Dictionary) -> String:
	var gameplay_state: Dictionary = world_data.get("gameplay_state", {})
	var mainline: Dictionary = gameplay_state.get("mainline", {})
	if mainline.is_empty():
		return ""
	var previous_chapter := str(last_report.get("mainline_chapter", ""))
	var current_chapter := str(mainline.get("chapter_title", ""))
	var current_objective := str(mainline.get("objective", ""))
	if previous_chapter != "" and current_chapter != "" and previous_chapter != current_chapter:
		return "主线推进：%s -> %s。下一轮：%s" % [
			previous_chapter,
			current_chapter,
			_short_ui_text(current_objective, 44),
		]
	var progress_label := str(mainline.get("progress_label", ""))
	var next_unlock := str(mainline.get("next_unlock", ""))
	if progress_label != "":
		return "主线进度：%s。%s" % [progress_label, _short_ui_text(next_unlock, 44)]
	return ""


func _applied_expedition_effect_text(action: String, applied: Dictionary) -> String:
	match action:
		"修复":
			var hazard_key := str(applied.get("hazard_key", ""))
			if bool(applied.get("world_task_completed", false)):
				return "风险项 %s 已被压低，生态韧性获得提升。" % (hazard_key if hazard_key != "" else "最高风险")
			return "报告已入库，但修复条件未完成，风险改善较弱。"
		"通道":
			var target_region_id := str(applied.get("target_region_id", ""))
			var target_name := target_region_id
			if target_region_id != "" and detail_cache.has(target_region_id):
				var target_detail: Dictionary = detail_cache.get(target_region_id, {})
				target_name = str(target_detail.get("name", target_region_id))
			if bool(applied.get("corridor_strengthened", false)):
				return "通往 %s 的区域连接已增强，物种流动更稳定。" % target_name
			return "通道目标 %s 已记录，但这轮未达到强化条件。" % (target_name if target_name != "" else "目标区域")
		_:
			var resource_key := str(applied.get("resource_key", ""))
			if resource_key != "":
				return "调查覆盖已提高，并补强资源判断：%s。" % resource_key
			return "调查覆盖已提高，后端会用这份报告更新生态链判断。"


func _recommended_action_line(region: Dictionary, frontier_links: Array) -> String:
	var gameplay_hint: Dictionary = region.get("gameplay_hint", {})
	var backend_action := str(gameplay_hint.get("action", ""))
	var backend_reason := str(gameplay_hint.get("reason", ""))
	if backend_action != "" and backend_reason != "":
		return "%s · %s" % [backend_action, _short_ui_text(backend_reason, 28)]
	var hazard := _top_hazard(region.get("hazard_state", {}))
	var health: Dictionary = region.get("health_state", {})
	var biodiversity := float(health.get("biodiversity", 0.0))
	var resilience := float(health.get("resilience", 0.0))
	if float(hazard.get("value", 0.0)) >= 0.55:
		return "修复 · 压低%s %s" % [
			_localized_hazard_name(str(hazard.get("key", "风险"))),
			_percent_text(float(hazard.get("value", 0.0))),
		]
	if biodiversity < 0.60 or resilience < 0.60:
		return "调查 · 补齐薄弱生态链"
	if not frontier_links.is_empty():
		var link: Dictionary = frontier_links[0]
		if float(link.get("strength", 0.0)) < 0.80:
			return "通道 · 连到%s" % [
				str(link.get("target_name", "相邻区域")),
			]
	return "调查 · 扩充物种与热点记录"


func _recommended_game_action(region: Dictionary) -> String:
	if region.is_empty():
		return "调查"
	var gameplay_hint: Dictionary = region.get("gameplay_hint", {})
	var backend_action := str(gameplay_hint.get("action", ""))
	if backend_action in ["调查", "修复", "通道"]:
		return backend_action
	var frontier_links: Array = region.get("frontier_links", [])
	var hazard := _top_hazard(region.get("hazard_state", {}))
	var health: Dictionary = region.get("health_state", {})
	if float(hazard.get("value", 0.0)) >= 0.55:
		return "修复"
	if float(health.get("biodiversity", 0.0)) < 0.60 or float(health.get("resilience", 0.0)) < 0.60:
		return "调查"
	if not frontier_links.is_empty():
		var link: Dictionary = frontier_links[0]
		if float(link.get("strength", 0.0)) < 0.80:
			return "通道"
	return "调查"


func _top_hazard(values: Dictionary) -> Dictionary:
	var best_key := ""
	var best_value := 0.0
	for key_variant in values.keys():
		var value := float(values.get(key_variant, 0.0))
		if value > best_value:
			best_value = value
			best_key = str(key_variant)
	return {"key": best_key, "value": best_value}


func _localized_hazard_name(key: String) -> String:
	return {
		"fire_risk": "火灾风险",
		"flood_risk": "洪水风险",
		"disease_pressure": "疾病压力",
		"predation_pressure": "捕食压力",
		"drought_risk": "干旱风险",
		"pollution_pressure": "污染压力",
		"storm_risk": "风暴风险",
		"bleaching_risk": "白化风险",
	}.get(key, key)


func _game_objective_line(region: Dictionary, frontier_links: Array) -> String:
	var hazards: Dictionary = region.get("hazard_state", {})
	var risk := _max_dictionary_value(hazards)
	if risk >= 0.55:
		return "压低最高风险，再扩大物种循环。"
	if frontier_links.size() > 0:
		var link: Dictionary = frontier_links[0]
		return "保持通往%s的连接通畅。" % [
			str(link.get("target_name", "相邻区域")),
		]
	return "稳定资源和代表物种。"


func _short_ui_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length) + "..."


func _game_action_hint(action_name: String, region: Dictionary, frontier_links: Array) -> String:
	match action_name:
		"修复":
			return "修复线：进区后采样风险热点，撤离回灌后降低风险并提高韧性。关键资源：%s。" % _top_dictionary_label(region.get("resource_state", {}))
		"通道":
			if frontier_links.is_empty():
				return "通道线：当前没有已知相邻区，先走调查线解锁连接。"
			var link: Dictionary = frontier_links[0]
			return "通道线：进区后前往目标出口，把本区连到%s；当前%s强度 %s。" % [
				str(link.get("target_name", "相邻区域")),
				str(link.get("connection_label", "生态通道")),
				_percent_text(float(link.get("strength", 0.0))),
			]
		_:
			return "调查线：进区后记录动物、采样热点，撤离回灌后更新后端生态链判断。"


func _world_mainline_plan_line(region: Dictionary, frontier_links: Array) -> String:
	return "主线：%s · %s" % [
		_world_mainline_title(selected_game_action),
		_world_mainline_enter_line(selected_game_action, region, frontier_links),
	]


func _world_mainline_title(action_name: String) -> String:
	match action_name:
		"修复":
			return "修复生态风险"
		"通道":
			return "连接下一片区域"
		_:
			return "完成生态调查"


func _world_mainline_enter_line(action_name: String, region: Dictionary, frontier_links: Array) -> String:
	match action_name:
		"修复":
			return "本轮玩法：修复线。进区后跟黄色目标到风险热点，按住 Space 采样；情报够了去出口按 E 撤离。"
		"通道":
			if frontier_links.is_empty():
				return "本轮玩法：通道线。当前区没有已知相邻通道，先记录动物和热点，撤离回灌来解锁连接。"
			var link: Dictionary = frontier_links[0]
			return "本轮玩法：通道线。进区后跟黄色目标去通往%s的出口，到达后按 E 撤离。" % str(link.get("target_name", "下一片区域"))
		_:
			return "本轮玩法：调查线。进区后跟黄色目标记录 1 种动物、采样 1 个热点；情报够了去出口按 E 撤离。"


func _world_mainline_controls_line(action_name: String, region: Dictionary, frontier_links: Array) -> String:
	return "怎么玩：1. 点“开始主线”  2. WASD 移动  3. 按住 Space 记录/采样  4. 出口按 E 撤离  5. 回世界图点“回灌报告”。"


func _sync_action_button_state() -> void:
	var report_pending := _latest_expedition_report_pending()
	for action_name in action_buttons.keys():
		var button: Button = action_buttons[action_name]
		var is_selected := str(action_name) == selected_game_action
		button.visible = false
		button.button_pressed = is_selected
		button.disabled = report_pending
		button.text = {
			"调查": "调查线\n记录",
			"修复": "修复线\n采样",
			"通道": "通道线\n撤离",
		}.get(str(action_name), str(action_name))
		if is_selected:
			button.text = "✓ " + button.text
		button.tooltip_text = "先回灌上一轮撤离报告，再选择新行动。" if report_pending else "选择%s作为本轮主线。" % _world_mainline_title(str(action_name))


func _sync_primary_button_state(active_region: Dictionary) -> void:
	var report_pending := _latest_expedition_report_pending()
	var strategy_pending := _strategy_intent_pending()
	var recommendation := _recommended_region_for_world()
	var recommended_region_id := str(recommendation.get("region_id", ""))
	if focus_recommended_button != null:
		focus_recommended_button.visible = not report_pending and recommended_region_id != "" and recommended_region_id != active_region_id
		focus_recommended_button.text = "查看主线区"
		focus_recommended_button.disabled = report_pending
		focus_recommended_button.tooltip_text = "先回灌上一轮撤离报告，再切换建议区。" if report_pending else "切到当前全局优先区域。"
	if apply_turn_button != null:
		apply_turn_button.visible = report_pending or strategy_pending
		apply_turn_button.text = "回灌报告" if report_pending else "推进模拟"
		apply_turn_button.disabled = not report_pending and not strategy_pending
		if report_pending:
			apply_turn_button.tooltip_text = "把刚才撤离得到的报告写回后端生态系统。"
		elif strategy_pending:
			apply_turn_button.tooltip_text = "把刚选择的世界行动提交给后端模拟。"
		else:
			apply_turn_button.tooltip_text = "先选择一条主线；主要玩法请点击“开始主线”。"
	if enter_region_button != null:
		var region_name := str(recommendation.get("name", active_region.get("name", "区域")))
		if region_name.length() > 6:
			region_name = region_name.substr(0, 6)
		enter_region_button.text = "开始主线：%s" % region_name
		enter_region_button.disabled = report_pending
		enter_region_button.tooltip_text = "先点击“回灌报告”，把上一轮撤离结果写回后端。" if report_pending else "进入%s，执行%s。" % [region_name, _world_mainline_title(selected_game_action)]


func _strategy_intent_pending() -> bool:
	return FileAccess.file_exists(STRATEGY_PATH) or FileAccess.file_exists(PROJECT_STRATEGY_PATH)


func _on_game_action_pressed(action_name: String) -> void:
	if _latest_expedition_report_pending():
		pending_strategy_message = "先点击“回灌报告”，把上一轮撤离结果写回后端，再选择新行动。"
		_refresh_game_hud()
		return
	selected_game_action = action_name
	_write_strategy_intent(action_name)
	_refresh_game_hud()


func _on_focus_recommended_region_pressed() -> void:
	if _latest_expedition_report_pending():
		pending_strategy_message = "先点击“回灌报告”，把上一轮撤离结果写回后端，再切换建议区域。"
		_refresh_game_hud()
		return
	var recommendation := _recommended_region_for_world()
	var region_id := str(recommendation.get("region_id", ""))
	if region_id == "" or not detail_cache.has(region_id):
		pending_strategy_message = "当前没有可推荐的优先区域。"
		_refresh_game_hud()
		return
	active_region_id = region_id
	selected_game_action = _recommended_game_action(detail_cache.get(active_region_id, world_data.get("active_region", {})))
	selected_game_action = _mainline_action_for_region(active_region_id, selected_game_action)
	selected_campaign_stage_index = 0
	selected_campaign_landing_target_id = ""
	selected_schedule_route_key = "primary_route"
	selected_formation_key = "assault"
	selected_activation_preset_key = "assault"
	selected_directive_key = "assault"
	selected_decision_key = "assault"
	selected_confirmation_key = "assault"
	selected_frontier_target_id = ""
	pending_strategy_message = "已切到建议优先区：%s。建议行动：%s。" % [
		str(recommendation.get("name", region_id)),
		selected_game_action,
	]
	_render_world()
	_animate_region_transition(_active_region_accent())


func _on_apply_turn_pressed() -> void:
	pending_strategy_message = "正在调用后端生态系统，应用本回合策略..."
	_refresh_game_hud()
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var command := "cd %s && PYTHONPATH=. python3 scripts/export_world_state.py --pretty" % _shell_quote(repo_root)
	var output: Array = []
	var exit_code := OS.execute("/bin/zsh", PackedStringArray(["-lc", command]), output, true, false)
	if exit_code == 0:
		var had_pending_report := _latest_expedition_report_pending()
		_clear_strategy_intent_files()
		_load_world_data()
		pending_strategy_message = _latest_applied_expedition_feedback() if had_pending_report else "策略已写入世界状态，现在可以点击“开始主线”进入区域执行。"
		_refresh_game_hud()
	else:
		pending_strategy_message = "后端应用失败：%s" % _short_command_output(output)
		_refresh_game_hud()


func _clear_strategy_intent_files() -> void:
	for path in [STRATEGY_PATH, PROJECT_STRATEGY_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _on_enter_region_pressed() -> void:
	if _latest_expedition_report_pending():
		pending_strategy_message = "先点击“回灌报告”，把上一轮撤离结果写回后端，再进入下一片区域。"
		_refresh_game_hud()
		return
	var recommendation := _recommended_region_for_world()
	var recommended_region_id := str(recommendation.get("region_id", ""))
	if recommended_region_id != "" and detail_cache.has(recommended_region_id):
		active_region_id = recommended_region_id
		selected_game_action = _recommended_game_action(detail_cache.get(active_region_id, world_data.get("active_region", {})))
		selected_game_action = _mainline_action_for_region(active_region_id, selected_game_action)
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	if active_region.is_empty():
		pending_strategy_message = "当前没有可进入的生态区。"
		_refresh_game_hud()
		return
	var request := _build_expedition_region_request(active_region)
	get_tree().set_meta("selected_expedition_region", request)
	_write_expedition_region_request(request)
	get_tree().change_scene_to_file(EXPLORER_SCENE)


func _build_expedition_region_request(active_region: Dictionary) -> Dictionary:
	var hint: Dictionary = active_region.get("gameplay_hint", {}).duplicate(true)
	hint["action"] = selected_game_action
	var gameplay_state: Dictionary = world_data.get("gameplay_state", {})
	var mainline: Dictionary = gameplay_state.get("mainline", {})
	if _mainline_applies_to_region(active_region_id, mainline):
		hint["action"] = selected_game_action
		hint["action_key"] = _strategy_action_key(selected_game_action)
		hint["reason"] = str(mainline.get("objective", _game_action_hint(selected_game_action, active_region, active_region.get("frontier_links", []))))
		hint["mainline_chapter"] = str(mainline.get("chapter_title", ""))
		hint["mainline_objective"] = str(mainline.get("objective", ""))
		if str(mainline.get("target_region_id", "")) != "":
			hint["target_region_id"] = str(mainline.get("target_region_id", ""))
			hint["target_region_name"] = str(mainline.get("target_region_name", ""))
	elif not hint.has("reason") or str(hint.get("reason", "")) == "":
		hint["reason"] = _game_action_hint(selected_game_action, active_region, active_region.get("frontier_links", []))
	return {
		"schema_version": 1,
		"created_at": Time.get_datetime_string_from_system(),
		"region_id": active_region_id,
		"region_name": str(active_region.get("name", active_region_id)),
		"recommended_action": selected_game_action,
		"gameplay_hint": hint,
	}


func _mainline_applies_to_region(region_id: String, mainline: Dictionary) -> bool:
	return not mainline.is_empty() and str(mainline.get("focus_region_id", "")) == region_id


func _write_expedition_region_request(payload: Dictionary) -> void:
	var payload_text := JSON.stringify(payload, "\t", false)
	var file := FileAccess.open(EXPEDITION_REGION_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(payload_text)
	var project_file := FileAccess.open(PROJECT_EXPEDITION_REGION_PATH, FileAccess.WRITE)
	if project_file != null:
		project_file.store_string(payload_text)


func _shell_quote(value: String) -> String:
	return "'" + value.replace("'", "'\"'\"'") + "'"


func _short_command_output(output: Array) -> String:
	var lines := PackedStringArray()
	for item in output:
		lines.append(str(item))
	var text := "\n".join(lines).strip_edges()
	if text == "":
		return "没有返回错误信息。"
	if text.length() > 160:
		return text.substr(0, 160) + "..."
	return text


func _write_strategy_intent(action_name: String) -> void:
	var active_region: Dictionary = detail_cache.get(active_region_id, world_data.get("active_region", {}))
	if active_region.is_empty():
		return
	var frontier_links: Array = active_region.get("frontier_links", [])
	var primary_link: Dictionary = {}
	if not frontier_links.is_empty():
		primary_link = frontier_links[0]
	var payload := {
		"schema_version": 1,
		"created_at": Time.get_datetime_string_from_system(),
		"region_id": active_region_id,
		"region_name": str(active_region.get("name", active_region_id)),
		"action": action_name,
		"action_key": _strategy_action_key(action_name),
		"target_region_id": str(primary_link.get("target_region_id", "")),
		"target_region_name": str(primary_link.get("target_name", "")),
		"connection_type": str(primary_link.get("connection_type", "")),
		"connection_strength": float(primary_link.get("strength", 0.0)),
		"health": active_region.get("health_state", {}),
		"resources": active_region.get("resource_state", {}),
		"hazards": active_region.get("hazard_state", {}),
	}
	var file := FileAccess.open(STRATEGY_PATH, FileAccess.WRITE)
	var payload_text := JSON.stringify(payload, "\t", false)
	if file != null:
		file.store_string(payload_text)
	var project_file := FileAccess.open(PROJECT_STRATEGY_PATH, FileAccess.WRITE)
	if project_file != null:
		project_file.store_string(payload_text)
	pending_strategy_message = "已选择本轮行动：%s。可以直接进入区域执行；如果只想推进后端模拟，点击“应用回合”。" % action_name
	if project_file == null:
		pending_strategy_message = "策略只写入了本地用户目录，项目策略文件写入失败；后端可能读不到。"
	status_label.text = "系统栏 · 已写入策略意图：%s · %s" % [str(active_region.get("name", active_region_id)), action_name]


func _strategy_action_key(action_name: String) -> String:
	return {
		"调查": "survey",
		"修复": "restore",
		"通道": "corridor",
	}.get(action_name, "survey")


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
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)

	var prosperity := float(active_region.get("health_state", {}).get("prosperity", 0.0))
	var stability := float(active_region.get("health_state", {}).get("stability", 0.0))
	var collapse_risk := float(active_region.get("health_state", {}).get("collapse_risk", 0.0))
	var report := _region_report(str(active_region.get("id", active_region_id)))

	root.add_child(_make_section_label("生态层"))

	var ecology_row := HBoxContainer.new()
	ecology_row.add_theme_constant_override("separation", 10)
	root.add_child(ecology_row)

	ecology_row.add_child(_make_status_chip("繁荣", "◎", "%.2f" % prosperity, prosperity, region_accent))
	ecology_row.add_child(_make_status_chip("稳定", "▲", "%.2f" % stability, stability, region_accent))
	ecology_row.add_child(_make_status_chip("风险", "◆", "%.2f" % collapse_risk, collapse_risk, region_accent))
	if not report.is_empty():
		var management_accent := _region_management_chip_color(report)
		var backbone_accent := _region_backbone_chip_color(report)
		var consolidation_accent := _region_consolidation_chip_color(report)
		ecology_row.add_child(_make_status_chip("窗口", "◌", str(report.get("event_window_title", _region_event_window_tag(active_region))), 0.62, region_accent))

		root.add_child(_make_section_label("进展层"))

		var progress_row := HBoxContainer.new()
		progress_row.add_theme_constant_override("separation", 10)
		root.add_child(progress_row)
		progress_row.add_child(_make_status_chip("回执", "✦", "%s / %s" % [str(report.get("top_intel_channel", "未分类")), str(report.get("intel", 0))], clamp(float(report.get("intel", 0)) / 10.0, 0.0, 1.0), region_accent))
		progress_row.add_child(_make_status_chip("回线", "↺", "风险 %.2f" % float(report.get("risk", 0.0)), clamp(1.0 - float(report.get("risk", 0.0)), 0.0, 1.0), region_accent))
		progress_row.add_child(_make_status_chip("档案", "▤", "%s / %d" % [_region_archive_tier(report), _region_archive_progress(report)], _region_archive_ratio(report), region_accent))
		progress_row.add_child(_make_status_chip("专精", "⇢", _region_specialization_tag(report), 0.68, region_accent))
		progress_row.add_child(_make_status_chip("跑法", "▣", _region_specialization_run_tag(report), 0.68, region_accent))
		progress_row.add_child(_make_status_chip("惯性", "◎", _region_run_profile_tag(report), 0.66, region_accent))

		root.add_child(_make_section_label("经营层"))

		var management_row := HBoxContainer.new()
		management_row.add_theme_constant_override("separation", 10)
		root.add_child(management_row)
		management_row.add_child(_make_status_chip("经营", "▦", _region_management_short_display(report), 0.78 if _region_management_display(report) != "常规经营区" else 0.34, management_accent))
		management_row.add_child(_make_status_chip("骨干", "⬢", _region_backbone_short_display(report), 0.80 if _region_management_backbone_tag(report) != "" else 0.24, backbone_accent))
		management_row.add_child(_make_status_chip("巩固", "⟲", _region_consolidation_short_display(report), _region_consolidation_ratio(report), consolidation_accent))
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

	var report := _region_report(str(active_region.get("id", active_region_id)))
	if not report.is_empty():
		var report_line := Label.new()
		report_line.text = "%s · 最近回线 %s / 情报 %s / 风险 %.2f" % [
			_region_focus_brief(report),
			str(report.get("top_intel_channel", "未分类")),
			str(report.get("intel", 0)),
			float(report.get("risk", 0.0)),
		]
		_style_dim(report_line, 10)
		text_col.add_child(report_line)

	root.add_child(_make_status_strip(active_region, region_accent))

	root.add_child(_make_section_label("生态层"))

	var ecology_badge_row := HBoxContainer.new()
	ecology_badge_row.add_theme_constant_override("separation", 4)
	root.add_child(ecology_badge_row)
	ecology_badge_row.add_child(_make_hero_chip("地貌", " / ".join(active_region.get("dominant_biomes", []).slice(0, 2)), region_accent))
	ecology_badge_row.add_child(_make_hero_chip("通道", str(active_region.get("connector_count", active_region.get("connectors", []).size())), Color8(102, 152, 204)))
	if not report.is_empty():
		ecology_badge_row.add_child(_make_hero_chip("已知标签", _region_focus_brief(report), Color8(104, 171, 144)))

	root.add_child(_make_section_label("进展层"))

	var progress_badge_row := HBoxContainer.new()
	progress_badge_row.add_theme_constant_override("separation", 4)
	root.add_child(progress_badge_row)
	progress_badge_row.add_child(_make_hero_chip("最近回执", _region_report_summary(str(active_region.get("id", active_region_id))), Color8(210, 182, 96)))
	if not report.is_empty():
		progress_badge_row.add_child(_make_hero_chip("档案成长", "%s · 进度 %d" % [_region_archive_tier(report), _region_archive_progress(report)], Color8(102, 152, 204)))

	if not report.is_empty():
		var management_accent := _region_management_chip_color(report)
		var backbone_accent := _region_backbone_chip_color(report)
		var consolidation_accent := _region_consolidation_chip_color(report)
		root.add_child(_make_section_label("经营层"))

		var management_badge_row := HBoxContainer.new()
		management_badge_row.add_theme_constant_override("separation", 4)
		root.add_child(management_badge_row)
		management_badge_row.add_child(_make_hero_chip("经营层级", _region_management_display(report), management_accent))
		management_badge_row.add_child(_make_hero_chip("骨干状态", _region_backbone_display(report), backbone_accent))
		management_badge_row.add_child(_make_hero_chip("巩固状态", _region_consolidation_display(report), consolidation_accent))

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


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_style_dim(label, 10)
	return label


func _make_compact_hero_chip(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)

	var label := Label.new()
	label.text = label_text
	_style_dim(label, 9)
	box.add_child(label)

	var value := Label.new()
	value.text = value_text
	_style_secondary_title(value, 10)
	value.modulate = accent.lightened(0.08)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value)
	return panel


func _make_compact_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_style_dim(label, 9)
	return label


func _make_candidate_header_card(title_text: String, meta_text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)

	var title := Label.new()
	title.text = title_text
	_style_primary_title(title, 15)
	title.modulate = accent.lightened(0.26)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)

	var meta := Label.new()
	meta.text = meta_text
	_style_dim(meta, 9)
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(meta)
	return panel


func _make_state_badge(text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.42)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	_style_dim(label, 9)
	label.modulate = accent.lightened(0.18)
	panel.add_child(label)
	return panel


func _candidate_state_accent(is_locked: bool, is_preferred: bool, default_accent: Color) -> Color:
	if is_locked:
		return default_accent
	if is_preferred:
		return Color8(224, 186, 92)
	return default_accent


func _make_candidate_shell(is_locked: bool, is_preferred: bool, accent: Color) -> PanelContainer:
	var shell := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if is_locked:
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
		style.set_border_width_all(2)
	elif is_preferred:
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
		style.set_border_width_all(2)
	else:
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.05)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.26)
		style.set_border_width_all(1)
	shell.add_theme_stylebox_override("panel", style)
	return shell


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
	var report := _region_report(str(active_region.get("id", active_region_id)))

	box.add_child(_make_menu_entry_card(
		"当前区域",
		str(active_region.get("name", "未选择")),
		"%s · %s" % [
			str(summary.get("one_liner", active_region.get("region_role", "生态观测区"))),
			_region_known_tag(report),
		],
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
		"%s · %s · %s" % [
			str(active_stage.get("stage", "阶段待命")),
			_route_identity_text(active_region),
			_region_specialization_tag(report),
		],
		Color8(171, 132, 196),
		"✦"
	))

	if not report.is_empty():
		box.add_child(_make_menu_entry_card(
			"最近回执",
			"%s · 情报 %s" % [
				str(report.get("top_intel_channel", "未分类")),
				str(report.get("intel", 0)),
			],
			"风险 %.2f · %s" % [
				float(report.get("risk", 0.0)),
				str(report.get("summary", "暂无回执摘要")),
			],
			Color8(210, 182, 96),
			"回"
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
	var rotation_plan := _campaign_management_rotation_plan(candidates)
	var preferred_rotation_target_id := _preferred_rotation_candidate_id(candidates)

	var title := Label.new()
	title.text = "%s · 落点网络总板" % _region_type_chip(active_region)
	_style_primary_title(title, 22)
	box.add_child(title)

	box.add_child(_make_section_label("筛选层"))

	var filter_chip_row := HBoxContainer.new()
	filter_chip_row.add_theme_constant_override("separation", 8)
	box.add_child(filter_chip_row)
	filter_chip_row.add_child(_make_hero_chip("当前筛选", _campaign_filter_label(), region_accent))
	filter_chip_row.add_child(_make_hero_chip("排序依据", "评分从高到低", Color8(102, 152, 204)))

	var report := _region_report(str(active_region.get("id", active_region_id)))
	if not report.is_empty():
		box.add_child(_make_section_label("进展层"))

		var progress_chip_row := HBoxContainer.new()
		progress_chip_row.add_theme_constant_override("separation", 8)
		box.add_child(progress_chip_row)

		var management_accent := _region_management_chip_color(report)
		var backbone_accent := _region_backbone_chip_color(report)
		var consolidation_accent := _region_consolidation_chip_color(report)
		progress_chip_row.add_child(_make_hero_chip("默认路线", _region_archive_route_tag(report), Color8(210, 182, 96)))

		box.add_child(_make_section_label("经营层"))

		var management_chip_row := HBoxContainer.new()
		management_chip_row.add_theme_constant_override("separation", 8)
		box.add_child(management_chip_row)
		management_chip_row.add_child(_make_hero_chip("经营建议", _management_rotation_tag_from_management(_region_management_priority_tag(report)), management_accent))
		management_chip_row.add_child(_make_hero_chip("经营层级", _region_management_short_display(report), management_accent))
		management_chip_row.add_child(_make_hero_chip("骨干状态", _region_backbone_short_display(report), backbone_accent))
		management_chip_row.add_child(_make_hero_chip("巩固状态", _region_consolidation_short_display(report), consolidation_accent))
	if not rotation_plan.is_empty():
		var rotation_row := HBoxContainer.new()
		rotation_row.add_theme_constant_override("separation", 8)
		box.add_child(rotation_row)
		rotation_row.add_child(_make_hero_chip("经营轮换", str(rotation_plan.get("tag", "常规经营")), Color8(104, 171, 144)))

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
			"%s · %.2f · %s" % [str(best_candidate.get("name", "")), float(best_candidate.get("score", 0.0)), str(best_candidate.get("run_profile_tag", "基础观察"))],
			region_accent
		))
		summary_row.add_child(_make_hero_chip(
			"当前落点",
			"%s · %s" % [str(active_landing.get("name", active_stage.get("title", "等待落点"))), str(active_landing.get("run_profile_tag", "基础观察"))],
			Color8(102, 152, 204)
		))
		summary_row.add_child(_make_hero_chip(
			"高风险分支",
			"%s · %.2f" % [str(riskiest_candidate.get("name", "")), float(riskiest_candidate.get("risk", 0.0))],
			Color8(171, 132, 196)
		))
		summary_row.add_child(_make_hero_chip(
			"经营顺序",
			str(rotation_plan.get("summary", "当前按总态推进")),
			Color8(104, 171, 144)
		))
		if preferred_rotation_target_id != "":
			var preferred_name := str((candidates[0] as Dictionary).get("name", preferred_rotation_target_id))
			for candidate_variant in candidates:
				var candidate: Dictionary = candidate_variant
				if str(candidate.get("target_region_id", "")) == preferred_rotation_target_id:
					preferred_name = str(candidate.get("name", preferred_rotation_target_id))
					break
			summary_row.add_child(_make_hero_chip(
				"下一段默认落点",
				preferred_name,
				Color8(210, 182, 96)
			))

	for landing_variant in candidates:
		var landing: Dictionary = landing_variant
		var landing_id := str(landing.get("target_region_id", ""))
		var is_stage := landing_id == str(active_stage.get("target_region_id", ""))
		var is_locked := landing_id == selected_campaign_landing_target_id
		var is_preferred := landing_id == preferred_rotation_target_id and preferred_rotation_target_id != ""
		var candidate_accent := _candidate_state_accent(is_locked, is_preferred, Color8(171, 132, 196))
		var landing_shell := _make_candidate_shell(is_locked, is_preferred, region_accent if is_locked else candidate_accent)
		var landing_card := VBoxContainer.new()
		landing_card.add_theme_constant_override("separation", 6 if is_preferred else 4)
		landing_shell.add_child(landing_card)

		var state_ribbon := ColorRect.new()
		state_ribbon.color = (region_accent if is_locked else candidate_accent).lightened(0.08)
		state_ribbon.custom_minimum_size = Vector2(0, 6 if is_preferred else 4)
		landing_card.add_child(state_ribbon)
		landing_card.add_child(_make_compact_section_label("生态层"))
		var state_badge_row := HBoxContainer.new()
		state_badge_row.add_theme_constant_override("separation", 6)
		landing_card.add_child(state_badge_row)
		if is_preferred and not is_locked:
			state_badge_row.add_child(_make_state_badge("默认", Color8(224, 186, 92)))
		if is_locked:
			state_badge_row.add_child(_make_state_badge("已锁定", region_accent))
		if is_stage and not is_locked:
			state_badge_row.add_child(_make_state_badge(str(landing.get("stage_label", "落点")), Color8(102, 152, 204)))
		var ecology_row := HBoxContainer.new()
		ecology_row.add_theme_constant_override("separation", 6)
		landing_card.add_child(ecology_row)
		var header_card := _make_candidate_header_card(
			str(landing.get("name", landing_id)),
			"%s%s%s%s · 评分 %.2f · 繁荣 %.2f · 风险 %.2f" % [
				"默认落点 · " if is_preferred and not is_locked else "",
				"锁定 · " if is_locked else "",
				"阶段 · " if is_stage and not is_locked else "",
				str(landing.get("stage_label", "落点")),
				float(landing.get("score", 0.0)),
				float(landing.get("prosperity", 0.0)),
				float(landing.get("risk", 0.0)),
			],
			region_accent if is_locked else candidate_accent
		)
		header_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_card.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_locked else (Color(1.0, 1.0, 1.0, 0.98) if is_preferred else Color(1.0, 1.0, 1.0, 0.90))
		ecology_row.add_child(header_card)

		var lock_button := Button.new()
		lock_button.text = "已锁定" if is_locked else ("默认推进" if is_preferred else "锁定推进")
		lock_button.disabled = is_locked
		lock_button.custom_minimum_size = Vector2(92, 30)
		lock_button.modulate = region_accent if is_locked else (Color8(224, 186, 92) if is_preferred else Color8(162, 168, 176))
		lock_button.pressed.connect(_on_campaign_landing_selected.bind(landing_id))
		ecology_row.add_child(lock_button)

		landing_card.add_child(_make_compact_section_label("进展层"))
		var progress_row := HBoxContainer.new()
		progress_row.add_theme_constant_override("separation", 6)
		landing_card.add_child(progress_row)
		progress_row.add_child(_make_compact_hero_chip(
			"路线",
			"%s · %s" % [
				str(landing.get("run_profile_tag", "基础观察")),
				str(landing.get("archive_tier", "未建档")),
			],
			Color8(102, 152, 204)
		))

		var management_tag := str(landing.get("management_priority_tag", "常规经营区"))
		var backbone_tag := _region_management_backbone_tag({
			"management_priority_tag": landing.get("management_priority_tag", "常规经营区"),
			"branch_mode": landing.get("branch_mode", ""),
			"branch_completed": landing.get("branch_completed", false),
			"branch_completion_tag": landing.get("branch_completion_tag", ""),
			"branch_completion_counts": landing.get("branch_completion_counts", {}),
			"branch_completion_streak": landing.get("branch_completion_streak", 0),
		})
		var management_report := {
			"management_priority_tag": management_tag,
			"backbone_completion_tag": landing.get("backbone_completion_tag", ""),
			"backbone_completion_streak": landing.get("backbone_completion_streak", 0),
			"branch_mode": landing.get("branch_mode", ""),
			"branch_completed": landing.get("branch_completed", false),
			"branch_completion_tag": landing.get("branch_completion_tag", ""),
			"branch_completion_counts": landing.get("branch_completion_counts", {}),
			"branch_completion_streak": landing.get("branch_completion_streak", 0),
		}
		var management_chip_accent := _region_management_chip_color(management_report)
		var backbone_chip_accent := _region_backbone_chip_color(management_report)
		var consolidation_chip_accent := _region_consolidation_chip_color(management_report)
		if management_tag != "常规经营区" or backbone_tag != "" or str(landing.get("backbone_completion_tag", "")) != "":
			landing_card.add_child(_make_compact_section_label("经营层"))
			var management_row := HBoxContainer.new()
			management_row.add_theme_constant_override("separation", 6)
			landing_card.add_child(management_row)
			management_row.add_child(_make_compact_hero_chip("经营层级", _region_management_short_display(management_report), management_chip_accent))
			management_row.add_child(_make_compact_hero_chip("骨干状态", _region_backbone_short_display(management_report), backbone_chip_accent))
			management_row.add_child(_make_compact_hero_chip("巩固状态", _region_consolidation_short_display(management_report), consolidation_chip_accent))
		box.add_child(landing_shell)

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
	selected_game_action = _recommended_game_action(detail_cache.get(active_region_id, world_data.get("active_region", {})))
	selected_game_action = _mainline_action_for_region(active_region_id, selected_game_action)
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

extends Control

const DATA_PATH := "res://data/world_state.json"
const REPORT_PATH := "user://expedition_reports.json"
const PROJECT_REPORT_PATH := "res://data/expedition_reports.json"
const SELECTED_REGION_PATH := "user://selected_expedition_region.json"
const PROJECT_SELECTED_REGION_PATH := "res://data/selected_expedition_region.json"
const WORLD_MAP_SCENE := "res://scenes/world_map.tscn"
const BASE_WORLD_SIZE := Vector2(2800, 1700)
const WORLD_SIZE := Vector2(3600, 2300)
const PLAYER_RADIUS := Vector2(18, 22)
const DEFAULT_SPAWN := Vector2(860, 1120)
const HOTSPOT_LAYOUT := {
	"waterhole": Vector2(1180, 930),
	"migration_corridor": Vector2(1520, 760),
	"predator_ridge": Vector2(2040, 540),
	"carrion_field": Vector2(2140, 960),
	"shade_grove": Vector2(720, 650),
}
const CATEGORY_COLORS := {
	"掠食者": Color8(214, 112, 87),
	"草食动物": Color8(216, 190, 104),
	"飞行动物": Color8(130, 170, 224),
	"水域动物": Color8(88, 176, 182),
	"区域生物": Color8(174, 191, 126),
}
const CATEGORY_ICONS := {
	"掠食者": "▲",
	"草食动物": "◎",
	"飞行动物": "✦",
	"水域动物": "≈",
	"区域生物": "•",
}
const OBSTACLE_RECTS := [
	{"rect": Rect2(630, 560, 170, 126), "label": "林荫带"},
	{"rect": Rect2(1760, 640, 170, 110), "label": "林荫带"},
	{"rect": Rect2(1840, 390, 540, 300), "label": "断崖带"},
	{"rect": Rect2(1088, 838, 180, 184), "label": "深水区"},
]
const EXIT_LAYOUTS := [
	{"id": "west_gate", "label": "西部迁徙线", "rect": Rect2(40, 1180, 180, 220), "hint": "返回世界图 / 切换战区"},
	{"id": "north_gate", "label": "断崖高地口", "rect": Rect2(2330, 220, 230, 220), "hint": "进入北部断崖路线"},
	{"id": "east_gate", "label": "河口联通口", "rect": Rect2(2480, 620, 220, 220), "hint": "沿河口撤离并提交报告"},
]
const GATE_SPAWNS := {
	"west_gate": Vector2(260, 1280),
	"north_gate": Vector2(2160, 520),
	"east_gate": Vector2(2360, 760),
}
const REGION_LAYOUTS := {
	"grassland": {
		"hotspots": {
			"waterhole": Vector2(1180, 930),
			"migration_corridor": Vector2(1520, 760),
			"predator_ridge": Vector2(2040, 540),
			"carrion_field": Vector2(2140, 960),
			"shade_grove": Vector2(720, 650),
		},
		"obstacles": OBSTACLE_RECTS,
	},
	"wetland": {
		"hotspots": {
			"waterhole": Vector2(980, 900),
			"migration_corridor": Vector2(1460, 640),
			"predator_ridge": Vector2(1880, 510),
			"carrion_field": Vector2(2100, 930),
			"shade_grove": Vector2(610, 600),
		},
		"obstacles": [
			{"rect": Rect2(520, 720, 280, 220), "label": "浅滩沼泽"},
			{"rect": Rect2(980, 820, 240, 210), "label": "深水区"},
			{"rect": Rect2(1640, 500, 230, 180), "label": "芦苇沼带"},
			{"rect": Rect2(2020, 380, 320, 190), "label": "泥洲区"},
		],
	},
	"forest": {
		"hotspots": {
			"waterhole": Vector2(1240, 1040),
			"migration_corridor": Vector2(1610, 820),
			"predator_ridge": Vector2(1980, 560),
			"carrion_field": Vector2(2140, 870),
			"shade_grove": Vector2(760, 520),
		},
		"obstacles": [
			{"rect": Rect2(560, 460, 250, 210), "label": "密林带"},
			{"rect": Rect2(880, 980, 220, 170), "label": "倒木带"},
			{"rect": Rect2(1680, 660, 260, 200), "label": "密林带"},
			{"rect": Rect2(2050, 400, 250, 220), "label": "岩坡林带"},
		],
	},
	"coast": {
		"hotspots": {
			"waterhole": Vector2(980, 980),
			"migration_corridor": Vector2(1440, 760),
			"predator_ridge": Vector2(1880, 540),
			"carrion_field": Vector2(2240, 880),
			"shade_grove": Vector2(680, 610),
		},
		"obstacles": [
			{"rect": Rect2(900, 840, 280, 220), "label": "潮汐深带"},
			{"rect": Rect2(1820, 430, 330, 180), "label": "海岸岩脊"},
			{"rect": Rect2(620, 560, 210, 130), "label": "防风林"},
			{"rect": Rect2(2260, 760, 220, 180), "label": "礁岩浅滩"},
		],
	},
}
const BIOME_THEMES := {
	"grassland": {
		"ground": Color8(214, 197, 138),
		"arc": Color(1.0, 0.95, 0.78, 0.07),
		"grass_a": Color8(158, 176, 88, 120),
		"grass_b": Color8(168, 188, 98, 128),
		"water_a": Color8(91, 154, 188, 180),
		"water_b": Color8(176, 225, 234, 235),
		"route_a": Color8(123, 97, 63, 150),
		"route_b": Color8(235, 219, 168, 235),
	},
	"wetland": {
		"ground": Color8(160, 177, 132),
		"arc": Color(0.90, 1.0, 0.92, 0.08),
		"grass_a": Color8(118, 152, 96, 132),
		"grass_b": Color8(138, 170, 108, 136),
		"water_a": Color8(72, 134, 160, 190),
		"water_b": Color8(168, 220, 214, 240),
		"route_a": Color8(94, 102, 74, 140),
		"route_b": Color8(226, 236, 184, 218),
	},
	"forest": {
		"ground": Color8(110, 132, 96),
		"arc": Color(0.86, 0.95, 0.86, 0.06),
		"grass_a": Color8(88, 118, 72, 130),
		"grass_b": Color8(98, 132, 82, 136),
		"water_a": Color8(74, 122, 148, 180),
		"water_b": Color8(154, 198, 204, 228),
		"route_a": Color8(78, 68, 52, 150),
		"route_b": Color8(214, 196, 152, 220),
	},
	"coast": {
		"ground": Color8(194, 189, 160),
		"arc": Color(0.93, 0.97, 1.0, 0.08),
		"grass_a": Color8(154, 176, 132, 104),
		"grass_b": Color8(164, 186, 142, 108),
		"water_a": Color8(84, 152, 194, 200),
		"water_b": Color8(186, 228, 240, 236),
		"route_a": Color8(106, 104, 82, 140),
		"route_b": Color8(240, 228, 182, 226),
	},
}
const REGION_TEXTURE_PATHS := {
	"grassland": "res://assets/ui/region_maps/grassland.png",
	"wetland": "res://assets/ui/region_maps/wetland.png",
	"forest": "res://assets/ui/region_maps/forest.png",
	"coast": "res://assets/ui/region_maps/coast.png",
}

var world_data: Dictionary = {}
var region_detail: Dictionary = {}
var current_region_id := ""
var current_theme: Dictionary = BIOME_THEMES["grassland"]
var current_region_layout: Dictionary = REGION_LAYOUTS["grassland"]
var current_region_texture: Texture2D
var species_manifest: Array = []
var hotspots: Array = []
var wildlife: Array = []
var exit_zones: Array = []
var player_pos := Vector2(1080, 960)
var camera_pos := Vector2.ZERO
var player_speed := 280.0
var elapsed := 0.0
var show_codex := false
var current_encounter: Dictionary = {}
var current_hotspot: Dictionary = {}
var current_exit_zone: Dictionary = {}
var current_event: Dictionary = {}
var current_interaction: Dictionary = {}
var current_chase: Dictionary = {}
var current_chase_result: Dictionary = {}
var current_task: Dictionary = {}
var reward_feedback: Dictionary = {}
var reward_feedback_timer := 0.0
var world_task: Dictionary = {}
var mission_intro_timer := 0.0
var entry_request: Dictionary = {}
var incoming_handoff: Dictionary = {}
var handoff_task_completed := false
var region_event_chain: Array = []
var region_event_index := 0
var region_event_timer := 0.0
var discovered_species_ids: Dictionary = {}
var discovered_hotspot_ids: Dictionary = {}
var visited_region_ids: Dictionary = {}
var completed_task_ids: Dictionary = {}
var discovery_log: Array = []
var witnessed_pressure := false
var witnessed_chase_result := false
var hotspot_focus_time := 0.0
var chase_focus_time := 0.0
var survey_target_kind := ""
var survey_target_id := ""
var survey_target_label := ""
var survey_progress := 0.0
var survey_required_time := 0.0
var survey_target_data: Dictionary = {}
var nearby_threat_level := 0.0
var expedition_phase := "追踪"
var extraction_ready := false
var world_task_completion_notified := false
var species_intel_score := 0
var hotspot_intel_score := 0
var specialization_chain_bonus_claimed := false
var intel_breakdown := {
	"水源": 0,
	"迁徙": 0,
	"压迫": 0,
	"腐食": 0,
	"栖地": 0,
}
var ui_font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	ui_font = ThemeDB.fallback_font
	_load_region_payload()
	_build_wildlife()
	_update_camera()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			show_codex = not show_codex
			queue_redraw()
		elif event.keycode == KEY_M:
			get_tree().change_scene_to_file(WORLD_MAP_SCENE)
		elif event.keycode == KEY_E and not current_exit_zone.is_empty():
			_record_exit_summary(current_exit_zone)
			get_tree().change_scene_to_file(WORLD_MAP_SCENE)


func _process(delta: float) -> void:
	elapsed += delta
	_update_player(delta)
	_update_wildlife(delta)
	_update_camera()
	_update_encounter()
	_update_hotspot_focus(delta)
	_update_exit_zone()
	_update_field_survey(delta)
	_update_expedition_state()
	_update_region_event_chain(delta)
	_update_event_focus()
	_update_reward_feedback(delta)
	mission_intro_timer = maxf(0.0, mission_intro_timer - delta)
	queue_redraw()


func _draw() -> void:
	var viewport_rect := Rect2(Vector2.ZERO, size)
	draw_rect(viewport_rect, current_theme.get("ground", Color8(214, 197, 138)))
	_draw_world_ground()
	_draw_world_routes()
	_draw_hotspots()
	_draw_objective_guidance()
	_draw_objective_marker()
	_draw_wildlife()
	_draw_survey_lock_marker()
	_draw_interaction_prompts()
	_draw_player()
	_draw_overlay()


func _load_region_payload() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		return

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	world_data = parsed
	var region_details: Dictionary = world_data.get("region_details", {})
	entry_request = _load_entry_request(region_details)
	var target_region_id := str(entry_request.get("region_id", ""))
	if target_region_id == "":
		target_region_id = str(world_data.get("active_region", {}).get("id", ""))
	if target_region_id == "" or not region_details.has(target_region_id):
		for region_id in region_details.keys():
			var detail: Dictionary = region_details[region_id]
			if "grassland" in detail.get("dominant_biomes", []):
				target_region_id = str(region_id)
				break
	if target_region_id == "" and not region_details.is_empty():
		target_region_id = str(region_details.keys()[0])
	_apply_region(target_region_id)


func _load_entry_request(region_details: Dictionary) -> Dictionary:
	var tree_request = get_tree().get_meta("selected_expedition_region", {})
	if typeof(tree_request) == TYPE_DICTIONARY:
		var normalized_tree_request := _normalize_entry_request(tree_request, region_details)
		if not normalized_tree_request.is_empty():
			return normalized_tree_request
	var request := _read_entry_request(PROJECT_SELECTED_REGION_PATH, region_details)
	if not request.is_empty():
		return request
	return _read_entry_request(SELECTED_REGION_PATH, region_details)


func _read_entry_request(path: String, region_details: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return _normalize_entry_request(parsed, region_details)


func _normalize_entry_request(raw_request: Dictionary, region_details: Dictionary) -> Dictionary:
	var region_id := str(raw_request.get("region_id", ""))
	if region_details.has(region_id):
		return raw_request

	var region_name := str(raw_request.get("region_name", ""))
	for candidate_id in region_details.keys():
		var detail: Dictionary = region_details[candidate_id]
		if region_name != "" and region_name == str(detail.get("name", "")):
			raw_request["region_id"] = str(candidate_id)
			return raw_request
	return {}


func _apply_region(region_id: String, spawn_gate: String = "") -> void:
	var region_details: Dictionary = world_data.get("region_details", {})
	var next_detail: Dictionary = region_details.get(region_id, {})
	if next_detail.is_empty():
		return
	current_region_id = region_id
	region_detail = next_detail
	current_theme = _theme_for_region(next_detail)
	current_region_layout = _layout_for_region(next_detail)
	current_region_texture = _texture_for_biome_key(_biome_key())
	species_manifest = region_detail.get("species_manifest", [])
	if species_manifest.is_empty():
		species_manifest = region_detail.get("top_species", [])
	hotspots = region_detail.get("exploration_hotspots", [])
	_build_wildlife()
	_build_exit_zones()
	current_encounter.clear()
	current_hotspot.clear()
	current_exit_zone.clear()
	current_event.clear()
	current_interaction.clear()
	current_chase.clear()
	current_chase_result.clear()
	current_task.clear()
	reward_feedback.clear()
	reward_feedback_timer = 0.0
	world_task.clear()
	mission_intro_timer = 6.0
	incoming_handoff.clear()
	handoff_task_completed = false
	region_event_chain.clear()
	region_event_index = 0
	region_event_timer = 0.0
	visited_region_ids[region_id] = true
	hotspots = _sort_hotspots_by_priority(hotspots)
	hotspot_focus_time = 0.0
	chase_focus_time = 0.0
	survey_target_kind = ""
	survey_target_id = ""
	survey_target_label = ""
	survey_progress = 0.0
	survey_required_time = 0.0
	survey_target_data.clear()
	nearby_threat_level = 0.0
	expedition_phase = "追踪"
	extraction_ready = false
	world_task_completion_notified = false
	species_intel_score = 0
	hotspot_intel_score = 0
	specialization_chain_bonus_claimed = false
	for key in intel_breakdown.keys():
		intel_breakdown[key] = 0
	_build_region_event_chain()
	_ensure_world_task_request()
	_apply_region_entry_prompt()
	if spawn_gate != "" and GATE_SPAWNS.has(spawn_gate):
		player_pos = _find_safe_spawn(_scale_world_point(GATE_SPAWNS[spawn_gate]))
	else:
		player_pos = _find_safe_spawn(_scale_world_point(DEFAULT_SPAWN))


func _build_exit_zones() -> void:
	exit_zones.clear()
	var base_layout: Dictionary = EXIT_LAYOUTS[0]
	exit_zones.append(
		{
			"id": str(base_layout.get("id", "base_camp")),
			"label": "调查营地",
			"rect": _scale_world_rect(base_layout.get("rect", Rect2())),
			"hint": "按 E 撤离回世界图；报告会回到调查营地等待回灌",
			"target_region_id": "",
			"target_role": "回灌营地",
		}
	)
	var links: Array = region_detail.get("frontier_links", [])
	for index in range(min(maxi(0, EXIT_LAYOUTS.size() - 1), links.size())):
		var layout: Dictionary = EXIT_LAYOUTS[index + 1]
		var link: Dictionary = links[index]
		exit_zones.append(
			{
				"id": str(layout.get("id", "")),
				"label": str(link.get("target_name", layout.get("label", "区域出口"))),
				"rect": _scale_world_rect(layout.get("rect", Rect2())),
				"hint": "按 E 撤离回世界图；报告会标记通往 " + str(link.get("target_name", "下一片区域")),
				"target_region_id": str(link.get("target_region_id", "")),
				"target_role": str(link.get("target_role", "生态观测区")),
			}
		)


func _sort_hotspots_by_priority(raw_hotspots: Array) -> Array:
	var sorted_hotspots := raw_hotspots.duplicate(true)
	sorted_hotspots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _hotspot_priority_score(a) > _hotspot_priority_score(b)
	)
	return sorted_hotspots


func _hotspot_priority_score(hotspot: Dictionary) -> float:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	var intensity := float(hotspot.get("intensity", 0.0))
	var resource_state: Dictionary = region_detail.get("resource_state", {})
	var pressure_state: Dictionary = region_detail.get("ecological_pressures", {})
	var health_state: Dictionary = region_detail.get("health_state", {})
	var event_bonus := float(_active_event_hotspot_bonus(hotspot) + _report_hotspot_priority_bonus(hotspot))
	match hotspot_id:
		"waterhole":
			return intensity + float(resource_state.get("surface_water", 0.0)) * 1.4 + float(resource_state.get("freshwater", 0.0)) * 0.5 + event_bonus
		"migration_corridor":
			return intensity + float(resource_state.get("grazing_pressure", 0.0)) * 1.1 + float(resource_state.get("understory", 0.0)) * 0.35 + event_bonus
		"predator_ridge":
			return intensity + float(pressure_state.get("predation_load", 0.0)) * 1.2 + float(pressure_state.get("territorial_stress", 0.0)) * 0.5 + event_bonus
		"carrion_field":
			return intensity + float(resource_state.get("carcass_availability", 0.0)) * 1.6 + float(pressure_state.get("aerial_carrion_cycle", 0.0)) * 0.4 + event_bonus
		_:
			return intensity + float(health_state.get("resilience", 0.0)) * 0.9 + float(resource_state.get("canopy_cover", 0.0)) * 0.4 + event_bonus


func _report_hotspot_priority_bonus(hotspot: Dictionary) -> int:
	var reports := _load_expedition_reports()
	var report: Dictionary = reports.get(current_region_id, {})
	var channel := str(report.get("top_intel_channel", ""))
	var dominant_channel := str(report.get("dominant_intel_channel", channel))
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	var visit_count := int(report.get("visit_count", 0))
	var archive_tier := str(report.get("archive_tier", "初勘档案"))
	var bonus := 0
	match channel:
		"水源":
			bonus += 1 if hotspot_id == "waterhole" else 0
		"迁徙":
			bonus += 1 if hotspot_id == "migration_corridor" else 0
		"压迫":
			bonus += 1 if hotspot_id == "predator_ridge" else 0
		"腐食":
			bonus += 1 if hotspot_id == "carrion_field" else 0
		"栖地":
			bonus += 1 if hotspot_id == "shade_grove" else 0
	if dominant_channel != channel:
		match dominant_channel:
			"水源":
				bonus += 1 if hotspot_id == "waterhole" else 0
			"迁徙":
				bonus += 1 if hotspot_id == "migration_corridor" else 0
			"压迫":
				bonus += 1 if hotspot_id == "predator_ridge" else 0
			"腐食":
				bonus += 1 if hotspot_id == "carrion_field" else 0
			"栖地":
				bonus += 1 if hotspot_id == "shade_grove" else 0
	if visit_count >= 3:
		match dominant_channel:
			"水源":
				bonus += 2 if hotspot_id == "waterhole" else 0
			"迁徙":
				bonus += 2 if hotspot_id == "migration_corridor" else 0
			"压迫":
				bonus += 2 if hotspot_id == "predator_ridge" else 0
			"腐食":
				bonus += 2 if hotspot_id == "carrion_field" else 0
			"栖地":
				bonus += 2 if hotspot_id == "shade_grove" else 0
	match archive_tier:
		"熟悉档案":
			match dominant_channel:
				"水源":
					bonus += 1 if hotspot_id == "waterhole" else 0
				"迁徙":
					bonus += 1 if hotspot_id == "migration_corridor" else 0
				"压迫":
					bonus += 1 if hotspot_id == "predator_ridge" else 0
				"腐食":
					bonus += 1 if hotspot_id == "carrion_field" else 0
				"栖地":
					bonus += 1 if hotspot_id == "shade_grove" else 0
		"定型档案":
			match dominant_channel:
				"水源":
					bonus += 2 if hotspot_id == "waterhole" else 0
				"迁徙":
					bonus += 2 if hotspot_id == "migration_corridor" else 0
				"压迫":
					bonus += 2 if hotspot_id == "predator_ridge" else 0
				"腐食":
					bonus += 2 if hotspot_id == "carrion_field" else 0
				"栖地":
					bonus += 2 if hotspot_id == "shade_grove" else 0
	var route_style := str(report.get("dominant_route_style", "base"))
	var route_streak := int(report.get("route_style_streak", 0))
	var route_lock_tag := str(report.get("route_lock_tag", "未锁定"))
	var lock_completion_streak := int(report.get("lock_completion_streak", 0))
	if route_style == "quick" and route_streak >= 3 and hotspot_id == _specialization_target_hotspot_id():
		bonus += 1 if route_streak < 5 else 2
	elif route_style == "deep" and route_streak >= 3:
		if hotspot_id == _specialization_target_hotspot_id():
			bonus += 1
		elif hotspot_id == _specialization_followup_hotspot_id():
			bonus += 1 if route_streak < 5 else 2
	if route_lock_tag == "快取锁定" and hotspot_id == _specialization_target_hotspot_id():
		bonus += 1 if lock_completion_streak < 3 else 2
	elif route_lock_tag == "深挖锁定" and hotspot_id in [_specialization_target_hotspot_id(), _specialization_followup_hotspot_id()]:
		bonus += 1 if lock_completion_streak < 3 else 2
	var management_phase := str(report.get("management_rotation_phase", "常规经营"))
	var handoff_streak := int(report.get("handoff_completion_streak", 0))
	var branch_stability_tag := _region_branch_stability_tag()
	var backbone_tag := _region_management_backbone_tag()
	var backbone_streak := _region_backbone_completion_streak()
	if management_phase in ["主经营第一段", "单区快取主经营", "单区深挖主经营"]:
		if hotspot_id == _specialization_target_hotspot_id():
			bonus += 2 if handoff_streak >= 2 else 1
		elif _region_specialization_mode() == "深挖线" and hotspot_id == _specialization_followup_hotspot_id() and handoff_streak >= 3:
			bonus += 1
	if not incoming_handoff.is_empty() and not handoff_task_completed:
		var branch_mode := str(incoming_handoff.get("branch_mode", ""))
		var branch_completed := bool(incoming_handoff.get("branch_completed", false))
		if branch_mode == "deep_expand":
			if hotspot_id == _specialization_target_hotspot_id():
				bonus += 4 if branch_completed else 2
			elif hotspot_id == _specialization_followup_hotspot_id():
				bonus += 3 if branch_completed else 2
		elif branch_mode == "quick_close" and hotspot_id == _specialization_target_hotspot_id():
			bonus += 4 if branch_completed else 2
	if branch_stability_tag == "稳定扩线区":
		if hotspot_id == _specialization_target_hotspot_id():
			bonus += 3
		elif hotspot_id == _specialization_followup_hotspot_id():
			bonus += 3
	elif branch_stability_tag == "扩线塑形中":
		if hotspot_id == _specialization_target_hotspot_id():
			bonus += 2
		elif hotspot_id == _specialization_followup_hotspot_id():
			bonus += 1
	elif branch_stability_tag == "稳定收束区" and hotspot_id == _specialization_target_hotspot_id():
		bonus += 3
	elif branch_stability_tag == "收束塑形中" and hotspot_id == _specialization_target_hotspot_id():
		bonus += 2
	if backbone_tag == "快取经营骨干区" and hotspot_id == _specialization_target_hotspot_id():
		bonus += 3
	elif backbone_tag == "深挖经营骨干区":
		if hotspot_id == _specialization_target_hotspot_id():
			bonus += 3
		elif hotspot_id == _specialization_followup_hotspot_id():
			bonus += 2
	if backbone_streak >= 2:
		if backbone_tag == "快取经营骨干区" and hotspot_id == _specialization_target_hotspot_id():
			bonus += 2
		elif backbone_tag == "深挖经营骨干区":
			if hotspot_id == _specialization_target_hotspot_id():
				bonus += 2
			elif hotspot_id == _specialization_followup_hotspot_id():
				bonus += 1
	return bonus


func _build_wildlife() -> void:
	wildlife.clear()
	var capped_manifest := species_manifest.slice(0, min(species_manifest.size(), 18))
	for index in range(capped_manifest.size()):
		var entry: Dictionary = capped_manifest[index]
		var species_id := str(entry.get("species_id", ""))
		var category := str(entry.get("category", "区域生物"))
		var anchor_id := _identity_anchor_for_species(species_id, category, _anchor_for_species(species_id))
		var anchor: Vector2 = _hotspot_position(anchor_id)
		var phase := float(index) * 0.67
		var color: Color = CATEGORY_COLORS.get(category, Color8(174, 191, 126))
		var behavior := _identity_behavior_for_species(species_id, category, _behavior_for_species(species_id, category))
		var group_size := maxi(1, _group_size_for_species(species_id, category, int(entry.get("count", 0))) + _identity_group_size_bonus(species_id, category))
		var radius := _identity_radius_for_species(category, Vector2(128 + (index % 4) * 34, 72 + (index % 3) * 28))
		radius = Vector2(radius.x * _world_scale().x * 1.45, radius.y * _world_scale().y * 1.45)
		var speed := _identity_speed_for_species(category, 0.16 + float((index % 5) + 1) * 0.035)
		wildlife.append(
			{
				"species_id": species_id,
				"label": str(entry.get("label", species_id)),
				"count": int(entry.get("count", 0)),
				"category": category,
				"anchor_id": anchor_id,
				"anchor": anchor,
				"radius": radius,
				"phase": phase,
				"speed": speed,
				"position": _wildlife_spawn_position(index, anchor, radius),
				"target_position": _wildlife_spawn_position(index + 7, anchor, radius),
				"next_target_time": 0.7 + float(index % 5) * 0.33,
				"color": color,
				"behavior": behavior,
				"group_size": group_size,
				"alert_radius": 110.0 + float(index % 4) * 18.0,
				"focus": Vector2.ZERO,
				"activity": "移动",
			}
		)


func _texture_for_biome_key(biome_key: String) -> Texture2D:
	var path := str(REGION_TEXTURE_PATHS.get(biome_key, REGION_TEXTURE_PATHS["grassland"]))
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func _wildlife_spawn_position(index: int, anchor: Vector2, radius: Vector2) -> Vector2:
	var angle := float(index) * 1.91
	var spread := Vector2(cos(angle) * radius.x * 0.92, sin(angle * 1.37) * radius.y * 0.82)
	var offset := Vector2(sin(float(index) * 2.37) * 80.0, cos(float(index) * 1.63) * 46.0)
	return _clamped_world_position(anchor + spread + offset)


func _anchor_for_species(species_id: String) -> String:
	var is_wetland := current_theme == BIOME_THEMES["wetland"]
	var is_forest := current_theme == BIOME_THEMES["forest"]
	var is_coast := current_theme == BIOME_THEMES["coast"]
	if species_id in ["lion", "hyena", "wolf", "fox"]:
		if is_forest:
			return "shade_grove"
		return "predator_ridge"
	if species_id in ["vulture", "eagle"]:
		if is_coast:
			return "migration_corridor"
		return "carrion_field"
	if species_id in ["small_fish", "minnow", "carp", "catfish", "blackfish", "pike", "pufferfish", "shrimp", "crab", "frog", "hippopotamus"]:
		return "waterhole"
	if species_id in ["african_elephant", "white_rhino", "giraffe", "zebra", "antelope", "deer", "rabbit", "boar", "wild_boar"]:
		if is_wetland:
			return "waterhole"
		if is_forest:
			return "shade_grove"
		return "migration_corridor"
	if is_coast:
		return "waterhole"
	return "shade_grove"


func _behavior_for_species(species_id: String, category: String) -> String:
	if category == "掠食者":
		return "stalk"
	if category == "飞行动物":
		return "glide"
	if category == "水域动物":
		return "swim"
	if species_id in ["african_elephant", "white_rhino", "hippopotamus"]:
		return "heavy_roam"
	return "graze"


func _group_size_for_species(species_id: String, category: String, count: int) -> int:
	if species_id in ["zebra", "antelope", "deer"]:
		return clampi(int(round(count / 4.0)), 3, 6)
	if species_id in ["vulture", "duck", "sparrow"]:
		return clampi(int(round(count / 3.0)), 2, 5)
	if species_id in ["lion", "hyena", "eagle"]:
		return clampi(int(round(count / 2.0)), 1, 3)
	if category == "水域动物":
		return clampi(int(round(count / 4.0)), 2, 5)
	return clampi(int(round(count / 5.0)), 1, 4)


func _identity_anchor_for_species(species_id: String, category: String, default_anchor: String) -> String:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 3:
		return default_anchor
	match dominant_channel:
		"水源":
			if category == "水域动物" or species_id in ["african_elephant", "zebra", "antelope", "deer"]:
				return "waterhole"
		"迁徙":
			if category == "草食动物":
				return "migration_corridor"
		"压迫":
			if category == "掠食者":
				return "predator_ridge"
		"腐食":
			if category == "飞行动物":
				return "carrion_field"
		"栖地":
			if category == "区域生物" or species_id in ["giraffe", "boar", "wild_boar"]:
				return "shade_grove"
	if _region_archive_tier() == "定型档案":
		match dominant_channel:
			"水源":
				if category in ["水域动物", "草食动物"]:
					return "waterhole"
			"迁徙":
				if category == "草食动物":
					return "migration_corridor"
			"压迫":
				if category == "掠食者":
					return "predator_ridge"
			"腐食":
				if category == "飞行动物":
					return "carrion_field"
			"栖地":
				if category == "区域生物":
					return "shade_grove"
	return default_anchor


func _identity_behavior_for_species(species_id: String, category: String, default_behavior: String) -> String:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 3:
		return default_behavior
	match dominant_channel:
		"压迫":
			if category == "掠食者":
				return "stalk"
		"腐食":
			if category == "飞行动物":
				return "glide"
		"水源":
			if category == "水域动物":
				return "swim"
		"栖地":
			if species_id in ["african_elephant", "white_rhino", "hippopotamus"]:
				return "heavy_roam"
	return default_behavior


func _identity_group_size_bonus(species_id: String, category: String) -> int:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 3:
		return 0
	var archive_tier := _region_archive_tier()
	match dominant_channel:
		"迁徙":
			if category == "草食动物":
				return 2 if archive_tier == "定型档案" else 1
			return 0
		"压迫":
			if category == "掠食者":
				return 2 if archive_tier == "定型档案" else 1
			return 0
		"腐食":
			if category == "飞行动物":
				return 2 if archive_tier == "定型档案" else 1
			return 0
		"水源":
			if category == "水域动物":
				return 2 if archive_tier == "定型档案" else 1
			return 0
		"栖地":
			if category == "区域生物" or species_id in ["giraffe", "boar", "wild_boar"]:
				return 2 if archive_tier == "定型档案" else 1
			return 0
		_:
			return 0


func _identity_radius_for_species(category: String, default_radius: Vector2) -> Vector2:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 3:
		return default_radius
	var archive_tier := _region_archive_tier()
	match dominant_channel:
		"迁徙":
			if category == "草食动物":
				return default_radius * (Vector2(1.32, 1.14) if archive_tier == "定型档案" else Vector2(1.24, 1.10))
		"压迫":
			if category == "掠食者":
				return default_radius * (Vector2(1.20, 1.10) if archive_tier == "定型档案" else Vector2(1.12, 1.06))
		"水源":
			if category == "水域动物":
				return default_radius * (Vector2(1.28, 1.12) if archive_tier == "定型档案" else Vector2(1.18, 1.08))
		"腐食":
			if category == "飞行动物":
				return default_radius * (Vector2(1.32, 1.24) if archive_tier == "定型档案" else Vector2(1.20, 1.18))
	return default_radius


func _identity_speed_for_species(category: String, default_speed: float) -> float:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 3:
		return default_speed
	var archive_tier := _region_archive_tier()
	match dominant_channel:
		"迁徙":
			if category == "草食动物":
				return default_speed + (0.07 if archive_tier == "定型档案" else 0.04)
			return default_speed
		"压迫":
			if category == "掠食者":
				return default_speed + (0.05 if archive_tier == "定型档案" else 0.03)
			return default_speed
		"水源":
			if category == "水域动物":
				return default_speed - (0.05 if archive_tier == "定型档案" else 0.03)
			return default_speed
		"栖地":
			if category == "区域生物":
				return default_speed - (0.04 if archive_tier == "定型档案" else 0.02)
			return default_speed
		_:
			return default_speed


func _theme_for_region(detail: Dictionary) -> Dictionary:
	var biomes: Array = detail.get("dominant_biomes", [])
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return BIOME_THEMES["forest"]
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return BIOME_THEMES["wetland"]
	if "coast" in biomes or "seagrass" in biomes or "coral_reef" in biomes or "estuary" in biomes:
		return BIOME_THEMES["coast"]
	return BIOME_THEMES["grassland"]


func _layout_for_region(detail: Dictionary) -> Dictionary:
	var biomes: Array = detail.get("dominant_biomes", [])
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return REGION_LAYOUTS["forest"]
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return REGION_LAYOUTS["wetland"]
	if "coast" in biomes or "seagrass" in biomes or "coral_reef" in biomes or "estuary" in biomes:
		return REGION_LAYOUTS["coast"]
	return REGION_LAYOUTS["grassland"]


func _exploration_title() -> String:
	var biomes: Array = region_detail.get("dominant_biomes", [])
	if "tropical_rainforest" in biomes:
		return "雨林河道 · 探索中"
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return "森林前线 · 探索中"
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return "湿地前线 · 探索中"
	if "coast" in biomes or "seagrass" in biomes or "coral_reef" in biomes or "estuary" in biomes:
		return "海岸前线 · 探索中"
	if "grassland" in biomes or "shrubland" in biomes or "seasonal_waterhole" in biomes:
		return "草原前线 · 探索中"
	return "生态前线 · 探索中"


func _hotspot_position(hotspot_id: String) -> Vector2:
	var layout_hotspots: Dictionary = current_region_layout.get("hotspots", HOTSPOT_LAYOUT)
	return _scale_world_point(layout_hotspots.get(hotspot_id, HOTSPOT_LAYOUT.get(hotspot_id, BASE_WORLD_SIZE * 0.5)))


func _active_obstacles() -> Array:
	var scaled: Array = []
	for obstacle_variant in current_region_layout.get("obstacles", OBSTACLE_RECTS):
		var obstacle: Dictionary = obstacle_variant
		var copy := obstacle.duplicate(true)
		copy["rect"] = _scale_world_rect(obstacle.get("rect", Rect2()))
		scaled.append(copy)
	return scaled


func _scale_world_point(point: Vector2) -> Vector2:
	return Vector2(point.x * WORLD_SIZE.x / BASE_WORLD_SIZE.x, point.y * WORLD_SIZE.y / BASE_WORLD_SIZE.y)


func _scale_world_rect(rect: Rect2) -> Rect2:
	return Rect2(_scale_world_point(rect.position), Vector2(rect.size.x * WORLD_SIZE.x / BASE_WORLD_SIZE.x, rect.size.y * WORLD_SIZE.y / BASE_WORLD_SIZE.y))


func _world_scale() -> Vector2:
	return Vector2(WORLD_SIZE.x / BASE_WORLD_SIZE.x, WORLD_SIZE.y / BASE_WORLD_SIZE.y)


func _update_player(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		move.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		move.y += 1.0
	if move.length() > 1.0:
		move = move.normalized()
	var speed := player_speed * (1.45 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	var next_pos := player_pos + move * speed * delta
	player_pos = _resolve_player_collision(next_pos)


func _resolve_player_collision(target_pos: Vector2) -> Vector2:
	var resolved := target_pos
	resolved.x = clampf(resolved.x, 120.0, WORLD_SIZE.x - 120.0)
	resolved.y = clampf(resolved.y, 120.0, WORLD_SIZE.y - 120.0)
	var full_rect := Rect2(resolved - PLAYER_RADIUS, PLAYER_RADIUS * 2.0)
	for obstacle in _active_obstacles():
		var obstacle_rect: Rect2 = obstacle["rect"]
		if full_rect.intersects(obstacle_rect):
			var x_rect := Rect2(Vector2(resolved.x, player_pos.y) - PLAYER_RADIUS, PLAYER_RADIUS * 2.0)
			var y_rect := Rect2(Vector2(player_pos.x, resolved.y) - PLAYER_RADIUS, PLAYER_RADIUS * 2.0)
			if not x_rect.intersects(obstacle_rect):
				resolved.y = player_pos.y
			elif not y_rect.intersects(obstacle_rect):
				resolved.x = player_pos.x
			else:
				resolved = player_pos
			full_rect = Rect2(resolved - PLAYER_RADIUS, PLAYER_RADIUS * 2.0)
	return resolved


func _is_blocked(candidate: Vector2) -> bool:
	var player_rect := Rect2(candidate - PLAYER_RADIUS, PLAYER_RADIUS * 2.0)
	for obstacle in _active_obstacles():
		var obstacle_rect: Rect2 = obstacle["rect"]
		if player_rect.intersects(obstacle_rect):
			return true
	return false


func _find_safe_spawn(preferred: Vector2) -> Vector2:
	if not _is_blocked(preferred):
		return preferred
	var offsets = [
		Vector2(80, 0),
		Vector2(-80, 0),
		Vector2(0, 80),
		Vector2(0, -80),
		Vector2(120, 120),
		Vector2(-120, 120),
		Vector2(140, -120),
		Vector2(-140, -120),
		Vector2(220, 0),
		Vector2(-220, 0),
	]
	for offset in offsets:
		var candidate: Vector2 = preferred + offset
		if not _is_blocked(candidate):
			return candidate
	return _scale_world_point(Vector2(720, 1080))


func _update_wildlife(delta: float) -> void:
	var herd_focus := _herd_center()
	var prey_positions := _prey_positions()
	var strongest_pressure: Dictionary = {}
	var strongest_chase: Dictionary = {}
	for index in range(wildlife.size()):
		var animal: Dictionary = wildlife[index]
		var phase := float(animal.get("phase", 0.0))
		var speed := float(animal.get("speed", 0.32))
		var angle := elapsed * speed + phase
		var behavior := str(animal.get("behavior", "graze"))
		var activity := _animal_activity(animal, angle)
		animal["activity"] = activity
		var current_pos: Vector2 = animal.get("position", animal.get("anchor", Vector2.ZERO))
		var target_pos: Vector2 = animal.get("target_position", _wildlife_next_target(animal, index))
		if elapsed >= float(animal.get("next_target_time", 0.0)) or current_pos.distance_to(target_pos) < 34.0:
			target_pos = _wildlife_next_target(animal, index)
			animal["target_position"] = target_pos
			animal["next_target_time"] = elapsed + _wildlife_target_duration(animal, index)
		var player_delta := current_pos - player_pos
		var player_distance := player_delta.length()
		if behavior == "stalk":
			var prey_focus := _nearest_target(current_pos, prey_positions)
			if prey_focus != Vector2.ZERO:
				var chase_distance := current_pos.distance_to(prey_focus)
				var chase_burst := chase_distance < 90.0
				target_pos = target_pos.lerp(prey_focus, 0.16 if chase_burst else 0.08)
				var pressure_score := 1.0 / maxf(1.0, chase_distance)
				if strongest_pressure.is_empty() or pressure_score > float(strongest_pressure.get("score", 0.0)):
					strongest_pressure = {
						"predator": animal,
						"target": prey_focus,
						"score": pressure_score,
					}
				if chase_burst and (strongest_chase.is_empty() or chase_distance < float(strongest_chase.get("distance", 999999.0))):
					strongest_chase = {
						"predator": animal,
						"target": prey_focus,
						"distance": chase_distance,
					}
			elif herd_focus != Vector2.ZERO:
				target_pos = target_pos.lerp(herd_focus, 0.12)
			if player_distance < 120.0:
				target_pos = target_pos.lerp(current_pos, 0.18)
		elif behavior == "glide":
			target_pos.y -= 34.0
		elif behavior == "swim":
			target_pos = target_pos.lerp(_hotspot_position("waterhole"), 0.30)
		elif behavior == "heavy_roam":
			target_pos = target_pos.lerp(_behavior_bias_target(animal, phase), 0.20)
		else:
			var nearest_predator := _nearest_predator_position(current_pos)
			if nearest_predator != Vector2.ZERO and current_pos.distance_to(nearest_predator) < 240.0:
				var flee := (current_pos - nearest_predator).normalized()
				target_pos += flee * (180.0 if current_pos.distance_to(nearest_predator) > 150.0 else 260.0)
		target_pos = _clamped_world_position(target_pos)
		var next_pos := _move_animal_toward(current_pos, target_pos, animal, activity, delta)
		animal["position"] = next_pos
		animal["target_position"] = target_pos
		wildlife[index] = animal
	current_interaction.clear()
	current_chase.clear()
	current_chase_result.clear()
	if not strongest_pressure.is_empty():
		var predator: Dictionary = strongest_pressure.get("predator", {})
		var target: Vector2 = strongest_pressure.get("target", Vector2.ZERO)
		var predator_pos: Vector2 = predator.get("position", Vector2.ZERO)
		if predator_pos.distance_to(target) < 220.0:
			current_interaction = {
				"title": "追逐压力",
				"body": "%s 正在压迫草食群，群体已经开始偏移。" % str(predator.get("label", "掠食者")),
				"accent": Color8(240, 156, 110),
				"predator": predator,
				"target": target,
			}
			witnessed_pressure = true
	if not strongest_chase.is_empty():
		var chase_predator: Dictionary = strongest_chase.get("predator", {})
		chase_focus_time += delta
		current_chase = {
			"title": "追猎爆发",
			"body": "%s 已进入短时冲刺，草食群正在快速逃散。" % str(chase_predator.get("label", "掠食者")),
			"accent": Color8(255, 119, 86),
			"predator": chase_predator,
			"target": strongest_chase.get("target", Vector2.ZERO),
		}
		if float(strongest_chase.get("distance", 999999.0)) < 20.0 and chase_focus_time > 3.2:
			current_chase_result = {
				"title": "追猎命中",
				"body": "%s 成功切入草食群，群体被彻底冲散。" % str(chase_predator.get("label", "掠食者")),
				"accent": Color8(255, 96, 78),
			}
			witnessed_chase_result = true
			discovery_log.push_front("追猎命中：%s" % str(chase_predator.get("label", "掠食者")))
			discovery_log = discovery_log.slice(0, 6)
			chase_focus_time = 0.0
		elif chase_focus_time > 8.0:
			current_chase_result = {
				"title": "追猎落空",
				"body": "%s 的冲刺结束，草食群成功脱离压迫区。" % str(chase_predator.get("label", "掠食者")),
				"accent": Color8(240, 202, 132),
			}
			witnessed_chase_result = true
			discovery_log.push_front("追猎落空：%s" % str(chase_predator.get("label", "掠食者")))
			discovery_log = discovery_log.slice(0, 6)
			chase_focus_time = 0.0
	else:
		chase_focus_time = 0.0


func _behavior_bias_target(animal: Dictionary, phase: float) -> Vector2:
	var behavior := str(animal.get("behavior", "graze"))
	var anchor: Vector2 = animal.get("anchor", Vector2.ZERO)
	if behavior == "swim":
		return _hotspot_position("waterhole")
	if behavior == "glide":
		return _hotspot_position("carrion_field").lerp(_hotspot_position("predator_ridge"), 0.45)
	if behavior == "heavy_roam":
		var roam_shift := 0.5 + 0.5 * sin(elapsed * 0.18 + phase)
		return _hotspot_position("waterhole").lerp(_hotspot_position("shade_grove"), roam_shift)
	if behavior == "stalk":
		return _hotspot_position("predator_ridge").lerp(_hotspot_position("migration_corridor"), 0.45)
	var migration_weight := 0.48 + 0.28 * sin(elapsed * 0.14 + phase)
	return _hotspot_position("migration_corridor").lerp(_hotspot_position("waterhole"), migration_weight).lerp(anchor, 0.22)


func _wildlife_next_target(animal: Dictionary, index: int) -> Vector2:
	var behavior := str(animal.get("behavior", "graze"))
	var anchor: Vector2 = animal.get("anchor", Vector2.ZERO)
	var radius: Vector2 = animal.get("radius", Vector2(120, 80))
	var phase := float(animal.get("phase", 0.0))
	var seed := elapsed * 0.31 + phase * 8.7 + float(index) * 1.9
	var wander := Vector2(cos(seed) * radius.x, sin(seed * 1.27) * radius.y)
	match behavior:
		"swim":
			return _clamped_world_position(_hotspot_position("waterhole") + Vector2(cos(seed) * 150.0, sin(seed * 1.4) * 76.0))
		"glide":
			var sky_lane := _hotspot_position("carrion_field").lerp(_hotspot_position("predator_ridge"), 0.48)
			return _clamped_world_position(sky_lane + Vector2(cos(seed * 0.74) * 360.0, sin(seed * 0.58) * 190.0 - 70.0))
		"stalk":
			var ambush := _hotspot_position("predator_ridge").lerp(_hotspot_position("migration_corridor"), 0.38)
			return _clamped_world_position(ambush + wander * 0.72)
		"heavy_roam":
			var water_to_shade := _hotspot_position("waterhole").lerp(_hotspot_position("shade_grove"), 0.50 + sin(seed * 0.35) * 0.34)
			return _clamped_world_position(water_to_shade + wander * 0.88)
		_:
			var route := _hotspot_position("migration_corridor").lerp(_hotspot_position("waterhole"), 0.38 + sin(seed * 0.24) * 0.28)
			return _clamped_world_position(route.lerp(anchor, 0.28) + wander)


func _wildlife_target_duration(animal: Dictionary, index: int) -> float:
	match str(animal.get("behavior", "graze")):
		"stalk":
			return 1.3 + fmod(float(index) * 0.41, 0.9)
		"glide":
			return 1.0 + fmod(float(index) * 0.29, 0.8)
		"swim":
			return 1.8 + fmod(float(index) * 0.37, 1.2)
		"heavy_roam":
			return 2.8 + fmod(float(index) * 0.53, 1.8)
		_:
			return 2.1 + fmod(float(index) * 0.47, 1.4)


func _move_animal_toward(current_pos: Vector2, target_pos: Vector2, animal: Dictionary, activity: String, delta: float) -> Vector2:
	if activity in ["停留", "觅食", "潜伏"]:
		target_pos = current_pos.lerp(target_pos, 0.22)
	var delta_to_target := target_pos - current_pos
	var distance := delta_to_target.length()
	if distance < 0.01:
		return current_pos
	var speed_px := _wildlife_speed_px(animal, activity)
	var step := minf(distance, speed_px * delta)
	var moved := current_pos + delta_to_target.normalized() * step
	var drift := Vector2(sin(elapsed * 1.7 + float(animal.get("phase", 0.0))) * 4.0, cos(elapsed * 1.1) * 2.4)
	if activity in ["停留", "觅食", "潜伏"]:
		drift *= 0.26
	return _clamped_world_position(moved + drift * delta)


func _wildlife_speed_px(animal: Dictionary, activity: String) -> float:
	var behavior := str(animal.get("behavior", "graze"))
	var base := 74.0
	match behavior:
		"stalk":
			base = 78.0
		"glide":
			base = 150.0
		"swim":
			base = 64.0
		"heavy_roam":
			base = 52.0
	match activity:
		"逼近", "巡猎":
			base *= 1.12
		"警觉":
			base *= 1.42
		"取水", "觅食", "潜伏", "停留":
			base *= 0.42
	return base


func _clamped_world_position(value: Vector2) -> Vector2:
	return Vector2(
		clampf(value.x, 120.0, WORLD_SIZE.x - 120.0),
		clampf(value.y, 120.0, WORLD_SIZE.y - 120.0)
	)


func _animal_activity(animal: Dictionary, angle: float) -> String:
	var behavior := str(animal.get("behavior", "graze"))
	var phase := float(animal.get("phase", 0.0))
	var cycle := sin(elapsed * 0.34 + phase * 1.7)
	var pulse := sin(angle * 1.9 + phase)
	if behavior == "glide":
		return "盘旋" if cycle > -0.25 else "滑翔"
	if behavior == "swim":
		return "潜游" if cycle < -0.35 else "巡游"
	if behavior == "stalk":
		if cycle > 0.42:
			return "潜伏"
		if pulse > 0.55:
			return "逼近"
		return "巡猎"
	if behavior == "heavy_roam":
		if cycle > 0.36:
			return "停留"
		if cycle < -0.42:
			return "取水"
		return "漫游"
	if cycle > 0.40:
		return "觅食"
	if cycle < -0.45:
		return "停留"
	if pulse > 0.62:
		return "警觉"
	return "移动"


func _apply_animal_activity_motion(animal: Dictionary, target_pos: Vector2, activity: String, player_delta: Vector2, player_distance: float) -> Vector2:
	var current_pos: Vector2 = animal.get("position", target_pos)
	var anchor: Vector2 = animal.get("anchor", target_pos)
	match activity:
		"停留", "觅食", "潜伏":
			var settle_point := current_pos.lerp(anchor, 0.018)
			return current_pos.lerp(settle_point, 0.22)
		"取水":
			return target_pos.lerp(_hotspot_position("waterhole"), 0.34)
		"警觉":
			return target_pos.lerp(current_pos, 0.32)
		"逼近":
			return current_pos.lerp(target_pos, 0.58)
		"盘旋":
			return current_pos.lerp(target_pos + Vector2(0, -34), 0.42)
		"潜游":
			return current_pos.lerp(target_pos, 0.26)
		_:
			return current_pos.lerp(target_pos, 0.72)


func _prey_positions() -> Array:
	var positions: Array = []
	for animal in wildlife:
		if str(animal.get("category", "")) == "草食动物":
			positions.append(animal.get("position", Vector2.ZERO))
	return positions


func _nearest_target(origin: Vector2, targets: Array) -> Vector2:
	var nearest := Vector2.ZERO
	var nearest_distance := 1000000.0
	for target in targets:
		var point := target as Vector2
		var distance := origin.distance_to(point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = point
	if nearest_distance > 460.0:
		return Vector2.ZERO
	return nearest


func _nearest_predator_position(origin: Vector2) -> Vector2:
	var nearest := Vector2.ZERO
	var nearest_distance := 1000000.0
	for animal in wildlife:
		if str(animal.get("category", "")) != "掠食者":
			continue
		var point: Vector2 = animal.get("position", Vector2.ZERO)
		var distance := origin.distance_to(point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = point
	if nearest_distance > 320.0:
		return Vector2.ZERO
	return nearest


func _herd_center() -> Vector2:
	var total := Vector2.ZERO
	var count := 0
	for animal in wildlife:
		if str(animal.get("category", "")) == "草食动物":
			total += animal.get("position", Vector2.ZERO)
			count += 1
	if count == 0:
		return Vector2.ZERO
	return total / float(count)


func _update_camera() -> void:
	camera_pos = player_pos - size * 0.5
	camera_pos.x = clampf(camera_pos.x, 0.0, maxf(0.0, WORLD_SIZE.x - size.x))
	camera_pos.y = clampf(camera_pos.y, 0.0, maxf(0.0, WORLD_SIZE.y - size.y))


func _update_encounter() -> void:
	current_encounter.clear()
	var best_score := -100000.0
	for animal in wildlife:
		var distance := player_pos.distance_to(animal.get("position", Vector2.ZERO))
		if distance < 155.0:
			var score := (155.0 - distance) + _active_event_encounter_bias(animal) * 24.0 + _run_profile_encounter_bias(animal) * 20.0
			if score > best_score:
				best_score = score
				current_encounter = animal


func _active_event_encounter_bias(animal: Dictionary) -> float:
	match _active_region_event_tag():
		"predation":
			return 1.0 if str(animal.get("category", "")) == "掠食者" else 0.0
		"carrion":
			return 1.0 if str(animal.get("category", "")) == "飞行动物" else 0.0
		"territory":
			return 0.8 if str(animal.get("category", "")) == "草食动物" else 0.0
		"pressure":
			return 0.8 if str(animal.get("category", "")) == "掠食者" else 0.2
		"symbiosis":
			return 0.8 if str(animal.get("category", "")) == "区域生物" else 0.0
		"focus":
			if hotspots.is_empty():
				return 0.0
			return 0.8 if str(animal.get("anchor_id", "")) == str(hotspots[0].get("hotspot_id", "")) else 0.0
		_:
			return 0.0


func _run_profile_encounter_bias(animal: Dictionary) -> float:
	var archive_tier := _region_archive_tier()
	match _region_run_profile():
		"快取完成":
			if _species_intel_channel(animal) == _region_specialization_target_channel():
				return 1.15 if archive_tier == "定型档案" else 1.0
			return 0.0
		"深挖完成":
			if str(animal.get("anchor_id", "")) == _specialization_followup_hotspot_id():
				return 1.1 if archive_tier == "定型档案" else 0.9
			if _species_intel_channel(animal) == _region_specialization_target_channel():
				return 0.58 if archive_tier == "定型档案" else 0.45
			return 0.0
		_:
			if archive_tier in ["熟悉档案", "定型档案"] and _species_intel_channel(animal) == _region_specialization_target_channel():
				return 0.18 if archive_tier == "熟悉档案" else 0.30
			return 0.0


func _update_hotspot_focus(delta: float) -> void:
	var previous_hotspot_id := str(current_hotspot.get("hotspot_id", ""))
	current_hotspot.clear()
	var nearest_distance := 100000.0
	for hotspot in hotspots:
		var hotspot_id := str(hotspot.get("hotspot_id", ""))
		var center: Vector2 = _hotspot_position(hotspot_id)
		var distance := player_pos.distance_to(center)
		if distance < 170.0 and distance < nearest_distance:
			current_hotspot = hotspot
			nearest_distance = distance
	if not current_hotspot.is_empty():
		_record_hotspot_discovery(current_hotspot)
		var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		if hotspot_id != previous_hotspot_id:
			hotspot_focus_time = 0.0
		hotspot_focus_time += delta
		_update_hotspot_task()
	else:
		hotspot_focus_time = 0.0
		current_task.clear()


func _update_exit_zone() -> void:
	current_exit_zone.clear()
	for zone in exit_zones:
		var zone_rect: Rect2 = zone["rect"]
		if zone_rect.has_point(player_pos):
			current_exit_zone = zone
			return


func _update_event_focus() -> void:
	current_event.clear()
	if not current_exit_zone.is_empty():
		current_event = {
			"title": "区域出口已锁定",
			"body": _exit_event_body(),
			"accent": Color8(246, 220, 158),
		}
		return
	if not current_interaction.is_empty():
		current_event = current_interaction
		return
	if not current_chase.is_empty():
		current_event = current_chase
		return
	if not current_chase_result.is_empty():
		current_event = current_chase_result
		return
	if not current_task.is_empty():
		current_event = current_task
		return
	var handoff_task := _active_handoff_task()
	if not handoff_task.is_empty():
		current_event = handoff_task
		return
	if not current_hotspot.is_empty():
		var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		current_event = {
			"title": "生态观察",
			"body": _biome_hotspot_label(hotspot_id) + " · " + _biome_hotspot_summary(current_hotspot) + " · 按住 Space 开始采样。",
			"accent": Color8(170, 224, 198),
		}
		return
	if not current_encounter.is_empty():
		current_event = {
			"title": "动物偶遇",
			"body": str(current_encounter.get("label", "")) + " · " + str(current_encounter.get("category", "")) + " · 按住 Space 记录。",
			"accent": Color8(244, 213, 142),
		}
		return
	if not region_event_chain.is_empty():
		current_event = region_event_chain[region_event_index % region_event_chain.size()]


func _update_region_event_chain(delta: float) -> void:
	if region_event_chain.is_empty():
		return
	region_event_timer += delta
	if region_event_timer >= 4.8:
		region_event_timer = 0.0
		region_event_index = (region_event_index + 1) % region_event_chain.size()


func _build_region_event_chain() -> void:
	region_event_chain.clear()
	var pressure_headlines: Array = region_detail.get("pressure_headlines", [])
	var narrative: Dictionary = region_detail.get("narrative", {})
	var seen := {}
	_append_region_event("区域总态", "%s · %s" % [_region_state_label(), _chain_focus_text()], Color8(170, 224, 198), seen, "focus")
	_append_biome_event_chain(seen)
	if pressure_headlines.size() > 0:
		_append_region_event("压力播报", str(pressure_headlines[0]), Color8(214, 132, 132), seen, "pressure")
	if pressure_headlines.size() > 1:
		_append_region_event("风险抬头", str(pressure_headlines[1]), Color8(196, 148, 214), seen, "risk")
	_append_region_event("主线播报", _story_line(narrative.get("grassland_chain", narrative.get("wetland_chain", []))), Color8(170, 224, 198), seen, "focus")
	_append_region_event("捕食播报", _story_line(narrative.get("predation", [])), Color8(214, 132, 132), seen, "predation")
	_append_region_event("领地播报", _story_line(narrative.get("territory", [])), Color8(196, 148, 214), seen, "territory")
	_append_region_event("趋势播报", _story_line(narrative.get("social_trends", [])), Color8(124, 176, 224), seen, "trend")
	_append_region_event("共生播报", _story_line(narrative.get("symbiosis", [])), Color8(210, 182, 96), seen, "symbiosis")
	_append_region_event("腐食播报", _story_line(narrative.get("carrion_chain", [])), Color8(184, 186, 122), seen, "carrion")


func _append_biome_event_chain(seen: Dictionary) -> void:
	for event_variant in _biome_event_specs():
		var event: Dictionary = event_variant
		_append_region_event(
			str(event.get("title", "现场生态")),
			str(event.get("body", "")),
			event.get("accent", Color8(170, 224, 198)),
			seen,
			str(event.get("tag", "focus"))
		)


func _biome_event_specs() -> Array:
	match _biome_key():
		"wetland":
			return [
				{"title": "湿地现场", "body": "浅水边缘会聚集水域动物和飞行动物，先看水位，再看芦苇带通行。", "accent": Color8(116, 196, 190), "tag": "water"},
				{"title": "芦苇动线", "body": "芦苇带不是装饰，它决定动物能否从水眼安全移动到庇护区。", "accent": Color8(138, 206, 148), "tag": "symbiosis"},
			]
		"forest":
			return [
				{"title": "森林现场", "body": "密林会让动物更分散，优先找林下水洼、倒木和荫蔽边缘。", "accent": Color8(112, 178, 116), "tag": "habitat"},
				{"title": "庇护窗口", "body": "森林任务重点不是追速度，而是确认庇护点是否能稳定承接动物停留。", "accent": Color8(154, 206, 132), "tag": "symbiosis"},
			]
		"coast":
			return [
				{"title": "海岸现场", "body": "潮线会改变动物停留位置，先看潮汐水线，再看礁岩和漂上海滩。", "accent": Color8(118, 186, 220), "tag": "water"},
				{"title": "海岸通道", "body": "海岸区的连接价值来自潮间带和防风林缘，通道线会优先验证出口。", "accent": Color8(210, 190, 128), "tag": "territory"},
			]
		_:
			return [
				{"title": "草原现场", "body": "草食群会在迁徙带和水洼之间移动，先记录迁徙动物，再采样补给点。", "accent": Color8(220, 194, 112), "tag": "territory"},
				{"title": "掠食压力", "body": "掠食者会压迫迁徙带边缘，观察追猎能补强后端的捕食压力判断。", "accent": Color8(222, 132, 104), "tag": "predation"},
			]


func _apply_region_entry_prompt() -> void:
	_apply_world_task_entry_prompt()
	var reports := _load_expedition_reports()
	var report: Dictionary = reports.get(current_region_id, {})
	if report.is_empty():
		return
	incoming_handoff = _incoming_handoff_context(reports)
	var channel := str(report.get("top_intel_channel", "未分类"))
	var window_title := str(report.get("event_window_title", "当前窗口"))
	var archive_tier := str(report.get("archive_tier", "初勘档案"))
	var archive_progress := int(report.get("archive_progress", 0))
	var strategy := _archive_entry_strategy_note(report)
	var incoming_note := str(incoming_handoff.get("note", ""))
	var backbone_note := _region_backbone_entry_note()
	var handoff_prefix := ""
	if incoming_note != "":
		handoff_prefix = incoming_note + " "
	var first_segment_note := _region_first_segment_entry_note(report)
	var prompt_title := "区域承接"
	var backbone_completion_tag := str(report.get("backbone_completion_tag", ""))
	if backbone_completion_tag != "":
		prompt_title = "骨干巩固"
	var prompt := {
		"title": prompt_title,
		"body": "%s上次在这里带回的是%s · %s。当前已建立%s（进度 %d），这轮优先沿%s线推进。%s%s%s" % [
			handoff_prefix,
			channel,
			window_title,
			archive_tier,
			archive_progress,
			channel,
			first_segment_note,
			backbone_note,
			strategy,
		],
		"accent": Color8(210, 182, 96),
		"tag": "handoff",
	}
	region_event_chain.insert(0, prompt)


func _ensure_world_task_request() -> void:
	if not entry_request.is_empty() and str(entry_request.get("region_id", "")) == current_region_id:
		return
	var gameplay_hint: Dictionary = region_detail.get("gameplay_hint", {})
	var action := str(gameplay_hint.get("action", "调查"))
	if action not in ["调查", "修复", "通道"]:
		action = _fallback_region_action()
	entry_request = {
		"schema_version": 1,
		"created_at": Time.get_datetime_string_from_system(),
		"region_id": current_region_id,
		"region_name": str(region_detail.get("name", current_region_id)),
		"recommended_action": action,
		"gameplay_hint": gameplay_hint,
		"source": "region_gameplay_hint",
	}


func _fallback_region_action() -> String:
	var hazard := _top_hazard(region_detail.get("hazard_state", {}))
	var health: Dictionary = region_detail.get("health_state", {})
	if float(hazard.get("value", 0.0)) >= 0.55:
		return "修复"
	if float(health.get("biodiversity", 0.0)) < 0.60 or float(health.get("resilience", 0.0)) < 0.60:
		return "调查"
	var frontier_links: Array = region_detail.get("frontier_links", [])
	if not frontier_links.is_empty() and float(frontier_links[0].get("strength", 0.0)) < 0.80:
		return "通道"
	return "调查"


func _top_hazard(hazard_state: Dictionary) -> Dictionary:
	var top_key := ""
	var top_value := -1.0
	for key in hazard_state.keys():
		var value := float(hazard_state.get(key, 0.0))
		if value > top_value:
			top_key = str(key)
			top_value = value
	return {"key": top_key, "value": maxf(top_value, 0.0)}


func _apply_world_task_entry_prompt() -> void:
	if entry_request.is_empty():
		return
	var gameplay_hint: Dictionary = entry_request.get("gameplay_hint", {})
	var action := str(entry_request.get("recommended_action", gameplay_hint.get("action", "调查")))
	var reason := str(gameplay_hint.get("reason", "按世界图推荐目标执行本轮调查。"))
	var target_region_id := str(gameplay_hint.get("target_region_id", ""))
	var chapter := str(gameplay_hint.get("mainline_chapter", ""))
	var objective := str(gameplay_hint.get("mainline_objective", ""))
	var chapter_goal := str(gameplay_hint.get("mainline_chapter_goal", ""))
	var chapter_payoff := str(gameplay_hint.get("mainline_chapter_payoff", ""))
	var body := "世界图推荐：%s。%s" % [action, reason]
	if chapter != "" and objective != "":
		body = "%s · %s 本轮执行：%s。%s" % [chapter, objective, action, reason]
	world_task = {
		"title": "世界任务",
		"body": body,
		"accent": Color8(210, 182, 96),
		"action": action,
		"reason": reason,
		"mainline_chapter": chapter,
		"mainline_objective": objective,
		"mainline_chapter_goal": chapter_goal,
		"mainline_chapter_payoff": chapter_payoff,
		"target_region_id": target_region_id,
	}
	region_event_chain.insert(0, world_task)


func _region_first_segment_entry_note(report: Dictionary) -> String:
	var management_phase := str(report.get("management_rotation_phase", "常规经营"))
	var handoff_streak := int(report.get("handoff_completion_streak", 0))
	var backbone_tag := _region_management_backbone_tag()
	var backbone_streak := _region_backbone_completion_streak()
	if management_phase == "主经营第一段":
		if backbone_tag != "" and backbone_streak >= 2:
			return "这片区当前是经营轮换第一站，而且%s已经连成 %d 轮，开局就该直压主力目标组。 " % [backbone_tag, backbone_streak]
		if handoff_streak >= 3:
			return "这片区当前是经营轮换第一站，而且承接已经连成 %d 轮，优先直压主热点。 " % handoff_streak
		if handoff_streak >= 1:
			return "这片区当前是经营轮换第一站，优先先把第一批主线样本接稳。 "
	if management_phase in ["单区快取主经营", "单区深挖主经营"]:
		if backbone_tag != "" and backbone_streak >= 2:
			return "这片区当前是单区主经营站，而且%s已经跑成 %d 轮，本轮直接沿主力目标组推进。 " % [backbone_tag, backbone_streak]
		return "这片区当前是单区主经营站，本轮先沿默认主线拿稳关键样本。 "
	return ""


func _region_backbone_completed() -> bool:
	var report := _region_identity_report()
	if report.is_empty():
		return false
	if not bool(report.get("backbone_completed", false)):
		return false
	return str(report.get("management_backbone_tag", "")) == _region_management_backbone_tag()


func _region_backbone_completion_streak() -> int:
	if not _region_backbone_completed():
		return 0
	var report := _region_identity_report()
	return int(report.get("backbone_completion_streak", 0))


func _region_backbone_entry_note() -> String:
	var backbone_tag := _region_management_backbone_tag()
	var backbone_streak := _region_backbone_completion_streak()
	if backbone_tag == "":
		return ""
	if backbone_streak >= 3:
		return "这片区已经形成%s，并且连成 %d 轮。 " % [backbone_tag, backbone_streak]
	if _region_backbone_completed():
		return "这片区已经形成%s，本轮可以直接按主力目标组推进。 " % backbone_tag
	return ""


func _incoming_handoff_context(reports: Dictionary) -> Dictionary:
	var latest_report: Dictionary = reports.get("_last", {})
	if latest_report.is_empty():
		return {}
	if str(latest_report.get("target_region_id", "")) != current_region_id:
		return {}
	var source_region := str(latest_report.get("region_name", latest_report.get("region_id", "")))
	if source_region == "" or source_region == current_region_id:
		return {}
	var source_channel := str(latest_report.get("top_intel_channel", "未分类"))
	var source_window := str(latest_report.get("event_window_title", "当前窗口"))
	var source_phase := str(latest_report.get("management_rotation_phase", "常规经营"))
	var first_segment_completed := bool(latest_report.get("first_segment_completed", false))
	var second_segment_completed := bool(latest_report.get("second_segment_completed", false))
	var branch_completed := bool(latest_report.get("branch_completed", false))
	var branch_completion_tag := str(latest_report.get("branch_completion_tag", "非分支段"))
	var branch_mode := ""
	var management_tag := str(latest_report.get("management_priority_tag", "常规经营区"))
	var route_lock_tag := str(latest_report.get("route_lock_tag", "未锁定"))
	var specialization_mode := str(latest_report.get("specialization_mode", "基础线"))
	var note := "你刚从%s转入这里，上轮带回的是%s · %s（%s）。" % [source_region, source_channel, source_window, source_phase]
	if first_segment_completed:
		note = "你刚从%s转入这里，上轮已经把第一站跑成，带回的是%s · %s（%s）。" % [source_region, source_channel, source_window, source_phase]
	if second_segment_completed:
		if management_tag in ["主力深挖经营区", "重点深挖经营区"] or route_lock_tag == "深挖锁定" or specialization_mode == "深挖线":
			branch_mode = "deep_expand"
			note = "你刚从%s转入这里，上轮已经把第二段接稳，当前进入深挖扩线段。" % source_region
		elif management_tag in ["主力快取经营区", "重点快取经营区"] or route_lock_tag == "快取锁定" or specialization_mode == "快取线":
			branch_mode = "quick_close"
			note = "你刚从%s转入这里，上轮已经把第二段接稳，当前进入快取收束段。" % source_region
	if branch_completed:
		if branch_mode == "deep_expand":
			note = "你刚从%s转入这里，上轮已%s，当前继续执行深挖扩线后续段。" % [source_region, branch_completion_tag]
		elif branch_mode == "quick_close":
			note = "你刚从%s转入这里，上轮已%s，当前继续执行快取收束后续段。" % [source_region, branch_completion_tag]
	return {
		"source_region": source_region,
		"channel": source_channel,
		"window": source_window,
		"phase": source_phase,
		"first_segment_completed": first_segment_completed,
		"second_segment_completed": second_segment_completed,
		"branch_completed": branch_completed,
		"branch_completion_tag": branch_completion_tag,
		"branch_mode": branch_mode,
		"note": note,
	}


func _active_handoff_task() -> Dictionary:
	if handoff_task_completed or survey_progress > 0.0 or specialization_chain_bonus_claimed:
		return {}
	var backbone_task := _active_backbone_consolidation_task()
	if not backbone_task.is_empty():
		return backbone_task
	if incoming_handoff.is_empty():
		return {}
	var first_segment_completed := bool(incoming_handoff.get("first_segment_completed", false))
	var second_segment_completed := bool(incoming_handoff.get("second_segment_completed", false))
	var branch_completed := bool(incoming_handoff.get("branch_completed", false))
	var branch_mode := str(incoming_handoff.get("branch_mode", ""))
	var branch_stability_tag := _region_branch_stability_tag()
	var title := "第二段任务" if first_segment_completed else "承接任务"
	var body := ""
	if second_segment_completed and branch_mode == "deep_expand":
		title = "扩线后续任务" if branch_completed else "扩线任务"
		body = "从%s转入 · 上轮%s，当前进入深挖扩线段。先压主线复核，再补第二复核点和对应样本，把经营线继续往外推。" % [
			str(incoming_handoff.get("source_region", "上一段区域")),
			str(incoming_handoff.get("branch_completion_tag", "第二段已接稳")),
		]
	elif second_segment_completed and branch_mode == "quick_close":
		title = "收束后续任务" if branch_completed else "收束任务"
		body = "从%s转入 · 上轮%s，当前进入快取收束段。先拿关键样本和高值速查点，再准备短线撤离。" % [
			str(incoming_handoff.get("source_region", "上一段区域")),
			str(incoming_handoff.get("branch_completion_tag", "第二段已接稳")),
		]
	elif first_segment_completed:
		body = "从%s转入 · 上轮第一站已跑成，带回%s · %s（%s）。这轮直接执行第二段：先沿当前主线拿到第一批落地样本，再按本区决定快取还是深挖。" % [
			str(incoming_handoff.get("source_region", "上一段区域")),
			str(incoming_handoff.get("channel", "未分类")),
			str(incoming_handoff.get("window", "当前窗口")),
			str(incoming_handoff.get("phase", "常规经营")),
		]
	else:
		body = "从%s转入 · 上轮带回%s · %s（%s）。先沿当前主线找到第一批承接样本，再决定是快取还是深挖。" % [
			str(incoming_handoff.get("source_region", "上一段区域")),
			str(incoming_handoff.get("channel", "未分类")),
			str(incoming_handoff.get("window", "当前窗口")),
			str(incoming_handoff.get("phase", "常规经营")),
		]
	if branch_stability_tag == "稳定扩线区":
		body += " 当前区已稳定成扩线区，主线复核和第二复核点会更早成型。"
	elif branch_stability_tag == "扩线塑形中":
		body += " 当前区正在扩线塑形，优先把主热点和后续复核点接稳。"
	elif branch_stability_tag == "稳定收束区":
		body += " 当前区已稳定成收束区，高值速查点会更早打开，接稳后应短线撤离。"
	elif branch_stability_tag == "收束塑形中":
		body += " 当前区正在收束塑形，优先吃主速查点再准备收束。"
	return {
		"title": title,
		"body": body,
		"accent": Color8(210, 182, 96),
	}


func _active_backbone_consolidation_task() -> Dictionary:
	var report := _region_identity_report()
	if report.is_empty():
		return {}
	var backbone_tag := str(report.get("management_backbone_tag", ""))
	var backbone_completion_tag := str(report.get("backbone_completion_tag", ""))
	if backbone_tag == "":
		return {}
	var backbone_streak := int(report.get("backbone_completion_streak", 0))
	var body := ""
	match backbone_tag:
		"快取经营骨干区":
			body = "这片区已经进入%s，当前应先拿主力速查组和关键样本，再按短推进节奏准备撤离。" % [backbone_completion_tag if backbone_completion_tag != "" else backbone_tag]
			if backbone_streak >= 3:
				body += " 连成 %d 轮后，开局就该直压主速查点。" % backbone_streak
		"深挖经营骨干区":
			body = "这片区已经进入%s，当前应先压主力主复核，再补主力次复核和对应样本。" % [backbone_completion_tag if backbone_completion_tag != "" else backbone_tag]
			if backbone_streak >= 3:
				body += " 连成 %d 轮后，开局就该直接拉起整条主力复核链。" % backbone_streak
		_:
			return {}
	return {
		"title": "巩固任务",
		"body": body,
		"accent": Color8(210, 182, 96),
	}


func _maybe_complete_handoff(trigger_label: String, channel: String) -> void:
	if incoming_handoff.is_empty() or handoff_task_completed:
		return
	handoff_task_completed = true
	var first_segment_completed := bool(incoming_handoff.get("first_segment_completed", false))
	var second_segment_completed := bool(incoming_handoff.get("second_segment_completed", false))
	var branch_mode := str(incoming_handoff.get("branch_mode", ""))
	var branch_bonus := _branch_mode_completion_bonus(branch_mode, channel)
	var completion_label := "承接完成"
	if second_segment_completed and branch_mode == "deep_expand":
		completion_label = "扩线接稳"
	elif second_segment_completed and branch_mode == "quick_close":
		completion_label = "收束接稳"
	elif first_segment_completed:
		completion_label = "第二段接稳"
	discovery_log.push_front("%s：%s · %s线已接上" % [completion_label, trigger_label, channel])
	discovery_log = discovery_log.slice(0, 6)
	var title := completion_label
	var body := ""
	if second_segment_completed and branch_mode == "deep_expand":
		body = "已用%s把深挖扩线段接稳，当前%s调查已经落地。本轮接下来继续按%s往外扩线。" % [
			trigger_label,
			channel,
			_region_specialization_mode(),
		]
	elif second_segment_completed and branch_mode == "quick_close":
		body = "已用%s把快取收束段接稳，当前%s调查已经落地。本轮接下来按%s完成收束。" % [
			trigger_label,
			channel,
			_region_specialization_mode(),
		]
	elif first_segment_completed:
		body = "已用%s把第二段经营线接稳，当前%s调查已经落地。本轮接下来按%s继续推进。" % [
			trigger_label,
			channel,
			_region_specialization_mode(),
		]
	else:
		body = "已用%s接上跨区经营线，当前%s调查已经落地。本轮接下来按%s继续推进。" % [
			trigger_label,
			channel,
			_region_specialization_mode(),
		]
	if branch_bonus > 0:
		hotspot_intel_score += branch_bonus
		intel_breakdown[channel] = int(intel_breakdown.get(channel, 0)) + branch_bonus
		var branch_bonus_label := "分支奖励"
		if branch_mode == "deep_expand":
			branch_bonus_label = "扩线奖励"
		elif branch_mode == "quick_close":
			branch_bonus_label = "收束奖励"
		discovery_log.push_front("%s：%s +%d" % [completion_label, branch_bonus_label, branch_bonus])
		discovery_log = discovery_log.slice(0, 6)
		body += " %s +%d。" % [branch_bonus_label, branch_bonus]
	current_task = {
		"title": title,
		"body": body,
		"accent": Color8(198, 222, 160),
	}


func _archive_entry_strategy_note(report: Dictionary) -> String:
	var shaping_tag := _region_route_shaping_tag()
	var lock_tag := _region_route_lock_tag()
	var management_tag := _region_management_priority_tag()
	var management_rotation := _region_management_rotation_note()
	var management_prefix := ""
	if management_tag != "常规经营区":
		management_prefix = "%s，" % management_tag
	match str(report.get("archive_tier", "初勘档案")):
		"定型档案":
			return "%s这片区已经定型，适合按既有档案直接压主线和高值复核。当前%s / %s。%s" % [management_prefix, shaping_tag, lock_tag, management_rotation]
		"熟悉档案":
			return "%s这片区已经熟悉，开局就能更快补主线样本。当前%s / %s。%s" % [management_prefix, shaping_tag, lock_tag, management_rotation]
		"已知档案":
			return "%s这片区已有稳定记录，适合顺着既有线索继续推进。当前%s / %s。%s" % [management_prefix, shaping_tag, lock_tag, management_rotation]
		_:
			return "%s这片区仍在初勘阶段，先补足基础样本。当前%s / %s。%s" % [management_prefix, shaping_tag, lock_tag, management_rotation]


func _append_region_event(title: String, body: String, accent: Color, seen: Dictionary, tag: String) -> void:
	var cleaned := body.strip_edges()
	if cleaned == "" or seen.has(cleaned):
		return
	seen[cleaned] = true
	region_event_chain.append(
		{
			"title": title,
			"body": cleaned,
			"accent": accent,
			"tag": tag,
		}
	)


func _story_line(rows: Array) -> String:
	if rows.is_empty():
		return ""
	var first = rows[0]
	if typeof(first) == TYPE_STRING:
		return str(first)
	if typeof(first) == TYPE_DICTIONARY:
		for key in ["summary", "line", "headline", "label", "text", "body", "description"]:
			if first.has(key):
				return str(first.get(key, ""))
	return str(first)


func _active_region_event() -> Dictionary:
	if region_event_chain.is_empty():
		return {}
	return region_event_chain[region_event_index % region_event_chain.size()]


func _active_region_event_tag() -> String:
	return str(_active_region_event().get("tag", ""))


func _update_reward_feedback(delta: float) -> void:
	if reward_feedback_timer <= 0.0:
		return
	reward_feedback_timer = maxf(0.0, reward_feedback_timer - delta)
	if reward_feedback_timer <= 0.0:
		reward_feedback.clear()


func _update_expedition_state() -> void:
	var threat_target := 0.0
	var pressure_state: Dictionary = region_detail.get("ecological_pressures", {})
	threat_target = maxf(threat_target, float(pressure_state.get("predation_load", 0.0)) * 0.42)
	threat_target = maxf(threat_target, float(pressure_state.get("collapse_pressure", 0.0)) * 0.78)
	for animal in wildlife:
		if str(animal.get("category", "")) != "掠食者":
			continue
		var distance := player_pos.distance_to(animal.get("position", Vector2.ZERO))
		if distance < 320.0:
			threat_target = maxf(threat_target, inverse_lerp(320.0, 70.0, distance))
	if not current_interaction.is_empty():
		threat_target = maxf(threat_target, 0.68)
	if not current_chase.is_empty():
		threat_target = maxf(threat_target, 0.92)
	if not current_chase_result.is_empty():
		threat_target = maxf(threat_target, 0.56)
	threat_target = clampf(threat_target + _active_event_threat_bias(), 0.0, 1.0)
	nearby_threat_level = lerpf(nearby_threat_level, threat_target, 0.18)
	var world_action := str(world_task.get("action", ""))
	var world_task_ready := world_action != "通道" and _world_task_completed({})
	extraction_ready = world_task_ready or _expedition_intel_points() >= _required_extraction_intel() or (completed_task_ids.size() >= 1 and discovered_species_ids.size() >= 2 and _required_extraction_intel() <= 4)
	if world_task_ready and not world_task_completion_notified:
		world_task_completion_notified = true
		_show_reward_feedback(
			"主线目标完成",
			_world_task_progress_label(world_action),
			"现在前往出口按 E，回世界图点击回灌报告。",
			Color8(238, 204, 112)
		)
	expedition_phase = _current_expedition_phase()


func _required_extraction_intel() -> int:
	var report := _region_identity_report()
	var visit_count := int(report.get("visit_count", 0))
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var current_channel := _top_intel_channel()
	var threshold := 4
	if visit_count >= 5:
		threshold = 3 if dominant_channel != "" and dominant_channel == current_channel else 5
	elif visit_count >= 3:
		threshold = 4
	var specialization_mode := _region_specialization_mode()
	if dominant_channel != "" and dominant_channel == current_channel:
		if specialization_mode == "快取线":
			threshold -= 1
		elif specialization_mode == "深挖线":
			threshold += 1
	match _region_archive_tier():
		"已知档案":
			if dominant_channel != "" and dominant_channel == current_channel:
				threshold -= 1
		"熟悉档案":
			threshold -= 1
		"定型档案":
			threshold -= 1 if specialization_mode != "深挖线" else 0
	match _region_archive_route_mode():
		"short":
			if specialization_chain_bonus_claimed:
				threshold -= 1
		"deep":
			if not specialization_chain_bonus_claimed:
				threshold += 1
	match _region_route_shaping_tag():
		"快取塑形稳固":
			if _region_archive_route_mode() == "short":
				threshold -= 1
		"深挖塑形稳固":
			if _region_archive_route_mode() == "deep" and not specialization_chain_bonus_claimed:
				threshold += 1
	match _region_route_lock_tag():
		"快取锁定":
			if specialization_chain_bonus_claimed:
				threshold -= 1
		"深挖锁定":
			if not specialization_chain_bonus_claimed:
				threshold += 1
	return clampi(threshold, 2, 6)


func _active_event_threat_bias() -> float:
	match _active_region_event_tag():
		"pressure":
			return 0.12
		"risk":
			return 0.16
		"predation":
			return 0.18
		"territory":
			return 0.08
		"symbiosis":
			return -0.06
		_:
			return 0.0


func _expedition_intel_points() -> int:
	return species_intel_score + hotspot_intel_score + int(witnessed_pressure) + int(witnessed_chase_result)


func _current_expedition_phase() -> String:
	if extraction_ready:
		return "撤离"
	if completed_task_ids.size() >= 1 or discovered_species_ids.size() >= 2:
		return "记录"
	return "追踪"


func _threat_label() -> String:
	if nearby_threat_level >= 0.82:
		return "极高"
	if nearby_threat_level >= 0.58:
		return "高"
	if nearby_threat_level >= 0.32:
		return "中"
	return "低"


func _region_state_label() -> String:
	var health_state: Dictionary = region_detail.get("health_state", {})
	var resilience := float(health_state.get("resilience", 0.0))
	var collapse_risk := float(health_state.get("collapse_risk", 0.0))
	var stability := float(health_state.get("stability", 0.0))
	if collapse_risk >= 0.58:
		return "崩塌边缘"
	if resilience >= 0.72 and collapse_risk <= 0.18:
		return "恢复窗口"
	if stability >= 0.45:
		return "稳态区"
	return "脆弱区"


func _chain_focus_text() -> String:
	var focus: Array = region_detail.get("chain_focus", [])
	if focus.is_empty():
		return "区域主线未明确，优先靠近水源与迁徙带。"
	return str(focus[0])


func _species_intel_reward(animal: Dictionary) -> int:
	var base := 1
	match str(animal.get("category", "")):
		"掠食者":
			base = 3
		"飞行动物":
			base = 2
		"水域动物":
			base = 2
		_:
			base = 1
	var scaled := maxi(1, int(round(float(base) * _active_event_species_reward_multiplier(animal))))
	var channel := _species_intel_channel(animal)
	return scaled + _identity_chain_bonus_for_channel(channel, "species") + _first_segment_handoff_reward_bonus(channel, "species") + _branch_followup_reward_bonus(channel, "species") + _management_backbone_reward_bonus(channel, "species")


func _active_event_species_reward_multiplier(animal: Dictionary) -> float:
	match _active_region_event_tag():
		"predation":
			return 1.45 if str(animal.get("category", "")) == "掠食者" else 1.0
		"pressure":
			return 1.30 if str(animal.get("category", "")) == "掠食者" else 1.0
		"territory":
			return 1.25 if str(animal.get("category", "")) == "草食动物" else 1.0
		"carrion":
			return 1.35 if str(animal.get("category", "")) == "飞行动物" else 1.0
		"symbiosis":
			return 1.25 if str(animal.get("category", "")) == "区域生物" else 1.0
		"focus":
			if hotspots.is_empty():
				return 1.0
			return 1.20 if str(animal.get("anchor_id", "")) == str(hotspots[0].get("hotspot_id", "")) else 1.0
		_:
			return 1.0


func _species_intel_channel(animal: Dictionary) -> String:
	match str(animal.get("category", "")):
		"掠食者":
			return "压迫"
		"飞行动物":
			return "腐食"
		"水域动物":
			return "水源"
		"草食动物":
			return "迁徙"
		_:
			return "栖地"


func _hotspot_intel_reward(hotspot: Dictionary) -> int:
	var intensity := float(hotspot.get("intensity", 0.0))
	var channel := _hotspot_intel_channel(hotspot)
	return maxi(2, int(round(intensity * 4.0)) + 1 + _active_event_hotspot_bonus(hotspot) + _identity_special_hotspot_bonus(hotspot) + _identity_chain_bonus_for_channel(channel, "hotspot") + _run_profile_hotspot_bonus(hotspot) + _archive_hotspot_bonus(channel) + _archive_strategy_hotspot_bonus(hotspot) + _region_route_shaping_bonus() + _region_lock_completion_bonus() + _first_segment_handoff_reward_bonus(channel, "hotspot") + _branch_followup_reward_bonus(channel, "hotspot") + _management_backbone_reward_bonus(channel, "hotspot", str(hotspot.get("hotspot_id", ""))))


func _management_backbone_reward_bonus(channel: String, source_kind: String, hotspot_id: String = "") -> int:
	var backbone_tag := _region_management_backbone_tag()
	var target_channel := _region_specialization_target_channel()
	match backbone_tag:
		"快取经营骨干区":
			if channel != target_channel:
				return 0
			if source_kind == "hotspot" and hotspot_id == _specialization_target_hotspot_id():
				return 3
			return 2 if source_kind == "species" else 1
		"深挖经营骨干区":
			if channel != target_channel:
				return 0
			if source_kind == "hotspot":
				if hotspot_id == _specialization_target_hotspot_id():
					return 3
				if hotspot_id == _specialization_followup_hotspot_id():
					return 2
				return 1
			return 2
		_:
			return 0


func _first_segment_handoff_reward_bonus(channel: String, source_kind: String) -> int:
	if incoming_handoff.is_empty() or handoff_task_completed:
		return 0
	var report := _region_identity_report()
	var management_phase := str(report.get("management_rotation_phase", "常规经营"))
	if management_phase not in ["主经营第一段", "单区快取主经营", "单区深挖主经营"]:
		return 0
	var bonus := 1
	if channel == _region_specialization_target_channel():
		bonus += 1
	var handoff_streak := int(report.get("handoff_completion_streak", 0))
	if handoff_streak >= 2:
		bonus += 1
	if source_kind == "hotspot" and _region_specialization_mode() == "深挖线" and channel == _region_specialization_target_channel():
		bonus += 1
	return bonus


func _branch_mode_completion_bonus(branch_mode: String, channel: String) -> int:
	var bonus := 0
	match branch_mode:
		"deep_expand":
			bonus = 4
			if channel == _region_specialization_target_channel():
				bonus += 1
		"quick_close":
			bonus = 3
			if channel == _region_specialization_target_channel():
				bonus += 1
		_:
			bonus = 0
	return bonus


func _branch_followup_reward_bonus(channel: String, source_kind: String) -> int:
	if incoming_handoff.is_empty() or handoff_task_completed:
		return 0
	if not bool(incoming_handoff.get("branch_completed", false)):
		return 0
	var branch_mode := str(incoming_handoff.get("branch_mode", ""))
	var bonus := 0
	match branch_mode:
		"deep_expand":
			bonus = 2 if source_kind == "hotspot" else 1
			if channel == _region_specialization_target_channel():
				bonus += 1
			if source_kind == "hotspot" and channel == _region_specialization_target_channel():
				bonus += 1
		"quick_close":
			bonus = 2
			if channel == _region_specialization_target_channel():
				bonus += 1
		_:
			bonus = 0
	return bonus


func _archive_hotspot_bonus(channel: String) -> int:
	var dominant_channel := str(_region_identity_report().get("dominant_intel_channel", ""))
	if dominant_channel == "" or channel != dominant_channel:
		return 0
	match _region_archive_tier():
		"熟悉档案":
			return 1
		"定型档案":
			return 2
		_:
			return 0


func _archive_strategy_hotspot_bonus(hotspot: Dictionary) -> int:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	if _archive_has_stable_quicktake_window() and hotspot_id == _specialization_target_hotspot_id():
		return 2 if _region_archive_tier() == "定型档案" else 1
	if _archive_has_stable_followup_chain() and hotspot_id == _specialization_followup_hotspot_id():
		return 2 if _region_archive_tier() == "定型档案" else 1
	if _region_route_style() == "quick" and _region_route_style_streak() >= 3 and hotspot_id == _specialization_target_hotspot_id():
		return 1
	if _region_route_style() == "deep" and _region_route_style_streak() >= 3 and hotspot_id == _specialization_followup_hotspot_id():
		return 1
	return 0


func _active_event_hotspot_bonus(hotspot: Dictionary) -> int:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	match _active_region_event_tag():
		"predation":
			return 2 if hotspot_id == "predator_ridge" else 0
		"carrion":
			return 2 if hotspot_id == "carrion_field" else 0
		"territory":
			return 2 if hotspot_id == "migration_corridor" else 0
		"symbiosis":
			return 2 if hotspot_id == "shade_grove" else 0
		"focus":
			if hotspots.is_empty():
				return 0
			return 1 if hotspot_id == str(hotspots[0].get("hotspot_id", "")) else 0
		_:
			return 0


func _identity_special_hotspot_bonus(hotspot: Dictionary) -> int:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 5:
		return 0
	match dominant_channel:
		"水源":
			return 2 if str(hotspot.get("hotspot_id", "")) == "waterhole" else 0
		"迁徙":
			return 2 if str(hotspot.get("hotspot_id", "")) == "migration_corridor" else 0
		"压迫":
			return 2 if str(hotspot.get("hotspot_id", "")) == "predator_ridge" else 0
		"腐食":
			return 2 if str(hotspot.get("hotspot_id", "")) == "carrion_field" else 0
		"栖地":
			return 2 if str(hotspot.get("hotspot_id", "")) == "shade_grove" else 0
		_:
			return 0


func _identity_special_hotspot_note(hotspot: Dictionary) -> String:
	var bonus := _identity_special_hotspot_bonus(hotspot)
	if bonus <= 0:
		return ""
	var report := _region_identity_report()
	return " · 高价值复核 · 额外情报 +%d (%s)" % [bonus, str(report.get("dominant_intel_channel", "主线"))]


func _hotspot_intel_channel(hotspot: Dictionary) -> String:
	match str(hotspot.get("hotspot_id", "")):
		"waterhole":
			return "水源"
		"migration_corridor":
			return "迁徙"
		"predator_ridge":
			return "压迫"
		"carrion_field":
			return "腐食"
		_:
			return "栖地"


func _top_intel_channel() -> String:
	var best_key := "栖地"
	var best_value := -1
	for key in intel_breakdown.keys():
		var value := int(intel_breakdown[key])
		if value > best_value:
			best_value = value
			best_key = str(key)
	return best_key


func _exit_event_body() -> String:
	if extraction_ready:
		return "%s 已到达 · %s" % [str(current_exit_zone.get("label", "区域出口")), _exit_value_text(current_exit_zone, true)]
	return "%s 已到达 · %s" % [str(current_exit_zone.get("label", "区域出口")), _exit_value_text(current_exit_zone, false)]


func _exit_value_text(zone: Dictionary, ready: bool) -> String:
	var target_region_id := str(zone.get("target_region_id", ""))
	var target_detail: Dictionary = world_data.get("region_details", {}).get(target_region_id, {})
	var target_name := str(target_detail.get("name", zone.get("label", "下一片区域")))
	var target_health: Dictionary = target_detail.get("health_state", {})
	var target_risk := float(target_health.get("collapse_risk", 0.0))
	var target_resilience := float(target_health.get("resilience", 0.0))
	var event_note := _active_event_exit_note() + _run_profile_exit_note()
	var rotation_note := _region_management_rotation_note()
	var route_mode := _region_archive_route_mode()
	var route_lock := _region_route_lock_tag()
	var backbone_tag := _region_management_backbone_tag()
	var branch_mode := str(incoming_handoff.get("branch_mode", ""))
	var branch_completed := bool(incoming_handoff.get("branch_completed", false))
	var branch_stability_tag := _region_branch_stability_tag()
	var world_task_note := _world_task_exit_note(zone)
	if ready:
		if world_task_note != "":
			return "%s 可以从这里撤离，报告会把%s标记为下一站。%s" % [world_task_note, target_name, event_note]
		if backbone_tag == "快取经营骨干区" and handoff_task_completed:
			return "这片区已经是快取经营骨干区，主力速查组和关键样本都已到手，现在就是最优短线撤离点，建议立刻把结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if backbone_tag == "深挖经营骨干区" and handoff_task_completed:
			return "这片区已经是深挖经营骨干区，主复核和次复核链都已接稳，现在撤离价值最高，建议把整条复核结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if branch_stability_tag == "稳定收束区" and handoff_task_completed:
			return "这片区已稳定成收束区，关键样本和速查点都已接稳，现在就是最优短线撤离窗口，建议立刻带着结果去 %s。%s%s" % [target_name, event_note, rotation_note]
		if branch_stability_tag == "稳定扩线区" and handoff_task_completed:
			return "这片区已稳定成扩线区，主线复核链已经落地，现在撤离最值，建议把扩线结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if branch_completed and branch_mode == "quick_close" and handoff_task_completed:
			return "这片区正在承接收束后续段，关键样本和速查点都已接稳，现在就是短线撤离窗口，建议立刻带着结果去 %s。%s%s" % [target_name, event_note, rotation_note]
		if branch_completed and branch_mode == "deep_expand" and handoff_task_completed:
			return "这片区正在承接扩线后续段，主线复核和跟进样本都已落地，现在撤离最值，建议把扩线结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if route_lock == "快取锁定" and specialization_chain_bonus_claimed:
			return "这片区已经锁定为短推进区，现在就是最佳撤离点，拿到关键样本后应立即撤离并把结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if route_lock == "深挖锁定" and specialization_chain_bonus_claimed:
			return "这片区已经锁定为连续复核区，整条深挖链已跑成，现在撤离价值最高，建议把结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if route_mode == "short" and specialization_chain_bonus_claimed:
			return "这片区已进入短推进最佳撤离点，关键样本和专精链都已到手，建议立即撤离并把结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if route_mode == "deep" and specialization_chain_bonus_claimed:
			return "这片区的连续复核链已经跑成，现在撤离最值，建议把整条深挖结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
		if target_resilience >= 0.65 and target_risk <= 0.2:
			return "情报已够，且 %s 是稳定接应区，建议撤离并回灌报告。%s%s" % [target_name, event_note, rotation_note]
		return "情报已够，建议撤离；报告会把这轮结果带去 %s。%s%s" % [target_name, event_note, rotation_note]
	if backbone_tag == "快取经营骨干区":
		return "这片区已经是快取经营骨干区，优先拿主力速查组和关键样本，接稳后就该立即短线撤离。%s%s" % [event_note, rotation_note]
	if backbone_tag == "深挖经营骨干区":
		return "这片区已经是深挖经营骨干区，主复核和次复核链没跑稳前，延后撤离通常更值。%s%s" % [event_note, rotation_note]
	if route_lock == "快取锁定" and specialization_chain_bonus_claimed:
		return "这片区已锁定为短推进区，关键样本到手后应立刻收束撤离。%s%s" % [event_note, rotation_note]
	if route_lock == "深挖锁定" and not specialization_chain_bonus_claimed:
		return "这片区已锁定为连续复核区，主热点、第二复核点和对应样本没补齐前，延后撤离通常更值。%s%s" % [event_note, rotation_note]
	if branch_stability_tag == "稳定收束区":
		return "这片区已稳定成收束区，优先拿关键样本和主速查点，接稳后就该立即短线撤离。%s%s" % [event_note, rotation_note]
	if branch_stability_tag == "稳定扩线区":
		return "这片区已稳定成扩线区，主热点和第二复核点没接稳前，延后撤离通常更值。%s%s" % [event_note, rotation_note]
	if branch_completed and branch_mode == "quick_close" and not handoff_task_completed:
		return "这片区正在承接收束后续段，优先拿关键样本和高值速查点，接稳后就该短线撤离。%s%s" % [event_note, rotation_note]
	if branch_completed and branch_mode == "deep_expand" and not handoff_task_completed:
		return "这片区正在承接扩线后续段，先压主线复核和第二复核点，未接稳前延后撤离更值。%s%s" % [event_note, rotation_note]
	if route_mode == "short" and _archive_has_stable_quicktake_window() and specialization_chain_bonus_claimed:
		return "这片区偏短推进，最佳撤离点已经接近成熟，再补一点就该走。%s%s" % [event_note, rotation_note]
	if route_mode == "deep" and _archive_has_stable_followup_chain():
		return "这片区偏连续复核，若主热点、第二复核点和对应样本还没补齐，可以接受更晚撤离。%s%s" % [event_note, rotation_note]
	if target_risk >= 0.45:
		return "%s 风险也偏高，这轮可以再多拿一点情报再走。%s%s" % [target_name, event_note, rotation_note]
	if world_task_note != "":
		return "%s %s%s" % [world_task_note, event_note, rotation_note]
	return "这轮记录还偏少，但 %s 是安全出口，随时可以保守撤离并回灌报告。%s%s" % [target_name, event_note, rotation_note]


func _world_task_exit_note(zone: Dictionary) -> String:
	var action := str(world_task.get("action", ""))
	if action == "":
		return ""
	if _world_task_completed(zone):
		return "世界任务已完成"
	match action:
		"调查":
			return "世界任务未完成：至少拿到 3 情报、发现 3 种动物，或完成 1 个热点。"
		"修复":
			return "世界任务未完成：需要完成 1 个热点，并把情报提高到 3。"
		"通道":
			var expected_target := str(world_task.get("target_region_id", ""))
			if expected_target != "":
				var expected_detail: Dictionary = world_data.get("region_details", {}).get(expected_target, {})
				return "世界任务未完成：需要从通往%s的出口撤离。" % str(expected_detail.get("name", expected_target))
			return "世界任务未完成：需要从任意有效目标出口撤离。"
		_:
			return ""


func _active_event_exit_note() -> String:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	var specialization_mode := _region_specialization_mode()
	var specialization_note := ""
	if specialization_mode == "快取线":
		specialization_note = "这片区更适合短跑快取，拿到关键样本就走。"
	elif specialization_mode == "深挖线":
		specialization_note = "这片区更适合深挖复核，继续补样的回报更高。"
	match _active_region_event_tag():
		"pressure":
			return "当前压力抬头，久留的边际收益在下降。%s%s" % [("这片压迫调查区更适合带着样本及时转场。" if dominant_channel == "压迫" and visit_count >= 3 else ""), specialization_note]
		"risk":
			return "风险事件正在放大，这轮更适合保守撤出。%s" % specialization_note
		"predation":
			return "捕食线正活跃，如果还要贪情报要接受更高危险。%s%s" % [("这片区已经有较完整压迫档案，继续停留更偏向高风险扩样。" if dominant_channel == "压迫" and visit_count >= 5 else ""), specialization_note]
		"territory":
			return "领地冲突升温，路线窗口可能很快收窄。%s" % specialization_note
		"symbiosis":
			return "共生窗口还开着，可以接受更稳一点的补采样。%s%s" % [("这片栖地调查区适合继续补稳态样本。" if dominant_channel == "栖地" and visit_count >= 3 else ""), specialization_note]
		"carrion":
			return "腐食线活跃，若要补采样优先看腐食热点。%s%s" % [("这片腐食调查区更适合短停快取。" if dominant_channel == "腐食" and visit_count >= 3 else ""), specialization_note]
		_:
			if visit_count >= 5:
				return "按当前区域总态判断撤离值。这片区已有较成熟调查档案，更适合定向扩样。%s" % specialization_note
			return "按当前区域总态判断撤离值。"


func _run_profile_exit_note() -> String:
	match _region_run_profile():
		"快取完成":
			return " 最近几轮这片区更适合短跑快取，这轮拿到关键样本后不必久留。"
		"深挖完成":
			return " 最近几轮这片区更适合深挖复核，若双复核链未跑完可以接受更晚撤离。"
		"快取未完成":
			return " 这片区此前多是快取试探，若关键样本还没拿到，继续贪的性价比不高。"
		"深挖未完成":
			return " 这片区此前多是深挖试探，若主链已起手，继续补完复核回报更高。"
		_:
			return ""


func _record_exit_summary(zone: Dictionary) -> void:
	var zone_label := str(zone.get("label", "区域出口"))
	var summary := "%s撤离：情报 %d · 热点 %d · 危险 %s" % [
		zone_label,
		_expedition_intel_points(),
		completed_task_ids.size(),
		_threat_label(),
	]
	var backbone_summary_tag := _region_backbone_summary_tag()
	if backbone_summary_tag != "":
		summary += " · %s" % backbone_summary_tag
	if not world_task.is_empty():
		summary += " · 世界任务%s" % ("完成" if _world_task_completed(zone) else "未完成")
	discovery_log.push_front(summary)
	discovery_log = discovery_log.slice(0, 6)
	_show_reward_feedback(
		"撤离报告已生成",
		"情报 %d · 热点 %d · 世界任务%s" % [
			_expedition_intel_points(),
			completed_task_ids.size(),
			("完成" if _world_task_completed(zone) else "未完成"),
		],
		"回到世界图：点击回灌报告。",
		Color8(210, 182, 96)
	)
	_write_expedition_report(zone, summary)


func _world_task_completed(zone: Dictionary) -> bool:
	var action := str(world_task.get("action", ""))
	if action == "":
		return false
	match action:
		"调查":
			return discovered_species_ids.size() >= 1 and completed_task_ids.size() >= 1 and _expedition_intel_points() >= _world_task_intel_goal(action)
		"修复":
			return completed_task_ids.size() >= 1 and _expedition_intel_points() >= _world_task_intel_goal(action)
		"通道":
			var expected_target := str(world_task.get("target_region_id", ""))
			var exit_target := str(zone.get("target_region_id", ""))
			if expected_target != "":
				return exit_target == expected_target
			return exit_target != ""
		_:
			return false


func _world_task_intel_goal(action: String) -> int:
	match action:
		"调查":
			return 3
		"修复":
			return 3
		_:
			return _required_extraction_intel()


func _write_expedition_report(zone: Dictionary, summary: String) -> void:
	var reports := _load_expedition_reports()
	var previous: Dictionary = reports.get(current_region_id, {})
	var cumulative_breakdown: Dictionary = previous.get("cumulative_intel_breakdown", {}).duplicate(true) if previous.has("cumulative_intel_breakdown") else {}
	for key in intel_breakdown.keys():
		cumulative_breakdown[key] = int(cumulative_breakdown.get(key, 0)) + int(intel_breakdown.get(key, 0))
	var window_counts: Dictionary = previous.get("window_counts", {}).duplicate(true) if previous.has("window_counts") else {}
	var current_window := _active_region_event_tag()
	window_counts[current_window] = int(window_counts.get(current_window, 0)) + 1
	var specialization_run_counts: Dictionary = previous.get("specialization_run_counts", {}).duplicate(true) if previous.has("specialization_run_counts") else {}
	var current_run_tag := _specialization_run_tag()
	specialization_run_counts[current_run_tag] = int(specialization_run_counts.get(current_run_tag, 0)) + 1
	var current_route_style := _run_style_family(current_run_tag)
	var route_style_counts: Dictionary = previous.get("route_style_counts", {}).duplicate(true) if previous.has("route_style_counts") else {}
	route_style_counts[current_route_style] = int(route_style_counts.get(current_route_style, 0)) + 1
	var previous_route_style := str(previous.get("last_route_style", ""))
	var previous_route_streak := int(previous.get("route_style_streak", 0))
	var route_style_streak := 1
	if current_route_style != "" and current_route_style == previous_route_style:
		route_style_streak = previous_route_streak + 1
	var previous_handoff_completed := bool(previous.get("handoff_completed", false))
	var previous_handoff_streak := int(previous.get("handoff_completion_streak", 0))
	var handoff_completion_count := int(previous.get("handoff_completion_count", 0))
	var handoff_completion_streak := 0
	if handoff_task_completed:
		handoff_completion_count += 1
		handoff_completion_streak = 1
		if previous_handoff_completed:
			handoff_completion_streak = previous_handoff_streak + 1
	var archive_progress := int(previous.get("archive_progress", 0)) + _archive_progress_gain(previous, current_run_tag, route_style_streak)
	archive_progress += _handoff_archive_progress_bonus(handoff_task_completed, handoff_completion_streak, handoff_completion_count)
	var route_lock_tag := _region_route_lock_tag()
	var route_lock_completed := _locked_route_completed()
	var management_backbone_tag := _region_management_backbone_tag()
	var backbone_completed := management_backbone_tag != "" and specialization_chain_bonus_claimed
	var backbone_completion_tag := _region_backbone_summary_tag()
	var backbone_completion_counts: Dictionary = previous.get("backbone_completion_counts", {}).duplicate(true) if previous.has("backbone_completion_counts") else {}
	var previous_backbone_tag := str(previous.get("management_backbone_tag", ""))
	var previous_backbone_completed := bool(previous.get("backbone_completed", false))
	var backbone_completion_streak := 0
	if management_backbone_tag != "" and backbone_completed:
		backbone_completion_counts[management_backbone_tag] = int(backbone_completion_counts.get(management_backbone_tag, 0)) + 1
		backbone_completion_streak = 1
		if previous_backbone_completed and previous_backbone_tag == management_backbone_tag:
			backbone_completion_streak = int(previous.get("backbone_completion_streak", 0)) + 1
	archive_progress += _backbone_archive_progress_bonus(management_backbone_tag, backbone_completed, backbone_completion_streak, backbone_completion_counts)
	var route_lock_counts: Dictionary = previous.get("route_lock_counts", {}).duplicate(true) if previous.has("route_lock_counts") else {}
	if route_lock_tag != "未锁定":
		route_lock_counts[route_lock_tag] = int(route_lock_counts.get(route_lock_tag, 0)) + 1
	var previous_lock_tag := str(previous.get("last_route_lock_tag", ""))
	var previous_lock_completed := bool(previous.get("route_lock_completed", false))
	var lock_completion_streak := 0
	if route_lock_tag != "未锁定" and route_lock_completed:
		lock_completion_streak = 1
		if previous_lock_tag == route_lock_tag and previous_lock_completed:
			lock_completion_streak = int(previous.get("lock_completion_streak", 0)) + 1
	var management_priority_tag := _region_management_priority_tag()
	var management_rotation_phase := _region_management_rotation_phase()
	var first_segment_completed := handoff_task_completed and management_rotation_phase in ["主经营第一段", "单区快取主经营", "单区深挖主经营"]
	var second_segment_completed := handoff_task_completed and bool(incoming_handoff.get("first_segment_completed", false))
	var branch_mode := str(incoming_handoff.get("branch_mode", ""))
	var branch_completed := second_segment_completed and branch_mode in ["deep_expand", "quick_close"]
	var branch_completion_tag := "非分支段"
	if branch_mode == "deep_expand":
		branch_completion_tag = "扩线接稳" if branch_completed else "扩线未接稳"
	elif branch_mode == "quick_close":
		branch_completion_tag = "收束接稳" if branch_completed else "收束未接稳"
	var branch_completion_counts: Dictionary = previous.get("branch_completion_counts", {}).duplicate(true) if previous.has("branch_completion_counts") else {}
	var previous_branch_mode := str(previous.get("branch_mode", ""))
	var previous_branch_completed := bool(previous.get("branch_completed", false))
	var branch_completion_streak := 0
	if branch_mode != "" and branch_completed:
		branch_completion_counts[branch_mode] = int(branch_completion_counts.get(branch_mode, 0)) + 1
		branch_completion_streak = 1
		if previous_branch_completed and previous_branch_mode == branch_mode:
			branch_completion_streak = int(previous.get("branch_completion_streak", 0)) + 1
	var handoff_source_region := str(incoming_handoff.get("source_region", ""))
	var handoff_source_channel := str(incoming_handoff.get("channel", ""))
	var handoff_source_window := str(incoming_handoff.get("window", ""))
	var handoff_source_phase := str(incoming_handoff.get("phase", ""))
	var created_at := Time.get_datetime_string_from_system()
	var report_id := "%s:%s:%d" % [current_region_id, created_at, int(previous.get("visit_count", 0)) + 1]
	var request_hint: Dictionary = entry_request.get("gameplay_hint", {})
	var record := {
		"report_id": report_id,
		"created_at": created_at,
		"region_id": current_region_id,
		"region_name": str(region_detail.get("name", current_region_id)),
		"visit_count": int(previous.get("visit_count", 0)) + 1,
		"archive_progress": archive_progress,
		"archive_tier": _archive_tier_from_progress(archive_progress),
		"phase": expedition_phase,
		"intel": _expedition_intel_points(),
		"cumulative_intel": int(previous.get("cumulative_intel", 0)) + _expedition_intel_points(),
		"species_intel": species_intel_score,
		"hotspot_intel": hotspot_intel_score,
		"risk": _threat_label(),
		"summary": summary,
		"world_task_action": str(world_task.get("action", "")),
		"world_task_reason": str(world_task.get("reason", "")),
		"world_task_target_region_id": str(world_task.get("target_region_id", "")),
		"world_task_completed": _world_task_completed(zone),
		"mainline_chapter": str(request_hint.get("mainline_chapter", "")),
		"mainline_objective": str(request_hint.get("mainline_objective", "")),
		"mainline_chapter_goal": str(request_hint.get("mainline_chapter_goal", "")),
		"mainline_chapter_payoff": str(request_hint.get("mainline_chapter_payoff", "")),
		"chain_focus": _chain_focus_text(),
		"event_window": _active_region_event_tag(),
		"event_window_title": str(_active_region_event().get("title", "当前窗口")),
		"top_intel_channel": _top_intel_channel(),
		"intel_breakdown": intel_breakdown.duplicate(true),
		"cumulative_intel_breakdown": cumulative_breakdown,
		"dominant_intel_channel": _dominant_breakdown_key(cumulative_breakdown, "栖地"),
		"window_counts": window_counts,
		"dominant_window": _dominant_breakdown_key(window_counts, "focus"),
		"specialization_mode": _region_specialization_mode(),
		"specialization_target": _region_specialization_target_channel(),
		"specialization_chain_completed": specialization_chain_bonus_claimed,
		"specialization_chain_bonus": (_specialization_chain_bonus_value() if specialization_chain_bonus_claimed else 0),
		"specialization_run_tag": current_run_tag,
		"specialization_run_counts": specialization_run_counts,
		"dominant_run_style": _dominant_breakdown_key(specialization_run_counts, "基础观察"),
		"last_route_style": current_route_style,
		"route_style_counts": route_style_counts,
		"route_style_streak": route_style_streak,
		"route_style_streak_style": current_route_style,
		"dominant_route_style": _dominant_breakdown_key(route_style_counts, current_route_style),
		"route_lock_tag": route_lock_tag,
		"route_lock_completed": route_lock_completed,
		"last_route_lock_tag": route_lock_tag,
		"route_lock_counts": route_lock_counts,
		"lock_completion_streak": lock_completion_streak,
		"management_priority_tag": management_priority_tag,
		"management_backbone_tag": management_backbone_tag,
		"management_rotation_phase": management_rotation_phase,
		"first_segment_completed": first_segment_completed,
		"second_segment_completed": second_segment_completed,
		"branch_mode": branch_mode,
		"branch_completed": branch_completed,
		"branch_completion_tag": branch_completion_tag,
		"branch_completion_counts": branch_completion_counts,
		"branch_completion_streak": branch_completion_streak,
		"primary_lock_zone": _region_is_primary_lock_zone(),
		"backbone_completed": backbone_completed,
		"backbone_completion_tag": backbone_completion_tag,
		"backbone_completion_counts": backbone_completion_counts,
		"backbone_completion_streak": backbone_completion_streak,
		"handoff_completed": handoff_task_completed,
		"handoff_completion_count": handoff_completion_count,
		"handoff_completion_streak": handoff_completion_streak,
		"handoff_source_region": handoff_source_region,
		"handoff_source_channel": handoff_source_channel,
		"handoff_source_window": handoff_source_window,
		"handoff_source_phase": handoff_source_phase,
		"exit_label": str(zone.get("label", "区域出口")),
		"target_region_id": str(zone.get("target_region_id", "")),
	}
	reports[current_region_id] = record
	reports["_last"] = record
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		return
	var report_text := JSON.stringify(reports)
	file.store_string(report_text)
	var project_file := FileAccess.open(PROJECT_REPORT_PATH, FileAccess.WRITE)
	if project_file != null:
		project_file.store_string(report_text)


func _region_backbone_summary_tag() -> String:
	var backbone_tag := _region_management_backbone_tag()
	if backbone_tag == "" or not specialization_chain_bonus_claimed:
		return ""
	var streak := _region_backbone_completion_streak()
	if streak >= 3:
		return "%s巩固" % backbone_tag
	return "%s跑成" % backbone_tag


func _handoff_archive_progress_bonus(handoff_completed: bool, handoff_streak: int, handoff_count: int) -> int:
	if not handoff_completed:
		return 0
	var bonus := 1
	if handoff_streak >= 3:
		bonus += 1
	if handoff_count >= 5:
		bonus += 1
	return bonus


func _backbone_archive_progress_bonus(backbone_tag: String, backbone_completed: bool, backbone_streak: int, backbone_counts: Dictionary) -> int:
	if backbone_tag == "" or not backbone_completed:
		return 0
	var count := int(backbone_counts.get(backbone_tag, 0))
	var bonus := 1
	if backbone_streak >= 2:
		bonus += 1
	if backbone_streak >= 4 or count >= 5:
		bonus += 1
	return bonus


func _branch_archive_progress_bonus(previous: Dictionary = {}) -> int:
	var report := previous if not previous.is_empty() else _region_identity_report()
	if report.is_empty():
		return 0
	var branch_mode := str(report.get("branch_mode", ""))
	var branch_completed := bool(report.get("branch_completed", false))
	var branch_streak := int(report.get("branch_completion_streak", 0))
	var branch_counts: Dictionary = report.get("branch_completion_counts", {}) if report.has("branch_completion_counts") else {}
	if branch_mode == "deep_expand":
		var deep_count := int(branch_counts.get("deep_expand", 0))
		if branch_completed and branch_streak >= 3:
			return 2
		if deep_count >= 2:
			return 1
	elif branch_mode == "quick_close":
		var quick_count := int(branch_counts.get("quick_close", 0))
		if branch_completed and branch_streak >= 3:
			return 2
		if quick_count >= 2:
			return 1
	return 0


func _archive_progress_gain(previous: Dictionary = {}, run_tag: String = "", route_style_streak: int = 0) -> int:
	var current_run_tag := run_tag if run_tag != "" else _specialization_run_tag()
	var bonus := 1
	match current_run_tag:
		"快取完成":
			bonus = 2
		"深挖完成":
			bonus = 3
		"快取未完成":
			bonus = 1
		"深挖未完成":
			bonus = 1
		_:
			bonus = 1
	var style_key := _run_style_family(current_run_tag)
	var streak := route_style_streak
	if streak <= 0 and not previous.is_empty():
		var previous_style := str(previous.get("last_route_style", ""))
		var previous_streak := int(previous.get("route_style_streak", 0))
		streak = previous_streak + 1 if style_key != "" and previous_style == style_key else 1
	match style_key:
		"quick":
			if streak >= 2:
				bonus += 1
			if current_run_tag == "快取完成" and streak >= 4:
				bonus += 1
		"deep":
			if streak >= 2:
				bonus += 1
			if current_run_tag == "深挖完成" and streak >= 3:
				bonus += 1
		"base":
			if streak >= 3:
				bonus += 1
	var previous_tier := str(previous.get("archive_tier", "初勘档案"))
	if style_key == "quick" and previous_tier in ["已知档案", "熟悉档案"] and current_run_tag == "快取完成":
		bonus += 1
	if style_key == "deep" and previous_tier in ["已知档案", "熟悉档案"] and current_run_tag == "深挖完成":
		bonus += 1
	bonus += _branch_archive_progress_bonus(previous)
	return bonus


func _archive_tier_from_progress(progress: int) -> String:
	if progress >= 12:
		return "定型档案"
	if progress >= 7:
		return "熟悉档案"
	if progress >= 3:
		return "已知档案"
	return "初勘档案"


func _dominant_breakdown_key(data: Dictionary, fallback: String) -> String:
	var best_key := fallback
	var best_value := -1
	for key_variant in data.keys():
		var key := str(key_variant)
		var value := int(data.get(key, 0))
		if value > best_value:
			best_value = value
			best_key = key
	return best_key


func _load_expedition_reports() -> Dictionary:
	if not FileAccess.file_exists(REPORT_PATH):
		return {}
	var file := FileAccess.open(REPORT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _region_identity_report() -> Dictionary:
	var reports := _load_expedition_reports()
	return reports.get(current_region_id, {})


func _region_archive_tier() -> String:
	var report := _region_identity_report()
	return str(report.get("archive_tier", "初勘档案"))


func _region_archive_progress() -> int:
	var report := _region_identity_report()
	return int(report.get("archive_progress", 0))


func _region_specialization_target_channel() -> String:
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	if dominant_channel != "":
		return dominant_channel
	return _top_intel_channel()


func _region_specialization_mode() -> String:
	var report := _region_identity_report()
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 3:
		return "基础线"
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var dominant_window := str(report.get("dominant_window", "focus"))
	if dominant_channel in ["压迫", "腐食"] or dominant_window in ["predation", "pressure", "risk", "carrion"]:
		return "快取线"
	if dominant_channel in ["水源", "栖地"] or dominant_window in ["symbiosis", "focus", "handoff"]:
		return "深挖线"
	if dominant_channel == "迁徙" or dominant_window in ["territory", "trend"]:
		return "深挖线" if visit_count >= 5 else "快取线"
	return "基础线"


func _region_specialization_note() -> String:
	var target := _region_specialization_target_channel()
	match _region_specialization_mode():
		"快取线":
			return "专精链：快取%s，拿到关键样本后尽早撤离" % target
		"深挖线":
			return "专精链：深挖%s，适合连续补样和复核" % target
		_:
			return "专精链：基础观察，先建立区域样本"


func _archive_has_stable_quicktake_window() -> bool:
	if _region_specialization_mode() != "快取线":
		return false
	if _region_route_lock_tag() == "快取锁定":
		return true
	if _region_archive_tier() in ["熟悉档案", "定型档案"]:
		return true
	return _region_route_style() == "quick" and _region_route_style_streak() >= 4


func _archive_has_stable_followup_chain() -> bool:
	if _region_specialization_mode() != "深挖线":
		return false
	if _region_route_lock_tag() == "深挖锁定":
		return true
	if _region_archive_tier() in ["熟悉档案", "定型档案"]:
		return true
	return _region_route_style() == "deep" and _region_route_style_streak() >= 4


func _region_archive_route_mode() -> String:
	if _region_route_lock_tag() == "快取锁定":
		return "short"
	if _region_route_lock_tag() == "深挖锁定":
		return "deep"
	if _region_archive_tier() == "定型档案" and _region_run_profile() == "快取完成":
		return "short"
	if _region_archive_tier() == "定型档案" and _region_run_profile() == "深挖完成":
		return "deep"
	if _region_archive_tier() == "熟悉档案" and _region_run_profile() in ["快取完成", "快取未完成"]:
		return "short"
	if _region_archive_tier() == "熟悉档案" and _region_run_profile() in ["深挖完成", "深挖未完成"]:
		return "deep"
	if _region_archive_tier() == "已知档案" and _region_route_style() == "quick" and _region_route_style_streak() >= 4:
		return "short"
	if _region_archive_tier() == "已知档案" and _region_route_style() == "deep" and _region_route_style_streak() >= 4:
		return "deep"
	return "base"


func _region_run_profile() -> String:
	var report := _region_identity_report()
	if report.is_empty():
		return "基础观察"
	return str(report.get("dominant_run_style", report.get("specialization_run_tag", "基础观察")))


func _run_style_family(run_tag: String) -> String:
	match run_tag:
		"快取完成", "快取未完成":
			return "quick"
		"深挖完成", "深挖未完成":
			return "deep"
		_:
			return "base"


func _region_route_style() -> String:
	var report := _region_identity_report()
	if report.is_empty():
		return "base"
	return str(report.get("dominant_route_style", _run_style_family(_region_run_profile())))


func _region_route_style_streak() -> int:
	var report := _region_identity_report()
	if report.is_empty():
		return 0
	if str(report.get("route_style_streak_style", _region_route_style())) != _region_route_style():
		return 0
	return int(report.get("route_style_streak", 0))


func _region_route_shaping_tag() -> String:
	var route_style := _region_route_style()
	var streak := _region_route_style_streak()
	match route_style:
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


func _region_route_shaping_bonus() -> int:
	match _region_route_shaping_tag():
		"快取塑形稳固", "深挖塑形稳固":
			return 2
		"快取塑形中", "深挖塑形中", "基础塑形中":
			return 1
		_:
			return 0


func _region_route_lock_tag() -> String:
	var route_style := _region_route_style()
	var streak := _region_route_style_streak()
	match route_style:
		"quick":
			if streak >= 6 and _region_archive_tier() in ["已知档案", "熟悉档案", "定型档案"]:
				return "快取锁定"
		"deep":
			if streak >= 5 and _region_archive_tier() in ["已知档案", "熟悉档案", "定型档案"]:
				return "深挖锁定"
	return "未锁定"


func _locked_route_completed() -> bool:
	match _region_route_lock_tag():
		"快取锁定":
			return _region_archive_route_mode() == "short" and specialization_chain_bonus_claimed
		"深挖锁定":
			return _region_archive_route_mode() == "deep" and specialization_chain_bonus_claimed
		_:
			return false


func _region_lock_completion_streak() -> int:
	var report := _region_identity_report()
	if report.is_empty():
		return 0
	if not bool(report.get("route_lock_completed", false)):
		return 0
	if str(report.get("last_route_lock_tag", _region_route_lock_tag())) != _region_route_lock_tag():
		return 0
	return int(report.get("lock_completion_streak", 0))


func _region_lock_completion_bonus() -> int:
	var streak := _region_lock_completion_streak()
	if streak >= 5:
		return 2
	if streak >= 3:
		return 1
	return 0


func _region_handoff_completion_count() -> int:
	var report := _region_identity_report()
	if report.is_empty():
		return 0
	return int(report.get("handoff_completion_count", 0))


func _region_handoff_completion_streak() -> int:
	var report := _region_identity_report()
	if report.is_empty():
		return 0
	if not bool(report.get("handoff_completed", false)):
		return 0
	return int(report.get("handoff_completion_streak", 0))


func _region_handoff_completion_bonus() -> int:
	var streak := _region_handoff_completion_streak()
	var count := _region_handoff_completion_count()
	if streak >= 3:
		return 2
	if streak >= 2 or count >= 4:
		return 1
	return 0


func _region_branch_stability_tag() -> String:
	var report := _region_identity_report()
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


func _region_is_primary_lock_zone() -> bool:
	if _region_management_backbone_tag() != "":
		return true
	return _region_route_lock_tag() != "未锁定" and (_region_lock_completion_streak() + _region_handoff_completion_bonus()) >= 3


func _region_management_priority_tag() -> String:
	var lock_tag := _region_route_lock_tag()
	var streak := _region_lock_completion_streak() + _region_handoff_completion_bonus()
	var branch_stability_tag := _region_branch_stability_tag()
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


func _region_management_backbone_tag() -> String:
	var management_tag := _region_management_priority_tag()
	var branch_stability_tag := _region_branch_stability_tag()
	if management_tag == "主力快取经营区" and branch_stability_tag == "稳定收束区":
		return "快取经营骨干区"
	if management_tag == "主力深挖经营区" and branch_stability_tag == "稳定扩线区":
		return "深挖经营骨干区"
	return ""


func _management_candidate_score(report: Dictionary) -> float:
	var score := float(report.get("lock_completion_streak", 0)) * 3.0 + float(report.get("handoff_completion_streak", 0)) * 1.5 + float(report.get("handoff_completion_count", 0)) * 0.35 + float(report.get("archive_progress", 0)) + float(report.get("intel", 0)) * 0.05
	var branch_tag := _region_branch_stability_tag()
	match branch_tag:
		"稳定扩线区", "稳定收束区":
			score += 2.5
		"扩线塑形中", "收束塑形中":
			score += 1.2
	match _region_management_backbone_tag():
		"快取经营骨干区", "深挖经营骨干区":
			score += 4.0
	return score


func _region_management_rotation_note() -> String:
	var reports := _load_expedition_reports()
	var best_quick: Dictionary = {}
	var best_deep: Dictionary = {}
	for key_variant in reports.keys():
		var key := str(key_variant)
		if key == "_last":
			continue
		var report: Dictionary = reports.get(key, {})
		var tag := str(report.get("management_priority_tag", ""))
		if tag == "":
			continue
		var score := _management_candidate_score(report)
		var enriched := report.duplicate(true)
		enriched["score"] = score
		enriched["region_id"] = key
		match tag:
			"主力快取经营区":
				if best_quick.is_empty() or score > float(best_quick.get("score", -1.0)):
					best_quick = enriched
			"主力深挖经营区":
				if best_deep.is_empty() or score > float(best_deep.get("score", -1.0)):
					best_deep = enriched
	var current_tag := _region_management_priority_tag()
	if best_quick.is_empty() and best_deep.is_empty():
		return "当前没有主力经营区，先按本区主线推进。"
	var backbone_tag := _region_management_backbone_tag()
	if backbone_tag == "快取经营骨干区":
		if not best_deep.is_empty():
			return "当前经营顺序：本区是快取经营骨干区，先稳吃主速查组，再转去 %s 深挖。" % str(best_deep.get("region_name", best_deep.get("region_id", "目标区")))
		return "当前经营顺序：本区是快取经营骨干区，默认作为短推进第一站。"
	if backbone_tag == "深挖经营骨干区":
		if not best_quick.is_empty():
			return "当前经营顺序：本区是深挖经营骨干区，先稳压主复核，再转去 %s 快取。" % str(best_quick.get("region_name", best_quick.get("region_id", "目标区")))
		return "当前经营顺序：本区是深挖经营骨干区，默认作为扩线主轴。"
	if current_tag == "主力快取经营区":
		if not best_deep.is_empty():
			if float(best_quick.get("score", 0.0)) >= float(best_deep.get("score", 0.0)):
				return "当前经营顺序：先在本区完成主力快取，再转去 %s 深挖。" % str(best_deep.get("region_name", best_deep.get("region_id", "目标区")))
			return "当前经营顺序：先去 %s 深挖，再回本区收主力快取。" % str(best_deep.get("region_name", best_deep.get("region_id", "目标区")))
		return "当前经营顺序：本区是主力快取经营区，先拿关键样本再转场。"
	if current_tag == "主力深挖经营区":
		if not best_quick.is_empty():
			if float(best_deep.get("score", 0.0)) >= float(best_quick.get("score", 0.0)):
				return "当前经营顺序：先在本区完成主力深挖，再转去 %s 快取。" % str(best_quick.get("region_name", best_quick.get("region_id", "目标区")))
			return "当前经营顺序：先去 %s 快取，再回本区补主力深挖链。" % str(best_quick.get("region_name", best_quick.get("region_id", "目标区")))
		return "当前经营顺序：本区是主力深挖经营区，先补完整条复核链再转场。"
	if current_tag == "重点快取经营区":
		return "当前经营顺序：本区是快取后续经营区，适合在主力深挖结束后补短推进样本。"
	if current_tag == "重点深挖经营区":
		return "当前经营顺序：本区是深挖后续经营区，适合在主力快取结束后补复核链。"
	return "当前经营顺序：本区仍以常规经营为主，先顺着主线建立稳定样本。"


func _region_management_rotation_phase() -> String:
	var reports := _load_expedition_reports()
	var best_quick: Dictionary = {}
	var best_deep: Dictionary = {}
	for key_variant in reports.keys():
		var key := str(key_variant)
		if key == "_last":
			continue
		var report: Dictionary = reports.get(key, {})
		var tag := str(report.get("management_priority_tag", ""))
		if tag == "":
			continue
		var score := _management_candidate_score(report)
		var enriched := report.duplicate(true)
		enriched["score"] = score
		enriched["region_id"] = key
		match tag:
			"主力快取经营区":
				if best_quick.is_empty() or score > float(best_quick.get("score", -1.0)):
					best_quick = enriched
			"主力深挖经营区":
				if best_deep.is_empty() or score > float(best_deep.get("score", -1.0)):
					best_deep = enriched
	var current_tag := _region_management_priority_tag()
	var backbone_tag := _region_management_backbone_tag()
	if best_quick.is_empty() and best_deep.is_empty():
		return "常规经营"
	if backbone_tag == "快取经营骨干区":
		if best_deep.is_empty():
			return "单区快取主经营"
		return "主经营第一段"
	if backbone_tag == "深挖经营骨干区":
		if best_quick.is_empty():
			return "单区深挖主经营"
		return "主经营第一段"
	if current_tag == "主力快取经营区":
		if best_deep.is_empty():
			return "单区快取主经营"
		return "主经营第一段" if float(best_quick.get("score", 0.0)) >= float(best_deep.get("score", 0.0)) else "主经营第二段"
	if current_tag == "主力深挖经营区":
		if best_quick.is_empty():
			return "单区深挖主经营"
		return "主经营第一段" if float(best_deep.get("score", 0.0)) > float(best_quick.get("score", 0.0)) else "主经营第二段"
	if current_tag in ["重点快取经营区", "重点深挖经营区"]:
		return "后续经营段"
	return "常规经营"


func _specialization_run_tag() -> String:
	match _region_specialization_mode():
		"快取线":
			return "快取完成" if specialization_chain_bonus_claimed else "快取未完成"
		"深挖线":
			return "深挖完成" if specialization_chain_bonus_claimed else "深挖未完成"
		_:
			return "基础观察"


func _specialization_target_hotspot_id() -> String:
	match _region_specialization_target_channel():
		"水源":
			return "waterhole"
		"迁徙":
			return "migration_corridor"
		"压迫":
			return "predator_ridge"
		"腐食":
			return "carrion_field"
		"栖地":
			return "shade_grove"
		_:
			return ""


func _specialization_target_category() -> String:
	match _region_specialization_target_channel():
		"水源":
			return "水域动物"
		"迁徙":
			return "草食动物"
		"压迫":
			return "掠食者"
		"腐食":
			return "飞行动物"
		"栖地":
			return "区域生物"
		_:
			return ""


func _specialization_followup_hotspot_id() -> String:
	match _region_specialization_target_channel():
		"水源":
			return "shade_grove"
		"迁徙":
			return "waterhole"
		"压迫":
			return "migration_corridor"
		"腐食":
			return "predator_ridge"
		"栖地":
			return "waterhole"
		_:
			return ""


func _specialization_chain_state_text() -> String:
	var hotspot_id := _specialization_target_hotspot_id()
	var followup_hotspot_id := _specialization_followup_hotspot_id()
	var category := _specialization_target_category()
	var backbone_tag := _region_management_backbone_tag()
	var hotspot_done := hotspot_id != "" and completed_task_ids.has("task_" + hotspot_id)
	var followup_done := followup_hotspot_id != "" and completed_task_ids.has("task_" + followup_hotspot_id)
	var deep_inertia := _region_run_profile() == "深挖完成"
	var category_seen := false
	for species_id_variant in discovered_species_ids.keys():
		var species_id := str(species_id_variant)
		for animal in wildlife:
			if str(animal.get("species_id", "")) == species_id and str(animal.get("category", "")) == category:
				category_seen = true
				break
		if category_seen:
			break
	match _region_specialization_mode():
		"快取线":
			if backbone_tag == "快取经营骨干区" and specialization_chain_bonus_claimed:
				return "链进度：主力速查组已跑成，本轮应按骨干快取节奏立即撤离"
			if _region_route_lock_tag() == "快取锁定" and specialization_chain_bonus_claimed:
				return "链进度：锁定速查组已跑成，本轮应按短推进节奏立即撤离"
			if specialization_chain_bonus_claimed:
				return "链进度：快取链已完成，本轮可直接按高值样本撤离"
			if category_seen:
				return "链进度：关键样本已拿到，回到出口可按快取线收束"
			return "链进度：优先记录%s，再决定是否立刻撤离" % category
		"深挖线":
			if backbone_tag == "深挖经营骨干区" and specialization_chain_bonus_claimed:
				return "链进度：主力复核链已跑成，本轮应带着骨干深挖结果撤离"
			if _region_route_lock_tag() == "深挖锁定" and specialization_chain_bonus_claimed:
				return "链进度：锁定复核链已跑成，本轮应带着整条深挖结果撤离"
			if specialization_chain_bonus_claimed:
				return "链进度：深挖链已完成，本轮适合带着复核结果撤离"
			if deep_inertia and hotspot_done and not followup_done:
				return "链进度：主热点已复核，下一步补第二复核点"
			if deep_inertia and hotspot_done and followup_done and category_seen:
				return "链进度：主热点、第二复核点和对应样本都已完成"
			if deep_inertia and hotspot_done and followup_done:
				return "链进度：双复核已完成，下一步补%s样本" % category
			if hotspot_done and category_seen:
				return "链进度：主热点复核和对应样本都已完成"
			if hotspot_done:
				return "链进度：主热点已复核，下一步补%s样本" % category
			return "链进度：先完成主热点复核，再补%s样本" % category
		_:
			return "链进度：先建立基础观察样本"


func _identity_chain_bonus_for_channel(channel: String, source_kind: String) -> int:
	var report := _region_identity_report()
	var visit_count := int(report.get("visit_count", 0))
	if visit_count < 3:
		return 0
	if channel != _region_specialization_target_channel():
		return 0
	match _region_specialization_mode():
		"快取线":
			return 1 if source_kind == "species" else 0
		"深挖线":
			return 2 if source_kind == "hotspot" else 1
		_:
			return 0


func _identity_chain_note_for_channel(channel: String, source_kind: String) -> String:
	var bonus := _identity_chain_bonus_for_channel(channel, source_kind)
	if bonus <= 0:
		return ""
	return " · 专精链 %s · 额外情报 +%d" % [_region_specialization_mode(), bonus]


func _run_profile_hotspot_bonus(hotspot: Dictionary) -> int:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	match _region_run_profile():
		"快取完成":
			return 2 if hotspot_id == _specialization_target_hotspot_id() else 0
		"深挖完成":
			return 2 if hotspot_id == _specialization_followup_hotspot_id() else 0
		_:
			return 0


func _specialization_chain_ready() -> bool:
	var hotspot_id := _specialization_target_hotspot_id()
	var followup_hotspot_id := _specialization_followup_hotspot_id()
	var category := _specialization_target_category()
	var hotspot_done := hotspot_id != "" and completed_task_ids.has("task_" + hotspot_id)
	var followup_done := followup_hotspot_id != "" and completed_task_ids.has("task_" + followup_hotspot_id)
	var category_seen := false
	for species_id_variant in discovered_species_ids.keys():
		var species_id := str(species_id_variant)
		for animal in wildlife:
			if str(animal.get("species_id", "")) == species_id and str(animal.get("category", "")) == category:
				category_seen = true
				break
		if category_seen:
			break
	match _region_specialization_mode():
		"快取线":
			return category_seen
		"深挖线":
			if _region_run_profile() == "深挖完成":
				return hotspot_done and followup_done and category_seen
			return hotspot_done and category_seen
		_:
			return false


func _specialization_chain_bonus_value() -> int:
	var bonus := 0
	match _region_specialization_mode():
		"快取线":
			bonus = 2
		"深挖线":
			bonus = 3
		_:
			bonus = 0
	match _region_archive_tier():
		"熟悉档案":
			bonus += 1
		"定型档案":
			bonus += 2
	match _region_archive_route_mode():
		"short":
			bonus += 1
		"deep":
			bonus += 2
	match _region_route_lock_tag():
		"快取锁定":
			bonus += 1
		"深挖锁定":
			bonus += 2
	match _region_management_backbone_tag():
		"快取经营骨干区":
			bonus += 2
		"深挖经营骨干区":
			bonus += 3
	return bonus


func _maybe_award_specialization_chain_bonus(trigger_label: String) -> void:
	if specialization_chain_bonus_claimed:
		return
	if not _specialization_chain_ready():
		return
	var bonus := _specialization_chain_bonus_value()
	if bonus <= 0:
		return
	var channel := _region_specialization_target_channel()
	var backbone_tag := _region_management_backbone_tag()
	specialization_chain_bonus_claimed = true
	hotspot_intel_score += bonus
	intel_breakdown[channel] = int(intel_breakdown.get(channel, 0)) + bonus
	if backbone_tag != "":
		discovery_log.push_front("骨干巩固完成：%s · %s情报 +%d" % [trigger_label, channel, bonus])
	else:
		discovery_log.push_front("专精链完成：%s · %s情报 +%d" % [trigger_label, channel, bonus])
	discovery_log = discovery_log.slice(0, 6)
	if backbone_tag != "":
		current_task = {
			"title": "骨干巩固完成",
			"body": "%s 已完成本轮%s，当前%s已被再次接稳，%s情报 +%d。%s" % [trigger_label, _region_specialization_mode(), backbone_tag, channel, bonus, _specialization_chain_state_text()],
			"accent": Color8(198, 222, 160),
		}
	else:
		current_task = {
			"title": "专精链完成",
			"body": "%s 已完成本轮%s，%s情报 +%d。%s" % [trigger_label, _region_specialization_mode(), channel, bonus, _specialization_chain_state_text()],
			"accent": Color8(198, 222, 160),
		}


func _update_hotspot_task() -> void:
	if current_hotspot.is_empty():
		return
	var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
	var task_id := "task_" + hotspot_id
	var hotspot_label := _biome_hotspot_label(hotspot_id)
	var task_config := _hotspot_task_config(hotspot_id)
	var required_time := float(task_config.get("required_time", 2.0))
	var required_category := str(task_config.get("required_category", ""))
	var required_presence := required_category == "" or _has_nearby_category(required_category, _hotspot_position(hotspot_id), 210.0)
	var is_active_target := survey_target_kind == "hotspot" and survey_target_id == hotspot_id
	var progress_value := survey_progress if is_active_target else 0.0
	if completed_task_ids.has(task_id):
		current_task = {
			"title": "观察完成",
			"body": "%s 的%s已经记录进图鉴。" % [hotspot_label, str(task_config.get("noun", "观察"))],
			"accent": Color8(150, 216, 176),
		}
		return
	if not required_presence:
		current_task = {
			"title": str(task_config.get("title", "观察目标")),
			"body": "%s 还缺少%s，先把目标生物等进观察区。" % [hotspot_label, required_category],
			"accent": Color8(232, 194, 118),
		}
		return
	current_task = {
		"title": str(task_config.get("title", "观察目标")),
		"body": "%s · 按住 Space %s %.1f / %.1f 秒%s" % [
			hotspot_label,
			str(task_config.get("prompt", "停留记录")),
			progress_value,
			required_time,
			("" if required_category == "" else " · 目标生物：" + required_category) + _identity_special_hotspot_note(current_hotspot) + " · " + _region_specialization_note(),
		],
		"accent": Color8(170, 224, 198),
	}
	current_task["body"] += " · " + _specialization_chain_state_text()


func _update_field_survey(delta: float) -> void:
	var target := _current_survey_target()
	if target.is_empty():
		_decay_survey(delta)
		return
	var target_kind := str(target.get("kind", ""))
	var target_id := str(target.get("id", ""))
	if target_kind != survey_target_kind or target_id != survey_target_id:
		survey_target_kind = target_kind
		survey_target_id = target_id
		survey_target_label = str(target.get("label", ""))
		survey_required_time = float(target.get("required_time", 0.0))
		survey_target_data = target.get("data", {})
		survey_progress = 0.0
	if not Input.is_key_pressed(KEY_SPACE):
		_decay_survey(delta)
		return
	survey_progress = minf(survey_required_time, survey_progress + delta)
	if survey_progress >= survey_required_time:
		_complete_survey_target()


func _current_survey_target() -> Dictionary:
	var locked_target := _locked_survey_target()
	if not locked_target.is_empty():
		return locked_target
	var specialization_mode := _region_specialization_mode()
	var target_hotspot_id := _specialization_target_hotspot_id()
	var followup_hotspot_id := _specialization_followup_hotspot_id()
	var target_category := _specialization_target_category()
	var branch_stability_tag := _region_branch_stability_tag()
	var backbone_tag := _region_management_backbone_tag()
	var backbone_streak := _region_backbone_completion_streak()
	var stable_quicktake_window := _archive_has_stable_quicktake_window() or branch_stability_tag == "稳定收束区" or backbone_tag == "快取经营骨干区"
	var stable_followup_chain := _archive_has_stable_followup_chain() or branch_stability_tag == "稳定扩线区" or backbone_tag == "深挖经营骨干区"
	if stable_quicktake_window and not current_hotspot.is_empty():
		var quick_hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		var quick_task_id := "task_" + quick_hotspot_id
		if quick_hotspot_id == target_hotspot_id and not completed_task_ids.has(quick_task_id):
			var quick_task_config := _hotspot_task_config(quick_hotspot_id)
			var quick_required_category := str(quick_task_config.get("required_category", ""))
			var quick_required_presence := quick_required_category == "" or _has_nearby_category(quick_required_category, _hotspot_position(quick_hotspot_id), 210.0)
			if quick_required_presence:
				return {
					"kind": "hotspot",
					"id": quick_hotspot_id,
					"label": str(current_hotspot.get("label", quick_hotspot_id)),
					"required_time": maxf(1.0, float(quick_task_config.get("required_time", 2.0)) - (0.15 if backbone_streak >= 2 else 0.0)),
					"data": current_hotspot,
				}
	if stable_followup_chain and not current_hotspot.is_empty():
		var deep_hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		var deep_task_id := "task_" + deep_hotspot_id
		if not completed_task_ids.has(deep_task_id):
			var deep_task_config := _hotspot_task_config(deep_hotspot_id)
			var deep_required_category := str(deep_task_config.get("required_category", ""))
			var deep_required_presence := deep_required_category == "" or _has_nearby_category(deep_required_category, _hotspot_position(deep_hotspot_id), 210.0)
			var target_done := completed_task_ids.has("task_" + target_hotspot_id)
			if deep_required_presence:
				if deep_hotspot_id == target_hotspot_id:
					return {
						"kind": "hotspot",
						"id": deep_hotspot_id,
						"label": str(current_hotspot.get("label", deep_hotspot_id)),
						"required_time": maxf(1.0, float(deep_task_config.get("required_time", 2.0)) - (0.12 if backbone_streak >= 2 else 0.0)),
						"data": current_hotspot,
					}
				if deep_hotspot_id == followup_hotspot_id and (target_done or backbone_tag == "深挖经营骨干区"):
					return {
						"kind": "hotspot",
						"id": deep_hotspot_id,
						"label": str(current_hotspot.get("label", deep_hotspot_id)),
						"required_time": maxf(1.0, float(deep_task_config.get("required_time", 2.0)) - (0.10 if backbone_streak >= 2 else 0.0)),
						"data": current_hotspot,
					}
	if specialization_mode == "快取线" and not current_encounter.is_empty():
		var encounter_species_id := str(current_encounter.get("species_id", ""))
		var encounter_category := str(current_encounter.get("category", ""))
		if encounter_species_id != "" and encounter_category == target_category and not discovered_species_ids.has(encounter_species_id):
			return {
				"kind": "species",
				"id": encounter_species_id,
				"label": str(current_encounter.get("label", encounter_species_id)),
				"required_time": _species_survey_time(encounter_category),
				"data": current_encounter,
			}
	if not current_hotspot.is_empty():
		var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		var task_id := "task_" + hotspot_id
		if not completed_task_ids.has(task_id):
			var task_config := _hotspot_task_config(hotspot_id)
			var required_category := str(task_config.get("required_category", ""))
			var required_presence := required_category == "" or _has_nearby_category(required_category, _hotspot_position(hotspot_id), 210.0)
			var deep_ready := specialization_mode != "深挖线"
			if specialization_mode == "深挖线":
				if _region_run_profile() == "深挖完成" or stable_followup_chain:
					deep_ready = target_hotspot_id == "" \
						or hotspot_id == target_hotspot_id \
						or (completed_task_ids.has("task_" + target_hotspot_id) and hotspot_id == followup_hotspot_id) \
						or (completed_task_ids.has("task_" + target_hotspot_id) and completed_task_ids.has("task_" + followup_hotspot_id))
				else:
					deep_ready = target_hotspot_id == "" or hotspot_id == target_hotspot_id or completed_task_ids.has("task_" + target_hotspot_id)
			if required_presence and deep_ready:
				return {
					"kind": "hotspot",
					"id": hotspot_id,
					"label": str(current_hotspot.get("label", hotspot_id)),
					"required_time": float(task_config.get("required_time", 2.0)),
					"data": current_hotspot,
				}
	if not current_encounter.is_empty():
		var species_id := str(current_encounter.get("species_id", ""))
		if species_id != "" and not discovered_species_ids.has(species_id):
			return {
				"kind": "species",
				"id": species_id,
				"label": str(current_encounter.get("label", species_id)),
				"required_time": _species_survey_time(str(current_encounter.get("category", ""))),
				"data": current_encounter,
			}
	return {}


func _locked_survey_target() -> Dictionary:
	if survey_progress <= 0.0 or survey_target_kind == "" or survey_target_id == "":
		return {}
	if not Input.is_key_pressed(KEY_SPACE):
		return {}
	if survey_target_kind == "species":
		if discovered_species_ids.has(survey_target_id):
			return {}
		for animal_variant in wildlife:
			var animal: Dictionary = animal_variant
			if str(animal.get("species_id", "")) != survey_target_id:
				continue
			var animal_pos: Vector2 = animal.get("position", player_pos)
			if player_pos.distance_to(animal_pos) > 260.0:
				return {}
			return {
				"kind": "species",
				"id": survey_target_id,
				"label": str(animal.get("label", survey_target_label)),
				"required_time": survey_required_time,
				"data": animal,
			}
	if survey_target_kind == "hotspot":
		if completed_task_ids.has("task_" + survey_target_id):
			return {}
		var hotspot_pos := _hotspot_position(survey_target_id)
		if player_pos.distance_to(hotspot_pos) > 260.0:
			return {}
		for hotspot_variant in hotspots:
			var hotspot: Dictionary = hotspot_variant
			if str(hotspot.get("hotspot_id", "")) != survey_target_id:
				continue
			return {
				"kind": "hotspot",
				"id": survey_target_id,
				"label": str(hotspot.get("label", survey_target_label)),
				"required_time": survey_required_time,
				"data": hotspot,
			}
	return {}


func _species_survey_time(category: String) -> float:
	var base := 1.5
	match category:
		"掠食者":
			base = 1.8
		"飞行动物":
			base = 1.4
		"水域动物":
			base = 1.6
		_:
			base = 1.5
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	var branch_stability_tag := _region_branch_stability_tag()
	if visit_count >= 3:
		match dominant_channel:
			"水源":
				if category == "水域动物":
					base -= 0.2
			"迁徙":
				if category == "草食动物":
					base -= 0.2
			"压迫":
				if category == "掠食者":
					base -= 0.2
			"腐食":
				if category == "飞行动物":
					base -= 0.2
			"栖地":
				if category == "区域生物":
					base -= 0.15
		if _region_specialization_mode() == "快取线" and _species_intel_channel({"category": category}) == dominant_channel:
			base -= 0.1
		elif _region_specialization_mode() == "深挖线" and _species_intel_channel({"category": category}) == dominant_channel:
			base += 0.1
	if _species_intel_channel({"category": category}) == dominant_channel:
		match _region_archive_tier():
			"已知档案":
				base -= 0.05
			"熟悉档案":
				base -= 0.12
			"定型档案":
				base -= 0.20
	if branch_stability_tag == "稳定扩线区" and _species_intel_channel({"category": category}) == dominant_channel:
		base -= 0.12
	elif branch_stability_tag == "扩线塑形中" and _species_intel_channel({"category": category}) == dominant_channel:
		base -= 0.06
	if branch_stability_tag == "稳定收束区" and _species_intel_channel({"category": category}) == dominant_channel:
		base -= 0.14
	elif branch_stability_tag == "收束塑形中" and _species_intel_channel({"category": category}) == dominant_channel:
		base -= 0.08
	if _region_route_style() == "quick" and _species_intel_channel({"category": category}) == dominant_channel:
		base -= 0.04 * float(_region_route_shaping_bonus())
	elif _region_route_style() == "deep" and _species_intel_channel({"category": category}) == dominant_channel and _archive_has_stable_followup_chain():
		base -= 0.03 * float(_region_route_shaping_bonus())
	return maxf(1.0, base)


func _decay_survey(delta: float) -> void:
	if survey_progress > 0.0:
		survey_progress = maxf(0.0, survey_progress - delta * 1.35)
	if survey_progress <= 0.0 and _current_survey_target().is_empty():
		survey_target_kind = ""
		survey_target_id = ""
		survey_target_label = ""
		survey_required_time = 0.0
		survey_target_data.clear()


func _complete_survey_target() -> void:
	if survey_target_kind == "species":
		_record_species_discovery(survey_target_data)
	elif survey_target_kind == "hotspot":
		_complete_hotspot_task(survey_target_data)
	survey_progress = 0.0
	survey_target_kind = ""
	survey_target_id = ""
	survey_target_label = ""
	survey_required_time = 0.0
	survey_target_data.clear()


func _complete_hotspot_task(hotspot: Dictionary) -> void:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	if hotspot_id == "":
		return
	var task_id := "task_" + hotspot_id
	if completed_task_ids.has(task_id):
		return
	var hotspot_label := _biome_hotspot_label(hotspot_id)
	var task_config := _hotspot_task_config(hotspot_id)
	var reward := _hotspot_intel_reward(hotspot)
	var channel := _hotspot_intel_channel(hotspot)
	var handoff_bonus := _first_segment_handoff_reward_bonus(channel, "hotspot")
	var followup_bonus := _branch_followup_reward_bonus(channel, "hotspot")
	var backbone_bonus := _management_backbone_reward_bonus(channel, "hotspot", hotspot_id)
	hotspot_intel_score += reward
	intel_breakdown[channel] = int(intel_breakdown.get(channel, 0)) + reward
	completed_task_ids[task_id] = true
	var bonus_note := ""
	if handoff_bonus > 0:
		bonus_note += " · 第一站奖励 +%d" % handoff_bonus
	if followup_bonus > 0:
		var followup_label := "扩线后续奖励" if str(incoming_handoff.get("branch_mode", "")) == "deep_expand" else "收束后续奖励"
		bonus_note += " · %s +%d" % [followup_label, followup_bonus]
	if backbone_bonus > 0:
		bonus_note += " · 骨干奖励 +%d" % backbone_bonus
	discovery_log.push_front("%s完成：%s · %s情报 +%d%s" % [str(task_config.get("noun", "观察")), hotspot_label, channel, reward, bonus_note])
	discovery_log = discovery_log.slice(0, 6)
	_show_reward_feedback(
		"%s完成" % str(task_config.get("noun", "观察")),
		"%s情报 +%d%s" % [channel, reward, bonus_note],
		_backend_effect_for_intel(channel, "hotspot"),
		Color8(118, 214, 164)
	)
	current_task = {
		"title": "观察完成",
		"body": "%s 的%s已完成，%s情报 +%d%s%s%s，继续寻找下一处目标。" % [hotspot_label, str(task_config.get("noun", "观察")), channel, reward, bonus_note, _identity_special_hotspot_note(hotspot), _identity_chain_note_for_channel(channel, "hotspot")],
		"accent": Color8(150, 216, 176),
	}
	_maybe_complete_handoff(hotspot_label, channel)
	_maybe_award_specialization_chain_bonus(hotspot_label)


func _hotspot_task_config(hotspot_id: String) -> Dictionary:
	var config := {}
	match hotspot_id:
		"waterhole":
			config = {"required_time": 1.8, "title": "水源采样", "prompt": "记录水源驻留", "noun": "水源观察", "required_category": "水域动物"}
		"migration_corridor":
			config = {"required_time": 2.2, "title": "迁徙观察", "prompt": "跟进迁徙带活动", "noun": "迁徙观察", "required_category": "草食动物"}
		"predator_ridge":
			config = {"required_time": 2.4, "title": "掠食观察", "prompt": "盯防掠食巡猎", "noun": "掠食观察", "required_category": "掠食者"}
		"carrion_field":
			config = {"required_time": 2.0, "title": "腐食观察", "prompt": "记录腐食活动", "noun": "腐食观察", "required_category": "飞行动物"}
		_:
			config = {"required_time": 2.1, "title": "林荫观察", "prompt": "记录林荫驻留", "noun": "栖地观察"}
	var report := _region_identity_report()
	var dominant_channel := str(report.get("dominant_intel_channel", ""))
	var visit_count := int(report.get("visit_count", 0))
	var followup_hotspot_id := _specialization_followup_hotspot_id()
	var backbone_tag := _region_management_backbone_tag()
	var stable_quicktake_window := _archive_has_stable_quicktake_window()
	var stable_followup_chain := _archive_has_stable_followup_chain()
	if visit_count >= 3:
		match dominant_channel:
			"水源":
				if hotspot_id == "waterhole":
					config["title"] = "水线复测"
					config["prompt"] = "核验水源驻留与补给窗口"
					config["noun"] = "水线复测"
				elif hotspot_id == "shade_grove":
					config["prompt"] = "补查岸带外缘的庇护反应"
			"迁徙":
				if hotspot_id == "migration_corridor":
					config["title"] = "迁徙复测"
					config["prompt"] = "核验迁徙带通行与聚群节奏"
					config["noun"] = "迁徙复测"
				elif hotspot_id == "waterhole":
					config["prompt"] = "核验迁徙补给点"
			"压迫":
				if hotspot_id == "predator_ridge":
					config["title"] = "压迫复盘"
					config["prompt"] = "复盘掠食压迫与切入线路"
					config["noun"] = "压迫复盘"
				elif hotspot_id == "migration_corridor":
					config["prompt"] = "记录逃散走廊与回避反应"
			"腐食":
				if hotspot_id == "carrion_field":
					config["title"] = "腐食复测"
					config["prompt"] = "核验腐食聚集与空中回线"
					config["noun"] = "腐食复测"
				elif hotspot_id == "predator_ridge":
					config["prompt"] = "补查高地对腐食线的牵引"
			"栖地":
				if hotspot_id == "shade_grove":
					config["title"] = "庇护复测"
					config["prompt"] = "核验庇护点稳定性与停留窗口"
					config["noun"] = "庇护复测"
				elif hotspot_id == "waterhole":
					config["prompt"] = "补查栖地边缘的取水联系"
		match dominant_channel:
			"水源":
				if hotspot_id == "waterhole":
					config["required_time"] = maxf(1.3, float(config.get("required_time", 2.0)) - 0.3)
			"迁徙":
				if hotspot_id == "migration_corridor":
					config["required_time"] = maxf(1.5, float(config.get("required_time", 2.0)) - 0.4)
			"压迫":
				if hotspot_id == "predator_ridge":
					config["required_time"] = maxf(1.6, float(config.get("required_time", 2.0)) - 0.4)
			"腐食":
				if hotspot_id == "carrion_field":
					config["required_time"] = maxf(1.4, float(config.get("required_time", 2.0)) - 0.3)
			"栖地":
				if hotspot_id == "shade_grove":
					config["required_time"] = maxf(1.5, float(config.get("required_time", 2.0)) - 0.3)
	if visit_count >= 5:
		config["prompt"] = "%s · 按既有调查档案快速补样" % str(config.get("prompt", "停留记录"))
	match _region_archive_tier():
		"熟悉档案":
			if hotspot_id == _specialization_target_hotspot_id():
				config["prompt"] = "%s · 熟悉档案已建立，主线热点可以快速复核" % str(config.get("prompt", "停留记录"))
				config["required_time"] = maxf(1.0, float(config.get("required_time", 2.0)) - 0.12)
		"定型档案":
			if hotspot_id == _specialization_target_hotspot_id():
				config["title"] = "定型复核"
				config["noun"] = "定型复核"
				config["prompt"] = "%s · 定型档案已建立，主线复核会给出稳定高值样本" % str(config.get("prompt", "停留记录"))
				config["required_time"] = maxf(1.0, float(config.get("required_time", 2.0)) - 0.22)
			elif hotspot_id == followup_hotspot_id and _region_specialization_mode() == "深挖线":
				config["title"] = "稳定复核"
				config["noun"] = "稳定复核"
				config["prompt"] = "%s · 定型档案支持连续复核，补完这一点后再收对应样本" % str(config.get("prompt", "停留记录"))
				config["required_time"] = maxf(1.1, float(config.get("required_time", 2.0)) - 0.20)
	if stable_followup_chain and _region_specialization_mode() == "深挖线":
		if hotspot_id == _specialization_target_hotspot_id():
			if backbone_tag == "深挖经营骨干区" or (_region_is_primary_lock_zone() and _region_route_lock_tag() == "深挖锁定"):
				config["title"] = "主力主复核"
				config["noun"] = "主力主复核"
			else:
				config["title"] = "锁定主复核" if _region_route_lock_tag() == "深挖锁定" else "主线复核"
				config["noun"] = "锁定主复核" if _region_route_lock_tag() == "深挖锁定" else "主线复核"
			config["prompt"] = "%s · %s" % [
				str(config.get("prompt", "停留记录")),
				"这片区已成深挖经营骨干区，先完成主力主复核" if backbone_tag == "深挖经营骨干区" else ("这片区已成主力深挖区，先完成主力主复核" if _region_is_primary_lock_zone() and _region_route_lock_tag() == "深挖锁定" else ("这片区已锁定为连续复核区，先完成锁定主复核" if _region_route_lock_tag() == "深挖锁定" else "这片区已形成稳定深挖链，先完成主热点复核"))
			]
		elif hotspot_id == followup_hotspot_id:
			if backbone_tag == "深挖经营骨干区" or (_region_is_primary_lock_zone() and _region_route_lock_tag() == "深挖锁定"):
				config["title"] = "主力次复核"
				config["noun"] = "主力次复核"
			else:
				config["title"] = "锁定次复核" if _region_route_lock_tag() == "深挖锁定" else "第二复核点"
				config["noun"] = "锁定次复核" if _region_route_lock_tag() == "深挖锁定" else "第二复核点"
			config["prompt"] = "%s · %s" % [
				str(config.get("prompt", "停留记录")),
				"主力主复核完成后，这里会稳定成为主力次复核点" if backbone_tag == "深挖经营骨干区" else ("主复核完成后，这里会稳定成为主力次复核点" if _region_is_primary_lock_zone() and _region_route_lock_tag() == "深挖锁定" else ("主复核完成后，这里会稳定成为锁定次复核点" if _region_route_lock_tag() == "深挖锁定" else "主热点完成后，这里会稳定成为第二复核点"))
			]
	if stable_quicktake_window and hotspot_id == _specialization_target_hotspot_id():
		if backbone_tag == "快取经营骨干区" or (_region_is_primary_lock_zone() and _region_route_lock_tag() == "快取锁定"):
			config["title"] = "主力速查组"
			config["noun"] = "主力速查组"
		else:
			config["title"] = "锁定速查组" if _region_route_lock_tag() == "快取锁定" else "高值速查"
			config["noun"] = "锁定速查组" if _region_route_lock_tag() == "快取锁定" else "高值速查"
		config["prompt"] = "%s · %s" % [
			str(config.get("prompt", "停留记录")),
			"这片区已成快取经营骨干区，这里会稳定产出主力速查组" if backbone_tag == "快取经营骨干区" else ("这片区已形成稳定快取窗%s，这里会稳定产出高值短窗目标" % ["并完成快取锁定" if _region_route_lock_tag() == "快取锁定" else ""])
		]
		config["required_time"] = maxf(1.0, float(config.get("required_time", 2.0)) - (0.20 if _region_archive_tier() == "熟悉档案" else 0.30))
	elif _region_route_style() == "quick" and _region_route_style_streak() >= 3 and hotspot_id == _specialization_target_hotspot_id():
		config["title"] = "塑形速查"
		config["noun"] = "塑形速查"
		config["prompt"] = "%s · 快取塑形正在形成，先抓关键样本建立短推进节奏" % str(config.get("prompt", "停留记录"))
		config["required_time"] = maxf(1.1, float(config.get("required_time", 2.0)) - 0.15)
	elif _region_route_style() == "deep" and _region_route_style_streak() >= 3 and hotspot_id == followup_hotspot_id:
		config["title"] = "塑形复核"
		config["noun"] = "塑形复核"
		config["prompt"] = "%s · 深挖塑形正在形成，先补第二复核点把链路拉稳" % str(config.get("prompt", "停留记录"))
		config["required_time"] = maxf(1.2, float(config.get("required_time", 2.0)) - 0.10)
	var specialization_mode := _region_specialization_mode()
	if specialization_mode == "快取线" and _hotspot_intel_channel({"hotspot_id": hotspot_id}) == dominant_channel:
		config["prompt"] = "%s · 当前是快取窗口，取到关键样本就撤" % str(config.get("prompt", "停留记录"))
		config["required_time"] = maxf(1.1, float(config.get("required_time", 2.0)) - 0.2)
	elif specialization_mode == "深挖线" and _hotspot_intel_channel({"hotspot_id": hotspot_id}) == dominant_channel:
		config["prompt"] = "%s · 当前适合深挖复核，建议补完连续样本" % str(config.get("prompt", "停留记录"))
		config["required_time"] = minf(3.0, float(config.get("required_time", 2.0)) + 0.15)
	if _region_run_profile() == "深挖完成" and hotspot_id == followup_hotspot_id:
		config["title"] = "链路复核"
		config["noun"] = "链路复核"
		config["prompt"] = "%s · 按既有调查档案继续补第二复核点" % str(config.get("prompt", "停留记录"))
		config["required_time"] = maxf(1.4, float(config.get("required_time", 2.0)) - 0.15)
	elif _region_run_profile() == "快取完成" and hotspot_id == _specialization_target_hotspot_id():
		config["title"] = "高值速查"
		config["noun"] = "高值速查"
		config["prompt"] = "%s · 当前回线偏快取，优先完成这一处高值点" % str(config.get("prompt", "停留记录"))
		config["required_time"] = maxf(1.0, float(config.get("required_time", 2.0)) - 0.25)
	return config


func _has_nearby_category(category: String, center: Vector2, radius: float) -> bool:
	for animal in wildlife:
		if str(animal.get("category", "")) != category:
			continue
		if center.distance_to(animal.get("position", Vector2.ZERO)) <= radius:
			return true
	return false


func _objective_rows() -> Array:
	var rows: Array = []
	var task_action := str(world_task.get("action", ""))
	if task_action != "":
		rows.append(
			{
				"title": "世界任务 · %s" % task_action,
				"label": _world_task_progress_label(task_action),
				"done": _world_task_completed(current_exit_zone),
				"progress": _world_task_progress_ratio(task_action),
			}
		)
	var stage := 1
	if discovered_species_ids.size() >= 3 and discovered_hotspot_ids.size() >= 2:
		stage = 2
	if witnessed_pressure and visited_region_ids.size() >= 2:
		stage = 3
	if stage == 1:
		rows.append_array([
			{"title": "阶段一 · 建立观察", "label": "发现动物 %d/3" % mini(discovered_species_ids.size(), 3), "done": discovered_species_ids.size() >= 3, "progress": clampf(float(discovered_species_ids.size()) / 3.0, 0.0, 1.0)},
			{"title": "", "label": "热点采样 %d/1" % mini(completed_task_ids.size(), 1), "done": completed_task_ids.size() >= 1, "progress": clampf(float(completed_task_ids.size()), 0.0, 1.0)},
		])
		return rows
	if stage == 2:
		rows.append_array([
			{"title": "阶段二 · 见证压力", "label": "观察一次掠食追逐", "done": witnessed_pressure, "progress": 1.0 if witnessed_pressure else 0.0},
			{"title": "", "label": "不同热点任务 %d/2" % mini(completed_task_ids.size(), 2), "done": completed_task_ids.size() >= 2, "progress": clampf(float(completed_task_ids.size()) / 2.0, 0.0, 1.0)},
		])
		return rows
	rows.append_array([
		{"title": "阶段三 · 扩展生态图", "label": "已进入区域 %d/2" % mini(visited_region_ids.size(), 2), "done": visited_region_ids.size() >= 2, "progress": clampf(float(visited_region_ids.size()) / 2.0, 0.0, 1.0)},
		{"title": "", "label": "见证一次追猎命中或落空", "done": witnessed_chase_result, "progress": 1.0 if witnessed_chase_result else 0.0},
	])
	return rows


func _world_task_progress_ratio(action: String) -> float:
	match action:
		"修复":
			var intel_ratio := clampf(float(_expedition_intel_points()) / float(_world_task_intel_goal(action)), 0.0, 1.0)
			var hotspot_ratio := clampf(float(completed_task_ids.size()), 0.0, 1.0)
			return (intel_ratio + hotspot_ratio) * 0.5
		"通道":
			var target := str(world_task.get("target_region_id", ""))
			if target == "":
				return 1.0 if _is_current_exit_a_corridor() else 0.0
			return 1.0 if not current_exit_zone.is_empty() and str(current_exit_zone.get("target_region_id", "")) == target else 0.0
		_:
			var intel_ratio := clampf(float(_expedition_intel_points()) / float(_world_task_intel_goal(action)), 0.0, 1.0)
			var species_ratio := clampf(float(discovered_species_ids.size()), 0.0, 1.0)
			var hotspot_ratio := clampf(float(completed_task_ids.size()), 0.0, 1.0)
			return (intel_ratio + species_ratio + hotspot_ratio) / 3.0


func _world_task_progress_label(action: String) -> String:
	match action:
		"修复":
			var repair_goal := _world_task_intel_goal(action)
			return "情报 %d/%d · 热点 %d/1" % [
				mini(_expedition_intel_points(), repair_goal),
				repair_goal,
				mini(completed_task_ids.size(), 1),
			]
		"通道":
			var target := str(world_task.get("target_region_id", ""))
			if target == "":
				return "靠近任意通道出口，按 E 撤离"
			var zone := _objective_exit_target()
			var target_name := str(zone.get("label", "目标出口")) if not zone.is_empty() else "目标出口"
			var ready := not current_exit_zone.is_empty() and str(current_exit_zone.get("target_region_id", "")) == target
			return "%s · %s" % [target_name, ("已到达" if ready else "未到达")]
		_:
			var survey_goal := _world_task_intel_goal(action)
			return "情报 %d/%d · 动物 %d/1 · 热点 %d/1" % [
				mini(_expedition_intel_points(), survey_goal),
				survey_goal,
				mini(discovered_species_ids.size(), 1),
				mini(completed_task_ids.size(), 1),
			]


func _record_species_discovery(animal: Dictionary) -> void:
	var species_id := str(animal.get("species_id", ""))
	if species_id == "" or discovered_species_ids.has(species_id):
		return
	var reward := _species_intel_reward(animal)
	var channel := _species_intel_channel(animal)
	var handoff_bonus := _first_segment_handoff_reward_bonus(channel, "species")
	var followup_bonus := _branch_followup_reward_bonus(channel, "species")
	var backbone_bonus := _management_backbone_reward_bonus(channel, "species")
	species_intel_score += reward
	intel_breakdown[channel] = int(intel_breakdown.get(channel, 0)) + reward
	discovered_species_ids[species_id] = true
	var bonus_note := ""
	if handoff_bonus > 0:
		bonus_note += " · 第一站奖励 +%d" % handoff_bonus
	if followup_bonus > 0:
		var followup_label := "扩线后续奖励" if str(incoming_handoff.get("branch_mode", "")) == "deep_expand" else "收束后续奖励"
		bonus_note += " · %s +%d" % [followup_label, followup_bonus]
	if backbone_bonus > 0:
		bonus_note += " · 骨干奖励 +%d" % backbone_bonus
	discovery_log.push_front("发现动物：%s · %s情报 +%d%s%s" % [str(animal.get("label", species_id)), channel, reward, bonus_note, _identity_chain_note_for_channel(channel, "species")])
	discovery_log = discovery_log.slice(0, 6)
	_show_reward_feedback(
		"记录新物种",
		"%s · %s情报 +%d%s" % [str(animal.get("label", species_id)), channel, reward, bonus_note],
		_backend_effect_for_intel(channel, "species"),
		Color8(230, 188, 102)
	)
	_maybe_complete_handoff(str(animal.get("label", species_id)), channel)
	_maybe_award_specialization_chain_bonus(str(animal.get("label", species_id)))


func _record_hotspot_discovery(hotspot: Dictionary) -> void:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	if hotspot_id == "" or discovered_hotspot_ids.has(hotspot_id):
		return
	discovered_hotspot_ids[hotspot_id] = true
	discovery_log.push_front("记录热点：%s" % _biome_hotspot_label(hotspot_id))
	discovery_log = discovery_log.slice(0, 6)


func _screen_point(world_point: Vector2) -> Vector2:
	return world_point - camera_pos


func _draw_world_ground() -> void:
	if current_region_texture != null:
		var texture_region := Rect2(camera_pos, size)
		draw_texture_rect_region(current_region_texture, Rect2(Vector2.ZERO, size), texture_region)
		_draw_ground_atmosphere()
		_draw_waterhole()
		_draw_carcass_field()
		_draw_biome_life_details()
		_draw_exit_markers()
		return
	var terrain_points = [
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
	]
	draw_colored_polygon(terrain_points, current_theme.get("ground", Color8(201, 183, 122)))
	_draw_ground_texture()

	for band in range(5):
		var y := 90.0 + float(band) * 160.0
		draw_arc(Vector2(size.x * 0.45, y), size.x * 0.48, 0.15, 3.0, 64, current_theme.get("arc", Color(1.0, 0.95, 0.78, 0.07)), 2.0)

	_draw_grass_patch(Vector2(780, 620), 260, 150, current_theme.get("grass_a", Color8(158, 176, 88, 120)))
	_draw_grass_patch(Vector2(1540, 760), 320, 180, current_theme.get("grass_b", Color8(168, 188, 98, 128)))
	_draw_grass_patch(Vector2(990, 1220), 260, 160, current_theme.get("grass_a", Color8(171, 185, 104, 120)))
	_draw_grass_patch(Vector2(2220, 820), 220, 130, current_theme.get("grass_b", Color8(148, 164, 88, 110)))

	_draw_river()
	_draw_waterhole()
	if current_theme == BIOME_THEMES["wetland"]:
		_draw_marsh_pools()
		_draw_reed_bank(Vector2(700, 670), 6)
		_draw_reed_bank(Vector2(1870, 730), 5)
	elif current_theme == BIOME_THEMES["forest"]:
		_draw_canopy_shadows()
		_draw_forest_cluster(Vector2(690, 620), 7)
		_draw_forest_cluster(Vector2(1840, 720), 6)
	elif current_theme == BIOME_THEMES["coast"]:
		_draw_shore_bands()
		_draw_palm_cluster(Vector2(690, 640), 5)
		_draw_palm_cluster(Vector2(1870, 700), 4)
	else:
		_draw_dust_trails()
		_draw_acacia_grove(Vector2(710, 650), 5)
		_draw_acacia_grove(Vector2(1870, 700), 4)
	_draw_ridge()
	_draw_carcass_field()
	_draw_exit_markers()


func _draw_ground_atmosphere() -> void:
	if current_theme == BIOME_THEMES["forest"]:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.08, 0.04, 0.10), true)
	elif current_theme == BIOME_THEMES["wetland"]:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.10, 0.11, 0.06), true)
	elif current_theme == BIOME_THEMES["coast"]:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.10, 0.12, 0.05), true)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.07, 0.02, 0.04), true)


func _draw_biome_life_details() -> void:
	match _biome_key():
		"wetland":
			_draw_reed_bank(Vector2(700, 670), 6)
			_draw_reed_bank(Vector2(1870, 730), 5)
		"forest":
			_draw_forest_cluster(Vector2(690, 620), 7)
			_draw_forest_cluster(Vector2(1840, 720), 6)
		"coast":
			_draw_palm_cluster(Vector2(690, 640), 5)
			_draw_palm_cluster(Vector2(1870, 700), 4)
		_:
			_draw_acacia_grove(Vector2(710, 650), 5)
			_draw_acacia_grove(Vector2(1870, 700), 4)


func _draw_grass_patch(center: Vector2, width: float, height: float, color: Color) -> void:
	_draw_natural_blob(center, width, height, color, 28)


func _draw_ground_texture() -> void:
	var origin := Vector2(floor(camera_pos.x / 92.0) * 92.0, floor(camera_pos.y / 72.0) * 72.0)
	for x_index in range(-1, int(ceil(size.x / 92.0)) + 2):
		for y_index in range(-1, int(ceil(size.y / 72.0)) + 2):
			var world_pos := origin + Vector2(float(x_index) * 92.0, float(y_index) * 72.0)
			var jitter := Vector2(
				sin(world_pos.x * 0.017 + world_pos.y * 0.011) * 24.0,
				cos(world_pos.x * 0.013 - world_pos.y * 0.019) * 18.0
			)
			var p := _screen_point(world_pos + jitter)
			var shade := 0.055 + sin(world_pos.x * 0.005) * 0.018
			draw_arc(p, 18.0, -0.8, 0.9, 8, Color(0.20, 0.26, 0.14, shade), 1.0, true)


func _draw_natural_blob(center: Vector2, width: float, height: float, color: Color, segments: int = 24) -> void:
	var points := PackedVector2Array()
	var screen_center := _screen_point(center)
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		var ripple := 1.0 + sin(angle * 3.0 + center.x * 0.003) * 0.10 + cos(angle * 5.0 + center.y * 0.002) * 0.07
		points.append(screen_center + Vector2(cos(angle) * width * 0.5 * ripple, sin(angle) * height * 0.5 * ripple))
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(color.r, color.g, color.b, minf(color.a + 0.08, 0.32)), 1.4, true)


func _draw_river() -> void:
	var river_points = PackedVector2Array()
	for point in [
		Vector2(280, 1320),
		Vector2(560, 1110),
		Vector2(920, 980),
		Vector2(1280, 910),
		Vector2(1680, 960),
		Vector2(2060, 860),
		Vector2(2510, 720),
	]:
		river_points.append(_screen_point(point))
	draw_polyline(river_points, current_theme.get("water_a", Color8(91, 154, 188, 180)), 42.0, true)
	draw_polyline(river_points, current_theme.get("water_b", Color8(176, 225, 234, 235)), 20.0, true)


func _draw_waterhole() -> void:
	var center := _screen_point(_hotspot_position("waterhole"))
	_draw_natural_blob(_hotspot_position("waterhole"), 178.0, 126.0, Color8(80, 145, 182, 150), 30)
	draw_circle(center, 48.0, Color8(138, 209, 221, 150))


func _draw_acacia_grove(center: Vector2, count: int) -> void:
	for index in range(count):
		var offset := Vector2((index % 3) * 42 - 44, int(index / 3) * 36 - 22)
		var tree_pos := _screen_point(center + offset)
		draw_rect(Rect2(tree_pos + Vector2(-4, 8), Vector2(8, 28)), Color8(96, 68, 44, 220))
		draw_circle(tree_pos, 22.0, Color8(87, 122, 72, 220))
		draw_circle(tree_pos + Vector2(12, -6), 17.0, Color8(108, 143, 84, 230))


func _draw_reed_bank(center: Vector2, count: int) -> void:
	for index in range(count):
		var offset := Vector2(index * 18 - count * 9, sin(float(index)) * 8.0)
		var reed_pos := _screen_point(center + offset)
		draw_line(reed_pos + Vector2(0, 20), reed_pos + Vector2(0, -12), Color8(96, 126, 74, 230), 3.0)
		draw_line(reed_pos + Vector2(-4, 14), reed_pos + Vector2(4, -8), Color8(118, 154, 96, 220), 2.0)
		draw_line(reed_pos + Vector2(4, 16), reed_pos + Vector2(-3, -4), Color8(144, 178, 110, 220), 2.0)


func _draw_forest_cluster(center: Vector2, count: int) -> void:
	for index in range(count):
		var offset := Vector2((index % 4) * 28 - 40, int(index / 4) * 32 - 18)
		var tree_pos := _screen_point(center + offset)
		draw_rect(Rect2(tree_pos + Vector2(-5, 10), Vector2(10, 30)), Color8(76, 56, 38, 220))
		draw_circle(tree_pos, 24.0, Color8(58, 94, 62, 228))
		draw_circle(tree_pos + Vector2(12, -4), 18.0, Color8(72, 110, 76, 236))


func _draw_palm_cluster(center: Vector2, count: int) -> void:
	for index in range(count):
		var offset := Vector2((index % 3) * 34 - 30, int(index / 3) * 26 - 14)
		var palm_pos := _screen_point(center + offset)
		draw_rect(Rect2(palm_pos + Vector2(-4, 8), Vector2(8, 32)), Color8(112, 84, 52, 220))
		for angle in [-0.8, -0.3, 0.2, 0.7]:
			draw_line(palm_pos, palm_pos + Vector2(cos(angle) * 28.0, sin(angle) * 18.0 - 12.0), Color8(88, 132, 88, 220), 3.0)


func _draw_marsh_pools() -> void:
	for center in [Vector2(620, 870), Vector2(1720, 640), Vector2(2140, 520)]:
		var p := _screen_point(center)
		draw_circle(p, 54.0, Color8(74, 132, 142, 120))
		draw_circle(p + Vector2(28, 0), 32.0, Color8(74, 132, 142, 110))
		draw_circle(p, 34.0, Color8(138, 188, 176, 110))


func _draw_canopy_shadows() -> void:
	for center in [Vector2(640, 560), Vector2(1120, 680), Vector2(1940, 690)]:
		var p := _screen_point(center)
		draw_circle(p, 72.0, Color(0.08, 0.16, 0.10, 0.16))
		draw_circle(p + Vector2(30, 8), 52.0, Color(0.08, 0.16, 0.10, 0.12))


func _draw_shore_bands() -> void:
	for y in [1180.0, 1260.0, 1340.0]:
		draw_line(_screen_point(Vector2(120, y)), _screen_point(Vector2(2680, y + 40.0)), Color(0.92, 0.91, 0.78, 0.18), 8.0)


func _draw_dust_trails() -> void:
	for center in [Vector2(950, 760), Vector2(1450, 860), Vector2(1920, 880)]:
		var p := _screen_point(center)
		draw_arc(p, 64.0, -0.3, 2.7, 28, Color(0.84, 0.72, 0.44, 0.18), 10.0)


func _draw_ridge() -> void:
	var contours := [
		[Vector2(1840, 575), Vector2(1980, 515), Vector2(2150, 500), Vector2(2320, 545)],
		[Vector2(1880, 520), Vector2(2035, 455), Vector2(2200, 458), Vector2(2380, 508)],
		[Vector2(1930, 468), Vector2(2090, 410), Vector2(2260, 430)],
	]
	for contour in contours:
		var points := PackedVector2Array()
		for point in contour:
			points.append(_screen_point(point))
		draw_polyline(points, Color8(118, 104, 82, 118), 5.0, true)
		draw_polyline(points, Color8(238, 222, 176, 72), 1.8, true)
	for rock in [Vector2(1988, 540), Vector2(2144, 492), Vector2(2268, 515), Vector2(2070, 438)]:
		var p := _screen_point(rock)
		draw_circle(p, 9.0, Color8(126, 112, 88, 128))
		draw_circle(p + Vector2(-2, -2), 4.0, Color8(220, 204, 164, 84))


func _draw_carcass_field() -> void:
	var center := _screen_point(_hotspot_position("carrion_field"))
	_draw_natural_blob(_hotspot_position("carrion_field"), 118.0, 78.0, Color8(112, 76, 58, 82), 22)
	draw_circle(center, 14.0, Color8(235, 223, 178, 168))
	draw_line(center + Vector2(-13, -6), center + Vector2(13, 7), Color8(132, 94, 72, 160), 2.2)
	draw_line(center + Vector2(-8, 12), center + Vector2(16, -12), Color8(132, 94, 72, 150), 2.0)


func _draw_world_routes() -> void:
	if not current_interaction.is_empty():
		var predator_pos := _screen_point(current_interaction.get("predator", {}).get("position", Vector2.ZERO))
		var target_pos := _screen_point(current_interaction.get("target", Vector2.ZERO))
		draw_line(predator_pos, target_pos, Color(0.94, 0.52, 0.38, 0.32), 14.0)
		draw_line(predator_pos, target_pos, Color(1.0, 0.76, 0.58, 0.75), 4.0)
		draw_arc(target_pos, 52.0, 0.0, TAU, 36, Color(0.96, 0.72, 0.48, 0.22), 7.0)
	if not current_chase.is_empty():
		var chase_predator_pos := _screen_point(current_chase.get("predator", {}).get("position", Vector2.ZERO))
		var chase_target_pos := _screen_point(current_chase.get("target", Vector2.ZERO))
		draw_line(chase_predator_pos, chase_target_pos, Color(1.0, 0.44, 0.30, 0.44), 18.0)
		draw_line(chase_predator_pos, chase_target_pos, Color(1.0, 0.84, 0.64, 0.95), 5.0)
		draw_arc(chase_predator_pos, 40.0, 0.0, TAU, 40, Color(1.0, 0.58, 0.34, 0.25), 6.0)
		draw_arc(chase_target_pos, 68.0, 0.0, TAU, 40, Color(1.0, 0.76, 0.52, 0.20), 10.0)


func _draw_exit_markers() -> void:
	for zone in exit_zones:
		var rect: Rect2 = zone["rect"]
		var marker := _screen_point(rect.position + rect.size * 0.5)
		var accent := Color8(232, 210, 142, 190)
		if not current_exit_zone.is_empty() and str(current_exit_zone.get("id", "")) == str(zone["id"]):
			draw_arc(marker, 40.0, 0.0, TAU, 42, Color(0.96, 0.86, 0.46, 0.34), 5.0, true)
			accent = Color8(255, 232, 150, 230)
		draw_circle(marker, 10.0, Color(0.08, 0.08, 0.06, 0.22))
		draw_circle(marker, 6.0, accent)
		draw_line(marker + Vector2(0, 7), marker + Vector2(0, 28), Color8(96, 70, 42, 180), 3.0)
		_draw_text(marker + Vector2(14, -8), str(zone["label"]), 14, Color8(245, 239, 220, 210))
		_draw_text(marker + Vector2(14, 10), "按 E 撤离", 11, Color8(194, 204, 202, 180))


func _draw_hotspots() -> void:
	var objective := _current_objective_target()
	for hotspot in hotspots:
		var hotspot_id := str(hotspot.get("hotspot_id", ""))
		var label := _biome_hotspot_label(hotspot_id)
		var center := _screen_point(_hotspot_position(hotspot_id))
		var is_current := not current_hotspot.is_empty() and str(current_hotspot.get("hotspot_id", "")) == hotspot_id
		var is_objective := str(objective.get("kind", "")) == "hotspot" and _hotspot_position(hotspot_id).distance_to(objective.get("position", Vector2.ZERO)) < 2.0
		var accent := Color(1.0, 0.95, 0.7, 0.16 if is_current or is_objective else 0.045)
		draw_circle(center, 30.0 if is_current or is_objective else 18.0, accent)
		if is_current or is_objective:
			draw_arc(center, 36.0, 0.0, TAU, 36, Color(1.0, 0.90, 0.52, 0.24), 2.0, true)
			_draw_text(center + Vector2(-28, -42), label, 13, Color8(238, 235, 212, 202))


func _draw_objective_marker() -> void:
	var target := _current_objective_target()
	if target.is_empty():
		return
	var world_pos: Vector2 = target.get("position", player_pos)
	var screen_pos := _screen_point(world_pos)
	var label := str(target.get("label", "目标"))
	var distance := int(round(player_pos.distance_to(world_pos)))
	var pulse := 0.5 + sin(elapsed * 3.2) * 0.5
	var margin := 58.0
	var inside := screen_pos.x >= margin and screen_pos.y >= margin and screen_pos.x <= size.x - margin and screen_pos.y <= size.y - margin
	if inside:
		var accent := Color(0.98, 0.82, 0.34, 0.28 + pulse * 0.12)
		draw_arc(screen_pos, 34.0 + pulse * 8.0, 0.0, TAU, 48, accent, 3.0, true)
		draw_circle(screen_pos, 6.0, Color8(255, 229, 135, 230))
		draw_circle(screen_pos, 2.6, Color8(64, 48, 28, 230))
		_draw_text(screen_pos + Vector2(14, -14), "%s · %dm" % [label, distance], 13, Color8(255, 241, 191, 224))
		return

	var edge_pos := Vector2(clampf(screen_pos.x, margin, size.x - margin), clampf(screen_pos.y, margin, size.y - margin))
	var direction := (screen_pos - Vector2(size.x * 0.5, size.y * 0.5)).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.UP
	var side := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([
		edge_pos + direction * 18.0,
		edge_pos - direction * 12.0 + side * 10.0,
		edge_pos - direction * 12.0 - side * 10.0,
	])
	draw_colored_polygon(arrow, Color8(255, 220, 112, 224))
	_draw_text(edge_pos + Vector2(16, 4), "%s · %dm" % [label, distance], 13, Color8(255, 241, 191, 214))


func _draw_objective_guidance() -> void:
	var target := _current_objective_target()
	if target.is_empty():
		return
	var world_pos: Vector2 = target.get("position", player_pos)
	var distance := player_pos.distance_to(world_pos)
	if distance < 120.0:
		return
	var direction := (world_pos - player_pos).normalized()
	if direction.length() <= 0.01:
		return
	var player_screen := _screen_point(player_pos)
	var pulse := 0.5 + sin(elapsed * 4.2) * 0.5
	var label := str(target.get("label", "目标"))
	var distance_m := int(round(distance))
	var side := Vector2(-direction.y, direction.x)
	var cone := PackedVector2Array([
		player_screen + direction * 34.0,
		player_screen + direction * 174.0 + side * 34.0,
		player_screen + direction * 174.0 - side * 34.0,
	])
	draw_colored_polygon(cone, Color(1.0, 0.78, 0.25, 0.055 + pulse * 0.025))
	for index in range(3):
		var step := 42.0 + float(index) * 34.0
		var dot_pos := player_screen + direction * step
		var alpha := 0.16 + float(index) * 0.08 + pulse * 0.08
		draw_circle(dot_pos, 4.0 + float(index) * 0.8, Color(1.0, 0.82, 0.32, alpha))
	var arrow_center := player_screen + direction * 30.0
	var arrow := PackedVector2Array([
		arrow_center + direction * 12.0,
		arrow_center - direction * 8.0 + side * 6.0,
		arrow_center - direction * 8.0 - side * 6.0,
	])
	draw_colored_polygon(arrow, Color(1.0, 0.82, 0.32, 0.50))
	_draw_text(player_screen + direction * 132.0 + side * 18.0, "%s · %dm" % [label, distance_m], 13, Color8(255, 239, 184, 216))


func _draw_survey_lock_marker() -> void:
	if survey_progress <= 0.0 or survey_target_kind == "" or survey_target_id == "" or survey_required_time <= 0.0:
		return
	var world_pos := _survey_lock_world_position()
	if world_pos == Vector2.INF:
		return
	var screen_pos := _screen_point(world_pos)
	var progress_ratio := clampf(survey_progress / survey_required_time, 0.0, 1.0)
	var accent := Color8(230, 188, 102) if survey_target_kind == "species" else Color8(118, 214, 164)
	var pulse := 0.5 + 0.5 * sin(elapsed * 5.0)
	draw_arc(screen_pos, 44.0 + pulse * 4.0, 0.0, TAU, 52, Color(accent.r, accent.g, accent.b, 0.22), 5.0, true)
	draw_arc(screen_pos, 44.0, -PI * 0.5, -PI * 0.5 + TAU * progress_ratio, 52, Color(accent.r, accent.g, accent.b, 0.92), 5.0, true)
	draw_circle(screen_pos, 5.0, Color(accent.r, accent.g, accent.b, 0.95))
	_draw_text(screen_pos + Vector2(16, -28), "锁定%s %.0f%%" % [("记录" if survey_target_kind == "species" else "采样"), progress_ratio * 100.0], 13, Color8(250, 242, 214))
	_draw_text(screen_pos + Vector2(16, -10), survey_target_label, 12, Color8(218, 231, 226))


func _survey_lock_world_position() -> Vector2:
	if survey_target_kind == "species":
		for animal_variant in wildlife:
			var animal: Dictionary = animal_variant
			if str(animal.get("species_id", "")) == survey_target_id:
				return animal.get("position", Vector2.INF)
	elif survey_target_kind == "hotspot":
		return _hotspot_position(survey_target_id)
	return Vector2.INF


func _current_objective_target() -> Dictionary:
	if not world_task.is_empty() and _world_task_completed(current_exit_zone):
		var ready_exit := _objective_exit_target()
		if not ready_exit.is_empty():
			return {
				"position": _exit_center(ready_exit),
				"label": "撤离回灌",
				"kind": "exit",
			}

	var action := str(world_task.get("action", "调查"))
	match action:
		"修复":
			var hotspot := _first_incomplete_hotspot()
			if not hotspot.is_empty():
				return {
					"position": _hotspot_position(str(hotspot.get("hotspot_id", ""))),
					"label": "采样修复",
					"kind": "hotspot",
				}
			var repair_animal := _first_undiscovered_animal()
			if not repair_animal.is_empty():
				return {
					"position": repair_animal.get("position", player_pos),
					"label": "补充记录",
					"kind": "animal",
				}
		"通道":
			var exit_zone := _objective_exit_target()
			if not exit_zone.is_empty() and str(exit_zone.get("target_region_id", "")) != "":
				return {
					"position": _exit_center(exit_zone),
					"label": "前往通道",
					"kind": "exit",
				}
			var corridor_animal := _first_undiscovered_animal(_biome_preferred_categories())
			if not corridor_animal.is_empty():
				return {
					"position": corridor_animal.get("position", player_pos),
					"label": "先补调查",
					"kind": "animal",
				}
		_:
			var preferred_hotspot := _first_incomplete_hotspot(_biome_preferred_hotspot_ids())
			if _biome_starts_with_hotspot() and not preferred_hotspot.is_empty():
				return {
					"position": _hotspot_position(str(preferred_hotspot.get("hotspot_id", ""))),
					"label": _biome_objective_label("hotspot"),
					"kind": "hotspot",
				}
			var animal := _first_undiscovered_animal(_biome_preferred_categories())
			if not animal.is_empty():
				return {
					"position": animal.get("position", player_pos),
					"label": _biome_objective_label("animal"),
					"kind": "animal",
				}
			var survey_hotspot := preferred_hotspot if not preferred_hotspot.is_empty() else _first_incomplete_hotspot()
			if not survey_hotspot.is_empty():
				return {
					"position": _hotspot_position(str(survey_hotspot.get("hotspot_id", ""))),
					"label": _biome_objective_label("hotspot"),
					"kind": "hotspot",
				}

	var fallback_exit := _objective_exit_target()
	if extraction_ready and not fallback_exit.is_empty():
		return {
			"position": _exit_center(fallback_exit),
			"label": "撤离回灌",
			"kind": "exit",
		}
	return {}


func _first_incomplete_hotspot(preferred_ids: Array = []) -> Dictionary:
	for preferred_id_variant in preferred_ids:
		var preferred_id := str(preferred_id_variant)
		for hotspot_variant in hotspots:
			var hotspot: Dictionary = hotspot_variant
			var hotspot_id := str(hotspot.get("hotspot_id", ""))
			if hotspot_id == "" or hotspot_id != preferred_id or completed_task_ids.has("task_" + hotspot_id):
				continue
			return hotspot
	for hotspot_variant in hotspots:
		var hotspot: Dictionary = hotspot_variant
		var hotspot_id := str(hotspot.get("hotspot_id", ""))
		if hotspot_id == "" or completed_task_ids.has("task_" + hotspot_id):
			continue
		return hotspot
	return {}


func _first_undiscovered_animal(preferred_categories: Array = []) -> Dictionary:
	for preferred_category_variant in preferred_categories:
		var preferred_category := str(preferred_category_variant)
		for animal_variant in wildlife:
			var animal: Dictionary = animal_variant
			var species_id := str(animal.get("species_id", ""))
			if species_id == "" or discovered_species_ids.has(species_id):
				continue
			if str(animal.get("category", "")) == preferred_category:
				return animal
	for animal_variant in wildlife:
		var animal: Dictionary = animal_variant
		var species_id := str(animal.get("species_id", ""))
		if species_id == "" or discovered_species_ids.has(species_id):
			continue
		return animal
	return {}


func _biome_key() -> String:
	var biomes: Array = region_detail.get("dominant_biomes", [])
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return "forest"
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return "wetland"
	if "coast" in biomes or "seagrass" in biomes or "coral_reef" in biomes or "estuary" in biomes:
		return "coast"
	return "grassland"


func _biome_starts_with_hotspot() -> bool:
	return _biome_key() in ["wetland", "forest", "coast"]


func _biome_preferred_hotspot_ids() -> Array:
	match _biome_key():
		"wetland":
			return ["waterhole", "shade_grove", "migration_corridor"]
		"forest":
			return ["shade_grove", "waterhole", "predator_ridge"]
		"coast":
			return ["waterhole", "carrion_field", "migration_corridor"]
		_:
			return ["migration_corridor", "waterhole", "predator_ridge"]


func _biome_preferred_categories() -> Array:
	match _biome_key():
		"wetland":
			return ["水域动物", "飞行动物", "区域生物"]
		"forest":
			return ["区域生物", "草食动物", "掠食者"]
		"coast":
			return ["水域动物", "飞行动物", "区域生物"]
		_:
			return ["草食动物", "掠食者", "飞行动物"]


func _biome_objective_label(kind: String) -> String:
	match _biome_key():
		"wetland":
			return "湿地采样" if kind == "hotspot" else "记录水域生物"
		"forest":
			return "林荫采样" if kind == "hotspot" else "记录林下生物"
		"coast":
			return "潮汐采样" if kind == "hotspot" else "记录海岸生物"
		_:
			return "采样迁徙带" if kind == "hotspot" else "记录迁徙物种"


func _biome_hotspot_label(hotspot_id: String) -> String:
	var labels := {
		"grassland": {
			"waterhole": "季节水洼",
			"migration_corridor": "草食迁徙带",
			"predator_ridge": "掠食高地",
			"carrion_field": "腐食开阔地",
			"shade_grove": "稀树荫带",
		},
		"wetland": {
			"waterhole": "浅滩水眼",
			"migration_corridor": "芦苇通行带",
			"predator_ridge": "泥洲伏击线",
			"carrion_field": "湿地腐食滩",
			"shade_grove": "岸带庇护丛",
		},
		"forest": {
			"waterhole": "林下水洼",
			"migration_corridor": "兽径通道",
			"predator_ridge": "岩坡潜伏带",
			"carrion_field": "倒木腐食点",
			"shade_grove": "密林荫蔽区",
		},
		"coast": {
			"waterhole": "潮汐水线",
			"migration_corridor": "海岸通行带",
			"predator_ridge": "海岸岩脊",
			"carrion_field": "漂上海滩",
			"shade_grove": "防风林缘",
		},
	}
	var biome_labels: Dictionary = labels.get(_biome_key(), labels["grassland"])
	return str(biome_labels.get(hotspot_id, hotspot_id))


func _biome_hotspot_summary(hotspot: Dictionary) -> String:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	var summaries := {
		"grassland": {
			"waterhole": "旱季动物会集中取水，是迁徙节奏和捕食压力的交汇点。",
			"migration_corridor": "草食群沿这里移动，适合记录迁徙密度和追猎压力。",
			"predator_ridge": "掠食者常在高处观察草食群，风险读数更敏感。",
			"carrion_field": "腐食者与掠食残留会在这里形成短时聚集。",
			"shade_grove": "动物在高温时段停留，适合补栖地稳定样本。",
		},
		"wetland": {
			"waterhole": "水位、泥滩和水域动物活动会直接影响湿地恢复判断。",
			"migration_corridor": "芦苇间的通行痕迹能反映湿地连接是否顺畅。",
			"predator_ridge": "泥洲边缘容易出现伏击和逃散行为。",
			"carrion_field": "水鸟和腐食者会把死亡事件带入湿地循环。",
			"shade_grove": "岸带植被提供庇护，是湿地韧性的关键样本。",
		},
		"forest": {
			"waterhole": "林下水点能反映隐蔽动物的活动窗口。",
			"migration_corridor": "兽径连接林地斑块，适合判断栖地破碎程度。",
			"predator_ridge": "岩坡和密林边缘容易留下潜伏与追踪痕迹。",
			"carrion_field": "倒木附近的腐食活动能说明林下分解链是否活跃。",
			"shade_grove": "密林荫蔽区是森林调查的主样本点。",
		},
		"coast": {
			"waterhole": "潮汐涨落会改变水域动物停留和营养交换。",
			"migration_corridor": "海岸通行带连接陆地和浅海生物活动。",
			"predator_ridge": "岩脊提供观察点，也会放大海岸风险。",
			"carrion_field": "漂上海滩会吸引鸟类和腐食者，形成短时食物脉冲。",
			"shade_grove": "防风林缘能缓冲风暴，对海岸韧性很关键。",
		},
	}
	var biome_summaries: Dictionary = summaries.get(_biome_key(), summaries["grassland"])
	return str(biome_summaries.get(hotspot_id, hotspot.get("summary", "")))


func _objective_exit_target() -> Dictionary:
	var expected_target := str(world_task.get("target_region_id", ""))
	for zone_variant in exit_zones:
		var zone: Dictionary = zone_variant
		if expected_target != "" and str(zone.get("target_region_id", "")) != expected_target:
			continue
		if expected_target == "" and str(world_task.get("action", "")) == "通道" and str(zone.get("target_region_id", "")) == "":
			continue
		return zone
	if not exit_zones.is_empty():
		return exit_zones[0]
	return {}


func _is_current_exit_a_corridor() -> bool:
	return not current_exit_zone.is_empty() and str(current_exit_zone.get("target_region_id", "")) != ""


func _has_corridor_exit() -> bool:
	for zone_variant in exit_zones:
		var zone: Dictionary = zone_variant
		if str(zone.get("target_region_id", "")) != "":
			return true
	return false


func _exit_center(zone: Dictionary) -> Vector2:
	var rect: Rect2 = zone.get("rect", Rect2())
	return rect.position + rect.size * 0.5


func _current_objective_summary() -> String:
	var target := _current_objective_target()
	if target.is_empty():
		return _mainline_current_instruction()
	var world_pos: Vector2 = target.get("position", player_pos)
	return "%s · %s · %dm · %s" % [
		_mainline_short_phase(),
		str(target.get("label", "现场目标")),
		int(round(player_pos.distance_to(world_pos))),
		_region_biome_line(),
	]


func _mainline_title() -> String:
	var action := str(world_task.get("action", "调查"))
	match action:
		"修复":
			return "主线：修复生态风险"
		"通道":
			return "主线：连接下一片区域"
		_:
			return "主线：完成生态调查"


func _mainline_short_phase() -> String:
	if extraction_ready:
		return "撤离阶段"
	if completed_task_ids.size() >= 1 and discovered_species_ids.size() >= 1:
		return "整理情报"
	if completed_task_ids.size() >= 1:
		return "补记录"
	if discovered_species_ids.size() >= 1:
		return "采样热点"
	return "寻找目标"


func _mainline_current_instruction() -> String:
	if not current_exit_zone.is_empty() and (extraction_ready or str(world_task.get("action", "")) == "通道"):
		return "按 E 撤离，把这轮报告带回世界图。"
	var missing_step := _world_task_missing_step()
	if missing_step != "" and not extraction_ready:
		return missing_step
	if not current_encounter.is_empty() and not discovered_species_ids.has(str(current_encounter.get("species_id", ""))):
		return "按住 Space 锁定并记录这只动物；完成后会增加生态情报。"
	if not current_hotspot.is_empty() and not completed_task_ids.has("task_" + str(current_hotspot.get("hotspot_id", ""))):
		return "按住 Space 锁定并采样这个热点；完成后会推进本轮任务。"
	var target := _current_objective_target()
	if not target.is_empty():
		var world_pos: Vector2 = target.get("position", player_pos)
		var distance := int(round(player_pos.distance_to(world_pos)))
		match str(target.get("kind", "")):
			"animal":
				return "跟着黄色目标靠近动物，距离约 %dm，靠近后按住 Space 锁定记录。" % distance
			"hotspot":
				return "跟着黄色目标前往生态热点，距离约 %dm，到达后按住 Space 锁定采样。" % distance
			"exit":
				return "跟着黄色目标前往出口，距离约 %dm，到达后按 E 撤离。" % distance
	return "自由调查：靠近动物或热点后按住 Space 锁定调查，情报足够后去出口按 E。"


func _world_task_missing_step() -> String:
	var action := str(world_task.get("action", "调查"))
	if action == "通道":
		var target_zone := _objective_exit_target()
		if target_zone.is_empty():
			return "当前没有可用通道出口，先记录动物或采样热点，回灌后解锁连接。"
		if current_exit_zone.is_empty() or str(current_exit_zone.get("id", "")) != str(target_zone.get("id", "")):
			return "通道线目标：跟着黄色目标去 %s，到达后按 E 撤离。" % str(target_zone.get("label", "通道出口"))
		return ""
	if action == "修复":
		if completed_task_ids.size() < 1:
			return "修复线还差：采样 1 个生态热点。跟着黄色目标到热点后按住 Space。"
		var repair_goal := _world_task_intel_goal(action)
		if _expedition_intel_points() < repair_goal:
			return "修复线还差：情报 %d/%d。继续记录动物或采样热点。" % [_expedition_intel_points(), repair_goal]
		return ""
	if discovered_species_ids.size() < 1:
		return "调查线还差：记录 1 种动物。跟着黄色目标靠近动物后按住 Space。"
	if completed_task_ids.size() < 1:
		return "调查线还差：采样 1 个热点。跟着黄色目标到热点后按住 Space。"
	var survey_goal := _world_task_intel_goal(action)
	if _expedition_intel_points() < survey_goal:
		return "调查线还差：情报 %d/%d。继续记录或采样。" % [_expedition_intel_points(), survey_goal]
	return ""


func _mainline_rows() -> Array:
	var action := str(world_task.get("action", "调查"))
	if action == "通道":
		if not _has_corridor_exit():
			return [
				{"label": "当前无通道出口", "done": false, "progress": 0.0},
				{"label": _biome_step_label("animal"), "done": discovered_species_ids.size() >= 1, "progress": clampf(float(discovered_species_ids.size()), 0.0, 1.0)},
				{"label": _biome_step_label("hotspot"), "done": completed_task_ids.size() >= 1, "progress": clampf(float(completed_task_ids.size()), 0.0, 1.0)},
				{"label": "撤离回灌以解锁连接", "done": extraction_ready and not current_exit_zone.is_empty(), "progress": 1.0 if extraction_ready else 0.0},
			]
		var target_zone := _objective_exit_target()
		var at_target := not current_exit_zone.is_empty()
		if not target_zone.is_empty():
			at_target = at_target and str(current_exit_zone.get("id", "")) == str(target_zone.get("id", ""))
		return [
			{"label": "找到黄色通道出口", "done": at_target, "progress": 1.0 if at_target else 0.0},
			{"label": "按 E 撤离并连接区域", "done": false, "progress": 0.0},
			{"label": "回世界图点击回灌报告", "done": false, "progress": 0.0},
		]
	var species_goal := 1
	var hotspot_goal := 1
	var intel_goal := _world_task_intel_goal(action)
	if action == "修复":
		return [
			{"label": _biome_step_label("hotspot"), "done": completed_task_ids.size() >= hotspot_goal, "progress": clampf(float(completed_task_ids.size()) / float(hotspot_goal), 0.0, 1.0)},
			{"label": "情报达到 %d 点" % intel_goal, "done": _expedition_intel_points() >= intel_goal, "progress": clampf(float(_expedition_intel_points()) / float(intel_goal), 0.0, 1.0)},
			{"label": "前往出口按 E 撤离", "done": extraction_ready and not current_exit_zone.is_empty(), "progress": 1.0 if extraction_ready else 0.0},
			{"label": "回世界图点击回灌报告", "done": false, "progress": 0.0},
		]
	return [
		{"label": _biome_step_label("animal"), "done": discovered_species_ids.size() >= species_goal, "progress": clampf(float(discovered_species_ids.size()) / float(species_goal), 0.0, 1.0)},
		{"label": _biome_step_label("hotspot"), "done": completed_task_ids.size() >= hotspot_goal, "progress": clampf(float(completed_task_ids.size()) / float(hotspot_goal), 0.0, 1.0)},
		{"label": "情报达到 %d 点" % intel_goal, "done": _expedition_intel_points() >= intel_goal, "progress": clampf(float(_expedition_intel_points()) / float(intel_goal), 0.0, 1.0)},
		{"label": "前往出口按 E 撤离", "done": extraction_ready and not current_exit_zone.is_empty(), "progress": 1.0 if extraction_ready else 0.0},
	]


func _biome_step_label(kind: String) -> String:
	match _biome_key():
		"wetland":
			return "记录 1 种水域/飞行动物" if kind == "animal" else "采样 1 个水源/芦苇热点"
		"forest":
			return "记录 1 种林下生物" if kind == "animal" else "采样 1 个林荫/倒木热点"
		"coast":
			return "记录 1 种海岸生物" if kind == "animal" else "采样 1 个潮汐/礁岩热点"
		_:
			return "记录 1 种迁徙动物" if kind == "animal" else "采样 1 个迁徙/水源热点"


func _region_biome_line() -> String:
	var names := PackedStringArray()
	for biome_variant in region_detail.get("dominant_biomes", []).slice(0, 2):
		names.append(_localized_biome_name(str(biome_variant)))
	if names.is_empty():
		return "复合生态区"
	return " / ".join(names)


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


func _region_species_brief() -> String:
	var names := PackedStringArray()
	for species_variant in species_manifest.slice(0, 3):
		var species: Dictionary = species_variant
		names.append(str(species.get("label", species.get("species_id", "物种"))))
	if names.is_empty():
		return "待记录"
	return "、".join(names)


func _draw_wildlife() -> void:
	var objective := _current_objective_target()
	for animal in wildlife:
		var pos := _screen_point(animal.get("position", Vector2.ZERO))
		var color: Color = animal.get("color", Color8(174, 191, 126))
		var group_size := int(animal.get("group_size", 1))
		var visual_count := mini(group_size, 3)
		for group_index in range(visual_count):
			var orbit := elapsed * (0.7 + 0.14 * group_index) + float(group_index) * 1.15
			var member_offset := Vector2(cos(orbit) * (14.0 + group_index * 9.0), sin(orbit * 1.2) * (7.0 + group_index * 5.0))
			var member_pos := pos + member_offset
			var scale := _animal_visual_scale(animal) * (1.0 if group_index == 0 else 0.74)
			var facing := -1.0 if sin(orbit) < 0.0 else 1.0
			_draw_animal_silhouette(animal, member_pos, color, scale, facing)
		var is_current: bool = not current_encounter.is_empty() and str(current_encounter.get("species_id", "")) == str(animal.get("species_id", ""))
		var is_objective: bool = str(objective.get("kind", "")) == "animal" and (animal.get("position", Vector2.ZERO) as Vector2).distance_to(objective.get("position", Vector2.ZERO)) < 2.0
		var label := _short_explorer_text("%s · %s" % [str(animal.get("label", "")), str(animal.get("category", ""))], 14)
		var label_pos := pos + Vector2(-58, 30)
		var label_rect := Rect2(label_pos + Vector2(-6, -14), Vector2(138, 22))
		var label_fill := Color8(22, 28, 23, 182) if is_current or is_objective else Color8(26, 32, 27, 132)
		_draw_panel(label_rect, label_fill, Color8(238, 226, 176, 120) if is_current or is_objective else Color8(238, 226, 176, 36), 7, 1)
		_draw_text(label_pos, label, 11, Color8(248, 243, 222, 230))


func _animal_visual_scale(animal: Dictionary) -> float:
	var species_id := str(animal.get("species_id", "")).to_lower()
	if "elephant" in species_id or "rhino" in species_id or "hippo" in species_id:
		return 1.55
	if "giraffe" in species_id:
		return 1.34
	if "lion" in species_id or "hyena" in species_id or "wild_dog" in species_id or "wolf" in species_id:
		return 1.18
	if "gazelle" in species_id or "antelope" in species_id or "deer" in species_id:
		return 1.08
	return 1.0


func _draw_interaction_prompts() -> void:
	if not current_encounter.is_empty():
		var pos := _screen_point(current_encounter.get("position", Vector2.ZERO))
		var species_id := str(current_encounter.get("species_id", ""))
		if not discovered_species_ids.has(species_id):
			_draw_interaction_ring(pos + Vector2(0, 18), Color8(230, 188, 102), "Space 记录")
	if not current_hotspot.is_empty():
		var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		if not completed_task_ids.has("task_" + hotspot_id):
			_draw_interaction_ring(_screen_point(_hotspot_position(hotspot_id)), Color8(118, 214, 164), "Space 采样")
	if not current_exit_zone.is_empty():
		var rect: Rect2 = current_exit_zone.get("rect", Rect2())
		_draw_interaction_ring(_screen_point(rect.position + rect.size * 0.5), Color8(232, 210, 142), "E 撤离")


func _draw_interaction_ring(pos: Vector2, accent: Color, text: String) -> void:
	var pulse := 0.5 + sin(elapsed * 5.0) * 0.5
	draw_arc(pos, 26.0 + pulse * 4.0, 0.0, TAU, 36, Color(accent.r, accent.g, accent.b, 0.34), 2.0, true)
	draw_circle(pos, 4.0, Color(accent.r, accent.g, accent.b, 0.82))
	_draw_text(pos + Vector2(14, -10), text, 12, Color8(246, 240, 214, 220))


func _draw_animal_silhouette(animal: Dictionary, pos: Vector2, color: Color, scale: float, facing: float) -> void:
	var category := str(animal.get("category", "区域生物"))
	var species_id := str(animal.get("species_id", "")).to_lower()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_ellipse(pos + Vector2(0, 12 * scale), Vector2(19, 6) * scale, Color(0, 0, 0, 0.13), 16)
	if category == "飞行动物":
		_draw_bird_silhouette(pos, color, scale, facing)
	elif category == "水域动物" or species_id in ["small_fish", "minnow", "carp", "catfish", "pike", "blackfish", "pufferfish", "shrimp", "crab", "frog"]:
		_draw_fish_silhouette(pos, color, scale, facing)
	elif category == "掠食者" or species_id in ["lion", "hyena", "wolf", "fox", "wild_dog"]:
		_draw_quadruped_silhouette(pos, color, scale, facing, true, species_id)
	else:
		_draw_quadruped_silhouette(pos, color, scale, facing, false, species_id)


func _draw_quadruped_silhouette(pos: Vector2, color: Color, scale: float, facing: float, predator: bool, species_id: String = "") -> void:
	var body := Vector2(24, 11) * scale
	var head_offset := Vector2(19 * facing, -5) * scale
	if "elephant" in species_id:
		body = Vector2(34, 17) * scale
		head_offset = Vector2(26 * facing, -4) * scale
	elif "giraffe" in species_id:
		body = Vector2(23, 10) * scale
		head_offset = Vector2(23 * facing, -27) * scale
	elif "gazelle" in species_id or "antelope" in species_id or "deer" in species_id:
		body = Vector2(25, 8) * scale
		head_offset = Vector2(22 * facing, -8) * scale
	_draw_ellipse(pos, body, color, 18)
	if "elephant" not in species_id:
		_draw_ellipse(pos + Vector2(-7 * facing, -8) * scale, Vector2(10, 7) * scale, color.darkened(0.05), 14)
	if "giraffe" in species_id:
		draw_line(pos + Vector2(11 * facing, -6) * scale, head_offset + pos, color.darkened(0.06), maxf(3.0, 4.6 * scale), true)
		for spot in [Vector2(-7, -3), Vector2(1, 1), Vector2(9, -2)]:
			draw_circle(pos + Vector2(spot.x * facing, spot.y) * scale, 2.0 * scale, color.darkened(0.20))
	_draw_ellipse(pos + head_offset, Vector2(9, 7) * scale, color.lightened(0.05), 14)
	var leg_color := color.darkened(0.18)
	var leg_length := 15.0
	if "giraffe" in species_id:
		leg_length = 24.0
	elif "elephant" in species_id:
		leg_length = 17.0
	for x in [-11, -3, 7, 14]:
		var foot_sway := sin(elapsed * 6.0 + float(x)) * 3.0 * scale
		var hip := pos + Vector2(float(x) * facing, 7) * scale
		draw_line(hip, hip + Vector2(foot_sway, leg_length * scale), leg_color, maxf(1.6, 2.8 * scale), true)
	var tail_end := pos + Vector2(-27 * facing, (-7 if predator else -2)) * scale
	draw_line(pos + Vector2(-20 * facing, -4) * scale, tail_end, leg_color, maxf(1.5, 2.2 * scale), true)
	if "elephant" in species_id:
		draw_line(pos + head_offset + Vector2(5 * facing, 3) * scale, pos + head_offset + Vector2(10 * facing, 20) * scale, leg_color, maxf(2.0, 3.2 * scale), true)
		draw_line(pos + head_offset + Vector2(7 * facing, 0) * scale, pos + head_offset + Vector2(15 * facing, 9) * scale, Color8(240, 228, 190), 1.2 * scale, true)
	elif predator:
		draw_circle(pos + head_offset + Vector2(4 * facing, -2) * scale, 1.8 * scale, Color8(250, 230, 176))
	else:
		draw_line(pos + head_offset + Vector2(1 * facing, -5) * scale, pos + head_offset + Vector2(5 * facing, -13) * scale, leg_color, 1.4 * scale, true)
		draw_line(pos + head_offset + Vector2(-2 * facing, -5) * scale, pos + head_offset + Vector2(-5 * facing, -12) * scale, leg_color, 1.4 * scale, true)


func _draw_bird_silhouette(pos: Vector2, color: Color, scale: float, facing: float) -> void:
	_draw_ellipse(pos, Vector2(10, 6) * scale, color, 14)
	var wing_color := color.darkened(0.08)
	var left_wing := PackedVector2Array([
		pos + Vector2(-4 * facing, 0) * scale,
		pos + Vector2(-25 * facing, -13) * scale,
		pos + Vector2(-12 * facing, 7) * scale,
	])
	var right_wing := PackedVector2Array([
		pos + Vector2(4 * facing, 0) * scale,
		pos + Vector2(24 * facing, -10) * scale,
		pos + Vector2(11 * facing, 8) * scale,
	])
	draw_colored_polygon(left_wing, wing_color)
	draw_colored_polygon(right_wing, wing_color.lightened(0.04))
	draw_circle(pos + Vector2(10 * facing, -3) * scale, 3.4 * scale, color.lightened(0.08))


func _draw_fish_silhouette(pos: Vector2, color: Color, scale: float, facing: float) -> void:
	_draw_ellipse(pos, Vector2(17, 8) * scale, color, 16)
	var tail := PackedVector2Array([
		pos + Vector2(-16 * facing, 0) * scale,
		pos + Vector2(-27 * facing, -8) * scale,
		pos + Vector2(-25 * facing, 8) * scale,
	])
	draw_colored_polygon(tail, color.darkened(0.10))
	draw_circle(pos + Vector2(9 * facing, -2) * scale, 1.8 * scale, Color8(236, 245, 238))


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color, segments: int = 18) -> void:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw_player() -> void:
	var pos := _screen_point(player_pos)
	draw_circle(pos + Vector2(0, 18), 15.0, Color(0, 0, 0, 0.16))
	var coat := Color8(56, 92, 124)
	var vest := Color8(218, 190, 116)
	var skin := Color8(226, 196, 152)
	_draw_ellipse(pos + Vector2(0, 8), Vector2(12, 19), coat, 18)
	_draw_ellipse(pos + Vector2(0, -13), Vector2(10, 10), skin, 16)
	draw_arc(pos + Vector2(0, -18), 14.0, PI, TAU, 20, Color8(92, 67, 42), 5.0, true)
	draw_line(pos + Vector2(-12, 1), pos + Vector2(-24, 12), coat.darkened(0.12), 3.0, true)
	draw_line(pos + Vector2(11, 1), pos + Vector2(22, 10), coat.darkened(0.12), 3.0, true)
	draw_line(pos + Vector2(-5, 24), pos + Vector2(-11, 38), Color8(48, 60, 68), 3.2, true)
	draw_line(pos + Vector2(5, 24), pos + Vector2(12, 38), Color8(48, 60, 68), 3.2, true)
	_draw_ellipse(pos + Vector2(0, 6), Vector2(5, 12), vest, 12)
	draw_line(pos + Vector2(16, -2), pos + Vector2(30, -18), Color8(72, 82, 74), 2.0, true)
	draw_circle(pos + Vector2(32, -20), 3.0, Color8(92, 112, 96))


func _draw_overlay() -> void:
	_draw_top_banner()
	_draw_ecology_radar()
	_draw_mainline_banner()
	_draw_mission_intro_card()
	_draw_event_banner()
	_draw_reward_feedback()
	_draw_survey_focus_strip()
	_draw_encounter_card()
	if show_codex:
		_draw_codex_panel()
	else:
		_draw_compact_task_tracker()
	_draw_controls()


func _draw_top_banner() -> void:
	_draw_panel(Rect2(24, 20, 390, 104), Color(0.05, 0.08, 0.11, 0.78), Color(0.92, 0.85, 0.62, 0.18), 28, 2)
	_draw_text(Vector2(42, 48), _exploration_title(), 28, Color8(245, 242, 228))
	_draw_text(Vector2(42, 76), "%s · %s" % [
		str(region_detail.get("name", "草原区")),
		_region_biome_line(),
	], 14, Color8(190, 205, 212))
	_draw_text(Vector2(42, 98), "物种：%s · 阶段 %s · 情报 %d · 危险 %s" % [
		_region_species_brief(),
		expedition_phase,
		_expedition_intel_points(),
		_threat_label(),
	], 13, Color8(176, 196, 202))

	_draw_panel(Rect2(size.x - 258, 20, 224, 64), Color(0.05, 0.08, 0.11, 0.68), Color(0.67, 0.8, 0.9, 0.14), 24, 2)
	var health: Dictionary = region_detail.get("health_state", {})
	_draw_text(Vector2(size.x - 236, 46), "繁荣 %d  稳定 %d  风险 %d" % [
		int(round(float(health.get("prosperity", 0.0)) * 100.0)),
		int(round(float(health.get("stability", 0.0)) * 100.0)),
		int(round(float(health.get("collapse_risk", 0.0)) * 100.0)),
	], 16, Color8(236, 242, 244))
	_draw_text(Vector2(size.x - 236, 68), "撤离 %s · 阈值 %d" % [("已准备" if extraction_ready else "未准备"), _required_extraction_intel()], 13, Color8(184, 203, 208))
	_draw_panel(Rect2(398, 20, 308, 64), Color(0.05, 0.08, 0.11, 0.68), Color(0.61, 0.77, 0.72, 0.14), 24, 2)
	_draw_text(Vector2(418, 44), "%s · %s" % [_region_state_label(), _chain_focus_text()], 14, Color8(226, 235, 229))
	_draw_text(Vector2(418, 67), _current_objective_summary(), 13, Color8(184, 203, 208))


func _draw_ecology_radar() -> void:
	var rect := Rect2(24, 112, 184, 122)
	_draw_panel(rect, Color(0.04, 0.07, 0.08, 0.58), Color(0.72, 0.86, 0.72, 0.12), 22, 1)
	_draw_text(rect.position + Vector2(16, 24), "生态雷达", 14, Color8(236, 233, 210, 210))
	var map_rect := Rect2(rect.position + Vector2(14, 34), Vector2(rect.size.x - 28, rect.size.y - 48))
	draw_rect(map_rect, Color(0.75, 0.82, 0.60, 0.08), true)
	draw_rect(map_rect, Color(1, 1, 1, 0.08), false, 1.0)

	for hotspot_variant in hotspots.slice(0, min(hotspots.size(), 5)):
		var hotspot: Dictionary = hotspot_variant
		var point := _radar_point(_hotspot_position(str(hotspot.get("hotspot_id", ""))), map_rect)
		var done := completed_task_ids.has("task_" + str(hotspot.get("hotspot_id", "")))
		draw_circle(point, 3.2, Color8(118, 214, 164, 110 if done else 210))
	for zone_variant in exit_zones:
		var zone: Dictionary = zone_variant
		var point := _radar_point(_exit_center(zone), map_rect)
		draw_circle(point, 3.6, Color8(232, 210, 142, 210))
	var target := _current_objective_target()
	if not target.is_empty():
		var target_point := _radar_point(target.get("position", player_pos), map_rect)
		draw_arc(target_point, 7.5, 0.0, TAU, 28, Color8(255, 220, 112, 230), 1.4, true)
		draw_circle(target_point, 3.0, Color8(255, 220, 112, 230))
	var player_point := _radar_point(player_pos, map_rect)
	draw_circle(player_point, 4.4, Color8(238, 238, 230, 230))
	draw_circle(player_point, 2.0, Color8(58, 92, 168, 230))
	_draw_text(rect.position + Vector2(16, 112), "白=你  黄=目标/出口  绿=热点", 10, Color8(180, 196, 190, 180))


func _radar_point(world_point: Vector2, radar_rect: Rect2) -> Vector2:
	var normalized := Vector2(
		clampf(world_point.x / WORLD_SIZE.x, 0.0, 1.0),
		clampf(world_point.y / WORLD_SIZE.y, 0.0, 1.0)
	)
	return radar_rect.position + Vector2(normalized.x * radar_rect.size.x, normalized.y * radar_rect.size.y)


func _draw_event_banner() -> void:
	if current_event.is_empty():
		return
	var accent: Color = current_event.get("accent", Color8(244, 213, 142))
	var rect := Rect2(size.x * 0.5 - 190, 214, 380, 58)
	_draw_panel(rect, Color(0.05, 0.08, 0.11, 0.76), Color(accent.r, accent.g, accent.b, 0.22), 24, 2)
	_draw_text(rect.position + Vector2(20, 27), str(current_event.get("title", "")), 17, Color8(246, 241, 228))
	_draw_text(rect.position + Vector2(20, 49), _short_explorer_text(str(current_event.get("body", "")), 42), 12, Color8(196, 210, 216))


func _draw_mainline_banner() -> void:
	var rect := Rect2(size.x * 0.5 - 300, 104, 600, 96)
	_draw_panel(rect, Color(0.04, 0.07, 0.09, 0.82), Color(1.0, 0.82, 0.32, 0.24), 26, 2)
	draw_circle(rect.position + Vector2(30, 36), 12.0, Color(1.0, 0.80, 0.30, 0.22))
	draw_circle(rect.position + Vector2(30, 36), 5.0, Color8(255, 221, 118, 230))
	_draw_text(rect.position + Vector2(52, 28), _mainline_title(), 18, Color8(250, 242, 214))
	_draw_text(rect.position + Vector2(52, 52), _mainline_current_instruction(), 13, Color8(211, 224, 222))
	_draw_text(rect.position + Vector2(52, 72), _world_task_reward_hint_short(), 12, Color8(169, 214, 180))
	var rows := _mainline_rows()
	var cursor_x := rect.position.x + 52.0
	var y := rect.position.y + 88.0
	for index in range(min(rows.size(), 4)):
		var row: Dictionary = rows[index]
		var done := bool(row.get("done", false))
		var x := cursor_x + float(index) * 132.0
		draw_circle(Vector2(x, y - 4.0), 4.0, Color8(132, 220, 154, 230) if done else Color8(238, 196, 96, 190))
		_draw_text(Vector2(x + 8.0, y), _short_explorer_text(str(row.get("label", "")), 8), 10, Color8(184, 204, 198))


func _draw_mission_intro_card() -> void:
	if mission_intro_timer <= 0.0 or world_task.is_empty():
		return
	var alpha := clampf(mission_intro_timer / 0.8, 0.0, 1.0) if mission_intro_timer < 0.8 else 1.0
	var rect := Rect2(size.x * 0.5 - 350, size.y * 0.5 - 142, 700, 284)
	_draw_panel(rect, Color(0.035, 0.055, 0.070, 0.88 * alpha), Color(1.0, 0.80, 0.30, 0.30 * alpha), 30, 2)
	draw_circle(rect.position + Vector2(44, 48), 18.0, Color(1.0, 0.76, 0.28, 0.18 * alpha))
	draw_circle(rect.position + Vector2(44, 48), 7.0, Color(1.0, 0.82, 0.34, 0.90 * alpha))
	var chapter := str(world_task.get("mainline_chapter", "区域主线"))
	if chapter == "":
		chapter = "区域主线"
	var action := str(world_task.get("action", "调查"))
	_draw_text(rect.position + Vector2(72, 40), chapter, 24, Color(0.98, 0.94, 0.78, alpha))
	_draw_text(rect.position + Vector2(72, 70), "本轮玩法：%s线 · %s" % [action, _mainline_short_phase()], 15, Color(0.78, 0.88, 0.84, alpha))
	var objective := str(world_task.get("mainline_objective", world_task.get("reason", "")))
	if objective == "":
		objective = str(world_task.get("reason", "跟随黄色目标完成本轮生态任务。"))
	_draw_text(rect.position + Vector2(36, 112), _short_explorer_text(objective, 56), 15, Color(0.86, 0.89, 0.84, alpha))
	var payoff := str(world_task.get("mainline_chapter_payoff", ""))
	if payoff != "":
		_draw_text(rect.position + Vector2(36, 134), "生态意义：%s" % _short_explorer_text(payoff, 48), 12, Color(0.70, 0.86, 0.74, alpha))
	var steps := _mission_intro_steps(action)
	for index in range(steps.size()):
		var y := rect.position.y + 152.0 + float(index) * 30.0
		draw_circle(Vector2(rect.position.x + 48, y - 5.0), 9.0, Color(1.0, 0.78, 0.28, 0.18 * alpha))
		_draw_text(Vector2(rect.position.x + 44, y), str(index + 1), 12, Color(0.98, 0.90, 0.62, alpha))
		_draw_text(Vector2(rect.position.x + 68, y), str(steps[index]), 14, Color(0.82, 0.90, 0.88, alpha))
	_draw_text(rect.position + Vector2(36, 262), "按 Tab 查看详细任务 · 按 M 返回世界图", 12, Color(0.62, 0.72, 0.74, alpha))


func _mission_intro_steps(action: String) -> Array:
	match action:
		"修复":
			return [
				"跟着黄色目标靠近风险热点",
				"按住 Space 完成热点采样",
				"情报达标后去出口按 E 撤离",
			]
		"通道":
			return [
				"跟着黄色目标找到目标出口",
				"靠近出口后按 E 完成本轮通道记录",
				"回世界图点击回灌报告强化连接",
			]
		_:
			return [
				"跟着黄色目标记录 1 种动物",
				"再采样 1 个生态热点",
				"情报达标后去出口按 E 撤离",
			]


func _draw_reward_feedback() -> void:
	if reward_feedback.is_empty() or reward_feedback_timer <= 0.0:
		return
	var alpha := clampf(reward_feedback_timer / 0.35, 0.0, 1.0) if reward_feedback_timer < 0.35 else 1.0
	var accent: Color = reward_feedback.get("accent", Color8(210, 182, 96))
	var rect := Rect2(size.x * 0.5 - 210, 108, 420, 92)
	_draw_panel(rect, Color(0.04, 0.08, 0.08, 0.74 * alpha), Color(accent.r, accent.g, accent.b, 0.24 * alpha), 26, 2)
	draw_circle(rect.position + Vector2(34, 44), 18.0, Color(accent.r, accent.g, accent.b, 0.18 * alpha))
	draw_circle(rect.position + Vector2(34, 44), 8.0, Color(accent.r, accent.g, accent.b, 0.88 * alpha))
	_draw_text(rect.position + Vector2(62, 32), str(reward_feedback.get("title", "")), 21, Color(0.98, 0.95, 0.84, alpha))
	_draw_text(rect.position + Vector2(62, 58), str(reward_feedback.get("gain", "")), 15, Color(accent.r, accent.g, accent.b, alpha))
	_draw_text(rect.position + Vector2(62, 78), str(reward_feedback.get("backend", "")), 12, Color(0.72, 0.86, 0.78, alpha))


func _draw_survey_focus_strip() -> void:
	var focus := _survey_focus_state()
	if focus.is_empty():
		return
	var rect := Rect2(24, size.y - 214, 356, 36)
	var accent: Color = focus.get("accent", Color8(210, 182, 96))
	_draw_panel(rect, Color(0.05, 0.08, 0.10, 0.74), Color(accent.r, accent.g, accent.b, 0.22), 18, 1)
	draw_circle(rect.position + Vector2(20, 18), 5.0, accent)
	_draw_text(rect.position + Vector2(34, 22), str(focus.get("text", "")), 13, Color8(226, 235, 228))


func _survey_focus_state() -> Dictionary:
	if survey_progress > 0.0 and survey_target_kind != "":
		var verb := "记录" if survey_target_kind == "species" else "采样"
		var accent := Color8(230, 188, 102) if survey_target_kind == "species" else Color8(118, 214, 164)
		return {
			"text": "已锁定%s：%s %.1f/%.1f 秒，继续按住 Space。" % [verb, survey_target_label, survey_progress, survey_required_time],
			"accent": accent,
		}
	if not current_encounter.is_empty():
		var species_id := str(current_encounter.get("species_id", ""))
		if discovered_species_ids.has(species_id):
			return {
				"text": "%s 已记录，继续找未记录目标或热点。" % str(current_encounter.get("label", "动物")),
				"accent": Color8(154, 172, 180),
			}
		if survey_target_kind == "species":
			return {
				"text": "已锁定记录 %s %.1f/%.1f 秒" % [str(current_encounter.get("label", "动物")), survey_progress, survey_required_time],
				"accent": Color8(230, 188, 102),
			}
		return {
			"text": "可记录：%s，按住 Space 锁定。" % str(current_encounter.get("label", "动物")),
			"accent": Color8(230, 188, 102),
		}
	if not current_hotspot.is_empty():
		var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		if completed_task_ids.has("task_" + hotspot_id):
			return {
				"text": "%s 已采样，继续找下一处。" % str(current_hotspot.get("label", "热点")),
				"accent": Color8(154, 172, 180),
			}
		if survey_target_kind == "hotspot":
			return {
				"text": "已锁定采样 %s %.1f/%.1f 秒" % [str(current_hotspot.get("label", "热点")), survey_progress, survey_required_time],
				"accent": Color8(118, 214, 164),
			}
		return {
			"text": "可采样：%s，按住 Space 锁定。" % str(current_hotspot.get("label", "热点")),
			"accent": Color8(118, 214, 164),
		}
	var target := _current_objective_target()
	if target.is_empty():
		return {}
	var world_pos: Vector2 = target.get("position", player_pos)
	var distance := int(round(player_pos.distance_to(world_pos)))
	return {
		"text": "前往目标：%s，距离 %dm。" % [str(target.get("label", "现场目标")), distance],
		"accent": Color8(255, 220, 112),
	}


func _draw_encounter_card() -> void:
	var rect := Rect2(24, size.y - 170, 356, 124)
	_draw_panel(rect, Color(0.06, 0.09, 0.12, 0.82), Color(0.95, 0.85, 0.6, 0.2), 26, 2)
	if not current_exit_zone.is_empty():
		_draw_text(rect.position + Vector2(22, 34), "出口 · " + str(current_exit_zone.get("label", "")), 22, Color8(245, 242, 228))
		_draw_text(rect.position + Vector2(22, 66), str(current_exit_zone.get("hint", "")), 14, Color8(187, 201, 208))
		_draw_text(rect.position + Vector2(22, 96), "按 E 撤离回世界图 · 当前情报 %d · 危险 %s" % [_expedition_intel_points(), _threat_label()], 14, Color8(170, 184, 191))
		_draw_text(rect.position + Vector2(22, 118), _exit_value_text(current_exit_zone, extraction_ready), 13, Color8(160, 176, 184))
		return
	if not current_hotspot.is_empty():
		var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		_draw_text(rect.position + Vector2(22, 34), "热点 · " + _biome_hotspot_label(hotspot_id), 22, Color8(245, 242, 228))
		_draw_text(rect.position + Vector2(22, 66), _biome_hotspot_summary(current_hotspot), 14, Color8(187, 201, 208))
		if survey_target_kind == "hotspot":
			_draw_text(rect.position + Vector2(22, 96), "按住 Space 采样 %.1f / %.1f 秒 · 完成后情报 +%d" % [survey_progress, survey_required_time, _hotspot_intel_reward(current_hotspot)], 14, Color8(170, 184, 191))
			_draw_progress_bar(Rect2(rect.position + Vector2(22, 104), Vector2(292, 10)), survey_progress, survey_required_time, Color8(110, 195, 164))
		else:
			_draw_text(rect.position + Vector2(22, 96), "站稳位置后按住 Space 开始采样 · 完成后情报 +%d。" % _hotspot_intel_reward(current_hotspot), 14, Color8(170, 184, 191))
		_draw_text(rect.position + Vector2(22, 118), _specialization_chain_state_text(), 13, Color8(160, 176, 184))
		return
	if current_encounter.is_empty():
		var handoff_task := _active_handoff_task()
		if not handoff_task.is_empty():
			_draw_text(rect.position + Vector2(22, 34), str(handoff_task.get("title", "承接任务")), 20, Color8(240, 240, 228))
			_draw_text(rect.position + Vector2(22, 66), str(handoff_task.get("body", "")), 14, Color8(182, 198, 205))
			_draw_text(rect.position + Vector2(22, 96), "先沿主线移动，贴近首个热点或目标生物后按住 Space 开始承接调查。", 14, Color8(164, 180, 188))
			return
		_draw_text(rect.position + Vector2(22, 34), "偶遇区域", 20, Color8(240, 240, 228))
		_draw_text(rect.position + Vector2(22, 66), "继续沿草地、水源和断崖移动，贴近动物或热点后主动调查。", 14, Color8(182, 198, 205))
		_draw_text(rect.position + Vector2(22, 96), "当前不是自动完成，按住 Space 才会把记录写进图鉴。", 14, Color8(164, 180, 188))
		return

	_draw_text(rect.position + Vector2(22, 34), "偶遇 · " + str(current_encounter.get("label", "")), 22, Color8(245, 242, 228))
	_draw_text(rect.position + Vector2(22, 66), "数量 %d · %s · %s" % [int(current_encounter.get("count", 0)), str(current_encounter.get("category", "")), str(current_encounter.get("activity", "移动"))], 15, Color8(208, 219, 222))
	if discovered_species_ids.has(str(current_encounter.get("species_id", ""))):
		_draw_text(rect.position + Vector2(22, 96), "这类动物已经记录过，继续追踪它们在热点附近的行为。", 14, Color8(184, 198, 205))
	elif survey_target_kind == "species":
		_draw_text(rect.position + Vector2(22, 96), "按住 Space 记录 %.1f / %.1f 秒 · 完成后情报 +%d" % [survey_progress, survey_required_time, _species_intel_reward(current_encounter)], 14, Color8(184, 198, 205))
		_draw_progress_bar(Rect2(rect.position + Vector2(22, 104), Vector2(292, 10)), survey_progress, survey_required_time, Color8(230, 188, 102))
	else:
		_draw_text(rect.position + Vector2(22, 96), "贴近目标后按住 Space 记录，再继续沿路径推进 · 情报 +%d。" % _species_intel_reward(current_encounter), 14, Color8(184, 198, 205))
	_draw_text(rect.position + Vector2(22, 118), _specialization_chain_state_text(), 13, Color8(160, 176, 184))


func _draw_codex_panel() -> void:
	var rect := Rect2(size.x - 360, 110, 320, size.y - 210)
	_draw_panel(rect, Color(0.05, 0.08, 0.11, 0.72), Color(0.78, 0.86, 0.9, 0.13), 30, 2)
	var action := str(world_task.get("action", "调查"))
	_draw_text(rect.position + Vector2(24, 34), "本轮生态任务", 24, Color8(244, 243, 235))
	_draw_text(rect.position + Vector2(24, 60), "%s · %s" % [action, _world_task_status_line()], 14, Color8(218, 229, 222))

	var task_rect := Rect2(rect.position + Vector2(18, 78), Vector2(rect.size.x - 36, 96))
	_draw_panel(task_rect, Color(0.18, 0.16, 0.10, 0.34), Color(0.92, 0.78, 0.42, 0.18), 20, 1)
	_draw_text(task_rect.position + Vector2(16, 26), _action_instruction_line(action), 15, Color8(246, 236, 198))
	_draw_text(task_rect.position + Vector2(16, 52), str(world_task.get("reason", "完成调查后撤离，结果会回灌世界。")), 12, Color8(210, 214, 202))
	_draw_text(task_rect.position + Vector2(16, 78), _world_task_backend_effect(action), 12, Color8(166, 206, 184))

	var objective_y := rect.position.y + 202
	_draw_text(Vector2(rect.position.x + 24, objective_y), "完成条件", 17, Color8(236, 230, 210))
	var objectives := _objective_rows()
	var objective_cursor_y := objective_y + 22.0
	for index in range(objectives.size()):
		if index >= 4:
			break
		var objective: Dictionary = objectives[index]
		if str(objective.get("title", "")) != "":
			_draw_text(Vector2(rect.position.x + 24, objective_cursor_y), str(objective.get("title", "")), 12, Color8(146, 169, 180))
			objective_cursor_y += 14.0
		var marker := "✓" if bool(objective.get("done", false)) else "·"
		_draw_text(Vector2(rect.position.x + 24, objective_cursor_y), "%s %s" % [marker, str(objective.get("label", ""))], 12, Color8(188, 203, 209))
		objective_cursor_y += 20.0

	var intel_y := objective_cursor_y + 10.0
	_draw_text(Vector2(rect.position.x + 24, intel_y), "已记录", 17, Color8(233, 230, 213))
	_draw_text(Vector2(rect.position.x + 24, intel_y + 24), "动物 %d 种 · 热点 %d 处 · 情报 %d / %d" % [
		discovered_species_ids.size(),
		discovered_hotspot_ids.size(),
		_expedition_intel_points(),
		_required_extraction_intel(),
	], 13, Color8(190, 205, 212))

	var species_y := intel_y + 58.0
	_draw_text(Vector2(rect.position.x + 24, species_y), "代表物种", 17, Color8(233, 230, 213))
	for index in range(min(species_manifest.size(), 6)):
		var entry: Dictionary = species_manifest[index]
		var x := rect.position.x + 24.0
		var y := species_y + 24.0 + index * 22.0
		var category := str(entry.get("category", "区域生物"))
		var color: Color = CATEGORY_COLORS.get(category, Color8(174, 191, 126))
		draw_circle(Vector2(x + 7, y + 7), 5.0, color)
		_draw_text(Vector2(x + 18, y + 10), "%s  %d" % [str(entry.get("label", "")), int(entry.get("count", 0))], 13, Color8(234, 238, 236))

	var bottom_y := rect.position.y + rect.size.y - 72.0
	if extraction_ready:
		_draw_text(Vector2(rect.position.x + 24, bottom_y), "可以撤离：靠近出口按 E，把本轮记录写回世界。", 13, Color8(174, 222, 190))
	else:
		_draw_text(Vector2(rect.position.x + 24, bottom_y), "继续靠近动物或热点，按住 Space 记录。", 13, Color8(196, 205, 210))
	_draw_text(Vector2(rect.position.x + 24, bottom_y + 22), "Tab 隐藏面板 · M 返回世界地图", 12, Color8(154, 172, 180))


func _draw_compact_task_tracker() -> void:
	var rect := Rect2(size.x - 342, size.y - 222, 308, 170)
	_draw_panel(rect, Color(0.05, 0.08, 0.10, 0.70), Color(0.92, 0.78, 0.42, 0.16), 24, 1)
	var action := str(world_task.get("action", "调查"))
	var task_done := _world_task_completed(current_exit_zone)
	_draw_text(rect.position + Vector2(18, 26), "主线进度", 17, Color8(244, 240, 222))
	_draw_text(rect.position + Vector2(18, 48), "当前行动：%s · %s" % [action, ("可撤离" if task_done or extraction_ready else "进行中")], 12, Color8(177, 205, 188))
	var missing_step := _world_task_missing_step()
	var helper_line := missing_step if missing_step != "" else _world_task_backend_effect(action)
	_draw_text(rect.position + Vector2(18, 66), _short_explorer_text(helper_line, 32), 11, Color8(154, 196, 168))
	var objectives := _mainline_rows()
	var y := rect.position.y + 88.0
	var shown := 0
	for objective_variant in objectives:
		var objective: Dictionary = objective_variant
		var label := str(objective.get("label", ""))
		if label == "":
			continue
		var marker := "✓" if bool(objective.get("done", false)) else "·"
		var text_color := Color8(174, 222, 190) if bool(objective.get("done", false)) else Color8(205, 215, 212)
		_draw_text(Vector2(rect.position.x + 18, y), "%s %s" % [marker, _short_explorer_text(label, 24)], 12, text_color)
		_draw_mini_progress(Rect2(rect.position + Vector2(18, y + 7), Vector2(258, 4)), float(objective.get("progress", 0.0)), bool(objective.get("done", false)))
		y += 22.0
		shown += 1
		if shown >= 4:
			break


func _draw_mini_progress(rect: Rect2, progress: float, done: bool) -> void:
	draw_rect(rect, Color(1, 1, 1, 0.08), true)
	var fill_rect := rect
	fill_rect.size.x *= clampf(progress, 0.0, 1.0)
	draw_rect(fill_rect, Color(0.50, 0.86, 0.58, 0.86) if done else Color(0.86, 0.68, 0.34, 0.72), true)


func _short_explorer_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length) + "..."


func _world_task_status_line() -> String:
	if world_task.is_empty():
		return "按区域状态自由调查"
	return "已完成" if _world_task_completed(current_exit_zone) else "进行中"


func _action_instruction_line(action: String) -> String:
	match action:
		"修复":
			return "采样热点，压低本区最高风险"
		"通道":
			return "找到出口，把本区接到目标区域"
		_:
			return "记录动物和热点，补齐生态情报"


func _world_task_backend_effect(action: String) -> String:
	match action:
		"修复":
			return "撤离回灌后：风险下降，生态韧性上升。"
		"通道":
			return "撤离回灌后：区域连接增强，物种流动更稳定。"
		_:
			return "撤离回灌后：调查覆盖率上升，资源判断更准确。"


func _backend_effect_for_intel(channel: String, source: String) -> String:
	var source_label := "采样" if source == "hotspot" else "记录"
	match channel:
		"水源":
			return "回灌后：水源可靠度上升，缺水风险判断更准。"
		"迁徙":
			return "回灌后：迁徙通道判断增强，区域连接更清楚。"
		"压迫":
			return "回灌后：捕食/压力模型更新，风险修复更准确。"
		"腐食":
			return "回灌后：腐食资源链更新，清道夫生态位更清楚。"
		"栖地":
			return "回灌后：庇护地质量更新，韧性和停留判断更准。"
		_:
			return "回灌后：%s会补强本区生态档案。" % source_label


func _show_reward_feedback(title: String, gain: String, backend: String, accent: Color) -> void:
	reward_feedback = {
		"title": title,
		"gain": gain,
		"backend": backend,
		"accent": accent,
	}
	reward_feedback_timer = 3.0


func _world_task_reward_hint() -> String:
	var action := str(world_task.get("action", "调查"))
	match action:
		"修复":
			return "若撤离时世界任务完成，后端会额外压低风险并提高韧性。"
		"通道":
			return "若从目标出口撤离，后端会增强区域通道连接。"
		_:
			return "撤离回灌后，后端会提高调查覆盖和资源判断。"


func _world_task_reward_hint_short() -> String:
	var action := str(world_task.get("action", "调查"))
	match action:
		"修复":
			return "回灌后：风险下降。"
		"通道":
			return "回灌后：通道增强。"
		_:
			return "回灌后：覆盖上升。"


func _draw_controls() -> void:
	var rect := Rect2(size.x * 0.5 - 164, size.y - 48, 328, 30)
	_draw_panel(rect, Color(0.05, 0.08, 0.11, 0.66), Color(0.76, 0.85, 0.9, 0.12), 16, 1)
	_draw_text(rect.position + Vector2(18, 20), "WASD 移动 · Space 调查 · E 撤离 · Tab 任务 · M 世界图", 13, Color8(213, 222, 226))


func _draw_progress_bar(rect: Rect2, value: float, max_value: float, fill_color: Color) -> void:
	draw_rect(rect, Color(1, 1, 1, 0.08), true)
	if max_value <= 0.0:
		return
	var fill_ratio := clampf(value / max_value, 0.0, 1.0)
	var fill_rect := Rect2(rect.position, Vector2(rect.size.x * fill_ratio, rect.size.y))
	draw_rect(fill_rect, fill_color, true)


func _draw_panel(rect: Rect2, fill: Color, outline: Color, radius: int, border_width: int) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = outline
	box.border_width_left = border_width
	box.border_width_right = border_width
	box.border_width_top = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	draw_style_box(box, rect)


func _draw_text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	if ui_font == null:
		return
	draw_string(ui_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

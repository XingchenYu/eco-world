extends Control

const DATA_PATH := "res://data/world_state.json"
const WORLD_MAP_SCENE := "res://scenes/world_map.tscn"
const WORLD_SIZE := Vector2(2800, 1700)
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
	{"id": "east_gate", "label": "河口联通口", "rect": Rect2(2480, 620, 220, 220), "hint": "沿河口进入下一片区域"},
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

var world_data: Dictionary = {}
var region_detail: Dictionary = {}
var current_region_id := ""
var current_theme: Dictionary = BIOME_THEMES["grassland"]
var current_region_layout: Dictionary = REGION_LAYOUTS["grassland"]
var species_manifest: Array = []
var hotspots: Array = []
var wildlife: Array = []
var exit_zones: Array = []
var player_pos := Vector2(1080, 960)
var camera_pos := Vector2.ZERO
var player_speed := 280.0
var elapsed := 0.0
var show_codex := true
var current_encounter: Dictionary = {}
var current_hotspot: Dictionary = {}
var current_exit_zone: Dictionary = {}
var current_event: Dictionary = {}
var current_interaction: Dictionary = {}
var current_chase: Dictionary = {}
var current_chase_result: Dictionary = {}
var current_task: Dictionary = {}
var discovered_species_ids: Dictionary = {}
var discovered_hotspot_ids: Dictionary = {}
var visited_region_ids: Dictionary = {}
var completed_task_ids: Dictionary = {}
var discovery_log: Array = []
var witnessed_pressure := false
var witnessed_chase_result := false
var hotspot_focus_time := 0.0
var chase_focus_time := 0.0
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
			var target_region_id := str(current_exit_zone.get("target_region_id", ""))
			if target_region_id != "":
				_apply_region(target_region_id, str(current_exit_zone.get("id", "")))
			else:
				get_tree().change_scene_to_file(WORLD_MAP_SCENE)


func _process(delta: float) -> void:
	elapsed += delta
	_update_player(delta)
	_update_wildlife()
	_update_camera()
	_update_encounter()
	_update_hotspot_focus(delta)
	_update_exit_zone()
	_update_event_focus()
	queue_redraw()


func _draw() -> void:
	var viewport_rect := Rect2(Vector2.ZERO, size)
	draw_rect(viewport_rect, current_theme.get("ground", Color8(214, 197, 138)))
	_draw_world_ground()
	_draw_world_routes()
	_draw_hotspots()
	_draw_wildlife()
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
	var target_region_id := ""
	var region_details: Dictionary = world_data.get("region_details", {})
	for region_id in region_details.keys():
		var detail: Dictionary = region_details[region_id]
		if "grassland" in detail.get("dominant_biomes", []):
			target_region_id = str(region_id)
			break
	if target_region_id == "":
		target_region_id = str(world_data.get("active_region", {}).get("id", ""))
	_apply_region(target_region_id)


func _apply_region(region_id: String, spawn_gate: String = "") -> void:
	var region_details: Dictionary = world_data.get("region_details", {})
	var next_detail: Dictionary = region_details.get(region_id, {})
	if next_detail.is_empty():
		return
	current_region_id = region_id
	region_detail = next_detail
	current_theme = _theme_for_region(next_detail)
	current_region_layout = _layout_for_region(next_detail)
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
	visited_region_ids[region_id] = true
	hotspot_focus_time = 0.0
	chase_focus_time = 0.0
	if spawn_gate != "" and GATE_SPAWNS.has(spawn_gate):
		player_pos = _find_safe_spawn(GATE_SPAWNS[spawn_gate])
	else:
		player_pos = _find_safe_spawn(DEFAULT_SPAWN)


func _build_exit_zones() -> void:
	exit_zones.clear()
	var links: Array = region_detail.get("frontier_links", [])
	for index in range(min(EXIT_LAYOUTS.size(), links.size())):
		var layout: Dictionary = EXIT_LAYOUTS[index]
		var link: Dictionary = links[index]
		exit_zones.append(
			{
				"id": str(layout.get("id", "")),
				"label": str(link.get("target_name", layout.get("label", "区域出口"))),
				"rect": layout.get("rect", Rect2()),
				"hint": "按 E 进入 " + str(link.get("target_name", "下一片区域")),
				"target_region_id": str(link.get("target_region_id", "")),
				"target_role": str(link.get("target_role", "生态观测区")),
			}
		)


func _build_wildlife() -> void:
	wildlife.clear()
	var capped_manifest := species_manifest.slice(0, min(species_manifest.size(), 18))
	for index in range(capped_manifest.size()):
		var entry: Dictionary = capped_manifest[index]
		var anchor_id := _anchor_for_species(str(entry.get("species_id", "")))
		var anchor: Vector2 = _hotspot_position(anchor_id)
		var phase := float(index) * 0.67
		var color: Color = CATEGORY_COLORS.get(str(entry.get("category", "区域生物")), Color8(174, 191, 126))
		var behavior := _behavior_for_species(str(entry.get("species_id", "")), str(entry.get("category", "区域生物")))
		var group_size := _group_size_for_species(str(entry.get("species_id", "")), str(entry.get("category", "区域生物")), int(entry.get("count", 0)))
		wildlife.append(
			{
				"species_id": str(entry.get("species_id", "")),
				"label": str(entry.get("label", entry.get("species_id", ""))),
				"count": int(entry.get("count", 0)),
				"category": str(entry.get("category", "区域生物")),
				"anchor_id": anchor_id,
				"anchor": anchor,
				"radius": Vector2(34 + (index % 4) * 18, 20 + (index % 3) * 14),
				"phase": phase,
				"speed": 0.28 + float((index % 5) + 1) * 0.06,
				"position": anchor,
				"color": color,
				"behavior": behavior,
				"group_size": group_size,
				"alert_radius": 110.0 + float(index % 4) * 18.0,
				"focus": Vector2.ZERO,
			}
		)


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


func _theme_for_region(detail: Dictionary) -> Dictionary:
	var biomes: Array = detail.get("dominant_biomes", [])
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return BIOME_THEMES["wetland"]
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return BIOME_THEMES["forest"]
	if "coast" in biomes or "seagrass" in biomes or "coral_reef" in biomes or "estuary" in biomes:
		return BIOME_THEMES["coast"]
	return BIOME_THEMES["grassland"]


func _layout_for_region(detail: Dictionary) -> Dictionary:
	var biomes: Array = detail.get("dominant_biomes", [])
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return REGION_LAYOUTS["wetland"]
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return REGION_LAYOUTS["forest"]
	if "coast" in biomes or "seagrass" in biomes or "coral_reef" in biomes or "estuary" in biomes:
		return REGION_LAYOUTS["coast"]
	return REGION_LAYOUTS["grassland"]


func _hotspot_position(hotspot_id: String) -> Vector2:
	var layout_hotspots: Dictionary = current_region_layout.get("hotspots", HOTSPOT_LAYOUT)
	return layout_hotspots.get(hotspot_id, HOTSPOT_LAYOUT.get(hotspot_id, WORLD_SIZE * 0.5))


func _active_obstacles() -> Array:
	return current_region_layout.get("obstacles", OBSTACLE_RECTS)


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
	return Vector2(720, 1080)


func _update_wildlife() -> void:
	var herd_focus := _herd_center()
	var prey_positions := _prey_positions()
	var strongest_pressure: Dictionary = {}
	var strongest_chase: Dictionary = {}
	for index in range(wildlife.size()):
		var animal: Dictionary = wildlife[index]
		var anchor: Vector2 = animal.get("anchor", Vector2.ZERO)
		var radius: Vector2 = animal.get("radius", Vector2(40, 24))
		var phase := float(animal.get("phase", 0.0))
		var speed := float(animal.get("speed", 0.32))
		var angle := elapsed * speed + phase
		var behavior := str(animal.get("behavior", "graze"))
		var base_pos := anchor + Vector2(cos(angle) * radius.x, sin(angle * 1.3) * radius.y)
		var bias_target := _behavior_bias_target(animal, phase)
		base_pos = base_pos.lerp(bias_target, 0.018)
		var player_delta := base_pos - player_pos
		var player_distance := player_delta.length()
		if behavior == "stalk":
			var prey_focus := _nearest_target(base_pos, prey_positions)
			if prey_focus != Vector2.ZERO:
				var chase_distance := base_pos.distance_to(prey_focus)
				var chase_burst := chase_distance < 150.0
				base_pos = base_pos.lerp(prey_focus, 0.038 if not chase_burst else 0.082)
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
				base_pos = base_pos.lerp(herd_focus, 0.018)
			if player_distance < 260.0:
				base_pos = base_pos.lerp(player_pos + player_delta.normalized() * 120.0, 0.018)
			base_pos.y += sin(angle * 0.45) * 18.0
		elif behavior == "glide":
			base_pos = anchor + Vector2(cos(angle * 0.76) * (radius.x + 24.0), sin(angle * 0.42) * (radius.y + 38.0) - 26.0)
			if player_distance < 150.0:
				base_pos += player_delta.normalized() * 46.0
		elif behavior == "swim":
			base_pos = base_pos.lerp(_hotspot_position("waterhole"), 0.026)
			base_pos = anchor + Vector2(cos(angle) * (radius.x * 0.82), sin(angle * 1.7) * (radius.y * 0.68))
		elif behavior == "heavy_roam":
			base_pos = anchor + Vector2(cos(angle * 0.52) * (radius.x + 12.0), sin(angle * 0.74) * (radius.y + 10.0))
			if player_distance < 140.0:
				base_pos += player_delta.normalized() * 22.0
		else:
			var nearest_predator := _nearest_predator_position(base_pos)
			if nearest_predator != Vector2.ZERO and base_pos.distance_to(nearest_predator) < 240.0:
				var flee := (base_pos - nearest_predator).normalized()
				base_pos += flee * (46.0 if base_pos.distance_to(nearest_predator) > 150.0 else 74.0)
			if player_distance < float(animal.get("alert_radius", 130.0)):
				base_pos += player_delta.normalized() * 28.0
		animal["position"] = base_pos
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
		chase_focus_time += 0.016
		current_chase = {
			"title": "追猎爆发",
			"body": "%s 已进入短时冲刺，草食群正在快速逃散。" % str(chase_predator.get("label", "掠食者")),
			"accent": Color8(255, 119, 86),
			"predator": chase_predator,
			"target": strongest_chase.get("target", Vector2.ZERO),
		}
		if float(strongest_chase.get("distance", 999999.0)) < 46.0:
			current_chase_result = {
				"title": "追猎命中",
				"body": "%s 成功切入草食群，群体被彻底冲散。" % str(chase_predator.get("label", "掠食者")),
				"accent": Color8(255, 96, 78),
			}
			witnessed_chase_result = true
			discovery_log.push_front("追猎命中：%s" % str(chase_predator.get("label", "掠食者")))
			discovery_log = discovery_log.slice(0, 6)
			chase_focus_time = 0.0
		elif chase_focus_time > 2.8:
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
	var nearest_distance := 100000.0
	for animal in wildlife:
		var distance := player_pos.distance_to(animal.get("position", Vector2.ZERO))
		if distance < 116.0 and distance < nearest_distance:
			current_encounter = animal
			nearest_distance = distance
	if not current_encounter.is_empty():
		_record_species_discovery(current_encounter)


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
			"body": str(current_exit_zone.get("label", "")) + " 已可进入。",
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
	if not current_hotspot.is_empty():
		current_event = {
			"title": "生态观察",
			"body": str(current_hotspot.get("label", "")) + " · " + str(current_hotspot.get("summary", "")),
			"accent": Color8(170, 224, 198),
		}
		return
	if not current_encounter.is_empty():
		current_event = {
			"title": "动物偶遇",
			"body": str(current_encounter.get("label", "")) + " · " + str(current_encounter.get("category", "")),
			"accent": Color8(244, 213, 142),
		}


func _update_hotspot_task() -> void:
	if current_hotspot.is_empty():
		return
	var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
	var task_id := "task_" + hotspot_id
	var hotspot_label := str(current_hotspot.get("label", "热点"))
	var task_config := _hotspot_task_config(hotspot_id)
	var required_time := float(task_config.get("required_time", 2.0))
	var required_category := str(task_config.get("required_category", ""))
	var required_presence := required_category == "" or _has_nearby_category(required_category, _hotspot_position(hotspot_id), 210.0)
	if completed_task_ids.has(task_id):
		current_task = {
			"title": "观察完成",
			"body": "%s 的%s已经记录进图鉴。" % [hotspot_label, str(task_config.get("noun", "观察"))],
			"accent": Color8(150, 216, 176),
		}
		return
	if hotspot_focus_time >= required_time:
		if not required_presence:
			current_task = {
				"title": str(task_config.get("title", "观察目标")),
				"body": "%s 还缺少%s，继续等待对应生物进入观察区。" % [hotspot_label, required_category],
				"accent": Color8(232, 194, 118),
			}
			return
		completed_task_ids[task_id] = true
		discovery_log.push_front("%s完成：%s" % [str(task_config.get("noun", "观察")), hotspot_label])
		discovery_log = discovery_log.slice(0, 6)
		current_task = {
			"title": "观察完成",
			"body": "%s 的%s已完成，继续寻找下一处目标。" % [hotspot_label, str(task_config.get("noun", "观察"))],
			"accent": Color8(150, 216, 176),
		}
		return
	current_task = {
		"title": str(task_config.get("title", "观察目标")),
		"body": "%s · %s %.1f / %.1f 秒%s" % [
			hotspot_label,
			str(task_config.get("prompt", "停留记录")),
			hotspot_focus_time,
			required_time,
			("" if required_category == "" else " · 目标生物：" + required_category),
		],
		"accent": Color8(170, 224, 198),
	}


func _hotspot_task_config(hotspot_id: String) -> Dictionary:
	match hotspot_id:
		"waterhole":
			return {"required_time": 1.8, "title": "水源采样", "prompt": "记录水源驻留", "noun": "水源观察", "required_category": "水域动物"}
		"migration_corridor":
			return {"required_time": 2.2, "title": "迁徙观察", "prompt": "跟进迁徙带活动", "noun": "迁徙观察", "required_category": "草食动物"}
		"predator_ridge":
			return {"required_time": 2.4, "title": "掠食观察", "prompt": "盯防掠食巡猎", "noun": "掠食观察", "required_category": "掠食者"}
		"carrion_field":
			return {"required_time": 2.0, "title": "腐食观察", "prompt": "记录腐食活动", "noun": "腐食观察", "required_category": "飞行动物"}
		_:
			return {"required_time": 2.1, "title": "林荫观察", "prompt": "记录林荫驻留", "noun": "栖地观察"}


func _has_nearby_category(category: String, center: Vector2, radius: float) -> bool:
	for animal in wildlife:
		if str(animal.get("category", "")) != category:
			continue
		if center.distance_to(animal.get("position", Vector2.ZERO)) <= radius:
			return true
	return false


func _objective_rows() -> Array:
	var stage := 1
	if discovered_species_ids.size() >= 3 and discovered_hotspot_ids.size() >= 2:
		stage = 2
	if witnessed_pressure and visited_region_ids.size() >= 2:
		stage = 3
	if stage == 1:
		return [
			{"title": "阶段一 · 建立观察", "label": "发现 3 种动物", "done": discovered_species_ids.size() >= 3},
			{"title": "", "label": "完成 1 个热点采样", "done": completed_task_ids.size() >= 1},
		]
	if stage == 2:
		return [
			{"title": "阶段二 · 见证压力", "label": "观察一次掠食追逐", "done": witnessed_pressure},
			{"title": "", "label": "完成 2 个不同热点任务", "done": completed_task_ids.size() >= 2},
		]
	return [
		{"title": "阶段三 · 扩展生态图", "label": "进入下一个区域", "done": visited_region_ids.size() >= 2},
		{"title": "", "label": "见证一次追猎命中或落空", "done": witnessed_chase_result},
	]


func _record_species_discovery(animal: Dictionary) -> void:
	var species_id := str(animal.get("species_id", ""))
	if species_id == "" or discovered_species_ids.has(species_id):
		return
	discovered_species_ids[species_id] = true
	discovery_log.push_front("发现动物：%s" % str(animal.get("label", species_id)))
	discovery_log = discovery_log.slice(0, 6)


func _record_hotspot_discovery(hotspot: Dictionary) -> void:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	if hotspot_id == "" or discovered_hotspot_ids.has(hotspot_id):
		return
	discovered_hotspot_ids[hotspot_id] = true
	discovery_log.push_front("记录热点：%s" % str(hotspot.get("label", hotspot_id)))
	discovery_log = discovery_log.slice(0, 6)


func _screen_point(world_point: Vector2) -> Vector2:
	return world_point - camera_pos


func _draw_world_ground() -> void:
	var terrain_points = [
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
	]
	draw_colored_polygon(terrain_points, Color8(201, 183, 122))

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


func _draw_grass_patch(center: Vector2, width: float, height: float, color: Color) -> void:
	var p := _screen_point(center)
	_draw_panel(Rect2(p - Vector2(width * 0.5, height * 0.5), Vector2(width, height)), color, Color(1, 1, 1, 0.04), 44, 1)


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
	draw_circle(center, 82.0, Color8(80, 145, 182, 215))
	draw_circle(center, 62.0, Color8(138, 209, 221, 210))
	_draw_text(center + Vector2(-34, 110), "主水源地", 18, Color8(239, 248, 246))


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
	var points = PackedVector2Array()
	for point in [Vector2(1870, 430), Vector2(2200, 350), Vector2(2360, 520), Vector2(2160, 660), Vector2(1860, 600)]:
		points.append(_screen_point(point))
	draw_colored_polygon(points, Color8(114, 101, 84, 220))
	draw_polyline(points + PackedVector2Array([points[0]]), Color8(232, 213, 162, 110), 3.0)


func _draw_carcass_field() -> void:
	var center := _screen_point(_hotspot_position("carrion_field"))
	draw_circle(center, 66.0, Color8(112, 76, 58, 170))
	draw_circle(center, 22.0, Color8(235, 223, 178, 220))
	draw_line(center + Vector2(-16, -8), center + Vector2(16, 8), Color8(132, 94, 72, 220), 4.0)
	draw_line(center + Vector2(-10, 16), center + Vector2(20, -14), Color8(132, 94, 72, 220), 4.0)


func _draw_world_routes() -> void:
	var route_lines = [
		[Vector2(430, 1280), Vector2(780, 1040), Vector2(1180, 930), Vector2(1560, 820), Vector2(2040, 540)],
		[Vector2(1180, 930), Vector2(1510, 760), Vector2(2140, 960)],
		[Vector2(720, 650), Vector2(1180, 930), Vector2(2040, 540)],
	]
	for route in route_lines:
		var poly = PackedVector2Array()
		for point in route:
			poly.append(_screen_point(point))
		draw_polyline(poly, current_theme.get("route_a", Color8(123, 97, 63, 150)), 18.0, true)
		draw_polyline(poly, current_theme.get("route_b", Color8(235, 219, 168, 235)), 6.0, true)

	for point in [Vector2(430, 1280), Vector2(2040, 540), Vector2(2490, 710)]:
		var screen_point := _screen_point(point)
		draw_circle(screen_point, 14.0, Color8(246, 233, 190, 230))
		draw_circle(screen_point, 6.0, Color8(112, 86, 54, 230))
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
		var local_rect := Rect2(_screen_point(rect.position), rect.size)
		var accent := Color(0.92, 0.84, 0.56, 0.16)
		if not current_exit_zone.is_empty() and str(current_exit_zone.get("id", "")) == str(zone["id"]):
			accent = Color(0.96, 0.9, 0.66, 0.28)
		_draw_panel(local_rect, Color(0.18, 0.12, 0.09, 0.08), accent, 22, 2)
		_draw_text(local_rect.position + Vector2(18, 28), str(zone["label"]), 17, Color8(245, 239, 220))
		_draw_text(local_rect.position + Vector2(18, 52), "出口", 12, Color8(188, 194, 198))


func _draw_hotspots() -> void:
	for hotspot in hotspots:
		var hotspot_id := str(hotspot.get("hotspot_id", ""))
		var label := str(hotspot.get("label", "热点"))
		var center := _screen_point(_hotspot_position(hotspot_id))
		var accent := Color(1.0, 0.95, 0.7, 0.08)
		if not current_hotspot.is_empty() and str(current_hotspot.get("hotspot_id", "")) == hotspot_id:
			accent = Color(1.0, 0.95, 0.7, 0.18)
		draw_circle(center, 28.0, accent)
		_draw_text(center + Vector2(-30, -42), label, 13, Color8(238, 235, 212, 188))


func _draw_wildlife() -> void:
	for animal in wildlife:
		var pos := _screen_point(animal.get("position", Vector2.ZERO))
		var color: Color = animal.get("color", Color8(174, 191, 126))
		var group_size := int(animal.get("group_size", 1))
		for group_index in range(group_size):
			var orbit := elapsed * (0.7 + 0.14 * group_index) + float(group_index) * 1.15
			var member_offset := Vector2(cos(orbit) * (8.0 + group_index * 5.0), sin(orbit * 1.2) * (5.0 + group_index * 4.0))
			var member_pos := pos + member_offset
			var radius := 16.0 if group_index == 0 else maxf(9.0, 13.0 - float(group_index))
			draw_circle(member_pos + Vector2(0, 12), radius * 0.62, Color(0, 0, 0, 0.12))
			draw_circle(member_pos, radius, color)
			draw_circle(member_pos, radius * 0.42, Color8(31, 38, 43, 200))
			if group_index == 0:
				_draw_text(member_pos + Vector2(-8, 6), CATEGORY_ICONS.get(str(animal.get("category", "")), "•"), 13, Color8(248, 245, 236))
		_draw_text(pos + Vector2(-26, 24), str(animal.get("label", "")), 11, Color8(242, 241, 230, 210))


func _draw_player() -> void:
	var pos := _screen_point(player_pos)
	draw_circle(pos + Vector2(0, 18), 14.0, Color(0, 0, 0, 0.16))
	draw_circle(pos, 16.0, Color8(235, 226, 205))
	draw_circle(pos + Vector2(0, -8), 14.0, Color8(207, 58, 58))
	draw_rect(Rect2(pos + Vector2(-14, -4), Vector2(28, 8)), Color8(220, 242, 246))
	draw_rect(Rect2(pos + Vector2(-10, 14), Vector2(20, 18)), Color8(67, 103, 175))
	draw_rect(Rect2(pos + Vector2(-15, -12), Vector2(30, 5)), Color8(245, 245, 230))


func _draw_overlay() -> void:
	_draw_top_banner()
	_draw_event_banner()
	_draw_encounter_card()
	if show_codex:
		_draw_codex_panel()
	_draw_controls()


func _draw_top_banner() -> void:
	_draw_panel(Rect2(24, 20, 360, 82), Color(0.05, 0.08, 0.11, 0.78), Color(0.92, 0.85, 0.62, 0.18), 28, 2)
	_draw_text(Vector2(42, 48), "生态草原 · 探索中", 28, Color8(245, 242, 228))
	_draw_text(Vector2(42, 76), str(region_detail.get("name", "草原区")) + "  自由探索 / 动物偶遇 / 区域跳转", 15, Color8(190, 205, 212))

	_draw_panel(Rect2(size.x - 258, 20, 224, 64), Color(0.05, 0.08, 0.11, 0.68), Color(0.67, 0.8, 0.9, 0.14), 24, 2)
	var health: Dictionary = region_detail.get("health_state", {})
	_draw_text(Vector2(size.x - 236, 46), "繁荣 %d  稳定 %d  风险 %d" % [
		int(round(float(health.get("prosperity", 0.0)) * 100.0)),
		int(round(float(health.get("stability", 0.0)) * 100.0)),
		int(round(float(health.get("collapse_risk", 0.0)) * 100.0)),
	], 16, Color8(236, 242, 244))


func _draw_event_banner() -> void:
	if current_event.is_empty():
		return
	var accent: Color = current_event.get("accent", Color8(244, 213, 142))
	var rect := Rect2(size.x * 0.5 - 170, 24, 340, 72)
	_draw_panel(rect, Color(0.05, 0.08, 0.11, 0.76), Color(accent.r, accent.g, accent.b, 0.22), 24, 2)
	_draw_text(rect.position + Vector2(20, 30), str(current_event.get("title", "")), 18, Color8(246, 241, 228))
	_draw_text(rect.position + Vector2(20, 56), str(current_event.get("body", "")), 13, Color8(196, 210, 216))


func _draw_encounter_card() -> void:
	var rect := Rect2(24, size.y - 170, 356, 124)
	_draw_panel(rect, Color(0.06, 0.09, 0.12, 0.82), Color(0.95, 0.85, 0.6, 0.2), 26, 2)
	if not current_exit_zone.is_empty():
		_draw_text(rect.position + Vector2(22, 34), "出口 · " + str(current_exit_zone.get("label", "")), 22, Color8(245, 242, 228))
		_draw_text(rect.position + Vector2(22, 66), str(current_exit_zone.get("hint", "")), 14, Color8(187, 201, 208))
		_draw_text(rect.position + Vector2(22, 96), "按 E 直接进入目标区域，不再只是返回世界图。", 14, Color8(170, 184, 191))
		return
	if not current_hotspot.is_empty():
		_draw_text(rect.position + Vector2(22, 34), "热点 · " + str(current_hotspot.get("label", "")), 22, Color8(245, 242, 228))
		_draw_text(rect.position + Vector2(22, 66), str(current_hotspot.get("summary", "")), 14, Color8(187, 201, 208))
		_draw_text(rect.position + Vector2(22, 96), "靠近这里会自动记录观察，图鉴里会累计生态发现。", 14, Color8(170, 184, 191))
		return
	if current_encounter.is_empty():
		_draw_text(rect.position + Vector2(22, 34), "偶遇区域", 20, Color8(240, 240, 228))
		_draw_text(rect.position + Vector2(22, 66), "继续沿草地、水源和断崖移动，靠近动物群即可触发观察。", 14, Color8(182, 198, 205))
		_draw_text(rect.position + Vector2(22, 96), "这里先给你可探索场景和可见生态，不再是总控面板。", 14, Color8(164, 180, 188))
		return

	_draw_text(rect.position + Vector2(22, 34), "偶遇 · " + str(current_encounter.get("label", "")), 22, Color8(245, 242, 228))
	_draw_text(rect.position + Vector2(22, 66), "数量 %d · %s" % [int(current_encounter.get("count", 0)), str(current_encounter.get("category", ""))], 15, Color8(208, 219, 222))
	_draw_text(rect.position + Vector2(22, 96), "观察它们在当前热点附近的活动，再继续沿路径推进。", 14, Color8(184, 198, 205))


func _draw_codex_panel() -> void:
	var rect := Rect2(size.x - 360, 110, 320, size.y - 210)
	_draw_panel(rect, Color(0.05, 0.08, 0.11, 0.76), Color(0.78, 0.86, 0.9, 0.14), 30, 2)
	_draw_text(rect.position + Vector2(24, 34), "区域生态图鉴", 24, Color8(244, 243, 235))
	_draw_text(rect.position + Vector2(24, 60), "当前区域所有生物 / 已发现物种 %d / 热点 %d" % [
		discovered_species_ids.size(),
		discovered_hotspot_ids.size(),
	], 13, Color8(178, 197, 205))

	var objective_y := rect.position.y + 86
	_draw_text(Vector2(rect.position.x + 24, objective_y), "探索目标", 17, Color8(236, 230, 210))
	var objectives := _objective_rows()
	for index in range(objectives.size()):
		var objective: Dictionary = objectives[index]
		var y := objective_y + 22 + index * 18
		if str(objective.get("title", "")) != "":
			_draw_text(Vector2(rect.position.x + 24, y), str(objective.get("title", "")), 12, Color8(146, 169, 180))
			y += 14
		var marker := "✓" if bool(objective.get("done", false)) else "·"
		_draw_text(Vector2(rect.position.x + 24, y), "%s %s" % [marker, str(objective.get("label", ""))], 12, Color8(188, 203, 209))

	var columns: Array = [rect.position.x + 24.0, rect.position.x + 166.0]
	var row_height := 24
	for index in range(min(species_manifest.size(), 18)):
		var entry: Dictionary = species_manifest[index]
		var column := index % 2
		var row := int(index / 2)
		var x: float = float(columns[column])
		var y: float = rect.position.y + 164.0 + row * row_height
		var category := str(entry.get("category", "区域生物"))
		var color: Color = CATEGORY_COLORS.get(category, Color8(174, 191, 126))
		draw_circle(Vector2(x + 7, y + 7), 5.0, color)
		_draw_text(Vector2(x + 18, y + 10), "%s  %d" % [str(entry.get("label", "")), int(entry.get("count", 0))], 13, Color8(234, 238, 236))

	var hotspot_y := rect.position.y + rect.size.y - 154
	_draw_text(Vector2(rect.position.x + 24, hotspot_y), "热点生态", 18, Color8(233, 230, 213))
	for index in range(min(hotspots.size(), 3)):
		var hotspot: Dictionary = hotspots[index]
		var y := hotspot_y + 26 + index * 24
		_draw_text(Vector2(rect.position.x + 24, y), "• " + str(hotspot.get("label", "")) + "  " + str(hotspot.get("summary", "")), 13, Color8(176, 194, 202))
	var pressure_y := hotspot_y + 100
	_draw_text(Vector2(rect.position.x + 24, pressure_y), "生态压力", 17, Color8(232, 227, 208))
	if current_interaction.is_empty():
		_draw_text(Vector2(rect.position.x + 24, pressure_y + 22), "暂未观测到掠食追逐。", 12, Color8(164, 181, 189))
	else:
		_draw_text(Vector2(rect.position.x + 24, pressure_y + 22), str(current_interaction.get("body", "")), 12, Color8(204, 188, 174))
	for index in range(min(discovery_log.size(), 3)):
		var y := pressure_y + 52 + index * 18
		_draw_text(Vector2(rect.position.x + 24, y), discovery_log[index], 12, Color8(206, 214, 218))


func _draw_controls() -> void:
	var rect := Rect2(size.x * 0.5 - 212, size.y - 48, 424, 30)
	_draw_panel(rect, Color(0.05, 0.08, 0.11, 0.66), Color(0.76, 0.85, 0.9, 0.12), 16, 1)
	_draw_text(rect.position + Vector2(18, 20), "WASD / 方向键移动   Shift 冲刺   Tab 图鉴开关   E 区域跳转   M 世界图", 13, Color8(213, 222, 226))


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

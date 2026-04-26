extends Node3D

const TerminalGuidance := preload("res://scripts/explorer_terminal_guidance.gd")
const AssetBindings := preload("res://scripts/explorer_asset_bindings.gd")
const DATA_PATH := "res://data/world_state.json"
const WORLD_MAP_SCENE := "res://scenes/world_map.tscn"
const REGION_SCALE := 2.1
const REGION_DISTANCE_SCALE := REGION_SCALE / 1.6
const LAYOUT_SPREAD_SCALE := 1.0 + (REGION_DISTANCE_SCALE - 1.0) * 0.72
const ROUTE_POINT_SPREAD_SCALE := 1.0 + (REGION_DISTANCE_SCALE - 1.0) * 0.86
const WORLD_BOUNDS := Rect2(-136.0, -100.0, 272.0, 200.0)
const PLAYER_SPEED := 8.5
const SPRINT_MULTIPLIER := 1.55
const CAMERA_OFFSET := Vector3(0.0, 10.8, 9.6)
const CAMERA_LOOK_OFFSET := Vector3(0.0, 1.6, 0.0)
const CAMERA_MOUSE_SENSITIVITY := 0.008
const CAMERA_KEYBOARD_TURN_SPEED := 1.9
const CAMERA_MIN_PITCH := -0.18
const CAMERA_MAX_PITCH := 1.22
const CAMERA_ZOOM_MIN := 0.76
const CAMERA_ZOOM_MAX := 1.22
const CAMERA_ZOOM_STEP := 0.08
const PLAYER_BODY_GROUND_HEIGHT := 0.92
const PLAYER_VISUAL_BASE_Y := -0.72
const PLAYER_SHADOW_BASE_Y := -0.88
const CAMERA_TURN_RESPONSE := 9.0
const CAMERA_TURN_DAMPING := 8.5
const CAMERA_YAW_MAX_SPEED := 2.6
const CAMERA_PITCH_MAX_SPEED := 1.9
const CATEGORY_COLORS := {
	"掠食者": Color8(214, 112, 87),
	"草食动物": Color8(216, 190, 104),
	"飞行动物": Color8(130, 170, 224),
	"水域动物": Color8(88, 176, 182),
	"区域生物": Color8(174, 191, 126),
}
const CATEGORY_ICONS := {
	"掠食者": "掠",
	"草食动物": "草",
	"飞行动物": "飞",
	"水域动物": "水",
	"区域生物": "域",
}
const BIOME_THEMES := {
	"grassland": {
		"ground": Color8(190, 168, 104),
		"route": Color8(240, 223, 176),
		"water": Color8(90, 152, 188),
		"foliage": Color8(96, 132, 74),
		"accent": Color8(236, 202, 118),
		"sky": Color8(164, 206, 236),
	},
	"wetland": {
		"ground": Color8(144, 158, 114),
		"route": Color8(214, 226, 188),
		"water": Color8(74, 136, 154),
		"foliage": Color8(106, 144, 92),
		"accent": Color8(178, 222, 176),
		"sky": Color8(168, 202, 220),
	},
	"forest": {
		"ground": Color8(104, 122, 96),
		"route": Color8(184, 172, 134),
		"water": Color8(82, 120, 144),
		"foliage": Color8(64, 96, 64),
		"accent": Color8(170, 206, 156),
		"sky": Color8(158, 188, 198),
	},
	"coast": {
		"ground": Color8(202, 194, 166),
		"route": Color8(244, 232, 192),
		"water": Color8(76, 156, 196),
		"foliage": Color8(100, 142, 96),
		"accent": Color8(216, 222, 180),
		"sky": Color8(180, 214, 240),
	},
}
const REGION_LAYOUTS := {
	"grassland": {
		"spawn": Vector3(-28.0, 0.9, 14.0),
		"hotspots": {
			"waterhole": Vector3(-18.0, 0.0, 12.0),
			"migration_corridor": Vector3(28.0, 0.0, -2.0),
			"predator_ridge": Vector3(24.0, 0.0, -14.0),
			"carrion_field": Vector3(10.0, 0.0, -12.0),
			"shade_grove": Vector3(-10.0, 0.0, -6.0),
		},
		"obstacles": [
			{"pos": Vector3(-10.0, 1.0, -6.0), "size": Vector3(8.0, 2.0, 6.0), "kind": "grove"},
			{"pos": Vector3(24.0, 2.0, -16.0), "size": Vector3(12.0, 4.0, 8.0), "kind": "ridge"},
			{"pos": Vector3(-18.0, 0.8, 12.0), "size": Vector3(7.0, 1.6, 7.0), "kind": "water"},
		],
		"props": {
			"trees": [Vector3(-14.0, 0.0, -10.0), Vector3(-6.0, 0.0, -2.0), Vector3(18.0, 0.0, 10.0)],
			"shrubs": [Vector3(-26.0, 0.0, 16.0), Vector3(4.0, 0.0, 8.0), Vector3(20.0, 0.0, -4.0)],
		},
	},
	"wetland": {
		"spawn": Vector3(-30.0, 0.9, 18.0),
		"hotspots": {
			"waterhole": Vector3(-22.0, 0.0, 12.0),
			"migration_corridor": Vector3(12.0, 0.0, -4.0),
			"predator_ridge": Vector3(18.0, 0.0, -10.0),
			"carrion_field": Vector3(-8.0, 0.0, -6.0),
			"shade_grove": Vector3(-18.0, 0.0, 18.0),
		},
		"obstacles": [
			{"pos": Vector3(-14.0, 0.8, 0.0), "size": Vector3(9.0, 1.6, 8.0), "kind": "marsh"},
			{"pos": Vector3(-22.0, 0.7, 12.0), "size": Vector3(9.0, 1.4, 8.0), "kind": "water"},
			{"pos": Vector3(18.0, 0.8, -10.0), "size": Vector3(8.0, 1.6, 6.0), "kind": "reed"},
		],
		"props": {
			"reeds": [Vector3(-22.0, 0.0, 8.0), Vector3(-8.0, 0.0, -2.0), Vector3(10.0, 0.0, -6.0)],
			"trees": [Vector3(-26.0, 0.0, 16.0), Vector3(18.0, 0.0, 10.0)],
		},
	},
	"forest": {
		"spawn": Vector3(-26.0, 0.9, 20.0),
		"hotspots": {
			"waterhole": Vector3(2.0, 0.0, 10.0),
			"migration_corridor": Vector3(18.0, 0.0, 0.0),
			"predator_ridge": Vector3(24.0, 0.0, -8.0),
			"carrion_field": Vector3(24.0, 0.0, 8.0),
			"shade_grove": Vector3(-18.0, 0.0, 18.0),
		},
		"obstacles": [
			{"pos": Vector3(-16.0, 1.2, 10.0), "size": Vector3(10.0, 2.4, 8.0), "kind": "forest"},
			{"pos": Vector3(20.0, 1.4, -6.0), "size": Vector3(10.0, 2.8, 8.0), "kind": "forest"},
			{"pos": Vector3(2.0, 0.9, 10.0), "size": Vector3(7.0, 1.8, 6.0), "kind": "water"},
		],
		"props": {
			"trees": [Vector3(-24.0, 0.0, 16.0), Vector3(-14.0, 0.0, 6.0), Vector3(12.0, 0.0, 10.0), Vector3(24.0, 0.0, 6.0)],
			"shrubs": [Vector3(-8.0, 0.0, 4.0), Vector3(10.0, 0.0, -6.0)],
		},
	},
	"coast": {
		"spawn": Vector3(-30.0, 0.9, 16.0),
		"hotspots": {
			"waterhole": Vector3(-20.0, 0.0, 14.0),
			"migration_corridor": Vector3(18.0, 0.0, 0.0),
			"predator_ridge": Vector3(18.0, 0.0, -10.0),
			"carrion_field": Vector3(24.0, 0.0, 6.0),
			"shade_grove": Vector3(-14.0, 0.0, -8.0),
		},
		"obstacles": [
			{"pos": Vector3(-20.0, 0.8, 14.0), "size": Vector3(9.0, 1.6, 8.0), "kind": "water"},
			{"pos": Vector3(18.0, 1.8, -10.0), "size": Vector3(12.0, 3.6, 6.0), "kind": "coast_ridge"},
		],
		"props": {
			"palms": [Vector3(-24.0, 0.0, 12.0), Vector3(-8.0, 0.0, 8.0), Vector3(20.0, 0.0, 10.0)],
			"reeds": [Vector3(-6.0, 0.0, 6.0), Vector3(14.0, 0.0, 2.0)],
		},
	},
}
const EXIT_LAYOUTS := [
	{"id": "west_gate", "pos": Vector3(-34.0, 0.0, 18.0), "spawn": Vector3(-28.0, 0.9, 16.0), "hint": "西部路线"},
	{"id": "north_gate", "pos": Vector3(22.0, 0.0, -22.0), "spawn": Vector3(18.0, 0.9, -18.0), "hint": "北部高地"},
	{"id": "east_gate", "pos": Vector3(32.0, 0.0, 8.0), "spawn": Vector3(26.0, 0.9, 8.0), "hint": "东部联通口"},
]

var world_data: Dictionary = {}
var region_detail: Dictionary = {}
var current_region_id := ""
var current_biome := "grassland"
var current_layout: Dictionary = REGION_LAYOUTS["grassland"]
var current_theme: Dictionary = BIOME_THEMES["grassland"]
var current_world_bounds := WORLD_BOUNDS
var species_manifest: Array = []
var hotspots: Array = []
var dynamic_region_state: Dictionary = {}
var wildlife: Array = []
var exit_zones: Array = []
var current_exit_layouts: Array = []
var current_encounter: Dictionary = {}
var current_hotspot: Dictionary = {}
var current_exit_zone: Dictionary = {}
var current_event: Dictionary = {}
var current_interaction: Dictionary = {}
var current_chase: Dictionary = {}
var current_chase_result: Dictionary = {}
var chase_aftermath: Dictionary = {}
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
var show_codex := true
var movement_blend := 0.0
var current_speed_ratio := 0.0
var camera_yaw := 0.0
var camera_pitch := 0.84
var camera_yaw_velocity := 0.0
var camera_pitch_velocity := 0.0
var camera_zoom := 1.0
var camera_zoom_target := 1.0
var smoothed_route_focus := Vector3.ZERO
var smoothed_camera_look := Vector3.ZERO
var smoothed_camera_focus_target := Vector3.ZERO
var smoothed_gate_focus_hold := 0.0
var route_focus_ready := false
var camera_look_ready := false
var camera_focus_target_ready := false
var hotspot_visuals: Dictionary = {}
var exit_visuals: Dictionary = {}
var ambient_visuals: Array = []
var ambient_stage_visuals: Dictionary = {}
var route_stage_visuals: Array = []
var current_route_stage := "entry"
var current_route_focus: Dictionary = {}

var environment_root: Node3D
var terrain_asset_root: Node3D
var vegetation_asset_root: Node3D
var ambient_root: Node3D
var wildlife_root: Node3D
var hotspot_root: Node3D
var exit_root: Node3D
var aftermath_root: Node3D
var player_body: CharacterBody3D
var player_visual: Node3D
var player_shadow: MeshInstance3D
var player_arm_left: MeshInstance3D
var player_arm_right: MeshInstance3D
var player_leg_left: MeshInstance3D
var player_leg_right: MeshInstance3D
var camera_node: Camera3D
var sun_light: DirectionalLight3D
var world_environment: WorldEnvironment

var ui_layer: CanvasLayer
var region_label: Label
var stats_label: Label
var event_label: Label
var codex_panel: Panel
var codex_title: Label
var objectives_label: Label
var species_label: Label
var log_label: Label
var hint_label: Label
var transition_panel: Panel
var transition_label: Label
var transition_timer := 0.0
var transition_duration := 0.0
var pending_gate_transition: Dictionary = {}
var pending_arrival_intro: Dictionary = {}
var arrival_event_focus_timer := 0.0
var transition_restore_codex := true


func _ready() -> void:
	_setup_roots()
	_setup_world()
	_setup_player()
	_setup_ui()
	_load_region_payload()
	_update_camera(true)
	set_process(true)
	set_physics_process(true)


func _setup_roots() -> void:
	environment_root = Node3D.new()
	environment_root.name = "EnvironmentRoot"
	add_child(environment_root)

	terrain_asset_root = Node3D.new()
	terrain_asset_root.name = "TerrainAssetRoot"
	add_child(terrain_asset_root)

	vegetation_asset_root = Node3D.new()
	vegetation_asset_root.name = "VegetationAssetRoot"
	add_child(vegetation_asset_root)

	ambient_root = Node3D.new()
	ambient_root.name = "AmbientRoot"
	add_child(ambient_root)

	hotspot_root = Node3D.new()
	hotspot_root.name = "HotspotRoot"
	add_child(hotspot_root)

	wildlife_root = Node3D.new()
	wildlife_root.name = "WildlifeRoot"
	add_child(wildlife_root)

	exit_root = Node3D.new()
	exit_root.name = "ExitRoot"
	add_child(exit_root)

	aftermath_root = Node3D.new()
	aftermath_root.name = "AftermathRoot"
	add_child(aftermath_root)


func _setup_world() -> void:
	world_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color8(164, 206, 236)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color8(195, 204, 214)
	env.ambient_light_energy = 1.15
	env.fog_enabled = true
	env.fog_light_color = Color8(208, 220, 232)
	env.fog_light_energy = 0.82
	env.fog_density = 0.008
	env.fog_aerial_perspective = 0.28
	env.fog_sun_scatter = 0.18
	world_environment.environment = env
	add_child(world_environment)
	_apply_real_biome_environment()

	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-48.0, 34.0, 0.0)
	sun_light.light_energy = 2.1
	add_child(sun_light)


func _setup_player() -> void:
	player_body = CharacterBody3D.new()
	player_body.name = "Player"
	player_body.position = Vector3(0.0, 0.9, 0.0)
	add_child(player_body)

	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.0
	collider.shape = capsule
	player_body.add_child(collider)

	player_shadow = MeshInstance3D.new()
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.34
	shadow_mesh.bottom_radius = 0.48
	shadow_mesh.height = 0.04
	player_shadow.mesh = shadow_mesh
	player_shadow.position = Vector3(0.0, PLAYER_SHADOW_BASE_Y, 0.0)
	player_shadow.material_override = _material(Color(0.0, 0.0, 0.0), 0.24)
	player_body.add_child(player_shadow)

	player_visual = Node3D.new()
	player_visual.position.y = PLAYER_VISUAL_BASE_Y
	player_body.add_child(player_visual)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.height = 1.14
	body_mesh.radius = 0.32
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.62, 0.0)
	body.material_override = _material(Color8(208, 68, 70))
	player_visual.add_child(body)

	var torso := MeshInstance3D.new()
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.52, 0.58, 0.32)
	torso.mesh = torso_mesh
	torso.position = Vector3(0.0, 0.58, 0.0)
	torso.material_override = _material(Color8(70, 108, 174))
	player_visual.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.12, 0.0)
	head.material_override = _material(Color8(236, 220, 194))
	player_visual.add_child(head)

	player_arm_left = MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.14, 0.52, 0.14)
	player_arm_left.mesh = arm_mesh
	player_arm_left.position = Vector3(-0.38, 0.6, 0.0)
	player_arm_left.material_override = _material(Color8(208, 68, 70))
	player_visual.add_child(player_arm_left)

	player_arm_right = MeshInstance3D.new()
	player_arm_right.mesh = arm_mesh
	player_arm_right.position = Vector3(0.38, 0.6, 0.0)
	player_arm_right.material_override = _material(Color8(208, 68, 70))
	player_visual.add_child(player_arm_right)

	player_leg_left = MeshInstance3D.new()
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.15, 0.56, 0.16)
	player_leg_left.mesh = leg_mesh
	player_leg_left.position = Vector3(-0.12, 0.1, 0.0)
	player_leg_left.material_override = _material(Color8(78, 64, 88))
	player_visual.add_child(player_leg_left)

	player_leg_right = MeshInstance3D.new()
	player_leg_right.mesh = leg_mesh
	player_leg_right.position = Vector3(0.12, 0.1, 0.0)
	player_leg_right.material_override = _material(Color8(78, 64, 88))
	player_visual.add_child(player_leg_right)

	camera_node = Camera3D.new()
	camera_node.current = true
	camera_node.fov = 49.0
	add_child(camera_node)
	camera_pitch = asin(clampf(CAMERA_OFFSET.y / maxf(CAMERA_OFFSET.length(), 0.001), -1.0, 1.0))
	camera_zoom = 1.0
	camera_zoom_target = 1.0
	smoothed_route_focus = player_body.global_position
	route_focus_ready = true


func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24.0, 20.0)
	top_panel.size = Vector2(420.0, 92.0)
	root.add_child(top_panel)

	region_label = Label.new()
	region_label.position = Vector2(18.0, 14.0)
	region_label.size = Vector2(380.0, 32.0)
	region_label.add_theme_font_size_override("font_size", 28)
	top_panel.add_child(region_label)

	stats_label = Label.new()
	stats_label.position = Vector2(18.0, 50.0)
	stats_label.size = Vector2(380.0, 30.0)
	stats_label.add_theme_font_size_override("font_size", 16)
	top_panel.add_child(stats_label)

	var event_panel := Panel.new()
	event_panel.position = Vector2(480.0, 20.0)
	event_panel.size = Vector2(520.0, 84.0)
	root.add_child(event_panel)

	event_label = Label.new()
	event_label.position = Vector2(18.0, 16.0)
	event_label.size = Vector2(480.0, 52.0)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.add_theme_font_size_override("font_size", 18)
	event_panel.add_child(event_label)

	codex_panel = Panel.new()
	codex_panel.position = Vector2(1240.0, 110.0)
	codex_panel.size = Vector2(320.0, 760.0)
	root.add_child(codex_panel)

	codex_title = Label.new()
	codex_title.position = Vector2(18.0, 16.0)
	codex_title.size = Vector2(260.0, 28.0)
	codex_title.add_theme_font_size_override("font_size", 24)
	codex_panel.add_child(codex_title)

	objectives_label = Label.new()
	objectives_label.position = Vector2(18.0, 58.0)
	objectives_label.size = Vector2(280.0, 160.0)
	objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objectives_label.add_theme_font_size_override("font_size", 14)
	codex_panel.add_child(objectives_label)

	species_label = Label.new()
	species_label.position = Vector2(18.0, 230.0)
	species_label.size = Vector2(280.0, 280.0)
	species_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	species_label.add_theme_font_size_override("font_size", 13)
	codex_panel.add_child(species_label)

	log_label = Label.new()
	log_label.position = Vector2(18.0, 528.0)
	log_label.size = Vector2(280.0, 190.0)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 13)
	codex_panel.add_child(log_label)

	var hint_panel := Panel.new()
	hint_panel.position = Vector2(350.0, 906.0)
	hint_panel.size = Vector2(900.0, 34.0)
	root.add_child(hint_panel)

	hint_label = Label.new()
	hint_label.position = Vector2(18.0, 8.0)
	hint_label.size = Vector2(860.0, 20.0)
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_panel.add_child(hint_label)

	transition_panel = Panel.new()
	transition_panel.position = Vector2(540.0, 120.0)
	transition_panel.size = Vector2(520.0, 88.0)
	transition_panel.visible = false
	root.add_child(transition_panel)

	transition_label = Label.new()
	transition_label.position = Vector2(20.0, 16.0)
	transition_label.size = Vector2(480.0, 56.0)
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.add_theme_font_size_override("font_size", 26)
	transition_panel.add_child(transition_label)


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
	var target_region_id := ""
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
	current_biome = _biome_key_for_region(next_detail)
	current_layout = _scaled_layout(REGION_LAYOUTS.get(current_biome, REGION_LAYOUTS["grassland"]))
	current_theme = BIOME_THEMES.get(current_biome, BIOME_THEMES["grassland"])
	current_exit_layouts = _scaled_exit_layouts()
	current_world_bounds = _compute_world_bounds()
	species_manifest = region_detail.get("species_manifest", [])
	if species_manifest.is_empty():
		species_manifest = region_detail.get("top_species", [])
	hotspots = region_detail.get("exploration_hotspots", [])
	dynamic_region_state = region_detail.get("dynamic_region_state", {})
	visited_region_ids[region_id] = true
	current_encounter.clear()
	current_hotspot.clear()
	current_exit_zone.clear()
	current_event.clear()
	current_interaction.clear()
	current_chase.clear()
	current_chase_result.clear()
	chase_aftermath.clear()
	current_task.clear()
	hotspot_focus_time = 0.0
	chase_focus_time = 0.0
	_build_world_geometry()
	_build_wildlife()
	_build_exit_zones()
	var spawn: Vector3 = current_layout.get("spawn", Vector3.ZERO)
	if spawn_gate != "":
		for exit_data in current_exit_layouts:
			if str(exit_data.get("id", "")) == spawn_gate:
				spawn = exit_data.get("spawn", spawn)
				break
	player_body.global_position = spawn
	smoothed_route_focus = player_body.global_position
	route_focus_ready = true
	pending_arrival_intro.clear()
	if spawn_gate != "":
		var exit_profile := _biome_exit_profile()
		var arrival_dir := _gate_forward_vector(spawn_gate) * -1.0
		pending_arrival_intro = {
			"timer": float(exit_profile.get("arrival_duration", 0.72)),
			"duration": float(exit_profile.get("arrival_duration", 0.72)),
			"direction": arrival_dir,
			"start_position": spawn - arrival_dir * 2.2,
			"end_position": spawn,
			"label": region_detail.get("name", "新区域"),
		}
		player_body.global_position = Vector3(pending_arrival_intro.get("start_position", spawn))
		smoothed_route_focus = player_body.global_position
		if not _using_real_terrain_asset():
			_add_arrival_entry_runway(spawn, arrival_dir)
	_start_region_transition(region_detail.get("name", "新区域"), _biome_label(current_biome), spawn_gate != "")
	_update_camera(true)
	_refresh_ui()


func _build_world_geometry() -> void:
	_clear_children(environment_root)
	_clear_children(terrain_asset_root)
	_clear_children(vegetation_asset_root)
	_clear_children(ambient_root)
	_clear_children(hotspot_root)
	_clear_children(exit_root)
	_clear_children(aftermath_root)
	hotspot_visuals.clear()
	exit_visuals.clear()
	ambient_visuals.clear()
	ambient_stage_visuals.clear()
	route_stage_visuals.clear()
	current_route_focus.clear()

	if world_environment.environment != null:
		_apply_real_biome_environment()

	var floor_size := Vector3(current_world_bounds.size.x, 1.0, current_world_bounds.size.y)
	var floor_center := Vector3(current_world_bounds.position.x + current_world_bounds.size.x * 0.5, -0.5, current_world_bounds.position.y + current_world_bounds.size.y * 0.5)
	_add_floor_collider(floor_center, floor_size)
	_build_terrain_layer()

	_build_routes()
	_build_biome_ambient_cues()
	_build_biome_stage_shells()
	_build_hotspots()
	_build_obstacles()
	_build_vegetation_layer()
	# Large procedural blocker layers stay disabled until the environment pass is rebuilt.


func _build_terrain_layer() -> void:
	_build_ground_surface()
	_build_terrain_layers()
	_instance_real_surface_floor()


func _build_vegetation_layer() -> void:
	_build_props()


func _using_real_terrain_asset() -> bool:
	return false


func _sanitize_real_terrain_instance(node: Node) -> void:
	if node == null:
		return
	if node is Node3D:
		var node3d := node as Node3D
		var hidden_tokens := [
			"Far",
			"Wall",
			"Ridge",
			"Shelf",
			"Shoulder",
			"Skirt",
			"Rise",
			"Spur",
			"Face",
			"Cut",
			"Berm",
			"Dune",
			"Ravine",
			"Cliff",
		]
		for token in hidden_tokens:
			if node3d.name.contains(token):
				node3d.visible = false
				break
	for child in node.get_children():
		_sanitize_real_terrain_instance(child)


func _try_instance_biome_asset(root: Node3D, scene_path: String) -> bool:
	var instance := AssetBindings.instantiate_scene(scene_path)
	if instance == null:
		return false
	if instance is Node3D:
		(instance as Node3D).position = Vector3.ZERO
	root.add_child(instance)
	if root == terrain_asset_root:
		_sanitize_real_terrain_instance(instance)
	return true


func _apply_real_biome_environment() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env := world_environment.environment
	var hdri_path := AssetBindings.biome_real_hdri_path(current_biome)
	if hdri_path != "":
		var panorama := load(hdri_path) as Texture2D
		if panorama != null:
			var sky_material := PanoramaSkyMaterial.new()
			sky_material.panorama = panorama
			var sky := Sky.new()
			sky.sky_material = sky_material
			env.background_mode = Environment.BG_SKY
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_energy = 1.1
			return
	env.background_mode = Environment.BG_COLOR
	env.sky = null
	env.background_color = current_theme.get("sky", Color8(164, 206, 236))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color8(195, 204, 214)
	env.ambient_light_energy = 1.15


func _instance_real_surface_floor() -> void:
	var texture_paths := AssetBindings.biome_real_surface_texture_paths(current_biome)
	if texture_paths.is_empty():
		return
	var floor_root := Node3D.new()
	floor_root.name = "RealSurfaceFloor"
	terrain_asset_root.add_child(floor_root)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Surface"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(current_world_bounds.size.x, current_world_bounds.size.y)
	mesh_instance.mesh = mesh
	mesh_instance.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	mesh_instance.position = Vector3(
		current_world_bounds.position.x + current_world_bounds.size.x * 0.5,
		_ground_contact_height_at(
			current_world_bounds.position.x + current_world_bounds.size.x * 0.5,
			current_world_bounds.position.y + current_world_bounds.size.y * 0.5
		) + 0.03,
		current_world_bounds.position.y + current_world_bounds.size.y * 0.5
	)
	var material := StandardMaterial3D.new()
	material.roughness = 1.0
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.uv1_scale = Vector3(
		maxf(1.0, current_world_bounds.size.x / 18.0),
		maxf(1.0, current_world_bounds.size.y / 18.0),
		1.0
	)
	var albedo := load(str(texture_paths.get("albedo", ""))) as Texture2D
	var normal := load(str(texture_paths.get("normal", ""))) as Texture2D
	var roughness := load(str(texture_paths.get("roughness", ""))) as Texture2D
	if albedo != null:
		material.albedo_texture = albedo
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
	if roughness != null:
		material.roughness_texture = roughness
	mesh_instance.material_override = material
	floor_root.add_child(mesh_instance)


func _instance_real_vegetation_assets() -> void:
	return


func _real_vegetation_layouts() -> Array[Dictionary]:
	match current_biome:
		"wetland":
			return [
				{"kind": "tree", "x": -34.0, "z": 18.0, "scale": 1.8, "yaw": 14.0},
				{"kind": "ground_cover", "x": -14.0, "z": 24.0, "scale": 2.2, "yaw": 0.0},
				{"kind": "shrub", "x": 20.0, "z": 12.0, "scale": 1.5, "yaw": -18.0},
				{"kind": "root", "x": 6.0, "z": -8.0, "scale": 1.6, "yaw": 26.0},
			]
		"forest":
			return [
				{"kind": "tree", "x": -18.0, "z": -22.0, "scale": 2.6, "yaw": 8.0},
				{"kind": "tree", "x": 32.0, "z": 16.0, "scale": 2.2, "yaw": -12.0},
				{"kind": "moss", "x": -8.0, "z": 14.0, "scale": 2.0, "yaw": 0.0},
				{"kind": "root", "x": 14.0, "z": -6.0, "scale": 1.8, "yaw": 32.0},
				{"kind": "deadwood", "x": 26.0, "z": -18.0, "scale": 1.5, "yaw": -22.0},
			]
		"coast":
			return [
				{"kind": "ground_cover", "x": 8.0, "z": 6.0, "scale": 2.2, "yaw": 0.0},
				{"kind": "shrub", "x": -12.0, "z": -8.0, "scale": 1.4, "yaw": 24.0},
				{"kind": "deadwood", "x": 20.0, "z": -18.0, "scale": 1.4, "yaw": -36.0},
			]
		_:
			return [
				{"kind": "tree", "x": -42.0, "z": 22.0, "scale": 2.0, "yaw": 12.0},
				{"kind": "tree", "x": 36.0, "z": 18.0, "scale": 1.8, "yaw": -10.0},
				{"kind": "shrub", "x": 10.0, "z": 16.0, "scale": 1.5, "yaw": 18.0},
				{"kind": "ground_cover", "x": -8.0, "z": 10.0, "scale": 2.6, "yaw": 0.0},
			]


func _species_asset_scene_path(species_id: String) -> String:
	return AssetBindings.species_scene_path(species_id)


func _is_imported_visual_scene_path(scene_path: String) -> bool:
	return scene_path.ends_with(".gltf") or scene_path.ends_with(".glb")


func _real_species_display_scale_factor(species_id: String) -> float:
	match species_id:
		"african_elephant":
			return 0.0024
		"zebra":
			return 0.0075
		"nile_crocodile":
			return 0.014
		"vulture":
			return 0.32
		"lion":
			return 1.36
		_:
			return 1.0


func _real_species_target_height(species_id: String, category: String) -> float:
	match species_id:
		"lion":
			return 1.3
		"zebra":
			return 1.7
		"nile_crocodile":
			return 0.9
		"vulture", "eagle":
			return 0.9
	match category:
		"掠食者":
			return 1.2
		"飞行动物":
			return 0.8
		"水域动物":
			return 0.9
		_:
			return 1.6


func _bounds_accumulate_mesh(node: Node3D, parent_transform: Transform3D, state: Dictionary) -> void:
	var local_transform := parent_transform * node.transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var aabb := mesh_instance.mesh.get_aabb()
			var corners := [
				aabb.position,
				aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
				aabb.position + Vector3(0.0, aabb.size.y, 0.0),
				aabb.position + Vector3(0.0, 0.0, aabb.size.z),
				aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
				aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
				aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
				aabb.position + aabb.size,
			]
			for corner in corners:
				var world_corner: Vector3 = local_transform * corner
				if not bool(state.get("has_bounds", false)):
					state["min"] = world_corner
					state["max"] = world_corner
					state["has_bounds"] = true
				else:
					var min_corner: Vector3 = state.get("min", world_corner)
					var max_corner: Vector3 = state.get("max", world_corner)
					state["min"] = Vector3(minf(min_corner.x, world_corner.x), minf(min_corner.y, world_corner.y), minf(min_corner.z, world_corner.z))
					state["max"] = Vector3(maxf(max_corner.x, world_corner.x), maxf(max_corner.y, world_corner.y), maxf(max_corner.z, world_corner.z))
	for child in node.get_children():
		var child_node := child as Node3D
		if child_node != null:
			_bounds_accumulate_mesh(child_node, local_transform, state)


func _fit_imported_visual_display_scale(visual: Node3D, species_id: String, category: String, fallback_scale: float) -> float:
	if visual == null:
		return fallback_scale
	var bounds_state := {
		"has_bounds": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_bounds_accumulate_mesh(visual, Transform3D.IDENTITY, bounds_state)
	if not bool(bounds_state.get("has_bounds", false)):
		return fallback_scale
	var min_corner: Vector3 = bounds_state.get("min", Vector3.ZERO)
	var max_corner: Vector3 = bounds_state.get("max", Vector3.ZERO)
	var size := max_corner - min_corner
	var height := maxf(size.y, 0.001)
	var target_height := _real_species_target_height(species_id, category)
	return clampf(target_height / height, 0.001, 8.0)


func _try_make_species_asset_member(species_id: String, category: String, primary: bool) -> Node3D:
	var scene_path := _species_asset_scene_path(species_id)
	var instance := AssetBindings.instantiate_scene(scene_path)
	if instance == null:
		return null
	var root := Node3D.new()
	root.name = "%sAssetMember" % species_id
	var visual: Node3D
	if instance is Node3D:
		visual = instance as Node3D
	else:
		visual = Node3D.new()
		visual.add_child(instance)
	var base_scale := 1.08 if primary else 0.94
	match category:
		"掠食者":
			base_scale *= 1.0
		"飞行动物":
			base_scale *= 0.92
		"水域动物":
			base_scale *= 0.98
		_:
			base_scale *= 1.0
	if _is_imported_visual_scene_path(scene_path):
		base_scale *= _real_species_display_scale_factor(species_id)
	root.scale = Vector3.ONE * base_scale
	if _is_imported_visual_scene_path(scene_path):
		var display_rig := Node3D.new()
		display_rig.name = "DisplayRig"
		root.add_child(display_rig)
		display_rig.add_child(visual)
		display_rig.scale = Vector3.ONE * _fit_imported_visual_display_scale(visual, species_id, category, 1.0)
		visual.name = "AssetVisual"
		root.set_meta("focus_rigs", {"body": display_rig, "head": null})
		root.set_meta("asset_display_only", true)
		return root
	root.add_child(visual)
	if _bind_asset_member_runtime_rigs(root, visual):
		_apply_asset_member_visibility_profile(root, species_id, category)
		root.set_meta("asset_runtime_bound", true)
	else:
		visual.name = "AssetVisual"
	return root


func _bind_asset_member_runtime_rigs(member_root: Node3D, visual_root: Node3D) -> bool:
	if visual_root == null:
		return false
	var grounded_body := visual_root.get_node_or_null("GroundAnchor/BodyRig") as Node3D
	var grounded_head := visual_root.get_node_or_null("GroundAnchor/HeadRig") as Node3D
	if grounded_body != null:
		var grounded_rigs := {"body": grounded_body, "head": grounded_head if grounded_head != null else grounded_body}
		member_root.set_meta("focus_rigs", grounded_rigs)
		member_root.set_meta("asset_actor_scene", true)
		return true
	var existing_body := visual_root.find_child("BodyRig", true, false) as Node3D
	var existing_head := visual_root.find_child("HeadRig", true, false) as Node3D
	if existing_body != null:
		if existing_body.get_parent() != member_root:
			var body_local := existing_body.transform
			existing_body.get_parent().remove_child(existing_body)
			member_root.add_child(existing_body)
			existing_body.transform = body_local
		if existing_head != null and existing_head.get_parent() != member_root:
			var head_local := existing_head.transform
			existing_head.get_parent().remove_child(existing_head)
			member_root.add_child(existing_head)
			existing_head.transform = head_local
		var rigs := {"body": existing_body, "head": existing_head if existing_head != null else existing_body}
		member_root.set_meta("focus_rigs", rigs)
		return true
	var bindable_children: Array[Node3D] = []
	for child in visual_root.get_children():
		var child_node := child as Node3D
		if child_node != null:
			bindable_children.append(child_node)
	if bindable_children.is_empty():
		return false
	var body_rig := Node3D.new()
	body_rig.name = "BodyRig"
	member_root.add_child(body_rig)
	var head_rig := Node3D.new()
	head_rig.name = "HeadRig"
	member_root.add_child(head_rig)
	for part in bindable_children:
		var local_transform := visual_root.transform * part.transform
		visual_root.remove_child(part)
		if _is_asset_leg_candidate(part.name):
			body_rig.add_child(part)
		elif _is_asset_head_part_name(part.name):
			head_rig.add_child(part)
		else:
			body_rig.add_child(part)
		part.transform = local_transform
	if visual_root.get_child_count() == 0:
		member_root.remove_child(visual_root)
		visual_root.queue_free()
	var rigs := {"body": body_rig, "head": head_rig}
	member_root.set_meta("focus_rigs", rigs)
	return true


func _is_asset_leg_candidate(node_name: String) -> bool:
	return node_name.begins_with("Leg_")


func _is_asset_head_part_name(node_name: String) -> bool:
	if node_name in [
		"Head",
		"Muzzle",
		"Beak",
		"NoseBridge",
		"SnoutBridge",
		"SnoutRidge",
		"ForeheadBridge",
		"Trunk",
		"TrunkTip",
		"TrunkRidge",
		"Neck",
		"NeckRuff",
		"Mane",
		"TailFan"
	]:
		return true
	for prefix in ["Eye", "Ear", "Horn", "HornTip", "Brow", "Cheek", "Face", "WingTip"]:
		if node_name.begins_with(prefix):
			return true
	return false


func _apply_asset_member_visibility_profile(member_root: Node3D, species_id: String, category: String) -> void:
	if member_root == null or member_root.has_meta("asset_visibility_tuned"):
		return
	if bool(member_root.get_meta("asset_actor_scene", false)):
		return
	var focus_rigs: Dictionary = member_root.get_meta("focus_rigs", {})
	var body_rig := focus_rigs.get("body", null) as Node3D
	var head_rig := focus_rigs.get("head", null) as Node3D
	if body_rig == null:
		body_rig = member_root.get_node_or_null("BodyRig") as Node3D
	if head_rig == null:
		head_rig = member_root.get_node_or_null("HeadRig") as Node3D
	var profile := _asset_member_visibility_profile(species_id, category)
	if body_rig != null:
		for child in body_rig.get_children():
			var body_part := child as Node3D
			if body_part == null:
				continue
			if body_part.name.begins_with("Leg_"):
				continue
			body_part.position.y += float(profile.get("body_lift", 0.0))
			body_part.position.z += float(profile.get("body_z", 0.0))
	if head_rig != null:
		head_rig.position.y += float(profile.get("head_lift", 0.0))
		head_rig.position.z += float(profile.get("head_z", 0.0))
	if body_rig != null:
		for child in body_rig.get_children():
			var leg_rig := child as Node3D
			if leg_rig == null or not leg_rig.name.begins_with("Leg_"):
				continue
			leg_rig.scale = Vector3(
				float(profile.get("leg_width", 1.0)),
				float(profile.get("leg_length", 1.0)),
				float(profile.get("leg_width", 1.0))
			)
			leg_rig.position.y += float(profile.get("leg_anchor_drop", 0.0))
	member_root.set_meta("asset_visibility_tuned", true)


func _member_body_rig(member: Node3D) -> Node3D:
	if member == null:
		return null
	var focus_rigs: Dictionary = _ensure_member_focus_rigs(member)
	var body_rig := focus_rigs.get("body", null) as Node3D
	if body_rig != null:
		return body_rig
	body_rig = member.get_node_or_null("BodyRig") as Node3D
	if body_rig != null:
		return body_rig
	return member.get_node_or_null("GroundAnchor/BodyRig") as Node3D


func _member_head_rig(member: Node3D) -> Node3D:
	if member == null:
		return null
	if bool(member.get_meta("asset_display_only", false)):
		return null
	var focus_rigs: Dictionary = _ensure_member_focus_rigs(member)
	var head_rig := focus_rigs.get("head", null) as Node3D
	if head_rig != null:
		return head_rig
	head_rig = member.get_node_or_null("HeadRig") as Node3D
	if head_rig != null:
		return head_rig
	return member.get_node_or_null("GroundAnchor/HeadRig") as Node3D


func _member_leg_rig(member: Node3D, leg_name: String) -> Node3D:
	var body_rig := _member_body_rig(member)
	if body_rig != null:
		var direct_leg := body_rig.get_node_or_null("Leg_%s" % leg_name) as Node3D
		if direct_leg != null:
			return direct_leg
	return member.get_node_or_null("Leg_%s" % leg_name) as Node3D


func _asset_member_visibility_profile(species_id: String, category: String) -> Dictionary:
	var profile := {
		"body_lift": 0.0,
		"body_z": 0.0,
		"head_lift": 0.0,
		"head_z": 0.0,
		"leg_length": 1.32,
		"leg_width": 1.08,
		"leg_anchor_drop": -0.2,
	}
	match category:
		"草食动物":
			profile["leg_length"] = 1.5
			profile["leg_width"] = 1.1
		"掠食者":
			profile["leg_length"] = 1.4
			profile["leg_width"] = 1.06
		"水域动物":
			profile["leg_length"] = 1.24
			profile["leg_width"] = 1.12
			profile["leg_anchor_drop"] = -0.08
		"飞行动物":
			profile["leg_length"] = 1.12
			profile["leg_width"] = 1.02
	match species_id:
		"african_elephant":
			profile["leg_length"] = 1.64
			profile["leg_width"] = 1.18
			profile["leg_anchor_drop"] = -0.24
		"giraffe":
			profile["head_lift"] = 0.02
			profile["head_z"] = 0.02
			profile["leg_length"] = 1.76
			profile["leg_width"] = 1.08
			profile["leg_anchor_drop"] = -0.26
		"zebra":
			profile["leg_length"] = 1.58
			profile["leg_width"] = 1.08
			profile["leg_anchor_drop"] = -0.22
		"antelope":
			profile["leg_length"] = 1.68
			profile["leg_width"] = 1.04
			profile["leg_anchor_drop"] = -0.24
		"lion":
			profile["body_z"] = -0.02
			profile["leg_length"] = 1.42
			profile["leg_anchor_drop"] = -0.22
		"canid":
			profile["body_z"] = -0.01
			profile["leg_length"] = 1.48
			profile["leg_width"] = 1.04
			profile["leg_anchor_drop"] = -0.22
		"nile_crocodile":
			profile["leg_length"] = 1.18
			profile["leg_width"] = 1.16
	return profile


func _build_aftermath_visuals() -> void:
	_clear_children(aftermath_root)
	if chase_aftermath.is_empty():
		return
	var target: Vector2 = chase_aftermath.get("target", Vector2.ZERO)
	if target == Vector2.ZERO:
		return
	var accent: Color = chase_aftermath.get("accent", Color8(248, 146, 102))
	var pulse := 0.5 + 0.5 * sin(elapsed_time() * 3.6)
	var duration := maxf(0.001, float(chase_aftermath.get("duration", 4.2)))
	var timer_ratio := clampf(float(chase_aftermath.get("timer", 0.0)) / duration, 0.0, 1.0)
	var target3 := Vector3(target.x, 0.0, target.y)
	var field := _box_mesh(Vector3(3.8 + pulse * 0.6, 0.04, 3.8 + pulse * 0.6), accent.darkened(0.12))
	field.position = target3 + Vector3(0.0, 0.02, 0.0)
	field.material_override = _material(accent.darkened(0.12), 0.18 + pulse * 0.08)
	aftermath_root.add_child(field)
	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 2.1 + pulse * 0.36
	ring_mesh.bottom_radius = 2.5 + pulse * 0.42
	ring_mesh.height = 0.14
	ring.mesh = ring_mesh
	ring.position = target3 + Vector3(0.0, 0.08, 0.0)
	ring.material_override = _material(accent, 0.42 + pulse * 0.18)
	aftermath_root.add_child(ring)
	var beacon := MeshInstance3D.new()
	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.top_radius = 0.12
	beacon_mesh.bottom_radius = 0.18
	beacon_mesh.height = 2.4 + pulse * 0.8
	beacon.mesh = beacon_mesh
	beacon.position = target3 + Vector3(0.0, 1.2 + pulse * 0.4, 0.0)
	beacon.material_override = _material(accent.lightened(0.08), 0.56 + pulse * 0.18)
	aftermath_root.add_child(beacon)
	var carrion := _hotspot_pos("carrion_field")
	var migration := _hotspot_pos("migration_corridor")
	_add_aftermath_link(target3, carrion, accent.darkened(0.08))
	_add_aftermath_link(target3, migration, current_theme.get("accent", Color8(236, 202, 118)))
	var migration_split := _box_mesh(Vector3(0.76, 0.05, 1.24), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.04))
	migration_split.position = target3 + Vector3(-1.08, 0.03, 1.22)
	migration_split.rotation_degrees = Vector3(0.0, -24.0, 0.0)
	aftermath_root.add_child(migration_split)
	var carrion_split := _box_mesh(Vector3(0.76, 0.05, 1.24), accent.darkened(0.04))
	carrion_split.position = target3 + Vector3(1.08, 0.03, 1.22)
	carrion_split.rotation_degrees = Vector3(0.0, 24.0, 0.0)
	aftermath_root.add_child(carrion_split)
	for index in range(3):
		var migration_pulse := _box_mesh(Vector3(0.18, 0.06, 0.26), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.1))
		migration_pulse.position = target3 + Vector3(-0.42 - index * 0.48, 0.07, 1.02 + index * 0.46)
		migration_pulse.rotation_degrees = Vector3(0.0, -24.0, 0.0)
		migration_pulse.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)).lightened(0.1), 0.42 + timer_ratio * 0.18)
		aftermath_root.add_child(migration_pulse)
		var carrion_pulse := _box_mesh(Vector3(0.18, 0.06, 0.26), accent.lightened(0.08))
		carrion_pulse.position = target3 + Vector3(0.42 + index * 0.48, 0.07, 1.02 + index * 0.46)
		carrion_pulse.rotation_degrees = Vector3(0.0, 24.0, 0.0)
		carrion_pulse.material_override = _material(accent.lightened(0.08), 0.42 + timer_ratio * 0.18)
		aftermath_root.add_child(carrion_pulse)
	for index in range(4):
		var migration_wave := _box_mesh(Vector3(0.36, 0.04, 0.14), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.06))
		migration_wave.position = target3 + Vector3(-0.92 - index * 0.62, 0.05, 1.46 + index * 0.68)
		migration_wave.rotation_degrees = Vector3(0.0, -26.0, 0.0)
		migration_wave.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)).lightened(0.06), 0.24 + (1.0 - timer_ratio) * 0.18)
		aftermath_root.add_child(migration_wave)
		var carrion_wave := _box_mesh(Vector3(0.36, 0.04, 0.14), accent.lightened(0.02))
		carrion_wave.position = target3 + Vector3(0.92 + index * 0.62, 0.05, 1.46 + index * 0.68)
		carrion_wave.rotation_degrees = Vector3(0.0, 26.0, 0.0)
		carrion_wave.material_override = _material(accent.lightened(0.02), 0.24 + (1.0 - timer_ratio) * 0.18)
		aftermath_root.add_child(carrion_wave)
	var spill_ring := MeshInstance3D.new()
	var spill_mesh := CylinderMesh.new()
	spill_mesh.top_radius = 3.1 + pulse * 0.24
	spill_mesh.bottom_radius = 3.5 + pulse * 0.3
	spill_mesh.height = 0.08
	spill_ring.mesh = spill_mesh
	spill_ring.position = target3 + Vector3(0.0, 0.04, 0.0)
	spill_ring.material_override = _material(accent.lightened(0.04), 0.14 + (1.0 - timer_ratio) * 0.14)
	aftermath_root.add_child(spill_ring)
	var migration_ring := MeshInstance3D.new()
	var migration_mesh := CylinderMesh.new()
	migration_mesh.top_radius = 1.4
	migration_mesh.bottom_radius = 1.8
	migration_mesh.height = 0.12
	migration_ring.mesh = migration_mesh
	migration_ring.position = migration + Vector3(0.0, 0.06, 0.0)
	migration_ring.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)), 0.24 + timer_ratio * 0.18 + pulse * 0.08)
	aftermath_root.add_child(migration_ring)
	var migration_beacon := _box_mesh(Vector3(0.18, 1.26, 0.18), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.12))
	migration_beacon.position = migration + Vector3(0.0, 0.64, 0.0)
	aftermath_root.add_child(migration_beacon)
	var migration_gate := _box_mesh(Vector3(0.84, 0.12, 0.12), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.08))
	migration_gate.position = migration + Vector3(0.0, 1.08, 0.0)
	aftermath_root.add_child(migration_gate)
	for side in [-1.0, 1.0]:
		var migration_flag := _box_mesh(Vector3(0.08, 0.7, 0.08), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.18))
		migration_flag.position = migration + Vector3(side * 1.02, 0.36, 0.82)
		aftermath_root.add_child(migration_flag)
		var migration_tip := _box_mesh(Vector3(0.24, 0.08, 0.14), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
		migration_tip.position = migration_flag.position + Vector3(0.0, 0.42, 0.0)
		aftermath_root.add_child(migration_tip)
	var migration_pad := _box_mesh(Vector3(1.34, 0.04, 1.02), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.08))
	migration_pad.position = migration + Vector3(0.0, 0.02, 0.0)
	aftermath_root.add_child(migration_pad)
	var migration_lane := _box_mesh(Vector3(0.68, 0.03, 1.46), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.06))
	migration_lane.position = migration + Vector3(0.0, 0.03, 0.32)
	aftermath_root.add_child(migration_lane)
	for side in [-1.0, 1.0]:
		var migration_wall := _box_mesh(Vector3(0.12, 0.18, 0.86), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.16))
		migration_wall.position = migration + Vector3(side * 0.74, 0.09, 0.0)
		aftermath_root.add_child(migration_wall)
		var migration_arch := _box_mesh(Vector3(0.08, 0.72, 0.08), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.2))
		migration_arch.position = migration + Vector3(side * 0.48, 0.36, 0.42)
		aftermath_root.add_child(migration_arch)
	var migration_lintel := _box_mesh(Vector3(1.02, 0.1, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.14))
	migration_lintel.position = migration + Vector3(0.0, 0.78, 0.42)
	aftermath_root.add_child(migration_lintel)
	for step in range(3):
		var retreat_arrow := _box_mesh(Vector3(0.18, 0.06, 0.26), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.16))
		retreat_arrow.position = migration + Vector3(0.0, 0.07, 0.66 + step * 0.34)
		retreat_arrow.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		aftermath_root.add_child(retreat_arrow)
	for side in [-1.0, 1.0]:
		var retreat_rail := _box_mesh(Vector3(0.1, 0.12, 1.16), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.14))
		retreat_rail.position = migration + Vector3(side * 0.42, 0.08, 0.54)
		aftermath_root.add_child(retreat_rail)
		var retreat_light := _box_mesh(Vector3(0.08, 0.08, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
		retreat_light.position = migration + Vector3(side * 0.36, 0.11, 0.92)
		aftermath_root.add_child(retreat_light)
	var retreat_terminal := _box_mesh(Vector3(0.92, 0.04, 0.44), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.1))
	retreat_terminal.position = migration + Vector3(0.0, 0.03, 1.14)
	aftermath_root.add_child(retreat_terminal)
	var retreat_terminal_lane := _box_mesh(Vector3(0.44, 0.03, 0.92), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
	retreat_terminal_lane.position = migration + Vector3(0.0, 0.04, 1.34)
	aftermath_root.add_child(retreat_terminal_lane)
	for step in range(2):
		var retreat_chevron := _box_mesh(Vector3(0.16, 0.06, 0.22), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.22))
		retreat_chevron.position = migration + Vector3(0.0, 0.07, 0.86 + step * 0.26)
		retreat_chevron.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		aftermath_root.add_child(retreat_chevron)
	var retreat_terminal_bar := _box_mesh(Vector3(0.74, 0.08, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.2))
	retreat_terminal_bar.position = migration + Vector3(0.0, 0.24, 1.34)
	aftermath_root.add_child(retreat_terminal_bar)
	for side in [-1.0, 1.0]:
		var retreat_edge_light := _box_mesh(Vector3(0.08, 0.08, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.22))
		retreat_edge_light.position = migration + Vector3(side * 0.22, 0.1, 1.34)
		aftermath_root.add_child(retreat_edge_light)
	var migration_gate_post_left := _box_mesh(Vector3(0.08, 0.64, 0.08), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.22))
	migration_gate_post_left.position = migration + Vector3(-0.28, 0.32, 1.08)
	aftermath_root.add_child(migration_gate_post_left)
	var migration_gate_post_right := _box_mesh(Vector3(0.08, 0.64, 0.08), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.22))
	migration_gate_post_right.position = migration + Vector3(0.28, 0.32, 1.08)
	aftermath_root.add_child(migration_gate_post_right)
	var migration_gate_bar := _box_mesh(Vector3(0.7, 0.08, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.16))
	migration_gate_bar.position = migration + Vector3(0.0, 0.68, 1.08)
	aftermath_root.add_child(migration_gate_bar)
	for side in [-1.0, 1.0]:
		var migration_porche_post := _box_mesh(Vector3(0.08, 0.52, 0.08), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.2))
		migration_porche_post.position = migration + Vector3(side * 0.54, 0.26, 0.42)
		aftermath_root.add_child(migration_porche_post)
		var retreat_terminal_wall := _box_mesh(Vector3(0.1, 0.16, 0.62), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.18))
		retreat_terminal_wall.position = migration + Vector3(side * 0.34, 0.08, 1.38)
		aftermath_root.add_child(retreat_terminal_wall)
	var migration_terminal_cap := _box_mesh(Vector3(0.68, 0.06, 0.12), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.22))
	migration_terminal_cap.position = migration + Vector3(0.0, 0.12, 1.72)
	aftermath_root.add_child(migration_terminal_cap)
	var migration_terminal_pad := _box_mesh(Vector3(0.86, 0.03, 0.34), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.08))
	migration_terminal_pad.position = migration + Vector3(0.0, 0.03, 1.56)
	aftermath_root.add_child(migration_terminal_pad)
	for step in range(2):
		var terminal_arrow := _box_mesh(Vector3(0.16, 0.06, 0.22), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.24))
		terminal_arrow.position = migration + Vector3(0.0, 0.07, 1.46 + step * 0.22)
		terminal_arrow.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		aftermath_root.add_child(terminal_arrow)
	for side in [-1.0, 1.0]:
		var terminal_gate_post := _box_mesh(Vector3(0.08, 0.46, 0.08), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.2))
		terminal_gate_post.position = migration + Vector3(side * 0.24, 0.24, 1.68)
		aftermath_root.add_child(terminal_gate_post)
	var carrion_ring := MeshInstance3D.new()
	var carrion_mesh := CylinderMesh.new()
	carrion_mesh.top_radius = 1.6
	carrion_mesh.bottom_radius = 2.0
	carrion_mesh.height = 0.12
	carrion_ring.mesh = carrion_mesh
	carrion_ring.position = carrion + Vector3(0.0, 0.06, 0.0)
	carrion_ring.material_override = _material(accent.darkened(0.12), 0.28 + timer_ratio * 0.2 + pulse * 0.08)
	aftermath_root.add_child(carrion_ring)
	var carrion_beacon := _box_mesh(Vector3(0.18, 1.34, 0.18), accent.darkened(0.18))
	carrion_beacon.position = carrion + Vector3(0.0, 0.68, 0.0)
	aftermath_root.add_child(carrion_beacon)
	var carrion_gate := _box_mesh(Vector3(0.76, 0.12, 0.12), accent.lightened(0.12))
	carrion_gate.position = carrion + Vector3(0.0, 1.16, 0.0)
	aftermath_root.add_child(carrion_gate)
	for side in [-1.0, 1.0]:
		var carrion_spike := _box_mesh(Vector3(0.08, 0.74, 0.08), accent.darkened(0.24))
		carrion_spike.position = carrion + Vector3(side * 0.92, 0.38, -0.78)
		aftermath_root.add_child(carrion_spike)
		var carrion_tip := _box_mesh(Vector3(0.22, 0.08, 0.18), accent.lightened(0.08))
		carrion_tip.position = carrion_spike.position + Vector3(0.0, 0.44, 0.0)
		aftermath_root.add_child(carrion_tip)
	var carrion_pad := _box_mesh(Vector3(1.22, 0.04, 0.94), accent.darkened(0.14))
	carrion_pad.position = carrion + Vector3(0.0, 0.02, 0.0)
	aftermath_root.add_child(carrion_pad)
	var carrion_bowl := _box_mesh(Vector3(1.42, 0.03, 1.18), accent.darkened(0.2))
	carrion_bowl.position = carrion + Vector3(0.0, 0.015, 0.0)
	aftermath_root.add_child(carrion_bowl)
	var carrion_center := _box_mesh(Vector3(0.38, 0.05, 0.38), accent.lightened(0.06))
	carrion_center.position = carrion + Vector3(0.0, 0.04, 0.0)
	aftermath_root.add_child(carrion_center)
	var carrion_outer := MeshInstance3D.new()
	var carrion_outer_mesh := CylinderMesh.new()
	carrion_outer_mesh.top_radius = 1.62
	carrion_outer_mesh.bottom_radius = 1.82
	carrion_outer_mesh.height = 0.04
	carrion_outer.mesh = carrion_outer_mesh
	carrion_outer.position = carrion + Vector3(0.0, 0.03, 0.0)
	carrion_outer.material_override = _material(accent.darkened(0.08), 0.22)
	aftermath_root.add_child(carrion_outer)
	var carrion_outer_2 := MeshInstance3D.new()
	var carrion_outer_mesh_2 := CylinderMesh.new()
	carrion_outer_mesh_2.top_radius = 2.02
	carrion_outer_mesh_2.bottom_radius = 2.22
	carrion_outer_mesh_2.height = 0.03
	carrion_outer_2.mesh = carrion_outer_mesh_2
	carrion_outer_2.position = carrion + Vector3(0.0, 0.025, 0.0)
	carrion_outer_2.material_override = _material(accent.darkened(0.12), 0.14)
	aftermath_root.add_child(carrion_outer_2)
	var carrion_outer_3 := MeshInstance3D.new()
	var carrion_outer_mesh_3 := CylinderMesh.new()
	carrion_outer_mesh_3.top_radius = 2.46
	carrion_outer_mesh_3.bottom_radius = 2.64
	carrion_outer_mesh_3.height = 0.03
	carrion_outer_3.mesh = carrion_outer_mesh_3
	carrion_outer_3.position = carrion + Vector3(0.0, 0.022, 0.0)
	carrion_outer_3.material_override = _material(accent.darkened(0.18), 0.1)
	aftermath_root.add_child(carrion_outer_3)
	for side in [-1.0, 1.0]:
		var carrion_wall := _box_mesh(Vector3(0.12, 0.18, 0.78), accent.darkened(0.2))
		carrion_wall.position = carrion + Vector3(side * 0.68, 0.09, 0.0)
		aftermath_root.add_child(carrion_wall)
		var carrion_stake := _box_mesh(Vector3(0.08, 0.64, 0.08), accent.darkened(0.26))
		carrion_stake.position = carrion + Vector3(side * 0.42, 0.32, -0.44)
		aftermath_root.add_child(carrion_stake)
		var carrion_bone := _box_mesh(Vector3(0.24, 0.06, 0.12), accent.lightened(0.06))
		carrion_bone.position = carrion_stake.position + Vector3(0.0, 0.18, 0.0)
		aftermath_root.add_child(carrion_bone)
	for orbit_index in range(2):
		var orbit_ring := MeshInstance3D.new()
		var orbit_mesh := CylinderMesh.new()
		orbit_mesh.top_radius = 0.82 + orbit_index * 0.34
		orbit_mesh.bottom_radius = 0.98 + orbit_index * 0.34
		orbit_mesh.height = 0.05
		orbit_ring.mesh = orbit_mesh
		orbit_ring.position = carrion + Vector3(0.0, 0.05 + orbit_index * 0.02, 0.0)
		orbit_ring.material_override = _material(accent.lightened(0.04), 0.18 + orbit_index * 0.08)
		aftermath_root.add_child(orbit_ring)
	for orbit_post_index in range(3):
		var orbit_post := _box_mesh(Vector3(0.08, 0.46, 0.08), accent.darkened(0.24))
		orbit_post.position = carrion + Vector3(cos(float(orbit_post_index) * 2.09) * 0.98, 0.24, sin(float(orbit_post_index) * 2.09) * 0.98)
		aftermath_root.add_child(orbit_post)
	for orbit_marker_index in range(4):
		var orbit_marker := _box_mesh(Vector3(0.18, 0.06, 0.12), accent.lightened(0.1))
		orbit_marker.position = carrion + Vector3(cos(float(orbit_marker_index) * 1.57) * 1.18, 0.08, sin(float(orbit_marker_index) * 1.57) * 1.18)
		orbit_marker.rotation_degrees = Vector3(0.0, float(orbit_marker_index) * 90.0, 0.0)
		aftermath_root.add_child(orbit_marker)
	for orbit_wall_index in range(4):
		var orbit_wall := _box_mesh(Vector3(0.1, 0.24, 0.42), accent.darkened(0.22))
		orbit_wall.position = carrion + Vector3(cos(float(orbit_wall_index) * 1.57 + 0.78) * 1.42, 0.12, sin(float(orbit_wall_index) * 1.57 + 0.78) * 1.42)
		orbit_wall.rotation_degrees = Vector3(0.0, float(orbit_wall_index) * 90.0 + 45.0, 0.0)
		aftermath_root.add_child(orbit_wall)
	for orbit_light_index in range(4):
		var orbit_light := _box_mesh(Vector3(0.1, 0.1, 0.1), accent.lightened(0.16))
		orbit_light.position = carrion + Vector3(cos(float(orbit_light_index) * 1.57 + 0.35) * 1.52, 0.1, sin(float(orbit_light_index) * 1.57 + 0.35) * 1.52)
		aftermath_root.add_child(orbit_light)
	for orbit_marker_index_2 in range(6):
		var angle := TAU * float(orbit_marker_index_2) / 6.0
		var orbit_outer_marker := _box_mesh(Vector3(0.16, 0.08, 0.16), accent.lightened(0.18))
		orbit_outer_marker.position = carrion + Vector3(cos(angle) * 2.28, 0.09, sin(angle) * 2.28)
		aftermath_root.add_child(orbit_outer_marker)
	for orbit_wall_index_2 in range(6):
		var angle2 := TAU * float(orbit_wall_index_2) / 6.0
		var orbit_outer_stub := _box_mesh(Vector3(0.12, 0.18, 0.34), accent.darkened(0.24))
		orbit_outer_stub.position = carrion + Vector3(cos(angle2) * 2.38, 0.1, sin(angle2) * 2.38)
		orbit_outer_stub.rotation_degrees = Vector3(0.0, rad_to_deg(angle2) + 90.0, 0.0)
		aftermath_root.add_child(orbit_outer_stub)
	var carrion_outer_pad := _box_mesh(Vector3(1.02, 0.03, 1.02), accent.darkened(0.18))
	carrion_outer_pad.position = carrion + Vector3(0.0, 0.02, 0.0)
	aftermath_root.add_child(carrion_outer_pad)
	var carrion_outer_ring_pad := _box_mesh(Vector3(1.62, 0.02, 1.62), accent.darkened(0.22))
	carrion_outer_ring_pad.position = carrion + Vector3(0.0, 0.015, 0.0)
	aftermath_root.add_child(carrion_outer_ring_pad)
	for orbit_light_index_2 in range(6):
		var angle3 := TAU * float(orbit_light_index_2) / 6.0 + 0.24
		var orbit_outer_light := _box_mesh(Vector3(0.1, 0.1, 0.1), accent.lightened(0.18))
		orbit_outer_light.position = carrion + Vector3(cos(angle3) * 2.54, 0.1, sin(angle3) * 2.54)
		aftermath_root.add_child(orbit_outer_light)
	for orbit_arch_index in range(4):
		var angle4 := TAU * float(orbit_arch_index) / 4.0 + 0.78
		var orbit_arch := _box_mesh(Vector3(0.08, 0.34, 0.42), accent.darkened(0.26))
		orbit_arch.position = carrion + Vector3(cos(angle4) * 2.66, 0.18, sin(angle4) * 2.66)
		orbit_arch.rotation_degrees = Vector3(0.0, rad_to_deg(angle4) + 90.0, 0.0)
		aftermath_root.add_child(orbit_arch)
	for side in [-1.0, 1.0]:
		var marker := _box_mesh(Vector3(0.14, 0.88, 0.14), accent.darkened(0.18))
		marker.position = target3 + Vector3(side * (2.4 + pulse * 0.22), 0.44, 0.0)
		aftermath_root.add_child(marker)
		var marker_cap := _box_mesh(Vector3(0.24, 0.08, 0.24), accent.lightened(0.06))
		marker_cap.position = marker.position + Vector3(0.0, 0.5, 0.0)
		aftermath_root.add_child(marker_cap)
	for corner in [Vector3(1.8, 0.0, 1.4), Vector3(-1.8, 0.0, 1.4), Vector3(1.8, 0.0, -1.4), Vector3(-1.8, 0.0, -1.4)]:
		var spike := _box_mesh(Vector3(0.1, 0.62, 0.1), accent.darkened(0.24))
		spike.position = target3 + corner + Vector3(0.0, 0.32, 0.0)
		aftermath_root.add_child(spike)
		var flare := _box_mesh(Vector3(0.18, 0.08, 0.18), accent.lightened(0.1))
		flare.position = spike.position + Vector3(0.0, 0.36, 0.0)
		aftermath_root.add_child(flare)
	for hub in [migration, carrion]:
		for side in [-1.0, 1.0]:
			var fin := _box_mesh(Vector3(0.12, 0.52, 0.12), accent.darkened(0.22))
			fin.position = hub + Vector3(side * 1.34, 0.26, 0.0)
			aftermath_root.add_child(fin)
	var split_plate := _box_mesh(Vector3(0.96, 0.08, 0.3), accent.lightened(0.08))
	split_plate.position = target3 + Vector3(0.0, 0.06, 2.1)
	aftermath_root.add_child(split_plate)
	var split_post := _box_mesh(Vector3(0.1, 0.52, 0.1), accent.darkened(0.2))
	split_post.position = target3 + Vector3(0.0, 0.26, 2.1)
	aftermath_root.add_child(split_post)


func _add_aftermath_link(a: Vector3, b: Vector3, color: Color) -> void:
	var diff := b - a
	var length := diff.length()
	if length <= 0.1:
		return
	var root := Node3D.new()
	root.position = (a + b) * 0.5 + Vector3(0.0, 0.04, 0.0)
	root.rotation.y = atan2(diff.x, diff.z)
	aftermath_root.add_child(root)
	var lane := MeshInstance3D.new()
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(0.18, 0.04, length)
	lane.mesh = lane_mesh
	lane.material_override = _material(color, 0.62)
	root.add_child(lane)
	for index in range(max(2, int(length / 3.2))):
		var pulse := _box_mesh(Vector3(0.22, 0.05, 0.34), color.lightened(0.08))
		pulse.position = Vector3(0.0, 0.04, -length * 0.5 + 1.0 + index * 2.8)
		root.add_child(pulse)
		if index < max(2, int(length / 3.2)) - 1:
			for side in [-1.0, 1.0]:
				var post := _box_mesh(Vector3(0.08, 0.46, 0.08), color.darkened(0.12))
				post.position = Vector3(side * 0.32, 0.22, pulse.position.z + 0.14)
				root.add_child(post)
	var terminal := _box_mesh(Vector3(0.42, 0.08, 0.42), color.lightened(0.14))
	terminal.position = Vector3(0.0, 0.05, length * 0.5 - 0.36)
	root.add_child(terminal)


func _build_terrain_layers() -> void:
	match current_biome:
		"wetland":
			_add_terrain_patch(_scaled_pos(Vector3(-18.0, -0.12, 4.0)), _scaled_size(Vector3(20.0, 0.24, 16.0)), current_theme.get("water", Color8(74, 136, 154)), 0.82)
			_add_terrain_patch(_scaled_pos(Vector3(8.0, 0.08, -10.0)), _scaled_size(Vector3(18.0, 0.18, 14.0)), current_theme.get("foliage", Color8(106, 144, 92)), 0.74)
			_add_terrain_patch(_scaled_pos(Vector3(-4.0, 0.03, -3.0)), _scaled_size(Vector3(32.0, 0.1, 8.0)), current_theme.get("route", Color8(214, 226, 188)), 0.42)
			_add_terrain_patch(_scaled_pos(Vector3(18.0, -0.05, 10.0)), _scaled_size(Vector3(14.0, 0.12, 12.0)), Color8(110, 126, 98), 0.58)
			_add_tilted_patch(_scaled_pos(Vector3(-10.0, 0.18, 10.0)), _scaled_size(Vector3(10.0, 0.18, 4.0)), Color8(186, 194, 160), 0.62, -8.0, 0.0)
			_add_tilted_patch(_scaled_pos(Vector3(12.0, 0.14, -6.0)), _scaled_size(Vector3(8.0, 0.16, 4.0)), Color8(158, 168, 132), 0.56, 0.0, 6.0)
		"forest":
			_add_terrain_patch(_scaled_pos(Vector3(-14.0, 0.22, -10.0)), _scaled_size(Vector3(22.0, 0.34, 18.0)), Color8(72, 94, 68), 0.86)
			_add_terrain_patch(_scaled_pos(Vector3(16.0, 0.16, 8.0)), _scaled_size(Vector3(18.0, 0.28, 14.0)), current_theme.get("foliage", Color8(64, 96, 64)), 0.78)
			_add_terrain_patch(_scaled_pos(Vector3(2.0, 0.04, 2.0)), _scaled_size(Vector3(28.0, 0.1, 7.0)), current_theme.get("route", Color8(184, 172, 134)), 0.44)
			_add_terrain_patch(_scaled_pos(Vector3(-24.0, 0.12, 8.0)), _scaled_size(Vector3(10.0, 0.18, 10.0)), Color8(88, 108, 80), 0.66)
			_add_tilted_patch(_scaled_pos(Vector3(-4.0, 0.24, 14.0)), _scaled_size(Vector3(12.0, 0.18, 4.0)), Color8(116, 126, 92), 0.64, 10.0, 0.0)
			_add_tilted_patch(_scaled_pos(Vector3(18.0, 0.28, -8.0)), _scaled_size(Vector3(8.0, 0.18, 4.0)), Color8(124, 116, 94), 0.58, 0.0, -8.0)
		"coast":
			_add_terrain_patch(_scaled_pos(Vector3(-20.0, -0.16, 6.0)), _scaled_size(Vector3(26.0, 0.22, 16.0)), current_theme.get("water", Color8(76, 156, 196)), 0.84)
			_add_terrain_patch(_scaled_pos(Vector3(18.0, 0.14, -14.0)), _scaled_size(Vector3(20.0, 0.26, 12.0)), Color8(164, 150, 122), 0.74)
			_add_terrain_patch(_scaled_pos(Vector3(-6.0, -0.08, 12.0)), _scaled_size(Vector3(30.0, 0.12, 7.0)), Color8(224, 214, 180), 0.48)
			_add_terrain_patch(_scaled_pos(Vector3(8.0, 0.05, -2.0)), _scaled_size(Vector3(26.0, 0.1, 6.0)), current_theme.get("route", Color8(244, 232, 192)), 0.38)
			_add_tilted_patch(_scaled_pos(Vector3(22.0, 0.24, -12.0)), _scaled_size(Vector3(12.0, 0.2, 4.0)), Color8(182, 170, 142), 0.6, 12.0, 0.0)
			_add_tilted_patch(_scaled_pos(Vector3(-16.0, 0.08, 14.0)), _scaled_size(Vector3(10.0, 0.16, 4.0)), Color8(238, 226, 184), 0.54, 0.0, 8.0)
		_:
			_add_terrain_patch(_scaled_pos(Vector3(-8.0, 0.12, 4.0)), _scaled_size(Vector3(30.0, 0.18, 12.0)), Color8(210, 188, 122), 0.58)
			_add_terrain_patch(_scaled_pos(Vector3(18.0, 0.18, -16.0)), _scaled_size(Vector3(18.0, 0.28, 10.0)), Color8(144, 122, 84), 0.72)
			_add_terrain_patch(_scaled_pos(Vector3(-10.0, 0.04, 8.0)), _scaled_size(Vector3(34.0, 0.08, 8.0)), current_theme.get("route", Color8(240, 223, 176)), 0.46)
			_add_terrain_patch(_scaled_pos(Vector3(12.0, 0.08, -2.0)), _scaled_size(Vector3(20.0, 0.12, 6.0)), Color8(184, 164, 96), 0.34)
			_add_tilted_patch(_scaled_pos(Vector3(18.0, 0.3, -14.0)), _scaled_size(Vector3(10.0, 0.18, 4.0)), Color8(162, 138, 92), 0.64, 10.0, 0.0)
			_add_tilted_patch(_scaled_pos(Vector3(-22.0, 0.12, -6.0)), _scaled_size(Vector3(8.0, 0.16, 4.0)), Color8(124, 150, 88), 0.48, 0.0, -7.0)
	_add_ground_detail_clusters()
	_add_ground_relief_clusters()
	_add_ground_surface_streaks()


func _build_ground_surface() -> void:
	var bounds := current_world_bounds
	var min_x := bounds.position.x
	var max_x := bounds.end.x
	var min_z := bounds.position.y
	var max_z := bounds.end.y
	var x_segments := 84
	var z_segments := 64
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z_index in range(z_segments):
		var tz0 := float(z_index) / float(z_segments)
		var tz1 := float(z_index + 1) / float(z_segments)
		for x_index in range(x_segments):
			var tx0 := float(x_index) / float(x_segments)
			var tx1 := float(x_index + 1) / float(x_segments)
			var p00 := _ground_surface_point(lerpf(min_x, max_x, tx0), lerpf(min_z, max_z, tz0))
			var p10 := _ground_surface_point(lerpf(min_x, max_x, tx1), lerpf(min_z, max_z, tz0))
			var p11 := _ground_surface_point(lerpf(min_x, max_x, tx1), lerpf(min_z, max_z, tz1))
			var p01 := _ground_surface_point(lerpf(min_x, max_x, tx0), lerpf(min_z, max_z, tz1))
			_add_ground_surface_triangle(tool, p00, p10, p11)
			_add_ground_surface_triangle(tool, p00, p11, p01)
	tool.generate_normals()
	var mesh := tool.commit()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.roughness = 1.0
	material.metallic = 0.0
	material.clearcoat = 0.0
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	environment_root.add_child(mesh_instance)


func _ground_surface_point(x: float, z: float) -> Vector3:
	var y := _ground_surface_height(x, z)
	return Vector3(x, y, z)


func _terrain_height_at(x: float, z: float) -> float:
	return _ground_surface_height(x, z)


func _ground_contact_height_at(x: float, z: float) -> float:
	var biome_amp := 0.42
	var primary_freq := 0.055
	var macro_freq := 0.022
	match current_biome:
		"wetland":
			biome_amp = 0.48
			primary_freq = 0.038
			macro_freq = 0.018
		"forest":
			biome_amp = 0.92
			primary_freq = 0.044
			macro_freq = 0.02
		"coast":
			biome_amp = 0.6
			primary_freq = 0.046
			macro_freq = 0.016
		_:
			biome_amp = 0.78
			primary_freq = 0.048
			macro_freq = 0.021
	var macro_wave := sin(x * macro_freq + z * 0.013) * biome_amp * 0.76
	var macro_cross := cos(z * macro_freq * 0.88 - x * 0.01) * biome_amp * 0.52
	var undulation := sin(x * primary_freq + z * 0.018) * cos(z * primary_freq - x * 0.012) * biome_amp * 0.56
	var ridge_pull := 0.0
	for hotspot_id in ["waterhole", "migration_corridor", "predator_ridge", "carrion_field", "shade_grove"]:
		var hotspot := _hotspot_pos(hotspot_id)
		if hotspot == Vector3.ZERO:
			continue
		var delta := Vector2(x - hotspot.x, z - hotspot.z)
		var dist := delta.length()
		var weight := clampf(1.0 - dist / (24.0 * REGION_DISTANCE_SCALE), 0.0, 1.0)
		match hotspot_id:
			"waterhole":
				ridge_pull -= weight * 0.22
			"migration_corridor":
				ridge_pull += weight * 0.06
			"predator_ridge":
				ridge_pull += weight * 0.34
			"carrion_field":
				ridge_pull += weight * 0.12
			"shade_grove":
				ridge_pull += weight * 0.18
	return macro_wave + macro_cross + undulation + ridge_pull


func _animal_ground_offset(species_id: String, category: String) -> float:
	match category:
		"飞行动物":
			return 1.36
		"水域动物":
			return 0.08
	match species_id:
		"african_elephant", "giraffe", "hippopotamus":
			return 0.08
		"nile_crocodile":
			return 0.03
		"lion", "hyena", "wolf", "fox", "zebra", "antelope", "deer":
			return 0.11
		_:
			return 0.1


func _ground_surface_height(x: float, z: float) -> float:
	var biome_amp := 0.42
	var primary_freq := 0.055
	var secondary_freq := 0.11
	var macro_freq := 0.022
	match current_biome:
		"wetland":
			biome_amp = 0.48
			primary_freq = 0.038
			secondary_freq = 0.076
			macro_freq = 0.018
		"forest":
			biome_amp = 0.92
			primary_freq = 0.044
			secondary_freq = 0.094
			macro_freq = 0.02
		"coast":
			biome_amp = 0.6
			primary_freq = 0.046
			secondary_freq = 0.09
			macro_freq = 0.016
		_:
			biome_amp = 0.78
			primary_freq = 0.048
			secondary_freq = 0.098
			macro_freq = 0.021
	var macro_wave := sin(x * macro_freq + z * 0.013) * biome_amp * 0.76
	var macro_cross := cos(z * macro_freq * 0.88 - x * 0.01) * biome_amp * 0.52
	var undulation := sin(x * primary_freq + z * 0.018) * cos(z * primary_freq - x * 0.012) * biome_amp * 0.72
	var detail := sin(x * secondary_freq + 1.2) * 0.22 + cos(z * secondary_freq * 0.92 - 0.6) * 0.18
	var ridge_pull := 0.0
	var spawn := Vector3(current_layout.get("spawn", Vector3.ZERO))
	var route_pull := 0.0
	for hotspot_id in ["waterhole", "migration_corridor", "predator_ridge", "carrion_field", "shade_grove"]:
		var hotspot := _hotspot_pos(hotspot_id)
		if hotspot == Vector3.ZERO:
			continue
		var delta := Vector2(x - hotspot.x, z - hotspot.z)
		var dist := delta.length()
		var weight := clampf(1.0 - dist / (20.0 * REGION_DISTANCE_SCALE), 0.0, 1.0)
		match hotspot_id:
			"waterhole":
				ridge_pull -= weight * 0.54
			"migration_corridor":
				ridge_pull += weight * 0.14
			"predator_ridge":
				ridge_pull += weight * 0.74
			"carrion_field":
				ridge_pull += weight * 0.28
			"shade_grove":
				ridge_pull += weight * 0.34
	var route_axis := Vector2(x - spawn.x, z - spawn.z)
	var route_weight := clampf(1.0 - abs(route_axis.x) / (18.0 * REGION_DISTANCE_SCALE), 0.0, 1.0)
	route_pull -= route_weight * 0.12
	return macro_wave + macro_cross + undulation + detail + ridge_pull + route_pull


func _ground_surface_color(height: float) -> Color:
	var ground: Color = current_theme.get("ground", Color8(190, 168, 104))
	var route: Color = current_theme.get("route", ground.lightened(0.08))
	var foliage: Color = current_theme.get("foliage", ground.darkened(0.12))
	var t := clampf((height + 0.25) / 0.9, 0.0, 1.0)
	var low_color := ground.darkened(0.1).lerp(route, 0.26)
	var high_color := ground.lightened(0.08).lerp(foliage.darkened(0.14), 0.18)
	return low_color.lerp(high_color, t)


func _add_ground_surface_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.set_color(_ground_surface_color((a.y + b.y + c.y) / 3.0))
	tool.add_vertex(a)
	tool.set_color(_ground_surface_color((a.y + b.y + c.y) / 3.0))
	tool.add_vertex(b)
	tool.set_color(_ground_surface_color((a.y + b.y + c.y) / 3.0))
	tool.add_vertex(c)


func _add_terrain_patch(pos: Vector3, size: Vector3, color: Color, alpha: float) -> void:
	var patch := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	patch.mesh = mesh
	patch.scale = Vector3(size.x, maxf(0.08, size.y * 2.2), size.z)
	patch.position = pos + Vector3(0.0, size.y * 0.18, 0.0)
	patch.material_override = _material(color, alpha)
	environment_root.add_child(patch)


func _add_tilted_patch(pos: Vector3, size: Vector3, color: Color, alpha: float, tilt_x_deg: float, tilt_z_deg: float) -> void:
	var patch := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	patch.mesh = mesh
	patch.scale = Vector3(size.x, maxf(0.08, size.y * 2.0), size.z)
	patch.position = pos + Vector3(0.0, size.y * 0.16, 0.0)
	patch.rotation_degrees = Vector3(tilt_x_deg, 0.0, tilt_z_deg)
	patch.material_override = _material(color, alpha)
	environment_root.add_child(patch)


func _add_ground_detail_clusters() -> void:
	match current_biome:
		"wetland":
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(-24.0, 0.02, 10.0)), Color8(126, 140, 102), Color8(164, 156, 118), 14, 7.2, 1.0)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(4.0, 0.02, -2.0)), Color8(110, 124, 96), Color8(152, 144, 112), 12, 6.6, 0.96)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(18.0, 0.02, -10.0)), Color8(102, 118, 92), Color8(144, 136, 106), 10, 6.2, 0.9)
		"forest":
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(-18.0, 0.02, 16.0)), Color8(72, 92, 62), Color8(110, 104, 82), 16, 7.4, 1.02)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(2.0, 0.02, 10.0)), Color8(82, 96, 68), Color8(118, 112, 90), 14, 6.8, 0.98)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(20.0, 0.02, -4.0)), Color8(76, 88, 64), Color8(112, 106, 86), 12, 6.4, 0.94)
		"coast":
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(-22.0, 0.01, 14.0)), Color8(216, 206, 170), Color8(176, 166, 136), 14, 7.4, 1.0)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(4.0, 0.01, 2.0)), Color8(228, 218, 182), Color8(182, 170, 142), 12, 6.8, 0.96)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(22.0, 0.01, -10.0)), Color8(198, 186, 154), Color8(162, 150, 122), 10, 6.0, 0.9)
		_:
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(-20.0, 0.02, 12.0)), Color8(206, 184, 118), Color8(156, 138, 92), 14, 7.0, 1.0)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(6.0, 0.02, 0.0)), Color8(214, 192, 126), Color8(164, 146, 96), 12, 6.6, 0.98)
			_add_ground_detail_cluster(_layout_scaled_pos(Vector3(24.0, 0.02, -14.0)), Color8(178, 154, 104), Color8(138, 122, 84), 10, 6.2, 0.92)


func _add_ground_detail_cluster(center: Vector3, color_a: Color, color_b: Color, count: int, radius: float, scale: float) -> void:
	for index in range(count):
		var phase := float(index) * 1.37 + center.x * 0.11 + center.z * 0.07
		var ring := 0.34 + 0.66 * float(index) / maxf(1.0, float(count - 1))
		var offset := Vector3(cos(phase) * radius * ring, 0.0, sin(phase * 1.16) * radius * (0.52 + ring * 0.48))
		var variant := clampf(0.5 + 0.5 * sin(phase * 1.9), 0.0, 1.0)
		var patch := MeshInstance3D.new()
		var patch_mesh := SphereMesh.new()
		patch_mesh.radius = 0.5
		patch_mesh.height = 1.0
		patch.mesh = patch_mesh
		patch.scale = Vector3((0.72 + variant * 0.9) * scale, 0.08 + variant * 0.1, (0.54 + (1.0 - variant) * 0.82) * scale)
		patch.position = center + offset + Vector3(0.0, patch.scale.y * 0.28, 0.0)
		patch.rotation_degrees = Vector3(0.0, phase * 48.0, 0.0)
		patch.material_override = _material(color_a.lerp(color_b, variant), 0.42 + variant * 0.24)
		environment_root.add_child(patch)
		if index % 3 == 0:
			var pebble := MeshInstance3D.new()
			var pebble_mesh := SphereMesh.new()
			pebble_mesh.radius = (0.12 + variant * 0.08) * scale
			pebble_mesh.height = pebble_mesh.radius * 2.0
			pebble.mesh = pebble_mesh
			pebble.position = center + offset + Vector3(0.22 * cos(phase * 0.7), pebble_mesh.radius * 0.88, -0.18 * sin(phase))
			pebble.material_override = _material(color_b.darkened(0.08 + variant * 0.08), 0.92)
			environment_root.add_child(pebble)


func _add_ground_relief_clusters() -> void:
	match current_biome:
		"wetland":
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(-26.0, 0.0, 12.0)), Color8(116, 126, 98), Color8(146, 152, 118), 8, 8.6, 1.12, 0.32)
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(8.0, 0.0, -6.0)), Color8(110, 120, 92), Color8(136, 142, 108), 7, 7.4, 1.02, 0.28)
		"forest":
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(-18.0, 0.0, 18.0)), Color8(86, 94, 70), Color8(122, 116, 88), 9, 8.2, 1.08, 0.34)
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(18.0, 0.0, -6.0)), Color8(82, 90, 68), Color8(114, 106, 82), 8, 7.8, 1.0, 0.3)
		"coast":
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(-24.0, 0.0, 16.0)), Color8(210, 198, 164), Color8(170, 156, 130), 8, 8.4, 1.12, 0.3)
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(18.0, 0.0, -12.0)), Color8(194, 180, 148), Color8(156, 142, 118), 7, 7.6, 1.02, 0.28)
		_:
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(-22.0, 0.0, 14.0)), Color8(196, 174, 118), Color8(150, 128, 90), 8, 8.4, 1.1, 0.32)
			_add_ground_relief_cluster(_layout_scaled_pos(Vector3(20.0, 0.0, -12.0)), Color8(176, 152, 102), Color8(136, 118, 82), 7, 7.8, 1.0, 0.3)


func _add_ground_relief_cluster(center: Vector3, color_a: Color, color_b: Color, count: int, radius: float, scale: float, mound_height: float) -> void:
	for index in range(count):
		var phase := float(index) * 0.94 + center.x * 0.05 + center.z * 0.03
		var ring := 0.38 + 0.62 * float(index) / maxf(1.0, float(count - 1))
		var offset := Vector3(cos(phase) * radius * ring, 0.0, sin(phase * 1.13) * radius * (0.58 + ring * 0.42))
		var mound := MeshInstance3D.new()
		var mound_mesh := SphereMesh.new()
		var mound_radius := (0.88 + 0.38 * sin(phase * 1.7)) * scale
		mound_mesh.radius = mound_radius
		mound_mesh.height = mound_radius * 1.16
		mound.mesh = mound_mesh
		mound.position = center + offset + Vector3(0.0, mound_height * (0.28 + ring * 0.16), 0.0)
		mound.scale = Vector3(1.18 + ring * 0.44, mound_height, 0.92 + ring * 0.24)
		mound.rotation_degrees = Vector3(0.0, phase * 44.0, 0.0)
		mound.material_override = _material(color_a.lerp(color_b, clampf(0.5 + 0.5 * sin(phase * 1.3), 0.0, 1.0)), 0.36)
		environment_root.add_child(mound)
		if index % 2 == 0:
			var ridge := MeshInstance3D.new()
			var ridge_mesh := SphereMesh.new()
			ridge_mesh.radius = 0.5
			ridge_mesh.height = 1.0
			ridge.mesh = ridge_mesh
			ridge.scale = Vector3((1.2 + ring * 0.9) * scale, 0.14 + ring * 0.08, (0.42 + ring * 0.36) * scale)
			ridge.position = center + offset + Vector3(0.0, ridge.scale.y * 0.3 + mound_height * 0.08, 0.0)
			ridge.rotation_degrees = Vector3(0.0, phase * 58.0, 0.0)
			ridge.material_override = _material(color_b.darkened(0.04), 0.42)
			environment_root.add_child(ridge)


func _add_ground_surface_streaks() -> void:
	match current_biome:
		"wetland":
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(-18.0, 0.02, 10.0)), Vector3(14.0, 0.0, -4.0), Color8(168, 176, 142), 10.0, 1.4, 0.34)
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(2.0, 0.02, 0.0)), Vector3(16.0, 0.0, -6.0), Color8(138, 148, 114), 9.0, 1.2, 0.28)
		"forest":
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(-16.0, 0.02, 16.0)), Vector3(16.0, 0.0, -8.0), Color8(112, 110, 88), 11.0, 1.2, 0.32)
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(4.0, 0.02, 8.0)), Vector3(14.0, 0.0, -8.0), Color8(96, 98, 78), 9.6, 1.0, 0.28)
		"coast":
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(-18.0, 0.01, 14.0)), Vector3(18.0, 0.0, -6.0), Color8(214, 206, 170), 11.0, 1.6, 0.3)
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(6.0, 0.01, 2.0)), Vector3(16.0, 0.0, -10.0), Color8(194, 184, 150), 10.0, 1.2, 0.26)
		_:
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(-20.0, 0.02, 12.0)), Vector3(18.0, 0.0, -6.0), Color8(198, 178, 120), 10.6, 1.4, 0.32)
			_add_ground_surface_streak(_layout_scaled_pos(Vector3(8.0, 0.02, -2.0)), Vector3(16.0, 0.0, -8.0), Color8(176, 156, 102), 9.8, 1.1, 0.28)


func _add_ground_surface_streak(origin: Vector3, direction: Vector3, color: Color, length: float, width: float, alpha: float) -> void:
	var dir := Vector3(direction.x, 0.0, direction.z)
	if dir.length() <= 0.01:
		return
	dir = dir.normalized()
	var lateral := Vector3(-dir.z, 0.0, dir.x)
	for index in range(4):
		var streak := MeshInstance3D.new()
		var streak_mesh := SphereMesh.new()
		streak_mesh.radius = 0.5
		streak_mesh.height = 1.0
		streak.mesh = streak_mesh
		streak.scale = Vector3(length * (0.54 + 0.08 * index), 0.08 + 0.03 * index, width * (0.82 + 0.06 * index))
		streak.position = origin + dir * (float(index) * 3.4) + lateral * ((float(index) - 1.5) * 0.42)
		streak.rotation.y = atan2(dir.x, dir.z) + deg_to_rad((float(index) - 1.5) * 6.0)
		streak.material_override = _material(color.lightened(0.03 * float(index % 2)), alpha - 0.04 * float(index))
		environment_root.add_child(streak)


func _build_routes() -> void:
	var entry_routes: Array = []
	var trunk_routes: Array = []
	var branch_routes: Array = []
	var connectors: Array = []
	var stage_markers: Array = []
	match current_biome:
		"wetland":
			entry_routes = [
				[_route_scaled_pos(Vector3(-44.0, 0.05, 24.0)), _route_scaled_pos(Vector3(-34.0, 0.05, 20.0)), _route_scaled_pos(Vector3(-22.0, 0.05, 12.0)), _hotspot_pos("waterhole")],
			]
			trunk_routes = [
				[_hotspot_pos("waterhole"), _route_scaled_pos(Vector3(-20.0, 0.05, 11.0)), _route_scaled_pos(Vector3(-12.0, 0.05, 7.0)), _route_scaled_pos(Vector3(-2.0, 0.05, 4.0)), _route_scaled_pos(Vector3(6.0, 0.05, 0.0)), _hotspot_pos("migration_corridor")],
			]
			branch_routes = [
				[_route_scaled_pos(Vector3(-20.0, 0.05, 10.5)), _route_scaled_pos(Vector3(-22.0, 0.05, 0.0)), _route_scaled_pos(Vector3(-8.0, 0.05, -6.0)), _hotspot_pos("carrion_field")],
				[_route_scaled_pos(Vector3(-12.0, 0.05, 6.5)), _route_scaled_pos(Vector3(-18.0, 0.05, 16.0)), _hotspot_pos("shade_grove")],
				[_route_scaled_pos(Vector3(4.0, 0.05, 0.0)), _route_scaled_pos(Vector3(12.0, 0.05, -8.0)), _hotspot_pos("predator_ridge")],
			]
			connectors = [
				[_route_scaled_pos(Vector3(-34.0, 0.05, 20.0)), _route_scaled_pos(Vector3(-24.0, 0.05, 14.0))],
				[_route_scaled_pos(Vector3(-6.0, 0.05, -2.0)), _route_scaled_pos(Vector3(6.0, 0.05, -8.0))],
				[_route_scaled_pos(Vector3(-18.0, 0.05, 8.0)), _route_scaled_pos(Vector3(-14.0, 0.05, 14.0))],
			]
			stage_markers = [
				{"pos": _route_scaled_pos(Vector3(-31.0, 0.05, 18.0)), "kind": "entry"},
				{"pos": _route_scaled_pos(Vector3(-16.0, 0.05, 8.0)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(2.0, 0.05, 0.5)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(-16.0, 0.05, -2.0)), "kind": "branch"},
				{"pos": _route_scaled_pos(Vector3(10.0, 0.05, -6.0)), "kind": "branch"},
			]
		"forest":
			entry_routes = [
				[_route_scaled_pos(Vector3(-42.0, 0.05, 24.0)), _route_scaled_pos(Vector3(-30.0, 0.05, 22.0)), _route_scaled_pos(Vector3(-18.0, 0.05, 18.0)), _hotspot_pos("shade_grove")],
			]
			trunk_routes = [
				[_hotspot_pos("shade_grove"), _route_scaled_pos(Vector3(-18.0, 0.05, 17.0)), _route_scaled_pos(Vector3(-8.0, 0.05, 12.5)), _hotspot_pos("waterhole"), _route_scaled_pos(Vector3(6.0, 0.05, 8.0)), _route_scaled_pos(Vector3(14.0, 0.05, 1.5)), _hotspot_pos("migration_corridor")],
			]
			branch_routes = [
				[_route_scaled_pos(Vector3(14.0, 0.05, 1.5)), _route_scaled_pos(Vector3(24.0, 0.05, -4.0)), _hotspot_pos("predator_ridge")],
				[_hotspot_pos("waterhole"), _route_scaled_pos(Vector3(14.0, 0.05, 12.0)), _route_scaled_pos(Vector3(22.0, 0.05, 10.0)), _hotspot_pos("carrion_field")],
				[_route_scaled_pos(Vector3(-8.0, 0.05, 12.5)), _route_scaled_pos(Vector3(-16.0, 0.05, 2.0)), _hotspot_pos("waterhole")],
			]
			connectors = [
				[_route_scaled_pos(Vector3(-30.0, 0.05, 20.0)), _route_scaled_pos(Vector3(-18.0, 0.05, 18.0))],
				[_route_scaled_pos(Vector3(-2.0, 0.05, 10.0)), _route_scaled_pos(Vector3(8.0, 0.05, 6.0))],
				[_route_scaled_pos(Vector3(6.0, 0.05, 0.0)), _route_scaled_pos(Vector3(18.0, 0.05, -10.0))],
			]
			stage_markers = [
				{"pos": _route_scaled_pos(Vector3(-24.0, 0.05, 19.0)), "kind": "entry"},
				{"pos": _route_scaled_pos(Vector3(-10.0, 0.05, 13.0)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(8.0, 0.05, 7.0)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(20.0, 0.05, 10.0)), "kind": "branch"},
				{"pos": _route_scaled_pos(Vector3(24.0, 0.05, -4.0)), "kind": "branch"},
			]
		"coast":
			entry_routes = [
				[_route_scaled_pos(Vector3(-44.0, 0.05, 20.0)), _route_scaled_pos(Vector3(-32.0, 0.05, 18.0)), _route_scaled_pos(Vector3(-20.0, 0.05, 14.0)), _hotspot_pos("waterhole")],
			]
			trunk_routes = [
				[_hotspot_pos("waterhole"), _route_scaled_pos(Vector3(-12.0, 0.05, 10.5)), _route_scaled_pos(Vector3(-4.0, 0.05, 6.5)), _route_scaled_pos(Vector3(6.0, 0.05, 4.0)), _route_scaled_pos(Vector3(16.0, 0.05, 1.5)), _hotspot_pos("migration_corridor")],
			]
			branch_routes = [
				[_route_scaled_pos(Vector3(16.0, 0.05, 1.5)), _route_scaled_pos(Vector3(22.0, 0.05, -4.0)), _route_scaled_pos(Vector3(18.0, 0.05, -10.0)), _hotspot_pos("predator_ridge")],
				[_route_scaled_pos(Vector3(6.0, 0.05, 4.0)), _route_scaled_pos(Vector3(16.0, 0.05, 7.0)), _route_scaled_pos(Vector3(24.0, 0.05, 5.0)), _hotspot_pos("carrion_field")],
			]
			connectors = [
				[_route_scaled_pos(Vector3(-32.0, 0.05, 16.0)), _route_scaled_pos(Vector3(-18.0, 0.05, 14.0))],
				[_route_scaled_pos(Vector3(0.0, 0.05, 6.0)), _route_scaled_pos(Vector3(10.0, 0.05, 4.0))],
				[_route_scaled_pos(Vector3(8.0, 0.05, -4.0)), _route_scaled_pos(Vector3(20.0, 0.05, -10.0))],
			]
			stage_markers = [
				{"pos": _route_scaled_pos(Vector3(-28.0, 0.05, 16.5)), "kind": "entry"},
				{"pos": _route_scaled_pos(Vector3(-6.0, 0.05, 6.8)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(12.0, 0.05, 2.6)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(20.0, 0.05, 6.0)), "kind": "branch"},
				{"pos": _route_scaled_pos(Vector3(20.0, 0.05, -4.0)), "kind": "branch"},
			]
		_:
			entry_routes = [
				[_route_scaled_pos(Vector3(-48.0, 0.05, 18.0)), _route_scaled_pos(Vector3(-34.0, 0.05, 16.0)), _route_scaled_pos(Vector3(-18.0, 0.05, 12.0)), _hotspot_pos("waterhole")],
			]
			trunk_routes = [
				[_hotspot_pos("waterhole"), _route_scaled_pos(Vector3(-8.0, 0.05, 8.5)), _route_scaled_pos(Vector3(14.0, 0.05, 4.0)), _route_scaled_pos(Vector3(28.0, 0.05, 0.0)), _hotspot_pos("migration_corridor"), _hotspot_pos("predator_ridge")],
			]
			branch_routes = [
				[_route_scaled_pos(Vector3(-8.0, 0.05, 8.5)), _route_scaled_pos(Vector3(-10.0, 0.05, -2.0)), _hotspot_pos("shade_grove")],
				[_hotspot_pos("waterhole"), _route_scaled_pos(Vector3(6.0, 0.05, -8.0)), _hotspot_pos("carrion_field")],
				[_route_scaled_pos(Vector3(28.0, 0.05, 0.0)), _route_scaled_pos(Vector3(22.0, 0.05, -10.0)), _hotspot_pos("predator_ridge")],
			]
			connectors = [
				[_route_scaled_pos(Vector3(-34.0, 0.05, 15.0)), _route_scaled_pos(Vector3(-20.0, 0.05, 12.0))],
				[_route_scaled_pos(Vector3(8.0, 0.05, 2.0)), _route_scaled_pos(Vector3(18.0, 0.05, -2.0))],
				[_route_scaled_pos(Vector3(0.0, 0.05, 6.0)), _route_scaled_pos(Vector3(-4.0, 0.05, 0.0))],
			]
			stage_markers = [
				{"pos": _route_scaled_pos(Vector3(-30.0, 0.05, 14.5)), "kind": "entry"},
				{"pos": _route_scaled_pos(Vector3(-8.0, 0.05, 8.4)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(16.0, 0.05, 4.0)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(28.0, 0.05, 0.0)), "kind": "trunk"},
				{"pos": _route_scaled_pos(Vector3(-8.0, 0.05, -2.0)), "kind": "branch"},
				{"pos": _route_scaled_pos(Vector3(8.0, 0.05, -8.0)), "kind": "branch"},
			]
	for route in entry_routes:
		for index in range(route.size() - 1):
			_add_entry_route_segment(route[index], route[index + 1], current_theme.get("route", Color8(240, 223, 176)))
	for route in trunk_routes:
		for index in range(route.size() - 1):
			_add_route_segment(route[index], route[index + 1], current_theme.get("route", Color8(240, 223, 176)))
	for route in branch_routes:
		for index in range(route.size() - 1):
			_add_branch_route_segment(route[index], route[index + 1], current_theme.get("route", Color8(240, 223, 176)))
	for connector in connectors:
		_add_route_connector(connector[0], connector[1], current_theme.get("route", Color8(240, 223, 176)).darkened(0.12))
	for marker in stage_markers:
		_add_route_stage_marker(_stage_marker_anchor(Vector3(marker.get("pos", Vector3.ZERO)), str(marker.get("kind", "trunk"))), str(marker.get("kind", "trunk")))
	_add_route_landmark(_route_landmark_anchor(_hotspot_pos("waterhole"), _hotspot_pos("migration_corridor"), 0.32, -1.0))
	_add_route_landmark(_route_landmark_anchor(_hotspot_pos("migration_corridor"), _hotspot_pos("predator_ridge"), 0.62, 1.0))


func _add_entry_route_segment(a: Vector3, b: Vector3, color: Color) -> void:
	var diff := b - a
	var length := diff.length()
	var root := Node3D.new()
	root.position = (a + b) * 0.5
	root.rotation.y = atan2(diff.x, diff.z)
	environment_root.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.56, 0.08, length)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.04, 0.0)
	mesh_instance.material_override = _material(color.lightened(0.04), 0.96)
	root.add_child(mesh_instance)
	for side in [-1.0, 1.0]:
		var edge := MeshInstance3D.new()
		var edge_mesh := BoxMesh.new()
		edge_mesh.size = Vector3(0.14, 0.16, length)
		edge.mesh = edge_mesh
		edge.position = Vector3(side * 0.88, 0.08, 0.0)
		edge.material_override = _material(color.darkened(0.18), 0.78)
		root.add_child(edge)
	var center_line := _box_mesh(Vector3(0.12, 0.04, length * 0.72), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
	center_line.position = Vector3(0.0, 0.05, 0.0)
	root.add_child(center_line)
	for side in [-1.0, 1.0]:
		var shoulder := _box_mesh(Vector3(0.08, 0.04, length * 0.56), color.darkened(0.1))
		shoulder.position = Vector3(side * 0.52, 0.04, 0.0)
		root.add_child(shoulder)
	for marker_index in range(max(2, int(length / 4.8))):
		var marker := _box_mesh(Vector3(0.2, 0.05, 0.44), current_theme.get("accent", Color8(236, 202, 118)))
		marker.position = Vector3(0.0, 0.08, -length * 0.5 + 1.1 + marker_index * 2.9)
		marker.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		root.add_child(marker)
	for side in [-1.0, 1.0]:
		for post_index in range(max(2, int(length / 5.6))):
			var post := _box_mesh(Vector3(0.1, 0.84, 0.1), Color8(122, 98, 66))
			post.position = Vector3(side * 1.06, 0.42, -length * 0.5 + 1.2 + post_index * 3.4)
			root.add_child(post)
			var light := MeshInstance3D.new()
			var light_mesh := SphereMesh.new()
			light_mesh.radius = 0.08
			light_mesh.height = 0.16
			light.mesh = light_mesh
			light.position = post.position + Vector3(0.0, 0.46, 0.0)
			light.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)), 0.9)
			root.add_child(light)
	var center_gate_bar := _box_mesh(Vector3(0.42, 0.06, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.22))
	center_gate_bar.position = Vector3(0.0, 0.18, length * 0.5 - 0.56)
	root.add_child(center_gate_bar)
	var terminal_pad := _box_mesh(Vector3(1.04, 0.03, 0.54), color.lightened(0.06))
	terminal_pad.position = Vector3(0.0, 0.025, length * 0.5 - 0.32)
	root.add_child(terminal_pad)
	for side in [-1.0, 1.0]:
		var terminal_post := _box_mesh(Vector3(0.08, 0.54, 0.08), Color8(118, 92, 62))
		terminal_post.position = Vector3(side * 0.38, 0.28, length * 0.5 - 0.36)
		root.add_child(terminal_post)
		var terminal_light := _box_mesh(Vector3(0.1, 0.1, 0.1), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.2))
		terminal_light.position = terminal_post.position + Vector3(0.0, 0.34, 0.0)
		root.add_child(terminal_light)
	for side in [-1.0, 1.0]:
		var terminal_rail := _box_mesh(Vector3(0.1, 0.12, 0.62), color.darkened(0.16))
		terminal_rail.position = Vector3(side * 0.34, 0.08, length * 0.5 - 0.28)
		root.add_child(terminal_rail)
	var terminal_cap := _box_mesh(Vector3(0.84, 0.06, 0.1), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.24))
	terminal_cap.position = Vector3(0.0, 0.12, length * 0.5 - 0.02)
	root.add_child(terminal_cap)
	_register_route_stage_visual(root, "entry_route", 1.08)

func _add_branch_route_segment(a: Vector3, b: Vector3, color: Color) -> void:
	var diff := b - a
	var length := diff.length()
	var root := Node3D.new()
	root.position = (a + b) * 0.5
	root.rotation.y = atan2(diff.x, diff.z)
	environment_root.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.84, 0.06, length)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.03, 0.0)
	mesh_instance.material_override = _material(color.darkened(0.04), 0.92)
	root.add_child(mesh_instance)
	for dash_index in range(max(2, int(length / 4.6))):
		var dash := _box_mesh(Vector3(0.18, 0.04, 0.34), color.lightened(0.1))
		dash.position = Vector3(0.0, 0.05, -length * 0.5 + 0.9 + dash_index * 2.7)
		root.add_child(dash)
	for side in [-1.0, 1.0]:
		var sign := _box_mesh(Vector3(0.08, 0.58, 0.08), Color8(112, 86, 58))
		sign.position = Vector3(side * 0.68, 0.3, -length * 0.18)
		root.add_child(sign)
	var branch_plate := _box_mesh(Vector3(0.64, 0.18, 0.06), current_theme.get("accent", Color8(236, 202, 118)).darkened(0.08))
	branch_plate.position = Vector3(0.0, 0.6, -length * 0.18)
	root.add_child(branch_plate)
	for side in [-1.0, 1.0]:
		var splitter := _box_mesh(Vector3(0.1, 0.34, 0.1), Color8(108, 84, 58))
		splitter.position = Vector3(side * 0.92, 0.18, length * 0.18)
		root.add_child(splitter)
		var splitter_arm := _box_mesh(Vector3(0.34, 0.08, 0.06), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.08))
		splitter_arm.position = Vector3(side * 0.76, 0.42, length * 0.18)
		splitter_arm.rotation_degrees = Vector3(0.0, side * 24.0, 0.0)
		root.add_child(splitter_arm)
	match current_biome:
		"wetland":
			for plank_index in range(max(2, int(length / 2.2))):
				var plank := _box_mesh(Vector3(0.96, 0.02, 0.12), color.lightened(0.1))
				plank.position = Vector3(0.0, 0.045, -length * 0.5 + 0.6 + plank_index * 1.2)
				root.add_child(plank)
		"forest":
			for side in [-1.0, 1.0]:
				var root_bar := _box_mesh(Vector3(0.08, 0.08, length * 0.72), color.darkened(0.2))
				root_bar.position = Vector3(side * 0.42, 0.05, 0.0)
				root_bar.rotation_degrees = Vector3(0.0, 0.0, side * 6.0)
				root.add_child(root_bar)
		"coast":
			for side in [-1.0, 1.0]:
				var dune_edge := _box_mesh(Vector3(0.12, 0.12, length * 0.66), color.darkened(0.18))
				dune_edge.position = Vector3(side * 0.54, 0.08, 0.0)
				root.add_child(dune_edge)
		_:
			for side in [-1.0, 1.0]:
				var stone_edge := _box_mesh(Vector3(0.12, 0.1, length * 0.62), color.darkened(0.16))
				stone_edge.position = Vector3(side * 0.5, 0.06, 0.0)
				root.add_child(stone_edge)
	_register_route_stage_visual(root, "branch_route", 1.04)


func _add_route_stage_marker(pos: Vector3, kind: String) -> void:
	var scale := lerpf(1.0, _world_spread_scale(), 0.6)
	if kind == "trunk":
		scale *= 1.16
	elif kind == "branch":
		scale *= 1.22
	elif kind == "entry":
		scale *= 1.06
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale
	environment_root.add_child(root)
	var base_color: Color = current_theme.get("accent", Color8(236, 202, 118))
	var pillar_color := Color8(114, 84, 52)
	var marker_color: Color = base_color
	match kind:
		"entry":
			marker_color = base_color.lightened(0.12)
		"branch":
			marker_color = base_color.darkened(0.12)
		_:
			marker_color = base_color
	var plate := _box_mesh(Vector3(1.2, 0.08, 1.2), marker_color)
	plate.material_override = _material(marker_color, 0.92)
	plate.position = Vector3(0.0, 0.05, 0.0)
	root.add_child(plate)
	var courtyard_size := Vector3(2.8, 0.04, 2.8)
	if kind == "entry":
		courtyard_size = Vector3(3.4, 0.04, 3.0)
	elif kind == "branch":
		courtyard_size = Vector3(2.3, 0.04, 2.3)
	var courtyard := _box_mesh(courtyard_size, marker_color.darkened(0.08))
	courtyard.material_override = _material(marker_color.darkened(0.08), 0.72)
	courtyard.position = Vector3(0.0, 0.02, 0.0)
	root.add_child(courtyard)
	if kind == "trunk":
		var route_pad := _box_mesh(Vector3(1.78, 0.05, 2.26), marker_color.lightened(0.08))
		route_pad.position = Vector3(0.0, 0.05, 0.0)
		root.add_child(route_pad)
		var hub_pad := _box_mesh(Vector3(3.6, 0.04, 3.2), marker_color.darkened(0.12))
		hub_pad.position = Vector3(0.0, 0.02, 0.0)
		hub_pad.material_override = _material(marker_color.darkened(0.12), 0.54)
		root.add_child(hub_pad)
		for direction in [-1.0, 1.0]:
			var throat := _box_mesh(Vector3(1.42, 0.05, 1.16), marker_color.lightened(0.04))
			throat.position = Vector3(0.0, 0.04, direction * 1.74)
			root.add_child(throat)
		for side in [-1.0, 1.0]:
			var lane_wall := _box_mesh(Vector3(0.12, 0.42, 2.0), marker_color.darkened(0.14))
			lane_wall.position = Vector3(side * 1.02, 0.22, 0.0)
			root.add_child(lane_wall)
			var bastion := _box_mesh(Vector3(0.64, 0.22, 0.64), marker_color.darkened(0.18))
			bastion.position = Vector3(side * 1.42, 0.12, 0.92)
			root.add_child(bastion)
			var rear_bastion := _box_mesh(Vector3(0.64, 0.22, 0.64), marker_color.darkened(0.18))
			rear_bastion.position = Vector3(side * 1.42, 0.12, -0.92)
			root.add_child(rear_bastion)
			var spur_pad := _box_mesh(Vector3(0.82, 0.04, 1.18), marker_color.lightened(0.02))
			spur_pad.position = Vector3(side * 1.86, 0.03, 0.0)
			root.add_child(spur_pad)
			var spur_edge := _box_mesh(Vector3(0.14, 0.12, 0.92), marker_color.darkened(0.16))
			spur_edge.position = Vector3(side * 2.12, 0.08, 0.0)
			root.add_child(spur_edge)
			var side_bench := _box_mesh(Vector3(0.42, 0.18, 0.84), marker_color.darkened(0.1))
			side_bench.position = Vector3(side * 2.34, 0.09, -0.84)
			root.add_child(side_bench)
		var route_sign := _box_mesh(Vector3(1.44, 0.34, 0.08), marker_color.lightened(0.14))
		route_sign.position = Vector3(0.0, 0.86, -0.78)
		root.add_child(route_sign)
		var route_sign_post := _box_mesh(Vector3(0.08, 0.58, 0.08), pillar_color)
		route_sign_post.position = Vector3(0.0, 0.46, -0.78)
		root.add_child(route_sign_post)
		for side in [-1.0, 1.0]:
			var side_plate := _box_mesh(Vector3(0.38, 0.16, 0.06), marker_color.lightened(0.1))
			side_plate.position = Vector3(side * 1.64, 0.34, 0.0)
			root.add_child(side_plate)
			var branch_post := _box_mesh(Vector3(0.08, 0.48, 0.08), pillar_color)
			branch_post.position = Vector3(side * 1.72, 0.26, 0.96)
			root.add_child(branch_post)
			var branch_arrow := _box_mesh(Vector3(0.34, 0.08, 0.08), marker_color.lightened(0.16))
			branch_arrow.position = Vector3(side * 1.52, 0.54, 0.96)
			branch_arrow.rotation_degrees = Vector3(0.0, side * 26.0, 0.0)
			root.add_child(branch_arrow)
		var canopy := _box_mesh(Vector3(3.26, 0.08, 0.16), marker_color.lightened(0.06))
		canopy.position = Vector3(0.0, 1.24, 0.0)
		root.add_child(canopy)
		var forecourt := _box_mesh(Vector3(2.4, 0.04, 1.5), marker_color.darkened(0.06))
		forecourt.position = Vector3(0.0, 0.02, -1.98)
		root.add_child(forecourt)
		for side in [-1.0, 1.0]:
			var fore_post := _box_mesh(Vector3(0.08, 0.54, 0.08), pillar_color)
			fore_post.position = Vector3(side * 1.18, 0.28, -1.98)
			root.add_child(fore_post)
			var fore_rail := _box_mesh(Vector3(0.12, 0.12, 1.12), marker_color.darkened(0.14))
			fore_rail.position = Vector3(side * 1.32, 0.08, -1.82)
			root.add_child(fore_rail)
		var station_lane := _box_mesh(Vector3(1.46, 0.03, 1.36), marker_color.lightened(0.02))
		station_lane.position = Vector3(0.0, 0.02, -1.16)
		root.add_child(station_lane)
		var axis_lane := _box_mesh(Vector3(0.64, 0.03, 3.96), marker_color.lightened(0.1))
		axis_lane.position = Vector3(0.0, 0.03, -1.02)
		root.add_child(axis_lane)
		for step in range(3):
			var axis_marker := _box_mesh(Vector3(0.18, 0.05, 0.3), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.08))
			axis_marker.position = Vector3(0.0, 0.06, -1.9 + step * 1.08)
			root.add_child(axis_marker)
		var gate_corridor := _box_mesh(Vector3(0.82, 0.03, 2.26), marker_color.lightened(0.04))
		gate_corridor.position = Vector3(0.0, 0.03, 1.92)
		root.add_child(gate_corridor)
		for side in [-1.0, 1.0]:
			var corridor_rail := _box_mesh(Vector3(0.12, 0.12, 1.96), marker_color.darkened(0.14))
			corridor_rail.position = Vector3(side * 0.62, 0.08, 1.92)
			root.add_child(corridor_rail)
		var gate_threshold := _box_mesh(Vector3(1.18, 0.05, 0.34), marker_color.lightened(0.12))
		gate_threshold.position = Vector3(0.0, 0.05, 3.0)
		root.add_child(gate_threshold)
		for side in [-1.0, 1.0]:
			var threshold_post := _box_mesh(Vector3(0.08, 0.42, 0.08), pillar_color)
			threshold_post.position = Vector3(side * 0.58, 0.22, 2.96)
			root.add_child(threshold_post)
		match current_biome:
			"wetland":
				for plank_index in range(4):
					var trunk_plank := _box_mesh(Vector3(1.12, 0.02, 0.12), marker_color.lightened(0.12))
					trunk_plank.position = Vector3(0.0, 0.055, -0.96 + plank_index * 1.02)
					root.add_child(trunk_plank)
				for side in [-1.0, 1.0]:
					var wet_pier := _box_mesh(Vector3(0.08, 0.18, 2.84), marker_color.darkened(0.18))
					wet_pier.position = Vector3(side * 0.9, 0.08, 0.48)
					root.add_child(wet_pier)
			"forest":
				for side in [-1.0, 1.0]:
					var root_arch := _box_mesh(Vector3(0.12, 0.26, 3.04), marker_color.darkened(0.22))
					root_arch.position = Vector3(side * 1.14, 0.12, 0.36)
					root_arch.rotation_degrees = Vector3(0.0, 0.0, side * 4.0)
					root.add_child(root_arch)
				var forest_canopy := _box_mesh(Vector3(2.72, 0.06, 0.22), marker_color.darkened(0.1))
				forest_canopy.position = Vector3(0.0, 1.36, -0.14)
				root.add_child(forest_canopy)
			"coast":
				for rib_index in range(4):
					var dune_rib := _box_mesh(Vector3(1.06, 0.02, 0.08), marker_color.lightened(0.08))
					dune_rib.position = Vector3(0.0, 0.05, -1.04 + rib_index * 1.04)
					root.add_child(dune_rib)
				for side in [-1.0, 1.0]:
					var shore_bank := _box_mesh(Vector3(0.12, 0.16, 2.66), marker_color.darkened(0.16))
					shore_bank.position = Vector3(side * 0.96, 0.08, 0.3)
					root.add_child(shore_bank)
			_:
				for side in [-1.0, 1.0]:
					var stone_curb := _box_mesh(Vector3(0.12, 0.16, 2.8), marker_color.darkened(0.18))
					stone_curb.position = Vector3(side * 0.94, 0.08, 0.34)
					root.add_child(stone_curb)
				var savanna_totem := _box_mesh(Vector3(0.12, 0.84, 0.12), pillar_color)
				savanna_totem.position = Vector3(0.0, 0.42, -1.36)
				root.add_child(savanna_totem)
	for side in [-1.0, 1.0]:
		var pillar := _box_mesh(Vector3(0.12, 0.94, 0.12), pillar_color)
		pillar.position = Vector3(side * 0.46, 0.47, 0.0)
		root.add_child(pillar)
	if kind == "entry":
		var lintel := _box_mesh(Vector3(1.08, 0.12, 0.12), marker_color)
		lintel.position = Vector3(0.0, 0.92, 0.0)
		root.add_child(lintel)
	elif kind == "branch":
		for side in [-1.0, 1.0]:
			var arrow := _box_mesh(Vector3(0.18, 0.08, 0.36), marker_color)
			arrow.position = Vector3(side * 0.24, 0.42, 0.2)
			arrow.rotation_degrees = Vector3(0.0, side * 32.0, 0.0)
			root.add_child(arrow)
	else:
		var beacon := MeshInstance3D.new()
		var beacon_mesh := CylinderMesh.new()
		beacon_mesh.top_radius = 0.12
		beacon_mesh.bottom_radius = 0.16
		beacon_mesh.height = 1.0
		beacon.mesh = beacon_mesh
		beacon.position = Vector3(0.0, 0.5, 0.0)
		beacon.material_override = _material(marker_color, 0.92)
		root.add_child(beacon)
		for side in [-1.0, 1.0]:
			var small_post := _box_mesh(Vector3(0.08, 0.58, 0.08), Color8(112, 88, 60))
			small_post.position = Vector3(side * 0.82, 0.28, 0.42)
			root.add_child(small_post)
			var lane_lamp := _box_mesh(Vector3(0.12, 0.12, 0.12), marker_color.lightened(0.12))
			lane_lamp.position = Vector3(side * 1.44, 0.26, 1.34)
			root.add_child(lane_lamp)
			var rear_lamp := _box_mesh(Vector3(0.12, 0.12, 0.12), marker_color.lightened(0.12))
			rear_lamp.position = Vector3(side * 1.44, 0.26, -1.34)
			root.add_child(rear_lamp)
	_register_route_stage_visual(root, "%s_marker" % kind, 1.22 if kind == "trunk" else (1.08 if kind == "branch" else 1.02))


func _build_hotspots() -> void:
	var spread_scale := _world_spread_scale()
	for hotspot in hotspots:
		var hotspot_id := str(hotspot.get("hotspot_id", ""))
		var dynamic_profile := _dynamic_hotspot_profile(hotspot_id)
		var dynamic_active := float(dynamic_profile.get("active_scale", 1.0))
		var dynamic_beacon := float(dynamic_profile.get("beacon_scale", 1.0))
		var pos := _hotspot_pos(hotspot_id)
		var cluster := Node3D.new()
		cluster.name = "Hotspot_" + hotspot_id
		cluster.position = pos + _hotspot_cluster_offset(hotspot_id)
		hotspot_root.add_child(cluster)
		var ring := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1.4 * dynamic_active * lerpf(1.0, spread_scale, 0.56)
		mesh.bottom_radius = 1.7 * dynamic_active * lerpf(1.0, spread_scale, 0.6)
		mesh.height = 0.2 * lerpf(1.0, spread_scale, 0.22)
		ring.mesh = mesh
		ring.position = Vector3(0.0, 0.1 * lerpf(1.0, spread_scale, 0.18), 0.0)
		ring.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)), 0.38)
		cluster.add_child(ring)

		var beacon := MeshInstance3D.new()
		var beacon_mesh := CylinderMesh.new()
		beacon_mesh.top_radius = 0.12 * lerpf(1.0, spread_scale, 0.38)
		beacon_mesh.bottom_radius = 0.18 * lerpf(1.0, spread_scale, 0.42)
		beacon_mesh.height = 2.2 * dynamic_beacon * lerpf(1.0, spread_scale, 0.44)
		beacon.mesh = beacon_mesh
		beacon.position = Vector3(0.0, 1.1 * dynamic_beacon * lerpf(1.0, spread_scale, 0.34), 0.0)
		beacon.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)), 0.7)
		cluster.add_child(beacon)
		var landmark := _add_hotspot_landmark(hotspot_id, pos, cluster)
		hotspot_visuals[hotspot_id] = {
			"cluster": cluster,
			"ring": ring,
			"beacon": beacon,
			"landmark": landmark,
		}


func _hotspot_cluster_offset(hotspot_id: String) -> Vector3:
	match hotspot_id:
		"waterhole":
			return Vector3(-1.0, 0.0, 0.8) * REGION_DISTANCE_SCALE
		"migration_corridor":
			return Vector3(0.0, 0.0, 1.3) * REGION_DISTANCE_SCALE
		"predator_ridge":
			return Vector3(1.1, 0.0, -0.9) * REGION_DISTANCE_SCALE
		"carrion_field":
			return Vector3(-0.9, 0.0, -1.1) * REGION_DISTANCE_SCALE
		"shade_grove":
			return Vector3(0.8, 0.0, 1.0) * REGION_DISTANCE_SCALE
		_:
			return Vector3.ZERO


func _route_landmark_anchor(a: Vector3, b: Vector3, t: float, lateral_sign: float) -> Vector3:
	var anchor := a.lerp(b, t)
	var span := b - a
	var planar := Vector3(span.x, 0.0, span.z)
	if planar.length() < 0.001:
		return anchor
	var lateral := Vector3(-planar.z, 0.0, planar.x).normalized()
	var spread_scale := lerpf(1.0, _world_spread_scale(), 0.42)
	return anchor + lateral * lateral_sign * 3.1 * REGION_DISTANCE_SCALE * spread_scale


func _stage_marker_anchor(pos: Vector3, kind: String) -> Vector3:
	var spawn := Vector3(current_layout.get("spawn", Vector3.ZERO))
	var factor := 1.0
	match kind:
		"trunk":
			factor = lerpf(1.0, ROUTE_POINT_SPREAD_SCALE, 0.42)
		"branch":
			factor = lerpf(1.0, ROUTE_POINT_SPREAD_SCALE, 0.56)
		"entry":
			factor = lerpf(1.0, ROUTE_POINT_SPREAD_SCALE, 0.12)
	return _spread_from_origin(pos, spawn, factor)


func _build_obstacles() -> void:
	for obstacle in current_layout.get("obstacles", []):
		var pos: Vector3 = obstacle.get("pos", Vector3.ZERO)
		var size: Vector3 = obstacle.get("size", Vector3.ONE)
		var kind := str(obstacle.get("kind", "rock"))
		var color := Color8(96, 92, 86)
		if kind in ["water", "marsh"]:
			color = current_theme.get("water", Color8(90, 152, 188))
		elif kind in ["grove", "forest", "reed"]:
			color = current_theme.get("foliage", Color8(96, 132, 74))
		elif kind in ["ridge", "coast_ridge"]:
			color = Color8(108, 98, 82)
		var mesh := _soft_obstacle_mesh(size, color, kind)
		mesh.position = pos
		environment_root.add_child(mesh)
		if kind in ["ridge", "coast_ridge"]:
			var cap := MeshInstance3D.new()
			var cap_mesh := SphereMesh.new()
			cap_mesh.radius = 0.5
			cap_mesh.height = 1.0
			cap.mesh = cap_mesh
			cap.scale = Vector3(size.x * 0.82, maxf(0.08, size.y * 0.22), size.z * 0.78)
			cap.position = pos + Vector3(0.0, size.y * 0.48, 0.0)
			cap.material_override = _material(Color8(176, 156, 118), 0.94)
			environment_root.add_child(cap)
		elif kind in ["water", "marsh"]:
			var rim := MeshInstance3D.new()
			var rim_mesh := SphereMesh.new()
			rim_mesh.radius = 0.5
			rim_mesh.height = 1.0
			rim.mesh = rim_mesh
			rim.scale = Vector3(size.x * 1.02, 0.08, size.z * 1.02)
			rim.position = pos + Vector3(0.0, size.y * 0.46 + 0.02, 0.0)
			rim.material_override = _material(Color8(208, 196, 154), 0.92)
			environment_root.add_child(rim)
		_add_static_collider(pos, size)


func _build_props() -> void:
	var props: Dictionary = current_layout.get("props", {})
	for pos in props.get("trees", []):
		var tree_pos := pos as Vector3
		if _is_hotspot_prop_zone(tree_pos, 3.6 * REGION_DISTANCE_SCALE):
			continue
		_add_tree(tree_pos, false)
		for offset in _prop_cluster_offsets("tree"):
			var extra_tree_pos: Vector3 = tree_pos + offset
			if _is_hotspot_prop_zone(extra_tree_pos, 3.6 * REGION_DISTANCE_SCALE):
				continue
			_add_tree(extra_tree_pos, false)
	for pos in props.get("palms", []):
		var palm_pos := pos as Vector3
		if _is_hotspot_prop_zone(palm_pos, 3.8 * REGION_DISTANCE_SCALE):
			continue
		_add_tree(palm_pos, true)
		for offset in _prop_cluster_offsets("palm"):
			var extra_palm_pos: Vector3 = palm_pos + offset
			if _is_hotspot_prop_zone(extra_palm_pos, 3.8 * REGION_DISTANCE_SCALE):
				continue
			_add_tree(extra_palm_pos, true)
	for pos in props.get("shrubs", []):
		var shrub_pos := pos as Vector3
		if _is_hotspot_prop_zone(shrub_pos, 4.8 * REGION_DISTANCE_SCALE):
			continue
		_add_shrub(shrub_pos)
		for offset in _prop_cluster_offsets("shrub"):
			var extra_shrub_pos: Vector3 = shrub_pos + offset
			if _is_hotspot_prop_zone(extra_shrub_pos, 4.8 * REGION_DISTANCE_SCALE):
				continue
			_add_shrub(extra_shrub_pos)
	for pos in props.get("reeds", []):
		var reed_pos := pos as Vector3
		if _is_hotspot_prop_zone(reed_pos, 5.2 * REGION_DISTANCE_SCALE):
			continue
		_add_reed_cluster(reed_pos)
		for offset in _prop_cluster_offsets("reed"):
			var extra_reed_pos: Vector3 = reed_pos + offset
			if _is_hotspot_prop_zone(extra_reed_pos, 5.2 * REGION_DISTANCE_SCALE):
				continue
			_add_reed_cluster(extra_reed_pos)
	for route_grass in [Vector3(-12.0, 0.0, 14.0), Vector3(14.0, 0.0, -4.0), Vector3(24.0, 0.0, 10.0)]:
		_add_reed_cluster(_scaled_pos(route_grass))
	_build_ground_scatter_features()


func _prop_cluster_offsets(kind: String) -> Array:
	match kind:
		"tree":
			return [
				Vector3(-4.0, 0.0, 2.8) * REGION_DISTANCE_SCALE,
				Vector3(3.6, 0.0, -2.4) * REGION_DISTANCE_SCALE,
				Vector3(-1.8, 0.0, -3.4) * REGION_DISTANCE_SCALE,
				Vector3(2.4, 0.0, 3.2) * REGION_DISTANCE_SCALE,
			]
		"palm":
			return [
				Vector3(-3.4, 0.0, 2.0) * REGION_DISTANCE_SCALE,
				Vector3(3.0, 0.0, -1.8) * REGION_DISTANCE_SCALE,
				Vector3(-1.6, 0.0, -2.8) * REGION_DISTANCE_SCALE,
			]
		"shrub":
			return [
				Vector3(-2.8, 0.0, 1.6) * REGION_DISTANCE_SCALE,
				Vector3(2.4, 0.0, -1.4) * REGION_DISTANCE_SCALE,
				Vector3(1.2, 0.0, 2.2) * REGION_DISTANCE_SCALE,
				Vector3(-1.6, 0.0, -2.2) * REGION_DISTANCE_SCALE,
				Vector3(3.0, 0.0, 0.8) * REGION_DISTANCE_SCALE,
			]
		"reed":
			return [
				Vector3(-2.6, 0.0, 1.8) * REGION_DISTANCE_SCALE,
				Vector3(2.2, 0.0, -1.6) * REGION_DISTANCE_SCALE,
				Vector3(-1.2, 0.0, -2.4) * REGION_DISTANCE_SCALE,
				Vector3(1.8, 0.0, 2.6) * REGION_DISTANCE_SCALE,
			]
		_:
			return []


func _is_hotspot_prop_zone(pos: Vector3, radius: float) -> bool:
	for hotspot_id in ["waterhole", "migration_corridor", "predator_ridge", "carrion_field", "shade_grove"]:
		if pos.distance_to(_hotspot_pos(hotspot_id)) <= radius:
			return true
	return false


func _build_ground_scatter_features() -> void:
	match current_biome:
		"wetland":
			for pos in [_layout_scaled_pos(Vector3(-18.0, 0.0, 12.0)), _layout_scaled_pos(Vector3(10.0, 0.0, -4.0)), _layout_scaled_pos(Vector3(20.0, 0.0, -12.0))]:
				_add_ground_scatter_cluster(pos, Color8(120, 110, 86), Color8(92, 82, 64), 7, 3.8, true)
		"forest":
			for pos in [_layout_scaled_pos(Vector3(-16.0, 0.0, 18.0)), _layout_scaled_pos(Vector3(4.0, 0.0, 10.0)), _layout_scaled_pos(Vector3(18.0, 0.0, -8.0))]:
				_add_ground_scatter_cluster(pos, Color8(104, 94, 74), Color8(82, 70, 54), 8, 4.0, true)
		"coast":
			for pos in [_layout_scaled_pos(Vector3(-20.0, 0.0, 16.0)), _layout_scaled_pos(Vector3(6.0, 0.0, 2.0)), _layout_scaled_pos(Vector3(22.0, 0.0, -10.0))]:
				_add_ground_scatter_cluster(pos, Color8(178, 168, 142), Color8(140, 126, 102), 7, 4.2, false)
		_:
			for pos in [_layout_scaled_pos(Vector3(-18.0, 0.0, 14.0)), _layout_scaled_pos(Vector3(8.0, 0.0, 0.0)), _layout_scaled_pos(Vector3(24.0, 0.0, -12.0))]:
				_add_ground_scatter_cluster(pos, Color8(150, 132, 96), Color8(112, 96, 68), 8, 4.0, false)


func _add_ground_scatter_cluster(center: Vector3, stone_color: Color, wood_color: Color, count: int, radius: float, with_log: bool) -> void:
	for index in range(count):
		var phase := float(index) * 1.22 + center.x * 0.08 + center.z * 0.04
		var offset := Vector3(cos(phase) * radius * (0.42 + 0.1 * index), 0.0, sin(phase * 1.14) * radius * (0.36 + 0.08 * index))
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.14 + 0.06 * float(index % 3)
		rock_mesh.height = rock_mesh.radius * 1.26
		rock.mesh = rock_mesh
		rock.position = center + offset + Vector3(0.0, rock_mesh.radius * 0.7, 0.0)
		rock.scale = Vector3(1.18, 0.72 + 0.06 * float(index % 3), 0.86)
		rock.rotation_degrees = Vector3(0.0, phase * 62.0, 0.0)
		rock.material_override = _material(stone_color.lightened(0.04 * float(index % 2)), 0.94)
		environment_root.add_child(rock)
		if index % 2 == 0:
			var tuft := MeshInstance3D.new()
			var tuft_mesh := BoxMesh.new()
			tuft_mesh.size = Vector3(0.08, 0.16 + 0.04 * float(index % 3), 0.22)
			tuft.mesh = tuft_mesh
			tuft.position = center + offset + Vector3(0.12, tuft_mesh.size.y * 0.5, -0.08)
			tuft.rotation_degrees = Vector3(-12.0, phase * 48.0, 8.0)
			tuft.material_override = _material(current_theme.get("foliage", Color8(108, 138, 84)).darkened(0.08), 0.88)
			environment_root.add_child(tuft)
		if index % 3 == 1:
			var twig := MeshInstance3D.new()
			var twig_mesh := BoxMesh.new()
			twig_mesh.size = Vector3(0.34, 0.04, 0.08)
			twig.mesh = twig_mesh
			twig.position = center + offset + Vector3(-0.14, 0.04, 0.06)
			twig.rotation_degrees = Vector3(0.0, phase * 72.0, 0.0)
			twig.material_override = _material(wood_color.darkened(0.04), 0.92)
			environment_root.add_child(twig)
			var twig_cross := MeshInstance3D.new()
			var twig_cross_mesh := BoxMesh.new()
			twig_cross_mesh.size = Vector3(0.26, 0.035, 0.06)
			twig_cross.mesh = twig_cross_mesh
			twig_cross.position = twig.position + Vector3(0.06, 0.01, -0.04)
			twig_cross.rotation_degrees = Vector3(0.0, phase * 72.0 + 48.0, 0.0)
			twig_cross.material_override = _material(wood_color.darkened(0.1), 0.9)
			environment_root.add_child(twig_cross)
	if with_log:
		var log := MeshInstance3D.new()
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.12
		log_mesh.bottom_radius = 0.16
		log_mesh.height = 1.4
		log.mesh = log_mesh
		log.position = center + Vector3(0.0, 0.18, 0.0)
		log.rotation_degrees = Vector3(0.0, center.x * 9.0 + center.z * 4.0, 84.0)
		log.material_override = _material(wood_color, 0.94)
		environment_root.add_child(log)


func _build_biome_structures() -> void:
	match current_biome:
		"wetland":
			_add_boardwalk([_layout_scaled_pos(Vector3(-24.0, 0.18, 12.0)), _layout_scaled_pos(Vector3(-16.0, 0.18, 8.0)), _layout_scaled_pos(Vector3(-8.0, 0.18, 4.0))], Color8(136, 112, 78))
			_add_fence_line(_layout_scaled_pos(Vector3(14.0, 0.0, -8.0)), 7, 2.6 * LAYOUT_SPREAD_SCALE, Color8(116, 98, 72))
		"forest":
			_add_fence_line(_layout_scaled_pos(Vector3(-22.0, 0.0, 14.0)), 8, 2.5 * LAYOUT_SPREAD_SCALE, Color8(102, 88, 64))
			_add_cliff_stack(_layout_scaled_pos(Vector3(20.0, 0.0, -16.0)), 5, Color8(118, 108, 86))
		"coast":
			_add_dune_ridge(_layout_scaled_pos(Vector3(-10.0, 0.0, 14.0)), 7, Color8(214, 198, 154))
			_add_boardwalk([_layout_scaled_pos(Vector3(10.0, 0.12, 2.0)), _layout_scaled_pos(Vector3(18.0, 0.12, 4.0)), _layout_scaled_pos(Vector3(26.0, 0.12, 6.0))], Color8(164, 138, 94))
		_:
			_add_fence_line(_layout_scaled_pos(Vector3(-18.0, 0.0, 14.0)), 7, 2.8 * LAYOUT_SPREAD_SCALE, Color8(122, 98, 66))
			_add_cliff_stack(_layout_scaled_pos(Vector3(24.0, 0.0, -18.0)), 4, Color8(144, 126, 88))


func _build_route_barriers() -> void:
	match current_biome:
		"wetland":
			_add_barrier_block(_layout_scaled_pos(Vector3(-2.0, 0.8, 14.0)), _scaled_size(Vector3(18.0, 1.6, 2.6)), Color8(110, 126, 98), 0.92)
			_add_barrier_block(_layout_scaled_pos(Vector3(12.0, 0.9, -12.0)), _scaled_size(Vector3(10.0, 1.8, 3.0)), Color8(106, 144, 92), 0.94)
			_add_barrier_block(_layout_scaled_pos(Vector3(-28.0, 0.9, 2.0)), _scaled_size(Vector3(8.0, 1.7, 10.0)), Color8(92, 112, 84), 0.92)
		"forest":
			_add_barrier_block(_layout_scaled_pos(Vector3(-4.0, 1.1, 15.0)), _scaled_size(Vector3(16.0, 2.2, 2.8)), Color8(74, 88, 62), 0.94)
			_add_barrier_block(_layout_scaled_pos(Vector3(8.0, 1.2, -10.0)), _scaled_size(Vector3(12.0, 2.4, 3.0)), Color8(88, 76, 58), 0.92)
			_add_barrier_block(_layout_scaled_pos(Vector3(28.0, 1.4, 6.0)), _scaled_size(Vector3(7.0, 2.8, 14.0)), Color8(66, 80, 54), 0.94)
		"coast":
			_add_barrier_block(_layout_scaled_pos(Vector3(-2.0, 0.9, 15.0)), _scaled_size(Vector3(18.0, 1.8, 2.8)), Color8(214, 198, 154), 0.9)
			_add_barrier_block(_layout_scaled_pos(Vector3(16.0, 1.0, -10.0)), _scaled_size(Vector3(10.0, 2.0, 3.0)), Color8(182, 170, 142), 0.9)
			_add_barrier_block(_layout_scaled_pos(Vector3(-26.0, 1.0, -6.0)), _scaled_size(Vector3(10.0, 1.8, 8.0)), Color8(198, 188, 156), 0.88)
		_:
			_add_barrier_block(_layout_scaled_pos(Vector3(-2.0, 0.9, 15.0)), _scaled_size(Vector3(16.0, 1.8, 2.8)), Color8(156, 138, 92), 0.9)
			_add_barrier_block(_layout_scaled_pos(Vector3(12.0, 1.0, -10.0)), _scaled_size(Vector3(10.0, 2.2, 3.2)), Color8(144, 126, 88), 0.92)
			_add_barrier_block(_layout_scaled_pos(Vector3(30.0, 1.2, 2.0)), _scaled_size(Vector3(8.0, 2.0, 12.0)), Color8(132, 116, 84), 0.9)


func _build_navigation_blocks() -> void:
	match current_biome:
		"wetland":
			_add_navigation_block(_layout_scaled_pos(Vector3(-40.0, 0.9, 4.0)), _scaled_size(Vector3(8.0, 1.8, 22.0)), Color8(84, 110, 92), "reed_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(36.0, 0.9, -10.0)), _scaled_size(Vector3(7.0, 1.8, 18.0)), Color8(96, 124, 96), "reed_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(2.0, 0.8, -32.0)), _scaled_size(Vector3(26.0, 1.6, 7.0)), Color8(96, 118, 94), "marsh_bank")
			_add_navigation_block(_layout_scaled_pos(Vector3(-6.0, 0.8, 34.0)), _scaled_size(Vector3(18.0, 1.5, 6.0)), Color8(92, 120, 98), "causeway_edge")
		"forest":
			_add_navigation_block(_layout_scaled_pos(Vector3(-40.0, 1.3, 2.0)), _scaled_size(Vector3(10.0, 2.6, 26.0)), Color8(58, 80, 58), "tree_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(34.0, 1.2, -22.0)), _scaled_size(Vector3(10.0, 2.4, 16.0)), Color8(66, 84, 58), "tree_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(4.0, 1.2, 34.0)), _scaled_size(Vector3(24.0, 2.2, 8.0)), Color8(74, 90, 62), "rock_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(-14.0, 1.1, -34.0)), _scaled_size(Vector3(20.0, 2.1, 6.0)), Color8(70, 86, 60), "root_barrier")
		"coast":
			_add_navigation_block(_layout_scaled_pos(Vector3(-36.0, 0.9, -12.0)), _scaled_size(Vector3(9.0, 1.8, 20.0)), Color8(214, 202, 168), "dune_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(36.0, 1.0, 22.0)), _scaled_size(Vector3(8.0, 2.0, 18.0)), Color8(206, 194, 156), "dune_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(4.0, 0.9, -36.0)), _scaled_size(Vector3(28.0, 1.8, 8.0)), Color8(188, 176, 142), "coast_bank")
			_add_navigation_block(_layout_scaled_pos(Vector3(-8.0, 0.9, 36.0)), _scaled_size(Vector3(20.0, 1.6, 6.0)), Color8(196, 186, 154), "rope_break")
		_:
			_add_navigation_block(_layout_scaled_pos(Vector3(-40.0, 1.0, 0.0)), _scaled_size(Vector3(9.0, 2.0, 24.0)), Color8(128, 120, 84), "ridge_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(36.0, 1.0, -22.0)), _scaled_size(Vector3(9.0, 2.0, 16.0)), Color8(136, 124, 88), "ridge_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(2.0, 1.0, 36.0)), _scaled_size(Vector3(30.0, 2.0, 8.0)), Color8(122, 138, 82), "thorn_wall")
			_add_navigation_block(_layout_scaled_pos(Vector3(-10.0, 0.9, -36.0)), _scaled_size(Vector3(18.0, 1.7, 6.0)), Color8(134, 126, 86), "totem_fence")


func _build_route_chokepoints() -> void:
	match current_biome:
		"wetland":
			_add_chokepoint_pair(_scaled_pos(Vector3(-12.0, 0.7, 10.0)), _scaled_pos(Vector3(-12.0, 0.7, 17.0)), _scaled_size(Vector3(2.2, 1.4, 3.6)), Color8(118, 102, 78))
			_add_chokepoint_pair(_scaled_pos(Vector3(10.0, 0.8, -4.0)), _scaled_pos(Vector3(10.0, 0.8, 4.0)), _scaled_size(Vector3(2.0, 1.6, 3.2)), Color8(122, 108, 82))
			_add_chokepoint_pair(_scaled_pos(Vector3(-18.0, 0.7, 0.0)), _scaled_pos(Vector3(-10.0, 0.7, 0.0)), _scaled_size(Vector3(1.8, 1.3, 3.2)), Color8(112, 98, 74))
		"forest":
			_add_chokepoint_pair(_scaled_pos(Vector3(-8.0, 0.9, 12.0)), _scaled_pos(Vector3(-8.0, 0.9, 20.0)), _scaled_size(Vector3(2.4, 1.8, 4.0)), Color8(92, 82, 62))
			_add_chokepoint_pair(_scaled_pos(Vector3(18.0, 1.0, -8.0)), _scaled_pos(Vector3(18.0, 1.0, 0.0)), _scaled_size(Vector3(2.4, 1.8, 4.0)), Color8(88, 78, 58))
			_add_chokepoint_pair(_scaled_pos(Vector3(-2.0, 0.9, 6.0)), _scaled_pos(Vector3(6.0, 0.9, 6.0)), _scaled_size(Vector3(2.0, 1.6, 3.6)), Color8(84, 74, 56))
		"coast":
			_add_chokepoint_pair(_scaled_pos(Vector3(-10.0, 0.8, 10.0)), _scaled_pos(Vector3(-10.0, 0.8, 18.0)), _scaled_size(Vector3(2.4, 1.5, 3.8)), Color8(196, 186, 152))
			_add_chokepoint_pair(_scaled_pos(Vector3(16.0, 0.9, 0.0)), _scaled_pos(Vector3(16.0, 0.9, 8.0)), _scaled_size(Vector3(2.0, 1.6, 3.4)), Color8(188, 174, 142))
			_add_chokepoint_pair(_scaled_pos(Vector3(8.0, 0.8, -2.0)), _scaled_pos(Vector3(8.0, 0.8, 6.0)), _scaled_size(Vector3(1.8, 1.4, 3.2)), Color8(182, 168, 138))
		_:
			_add_chokepoint_pair(_scaled_pos(Vector3(-14.0, 0.8, 8.0)), _scaled_pos(Vector3(-14.0, 0.8, 16.0)), _scaled_size(Vector3(2.4, 1.6, 3.8)), Color8(146, 128, 88))
			_add_chokepoint_pair(_scaled_pos(Vector3(14.0, 0.9, -4.0)), _scaled_pos(Vector3(14.0, 0.9, 4.0)), _scaled_size(Vector3(2.2, 1.8, 3.4)), Color8(138, 122, 84))
			_add_chokepoint_pair(_scaled_pos(Vector3(4.0, 0.8, 2.0)), _scaled_pos(Vector3(12.0, 0.8, 2.0)), _scaled_size(Vector3(2.0, 1.5, 3.4)), Color8(132, 118, 82))


func _add_chokepoint_pair(a: Vector3, b: Vector3, size: Vector3, color: Color) -> void:
	var scale := lerpf(1.0, _world_spread_scale(), 0.66)
	_add_barrier_block(a, size, color, 0.9)
	_add_barrier_block(b, size, color, 0.9)
	var center := (a + b) * 0.5
	var lane_vec := (b - a)
	var lateral := Vector3(lane_vec.z, 0.0, -lane_vec.x).normalized()
	var gate_root := Node3D.new()
	gate_root.position = center
	gate_root.rotation.y = atan2(lane_vec.x, lane_vec.z)
	environment_root.add_child(gate_root)
	var threshold := _box_mesh(Vector3(1.4 * scale, 0.05, 2.0 * scale), current_theme.get("route", Color8(240, 223, 176)).lightened(0.08))
	threshold.position = Vector3(0.0, 0.03, 0.0)
	gate_root.add_child(threshold)
	for direction in [-1.0, 1.0]:
		var forecourt := _box_mesh(Vector3(1.96 * scale, 0.04, 1.5 * scale), current_theme.get("route", Color8(240, 223, 176)).darkened(0.04))
		forecourt.position = Vector3(0.0, 0.02, direction * 1.88 * scale)
		gate_root.add_child(forecourt)
		var forecourt_edge := _box_mesh(Vector3(1.52 * scale, 0.06, 0.16), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.08))
		forecourt_edge.position = Vector3(0.0, 0.05, direction * 2.48 * scale)
		gate_root.add_child(forecourt_edge)
		var approach_lane := _box_mesh(Vector3(1.18 * scale, 0.03, 1.22 * scale), current_theme.get("route", Color8(240, 223, 176)).lightened(0.04))
		approach_lane.position = Vector3(0.0, 0.02, direction * 3.28 * scale)
		gate_root.add_child(approach_lane)
		for side in [-1.0, 1.0]:
			var taper_rail := _box_mesh(Vector3(0.1, 0.1, 1.02), color.darkened(0.16))
			taper_rail.position = Vector3(side * 0.74, 0.07, direction * 3.22)
			gate_root.add_child(taper_rail)
		for step in range(3):
			var guide_mark := _box_mesh(Vector3(0.16, 0.05, 0.24), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.12))
			guide_mark.position = Vector3(0.0, 0.06, direction * (2.62 + step * 0.48))
			guide_mark.rotation_degrees = Vector3(0.0, 45.0, 0.0)
			gate_root.add_child(guide_mark)
		for step in range(2):
			var lane_dash := _box_mesh(Vector3(0.12, 0.05, 0.22), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
			lane_dash.position = Vector3(0.0, 0.06, direction * (3.0 + step * 0.42))
			gate_root.add_child(lane_dash)
		var lane_spine := _box_mesh(Vector3(0.1, 0.04, 0.82), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.12))
		lane_spine.position = Vector3(0.0, 0.04, direction * 3.34)
		gate_root.add_child(lane_spine)
		var lane_spine_mid := _box_mesh(Vector3(0.08, 0.04, 0.66), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
		lane_spine_mid.position = Vector3(0.0, 0.04, direction * 2.72)
		gate_root.add_child(lane_spine_mid)
		for side in [-1.0, 1.0]:
			var lane_edge := _box_mesh(Vector3(0.08, 0.04, 0.88), current_theme.get("route", Color8(240, 223, 176)).darkened(0.08))
			lane_edge.position = Vector3(side * 0.42, 0.035, direction * 3.34)
			gate_root.add_child(lane_edge)
			var lane_taper := _box_mesh(Vector3(0.08, 0.04, 0.44), current_theme.get("route", Color8(240, 223, 176)).darkened(0.12))
			lane_taper.position = Vector3(side * 0.28, 0.035, direction * 3.78)
			gate_root.add_child(lane_taper)
			var lane_border := _box_mesh(Vector3(0.08, 0.04, 0.74), current_theme.get("route", Color8(240, 223, 176)).darkened(0.16))
			lane_border.position = Vector3(side * 0.56, 0.035, direction * 2.7)
			gate_root.add_child(lane_border)
		var lane_arrow := _box_mesh(Vector3(0.2, 0.06, 0.28), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.22))
		lane_arrow.position = Vector3(0.0, 0.07, direction * 3.72)
		lane_arrow.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		gate_root.add_child(lane_arrow)
		for side in [-1.0, 1.0]:
			var lane_light := _box_mesh(Vector3(0.1, 0.1, 0.1), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
			lane_light.position = Vector3(side * 0.88, 0.12, direction * 3.56)
			gate_root.add_child(lane_light)
			var lane_light_mid := _box_mesh(Vector3(0.08, 0.08, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.14))
			lane_light_mid.position = Vector3(side * 0.72, 0.1, direction * 2.96)
			gate_root.add_child(lane_light_mid)
			var lane_light_front := _box_mesh(Vector3(0.08, 0.08, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.16))
			lane_light_front.position = Vector3(side * 0.54, 0.1, direction * 2.48)
			gate_root.add_child(lane_light_front)
			var lane_light_inner := _box_mesh(Vector3(0.08, 0.08, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.2))
			lane_light_inner.position = Vector3(side * 0.38, 0.1, direction * 2.12)
			gate_root.add_child(lane_light_inner)
	for side in [-1.0, 1.0]:
		var post := _box_mesh(Vector3(0.14, 1.18, 0.14), Color8(118, 90, 62))
		post.position = Vector3(side * 0.54 * scale, 0.58, 0.0)
		gate_root.add_child(post)
		var lamp := MeshInstance3D.new()
		var lamp_mesh := SphereMesh.new()
		lamp_mesh.radius = 0.08
		lamp_mesh.height = 0.16
		lamp.mesh = lamp_mesh
		lamp.position = post.position + Vector3(0.0, 0.6, 0.0)
		lamp.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)), 0.92)
		gate_root.add_child(lamp)
	var lintel := _box_mesh(Vector3(1.18 * scale, 0.14, 0.14), Color8(168, 144, 104))
	lintel.position = Vector3(0.0, 1.18, 0.0)
	gate_root.add_child(lintel)
	for side in [-1.0, 1.0]:
		var rail := _box_mesh(Vector3(0.08, 0.24, 1.3), color.darkened(0.1))
		rail.position = Vector3(side * 0.86 * scale, 0.14, 0.0)
		gate_root.add_child(rail)
		for direction in [-1.0, 1.0]:
			var pylon := _box_mesh(Vector3(0.1, 0.68, 0.1), Color8(126, 98, 68))
			pylon.position = Vector3(side * 1.22, 0.34, direction * 1.86)
			gate_root.add_child(pylon)
			var pylon_cap := _box_mesh(Vector3(0.16, 0.08, 0.16), current_theme.get("accent", Color8(236, 202, 118)))
			pylon_cap.position = pylon.position + Vector3(0.0, 0.38, 0.0)
			gate_root.add_child(pylon_cap)
	match current_biome:
		"wetland":
			for side in [-1.0, 1.0]:
				var reed_guard := _box_mesh(Vector3(0.12, 0.2, 2.1), color.darkened(0.18))
				reed_guard.position = Vector3(side * 1.4 * scale, 0.08, 0.0)
				gate_root.add_child(reed_guard)
		"forest":
			for side in [-1.0, 1.0]:
				var root_gate := _box_mesh(Vector3(0.12, 0.24, 2.0), color.darkened(0.22))
				root_gate.position = Vector3(side * 1.34 * scale, 0.12, 0.0)
				root_gate.rotation_degrees = Vector3(0.0, 0.0, side * 5.0)
				gate_root.add_child(root_gate)
		"coast":
			for side in [-1.0, 1.0]:
				var shore_gate := _box_mesh(Vector3(0.12, 0.18, 2.02), color.darkened(0.16))
				shore_gate.position = Vector3(side * 1.36 * scale, 0.08, 0.0)
				gate_root.add_child(shore_gate)
		_:
			for side in [-1.0, 1.0]:
				var stone_gate := _box_mesh(Vector3(0.14, 0.18, 2.04), color.darkened(0.18))
				stone_gate.position = Vector3(side * 1.36 * scale, 0.08, 0.0)
				gate_root.add_child(stone_gate)
	_register_route_stage_visual(gate_root, "chokepoint", 1.18)


func _add_navigation_block(pos: Vector3, size: Vector3, color: Color, kind: String) -> void:
	var shell := _box_mesh(size, color)
	shell.material_override = _material(color, 0.92)
	shell.position = pos
	environment_root.add_child(shell)
	match kind:
		"reed_wall":
			for index in range(8):
				var reed := _box_mesh(Vector3(0.24, size.y * 0.72, 0.24), color.lightened(0.12))
				reed.position = pos + Vector3(-size.x * 0.38 + index * size.x * 0.11, size.y * 0.32, sin(float(index)) * size.z * 0.18)
				environment_root.add_child(reed)
			for index in range(5):
				var stake := _box_mesh(Vector3(0.12, size.y * 0.84, 0.12), color.darkened(0.2))
				stake.position = pos + Vector3(-size.x * 0.34 + index * size.x * 0.17, size.y * 0.36, -size.z * 0.22)
				environment_root.add_child(stake)
			var berm := _box_mesh(Vector3(size.x * 0.88, 0.18, size.z * 0.36), color.darkened(0.12))
			berm.position = pos + Vector3(0.0, -size.y * 0.38, size.z * 0.16)
			environment_root.add_child(berm)
		"tree_wall":
			for index in range(6):
				_add_tree(pos + Vector3(-size.x * 0.34 + index * size.x * 0.14, 0.0, sin(float(index) * 1.7) * size.z * 0.18), false)
			for index in range(4):
				var root_rib := _box_mesh(Vector3(size.x * 0.14, 0.18, size.z * 0.26), color.darkened(0.22))
				root_rib.position = pos + Vector3(-size.x * 0.3 + index * size.x * 0.2, 0.08, size.z * 0.24)
				root_rib.rotation_degrees = Vector3(0.0, 0.0, -14.0 + index * 8.0)
				environment_root.add_child(root_rib)
		"dune_wall":
			for index in range(5):
				_add_dune_ridge(pos + Vector3(-size.x * 0.24 + index * size.x * 0.12, 0.0, 0.0), 2, color.lightened(0.06))
			for index in range(4):
				var rope_post := _box_mesh(Vector3(0.14, size.y * 0.62, 0.14), color.darkened(0.24))
				rope_post.position = pos + Vector3(-size.x * 0.28 + index * size.x * 0.18, size.y * 0.12, -size.z * 0.18)
				environment_root.add_child(rope_post)
		"ridge_wall":
			for index in range(4):
				var top := _box_mesh(Vector3(size.x * 0.22, 0.3, size.z * 0.24), color.lightened(0.1))
				top.position = pos + Vector3(-size.x * 0.28 + index * size.x * 0.18, size.y * 0.54, sin(float(index) * 1.6) * size.z * 0.12)
				environment_root.add_child(top)
			for index in range(3):
				var spur := _box_mesh(Vector3(size.x * 0.16, 0.26, size.z * 0.14), color.darkened(0.18))
				spur.position = pos + Vector3(-size.x * 0.22 + index * size.x * 0.22, size.y * 0.68, -size.z * 0.2)
				environment_root.add_child(spur)
		"rock_wall":
			for index in range(4):
				var slab := _box_mesh(Vector3(size.x * 0.22, 0.3, size.z * 0.24), color.lightened(0.1))
				slab.position = pos + Vector3(-size.x * 0.28 + index * size.x * 0.18, size.y * 0.54, sin(float(index) * 1.6) * size.z * 0.12)
				environment_root.add_child(slab)
			for index in range(3):
				var crag := _box_mesh(Vector3(size.x * 0.12, size.y * 0.24, size.z * 0.16), color.darkened(0.14))
				crag.position = pos + Vector3(-size.x * 0.18 + index * size.x * 0.18, size.y * 0.82, size.z * 0.18)
				environment_root.add_child(crag)
		"coast_bank":
			for index in range(4):
				var shelf := _box_mesh(Vector3(size.x * 0.22, 0.3, size.z * 0.24), color.lightened(0.08))
				shelf.position = pos + Vector3(-size.x * 0.28 + index * size.x * 0.18, size.y * 0.54, sin(float(index) * 1.6) * size.z * 0.12)
				environment_root.add_child(shelf)
			for index in range(4):
				var bank_post := _box_mesh(Vector3(0.12, size.y * 0.58, 0.12), color.darkened(0.18))
				bank_post.position = pos + Vector3(-size.x * 0.3 + index * size.x * 0.2, size.y * 0.14, size.z * 0.18)
				environment_root.add_child(bank_post)
		"marsh_bank":
			for index in range(4):
				var shelf := _box_mesh(Vector3(size.x * 0.22, 0.3, size.z * 0.24), color.lightened(0.08))
				shelf.position = pos + Vector3(-size.x * 0.28 + index * size.x * 0.18, size.y * 0.54, sin(float(index) * 1.6) * size.z * 0.12)
				environment_root.add_child(shelf)
			for index in range(5):
				var tuft := _box_mesh(Vector3(0.18, size.y * 0.44, 0.18), color.lightened(0.14))
				tuft.position = pos + Vector3(-size.x * 0.32 + index * size.x * 0.16, size.y * 0.08, -size.z * 0.16)
				environment_root.add_child(tuft)
		"thorn_wall":
			for index in range(4):
				var shelf := _box_mesh(Vector3(size.x * 0.22, 0.3, size.z * 0.24), color.lightened(0.08))
				shelf.position = pos + Vector3(-size.x * 0.28 + index * size.x * 0.18, size.y * 0.54, sin(float(index) * 1.6) * size.z * 0.12)
				environment_root.add_child(shelf)
			for index in range(6):
				var thorn := _box_mesh(Vector3(0.08, size.y * 0.48, 0.08), color.darkened(0.2))
				thorn.position = pos + Vector3(-size.x * 0.34 + index * size.x * 0.12, size.y * 0.14, size.z * 0.2)
				thorn.rotation_degrees = Vector3(0.0, 0.0, -18.0 + index * 6.0)
				environment_root.add_child(thorn)
		"causeway_edge":
			for index in range(5):
				var curb := _box_mesh(Vector3(size.x * 0.14, 0.16, size.z * 0.18), color.lightened(0.08))
				curb.position = pos + Vector3(-size.x * 0.3 + index * size.x * 0.16, size.y * 0.42, 0.0)
				environment_root.add_child(curb)
			for side in [-1.0, 1.0]:
				var edge := _box_mesh(Vector3(size.x * 0.86, 0.12, 0.18), color.darkened(0.18))
				edge.position = pos + Vector3(0.0, size.y * 0.42, side * size.z * 0.22)
				environment_root.add_child(edge)
		"root_barrier":
			for index in range(5):
				var rib := _box_mesh(Vector3(size.x * 0.14, 0.18, size.z * 0.18), color.darkened(0.2))
				rib.position = pos + Vector3(-size.x * 0.3 + index * size.x * 0.16, size.y * 0.48, 0.0)
				rib.rotation_degrees = Vector3(0.0, 0.0, -16.0 + index * 8.0)
				environment_root.add_child(rib)
		"rope_break":
			for index in range(5):
				var rope_post := _box_mesh(Vector3(0.14, size.y * 0.58, 0.14), color.darkened(0.22))
				rope_post.position = pos + Vector3(-size.x * 0.32 + index * size.x * 0.16, size.y * 0.14, 0.0)
				environment_root.add_child(rope_post)
			var rope := _box_mesh(Vector3(size.x * 0.84, 0.06, 0.08), color.darkened(0.08))
			rope.position = pos + Vector3(0.0, size.y * 0.44, 0.0)
			environment_root.add_child(rope)
		"totem_fence":
			for index in range(4):
				var totem := _box_mesh(Vector3(0.18, size.y * 0.7, 0.18), color.darkened(0.18))
				totem.position = pos + Vector3(-size.x * 0.28 + index * size.x * 0.2, size.y * 0.1, 0.0)
				environment_root.add_child(totem)
			var rail := _box_mesh(Vector3(size.x * 0.82, 0.08, 0.14), color.lightened(0.08))
			rail.position = pos + Vector3(0.0, size.y * 0.46, 0.0)
			environment_root.add_child(rail)
	_add_static_collider(pos, size)


func _build_visibility_screens() -> void:
	var step_scale := lerpf(1.0, LAYOUT_SPREAD_SCALE, 0.96)
	match current_biome:
		"wetland":
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-18.0, 0.0, 20.0)), 7, Vector3(2.6 * step_scale, 0.0, 0.0), "reed")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(8.0, 0.0, -18.0)), 6, Vector3(2.8 * step_scale, 0.0, 0.0), "reed")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-28.0, 0.0, -8.0)), 5, Vector3(2.2 * step_scale, 0.0, 0.0), "reed_dense")
		"forest":
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-10.0, 0.0, 20.0)), 6, Vector3(3.2 * step_scale, 0.0, 0.0), "tree")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(16.0, 0.0, -18.0)), 5, Vector3(3.4 * step_scale, 0.0, 0.0), "tree")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-22.0, 0.0, -10.0)), 4, Vector3(3.0 * step_scale, 0.0, 0.0), "root_screen")
		"coast":
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-18.0, 0.0, 22.0)), 6, Vector3(3.0 * step_scale, 0.0, 0.0), "dune")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(12.0, 0.0, -20.0)), 5, Vector3(3.4 * step_scale, 0.0, 0.0), "palm")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-26.0, 0.0, 2.0)), 4, Vector3(3.1 * step_scale, 0.0, 0.0), "windbreak")
		_:
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-16.0, 0.0, 22.0)), 7, Vector3(3.0 * step_scale, 0.0, 0.0), "shrub")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(18.0, 0.0, -18.0)), 5, Vector3(3.2 * step_scale, 0.0, 0.0), "rock")
			_add_tall_screen_band(_layout_scaled_pos(Vector3(-24.0, 0.0, -6.0)), 5, Vector3(2.8 * step_scale, 0.0, 0.0), "thorn")


func _add_tall_screen_band(origin: Vector3, count: int, step: Vector3, kind: String) -> void:
	for index in range(count):
		var pos := origin + step * float(index) + Vector3(0.0, 0.0, sin(float(index) * 1.8) * 1.2)
		match kind:
			"reed":
				for offset in [Vector3(-0.6, 0.0, -0.2), Vector3(0.0, 0.0, 0.3), Vector3(0.7, 0.0, -0.1)]:
					var stem := _box_mesh(Vector3(0.24, 2.2, 0.24), current_theme.get("foliage", Color8(106, 144, 92)))
					stem.position = pos + offset + Vector3(0.0, 1.1, 0.0)
					environment_root.add_child(stem)
			"reed_dense":
				for offset in [Vector3(-0.7, 0.0, -0.3), Vector3(-0.2, 0.0, 0.2), Vector3(0.3, 0.0, -0.1), Vector3(0.8, 0.0, 0.25)]:
					var stem := _box_mesh(Vector3(0.2, 2.5, 0.2), current_theme.get("foliage", Color8(106, 144, 92)).darkened(0.04))
					stem.position = pos + offset + Vector3(0.0, 1.24, 0.0)
					environment_root.add_child(stem)
			"tree":
				_add_tree(pos, false)
				_add_tree(pos + Vector3(1.2, 0.0, 0.6), false)
			"root_screen":
				_add_tree(pos, false)
				var rib := _box_mesh(Vector3(1.4, 0.24, 0.22), Color8(86, 70, 54))
				rib.position = pos + Vector3(0.0, 0.18, 0.0)
				rib.rotation_degrees = Vector3(0.0, 0.0, -14.0)
				environment_root.add_child(rib)
			"palm":
				_add_tree(pos, true)
			"dune":
				_add_dune_ridge(pos, 2, Color8(220, 206, 170))
			"windbreak":
				_add_dune_ridge(pos, 2, Color8(214, 198, 154))
				var post := _box_mesh(Vector3(0.14, 1.2, 0.14), Color8(164, 138, 94))
				post.position = pos + Vector3(0.0, 0.6, 0.0)
				environment_root.add_child(post)
			"rock":
				_add_cliff_stack(pos, 2, Color8(132, 118, 88))
			"thorn":
				_add_shrub(pos)
				var thorn := _box_mesh(Vector3(0.08, 1.2, 0.08), Color8(104, 114, 68))
				thorn.position = pos + Vector3(0.0, 0.62, 0.0)
				thorn.rotation_degrees = Vector3(0.0, 0.0, -18.0)
				environment_root.add_child(thorn)
			_:
				_add_shrub(pos)
				_add_shrub(pos + Vector3(0.9, 0.0, 0.5))


func _add_barrier_block(pos: Vector3, size: Vector3, color: Color, alpha: float) -> void:
	var block := MeshInstance3D.new()
	var block_mesh := SphereMesh.new()
	block_mesh.radius = 0.5
	block_mesh.height = 1.0
	block.mesh = block_mesh
	block.scale = Vector3(size.x, maxf(0.12, size.y * 1.18), size.z)
	block.material_override = _material(color, alpha)
	block.position = pos
	environment_root.add_child(block)
	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.5
	cap_mesh.height = 1.0
	cap.mesh = cap_mesh
	cap.scale = Vector3(size.x * 0.88, 0.12, size.z * 0.86)
	cap.material_override = _material(color.lightened(0.12), minf(1.0, alpha + 0.04))
	cap.position = pos + Vector3(0.0, size.y * 0.46, 0.0)
	environment_root.add_child(cap)
	_add_static_collider(pos, size)


func _add_boardwalk(points: Array, color: Color) -> void:
	for index in range(points.size() - 1):
		_add_route_segment(points[index], points[index + 1], color)
		for side in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var post_mesh := BoxMesh.new()
			post_mesh.size = Vector3(0.12, 0.42, 0.12)
			post.mesh = post_mesh
			var p: Vector3 = points[index]
			post.position = p + Vector3(side * 0.8, 0.2, 0.0)
			post.material_override = _material(color.darkened(0.18))
			environment_root.add_child(post)


func _add_fence_line(origin: Vector3, count: int, step: float, color: Color) -> void:
	for index in range(count):
		var base := origin + Vector3(float(index) * step, 0.0, 0.0)
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.12, 1.1, 0.12)
		post.mesh = post_mesh
		post.position = base + Vector3(0.0, 0.55, 0.0)
		post.material_override = _material(color)
		environment_root.add_child(post)
		if index < count - 1:
			var rail := _box_mesh(Vector3(step, 0.08, 0.08), color.lightened(0.08))
			rail.position = base + Vector3(step * 0.5, 0.78, 0.0)
			environment_root.add_child(rail)


func _add_cliff_stack(origin: Vector3, layers: int, color: Color) -> void:
	for index in range(layers):
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.5
		rock_mesh.height = 1.0
		rock.mesh = rock_mesh
		rock.scale = Vector3(2.0 - index * 0.22, 0.52 + index * 0.04, 1.6 - index * 0.16)
		rock.position = origin + Vector3(float(index) * 0.42, 0.22 + index * 0.32, float(index % 2) * 0.22)
		rock.rotation_degrees = Vector3(index * 6.0, index * 18.0, 4.0 if index % 2 == 0 else -6.0)
		rock.material_override = _material(color.darkened(index * 0.04), 0.94)
		environment_root.add_child(rock)


func _add_dune_ridge(origin: Vector3, count: int, color: Color) -> void:
	for index in range(count):
		var dune := MeshInstance3D.new()
		var dune_mesh := SphereMesh.new()
		dune_mesh.radius = 1.0 + float(index % 2) * 0.2
		dune_mesh.height = 1.2 + float(index % 2) * 0.2
		dune.mesh = dune_mesh
		dune.scale = Vector3(1.8, 0.6, 1.0)
		dune.position = origin + Vector3(float(index) * 2.2, 0.36, sin(float(index)) * 0.4)
		dune.material_override = _material(color, 0.82)
		environment_root.add_child(dune)


func _build_boundary_landmarks() -> void:
	var perimeter_color := Color8(132, 108, 76)
	if current_biome == "forest":
		perimeter_color = Color8(84, 102, 74)
	elif current_biome == "wetland":
		perimeter_color = Color8(112, 124, 94)
	elif current_biome == "coast":
		perimeter_color = Color8(170, 158, 126)
	var min_x := current_world_bounds.position.x
	var max_x := current_world_bounds.end.x
	var min_z := current_world_bounds.position.y
	var max_z := current_world_bounds.end.y
	for t in [0.08, 0.24, 0.42, 0.58, 0.76, 0.92]:
		var x := lerpf(min_x, max_x, t)
		_add_boundary_post(Vector3(x, 0.0, min_z), perimeter_color)
		_add_boundary_post(Vector3(x, 0.0, max_z), perimeter_color)
	for t in [0.12, 0.3, 0.5, 0.7, 0.88]:
		var z := lerpf(min_z, max_z, t)
		_add_boundary_post(Vector3(min_x, 0.0, z), perimeter_color)
		_add_boundary_post(Vector3(max_x, 0.0, z), perimeter_color)
	match current_biome:
		"wetland":
			_add_fence_line(_layout_scaled_pos(Vector3(-48.0, 0.0, -34.0)), 6, 3.6 * LAYOUT_SPREAD_SCALE, Color8(110, 126, 98))
			_add_boardwalk([_layout_scaled_pos(Vector3(40.0, 0.1, 22.0)), _layout_scaled_pos(Vector3(48.0, 0.1, 26.0)), _layout_scaled_pos(Vector3(56.0, 0.1, 28.0))], Color8(144, 126, 92))
		"forest":
			_add_cliff_stack(_layout_scaled_pos(Vector3(-46.0, 0.0, -30.0)), 4, Color8(96, 88, 70))
			_add_fence_line(_layout_scaled_pos(Vector3(36.0, 0.0, 30.0)), 5, 3.2 * LAYOUT_SPREAD_SCALE, Color8(88, 78, 60))
		"coast":
			_add_dune_ridge(_layout_scaled_pos(Vector3(-52.0, 0.0, -28.0)), 4, Color8(214, 198, 154))
			_add_fence_line(_layout_scaled_pos(Vector3(38.0, 0.0, 28.0)), 5, 3.4 * LAYOUT_SPREAD_SCALE, Color8(170, 148, 112))
		_:
			_add_cliff_stack(_layout_scaled_pos(Vector3(-50.0, 0.0, -32.0)), 4, Color8(138, 124, 88))
			_add_fence_line(_layout_scaled_pos(Vector3(36.0, 0.0, 30.0)), 5, 3.6 * LAYOUT_SPREAD_SCALE, Color8(132, 108, 76))


func _add_boundary_post(pos: Vector3, color: Color) -> void:
	var scale := lerpf(1.0, _world_spread_scale(), 0.56)
	var root := Node3D.new()
	root.position = pos
	environment_root.add_child(root)
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.16 * scale
	post_mesh.bottom_radius = 0.2 * scale
	post_mesh.height = 1.4
	post.mesh = post_mesh
	post.position = Vector3(0.0, 0.7, 0.0)
	post.material_override = _material(color)
	root.add_child(post)
	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.18 * scale
	cap_mesh.height = 0.36
	cap.mesh = cap_mesh
	cap.position = Vector3(0.0, 1.48, 0.0)
	cap.material_override = _material(color.lightened(0.1))
	root.add_child(cap)


func _build_exit_zones() -> void:
	exit_zones.clear()
	var links: Array = region_detail.get("frontier_links", [])
	for index in range(min(links.size(), current_exit_layouts.size())):
		var link: Dictionary = links[index]
		var layout: Dictionary = current_exit_layouts[index]
		exit_zones.append(
			{
				"id": str(layout.get("id", "")),
				"label": str(link.get("target_name", "下一片区域")),
				"position": layout.get("pos", Vector3.ZERO),
				"hint": "按 E 进入 " + str(link.get("target_name", "下一片区域")),
				"target_region_id": str(link.get("target_region_id", "")),
			}
		)


func _add_exit_threshold(pos: Vector3) -> void:
	var color: Color = current_theme.get("route", Color8(240, 223, 176))
	var scale := _world_spread_scale()
	for step in range(3):
		var threshold := _box_mesh(Vector3((3.6 - step * 0.28) * scale, 0.06, 1.72 * scale), color.lightened(0.05 * step))
		threshold.position = pos + Vector3(0.0, 0.04 + step * 0.02, (-2.2 - step * 1.62) * scale)
		exit_root.add_child(threshold)
	var lane := _box_mesh(Vector3(2.4 * scale, 0.03, 9.2 * scale), color.lightened(0.08))
	lane.position = pos + Vector3(0.0, 0.02, -5.8 * scale)
	exit_root.add_child(lane)
	var spine := _box_mesh(Vector3(0.24 * scale, 0.04, 10.4 * scale), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.12))
	spine.position = pos + Vector3(0.0, 0.05, -6.1 * scale)
	exit_root.add_child(spine)
	var forecourt_pad := _box_mesh(Vector3(4.3 * scale, 0.04, 3.2 * scale), color.lightened(0.12))
	forecourt_pad.position = pos + Vector3(0.0, 0.03, -9.2 * scale)
	exit_root.add_child(forecourt_pad)
	var mid_pad := _box_mesh(Vector3(3.2 * scale, 0.035, 2.2 * scale), color.lightened(0.1))
	mid_pad.position = pos + Vector3(0.0, 0.028, -7.6 * scale)
	exit_root.add_child(mid_pad)
	var forecourt_spine := _box_mesh(Vector3(0.42 * scale, 0.05, 3.5 * scale), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.16))
	forecourt_spine.position = pos + Vector3(0.0, 0.06, -9.4 * scale)
	exit_root.add_child(forecourt_spine)
	for side in [-1.0, 1.0]:
		var apron := _box_mesh(Vector3(0.86 * scale, 0.03, 2.9 * scale), color.darkened(0.1))
		apron.position = pos + Vector3(side * 2.06 * scale, 0.025, -9.1 * scale)
		exit_root.add_child(apron)
		var outer_apron := _box_mesh(Vector3(0.54 * scale, 0.025, 2.4 * scale), color.darkened(0.16))
		outer_apron.position = pos + Vector3(side * 2.72 * scale, 0.02, -9.3 * scale)
		exit_root.add_child(outer_apron)
		var transition_bar := _box_mesh(Vector3(0.2 * scale, 0.08, 2.4 * scale), color.darkened(0.16))
		transition_bar.position = pos + Vector3(side * 1.42 * scale, 0.08, -7.8 * scale)
		exit_root.add_child(transition_bar)
		var transition_post := _box_mesh(Vector3(0.16 * scale, 0.52, 0.16 * scale), Color8(124, 98, 68))
		transition_post.position = pos + Vector3(side * 1.58 * scale, 0.26, -8.8 * scale)
		exit_root.add_child(transition_post)
	for marker_index in range(5):
		var chevron := _box_mesh(Vector3(0.42 * scale, 0.06, 0.22 * scale), current_theme.get("accent", Color8(236, 202, 118)))
		chevron.position = pos + Vector3(0.0, 0.06, (-3.0 - marker_index * 1.18) * scale)
		chevron.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		exit_root.add_child(chevron)
	for light_index in range(7):
		var center_light := _box_mesh(Vector3(0.16 * scale, 0.08, 0.16 * scale), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.18))
		center_light.position = pos + Vector3(0.0, 0.09, (-2.8 - light_index * 1.36) * scale)
		exit_root.add_child(center_light)
	var post_color := Color8(124, 98, 68)
	for side in [-1.0, 1.0]:
		var banner_post := MeshInstance3D.new()
		var banner_mesh := CylinderMesh.new()
		banner_mesh.top_radius = 0.08
		banner_mesh.bottom_radius = 0.1
		banner_mesh.height = 1.3
		banner_post.mesh = banner_mesh
		banner_post.position = pos + Vector3(side * 2.26 * scale, 0.65, -2.1 * scale)
		banner_post.material_override = _material(post_color)
		exit_root.add_child(banner_post)
		for rail_index in range(4):
			var rail := _box_mesh(Vector3(0.1, 0.34, 0.1), post_color.darkened(0.08))
			rail.position = pos + Vector3(side * 1.72 * scale, 0.17, (-2.9 - rail_index * 1.18) * scale)
			exit_root.add_child(rail)
			if rail_index < 3:
				var side_bar := _box_mesh(Vector3(0.08, 0.08, 1.46 * scale), post_color.lightened(0.04))
				side_bar.position = pos + Vector3(side * 1.84 * scale, 0.36, (-3.48 - rail_index * 1.18) * scale)
				exit_root.add_child(side_bar)
		for wing_index in range(5):
			var wing := _box_mesh(Vector3(0.14, 0.14, 1.34 * scale), color.darkened(0.14))
			wing.position = pos + Vector3(side * (2.36 + wing_index * 0.24) * scale, 0.08, (-3.1 - wing_index * 1.34) * scale)
			exit_root.add_child(wing)
		for guide_index in range(5):
			var guide_light := _box_mesh(Vector3(0.12 * scale, 0.12 * scale, 0.12 * scale), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.2))
			guide_light.position = pos + Vector3(side * 2.2 * scale, 0.14, (-3.0 - guide_index * 1.44) * scale)
			exit_root.add_child(guide_light)
		var gate_light := MeshInstance3D.new()
		var gate_light_mesh := SphereMesh.new()
		gate_light_mesh.radius = 0.12
		gate_light_mesh.height = 0.24
		gate_light.mesh = gate_light_mesh
		gate_light.position = pos + Vector3(side * 1.34 * scale, 1.42, -5.2 * scale)
		gate_light.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)), 0.92)
		exit_root.add_child(gate_light)


func _add_arrival_entry_runway(spawn: Vector3, direction: Vector3) -> void:
	var route_color: Color = current_theme.get("route", Color8(240, 223, 176))
	var reentry_profile := _route_stage_reentry_profile()
	var spread_scale := _world_spread_scale()
	var lane_scale := float(reentry_profile.get("lane_scale", 1.0)) * spread_scale
	var merge_scale := float(reentry_profile.get("merge_scale", 1.0)) * lerpf(1.0, spread_scale, 0.8)
	var beacon_scale := float(reentry_profile.get("beacon_scale", 1.0))
	var root := Node3D.new()
	root.position = spawn
	exit_root.add_child(root)
	var lateral := Vector3(direction.z, 0.0, -direction.x).normalized()
	var outer_lane := _box_mesh(Vector3(2.8 * lane_scale, 0.03, 2.8 * lane_scale), route_color.darkened(0.06))
	outer_lane.position = direction * (-4.1 * spread_scale) + Vector3(0.0, 0.02, 0.0)
	root.add_child(outer_lane)
	for index in range(4):
		var slab := _box_mesh(Vector3(2.4 * lane_scale, 0.04, 1.2 * lane_scale), route_color.lightened(0.03 * index))
		slab.position = direction * ((-1.2 - index * 1.14) * spread_scale) + Vector3(0.0, 0.03 + index * 0.01, 0.0)
		root.add_child(slab)
	var inner_lane := _box_mesh(Vector3(3.0 * lane_scale, 0.04, 4.0 * lane_scale), route_color.lightened(0.1))
	inner_lane.position = direction * (1.8 * spread_scale) + Vector3(0.0, 0.03, 0.0)
	root.add_child(inner_lane)
	var merge_lane := _box_mesh(Vector3(4.1 * merge_scale, 0.03, 6.2 * merge_scale), route_color.lightened(0.16))
	merge_lane.position = direction * (6.0 * spread_scale) + Vector3(0.0, 0.025, 0.0)
	root.add_child(merge_lane)
	for step in range(5):
		var merge_chevron := _box_mesh(Vector3(0.44, 0.05, 0.22), current_theme.get("accent", Color8(236, 202, 118)))
		merge_chevron.position = direction * ((2.9 + step * 1.16) * spread_scale) + Vector3(0.0, 0.06, 0.0)
		merge_chevron.rotation_degrees = Vector3(0.0, 45.0, 0.0)
		root.add_child(merge_chevron)
	for side in [-1.0, 1.0]:
		for segment in range(3):
			var guide_post := _box_mesh(Vector3(0.1, 0.72, 0.1), Color8(122, 98, 66))
			guide_post.position = direction * ((0.8 + segment * 1.52) * spread_scale) + lateral * side * ((1.82 + segment * 0.16) * spread_scale) + Vector3(0.0, 0.36, 0.0)
			root.add_child(guide_post)
			var guide_light := MeshInstance3D.new()
			var guide_light_mesh := SphereMesh.new()
			guide_light_mesh.radius = 0.08 * beacon_scale
			guide_light_mesh.height = 0.16 * beacon_scale
			guide_light.mesh = guide_light_mesh
			guide_light.position = guide_post.position + Vector3(0.0, 0.44, 0.0)
			guide_light.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)), 0.92)
			root.add_child(guide_light)
	var sign_pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.07
	pole_mesh.bottom_radius = 0.09
	pole_mesh.height = 1.5
	sign_pole.mesh = pole_mesh
	sign_pole.position = direction * (-1.1 * spread_scale) + Vector3(1.3 * spread_scale, 0.75, 0.0)
	sign_pole.material_override = _material(Color8(118, 92, 62))
	root.add_child(sign_pole)
	var sign_plate := _box_mesh(Vector3(1.2, 0.42, 0.08), current_theme.get("accent", Color8(236, 202, 118)))
	sign_plate.position = sign_pole.position + Vector3(0.0, 0.42, 0.0)
	root.add_child(sign_plate)
	match current_biome:
		"wetland":
			var marsh_frame := _box_mesh(Vector3(2.8, 0.16, 0.32), Color8(126, 104, 72))
			marsh_frame.position = direction * -0.4 + Vector3(0.0, 0.18, 0.0)
			root.add_child(marsh_frame)
			for side in [-1.0, 1.0]:
				var rail := _box_mesh(Vector3(0.08, 0.24, 3.4), Color8(126, 104, 72))
				rail.position = direction * -1.6 + Vector3(side * 1.1, 0.12, 0.0)
				root.add_child(rail)
				var reed := _box_mesh(Vector3(0.18, 0.74, 0.18), current_theme.get("foliage", Color8(106, 144, 92)))
				reed.position = direction * -2.4 + Vector3(side * 1.45, 0.36, 0.7)
				root.add_child(reed)
				var marsh_lamp := _box_mesh(Vector3(0.14, 1.0, 0.14), Color8(112, 90, 64))
				marsh_lamp.position = direction * 2.2 + lateral * side * 1.45 + Vector3(0.0, 0.5, 0.0)
				root.add_child(marsh_lamp)
		"forest":
			var root_gate := _box_mesh(Vector3(3.2, 0.18, 0.4), Color8(88, 70, 48))
			root_gate.position = direction * -0.6 + Vector3(0.0, 0.22, 0.0)
			root.add_child(root_gate)
			for side in [-1.0, 1.0]:
				var trunk := _box_mesh(Vector3(0.28, 1.4, 0.28), Color8(102, 74, 48))
				trunk.position = direction * -2.0 + Vector3(side * 1.55, 0.7, 0.5)
				root.add_child(trunk)
				var canopy := _box_mesh(Vector3(0.96, 0.56, 0.96), current_theme.get("foliage", Color8(64, 96, 64)))
				canopy.position = trunk.position + Vector3(0.0, 0.9, 0.0)
				root.add_child(canopy)
				var lantern := _box_mesh(Vector3(0.18, 0.42, 0.18), current_theme.get("accent", Color8(236, 202, 118)))
				lantern.position = direction * 1.9 + lateral * side * 1.22 + Vector3(0.0, 0.88, 0.2)
				root.add_child(lantern)
		"coast":
			var coast_crossbeam := _box_mesh(Vector3(2.9, 0.14, 0.28), Color8(164, 138, 94))
			coast_crossbeam.position = direction * -0.8 + Vector3(0.0, 0.16, 0.0)
			root.add_child(coast_crossbeam)
			for side in [-1.0, 1.0]:
				var dune := _box_mesh(Vector3(1.1, 0.26, 1.6), Color8(224, 214, 180))
				dune.position = direction * -1.8 + Vector3(side * 1.5, 0.12, 0.4)
				root.add_child(dune)
				var post := _box_mesh(Vector3(0.12, 0.92, 0.12), Color8(156, 126, 88))
				post.position = direction * -3.0 + Vector3(side * 1.2, 0.46, -0.2)
				root.add_child(post)
				var surf_post := _box_mesh(Vector3(0.12, 0.76, 0.12), Color8(168, 132, 88))
				surf_post.position = direction * 2.6 + lateral * side * 1.36 + Vector3(0.0, 0.38, -0.2)
				root.add_child(surf_post)
		_:
			var prairie_frame := _box_mesh(Vector3(2.8, 0.16, 0.3), Color8(144, 126, 88))
			prairie_frame.position = direction * -0.5 + Vector3(0.0, 0.16, 0.0)
			root.add_child(prairie_frame)
			for side in [-1.0, 1.0]:
				var cairn := _box_mesh(Vector3(0.72, 0.28, 0.72), Color8(144, 126, 88))
				cairn.position = direction * -2.1 + Vector3(side * 1.4, 0.14, 0.2)
				root.add_child(cairn)
				var stake := _box_mesh(Vector3(0.1, 0.8, 0.1), Color8(122, 98, 66))
				stake.position = direction * -3.0 + Vector3(side * 1.1, 0.4, -0.6)
				root.add_child(stake)
				var torch_stake := _box_mesh(Vector3(0.12, 0.9, 0.12), Color8(132, 104, 68))
				torch_stake.position = direction * 2.4 + lateral * side * 1.3 + Vector3(0.0, 0.45, 0.1)
				root.add_child(torch_stake)


func _build_wildlife() -> void:
	_clear_children(wildlife_root)
	wildlife.clear()
	var capped_manifest := species_manifest.slice(0, min(species_manifest.size(), 24))
	var spawn3 := Vector3(current_layout.get("spawn", Vector3.ZERO))
	var spawn2 := Vector2(spawn3.x, spawn3.z)
	for index in range(capped_manifest.size()):
		var entry: Dictionary = capped_manifest[index]
		var species_id := str(entry.get("species_id", ""))
		var species_scene_path := _species_asset_scene_path(species_id)
		if not _is_imported_visual_scene_path(species_scene_path):
			continue
		var category := str(entry.get("category", "区域生物"))
		var dynamic_cluster := _dynamic_cluster_profile(category)
		var anchor_id := _anchor_for_species(species_id)
		var anchor3 := _hotspot_pos(anchor_id)
		var group_size := _group_size_for_species(species_id, category, int(entry.get("count", 0)))
		group_size = int(clampi(roundi(group_size * float(dynamic_cluster.get("group_scale", 1.0))), 1, 8))
		var role := "member"
		if category == "草食动物" and group_size >= 4:
			role = "leader"
		elif category == "飞行动物":
			role = "sentry"
		elif category == "掠食者":
			role = "alpha"
		var animal_root := Node3D.new()
		animal_root.name = str(entry.get("species_id", "wildlife_%d" % index))
		wildlife_root.add_child(animal_root)
		var member_root := Node3D.new()
		member_root.name = "Members"
		animal_root.add_child(member_root)
		var marker_root := Node3D.new()
		marker_root.name = "Marker"
		marker_root.visible = false
		animal_root.add_child(marker_root)
		var marker_color: Color = CATEGORY_COLORS.get(category, Color8(174, 191, 126))
		var marker_ring := MeshInstance3D.new()
		var marker_ring_mesh := CylinderMesh.new()
		marker_ring_mesh.top_radius = 0.42 if category != "掠食者" else 0.34
		marker_ring_mesh.bottom_radius = 0.58 if category != "掠食者" else 0.68
		marker_ring_mesh.height = 0.04
		marker_ring.mesh = marker_ring_mesh
		marker_ring.position = Vector3(0.0, 0.03, 0.0)
		marker_ring.material_override = _material(marker_color.lightened(0.12), 0.28)
		marker_root.add_child(marker_ring)
		var marker_beacon := MeshInstance3D.new()
		var marker_beacon_mesh: PrimitiveMesh
		match category:
			"掠食者":
				var mesh := CylinderMesh.new()
				mesh.top_radius = 0.08 if role != "alpha" else 0.1
				mesh.bottom_radius = 0.14 if role != "alpha" else 0.18
				mesh.height = 0.4 if role != "alpha" else 0.54
				marker_beacon_mesh = mesh
			"飞行动物":
				var mesh := SphereMesh.new()
				mesh.radius = 0.1 if role != "sentry" else 0.12
				mesh.height = 0.2 if role != "sentry" else 0.24
				marker_beacon_mesh = mesh
			"草食动物":
				var mesh := BoxMesh.new()
				mesh.size = Vector3(0.18, 0.18, 0.18) if role != "leader" else Vector3(0.24, 0.22, 0.24)
				marker_beacon_mesh = mesh
			_:
				var mesh := SphereMesh.new()
				mesh.radius = 0.12
				mesh.height = 0.26
				marker_beacon_mesh = mesh
		marker_beacon.mesh = marker_beacon_mesh
		marker_beacon.position = Vector3(0.0, 1.34 if category != "飞行动物" else 1.48, 0.0)
		marker_beacon.material_override = _material(marker_color.lightened(0.18), 0.78)
		marker_root.add_child(marker_beacon)
		for member_index in range(group_size):
			member_root.add_child(_make_animal_member(species_id, category, member_index == 0))
		var initial_position := Vector2(anchor3.x, anchor3.z)
		var radius_scale := 1.0
		if index < 6:
			var entry_bias := clampf(0.34 + float(index) * 0.08, 0.34, 0.78)
			initial_position = spawn2.lerp(initial_position, entry_bias)
			var entry_dir := (initial_position - spawn2).normalized()
			if entry_dir == Vector2.ZERO:
				entry_dir = Vector2.RIGHT
			var entry_lateral := Vector2(-entry_dir.y, entry_dir.x)
			var fan_t := (-1.0 + float(index) / 5.0 * 2.0) if index < 5 else 0.0
			initial_position += entry_lateral * fan_t * (3.4 + float(index) * 0.68) * REGION_DISTANCE_SCALE
			initial_position += entry_dir * (1.2 + float(index) * 0.42) * REGION_DISTANCE_SCALE
		if index < 4:
			var scout_bias := clampf(0.2 + float(index) * 0.09, 0.2, 0.5)
			initial_position = spawn2.lerp(initial_position, scout_bias)
			var scout_dir := (initial_position - spawn2).normalized()
			if scout_dir == Vector2.ZERO:
				scout_dir = Vector2.RIGHT
			var scout_lateral := Vector2(-scout_dir.y, scout_dir.x)
			var scout_fan := -0.9 + float(index) / 3.0 * 1.8
			initial_position += scout_lateral * scout_fan * (3.1 + float(index) * 0.84) * REGION_DISTANCE_SCALE
			initial_position += scout_dir * (1.7 + float(index) * 0.68) * REGION_DISTANCE_SCALE
			radius_scale = 0.74
		elif index < 8:
			radius_scale = 0.9
		wildlife.append(
			{
				"species_id": str(entry.get("species_id", "")),
				"scene_path": species_scene_path,
				"label": str(entry.get("label", entry.get("species_id", ""))),
				"count": int(entry.get("count", 0)),
				"category": category,
				"anchor_id": anchor_id,
				"anchor": Vector2(anchor3.x, anchor3.z),
				"radius": _wildlife_radius_for(index, species_id, category) * float(dynamic_cluster.get("spread_scale", 1.0)) * radius_scale,
				"phase": float(index) * 0.72,
				"speed": _wildlife_speed_for(index, species_id, category),
				"position": initial_position,
				"route_points": _wildlife_route_points(species_id, anchor_id, category, _behavior_for_species(species_id, category)),
				"route_index": index % 3,
				"group_size": group_size,
				"behavior": _behavior_for_species(species_id, category),
				"role": role,
				"alert_radius": _wildlife_alert_radius_for(index, species_id, category, role),
				"alerted": false,
				"look_back": false,
				"regrouping": false,
				"alert_timer": 0.0,
				"pause_timer": 0.0,
				"signal_timer": 0.0,
				"heading": 0.0,
				"node": animal_root,
				"member_root": member_root,
				"marker_root": marker_root,
				"marker_ring": marker_ring,
				"marker_beacon": marker_beacon,
			}
		)


func _physics_process(delta: float) -> void:
	_update_arrival_event_focus_timer(delta)
	_update_player(delta)
	_update_wildlife(delta)
	_update_camera(false)
	_update_encounter()
	_update_hotspot_focus(delta)
	_update_exit_zone()
	_update_route_stage()
	_update_biome_ambient_cues()
	_update_gate_transition(delta)
	_update_arrival_intro(delta)
	_update_event_focus()
	_build_aftermath_visuals()
	_update_spatial_visibility()
	_update_transition_overlay(delta)
	_refresh_ui()


func _input(event: InputEvent) -> void:
	_handle_input_event(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle_input_event(event)


func _handle_input_event(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0):
		camera_yaw_velocity += -event.relative.x * CAMERA_MOUSE_SENSITIVITY * CAMERA_TURN_RESPONSE
		camera_pitch_velocity += -event.relative.y * (CAMERA_MOUSE_SENSITIVITY * 0.72) * CAMERA_TURN_RESPONSE
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_zoom_target = clampf(camera_zoom_target - CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_zoom_target = clampf(camera_zoom_target + CAMERA_ZOOM_STEP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			show_codex = not show_codex
			codex_panel.visible = show_codex
		elif event.keycode == KEY_M:
			get_tree().change_scene_to_file(WORLD_MAP_SCENE)
		elif event.keycode == KEY_E and not current_exit_zone.is_empty():
			var target_region_id := str(current_exit_zone.get("target_region_id", ""))
			if target_region_id != "":
				var exit_profile := _biome_exit_profile()
				var gate_id := str(current_exit_zone.get("id", ""))
				var gate_dir := _gate_forward_vector(gate_id)
				pending_gate_transition = {
					"target_region_id": target_region_id,
					"gate_id": gate_id,
					"label": str(current_exit_zone.get("label", "下一片区域")),
					"timer": float(exit_profile.get("gate_duration", 1.18)),
					"duration": float(exit_profile.get("gate_duration", 1.18)),
					"direction": gate_dir,
					"start_position": player_body.global_position,
					"gate_position": Vector3(current_exit_zone.get("position", Vector3.ZERO)),
					"end_position": Vector3(current_exit_zone.get("position", Vector3.ZERO)) + gate_dir * 3.1,
				}
				transition_restore_codex = show_codex
				show_codex = false
				codex_panel.visible = false
				_start_region_transition(str(current_exit_zone.get("label", "下一片区域")), "路线切换中", true)


func _update_player(delta: float) -> void:
	if camera_node == null or player_body == null or player_visual == null or player_shadow == null:
		return
	var motion_profile := _biome_player_motion_profile()
	var stage_motion := _route_stage_motion_profile()
	if not pending_gate_transition.is_empty():
		smoothed_gate_focus_hold = 0.0
		var reentry_profile := _route_stage_reentry_profile()
		player_body.velocity = Vector3.ZERO
		var duration := maxf(0.001, float(pending_gate_transition.get("duration", 1.0)))
		var timer := float(pending_gate_transition.get("timer", 0.0))
		var progress := clampf(1.0 - timer / duration, 0.0, 1.0)
		var start_position := Vector3(pending_gate_transition.get("start_position", player_body.global_position))
		var gate_position := Vector3(pending_gate_transition.get("gate_position", start_position))
		var end_position := Vector3(pending_gate_transition.get("end_position", gate_position))
		var direction := Vector3(pending_gate_transition.get("direction", Vector3(0.0, 0.0, -1.0)))
		var gate_progress := ease(progress, -1.35)
		var path_mid := start_position.lerp(gate_position, clampf(gate_progress * 1.2, 0.0, 1.0))
		var path_target := path_mid.lerp(end_position, clampf((gate_progress - 0.52) / 0.48, 0.0, 1.0))
		path_target.y = _ground_contact_height_at(path_target.x, path_target.z) + PLAYER_BODY_GROUND_HEIGHT
		player_body.global_position = player_body.global_position.lerp(path_target, float(reentry_profile.get("gate_move_lerp", 0.28)))
		player_visual.rotation.y = lerp_angle(player_visual.rotation.y, atan2(direction.x, direction.z), 0.22)
		var passage_stride := sin(elapsed_time() * 9.2) * 0.48
		player_visual.position.y = lerpf(player_visual.position.y, PLAYER_VISUAL_BASE_Y + 0.04 + sin(progress * PI) * 0.08, 0.2)
		if player_arm_left != null:
			player_arm_left.rotation.x = lerpf(player_arm_left.rotation.x, passage_stride, 0.24)
		if player_arm_right != null:
			player_arm_right.rotation.x = lerpf(player_arm_right.rotation.x, -passage_stride, 0.24)
		if player_leg_left != null:
			player_leg_left.rotation.x = lerpf(player_leg_left.rotation.x, -passage_stride * 0.92, 0.24)
		if player_leg_right != null:
			player_leg_right.rotation.x = lerpf(player_leg_right.rotation.x, passage_stride * 0.92, 0.24)
		player_shadow.scale = player_shadow.scale.lerp(Vector3(1.06, 1.0, 1.06), 0.14)
		return
	if not pending_arrival_intro.is_empty():
		smoothed_gate_focus_hold = 0.0
		var reentry_profile := _route_stage_reentry_profile()
		player_body.velocity = Vector3.ZERO
		var duration := maxf(0.001, float(pending_arrival_intro.get("duration", 1.0)))
		var timer := float(pending_arrival_intro.get("timer", 0.0))
		var progress := clampf(1.0 - timer / duration, 0.0, 1.0)
		var start_position := Vector3(pending_arrival_intro.get("start_position", player_body.global_position))
		var end_position := Vector3(pending_arrival_intro.get("end_position", start_position))
		var direction := Vector3(pending_arrival_intro.get("direction", Vector3(0.0, 0.0, 1.0)))
		var arrival_target := start_position.lerp(end_position, ease(progress, -1.25))
		arrival_target.y = _ground_contact_height_at(arrival_target.x, arrival_target.z) + PLAYER_BODY_GROUND_HEIGHT
		player_body.global_position = player_body.global_position.lerp(arrival_target, float(reentry_profile.get("arrival_move_lerp", 0.3)))
		player_visual.rotation.y = lerp_angle(player_visual.rotation.y, atan2(direction.x, direction.z), 0.18)
		var arrival_stride := sin(elapsed_time() * 7.4) * 0.34
		player_visual.position.y = lerpf(player_visual.position.y, PLAYER_VISUAL_BASE_Y + 0.03 + sin(progress * PI) * 0.05, 0.18)
		if player_arm_left != null:
			player_arm_left.rotation.x = lerpf(player_arm_left.rotation.x, arrival_stride, 0.22)
		if player_arm_right != null:
			player_arm_right.rotation.x = lerpf(player_arm_right.rotation.x, -arrival_stride, 0.22)
		if player_leg_left != null:
			player_leg_left.rotation.x = lerpf(player_leg_left.rotation.x, -arrival_stride * 0.88, 0.22)
		if player_leg_right != null:
			player_leg_right.rotation.x = lerpf(player_leg_right.rotation.x, arrival_stride * 0.88, 0.22)
		player_shadow.scale = player_shadow.scale.lerp(Vector3(1.04, 1.0, 1.04), 0.12)
		return
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		input_vector.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		input_vector.y -= 1.0
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	var sprint_multiplier := SPRINT_MULTIPLIER * float(motion_profile.get("sprint_scale", 1.0)) * float(stage_motion.get("sprint_scale", 1.0))
	var camera_turn_input := 0.0
	if Input.is_key_pressed(KEY_Q):
		camera_turn_input -= 1.0
	if Input.is_key_pressed(KEY_R):
		camera_turn_input += 1.0
	camera_yaw_velocity += camera_turn_input * CAMERA_KEYBOARD_TURN_SPEED
	_update_camera_rotation(delta)
	var target_speed_ratio := 0.0 if input_vector == Vector2.ZERO else (1.0 if not sprinting else sprint_multiplier)
	current_speed_ratio = lerpf(current_speed_ratio, target_speed_ratio, float(motion_profile.get("speed_blend", 0.12)) * float(stage_motion.get("speed_blend_scale", 1.0)))
	movement_blend = lerpf(movement_blend, 1.0 if input_vector != Vector2.ZERO else 0.0, float(motion_profile.get("movement_blend", 0.14)) * float(stage_motion.get("movement_blend_scale", 1.0)))
	var speed := PLAYER_SPEED * float(motion_profile.get("base_speed_scale", 1.0)) * float(stage_motion.get("base_speed_scale", 1.0)) * (sprint_multiplier if sprinting else 1.0)
	var cam_forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var cam_right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	var move_dir := (cam_right * input_vector.x + cam_forward * input_vector.y).normalized()
	player_body.velocity.x = move_dir.x * speed
	player_body.velocity.z = move_dir.z * speed
	player_body.velocity.y = -4.0
	player_body.move_and_slide()
	var world_padding := 2.6 * REGION_DISTANCE_SCALE
	player_body.global_position.x = clampf(player_body.global_position.x, current_world_bounds.position.x + world_padding, current_world_bounds.end.x - world_padding)
	player_body.global_position.z = clampf(player_body.global_position.z, current_world_bounds.position.y + world_padding, current_world_bounds.end.y - world_padding)
	var desired_ground_y := _ground_contact_height_at(player_body.global_position.x, player_body.global_position.z) + PLAYER_BODY_GROUND_HEIGHT
	player_body.global_position.y = lerpf(player_body.global_position.y, desired_ground_y, 0.22)
	if move_dir.length() > 0.0:
		player_visual.rotation.y = lerp_angle(player_visual.rotation.y, atan2(move_dir.x, move_dir.z), float(motion_profile.get("turn_lerp", 0.18)) * float(stage_motion.get("turn_lerp_scale", 1.0)))
		var bob_height := (0.05 + 0.025 * current_speed_ratio) * float(motion_profile.get("bob_scale", 1.0)) * float(stage_motion.get("bob_scale", 1.0))
		var bob_speed := (9.0 + current_speed_ratio * 4.8) * float(motion_profile.get("bob_speed_scale", 1.0)) * float(stage_motion.get("bob_speed_scale", 1.0))
		player_visual.position.y = lerpf(player_visual.position.y, PLAYER_VISUAL_BASE_Y + 0.06 + sin(elapsed_time() * bob_speed) * bob_height, float(motion_profile.get("pose_lerp", 0.24)) * float(stage_motion.get("pose_lerp_scale", 1.0)))
		player_visual.rotation.z = lerpf(player_visual.rotation.z, -input_vector.x * 0.06 * float(motion_profile.get("tilt_scale", 1.0)) * float(stage_motion.get("tilt_scale", 1.0)), float(motion_profile.get("turn_lerp", 0.18)) * float(stage_motion.get("turn_lerp_scale", 1.0)))
		var stride := sin(elapsed_time() * ((8.0 + current_speed_ratio * 4.2) * float(motion_profile.get("stride_speed_scale", 1.0)) * float(stage_motion.get("stride_speed_scale", 1.0)))) * 0.7 * movement_blend * float(motion_profile.get("stride_scale", 1.0)) * float(stage_motion.get("stride_scale", 1.0))
		if player_arm_left != null:
			player_arm_left.rotation.x = lerpf(player_arm_left.rotation.x, stride, float(motion_profile.get("limb_lerp", 0.22)) * float(stage_motion.get("limb_lerp_scale", 1.0)))
		if player_arm_right != null:
			player_arm_right.rotation.x = lerpf(player_arm_right.rotation.x, -stride, float(motion_profile.get("limb_lerp", 0.22)) * float(stage_motion.get("limb_lerp_scale", 1.0)))
		if player_leg_left != null:
			player_leg_left.rotation.x = lerpf(player_leg_left.rotation.x, -stride * 0.9, float(motion_profile.get("limb_lerp", 0.24)) * float(stage_motion.get("limb_lerp_scale", 1.0)))
		if player_leg_right != null:
			player_leg_right.rotation.x = lerpf(player_leg_right.rotation.x, stride * 0.9, float(motion_profile.get("limb_lerp", 0.24)) * float(stage_motion.get("limb_lerp_scale", 1.0)))
		player_shadow.scale = player_shadow.scale.lerp(Vector3(1.0 + 0.08 * movement_blend * float(motion_profile.get("shadow_scale", 1.0)) * float(stage_motion.get("shadow_scale", 1.0)), 1.0, 1.0 + 0.08 * movement_blend * float(motion_profile.get("shadow_scale", 1.0)) * float(stage_motion.get("shadow_scale", 1.0))), 0.12)
	else:
		player_visual.position.y = lerpf(player_visual.position.y, PLAYER_VISUAL_BASE_Y, float(motion_profile.get("idle_pose_lerp", 0.18)) * float(stage_motion.get("idle_pose_lerp_scale", 1.0)))
		player_visual.rotation.z = lerpf(player_visual.rotation.z, 0.0, float(motion_profile.get("idle_turn_lerp", 0.14)) * float(stage_motion.get("idle_turn_lerp_scale", 1.0)))
		if player_arm_left != null:
			player_arm_left.rotation.x = lerpf(player_arm_left.rotation.x, 0.0, float(motion_profile.get("idle_limb_lerp", 0.18)) * float(stage_motion.get("idle_limb_lerp_scale", 1.0)))
		if player_arm_right != null:
			player_arm_right.rotation.x = lerpf(player_arm_right.rotation.x, 0.0, float(motion_profile.get("idle_limb_lerp", 0.18)) * float(stage_motion.get("idle_limb_lerp_scale", 1.0)))
		if player_leg_left != null:
			player_leg_left.rotation.x = lerpf(player_leg_left.rotation.x, 0.0, float(motion_profile.get("idle_limb_lerp", 0.18)) * float(stage_motion.get("idle_limb_lerp_scale", 1.0)))
		if player_leg_right != null:
			player_leg_right.rotation.x = lerpf(player_leg_right.rotation.x, 0.0, float(motion_profile.get("idle_limb_lerp", 0.18)) * float(stage_motion.get("idle_limb_lerp_scale", 1.0)))
		player_shadow.scale = player_shadow.scale.lerp(Vector3.ONE, 0.12)


func _update_camera_rotation(delta: float) -> void:
	camera_yaw_velocity = clampf(camera_yaw_velocity, -CAMERA_YAW_MAX_SPEED, CAMERA_YAW_MAX_SPEED)
	camera_pitch_velocity = clampf(camera_pitch_velocity, -CAMERA_PITCH_MAX_SPEED, CAMERA_PITCH_MAX_SPEED)
	camera_yaw += camera_yaw_velocity * delta
	camera_pitch = clampf(camera_pitch + camera_pitch_velocity * delta, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
	var damping := clampf(delta * CAMERA_TURN_DAMPING, 0.0, 1.0)
	camera_yaw_velocity = lerpf(camera_yaw_velocity, 0.0, damping)
	camera_pitch_velocity = lerpf(camera_pitch_velocity, 0.0, damping)


func _update_wildlife(delta: float) -> void:
	if not chase_aftermath.is_empty():
		var aftermath_timer := maxf(0.0, float(chase_aftermath.get("timer", 0.0)) - delta)
		chase_aftermath["timer"] = aftermath_timer
		if aftermath_timer <= 0.0:
			chase_aftermath.clear()
	var aftermath_ratio := 0.0
	var chase_profile := _biome_chase_chain_profile()
	var stage_ecology := _route_stage_ecology_profile()
	var chase_state := _dynamic_chase_state()
	var pressure_window_profile := _dynamic_hotspot_window(str(chase_state.get("pressure_hotspot", "predator_ridge")))
	var aftermath_window_profile := _dynamic_hotspot_window(str(chase_state.get("aftermath_hotspot", "carrion_field")))
	var migration_window_profile := _dynamic_hotspot_window(str(chase_state.get("migration_hotspot", "migration_corridor")))
	var arrival_pressure_boost := _arrival_recommended_focus_boost("pressure")
	var arrival_aftermath_boost := _arrival_recommended_focus_boost("aftermath")
	var terminal_scale := _recommended_terminal_scale()
	var terminal_focus := current_route_stage == "terminal" or (arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"])
	var herd_pull_scale := float(chase_profile.get("herd_pull_scale", 1.0)) * float(stage_ecology.get("herd_pull_scale", 1.0))
	var glide_pull_scale := float(chase_profile.get("glide_pull_scale", 1.0)) * float(stage_ecology.get("glide_pull_scale", 1.0))
	var predator_pull_scale := float(chase_profile.get("predator_pull_scale", 1.0)) * float(stage_ecology.get("predator_pull_scale", 1.0))
	var aftermath_duration := maxf(0.001, float(chase_profile.get("aftermath_duration", 4.2)) * float(stage_ecology.get("aftermath_duration_scale", 1.0)))
	var pressure_distance := float(chase_profile.get("pressure_distance", 7.8)) * float(stage_ecology.get("pressure_scale", 1.0))
	var hit_distance := float(chase_profile.get("hit_distance", 1.2)) * float(stage_ecology.get("hit_scale", 1.0))
	var burst_distance := float(chase_profile.get("burst_distance", 3.4)) * float(stage_ecology.get("burst_distance_scale", 1.0))
	var burst_timeout := float(chase_profile.get("burst_timeout", 3.0)) * float(stage_ecology.get("burst_timeout_scale", 1.0))
	var alpha_push_scale := float(chase_profile.get("alpha_push_scale", 1.0)) * float(stage_ecology.get("alpha_push_scale", 1.0))
	var stalk_site_scale := float(chase_profile.get("stalk_site_scale", 1.0)) * float(stage_ecology.get("aftermath_pull_scale", 1.0))
	var glide_site_scale := float(chase_profile.get("glide_site_scale", 1.0)) * float(stage_ecology.get("aftermath_pull_scale", 1.0))
	var stalk_player_radius := float(chase_profile.get("stalk_player_radius", 8.0)) * float(stage_ecology.get("player_radius_scale", 1.0))
	var glide_pressure_radius := float(chase_profile.get("glide_pressure_radius", 10.0)) * float(stage_ecology.get("pressure_scale", 1.0))
	var chase_score_scale := float(chase_profile.get("chase_score_scale", 1.0)) * float(stage_ecology.get("pressure_scale", 1.0))
	var graze_player_radius := float(chase_profile.get("graze_player_radius", 6.0)) * float(stage_ecology.get("player_radius_scale", 1.0))
	var swim_player_radius := float(chase_profile.get("swim_player_radius", 6.4)) * float(stage_ecology.get("player_radius_scale", 1.0))
	var heavy_player_radius := float(chase_profile.get("heavy_player_radius", 6.8)) * float(stage_ecology.get("player_radius_scale", 1.0))
	var herd_signal_scale := float(chase_profile.get("herd_signal_scale", 1.0)) * float(stage_ecology.get("herd_signal_scale", 1.0))
	var sentry_signal_scale := float(chase_profile.get("sentry_signal_scale", 1.0)) * float(stage_ecology.get("sentry_signal_scale", 1.0))
	var regroup_scale := float(chase_profile.get("regroup_scale", 1.0)) * float(stage_ecology.get("regroup_scale", 1.0))
	var flee_scale := float(chase_profile.get("flee_scale", 1.0)) * float(stage_ecology.get("flee_scale", 1.0))
	pressure_distance *= float(pressure_window_profile.get("active_scale", 1.0))
	burst_distance *= float(pressure_window_profile.get("active_scale", 1.0))
	burst_timeout *= lerpf(0.92, 1.14, clampf(float(pressure_window_profile.get("task_scale", 1.0)) - 1.0, 0.0, 0.3) / 0.3)
	chase_score_scale *= float(pressure_window_profile.get("active_scale", 1.0))
	hit_distance *= float(pressure_window_profile.get("task_scale", 1.0))
	aftermath_duration *= float(aftermath_window_profile.get("active_scale", 1.0))
	glide_pull_scale *= float(aftermath_window_profile.get("active_scale", 1.0))
	predator_pull_scale *= float(aftermath_window_profile.get("active_scale", 1.0))
	herd_pull_scale *= float(migration_window_profile.get("active_scale", 1.0))
	regroup_scale *= float(migration_window_profile.get("task_scale", 1.0))
	pressure_distance *= arrival_pressure_boost
	burst_distance *= arrival_pressure_boost
	chase_score_scale *= arrival_pressure_boost
	hit_distance *= arrival_pressure_boost
	burst_timeout /= maxf(0.82, lerpf(1.0, 1.12, clampf(arrival_pressure_boost - 1.0, 0.0, 0.2) / 0.2))
	aftermath_duration *= arrival_aftermath_boost
	glide_pull_scale *= arrival_aftermath_boost
	predator_pull_scale *= arrival_aftermath_boost
	if terminal_focus:
		match _stage_shell_focus_band("terminal"):
			"pressure":
				pressure_distance = _terminal_scale_adjust(pressure_distance)
				burst_distance = _terminal_scale_adjust(burst_distance)
				hit_distance = _terminal_scale_adjust(hit_distance)
				chase_score_scale = _terminal_scale_adjust(chase_score_scale)
				burst_timeout /= maxf(0.82, terminal_scale)
			"aftermath":
				aftermath_duration = _terminal_scale_adjust(aftermath_duration)
				glide_pull_scale = _terminal_scale_adjust(glide_pull_scale)
				predator_pull_scale = _terminal_scale_adjust(predator_pull_scale)
			"exit":
				pressure_distance = lerpf(pressure_distance, pressure_distance * 0.94, minf(1.0, terminal_scale - 1.0))
				burst_distance = lerpf(burst_distance, burst_distance * 0.94, minf(1.0, terminal_scale - 1.0))
				aftermath_duration = _terminal_scale_adjust(aftermath_duration)
	if not chase_aftermath.is_empty():
		var active_duration := maxf(0.001, float(chase_aftermath.get("duration", aftermath_duration)))
		aftermath_ratio = clampf(float(chase_aftermath.get("timer", 0.0)) / active_duration, 0.0, 1.0)
	var herd_focus := _herd_center()
	var prey_positions := _prey_positions()
	var strongest_pressure: Dictionary = {}
	var strongest_chase: Dictionary = {}
	var carrion_focus := _hotspot_pos("carrion_field")
	var herd_route_focus := _biome_herd_route_focus()
	var sentry_watch_focus := _biome_sentry_watch_focus()
	var glide_after_focus := _biome_glide_aftermath_focus()
	var predator_after_focus := _biome_predator_aftermath_focus()
	var recent_pressure_target := Vector2.ZERO
	if not current_chase.is_empty():
		recent_pressure_target = current_chase.get("target", Vector2.ZERO)
	var recent_chase_site := recent_pressure_target
	if not current_chase_result.is_empty() and current_chase_result.has("target"):
		recent_chase_site = current_chase_result.get("target", recent_chase_site)
	elif not chase_aftermath.is_empty():
		recent_chase_site = chase_aftermath.get("target", recent_chase_site)
	var recent_chase_result := not current_chase_result.is_empty()
	var aftermath_active := not chase_aftermath.is_empty()
	if aftermath_active:
		recent_chase_result = true
	for index in range(wildlife.size()):
		var animal: Dictionary = wildlife[index]
		var anchor: Vector2 = animal.get("anchor", Vector2.ZERO)
		var radius: Vector2 = animal.get("radius", Vector2(4.0, 2.4))
		var current_pos: Vector2 = animal.get("position", anchor)
		var phase := float(animal.get("phase", 0.0))
		var speed := float(animal.get("speed", 0.4))
		var alert_timer := maxf(0.0, float(animal.get("alert_timer", 0.0)) - delta)
		var pause_timer := maxf(0.0, float(animal.get("pause_timer", 0.0)) - delta)
		var signal_timer := maxf(0.0, float(animal.get("signal_timer", 0.0)) - delta)
		var angle := elapsed_time() * speed + phase
		var base_pos := anchor + Vector2(cos(angle) * radius.x, sin(angle * 1.2) * radius.y)
		var player_delta := base_pos - _player_vec2()
		var player_distance := player_delta.length()
		var behavior := str(animal.get("behavior", "graze"))
		var category := str(animal.get("category", "区域生物"))
		var role := str(animal.get("role", "member"))
		var anchor_id := str(animal.get("anchor_id", ""))
		var route_points: Array = animal.get("route_points", [])
		var route_index := int(animal.get("route_index", 0))
		var alerted := false
		var look_back := false
		var regrouping := false
		var escort_target := Vector2.ZERO
		var route_wander := Vector2(cos(angle * 0.78) * radius.x * 0.36, sin(angle * 0.96) * radius.y * 0.28)
		if not route_points.is_empty():
			route_index = posmod(route_index, route_points.size())
			var patrol_target := Vector2(route_points[route_index])
			var route_threshold := maxf(6.2, radius.length() * 0.34)
			if current_pos.distance_to(patrol_target) < route_threshold:
				route_index = (route_index + 1) % route_points.size()
				patrol_target = Vector2(route_points[route_index])
			base_pos = current_pos.lerp(patrol_target + route_wander, 0.08)
		else:
			base_pos = anchor + route_wander
		base_pos = base_pos.lerp(_behavior_bias_target(animal, phase), 0.022)
		if role == "leader" and behavior in ["graze", "heavy_roam"]:
			base_pos = base_pos.lerp(herd_route_focus, 0.016)
			if recent_chase_site != Vector2.ZERO and base_pos.distance_to(recent_chase_site) < 16.0:
				base_pos = base_pos.lerp(herd_route_focus, (0.08 if not aftermath_active else 0.11) * herd_pull_scale)
				signal_timer = maxf(signal_timer, 0.92 if not aftermath_active else 1.18)
				alert_timer = maxf(alert_timer, 1.04 if not aftermath_active else 1.26)
		elif role == "sentry":
			base_pos = base_pos.lerp(sentry_watch_focus, 0.01)
		if role != "leader" and behavior in ["graze", "heavy_roam"]:
			var leader_pos := _role_anchor_position(anchor_id, "草食动物", "leader")
			if leader_pos != Vector2.ZERO:
				var leader_signal := _role_anchor_signal(anchor_id, "草食动物", "leader")
				var herd_slot := _formation_follow_slot("leader", phase, radius, leader_signal)
				escort_target = leader_pos + herd_slot
				base_pos = base_pos.lerp(escort_target, 0.06 if leader_signal else 0.052)
		elif role != "sentry" and behavior == "glide":
			var sentry_pos := _role_anchor_position(anchor_id, "飞行动物", "sentry")
			if sentry_pos != Vector2.ZERO:
				var sentry_signal := _role_anchor_signal(anchor_id, "飞行动物", "sentry")
				var wing_slot := _formation_follow_slot("sentry", angle + phase, radius, sentry_signal)
				escort_target = sentry_pos + wing_slot
				base_pos = base_pos.lerp(escort_target, 0.058 if sentry_signal else 0.048)
				if recent_chase_result:
					var carrion_glide_pull := 0.022 if aftermath_ratio > 0.55 else 0.0
					base_pos = base_pos.lerp(glide_after_focus, ((0.068 if sentry_signal else 0.054) * maxf(0.35, aftermath_ratio) + carrion_glide_pull) * glide_pull_scale)
					alert_timer = maxf(alert_timer, 0.82 if not aftermath_active else 1.02)
					if recent_chase_site != Vector2.ZERO and base_pos.distance_to(recent_chase_site) > 4.8:
						var site_pull := 0.058 if aftermath_ratio > 0.52 else 0.028
						base_pos = base_pos.lerp(recent_chase_site, (site_pull if aftermath_active else 0.052) * glide_site_scale)
					if role == "sentry":
						base_pos += Vector2(cos(angle * 1.8), sin(angle * 1.6)) * (0.18 if not aftermath_active else 0.26)
						if aftermath_ratio > 0.58:
							base_pos += Vector2(cos(angle * 0.9), sin(angle * 0.9)) * 0.18
		elif role != "alpha" and behavior == "stalk":
			var alpha_pos := _role_anchor_position(anchor_id, "掠食者", "alpha")
			if alpha_pos != Vector2.ZERO:
				var alpha_signal := _role_anchor_signal(anchor_id, "掠食者", "alpha")
				var flank_slot := _formation_follow_slot("alpha", phase, radius, alpha_signal)
				escort_target = alpha_pos + flank_slot
				base_pos = base_pos.lerp(escort_target, 0.074 if alpha_signal else 0.06)
				if recent_chase_result:
					var carrion_stalk_pull := 0.02 if aftermath_ratio > 0.5 else 0.0
					base_pos = base_pos.lerp(predator_after_focus, ((0.052 if not aftermath_active else 0.074) * maxf(0.4, aftermath_ratio) + carrion_stalk_pull) * predator_pull_scale)
					alert_timer = maxf(alert_timer, 0.76 if not aftermath_active else 0.96)
					if recent_chase_site != Vector2.ZERO and base_pos.distance_to(recent_chase_site) > 3.6:
						var stalk_site_pull := 0.072 if aftermath_ratio > 0.5 else 0.032
						base_pos = base_pos.lerp(recent_chase_site, (stalk_site_pull if aftermath_active else 0.062) * stalk_site_scale)
					if alpha_signal:
						var carrion_push := 0.12 if aftermath_ratio > 0.44 else 0.28
						base_pos += (predator_after_focus - base_pos).normalized() * ((0.16 if not aftermath_active else carrion_push) * predator_pull_scale)
				if role == "alpha" and recent_chase_site != Vector2.ZERO and aftermath_ratio > 0.62:
					base_pos += (recent_chase_site - base_pos).normalized() * (0.14 * predator_pull_scale)
		if behavior == "stalk":
			var prey_focus := _nearest_target(base_pos, prey_positions)
			if prey_focus != Vector2.ZERO:
				var chase_distance: float = base_pos.distance_to(prey_focus)
				var burst: bool = chase_distance < burst_distance
				var alpha_push := (0.08 if role == "alpha" else 0.05) * alpha_push_scale
				base_pos = base_pos.lerp(prey_focus, alpha_push if not burst else alpha_push + 0.07)
				if role == "alpha":
					var pressure_lane := (prey_focus - base_pos).normalized()
					if pressure_lane != Vector2.ZERO:
						base_pos += pressure_lane * (0.24 * alpha_push_scale)
					signal_timer = maxf(signal_timer, 0.92 if burst else 0.54)
				var pressure_score := (1.0 / maxf(1.0, chase_distance)) * chase_score_scale
				if strongest_pressure.is_empty() or pressure_score > float(strongest_pressure.get("score", 0.0)):
					strongest_pressure = {"predator": animal, "target": prey_focus, "score": pressure_score}
				if burst and (strongest_chase.is_empty() or chase_distance < float(strongest_chase.get("distance", 999999.0))):
					strongest_chase = {"predator": animal, "target": prey_focus, "distance": chase_distance}
			elif herd_focus != Vector2.ZERO:
				base_pos = base_pos.lerp(herd_focus, 0.02)
			elif recent_chase_result:
				base_pos = base_pos.lerp(predator_after_focus, (0.04 if role == "alpha" else (0.028 if not aftermath_active else 0.042)) * predator_pull_scale)
				if role == "alpha":
					signal_timer = maxf(signal_timer, 0.64 if not aftermath_active else 0.86)
			if player_distance < stalk_player_radius:
				base_pos += player_delta.normalized() * 0.6
				alerted = true
				alert_timer = maxf(alert_timer, 0.9)
				if role == "alpha":
					signal_timer = maxf(signal_timer, 0.74)
		elif behavior == "glide":
			base_pos += Vector2(cos(angle * 0.7) * 0.8, sin(angle * 0.5) * 0.6)
			if recent_pressure_target != Vector2.ZERO and base_pos.distance_to(recent_pressure_target) < glide_pressure_radius:
				base_pos += Vector2(cos(angle * 1.9), sin(angle * 1.5)) * 0.78
			if player_distance < (10.2 if role == "sentry" else 9.0):
				alerted = true
				alert_timer = maxf(alert_timer, (0.95 if role == "sentry" else 0.7) * sentry_signal_scale)
				if role == "sentry":
					if pause_timer <= 0.0:
						pause_timer = 0.34
						signal_timer = maxf(signal_timer, 0.82 * sentry_signal_scale)
					look_back = true
					if pause_timer > 0.08:
						base_pos = base_pos.lerp(anchor, 0.08)
					else:
						base_pos += player_delta.normalized() * (0.88 * sentry_signal_scale)
			elif role != "sentry" and _role_anchor_alert(anchor_id, "飞行动物", "sentry"):
				alerted = true
				alert_timer = maxf(alert_timer, 0.62 * sentry_signal_scale)
				base_pos += Vector2(cos(angle * 1.4), sin(angle * 1.2)) * (0.42 * sentry_signal_scale)
			elif role != "sentry" and _role_anchor_signal(anchor_id, "飞行动物", "sentry"):
				alerted = true
				alert_timer = maxf(alert_timer, 0.48 * sentry_signal_scale)
				base_pos += Vector2(cos(angle * 1.9) * 0.54, abs(sin(angle * 1.7)) * 0.58) * sentry_signal_scale
			if recent_chase_result:
				base_pos = base_pos.lerp(glide_after_focus, 0.052 if role == "sentry" else 0.064)
				if role == "sentry":
					signal_timer = maxf(signal_timer, 0.76)
		elif behavior == "swim":
			base_pos = base_pos.lerp(Vector2(_hotspot_pos("waterhole").x, _hotspot_pos("waterhole").z), 0.03)
			if player_distance < swim_player_radius:
				alerted = true
				alert_timer = maxf(alert_timer, 0.8 * regroup_scale)
		elif behavior == "heavy_roam":
			base_pos = base_pos.lerp(Vector2(_hotspot_pos("waterhole").x, _hotspot_pos("waterhole").z), 0.015)
			if player_distance < heavy_player_radius:
				alerted = true
				alert_timer = maxf(alert_timer, 1.0 * regroup_scale)
		else:
			var herd_neighbor := _nearest_same_category_position(base_pos, str(animal.get("species_id", "")), str(animal.get("category", "")))
			if herd_neighbor != Vector2.ZERO and player_distance > float(animal.get("alert_radius", 6.0)) and _nearest_predator_position(base_pos) == Vector2.ZERO:
				base_pos = base_pos.lerp(herd_neighbor, 0.018)
			var nearest_predator := _nearest_predator_position(base_pos)
			if nearest_predator != Vector2.ZERO and base_pos.distance_to(nearest_predator) < 7.0:
				var leader_escape := (1.24 if role == "leader" else 1.0) * flee_scale
				base_pos += (base_pos - nearest_predator).normalized() * leader_escape
				alerted = true
				alert_timer = maxf(alert_timer, (1.68 if role == "leader" else 1.4) * herd_signal_scale)
				if role == "leader":
					if pause_timer <= 0.0:
						pause_timer = 0.24
					var corridor_focus2 := _hotspot_pos("migration_corridor")
					if pause_timer > 0.08:
						base_pos = base_pos.lerp(anchor, 0.1)
					else:
						base_pos = base_pos.lerp(Vector2(corridor_focus2.x, corridor_focus2.z), 0.085)
					look_back = false
					signal_timer = maxf(signal_timer, 1.04 * herd_signal_scale)
			if recent_pressure_target != Vector2.ZERO and base_pos.distance_to(recent_pressure_target) < 10.0:
				base_pos = base_pos.lerp(herd_route_focus, 0.12 if role == "leader" else 0.08)
				alerted = true
				alert_timer = maxf(alert_timer, (1.1 if role == "leader" else 0.9) * herd_signal_scale)
			if recent_chase_result and recent_chase_site != Vector2.ZERO and base_pos.distance_to(recent_chase_site) < 16.0:
				var retreat_pull := 0.08 if aftermath_ratio > 0.62 else 0.2
				if aftermath_ratio > 0.62:
					base_pos += (base_pos - recent_chase_site).normalized() * (0.24 if role == "leader" else 0.18)
				base_pos = base_pos.lerp(herd_route_focus, (0.16 if role == "leader" else (0.1 if not aftermath_active else retreat_pull)) * herd_pull_scale)
				regrouping = true
				alerted = true
				alert_timer = maxf(alert_timer, (1.0 if role == "leader" else (0.78 if not aftermath_active else 1.04)) * herd_signal_scale)
				if role == "leader":
					signal_timer = maxf(signal_timer, (0.86 if not aftermath_active else 1.12) * herd_signal_scale)
			elif recent_chase_result and recent_chase_site != Vector2.ZERO and role == "leader":
				var far_pull := 0.026 if aftermath_ratio > 0.56 else 0.056
				base_pos = base_pos.lerp(herd_route_focus, (0.028 if not aftermath_active else far_pull) * herd_pull_scale)
				signal_timer = maxf(signal_timer, (0.52 if not aftermath_active else 0.74) * herd_signal_scale)
		if behavior in ["graze", "heavy_roam"] and recent_chase_result and role != "leader":
			var herd_leader_signal := _role_anchor_signal(anchor_id, "草食动物", "leader")
			if herd_leader_signal and escort_target != Vector2.ZERO:
				var corridor_dir := (herd_route_focus - escort_target).normalized()
				base_pos = base_pos.lerp(escort_target + corridor_dir * 0.42, (0.18 if not aftermath_active else 0.24) * herd_pull_scale)
			if player_distance < graze_player_radius:
				base_pos += player_delta.normalized() * (0.45 * flee_scale)
				alerted = true
				alert_timer = maxf(alert_timer, 1.2 * herd_signal_scale)
				if role == "leader":
					if pause_timer <= 0.0:
						pause_timer = 0.22
					signal_timer = maxf(signal_timer, 0.84 * herd_signal_scale)
			elif role != "leader" and _role_anchor_alert(anchor_id, "草食动物", "leader"):
				alerted = true
				alert_timer = maxf(alert_timer, 0.82 * regroup_scale)
				if escort_target != Vector2.ZERO:
					base_pos = base_pos.lerp(escort_target, 0.12 * regroup_scale)
			elif role != "leader" and _role_anchor_signal(anchor_id, "草食动物", "leader"):
				alerted = true
				alert_timer = maxf(alert_timer, 0.68 * regroup_scale)
				if escort_target != Vector2.ZERO:
					base_pos = base_pos.lerp(escort_target, 0.28 * regroup_scale)

		if role != "alpha" and behavior == "stalk" and _role_anchor_signal(anchor_id, "掠食者", "alpha"):
			alerted = true
			alert_timer = maxf(alert_timer, 0.76)
			if escort_target != Vector2.ZERO:
				base_pos = base_pos.lerp(escort_target, 0.26)
		if behavior == "glide" and not current_chase_result.is_empty():
			base_pos = base_pos.lerp(glide_after_focus, 0.024)
			if recent_chase_site != Vector2.ZERO:
				base_pos = base_pos.lerp(recent_chase_site, 0.018)

		if alert_timer > 0.0 and behavior != "stalk":
			var flee_vec := Vector2.ZERO
			if player_distance > 0.0:
				flee_vec += player_delta.normalized()
			var nearest_predator_focus := _nearest_predator_position(base_pos)
			if nearest_predator_focus != Vector2.ZERO:
				flee_vec += (base_pos - nearest_predator_focus).normalized()
			if flee_vec.length() > 0.0:
				base_pos += flee_vec.normalized() * (0.42 + minf(alert_timer, 1.0) * 0.66) * flee_scale
			alerted = true
			look_back = alert_timer < 0.55 and behavior in ["graze", "heavy_roam"]
		elif behavior in ["graze", "heavy_roam", "swim"] and base_pos.distance_to(anchor) > 2.0:
			base_pos = base_pos.lerp(anchor, 0.05 * regroup_scale)
			regrouping = true

		var previous_pos: Vector2 = current_pos
		var step_limit := _animal_motion_step_limit(behavior, category, alerted, role)
		var desired_travel: Vector2 = base_pos - previous_pos
		if desired_travel.length() > step_limit:
			base_pos = previous_pos + desired_travel.normalized() * step_limit
		base_pos = previous_pos.lerp(base_pos, 0.76 if alerted else 0.62)
		animal["position"] = base_pos
		animal["alerted"] = alerted
		animal["look_back"] = look_back
		animal["regrouping"] = regrouping
		animal["alert_timer"] = alert_timer
		animal["pause_timer"] = pause_timer
		animal["signal_timer"] = signal_timer
		animal["escort_target"] = escort_target
		animal["route_index"] = route_index
		var travel: Vector2 = base_pos - previous_pos
		animal["travel"] = travel
		var heading_basis := desired_travel
		if heading_basis.length() <= 0.04 and escort_target != Vector2.ZERO:
			heading_basis = escort_target - previous_pos
		if heading_basis.length() <= 0.04 and travel.length() > 0.02:
			heading_basis = travel
		if heading_basis.length() <= 0.04:
			match behavior:
				"stalk":
					var prey_heading_target := _nearest_target(base_pos, prey_positions)
					if prey_heading_target != Vector2.ZERO:
						heading_basis = prey_heading_target - base_pos
				"glide":
					if escort_target != Vector2.ZERO:
						heading_basis = escort_target - base_pos
					elif not current_hotspot.is_empty():
						var glide_focus := _hotspot_pos(str(current_hotspot.get("hotspot_id", "")))
						heading_basis = Vector2(glide_focus.x, glide_focus.z) - base_pos
				_:
					if anchor != Vector2.ZERO:
						heading_basis = anchor - base_pos
		var current_heading := float(animal.get("heading", 0.0))
		if heading_basis.length() > 0.04:
			var desired_heading := atan2(heading_basis.x, heading_basis.y)
			current_heading = lerp_angle(current_heading, desired_heading, 0.34 if alerted else 0.22)
		animal["heading"] = current_heading
		wildlife[index] = animal
		_position_animal_node(animal)

	current_interaction.clear()
	current_chase.clear()
	current_chase_result.clear()
	if not strongest_pressure.is_empty():
		var predator: Dictionary = strongest_pressure.get("predator", {})
		var target: Vector2 = strongest_pressure.get("target", Vector2.ZERO)
		var pressure_text := _biome_pressure_text(str(predator.get("label", "掠食者")))
		if Vector2(predator.get("position", Vector2.ZERO)).distance_to(target) < pressure_distance:
			current_interaction = {
				"title": pressure_text.get("title", "追逐压力"),
				"body": pressure_text.get("body", ""),
				"accent": Color8(240, 156, 110),
				"predator": predator,
				"target": target,
			}
			witnessed_pressure = true
	if not strongest_chase.is_empty():
		chase_focus_time += delta
		var chase_predator: Dictionary = strongest_chase.get("predator", {})
		var pressure_hotspot := _hotspot_pos(str(chase_state.get("pressure_hotspot", "predator_ridge")))
		var aftermath_hotspot := _hotspot_pos(str(chase_state.get("aftermath_hotspot", "carrion_field")))
		var pressure_target := Vector2(pressure_hotspot.x, pressure_hotspot.z)
		var aftermath_target := Vector2(aftermath_hotspot.x, aftermath_hotspot.z)
		var resolved_target: Vector2 = strongest_chase.get("target", Vector2.ZERO)
		if pressure_target != Vector2.ZERO:
			resolved_target = Vector2(resolved_target).lerp(
				pressure_target,
				0.36 * float(chase_state.get("pressure_pull_scale", 1.0)) * float(pressure_window_profile.get("active_scale", 1.0)) * arrival_pressure_boost
			)
		current_chase = {
			"title": _biome_chase_burst_text(str(chase_predator.get("label", "掠食者"))).get("title", "追猎爆发"),
			"body": _biome_chase_burst_text(str(chase_predator.get("label", "掠食者"))).get("body", ""),
			"accent": Color8(255, 119, 86),
			"predator": chase_predator,
			"target": resolved_target,
		}
		var chase_distance := float(strongest_chase.get("distance", 999999.0))
		if chase_distance < hit_distance * float(chase_state.get("result_radius_scale", 1.0)):
			current_chase_result = {
				"title": _biome_chase_hit_text(str(chase_predator.get("label", "掠食者"))).get("title", "追猎命中"),
				"body": _biome_chase_hit_text(str(chase_predator.get("label", "掠食者"))).get("body", ""),
				"accent": Color8(255, 96, 78),
				"predator": chase_predator,
				"target": resolved_target,
			}
			var aftermath_resolved: Vector2 = resolved_target
			if aftermath_target != Vector2.ZERO:
				aftermath_resolved = resolved_target.lerp(
					aftermath_target,
					0.54 * float(chase_state.get("aftermath_pull_scale", 1.0)) * float(aftermath_window_profile.get("active_scale", 1.0)) * arrival_aftermath_boost
				)
			chase_aftermath = {
				"title": _biome_aftermath_text(true).get("title", "追猎余波"),
				"body": _biome_aftermath_text(true).get("body", ""),
				"accent": Color8(248, 146, 102),
				"target": aftermath_resolved,
				"timer": aftermath_duration,
				"duration": aftermath_duration,
			}
			witnessed_chase_result = true
			discovery_log.push_front(_route_stage_log_entry("chase_hit", str(chase_predator.get("label", "掠食者"))))
			discovery_log = discovery_log.slice(0, 6)
			chase_focus_time = 0.0
		elif chase_focus_time > burst_timeout:
			current_chase_result = {
				"title": _biome_chase_miss_text(str(chase_predator.get("label", "掠食者"))).get("title", "追猎落空"),
				"body": _biome_chase_miss_text(str(chase_predator.get("label", "掠食者"))).get("body", ""),
				"accent": Color8(240, 202, 132),
				"predator": chase_predator,
				"target": resolved_target,
			}
			var miss_aftermath_target: Vector2 = resolved_target
			if aftermath_target != Vector2.ZERO:
				miss_aftermath_target = resolved_target.lerp(
					aftermath_target,
					0.48 * float(chase_state.get("aftermath_pull_scale", 1.0)) * float(aftermath_window_profile.get("active_scale", 1.0)) * arrival_aftermath_boost
				)
			chase_aftermath = {
				"title": _biome_aftermath_text(false).get("title", "追猎余波"),
				"body": _biome_aftermath_text(false).get("body", ""),
				"accent": Color8(236, 188, 122),
				"target": miss_aftermath_target,
				"timer": aftermath_duration,
				"duration": aftermath_duration,
			}
			witnessed_chase_result = true
			discovery_log.push_front(_route_stage_log_entry("chase_miss", str(chase_predator.get("label", "掠食者"))))
			discovery_log = discovery_log.slice(0, 6)
			chase_focus_time = 0.0
	else:
		chase_focus_time = 0.0


func _position_animal_node(animal: Dictionary) -> void:
	var root: Node3D = animal.get("node", null)
	if root == null:
		return
	var member_root: Node3D = animal.get("member_root", null)
	if member_root == null:
		member_root = root
	var pos2: Vector2 = animal.get("position", Vector2.ZERO)
	var role := str(animal.get("role", "member"))
	var category := str(animal.get("category", "区域生物"))
	var behavior := str(animal.get("behavior", "graze"))
	var species_id := str(animal.get("species_id", ""))
	var stage_animal_profile := _route_stage_animal_profile(animal)
	var dynamic_prominence := _dynamic_cluster_scale(category, "visibility_scale", 1.0)
	var travel_vec: Vector2 = animal.get("travel", Vector2.ZERO)
	var grounded_root_y := _ground_contact_height_at(pos2.x, pos2.y) + _animal_ground_offset(species_id, category)
	root.position = Vector3(pos2.x, lerpf(root.position.y, grounded_root_y, 0.28), pos2.y)
	var root_heading := float(animal.get("heading", 0.0))
	root.rotation.y = lerp_angle(root.rotation.y, root_heading, 0.74 if travel_vec.length() > 0.08 else 0.52)
	var encounter_match := str(current_encounter.get("species_id", "")) == str(animal.get("species_id", ""))
	var hotspot_target_category := ""
	if not current_hotspot.is_empty():
		hotspot_target_category = str(_hotspot_task_config(str(current_hotspot.get("hotspot_id", ""))).get("required_category", ""))
	var spotlight_match := encounter_match or (hotspot_target_category != "" and category == hotspot_target_category)
	var signal_timer := float(animal.get("signal_timer", 0.0))
	var base_scale := 1.0
	if role == "leader" or role == "alpha":
		base_scale = 1.06
	elif role == "sentry":
		base_scale = 0.96
	base_scale *= float(stage_animal_profile.get("prominence_scale", 1.0))
	base_scale *= dynamic_prominence
	var alert_scale := 1.12 if encounter_match else ((1.08 * base_scale) if bool(animal.get("alerted", false)) else ((1.03 * base_scale) if bool(animal.get("regrouping", false)) else base_scale))
	if signal_timer > 0.0:
		alert_scale += minf(0.08, signal_timer * 0.08) * float(stage_animal_profile.get("signal_scale", 1.0))
	root.scale = root.scale.lerp(Vector3.ONE * alert_scale, 0.16)
	var look_back_yaw := 0.48 if encounter_match else (0.34 if bool(animal.get("look_back", false)) else 0.0)
	var travel_speed := clampf(travel_vec.length() / 0.22, 0.0, 1.0)
	var attention_data := _animal_attention_data(animal, encounter_match, spotlight_match)
	var attention_target: Vector2 = attention_data.get("target", Vector2.ZERO)
	var attention_mode := str(attention_data.get("mode", "idle"))
	var members := member_root.get_children()
	for member_index in range(members.size()):
		var member := members[member_index] as Node3D
		var formation_phase := elapsed_time() * (0.9 + 0.08 * member_index) + float(member_index) * 0.7
		var offset := _member_formation_offset(role, category, member_index, elapsed_time(), signal_timer)
		if signal_timer > 0.0:
			offset = _signal_formation_offset(role, member_index, formation_phase)
		var pose_profile := _animal_member_pose_profile(
			species_id,
			category,
			behavior,
			role,
			travel_speed,
			member_index,
			formation_phase,
			bool(animal.get("alerted", false)),
			bool(animal.get("look_back", false)),
			signal_timer
		)
		var spacing_offset := _animal_member_spacing_offset(species_id, category, role, member_index, offset)
		offset += spacing_offset
		offset.y += float(pose_profile.get("y_offset", 0.0))
		offset.z += float(pose_profile.get("z_offset", 0.0))
		member.position = member.position.lerp(offset, 0.24 if signal_timer <= 0.0 else 0.34)
		if signal_timer > 0.0:
			member.position.y += sin(elapsed_time() * 7.4 + member_index) * minf(0.05, signal_timer * 0.06)
		if bool(animal.get("alerted", false)):
			var alert_yaw := 0.16 * sin(elapsed_time() * 6.0 + member_index) + float(pose_profile.get("yaw", 0.0))
			member.rotation.y = lerpf(member.rotation.y, alert_yaw, 0.18)
		elif bool(animal.get("look_back", false)):
			var look_target := (look_back_yaw if member_index == 0 else look_back_yaw * 0.35) + float(pose_profile.get("yaw", 0.0)) * 0.4
			member.rotation.y = lerpf(member.rotation.y, look_target, 0.18)
		else:
			var formation_yaw := clampf(-offset.x * 0.04, -0.06, 0.06)
			var pose_yaw := float(pose_profile.get("yaw", 0.0)) * 0.34
			var local_heading := formation_yaw + pose_yaw
			member.rotation.y = lerpf(member.rotation.y, local_heading, 0.14)
		var target_pitch := float(pose_profile.get("pitch", 0.0))
		match category:
			"掠食者":
				target_pitch += 0.08 * travel_speed
			"草食动物":
				target_pitch += 0.045 * travel_speed
			"飞行动物":
				target_pitch += -0.04 + 0.02 * travel_speed
			"水域动物":
				target_pitch += 0.025 * travel_speed
		if role in ["leader", "alpha"]:
			target_pitch += 0.015
		if bool(animal.get("look_back", false)):
			target_pitch *= 0.4
		member.rotation.x = lerpf(member.rotation.x, target_pitch * 0.62, 0.14)
		var target_roll := clampf(-offset.x * 0.05 - member.rotation.y * 0.22 + float(pose_profile.get("roll", 0.0)), -0.08, 0.08)
		member.rotation.z = lerpf(member.rotation.z, target_roll, 0.12)
		var focus_rigs := _ensure_member_focus_rigs(member)
		var body_rig: Node3D = focus_rigs.get("body", null)
		var head_rig: Node3D = focus_rigs.get("head", null)
		var attention_response := _animal_attention_response_profile(species_id, category, role, member_index)
		var attention_mode_response := _animal_attention_mode_response(attention_mode)
		var attention_distance_response := _animal_attention_distance_response(pos2, attention_target, attention_mode, species_id, category, role)
		var attention_scan := _animal_attention_scan_profile(species_id, category, role, member_index, formation_phase)
		var attention_pose := _animal_attention_pose_profile(species_id, category, role, attention_mode, member_index, formation_phase)
		var desired_attention_yaw := _animal_attention_yaw(pos2, root.rotation.y, attention_target)
		desired_attention_yaw *= float(attention_response.get("yaw_scale", 1.0))
		desired_attention_yaw *= float(attention_mode_response.get("yaw_scale", 1.0))
		desired_attention_yaw *= float(attention_distance_response.get("yaw_scale", 1.0))
		var attention_lerp_key := "attention_release_lerp"
		if absf(desired_attention_yaw) > 0.008:
			attention_lerp_key = "attention_acquire_lerp"
		var attention_yaw := _member_meta_lerpf(
			member,
			"attention_yaw",
			desired_attention_yaw,
			float(attention_response.get(attention_lerp_key, 0.12))
			* float(attention_mode_response.get(attention_lerp_key, 1.0))
			* float(attention_distance_response.get(attention_lerp_key, 1.0))
		)
		var attention_strength := clampf(abs(attention_yaw) / 0.12, 0.0, 1.0)
		attention_strength = maxf(attention_strength, float(attention_distance_response.get("target_strength", 0.0)) * 0.72)
		if bool(animal.get("alerted", false)) or bool(animal.get("look_back", false)):
			attention_strength = maxf(attention_strength, 0.75)
		var scan_weight := lerpf(1.0, 0.28, attention_strength)
		scan_weight *= float(attention_mode_response.get("scan_weight", 1.0))
		scan_weight *= float(attention_distance_response.get("scan_weight", 1.0))
		var head_yaw := clampf(
			float(pose_profile.get("yaw", 0.0)) * 1.15
			+ attention_yaw
			+ float(attention_pose.get("yaw", 0.0))
			+ float(attention_scan.get("yaw", 0.0)) * scan_weight,
			-0.26,
			0.26
		)
		var head_pitch := clampf(
			target_pitch * 0.72
			+ float(pose_profile.get("pitch", 0.0)) * 0.18
			+ float(attention_pose.get("pitch", 0.0))
			+ float(attention_scan.get("pitch", 0.0)) * scan_weight,
			-0.24,
			0.24
		)
		if bool(animal.get("look_back", false)):
			head_yaw = clampf(head_yaw + (look_back_yaw if member_index == 0 else look_back_yaw * 0.45), -0.28, 0.28)
		elif bool(animal.get("alerted", false)):
			head_yaw = clampf(head_yaw + 0.05 * sin(elapsed_time() * 4.6 + member_index), -0.28, 0.28)
		if body_rig != null:
			var body_pitch := target_pitch * (0.16 + attention_strength * 0.08)
			var body_yaw := head_yaw * (0.08 + attention_strength * 0.18)
			var body_roll := target_roll * (0.28 + attention_strength * 0.16)
			var body_lerp := float(attention_response.get("body_lerp", 1.0))
			body_lerp *= float(attention_mode_response.get("body_lerp", 1.0))
			body_lerp *= float(attention_distance_response.get("body_lerp", 1.0))
			body_rig.rotation.x = lerpf(body_rig.rotation.x, body_pitch, (0.09 + attention_strength * 0.04) * body_lerp)
			body_rig.rotation.y = lerpf(body_rig.rotation.y, body_yaw, (0.07 + attention_strength * 0.05) * body_lerp)
			body_rig.rotation.z = lerpf(body_rig.rotation.z, body_roll, (0.08 + attention_strength * 0.04) * body_lerp)
		if head_rig != null:
			var head_return_yaw := float(pose_profile.get("yaw", 0.0)) * 0.7
			var resolved_head_yaw := lerpf(head_return_yaw, head_yaw, 0.42 + attention_strength * 0.58)
			var head_return_pitch := target_pitch * 0.4
			var resolved_head_pitch := lerpf(head_return_pitch, head_pitch, 0.4 + attention_strength * 0.6)
			var head_lerp := float(attention_response.get("head_lerp", 1.0))
			head_lerp *= float(attention_mode_response.get("head_lerp", 1.0))
			head_lerp *= float(attention_distance_response.get("head_lerp", 1.0))
			head_rig.rotation.x = lerpf(head_rig.rotation.x, resolved_head_pitch, (0.16 + attention_strength * 0.12) * head_lerp)
			head_rig.rotation.y = lerpf(head_rig.rotation.y, resolved_head_yaw, (0.18 + attention_strength * 0.14) * head_lerp)
			head_rig.rotation.z = lerpf(head_rig.rotation.z, target_roll * 0.16, 0.12)
		_apply_member_locomotion(member, species_id, category, behavior, role, member_index, formation_phase, travel_speed, bool(animal.get("alerted", false)), signal_timer)
		if role == "sentry":
			member.position.y += 0.12 + sin(elapsed_time() * 2.8 + member_index) * 0.025
			if member_index == 0 and signal_timer > 0.0:
				member.rotation.y = lerpf(member.rotation.y, 0.52, 0.22)
		elif role == "leader" and member_index == 0:
			member.position.y += 0.03 + sin(elapsed_time() * 4.0) * 0.012
			if signal_timer > 0.0:
				member.position.z += 0.08
		elif role == "alpha" and member_index == 0:
			member.position.z += 0.04
			if signal_timer > 0.0:
				member.position.z += 0.12
	var marker_root: Node3D = animal.get("marker_root", null)
	var marker_ring: MeshInstance3D = animal.get("marker_ring", null)
	var marker_beacon: MeshInstance3D = animal.get("marker_beacon", null)
	if marker_root != null and marker_ring != null and marker_beacon != null:
		var marker_scale := maxf(0.92, float(stage_animal_profile.get("prominence_scale", 1.0)))
		var marker_height := 0.02
		var ring_alpha := 0.34
		var beacon_alpha := 0.7
		match category:
			"掠食者":
				marker_scale *= 1.04
				marker_height = 0.0
				ring_alpha = 0.42
				beacon_alpha = 0.82
			"飞行动物":
				marker_scale *= 0.98
				marker_height = 0.12
				ring_alpha = 0.28
				beacon_alpha = 0.74
			"草食动物":
				marker_scale *= 1.02
				marker_height = 0.06
				ring_alpha = 0.36
				beacon_alpha = 0.72
			"水域动物":
				marker_height = 0.04
				ring_alpha = 0.32
				beacon_alpha = 0.7
		if role in ["leader", "sentry", "alpha"]:
			marker_scale *= 1.06
			match role:
				"leader":
					marker_scale *= 1.04
					marker_height += 0.06
					ring_alpha += 0.04
				"sentry":
					marker_scale *= 0.98
					marker_height += 0.14
					beacon_alpha += 0.06
				"alpha":
					marker_scale *= 1.08
					marker_height += 0.02
					ring_alpha += 0.08
					beacon_alpha += 0.08
		if encounter_match:
			marker_scale *= 1.12
		elif signal_timer > 0.0:
			marker_scale *= 1.08
		if spotlight_match:
			marker_scale *= 1.08
			beacon_alpha += 0.08
			ring_alpha += 0.06
		marker_root.scale = marker_root.scale.lerp(Vector3.ONE * marker_scale, 0.18)
		marker_root.position.y = lerpf(marker_root.position.y, marker_height + minf(0.08, signal_timer * 0.08), 0.18)
		if marker_ring.material_override is StandardMaterial3D:
			var ring_mat := marker_ring.material_override as StandardMaterial3D
			ring_mat.albedo_color.a = lerpf(ring_mat.albedo_color.a, (0.64 if encounter_match or signal_timer > 0.08 else ring_alpha), 0.18)
			if role == "alpha":
				ring_mat.albedo_color = ring_mat.albedo_color.lerp(CATEGORY_COLORS.get("掠食者", Color8(214, 112, 87)).lightened(0.14), 0.14)
			elif role == "leader":
				ring_mat.albedo_color = ring_mat.albedo_color.lerp(CATEGORY_COLORS.get("草食动物", Color8(216, 190, 104)).lightened(0.08), 0.14)
			elif role == "sentry":
				ring_mat.albedo_color = ring_mat.albedo_color.lerp(CATEGORY_COLORS.get("飞行动物", Color8(130, 170, 224)).lightened(0.12), 0.14)
		if marker_beacon.material_override is StandardMaterial3D:
			var beacon_mat := marker_beacon.material_override as StandardMaterial3D
			beacon_mat.albedo_color.a = lerpf(beacon_mat.albedo_color.a, (0.92 if encounter_match or signal_timer > 0.08 else beacon_alpha), 0.18)
			if role == "alpha":
				var beacon_root_color: Color = CATEGORY_COLORS.get("掠食者", Color8(214, 112, 87)).lightened(0.22)
				beacon_mat.albedo_color = beacon_mat.albedo_color.lerp(beacon_root_color, 0.16)
			elif role == "leader":
				var beacon_root_color: Color = CATEGORY_COLORS.get("草食动物", Color8(216, 190, 104)).lightened(0.16)
				beacon_mat.albedo_color = beacon_mat.albedo_color.lerp(beacon_root_color, 0.14)
			elif role == "sentry":
				var beacon_root_color: Color = CATEGORY_COLORS.get("飞行动物", Color8(130, 170, 224)).lightened(0.2)
				beacon_mat.albedo_color = beacon_mat.albedo_color.lerp(beacon_root_color, 0.16)


func _member_formation_offset(role: String, category: String, member_index: int, time_value: float, signal_timer: float) -> Vector3:
	var lateral_sign := -1.0 if member_index % 2 == 0 else 1.0
	var rank := float(member_index / 2)
	var sway := sin(time_value * (1.2 + rank * 0.08) + float(member_index) * 0.55)
	var drift := cos(time_value * (0.96 + rank * 0.06) + float(member_index) * 0.42)
	var seed_wave := sin(float(member_index) * 1.73 + rank * 0.94)
	var lateral_gap := 0.24
	var depth_gap := 0.34
	var front_offset := 0.0
	var height_offset := 0.0
	var sway_scale := 0.012
	var depth_sway_scale := 0.008
	match category:
		"草食动物":
			lateral_gap = 0.3
			depth_gap = 0.38
			front_offset = 0.04
			sway_scale = 0.01
			depth_sway_scale = 0.006
		"掠食者":
			lateral_gap = 0.24
			depth_gap = 0.3
			front_offset = 0.08
			sway_scale = 0.008
			depth_sway_scale = 0.006
		"飞行动物":
			lateral_gap = 0.28
			depth_gap = 0.22
			front_offset = 0.02
			height_offset = 0.12
			sway_scale = 0.014
			depth_sway_scale = 0.01
		"水域动物":
			lateral_gap = 0.2
			depth_gap = 0.28
			sway_scale = 0.006
			depth_sway_scale = 0.004
	var offset := Vector3(
		lateral_sign * (lateral_gap + rank * (lateral_gap * 0.56)),
		height_offset,
		front_offset - rank * depth_gap
	)
	var lane_bias := seed_wave * 0.026
	offset.x += sway * sway_scale
	offset.z += drift * depth_sway_scale
	offset.x += lane_bias
	if role == "leader":
		if member_index == 0:
			offset = Vector3(0.0, 0.04, front_offset + 0.26)
		else:
			offset = Vector3(
				lateral_sign * (lateral_gap * 1.12 + rank * 0.18),
				height_offset,
				front_offset - 0.18 - rank * (depth_gap * 0.92)
			)
	elif role == "alpha":
		if member_index == 0:
			offset = Vector3(0.0, 0.03, front_offset + 0.3)
		else:
			offset = Vector3(
				lateral_sign * (lateral_gap * 0.96 + rank * 0.15),
				height_offset,
				front_offset - 0.14 - rank * (depth_gap * 0.86)
			)
	elif role == "sentry" or category == "飞行动物":
		offset = Vector3(
			lateral_sign * (lateral_gap + rank * 0.18),
			0.14 + sin(time_value * 2.1 + float(member_index)) * 0.028,
			front_offset - rank * (depth_gap * 0.72)
		)
	elif category == "水域动物":
		offset = Vector3(
			lateral_sign * (lateral_gap + rank * 0.1),
			0.0,
			front_offset - rank * (depth_gap * 0.86)
		)
	match category:
		"草食动物":
			offset.z -= abs(offset.x) * 0.12
			offset.x += lateral_sign * rank * 0.02
		"掠食者":
			offset.z -= abs(offset.x) * 0.08
			offset.x *= 0.94
		"飞行动物":
			offset.z += lateral_sign * 0.05
			offset.y += sin(time_value * 1.7 + float(member_index) * 0.6) * 0.018
		"水域动物":
			offset.x *= 0.86
			offset.z += lateral_sign * 0.02
	if signal_timer > 0.0 and role in ["leader", "alpha"]:
		offset.z += 0.04
	return offset


func _animal_member_pose_profile(species_id: String, category: String, behavior: String, role: String, travel_speed: float, member_index: int, phase: float, alerted: bool, look_back: bool, signal_timer: float) -> Dictionary:
	var profile := {
		"y_offset": 0.0,
		"z_offset": 0.0,
		"pitch": 0.0,
		"roll": 0.0,
		"yaw": 0.0,
	}
	var cadence_offset := float(member_index) * 0.72
	if role == "leader":
		cadence_offset += 0.24
	elif role == "alpha":
		cadence_offset += 0.38
	elif role == "sentry":
		cadence_offset += 0.54
	var stride_phase := phase * (0.9 + travel_speed * 0.8) + cadence_offset
	var stride_wave := sin(stride_phase * 1.8)
	var counter_wave := cos(stride_phase * 1.4 + float(member_index) * 0.45)
	var idle_wave := sin(stride_phase * 0.46 + float(member_index) * 1.12)
	var idle_counter := cos(stride_phase * 0.38 + float(member_index) * 0.84)
	var watch_wave := sin(stride_phase * 0.22 + float(member_index) * 0.58)
	var watch_phase := clampf(watch_wave * 0.5 + 0.5, 0.0, 1.0)
	match category:
		"草食动物":
			if travel_speed > 0.18:
				profile["y_offset"] = 0.018 * stride_wave * travel_speed
				profile["z_offset"] = 0.026 * counter_wave * travel_speed
				profile["pitch"] = 0.028 * stride_wave * travel_speed
			elif not alerted:
				var graze_bias := clampf(idle_wave * 0.5 + 0.5, 0.0, 1.0)
				var graze_slot := int(floor(fmod(abs(stride_phase * 0.18 + float(member_index)), 3.0)))
				if graze_slot != 1:
					profile["y_offset"] = -0.02 * graze_bias
					profile["z_offset"] = 0.02 * graze_bias
					profile["pitch"] = -0.06 - 0.025 * graze_bias
				else:
					profile["y_offset"] = 0.008 * idle_counter
					profile["pitch"] = -0.01 + 0.018 * idle_counter
					profile["yaw"] = 0.06 * idle_wave + 0.03 * (watch_phase - 0.5)
			if role == "leader":
				profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.012
				profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.05 * sin(stride_phase * 0.34 + 0.3)
				if travel_speed < 0.16 and not alerted:
					profile["pitch"] = maxf(float(profile.get("pitch", 0.0)), -0.01 + 0.012 * idle_counter)
		"掠食者":
			profile["y_offset"] = 0.008 * stride_wave * maxf(0.4, travel_speed)
			profile["z_offset"] = -0.02 * abs(counter_wave) * maxf(0.4, travel_speed)
			profile["pitch"] = 0.036 * maxf(0.45, travel_speed) - 0.014 * abs(stride_wave)
			if behavior == "stalk":
				profile["y_offset"] = -0.012 - 0.008 * abs(stride_wave)
				profile["pitch"] = 0.05 + 0.014 * abs(counter_wave)
				profile["roll"] = 0.012 * stride_wave
				profile["yaw"] = 0.035 * sin(stride_phase * 0.42 + float(member_index) * 0.25)
			elif not alerted and travel_speed < 0.2:
				profile["y_offset"] = -0.01 + 0.005 * idle_wave
				profile["z_offset"] = -0.012 + 0.008 * idle_counter
				profile["pitch"] = 0.028 + 0.012 * idle_counter
				profile["roll"] = 0.008 * idle_wave
				var sweep_sign := -1.0 if member_index % 2 == 0 else 1.0
				profile["yaw"] = sweep_sign * 0.045 * idle_wave
			if role == "alpha":
				profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.016
				profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.035 * sin(stride_phase * 0.3)
		"飞行动物":
			profile["y_offset"] = 0.048 * sin(stride_phase * 1.2 + float(member_index) * 0.3)
			profile["z_offset"] = 0.018 * counter_wave
			profile["pitch"] = -0.026 + 0.012 * stride_wave
			profile["roll"] = 0.022 * stride_wave
			if not alerted and signal_timer <= 0.0:
				profile["y_offset"] = 0.034 * sin(stride_phase * 0.88 + float(member_index) * 0.24)
				profile["z_offset"] = 0.012 * idle_counter
				profile["pitch"] = -0.038 + 0.008 * idle_wave
				profile["roll"] = 0.014 * idle_wave
				profile["yaw"] = 0.038 * sin(stride_phase * 0.36 + float(member_index) * 0.2)
				if member_index > 0:
					profile["y_offset"] = float(profile.get("y_offset", 0.0)) - 0.012 * minf(1.0, float(member_index) * 0.2)
			if role == "sentry":
				profile["y_offset"] = float(profile.get("y_offset", 0.0)) + 0.018
				profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.045 * sin(stride_phase * 0.4)
		"水域动物":
			profile["y_offset"] = 0.006 * stride_wave
			profile["z_offset"] = 0.014 * counter_wave
			profile["pitch"] = 0.01 * counter_wave
			profile["roll"] = 0.008 * stride_wave
			if not alerted and travel_speed < 0.16:
				profile["y_offset"] = 0.004 * idle_wave
				profile["z_offset"] = 0.01 * idle_counter
				profile["pitch"] = 0.006 * idle_counter
				profile["roll"] = 0.004 * idle_wave
				profile["yaw"] = 0.024 * idle_wave
	match species_id:
		"elephant":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) * 0.45
			profile["z_offset"] = float(profile.get("z_offset", 0.0)) * 0.55 - 0.012 * abs(stride_wave)
			profile["pitch"] = float(profile.get("pitch", 0.0)) * 0.72 + 0.012
			if role == "leader" and travel_speed < 0.16:
				profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.026 * sin(stride_phase * 0.22)
		"giraffe":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) * 0.72 + 0.012
			profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.018
			profile["roll"] = float(profile.get("roll", 0.0)) * 0.65
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.018 * sin(stride_phase * 0.18 + 0.4)
		"lion":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) * 0.64 - 0.01 * abs(stride_wave)
			profile["z_offset"] = float(profile.get("z_offset", 0.0)) - 0.018 * abs(counter_wave)
			profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.018
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.024 * sin(stride_phase * 0.24 + float(member_index) * 0.12)
			if role == "alpha":
				profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.022 * sin(stride_phase * 0.18)
		"canid":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) * 0.82
			profile["z_offset"] = float(profile.get("z_offset", 0.0)) - 0.01 * abs(counter_wave)
			profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.012
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.036 * sin(stride_phase * 0.42 + float(member_index) * 0.2)
		"zebra":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) + 0.01 * stride_wave
			profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.008 * stride_wave
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.028 * sin(stride_phase * 0.28 + float(member_index) * 0.16)
		"antelope":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) + 0.014 * stride_wave
			profile["z_offset"] = float(profile.get("z_offset", 0.0)) + 0.012 * counter_wave
			profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.012
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.042 * sin(stride_phase * 0.52 + float(member_index) * 0.26)
		"hippo":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) * 0.42
			profile["z_offset"] = float(profile.get("z_offset", 0.0)) * 0.48
			profile["pitch"] = float(profile.get("pitch", 0.0)) * 0.52
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.014 * sin(stride_phase * 0.18)
		"crocodile":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) * 0.28
			profile["z_offset"] = float(profile.get("z_offset", 0.0)) * 0.6
			profile["pitch"] = float(profile.get("pitch", 0.0)) * 0.4 - 0.012
			profile["roll"] = float(profile.get("roll", 0.0)) * 0.45
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.012 * sin(stride_phase * 0.16)
		"bird":
			profile["y_offset"] = float(profile.get("y_offset", 0.0)) + 0.022 * sin(stride_phase * 2.2 + float(member_index) * 0.34)
			profile["pitch"] = float(profile.get("pitch", 0.0)) - 0.016 + 0.014 * stride_wave
			profile["roll"] = float(profile.get("roll", 0.0)) + 0.02 * counter_wave
			profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.028 * sin(stride_phase * 0.52)
			if role == "sentry":
				profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.02 * sin(stride_phase * 0.32)
			elif member_index > 0:
				profile["yaw"] = float(profile.get("yaw", 0.0)) - 0.012 * minf(1.0, float(member_index) * 0.2)
	if member_index == 0 and role in ["leader", "alpha", "sentry"]:
		profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.01
		profile["z_offset"] = float(profile.get("z_offset", 0.0)) + 0.012
		profile["yaw"] = float(profile.get("yaw", 0.0)) + 0.02 * sin(stride_phase * 0.46 + 0.2)
	if look_back:
		profile["y_offset"] = float(profile.get("y_offset", 0.0)) * 0.7
		profile["pitch"] = float(profile.get("pitch", 0.0)) * 0.45
		profile["yaw"] = float(profile.get("yaw", 0.0)) * 0.4
	if signal_timer > 0.0:
		profile["y_offset"] = float(profile.get("y_offset", 0.0)) + minf(0.03, signal_timer * 0.03)
	return profile


func _animal_member_spacing_offset(species_id: String, category: String, role: String, member_index: int, offset: Vector3) -> Vector3:
	var adjusted := Vector3.ZERO
	var rank := float(member_index / 2)
	match species_id:
		"african_elephant":
			adjusted.x += sign(offset.x) * (0.08 + rank * 0.04)
			adjusted.z -= rank * 0.08
		"giraffe":
			adjusted.x += sign(offset.x) * (0.06 + rank * 0.03)
			adjusted.z -= rank * 0.06
		"hippopotamus":
			adjusted.x += sign(offset.x) * (0.05 + rank * 0.025)
			adjusted.z -= rank * 0.05
		"nile_crocodile":
			adjusted.x -= sign(offset.x) * 0.02
			adjusted.z -= rank * 0.03
		"zebra":
			adjusted.x += sign(offset.x) * 0.015
		"antelope", "deer":
			adjusted.x -= sign(offset.x) * 0.012
			adjusted.z += rank * 0.015
		"lion":
			if role != "alpha":
				adjusted.x -= sign(offset.x) * 0.02
				adjusted.z += rank * 0.012
		"hyena", "wolf", "fox":
			adjusted.x -= sign(offset.x) * 0.028
			adjusted.z += rank * 0.018
		"bird", "vulture", "eagle", "owl", "duck", "sparrow", "kingfisher_v4", "woodpecker", "bat_v4":
			adjusted.y += maxf(0.0, rank) * 0.02
			adjusted.z -= rank * 0.026
			if role == "sentry":
				adjusted.y += 0.03
			elif member_index > 0:
				adjusted.y -= minf(0.04, float(member_index) * 0.01)
	match category:
		"飞行动物":
			adjusted.y += rank * 0.008
		"草食动物":
			adjusted.x += sign(offset.x) * rank * 0.006
		"掠食者":
			adjusted.z -= rank * 0.012
	return adjusted


func _animal_attention_data(animal: Dictionary, encounter_match: bool, spotlight_match: bool) -> Dictionary:
	var species_id := str(animal.get("species_id", ""))
	var role := str(animal.get("role", "member"))
	var category := str(animal.get("category", "区域生物"))
	var anchor_id := str(animal.get("anchor_id", ""))
	if bool(animal.get("look_back", false)) or bool(animal.get("alerted", false)):
		return {"target": _player_vec2(), "mode": "player"}
	if category == "掠食者":
		if not current_chase.is_empty():
			return {"target": Vector2(current_chase.get("target", Vector2.ZERO)), "mode": "chase"}
		if not current_chase_result.is_empty():
			return {"target": Vector2(current_chase_result.get("target", Vector2.ZERO)), "mode": "aftermath"}
		if role != "alpha":
			var alpha_pos := _role_anchor_position(anchor_id, category, "alpha")
			if alpha_pos != Vector2.ZERO:
				return {"target": alpha_pos, "mode": "pack"}
	if current_exit_zone.has("id") and (role in ["leader", "alpha", "sentry"] or _gate_focus_hold_strength() > 0.42):
		var gate_pos: Vector3 = _gate_focus_point(str(current_exit_zone.get("id", "")))
		return {"target": Vector2(gate_pos.x, gate_pos.z), "mode": "exit"}
	if spotlight_match and not current_hotspot.is_empty():
		var hotspot_pos := _hotspot_pos(str(current_hotspot.get("hotspot_id", "")))
		return {"target": Vector2(hotspot_pos.x, hotspot_pos.z), "mode": "hotspot"}
	if encounter_match:
		return {"target": _player_vec2(), "mode": "player"}
	if category == "草食动物":
		if role == "leader" and animal.has("escort_target"):
			return {"target": Vector2(animal.get("escort_target", Vector2.ZERO)), "mode": "route"}
		if role != "leader":
			var leader_pos := _role_anchor_position(anchor_id, category, "leader")
			if leader_pos != Vector2.ZERO:
				return {"target": leader_pos, "mode": "herd"}
	if category == "飞行动物":
		if role == "sentry":
			if not current_hotspot.is_empty():
				var sentry_hotspot := _hotspot_pos(str(current_hotspot.get("hotspot_id", "")))
				return {"target": Vector2(sentry_hotspot.x, sentry_hotspot.z), "mode": "hotspot"}
			if current_exit_zone.has("id"):
				var sentry_gate: Vector3 = _gate_focus_point(str(current_exit_zone.get("id", "")))
				return {"target": Vector2(sentry_gate.x, sentry_gate.z), "mode": "exit"}
		else:
			var sentry_pos := _role_anchor_position(anchor_id, category, "sentry")
			if sentry_pos != Vector2.ZERO:
				return {"target": sentry_pos, "mode": "flight"}
	if category == "水域动物":
		var water_focus := _hotspot_pos("waterhole")
		return {"target": Vector2(water_focus.x, water_focus.z), "mode": "water"}
	if species_id == "giraffe" and role == "leader":
		return {"target": _player_vec2(), "mode": "player"}
	return {"target": Vector2.ZERO, "mode": "idle"}


func _animal_attention_yaw(pos2: Vector2, root_yaw: float, target: Vector2) -> float:
	if target == Vector2.ZERO:
		return 0.0
	var delta := target - pos2
	if delta.length() < 0.08:
		return 0.0
	return clampf(atan2(delta.x, delta.y) - root_yaw, -0.12, 0.12)


func _animal_attention_distance_response(pos2: Vector2, target: Vector2, mode: String, species_id: String, category: String, role: String) -> Dictionary:
	var profile := {
		"yaw_scale": 1.0,
		"head_lerp": 1.0,
		"body_lerp": 1.0,
		"attention_acquire_lerp": 1.0,
		"attention_release_lerp": 1.0,
		"scan_weight": 1.0,
		"target_strength": 0.0,
	}
	if target == Vector2.ZERO:
		return profile
	var focus_range := 7.0
	match mode:
		"player":
			focus_range = 10.0
		"chase":
			focus_range = 11.5
		"exit":
			focus_range = 12.5
		"aftermath":
			focus_range = 9.0
		"pack", "herd", "flight":
			focus_range = 5.2
		"route", "water":
			focus_range = 6.0
	var distance := pos2.distance_to(target)
	var proximity := clampf(1.0 - distance / focus_range, 0.0, 1.0)
	profile["target_strength"] = proximity
	profile["yaw_scale"] = lerpf(0.74, 1.08, proximity)
	profile["head_lerp"] = lerpf(0.88, 1.14, proximity)
	profile["body_lerp"] = lerpf(0.82, 1.04, proximity)
	profile["attention_acquire_lerp"] = lerpf(0.84, 1.18, proximity)
	profile["attention_release_lerp"] = lerpf(1.06, 0.82, proximity)
	profile["scan_weight"] = lerpf(1.12, 0.52, proximity)
	match mode:
		"player", "chase":
			profile["yaw_scale"] = lerpf(0.92, 1.16, proximity)
			profile["head_lerp"] = lerpf(0.96, 1.18, proximity)
			profile["body_lerp"] = lerpf(0.9, 1.06, proximity)
			profile["attention_acquire_lerp"] = lerpf(0.96, 1.22, proximity)
			profile["attention_release_lerp"] = lerpf(0.98, 0.76, proximity)
			profile["scan_weight"] = lerpf(0.92, 0.36, proximity)
		"exit":
			profile["yaw_scale"] = lerpf(0.84, 1.08, proximity)
			profile["head_lerp"] = lerpf(0.94, 1.1, proximity)
			profile["body_lerp"] = lerpf(0.88, 1.02, proximity)
			profile["attention_acquire_lerp"] = lerpf(0.92, 1.14, proximity)
			profile["attention_release_lerp"] = lerpf(1.02, 0.82, proximity)
			profile["scan_weight"] = lerpf(0.98, 0.46, proximity)
		"hotspot", "route", "water":
			profile["yaw_scale"] = lerpf(0.68, 0.96, proximity)
			profile["head_lerp"] = lerpf(0.82, 1.02, proximity)
			profile["body_lerp"] = lerpf(0.76, 0.92, proximity)
			profile["attention_acquire_lerp"] = lerpf(0.76, 0.98, proximity)
			profile["attention_release_lerp"] = lerpf(1.1, 0.92, proximity)
			profile["scan_weight"] = lerpf(1.18, 0.68, proximity)
		"pack", "herd", "flight":
			profile["yaw_scale"] = lerpf(0.62, 0.88, proximity)
			profile["head_lerp"] = lerpf(0.8, 0.96, proximity)
			profile["body_lerp"] = lerpf(0.74, 0.88, proximity)
			profile["attention_acquire_lerp"] = lerpf(0.72, 0.9, proximity)
			profile["attention_release_lerp"] = lerpf(1.14, 0.98, proximity)
			profile["scan_weight"] = lerpf(1.22, 0.8, proximity)
	if role in ["leader", "alpha", "sentry"]:
		profile["head_lerp"] = float(profile.get("head_lerp", 1.0)) * 1.04
		profile["attention_acquire_lerp"] = float(profile.get("attention_acquire_lerp", 1.0)) * 1.06
		profile["scan_weight"] = float(profile.get("scan_weight", 1.0)) * 0.94
	match species_id:
		"african_elephant", "hippopotamus":
			profile["body_lerp"] = float(profile.get("body_lerp", 1.0)) * 0.84
			profile["attention_release_lerp"] = float(profile.get("attention_release_lerp", 1.0)) * 1.04
		"giraffe":
			profile["head_lerp"] = float(profile.get("head_lerp", 1.0)) * 1.08
		"antelope", "deer", "hyena", "wolf", "fox":
			profile["head_lerp"] = float(profile.get("head_lerp", 1.0)) * 1.06
			profile["attention_acquire_lerp"] = float(profile.get("attention_acquire_lerp", 1.0)) * 1.08
	match category:
		"飞行动物":
			profile["scan_weight"] = float(profile.get("scan_weight", 1.0)) * 1.04
			profile["body_lerp"] = float(profile.get("body_lerp", 1.0)) * 0.92
		"掠食者":
			profile["scan_weight"] = float(profile.get("scan_weight", 1.0)) * 0.94
		"草食动物":
			profile["attention_release_lerp"] = float(profile.get("attention_release_lerp", 1.0)) * 1.04
	return profile


func _animal_attention_response_profile(species_id: String, category: String, role: String, member_index: int) -> Dictionary:
	var profile := {
		"yaw_scale": 1.0,
		"head_lerp": 1.0,
		"body_lerp": 1.0,
		"attention_acquire_lerp": 0.2,
		"attention_release_lerp": 0.08,
	}
	var rank := float(member_index / 2)
	if role in ["leader", "alpha", "sentry"] or member_index == 0:
		profile["yaw_scale"] = 1.0
		profile["head_lerp"] = 1.0
		profile["body_lerp"] = 1.0
		profile["attention_acquire_lerp"] = 0.24
		profile["attention_release_lerp"] = 0.1
	else:
		profile["yaw_scale"] = maxf(0.34, 0.7 - rank * 0.12)
		profile["head_lerp"] = maxf(0.46, 0.76 - rank * 0.12)
		profile["body_lerp"] = maxf(0.3, 0.5 - rank * 0.1)
		profile["attention_acquire_lerp"] = maxf(0.06, 0.12 - rank * 0.02)
		profile["attention_release_lerp"] = maxf(0.025, 0.05 - rank * 0.008)
	match category:
		"草食动物":
			profile["body_lerp"] = float(profile.get("body_lerp", 1.0)) * 0.92
			profile["attention_release_lerp"] = float(profile.get("attention_release_lerp", 0.08)) * 0.86
		"掠食者":
			profile["yaw_scale"] = float(profile.get("yaw_scale", 1.0)) * 1.04
			profile["body_lerp"] = float(profile.get("body_lerp", 1.0)) * 1.02
			profile["attention_acquire_lerp"] = float(profile.get("attention_acquire_lerp", 0.2)) * 1.08
		"飞行动物":
			profile["head_lerp"] = float(profile.get("head_lerp", 1.0)) * 1.06
			profile["body_lerp"] = float(profile.get("body_lerp", 1.0)) * 0.9
			profile["attention_release_lerp"] = float(profile.get("attention_release_lerp", 0.08)) * 0.78
	match species_id:
		"african_elephant", "hippopotamus":
			profile["body_lerp"] = float(profile.get("body_lerp", 1.0)) * 0.82
			profile["attention_acquire_lerp"] = float(profile.get("attention_acquire_lerp", 0.2)) * 0.82
		"giraffe":
			profile["head_lerp"] = float(profile.get("head_lerp", 1.0)) * 1.08
		"antelope", "deer", "hyena", "wolf", "fox":
			profile["head_lerp"] = float(profile.get("head_lerp", 1.0)) * 1.06
			profile["yaw_scale"] = float(profile.get("yaw_scale", 1.0)) * 1.04
			profile["attention_acquire_lerp"] = float(profile.get("attention_acquire_lerp", 0.2)) * 1.08
	return profile


func _animal_attention_mode_response(mode: String) -> Dictionary:
	var profile := {
		"yaw_scale": 1.0,
		"head_lerp": 1.0,
		"body_lerp": 1.0,
		"attention_acquire_lerp": 1.0,
		"attention_release_lerp": 1.0,
		"scan_weight": 1.0,
	}
	match mode:
		"player":
			profile["yaw_scale"] = 1.1
			profile["head_lerp"] = 1.08
			profile["body_lerp"] = 1.04
			profile["attention_acquire_lerp"] = 1.12
			profile["attention_release_lerp"] = 0.78
			profile["scan_weight"] = 0.72
		"chase":
			profile["yaw_scale"] = 1.18
			profile["head_lerp"] = 1.12
			profile["body_lerp"] = 1.08
			profile["attention_acquire_lerp"] = 1.18
			profile["attention_release_lerp"] = 0.8
			profile["scan_weight"] = 0.64
		"exit":
			profile["yaw_scale"] = 1.06
			profile["head_lerp"] = 1.04
			profile["body_lerp"] = 1.02
			profile["attention_acquire_lerp"] = 1.08
			profile["attention_release_lerp"] = 0.82
			profile["scan_weight"] = 0.78
		"hotspot":
			profile["yaw_scale"] = 0.96
			profile["head_lerp"] = 0.98
			profile["body_lerp"] = 0.92
			profile["attention_acquire_lerp"] = 0.96
			profile["attention_release_lerp"] = 0.9
			profile["scan_weight"] = 0.9
		"aftermath":
			profile["yaw_scale"] = 0.9
			profile["head_lerp"] = 0.94
			profile["body_lerp"] = 0.88
			profile["attention_acquire_lerp"] = 0.92
			profile["attention_release_lerp"] = 0.72
			profile["scan_weight"] = 0.86
		"pack", "herd", "flight":
			profile["yaw_scale"] = 0.82
			profile["head_lerp"] = 0.9
			profile["body_lerp"] = 0.84
			profile["attention_acquire_lerp"] = 0.84
			profile["attention_release_lerp"] = 0.96
			profile["scan_weight"] = 0.94
		"route", "water":
			profile["yaw_scale"] = 0.78
			profile["head_lerp"] = 0.88
			profile["body_lerp"] = 0.82
			profile["attention_acquire_lerp"] = 0.82
			profile["attention_release_lerp"] = 1.02
			profile["scan_weight"] = 0.98
	return profile


func _apply_member_locomotion(member: Node3D, species_id: String, category: String, behavior: String, role: String, member_index: int, phase: float, travel_speed: float, alerted: bool, signal_timer: float) -> void:
	var body_rig := _member_body_rig(member)
	if body_rig != null and not body_rig.has_meta("base_position"):
		body_rig.set_meta("base_position", body_rig.position)
	if body_rig != null and not body_rig.has_meta("locomotion_pitch"):
		body_rig.set_meta("locomotion_pitch", 0.0)
	var move_weight := clampf(travel_speed * 1.85 + (0.3 if alerted else 0.0), 0.0, 1.0)
	if travel_speed > 0.04:
		move_weight = maxf(move_weight, 0.2)
	var gait_speed := lerpf(2.8, 9.2, move_weight)
	var swing_amp := lerpf(0.16, 0.98, move_weight)
	var knee_amp := lerpf(0.14, 1.08, move_weight)
	var stride_offset := lerpf(0.01, 0.12, move_weight)
	var leg_lift_scale := lerpf(0.0, 0.34, move_weight)
	match category:
		"草食动物":
			gait_speed *= 0.92
			swing_amp *= 1.08
			leg_lift_scale *= 1.02
		"掠食者":
			gait_speed *= 1.08
			swing_amp *= 0.94
			knee_amp *= 0.88
			stride_offset *= 1.08
		"飞行动物":
			gait_speed *= 1.18
			swing_amp *= 0.28
			knee_amp *= 0.16
			leg_lift_scale *= 0.28
			stride_offset *= 0.36
		"水域动物":
			gait_speed *= 0.68
			swing_amp *= 0.18
			knee_amp *= 0.1
			leg_lift_scale *= 0.18
			stride_offset *= 0.22
	match species_id:
		"african_elephant", "hippopotamus":
			gait_speed *= 0.72
			swing_amp *= 0.72
			knee_amp *= 0.62
			leg_lift_scale *= 0.74
		"giraffe":
			gait_speed *= 0.82
			swing_amp *= 1.06
			stride_offset *= 1.18
		"antelope", "deer":
			gait_speed *= 1.16
			swing_amp *= 1.18
			leg_lift_scale *= 1.12
		"hyena", "wolf", "fox":
			gait_speed *= 1.12
			swing_amp *= 1.06
			stride_offset *= 1.12
		"nile_crocodile":
			gait_speed *= 0.62
			swing_amp *= 0.16
			knee_amp *= 0.08
			leg_lift_scale *= 0.12
	if role in ["leader", "alpha", "sentry"]:
		swing_amp *= 1.04
	var cadence := elapsed_time() * gait_speed + phase * 0.34 + float(member_index) * 0.38
	var body_bob := sin(cadence * 2.0) * lerpf(0.0, 0.075, move_weight)
	var body_pitch := sin(cadence) * lerpf(0.0, 0.08, move_weight)
	var body_sway := sin(cadence + PI * 0.5) * lerpf(0.0, 0.045, move_weight)
	if body_rig != null:
		var base_body_pos: Vector3 = body_rig.get_meta("base_position", body_rig.position)
		var previous_pitch := float(body_rig.get_meta("locomotion_pitch", 0.0))
		body_rig.position = body_rig.position.lerp(base_body_pos + Vector3(0.0, body_bob, body_sway * 0.08), 0.22)
		body_rig.rotation.x += (body_pitch - previous_pitch) * 0.42
		body_rig.set_meta("locomotion_pitch", body_pitch)
	for leg_name in ["FrontLeft", "FrontRight", "BackLeft", "BackRight"]:
		var leg_rig := _member_leg_rig(member, leg_name)
		if leg_rig == null:
			continue
		var knee := leg_rig.get_node_or_null("Knee") as Node3D
		var base_leg_pos: Vector3 = leg_rig.get_meta("base_position", leg_rig.position)
		var base_knee_pos := Vector3.ZERO
		if knee != null:
			base_knee_pos = knee.get_meta("base_position", knee.position)
		var phase_sign := 1.0 if leg_name in ["FrontLeft", "BackRight"] else -1.0
		if leg_name.begins_with("Back"):
			phase_sign *= -1.0
		var swing_wave := sin(cadence * phase_sign)
		var lift_wave := maxf(0.0, sin(cadence * phase_sign + PI * 0.5))
		var stride_bias := 0.0
		if behavior == "stalk":
			stride_bias = 0.06
		elif behavior == "glide":
			stride_bias = -0.02
		var target_leg_x := swing_wave * swing_amp + stride_bias
		var target_knee_x := -lift_wave * knee_amp
		if move_weight < 0.08:
			target_leg_x = lerpf(target_leg_x, 0.04 * sin(cadence * 0.3 + phase_sign), 0.84)
			target_knee_x = lerpf(target_knee_x, -0.05 * maxf(0.0, sin(cadence * 0.24 + phase_sign)), 0.88)
		var stride_z := swing_wave * stride_offset * (1.0 if leg_name.begins_with("Front") else -1.0)
		var leg_lift := lift_wave * leg_lift_scale
		leg_rig.position = leg_rig.position.lerp(base_leg_pos + Vector3(0.0, leg_lift, stride_z), 0.24)
		leg_rig.rotation.x = lerpf(leg_rig.rotation.x, target_leg_x, 0.18)
		if knee != null:
			knee.position = knee.position.lerp(base_knee_pos + Vector3(0.0, leg_lift * 0.58, stride_z * 0.28), 0.24)
			knee.rotation.x = lerpf(knee.rotation.x, target_knee_x, 0.2)


func _animal_attention_pose_profile(species_id: String, category: String, role: String, mode: String, member_index: int, phase: float) -> Dictionary:
	var profile := {"yaw": 0.0, "pitch": 0.0}
	match mode:
		"player":
			profile["pitch"] = 0.028
			profile["yaw"] = 0.018 * sin(phase * 0.42 + float(member_index) * 0.2)
		"hotspot":
			profile["pitch"] = -0.012
		"exit":
			profile["pitch"] = 0.016
		"chase":
			profile["pitch"] = 0.038
		"aftermath":
			profile["pitch"] = -0.008
			profile["yaw"] = 0.012 * sin(phase * 0.3)
		"pack", "herd", "flight":
			profile["yaw"] = 0.01 * sin(phase * 0.26 + float(member_index) * 0.16)
		"route", "water":
			profile["pitch"] = -0.006
	match category:
		"掠食者":
			if mode in ["chase", "player"]:
				profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.012
		"草食动物":
			if mode in ["player", "exit"]:
				profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.01
		"飞行动物":
			profile["pitch"] = float(profile.get("pitch", 0.0)) - 0.01
	match species_id:
		"giraffe":
			profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.014
		"crocodile", "hippopotamus":
			profile["pitch"] = float(profile.get("pitch", 0.0)) * 0.56
		"bird":
			profile["yaw"] = float(profile.get("yaw", 0.0)) * 1.18
	if role in ["leader", "alpha", "sentry"]:
		profile["pitch"] = float(profile.get("pitch", 0.0)) + 0.006
	return profile


func _animal_attention_scan_profile(species_id: String, category: String, role: String, member_index: int, phase: float) -> Dictionary:
	var yaw_amp := 0.014
	var pitch_amp := 0.008
	var yaw_speed := 0.42
	var pitch_speed := 0.34
	match category:
		"草食动物":
			yaw_amp = 0.022
			pitch_amp = 0.012
			yaw_speed = 0.34
			pitch_speed = 0.28
		"掠食者":
			yaw_amp = 0.016
			pitch_amp = 0.01
			yaw_speed = 0.26
			pitch_speed = 0.22
		"飞行动物":
			yaw_amp = 0.028
			pitch_amp = 0.014
			yaw_speed = 0.48
			pitch_speed = 0.36
		"水域动物":
			yaw_amp = 0.01
			pitch_amp = 0.006
			yaw_speed = 0.18
			pitch_speed = 0.16
	match role:
		"leader":
			yaw_amp *= 1.12
		"alpha":
			yaw_amp *= 0.78
			pitch_amp *= 0.82
		"sentry":
			yaw_amp *= 1.22
			pitch_amp *= 1.12
	match species_id:
		"giraffe":
			yaw_amp *= 1.18
			pitch_amp *= 1.16
		"elephant", "hippopotamus":
			yaw_amp *= 0.72
			pitch_amp *= 0.78
		"lion":
			yaw_amp *= 0.82
		"hyena", "wolf", "fox", "antelope", "deer":
			yaw_amp *= 1.12
		"bird":
			yaw_amp *= 1.18
			pitch_amp *= 1.08
	var scan_phase := phase + float(member_index) * 0.64
	return {
		"yaw": sin(scan_phase * yaw_speed) * yaw_amp,
		"pitch": cos(scan_phase * pitch_speed) * pitch_amp,
	}


func _member_meta_lerpf(member: Node3D, key: String, target: float, rate: float) -> float:
	var current := 0.0
	if member.has_meta(key):
		current = float(member.get_meta(key, 0.0))
	current = lerpf(current, target, clampf(rate, 0.0, 1.0))
	member.set_meta(key, current)
	return current


func _ensure_member_focus_rigs(member: Node3D) -> Dictionary:
	if member.has_meta("focus_rigs"):
		return member.get_meta("focus_rigs", {})
	if bool(member.get_meta("asset_display_only", false)):
		var display_rig := member.get_node_or_null("DisplayRig") as Node3D
		if display_rig != null:
			var display_rigs := {"body": display_rig, "head": null}
			member.set_meta("focus_rigs", display_rigs)
			return display_rigs
		return {}
	var existing_body := member.get_node_or_null("BodyRig") as Node3D
	var existing_head := member.get_node_or_null("HeadRig") as Node3D
	if existing_body != null or existing_head != null:
		if existing_body == null:
			existing_body = existing_head
		if existing_head == null:
			existing_head = existing_body
		var existing_rigs := {"body": existing_body, "head": existing_head}
		member.set_meta("focus_rigs", existing_rigs)
		return existing_rigs
	var body_rig := Node3D.new()
	body_rig.name = "BodyRig"
	member.add_child(body_rig)
	var head_rig := Node3D.new()
	head_rig.name = "HeadRig"
	member.add_child(head_rig)
	for child in member.get_children():
		var part := child as Node3D
		if part == null or part == body_rig or part == head_rig:
			continue
		var local_transform := part.transform
		member.remove_child(part)
		var target := body_rig
		if _is_head_part_candidate(part.position):
			target = head_rig
		target.add_child(part)
		part.transform = local_transform
	var rigs := {"body": body_rig, "head": head_rig}
	member.set_meta("focus_rigs", rigs)
	return rigs


func _is_head_part_candidate(local_pos: Vector3) -> bool:
	if local_pos.z > 0.3:
		return true
	if local_pos.z > 0.14 and local_pos.y > 0.72:
		return true
	return false


func _animal_motion_step_limit(behavior: String, category: String, alerted: bool, role: String) -> float:
	var step := 0.26
	match behavior:
		"stalk":
			step = 0.24
		"glide":
			step = 0.2
		"swim":
			step = 0.16
		"heavy_roam":
			step = 0.14
		_:
			step = 0.22
	if category == "飞行动物":
		step *= 0.92
	elif category == "水域动物":
		step *= 0.78
	elif category == "掠食者":
		step *= 1.02
	if role in ["leader", "alpha"]:
		step *= 1.06
	if alerted:
		step *= 1.18
	return step


func _update_camera(force: bool) -> void:
	if camera_node == null or player_body == null:
		return
	var motion_profile := _biome_player_motion_profile()
	var stage_motion := _route_stage_motion_profile()
	if not pending_gate_transition.is_empty():
		var reentry_profile := _route_stage_reentry_profile()
		var direction := Vector3(pending_gate_transition.get("direction", Vector3(0.0, 0.0, -1.0)))
		var duration := maxf(0.001, float(pending_gate_transition.get("duration", 1.0)))
		var timer := float(pending_gate_transition.get("timer", 0.0))
		var progress := clampf(1.0 - timer / duration, 0.0, 1.0)
		var camera_pull := float(reentry_profile.get("camera_pull", 1.0))
		var gate_look := player_body.global_position + direction * ((2.4 + progress * 1.8) * camera_pull)
		var target_pos := player_body.global_position + CAMERA_OFFSET * 0.82 - direction * (1.4 * camera_pull) + Vector3(0.0, float(reentry_profile.get("camera_height", 0.5)), 0.0)
		if force:
			camera_node.global_position = target_pos
		else:
			camera_node.global_position = camera_node.global_position.lerp(target_pos, 0.09)
		camera_node.fov = lerpf(camera_node.fov, float(reentry_profile.get("gate_fov", 48.0)), 0.12)
		camera_node.look_at(gate_look + Vector3(0.0, 1.4, 0.0), Vector3.UP)
		return
	if not pending_arrival_intro.is_empty():
		var reentry_profile := _route_stage_reentry_profile()
		var direction := Vector3(pending_arrival_intro.get("direction", Vector3(0.0, 0.0, 1.0)))
		var duration := maxf(0.001, float(pending_arrival_intro.get("duration", 1.0)))
		var timer := float(pending_arrival_intro.get("timer", 0.0))
		var progress := clampf(1.0 - timer / duration, 0.0, 1.0)
		var camera_pull := float(reentry_profile.get("camera_pull", 1.0))
		var arrival_look := player_body.global_position + direction * ((2.0 + progress * 1.3) * camera_pull)
		var target_pos := player_body.global_position + CAMERA_OFFSET * 0.9 - direction * (1.0 * camera_pull)
		if force:
			camera_node.global_position = target_pos
		else:
			camera_node.global_position = camera_node.global_position.lerp(target_pos, 0.08)
		camera_node.fov = lerpf(camera_node.fov, float(reentry_profile.get("arrival_fov", 49.0)), 0.1)
		camera_node.look_at(arrival_look + Vector3(0.0, 1.35, 0.0), Vector3.UP)
		return
	var planar_velocity := Vector3(player_body.velocity.x, 0.0, player_body.velocity.z)
	var desired_look_ahead := planar_velocity * float(motion_profile.get("camera_look_ahead", 0.3)) * float(stage_motion.get("camera_look_scale", 1.0))
	var desired_focus_target := player_body.global_position + CAMERA_LOOK_OFFSET * float(motion_profile.get("camera_look_height", 1.0))
	var desired_focus_anchor := player_body.global_position
	if not current_route_focus.is_empty():
		desired_focus_anchor = Vector3(current_route_focus.get("position", player_body.global_position))
	if not route_focus_ready:
		smoothed_route_focus = desired_focus_anchor
		route_focus_ready = true
	smoothed_route_focus = smoothed_route_focus.lerp(desired_focus_anchor, 0.1 + current_speed_ratio * 0.06)
	var focus_delta := smoothed_route_focus - player_body.global_position
	var focus_distance := Vector2(focus_delta.x, focus_delta.z).length()
	var focus_pull := clampf(1.0 - focus_distance / 28.0, 0.0, 1.0)
	if focus_pull > 0.0:
		desired_focus_target = desired_focus_target.lerp(smoothed_route_focus + Vector3(0.0, CAMERA_LOOK_OFFSET.y, 0.0), focus_pull * 0.26)
	var gate_focus_hold_target := _gate_focus_hold_strength()
	if force:
		smoothed_gate_focus_hold = gate_focus_hold_target
	else:
		smoothed_gate_focus_hold = lerpf(smoothed_gate_focus_hold, gate_focus_hold_target, 0.12 + current_speed_ratio * 0.04)
	var gate_focus_hold := smoothed_gate_focus_hold
	var player_pos2 := _player_vec2()
	if gate_focus_hold > 0.0:
		var gate_focus_point := player_body.global_position + _gate_focus_center_offset()
		desired_focus_target = desired_focus_target.lerp(gate_focus_point + Vector3(0.0, CAMERA_LOOK_OFFSET.y, 0.0), clampf(gate_focus_hold * 0.9, 0.0, 0.92))
	elif not current_exit_zone.is_empty():
		var exit_pos3 := Vector3(current_exit_zone.get("position", Vector3.ZERO))
		var exit_distance := player_pos2.distance_to(Vector2(exit_pos3.x, exit_pos3.z))
		var exit_bias := clampf(1.0 - exit_distance / 20.0, 0.0, 1.0)
		desired_focus_target = desired_focus_target.lerp(exit_pos3 + Vector3(0.0, CAMERA_LOOK_OFFSET.y * 0.82, 0.0), exit_bias * 0.2)
	elif not current_hotspot.is_empty():
		var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
		var hotspot_pos3 := _hotspot_pos(hotspot_id)
		var hotspot_distance := player_pos2.distance_to(Vector2(hotspot_pos3.x, hotspot_pos3.z))
		var hotspot_bias := clampf(1.0 - hotspot_distance / 18.0, 0.0, 1.0)
		desired_focus_target = desired_focus_target.lerp(hotspot_pos3 + Vector3(0.0, CAMERA_LOOK_OFFSET.y * 0.74, 0.0), hotspot_bias * 0.16)
	if force or not camera_look_ready:
		smoothed_camera_look = desired_look_ahead
		camera_look_ready = true
	else:
		var look_lerp := lerpf(0.05, 0.12, clampf(current_speed_ratio / maxf(1.0, SPRINT_MULTIPLIER), 0.0, 1.0))
		smoothed_camera_look = smoothed_camera_look.lerp(desired_look_ahead, look_lerp)
	var look_ahead := smoothed_camera_look
	if force or not camera_focus_target_ready:
		smoothed_camera_focus_target = desired_focus_target
		camera_focus_target_ready = true
	else:
		smoothed_camera_focus_target = smoothed_camera_focus_target.lerp(desired_focus_target + look_ahead * float(motion_profile.get("camera_look_pull", 0.18)) * float(stage_motion.get("camera_look_pull_scale", 1.0)), 0.05)
	camera_zoom = lerpf(camera_zoom, camera_zoom_target, 0.12)
	var sprint_lift := Vector3(0.0, current_speed_ratio * float(motion_profile.get("camera_lift", 0.45)) * float(stage_motion.get("camera_lift_scale", 1.0)), 0.0)
	var orbit_distance := CAMERA_OFFSET.length() * float(motion_profile.get("camera_offset_scale", 1.0)) * float(stage_motion.get("camera_offset_scale", 1.0)) * camera_zoom
	var orbit_horizontal := cos(camera_pitch) * orbit_distance
	var orbit_offset := Vector3(
		sin(camera_yaw) * orbit_horizontal,
		sin(camera_pitch) * orbit_distance,
		cos(camera_yaw) * orbit_horizontal
	)
	var focus_target := smoothed_camera_focus_target
	var target_pos := focus_target + orbit_offset + sprint_lift
	var space_state := get_world_3d().direct_space_state
	var camera_query := PhysicsRayQueryParameters3D.create(focus_target, target_pos)
	camera_query.exclude = [player_body]
	var camera_hit := space_state.intersect_ray(camera_query)
	if not camera_hit.is_empty():
		var hit_position := Vector3(camera_hit.get("position", target_pos))
		var push_dir := (target_pos - focus_target).normalized()
		target_pos = hit_position - push_dir * 0.6 + Vector3(0.0, 0.38, 0.0)
	if force:
		camera_node.global_position = target_pos
	else:
		var base_camera_lerp := float(motion_profile.get("camera_lerp", 0.11)) * float(stage_motion.get("camera_lerp_scale", 1.0))
		var speed_ratio_norm := clampf(current_speed_ratio / maxf(1.0, SPRINT_MULTIPLIER), 0.0, 1.0)
		var speed_camera_lerp := lerpf(base_camera_lerp * 0.68, base_camera_lerp * 1.28, speed_ratio_norm)
		camera_node.global_position = camera_node.global_position.lerp(target_pos, speed_camera_lerp)
	var base_fov_lerp := float(motion_profile.get("fov_lerp", 0.08)) * float(stage_motion.get("fov_lerp_scale", 1.0))
	var speed_fov_lerp := lerpf(base_fov_lerp * 0.82, base_fov_lerp * 1.18, clampf(current_speed_ratio / maxf(1.0, SPRINT_MULTIPLIER), 0.0, 1.0))
	camera_node.fov = lerpf(camera_node.fov, (float(motion_profile.get("base_fov", 49.0)) + current_speed_ratio * float(motion_profile.get("fov_kick", 2.2))) * float(stage_motion.get("fov_scale", 1.0)), speed_fov_lerp)
	camera_node.look_at(focus_target, Vector3.UP)


func _update_encounter() -> void:
	current_encounter.clear()
	var nearest_distance := 999999.0
	var stage_ecology := _route_stage_ecology_profile()
	var progress_focus := _progress_stage_interaction_focus("encounter")
	var pressure_window := _dynamic_pressure_window()
	var encounter_radius := 2.2 * float(stage_ecology.get("encounter_radius_scale", 1.0)) * progress_focus * float(pressure_window.get("encounter_scale", 1.0)) * _arrival_recommended_focus_boost("encounter")
	for animal in wildlife:
		var pos: Vector2 = animal.get("position", Vector2.ZERO)
		var distance := pos.distance_to(_player_vec2())
		var encounter_boost := _route_focus_channel_boost("encounter", Vector3(pos.x, 0.0, pos.y))
		if distance < encounter_radius * encounter_boost and distance < nearest_distance:
			current_encounter = animal
			nearest_distance = distance
	if not current_encounter.is_empty():
		_record_species_discovery(current_encounter)


func _update_hotspot_focus(delta: float) -> void:
	var previous_hotspot_id := str(current_hotspot.get("hotspot_id", ""))
	current_hotspot.clear()
	var nearest_distance := 999999.0
	var spotlight_profile := _biome_hotspot_spotlight_profile()
	var focus_scale := float(spotlight_profile.get("focus_scale", 1.0))
	var pressure_window := _dynamic_pressure_window()
	var progress_focus := _progress_stage_interaction_focus("hotspot")
	var recommended_focus_kind := _recommended_route_focus_kind()
	var recommended_focus_scale := _recommended_route_focus_scale()
	var entry_screen_scale := _entry_screen_focus_strength()
	var gate_focus_scale := _gate_focus_competition_scale("hotspot")
	var hotspot_bias := 1.0
	if recommended_focus_kind in ["entry_route", "trunk_route"]:
		hotspot_bias = lerpf(1.0, 0.9, minf(1.0, maxf(0.0, recommended_focus_scale - 0.96) / 0.22))
	elif recommended_focus_kind == "branch_route":
		hotspot_bias = lerpf(1.0, 1.1, minf(1.0, maxf(0.0, recommended_focus_scale - 0.96) / 0.22))
	elif recommended_focus_kind in ["chokepoint", "route_landmark"]:
		hotspot_bias = lerpf(1.0, 0.88, minf(1.0, maxf(0.0, recommended_focus_scale - 0.96) / 0.22))
	if not pending_arrival_intro.is_empty() and recommended_focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
		hotspot_bias *= 0.9
	for hotspot in hotspots:
		var hotspot_id := str(hotspot.get("hotspot_id", ""))
		var hotspot_window := _dynamic_hotspot_window(hotspot_id)
		var arrival_window_boost := _arrival_hotspot_window_boost(hotspot_id)
		var terminal_chain_boost := _terminal_chain_hotspot_boost(hotspot_id)
		var entry_screen_boost := _entry_screen_hotspot_scale(hotspot_id)
		var center3 := _hotspot_pos(hotspot_id)
		var center2 := Vector2(center3.x, center3.z)
		var distance := center2.distance_to(_player_vec2())
		var route_focus_boost := _route_focus_channel_boost("hotspot", center3)
		if distance < _hotspot_focus_radius(hotspot_id) * focus_scale * float(pressure_window.get("hotspot_scale", 1.0)) * float(hotspot_window.get("reveal_scale", 1.0)) * progress_focus * route_focus_boost * hotspot_bias * arrival_window_boost * terminal_chain_boost * entry_screen_boost * gate_focus_scale and distance < nearest_distance:
			current_hotspot = hotspot
			nearest_distance = distance
	if not current_hotspot.is_empty():
		_record_hotspot_discovery(current_hotspot)
		if str(current_hotspot.get("hotspot_id", "")) != previous_hotspot_id:
			hotspot_focus_time = 0.0
		hotspot_focus_time += delta
		_update_hotspot_task()
	else:
		hotspot_focus_time = 0.0
		current_task.clear()
	_update_hotspot_visuals()


func _update_exit_zone() -> void:
	current_exit_zone.clear()
	var exit_profile := _biome_exit_profile()
	var pressure_window := _dynamic_pressure_window()
	var completion_state := _dynamic_completion_state()
	var exit_state := _dynamic_exit_state()
	var progress_focus := _progress_stage_interaction_focus("exit")
	var recommended_focus_kind := _recommended_route_focus_kind()
	var recommended_focus_scale := _recommended_route_focus_scale()
	var gate_focus_scale := _gate_focus_competition_scale("exit")
	var lock_radius := float(exit_profile.get("lock_radius", 2.6)) * float(pressure_window.get("exit_scale", 1.0)) * float(completion_state.get("exit_bias_scale", 1.0)) * float(exit_state.get("exit_bias_scale", 1.0)) * progress_focus
	var best_score := -INF
	for zone in exit_zones:
		var pos3: Vector3 = zone.get("position", Vector3.ZERO)
		var gate_id := str(zone.get("id", ""))
		var gate_boost := _exit_gate_boost(gate_id) * _arrival_exit_window_boost(gate_id) * _terminal_chain_exit_boost(gate_id)
		if gate_id == _recommended_exit_gate_id():
			if recommended_focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
				gate_boost *= recommended_focus_scale
				if not pending_arrival_intro.is_empty():
					gate_boost *= 1.08
		var route_focus_boost := _route_focus_channel_boost("exit", pos3) * gate_boost * gate_focus_scale
		var distance := Vector2(pos3.x, pos3.z).distance_to(_player_vec2())
		if distance < lock_radius * route_focus_boost:
			var score := route_focus_boost - distance / maxf(0.001, lock_radius)
			if score > best_score:
				best_score = score
				current_exit_zone = zone
	_update_exit_visuals()


func _update_hotspot_visuals() -> void:
	var focused_id := str(current_hotspot.get("hotspot_id", ""))
	var spotlight_profile := _biome_hotspot_spotlight_profile()
	var stage_profile := _route_stage_signal_profile()
	var progress_profile := _progress_stage_signal_profile()
	var pressure_window := _dynamic_pressure_window()
	var reveal_scale := float(spotlight_profile.get("reveal_scale", 1.0))
	var active_scale := float(spotlight_profile.get("active_scale", 1.0))
	var task_scale := float(spotlight_profile.get("task_scale", 1.0))
	var beacon_scale := float(spotlight_profile.get("beacon_scale", 1.0))
	var interaction_focus := _route_stage_interaction_focus("hotspot") * _progress_stage_interaction_focus("hotspot") * float(pressure_window.get("hotspot_scale", 1.0))
	var stage_hotspot_reveal := float(stage_profile.get("hotspot_reveal_scale", 1.0)) * interaction_focus * float(progress_profile.get("hotspot_scale", 1.0))
	var stage_hotspot_active := float(stage_profile.get("hotspot_active_scale", 1.0)) * interaction_focus * float(progress_profile.get("hotspot_scale", 1.0))
	for hotspot_id in hotspot_visuals.keys():
		var dynamic_reveal := _dynamic_hotspot_scale(hotspot_id, "reveal_scale", 1.0)
		var dynamic_active := _dynamic_hotspot_scale(hotspot_id, "active_scale", 1.0)
		var dynamic_beacon := _dynamic_hotspot_scale(hotspot_id, "beacon_scale", 1.0)
		var hotspot_window := _dynamic_hotspot_window(hotspot_id)
		var arrival_boost := _arrival_recommended_focus_boost("hotspot") * _arrival_hotspot_window_boost(hotspot_id) * _terminal_chain_hotspot_boost(hotspot_id)
		var entry_screen_boost := _entry_screen_hotspot_scale(hotspot_id)
		var data: Dictionary = hotspot_visuals[hotspot_id]
		var cluster: Node3D = data.get("cluster", null)
		var ring: MeshInstance3D = data.get("ring", null)
		var beacon: MeshInstance3D = data.get("beacon", null)
		var landmark: Node3D = data.get("landmark", null)
		if cluster == null or ring == null or beacon == null:
			continue
		var center3 := _hotspot_pos(hotspot_id)
		var hotspot_distance := Vector2(center3.x, center3.z).distance_to(_player_vec2())
		var route_focus_boost := _route_focus_channel_boost("hotspot", center3)
		var active: bool = hotspot_id == focused_id
		cluster.visible = active or hotspot_distance < _hotspot_reveal_radius(hotspot_id) * reveal_scale * dynamic_reveal * float(hotspot_window.get("reveal_scale", 1.0)) * stage_hotspot_reveal * route_focus_boost * arrival_boost * entry_screen_boost or discovered_hotspot_ids.has(hotspot_id)
		var task_progress := 0.0
		if active and not current_task.is_empty():
			var cfg := _hotspot_task_config(hotspot_id)
			task_progress = clampf(hotspot_focus_time / maxf(0.001, float(cfg.get("required_time", 2.0))), 0.0, 1.0)
		cluster.scale = cluster.scale.lerp(Vector3.ONE * (((1.18 * active_scale * dynamic_active * float(hotspot_window.get("active_scale", 1.0)) * stage_hotspot_active * route_focus_boost * arrival_boost * entry_screen_boost) if active else maxf(1.0, dynamic_active * entry_screen_boost))), 0.18)
		cluster.position.y = lerpf(cluster.position.y, 0.24 if active else 0.0, 0.18)
		if ring.material_override is StandardMaterial3D:
			var ring_mat := ring.material_override as StandardMaterial3D
			ring_mat.albedo_color.a = lerpf(ring_mat.albedo_color.a, 0.76 if active else 0.38, 0.18)
		ring.scale = ring.scale.lerp(Vector3.ONE * (1.0 + task_progress * 0.22 * task_scale * float(hotspot_window.get("task_scale", 1.0)) * dynamic_active * stage_hotspot_active * route_focus_boost * arrival_boost * entry_screen_boost), 0.16)
		if beacon.material_override is StandardMaterial3D:
			var beacon_mat := beacon.material_override as StandardMaterial3D
			beacon_mat.albedo_color.a = lerpf(beacon_mat.albedo_color.a, 0.95 if active else 0.7, 0.18)
		beacon.scale = beacon.scale.lerp(Vector3.ONE * (((1.0 + task_progress * 0.18) * beacon_scale * dynamic_beacon * float(hotspot_window.get("active_scale", 1.0)) * stage_hotspot_active * route_focus_boost * arrival_boost * entry_screen_boost) if active else maxf(1.0, dynamic_beacon * entry_screen_boost)), 0.14)
		if landmark != null:
			landmark.scale = landmark.scale.lerp(Vector3.ONE * ((1.1 * active_scale * dynamic_active * route_focus_boost * arrival_boost * entry_screen_boost) if active else maxf(1.0, dynamic_active * entry_screen_boost)), 0.14)


func _update_exit_visuals() -> void:
	var active_exit := str(current_exit_zone.get("id", ""))
	var exit_profile := _biome_exit_profile()
	var stage_profile := _route_stage_signal_profile()
	var progress_profile := _progress_stage_signal_profile()
	var pressure_window := _dynamic_pressure_window()
	var completion_state := _dynamic_completion_state()
	var exit_state := _dynamic_exit_state()
	var reveal_radius := float(exit_profile.get("reveal_radius", _exit_reveal_radius()))
	var active_scale := float(exit_profile.get("active_scale", 1.0))
	var beacon_scale := float(exit_profile.get("beacon_scale", 1.0))
	var interaction_focus := _route_stage_interaction_focus("exit") * _progress_stage_interaction_focus("exit") * float(pressure_window.get("exit_scale", 1.0)) * float(completion_state.get("exit_bias_scale", 1.0)) * float(exit_state.get("exit_bias_scale", 1.0))
	var stage_exit_reveal := float(stage_profile.get("exit_reveal_scale", 1.0)) * interaction_focus * float(progress_profile.get("exit_scale", 1.0))
	var stage_exit_active := float(stage_profile.get("exit_active_scale", 1.0)) * interaction_focus * float(progress_profile.get("exit_scale", 1.0))
	var gate_focus_scale := _gate_focus_competition_scale("exit")
	for exit_id in exit_visuals.keys():
		var data: Dictionary = exit_visuals[exit_id]
		var marker: MeshInstance3D = data.get("marker", null)
		if marker == null:
			continue
		var exit_position := Vector3.ZERO
		for zone in exit_zones:
			if str(zone.get("id", "")) == exit_id:
				exit_position = zone.get("position", Vector3.ZERO)
				break
		var exit_distance := Vector2(exit_position.x, exit_position.z).distance_to(_player_vec2())
		var gate_boost := _exit_gate_boost(exit_id) * _terminal_chain_exit_boost(exit_id)
		var arrival_boost := _arrival_recommended_focus_boost("exit") * _arrival_exit_window_boost(exit_id) * _terminal_chain_exit_boost(exit_id)
		var route_focus_boost := _route_focus_channel_boost("exit", exit_position) * gate_boost * gate_focus_scale
		var active: bool = exit_id == active_exit
		marker.visible = active or exit_distance < reveal_radius * float(exit_state.get("reveal_scale", 1.0)) * stage_exit_reveal * route_focus_boost * arrival_boost
		marker.scale = marker.scale.lerp(Vector3.ONE * (((1.14 * active_scale * beacon_scale * float(exit_state.get("visual_scale", 1.0)) * stage_exit_active * route_focus_boost * arrival_boost) if active else beacon_scale * float(exit_state.get("visual_scale", 1.0)))), 0.18)
		marker.position.y = lerpf(marker.position.y, 1.42 if active else 1.2, 0.18)
		if marker.material_override is StandardMaterial3D:
			var mat := marker.material_override as StandardMaterial3D
			mat.albedo_color.a = lerpf(mat.albedo_color.a, 0.86 if active else 0.55, 0.18)


func _update_biome_ambient_cues() -> void:
	if ambient_visuals.is_empty():
		_update_biome_stage_shells(0.0)
		_update_route_stage_visuals(0.0)
		return
	var player_pos := _player_vec2()
	var profile := _biome_ambient_profile()
	var event_state := _dynamic_event_state()
	var reveal_radius := float(profile.get("reveal_radius", 18.0))
	var focus_radius := float(profile.get("focus_radius", 8.0))
	var active_scale := float(profile.get("active_scale", 1.18))
	var beacon_scale := float(profile.get("beacon_scale", 1.14))
	var sway_speed := float(profile.get("sway_speed", 1.6))
	var sway_amount := float(profile.get("sway_amount", 0.12))
	var pulse := 0.5 + 0.5 * sin(elapsed_time() * sway_speed)
	var focused_hotspot_id := str(current_hotspot.get("hotspot_id", ""))
	var active_exit_id := str(current_exit_zone.get("id", ""))
	var pressure_active := not current_chase.is_empty()
	var aftermath_active := not chase_aftermath.is_empty()
	var recommended_gate_id := _recommended_exit_gate_id()
	var recommended_gate_scale := float(_dynamic_exit_state().get("recommended_gate_scale", 1.0))
	var recommended_focus_kind := _recommended_route_focus_kind()
	var recommended_focus_scale := _recommended_route_focus_scale()
	var arrival_exit_boost := _arrival_recommended_focus_boost("exit")
	var entry_ambient_boost := 1.0
	var hotspot_progress_focus := _progress_stage_interaction_focus("hotspot")
	var exit_progress_focus := _progress_stage_interaction_focus("exit")
	var pressure_progress_focus := _progress_stage_interaction_focus("pressure")
	var aftermath_progress_focus := _progress_stage_interaction_focus("aftermath")
	for cue in ambient_visuals:
		var cluster: Node3D = cue.get("cluster", null)
		var ring: MeshInstance3D = cue.get("ring", null)
		var beacon: MeshInstance3D = cue.get("beacon", null)
		var pos3: Vector3 = cue.get("position", Vector3.ZERO)
		if cluster == null:
			continue
		var cue_distance := Vector2(pos3.x, pos3.z).distance_to(player_pos)
		var channel := str(cue.get("channel", ""))
		var event_boost := 1.0
		var route_focus_boost := 1.0
		var arrival_channel_boost := _arrival_ambient_channel_boost(channel)
		var terminal_chain_boost := _terminal_chain_ambient_boost(channel)
		entry_ambient_boost = _entry_screen_ambient_boost(channel)
		if channel == "pressure":
			route_focus_boost = _route_focus_channel_boost("pressure", pos3)
		elif channel == "aftermath":
			route_focus_boost = _route_focus_channel_boost("aftermath", pos3)
		elif channel != "":
			if channel in hotspot_visuals:
				route_focus_boost = _route_focus_channel_boost("hotspot", pos3)
			elif channel == active_exit_id or channel.find("_gate") != -1:
				route_focus_boost = _route_focus_channel_boost("exit", pos3)
		if channel == focused_hotspot_id and focused_hotspot_id != "":
			event_boost = 1.28 * _route_stage_interaction_focus("hotspot") * hotspot_progress_focus
		elif channel == active_exit_id and active_exit_id != "":
			event_boost = 1.24 * _route_stage_interaction_focus("exit") * exit_progress_focus * float(event_state.get("exit_push_scale", 1.0))
		elif channel == recommended_gate_id and recommended_gate_id != "":
			event_boost = 1.12 * _route_stage_interaction_focus("exit") * exit_progress_focus * recommended_gate_scale * arrival_exit_boost
			if recommended_focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
				event_boost *= recommended_focus_scale
				if not pending_arrival_intro.is_empty():
					event_boost *= 1.1
		elif channel == "pressure" and pressure_active:
			event_boost = 1.18 * _route_stage_interaction_focus("pressure") * pressure_progress_focus * float(event_state.get("chase_scale", 1.0))
		elif channel == "aftermath" and aftermath_active:
			event_boost = 1.3 * _route_stage_interaction_focus("aftermath") * aftermath_progress_focus * float(event_state.get("aftermath_scale", 1.0))
		event_boost *= arrival_channel_boost * terminal_chain_boost * entry_ambient_boost
		var visible := cue_distance < reveal_radius * event_boost * route_focus_boost
		var active := cue_distance < focus_radius * event_boost * route_focus_boost or event_boost > 1.05 or route_focus_boost > 1.08 or arrival_channel_boost > 1.06 or terminal_chain_boost > 1.08 or entry_ambient_boost > 1.08
		cluster.visible = visible
		if not visible:
			continue
		cluster.scale = cluster.scale.lerp(Vector3.ONE * ((active_scale * event_boost * route_focus_boost) if active else 1.0), 0.12)
		cluster.position.y = lerpf(cluster.position.y, (0.22 + pulse * sway_amount * event_boost * route_focus_boost) if active else pulse * sway_amount * 0.35, 0.12)
		if ring != null and ring.material_override is StandardMaterial3D:
			var ring_mat := ring.material_override as StandardMaterial3D
			ring_mat.albedo_color.a = lerpf(ring_mat.albedo_color.a, (0.78 if active else 0.36) + (0.08 if event_boost > 1.05 else 0.0), 0.14)
			ring.scale = ring.scale.lerp(Vector3.ONE * (1.0 + pulse * 0.12 + (0.18 if active else 0.0) + (event_boost - 1.0) * 0.22 + (route_focus_boost - 1.0) * 0.18), 0.14)
		if beacon != null and beacon.material_override is StandardMaterial3D:
			var beacon_mat := beacon.material_override as StandardMaterial3D
			beacon_mat.albedo_color.a = lerpf(beacon_mat.albedo_color.a, (0.92 if active else 0.52) + (0.06 if event_boost > 1.05 else 0.0), 0.14)
			beacon.scale = beacon.scale.lerp(Vector3.ONE * (((beacon_scale + pulse * 0.08) * event_boost * route_focus_boost) if active else 1.0), 0.12)
	_update_biome_stage_shells(pulse)
	_update_route_stage_visuals(pulse)


func _update_route_stage() -> void:
	var spawn: Vector3 = current_layout.get("spawn", Vector3.ZERO)
	var player_pos := _player_vec2()
	var spawn_distance := Vector2(spawn.x, spawn.z).distance_to(player_pos)
	if not pending_gate_transition.is_empty() or not pending_arrival_intro.is_empty():
		current_route_stage = "entry"
		return
	if arrival_event_focus_timer > 0.0:
		match _recommended_route_focus_kind():
			"branch_route":
				current_route_stage = "branch"
				return
			"chokepoint", "route_landmark":
				current_route_stage = "terminal"
				return
			"entry_route":
				current_route_stage = "entry"
				return
			"trunk_route":
				current_route_stage = "trunk"
				return
	if not current_exit_zone.is_empty() or not chase_aftermath.is_empty() or not current_chase_result.is_empty():
		current_route_stage = "terminal"
		return
	if not current_hotspot.is_empty() or not current_task.is_empty() or not current_encounter.is_empty():
		current_route_stage = "branch"
		return
	var profile := _route_stage_profile()
	current_route_stage = "entry" if spawn_distance < float(profile.get("entry_radius", 14.0)) else "trunk"


func _update_biome_stage_shells(pulse: float) -> void:
	if ambient_stage_visuals.is_empty():
		return
	var profile := _route_stage_profile()
	var player_pos := _player_vec2()
	for stage in ambient_stage_visuals.keys():
		var data: Dictionary = ambient_stage_visuals[stage]
		var cluster: Node3D = data.get("cluster", null)
		var ring: MeshInstance3D = data.get("ring", null)
		var beacon: MeshInstance3D = data.get("beacon", null)
		var pos3: Vector3 = data.get("position", Vector3.ZERO)
		if cluster == null:
			continue
		var distance := Vector2(pos3.x, pos3.z).distance_to(player_pos)
		var reveal_radius := float(profile.get("reveal_radius", 24.0))
		var active: bool = stage == current_route_stage
		var shell_profile := _stage_shell_focus_profile(stage)
		cluster.visible = active or distance < reveal_radius
		if not cluster.visible:
			continue
		var active_scale := (1.24 if active else 1.0) * float(shell_profile.get("active_scale", 1.0))
		if active and stage == "terminal" and (not current_exit_zone.is_empty() or not chase_aftermath.is_empty()):
			active_scale = 1.34
		cluster.scale = cluster.scale.lerp(Vector3.ONE * (active_scale + pulse * 0.04), 0.12)
		cluster.position.y = lerpf(cluster.position.y, (0.24 + pulse * 0.08) if active else 0.0, 0.12)
		if ring != null and ring.material_override is StandardMaterial3D:
			var ring_mat := ring.material_override as StandardMaterial3D
			ring_mat.albedo_color.a = lerpf(ring_mat.albedo_color.a, (0.82 if active else 0.22) * float(shell_profile.get("ring_alpha_scale", 1.0)), 0.14)
			ring.scale = ring.scale.lerp(Vector3.ONE * ((1.0 + (0.2 if active else 0.0) + pulse * 0.08) * float(shell_profile.get("ring_scale", 1.0))), 0.14)
		if beacon != null and beacon.material_override is StandardMaterial3D:
			var beacon_mat := beacon.material_override as StandardMaterial3D
			beacon_mat.albedo_color.a = lerpf(beacon_mat.albedo_color.a, (0.94 if active else 0.4) * float(shell_profile.get("beacon_alpha_scale", 1.0)), 0.14)
			beacon.scale = beacon.scale.lerp(Vector3.ONE * (((1.18 + pulse * 0.06) if active else 1.0) * float(shell_profile.get("beacon_scale", 1.0))), 0.12)


func _update_route_stage_visuals(pulse: float) -> void:
	if route_stage_visuals.is_empty():
		current_route_focus.clear()
		return
	var profile := _route_stage_route_profile()
	var completion_state := _dynamic_completion_state()
	var exit_state := _dynamic_exit_state()
	var recommended_focus_kind := str(exit_state.get("recommended_route_focus_kind", ""))
	var readiness_band := str(completion_state.get("readiness_band", "observe"))
	var route_focus_bias := 1.0
	if readiness_band == "prepare":
		route_focus_bias = 1.08
	elif readiness_band == "transition":
		route_focus_bias = 1.18
	route_focus_bias *= float(exit_state.get("focus_switch_scale", 1.0))
	var player_pos := _player_vec2()
	var gate_focus_hold := _gate_focus_hold_strength()
	var previous_focus_kind := str(current_route_focus.get("kind", ""))
	var best_score := -INF
	var best_focus: Dictionary = {}
	for visual in route_stage_visuals:
		var root: Node3D = visual.get("root", null)
		if root == null:
			continue
		var kind := str(visual.get("kind", "trunk_route"))
		var base_pos: Vector3 = visual.get("base_pos", root.position)
		var prominence := float(visual.get("prominence", 1.0))
		var emphasis := float(profile.get(kind, 1.0)) * _progress_stage_route_boost(kind)
		emphasis *= _stage_shell_route_boost(kind)
		if readiness_band == "prepare":
			if kind in ["chokepoint", "route_landmark"]:
				emphasis *= 1.08
			elif kind in ["entry_route", "entry_marker"]:
				emphasis *= 0.96
		elif readiness_band == "transition":
			if kind in ["chokepoint", "route_landmark"]:
				emphasis *= 1.16
			elif kind in ["branch_route", "branch_marker"]:
				emphasis *= 1.04
			elif kind in ["entry_route", "entry_marker", "trunk_route", "trunk_marker"]:
				emphasis *= 0.92
		var terminal_focus_scale := float(exit_state.get("terminal_focus_scale", 1.0))
		if kind in ["chokepoint", "route_landmark"]:
			emphasis *= terminal_focus_scale
		elif terminal_focus_scale > 1.0 and kind in ["entry_route", "entry_marker", "trunk_route", "trunk_marker"]:
			emphasis *= lerpf(1.0, 0.92, minf(1.0, (terminal_focus_scale - 1.0) / 0.24))
		if gate_focus_hold > 0.0:
			if kind in ["chokepoint", "route_landmark"]:
				emphasis *= lerpf(1.0, 1.22, gate_focus_hold)
			elif kind in ["trunk_route", "trunk_marker", "branch_route", "branch_marker", "connector"]:
				emphasis *= lerpf(1.0, 0.9, gate_focus_hold)
			elif kind in ["entry_route", "entry_marker"]:
				emphasis *= lerpf(1.0, 0.94, gate_focus_hold)
			if previous_focus_kind == kind and kind in ["chokepoint", "route_landmark"]:
				emphasis *= lerpf(1.0, 1.08, gate_focus_hold)
		if recommended_focus_kind != "":
			if kind == recommended_focus_kind:
				var focus_scale := float(exit_state.get("focus_switch_scale", 1.0))
				emphasis *= lerpf(1.02, 1.18, minf(1.0, maxf(0.0, focus_scale - 0.96) / 0.22))
				if not pending_arrival_intro.is_empty():
					emphasis *= 1.16
			elif not pending_arrival_intro.is_empty() and kind in ["entry_route", "trunk_route", "branch_route", "chokepoint"]:
				emphasis *= 0.94
		var emphasis_gain := maxf(0.0, emphasis - 1.0)
		var focus_distance := player_pos.distance_to(Vector2(base_pos.x, base_pos.z))
		var focus_score := emphasis * prominence * 100.0 * route_focus_bias - focus_distance
		if focus_score > best_score:
			best_score = focus_score
			best_focus = {
				"kind": kind,
				"position": base_pos,
				"distance": focus_distance,
			}
		var target_lift := base_pos.y
		if emphasis_gain > 0.0:
			target_lift += (0.12 + pulse * 0.05) * prominence * emphasis_gain
		root.position.y = lerpf(root.position.y, target_lift, 0.12)
		var target_scale := 1.0 + emphasis_gain * 0.24 * prominence
		if emphasis_gain > 0.0:
			target_scale += pulse * 0.03
		root.scale = root.scale.lerp(Vector3.ONE * target_scale, 0.12)
	current_route_focus = best_focus


func _build_biome_ambient_cues() -> void:
	var profile := _biome_ambient_profile()
	var spread_scale := _world_spread_scale()
	var accent: Color = profile.get("accent", current_theme.get("accent", Color8(236, 202, 118)))
	var support: Color = profile.get("support", current_theme.get("water", Color8(90, 152, 188)))
	for cue in _biome_ambient_points():
		var cue_type := str(cue.get("type", "guide"))
		var cue_pos := Vector3(cue.get("position", Vector3.ZERO))
		var cue_channel := str(cue.get("channel", ""))
		cue_pos += _ambient_channel_offset(cue_channel)
		var cue_color := accent if cue_type != "water" else support
		var cluster := Node3D.new()
		cluster.position = cue_pos
		cluster.visible = false
		ambient_root.add_child(cluster)
		var ring := MeshInstance3D.new()
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = (1.18 if cue_type != "guide" else 0.92) * lerpf(1.0, spread_scale, 0.54)
		ring_mesh.bottom_radius = (1.46 if cue_type != "guide" else 1.14) * lerpf(1.0, spread_scale, 0.54)
		ring_mesh.height = 0.08
		ring.mesh = ring_mesh
		ring.position = Vector3(0.0, 0.05, 0.0)
		ring.material_override = _material(cue_color, 0.34)
		cluster.add_child(ring)
		var beacon := _box_mesh(Vector3(0.16, 1.08, 0.16) * lerpf(1.0, spread_scale, 0.4), cue_color.darkened(0.12))
		beacon.position = Vector3(0.0, 0.54 * lerpf(1.0, spread_scale, 0.36), 0.0)
		if cue_type == "forest":
			beacon.scale = Vector3(0.76, 1.42, 0.76)
		elif cue_type == "coast":
			beacon.scale = Vector3(0.9, 1.12, 0.9)
		cluster.add_child(beacon)
		match cue_type:
			"wetland":
				for side in [-1.0, 1.0]:
					var mist := _box_mesh(Vector3(0.52, 0.04, 1.06), cue_color.lightened(0.16))
					mist.position = Vector3(side * 0.52, 0.03, 0.14)
					mist.material_override = _material(cue_color.lightened(0.16), 0.18)
					cluster.add_child(mist)
					var post := _box_mesh(Vector3(0.08, 0.56, 0.08), support.darkened(0.18))
					post.position = Vector3(side * 0.68, 0.28, -0.48)
					cluster.add_child(post)
			"forest":
				for side in [-1.0, 1.0]:
					var shaft := _box_mesh(Vector3(0.14, 1.52, 0.14), support.lightened(0.08))
					shaft.position = Vector3(side * 0.42, 0.78, 0.0)
					shaft.material_override = _material(support.lightened(0.08), 0.2)
					cluster.add_child(shaft)
				var shade_band := _box_mesh(Vector3(1.46, 0.03, 0.42), cue_color.darkened(0.2))
				shade_band.position = Vector3(0.0, 0.02, -0.54)
				shade_band.material_override = _material(cue_color.darkened(0.2), 0.24)
				cluster.add_child(shade_band)
			"coast":
				for side in [-1.0, 1.0]:
					var surf := _box_mesh(Vector3(0.18, 0.04, 1.28), support.lightened(0.14))
					surf.position = Vector3(side * 0.64, 0.03, 0.0)
					surf.material_override = _material(support.lightened(0.14), 0.24)
					cluster.add_child(surf)
				var mast := _box_mesh(Vector3(0.08, 0.86, 0.08), cue_color.darkened(0.16))
				mast.position = Vector3(0.0, 0.42, -0.56)
				cluster.add_child(mast)
			_:
				for side in [-1.0, 1.0]:
					var rail := _box_mesh(Vector3(0.12, 0.04, 1.2), cue_color.lightened(0.08))
					rail.position = Vector3(side * 0.58, 0.03, 0.04)
					rail.material_override = _material(cue_color.lightened(0.08), 0.22)
					cluster.add_child(rail)
					var guide_post := _box_mesh(Vector3(0.08, 0.62, 0.08), cue_color.darkened(0.18))
					guide_post.position = Vector3(side * 0.74, 0.31, -0.44)
					cluster.add_child(guide_post)
		if cue.has("length"):
			var cue_length := float(cue.get("length", 4.0))
			var cue_width := float(cue.get("width", 1.2))
			var cue_yaw := float(cue.get("yaw", 0.0))
			var band := _box_mesh(Vector3(cue_width, 0.03, cue_length), cue_color.lightened(0.06))
			band.position = Vector3(0.0, 0.025, 0.0)
			band.rotation_degrees = Vector3(0.0, cue_yaw, 0.0)
			band.material_override = _material(cue_color.lightened(0.06), 0.16)
			cluster.add_child(band)
			var spine := _box_mesh(Vector3(0.12, 0.04, cue_length * 0.88), cue_color.lightened(0.18))
			spine.position = Vector3(0.0, 0.04, 0.0)
			spine.rotation_degrees = Vector3(0.0, cue_yaw, 0.0)
			spine.material_override = _material(cue_color.lightened(0.18), 0.2)
			cluster.add_child(spine)
			for side in [-1.0, 1.0]:
				var side_band := _box_mesh(Vector3(0.08, 0.03, cue_length * 0.74), cue_color.darkened(0.08))
				side_band.position = Vector3(side * cue_width * 0.38, 0.03, 0.0)
				side_band.rotation_degrees = Vector3(0.0, cue_yaw, 0.0)
				side_band.material_override = _material(cue_color.darkened(0.08), 0.18)
				cluster.add_child(side_band)
				var tip_light := _box_mesh(Vector3(0.08, 0.08, 0.08), cue_color.lightened(0.2))
				tip_light.position = Vector3(side * cue_width * 0.42, 0.08, cue_length * 0.36)
				tip_light.rotation_degrees = Vector3(0.0, cue_yaw, 0.0)
				cluster.add_child(tip_light)
		if cue_channel != "":
			cluster.set_meta("channel", cue_channel)
		ambient_visuals.append({
			"cluster": cluster,
			"ring": ring,
			"beacon": beacon,
			"position": cue_pos,
			"type": cue_type,
			"channel": cue_channel,
		})
	for zone in exit_zones:
		var exit_pos := Vector3(zone.get("position", Vector3.ZERO))
		var exit_cluster := Node3D.new()
		exit_cluster.position = exit_pos + Vector3(0.0, 0.0, -1.8)
		exit_cluster.visible = false
		ambient_root.add_child(exit_cluster)
		var exit_band := _box_mesh(Vector3(1.2, 0.03, 3.8) * lerpf(1.0, spread_scale, 0.5), accent.lightened(0.12))
		exit_band.position = Vector3(0.0, 0.025, 0.0)
		exit_band.material_override = _material(accent.lightened(0.12), 0.16)
		exit_cluster.add_child(exit_band)
		var exit_spine := _box_mesh(Vector3(0.12, 0.04, 3.2) * lerpf(1.0, spread_scale, 0.5), accent.lightened(0.22))
		exit_spine.position = Vector3(0.0, 0.04, 0.0)
		exit_spine.material_override = _material(accent.lightened(0.22), 0.22)
		exit_cluster.add_child(exit_spine)
		var exit_ring := MeshInstance3D.new()
		var exit_ring_mesh := CylinderMesh.new()
		exit_ring_mesh.top_radius = 0.94 * lerpf(1.0, spread_scale, 0.54)
		exit_ring_mesh.bottom_radius = 1.14 * lerpf(1.0, spread_scale, 0.54)
		exit_ring_mesh.height = 0.08
		exit_ring.mesh = exit_ring_mesh
		exit_ring.position = Vector3(0.0, 0.05, 1.42)
		exit_ring.material_override = _material(accent, 0.3)
		exit_cluster.add_child(exit_ring)
		var exit_beacon := _box_mesh(Vector3(0.16, 1.22, 0.16) * lerpf(1.0, spread_scale, 0.42), accent.darkened(0.12))
		exit_beacon.position = Vector3(0.0, 0.62 * lerpf(1.0, spread_scale, 0.38), 1.42)
		exit_cluster.add_child(exit_beacon)
		ambient_visuals.append({
			"cluster": exit_cluster,
			"ring": exit_ring,
			"beacon": exit_beacon,
			"position": exit_cluster.position,
			"type": "exit_lane",
			"channel": str(zone.get("id", "")),
		})
	if not chase_aftermath.is_empty():
		var aftermath_pos := Vector3(chase_aftermath.get("target", Vector2.ZERO).x, 0.0, chase_aftermath.get("target", Vector2.ZERO).y)
		var aftermath_cluster := Node3D.new()
		aftermath_cluster.position = aftermath_pos
		aftermath_cluster.visible = false
		ambient_root.add_child(aftermath_cluster)
		var aftermath_band := _box_mesh(Vector3(1.3, 0.03, 5.2) * lerpf(1.0, spread_scale, 0.52), support.lightened(0.06))
		aftermath_band.position = Vector3(0.0, 0.025, 0.0)
		aftermath_band.material_override = _material(support.lightened(0.06), 0.14)
		aftermath_cluster.add_child(aftermath_band)
		var aftermath_ring := MeshInstance3D.new()
		var aftermath_mesh := CylinderMesh.new()
		aftermath_mesh.top_radius = 1.4 * lerpf(1.0, spread_scale, 0.56)
		aftermath_mesh.bottom_radius = 1.8 * lerpf(1.0, spread_scale, 0.56)
		aftermath_mesh.height = 0.08
		aftermath_ring.mesh = aftermath_mesh
		aftermath_ring.position = Vector3(0.0, 0.05, 0.0)
		aftermath_ring.material_override = _material(support, 0.3)
		aftermath_cluster.add_child(aftermath_ring)
		var aftermath_beacon := _box_mesh(Vector3(0.16, 1.08, 0.16) * lerpf(1.0, spread_scale, 0.42), support.darkened(0.14))
		aftermath_beacon.position = Vector3(0.0, 0.54 * lerpf(1.0, spread_scale, 0.38), 0.0)
		aftermath_cluster.add_child(aftermath_beacon)
		ambient_visuals.append({
			"cluster": aftermath_cluster,
			"ring": aftermath_ring,
			"beacon": aftermath_beacon,
			"position": aftermath_pos,
			"type": "aftermath_lane",
			"channel": "aftermath",
		})


func _ambient_channel_offset(channel: String) -> Vector3:
	match channel:
		"waterhole", "migration_corridor", "predator_ridge", "carrion_field", "shade_grove":
			return (_hotspot_cluster_offset(channel) + _hotspot_landmark_offset(channel) * 0.24) * 0.94
		_:
			return Vector3.ZERO


func _build_biome_stage_shells() -> void:
	for spec in _biome_stage_shell_specs():
		var stage := str(spec.get("stage", "trunk"))
		var shell_root := Node3D.new()
		shell_root.position = Vector3(spec.get("position", Vector3.ZERO))
		shell_root.visible = false
		ambient_root.add_child(shell_root)
		var color: Color = spec.get("color", current_theme.get("accent", Color8(236, 202, 118)))
		var size: Vector3 = spec.get("size", Vector3(3.6, 0.04, 6.4))
		var yaw := float(spec.get("yaw", 0.0))
		var plate := _box_mesh(size, color.darkened(0.06))
		plate.position = Vector3(0.0, 0.025, 0.0)
		plate.rotation_degrees = Vector3(0.0, yaw, 0.0)
		plate.material_override = _material(color.darkened(0.06), 0.1)
		shell_root.add_child(plate)
		var spine := _box_mesh(Vector3(maxf(0.14, size.x * 0.14), 0.04, size.z * 0.84), color.lightened(0.14))
		spine.position = Vector3(0.0, 0.04, 0.0)
		spine.rotation_degrees = Vector3(0.0, yaw, 0.0)
		spine.material_override = _material(color.lightened(0.14), 0.16)
		shell_root.add_child(spine)
		var ring := MeshInstance3D.new()
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = float(spec.get("ring_radius", 1.8)) * 1.08
		ring_mesh.bottom_radius = float(spec.get("ring_radius", 2.2)) * 1.12
		ring_mesh.height = 0.08
		ring.mesh = ring_mesh
		ring.position = Vector3(0.0, 0.05, 0.0)
		ring.material_override = _material(color, 0.22)
		shell_root.add_child(ring)
		var beacon_height := float(spec.get("beacon_height", 1.24))
		var beacon := _box_mesh(Vector3(0.22, beacon_height * 1.08, 0.22), color.darkened(0.12))
		beacon.position = Vector3(0.0, beacon_height * 0.5, 0.0)
		shell_root.add_child(beacon)
		for side in [-1.0, 1.0]:
			var edge := _box_mesh(Vector3(0.08, 0.03, size.z * 0.72), color.darkened(0.12))
			edge.position = Vector3(side * size.x * 0.34, 0.03, 0.0)
			edge.rotation_degrees = Vector3(0.0, yaw, 0.0)
			edge.material_override = _material(color.darkened(0.12), 0.16)
			shell_root.add_child(edge)
			var light := _box_mesh(Vector3(0.1, 0.1, 0.1), color.lightened(0.2))
			light.position = Vector3(side * size.x * 0.3, 0.1, size.z * 0.28)
			light.rotation_degrees = Vector3(0.0, yaw, 0.0)
			shell_root.add_child(light)
		ambient_stage_visuals[stage] = {
			"cluster": shell_root,
			"ring": ring,
			"beacon": beacon,
			"position": shell_root.position,
		}


func _biome_ambient_points() -> Array:
	var waterhole := _hotspot_pos("waterhole")
	var migration := _hotspot_pos("migration_corridor")
	var shade := _hotspot_pos("shade_grove")
	var carrion := _hotspot_pos("carrion_field")
	var ridge := _hotspot_pos("predator_ridge")
	var spawn := Vector3(current_layout.get("spawn", Vector3.ZERO))
	match current_biome:
		"wetland":
			return [
				_ambient_corridor_spec(spawn + Vector3(2.0, 0.0, -2.0), waterhole + Vector3(0.0, 0.0, 1.2), "wetland", "waterhole"),
				_ambient_corridor_spec(waterhole + Vector3(2.0, 0.0, -0.6), migration + Vector3(-1.4, 0.0, 0.4), "wetland", "migration_corridor"),
				{"type": "wetland", "position": waterhole + Vector3(-2.3, 0.0, 1.8), "channel": "waterhole"},
				{"type": "wetland", "position": migration + Vector3(2.3, 0.0, -1.5), "channel": "migration_corridor"},
				{"type": "water", "position": carrion + Vector3(-1.9, 0.0, 2.4), "channel": "carrion_field"},
			]
		"forest":
			return [
				_ambient_corridor_spec(spawn + Vector3(1.0, 0.0, -1.0), shade + Vector3(0.0, 0.0, -0.6), "forest", "shade_grove"),
				_ambient_corridor_spec(shade + Vector3(1.9, 0.0, -1.0), waterhole + Vector3(-1.3, 0.0, 0.4), "forest", "waterhole"),
				{"type": "forest", "position": shade + Vector3(1.6, 0.0, 1.5), "channel": "shade_grove"},
				{"type": "forest", "position": ridge + Vector3(-2.2, 0.0, 1.8), "channel": "predator_ridge"},
				{"type": "forest", "position": waterhole + Vector3(2.0, 0.0, -2.0), "channel": "waterhole"},
			]
		"coast":
			return [
				_ambient_corridor_spec(spawn + Vector3(2.2, 0.0, -0.8), waterhole + Vector3(-0.8, 0.0, 0.6), "coast", "waterhole"),
				_ambient_corridor_spec(waterhole + Vector3(1.8, 0.0, -0.4), migration + Vector3(-1.8, 0.0, 0.6), "coast", "migration_corridor"),
				{"type": "coast", "position": migration + Vector3(-2.5, 0.0, 1.5), "channel": "migration_corridor"},
				{"type": "coast", "position": waterhole + Vector3(2.8, 0.0, -1.5), "channel": "waterhole"},
				{"type": "coast", "position": carrion + Vector3(-1.8, 0.0, -2.0), "channel": "carrion_field"},
			]
		_:
			return [
				_ambient_corridor_spec(spawn + Vector3(2.4, 0.0, -1.2), migration + Vector3(-1.4, 0.0, 0.8), "guide", "migration_corridor"),
				_ambient_corridor_spec(migration + Vector3(1.8, 0.0, -1.0), ridge + Vector3(-1.2, 0.0, 0.3), "guide", "predator_ridge"),
				{"type": "guide", "position": migration + Vector3(0.0, 0.0, 2.5), "channel": "migration_corridor"},
				{"type": "guide", "position": ridge + Vector3(-2.3, 0.0, 1.2), "channel": "predator_ridge"},
				{"type": "guide", "position": shade + Vector3(1.8, 0.0, -1.6), "channel": "shade_grove"},
			]


func _ambient_corridor_spec(a: Vector3, b: Vector3, cue_type: String, channel: String) -> Dictionary:
	var spread_scale := _world_spread_scale()
	var delta := b - a
	var center := a.lerp(b, 0.5)
	var length := maxf(2.6, Vector2(delta.x, delta.z).length())
	var yaw := rad_to_deg(atan2(delta.x, delta.z))
	var width := 1.36
	match current_biome:
		"wetland":
			width = 1.12
		"forest":
			width = 1.0
		"coast":
			width = 1.26
		_:
			width = 1.42
	length *= lerpf(1.0, spread_scale, 0.72)
	width *= lerpf(1.0, spread_scale, 0.48)
	return {
		"type": cue_type,
		"position": center,
		"length": length,
		"width": width,
		"yaw": yaw,
		"channel": channel,
	}


func _biome_stage_shell_specs() -> Array:
	var spawn: Vector3 = current_layout.get("spawn", Vector3.ZERO)
	var waterhole := _hotspot_pos("waterhole")
	var migration := _hotspot_pos("migration_corridor")
	var shade := _hotspot_pos("shade_grove")
	var carrion := _hotspot_pos("carrion_field")
	var ridge := _hotspot_pos("predator_ridge")
	var exit_focus := _exit_focus_point()
	var shell_scale := _world_spread_scale()
	var shell_height_scale := lerpf(1.0, shell_scale, 0.42)
	var shell_spread := lerpf(1.0, shell_scale, 0.34)
	match current_biome:
		"wetland":
			return [
				{"stage": "entry", "position": spawn.lerp(waterhole, 0.46), "size": Vector3(3.2 * shell_scale, 0.04, 7.0 * shell_scale), "yaw": -22.0, "ring_radius": 1.72 * shell_scale, "beacon_height": 1.28 * shell_height_scale, "color": current_theme.get("accent", Color8(178, 222, 176))},
				{"stage": "trunk", "position": waterhole.lerp(migration, 0.56) + Vector3(1.2, 0.0, -0.6) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(4.6 * shell_scale, 0.04, 8.8 * shell_scale), "yaw": -18.0, "ring_radius": 2.2 * shell_scale, "beacon_height": 1.28 * shell_height_scale, "color": current_theme.get("route", Color8(214, 226, 188))},
				{"stage": "branch", "position": shade.lerp(carrion, 0.44) + Vector3(-1.4, 0.0, 0.9) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(4.0 * shell_scale, 0.04, 6.4 * shell_scale), "yaw": 26.0, "ring_radius": 1.98 * shell_scale, "beacon_height": 1.38 * shell_height_scale, "color": current_theme.get("foliage", Color8(106, 144, 92))},
				{"stage": "terminal", "position": exit_focus.lerp(migration, 0.24) + Vector3(0.0, 0.0, -1.8) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(5.0 * shell_scale, 0.04, 8.4 * shell_scale), "yaw": 0.0, "ring_radius": 2.48 * shell_scale, "beacon_height": 1.56 * shell_height_scale, "color": current_theme.get("water", Color8(74, 136, 154))},
			]
		"forest":
			return [
				{"stage": "entry", "position": spawn.lerp(shade, 0.5), "size": Vector3(2.8 * shell_scale, 0.04, 6.2 * shell_scale), "yaw": -18.0, "ring_radius": 1.64 * shell_scale, "beacon_height": 1.34 * shell_height_scale, "color": current_theme.get("accent", Color8(170, 206, 156))},
				{"stage": "trunk", "position": shade.lerp(waterhole, 0.58) + Vector3(1.0, 0.0, -0.5) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(4.0 * shell_scale, 0.04, 7.8 * shell_scale), "yaw": -8.0, "ring_radius": 2.08 * shell_scale, "beacon_height": 1.32 * shell_height_scale, "color": current_theme.get("route", Color8(184, 172, 134))},
				{"stage": "branch", "position": ridge.lerp(carrion, 0.4) + Vector3(-1.2, 0.0, 0.8) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(3.8 * shell_scale, 0.04, 6.0 * shell_scale), "yaw": 32.0, "ring_radius": 1.9 * shell_scale, "beacon_height": 1.42 * shell_height_scale, "color": current_theme.get("foliage", Color8(64, 96, 64))},
				{"stage": "terminal", "position": exit_focus.lerp(ridge, 0.2) + Vector3(0.0, 0.0, -1.6) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(4.5 * shell_scale, 0.04, 7.6 * shell_scale), "yaw": -12.0, "ring_radius": 2.34 * shell_scale, "beacon_height": 1.58 * shell_height_scale, "color": current_theme.get("ground", Color8(104, 122, 96))},
			]
		"coast":
			return [
				{"stage": "entry", "position": spawn.lerp(waterhole, 0.48), "size": Vector3(3.0 * shell_scale, 0.04, 6.8 * shell_scale), "yaw": -12.0, "ring_radius": 1.7 * shell_scale, "beacon_height": 1.24 * shell_height_scale, "color": current_theme.get("accent", Color8(216, 222, 180))},
				{"stage": "trunk", "position": waterhole.lerp(migration, 0.58) + Vector3(1.2, 0.0, -0.4) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(4.6 * shell_scale, 0.04, 8.6 * shell_scale), "yaw": -6.0, "ring_radius": 2.16 * shell_scale, "beacon_height": 1.24 * shell_height_scale, "color": current_theme.get("route", Color8(244, 232, 192))},
				{"stage": "branch", "position": migration.lerp(carrion, 0.42) + Vector3(-1.1, 0.0, 0.7) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(4.0 * shell_scale, 0.04, 6.4 * shell_scale), "yaw": 18.0, "ring_radius": 1.98 * shell_scale, "beacon_height": 1.36 * shell_height_scale, "color": current_theme.get("water", Color8(76, 156, 196))},
				{"stage": "terminal", "position": exit_focus.lerp(carrion, 0.18) + Vector3(0.0, 0.0, -1.7) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(5.0 * shell_scale, 0.04, 8.2 * shell_scale), "yaw": 4.0, "ring_radius": 2.5 * shell_scale, "beacon_height": 1.54 * shell_height_scale, "color": current_theme.get("ground", Color8(202, 194, 166))},
			]
		_:
			return [
				{"stage": "entry", "position": spawn.lerp(waterhole, 0.5), "size": Vector3(3.4 * shell_scale, 0.04, 7.2 * shell_scale), "yaw": -8.0, "ring_radius": 1.76 * shell_scale, "beacon_height": 1.24 * shell_height_scale, "color": current_theme.get("accent", Color8(236, 202, 118))},
				{"stage": "trunk", "position": waterhole.lerp(migration, 0.6) + Vector3(1.3, 0.0, -0.4) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(5.0 * shell_scale, 0.04, 9.2 * shell_scale), "yaw": -4.0, "ring_radius": 2.24 * shell_scale, "beacon_height": 1.22 * shell_height_scale, "color": current_theme.get("route", Color8(240, 223, 176))},
				{"stage": "branch", "position": ridge.lerp(shade, 0.46) + Vector3(-1.3, 0.0, 0.8) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(4.0 * shell_scale, 0.04, 6.6 * shell_scale), "yaw": 22.0, "ring_radius": 1.98 * shell_scale, "beacon_height": 1.4 * shell_height_scale, "color": current_theme.get("foliage", Color8(96, 132, 74))},
				{"stage": "terminal", "position": exit_focus.lerp(migration, 0.2) + Vector3(0.0, 0.0, -1.8) * REGION_DISTANCE_SCALE * shell_spread, "size": Vector3(5.2 * shell_scale, 0.04, 8.6 * shell_scale), "yaw": 2.0, "ring_radius": 2.58 * shell_scale, "beacon_height": 1.58 * shell_height_scale, "color": current_theme.get("ground", Color8(190, 168, 104))},
			]


func _route_stage_profile() -> Dictionary:
	match current_biome:
		"wetland":
			return {"entry_radius": 15.5 * REGION_DISTANCE_SCALE, "reveal_radius": 24.0 * REGION_DISTANCE_SCALE}
		"forest":
			return {"entry_radius": 12.5 * REGION_DISTANCE_SCALE, "reveal_radius": 18.0 * REGION_DISTANCE_SCALE}
		"coast":
			return {"entry_radius": 16.5 * REGION_DISTANCE_SCALE, "reveal_radius": 26.0 * REGION_DISTANCE_SCALE}
		_:
			return {"entry_radius": 15.0 * REGION_DISTANCE_SCALE, "reveal_radius": 25.0 * REGION_DISTANCE_SCALE}


func _route_stage_signal_profile() -> Dictionary:
	match current_route_stage:
		"entry":
			return {
				"hotspot_focus_scale": 0.88,
				"hotspot_reveal_scale": 0.86,
				"hotspot_active_scale": 0.96,
				"exit_reveal_scale": 1.18,
				"exit_active_scale": 1.08,
				"animal_reveal_scale": 0.88,
			}
		"branch":
			return {
				"hotspot_focus_scale": 1.18,
				"hotspot_reveal_scale": 1.18,
				"hotspot_active_scale": 1.22,
				"exit_reveal_scale": 0.92,
				"exit_active_scale": 0.96,
				"animal_reveal_scale": 1.02,
			}
		"terminal":
			return {
				"hotspot_focus_scale": _terminal_scale_adjust(0.96),
				"hotspot_reveal_scale": _terminal_scale_adjust(0.94),
				"hotspot_active_scale": _terminal_scale_adjust(1.04),
				"exit_reveal_scale": _terminal_scale_adjust(1.26),
				"exit_active_scale": _terminal_scale_adjust(1.24),
				"animal_reveal_scale": _terminal_scale_adjust(1.12),
			}
		_:
			return {
				"hotspot_focus_scale": 1.0,
				"hotspot_reveal_scale": 1.0,
				"hotspot_active_scale": 1.0,
				"exit_reveal_scale": 1.0,
				"exit_active_scale": 1.0,
				"animal_reveal_scale": 1.0,
			}


func _route_stage_route_profile() -> Dictionary:
	match current_route_stage:
		"entry":
			return {
				"entry_route": 1.34,
				"entry_marker": 1.28,
				"trunk_route": 0.98,
				"trunk_marker": 1.02,
				"branch_route": 0.9,
				"branch_marker": 0.9,
				"connector": 0.96,
				"chokepoint": 1.16,
				"route_landmark": 0.94,
			}
		"branch":
			return {
				"entry_route": 0.92,
				"entry_marker": 0.94,
				"trunk_route": 1.08,
				"trunk_marker": 1.12,
				"branch_route": 1.34,
				"branch_marker": 1.28,
				"connector": 1.14,
				"chokepoint": 0.98,
				"route_landmark": 1.2,
			}
		"terminal":
			return {
				"entry_route": 0.88,
				"entry_marker": 0.92,
				"trunk_route": 1.04,
				"trunk_marker": 1.16,
				"branch_route": 1.06,
				"branch_marker": 1.12,
				"connector": 1.08,
				"chokepoint": 1.36,
				"route_landmark": 1.28,
			}
		_:
			return {
				"entry_route": 1.0,
				"entry_marker": 1.0,
				"trunk_route": 1.28,
				"trunk_marker": 1.24,
				"branch_route": 0.96,
				"branch_marker": 0.98,
				"connector": 1.18,
				"chokepoint": 1.08,
				"route_landmark": 1.04,
			}


func _route_stage_ecology_profile() -> Dictionary:
	match current_route_stage:
		"entry":
			return {
				"pressure_scale": 0.88,
				"hit_scale": 0.92,
				"burst_distance_scale": 0.9,
				"burst_timeout_scale": 0.92,
				"player_radius_scale": 0.9,
				"encounter_radius_scale": 0.9,
				"herd_pull_scale": 0.92,
				"glide_pull_scale": 0.9,
				"predator_pull_scale": 0.9,
				"aftermath_pull_scale": 0.92,
				"aftermath_duration_scale": 0.94,
				"alpha_push_scale": 0.92,
				"herd_signal_scale": 0.9,
				"sentry_signal_scale": 0.92,
				"regroup_scale": 0.94,
				"flee_scale": 0.9,
			}
		"branch":
			return {
				"pressure_scale": 1.04,
				"hit_scale": 1.0,
				"burst_distance_scale": 0.98,
				"burst_timeout_scale": 1.02,
				"player_radius_scale": 1.08,
				"encounter_radius_scale": 1.08,
				"herd_pull_scale": 1.06,
				"glide_pull_scale": 1.04,
				"predator_pull_scale": 1.0,
				"aftermath_pull_scale": 1.06,
				"aftermath_duration_scale": 1.02,
				"alpha_push_scale": 1.0,
				"herd_signal_scale": 1.08,
				"sentry_signal_scale": 1.08,
				"regroup_scale": 1.08,
				"flee_scale": 1.04,
			}
		"terminal":
			return {
				"pressure_scale": _terminal_scale_adjust(1.14),
				"hit_scale": _terminal_scale_adjust(1.08),
				"burst_distance_scale": _terminal_scale_adjust(1.08),
				"burst_timeout_scale": _terminal_scale_adjust(1.12),
				"player_radius_scale": _terminal_scale_adjust(1.02),
				"encounter_radius_scale": _terminal_scale_adjust(1.04),
				"herd_pull_scale": _terminal_scale_adjust(1.12),
				"glide_pull_scale": _terminal_scale_adjust(1.14),
				"predator_pull_scale": _terminal_scale_adjust(1.16),
				"aftermath_pull_scale": _terminal_scale_adjust(1.18),
				"aftermath_duration_scale": _terminal_scale_adjust(1.14),
				"alpha_push_scale": _terminal_scale_adjust(1.14),
				"herd_signal_scale": _terminal_scale_adjust(1.06),
				"sentry_signal_scale": _terminal_scale_adjust(1.12),
				"regroup_scale": _terminal_scale_adjust(1.1),
				"flee_scale": _terminal_scale_adjust(1.08),
			}
		_:
			return {
				"pressure_scale": 1.0,
				"hit_scale": 1.0,
				"burst_distance_scale": 1.0,
				"burst_timeout_scale": 1.0,
				"player_radius_scale": 1.0,
				"encounter_radius_scale": 1.0,
				"herd_pull_scale": 1.0,
				"glide_pull_scale": 1.0,
				"predator_pull_scale": 1.0,
				"aftermath_pull_scale": 1.0,
				"aftermath_duration_scale": 1.0,
				"alpha_push_scale": 1.0,
				"herd_signal_scale": 1.0,
				"sentry_signal_scale": 1.0,
				"regroup_scale": 1.0,
				"flee_scale": 1.0,
			}


func _route_stage_task_profile(hotspot_id: String) -> Dictionary:
	match current_route_stage:
		"entry":
			if hotspot_id == "migration_corridor":
				return {
					"required_time_scale": 0.9,
					"required_radius_scale": 1.08,
					"stage_hint": "入口段更偏顺主路读图，迁徙线更容易先完成。",
				}
			return {
				"required_time_scale": 1.12,
				"required_radius_scale": 0.92,
				"stage_hint": "入口段先稳住推进，支路观察会稍慢吃到。",
			}
		"branch":
			return {
				"required_time_scale": (0.82 if hotspot_id != "migration_corridor" else 0.9),
				"required_radius_scale": (1.18 if hotspot_id != "migration_corridor" else 1.08),
				"stage_hint": "支路段偏观察，热点采样和近距记录会更快推进。",
			}
		"terminal":
			if hotspot_id in ["predator_ridge", "carrion_field"]:
				return {
					"required_time_scale": 0.84,
					"required_radius_scale": 1.16,
					"stage_hint": "终端段偏高张力，掠食和腐食观察会更快成立。",
				}
			return {
				"required_time_scale": 0.96,
				"required_radius_scale": 1.04,
				"stage_hint": "终端段更强调出口与余波，普通观察保持中等节奏。",
			}
		_:
			return {
				"required_time_scale": 0.96 if hotspot_id == "migration_corridor" else 1.0,
				"required_radius_scale": 1.04 if hotspot_id == "migration_corridor" else 1.0,
				"stage_hint": "主路段更稳定，任务会按常规节奏推进。",
			}


func _route_stage_reentry_profile() -> Dictionary:
	var gate_id := _recommended_exit_gate_id()
	var terminal_focus := _recommended_route_focus_kind() in ["chokepoint", "route_landmark"]
	var terminal_scale := _recommended_terminal_scale()
	match current_biome:
		"wetland":
			var profile := {
				"lane_scale": 1.08,
				"merge_scale": 1.12,
				"beacon_scale": 1.14,
				"gate_move_lerp": 0.24,
				"arrival_move_lerp": 0.26,
				"gate_fov": 47.0,
				"arrival_fov": 48.5,
				"camera_height": 0.58,
				"camera_pull": 1.18,
			}
			if gate_id == "west_gate":
				profile["lane_scale"] = 1.16
				profile["beacon_scale"] = 1.22
			elif gate_id == "north_gate":
				profile["merge_scale"] = 1.18
			if terminal_focus:
				match _stage_shell_focus_band("terminal"):
					"pressure":
						profile["gate_move_lerp"] = 0.27
						profile["arrival_move_lerp"] = 0.29
						profile["gate_fov"] = 47.8
						profile["arrival_fov"] = 49.0
						profile["camera_pull"] = 1.24
						profile["beacon_scale"] = float(profile.get("beacon_scale", 1.0)) * 1.06
					"aftermath":
						profile["gate_move_lerp"] = 0.22
						profile["arrival_move_lerp"] = 0.24
						profile["gate_fov"] = 46.6
						profile["arrival_fov"] = 48.2
						profile["camera_pull"] = 1.3
						profile["lane_scale"] = float(profile.get("lane_scale", 1.0)) * 1.04
					"exit":
						profile["gate_move_lerp"] = 0.25
						profile["arrival_move_lerp"] = 0.27
						profile["gate_fov"] = 47.4
						profile["arrival_fov"] = 48.8
						profile["camera_pull"] = 1.12
						profile["merge_scale"] = float(profile.get("merge_scale", 1.0)) * 1.08
						profile["beacon_scale"] = float(profile.get("beacon_scale", 1.0)) * 1.08
				profile["lane_scale"] = _terminal_scale_adjust(float(profile.get("lane_scale", 1.0)))
				profile["merge_scale"] = _terminal_scale_adjust(float(profile.get("merge_scale", 1.0)))
				profile["beacon_scale"] = _terminal_scale_adjust(float(profile.get("beacon_scale", 1.0)))
				profile["camera_pull"] = _terminal_scale_adjust(float(profile.get("camera_pull", 1.0)))
				profile["gate_move_lerp"] = _terminal_scale_adjust(float(profile.get("gate_move_lerp", 0.24)))
				profile["arrival_move_lerp"] = _terminal_scale_adjust(float(profile.get("arrival_move_lerp", 0.26)))
				profile["gate_fov"] = lerpf(float(profile.get("gate_fov", 47.0)), float(profile.get("gate_fov", 47.0)) + 1.4, minf(1.0, terminal_scale - 1.0))
				profile["arrival_fov"] = lerpf(float(profile.get("arrival_fov", 48.5)), float(profile.get("arrival_fov", 48.5)) + 1.6, minf(1.0, terminal_scale - 1.0))
			return profile
		"forest":
			var profile := {
				"lane_scale": 0.96,
				"merge_scale": 0.94,
				"beacon_scale": 0.96,
				"gate_move_lerp": 0.3,
				"arrival_move_lerp": 0.32,
				"gate_fov": 46.2,
				"arrival_fov": 47.4,
				"camera_height": 0.46,
				"camera_pull": 0.94,
			}
			if gate_id == "north_gate":
				profile["lane_scale"] = 1.04
				profile["camera_pull"] = 1.0
			elif gate_id == "west_gate":
				profile["beacon_scale"] = 1.02
			if terminal_focus:
				match _stage_shell_focus_band("terminal"):
					"pressure":
						profile["gate_move_lerp"] = 0.33
						profile["arrival_move_lerp"] = 0.35
						profile["gate_fov"] = 46.8
						profile["arrival_fov"] = 47.8
						profile["camera_pull"] = 0.98
						profile["merge_scale"] = float(profile.get("merge_scale", 1.0)) * 1.06
					"aftermath":
						profile["gate_move_lerp"] = 0.28
						profile["arrival_move_lerp"] = 0.3
						profile["gate_fov"] = 45.8
						profile["arrival_fov"] = 47.0
						profile["camera_pull"] = 1.04
						profile["lane_scale"] = float(profile.get("lane_scale", 1.0)) * 1.04
					"exit":
						profile["gate_move_lerp"] = 0.31
						profile["arrival_move_lerp"] = 0.33
						profile["gate_fov"] = 46.4
						profile["arrival_fov"] = 47.6
						profile["camera_pull"] = 0.96
						profile["beacon_scale"] = float(profile.get("beacon_scale", 1.0)) * 1.08
				profile["lane_scale"] = _terminal_scale_adjust(float(profile.get("lane_scale", 1.0)))
				profile["merge_scale"] = _terminal_scale_adjust(float(profile.get("merge_scale", 1.0)))
				profile["beacon_scale"] = _terminal_scale_adjust(float(profile.get("beacon_scale", 1.0)))
				profile["camera_pull"] = _terminal_scale_adjust(float(profile.get("camera_pull", 1.0)))
				profile["gate_move_lerp"] = _terminal_scale_adjust(float(profile.get("gate_move_lerp", 0.3)))
				profile["arrival_move_lerp"] = _terminal_scale_adjust(float(profile.get("arrival_move_lerp", 0.32)))
				profile["gate_fov"] = lerpf(float(profile.get("gate_fov", 46.2)), float(profile.get("gate_fov", 46.2)) + 1.2, minf(1.0, terminal_scale - 1.0))
				profile["arrival_fov"] = lerpf(float(profile.get("arrival_fov", 47.4)), float(profile.get("arrival_fov", 47.4)) + 1.4, minf(1.0, terminal_scale - 1.0))
			return profile
		"coast":
			var profile := {
				"lane_scale": 1.04,
				"merge_scale": 1.08,
				"beacon_scale": 1.18,
				"gate_move_lerp": 0.26,
				"arrival_move_lerp": 0.28,
				"gate_fov": 48.4,
				"arrival_fov": 49.4,
				"camera_height": 0.52,
				"camera_pull": 1.12,
			}
			if gate_id == "east_gate":
				profile["lane_scale"] = 1.14
				profile["beacon_scale"] = 1.24
			if terminal_focus:
				match _stage_shell_focus_band("terminal"):
					"pressure":
						profile["gate_move_lerp"] = 0.29
						profile["arrival_move_lerp"] = 0.31
						profile["gate_fov"] = 49.0
						profile["arrival_fov"] = 50.0
						profile["camera_pull"] = 1.18
						profile["merge_scale"] = float(profile.get("merge_scale", 1.0)) * 1.04
					"aftermath":
						profile["gate_move_lerp"] = 0.24
						profile["arrival_move_lerp"] = 0.26
						profile["gate_fov"] = 48.2
						profile["arrival_fov"] = 49.8
						profile["camera_pull"] = 1.24
						profile["lane_scale"] = float(profile.get("lane_scale", 1.0)) * 1.06
					"exit":
						profile["gate_move_lerp"] = 0.27
						profile["arrival_move_lerp"] = 0.29
						profile["gate_fov"] = 48.8
						profile["arrival_fov"] = 49.6
						profile["camera_pull"] = 1.14
						profile["beacon_scale"] = float(profile.get("beacon_scale", 1.0)) * 1.08
				profile["lane_scale"] = _terminal_scale_adjust(float(profile.get("lane_scale", 1.0)))
				profile["merge_scale"] = _terminal_scale_adjust(float(profile.get("merge_scale", 1.0)))
				profile["beacon_scale"] = _terminal_scale_adjust(float(profile.get("beacon_scale", 1.0)))
				profile["camera_pull"] = _terminal_scale_adjust(float(profile.get("camera_pull", 1.0)))
				profile["gate_move_lerp"] = _terminal_scale_adjust(float(profile.get("gate_move_lerp", 0.26)))
				profile["arrival_move_lerp"] = _terminal_scale_adjust(float(profile.get("arrival_move_lerp", 0.28)))
				profile["gate_fov"] = lerpf(float(profile.get("gate_fov", 48.4)), float(profile.get("gate_fov", 48.4)) + 1.4, minf(1.0, terminal_scale - 1.0))
				profile["arrival_fov"] = lerpf(float(profile.get("arrival_fov", 49.4)), float(profile.get("arrival_fov", 49.4)) + 1.6, minf(1.0, terminal_scale - 1.0))
			return profile
		_:
			var profile := {
				"lane_scale": 1.02,
				"merge_scale": 1.06,
				"beacon_scale": 1.08,
				"gate_move_lerp": 0.28,
				"arrival_move_lerp": 0.3,
				"gate_fov": 47.8,
				"arrival_fov": 48.8,
				"camera_height": 0.5,
				"camera_pull": 1.06,
			}
			if gate_id == "east_gate":
				profile["lane_scale"] = 1.12
			elif gate_id == "west_gate":
				profile["beacon_scale"] = 1.14
			if terminal_focus:
				match _stage_shell_focus_band("terminal"):
					"pressure":
						profile["gate_move_lerp"] = 0.31
						profile["arrival_move_lerp"] = 0.33
						profile["gate_fov"] = 48.4
						profile["arrival_fov"] = 49.4
						profile["camera_pull"] = 1.1
						profile["merge_scale"] = float(profile.get("merge_scale", 1.0)) * 1.06
					"aftermath":
						profile["gate_move_lerp"] = 0.26
						profile["arrival_move_lerp"] = 0.28
						profile["gate_fov"] = 47.4
						profile["arrival_fov"] = 49.0
						profile["camera_pull"] = 1.18
						profile["lane_scale"] = float(profile.get("lane_scale", 1.0)) * 1.05
					"exit":
						profile["gate_move_lerp"] = 0.29
						profile["arrival_move_lerp"] = 0.31
						profile["gate_fov"] = 48.0
						profile["arrival_fov"] = 49.2
						profile["camera_pull"] = 1.08
						profile["beacon_scale"] = float(profile.get("beacon_scale", 1.0)) * 1.08
				profile["lane_scale"] = _terminal_scale_adjust(float(profile.get("lane_scale", 1.0)))
				profile["merge_scale"] = _terminal_scale_adjust(float(profile.get("merge_scale", 1.0)))
				profile["beacon_scale"] = _terminal_scale_adjust(float(profile.get("beacon_scale", 1.0)))
				profile["camera_pull"] = _terminal_scale_adjust(float(profile.get("camera_pull", 1.0)))
				profile["gate_move_lerp"] = _terminal_scale_adjust(float(profile.get("gate_move_lerp", 0.28)))
				profile["arrival_move_lerp"] = _terminal_scale_adjust(float(profile.get("arrival_move_lerp", 0.3)))
				profile["gate_fov"] = lerpf(float(profile.get("gate_fov", 47.8)), float(profile.get("gate_fov", 47.8)) + 1.4, minf(1.0, terminal_scale - 1.0))
				profile["arrival_fov"] = lerpf(float(profile.get("arrival_fov", 48.8)), float(profile.get("arrival_fov", 48.8)) + 1.6, minf(1.0, terminal_scale - 1.0))
			return profile


func _route_stage_motion_profile() -> Dictionary:
	match current_route_stage:
		"entry":
			return {
				"base_speed_scale": 0.92,
				"sprint_scale": 0.94,
				"speed_blend_scale": 0.92,
				"movement_blend_scale": 0.94,
				"turn_lerp_scale": 1.06,
				"pose_lerp_scale": 0.96,
				"idle_pose_lerp_scale": 0.96,
				"idle_turn_lerp_scale": 1.0,
				"limb_lerp_scale": 0.94,
				"idle_limb_lerp_scale": 0.96,
				"bob_scale": 0.92,
				"bob_speed_scale": 0.92,
				"stride_scale": 0.9,
				"stride_speed_scale": 0.94,
				"tilt_scale": 0.9,
				"shadow_scale": 0.96,
				"camera_offset_scale": 0.94,
				"camera_look_scale": 0.86,
				"camera_lift_scale": 0.92,
				"camera_lerp_scale": 1.08,
				"fov_scale": 0.98,
				"fov_lerp_scale": 0.96,
				"camera_look_pull_scale": 0.9,
			}
		"branch":
			return {
				"base_speed_scale": 0.98,
				"sprint_scale": 0.96,
				"speed_blend_scale": 1.04,
				"movement_blend_scale": 1.06,
				"turn_lerp_scale": 1.14,
				"pose_lerp_scale": 1.06,
				"idle_pose_lerp_scale": 1.02,
				"idle_turn_lerp_scale": 1.04,
				"limb_lerp_scale": 1.08,
				"idle_limb_lerp_scale": 1.04,
				"bob_scale": 1.04,
				"bob_speed_scale": 1.08,
				"stride_scale": 1.04,
				"stride_speed_scale": 1.08,
				"tilt_scale": 1.06,
				"shadow_scale": 1.02,
				"camera_offset_scale": 0.9,
				"camera_look_scale": 0.96,
				"camera_lift_scale": 1.0,
				"camera_lerp_scale": 1.1,
				"fov_scale": 0.99,
				"fov_lerp_scale": 1.04,
				"camera_look_pull_scale": 1.02,
			}
		"terminal":
			var profile := {
				"base_speed_scale": 1.02,
				"sprint_scale": 1.08,
				"speed_blend_scale": 1.08,
				"movement_blend_scale": 1.08,
				"turn_lerp_scale": 1.12,
				"pose_lerp_scale": 1.08,
				"idle_pose_lerp_scale": 1.0,
				"idle_turn_lerp_scale": 1.02,
				"limb_lerp_scale": 1.08,
				"idle_limb_lerp_scale": 1.02,
				"bob_scale": 1.08,
				"bob_speed_scale": 1.06,
				"stride_scale": 1.06,
				"stride_speed_scale": 1.1,
				"tilt_scale": 1.08,
				"shadow_scale": 1.04,
				"camera_offset_scale": 1.02,
				"camera_look_scale": 1.08,
				"camera_lift_scale": 1.08,
				"camera_lerp_scale": 1.06,
				"fov_scale": 1.04,
				"fov_lerp_scale": 1.08,
				"camera_look_pull_scale": 1.08,
			}
			match _stage_shell_focus_band("terminal"):
				"pressure":
					profile["base_speed_scale"] = float(profile.get("base_speed_scale", 1.0)) * 1.04
					profile["sprint_scale"] = float(profile.get("sprint_scale", 1.0)) * 1.08
					profile["movement_blend_scale"] = float(profile.get("movement_blend_scale", 1.0)) * 1.06
					profile["turn_lerp_scale"] = float(profile.get("turn_lerp_scale", 1.0)) * 1.08
					profile["tilt_scale"] = float(profile.get("tilt_scale", 1.0)) * 1.08
					profile["camera_look_scale"] = float(profile.get("camera_look_scale", 1.0)) * 1.06
					profile["camera_lift_scale"] = float(profile.get("camera_lift_scale", 1.0)) * 1.04
					profile["fov_scale"] = float(profile.get("fov_scale", 1.0)) * 1.04
					profile["camera_look_pull_scale"] = float(profile.get("camera_look_pull_scale", 1.0)) * 1.08
				"aftermath":
					profile["base_speed_scale"] = float(profile.get("base_speed_scale", 1.0)) * 0.98
					profile["speed_blend_scale"] = float(profile.get("speed_blend_scale", 1.0)) * 0.96
					profile["movement_blend_scale"] = float(profile.get("movement_blend_scale", 1.0)) * 0.98
					profile["pose_lerp_scale"] = float(profile.get("pose_lerp_scale", 1.0)) * 1.04
					profile["bob_scale"] = float(profile.get("bob_scale", 1.0)) * 0.96
					profile["camera_offset_scale"] = float(profile.get("camera_offset_scale", 1.0)) * 1.03
					profile["camera_look_scale"] = float(profile.get("camera_look_scale", 1.0)) * 1.1
					profile["camera_lift_scale"] = float(profile.get("camera_lift_scale", 1.0)) * 1.08
					profile["camera_lerp_scale"] = float(profile.get("camera_lerp_scale", 1.0)) * 0.96
					profile["fov_scale"] = float(profile.get("fov_scale", 1.0)) * 1.02
					profile["camera_look_pull_scale"] = float(profile.get("camera_look_pull_scale", 1.0)) * 1.12
				"exit":
					profile["base_speed_scale"] = float(profile.get("base_speed_scale", 1.0)) * 1.02
					profile["sprint_scale"] = float(profile.get("sprint_scale", 1.0)) * 1.04
					profile["speed_blend_scale"] = float(profile.get("speed_blend_scale", 1.0)) * 1.02
					profile["turn_lerp_scale"] = float(profile.get("turn_lerp_scale", 1.0)) * 0.98
					profile["bob_scale"] = float(profile.get("bob_scale", 1.0)) * 0.94
					profile["stride_scale"] = float(profile.get("stride_scale", 1.0)) * 0.98
					profile["camera_offset_scale"] = float(profile.get("camera_offset_scale", 1.0)) * 1.08
					profile["camera_look_scale"] = float(profile.get("camera_look_scale", 1.0)) * 1.04
					profile["camera_lift_scale"] = float(profile.get("camera_lift_scale", 1.0)) * 0.96
					profile["camera_lerp_scale"] = float(profile.get("camera_lerp_scale", 1.0)) * 0.98
					profile["fov_scale"] = float(profile.get("fov_scale", 1.0)) * 1.06
					profile["camera_look_pull_scale"] = float(profile.get("camera_look_pull_scale", 1.0)) * 1.04
			profile["base_speed_scale"] = _terminal_scale_adjust(float(profile.get("base_speed_scale", 1.0)))
			profile["sprint_scale"] = _terminal_scale_adjust(float(profile.get("sprint_scale", 1.0)))
			profile["speed_blend_scale"] = _terminal_scale_adjust(float(profile.get("speed_blend_scale", 1.0)))
			profile["movement_blend_scale"] = _terminal_scale_adjust(float(profile.get("movement_blend_scale", 1.0)))
			profile["turn_lerp_scale"] = _terminal_scale_adjust(float(profile.get("turn_lerp_scale", 1.0)))
			profile["tilt_scale"] = _terminal_scale_adjust(float(profile.get("tilt_scale", 1.0)))
			profile["camera_look_scale"] = _terminal_scale_adjust(float(profile.get("camera_look_scale", 1.0)))
			profile["camera_lift_scale"] = _terminal_scale_adjust(float(profile.get("camera_lift_scale", 1.0)))
			profile["fov_scale"] = _terminal_scale_adjust(float(profile.get("fov_scale", 1.0)))
			profile["camera_look_pull_scale"] = _terminal_scale_adjust(float(profile.get("camera_look_pull_scale", 1.0)))
			return profile
		_:
			return {
				"base_speed_scale": 1.0,
				"sprint_scale": 1.0,
				"speed_blend_scale": 1.0,
				"movement_blend_scale": 1.0,
				"turn_lerp_scale": 1.0,
				"pose_lerp_scale": 1.0,
				"idle_pose_lerp_scale": 1.0,
				"idle_turn_lerp_scale": 1.0,
				"limb_lerp_scale": 1.0,
				"idle_limb_lerp_scale": 1.0,
				"bob_scale": 1.0,
				"bob_speed_scale": 1.0,
				"stride_scale": 1.0,
				"stride_speed_scale": 1.0,
				"tilt_scale": 1.0,
				"shadow_scale": 1.0,
				"camera_offset_scale": 1.0,
				"camera_look_scale": 1.0,
				"camera_lift_scale": 1.0,
				"camera_lerp_scale": 1.0,
				"fov_scale": 1.0,
				"fov_lerp_scale": 1.0,
				"camera_look_pull_scale": 1.0,
			}


func _route_stage_label() -> String:
	var shell_suffix := _stage_shell_focus_suffix()
	match current_biome:
		"wetland":
			match current_route_stage:
				"entry":
					return "栈桥入口段" + shell_suffix
				"branch":
					return "近水观察段" + shell_suffix
				"terminal":
					return "湿地终端段" + shell_suffix
				_:
					return "湿地主栈道" + shell_suffix
		"forest":
			match current_route_stage:
				"entry":
					return "林门入口段" + shell_suffix
				"branch":
					return "林下观察段" + shell_suffix
				"terminal":
					return "森林终端段" + shell_suffix
				_:
					return "森林主林道" + shell_suffix
		"coast":
			match current_route_stage:
				"entry":
					return "沿岸入口段" + shell_suffix
				"branch":
					return "岸侧观察段" + shell_suffix
				"terminal":
					return "海岸终端段" + shell_suffix
				_:
					return "海岸主路线" + shell_suffix
		_:
			match current_route_stage:
				"entry":
					return "草原入口段" + shell_suffix
				"branch":
					return "支路观察段" + shell_suffix
				"terminal":
					return "草原终端段" + shell_suffix
				_:
					return "草原主道" + shell_suffix


func _entry_screen_prompt_text(arrival: bool = false) -> String:
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var primary_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(primary_cfg.get("label", primary_hotspot_id))
	match _recommended_route_focus_kind():
		"entry_route", "trunk_route":
			return ("先顺入口主线读向 %s。" if arrival else "当前入口主线先读向 %s。") % hotspot_label
		"branch_route":
			return ("先顺推荐支链贴向 %s。" if arrival else "当前支链先贴向 %s。") % hotspot_label
		"chokepoint", "route_landmark":
			return ("先顺终端门段确认 %s。" if arrival else "当前终端链先确认 %s。") % hotspot_label
		_:
			return ""


func _entry_screen_signal_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var primary_cfg := _hotspot_task_config(primary_hotspot_id)
	return "当前首屏主线 · %s" % str(primary_cfg.get("label", primary_hotspot_id))


func _entry_screen_objective_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var primary_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(primary_cfg.get("label", primary_hotspot_id))
	match _recommended_route_focus_kind():
		"entry_route":
			return "当前引导 · 入口首段先沿主线确认 %s，再扩到出口和其它观察点。" % hotspot_label
		"trunk_route":
			return "当前引导 · 主路首段先沿主干推进到 %s，再判断是否转支线。" % hotspot_label
		"branch_route":
			return "当前引导 · 当前先贴支链吃到 %s，再扩观察面。" % hotspot_label
		"chokepoint", "route_landmark":
			return "当前引导 · 当前先顺门段确认 %s，再判断离场链。" % hotspot_label
		_:
			return ""


func _entry_screen_progress_text(arrival: bool = false) -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var primary_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(primary_cfg.get("label", primary_hotspot_id))
	match _recommended_route_focus_kind():
		"entry_route":
			return ("落地进度 · 先顺入口主线把 %s 读清，再扩到其它观察链。" if arrival else "当前进度 · 先顺入口主线把 %s 读清，再扩到其它观察链。") % hotspot_label
		"trunk_route":
			return ("落地进度 · 先沿主路推进到 %s，再决定是否转支线或压力链。" if arrival else "当前进度 · 先沿主路推进到 %s，再决定是否转支线或压力链。") % hotspot_label
		"branch_route":
			return ("落地进度 · 先贴支链吃到 %s，再扩观察面。" if arrival else "当前进度 · 先贴支链吃到 %s，再扩观察面。") % hotspot_label
		"chokepoint", "route_landmark":
			return ("落地进度 · 先顺门段确认 %s，再判断离场条件。" if arrival else "当前进度 · 先顺门段确认 %s，再判断离场条件。") % hotspot_label
		_:
			return ""


func _entry_screen_objective_line() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(task_cfg.get("label", primary_hotspot_id))
	var category_label := str(task_cfg.get("required_category", "区域生物"))
	match _recommended_route_focus_kind():
		"entry_route":
			return "当前生态导引 · 先顺入口主线读清 %s（%s）" % [hotspot_label, category_label]
		"trunk_route":
			return "当前生态导引 · 先沿主路推进到 %s（%s）" % [hotspot_label, category_label]
		"branch_route":
			return "当前生态导引 · 先贴支链吃到 %s（%s）" % [hotspot_label, category_label]
		"chokepoint", "route_landmark":
			return "当前生态导引 · 先顺门段确认 %s（%s）" % [hotspot_label, category_label]
		_:
			return ""


func _entry_screen_species_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(task_cfg.get("label", primary_hotspot_id))
	var category_label := str(task_cfg.get("required_category", "区域生物"))
	return "首屏观察优先 · 先看 %s 附近的%s。" % [hotspot_label, category_label]


func _entry_screen_log_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(task_cfg.get("label", primary_hotspot_id))
	return "首屏记录优先 · 先记 %s 的入口线、首批生物和主路关系。" % hotspot_label


func _entry_screen_event_short_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(task_cfg.get("label", primary_hotspot_id))
	match _recommended_route_focus_kind():
		"entry_route":
			return "首屏默认事件 · 先顺入口主线读清 %s。" % hotspot_label
		"trunk_route":
			return "首屏默认事件 · 先沿主路推进到 %s。" % hotspot_label
		"branch_route":
			return "首屏默认事件 · 先贴支链吃到 %s。" % hotspot_label
		"chokepoint", "route_landmark":
			return "首屏默认事件 · 先顺门段确认 %s。" % hotspot_label
		_:
			return ""


func _gate_focus_prompt_text() -> String:
	var gate_hold := smoothed_gate_focus_hold if smoothed_gate_focus_hold > 0.0 else _gate_focus_hold_strength()
	if gate_hold <= 0.42:
		return ""
	if _recommended_route_focus_kind() in ["chokepoint", "route_landmark"] or current_route_stage == "terminal":
		return ""
	match current_biome:
		"wetland":
			return "当前已进入离场判断段，先对齐栈桥门向和出口线。"
		"forest":
			return "当前已进入离场判断段，先对齐树门门向和出口线。"
		"coast":
			return "当前已进入离场判断段，先对齐岸线门向和出口线。"
		_:
			return "当前已进入离场判断段，先对齐主道门向和出口线。"


func _gate_focus_event_short_text() -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	var gate_reason := _recommended_exit_gate_reason()
	return "离场判断段 · 先对齐门向和出口线。%s" % gate_reason


func _entry_screen_objective_short_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(task_cfg.get("label", primary_hotspot_id))
	return "首屏目标 · 先读清 %s。" % hotspot_label


func _gate_focus_objective_short_text() -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	return "离场目标 · 先稳住门向和出口线。"


func _entry_screen_completion_short_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	return "首屏完成导引 · 先把主热点链立稳。"


func _gate_focus_completion_short_text() -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	return "离场完成导引 · 先确认门向、出口线和切区条件。"


func _entry_screen_chase_short_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	return "首屏追猎导引 · 先别被旁线带走，先读清 %s。" % str(task_cfg.get("label", primary_hotspot_id))


func _gate_focus_chase_short_text() -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	return "离场追猎导引 · 只保留与门段和出口线相关的最后竞争。"


func _entry_screen_species_short_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	return "首屏图鉴 · 先看 %s。" % str(task_cfg.get("label", primary_hotspot_id))


func _gate_focus_species_short_text() -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	return "离场图鉴 · 先看门段、出口线和最后目标。"


func _entry_screen_log_short_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	return "首屏记录 · 先记 %s。" % str(task_cfg.get("label", primary_hotspot_id))


func _gate_focus_log_short_text() -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	return "离场记录 · 先记门向、出口线和最后竞争。"


func _entry_screen_event_text() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return ""
	var task_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(task_cfg.get("label", primary_hotspot_id))
	match _recommended_route_focus_kind():
		"entry_route":
			return "当前默认事件 · 先顺入口主线锁定 %s。" % hotspot_label
		"trunk_route":
			return "当前默认事件 · 先沿主路推进并锁定 %s。" % hotspot_label
		"branch_route":
			return "当前默认事件 · 先贴支链吃到 %s。" % hotspot_label
		"chokepoint", "route_landmark":
			return "当前默认事件 · 先顺门段确认 %s。" % hotspot_label
		_:
			return ""


func _gate_focus_progress_text(arrival: bool = false) -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	if arrival:
		return "落地进度 · 当前先稳住门向和出口线，再判断是否继续观察或直接离场。"
	return "当前进度 · 当前先稳住门向和出口线，再判断是否继续观察或直接离场。"


func _gate_focus_completion_text(arrival: bool = false) -> String:
	var gate_prompt := _gate_focus_prompt_text()
	if gate_prompt == "":
		return ""
	var completion_state := _dynamic_completion_state()
	var gate_reason := _recommended_exit_gate_reason()
	if arrival:
		return "落地完成导引 · 当前已进入离场判断段，优先确认门向、出口线和切区条件。%s %s" % [str(completion_state.get("summary", "")), gate_reason]
	return "当前阶段导引 · 当前已进入离场判断段，优先确认门向、出口线和切区条件。%s %s" % [str(completion_state.get("summary", "")), gate_reason]


func _route_stage_prompt() -> String:
	var terminal_signal := _terminal_signal_text()
	var terminal_action := _recommended_terminal_action_text()
	var entry_screen_prompt := _entry_screen_prompt_text()
	match current_route_stage:
		"entry":
			if entry_screen_prompt != "":
				return entry_screen_prompt
			match current_biome:
				"wetland":
					return "先沿栈桥入口推进，出口线会更早暴露。"
				"forest":
					return "先贴树门和林道前段推进，热点会压后出现。"
				"coast":
					return "先沿岸入口推进，远侧出口和岸线导流会更显眼。"
				_:
					return "先沿草原入口推进，主道和出口会比支路更先被读到。"
		"branch":
			match current_biome:
				"wetland":
					return "当前更偏近水观察，浅滩与栈道热点会更快聚焦。"
				"forest":
					return "当前更偏穿遮挡找观察点，林下热点会更快锁定。"
				"coast":
					return "当前更偏沿岸支路观察，岸侧热点会更快被强化。"
				_:
					return "当前更偏支路探索，热点与观察对象会更快进入视野。"
		"terminal":
			match current_biome:
				"wetland":
					return "当前更偏终端区，出口和近水余波会更强。%s %s" % [terminal_action, terminal_signal]
				"forest":
					return "当前更偏终端区，树门出口和林缘事件会更强。%s %s" % [terminal_action, terminal_signal]
				"coast":
					return "当前更偏终端区，岸线出口和沿岸余波会更强。%s %s" % [terminal_action, terminal_signal]
				_:
					return "当前更偏终端区，出口和开阔地余波会更强。%s %s" % [terminal_action, terminal_signal]
		_:
			match current_biome:
				"wetland":
					return "当前位于湿地主栈道，路线与近水群落最稳定。"
				"forest":
					return "当前位于森林主林道，主路推进最稳定。"
				"coast":
					return "当前位于海岸主路线，沿岸导流最稳定。"
				_:
					return "当前位于草原主道，开阔推进和迁徙带读法最稳定。"


func _exit_focus_point() -> Vector3:
	if current_exit_layouts.is_empty():
		return _hotspot_pos("migration_corridor")
	var accum := Vector3.ZERO
	for layout in current_exit_layouts:
		accum += Vector3(layout.get("pos", Vector3.ZERO))
	return accum / float(current_exit_layouts.size())


func _gate_focus_point(gate_id: String) -> Vector3:
	if not current_exit_zone.is_empty() and str(current_exit_zone.get("id", "")) == gate_id:
		return Vector3(current_exit_zone.get("position", Vector3.ZERO))
	for layout in current_exit_layouts:
		if str(layout.get("id", "")) == gate_id:
			return Vector3(layout.get("pos", Vector3.ZERO))
	return _exit_focus_point()


func _biome_ambient_profile() -> Dictionary:
	var spread_scale := _world_spread_scale()
	match current_biome:
		"wetland":
			return {
				"accent": current_theme.get("accent", Color8(178, 222, 176)),
				"support": current_theme.get("water", Color8(74, 136, 154)),
				"reveal_radius": 20.0 * spread_scale,
				"focus_radius": 8.8 * spread_scale,
				"active_scale": 1.22,
				"beacon_scale": 1.18,
				"sway_speed": 1.4,
				"sway_amount": 0.16,
			}
		"forest":
			return {
				"accent": current_theme.get("accent", Color8(170, 206, 156)),
				"support": current_theme.get("foliage", Color8(64, 96, 64)),
				"reveal_radius": 16.0 * spread_scale,
				"focus_radius": 7.2 * spread_scale,
				"active_scale": 1.28,
				"beacon_scale": 1.12,
				"sway_speed": 1.1,
				"sway_amount": 0.1,
			}
		"coast":
			return {
				"accent": current_theme.get("accent", Color8(216, 222, 180)),
				"support": current_theme.get("water", Color8(76, 156, 196)),
				"reveal_radius": 22.0 * spread_scale,
				"focus_radius": 9.4 * spread_scale,
				"active_scale": 1.18,
				"beacon_scale": 1.22,
				"sway_speed": 1.8,
				"sway_amount": 0.12,
			}
		_:
			return {
				"accent": current_theme.get("accent", Color8(236, 202, 118)),
				"support": current_theme.get("route", Color8(240, 223, 176)),
				"reveal_radius": 21.0 * spread_scale,
				"focus_radius": 8.4 * spread_scale,
				"active_scale": 1.2,
				"beacon_scale": 1.16,
				"sway_speed": 1.55,
				"sway_amount": 0.11,
			}


func _update_spatial_visibility() -> void:
	var player_pos := _player_vec2()
	var stage_profile := _route_stage_signal_profile()
	var progress_profile := _progress_stage_signal_profile()
	var stage_animal_reveal := float(stage_profile.get("animal_reveal_scale", 1.0))
	var progress_animal_reveal := float(progress_profile.get("animal_scale", 1.0))
	var pressure_window := _dynamic_pressure_window()
	var encounter_progress_focus := _progress_stage_interaction_focus("encounter")
	var arrival_boost := _arrival_recommended_focus_boost("encounter")
	var entry_screen_strength := _entry_screen_focus_strength()
	var recommended_focus_kind := _recommended_route_focus_kind()
	var gate_focus_scale := _gate_focus_competition_scale("encounter")
	var focus_category := _route_stage_focus_category()
	var hotspot_target_category := ""
	if not current_hotspot.is_empty():
		hotspot_target_category = str(_hotspot_task_config(str(current_hotspot.get("hotspot_id", ""))).get("required_category", ""))
	elif entry_screen_strength > 0.0:
		var entry_hotspot_id := _entry_screen_primary_hotspot_id()
		if entry_hotspot_id != "":
			hotspot_target_category = str(_hotspot_task_config(entry_hotspot_id).get("required_category", ""))
	var encounter_species_id := str(current_encounter.get("species_id", ""))
	for animal in wildlife:
		var root: Node3D = animal.get("node", null)
		if root == null:
			continue
		var member_root: Node3D = animal.get("member_root", null)
		var marker_root: Node3D = animal.get("marker_root", null)
		var marker_ring: MeshInstance3D = animal.get("marker_ring", null)
		var marker_beacon: MeshInstance3D = animal.get("marker_beacon", null)
		var dist := player_pos.distance_to(animal.get("position", Vector2.ZERO))
		var category := str(animal.get("category", "区域生物"))
		var role := str(animal.get("role", "member"))
		var stage_animal_profile := _route_stage_animal_profile(animal)
		var route_focus_boost := _route_focus_channel_boost("encounter", Vector3(animal.get("position", Vector2.ZERO).x, 0.0, animal.get("position", Vector2.ZERO).y))
		var dynamic_reveal := _dynamic_cluster_scale(category, "visibility_scale", 1.0)
		var visible_radius := _animal_visible_radius(animal) * 1.24 * stage_animal_reveal * progress_animal_reveal * float(pressure_window.get("encounter_scale", 1.0)) * encounter_progress_focus * float(stage_animal_profile.get("reveal_scale", 1.0)) * dynamic_reveal * route_focus_boost * arrival_boost * gate_focus_scale
		var should_show := dist < visible_radius or bool(animal.get("alerted", false)) or bool(animal.get("look_back", false)) or float(animal.get("signal_timer", 0.0)) > 0.08 or str(current_encounter.get("species_id", "")) == str(animal.get("species_id", ""))
		var spotlight_match := str(animal.get("species_id", "")) == encounter_species_id or (hotspot_target_category != "" and category == hotspot_target_category)
		var marker_visible_radius := visible_radius * 1.72
		if entry_screen_strength > 0.0 and recommended_focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"] and not spotlight_match and category != focus_category and role not in ["leader", "sentry", "alpha"]:
			marker_visible_radius *= lerpf(1.0, 0.76, entry_screen_strength)
		var marker_show := dist < marker_visible_radius and (
			category == focus_category
			or role in ["leader", "sentry", "alpha"]
			or float(stage_animal_profile.get("prominence_scale", 1.0)) > 1.04
			or spotlight_match
			or str(current_encounter.get("species_id", "")) == str(animal.get("species_id", ""))
		)
		root.visible = should_show or marker_show
		if member_root != null:
			member_root.visible = should_show
		if marker_root != null:
			marker_root.visible = marker_show
		if marker_ring != null and marker_ring.material_override is StandardMaterial3D:
			var ring_mat := marker_ring.material_override as StandardMaterial3D
			ring_mat.albedo_color.a = lerpf(ring_mat.albedo_color.a, 0.64 if marker_show else 0.0, 0.22)
		if marker_beacon != null and marker_beacon.material_override is StandardMaterial3D:
			var beacon_mat := marker_beacon.material_override as StandardMaterial3D
			beacon_mat.albedo_color.a = lerpf(beacon_mat.albedo_color.a, 0.88 if marker_show else 0.0, 0.22)


func _update_gate_transition(delta: float) -> void:
	if pending_gate_transition.is_empty():
		return
	var timer := maxf(0.0, float(pending_gate_transition.get("timer", 0.0)) - delta)
	pending_gate_transition["timer"] = timer
	if timer > 0.0:
		return
	var target_region_id := str(pending_gate_transition.get("target_region_id", ""))
	var gate_id := str(pending_gate_transition.get("gate_id", ""))
	pending_gate_transition.clear()
	show_codex = transition_restore_codex
	codex_panel.visible = show_codex
	if target_region_id != "":
		_apply_region(target_region_id, gate_id)


func _update_arrival_intro(delta: float) -> void:
	if pending_arrival_intro.is_empty():
		return
	var timer := maxf(0.0, float(pending_arrival_intro.get("timer", 0.0)) - delta)
	pending_arrival_intro["timer"] = timer
	if timer > 0.0:
		return
	arrival_event_focus_timer = 3.2
	pending_arrival_intro.clear()


func _transition_overlay_profile() -> Dictionary:
	var kind := str(current_route_focus.get("kind", "trunk_route"))
	var profile: Dictionary
	match kind:
		"entry_route", "entry_marker":
			profile = {"alpha_scale": 1.0, "zoom_scale": 0.024}
		"branch_route", "branch_marker":
			profile = {"alpha_scale": 1.08, "zoom_scale": 0.036}
		"chokepoint", "route_landmark":
			profile = {"alpha_scale": 1.14, "zoom_scale": 0.044}
		_:
			profile = {"alpha_scale": 1.04, "zoom_scale": 0.03}
	var progress_boost := _progress_stage_transition_profile()
	profile["alpha_scale"] = float(profile.get("alpha_scale", 1.0)) * float(progress_boost.get("alpha_scale", 1.0))
	profile["zoom_scale"] = float(profile.get("zoom_scale", 0.03)) * float(progress_boost.get("zoom_scale", 1.0))
	var exit_state := _dynamic_exit_state()
	var transition_push_scale := float(exit_state.get("transition_push_scale", 1.0))
	profile["alpha_scale"] = float(profile.get("alpha_scale", 1.0)) * transition_push_scale
	profile["zoom_scale"] = float(profile.get("zoom_scale", 0.03)) * lerpf(0.96, 1.16, clampf(transition_push_scale - 0.92, 0.0, 0.32) / 0.32)
	var shell_profile := _stage_shell_transition_profile(_stage_shell_focus_band(_route_focus_stage_name(kind)))
	profile["alpha_scale"] = float(profile.get("alpha_scale", 1.0)) * float(shell_profile.get("alpha_scale", 1.0))
	profile["zoom_scale"] = float(profile.get("zoom_scale", 0.03)) * float(shell_profile.get("zoom_scale", 1.0))
	if kind in ["chokepoint", "route_landmark"]:
		var terminal_scale := _recommended_terminal_scale()
		profile["alpha_scale"] = float(profile.get("alpha_scale", 1.0)) * lerpf(1.0, 1.12, minf(1.0, terminal_scale - 1.0))
		profile["zoom_scale"] = float(profile.get("zoom_scale", 0.03)) * lerpf(1.0, 1.1, minf(1.0, terminal_scale - 1.0))
	return profile


func _transition_focus_title(arrival: bool) -> String:
	var kind := str(current_route_focus.get("kind", "trunk_route"))
	var exit_state := _dynamic_exit_state()
	var focus_stage := _route_focus_stage_name(kind)
	var shell_suffix := _stage_shell_transition_suffix(_stage_shell_focus_band(focus_stage))
	if not _recommended_exit_gate_id().is_empty():
		var recommended_title := str(exit_state.get("recommended_arrival_title" if arrival else "recommended_transition_title", ""))
		if recommended_title != "":
			var progress_prefix := _progress_stage_transition_prefix()
			var shell_title := recommended_title if shell_suffix == "" else "%s · %s" % [recommended_title, shell_suffix]
			return "%s · %s · %s" % [progress_prefix, shell_title, _recommended_exit_gate_id()]
	var base_title := ""
	match kind:
		"entry_route", "entry_marker":
			base_title = "入口落地" if arrival else "入口导入"
		"branch_route", "branch_marker":
			base_title = "支路导入" if arrival else "支路回接"
		"chokepoint", "route_landmark":
			base_title = "终端落地" if arrival else "终端转出"
		_:
			base_title = "主路并入" if arrival else "主路切换"
	var progress_prefix := _progress_stage_transition_prefix()
	var gate_hint := ""
	if _recommended_exit_gate_id() != "":
		gate_hint = " · " + _recommended_exit_gate_id()
	var titled := base_title if shell_suffix == "" else "%s · %s" % [base_title, shell_suffix]
	return "%s · %s%s" % [progress_prefix, titled, gate_hint]


func _transition_overlay_text(region_name: String, biome_name: String, from_gate: bool, progress: float = -1.0) -> String:
	var phase_title := _transition_focus_title(not from_gate)
	var phase_body := _transition_focus_body(not from_gate)
	if progress >= 0.0:
		return "%s\n%s · %d%%\n%s" % [str(region_name), phase_title, int(round(progress * 100.0)), phase_body]
	return "%s\n%s · %s\n%s" % [str(region_name), phase_title, str(biome_name), phase_body]


func _start_region_transition(region_name: String, biome_name: String, from_gate: bool) -> void:
	transition_duration = 1.8 if from_gate else 1.2
	transition_timer = transition_duration
	if transition_label != null:
		transition_label.text = _transition_overlay_text(region_name, biome_name, from_gate)
	if transition_panel != null:
		transition_panel.visible = true
		transition_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_transition_overlay(delta: float) -> void:
	if transition_panel == null:
		return
	if transition_timer <= 0.0:
		transition_panel.visible = false
		return
	transition_timer = maxf(0.0, transition_timer - delta)
	var t := transition_timer / maxf(0.001, transition_duration)
	if transition_label != null:
		if not pending_gate_transition.is_empty():
			var gate_duration := maxf(0.001, float(pending_gate_transition.get("duration", 1.0)))
			var gate_timer := float(pending_gate_transition.get("timer", 0.0))
			var gate_progress := clampf(1.0 - gate_timer / gate_duration, 0.0, 1.0)
			transition_label.text = _transition_overlay_text(str(pending_gate_transition.get("label", "下一片区域")), "路线切换中", true, gate_progress)
		elif not pending_arrival_intro.is_empty():
			var arrival_duration := maxf(0.001, float(pending_arrival_intro.get("duration", 1.0)))
			var arrival_timer := float(pending_arrival_intro.get("timer", 0.0))
			var arrival_progress := clampf(1.0 - arrival_timer / arrival_duration, 0.0, 1.0)
			transition_label.text = _transition_overlay_text(str(pending_arrival_intro.get("label", "新区域")), _biome_label(current_biome), false, arrival_progress)
	transition_panel.visible = true
	var overlay_profile := _transition_overlay_profile()
	transition_panel.modulate.a = clampf(t * 1.2 * float(overlay_profile.get("alpha_scale", 1.0)), 0.0, 1.0)
	transition_panel.scale = Vector2.ONE * (1.0 + (1.0 - t) * float(overlay_profile.get("zoom_scale", 0.03)))


func _update_event_focus() -> void:
	current_event.clear()
	if not pending_gate_transition.is_empty():
		var duration := maxf(0.001, float(pending_gate_transition.get("duration", 1.0)))
		var timer := float(pending_gate_transition.get("timer", 0.0))
		var progress := clampf(1.0 - timer / duration, 0.0, 1.0)
		current_event = _biome_transition_event(str(pending_gate_transition.get("label", "下一片区域")), progress)
		return
	if not pending_arrival_intro.is_empty():
		var duration2 := maxf(0.001, float(pending_arrival_intro.get("duration", 1.0)))
		var timer2 := float(pending_arrival_intro.get("timer", 0.0))
		var progress2 := clampf(1.0 - timer2 / duration2, 0.0, 1.0)
		current_event = _biome_arrival_event(str(pending_arrival_intro.get("label", "新区域")), progress2)
		return
	var candidates: Array = []
	if not current_exit_zone.is_empty():
		candidates.append({"kind": "exit", "payload": _biome_exit_event(str(current_exit_zone.get("hint", "")))})
	if not current_chase_result.is_empty():
		candidates.append({"kind": "chase_result", "payload": current_chase_result})
	if not chase_aftermath.is_empty():
		candidates.append({"kind": "aftermath", "payload": chase_aftermath})
	if not current_chase.is_empty():
		candidates.append({"kind": "chase", "payload": current_chase})
	if not current_interaction.is_empty():
		candidates.append({"kind": "interaction", "payload": current_interaction})
	if not current_task.is_empty():
		candidates.append({"kind": "task", "payload": current_task})
	if not current_hotspot.is_empty():
		candidates.append({"kind": "hotspot", "payload": _biome_hotspot_event(str(current_hotspot.get("label", "")), str(current_hotspot.get("summary", "")))})
	if not current_encounter.is_empty():
		candidates.append({"kind": "encounter", "payload": _biome_encounter_event(str(current_encounter.get("label", "")), str(current_encounter.get("category", "")))})
	var best_score := -999999
	var interaction_state := _dynamic_interaction_state()
	var event_state := _dynamic_event_state()
	var completion_state := _dynamic_completion_state()
	var dominant_interaction := str(interaction_state.get("dominant_interaction", ""))
	var active_event_band := str(event_state.get("active_event_band", ""))
	var completion_bias := 0.0
	match str(completion_state.get("readiness_band", "observe")):
		"prepare":
			completion_bias = 0.22
		"transition":
			completion_bias = 0.42
	for candidate in candidates:
		var kind := str(candidate.get("kind", ""))
		var score := _route_stage_event_priority(kind) + _route_focus_event_boost(kind, candidate.get("payload", {})) + _progress_stage_event_boost(kind) + _arrival_event_focus_boost(kind)
		score += _stage_shell_event_boost(kind)
		score += _entry_screen_event_boost(kind)
		score += _gate_focus_event_boost(kind)
		score += _gate_focus_event_clamp(kind)
		if kind == "chase":
			score += float(event_state.get("chase_scale", 1.0)) * 0.7
			if dominant_interaction == "predation":
				score += 0.45
		elif kind == "chase_result" or kind == "aftermath":
			score += float(event_state.get("aftermath_scale", 1.0)) * 0.72
			if active_event_band == "aftermath":
				score += 0.5
			score += _arrival_result_event_boost(kind)
		elif kind == "hotspot" or kind == "task":
			score += float(event_state.get("migration_scale", 1.0)) * 0.42
			if dominant_interaction == "migration" or dominant_interaction == "water":
				score += 0.28
		elif kind == "encounter":
			score += float(interaction_state.get("predation_scale", 1.0)) * 0.24
			score += float(interaction_state.get("water_dependence_scale", 1.0)) * 0.18
		elif kind == "exit":
			score += float(event_state.get("exit_push_scale", 1.0)) * 0.5
			score += float(_dynamic_exit_state().get("force_exit_push_scale", 1.0)) * 0.38
			if str(current_exit_zone.get("id", "")) == _recommended_exit_gate_id():
				score += float(_dynamic_exit_state().get("recommended_gate_scale", 1.0)) * 0.4
			score += completion_bias
		elif kind == "chase_result" or kind == "aftermath":
			score += completion_bias * 0.46
		if score > best_score:
			best_score = score
			current_event = candidate.get("payload", {})


func _update_hotspot_task() -> void:
	if current_hotspot.is_empty():
		return
	var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
	var task_id := "task_" + hotspot_id
	var task_config := _hotspot_task_config(hotspot_id)
	var required_time := float(task_config.get("required_time", 2.0))
	var required_category := str(task_config.get("required_category", ""))
	var required_radius := float(task_config.get("required_radius", 4.2))
	var hotspot_label := str(current_hotspot.get("label", "热点"))
	var stage_hint := str(task_config.get("stage_hint", ""))
	var center := _hotspot_pos(hotspot_id)
	var has_required := required_category == "" or _has_nearby_category(required_category, Vector2(center.x, center.z), required_radius)
	if completed_task_ids.has(task_id):
		current_task = {
			"title": "观察完成",
			"body": "%s 的%s已经记录进图鉴。%s" % [hotspot_label, str(task_config.get("noun", "观察")), stage_hint],
		}
		return
	if hotspot_focus_time >= required_time:
		if not has_required:
			current_task = {
				"title": str(task_config.get("title", "观察目标")),
				"body": "%s 还缺少%s，继续等待对应生物靠近。%s" % [hotspot_label, required_category, stage_hint],
			}
			return
		completed_task_ids[task_id] = true
		discovery_log.push_front(_route_stage_log_entry("task_complete", "%s：%s" % [str(task_config.get("noun", "观察")), hotspot_label]))
		discovery_log = discovery_log.slice(0, 6)
		current_task = {
			"title": "观察完成",
			"body": "%s 的%s已完成。%s" % [hotspot_label, str(task_config.get("noun", "观察")), stage_hint],
		}
		return
	current_task = {
		"title": str(task_config.get("title", "观察目标")),
		"body": "%s · %s %.1f / %.1f 秒%s" % [
			hotspot_label,
			str(task_config.get("prompt", "停留记录")),
			hotspot_focus_time,
			required_time,
			("" if required_category == "" else " · 目标：" + required_category) + (" · " + stage_hint if stage_hint != "" else ""),
		],
	}


func _hotspot_task_config(hotspot_id: String) -> Dictionary:
	var base_config: Dictionary = {}
	var objective_state := _dynamic_objective_state()
	var hotspot_window := _dynamic_hotspot_window(hotspot_id)
	match current_biome:
		"wetland":
			match hotspot_id:
				"waterhole":
					base_config = {"required_time": 1.5, "title": "浅滩采样", "prompt": "记录浅滩近水活动", "noun": "浅滩观察", "required_category": "水域动物", "required_radius": 5.0}
				"migration_corridor":
					base_config = {"required_time": 2.4, "title": "栈道观察", "prompt": "沿栈桥跟进迁移活动", "noun": "栈道观察", "required_category": "草食动物", "required_radius": 4.6}
				"predator_ridge":
					base_config = {"required_time": 2.2, "title": "湿地盯防", "prompt": "观察湿地边缘掠食压迫", "noun": "湿地掠食观察", "required_category": "掠食者", "required_radius": 4.0}
				"carrion_field":
					base_config = {"required_time": 1.8, "title": "腐食盘旋", "prompt": "记录湿地腐食盘旋", "noun": "湿地腐食观察", "required_category": "飞行动物", "required_radius": 5.0}
				_:
					base_config = {"required_time": 1.9, "title": "芦苇栖地观察", "prompt": "记录芦苇带驻留", "noun": "湿地栖地观察"}
		"forest":
			match hotspot_id:
				"waterhole":
					base_config = {"required_time": 2.0, "title": "林下水坑观察", "prompt": "穿过遮挡记录林下饮水", "noun": "林下水源观察", "required_category": "水域动物", "required_radius": 3.8}
				"migration_corridor":
					base_config = {"required_time": 2.6, "title": "林道追迹", "prompt": "沿林道跟进群体穿行", "noun": "林道迁徙观察", "required_category": "草食动物", "required_radius": 3.8}
				"predator_ridge":
					base_config = {"required_time": 2.5, "title": "伏击高点观察", "prompt": "盯防林缘伏击活动", "noun": "林缘掠食观察", "required_category": "掠食者", "required_radius": 3.6}
				"carrion_field":
					base_config = {"required_time": 2.2, "title": "林空腐食观察", "prompt": "记录林空盘旋与腐食响应", "noun": "林空腐食观察", "required_category": "飞行动物", "required_radius": 4.0}
				_:
					base_config = {"required_time": 2.1, "title": "林下栖地观察", "prompt": "穿过树门记录栖地驻留", "noun": "林下栖地观察"}
		"coast":
			match hotspot_id:
				"waterhole":
					base_config = {"required_time": 1.7, "title": "岸线水点采样", "prompt": "沿岸记录浅水活动", "noun": "岸线水源观察", "required_category": "水域动物", "required_radius": 4.8}
				"migration_corridor":
					base_config = {"required_time": 2.1, "title": "岸线导流观察", "prompt": "顺着岸线追踪迁徙", "noun": "岸线迁徙观察", "required_category": "草食动物", "required_radius": 4.4}
				"predator_ridge":
					base_config = {"required_time": 2.3, "title": "岸崖掠食观察", "prompt": "观察岸崖压迫与逼近", "noun": "岸崖掠食观察", "required_category": "掠食者", "required_radius": 3.8}
				"carrion_field":
					base_config = {"required_time": 1.9, "title": "海风腐食盘旋", "prompt": "记录岸侧盘旋与聚集", "noun": "岸侧腐食观察", "required_category": "飞行动物", "required_radius": 5.2}
				_:
					base_config = {"required_time": 1.9, "title": "岸带栖地观察", "prompt": "沿岸记录栖地驻留", "noun": "岸带栖地观察"}
		_:
			match hotspot_id:
				"waterhole":
					base_config = {"required_time": 1.8, "title": "水源采样", "prompt": "记录开阔水源驻留", "noun": "水源观察", "required_category": "水域动物", "required_radius": 4.6}
				"migration_corridor":
					base_config = {"required_time": 2.0, "title": "迁徙观察", "prompt": "在开阔带跟进迁徙活动", "noun": "迁徙观察", "required_category": "草食动物", "required_radius": 5.0}
				"predator_ridge":
					base_config = {"required_time": 2.3, "title": "高地盯防", "prompt": "观察高地掠食压迫", "noun": "掠食观察", "required_category": "掠食者", "required_radius": 4.0}
				"carrion_field":
					base_config = {"required_time": 2.0, "title": "腐食观察", "prompt": "记录开阔腐食活动", "noun": "腐食观察", "required_category": "飞行动物", "required_radius": 5.0}
				_:
					base_config = {"required_time": 2.0, "title": "栖地观察", "prompt": "记录开阔栖地驻留", "noun": "栖地观察"}
	var stage_profile := _route_stage_task_profile(hotspot_id)
	base_config["required_time"] = float(base_config.get("required_time", 2.0)) * float(stage_profile.get("required_time_scale", 1.0))
	base_config["required_radius"] = float(base_config.get("required_radius", 4.2)) * float(stage_profile.get("required_radius_scale", 1.0))
	if hotspot_id == str(objective_state.get("primary_hotspot", "")):
		base_config["required_time"] = float(base_config.get("required_time", 2.0)) * float(objective_state.get("task_time_scale", 1.0))
		base_config["required_radius"] = float(base_config.get("required_radius", 4.2)) * float(objective_state.get("task_radius_scale", 1.0))
	elif hotspot_id == str(objective_state.get("secondary_hotspot", "")):
		base_config["required_time"] = float(base_config.get("required_time", 2.0)) * 1.04
	base_config["required_time"] = float(base_config.get("required_time", 2.0)) / maxf(0.001, float(hotspot_window.get("task_scale", 1.0)))
	if arrival_event_focus_timer > 0.0:
		match _recommended_route_focus_kind():
			"branch_route":
				base_config["required_time"] = float(base_config.get("required_time", 2.0)) * 0.88
				base_config["required_radius"] = float(base_config.get("required_radius", 4.2)) * 1.08
			"entry_route", "trunk_route":
				base_config["required_time"] = float(base_config.get("required_time", 2.0)) * 1.06
				base_config["required_radius"] = float(base_config.get("required_radius", 4.2)) * 0.94
			"chokepoint", "route_landmark":
				var terminal_scale := _recommended_terminal_scale()
				if hotspot_id in ["predator_ridge", "carrion_field"]:
					base_config["required_time"] = float(base_config.get("required_time", 2.0)) * lerpf(0.9, 0.78, minf(1.0, terminal_scale - 1.0))
					base_config["required_radius"] = float(base_config.get("required_radius", 4.2)) * lerpf(1.08, 1.18, minf(1.0, terminal_scale - 1.0))
					base_config["stage_hint"] = "当前为终端压力段，优先确认压力/余波热点。%s %s" % [_recommended_terminal_scale_text(), _recommended_terminal_reason()]
				else:
					base_config["required_time"] = float(base_config.get("required_time", 2.0)) * lerpf(1.08, 1.16, minf(1.0, terminal_scale - 1.0))
					base_config["required_radius"] = float(base_config.get("required_radius", 4.2)) * lerpf(0.94, 0.88, minf(1.0, terminal_scale - 1.0))
		var arrival_window_boost := _arrival_hotspot_window_boost(hotspot_id)
		base_config["required_time"] = float(base_config.get("required_time", 2.0)) / maxf(0.001, arrival_window_boost)
		base_config["required_radius"] = float(base_config.get("required_radius", 4.2)) * maxf(0.82, minf(1.18, arrival_window_boost))
	if not base_config.has("stage_hint"):
		base_config["stage_hint"] = str(stage_profile.get("stage_hint", ""))
	return base_config


func _hotspot_focus_radius(hotspot_id: String) -> float:
	var stage_focus_scale := float(_route_stage_signal_profile().get("hotspot_focus_scale", 1.0))
	var distance_scale := REGION_DISTANCE_SCALE
	match current_biome:
		"forest":
			match hotspot_id:
				"shade_grove":
					return 3.2 * stage_focus_scale * distance_scale
				"waterhole":
					return 3.6 * stage_focus_scale * distance_scale
				_:
					return 3.4 * stage_focus_scale * distance_scale
		"wetland":
			match hotspot_id:
				"waterhole":
					return 4.2 * stage_focus_scale * distance_scale
				"migration_corridor":
					return 3.5 * stage_focus_scale * distance_scale
				_:
					return 3.7 * stage_focus_scale * distance_scale
		"coast":
			match hotspot_id:
				"waterhole":
					return 4.1 * stage_focus_scale * distance_scale
				"predator_ridge":
					return 3.4 * stage_focus_scale * distance_scale
				_:
					return 3.8 * stage_focus_scale * distance_scale
		_:
			match hotspot_id:
				"migration_corridor":
					return 4.2 * stage_focus_scale * distance_scale
				"predator_ridge":
					return 3.5 * stage_focus_scale * distance_scale
				_:
					return 3.9 * stage_focus_scale * distance_scale


func _hotspot_reveal_radius(hotspot_id: String) -> float:
	var stage_reveal_scale := float(_route_stage_signal_profile().get("hotspot_reveal_scale", 1.0))
	var distance_scale := REGION_DISTANCE_SCALE
	match current_biome:
		"forest":
			match hotspot_id:
				"shade_grove":
					return 12.0 * stage_reveal_scale * distance_scale
				"waterhole":
					return 13.5 * stage_reveal_scale * distance_scale
				_:
					return 11.0 * stage_reveal_scale * distance_scale
		"wetland":
			match hotspot_id:
				"waterhole":
					return 18.5 * stage_reveal_scale * distance_scale
				"migration_corridor":
					return 13.5 * stage_reveal_scale * distance_scale
				_:
					return 14.5 * stage_reveal_scale * distance_scale
		"coast":
			match hotspot_id:
				"waterhole":
					return 19.0 * stage_reveal_scale * distance_scale
				"carrion_field":
					return 16.0 * stage_reveal_scale * distance_scale
				_:
					return 17.0 * stage_reveal_scale * distance_scale
		_:
			match hotspot_id:
				"migration_corridor":
					return 20.0 * stage_reveal_scale * distance_scale
				"predator_ridge":
					return 16.0 * stage_reveal_scale * distance_scale
				_:
					return 17.5 * stage_reveal_scale * distance_scale


func _exit_reveal_radius() -> float:
	var stage_exit_scale := float(_route_stage_signal_profile().get("exit_reveal_scale", 1.0))
	var distance_scale := REGION_DISTANCE_SCALE
	match current_biome:
		"forest":
			return 18.0 * stage_exit_scale * distance_scale
		"wetland":
			return 20.0 * stage_exit_scale * distance_scale
		"coast":
			return 22.0 * stage_exit_scale * distance_scale
		_:
			return 24.0 * stage_exit_scale * distance_scale


func _biome_exit_profile() -> Dictionary:
	var spread_scale := _world_spread_scale()
	match current_biome:
		"wetland":
			return {
				"reveal_radius": 21.5 * spread_scale,
				"lock_radius": 2.9,
				"gate_duration": 1.28,
				"arrival_duration": 0.86,
				"active_scale": 1.12,
				"beacon_scale": 1.08,
			}
		"forest":
			return {
				"reveal_radius": 15.8 * spread_scale,
				"lock_radius": 2.2,
				"gate_duration": 1.08,
				"arrival_duration": 0.68,
				"active_scale": 1.18,
				"beacon_scale": 0.96,
			}
		"coast":
			return {
				"reveal_radius": 24.6 * spread_scale,
				"lock_radius": 3.0,
				"gate_duration": 1.22,
				"arrival_duration": 0.8,
				"active_scale": 1.08,
				"beacon_scale": 1.18,
			}
		_:
			return {
				"reveal_radius": 25.2 * spread_scale,
				"lock_radius": 2.7,
				"gate_duration": 1.14,
				"arrival_duration": 0.74,
				"active_scale": 1.1,
				"beacon_scale": 1.02,
			}


func _biome_player_motion_profile() -> Dictionary:
	match current_biome:
		"wetland":
			return {
				"base_speed_scale": 0.9,
				"sprint_scale": 0.92,
				"speed_blend": 0.1,
				"movement_blend": 0.12,
				"turn_lerp": 0.15,
				"pose_lerp": 0.2,
				"idle_pose_lerp": 0.16,
				"idle_turn_lerp": 0.12,
				"limb_lerp": 0.2,
				"idle_limb_lerp": 0.16,
				"bob_scale": 1.18,
				"bob_speed_scale": 0.88,
				"stride_scale": 0.92,
				"stride_speed_scale": 0.92,
				"tilt_scale": 0.84,
				"shadow_scale": 0.96,
				"camera_offset_scale": 0.96,
				"camera_look_ahead": 0.28,
				"camera_lift": 0.34,
				"camera_lerp": 0.1,
				"base_fov": 48.0,
				"fov_kick": 1.8,
				"fov_lerp": 0.07,
				"camera_look_height": 1.02,
				"camera_look_pull": 0.14,
			}
		"forest":
			return {
				"base_speed_scale": 0.94,
				"sprint_scale": 0.96,
				"speed_blend": 0.14,
				"movement_blend": 0.16,
				"turn_lerp": 0.22,
				"pose_lerp": 0.26,
				"idle_pose_lerp": 0.2,
				"idle_turn_lerp": 0.16,
				"limb_lerp": 0.24,
				"idle_limb_lerp": 0.2,
				"bob_scale": 0.94,
				"bob_speed_scale": 1.04,
				"stride_scale": 1.02,
				"stride_speed_scale": 1.1,
				"tilt_scale": 1.08,
				"shadow_scale": 1.0,
				"camera_offset_scale": 0.92,
				"camera_look_ahead": 0.24,
				"camera_lift": 0.28,
				"camera_lerp": 0.14,
				"base_fov": 47.2,
				"fov_kick": 1.6,
				"fov_lerp": 0.1,
				"camera_look_height": 1.06,
				"camera_look_pull": 0.12,
			}
		"coast":
			return {
				"base_speed_scale": 1.02,
				"sprint_scale": 1.04,
				"speed_blend": 0.12,
				"movement_blend": 0.14,
				"turn_lerp": 0.17,
				"pose_lerp": 0.22,
				"idle_pose_lerp": 0.18,
				"idle_turn_lerp": 0.13,
				"limb_lerp": 0.22,
				"idle_limb_lerp": 0.18,
				"bob_scale": 0.86,
				"bob_speed_scale": 1.0,
				"stride_scale": 0.94,
				"stride_speed_scale": 0.98,
				"tilt_scale": 0.74,
				"shadow_scale": 0.92,
				"camera_offset_scale": 1.02,
				"camera_look_ahead": 0.4,
				"camera_lift": 0.38,
				"camera_lerp": 0.1,
				"base_fov": 50.0,
				"fov_kick": 2.6,
				"fov_lerp": 0.08,
				"camera_look_height": 0.98,
				"camera_look_pull": 0.22,
			}
		_:
			return {
				"base_speed_scale": 1.06,
				"sprint_scale": 1.08,
				"speed_blend": 0.12,
				"movement_blend": 0.15,
				"turn_lerp": 0.18,
				"pose_lerp": 0.24,
				"idle_pose_lerp": 0.18,
				"idle_turn_lerp": 0.14,
				"limb_lerp": 0.22,
				"idle_limb_lerp": 0.18,
				"bob_scale": 1.04,
				"bob_speed_scale": 1.06,
				"stride_scale": 1.08,
				"stride_speed_scale": 1.08,
				"tilt_scale": 0.92,
				"shadow_scale": 1.04,
				"camera_offset_scale": 1.04,
				"camera_look_ahead": 0.38,
				"camera_lift": 0.48,
				"camera_lerp": 0.11,
				"base_fov": 49.6,
				"fov_kick": 2.8,
				"fov_lerp": 0.08,
				"camera_look_height": 1.0,
				"camera_look_pull": 0.2,
			}


func _animal_visible_radius(animal: Dictionary) -> float:
	var category := str(animal.get("category", "区域生物"))
	var role := str(animal.get("role", "member"))
	var base := 16.0
	match current_biome:
		"forest":
			match category:
				"掠食者":
					base = 15.0
				"飞行动物":
					base = 18.0
				"水域动物":
					base = 12.5
				_:
					base = 13.5
		"wetland":
			match category:
				"掠食者":
					base = 16.0
				"飞行动物":
					base = 20.0
				"水域动物":
					base = 17.5
				_:
					base = 14.5
		"coast":
			match category:
				"掠食者":
					base = 17.0
				"飞行动物":
					base = 23.0
				"水域动物":
					base = 16.0
				_:
					base = 16.5
		_:
			match category:
				"掠食者":
					base = 20.0
				"飞行动物":
					base = 25.0
				"水域动物":
					base = 14.0
				_:
					base = 18.0
	if role in ["leader", "sentry", "alpha"]:
		base += 3.0
	return base * REGION_SCALE * 1.12


func _terminal_chain_event_hint() -> String:
	if current_route_stage != "terminal" and not (arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"]):
		return ""
	var terminal_reason := _recommended_terminal_reason()
	match _stage_shell_focus_band("terminal"):
		"pressure":
			return " 当前终端更偏压力链。%s" % terminal_reason
		"aftermath":
			return " 当前终端更偏余波链。%s" % terminal_reason
		"exit":
			return " 当前终端更偏离场链。%s" % terminal_reason
		_:
			return ""


func _biome_transition_event(label: String, progress: float) -> Dictionary:
	var pct := int(round(progress * 100.0))
	match current_biome:
		"wetland":
			return {"title": "栈道切换", "body": "正沿湿地入口前往 %s · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}
		"forest":
			return {"title": "林道切换", "body": "正穿过树门前往 %s · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}
		"coast":
			return {"title": "岸线切换", "body": "正沿岸线入口前往 %s · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}
		_:
			return {"title": "路线切换", "body": "正沿草原主道前往 %s · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}


func _biome_arrival_event(label: String, progress: float) -> Dictionary:
	var pct := int(round(progress * 100.0))
	match current_biome:
		"wetland":
			return {"title": "进入湿地区域", "body": "已抵达 %s 栈桥入口，正并入主栈道 · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}
		"forest":
			return {"title": "进入森林区域", "body": "已抵达 %s 林门入口，正并入林道 · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}
		"coast":
			return {"title": "进入海岸区域", "body": "已抵达 %s 岸线入口，正并入沿岸路 · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}
		_:
			return {"title": "进入草原区域", "body": "已抵达 %s 主道入口，正并入迁徙主路 · %d%% · %s" % [label, pct, _route_stage_reentry_prompt()]}


func _biome_exit_event(hint: String) -> Dictionary:
	var suffix := _terminal_chain_event_hint()
	match current_biome:
		"wetland":
			return {"title": "湿地出口已锁定", "body": "%s · %s%s" % [hint, _route_stage_exit_prompt(), suffix]}
		"forest":
			return {"title": "林道出口已锁定", "body": "%s · %s%s" % [hint, _route_stage_exit_prompt(), suffix]}
		"coast":
			return {"title": "岸线出口已锁定", "body": "%s · %s%s" % [hint, _route_stage_exit_prompt(), suffix]}
		_:
			return {"title": "草原出口已锁定", "body": "%s · %s%s" % [hint, _route_stage_exit_prompt(), suffix]}


func _biome_hotspot_event(label: String, summary: String) -> Dictionary:
	var suffix := _terminal_chain_event_hint()
	match current_biome:
		"wetland":
			return {"title": "湿地观察", "body": "%s · %s%s" % [label, summary, suffix]}
		"forest":
			return {"title": "林下观察", "body": "%s · %s%s" % [label, summary, suffix]}
		"coast":
			return {"title": "岸线观察", "body": "%s · %s%s" % [label, summary, suffix]}
		_:
			return {"title": "开阔观察", "body": "%s · %s%s" % [label, summary, suffix]}


func _biome_encounter_event(label: String, category: String) -> Dictionary:
	var suffix := _terminal_chain_event_hint()
	match current_biome:
		"wetland":
			return {"title": "湿地偶遇", "body": "%s · %s%s" % [label, category, suffix]}
		"forest":
			return {"title": "林间偶遇", "body": "%s · %s%s" % [label, category, suffix]}
		"coast":
			return {"title": "岸线偶遇", "body": "%s · %s%s" % [label, category, suffix]}
		_:
			return {"title": "草原偶遇", "body": "%s · %s%s" % [label, category, suffix]}


func _biome_chase_burst_text(predator_label: String) -> Dictionary:
	var suffix := _terminal_chain_event_hint()
	match current_biome:
		"wetland":
			return {"title": "湿地追猎爆发", "body": "%s 已沿湿地边缘短时冲刺，群落正在快速散开。%s" % [predator_label, suffix]}
		"forest":
			return {"title": "林缘追猎爆发", "body": "%s 已从林缘压出，草食群正在穿林躲避。%s" % [predator_label, suffix]}
		"coast":
			return {"title": "岸线追猎爆发", "body": "%s 已沿岸线突进，群落正在向岸带外扩。%s" % [predator_label, suffix]}
		_:
			return {"title": "草原追猎爆发", "body": "%s 已进入短时冲刺，草食群正在快速逃散。%s" % [predator_label, suffix]}


func _biome_chase_hit_text(predator_label: String) -> Dictionary:
	var suffix := _terminal_chain_event_hint()
	match current_biome:
		"wetland":
			return {"title": "湿地追猎命中", "body": "%s 成功切入湿地群落，近水压力正在上升。%s" % [predator_label, suffix]}
		"forest":
			return {"title": "林缘追猎命中", "body": "%s 在林缘完成压迫，林道压力正在上升。%s" % [predator_label, suffix]}
		"coast":
			return {"title": "岸线追猎命中", "body": "%s 沿岸完成切入，岸带压力正在上升。%s" % [predator_label, suffix]}
		_:
			return {"title": "草原追猎命中", "body": "%s 成功切入草食群，区域压力正在上升。%s" % [predator_label, suffix]}


func _biome_chase_miss_text(predator_label: String) -> Dictionary:
	var suffix := _terminal_chain_event_hint()
	match current_biome:
		"wetland":
			return {"title": "湿地追猎落空", "body": "%s 的冲刺结束，群落已沿栈桥与浅滩脱离压迫。%s" % [predator_label, suffix]}
		"forest":
			return {"title": "林缘追猎落空", "body": "%s 的冲刺结束，草食群已借林道脱离压迫。%s" % [predator_label, suffix]}
		"coast":
			return {"title": "岸线追猎落空", "body": "%s 的冲刺结束，群落已沿岸线拉开距离。%s" % [predator_label, suffix]}
		_:
			return {"title": "草原追猎落空", "body": "%s 的冲刺结束，草食群成功脱离压迫区。%s" % [predator_label, suffix]}


func _biome_aftermath_text(hit: bool) -> Dictionary:
	var suffix := _terminal_chain_event_hint()
	match current_biome:
		"wetland":
			return {
				"title": "湿地余波",
				"body": (("群落正沿浅滩和栈桥重组，飞行动物与掠食者正朝事件点联动。" if hit else "群落正沿浅滩重新结列，飞行动物开始在湿地上空盘旋。") + suffix),
			}
		"forest":
			return {
				"title": "林缘余波",
				"body": (("群落正穿林重组，飞行动物与掠食者正朝林缘事件点联动。" if hit else "群落正沿林道重排，飞行动物开始在林空聚集。") + suffix),
			}
		"coast":
			return {
				"title": "岸线余波",
				"body": (("群落正沿岸线重组，飞行动物与掠食者正朝岸侧事件点联动。" if hit else "群落正重新拉开岸线队形，飞行动物开始沿岸盘旋。") + suffix),
			}
		_:
			return {
				"title": "草原余波",
				"body": (("草食群正在重组，飞行动物与掠食群正朝事件点联动。" if hit else "草食群正在重新结列，飞行动物开始朝事件点盘旋。") + suffix),
			}


func _arrival_pressure_prompt() -> String:
	var terminal_hint := _recommended_terminal_reason()
	var terminal_scale_hint := _recommended_terminal_scale_text()
	match _recommended_route_focus_kind():
		"chokepoint", "route_landmark":
			match current_biome:
				"wetland":
					return "落地压力导引 · 当前先盯近水压迫和湿地余波，再决定离场。%s %s" % [terminal_scale_hint, terminal_hint]
				"forest":
					return "落地压力导引 · 当前先盯林缘压迫和终端余波，再决定离场。%s %s" % [terminal_scale_hint, terminal_hint]
				"coast":
					return "落地压力导引 · 当前先盯岸线压迫和沿岸余波，再决定离场。%s %s" % [terminal_scale_hint, terminal_hint]
				_:
					return "落地压力导引 · 当前先盯终端压迫和结果链，再决定离场。%s %s" % [terminal_scale_hint, terminal_hint]
		"branch_route":
			return "落地压力导引 · 当前先把观察链立稳，再看是否转压迫。"
		"entry_route", "trunk_route":
			return "落地压力导引 · 当前先稳入口和主路，再决定是否接压力链。"
		_:
			return "落地压力导引 · 当前先按推荐链判断压力是否成立。"


func _route_stage_log_entry(kind: String, subject: String) -> String:
	var arrival_terminal := arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"]
	match kind:
		"species":
			if arrival_terminal and current_route_stage == "terminal":
				return "终端压力段目击：%s" % subject
			match current_route_stage:
				"entry":
					return "入口发现：%s" % subject
				"branch":
					return "支路记录：%s" % subject
				"terminal":
					return "终端目击：%s" % subject
				_:
					return "主路发现：%s" % subject
		"hotspot":
			if arrival_terminal and current_route_stage == "terminal":
				return "终端压力段热点：%s" % subject
			match current_route_stage:
				"entry":
					return "入口标记：%s" % subject
				"branch":
					return "支路热点：%s" % subject
				"terminal":
					return "终端热点：%s" % subject
				_:
					return "主路热点：%s" % subject
		"task_complete":
			if arrival_terminal and current_route_stage == "terminal":
				return "终端压力段完成：%s" % subject
			match current_route_stage:
				"entry":
					return "入口完成：%s" % subject
				"branch":
					return "支路完成：%s" % subject
				"terminal":
					return "终端完成：%s" % subject
				_:
					return "主路完成：%s" % subject
		"chase_hit":
			if arrival_terminal and current_route_stage == "terminal":
				return "终端压力段命中：%s" % subject
			match current_route_stage:
				"entry":
					return "入口压迫命中：%s" % subject
				"branch":
					return "支路追猎命中：%s" % subject
				"terminal":
					return "终端追猎命中：%s" % subject
				_:
					return "主路追猎命中：%s" % subject
		"chase_miss":
			if arrival_terminal and current_route_stage == "terminal":
				return "终端压力段落空：%s" % subject
			match current_route_stage:
				"entry":
					return "入口压迫落空：%s" % subject
				"branch":
					return "支路追猎落空：%s" % subject
				"terminal":
					return "终端追猎落空：%s" % subject
				_:
					return "主路追猎落空：%s" % subject
		_:
			return subject


func _route_stage_event_priority(kind: String) -> int:
	match current_route_stage:
		"entry":
			match kind:
				"exit":
					return 100
				"task":
					return 78
				"hotspot":
					return 72
				"encounter":
					return 66
				"interaction":
					return 62
				"chase":
					return 58
				"aftermath":
					return 84
				"chase_result":
					return 88
				_:
					return 40
		"branch":
			match kind:
				"task":
					return 100
				"hotspot":
					return 94
				"encounter":
					return 88
				"interaction":
					return 82
				"chase":
					return 78
				"aftermath":
					return 84
				"chase_result":
					return 90
				"exit":
					return 64
				_:
					return 40
		"terminal":
			match kind:
				"chase_result":
					return 100
				"aftermath":
					return 96
				"chase":
					return 90
				"interaction":
					return 80
				"exit":
					return 78
				"task":
					return 74
				"hotspot":
					return 68
				"encounter":
					return 62
				_:
					return 40
		_:
			match kind:
				"interaction":
					return 86
				"task":
					return 82
				"hotspot":
					return 78
				"encounter":
					return 74
				"exit":
					return 72
				"chase":
					return 76
				"aftermath":
					return 84
				"chase_result":
					return 88
				_:
					return 40


func _route_stage_interaction_focus(kind: String) -> float:
	match current_route_stage:
		"entry":
			match kind:
				"exit":
					return 1.24
				"hotspot":
					return 0.92
				"encounter":
					return 0.94
				"pressure":
					return 0.96
				"aftermath":
					return 1.02
				_:
					return 1.0
		"branch":
			match kind:
				"exit":
					return 0.9
				"hotspot":
					return 1.24
				"encounter":
					return 1.12
				"pressure":
					return 1.04
				"aftermath":
					return 1.0
				_:
					return 1.0
		"terminal":
			match kind:
				"exit":
					return 1.12
				"hotspot":
					return 0.94
				"encounter":
					return 0.98
				"pressure":
					return 1.16
				"aftermath":
					return 1.24
				_:
					return 1.0
		_:
			match kind:
				"exit":
					return 0.98
				"hotspot":
					return 1.04
				"encounter":
					return 1.02
				"pressure":
					return 1.04
				"aftermath":
					return 1.06
				_:
					return 1.0


func _route_stage_species_score(entry: Dictionary) -> int:
	var category := str(entry.get("category", ""))
	var score := int(entry.get("count", 0))
	match current_route_stage:
		"entry":
			if current_biome == "wetland" and category == "水域动物":
				score += 36
			elif current_biome == "coast" and category == "飞行动物":
				score += 32
			elif category == "草食动物":
				score += 24
			elif category == "掠食者":
				score += 10
		"branch":
			var focus_category := ""
			if not current_hotspot.is_empty():
				focus_category = str(_hotspot_task_config(str(current_hotspot.get("hotspot_id", ""))).get("required_category", ""))
			elif str(current_task.get("title", "")) != "":
				focus_category = str(_hotspot_task_config(str(current_hotspot.get("hotspot_id", ""))).get("required_category", ""))
			if focus_category != "" and category == focus_category:
				score += 48
			elif category == "草食动物" or category == "水域动物":
				score += 18
		"terminal":
			if category == "掠食者":
				score += 44
			elif category == "飞行动物":
				score += 38
			elif category == "草食动物":
				score += 14
		_:
			if category == "草食动物":
				score += 26
			elif category == "掠食者":
				score += 18
			elif category == "飞行动物":
				score += 12
	return score


func _route_stage_focus_category() -> String:
	if not current_hotspot.is_empty():
		return str(_hotspot_task_config(str(current_hotspot.get("hotspot_id", ""))).get("required_category", ""))
	match current_route_stage:
		"entry":
			match current_biome:
				"wetland":
					return "水域动物"
				"forest":
					return "草食动物"
				"coast":
					return "飞行动物"
				_:
					return "草食动物"
		"branch":
			match current_biome:
				"wetland":
					return "水域动物"
				"forest":
					return "草食动物"
				"coast":
					return "飞行动物"
				_:
					return "草食动物"
		"terminal":
			match current_biome:
				"wetland":
					return "飞行动物"
				"forest":
					return "掠食者"
				"coast":
					return "飞行动物"
				_:
					return "掠食者"
		_:
			match current_biome:
				"wetland":
					return "水域动物"
				"forest":
					return "草食动物"
				"coast":
					return "飞行动物"
				_:
					return "草食动物"


func _route_stage_animal_profile(animal: Dictionary) -> Dictionary:
	var category := str(animal.get("category", "区域生物"))
	var role := str(animal.get("role", "member"))
	var focus_category := _route_stage_focus_category()
	var arrival_focus_kind := _recommended_route_focus_kind()
	var arrival_focus_scale := _recommended_route_focus_scale()
	var arrival_blend := minf(1.0, maxf(0.0, arrival_focus_scale - 0.96) / 0.22)
	var reveal_scale := 1.0
	var prominence_scale := 1.0
	var signal_scale := 1.0
	match current_route_stage:
		"entry":
			if category == focus_category:
				reveal_scale = 1.18
				prominence_scale = 1.06
			elif role in ["leader", "sentry", "alpha"]:
				reveal_scale = 1.08
				prominence_scale = 1.04
			else:
				reveal_scale = 0.94
				prominence_scale = 0.98
		"branch":
			if category == focus_category:
				reveal_scale = 1.24
				prominence_scale = 1.08
				signal_scale = 1.08
			elif role in ["leader", "sentry", "alpha"]:
				reveal_scale = 1.12
				prominence_scale = 1.05
			else:
				reveal_scale = 0.96
				prominence_scale = 1.0
		"terminal":
			if category in ["掠食者", "飞行动物"]:
				reveal_scale = 1.22
				prominence_scale = 1.1
				signal_scale = 1.12
			elif category == focus_category:
				reveal_scale = 1.16
				prominence_scale = 1.06
			else:
				reveal_scale = 0.92
				prominence_scale = 0.98
		_:
			if category == focus_category:
				reveal_scale = 1.12
				prominence_scale = 1.04
			elif role in ["leader", "sentry", "alpha"]:
				reveal_scale = 1.08
				prominence_scale = 1.03
	if arrival_event_focus_timer > 0.0:
		match arrival_focus_kind:
			"branch_route":
				if category == focus_category:
					reveal_scale *= lerpf(1.0, 1.12, arrival_blend)
					prominence_scale *= lerpf(1.0, 1.08, arrival_blend)
					signal_scale *= lerpf(1.0, 1.06, arrival_blend)
			"chokepoint", "route_landmark":
				if category in ["掠食者", "飞行动物"]:
					reveal_scale *= lerpf(1.0, 1.16, arrival_blend)
					prominence_scale *= lerpf(1.0, 1.12, arrival_blend)
					signal_scale *= lerpf(1.0, 1.14, arrival_blend)
				elif category == focus_category:
					reveal_scale *= lerpf(1.0, 1.08, arrival_blend)
					prominence_scale *= lerpf(1.0, 1.06, arrival_blend)
			"entry_route", "trunk_route":
				if category in ["掠食者", "飞行动物"]:
					reveal_scale *= lerpf(1.0, 0.92, arrival_blend)
					prominence_scale *= lerpf(1.0, 0.96, arrival_blend)
	var terminal_chain_profile := _terminal_chain_animal_boost(category)
	reveal_scale *= float(terminal_chain_profile.get("reveal_scale", 1.0))
	prominence_scale *= float(terminal_chain_profile.get("prominence_scale", 1.0))
	signal_scale *= float(terminal_chain_profile.get("signal_scale", 1.0))
	return {
		"reveal_scale": reveal_scale,
		"prominence_scale": prominence_scale,
		"signal_scale": signal_scale,
	}


func _stage_sorted_species_manifest(limit: int) -> Array:
	var sorted: Array = []
	var capped := species_manifest.slice(0, min(species_manifest.size(), max(limit, 0)))
	for entry in capped:
		var inserted := false
		var score := _route_stage_species_score(entry) + _progress_stage_species_boost(entry) + _entry_screen_species_boost(entry)
		for i in range(sorted.size()):
			if score > _route_stage_species_score(sorted[i]) + _progress_stage_species_boost(sorted[i]) + _entry_screen_species_boost(sorted[i]):
				sorted.insert(i, entry)
				inserted = true
				break
		if not inserted:
			sorted.append(entry)
	return sorted


func _arrival_sorted_species_manifest(limit: int) -> Array:
	var sorted := _stage_sorted_species_manifest(limit)
	if arrival_event_focus_timer <= 0.0:
		return sorted
	var focus_kind := _recommended_route_focus_kind()
	var arrival_scale := _recommended_route_focus_scale()
	var terminal_scale := _recommended_terminal_scale()
	var blended_limit := minf(1.0, maxf(0.0, arrival_scale - 0.96) / 0.22)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score := _route_stage_species_score(a) + _progress_stage_species_boost(a) + _entry_screen_species_boost(a)
		var b_score := _route_stage_species_score(b) + _progress_stage_species_boost(b) + _entry_screen_species_boost(b)
		var a_category := str(a.get("category", ""))
		var b_category := str(b.get("category", ""))
		match focus_kind:
			"branch_route":
				if a_category == _route_stage_focus_category():
					a_score += int(18.0 * blended_limit)
				if b_category == _route_stage_focus_category():
					b_score += int(18.0 * blended_limit)
			"chokepoint", "route_landmark":
				var terminal_bonus := blended_limit * terminal_scale
				if a_category in ["掠食者", "飞行动物"]:
					a_score += int(22.0 * terminal_bonus)
				if b_category in ["掠食者", "飞行动物"]:
					b_score += int(22.0 * terminal_bonus)
			"entry_route", "trunk_route":
				if a_category in ["掠食者", "飞行动物"]:
					a_score -= int(10.0 * blended_limit)
				if b_category in ["掠食者", "飞行动物"]:
					b_score -= int(10.0 * blended_limit)
		return a_score > b_score
	)
	return sorted


func _current_progress_stage() -> int:
	var stage := 1
	if discovered_species_ids.size() >= 3 and completed_task_ids.size() >= 1:
		stage = 2
	if witnessed_pressure and completed_task_ids.size() >= 2:
		stage = 3
	var completion_state := _dynamic_completion_state()
	var readiness_band := str(completion_state.get("readiness_band", "observe"))
	if readiness_band == "prepare":
		stage = max(stage, 2)
	elif readiness_band == "transition":
		stage = max(stage, 3)
	stage = max(stage, int(_dynamic_exit_state().get("force_progress_stage", 1)))
	return stage


func _progress_stage_signal_profile() -> Dictionary:
	var profile := {}
	match _current_progress_stage():
		1:
			profile = {
				"hotspot_scale": 0.98,
				"exit_scale": 0.92,
				"animal_scale": 1.08,
				"pressure_scale": 0.9,
				"aftermath_scale": 0.88,
			}
		2:
			profile = {
				"hotspot_scale": 1.08,
				"exit_scale": 0.96,
				"animal_scale": 1.0,
				"pressure_scale": 1.08,
				"aftermath_scale": 0.98,
			}
		_:
			profile = {
				"hotspot_scale": 0.96,
				"exit_scale": 1.12,
				"animal_scale": 1.02,
				"pressure_scale": 1.12,
				"aftermath_scale": 1.16,
			}
	if current_route_stage == "terminal" or _recommended_route_focus_kind() in ["chokepoint", "route_landmark"]:
		match _stage_shell_focus_band("terminal"):
			"pressure":
				profile["pressure_scale"] = _terminal_scale_adjust(float(profile.get("pressure_scale", 1.0)))
			"aftermath":
				profile["aftermath_scale"] = _terminal_scale_adjust(float(profile.get("aftermath_scale", 1.0)))
			"exit":
				profile["exit_scale"] = _terminal_scale_adjust(float(profile.get("exit_scale", 1.0)))
	return profile


func _progress_stage_interaction_focus(kind: String) -> float:
	var completion_focus := _progress_stage_completion_focus(kind)
	match _current_progress_stage():
		1:
			match kind:
				"hotspot":
					return 1.12 * completion_focus
				"encounter":
					return 1.14 * completion_focus
				"exit":
					return 0.92 * completion_focus
				"pressure":
					return 0.9 * completion_focus
				"aftermath":
					return 0.88 * completion_focus
				_:
					return completion_focus
		2:
			match kind:
				"hotspot":
					return 1.08 * completion_focus
				"encounter":
					return 1.04 * completion_focus
				"exit":
					return 0.96 * completion_focus
				"pressure":
					return 1.12 * completion_focus
				"aftermath":
					return 1.02 * completion_focus
				_:
					return completion_focus
		_:
			match kind:
				"hotspot":
					return 0.94 * completion_focus
				"encounter":
					return 0.98 * completion_focus
				"exit":
					return 1.1 * completion_focus
				"pressure":
					return 1.08 * completion_focus
				"aftermath":
					return 1.18 * completion_focus
				_:
					return completion_focus


func _progress_stage_transition_profile() -> Dictionary:
	match _current_progress_stage():
		1:
			return {"alpha_scale": 0.94, "zoom_scale": 0.9}
		2:
			return {"alpha_scale": 1.02, "zoom_scale": 1.04}
		_:
			return {"alpha_scale": 1.12, "zoom_scale": 1.14}


func _progress_stage_transition_prefix() -> String:
	match _current_progress_stage():
		1:
			return "发现链"
		2:
			return "压力链"
		_:
			return "结果链"


func _objective_check_states() -> Array:
	var stage_done_one := discovered_species_ids.size() >= 3
	var stage_done_two := completed_task_ids.size() >= 1
	var stage_two_done_one := witnessed_pressure
	var stage_two_done_two := completed_task_ids.size() >= 2
	var stage_three_done_one := visited_region_ids.size() >= 2
	var stage_three_done_two := witnessed_chase_result
	return [stage_done_one, stage_done_two, stage_two_done_one, stage_two_done_two, stage_three_done_one, stage_three_done_two]


func _is_progress_stage_complete(stage: int = -1) -> bool:
	var resolved_stage := _current_progress_stage() if stage < 0 else stage
	var checks := _objective_check_states()
	match resolved_stage:
		1:
			return bool(checks[0]) and bool(checks[1])
		2:
			return bool(checks[2]) and bool(checks[3])
		_:
			return bool(checks[4]) and bool(checks[5])


func _progress_stage_completion_focus(kind: String) -> float:
	if not _is_progress_stage_complete():
		return 1.0
	match _current_progress_stage():
		1:
			match kind:
				"hotspot":
					return 0.88
				"encounter":
					return 0.9
				"pressure":
					return 1.18
				"aftermath":
					return 1.04
				"exit":
					return 1.06
				_:
					return 1.0
		2:
			match kind:
				"hotspot":
					return 0.9
				"encounter":
					return 0.92
				"pressure":
					return 0.96
				"aftermath":
					return 1.2
				"exit":
					return 1.14
				_:
					return 1.0
		_:
			match kind:
				"hotspot":
					return 0.86
				"encounter":
					return 0.9
				"pressure":
					return 0.98
				"aftermath":
					return 1.08
				"exit":
					return 1.24
				_:
					return 1.0


func _progress_stage_completion_prompt() -> String:
	var gate_completion := _gate_focus_completion_text(false)
	if gate_completion != "":
		return gate_completion
	var completion_state := _dynamic_completion_state()
	var exit_state := _dynamic_exit_state()
	var gate_band := str(exit_state.get("recommended_gate_band", "observe"))
	var gate_reason := _recommended_exit_gate_reason()
	var terminal_focus := _recommended_route_focus_kind() in ["chokepoint", "route_landmark"]
	var terminal_suffix := ""
	if terminal_focus:
		terminal_suffix = " %s %s %s" % [_recommended_terminal_scale_text(), _recommended_terminal_action_text(), _recommended_terminal_reason()]
	if not _is_progress_stage_complete():
		return "当前阶段未完成，继续按本阶段链路推进。%s %s%s" % [str(completion_state.get("summary", "")), gate_reason, terminal_suffix]
	match _current_progress_stage():
		1:
			return "当前阶段已完成，开始把场景重心转向压力链。%s %s%s" % [str(completion_state.get("summary", "")), gate_reason, terminal_suffix]
		2:
			return "当前阶段已完成，开始把场景重心转向结果链。%s %s%s" % [str(completion_state.get("summary", "")), gate_reason, terminal_suffix]
		_:
			if gate_band == "commit":
				return "当前阶段已完成，开始把场景重心转向出口和切区。%s %s%s" % [str(completion_state.get("summary", "")), gate_reason, terminal_suffix]
			return "当前阶段已完成，开始把场景重心转向出口准备。%s %s%s" % [str(completion_state.get("summary", "")), gate_reason, terminal_suffix]


func _arrival_progress_prompt() -> String:
	var terminal_band := _stage_shell_focus_band("terminal")
	var terminal_signal := _terminal_signal_text()
	var gate_progress := _gate_focus_progress_text(true)
	var entry_progress := _entry_screen_progress_text(true)
	if entry_progress != "":
		return entry_progress
	if gate_progress != "":
		return gate_progress
	match _recommended_route_focus_kind():
		"entry_route":
			return "落地进度 · 先补入口发现链，再决定是否立压力。"
		"trunk_route":
			return "落地进度 · 先稳住主路推进链，再扩到观察和压力。"
		"branch_route":
			return "落地进度 · 先补支路观察链，再根据结果转入压力或终端。"
		"chokepoint", "route_landmark":
			match terminal_band:
				"pressure":
					return "落地进度 · 先把压力终端链顶起来，再决定是否转结果或离场。%s" % terminal_signal
				"aftermath":
					return "落地进度 · 先把余波终端链顶起来，再决定是否直接离场。%s" % terminal_signal
				"exit":
					return "落地进度 · 先把离场终端链立稳，再决定是否直接切区。%s" % terminal_signal
				_:
					return "落地进度 · 先把终端压力和结果链顶起来，再决定是否直接离场。%s" % terminal_signal
		_:
			return "落地进度 · 先沿推荐链补当前最缺的推进环节。"


func _arrival_completion_prompt() -> String:
	var gate_completion := _gate_focus_completion_text(true)
	if gate_completion != "":
		return gate_completion
	var completion_state := _dynamic_completion_state()
	var gate_reason := _recommended_exit_gate_reason()
	var terminal_band := _stage_shell_focus_band("terminal")
	var terminal_signal := _terminal_signal_text()
	match _recommended_route_focus_kind():
		"entry_route":
			return "落地完成导引 · 先把入口链补稳，再转向压力或出口判断。%s %s" % [str(completion_state.get("summary", "")), gate_reason]
		"trunk_route":
			return "落地完成导引 · 先把主路推进链补齐，再决定分到观察还是终端。%s %s" % [str(completion_state.get("summary", "")), gate_reason]
		"branch_route":
			return "落地完成导引 · 先把支路观察链补满，再看是否转压迫或回主线。%s %s" % [str(completion_state.get("summary", "")), gate_reason]
		"chokepoint", "route_landmark":
			match terminal_band:
				"pressure":
					return "落地完成导引 · 当前更接近压力终端，优先确认压迫结果链和离场门。%s %s %s" % [str(completion_state.get("summary", "")), gate_reason, terminal_signal]
				"aftermath":
					return "落地完成导引 · 当前更接近余波终端，优先确认余波结果链和离场门。%s %s %s" % [str(completion_state.get("summary", "")), gate_reason, terminal_signal]
				"exit":
					return "落地完成导引 · 当前更接近离场终端，优先确认离场门和切区条件。%s %s %s" % [str(completion_state.get("summary", "")), gate_reason, terminal_signal]
				_:
					return "落地完成导引 · 当前更接近终端收束，优先确认压力结果链和离场门。%s %s %s" % [str(completion_state.get("summary", "")), gate_reason, terminal_signal]
		_:
			return "落地完成导引 · 先沿推荐链补齐当前推进条件。%s %s" % [str(completion_state.get("summary", "")), gate_reason]


func _progress_stage_route_boost(kind: String) -> float:
	match _current_progress_stage():
		1:
			match kind:
				"entry_route", "entry_marker":
					return 1.18
				"trunk_route", "trunk_marker":
					return 1.08
				"connector":
					return 1.04
				"branch_route", "branch_marker":
					return 0.94
				"chokepoint", "route_landmark":
					return 0.92
				_:
					return 1.0
		2:
			match kind:
				"trunk_route", "trunk_marker":
					return 1.1
				"branch_route", "branch_marker":
					return 1.14
				"connector":
					return 1.12
				"chokepoint":
					return 1.02
				"entry_route", "entry_marker":
					return 0.92
				_:
					return 1.0
		_:
			match kind:
				"chokepoint", "route_landmark":
					return 1.2
				"branch_route", "branch_marker":
					return 1.04
				"trunk_marker":
					return 1.08
				"trunk_route", "connector":
					return 0.96
				"entry_route", "entry_marker":
					return 0.88
				_:
					return 1.0


func _progress_stage_event_boost(kind: String) -> int:
	match _current_progress_stage():
		1:
			match kind:
				"encounter":
					return 16
				"hotspot":
					return 12
				"task":
					return 10
				"exit":
					return -8
				"chase", "chase_result", "aftermath":
					return -10
				_:
					return 0
		2:
			match kind:
				"chase":
					return 18
				"task":
					return 14
				"hotspot":
					return 10
				"encounter":
					return 8
				"chase_result", "aftermath":
					return 6
				"exit":
					return -4
				_:
					return 0
		_:
			match kind:
				"chase_result":
					return 18
				"aftermath":
					return 16
				"exit":
					return 12
				"chase":
					return 10
				"task":
					return 4
				"hotspot":
					return -4
				"encounter":
					return -2
				_:
					return 0


func _progress_stage_species_boost(entry: Dictionary) -> int:
	var category := str(entry.get("category", ""))
	match _current_progress_stage():
		1:
			if category in ["草食动物", "水域动物", "飞行动物"]:
				return 18
			if category == "掠食者":
				return -8
			return 0
		2:
			if category == "掠食者":
				return 20
			if category == "草食动物":
				return 12
			if category == "飞行动物":
				return 8
			return 0
		_:
			if category == "掠食者":
				return 18
			if category == "飞行动物":
				return 16
			if category == "草食动物":
				return 6
			return 0


func _objective_rows() -> Array:
	var stage := _current_progress_stage()
	var terminal_active := current_route_stage == "terminal" or _recommended_route_focus_kind() in ["chokepoint", "route_landmark"]
	var terminal_band := _stage_shell_focus_band("terminal")
	var entry_hotspot_id := _entry_screen_primary_hotspot_id()
	var entry_hotspot_label := ""
	if entry_hotspot_id != "":
		entry_hotspot_label = str(_hotspot_task_config(entry_hotspot_id).get("label", entry_hotspot_id))
	match current_biome:
		"wetland":
			if stage == 1:
				if entry_hotspot_label != "":
					return ["阶段一 · 先读清 %s" % entry_hotspot_label, "阶段一 · 在湿地发现 3 种动物"]
				return ["阶段一 · 在湿地发现 3 种动物", "阶段一 · 完成 1 个近水观察任务"]
			if stage == 2:
				return ["阶段二 · 见证一次湿地追逐压力", "阶段二 · 完成 2 个不同湿地热点任务"]
			if terminal_active:
				if terminal_band == "pressure":
					return ["阶段三 · 见证一次湿地追逐压力", "阶段三 · 进入下一个湿地区域"]
				if terminal_band == "aftermath":
					return ["阶段三 · 见证一次湿地追猎命中或落空", "阶段三 · 进入下一个湿地区域"]
				if terminal_band == "exit":
					return ["阶段三 · 进入下一个湿地区域", "阶段三 · 见证一次湿地追猎命中或落空"]
			return ["阶段三 · 进入下一个湿地区域", "阶段三 · 见证一次湿地追猎命中或落空"]
		"forest":
			if stage == 1:
				if entry_hotspot_label != "":
					return ["阶段一 · 先读清 %s" % entry_hotspot_label, "阶段一 · 在林下发现 3 种动物"]
				return ["阶段一 · 在林下发现 3 种动物", "阶段一 · 完成 1 个林下观察任务"]
			if stage == 2:
				return ["阶段二 · 见证一次林缘追逐压力", "阶段二 · 完成 2 个不同林道热点任务"]
			if terminal_active:
				if terminal_band == "pressure":
					return ["阶段三 · 见证一次林缘追逐压力", "阶段三 · 进入下一个森林区域"]
				if terminal_band == "aftermath":
					return ["阶段三 · 见证一次林缘追猎命中或落空", "阶段三 · 进入下一个森林区域"]
				if terminal_band == "exit":
					return ["阶段三 · 进入下一个森林区域", "阶段三 · 见证一次林缘追猎命中或落空"]
			return ["阶段三 · 进入下一个森林区域", "阶段三 · 见证一次林缘追猎命中或落空"]
		"coast":
			if stage == 1:
				if entry_hotspot_label != "":
					return ["阶段一 · 先读清 %s" % entry_hotspot_label, "阶段一 · 在岸线发现 3 种动物"]
				return ["阶段一 · 在岸线发现 3 种动物", "阶段一 · 完成 1 个岸线观察任务"]
			if stage == 2:
				return ["阶段二 · 见证一次岸线追逐压力", "阶段二 · 完成 2 个不同岸线热点任务"]
			if terminal_active:
				if terminal_band == "pressure":
					return ["阶段三 · 见证一次岸线追逐压力", "阶段三 · 进入下一个海岸区域"]
				if terminal_band == "aftermath":
					return ["阶段三 · 见证一次岸线追猎命中或落空", "阶段三 · 进入下一个海岸区域"]
				if terminal_band == "exit":
					return ["阶段三 · 进入下一个海岸区域", "阶段三 · 见证一次岸线追猎命中或落空"]
			return ["阶段三 · 进入下一个海岸区域", "阶段三 · 见证一次岸线追猎命中或落空"]
		_:
			if stage == 1:
				if entry_hotspot_label != "":
					return ["阶段一 · 先读清 %s" % entry_hotspot_label, "阶段一 · 在草原发现 3 种动物"]
				return ["阶段一 · 在草原发现 3 种动物", "阶段一 · 完成 1 个开阔观察任务"]
			if stage == 2:
				return ["阶段二 · 见证一次草原追逐压力", "阶段二 · 完成 2 个不同草原热点任务"]
			if terminal_active:
				if terminal_band == "pressure":
					return ["阶段三 · 见证一次草原追逐压力", "阶段三 · 进入下一个草原区域"]
				if terminal_band == "aftermath":
					return ["阶段三 · 见证一次草原追猎命中或落空", "阶段三 · 进入下一个草原区域"]
				if terminal_band == "exit":
					return ["阶段三 · 进入下一个草原区域", "阶段三 · 见证一次草原追猎命中或落空"]
			return ["阶段三 · 进入下一个草原区域", "阶段三 · 见证一次草原追猎命中或落空"]


func _arrival_sorted_objective_rows(rows: Array) -> Array:
	if arrival_event_focus_timer <= 0.0:
		return rows
	var sorted := rows.duplicate()
	var focus_kind := _recommended_route_focus_kind()
	var terminal_band := _stage_shell_focus_band("terminal")
	var arrival_scale := _recommended_route_focus_scale()
	var terminal_scale := _recommended_terminal_scale()
	var blended_limit := minf(1.0, maxf(0.0, arrival_scale - 0.96) / 0.22)
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		var a_row := str(a)
		var b_row := str(b)
		var a_score := 0.0
		var b_score := 0.0
		match focus_kind:
			"entry_route", "trunk_route":
				if "发现" in a_row:
					a_score += 18.0 * blended_limit
				if "发现" in b_row:
					b_score += 18.0 * blended_limit
				if "进入下一个" in a_row:
					a_score -= 8.0 * blended_limit
				if "进入下一个" in b_row:
					b_score -= 8.0 * blended_limit
			"branch_route":
				if "热点任务" in a_row or "观察" in a_row:
					a_score += 18.0 * blended_limit
				if "热点任务" in b_row or "观察" in b_row:
					b_score += 18.0 * blended_limit
			"chokepoint", "route_landmark":
				var terminal_bonus := blended_limit * terminal_scale
				match terminal_band:
					"pressure":
						if "追逐压力" in a_row:
							a_score += 28.0 * terminal_bonus
						if "追逐压力" in b_row:
							b_score += 28.0 * terminal_bonus
						if "追猎命中或落空" in a_row:
							a_score += 18.0 * terminal_bonus
						if "追猎命中或落空" in b_row:
							b_score += 18.0 * terminal_bonus
						if "进入下一个" in a_row:
							a_score += 8.0 * terminal_bonus
						if "进入下一个" in b_row:
							b_score += 8.0 * terminal_bonus
					"aftermath":
						if "追猎命中或落空" in a_row:
							a_score += 30.0 * terminal_bonus
						if "追猎命中或落空" in b_row:
							b_score += 30.0 * terminal_bonus
						if "进入下一个" in a_row:
							a_score += 10.0 * terminal_bonus
						if "进入下一个" in b_row:
							b_score += 10.0 * terminal_bonus
						if "追逐压力" in a_row:
							a_score += 12.0 * terminal_bonus
						if "追逐压力" in b_row:
							b_score += 12.0 * terminal_bonus
					"exit":
						if "进入下一个" in a_row:
							a_score += 28.0 * terminal_bonus
						if "进入下一个" in b_row:
							b_score += 28.0 * terminal_bonus
						if "追猎命中或落空" in a_row:
							a_score += 16.0 * terminal_bonus
						if "追猎命中或落空" in b_row:
							b_score += 16.0 * terminal_bonus
						if "追逐压力" in a_row:
							a_score += 10.0 * terminal_bonus
						if "追逐压力" in b_row:
							b_score += 10.0 * terminal_bonus
					_:
						if "追逐压力" in a_row:
							a_score += 22.0 * terminal_bonus
						if "追逐压力" in b_row:
							b_score += 22.0 * terminal_bonus
						if "追猎命中或落空" in a_row:
							a_score += 24.0 * terminal_bonus
						if "追猎命中或落空" in b_row:
							b_score += 24.0 * terminal_bonus
						if "进入下一个" in a_row:
							a_score += 12.0 * terminal_bonus
						if "进入下一个" in b_row:
							b_score += 12.0 * terminal_bonus
		return a_score > b_score
	)
	return sorted


func _arrival_sorted_discovery_log(limit: int) -> Array:
	var lines := discovery_log.slice(0, min(discovery_log.size(), max(limit, 0)))
	if arrival_event_focus_timer <= 0.0:
		return lines
	var focus_kind := _recommended_route_focus_kind()
	var terminal_band := _stage_shell_focus_band("terminal")
	var arrival_scale := _recommended_route_focus_scale()
	var terminal_scale := _recommended_terminal_scale()
	var blended_limit := minf(1.0, maxf(0.0, arrival_scale - 0.96) / 0.22)
	lines.sort_custom(func(a: Variant, b: Variant) -> bool:
		var a_line := str(a)
		var b_line := str(b)
		var a_score := float(_entry_screen_log_boost(a_line))
		var b_score := float(_entry_screen_log_boost(b_line))
		match focus_kind:
			"branch_route":
				if "支路" in a_line or "观察" in a_line or "热点" in a_line:
					a_score += 16.0 * blended_limit
				if "支路" in b_line or "观察" in b_line or "热点" in b_line:
					b_score += 16.0 * blended_limit
			"chokepoint", "route_landmark":
				var terminal_bonus := blended_limit * terminal_scale
				match terminal_band:
					"pressure":
						if "终端压力段" in a_line or "压迫" in a_line or "追逐" in a_line:
							a_score += 26.0 * terminal_bonus
						if "终端压力段" in b_line or "压迫" in b_line or "追逐" in b_line:
							b_score += 26.0 * terminal_bonus
					"aftermath":
						if "余波" in a_line or "终端" in a_line or "追猎" in a_line:
							a_score += 28.0 * terminal_bonus
						if "余波" in b_line or "终端" in b_line or "追猎" in b_line:
							b_score += 28.0 * terminal_bonus
					"exit":
						if "离场" in a_line or "出口" in a_line or "终端" in a_line:
							a_score += 28.0 * terminal_bonus
						if "离场" in b_line or "出口" in b_line or "终端" in b_line:
							b_score += 28.0 * terminal_bonus
					_:
						if "终端压力段" in a_line or "追猎" in a_line or "余波" in a_line:
							a_score += 22.0 * terminal_bonus
						if "终端压力段" in b_line or "追猎" in b_line or "余波" in b_line:
							b_score += 22.0 * terminal_bonus
			"entry_route", "trunk_route":
				if "入口" in a_line or "主路" in a_line:
					a_score += 14.0 * blended_limit
				if "入口" in b_line or "主路" in b_line:
					b_score += 14.0 * blended_limit
		return a_score > b_score
	)
	return lines


func _route_stage_objective_prompt() -> String:
	var progress_stage := _current_progress_stage()
	var terminal_signal := _terminal_signal_text()
	var terminal_action := _recommended_terminal_action_text()
	var entry_objective := _entry_screen_objective_text()
	var gate_prompt := _gate_focus_prompt_text()
	if arrival_event_focus_timer > 0.0:
		if entry_objective != "":
			return entry_objective
		if gate_prompt != "":
			return gate_prompt + " 当前先按离场判断段收束，再决定是否切区。"
		match _recommended_route_focus_kind():
			"entry_route":
				return "当前引导 · 落地首段先沿推荐入口链读图，优先确认入口主线和出口方向。"
			"trunk_route":
				return "当前引导 · 落地首段先并入推荐主路，优先确认主干推进方向。"
			"branch_route":
				return "当前引导 · 落地首段先贴推荐支路线，优先吃到第一个观察热点。"
			"chokepoint", "route_landmark":
				return "当前引导 · 落地首段先盯推荐终端链，优先确认结果段和离场门。%s %s" % [terminal_action, terminal_signal]
	match current_route_stage:
		"entry":
			if entry_objective != "":
				return entry_objective
			if gate_prompt != "":
				return gate_prompt + " 当前先按离场判断段收束，再决定是否切区。"
			match current_biome:
				"wetland":
					return "当前引导 · 先沿栈桥入口推进，优先把近水点和出口线读清。"
				"forest":
					return "当前引导 · 先穿树门进林道，优先确认主路和首个林下观察点。"
				"coast":
					return "当前引导 · 先沿岸入口推进，优先读清岸线主路和远侧出口。"
				_:
					return "当前引导 · 先沿草原入口上主道，优先确认迁徙主线和出口方向。"
		"branch":
			match current_biome:
				"wetland":
					return "当前引导 · 支路段偏近水观察，优先完成浅滩/栈道采样。"
				"forest":
					return "当前引导 · 支路段偏林下观察，优先靠近遮挡后的水坑或林道点。"
				"coast":
					return "当前引导 · 支路段偏沿岸观察，优先贴岸侧热点推进采样。"
				_:
					return "当前引导 · 支路段偏开阔观察，优先吃到迁徙或水源热点。"
		"terminal":
			if progress_stage >= 3:
				match current_biome:
					"wetland":
						return "当前引导 · 终端段偏余波与出口，优先见证近水追猎结果并准备切区。%s %s" % [terminal_action, terminal_signal]
					"forest":
						return "当前引导 · 终端段偏林缘高张力，优先盯住追猎结果或树门出口。%s %s" % [terminal_action, terminal_signal]
					"coast":
						return "当前引导 · 终端段偏岸侧余波，优先见证盘旋聚场并准备离场。%s %s" % [terminal_action, terminal_signal]
					_:
						return "当前引导 · 终端段偏开阔追猎与离场，优先确认结果并切向下一片区域。%s %s" % [terminal_action, terminal_signal]
			match current_biome:
				"wetland":
					return "当前引导 · 终端段偏近水高张力，优先读清撤离口和腐食盘旋终端。%s %s" % [terminal_action, terminal_signal]
				"forest":
					return "当前引导 · 终端段偏林缘高张力，优先读清林门终端和腐食侧动线。%s %s" % [terminal_action, terminal_signal]
				"coast":
					return "当前引导 · 终端段偏沿岸高张力，优先读清撤离口和盘旋聚场。%s %s" % [terminal_action, terminal_signal]
				_:
					return "当前引导 · 终端段偏追猎高张力，优先读清迁徙终端和腐食终端。%s %s" % [terminal_action, terminal_signal]
		_:
			match current_biome:
				"wetland":
					return "当前引导 · 主路段偏稳态推进，优先沿栈桥读下一个近水观察点。"
				"forest":
					return "当前引导 · 主路段偏林道推进，优先沿林下主路找下一处空地。"
				"coast":
					return "当前引导 · 主路段偏沿岸推进，优先顺岸线找下一个分路口。"
				_:
					return "当前引导 · 主路段偏开阔推进，优先顺主道把迁徙线和支路关系读清。"


func _progress_stage_prompt() -> String:
	var entry_progress := _entry_screen_progress_text(false)
	if entry_progress != "":
		return entry_progress
	var gate_progress := _gate_focus_progress_text(false)
	if gate_progress != "":
		return gate_progress
	match _current_progress_stage():
		1:
			return "当前进度 · 先立住发现链，优先补首批物种和第一个热点。"
		2:
			return "当前进度 · 先立住压力链，优先见证追逐并完成多热点并行观察。"
		_:
			return "当前进度 · 先立住结果链，优先盯余波、终端和切区准备。"


func _refresh_ui() -> void:
	region_label.text = "%s · %s" % [str(region_detail.get("name", "区域")), _biome_label(current_biome)]
	var health: Dictionary = region_detail.get("health_state", {})
	var pressure_window := _dynamic_pressure_window()
	var interaction_state := _dynamic_interaction_state()
	var event_state := _dynamic_event_state()
	var objective_state := _dynamic_objective_state()
	var chase_state := _dynamic_chase_state()
	var completion_state := _dynamic_completion_state()
	var exit_state := _dynamic_exit_state()
	var pressure_line := "当前压力 · %s（%s）" % [
		str(pressure_window.get("primary_pressure", "稳定态势")),
		str(pressure_window.get("event_bias", "区域平衡")),
	]
	if arrival_event_focus_timer > 0.0:
		pressure_line = _arrival_pressure_prompt() + " · " + pressure_line
	var interaction_line := "当前关系 · %s" % str(interaction_state.get("dominant_interaction", "均衡链"))
	var event_line := "当前事件带 · %s" % str(event_state.get("active_event_band", "稳态"))
	var objective_line := "当前生态导引 · %s → %s（%s）" % [
		str(objective_state.get("primary_hotspot", "waterhole")),
		str(objective_state.get("secondary_hotspot", "migration_corridor")),
		str(objective_state.get("priority_category", "草食动物")),
	]
	var entry_screen_line := _entry_screen_signal_text()
	var entry_screen_event_line := _entry_screen_event_text()
	var entry_screen_event_short := _entry_screen_event_short_text()
	var entry_objective_line := _entry_screen_objective_line()
	var gate_focus_line := _gate_focus_prompt_text()
	var gate_focus_event_short := _gate_focus_event_short_text()
	if entry_objective_line != "":
		objective_line = entry_objective_line
	if gate_focus_line != "":
		event_line = "当前离场判断 · 门段和出口线已优先"
	elif entry_screen_event_line != "":
		event_line = entry_screen_event_line
	var chase_line := "当前追猎导引 · %s → %s" % [
		str(chase_state.get("pressure_hotspot", "predator_ridge")),
		str(chase_state.get("aftermath_hotspot", "carrion_field")),
	]
	var completion_line := "当前完成态 · %s" % str(completion_state.get("summary", "继续沿当前生态链推进。"))
	var exit_line := "当前出口建议 · %s" % str(exit_state.get("summary", "继续观察，再决定是否离场。"))
	var terminal_signal_line := _terminal_signal_text()
	var progress_prompt := _arrival_progress_prompt() if arrival_event_focus_timer > 0.0 else _progress_stage_prompt()
	var completion_prompt := _arrival_completion_prompt() if arrival_event_focus_timer > 0.0 else _progress_stage_completion_prompt()
	stats_label.text = "繁荣 %d  稳定 %d  风险 %d" % [
		int(round(float(health.get("prosperity", 0.0)) * 100.0)),
		int(round(float(health.get("stability", 0.0)) * 100.0)),
		int(round(float(health.get("collapse_risk", 0.0)) * 100.0)),
	]
	if current_event.is_empty():
		var signal_suffix := ""
		if terminal_signal_line != "":
			signal_suffix = "。%s" % terminal_signal_line
		if gate_focus_event_short != "":
			event_label.text = "%s\n%s%s" % [_route_stage_label(), gate_focus_event_short, signal_suffix]
		elif entry_screen_event_short != "":
			event_label.text = "%s\n%s%s" % [_route_stage_label(), entry_screen_event_short, signal_suffix]
		else:
			match current_biome:
				"wetland":
					event_label.text = "湿地探索中 · %s。%s。%s。%s。%s。%s。%s。%s%s%s%s" % [_route_stage_label(), _route_stage_prompt(), completion_prompt, pressure_line, interaction_line, event_line, completion_line, exit_line, ("。%s" % entry_screen_line) if entry_screen_line != "" else "", ("。%s" % gate_focus_line) if gate_focus_line != "" else "", signal_suffix]
				"forest":
					event_label.text = "森林探索中 · %s。%s。%s。%s。%s。%s。%s。%s%s%s%s" % [_route_stage_label(), _route_stage_prompt(), completion_prompt, pressure_line, interaction_line, event_line, completion_line, exit_line, ("。%s" % entry_screen_line) if entry_screen_line != "" else "", ("。%s" % gate_focus_line) if gate_focus_line != "" else "", signal_suffix]
				"coast":
					event_label.text = "海岸探索中 · %s。%s。%s。%s。%s。%s。%s。%s%s%s%s" % [_route_stage_label(), _route_stage_prompt(), completion_prompt, pressure_line, interaction_line, event_line, completion_line, exit_line, ("。%s" % entry_screen_line) if entry_screen_line != "" else "", ("。%s" % gate_focus_line) if gate_focus_line != "" else "", signal_suffix]
				_:
					event_label.text = "草原探索中 · %s。%s。%s。%s。%s。%s。%s。%s%s%s%s" % [_route_stage_label(), _route_stage_prompt(), completion_prompt, pressure_line, interaction_line, event_line, completion_line, exit_line, ("。%s" % entry_screen_line) if entry_screen_line != "" else "", ("。%s" % gate_focus_line) if gate_focus_line != "" else "", signal_suffix]
	else:
		event_label.text = "%s\n%s" % [str(current_event.get("title", "")), str(current_event.get("body", ""))]

	match current_biome:
		"wetland":
			codex_title.text = "湿地生态图鉴"
		"forest":
			codex_title.text = "森林生态图鉴"
		"coast":
			codex_title.text = "海岸生态图鉴"
		_:
			codex_title.text = "草原生态图鉴"
	var objective_rows := _arrival_sorted_objective_rows(_objective_rows())
	var objective_text := _objective_panel_title()
	var entry_objective_short := _entry_screen_objective_short_text()
	var gate_objective_short := _gate_focus_objective_short_text()
	var entry_completion_short := _entry_screen_completion_short_text()
	var gate_completion_short := _gate_focus_completion_short_text()
	var entry_chase_short := _entry_screen_chase_short_text()
	var gate_chase_short := _gate_focus_chase_short_text()
	if gate_objective_short != "":
		objective_text += "› %s\n" % gate_objective_short
	elif entry_objective_short != "":
		objective_text += "› %s\n" % entry_objective_short
	else:
		objective_text += "› %s\n" % (_arrival_objective_prompt() if arrival_event_focus_timer > 0.0 else _route_stage_objective_prompt())
	objective_text += "› %s\n" % progress_prompt
	if gate_completion_short != "":
		objective_text += "› %s\n" % gate_completion_short
	elif entry_completion_short != "":
		objective_text += "› %s\n" % entry_completion_short
	else:
		objective_text += "› %s\n" % completion_prompt
	objective_text += "› %s\n" % (gate_completion_short if gate_completion_short != "" else (entry_completion_short if entry_completion_short != "" else str(objective_state.get("completion_hint", "继续沿当前生态链推进。"))))
	objective_text += "› %s\n" % (gate_chase_short if gate_chase_short != "" else (entry_chase_short if entry_chase_short != "" else chase_line))
	var stage_checks := _objective_check_states()
	for idx in range(objective_rows.size()):
		var mark := "✓" if stage_checks[idx] else "·"
		objective_text += "%s %s\n" % [mark, objective_rows[idx]]
	objectives_label.text = objective_text

	var species_text := _species_panel_title()
	var entry_species_short := _entry_screen_species_short_text()
	var gate_species_short := _gate_focus_species_short_text()
	if gate_species_short != "":
		species_text += "› %s\n" % gate_species_short
	elif entry_species_short != "":
		species_text += "› %s\n" % entry_species_short
	else:
		species_text += "› %s\n" % _route_stage_species_prompt()
	species_text += "› %s\n" % (gate_objective_short if gate_objective_short != "" else (entry_objective_short if entry_objective_short != "" else objective_line))
	for entry in _arrival_sorted_species_manifest(14):
		species_text += "%s %s × %d\n" % [
			CATEGORY_ICONS.get(str(entry.get("category", "")), "•"),
			str(entry.get("label", "")),
			int(entry.get("count", 0)),
		]
	species_label.text = species_text

	var log_text := _log_panel_title()
	var entry_log_short := _entry_screen_log_short_text()
	var gate_log_short := _gate_focus_log_short_text()
	if gate_log_short != "":
		log_text += "› %s\n" % gate_log_short
	elif entry_log_short != "":
		log_text += "› %s\n" % entry_log_short
	else:
		log_text += "› %s\n" % _route_stage_log_prompt()
	for line in _arrival_sorted_discovery_log(10):
		log_text += "• %s\n" % str(line)
	if current_hotspot.is_empty() and current_chase_result.is_empty() and chase_aftermath.is_empty() and current_event.is_empty():
		log_text += "• %s\n" % _idle_log_prompt()
	log_label.text = log_text

	var exit_hint := "WASD/方向键移动   Shift 冲刺   Tab 图鉴   E 进出口   M 世界图"
	if not pending_gate_transition.is_empty():
		exit_hint = "过门中   |   " + _route_stage_reentry_prompt()
	elif not pending_arrival_intro.is_empty():
		exit_hint = "并入主路中   |   " + _route_stage_reentry_prompt()
	elif not current_exit_zone.is_empty():
		exit_hint = str(current_exit_zone.get("hint", "")) + "   |   " + _route_stage_exit_prompt() + "   |   " + exit_hint
	var hint_mid := progress_prompt
	if gate_focus_event_short != "":
		hint_mid = gate_focus_event_short
	elif entry_screen_event_short != "":
		hint_mid = entry_screen_event_short
	var hint_text := _route_stage_label() + "   |   " + hint_mid + "   |   " + _route_stage_focus_prompt()
	if terminal_signal_line != "":
		hint_text += "   |   " + terminal_signal_line
	if entry_screen_line != "":
		hint_text += "   |   " + entry_screen_line
	hint_text += "   |   " + exit_hint
	hint_label.text = hint_text


func _player_vec2() -> Vector2:
	return Vector2(player_body.global_position.x, player_body.global_position.z)


func _entry_screen_focus_strength() -> float:
	var spawn := Vector3(current_layout.get("spawn", Vector3.ZERO))
	var spawn_distance := Vector2(spawn.x, spawn.z).distance_to(_player_vec2())
	var profile := _route_stage_profile()
	var entry_radius := maxf(8.0, float(profile.get("entry_radius", 14.0)))
	var spatial_strength := clampf(1.0 - spawn_distance / (entry_radius * 0.96), 0.0, 1.0)
	var arrival_strength := 0.0
	if arrival_event_focus_timer > 0.0:
		arrival_strength = clampf(arrival_event_focus_timer / 3.2, 0.0, 1.0)
	return maxf(spatial_strength, arrival_strength)


func _entry_screen_hotspot_scale(hotspot_id: String) -> float:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return 1.0
	var focus_kind := _recommended_route_focus_kind()
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id != "":
		if hotspot_id == primary_hotspot_id:
			return lerpf(1.0, 1.14, focus_strength)
		if focus_kind in ["entry_route", "trunk_route", "branch_route", "chokepoint", "route_landmark"]:
			return lerpf(1.0, 0.82, focus_strength)
	match focus_kind:
		"entry_route", "trunk_route":
			if hotspot_id in ["predator_ridge", "carrion_field"]:
				return lerpf(1.0, 0.76, focus_strength)
			if hotspot_id in ["waterhole", "migration_corridor", "shade_grove"]:
				return lerpf(1.0, 1.06, focus_strength)
		"chokepoint", "route_landmark":
			if hotspot_id in ["predator_ridge", "carrion_field"]:
				return lerpf(1.0, 1.1, focus_strength)
			return lerpf(1.0, 0.82, focus_strength)
	return 1.0


func _entry_screen_primary_hotspot_id() -> String:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return ""
	var focus_kind := _recommended_route_focus_kind()
	var objective_state := _dynamic_objective_state()
	var chase_state := _dynamic_chase_state()
	var primary_hotspot := str(objective_state.get("primary_hotspot", ""))
	var secondary_hotspot := str(objective_state.get("secondary_hotspot", ""))
	match focus_kind:
		"branch_route":
			if primary_hotspot != "":
				return primary_hotspot
			if secondary_hotspot != "":
				return secondary_hotspot
		"chokepoint", "route_landmark":
			match _stage_shell_focus_band("terminal"):
				"pressure":
					return str(chase_state.get("pressure_hotspot", "predator_ridge"))
				"aftermath":
					return str(chase_state.get("aftermath_hotspot", "carrion_field"))
				"exit":
					if secondary_hotspot != "":
						return secondary_hotspot
		"entry_route":
			if primary_hotspot != "":
				return primary_hotspot
			return "waterhole"
		"trunk_route":
			if primary_hotspot != "":
				return primary_hotspot
			if secondary_hotspot != "":
				return secondary_hotspot
			return "migration_corridor"
	return ""


func _entry_screen_ambient_boost(channel: String) -> float:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return 1.0
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return 1.0
	if channel == primary_hotspot_id:
		return lerpf(1.0, 1.18, focus_strength)
	if channel in hotspot_visuals:
		return lerpf(1.0, 0.76, focus_strength)
	return 1.0


func _gate_focus_hold_strength() -> float:
	var hold := 0.0
	if not current_exit_zone.is_empty():
		var exit_pos3 := Vector3(current_exit_zone.get("position", Vector3.ZERO))
		var exit_distance := _player_vec2().distance_to(Vector2(exit_pos3.x, exit_pos3.z))
		hold = maxf(hold, clampf(1.0 - exit_distance / 12.0, 0.0, 1.0))
	if not current_route_focus.is_empty():
		var kind := str(current_route_focus.get("kind", ""))
		if kind in ["chokepoint", "route_landmark"]:
			var focus_pos3 := Vector3(current_route_focus.get("position", player_body.global_position))
			var focus_distance := _player_vec2().distance_to(Vector2(focus_pos3.x, focus_pos3.z))
			hold = maxf(hold, clampf(1.0 - focus_distance / 15.0, 0.0, 1.0))
	if arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"]:
		hold = maxf(hold, 0.42)
	return hold


func _gate_focus_competition_scale(channel: String) -> float:
	var hold := smoothed_gate_focus_hold if smoothed_gate_focus_hold > 0.0 else _gate_focus_hold_strength()
	if hold <= 0.0:
		return 1.0
	match channel:
		"hotspot":
			return lerpf(1.0, 0.76, hold)
		"encounter":
			return lerpf(1.0, 0.82, hold)
		"exit":
			return lerpf(1.0, 1.16, hold)
		_:
			return 1.0


func _gate_focus_center_offset() -> Vector3:
	var hold := smoothed_gate_focus_hold if smoothed_gate_focus_hold > 0.0 else _gate_focus_hold_strength()
	if hold <= 0.0:
		return Vector3.ZERO
	var gate_id := str(current_exit_zone.get("id", ""))
	if gate_id == "":
		gate_id = _recommended_exit_gate_id()
	if gate_id == "":
		return Vector3.ZERO
	var gate_position := Vector3.ZERO
	if not current_exit_zone.is_empty() and str(current_exit_zone.get("id", "")) == gate_id:
		gate_position = Vector3(current_exit_zone.get("position", Vector3.ZERO))
	else:
		for zone in exit_zones:
			if str(zone.get("id", "")) == gate_id:
				gate_position = Vector3(zone.get("position", Vector3.ZERO))
				break
	if gate_position == Vector3.ZERO:
		return Vector3.ZERO
	var gate_forward := _gate_forward_vector(gate_id)
	var gate_right := Vector3(gate_forward.z, 0.0, -gate_forward.x).normalized()
	var player_offset := player_body.global_position - gate_position
	var lateral_offset := gate_right.dot(player_offset)
	return -gate_right * lateral_offset * 0.22 * hold


func _entry_screen_event_boost(kind: String) -> float:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return 0.0
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	var focus_kind := _recommended_route_focus_kind()
	var base := 0.0
	match kind:
		"hotspot", "task":
			if primary_hotspot_id != "" and str(current_hotspot.get("hotspot_id", "")) == primary_hotspot_id:
				base = 18.0 * focus_strength
			elif focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
				base = -10.0 * focus_strength
		"encounter":
			if primary_hotspot_id != "":
				var required_category := str(_hotspot_task_config(primary_hotspot_id).get("required_category", ""))
				if required_category != "" and str(current_encounter.get("category", "")) == required_category:
					base = 10.0 * focus_strength
				elif focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
					base = -8.0 * focus_strength
		"exit":
			if focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
				base = 12.0 * focus_strength
	return base


func _gate_focus_event_boost(kind: String) -> float:
	var hold := smoothed_gate_focus_hold if smoothed_gate_focus_hold > 0.0 else _gate_focus_hold_strength()
	if hold <= 0.0:
		return 0.0
	match kind:
		"exit":
			return 18.0 * hold
		"hotspot", "task":
			return -12.0 * hold
		"encounter":
			return -10.0 * hold
		_:
			return 0.0


func _gate_focus_event_clamp(kind: String) -> float:
	var hold := smoothed_gate_focus_hold if smoothed_gate_focus_hold > 0.0 else _gate_focus_hold_strength()
	if hold < 0.52:
		return 0.0
	match kind:
		"exit":
			return 16.0 * hold
		"hotspot", "task":
			return -18.0 * hold
		"encounter":
			return -14.0 * hold
		_:
			return 0.0


func _entry_screen_species_boost(entry: Dictionary) -> int:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return 0
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return 0
	var required_category := str(_hotspot_task_config(primary_hotspot_id).get("required_category", ""))
	if required_category == "":
		return 0
	var entry_category := str(entry.get("category", ""))
	if entry_category == required_category:
		return int(round(20.0 * focus_strength))
	var focus_kind := _recommended_route_focus_kind()
	if focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
		return -int(round(8.0 * focus_strength))
	return 0


func _entry_screen_log_boost(line: String) -> int:
	var focus_strength := _entry_screen_focus_strength()
	if focus_strength <= 0.0:
		return 0
	var primary_hotspot_id := _entry_screen_primary_hotspot_id()
	if primary_hotspot_id == "":
		return 0
	var primary_cfg := _hotspot_task_config(primary_hotspot_id)
	var hotspot_label := str(primary_cfg.get("label", primary_hotspot_id))
	if hotspot_label != "" and hotspot_label in line:
		return int(round(22.0 * focus_strength))
	var focus_kind := _recommended_route_focus_kind()
	if focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"] and ("支路" in line or "热点" in line or "观察" in line):
		return -int(round(8.0 * focus_strength))
	return 0


func _objective_panel_title() -> String:
	match current_biome:
		"wetland":
			return "湿地目标 · %s\n" % _route_stage_label()
		"forest":
			return "森林目标 · %s\n" % _route_stage_label()
		"coast":
			return "海岸目标 · %s\n" % _route_stage_label()
		_:
			return "草原目标 · %s\n" % _route_stage_label()


func _species_panel_title() -> String:
	match current_biome:
		"wetland":
			return "可见湿地生物 · %s\n" % _route_stage_label()
		"forest":
			return "可见林间生物 · %s\n" % _route_stage_label()
		"coast":
			return "可见岸线生物 · %s\n" % _route_stage_label()
		_:
			return "可见草原生物 · %s\n" % _route_stage_label()


func _log_panel_title() -> String:
	match current_biome:
		"wetland":
			return "湿地记录 · %s\n" % _route_stage_label()
		"forest":
			return "林间记录 · %s\n" % _route_stage_label()
		"coast":
			return "岸线记录 · %s\n" % _route_stage_label()
		_:
			return "草原记录 · %s\n" % _route_stage_label()


func _route_stage_focus_prompt() -> String:
	if current_route_focus.is_empty():
		return "当前骨架焦点 · 正沿当前阶段主线推进。%s" % _progress_stage_focus_suffix()
	var kind := str(current_route_focus.get("kind", "trunk_route"))
	var shell_suffix := _stage_shell_focus_text()
	match kind:
		"entry_route", "entry_marker":
			return "当前骨架焦点 · 入口段与入口引导带优先。%s%s" % [_progress_stage_focus_suffix(), shell_suffix]
		"branch_route", "branch_marker":
			return "当前骨架焦点 · 支路与观察分叉优先。%s%s" % [_progress_stage_focus_suffix(), shell_suffix]
		"chokepoint":
			return "当前骨架焦点 · 卡口与终端门段优先。%s%s" % [_progress_stage_focus_suffix(), shell_suffix]
		"route_landmark":
			return "当前骨架焦点 · 路线地标与终端锚点优先。%s%s" % [_progress_stage_focus_suffix(), shell_suffix]
		_:
			return "当前骨架焦点 · 主路与中继连接优先。%s%s" % [_progress_stage_focus_suffix(), shell_suffix]


func _progress_stage_focus_suffix() -> String:
	match _current_progress_stage():
		1:
			return "当前更偏发现链。"
		2:
			return "当前更偏压力链。"
		_:
			return "当前更偏结果链。"


func _stage_shell_focus_band(stage: String = "") -> String:
	var resolved_stage := current_route_stage if stage == "" else stage
	var objective_state := _dynamic_objective_state()
	var chase_state := _dynamic_chase_state()
	var exit_state := _dynamic_exit_state()
	var recommended_gate_id := _recommended_exit_gate_id()
	if resolved_stage == "terminal":
		var backend_terminal_band := str(exit_state.get("recommended_terminal_band", ""))
		if backend_terminal_band in ["pressure", "aftermath", "exit"]:
			return backend_terminal_band
		if arrival_event_focus_timer > 0.0:
			match _recommended_route_focus_kind():
				"chokepoint", "route_landmark":
					if str(chase_state.get("aftermath_hotspot", "")) != "":
						return "aftermath"
					if str(chase_state.get("pressure_hotspot", "")) != "":
						return "pressure"
					if recommended_gate_id != "":
						return "exit"
		if not chase_aftermath.is_empty() or str(chase_state.get("aftermath_hotspot", "")) != "":
			return "aftermath"
		if not current_chase.is_empty() or str(chase_state.get("pressure_hotspot", "")) != "":
			return "pressure"
		if not current_exit_zone.is_empty() or recommended_gate_id != "":
			return "exit"
	if resolved_stage == "branch":
		if str(objective_state.get("primary_hotspot", "")) != "":
			return "objective"
	return ""


func _stage_shell_focus_profile(stage: String) -> Dictionary:
	var band := _stage_shell_focus_band(stage)
	var terminal_scale := _recommended_terminal_scale()
	match band:
		"objective":
			return {"active_scale": 1.06, "ring_scale": 1.08, "beacon_scale": 1.06, "ring_alpha_scale": 1.08, "beacon_alpha_scale": 1.08}
		"pressure":
			return {
				"active_scale": _terminal_scale_adjust(1.1),
				"ring_scale": _terminal_scale_adjust(1.12),
				"beacon_scale": _terminal_scale_adjust(1.1),
				"ring_alpha_scale": _terminal_scale_adjust(1.12),
				"beacon_alpha_scale": _terminal_scale_adjust(1.14)
			}
		"aftermath":
			return {
				"active_scale": _terminal_scale_adjust(1.14),
				"ring_scale": _terminal_scale_adjust(1.16),
				"beacon_scale": _terminal_scale_adjust(1.14),
				"ring_alpha_scale": _terminal_scale_adjust(1.16),
				"beacon_alpha_scale": _terminal_scale_adjust(1.18)
			}
		"exit":
			return {
				"active_scale": _terminal_scale_adjust(1.08),
				"ring_scale": _terminal_scale_adjust(1.1),
				"beacon_scale": _terminal_scale_adjust(1.16),
				"ring_alpha_scale": _terminal_scale_adjust(1.06),
				"beacon_alpha_scale": _terminal_scale_adjust(1.16)
			}
		_:
			return {"active_scale": 1.0, "ring_scale": 1.0, "beacon_scale": 1.0, "ring_alpha_scale": 1.0, "beacon_alpha_scale": 1.0}


func _stage_shell_focus_suffix() -> String:
	match _stage_shell_focus_band():
		"objective":
			return " · 观察链"
		"pressure":
			return " · 压力链"
		"aftermath":
			return " · 余波链"
		"exit":
			return " · 离场链"
		_:
			return ""


func _stage_shell_focus_text() -> String:
	var terminal_signal := _terminal_signal_text()
	match _stage_shell_focus_band():
		"objective":
			return " 当前更偏观察链。"
		"pressure":
			return " 当前更偏终端压力链。%s" % terminal_signal
		"aftermath":
			return " 当前更偏终端余波链。%s" % terminal_signal
		"exit":
			return " 当前更偏终端离场链。%s" % terminal_signal
		_:
			return ""


func _route_focus_stage_name(kind: String) -> String:
	match kind:
		"entry_route", "entry_marker":
			return "entry"
		"branch_route", "branch_marker":
			return "branch"
		"chokepoint", "route_landmark":
			return "terminal"
		_:
			return "trunk"


func _stage_shell_transition_profile(band: String) -> Dictionary:
	match band:
		"objective":
			return {"alpha_scale": 1.02, "zoom_scale": 1.02}
		"pressure":
			return {"alpha_scale": 1.08, "zoom_scale": 1.1}
		"aftermath":
			return {"alpha_scale": 1.12, "zoom_scale": 1.14}
		"exit":
			return {"alpha_scale": 1.1, "zoom_scale": 1.08}
		_:
			return {"alpha_scale": 1.0, "zoom_scale": 1.0}


func _stage_shell_transition_suffix(band: String) -> String:
	match band:
		"objective":
			return "观察链"
		"pressure":
			return "压力链"
		"aftermath":
			return "余波链"
		"exit":
			return "离场链"
		_:
			return ""


func _transition_focus_body(arrival: bool) -> String:
	var kind := str(current_route_focus.get("kind", "trunk_route"))
	var focus_stage := _route_focus_stage_name(kind)
	var band := _stage_shell_focus_band(focus_stage)
	var gate_reason := _recommended_exit_gate_reason()
	var terminal_reason := _recommended_terminal_reason()
	var terminal_scale_text := _recommended_terminal_scale_text()
	match band:
		"pressure":
			return "当前按压力链推进，优先确认压迫热点、结果链和离场门。%s %s %s" % [terminal_scale_text, terminal_reason, gate_reason]
		"aftermath":
			return "当前按余波链推进，优先确认余波落点、回聚链和离场门。%s %s %s" % [terminal_scale_text, terminal_reason, gate_reason]
		"exit":
			return "当前按离场链推进，优先确认终端门段、出口线和切区条件。%s %s %s" % [terminal_scale_text, terminal_reason, gate_reason]
		"objective":
			return "当前按观察链推进，优先确认主热点、首段观察面和后续分支。%s" % gate_reason
		_:
			if arrival:
				return "当前先沿落地焦点读清第一段空间关系，再决定继续观察还是转入终端。%s" % gate_reason
			return "当前先沿过门焦点收束路线关系，再决定继续推进还是准备切区。%s" % gate_reason


func _stage_shell_route_boost(kind: String) -> float:
	var base := 1.0
	match _stage_shell_focus_band():
		"objective":
			if kind in ["branch_route", "branch_marker", "route_landmark"]:
				base = 1.08
			if kind in ["entry_route", "entry_marker", "chokepoint"]:
				base = 0.96
		"pressure":
			if kind in ["chokepoint", "route_landmark"]:
				base = 1.12
			if kind in ["entry_route", "entry_marker", "trunk_route", "trunk_marker"]:
				base = 0.94
		"aftermath":
			if kind in ["route_landmark", "chokepoint"]:
				base = 1.16
			if kind in ["branch_route", "branch_marker"]:
				base = 1.04
			if kind in ["entry_route", "entry_marker", "trunk_route", "trunk_marker"]:
				base = 0.92
		"exit":
			if kind in ["chokepoint", "route_landmark"]:
				base = 1.14
			if kind in ["branch_route", "branch_marker"]:
				base = 0.94
			if kind in ["entry_route", "entry_marker", "trunk_route", "trunk_marker"]:
				base = 0.9
	return _terminal_scale_adjust(base)


func _stage_shell_event_boost(kind: String) -> float:
	var base := 0.0
	match _stage_shell_focus_band():
		"objective":
			match kind:
				"hotspot", "task", "encounter":
					base = 0.45
				"chase", "chase_result", "aftermath", "exit":
					base = -0.18
		"pressure":
			match kind:
				"chase", "interaction":
					base = 0.42
				"chase_result", "aftermath":
					base = 0.18
				"hotspot", "task":
					base = -0.12
		"aftermath":
			match kind:
				"chase_result", "aftermath":
					base = 0.5
				"exit":
					base = 0.16
				"hotspot", "task", "encounter":
					base = -0.16
		"exit":
			match kind:
				"exit":
					base = 0.56
				"chase_result", "aftermath":
					base = 0.18
				"hotspot", "task", "encounter":
					base = -0.22
	return _terminal_event_scale_adjust(base)


func _terminal_chain_hotspot_boost(hotspot_id: String) -> float:
	var terminal_active := current_route_stage == "terminal" or (arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"])
	if not terminal_active:
		return 1.0
	match _stage_shell_focus_band("terminal"):
		"pressure":
			if hotspot_id == "predator_ridge":
				return _terminal_scale_adjust(1.18)
			if hotspot_id == "carrion_field":
				return _terminal_scale_adjust(0.98)
			return _terminal_scale_adjust(0.9)
		"aftermath":
			if hotspot_id == "carrion_field":
				return _terminal_scale_adjust(1.2)
			if hotspot_id == "predator_ridge":
				return _terminal_scale_adjust(1.06)
			return _terminal_scale_adjust(0.9)
		"exit":
			if hotspot_id in ["predator_ridge", "carrion_field"]:
				return _terminal_scale_adjust(0.94)
			return _terminal_scale_adjust(0.88)
		_:
			return 1.0


func _terminal_chain_exit_boost(exit_id: String) -> float:
	var terminal_active := current_route_stage == "terminal" or (arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"])
	if not terminal_active:
		return 1.0
	var recommended_gate_id := _recommended_exit_gate_id()
	match _stage_shell_focus_band("terminal"):
		"pressure":
			if exit_id == recommended_gate_id and recommended_gate_id != "":
				return _terminal_scale_adjust(1.04)
			return _terminal_scale_adjust(0.96)
		"aftermath":
			if exit_id == recommended_gate_id and recommended_gate_id != "":
				return _terminal_scale_adjust(1.08)
			return _terminal_scale_adjust(0.94)
		"exit":
			if exit_id == recommended_gate_id and recommended_gate_id != "":
				return _terminal_scale_adjust(1.18)
			return _terminal_scale_adjust(0.9)
		_:
			return 1.0


func _terminal_chain_animal_boost(category: String) -> Dictionary:
	var terminal_active := current_route_stage == "terminal" or (arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"])
	if not terminal_active:
		return {"reveal_scale": 1.0, "prominence_scale": 1.0, "signal_scale": 1.0}
	var terminal_scale := _recommended_terminal_scale()
	match _stage_shell_focus_band("terminal"):
		"pressure":
			if category == "掠食者":
				return {
					"reveal_scale": _terminal_scale_adjust(1.14),
					"prominence_scale": _terminal_scale_adjust(1.12),
					"signal_scale": _terminal_scale_adjust(1.14),
				}
			if category == "飞行动物":
				return {
					"reveal_scale": _terminal_scale_adjust(1.04),
					"prominence_scale": _terminal_scale_adjust(1.04),
					"signal_scale": _terminal_scale_adjust(1.08),
				}
			return {
				"reveal_scale": _terminal_scale_adjust(0.94),
				"prominence_scale": _terminal_scale_adjust(0.96),
				"signal_scale": _terminal_scale_adjust(0.96),
			}
		"aftermath":
			if category == "飞行动物":
				return {
					"reveal_scale": _terminal_scale_adjust(1.16),
					"prominence_scale": _terminal_scale_adjust(1.14),
					"signal_scale": _terminal_scale_adjust(1.16),
				}
			if category == "掠食者":
				return {
					"reveal_scale": _terminal_scale_adjust(1.08),
					"prominence_scale": _terminal_scale_adjust(1.08),
					"signal_scale": _terminal_scale_adjust(1.1),
				}
			return {
				"reveal_scale": _terminal_scale_adjust(0.94),
				"prominence_scale": _terminal_scale_adjust(0.96),
				"signal_scale": _terminal_scale_adjust(0.96),
			}
		"exit":
			if category in ["草食动物", "大型动物"]:
				return {
					"reveal_scale": _terminal_scale_adjust(1.08),
					"prominence_scale": _terminal_scale_adjust(1.06),
					"signal_scale": _terminal_scale_adjust(1.02),
				}
			if category in ["掠食者", "飞行动物"]:
				return {
					"reveal_scale": _terminal_scale_adjust(0.94),
					"prominence_scale": _terminal_scale_adjust(0.94),
					"signal_scale": _terminal_scale_adjust(0.94),
				}
			return {"reveal_scale": 1.0, "prominence_scale": 1.0, "signal_scale": 1.0}
		_:
			return {"reveal_scale": 1.0, "prominence_scale": 1.0, "signal_scale": 1.0}


func _route_focus_channel_boost(kind: String, pos3: Vector3 = Vector3.ZERO) -> float:
	if current_route_focus.is_empty():
		return 1.0
	var focus_kind := str(current_route_focus.get("kind", "trunk_route"))
	var focus_pos := Vector3(current_route_focus.get("position", pos3))
	var distance := Vector2(pos3.x, pos3.z).distance_to(Vector2(focus_pos.x, focus_pos.z))
	var distance_weight := clampf(1.0 - distance / 24.0, 0.0, 1.0)
	var base := 1.0
	match kind:
		"hotspot":
			match focus_kind:
				"branch_route", "branch_marker", "route_landmark":
					base = 1.18
				"entry_route", "entry_marker":
					base = 0.94
				"chokepoint":
					base = 1.04
				_:
					base = 1.06
		"exit":
			match focus_kind:
				"entry_route", "entry_marker":
					base = 1.18
				"chokepoint", "route_landmark":
					base = 1.22
				"branch_route", "branch_marker":
					base = 0.92
				_:
					base = 1.04
		"pressure", "aftermath":
			match focus_kind:
				"chokepoint", "route_landmark":
					base = 1.2
				"branch_route", "branch_marker":
					base = 1.08
				"entry_route", "entry_marker":
					base = 0.94
				_:
					base = 1.06
		"encounter":
			match focus_kind:
				"branch_route", "branch_marker":
					base = 1.14
				"trunk_route", "trunk_marker", "connector":
					base = 1.08
				_:
					base = 0.98
	return 1.0 + (base - 1.0) * distance_weight


func _route_focus_event_boost(kind: String, payload: Dictionary) -> int:
	var pos3 := Vector3.ZERO
	match kind:
		"exit":
			for zone in exit_zones:
				if str(zone.get("id", "")) == str(current_exit_zone.get("id", "")):
					pos3 = zone.get("position", Vector3.ZERO)
					break
			return int((_route_focus_channel_boost("exit", pos3) - 1.0) * 24.0)
		"hotspot", "task":
			var hotspot_id := str(current_hotspot.get("hotspot_id", ""))
			if hotspot_id != "":
				pos3 = _hotspot_pos(hotspot_id)
			return int((_route_focus_channel_boost("hotspot", pos3) - 1.0) * 22.0)
		"encounter", "interaction":
			pos3 = Vector3(payload.get("position", Vector2.ZERO).x, 0.0, payload.get("position", Vector2.ZERO).y)
			return int((_route_focus_channel_boost("encounter", pos3) - 1.0) * 20.0)
		"chase":
			pos3 = Vector3(payload.get("target", Vector2.ZERO).x, 0.0, payload.get("target", Vector2.ZERO).y)
			return int((_route_focus_channel_boost("pressure", pos3) - 1.0) * 24.0)
		"chase_result", "aftermath":
			pos3 = Vector3(payload.get("target", Vector2.ZERO).x, 0.0, payload.get("target", Vector2.ZERO).y)
			return int((_route_focus_channel_boost("aftermath", pos3) - 1.0) * 26.0)
		_:
			return 0


func _route_stage_species_prompt() -> String:
	var terminal_signal := _terminal_signal_text()
	var gate_focus_prompt := _gate_focus_prompt_text()
	var entry_species_prompt := _entry_screen_species_text()
	if arrival_event_focus_timer > 0.0:
		var terminal_band_arrival := _stage_shell_focus_band("terminal")
		match _recommended_route_focus_kind():
			"entry_route":
				return "落地观察优先 · 先看推荐入口链附近最先暴露的入口生物。"
			"trunk_route":
				return "落地观察优先 · 先看推荐主路附近最先成层的主道生物。"
			"branch_route":
				return "落地观察优先 · 先看推荐支路热点附近最先成组的观察对象。"
			"chokepoint", "route_landmark":
				match terminal_band_arrival:
					"pressure":
						return "落地观察优先 · 先看推荐压力终端链附近最先抬起的掠食与压迫对象。%s" % terminal_signal
					"aftermath":
						return "落地观察优先 · 先看推荐余波终端链附近最先抬起的飞行动物和余波对象。%s" % terminal_signal
					"exit":
						return "落地观察优先 · 先看推荐离场终端链附近最先抬起的终端物种和离场对象。%s" % terminal_signal
					_:
						return "落地观察优先 · 先看推荐终端链附近最先抬起的高张力物种。%s" % terminal_signal
	if entry_species_prompt != "":
		return entry_species_prompt
	if gate_focus_prompt != "":
		match current_biome:
			"wetland":
				return "离场判断段优先看栈桥门段、出口线附近物种和最后的近水目标。"
			"forest":
				return "离场判断段优先看树门门段、出口线附近物种和最后的林缘目标。"
			"coast":
				return "离场判断段优先看岸线门段、出口线附近物种和最后的沿岸目标。"
			_:
				return "离场判断段优先看门段、出口线附近物种和最后的终端目标。"
	match current_route_stage:
		"entry":
			match current_biome:
				"wetland":
					return "优先盯近水和栈桥边最先暴露的物种。"
				"forest":
					return "优先盯林门附近先露头的林间生物。"
				"coast":
					return "优先盯沿岸先暴露的飞行动物和岸侧活动点。"
				_:
					return "优先盯主道远端最先读到的开阔带物种。"
		"branch":
			match current_biome:
				"wetland":
					return "支路段偏近水采样，优先看浅滩与水域动物。"
				"forest":
					return "支路段偏林下观察，优先看遮挡后露出的水坑和草食群。"
				"coast":
					return "支路段偏沿岸观察，优先看岸侧迁移与盘旋目标。"
				_:
					return "支路段偏热点观察，优先盯迁徙线与水源附近的群落。"
		"terminal":
			match _stage_shell_focus_band("terminal"):
				"pressure":
					match current_biome:
						"wetland":
							return "终端压力段优先看近水掠食、压迫对象和栈桥边高张力目标。%s" % terminal_signal
						"forest":
							return "终端压力段优先盯林缘伏击点、掠食者和贴遮挡的压迫对象。%s" % terminal_signal
						"coast":
							return "终端压力段优先看沿岸压迫对象、掠食后续和近岸高张力目标。%s" % terminal_signal
						_:
							return "终端压力段优先盯掠食群、压迫对象和开阔高张力目标。%s" % terminal_signal
				"aftermath":
					match current_biome:
						"wetland":
							return "终端余波段优先看近水盘旋对象、余波落点和回聚链。%s" % terminal_signal
						"forest":
							return "终端余波段优先看林空盘旋对象、余波落点和林缘后续。%s" % terminal_signal
						"coast":
							return "终端余波段优先看沿岸盘旋对象、余波落点和岸侧聚场。%s" % terminal_signal
						_:
							return "终端余波段优先盯飞行动物、腐食区和余波聚场。%s" % terminal_signal
				"exit":
					match current_biome:
						"wetland":
							return "终端离场段优先看撤离口附近物种、离场链和最后的近水目标。%s" % terminal_signal
						"forest":
							return "终端离场段优先看树门终端物种、离场链和最后的林缘目标。%s" % terminal_signal
						"coast":
							return "终端离场段优先看岸线出口物种、离场链和最后的沿岸目标。%s" % terminal_signal
						_:
							return "终端离场段优先盯撤离线附近物种、离场链和最后的终端目标。%s" % terminal_signal
				_:
					match current_biome:
						"wetland":
							return "终端段偏高张力，优先看掠食、盘旋和近水余波目标。%s" % terminal_signal
						"forest":
							return "终端段偏林缘高张力，优先盯伏击点和林空盘旋目标。%s" % terminal_signal
						"coast":
							return "终端段偏岸侧余波，优先看沿岸盘旋和掠食后续。%s" % terminal_signal
						_:
							return "终端段偏追猎结果，优先盯掠食群、腐食区和撤离线。%s" % terminal_signal
		_:
			match current_biome:
				"wetland":
					return "主路段先稳定读图，优先把近水和栈桥生物分层看清。"
				"forest":
					return "主路段先稳读林道，优先看林间草食和遮挡边活动。"
				"coast":
					return "主路段先沿岸推进，优先看岸线飞行与沿岸草食。"
				_:
					return "主路段先稳读主道，优先看开阔带草食与远端掠食。"


func _route_stage_log_prompt() -> String:
	var terminal_signal := _terminal_signal_text()
	var gate_focus_prompt := _gate_focus_prompt_text()
	var entry_log_prompt := _entry_screen_log_text()
	if arrival_event_focus_timer > 0.0:
		var terminal_band_arrival := _stage_shell_focus_band("terminal")
		match _recommended_route_focus_kind():
			"entry_route":
				return "落地记录优先 · 先记推荐入口链的入口线、出口线和首个群落。"
			"trunk_route":
				return "落地记录优先 · 先记推荐主路的并入段、中继点和第一处分路。"
			"branch_route":
				return "落地记录优先 · 先记推荐支路热点、近距观察和首批物种。"
			"chokepoint", "route_landmark":
				match terminal_band_arrival:
					"pressure":
						return "落地记录优先 · 先记推荐压力终端链的压迫热点、卡口和结果门。%s" % terminal_signal
					"aftermath":
						return "落地记录优先 · 先记推荐余波终端链的余波落点、聚场和离场门。%s" % terminal_signal
					"exit":
						return "落地记录优先 · 先记推荐离场终端链的卡口、门段和切区条件。%s" % terminal_signal
					_:
						return "落地记录优先 · 先记推荐终端链的卡口、余波和离场门。%s" % terminal_signal
	if entry_log_prompt != "":
		return entry_log_prompt
	if gate_focus_prompt != "":
		return "优先记录离场判断段的门向、出口线和仍在竞争主焦点的最后对象。"
	match current_route_stage:
		"entry":
			return "先记入口段最先暴露的路线、出口和首个群落。"
		"branch":
			return "优先记当前支路热点、近距观察和刚吃到的物种。"
		"terminal":
			match _stage_shell_focus_band("terminal"):
				"pressure":
					return "优先记终端压力段的压迫热点、结果链和离场门。%s" % terminal_signal
				"aftermath":
					return "优先记终端余波段的余波落点、回聚链和离场门。%s" % terminal_signal
				"exit":
					return "优先记终端离场段的门段、出口线和切区条件。%s" % terminal_signal
				_:
					return "优先记终端区的余波、出口和高张力事件。%s" % terminal_signal
		_:
			return "优先记主路推进、分路口和下一处观察点。"


func _route_stage_reentry_prompt() -> String:
	var gate_hint := _recommended_exit_gate_reason()
	var terminal_hint := _recommended_terminal_reason()
	var terminal_band := _stage_shell_focus_band("terminal")
	var terminal_signal := _terminal_signal_text()
	var terminal_action := _recommended_terminal_action_text()
	if _recommended_route_focus_kind() == "chokepoint" or _recommended_route_focus_kind() == "route_landmark":
		match terminal_band:
			"pressure":
				return "先贴终端压力链推进，再确认压迫结果和离场门。%s %s %s" % [terminal_action, terminal_hint, terminal_signal]
			"aftermath":
				return "先贴终端余波链推进，再确认余波落点和离场门。%s %s %s" % [terminal_action, terminal_hint, terminal_signal]
			"exit":
				return "先贴终端离场链推进，再确认离场门和切区条件。%s %s %s" % [terminal_action, terminal_hint, terminal_signal]
	match current_biome:
		"wetland":
			return "先读栈桥主线，再确认近水点和出口线。%s" % gate_hint
		"forest":
			return "先贴林道主线，再确认首个林下观察点。%s" % gate_hint
		"coast":
			return "先顺岸线主路，再确认远侧出口和岸侧分路。%s" % gate_hint
		_:
			return "先顺草原主道推进，再确认迁徙主线和支路口。%s" % gate_hint


func _arrival_objective_prompt() -> String:
	var terminal_band := _stage_shell_focus_band("terminal")
	var terminal_hint := _recommended_terminal_reason()
	var terminal_signal := _terminal_signal_text()
	match _recommended_route_focus_kind():
		"entry_route":
			return "落地导引 · 当前先按推荐入口链读图，确认入口主线和出口方向。"
		"trunk_route":
			return "落地导引 · 当前先按推荐主路推进，确认主干中继和下一段去向。"
		"branch_route":
			return "落地导引 · 当前先按推荐支路线吃第一个观察点，再扩观察面。"
		"chokepoint", "route_landmark":
			match terminal_band:
				"pressure":
					return "落地导引 · 当前先按推荐压力终端链盯压迫热点，再确认结果和离场门。%s %s" % [terminal_hint, terminal_signal]
				"aftermath":
					return "落地导引 · 当前先按推荐余波终端链盯余波热点，再确认离场门。%s %s" % [terminal_hint, terminal_signal]
				"exit":
					return "落地导引 · 当前先按推荐离场终端链确认离场门，再决定是否直接切区。%s %s" % [terminal_hint, terminal_signal]
				_:
					return "落地导引 · 当前先按推荐终端链盯压力/结果热点，再确认离场门。%s" % terminal_signal
		_:
			return "落地导引 · 当前先沿推荐链读清第一段空间关系。"


func _route_stage_exit_prompt() -> String:
	var exit_state := _dynamic_exit_state()
	var gate_hint := _recommended_exit_gate_reason()
	var terminal_signal := _terminal_signal_text()
	var terminal_action := _recommended_terminal_action_text()
	var focus_kind := _recommended_route_focus_kind()
	var gate_hold := smoothed_gate_focus_hold if smoothed_gate_focus_hold > 0.0 else _gate_focus_hold_strength()
	if focus_kind in ["chokepoint", "route_landmark"] or current_route_stage == "terminal":
		match _stage_shell_focus_band("terminal"):
			"pressure":
				return "锁出口后先确认压力终端链，再决定是否切区。%s %s %s %s" % [str(exit_state.get("summary", "")), gate_hint, terminal_action, terminal_signal]
			"aftermath":
				return "锁出口后先确认余波终端链，再决定是否切区。%s %s %s %s" % [str(exit_state.get("summary", "")), gate_hint, terminal_action, terminal_signal]
			"exit":
				return "锁出口后先确认离场终端链，再决定是否直接切区。%s %s %s %s" % [str(exit_state.get("summary", "")), gate_hint, terminal_action, terminal_signal]
	if gate_hold > 0.42:
		match current_biome:
			"wetland":
				return "当前已进入离场判断段，先对齐栈桥门向和出口线，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]
			"forest":
				return "当前已进入离场判断段，先对齐树门门向和主线，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]
			"coast":
				return "当前已进入离场判断段，先对齐岸线门向和出口线，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]
			_:
				return "当前已进入离场判断段，先对齐主道门向和出口线，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]
	match current_biome:
		"wetland":
			return "锁出口后先看栈桥并入口，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]
		"forest":
			return "锁出口后先看树门后主线，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]
		"coast":
			return "锁出口后先看岸线并入口，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]
		_:
			return "锁出口后先看主道并入口，再决定是否切区。%s %s" % [str(exit_state.get("summary", "")), gate_hint]


func _idle_log_prompt() -> String:
	var terminal_signal := _terminal_signal_text()
	var terminal_action := _recommended_terminal_action_text()
	var arrival_entry_prompt := _entry_screen_prompt_text(true)
	var steady_entry_prompt := _entry_screen_prompt_text(false)
	if arrival_event_focus_timer > 0.0:
		match _recommended_route_focus_kind():
			"entry_route":
				return arrival_entry_prompt if arrival_entry_prompt != "" else "继续按推荐入口链读图，先把入口主线和最近出口线确认清楚"
			"trunk_route":
				return arrival_entry_prompt if arrival_entry_prompt != "" else "继续沿推荐主路并入，先把主干推进方向和下一个中继点读清"
			"branch_route":
				return "继续贴推荐支路线推进，先把首个观察热点和相关生物吃出来"
			"chokepoint", "route_landmark":
				return "继续盯推荐终端链，先把结果段和离场门确认清楚。%s %s" % [terminal_action, terminal_signal]
	match current_route_stage:
		"entry":
			if steady_entry_prompt != "":
				return steady_entry_prompt
			match current_biome:
				"wetland":
					return "继续沿栈桥入口推进，先把近水点和出口线读清"
				"forest":
					return "继续穿过树门，先把主林道和首个林下点吃出来"
				"coast":
					return "继续沿岸入口推进，先把岸线主路和远侧出口读清"
				_:
					return "继续沿草原入口上主道，先把迁徙主线和出口方向读清"
		"branch":
			match current_biome:
				"wetland":
					return "继续贴近浅滩和栈道，优先完成近水观察"
				"forest":
					return "继续贴遮挡推进，优先完成林下观察"
				"coast":
					return "继续沿岸支路推进，优先完成岸侧观察"
				_:
					return "继续贴支路热点推进，优先完成迁徙或水源观察"
		"terminal":
			match current_biome:
				"wetland":
					return "继续盯近水终端和余波，准备切向下一个湿地区域。%s %s" % [terminal_action, terminal_signal]
				"forest":
					return "继续盯林缘终端和树门出口，准备切向下一个森林区域。%s %s" % [terminal_action, terminal_signal]
				"coast":
					return "继续盯岸侧终端和出口，准备切向下一个海岸区域。%s %s" % [terminal_action, terminal_signal]
				_:
					return "继续盯迁徙终端和追猎结果，准备切向下一个草原区域。%s %s" % [terminal_action, terminal_signal]
		_:
			match current_biome:
				"wetland":
					return "继续沿浅滩和栈道寻找下一个近水点"
				"forest":
					return "继续沿林道推进，寻找下一处林下空地"
				"coast":
					return "继续沿岸线寻找下一个岸侧热点"
				_:
					return "继续沿主道寻找下一个迁徙带或水源点"


func _prey_positions() -> Array:
	var positions: Array = []
	for animal in wildlife:
		if str(animal.get("category", "")) == "草食动物":
			positions.append(animal.get("position", Vector2.ZERO))
	return positions


func _nearest_target(origin: Vector2, targets: Array) -> Vector2:
	var nearest := Vector2.ZERO
	var nearest_distance := 999999.0
	for target in targets:
		var p := target as Vector2
		var distance := origin.distance_to(p)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = p
	if nearest_distance > 14.0:
		return Vector2.ZERO
	return nearest


func _nearest_predator_position(origin: Vector2) -> Vector2:
	var nearest := Vector2.ZERO
	var nearest_distance := 999999.0
	for animal in wildlife:
		if str(animal.get("category", "")) != "掠食者":
			continue
		var p: Vector2 = animal.get("position", Vector2.ZERO)
		var distance := origin.distance_to(p)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = p
	if nearest_distance > 12.0:
		return Vector2.ZERO
	return nearest


func _nearest_same_category_position(origin: Vector2, species_id: String, category: String) -> Vector2:
	var nearest := Vector2.ZERO
	var nearest_distance := 999999.0
	for animal in wildlife:
		if str(animal.get("species_id", "")) == species_id:
			continue
		if str(animal.get("category", "")) != category:
			continue
		var p: Vector2 = animal.get("position", Vector2.ZERO)
		var distance := origin.distance_to(p)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = p
	if nearest_distance > 3.4:
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


func _role_anchor_position(anchor_id: String, category: String, role: String) -> Vector2:
	for animal in wildlife:
		if str(animal.get("anchor_id", "")) != anchor_id:
			continue
		if str(animal.get("category", "")) != category:
			continue
		if str(animal.get("role", "")) != role:
			continue
		return Vector2(animal.get("position", Vector2.ZERO))
	return Vector2.ZERO


func _role_anchor_alert(anchor_id: String, category: String, role: String) -> bool:
	for animal in wildlife:
		if str(animal.get("anchor_id", "")) != anchor_id:
			continue
		if str(animal.get("category", "")) != category:
			continue
		if str(animal.get("role", "")) != role:
			continue
		if bool(animal.get("alerted", false)) or float(animal.get("alert_timer", 0.0)) > 0.28:
			return true
	return false


func _role_anchor_signal(anchor_id: String, category: String, role: String) -> bool:
	for animal in wildlife:
		if str(animal.get("anchor_id", "")) != anchor_id:
			continue
		if str(animal.get("category", "")) != category:
			continue
		if str(animal.get("role", "")) != role:
			continue
		if float(animal.get("signal_timer", 0.0)) > 0.08:
			return true
	return false


func _gate_forward_vector(gate_id: String) -> Vector3:
	match gate_id:
		"west_gate":
			return Vector3(-1.0, 0.0, 0.0)
		"north_gate":
			return Vector3(0.0, 0.0, -1.0)
		"east_gate":
			return Vector3(1.0, 0.0, 0.0)
		_:
			return Vector3(0.0, 0.0, -1.0)


func _signal_formation_offset(role: String, member_index: int, orbit: float) -> Vector3:
	if member_index == 0:
		match role:
			"leader":
				return Vector3(0.0, 0.04, 0.36)
			"sentry":
				return Vector3(0.0, 0.22, 0.22)
			"alpha":
				return Vector3(0.0, 0.04, 0.4)
			_:
				return Vector3.ZERO
	var rank := int((member_index + 1) / 2)
	var side := -1.0 if member_index % 2 == 0 else 1.0
	match role:
		"leader":
			return Vector3(side * (0.24 + rank * 0.18), 0.0, -0.12 - rank * 0.46)
		"sentry":
			var arc_angle := -1.1 + float(member_index - 1) * 0.48
			return Vector3(cos(arc_angle) * 1.72, 0.24 + sin(orbit * 1.8) * 0.05, 0.42 + sin(arc_angle) * 1.3)
		"alpha":
			return Vector3(side * (0.34 + rank * 0.22), 0.0, 0.02 - rank * 0.34)
		_:
			return Vector3(cos(orbit) * 0.4, 0.0, sin(orbit * 1.2) * 0.28)


func _formation_follow_slot(role: String, phase: float, radius: Vector2, signaled: bool) -> Vector2:
	match role:
		"leader":
			if signaled:
				var lane_side := -1.0 if sin(phase * 2.4) < 0.0 else 1.0
				var lane_depth: float = 1.1 + abs(cos(phase * 1.6)) * (1.8 + radius.y * 0.2)
				return Vector2(lane_side * (0.34 + radius.x * 0.04), -lane_depth)
			return Vector2(cos(phase * 1.8) * (0.8 + radius.x * 0.06), -0.7 - abs(sin(phase * 1.4)) * (1.1 + radius.y * 0.14))
		"sentry":
			if signaled:
				var arc_angle := -1.08 + phase * 0.32
				return Vector2(cos(arc_angle) * (2.5 + radius.x * 0.1), 0.62 + sin(arc_angle) * (1.9 + radius.y * 0.1))
			return Vector2(cos(phase * 0.92) * 2.1, 0.4 + sin(phase * 0.88) * 1.4)
		"alpha":
			if signaled:
				var fan_side := -1.0 if sin(phase * 2.1) < 0.0 else 1.0
				var fan_depth: float = 0.7 + abs(cos(phase * 1.7)) * (1.9 + radius.y * 0.18)
				return Vector2(fan_side * (1.12 + radius.x * 0.14), fan_depth)
			return Vector2(cos(phase * 2.1) * 1.85, 0.4 + abs(sin(phase * 1.9)) * 1.2)
		_:
			return Vector2(cos(phase) * 0.8, sin(phase * 1.2) * 0.6)


func _behavior_bias_target(animal: Dictionary, phase: float) -> Vector2:
	var behavior := str(animal.get("behavior", "graze"))
	var anchor: Vector2 = animal.get("anchor", Vector2.ZERO)
	var category := str(animal.get("category", "区域生物"))
	var objective_state := _dynamic_objective_state()
	var chase_state := _dynamic_chase_state()
	var dynamic_focus_hotspot := str(_dynamic_cluster_profile(category).get("focus_hotspot", objective_state.get("primary_hotspot", "")))
	var dynamic_focus_pos := _hotspot_pos(dynamic_focus_hotspot)
	var dynamic_focus := Vector2(dynamic_focus_pos.x, dynamic_focus_pos.z)
	var water := _hotspot_pos("waterhole")
	var migration := _hotspot_pos("migration_corridor")
	var ridge := _hotspot_pos("predator_ridge")
	var carrion := _hotspot_pos("carrion_field")
	var shade := _hotspot_pos("shade_grove")
	if behavior == "swim":
		if dynamic_focus_hotspot != "":
			return Vector2(water.x, water.z).lerp(dynamic_focus, 0.34)
		match current_biome:
			"wetland":
				return Vector2(water.x, water.z).lerp(Vector2(migration.x, migration.z), 0.24)
			"coast":
				return Vector2(water.x, water.z).lerp(Vector2(migration.x, migration.z), 0.34)
			_:
				return Vector2(water.x, water.z)
	if behavior == "glide":
		if str(chase_state.get("aftermath_hotspot", "")) != "":
			var aftermath_hotspot := _hotspot_pos(str(chase_state.get("aftermath_hotspot", "")))
			return Vector2(carrion.x, carrion.z).lerp(Vector2(aftermath_hotspot.x, aftermath_hotspot.z), 0.42)
		match current_biome:
			"wetland":
				return Vector2(carrion.x, carrion.z).lerp(Vector2(water.x, water.z), 0.38)
			"forest":
				return Vector2(carrion.x, carrion.z).lerp(Vector2(shade.x, shade.z), 0.34)
			"coast":
				return Vector2(carrion.x, carrion.z).lerp(Vector2(migration.x, migration.z), 0.42)
			_:
				return Vector2(carrion.x, carrion.z).lerp(Vector2(ridge.x, ridge.z), 0.4)
	if behavior == "heavy_roam":
		var mix := 0.5 + 0.5 * sin(elapsed_time() * 0.18 + phase)
		if dynamic_focus_hotspot != "":
			return Vector2(water.x, water.z).lerp(dynamic_focus, 0.52 + mix * 0.18).lerp(anchor, 0.18)
		match current_biome:
			"wetland":
				return Vector2(water.x, water.z).lerp(Vector2(migration.x, migration.z), mix * 0.42)
			"forest":
				return Vector2(shade.x, shade.z).lerp(Vector2(water.x, water.z), mix)
			"coast":
				return Vector2(water.x, water.z).lerp(Vector2(migration.x, migration.z), mix * 0.72)
			_:
				return Vector2(water.x, water.z).lerp(Vector2(shade.x, shade.z), mix)
	if behavior == "stalk":
		if str(chase_state.get("pressure_hotspot", "")) != "":
			var pressure_hotspot := _hotspot_pos(str(chase_state.get("pressure_hotspot", "")))
			return Vector2(ridge.x, ridge.z).lerp(Vector2(pressure_hotspot.x, pressure_hotspot.z), 0.46)
		match current_biome:
			"wetland":
				return Vector2(ridge.x, ridge.z).lerp(Vector2(carrion.x, carrion.z), 0.36)
			"forest":
				return Vector2(ridge.x, ridge.z).lerp(Vector2(shade.x, shade.z), 0.42)
			"coast":
				return Vector2(ridge.x, ridge.z).lerp(Vector2(migration.x, migration.z), 0.5)
			_:
				return Vector2(ridge.x, ridge.z).lerp(Vector2(migration.x, migration.z), 0.45)
	var weight := 0.5 + 0.24 * sin(elapsed_time() * 0.14 + phase)
	if dynamic_focus_hotspot != "":
		return dynamic_focus.lerp(anchor, 0.24 + weight * 0.18)
	match current_biome:
		"wetland":
			return Vector2(water.x, water.z).lerp(Vector2(migration.x, migration.z), weight * 0.78).lerp(anchor, 0.18)
		"forest":
			return Vector2(shade.x, shade.z).lerp(Vector2(water.x, water.z), weight).lerp(anchor, 0.28)
		"coast":
			return Vector2(migration.x, migration.z).lerp(Vector2(water.x, water.z), weight * 0.84).lerp(anchor, 0.2)
		_:
			return Vector2(migration.x, migration.z).lerp(Vector2(water.x, water.z), weight).lerp(anchor, 0.24)


func _biome_herd_route_focus() -> Vector2:
	var chase_state := _dynamic_chase_state()
	var migration := _hotspot_pos("migration_corridor")
	var water := _hotspot_pos("waterhole")
	var shade := _hotspot_pos("shade_grove")
	var dynamic_target := str(chase_state.get("migration_hotspot", ""))
	if dynamic_target != "":
		var target_pos := _hotspot_pos(dynamic_target)
		return Vector2(target_pos.x, target_pos.z)
	match current_biome:
		"wetland":
			return Vector2(water.x, water.z).lerp(Vector2(migration.x, migration.z), 0.64)
		"forest":
			return Vector2(shade.x, shade.z).lerp(Vector2(migration.x, migration.z), 0.42)
		"coast":
			return Vector2(water.x, water.z).lerp(Vector2(migration.x, migration.z), 0.78)
		_:
			return Vector2(migration.x, migration.z)


func _biome_sentry_watch_focus() -> Vector2:
	var chase_state := _dynamic_chase_state()
	var ridge := _hotspot_pos("predator_ridge")
	var water := _hotspot_pos("waterhole")
	var carrion := _hotspot_pos("carrion_field")
	var dynamic_target := str(chase_state.get("pressure_hotspot", ""))
	if dynamic_target != "":
		var target_pos := _hotspot_pos(dynamic_target)
		return Vector2(target_pos.x, target_pos.z)
	match current_biome:
		"wetland":
			return Vector2(water.x, water.z).lerp(Vector2(ridge.x, ridge.z), 0.24)
		"forest":
			return Vector2(ridge.x, ridge.z).lerp(Vector2(carrion.x, carrion.z), 0.18)
		"coast":
			return Vector2(ridge.x, ridge.z).lerp(Vector2(water.x, water.z), 0.28)
		_:
			return Vector2(ridge.x, ridge.z)


func _biome_glide_aftermath_focus() -> Vector2:
	var carrion := _hotspot_pos("carrion_field")
	var water := _hotspot_pos("waterhole")
	var migration := _hotspot_pos("migration_corridor")
	var shade := _hotspot_pos("shade_grove")
	match current_biome:
		"wetland":
			return Vector2(carrion.x, carrion.z).lerp(Vector2(water.x, water.z), 0.36)
		"forest":
			return Vector2(carrion.x, carrion.z).lerp(Vector2(shade.x, shade.z), 0.32)
		"coast":
			return Vector2(carrion.x, carrion.z).lerp(Vector2(migration.x, migration.z), 0.38)
		_:
			return Vector2(carrion.x, carrion.z)


func _biome_predator_aftermath_focus() -> Vector2:
	var carrion := _hotspot_pos("carrion_field")
	var ridge := _hotspot_pos("predator_ridge")
	var shade := _hotspot_pos("shade_grove")
	match current_biome:
		"wetland":
			return Vector2(carrion.x, carrion.z).lerp(Vector2(ridge.x, ridge.z), 0.28)
		"forest":
			return Vector2(carrion.x, carrion.z).lerp(Vector2(shade.x, shade.z), 0.24)
		"coast":
			return Vector2(carrion.x, carrion.z).lerp(Vector2(ridge.x, ridge.z), 0.4)
		_:
			return Vector2(carrion.x, carrion.z)


func _biome_chase_chain_profile() -> Dictionary:
	match current_biome:
		"wetland":
			return {
				"pressure_distance": 8.8,
				"hit_distance": 1.02,
				"burst_distance": 3.0,
				"burst_timeout": 3.4,
				"aftermath_duration": 4.9,
				"herd_pull_scale": 1.14,
				"glide_pull_scale": 0.94,
				"predator_pull_scale": 0.9,
				"alpha_push_scale": 0.92,
				"stalk_site_scale": 0.88,
				"glide_site_scale": 0.84,
				"stalk_player_radius": 7.2,
				"glide_pressure_radius": 11.2,
				"chase_score_scale": 1.08,
				"graze_player_radius": 6.2,
				"swim_player_radius": 7.2,
				"heavy_player_radius": 7.6,
				"herd_signal_scale": 0.96,
				"sentry_signal_scale": 1.14,
				"regroup_scale": 0.94,
				"flee_scale": 0.88,
			}
		"forest":
			return {
				"pressure_distance": 7.1,
				"hit_distance": 0.94,
				"burst_distance": 2.6,
				"burst_timeout": 2.7,
				"aftermath_duration": 4.5,
				"herd_pull_scale": 1.2,
				"glide_pull_scale": 0.88,
				"predator_pull_scale": 0.98,
				"alpha_push_scale": 1.06,
				"stalk_site_scale": 1.16,
				"glide_site_scale": 0.78,
				"stalk_player_radius": 6.8,
				"glide_pressure_radius": 8.8,
				"chase_score_scale": 1.14,
				"graze_player_radius": 5.2,
				"swim_player_radius": 5.8,
				"heavy_player_radius": 6.0,
				"herd_signal_scale": 1.18,
				"sentry_signal_scale": 0.92,
				"regroup_scale": 1.12,
				"flee_scale": 1.06,
			}
		"coast":
			return {
				"pressure_distance": 8.1,
				"hit_distance": 1.08,
				"burst_distance": 3.2,
				"burst_timeout": 3.2,
				"aftermath_duration": 4.7,
				"herd_pull_scale": 0.96,
				"glide_pull_scale": 1.22,
				"predator_pull_scale": 1.04,
				"alpha_push_scale": 0.98,
				"stalk_site_scale": 0.9,
				"glide_site_scale": 1.18,
				"stalk_player_radius": 7.6,
				"glide_pressure_radius": 12.6,
				"chase_score_scale": 0.96,
				"graze_player_radius": 6.8,
				"swim_player_radius": 7.4,
				"heavy_player_radius": 7.0,
				"herd_signal_scale": 0.9,
				"sentry_signal_scale": 1.22,
				"regroup_scale": 0.9,
				"flee_scale": 0.94,
			}
		_:
			return {
				"pressure_distance": 8.6,
				"hit_distance": 1.18,
				"burst_distance": 3.6,
				"burst_timeout": 3.0,
				"aftermath_duration": 4.2,
				"herd_pull_scale": 1.04,
				"glide_pull_scale": 1.0,
				"predator_pull_scale": 1.12,
				"alpha_push_scale": 1.12,
				"stalk_site_scale": 1.02,
				"glide_site_scale": 0.94,
				"stalk_player_radius": 8.4,
				"glide_pressure_radius": 10.4,
				"chase_score_scale": 1.02,
				"graze_player_radius": 7.2,
				"swim_player_radius": 6.6,
				"heavy_player_radius": 7.4,
				"herd_signal_scale": 1.1,
				"sentry_signal_scale": 0.98,
				"regroup_scale": 1.0,
				"flee_scale": 1.12,
			}


func _biome_pressure_text(predator_label: String) -> Dictionary:
	match current_biome:
		"wetland":
			return {
				"title": "浅滩压迫",
				"body": "%s 正把草食群压向浅滩与栈道，近水群落正在被迫改线。" % predator_label,
			}
		"forest":
			return {
				"title": "林缘压迫",
				"body": "%s 正把草食群逼向林门与林道，遮挡后的队形正在重排。" % predator_label,
			}
		"coast":
			return {
				"title": "岸线压迫",
				"body": "%s 正把草食群压向岸侧导流口，沿岸队形正在被迫拉开。" % predator_label,
			}
		_:
			return {
				"title": "追逐压力",
				"body": "%s 正在压迫草食群，开阔带上的群体正在被迫改线。" % predator_label,
			}


func _biome_hotspot_spotlight_profile() -> Dictionary:
	match current_biome:
		"wetland":
			return {
				"focus_scale": 1.12,
				"reveal_scale": 1.08,
				"active_scale": 1.08,
				"task_scale": 1.16,
				"beacon_scale": 1.12,
			}
		"forest":
			return {
				"focus_scale": 0.9,
				"reveal_scale": 0.84,
				"active_scale": 1.14,
				"task_scale": 1.22,
				"beacon_scale": 0.94,
			}
		"coast":
			return {
				"focus_scale": 1.04,
				"reveal_scale": 1.16,
				"active_scale": 1.04,
				"task_scale": 1.08,
				"beacon_scale": 1.2,
			}
		_:
			return {
				"focus_scale": 1.02,
				"reveal_scale": 1.0,
				"active_scale": 1.12,
				"task_scale": 1.1,
				"beacon_scale": 1.04,
			}


func _has_nearby_category(category: String, center: Vector2, radius: float) -> bool:
	for animal in wildlife:
		if str(animal.get("category", "")) != category:
			continue
		if center.distance_to(animal.get("position", Vector2.ZERO)) <= radius:
			return true
	return false


func _record_species_discovery(animal: Dictionary) -> void:
	var species_id := str(animal.get("species_id", ""))
	if species_id == "" or discovered_species_ids.has(species_id):
		return
	discovered_species_ids[species_id] = true
	discovery_log.push_front(_route_stage_log_entry("species", str(animal.get("label", species_id))))
	discovery_log = discovery_log.slice(0, 10)


func _record_hotspot_discovery(hotspot: Dictionary) -> void:
	var hotspot_id := str(hotspot.get("hotspot_id", ""))
	if hotspot_id == "" or discovered_hotspot_ids.has(hotspot_id):
		return
	discovered_hotspot_ids[hotspot_id] = true
	discovery_log.push_front(_route_stage_log_entry("hotspot", str(hotspot.get("label", hotspot_id))))
	discovery_log = discovery_log.slice(0, 10)


func _add_floor_collider(pos: Vector3, size: Vector3) -> void:
	_add_static_collider(pos, size)


func _add_static_collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	body.add_child(collider)
	environment_root.add_child(body)


func _add_route_segment(a: Vector3, b: Vector3, color: Color) -> void:
	var diff := b - a
	var length := diff.length()
	var root := Node3D.new()
	root.position = (a + b) * 0.5
	root.rotation.y = atan2(diff.x, diff.z)
	environment_root.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.2, 0.08, length)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.04, 0.0)
	mesh_instance.material_override = _material(color)
	root.add_child(mesh_instance)
	for side in [-1.0, 1.0]:
		var edge := MeshInstance3D.new()
		var edge_mesh := BoxMesh.new()
		edge_mesh.size = Vector3(0.12, 0.12, length)
		edge.mesh = edge_mesh
		edge.position = Vector3(side * 0.68, 0.08, 0.0)
		edge.material_override = _material(color.darkened(0.22), 0.7)
		root.add_child(edge)
	for post_index in range(max(1, int(length / 6.8))):
		var route_post := _box_mesh(Vector3(0.08, 0.46, 0.08), Color8(110, 88, 60))
		route_post.position = Vector3(0.0, 0.24, -length * 0.5 + 2.2 + post_index * 5.0)
		root.add_child(route_post)
		var route_cap := _box_mesh(Vector3(0.16, 0.08, 0.16), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.04))
		route_cap.position = route_post.position + Vector3(0.0, 0.3, 0.0)
		root.add_child(route_cap)
	match current_biome:
		"wetland":
			for plank_index in range(max(3, int(length / 2.0))):
				var plank := _box_mesh(Vector3(1.02, 0.02, 0.12), color.lightened(0.12))
				plank.position = Vector3(0.0, 0.05, -length * 0.5 + 0.54 + plank_index * 1.08)
				root.add_child(plank)
			for side in [-1.0, 1.0]:
				var rail := _box_mesh(Vector3(0.08, 0.16, length * 0.82), color.darkened(0.18))
				rail.position = Vector3(side * 0.86, 0.1, 0.0)
				root.add_child(rail)
		"forest":
			for side in [-1.0, 1.0]:
				var root_wall := _box_mesh(Vector3(0.1, 0.14, length * 0.78), color.darkened(0.22))
				root_wall.position = Vector3(side * 0.78, 0.08, 0.0)
				root_wall.rotation_degrees = Vector3(0.0, 0.0, side * 5.0)
				root.add_child(root_wall)
			for node_index in range(max(2, int(length / 6.2))):
				var lantern := _box_mesh(Vector3(0.14, 0.14, 0.14), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.12))
				lantern.position = Vector3(0.0, 0.16, -length * 0.5 + 1.8 + node_index * 4.4)
				root.add_child(lantern)
		"coast":
			for side in [-1.0, 1.0]:
				var dune_bank := _box_mesh(Vector3(0.14, 0.14, length * 0.8), color.darkened(0.18))
				dune_bank.position = Vector3(side * 0.82, 0.08, 0.0)
				root.add_child(dune_bank)
			for rib_index in range(max(2, int(length / 5.0))):
				var rib := _box_mesh(Vector3(0.92, 0.02, 0.08), current_theme.get("accent", Color8(236, 202, 118)).lightened(0.08))
				rib.position = Vector3(0.0, 0.05, -length * 0.5 + 1.0 + rib_index * 3.0)
				root.add_child(rib)
		_:
			for side in [-1.0, 1.0]:
				var stone_curb := _box_mesh(Vector3(0.12, 0.12, length * 0.78), color.darkened(0.16))
				stone_curb.position = Vector3(side * 0.8, 0.08, 0.0)
				root.add_child(stone_curb)
			for totem_index in range(max(2, int(length / 6.2))):
				var totem := _box_mesh(Vector3(0.1, 0.68, 0.1), Color8(128, 102, 68))
				totem.position = Vector3(0.0, 0.34, -length * 0.5 + 1.8 + totem_index * 5.8)
				root.add_child(totem)
	_register_route_stage_visual(root, "trunk_route", 1.08)


func _add_route_connector(a: Vector3, b: Vector3, color: Color) -> void:
	var diff := b - a
	var length := diff.length()
	var root := Node3D.new()
	root.position = (a + b) * 0.5
	root.rotation.y = atan2(diff.x, diff.z)
	environment_root.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.64, 0.06, length)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.03, 0.0)
	mesh_instance.material_override = _material(color, 0.92)
	root.add_child(mesh_instance)
	for side in [-1.0, 1.0]:
		var shoulder := _box_mesh(Vector3(0.08, 0.08, length), color.darkened(0.18))
		shoulder.position = Vector3(side * 0.46, 0.04, 0.0)
		root.add_child(shoulder)
	for dash_index in range(max(2, int(length / 3.8))):
		var dash := _box_mesh(Vector3(0.16, 0.04, 0.42), color.lightened(0.14))
		dash.position = Vector3(0.0, 0.05, -length * 0.5 + 0.8 + dash_index * 2.4)
		root.add_child(dash)
		if dash_index < max(2, int(length / 3.8)) - 1:
			for side in [-1.0, 1.0]:
				var post := _box_mesh(Vector3(0.06, 0.32, 0.06), Color8(108, 84, 58))
				post.position = Vector3(side * 0.58, 0.16, dash.position.z + 0.22)
				root.add_child(post)
	var midpoint_plate := _box_mesh(Vector3(0.54, 0.08, 0.24), color.lightened(0.18))
	midpoint_plate.position = Vector3(0.0, 0.07, 0.0)
	root.add_child(midpoint_plate)
	for direction in [-1.0, 1.0]:
		var end_pad := _box_mesh(Vector3(0.92, 0.04, 0.88), color.darkened(0.06))
		end_pad.position = Vector3(0.0, 0.02, direction * (length * 0.5 - 0.56))
		root.add_child(end_pad)
	match current_biome:
		"wetland":
			for step in range(max(2, int(length / 2.6))):
				var connector_plank := _box_mesh(Vector3(0.54, 0.02, 0.12), color.lightened(0.16))
				connector_plank.position = Vector3(0.0, 0.04, -length * 0.5 + 0.6 + step * 1.4)
				root.add_child(connector_plank)
		"forest":
			for side in [-1.0, 1.0]:
				var connector_root := _box_mesh(Vector3(0.08, 0.08, length * 0.76), color.darkened(0.2))
				connector_root.position = Vector3(side * 0.36, 0.04, 0.0)
				root.add_child(connector_root)
		"coast":
			for side in [-1.0, 1.0]:
				var connector_bank := _box_mesh(Vector3(0.1, 0.1, length * 0.72), color.darkened(0.16))
				connector_bank.position = Vector3(side * 0.38, 0.06, 0.0)
				root.add_child(connector_bank)
		_:
			for step in range(max(2, int(length / 4.4))):
				var connector_stone := _box_mesh(Vector3(0.2, 0.06, 0.2), color.lightened(0.12))
				connector_stone.position = Vector3(0.0, 0.05, -length * 0.5 + 0.8 + step * 2.6)
				root.add_child(connector_stone)
	_register_route_stage_visual(root, "connector", 0.94)


func _add_route_landmark(pos: Vector3) -> void:
	var scale := lerpf(1.0, _world_spread_scale(), 0.9)
	var root := Node3D.new()
	root.position = pos + Vector3(0.0, 0.0, 0.0)
	root.scale = Vector3.ONE * scale
	environment_root.add_child(root)
	var pad := MeshInstance3D.new()
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(2.0, 0.06, 1.4)
	pad.mesh = pad_mesh
	pad.position = Vector3(0.0, 0.03, 0.0)
	pad.material_override = _material(current_theme.get("route", Color8(240, 223, 176)).darkened(0.08), 0.68)
	root.add_child(pad)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(0.34, 2.1, 0.34)
	sign.mesh = sign_mesh
	sign.position = Vector3(0.0, 1.05, 0.0)
	sign.material_override = _material(Color8(114, 84, 52))
	root.add_child(sign)
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(1.72, 0.84, 0.16)
	plate.mesh = plate_mesh
	plate.position = Vector3(0.0, 2.04, 0.0)
	plate.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)))
	root.add_child(plate)
	for side in [-1.0, 1.0]:
		var side_post := _box_mesh(Vector3(0.1, 0.56, 0.1), Color8(114, 84, 52))
		side_post.position = Vector3(side * 0.62, 0.28, 0.18)
		root.add_child(side_post)
	_register_route_stage_visual(root, "route_landmark", 1.12)


func _register_route_stage_visual(root: Node3D, kind: String, prominence: float = 1.0) -> void:
	route_stage_visuals.append({
		"root": root,
		"kind": kind,
		"base_pos": root.position,
		"prominence": prominence,
	})


func _add_exit_arch(pos: Vector3) -> void:
	var scale := _world_spread_scale()
	var root := Node3D.new()
	root.position = pos
	exit_root.add_child(root)
	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var pillar_mesh := BoxMesh.new()
		pillar_mesh.size = Vector3(0.5 * scale, 3.2, 0.5 * scale)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(side * 1.18 * scale, 1.6, 0.0)
		pillar.material_override = _material(Color8(122, 94, 62))
		root.add_child(pillar)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(3.0 * scale, 0.48, 0.5 * scale)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, 3.08, 0.0)
	lintel.material_override = _material(Color8(224, 210, 166))
	root.add_child(lintel)
	var banner := MeshInstance3D.new()
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(2.0 * scale, 1.04, 0.08)
	banner.mesh = banner_mesh
	banner.position = Vector3(0.0, 2.26, -0.18)
	banner.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)))
	root.add_child(banner)
	for side in [-1.0, 1.0]:
		var torch := MeshInstance3D.new()
		var torch_mesh := SphereMesh.new()
		torch_mesh.radius = 0.12
		torch_mesh.height = 0.24
		torch.mesh = torch_mesh
		torch.position = Vector3(side * 1.08 * scale, 2.48, -0.2 * scale)
		torch.material_override = _material(Color8(246, 198, 112))
		root.add_child(torch)


func _add_hotspot_landmark(hotspot_id: String, pos: Vector3, parent: Node3D) -> Node3D:
	var scale := lerpf(1.0, _world_spread_scale(), 0.84)
	var landmark: Node3D = null
	match hotspot_id:
		"waterhole":
			landmark = _add_waterhole_landmark(pos, parent)
		"migration_corridor":
			landmark = _add_corridor_landmark(pos, parent)
		"predator_ridge":
			landmark = _add_ridge_landmark(pos, parent)
		"carrion_field":
			landmark = _add_carrion_landmark(pos, parent)
		"shade_grove":
			landmark = _add_grove_landmark(pos, parent)
	if landmark != null:
		landmark.position += _hotspot_landmark_offset(hotspot_id)
		landmark.scale = Vector3.ONE * scale
	return landmark


func _hotspot_landmark_offset(hotspot_id: String) -> Vector3:
	var spread_scale := lerpf(1.0, _world_spread_scale(), 0.44)
	match hotspot_id:
		"waterhole":
			return Vector3(-2.2, 0.0, 1.6) * REGION_DISTANCE_SCALE * spread_scale
		"migration_corridor":
			return Vector3(0.0, 0.0, 2.4) * REGION_DISTANCE_SCALE * spread_scale
		"predator_ridge":
			return Vector3(2.0, 0.0, -1.8) * REGION_DISTANCE_SCALE * spread_scale
		"carrion_field":
			return Vector3(-1.8, 0.0, -2.0) * REGION_DISTANCE_SCALE * spread_scale
		"shade_grove":
			return Vector3(1.6, 0.0, 1.8) * REGION_DISTANCE_SCALE * spread_scale
		_:
			return Vector3.ZERO


func _add_waterhole_landmark(pos: Vector3, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	for offset in [Vector3(-1.6, 0.0, -1.2), Vector3(1.4, 0.0, -1.0), Vector3(-1.2, 0.0, 1.4), Vector3(1.6, 0.0, 1.2)]:
		var stone := _box_mesh(Vector3(0.8, 0.34, 0.7), Color8(166, 154, 128))
		stone.position = offset + Vector3(0.0, 0.16, 0.0)
		root.add_child(stone)
	if current_biome in ["wetland", "coast"]:
		_add_reed_cluster(pos + Vector3(-2.0, 0.0, 0.8))
		_add_reed_cluster(pos + Vector3(1.8, 0.0, -0.6))
	match current_biome:
		"wetland":
			var marsh_deck := _box_mesh(Vector3(2.2, 0.04, 0.72), Color8(174, 166, 132))
			marsh_deck.position = Vector3(0.0, 0.03, 1.72)
			root.add_child(marsh_deck)
		"forest":
			var forest_bank := _box_mesh(Vector3(2.0, 0.08, 0.4), Color8(116, 102, 74))
			forest_bank.position = Vector3(0.0, 0.06, -1.62)
			root.add_child(forest_bank)
		"coast":
			var shore_deck := _box_mesh(Vector3(2.4, 0.04, 0.64), Color8(220, 208, 172))
			shore_deck.position = Vector3(0.0, 0.03, 1.84)
			root.add_child(shore_deck)
		_:
			var savanna_ring := _box_mesh(Vector3(2.2, 0.04, 0.34), Color8(170, 148, 104))
			savanna_ring.position = Vector3(0.0, 0.03, -1.74)
			root.add_child(savanna_ring)
	return root


func _add_corridor_landmark(pos: Vector3, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	for side in [-1.0, 1.0]:
		var flag_root := Node3D.new()
		flag_root.position = Vector3(side * 1.2, 0.0, 0.0)
		root.add_child(flag_root)
		var pole := MeshInstance3D.new()
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.06
		pole_mesh.bottom_radius = 0.08
		pole_mesh.height = 2.0
		pole.mesh = pole_mesh
		pole.position = Vector3(0.0, 1.0, 0.0)
		pole.material_override = _material(Color8(118, 92, 62))
		flag_root.add_child(pole)
		var flag := MeshInstance3D.new()
		var flag_mesh := BoxMesh.new()
		flag_mesh.size = Vector3(0.84, 0.46, 0.05)
		flag.mesh = flag_mesh
		flag.position = Vector3(side * 0.36, 1.68, 0.0)
		flag.material_override = _material(current_theme.get("accent", Color8(236, 202, 118)))
		flag_root.add_child(flag)
	match current_biome:
		"wetland":
			var boardwalk := _box_mesh(Vector3(1.2, 0.04, 1.8), Color8(182, 172, 138))
			boardwalk.position = Vector3(0.0, 0.03, 0.0)
			root.add_child(boardwalk)
		"forest":
			var root_gate := _box_mesh(Vector3(1.48, 0.08, 0.16), Color8(104, 90, 68))
			root_gate.position = Vector3(0.0, 1.04, 0.0)
			root.add_child(root_gate)
		"coast":
			var dune_marker := _box_mesh(Vector3(1.4, 0.04, 1.2), Color8(228, 216, 182))
			dune_marker.position = Vector3(0.0, 0.03, 0.0)
			root.add_child(dune_marker)
		_:
			var stone_lane := _box_mesh(Vector3(1.24, 0.04, 1.44), Color8(176, 156, 110))
			stone_lane.position = Vector3(0.0, 0.03, 0.0)
			root.add_child(stone_lane)
	return root


func _add_ridge_landmark(pos: Vector3, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	for offset in [Vector3(-1.2, 0.0, 0.0), Vector3(0.0, 0.0, -0.8), Vector3(1.2, 0.0, 0.2)]:
		var cairn := _box_mesh(Vector3(0.9, 0.42, 0.9), Color8(136, 118, 86))
		cairn.position = offset + Vector3(0.0, 0.2, 0.0)
		root.add_child(cairn)
	var lookout := _box_mesh(Vector3(1.4, 0.18, 1.1), Color8(186, 170, 128))
	lookout.position = Vector3(0.0, 0.86, 0.0)
	root.add_child(lookout)
	match current_biome:
		"wetland":
			var wet_watch := _box_mesh(Vector3(1.2, 0.08, 0.42), Color8(164, 152, 116))
			wet_watch.position = Vector3(0.0, 0.98, 0.84)
			root.add_child(wet_watch)
		"forest":
			var forest_perch := _box_mesh(Vector3(1.0, 0.08, 0.34), Color8(122, 108, 82))
			forest_perch.position = Vector3(0.0, 1.04, 0.72)
			root.add_child(forest_perch)
		"coast":
			var coast_perch := _box_mesh(Vector3(1.2, 0.08, 0.36), Color8(198, 188, 152))
			coast_perch.position = Vector3(0.0, 1.0, 0.78)
			root.add_child(coast_perch)
		_:
			var ridge_banner := _box_mesh(Vector3(0.86, 0.12, 0.08), Color8(196, 178, 126))
			ridge_banner.position = Vector3(0.0, 1.26, 0.0)
			root.add_child(ridge_banner)
	return root


func _add_carrion_landmark(pos: Vector3, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	for offset in [Vector3(-0.8, 0.0, -0.2), Vector3(0.6, 0.0, 0.4)]:
		var bone := _box_mesh(Vector3(0.86, 0.1, 0.18), Color8(236, 226, 196))
		bone.position = offset + Vector3(0.0, 0.08, 0.0)
		bone.rotation_degrees = Vector3(0.0, 25.0 if offset.x < 0.0 else -20.0, 0.0)
		root.add_child(bone)
	var marker := _box_mesh(Vector3(0.5, 0.5, 0.5), Color8(126, 76, 64))
	marker.position = Vector3(0.0, 0.24, 0.0)
	root.add_child(marker)
	match current_biome:
		"wetland":
			var marsh_ring := _box_mesh(Vector3(1.26, 0.03, 1.0), Color8(122, 94, 78))
			marsh_ring.position = Vector3(0.0, 0.02, 0.0)
			root.add_child(marsh_ring)
		"forest":
			var forest_circle := _box_mesh(Vector3(1.12, 0.03, 0.9), Color8(108, 82, 68))
			forest_circle.position = Vector3(0.0, 0.02, 0.0)
			root.add_child(forest_circle)
		"coast":
			var coast_circle := _box_mesh(Vector3(1.34, 0.03, 1.06), Color8(148, 120, 96))
			coast_circle.position = Vector3(0.0, 0.02, 0.0)
			root.add_child(coast_circle)
		_:
			var savanna_circle := _box_mesh(Vector3(1.28, 0.03, 0.96), Color8(132, 94, 74))
			savanna_circle.position = Vector3(0.0, 0.02, 0.0)
			root.add_child(savanna_circle)
	return root


func _add_grove_landmark(pos: Vector3, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var bench := _box_mesh(Vector3(1.6, 0.18, 0.6), Color8(138, 98, 62))
	bench.position = Vector3(0.0, 0.24, 0.0)
	root.add_child(bench)
	_add_tree(pos + Vector3(-1.4, 0.0, -1.0), false)
	_add_tree(pos + Vector3(1.4, 0.0, 0.8), false)
	return root


func _add_tree(pos: Vector3, palm: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	var variation := _foliage_variation(pos)
	root.rotation.y = variation * 0.6
	environment_root.add_child(root)
	_add_undergrowth_cluster(pos, 0.92 + variation * 0.18, palm)
	_add_grass_tuft_patch(pos, 1.08 + variation * 0.2, palm)
	var base_ring := MeshInstance3D.new()
	var base_ring_mesh := CylinderMesh.new()
	base_ring_mesh.top_radius = 0.28 + variation * 0.08
	base_ring_mesh.bottom_radius = 0.42 + variation * 0.1
	base_ring_mesh.height = 0.08
	base_ring.mesh = base_ring_mesh
	base_ring.position = Vector3(0.0, 0.04, 0.0)
	base_ring.material_override = _material(Color8(118, 96, 66), 0.9)
	root.add_child(base_ring)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16 + variation * 0.02
	trunk_mesh.bottom_radius = 0.22 + variation * 0.03
	trunk_mesh.height = 2.1 + variation * 0.7
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0.0, trunk_mesh.height * 0.5, 0.0)
	trunk.material_override = _material(Color8(102, 74, 48))
	root.add_child(trunk)
	for side in [-1.0, 1.0]:
		var root_flare := MeshInstance3D.new()
		var root_flare_mesh := BoxMesh.new()
		root_flare_mesh.size = Vector3(0.16, 0.06, 0.54 + variation * 0.12)
		root_flare.mesh = root_flare_mesh
		root_flare.position = Vector3(side * (0.18 + variation * 0.04), 0.05, 0.06 * side)
		root_flare.rotation_degrees = Vector3(0.0, side * (18.0 + variation * 8.0), 0.0)
		root_flare.material_override = _material(Color8(96, 72, 46))
		root.add_child(root_flare)
	if palm:
		for ring_index in range(4):
			var trunk_band := MeshInstance3D.new()
			var trunk_band_mesh := CylinderMesh.new()
			trunk_band_mesh.top_radius = trunk_mesh.top_radius + 0.006
			trunk_band_mesh.bottom_radius = trunk_mesh.bottom_radius - 0.01
			trunk_band_mesh.height = 0.08
			trunk_band.mesh = trunk_band_mesh
			trunk_band.position = Vector3(0.0, 0.42 + ring_index * 0.46 + variation * 0.06, 0.0)
			trunk_band.material_override = _material(Color8(138, 110, 74), 0.82)
			root.add_child(trunk_band)
		for angle in [-1.05, -0.45, -0.05, 0.32, 0.82]:
			var frond := MeshInstance3D.new()
			var frond_mesh := BoxMesh.new()
			frond_mesh.size = Vector3(0.12, 0.04, 1.8 + variation * 0.4)
			frond.mesh = frond_mesh
			frond.position = Vector3(cos(angle) * (0.56 + variation * 0.08), trunk_mesh.height, sin(angle) * (0.56 + variation * 0.08))
			frond.rotation = Vector3(deg_to_rad(-46 - variation * 6.0), angle + variation * 0.08, 0.0)
			frond.material_override = _material(current_theme.get("foliage", Color8(96, 132, 74)))
			root.add_child(frond)
			var frond_tip := MeshInstance3D.new()
			var frond_tip_mesh := BoxMesh.new()
			frond_tip_mesh.size = Vector3(0.1, 0.03, 0.82 + variation * 0.18)
			frond_tip.mesh = frond_tip_mesh
			frond_tip.position = frond.position + Vector3(cos(angle) * (0.72 + variation * 0.1), -0.12, sin(angle) * (0.72 + variation * 0.1))
			frond_tip.rotation = Vector3(deg_to_rad(-58 - variation * 6.0), angle + variation * 0.08, 0.0)
			frond_tip.material_override = _material(current_theme.get("foliage", Color8(104, 144, 82)).lightened(0.04))
			root.add_child(frond_tip)
		var palm_shadow := MeshInstance3D.new()
		var palm_shadow_mesh := CylinderMesh.new()
		palm_shadow_mesh.top_radius = 0.92 + variation * 0.16
		palm_shadow_mesh.bottom_radius = 1.18 + variation * 0.18
		palm_shadow_mesh.height = 0.08
		palm_shadow.mesh = palm_shadow_mesh
		palm_shadow.position = Vector3(0.0, 0.04, 0.0)
		palm_shadow.material_override = _material(current_theme.get("ground", Color8(190, 168, 104)).darkened(0.22), 0.22)
		root.add_child(palm_shadow)
	else:
		for branch_dir in [-1.0, 1.0]:
			var branch := MeshInstance3D.new()
			var branch_mesh := CylinderMesh.new()
			branch_mesh.top_radius = 0.05
			branch_mesh.bottom_radius = 0.08
			branch_mesh.height = 0.82 + variation * 0.18
			branch.mesh = branch_mesh
			branch.position = Vector3(branch_dir * (0.12 + variation * 0.02), trunk_mesh.height * (0.64 + variation * 0.04), 0.08 * branch_dir)
			branch.rotation_degrees = Vector3(24.0 + variation * 10.0, 0.0, branch_dir * (48.0 + variation * 12.0))
			branch.material_override = _material(Color8(96, 72, 46))
			root.add_child(branch)
		for crown_offset in [
			Vector3(0.0, trunk_mesh.height + 0.28, 0.0),
			Vector3(-0.42, trunk_mesh.height + 0.12, 0.18),
			Vector3(0.38, trunk_mesh.height + 0.06, -0.14),
			Vector3(0.12, trunk_mesh.height + 0.38, 0.26),
			Vector3(-0.22, trunk_mesh.height + 0.3, -0.24),
		]:
			var crown := MeshInstance3D.new()
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 0.74 + variation * 0.22
			crown_mesh.height = 1.42 + variation * 0.3
			crown.mesh = crown_mesh
			crown.position = crown_offset
			crown.material_override = _material(current_theme.get("foliage", Color8(96, 132, 74)).lightened(variation * 0.04))
			root.add_child(crown)
		var crown_shadow := MeshInstance3D.new()
		var crown_shadow_mesh := CylinderMesh.new()
		crown_shadow_mesh.top_radius = 0.96 + variation * 0.22
		crown_shadow_mesh.bottom_radius = 1.16 + variation * 0.22
		crown_shadow_mesh.height = 0.12
		crown_shadow.mesh = crown_shadow_mesh
		crown_shadow.position = Vector3(0.0, trunk_mesh.height * 0.78, 0.0)
		crown_shadow.material_override = _material(current_theme.get("ground", Color8(190, 168, 104)).darkened(0.18), 0.28)
		root.add_child(crown_shadow)
		for side in [-1.0, 1.0]:
			var lower_crown := MeshInstance3D.new()
			var lower_crown_mesh := SphereMesh.new()
			lower_crown_mesh.radius = 0.32 + variation * 0.08
			lower_crown_mesh.height = 0.64 + variation * 0.12
			lower_crown.mesh = lower_crown_mesh
			lower_crown.position = Vector3(side * (0.52 + variation * 0.08), trunk_mesh.height * 0.72, -0.18 * side)
			lower_crown.material_override = _material(current_theme.get("foliage", Color8(92, 126, 70)).darkened(0.02))
			root.add_child(lower_crown)
		for side in [-1.0, 1.0]:
			var twig := MeshInstance3D.new()
			var twig_mesh := CylinderMesh.new()
			twig_mesh.top_radius = 0.026
			twig_mesh.bottom_radius = 0.038
			twig_mesh.height = 0.46 + variation * 0.12
			twig.mesh = twig_mesh
			twig.position = Vector3(side * (0.22 + variation * 0.04), trunk_mesh.height * 0.88, 0.12 * side)
			twig.rotation_degrees = Vector3(18.0 + variation * 8.0, 0.0, side * (34.0 + variation * 10.0))
			twig.material_override = _material(Color8(96, 72, 46))
			root.add_child(twig)
		for side in [-1.0, 1.0]:
			var canopy_lobe := MeshInstance3D.new()
			var canopy_lobe_mesh := SphereMesh.new()
			canopy_lobe_mesh.radius = 0.24 + variation * 0.08
			canopy_lobe_mesh.height = 0.52 + variation * 0.1
			canopy_lobe.mesh = canopy_lobe_mesh
			canopy_lobe.position = Vector3(side * (0.74 + variation * 0.1), trunk_mesh.height * 0.9, 0.18 * side)
			canopy_lobe.material_override = _material(current_theme.get("foliage", Color8(88, 122, 68)).darkened(0.04))
			root.add_child(canopy_lobe)
		var trunk_shadow := MeshInstance3D.new()
		var trunk_shadow_mesh := BoxMesh.new()
		trunk_shadow_mesh.size = Vector3(1.24 + variation * 0.24, 0.03, 0.92 + variation * 0.18)
		trunk_shadow.mesh = trunk_shadow_mesh
		trunk_shadow.position = Vector3(0.0, 0.03, 0.0)
		trunk_shadow.rotation_degrees = Vector3(0.0, variation * 28.0, 0.0)
		trunk_shadow.material_override = _material(current_theme.get("ground", Color8(182, 162, 104)).darkened(0.22), 0.22)
		root.add_child(trunk_shadow)


func _add_shrub(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	environment_root.add_child(root)
	var variation := _foliage_variation(pos)
	_add_undergrowth_cluster(pos, 0.44 + variation * 0.12, false)
	_add_grass_tuft_patch(pos, 0.62 + variation * 0.1, false)
	for stem_offset in [Vector3(-0.08, 0.16, 0.04), Vector3(0.0, 0.18, -0.02), Vector3(0.1, 0.14, 0.06)]:
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = 0.028
		stem_mesh.bottom_radius = 0.04
		stem_mesh.height = 0.34 + variation * 0.12
		stem.mesh = stem_mesh
		stem.position = stem_offset + Vector3(0.0, stem_mesh.height * 0.5 - 0.02, 0.0)
		stem.material_override = _material(Color8(92, 72, 48))
		root.add_child(stem)
	for crown_offset in [
		Vector3(0.0, 0.44, 0.0),
		Vector3(-0.28, 0.36, 0.12),
		Vector3(0.22, 0.32, -0.16),
		Vector3(0.12, 0.28, 0.18),
	]:
		var mesh_instance := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.36 + variation * 0.12
		mesh.height = 0.74 + variation * 0.2
		mesh_instance.mesh = mesh
		mesh_instance.position = crown_offset
		mesh_instance.material_override = _material(current_theme.get("foliage", Color8(96, 132, 74)).lightened(variation * 0.06))
		root.add_child(mesh_instance)
	for side in [-1.0, 1.0]:
		var side_leaf := MeshInstance3D.new()
		var side_leaf_mesh := BoxMesh.new()
		side_leaf_mesh.size = Vector3(0.34 + variation * 0.08, 0.08, 0.22)
		side_leaf.mesh = side_leaf_mesh
		side_leaf.position = Vector3(side * (0.22 + variation * 0.04), 0.22, 0.04 * side)
		side_leaf.rotation_degrees = Vector3(0.0, side * 34.0, side * 16.0)
		side_leaf.material_override = _material(current_theme.get("foliage", Color8(92, 126, 70)).darkened(0.04), 0.92)
		root.add_child(side_leaf)
	var shrub_shadow := MeshInstance3D.new()
	var shrub_shadow_mesh := BoxMesh.new()
	shrub_shadow_mesh.size = Vector3(0.78 + variation * 0.14, 0.025, 0.64 + variation * 0.12)
	shrub_shadow.mesh = shrub_shadow_mesh
	shrub_shadow.position = Vector3(0.0, 0.025, 0.0)
	shrub_shadow.rotation_degrees = Vector3(0.0, variation * 36.0, 0.0)
	shrub_shadow.material_override = _material(current_theme.get("ground", Color8(176, 156, 98)).darkened(0.18), 0.24)
	root.add_child(shrub_shadow)


func _add_undergrowth_cluster(pos: Vector3, scale: float, palm: bool) -> void:
	var base_color: Color = current_theme.get("foliage", Color8(96, 132, 74)).darkened(0.14 if palm else 0.08)
	for index in range(5):
		var phase := float(index) * 1.18 + pos.x * 0.09 + pos.z * 0.05
		var offset := Vector3(cos(phase) * (0.46 + 0.12 * index) * scale, 0.0, sin(phase * 1.12) * (0.34 + 0.1 * index) * scale)
		var tuft := MeshInstance3D.new()
		var tuft_mesh := BoxMesh.new()
		tuft_mesh.size = Vector3(0.06, 0.14 + 0.04 * float(index % 3), 0.24 + 0.06 * float(index % 2))
		tuft.mesh = tuft_mesh
		tuft.position = pos + offset + Vector3(0.0, tuft_mesh.size.y * 0.5, 0.0)
		tuft.rotation_degrees = Vector3(-8.0, phase * 54.0, 6.0 if index % 2 == 0 else -4.0)
		tuft.material_override = _material(base_color.lightened(0.04 * float(index % 2)), 0.9)
		environment_root.add_child(tuft)
		if not palm and index % 2 == 0:
			var leaf_pad := MeshInstance3D.new()
			var leaf_pad_mesh := SphereMesh.new()
			leaf_pad_mesh.radius = 0.12 + 0.03 * float(index % 3)
			leaf_pad_mesh.height = leaf_pad_mesh.radius * 1.1
			leaf_pad.mesh = leaf_pad_mesh
			leaf_pad.position = pos + offset + Vector3(0.06, 0.08, -0.04)
			leaf_pad.scale = Vector3(1.32, 0.42, 0.92)
			leaf_pad.material_override = _material(base_color.darkened(0.08), 0.54)
			environment_root.add_child(leaf_pad)


func _add_grass_tuft_patch(pos: Vector3, scale: float, sparse: bool) -> void:
	for index in range(6 if sparse else 8):
		var phase := float(index) * 1.04 + pos.x * 0.07 + pos.z * 0.05
		var offset := Vector3(cos(phase) * (0.64 + 0.08 * index) * scale, 0.0, sin(phase * 1.08) * (0.42 + 0.06 * index) * scale)
		var tuft := MeshInstance3D.new()
		var tuft_mesh := BoxMesh.new()
		tuft_mesh.size = Vector3(0.04, 0.18 + 0.05 * float(index % 3), 0.18 + 0.04 * float(index % 2))
		tuft.mesh = tuft_mesh
		tuft.position = pos + offset + Vector3(0.0, tuft_mesh.size.y * 0.5, 0.0)
		tuft.rotation_degrees = Vector3(-10.0 + 2.0 * float(index % 2), phase * 62.0, 10.0 if index % 2 == 0 else -8.0)
		tuft.material_override = _material(current_theme.get("foliage", Color8(104, 136, 80)).lightened(0.02 * float(index % 2)), 0.86)
		environment_root.add_child(tuft)


func _add_reed_cluster(pos: Vector3) -> void:
	var variation := _foliage_variation(pos)
	for index in range(14):
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = 0.028
		stem_mesh.bottom_radius = 0.05
		stem_mesh.height = 1.06 + float(index % 4) * 0.18 + variation * 0.24
		stem.mesh = stem_mesh
		stem.position = pos + Vector3(float(index) * 0.12 - 0.82, stem_mesh.height * 0.5, sin(float(index) + variation) * 0.46)
		stem.material_override = _material(Color8(124, 154, 96))
		environment_root.add_child(stem)
		if index % 2 == 0:
			var tip := MeshInstance3D.new()
			var tip_mesh := BoxMesh.new()
			tip_mesh.size = Vector3(0.06, 0.12 + variation * 0.04, 0.06)
			tip.mesh = tip_mesh
			tip.position = stem.position + Vector3(0.0, stem_mesh.height * 0.5 + 0.02, 0.0)
			tip.material_override = _material(Color8(168, 150, 92), 0.92)
			environment_root.add_child(tip)
		if index % 3 == 0:
			for side in [-1.0, 1.0]:
				var blade := MeshInstance3D.new()
				var blade_mesh := BoxMesh.new()
				blade_mesh.size = Vector3(0.03, 0.18 + variation * 0.06, 0.26 + variation * 0.1)
				blade.mesh = blade_mesh
				blade.position = stem.position + Vector3(side * 0.08, stem_mesh.height * (0.44 + variation * 0.04), 0.02 * side)
				blade.rotation_degrees = Vector3(side * 18.0, 0.0, side * 26.0)
				blade.material_override = _material(Color8(118, 150, 92), 0.88)
				environment_root.add_child(blade)


func _foliage_variation(pos: Vector3) -> float:
	return clampf(0.5 + 0.5 * sin(pos.x * 0.173 + pos.z * 0.117), 0.0, 1.0)


func _make_animal_member(species_id: String, category: String, primary: bool) -> Node3D:
	var asset_member := _try_make_species_asset_member(species_id, category, primary)
	if asset_member != null:
		return asset_member
	var root := Node3D.new()
	var color: Color = CATEGORY_COLORS.get(category, Color8(174, 191, 126))
	if species_id == "zebra":
		return _make_zebra_member(color, primary)
	if species_id == "antelope" or species_id == "deer":
		return _make_antelope_member(color, primary)
	if species_id == "lion":
		return _make_lion_member(color, primary)
	if species_id == "hyena" or species_id == "wolf" or species_id == "fox":
		return _make_canid_member(species_id, color, primary)
	if species_id == "african_elephant":
		return _make_elephant_member(color, primary)
	if species_id == "giraffe":
		return _make_giraffe_member(color, primary)
	if species_id == "hippopotamus":
		return _make_hippo_member(color, primary)
	if species_id == "nile_crocodile":
		return _make_crocodile_member(color, primary)
	if species_id == "vulture" or species_id == "eagle" or species_id == "owl" or species_id == "duck" or species_id == "sparrow" or species_id == "kingfisher_v4" or species_id == "woodpecker" or species_id == "bat_v4":
		return _make_bird_member(species_id, color, primary)
	var body := MeshInstance3D.new()
	if category == "飞行动物":
		var mesh := SphereMesh.new()
		mesh.radius = 0.18 if primary else 0.14
		mesh.height = mesh.radius * 2.0
		body.mesh = mesh
		body.position = Vector3(0.0, 1.6 if primary else 1.4, 0.0)
		var wing_left := MeshInstance3D.new()
		var wing_mesh := BoxMesh.new()
		wing_mesh.size = Vector3(0.54 if primary else 0.4, 0.04, 0.22)
		wing_left.mesh = wing_mesh
		wing_left.position = Vector3(-0.32 if primary else -0.24, body.position.y, 0.0)
		wing_left.rotation.z = deg_to_rad(-12.0)
		wing_left.material_override = _material(color.darkened(0.1))
		root.add_child(wing_left)
		var wing_right := MeshInstance3D.new()
		wing_right.mesh = wing_mesh
		wing_right.position = Vector3(0.32 if primary else 0.24, body.position.y, 0.0)
		wing_right.rotation.z = deg_to_rad(12.0)
		wing_right.material_override = _material(color.darkened(0.1))
		root.add_child(wing_right)
	elif category == "水域动物":
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.18 if primary else 0.14
		mesh.height = 0.64 if primary else 0.48
		body.mesh = mesh
		body.rotation.x = deg_to_rad(90.0)
		body.position = Vector3(0.0, 0.22, 0.0)
		var fin := MeshInstance3D.new()
		var fin_mesh := BoxMesh.new()
		fin_mesh.size = Vector3(0.06, 0.18, 0.24)
		fin.mesh = fin_mesh
		fin.position = Vector3(0.0, 0.3, -0.24)
		fin.material_override = _material(color.lightened(0.08))
		root.add_child(fin)
	else:
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.26 if primary else 0.18
		mesh.height = 0.86 if primary else 0.58
		body.mesh = mesh
		body.position = Vector3(0.0, 0.52 if primary else 0.4, -0.02)
	body.material_override = _material(color)
	root.add_child(body)
	if category != "飞行动物":
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.14 if primary else 0.1
		head_mesh.height = head_mesh.radius * 2.0
		head.mesh = head_mesh
		head.position = body.position + Vector3(0.0, 0.1 if category != "水域动物" else 0.04, 0.4 if category != "水域动物" else 0.28)
		head.material_override = _material(color.lightened(0.08))
		root.add_child(head)
		root.add_child(_sphere_part(head.position + Vector3(0.0, -0.02, 0.08), 0.08 if primary else 0.06, color.lightened(0.16), 0.92))
		root.add_child(_box_part(body.position + Vector3(0.0, -0.02, 0.04), Vector3(0.22 if primary else 0.16, 0.08, 0.46 if primary else 0.32), color.lightened(0.12), 0.9))
		for side in [-1.0, 1.0]:
			root.add_child(_sphere_part(head.position + Vector3(side * 0.08, 0.06, -0.02), 0.04 if primary else 0.03, color.darkened(0.06), 0.94))
			root.add_child(_sphere_part(head.position + Vector3(side * 0.05, 0.02, 0.12), 0.015, Color8(30, 28, 24), 0.98))
	if category in ["草食动物", "掠食者", "区域生物"]:
		for leg_side in [-1.0, 1.0]:
			for leg_row in [-1.0, 1.0]:
				var leg_name := "Leg_%s%s" % ["Front" if leg_row > 0.0 else "Back", "Left" if leg_side < 0.0 else "Right"]
				root.add_child(_quadruped_leg_rig(
					leg_name,
					Vector3(leg_side * 0.13, 0.26 if primary else 0.18, leg_row * 0.16),
					0.16 if primary else 0.12,
					0.14 if primary else 0.1,
					0.024,
					color.darkened(0.18),
					color.darkened(0.3)
				))
		root.add_child(_box_part(body.position + Vector3(0.0, -0.08, -0.08), Vector3(0.14 if primary else 0.1, 0.04, 0.24 if primary else 0.18), color.darkened(0.08), 0.84))
	return root


func _make_elephant_member(color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_capsule_part(Vector3(0.0, 0.76, 0.0), 0.34, 1.54, color, Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_capsule_part(Vector3(0.0, 0.96, -0.08), 0.18, 0.66, color.lightened(0.04), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.94))
	root.add_child(_sphere_part(Vector3(0.0, 0.92, 0.74), 0.36, color.lightened(0.06)))
	root.add_child(_box_part(Vector3(0.0, 1.0, 0.86), Vector3(0.28, 0.08, 0.18), color.lightened(0.12), 0.94))
	root.add_child(_box_part(Vector3(0.0, 0.8, 0.08), Vector3(0.48, 0.08, 1.02), color.darkened(0.04), 0.86))
	root.add_child(_box_part(Vector3(0.0, 0.72, -0.06), Vector3(0.3, 0.06, 0.42), color.darkened(0.08), 0.86))
	root.add_child(_capsule_part(Vector3(0.0, 0.54, 1.1), 0.11, 0.78, color.darkened(0.08)))
	root.add_child(_sphere_part(Vector3(0.0, 0.18, 1.2), 0.11, color.darkened(0.14)))
	for side in [-1.0, 1.0]:
		root.add_child(_capsule_part(Vector3(side * 0.4, 0.86, 0.66), 0.05, 0.44, color.lightened(0.14), Vector3(0.0, 0.0, deg_to_rad(side * 42.0)), 0.9))
		root.add_child(_box_part(Vector3(side * 0.18, 0.56, 0.98), Vector3(0.04, 0.14, 0.22), Color8(236, 228, 206), 0.96))
		root.add_child(_sphere_part(Vector3(side * 0.18, 0.96, 0.84), 0.04, Color8(42, 42, 42), 0.98))
		root.add_child(_box_part(Vector3(side * 0.3, 0.92, 0.54), Vector3(0.08, 0.42, 0.16), color.darkened(0.08), 0.84))
		root.add_child(_sphere_part(Vector3(side * 0.12, 0.86, 1.04), 0.025, Color8(38, 34, 30), 0.98))
	for side in [-1.0, 1.0]:
		for row in [-1.0, 1.0]:
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.28, 0.58, row * 0.34),
				0.28,
				0.28,
				0.045,
				color.darkened(0.18),
				color.darkened(0.22)
			))
	root.add_child(_capsule_part(Vector3(0.0, 0.76, -0.92), 0.03, 0.4, color.darkened(0.18), Vector3(deg_to_rad(34.0), 0.0, 0.0), 0.9))
	root.scale = Vector3.ONE * (1.08 if primary else 0.92)
	return root


func _make_giraffe_member(color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_capsule_part(Vector3(0.0, 0.76, 0.0), 0.22, 1.16, color, Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_capsule_part(Vector3(0.0, 1.4, 0.28), 0.07, 1.24, color.lightened(0.06), Vector3(deg_to_rad(-10.0), 0.0, 0.0)))
	root.add_child(_capsule_part(Vector3(0.0, 1.44, 0.14), 0.024, 1.18, Color8(94, 74, 48), Vector3(deg_to_rad(-10.0), 0.0, 0.0), 0.92))
	root.add_child(_sphere_part(Vector3(0.0, 1.88, 0.48), 0.18, color.lightened(0.12)))
	root.add_child(_box_part(Vector3(0.0, 1.84, 0.68), Vector3(0.16, 0.06, 0.16), Color8(214, 190, 154), 0.96))
	root.add_child(_box_part(Vector3(0.0, 0.56, 0.18), Vector3(0.2, 0.08, 0.52), Color8(226, 214, 178), 0.86))
	root.add_child(_capsule_part(Vector3(0.0, 1.18, -0.42), 0.02, 0.46, Color8(98, 74, 48), Vector3(deg_to_rad(22.0), 0.0, 0.0), 0.94))
	root.add_child(_box_part(Vector3(0.0, 0.5, -0.08), Vector3(0.16, 0.05, 0.36), Color8(214, 198, 154), 0.82))
	for spot in [Vector3(-0.14, 0.72, -0.18), Vector3(0.16, 0.76, 0.12), Vector3(-0.08, 1.16, 0.28), Vector3(0.1, 1.42, 0.36), Vector3(-0.1, 0.88, 0.16), Vector3(0.08, 1.3, 0.34), Vector3(-0.04, 1.62, 0.44), Vector3(0.12, 0.94, -0.06)]:
		root.add_child(_sphere_part(spot, 0.06, Color8(132, 92, 56), 0.96))
	for side in [-1.0, 1.0]:
		root.add_child(_capsule_part(Vector3(side * 0.08, 2.0, 0.48), 0.015, 0.16, Color8(88, 62, 38), Vector3(0.0, 0.0, deg_to_rad(side * 18.0))))
		root.add_child(_sphere_part(Vector3(side * 0.08, 1.88, 0.62), 0.03, Color8(34, 28, 22), 0.98))
	for side in [-1.0, 1.0]:
		for row in [-1.0, 1.0]:
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.18, 0.72, row * 0.24),
				0.34,
				0.32,
				0.026,
				color.darkened(0.18),
				Color8(76, 60, 40)
			))
	root.add_child(_capsule_part(Vector3(0.0, 0.92, -0.62), 0.018, 0.22, Color8(72, 56, 38), Vector3(deg_to_rad(18.0), 0.0, 0.0), 0.94))
	root.add_child(_sphere_part(Vector3(0.0, 0.82, -0.76), 0.034, Color8(62, 46, 30), 0.96))
	root.scale = Vector3.ONE * (1.02 if primary else 0.9)
	return root


func _make_lion_member(color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_capsule_part(Vector3(0.0, 0.58, -0.04), 0.19, 1.02, color, Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_capsule_part(Vector3(0.0, 0.62, -0.16), 0.12, 0.48, color.lightened(0.04), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.92))
	root.add_child(_sphere_part(Vector3(0.0, 0.64, 0.52), 0.19, color.lightened(0.08)))
	root.add_child(_sphere_part(Vector3(0.0, 0.64, 0.36), 0.22, Color8(122, 84, 46), 0.95))
	root.add_child(_box_part(Vector3(0.0, 0.48, 0.14), Vector3(0.18, 0.06, 0.5), Color8(220, 200, 164), 0.88))
	root.add_child(_capsule_part(Vector3(0.0, 0.54, -0.16), 0.09, 0.44, color.darkened(0.08), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.88))
	root.add_child(_box_part(Vector3(0.0, 0.54, 0.66), Vector3(0.16, 0.08, 0.18), Color8(214, 190, 154), 0.96))
	root.add_child(_capsule_part(Vector3(0.0, 0.56, -0.78), 0.026, 0.62, color.darkened(0.14), Vector3(deg_to_rad(18.0), 0.0, 0.0), 0.92))
	root.add_child(_sphere_part(Vector3(0.0, 0.62, -1.04), 0.06, Color8(122, 84, 46), 0.96))
	for side in [-1.0, 1.0]:
		root.add_child(_capsule_part(Vector3(side * 0.14, 0.74, 0.46), 0.018, 0.12, Color8(58, 42, 26), Vector3(0.0, 0.0, deg_to_rad(side * 20.0)), 0.96))
		root.add_child(_sphere_part(Vector3(side * 0.08, 0.64, 0.58), 0.028, Color8(36, 28, 22), 0.98))
		root.add_child(_box_part(Vector3(side * 0.12, 0.5, 0.62), Vector3(0.04, 0.03, 0.06), Color8(46, 34, 24), 0.96))
		root.add_child(_box_part(Vector3(side * 0.06, 0.58, 0.74), Vector3(0.02, 0.02, 0.06), Color8(34, 24, 18), 0.98))
		for row in [-1.0, 1.0]:
			var leg_z: float = row * (0.26 if row > 0.0 else 0.18)
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.16, 0.5 if row > 0.0 else 0.44, leg_z),
				0.18,
				0.18,
				0.026,
				color.darkened(0.18),
				color.darkened(0.08)
			))
	root.add_child(_box_part(Vector3(0.0, 0.58, 0.72), Vector3(0.12, 0.03, 0.04), Color8(32, 24, 20), 0.98))
	root.add_child(_box_part(Vector3(0.0, 0.42, -0.06), Vector3(0.12, 0.03, 0.22), Color8(94, 72, 46), 0.9))
	root.add_child(_box_part(Vector3(0.0, 0.5, 0.8), Vector3(0.18, 0.03, 0.08), Color8(238, 226, 198), 0.92))
	root.scale = Vector3.ONE * (1.04 if primary else 0.9)
	return root


func _make_canid_member(species_id: String, color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	var back_height := 0.58 if species_id == "hyena" else 0.5
	root.add_child(_capsule_part(Vector3(0.0, back_height, -0.04), 0.15, 0.94, color, Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_capsule_part(Vector3(0.0, back_height + 0.04, -0.08), 0.07, 0.34, color.lightened(0.04), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.9))
	root.add_child(_sphere_part(Vector3(0.0, back_height + 0.04, 0.5), 0.14, color.lightened(0.08)))
	root.add_child(_box_part(Vector3(0.0, back_height + 0.02, 0.62), Vector3(0.1, 0.06, 0.18), Color8(52, 38, 28), 0.96))
	root.add_child(_box_part(Vector3(0.0, back_height - 0.06, 0.12), Vector3(0.14, 0.05, 0.34), Color8(214, 204, 180), 0.84))
	root.add_child(_capsule_part(Vector3(0.0, back_height + 0.04, -0.16), 0.07, 0.3, color.darkened(0.08), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.88))
	root.add_child(_capsule_part(Vector3(0.0, back_height + 0.06, -0.68), 0.02, 0.56, color.darkened(0.12), Vector3(deg_to_rad(18.0), 0.0, 0.0), 0.92))
	for side in [-1.0, 1.0]:
		root.add_child(_capsule_part(Vector3(side * 0.08, back_height + 0.16, 0.46), 0.014, 0.12, Color8(60, 44, 30), Vector3(0.0, 0.0, deg_to_rad(side * 18.0))))
		root.add_child(_capsule_part(Vector3(side * 0.09, back_height + 0.18, 0.42), 0.018, 0.08, Color8(52, 36, 26), Vector3(0.0, 0.0, deg_to_rad(side * 26.0))))
		root.add_child(_box_part(Vector3(side * 0.08, back_height + 0.08, 0.64), Vector3(0.04, 0.03, 0.1), Color8(42, 34, 28), 0.96))
		root.add_child(_sphere_part(Vector3(side * 0.06, back_height + 0.06, 0.68), 0.024, Color8(36, 28, 22), 0.98))
		root.add_child(_box_part(Vector3(side * 0.04, back_height + 0.02, 0.76), Vector3(0.018, 0.02, 0.05), Color8(32, 24, 18), 0.98))
		for row in [-1.0, 1.0]:
			var leg_z: float = row * (0.24 if row > 0.0 else 0.16)
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.16, 0.42 if row > 0.0 else 0.36, leg_z),
				0.16,
				0.14,
				0.022,
				color.darkened(0.18),
				color.darkened(0.08)
			))
	if species_id == "hyena":
		root.add_child(_capsule_part(Vector3(0.0, 0.74, -0.08), 0.06, 0.46, Color8(88, 74, 52), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.94))
		for spot in [Vector3(-0.14, 0.54, -0.1), Vector3(0.12, 0.56, 0.08), Vector3(-0.1, 0.48, 0.26)]:
			root.add_child(_sphere_part(spot, 0.04, Color8(74, 58, 40), 0.94))
		root.add_child(_capsule_part(Vector3(0.0, 0.36, -0.64), 0.03, 0.26, Color8(58, 46, 34), Vector3(deg_to_rad(18.0), 0.0, 0.0), 0.94))
	else:
		root.add_child(_box_part(Vector3(0.0, back_height + 0.02, -0.02), Vector3(0.1, 0.03, 0.28), Color8(214, 206, 184), 0.84))
	root.add_child(_box_part(Vector3(0.0, back_height - 0.02, 0.74), Vector3(0.12, 0.03, 0.08), Color8(226, 216, 198), 0.9))
	root.scale = Vector3.ONE * (1.0 if primary else 0.9)
	return root


func _make_zebra_member(color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_capsule_part(Vector3(0.0, 0.54, 0.0), 0.18, 0.98, Color8(226, 224, 214), Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_sphere_part(Vector3(0.0, 0.64, 0.44), 0.16, Color8(226, 224, 214)))
	for stripe_z in [-0.3, -0.12, 0.06, 0.24]:
		root.add_child(_box_part(Vector3(0.0, 0.54, stripe_z), Vector3(0.62, 0.04, 0.06), Color8(44, 44, 44), 0.96))
	root.add_child(_box_part(Vector3(0.0, 0.66, 0.36), Vector3(0.24, 0.04, 0.06), Color8(44, 44, 44), 0.96))
	for neck_stripe_z in [0.48, 0.58]:
		root.add_child(_box_part(Vector3(0.0, 0.7, neck_stripe_z), Vector3(0.18, 0.03, 0.05), Color8(44, 44, 44), 0.96))
	root.add_child(_capsule_part(Vector3(0.0, 0.78, -0.02), 0.018, 0.56, Color8(44, 44, 44), Vector3(0.0, 0.0, 0.0), 0.96))
	root.add_child(_box_part(Vector3(0.0, 0.62, 0.54), Vector3(0.12, 0.03, 0.1), Color8(42, 42, 42), 0.98))
	root.add_child(_box_part(Vector3(0.0, 0.56, 0.62), Vector3(0.08, 0.06, 0.12), Color8(42, 42, 42), 0.98))
	root.add_child(_capsule_part(Vector3(0.0, 0.54, -0.7), 0.02, 0.38, Color8(42, 42, 42), Vector3(deg_to_rad(28.0), 0.0, 0.0), 0.96))
	root.add_child(_capsule_part(Vector3(0.0, 0.78, -0.04), 0.014, 0.72, Color8(44, 44, 44), Vector3(0.0, 0.0, 0.0), 0.96))
	for side in [-1.0, 1.0]:
		root.add_child(_capsule_part(Vector3(side * 0.08, 0.78, 0.44), 0.016, 0.1, Color8(52, 52, 48), Vector3(0.0, 0.0, deg_to_rad(side * 24.0))))
		root.add_child(_sphere_part(Vector3(side * 0.05, 0.66, 0.58), 0.02, Color8(26, 26, 22), 0.98))
		for row in [-1.0, 1.0]:
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.16, 0.42, row * 0.22),
				0.16,
				0.14,
				0.02,
				Color8(58, 58, 58),
				Color8(42, 42, 42)
			))
	root.add_child(_box_part(Vector3(0.0, 0.34, -0.12), Vector3(0.16, 0.03, 0.2), Color8(228, 226, 214), 0.82))
	root.scale = Vector3.ONE * (1.0 if primary else 0.9)
	return root


func _make_antelope_member(color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_capsule_part(Vector3(0.0, 0.52, -0.02), 0.15, 0.96, color, Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_sphere_part(Vector3(0.0, 0.62, 0.5), 0.13, color.lightened(0.08)))
	root.add_child(_box_part(Vector3(0.0, 0.44, 0.08), Vector3(0.16, 0.05, 0.42), Color8(226, 214, 182), 0.86))
	root.add_child(_capsule_part(Vector3(0.0, 0.46, -0.74), 0.018, 0.38, Color8(86, 68, 42), Vector3(deg_to_rad(18.0), 0.0, 0.0), 0.94))
	root.add_child(_capsule_part(Vector3(0.0, 0.46, 0.04), 0.08, 0.72, Color8(214, 198, 154), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.78))
	root.add_child(_box_part(Vector3(0.0, 0.54, 0.58), Vector3(0.12, 0.04, 0.12), Color8(238, 228, 198), 0.96))
	root.add_child(_capsule_part(Vector3(0.0, 0.6, -0.06), 0.02, 0.78, Color8(102, 82, 52), Vector3(0.0, 0.0, 0.0), 0.96))
	root.add_child(_box_part(Vector3(0.0, 0.42, -0.08), Vector3(0.1, 0.03, 0.24), Color8(164, 140, 96), 0.88))
	for side in [-1.0, 1.0]:
		root.add_child(_capsule_part(Vector3(side * 0.05, 0.82, 0.5), 0.014, 0.22, Color8(70, 52, 34), Vector3(0.0, 0.0, deg_to_rad(side * 14.0))))
		root.add_child(_capsule_part(Vector3(side * 0.1, 0.92, 0.54), 0.01, 0.22, Color8(54, 42, 30), Vector3(0.0, 0.0, deg_to_rad(side * 10.0)), 0.96))
		for row in [-1.0, 1.0]:
			var leg_z: float = row * (0.24 if row > 0.0 else 0.16)
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.15, 0.52 if row > 0.0 else 0.44, leg_z),
				0.22,
				0.2,
				0.018,
				color.darkened(0.18),
				color.darkened(0.08)
			))
	root.add_child(_box_part(Vector3(0.0, 0.32, -0.1), Vector3(0.12, 0.03, 0.16), Color8(188, 168, 118), 0.82))
	root.scale = Vector3.ONE * (1.0 if primary else 0.88)
	return root


func _make_hippo_member(color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_capsule_part(Vector3(0.0, 0.46, 0.0), 0.24, 1.26, color, Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_capsule_part(Vector3(0.0, 0.54, -0.1), 0.14, 0.4, color.lightened(0.04), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.9))
	root.add_child(_capsule_part(Vector3(0.0, 0.46, 0.58), 0.18, 0.52, color.lightened(0.04), Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_box_part(Vector3(0.0, 0.4, 0.82), Vector3(0.3, 0.08, 0.22), Color8(192, 158, 142), 0.94))
	root.add_child(_capsule_part(Vector3(0.0, 0.58, -0.1), 0.1, 0.62, color.darkened(0.06), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.86))
	for side in [-1.0, 1.0]:
		root.add_child(_sphere_part(Vector3(side * 0.08, 0.56, 0.78), 0.03, Color8(48, 42, 38), 0.96))
		root.add_child(_capsule_part(Vector3(side * 0.18, 0.62, 0.62), 0.024, 0.12, Color8(74, 62, 58), Vector3(0.0, 0.0, deg_to_rad(side * 16.0)), 0.96))
		root.add_child(_sphere_part(Vector3(side * 0.12, 0.48, 0.9), 0.025, Color8(44, 38, 34), 0.98))
		root.add_child(_sphere_part(Vector3(side * 0.06, 0.48, 0.98), 0.02, Color8(76, 64, 58), 0.94))
	root.add_child(_box_part(Vector3(0.0, 0.32, 0.88), Vector3(0.26, 0.04, 0.14), Color8(176, 138, 124), 0.94))
	root.add_child(_capsule_part(Vector3(0.0, 0.54, -0.72), 0.03, 0.18, color.darkened(0.12), Vector3(deg_to_rad(18.0), 0.0, 0.0), 0.9))
	for side in [-1.0, 1.0]:
		for row in [-1.0, 1.0]:
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.22, 0.34, row * 0.28),
				0.12,
				0.12,
				0.028,
				color.darkened(0.16),
				color.darkened(0.08)
			))
	root.scale = Vector3.ONE * (1.05 if primary else 0.92)
	return root


func _make_crocodile_member(color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_capsule_part(Vector3(0.0, 0.2, 0.0), 0.08, 1.42, color, Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_capsule_part(Vector3(0.0, 0.2, 0.76), 0.05, 0.56, color.lightened(0.06), Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	root.add_child(_box_part(Vector3(0.0, 0.18, 1.02), Vector3(0.14, 0.04, 0.28), color.lightened(0.1)))
	root.add_child(_capsule_part(Vector3(0.0, 0.28, 0.2), 0.026, 0.84, color.lightened(0.08), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.92))
	root.add_child(_capsule_part(Vector3(0.0, 0.18, -0.88), 0.04, 0.74, color.darkened(0.14), Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	for ridge_z in [-0.48, -0.24, -0.02, 0.22, 0.44]:
		root.add_child(_sphere_part(Vector3(0.0, 0.28, ridge_z), 0.05, color.lightened(0.08), 0.94))
	for side in [-1.0, 1.0]:
		root.add_child(_box_part(Vector3(side * 0.05, 0.24, 0.98), Vector3(0.02, 0.02, 0.1), Color8(232, 222, 198), 0.96))
		root.add_child(_sphere_part(Vector3(side * 0.06, 0.26, 0.78), 0.02, Color8(40, 34, 28), 0.98))
		for ridge_z in [-0.28, 0.04, 0.36]:
			root.add_child(_box_part(Vector3(side * 0.09, 0.16, ridge_z), Vector3(0.04, 0.03, 0.08), color.darkened(0.08), 0.9))
	root.add_child(_capsule_part(Vector3(0.0, 0.18, -1.22), 0.03, 0.34, color.darkened(0.2), Vector3(deg_to_rad(90.0), 0.0, 0.0)))
	for side in [-1.0, 1.0]:
		for row in [-1.0, 1.0]:
			var leg_name := "Leg_%s%s" % ["Front" if row > 0.0 else "Back", "Left" if side < 0.0 else "Right"]
			root.add_child(_quadruped_leg_rig(
				leg_name,
				Vector3(side * 0.12, 0.16, row * 0.2),
				0.05,
				0.04,
				0.014,
				color.darkened(0.22),
				color.darkened(0.28)
			))
	root.scale = Vector3.ONE * (1.02 if primary else 0.88)
	return root


func _make_bird_member(species_id: String, color: Color, primary: bool) -> Node3D:
	var root := Node3D.new()
	var body_y := 1.48 if primary else 1.34
	var body := _capsule_part(Vector3(0.0, body_y, 0.0), 0.08 if primary else 0.06, 0.34 if primary else 0.26, color, Vector3(deg_to_rad(90.0), 0.0, 0.0))
	root.add_child(body)
	var wing_span := 0.86 if species_id in ["vulture", "eagle", "owl"] else 0.56
	var wing_color := color.darkened(0.12)
	if species_id == "owl":
		wing_color = Color8(158, 144, 118)
	elif species_id == "duck":
		wing_color = Color8(108, 156, 112)
	root.add_child(_capsule_part(Vector3(-wing_span * 0.28, body_y, 0.0), 0.028, wing_span * 0.72, wing_color, Vector3(0.0, 0.0, deg_to_rad(-88.0)), 0.94))
	root.add_child(_capsule_part(Vector3(wing_span * 0.28, body_y, 0.0), 0.028, wing_span * 0.72, wing_color, Vector3(0.0, 0.0, deg_to_rad(88.0)), 0.94))
	root.add_child(_capsule_part(Vector3(0.0, body_y + 0.04, -0.06), 0.024, 0.18, wing_color.lightened(0.06), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.9))
	var head_color := color.lightened(0.1)
	if species_id == "vulture":
		head_color = Color8(216, 204, 182)
	elif species_id == "duck":
		head_color = Color8(84, 126, 82)
	root.add_child(_sphere_part(Vector3(0.0, body_y + 0.06, 0.16), 0.08 if primary else 0.06, head_color))
	var beak_size := Vector3(0.03, 0.03, 0.1)
	var beak_color := Color8(222, 188, 104)
	if species_id == "duck":
		beak_size = Vector3(0.05, 0.03, 0.12)
		beak_color = Color8(232, 184, 86)
	elif species_id == "owl":
		beak_size = Vector3(0.02, 0.03, 0.06)
	if species_id == "owl":
		root.add_child(_capsule_part(Vector3(0.0, body_y + 0.08, 0.1), 0.05, 0.22, Color8(216, 204, 176), Vector3(0.0, 0.0, deg_to_rad(90.0)), 0.94))
	if species_id == "vulture":
		root.add_child(_capsule_part(Vector3(0.0, body_y + 0.02, 0.06), 0.04, 0.18, Color8(226, 214, 186), Vector3(0.0, 0.0, deg_to_rad(90.0)), 0.94))
	elif species_id == "eagle":
		root.add_child(_capsule_part(Vector3(0.0, body_y + 0.02, -0.12), 0.016, 0.28, Color8(96, 72, 48), Vector3(deg_to_rad(12.0), 0.0, 0.0), 0.94))
	elif species_id == "duck":
		root.add_child(_capsule_part(Vector3(0.0, body_y - 0.02, 0.02), 0.08, 0.28, Color8(118, 168, 118), Vector3(deg_to_rad(90.0), 0.0, 0.0), 0.92))
	root.add_child(_capsule_part(Vector3(0.0, body_y - 0.02, -0.2), 0.016, 0.28, wing_color.darkened(0.08), Vector3(deg_to_rad(16.0), 0.0, 0.0), 0.92))
	root.add_child(_box_part(Vector3(0.0, body_y - 0.02, -0.34), Vector3(0.14 if primary else 0.1, 0.03, 0.14), wing_color.darkened(0.12), 0.94))
	if species_id == "sparrow":
		root.add_child(_capsule_part(Vector3(0.0, body_y, -0.16), 0.016, 0.12, Color8(120, 94, 72), Vector3(deg_to_rad(18.0), 0.0, 0.0), 0.94))
	root.add_child(_box_part(Vector3(0.0, body_y + 0.03, 0.28), beak_size, beak_color, 0.96))
	root.add_child(_capsule_part(Vector3(0.0, body_y, -0.2), 0.02, 0.22, color.darkened(0.16), Vector3(deg_to_rad(12.0), 0.0, 0.0)))
	for side in [-1.0, 1.0]:
		root.add_child(_sphere_part(Vector3(side * 0.04, body_y + 0.06, 0.22), 0.018, Color8(28, 28, 24), 0.98))
		var leg_name := "Leg_%s" % ("Left" if side < 0.0 else "Right")
		root.add_child(_bird_leg_rig(
			leg_name,
			Vector3(side * 0.04, body_y - 0.08, 0.02),
			0.08,
			0.06,
			0.007,
			Color8(84, 68, 48),
			Color8(102, 84, 58)
		))
	root.scale = Vector3.ONE * (1.0 if primary else 0.88)
	return root


func _sphere_part(pos: Vector3, radius: float, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.position = pos
	mesh.material_override = _material(color, alpha)
	return mesh


func _capsule_part(pos: Vector3, radius: float, height: float, color: Color, rotation: Vector3 = Vector3.ZERO, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	mesh.mesh = capsule
	mesh.position = pos
	mesh.rotation = rotation
	mesh.material_override = _material(color, alpha)
	return mesh


func _cylinder_part(pos: Vector3, radius: float, height: float, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.82
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.position = pos
	mesh.material_override = _material(color, alpha)
	return mesh


func _box_part(pos: Vector3, size: Vector3, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = _material(color, alpha)
	return mesh


func _quadruped_leg_rig(name: String, pos: Vector3, upper_h: float, lower_h: float, radius: float, color: Color, hoof_color: Color) -> Node3D:
	var rig := Node3D.new()
	rig.name = name
	rig.position = pos
	rig.set_meta("base_position", pos)
	rig.add_child(_capsule_part(Vector3(0.0, -upper_h * 0.5, 0.0), radius, upper_h, color, Vector3.ZERO, 0.96))
	var knee := Node3D.new()
	knee.name = "Knee"
	knee.position = Vector3(0.0, -upper_h, 0.0)
	knee.set_meta("base_position", knee.position)
	rig.add_child(knee)
	knee.add_child(_cylinder_part(Vector3(0.0, -lower_h * 0.5, 0.0), radius * 0.9, lower_h, color.darkened(0.08), 0.96))
	knee.add_child(_box_part(Vector3(0.0, -lower_h - 0.03, 0.02), Vector3(radius * 3.0, 0.04, radius * 3.6), hoof_color, 0.96))
	return rig


func _bird_leg_rig(name: String, pos: Vector3, upper_h: float, lower_h: float, radius: float, color: Color, foot_color: Color) -> Node3D:
	var rig := Node3D.new()
	rig.name = name
	rig.position = pos
	rig.set_meta("base_position", pos)
	rig.add_child(_cylinder_part(Vector3(0.0, -upper_h * 0.5, 0.0), radius, upper_h, color, 0.96))
	var knee := Node3D.new()
	knee.name = "Knee"
	knee.position = Vector3(0.0, -upper_h, 0.0)
	knee.set_meta("base_position", knee.position)
	rig.add_child(knee)
	knee.add_child(_cylinder_part(Vector3(0.0, -lower_h * 0.5, 0.0), radius * 0.86, lower_h, color.darkened(0.08), 0.96))
	knee.add_child(_box_part(Vector3(0.0, -lower_h - 0.012, 0.04), Vector3(0.04, 0.012, 0.07), foot_color, 0.96))
	return rig


func _hotspot_pos(hotspot_id: String) -> Vector3:
	var hotspot_map: Dictionary = current_layout.get("hotspots", {})
	return hotspot_map.get(hotspot_id, Vector3.ZERO)


func _category_for_species(species_id: String) -> String:
	for entry in species_manifest:
		if str(entry.get("species_id", "")) == species_id:
			return str(entry.get("category", "区域生物"))
	return "区域生物"


func _dynamic_hotspot_profile(hotspot_id: String) -> Dictionary:
	var rows: Dictionary = dynamic_region_state.get("hotspot_activity", {})
	return rows.get(hotspot_id, {})


func _dynamic_hotspot_scale(hotspot_id: String, key: String, default_value: float = 1.0) -> float:
	var profile := _dynamic_hotspot_profile(hotspot_id)
	return float(profile.get(key, default_value))


func _dynamic_cluster_profile(category: String) -> Dictionary:
	var rows: Dictionary = dynamic_region_state.get("species_clusters", {})
	return rows.get(category, {})


func _dynamic_cluster_scale(category: String, key: String, default_value: float = 1.0) -> float:
	var profile := _dynamic_cluster_profile(category)
	return float(profile.get(key, default_value))


func _dynamic_pressure_window() -> Dictionary:
	return dynamic_region_state.get("pressure_window", {})


func _dynamic_interaction_state() -> Dictionary:
	return dynamic_region_state.get("interaction_state", {})


func _dynamic_event_state() -> Dictionary:
	return dynamic_region_state.get("event_state", {})


func _dynamic_objective_state() -> Dictionary:
	return dynamic_region_state.get("objective_state", {})


func _dynamic_chase_state() -> Dictionary:
	return dynamic_region_state.get("chase_state", {})


func _dynamic_hotspot_windows() -> Dictionary:
	return dynamic_region_state.get("hotspot_windows", {})


func _dynamic_hotspot_window(hotspot_id: String) -> Dictionary:
	var rows := _dynamic_hotspot_windows()
	return rows.get(hotspot_id, {})


func _dynamic_completion_state() -> Dictionary:
	return dynamic_region_state.get("completion_state", {})


func _dynamic_exit_state() -> Dictionary:
	return dynamic_region_state.get("exit_state", {})


func _recommended_exit_gate_id() -> String:
	return str(_dynamic_exit_state().get("recommended_gate_id", ""))


func _recommended_exit_gate_reason() -> String:
	return str(_dynamic_exit_state().get("recommended_gate_reason", ""))


func _recommended_terminal_reason() -> String:
	return str(_dynamic_exit_state().get("recommended_terminal_reason", ""))


func _recommended_terminal_scale() -> float:
	return float(_dynamic_exit_state().get("recommended_terminal_scale", 1.0))


func _terminal_scale_adjust(base: float) -> float:
	if is_equal_approx(base, 1.0):
		return base
	return 1.0 + (base - 1.0) * _recommended_terminal_scale()


func _terminal_event_scale_adjust(base: float) -> float:
	if is_zero_approx(base):
		return base
	return base * _recommended_terminal_scale()


func _recommended_terminal_scale_text() -> String:
	return TerminalGuidance.scale_text(_recommended_terminal_scale())


func _recommended_terminal_action_text() -> String:
	return TerminalGuidance.action_text(_recommended_terminal_scale())


func _terminal_signal_text() -> String:
	if current_route_stage != "terminal" and _recommended_route_focus_kind() not in ["chokepoint", "route_landmark"]:
		return ""
	return TerminalGuidance.signal_text(_recommended_terminal_scale(), _recommended_terminal_reason())


func _recommended_route_focus_kind() -> String:
	return str(_dynamic_exit_state().get("recommended_route_focus_kind", ""))


func _recommended_route_focus_scale() -> float:
	return float(_dynamic_exit_state().get("focus_switch_scale", 1.0))


func _arrival_recommended_focus_boost(channel: String) -> float:
	if pending_arrival_intro.is_empty():
		return 1.0
	var focus_kind := _recommended_route_focus_kind()
	var focus_scale := _recommended_route_focus_scale()
	var blend := minf(1.0, maxf(0.0, focus_scale - 0.96) / 0.22)
	var terminal_scale := _recommended_terminal_scale()
	var terminal_focus := focus_kind in ["chokepoint", "route_landmark"]
	var base := 1.0
	match channel:
		"exit":
			if focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
				base = lerpf(1.0, 1.14, blend)
		"hotspot":
			if focus_kind == "branch_route":
				base = lerpf(1.0, 1.12, blend)
			if focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
				base = lerpf(1.0, 0.9, blend)
		"encounter":
			if focus_kind == "branch_route":
				base = lerpf(1.0, 1.08, blend)
			if focus_kind in ["entry_route", "chokepoint", "route_landmark"]:
				base = lerpf(1.0, 0.92, blend)
		"pressure":
			if focus_kind == "branch_route":
				base = lerpf(1.0, 1.05, blend)
			if focus_kind in ["entry_route", "trunk_route"]:
				base = lerpf(1.0, 0.94, blend)
			if focus_kind in ["chokepoint", "route_landmark"]:
				base = lerpf(1.0, 1.12, blend)
		"aftermath":
			if focus_kind == "branch_route":
				base = lerpf(1.0, 0.98, blend)
			if focus_kind in ["entry_route", "trunk_route"]:
				base = lerpf(1.0, 0.92, blend)
			if focus_kind in ["chokepoint", "route_landmark"]:
				base = lerpf(1.0, 1.16, blend)
	if terminal_focus and channel in ["exit", "hotspot", "encounter", "pressure", "aftermath"]:
		return 1.0 + (base - 1.0) * terminal_scale
	return base


func _arrival_event_focus_boost(kind: String) -> int:
	if arrival_event_focus_timer <= 0.0:
		return 0
	var focus_kind := _recommended_route_focus_kind()
	var focus_scale := _recommended_route_focus_scale()
	var blend := minf(1.0, maxf(0.0, focus_scale - 0.96) / 0.22)
	var base := 0
	match focus_kind:
		"entry_route":
			if kind == "exit":
				base = int(18.0 * blend)
			if kind in ["hotspot", "encounter"]:
				base = -int(10.0 * blend)
		"trunk_route":
			if kind == "exit":
				base = int(10.0 * blend)
			if kind == "hotspot":
				base = -int(6.0 * blend)
		"branch_route":
			if kind in ["hotspot", "task", "encounter"]:
				base = int(14.0 * blend)
			if kind == "exit":
				base = -int(8.0 * blend)
		"chokepoint", "route_landmark":
			if kind in ["exit", "chase_result", "aftermath"]:
				base = int(16.0 * blend)
			if kind in ["hotspot", "encounter"]:
				base = -int(8.0 * blend)
	if focus_kind in ["chokepoint", "route_landmark"] and base != 0:
		return int(round(float(base) * _recommended_terminal_scale()))
	return base


func _arrival_result_event_boost(kind: String) -> float:
	if arrival_event_focus_timer <= 0.0:
		return 0.0
	var focus_kind := _recommended_route_focus_kind()
	var focus_scale := _recommended_route_focus_scale()
	var blend := minf(1.0, maxf(0.0, focus_scale - 0.96) / 0.22)
	var base := 0.0
	match focus_kind:
		"chokepoint", "route_landmark":
			if kind == "chase_result":
				base = 0.62 * blend
			if kind == "aftermath":
				base = 0.74 * blend
		"branch_route":
			if kind in ["chase_result", "aftermath"]:
				base = 0.12 * blend
		"entry_route", "trunk_route":
			if kind in ["chase_result", "aftermath"]:
				base = -0.16 * blend
	if focus_kind in ["chokepoint", "route_landmark"] and not is_zero_approx(base):
		return base * _recommended_terminal_scale()
	return base


func _arrival_hotspot_window_boost(hotspot_id: String) -> float:
	if arrival_event_focus_timer <= 0.0:
		return 1.0
	var focus_kind := _recommended_route_focus_kind()
	var focus_scale := _recommended_route_focus_scale()
	var blend := minf(1.0, maxf(0.0, focus_scale - 0.96) / 0.22)
	var objective_state := _dynamic_objective_state()
	var chase_state := _dynamic_chase_state()
	var objective_hotspots := [
		str(objective_state.get("primary_hotspot", "")),
		str(objective_state.get("secondary_hotspot", "")),
	]
	var pressure_hotspot := str(chase_state.get("pressure_hotspot", ""))
	var aftermath_hotspot := str(chase_state.get("aftermath_hotspot", ""))
	var is_terminal_hotspot := hotspot_id in ["predator_ridge", "carrion_field", pressure_hotspot, aftermath_hotspot]
	var is_objective_hotspot := hotspot_id in objective_hotspots
	match focus_kind:
		"entry_route", "trunk_route":
			if hotspot_id in ["waterhole", "migration_corridor"] or is_objective_hotspot:
				return lerpf(1.0, 1.08, blend)
			if is_terminal_hotspot:
				return lerpf(1.0, 0.86, blend)
		"branch_route":
			if is_objective_hotspot:
				return lerpf(1.0, 1.16, blend)
			if is_terminal_hotspot:
				return lerpf(1.0, 0.94, blend)
		"chokepoint", "route_landmark":
			if is_terminal_hotspot:
				return lerpf(1.0, 1.18, blend)
			if is_objective_hotspot:
				return lerpf(1.0, 0.92, blend)
	return 1.0


func _arrival_exit_window_boost(exit_id: String) -> float:
	if arrival_event_focus_timer <= 0.0:
		return 1.0
	var focus_kind := _recommended_route_focus_kind()
	var focus_scale := _recommended_route_focus_scale()
	var blend := minf(1.0, maxf(0.0, focus_scale - 0.96) / 0.22)
	var recommended_gate_id := _recommended_exit_gate_id()
	if exit_id == recommended_gate_id and recommended_gate_id != "":
		match focus_kind:
			"entry_route", "trunk_route":
				return lerpf(1.0, 1.18, blend)
			"chokepoint", "route_landmark":
				return lerpf(1.0, 1.24, blend)
			"branch_route":
				return lerpf(1.0, 1.04, blend)
	if focus_kind == "branch_route":
		return lerpf(1.0, 0.9, blend)
	if focus_kind in ["entry_route", "trunk_route", "chokepoint", "route_landmark"]:
		return lerpf(1.0, 0.94, blend)
	return 1.0


func _arrival_ambient_channel_boost(channel: String) -> float:
	if arrival_event_focus_timer <= 0.0:
		return 1.0
	var focus_kind := _recommended_route_focus_kind()
	var focus_scale := _recommended_route_focus_scale()
	var blend := minf(1.0, maxf(0.0, focus_scale - 0.96) / 0.22)
	var objective_state := _dynamic_objective_state()
	var chase_state := _dynamic_chase_state()
	var recommended_gate_id := _recommended_exit_gate_id()
	var primary_hotspot := str(objective_state.get("primary_hotspot", ""))
	var secondary_hotspot := str(objective_state.get("secondary_hotspot", ""))
	var pressure_hotspot := str(chase_state.get("pressure_hotspot", ""))
	var aftermath_hotspot := str(chase_state.get("aftermath_hotspot", ""))
	if channel == recommended_gate_id and recommended_gate_id != "":
		match focus_kind:
			"entry_route", "trunk_route":
				return lerpf(1.0, 1.2, blend)
			"chokepoint", "route_landmark":
				return lerpf(1.0, 1.28, blend)
			"branch_route":
				return lerpf(1.0, 0.96, blend)
	if channel == primary_hotspot and primary_hotspot != "":
		match focus_kind:
			"branch_route":
				return lerpf(1.0, 1.18, blend)
			"entry_route", "trunk_route":
				return lerpf(1.0, 1.06, blend)
			"chokepoint", "route_landmark":
				return lerpf(1.0, 0.9, blend)
	if channel == secondary_hotspot and secondary_hotspot != "":
		match focus_kind:
			"branch_route":
				return lerpf(1.0, 1.1, blend)
			"chokepoint", "route_landmark":
				return lerpf(1.0, 0.94, blend)
	if channel == pressure_hotspot and pressure_hotspot != "":
		if focus_kind in ["chokepoint", "route_landmark"]:
			return lerpf(1.0, 1.18, blend)
		if focus_kind == "branch_route":
			return lerpf(1.0, 1.06, blend)
	if channel == aftermath_hotspot and aftermath_hotspot != "":
		if focus_kind in ["chokepoint", "route_landmark"]:
			return lerpf(1.0, 1.22, blend)
		if focus_kind == "branch_route":
			return lerpf(1.0, 0.98, blend)
	return 1.0


func _terminal_chain_ambient_boost(channel: String) -> float:
	var terminal_active := current_route_stage == "terminal" or (arrival_event_focus_timer > 0.0 and _recommended_route_focus_kind() in ["chokepoint", "route_landmark"])
	if not terminal_active:
		return 1.0
	var objective_state := _dynamic_objective_state()
	var chase_state := _dynamic_chase_state()
	var recommended_gate_id := _recommended_exit_gate_id()
	var primary_hotspot := str(objective_state.get("primary_hotspot", ""))
	var pressure_hotspot := str(chase_state.get("pressure_hotspot", ""))
	var aftermath_hotspot := str(chase_state.get("aftermath_hotspot", ""))
	match _stage_shell_focus_band("terminal"):
		"pressure":
			if channel == "pressure" or (pressure_hotspot != "" and channel == pressure_hotspot):
				return _terminal_scale_adjust(1.22)
			if channel == "aftermath" or (aftermath_hotspot != "" and channel == aftermath_hotspot):
				return _terminal_scale_adjust(0.94)
			if channel == recommended_gate_id and recommended_gate_id != "":
				return _terminal_scale_adjust(1.02)
			if channel == primary_hotspot and primary_hotspot != "":
				return _terminal_scale_adjust(0.96)
		"aftermath":
			if channel == "aftermath" or (aftermath_hotspot != "" and channel == aftermath_hotspot):
				return _terminal_scale_adjust(1.24)
			if channel == "pressure" or (pressure_hotspot != "" and channel == pressure_hotspot):
				return _terminal_scale_adjust(1.04)
			if channel == recommended_gate_id and recommended_gate_id != "":
				return _terminal_scale_adjust(1.06)
			if channel == primary_hotspot and primary_hotspot != "":
				return _terminal_scale_adjust(0.94)
		"exit":
			if channel == recommended_gate_id and recommended_gate_id != "":
				return _terminal_scale_adjust(1.26)
			if channel == "pressure" or (pressure_hotspot != "" and channel == pressure_hotspot):
				return _terminal_scale_adjust(0.92)
			if channel == "aftermath" or (aftermath_hotspot != "" and channel == aftermath_hotspot):
				return _terminal_scale_adjust(0.96)
			if channel == primary_hotspot and primary_hotspot != "":
				return _terminal_scale_adjust(0.9)
		_:
			return 1.0
	return 1.0


func _update_arrival_event_focus_timer(delta: float) -> void:
	if arrival_event_focus_timer <= 0.0:
		return
	arrival_event_focus_timer = maxf(0.0, arrival_event_focus_timer - delta)


func _exit_gate_boost(exit_id: String) -> float:
	var recommended_gate_id := _recommended_exit_gate_id()
	if recommended_gate_id == "" or exit_id != recommended_gate_id:
		return 1.0
	return float(_dynamic_exit_state().get("recommended_gate_scale", 1.18))


func _biome_key_for_region(detail: Dictionary) -> String:
	var biomes: Array = detail.get("dominant_biomes", [])
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return "wetland"
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return "forest"
	if "coast" in biomes or "estuary" in biomes or "coral_reef" in biomes or "seagrass" in biomes:
		return "coast"
	return "grassland"


func _biome_label(biome: String) -> String:
	match biome:
		"wetland":
			return "湿地探索"
		"forest":
			return "森林探索"
		"coast":
			return "海岸探索"
		_:
			return "草原探索"


func _scaled_pos(pos: Vector3) -> Vector3:
	return Vector3(pos.x * REGION_SCALE, pos.y, pos.z * REGION_SCALE)


func _spread_from_origin(pos: Vector3, origin: Vector3, scale: float) -> Vector3:
	return origin + (pos - origin) * scale


func _route_scaled_pos(pos: Vector3) -> Vector3:
	var spawn := Vector3(current_layout.get("spawn", Vector3.ZERO))
	return _spread_from_origin(_scaled_pos(pos), spawn, ROUTE_POINT_SPREAD_SCALE)


func _layout_scaled_pos(pos: Vector3, factor: float = LAYOUT_SPREAD_SCALE) -> Vector3:
	var spawn := Vector3(current_layout.get("spawn", Vector3.ZERO))
	return _spread_from_origin(_scaled_pos(pos), spawn, factor)


func _scaled_size(size: Vector3) -> Vector3:
	return Vector3(size.x * REGION_SCALE, size.y * 1.08, size.z * REGION_SCALE)


func _scaled_layout(layout: Dictionary) -> Dictionary:
	var scaled_spawn := _scaled_pos(layout.get("spawn", Vector3.ZERO))
	var scaled := {
		"spawn": scaled_spawn,
		"hotspots": {},
		"obstacles": [],
		"props": {
			"trees": [],
			"palms": [],
			"shrubs": [],
			"reeds": [],
		},
	}
	var hotspot_map: Dictionary = layout.get("hotspots", {})
	for hotspot_id in hotspot_map.keys():
		scaled["hotspots"][hotspot_id] = _spread_from_origin(_scaled_pos(hotspot_map[hotspot_id]), scaled_spawn, LAYOUT_SPREAD_SCALE)
	for obstacle in layout.get("obstacles", []):
		scaled["obstacles"].append(
			{
				"pos": _spread_from_origin(_scaled_pos(obstacle.get("pos", Vector3.ZERO)), scaled_spawn, lerpf(1.0, LAYOUT_SPREAD_SCALE, 0.82)),
				"size": _scaled_size(obstacle.get("size", Vector3.ONE)),
				"kind": str(obstacle.get("kind", "rock")),
			}
		)
	var props: Dictionary = layout.get("props", {})
	for key in ["trees", "palms", "shrubs", "reeds"]:
		var scaled_positions: Array = []
		for pos in props.get(key, []):
			scaled_positions.append(_spread_from_origin(_scaled_pos(pos as Vector3), scaled_spawn, lerpf(1.0, LAYOUT_SPREAD_SCALE, 0.68)))
		scaled["props"][key] = scaled_positions
	return scaled


func _scaled_exit_layouts() -> Array:
	var layouts: Array = []
	var scaled_spawn := Vector3(current_layout.get("spawn", _scaled_pos(REGION_LAYOUTS.get(current_biome, REGION_LAYOUTS["grassland"]).get("spawn", Vector3.ZERO))))
	for layout in EXIT_LAYOUTS:
		var scaled_pos := _scaled_pos(layout.get("pos", Vector3.ZERO))
		var scaled_gate_spawn := _scaled_pos(layout.get("spawn", Vector3.ZERO))
		layouts.append(
			{
				"id": str(layout.get("id", "")),
				"pos": _spread_from_origin(scaled_pos, scaled_spawn, lerpf(1.0, LAYOUT_SPREAD_SCALE, 0.9)),
				"spawn": _spread_from_origin(scaled_gate_spawn, scaled_spawn, lerpf(1.0, LAYOUT_SPREAD_SCALE, 0.72)),
				"hint": str(layout.get("hint", "")),
			}
		)
	return layouts


func _compute_world_bounds() -> Rect2:
	var min_x := INF
	var min_z := INF
	var max_x := -INF
	var max_z := -INF
	var include_point := func(pos3: Vector3) -> void:
		min_x = minf(min_x, pos3.x)
		min_z = minf(min_z, pos3.z)
		max_x = maxf(max_x, pos3.x)
		max_z = maxf(max_z, pos3.z)

	include_point.call(Vector3(current_layout.get("spawn", Vector3.ZERO)))
	var hotspot_map: Dictionary = current_layout.get("hotspots", {})
	for hotspot_id in hotspot_map.keys():
		include_point.call(Vector3(hotspot_map[hotspot_id]))
	for obstacle in current_layout.get("obstacles", []):
		var pos3 := Vector3(obstacle.get("pos", Vector3.ZERO))
		var size3 := Vector3(obstacle.get("size", Vector3.ONE))
		include_point.call(pos3 + Vector3(size3.x * 0.5, 0.0, size3.z * 0.5))
		include_point.call(pos3 - Vector3(size3.x * 0.5, 0.0, size3.z * 0.5))
	var props: Dictionary = current_layout.get("props", {})
	for key in props.keys():
		for pos in props.get(key, []):
			include_point.call(pos as Vector3)
	for exit_layout in current_exit_layouts:
		include_point.call(Vector3(exit_layout.get("pos", Vector3.ZERO)))
		include_point.call(Vector3(exit_layout.get("spawn", Vector3.ZERO)))
	if min_x == INF or min_z == INF:
		return WORLD_BOUNDS
	var margin_x := 24.0 * REGION_DISTANCE_SCALE
	var margin_z := 20.0 * REGION_DISTANCE_SCALE
	var rect := Rect2(
		min_x - margin_x,
		min_z - margin_z,
		(max_x - min_x) + margin_x * 2.0,
		(max_z - min_z) + margin_z * 2.0
	)
	var merged_min_x := minf(rect.position.x, WORLD_BOUNDS.position.x)
	var merged_min_z := minf(rect.position.y, WORLD_BOUNDS.position.y)
	var merged_max_x := maxf(rect.end.x, WORLD_BOUNDS.end.x)
	var merged_max_z := maxf(rect.end.y, WORLD_BOUNDS.end.y)
	return Rect2(merged_min_x, merged_min_z, merged_max_x - merged_min_x, merged_max_z - merged_min_z)


func _world_spread_scale() -> float:
	var width_scale := current_world_bounds.size.x / maxf(WORLD_BOUNDS.size.x, 1.0)
	var depth_scale := current_world_bounds.size.y / maxf(WORLD_BOUNDS.size.y, 1.0)
	var dominant_scale := maxf(width_scale, depth_scale)
	return clampf(lerpf(1.0, dominant_scale, 0.52), 1.0, 1.24)


func _anchor_for_species(species_id: String) -> String:
	var dynamic_category := _category_for_species(species_id)
	var dynamic_cluster := _dynamic_cluster_profile(dynamic_category)
	var dynamic_anchor := str(dynamic_cluster.get("preferred_anchor", ""))
	if dynamic_anchor != "":
		return dynamic_anchor
	var is_wetland := current_biome == "wetland"
	var is_forest := current_biome == "forest"
	var is_coast := current_biome == "coast"
	if species_id in ["lion", "hyena", "wolf", "fox"]:
		if is_forest:
			return "shade_grove"
		if is_wetland:
			return "carrion_field"
		return "predator_ridge"
	if species_id in ["vulture", "eagle", "duck", "sparrow"]:
		if is_coast:
			return "migration_corridor"
		if is_wetland:
			return "waterhole"
		return "carrion_field"
	if species_id in ["small_fish", "minnow", "carp", "catfish", "blackfish", "pike", "pufferfish", "shrimp", "crab", "frog", "hippopotamus"]:
		return "waterhole"
	if species_id in ["african_elephant", "white_rhino", "giraffe", "zebra", "antelope", "deer", "rabbit", "boar", "wild_boar"]:
		if is_wetland:
			return "waterhole"
		if is_forest:
			return "shade_grove"
		return "migration_corridor"
	return "waterhole" if is_coast else "shade_grove"


func _wildlife_radius_for(index: int, species_id: String, category: String) -> Vector2:
	var radius := Vector2(3.2 + float(index % 4) * 1.1, 2.2 + float(index % 3) * 0.9)
	match current_biome:
		"wetland":
			if category == "水域动物":
				radius = Vector2(2.4 + float(index % 3) * 0.8, 1.8 + float(index % 2) * 0.6)
			elif category == "飞行动物":
				radius = Vector2(4.2 + float(index % 3) * 1.0, 3.0 + float(index % 2) * 0.8)
			elif category == "草食动物":
				radius = Vector2(2.8 + float(index % 3) * 0.9, 2.0 + float(index % 2) * 0.6)
		"forest":
			if category == "草食动物":
				radius = Vector2(2.6 + float(index % 3) * 0.8, 1.9 + float(index % 2) * 0.6)
			elif category == "掠食者":
				radius = Vector2(2.8 + float(index % 3) * 0.7, 2.0 + float(index % 2) * 0.5)
			elif category == "飞行动物":
				radius = Vector2(3.4 + float(index % 3) * 0.9, 2.6 + float(index % 2) * 0.7)
		"coast":
			if category == "飞行动物":
				radius = Vector2(5.0 + float(index % 3) * 1.2, 3.2 + float(index % 2) * 0.9)
			elif category == "水域动物":
				radius = Vector2(3.2 + float(index % 3) * 1.0, 2.2 + float(index % 2) * 0.7)
			elif category == "草食动物":
				radius = Vector2(3.4 + float(index % 3) * 0.9, 2.4 + float(index % 2) * 0.7)
		_:
			if category == "草食动物":
				radius = Vector2(4.6 + float(index % 3) * 1.2, 3.0 + float(index % 2) * 0.9)
			elif category == "掠食者":
				radius = Vector2(3.4 + float(index % 3) * 0.9, 2.4 + float(index % 2) * 0.6)
	return radius * lerpf(1.0, REGION_DISTANCE_SCALE, 0.78)


func _wildlife_speed_for(index: int, species_id: String, category: String) -> float:
	var speed := 0.34 + float((index % 5) + 1) * 0.07
	match current_biome:
		"wetland":
			if category == "水域动物":
				speed *= 0.88
			elif category == "飞行动物":
				speed *= 1.06
		"forest":
			if category == "草食动物":
				speed *= 0.92
			elif category == "掠食者":
				speed *= 0.98
		"coast":
			if category == "飞行动物":
				speed *= 1.14
			elif category == "水域动物":
				speed *= 0.96
		_:
			if category == "草食动物":
				speed *= 1.04
			elif category == "掠食者":
				speed *= 1.02
	if species_id in ["african_elephant", "white_rhino", "hippopotamus"]:
		speed *= 0.84
	return speed


func _wildlife_alert_radius_for(index: int, species_id: String, category: String, role: String) -> float:
	var radius := 5.5 + float(index % 4) * 1.2
	match current_biome:
		"wetland":
			if category == "飞行动物":
				radius += 1.0
			elif category == "水域动物":
				radius -= 0.4
		"forest":
			radius -= 0.8
			if category == "掠食者":
				radius -= 0.2
		"coast":
			if category == "飞行动物":
				radius += 1.2
			elif category == "草食动物":
				radius += 0.4
		_:
			if category == "草食动物":
				radius += 0.8
			elif category == "掠食者":
				radius += 0.4
	if role in ["leader", "sentry", "alpha"]:
		radius += 0.6
	if species_id in ["rabbit", "sparrow", "duck"]:
		radius += 0.4
	return radius


func _wildlife_route_points(species_id: String, anchor_id: String, category: String, behavior: String) -> Array:
	var points: Array = []
	var spawn: Vector3 = Vector3(current_layout.get("spawn", Vector3.ZERO))
	_append_wildlife_route_point(points, Vector2(spawn.x, spawn.z))
	match behavior:
		"stalk":
			_append_wildlife_route_hotspot(points, "predator_ridge")
			_append_wildlife_route_hotspot(points, "migration_corridor")
			_append_wildlife_route_hotspot(points, "carrion_field")
		"glide":
			_append_wildlife_route_hotspot(points, "carrion_field")
			_append_wildlife_route_hotspot(points, "predator_ridge")
			_append_wildlife_route_hotspot(points, "migration_corridor")
		"swim":
			_append_wildlife_route_hotspot(points, "waterhole")
			var waterhole := _hotspot_pos("waterhole")
			_append_wildlife_route_point(points, Vector2(waterhole.x + 8.0 * REGION_DISTANCE_SCALE, waterhole.z + 4.0 * REGION_DISTANCE_SCALE))
			_append_wildlife_route_point(points, Vector2(waterhole.x - 7.0 * REGION_DISTANCE_SCALE, waterhole.z - 3.5 * REGION_DISTANCE_SCALE))
		"heavy_roam":
			_append_wildlife_route_hotspot(points, anchor_id)
			_append_wildlife_route_hotspot(points, "waterhole")
			_append_wildlife_route_hotspot(points, "migration_corridor")
		_:
			_append_wildlife_route_hotspot(points, anchor_id)
			_append_wildlife_route_hotspot(points, "waterhole")
			_append_wildlife_route_hotspot(points, "migration_corridor")
			if category == "草食动物":
				_append_wildlife_route_hotspot(points, "shade_grove")
			elif category == "掠食者":
				_append_wildlife_route_hotspot(points, "predator_ridge")
			elif category == "飞行动物":
				_append_wildlife_route_hotspot(points, "carrion_field")
	if species_id in ["african_elephant", "giraffe", "zebra", "antelope", "deer"]:
		_append_wildlife_route_hotspot(points, "shade_grove")
	if points.size() < 2:
		_append_wildlife_route_hotspot(points, anchor_id)
	return points


func _append_wildlife_route_hotspot(points: Array, hotspot_id: String) -> void:
	if hotspot_id == "":
		return
	var hotspot := _hotspot_pos(hotspot_id)
	_append_wildlife_route_point(points, Vector2(hotspot.x, hotspot.z))


func _append_wildlife_route_point(points: Array, point: Vector2) -> void:
	if point == Vector2.ZERO and not points.is_empty():
		return
	for existing in points:
		if Vector2(existing).distance_to(point) < 1.8:
			return
	points.append(point)


func _group_size_for_species(species_id: String, category: String, count: int) -> int:
	if species_id in ["zebra", "antelope", "deer"]:
		return clampi(int(round(count / 4.0)), 3, 6)
	if species_id in ["vulture", "duck", "sparrow", "eagle"]:
		return clampi(int(round(count / 3.0)), 2, 5)
	if species_id in ["lion", "hyena"]:
		return clampi(int(round(count / 2.0)), 1, 3)
	if category == "水域动物":
		return clampi(int(round(count / 4.0)), 2, 5)
	return clampi(int(round(count / 5.0)), 1, 4)


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


func _material(color: Color, alpha_override: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha_override)
	material.roughness = 0.9
	material.metallic = 0.0
	material.clearcoat = 0.0
	material.subsurf_scatter_strength = 0.06 if alpha_override >= 0.9 else 0.0
	material.vertex_color_use_as_albedo = false
	if alpha_override < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	return mesh_instance


func _soft_obstacle_mesh(size: Vector3, color: Color, kind: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	if kind in ["water", "marsh"]:
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh_instance.mesh = mesh
	else:
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh_instance.mesh = mesh
		var height_scale := 1.4 if kind in ["ridge", "coast_ridge"] else 1.1
		mesh_instance.scale = Vector3(size.x, maxf(0.08, size.y * height_scale), size.z)
	mesh_instance.material_override = _material(color)
	return mesh_instance


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func elapsed_time() -> float:
	return Time.get_ticks_msec() / 1000.0

extends Node3D

const ANTELOPE_SCENE := preload("res://assets/fauna/antelope/antelope_actor.tscn")
const LION_SCENE := preload("res://assets/fauna/lion/lion_actor.tscn")

var actors: Array[Dictionary] = []


func _ready() -> void:
	_build_test_world()
	_spawn_actor(ANTELOPE_SCENE, Vector3(-2.2, 0.0, 0.0), 0.0, 1.0)
	_spawn_actor(ANTELOPE_SCENE, Vector3(-0.2, 0.0, -0.8), 0.9, 0.92)
	_spawn_actor(LION_SCENE, Vector3(2.2, 0.0, 0.2), PI, 1.0)
	_spawn_actor(LION_SCENE, Vector3(4.0, 0.0, -0.6), PI + 0.4, 0.96)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for actor_data in actors:
		_animate_actor(actor_data, t)


func _build_test_world() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 3.6, 8.8)
	camera.rotation = Vector3(-0.24, 0.0, 0.0)
	add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-46.0, 28.0, 0.0)
	light.light_energy = 1.35
	add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 2.8, 3.0)
	fill.light_energy = 0.35
	add_child(fill)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 12.0)
	ground.mesh = plane
	ground.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	ground.material_override = _mat(Color(0.63, 0.56, 0.41, 1.0))
	add_child(ground)


func _spawn_actor(scene: PackedScene, base_pos: Vector3, phase: float, scale_value: float) -> void:
	var actor := scene.instantiate() as Node3D
	actor.position = base_pos
	actor.scale = Vector3.ONE * scale_value
	add_child(actor)
	actors.append(
		{
			"node": actor,
			"base_pos": base_pos,
			"phase": phase,
			"body": actor.find_child("BodyRig", true, false),
			"head": actor.find_child("HeadRig", true, false),
		}
	)


func _animate_actor(actor_data: Dictionary, t: float) -> void:
	var actor := actor_data.get("node", null) as Node3D
	if actor == null:
		return
	var body := actor_data.get("body", null) as Node3D
	var head := actor_data.get("head", null) as Node3D
	var base_pos := actor_data.get("base_pos", Vector3.ZERO) as Vector3
	var phase := float(actor_data.get("phase", 0.0))
	var gait := t * 4.2 + phase
	var bob := sin(gait * 2.0) * 0.04
	var pitch := sin(gait) * 0.05
	actor.position = base_pos + Vector3(sin(t * 0.36 + phase) * 0.35, 0.0, cos(t * 0.28 + phase) * 0.18)
	if body != null:
		if not body.has_meta("base_pos"):
			body.set_meta("base_pos", body.position)
		var body_base := body.get_meta("base_pos", body.position) as Vector3
		body.position = body_base + Vector3(0.0, bob, 0.0)
		body.rotation.x = pitch
		for leg_name in ["FrontLeft", "FrontRight", "BackLeft", "BackRight"]:
			var leg := body.get_node_or_null("Leg_%s" % leg_name) as Node3D
			if leg == null:
				continue
			var knee := leg.get_node_or_null("Knee") as Node3D
			if not leg.has_meta("base_pos"):
				leg.set_meta("base_pos", leg.position)
			var leg_base := leg.get_meta("base_pos", leg.position) as Vector3
			var swing_sign := 1.0 if leg_name in ["FrontLeft", "BackRight"] else -1.0
			var swing := sin(gait * swing_sign) * 0.62
			var lift := maxf(0.0, sin(gait * swing_sign + PI * 0.5))
			leg.position = leg_base + Vector3(0.0, lift * 0.08, swing * 0.05)
			leg.rotation.x = swing
			if knee != null:
				if not knee.has_meta("base_pos"):
					knee.set_meta("base_pos", knee.position)
				var knee_base := knee.get_meta("base_pos", knee.position) as Vector3
				knee.position = knee_base + Vector3(0.0, lift * 0.05, swing * 0.02)
				knee.rotation.x = -lift * 0.9
	if head != null:
		head.rotation.y = sin(t * 0.9 + phase) * 0.12
		head.rotation.x = -0.04 + cos(t * 0.7 + phase) * 0.04


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat

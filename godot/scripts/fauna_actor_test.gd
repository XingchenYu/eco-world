extends Node3D

const ANTELOPE_SCENE := preload("res://assets/fauna/antelope/antelope_actor.tscn")
const LION_SCENE := preload("res://assets/fauna/lion/lion_actor.tscn")
const ZEBRA_SCENE := preload("res://assets/fauna/zebra/zebra_actor.tscn")
const CANID_SCENE := preload("res://assets/fauna/canid/canid_actor.tscn")
const GIRAFFE_SCENE := preload("res://assets/fauna/giraffe/giraffe_actor.tscn")
const ELEPHANT_SCENE := preload("res://assets/fauna/african_elephant/african_elephant_actor.tscn")
const CROCODILE_SCENE := preload("res://assets/fauna/nile_crocodile/nile_crocodile_actor.tscn")
const VULTURE_SCENE := preload("res://assets/fauna/vulture/vulture_actor.tscn")

var actors: Array[Dictionary] = []


func _ready() -> void:
	_build_test_world()
	_spawn_actor(ANTELOPE_SCENE, Vector3(-2.2, 0.0, 0.0), 0.0, 1.0)
	_spawn_actor(ANTELOPE_SCENE, Vector3(-0.2, 0.0, -0.8), 0.9, 0.92)
	_spawn_actor(LION_SCENE, Vector3(2.2, 0.0, 0.2), PI, 1.0)
	_spawn_actor(LION_SCENE, Vector3(4.0, 0.0, -0.6), PI + 0.4, 0.96)
	_spawn_actor(ZEBRA_SCENE, Vector3(-4.4, 0.0, 0.6), 0.5, 1.0)
	_spawn_actor(CANID_SCENE, Vector3(5.8, 0.0, 0.5), PI + 0.8, 0.94)
	_spawn_actor(GIRAFFE_SCENE, Vector3(-6.8, 0.0, -0.8), 0.2, 1.02)
	_spawn_actor(ELEPHANT_SCENE, Vector3(8.6, 0.0, -0.2), PI + 0.15, 1.0)
	_spawn_actor(CROCODILE_SCENE, Vector3(-2.8, 0.0, 2.0), 0.4, 1.0)
	_spawn_actor(VULTURE_SCENE, Vector3(2.4, 0.0, 2.2), PI + 0.6, 1.0)


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
	var grounded_pos := _grounded_actor_position(actor, base_pos)
	actor.position = grounded_pos
	actors.append(
		{
			"node": actor,
			"base_pos": grounded_pos,
			"phase": phase,
			"body": actor.find_child("BodyRig", true, false),
			"head": actor.find_child("HeadRig", true, false),
			"profile": _actor_profile(actor.name),
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
	var profile := actor_data.get("profile", _actor_profile(actor.name)) as Dictionary
	var move_speed := float(profile.get("move_speed", 0.34))
	var move_width := float(profile.get("move_width", 0.35))
	var move_depth := float(profile.get("move_depth", 0.18))
	var gait_speed := float(profile.get("gait_speed", 4.2))
	var bob_amp := float(profile.get("bob_amp", 0.04))
	var pitch_amp := float(profile.get("pitch_amp", 0.05))
	var head_yaw_amp := float(profile.get("head_yaw_amp", 0.12))
	var head_pitch_base := float(profile.get("head_pitch_base", -0.04))
	var head_pitch_amp := float(profile.get("head_pitch_amp", 0.04))
	var wing_flap_amp := float(profile.get("wing_flap_amp", 0.0))
	var wing_flap_speed := float(profile.get("wing_flap_speed", 0.0))
	var body_roll_amp := float(profile.get("body_roll_amp", 0.0))
	var gait := t * gait_speed + phase
	var bob := sin(gait * 2.0) * bob_amp
	var pitch := sin(gait) * pitch_amp
	var roll := sin(gait * 0.5) * body_roll_amp
	actor.position = base_pos + Vector3(sin(t * 0.36 + phase) * 0.35, 0.0, cos(t * 0.28 + phase) * 0.18)
	actor.position = base_pos + Vector3(sin(t * move_speed + phase) * move_width, 0.0, cos(t * move_speed * 0.78 + phase) * move_depth)
	if body != null:
		if not body.has_meta("base_pos"):
			body.set_meta("base_pos", body.position)
		var body_base := body.get_meta("base_pos", body.position) as Vector3
		body.position = body_base + Vector3(0.0, bob, 0.0)
		body.rotation.x = pitch
		body.rotation.z = roll
		if wing_flap_amp > 0.0:
			var left_wing := body.get_node_or_null("WingLeft") as Node3D
			var right_wing := body.get_node_or_null("WingRight") as Node3D
			var flap := sin(t * wing_flap_speed + phase) * wing_flap_amp
			if left_wing != null:
				left_wing.rotation.z = -0.14 + flap
			if right_wing != null:
				right_wing.rotation.z = 0.14 - flap
		for leg_name in _actor_leg_names(actor.name):
			var leg := body.get_node_or_null("Leg_%s" % leg_name) as Node3D
			if leg == null:
				continue
			var knee := leg.get_node_or_null("Knee") as Node3D
			if not leg.has_meta("base_pos"):
				leg.set_meta("base_pos", leg.position)
			var leg_base := leg.get_meta("base_pos", leg.position) as Vector3
			var swing_sign := _actor_leg_phase_sign(actor.name, leg_name)
			var swing := sin(gait * swing_sign) * float(profile.get("leg_swing_amp", 0.62))
			var lift := maxf(0.0, sin(gait * swing_sign + PI * 0.5))
			leg.position = leg_base + Vector3(0.0, lift * float(profile.get("leg_lift_amp", 0.08)), swing * float(profile.get("leg_stride_amp", 0.05)))
			leg.rotation.x = swing
			leg.rotation.z = swing * float(profile.get("leg_splay_amp", 0.0))
			if knee != null:
				if not knee.has_meta("base_pos"):
					knee.set_meta("base_pos", knee.position)
				var knee_base := knee.get_meta("base_pos", knee.position) as Vector3
				knee.position = knee_base + Vector3(0.0, lift * float(profile.get("knee_lift_amp", 0.05)), swing * float(profile.get("knee_stride_amp", 0.02)))
				knee.rotation.x = -lift * float(profile.get("knee_bend_amp", 0.9))
	if head != null:
		head.rotation.y = sin(t * 0.9 + phase) * head_yaw_amp
		head.rotation.x = head_pitch_base + cos(t * 0.7 + phase) * head_pitch_amp


func _actor_profile(actor_name: String) -> Dictionary:
	var profile := {
		"move_speed": 0.34,
		"move_width": 0.35,
		"move_depth": 0.18,
		"gait_speed": 4.2,
		"bob_amp": 0.04,
		"pitch_amp": 0.05,
		"leg_swing_amp": 0.62,
		"leg_lift_amp": 0.08,
		"leg_stride_amp": 0.05,
		"knee_lift_amp": 0.05,
		"knee_stride_amp": 0.02,
		"knee_bend_amp": 0.9,
		"head_yaw_amp": 0.12,
		"head_pitch_base": -0.04,
		"head_pitch_amp": 0.04,
		"wing_flap_amp": 0.0,
		"wing_flap_speed": 0.0,
		"body_roll_amp": 0.0,
		"leg_splay_amp": 0.0,
	}
	if actor_name.contains("Elephant"):
		profile["move_speed"] = 0.22
		profile["move_width"] = 0.24
		profile["move_depth"] = 0.12
		profile["gait_speed"] = 2.2
		profile["bob_amp"] = 0.028
		profile["pitch_amp"] = 0.03
		profile["leg_swing_amp"] = 0.42
		profile["leg_lift_amp"] = 0.05
		profile["leg_stride_amp"] = 0.03
		profile["knee_lift_amp"] = 0.03
		profile["knee_stride_amp"] = 0.012
		profile["knee_bend_amp"] = 0.56
		profile["head_yaw_amp"] = 0.06
		profile["head_pitch_base"] = -0.02
		profile["head_pitch_amp"] = 0.02
		profile["body_roll_amp"] = 0.012
	elif actor_name.contains("Giraffe"):
		profile["move_speed"] = 0.28
		profile["move_width"] = 0.28
		profile["move_depth"] = 0.14
		profile["gait_speed"] = 2.9
		profile["bob_amp"] = 0.03
		profile["pitch_amp"] = 0.035
		profile["leg_swing_amp"] = 0.48
		profile["leg_lift_amp"] = 0.06
		profile["leg_stride_amp"] = 0.04
		profile["knee_bend_amp"] = 0.72
		profile["head_yaw_amp"] = 0.08
		profile["body_roll_amp"] = 0.01
	elif actor_name.contains("Crocodile"):
		profile["move_speed"] = 0.18
		profile["move_width"] = 0.18
		profile["move_depth"] = 0.1
		profile["gait_speed"] = 2.0
		profile["bob_amp"] = 0.012
		profile["pitch_amp"] = 0.018
		profile["leg_swing_amp"] = 0.26
		profile["leg_lift_amp"] = 0.028
		profile["leg_stride_amp"] = 0.02
		profile["knee_lift_amp"] = 0.016
		profile["knee_stride_amp"] = 0.008
		profile["knee_bend_amp"] = 0.38
		profile["head_yaw_amp"] = 0.05
		profile["head_pitch_base"] = 0.02
		profile["head_pitch_amp"] = 0.015
		profile["body_roll_amp"] = 0.02
		profile["leg_splay_amp"] = 0.08
	elif actor_name.contains("Vulture"):
		profile["move_speed"] = 0.3
		profile["move_width"] = 0.22
		profile["move_depth"] = 0.12
		profile["gait_speed"] = 3.2
		profile["bob_amp"] = 0.02
		profile["pitch_amp"] = 0.025
		profile["leg_swing_amp"] = 0.18
		profile["leg_lift_amp"] = 0.02
		profile["leg_stride_amp"] = 0.015
		profile["knee_lift_amp"] = 0.01
		profile["knee_stride_amp"] = 0.006
		profile["knee_bend_amp"] = 0.24
		profile["head_yaw_amp"] = 0.08
		profile["head_pitch_base"] = -0.02
		profile["head_pitch_amp"] = 0.03
		profile["wing_flap_amp"] = 0.18
		profile["wing_flap_speed"] = 3.8
		profile["body_roll_amp"] = 0.06
	elif actor_name.contains("Lion"):
		profile["move_speed"] = 0.32
		profile["move_width"] = 0.32
		profile["move_depth"] = 0.16
		profile["gait_speed"] = 3.6
		profile["bob_amp"] = 0.038
		profile["pitch_amp"] = 0.045
		profile["leg_swing_amp"] = 0.68
		profile["leg_lift_amp"] = 0.085
		profile["leg_stride_amp"] = 0.055
		profile["knee_bend_amp"] = 0.96
		profile["body_roll_amp"] = 0.016
	elif actor_name.contains("Canid"):
		profile["move_speed"] = 0.38
		profile["move_width"] = 0.38
		profile["move_depth"] = 0.18
		profile["gait_speed"] = 4.8
		profile["bob_amp"] = 0.034
		profile["pitch_amp"] = 0.04
		profile["leg_swing_amp"] = 0.76
		profile["leg_lift_amp"] = 0.09
		profile["leg_stride_amp"] = 0.06
		profile["knee_bend_amp"] = 1.02
		profile["body_roll_amp"] = 0.018
	elif actor_name.contains("Zebra"):
		profile["move_speed"] = 0.34
		profile["move_width"] = 0.34
		profile["move_depth"] = 0.18
		profile["gait_speed"] = 4.0
		profile["leg_swing_amp"] = 0.7
		profile["leg_lift_amp"] = 0.085
		profile["leg_stride_amp"] = 0.055
		profile["knee_bend_amp"] = 0.98
		profile["body_roll_amp"] = 0.014
	elif actor_name.contains("Antelope"):
		profile["move_speed"] = 0.42
		profile["move_width"] = 0.42
		profile["move_depth"] = 0.2
		profile["gait_speed"] = 5.2
		profile["bob_amp"] = 0.042
		profile["pitch_amp"] = 0.05
		profile["leg_swing_amp"] = 0.84
		profile["leg_lift_amp"] = 0.1
		profile["leg_stride_amp"] = 0.065
		profile["knee_bend_amp"] = 1.08
		profile["head_yaw_amp"] = 0.14
		profile["body_roll_amp"] = 0.018
	return profile


func _actor_leg_names(actor_name: String) -> Array[String]:
	if actor_name.contains("Vulture"):
		return ["Left", "Right"]
	return ["FrontLeft", "FrontRight", "BackLeft", "BackRight"]


func _actor_leg_phase_sign(actor_name: String, leg_name: String) -> float:
	if actor_name.contains("Vulture"):
		return 1.0 if leg_name == "Left" else -1.0
	if actor_name.contains("Crocodile"):
		return 1.0 if leg_name in ["FrontLeft", "BackLeft"] else -1.0
	return 1.0 if leg_name in ["FrontLeft", "BackRight"] else -1.0


func _grounded_actor_position(actor: Node3D, base_pos: Vector3) -> Vector3:
	var min_y := _actor_min_world_y(actor)
	if is_inf(min_y):
		return base_pos
	return base_pos + Vector3(0.0, -min_y, 0.0)


func _actor_min_world_y(root: Node3D) -> float:
	var found := false
	var min_y := INF
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D:
			var mesh_instance := current as MeshInstance3D
			if mesh_instance.mesh != null:
				var aabb: AABB = mesh_instance.mesh.get_aabb()
				for x in [aabb.position.x, aabb.position.x + aabb.size.x]:
					for y in [aabb.position.y, aabb.position.y + aabb.size.y]:
						for z in [aabb.position.z, aabb.position.z + aabb.size.z]:
							var world_point: Vector3 = mesh_instance.to_global(Vector3(x, y, z))
							min_y = minf(min_y, world_point.y)
							found = true
		for child in current.get_children():
			stack.append(child)
	return min_y if found else INF


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return mat

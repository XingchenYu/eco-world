extends Control

const MAP_TEXTURE_PATH := "res://assets/ui/world_map/arelian_world_map.png"

var regions: Array = []
var active_region_id := ""
var target_region_id := ""
var region_layout := {}
var region_colors := {}
var map_texture: Texture2D
var ui_font: Font


func configure(p_regions: Array, p_active_region_id: String, p_target_region_id: String, p_region_layout: Dictionary, p_region_colors: Dictionary) -> void:
	regions = p_regions
	active_region_id = p_active_region_id
	target_region_id = p_target_region_id
	region_layout = p_region_layout
	region_colors = p_region_colors
	queue_redraw()


func _draw() -> void:
	var map_size := size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	_draw_map_texture(map_size)
	_draw_biome_washes(map_size)
	_draw_region_markers(map_size)


func _draw_map_texture(map_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color8(22, 54, 61), true)
	if map_texture == null:
		var map_image := Image.load_from_file(MAP_TEXTURE_PATH)
		if map_image != null:
			map_texture = ImageTexture.create_from_image(map_image)
	if map_texture == null:
		return
	draw_texture_rect(map_texture, Rect2(Vector2.ZERO, map_size), false)


func _draw_region_markers(map_size: Vector2) -> void:
	if ui_font == null:
		ui_font = ThemeDB.fallback_font
	for region_variant in regions:
		var region: Dictionary = region_variant
		var region_id := str(region.get("id", ""))
		if not region_layout.has(region_id):
			continue
		var pos := _region_position(region_id, map_size)
		var accent: Color = region_colors.get(region_id, Color8(170, 178, 160))
		var active := region_id == active_region_id
		var target := region_id == target_region_id
		var radius := 7.4 if active else 5.0
		draw_circle(pos + Vector2(1.2, 1.6), radius + 1.8, Color(0.05, 0.06, 0.05, 0.18))
		if active:
			draw_circle(pos, 22.0, Color(accent.r, accent.g, accent.b, 0.13))
			draw_arc(pos, 18.0, 0.0, TAU, 54, Color(0.98, 0.88, 0.50, 0.46), 1.6, true)
		elif target:
			draw_arc(pos, 14.0, 0.0, TAU, 40, Color(0.70, 0.92, 1.0, 0.34), 1.2, true)
		draw_circle(pos, radius, Color(accent.r, accent.g, accent.b, 0.92))
		draw_arc(pos, radius + 2.0, 0.0, TAU, 32, Color(0.96, 0.93, 0.80, 0.36 if active else 0.18), 0.8, true)
		_draw_region_label(region, pos, accent, active, target)


func _draw_biome_washes(map_size: Vector2) -> void:
	for region_variant in regions:
		var region: Dictionary = region_variant
		var region_id := str(region.get("id", ""))
		if not region_layout.has(region_id):
			continue
		var pos := _region_position(region_id, map_size)
		var tint := _biome_tint(region)
		var active := region_id == active_region_id
		var base_radius := 88.0 if active else 66.0
		for ring in range(4):
			var radius := base_radius + float(ring) * 34.0
			var alpha := (0.060 if active else 0.034) / float(ring + 1)
			draw_circle(pos, radius, Color(tint.r, tint.g, tint.b, alpha))


func _draw_region_label(region: Dictionary, pos: Vector2, accent: Color, active: bool, target: bool) -> void:
	if ui_font == null:
		return
	var label := str(region.get("name", region.get("id", "")))
	var label_pos := pos + Vector2(12, -10)
	var font_size := 15 if active else 12
	var label_color := Color8(246, 241, 220, 238 if active else 178)
	_draw_map_text(label_pos + Vector2(1, 1), label, font_size, Color(0.02, 0.03, 0.03, 0.42))
	_draw_map_text(label_pos, label, font_size, label_color)
	if active:
		var stat := "多样性 %s  韧性 %s" % [
			_percent(float(region.get("biodiversity", 0.0))),
			_percent(float(region.get("resilience", 0.0))),
		]
		_draw_map_text(label_pos + Vector2(0, 18), stat, 11, Color8(236, 229, 198, 205))
	elif target:
		_draw_map_text(label_pos + Vector2(0, 15), "通道目标", 10, Color(accent.r, accent.g, accent.b, 0.78))


func _draw_map_text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(ui_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _biome_tint(region: Dictionary) -> Color:
	var biomes: Array = region.get("dominant_biomes", [])
	if "coral_reef" in biomes or "seagrass" in biomes:
		return Color8(78, 168, 196)
	if "coast" in biomes or "estuary" in biomes:
		return Color8(94, 158, 202)
	if "wetland" in biomes or "lake_shore" in biomes or "floodplain" in biomes:
		return Color8(78, 164, 150)
	if "temperate_forest" in biomes or "mixed_forest" in biomes or "tropical_rainforest" in biomes:
		return Color8(68, 148, 92)
	return Color8(206, 176, 92)


func _percent(value: float) -> String:
	return "%d%%" % int(round(clampf(value, 0.0, 1.0) * 100.0))


func _region_position(region_id: String, map_size: Vector2) -> Vector2:
	var rel: Vector2 = region_layout.get(region_id, Vector2(0.5, 0.5))
	return Vector2(map_size.x * rel.x, map_size.y * rel.y)

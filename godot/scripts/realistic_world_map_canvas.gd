extends Control

const MAP_TEXTURE_PATH := "res://assets/ui/world_map/arelian_world_map.png"

var regions: Array = []
var active_region_id := ""
var target_region_id := ""
var priority_region_id := ""
var region_layout := {}
var region_colors := {}
var map_texture: Texture2D
var ui_font: Font


func configure(p_regions: Array, p_active_region_id: String, p_target_region_id: String, p_region_layout: Dictionary, p_region_colors: Dictionary, p_priority_region_id: String = "") -> void:
	regions = p_regions
	active_region_id = p_active_region_id
	target_region_id = p_target_region_id
	priority_region_id = p_priority_region_id
	region_layout = p_region_layout
	region_colors = p_region_colors
	queue_redraw()


func _draw() -> void:
	var map_size := size
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		map_size = Vector2(1040, 720)

	_draw_map_texture(map_size)
	_draw_map_atmosphere(map_size)
	_draw_region_markers(map_size)
	_draw_map_furniture(map_size)


func _draw_map_texture(map_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color8(22, 54, 61), true)
	if map_texture == null:
		var map_image := Image.load_from_file(MAP_TEXTURE_PATH)
		if map_image != null:
			map_texture = ImageTexture.create_from_image(map_image)
	if map_texture == null:
		return
	draw_texture_rect(map_texture, Rect2(Vector2.ZERO, map_size), false)


func _draw_map_atmosphere(map_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.06, 0.08, 0.055, 0.10), true)


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
		var priority := region_id == priority_region_id
		if active:
			_draw_active_pin(pos, accent)
		elif priority:
			draw_circle(pos + Vector2(1.0, 1.4), 6.0, Color(0.03, 0.04, 0.03, 0.28))
			draw_arc(pos, 14.0, 0.0, TAU, 48, Color(1.0, 0.70, 0.18, 0.46), 1.2, true)
			_draw_priority_marker(pos, accent)
		elif target:
			draw_circle(pos + Vector2(1.0, 1.4), 5.6, Color(0.03, 0.04, 0.03, 0.24))
			draw_arc(pos, 12.0, 0.0, TAU, 40, Color(0.70, 0.92, 1.0, 0.40), 1.0, true)
			_draw_target_marker(pos, accent)
		else:
			_draw_minor_marker(pos, accent)
		_draw_region_label(region, pos, accent, active, target, priority)


func _draw_active_pin(pos: Vector2, accent: Color) -> void:
	draw_arc(pos, 18.0, -0.35, TAU - 0.35, 64, Color(0.98, 0.88, 0.50, 0.72), 1.6, true)
	draw_arc(pos, 26.0, 0.55, TAU + 0.55, 64, Color(0.98, 0.88, 0.50, 0.22), 1.0, true)
	var pin_points := PackedVector2Array([
		pos + Vector2(0, 13),
		pos + Vector2(-6, 3),
		pos + Vector2(6, 3),
	])
	draw_colored_polygon(pin_points, Color(0.05, 0.04, 0.02, 0.32))
	draw_circle(pos + Vector2(1.2, 1.7), 8.2, Color(0.03, 0.03, 0.02, 0.34))
	draw_circle(pos, 7.0, Color(0.98, 0.90, 0.54, 0.96))
	draw_circle(pos, 3.0, Color(accent.r, accent.g, accent.b, 0.96))


func _draw_priority_marker(pos: Vector2, accent: Color) -> void:
	var points := PackedVector2Array([
		pos + Vector2(0, -5),
		pos + Vector2(5, 0),
		pos + Vector2(0, 5),
		pos + Vector2(-5, 0),
	])
	draw_colored_polygon(points, Color(1.0, 0.80, 0.30, 0.88))
	draw_circle(pos, 2.0, Color(accent.r, accent.g, accent.b, 0.95))


func _draw_target_marker(pos: Vector2, accent: Color) -> void:
	draw_circle(pos, 4.4, Color(0.82, 0.96, 1.0, 0.72))
	draw_circle(pos, 2.0, Color(accent.r, accent.g, accent.b, 0.90))


func _draw_minor_marker(pos: Vector2, accent: Color) -> void:
	draw_circle(pos + Vector2(1.0, 1.4), 4.8, Color(0.03, 0.04, 0.03, 0.22))
	draw_circle(pos, 3.2, Color(0.96, 0.88, 0.62, 0.70))
	draw_circle(pos, 1.4, Color(accent.r, accent.g, accent.b, 0.86))


func _draw_map_furniture(map_size: Vector2) -> void:
	if ui_font == null:
		ui_font = ThemeDB.fallback_font
	var compass_center := Vector2(map_size.x - 62.0, 58.0)
	draw_line(compass_center + Vector2(0, 18), compass_center + Vector2(0, -20), Color(0.96, 0.90, 0.72, 0.38), 1.2, true)
	draw_line(compass_center + Vector2(-12, 0), compass_center + Vector2(12, 0), Color(0.96, 0.90, 0.72, 0.20), 0.9, true)
	draw_circle(compass_center, 3.0, Color(0.96, 0.90, 0.72, 0.42))
	_draw_map_text(compass_center + Vector2(-5, -26), "N", 11, Color(0.96, 0.90, 0.72, 0.54))
	var scale_origin := Vector2(map_size.x - 168.0, map_size.y - 36.0)
	draw_line(scale_origin, scale_origin + Vector2(104, 0), Color(0.96, 0.90, 0.72, 0.30), 1.2, true)
	draw_line(scale_origin, scale_origin + Vector2(0, -6), Color(0.96, 0.90, 0.72, 0.30), 1.2, true)
	draw_line(scale_origin + Vector2(104, 0), scale_origin + Vector2(104, -6), Color(0.96, 0.90, 0.72, 0.30), 1.2, true)
	_draw_map_text(scale_origin + Vector2(22, -10), "生态区尺度", 9, Color(0.96, 0.90, 0.72, 0.42))


func _draw_region_label(region: Dictionary, pos: Vector2, accent: Color, active: bool, target: bool, priority: bool) -> void:
	if ui_font == null:
		return
	if not active and not target and not priority:
		return
	var label := str(region.get("name", region.get("id", "")))
	var label_pos := pos + Vector2(11, -8)
	var font_size := 14 if active else 11
	var label_color := Color8(248, 241, 219, 236 if active else 188)
	_draw_map_text(label_pos + Vector2(1, 1), label, font_size, Color(0.01, 0.02, 0.015, 0.62))
	_draw_map_text(label_pos, label, font_size, label_color)
	if active:
		var stat := "多样性 %s  韧性 %s" % [
			_percent(float(region.get("biodiversity", 0.0))),
			_percent(float(region.get("resilience", 0.0))),
		]
		_draw_map_text(label_pos + Vector2(0, 17), stat, 10, Color8(242, 232, 196, 214))
	elif priority:
		_draw_map_text(label_pos + Vector2(0, 14), "建议优先", 9, Color8(255, 218, 128, 218))
	elif target:
		_draw_map_text(label_pos + Vector2(0, 14), "通道目标", 9, Color(accent.r, accent.g, accent.b, 0.80))


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

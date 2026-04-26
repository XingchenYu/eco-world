class_name ExplorerAssetBindings
extends RefCounted

static func biome_terrain_scene_path(biome: String) -> String:
	return ""


static func biome_vegetation_scene_path(biome: String) -> String:
	return ""


static func biome_real_surface_texture_paths(biome: String) -> Dictionary:
	return {}


static func biome_has_real_surface_textures(biome: String) -> bool:
	return false


static func biome_real_vegetation_scene_path(biome: String, kind: String) -> String:
	return ""


static func biome_real_vegetation_scene_paths(biome: String) -> Dictionary:
	return {}


static func biome_has_real_vegetation(biome: String) -> bool:
	return false


static func biome_real_hdri_path(biome: String) -> String:
	return ""


static func species_scene_path(species_id: String) -> String:
	return ""


static func scene_import_candidates(scene_stub: String) -> Array[String]:
	return []


static func resolve_scene_path(scene_stub: String) -> String:
	return ""


static func resolve_resource_path(resource_path: String) -> String:
	return ""


static func instantiate_scene(scene_path: String) -> Node:
	return null

class_name ExplorerAssetBindings
extends RefCounted

const SCENE_IMPORT_EXTENSIONS := [".glb", ".gltf", ".tscn"]

const BIOME_TERRAIN_ASSET_SCENES := {
	"grassland": "res://assets/terrain/grassland/grassland_terrain",
	"wetland": "res://assets/terrain/wetland/wetland_terrain",
	"forest": "res://assets/terrain/forest/forest_terrain",
	"coast": "res://assets/terrain/coast/coast_terrain",
}

const BIOME_VEGETATION_ASSET_SCENES := {
	"grassland": "res://assets/vegetation/grassland/grassland_vegetation",
	"wetland": "res://assets/vegetation/wetland/wetland_vegetation",
	"forest": "res://assets/vegetation/forest/forest_vegetation",
	"coast": "res://assets/vegetation/coast/coast_vegetation",
}

const FAUNA_ASSET_BASE_PATH := "res://assets/fauna"


static func biome_terrain_scene_path(biome: String) -> String:
	return resolve_scene_path(str(BIOME_TERRAIN_ASSET_SCENES.get(biome, "")))


static func biome_vegetation_scene_path(biome: String) -> String:
	return resolve_scene_path(str(BIOME_VEGETATION_ASSET_SCENES.get(biome, "")))


static func species_scene_path(species_id: String) -> String:
	if species_id == "":
		return ""
	var actor_stub := "%s/%s/%s_actor" % [FAUNA_ASSET_BASE_PATH, species_id, species_id]
	var actor_path := resolve_scene_path(actor_stub)
	if actor_path != "":
		return actor_path
	return resolve_scene_path("%s/%s/%s" % [FAUNA_ASSET_BASE_PATH, species_id, species_id])


static func scene_import_candidates(scene_stub: String) -> Array[String]:
	var trimmed := scene_stub.strip_edges()
	if trimmed == "":
		return []
	for ext in SCENE_IMPORT_EXTENSIONS:
		if trimmed.ends_with(ext):
			return [trimmed]
	var candidates: Array[String] = []
	for ext in SCENE_IMPORT_EXTENSIONS:
		candidates.append("%s%s" % [trimmed, ext])
	return candidates


static func resolve_scene_path(scene_stub: String) -> String:
	for candidate in scene_import_candidates(scene_stub):
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


static func instantiate_scene(scene_path: String) -> Node:
	var resolved_path := resolve_scene_path(scene_path)
	if resolved_path == "":
		return null
	var packed := load(resolved_path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()

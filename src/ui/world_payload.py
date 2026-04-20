"""Godot 世界界面数据桥接。"""

from __future__ import annotations

from typing import Any

from src.sim.world_simulation import WorldSimulation

SPECIES_LABELS = {
    "african_elephant": "非洲象",
    "algae": "藻类",
    "antelope": "羚羊",
    "bat_v4": "蝙蝠",
    "beaver": "河狸",
    "blackfish": "黑鱼",
    "boar": "野猪",
    "carp": "鲤鱼",
    "catfish": "鲶鱼",
    "crab": "蟹",
    "deer": "鹿",
    "duck": "野鸭",
    "eagle": "鹰",
    "fox": "狐狸",
    "frog": "青蛙",
    "giraffe": "长颈鹿",
    "hippopotamus": "河马",
    "hyena": "鬣狗",
    "insect": "昆虫",
    "kingfisher_v4": "翠鸟",
    "lion": "狮",
    "mouse": "鼠",
    "minnow": "米诺鱼",
    "night_moth": "夜蛾",
    "nile_crocodile": "尼罗鳄",
    "owl": "猫头鹰",
    "pike": "狗鱼",
    "plankton": "浮游生物",
    "pufferfish": "河豚",
    "rabbit": "兔子",
    "seaweed": "海草",
    "seal": "海豹",
    "shrimp": "虾",
    "small_fish": "小鱼群",
    "sparrow": "麻雀",
    "vulture": "秃鹫",
    "white_rhino": "白犀牛",
    "wild_boar": "野猪",
    "wolf": "狼",
    "woodpecker": "啄木鸟",
    "zebra": "斑马",
}

CONNECTION_LABELS = {
    "air_migration_lane": "迁飞航线",
    "coastal_exchange": "海岸交换带",
    "land_corridor": "陆地走廊",
    "river_network": "河网通道",
}

BIOME_LABELS = {
    "coast": "近海岸带",
    "coral_reef": "珊瑚礁",
    "estuary": "河口带",
    "floodplain": "泛洪平原",
    "grassland": "草原",
    "lake_shore": "湖滨带",
    "mixed_forest": "混交林",
    "seagrass": "海草床",
    "shrubland": "灌丛带",
    "temperate_forest": "温带森林",
    "tropical_rainforest": "热带雨林",
    "wetland": "湿地",
}


def _top_mapping_items(mapping: dict[str, Any], limit: int = 4) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for key, value in sorted(mapping.items(), key=lambda item: float(item[1]), reverse=True)[:limit]:
        items.append({"key": key, "value": round(float(value), 4)})
    return items


def _region_connectors(world: WorldSimulation, region_id: str) -> list[dict[str, Any]]:
    region = world.world_map.get_region(region_id)
    if region is None:
        return []
    return [
        {
            "target_region_id": connector.target_region_id,
            "connection_type": connector.connection_type,
            "strength": round(float(connector.strength), 4),
            "seasonal_bias": connector.seasonal_bias,
        }
        for connector in region.connectors
    ]


def _collect_top_list(mapping: dict[str, Any], limit: int = 6) -> list[dict[str, Any]]:
    return _top_mapping_items(mapping, limit)


def _collect_top_species(region_species_pool: dict[str, Any], limit: int = 8) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for species_id, count in sorted(region_species_pool.items(), key=lambda item: int(item[1]), reverse=True)[:limit]:
        entries.append({"species_id": species_id, "count": int(count)})
    return entries


def _species_label(species_id: str) -> str:
    if species_id in SPECIES_LABELS:
        return SPECIES_LABELS[species_id]
    return species_id.replace("_", " ").title()


def _species_category(species_id: str) -> str:
    if species_id in {"lion", "hyena", "nile_crocodile", "wolf", "fox", "eagle"}:
        return "掠食者"
    if species_id in {"vulture", "owl", "bat_v4", "sparrow", "woodpecker", "duck", "kingfisher_v4"}:
        return "飞行动物"
    if species_id in {"antelope", "zebra", "giraffe", "white_rhino", "african_elephant", "hippopotamus", "deer", "rabbit", "boar", "wild_boar"}:
        return "草食动物"
    if species_id in {"small_fish", "minnow", "carp", "catfish", "blackfish", "pike", "pufferfish", "shrimp", "crab", "frog"}:
        return "水域动物"
    return "区域生物"


def _build_species_manifest(region_species_pool: dict[str, Any]) -> list[dict[str, Any]]:
    manifest: list[dict[str, Any]] = []
    for species_id, count in sorted(region_species_pool.items(), key=lambda item: int(item[1]), reverse=True):
        manifest.append(
            {
                "species_id": species_id,
                "label": _species_label(species_id),
                "category": _species_category(species_id),
                "count": int(count),
            }
        )
    return manifest


def _build_exploration_hotspots(active_region: dict[str, Any], chains: dict[str, list[dict[str, Any]]]) -> list[dict[str, Any]]:
    resource_state = active_region["resource_state"]
    pressure_state = active_region["ecological_pressures"]
    hotspots = [
        {
            "hotspot_id": "waterhole",
            "label": "主水源地",
            "summary": f"地表水 {float(resource_state.get('surface_water', 0.0)):.2f}",
            "intensity": round(float(resource_state.get("surface_water", 0.0)), 4),
            "biome": "water",
        },
        {
            "hotspot_id": "migration_corridor",
            "label": "高草迁徙带",
            "summary": _build_chain_focus(chains)[0] if _build_chain_focus(chains) else "草食群迁徙正在进行。",
            "intensity": round(float(resource_state.get("grazing_pressure", 0.0)), 4),
            "biome": "grass",
        },
        {
            "hotspot_id": "predator_ridge",
            "label": "伏击断崖",
            "summary": f"捕食压力 {float(pressure_state.get('predation_pressure', 0.0)):.2f}",
            "intensity": round(float(pressure_state.get("predation_pressure", 0.0)), 4),
            "biome": "ridge",
        },
        {
            "hotspot_id": "carrion_field",
            "label": "腐食盘旋区",
            "summary": f"尸体资源 {float(resource_state.get('carcass_availability', 0.0)):.2f}",
            "intensity": round(float(resource_state.get("carcass_availability", 0.0)), 4),
            "biome": "carrion",
        },
        {
            "hotspot_id": "shade_grove",
            "label": "林荫歇息带",
            "summary": f"生态韧性 {float(active_region['health_state'].get('resilience', 0.0)):.2f}",
            "intensity": round(float(active_region["health_state"].get("resilience", 0.0)), 4),
            "biome": "grove",
        },
    ]
    return hotspots


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


def _build_dynamic_hotspot_activity(
    active_region: dict[str, Any],
    species_manifest: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    resource_state = active_region["resource_state"]
    pressure_state = active_region["ecological_pressures"]
    health_state = active_region["health_state"]
    category_totals = {
        "掠食者": 0,
        "草食动物": 0,
        "飞行动物": 0,
        "水域动物": 0,
    }
    total_population = max(1, sum(int(entry.get("count", 0)) for entry in species_manifest))
    for entry in species_manifest:
        category = str(entry.get("category", ""))
        if category in category_totals:
            category_totals[category] += int(entry.get("count", 0))

    predator_density = category_totals["掠食者"] / total_population
    herbivore_density = category_totals["草食动物"] / total_population
    avian_density = category_totals["飞行动物"] / total_population
    aquatic_density = category_totals["水域动物"] / total_population

    hotspot_specs = {
        "waterhole": {
            "activity": _clamp01(
                float(resource_state.get("surface_water", 0.0)) * 0.58
                + aquatic_density * 0.26
                + float(health_state.get("resilience", 0.0)) * 0.16
            ),
            "focus_category": "水域动物",
            "cue_band": "近水活跃",
        },
        "migration_corridor": {
            "activity": _clamp01(
                float(resource_state.get("grazing_pressure", 0.0)) * 0.48
                + herbivore_density * 0.34
                + float(health_state.get("prosperity", 0.0)) * 0.18
            ),
            "focus_category": "草食动物",
            "cue_band": "迁徙活跃",
        },
        "predator_ridge": {
            "activity": _clamp01(
                float(pressure_state.get("predation_pressure", 0.0)) * 0.56
                + predator_density * 0.28
                + float(health_state.get("collapse_risk", 0.0)) * 0.16
            ),
            "focus_category": "掠食者",
            "cue_band": "压迫活跃",
        },
        "carrion_field": {
            "activity": _clamp01(
                float(resource_state.get("carcass_availability", 0.0)) * 0.58
                + avian_density * 0.24
                + predator_density * 0.18
            ),
            "focus_category": "飞行动物",
            "cue_band": "腐食活跃",
        },
        "shade_grove": {
            "activity": _clamp01(
                float(health_state.get("resilience", 0.0)) * 0.54
                + herbivore_density * 0.22
                + float(resource_state.get("canopy_cover", 0.0)) * 0.24
            ),
            "focus_category": "草食动物",
            "cue_band": "遮蔽活跃",
        },
    }
    activity_rows: dict[str, dict[str, Any]] = {}
    for hotspot_id, entry in hotspot_specs.items():
        activity = float(entry["activity"])
        activity_rows[hotspot_id] = {
            "activity": round(activity, 4),
            "focus_category": entry["focus_category"],
            "cue_band": entry["cue_band"],
            "reveal_scale": round(0.88 + activity * 0.34, 4),
            "active_scale": round(0.92 + activity * 0.3, 4),
            "beacon_scale": round(0.9 + activity * 0.36, 4),
        }
    return activity_rows


def _build_dynamic_species_clusters(
    dominant_biomes: list[str],
    species_manifest: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    category_totals: dict[str, int] = {}
    total_population = max(1, sum(int(entry.get("count", 0)) for entry in species_manifest))
    for entry in species_manifest:
        category = str(entry.get("category", "区域生物"))
        category_totals[category] = category_totals.get(category, 0) + int(entry.get("count", 0))

    biome_key = "grassland"
    if any(biome in dominant_biomes for biome in {"wetland", "lake_shore", "floodplain"}):
        biome_key = "wetland"
    elif any(biome in dominant_biomes for biome in {"temperate_forest", "mixed_forest", "tropical_rainforest"}):
        biome_key = "forest"
    elif any(biome in dominant_biomes for biome in {"coast", "estuary", "coral_reef", "seagrass"}):
        biome_key = "coast"

    anchor_map = {
        "grassland": {
            "掠食者": ("predator_ridge", "carrion_field"),
            "草食动物": ("migration_corridor", "shade_grove"),
            "飞行动物": ("carrion_field", "predator_ridge"),
            "水域动物": ("waterhole", "migration_corridor"),
        },
        "wetland": {
            "掠食者": ("carrion_field", "predator_ridge"),
            "草食动物": ("waterhole", "migration_corridor"),
            "飞行动物": ("waterhole", "carrion_field"),
            "水域动物": ("waterhole", "shade_grove"),
        },
        "forest": {
            "掠食者": ("shade_grove", "predator_ridge"),
            "草食动物": ("shade_grove", "waterhole"),
            "飞行动物": ("carrion_field", "shade_grove"),
            "水域动物": ("waterhole", "shade_grove"),
        },
        "coast": {
            "掠食者": ("predator_ridge", "carrion_field"),
            "草食动物": ("migration_corridor", "waterhole"),
            "飞行动物": ("migration_corridor", "carrion_field"),
            "水域动物": ("waterhole", "migration_corridor"),
        },
    }

    clusters: dict[str, dict[str, Any]] = {}
    for category, count in category_totals.items():
        preferred_anchor, secondary_anchor = anchor_map[biome_key].get(category, ("shade_grove", "waterhole"))
        density = count / total_population
        clusters[category] = {
            "count": count,
            "density": round(density, 4),
            "preferred_anchor": preferred_anchor,
            "secondary_anchor": secondary_anchor,
            "focus_hotspot": preferred_anchor,
            "visibility_scale": round(0.9 + density * 0.42, 4),
            "alert_scale": round(0.92 + density * 0.34, 4),
            "spread_scale": round(0.92 + density * 0.3, 4),
            "group_scale": round(0.94 + density * 0.28, 4),
        }
    return clusters


def _build_dynamic_pressure_window(active_region: dict[str, Any]) -> dict[str, Any]:
    pressure_state = active_region["ecological_pressures"]
    top_pressure_items = sorted(
        pressure_state.items(),
        key=lambda item: float(item[1]),
        reverse=True,
    )
    primary_key, primary_value = top_pressure_items[0]
    predation_pressure = float(pressure_state.get("predation_pressure", 0.0))
    resource_pressure = float(pressure_state.get("runtime_resource_pressure", 0.0))
    prosperity_pressure = float(pressure_state.get("prosperity_pressure", 0.0))
    event_bias = "pressure"
    if resource_pressure > predation_pressure and resource_pressure >= prosperity_pressure:
        event_bias = "resource"
    elif prosperity_pressure > predation_pressure and prosperity_pressure > resource_pressure:
        event_bias = "stability"
    return {
        "primary_pressure": primary_key,
        "primary_value": round(float(primary_value), 4),
        "event_bias": event_bias,
        "encounter_scale": round(0.94 + predation_pressure * 0.3, 4),
        "hotspot_scale": round(0.9 + resource_pressure * 0.32, 4),
        "exit_scale": round(0.9 + prosperity_pressure * 0.28, 4),
    }


def _build_dynamic_interaction_state(
    active_region: dict[str, Any],
    chains: dict[str, list[dict[str, Any]]],
    species_manifest: list[dict[str, Any]],
) -> dict[str, Any]:
    pressure_state = active_region["ecological_pressures"]
    resource_state = active_region["resource_state"]
    total_population = max(1, sum(int(entry.get("count", 0)) for entry in species_manifest))
    predator_count = sum(int(entry.get("count", 0)) for entry in species_manifest if str(entry.get("category", "")) == "掠食者")
    herbivore_count = sum(int(entry.get("count", 0)) for entry in species_manifest if str(entry.get("category", "")) == "草食动物")
    avian_count = sum(int(entry.get("count", 0)) for entry in species_manifest if str(entry.get("category", "")) == "飞行动物")

    predation_scale = _clamp01(
        float(pressure_state.get("predation_pressure", 0.0)) * 0.58 + (predator_count / total_population) * 0.24
    )
    competition_scale = _clamp01(
        float(pressure_state.get("runtime_resource_pressure", 0.0)) * 0.44
        + float(pressure_state.get("prosperity_pressure", 0.0)) * 0.18
        + len(chains.get("competition", [])) * 0.04
    )
    migration_scale = _clamp01(
        float(resource_state.get("grazing_pressure", 0.0)) * 0.54 + (herbivore_count / total_population) * 0.24
    )
    carrion_scale = _clamp01(
        float(resource_state.get("carcass_availability", 0.0)) * 0.6 + (avian_count / total_population) * 0.22
    )
    water_dependence_scale = _clamp01(float(resource_state.get("surface_water", 0.0)) * 0.66)

    focus_rows = {
        "predation": predation_scale,
        "competition": competition_scale,
        "migration": migration_scale,
        "carrion": carrion_scale,
        "water": water_dependence_scale,
    }
    dominant_interaction = max(focus_rows.items(), key=lambda item: item[1])[0]
    encounter_bias = "predation" if dominant_interaction in {"predation", "competition"} else "observation"
    if dominant_interaction in {"carrion", "water"}:
        encounter_bias = "resource"

    return {
        "dominant_interaction": dominant_interaction,
        "encounter_bias": encounter_bias,
        "predation_scale": round(0.92 + predation_scale * 0.36, 4),
        "competition_scale": round(0.92 + competition_scale * 0.28, 4),
        "migration_scale": round(0.92 + migration_scale * 0.34, 4),
        "carrion_scale": round(0.92 + carrion_scale * 0.34, 4),
        "water_dependence_scale": round(0.92 + water_dependence_scale * 0.3, 4),
    }


def _build_dynamic_event_state(
    active_region: dict[str, Any],
    species_manifest: list[dict[str, Any]],
) -> dict[str, Any]:
    pressure_state = active_region["ecological_pressures"]
    resource_state = active_region["resource_state"]
    health_state = active_region["health_state"]
    total_population = max(1, sum(int(entry.get("count", 0)) for entry in species_manifest))
    predator_count = sum(int(entry.get("count", 0)) for entry in species_manifest if str(entry.get("category", "")) == "掠食者")
    avian_count = sum(int(entry.get("count", 0)) for entry in species_manifest if str(entry.get("category", "")) == "飞行动物")
    herbivore_count = sum(int(entry.get("count", 0)) for entry in species_manifest if str(entry.get("category", "")) == "草食动物")

    chase_window = _clamp01(
        float(pressure_state.get("predation_pressure", 0.0)) * 0.58
        + (predator_count / total_population) * 0.24
        + float(health_state.get("collapse_risk", 0.0)) * 0.12
    )
    aftermath_window = _clamp01(
        float(resource_state.get("carcass_availability", 0.0)) * 0.58
        + (avian_count / total_population) * 0.22
        + float(pressure_state.get("predation_pressure", 0.0)) * 0.12
    )
    migration_window = _clamp01(
        float(resource_state.get("grazing_pressure", 0.0)) * 0.56
        + (herbivore_count / total_population) * 0.24
        + float(health_state.get("prosperity", 0.0)) * 0.1
    )
    water_window = _clamp01(
        float(resource_state.get("surface_water", 0.0)) * 0.62
        + float(health_state.get("resilience", 0.0)) * 0.18
    )

    event_rows = {
        "chase": chase_window,
        "aftermath": aftermath_window,
        "migration": migration_window,
        "water": water_window,
    }
    active_event_band = max(event_rows.items(), key=lambda item: item[1])[0]

    return {
        "active_event_band": active_event_band,
        "chase_scale": round(0.92 + chase_window * 0.42, 4),
        "aftermath_scale": round(0.92 + aftermath_window * 0.42, 4),
        "migration_scale": round(0.92 + migration_window * 0.34, 4),
        "water_scale": round(0.92 + water_window * 0.32, 4),
        "exit_push_scale": round(0.9 + max(aftermath_window, migration_window) * 0.28, 4),
    }


def _build_dynamic_objective_state(
    hotspot_activity: dict[str, dict[str, Any]],
    interaction_state: dict[str, Any],
    event_state: dict[str, Any],
) -> dict[str, Any]:
    sorted_hotspots = sorted(
        hotspot_activity.items(),
        key=lambda item: float(item[1].get("activity", 0.0)),
        reverse=True,
    )
    primary_hotspot = sorted_hotspots[0][0] if sorted_hotspots else "waterhole"
    secondary_hotspot = sorted_hotspots[1][0] if len(sorted_hotspots) > 1 else primary_hotspot
    dominant_interaction = str(interaction_state.get("dominant_interaction", "migration"))
    active_event_band = str(event_state.get("active_event_band", "migration"))
    priority_category = str(hotspot_activity.get(primary_hotspot, {}).get("focus_category", "草食动物"))
    completion_hint = f"优先沿 {primary_hotspot} 建立观察，再转向 {secondary_hotspot}。"
    if active_event_band == "chase":
        completion_hint = "当前更适合先立住压迫链，再补观察。"
    elif active_event_band == "aftermath":
        completion_hint = "当前更适合盯住余波去向，再决定是否切区。"
    elif dominant_interaction == "water":
        completion_hint = "当前更适合先补近水观察，再扩到迁徙和腐食。"
    return {
        "primary_hotspot": primary_hotspot,
        "secondary_hotspot": secondary_hotspot,
        "priority_category": priority_category,
        "completion_hint": completion_hint,
        "task_time_scale": round(0.9 + float(hotspot_activity.get(primary_hotspot, {}).get("activity", 0.0)) * 0.3, 4),
        "task_radius_scale": round(0.92 + float(interaction_state.get("migration_scale", 1.0)) * 0.12, 4),
    }


def _build_dynamic_chase_state(
    interaction_state: dict[str, Any],
    event_state: dict[str, Any],
) -> dict[str, Any]:
    dominant_interaction = str(interaction_state.get("dominant_interaction", "predation"))
    active_event_band = str(event_state.get("active_event_band", "chase"))
    pressure_hotspot = "predator_ridge"
    aftermath_hotspot = "carrion_field"
    migration_hotspot = "migration_corridor"
    if dominant_interaction == "water":
        pressure_hotspot = "waterhole"
    elif dominant_interaction == "migration":
        pressure_hotspot = "migration_corridor"
    if active_event_band == "water":
        migration_hotspot = "waterhole"
    elif active_event_band == "migration":
        aftermath_hotspot = "migration_corridor"
    return {
        "pressure_hotspot": pressure_hotspot,
        "aftermath_hotspot": aftermath_hotspot,
        "migration_hotspot": migration_hotspot,
        "pressure_pull_scale": round(max(1.0, float(event_state.get("chase_scale", 1.0))), 4),
        "aftermath_pull_scale": round(max(1.0, float(event_state.get("aftermath_scale", 1.0))), 4),
        "result_radius_scale": round(0.94 + max(0.0, float(event_state.get("chase_scale", 1.0)) - 0.92) * 0.5, 4),
    }


def _build_dynamic_hotspot_windows(
    hotspot_activity: dict[str, dict[str, Any]],
    objective_state: dict[str, Any],
    chase_state: dict[str, Any],
    event_state: dict[str, Any],
) -> dict[str, dict[str, Any]]:
    windows: dict[str, dict[str, Any]] = {}
    primary_hotspot = str(objective_state.get("primary_hotspot", ""))
    secondary_hotspot = str(objective_state.get("secondary_hotspot", ""))
    pressure_hotspot = str(chase_state.get("pressure_hotspot", ""))
    aftermath_hotspot = str(chase_state.get("aftermath_hotspot", ""))
    migration_hotspot = str(chase_state.get("migration_hotspot", ""))
    active_event_band = str(event_state.get("active_event_band", ""))

    for hotspot_id, entry in hotspot_activity.items():
        task_scale = 1.0
        reveal_scale = 1.0
        active_scale = 1.0
        event_band = "stable"
        if hotspot_id == primary_hotspot:
            task_scale += 0.16
            reveal_scale += 0.12
            active_scale += 0.14
            event_band = "objective"
        elif hotspot_id == secondary_hotspot:
            task_scale += 0.08
            reveal_scale += 0.06
            event_band = "secondary"
        if hotspot_id == pressure_hotspot and active_event_band == "chase":
            active_scale += 0.18
            reveal_scale += 0.08
            event_band = "pressure"
        if hotspot_id == aftermath_hotspot and active_event_band == "aftermath":
            active_scale += 0.2
            reveal_scale += 0.1
            event_band = "aftermath"
        if hotspot_id == migration_hotspot and active_event_band == "migration":
            task_scale += 0.12
            reveal_scale += 0.08
            event_band = "migration"
        windows[hotspot_id] = {
            "event_band": event_band,
            "task_scale": round(task_scale, 4),
            "reveal_scale": round(reveal_scale, 4),
            "active_scale": round(active_scale, 4),
        }
    return windows


def _build_dynamic_exit_state(
    interaction_state: dict[str, Any],
    event_state: dict[str, Any],
    objective_state: dict[str, Any],
    chase_state: dict[str, Any],
    hotspot_windows: dict[str, dict[str, Any]],
    completion_state_hint: str,
) -> dict[str, Any]:
    dominant_interaction = str(interaction_state.get("dominant_interaction", "migration"))
    active_event_band = str(event_state.get("active_event_band", "migration"))
    exit_bias_scale = 1.0
    reveal_scale = 1.0
    visual_scale = 1.0
    readiness_band = completion_state_hint
    if active_event_band == "aftermath":
        exit_bias_scale += 0.14
        reveal_scale += 0.1
        visual_scale += 0.12
    elif active_event_band == "migration":
        exit_bias_scale += 0.1
        reveal_scale += 0.08
    elif active_event_band == "water":
        reveal_scale += 0.06
    if dominant_interaction == "predation":
        exit_bias_scale += 0.08
    summary = "当前更适合继续观察。"
    if exit_bias_scale >= 1.16:
        summary = "当前更适合沿出口链准备切区。"
    elif reveal_scale >= 1.08:
        summary = "当前更适合先把出口和并入口读清。"
    gate_source = str(objective_state.get("primary_hotspot", "migration_corridor"))
    if active_event_band == "chase":
        gate_source = str(chase_state.get("pressure_hotspot", gate_source))
    elif active_event_band == "aftermath":
        gate_source = str(chase_state.get("aftermath_hotspot", gate_source))
    elif active_event_band == "migration":
        gate_source = str(chase_state.get("migration_hotspot", gate_source))
    strongest_hotspot_id = gate_source
    strongest_hotspot_band = "objective"
    strongest_hotspot_score = float("-inf")
    for hotspot_id, window in hotspot_windows.items():
        score = float(window.get("active_scale", 1.0)) + float(window.get("reveal_scale", 1.0)) * 0.35
        if score > strongest_hotspot_score:
            strongest_hotspot_score = score
            strongest_hotspot_id = hotspot_id
            strongest_hotspot_band = str(window.get("event_band", "stable"))
    if strongest_hotspot_band in {"objective", "pressure", "aftermath", "migration"}:
        gate_source = strongest_hotspot_id
    gate_map = {
        "waterhole": "west_gate",
        "shade_grove": "west_gate",
        "predator_ridge": "north_gate",
        "migration_corridor": "east_gate",
        "carrion_field": "east_gate",
    }
    recommended_gate_id = gate_map.get(gate_source, "east_gate")
    gate_reason_map = {
        "west_gate": "当前更适合沿西侧入口链继续读近水或遮蔽带。",
        "north_gate": "当前更适合沿北侧高地门继续盯压迫和高点链。",
        "east_gate": "当前更适合沿东侧主通路继续推进迁徙或余波链。",
    }
    gate_focus_kind_map = {
        "west_gate": "entry_route",
        "north_gate": "chokepoint",
        "east_gate": "trunk_route",
    }
    recommended_gate_scale = 1.04
    gate_band = "observe"
    if readiness_band == "transition":
        recommended_gate_scale += 0.16
        gate_band = "commit"
    elif readiness_band == "prepare":
        recommended_gate_scale += 0.08
        gate_band = "prepare"
    if active_event_band in {"aftermath", "migration"}:
        recommended_gate_scale += 0.06
    if dominant_interaction == "predation" and recommended_gate_id == "north_gate":
        recommended_gate_scale += 0.04
    elif dominant_interaction in {"migration", "water"} and recommended_gate_id != "north_gate":
        recommended_gate_scale += 0.04
    if strongest_hotspot_band == "pressure" and recommended_gate_id == "north_gate":
        recommended_gate_scale += 0.06
    elif strongest_hotspot_band == "aftermath" and recommended_gate_id == "east_gate":
        recommended_gate_scale += 0.06
    elif strongest_hotspot_band == "objective" and recommended_gate_id == "west_gate":
        recommended_gate_scale += 0.04
    recommended_terminal_band = "exit"
    if active_event_band == "aftermath" or strongest_hotspot_band == "aftermath":
        recommended_terminal_band = "aftermath"
    elif (
        active_event_band == "chase"
        or strongest_hotspot_band == "pressure"
        or dominant_interaction == "predation"
    ):
        recommended_terminal_band = "pressure"
    elif readiness_band in {"prepare", "transition"} or gate_band in {"prepare", "commit"}:
        recommended_terminal_band = "exit"
    terminal_reason_map = {
        "pressure": "当前终端更适合先盯压迫热点，再确认结果链和离场门。",
        "aftermath": "当前终端更适合先盯余波落点，再确认回聚链和离场门。",
        "exit": "当前终端更适合先收束到离场门，再判断是否切区。",
    }
    recommended_terminal_scale = 1.0
    if recommended_terminal_band == "pressure":
        recommended_terminal_scale += 0.08
        if active_event_band == "chase":
            recommended_terminal_scale += 0.06
        if strongest_hotspot_band == "pressure":
            recommended_terminal_scale += 0.06
        if dominant_interaction == "predation":
            recommended_terminal_scale += 0.04
    elif recommended_terminal_band == "aftermath":
        recommended_terminal_scale += 0.1
        if active_event_band == "aftermath":
            recommended_terminal_scale += 0.06
        if strongest_hotspot_band == "aftermath":
            recommended_terminal_scale += 0.06
    else:
        recommended_terminal_scale += 0.08
        if readiness_band == "prepare":
            recommended_terminal_scale += 0.04
        elif readiness_band == "transition":
            recommended_terminal_scale += 0.08
        if gate_band == "prepare":
            recommended_terminal_scale += 0.04
        elif gate_band == "commit":
            recommended_terminal_scale += 0.08
    recommended_terminal_scale += max(0.0, recommended_gate_scale - 1.0) * 0.72
    force_exit_push_scale = 0.92 + (recommended_gate_scale - 1.0) * 0.9
    if readiness_band == "transition":
        force_exit_push_scale += 0.12
    elif readiness_band == "prepare":
        force_exit_push_scale += 0.06
    focus_switch_scale = 0.96 + max(0.0, recommended_gate_scale - 1.0) * 1.08
    if gate_band == "prepare":
        focus_switch_scale += 0.04
    elif gate_band == "commit":
        focus_switch_scale += 0.1
    force_progress_stage = 1
    if readiness_band == "prepare" or strongest_hotspot_band in {"pressure", "migration"}:
        force_progress_stage = 2
    if readiness_band == "transition" or strongest_hotspot_band == "aftermath":
        force_progress_stage = 3
    terminal_focus_scale = 0.94 + max(0.0, recommended_gate_scale - 1.0) * 1.24
    if gate_band == "prepare":
        terminal_focus_scale += 0.08
    elif gate_band == "commit":
        terminal_focus_scale += 0.18
    transition_push_scale = 0.92 + max(0.0, force_exit_push_scale - 1.0) * 1.08
    if strongest_hotspot_band == "pressure":
        transition_push_scale += 0.04
    elif strongest_hotspot_band == "aftermath":
        transition_push_scale += 0.08
    elif strongest_hotspot_band == "migration":
        transition_push_scale += 0.06
    gate_title_map = {
        "west_gate": ("西侧观察离场", "西侧入口导入"),
        "north_gate": ("北侧高地离场", "北侧高地导入"),
        "east_gate": ("东侧主线离场", "东侧主线导入"),
    }
    base_transition_title, base_arrival_title = gate_title_map.get(recommended_gate_id, gate_title_map["east_gate"])
    if strongest_hotspot_band == "pressure":
        base_transition_title = "压迫线离场"
    elif strongest_hotspot_band == "aftermath":
        base_transition_title = "余波线离场"
    elif strongest_hotspot_band == "migration":
        base_transition_title = "迁徙线离场"
    return {
        "exit_bias_scale": round(exit_bias_scale, 4),
        "reveal_scale": round(reveal_scale, 4),
        "visual_scale": round(visual_scale, 4),
        "readiness_band": readiness_band,
        "summary": summary,
        "recommended_gate_id": recommended_gate_id,
        "recommended_gate_reason": gate_reason_map.get(recommended_gate_id, gate_reason_map["east_gate"]),
        "recommended_gate_scale": round(recommended_gate_scale, 4),
        "recommended_gate_band": gate_band,
        "recommended_terminal_band": recommended_terminal_band,
        "recommended_terminal_reason": terminal_reason_map.get(recommended_terminal_band, terminal_reason_map["exit"]),
        "recommended_terminal_scale": round(recommended_terminal_scale, 4),
        "recommended_route_focus_kind": gate_focus_kind_map.get(recommended_gate_id, "trunk_route"),
        "focus_switch_scale": round(focus_switch_scale, 4),
        "recommended_gate_source_hotspot": gate_source,
        "recommended_gate_trigger_band": strongest_hotspot_band,
        "force_exit_push_scale": round(force_exit_push_scale, 4),
        "force_progress_stage": int(force_progress_stage),
        "terminal_focus_scale": round(terminal_focus_scale, 4),
        "transition_push_scale": round(transition_push_scale, 4),
        "recommended_transition_title": base_transition_title,
        "recommended_arrival_title": base_arrival_title,
    }


def _build_dynamic_completion_state(
    active_region: dict[str, Any],
    event_state: dict[str, Any],
    objective_state: dict[str, Any],
) -> dict[str, Any]:
    health_state = active_region["health_state"]
    readiness_score = _clamp01(
        float(health_state.get("stability", 0.0)) * 0.42
        + float(health_state.get("resilience", 0.0)) * 0.28
        + max(0.0, 1.08 - float(event_state.get("exit_push_scale", 1.0))) * 0.16
        + float(objective_state.get("task_radius_scale", 1.0)) * 0.08
    )
    observation_bias_scale = round(1.18 - readiness_score * 0.18, 4)
    exit_bias_scale = round(0.92 + readiness_score * 0.28, 4)
    readiness_band = "observe"
    summary = "当前更适合继续建立观察链。"
    if readiness_score >= 0.74:
        readiness_band = "transition"
        summary = "当前区域已经接近完成态，可以准备沿出口切区。"
    elif readiness_score >= 0.58:
        readiness_band = "prepare"
        summary = "当前区域已进入收束段，先补终端观察，再准备出口。"
    return {
        "readiness_score": round(readiness_score, 4),
        "readiness_band": readiness_band,
        "observation_bias_scale": observation_bias_scale,
        "exit_bias_scale": exit_bias_scale,
        "summary": summary,
    }


def _build_region_role(region_id: str, climate_zone: str, dominant_biomes: list[str]) -> str:
    role_map = {
        "temperate_forest": "林地观测区",
        "temperate_grassland": "草原迁徙区",
        "wetland_lake": "湿地缓冲区",
        "rainforest_river": "雨林河运区",
        "coastal_shelf": "近海交换区",
        "coral_sea": "珊瑚航路区",
    }
    climate_text = {
        "temperate": "温带",
        "subtropical": "亚热带",
        "tropical": "热带",
        "equatorial": "赤道",
    }.get(climate_zone, climate_zone)
    if dominant_biomes:
        biome_text = " / ".join(BIOME_LABELS.get(biome, biome) for biome in dominant_biomes[:2])
        return f"{role_map.get(region_id, '生态观测区')} · {climate_text} · {biome_text}"
    return f"{role_map.get(region_id, '生态观测区')} · {climate_text}"


def _build_chain_focus(chains: dict[str, list[dict[str, Any]]]) -> list[str]:
    focus_rows = [
        ("社会相位", chains.get("social_phases", [])),
        ("草原主链", chains.get("grassland_chain", [])),
        ("尸体资源链", chains.get("carrion_chain", [])),
        ("湿地主链", chains.get("wetland_chain", [])),
    ]
    focus: list[str] = []
    for title, rows in focus_rows:
        if not rows:
            continue
        row = rows[0]
        focus.append(f"{title}主导项：{row['key']}（{float(row['value']):.2f}）")
    return focus[:4]


def _build_region_intro(region_name: str, climate_zone: str, dominant_biomes: list[str]) -> str:
    climate_labels = {
        "temperate": "温带",
        "subtropical": "亚热带",
        "tropical": "热带",
        "equatorial": "赤道",
    }
    climate_text = climate_labels.get(climate_zone, climate_zone)
    if not dominant_biomes:
        return f"{region_name}属于{climate_text}生态区。"
    biome_text = "、".join(dominant_biomes[:3])
    return f"{region_name}属于{climate_text}生态区，当前主导群系包括{biome_text}。"


def _build_route_summary(connectors: list[dict[str, Any]]) -> list[str]:
    summaries: list[str] = []
    for connector in connectors[:4]:
        connection_type = CONNECTION_LABELS.get(connector["connection_type"], connector["connection_type"])
        summaries.append(
            f"{connection_type}通向 {connector['target_region_id']}（强度 {float(connector['strength']):.2f}）"
        )
    return summaries


def _build_frontier_links(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    frontier_links: list[dict[str, Any]] = []
    for connector in region_detail.get("connectors", []):
        target_id = str(connector["target_region_id"])
        target_detail = region_details.get(target_id, {})
        target_species = target_detail.get("top_species", [])
        frontier_links.append(
            {
                "target_region_id": target_id,
                "target_name": target_detail.get("name", target_id),
                "target_role": target_detail.get("region_role", "生态观测区"),
                "target_biomes": list(target_detail.get("dominant_biomes", [])),
                "connection_type": connector["connection_type"],
                "connection_label": CONNECTION_LABELS.get(connector["connection_type"], connector["connection_type"]),
                "strength": round(float(connector["strength"]), 4),
                "seasonal_bias": connector.get("seasonal_bias", ""),
                "target_prosperity": round(float(target_detail.get("health_state", {}).get("prosperity", 0.0)), 4),
                "target_stability": round(float(target_detail.get("health_state", {}).get("stability", 0.0)), 4),
                "target_risk": round(float(target_detail.get("health_state", {}).get("collapse_risk", 0.0)), 4),
                "target_species": [
                    {
                        "label": str(entry.get("label", entry.get("species_id", ""))),
                        "count": int(entry.get("count", 0)),
                    }
                    for entry in target_species[:2]
                ],
            }
        )
    frontier_links.sort(key=lambda item: float(item["strength"]), reverse=True)
    return frontier_links[:4]


def _build_frontier_network(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    frontier_network: list[dict[str, Any]] = []
    for connector in region_detail.get("connectors", []):
        target_id = str(connector["target_region_id"])
        target_detail = region_details.get(target_id, {})
        branches: list[dict[str, Any]] = []
        for branch_connector in target_detail.get("connectors", []):
            branch_target_id = str(branch_connector["target_region_id"])
            if branch_target_id == region_id:
                continue
            branch_detail = region_details.get(branch_target_id, {})
            branches.append(
                {
                    "target_region_id": branch_target_id,
                    "target_name": branch_detail.get("name", branch_target_id),
                    "target_role": branch_detail.get("region_role", "生态观测区"),
                    "connection_type": branch_connector["connection_type"],
                    "connection_label": CONNECTION_LABELS.get(
                        branch_connector["connection_type"],
                        branch_connector["connection_type"],
                    ),
                    "strength": round(float(branch_connector["strength"]), 4),
                    "target_prosperity": round(
                        float(branch_detail.get("health_state", {}).get("prosperity", 0.0)),
                        4,
                    ),
                    "target_risk": round(
                        float(branch_detail.get("health_state", {}).get("collapse_risk", 0.0)),
                        4,
                    ),
                }
            )
        branches.sort(key=lambda item: float(item["strength"]), reverse=True)
        frontier_network.append(
            {
                "target_region_id": target_id,
                "branch_count": len(branches),
                "branch_total_strength": round(sum(float(item["strength"]) for item in branches), 4),
                "branches": branches[:3],
            }
        )
    frontier_network.sort(key=lambda item: float(item["branch_total_strength"]), reverse=True)
    return frontier_network


def _frontier_threat_band(target_risk: float, branch_count: int, branch_total_strength: float) -> str:
    if target_risk >= 0.68 or branch_total_strength >= 1.6:
        return "高压战区"
    if target_risk >= 0.42 or branch_count >= 2:
        return "波动战区"
    return "稳态战区"


def _frontier_opportunity_band(target_prosperity: float, target_stability: float, strength: float) -> str:
    if target_prosperity >= 0.62 and target_stability >= 0.52:
        return "扩张窗口"
    if strength >= 0.58:
        return "通道窗口"
    return "侦察窗口"


def _frontier_operation_posture(
    target_risk: float,
    strength: float,
    branch_count: int,
    branch_total_strength: float,
) -> str:
    if target_risk >= 0.68 and strength >= 0.56:
        return "高压突进"
    if branch_count >= 2 and branch_total_strength >= 1.2:
        return "网络扩张"
    if target_risk <= 0.38 and strength >= 0.44:
        return "稳态推进"
    return "前线侦察"


def _frontier_operation_badges(
    target_name: str,
    threat_band: str,
    opportunity_band: str,
    branch_count: int,
) -> list[str]:
    badges = [
        f"焦点前线：{target_name}",
        f"威胁带：{threat_band}",
        f"机会带：{opportunity_band}",
    ]
    if branch_count > 0:
        badges.append(f"网络分支：{branch_count} 条")
    return badges[:4]


def _build_frontier_operations(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    frontier_links = region_detail.get("frontier_links", [])
    frontier_network = {
        str(entry.get("target_region_id", "")): entry
        for entry in region_detail.get("frontier_network", [])
    }
    operations: list[dict[str, Any]] = []

    for frontier_link in frontier_links:
        target_region_id = str(frontier_link.get("target_region_id", ""))
        network_entry = frontier_network.get(target_region_id, {})
        branches = list(network_entry.get("branches", []))
        lead_branch = branches[0] if branches else {}
        target_name = str(frontier_link.get("target_name", target_region_id))
        target_risk = float(frontier_link.get("target_risk", 0.0))
        target_prosperity = float(frontier_link.get("target_prosperity", 0.0))
        target_stability = float(frontier_link.get("target_stability", 0.0))
        strength = float(frontier_link.get("strength", 0.0))
        branch_count = int(network_entry.get("branch_count", 0))
        branch_total_strength = float(network_entry.get("branch_total_strength", 0.0))
        threat_band = _frontier_threat_band(target_risk, branch_count, branch_total_strength)
        opportunity_band = _frontier_opportunity_band(target_prosperity, target_stability, strength)
        posture = _frontier_operation_posture(target_risk, strength, branch_count, branch_total_strength)

        route_stages = [
            {
                "stage": "第一跳",
                "target_region_id": target_region_id,
                "title": f"推进至 {target_name}",
                "detail": f"{frontier_link.get('connection_label', '区域通道')} · 强度 {strength:.2f}",
            }
        ]
        if lead_branch:
            route_stages.append(
                {
                    "stage": "第二跳",
                    "target_region_id": str(lead_branch.get("target_region_id", "")),
                    "title": f"分支至 {lead_branch.get('target_name', lead_branch.get('target_region_id', '分支区域'))}",
                    "detail": f"{lead_branch.get('connection_label', '区域通道')} · 强度 {float(lead_branch.get('strength', 0.0)):.2f}",
                }
            )

        operations.append(
            {
                "target_region_id": target_region_id,
                "target_name": target_name,
                "posture": posture,
                "threat_band": threat_band,
                "opportunity_band": opportunity_band,
                "summary": (
                    f"{target_name} 当前适合执行 {posture}，"
                    f"前线处于{threat_band}，当前机会判断为{opportunity_band}。"
                ),
                "route_stages": route_stages,
                "badges": _frontier_operation_badges(
                    target_name,
                    threat_band,
                    opportunity_band,
                    branch_count,
                ),
            }
        )

    return operations[:4]


def _frontier_campaign_band(posture: str, threat_band: str, opportunity_band: str) -> str:
    if posture == "高压突进":
        return "赤线推进令"
    if posture == "网络扩张":
        return "多线扩张令"
    if opportunity_band == "扩张窗口":
        return "丰度扩张令"
    if threat_band == "稳态战区":
        return "稳态侦察令"
    return "前线巡察令"


def _build_frontier_campaigns(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    operations: list[dict[str, Any]] = list(region_detail.get("frontier_operations", []))
    campaigns: list[dict[str, Any]] = []

    for index, operation in enumerate(operations):
        route_stages = list(operation.get("route_stages", []))
        target_name = str(operation.get("target_name", operation.get("target_region_id", "")))
        posture = str(operation.get("posture", "前线侦察"))
        threat_band = str(operation.get("threat_band", "稳态战区"))
        opportunity_band = str(operation.get("opportunity_band", "侦察窗口"))
        campaign_band = _frontier_campaign_band(posture, threat_band, opportunity_band)
        campaigns.append(
            {
                "target_region_id": str(operation.get("target_region_id", "")),
                "campaign_name": f"{target_name} · {campaign_band}",
                "campaign_band": campaign_band,
                "posture": posture,
                "threat_band": threat_band,
                "opportunity_band": opportunity_band,
                "priority": index + 1,
                "route_titles": [str(stage.get("title", "")) for stage in route_stages[:2]],
                "summary": (
                    f"{campaign_band} 当前以 {target_name} 为主目标，"
                    f"执行姿态为{posture}，战区判断为{threat_band}。"
                ),
            }
        )

    return campaigns[:3]


def _frontier_confirmation_band(posture: str, threat_band: str, opportunity_band: str) -> str:
    if posture == "高压突进":
        return "落点突入确认"
    if posture == "网络扩张":
        return "多段扩张确认"
    if opportunity_band == "扩张窗口":
        return "丰度接管确认"
    if threat_band == "高压战区":
        return "高压试探确认"
    return "主走廊确认"


def _build_frontier_route_profiles(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    operations: list[dict[str, Any]] = list(region_detail.get("frontier_operations", []))
    campaigns: dict[str, dict[str, Any]] = {
        str(entry.get("target_region_id", "")): entry
        for entry in region_detail.get("frontier_campaigns", [])
    }
    frontier_network: dict[str, dict[str, Any]] = {
        str(entry.get("target_region_id", "")): entry
        for entry in region_detail.get("frontier_network", [])
    }
    frontier_links: dict[str, dict[str, Any]] = {
        str(entry.get("target_region_id", "")): entry
        for entry in region_detail.get("frontier_links", [])
    }
    profiles: list[dict[str, Any]] = []

    for operation in operations:
        target_region_id = str(operation.get("target_region_id", ""))
        if not target_region_id:
            continue
        campaign = campaigns.get(target_region_id, {})
        network = frontier_network.get(target_region_id, {})
        link = frontier_links.get(target_region_id, {})
        route_stages = list(operation.get("route_stages", []))
        stage_titles = [str(stage.get("title", "")) for stage in route_stages[:2]]
        target_name = str(operation.get("target_name", target_region_id))
        threat_band = str(operation.get("threat_band", "稳态战区"))
        opportunity_band = str(operation.get("opportunity_band", "侦察窗口"))
        posture = str(operation.get("posture", "前线侦察"))
        confirmation_band = _frontier_confirmation_band(posture, threat_band, opportunity_band)
        lead_branch = (network.get("branches", []) or [{}])[0]
        lead_branch_name = str(lead_branch.get("target_name", lead_branch.get("target_region_id", "等待二阶段分支")))
        corridor_strength = float(link.get("strength", 0.0))
        target_prosperity = float(link.get("target_prosperity", 0.0))
        target_risk = float(link.get("target_risk", 0.0))
        branch_count = int(network.get("branch_count", 0))
        profiles.append(
            {
                "target_region_id": target_region_id,
                "route_name": f"{target_name} · {confirmation_band}",
                "campaign_name": str(campaign.get("campaign_name", target_name)),
                "campaign_band": str(campaign.get("campaign_band", "战区推进令")),
                "confirmation_band": confirmation_band,
                "primary_stage_title": stage_titles[0] if stage_titles else f"推进至 {target_name}",
                "secondary_stage_title": stage_titles[1] if len(stage_titles) > 1 else f"分支至 {lead_branch_name}",
                "route_stage_titles": stage_titles,
                "lead_branch_name": lead_branch_name,
                "landing_count": max(1, branch_count + 1),
                "corridor_strength": corridor_strength,
                "target_prosperity": target_prosperity,
                "target_risk": target_risk,
                "summary": (
                    f"{confirmation_band} 当前以 {target_name} 为主走廊，"
                    f"阶段目标为 {stage_titles[0] if stage_titles else target_name}，"
                    f"二阶段延伸至 {lead_branch_name}。"
                ),
                "badges": [
                    f"姿态：{posture}",
                    f"走廊强度：{corridor_strength:.2f}",
                    f"候选落点：{max(1, branch_count + 1)}",
                    f"风险/繁荣：{target_risk:.2f}/{target_prosperity:.2f}",
                ],
            }
        )

    return profiles[:3]


def _build_frontier_execution_plans(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    profiles: list[dict[str, Any]] = list(region_detail.get("frontier_route_profiles", []))
    plans: list[dict[str, Any]] = []

    for index, profile in enumerate(profiles):
        target_region_id = str(profile.get("target_region_id", ""))
        if not target_region_id:
            continue
        target_detail = region_details.get(target_region_id, {})
        target_name = str(profile.get("route_name", target_region_id))
        prosperity = float(profile.get("target_prosperity", 0.0))
        risk = float(profile.get("target_risk", 0.0))
        branch_count = int(profile.get("landing_count", 1))
        confirmation_band = str(profile.get("confirmation_band", "主走廊确认"))

        execution_mode = "当前执行"
        if index == 1:
            execution_mode = "备用推进"
        elif index >= 2:
            execution_mode = "回退路线"

        readiness = max(0.1, min(1.0, prosperity * 0.58 + (1.0 - risk) * 0.42))
        pressure = max(0.1, min(1.0, risk * 0.72 + branch_count * 0.08))

        plans.append(
            {
                "target_region_id": target_region_id,
                "execution_mode": execution_mode,
                "route_name": target_name,
                "confirmation_band": confirmation_band,
                "primary_stage_title": str(profile.get("primary_stage_title", "等待主走廊")),
                "secondary_stage_title": str(profile.get("secondary_stage_title", "等待二阶段")),
                "ready_band": "高就绪" if readiness >= 0.72 else "稳态就绪" if readiness >= 0.48 else "低就绪",
                "pressure_band": "高压回退" if pressure >= 0.72 else "中压推进" if pressure >= 0.48 else "低压推进",
                "readiness": round(readiness, 4),
                "pressure": round(pressure, 4),
                "landing_name": str(target_detail.get("name", target_region_id)),
                "landing_role": str(target_detail.get("region_role", "生态观测区")),
                "summary": (
                    f"{execution_mode} 当前指向 {str(target_detail.get('name', target_region_id))}，"
                    f"{confirmation_band} 下维持 {str(profile.get('primary_stage_title', '主走廊'))}，"
                    f"就绪度 {readiness:.2f}，压力 {pressure:.2f}。"
                ),
                "badges": [
                    f"确认：{confirmation_band}",
                    f"就绪带：{'高' if readiness >= 0.72 else '稳' if readiness >= 0.48 else '低'}",
                    f"压力带：{'高' if pressure >= 0.72 else '中' if pressure >= 0.48 else '低'}",
                    f"落点：{str(target_detail.get('name', target_region_id))}",
                ],
            }
        )

    return plans[:3]


def _build_frontier_schedule_profiles(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    execution_plans: list[dict[str, Any]] = list(region_detail.get("frontier_execution_plans", []))
    if not execution_plans:
        return []

    primary = execution_plans[0]
    support = execution_plans[1] if len(execution_plans) > 1 else execution_plans[0]
    fallback = execution_plans[2] if len(execution_plans) > 2 else execution_plans[-1]

    readiness = float(primary.get("readiness", 0.0))
    pressure = float(primary.get("pressure", 0.0))
    dispatch_band = "高压调度"
    if pressure < 0.48 and readiness >= 0.58:
        dispatch_band = "稳态调度"
    elif readiness >= 0.72:
        dispatch_band = "高就绪调度"

    schedule = {
        "target_region_id": str(primary.get("target_region_id", "")),
        "schedule_name": f"{str(primary.get('landing_name', '前线目标'))} · {dispatch_band}",
        "dispatch_band": dispatch_band,
        "primary_route": {
            "label": "主执行",
            "target_region_id": str(primary.get("target_region_id", "")),
            "route_name": str(primary.get("route_name", "等待主执行")),
            "landing_name": str(primary.get("landing_name", "等待落点")),
            "ready_band": str(primary.get("ready_band", "待命")),
        },
        "support_route": {
            "label": "辅执行",
            "target_region_id": str(support.get("target_region_id", "")),
            "route_name": str(support.get("route_name", "等待辅执行")),
            "landing_name": str(support.get("landing_name", "等待落点")),
            "ready_band": str(support.get("ready_band", "待命")),
        },
        "fallback_route": {
            "label": "回退",
            "target_region_id": str(fallback.get("target_region_id", "")),
            "route_name": str(fallback.get("route_name", "等待回退路线")),
            "landing_name": str(fallback.get("landing_name", "等待落点")),
            "ready_band": str(fallback.get("ready_band", "待命")),
        },
        "summary": (
            f"{dispatch_band} 当前以 {str(primary.get('landing_name', '前线目标'))} 为主执行，"
            f"{str(support.get('landing_name', '辅执行目标'))} 作为辅执行，"
            f"{str(fallback.get('landing_name', '回退目标'))} 作为回退路线。"
        ),
        "badges": [
            f"主执行：{str(primary.get('landing_name', '前线目标'))}",
            f"辅执行：{str(support.get('landing_name', '辅执行目标'))}",
            f"回退：{str(fallback.get('landing_name', '回退目标'))}",
            f"调度带：{dispatch_band}",
        ],
    }
    return [schedule]


def _build_frontier_formation_profiles(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    schedule_profiles: list[dict[str, Any]] = list(region_detail.get("frontier_schedule_profiles", []))
    if not schedule_profiles:
        return []

    schedule = schedule_profiles[0]
    primary = dict(schedule.get("primary_route", {}))
    support = dict(schedule.get("support_route", {}))
    fallback = dict(schedule.get("fallback_route", {}))

    formations = [
        {
            "formation_key": "assault",
            "formation_name": "突进编成",
            "formation_band": "高压突进",
            "active_route": primary,
            "support_route": support,
            "fallback_route": fallback,
            "summary": f"突进编成当前以 {primary.get('landing_name', '前线目标')} 为主执行，快速压向前线核心。",
        },
        {
            "formation_key": "balanced",
            "formation_name": "均衡编成",
            "formation_band": "稳态推进",
            "active_route": support,
            "support_route": primary,
            "fallback_route": fallback,
            "summary": f"均衡编成当前以 {support.get('landing_name', '辅执行目标')} 为中轴，保持主辅路线轮换。",
        },
        {
            "formation_key": "safe",
            "formation_name": "稳态编成",
            "formation_band": "回退预备",
            "active_route": fallback,
            "support_route": support,
            "fallback_route": primary,
            "summary": f"稳态编成当前以 {fallback.get('landing_name', '回退目标')} 为安全轴，优先保留退场空间。",
        },
    ]

    for formation in formations:
        formation["badges"] = [
            f"当前：{formation['formation_name']}",
            f"主轴：{formation['active_route'].get('landing_name', '待命')}",
            f"支援：{formation['support_route'].get('landing_name', '待命')}",
            f"预备：{formation['fallback_route'].get('landing_name', '待命')}",
        ]
    return formations


def _build_frontier_formation_presets(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    formations: list[dict[str, Any]] = list(region_detail.get("frontier_formation_profiles", []))
    presets: list[dict[str, Any]] = []
    for formation in formations:
        active_route = dict(formation.get("active_route", {}))
        support_route = dict(formation.get("support_route", {}))
        fallback_route = dict(formation.get("fallback_route", {}))
        presets.append(
            {
                "preset_key": str(formation.get("formation_key", "")),
                "preset_name": f"{str(formation.get('formation_name', '编成'))}预案",
                "formation_band": str(formation.get("formation_band", "战区编成")),
                "active_route": active_route,
                "support_route": support_route,
                "fallback_route": fallback_route,
                "route_order": [
                    str(active_route.get("landing_name", "待命")),
                    str(support_route.get("landing_name", "待命")),
                    str(fallback_route.get("landing_name", "待命")),
                ],
                "summary": (
                    f"{str(formation.get('formation_name', '编成'))} 当前按 "
                    f"{str(active_route.get('landing_name', '待命'))} → "
                    f"{str(support_route.get('landing_name', '待命'))} → "
                    f"{str(fallback_route.get('landing_name', '待命'))} 编排。"
                ),
                "badges": [
                    f"主序列：{str(active_route.get('landing_name', '待命'))}",
                    f"支序列：{str(support_route.get('landing_name', '待命'))}",
                    f"回退序列：{str(fallback_route.get('landing_name', '待命'))}",
                    f"带型：{str(formation.get('formation_band', '战区编成'))}",
                ],
            }
        )
    return presets


def _humanize_filter_key(filter_key: str) -> str:
    return {
        "balanced": "综合",
        "safe": "稳态",
        "rich": "高繁荣",
        "risk": "高风险",
    }.get(filter_key, "综合")


def _build_frontier_activation_profiles(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    presets: list[dict[str, Any]] = list(region_detail.get("frontier_formation_presets", []))
    activations: list[dict[str, Any]] = []
    for index, preset in enumerate(presets):
        active_route = dict(preset.get("active_route", {}))
        preset_name = str(preset.get("preset_name", "战区预案"))
        formation_band = str(preset.get("formation_band", "战区编成"))
        activation_band = "主战区激活"
        if index == 1:
            activation_band = "均衡激活"
        elif index >= 2:
            activation_band = "稳态激活"
        activations.append(
            {
                "activation_key": str(preset.get("preset_key", "")),
                "activation_name": f"{preset_name} · {activation_band}",
                "activation_band": activation_band,
                "preset_name": preset_name,
                "formation_band": formation_band,
                "active_route": active_route,
                "summary": (
                    f"{activation_band} 当前把 {preset_name} 设为现行战区计划，"
                    f"主轴落点为 {str(active_route.get('landing_name', '待命'))}。"
                ),
                "badges": [
                    f"预案：{preset_name}",
                    f"激活带：{activation_band}",
                    f"主轴：{str(active_route.get('landing_name', '待命'))}",
                    f"编成：{formation_band}",
                ],
            }
        )
    return activations


def _build_frontier_activation_feedbacks(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    activations: list[dict[str, Any]] = list(region_detail.get("frontier_activation_profiles", []))
    campaigns: list[dict[str, Any]] = list(region_detail.get("frontier_campaigns", []))
    feedbacks: list[dict[str, Any]] = []

    for activation in activations:
        activation_key = str(activation.get("activation_key", ""))
        active_route = dict(activation.get("active_route", {}))
        target_region_id = str(active_route.get("target_region_id", ""))
        target_detail = region_details.get(target_region_id, {})

        recommended_filter = "balanced"
        recommended_stage_index = 0
        feedback_band = "稳态回路"
        if activation_key == "assault":
            recommended_filter = "rich"
            feedback_band = "高繁荣回路"
        elif activation_key == "safe":
            recommended_filter = "safe"
            recommended_stage_index = 1
            feedback_band = "稳态回退回路"

        route_priority_order = ["primary_route", "support_route", "fallback_route"]
        comparison_focus = "综合推进"
        if activation_key == "balanced":
            route_priority_order = ["support_route", "primary_route", "fallback_route"]
            comparison_focus = "中轴轮换"
        elif activation_key == "safe":
            route_priority_order = ["fallback_route", "support_route", "primary_route"]
            comparison_focus = "稳态回退"
        elif activation_key == "assault":
            comparison_focus = "高压突进"

        if target_detail:
            prosperity = float(target_detail.get("health_state", {}).get("prosperity", 0.0))
            risk = float(target_detail.get("health_state", {}).get("collapse_risk", 0.0))
            if risk >= 0.62:
                recommended_filter = "risk"
                feedback_band = "高风险回路"
            elif prosperity >= 0.68 and activation_key != "safe":
                recommended_filter = "rich"
                feedback_band = "高繁荣回路"

        campaign_name = str(activation.get("activation_name", "战区预案"))
        route_titles: list[str] = []
        for campaign in campaigns:
            if str(campaign.get("target_region_id", "")) == target_region_id:
                route_titles = [str(item) for item in campaign.get("route_titles", [])]
                break

        route_stage_title = "第一阶段"
        if route_titles:
            clamped_index = min(recommended_stage_index, len(route_titles) - 1)
            recommended_stage_index = clamped_index
            route_stage_title = route_titles[clamped_index]

        feedbacks.append(
            {
                "activation_key": activation_key,
                "feedback_name": f"{campaign_name} · {feedback_band}",
                "feedback_band": feedback_band,
                "recommended_filter": recommended_filter,
                "recommended_stage_index": recommended_stage_index,
                "recommended_stage_title": route_stage_title,
                "priority_target_id": target_region_id,
                "priority_target_name": str(target_detail.get("name", target_region_id or "待命")),
                "priority_role": str(target_detail.get("region_role", "生态观测区")),
                "route_priority_order": route_priority_order,
                "comparison_focus": comparison_focus,
                "summary": (
                    f"{campaign_name} 当前建议切到 {_humanize_filter_key(recommended_filter)} 筛选，"
                    f"推进 {route_stage_title}，优先围绕 "
                    f"{str(target_detail.get('name', target_region_id or '待命'))} 重排战区。"
                ),
                "badges": [
                    f"筛选：{_humanize_filter_key(recommended_filter)}",
                    f"阶段：{route_stage_title}",
                    f"调度：{comparison_focus}",
                    f"优先落点：{str(target_detail.get('name', target_region_id or '待命'))}",
                    f"回路：{feedback_band}",
                ],
            }
        )

    return feedbacks


def _build_frontier_directive_profiles(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    feedbacks: list[dict[str, Any]] = list(region_detail.get("frontier_activation_feedbacks", []))
    schedule_profiles: list[dict[str, Any]] = list(region_detail.get("frontier_schedule_profiles", []))
    if not feedbacks or not schedule_profiles:
        return []

    schedule = schedule_profiles[0]
    directives: list[dict[str, Any]] = []
    for feedback in feedbacks:
        directive_key = str(feedback.get("activation_key", ""))
        route_priority_order: list[str] = [str(item) for item in feedback.get("route_priority_order", [])]
        if not route_priority_order:
            route_priority_order = ["primary_route", "support_route", "fallback_route"]

        ordered_routes: list[dict[str, Any]] = []
        for route_key in route_priority_order:
            route = dict(schedule.get(route_key, {}))
            if not route:
                continue
            route["route_key"] = route_key
            ordered_routes.append(route)

        active_route = ordered_routes[0] if ordered_routes else {}
        support_route = ordered_routes[1] if len(ordered_routes) > 1 else active_route
        fallback_route = ordered_routes[2] if len(ordered_routes) > 2 else support_route

        directive_band = "战区均衡指令"
        if directive_key == "assault":
            directive_band = "战区突进指令"
        elif directive_key == "safe":
            directive_band = "战区稳态指令"

        directives.append(
            {
                "directive_key": directive_key,
                "directive_name": f"{str(feedback.get('feedback_name', '战区回路'))} · {directive_band}",
                "directive_band": directive_band,
                "comparison_focus": str(feedback.get("comparison_focus", "综合推进")),
                "recommended_filter": str(feedback.get("recommended_filter", "balanced")),
                "recommended_stage_index": int(feedback.get("recommended_stage_index", 0)),
                "recommended_stage_title": str(feedback.get("recommended_stage_title", "第一阶段")),
                "priority_target_id": str(feedback.get("priority_target_id", "")),
                "priority_target_name": str(feedback.get("priority_target_name", "待命")),
                "active_route_key": str(active_route.get("route_key", "primary_route")),
                "active_route": active_route,
                "support_route": support_route,
                "fallback_route": fallback_route,
                "summary": (
                    f"{directive_band} 当前以 {str(active_route.get('landing_name', '待命'))} 为主轴，"
                    f"按 {str(feedback.get('comparison_focus', '综合推进'))} 逻辑重排战区。"
                ),
                "badges": [
                    f"筛选：{_humanize_filter_key(str(feedback.get('recommended_filter', 'balanced')))}",
                    f"阶段：{str(feedback.get('recommended_stage_title', '第一阶段'))}",
                    f"主轴：{str(active_route.get('landing_name', '待命'))}",
                    f"指令：{directive_band}",
                ],
            }
        )

    return directives


def _build_frontier_directive_previews(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    directives: list[dict[str, Any]] = list(region_detail.get("frontier_directive_profiles", []))
    previews: list[dict[str, Any]] = []
    for directive in directives:
        active_route = dict(directive.get("active_route", {}))
        support_route = dict(directive.get("support_route", {}))
        fallback_route = dict(directive.get("fallback_route", {}))
        preview_stages = [
            {
                "stage_label": "预演一阶",
                "target_region_id": str(active_route.get("target_region_id", "")),
                "target_name": str(active_route.get("landing_name", "待命")),
                "focus": "主轴压进",
            },
            {
                "stage_label": "预演二阶",
                "target_region_id": str(support_route.get("target_region_id", "")),
                "target_name": str(support_route.get("landing_name", "待命")),
                "focus": "支援轮换",
            },
            {
                "stage_label": "预演回退",
                "target_region_id": str(fallback_route.get("target_region_id", "")),
                "target_name": str(fallback_route.get("landing_name", "待命")),
                "focus": "回退保留",
            },
        ]
        previews.append(
            {
                "directive_key": str(directive.get("directive_key", "")),
                "preview_name": f"{str(directive.get('directive_band', '战区指令'))} · 路线预演",
                "preview_band": str(directive.get("directive_band", "战区指令")),
                "preview_stages": preview_stages,
                "summary": (
                    f"{str(directive.get('directive_band', '战区指令'))} 当前按 "
                    f"{str(active_route.get('landing_name', '待命'))} → "
                    f"{str(support_route.get('landing_name', '待命'))} → "
                    f"{str(fallback_route.get('landing_name', '待命'))} 预演推进。"
                ),
                "badges": [
                    f"一阶：{str(active_route.get('landing_name', '待命'))}",
                    f"二阶：{str(support_route.get('landing_name', '待命'))}",
                    f"回退：{str(fallback_route.get('landing_name', '待命'))}",
                    f"编排：{str(directive.get('comparison_focus', '综合推进'))}",
                ],
            }
        )
    return previews


def _build_frontier_directive_sandbox(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    directives: list[dict[str, Any]] = list(region_detail.get("frontier_directive_profiles", []))
    sandbox_rows: list[dict[str, Any]] = []
    for directive in directives:
        active_route = dict(directive.get("active_route", {}))
        support_route = dict(directive.get("support_route", {}))
        fallback_route = dict(directive.get("fallback_route", {}))
        score = 0.0
        for weight, route in [(0.55, active_route), (0.3, support_route), (0.15, fallback_route)]:
            target_id = str(route.get("target_region_id", ""))
            target_detail = region_details.get(target_id, {})
            prosperity = float(target_detail.get("health_state", {}).get("prosperity", 0.0))
            risk = float(target_detail.get("health_state", {}).get("collapse_risk", 0.0))
            score += weight * (prosperity * 0.64 + (1.0 - risk) * 0.36)
        sandbox_rows.append(
            {
                "directive_key": str(directive.get("directive_key", "")),
                "sandbox_name": f"{str(directive.get('directive_band', '战区指令'))} · 沙盘推演",
                "sandbox_score": round(score, 4),
                "comparison_focus": str(directive.get("comparison_focus", "综合推进")),
                "primary_target_name": str(active_route.get("landing_name", "待命")),
                "support_target_name": str(support_route.get("landing_name", "待命")),
                "fallback_target_name": str(fallback_route.get("landing_name", "待命")),
                "summary": (
                    f"{str(directive.get('directive_band', '战区指令'))} 在沙盘里当前总分 {score:.2f}，"
                    f"主轴为 {str(active_route.get('landing_name', '待命'))}。"
                ),
                "badges": [
                    f"主轴：{str(active_route.get('landing_name', '待命'))}",
                    f"支援：{str(support_route.get('landing_name', '待命'))}",
                    f"回退：{str(fallback_route.get('landing_name', '待命'))}",
                    f"总分：{score:.2f}",
                ],
            }
        )
    sandbox_rows.sort(key=lambda row: float(row["sandbox_score"]), reverse=True)
    return sandbox_rows


def _build_frontier_directive_comparison(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    region_detail = region_details.get(region_id, {})
    sandbox_rows: list[dict[str, Any]] = list(region_detail.get("frontier_directive_sandbox", []))
    if not sandbox_rows:
        return {}

    best_row = sandbox_rows[0]
    riskiest_row = max(
        sandbox_rows,
        key=lambda row: 0.0 if "稳态" in str(row.get("sandbox_name", "")) else float(row.get("sandbox_score", 0.0)),
    )
    active_row = sandbox_rows[0]
    for row in sandbox_rows:
        if str(row.get("directive_key", "")) == "assault":
            active_row = row
            break

    return {
        "best_directive": {
            "directive_key": str(best_row.get("directive_key", "")),
            "directive_name": str(best_row.get("sandbox_name", "待命")),
            "sandbox_score": float(best_row.get("sandbox_score", 0.0)),
            "primary_target_name": str(best_row.get("primary_target_name", "待命")),
        },
        "active_directive": {
            "directive_key": str(active_row.get("directive_key", "")),
            "directive_name": str(active_row.get("sandbox_name", "待命")),
            "sandbox_score": float(active_row.get("sandbox_score", 0.0)),
            "primary_target_name": str(active_row.get("primary_target_name", "待命")),
        },
        "risk_directive": {
            "directive_key": str(riskiest_row.get("directive_key", "")),
            "directive_name": str(riskiest_row.get("sandbox_name", "待命")),
            "sandbox_score": float(riskiest_row.get("sandbox_score", 0.0)),
            "primary_target_name": str(riskiest_row.get("primary_target_name", "待命")),
        },
        "summary": (
            f"当前沙盘优选 {str(best_row.get('sandbox_name', '待命'))}，"
            f"主轴指向 {str(best_row.get('primary_target_name', '待命'))}。"
        ),
    }


def _build_frontier_directive_decisions(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    comparison: dict[str, Any] = dict(region_detail.get("frontier_directive_comparison", {}))
    if not comparison:
        return []

    decisions: list[dict[str, Any]] = []
    for decision_key, decision_band in [
        ("best_directive", "优选定案"),
        ("active_directive", "现行定案"),
        ("risk_directive", "风险定案"),
    ]:
        source = dict(comparison.get(decision_key, {}))
        if not source:
            continue
        decisions.append(
            {
                "decision_key": str(source.get("directive_key", "")),
                "decision_name": f"{str(source.get('directive_name', '战区指令'))} · {decision_band}",
                "decision_band": decision_band,
                "directive_name": str(source.get("directive_name", "战区指令")),
                "primary_target_name": str(source.get("primary_target_name", "待命")),
                "sandbox_score": float(source.get("sandbox_score", 0.0)),
                "summary": (
                    f"{decision_band} 当前指向 {str(source.get('primary_target_name', '待命'))}，"
                    f"沙盘总分 {float(source.get('sandbox_score', 0.0)):.2f}。"
                ),
                "badges": [
                    f"定案：{decision_band}",
                    f"主轴：{str(source.get('primary_target_name', '待命'))}",
                    f"分数：{float(source.get('sandbox_score', 0.0)):.2f}",
                ],
            }
        )
    return decisions


def _build_frontier_directive_locks(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    decisions: list[dict[str, Any]] = list(region_detail.get("frontier_directive_decisions", []))
    locks: list[dict[str, Any]] = []
    for decision in decisions:
        locks.append(
            {
                "lock_key": str(decision.get("decision_key", "")),
                "lock_name": f"{str(decision.get('decision_name', '战区定案'))} · 锁定结论",
                "lock_band": str(decision.get("decision_band", "战区定案")),
                "directive_name": str(decision.get("directive_name", "战区指令")),
                "primary_target_name": str(decision.get("primary_target_name", "待命")),
                "sandbox_score": float(decision.get("sandbox_score", 0.0)),
                "summary": (
                    f"{str(decision.get('decision_band', '战区定案'))} 当前将 "
                    f"{str(decision.get('directive_name', '战区指令'))} 锁为现行结论，"
                    f"主轴维持 {str(decision.get('primary_target_name', '待命'))}。"
                ),
                "badges": [
                    f"锁定：{str(decision.get('decision_band', '战区定案'))}",
                    f"指令：{str(decision.get('directive_name', '战区指令'))}",
                    f"主轴：{str(decision.get('primary_target_name', '待命'))}",
                ],
            }
        )
    return locks


def _build_frontier_directive_confirmations(
    region_id: str,
    region_details: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    region_detail = region_details.get(region_id, {})
    locks: list[dict[str, Any]] = list(region_detail.get("frontier_directive_locks", []))
    confirmations: list[dict[str, Any]] = []
    for lock in locks:
        confirmations.append(
            {
                "confirmation_key": str(lock.get("lock_key", "")),
                "confirmation_name": f"{str(lock.get('lock_name', '战区锁定'))} · 确认通令",
                "confirmation_band": str(lock.get("lock_band", "战区锁定")),
                "directive_name": str(lock.get("directive_name", "战区指令")),
                "primary_target_name": str(lock.get("primary_target_name", "待命")),
                "lock_name": str(lock.get("lock_name", "战区锁定")),
                "sandbox_score": float(lock.get("sandbox_score", 0.0)),
                "summary": (
                    f"{str(lock.get('lock_name', '战区锁定'))} 当前已经转入确认通令，"
                    f"现行主轴维持 {str(lock.get('primary_target_name', '待命'))}，"
                    f"并继续执行 {str(lock.get('directive_name', '战区指令'))}。"
                ),
                "badges": [
                    f"确认：{str(lock.get('lock_band', '战区锁定'))}",
                    f"锁定：{str(lock.get('lock_name', '战区锁定'))}",
                    f"主轴：{str(lock.get('primary_target_name', '待命'))}",
                ],
            }
        )
    return confirmations


def _build_world_bulletin(active_region: dict[str, Any], chains: dict[str, Any], narrative: dict[str, Any]) -> list[str]:
    bulletins: list[str] = []
    top_pressure_items = sorted(
        active_region["ecological_pressures"].items(),
        key=lambda item: float(item[1]),
        reverse=True,
    )[:2]
    for key, value in top_pressure_items:
        bulletins.append(f"{active_region['name']} 当前主压为 {key}（{float(value):.2f}）。")

    for chain_name, rows in (
        ("社会相位", chains.get("social_phases", [])),
        ("草原主链", chains.get("grassland_chain", [])),
        ("尸体资源链", chains.get("carrion_chain", [])),
        ("湿地主链", chains.get("wetland_chain", [])),
    ):
        if rows:
            top_row = rows[0]
            bulletins.append(f"{chain_name} 当前最强项为 {top_row['key']}（{float(top_row['value']):.2f}）。")

    for key in ["territory", "social_trends", "grassland_chain", "carrion_chain", "wetland_chain"]:
        entries = narrative.get(key, [])
        if entries:
            bulletins.append(str(entries[0]))
    return bulletins[:6]


def _build_region_detail_payload(world: WorldSimulation, region_id: str) -> dict[str, Any]:
    previous_active_region_id = world.active_region_id
    world.set_active_region(region_id)
    stats = world.get_statistics()
    active_region = stats["active_region"]
    species_manifest = _build_species_manifest(world.get_active_region().species_pool)

    chains = {
        "social_phases": _collect_top_list(stats["social_trends"]["phase_scores"], 6),
        "social_trends": _collect_top_list(stats["social_trends"]["trend_scores"], 6),
        "grassland_chain": _collect_top_list(stats["grassland_chain"]["trophic_scores"], 6),
        "carrion_chain": _collect_top_list(stats["carrion_chain"]["resource_scores"], 6),
        "wetland_chain": _collect_top_list(stats["wetland_chain"]["trophic_scores"], 6),
        "territory": _collect_top_list(stats["territory"]["pressure_scores"], 6),
        "competition": _collect_top_list(stats["competition"]["pressure_scores"], 6),
        "predation": _collect_top_list(stats["predation"]["pressure_scores"], 6),
    }

    top_pressure_items = sorted(
        active_region["ecological_pressures"].items(),
        key=lambda item: float(item[1]),
        reverse=True,
    )[:3]
    exploration_hotspots = _build_exploration_hotspots(active_region, chains)
    hotspot_activity = _build_dynamic_hotspot_activity(active_region, species_manifest)
    species_clusters = _build_dynamic_species_clusters(list(active_region["dominant_biomes"]), species_manifest)
    pressure_window = _build_dynamic_pressure_window(active_region)
    interaction_state = _build_dynamic_interaction_state(active_region, chains, species_manifest)
    event_state = _build_dynamic_event_state(active_region, species_manifest)
    objective_state = _build_dynamic_objective_state(hotspot_activity, interaction_state, event_state)
    chase_state = _build_dynamic_chase_state(interaction_state, event_state)
    completion_state = _build_dynamic_completion_state(active_region, event_state, objective_state)
    hotspot_windows = _build_dynamic_hotspot_windows(hotspot_activity, objective_state, chase_state, event_state)
    dynamic_region_state = {
        "hotspot_activity": hotspot_activity,
        "species_clusters": species_clusters,
        "pressure_window": pressure_window,
        "interaction_state": interaction_state,
        "event_state": event_state,
        "objective_state": objective_state,
        "chase_state": chase_state,
        "hotspot_windows": hotspot_windows,
        "completion_state": completion_state,
        "exit_state": _build_dynamic_exit_state(
            interaction_state,
            event_state,
            objective_state,
            chase_state,
            hotspot_windows,
            str(completion_state.get("readiness_band", "observe")),
        ),
    }

    payload = {
        "id": active_region["id"],
        "name": active_region["name"],
        "climate_zone": active_region["climate_zone"],
        "dominant_biomes": list(active_region["dominant_biomes"]),
        "region_role": _build_region_role(
            active_region["id"],
            active_region["climate_zone"],
            list(active_region["dominant_biomes"]),
        ),
        "region_intro": _build_region_intro(
            active_region["name"],
            active_region["climate_zone"],
            list(active_region["dominant_biomes"]),
        ),
        "region_summary": {
            "species_pool_count": int(active_region["species_pool_count"]),
            "biome_count": int(active_region["biome_count"]),
            "habitat_count": int(active_region["habitat_count"]),
        },
        "health_state": {key: round(float(value), 4) for key, value in active_region["health_state"].items()},
        "resource_state": {key: round(float(value), 4) for key, value in active_region["resource_state"].items()},
        "hazard_state": {key: round(float(value), 4) for key, value in active_region["hazard_state"].items()},
        "ecological_pressures": {
            key: round(float(value), 4) for key, value in active_region["ecological_pressures"].items()
        },
        "recent_adjustments": list(active_region["recent_adjustments"][-10:]),
        "top_species": [
            {
                **entry,
                "label": _species_label(str(entry["species_id"])),
            }
            for entry in _collect_top_species(world.get_active_region().species_pool, 8)
        ],
        "species_manifest": species_manifest,
        "connectors": _region_connectors(world, region_id),
        "route_summary": _build_route_summary(_region_connectors(world, region_id)),
        "pressure_headlines": [
            f"{key}（{float(value):.2f}）" for key, value in top_pressure_items
        ],
        "chain_focus": _build_chain_focus(chains),
        "exploration_hotspots": exploration_hotspots,
        "dynamic_region_state": dynamic_region_state,
        "chains": chains,
        "narrative": {
            "territory": list(stats["territory"]["narrative_territory"][:3]),
            "social_trends": list(stats["social_trends"]["narrative_trends"][:4]),
            "grassland_chain": list(stats["grassland_chain"]["narrative_chain"][:3]),
            "carrion_chain": list(stats["carrion_chain"]["narrative_chain"][:3]),
            "wetland_chain": list(stats["wetland_chain"]["narrative_chain"][:3]),
            "symbiosis": list(stats["symbiosis"]["narrative_symbiosis"][:3]),
            "predation": list(stats["predation"]["narrative_predation"][:3]),
        },
    }
    world.set_active_region(previous_active_region_id)
    return payload


def build_world_ui_payload(world: WorldSimulation) -> dict[str, Any]:
    """构建给 Godot 世界界面使用的紧凑 JSON。"""
    overview = world.get_world_overview()
    stats = world.get_statistics()
    active_region = stats["active_region"]
    region_details: dict[str, Any] = {}

    regions = []
    for region in overview["regions"]:
        region_id = region["id"]
        regions.append(
            {
                **region,
                "connectors": _region_connectors(world, region_id),
            }
        )
        region_details[region_id] = _build_region_detail_payload(world, region_id)

    for region_id, region_detail in region_details.items():
        region_detail["frontier_links"] = _build_frontier_links(region_id, region_details)
        region_detail["frontier_network"] = _build_frontier_network(region_id, region_details)
        region_detail["frontier_operations"] = _build_frontier_operations(region_id, region_details)
        region_detail["frontier_campaigns"] = _build_frontier_campaigns(region_id, region_details)
        region_detail["frontier_route_profiles"] = _build_frontier_route_profiles(region_id, region_details)
        region_detail["frontier_execution_plans"] = _build_frontier_execution_plans(region_id, region_details)
        region_detail["frontier_schedule_profiles"] = _build_frontier_schedule_profiles(region_id, region_details)
        region_detail["frontier_formation_profiles"] = _build_frontier_formation_profiles(region_id, region_details)
        region_detail["frontier_formation_presets"] = _build_frontier_formation_presets(region_id, region_details)
        region_detail["frontier_activation_profiles"] = _build_frontier_activation_profiles(region_id, region_details)
        region_detail["frontier_activation_feedbacks"] = _build_frontier_activation_feedbacks(region_id, region_details)
        region_detail["frontier_directive_profiles"] = _build_frontier_directive_profiles(region_id, region_details)
        region_detail["frontier_directive_previews"] = _build_frontier_directive_previews(region_id, region_details)
        region_detail["frontier_directive_sandbox"] = _build_frontier_directive_sandbox(region_id, region_details)
        region_detail["frontier_directive_comparison"] = _build_frontier_directive_comparison(region_id, region_details)
        region_detail["frontier_directive_decisions"] = _build_frontier_directive_decisions(region_id, region_details)
        region_detail["frontier_directive_locks"] = _build_frontier_directive_locks(region_id, region_details)
        region_detail["frontier_directive_confirmations"] = _build_frontier_directive_confirmations(region_id, region_details)

    chain_highlights = {
        "social_phases": _top_mapping_items(stats["social_trends"]["phase_scores"], 5),
        "grassland_chain": _top_mapping_items(stats["grassland_chain"]["trophic_scores"], 5),
        "carrion_chain": _top_mapping_items(stats["carrion_chain"]["resource_scores"], 5),
        "wetland_chain": _top_mapping_items(stats["wetland_chain"]["trophic_scores"], 5),
        "territory": _top_mapping_items(stats["territory"]["pressure_scores"], 5),
    }

    return {
        "schema_version": 1,
        "world": {
            "name": overview["world_name"],
            "size": list(overview["world_size"]),
            "tick": overview["tick"],
            "loaded_regions": overview["loaded_regions"],
            "total_regions": overview["total_regions"],
            "active_region_id": overview["active_region_id"],
            "regions": regions,
        },
        "active_region": {
            "id": active_region["id"],
            "name": active_region["name"],
            "climate_zone": active_region["climate_zone"],
            "dominant_biomes": list(active_region["dominant_biomes"]),
            "region_role": _build_region_role(
                active_region["id"],
                active_region["climate_zone"],
                list(active_region["dominant_biomes"]),
            ),
            "region_intro": _build_region_intro(
                active_region["name"],
                active_region["climate_zone"],
                list(active_region["dominant_biomes"]),
            ),
            "region_summary": {
                "species_pool_count": int(active_region["species_pool_count"]),
                "biome_count": int(active_region["biome_count"]),
                "habitat_count": int(active_region["habitat_count"]),
            },
            "health_state": {key: round(float(value), 4) for key, value in active_region["health_state"].items()},
            "resource_state": {key: round(float(value), 4) for key, value in active_region["resource_state"].items()},
            "hazard_state": {key: round(float(value), 4) for key, value in active_region["hazard_state"].items()},
            "ecological_pressures": {
                key: round(float(value), 4) for key, value in active_region["ecological_pressures"].items()
            },
            "recent_adjustments": list(active_region["recent_adjustments"][-10:]),
            "top_species": [
                {
                    **entry,
                    "label": _species_label(str(entry["species_id"])),
                }
                for entry in _collect_top_species(world.get_active_region().species_pool, 8)
            ],
        },
        "region_details": region_details,
        "chains": chain_highlights,
        "narrative": {
            "territory": list(stats["territory"]["narrative_territory"][:3]),
            "social_trends": list(stats["social_trends"]["narrative_trends"][:4]),
            "grassland_chain": list(stats["grassland_chain"]["narrative_chain"][:3]),
            "carrion_chain": list(stats["carrion_chain"]["narrative_chain"][:3]),
            "wetland_chain": list(stats["wetland_chain"]["narrative_chain"][:3]),
        },
        "world_bulletin": _build_world_bulletin(active_region, chain_highlights, {
            "territory": list(stats["territory"]["narrative_territory"][:3]),
            "social_trends": list(stats["social_trends"]["narrative_trends"][:4]),
            "grassland_chain": list(stats["grassland_chain"]["narrative_chain"][:3]),
            "carrion_chain": list(stats["carrion_chain"]["narrative_chain"][:3]),
            "wetland_chain": list(stats["wetland_chain"]["narrative_chain"][:3]),
        }),
        "map_legend": [
            {"label": "森林区", "color": "forest"},
            {"label": "草原区", "color": "grassland"},
            {"label": "湿地区", "color": "wetland"},
            {"label": "海岸区", "color": "coast"},
            {"label": "珊瑚海", "color": "coral"},
        ],
        "ui_meta": {
            "active_speed": 1,
            "source": "WorldSimulation.get_statistics",
            "language": "zh-CN",
            "refresh_mode": "manual_or_timer",
        },
    }

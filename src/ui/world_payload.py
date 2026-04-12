"""Godot 世界界面数据桥接。"""

from __future__ import annotations

from typing import Any

from src.sim.world_simulation import WorldSimulation


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

    payload = {
        "id": active_region["id"],
        "name": active_region["name"],
        "climate_zone": active_region["climate_zone"],
        "dominant_biomes": list(active_region["dominant_biomes"]),
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
        "top_species": _collect_top_species(world.get_active_region().species_pool, 8),
        "connectors": _region_connectors(world, region_id),
        "chains": {
            "social_phases": _collect_top_list(stats["social_trends"]["phase_scores"], 6),
            "social_trends": _collect_top_list(stats["social_trends"]["trend_scores"], 6),
            "grassland_chain": _collect_top_list(stats["grassland_chain"]["trophic_scores"], 6),
            "carrion_chain": _collect_top_list(stats["carrion_chain"]["resource_scores"], 6),
            "wetland_chain": _collect_top_list(stats["wetland_chain"]["trophic_scores"], 6),
            "territory": _collect_top_list(stats["territory"]["pressure_scores"], 6),
            "competition": _collect_top_list(stats["competition"]["pressure_scores"], 6),
            "predation": _collect_top_list(stats["predation"]["pressure_scores"], 6),
        },
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
            "top_species": _collect_top_species(world.get_active_region().species_pool, 8),
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
        "ui_meta": {
            "active_speed": 1,
            "source": "WorldSimulation.get_statistics",
            "language": "zh-CN",
            "refresh_mode": "manual_or_timer",
        },
    }

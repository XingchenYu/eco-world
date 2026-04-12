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


def build_world_ui_payload(world: WorldSimulation) -> dict[str, Any]:
    """构建给 Godot 世界界面使用的紧凑 JSON。"""
    overview = world.get_world_overview()
    stats = world.get_statistics()
    active_region = stats["active_region"]

    regions = []
    for region in overview["regions"]:
        regions.append(
            {
                **region,
                "connectors": _region_connectors(world, region["id"]),
            }
        )

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
            "health_state": {key: round(float(value), 4) for key, value in active_region["health_state"].items()},
            "resource_state": {key: round(float(value), 4) for key, value in active_region["resource_state"].items()},
            "hazard_state": {key: round(float(value), 4) for key, value in active_region["hazard_state"].items()},
            "ecological_pressures": {
                key: round(float(value), 4) for key, value in active_region["ecological_pressures"].items()
            },
            "recent_adjustments": list(active_region["recent_adjustments"][-10:]),
        },
        "chains": chain_highlights,
        "narrative": {
            "territory": list(stats["territory"]["narrative_territory"][:3]),
            "social_trends": list(stats["social_trends"]["narrative_trends"][:4]),
            "grassland_chain": list(stats["grassland_chain"]["narrative_chain"][:3]),
            "carrion_chain": list(stats["carrion_chain"]["narrative_chain"][:3]),
            "wetland_chain": list(stats["wetland_chain"]["narrative_chain"][:3]),
        },
        "ui_meta": {
            "active_speed": 1,
            "source": "WorldSimulation.get_statistics",
            "language": "zh-CN",
        },
    }

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
        "connectors": _region_connectors(world, region_id),
        "route_summary": _build_route_summary(_region_connectors(world, region_id)),
        "pressure_headlines": [
            f"{key}（{float(value):.2f}）" for key, value in top_pressure_items
        ],
        "chain_focus": _build_chain_focus(chains),
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

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

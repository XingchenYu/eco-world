"""v4 领地与核心活动区摘要。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

from src.data import WorldRegistry
from src.world import Region


@dataclass
class RegionTerritorySummary:
    """区域级领地压力摘要。"""

    region_id: str
    active_species: List[str] = field(default_factory=list)
    pressure_scores: Dict[str, float] = field(default_factory=dict)
    contested_zones: List[str] = field(default_factory=list)
    narrative_territory: List[str] = field(default_factory=list)
    runtime_signals: Dict[str, int] = field(default_factory=dict)


def build_region_territory_summary(
    region: Region,
    registry: WorldRegistry,
    recent_events: Optional[List[str]] = None,
    runtime_state: Optional[Dict[str, float]] = None,
) -> RegionTerritorySummary:
    """构建区域级领地压力摘要。"""

    resident_species = registry.species_for_region(region.region_id)
    region_species = set(region.species_pool) if region.species_pool else set(resident_species)
    active_species: List[str] = []
    pressure_scores: Dict[str, float] = {}
    contested_zones: List[str] = []
    narrative_territory: List[str] = []
    runtime_signals: Dict[str, int] = {}

    def add_pressure(species: str, key: str, value: float, zone: str, narrative: str) -> None:
        pressure_scores[key] = round(pressure_scores.get(key, 0.0) + value, 2)
        if species not in active_species:
            active_species.append(species)
        if zone not in contested_zones:
            contested_zones.append(zone)
        if narrative not in narrative_territory:
            narrative_territory.append(narrative)

    if region.region_id == "temperate_grassland":
        surface_water = float(region.resource_state.get("surface_water", 0.0))
        carcass_availability = float(region.resource_state.get("carcass_availability", 0.0))
        if "lion" in region_species:
            add_pressure("lion", "pride_core_range", 0.58, "seasonal_waterhole", "狮群围绕水源和伏击带形成核心巡猎领地。")
            add_pressure("lion", "male_takeover_front", 0.44, "open_grazing_range", "雄狮接管压力会推动草原核心巡猎区重新划分。")
        if "hyena" in region_species:
            add_pressure("hyena", "clan_den_range", 0.55, "carcass_site", "鬣狗 clan 会围绕尸体点和洞穴带形成稳定活动圈。")
            add_pressure("hyena", "scavenger_perimeter", 0.41, "open_grazing_range", "鬣狗会把清道夫觅食路径扩展到草食群边缘。")
        if {"lion", "hyena"} <= region_species:
            add_pressure("lion", "apex_boundary_conflict", 0.63, "carcass_site", "狮群与鬣狗 clan 的边界冲突会抬高草原顶层竞争压力。")
            add_pressure("hyena", "carcass_route_overlap", 0.49, "seasonal_waterhole", "尸体与饮水通道重叠会放大清道夫与捕食者的相遇密度。")
        if {"african_elephant", "white_rhino"} & region_species:
            add_pressure("african_elephant", "waterhole_spacing", 0.34, "seasonal_waterhole", "大型植食者会把草原水源点推成高密度共享节点。")
        if surface_water > 0.0:
            runtime_signals["surface_water_anchor"] = round(surface_water, 3)
            pressure_scores["waterhole_spacing"] = round(
                pressure_scores.get("waterhole_spacing", 0.0) + min(0.12, surface_water * 0.10),
                2,
            )
        if carcass_availability > 0.0:
            runtime_signals["carcass_anchor"] = round(carcass_availability, 3)
            pressure_scores["carcass_route_overlap"] = round(
                pressure_scores.get("carcass_route_overlap", 0.0) + min(0.12, carcass_availability * 0.10),
                2,
            )

    if region.region_id in {"wetland_lake", "rainforest_river"}:
        if "hippopotamus" in region_species:
            add_pressure("hippopotamus", "channel_claim", 0.57, "mud_bank", "河马会围绕深水休息带和夜间上岸路线形成核心领地。")
            add_pressure("hippopotamus", "night_grazing_corridor", 0.43, "reed_belt", "河马夜间上岸取食会把岸带踩成稳定通道。")
        if "nile_crocodile" in region_species:
            add_pressure("nile_crocodile", "basking_bank_claim", 0.56, "basking_bank", "鳄鱼会占据晒背岸和伏击岸段。")
            add_pressure("nile_crocodile", "ambush_bank_hold", 0.52, "riparian_perch", "鳄鱼会沿浅滩和岸栖位形成稳定伏击核心。")
        if {"hippopotamus", "nile_crocodile"} <= region_species:
            add_pressure("nile_crocodile", "shoreline_standoff", 0.62, "mud_bank", "河马与鳄鱼会把岸带热点推成高风险对峙区。")
        if "beaver" in region_species:
            add_pressure("beaver", "dam_complex_claim", 0.47, "reed_belt", "河狸坝系会把缓流水和芦苇带变成长期工程师活动核心。")

    previous_territory = region.relationship_state.get("territory", {})
    previous_grassland = region.relationship_state.get("grassland_chain", {})
    previous_carrion = region.relationship_state.get("carrion_chain", {})
    previous_runtime = previous_territory.get("runtime_signals", {}) if isinstance(previous_territory, dict) else {}
    previous_social = region.relationship_state.get("social_trends", {})
    previous_grassland_layer = previous_grassland.get("dominant_layer", "") if isinstance(previous_grassland, dict) else ""
    previous_carrion_layer = previous_carrion.get("dominant_layer", "") if isinstance(previous_carrion, dict) else ""
    previous_social_cycles = previous_social.get("cycle_signals", []) if isinstance(previous_social, dict) else []
    previous_social_prosperity = previous_social.get("prosperity_scores", {}) if isinstance(previous_social, dict) else {}
    surface_water_anchor = float(region.resource_state.get("surface_water", 0.0))
    carcass_anchor = float(region.resource_state.get("carcass_availability", 0.0))

    for description in recent_events or []:
        if "pride core range" in description:
            runtime_signals["pride_core_events"] = runtime_signals.get("pride_core_events", 0) + 1
        if "male takeover front" in description:
            runtime_signals["male_takeover_events"] = runtime_signals.get("male_takeover_events", 0) + 1
        if "clan den corridor" in description:
            runtime_signals["clan_den_events"] = runtime_signals.get("clan_den_events", 0) + 1
        if "clan frontier" in description:
            runtime_signals["clan_front_events"] = runtime_signals.get("clan_front_events", 0) + 1
        if "shoreline" in description and ("ambush" in description or "crocodile" in description):
            runtime_signals["shoreline_conflict_events"] = runtime_signals.get("shoreline_conflict_events", 0) + 1

    pride_events = runtime_signals.get("pride_core_events", 0)
    takeover_events = runtime_signals.get("male_takeover_events", 0)
    clan_den_events = runtime_signals.get("clan_den_events", 0)
    clan_front_events = runtime_signals.get("clan_front_events", 0)
    shoreline_events = runtime_signals.get("shoreline_conflict_events", 0)

    if pride_events:
        pressure_scores["pride_core_range"] = round(pressure_scores.get("pride_core_range", 0.0) + min(0.24, pride_events * 0.06), 2)
    if takeover_events:
        pressure_scores["male_takeover_front"] = round(pressure_scores.get("male_takeover_front", 0.0) + min(0.20, takeover_events * 0.05), 2)
    if clan_den_events:
        pressure_scores["clan_den_range"] = round(pressure_scores.get("clan_den_range", 0.0) + min(0.22, clan_den_events * 0.055), 2)
    if clan_front_events:
        pressure_scores["scavenger_perimeter"] = round(pressure_scores.get("scavenger_perimeter", 0.0) + min(0.18, clan_front_events * 0.045), 2)
    if shoreline_events:
        pressure_scores["shoreline_standoff"] = round(pressure_scores.get("shoreline_standoff", 0.0) + min(0.18, shoreline_events * 0.045), 2)

    runtime_state = runtime_state or {}
    pride_strength = float(runtime_state.get("lion_pride_strength", 0.0))
    takeover_strength = float(runtime_state.get("lion_takeover_pressure", 0.0))
    pride_count = int(runtime_state.get("lion_pride_count", 0.0))
    lion_hotspot_count = int(runtime_state.get("lion_hotspot_count", 0.0))
    lion_cycle_expansion = float(runtime_state.get("lion_cycle_expansion", 0.0))
    lion_cycle_contraction = float(runtime_state.get("lion_cycle_contraction", 0.0))
    clan_cohesion = float(runtime_state.get("hyena_clan_cohesion", 0.0))
    clan_front_strength = float(runtime_state.get("hyena_clan_front_pressure", 0.0))
    clan_count = int(runtime_state.get("hyena_clan_count", 0.0))
    hyena_hotspot_count = int(runtime_state.get("hyena_hotspot_count", 0.0))
    hyena_cycle_expansion = float(runtime_state.get("hyena_cycle_expansion", 0.0))
    hyena_cycle_contraction = float(runtime_state.get("hyena_cycle_contraction", 0.0))
    herd_hotspot_count = int(runtime_state.get("herd_hotspot_count", 0.0))
    herd_apex_overlap = int(runtime_state.get("herd_apex_overlap", 0.0))
    vulture_hotspot_count = int(runtime_state.get("vulture_hotspot_count", 0.0))
    vulture_carrion_overlap = int(runtime_state.get("vulture_carrion_overlap", 0.0))
    shared_hotspot_overlap = int(runtime_state.get("shared_hotspot_overlap", 0.0))
    herd_route_cycle_runtime = float(runtime_state.get("herd_route_cycle_runtime", 0.0))
    aerial_carrion_cycle_runtime = float(runtime_state.get("aerial_carrion_cycle_runtime", 0.0))
    herd_birth_runtime = float(runtime_state.get("herd_birth_runtime", 0.0))
    aerial_birth_runtime = float(runtime_state.get("aerial_birth_runtime", 0.0))
    apex_birth_runtime = float(runtime_state.get("apex_birth_runtime", 0.0))
    herd_surface_water_runtime = float(runtime_state.get("herd_surface_water_runtime", 0.0))
    aerial_carcass_runtime = float(runtime_state.get("aerial_carcass_runtime", 0.0))
    apex_regional_health_runtime = float(runtime_state.get("apex_regional_health_runtime", 0.0))
    herd_regional_health_runtime = float(runtime_state.get("herd_regional_health_runtime", 0.0))
    aerial_regional_health_runtime = float(runtime_state.get("aerial_regional_health_runtime", 0.0))
    apex_condition_runtime = float(runtime_state.get("apex_condition_runtime", 0.0))
    herd_condition_runtime = float(runtime_state.get("herd_condition_runtime", 0.0))
    aerial_condition_runtime = float(runtime_state.get("aerial_condition_runtime", 0.0))
    apex_condition_phase_runtime = max(float(runtime_state.get("apex_condition_phase_runtime", 0.0)), apex_condition_runtime)
    herd_condition_phase_runtime = max(float(runtime_state.get("herd_condition_phase_runtime", 0.0)), herd_condition_runtime)
    aerial_condition_phase_runtime = max(float(runtime_state.get("aerial_condition_phase_runtime", 0.0)), aerial_condition_runtime)
    apex_condition_phase_bias_runtime = float(runtime_state.get("apex_condition_phase_bias_runtime", 0.0))
    herd_condition_phase_bias_runtime = float(runtime_state.get("herd_condition_phase_bias_runtime", 0.0))
    aerial_condition_phase_bias_runtime = float(runtime_state.get("aerial_condition_phase_bias_runtime", 0.0))
    apex_anchor_prosperity_runtime = float(runtime_state.get("apex_anchor_prosperity_runtime", 0.0))
    herd_anchor_prosperity_runtime = float(runtime_state.get("herd_anchor_prosperity_runtime", 0.0))
    aerial_anchor_prosperity_runtime = float(runtime_state.get("aerial_anchor_prosperity_runtime", 0.0))
    apex_regional_bias_runtime = float(runtime_state.get("apex_regional_bias_runtime", 0.0))
    herd_regional_bias_runtime = float(runtime_state.get("herd_regional_bias_runtime", 0.0))
    aerial_regional_bias_runtime = float(runtime_state.get("aerial_regional_bias_runtime", 0.0))
    regional_health_anchor = max(
        0.0,
        float(region.health_state.get("prosperity", 0.0))
        + float(region.health_state.get("stability", 0.0))
        - float(region.health_state.get("collapse_risk", 0.0)),
    )
    apex_regional_health_anchor_runtime = max(
        float(runtime_state.get("apex_regional_health_anchor_runtime", 0.0)),
        apex_regional_health_runtime,
        regional_health_anchor,
    )
    herd_regional_health_anchor_runtime = max(
        float(runtime_state.get("herd_regional_health_anchor_runtime", 0.0)),
        herd_regional_health_runtime,
        regional_health_anchor,
    )
    aerial_regional_health_anchor_runtime = max(
        float(runtime_state.get("aerial_regional_health_anchor_runtime", 0.0)),
        aerial_regional_health_runtime,
        regional_health_anchor,
    )
    herd_condition_anchor_runtime = max(
        float(runtime_state.get("herd_condition_anchor_runtime", 0.0)),
        herd_condition_runtime * 0.60
        + herd_regional_health_runtime * 0.20
        + herd_surface_water_runtime * 0.12
        + herd_anchor_prosperity_runtime * 0.08,
    )
    herd_condition_phase_anchor_runtime = max(
        float(runtime_state.get("herd_condition_phase_anchor_runtime", 0.0)),
        herd_condition_phase_runtime * 0.62
        + herd_regional_health_anchor_runtime * 0.18
        + herd_surface_water_runtime * 0.12
        + herd_anchor_prosperity_runtime * 0.08,
    )
    aerial_condition_anchor_runtime = max(
        float(runtime_state.get("aerial_condition_anchor_runtime", 0.0)),
        aerial_condition_runtime * 0.60
        + aerial_regional_health_runtime * 0.20
        + aerial_carcass_runtime * 0.12
        + aerial_anchor_prosperity_runtime * 0.08,
    )
    aerial_condition_phase_anchor_runtime = max(
        float(runtime_state.get("aerial_condition_phase_anchor_runtime", 0.0)),
        aerial_condition_phase_runtime * 0.62
        + aerial_regional_health_anchor_runtime * 0.18
        + aerial_carcass_runtime * 0.12
        + aerial_anchor_prosperity_runtime * 0.08,
    )
    apex_world_pressure_runtime = float(runtime_state.get("apex_world_pressure_runtime", 0.0))
    herd_world_pressure_runtime = float(runtime_state.get("herd_world_pressure_runtime", 0.0))
    aerial_world_pressure_runtime = float(runtime_state.get("aerial_world_pressure_runtime", 0.0))
    apex_world_pressure_window_runtime = float(runtime_state.get("apex_world_pressure_window_runtime", 0.0))
    herd_world_pressure_window_runtime = float(runtime_state.get("herd_world_pressure_window_runtime", 0.0))
    aerial_world_pressure_window_runtime = float(runtime_state.get("aerial_world_pressure_window_runtime", 0.0))
    apex_condition_anchor_runtime = max(
        float(runtime_state.get("apex_condition_anchor_runtime", 0.0)),
        apex_condition_runtime * 0.62
        + apex_regional_health_runtime * 0.22
        + apex_anchor_prosperity_runtime * 0.10
        + max(surface_water_anchor, carcass_anchor) * 0.06,
    )
    apex_condition_phase_anchor_runtime = max(
        float(runtime_state.get("apex_condition_phase_anchor_runtime", 0.0)),
        apex_condition_phase_runtime * 0.64
        + apex_regional_health_anchor_runtime * 0.18
        + apex_anchor_prosperity_runtime * 0.10
        + max(surface_water_anchor, carcass_anchor) * 0.08,
    )
    herd_resource_anchor_runtime = max(0.0, herd_surface_water_runtime * 0.6 + herd_regional_health_runtime * 0.4)
    aerial_resource_anchor_runtime = max(0.0, aerial_carcass_runtime * 0.6 + aerial_regional_health_runtime * 0.4)

    if pride_strength > 0.0:
        runtime_signals["lion_pride_strength"] = round(pride_strength, 3)
        pressure_scores["pride_core_range"] = round(pressure_scores.get("pride_core_range", 0.0) + min(0.28, pride_strength * 0.22), 2)
    if takeover_strength > 0.0:
        runtime_signals["lion_takeover_pressure"] = round(takeover_strength, 3)
        pressure_scores["male_takeover_front"] = round(pressure_scores.get("male_takeover_front", 0.0) + min(0.24, takeover_strength * 0.20), 2)
    if pride_count > 0:
        runtime_signals["lion_pride_count"] = pride_count
        pressure_scores["pride_core_range"] = round(pressure_scores.get("pride_core_range", 0.0) + min(0.18, pride_count * 0.04), 2)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + max(0.0, pride_count - 1) * 0.06,
            2,
        )
    if lion_hotspot_count > 0:
        runtime_signals["lion_hotspot_count"] = lion_hotspot_count
        pressure_scores["pride_core_range"] = round(
            pressure_scores.get("pride_core_range", 0.0) + min(0.12, lion_hotspot_count * 0.03),
            2,
        )
    if lion_cycle_expansion > 0.0:
        runtime_signals["lion_cycle_expansion"] = round(lion_cycle_expansion, 3)
        pressure_scores["pride_core_range"] = round(
            pressure_scores.get("pride_core_range", 0.0) + min(0.16, lion_cycle_expansion * 0.12),
            2,
        )
    if lion_cycle_contraction > 0.0:
        runtime_signals["lion_cycle_contraction"] = round(lion_cycle_contraction, 3)
        pressure_scores["male_takeover_front"] = round(
            pressure_scores.get("male_takeover_front", 0.0) + min(0.12, lion_cycle_contraction * 0.10),
            2,
        )
    if clan_cohesion > 0.0:
        runtime_signals["hyena_clan_cohesion"] = round(clan_cohesion, 3)
        pressure_scores["clan_den_range"] = round(pressure_scores.get("clan_den_range", 0.0) + min(0.24, clan_cohesion * 0.20), 2)
    if clan_front_strength > 0.0:
        runtime_signals["hyena_clan_front_pressure"] = round(clan_front_strength, 3)
        pressure_scores["scavenger_perimeter"] = round(pressure_scores.get("scavenger_perimeter", 0.0) + min(0.22, clan_front_strength * 0.18), 2)
    if clan_count > 0:
        runtime_signals["hyena_clan_count"] = clan_count
        pressure_scores["clan_den_range"] = round(pressure_scores.get("clan_den_range", 0.0) + min(0.18, clan_count * 0.035), 2)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + max(0.0, clan_count - 1) * 0.05,
            2,
        )
    if hyena_hotspot_count > 0:
        runtime_signals["hyena_hotspot_count"] = hyena_hotspot_count
        pressure_scores["clan_den_range"] = round(
            pressure_scores.get("clan_den_range", 0.0) + min(0.10, hyena_hotspot_count * 0.025),
            2,
        )
    if hyena_cycle_expansion > 0.0:
        runtime_signals["hyena_cycle_expansion"] = round(hyena_cycle_expansion, 3)
        pressure_scores["clan_den_range"] = round(
            pressure_scores.get("clan_den_range", 0.0) + min(0.15, hyena_cycle_expansion * 0.11),
            2,
        )
    if hyena_cycle_contraction > 0.0:
        runtime_signals["hyena_cycle_contraction"] = round(hyena_cycle_contraction, 3)
        pressure_scores["scavenger_perimeter"] = round(
            pressure_scores.get("scavenger_perimeter", 0.0) + min(0.11, hyena_cycle_contraction * 0.09),
            2,
        )
    if shared_hotspot_overlap > 0:
        runtime_signals["shared_hotspot_overlap"] = shared_hotspot_overlap
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.18, shared_hotspot_overlap * 0.09),
            2,
        )
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.15, shared_hotspot_overlap * 0.07),
            2,
        )
    if herd_hotspot_count > 0:
        runtime_signals["herd_hotspot_count"] = herd_hotspot_count
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.14, herd_hotspot_count * 0.03),
            2,
        )
    if herd_route_cycle_runtime > 0.0:
        runtime_signals["herd_route_cycle_runtime"] = round(herd_route_cycle_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.10, herd_route_cycle_runtime * 0.08),
            2,
        )
    if herd_birth_runtime > 0.0:
        runtime_signals["herd_birth_runtime"] = round(herd_birth_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.10, herd_birth_runtime * 0.08),
            2,
        )
    herd_birth_memory_runtime = float(runtime_state.get("herd_birth_memory_runtime", 0.0))
    herd_birth_memory_world_pressure_runtime = float(runtime_state.get("herd_birth_memory_world_pressure_runtime", 0.0))
    if herd_birth_memory_runtime > 0.0:
        runtime_signals["herd_birth_memory_runtime"] = round(herd_birth_memory_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_birth_memory_runtime * 0.06),
            2,
        )
    if herd_birth_memory_world_pressure_runtime > 0.0:
        runtime_signals["herd_birth_memory_world_pressure_runtime"] = round(herd_birth_memory_world_pressure_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_birth_memory_world_pressure_runtime * 0.06),
            2,
        )
    if herd_surface_water_runtime > 0.0:
        runtime_signals["herd_surface_water_runtime"] = round(herd_surface_water_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.10, herd_surface_water_runtime * 0.07),
            2,
        )
    if herd_regional_health_runtime > 0.0:
        runtime_signals["herd_regional_health_runtime"] = round(herd_regional_health_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_regional_health_runtime * 0.05),
            2,
        )
    if herd_condition_runtime > 0.0:
        runtime_signals["herd_condition_runtime"] = round(herd_condition_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.07, herd_condition_runtime * 0.05),
            2,
        )
    if herd_condition_phase_runtime > 0.0:
        runtime_signals["herd_condition_phase_runtime"] = round(herd_condition_phase_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_condition_phase_runtime * 0.05),
            2,
        )
    if herd_condition_phase_anchor_runtime > 0.0:
        runtime_signals["herd_condition_phase_anchor_runtime"] = round(herd_condition_phase_anchor_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.09, herd_condition_phase_anchor_runtime * 0.06),
            2,
        )
    if herd_condition_phase_bias_runtime > 0.0:
        runtime_signals["herd_condition_phase_bias_runtime"] = round(herd_condition_phase_bias_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.07, herd_condition_phase_bias_runtime * 0.05),
            2,
        )
    if herd_regional_health_anchor_runtime > 0.0:
        runtime_signals["herd_regional_health_anchor_runtime"] = round(herd_regional_health_anchor_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.10, herd_regional_health_anchor_runtime * 0.06),
            2,
        )
    if herd_condition_anchor_runtime > 0.0:
        runtime_signals["herd_condition_anchor_runtime"] = round(herd_condition_anchor_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_condition_anchor_runtime * 0.06),
            2,
        )
    if herd_resource_anchor_runtime > 0.0:
        runtime_signals["herd_resource_anchor_runtime"] = round(herd_resource_anchor_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.10, herd_resource_anchor_runtime * 0.06),
            2,
        )
    if herd_anchor_prosperity_runtime > 0.0:
        runtime_signals["herd_anchor_prosperity_runtime"] = round(herd_anchor_prosperity_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_anchor_prosperity_runtime * 0.05),
            2,
        )
    if herd_apex_overlap > 0:
        runtime_signals["herd_apex_overlap"] = herd_apex_overlap
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.12, herd_apex_overlap * 0.04),
            2,
        )
    if vulture_hotspot_count > 0:
        runtime_signals["vulture_hotspot_count"] = vulture_hotspot_count
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, vulture_hotspot_count * 0.025),
            2,
        )
    if aerial_carrion_cycle_runtime > 0.0:
        runtime_signals["aerial_carrion_cycle_runtime"] = round(aerial_carrion_cycle_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, aerial_carrion_cycle_runtime * 0.08),
            2,
        )
    if aerial_birth_runtime > 0.0:
        runtime_signals["aerial_birth_runtime"] = round(aerial_birth_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, aerial_birth_runtime * 0.08),
            2,
        )
    aerial_birth_memory_runtime = float(runtime_state.get("aerial_birth_memory_runtime", 0.0))
    aerial_birth_memory_world_pressure_runtime = float(runtime_state.get("aerial_birth_memory_world_pressure_runtime", 0.0))
    if aerial_birth_memory_runtime > 0.0:
        runtime_signals["aerial_birth_memory_runtime"] = round(aerial_birth_memory_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_birth_memory_runtime * 0.06),
            2,
        )
    if aerial_birth_memory_world_pressure_runtime > 0.0:
        runtime_signals["aerial_birth_memory_world_pressure_runtime"] = round(aerial_birth_memory_world_pressure_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_birth_memory_world_pressure_runtime * 0.06),
            2,
        )
    if aerial_carcass_runtime > 0.0:
        runtime_signals["aerial_carcass_runtime"] = round(aerial_carcass_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, aerial_carcass_runtime * 0.07),
            2,
        )
    if aerial_regional_health_runtime > 0.0:
        runtime_signals["aerial_regional_health_runtime"] = round(aerial_regional_health_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_regional_health_runtime * 0.05),
            2,
        )
    if aerial_condition_runtime > 0.0:
        runtime_signals["aerial_condition_runtime"] = round(aerial_condition_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.07, aerial_condition_runtime * 0.05),
            2,
        )
    if aerial_condition_phase_runtime > 0.0:
        runtime_signals["aerial_condition_phase_runtime"] = round(aerial_condition_phase_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_condition_phase_runtime * 0.05),
            2,
        )
    if aerial_condition_phase_anchor_runtime > 0.0:
        runtime_signals["aerial_condition_phase_anchor_runtime"] = round(aerial_condition_phase_anchor_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.09, aerial_condition_phase_anchor_runtime * 0.06),
            2,
        )
    if aerial_condition_phase_bias_runtime > 0.0:
        runtime_signals["aerial_condition_phase_bias_runtime"] = round(aerial_condition_phase_bias_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.07, aerial_condition_phase_bias_runtime * 0.05),
            2,
        )
    if aerial_regional_health_anchor_runtime > 0.0:
        runtime_signals["aerial_regional_health_anchor_runtime"] = round(aerial_regional_health_anchor_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, aerial_regional_health_anchor_runtime * 0.06),
            2,
        )
    if aerial_condition_anchor_runtime > 0.0:
        runtime_signals["aerial_condition_anchor_runtime"] = round(aerial_condition_anchor_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_condition_anchor_runtime * 0.06),
            2,
        )
    if aerial_resource_anchor_runtime > 0.0:
        runtime_signals["aerial_resource_anchor_runtime"] = round(aerial_resource_anchor_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, aerial_resource_anchor_runtime * 0.06),
            2,
        )
    if aerial_anchor_prosperity_runtime > 0.0:
        runtime_signals["aerial_anchor_prosperity_runtime"] = round(aerial_anchor_prosperity_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_anchor_prosperity_runtime * 0.05),
            2,
        )
    if vulture_carrion_overlap > 0:
        runtime_signals["vulture_carrion_overlap"] = vulture_carrion_overlap
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.12, vulture_carrion_overlap * 0.04),
            2,
        )
    if apex_regional_health_runtime > 0.0:
        runtime_signals["apex_regional_health_runtime"] = round(apex_regional_health_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_regional_health_runtime * 0.05),
            2,
        )
    if apex_condition_runtime > 0.0:
        runtime_signals["apex_condition_runtime"] = round(apex_condition_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.07, apex_condition_runtime * 0.05),
            2,
        )
    if apex_condition_phase_runtime > 0.0:
        runtime_signals["apex_condition_phase_runtime"] = round(apex_condition_phase_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_condition_phase_runtime * 0.05),
            2,
        )
    if apex_condition_phase_anchor_runtime > 0.0:
        runtime_signals["apex_condition_phase_anchor_runtime"] = round(apex_condition_phase_anchor_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.09, apex_condition_phase_anchor_runtime * 0.06),
            2,
        )
    if apex_condition_phase_bias_runtime > 0.0:
        runtime_signals["apex_condition_phase_bias_runtime"] = round(apex_condition_phase_bias_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.07, apex_condition_phase_bias_runtime * 0.05),
            2,
        )
    if apex_regional_health_anchor_runtime > 0.0:
        runtime_signals["apex_regional_health_anchor_runtime"] = round(apex_regional_health_anchor_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.10, apex_regional_health_anchor_runtime * 0.06),
            2,
        )
    if apex_condition_anchor_runtime > 0.0:
        runtime_signals["apex_condition_anchor_runtime"] = round(apex_condition_anchor_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_condition_anchor_runtime * 0.06),
            2,
        )
    if apex_anchor_prosperity_runtime > 0.0:
        runtime_signals["apex_anchor_prosperity_runtime"] = round(apex_anchor_prosperity_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_anchor_prosperity_runtime * 0.05),
            2,
        )
    if herd_regional_bias_runtime > 0.0:
        runtime_signals["herd_regional_bias_runtime"] = round(herd_regional_bias_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_regional_bias_runtime * 0.05),
            2,
        )
    if aerial_regional_bias_runtime > 0.0:
        runtime_signals["aerial_regional_bias_runtime"] = round(aerial_regional_bias_runtime, 3)
    if herd_world_pressure_runtime > 0.0:
        runtime_signals["herd_world_pressure_runtime"] = round(herd_world_pressure_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.10, herd_world_pressure_runtime * 0.08),
            2,
        )
    if herd_world_pressure_window_runtime > 0.0:
        runtime_signals["herd_world_pressure_window_runtime"] = round(herd_world_pressure_window_runtime, 3)
        pressure_scores["waterhole_spacing"] = round(
            pressure_scores.get("waterhole_spacing", 0.0) + min(0.08, herd_world_pressure_window_runtime * 0.06),
            2,
        )
    if aerial_world_pressure_runtime > 0.0:
        runtime_signals["aerial_world_pressure_runtime"] = round(aerial_world_pressure_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, aerial_world_pressure_runtime * 0.08),
            2,
        )
    if aerial_world_pressure_window_runtime > 0.0:
        runtime_signals["aerial_world_pressure_window_runtime"] = round(aerial_world_pressure_window_runtime, 3)
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_world_pressure_window_runtime * 0.06),
            2,
        )
    if apex_world_pressure_runtime > 0.0:
        runtime_signals["apex_world_pressure_runtime"] = round(apex_world_pressure_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.10, apex_world_pressure_runtime * 0.08),
            2,
        )
    if apex_birth_runtime > 0.0:
        runtime_signals["apex_birth_runtime"] = round(apex_birth_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.10, apex_birth_runtime * 0.08),
            2,
        )
    apex_birth_memory_runtime = float(runtime_state.get("apex_birth_memory_runtime", 0.0))
    apex_birth_memory_world_pressure_runtime = float(runtime_state.get("apex_birth_memory_world_pressure_runtime", 0.0))
    if apex_birth_memory_runtime > 0.0:
        runtime_signals["apex_birth_memory_runtime"] = round(apex_birth_memory_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_birth_memory_runtime * 0.06),
            2,
        )
    if apex_birth_memory_world_pressure_runtime > 0.0:
        runtime_signals["apex_birth_memory_world_pressure_runtime"] = round(apex_birth_memory_world_pressure_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_birth_memory_world_pressure_runtime * 0.06),
            2,
        )
    if apex_world_pressure_window_runtime > 0.0:
        runtime_signals["apex_world_pressure_window_runtime"] = round(apex_world_pressure_window_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_world_pressure_window_runtime * 0.06),
            2,
        )
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.08, aerial_regional_bias_runtime * 0.05),
            2,
        )
    if apex_regional_bias_runtime > 0.0:
        runtime_signals["apex_regional_bias_runtime"] = round(apex_regional_bias_runtime, 3)
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, apex_regional_bias_runtime * 0.05),
            2,
        )

    previous_lion_hotspots = int(previous_runtime.get("lion_hotspot_count", 0))
    previous_hyena_hotspots = int(previous_runtime.get("hyena_hotspot_count", 0))
    previous_shared_overlap = int(previous_runtime.get("shared_hotspot_overlap", 0))
    if lion_hotspot_count > 0 and previous_lion_hotspots > 0:
        persistence = min(lion_hotspot_count, previous_lion_hotspots)
        runtime_signals["lion_hotspot_persistence"] = persistence
        pressure_scores["pride_core_range"] = round(
            pressure_scores.get("pride_core_range", 0.0) + min(0.12, persistence * 0.04),
            2,
        )
    if hyena_hotspot_count > 0 and previous_hyena_hotspots > 0:
        persistence = min(hyena_hotspot_count, previous_hyena_hotspots)
        runtime_signals["hyena_hotspot_persistence"] = persistence
        pressure_scores["clan_den_range"] = round(
            pressure_scores.get("clan_den_range", 0.0) + min(0.10, persistence * 0.035),
            2,
        )
    if shared_hotspot_overlap > 0 and previous_shared_overlap > 0:
        persistence = min(shared_hotspot_overlap, previous_shared_overlap)
        runtime_signals["shared_hotspot_persistence"] = persistence
        pressure_scores["carcass_route_overlap"] = round(
            pressure_scores.get("carcass_route_overlap", 0.0) + min(0.10, persistence * 0.05),
            2,
        )
    lion_shift = max(0, lion_hotspot_count - previous_lion_hotspots)
    hyena_shift = max(0, hyena_hotspot_count - previous_hyena_hotspots)
    overlap_shift = max(0, shared_hotspot_overlap - previous_shared_overlap)
    if lion_shift > 0:
        runtime_signals["lion_hotspot_shift"] = lion_shift
        pressure_scores["male_takeover_front"] = round(
            pressure_scores.get("male_takeover_front", 0.0) + min(0.09, lion_shift * 0.04),
            2,
        )
    if hyena_shift > 0:
        runtime_signals["hyena_hotspot_shift"] = hyena_shift
        pressure_scores["scavenger_perimeter"] = round(
            pressure_scores.get("scavenger_perimeter", 0.0) + min(0.08, hyena_shift * 0.035),
            2,
        )
    if overlap_shift > 0:
        runtime_signals["shared_hotspot_shift"] = overlap_shift
        pressure_scores["apex_boundary_conflict"] = round(
            pressure_scores.get("apex_boundary_conflict", 0.0) + min(0.08, overlap_shift * 0.04),
            2,
        )

    if region.region_id == "temperate_grassland":
        if previous_grassland_layer == "herd_layer":
            runtime_signals["herd_channel_bias"] = 1
            pressure_scores["waterhole_spacing"] = round(pressure_scores.get("waterhole_spacing", 0.0) + 0.08, 2)
        elif previous_grassland_layer == "predator_layer":
            runtime_signals["apex_hotspot_bias"] = 1
            pressure_scores["apex_boundary_conflict"] = round(pressure_scores.get("apex_boundary_conflict", 0.0) + 0.08, 2)
        elif previous_grassland_layer in {"scavenger_layer", "social_layer"}:
            runtime_signals["scavenger_hotspot_bias"] = 1
            pressure_scores["carcass_route_overlap"] = round(pressure_scores.get("carcass_route_overlap", 0.0) + 0.07, 2)

        if previous_carrion_layer == "herd_source_layer":
            runtime_signals["herd_source_bias"] = 1
            pressure_scores["waterhole_spacing"] = round(pressure_scores.get("waterhole_spacing", 0.0) + 0.05, 2)
        elif previous_carrion_layer == "kill_layer":
            runtime_signals["kill_corridor_bias"] = 1
            pressure_scores["carcass_route_overlap"] = round(pressure_scores.get("carcass_route_overlap", 0.0) + 0.08, 2)
        elif previous_carrion_layer == "aerial_scavenge_layer":
            runtime_signals["aerial_lane_bias"] = 1
            pressure_scores["carcass_route_overlap"] = round(pressure_scores.get("carcass_route_overlap", 0.0) + 0.06, 2)

        if "regional_prosperity_anchor" in previous_social_cycles:
            runtime_signals["regional_prosperity_bias"] = 1
            pressure_scores["waterhole_spacing"] = round(pressure_scores.get("waterhole_spacing", 0.0) + 0.06, 2)
            pressure_scores["carcass_route_overlap"] = round(pressure_scores.get("carcass_route_overlap", 0.0) + 0.05, 2)
        if "regional_stability_anchor" in previous_social_cycles:
            runtime_signals["regional_stability_bias"] = 1
            pressure_scores["pride_core_range"] = round(pressure_scores.get("pride_core_range", 0.0) + 0.05, 2)
            pressure_scores["clan_den_range"] = round(pressure_scores.get("clan_den_range", 0.0) + 0.05, 2)
        if "regional_collapse_anchor" in previous_social_cycles or float(
            previous_social_prosperity.get("grassland_collapse_phase", 0.0)
        ) >= 0.18:
            runtime_signals["regional_collapse_bias"] = 1
            pressure_scores["apex_boundary_conflict"] = round(
                pressure_scores.get("apex_boundary_conflict", 0.0) + 0.07,
                2,
            )
            pressure_scores["carcass_route_overlap"] = round(
                pressure_scores.get("carcass_route_overlap", 0.0) + 0.05,
                2,
            )

    return RegionTerritorySummary(
        region_id=region.region_id,
        active_species=active_species,
        pressure_scores=dict(sorted(pressure_scores.items())),
        contested_zones=sorted(contested_zones),
        narrative_territory=narrative_territory,
        runtime_signals=runtime_signals,
    )


def apply_region_territory_feedback(
    region: Region, territory: RegionTerritorySummary, feedback_scale: float = 0.04
) -> None:
    """将领地压力轻量回灌到区域状态。"""

    scores = territory.pressure_scores
    _adjust(region.hazard_state, "territorial_conflict", sum(scores.values()) * 0.12, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("apex_boundary_conflict", 0.0) * 0.45, feedback_scale)
    _adjust(region.hazard_state, "shoreline_risk", scores.get("shoreline_standoff", 0.0) * 0.65, feedback_scale)

    _adjust(region.resource_state, "surface_water", -scores.get("waterhole_spacing", 0.0) * 0.22, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("carcass_route_overlap", 0.0) * 0.28, feedback_scale)
    _adjust(region.resource_state, "reed_cover", scores.get("dam_complex_claim", 0.0) * 0.24, feedback_scale)
    _adjust(region.resource_state, "shore_hatch", -scores.get("ambush_bank_hold", 0.0) * 0.20, feedback_scale)

    _adjust(region.health_state, "fragmentation", sum(scores.values()) * 0.04, feedback_scale)
    _adjust(region.health_state, "resilience", -scores.get("male_takeover_front", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "resilience", -scores.get("shoreline_standoff", 0.0) * 0.08, feedback_scale)


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

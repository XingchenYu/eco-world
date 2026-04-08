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
    shared_hotspot_overlap = int(runtime_state.get("shared_hotspot_overlap", 0.0))

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

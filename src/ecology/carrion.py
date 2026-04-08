"""v4 尸体资源链摘要、反馈与重平衡。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

from src.data import WorldRegistry
from src.world import Region


@dataclass
class RegionCarrionChainSummary:
    """草原尸体资源链摘要。"""

    region_id: str
    key_species: List[str] = field(default_factory=list)
    resource_scores: Dict[str, float] = field(default_factory=dict)
    layer_scores: Dict[str, float] = field(default_factory=dict)
    layer_species: Dict[str, List[str]] = field(default_factory=dict)
    narrative_chain: List[str] = field(default_factory=list)


def build_region_carrion_chain_summary(
    region: Region,
    registry: WorldRegistry,
    territory_summary: Optional[object] = None,
    social_trend_summary: Optional[object] = None,
) -> RegionCarrionChainSummary:
    """构建草原区尸体资源链摘要。"""

    if "grassland" not in region.dominant_biomes:
        return RegionCarrionChainSummary(region_id=region.region_id)

    region_species = set(region.species_pool)
    key_species = [species for species in ("lion", "hyena", "vulture", "antelope", "zebra") if species in region_species]
    resource_scores: Dict[str, float] = {}
    layer_scores: Dict[str, float] = {}
    layer_species: Dict[str, List[str]] = {
        "kill_layer": [],
        "scavenge_layer": [],
        "aerial_scavenge_layer": [],
        "herd_source_layer": [],
    }
    narrative_chain: List[str] = []

    def add_score(key: str, value: float, narrative: str) -> None:
        resource_scores[key] = round(resource_scores.get(key, 0.0) + value, 2)
        if narrative not in narrative_chain:
            narrative_chain.append(narrative)

    def add_layer(layer: str, species: str, value: float) -> None:
        layer_scores[layer] = round(layer_scores.get(layer, 0.0) + value, 2)
        if species not in layer_species[layer]:
            layer_species[layer].append(species)

    if "lion" in region_species:
        add_score("kill_generation", 0.74, "狮群会把草食群猎杀事件转化成局部尸体资源热点。")
        add_score("kill_site_control", 0.62, "狮群会优先控制击杀点周边的草原空间。")
        add_layer("kill_layer", "lion", 0.74)
    if "hyena" in region_species:
        add_score("scavenger_pressure", 0.68, "鬣狗群会高频利用残食和尸体，把草原能量回收到清道夫链。")
        add_score("carcass_recycling", 0.57, "鬣狗群提升尸体资源的周转速度。")
        add_layer("scavenge_layer", "hyena", 0.68)
    if "vulture" in region_species:
        add_score("aerial_scavenging", 0.63, "秃鹫会把尸体热点转化成空中清道夫网络。")
        add_score("thermal_tracking", 0.49, "秃鹫会围绕热气流柱快速锁定大范围尸体资源。")
        add_layer("aerial_scavenge_layer", "vulture", 0.63)
    if "antelope" in region_species:
        add_score("herd_mortality_supply", 0.46, "羚羊群为草原尸体资源链提供稳定的中型猎物来源。")
        add_layer("herd_source_layer", "antelope", 0.46)
    if "zebra" in region_species:
        add_score("large_carcass_supply", 0.52, "斑马群提供更大体量的尸体资源峰值。")
        add_layer("herd_source_layer", "zebra", 0.52)
    if {"lion", "hyena"} <= region_species:
        add_score("carcass_competition_loop", 0.66, "狮群与鬣狗围绕尸体与击杀点形成持续争夺。")
    if {"lion", "hyena", "vulture"} <= region_species:
        add_score("scavenger_stack", 0.58, "地面与空中清道夫共同放大草原尸体资源链。")
    if {"lion", "hyena"} <= region_species and {"antelope", "zebra"} & region_species:
        add_score("carrion_energy_loop", 0.71, "草食群、狮群和鬣狗共同闭合草原尸体资源链。")
    if {"lion", "hyena", "vulture"} <= region_species and {"antelope", "zebra"} & region_species:
        add_score("full_carrion_closure", 0.76, "草食群、顶级捕食者、地面清道夫和空中清道夫共同闭合更完整的草原尸体资源网络。")
    if territory_summary is not None:
        runtime_signals = getattr(territory_summary, "runtime_signals", {}) or {}
        shared_hotspots = int(runtime_signals.get("shared_hotspot_overlap", 0))
        lion_hotspots = int(runtime_signals.get("lion_hotspot_count", 0))
        hyena_hotspots = int(runtime_signals.get("hyena_hotspot_count", 0))
        if shared_hotspots > 0:
            add_score("kill_corridor_overlap", min(0.38, shared_hotspots * 0.15), "领地热点重叠会把击杀点和尸体点压缩进更少的高频通道。")
        if lion_hotspots > 0 and hyena_hotspots > 0:
            add_score("scavenger_lane_pressure", min(0.34, (lion_hotspots + hyena_hotspots) * 0.06), "多个顶层热点会强化地面与空中清道夫对尸体通道的跟随压力。")
    if social_trend_summary is not None:
        hotspot_scores = getattr(social_trend_summary, "hotspot_scores", {}) or {}
        lion_hotspot_memory = float(hotspot_scores.get("lion_hotspot_memory", 0.0))
        hyena_hotspot_memory = float(hotspot_scores.get("hyena_hotspot_memory", 0.0))
        shared_hotspot_memory = float(hotspot_scores.get("shared_hotspot_memory", 0.0))
        if lion_hotspot_memory > 0.0:
            add_score("hotspot_cycle_carrion", lion_hotspot_memory * 0.22, "持续的狮群热点记忆会把击杀点维持成更稳定的尸体资源通道。")
        if hyena_hotspot_memory > 0.0:
            add_score("hotspot_cycle_carrion", hyena_hotspot_memory * 0.20, "持续的鬣狗热点记忆会延长尸体资源的地面清道夫使用窗口。")
        if shared_hotspot_memory > 0.0:
            add_score("hotspot_cycle_tracking", shared_hotspot_memory * 0.24, "共享热点记忆会强化秃鹫与地面清道夫对尸体通道的协同追踪。")

    return RegionCarrionChainSummary(
        region_id=region.region_id,
        key_species=key_species,
        resource_scores=dict(sorted(resource_scores.items())),
        layer_scores=dict(sorted(layer_scores.items())),
        layer_species={layer: sorted(species) for layer, species in layer_species.items() if species},
        narrative_chain=narrative_chain,
    )


def apply_region_carrion_chain_feedback(
    region: Region,
    carrion_chain: RegionCarrionChainSummary,
    feedback_scale: float = 0.02,
) -> None:
    """将尸体资源链轻量回灌到区域状态。"""

    scores = carrion_chain.resource_scores
    _adjust(region.resource_state, "carcass_availability", scores.get("kill_generation", 0.0) * 0.26, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("large_carcass_supply", 0.0) * 0.24, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", -scores.get("aerial_scavenging", 0.0) * 0.10, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("kill_corridor_overlap", 0.0) * 0.18, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("hotspot_cycle_carrion", 0.0) * 0.16, feedback_scale)
    _adjust(region.resource_state, "dung_cycle", scores.get("carcass_recycling", 0.0) * 0.18, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("kill_site_control", 0.0) * 0.16, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("carcass_competition_loop", 0.0) * 0.12, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("scavenger_lane_pressure", 0.0) * 0.14, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("hotspot_cycle_tracking", 0.0) * 0.14, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("carrion_energy_loop", 0.0) * 0.14, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("full_carrion_closure", 0.0) * 0.12, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("hotspot_cycle_carrion", 0.0) * 0.08, feedback_scale)


def apply_region_carrion_chain_rebalancing(
    region: Region,
    carrion_chain: RegionCarrionChainSummary,
    territory_summary: Optional[object] = None,
    social_trend_summary: Optional[object] = None,
) -> List[dict]:
    """根据尸体资源链对草原关键物种池做低频、轻量重平衡。"""

    if not carrion_chain.resource_scores:
        return []

    adjustments: List[dict] = []
    species_pool = region.species_pool
    scores = carrion_chain.resource_scores

    lion_count = species_pool.get("lion", 0)
    hyena_count = species_pool.get("hyena", 0)
    vulture_count = species_pool.get("vulture", 0)
    antelope_count = species_pool.get("antelope", 0)
    zebra_count = species_pool.get("zebra", 0)
    hotspot_overlap = 0
    lion_hotspots = 0
    hyena_hotspots = 0
    pride_strength = 0.0
    clan_cohesion = 0.0
    pride_count = 0
    clan_count = 0
    lion_recovery_bias = 0.0
    hyena_recovery_bias = 0.0
    lion_expansion_phase = 0.0
    hyena_expansion_phase = 0.0
    grassland_boom_phase = 0.0
    grassland_bust_phase = 0.0
    lion_hotspot_memory = 0.0
    hyena_hotspot_memory = 0.0
    shared_hotspot_memory = 0.0
    if territory_summary is not None:
        runtime_signals = getattr(territory_summary, "runtime_signals", {}) or {}
        hotspot_overlap = int(runtime_signals.get("shared_hotspot_overlap", 0))
        lion_hotspots = int(runtime_signals.get("lion_hotspot_count", 0))
        hyena_hotspots = int(runtime_signals.get("hyena_hotspot_count", 0))
        pride_strength = float(runtime_signals.get("lion_pride_strength", 0.0))
        clan_cohesion = float(runtime_signals.get("hyena_clan_cohesion", 0.0))
        pride_count = int(runtime_signals.get("lion_pride_count", 0))
        clan_count = int(runtime_signals.get("hyena_clan_count", 0))
    if social_trend_summary is not None:
        trend_scores = getattr(social_trend_summary, "trend_scores", {}) or {}
        phase_scores = getattr(social_trend_summary, "phase_scores", {}) or {}
        hotspot_scores = getattr(social_trend_summary, "hotspot_scores", {}) or {}
        lion_recovery_bias = float(trend_scores.get("lion_recovery_bias", 0.0))
        hyena_recovery_bias = float(trend_scores.get("hyena_recovery_bias", 0.0))
        lion_expansion_phase = float(phase_scores.get("lion_expansion_phase", 0.0))
        hyena_expansion_phase = float(phase_scores.get("hyena_expansion_phase", 0.0))
        boom_bust_scores = getattr(social_trend_summary, "boom_bust_scores", {}) or {}
        grassland_boom_phase = float(boom_bust_scores.get("grassland_boom_phase", 0.0))
        grassland_bust_phase = float(boom_bust_scores.get("grassland_bust_phase", 0.0))
        lion_hotspot_memory = float(hotspot_scores.get("lion_hotspot_memory", 0.0))
        hyena_hotspot_memory = float(hotspot_scores.get("hyena_hotspot_memory", 0.0))
        shared_hotspot_memory = float(hotspot_scores.get("shared_hotspot_memory", 0.0))

    if scores.get("carrion_energy_loop", 0.0) >= 0.7 and antelope_count < 20:
        species_pool["antelope"] = antelope_count + 1
        adjustments.append(
            {
                "source_species": "carrion_chain",
                "target_species": "antelope",
                "layer_group": "herd_source_layer",
                "effect": "carrion_source_support",
                "new_target_count": species_pool["antelope"],
            }
        )

    if scores.get("carcass_competition_loop", 0.0) >= 0.6 and lion_count >= 3 and hyena_count >= 4:
        species_pool["hyena"] = hyena_count - 1
        adjustments.append(
            {
                "source_species": "lion",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "kill_site_exclusion",
                "new_target_count": species_pool["hyena"],
            }
        )
    elif scores.get("scavenger_pressure", 0.0) >= 0.65 and hyena_count >= 4 and lion_count >= 2:
        species_pool["lion"] = lion_count - 1
        adjustments.append(
            {
                "source_species": "hyena",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "scavenger_pushback",
                "new_target_count": species_pool["lion"],
            }
        )

    if scores.get("large_carcass_supply", 0.0) >= 0.5 and zebra_count < 14:
        species_pool["zebra"] = zebra_count + 1
        adjustments.append(
            {
                "source_species": "carrion_chain",
                "target_species": "zebra",
                "layer_group": "herd_source_layer",
                "effect": "large_carcass_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("scavenger_stack", 0.0) >= 0.55 and vulture_count < 8:
        species_pool["vulture"] = vulture_count + 1
        adjustments.append(
            {
                "source_species": "carrion_chain",
                "target_species": "vulture",
                "layer_group": "aerial_scavenge_layer",
                "effect": "aerial_scavenger_support",
                "new_target_count": species_pool["vulture"],
            }
        )
    if hotspot_overlap > 0 and vulture_count < 9:
        species_pool["vulture"] = species_pool["vulture"] + 1
        adjustments.append(
            {
                "source_species": "territory",
                "target_species": "vulture",
                "layer_group": "aerial_scavenge_layer",
                "effect": "overlap_tracking_support",
                "new_target_count": species_pool["vulture"],
            }
        )
    if hotspot_overlap > 0 and lion_hotspots >= hyena_hotspots and hyena_count >= 4:
        species_pool["hyena"] = hyena_count - 1
        adjustments.append(
            {
                "source_species": "territory",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "kill_corridor_exclusion",
                "new_target_count": species_pool["hyena"],
            }
        )
    elif hotspot_overlap > 0 and hyena_hotspots > lion_hotspots and lion_count >= 3:
        species_pool["lion"] = lion_count - 1
        adjustments.append(
            {
                "source_species": "territory",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "kill_corridor_exclusion",
                "new_target_count": species_pool["lion"],
            }
        )
    if pride_strength >= 0.55 and lion_count < 5 and scores.get("kill_generation", 0.0) >= 0.45:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "stable_pride_carcass_recovery",
                "new_target_count": species_pool["lion"],
            }
        )
    if clan_cohesion >= 0.5 and hyena_count < 6 and scores.get("scavenger_pressure", 0.0) >= 0.45:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "stable_clan_carrion_recovery",
                "new_target_count": species_pool["hyena"],
            }
        )
    if (
        pride_strength >= 0.68
        and pride_count >= 2
        and lion_hotspots >= 2
        and hotspot_overlap <= 1
        and scores.get("kill_generation", 0.0) >= 0.58
        and scores.get("carrion_energy_loop", 0.0) >= 0.70
        and lion_count < 6
    ):
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "pride_carrion_expansion_window",
                "new_target_count": species_pool["lion"],
            }
        )
    if (
        clan_cohesion >= 0.65
        and clan_count >= 2
        and hyena_hotspots >= 2
        and hotspot_overlap <= 1
        and scores.get("scavenger_pressure", 0.0) >= 0.58
        and scores.get("carrion_energy_loop", 0.0) >= 0.70
        and hyena_count < 7
    ):
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "clan_carrion_expansion_window",
                "new_target_count": species_pool["hyena"],
            }
        )
    if (
        lion_count <= 1
        and pride_strength >= 0.72
        and pride_count >= 2
        and lion_hotspots >= 1
        and scores.get("kill_generation", 0.0) >= 0.62
        and scores.get("carrion_energy_loop", 0.0) >= 0.70
    ):
        species_pool["lion"] = species_pool.get("lion", 0) + 2
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "pride_carrion_recolonization_window",
                "new_target_count": species_pool["lion"],
            }
        )
    if (
        hyena_count <= 1
        and clan_cohesion >= 0.7
        and clan_count >= 2
        and hyena_hotspots >= 1
        and scores.get("scavenger_pressure", 0.0) >= 0.62
        and scores.get("carrion_energy_loop", 0.0) >= 0.70
    ):
        species_pool["hyena"] = species_pool.get("hyena", 0) + 2
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "clan_carrion_recolonization_window",
                "new_target_count": species_pool["hyena"],
            }
        )
    if lion_recovery_bias >= 0.58 and lion_count <= 2 and scores.get("kill_generation", 0.0) >= 0.55:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_trend",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "trend_carrion_recovery",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_recovery_bias >= 0.56 and hyena_count <= 2 and scores.get("scavenger_pressure", 0.0) >= 0.55:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_trend",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "trend_carrion_recovery",
                "new_target_count": species_pool["hyena"],
            }
        )
    if lion_expansion_phase >= 0.58 and 2 <= lion_count < 6 and scores.get("kill_generation", 0.0) >= 0.60:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "cycle_carrion_expansion",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_expansion_phase >= 0.56 and 2 <= hyena_count < 7 and scores.get("scavenger_pressure", 0.0) >= 0.60:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "cycle_carrion_expansion",
                "new_target_count": species_pool["hyena"],
            }
        )
    if lion_hotspot_memory >= 0.34 and lion_hotspots >= 2 and scores.get("kill_generation", 0.0) >= 0.42:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "lion",
                "layer_group": "kill_layer",
                "effect": "hotspot_memory_carrion_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_hotspot_memory >= 0.34 and hyena_hotspots >= 2 and scores.get("scavenger_pressure", 0.0) >= 0.42:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "hyena",
                "layer_group": "scavenge_layer",
                "effect": "hotspot_memory_carrion_support",
                "new_target_count": species_pool["hyena"],
            }
        )
    if shared_hotspot_memory >= 0.34 and vulture_count < 10:
        species_pool["vulture"] = species_pool.get("vulture", 0) + 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "vulture",
                "layer_group": "aerial_scavenge_layer",
                "effect": "shared_hotspot_tracking",
                "new_target_count": species_pool["vulture"],
            }
        )
    if lion_hotspot_memory + hyena_hotspot_memory >= 0.78 and vulture_count < 10 and antelope_count + zebra_count >= 18:
        species_pool["vulture"] = species_pool.get("vulture", 0) + 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "vulture",
                "layer_group": "aerial_scavenge_layer",
                "effect": "hotspot_cycle_scavenger_wave",
                "new_target_count": species_pool["vulture"],
            }
        )
    if grassland_boom_phase >= 0.45 and vulture_count < 11 and antelope_count + zebra_count >= 16:
        species_pool["vulture"] = species_pool.get("vulture", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "vulture",
                "layer_group": "aerial_scavenge_layer",
                "effect": "boom_phase_scavenger_release",
                "new_target_count": species_pool["vulture"],
            }
        )
    if shared_hotspot_memory >= 0.42 and lion_count >= 3 and hyena_count >= 3:
        if species_pool.get("hyena", 0) >= species_pool.get("lion", 0):
            species_pool["hyena"] = species_pool["hyena"] - 1
            adjustments.append(
                {
                    "source_species": "social_hotspot",
                    "target_species": "hyena",
                    "layer_group": "scavenge_layer",
                    "effect": "hotspot_cycle_churn",
                    "new_target_count": species_pool["hyena"],
                }
            )
        else:
            species_pool["lion"] = species_pool["lion"] - 1
            adjustments.append(
                {
                    "source_species": "social_hotspot",
                    "target_species": "lion",
                    "layer_group": "kill_layer",
                    "effect": "hotspot_cycle_churn",
                    "new_target_count": species_pool["lion"],
                }
            )
    if grassland_bust_phase >= 0.56 and vulture_count >= 4:
        species_pool["vulture"] = species_pool.get("vulture", 0) - 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "vulture",
                "layer_group": "aerial_scavenge_layer",
                "effect": "bust_phase_scavenger_drag",
                "new_target_count": species_pool["vulture"],
            }
        )

    return adjustments


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

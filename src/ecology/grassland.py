"""v4 草原大型植食者链摘要与反馈。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List

from src.data import WorldRegistry
from src.world import Region


@dataclass
class RegionGrasslandChainSummary:
    """草原大型植食者链摘要。"""

    region_id: str
    key_species: List[str] = field(default_factory=list)
    trophic_scores: Dict[str, float] = field(default_factory=dict)
    layer_scores: Dict[str, float] = field(default_factory=dict)
    layer_species: Dict[str, List[str]] = field(default_factory=dict)
    narrative_chain: List[str] = field(default_factory=list)


def build_region_grassland_chain_summary(region: Region, registry: WorldRegistry) -> RegionGrasslandChainSummary:
    """构建草原大型植食者链摘要。非草原区返回空摘要。"""

    if not _is_grassland_region(region):
        return RegionGrasslandChainSummary(region_id=region.region_id)

    region_species = set(region.species_pool)
    key_species = [
        species
        for species in ["african_elephant", "white_rhino", "giraffe", "lion", "hyena"]
        if species in region_species
    ]

    trophic_scores: Dict[str, float] = {}
    layer_scores: Dict[str, float] = {}
    layer_species: Dict[str, List[str]] = {
        "grazing_layer": [],
        "browse_layer": [],
        "engineering_layer": [],
        "predator_layer": [],
        "scavenger_layer": [],
    }
    narrative_chain: List[str] = []

    def add_score(key: str, value: float, narrative: str) -> None:
        trophic_scores[key] = round(trophic_scores.get(key, 0.0) + value, 2)
        if narrative not in narrative_chain:
            narrative_chain.append(narrative)

    def add_layer(layer: str, species: str, value: float) -> None:
        layer_scores[layer] = round(layer_scores.get(layer, 0.0) + value, 2)
        if species not in layer_species[layer]:
            layer_species[layer].append(species)

    if "african_elephant" in region_species:
        add_score("canopy_opening", 0.82, "大象通过开林和踩踏重塑草灌边界。")
        add_score("seed_dispersal", 0.54, "大象扩大大型种子的景观级扩散。")
        add_layer("engineering_layer", "african_elephant", 0.82)

    if "white_rhino" in region_species:
        add_score("grazing_pressure", 0.76, "白犀维持低矮草场并压制灌丛回侵。")
        add_score("mud_wallow_disturbance", 0.42, "白犀围绕泥浴点形成局部踩踏和资源聚集。")
        add_layer("grazing_layer", "white_rhino", 0.76)

    if "giraffe" in region_species:
        add_score("canopy_browsing", 0.72, "长颈鹿利用高树冠叶源形成垂直取食分层。")
        add_layer("browse_layer", "giraffe", 0.72)

    if {"african_elephant", "white_rhino"} <= region_species:
        add_score("waterhole_competition_bridge", 0.48, "大型植食者会围绕水源和泥浴位点形成持续竞争。")
    if {"african_elephant", "giraffe"} <= region_species:
        add_score("vertical_partitioning", 0.51, "大象与长颈鹿共同塑造草地到树冠的垂直资源分层。")
    if {"african_elephant", "white_rhino", "giraffe"} <= region_species:
        add_score("megaherbivore_stack", 0.74, "大象、白犀和长颈鹿共同形成草原大型植食者结构骨架。")
    if "lion" in region_species:
        add_score("apex_predation", 0.71, "狮群围绕草食动物通道与水源形成顶层捕食压力。")
        add_layer("predator_layer", "lion", 0.71)
    if "hyena" in region_species:
        add_score("carrion_scavenging", 0.66, "鬣狗把尸体资源和机会型捕食重新接回草原营养循环。")
        add_layer("scavenger_layer", "hyena", 0.66)
    if {"lion", "hyena"} <= region_species:
        add_score("carcass_competition", 0.57, "狮与鬣狗围绕猎物残体和水源形成持续竞争。")
    if {"lion", "hyena", "african_elephant", "white_rhino", "giraffe"} <= region_species:
        add_score("grassland_predator_closure", 0.63, "顶层捕食者与大型植食者共同闭合草原主食物链。")

    return RegionGrasslandChainSummary(
        region_id=region.region_id,
        key_species=key_species,
        trophic_scores=dict(sorted(trophic_scores.items())),
        layer_scores=dict(sorted(layer_scores.items())),
        layer_species={layer: sorted(species) for layer, species in layer_species.items() if species},
        narrative_chain=narrative_chain,
    )


def apply_region_grassland_chain_feedback(
    region: Region,
    grassland_chain: RegionGrasslandChainSummary,
    feedback_scale: float = 0.02,
) -> None:
    """将草原大型植食者链摘要轻量回灌到区域状态。"""

    scores = grassland_chain.trophic_scores

    _adjust(region.resource_state, "grazing_biomass", scores.get("grazing_pressure", 0.0) * 0.35, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -scores.get("canopy_browsing", 0.0) * 0.34, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -scores.get("canopy_opening", 0.0) * 0.25, feedback_scale)
    _adjust(region.resource_state, "canopy_cover", -scores.get("canopy_opening", 0.0) * 0.38, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("waterhole_competition_bridge", 0.0) * 0.12, feedback_scale)
    _adjust(region.resource_state, "dung_cycle", scores.get("carrion_scavenging", 0.0) * 0.16, feedback_scale)

    _adjust(region.hazard_state, "predation_pressure", scores.get("canopy_opening", 0.0) * 0.16, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("apex_predation", 0.0) * 0.28, feedback_scale)
    _adjust(region.hazard_state, "drought_risk", scores.get("grazing_pressure", 0.0) * 0.08, feedback_scale)

    _adjust(region.health_state, "biodiversity", scores.get("megaherbivore_stack", 0.0) * 0.22, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("vertical_partitioning", 0.0) * 0.18, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("grassland_predator_closure", 0.0) * 0.16, feedback_scale)
    _adjust(region.health_state, "fragmentation", -scores.get("canopy_opening", 0.0) * 0.08, feedback_scale)


def _is_grassland_region(region: Region) -> bool:
    if region.region_id == "temperate_grassland":
        return True
    return any(biome in {"grassland", "savanna", "shrubland", "seasonal_waterhole"} for biome in region.dominant_biomes)


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

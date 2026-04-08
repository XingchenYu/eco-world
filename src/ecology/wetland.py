"""v4 湿地核心食物链摘要与反馈。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List

from src.data import WorldRegistry
from src.world import Region


@dataclass
class RegionWetlandChainSummary:
    """湿地与湖泊区的核心链摘要。"""

    region_id: str
    key_species: List[str] = field(default_factory=list)
    trophic_scores: Dict[str, float] = field(default_factory=dict)
    layer_scores: Dict[str, float] = field(default_factory=dict)
    layer_species: Dict[str, List[str]] = field(default_factory=dict)
    narrative_chain: List[str] = field(default_factory=list)


def build_region_wetland_chain_summary(region: Region, registry: WorldRegistry) -> RegionWetlandChainSummary:
    """构建湿地核心链条摘要。非湿地区返回空摘要。"""

    if not _is_wetland_region(region):
        return RegionWetlandChainSummary(region_id=region.region_id)

    region_species = set(region.species_pool)
    key_species = [
        species
        for species in [
            "beaver",
            "hippopotamus",
            "nile_crocodile",
            "kingfisher_v4",
            "frog",
            "minnow",
            "catfish",
            "blackfish",
        ]
        if species in region_species
    ]

    trophic_scores: Dict[str, float] = {}
    layer_scores: Dict[str, float] = {}
    layer_species: Dict[str, List[str]] = {
        "shoreline_layer": [],
        "fish_layer": [],
        "apex_layer": [],
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

    if "beaver" in region_species:
        add_score("wetland_engineering", 0.82, "河狸提升缓流水域、芦苇带和岸带复杂度。")
        add_layer("shoreline_layer", "beaver", 0.82)
    if "hippopotamus" in region_species:
        add_score("nutrient_exchange", 0.78, "河马把陆地营养搬回水体，推高湿地生产力。")
        add_layer("apex_layer", "hippopotamus", 0.78)
    if "frog" in region_species:
        add_score("amphibian_bridge", 0.72, "青蛙把岸带羽化资源与陆地捕食链连接起来。")
        add_layer("shoreline_layer", "frog", 0.72)
    if "minnow" in region_species:
        add_score("nursery_fish_layer", 0.76, "米诺鱼构成湿地浅水带最敏感的小型鱼层。")
        add_layer("fish_layer", "minnow", 0.76)
    if "catfish" in region_species:
        add_score("benthic_predation", 0.58, "鲶鱼对浅水和底栖小型猎物形成持续压力。")
        add_layer("fish_layer", "catfish", 0.58)
    if "blackfish" in region_species:
        add_score("midwater_predation", 0.66, "黑鱼对中上层浅水猎物形成更强的机会型捕食压力。")
        add_layer("fish_layer", "blackfish", 0.66)
    if "kingfisher_v4" in region_species:
        add_score("shoreline_bird_foraging", 0.63, "翠鸟把岸栖位、浅滩和小型鱼虾资源连接成岸带食物链。")
        add_layer("shoreline_layer", "kingfisher_v4", 0.63)
    if "nile_crocodile" in region_species:
        add_score("apex_shoreline_risk", 0.84, "鳄鱼把岸线捕食风险推到顶层，并改变所有靠岸取食行为。")
        add_layer("apex_layer", "nile_crocodile", 0.84)

    if {"frog", "minnow", "kingfisher_v4"} <= region_species:
        add_score("shoreline_trophic_coupling", 0.54, "羽化带、浅滩鱼群和岸栖鸟类形成稳定的湿地边缘耦合链。")
    if {"minnow", "catfish", "blackfish"} <= region_species:
        add_score("layered_fish_pressure", 0.61, "米诺鱼、鲶鱼和黑鱼构成分层鱼类压力结构。")
    if {"beaver", "hippopotamus", "nile_crocodile"} <= region_species:
        add_score("wetland_keystone_stack", 0.74, "河狸、河马与鳄鱼共同塑造湿地工程、营养与风险三角。")

    return RegionWetlandChainSummary(
        region_id=region.region_id,
        key_species=key_species,
        trophic_scores=dict(sorted(trophic_scores.items())),
        layer_scores=dict(sorted(layer_scores.items())),
        layer_species={layer: sorted(species) for layer, species in layer_species.items() if species},
        narrative_chain=narrative_chain,
    )


def apply_region_wetland_chain_feedback(
    region: Region,
    wetland_chain: RegionWetlandChainSummary,
    feedback_scale: float = 0.02,
) -> None:
    """将湿地链摘要轻量回灌到区域状态。"""

    scores = wetland_chain.trophic_scores

    _adjust(region.resource_state, "reed_cover", scores.get("wetland_engineering", 0.0) * 0.42, feedback_scale)
    _adjust(region.resource_state, "open_water", scores.get("wetland_engineering", 0.0) * 0.28, feedback_scale)
    _adjust(region.resource_state, "shore_hatch", scores.get("shoreline_trophic_coupling", 0.0) * 0.4, feedback_scale)
    _adjust(region.resource_state, "fish_cover", scores.get("nursery_fish_layer", 0.0) * 0.36, feedback_scale)
    _adjust(region.resource_state, "nutrient_load", scores.get("nutrient_exchange", 0.0) * 0.48, feedback_scale)

    _adjust(region.hazard_state, "shoreline_risk", scores.get("apex_shoreline_risk", 0.0) * 0.45, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("layered_fish_pressure", 0.0) * 0.25, feedback_scale)

    _adjust(region.health_state, "biodiversity", scores.get("wetland_keystone_stack", 0.0) * 0.3, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("amphibian_bridge", 0.0) * 0.22, feedback_scale)
    _adjust(region.health_state, "connectivity", scores.get("shoreline_trophic_coupling", 0.0) * 0.2, feedback_scale)


def apply_region_wetland_chain_rebalancing(region: Region, wetland_chain: RegionWetlandChainSummary) -> List[dict]:
    """根据湿地链结构对物种池做低频、轻量重平衡。"""

    if not wetland_chain.trophic_scores:
        return []

    adjustments: List[dict] = []
    species_pool = region.species_pool
    scores = wetland_chain.trophic_scores

    minnow_count = species_pool.get("minnow", 0)
    catfish_count = species_pool.get("catfish", 0)
    blackfish_count = species_pool.get("blackfish", 0)
    kingfisher_count = species_pool.get("kingfisher_v4", 0)
    frog_count = species_pool.get("frog", 0)
    crocodile_count = species_pool.get("nile_crocodile", 0)

    layered_pressure = scores.get("layered_fish_pressure", 0.0)
    shoreline_coupling = scores.get("shoreline_trophic_coupling", 0.0)
    shoreline_risk = scores.get("apex_shoreline_risk", 0.0)

    if minnow_count > 0 and layered_pressure >= 0.6 and minnow_count > max(10, catfish_count + blackfish_count):
        species_pool["minnow"] = max(8, minnow_count - 2)
        adjustments.append(
            {
                "source_species": "wetland_chain",
                "target_species": "minnow",
                "layer_group": "fish_layer",
                "effect": "nursery_trim",
                "new_target_count": species_pool["minnow"],
            }
        )

    if shoreline_coupling >= 0.5 and kingfisher_count > 0 and frog_count > 0:
        if minnow_count < 16:
            species_pool["minnow"] = minnow_count + 1
            adjustments.append(
                {
                    "source_species": "wetland_chain",
                    "target_species": "minnow",
                    "layer_group": "shoreline_layer",
                    "effect": "shoreline_support",
                    "new_target_count": species_pool["minnow"],
                }
            )
        if frog_count < 30:
            species_pool["frog"] = frog_count + 1
            adjustments.append(
                {
                    "source_species": "wetland_chain",
                    "target_species": "frog",
                    "layer_group": "shoreline_layer",
                    "effect": "amphibian_support",
                    "new_target_count": species_pool["frog"],
                }
            )

    if shoreline_risk >= 0.8 and crocodile_count >= 2:
        if kingfisher_count > 2:
            species_pool["kingfisher_v4"] = kingfisher_count - 1
            adjustments.append(
                {
                    "source_species": "nile_crocodile",
                    "target_species": "kingfisher_v4",
                    "layer_group": "apex_layer",
                    "effect": "shoreline_suppression",
                    "new_target_count": species_pool["kingfisher_v4"],
                }
            )
        if frog_count > 8:
            species_pool["frog"] = frog_count - 1
            adjustments.append(
                {
                    "source_species": "nile_crocodile",
                    "target_species": "frog",
                    "layer_group": "apex_layer",
                    "effect": "shoreline_suppression",
                    "new_target_count": species_pool["frog"],
                }
            )

    return adjustments


def _is_wetland_region(region: Region) -> bool:
    if region.region_id == "wetland_lake":
        return True
    return any(biome in {"wetland", "lake_shore", "reed_belt", "major_river", "floodplain"} for biome in region.dominant_biomes)


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

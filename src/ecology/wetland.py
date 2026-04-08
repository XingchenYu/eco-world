"""v4 湿地核心食物链摘要。"""

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
    narrative_chain: List[str] = []

    def add_score(key: str, value: float, narrative: str) -> None:
        trophic_scores[key] = round(trophic_scores.get(key, 0.0) + value, 2)
        if narrative not in narrative_chain:
            narrative_chain.append(narrative)

    if "beaver" in region_species:
        add_score("wetland_engineering", 0.82, "河狸提升缓流水域、芦苇带和岸带复杂度。")
    if "hippopotamus" in region_species:
        add_score("nutrient_exchange", 0.78, "河马把陆地营养搬回水体，推高湿地生产力。")
    if "frog" in region_species:
        add_score("amphibian_bridge", 0.72, "青蛙把岸带羽化资源与陆地捕食链连接起来。")
    if "minnow" in region_species:
        add_score("nursery_fish_layer", 0.76, "米诺鱼构成湿地浅水带最敏感的小型鱼层。")
    if "catfish" in region_species:
        add_score("benthic_predation", 0.58, "鲶鱼对浅水和底栖小型猎物形成持续压力。")
    if "blackfish" in region_species:
        add_score("midwater_predation", 0.66, "黑鱼对中上层浅水猎物形成更强的机会型捕食压力。")
    if "kingfisher_v4" in region_species:
        add_score("shoreline_bird_foraging", 0.63, "翠鸟把岸栖位、浅滩和小型鱼虾资源连接成岸带食物链。")
    if "nile_crocodile" in region_species:
        add_score("apex_shoreline_risk", 0.84, "鳄鱼把岸线捕食风险推到顶层，并改变所有靠岸取食行为。")

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
        narrative_chain=narrative_chain,
    )


def _is_wetland_region(region: Region) -> bool:
    if region.region_id == "wetland_lake":
        return True
    return any(biome in {"wetland", "lake_shore", "reed_belt", "major_river", "floodplain"} for biome in region.dominant_biomes)

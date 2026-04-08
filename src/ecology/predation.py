"""v4 区域级捕食压力摘要与反馈。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List

from src.data import WorldRegistry
from src.data.models import RelationTable
from src.world import Region


@dataclass
class RegionPredationSummary:
    """区域级捕食摘要。"""

    region_id: str
    active_relations: List[RelationTable] = field(default_factory=list)
    pressure_scores: Dict[str, float] = field(default_factory=dict)
    vulnerable_resources: List[str] = field(default_factory=list)
    narrative_predation: List[str] = field(default_factory=list)


def build_region_predation_summary(region: Region, registry: WorldRegistry) -> RegionPredationSummary:
    """根据区域物种池和注册表构建捕食压力摘要。"""

    region_species = set(region.species_pool)
    active_relations = [
        relation
        for relation in registry.relations
        if relation.relation_type == "predation"
        and relation.source_species in region_species
        and _relation_target_is_relevant(relation, region, region_species)
    ]

    pressure_scores: Dict[str, float] = {}
    vulnerable_resources: List[str] = []
    narrative_predation: List[str] = []

    def add_pressure(key: str, value: float, resource: str, narrative: str) -> None:
        pressure_scores[key] = round(pressure_scores.get(key, 0.0) + value, 2)
        if resource not in vulnerable_resources:
            vulnerable_resources.append(resource)
        if narrative not in narrative_predation:
            narrative_predation.append(narrative)

    for relation in active_relations:
        if relation.source_species == "kingfisher_v4" and relation.target_species == "minnow":
            add_pressure(
                "shoreline_bird_predation",
                relation.strength,
                "shore_hatch",
                "翠鸟沿岸线压制浅滩小型鱼群，并强化岸带取食窗口。",
            )
        elif relation.source_species == "catfish" and relation.target_species == "minnow":
            add_pressure(
                "benthic_fish_predation",
                relation.strength,
                "fish_cover",
                "鲶鱼在底层和浑浊水带持续消耗米诺鱼群。",
            )
        elif relation.source_species == "blackfish" and relation.target_species == "minnow":
            add_pressure(
                "midwater_fish_predation",
                relation.strength,
                "fish_cover",
                "黑鱼在浅水中上层对米诺鱼形成更强的机会型捕食压力。",
            )
        elif relation.source_species == "blackfish" and relation.target_species == "frog":
            add_pressure(
                "amphibian_predation",
                relation.strength,
                "amphibian_bridge",
                "黑鱼会在岸边与浅滩机会性捕食成体蛙。",
            )
        elif relation.source_species == "bat_v4" and relation.target_species == "night_moth":
            add_pressure(
                "nocturnal_insect_predation",
                relation.strength,
                "night_insects",
                "蝙蝠把夜飞昆虫脉冲转化成夜行捕食压力。",
            )
        elif relation.source_species == "lion" and relation.target_species == "rabbit":
            add_pressure(
                "grassland_apex_predation",
                relation.strength,
                "small_prey",
                "狮群围绕草原小型猎物和通道形成顶层捕食压力。",
            )
        elif relation.source_species == "hyena" and relation.target_species == "rabbit":
            add_pressure(
                "grassland_scavenger_predation",
                relation.strength,
                "small_prey",
                "鬣狗群会把机会型捕食与腐食压力同时施加到草原小型猎物层。",
            )
        elif relation.source_species == "lion" and relation.target_species == "antelope":
            add_pressure(
                "grassland_herd_predation",
                relation.strength,
                "herd_prey",
                "狮群对羚羊群形成草原主猎物层的顶层捕食压力。",
            )
        elif relation.source_species == "lion" and relation.target_species == "zebra":
            add_pressure(
                "grassland_large_herd_predation",
                relation.strength,
                "herd_prey",
                "狮群沿迁移通道和水源对斑马群形成高位捕食压力。",
            )
        elif relation.source_species == "hyena" and relation.target_species == "antelope":
            add_pressure(
                "grassland_scavenger_herd_predation",
                relation.strength,
                "herd_prey",
                "鬣狗群对羚羊幼体和受伤个体施加机会型顶层压力。",
            )

    return RegionPredationSummary(
        region_id=region.region_id,
        active_relations=active_relations,
        pressure_scores=dict(sorted(pressure_scores.items())),
        vulnerable_resources=sorted(vulnerable_resources),
        narrative_predation=narrative_predation,
    )


def apply_region_predation_feedback(region: Region, predation: RegionPredationSummary, feedback_scale: float = 0.02) -> None:
    """将区域捕食压力轻量回灌到区域状态。"""

    pressures = predation.pressure_scores

    _adjust(region.resource_state, "shore_hatch", -pressures.get("shoreline_bird_predation", 0.0) * 0.18, feedback_scale)
    _adjust(region.resource_state, "fish_cover", -pressures.get("benthic_fish_predation", 0.0) * 0.22, feedback_scale)
    _adjust(region.resource_state, "fish_cover", -pressures.get("midwater_fish_predation", 0.0) * 0.26, feedback_scale)
    _adjust(region.resource_state, "night_insects", -pressures.get("nocturnal_insect_predation", 0.0) * 0.18, feedback_scale)
    _adjust(region.resource_state, "grazing_biomass", -pressures.get("grassland_apex_predation", 0.0) * 0.05, feedback_scale)
    _adjust(region.resource_state, "grazing_biomass", -pressures.get("grassland_herd_predation", 0.0) * 0.08, feedback_scale)
    _adjust(region.resource_state, "surface_water", pressures.get("grassland_large_herd_predation", 0.0) * 0.05, feedback_scale)
    _adjust(region.resource_state, "dung_cycle", pressures.get("grassland_scavenger_predation", 0.0) * 0.08, feedback_scale)

    _adjust(region.hazard_state, "predation_pressure", sum(pressures.values()) * 0.2, feedback_scale)
    _adjust(region.hazard_state, "shoreline_risk", pressures.get("shoreline_bird_predation", 0.0) * 0.08, feedback_scale)
    _adjust(region.hazard_state, "shoreline_risk", pressures.get("amphibian_predation", 0.0) * 0.12, feedback_scale)

    _adjust(region.health_state, "biodiversity", -sum(pressures.values()) * 0.05, feedback_scale)
    _adjust(region.health_state, "resilience", -pressures.get("amphibian_predation", 0.0) * 0.04, feedback_scale)


def _relation_target_is_relevant(relation: RelationTable, region: Region, resident_ids: set[str]) -> bool:
    if relation.target_species in resident_ids:
        return True
    if relation.target_species in region.species_pool:
        return True

    habitat_types = {habitat.habitat_type for patch in region.biome_patches for habitat in patch.habitats}
    return relation.target_species in habitat_types


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

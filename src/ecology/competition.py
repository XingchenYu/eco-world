"""v4 区域级竞争关系摘要与反馈。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List

from src.data import WorldRegistry
from src.data.models import RelationTable
from src.world import Region


@dataclass
class RegionCompetitionSummary:
    """区域级竞争摘要。"""

    region_id: str
    active_relations: List[RelationTable] = field(default_factory=list)
    pressure_scores: Dict[str, float] = field(default_factory=dict)
    contested_resources: List[str] = field(default_factory=list)
    narrative_competition: List[str] = field(default_factory=list)


def build_region_competition_summary(region: Region, registry: WorldRegistry) -> RegionCompetitionSummary:
    """根据区域物种池和注册表构建竞争摘要。"""

    region_species = set(region.species_pool)
    active_relations = [
        relation
        for relation in registry.relations
        if relation.relation_type == "competition"
        and relation.source_species in region_species
        and relation.target_species in region_species
    ]

    pressure_scores: Dict[str, float] = {}
    contested_resources: List[str] = []
    narrative_competition: List[str] = []

    def add_pressure(key: str, value: float, resource: str, narrative: str) -> None:
        pressure_scores[key] = round(pressure_scores.get(key, 0.0) + value, 2)
        if resource not in contested_resources:
            contested_resources.append(resource)
        if narrative not in narrative_competition:
            narrative_competition.append(narrative)

    for relation in active_relations:
        if relation.source_species == "nile_crocodile" and relation.target_species == "hippopotamus":
            add_pressure(
                "shoreline_space_competition",
                relation.strength,
                "shoreline_space",
                "鳄鱼与河马围绕岸带浅滩和稳定伏击位发生竞争。",
            )
        elif relation.source_species == "hippopotamus" and relation.target_species == "nile_crocodile":
            add_pressure(
                "wallow_site_competition",
                relation.strength,
                "wallow_site",
                "河马通过踩踏和高密度占位压缩鳄鱼的稳定水边位点。",
            )
        elif relation.source_species == "african_elephant" and relation.target_species == "white_rhino":
            add_pressure(
                "waterhole_competition",
                relation.strength,
                "waterhole",
                "大象与白犀围绕水源、泥浴点与草灌边界发生竞争。",
            )
        elif relation.source_species == "white_rhino" and relation.target_species == "african_elephant":
            add_pressure(
                "grazer_competition",
                relation.strength,
                "grazing_patch",
                "白犀通过持续放牧和泥浴点占用，对大象形成反向草场压力。",
            )
        elif relation.source_species == "african_elephant" and relation.target_species == "giraffe":
            add_pressure(
                "browse_layer_competition",
                relation.strength,
                "browse_layer",
                "大象开林与折枝会压缩部分高位树冠资源，对长颈鹿形成竞争。",
            )

    return RegionCompetitionSummary(
        region_id=region.region_id,
        active_relations=active_relations,
        pressure_scores=dict(sorted(pressure_scores.items())),
        contested_resources=sorted(contested_resources),
        narrative_competition=narrative_competition,
    )


def apply_region_competition_feedback(region: Region, registry: WorldRegistry) -> List[dict]:
    """根据关键竞争关系轻量调整区域物种池和资源压力。"""

    adjustments: List[dict] = []
    region_species = set(region.species_pool)

    for relation in registry.relations:
        if relation.relation_type != "competition":
            continue
        if relation.source_species not in region_species or relation.target_species not in region_species:
            continue
        _apply_competition_relation(region, relation, adjustments)

    return adjustments


def _apply_competition_relation(region: Region, relation: RelationTable, adjustments: List[dict]) -> None:
    source_count = region.species_pool.get(relation.source_species, 0)
    target_count = region.species_pool.get(relation.target_species, 0)
    if source_count <= 0 or target_count <= 0:
        return

    should_reduce_target = False
    if relation.target_species == "white_rhino" and source_count >= 2 and target_count >= 2 and relation.strength >= 0.35:
        should_reduce_target = True
        _adjust(region.resource_state, "browse_cover", -0.08, 0.05)
        _adjust(region.hazard_state, "predation_pressure", 0.04, 0.05)
    elif relation.target_species == "nile_crocodile" and source_count >= 2 and target_count >= 2 and relation.strength >= 0.4:
        should_reduce_target = True
        _adjust(region.resource_state, "shore_hatch", 0.06, 0.05)
        _adjust(region.hazard_state, "shoreline_risk", -0.08, 0.05)
    elif relation.target_species == "giraffe" and source_count >= 2 and target_count >= 3 and relation.strength >= 0.2:
        should_reduce_target = True
        _adjust(region.resource_state, "canopy_cover", -0.06, 0.04)
    elif relation.target_species == "african_elephant" and source_count >= 2 and target_count >= 2 and relation.strength >= 0.2:
        should_reduce_target = True
        _adjust(region.resource_state, "grazing_biomass", -0.05, 0.04)
    elif relation.target_species == "hippopotamus" and source_count >= 2 and target_count >= 2 and relation.strength >= 0.3:
        should_reduce_target = True
        _adjust(region.hazard_state, "shoreline_risk", 0.05, 0.04)

    if not should_reduce_target:
        return

    new_target_count = max(1, target_count - 1)
    if new_target_count == target_count:
        return

    region.species_pool[relation.target_species] = new_target_count
    adjustments.append(
        {
            "source_species": relation.source_species,
            "target_species": relation.target_species,
            "effect": "pressure_reduction",
            "new_target_count": new_target_count,
        }
    )


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

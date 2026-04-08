"""v4 区域级共生与偏利关系摘要。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List

from src.data import WorldRegistry
from src.data.models import RelationTable
from src.world import Region


@dataclass
class RegionSymbiosisSummary:
    """区域级共生/偏利关系摘要。"""

    region_id: str
    active_relations: List[RelationTable] = field(default_factory=list)
    support_scores: Dict[str, float] = field(default_factory=dict)
    supported_resources: List[str] = field(default_factory=list)
    narrative_symbiosis: List[str] = field(default_factory=list)


def build_region_symbiosis_summary(region: Region, registry: WorldRegistry) -> RegionSymbiosisSummary:
    """根据区域物种池和注册表构建共生摘要。"""

    region_species = set(region.species_pool)
    active_relations = [
        relation
        for relation in registry.relations
        if relation.relation_type == "symbiosis"
        and relation.source_species in region_species
        and _relation_target_is_relevant(relation, region, region_species)
    ]

    support_scores: Dict[str, float] = {}
    supported_resources: List[str] = []
    narrative_symbiosis: List[str] = []

    def add_support(key: str, value: float, resource: str, narrative: str) -> None:
        support_scores[key] = round(support_scores.get(key, 0.0) + value, 2)
        if resource not in supported_resources:
            supported_resources.append(resource)
        if narrative not in narrative_symbiosis:
            narrative_symbiosis.append(narrative)

    for relation in active_relations:
        if relation.source_species == "kingfisher_v4":
            add_support(
                "riparian_foraging_support",
                relation.strength,
                "shore_hatch",
                "翠鸟依赖岸边停栖位和浅滩鱼虾带形成高效捕食窗口。",
            )
        elif relation.source_species == "bat_v4":
            add_support(
                "nocturnal_insect_support",
                relation.strength,
                "night_swarm",
                "蝙蝠依赖夜间飞虫云团与稳定夜栖位维持夜行食虫链。",
            )
        elif relation.source_species == "beaver":
            add_support(
                "wetland_engineering_support",
                relation.strength,
                "reed_belt",
                "河狸创造的湿地与芦苇带提升了幼体庇护和岸带生境复杂度。",
            )

    return RegionSymbiosisSummary(
        region_id=region.region_id,
        active_relations=active_relations,
        support_scores=dict(sorted(support_scores.items())),
        supported_resources=sorted(supported_resources),
        narrative_symbiosis=narrative_symbiosis,
    )


def apply_region_symbiosis_feedback(region: Region, symbiosis: RegionSymbiosisSummary, feedback_scale: float = 0.02) -> None:
    """将区域共生摘要轻量回灌到区域状态。"""

    supports = symbiosis.support_scores

    _adjust(region.resource_state, "shore_hatch", supports.get("riparian_foraging_support", 0.0) * 0.45, feedback_scale)
    _adjust(region.resource_state, "night_insects", supports.get("nocturnal_insect_support", 0.0) * 0.55, feedback_scale)
    _adjust(region.resource_state, "reed_cover", supports.get("wetland_engineering_support", 0.0) * 0.38, feedback_scale)
    _adjust(region.resource_state, "nesting_cover", supports.get("wetland_engineering_support", 0.0) * 0.28, feedback_scale)

    _adjust(region.health_state, "biodiversity", supports.get("wetland_engineering_support", 0.0) * 0.24, feedback_scale)
    _adjust(region.health_state, "resilience", supports.get("nocturnal_insect_support", 0.0) * 0.18, feedback_scale)
    _adjust(region.health_state, "resilience", supports.get("riparian_foraging_support", 0.0) * 0.16, feedback_scale)


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

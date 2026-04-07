"""v4 区域食物网与关系摘要。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Set

from src.data import WorldRegistry
from src.data.models import RelationTable, SpeciesVariant
from src.world import Region


@dataclass
class RegionFoodWeb:
    """区域食物网摘要。"""

    region_id: str
    resident_species: Dict[str, SpeciesVariant] = field(default_factory=dict)
    active_relations: List[RelationTable] = field(default_factory=list)
    relation_summary: Dict[str, int] = field(default_factory=dict)
    role_summary: Dict[str, int] = field(default_factory=dict)
    keystone_species: List[str] = field(default_factory=list)
    engineer_species: List[str] = field(default_factory=list)
    flagship_species: List[str] = field(default_factory=list)


def build_region_food_web(region: Region, registry: WorldRegistry) -> RegionFoodWeb:
    """根据区域物种池和注册表构建区域食物网。"""

    resident_species = _resolve_resident_species(region, registry)
    resident_ids = set(resident_species)
    active_relations = [
        relation
        for relation in registry.relations
        if relation.source_species in resident_ids and _relation_target_is_relevant(relation, region, resident_ids)
    ]

    relation_summary: Dict[str, int] = {}
    for relation in active_relations:
        relation_summary[relation.relation_type] = relation_summary.get(relation.relation_type, 0) + 1

    role_summary: Dict[str, int] = {}
    keystone_species: List[str] = []
    engineer_species: List[str] = []
    flagship_species: List[str] = []

    for species_id, variant in resident_species.items():
        template = registry.get_template(variant.template_id)
        role_summary[template.role] = role_summary.get(template.role, 0) + 1
        if variant.flags.keystone:
            keystone_species.append(species_id)
        if variant.flags.engineer:
            engineer_species.append(species_id)
        if variant.flags.flagship:
            flagship_species.append(species_id)

    return RegionFoodWeb(
        region_id=region.region_id,
        resident_species=resident_species,
        active_relations=active_relations,
        relation_summary=relation_summary,
        role_summary=role_summary,
        keystone_species=sorted(keystone_species),
        engineer_species=sorted(engineer_species),
        flagship_species=sorted(flagship_species),
    )


def _resolve_resident_species(region: Region, registry: WorldRegistry) -> Dict[str, SpeciesVariant]:
    candidates = registry.species_for_region(region.region_id)
    if not region.species_pool:
        return candidates
    return {species_id: variant for species_id, variant in candidates.items() if species_id in region.species_pool}


def _relation_target_is_relevant(relation: RelationTable, region: Region, resident_ids: Set[str]) -> bool:
    if relation.target_species in resident_ids:
        return True
    if relation.target_species in region.species_pool:
        return True

    habitat_types = {
        habitat.habitat_type
        for patch in region.biome_patches
        for habitat in patch.habitats
    }
    if relation.target_species in habitat_types:
        return True

    biome_types = {patch.biome_type for patch in region.biome_patches}
    return relation.target_species in biome_types

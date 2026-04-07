"""v4 世界数据注册表。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, Iterable, List

from .defaults import (
    build_default_relation_tables,
    build_default_species_templates,
    build_default_species_variants,
)
from .models import RelationTable, SpeciesTemplate, SpeciesVariant


@dataclass
class WorldRegistry:
    """统一收纳模板、物种和关系表。"""

    templates: Dict[str, SpeciesTemplate] = field(default_factory=dict)
    species: Dict[str, SpeciesVariant] = field(default_factory=dict)
    relations: List[RelationTable] = field(default_factory=list)

    def get_template(self, template_id: str) -> SpeciesTemplate:
        return self.templates[template_id]

    def get_species(self, species_id: str) -> SpeciesVariant:
        return self.species[species_id]

    def species_for_region(self, region_id: str) -> Dict[str, SpeciesVariant]:
        return {
            species_id: variant
            for species_id, variant in self.species.items()
            if region_id in variant.native_regions
        }

    def relations_for_species(self, species_id: str) -> List[RelationTable]:
        return [
            relation
            for relation in self.relations
            if relation.source_species == species_id or relation.target_species == species_id
        ]

    def relation_summary(self) -> Dict[str, int]:
        counts: Dict[str, int] = {}
        for relation in self.relations:
            counts[relation.relation_type] = counts.get(relation.relation_type, 0) + 1
        return counts


def build_default_world_registry() -> WorldRegistry:
    """创建默认 v4 世界注册表。"""

    return WorldRegistry(
        templates=build_default_species_templates(),
        species=build_default_species_variants(),
        relations=build_default_relation_tables(),
    )

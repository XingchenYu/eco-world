"""v4 数据模型模块。"""

from .defaults import (
    build_default_relation_tables,
    build_default_species_templates,
    build_default_species_variants,
)
from .models import (
    BehaviorProfile,
    DietProfile,
    EcologicalFlags,
    HabitatProfile,
    LifeStageProfile,
    RelationTable,
    SocialProfile,
    SpeciesTemplate,
    SpeciesVariant,
    TerritoryProfile,
)
from .registry import WorldRegistry, build_default_world_registry

__all__ = [
    "BehaviorProfile",
    "build_default_relation_tables",
    "build_default_species_templates",
    "build_default_species_variants",
    "build_default_world_registry",
    "DietProfile",
    "EcologicalFlags",
    "HabitatProfile",
    "LifeStageProfile",
    "RelationTable",
    "SocialProfile",
    "SpeciesTemplate",
    "SpeciesVariant",
    "TerritoryProfile",
    "WorldRegistry",
]

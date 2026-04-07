"""v4 物种模板和关系表数据模型。"""

from dataclasses import dataclass, field
from typing import Dict, Optional, Tuple


@dataclass(frozen=True)
class LifeStageProfile:
    stage_id: str
    display_name: str
    maturity: float
    speed_multiplier: float = 1.0
    hunger_multiplier: float = 1.0
    mortality_risk: float = 1.0


@dataclass(frozen=True)
class DietProfile:
    diet_mode: str
    primary_foods: Tuple[str, ...] = ()
    fallback_foods: Tuple[str, ...] = ()
    opportunistic_foods: Tuple[str, ...] = ()


@dataclass(frozen=True)
class BehaviorProfile:
    movement_mode: str
    social_mode: str
    breeding_mode: str
    is_nocturnal: bool = False
    forms_groups: bool = False
    uses_territory: bool = False


@dataclass(frozen=True)
class HabitatProfile:
    biomes: Tuple[str, ...]
    microhabitats: Tuple[str, ...] = ()
    preferred_climate: Tuple[str, ...] = ()


@dataclass(frozen=True)
class SocialProfile:
    grouping: str = "solitary"
    dominance_system: str = "none"
    caregiving_mode: str = "minimal"


@dataclass(frozen=True)
class TerritoryProfile:
    territory_mode: str = "none"
    territory_radius: float = 0.0
    breeding_site_required: bool = False


@dataclass(frozen=True)
class EcologicalFlags:
    keystone: bool = False
    engineer: bool = False
    cleaner: bool = False
    pollinator: bool = False
    seed_disperser: bool = False
    parasite_host: bool = False
    flagship: bool = False


@dataclass(frozen=True)
class SpeciesTemplate:
    template_id: str
    role: str
    domain: str
    body_size_class: str
    diet: DietProfile
    behavior: BehaviorProfile
    habitat: HabitatProfile
    social: SocialProfile
    territory: TerritoryProfile
    life_stages: Tuple[LifeStageProfile, ...]
    notes: str = ""


@dataclass(frozen=True)
class SpeciesVariant:
    species_id: str
    cn_name: str
    scientific_name: str
    template_id: str
    native_regions: Tuple[str, ...]
    biome_affinity: Tuple[str, ...]
    trait_modifiers: Dict[str, float] = field(default_factory=dict)
    encyclopedia_entry: str = ""
    flags: EcologicalFlags = EcologicalFlags()


@dataclass(frozen=True)
class RelationTable:
    relation_id: str
    relation_type: str
    source_species: str
    target_species: str
    stage_constraints: Tuple[str, ...] = ()
    habitat_constraints: Tuple[str, ...] = ()
    strength: float = 1.0
    notes: str = ""

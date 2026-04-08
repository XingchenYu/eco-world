"""v4 区域级关键种级联影响摘要。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Dict, List, Optional

from src.data import WorldRegistry
from src.world import Region

if TYPE_CHECKING:
    from .competition import RegionCompetitionSummary
    from .predation import RegionPredationSummary
    from .symbiosis import RegionSymbiosisSummary


@dataclass
class RegionCascadeSummary:
    """区域级关键种级联影响摘要。"""

    region_id: str
    driver_species: List[str] = field(default_factory=list)
    impact_scores: Dict[str, float] = field(default_factory=dict)
    active_pressures: List[str] = field(default_factory=list)
    narrative_impacts: List[str] = field(default_factory=list)
    source_modules: List[str] = field(default_factory=list)


def apply_region_cascade_feedback(region: Region, cascade: RegionCascadeSummary, feedback_scale: float = 0.02) -> None:
    """将区域级联摘要轻量回灌到区域状态。"""

    impacts = cascade.impact_scores

    _adjust(region.resource_state, "freshwater", impacts.get("wetland_expansion", 0.0) * 0.60, feedback_scale)
    _adjust(region.resource_state, "surface_water", impacts.get("wetland_expansion", 0.0) * 0.60, feedback_scale)
    _adjust(region.resource_state, "open_water", impacts.get("wetland_expansion", 0.0) * 0.55, feedback_scale)
    _adjust(region.resource_state, "reed_cover", impacts.get("wetland_expansion", 0.0) * 0.42, feedback_scale)
    _adjust(region.resource_state, "shore_hatch", impacts.get("nursery_habitat_gain", 0.0) * 0.60, feedback_scale)
    _adjust(region.resource_state, "water_nutrients", impacts.get("nutrient_input", 0.0) * 0.75, feedback_scale)
    _adjust(region.resource_state, "grazing_biomass", impacts.get("grazing_pressure", 0.0) * 0.50, feedback_scale)
    _adjust(region.resource_state, "canopy_cover", -impacts.get("canopy_opening", 0.0) * 0.80, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -impacts.get("grazing_pressure", 0.0) * 0.55, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -impacts.get("canopy_browsing", 0.0) * 0.35, feedback_scale)
    _adjust(region.resource_state, "fruit_pulse", impacts.get("seed_dispersal", 0.0) * 0.25, feedback_scale)

    _adjust(region.hazard_state, "flood_risk", impacts.get("wetland_expansion", 0.0) * 0.20, feedback_scale)
    _adjust(region.hazard_state, "shoreline_risk", impacts.get("shoreline_risk", 0.0), feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", impacts.get("shoreline_risk", 0.0) * 0.55, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", impacts.get("canopy_opening", 0.0) * 0.20, feedback_scale)

    _adjust(region.health_state, "biodiversity", impacts.get("nursery_habitat_gain", 0.0) * 0.35, feedback_scale)
    _adjust(region.health_state, "biodiversity", impacts.get("seed_dispersal", 0.0) * 0.20, feedback_scale)
    _adjust(region.health_state, "biodiversity", impacts.get("mutualist_support", 0.0) * 0.18, feedback_scale)
    _adjust(region.health_state, "resilience", impacts.get("wetland_expansion", 0.0) * 0.28, feedback_scale)
    _adjust(region.health_state, "resilience", impacts.get("nutrient_input", 0.0) * 0.25, feedback_scale)
    _adjust(region.health_state, "resilience", impacts.get("mutualist_support", 0.0) * 0.22, feedback_scale)
    _adjust(region.health_state, "fragmentation", impacts.get("competitive_stress", 0.0) * 0.06, feedback_scale)
    _adjust(region.health_state, "fragmentation", -impacts.get("canopy_opening", 0.0) * 0.12, feedback_scale)


def build_region_cascade_summary(
    region: Region,
    registry: WorldRegistry,
    competition: Optional["RegionCompetitionSummary"] = None,
    predation: Optional["RegionPredationSummary"] = None,
    symbiosis: Optional["RegionSymbiosisSummary"] = None,
) -> RegionCascadeSummary:
    """根据区域关键种和关系网生成粗粒度级联影响摘要。"""

    resident_species = registry.species_for_region(region.region_id)
    region_species = set(region.species_pool) if region.species_pool else set(resident_species)

    driver_species = sorted(
        species_id
        for species_id, variant in resident_species.items()
        if species_id in region_species and (variant.flags.keystone or variant.flags.engineer or variant.flags.flagship)
    )

    impact_scores: Dict[str, float] = {}
    active_pressures: List[str] = []
    narrative_impacts: List[str] = []
    source_modules: List[str] = []

    def add_impact(key: str, value: float, pressure: str, narrative: str) -> None:
        impact_scores[key] = round(impact_scores.get(key, 0.0) + value, 2)
        if pressure not in active_pressures:
            active_pressures.append(pressure)
        if narrative not in narrative_impacts:
            narrative_impacts.append(narrative)

    if "beaver" in region_species:
        add_impact(
            "wetland_expansion",
            0.9,
            "hydrology_retention",
            "河狸通过筑坝和拦水提升湿地面积与岸带复杂度。",
        )
        add_impact(
            "nursery_habitat_gain",
            0.55,
            "riparian_complexity",
            "河狸创造的缓流水域提升了两栖和岸带幼体的庇护价值。",
        )

    if "hippopotamus" in region_species:
        add_impact(
            "nutrient_input",
            0.85,
            "shoreline_grazing",
            "河马在水陆之间搬运营养，增强岸带和浅水带生产力。",
        )
        add_impact(
            "shoreline_disturbance",
            0.45,
            "bank_disturbance",
            "河马的上岸取食和踩踏会重塑岸带植被和浅滩结构。",
        )

    if "nile_crocodile" in region_species:
        add_impact(
            "shoreline_risk",
            0.88,
            "ambush_predation",
            "鳄鱼提高饮水点和浅滩的伏击风险，改变岸线使用方式。",
        )

    if "african_elephant" in region_species:
        add_impact(
            "canopy_opening",
            0.82,
            "megaherbivore_engineering",
            "大象通过折断乔木和踩踏灌丛扩大开阔草地与通道。",
        )
        add_impact(
            "seed_dispersal",
            0.5,
            "landscape_redistribution",
            "大象促进大型种子跨斑块扩散，改变区域植被更新方向。",
        )

    if "white_rhino" in region_species:
        add_impact(
            "grazing_pressure",
            0.76,
            "grazer_competition",
            "白犀维持低矮草场并压制灌丛回侵。",
        )
        add_impact(
            "mud_wallow_disturbance",
            0.42,
            "wallow_site_competition",
            "白犀围绕泥浴点和水源形成局部踩踏与资源竞争。",
        )

    if "giraffe" in region_species:
        add_impact(
            "canopy_browsing",
            0.72,
            "vertical_foraging_partition",
            "长颈鹿利用高树冠资源，形成与地面食草兽分层的取食格局。",
        )

    if competition is not None:
        source_modules.append("competition")
        if competition.pressure_scores:
            impact_scores["competitive_stress"] = round(sum(competition.pressure_scores.values()), 2)
        for resource in competition.contested_resources:
            if resource not in active_pressures:
                active_pressures.append(resource)
        for narrative in competition.narrative_competition:
            if narrative not in narrative_impacts:
                narrative_impacts.append(narrative)

    if predation is not None:
        source_modules.append("predation")
        if predation.pressure_scores:
            impact_scores["predation_load"] = round(sum(predation.pressure_scores.values()), 2)
        for resource in predation.vulnerable_resources:
            if resource not in active_pressures:
                active_pressures.append(resource)
        for narrative in predation.narrative_predation:
            if narrative not in narrative_impacts:
                narrative_impacts.append(narrative)

    if symbiosis is not None:
        source_modules.append("symbiosis")
        if symbiosis.support_scores:
            impact_scores["mutualist_support"] = round(sum(symbiosis.support_scores.values()), 2)
        for resource in symbiosis.supported_resources:
            if resource not in active_pressures:
                active_pressures.append(resource)
        for narrative in symbiosis.narrative_symbiosis:
            if narrative not in narrative_impacts:
                narrative_impacts.append(narrative)

    return RegionCascadeSummary(
        region_id=region.region_id,
        driver_species=driver_species,
        impact_scores=dict(sorted(impact_scores.items())),
        active_pressures=sorted(active_pressures),
        narrative_impacts=narrative_impacts,
        source_modules=source_modules,
    )


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

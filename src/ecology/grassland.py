"""v4 草原链摘要、反馈与重平衡。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List

from src.data import WorldRegistry
from src.world import Region


@dataclass
class RegionGrasslandChainSummary:
    """草原大型植食者链摘要。"""

    region_id: str
    key_species: List[str] = field(default_factory=list)
    trophic_scores: Dict[str, float] = field(default_factory=dict)
    layer_scores: Dict[str, float] = field(default_factory=dict)
    layer_species: Dict[str, List[str]] = field(default_factory=dict)
    narrative_chain: List[str] = field(default_factory=list)


def build_region_grassland_chain_summary(region: Region, registry: WorldRegistry) -> RegionGrasslandChainSummary:
    """构建草原大型植食者链摘要。非草原区返回空摘要。"""

    if not _is_grassland_region(region):
        return RegionGrasslandChainSummary(region_id=region.region_id)

    region_species = set(region.species_pool)
    key_species = [
        species
        for species in ["african_elephant", "white_rhino", "giraffe", "antelope", "zebra", "lion", "hyena"]
        if species in region_species
    ]

    trophic_scores: Dict[str, float] = {}
    layer_scores: Dict[str, float] = {}
    layer_species: Dict[str, List[str]] = {
        "grazing_layer": [],
        "browse_layer": [],
        "engineering_layer": [],
        "herd_layer": [],
        "predator_layer": [],
        "scavenger_layer": [],
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

    if "african_elephant" in region_species:
        add_score("canopy_opening", 0.82, "大象通过开林和踩踏重塑草灌边界。")
        add_score("seed_dispersal", 0.54, "大象扩大大型种子的景观级扩散。")
        add_layer("engineering_layer", "african_elephant", 0.82)

    if "white_rhino" in region_species:
        add_score("grazing_pressure", 0.76, "白犀维持低矮草场并压制灌丛回侵。")
        add_score("mud_wallow_disturbance", 0.42, "白犀围绕泥浴点形成局部踩踏和资源聚集。")
        add_layer("grazing_layer", "white_rhino", 0.76)

    if "giraffe" in region_species:
        add_score("canopy_browsing", 0.72, "长颈鹿利用高树冠叶源形成垂直取食分层。")
        add_layer("browse_layer", "giraffe", 0.72)
    if "antelope" in region_species:
        add_score("herd_grazing", 0.69, "羚羊群在开阔草场形成高频取食与逃逸通道。")
        add_layer("herd_layer", "antelope", 0.69)
    if "zebra" in region_species:
        add_score("migration_pressure", 0.65, "斑马群会沿水源和草场形成稳定迁移走廊。")
        add_layer("herd_layer", "zebra", 0.65)

    if {"african_elephant", "white_rhino"} <= region_species:
        add_score("waterhole_competition_bridge", 0.48, "大型植食者会围绕水源和泥浴位点形成持续竞争。")
    if {"african_elephant", "giraffe"} <= region_species:
        add_score("vertical_partitioning", 0.51, "大象与长颈鹿共同塑造草地到树冠的垂直资源分层。")
    if {"african_elephant", "white_rhino", "giraffe"} <= region_species:
        add_score("megaherbivore_stack", 0.74, "大象、白犀和长颈鹿共同形成草原大型植食者结构骨架。")
    if "lion" in region_species:
        add_score("apex_predation", 0.71, "狮群围绕草食动物通道与水源形成顶层捕食压力。")
        add_layer("predator_layer", "lion", 0.71)
    if "hyena" in region_species:
        add_score("carrion_scavenging", 0.66, "鬣狗把尸体资源和机会型捕食重新接回草原营养循环。")
        add_layer("scavenger_layer", "hyena", 0.66)
    if {"lion", "hyena"} <= region_species:
        add_score("carcass_competition", 0.57, "狮与鬣狗围绕猎物残体和水源形成持续竞争。")
    if {"antelope", "zebra"} & region_species:
        add_score("prey_corridor_density", 0.58, "草原猎物群提高了捕食者与清道夫的空间联动密度。")
    if {"lion", "hyena", "african_elephant", "white_rhino", "giraffe"} <= region_species:
        add_score("grassland_predator_closure", 0.63, "顶层捕食者与大型植食者共同闭合草原主食物链。")
    if {"lion", "hyena"} <= region_species and {"antelope", "zebra"} & region_species:
        add_score("herd_predator_loop", 0.67, "草原食草群与狮鬣狗共同形成更完整的顶层捕食闭环。")

    return RegionGrasslandChainSummary(
        region_id=region.region_id,
        key_species=key_species,
        trophic_scores=dict(sorted(trophic_scores.items())),
        layer_scores=dict(sorted(layer_scores.items())),
        layer_species={layer: sorted(species) for layer, species in layer_species.items() if species},
        narrative_chain=narrative_chain,
    )


def apply_region_grassland_chain_feedback(
    region: Region,
    grassland_chain: RegionGrasslandChainSummary,
    feedback_scale: float = 0.02,
) -> None:
    """将草原大型植食者链摘要轻量回灌到区域状态。"""

    scores = grassland_chain.trophic_scores

    _adjust(region.resource_state, "grazing_biomass", scores.get("grazing_pressure", 0.0) * 0.35, feedback_scale)
    _adjust(region.resource_state, "grazing_biomass", scores.get("herd_grazing", 0.0) * 0.24, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -scores.get("canopy_browsing", 0.0) * 0.34, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -scores.get("canopy_opening", 0.0) * 0.25, feedback_scale)
    _adjust(region.resource_state, "canopy_cover", -scores.get("canopy_opening", 0.0) * 0.38, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("waterhole_competition_bridge", 0.0) * 0.12, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("migration_pressure", 0.0) * 0.10, feedback_scale)
    _adjust(region.resource_state, "dung_cycle", scores.get("carrion_scavenging", 0.0) * 0.16, feedback_scale)

    _adjust(region.hazard_state, "predation_pressure", scores.get("canopy_opening", 0.0) * 0.16, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("apex_predation", 0.0) * 0.28, feedback_scale)
    _adjust(region.hazard_state, "drought_risk", scores.get("grazing_pressure", 0.0) * 0.08, feedback_scale)

    _adjust(region.health_state, "biodiversity", scores.get("megaherbivore_stack", 0.0) * 0.22, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("vertical_partitioning", 0.0) * 0.18, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("grassland_predator_closure", 0.0) * 0.16, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("herd_predator_loop", 0.0) * 0.16, feedback_scale)
    _adjust(region.health_state, "fragmentation", -scores.get("canopy_opening", 0.0) * 0.08, feedback_scale)


def apply_region_grassland_chain_rebalancing(region: Region, grassland_chain: RegionGrasslandChainSummary) -> List[dict]:
    """根据草原链结构对物种池做低频、轻量重平衡。"""

    if not grassland_chain.trophic_scores:
        return []

    adjustments: List[dict] = []
    species_pool = region.species_pool
    scores = grassland_chain.trophic_scores

    elephant_count = species_pool.get("african_elephant", 0)
    rhino_count = species_pool.get("white_rhino", 0)
    giraffe_count = species_pool.get("giraffe", 0)
    lion_count = species_pool.get("lion", 0)
    hyena_count = species_pool.get("hyena", 0)
    rabbit_count = species_pool.get("rabbit", 0)

    megaherbivore_stack = scores.get("megaherbivore_stack", 0.0)
    predator_closure = scores.get("grassland_predator_closure", 0.0)
    carcass_competition = scores.get("carcass_competition", 0.0)
    apex_predation = scores.get("apex_predation", 0.0)

    if megaherbivore_stack >= 0.7 and elephant_count > 0 and rhino_count > 0 and giraffe_count > 0:
        if rabbit_count < 24:
            species_pool["rabbit"] = rabbit_count + 2
            adjustments.append(
                {
                    "source_species": "grassland_chain",
                    "target_species": "rabbit",
                    "layer_group": "grazing_layer",
                    "effect": "grazing_patch_support",
                    "new_target_count": species_pool["rabbit"],
                }
            )

    if predator_closure >= 0.6 and lion_count > 0 and hyena_count > 0:
        if rabbit_count > 10:
            species_pool["rabbit"] = rabbit_count - 1
            adjustments.append(
                {
                    "source_species": "grassland_chain",
                    "target_species": "rabbit",
                    "layer_group": "predator_layer",
                    "effect": "top_down_trim",
                    "new_target_count": species_pool["rabbit"],
                }
            )

    if carcass_competition >= 0.5 and lion_count >= 3 and hyena_count >= 4:
        if hyena_count > lion_count:
            species_pool["hyena"] = hyena_count - 1
            adjustments.append(
                {
                    "source_species": "lion",
                    "target_species": "hyena",
                    "layer_group": "scavenger_layer",
                    "effect": "carcass_pressure",
                    "new_target_count": species_pool["hyena"],
                }
            )
        elif lion_count > 2:
            species_pool["lion"] = lion_count - 1
            adjustments.append(
                {
                    "source_species": "hyena",
                    "target_species": "lion",
                    "layer_group": "predator_layer",
                    "effect": "carcass_pressure",
                    "new_target_count": species_pool["lion"],
                }
            )

    if apex_predation >= 0.7 and giraffe_count > 3 and lion_count >= 2:
        species_pool["giraffe"] = giraffe_count - 1
        adjustments.append(
            {
                "source_species": "lion",
                "target_species": "giraffe",
                "layer_group": "browse_layer",
                "effect": "apex_browse_pressure",
                "new_target_count": species_pool["giraffe"],
            }
        )

    antelope_count = species_pool.get("antelope", 0)
    zebra_count = species_pool.get("zebra", 0)
    herd_loop = scores.get("herd_predator_loop", 0.0)
    prey_density = scores.get("prey_corridor_density", 0.0)

    if prey_density >= 0.55 and antelope_count < 24:
        species_pool["antelope"] = antelope_count + 1
        adjustments.append(
            {
                "source_species": "grassland_chain",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "herd_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if prey_density >= 0.55 and zebra_count < 16:
        species_pool["zebra"] = zebra_count + 1
        adjustments.append(
            {
                "source_species": "grassland_chain",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "herd_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if herd_loop >= 0.6 and lion_count > 0 and antelope_count > 8:
        species_pool["antelope"] = max(6, species_pool["antelope"] - 1)
        adjustments.append(
            {
                "source_species": "lion",
                "target_species": "antelope",
                "layer_group": "predator_layer",
                "effect": "herd_trim",
                "new_target_count": species_pool["antelope"],
            }
        )

    return adjustments


def _is_grassland_region(region: Region) -> bool:
    if region.region_id == "temperate_grassland":
        return True
    return any(biome in {"grassland", "savanna", "shrubland", "seasonal_waterhole"} for biome in region.dominant_biomes)


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

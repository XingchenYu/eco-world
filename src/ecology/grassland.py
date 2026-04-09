"""v4 草原链摘要、反馈与重平衡。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

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
    dominant_layer: str = ""
    narrative_chain: List[str] = field(default_factory=list)


def build_region_grassland_chain_summary(
    region: Region,
    registry: WorldRegistry,
    territory_summary: Optional[object] = None,
    social_trend_summary: Optional[object] = None,
) -> RegionGrasslandChainSummary:
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
        "social_layer": [],
    }
    narrative_chain: List[str] = []
    herd_route_cycle = 0.0

    def add_score(key: str, value: float, narrative: str) -> None:
        trophic_scores[key] = round(trophic_scores.get(key, 0.0) + value, 2)
        if narrative not in narrative_chain:
            narrative_chain.append(narrative)

    def add_layer(layer: str, species: str, value: float) -> None:
        layer_scores[layer] = round(layer_scores.get(layer, 0.0) + value, 2)
        if species not in layer_species[layer]:
            layer_species[layer].append(species)

    def add_layer_bias(layer: str, value: float) -> None:
        layer_scores[layer] = round(layer_scores.get(layer, 0.0) + value, 2)

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
        add_score("pride_patrol", 0.56, "狮群会围绕草食走廊和水源形成稳定巡猎带。")
        add_score("male_competition_pressure", 0.41, "雄狮之间的支配竞争会重新分配巡猎核心区。")
        add_layer("social_layer", "lion", 0.56)
    if "hyena" in region_species:
        add_score("carrion_scavenging", 0.66, "鬣狗把尸体资源和机会型捕食重新接回草原营养循环。")
        add_layer("scavenger_layer", "hyena", 0.66)
        add_score("clan_pressure", 0.54, "鬣狗 clan 会围绕尸体、水源和猎物走廊形成集群压力。")
        add_score("den_cluster_pressure", 0.38, "鬣狗 clan 的稳定活动区会改变草原边缘资源利用。")
        add_layer("social_layer", "hyena", 0.54)
    if {"lion", "hyena"} <= region_species:
        add_score("carcass_competition", 0.57, "狮与鬣狗围绕猎物残体和水源形成持续竞争。")
        add_score("apex_rivalry", 0.59, "狮群与鬣狗 clan 的对抗会重新塑造顶层空间边界。")
    if {"antelope", "zebra"} & region_species:
        add_score("prey_corridor_density", 0.58, "草原猎物群提高了捕食者与清道夫的空间联动密度。")
    if {"lion", "hyena", "african_elephant", "white_rhino", "giraffe"} <= region_species:
        add_score("grassland_predator_closure", 0.63, "顶层捕食者与大型植食者共同闭合草原主食物链。")
    if {"lion", "hyena"} <= region_species and {"antelope", "zebra"} & region_species:
        add_score("herd_predator_loop", 0.67, "草原食草群与狮鬣狗共同形成更完整的顶层捕食闭环。")
        add_score("group_hunt_instability", 0.45, "猎物群规模越大，狮群与鬣狗 clan 的协同追逐和冲突越明显。")
    if territory_summary is not None:
        runtime_signals = getattr(territory_summary, "runtime_signals", {}) or {}
        shared_hotspots = int(runtime_signals.get("shared_hotspot_overlap", 0))
        lion_hotspots = int(runtime_signals.get("lion_hotspot_count", 0))
        hyena_hotspots = int(runtime_signals.get("hyena_hotspot_count", 0))
        herd_hotspots = int(runtime_signals.get("herd_hotspot_count", 0))
        herd_apex_overlap = int(runtime_signals.get("herd_apex_overlap", 0))
        herd_condition_runtime = float(runtime_signals.get("herd_condition_runtime", 0.0))
        herd_condition_phase_runtime = float(runtime_signals.get("herd_condition_phase_runtime", 0.0))
        herd_condition_phase_bias_runtime = float(runtime_signals.get("herd_condition_phase_bias_runtime", 0.0))
        herd_regional_health_runtime = float(runtime_signals.get("herd_regional_health_runtime", 0.0))
        herd_regional_health_anchor_runtime = float(runtime_signals.get("herd_regional_health_anchor_runtime", 0.0))
        herd_regional_bias_runtime = float(runtime_signals.get("herd_regional_bias_runtime", 0.0))
        apex_condition_runtime = float(runtime_signals.get("apex_condition_runtime", 0.0))
        apex_condition_phase_runtime = float(runtime_signals.get("apex_condition_phase_runtime", 0.0))
        apex_condition_phase_bias_runtime = float(runtime_signals.get("apex_condition_phase_bias_runtime", 0.0))
        apex_regional_health_runtime = float(runtime_signals.get("apex_regional_health_runtime", 0.0))
        apex_regional_health_anchor_runtime = float(runtime_signals.get("apex_regional_health_anchor_runtime", 0.0))
        apex_condition_anchor_runtime = float(runtime_signals.get("apex_condition_anchor_runtime", 0.0))
        apex_regional_bias_runtime = float(runtime_signals.get("apex_regional_bias_runtime", 0.0))
        herd_resource_anchor_runtime = float(runtime_signals.get("herd_resource_anchor_runtime", 0.0))
        herd_condition_anchor_runtime = float(runtime_signals.get("herd_condition_anchor_runtime", 0.0))
        herd_anchor_prosperity_runtime = float(runtime_signals.get("herd_anchor_prosperity_runtime", 0.0))
        apex_anchor_prosperity_runtime = float(runtime_signals.get("apex_anchor_prosperity_runtime", 0.0))
        if int(runtime_signals.get("herd_channel_bias", 0)) > 0:
            add_score("dominant_herd_channeling", 0.18, "上一周期的草食群主导态正在把草原通道重新拉回 herd 核心。")
        if int(runtime_signals.get("apex_hotspot_bias", 0)) > 0:
            add_score("dominant_apex_layout", 0.18, "上一周期的顶层主导态正在把热点重新压回 apex 巡猎核心。")
        if int(runtime_signals.get("scavenger_hotspot_bias", 0)) > 0:
            add_score("dominant_scavenger_layout", 0.16, "上一周期的清道夫主导态正在把草原热点重新拉向尸体资源通道。")
        if shared_hotspots > 0:
            add_score("hotspot_overlap_pressure", min(0.42, shared_hotspots * 0.16), "狮群与鬣狗 clan 的热点重叠会把草原资源通道挤压成更高冲突密度。")
            add_score("carcass_channeling", min(0.36, shared_hotspots * 0.14), "领地热点重叠会把尸体与伏击资源进一步集中到少数核心通道。")
        if lion_hotspots > 0 and hyena_hotspots > 0:
            add_score("territory_channel_pressure", min(0.34, (lion_hotspots + hyena_hotspots) * 0.06), "多个 pride 与 clan 热点会强化草原顶层巡猎和清道夫路线的空间压缩。")
        if herd_hotspots > 0:
            add_score("runtime_herd_corridors", min(0.28, herd_hotspots * 0.05), "运行中的食草群热点正在重新加深草原 herd 通道。")
        if herd_apex_overlap > 0:
            add_score("runtime_herd_apex_overlap", min(0.24, herd_apex_overlap * 0.06), "食草群与顶层热点重叠正在抬高草原通道冲突密度。")
        herd_surface_water_runtime = float(runtime_signals.get("herd_surface_water_runtime", 0.0))
        if herd_surface_water_runtime > 0.0:
            add_score("runtime_surface_water_pull", min(0.22, herd_surface_water_runtime * 0.16), "运行中的食草群水源依赖正在把草原通道重新拉向稳定水源轴。")
            add_layer_bias("herd_layer", herd_surface_water_runtime * 0.08)
        if herd_condition_runtime > 0.0:
            add_score("runtime_herd_condition_pull", min(0.18, herd_condition_runtime * 0.14), "运行中的食草群真实体况正在把 herd 通道重新压回更稳定的草原走廊。")
            add_layer_bias("herd_layer", herd_condition_runtime * 0.06)
        if herd_condition_phase_runtime > 0.0:
            add_score("runtime_herd_condition_phase_pull", min(0.20, herd_condition_phase_runtime * 0.14), "长期相位修正后的食草群真实体况正在把 herd 通道继续压回更稳定的草原走廊。")
            add_layer_bias("herd_layer", herd_condition_phase_runtime * 0.07)
            add_layer_bias("social_layer", herd_condition_phase_runtime * 0.03)
        if herd_condition_phase_bias_runtime > 0.0:
            add_score("runtime_herd_condition_phase_bias_pull", min(0.18, herd_condition_phase_bias_runtime * 0.12), "长期 prosperity/collapse 直接沉淀成的 herd 体况偏置，正在继续放大稳定草原走廊。")
            add_layer_bias("herd_layer", herd_condition_phase_bias_runtime * 0.06)
            add_layer_bias("social_layer", herd_condition_phase_bias_runtime * 0.03)
        if herd_regional_health_runtime > 0.0:
            add_score("runtime_herd_health_pull", min(0.20, herd_regional_health_runtime * 0.14), "运行中的食草群长期健康度正在把 herd 通道拉向更稳定的草原走廊。")
            add_layer_bias("herd_layer", herd_regional_health_runtime * 0.07)
        if herd_regional_health_anchor_runtime > 0.0:
            add_score("runtime_herd_health_anchor_pull", min(0.20, herd_regional_health_anchor_runtime * 0.14), "运行中的区域长期健康锚点正在继续抬升 herd 通道的稳定走廊效应。")
            add_layer_bias("herd_layer", herd_regional_health_anchor_runtime * 0.07)
            add_layer_bias("social_layer", herd_regional_health_anchor_runtime * 0.04)
        herd_condition_phase_anchor_runtime = float(runtime_signals.get("herd_condition_phase_anchor_runtime", 0.0))
        if herd_condition_anchor_runtime > 0.0:
            add_score("runtime_herd_condition_anchor_pull", min(0.18, herd_condition_anchor_runtime * 0.13), "运行中的真实体况锚点正在把 herd 通道继续拉向更稳定的草原走廊。")
            add_layer_bias("herd_layer", herd_condition_anchor_runtime * 0.06)
            add_layer_bias("social_layer", herd_condition_anchor_runtime * 0.03)
        if herd_condition_phase_anchor_runtime > 0.0:
            add_score("runtime_herd_condition_phase_anchor_pull", min(0.20, herd_condition_phase_anchor_runtime * 0.13), "长期相位修正后的真实体况锚点正在把 herd 通道继续拉向更稳定的草原走廊。")
            add_layer_bias("herd_layer", herd_condition_phase_anchor_runtime * 0.07)
            add_layer_bias("social_layer", herd_condition_phase_anchor_runtime * 0.04)
        if herd_regional_bias_runtime > 0.0:
            add_score("runtime_herd_regional_bias_pull", min(0.20, herd_regional_bias_runtime * 0.14), "运行中的区域长期社会锚点正在把 herd 通道继续拉向更稳定的草原走廊。")
            add_layer_bias("herd_layer", herd_regional_bias_runtime * 0.07)
            add_layer_bias("social_layer", herd_regional_bias_runtime * 0.04)
        if apex_regional_health_runtime > 0.0:
            add_score("runtime_apex_health_pull", min(0.18, apex_regional_health_runtime * 0.12), "运行中的顶层捕食者长期健康度正在把草原热点重新压向 apex 核心。")
            add_layer_bias("predator_layer", apex_regional_health_runtime * 0.06)
        if apex_condition_runtime > 0.0:
            add_score("runtime_apex_condition_pull", min(0.16, apex_condition_runtime * 0.12), "运行中的顶层捕食者真实体况正在把草原热点重新压向更强的 apex 核心。")
            add_layer_bias("predator_layer", apex_condition_runtime * 0.05)
        if apex_condition_phase_runtime > 0.0:
            add_score("runtime_apex_condition_phase_pull", min(0.18, apex_condition_phase_runtime * 0.12), "长期相位修正后的顶层真实体况正在把草原热点继续压向更稳定的 apex 核心。")
            add_layer_bias("predator_layer", apex_condition_phase_runtime * 0.06)
            add_layer_bias("social_layer", apex_condition_phase_runtime * 0.03)
        if apex_condition_phase_bias_runtime > 0.0:
            add_score("runtime_apex_condition_phase_bias_pull", min(0.16, apex_condition_phase_bias_runtime * 0.11), "长期 prosperity/collapse 直接沉淀成的 apex 体况偏置，正在继续抬升顶层热点稳定度。")
            add_layer_bias("predator_layer", apex_condition_phase_bias_runtime * 0.05)
            add_layer_bias("social_layer", apex_condition_phase_bias_runtime * 0.03)
        if apex_regional_health_anchor_runtime > 0.0:
            add_score("runtime_apex_health_anchor_pull", min(0.18, apex_regional_health_anchor_runtime * 0.12), "运行中的区域长期健康锚点正在继续把 apex 热点压向更稳定的前线核心。")
            add_layer_bias("predator_layer", apex_regional_health_anchor_runtime * 0.06)
            add_layer_bias("social_layer", apex_regional_health_anchor_runtime * 0.04)
        apex_condition_phase_anchor_runtime = float(runtime_signals.get("apex_condition_phase_anchor_runtime", 0.0))
        if apex_condition_anchor_runtime > 0.0:
            add_score("runtime_apex_condition_anchor_pull", min(0.15, apex_condition_anchor_runtime * 0.12), "运行中的顶层体况锚点正在把 apex 热点继续拉回更稳定的长期核心。")
            add_layer_bias("predator_layer", apex_condition_anchor_runtime * 0.05)
            add_layer_bias("social_layer", apex_condition_anchor_runtime * 0.03)
        if apex_condition_phase_anchor_runtime > 0.0:
            add_score("runtime_apex_condition_phase_anchor_pull", min(0.17, apex_condition_phase_anchor_runtime * 0.12), "长期相位修正后的顶层体况锚点正在把 apex 热点继续拉回更稳定的长期核心。")
            add_layer_bias("predator_layer", apex_condition_phase_anchor_runtime * 0.06)
            add_layer_bias("social_layer", apex_condition_phase_anchor_runtime * 0.04)
        if apex_regional_bias_runtime > 0.0:
            add_score("runtime_apex_regional_bias_pull", min(0.18, apex_regional_bias_runtime * 0.12), "运行中的区域长期社会锚点正在把 apex 热点继续压向更稳定的核心前线。")
            add_layer_bias("predator_layer", apex_regional_bias_runtime * 0.06)
            add_layer_bias("social_layer", apex_regional_bias_runtime * 0.04)
        if herd_resource_anchor_runtime > 0.0:
            add_score("runtime_herd_resource_anchor_pull", min(0.22, herd_resource_anchor_runtime * 0.14), "运行中的草食群资源锚点正在把 herd 通道重新压回稳定饮水与放牧轴。")
            add_layer_bias("herd_layer", herd_resource_anchor_runtime * 0.08)
            add_layer_bias("social_layer", herd_resource_anchor_runtime * 0.04)
        if herd_anchor_prosperity_runtime > 0.0:
            add_score("runtime_herd_anchor_prosperity_pull", min(0.20, herd_anchor_prosperity_runtime * 0.13), "运行中的草食群繁荣锚点正在把 herd 通道重新推向更持久的稳定核心。")
            add_layer_bias("herd_layer", herd_anchor_prosperity_runtime * 0.07)
            add_layer_bias("social_layer", herd_anchor_prosperity_runtime * 0.04)
        if apex_anchor_prosperity_runtime > 0.0:
            add_score("runtime_apex_anchor_prosperity_pull", min(0.18, apex_anchor_prosperity_runtime * 0.12), "运行中的顶层繁荣锚点正在把草原热点重新收拢到更稳定的 apex 前线。")
            add_layer_bias("predator_layer", apex_anchor_prosperity_runtime * 0.06)
        surface_water_anchor = float(runtime_signals.get("surface_water_anchor", 0.0))
        if surface_water_anchor > 0.0:
            add_score("surface_water_anchor", min(0.24, surface_water_anchor * 0.16), "区域水源锚点正在把 herd 通道重新拉回稳定饮水走廊。")
            add_layer_bias("herd_layer", surface_water_anchor * 0.10)
            add_layer_bias("browse_layer", surface_water_anchor * 0.04)
    if social_trend_summary is not None:
        prosperity_scores = getattr(social_trend_summary, "prosperity_scores", {}) or {}
        phase_scores = getattr(social_trend_summary, "phase_scores", {}) or {}
        hotspot_scores = getattr(social_trend_summary, "hotspot_scores", {}) or {}
        grassland_prosperity_phase = float(prosperity_scores.get("grassland_prosperity_phase", 0.0))
        grassland_collapse_phase = float(prosperity_scores.get("grassland_collapse_phase", 0.0))
        herd_route_cycle = float(phase_scores.get("herd_route_cycle", 0.0))
        lion_hotspot_memory = float(hotspot_scores.get("lion_hotspot_memory", 0.0))
        hyena_hotspot_memory = float(hotspot_scores.get("hyena_hotspot_memory", 0.0))
        shared_hotspot_memory = float(hotspot_scores.get("shared_hotspot_memory", 0.0))
        herd_hotspot_memory = float(hotspot_scores.get("herd_hotspot_memory", 0.0))
        herd_apex_memory = float(hotspot_scores.get("herd_apex_memory", 0.0))
        if grassland_prosperity_phase > 0.0:
            add_score("prosperity_phase_weight", grassland_prosperity_phase * 0.24, "区域繁荣相位正在整体抬升草原链的联动权重。")
            add_score("prosperity_feedback_bias", grassland_prosperity_phase * 0.22, "区域繁荣相位正在把草原链推向更高连通度的稳定态。")
            add_layer_bias("herd_layer", grassland_prosperity_phase * 0.10)
            add_layer_bias("predator_layer", grassland_prosperity_phase * 0.08)
        if grassland_collapse_phase > 0.0:
            add_score("collapse_phase_weight", grassland_collapse_phase * 0.22, "区域衰退相位正在整体压缩草原链的稳定权重。")
            add_score("collapse_feedback_bias", grassland_collapse_phase * 0.22, "区域衰退相位正在把草原链推向更高断裂度的收缩态。")
            add_layer_bias("scavenger_layer", grassland_collapse_phase * 0.08)
            add_layer_bias("social_layer", grassland_collapse_phase * 0.08)
        if lion_hotspot_memory > 0.0:
            add_score("hotspot_cycle_pressure", lion_hotspot_memory * 0.22, "持续的狮群热点记忆会放大草原巡猎核心区的多周期占用。")
        if hyena_hotspot_memory > 0.0:
            add_score("hotspot_cycle_pressure", hyena_hotspot_memory * 0.20, "持续的鬣狗热点记忆会强化清道夫通道的多周期跟随。")
        if shared_hotspot_memory > 0.0:
            add_score("hotspot_cycle_overlap", shared_hotspot_memory * 0.24, "共享热点记忆会让草原热点冲突在多周期内持续回响。")
        if herd_hotspot_memory > 0.0:
            add_score("herd_memory_corridors", herd_hotspot_memory * 0.22, "食草群热点记忆正在把迁移通道固化为更稳定的 herd 走廊。")
        if herd_apex_memory > 0.0:
            add_score("herd_memory_pressure", herd_apex_memory * 0.20, "食草群与顶层热点记忆叠加时，会把草原 herd 通道重新压向高风险边缘。")

        if herd_route_cycle > 0.0:
            add_score("herd_route_cycle_pressure", herd_route_cycle * 0.22, "长期 herd-route 周期正在把草原资源重新拉回稳定迁移走廊。")

    regional_prosperity = float(region.health_state.get("prosperity", 0.0))
    regional_collapse = float(region.health_state.get("collapse_risk", 0.0))
    regional_stability = float(region.health_state.get("stability", 0.0))
    if regional_prosperity > 0.0:
        add_score("regional_prosperity_anchor", min(0.24, regional_prosperity * 0.18), "区域长期繁荣度正在直接抬升草原链的稳定主导层。")
        add_layer_bias("herd_layer", regional_prosperity * 0.08)
        add_layer_bias("browse_layer", regional_prosperity * 0.05)
    if regional_stability > 0.0:
        add_score("regional_stability_anchor", min(0.20, regional_stability * 0.16), "区域长期稳定度正在直接压低草原链的瞬时波动。")
        add_layer_bias("social_layer", regional_stability * 0.07)
        add_layer_bias("herd_layer", regional_stability * 0.04)
    if regional_collapse > 0.0:
        add_score("regional_collapse_anchor", min(0.22, regional_collapse * 0.16), "区域长期衰退风险正在把草原链推回更脆弱的顶层和清道夫主导。")
        add_layer_bias("predator_layer", regional_collapse * 0.06)
        add_layer_bias("scavenger_layer", regional_collapse * 0.06)

    dominant_layer = _select_dominant_grassland_layer(
        layer_scores,
        trophic_scores,
    )

    return RegionGrasslandChainSummary(
        region_id=region.region_id,
        key_species=key_species,
        trophic_scores=dict(sorted(trophic_scores.items())),
        layer_scores=dict(sorted(layer_scores.items())),
        layer_species={layer: sorted(species) for layer, species in layer_species.items() if species},
        dominant_layer=dominant_layer,
        narrative_chain=narrative_chain,
    )


def apply_region_grassland_chain_feedback(
    region: Region,
    grassland_chain: RegionGrasslandChainSummary,
    feedback_scale: float = 0.02,
) -> None:
    """将草原大型植食者链摘要轻量回灌到区域状态。"""

    scores = grassland_chain.trophic_scores
    prosperity_bias = 1.0 + min(0.35, scores.get("prosperity_feedback_bias", 0.0))
    collapse_bias = 1.0 + min(0.35, scores.get("collapse_feedback_bias", 0.0))
    dominant_layer = grassland_chain.dominant_layer
    herd_bias = 1.15 if dominant_layer == "herd_layer" else 1.0
    predator_bias = 1.15 if dominant_layer == "predator_layer" else 1.0
    scavenger_bias = 1.15 if dominant_layer == "scavenger_layer" else 1.0
    social_bias = 1.15 if dominant_layer == "social_layer" else 1.0

    _adjust(region.resource_state, "grazing_biomass", scores.get("grazing_pressure", 0.0) * 0.35 * prosperity_bias * herd_bias, feedback_scale)
    _adjust(region.resource_state, "grazing_biomass", scores.get("herd_grazing", 0.0) * 0.24 * prosperity_bias * herd_bias, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -scores.get("canopy_browsing", 0.0) * 0.34 * prosperity_bias, feedback_scale)
    _adjust(region.resource_state, "browse_cover", -scores.get("canopy_opening", 0.0) * 0.25 * collapse_bias, feedback_scale)
    _adjust(region.resource_state, "canopy_cover", -scores.get("canopy_opening", 0.0) * 0.38, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("waterhole_competition_bridge", 0.0) * 0.12, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("migration_pressure", 0.0) * 0.10, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("dominant_herd_channeling", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_corridors", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_surface_water_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_condition_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_condition_phase_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_health_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_health_anchor_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_condition_anchor_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_condition_phase_anchor_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_regional_bias_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_resource_anchor_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("runtime_herd_anchor_prosperity_pull", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("herd_memory_corridors", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "surface_water", scores.get("herd_route_cycle_pressure", 0.0) * 0.10 * herd_bias, feedback_scale)
    _adjust(region.resource_state, "dung_cycle", scores.get("carrion_scavenging", 0.0) * 0.16 * scavenger_bias, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", -scores.get("clan_pressure", 0.0) * 0.06 * collapse_bias * social_bias, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("carcass_channeling", 0.0) * 0.20 * scavenger_bias, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("dominant_scavenger_layout", 0.0) * 0.12 * scavenger_bias, feedback_scale)

    _adjust(region.hazard_state, "predation_pressure", scores.get("canopy_opening", 0.0) * 0.16, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("apex_predation", 0.0) * 0.28 * collapse_bias * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("apex_rivalry", 0.0) * 0.14 * collapse_bias * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("territory_channel_pressure", 0.0) * 0.18 * collapse_bias * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("hotspot_cycle_pressure", 0.0) * 0.18 * collapse_bias * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("herd_memory_pressure", 0.0) * 0.14 * collapse_bias * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("dominant_apex_layout", 0.0) * 0.14 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_herd_apex_overlap", 0.0) * 0.12 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_condition_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_condition_phase_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_health_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_health_anchor_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_condition_anchor_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_condition_phase_anchor_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_regional_bias_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("runtime_apex_anchor_prosperity_pull", 0.0) * 0.10 * predator_bias, feedback_scale)
    _adjust(region.hazard_state, "drought_risk", scores.get("grazing_pressure", 0.0) * 0.08, feedback_scale)

    _adjust(region.health_state, "biodiversity", scores.get("megaherbivore_stack", 0.0) * 0.22 * prosperity_bias, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("vertical_partitioning", 0.0) * 0.18 * prosperity_bias, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("grassland_predator_closure", 0.0) * 0.16 * prosperity_bias, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("herd_predator_loop", 0.0) * 0.16 * prosperity_bias, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("pride_patrol", 0.0) * 0.10 * prosperity_bias * social_bias, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("hotspot_cycle_pressure", 0.0) * 0.08 * prosperity_bias, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("prosperity_phase_weight", 0.0) * 0.12 * prosperity_bias, feedback_scale)
    _adjust(region.health_state, "fragmentation", -scores.get("canopy_opening", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "fragmentation", scores.get("group_hunt_instability", 0.0) * 0.08 * collapse_bias, feedback_scale)
    _adjust(region.health_state, "fragmentation", scores.get("hotspot_overlap_pressure", 0.0) * 0.10 * collapse_bias, feedback_scale)
    _adjust(region.health_state, "fragmentation", scores.get("hotspot_cycle_overlap", 0.0) * 0.10 * collapse_bias, feedback_scale)
    _adjust(region.health_state, "fragmentation", scores.get("collapse_phase_weight", 0.0) * 0.12 * collapse_bias, feedback_scale)


def apply_region_grassland_chain_rebalancing(
    region: Region,
    grassland_chain: RegionGrasslandChainSummary,
    territory_summary: Optional[object] = None,
    social_trend_summary: Optional[object] = None,
) -> List[dict]:
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
    antelope_count = species_pool.get("antelope", 0)
    zebra_count = species_pool.get("zebra", 0)

    megaherbivore_stack = scores.get("megaherbivore_stack", 0.0)
    predator_closure = scores.get("grassland_predator_closure", 0.0)
    carcass_competition = scores.get("carcass_competition", 0.0)
    apex_predation = scores.get("apex_predation", 0.0)
    pride_patrol = scores.get("pride_patrol", 0.0)
    clan_pressure = scores.get("clan_pressure", 0.0)
    apex_rivalry = scores.get("apex_rivalry", 0.0)
    hotspot_overlap = 0
    lion_hotspots = 0
    hyena_hotspots = 0
    pride_strength = 0.0
    clan_cohesion = 0.0
    pride_count_signal = 0
    clan_count_signal = 0
    lion_recovery_bias = 0.0
    lion_decline_bias = 0.0
    hyena_recovery_bias = 0.0
    hyena_decline_bias = 0.0
    lion_expansion_phase = 0.0
    lion_contraction_phase = 0.0
    hyena_expansion_phase = 0.0
    hyena_contraction_phase = 0.0
    grassland_boom_phase = 0.0
    grassland_bust_phase = 0.0
    grassland_prosperity_phase = 0.0
    grassland_collapse_phase = 0.0
    lion_hotspot_memory = 0.0
    hyena_hotspot_memory = 0.0
    shared_hotspot_memory = 0.0
    herd_route_cycle = 0.0
    if territory_summary is not None:
        runtime_signals = getattr(territory_summary, "runtime_signals", {}) or {}
        hotspot_overlap = int(runtime_signals.get("shared_hotspot_overlap", 0))
        lion_hotspots = int(runtime_signals.get("lion_hotspot_count", 0))
        hyena_hotspots = int(runtime_signals.get("hyena_hotspot_count", 0))
        pride_strength = float(runtime_signals.get("lion_pride_strength", 0.0))
        clan_cohesion = float(runtime_signals.get("hyena_clan_cohesion", 0.0))
        pride_count_signal = int(runtime_signals.get("lion_pride_count", 0))
        clan_count_signal = int(runtime_signals.get("hyena_clan_count", 0))
    if social_trend_summary is not None:
        trend_scores = getattr(social_trend_summary, "trend_scores", {}) or {}
        phase_scores = getattr(social_trend_summary, "phase_scores", {}) or {}
        hotspot_scores = getattr(social_trend_summary, "hotspot_scores", {}) or {}
        lion_recovery_bias = float(trend_scores.get("lion_recovery_bias", 0.0))
        lion_decline_bias = float(trend_scores.get("lion_decline_bias", 0.0))
        hyena_recovery_bias = float(trend_scores.get("hyena_recovery_bias", 0.0))
        hyena_decline_bias = float(trend_scores.get("hyena_decline_bias", 0.0))
        lion_expansion_phase = float(phase_scores.get("lion_expansion_phase", 0.0))
        lion_contraction_phase = float(phase_scores.get("lion_contraction_phase", 0.0))
        hyena_expansion_phase = float(phase_scores.get("hyena_expansion_phase", 0.0))
        hyena_contraction_phase = float(phase_scores.get("hyena_contraction_phase", 0.0))
        herd_route_cycle = float(phase_scores.get("herd_route_cycle", 0.0))
        boom_bust_scores = getattr(social_trend_summary, "boom_bust_scores", {}) or {}
        prosperity_scores = getattr(social_trend_summary, "prosperity_scores", {}) or {}
        grassland_boom_phase = float(boom_bust_scores.get("grassland_boom_phase", 0.0))
        grassland_bust_phase = float(boom_bust_scores.get("grassland_bust_phase", 0.0))
        grassland_prosperity_phase = float(prosperity_scores.get("grassland_prosperity_phase", 0.0))
        grassland_collapse_phase = float(prosperity_scores.get("grassland_collapse_phase", 0.0))
        lion_hotspot_memory = float(hotspot_scores.get("lion_hotspot_memory", 0.0))
        hyena_hotspot_memory = float(hotspot_scores.get("hyena_hotspot_memory", 0.0))
        shared_hotspot_memory = float(hotspot_scores.get("shared_hotspot_memory", 0.0))
        herd_route_cycle = float(phase_scores.get("herd_route_cycle", 0.0))

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

    if pride_patrol >= 0.55 and lion_count < 4 and antelope_count >= 16:
        species_pool["lion"] = lion_count + 1
        adjustments.append(
            {
                "source_species": "grassland_chain",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "pride_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if clan_pressure >= 0.5 and hyena_count < 5 and antelope_count + zebra_count >= 20:
        species_pool["hyena"] = hyena_count + 1
        adjustments.append(
            {
                "source_species": "grassland_chain",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "clan_support",
                "new_target_count": species_pool["hyena"],
            }
        )
    if apex_rivalry >= 0.55 and lion_count >= 4 and hyena_count >= 5:
        species_pool["hyena"] = hyena_count - 1
        adjustments.append(
            {
                "source_species": "lion",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "rivalry_trim",
                "new_target_count": species_pool["hyena"],
            }
        )
    if hotspot_overlap > 0 and lion_count >= 3 and hyena_count >= 3:
        if hyena_count >= lion_count:
            species_pool["hyena"] = hyena_count - 1
            adjustments.append(
                {
                    "source_species": "territory",
                    "target_species": "hyena",
                    "layer_group": "social_layer",
                    "effect": "hotspot_overlap_trim",
                    "new_target_count": species_pool["hyena"],
                }
            )
        else:
            species_pool["lion"] = lion_count - 1
            adjustments.append(
                {
                    "source_species": "territory",
                    "target_species": "lion",
                    "layer_group": "social_layer",
                    "effect": "hotspot_overlap_trim",
                    "new_target_count": species_pool["lion"],
                }
            )
    if lion_hotspots >= 2 and lion_count < 5 and antelope_count + zebra_count >= 24:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "territory",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "distributed_pride_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_hotspots >= 2 and hyena_count < 6 and antelope_count + zebra_count >= 24:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "territory",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "distributed_clan_support",
                "new_target_count": species_pool["hyena"],
            }
        )
    if pride_strength >= 0.55 and pride_count_signal >= 2 and lion_count < 5 and antelope_count + zebra_count >= 18:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "stable_pride_recovery",
                "new_target_count": species_pool["lion"],
            }
        )
    if clan_cohesion >= 0.5 and clan_count_signal >= 2 and hyena_count < 6 and antelope_count + zebra_count >= 18:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "stable_clan_recovery",
                "new_target_count": species_pool["hyena"],
            }
        )
    if (
        pride_strength >= 0.68
        and pride_count_signal >= 2
        and lion_hotspots >= 2
        and hotspot_overlap <= 1
        and antelope_count + zebra_count >= 24
        and lion_count < 6
    ):
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "pride_expansion_window",
                "new_target_count": species_pool["lion"],
            }
        )
    if (
        clan_cohesion >= 0.65
        and clan_count_signal >= 2
        and hyena_hotspots >= 2
        and hotspot_overlap <= 1
        and antelope_count + zebra_count >= 24
        and hyena_count < 7
    ):
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "clan_expansion_window",
                "new_target_count": species_pool["hyena"],
            }
        )
    if (
        lion_count <= 1
        and pride_strength >= 0.72
        and pride_count_signal >= 2
        and lion_hotspots >= 1
        and antelope_count + zebra_count >= 26
    ):
        species_pool["lion"] = species_pool.get("lion", 0) + 2
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "pride_recolonization_window",
                "new_target_count": species_pool["lion"],
            }
        )
    if (
        hyena_count <= 1
        and clan_cohesion >= 0.7
        and clan_count_signal >= 2
        and hyena_hotspots >= 1
        and antelope_count + zebra_count >= 26
    ):
        species_pool["hyena"] = species_pool.get("hyena", 0) + 2
        adjustments.append(
            {
                "source_species": "social_state",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "clan_recolonization_window",
                "new_target_count": species_pool["hyena"],
            }
        )
    if lion_recovery_bias >= 0.58 and lion_count <= 2 and antelope_count + zebra_count >= 20:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_trend",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "trend_recovery_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_recovery_bias >= 0.56 and hyena_count <= 2 and antelope_count + zebra_count >= 20:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_trend",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "trend_recovery_support",
                "new_target_count": species_pool["hyena"],
            }
        )
    if lion_decline_bias >= 0.62 and lion_count >= 5:
        species_pool["lion"] = lion_count - 1
        adjustments.append(
            {
                "source_species": "social_trend",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "trend_contraction",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_decline_bias >= 0.60 and hyena_count >= 6:
        species_pool["hyena"] = hyena_count - 1
        adjustments.append(
            {
                "source_species": "social_trend",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "trend_contraction",
                "new_target_count": species_pool["hyena"],
            }
        )
    if lion_expansion_phase >= 0.58 and 2 <= lion_count < 6 and antelope_count + zebra_count >= 22:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "cycle_expansion_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_expansion_phase >= 0.56 and 2 <= hyena_count < 7 and antelope_count + zebra_count >= 22:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "cycle_expansion_support",
                "new_target_count": species_pool["hyena"],
            }
        )
    if lion_contraction_phase >= 0.54 and lion_count >= 5:
        species_pool["lion"] = species_pool["lion"] - 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "cycle_contraction",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_contraction_phase >= 0.52 and hyena_count >= 6:
        species_pool["hyena"] = species_pool["hyena"] - 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "cycle_contraction",
                "new_target_count": species_pool["hyena"],
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
    if lion_hotspot_memory >= 0.34 and lion_hotspots >= 2 and antelope_count + zebra_count >= 16:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "hotspot_memory_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if hyena_hotspot_memory >= 0.34 and hyena_hotspots >= 2 and antelope_count + zebra_count >= 16:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "hotspot_memory_support",
                "new_target_count": species_pool["hyena"],
            }
        )
    if shared_hotspot_memory >= 0.34 and hotspot_overlap > 0:
        if species_pool.get("hyena", 0) >= max(2, species_pool.get("lion", 0)):
            species_pool["hyena"] = species_pool["hyena"] - 1
            adjustments.append(
                {
                    "source_species": "social_hotspot",
                    "target_species": "hyena",
                    "layer_group": "social_layer",
                    "effect": "hotspot_memory_conflict_drag",
                    "new_target_count": species_pool["hyena"],
                }
            )
        elif species_pool.get("lion", 0) >= 2:
            species_pool["lion"] = species_pool["lion"] - 1
            adjustments.append(
                {
                    "source_species": "social_hotspot",
                    "target_species": "lion",
                    "layer_group": "social_layer",
                    "effect": "hotspot_memory_conflict_drag",
                    "new_target_count": species_pool["lion"],
                }
            )
    if lion_hotspot_memory + hyena_hotspot_memory >= 0.78 and antelope_count > 16:
        species_pool["antelope"] = species_pool["antelope"] - 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "hotspot_cycle_predator_wave",
                "new_target_count": species_pool["antelope"],
            }
        )
    if herd_route_cycle >= 0.30 and antelope_count < 17:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "herd_route_cycle_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if herd_route_cycle >= 0.32 and zebra_count < 15:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "herd_route_cycle_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_surface_water_pull", 0.0) >= 0.08 and antelope_count < 18:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_resource",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_surface_water_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_condition_pull", 0.0) >= 0.06 and antelope_count < 19:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_condition_phase_pull", 0.0) >= 0.06 and antelope_count < 20:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_phase",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_phase_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_condition_pull", 0.0) >= 0.06 and antelope_count < 20:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "condition_herd_recovery",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_health_pull", 0.0) >= 0.06 and antelope_count < 19:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_health",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_health_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_health_anchor_pull", 0.0) >= 0.06 and antelope_count < 20:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_health_anchor",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_health_anchor_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_condition_anchor_pull", 0.0) >= 0.05 and antelope_count < 20:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_anchor",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_anchor_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_condition_phase_anchor_pull", 0.0) >= 0.05 and antelope_count < 20:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_phase_anchor",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_phase_anchor_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_regional_bias_pull", 0.0) >= 0.06 and antelope_count < 20:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_regional_bias",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_regional_bias_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_resource_anchor_pull", 0.0) >= 0.07 and antelope_count < 20:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_anchor",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_anchor_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_herd_anchor_prosperity_pull", 0.0) >= 0.06 and antelope_count < 21:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_anchor_prosperity",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_anchor_prosperity_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("runtime_surface_water_pull", 0.0) >= 0.08 and zebra_count < 16:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_resource",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_surface_water_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_condition_pull", 0.0) >= 0.06 and zebra_count < 17:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_condition_phase_pull", 0.0) >= 0.06 and zebra_count < 18:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_phase",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_phase_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_condition_pull", 0.0) >= 0.06 and zebra_count < 18:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "condition_herd_recovery",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_health_pull", 0.0) >= 0.06 and zebra_count < 17:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_health",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_health_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_health_anchor_pull", 0.0) >= 0.06 and zebra_count < 18:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_health_anchor",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_health_anchor_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_condition_anchor_pull", 0.0) >= 0.05 and zebra_count < 18:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_anchor",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_anchor_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_condition_phase_anchor_pull", 0.0) >= 0.05 and zebra_count < 18:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_phase_anchor",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_condition_phase_anchor_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_regional_bias_pull", 0.0) >= 0.06 and zebra_count < 18:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_regional_bias",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_regional_bias_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_resource_anchor_pull", 0.0) >= 0.07 and zebra_count < 18:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_anchor",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_anchor_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_herd_anchor_prosperity_pull", 0.0) >= 0.06 and zebra_count < 19:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_anchor_prosperity",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "runtime_herd_anchor_prosperity_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("runtime_apex_health_pull", 0.0) >= 0.06 and lion_count < 7:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_health",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_health_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_condition_pull", 0.0) >= 0.06 and lion_count < 8:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_condition_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_condition_phase_pull", 0.0) >= 0.05 and lion_count < 8:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_phase",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_condition_phase_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_condition_pull", 0.0) >= 0.04 and lion_count < 9:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition",
                "target_species": "lion",
                "layer_group": "social_layer",
                "effect": "condition_pride_recovery",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_condition_pull", 0.0) >= 0.04 and hyena_count < 8:
        species_pool["hyena"] = species_pool.get("hyena", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition",
                "target_species": "hyena",
                "layer_group": "social_layer",
                "effect": "condition_clan_recovery",
                "new_target_count": species_pool["hyena"],
            }
        )
    if scores.get("runtime_apex_health_anchor_pull", 0.0) >= 0.06 and lion_count < 8:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_health_anchor",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_health_anchor_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_condition_anchor_pull", 0.0) >= 0.05 and lion_count < 8:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_anchor",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_condition_anchor_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_condition_phase_anchor_pull", 0.0) >= 0.05 and lion_count < 8:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_condition_phase_anchor",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_condition_phase_anchor_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_regional_bias_pull", 0.0) >= 0.06 and lion_count < 8:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_regional_bias",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_regional_bias_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("runtime_apex_anchor_prosperity_pull", 0.0) >= 0.05 and lion_count < 8:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "runtime_anchor_prosperity",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "runtime_apex_anchor_prosperity_support",
                "new_target_count": species_pool["lion"],
            }
        )
    if scores.get("regional_prosperity_anchor", 0.0) >= 0.07 and antelope_count < 22:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "regional_health",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "regional_prosperity_support",
                "new_target_count": species_pool["antelope"],
            }
        )
    if scores.get("regional_stability_anchor", 0.0) >= 0.06 and zebra_count < 20:
        species_pool["zebra"] = species_pool.get("zebra", 0) + 1
        adjustments.append(
            {
                "source_species": "regional_health",
                "target_species": "zebra",
                "layer_group": "social_layer",
                "effect": "regional_stability_support",
                "new_target_count": species_pool["zebra"],
            }
        )
    if scores.get("regional_collapse_anchor", 0.0) >= 0.07 and lion_count > 3:
        species_pool["lion"] = species_pool.get("lion", 0) - 1
        adjustments.append(
            {
                "source_species": "regional_health",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "regional_collapse_drag",
                "new_target_count": species_pool["lion"],
            }
        )
    if grassland_boom_phase >= 0.45 and antelope_count < 22:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "boom_phase_herd_release",
                "new_target_count": species_pool["antelope"],
            }
        )
    if shared_hotspot_memory >= 0.42 and zebra_count > 10:
        species_pool["zebra"] = species_pool["zebra"] - 1
        adjustments.append(
            {
                "source_species": "social_hotspot",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "hotspot_cycle_overlap_drag",
                "new_target_count": species_pool["zebra"],
            }
        )
    if grassland_bust_phase >= 0.56 and zebra_count > 9:
        species_pool["zebra"] = species_pool.get("zebra", 0) - 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "zebra",
                "layer_group": "herd_layer",
                "effect": "bust_phase_herd_drag",
                "new_target_count": species_pool["zebra"],
            }
        )
    if grassland_boom_phase >= 0.48 and 2 <= lion_count < 7 and antelope_count + zebra_count >= 18:
        species_pool["lion"] = species_pool.get("lion", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "boom_phase_apex_release",
                "new_target_count": species_pool["lion"],
            }
        )
    if grassland_prosperity_phase >= 0.2 and antelope_count < 24:
        species_pool["antelope"] = species_pool.get("antelope", 0) + 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "antelope",
                "layer_group": "herd_layer",
                "effect": "prosperity_phase_herd_gain",
                "new_target_count": species_pool["antelope"],
            }
        )
    if grassland_bust_phase >= 0.58 and lion_count >= 3:
        species_pool["lion"] = species_pool.get("lion", 0) - 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "lion",
                "layer_group": "predator_layer",
                "effect": "bust_phase_apex_drag",
                "new_target_count": species_pool["lion"],
            }
        )
    if grassland_collapse_phase >= 0.2 and hyena_count >= 3:
        species_pool["hyena"] = species_pool.get("hyena", 0) - 1
        adjustments.append(
            {
                "source_species": "social_cycle",
                "target_species": "hyena",
                "layer_group": "scavenger_layer",
                "effect": "collapse_phase_scavenger_loss",
                "new_target_count": species_pool["hyena"],
            }
        )

    return adjustments


def _select_dominant_grassland_layer(
    layer_scores: Dict[str, float],
    trophic_scores: Dict[str, float],
) -> str:
    prosperity = float(trophic_scores.get("prosperity_feedback_bias", 0.0))
    collapse = float(trophic_scores.get("collapse_feedback_bias", 0.0))
    surface_water_anchor = float(trophic_scores.get("surface_water_anchor", 0.0))
    if surface_water_anchor >= 0.10:
        candidates = ("herd_layer", "browse_layer", "predator_layer")
    elif prosperity > collapse:
        candidates = ("herd_layer", "predator_layer", "browse_layer")
    elif collapse > prosperity:
        candidates = ("scavenger_layer", "social_layer", "predator_layer")
    else:
        candidates = tuple(layer_scores.keys())
    ranked = [(layer, float(layer_scores.get(layer, 0.0))) for layer in candidates]
    ranked = [entry for entry in ranked if entry[1] > 0.0]
    if not ranked:
        return ""
    return max(ranked, key=lambda item: item[1])[0]


def _is_grassland_region(region: Region) -> bool:
    if region.region_id == "temperate_grassland":
        return True
    return any(biome in {"grassland", "savanna", "shrubland", "seasonal_waterhole"} for biome in region.dominant_biomes)


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

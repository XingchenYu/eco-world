"""v4 社群长期趋势摘要。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

from src.world import Region


@dataclass
class RegionSocialTrendSummary:
    """区域级社群兴衰趋势摘要。"""

    region_id: str
    trend_scores: Dict[str, float] = field(default_factory=dict)
    phase_scores: Dict[str, float] = field(default_factory=dict)
    boom_bust_scores: Dict[str, float] = field(default_factory=dict)
    prosperity_scores: Dict[str, float] = field(default_factory=dict)
    hotspot_scores: Dict[str, float] = field(default_factory=dict)
    cycle_signals: List[str] = field(default_factory=list)
    narrative_trends: List[str] = field(default_factory=list)


def build_region_social_trend_summary(
    region: Region,
    territory_summary: Optional[object] = None,
) -> RegionSocialTrendSummary:
    """基于上轮状态和当前社群信号构建长期趋势。"""

    previous = region.relationship_state.get("social_trends", {})
    previous_scores = previous.get("trend_scores", {}) if isinstance(previous, dict) else {}
    previous_phase_scores = previous.get("phase_scores", {}) if isinstance(previous, dict) else {}
    previous_boom_bust_scores = previous.get("boom_bust_scores", {}) if isinstance(previous, dict) else {}
    previous_prosperity_scores = previous.get("prosperity_scores", {}) if isinstance(previous, dict) else {}
    previous_hotspot_scores = previous.get("hotspot_scores", {}) if isinstance(previous, dict) else {}
    runtime_signals = getattr(territory_summary, "runtime_signals", {}) or {}

    pride_strength = float(runtime_signals.get("lion_pride_strength", 0.0))
    takeover_pressure = float(runtime_signals.get("lion_takeover_pressure", 0.0))
    pride_count = int(runtime_signals.get("lion_pride_count", 0))
    lion_hotspots = int(runtime_signals.get("lion_hotspot_count", 0))

    clan_cohesion = float(runtime_signals.get("hyena_clan_cohesion", 0.0))
    clan_front_pressure = float(runtime_signals.get("hyena_clan_front_pressure", 0.0))
    clan_count = int(runtime_signals.get("hyena_clan_count", 0))
    hyena_hotspots = int(runtime_signals.get("hyena_hotspot_count", 0))
    lion_hotspot_persistence = int(runtime_signals.get("lion_hotspot_persistence", 0))
    hyena_hotspot_persistence = int(runtime_signals.get("hyena_hotspot_persistence", 0))
    shared_hotspot_persistence = int(runtime_signals.get("shared_hotspot_persistence", 0))
    lion_hotspot_shift = int(runtime_signals.get("lion_hotspot_shift", 0))
    hyena_hotspot_shift = int(runtime_signals.get("hyena_hotspot_shift", 0))
    shared_hotspot_shift = int(runtime_signals.get("shared_hotspot_shift", 0))
    herd_hotspots = int(runtime_signals.get("herd_hotspot_count", 0))
    herd_apex_overlap = int(runtime_signals.get("herd_apex_overlap", 0))
    herd_route_cycle_runtime = float(runtime_signals.get("herd_route_cycle_runtime", 0.0))
    herd_surface_water_runtime = float(runtime_signals.get("herd_surface_water_runtime", 0.0))
    surface_water_anchor = float(runtime_signals.get("surface_water_anchor", 0.0))
    vulture_hotspots = int(runtime_signals.get("vulture_hotspot_count", 0))
    vulture_carrion_overlap = int(runtime_signals.get("vulture_carrion_overlap", 0))
    aerial_carrion_cycle_runtime = float(runtime_signals.get("aerial_carrion_cycle_runtime", 0.0))
    aerial_carcass_runtime = float(runtime_signals.get("aerial_carcass_runtime", 0.0))
    carcass_anchor = float(runtime_signals.get("carcass_anchor", 0.0))

    overlap = int(runtime_signals.get("shared_hotspot_overlap", 0))

    def carry(key: str) -> float:
        return float(previous_scores.get(key, 0.0))

    def carry_phase(key: str) -> float:
        return float(previous_phase_scores.get(key, 0.0))

    def carry_boom_bust(key: str) -> float:
        return float(previous_boom_bust_scores.get(key, 0.0))

    def carry_prosperity(key: str) -> float:
        return float(previous_prosperity_scores.get(key, 0.0))

    def carry_hotspot(key: str) -> float:
        return float(previous_hotspot_scores.get(key, 0.0))

    lion_recovery = min(
        1.0,
        carry("lion_recovery_bias") * 0.62
        + pride_strength * 0.46
        + max(0, pride_count - 1) * 0.08
        + lion_hotspots * 0.05
        - overlap * 0.05,
    )
    lion_decline = min(
        1.0,
        carry("lion_decline_bias") * 0.62
        + takeover_pressure * 0.42
        + overlap * 0.08
        - pride_strength * 0.10,
    )
    hyena_recovery = min(
        1.0,
        carry("hyena_recovery_bias") * 0.62
        + clan_cohesion * 0.44
        + max(0, clan_count - 1) * 0.07
        + hyena_hotspots * 0.05
        - overlap * 0.04,
    )
    hyena_decline = min(
        1.0,
        carry("hyena_decline_bias") * 0.62
        + clan_front_pressure * 0.36
        + overlap * 0.07
        - clan_cohesion * 0.10,
    )

    trend_scores = {
        "lion_recovery_bias": round(max(0.0, lion_recovery), 3),
        "lion_decline_bias": round(max(0.0, lion_decline), 3),
        "hyena_recovery_bias": round(max(0.0, hyena_recovery), 3),
        "hyena_decline_bias": round(max(0.0, hyena_decline), 3),
    }

    phase_scores = {
        "lion_expansion_phase": round(
            max(0.0, min(1.0, carry_phase("lion_expansion_phase") * 0.64 + lion_recovery * 0.42 - lion_decline * 0.18)),
            3,
        ),
        "lion_contraction_phase": round(
            max(0.0, min(1.0, carry_phase("lion_contraction_phase") * 0.64 + lion_decline * 0.44 - lion_recovery * 0.14)),
            3,
        ),
        "hyena_expansion_phase": round(
            max(0.0, min(1.0, carry_phase("hyena_expansion_phase") * 0.64 + hyena_recovery * 0.40 - hyena_decline * 0.17)),
            3,
        ),
        "hyena_contraction_phase": round(
            max(0.0, min(1.0, carry_phase("hyena_contraction_phase") * 0.64 + hyena_decline * 0.42 - hyena_recovery * 0.14)),
            3,
        ),
    }

    herd_route_cycle_signal = max(
        0.0,
        min(
            1.0,
            carry_phase("herd_route_cycle") * 0.66
            + (carry_hotspot("herd_hotspot_memory") * 0.68 + herd_hotspots * 0.08 + herd_apex_overlap * 0.04) * 0.32
            + (carry_hotspot("herd_apex_memory") * 0.68 + herd_apex_overlap * 0.10) * 0.18
            + herd_route_cycle_runtime * 0.08
            + herd_surface_water_runtime * 0.06
            + surface_water_anchor * 0.06
            - (carry_hotspot("shared_hotspot_memory") * 0.66 + shared_hotspot_persistence * 0.20 + overlap * 0.08 - shared_hotspot_shift * 0.06) * 0.08,
        ),
    )
    aerial_carrion_cycle_signal = max(
        0.0,
        min(
            1.0,
            carry_phase("aerial_carrion_cycle") * 0.66
            + (carry_hotspot("vulture_hotspot_memory") * 0.68 + vulture_hotspots * 0.08 + vulture_carrion_overlap * 0.05) * 0.30
            + (carry_hotspot("vulture_carrion_memory") * 0.68 + vulture_carrion_overlap * 0.10) * 0.22
            + aerial_carrion_cycle_runtime * 0.08
            + aerial_carcass_runtime * 0.06
            + carcass_anchor * 0.06
            - (carry_hotspot("shared_hotspot_memory") * 0.66 + shared_hotspot_persistence * 0.20 + overlap * 0.08 - shared_hotspot_shift * 0.06) * 0.06,
        ),
    )

    boom_bust_scores = {
        "grassland_boom_phase": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_boom_bust("grassland_boom_phase") * 0.66
                    + phase_scores["lion_expansion_phase"] * 0.24
                    + phase_scores["hyena_expansion_phase"] * 0.20
                    + herd_route_cycle_signal * 0.10
                    + aerial_carrion_cycle_signal * 0.08
                    + surface_water_anchor * 0.06
                    + carcass_anchor * 0.05
                    + max(0.0, pride_strength - takeover_pressure) * 0.10
                    + max(0.0, clan_cohesion - clan_front_pressure) * 0.08
                    + max(0.0, lion_hotspot_persistence - lion_hotspot_shift) * 0.03
                    + max(0.0, hyena_hotspot_persistence - hyena_hotspot_shift) * 0.03
                    - max(0.0, shared_hotspot_shift - shared_hotspot_persistence) * 0.04,
                ),
            ),
            3,
        ),
        "grassland_bust_phase": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_boom_bust("grassland_bust_phase") * 0.66
                    + phase_scores["lion_contraction_phase"] * 0.22
                    + phase_scores["hyena_contraction_phase"] * 0.18
                    + max(0.0, takeover_pressure - pride_strength) * 0.10
                    + max(0.0, clan_front_pressure - clan_cohesion) * 0.08
                    + shared_hotspot_shift * 0.05
                    + shared_hotspot_persistence * 0.04
                    - surface_water_anchor * 0.04
                    - carcass_anchor * 0.03
                    - herd_route_cycle_signal * 0.06
                    - aerial_carrion_cycle_signal * 0.05
                    - max(0.0, lion_hotspot_persistence - lion_hotspot_shift) * 0.02
                    - max(0.0, hyena_hotspot_persistence - hyena_hotspot_shift) * 0.02,
                ),
            ),
            3,
        ),
    }

    prosperity_scores = {
        "grassland_prosperity_phase": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_prosperity("grassland_prosperity_phase") * 0.7
                    + boom_bust_scores["grassland_boom_phase"] * 0.26
                    + herd_route_cycle_signal * 0.10
                    + aerial_carrion_cycle_signal * 0.08
                    + surface_water_anchor * 0.06
                    + carcass_anchor * 0.05
                    + max(0.0, lion_hotspot_persistence - lion_hotspot_shift) * 0.03
                    + max(0.0, hyena_hotspot_persistence - hyena_hotspot_shift) * 0.03
                    - boom_bust_scores["grassland_bust_phase"] * 0.12,
                ),
            ),
            3,
        ),
        "grassland_collapse_phase": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_prosperity("grassland_collapse_phase") * 0.7
                    + boom_bust_scores["grassland_bust_phase"] * 0.28
                    + shared_hotspot_shift * 0.05
                    + overlap * 0.03
                    - surface_water_anchor * 0.03
                    - carcass_anchor * 0.02
                    - herd_route_cycle_signal * 0.05
                    - aerial_carrion_cycle_signal * 0.04
                    - boom_bust_scores["grassland_boom_phase"] * 0.10,
                ),
            ),
            3,
        ),
    }

    prosperity_phase_signal = prosperity_scores["grassland_prosperity_phase"]
    collapse_phase_signal = prosperity_scores["grassland_collapse_phase"]

    hotspot_scores = {
        "lion_hotspot_memory": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_hotspot("lion_hotspot_memory") * 0.66
                    + lion_hotspot_persistence * 0.18
                    + lion_hotspots * 0.06
                    - lion_hotspot_shift * 0.05,
                ),
            ),
            3,
        ),
        "hyena_hotspot_memory": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_hotspot("hyena_hotspot_memory") * 0.66
                    + hyena_hotspot_persistence * 0.16
                    + hyena_hotspots * 0.06
                    - hyena_hotspot_shift * 0.05,
                ),
            ),
            3,
        ),
        "shared_hotspot_memory": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_hotspot("shared_hotspot_memory") * 0.66
                    + shared_hotspot_persistence * 0.20
                    + overlap * 0.08
                    - shared_hotspot_shift * 0.06,
                ),
            ),
            3,
        ),
        "herd_hotspot_memory": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_hotspot("herd_hotspot_memory") * 0.68
                    + herd_hotspots * 0.08
                    + herd_apex_overlap * 0.04
                    + herd_route_cycle_runtime * 0.06
                    + herd_surface_water_runtime * 0.05
                    + surface_water_anchor * 0.06
                ),
            ),
            3,
        ),
        "herd_apex_memory": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_hotspot("herd_apex_memory") * 0.68
                    + herd_apex_overlap * 0.10
                    + herd_route_cycle_runtime * 0.04
                    + herd_surface_water_runtime * 0.03
                    + surface_water_anchor * 0.04
                ),
            ),
            3,
        ),
        "vulture_hotspot_memory": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_hotspot("vulture_hotspot_memory") * 0.68
                    + vulture_hotspots * 0.08
                    + vulture_carrion_overlap * 0.05
                    + aerial_carrion_cycle_runtime * 0.06
                    + aerial_carcass_runtime * 0.05
                    + carcass_anchor * 0.06
                ),
            ),
            3,
        ),
        "vulture_carrion_memory": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_hotspot("vulture_carrion_memory") * 0.68
                    + vulture_carrion_overlap * 0.10
                    + aerial_carrion_cycle_runtime * 0.04
                    + aerial_carcass_runtime * 0.03
                    + carcass_anchor * 0.05
                ),
            ),
            3,
        ),
    }

    prosperity_push = prosperity_scores["grassland_prosperity_phase"]
    collapse_drag = prosperity_scores["grassland_collapse_phase"]
    hotspot_scores["herd_hotspot_memory"] = round(
        max(
            0.0,
            min(
                1.0,
                hotspot_scores["herd_hotspot_memory"]
                + prosperity_push * 0.08
                - collapse_drag * 0.04,
            ),
        ),
        3,
    )
    hotspot_scores["herd_apex_memory"] = round(
        max(
            0.0,
            min(
                1.0,
                hotspot_scores["herd_apex_memory"]
                + prosperity_push * 0.05
                - collapse_drag * 0.03,
            ),
        ),
        3,
    )
    hotspot_scores["vulture_hotspot_memory"] = round(
        max(
            0.0,
            min(
                1.0,
                hotspot_scores["vulture_hotspot_memory"]
                + prosperity_push * 0.07
                - collapse_drag * 0.04,
            ),
        ),
        3,
    )
    hotspot_scores["vulture_carrion_memory"] = round(
        max(
            0.0,
            min(
                1.0,
                hotspot_scores["vulture_carrion_memory"]
                + prosperity_push * 0.06
                - collapse_drag * 0.03,
            ),
        ),
        3,
    )

    phase_scores["herd_route_cycle"] = round(
        max(
            0.0,
            min(
                1.0,
                herd_route_cycle_signal
                + prosperity_phase_signal * 0.06
                - collapse_phase_signal * 0.04,
            ),
        ),
        3,
    )
    phase_scores["aerial_carrion_cycle"] = round(
        max(
            0.0,
            min(
                1.0,
                aerial_carrion_cycle_signal
                + prosperity_phase_signal * 0.05
                - collapse_phase_signal * 0.03,
            ),
        ),
        3,
    )

    cycle_signals: List[str] = []
    narrative_trends: List[str] = []

    if phase_scores["lion_expansion_phase"] >= 0.55:
        cycle_signals.append("lion_expansion_cycle")
        narrative_trends.append("狮群稳定度和热点延续性正在推动新的扩张周期。")
    if phase_scores["lion_contraction_phase"] >= 0.52:
        cycle_signals.append("lion_contraction_cycle")
        narrative_trends.append("狮群接管压力与热点重叠正在积累收缩风险。")
    if pride_count <= 1 and trend_scores["lion_recovery_bias"] >= 0.62:
        cycle_signals.append("lion_recolonization_memory")
        narrative_trends.append("狮群虽处低谷，但保留了足以重占热点区的社群记忆。")

    if phase_scores["hyena_expansion_phase"] >= 0.53:
        cycle_signals.append("hyena_expansion_cycle")
        narrative_trends.append("鬣狗 clan 的凝聚度和活动热点支撑着稳定扩张。")
    if phase_scores["hyena_contraction_phase"] >= 0.50:
        cycle_signals.append("hyena_contraction_cycle")
        narrative_trends.append("鬣狗 clan 前沿压力和热点拥挤正在推高收缩风险。")
    if clan_count <= 1 and trend_scores["hyena_recovery_bias"] >= 0.60:
        cycle_signals.append("hyena_recolonization_memory")
        narrative_trends.append("鬣狗 clan 即便处于低谷，仍保留了重占尸体通道的趋势记忆。")
    if hotspot_scores["lion_hotspot_memory"] >= 0.38:
        cycle_signals.append("lion_hotspot_memory")
        narrative_trends.append("狮群热点保持了跨周期延续性。")
    if hotspot_scores["hyena_hotspot_memory"] >= 0.36:
        cycle_signals.append("hyena_hotspot_memory")
        narrative_trends.append("鬣狗 clan 热点正在稳定延续。")
    if hotspot_scores["shared_hotspot_memory"] >= 0.34:
        cycle_signals.append("shared_hotspot_memory")
        narrative_trends.append("狮群与鬣狗热点重叠正在形成长期通道记忆。")
    if hotspot_scores["herd_hotspot_memory"] >= 0.30:
        cycle_signals.append("herd_hotspot_memory")
        narrative_trends.append("食草群通道热点正在形成跨周期迁移记忆。")
    if hotspot_scores["vulture_hotspot_memory"] >= 0.28:
        cycle_signals.append("vulture_hotspot_memory")
        narrative_trends.append("空中清道夫热点正在形成跨周期追踪记忆。")
    if phase_scores["herd_route_cycle"] >= 0.16:
        cycle_signals.append("herd_route_cycle")
        narrative_trends.append("食草群通道记忆已经积累成更明确的 herd-route 周期。")
    if phase_scores["aerial_carrion_cycle"] >= 0.12:
        cycle_signals.append("aerial_carrion_cycle")
        narrative_trends.append("空中尸体追踪记忆已经积累成更明确的 aerial-carrion 周期。")
    if surface_water_anchor >= 0.45:
        cycle_signals.append("surface_water_anchor")
        narrative_trends.append("稳定水源锚点正在持续加固食草群的长期迁移记忆。")
    if herd_surface_water_runtime >= 0.45:
        cycle_signals.append("herd_surface_water_runtime")
        narrative_trends.append("运行中的食草群水源依赖正在把草原 herd 通道固化成更稳定的长期节律。")
    if carcass_anchor >= 0.40:
        cycle_signals.append("carcass_anchor")
        narrative_trends.append("稳定尸体资源锚点正在持续加固空中清道夫的长期追踪记忆。")
    if aerial_carcass_runtime >= 0.40:
        cycle_signals.append("aerial_carcass_runtime")
        narrative_trends.append("运行中的空中尸体追踪正在把清道夫通道固化成更稳定的长期节律。")
    if hotspot_scores["lion_hotspot_memory"] + hotspot_scores["hyena_hotspot_memory"] >= 0.78:
        cycle_signals.append("apex_hotspot_wave")
        narrative_trends.append("顶层捕食者热点记忆正在放大草原多周期兴衰波动。")
    if hotspot_scores["shared_hotspot_memory"] >= 0.42:
        cycle_signals.append("shared_hotspot_churn")
        narrative_trends.append("共享热点记忆正在把草原热点冲突转化为更明显的周期性震荡。")
    if hotspot_scores["herd_hotspot_memory"] + hotspot_scores["herd_apex_memory"] >= 0.44:
        cycle_signals.append("herd_route_memory")
        narrative_trends.append("食草群热点记忆正在把水源与草场重新织成更稳定的 herd 通道。")
    if hotspot_scores["vulture_hotspot_memory"] + hotspot_scores["vulture_carrion_memory"] >= 0.40:
        cycle_signals.append("aerial_carrion_memory")
        narrative_trends.append("空中尸体通道记忆正在强化秃鹫对击杀走廊的长期跟踪。")
    if boom_bust_scores["grassland_boom_phase"] >= 0.45:
        cycle_signals.append("grassland_boom_phase")
        narrative_trends.append("草原社群热点与扩张周期正在共同推高长期繁荣相位。")
    if boom_bust_scores["grassland_bust_phase"] >= 0.54:
        cycle_signals.append("grassland_bust_phase")
        narrative_trends.append("热点重叠与收缩压力正在把草原拖入更明显的衰退相位。")
    if prosperity_scores["grassland_prosperity_phase"] >= 0.25:
        cycle_signals.append("grassland_prosperity_phase")
        narrative_trends.append("草原顶层社群与热点布局已经累积成更长期的繁荣期。")
    if prosperity_scores["grassland_collapse_phase"] >= 0.46:
        cycle_signals.append("grassland_collapse_phase")
        narrative_trends.append("草原热点冲突和收缩压力正在累积成区域级衰退期。")
    if surface_water_anchor + carcass_anchor >= 0.90:
        cycle_signals.append("resource_anchor_prosperity")
        narrative_trends.append("稳定水源和尸体资源锚点正在共同抬升草原长期繁荣相位。")

    return RegionSocialTrendSummary(
        region_id=region.region_id,
        trend_scores=trend_scores,
        phase_scores=phase_scores,
        boom_bust_scores=boom_bust_scores,
        prosperity_scores=prosperity_scores,
        hotspot_scores=hotspot_scores,
        cycle_signals=cycle_signals,
        narrative_trends=narrative_trends,
    )


def apply_region_social_trend_feedback(
    region: Region,
    social_trends: RegionSocialTrendSummary,
    feedback_scale: float = 0.04,
) -> None:
    """将社群长期趋势轻量回灌到区域状态。"""

    scores = social_trends.trend_scores
    phases = social_trends.phase_scores
    _adjust(region.health_state, "resilience", scores.get("lion_recovery_bias", 0.0) * 0.20, feedback_scale)
    _adjust(region.health_state, "resilience", scores.get("hyena_recovery_bias", 0.0) * 0.16, feedback_scale)
    _adjust(region.health_state, "resilience", phases.get("lion_expansion_phase", 0.0) * 0.12, feedback_scale)
    _adjust(region.health_state, "resilience", phases.get("hyena_expansion_phase", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "resilience", phases.get("herd_route_cycle", 0.0) * 0.08, feedback_scale)
    _adjust(region.resource_state, "surface_water", phases.get("herd_route_cycle", 0.0) * 0.08, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", phases.get("aerial_carrion_cycle", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "fragmentation", scores.get("lion_decline_bias", 0.0) * 0.12, feedback_scale)
    _adjust(region.health_state, "fragmentation", phases.get("lion_contraction_phase", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "fragmentation", phases.get("hyena_contraction_phase", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "biodiversity", social_trends.boom_bust_scores.get("grassland_boom_phase", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "fragmentation", social_trends.boom_bust_scores.get("grassland_bust_phase", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "resilience", social_trends.prosperity_scores.get("grassland_prosperity_phase", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "fragmentation", social_trends.prosperity_scores.get("grassland_collapse_phase", 0.0) * 0.12, feedback_scale)
    _adjust(region.health_state, "resilience", social_trends.hotspot_scores.get("lion_hotspot_memory", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "resilience", social_trends.hotspot_scores.get("hyena_hotspot_memory", 0.0) * 0.09, feedback_scale)
    _adjust(region.health_state, "resilience", social_trends.hotspot_scores.get("herd_hotspot_memory", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "biodiversity", social_trends.hotspot_scores.get("vulture_hotspot_memory", 0.0) * 0.07, feedback_scale)
    _adjust(region.hazard_state, "territorial_conflict", social_trends.hotspot_scores.get("shared_hotspot_memory", 0.0) * 0.10, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("lion_recovery_bias", 0.0) * 0.12, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("hyena_recovery_bias", 0.0) * 0.10, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", social_trends.hotspot_scores.get("vulture_carrion_memory", 0.0) * 0.06, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", phases.get("aerial_carrion_cycle", 0.0) * 0.05, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("hyena_recovery_bias", 0.0) * 0.08, feedback_scale)
    _adjust(region.resource_state, "surface_water", social_trends.hotspot_scores.get("herd_apex_memory", 0.0) * 0.05, feedback_scale)


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

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

    overlap = int(runtime_signals.get("shared_hotspot_overlap", 0))

    def carry(key: str) -> float:
        return float(previous_scores.get(key, 0.0))

    def carry_phase(key: str) -> float:
        return float(previous_phase_scores.get(key, 0.0))

    def carry_boom_bust(key: str) -> float:
        return float(previous_boom_bust_scores.get(key, 0.0))

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

    boom_bust_scores = {
        "grassland_boom_phase": round(
            max(
                0.0,
                min(
                    1.0,
                    carry_boom_bust("grassland_boom_phase") * 0.66
                    + phase_scores["lion_expansion_phase"] * 0.24
                    + phase_scores["hyena_expansion_phase"] * 0.20
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
                    - max(0.0, lion_hotspot_persistence - lion_hotspot_shift) * 0.02
                    - max(0.0, hyena_hotspot_persistence - hyena_hotspot_shift) * 0.02,
                ),
            ),
            3,
        ),
    }

    hotspot_scores = {
        "lion_hotspot_memory": round(
            max(0.0, min(1.0, lion_hotspot_persistence * 0.18 + lion_hotspots * 0.06 - lion_hotspot_shift * 0.05)),
            3,
        ),
        "hyena_hotspot_memory": round(
            max(0.0, min(1.0, hyena_hotspot_persistence * 0.16 + hyena_hotspots * 0.06 - hyena_hotspot_shift * 0.05)),
            3,
        ),
        "shared_hotspot_memory": round(
            max(0.0, min(1.0, shared_hotspot_persistence * 0.20 + overlap * 0.08 - shared_hotspot_shift * 0.06)),
            3,
        ),
    }

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
    if hotspot_scores["lion_hotspot_memory"] + hotspot_scores["hyena_hotspot_memory"] >= 0.78:
        cycle_signals.append("apex_hotspot_wave")
        narrative_trends.append("顶层捕食者热点记忆正在放大草原多周期兴衰波动。")
    if hotspot_scores["shared_hotspot_memory"] >= 0.42:
        cycle_signals.append("shared_hotspot_churn")
        narrative_trends.append("共享热点记忆正在把草原热点冲突转化为更明显的周期性震荡。")
    if boom_bust_scores["grassland_boom_phase"] >= 0.45:
        cycle_signals.append("grassland_boom_phase")
        narrative_trends.append("草原社群热点与扩张周期正在共同推高长期繁荣相位。")
    if boom_bust_scores["grassland_bust_phase"] >= 0.54:
        cycle_signals.append("grassland_bust_phase")
        narrative_trends.append("热点重叠与收缩压力正在把草原拖入更明显的衰退相位。")

    return RegionSocialTrendSummary(
        region_id=region.region_id,
        trend_scores=trend_scores,
        phase_scores=phase_scores,
        boom_bust_scores=boom_bust_scores,
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
    _adjust(region.health_state, "fragmentation", scores.get("lion_decline_bias", 0.0) * 0.12, feedback_scale)
    _adjust(region.health_state, "fragmentation", phases.get("lion_contraction_phase", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "fragmentation", phases.get("hyena_contraction_phase", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "biodiversity", social_trends.boom_bust_scores.get("grassland_boom_phase", 0.0) * 0.08, feedback_scale)
    _adjust(region.health_state, "fragmentation", social_trends.boom_bust_scores.get("grassland_bust_phase", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "resilience", social_trends.hotspot_scores.get("lion_hotspot_memory", 0.0) * 0.10, feedback_scale)
    _adjust(region.health_state, "resilience", social_trends.hotspot_scores.get("hyena_hotspot_memory", 0.0) * 0.09, feedback_scale)
    _adjust(region.hazard_state, "territorial_conflict", social_trends.hotspot_scores.get("shared_hotspot_memory", 0.0) * 0.10, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("lion_recovery_bias", 0.0) * 0.12, feedback_scale)
    _adjust(region.hazard_state, "predation_pressure", scores.get("hyena_recovery_bias", 0.0) * 0.10, feedback_scale)
    _adjust(region.resource_state, "carcass_availability", scores.get("hyena_recovery_bias", 0.0) * 0.08, feedback_scale)


def _adjust(state: Dict[str, float], key: str, raw_delta: float, feedback_scale: float) -> None:
    if not raw_delta:
        return
    current = state.get(key, 0.0)
    state[key] = round(max(0.0, min(1.0, current + raw_delta * feedback_scale)), 4)

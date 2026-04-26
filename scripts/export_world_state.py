"""导出 Godot 世界界面所需的 JSON 状态。"""

from __future__ import annotations

import argparse
import json
from dataclasses import replace
from pathlib import Path
from typing import Any

from src.sim.world_simulation import build_default_world_simulation
from src.ui import build_world_ui_payload


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export EcoWorld v4 world state for Godot UI")
    parser.add_argument("--ticks", type=int, default=12, help="Ticks to advance before exporting")
    parser.add_argument("--active-region", type=str, default=None, help="Optional active region id")
    parser.add_argument(
        "--output",
        type=str,
        default="godot/data/world_state.json",
        help="Output JSON path",
    )
    parser.add_argument(
        "--intent",
        type=str,
        default="godot/data/world_strategy_intent.json",
        help="Optional Godot player strategy intent JSON path",
    )
    parser.add_argument(
        "--reports",
        type=str,
        default="godot/data/expedition_reports.json",
        help="Optional Godot expedition reports JSON path",
    )
    parser.add_argument("--ignore-intent", action="store_true", help="Ignore any saved Godot strategy intent")
    parser.add_argument("--ignore-reports", action="store_true", help="Ignore any saved Godot expedition reports")
    parser.add_argument("--pretty", action="store_true", help="Write indented JSON")
    return parser.parse_args()


def _load_strategy_intent(path: str | None) -> dict[str, Any]:
    if not path:
        return {}
    intent_path = Path(path)
    if not intent_path.exists():
        return {}
    try:
        with intent_path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(payload, dict):
        return {}
    return payload


def _load_expedition_reports(path: str | None) -> dict[str, Any]:
    if not path:
        return {}
    report_path = Path(path)
    if not report_path.exists():
        return {}
    try:
        with report_path.open(encoding="utf-8") as handle:
            payload = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(payload, dict):
        return {}
    return payload


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


def _top_key(mapping: dict[str, Any]) -> str:
    if not mapping:
        return ""
    return max(mapping, key=lambda key: float(mapping.get(key, 0.0)))


def _report_risk_value(label: str) -> float:
    return {
        "低": 0.18,
        "中": 0.42,
        "高": 0.68,
        "极高": 0.88,
    }.get(label, 0.32)


def _preferred_resource_key(region, channel: str) -> str:
    resource_keys_by_channel = {
        "水源": ["freshwater", "surface_water", "open_water", "river_nutrients", "tidal_exchange"],
        "迁徙": ["grazing_biomass", "open_visibility", "browse_cover", "dung_cycle"],
        "压迫": ["open_visibility", "nesting_cover", "canopy_cover", "understory"],
        "腐食": ["carcass_availability", "deadwood", "plankton_pulse"],
        "栖地": ["canopy_cover", "nesting_cover", "understory", "nursery_habitat", "reef_complexity"],
    }
    for key in resource_keys_by_channel.get(channel, []):
        if key in region.resource_state:
            return key
    return _top_key(region.resource_state)


def _strengthen_corridor(world, region_id: str, target_region_id: str, forward_delta: float, reverse_delta: float) -> bool:
    if not region_id or not target_region_id:
        return False
    region = world.world_map.get_region(region_id)
    target_region = world.world_map.get_region(target_region_id)
    if region is None or target_region is None:
        return False
    strengthened = False
    for index, connector in enumerate(region.connectors):
        if connector.target_region_id == target_region_id:
            region.connectors[index] = replace(connector, strength=round(_clamp01(connector.strength + forward_delta), 4))
            strengthened = True
            break
    for index, connector in enumerate(target_region.connectors):
        if connector.target_region_id == region_id:
            target_region.connectors[index] = replace(connector, strength=round(_clamp01(connector.strength + reverse_delta), 4))
            strengthened = True
            break
    return strengthened


def _apply_expedition_reports(world, reports: dict[str, Any]) -> dict[str, Any]:
    applied: dict[str, Any] = {}
    for region_id, report_value in reports.items():
        if str(region_id).startswith("_") or not isinstance(report_value, dict):
            continue
        region = world.world_map.get_region(str(region_id))
        if region is None:
            continue
        report = report_value
        intel = max(0, int(report.get("cumulative_intel", report.get("intel", 0))))
        archive_progress = max(0, int(report.get("archive_progress", 0)))
        visit_count = max(0, int(report.get("visit_count", 0)))
        risk_value = _report_risk_value(str(report.get("risk", "中")))
        top_channel = str(report.get("dominant_intel_channel", report.get("top_intel_channel", "栖地")))
        world_task_action = str(report.get("world_task_action", ""))
        world_task_reason = str(report.get("world_task_reason", ""))
        world_task_completed = bool(report.get("world_task_completed", False))
        target_region_id = str(report.get("world_task_target_region_id", report.get("target_region_id", "")))
        resource_key = _preferred_resource_key(region, top_channel)
        hazard_key = _top_key(region.hazard_state)
        task_bonus = 1.18 if world_task_completed and world_task_action in ["调查", "修复", "通道"] else 1.0

        coverage = _clamp01(0.18 + archive_progress * 0.045 + intel * 0.012 * task_bonus + visit_count * 0.025)
        if world_task_action == "调查" and world_task_completed:
            coverage = _clamp01(coverage + 0.06)
        region.ecological_pressures["survey_coverage"] = max(
            float(region.ecological_pressures.get("survey_coverage", 0.0)),
            round(coverage, 4),
            )
        if resource_key:
            resource_gain = min(0.09, intel * 0.006 + archive_progress * 0.003)
            if world_task_action == "调查" and world_task_completed:
                resource_gain = min(0.11, resource_gain + 0.018)
            region.resource_state[resource_key] = round(
                _clamp01(float(region.resource_state.get(resource_key, 0.0)) + resource_gain),
                4,
            )
        if hazard_key:
            mitigation = min(0.07, intel * 0.004 + archive_progress * 0.004)
            if world_task_action == "修复" and world_task_completed:
                mitigation = min(0.12, mitigation + 0.04)
            pressure_floor = 0.02 if risk_value < 0.60 else 0.06
            region.hazard_state[hazard_key] = round(max(pressure_floor, _clamp01(float(region.hazard_state.get(hazard_key, 0.0)) - mitigation)), 4)
        corridor_strengthened = False
        if world_task_action == "通道" and world_task_completed:
            corridor_strengthened = _strengthen_corridor(world, str(region_id), target_region_id, 0.035, 0.02)
        region.health_state["biodiversity"] = round(
            _clamp01(float(region.health_state.get("biodiversity", 0.0)) + min(0.045, intel * 0.004)),
            4,
        )
        resilience_gain = min(0.035, archive_progress * 0.004 + visit_count * 0.003)
        if world_task_action == "修复" and world_task_completed:
            resilience_gain = min(0.06, resilience_gain + 0.015)
        elif world_task_action == "通道" and corridor_strengthened:
            resilience_gain = min(0.05, resilience_gain + 0.01)
        region.health_state["resilience"] = round(
            _clamp01(float(region.health_state.get("resilience", 0.0)) + resilience_gain),
            4,
        )
        region.append_adjustments(
            [
                {
                    "source": "expedition_report",
                    "label": "玩家撤离报告回灌",
                    "intel": intel,
                    "archive_progress": archive_progress,
                    "channel": top_channel,
                    "world_task_action": world_task_action,
                    "world_task_reason": world_task_reason,
                    "world_task_completed": world_task_completed,
                    "resource_key": resource_key,
                    "hazard_key": hazard_key,
                    "target_region_id": target_region_id,
                    "corridor_strengthened": corridor_strengthened,
                }
            ]
        )
        applied[str(region_id)] = {
            "region_id": str(region_id),
            "region_name": region.name,
            "intel": intel,
            "archive_progress": archive_progress,
            "archive_tier": str(report.get("archive_tier", "初勘档案")),
            "risk": str(report.get("risk", "中")),
            "top_intel_channel": top_channel,
            "world_task_action": world_task_action,
            "world_task_reason": world_task_reason,
            "world_task_completed": world_task_completed,
            "resource_key": resource_key,
            "hazard_key": hazard_key,
            "target_region_id": target_region_id,
            "corridor_strengthened": corridor_strengthened,
            "summary": str(report.get("summary", "玩家撤离报告已回灌。")),
        }
    return applied


def _apply_strategy_intent(world, intent: dict[str, Any]) -> dict[str, Any]:
    region_id = str(intent.get("region_id", ""))
    action_key = str(intent.get("action_key", "survey"))
    action_name = str(intent.get("action", "调查"))
    if not region_id or world.world_map.get_region(region_id) is None:
        return {}

    region = world.world_map.get_region(region_id)
    target_region_id = str(intent.get("target_region_id", ""))
    applied: dict[str, Any] = {
        "region_id": region_id,
        "region_name": region.name,
        "action": action_name,
        "action_key": action_key,
        "target_region_id": target_region_id,
        "summary": "",
    }

    if action_key == "restore":
        resource_key = _top_key(region.resource_state)
        hazard_key = _top_key(region.hazard_state)
        if resource_key:
            region.resource_state[resource_key] = round(_clamp01(float(region.resource_state[resource_key]) + 0.05), 4)
        if hazard_key:
            region.hazard_state[hazard_key] = round(_clamp01(float(region.hazard_state[hazard_key]) - 0.08), 4)
        region.health_state["resilience"] = round(_clamp01(float(region.health_state.get("resilience", 0.0)) + 0.025), 4)
        region.append_adjustments(
            [
                {
                    "source": "player_strategy",
                    "action": "restore",
                    "label": "玩家执行生态修复",
                    "resource_key": resource_key,
                    "hazard_key": hazard_key,
                }
            ]
        )
        applied["summary"] = f"已应用修复：提升 {resource_key or '关键资源'}，压低 {hazard_key or '最高风险'}。"
    elif action_key == "corridor":
        strengthened = _strengthen_corridor(world, region_id, target_region_id, 0.04, 0.02)
        region.append_adjustments(
            [
                {
                    "source": "player_strategy",
                    "action": "corridor",
                    "label": "玩家加固生态通道",
                    "target_region_id": target_region_id,
                    "strengthened": strengthened,
                }
            ]
        )
        applied["summary"] = "已应用通道策略：强化相邻区域连接。" if strengthened else "已记录通道策略：等待有效目标区域。"
    else:
        region.ecological_pressures["survey_coverage"] = round(
            _clamp01(float(region.ecological_pressures.get("survey_coverage", 0.0)) + 0.06),
            4,
        )
        region.append_adjustments(
            [
                {
                    "source": "player_strategy",
                    "action": "survey",
                    "label": "玩家执行生态调查",
                    "survey_coverage": region.ecological_pressures["survey_coverage"],
                }
            ]
        )
        applied["summary"] = "已应用调查：提高本区调查覆盖度。"
    return applied


def _strategy_tick_bonus(intent: dict[str, Any]) -> int:
    return {
        "survey": 2,
        "restore": 4,
        "corridor": 3,
    }.get(str(intent.get("action_key", "survey")), 0)


def _attach_strategy_to_payload(payload: dict[str, Any], applied: dict[str, Any], intent: dict[str, Any]) -> None:
    if not applied:
        return
    payload["player_intent"] = {
        "requested": intent,
        "applied": applied,
    }
    payload.setdefault("ui_meta", {})["player_intent"] = applied
    region_id = str(applied.get("region_id", ""))
    if region_id:
        payload.setdefault("region_details", {}).setdefault(region_id, {})["player_intent"] = applied
    target_region_id = str(applied.get("target_region_id", ""))
    if target_region_id and target_region_id != region_id:
        payload.setdefault("region_details", {}).setdefault(target_region_id, {})["incoming_player_intent"] = applied
    payload.setdefault("world_bulletin", []).insert(
        0,
        {
            "title": "玩家策略已接入后端",
            "body": applied.get("summary", "已读取玩家策略。"),
            "region_id": applied.get("region_id", ""),
            "action": applied.get("action", ""),
        },
    )


def _attach_expedition_reports_to_payload(payload: dict[str, Any], applied_reports: dict[str, Any], reports: dict[str, Any]) -> None:
    if not applied_reports:
        return
    payload["expedition_reports"] = {
        "applied": applied_reports,
        "last": reports.get("_last", {}),
    }
    payload.setdefault("ui_meta", {})["expedition_reports"] = {
        "applied_count": len(applied_reports),
        "last": reports.get("_last", {}),
    }
    for region_id, applied in applied_reports.items():
        payload.setdefault("region_details", {}).setdefault(region_id, {})["expedition_report"] = applied
    last_report = reports.get("_last", {})
    if isinstance(last_report, dict) and last_report:
        payload.setdefault("world_bulletin", []).insert(
            0,
            {
                "title": "撤离报告已回灌后端",
                "body": str(last_report.get("summary", "玩家撤离报告已接入生态系统。")),
                "region_id": str(last_report.get("region_id", "")),
                "action": "expedition_report",
            },
        )


def _max_numeric_value(mapping: dict[str, Any]) -> float:
    if not mapping:
        return 0.0
    return max(float(value) for value in mapping.values())


def _top_numeric_pair(mapping: dict[str, Any]) -> tuple[str, float]:
    if not mapping:
        return "", 0.0
    key = max(mapping, key=lambda item: float(mapping.get(item, 0.0)))
    return str(key), float(mapping.get(key, 0.0))


def _gameplay_region_hint(region: dict[str, Any]) -> dict[str, Any]:
    health = region.get("health_state", {})
    hazards = region.get("hazard_state", {})
    resources = region.get("resource_state", {})
    frontier_links = region.get("frontier_links", [])
    hazard_key, hazard_value = _top_numeric_pair(hazards)
    resource_key, resource_value = _top_numeric_pair(resources)
    biodiversity = float(health.get("biodiversity", 0.0))
    resilience = float(health.get("resilience", 0.0))
    if hazard_value >= 0.55:
        return {
            "action_key": "restore",
            "action": "修复",
            "priority": "high",
            "reason": f"压低最高风险 {hazard_key} {hazard_value:.0%}",
            "hazard_key": hazard_key,
            "hazard_value": round(hazard_value, 4),
            "resource_key": resource_key,
            "resource_value": round(resource_value, 4),
        }
    if biodiversity < 0.60 or resilience < 0.60:
        return {
            "action_key": "survey",
            "action": "调查",
            "priority": "medium",
            "reason": "补齐情报，找出薄弱生态链",
            "hazard_key": hazard_key,
            "hazard_value": round(hazard_value, 4),
            "resource_key": resource_key,
            "resource_value": round(resource_value, 4),
        }
    if frontier_links:
        link = frontier_links[0]
        strength = float(link.get("strength", 0.0))
        if strength < 0.80:
            return {
                "action_key": "corridor",
                "action": "通道",
                "priority": "medium",
                "reason": f"加强到{link.get('target_name', '相邻区域')}的{link.get('connection_label', '生态通道')}",
                "target_region_id": str(link.get("target_region_id", "")),
                "target_region_name": str(link.get("target_name", "")),
                "connection_strength": round(strength, 4),
                "hazard_key": hazard_key,
                "hazard_value": round(hazard_value, 4),
            }
    return {
        "action_key": "survey",
        "action": "调查",
        "priority": "low",
        "reason": "稳定区继续扩充物种与热点记录",
        "hazard_key": hazard_key,
        "hazard_value": round(hazard_value, 4),
        "resource_key": resource_key,
        "resource_value": round(resource_value, 4),
    }


def _attach_gameplay_state(payload: dict[str, Any], ticks: int) -> None:
    regions = payload.get("region_details", {})
    if not isinstance(regions, dict) or not regions:
        return
    safe_count = 0
    weakest_region: dict[str, Any] = {"id": "", "name": "未知区域", "score": 2.0}
    riskiest_region: dict[str, Any] = {"id": "", "name": "未知区域", "risk": 0.0}
    recommendations: dict[str, Any] = {}
    for region_id, region_value in regions.items():
        if not isinstance(region_value, dict):
            continue
        region = region_value
        health = region.get("health_state", {})
        risk = _max_numeric_value(region.get("hazard_state", {}))
        biodiversity = float(health.get("biodiversity", 0.0))
        resilience = float(health.get("resilience", 0.0))
        if biodiversity >= 0.60 and resilience >= 0.60 and risk < 0.55:
            safe_count += 1
        health_score = biodiversity + resilience - risk
        if health_score < float(weakest_region["score"]):
            weakest_region = {
                "id": str(region_id),
                "name": str(region.get("name", region_id)),
                "score": round(health_score, 4),
            }
        if risk > float(riskiest_region["risk"]):
            riskiest_region = {
                "id": str(region_id),
                "name": str(region.get("name", region_id)),
                "risk": round(risk, 4),
            }
        hint = _gameplay_region_hint(region)
        region["gameplay_hint"] = hint
        recommendations[str(region_id)] = hint
    total = len(regions)
    world_goal = {
        "safe_count": safe_count,
        "total_regions": total,
        "weak_count": max(0, total - safe_count),
        "target_biodiversity": 0.60,
        "target_resilience": 0.60,
        "max_safe_risk": 0.55,
        "weakest_region": weakest_region,
        "riskiest_region": riskiest_region,
        "summary": (
            "让全部生态区保持多样性/韧性 60% 以上且风险低于 55%。"
            f"当前安全 {safe_count}/{total}，优先关注 {weakest_region['name']}，"
            f"最高风险 {riskiest_region['name']} {float(riskiest_region['risk']):.0%}。"
        ),
    }
    gameplay_state = {
        "turn_ticks": ticks,
        "world_goal": world_goal,
        "region_recommendations": recommendations,
    }
    payload["gameplay_state"] = gameplay_state
    payload.setdefault("ui_meta", {})["gameplay_state"] = gameplay_state


def main() -> None:
    args = parse_args()
    intent = {} if args.ignore_intent else _load_strategy_intent(args.intent)
    reports = {} if args.ignore_reports else _load_expedition_reports(args.reports)
    world = build_default_world_simulation()
    active_region = args.active_region or str(intent.get("region_id", ""))
    if not active_region and isinstance(reports.get("_last", {}), dict):
        active_region = str(reports.get("_last", {}).get("region_id", ""))
    if active_region:
        world.set_active_region(active_region)

    applied_reports = _apply_expedition_reports(world, reports) if reports else {}
    applied_intent = _apply_strategy_intent(world, intent) if intent else {}
    ticks = max(0, args.ticks) + (_strategy_tick_bonus(intent) if applied_intent else 0)
    for _ in range(ticks):
        world.update()
    if applied_intent and str(intent.get("action_key", "")) == "corridor":
        target_region_id = str(intent.get("target_region_id", ""))
        if target_region_id and world.world_map.get_region(target_region_id) is not None:
            world.set_active_region(target_region_id)

    payload = build_world_ui_payload(world)
    _attach_strategy_to_payload(payload, applied_intent, intent)
    _attach_expedition_reports_to_payload(payload, applied_reports, reports)
    _attach_gameplay_state(payload, ticks)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as handle:
        if args.pretty:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
        else:
            json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
    print(f"Exported world state to {output_path}")


if __name__ == "__main__":
    main()

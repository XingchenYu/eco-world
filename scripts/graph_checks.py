#!/usr/bin/env python3
"""根据改动文件给出 graph-guided 编译与测试建议。"""

from __future__ import annotations

import argparse
import bisect
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Set, Tuple


ROOT = Path(__file__).resolve().parents[1]
DOC_PREFIXES = ("docs/",)
DOC_FILES = {"README.md", ".mcp.json", ".code-review-graphignore"}
TEST_FILE_BY_GROUP = {
    "basic": "tests/test_basic.py",
    "world": "tests/test_world.py",
    "wetland": "tests/test_wetland.py",
    "grassland": "tests/test_grassland.py",
    "runtime": "tests/test_runtime.py",
    "species": "tests/test_species.py",
}


def _is_doc_only(paths: Sequence[str]) -> bool:
    return all(path in DOC_FILES or path.startswith(DOC_PREFIXES) for path in paths)


def _normalize(paths: Iterable[str]) -> List[str]:
    normalized: List[str] = []
    for raw in paths:
        raw = raw.strip()
        if not raw:
            continue
        path = Path(raw)
        if path.is_absolute():
            try:
                normalized.append(str(path.relative_to(ROOT)))
            except ValueError:
                normalized.append(str(path))
        else:
            normalized.append(raw)
    return normalized


def _git_changed_files(staged: bool = False) -> List[str]:
    args = ["git", "diff", "--name-only"]
    if staged:
        args.append("--cached")
    else:
        args.append("HEAD")
    result = subprocess.run(
        args,
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return _normalize(result.stdout.splitlines())


def _git_diff_text(path: str) -> str:
    result = subprocess.run(
        ["git", "diff", "--unified=0", "--", path],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout


def _matches(paths: Sequence[str], prefixes: Sequence[str]) -> bool:
    return any(any(path.startswith(prefix) for prefix in prefixes) for path in paths)


def _add_compile_targets(targets: Set[str], *paths: str) -> None:
    targets.update(paths)
    targets.add("tests/test_ecosystem.py")


def _parse_changed_new_lines(diff_text: str) -> Set[int]:
    changed: Set[int] = set()
    for line in diff_text.splitlines():
        if not line.startswith("@@"):
            continue
        match = re.search(r"\+(\d+)(?:,(\d+))?", line)
        if not match:
            continue
        start = int(match.group(1))
        length = int(match.group(2) or "1")
        if length == 0:
            continue
        changed.update(range(start, start + length))
    return changed


def _test_function_ranges() -> List[Tuple[int, str]]:
    test_file = ROOT / "tests/test_ecosystem.py"
    return _python_def_ranges(test_file)


def _python_def_ranges(path: Path) -> List[Tuple[int, str]]:
    ranges: List[Tuple[int, str]] = []
    with path.open("r", encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, start=1):
            if line.startswith("def "):
                name = line[4 : line.index("(")]
                ranges.append((lineno, name))
    return ranges


def _infer_group_from_test_name(name: str) -> str | None:
    basic_names = {
        "test_environment",
        "test_plants",
        "test_animals",
        "test_ecosystem_update",
        "test_food_chain",
        "test_statistics",
        "test_minnow_registration_and_spawn",
        "test_shrimp_uses_shallow_or_river_habitat",
        "test_load_config_preserves_world_dimensions",
        "test_land_animals_do_not_spawn_in_water",
        "test_amphibious_animals_can_spawn_in_water",
        "test_night_moth_registration_and_spawn",
    }
    if name in basic_names:
        return "basic"
    if "wetland" in name or any(token in name for token in ("beaver", "crocodile", "hippopotamus")):
        return "wetland"
    if "grassland" in name or "carrion" in name:
        return "grassland"
    if "runtime_" in name or "region_simulation_applies" in name or "hotspot_memory_center" in name:
        return "runtime"
    if any(
        token in name
        for token in (
            "elephant",
            "rhino",
            "giraffe",
            "antelope",
            "zebra",
            "lion_",
            "hyena_",
            "vulture",
        )
    ):
        return "species"
    if any(
        token in name
        for token in (
            "world",
            "registry",
            "food_web",
            "cascade",
            "competition",
            "predation",
            "symbiosis",
            "territory_summary",
            "social_trend_summary",
            "region_relationship_state",
            "region_defaults",
        )
    ):
        return "world"
    return None


def _classify_test_file_diff() -> Tuple[Set[str], bool]:
    diff_text = _git_diff_text("tests/test_ecosystem.py")
    changed_lines = _parse_changed_new_lines(diff_text)
    if not changed_lines:
        return set(), False

    function_ranges = _test_function_ranges()
    if not function_ranges:
        return set(), True

    function_starts = [line for line, _ in function_ranges]
    changed_groups: Set[str] = set()
    touches_harness = False

    for line in changed_lines:
        idx = bisect.bisect_right(function_starts, line) - 1
        if idx < 0:
            touches_harness = True
            continue
        _, func_name = function_ranges[idx]
        if func_name in {"_run_test_group", "run_all_tests"}:
            touches_harness = True
            continue
        group = _infer_group_from_test_name(func_name)
        if group is None:
            touches_harness = True
            continue
        changed_groups.add(group)

    return changed_groups, touches_harness


def _infer_group_from_entity_def(path: str, name: str) -> str | None:
    if path == "src/entities/animals.py":
        if name in {"_give_birth"}:
            return "species"
        if any(
            token in name
            for token in (
                "runtime",
                "cycle",
                "bias",
                "condition",
                "route",
                "drift",
            )
        ):
            return "runtime"
        if name.startswith("_apply_"):
            return "runtime"
        if any(token in name for token in ("antelope", "zebra", "vulture")):
            return "species"
    if path == "src/entities/omnivores.py":
        if name in {"_social_group_birth"}:
            return "species"
        if any(
            token in name
            for token in (
                "runtime",
                "stability",
                "cycle",
                "core",
                "front",
                "corridor",
                "cluster",
                "bias",
                "center",
                "pressure",
            )
        ):
            return "runtime"
        if name.startswith("_apply_"):
            return "runtime"
        if any(token in name for token in ("lion", "hyena")):
            return "species"
    return None


def _classify_entity_diff(path: str) -> Tuple[Set[str], bool]:
    diff_text = _git_diff_text(path)
    changed_lines = _parse_changed_new_lines(diff_text)
    if not changed_lines:
        return set(), False

    function_ranges = _python_def_ranges(ROOT / path)
    if not function_ranges:
        return set(), True

    function_starts = [line for line, _ in function_ranges]
    changed_groups: Set[str] = set()
    touches_unknown = False

    for line in changed_lines:
        idx = bisect.bisect_right(function_starts, line) - 1
        if idx < 0:
            touches_unknown = True
            continue
        _, func_name = function_ranges[idx]
        group = _infer_group_from_entity_def(path, func_name)
        if group is None:
            touches_unknown = True
            continue
        changed_groups.add(group)

    return changed_groups, touches_unknown


def _infer_group_from_sim_def(path: str, name: str) -> str | None:
    if path == "src/sim/region_simulation.py":
        if name == "apply_relationship_runtime_state":
            return "runtime"
        if any(token in name for token in ("runtime", "relationship")):
            return "runtime"
        if any(token in name for token in ("region_config", "_build_region_config")):
            return "world"
    if path == "src/sim/world_simulation.py":
        if any(token in name for token in ("_build_runtime_territory_state", "_collect_runtime_birth_signals")):
            return "runtime"
        if any(token in name for token in ("_build_combined_pressures", "get_statistics", "update")):
            return "world"
    return None


def _classify_sim_diff(path: str) -> Tuple[Set[str], bool]:
    diff_text = _git_diff_text(path)
    changed_lines = _parse_changed_new_lines(diff_text)
    if not changed_lines:
        return set(), False

    function_ranges = _python_def_ranges(ROOT / path)
    if not function_ranges:
        return set(), True

    function_starts = [line for line, _ in function_ranges]
    changed_groups: Set[str] = set()
    touches_unknown = False

    for line in changed_lines:
        idx = bisect.bisect_right(function_starts, line) - 1
        if idx < 0:
            touches_unknown = True
            continue
        _, func_name = function_ranges[idx]
        group = _infer_group_from_sim_def(path, func_name)
        if group is None:
            touches_unknown = True
            continue
        changed_groups.add(group)

    return changed_groups, touches_unknown


def build_plan(changed_files: Sequence[str]) -> dict:
    compile_targets: Set[str] = set()
    test_groups: List[str] = []
    reasons: List[str] = []
    full_regression = False

    if _is_doc_only(changed_files):
        return {
            "changed_files": list(changed_files),
            "compile_targets": [],
            "test_groups": [],
            "reasons": ["仅检测到文档或配置说明改动，可跳过代码编译与测试。"],
            "skip_checks": True,
            "profiles": {},
        }

    if _matches(changed_files, ("src/ecology/grassland.py", "src/ecology/carrion.py")):
        _add_compile_targets(
            compile_targets,
            "src/ecology/grassland.py",
            "src/ecology/carrion.py",
        )
        test_groups.append("grassland")
        reasons.append("检测到草原链或尸体资源链改动，优先跑 grassland 组。")

    if _matches(changed_files, ("src/ecology/social.py", "src/ecology/territory.py")):
        _add_compile_targets(
            compile_targets,
            "src/ecology/social.py",
            "src/ecology/territory.py",
            "src/ecology/grassland.py",
            "src/ecology/carrion.py",
        )
        test_groups.extend(["world", "runtime", "grassland"])
        reasons.append("检测到 social/territory 改动，优先检查 world、runtime、grassland。")

    if _matches(changed_files, ("src/sim/world_simulation.py", "src/sim/region_simulation.py")):
        _add_compile_targets(
            compile_targets,
            "src/sim/world_simulation.py",
            "src/sim/region_simulation.py",
            "src/ecology/social.py",
            "src/ecology/territory.py",
            "src/ecology/grassland.py",
            "src/ecology/carrion.py",
        )
        sim_groups: Set[str] = set()
        touches_unknown = False
        for sim_path in ("src/sim/world_simulation.py", "src/sim/region_simulation.py"):
            if sim_path not in changed_files:
                continue
            groups, unknown = _classify_sim_diff(sim_path)
            sim_groups.update(groups)
            touches_unknown = touches_unknown or unknown
        if sim_groups and not touches_unknown:
            ordered_sim_groups = [group for group in ("world", "runtime", "grassland") if group in sim_groups]
            test_groups.extend(ordered_sim_groups)
            reasons.append("检测到 sim 改动，且 diff 可归类到具体函数，按受影响的 world/runtime/grassland 文件执行。")
        else:
            test_groups.extend(["world", "runtime", "grassland"])
            reasons.append("检测到 sim 枢纽改动，优先检查 world、runtime、grassland。")

    if _matches(changed_files, ("src/entities/animals.py", "src/entities/omnivores.py")):
        _add_compile_targets(
            compile_targets,
            "src/entities/animals.py",
            "src/entities/omnivores.py",
        )
        entity_groups: Set[str] = set()
        touches_unknown = False
        for entity_path in ("src/entities/animals.py", "src/entities/omnivores.py"):
            if entity_path not in changed_files:
                continue
            groups, unknown = _classify_entity_diff(entity_path)
            entity_groups.update(groups)
            touches_unknown = touches_unknown or unknown
        if entity_groups and not touches_unknown:
            ordered_entity_groups = [group for group in ("species", "runtime") if group in entity_groups]
            test_groups.extend(ordered_entity_groups)
            reasons.append("检测到运行体改动，且 diff 可归类到具体行为函数，按受影响的 species/runtime 组增量执行。")
        else:
            test_groups.extend(["species", "runtime"])
            reasons.append("检测到运行体改动，优先检查 species、runtime。")

    if _matches(changed_files, ("src/world/", "src/data/")):
        _add_compile_targets(
            compile_targets,
            "src/sim/world_simulation.py",
            "src/sim/region_simulation.py",
            "src/world/world_map.py",
            "src/world/region.py",
            "src/data/models.py",
            "src/data/registry.py",
            "src/data/defaults.py",
        )
        test_groups.extend(["world", "wetland", "grassland"])
        reasons.append("检测到 world/data 改动，优先检查 world、wetland、grassland。")

    if _matches(changed_files, ("tests/test_ecosystem.py",)):
        _add_compile_targets(compile_targets, "tests/test_ecosystem.py")
        changed_groups, touches_harness = _classify_test_file_diff()
        if touches_harness or not changed_groups:
            full_regression = True
            reasons.append("检测到测试入口或分组骨架改动，建议至少补一次 all 全量回归。")
        else:
            test_groups.extend(sorted(changed_groups))
            reasons.append(
                "检测到测试文件改动，但变更落在具体测试函数内，按受影响测试组增量执行。"
            )

    if _matches(changed_files, ("src/core/ecosystem.py", "src/data/defaults.py")):
        full_regression = True
        reasons.append("检测到共享核心层改动，建议补 all 全量回归。")

    if not compile_targets:
        _add_compile_targets(compile_targets, "tests/test_ecosystem.py")
        test_groups.append("basic")
        reasons.append("未命中高耦合图谱规则，先跑 basic 冒烟测试。")

    ordered_groups: List[str] = []
    for group in test_groups:
        if group not in ordered_groups:
            ordered_groups.append(group)
    if full_regression and "all" not in ordered_groups:
        ordered_groups.append("all")

    return {
        "changed_files": list(changed_files),
        "compile_targets": sorted(compile_targets),
        "test_groups": ordered_groups,
        "reasons": reasons,
        "skip_checks": False,
        "profiles": _build_profiles(sorted(compile_targets), ordered_groups),
    }


def _build_profiles(compile_targets: Sequence[str], test_groups: Sequence[str]) -> Dict[str, dict]:
    profiles: Dict[str, dict] = {}
    if not compile_targets:
        return profiles

    smoke_groups = [group for group in test_groups if group in {"basic", "world", "runtime", "grassland", "species", "wetland"}]
    smoke_groups = smoke_groups[:1] if smoke_groups else []

    targeted_groups = [group for group in test_groups if group != "all"]

    profiles["smoke"] = {
        "compile_targets": list(compile_targets),
        "test_groups": smoke_groups,
        "description": "最小代价确认当前主改动没有立即损坏。",
    }
    profiles["targeted"] = {
        "compile_targets": list(compile_targets),
        "test_groups": targeted_groups,
        "description": "按 graph 影响面覆盖本轮真正相关的模块。",
    }
    profiles["full"] = {
        "compile_targets": list(compile_targets),
        "test_groups": ["all"],
        "description": "共享层、测试入口或高风险改动时使用全量回归。",
    }
    return profiles


def _format_profile_commands(profile: dict, emit: str = "both") -> str:
    lines: List[str] = []
    if emit in {"both", "compile"}:
        compile_cmd = (
            "PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile "
            + " ".join(profile["compile_targets"])
        )
        lines.append(compile_cmd)
    if emit in {"both", "tests"}:
        if profile["test_groups"]:
            for group in profile["test_groups"]:
                test_file = TEST_FILE_BY_GROUP.get(group)
                if test_file:
                    lines.append(f"PYTHONDONTWRITEBYTECODE=1 python3 {test_file}")
                else:
                    lines.append(
                        f"PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py {group}"
                    )
        else:
            lines.append("skip tests / 可跳过测试")
    return "\n".join(lines)


def format_plan(
    plan: dict,
    profile_only: str | None = None,
    commands_only: bool = False,
    emit: str = "both",
) -> str:
    if profile_only:
        profile = plan["profiles"].get(profile_only)
        if not profile:
            return f"Unknown profile / 未知检查档位: {profile_only}"
        if commands_only:
            return _format_profile_commands(profile, emit=emit)
        return "\n".join(
            [
                f"Profile / 检查档位: {profile_only}",
                profile["description"],
                "",
                _format_profile_commands(profile, emit=emit),
            ]
        )

    lines = [
        "Graph-guided checks / 图谱驱动检查建议",
        "",
        "Changed files / 改动文件:",
    ]
    lines.extend(f"- {path}" for path in plan["changed_files"])
    lines.append("")
    if plan.get("skip_checks"):
        lines.append("Compile command / 编译命令:")
        lines.append("- skip / 可跳过")
        lines.append("")
        lines.append("Test groups / 建议测试组:")
        lines.append("- skip / 可跳过")
        lines.append("")
        lines.append("Reasons / 规则命中原因:")
        lines.extend(f"- {reason}" for reason in plan["reasons"])
        return "\n".join(lines)

    compile_cmd = (
        "PYTHONPYCACHEPREFIX=/tmp/eco-world-pyc python3 -m py_compile "
        + " ".join(plan["compile_targets"])
    )
    lines.append("Compile command / 编译命令:")
    lines.append(compile_cmd)
    lines.append("")
    lines.append("Test groups / 建议测试组:")
    for group in plan["test_groups"]:
        test_file = TEST_FILE_BY_GROUP.get(group)
        if test_file:
            lines.append(f"- {group}: PYTHONDONTWRITEBYTECODE=1 python3 {test_file}")
        else:
            lines.append(
                f"- {group}: PYTHONDONTWRITEBYTECODE=1 python3 tests/test_ecosystem.py {group}"
            )
    lines.append("")
    lines.append("Profiles / 三档检查方案:")
    for name in ("smoke", "targeted", "full"):
        profile = plan["profiles"].get(name)
        if not profile:
            continue
        lines.append(f"- {name}: {profile['description']}")
        lines.append("  " + _format_profile_commands(profile, emit=emit).replace("\n", "\n  "))
    lines.append("")
    lines.append("Reasons / 规则命中原因:")
    lines.extend(f"- {reason}" for reason in plan["reasons"])
    return "\n".join(lines)


def _parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="根据改动文件给出 graph-guided 编译与测试建议。"
    )
    parser.add_argument(
        "--staged",
        action="store_true",
        help="只读取 git staged / 已暂存的改动文件。",
    )
    parser.add_argument(
        "--profile",
        choices=("smoke", "targeted", "full"),
        help="只输出某一档检查方案。",
    )
    parser.add_argument(
        "--commands-only",
        action="store_true",
        help="只输出可执行命令，减少解释性文本。",
    )
    parser.add_argument(
        "--emit",
        choices=("both", "compile", "tests"),
        default="both",
        help="只输出编译命令、测试命令，或两者都输出。",
    )
    parser.add_argument("paths", nargs="*", help="手动指定改动文件。")
    return parser.parse_args(argv[1:])


def main(argv: Sequence[str]) -> int:
    args = _parse_args(argv)
    if args.paths:
        changed_files = _normalize(args.paths)
    else:
        changed_files = _git_changed_files(staged=args.staged)
    if not changed_files:
        print("No changed files detected / 未检测到改动文件。")
        return 0
    print(
        format_plan(
            build_plan(changed_files),
            profile_only=args.profile,
            commands_only=args.commands_only,
            emit=args.emit,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

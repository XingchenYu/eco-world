"""导出 Godot 世界界面所需的 JSON 状态。"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

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
    parser.add_argument("--pretty", action="store_true", help="Write indented JSON")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    world = build_default_world_simulation()
    if args.active_region:
        world.set_active_region(args.active_region)
    for _ in range(max(0, args.ticks)):
        world.update()

    payload = build_world_ui_payload(world)
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

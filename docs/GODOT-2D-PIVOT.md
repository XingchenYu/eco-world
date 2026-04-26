# Godot 2D Pivot

## Decision

The 3D exploration line is no longer the main product path.

The Godot frontend now pivots to:

- 2D exploration
- ecology-driven encounters
- hotspot routing
- codex / log / task progression
- world map + region traversal

The immediate goal is not visual realism. The immediate goal is:

- readable game state
- stable movement
- meaningful ecology-driven decisions
- a full playable loop driven by backend world data

## Main Scene

The main scene should be:

- `res://scenes/savanna_explorer.tscn`

The 3D scene remains in the repo only as archived experimental work:

- `res://scenes/savanna_explorer_3d.tscn`

It is not the active gameplay baseline.

The downloaded realism resource pipeline has been removed. Do not resume:

- external 3D terrain packs
- external 3D vegetation packs
- external 3D fauna import
- HDRI realism integration

## What Gets Reused

The 2D line should directly reuse:

- `godot/data/world_state.json`
- region details
- species manifests
- hotspot manifests
- frontier links
- narrative and bulletin data when useful

The existing 2D scenes and scripts are the base:

- `res://scenes/savanna_explorer.tscn`
- `res://scripts/savanna_explorer.gd`
- `res://scenes/world_map.tscn`
- `res://scripts/world_map.gd`

## What Stops

Stop investing in:

- 3D asset import integration
- 3D realism migration
- placeholder 3D fauna rigs
- 3D terrain dressing

Those files stay only for reference unless explicitly revived later.

## Next Build Order

1. Stabilize the 2D explorer as the default entry scene.
2. Strengthen the 2D gameplay loop:
   - exploration
   - encounter pressure
   - hotspot tasks
   - chase / aftermath / exit decisions
3. Tighten the 2D UI into a clean game HUD.
4. Keep all ecology logic backend-driven.

## Current Design Baseline

The active design baseline now lives in:

- [/Users/yumini/Projects/eco-world/docs/GODOT-2D-GAME-FRAMEWORK.md](/Users/yumini/Projects/eco-world/docs/GODOT-2D-GAME-FRAMEWORK.md)
- [/Users/yumini/Projects/eco-world/docs/WORLD-BIBLE.md](/Users/yumini/Projects/eco-world/docs/WORLD-BIBLE.md)
- [/Users/yumini/Projects/eco-world/docs/BACKEND-TO-GAMEPLAY-MAPPING.md](/Users/yumini/Projects/eco-world/docs/BACKEND-TO-GAMEPLAY-MAPPING.md)

## Quality Bar

The 2D game should feel:

- readable
- systemic
- fast to iterate
- mechanically interesting

Not:

- pseudo-3D
- realism-driven
- asset-blocked
- visually overloaded

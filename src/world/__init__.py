"""v4 世界结构模块。"""

from .region import BiomePatch, HabitatPatch, Region, RegionConnector
from .world_map import WorldMap, build_default_world_map

__all__ = [
    "BiomePatch",
    "HabitatPatch",
    "Region",
    "RegionConnector",
    "WorldMap",
    "build_default_world_map",
]

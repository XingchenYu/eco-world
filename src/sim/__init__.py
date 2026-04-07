"""v4 模拟入口兼容层。"""

from .region_simulation import RegionSimulation
from .world_simulation import WorldSimulation, WorldTickSummary, build_default_world_simulation

__all__ = [
    "RegionSimulation",
    "WorldSimulation",
    "WorldTickSummary",
    "build_default_world_simulation",
]

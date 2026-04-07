"""核心引擎模块."""

from .creature import Creature, BehaviorState
from .balance import EcoBalance, Alert, CausalEvent, SpeciesState
from .environment import Environment, TerrainType, Weather

__all__ = [
    "Creature",
    "BehaviorState",
    "Ecosystem",
    "RegionSimulation",
    "WorldSimulation",
    "Environment",
    "TerrainType",
    "Weather",
    "EcoBalance",
    "Alert",
    "CausalEvent",
    "SpeciesState",
]


def __getattr__(name):
    if name == "Ecosystem":
        from .ecosystem import Ecosystem

        return Ecosystem
    if name == "RegionSimulation":
        from src.sim.region_simulation import RegionSimulation

        return RegionSimulation
    if name == "WorldSimulation":
        from src.sim.world_simulation import WorldSimulation

        return WorldSimulation
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")

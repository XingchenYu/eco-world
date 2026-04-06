"""核心引擎模块."""

from .creature import Creature, BehaviorState
from .balance import EcoBalance, Alert, CausalEvent, SpeciesState
from .environment import Environment, TerrainType, Weather

__all__ = [
    "Creature",
    "BehaviorState",
    "Ecosystem",
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
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")

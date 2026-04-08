"""区域、群系和栖息地数据结构。"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple


@dataclass(frozen=True)
class RegionConnector:
    """区域边界交换通道。"""

    target_region_id: str
    connection_type: str
    strength: float = 1.0
    seasonal_bias: Optional[str] = None


@dataclass(frozen=True)
class HabitatPatch:
    """区域内部的细粒度栖息地块。"""

    habitat_type: str
    bounds: Tuple[int, int, int, int]
    vegetation_density: float = 0.0
    canopy_density: float = 0.0
    shrub_density: float = 0.0
    water_depth: float = 0.0
    salinity: float = 0.0
    oxygen_level: float = 1.0
    nutrient_load: float = 0.0
    disturbance_level: float = 0.0


@dataclass(frozen=True)
class BiomePatch:
    """区域内的生物群系块。"""

    biome_type: str
    bounds: Tuple[int, int, int, int]
    elevation: float = 0.0
    moisture: float = 0.0
    temperature_bias: float = 0.0
    habitats: Tuple[HabitatPatch, ...] = ()


@dataclass
class Region:
    """v4 世界中的单个生态区。"""

    region_id: str
    name: str
    climate_zone: str
    dominant_biomes: Tuple[str, ...]
    simulation_size: Tuple[int, int]
    hydrology_type: str
    connectors: List[RegionConnector] = field(default_factory=list)
    biome_patches: List[BiomePatch] = field(default_factory=list)
    resource_state: Dict[str, float] = field(default_factory=dict)
    hazard_state: Dict[str, float] = field(default_factory=dict)
    health_state: Dict[str, float] = field(default_factory=dict)
    species_pool: Dict[str, int] = field(default_factory=dict)
    relationship_state: Dict[str, Dict[str, object]] = field(default_factory=dict)
    recent_adjustments: List[Dict[str, object]] = field(default_factory=list)
    ecological_pressures: Dict[str, float] = field(default_factory=dict)

    def add_connector(self, connector: RegionConnector) -> None:
        self.connectors.append(connector)

    def add_biome_patch(self, patch: BiomePatch) -> None:
        self.biome_patches.append(patch)

    @property
    def biome_count(self) -> int:
        return len(self.biome_patches)

    @property
    def habitat_count(self) -> int:
        return sum(len(patch.habitats) for patch in self.biome_patches)

    @property
    def species_count(self) -> int:
        return len(self.species_pool)

    def record_relationship_state(self, key: str, payload: Dict[str, object]) -> None:
        self.relationship_state[key] = payload

    def append_adjustments(self, adjustments: List[Dict[str, object]], limit: int = 20) -> None:
        if not adjustments:
            return
        self.recent_adjustments.extend(adjustments)
        if len(self.recent_adjustments) > limit:
            self.recent_adjustments = self.recent_adjustments[-limit:]

    def update_ecological_pressures(self, pressures: Dict[str, float]) -> None:
        for key, value in pressures.items():
            self.ecological_pressures[key] = round(float(value), 4)

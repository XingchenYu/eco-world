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

    def add_connector(self, connector: RegionConnector) -> None:
        self.connectors.append(connector)

    def add_biome_patch(self, patch: BiomePatch) -> None:
        self.biome_patches.append(patch)

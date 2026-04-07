"""v4 世界级模拟骨架。"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional

from src.data import WorldRegistry, build_default_world_registry
from src.ecology import build_region_food_web
from src.sim.region_simulation import RegionSimulation
from src.world import Region, WorldMap, build_default_world_map


@dataclass
class WorldTickSummary:
    """单次世界更新后的摘要。"""

    tick: int
    active_region_id: str
    loaded_regions: int


class WorldSimulation:
    """管理多个区域模拟的世界容器。"""

    def __init__(
        self,
        world_map: Optional[WorldMap] = None,
        registry: Optional[WorldRegistry] = None,
        region_configs: Optional[Dict[str, dict]] = None,
        default_region_config: Optional[dict] = None,
        initial_region_id: Optional[str] = None,
    ):
        self.world_map = world_map or build_default_world_map()
        self.registry = registry or build_default_world_registry()
        self.region_configs = region_configs or {}
        self.default_region_config = default_region_config or {"world": {"width": 200, "height": 200, "grid_size": 20}}
        self.region_simulations: Dict[str, RegionSimulation] = {}
        self.tick_count = 0

        self.active_region_id = initial_region_id or next(iter(self.world_map.regions))
        self.ensure_region_simulation(self.active_region_id)

    def _build_region_config(self, region_id: str) -> dict:
        return self.region_configs.get(region_id, self.default_region_config)

    def ensure_region_simulation(self, region_id: str) -> RegionSimulation:
        simulation = self.region_simulations.get(region_id)
        if simulation is not None:
            return simulation

        region = self.world_map.get_region(region_id)
        simulation = RegionSimulation(region=region, config=self._build_region_config(region_id))
        self.region_simulations[region_id] = simulation
        return simulation

    def set_active_region(self, region_id: str) -> RegionSimulation:
        simulation = self.ensure_region_simulation(region_id)
        self.active_region_id = region_id
        return simulation

    def get_active_region(self) -> Region:
        return self.world_map.get_region(self.active_region_id)

    def get_active_simulation(self) -> RegionSimulation:
        return self.ensure_region_simulation(self.active_region_id)

    def update(self) -> WorldTickSummary:
        active_simulation = self.get_active_simulation()
        active_simulation.update()
        self.tick_count += 1
        return WorldTickSummary(
            tick=self.tick_count,
            active_region_id=self.active_region_id,
            loaded_regions=len(self.region_simulations),
        )

    def get_statistics(self) -> dict:
        active_region = self.get_active_region()
        active_simulation = self.get_active_simulation()
        simulation_stats = active_simulation.get_statistics()
        regional_species = self.registry.species_for_region(active_region.region_id)
        regional_bridges = self.registry.bridged_species_for_region(active_region.region_id)
        food_web = build_region_food_web(active_region, self.registry)

        return {
            "world_tick": self.tick_count,
            "active_region": {
                "id": active_region.region_id,
                "name": active_region.name,
                "climate_zone": active_region.climate_zone,
                "dominant_biomes": active_region.dominant_biomes,
                "biome_count": active_region.biome_count,
                "habitat_count": active_region.habitat_count,
                "species_pool_count": active_region.species_count,
                "resource_state": dict(active_region.resource_state),
                "hazard_state": dict(active_region.hazard_state),
                "health_state": dict(active_region.health_state),
            },
            "loaded_regions": len(self.region_simulations),
            "regions_total": len(self.world_map.regions),
            "registry": {
                "templates": len(self.registry.templates),
                "species": len(self.registry.species),
                "relations": len(self.registry.relations),
                "bridges": len(self.registry.runtime_bridges),
                "regional_species": sorted(regional_species),
                "relation_summary": self.registry.relation_summary(),
                "bridge_summary": self.registry.bridge_summary(),
                "regional_bridges": {
                    species_id: {
                        "runtime_species_id": bridge.runtime_species_id,
                        "support_level": bridge.support_level,
                        "runtime_domain": bridge.runtime_domain,
                    }
                    for species_id, bridge in regional_bridges.items()
                },
            },
            "food_web": {
                "resident_species": sorted(food_web.resident_species),
                "active_relations": len(food_web.active_relations),
                "relation_summary": dict(food_web.relation_summary),
                "role_summary": dict(food_web.role_summary),
                "keystone_species": list(food_web.keystone_species),
                "engineer_species": list(food_web.engineer_species),
                "flagship_species": list(food_web.flagship_species),
            },
            "simulation": simulation_stats,
        }


def build_default_world_simulation() -> WorldSimulation:
    """创建默认 v4 世界模拟骨架。"""

    return WorldSimulation()

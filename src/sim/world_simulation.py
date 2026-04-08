"""v4 世界级模拟骨架。"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional

from src.data import WorldRegistry, build_default_world_registry
from src.ecology import (
    apply_region_cascade_feedback,
    apply_region_competition_feedback,
    apply_region_symbiosis_feedback,
    build_region_cascade_summary,
    build_region_competition_summary,
    build_region_food_web,
    build_region_symbiosis_summary,
)
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
        self.last_competition_adjustments: Dict[str, list[dict]] = {}

        self.active_region_id = initial_region_id or next(iter(self.world_map.regions))
        self.ensure_region_simulation(self.active_region_id)

    def _persist_region_relationships(
        self,
        region: Region,
        cascade: object,
        competition: object,
        symbiosis: object,
        competition_adjustments: list[dict],
    ) -> None:
        region.record_relationship_state(
            "cascade",
            {
                "driver_species": list(cascade.driver_species),
                "impact_scores": dict(cascade.impact_scores),
                "active_pressures": list(cascade.active_pressures),
                "source_modules": list(cascade.source_modules),
            },
        )
        region.record_relationship_state(
            "competition",
            {
                "active_relations": len(competition.active_relations),
                "pressure_scores": dict(competition.pressure_scores),
                "contested_resources": list(competition.contested_resources),
            },
        )
        region.record_relationship_state(
            "symbiosis",
            {
                "active_relations": len(symbiosis.active_relations),
                "support_scores": dict(symbiosis.support_scores),
                "supported_resources": list(symbiosis.supported_resources),
            },
        )
        region.append_adjustments(competition_adjustments)

        combined_pressures: Dict[str, float] = {}
        for source in (cascade.active_pressures, competition.contested_resources, symbiosis.supported_resources):
            for key in source:
                combined_pressures[key] = combined_pressures.get(key, 0.0) + 1.0
        for key, value in cascade.impact_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in competition.pressure_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in symbiosis.support_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value

        region.update_ecological_pressures(combined_pressures)

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
        active_region = self.get_active_region()
        symbiosis = build_region_symbiosis_summary(active_region, self.registry)
        competition = build_region_competition_summary(active_region, self.registry)
        cascade = build_region_cascade_summary(
            active_region,
            self.registry,
            competition=competition,
            symbiosis=symbiosis,
        )
        apply_region_cascade_feedback(active_region, cascade)
        apply_region_symbiosis_feedback(active_region, symbiosis)
        competition_adjustments: list[dict] = []
        if self.tick_count % 8 == 0:
            competition_adjustments = apply_region_competition_feedback(active_region, self.registry)
        self._persist_region_relationships(
            active_region,
            cascade=cascade,
            competition=competition,
            symbiosis=symbiosis,
            competition_adjustments=competition_adjustments,
        )
        self.last_competition_adjustments[active_region.region_id] = competition_adjustments
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
        competition = build_region_competition_summary(active_region, self.registry)
        symbiosis = build_region_symbiosis_summary(active_region, self.registry)
        cascade = build_region_cascade_summary(
            active_region,
            self.registry,
            competition=competition,
            symbiosis=symbiosis,
        )

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
                "relationship_state": dict(active_region.relationship_state),
                "recent_adjustments": list(active_region.recent_adjustments),
                "ecological_pressures": dict(active_region.ecological_pressures),
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
            "cascade": {
                "driver_species": list(cascade.driver_species),
                "impact_scores": dict(cascade.impact_scores),
                "active_pressures": list(cascade.active_pressures),
                "narrative_impacts": list(cascade.narrative_impacts),
                "source_modules": list(cascade.source_modules),
            },
            "competition": {
                "active_relations": len(competition.active_relations),
                "pressure_scores": dict(competition.pressure_scores),
                "contested_resources": list(competition.contested_resources),
                "narrative_competition": list(competition.narrative_competition),
                "competition_adjustments": list(self.last_competition_adjustments.get(active_region.region_id, [])),
            },
            "symbiosis": {
                "active_relations": len(symbiosis.active_relations),
                "support_scores": dict(symbiosis.support_scores),
                "supported_resources": list(symbiosis.supported_resources),
                "narrative_symbiosis": list(symbiosis.narrative_symbiosis),
            },
            "simulation": simulation_stats,
        }


def build_default_world_simulation() -> WorldSimulation:
    """创建默认 v4 世界模拟骨架。"""

    return WorldSimulation()

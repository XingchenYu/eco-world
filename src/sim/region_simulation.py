"""区域模拟兼容层。"""

from copy import deepcopy
from typing import Optional

from src.core.ecosystem import Ecosystem
from src.world import Region


class RegionSimulation(Ecosystem):
    """在 v4 过渡阶段，沿用当前 Ecosystem 作为区域模拟内核。"""

    def __init__(self, region: Optional[Region] = None, config_path: str = None, config: dict = None):
        region_config = self._build_region_config(region, config)
        super().__init__(config_path=config_path, config=region_config)
        self.region = region
        self.region_id = region.region_id if region is not None else "legacy_region"
        self.region_name = region.name if region is not None else "Legacy Region"

    def _build_region_config(self, region: Optional[Region], config: Optional[dict]) -> dict:
        merged = deepcopy(config or {})
        if region is None:
            return merged

        world_cfg = dict(merged.get("world", {}))
        grid_size = world_cfg.get("grid_size", 20)
        world_cfg.setdefault("width", region.simulation_size[0] * grid_size)
        world_cfg.setdefault("height", region.simulation_size[1] * grid_size)
        merged["world"] = world_cfg
        return merged

    def apply_relationship_runtime_state(self) -> None:
        """将区域级关系状态回灌到当前运行中的个体。"""
        if self.region is None:
            return

        social_state = self.region.relationship_state.get("social_trends", {})
        territory_state = self.region.relationship_state.get("territory", {})
        phase_scores = social_state.get("phase_scores", {})
        hotspot_scores = social_state.get("hotspot_scores", {})
        prosperity_scores = social_state.get("prosperity_scores", {})
        territory_signals = territory_state.get("runtime_signals", {}) if isinstance(territory_state, dict) else {}
        lion_expansion = float(phase_scores.get("lion_expansion_phase", 0.0))
        lion_contraction = float(phase_scores.get("lion_contraction_phase", 0.0))
        hyena_expansion = float(phase_scores.get("hyena_expansion_phase", 0.0))
        hyena_contraction = float(phase_scores.get("hyena_contraction_phase", 0.0))
        herd_route_cycle = float(phase_scores.get("herd_route_cycle", 0.0))
        aerial_carrion_cycle = float(phase_scores.get("aerial_carrion_cycle", 0.0))
        grassland_prosperity = float(prosperity_scores.get("grassland_prosperity_phase", 0.0))
        grassland_collapse = float(prosperity_scores.get("grassland_collapse_phase", 0.0))
        lion_hotspot_memory = float(hotspot_scores.get("lion_hotspot_memory", 0.0))
        hyena_hotspot_memory = float(hotspot_scores.get("hyena_hotspot_memory", 0.0))
        shared_hotspot_memory = float(hotspot_scores.get("shared_hotspot_memory", 0.0))
        herd_channel_bias = float(territory_signals.get("herd_channel_bias", 0.0))
        apex_hotspot_bias = float(territory_signals.get("apex_hotspot_bias", 0.0))
        scavenger_hotspot_bias = float(territory_signals.get("scavenger_hotspot_bias", 0.0))
        herd_source_bias = float(territory_signals.get("herd_source_bias", 0.0))
        kill_corridor_bias = float(territory_signals.get("kill_corridor_bias", 0.0))
        aerial_lane_bias = float(territory_signals.get("aerial_lane_bias", 0.0))
        surface_water_anchor = float(territory_signals.get("surface_water_anchor", 0.0))
        carcass_anchor = float(territory_signals.get("carcass_anchor", 0.0))

        for animal in self.animals:
            if not animal.alive:
                continue
            if animal.species == "lion":
                animal.cycle_expansion_phase = lion_expansion
                animal.cycle_contraction_phase = lion_contraction
                animal.hotspot_memory = lion_hotspot_memory
                animal.shared_hotspot_memory = shared_hotspot_memory
                animal.apex_hotspot_bias = apex_hotspot_bias
                animal.kill_corridor_bias = kill_corridor_bias
                animal.surface_water_anchor = surface_water_anchor
            elif animal.species == "hyena":
                animal.cycle_expansion_phase = hyena_expansion
                animal.cycle_contraction_phase = hyena_contraction
                animal.hotspot_memory = hyena_hotspot_memory
                animal.shared_hotspot_memory = shared_hotspot_memory
                animal.scavenger_hotspot_bias = scavenger_hotspot_bias
                animal.kill_corridor_bias = kill_corridor_bias
                animal.carcass_anchor = carcass_anchor
            elif animal.species == "antelope":
                animal.herd_channel_bias = herd_channel_bias
                animal.herd_source_bias = herd_source_bias
                animal.route_cycle_bias = herd_route_cycle
                animal.prosperity_phase_bias = grassland_prosperity
                animal.collapse_phase_bias = grassland_collapse
                animal.surface_water_anchor = surface_water_anchor
            elif animal.species == "zebra":
                animal.herd_channel_bias = herd_channel_bias
                animal.herd_source_bias = herd_source_bias
                animal.route_cycle_bias = herd_route_cycle
                animal.prosperity_phase_bias = grassland_prosperity
                animal.collapse_phase_bias = grassland_collapse
                animal.surface_water_anchor = surface_water_anchor
            elif animal.species == "vulture":
                animal.aerial_lane_bias = aerial_lane_bias
                animal.kill_corridor_bias = kill_corridor_bias
                animal.carrion_cycle_bias = aerial_carrion_cycle
                animal.prosperity_phase_bias = grassland_prosperity
                animal.collapse_phase_bias = grassland_collapse
                animal.carcass_anchor = carcass_anchor

    def get_statistics(self) -> dict:
        stats = super().get_statistics()
        if self.region is None:
            return stats

        stats["region"] = {
            "id": self.region.region_id,
            "name": self.region.name,
            "climate_zone": self.region.climate_zone,
            "hydrology_type": self.region.hydrology_type,
            "dominant_biomes": self.region.dominant_biomes,
            "biome_count": self.region.biome_count,
            "habitat_count": self.region.habitat_count,
            "species_pool": dict(self.region.species_pool),
            "resource_state": dict(self.region.resource_state),
            "hazard_state": dict(self.region.hazard_state),
            "health_state": dict(self.region.health_state),
        }
        return stats

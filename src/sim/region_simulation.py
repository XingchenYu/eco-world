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
        trend_scores = social_state.get("trend_scores", {})
        hotspot_scores = social_state.get("hotspot_scores", {})
        prosperity_scores = social_state.get("prosperity_scores", {})
        cycle_signals = social_state.get("cycle_signals", []) if isinstance(social_state, dict) else []
        health_state = self.region.health_state if isinstance(self.region.health_state, dict) else {}
        territory_signals = territory_state.get("runtime_signals", {}) if isinstance(territory_state, dict) else {}
        resource_state = self.region.resource_state if isinstance(self.region.resource_state, dict) else {}
        lion_expansion = float(phase_scores.get("lion_expansion_phase", 0.0))
        lion_contraction = float(phase_scores.get("lion_contraction_phase", 0.0))
        hyena_expansion = float(phase_scores.get("hyena_expansion_phase", 0.0))
        hyena_contraction = float(phase_scores.get("hyena_contraction_phase", 0.0))
        herd_route_cycle = float(phase_scores.get("herd_route_cycle", 0.0))
        aerial_carrion_cycle = float(phase_scores.get("aerial_carrion_cycle", 0.0))
        grassland_prosperity = float(prosperity_scores.get("grassland_prosperity_phase", 0.0))
        grassland_collapse = float(prosperity_scores.get("grassland_collapse_phase", 0.0))
        herd_birth_memory = float(trend_scores.get("herd_birth_memory", 0.0))
        aerial_birth_memory = float(trend_scores.get("aerial_birth_memory", 0.0))
        apex_birth_memory = float(trend_scores.get("apex_birth_memory", 0.0))
        lion_hotspot_memory = float(hotspot_scores.get("lion_hotspot_memory", 0.0))
        hyena_hotspot_memory = float(hotspot_scores.get("hyena_hotspot_memory", 0.0))
        shared_hotspot_memory = float(hotspot_scores.get("shared_hotspot_memory", 0.0))
        herd_channel_bias = float(territory_signals.get("herd_channel_bias", 0.0))
        apex_hotspot_bias = float(territory_signals.get("apex_hotspot_bias", 0.0))
        scavenger_hotspot_bias = float(territory_signals.get("scavenger_hotspot_bias", 0.0))
        herd_source_bias = float(territory_signals.get("herd_source_bias", 0.0))
        kill_corridor_bias = float(territory_signals.get("kill_corridor_bias", 0.0))
        aerial_lane_bias = float(territory_signals.get("aerial_lane_bias", 0.0))
        regional_prosperity_bias = float(territory_signals.get("regional_prosperity_bias", 0.0))
        regional_stability_bias = float(territory_signals.get("regional_stability_bias", 0.0))
        regional_collapse_bias = float(territory_signals.get("regional_collapse_bias", 0.0))
        surface_water_anchor = max(
            float(territory_signals.get("surface_water_anchor", 0.0)),
            float(resource_state.get("surface_water", 0.0)),
        )
        carcass_anchor = max(
            float(territory_signals.get("carcass_anchor", 0.0)),
            float(resource_state.get("carcass_availability", 0.0)),
        )
        runtime_anchor_prosperity = min(
            1.0,
            grassland_prosperity * 0.65
            + max(surface_water_anchor, carcass_anchor) * 0.25
            + max(herd_route_cycle, aerial_carrion_cycle) * 0.15,
        )
        regional_prosperity = float(health_state.get("prosperity", 0.0))
        regional_collapse_risk = float(health_state.get("collapse_risk", 0.0))
        regional_stability = float(health_state.get("stability", 0.0))
        if regional_prosperity <= 0.0:
            regional_prosperity = grassland_prosperity * 0.6 + max(herd_route_cycle, aerial_carrion_cycle) * 0.12
        if regional_collapse_risk <= 0.0:
            regional_collapse_risk = grassland_collapse * 0.6
        if regional_stability <= 0.0:
            regional_stability = max(0.0, regional_prosperity * 0.5 - regional_collapse_risk * 0.2)
        regional_health_anchor = max(0.0, regional_prosperity + regional_stability - regional_collapse_risk)
        herd_condition_runtime = float(territory_signals.get("herd_condition_runtime", 0.0))
        aerial_condition_runtime = float(territory_signals.get("aerial_condition_runtime", 0.0))
        apex_condition_runtime = float(territory_signals.get("apex_condition_runtime", 0.0))
        herd_condition_phase_runtime = min(
            1.0,
            max(0.0, herd_condition_runtime + grassland_prosperity * 0.10 - grassland_collapse * 0.08),
        )
        aerial_condition_phase_runtime = min(
            1.0,
            max(0.0, aerial_condition_runtime + grassland_prosperity * 0.10 - grassland_collapse * 0.08),
        )
        apex_condition_phase_runtime = min(
            1.0,
            max(0.0, apex_condition_runtime + grassland_prosperity * 0.10 - grassland_collapse * 0.08),
        )
        apex_regional_health_anchor = max(
            regional_health_anchor,
            float(territory_signals.get("apex_regional_health_anchor_runtime", 0.0)),
        )
        herd_regional_health_anchor = max(
            regional_health_anchor,
            float(territory_signals.get("herd_regional_health_anchor_runtime", 0.0)),
        )
        aerial_regional_health_anchor = max(
            regional_health_anchor,
            float(territory_signals.get("aerial_regional_health_anchor_runtime", 0.0)),
        )
        condition_phase_bias = min(
            1.0,
            max(
                0.0,
                grassland_prosperity * 0.58
                + regional_prosperity * 0.18
                + regional_stability * 0.12
                + runtime_anchor_prosperity * 0.10
                - grassland_collapse * 0.28
                - regional_collapse_risk * 0.16,
            ),
        )
        condition_window_memory = 1.0 if "condition_phase_window_memory" in cycle_signals else 0.0
        world_pressure_bias = min(
            1.0,
            max(
                0.0,
                regional_prosperity * 0.42
                + regional_stability * 0.24
                + runtime_anchor_prosperity * 0.12
                + condition_phase_bias * 0.10
                + condition_window_memory * 0.08
                - regional_collapse_risk * 0.26,
            ),
        )
        world_pressure_window_memory = 1.0 if "world_pressure_window_memory" in cycle_signals else 0.0
        world_pressure_window_bias = min(
            1.0,
            max(
                0.0,
                world_pressure_window_memory * 0.26
                + world_pressure_bias * 0.42
                + condition_phase_bias * 0.16
                + runtime_anchor_prosperity * 0.10
                + regional_stability * 0.08
                - regional_collapse_risk * 0.12,
            ),
        )
        apex_birth_memory_world_pressure_bias = min(
            1.0,
            max(
                0.0,
                apex_birth_memory * 0.34
                + world_pressure_bias * 0.26
                + world_pressure_window_bias * 0.22
                + condition_phase_bias * 0.10
                + runtime_anchor_prosperity * 0.08
                - regional_collapse_risk * 0.10,
            ),
        )
        herd_birth_memory_world_pressure_bias = min(
            1.0,
            max(
                0.0,
                herd_birth_memory * 0.36
                + world_pressure_bias * 0.24
                + world_pressure_window_bias * 0.20
                + condition_phase_bias * 0.10
                + runtime_anchor_prosperity * 0.10
                - regional_collapse_risk * 0.10,
            ),
        )
        aerial_birth_memory_world_pressure_bias = min(
            1.0,
            max(
                0.0,
                aerial_birth_memory * 0.36
                + world_pressure_bias * 0.24
                + world_pressure_window_bias * 0.20
                + condition_phase_bias * 0.10
                + runtime_anchor_prosperity * 0.10
                - regional_collapse_risk * 0.10,
            ),
        )
        apex_birth_cycle_bias = min(
            1.0,
            max(
                0.0,
                apex_birth_memory * 0.28
                + apex_birth_memory_world_pressure_bias * 0.36
                + world_pressure_window_bias * 0.16
                + runtime_anchor_prosperity * 0.10
                - regional_collapse_risk * 0.10,
            ),
        )
        herd_birth_cycle_bias = min(
            1.0,
            max(
                0.0,
                herd_birth_memory * 0.30
                + herd_birth_memory_world_pressure_bias * 0.36
                + world_pressure_window_bias * 0.14
                + runtime_anchor_prosperity * 0.12
                - regional_collapse_risk * 0.10,
            ),
        )
        aerial_birth_cycle_bias = min(
            1.0,
            max(
                0.0,
                aerial_birth_memory * 0.30
                + aerial_birth_memory_world_pressure_bias * 0.36
                + world_pressure_window_bias * 0.14
                + runtime_anchor_prosperity * 0.12
                - regional_collapse_risk * 0.10,
            ),
        )

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
                animal.runtime_anchor_prosperity = runtime_anchor_prosperity
                animal.regional_prosperity = regional_prosperity
                animal.regional_collapse_risk = regional_collapse_risk
                animal.regional_stability = regional_stability
                animal.regional_health_anchor = apex_regional_health_anchor
                animal.condition_runtime = apex_condition_phase_runtime
                animal.condition_phase_bias = condition_phase_bias
                animal.birth_memory_bias = apex_birth_memory
                animal.world_pressure_bias = world_pressure_bias
                animal.world_pressure_window_bias = world_pressure_window_bias
                animal.birth_memory_world_pressure_bias = apex_birth_memory_world_pressure_bias
                animal.birth_cycle_bias = apex_birth_cycle_bias
                animal.regional_prosperity_bias = regional_prosperity_bias
                animal.regional_stability_bias = regional_stability_bias
                animal.regional_collapse_bias = regional_collapse_bias
            elif animal.species == "hyena":
                animal.cycle_expansion_phase = hyena_expansion
                animal.cycle_contraction_phase = hyena_contraction
                animal.hotspot_memory = hyena_hotspot_memory
                animal.shared_hotspot_memory = shared_hotspot_memory
                animal.scavenger_hotspot_bias = scavenger_hotspot_bias
                animal.kill_corridor_bias = kill_corridor_bias
                animal.carcass_anchor = carcass_anchor
                animal.runtime_anchor_prosperity = runtime_anchor_prosperity
                animal.regional_prosperity = regional_prosperity
                animal.regional_collapse_risk = regional_collapse_risk
                animal.regional_stability = regional_stability
                animal.regional_health_anchor = apex_regional_health_anchor
                animal.condition_runtime = apex_condition_phase_runtime
                animal.condition_phase_bias = condition_phase_bias
                animal.birth_memory_bias = apex_birth_memory
                animal.world_pressure_bias = world_pressure_bias
                animal.world_pressure_window_bias = world_pressure_window_bias
                animal.birth_memory_world_pressure_bias = apex_birth_memory_world_pressure_bias
                animal.birth_cycle_bias = apex_birth_cycle_bias
                animal.regional_prosperity_bias = regional_prosperity_bias
                animal.regional_stability_bias = regional_stability_bias
                animal.regional_collapse_bias = regional_collapse_bias
            elif animal.species == "antelope":
                animal.herd_channel_bias = herd_channel_bias
                animal.herd_source_bias = herd_source_bias
                animal.route_cycle_bias = herd_route_cycle
                animal.prosperity_phase_bias = grassland_prosperity
                animal.collapse_phase_bias = grassland_collapse
                animal.surface_water_anchor = surface_water_anchor
                animal.runtime_anchor_prosperity = runtime_anchor_prosperity
                animal.regional_prosperity = regional_prosperity
                animal.regional_collapse_risk = regional_collapse_risk
                animal.regional_stability = regional_stability
                animal.regional_health_anchor = herd_regional_health_anchor
                animal.condition_runtime = herd_condition_phase_runtime
                animal.condition_phase_bias = condition_phase_bias
                animal.birth_memory_bias = herd_birth_memory
                animal.world_pressure_bias = world_pressure_bias
                animal.world_pressure_window_bias = world_pressure_window_bias
                animal.birth_memory_world_pressure_bias = herd_birth_memory_world_pressure_bias
                animal.birth_cycle_bias = herd_birth_cycle_bias
                animal.regional_prosperity_bias = regional_prosperity_bias
                animal.regional_stability_bias = regional_stability_bias
                animal.regional_collapse_bias = regional_collapse_bias
            elif animal.species == "zebra":
                animal.herd_channel_bias = herd_channel_bias
                animal.herd_source_bias = herd_source_bias
                animal.route_cycle_bias = herd_route_cycle
                animal.prosperity_phase_bias = grassland_prosperity
                animal.collapse_phase_bias = grassland_collapse
                animal.surface_water_anchor = surface_water_anchor
                animal.runtime_anchor_prosperity = runtime_anchor_prosperity
                animal.regional_prosperity = regional_prosperity
                animal.regional_collapse_risk = regional_collapse_risk
                animal.regional_stability = regional_stability
                animal.regional_health_anchor = herd_regional_health_anchor
                animal.condition_runtime = herd_condition_phase_runtime
                animal.condition_phase_bias = condition_phase_bias
                animal.birth_memory_bias = herd_birth_memory
                animal.world_pressure_bias = world_pressure_bias
                animal.world_pressure_window_bias = world_pressure_window_bias
                animal.birth_memory_world_pressure_bias = herd_birth_memory_world_pressure_bias
                animal.birth_cycle_bias = herd_birth_cycle_bias
                animal.regional_prosperity_bias = regional_prosperity_bias
                animal.regional_stability_bias = regional_stability_bias
                animal.regional_collapse_bias = regional_collapse_bias
            elif animal.species == "vulture":
                animal.aerial_lane_bias = aerial_lane_bias
                animal.kill_corridor_bias = kill_corridor_bias
                animal.carrion_cycle_bias = aerial_carrion_cycle
                animal.prosperity_phase_bias = grassland_prosperity
                animal.collapse_phase_bias = grassland_collapse
                animal.carcass_anchor = carcass_anchor
                animal.runtime_anchor_prosperity = runtime_anchor_prosperity
                animal.regional_prosperity = regional_prosperity
                animal.regional_collapse_risk = regional_collapse_risk
                animal.regional_stability = regional_stability
                animal.regional_health_anchor = aerial_regional_health_anchor
                animal.condition_runtime = aerial_condition_phase_runtime
                animal.condition_phase_bias = condition_phase_bias
                animal.birth_memory_bias = aerial_birth_memory
                animal.world_pressure_bias = world_pressure_bias
                animal.world_pressure_window_bias = world_pressure_window_bias
                animal.birth_memory_world_pressure_bias = aerial_birth_memory_world_pressure_bias
                animal.birth_cycle_bias = aerial_birth_cycle_bias
                animal.regional_prosperity_bias = regional_prosperity_bias
                animal.regional_stability_bias = regional_stability_bias
                animal.regional_collapse_bias = regional_collapse_bias

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

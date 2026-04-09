"""v4 世界级模拟骨架。"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional

from src.data import WorldRegistry, build_default_world_registry
from src.ecology import (
    apply_region_cascade_feedback,
    apply_region_carrion_chain_feedback,
    apply_region_carrion_chain_rebalancing,
    apply_region_competition_feedback,
    apply_region_grassland_chain_feedback,
    apply_region_grassland_chain_rebalancing,
    apply_region_predation_feedback,
    apply_region_symbiosis_feedback,
    apply_region_social_trend_feedback,
    apply_region_territory_feedback,
    apply_region_wetland_chain_feedback,
    apply_region_wetland_chain_rebalancing,
    build_region_cascade_summary,
    build_region_carrion_chain_summary,
    build_region_competition_summary,
    build_region_food_web,
    build_region_grassland_chain_summary,
    build_region_predation_summary,
    build_region_symbiosis_summary,
    build_region_social_trend_summary,
    build_region_territory_summary,
    build_region_wetland_chain_summary,
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
        self.last_carrion_adjustments: Dict[str, list[dict]] = {}
        self.last_wetland_adjustments: Dict[str, list[dict]] = {}
        self.last_grassland_adjustments: Dict[str, list[dict]] = {}

        self.active_region_id = initial_region_id or next(iter(self.world_map.regions))
        self.ensure_region_simulation(self.active_region_id)

    @staticmethod
    def _build_combined_pressures(
        region: Region,
        cascade: object,
        competition: object,
        carrion_chain: object,
        predation: object,
        social_trends: object,
        symbiosis: object,
        territory: object,
        wetland_chain: object,
        grassland_chain: object,
    ) -> Dict[str, float]:
        combined_pressures: Dict[str, float] = {}
        for source in (
            cascade.active_pressures,
            competition.contested_resources,
            predation.vulnerable_resources,
            social_trends.cycle_signals,
            symbiosis.supported_resources,
            territory.contested_zones,
            wetland_chain.key_species,
            grassland_chain.key_species,
            carrion_chain.key_species,
        ):
            for key in source:
                combined_pressures[key] = combined_pressures.get(key, 0.0) + 1.0
        for key, value in cascade.impact_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in social_trends.hotspot_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in competition.pressure_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in predation.pressure_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in social_trends.trend_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in social_trends.phase_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in social_trends.boom_bust_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in social_trends.prosperity_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in symbiosis.support_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in territory.pressure_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in wetland_chain.trophic_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in grassland_chain.trophic_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value
        for key, value in carrion_chain.resource_scores.items():
            combined_pressures[key] = combined_pressures.get(key, 0.0) + value

        prosperity_pressure = (
            float(social_trends.prosperity_scores.get("grassland_prosperity_phase", 0.0))
            + float(grassland_chain.trophic_scores.get("prosperity_phase_weight", 0.0))
            + float(carrion_chain.resource_scores.get("prosperity_phase_carrion", 0.0))
            + float(grassland_chain.trophic_scores.get("runtime_surface_water_pull", 0.0))
            + float(carrion_chain.resource_scores.get("runtime_carcass_pull", 0.0))
            + float(grassland_chain.trophic_scores.get("runtime_herd_health_pull", 0.0))
            + float(grassland_chain.trophic_scores.get("runtime_apex_health_pull", 0.0)) * 0.8
            + float(carrion_chain.resource_scores.get("runtime_aerial_health_pull", 0.0))
            + float(carrion_chain.resource_scores.get("runtime_apex_health_pull", 0.0)) * 0.8
        )
        collapse_pressure = (
            float(social_trends.prosperity_scores.get("grassland_collapse_phase", 0.0))
            + float(grassland_chain.trophic_scores.get("collapse_phase_weight", 0.0))
            + float(carrion_chain.resource_scores.get("collapse_phase_carrion", 0.0))
            + float(social_trends.boom_bust_scores.get("grassland_bust_phase", 0.0))
            + float(grassland_chain.trophic_scores.get("runtime_apex_health_pull", 0.0)) * 0.35
            + float(carrion_chain.resource_scores.get("runtime_apex_health_pull", 0.0)) * 0.4
        )
        runtime_resource_pressure = (
            float(territory.runtime_signals.get("herd_surface_water_runtime", 0.0))
            + float(territory.runtime_signals.get("aerial_carcass_runtime", 0.0))
            + float(territory.runtime_signals.get("surface_water_anchor", 0.0))
            + float(territory.runtime_signals.get("carcass_anchor", 0.0))
            + float(territory.runtime_signals.get("herd_regional_health_runtime", 0.0))
            + float(territory.runtime_signals.get("aerial_regional_health_runtime", 0.0))
            + float(territory.runtime_signals.get("apex_regional_health_runtime", 0.0)) * 0.8
        )
        combined_pressures["prosperity_pressure"] = round(prosperity_pressure, 4)
        combined_pressures["collapse_pressure"] = round(collapse_pressure, 4)
        combined_pressures["runtime_resource_pressure"] = round(runtime_resource_pressure, 4)
        return combined_pressures

    @staticmethod
    def _apply_long_term_health_pressures(region: Region, combined_pressures: Dict[str, float]) -> None:
        prosperity_pressure = float(combined_pressures.get("prosperity_pressure", 0.0))
        collapse_pressure = float(combined_pressures.get("collapse_pressure", 0.0))
        runtime_resource_pressure = float(combined_pressures.get("runtime_resource_pressure", 0.0))
        current_prosperity = float(region.health_state.get("prosperity", 0.0))
        current_collapse = float(region.health_state.get("collapse_risk", 0.0))
        current_stability = float(region.health_state.get("stability", 0.0))
        region.health_state["prosperity"] = round(
            max(current_prosperity, prosperity_pressure * 0.18 + runtime_resource_pressure * 0.05),
            4,
        )
        region.health_state["collapse_risk"] = round(
            max(current_collapse, collapse_pressure * 0.18),
            4,
        )
        region.health_state["stability"] = round(
            max(current_stability, prosperity_pressure * 0.10 - collapse_pressure * 0.04 + runtime_resource_pressure * 0.03),
            4,
        )

    def _persist_region_relationships(
        self,
        region: Region,
        cascade: object,
        competition: object,
        carrion_chain: object,
        predation: object,
        social_trends: object,
        symbiosis: object,
        territory: object,
        wetland_chain: object,
        grassland_chain: object,
        competition_adjustments: list[dict],
        wetland_adjustments: list[dict],
        grassland_adjustments: list[dict],
        carrion_adjustments: list[dict],
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
            "carrion_chain",
            {
                "key_species": list(carrion_chain.key_species),
                "resource_scores": dict(carrion_chain.resource_scores),
                "layer_scores": dict(carrion_chain.layer_scores),
                "layer_species": {key: list(value) for key, value in carrion_chain.layer_species.items()},
                "narrative_chain": list(carrion_chain.narrative_chain),
            },
        )
        region.record_relationship_state(
            "predation",
            {
                "active_relations": len(predation.active_relations),
                "pressure_scores": dict(predation.pressure_scores),
                "vulnerable_resources": list(predation.vulnerable_resources),
            },
        )
        region.record_relationship_state(
            "social_trends",
            {
                "trend_scores": dict(social_trends.trend_scores),
                "phase_scores": dict(social_trends.phase_scores),
                "boom_bust_scores": dict(social_trends.boom_bust_scores),
                "prosperity_scores": dict(social_trends.prosperity_scores),
                "hotspot_scores": dict(social_trends.hotspot_scores),
                "cycle_signals": list(social_trends.cycle_signals),
                "narrative_trends": list(social_trends.narrative_trends),
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
        region.record_relationship_state(
            "territory",
            {
                "active_species": list(territory.active_species),
                "pressure_scores": dict(territory.pressure_scores),
                "contested_zones": list(territory.contested_zones),
                "narrative_territory": list(territory.narrative_territory),
                "runtime_signals": dict(territory.runtime_signals),
            },
        )
        region.record_relationship_state(
            "wetland_chain",
            {
                "key_species": list(wetland_chain.key_species),
                "trophic_scores": dict(wetland_chain.trophic_scores),
                "layer_scores": dict(wetland_chain.layer_scores),
                "layer_species": {key: list(value) for key, value in wetland_chain.layer_species.items()},
                "narrative_chain": list(wetland_chain.narrative_chain),
            },
        )
        region.record_relationship_state(
            "grassland_chain",
            {
                "key_species": list(grassland_chain.key_species),
                "trophic_scores": dict(grassland_chain.trophic_scores),
                "layer_scores": dict(grassland_chain.layer_scores),
                "layer_species": {key: list(value) for key, value in grassland_chain.layer_species.items()},
                "narrative_chain": list(grassland_chain.narrative_chain),
            },
        )
        wetland_layer_groups: Dict[str, int] = {}
        for item in wetland_adjustments:
            layer_group = item.get("layer_group", "ungrouped")
            wetland_layer_groups[layer_group] = wetland_layer_groups.get(layer_group, 0) + 1
        region.record_relationship_state(
            "wetland_rebalancing",
            {
                "adjustments": list(wetland_adjustments),
                "layer_groups": wetland_layer_groups,
            },
        )
        grassland_layer_groups: Dict[str, int] = {}
        for item in grassland_adjustments:
            layer_group = item.get("layer_group", "ungrouped")
            grassland_layer_groups[layer_group] = grassland_layer_groups.get(layer_group, 0) + 1
        region.record_relationship_state(
            "grassland_rebalancing",
            {
                "adjustments": list(grassland_adjustments),
                "layer_groups": grassland_layer_groups,
            },
        )
        carrion_layer_groups: Dict[str, int] = {}
        for item in carrion_adjustments:
            layer_group = item.get("layer_group", "ungrouped")
            carrion_layer_groups[layer_group] = carrion_layer_groups.get(layer_group, 0) + 1
        region.record_relationship_state(
            "carrion_rebalancing",
            {
                "adjustments": list(carrion_adjustments),
                "layer_groups": carrion_layer_groups,
            },
        )
        region.append_adjustments(competition_adjustments + wetland_adjustments + grassland_adjustments + carrion_adjustments)

        combined_pressures = self._build_combined_pressures(
            region,
            cascade,
            competition,
            carrion_chain,
            predation,
            social_trends,
            symbiosis,
            territory,
            wetland_chain,
            grassland_chain,
        )
        self._apply_long_term_health_pressures(region, combined_pressures)
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

    def _build_runtime_territory_state(self, simulation: RegionSimulation) -> Dict[str, float]:
        region_resource_state = simulation.region.resource_state if simulation.region is not None and isinstance(simulation.region.resource_state, dict) else {}
        state = {
            "lion_pride_strength": 0.0,
            "lion_takeover_pressure": 0.0,
            "lion_pride_count": 0.0,
            "lion_hotspot_count": 0.0,
            "lion_cycle_expansion": 0.0,
            "lion_cycle_contraction": 0.0,
            "hyena_clan_cohesion": 0.0,
            "hyena_clan_front_pressure": 0.0,
            "hyena_clan_count": 0.0,
            "hyena_hotspot_count": 0.0,
            "hyena_cycle_expansion": 0.0,
            "hyena_cycle_contraction": 0.0,
            "herd_hotspot_count": 0.0,
            "herd_apex_overlap": 0.0,
            "vulture_hotspot_count": 0.0,
            "vulture_carrion_overlap": 0.0,
            "shared_hotspot_overlap": 0.0,
            "herd_route_cycle_runtime": 0.0,
            "aerial_carrion_cycle_runtime": 0.0,
            "herd_surface_water_runtime": 0.0,
            "aerial_carcass_runtime": 0.0,
            "apex_regional_health_runtime": 0.0,
            "herd_regional_health_runtime": 0.0,
            "aerial_regional_health_runtime": 0.0,
        }
        lions = [animal for animal in simulation.animals if animal.alive and animal.species == "lion"]
        hyenas = [animal for animal in simulation.animals if animal.alive and animal.species == "hyena"]
        antelopes = [animal for animal in simulation.animals if animal.alive and animal.species == "antelope"]
        zebras = [animal for animal in simulation.animals if animal.alive and animal.species == "zebra"]
        vultures = [animal for animal in simulation.animals if animal.alive and animal.species == "vulture"]
        lion_hotspots = set()
        hyena_hotspots = set()
        herd_hotspots = set()
        vulture_hotspots = set()
        if lions:
            state["lion_pride_strength"] = max(getattr(animal, "pride_strength", 0.0) for animal in lions)
            state["lion_takeover_pressure"] = max(getattr(animal, "takeover_pressure", 0.0) for animal in lions)
            state["lion_pride_count"] = float(len({getattr(animal, "pride_id", animal.id) for animal in lions}))
            state["lion_cycle_expansion"] = max(getattr(animal, "cycle_expansion_phase", 0.0) for animal in lions)
            state["lion_cycle_contraction"] = max(getattr(animal, "cycle_contraction_phase", 0.0) for animal in lions)
            lion_hotspots = {self._territory_hotspot(getattr(animal, "pride_center", animal.position)) for animal in lions}
            state["lion_hotspot_count"] = float(len(lion_hotspots))
            state["apex_regional_health_runtime"] = max(
                [
                    max(
                        0.0,
                        getattr(animal, "regional_prosperity", 0.0)
                        + getattr(animal, "regional_stability", 0.0)
                        - getattr(animal, "regional_collapse_risk", 0.0),
                    )
                    for animal in lions
                ]
                or [0.0]
            )
        if hyenas:
            state["hyena_clan_cohesion"] = max(getattr(animal, "clan_cohesion", 0.0) for animal in hyenas)
            state["hyena_clan_front_pressure"] = max(getattr(animal, "clan_front_pressure", 0.0) for animal in hyenas)
            state["hyena_clan_count"] = float(len({getattr(animal, "clan_id", animal.id) for animal in hyenas}))
            state["hyena_cycle_expansion"] = max(getattr(animal, "cycle_expansion_phase", 0.0) for animal in hyenas)
            state["hyena_cycle_contraction"] = max(getattr(animal, "cycle_contraction_phase", 0.0) for animal in hyenas)
            hyena_hotspots = {self._territory_hotspot(getattr(animal, "clan_center", animal.position)) for animal in hyenas}
            state["hyena_hotspot_count"] = float(len(hyena_hotspots))
            state["apex_regional_health_runtime"] = max(
                state["apex_regional_health_runtime"],
                max(
                    [
                        max(
                            0.0,
                            getattr(animal, "regional_prosperity", 0.0)
                            + getattr(animal, "regional_stability", 0.0)
                            - getattr(animal, "regional_collapse_risk", 0.0),
                        )
                        for animal in hyenas
                    ]
                    or [0.0]
                ),
            )
        if antelopes or zebras:
            herd_hotspots = {self._territory_hotspot(animal.position) for animal in antelopes + zebras}
            state["herd_hotspot_count"] = float(len(herd_hotspots))
            state["herd_route_cycle_runtime"] = max(
                [getattr(animal, "route_cycle_bias", 0.0) for animal in antelopes + zebras] or [0.0]
            )
            state["herd_surface_water_runtime"] = max(
                [getattr(animal, "surface_water_anchor", 0.0) for animal in antelopes + zebras] or [0.0]
            )
            state["herd_surface_water_runtime"] = max(
                state["herd_surface_water_runtime"],
                float(region_resource_state.get("surface_water", 0.0)),
            )
            state["herd_regional_health_runtime"] = max(
                [
                    max(
                        0.0,
                        getattr(animal, "regional_prosperity", 0.0)
                        + getattr(animal, "regional_stability", 0.0)
                        - getattr(animal, "regional_collapse_risk", 0.0),
                    )
                    for animal in antelopes + zebras
                ]
                or [0.0]
            )
        if vultures:
            vulture_hotspots = {self._territory_hotspot(animal.position) for animal in vultures}
            state["vulture_hotspot_count"] = float(len(vulture_hotspots))
            state["aerial_carrion_cycle_runtime"] = max(
                [getattr(animal, "carrion_cycle_bias", 0.0) for animal in vultures] or [0.0]
            )
            state["aerial_carcass_runtime"] = max(
                [getattr(animal, "carcass_anchor", 0.0) for animal in vultures] or [0.0]
            )
            state["aerial_carcass_runtime"] = max(
                state["aerial_carcass_runtime"],
                float(region_resource_state.get("carcass_availability", 0.0)),
            )
            state["aerial_regional_health_runtime"] = max(
                [
                    max(
                        0.0,
                        getattr(animal, "regional_prosperity", 0.0)
                        + getattr(animal, "regional_stability", 0.0)
                        - getattr(animal, "regional_collapse_risk", 0.0),
                    )
                    for animal in vultures
                ]
                or [0.0]
            )
        if lion_hotspots and hyena_hotspots:
            state["shared_hotspot_overlap"] = float(len(lion_hotspots & hyena_hotspots))
        if herd_hotspots and (lion_hotspots or hyena_hotspots):
            state["herd_apex_overlap"] = float(len(herd_hotspots & (lion_hotspots | hyena_hotspots)))
        if vulture_hotspots and (lion_hotspots or hyena_hotspots):
            state["vulture_carrion_overlap"] = float(len(vulture_hotspots & (lion_hotspots | hyena_hotspots)))
        return state

    @staticmethod
    def _territory_hotspot(position: tuple[int, int]) -> tuple[int, int]:
        return (position[0] // 8, position[1] // 8)

    def update(self) -> WorldTickSummary:
        active_simulation = self.get_active_simulation()
        active_simulation.apply_relationship_runtime_state()
        active_simulation.update()
        active_region = self.get_active_region()
        recent_events = [event.description for event in active_simulation.events[-120:]]
        runtime_territory_state = self._build_runtime_territory_state(active_simulation)
        symbiosis = build_region_symbiosis_summary(active_region, self.registry)
        competition = build_region_competition_summary(active_region, self.registry)
        predation = build_region_predation_summary(active_region, self.registry)
        territory = build_region_territory_summary(
            active_region,
            self.registry,
            recent_events=recent_events,
            runtime_state=runtime_territory_state,
        )
        social_trends = build_region_social_trend_summary(active_region, territory_summary=territory)
        wetland_chain = build_region_wetland_chain_summary(active_region, self.registry)
        grassland_chain = build_region_grassland_chain_summary(
            active_region,
            self.registry,
            territory_summary=territory,
            social_trend_summary=social_trends,
        )
        carrion_chain = build_region_carrion_chain_summary(
            active_region,
            self.registry,
            territory_summary=territory,
            social_trend_summary=social_trends,
        )
        cascade = build_region_cascade_summary(
            active_region,
            self.registry,
            competition=competition,
            predation=predation,
            symbiosis=symbiosis,
            territory=territory,
        )
        apply_region_cascade_feedback(active_region, cascade)
        apply_region_predation_feedback(active_region, predation)
        apply_region_social_trend_feedback(active_region, social_trends)
        apply_region_symbiosis_feedback(active_region, symbiosis)
        apply_region_territory_feedback(active_region, territory)
        apply_region_wetland_chain_feedback(active_region, wetland_chain)
        apply_region_grassland_chain_feedback(active_region, grassland_chain)
        apply_region_carrion_chain_feedback(active_region, carrion_chain)
        competition_adjustments: list[dict] = []
        wetland_adjustments: list[dict] = []
        grassland_adjustments: list[dict] = []
        carrion_adjustments: list[dict] = []
        if self.tick_count % 8 == 0:
            competition_adjustments = apply_region_competition_feedback(active_region, self.registry)
        if self.tick_count % 6 == 0:
            wetland_adjustments = apply_region_wetland_chain_rebalancing(active_region, wetland_chain)
            grassland_adjustments = apply_region_grassland_chain_rebalancing(
                active_region,
                grassland_chain,
                territory_summary=territory,
                social_trend_summary=social_trends,
            )
            carrion_adjustments = apply_region_carrion_chain_rebalancing(
                active_region,
                carrion_chain,
                territory_summary=territory,
                social_trend_summary=social_trends,
            )
        self._persist_region_relationships(
            active_region,
            cascade=cascade,
            competition=competition,
            carrion_chain=carrion_chain,
            predation=predation,
            social_trends=social_trends,
            symbiosis=symbiosis,
            territory=territory,
            wetland_chain=wetland_chain,
            grassland_chain=grassland_chain,
            competition_adjustments=competition_adjustments,
            wetland_adjustments=wetland_adjustments,
            grassland_adjustments=grassland_adjustments,
            carrion_adjustments=carrion_adjustments,
        )
        self.last_competition_adjustments[active_region.region_id] = competition_adjustments
        self.last_wetland_adjustments[active_region.region_id] = wetland_adjustments
        self.last_grassland_adjustments[active_region.region_id] = grassland_adjustments
        self.last_carrion_adjustments[active_region.region_id] = carrion_adjustments
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
        recent_events = [event.description for event in active_simulation.events[-120:]]
        runtime_territory_state = self._build_runtime_territory_state(active_simulation)
        regional_species = self.registry.species_for_region(active_region.region_id)
        regional_bridges = self.registry.bridged_species_for_region(active_region.region_id)
        food_web = build_region_food_web(active_region, self.registry)
        competition = build_region_competition_summary(active_region, self.registry)
        predation = build_region_predation_summary(active_region, self.registry)
        symbiosis = build_region_symbiosis_summary(active_region, self.registry)
        territory = build_region_territory_summary(
            active_region,
            self.registry,
            recent_events=recent_events,
            runtime_state=runtime_territory_state,
        )
        social_trends = build_region_social_trend_summary(active_region, territory_summary=territory)
        cascade = build_region_cascade_summary(
            active_region,
            self.registry,
            competition=competition,
            predation=predation,
            symbiosis=symbiosis,
            territory=territory,
        )
        wetland_chain = build_region_wetland_chain_summary(active_region, self.registry)
        grassland_chain = build_region_grassland_chain_summary(
            active_region,
            self.registry,
            territory_summary=territory,
            social_trend_summary=social_trends,
        )
        carrion_chain = build_region_carrion_chain_summary(
            active_region,
            self.registry,
            territory_summary=territory,
            social_trend_summary=social_trends,
        )
        combined_pressures = self._build_combined_pressures(
            active_region,
            cascade,
            competition,
            carrion_chain,
            predation,
            social_trends,
            symbiosis,
            territory,
            wetland_chain,
            grassland_chain,
        )
        self._apply_long_term_health_pressures(active_region, combined_pressures)
        active_region.update_ecological_pressures(combined_pressures)

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
            "wetland_rebalancing": list(self.last_wetland_adjustments.get(active_region.region_id, [])),
            "grassland_rebalancing": list(self.last_grassland_adjustments.get(active_region.region_id, [])),
            "carrion_rebalancing": list(self.last_carrion_adjustments.get(active_region.region_id, [])),
            "predation": {
                "active_relations": len(predation.active_relations),
                "pressure_scores": dict(predation.pressure_scores),
                "vulnerable_resources": list(predation.vulnerable_resources),
                "narrative_predation": list(predation.narrative_predation),
            },
            "social_trends": {
                "trend_scores": dict(social_trends.trend_scores),
                "phase_scores": dict(social_trends.phase_scores),
                "boom_bust_scores": dict(social_trends.boom_bust_scores),
                "prosperity_scores": dict(social_trends.prosperity_scores),
                "hotspot_scores": dict(social_trends.hotspot_scores),
                "cycle_signals": list(social_trends.cycle_signals),
                "narrative_trends": list(social_trends.narrative_trends),
            },
            "symbiosis": {
                "active_relations": len(symbiosis.active_relations),
                "support_scores": dict(symbiosis.support_scores),
                "supported_resources": list(symbiosis.supported_resources),
                "narrative_symbiosis": list(symbiosis.narrative_symbiosis),
            },
            "territory": {
                "active_species": list(territory.active_species),
                "pressure_scores": dict(territory.pressure_scores),
                "contested_zones": list(territory.contested_zones),
                "narrative_territory": list(territory.narrative_territory),
                "runtime_signals": dict(territory.runtime_signals),
            },
            "wetland_chain": {
                "key_species": list(wetland_chain.key_species),
                "trophic_scores": dict(wetland_chain.trophic_scores),
                "layer_scores": dict(wetland_chain.layer_scores),
                "layer_species": {key: list(value) for key, value in wetland_chain.layer_species.items()},
                "narrative_chain": list(wetland_chain.narrative_chain),
            },
            "grassland_chain": {
                "key_species": list(grassland_chain.key_species),
                "trophic_scores": dict(grassland_chain.trophic_scores),
                "layer_scores": dict(grassland_chain.layer_scores),
                "layer_species": {key: list(value) for key, value in grassland_chain.layer_species.items()},
                "narrative_chain": list(grassland_chain.narrative_chain),
            },
            "carrion_chain": {
                "key_species": list(carrion_chain.key_species),
                "resource_scores": dict(carrion_chain.resource_scores),
                "layer_scores": dict(carrion_chain.layer_scores),
                "layer_species": {key: list(value) for key, value in carrion_chain.layer_species.items()},
                "narrative_chain": list(carrion_chain.narrative_chain),
            },
            "simulation": simulation_stats,
        }


def build_default_world_simulation() -> WorldSimulation:
    """创建默认 v4 世界模拟骨架。"""

    return WorldSimulation()

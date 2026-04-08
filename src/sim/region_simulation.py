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
        phase_scores = social_state.get("phase_scores", {})
        lion_expansion = float(phase_scores.get("lion_expansion_phase", 0.0))
        lion_contraction = float(phase_scores.get("lion_contraction_phase", 0.0))
        hyena_expansion = float(phase_scores.get("hyena_expansion_phase", 0.0))
        hyena_contraction = float(phase_scores.get("hyena_contraction_phase", 0.0))

        for animal in self.animals:
            if not animal.alive:
                continue
            if animal.species == "lion":
                animal.cycle_expansion_phase = lion_expansion
                animal.cycle_contraction_phase = lion_contraction
            elif animal.species == "hyena":
                animal.cycle_expansion_phase = hyena_expansion
                animal.cycle_contraction_phase = hyena_contraction

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

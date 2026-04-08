"""v4 世界地图骨架。"""

from dataclasses import dataclass, field
from typing import Dict, Iterable, Optional, Tuple

from .region import BiomePatch, HabitatPatch, Region, RegionConnector


@dataclass
class WorldMap:
    """多区域世界地图。"""

    name: str
    size: Tuple[int, int]
    climate_bands: Tuple[str, ...]
    regions: Dict[str, Region] = field(default_factory=dict)
    metadata: Dict[str, object] = field(default_factory=dict)

    def add_region(self, region: Region) -> None:
        self.regions[region.region_id] = region

    def get_region(self, region_id: str) -> Optional[Region]:
        return self.regions.get(region_id)

    def iter_regions(self) -> Iterable[Region]:
        return self.regions.values()


def build_default_world_map() -> WorldMap:
    """构建 v4 首批六区世界骨架。"""

    world = WorldMap(
        name="Aurelia",
        size=(1024, 512),
        climate_bands=("polar", "subarctic", "temperate", "subtropical", "tropical", "equatorial"),
        metadata={
            "version": "v4",
            "description": "首批多区域生态世界骨架",
        },
    )

    regions = [
        Region(
            region_id="temperate_forest",
            name="温带森林区",
            climate_zone="temperate",
            dominant_biomes=("temperate_forest", "mixed_forest", "river_valley"),
            simulation_size=(384, 384),
            hydrology_type="river_network",
        ),
        Region(
            region_id="temperate_grassland",
            name="温带草原区",
            climate_zone="temperate",
            dominant_biomes=("grassland", "shrubland", "seasonal_waterhole"),
            simulation_size=(384, 320),
            hydrology_type="seasonal_drainage",
        ),
        Region(
            region_id="rainforest_river",
            name="热带雨林与大河区",
            climate_zone="equatorial",
            dominant_biomes=("tropical_rainforest", "floodplain", "major_river"),
            simulation_size=(448, 448),
            hydrology_type="major_river",
        ),
        Region(
            region_id="wetland_lake",
            name="湿地与湖泊区",
            climate_zone="subtropical",
            dominant_biomes=("wetland", "lake_shore", "reed_belt"),
            simulation_size=(320, 320),
            hydrology_type="lake_system",
        ),
        Region(
            region_id="coastal_shelf",
            name="海岸与浅海区",
            climate_zone="subtropical",
            dominant_biomes=("coast", "estuary", "shallow_sea", "mangrove"),
            simulation_size=(448, 320),
            hydrology_type="coastal_exchange",
        ),
        Region(
            region_id="coral_sea",
            name="珊瑚礁海区",
            climate_zone="tropical",
            dominant_biomes=("coral_reef", "seagrass", "lagoon", "open_coast"),
            simulation_size=(384, 320),
            hydrology_type="ocean_current",
        ),
    ]

    for region in regions:
        world.add_region(region)

    connections = {
        "temperate_forest": [
            RegionConnector("temperate_grassland", "land_corridor", 0.72),
            RegionConnector("wetland_lake", "river_network", 0.88),
        ],
        "temperate_grassland": [
            RegionConnector("temperate_forest", "land_corridor", 0.72),
        ],
        "rainforest_river": [
            RegionConnector("wetland_lake", "river_network", 0.64),
            RegionConnector("coastal_shelf", "river_network", 0.92),
            RegionConnector("coral_sea", "air_migration_lane", 0.55, seasonal_bias="spring_autumn"),
        ],
        "wetland_lake": [
            RegionConnector("temperate_forest", "river_network", 0.88),
            RegionConnector("rainforest_river", "river_network", 0.64),
            RegionConnector("coastal_shelf", "air_migration_lane", 0.60, seasonal_bias="spring_autumn"),
        ],
        "coastal_shelf": [
            RegionConnector("rainforest_river", "river_network", 0.92),
            RegionConnector("wetland_lake", "air_migration_lane", 0.60, seasonal_bias="spring_autumn"),
            RegionConnector("coral_sea", "coastal_exchange", 0.86),
        ],
        "coral_sea": [
            RegionConnector("coastal_shelf", "coastal_exchange", 0.86),
            RegionConnector("rainforest_river", "air_migration_lane", 0.55, seasonal_bias="spring_autumn"),
        ],
    }

    for source, connectors in connections.items():
        region = world.get_region(source)
        if region is None:
            continue
        for connector in connectors:
            region.add_connector(connector)

    _populate_default_region_profiles(world)

    return world


def _populate_default_region_profiles(world: WorldMap) -> None:
    _configure_temperate_forest(world.get_region("temperate_forest"))
    _configure_temperate_grassland(world.get_region("temperate_grassland"))
    _configure_rainforest_river(world.get_region("rainforest_river"))
    _configure_wetland_lake(world.get_region("wetland_lake"))
    _configure_coastal_shelf(world.get_region("coastal_shelf"))
    _configure_coral_sea(world.get_region("coral_sea"))


def _configure_temperate_forest(region: Optional[Region]) -> None:
    if region is None:
        return
    region.resource_state.update(
        {
            "freshwater": 0.82,
            "canopy_cover": 0.86,
            "understory": 0.74,
            "flower_pulse": 0.42,
            "deadwood": 0.58,
        }
    )
    region.hazard_state.update({"fire_risk": 0.22, "flood_risk": 0.31, "disease_pressure": 0.28})
    region.health_state.update({"biodiversity": 0.78, "resilience": 0.73, "fragmentation": 0.21})
    region.species_pool.update(
        {
            "beaver": 2,
            "kingfisher_v4": 4,
            "bat_v4": 8,
            "night_moth": 18,
            "rabbit": 24,
            "fox": 8,
            "wolf": 4,
            "deer": 18,
            "sparrow": 20,
            "owl": 6,
            "woodpecker": 6,
        }
    )
    region.add_biome_patch(
        BiomePatch(
            "temperate_forest_core",
            (0, 0, 220, 220),
            elevation=0.38,
            moisture=0.72,
            habitats=(
                HabitatPatch("canopy_niche", (20, 20, 120, 100), vegetation_density=0.95, canopy_density=0.94),
                HabitatPatch("tree_hollow", (60, 40, 40, 40), vegetation_density=0.82, canopy_density=0.90),
                HabitatPatch("fungal_bed", (120, 120, 60, 50), vegetation_density=0.66, nutrient_load=0.72),
            ),
        )
    )
    region.add_biome_patch(
        BiomePatch(
            "river_valley",
            (220, 40, 140, 200),
            elevation=0.16,
            moisture=0.90,
            habitats=(
                HabitatPatch("riparian_perch", (250, 70, 60, 40), vegetation_density=0.70, shrub_density=0.62),
                HabitatPatch("mud_bank", (270, 180, 70, 30), water_depth=0.35, nutrient_load=0.60),
                HabitatPatch("shore_hatch", (235, 145, 80, 40), water_depth=0.22, nutrient_load=0.68),
            ),
        )
    )


def _configure_temperate_grassland(region: Optional[Region]) -> None:
    if region is None:
        return
    region.resource_state.update(
        {
            "grazing_biomass": 0.88,
            "surface_water": 0.34,
            "browse_cover": 0.28,
            "open_visibility": 0.91,
            "dung_cycle": 0.64,
        }
    )
    region.hazard_state.update({"fire_risk": 0.47, "drought_risk": 0.44, "predation_pressure": 0.57})
    region.health_state.update({"biodiversity": 0.62, "resilience": 0.69, "fragmentation": 0.18})
    region.species_pool.update(
        {
            "african_elephant": 2,
            "white_rhino": 2,
            "giraffe": 4,
            "lion": 3,
            "hyena": 4,
            "rabbit": 18,
            "fox": 7,
            "wolf": 3,
            "sparrow": 14,
            "eagle": 3,
        }
    )
    region.add_biome_patch(
        BiomePatch(
            "open_grassland",
            (0, 0, 240, 220),
            elevation=0.22,
            moisture=0.34,
            habitats=(
                HabitatPatch("open_grazing_range", (20, 20, 180, 140), vegetation_density=0.90, shrub_density=0.08),
                HabitatPatch("seasonal_waterhole", (180, 140, 40, 40), water_depth=0.44, nutrient_load=0.50),
            ),
        )
    )
    region.add_biome_patch(
        BiomePatch(
            "shrubland_margin",
            (240, 40, 110, 150),
            elevation=0.26,
            moisture=0.26,
            habitats=(
                HabitatPatch("shrub_shelter", (255, 60, 60, 80), vegetation_density=0.58, shrub_density=0.84),
                HabitatPatch("mud_bank", (290, 150, 35, 25), water_depth=0.18, nutrient_load=0.40),
            ),
        )
    )


def _configure_rainforest_river(region: Optional[Region]) -> None:
    if region is None:
        return
    region.resource_state.update(
        {
            "canopy_cover": 0.95,
            "fruit_pulse": 0.76,
            "river_nutrients": 0.73,
            "night_insects": 0.81,
            "floodplain_productivity": 0.84,
        }
    )
    region.hazard_state.update({"flood_risk": 0.62, "parasite_pressure": 0.58, "storm_risk": 0.37})
    region.health_state.update({"biodiversity": 0.93, "resilience": 0.80, "fragmentation": 0.11})
    region.species_pool.update(
        {
            "african_elephant": 1,
            "hippopotamus": 4,
            "nile_crocodile": 3,
            "kingfisher_v4": 5,
            "bat_v4": 10,
            "night_moth": 24,
            "frog": 22,
            "minnow": 20,
            "catfish": 10,
            "blackfish": 8,
        }
    )
    region.add_biome_patch(
        BiomePatch(
            "rainforest_core",
            (0, 0, 240, 260),
            elevation=0.30,
            moisture=0.94,
            temperature_bias=0.24,
            habitats=(
                HabitatPatch("canopy_niche", (30, 20, 130, 90), vegetation_density=0.98, canopy_density=0.98),
                HabitatPatch("flower_patch", (120, 160, 70, 50), vegetation_density=0.72, canopy_density=0.48, nutrient_load=0.42),
                HabitatPatch("night_swarm", (70, 190, 90, 45), vegetation_density=0.64, nutrient_load=0.74),
            ),
        )
    )
    region.add_biome_patch(
        BiomePatch(
            "major_river",
            (240, 40, 180, 300),
            elevation=0.08,
            moisture=0.98,
            habitats=(
                HabitatPatch("riparian_perch", (260, 70, 55, 50), vegetation_density=0.60, shrub_density=0.52),
                HabitatPatch("shore_hatch", (255, 220, 90, 50), water_depth=0.24, nutrient_load=0.82),
                HabitatPatch("shallow_spawn_bed", (325, 180, 70, 60), water_depth=0.38, oxygen_level=0.88, nutrient_load=0.66),
            ),
        )
    )


def _configure_wetland_lake(region: Optional[Region]) -> None:
    if region is None:
        return
    region.resource_state.update(
        {
            "reed_cover": 0.85,
            "shore_hatch": 0.78,
            "open_water": 0.72,
            "benthic_food": 0.67,
            "nesting_cover": 0.64,
        }
    )
    region.hazard_state.update({"drought_risk": 0.29, "eutrophication_risk": 0.41, "predation_pressure": 0.54})
    region.health_state.update({"biodiversity": 0.84, "resilience": 0.77, "fragmentation": 0.17})
    region.species_pool.update(
        {
            "hippopotamus": 2,
            "nile_crocodile": 2,
            "beaver": 3,
            "kingfisher_v4": 6,
            "bat_v4": 7,
            "night_moth": 16,
            "frog": 26,
            "minnow": 18,
            "pike": 7,
            "catfish": 8,
            "blackfish": 8,
        }
    )
    region.add_biome_patch(
        BiomePatch(
            "lake_shore",
            (0, 0, 180, 180),
            elevation=0.10,
            moisture=0.96,
            habitats=(
                HabitatPatch("reed_belt", (20, 30, 70, 90), vegetation_density=0.88, shrub_density=0.22),
                HabitatPatch("riparian_perch", (90, 25, 50, 40), vegetation_density=0.58, shrub_density=0.66),
                HabitatPatch("shore_hatch", (70, 120, 90, 45), water_depth=0.20, nutrient_load=0.79),
            ),
        )
    )
    region.add_biome_patch(
        BiomePatch(
            "open_lake",
            (180, 20, 120, 220),
            elevation=0.02,
            moisture=0.99,
            habitats=(
                HabitatPatch("shallow_spawn_bed", (195, 40, 55, 60), water_depth=0.34, oxygen_level=0.87, nutrient_load=0.69),
                HabitatPatch("mud_bank", (210, 190, 70, 25), water_depth=0.14, nutrient_load=0.56),
            ),
        )
    )


def _configure_coastal_shelf(region: Optional[Region]) -> None:
    if region is None:
        return
    region.resource_state.update(
        {
            "seagrass_cover": 0.72,
            "tidal_exchange": 0.83,
            "nursery_habitat": 0.76,
            "shellfish_beds": 0.61,
            "salinity_gradient": 0.68,
        }
    )
    region.hazard_state.update({"storm_surge_risk": 0.52, "salinity_stress": 0.47, "pollution_risk": 0.33})
    region.health_state.update({"biodiversity": 0.79, "resilience": 0.71, "fragmentation": 0.24})
    region.species_pool.update(
        {
            "nile_crocodile": 1,
            "kingfisher_v4": 3,
            "shrimp": 18,
            "crab": 14,
            "small_fish": 22,
            "minnow": 8,
        }
    )
    region.add_biome_patch(
        BiomePatch(
            "mangrove_estuary",
            (0, 0, 170, 160),
            elevation=0.04,
            moisture=0.96,
            habitats=(
                HabitatPatch("mangrove_root", (20, 20, 90, 90), vegetation_density=0.82, shrub_density=0.58, salinity=0.46),
                HabitatPatch("tide_pool", (115, 85, 40, 40), water_depth=0.28, salinity=0.52, nutrient_load=0.62),
            ),
        )
    )
    region.add_biome_patch(
        BiomePatch(
            "shallow_shelf",
            (170, 20, 220, 180),
            elevation=-0.08,
            moisture=0.94,
            habitats=(
                HabitatPatch("seagrass_refuge", (190, 50, 95, 80), water_depth=0.42, oxygen_level=0.84, nutrient_load=0.55),
                HabitatPatch("cleaning_station", (305, 70, 45, 40), water_depth=0.58, salinity=0.71, oxygen_level=0.89),
            ),
        )
    )


def _configure_coral_sea(region: Optional[Region]) -> None:
    if region is None:
        return
    region.resource_state.update(
        {
            "reef_complexity": 0.94,
            "clear_water": 0.88,
            "plankton_pulse": 0.52,
            "cleaning_network": 0.74,
            "grazing_pressure_balance": 0.69,
        }
    )
    region.hazard_state.update({"bleaching_risk": 0.36, "storm_damage": 0.41, "predation_pressure": 0.44})
    region.health_state.update({"biodiversity": 0.95, "resilience": 0.76, "fragmentation": 0.14})
    region.species_pool.update(
        {
            "small_fish": 26,
            "large_fish": 12,
            "shrimp": 16,
            "crab": 10,
            "pufferfish": 8,
        }
    )
    region.add_biome_patch(
        BiomePatch(
            "coral_reef",
            (0, 0, 220, 180),
            elevation=-0.12,
            moisture=0.92,
            temperature_bias=0.18,
            habitats=(
                HabitatPatch("reef_crevice", (30, 25, 100, 90), water_depth=0.68, salinity=0.82, oxygen_level=0.91),
                HabitatPatch("cleaning_station", (140, 60, 45, 45), water_depth=0.74, salinity=0.84, oxygen_level=0.93),
            ),
        )
    )
    region.add_biome_patch(
        BiomePatch(
            "lagoon",
            (220, 40, 130, 140),
            elevation=-0.04,
            moisture=0.88,
            habitats=(
                HabitatPatch("seagrass_refuge", (240, 70, 70, 55), water_depth=0.40, salinity=0.75, oxygen_level=0.87),
                HabitatPatch("tide_pool", (285, 130, 35, 25), water_depth=0.22, salinity=0.70, nutrient_load=0.48),
            ),
        )
    )

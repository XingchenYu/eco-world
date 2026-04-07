"""v4 世界地图骨架。"""

from dataclasses import dataclass, field
from typing import Dict, Iterable, Optional, Tuple

from .region import Region, RegionConnector


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

    return world

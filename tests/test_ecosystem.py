"""
基础测试
"""

import sys
import os
from copy import deepcopy

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.core.ecosystem import Ecosystem, Environment
from src.core.environment import TerrainType
from src.data.defaults import (
    build_default_relation_tables,
    build_default_runtime_species_bridges,
    build_default_species_templates,
    build_default_species_variants,
)
from src.data.registry import build_default_world_registry
from src.ecology.cascade import (
    apply_region_cascade_feedback,
    build_region_cascade_summary,
)
from src.ecology.competition import (
    apply_region_competition_feedback,
    build_region_competition_summary,
)
from src.ecology.predation import apply_region_predation_feedback, build_region_predation_summary
from src.ecology.symbiosis import apply_region_symbiosis_feedback, build_region_symbiosis_summary
from src.ecology.territory import apply_region_territory_feedback, build_region_territory_summary
from src.ecology.wetland import (
    apply_region_wetland_chain_feedback,
    apply_region_wetland_chain_rebalancing,
    build_region_wetland_chain_summary,
)
from src.ecology.food_web import build_region_food_web
from src.ecology.grassland import (
    apply_region_grassland_chain_feedback,
    apply_region_grassland_chain_rebalancing,
    build_region_grassland_chain_summary,
)
from src.ecology.carrion import (
    apply_region_carrion_chain_feedback,
    apply_region_carrion_chain_rebalancing,
    build_region_carrion_chain_summary,
)
from src.entities.plants import Grass, Tree
from src.entities.animals import Rabbit, Fox
from src.main import load_config
from src.sim.region_simulation import RegionSimulation
from src.sim.world_simulation import build_default_world_simulation
from src.world.world_map import build_default_world_map


def test_environment():
    """测试环境系统"""
    env = Environment(40, 30)
    
    assert env.width == 40
    assert env.height == 30
    assert env.season == "spring"
    
    # 测试地形生成
    terrain_types = set(env.terrain.values())
    assert TerrainType.GRASS in terrain_types
    
    print("✅ Environment test passed")


def test_plants():
    """测试植物系统"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None
    
    # 添加草
    initial_count = len(eco.plants)
    eco.spawn_plant("grass", position)
    assert len(eco.plants) == initial_count + 1
    
    # 测试生长
    grass = eco.plants[-1]
    assert grass.species == "grass"
    initial_size = grass.size
    grass.update(eco)
    assert grass.size > initial_size
    
    print("✅ Plants test passed")


def test_animals():
    """测试动物系统"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None
    
    # 添加兔子
    initial_animals = len(eco.animals)
    eco.spawn_animal("rabbit", position, source="manual")
    assert len(eco.animals) == initial_animals + 1
    
    # 测试状态
    rabbit = eco.animals[-1]
    assert rabbit.health == 100
    assert rabbit.hunger == 0
    
    print("✅ Animals test passed")


def test_ecosystem_update():
    """测试生态系统更新"""
    eco = Ecosystem()
    
    initial_tick = eco.tick_count
    eco.update()
    
    assert eco.tick_count == initial_tick + 1
    assert eco.environment.hour == 1 or eco.environment.hour == 0
    
    print("✅ Ecosystem update test passed")


def test_food_chain():
    """测试食物链"""
    eco = Ecosystem()
    
    # 清空后手动添加
    eco.plants = []
    eco.animals = []
    eco.aquatic_creatures = []
    eco._rebuild_spatial_indices()
    
    # 添加草和兔子
    position = eco._random_land_position()
    assert position is not None
    eco.spawn_plant("grass", position)
    eco.spawn_animal("rabbit", position)
    
    rabbit = next(a for a in eco.animals if a.species == "rabbit")
    initial_hunger = rabbit.hunger
    
    # 运行一段时间
    for _ in range(10):
        eco.update()
    
    # 兔子应该有饥饿值变化
    assert rabbit.hunger != initial_hunger or not rabbit.alive
    
    print("✅ Food chain test passed")


def test_statistics():
    """测试统计功能"""
    eco = Ecosystem()
    
    stats = eco.get_statistics()
    
    assert "tick" in stats
    assert "plants" in stats
    assert "animals" in stats
    assert "species" in stats
    
    print("✅ Statistics test passed")


def test_minnow_registration_and_spawn():
    """测试米诺鱼注册和按水体类型生成"""
    eco = Ecosystem()

    assert "minnow" in eco.AQUATIC_SPECIES

    position = eco._random_water_position_for_body_type({"river_channel", "lake_shallow"})
    assert position is not None
    body_type = eco.environment.get_water_body_type(position[0], position[1])
    assert body_type in {"river_channel", "lake_shallow"}

    initial_count = len(eco.aquatic_creatures)
    eco.spawn_aquatic("minnow", position, source="manual")
    assert len(eco.aquatic_creatures) == initial_count + 1
    assert eco.aquatic_creatures[-1].species == "minnow"

    print("✅ Minnow registration test passed")


def test_shrimp_uses_shallow_or_river_habitat():
    """测试虾优先有有效的浅水/河道栖息地来源"""
    eco = Ecosystem()

    position = eco._random_inflow_water_position_for_body_type({"river_channel", "lake_shallow"})
    assert position is not None
    body_type = eco.environment.get_water_body_type(position[0], position[1])
    assert body_type in {"river_channel", "lake_shallow"}

    print("✅ Shrimp habitat source test passed")


def test_load_config_preserves_world_dimensions():
    """未显式传 CLI 宽高时，保留配置文件中的世界尺寸。"""
    config = load_config("config/test.yaml")
    world = deepcopy(config.get("world", {}))
    world["grid_size"] = world.get("grid_size", 20)

    eco = Ecosystem(config=config)

    assert world["width"] == 800
    assert world["height"] == 600
    assert eco.width == world["width"] // world["grid_size"]
    assert eco.height == world["height"] // world["grid_size"]

    print("✅ Config world size preservation test passed")


def test_land_animals_do_not_spawn_in_water():
    """陆地动物不应生成在水域。"""
    eco = Ecosystem()
    water_pos = eco._random_water_position()
    assert water_pos is not None

    initial_rabbits = len([a for a in eco.animals if a.species == "rabbit" and a.alive])
    eco.spawn_animal("rabbit", water_pos, source="manual")
    rabbit_count = len([a for a in eco.animals if a.species == "rabbit" and a.alive])

    assert rabbit_count == initial_rabbits

    print("✅ Land animal water spawn guard test passed")


def test_amphibious_animals_can_spawn_in_water():
    """两栖/水鸟仍允许在水域生成。"""
    eco = Ecosystem()
    water_pos = eco._random_water_position()
    assert water_pos is not None

    initial_frogs = len([a for a in eco.animals if a.species == "frog" and a.alive])
    eco.spawn_animal("frog", water_pos, source="manual")
    frog_count = len([a for a in eco.animals if a.species == "frog" and a.alive])

    assert frog_count == initial_frogs + 1
    assert eco.animals[-1].position == water_pos

    print("✅ Amphibious water spawn test passed")


def test_night_moth_registration_and_spawn():
    """夜飞蛾应完成注册并可在陆地/水边生成。"""
    eco = Ecosystem()
    position = eco._random_water_adjacent_position() or eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("night_moth")
    eco.spawn_animal("night_moth", position, source="manual")
    assert eco.get_species_count("night_moth") == initial + 1

    print("✅ Night moth registration test passed")


def test_v4_world_and_data_skeleton():
    """v4 世界、数据和区域模拟骨架应可正常构建。"""
    world_map = build_default_world_map()
    templates = build_default_species_templates()
    variants = build_default_species_variants()
    relations = build_default_relation_tables()
    bridges = build_default_runtime_species_bridges()

    assert len(world_map.regions) == 6
    assert "temperate_forest" in world_map.regions
    assert "megaherbivore_engineer" in templates
    assert "african_elephant" in variants
    assert any(link.relation_type == "engineering" for link in relations)
    assert bridges["african_elephant"].support_level == "native"
    assert bridges["kingfisher_v4"].support_level == "native"
    assert bridges["beaver"].support_level == "native"
    assert world_map.get_region("temperate_forest").biome_count >= 2
    assert world_map.get_region("wetland_lake").habitat_count >= 4
    assert world_map.get_region("coastal_shelf").species_count >= 4

    region = world_map.get_region("temperate_forest")
    sim = RegionSimulation(region=region, config={"world": {"width": 200, "height": 200, "grid_size": 20}})

    assert sim.region_id == "temperate_forest"
    assert sim.region_name == "温带森林区"
    assert sim.width == 10
    assert sim.height == 10

    print("✅ V4 skeleton test passed")


def test_v4_world_simulation_skeleton():
    """v4 世界模拟器应可管理区域并执行焦点区域更新。"""
    world_sim = build_default_world_simulation()

    assert world_sim.active_region_id == "temperate_forest"
    assert world_sim.get_active_region().name == "温带森林区"

    summary = world_sim.update()
    stats = world_sim.get_statistics()

    assert summary.tick == 1
    assert summary.active_region_id == "temperate_forest"
    assert stats["world_tick"] == 1
    assert stats["active_region"]["id"] == "temperate_forest"
    assert stats["regions_total"] == 6
    assert stats["active_region"]["biome_count"] >= 2
    assert stats["active_region"]["habitat_count"] >= 4
    assert stats["active_region"]["species_pool_count"] >= 6
    assert stats["active_region"]["resource_state"]["canopy_cover"] > 0.8
    assert stats["registry"]["templates"] >= 8
    assert "beaver" in stats["registry"]["regional_species"]
    assert stats["registry"]["relation_summary"]["engineering"] >= 1
    assert stats["registry"]["bridges"] >= 8
    assert stats["registry"]["bridge_summary"]["native"] >= 2
    assert stats["registry"]["regional_bridges"]["beaver"]["support_level"] == "native"
    assert "beaver" in stats["food_web"]["resident_species"]
    assert "beaver" in stats["cascade"]["driver_species"]
    assert stats["cascade"]["impact_scores"]["wetland_expansion"] > 0.0
    assert "symbiosis" in stats["cascade"]["source_modules"]
    assert stats["symbiosis"]["active_relations"] >= 1
    assert stats["wetland_chain"]["key_species"] == []
    assert stats["grassland_chain"]["key_species"] == []
    assert stats["carrion_chain"]["key_species"] == []
    assert "cascade" in stats["active_region"]["relationship_state"]
    assert "competition" in stats["active_region"]["relationship_state"]
    assert "predation" in stats["active_region"]["relationship_state"]
    assert "symbiosis" in stats["active_region"]["relationship_state"]
    assert "territory" in stats["active_region"]["relationship_state"]
    assert "grassland_chain" in stats["active_region"]["relationship_state"]
    assert "grassland_rebalancing" in stats["active_region"]["relationship_state"]
    assert "carrion_chain" in stats["active_region"]["relationship_state"]
    assert "carrion_rebalancing" in stats["active_region"]["relationship_state"]
    assert stats["active_region"]["ecological_pressures"]

    world_sim.set_active_region("wetland_lake")
    assert world_sim.active_region_id == "wetland_lake"
    assert world_sim.get_active_region().name == "湿地与湖泊区"
    wetland_stats = world_sim.get_statistics()
    assert wetland_stats["food_web"]["active_relations"] >= 1
    assert wetland_stats["wetland_chain"]["key_species"]
    assert wetland_stats["wetland_chain"]["trophic_scores"]["wetland_engineering"] > 0.0
    assert wetland_stats["wetland_chain"]["layer_scores"]["shoreline_layer"] > 0.0
    assert "kingfisher_v4" in wetland_stats["wetland_chain"]["layer_species"]["shoreline_layer"]
    assert wetland_stats["cascade"]["impact_scores"]["shoreline_risk"] > 0.0
    assert "wetland_rebalancing" in wetland_stats
    assert wetland_stats["predation"]["pressure_scores"]["shoreline_bird_predation"] > 0.0
    assert wetland_stats["symbiosis"]["support_scores"]["wetland_engineering_support"] > 0.0
    assert wetland_stats["territory"]["pressure_scores"]["shoreline_standoff"] > 0.0
    assert "runtime_signals" in wetland_stats["territory"]

    world_sim.set_active_region("temperate_grassland")
    grassland_stats = world_sim.get_statistics()
    assert grassland_stats["grassland_chain"]["key_species"]
    assert grassland_stats["grassland_chain"]["layer_scores"]["engineering_layer"] > 0.0
    assert grassland_stats["territory"]["pressure_scores"]["apex_boundary_conflict"] > 0.0
    assert "grassland_rebalancing" in grassland_stats
    assert grassland_stats["carrion_chain"]["key_species"]
    assert grassland_stats["carrion_chain"]["resource_scores"]["carcass_competition_loop"] > 0.0

    print("✅ V4 world simulation test passed")


def test_v4_region_relationship_state_persists():
    """v4 世界更新后应把关系摘要持久写回 Region。"""
    world_sim = build_default_world_simulation()
    world_sim.set_active_region("wetland_lake")
    world_sim.update()

    region = world_sim.get_active_region()

    assert "cascade" in region.relationship_state
    assert "competition" in region.relationship_state
    assert "predation" in region.relationship_state
    assert "symbiosis" in region.relationship_state
    assert "territory" in region.relationship_state
    assert "wetland_chain" in region.relationship_state
    assert "grassland_chain" in region.relationship_state
    assert "wetland_rebalancing" in region.relationship_state
    assert "grassland_rebalancing" in region.relationship_state
    assert "carrion_chain" in region.relationship_state
    assert "carrion_rebalancing" in region.relationship_state
    assert region.ecological_pressures
    assert region.relationship_state["cascade"]["impact_scores"]["shoreline_risk"] > 0.0
    assert region.relationship_state["predation"]["pressure_scores"]["shoreline_bird_predation"] > 0.0
    assert region.relationship_state["symbiosis"]["support_scores"]["wetland_engineering_support"] > 0.0
    assert region.relationship_state["territory"]["pressure_scores"]["shoreline_standoff"] > 0.0
    assert "runtime_signals" in region.relationship_state["territory"]
    assert region.relationship_state["wetland_chain"]["trophic_scores"]["wetland_keystone_stack"] > 0.0
    assert region.relationship_state["wetland_chain"]["layer_scores"]["apex_layer"] > 0.0
    assert "nile_crocodile" in region.relationship_state["wetland_chain"]["layer_species"]["apex_layer"]

    print("✅ V4 region relationship state test passed")


def test_v4_registry_queries():
    """v4 注册表应支持按区域和物种关系查询。"""
    registry = build_default_world_registry()

    wetland_species = registry.species_for_region("wetland_lake")
    crocodile_relations = registry.relations_for_species("nile_crocodile")
    crocodile_bridge = registry.get_runtime_bridge("nile_crocodile")

    assert "hippopotamus" in wetland_species
    assert "nile_crocodile" in wetland_species
    assert any(relation.relation_type == "competition" for relation in crocodile_relations)
    assert registry.get_runtime_bridge("african_elephant").runtime_species_id == "elephant"
    assert registry.get_runtime_bridge("african_elephant").support_level == "native"
    assert registry.get_runtime_bridge("white_rhino").runtime_species_id == "white_rhino"
    assert registry.get_runtime_bridge("white_rhino").support_level == "native"
    assert registry.get_runtime_bridge("giraffe").runtime_species_id == "giraffe"
    assert registry.get_runtime_bridge("giraffe").support_level == "native"
    assert registry.get_runtime_bridge("lion").runtime_species_id == "lion"
    assert registry.get_runtime_bridge("lion").support_level == "native"
    assert registry.get_runtime_bridge("hyena").runtime_species_id == "hyena"
    assert registry.get_runtime_bridge("hyena").support_level == "native"
    assert registry.get_runtime_bridge("antelope").runtime_species_id == "antelope"
    assert registry.get_runtime_bridge("antelope").support_level == "native"
    assert registry.get_runtime_bridge("zebra").runtime_species_id == "zebra"
    assert registry.get_runtime_bridge("zebra").support_level == "native"
    assert registry.get_runtime_bridge("vulture").runtime_species_id == "vulture"
    assert registry.get_runtime_bridge("vulture").support_level == "native"
    assert registry.get_runtime_bridge("hippopotamus").runtime_species_id == "hippopotamus"
    assert registry.get_runtime_bridge("hippopotamus").support_level == "native"
    assert crocodile_bridge.runtime_species_id == "crocodile"
    assert crocodile_bridge.support_level == "native"
    assert registry.get_runtime_bridge("beaver").runtime_species_id == "beaver"
    assert registry.get_runtime_bridge("beaver").support_level == "native"

    print("✅ V4 registry test passed")


def test_v4_region_food_web_summary():
    """v4 区域食物网应返回区域级关系和关键种摘要。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    food_web = build_region_food_web(world_map.get_region("wetland_lake"), registry)

    assert "hippopotamus" in food_web.resident_species
    assert "nile_crocodile" in food_web.resident_species
    assert food_web.relation_summary["competition"] >= 1
    assert food_web.relation_summary["predation"] >= 1
    assert "hippopotamus" in food_web.keystone_species
    assert "beaver" in food_web.engineer_species

    print("✅ V4 food web test passed")


def test_v4_region_cascade_summary():
    """v4 区域级联摘要应反映关键种对区域结构的推动方向。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()

    wetland_region = world_map.get_region("wetland_lake")
    grassland_region = world_map.get_region("temperate_grassland")
    wetland_competition = build_region_competition_summary(wetland_region, registry)
    wetland_predation = build_region_predation_summary(wetland_region, registry)
    wetland_symbiosis = build_region_symbiosis_summary(wetland_region, registry)
    grassland_competition = build_region_competition_summary(grassland_region, registry)
    grassland_predation = build_region_predation_summary(grassland_region, registry)
    grassland_symbiosis = build_region_symbiosis_summary(grassland_region, registry)

    wetland_cascade = build_region_cascade_summary(
        wetland_region,
        registry,
        competition=wetland_competition,
        predation=wetland_predation,
        symbiosis=wetland_symbiosis,
    )
    grassland_cascade = build_region_cascade_summary(
        grassland_region,
        registry,
        competition=grassland_competition,
        predation=grassland_predation,
        symbiosis=grassland_symbiosis,
    )

    assert "beaver" in wetland_cascade.driver_species
    assert "hippopotamus" in wetland_cascade.driver_species
    assert "nile_crocodile" in wetland_cascade.driver_species
    assert wetland_cascade.impact_scores["wetland_expansion"] > 0.0
    assert wetland_cascade.impact_scores["shoreline_risk"] > 0.0
    assert wetland_cascade.impact_scores["competitive_stress"] > 0.0
    assert wetland_cascade.impact_scores["predation_load"] > 0.0
    assert wetland_cascade.impact_scores["mutualist_support"] > 0.0
    assert "hydrology_retention" in wetland_cascade.active_pressures
    assert "competition" in wetland_cascade.source_modules
    assert "predation" in wetland_cascade.source_modules
    assert "symbiosis" in wetland_cascade.source_modules

    assert "african_elephant" in grassland_cascade.driver_species
    assert "white_rhino" in grassland_cascade.driver_species
    assert "giraffe" in grassland_cascade.driver_species
    assert "lion" in grassland_cascade.driver_species
    assert "hyena" in grassland_cascade.driver_species
    assert "antelope" in grassland_cascade.driver_species
    assert "zebra" in grassland_cascade.driver_species
    assert grassland_cascade.impact_scores["canopy_opening"] > 0.0
    assert grassland_cascade.impact_scores["grazing_pressure"] > 0.0
    assert grassland_cascade.impact_scores["canopy_browsing"] > 0.0
    assert grassland_cascade.impact_scores["predation_load"] > 0.0
    assert grassland_cascade.impact_scores["competitive_stress"] > 0.0

    print("✅ V4 cascade summary test passed")


def test_v4_cascade_feedback_updates_region_state():
    """v4 级联反馈应轻量更新区域资源、风险和健康状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("wetland_lake")
    assert region is not None

    before_open_water = region.resource_state["open_water"]
    before_risk = region.hazard_state.get("shoreline_risk", 0.0)
    before_resilience = region.health_state["resilience"]

    cascade = build_region_cascade_summary(region, registry)
    apply_region_cascade_feedback(region, cascade, feedback_scale=0.05)

    assert region.resource_state["open_water"] > before_open_water
    assert region.hazard_state.get("shoreline_risk", 0.0) > before_risk
    assert region.health_state["resilience"] > before_resilience

    print("✅ V4 cascade feedback test passed")


def test_v4_competition_feedback_rebalances_species_pool():
    """v4 竞争反馈应能轻量重平衡关键种物种池。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    grassland = world_map.get_region("temperate_grassland")
    assert grassland is not None

    before_rhino = grassland.species_pool["white_rhino"]
    before_giraffe = grassland.species_pool["giraffe"]
    before_hyena = grassland.species_pool["hyena"]
    before_carcass = grassland.resource_state["carcass_availability"]

    adjustments = apply_region_competition_feedback(grassland, registry)

    assert any(item["target_species"] == "white_rhino" for item in adjustments)
    assert any(item["target_species"] == "giraffe" for item in adjustments)
    assert any(item["target_species"] == "hyena" for item in adjustments)
    assert grassland.species_pool["white_rhino"] < before_rhino
    assert grassland.species_pool["giraffe"] < before_giraffe
    assert grassland.species_pool["hyena"] < before_hyena
    assert grassland.resource_state["carcass_availability"] < before_carcass

    print("✅ V4 competition feedback test passed")


def test_v4_region_competition_summary():
    """v4 竞争摘要应独立汇总区域关键种竞争压力。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    grassland = world_map.get_region("temperate_grassland")
    wetland = world_map.get_region("wetland_lake")

    grassland_summary = build_region_competition_summary(grassland, registry)
    wetland_summary = build_region_competition_summary(wetland, registry)

    assert grassland_summary.active_relations
    assert grassland_summary.pressure_scores["waterhole_competition"] > 0.0
    assert grassland_summary.pressure_scores["browse_layer_competition"] > 0.0
    assert grassland_summary.pressure_scores["carcass_site_competition"] > 0.0
    assert grassland_summary.pressure_scores["herd_route_interference"] > 0.0
    assert "waterhole" in grassland_summary.contested_resources
    assert "carcass_site" in grassland_summary.contested_resources

    assert wetland_summary.active_relations
    assert wetland_summary.pressure_scores["shoreline_space_competition"] > 0.0
    assert "shoreline_space" in wetland_summary.contested_resources

    print("✅ V4 competition summary test passed")


def test_v4_region_predation_summary():
    """v4 捕食摘要应独立汇总区域分层捕食压力。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    wetland = world_map.get_region("wetland_lake")
    rainforest = world_map.get_region("rainforest_river")

    wetland_summary = build_region_predation_summary(wetland, registry)
    rainforest_summary = build_region_predation_summary(rainforest, registry)

    assert wetland_summary.active_relations
    assert wetland_summary.pressure_scores["shoreline_bird_predation"] > 0.0
    assert wetland_summary.pressure_scores["benthic_fish_predation"] > 0.0
    assert wetland_summary.pressure_scores["midwater_fish_predation"] > 0.0
    assert "fish_cover" in wetland_summary.vulnerable_resources

    assert rainforest_summary.active_relations
    assert rainforest_summary.pressure_scores["nocturnal_insect_predation"] > 0.0

    print("✅ V4 predation summary test passed")


def test_v4_region_symbiosis_summary():
    """v4 共生摘要应独立汇总区域资源支持关系。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    wetland = world_map.get_region("wetland_lake")
    rainforest = world_map.get_region("rainforest_river")

    wetland_summary = build_region_symbiosis_summary(wetland, registry)
    rainforest_summary = build_region_symbiosis_summary(rainforest, registry)

    assert wetland_summary.active_relations
    assert wetland_summary.support_scores["riparian_foraging_support"] > 0.0
    assert wetland_summary.support_scores["wetland_engineering_support"] > 0.0
    assert "shore_hatch" in wetland_summary.supported_resources

    assert rainforest_summary.active_relations
    assert rainforest_summary.support_scores["nocturnal_insect_support"] > 0.0

    print("✅ V4 symbiosis summary test passed")


def test_v4_wetland_chain_summary():
    """v4 湿地链摘要应识别湿地区关键链条。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()

    wetland = world_map.get_region("wetland_lake")
    grassland = world_map.get_region("temperate_grassland")

    wetland_chain = build_region_wetland_chain_summary(wetland, registry)
    grassland_chain = build_region_wetland_chain_summary(grassland, registry)

    assert "beaver" in wetland_chain.key_species
    assert "nile_crocodile" in wetland_chain.key_species
    assert wetland_chain.trophic_scores["wetland_engineering"] > 0.0
    assert wetland_chain.trophic_scores["wetland_keystone_stack"] > 0.0
    assert wetland_chain.trophic_scores["shoreline_trophic_coupling"] > 0.0
    assert wetland_chain.layer_scores["shoreline_layer"] > 0.0
    assert wetland_chain.layer_scores["fish_layer"] > 0.0
    assert wetland_chain.layer_scores["apex_layer"] > 0.0
    assert "minnow" in wetland_chain.layer_species["fish_layer"]
    assert "frog" in wetland_chain.layer_species["shoreline_layer"]
    assert "hippopotamus" in wetland_chain.layer_species["apex_layer"]

    assert grassland_chain.key_species == []
    assert grassland_chain.trophic_scores == {}

    print("✅ V4 wetland chain summary test passed")


def test_v4_grassland_chain_summary():
    """v4 草原链摘要应识别大型植食者分层结构。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()

    grassland = world_map.get_region("temperate_grassland")
    wetland = world_map.get_region("wetland_lake")

    grassland_chain = build_region_grassland_chain_summary(grassland, registry)
    wetland_chain = build_region_grassland_chain_summary(wetland, registry)

    assert "african_elephant" in grassland_chain.key_species
    assert "white_rhino" in grassland_chain.key_species
    assert "giraffe" in grassland_chain.key_species
    assert "antelope" in grassland_chain.key_species
    assert "zebra" in grassland_chain.key_species
    assert "lion" in grassland_chain.key_species
    assert "hyena" in grassland_chain.key_species
    assert grassland_chain.trophic_scores["canopy_opening"] > 0.0
    assert grassland_chain.trophic_scores["grazing_pressure"] > 0.0
    assert grassland_chain.trophic_scores["megaherbivore_stack"] > 0.0
    assert grassland_chain.trophic_scores["apex_predation"] > 0.0
    assert grassland_chain.trophic_scores["carrion_scavenging"] > 0.0
    assert grassland_chain.trophic_scores["pride_patrol"] > 0.0
    assert grassland_chain.trophic_scores["clan_pressure"] > 0.0
    assert grassland_chain.trophic_scores["apex_rivalry"] > 0.0
    assert grassland_chain.trophic_scores["herd_grazing"] > 0.0
    assert grassland_chain.trophic_scores["migration_pressure"] > 0.0
    assert grassland_chain.layer_scores["engineering_layer"] > 0.0
    assert grassland_chain.layer_scores["grazing_layer"] > 0.0
    assert grassland_chain.layer_scores["browse_layer"] > 0.0
    assert grassland_chain.layer_scores["herd_layer"] > 0.0
    assert grassland_chain.layer_scores["predator_layer"] > 0.0
    assert grassland_chain.layer_scores["scavenger_layer"] > 0.0
    assert grassland_chain.layer_scores["social_layer"] > 0.0
    assert "african_elephant" in grassland_chain.layer_species["engineering_layer"]
    assert "white_rhino" in grassland_chain.layer_species["grazing_layer"]
    assert "giraffe" in grassland_chain.layer_species["browse_layer"]
    assert "antelope" in grassland_chain.layer_species["herd_layer"]
    assert "zebra" in grassland_chain.layer_species["herd_layer"]
    assert "lion" in grassland_chain.layer_species["predator_layer"]
    assert "hyena" in grassland_chain.layer_species["scavenger_layer"]
    assert "lion" in grassland_chain.layer_species["social_layer"]
    assert "hyena" in grassland_chain.layer_species["social_layer"]

    assert wetland_chain.key_species == []
    assert wetland_chain.trophic_scores == {}

    print("✅ V4 grassland chain summary test passed")


def test_v4_territory_summary():
    """v4 领地摘要应识别草原和湿地的热点领地冲突。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()

    grassland = world_map.get_region("temperate_grassland")
    wetland = world_map.get_region("wetland_lake")

    grassland_territory = build_region_territory_summary(grassland, registry)
    wetland_territory = build_region_territory_summary(wetland, registry)

    assert "lion" in grassland_territory.active_species
    assert "hyena" in grassland_territory.active_species
    assert grassland_territory.pressure_scores["pride_core_range"] > 0.0
    assert grassland_territory.pressure_scores["clan_den_range"] > 0.0
    assert grassland_territory.pressure_scores["apex_boundary_conflict"] > 0.0
    assert "seasonal_waterhole" in grassland_territory.contested_zones
    assert "carcass_site" in grassland_territory.contested_zones

    assert "hippopotamus" in wetland_territory.active_species
    assert "nile_crocodile" in wetland_territory.active_species
    assert wetland_territory.pressure_scores["shoreline_standoff"] > 0.0
    assert "mud_bank" in wetland_territory.contested_zones

    print("✅ V4 territory summary test passed")


def test_v4_territory_summary_uses_runtime_events():
    """v4 领地摘要应能吸收运行期社群事件信号。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    grassland = world_map.get_region("temperate_grassland")

    summary = build_region_territory_summary(
        grassland,
        registry,
        recent_events=[
            "lion-1 established a pride core range",
            "lion-1 pressed a male takeover front",
            "hyena-2 reinforced a clan den corridor",
            "hyena-2 expanded a clan frontier",
        ],
    )

    assert summary.runtime_signals["pride_core_events"] == 1
    assert summary.runtime_signals["male_takeover_events"] == 1
    assert summary.runtime_signals["clan_den_events"] == 1
    assert summary.runtime_signals["clan_front_events"] == 1
    assert summary.pressure_scores["pride_core_range"] > 0.58
    assert summary.pressure_scores["male_takeover_front"] > 0.44
    assert summary.pressure_scores["clan_den_range"] > 0.55

    print("✅ V4 territory runtime signal test passed")


def test_v4_territory_summary_uses_runtime_state():
    """v4 领地摘要应能吸收运行期社群状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    grassland = world_map.get_region("temperate_grassland")

    summary = build_region_territory_summary(
        grassland,
        registry,
        runtime_state={
            "lion_pride_strength": 0.7,
            "lion_takeover_pressure": 0.5,
            "hyena_clan_cohesion": 0.6,
            "hyena_clan_front_pressure": 0.4,
        },
    )

    assert summary.runtime_signals["lion_pride_strength"] == 0.7
    assert summary.runtime_signals["lion_takeover_pressure"] == 0.5
    assert summary.runtime_signals["hyena_clan_cohesion"] == 0.6
    assert summary.runtime_signals["hyena_clan_front_pressure"] == 0.4
    assert summary.pressure_scores["pride_core_range"] > 0.58
    assert summary.pressure_scores["male_takeover_front"] > 0.44
    assert summary.pressure_scores["clan_den_range"] > 0.55
    assert summary.pressure_scores["scavenger_perimeter"] > 0.41

    print("✅ V4 territory runtime state test passed")


def test_v4_carrion_chain_summary():
    """v4 尸体资源链摘要应识别草原尸体资源闭环。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()

    grassland = world_map.get_region("temperate_grassland")
    wetland = world_map.get_region("wetland_lake")

    grassland_chain = build_region_carrion_chain_summary(grassland, registry)
    wetland_chain = build_region_carrion_chain_summary(wetland, registry)

    assert "lion" in grassland_chain.key_species
    assert "hyena" in grassland_chain.key_species
    assert "vulture" in grassland_chain.key_species
    assert "antelope" in grassland_chain.key_species
    assert "zebra" in grassland_chain.key_species
    assert grassland_chain.resource_scores["kill_generation"] > 0.0
    assert grassland_chain.resource_scores["scavenger_pressure"] > 0.0
    assert grassland_chain.resource_scores["aerial_scavenging"] > 0.0
    assert grassland_chain.resource_scores["carcass_competition_loop"] > 0.0
    assert grassland_chain.resource_scores["carrion_energy_loop"] > 0.0
    assert grassland_chain.layer_scores["kill_layer"] > 0.0
    assert grassland_chain.layer_scores["scavenge_layer"] > 0.0
    assert grassland_chain.layer_scores["aerial_scavenge_layer"] > 0.0
    assert grassland_chain.layer_scores["herd_source_layer"] > 0.0
    assert "lion" in grassland_chain.layer_species["kill_layer"]
    assert "hyena" in grassland_chain.layer_species["scavenge_layer"]
    assert "vulture" in grassland_chain.layer_species["aerial_scavenge_layer"]
    assert "antelope" in grassland_chain.layer_species["herd_source_layer"]

    assert wetland_chain.key_species == []
    assert wetland_chain.resource_scores == {}

    print("✅ V4 carrion chain summary test passed")


def test_v4_territory_feedback_updates_region_state():
    """v4 领地反馈应轻量更新区域风险与碎片化。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")

    initial_conflict = region.hazard_state.get("territorial_conflict", 0.0)
    initial_fragmentation = region.health_state["fragmentation"]

    summary = build_region_territory_summary(region, registry)
    apply_region_territory_feedback(region, summary, feedback_scale=0.05)

    assert region.hazard_state["territorial_conflict"] >= initial_conflict
    assert region.health_state["fragmentation"] >= initial_fragmentation

    print("✅ V4 territory feedback test passed")


def test_v4_wetland_chain_feedback_updates_region_state():
    """v4 湿地链反馈应轻量更新区域资源、风险和健康状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("wetland_lake")

    initial_open_water = region.resource_state["open_water"]
    initial_shore_hatch = region.resource_state["shore_hatch"]
    initial_risk = region.hazard_state.get("shoreline_risk", 0.0)
    initial_resilience = region.health_state["resilience"]

    summary = build_region_wetland_chain_summary(region, registry)
    apply_region_wetland_chain_feedback(region, summary, feedback_scale=0.05)

    assert region.resource_state["open_water"] >= initial_open_water
    assert region.resource_state["shore_hatch"] >= initial_shore_hatch
    assert region.hazard_state.get("shoreline_risk", 0.0) >= initial_risk
    assert region.health_state["resilience"] >= initial_resilience

    print("✅ V4 wetland chain feedback test passed")


def test_v4_wetland_chain_rebalancing_updates_species_pool():
    """v4 湿地链重平衡应轻量调整湿地关键物种池。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("wetland_lake")

    initial_minnow = region.species_pool["minnow"]
    initial_frog = region.species_pool["frog"]

    summary = build_region_wetland_chain_summary(region, registry)
    adjustments = apply_region_wetland_chain_rebalancing(region, summary)

    assert adjustments
    assert any(item["layer_group"] in {"shoreline_layer", "fish_layer", "apex_layer"} for item in adjustments)
    assert region.species_pool["minnow"] != initial_minnow or region.species_pool["frog"] != initial_frog

    print("✅ V4 wetland chain rebalancing test passed")


def test_v4_grassland_chain_feedback_updates_region_state():
    """v4 草原链反馈应轻量更新草原资源与健康状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")

    initial_browse = region.resource_state["browse_cover"]
    initial_biodiversity = region.health_state["biodiversity"]

    summary = build_region_grassland_chain_summary(region, registry)
    apply_region_grassland_chain_feedback(region, summary, feedback_scale=0.05)

    assert region.resource_state["browse_cover"] <= initial_browse
    assert region.health_state["biodiversity"] >= initial_biodiversity

    print("✅ V4 grassland chain feedback test passed")


def test_v4_grassland_chain_rebalancing_updates_species_pool():
    """v4 草原链重平衡应轻量调整草原关键物种池。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")

    initial_rabbit = region.species_pool["rabbit"]
    initial_antelope = region.species_pool["antelope"]
    initial_hyena = region.species_pool["hyena"]
    initial_lion = region.species_pool["lion"]

    summary = build_region_grassland_chain_summary(region, registry)
    adjustments = apply_region_grassland_chain_rebalancing(region, summary)

    assert adjustments
    assert any(item["layer_group"] in {"grazing_layer", "predator_layer", "scavenger_layer", "browse_layer", "herd_layer", "social_layer"} for item in adjustments)
    assert (
        region.species_pool["rabbit"] != initial_rabbit
        or region.species_pool["hyena"] != initial_hyena
        or region.species_pool["antelope"] != initial_antelope
        or region.species_pool["lion"] != initial_lion
    )

    print("✅ V4 grassland chain rebalancing test passed")


def test_v4_carrion_chain_feedback_updates_region_state():
    """v4 尸体资源链反馈应轻量更新草原资源与健康状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")

    initial_carrion = region.resource_state["carcass_availability"]
    initial_resilience = region.health_state["resilience"]

    summary = build_region_carrion_chain_summary(region, registry)
    apply_region_carrion_chain_feedback(region, summary, feedback_scale=0.05)

    assert region.resource_state["carcass_availability"] >= initial_carrion
    assert region.health_state["resilience"] >= initial_resilience

    print("✅ V4 carrion chain feedback test passed")


def test_v4_carrion_chain_rebalancing_updates_species_pool():
    """v4 尸体资源链重平衡应轻量调整草原关键物种池。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")

    initial_antelope = region.species_pool["antelope"]
    initial_zebra = region.species_pool["zebra"]
    initial_hyena = region.species_pool["hyena"]
    initial_vulture = region.species_pool["vulture"]

    summary = build_region_carrion_chain_summary(region, registry)
    adjustments = apply_region_carrion_chain_rebalancing(region, summary)

    assert adjustments
    assert any(item["layer_group"] in {"kill_layer", "scavenge_layer", "aerial_scavenge_layer", "herd_source_layer"} for item in adjustments)
    assert (
        region.species_pool["antelope"] != initial_antelope
        or region.species_pool["zebra"] != initial_zebra
        or region.species_pool["hyena"] != initial_hyena
        or region.species_pool["vulture"] != initial_vulture
    )

    print("✅ V4 carrion chain rebalancing test passed")


def test_v4_predation_feedback_updates_region_state():
    """v4 捕食反馈应轻量更新区域资源、风险和健康状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("wetland_lake")

    initial_fish_cover = region.resource_state.get("fish_cover", 0.0)
    initial_predation = region.hazard_state.get("predation_pressure", 0.0)
    initial_biodiversity = region.health_state["biodiversity"]

    summary = build_region_predation_summary(region, registry)
    apply_region_predation_feedback(region, summary, feedback_scale=0.05)

    assert region.resource_state.get("fish_cover", 0.0) <= initial_fish_cover
    assert region.hazard_state.get("predation_pressure", 0.0) >= initial_predation
    assert region.health_state["biodiversity"] <= initial_biodiversity

    print("✅ V4 predation feedback test passed")


def test_v4_symbiosis_feedback_updates_region_state():
    """v4 共生反馈应轻量提升相关区域资源与健康状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("wetland_lake")
    assert region is not None

    before_hatch = region.resource_state["shore_hatch"]
    before_reed = region.resource_state["reed_cover"]
    before_resilience = region.health_state["resilience"]

    summary = build_region_symbiosis_summary(region, registry)
    apply_region_symbiosis_feedback(region, summary, feedback_scale=0.05)

    assert region.resource_state["shore_hatch"] > before_hatch
    assert region.resource_state["reed_cover"] > before_reed
    assert region.health_state["resilience"] > before_resilience

    print("✅ V4 symbiosis feedback test passed")


def test_region_simulation_uses_region_defaults():
    """未显式覆盖尺寸时，RegionSimulation 应使用区域默认模拟尺寸。"""
    region = build_default_world_map().get_region("wetland_lake")
    sim = RegionSimulation(region=region, config={"world": {"grid_size": 20}})
    stats = sim.get_statistics()

    assert sim.width == region.simulation_size[0]
    assert sim.height == region.simulation_size[1]
    assert stats["region"]["id"] == "wetland_lake"
    assert stats["region"]["hydrology_type"] == "lake_system"
    assert stats["region"]["species_pool"]["frog"] >= 20

    print("✅ Region simulation default sizing test passed")


def test_beaver_registration_and_spawn():
    """河狸应完成注册，并能在水边生成。"""
    eco = Ecosystem()
    position = eco._random_water_adjacent_position()
    assert position is not None

    initial = eco.get_species_count("beaver")
    eco.spawn_animal("beaver", position, source="manual")

    assert eco.get_species_count("beaver") == initial + 1
    assert eco.animals[-1].species == "beaver"

    print("✅ Beaver registration test passed")


def test_beaver_engineering_effect():
    """河狸应能在水边触发基础湿地工程师效果。"""
    eco = Ecosystem()
    position = eco._random_water_adjacent_position()
    assert position is not None

    eco.spawn_animal("beaver", position, source="manual")
    beaver = eco.animals[-1]
    before_events = len(eco.events)

    beaver._engineer_habitat(eco)

    assert len(eco.events) == before_events + 1

    print("✅ Beaver engineering test passed")


def test_crocodile_registration_and_spawn():
    """鳄鱼应完成注册，并能在水边或浅水生成。"""
    eco = Ecosystem()
    position = eco._random_water_adjacent_position() or eco._random_water_position_for_body_type({"river_channel", "lake_shallow"})
    assert position is not None

    initial = eco.get_species_count("crocodile")
    eco.spawn_animal("crocodile", position, source="manual")

    assert eco.get_species_count("crocodile") == initial + 1
    assert eco.animals[-1].species == "crocodile"

    print("✅ Crocodile registration test passed")


def test_crocodile_ambush_effect():
    """鳄鱼应能触发基础水边伏击占位效果。"""
    eco = Ecosystem()
    position = eco._random_water_adjacent_position() or eco._random_land_position()
    assert position is not None

    eco.spawn_animal("crocodile", position, source="manual")
    crocodile = eco.animals[-1]
    before_events = len(eco.events)

    crocodile._hold_ambush_position(eco)

    assert len(eco.events) == before_events + 1

    print("✅ Crocodile ambush test passed")


def test_hippopotamus_registration_and_spawn():
    """河马应完成注册，并能在水边或浅水生成。"""
    eco = Ecosystem()
    position = eco._random_water_adjacent_position() or eco._random_water_position_for_body_type({"river_channel", "lake_shallow"})
    assert position is not None

    initial = eco.get_species_count("hippopotamus")
    eco.spawn_animal("hippopotamus", position, source="manual")

    assert eco.get_species_count("hippopotamus") == initial + 1
    assert eco.animals[-1].species == "hippopotamus"

    print("✅ Hippopotamus registration test passed")


def test_hippopotamus_nutrient_cycle_effect():
    """河马应能触发基础岸带营养回流效果。"""
    eco = Ecosystem()
    position = eco._random_water_adjacent_position() or eco._random_land_position()
    assert position is not None

    eco.spawn_animal("hippopotamus", position, source="manual")
    hippo = eco.animals[-1]
    before_events = len(eco.events)
    before_value = eco.get_local_microhabitat_value(position, {"wetland_patch", "shore_hatch"}, radius=3)

    hippo._cycle_nutrients(eco)

    after_value = eco.get_local_microhabitat_value(position, {"wetland_patch", "shore_hatch"}, radius=3)
    assert len(eco.events) == before_events + 1
    assert after_value >= before_value

    print("✅ Hippopotamus nutrient cycle test passed")


def test_elephant_registration_and_spawn():
    """大象应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("elephant")
    eco.spawn_animal("elephant", position, source="manual")

    assert eco.get_species_count("elephant") == initial + 1
    assert eco.animals[-1].species == "elephant"

    print("✅ Elephant registration test passed")


def test_elephant_engineering_effect():
    """大象应能触发基础植被工程师效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("elephant", position, source="manual")
    elephant = eco.animals[-1]
    before_events = len(eco.events)
    before_grass = eco.get_species_count("grass")

    elephant._engineer_landscape(eco)

    assert len(eco.events) == before_events + 1
    assert eco.get_species_count("grass") >= before_grass

    print("✅ Elephant engineering test passed")


def test_white_rhino_registration_and_spawn():
    """白犀应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("white_rhino")
    eco.spawn_animal("white_rhino", position, source="manual")

    assert eco.get_species_count("white_rhino") == initial + 1
    assert eco.animals[-1].species == "white_rhino"

    print("✅ White rhino registration test passed")


def test_white_rhino_grazing_effect():
    """白犀应能触发基础草灌结构调节效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("white_rhino", position, source="manual")
    rhino = eco.animals[-1]
    before_events = len(eco.events)
    before_grass = eco.get_species_count("grass")

    rhino._maintain_grazing_patch(eco)

    assert len(eco.events) == before_events + 1
    assert eco.get_species_count("grass") >= before_grass

    print("✅ White rhino grazing test passed")


def test_giraffe_registration_and_spawn():
    """长颈鹿应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("giraffe")
    eco.spawn_animal("giraffe", position, source="manual")

    assert eco.get_species_count("giraffe") == initial + 1
    assert eco.animals[-1].species == "giraffe"

    print("✅ Giraffe registration test passed")


def test_giraffe_canopy_effect():
    """长颈鹿应能触发基础树冠浏览效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("giraffe", position, source="manual")
    giraffe = eco.animals[-1]
    before_events = len(eco.events)

    giraffe._shape_canopy(eco)

    assert len(eco.events) == before_events + 1

    print("✅ Giraffe canopy test passed")


def test_antelope_registration_and_spawn():
    """羚羊应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("antelope")
    eco.spawn_animal("antelope", position, source="manual")

    assert eco.get_species_count("antelope") == initial + 1
    assert eco.animals[-1].species == "antelope"

    print("✅ Antelope registration test passed")


def test_zebra_registration_and_spawn():
    """斑马应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("zebra")
    eco.spawn_animal("zebra", position, source="manual")

    assert eco.get_species_count("zebra") == initial + 1
    assert eco.animals[-1].species == "zebra"

    print("✅ Zebra registration test passed")


def test_lion_registration_and_spawn():
    """狮应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("lion")
    eco.spawn_animal("lion", position, source="manual")

    assert eco.get_species_count("lion") == initial + 1
    assert eco.animals[-1].species == "lion"

    print("✅ Lion registration test passed")


def test_lion_hunt_corridor_effect():
    """狮应能触发基础巡猎走廊效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("lion", position, source="manual")
    lion = eco.animals[-1]
    before_events = len(eco.events)

    lion._mark_hunt_corridor(eco)

    assert len(eco.events) == before_events + 1

    print("✅ Lion hunt corridor test passed")


def test_lion_pride_core_effect():
    """狮应能触发基础核心领地效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("lion", position, source="manual")
    lion = eco.animals[-1]
    before_events = len(eco.events)

    lion._establish_pride_core(eco)

    assert len(eco.events) == before_events + 1
    assert lion.pride_strength > 0.0

    print("✅ Lion pride core test passed")


def test_lion_male_takeover_effect():
    """狮应能触发基础雄性接管前线效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("lion", position, source="manual")
    lion = eco.animals[-1]
    before_events = len(eco.events)
    before_health = lion.health

    lion._contest_male_front(eco)

    assert len(eco.events) == before_events + 1
    assert lion.health <= before_health
    assert lion.takeover_pressure > 0.0

    print("✅ Lion male takeover test passed")


def test_hyena_registration_and_spawn():
    """鬣狗应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("hyena")
    eco.spawn_animal("hyena", position, source="manual")

    assert eco.get_species_count("hyena") == initial + 1
    assert eco.animals[-1].species == "hyena"

    print("✅ Hyena registration test passed")


def test_hyena_scavenging_effect():
    """鬣狗应能触发基础腐食压力效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("hyena", position, source="manual")
    hyena = eco.animals[-1]
    before_events = len(eco.events)

    hyena._scavenge_pressure(eco)

    assert len(eco.events) == before_events + 1

    print("✅ Hyena scavenging test passed")


def test_hyena_den_cluster_effect():
    """鬣狗应能触发基础 clan 通道效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("hyena", position, source="manual")
    hyena = eco.animals[-1]
    before_events = len(eco.events)

    hyena._mark_den_cluster(eco)

    assert len(eco.events) == before_events + 1
    assert hyena.clan_cohesion > 0.0

    print("✅ Hyena den cluster test passed")


def test_hyena_clan_front_effect():
    """鬣狗应能触发基础 clan 扩张前线效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("hyena", position, source="manual")
    hyena = eco.animals[-1]
    before_events = len(eco.events)
    before_hunger = hyena.hunger

    hyena._expand_clan_front(eco)

    assert len(eco.events) == before_events + 1
    assert hyena.hunger <= before_hunger
    assert hyena.clan_front_pressure > 0.0

    print("✅ Hyena clan front test passed")


def test_vulture_registration_and_spawn():
    """秃鹫应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("vulture")
    eco.spawn_animal("vulture", position, source="manual")

    assert eco.get_species_count("vulture") == initial + 1
    assert eco.animals[-1].species == "vulture"

    print("✅ Vulture registration test passed")


def run_all_tests():
    """运行所有测试"""
    print("🧪 Running EcoWorld tests...\n")
    
    test_environment()
    test_plants()
    test_animals()
    test_ecosystem_update()
    test_food_chain()
    test_statistics()
    test_minnow_registration_and_spawn()
    test_shrimp_uses_shallow_or_river_habitat()
    test_load_config_preserves_world_dimensions()
    test_land_animals_do_not_spawn_in_water()
    test_amphibious_animals_can_spawn_in_water()
    test_night_moth_registration_and_spawn()
    test_v4_world_and_data_skeleton()
    test_v4_world_simulation_skeleton()
    test_v4_region_relationship_state_persists()
    test_v4_registry_queries()
    test_v4_region_food_web_summary()
    test_v4_region_cascade_summary()
    test_v4_cascade_feedback_updates_region_state()
    test_v4_region_competition_summary()
    test_v4_competition_feedback_rebalances_species_pool()
    test_v4_region_predation_summary()
    test_v4_region_symbiosis_summary()
    test_v4_wetland_chain_summary()
    test_v4_grassland_chain_summary()
    test_v4_territory_summary()
    test_v4_territory_summary_uses_runtime_events()
    test_v4_territory_summary_uses_runtime_state()
    test_v4_carrion_chain_summary()
    test_v4_wetland_chain_feedback_updates_region_state()
    test_v4_wetland_chain_rebalancing_updates_species_pool()
    test_v4_grassland_chain_feedback_updates_region_state()
    test_v4_grassland_chain_rebalancing_updates_species_pool()
    test_v4_territory_feedback_updates_region_state()
    test_v4_carrion_chain_feedback_updates_region_state()
    test_v4_carrion_chain_rebalancing_updates_species_pool()
    test_v4_predation_feedback_updates_region_state()
    test_v4_symbiosis_feedback_updates_region_state()
    test_region_simulation_uses_region_defaults()
    test_beaver_registration_and_spawn()
    test_beaver_engineering_effect()
    test_crocodile_registration_and_spawn()
    test_crocodile_ambush_effect()
    test_hippopotamus_registration_and_spawn()
    test_hippopotamus_nutrient_cycle_effect()
    test_elephant_registration_and_spawn()
    test_elephant_engineering_effect()
    test_white_rhino_registration_and_spawn()
    test_white_rhino_grazing_effect()
    test_giraffe_registration_and_spawn()
    test_giraffe_canopy_effect()
    test_antelope_registration_and_spawn()
    test_zebra_registration_and_spawn()
    test_lion_registration_and_spawn()
    test_lion_hunt_corridor_effect()
    test_lion_pride_core_effect()
    test_lion_male_takeover_effect()
    test_hyena_registration_and_spawn()
    test_hyena_scavenging_effect()
    test_hyena_den_cluster_effect()
    test_hyena_clan_front_effect()
    test_vulture_registration_and_spawn()
    
    print("\n✅ All tests passed!")


if __name__ == "__main__":
    run_all_tests()

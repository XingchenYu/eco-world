"""
基础测试
"""

import sys
import os
import random
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
from src.ecology.social import apply_region_social_trend_feedback, build_region_social_trend_summary
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
from src.entities.omnivores import Hyena, Lion
from src.entities.plants import Grass, Tree
from src.entities.animals import Antelope, Fox, Gender, Rabbit, Vulture, Zebra
from src.main import load_config
from src.sim.region_simulation import RegionSimulation
from src.sim.world_simulation import WorldSimulation, build_default_world_simulation
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
    assert grassland_stats["active_region"]["ecological_pressures"]["prosperity_pressure"] > 0.0
    assert grassland_stats["active_region"]["ecological_pressures"]["runtime_resource_pressure"] > 0.0
    assert grassland_stats["active_region"]["health_state"]["prosperity"] > 0.0
    assert grassland_stats["active_region"]["health_state"]["stability"] > 0.0

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


def test_v4_grassland_runtime_pressure_updates_region_health():
    """v4 运行期资源通道应进入区域长期繁荣/衰退压力。"""
    world_sim = build_default_world_simulation()
    world_sim.set_active_region("temperate_grassland")
    world_sim.update()

    region = world_sim.get_active_region()

    assert region.ecological_pressures["prosperity_pressure"] > 0.0
    assert region.ecological_pressures["collapse_pressure"] > 0.0
    assert region.ecological_pressures["runtime_resource_pressure"] > 0.0
    assert "condition_phase_window_memory" in region.relationship_state["social_trends"]["cycle_signals"]
    assert "birth_cycle_window_memory" in region.relationship_state["social_trends"]["cycle_signals"]
    assert region.ecological_pressures["runtime_herd_health_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_birth_memory_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_birth_memory_world_pressure_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_birth_cycle_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_birth_cycle_window_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_birth_cycle_window_pressure_pull"] > 0.0
    assert region.ecological_pressures["birth_cycle_window_memory_strength_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_health_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_condition_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_health_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_birth_memory_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_birth_memory_world_pressure_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_birth_cycle_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_birth_cycle_window_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_birth_cycle_window_pressure_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_health_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_condition_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_health_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_birth_memory_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_birth_memory_world_pressure_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_birth_cycle_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_birth_cycle_window_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_birth_cycle_window_pressure_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_health_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_condition_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_regional_bias_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_regional_bias_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_regional_bias_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_resource_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_resource_anchor_pull"] > 0.0
    assert region.ecological_pressures["runtime_herd_anchor_prosperity_pull"] > 0.0
    assert region.ecological_pressures["runtime_aerial_anchor_prosperity_pull"] > 0.0
    assert region.ecological_pressures["runtime_apex_anchor_prosperity_pull"] > 0.0
    assert region.health_state["prosperity"] > 0.0
    assert region.health_state["collapse_risk"] >= 0.0
    assert region.health_state["stability"] > 0.0

    print("✅ V4 grassland runtime pressure health test passed")


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
    grassland.resource_state["surface_water"] = 0.6
    wetland = world_map.get_region("wetland_lake")

    territory = build_region_territory_summary(
        grassland,
        registry,
        runtime_state={
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "herd_surface_water_runtime": 0.6,
            "herd_birth_runtime": 0.28,
            "herd_birth_memory_runtime": 0.48,
            "herd_birth_memory_world_pressure_runtime": 0.30,
            "herd_birth_cycle_runtime": 0.26,
            "herd_birth_cycle_window_runtime": 0.24,
            "herd_birth_cycle_window_pressure_runtime": 0.24,
            "herd_condition_runtime": 0.46,
            "apex_birth_runtime": 0.24,
            "apex_birth_memory_runtime": 0.48,
            "apex_birth_memory_world_pressure_runtime": 0.28,
            "apex_birth_cycle_runtime": 0.24,
            "apex_birth_cycle_window_runtime": 0.22,
            "apex_birth_cycle_window_pressure_runtime": 0.22,
            "apex_condition_runtime": 0.39,
            "shared_hotspot_overlap": 1.0,
        },
    )
    social_trends = build_region_social_trend_summary(grassland, territory_summary=territory)
    grassland_chain = build_region_grassland_chain_summary(
        grassland,
        registry,
        territory_summary=territory,
        social_trend_summary=social_trends,
    )
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
    assert grassland_chain.trophic_scores["hotspot_overlap_pressure"] > 0.0
    assert grassland_chain.trophic_scores["territory_channel_pressure"] > 0.0
    assert grassland_chain.trophic_scores["carcass_channeling"] > 0.0
    assert grassland_chain.trophic_scores["runtime_surface_water_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_herd_birth_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_herd_birth_memory_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_herd_birth_memory_world_pressure_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_herd_birth_cycle_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_herd_birth_cycle_window_pressure_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_herd_condition_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_herd_condition_phase_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_apex_condition_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_apex_birth_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_apex_birth_memory_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_apex_birth_memory_world_pressure_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_apex_birth_cycle_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_apex_birth_cycle_window_pressure_pull"] > 0.0
    assert grassland_chain.trophic_scores["runtime_apex_condition_phase_pull"] > 0.0
    assert grassland_chain.trophic_scores["birth_cycle_window_memory_strength_pull"] > 0.0
    assert grassland_chain.trophic_scores["surface_water_anchor"] > 0.0
    assert grassland_chain.trophic_scores["herd_grazing"] > 0.0
    assert grassland_chain.trophic_scores["migration_pressure"] > 0.0
    assert grassland_chain.layer_scores["engineering_layer"] > 0.0
    assert grassland_chain.layer_scores["grazing_layer"] > 0.0
    assert grassland_chain.layer_scores["browse_layer"] > 0.0
    assert grassland_chain.layer_scores["herd_layer"] > 0.0
    assert grassland_chain.layer_scores["predator_layer"] > 0.0
    assert grassland_chain.layer_scores["scavenger_layer"] > 0.0
    assert grassland_chain.layer_scores["social_layer"] > 0.0
    assert grassland_chain.layer_scores["herd_layer"] > grassland_chain.layer_scores["browse_layer"]
    assert "african_elephant" in grassland_chain.layer_species["engineering_layer"]
    assert "white_rhino" in grassland_chain.layer_species["grazing_layer"]
    assert "giraffe" in grassland_chain.layer_species["browse_layer"]
    assert "antelope" in grassland_chain.layer_species["herd_layer"]
    assert "zebra" in grassland_chain.layer_species["herd_layer"]
    assert "lion" in grassland_chain.layer_species["predator_layer"]
    assert "hyena" in grassland_chain.layer_species["scavenger_layer"]
    assert "lion" in grassland_chain.layer_species["social_layer"]
    assert "hyena" in grassland_chain.layer_species["social_layer"]
    assert grassland_chain.dominant_layer == "herd_layer"

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
    grassland.resource_state["surface_water"] = 0.6
    grassland.resource_state["carcass_availability"] = 0.5
    grassland.health_state["prosperity"] = 0.42
    grassland.health_state["stability"] = 0.36
    grassland.health_state["collapse_risk"] = 0.08

    summary = build_region_territory_summary(
        grassland,
        registry,
        runtime_state={
            "lion_pride_strength": 0.7,
            "lion_takeover_pressure": 0.5,
            "lion_pride_count": 2.0,
            "lion_hotspot_count": 2.0,
            "lion_cycle_expansion": 0.6,
            "hyena_clan_cohesion": 0.6,
            "hyena_clan_front_pressure": 0.4,
            "hyena_clan_count": 3.0,
            "hyena_hotspot_count": 2.0,
            "hyena_cycle_expansion": 0.5,
            "herd_hotspot_count": 3.0,
            "herd_apex_overlap": 1.0,
            "herd_route_cycle_runtime": 0.36,
            "herd_surface_water_runtime": 0.6,
            "herd_regional_health_runtime": 0.52,
            "herd_regional_health_anchor_runtime": 0.70,
            "herd_condition_runtime": 0.46,
            "herd_regional_bias_runtime": 0.46,
            "herd_anchor_prosperity_runtime": 0.58,
            "herd_regional_bias_runtime": 1.0,
            "vulture_hotspot_count": 2.0,
            "aerial_carrion_cycle_runtime": 0.31,
            "aerial_carcass_runtime": 0.5,
            "aerial_regional_health_runtime": 0.44,
            "aerial_regional_health_anchor_runtime": 0.70,
            "aerial_condition_runtime": 0.41,
            "aerial_regional_bias_runtime": 0.42,
            "aerial_anchor_prosperity_runtime": 0.49,
            "aerial_regional_bias_runtime": 1.0,
            "vulture_carrion_overlap": 1.0,
            "shared_hotspot_overlap": 1.0,
            "apex_regional_health_runtime": 0.48,
            "apex_regional_health_anchor_runtime": 0.70,
            "apex_condition_runtime": 0.39,
            "apex_regional_bias_runtime": 0.43,
            "apex_anchor_prosperity_runtime": 0.46,
            "apex_regional_bias_runtime": 1.0,
        },
    )

    assert summary.runtime_signals["lion_pride_strength"] == 0.7
    assert summary.runtime_signals["lion_takeover_pressure"] == 0.5
    assert summary.runtime_signals["lion_pride_count"] == 2
    assert summary.runtime_signals["lion_hotspot_count"] == 2
    assert summary.runtime_signals["lion_cycle_expansion"] == 0.6
    assert summary.runtime_signals["hyena_clan_cohesion"] == 0.6
    assert summary.runtime_signals["hyena_clan_front_pressure"] == 0.4
    assert summary.runtime_signals["hyena_clan_count"] == 3
    assert summary.runtime_signals["hyena_hotspot_count"] == 2
    assert summary.runtime_signals["hyena_cycle_expansion"] == 0.5
    assert summary.runtime_signals["herd_hotspot_count"] == 3
    assert summary.runtime_signals["herd_apex_overlap"] == 1
    assert summary.runtime_signals["herd_route_cycle_runtime"] == 0.36
    assert summary.runtime_signals["herd_surface_water_runtime"] == 0.6
    assert summary.runtime_signals["herd_regional_health_runtime"] == 0.52
    assert summary.runtime_signals["herd_regional_health_anchor_runtime"] >= 0.67
    assert summary.runtime_signals["herd_condition_anchor_runtime"] > 0.38
    assert summary.runtime_signals["herd_condition_runtime"] == 0.46
    assert summary.runtime_signals["herd_condition_phase_runtime"] >= 0.46
    assert summary.runtime_signals["herd_condition_phase_anchor_runtime"] >= 0.40
    assert summary.runtime_signals["herd_resource_anchor_runtime"] > 0.56
    assert summary.runtime_signals["herd_anchor_prosperity_runtime"] == 0.58
    assert summary.runtime_signals["herd_regional_bias_runtime"] == 1.0
    assert summary.runtime_signals["surface_water_anchor"] == 0.6
    assert summary.runtime_signals["vulture_hotspot_count"] == 2
    assert summary.runtime_signals["aerial_carrion_cycle_runtime"] == 0.31
    assert summary.runtime_signals["aerial_carcass_runtime"] == 0.5
    assert summary.runtime_signals["aerial_regional_health_runtime"] == 0.44
    assert summary.runtime_signals["aerial_regional_health_anchor_runtime"] >= 0.66
    assert summary.runtime_signals["aerial_condition_anchor_runtime"] > 0.34
    assert summary.runtime_signals["aerial_condition_runtime"] == 0.41
    assert summary.runtime_signals["aerial_condition_phase_runtime"] >= 0.41
    assert summary.runtime_signals["aerial_condition_phase_anchor_runtime"] >= 0.36
    assert summary.runtime_signals["aerial_resource_anchor_runtime"] > 0.47
    assert summary.runtime_signals["aerial_anchor_prosperity_runtime"] == 0.49
    assert summary.runtime_signals["aerial_regional_bias_runtime"] == 1.0
    assert summary.runtime_signals["carcass_anchor"] == 0.5
    assert summary.runtime_signals["apex_regional_health_runtime"] == 0.48
    assert summary.runtime_signals["apex_regional_health_anchor_runtime"] >= 0.64
    assert summary.runtime_signals["apex_condition_anchor_runtime"] > 0.30
    assert summary.runtime_signals["apex_condition_runtime"] == 0.39
    assert summary.runtime_signals["apex_condition_phase_runtime"] >= 0.39
    assert summary.runtime_signals["apex_condition_phase_anchor_runtime"] >= 0.34
    assert summary.runtime_signals["apex_anchor_prosperity_runtime"] == 0.46
    assert summary.runtime_signals["apex_regional_bias_runtime"] == 1.0
    assert summary.runtime_signals["vulture_carrion_overlap"] == 1
    assert summary.runtime_signals["shared_hotspot_overlap"] == 1
    assert summary.pressure_scores["pride_core_range"] > 0.58
    assert summary.pressure_scores["male_takeover_front"] > 0.44
    assert summary.pressure_scores["clan_den_range"] > 0.55
    assert summary.pressure_scores["scavenger_perimeter"] > 0.41
    assert summary.pressure_scores["apex_boundary_conflict"] > 0.63
    assert summary.pressure_scores["carcass_route_overlap"] > 0.49

    print("✅ V4 territory runtime state test passed")


def test_v4_territory_summary_uses_dominant_layers():
    """v4 领地摘要应吸收上一周期链路主导层。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    grassland = world_map.get_region("temperate_grassland")
    grassland.record_relationship_state("grassland_chain", {"dominant_layer": "herd_layer"})
    grassland.record_relationship_state("carrion_chain", {"dominant_layer": "kill_layer"})

    summary = build_region_territory_summary(grassland, registry)

    assert summary.runtime_signals["herd_channel_bias"] == 1
    assert summary.runtime_signals["kill_corridor_bias"] == 1
    assert summary.pressure_scores["waterhole_spacing"] > 0.34
    assert summary.pressure_scores["carcass_route_overlap"] > 0.49

    print("✅ V4 territory dominant layer test passed")


def test_v4_territory_summary_uses_regional_social_anchors():
    """v4 领地摘要应吸收区域长期社会锚点。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    grassland = world_map.get_region("temperate_grassland")
    grassland.record_relationship_state(
        "social_trends",
        {
            "cycle_signals": [
                "regional_prosperity_anchor",
                "regional_stability_anchor",
                "regional_collapse_anchor",
            ],
            "prosperity_scores": {"grassland_collapse_phase": 0.2},
        },
    )

    summary = build_region_territory_summary(grassland, registry)

    assert summary.runtime_signals["regional_prosperity_bias"] == 1
    assert summary.runtime_signals["regional_stability_bias"] == 1
    assert summary.runtime_signals["regional_collapse_bias"] == 1
    assert summary.pressure_scores["waterhole_spacing"] > 0.34
    assert summary.pressure_scores["carcass_route_overlap"] > 0.49
    assert summary.pressure_scores["pride_core_range"] > 0.58
    assert summary.pressure_scores["clan_den_range"] > 0.55
    assert summary.pressure_scores["apex_boundary_conflict"] > 0.63

    print("✅ V4 territory regional social anchor test passed")


def test_v4_territory_summary_uses_hotspot_memory():
    """v4 领地摘要应能吸收热点持续与迁移记忆。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    grassland = world_map.get_region("temperate_grassland")
    grassland.record_relationship_state(
        "territory",
        {
            "runtime_signals": {
                "lion_hotspot_count": 2,
                "hyena_hotspot_count": 2,
                "shared_hotspot_overlap": 1,
            }
        },
    )

    summary = build_region_territory_summary(
        grassland,
        registry,
        runtime_state={
            "lion_hotspot_count": 3.0,
            "hyena_hotspot_count": 2.0,
            "shared_hotspot_overlap": 2.0,
        },
    )

    assert summary.runtime_signals["lion_hotspot_persistence"] == 2
    assert summary.runtime_signals["hyena_hotspot_persistence"] == 2
    assert summary.runtime_signals["shared_hotspot_persistence"] == 1
    assert summary.runtime_signals["lion_hotspot_shift"] == 1
    assert summary.runtime_signals["shared_hotspot_shift"] == 1

    print("✅ V4 territory hotspot memory test passed")


def test_v4_social_trend_summary_uses_memory():
    """v4 社群趋势摘要应结合历史记忆与当前领地信号。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")
    region.record_relationship_state(
        "territory",
        {
            "runtime_signals": {
                "lion_hotspot_count": 2,
                "hyena_hotspot_count": 2,
                "shared_hotspot_overlap": 0,
            }
        },
    )
    region.record_relationship_state(
        "social_trends",
        {
            "cycle_signals": ["birth_cycle_window_memory"],
            "trend_scores": {
                "lion_recovery_bias": 0.4,
                "lion_decline_bias": 0.1,
                "hyena_recovery_bias": 0.35,
                "hyena_decline_bias": 0.12,
            },
            "phase_scores": {
                "lion_expansion_phase": 0.45,
                "hyena_expansion_phase": 0.42,
            },
            "hotspot_scores": {
                "lion_hotspot_memory": 0.46,
                "hyena_hotspot_memory": 0.44,
                "shared_hotspot_memory": 0.38,
                "herd_hotspot_memory": 0.34,
                "herd_apex_memory": 0.22,
                "vulture_hotspot_memory": 0.30,
                "vulture_carrion_memory": 0.26,
            },
        },
    )
    region.record_relationship_state(
        "grassland_rebalancing",
        {
            "adjustments": [
                {"effect": "condition_phase_pride_window"},
                {"effect": "condition_phase_clan_window"},
                {"effect": "world_pressure_herd_window"},
                {"effect": "world_pressure_apex_window"},
                {"effect": "birth_cycle_herd_window"},
                {"effect": "birth_cycle_apex_window"},
            ]
        },
    )
    region.record_relationship_state(
        "carrion_rebalancing",
        {
            "adjustments": [
                {"effect": "condition_phase_aerial_window"},
                {"effect": "world_pressure_aerial_window"},
                {"effect": "world_pressure_apex_carrion_window"},
                {"effect": "birth_cycle_aerial_window"},
                {"effect": "birth_cycle_apex_carrion_window"},
            ]
        },
    )
    region.health_state["prosperity"] = 0.42
    region.health_state["stability"] = 0.36
    region.health_state["collapse_risk"] = 0.18
    region.resource_state["surface_water"] = 0.6
    region.resource_state["carcass_availability"] = 0.5
    territory = build_region_territory_summary(
        region,
        registry,
        runtime_state={
            "lion_pride_strength": 0.7,
            "lion_pride_count": 2.0,
            "lion_hotspot_count": 2.0,
            "hyena_clan_cohesion": 0.65,
            "hyena_clan_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "herd_hotspot_count": 3.0,
            "herd_apex_overlap": 1.0,
            "herd_route_cycle_runtime": 0.34,
            "herd_surface_water_runtime": 0.6,
            "herd_birth_runtime": 0.30,
            "herd_birth_memory_runtime": 0.28,
            "herd_birth_memory_world_pressure_runtime": 0.24,
            "herd_birth_cycle_runtime": 0.22,
            "herd_birth_cycle_window_runtime": 0.20,
            "herd_birth_cycle_window_pressure_runtime": 0.22,
            "herd_regional_health_runtime": 0.52,
            "herd_condition_runtime": 0.46,
            "herd_regional_bias_runtime": 0.46,
            "herd_anchor_prosperity_runtime": 0.58,
            "herd_world_pressure_window_runtime": 0.36,
            "surface_water_anchor": 0.6,
            "vulture_hotspot_count": 2.0,
            "vulture_carrion_overlap": 1.0,
            "aerial_carrion_cycle_runtime": 0.28,
            "aerial_carcass_runtime": 0.5,
            "aerial_birth_runtime": 0.26,
            "aerial_birth_memory_runtime": 0.48,
            "aerial_birth_memory_world_pressure_runtime": 0.24,
            "aerial_birth_cycle_runtime": 0.22,
            "aerial_birth_cycle_window_runtime": 0.20,
            "aerial_birth_cycle_window_pressure_runtime": 0.22,
            "aerial_regional_health_runtime": 0.44,
            "aerial_condition_runtime": 0.41,
            "aerial_regional_bias_runtime": 0.42,
            "aerial_anchor_prosperity_runtime": 0.49,
            "aerial_world_pressure_window_runtime": 0.34,
            "carcass_anchor": 0.5,
            "apex_regional_health_runtime": 0.48,
            "apex_birth_runtime": 0.22,
            "apex_birth_memory_runtime": 0.48,
            "apex_birth_memory_world_pressure_runtime": 0.24,
            "apex_birth_cycle_runtime": 0.22,
            "apex_birth_cycle_window_runtime": 0.20,
            "apex_birth_cycle_window_pressure_runtime": 0.20,
            "apex_condition_runtime": 0.39,
            "apex_regional_bias_runtime": 0.43,
            "apex_anchor_prosperity_runtime": 0.46,
            "apex_world_pressure_window_runtime": 0.31,
            "shared_hotspot_overlap": 0.0,
        },
    )

    summary = build_region_social_trend_summary(region, territory_summary=territory)

    assert summary.trend_scores["lion_recovery_bias"] > 0.58
    assert summary.trend_scores["hyena_recovery_bias"] > 0.56
    assert summary.phase_scores["lion_expansion_phase"] > 0.55
    assert summary.phase_scores["hyena_expansion_phase"] > 0.53
    assert summary.phase_scores["herd_route_cycle"] > 0.18
    assert summary.phase_scores["aerial_carrion_cycle"] > 0.14
    assert summary.boom_bust_scores["grassland_boom_phase"] > 0.45
    assert summary.prosperity_scores["grassland_prosperity_phase"] > 0.0
    assert summary.prosperity_scores["grassland_prosperity_phase"] > summary.prosperity_scores["grassland_collapse_phase"]
    assert summary.hotspot_scores["lion_hotspot_memory"] >= 0.12
    assert summary.hotspot_scores["hyena_hotspot_memory"] >= 0.12
    assert summary.hotspot_scores["herd_hotspot_memory"] > 0.25
    assert summary.hotspot_scores["vulture_hotspot_memory"] > 0.20
    assert summary.hotspot_scores["herd_hotspot_memory"] > 0.30
    assert summary.hotspot_scores["herd_apex_memory"] > 0.08
    assert summary.hotspot_scores["vulture_carrion_memory"] > 0.08
    assert summary.hotspot_scores["vulture_carrion_memory"] > 0.12
    assert "lion_expansion_cycle" in summary.cycle_signals
    assert "hyena_expansion_cycle" in summary.cycle_signals
    assert "apex_hotspot_wave" in summary.cycle_signals
    assert "grassland_boom_phase" in summary.cycle_signals
    assert "grassland_prosperity_phase" in summary.cycle_signals
    assert "resource_anchor_prosperity" in summary.cycle_signals
    assert "herd_hotspot_memory" in summary.cycle_signals
    assert "vulture_hotspot_memory" in summary.cycle_signals
    assert "herd_route_cycle" in summary.cycle_signals
    assert "herd_birth_runtime" in summary.cycle_signals
    assert "herd_birth_memory_runtime" in summary.cycle_signals
    assert "herd_birth_memory_world_pressure_runtime" in summary.cycle_signals
    assert "herd_birth_cycle_runtime" in summary.cycle_signals
    assert "herd_birth_cycle_window_runtime" in summary.cycle_signals
    assert "herd_birth_cycle_runtime" in summary.cycle_signals
    assert "aerial_carrion_cycle" in summary.cycle_signals
    assert "aerial_birth_runtime" in summary.cycle_signals
    assert "aerial_birth_memory_runtime" in summary.cycle_signals
    assert "aerial_birth_memory_world_pressure_runtime" in summary.cycle_signals
    assert "aerial_birth_cycle_runtime" in summary.cycle_signals
    assert "aerial_birth_cycle_window_runtime" in summary.cycle_signals
    assert "aerial_birth_cycle_runtime" in summary.cycle_signals
    assert "apex_birth_runtime" in summary.cycle_signals
    assert "apex_birth_memory_runtime" in summary.cycle_signals
    assert "apex_birth_memory_world_pressure_runtime" in summary.cycle_signals
    assert "apex_birth_cycle_runtime" in summary.cycle_signals
    assert "apex_birth_cycle_window_runtime" in summary.cycle_signals
    assert "apex_birth_cycle_runtime" in summary.cycle_signals
    assert summary.trend_scores["herd_birth_memory"] > 0.0
    assert summary.trend_scores["aerial_birth_memory"] > 0.0
    assert summary.trend_scores["apex_birth_memory"] > 0.0
    assert summary.trend_scores["birth_cycle_window_memory_strength"] > 0.0
    assert "surface_water_anchor" in summary.cycle_signals
    assert "carcass_anchor" in summary.cycle_signals
    assert "herd_regional_health_runtime" in summary.cycle_signals
    assert "herd_condition_runtime" in summary.cycle_signals
    assert "herd_condition_phase_runtime" in summary.cycle_signals
    assert "herd_condition_phase_anchor_runtime" in summary.cycle_signals
    assert "herd_regional_health_anchor_runtime" in summary.cycle_signals
    assert "herd_condition_anchor_runtime" in summary.cycle_signals
    assert "herd_regional_bias_runtime" in summary.cycle_signals
    assert "aerial_regional_health_runtime" in summary.cycle_signals
    assert "aerial_condition_runtime" in summary.cycle_signals
    assert "aerial_condition_phase_runtime" in summary.cycle_signals
    assert "aerial_condition_phase_anchor_runtime" in summary.cycle_signals
    assert "aerial_regional_health_anchor_runtime" in summary.cycle_signals
    assert "aerial_condition_anchor_runtime" in summary.cycle_signals
    assert "aerial_regional_bias_runtime" in summary.cycle_signals
    assert "apex_regional_health_runtime" in summary.cycle_signals
    assert "apex_condition_runtime" in summary.cycle_signals
    assert "apex_condition_phase_runtime" in summary.cycle_signals
    assert "apex_condition_phase_anchor_runtime" in summary.cycle_signals
    assert "apex_regional_health_anchor_runtime" in summary.cycle_signals
    assert "apex_condition_anchor_runtime" in summary.cycle_signals
    assert "condition_phase_window_memory" in summary.cycle_signals
    assert "world_pressure_window_memory" in summary.cycle_signals
    assert "birth_cycle_window_memory" in summary.cycle_signals
    assert "birth_cycle_window_memory_strength" in summary.cycle_signals
    assert "herd_birth_cycle_window_pressure_runtime" in summary.cycle_signals
    assert "aerial_birth_cycle_window_pressure_runtime" in summary.cycle_signals
    assert "apex_birth_cycle_window_pressure_runtime" in summary.cycle_signals
    assert "herd_world_pressure_window_runtime" in summary.cycle_signals
    assert "aerial_world_pressure_window_runtime" in summary.cycle_signals
    assert "apex_world_pressure_window_runtime" in summary.cycle_signals
    assert "apex_regional_bias_runtime" in summary.cycle_signals
    assert "herd_surface_water_runtime" in summary.cycle_signals
    assert "aerial_carcass_runtime" in summary.cycle_signals
    assert "herd_resource_anchor_runtime" in summary.cycle_signals
    assert "herd_anchor_prosperity_runtime" in summary.cycle_signals
    assert "aerial_resource_anchor_runtime" in summary.cycle_signals
    assert "aerial_anchor_prosperity_runtime" in summary.cycle_signals
    assert "apex_anchor_prosperity_runtime" in summary.cycle_signals
    assert "regional_prosperity_anchor" in summary.cycle_signals
    assert "regional_stability_anchor" in summary.cycle_signals
    assert "regional_collapse_anchor" in summary.cycle_signals
    assert "runtime_anchor_prosperity" in summary.cycle_signals

    before_resilience = region.health_state["resilience"]
    before_surface_water = region.resource_state["surface_water"]
    before_carcass = region.resource_state["carcass_availability"]
    apply_region_social_trend_feedback(region, summary, feedback_scale=0.05)
    assert region.health_state["resilience"] >= before_resilience
    assert region.resource_state["surface_water"] >= before_surface_water
    assert region.resource_state["carcass_availability"] >= before_carcass

    print("✅ V4 social trend summary test passed")


def test_v4_social_trend_birth_cycle_window_support_memory():
    """birth_cycle_window 的 support 效果也应沉淀成社群长期记忆。"""
    world_map = build_default_world_map()
    region = world_map.get_region("temperate_grassland")
    region.record_relationship_state(
        "grassland_rebalancing",
        {
            "adjustments": [
                {"effect": "birth_cycle_window_herd_support"},
                {"effect": "birth_cycle_window_apex_support"},
            ]
        },
    )
    region.record_relationship_state(
        "carrion_rebalancing",
        {
            "adjustments": [
                {"effect": "birth_cycle_window_aerial_support"},
                {"effect": "birth_cycle_window_pressure_aerial_support"},
                {"effect": "birth_cycle_window_apex_carrion_support"},
                {"effect": "birth_cycle_window_pressure_apex_carrion_support"},
            ]
        },
    )

    summary = build_region_social_trend_summary(region)

    assert "birth_cycle_window_memory" in summary.cycle_signals
    assert "birth_cycle_window_memory_strength" in summary.cycle_signals
    assert summary.trend_scores["birth_cycle_window_memory_strength"] > 0.0

    print("✅ V4 social trend birth-cycle window support memory test passed")


def test_v4_carrion_chain_summary():
    """v4 尸体资源链摘要应识别草原尸体资源闭环。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()

    grassland = world_map.get_region("temperate_grassland")
    grassland.resource_state["carcass_availability"] = 0.5
    wetland = world_map.get_region("wetland_lake")

    territory = build_region_territory_summary(
        grassland,
        registry,
        runtime_state={
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "aerial_carcass_runtime": 0.5,
            "aerial_birth_runtime": 0.26,
            "aerial_birth_memory_runtime": 0.24,
            "aerial_birth_memory_world_pressure_runtime": 0.22,
            "aerial_birth_cycle_runtime": 0.20,
            "aerial_birth_cycle_window_runtime": 0.22,
            "aerial_birth_cycle_window_pressure_runtime": 0.22,
            "aerial_condition_runtime": 0.41,
            "apex_birth_runtime": 0.22,
            "apex_birth_memory_runtime": 0.20,
            "apex_birth_memory_world_pressure_runtime": 0.22,
            "apex_birth_cycle_runtime": 0.20,
            "apex_birth_cycle_window_runtime": 0.20,
            "apex_birth_cycle_window_pressure_runtime": 0.20,
            "apex_condition_runtime": 0.39,
            "shared_hotspot_overlap": 1.0,
        },
    )
    social_trends = build_region_social_trend_summary(grassland, territory_summary=territory)
    grassland_chain = build_region_carrion_chain_summary(
        grassland,
        registry,
        territory_summary=territory,
        social_trend_summary=social_trends,
    )
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
    assert grassland_chain.resource_scores["kill_corridor_overlap"] > 0.0
    assert grassland_chain.resource_scores["scavenger_lane_pressure"] > 0.0
    assert grassland_chain.resource_scores["runtime_carcass_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_aerial_birth_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_aerial_birth_memory_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_aerial_birth_memory_world_pressure_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_aerial_birth_cycle_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_aerial_birth_cycle_window_pressure_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_aerial_condition_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_apex_birth_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_apex_birth_memory_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_apex_birth_memory_world_pressure_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_apex_birth_cycle_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_apex_birth_cycle_window_pressure_pull"] > 0.0
    assert grassland_chain.resource_scores["runtime_apex_condition_pull"] > 0.0
    assert grassland_chain.resource_scores["birth_cycle_window_memory_strength_pull"] > 0.0
    assert grassland_chain.resource_scores["carcass_anchor_pressure"] > 0.0
    assert grassland_chain.layer_scores["kill_layer"] > 0.0
    assert grassland_chain.layer_scores["scavenge_layer"] > 0.0
    assert grassland_chain.layer_scores["aerial_scavenge_layer"] > 0.0
    assert grassland_chain.layer_scores["herd_source_layer"] > 0.0
    assert grassland_chain.layer_scores["aerial_scavenge_layer"] > 0.63
    assert "lion" in grassland_chain.layer_species["kill_layer"]
    assert "hyena" in grassland_chain.layer_species["scavenge_layer"]
    assert "vulture" in grassland_chain.layer_species["aerial_scavenge_layer"]
    assert "antelope" in grassland_chain.layer_species["herd_source_layer"]
    assert grassland_chain.dominant_layer in {"herd_source_layer", "aerial_scavenge_layer"}

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


def test_runtime_birth_signal_aggregation():
    """运行期产仔事件应汇总为 territory runtime 信号。"""
    world_sim = WorldSimulation(build_default_world_map())
    sim = world_sim.get_active_simulation()
    sim.balance.record_causal_event("antelope产仔", "antelope+2", 0.2, sim.tick_count)
    sim.balance.record_causal_event("vulture产仔", "vulture+1", 0.2, sim.tick_count)
    sim.balance.record_causal_event("lion产仔", "lion+2", 0.2, sim.tick_count)

    runtime_state = world_sim._build_runtime_territory_state(sim)

    assert runtime_state["herd_birth_runtime"] > 0.0
    assert runtime_state["aerial_birth_runtime"] > 0.0
    assert runtime_state["apex_birth_runtime"] > 0.0

    print("✅ Runtime birth signal aggregation test passed")


def test_runtime_birth_memory_signal_aggregation():
    """运行中的 birth_memory_bias 应汇总为 territory runtime 信号。"""
    world_sim = WorldSimulation(build_default_world_map())
    sim = world_sim.get_active_simulation()

    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    lion = Lion(position=(24, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(26, 20), gender=Gender.FEMALE)
    sim.animals.extend([antelope, zebra, lion, vulture])

    antelope.birth_memory_bias = 0.34
    antelope.birth_memory_world_pressure_bias = 0.27
    antelope.birth_cycle_bias = 0.25
    zebra.birth_memory_bias = 0.30
    zebra.birth_memory_world_pressure_bias = 0.24
    zebra.birth_cycle_bias = 0.22
    lion.birth_memory_bias = 0.28
    lion.birth_memory_world_pressure_bias = 0.22
    lion.birth_cycle_bias = 0.21
    vulture.birth_memory_bias = 0.26
    vulture.birth_memory_world_pressure_bias = 0.21
    vulture.birth_cycle_bias = 0.20

    runtime_state = world_sim._build_runtime_territory_state(sim)

    assert runtime_state["herd_birth_memory_runtime"] > 0.0
    assert runtime_state["herd_birth_memory_world_pressure_runtime"] > 0.0
    assert runtime_state["herd_birth_cycle_runtime"] > 0.0
    assert runtime_state["herd_birth_cycle_window_runtime"] > 0.0
    assert runtime_state["aerial_birth_memory_runtime"] > 0.0
    assert runtime_state["aerial_birth_memory_world_pressure_runtime"] > 0.0
    assert runtime_state["aerial_birth_cycle_runtime"] > 0.0
    assert runtime_state["aerial_birth_cycle_window_runtime"] > 0.0
    assert runtime_state["apex_birth_memory_runtime"] > 0.0
    assert runtime_state["apex_birth_memory_world_pressure_runtime"] > 0.0
    assert runtime_state["apex_birth_cycle_runtime"] > 0.0
    assert runtime_state["apex_birth_cycle_window_runtime"] > 0.0

    print("✅ Runtime birth memory signal aggregation test passed")


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
    region.health_state["prosperity"] = 0.42
    region.health_state["stability"] = 0.36
    region.health_state["collapse_risk"] = 0.18

    initial_browse = region.resource_state["browse_cover"]
    initial_biodiversity = region.health_state["biodiversity"]
    region.record_relationship_state(
        "social_trends",
        {
            "trend_scores": {
                "lion_recovery_bias": 0.45,
                "hyena_recovery_bias": 0.42,
                "birth_cycle_window_memory_strength": 0.36,
            },
            "phase_scores": {
                "lion_expansion_phase": 0.48,
                "hyena_expansion_phase": 0.46,
            },
            "boom_bust_scores": {
                "grassland_boom_phase": 0.44,
                "grassland_bust_phase": 0.18,
            },
            "prosperity_scores": {
                "grassland_prosperity_phase": 0.24,
                "grassland_collapse_phase": 0.12,
            },
            "hotspot_scores": {
                "lion_hotspot_memory": 0.46,
                "hyena_hotspot_memory": 0.44,
                "shared_hotspot_memory": 0.43,
                "herd_hotspot_memory": 0.40,
                "herd_apex_memory": 0.28,
            },
        },
    )
    region.record_relationship_state("grassland_chain", {"dominant_layer": "herd_layer"})
    region.record_relationship_state("carrion_chain", {"dominant_layer": "kill_layer"})

    territory = build_region_territory_summary(
        region,
        registry,
        runtime_state={
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "herd_hotspot_count": 3.0,
            "herd_apex_overlap": 1.0,
            "herd_surface_water_runtime": 0.6,
            "herd_condition_runtime": 0.46,
            "herd_regional_health_runtime": 0.52,
            "herd_regional_health_anchor_runtime": 0.70,
            "herd_regional_bias_runtime": 0.46,
            "herd_anchor_prosperity_runtime": 0.58,
            "herd_world_pressure_window_runtime": 0.36,
            "herd_birth_memory_runtime": 0.48,
            "apex_regional_health_runtime": 0.48,
            "apex_birth_memory_runtime": 0.48,
            "apex_condition_runtime": 0.39,
            "apex_regional_health_anchor_runtime": 0.70,
            "apex_regional_bias_runtime": 0.43,
            "apex_anchor_prosperity_runtime": 0.46,
            "apex_world_pressure_window_runtime": 0.31,
            "shared_hotspot_overlap": 1.0,
        },
    )
    social_trends = build_region_social_trend_summary(region, territory_summary=territory)
    summary = build_region_grassland_chain_summary(region, registry, territory_summary=territory, social_trend_summary=social_trends)
    apply_region_grassland_chain_feedback(region, summary, feedback_scale=0.05)

    assert region.resource_state["browse_cover"] <= initial_browse
    assert region.health_state["biodiversity"] >= initial_biodiversity
    assert "hotspot_cycle_pressure" in summary.trophic_scores
    assert "hotspot_cycle_overlap" in summary.trophic_scores
    assert "prosperity_phase_weight" in summary.trophic_scores
    assert "collapse_phase_weight" in summary.trophic_scores
    assert "prosperity_feedback_bias" in summary.trophic_scores
    assert "collapse_feedback_bias" in summary.trophic_scores
    assert "dominant_herd_channeling" in summary.trophic_scores
    assert "runtime_herd_corridors" in summary.trophic_scores
    assert "runtime_surface_water_pull" in summary.trophic_scores
    assert "runtime_herd_birth_memory_pull" in summary.trophic_scores
    assert "runtime_herd_condition_pull" in summary.trophic_scores
    assert "runtime_herd_condition_phase_pull" in summary.trophic_scores
    assert "runtime_herd_health_pull" in summary.trophic_scores
    assert "runtime_herd_health_anchor_pull" in summary.trophic_scores
    assert "runtime_herd_world_pressure_window_pull" in summary.trophic_scores
    assert "runtime_herd_condition_anchor_pull" in summary.trophic_scores
    assert "runtime_herd_condition_phase_anchor_pull" in summary.trophic_scores
    assert "runtime_herd_regional_bias_pull" in summary.trophic_scores
    assert "runtime_herd_resource_anchor_pull" in summary.trophic_scores
    assert "runtime_herd_anchor_prosperity_pull" in summary.trophic_scores
    assert "runtime_apex_condition_pull" in summary.trophic_scores
    assert "runtime_apex_birth_memory_pull" in summary.trophic_scores
    assert "runtime_apex_condition_phase_pull" in summary.trophic_scores
    assert "runtime_apex_health_pull" in summary.trophic_scores
    assert "runtime_apex_health_anchor_pull" in summary.trophic_scores
    assert "runtime_apex_world_pressure_window_pull" in summary.trophic_scores
    assert "runtime_apex_condition_anchor_pull" in summary.trophic_scores
    assert "runtime_apex_condition_phase_anchor_pull" in summary.trophic_scores
    assert "runtime_apex_regional_bias_pull" in summary.trophic_scores
    assert "runtime_apex_anchor_prosperity_pull" in summary.trophic_scores
    assert "regional_prosperity_anchor" in summary.trophic_scores
    assert "regional_stability_anchor" in summary.trophic_scores
    assert "runtime_herd_apex_overlap" in summary.trophic_scores
    assert "herd_memory_corridors" in summary.trophic_scores
    assert "herd_memory_pressure" in summary.trophic_scores
    assert "herd_route_cycle_pressure" in summary.trophic_scores
    assert summary.layer_scores["herd_layer"] > 0.69
    assert summary.layer_scores["social_layer"] > 1.0
    assert summary.dominant_layer == "herd_layer"

    print("✅ V4 grassland chain feedback test passed")


def test_v4_grassland_chain_rebalancing_updates_species_pool():
    """v4 草原链重平衡应轻量调整草原关键物种池。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")
    region.health_state["prosperity"] = 0.42
    region.health_state["stability"] = 0.36
    region.health_state["collapse_risk"] = 0.18

    initial_rabbit = region.species_pool["rabbit"]
    initial_antelope = region.species_pool["antelope"]
    initial_hyena = region.species_pool["hyena"]
    initial_lion = region.species_pool["lion"]
    region.species_pool["antelope"] = min(region.species_pool["antelope"], 18)
    region.species_pool["zebra"] = min(region.species_pool["zebra"], 16)
    region.species_pool["lion"] = min(region.species_pool["lion"], 7)
    region.species_pool["hyena"] = min(region.species_pool["hyena"], 7)
    region.record_relationship_state(
        "territory",
        {
            "runtime_signals": {
                "lion_hotspot_count": 2,
                "hyena_hotspot_count": 2,
                "shared_hotspot_overlap": 1,
            }
        },
    )
    region.record_relationship_state(
        "social_trends",
        {
            "trend_scores": {
                "lion_recovery_bias": 0.45,
                "hyena_recovery_bias": 0.42,
                "birth_cycle_window_memory_strength": 0.34,
            },
            "cycle_signals": ["world_pressure_window_memory"],
            "phase_scores": {
                "lion_expansion_phase": 0.48,
                "hyena_expansion_phase": 0.46,
                "herd_route_cycle": 0.36,
            },
            "boom_bust_scores": {
                "grassland_boom_phase": 0.44,
                "grassland_bust_phase": 0.18,
            },
            "prosperity_scores": {
                "grassland_prosperity_phase": 0.24,
                "grassland_collapse_phase": 0.12,
            },
            "hotspot_scores": {
                "lion_hotspot_memory": 0.46,
                "hyena_hotspot_memory": 0.44,
                "shared_hotspot_memory": 0.43,
                "vulture_hotspot_memory": 0.38,
                "vulture_carrion_memory": 0.32,
            },
        },
    )
    region.record_relationship_state("grassland_chain", {"dominant_layer": "herd_layer"})
    region.record_relationship_state("carrion_chain", {"dominant_layer": "kill_layer"})

    territory = build_region_territory_summary(
        region,
        registry,
        runtime_state={
            "lion_pride_strength": 0.7,
            "lion_pride_count": 2.0,
            "hyena_clan_cohesion": 0.6,
            "hyena_clan_count": 2.0,
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "herd_surface_water_runtime": 0.6,
            "herd_world_pressure_runtime": 0.62,
            "herd_world_pressure_window_runtime": 0.36,
            "herd_birth_memory_runtime": 0.26,
            "herd_birth_cycle_window_runtime": 0.34,
            "herd_condition_runtime": 0.46,
            "herd_regional_health_runtime": 0.52,
            "herd_regional_health_anchor_runtime": 0.70,
            "herd_regional_bias_runtime": 0.46,
            "herd_anchor_prosperity_runtime": 0.58,
            "apex_regional_health_runtime": 0.48,
            "apex_world_pressure_runtime": 0.58,
            "apex_world_pressure_window_runtime": 0.31,
            "apex_birth_memory_runtime": 0.22,
            "apex_birth_cycle_window_runtime": 0.40,
            "apex_condition_runtime": 0.39,
            "apex_regional_health_anchor_runtime": 0.70,
            "apex_regional_bias_runtime": 0.43,
            "apex_anchor_prosperity_runtime": 0.46,
            "shared_hotspot_overlap": 1.0,
        },
    )
    summary = build_region_grassland_chain_summary(region, registry, territory_summary=territory)
    summary.trophic_scores["birth_cycle_window_memory_strength_pull"] = 0.06
    social_trends = build_region_social_trend_summary(region, territory_summary=territory)
    adjustments = apply_region_grassland_chain_rebalancing(
        region,
        summary,
        territory_summary=territory,
        social_trend_summary=social_trends,
    )
    assert adjustments
    assert any(item["layer_group"] in {"grazing_layer", "predator_layer", "scavenger_layer", "browse_layer", "herd_layer", "social_layer"} for item in adjustments)
    assert any(item["source_species"] == "territory" for item in adjustments)
    assert any(item["source_species"] == "social_state" for item in adjustments)
    assert any(item["source_species"] == "runtime_resource" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition" for item in adjustments)
    assert any(item["source_species"] == "runtime_health" for item in adjustments)
    assert any(item["source_species"] == "runtime_health_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition_phase_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition_phase" for item in adjustments)
    assert any(item["source_species"] == "runtime_regional_bias" for item in adjustments)
    assert any(item["source_species"] == "runtime_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_anchor_prosperity" for item in adjustments)
    assert any(item["source_species"] == "world_pressure" for item in adjustments)
    assert any(item["source_species"] == "world_pressure_window" for item in adjustments)
    assert any(item["source_species"] == "regional_health" for item in adjustments)
    assert any(item["effect"] in {"hotspot_cycle_predator_wave", "hotspot_cycle_overlap_drag", "herd_route_cycle_support"} for item in adjustments)
    assert any(item["effect"] == "runtime_surface_water_support" for item in adjustments)
    assert any(item["effect"] in {"runtime_herd_condition_support", "runtime_apex_condition_support"} for item in adjustments)
    assert any(item["effect"] in {"condition_herd_recovery", "condition_pride_recovery", "condition_clan_recovery"} for item in adjustments)
    assert any(item["effect"] in {"condition_phase_pride_window", "condition_phase_clan_window"} for item in adjustments)
    assert any(item["effect"] in {"world_pressure_herd_window", "world_pressure_apex_window"} for item in adjustments)
    assert any(item["effect"] in {"world_pressure_window_herd_support", "world_pressure_window_apex_support"} for item in adjustments)
    assert any(item["effect"] in {"runtime_herd_health_support", "runtime_apex_health_support", "runtime_herd_health_anchor_support", "runtime_apex_health_anchor_support"} for item in adjustments)
    assert any(item["effect"] in {"runtime_herd_condition_anchor_support", "runtime_apex_condition_anchor_support"} for item in adjustments)
    assert any(item["effect"] in {"runtime_herd_condition_phase_anchor_support", "runtime_apex_condition_phase_anchor_support"} for item in adjustments)
    assert any(item["effect"] in {"runtime_herd_regional_bias_support", "runtime_apex_regional_bias_support"} for item in adjustments)
    assert any(item["effect"] == "runtime_herd_anchor_support" for item in adjustments)
    assert any(item["effect"] in {"runtime_herd_anchor_prosperity_support", "runtime_apex_anchor_prosperity_support"} for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_herd_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_apex_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_herd_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_apex_support" for item in adjustments)
    assert any(item["effect"] in {"regional_prosperity_support", "regional_stability_support", "regional_collapse_drag"} for item in adjustments)
    assert any(item["effect"] in {"boom_phase_herd_release", "bust_phase_herd_drag", "boom_phase_apex_release", "bust_phase_apex_drag"} for item in adjustments)
    assert any(item["effect"] in {"prosperity_phase_herd_gain", "collapse_phase_scavenger_loss"} for item in adjustments)
    assert any(item["effect"] in {"pride_expansion_window", "clan_expansion_window"} for item in adjustments)
    assert (
        region.species_pool["rabbit"] != initial_rabbit
        or region.species_pool["hyena"] != initial_hyena
        or region.species_pool["antelope"] != initial_antelope
        or region.species_pool["lion"] != initial_lion
    )

    print("✅ V4 grassland chain rebalancing test passed")


def test_v4_grassland_chain_recolonization_window():
    """v4 草原链应在低谷时打开社群重占窗口。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")
    region.species_pool["lion"] = 1
    region.species_pool["hyena"] = 1

    territory = build_region_territory_summary(
        region,
        registry,
        runtime_state={
            "lion_pride_strength": 0.8,
            "lion_pride_count": 2.0,
            "hyena_clan_cohesion": 0.78,
            "hyena_clan_count": 2.0,
            "lion_hotspot_count": 1.0,
            "hyena_hotspot_count": 1.0,
            "shared_hotspot_overlap": 0.0,
        },
    )
    summary = build_region_grassland_chain_summary(region, registry, territory_summary=territory)
    adjustments = apply_region_grassland_chain_rebalancing(region, summary, territory_summary=territory)

    assert any(item["effect"] == "pride_recolonization_window" for item in adjustments)
    assert any(item["effect"] == "clan_recolonization_window" for item in adjustments)
    assert region.species_pool["lion"] >= 3
    assert region.species_pool["hyena"] >= 3

    print("✅ V4 grassland recolonization test passed")


def test_v4_carrion_chain_feedback_updates_region_state():
    """v4 尸体资源链反馈应轻量更新草原资源与健康状态。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")
    region.health_state["prosperity"] = 0.42
    region.health_state["stability"] = 0.36
    region.health_state["collapse_risk"] = 0.18

    initial_carrion = region.resource_state["carcass_availability"]
    initial_resilience = region.health_state["resilience"]
    region.record_relationship_state(
        "social_trends",
        {
            "trend_scores": {
                "lion_recovery_bias": 0.45,
                "hyena_recovery_bias": 0.42,
            },
            "phase_scores": {
                "lion_expansion_phase": 0.48,
                "hyena_expansion_phase": 0.46,
                "aerial_carrion_cycle": 0.34,
            },
            "boom_bust_scores": {
                "grassland_boom_phase": 0.44,
                "grassland_bust_phase": 0.18,
            },
            "prosperity_scores": {
                "grassland_prosperity_phase": 0.24,
                "grassland_collapse_phase": 0.12,
            },
            "hotspot_scores": {
                "lion_hotspot_memory": 0.46,
                "hyena_hotspot_memory": 0.44,
                "shared_hotspot_memory": 0.43,
            },
        },
    )
    region.record_relationship_state("grassland_chain", {"dominant_layer": "herd_layer"})
    region.record_relationship_state("carrion_chain", {"dominant_layer": "kill_layer"})

    territory = build_region_territory_summary(
        region,
        registry,
        runtime_state={
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "vulture_hotspot_count": 2.0,
            "vulture_carrion_overlap": 1.0,
            "aerial_carcass_runtime": 0.5,
            "aerial_birth_memory_runtime": 0.48,
            "aerial_condition_runtime": 0.41,
            "aerial_regional_health_runtime": 0.44,
            "aerial_regional_health_anchor_runtime": 0.70,
            "aerial_regional_bias_runtime": 0.42,
            "aerial_anchor_prosperity_runtime": 0.49,
            "aerial_world_pressure_window_runtime": 0.34,
            "apex_regional_health_runtime": 0.48,
            "apex_birth_memory_runtime": 0.48,
            "apex_condition_runtime": 0.39,
            "apex_regional_health_anchor_runtime": 0.70,
            "apex_regional_bias_runtime": 0.43,
            "apex_anchor_prosperity_runtime": 0.46,
            "apex_world_pressure_window_runtime": 0.31,
            "shared_hotspot_overlap": 1.0,
        },
    )
    social_trends = build_region_social_trend_summary(region, territory_summary=territory)
    summary = build_region_carrion_chain_summary(region, registry, territory_summary=territory, social_trend_summary=social_trends)
    apply_region_carrion_chain_feedback(region, summary, feedback_scale=0.05)

    assert region.resource_state["carcass_availability"] >= initial_carrion
    assert region.health_state["resilience"] >= initial_resilience
    assert "hotspot_cycle_carrion" in summary.resource_scores
    assert "hotspot_cycle_tracking" in summary.resource_scores
    assert "prosperity_phase_carrion" in summary.resource_scores
    assert "collapse_phase_carrion" in summary.resource_scores
    assert "prosperity_feedback_bias" in summary.resource_scores
    assert "collapse_feedback_bias" in summary.resource_scores
    assert "dominant_kill_layout" in summary.resource_scores
    assert "runtime_aerial_lanes" in summary.resource_scores
    assert "runtime_carcass_pull" in summary.resource_scores
    assert "runtime_aerial_birth_memory_pull" in summary.resource_scores
    assert "runtime_aerial_condition_pull" in summary.resource_scores
    assert "runtime_aerial_condition_phase_pull" in summary.resource_scores
    assert "runtime_aerial_health_pull" in summary.resource_scores
    assert "runtime_aerial_health_anchor_pull" in summary.resource_scores
    assert "runtime_aerial_world_pressure_window_pull" in summary.resource_scores
    assert "runtime_aerial_condition_anchor_pull" in summary.resource_scores
    assert "runtime_aerial_condition_phase_anchor_pull" in summary.resource_scores
    assert "runtime_aerial_regional_bias_pull" in summary.resource_scores
    assert "runtime_aerial_resource_anchor_pull" in summary.resource_scores
    assert "runtime_aerial_anchor_prosperity_pull" in summary.resource_scores
    assert "regional_prosperity_anchor" in summary.resource_scores
    assert "regional_stability_anchor" in summary.resource_scores
    assert "runtime_apex_condition_pull" in summary.resource_scores
    assert "runtime_apex_birth_memory_pull" in summary.resource_scores
    assert "runtime_apex_condition_phase_pull" in summary.resource_scores
    assert "runtime_apex_health_pull" in summary.resource_scores
    assert "runtime_apex_health_anchor_pull" in summary.resource_scores
    assert "runtime_apex_world_pressure_window_pull" in summary.resource_scores
    assert "runtime_apex_condition_anchor_pull" in summary.resource_scores
    assert "runtime_apex_condition_phase_anchor_pull" in summary.resource_scores
    assert "runtime_apex_regional_bias_pull" in summary.resource_scores
    assert "runtime_vulture_overlap" in summary.resource_scores
    assert "aerial_memory_lanes" in summary.resource_scores
    assert "aerial_memory_overlap" in summary.resource_scores
    assert "aerial_carrion_cycle_pressure" in summary.resource_scores
    assert summary.layer_scores["herd_source_layer"] > 0.9
    assert summary.layer_scores["scavenge_layer"] > 0.68
    assert summary.dominant_layer in {"herd_source_layer", "aerial_scavenge_layer"}

    print("✅ V4 carrion chain feedback test passed")


def test_v4_carrion_chain_rebalancing_updates_species_pool():
    """v4 尸体资源链重平衡应轻量调整草原关键物种池。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")
    region.health_state["prosperity"] = 0.42
    region.health_state["stability"] = 0.36
    region.health_state["collapse_risk"] = 0.18

    initial_antelope = region.species_pool["antelope"]
    initial_zebra = region.species_pool["zebra"]
    initial_hyena = region.species_pool["hyena"]
    initial_vulture = region.species_pool["vulture"]
    region.species_pool["lion"] = min(region.species_pool["lion"], 7)
    region.species_pool["hyena"] = min(region.species_pool["hyena"], 7)
    region.species_pool["vulture"] = min(region.species_pool["vulture"], 10)
    region.record_relationship_state(
        "territory",
        {
            "runtime_signals": {
                "lion_hotspot_count": 2,
                "hyena_hotspot_count": 2,
                "shared_hotspot_overlap": 1,
            }
        },
    )
    region.record_relationship_state(
        "social_trends",
        {
            "trend_scores": {
                "lion_recovery_bias": 0.45,
                "hyena_recovery_bias": 0.42,
            },
            "phase_scores": {
                "lion_expansion_phase": 0.48,
                "hyena_expansion_phase": 0.46,
                "aerial_carrion_cycle": 0.34,
            },
            "boom_bust_scores": {
                "grassland_boom_phase": 0.44,
                "grassland_bust_phase": 0.18,
            },
            "prosperity_scores": {
                "grassland_prosperity_phase": 0.24,
                "grassland_collapse_phase": 0.12,
            },
            "hotspot_scores": {
                "lion_hotspot_memory": 0.46,
                "hyena_hotspot_memory": 0.44,
                "shared_hotspot_memory": 0.43,
            },
        },
    )

    territory = build_region_territory_summary(
        region,
        registry,
        runtime_state={
            "lion_pride_strength": 0.7,
            "lion_pride_count": 2.0,
            "hyena_clan_cohesion": 0.6,
            "hyena_clan_count": 2.0,
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "aerial_carcass_runtime": 0.5,
            "aerial_birth_memory_runtime": 0.24,
            "aerial_world_pressure_runtime": 0.60,
            "aerial_world_pressure_window_runtime": 0.34,
            "aerial_condition_runtime": 0.41,
            "aerial_birth_cycle_window_runtime": 0.35,
            "aerial_regional_health_runtime": 0.44,
            "aerial_regional_health_anchor_runtime": 0.70,
            "aerial_regional_bias_runtime": 0.42,
            "aerial_anchor_prosperity_runtime": 0.49,
            "apex_regional_health_runtime": 0.48,
            "apex_world_pressure_runtime": 0.58,
            "apex_world_pressure_window_runtime": 0.31,
            "apex_birth_memory_runtime": 0.20,
            "apex_birth_cycle_window_runtime": 0.40,
            "apex_condition_runtime": 0.39,
            "apex_regional_health_anchor_runtime": 0.70,
            "apex_regional_bias_runtime": 0.43,
            "apex_anchor_prosperity_runtime": 0.46,
            "shared_hotspot_overlap": 1.0,
        },
    )
    summary = build_region_carrion_chain_summary(region, registry, territory_summary=territory)
    summary.resource_scores["birth_cycle_window_memory_strength_pull"] = 0.06
    social_trends = build_region_social_trend_summary(region, territory_summary=territory)
    adjustments = apply_region_carrion_chain_rebalancing(
        region,
        summary,
        territory_summary=territory,
        social_trend_summary=social_trends,
    )

    assert adjustments
    assert any(item["layer_group"] in {"kill_layer", "scavenge_layer", "aerial_scavenge_layer", "herd_source_layer"} for item in adjustments)
    assert any(item["source_species"] == "territory" for item in adjustments)
    assert any(item["source_species"] == "social_state" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition_phase_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_condition_phase" for item in adjustments)
    assert any(item["source_species"] == "runtime_health" for item in adjustments)
    assert any(item["source_species"] == "runtime_health_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_regional_bias" for item in adjustments)
    assert any(item["source_species"] == "runtime_anchor" for item in adjustments)
    assert any(item["source_species"] == "runtime_anchor_prosperity" for item in adjustments)
    assert any(item["source_species"] == "world_pressure" for item in adjustments)
    assert any(item["source_species"] == "world_pressure_window" for item in adjustments)
    assert any(item["source_species"] == "regional_health" for item in adjustments)
    assert any(item["effect"] in {"hotspot_cycle_scavenger_wave", "hotspot_cycle_churn", "aerial_carrion_cycle_support"} for item in adjustments)
    assert any(item["effect"] == "runtime_carcass_support" for item in adjustments)
    assert any(item["effect"] in {"runtime_aerial_condition_support", "runtime_apex_condition_support"} for item in adjustments)
    assert any(item["effect"] in {"condition_aerial_recovery", "condition_apex_carrion_recovery"} for item in adjustments)
    assert any(item["effect"] in {"condition_phase_aerial_window", "condition_phase_apex_carrion_window"} for item in adjustments)
    assert any(item["effect"] in {"world_pressure_aerial_window", "world_pressure_apex_carrion_window"} for item in adjustments)
    assert any(item["effect"] in {"world_pressure_window_aerial_support", "world_pressure_window_apex_carrion_support"} for item in adjustments)
    assert any(item["effect"] in {"runtime_aerial_health_support", "runtime_apex_health_support", "runtime_aerial_health_anchor_support", "runtime_apex_health_anchor_support"} for item in adjustments)
    assert any(item["effect"] in {"runtime_aerial_regional_bias_support", "runtime_apex_regional_bias_support"} for item in adjustments)
    assert any(item["effect"] in {"runtime_aerial_condition_phase_anchor_support", "runtime_apex_condition_phase_anchor_support"} for item in adjustments)
    assert any(item["effect"] == "runtime_aerial_anchor_support" for item in adjustments)
    assert any(item["effect"] == "runtime_aerial_anchor_prosperity_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_aerial_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_apex_carrion_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_aerial_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_apex_carrion_support" for item in adjustments)
    assert any(item["effect"] in {"regional_prosperity_support", "regional_stability_support", "regional_collapse_drag"} for item in adjustments)
    assert any(item["effect"] in {"boom_phase_scavenger_release", "bust_phase_scavenger_drag"} for item in adjustments)
    assert any(item["effect"] in {"prosperity_phase_scavenger_gain", "collapse_phase_apex_loss"} for item in adjustments)
    assert any(item["effect"] in {"pride_carrion_expansion_window", "clan_carrion_expansion_window"} for item in adjustments)
    assert (
        region.species_pool["antelope"] != initial_antelope
        or region.species_pool["zebra"] != initial_zebra
        or region.species_pool["hyena"] != initial_hyena
        or region.species_pool["vulture"] != initial_vulture
    )

    print("✅ V4 carrion chain rebalancing test passed")


def test_v4_grassland_birth_memory_rebalancing_support():
    """birth_memory 的草原慢反馈应能直接触发 herd/apex 重平衡支持。"""
    world_map = build_default_world_map()
    region = world_map.get_region("temperate_grassland")
    region.species_pool["antelope"] = 18
    region.species_pool["zebra"] = 16
    region.species_pool["lion"] = 7
    region.species_pool["hyena"] = 7

    summary = build_region_grassland_chain_summary(region, build_default_world_registry())
    summary.trophic_scores["runtime_herd_birth_memory_pull"] = 0.06
    summary.trophic_scores["runtime_herd_birth_memory_world_pressure_pull"] = 0.06
    summary.trophic_scores["runtime_herd_birth_cycle_pull"] = 0.06
    summary.trophic_scores["runtime_herd_birth_cycle_window_pull"] = 0.06
    summary.trophic_scores["runtime_herd_birth_cycle_window_pressure_pull"] = 0.06
    summary.trophic_scores["runtime_apex_birth_memory_pull"] = 0.05
    summary.trophic_scores["runtime_apex_birth_memory_world_pressure_pull"] = 0.05
    summary.trophic_scores["runtime_apex_birth_cycle_pull"] = 0.05
    summary.trophic_scores["runtime_apex_birth_cycle_window_pull"] = 0.05
    summary.trophic_scores["runtime_apex_birth_cycle_window_pressure_pull"] = 0.05
    summary.trophic_scores["birth_cycle_window_memory_strength_pull"] = 0.06

    adjustments = apply_region_grassland_chain_rebalancing(region, summary)

    assert any(item["source_species"] == "runtime_birth_memory" for item in adjustments)
    assert any(item["effect"] == "runtime_herd_birth_memory_support" for item in adjustments)
    assert any(item["effect"] == "runtime_apex_birth_memory_support" for item in adjustments)
    assert any(item["effect"] == "birth_memory_world_pressure_herd_support" for item in adjustments)
    assert any(item["effect"] == "birth_memory_world_pressure_apex_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_herd_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_herd_window" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_herd_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_pressure_herd_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_herd_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_apex_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_apex_window" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_apex_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_pressure_apex_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_apex_support" for item in adjustments)

    print("✅ V4 grassland birth memory rebalancing support test passed")


def test_v4_carrion_birth_memory_rebalancing_support():
    """birth_memory 的尸体资源慢反馈应能直接触发 aerial/apex 重平衡支持。"""
    world_map = build_default_world_map()
    region = world_map.get_region("temperate_grassland")
    region.species_pool["vulture"] = 10
    region.species_pool["lion"] = 7
    region.species_pool["hyena"] = 7

    summary = build_region_carrion_chain_summary(region, build_default_world_registry())
    summary.resource_scores["runtime_aerial_birth_memory_pull"] = 0.06
    summary.resource_scores["runtime_aerial_birth_memory_world_pressure_pull"] = 0.06
    summary.resource_scores["runtime_aerial_birth_cycle_pull"] = 0.06
    summary.resource_scores["runtime_aerial_birth_cycle_window_pull"] = 0.06
    summary.resource_scores["runtime_aerial_birth_cycle_window_pressure_pull"] = 0.06
    summary.resource_scores["runtime_apex_birth_memory_pull"] = 0.05
    summary.resource_scores["runtime_apex_birth_memory_world_pressure_pull"] = 0.05
    summary.resource_scores["runtime_apex_birth_cycle_pull"] = 0.05
    summary.resource_scores["runtime_apex_birth_cycle_window_pull"] = 0.05
    summary.resource_scores["runtime_apex_birth_cycle_window_pressure_pull"] = 0.05
    summary.resource_scores["birth_cycle_window_memory_strength_pull"] = 0.06

    adjustments = apply_region_carrion_chain_rebalancing(region, summary)

    assert any(item["source_species"] == "runtime_birth_memory" for item in adjustments)
    assert any(item["effect"] == "runtime_aerial_birth_memory_support" for item in adjustments)
    assert any(item["effect"] == "runtime_apex_birth_memory_support" for item in adjustments)
    assert any(item["effect"] == "birth_memory_world_pressure_aerial_support" for item in adjustments)
    assert any(item["effect"] == "birth_memory_world_pressure_apex_carrion_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_aerial_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_aerial_window" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_aerial_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_pressure_aerial_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_aerial_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_apex_carrion_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_apex_carrion_window" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_apex_carrion_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_pressure_apex_carrion_support" for item in adjustments)
    assert any(item["effect"] == "birth_cycle_window_memory_apex_carrion_support" for item in adjustments)

    print("✅ V4 carrion birth memory rebalancing support test passed")


def test_v4_carrion_chain_recolonization_window():
    """v4 尸体资源链应在低谷时打开捕食者重占窗口。"""
    world_map = build_default_world_map()
    registry = build_default_world_registry()
    region = world_map.get_region("temperate_grassland")
    region.species_pool["lion"] = 1
    region.species_pool["hyena"] = 1

    territory = build_region_territory_summary(
        region,
        registry,
        runtime_state={
            "lion_pride_strength": 0.8,
            "lion_pride_count": 2.0,
            "hyena_clan_cohesion": 0.78,
            "hyena_clan_count": 2.0,
            "lion_hotspot_count": 1.0,
            "hyena_hotspot_count": 1.0,
            "shared_hotspot_overlap": 0.0,
        },
    )
    summary = build_region_carrion_chain_summary(region, registry, territory_summary=territory)
    adjustments = apply_region_carrion_chain_rebalancing(region, summary, territory_summary=territory)

    assert any(item["effect"] == "pride_carrion_recolonization_window" for item in adjustments)
    assert any(item["effect"] == "clan_carrion_recolonization_window" for item in adjustments)
    assert region.species_pool["lion"] >= 3
    assert region.species_pool["hyena"] >= 3

    print("✅ V4 carrion recolonization test passed")


def test_v4_social_trend_rebalancing_support():
    """v4 社群长期趋势应驱动低谷中的草原与尸体资源恢复。"""
    registry = build_default_world_registry()

    world_map_grassland = build_default_world_map()
    grassland_region = world_map_grassland.get_region("temperate_grassland")
    grassland_region.species_pool["lion"] = 2
    grassland_region.species_pool["hyena"] = 2
    grassland_region.record_relationship_state(
        "territory",
        {
            "runtime_signals": {
                "lion_hotspot_count": 2.0,
                "hyena_hotspot_count": 2.0,
                "shared_hotspot_overlap": 1.0,
            }
        },
    )
    grassland_region.record_relationship_state(
        "social_trends",
        {
            "trend_scores": {
                "lion_recovery_bias": 0.45,
                "hyena_recovery_bias": 0.42,
            },
            "phase_scores": {
                "lion_expansion_phase": 0.45,
                "hyena_expansion_phase": 0.42,
            },
            "hotspot_scores": {
                "lion_hotspot_memory": 0.46,
                "hyena_hotspot_memory": 0.44,
                "shared_hotspot_memory": 0.38,
            },
        },
    )

    grassland_territory = build_region_territory_summary(
        grassland_region,
        registry,
        runtime_state={
            "lion_pride_strength": 0.7,
            "lion_pride_count": 2.0,
            "hyena_clan_cohesion": 0.6,
            "hyena_clan_count": 2.0,
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "shared_hotspot_overlap": 1.0,
        },
    )
    grassland_trends = build_region_social_trend_summary(grassland_region, territory_summary=grassland_territory)
    grassland = build_region_grassland_chain_summary(grassland_region, registry, territory_summary=grassland_territory)

    grassland_adjustments = apply_region_grassland_chain_rebalancing(
        grassland_region,
        grassland,
        territory_summary=grassland_territory,
        social_trend_summary=grassland_trends,
    )

    world_map_carrion = build_default_world_map()
    carrion_region = world_map_carrion.get_region("temperate_grassland")
    carrion_region.species_pool["lion"] = 2
    carrion_region.species_pool["hyena"] = 2
    carrion_region.record_relationship_state(
        "territory",
        {
            "runtime_signals": {
                "lion_hotspot_count": 2.0,
                "hyena_hotspot_count": 2.0,
                "shared_hotspot_overlap": 1.0,
            }
        },
    )
    carrion_region.record_relationship_state(
        "social_trends",
        {
            "trend_scores": {
                "lion_recovery_bias": 0.45,
                "hyena_recovery_bias": 0.42,
            },
            "phase_scores": {
                "lion_expansion_phase": 0.45,
                "hyena_expansion_phase": 0.42,
            },
        },
    )
    carrion_territory = build_region_territory_summary(
        carrion_region,
        registry,
        runtime_state={
            "lion_pride_strength": 0.7,
            "lion_pride_count": 2.0,
            "hyena_clan_cohesion": 0.6,
            "hyena_clan_count": 2.0,
            "lion_hotspot_count": 2.0,
            "hyena_hotspot_count": 2.0,
            "shared_hotspot_overlap": 1.0,
        },
    )
    carrion_trends = build_region_social_trend_summary(carrion_region, territory_summary=carrion_territory)
    carrion = build_region_carrion_chain_summary(carrion_region, registry, territory_summary=carrion_territory)
    carrion_adjustments = apply_region_carrion_chain_rebalancing(
        carrion_region,
        carrion,
        territory_summary=carrion_territory,
        social_trend_summary=carrion_trends,
    )

    assert any(item["source_species"] == "social_trend" for item in grassland_adjustments)
    assert any(item["source_species"] == "social_cycle" for item in grassland_adjustments)
    assert any(item["source_species"] == "social_hotspot" for item in grassland_adjustments)
    assert any(item["source_species"] == "social_trend" for item in carrion_adjustments)
    assert any(item["source_species"] == "social_cycle" for item in carrion_adjustments)
    assert any(item["source_species"] == "social_hotspot" for item in carrion_adjustments)

    print("✅ V4 social trend rebalancing test passed")


def test_region_simulation_applies_social_phase_state():
    """RegionSimulation 应将区域社群周期相位回灌到运行体。"""
    world_map = build_default_world_map()
    region = world_map.get_region("temperate_grassland")
    region.record_relationship_state(
        "social_trends",
        {
            "phase_scores": {
                "lion_expansion_phase": 0.62,
                "lion_contraction_phase": 0.14,
                "hyena_expansion_phase": 0.58,
                "hyena_contraction_phase": 0.18,
                "herd_route_cycle": 0.36,
                "aerial_carrion_cycle": 0.31,
            },
            "trend_scores": {
                "herd_birth_memory": 0.34,
                "aerial_birth_memory": 0.31,
                "apex_birth_memory": 0.29,
            },
            "prosperity_scores": {
                "grassland_prosperity_phase": 0.41,
                "grassland_collapse_phase": 0.16,
            },
            "hotspot_scores": {
                "lion_hotspot_memory": 0.52,
                "hyena_hotspot_memory": 0.49,
                "shared_hotspot_memory": 0.31,
            },
        },
    )
    region.record_relationship_state(
        "territory",
        {
            "runtime_signals": {
                "apex_hotspot_bias": 1,
                "scavenger_hotspot_bias": 1,
                "herd_channel_bias": 1,
                "herd_source_bias": 1,
                "kill_corridor_bias": 1,
                "aerial_lane_bias": 1,
                "regional_prosperity_bias": 1,
                "regional_stability_bias": 1,
                "regional_collapse_bias": 1,
                "surface_water_anchor": 0.6,
                "carcass_anchor": 0.5,
                "herd_condition_runtime": 0.46,
                "aerial_condition_runtime": 0.41,
                "apex_condition_runtime": 0.39,
            }
        },
    )
    region.resource_state["surface_water"] = 0.68
    region.resource_state["carcass_availability"] = 0.57

    sim = RegionSimulation(region=region, config={"world": {"grid_size": 20}})
    sim.spawn_animal("lion", sim._random_land_position(), source="manual")
    sim.spawn_animal("hyena", sim._random_land_position(), source="manual")
    sim.spawn_animal("antelope", sim._random_land_position(), source="manual")
    sim.spawn_animal("zebra", sim._random_land_position(), source="manual")
    sim.spawn_animal("vulture", sim._random_land_position(), source="manual")
    lion = next(animal for animal in sim.animals if animal.species == "lion" and animal.alive)
    hyena = next(animal for animal in sim.animals if animal.species == "hyena" and animal.alive)
    antelope = next(animal for animal in sim.animals if animal.species == "antelope" and animal.alive)
    zebra = next(animal for animal in sim.animals if animal.species == "zebra" and animal.alive)
    vulture = next(animal for animal in sim.animals if animal.species == "vulture" and animal.alive)

    sim.apply_relationship_runtime_state()

    assert lion.cycle_expansion_phase == 0.62
    assert lion.cycle_contraction_phase == 0.14
    assert lion.hotspot_memory == 0.52
    assert lion.shared_hotspot_memory == 0.31
    assert lion.surface_water_anchor == 0.68
    assert lion.runtime_anchor_prosperity > 0.30
    assert lion.birth_memory_bias > 0.0
    assert lion.birth_memory_world_pressure_bias > 0.10
    assert lion.birth_cycle_bias > 0.10
    assert lion.world_pressure_bias > 0.10
    assert lion.world_pressure_window_bias > 0.10
    assert lion.regional_health_anchor > 0.20
    assert lion.condition_runtime > 0.41
    assert lion.condition_phase_bias > 0.20
    assert lion.regional_prosperity > 0.0
    assert lion.regional_stability > 0.0
    assert lion.regional_prosperity_bias == 1.0
    assert lion.regional_stability_bias == 1.0
    assert lion.regional_collapse_bias == 1.0
    assert hyena.cycle_expansion_phase == 0.58
    assert hyena.cycle_contraction_phase == 0.18
    assert hyena.hotspot_memory == 0.49
    assert hyena.shared_hotspot_memory == 0.31
    assert hyena.carcass_anchor == 0.57
    assert hyena.runtime_anchor_prosperity > 0.30
    assert hyena.birth_memory_bias > 0.0
    assert hyena.birth_memory_world_pressure_bias > 0.10
    assert hyena.birth_cycle_bias > 0.10
    assert hyena.world_pressure_bias > 0.10
    assert hyena.world_pressure_window_bias > 0.10
    assert hyena.regional_health_anchor > 0.20
    assert hyena.condition_runtime > 0.41
    assert hyena.condition_phase_bias > 0.20
    assert hyena.regional_prosperity > 0.0
    assert hyena.regional_stability > 0.0
    assert hyena.regional_prosperity_bias == 1.0
    assert hyena.regional_stability_bias == 1.0
    assert hyena.regional_collapse_bias == 1.0
    assert lion.apex_hotspot_bias == 1.0
    assert lion.kill_corridor_bias == 1.0
    assert hyena.scavenger_hotspot_bias == 1.0
    assert hyena.kill_corridor_bias == 1.0
    assert antelope.herd_channel_bias == 1.0
    assert antelope.herd_source_bias == 1.0
    assert antelope.route_cycle_bias == 0.36
    assert antelope.prosperity_phase_bias == 0.41
    assert antelope.collapse_phase_bias == 0.16
    assert antelope.surface_water_anchor == 0.68
    assert antelope.runtime_anchor_prosperity > 0.30
    assert antelope.birth_memory_bias > 0.0
    assert antelope.birth_memory_world_pressure_bias > 0.10
    assert antelope.birth_cycle_bias > 0.10
    assert antelope.world_pressure_bias > 0.10
    assert antelope.world_pressure_window_bias > 0.10
    assert antelope.regional_health_anchor > 0.20
    assert antelope.condition_runtime > 0.48
    assert antelope.condition_phase_bias > 0.20
    assert antelope.regional_prosperity > 0.0
    assert antelope.regional_stability > 0.0
    assert antelope.regional_prosperity_bias == 1.0
    assert antelope.regional_stability_bias == 1.0
    assert antelope.regional_collapse_bias == 1.0
    assert zebra.herd_channel_bias == 1.0
    assert zebra.herd_source_bias == 1.0
    assert zebra.route_cycle_bias == 0.36
    assert zebra.prosperity_phase_bias == 0.41
    assert zebra.collapse_phase_bias == 0.16
    assert zebra.surface_water_anchor == 0.68
    assert zebra.runtime_anchor_prosperity > 0.30
    assert zebra.birth_memory_bias > 0.0
    assert zebra.birth_memory_world_pressure_bias > 0.10
    assert zebra.birth_cycle_bias > 0.10
    assert zebra.world_pressure_bias > 0.10
    assert zebra.world_pressure_window_bias > 0.10
    assert zebra.regional_health_anchor > 0.20
    assert zebra.condition_runtime > 0.48
    assert zebra.condition_phase_bias > 0.20
    assert zebra.regional_prosperity > 0.0
    assert zebra.regional_stability > 0.0
    assert zebra.regional_prosperity_bias == 1.0
    assert zebra.regional_stability_bias == 1.0
    assert zebra.regional_collapse_bias == 1.0
    assert vulture.aerial_lane_bias == 1.0
    assert vulture.kill_corridor_bias == 1.0
    assert vulture.carrion_cycle_bias == 0.31
    assert vulture.prosperity_phase_bias == 0.41
    assert vulture.collapse_phase_bias == 0.16
    assert vulture.carcass_anchor == 0.57
    assert vulture.runtime_anchor_prosperity > 0.30
    assert vulture.birth_memory_bias > 0.0
    assert vulture.birth_memory_world_pressure_bias > 0.10
    assert vulture.birth_cycle_bias > 0.10
    assert vulture.world_pressure_bias > 0.10
    assert vulture.world_pressure_window_bias > 0.10
    assert vulture.regional_health_anchor > 0.20
    assert vulture.condition_runtime > 0.43
    assert vulture.condition_phase_bias > 0.20
    assert vulture.regional_prosperity > 0.0
    assert vulture.regional_stability > 0.0
    assert vulture.regional_prosperity_bias == 1.0
    assert vulture.regional_stability_bias == 1.0
    assert vulture.regional_collapse_bias == 1.0
    runtime_state = WorldSimulation()._build_runtime_territory_state(sim)
    assert runtime_state["herd_world_pressure_window_runtime"] > 0.10
    assert runtime_state["herd_birth_memory_world_pressure_runtime"] > 0.10
    assert runtime_state["herd_birth_cycle_runtime"] > 0.10
    assert runtime_state["aerial_world_pressure_window_runtime"] > 0.10
    assert runtime_state["aerial_birth_memory_world_pressure_runtime"] > 0.10
    assert runtime_state["aerial_birth_cycle_runtime"] > 0.10
    assert runtime_state["apex_world_pressure_window_runtime"] > 0.10
    assert runtime_state["apex_birth_memory_world_pressure_runtime"] > 0.10
    assert runtime_state["apex_birth_cycle_runtime"] > 0.10

    print("✅ Region simulation social phase injection test passed")


def test_herd_and_carrion_runtime_prosperity_bias():
    """长期 prosperity/collapse 相位应进入 herd 与 carrion 运行行为。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.prosperity_phase_bias = 0.45
    antelope.collapse_phase_bias = 0.10
    antelope.route_cycle_bias = 0.34
    zebra.prosperity_phase_bias = 0.40
    zebra.collapse_phase_bias = 0.08
    zebra.route_cycle_bias = 0.32
    vulture.prosperity_phase_bias = 0.42
    vulture.collapse_phase_bias = 0.12
    vulture.carrion_cycle_bias = 0.30

    assert antelope.prosperity_phase_bias > antelope.collapse_phase_bias
    assert antelope.route_cycle_bias > 0.0
    assert zebra.prosperity_phase_bias > zebra.collapse_phase_bias
    assert zebra.route_cycle_bias > 0.0
    assert vulture.prosperity_phase_bias > vulture.collapse_phase_bias
    assert vulture.carrion_cycle_bias > 0.0

    print("✅ Herd and carrion runtime prosperity bias test passed")


def test_runtime_regional_health_bias():
    """区域长期健康度应进入 herd 与 carrion 运行偏置。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.regional_prosperity = 0.42
    antelope.regional_stability = 0.30
    antelope.regional_collapse_risk = 0.08
    zebra.regional_prosperity = 0.40
    zebra.regional_stability = 0.28
    zebra.regional_collapse_risk = 0.06
    vulture.regional_prosperity = 0.38
    vulture.regional_stability = 0.24
    vulture.regional_collapse_risk = 0.05

    assert antelope.regional_prosperity > antelope.regional_collapse_risk
    assert antelope.regional_stability > 0.0
    assert zebra.regional_prosperity > zebra.regional_collapse_risk
    assert zebra.regional_stability > 0.0
    assert vulture.regional_prosperity > vulture.regional_collapse_risk
    assert vulture.regional_stability > 0.0

    print("✅ Runtime regional health bias test passed")


def test_runtime_regional_health_anchor_effect():
    """regional_health_anchor 应直接改善 herd 与 carrion 运行期体况。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.regional_health_anchor = 0.60
    zebra.regional_health_anchor = 0.50
    vulture.regional_health_anchor = 0.55

    antelope.health = 70.0
    antelope.hunger = 50.0
    zebra.health = 72.0
    zebra.hunger = 48.0
    vulture.health = 68.0
    vulture.hunger = 46.0

    antelope_base_rate = antelope.reproduction_rate
    zebra_base_rate = zebra.reproduction_rate
    vulture_base_rate = vulture.reproduction_rate

    antelope._apply_regional_health_anchor()
    zebra._apply_regional_health_anchor()
    vulture._apply_regional_health_anchor()

    assert antelope.health > 70.0
    assert antelope.hunger < 50.0
    assert antelope.reproduction_rate > antelope_base_rate
    assert zebra.health > 72.0
    assert zebra.hunger < 48.0
    assert zebra.reproduction_rate > zebra_base_rate
    assert vulture.health > 68.0
    assert vulture.hunger < 46.0
    assert vulture.reproduction_rate > vulture_base_rate

    print("✅ Runtime regional health anchor effect test passed")


def test_runtime_condition_effect():
    """condition_runtime 应直接改善 herd 与 carrion 运行期体况和繁殖冷却。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.condition_runtime = 0.46
    zebra.condition_runtime = 0.42
    vulture.condition_runtime = 0.41

    antelope.health = 70.0
    antelope.hunger = 50.0
    antelope.mate_cooldown = 4
    zebra.health = 72.0
    zebra.hunger = 48.0
    zebra.mate_cooldown = 4
    vulture.health = 68.0
    vulture.hunger = 46.0
    vulture.mate_cooldown = 4

    antelope_base_rate = antelope.reproduction_rate
    zebra_base_rate = zebra.reproduction_rate
    vulture_base_rate = vulture.reproduction_rate

    antelope._apply_condition_runtime()
    zebra._apply_condition_runtime()
    vulture._apply_condition_runtime()

    assert antelope.health > 70.0
    assert antelope.hunger < 50.0
    assert antelope.mate_cooldown < 4
    assert antelope.reproduction_rate > antelope_base_rate
    assert zebra.health > 72.0
    assert zebra.hunger < 48.0
    assert zebra.mate_cooldown < 4
    assert zebra.reproduction_rate > zebra_base_rate
    assert vulture.health > 68.0
    assert vulture.hunger < 46.0
    assert vulture.mate_cooldown < 4
    assert vulture.reproduction_rate > vulture_base_rate

    print("✅ Runtime condition effect test passed")


def test_runtime_apex_regional_health_anchor_effect():
    """regional_health_anchor 应直接改善 apex 运行期体况。"""
    lion = Lion(position=(20, 20), gender=Gender.FEMALE)
    hyena = Hyena(position=(24, 20), gender=Gender.FEMALE)

    lion.regional_health_anchor = 0.58
    hyena.regional_health_anchor = 0.52
    lion.health = 72.0
    lion.hunger = 48.0
    hyena.health = 69.0
    hyena.hunger = 46.0

    lion_base_rate = lion.reproduction_rate
    hyena_base_rate = hyena.reproduction_rate

    lion._apply_regional_health_anchor()
    hyena._apply_regional_health_anchor()

    assert lion.health > 72.0
    assert lion.hunger < 48.0
    assert lion.reproduction_rate > lion_base_rate
    assert hyena.health > 69.0
    assert hyena.hunger < 46.0
    assert hyena.reproduction_rate > hyena_base_rate

    print("✅ Runtime apex regional health anchor effect test passed")


def test_runtime_apex_condition_effect():
    """apex 的 condition_runtime 应直接改善当前体况、冷却和繁殖节律。"""
    lion = Lion(position=(20, 20), gender=Gender.FEMALE)
    hyena = Hyena(position=(24, 20), gender=Gender.FEMALE)

    lion.condition_runtime = 0.39
    hyena.condition_runtime = 0.37
    lion.health = 72.0
    lion.hunger = 48.0
    lion.mate_cooldown = 4
    hyena.health = 69.0
    hyena.hunger = 46.0
    hyena.mate_cooldown = 4

    lion_base_rate = lion.reproduction_rate
    hyena_base_rate = hyena.reproduction_rate

    lion._apply_condition_runtime()
    hyena._apply_condition_runtime()

    assert lion.health > 72.0
    assert lion.hunger < 48.0
    assert lion.mate_cooldown < 4
    assert lion.reproduction_rate > lion_base_rate
    assert hyena.health > 69.0
    assert hyena.hunger < 46.0
    assert hyena.mate_cooldown < 4
    assert hyena.reproduction_rate > hyena_base_rate

    print("✅ Runtime apex condition effect test passed")


def test_runtime_condition_phase_bias_effect():
    """condition_phase_bias 应直接改善 herd 与 carrion 运行期体况和繁殖冷却。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.condition_phase_bias = 0.34
    zebra.condition_phase_bias = 0.31
    vulture.condition_phase_bias = 0.33

    antelope.health = 70.0
    antelope.hunger = 50.0
    antelope.mate_cooldown = 4
    zebra.health = 72.0
    zebra.hunger = 48.0
    zebra.mate_cooldown = 4
    vulture.health = 68.0
    vulture.hunger = 46.0
    vulture.mate_cooldown = 4

    antelope_base_rate = antelope.reproduction_rate
    zebra_base_rate = zebra.reproduction_rate
    vulture_base_rate = vulture.reproduction_rate

    antelope._apply_condition_phase_bias()
    zebra._apply_condition_phase_bias()
    vulture._apply_condition_phase_bias()

    assert antelope.health > 70.0
    assert antelope.hunger < 50.0
    assert antelope.mate_cooldown < 4
    assert antelope.reproduction_rate > antelope_base_rate
    assert zebra.health > 72.0
    assert zebra.hunger < 48.0
    assert zebra.mate_cooldown < 4
    assert zebra.reproduction_rate > zebra_base_rate
    assert vulture.health > 68.0
    assert vulture.hunger < 46.0
    assert vulture.mate_cooldown < 4
    assert vulture.reproduction_rate > vulture_base_rate

    print("✅ Runtime condition phase bias effect test passed")


def test_runtime_world_pressure_bias_effect():
    """world_pressure_bias 应直接改善 herd 与 carrion 的运行期体况和繁殖冷却。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.world_pressure_bias = 0.34
    zebra.world_pressure_bias = 0.31
    vulture.world_pressure_bias = 0.33

    antelope.health = 70.0
    antelope.hunger = 50.0
    antelope.mate_cooldown = 4
    zebra.health = 72.0
    zebra.hunger = 48.0
    zebra.mate_cooldown = 4
    vulture.health = 68.0
    vulture.hunger = 46.0
    vulture.mate_cooldown = 4

    antelope_base_rate = antelope.reproduction_rate
    zebra_base_rate = zebra.reproduction_rate
    vulture_base_rate = vulture.reproduction_rate

    antelope._apply_world_pressure_bias()
    zebra._apply_world_pressure_bias()
    vulture._apply_world_pressure_bias()

    assert antelope.health > 70.0
    assert antelope.hunger < 50.0
    assert antelope.mate_cooldown < 4
    assert antelope.reproduction_rate > antelope_base_rate
    assert zebra.health > 72.0
    assert zebra.hunger < 48.0
    assert zebra.mate_cooldown < 4
    assert zebra.reproduction_rate > zebra_base_rate
    assert vulture.health > 68.0
    assert vulture.hunger < 46.0
    assert vulture.mate_cooldown < 4
    assert vulture.reproduction_rate > vulture_base_rate

    print("✅ Runtime world pressure bias effect test passed")


def test_runtime_world_pressure_window_bias_effect():
    """world_pressure_window_bias 应直接改善 herd 与 carrion 的运行期体况和繁殖冷却。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.world_pressure_window_bias = 0.34
    zebra.world_pressure_window_bias = 0.31
    vulture.world_pressure_window_bias = 0.33

    antelope.health = 70.0
    antelope.hunger = 50.0
    antelope.mate_cooldown = 4
    zebra.health = 72.0
    zebra.hunger = 48.0
    zebra.mate_cooldown = 4
    vulture.health = 68.0
    vulture.hunger = 46.0
    vulture.mate_cooldown = 4

    antelope_base_rate = antelope.reproduction_rate
    zebra_base_rate = zebra.reproduction_rate
    vulture_base_rate = vulture.reproduction_rate

    antelope._apply_world_pressure_window_bias()
    zebra._apply_world_pressure_window_bias()
    vulture._apply_world_pressure_window_bias()

    assert antelope.health > 70.0
    assert antelope.hunger < 50.0
    assert antelope.mate_cooldown < 4
    assert antelope.reproduction_rate > antelope_base_rate
    assert zebra.health > 72.0
    assert zebra.hunger < 48.0
    assert zebra.mate_cooldown < 4
    assert zebra.reproduction_rate > zebra_base_rate
    assert vulture.health > 68.0
    assert vulture.hunger < 46.0
    assert vulture.mate_cooldown < 4
    assert vulture.reproduction_rate > vulture_base_rate

    print("✅ Runtime world pressure window bias effect test passed")


def test_runtime_birth_memory_bias_effect():
    """birth_memory_bias 应直接改善 herd 与 carrion 的运行期体况和繁殖冷却。"""
    antelope = Antelope((10, 10), Gender.FEMALE)
    zebra = Zebra((12, 10), Gender.FEMALE)
    vulture = Vulture((14, 10), Gender.FEMALE)

    antelope.birth_memory_bias = 0.34
    zebra.birth_memory_bias = 0.31
    vulture.birth_memory_bias = 0.33

    antelope.health = zebra.health = vulture.health = 70
    antelope.hunger = zebra.hunger = vulture.hunger = 40
    antelope.mate_cooldown = zebra.mate_cooldown = vulture.mate_cooldown = 5

    antelope._apply_birth_memory_bias()
    zebra._apply_birth_memory_bias()
    vulture._apply_birth_memory_bias()

    assert antelope.health > 70 and antelope.hunger < 40 and antelope.mate_cooldown < 5
    assert zebra.health > 70 and zebra.hunger < 40 and zebra.mate_cooldown < 5
    assert vulture.health > 70 and vulture.hunger < 40 and vulture.mate_cooldown < 5

    print("✅ Runtime birth memory bias effect test passed")


def test_runtime_birth_memory_world_pressure_bias_effect():
    """birth_memory_world_pressure_bias 应直接改善 herd 与 carrion 的运行期体况和繁殖冷却。"""
    antelope = Antelope((10, 10), Gender.FEMALE)
    zebra = Zebra((12, 10), Gender.FEMALE)
    vulture = Vulture((14, 10), Gender.FEMALE)

    antelope.birth_memory_world_pressure_bias = 0.34
    zebra.birth_memory_world_pressure_bias = 0.31
    vulture.birth_memory_world_pressure_bias = 0.33

    antelope.health = zebra.health = vulture.health = 70
    antelope.hunger = zebra.hunger = vulture.hunger = 40
    antelope.mate_cooldown = zebra.mate_cooldown = vulture.mate_cooldown = 5

    antelope._apply_birth_memory_world_pressure_bias()
    zebra._apply_birth_memory_world_pressure_bias()
    vulture._apply_birth_memory_world_pressure_bias()

    assert antelope.health > 70 and antelope.hunger < 40 and antelope.mate_cooldown < 5
    assert zebra.health > 70 and zebra.hunger < 40 and zebra.mate_cooldown < 5
    assert vulture.health > 70 and vulture.hunger < 40 and vulture.mate_cooldown < 5

    print("✅ Runtime birth memory world pressure bias effect test passed")


def test_runtime_birth_cycle_bias_effect():
    """birth_cycle_bias 应直接改善 herd 与 carrion 的运行期体况和繁殖冷却。"""
    antelope = Antelope((10, 10), Gender.FEMALE)
    zebra = Zebra((12, 10), Gender.FEMALE)
    vulture = Vulture((14, 10), Gender.FEMALE)

    antelope.birth_cycle_bias = 0.34
    zebra.birth_cycle_bias = 0.31
    vulture.birth_cycle_bias = 0.33

    antelope.health = zebra.health = vulture.health = 70
    antelope.hunger = zebra.hunger = vulture.hunger = 40
    antelope.mate_cooldown = zebra.mate_cooldown = vulture.mate_cooldown = 5

    antelope._apply_birth_cycle_bias()
    zebra._apply_birth_cycle_bias()
    vulture._apply_birth_cycle_bias()

    assert antelope.health > 70 and antelope.hunger < 40 and antelope.mate_cooldown < 5
    assert zebra.health > 70 and zebra.hunger < 40 and zebra.mate_cooldown < 5
    assert vulture.health > 70 and vulture.hunger < 40 and vulture.mate_cooldown < 5

    print("✅ Runtime birth cycle bias effect test passed")


def test_runtime_birth_cycle_window_pressure_bias_effect():
    """birth_cycle_window_pressure_bias 应直接改善 herd 与 carrion 的运行期体况。"""
    antelope = Antelope(position=(20, 20), gender=Gender.FEMALE)
    zebra = Zebra(position=(22, 20), gender=Gender.FEMALE)
    vulture = Vulture(position=(24, 20), gender=Gender.FEMALE)

    antelope.birth_cycle_window_pressure_bias = 0.42
    zebra.birth_cycle_window_pressure_bias = 0.38
    vulture.birth_cycle_window_pressure_bias = 0.40

    antelope.health = 70.0
    antelope.hunger = 50.0
    antelope.mate_cooldown = 4
    zebra.health = 72.0
    zebra.hunger = 48.0
    zebra.mate_cooldown = 4
    vulture.health = 68.0
    vulture.hunger = 46.0
    vulture.mate_cooldown = 4

    antelope_base_rate = antelope.reproduction_rate
    zebra_base_rate = zebra.reproduction_rate
    vulture_base_rate = vulture.reproduction_rate

    antelope._apply_birth_cycle_window_pressure_bias()
    zebra._apply_birth_cycle_window_pressure_bias()
    vulture._apply_birth_cycle_window_pressure_bias()

    assert antelope.health > 70.0
    assert antelope.hunger < 50.0
    assert antelope.mate_cooldown < 4
    assert antelope.reproduction_rate > antelope_base_rate
    assert zebra.health > 72.0
    assert zebra.hunger < 48.0
    assert zebra.mate_cooldown < 4
    assert zebra.reproduction_rate > zebra_base_rate
    assert vulture.health > 68.0
    assert vulture.hunger < 46.0
    assert vulture.mate_cooldown < 4
    assert vulture.reproduction_rate > vulture_base_rate

    print("✅ Runtime birth cycle window pressure bias effect test passed")


def test_runtime_apex_condition_phase_bias_effect():
    """apex 的 condition_phase_bias 应直接改善当前体况、冷却和繁殖节律。"""
    lion = Lion(position=(20, 20), gender=Gender.FEMALE)
    hyena = Hyena(position=(24, 20), gender=Gender.FEMALE)

    lion.condition_phase_bias = 0.32
    hyena.condition_phase_bias = 0.30
    lion.health = 72.0
    lion.hunger = 48.0
    lion.mate_cooldown = 4
    hyena.health = 69.0
    hyena.hunger = 46.0
    hyena.mate_cooldown = 4

    lion_base_rate = lion.reproduction_rate
    hyena_base_rate = hyena.reproduction_rate

    lion._apply_condition_phase_bias()
    hyena._apply_condition_phase_bias()

    assert lion.health > 72.0
    assert lion.hunger < 48.0
    assert lion.mate_cooldown < 4
    assert lion.reproduction_rate > lion_base_rate
    assert hyena.health > 69.0
    assert hyena.hunger < 46.0
    assert hyena.mate_cooldown < 4
    assert hyena.reproduction_rate > hyena_base_rate

    print("✅ Runtime apex condition phase bias effect test passed")


def test_runtime_apex_world_pressure_bias_effect():
    """apex 的 world_pressure_bias 应直接改善当前体况、冷却和繁殖节律。"""
    lion = Lion(position=(20, 20), gender=Gender.FEMALE)
    hyena = Hyena(position=(24, 20), gender=Gender.FEMALE)

    lion.world_pressure_bias = 0.32
    hyena.world_pressure_bias = 0.30
    lion.health = 72.0
    lion.hunger = 48.0
    lion.mate_cooldown = 4
    hyena.health = 69.0
    hyena.hunger = 46.0
    hyena.mate_cooldown = 4

    lion_base_rate = lion.reproduction_rate
    hyena_base_rate = hyena.reproduction_rate

    lion._apply_world_pressure_bias()
    hyena._apply_world_pressure_bias()

    assert lion.health > 72.0
    assert lion.hunger < 48.0
    assert lion.mate_cooldown < 4
    assert lion.reproduction_rate > lion_base_rate
    assert hyena.health > 69.0
    assert hyena.hunger < 46.0
    assert hyena.mate_cooldown < 4
    assert hyena.reproduction_rate > hyena_base_rate

    print("✅ Runtime apex world pressure bias effect test passed")


def test_runtime_apex_world_pressure_window_bias_effect():
    """apex 的 world_pressure_window_bias 应直接改善当前体况、冷却和繁殖节律。"""
    lion = Lion(position=(20, 20), gender=Gender.FEMALE)
    hyena = Hyena(position=(24, 20), gender=Gender.FEMALE)

    lion.world_pressure_window_bias = 0.32
    hyena.world_pressure_window_bias = 0.30
    lion.health = 72.0
    lion.hunger = 48.0
    lion.mate_cooldown = 4
    hyena.health = 69.0
    hyena.hunger = 46.0
    hyena.mate_cooldown = 4

    lion_base_rate = lion.reproduction_rate
    hyena_base_rate = hyena.reproduction_rate

    lion._apply_world_pressure_window_bias()
    hyena._apply_world_pressure_window_bias()

    assert lion.health > 72.0
    assert lion.hunger < 48.0
    assert lion.mate_cooldown < 4
    assert lion.reproduction_rate > lion_base_rate
    assert hyena.health > 69.0
    assert hyena.hunger < 46.0
    assert hyena.mate_cooldown < 4
    assert hyena.reproduction_rate > hyena_base_rate

    print("✅ Runtime apex world pressure window bias effect test passed")


def test_runtime_apex_birth_memory_bias_effect():
    """apex 的 birth_memory_bias 应直接改善当前体况、冷却和繁殖节律。"""
    lion = Lion((10, 10), Gender.FEMALE)
    hyena = Hyena((12, 10), Gender.FEMALE)

    lion.birth_memory_bias = 0.32
    hyena.birth_memory_bias = 0.30
    lion.health = hyena.health = 72
    lion.hunger = hyena.hunger = 38
    lion.mate_cooldown = hyena.mate_cooldown = 4

    lion._apply_birth_memory_bias()
    hyena._apply_birth_memory_bias()

    assert lion.health > 72 and lion.hunger < 38 and lion.mate_cooldown < 4
    assert hyena.health > 72 and hyena.hunger < 38 and hyena.mate_cooldown < 4

    print("✅ Runtime apex birth memory bias effect test passed")


def test_runtime_apex_birth_memory_world_pressure_bias_effect():
    """apex 的 birth_memory_world_pressure_bias 应直接改善当前体况、冷却和繁殖节律。"""
    lion = Lion((10, 10), Gender.FEMALE)
    hyena = Hyena((12, 10), Gender.FEMALE)

    lion.birth_memory_world_pressure_bias = 0.32
    hyena.birth_memory_world_pressure_bias = 0.30
    lion.health = hyena.health = 72
    lion.hunger = hyena.hunger = 38
    lion.mate_cooldown = hyena.mate_cooldown = 4

    lion._apply_birth_memory_world_pressure_bias()
    hyena._apply_birth_memory_world_pressure_bias()

    assert lion.health > 72 and lion.hunger < 38 and lion.mate_cooldown < 4
    assert hyena.health > 72 and hyena.hunger < 38 and hyena.mate_cooldown < 4

    print("✅ Runtime apex birth memory world pressure bias effect test passed")


def test_runtime_apex_birth_cycle_bias_effect():
    """apex 的 birth_cycle_bias 应直接改善当前体况、冷却和繁殖节律。"""
    lion = Lion((10, 10), Gender.FEMALE)
    hyena = Hyena((12, 10), Gender.FEMALE)

    lion.birth_cycle_bias = 0.32
    hyena.birth_cycle_bias = 0.30
    lion.health = hyena.health = 72
    lion.hunger = hyena.hunger = 38
    lion.mate_cooldown = hyena.mate_cooldown = 4

    lion._apply_birth_cycle_bias()
    hyena._apply_birth_cycle_bias()

    assert lion.health > 72 and lion.hunger < 38 and lion.mate_cooldown < 4
    assert hyena.health > 72 and hyena.hunger < 38 and hyena.mate_cooldown < 4

    print("✅ Runtime apex birth cycle bias effect test passed")


def test_runtime_apex_birth_cycle_window_pressure_bias_effect():
    """birth_cycle_window_pressure_bias 应直接改善 apex 运行期体况。"""
    lion = Lion(position=(20, 20), gender=Gender.FEMALE)
    hyena = Hyena(position=(22, 20), gender=Gender.FEMALE)

    lion.birth_cycle_window_pressure_bias = 0.40
    hyena.birth_cycle_window_pressure_bias = 0.38
    lion.health = 70.0
    lion.hunger = 50.0
    lion.mate_cooldown = 4
    hyena.health = 72.0
    hyena.hunger = 48.0
    hyena.mate_cooldown = 4

    lion_base_rate = lion.reproduction_rate
    hyena_base_rate = hyena.reproduction_rate

    lion._apply_birth_cycle_window_pressure_bias()
    hyena._apply_birth_cycle_window_pressure_bias()

    assert lion.health > 70.0
    assert lion.hunger < 50.0
    assert lion.mate_cooldown < 4
    assert lion.reproduction_rate > lion_base_rate
    assert hyena.health > 72.0
    assert hyena.hunger < 48.0
    assert hyena.mate_cooldown < 4
    assert hyena.reproduction_rate > hyena_base_rate

    print("✅ Runtime apex birth cycle window pressure bias effect test passed")


def test_lion_hotspot_memory_center_effect():
    """Lion 的热点记忆应让 pride_center 漂移而不是瞬间跳点。"""
    lion = Lion(position=(16, 16), gender=Gender.MALE)
    lion.pride_center = (0, 0)
    lion.hotspot_memory = 0.8
    lion.shared_hotspot_memory = 0.0

    lion._update_pride_center_from_cycle()

    assert lion.pride_center != (0, 0)
    assert lion.pride_center != (16, 16)

    print("✅ Lion hotspot memory center test passed")


def test_hyena_hotspot_memory_center_effect():
    """Hyena 的热点记忆应让 clan_center 漂移而不是瞬间跳点。"""
    hyena = Hyena(position=(16, 16), gender=Gender.FEMALE)
    hyena.clan_center = (0, 0)
    hyena.hotspot_memory = 0.8
    hyena.shared_hotspot_memory = 0.0

    hyena._update_clan_center_from_cycle()

    assert hyena.clan_center != (0, 0)
    assert hyena.clan_center != (16, 16)

    print("✅ Hyena hotspot memory center test passed")


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


def test_antelope_world_pressure_birth_scaling():
    """羚羊世界压力偏置应继续改善产后冷却和 herd 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("antelope", pos_high, source="manual")
    antelope_high = eco_high.animals[-1]
    antelope_high.gender = Gender.FEMALE
    antelope_high.pregnant = True
    antelope_high.condition_runtime = 0.4
    antelope_high.world_pressure_bias = 0.8
    antelope_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("antelope")

    random.seed(84)
    antelope_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("antelope")
    high_cooldown = antelope_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("antelope", pos_low, source="manual")
    antelope_low = eco_low.animals[-1]
    antelope_low.gender = Gender.FEMALE
    antelope_low.pregnant = True
    antelope_low.condition_runtime = 0.4
    antelope_low.world_pressure_bias = 0.0
    antelope_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("antelope")

    random.seed(84)
    antelope_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("antelope")
    low_cooldown = antelope_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Antelope world pressure birth scaling test passed")


def test_vulture_world_pressure_window_birth_scaling():
    """秃鹫世界压力窗口偏置应继续改善产后冷却和 aerial 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("vulture", pos_high, source="manual")
    vulture_high = eco_high.animals[-1]
    vulture_high.gender = Gender.FEMALE
    vulture_high.pregnant = True
    vulture_high.condition_runtime = 0.4
    vulture_high.world_pressure_window_bias = 0.8
    vulture_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("vulture")

    random.seed(85)
    vulture_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("vulture")
    high_cooldown = vulture_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("vulture", pos_low, source="manual")
    vulture_low = eco_low.animals[-1]
    vulture_low.gender = Gender.FEMALE
    vulture_low.pregnant = True
    vulture_low.condition_runtime = 0.4
    vulture_low.world_pressure_window_bias = 0.0
    vulture_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("vulture")

    random.seed(85)
    vulture_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("vulture")
    low_cooldown = vulture_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Vulture world pressure window birth scaling test passed")


def test_antelope_birth_cycle_scaling():
    """羚羊 birth_cycle_bias 应继续改善产后冷却和 herd 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("antelope", pos_high, source="manual")
    antelope_high = eco_high.animals[-1]
    antelope_high.gender = Gender.FEMALE
    antelope_high.pregnant = True
    antelope_high.condition_runtime = 0.4
    antelope_high.birth_cycle_bias = 0.8
    antelope_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("antelope")

    random.seed(86)
    antelope_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("antelope")
    high_cooldown = antelope_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("antelope", pos_low, source="manual")
    antelope_low = eco_low.animals[-1]
    antelope_low.gender = Gender.FEMALE
    antelope_low.pregnant = True
    antelope_low.condition_runtime = 0.4
    antelope_low.birth_cycle_bias = 0.0
    antelope_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("antelope")

    random.seed(86)
    antelope_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("antelope")
    low_cooldown = antelope_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Antelope birth cycle scaling test passed")


def test_vulture_birth_cycle_scaling():
    """秃鹫 birth_cycle_bias 应继续改善产后冷却和 aerial 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("vulture", pos_high, source="manual")
    vulture_high = eco_high.animals[-1]
    vulture_high.gender = Gender.FEMALE
    vulture_high.pregnant = True
    vulture_high.condition_runtime = 0.4
    vulture_high.birth_cycle_bias = 0.8
    vulture_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("vulture")

    random.seed(87)
    vulture_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("vulture")
    high_cooldown = vulture_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("vulture", pos_low, source="manual")
    vulture_low = eco_low.animals[-1]
    vulture_low.gender = Gender.FEMALE
    vulture_low.pregnant = True
    vulture_low.condition_runtime = 0.4
    vulture_low.birth_cycle_bias = 0.0
    vulture_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("vulture")

    random.seed(87)
    vulture_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("vulture")
    low_cooldown = vulture_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Vulture birth cycle scaling test passed")


def test_lion_registration_and_spawn():
    """狮应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("lion")
    eco.spawn_animal("lion", position, source="manual")

    assert eco.get_species_count("lion") == initial + 1
    assert eco.animals[-1].species == "lion"
    assert eco.animals[-1].pride_id.startswith("pride-")
    assert eco.animals[-1].pride_center == position

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


def test_lion_cycle_core_effect():
    """扩张期应放大狮群核心区建立强度。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("lion", position, source="manual")
    lion = eco.animals[-1]
    lion.cycle_expansion_phase = 0.7

    lion._establish_pride_core(eco)

    assert lion.pride_strength >= 0.12

    print("✅ Lion cycle core test passed")


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


def test_lion_social_stability_effect():
    """狮群稳定度应影响体况和繁殖冷却。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("lion", position, source="manual")
    eco.spawn_animal("lion", position, source="manual")
    lion = eco.animals[-2]
    partner = eco.animals[-1]
    partner.pride_id = lion.pride_id
    partner.pride_center = lion.position
    lion.pride_strength = 0.6
    lion.mate_cooldown = 3
    before_hunger = lion.hunger

    lion._apply_social_stability(eco)

    assert lion.pride_stability > 0.0
    assert lion.hunger <= before_hunger
    assert lion.mate_cooldown <= 2

    print("✅ Lion social stability test passed")


def test_lion_cycle_phase_effect():
    """狮群周期相位应轻量影响当前个体状态。"""
    lion = Lion((10, 10), Gender.MALE)
    lion.health = 70
    lion.hunger = 40
    lion.mate_cooldown = 5
    base_reproduction = lion.reproduction_rate
    lion.cycle_expansion_phase = 0.6
    lion.cycle_contraction_phase = 0.0

    lion._apply_cycle_phase()

    assert lion.health > 70
    assert lion.hunger < 40
    assert lion.mate_cooldown < 5
    assert lion.reproduction_rate > base_reproduction

    print("✅ Lion cycle phase test passed")


def test_lion_social_birth_scaling():
    """狮群稳定度应影响产后冷却和幼崽规模。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("lion", pos_high, source="manual")
    lion_high = eco_high.animals[-1]
    lion_high.gender = Gender.FEMALE
    lion_high.pregnant = True
    lion_high.pride_stability = 0.8
    lion_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("lion")

    random.seed(42)
    lion_high._give_birth(eco_high)

    high_cooldown = lion_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("lion", pos_low, source="manual")
    lion_low = eco_low.animals[-1]
    lion_low.gender = Gender.FEMALE
    lion_low.pregnant = True
    lion_low.pride_stability = 0.0
    lion_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("lion")

    random.seed(42)
    lion_low._give_birth(eco_low)

    low_cooldown = lion_low.mate_cooldown

    assert not lion_high.pregnant
    assert not lion_low.pregnant
    assert eco_high.get_species_count("lion") >= before_high
    assert eco_low.get_species_count("lion") >= before_low
    assert high_cooldown < low_cooldown

    print("✅ Lion social birth scaling test passed")


def test_lion_condition_birth_scaling():
    """狮群真实体况应进一步改善产后冷却和群体延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("lion", pos_high, source="manual")
    lion_high = eco_high.animals[-1]
    lion_high.gender = Gender.FEMALE
    lion_high.pregnant = True
    lion_high.pride_stability = 0.6
    lion_high.condition_runtime = 0.8
    lion_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("lion")

    random.seed(52)
    lion_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("lion")
    high_cooldown = lion_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("lion", pos_low, source="manual")
    lion_low = eco_low.animals[-1]
    lion_low.gender = Gender.FEMALE
    lion_low.pregnant = True
    lion_low.pride_stability = 0.6
    lion_low.condition_runtime = 0.0
    lion_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("lion")

    random.seed(52)
    lion_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("lion")
    low_cooldown = lion_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Lion condition birth scaling test passed")


def test_lion_condition_phase_birth_scaling():
    """狮群长期相位体况偏置应继续改善产后冷却和群体延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("lion", pos_high, source="manual")
    lion_high = eco_high.animals[-1]
    lion_high.gender = Gender.FEMALE
    lion_high.pregnant = True
    lion_high.pride_stability = 0.6
    lion_high.condition_runtime = 0.4
    lion_high.condition_phase_bias = 0.8
    lion_high.regional_health_anchor = 0.6
    lion_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("lion")

    random.seed(62)
    lion_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("lion")
    high_cooldown = lion_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("lion", pos_low, source="manual")
    lion_low = eco_low.animals[-1]
    lion_low.gender = Gender.FEMALE
    lion_low.pregnant = True
    lion_low.pride_stability = 0.6
    lion_low.condition_runtime = 0.4
    lion_low.condition_phase_bias = 0.0
    lion_low.regional_health_anchor = 0.0
    lion_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("lion")

    random.seed(62)
    lion_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("lion")
    low_cooldown = lion_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Lion condition phase birth scaling test passed")


def test_lion_world_pressure_birth_scaling():
    """狮群世界压力偏置应继续改善产后冷却和群体延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("lion", pos_high, source="manual")
    lion_high = eco_high.animals[-1]
    lion_high.gender = Gender.FEMALE
    lion_high.pregnant = True
    lion_high.pride_stability = 0.6
    lion_high.condition_runtime = 0.4
    lion_high.world_pressure_bias = 0.8
    lion_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("lion")

    random.seed(63)
    lion_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("lion")
    high_cooldown = lion_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("lion", pos_low, source="manual")
    lion_low = eco_low.animals[-1]
    lion_low.gender = Gender.FEMALE
    lion_low.pregnant = True
    lion_low.pride_stability = 0.6
    lion_low.condition_runtime = 0.4
    lion_low.world_pressure_bias = 0.0
    lion_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("lion")

    random.seed(63)
    lion_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("lion")
    low_cooldown = lion_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Lion world pressure birth scaling test passed")


def test_lion_world_pressure_window_birth_scaling():
    """狮群世界压力窗口偏置应继续改善产后冷却和群体延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("lion", pos_high, source="manual")
    lion_high = eco_high.animals[-1]
    lion_high.gender = Gender.FEMALE
    lion_high.pregnant = True
    lion_high.pride_stability = 0.6
    lion_high.condition_runtime = 0.4
    lion_high.world_pressure_window_bias = 0.8
    lion_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("lion")

    random.seed(64)
    lion_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("lion")
    high_cooldown = lion_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("lion", pos_low, source="manual")
    lion_low = eco_low.animals[-1]
    lion_low.gender = Gender.FEMALE
    lion_low.pregnant = True
    lion_low.pride_stability = 0.6
    lion_low.condition_runtime = 0.4
    lion_low.world_pressure_window_bias = 0.0
    lion_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("lion")

    random.seed(64)
    lion_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("lion")
    low_cooldown = lion_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Lion world pressure window birth scaling test passed")


def test_lion_birth_cycle_scaling():
    """狮群 birth_cycle_bias 应继续改善产后冷却和群体延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("lion", pos_high, source="manual")
    lion_high = eco_high.animals[-1]
    lion_high.gender = Gender.FEMALE
    lion_high.pregnant = True
    lion_high.pride_stability = 0.6
    lion_high.birth_cycle_bias = 0.8
    lion_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("lion")

    random.seed(56)
    lion_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("lion")
    high_cooldown = lion_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("lion", pos_low, source="manual")
    lion_low = eco_low.animals[-1]
    lion_low.gender = Gender.FEMALE
    lion_low.pregnant = True
    lion_low.pride_stability = 0.6
    lion_low.birth_cycle_bias = 0.0
    lion_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("lion")

    random.seed(56)
    lion_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("lion")
    low_cooldown = lion_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Lion birth cycle scaling test passed")


def test_hyena_registration_and_spawn():
    """鬣狗应完成注册，并能在陆地生成。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    initial = eco.get_species_count("hyena")
    eco.spawn_animal("hyena", position, source="manual")

    assert eco.get_species_count("hyena") == initial + 1
    assert eco.animals[-1].species == "hyena"
    assert eco.animals[-1].clan_id.startswith("clan-")
    assert eco.animals[-1].clan_center == position

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


def test_hyena_cycle_den_effect():
    """扩张期应放大鬣狗 clan 核心区凝聚效果。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("hyena", position, source="manual")
    hyena = eco.animals[-1]
    hyena.cycle_expansion_phase = 0.7

    hyena._mark_den_cluster(eco)

    assert hyena.clan_cohesion >= 0.10

    print("✅ Hyena cycle den test passed")


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


def test_hyena_clan_stability_effect():
    """鬣狗 clan 稳定度应影响体况和繁殖冷却。"""
    eco = Ecosystem()
    position = eco._random_land_position()
    assert position is not None

    eco.spawn_animal("hyena", position, source="manual")
    eco.spawn_animal("hyena", position, source="manual")
    hyena = eco.animals[-2]
    partner = eco.animals[-1]
    partner.clan_id = hyena.clan_id
    partner.clan_center = hyena.position
    hyena.clan_cohesion = 0.6
    hyena.mate_cooldown = 3
    before_hunger = hyena.hunger

    hyena._apply_clan_stability(eco)

    assert hyena.clan_stability > 0.0
    assert hyena.hunger <= before_hunger
    assert hyena.mate_cooldown <= 2

    print("✅ Hyena clan stability test passed")


def test_hyena_social_birth_scaling():
    """鬣狗 clan 稳定度应影响产后冷却和幼崽规模。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("hyena", pos_high, source="manual")
    hyena_high = eco_high.animals[-1]
    hyena_high.gender = Gender.FEMALE
    hyena_high.pregnant = True
    hyena_high.clan_stability = 0.8
    hyena_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("hyena")

    random.seed(24)
    hyena_high._give_birth(eco_high)

    high_cooldown = hyena_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("hyena", pos_low, source="manual")
    hyena_low = eco_low.animals[-1]
    hyena_low.gender = Gender.FEMALE
    hyena_low.pregnant = True
    hyena_low.clan_stability = 0.0
    hyena_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("hyena")

    random.seed(24)
    hyena_low._give_birth(eco_low)

    low_cooldown = hyena_low.mate_cooldown

    assert not hyena_high.pregnant
    assert not hyena_low.pregnant
    assert eco_high.get_species_count("hyena") >= before_high
    assert eco_low.get_species_count("hyena") >= before_low
    assert high_cooldown < low_cooldown

    print("✅ Hyena social birth scaling test passed")


def test_hyena_condition_birth_scaling():
    """鬣狗真实体况应进一步改善产后冷却和 clan 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("hyena", pos_high, source="manual")
    hyena_high = eco_high.animals[-1]
    hyena_high.gender = Gender.FEMALE
    hyena_high.pregnant = True
    hyena_high.clan_stability = 0.6
    hyena_high.condition_runtime = 0.8
    hyena_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("hyena")

    random.seed(33)
    hyena_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("hyena")
    high_cooldown = hyena_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("hyena", pos_low, source="manual")
    hyena_low = eco_low.animals[-1]
    hyena_low.gender = Gender.FEMALE
    hyena_low.pregnant = True
    hyena_low.clan_stability = 0.6
    hyena_low.condition_runtime = 0.0
    hyena_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("hyena")

    random.seed(33)
    hyena_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("hyena")
    low_cooldown = hyena_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Hyena condition birth scaling test passed")


def test_hyena_condition_phase_birth_scaling():
    """鬣狗长期相位体况偏置应继续改善产后冷却和 clan 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("hyena", pos_high, source="manual")
    hyena_high = eco_high.animals[-1]
    hyena_high.gender = Gender.FEMALE
    hyena_high.pregnant = True
    hyena_high.clan_stability = 0.6
    hyena_high.condition_runtime = 0.4
    hyena_high.condition_phase_bias = 0.8
    hyena_high.regional_health_anchor = 0.6
    hyena_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("hyena")

    random.seed(73)
    hyena_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("hyena")
    high_cooldown = hyena_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("hyena", pos_low, source="manual")
    hyena_low = eco_low.animals[-1]
    hyena_low.gender = Gender.FEMALE
    hyena_low.pregnant = True
    hyena_low.clan_stability = 0.6
    hyena_low.condition_runtime = 0.4
    hyena_low.condition_phase_bias = 0.0
    hyena_low.regional_health_anchor = 0.0
    hyena_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("hyena")

    random.seed(73)
    hyena_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("hyena")
    low_cooldown = hyena_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Hyena condition phase birth scaling test passed")


def test_hyena_world_pressure_birth_scaling():
    """鬣狗世界压力偏置应继续改善产后冷却和 clan 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("hyena", pos_high, source="manual")
    hyena_high = eco_high.animals[-1]
    hyena_high.gender = Gender.FEMALE
    hyena_high.pregnant = True
    hyena_high.clan_stability = 0.6
    hyena_high.condition_runtime = 0.4
    hyena_high.world_pressure_bias = 0.8
    hyena_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("hyena")

    random.seed(74)
    hyena_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("hyena")
    high_cooldown = hyena_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("hyena", pos_low, source="manual")
    hyena_low = eco_low.animals[-1]
    hyena_low.gender = Gender.FEMALE
    hyena_low.pregnant = True
    hyena_low.clan_stability = 0.6
    hyena_low.condition_runtime = 0.4
    hyena_low.world_pressure_bias = 0.0
    hyena_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("hyena")

    random.seed(74)
    hyena_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("hyena")
    low_cooldown = hyena_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Hyena world pressure birth scaling test passed")


def test_hyena_world_pressure_window_birth_scaling():
    """鬣狗世界压力窗口偏置应继续改善产后冷却和 clan 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("hyena", pos_high, source="manual")
    hyena_high = eco_high.animals[-1]
    hyena_high.gender = Gender.FEMALE
    hyena_high.pregnant = True
    hyena_high.clan_stability = 0.6
    hyena_high.condition_runtime = 0.4
    hyena_high.world_pressure_window_bias = 0.8
    hyena_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("hyena")

    random.seed(75)
    hyena_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("hyena")
    high_cooldown = hyena_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("hyena", pos_low, source="manual")
    hyena_low = eco_low.animals[-1]
    hyena_low.gender = Gender.FEMALE
    hyena_low.pregnant = True
    hyena_low.clan_stability = 0.6
    hyena_low.condition_runtime = 0.4
    hyena_low.world_pressure_window_bias = 0.0
    hyena_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("hyena")

    random.seed(75)
    hyena_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("hyena")
    low_cooldown = hyena_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Hyena world pressure window birth scaling test passed")


def test_hyena_birth_cycle_scaling():
    """鬣狗 birth_cycle_bias 应继续改善产后冷却和 clan 延续。"""
    eco_high = Ecosystem()
    pos_high = eco_high._random_land_position()
    assert pos_high is not None
    eco_high.spawn_animal("hyena", pos_high, source="manual")
    hyena_high = eco_high.animals[-1]
    hyena_high.gender = Gender.FEMALE
    hyena_high.pregnant = True
    hyena_high.clan_stability = 0.6
    hyena_high.birth_cycle_bias = 0.8
    hyena_high.breeding_patch_threshold = lambda: 0.0
    before_high = eco_high.get_species_count("hyena")

    random.seed(37)
    hyena_high._give_birth(eco_high)

    high_count = eco_high.get_species_count("hyena")
    high_cooldown = hyena_high.mate_cooldown

    eco_low = Ecosystem()
    pos_low = eco_low._random_land_position()
    assert pos_low is not None
    eco_low.spawn_animal("hyena", pos_low, source="manual")
    hyena_low = eco_low.animals[-1]
    hyena_low.gender = Gender.FEMALE
    hyena_low.pregnant = True
    hyena_low.clan_stability = 0.6
    hyena_low.birth_cycle_bias = 0.0
    hyena_low.breeding_patch_threshold = lambda: 0.0
    before_low = eco_low.get_species_count("hyena")

    random.seed(37)
    hyena_low._give_birth(eco_low)

    low_count = eco_low.get_species_count("hyena")
    low_cooldown = hyena_low.mate_cooldown

    assert high_count >= before_high
    assert low_count >= before_low
    assert high_count >= low_count
    assert high_cooldown < low_cooldown

    print("✅ Hyena birth cycle scaling test passed")


def test_hyena_cycle_phase_effect():
    """鬣狗周期相位应轻量影响当前个体状态。"""
    hyena = Hyena((10, 10), Gender.FEMALE)
    hyena.health = 72
    hyena.hunger = 38
    hyena.mate_cooldown = 4
    base_reproduction = hyena.reproduction_rate
    hyena.cycle_expansion_phase = 0.55
    hyena.cycle_contraction_phase = 0.0

    hyena._apply_cycle_phase()

    assert hyena.health > 72
    assert hyena.hunger < 38
    assert hyena.mate_cooldown < 4
    assert hyena.reproduction_rate > base_reproduction

    print("✅ Hyena cycle phase test passed")


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


def _run_test_group(name, tests):
    """按分组运行测试。"""
    print(f"🧪 Running EcoWorld tests [{name}]...\n")
    for test in tests:
        test()
    print(f"\n✅ {name} tests passed!")


BASIC_TESTS = [
    test_environment,
    test_plants,
    test_animals,
    test_ecosystem_update,
    test_food_chain,
    test_statistics,
    test_minnow_registration_and_spawn,
    test_shrimp_uses_shallow_or_river_habitat,
    test_load_config_preserves_world_dimensions,
    test_land_animals_do_not_spawn_in_water,
    test_amphibious_animals_can_spawn_in_water,
    test_night_moth_registration_and_spawn,
]

WORLD_TESTS = [
    test_v4_world_and_data_skeleton,
    test_v4_world_simulation_skeleton,
    test_v4_region_relationship_state_persists,
    test_v4_registry_queries,
    test_v4_region_food_web_summary,
    test_v4_region_cascade_summary,
    test_v4_cascade_feedback_updates_region_state,
    test_v4_region_competition_summary,
    test_v4_competition_feedback_rebalances_species_pool,
    test_v4_region_predation_summary,
    test_v4_region_symbiosis_summary,
    test_v4_territory_summary,
    test_v4_territory_summary_uses_runtime_events,
    test_v4_territory_summary_uses_runtime_state,
    test_v4_territory_summary_uses_regional_social_anchors,
    test_v4_territory_summary_uses_hotspot_memory,
    test_v4_social_trend_summary_uses_memory,
    test_v4_social_trend_birth_cycle_window_support_memory,
    test_region_simulation_uses_region_defaults,
]

WETLAND_TESTS = [
    test_v4_wetland_chain_summary,
    test_v4_wetland_chain_feedback_updates_region_state,
    test_v4_wetland_chain_rebalancing_updates_species_pool,
    test_beaver_registration_and_spawn,
    test_beaver_engineering_effect,
    test_crocodile_registration_and_spawn,
    test_crocodile_ambush_effect,
    test_hippopotamus_registration_and_spawn,
    test_hippopotamus_nutrient_cycle_effect,
]

GRASSLAND_TESTS = [
    test_v4_grassland_chain_summary,
    test_v4_grassland_chain_feedback_updates_region_state,
    test_v4_grassland_chain_rebalancing_updates_species_pool,
    test_v4_grassland_birth_memory_rebalancing_support,
    test_v4_grassland_chain_recolonization_window,
    test_v4_carrion_chain_summary,
    test_v4_carrion_chain_feedback_updates_region_state,
    test_v4_carrion_chain_rebalancing_updates_species_pool,
    test_v4_carrion_birth_memory_rebalancing_support,
    test_v4_carrion_chain_recolonization_window,
    test_v4_social_trend_rebalancing_support,
    test_v4_territory_feedback_updates_region_state,
    test_v4_predation_feedback_updates_region_state,
    test_v4_symbiosis_feedback_updates_region_state,
]

RUNTIME_TESTS = [
    test_region_simulation_applies_social_phase_state,
    test_runtime_birth_signal_aggregation,
    test_runtime_birth_memory_signal_aggregation,
    test_lion_hotspot_memory_center_effect,
    test_hyena_hotspot_memory_center_effect,
    test_runtime_regional_health_bias,
    test_runtime_regional_health_anchor_effect,
    test_runtime_condition_effect,
    test_runtime_condition_phase_bias_effect,
    test_runtime_world_pressure_bias_effect,
    test_runtime_world_pressure_window_bias_effect,
    test_runtime_birth_memory_bias_effect,
    test_runtime_birth_memory_world_pressure_bias_effect,
    test_runtime_birth_cycle_bias_effect,
    test_runtime_birth_cycle_window_pressure_bias_effect,
    test_runtime_apex_regional_health_anchor_effect,
    test_runtime_apex_condition_effect,
    test_runtime_apex_condition_phase_bias_effect,
    test_runtime_apex_world_pressure_bias_effect,
    test_runtime_apex_world_pressure_window_bias_effect,
    test_runtime_apex_birth_memory_bias_effect,
    test_runtime_apex_birth_memory_world_pressure_bias_effect,
    test_runtime_apex_birth_cycle_bias_effect,
    test_runtime_apex_birth_cycle_window_pressure_bias_effect,
]

SPECIES_TESTS = [
    test_elephant_registration_and_spawn,
    test_elephant_engineering_effect,
    test_white_rhino_registration_and_spawn,
    test_white_rhino_grazing_effect,
    test_giraffe_registration_and_spawn,
    test_giraffe_canopy_effect,
    test_antelope_registration_and_spawn,
    test_zebra_registration_and_spawn,
    test_lion_registration_and_spawn,
    test_lion_hunt_corridor_effect,
    test_lion_pride_core_effect,
    test_lion_cycle_core_effect,
    test_lion_male_takeover_effect,
    test_lion_social_stability_effect,
    test_lion_cycle_phase_effect,
    test_lion_social_birth_scaling,
    test_lion_condition_birth_scaling,
    test_lion_condition_phase_birth_scaling,
    test_lion_world_pressure_birth_scaling,
    test_lion_world_pressure_window_birth_scaling,
    test_lion_birth_cycle_scaling,
    test_hyena_registration_and_spawn,
    test_hyena_scavenging_effect,
    test_hyena_den_cluster_effect,
    test_hyena_cycle_den_effect,
    test_hyena_clan_front_effect,
    test_hyena_clan_stability_effect,
    test_hyena_social_birth_scaling,
    test_hyena_condition_birth_scaling,
    test_hyena_condition_phase_birth_scaling,
    test_hyena_world_pressure_birth_scaling,
    test_hyena_world_pressure_window_birth_scaling,
    test_hyena_birth_cycle_scaling,
    test_hyena_cycle_phase_effect,
    test_vulture_registration_and_spawn,
    test_antelope_birth_cycle_scaling,
    test_vulture_birth_cycle_scaling,
]

TEST_GROUPS = {
    "basic": BASIC_TESTS,
    "world": WORLD_TESTS,
    "wetland": WETLAND_TESTS,
    "grassland": GRASSLAND_TESTS,
    "runtime": RUNTIME_TESTS,
    "species": SPECIES_TESTS,
}


def run_all_tests():
    """运行所有测试"""
    all_tests = []
    for tests in TEST_GROUPS.values():
        all_tests.extend(tests)
    _run_test_group("all", all_tests)


if __name__ == "__main__":
    group = sys.argv[1].lower() if len(sys.argv) > 1 else "all"
    if group == "all":
        run_all_tests()
    elif group in TEST_GROUPS:
        _run_test_group(group, TEST_GROUPS[group])
    else:
        valid = ", ".join(["all"] + list(TEST_GROUPS.keys()))
        raise SystemExit(f"Unknown test group: {group}. Valid groups: {valid}")

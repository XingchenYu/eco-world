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
    build_default_species_templates,
    build_default_species_variants,
)
from src.data.registry import build_default_world_registry
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
    eco.spawn_animal("rabbit", position)
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

    assert len(world_map.regions) == 6
    assert "temperate_forest" in world_map.regions
    assert "megaherbivore_engineer" in templates
    assert "african_elephant" in variants
    assert any(link.relation_type == "engineering" for link in relations)

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
    assert stats["registry"]["templates"] >= 8
    assert "beaver" in stats["registry"]["regional_species"]
    assert stats["registry"]["relation_summary"]["engineering"] >= 1

    world_sim.set_active_region("wetland_lake")
    assert world_sim.active_region_id == "wetland_lake"
    assert world_sim.get_active_region().name == "湿地与湖泊区"

    print("✅ V4 world simulation test passed")


def test_v4_registry_queries():
    """v4 注册表应支持按区域和物种关系查询。"""
    registry = build_default_world_registry()

    wetland_species = registry.species_for_region("wetland_lake")
    crocodile_relations = registry.relations_for_species("nile_crocodile")

    assert "hippopotamus" in wetland_species
    assert "nile_crocodile" in wetland_species
    assert any(relation.relation_type == "competition" for relation in crocodile_relations)

    print("✅ V4 registry test passed")


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
    test_v4_registry_queries()
    
    print("\n✅ All tests passed!")


if __name__ == "__main__":
    run_all_tests()

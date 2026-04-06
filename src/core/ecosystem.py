"""
生态系统核心引擎 - 完整版（陆地+水生）
"""

import random
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from collections import Counter, defaultdict
import yaml

from .creature import Creature, BehaviorState
from .balance import EcoBalance, Alert
from .environment import Environment, TerrainType, Weather
from ..entities.plants import (
    Plant, Grass, Bush, Flower, Moss,
    # 新增植物
    Tree, Vine, Cactus, Berry, Mushroom, Fern,
    # 果类植物
    AppleTree, CherryTree, GrapeVine, Strawberry, 
    Blueberry, OrangeTree, Watermelon
)
from ..entities.omnivores import (
    Bear, WildBoar, Badger, RaccoonDog, Skunk, 
    Opossum, Coati, Armadillo
)
from ..entities.animals import (
    Animal, Insect, Rabbit, Fox, Deer, Mouse, Bird, Snake, Bee, Gender,
    Eagle, Owl, Duck, Swan, Sparrow, Parrot, Kingfisher, Wolf, Spider,
    # 新增鸟类
    Magpie, Crow, Woodpecker, Hummingbird,
    # 新增哺乳动物
    Squirrel, Hedgehog, Bat, Raccoon
)
from ..entities.aquatic import (
    AquaticCreature, Algae, Seaweed, Plankton, 
    SmallFish, Minnow, Carp, Catfish, LargeFish, Pufferfish,
    Shrimp, Crab, Frog, Tadpole, WaterStrider, Blackfish, Pike
)


@dataclass
class Event:
    """事件记录"""
    tick: int
    type: str
    description: str


class Ecosystem:
    """完整生态系统 - 陆地 + 水生"""

    PLANT_SPECIES = [
        "grass", "bush", "flower", "moss",
        "tree", "vine", "cactus", "berry", "mushroom", "fern",
        "apple_tree", "cherry_tree", "grape_vine", "strawberry",
        "blueberry", "orange_tree", "watermelon",
    ]
    LAND_ANIMAL_SPECIES = [
        "insect", "rabbit", "fox", "deer", "mouse", "bird", "snake", "bee", "frog",
        "eagle", "owl", "duck", "swan", "sparrow", "parrot", "kingfisher",
        "wolf", "spider",
        "magpie", "crow", "woodpecker", "hummingbird",
        "squirrel", "hedgehog", "bat", "raccoon",
        "bear", "wild_boar", "badger", "raccoon_dog",
        "skunk", "opossum", "coati", "armadillo",
    ]
    AQUATIC_SPECIES = [
        "algae", "seaweed", "plankton", "small_fish", "minnow", "carp", "catfish",
        "large_fish", "pufferfish", "shrimp", "crab", "tadpole", "water_strider",
        "blackfish", "pike",
    ]
    AQUATIC_PRODUCERS = {"algae", "seaweed", "plankton"}
    AQUATIC_CONSUMERS = {"small_fish", "minnow", "carp", "shrimp", "tadpole", "water_strider", "pufferfish"}
    AQUATIC_PREDATORS = {"catfish", "large_fish", "blackfish", "pike", "crab"}
    LAND_PREY = {
        "insect", "rabbit", "mouse", "deer", "bird", "sparrow", "duck", "frog",
        "bee", "squirrel", "hedgehog", "bat", "raccoon", "raccoon_dog",
        "opossum", "armadillo", "magpie", "crow", "woodpecker", "parrot",
        "hummingbird",
    }
    LAND_PREDATORS = {"fox", "wolf", "snake", "spider", "eagle", "owl", "bear", "wild_boar", "badger", "skunk", "coati"}
    
    def __init__(self, config_path: str = None, config: dict = None):
        self.config = self._load_config(config_path, config)
        self.width = self.config.get("world", {}).get("width", 800) // 20
        self.height = self.config.get("world", {}).get("height", 600) // 20
        
        # 完整环境系统
        self.environment = Environment(self.width, self.height)
        
        # 陆地生物
        self.plants: List[Plant] = []
        self.animals: List[Animal] = []
        
        # 水生生物
        self.aquatic_creatures: List[AquaticCreature] = []
        
        self.events: List[Event] = []
        self.tick_count = 0
        
        # 蝴蝶效应监测器
        self.balance = EcoBalance(self.width, self.height)
        self.active_alerts: List[Alert] = []
        self.previous_counts: Dict[str, int] = {}
        
        # 轻量空间索引，降低邻域查询开销。
        self._spatial_cell_size = max(3, self.config.get("world", {}).get("grid_size", 20) // 5)
        self._plant_index: Dict[Tuple[int, int], List[Plant]] = defaultdict(list)
        self._animal_index: Dict[Tuple[int, int], List[Animal]] = defaultdict(list)
        self._aquatic_index: Dict[Tuple[int, int], List[AquaticCreature]] = defaultdict(list)
        self._entity_cells: Dict[str, Tuple[str, Tuple[int, int]]] = {}
        self._stats_cache: Optional[Dict] = None
        self._stats_cache_tick: int = -1
        self._migration_cooldowns: Dict[str, int] = {}
        
        self._init_population()
        self._rebuild_spatial_indices()
        
    def _load_config(self, path: str = None, config: dict = None) -> dict:
        if config is not None:
            return config
        if path:
            with open(path, 'r') as f:
                return yaml.safe_load(f)
        return {}
        
    def _init_population(self):
        """初始化所有生物"""
        initial = self.config.get("initial_population", {})
        
        # === 陆地植物 ===
        for _ in range(initial.get("grass", 50)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Grass(pos))
            
        for _ in range(initial.get("bush", 15)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Bush(pos))
            
        for _ in range(initial.get("flower", 20)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Flower(pos))
            
        for _ in range(initial.get("moss", 10)):
            pos = self._random_water_adjacent_position()
            if pos:
                self.plants.append(Moss(pos))
            
        # === 新增植物 ===
        for _ in range(initial.get("tree", 8)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Tree(pos))
            
        for _ in range(initial.get("vine", 12)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Vine(pos))
            
        for _ in range(initial.get("cactus", 6)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Cactus(pos))
            
        for _ in range(initial.get("berry", 10)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Berry(pos))
            
        for _ in range(initial.get("mushroom", 15)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Mushroom(pos))
            
        for _ in range(initial.get("fern", 12)):
            pos = self._random_water_adjacent_position() or self._random_land_position()
            if pos:
                self.plants.append(Fern(pos))
            
        # === 果类植物 ===
        for _ in range(initial.get("apple_tree", 10)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(AppleTree(pos))
            
        for _ in range(initial.get("cherry_tree", 8)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(CherryTree(pos))
            
        for _ in range(initial.get("grape_vine", 15)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(GrapeVine(pos))
            
        for _ in range(initial.get("strawberry", 20)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Strawberry(pos))
            
        for _ in range(initial.get("blueberry", 15)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Blueberry(pos))
            
        for _ in range(initial.get("orange_tree", 8)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(OrangeTree(pos))
            
        for _ in range(initial.get("watermelon", 10)):
            pos = self._random_land_position()
            if pos:
                self.plants.append(Watermelon(pos))
        
        # === 陆地动物 ===
        for _ in range(initial.get("insects", 20)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Insect(pos))
            
        for _ in range(initial.get("rabbits", 15)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Rabbit(pos))
            
        for _ in range(initial.get("foxes", 5)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Fox(pos))
            
        for _ in range(initial.get("deer", 3)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Deer(pos))
            
        for _ in range(initial.get("mouse", 10)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Mouse(pos))
            
        for _ in range(initial.get("bird", 5)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Bird(pos))
            
        for _ in range(initial.get("snake", 3)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Snake(pos))
            
        for _ in range(initial.get("bee", 8)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Bee(pos))
            
        # === 新增鸟类 ===
        for _ in range(initial.get("eagle", 2)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Eagle(pos))
            
        for _ in range(initial.get("owl", 3)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Owl(pos))
            
        for _ in range(initial.get("duck", 5)):
            pos = self._random_water_adjacent_position() or self._random_land_position()
            if pos:
                self.animals.append(Duck(pos))
            
        for _ in range(initial.get("swan", 3)):
            pos = self._random_water_position()
            if pos:
                self.animals.append(Swan(pos))
            
        for _ in range(initial.get("sparrow", 10)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Sparrow(pos))
            
        for _ in range(initial.get("parrot", 4)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Parrot(pos))
            
        for _ in range(initial.get("kingfisher", 3)):
            pos = self._random_water_adjacent_position()
            if pos:
                self.animals.append(Kingfisher(pos))
            
        # === 新增天敌（控制泛滥物种）===
        for _ in range(initial.get("wolf", 3)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Wolf(pos))
            
        for _ in range(initial.get("spider", 10)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Spider(pos))
            
        # === 新增鸟类 ===
        for _ in range(initial.get("magpie", 8)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Magpie(pos))
            
        for _ in range(initial.get("crow", 5)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Crow(pos))
            
        for _ in range(initial.get("woodpecker", 6)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Woodpecker(pos))
            
        for _ in range(initial.get("hummingbird", 10)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Hummingbird(pos))
            
        # === 新增哺乳动物 ===
        for _ in range(initial.get("squirrel", 12)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Squirrel(pos))
            
        for _ in range(initial.get("hedgehog", 8)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Hedgehog(pos))
            
        for _ in range(initial.get("bat", 8)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Bat(pos))
            
        for _ in range(initial.get("raccoon", 6)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Raccoon(pos))
            
        # === 新增杂食动物 ===
        for _ in range(initial.get("bear", 4)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Bear(pos))
            
        for _ in range(initial.get("wild_boar", 10)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(WildBoar(pos))
            
        for _ in range(initial.get("badger", 8)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Badger(pos))
            
        for _ in range(initial.get("raccoon_dog", 6)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(RaccoonDog(pos))
            
        for _ in range(initial.get("skunk", 8)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Skunk(pos))
            
        for _ in range(initial.get("opossum", 10)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Opossum(pos))
            
        for _ in range(initial.get("coati", 6)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Coati(pos))
            
        for _ in range(initial.get("armadillo", 6)):
            pos = self._random_land_position()
            if pos:
                self.animals.append(Armadillo(pos))
            
        # === 水生生物 ===
        for _ in range(initial.get("algae", 30)):
            pos = self._random_water_position()
            if pos:
                self.aquatic_creatures.append(Algae(pos))
            
        for _ in range(initial.get("seaweed", 15)):
            pos = self._random_water_position()
            if pos:
                self.aquatic_creatures.append(Seaweed(pos))
            
        for _ in range(initial.get("plankton", 40)):
            pos = self._random_water_position()
            if pos:
                self.aquatic_creatures.append(Plankton(pos))
            
        # === 新增鱼类 ===
        for _ in range(initial.get("small_fish", 15)):
            pos = self._random_water_position_for_body_type({"lake_shallow", "lake_deep"})
            if pos:
                self.aquatic_creatures.append(SmallFish(pos))

        for _ in range(initial.get("minnow", 12)):
            pos = self._random_water_position_for_body_type({"river_channel", "lake_shallow"})
            if pos:
                self.aquatic_creatures.append(Minnow(pos))
            
        for _ in range(initial.get("carp", 8)):
            pos = self._random_water_position_for_body_type({"lake_shallow", "lake_deep"})
            if pos:
                self.aquatic_creatures.append(Carp(pos))
            
        for _ in range(initial.get("catfish", 5)):
            pos = self._random_water_position_for_body_type({"river_channel", "lake_shallow", "lake_deep"})
            if pos:
                self.aquatic_creatures.append(Catfish(pos))
            
        for _ in range(initial.get("large_fish", 3)):
            pos = self._random_water_position_for_body_type({"lake_shallow", "lake_deep"})
            if pos:
                self.aquatic_creatures.append(LargeFish(pos))
            
        for _ in range(initial.get("pufferfish", 4)):
            pos = self._random_water_position()
            if pos:
                self.aquatic_creatures.append(Pufferfish(pos))
            
        # === 新增天敌鱼（控制鲤鱼泛滥）===
        for _ in range(initial.get("blackfish", 4)):
            pos = self._random_water_position_for_body_type({"lake_shallow", "lake_deep"})
            if pos:
                self.aquatic_creatures.append(Blackfish(pos))
            
        for _ in range(initial.get("pike", 3)):
            pos = self._random_water_position_for_body_type({"river_channel", "lake_shallow"})
            if pos:
                self.aquatic_creatures.append(Pike(pos))
            
        # === 甲壳类 ===
        for _ in range(initial.get("shrimp", 20)):
            pos = self._random_water_position_for_body_type({"river_channel", "lake_shallow"})
            if pos:
                self.aquatic_creatures.append(Shrimp(pos))
            
        for _ in range(initial.get("crab", 6)):
            pos = self._random_water_position_for_body_type({"lake_shallow", "river_channel"})
            if pos:
                self.aquatic_creatures.append(Crab(pos))
            
        # === 两栖动物 ===
        for _ in range(initial.get("frog", 5)):
            pos = self._random_water_position()
            if pos:
                self.animals.append(Frog(pos))
            
    def _random_land_position(self) -> Optional[Tuple[int, int]]:
        """随机陆地位置"""
        for _ in range(100):
            x = random.randint(0, self.width - 1)
            y = random.randint(0, self.height - 1)
            if self.environment.is_land(x, y):
                return (x, y)
        return None
            
    def _random_water_position(self) -> Optional[Tuple[int, int]]:
        """随机水域位置"""
        for _ in range(100):
            x = random.randint(0, self.width - 1)
            y = random.randint(0, self.height - 1)
            if self.environment.is_water(x, y):
                return (x, y)
        return None

    def _random_water_position_for_body_type(self, body_types) -> Optional[Tuple[int, int]]:
        """按水体类型随机位置，避免湖泊/河道物种初始分布完全混在一起。"""
        if isinstance(body_types, str):
            body_types = {body_types}
        for _ in range(140):
            pos = self._random_water_position()
            if not pos:
                return None
            if self.environment.get_water_body_type(pos[0], pos[1]) in body_types:
                return pos
        return self._random_water_position()
            
    def _random_water_adjacent_position(self) -> Optional[Tuple[int, int]]:
        """随机水源附近位置"""
        for _ in range(100):
            x = random.randint(0, self.width - 1)
            y = random.randint(0, self.height - 1)
            
            for dx in range(-2, 3):
                for dy in range(-2, 3):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.width and 0 <= ny < self.height:
                        if self.environment.is_water(nx, ny):
                            if self.environment.is_land(x, y):
                                return (x, y)
        return None

    def _random_edge_land_position(self) -> Optional[Tuple[int, int]]:
        """随机边缘陆地位置，模拟从生态廊道迁入。"""
        for _ in range(120):
            if random.random() < 0.5:
                x = random.choice([0, self.width - 1])
                y = random.randint(0, self.height - 1)
            else:
                x = random.randint(0, self.width - 1)
                y = random.choice([0, self.height - 1])
            if self.environment.is_land(x, y):
                return (x, y)
        return self._random_land_position()

    def _random_inflow_water_position(self) -> Optional[Tuple[int, int]]:
        """随机边缘或河道水域位置，模拟上游/邻近水体迁入。"""
        for _ in range(160):
            mode = random.random()
            if mode < 0.55:
                if random.random() < 0.5:
                    x = random.choice([0, self.width - 1])
                    y = random.randint(0, self.height - 1)
                else:
                    x = random.randint(0, self.width - 1)
                    y = random.choice([0, self.height - 1])
            else:
                pos = self._random_water_position()
                if not pos:
                    continue
                x, y = pos
                if self.environment.get_terrain(x, y) != "river" and mode < 0.8:
                    continue
            if self.environment.is_water(x, y):
                return (x, y)
        return self._random_water_position()

    def _random_inflow_water_position_for_body_type(self, body_types) -> Optional[Tuple[int, int]]:
        """按指定水体类型选择迁入位置，给河流/湖泊保留独立来源。"""
        if isinstance(body_types, str):
            body_types = {body_types}
        for _ in range(180):
            pos = self._random_inflow_water_position()
            if not pos:
                return None
            if self.environment.get_water_body_type(pos[0], pos[1]) in body_types:
                return pos
        return self._random_water_position_for_body_type(body_types)
    
    def _cell_for(self, position: Tuple[int, int]) -> Tuple[int, int]:
        return (position[0] // self._spatial_cell_size, position[1] // self._spatial_cell_size)
    
    def _rebuild_spatial_indices(self):
        self._plant_index = defaultdict(list)
        self._animal_index = defaultdict(list)
        self._aquatic_index = defaultdict(list)
        self._entity_cells = {}
        
        for plant in self.plants:
            if plant.alive:
                cell = self._cell_for(plant.position)
                self._plant_index[cell].append(plant)
                self._entity_cells[plant.id] = ("plant", cell)
        
        for animal in self.animals:
            if animal.alive:
                cell = self._cell_for(animal.position)
                self._animal_index[cell].append(animal)
                self._entity_cells[animal.id] = ("animal", cell)
        
        for aquatic in self.aquatic_creatures:
            if aquatic.alive:
                cell = self._cell_for(aquatic.position)
                self._aquatic_index[cell].append(aquatic)
                self._entity_cells[aquatic.id] = ("aquatic", cell)
    
    def refresh_spatial_entity(self, entity: Creature):
        record = self._entity_cells.get(entity.id)
        if not record:
            return
        kind, old_cell = record
        new_cell = self._cell_for(entity.position)
        if new_cell == old_cell:
            return
        
        index = {
            "plant": self._plant_index,
            "animal": self._animal_index,
            "aquatic": self._aquatic_index,
        }[kind]
        bucket = index.get(old_cell, [])
        if entity in bucket:
            bucket.remove(entity)
        index[new_cell].append(entity)
        self._entity_cells[entity.id] = (kind, new_cell)
    
    def _query_spatial_index(self, index: Dict[Tuple[int, int], List[Creature]], position: Tuple[int, int], range_: int) -> List[Creature]:
        cell_x, cell_y = self._cell_for(position)
        radius = max(1, (range_ + self._spatial_cell_size - 1) // self._spatial_cell_size)
        nearby = []
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                bucket = index.get((cell_x + dx, cell_y + dy), [])
                for entity in bucket:
                    if entity.alive:
                        dist = abs(entity.position[0] - position[0]) + abs(entity.position[1] - position[1])
                        if dist <= range_:
                            nearby.append(entity)
        return nearby
    
    def _get_species_counts(self) -> Dict[str, int]:
        species_counts = {sp: 0 for sp in self.PLANT_SPECIES + self.LAND_ANIMAL_SPECIES + self.AQUATIC_SPECIES}
        species_counts.update(Counter(p.species for p in self.plants if p.alive))
        species_counts.update(Counter(a.species for a in self.animals if a.alive))
        species_counts.update(Counter(a.species for a in self.aquatic_creatures if a.alive))
        return species_counts
    
    def _soft_population_limit(self, species: str, domain: str) -> int:
        water_capacity = max(1, len(self.environment.water_quality))
        land_capacity = self.width * self.height
        if domain == "aquatic":
            if species in self.AQUATIC_PRODUCERS:
                return int(water_capacity * 0.55)
            if species in self.AQUATIC_CONSUMERS:
                return int(water_capacity * 0.18)
            if species in self.AQUATIC_PREDATORS:
                return int(water_capacity * 0.08)
            return int(water_capacity * 0.12)
        if species in {"insect", "mouse", "rabbit"}:
            return int(land_capacity * 0.12)
        if species in {"fox", "wolf", "snake", "spider", "eagle", "owl"}:
            return int(land_capacity * 0.03)
        return int(land_capacity * 0.05)
    
    def _allow_spawn(self, species: str, current_count: int, domain: str, manual: bool = False) -> bool:
        if manual:
            return True
        soft_limit = max(1, self._soft_population_limit(species, domain))
        if current_count <= soft_limit:
            suppression = 0.0
        else:
            overflow = current_count - soft_limit
            suppression = min(0.97, overflow / max(1, soft_limit) * 0.7)

        if domain == "aquatic":
            water_capacity = max(1, len(self.environment.water_quality))
            total_aquatic = sum(1 for a in self.aquatic_creatures if a.alive)
            global_soft_limit = max(1, int(water_capacity * 1.45))
            if total_aquatic > global_soft_limit:
                global_overflow = total_aquatic - global_soft_limit
                trophic_weight = 1.0
                if species in self.AQUATIC_CONSUMERS:
                    trophic_weight = 0.7 if current_count > 6 else 0.35
                elif species in self.AQUATIC_PREDATORS:
                    trophic_weight = 0.45 if current_count > 4 else 0.15
                suppression = max(
                    suppression,
                    min(0.985, global_overflow / max(1, global_soft_limit) * 0.9 * trophic_weight),
                )
        return random.random() > suppression

    def _invalidate_stats_cache(self):
        self._stats_cache = None
        self._stats_cache_tick = -1

    def _apply_population_pressure(self, species_counts: Dict[str, int]):
        """按营养级和关键物种数量给出生存/繁殖阻尼。"""
        land_prey_total = sum(species_counts.get(sp, 0) for sp in self.LAND_PREY)
        aquatic_producer_total = sum(species_counts.get(sp, 0) for sp in self.AQUATIC_PRODUCERS)
        aquatic_consumer_total = sum(species_counts.get(sp, 0) for sp in self.AQUATIC_CONSUMERS)

        def modifiers(species: str) -> Tuple[float, float]:
            hunger_mult = 1.0
            reproduction_mult = 1.0
            count = species_counts.get(species, 0)

            if species == "insect":
                if count > 90:
                    hunger_mult *= 1.18
                    reproduction_mult *= 0.72
                elif count > 65:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.86
            elif species == "rabbit":
                if count > 20:
                    hunger_mult *= 1.12
                    reproduction_mult *= 0.82
            elif species == "mouse":
                if count > 24:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.84
            elif species == "fox":
                if count <= 4 and land_prey_total > 35:
                    hunger_mult *= 0.88
                    reproduction_mult *= 1.28
            elif species == "wolf":
                if count <= 3 and species_counts.get("deer", 0) + species_counts.get("rabbit", 0) > 18:
                    hunger_mult *= 0.90
                    reproduction_mult *= 1.20
            elif species == "plankton":
                if count > 150:
                    hunger_mult *= 1.20
                    reproduction_mult *= 0.68
                elif count > 110:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.84
            elif species == "algae":
                if count > 120:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.78
            elif species == "carp":
                if count > 28:
                    hunger_mult *= 1.12
                    reproduction_mult *= 0.74
                elif count <= 8 and aquatic_producer_total > 90:
                    hunger_mult *= 0.92
                    reproduction_mult *= 1.22
            elif species == "small_fish":
                if count > 30:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.80
                elif count <= 12 and aquatic_producer_total > 90:
                    hunger_mult *= 0.82
                    reproduction_mult *= 1.55
            elif species == "minnow":
                if count <= 12 and aquatic_producer_total > 75:
                    hunger_mult *= 0.80
                    reproduction_mult *= 1.46
                elif count > 34:
                    hunger_mult *= 1.12
                    reproduction_mult *= 0.78
            elif species == "shrimp":
                if count <= 8 and aquatic_producer_total > 75:
                    hunger_mult *= 0.82
                    reproduction_mult *= 1.50
                elif count > 24:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.82
            elif species == "blackfish":
                if count <= 2 and aquatic_consumer_total > 20:
                    hunger_mult *= 0.82
                    reproduction_mult *= 1.45
                elif count > 10:
                    hunger_mult *= 1.06
                    reproduction_mult *= 0.85
            elif species == "pike":
                if count <= 2 and aquatic_consumer_total > 18:
                    hunger_mult *= 0.86
                    reproduction_mult *= 1.22
                elif count <= 4 and aquatic_consumer_total > 24:
                    hunger_mult *= 0.92
                    reproduction_mult *= 1.08
                elif count > 9:
                    hunger_mult *= 1.07
                    reproduction_mult *= 0.84
            elif species == "catfish":
                if count <= 3 and aquatic_consumer_total > 18:
                    hunger_mult *= 0.94
                    reproduction_mult *= 1.10
                elif count <= 5 and aquatic_consumer_total > 24:
                    hunger_mult *= 0.94
                    reproduction_mult *= 1.04
            elif species == "large_fish":
                if count <= 2 and aquatic_consumer_total > 16:
                    hunger_mult *= 0.84
                    reproduction_mult *= 1.36
                elif count <= 4 and aquatic_consumer_total > 22:
                    hunger_mult *= 0.92
                    reproduction_mult *= 1.14
                elif count <= 6 and aquatic_consumer_total > 24:
                    hunger_mult *= 0.96
                    reproduction_mult *= 1.08
                elif count > 8:
                    hunger_mult *= 1.04
                    reproduction_mult *= 0.88

            return hunger_mult, reproduction_mult

        for collection in (self.plants, self.animals, self.aquatic_creatures):
            for entity in collection:
                if entity.alive and hasattr(entity, "apply_ecology_modifiers"):
                    hunger_mult, reproduction_mult = modifiers(entity.species)
                    entity.apply_ecology_modifiers(hunger_mult, reproduction_mult)

    def _maybe_recolonize_species(self, species_counts: Dict[str, int]):
        """关键控制物种的低密度自然迁入，避免生态链永久断裂。"""
        if self.tick_count < 40 or self.tick_count % 12 != 0:
            return

        season = self.environment.season
        weather = self.environment.weather
        recolonization_rules = [
            {
                "species": "fox",
                "domain": "land",
                "max_count": 2,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["rabbit", "mouse", "insect", "frog"]) >= 24,
                "chance": 0.18 if season == "winter" else 0.28,
                "position": self._random_edge_land_position,
                "message": "一只狐狸沿陆地边缘迁入了这片区域",
                "cooldown": 72,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_animals(pos, 8)
                    if a.species in {"rabbit", "mouse", "insect", "frog"} and a.alive
                ]) >= 4,
            },
            {
                "species": "small_fish",
                "domain": "aquatic",
                "max_count": 4,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["plankton", "algae", "water_strider"]) >= 48,
                "chance": 0.24 if weather in {"rainy", "stormy"} else 0.18,
                "position": lambda: self._random_inflow_water_position_for_body_type({"lake_shallow", "lake_deep"}),
                "message": "一群小鱼从邻近湖湾回游补入湖区",
                "cooldown": 36,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_aquatic(pos, 6)
                    if a.species in {"plankton", "algae", "water_strider"} and a.alive
                ]) >= 4,
            },
            {
                "species": "minnow",
                "domain": "aquatic",
                "max_count": 8,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["plankton", "algae", "water_strider"]) >= 48,
                "chance": 0.28 if weather in {"rainy", "stormy"} else 0.2,
                "position": lambda: self._random_inflow_water_position_for_body_type({"river_channel", "lake_shallow"}),
                "message": "一小群米诺鱼顺着河道和浅湖连通带迁入",
                "cooldown": 36,
                "habitat_check": lambda pos: self.environment.get_water_body_type(pos[0], pos[1]) == "river_channel" and len([
                    a for a in self.get_nearby_aquatic(pos, 6)
                    if a.species in {"plankton", "algae", "water_strider"} and a.alive
                ]) >= 4,
            },
            {
                "species": "shrimp",
                "domain": "aquatic",
                "max_count": 5,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["algae", "plankton", "seaweed"]) >= 55,
                "chance": 0.28 if weather in {"rainy", "stormy"} else 0.18,
                "position": lambda: self._random_inflow_water_position_for_body_type({"river_channel", "lake_shallow"}),
                "message": "少量虾群顺着连通水道迁入",
                "cooldown": 36,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_aquatic(pos, 6)
                    if a.species in {"algae", "plankton", "seaweed"} and a.alive
                ]) >= 4,
            },
            {
                "species": "blackfish",
                "domain": "aquatic",
                "max_count": 1,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["carp", "small_fish", "minnow"]) >= 18,
                "chance": 0.14,
                "position": lambda: self._random_inflow_water_position_for_body_type({"lake_shallow", "lake_deep"}),
                "message": "一条黑鱼顺着外部连通水体迁入",
                "cooldown": 96,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_aquatic(pos, 8)
                    if a.species in {"carp", "small_fish", "minnow"} and a.alive
                ]) >= 3,
            },
            {
                "species": "large_fish",
                "domain": "aquatic",
                "max_count": 1,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["small_fish", "minnow", "carp", "shrimp"]) >= 20,
                "chance": 0.20,
                "position": lambda: self._random_inflow_water_position_for_body_type({"lake_deep", "lake_shallow"}),
                "message": "一条大鱼从深湖连通带回游进入该湖区",
                "cooldown": 24,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_aquatic(pos, 8)
                    if a.species in {"small_fish", "minnow", "carp", "shrimp"} and a.alive
                ]) >= 2,
            },
            {
                "species": "pike",
                "domain": "aquatic",
                "max_count": 1,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["carp", "small_fish", "minnow", "frog"]) >= 20,
                "chance": 0.12,
                "position": lambda: self._random_inflow_water_position_for_body_type({"river_channel", "lake_shallow"}),
                "message": "一条狗鱼沿河道迁入了该水域",
                "cooldown": 108,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_aquatic(pos, 8)
                    if a.species in {"carp", "small_fish", "minnow", "frog"} and a.alive
                ]) >= 3,
            },
        ]

        for rule in recolonization_rules:
            species = rule["species"]
            if species_counts.get(species, 0) > rule["max_count"] or not rule["food_min"]:
                continue
            if self.tick_count - self._migration_cooldowns.get(species, -10_000) < rule["cooldown"]:
                continue
            chance = rule["chance"]
            if species == "large_fish" and species_counts.get(species, 0) == 0:
                chance = min(0.45, chance * 2)
            if random.random() >= chance:
                continue

            pos = rule["position"]()
            if not pos:
                continue
            if not rule["habitat_check"](pos):
                continue

            if rule["domain"] == "land":
                before = len(self.animals)
                self.spawn_animal(species, pos, source="natural")
                spawned = len(self.animals) > before
            else:
                before = len(self.aquatic_creatures)
                self.spawn_aquatic(species, pos, source="natural")
                spawned = len(self.aquatic_creatures) > before

            if spawned:
                self._migration_cooldowns[species] = self.tick_count
                self.log_event(rule["message"])
                self.balance.record_causal_event(
                    cause=f"{species}自然迁入",
                    effect=f"{species}+1",
                    impact=0.08,
                    tick=self.tick_count,
                )
                species_counts[species] = species_counts.get(species, 0) + 1
                
    def update(self):
        """更新整个生态系统"""
        self.tick_count += 1
        self._invalidate_stats_cache()

        species_counts = self._get_species_counts()
        self._apply_population_pressure(species_counts)
        
        # 获取生物数量用于环境更新
        plant_count = len([p for p in self.plants if p.alive])
        fish_count = len([a for a in self.aquatic_creatures if a.species in ["small_fish", "minnow", "large_fish", "carp", "catfish", "blackfish", "pike"] and a.alive])
        
        # 更新环境
        self.environment.update(plant_count, fish_count)
        
        # 记录上一轮的物种数量
        self.previous_counts = species_counts
        self._rebuild_spatial_indices()
        
        # 更新陆地植物
        for plant in self.plants:
            plant.update(self)
        self.plants = [p for p in self.plants if p.alive]
        self._rebuild_spatial_indices()
        
        # 更新陆地动物
        for animal in self.animals:
            animal.update(self)
        self.animals = [a for a in self.animals if a.alive]
        self._rebuild_spatial_indices()
        
        # 更新水生生物
        for aquatic in self.aquatic_creatures:
            aquatic.execute_behavior(self)
        self.aquatic_creatures = [a for a in self.aquatic_creatures if a.alive]
        self._rebuild_spatial_indices()

        current_counts = self._get_species_counts()
        self._maybe_recolonize_species(current_counts)
        
        # 蝴蝶效应分析
        current_stats = self.get_statistics()
        current_counts = current_stats.get("species", {})
        for species, new_count in current_counts.items():
            old_count = self.previous_counts.get(species, 0)
            if abs(new_count - old_count) >= 3:
                self.balance.analyze_cascade(species, new_count, old_count, self.tick_count)
        self.balance.record_snapshot(current_stats)
        self.active_alerts = self.balance.check_balance(current_stats)
        
    def spawn_plant(self, species: str, position: Tuple[int, int], source: str = "manual"):
        """生成植物 - 支持所有物种"""
        plant_classes = {
            "grass": Grass, "bush": Bush, "flower": Flower, "moss": Moss,
            "tree": Tree, "vine": Vine, "cactus": Cactus, "berry": Berry,
            "mushroom": Mushroom, "fern": Fern,
            # 果类植物
            "apple_tree": AppleTree, "cherry_tree": CherryTree,
            "grape_vine": GrapeVine, "strawberry": Strawberry,
            "blueberry": Blueberry, "orange_tree": OrangeTree,
            "watermelon": Watermelon
        }
        if species in plant_classes and self.environment.is_land(position[0], position[1]):
            plant = plant_classes[species](position)
            self.plants.append(plant)
            cell = self._cell_for(plant.position)
            self._plant_index[cell].append(plant)
            self._entity_cells[plant.id] = ("plant", cell)
            self._invalidate_stats_cache()
            self.balance.record_causal_event(
                cause=f"添加{species}", effect=f"{species}+1", impact=0.1, tick=self.tick_count
            )
        
    def add_plant_directly(self, plant: Plant):
        """直接添加植物"""
        if plant and plant.alive:
            self.plants.append(plant)
            cell = self._cell_for(plant.position)
            self._plant_index[cell].append(plant)
            self._entity_cells[plant.id] = ("plant", cell)
            self._invalidate_stats_cache()
            
    def spawn_animal(self, species: str, position: Tuple[int, int], gender: Gender = None, is_offspring: bool = False, source: str = "natural"):
        """生成动物 - 支持所有物种"""
        animal_classes = {
            "insect": Insect, "rabbit": Rabbit, "fox": Fox, "deer": Deer,
            "mouse": Mouse, "bird": Bird, "snake": Snake, "bee": Bee, "frog": Frog,
            "eagle": Eagle, "owl": Owl, "duck": Duck, "swan": Swan,
            "sparrow": Sparrow, "parrot": Parrot, "kingfisher": Kingfisher,
            "wolf": Wolf, "spider": Spider,
            # 新增鸟类
            "magpie": Magpie, "crow": Crow, "woodpecker": Woodpecker, "hummingbird": Hummingbird,
            # 新增哺乳动物
            "squirrel": Squirrel, "hedgehog": Hedgehog, "bat": Bat, "raccoon": Raccoon,
            # 新增杂食动物
            "bear": Bear, "wild_boar": WildBoar, "badger": Badger,
            "raccoon_dog": RaccoonDog, "skunk": Skunk, "opossum": Opossum,
            "coati": Coati, "armadillo": Armadillo
        }
        current_count = len([a for a in self.animals if a.species == species and a.alive])
        manual = source == "manual" and not is_offspring
        if species in animal_classes and self._allow_spawn(species, current_count, "land", manual=manual) and (species == "frog" or self.environment.is_land(position[0], position[1]) or self.environment.is_water(position[0], position[1])):
            animal = animal_classes[species](position, gender)
            self.animals.append(animal)
            cell = self._cell_for(animal.position)
            self._animal_index[cell].append(animal)
            self._entity_cells[animal.id] = ("animal", cell)
            self._invalidate_stats_cache()
            cause = f"{species}出生" if is_offspring else f"添加{species}"
            self.balance.record_causal_event(cause=cause, effect=f"{species}+1", impact=0.15 if is_offspring else 0.2, tick=self.tick_count)
            
    def spawn_aquatic(self, species: str, position: Tuple[int, int], source: str = "natural"):
        """生成水生生物 - 支持所有物种"""
        aquatic_classes = {
            "algae": Algae, "seaweed": Seaweed, "plankton": Plankton,
            "small_fish": SmallFish, "minnow": Minnow, "carp": Carp, "catfish": Catfish, 
            "large_fish": LargeFish, "pufferfish": Pufferfish,
            "shrimp": Shrimp, "crab": Crab, "tadpole": Tadpole, "water_strider": WaterStrider,
            "blackfish": Blackfish, "pike": Pike  # 新增天敌鱼
        }
        current_count = len([a for a in self.aquatic_creatures if a.species == species and a.alive])
        if species in aquatic_classes and self._allow_spawn(species, current_count, "aquatic", manual=(source == "manual")) and self.environment.is_water(position[0], position[1]):
            creature = aquatic_classes[species](position)
            self.aquatic_creatures.append(creature)
            cell = self._cell_for(creature.position)
            self._aquatic_index[cell].append(creature)
            self._entity_cells[creature.id] = ("aquatic", cell)
            self._invalidate_stats_cache()
            
    def get_nearby_creatures(self, position: Tuple[int, int], range_: int) -> List[Creature]:
        """获取附近陆地生物"""
        return self._query_spatial_index(self._animal_index, position, range_)
        
    def get_nearby_plants(self, position: Tuple[int, int], range_: int) -> List[Plant]:
        """获取附近植物"""
        return self._query_spatial_index(self._plant_index, position, range_)
        
    def get_nearby_animals(self, position: Tuple[int, int], range_: int) -> List[Animal]:
        """获取附近动物"""
        return self.get_nearby_creatures(position, range_)
    
    def get_nearby_aquatic(self, position: Tuple[int, int], range_: int) -> List[AquaticCreature]:
        """获取附近水生生物"""
        return self._query_spatial_index(self._aquatic_index, position, range_)
        
    def log_event(self, description: str):
        """记录事件"""
        event = Event(tick=self.tick_count, type="action", description=description)
        self.events.append(event)
        if len(self.events) > 1000:
            self.events = self.events[-1000:]
            
    def get_statistics(self) -> Dict:
        """获取统计数据 - 包含所有物种"""
        if self._stats_cache_tick == self.tick_count and self._stats_cache is not None:
            return self._stats_cache

        species_counts = self._get_species_counts()
        
        # 性别统计
        gender_stats = {}
        for sp in self.LAND_ANIMAL_SPECIES:
            animals = [a for a in self.animals if a.species == sp]
            males = len([a for a in animals if hasattr(a, 'gender') and (a.gender == Gender.MALE or a.gender == "male")])
            females = len([a for a in animals if hasattr(a, 'gender') and (a.gender == Gender.FEMALE or a.gender == "female")])
            pregnant = len([a for a in animals if hasattr(a, 'pregnant') and a.pregnant])
            if males + females > 0:
                gender_stats[sp] = {"males": males, "females": females, "pregnant": pregnant}
            
        env_summary = self.environment.get_environment_summary()
        
        self._stats_cache = {
            "tick": self.tick_count,
            "day": env_summary["day"],
            "season": env_summary["season"],
            "weather": env_summary["weather"],
            "temperature": env_summary["temperature"],
            "sunlight": env_summary["sunlight"],
            "plants": len(self.plants),
            "animals": len(self.animals),
            "aquatic": len(self.aquatic_creatures),
            "species": species_counts,
            "gender": gender_stats,
            "health": self.balance.get_ecosystem_health({"species": species_counts, "tick": self.tick_count}),
            "alerts": [str(a) for a in self.active_alerts],
            "recommendations": self.balance.get_recommendations({"species": species_counts, "tick": self.tick_count}),
            "butterfly_events": [str(e) for e in self.balance.get_butterfly_events(5)],
            "grass_protection": self.balance.grass_protection_factor,
            "environment": env_summary,
        }
        self._stats_cache_tick = self.tick_count
        return self._stats_cache

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
    Magpie, Crow, Woodpecker, Hummingbird, NightMoth,
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


@dataclass
class MicrohabitatPatch:
    """可被生物占用和消耗的微栖息地资源。"""
    kind: str
    position: Tuple[int, int]
    capacity: float
    available: float
    seasonal_multiplier: float
    occupancy: float = 0.0


class Ecosystem:
    """完整生态系统 - 陆地 + 水生"""

    DEFAULT_INITIAL_POPULATION = {
        "grass": 500, "bush": 150, "flower": 200, "moss": 100,
        "tree": 80, "vine": 120, "cactus": 60, "berry": 100, "mushroom": 150, "fern": 120,
        "apple_tree": 100, "cherry_tree": 80, "grape_vine": 150, "strawberry": 200,
        "blueberry": 150, "orange_tree": 80, "watermelon": 100,
        "insects": 200, "night_moths": 120, "rabbits": 150, "foxes": 50, "deer": 30, "mouse": 100, "bird": 60, "snake": 30, "bee": 80,
        "eagle": 20, "owl": 30, "duck": 50, "swan": 30, "sparrow": 140, "parrot": 40, "kingfisher": 30,
        "wolf": 30, "spider": 100, "magpie": 80, "crow": 50, "woodpecker": 60, "hummingbird": 100,
        "squirrel": 120, "hedgehog": 80, "bat": 80, "raccoon": 60,
        "bear": 40, "wild_boar": 100, "badger": 80, "raccoon_dog": 60, "skunk": 80, "opossum": 100, "coati": 60, "armadillo": 60,
        "algae": 300, "seaweed": 150, "plankton": 400, "small_fish": 150, "minnow": 120, "carp": 80, "catfish": 50,
        "large_fish": 30, "pufferfish": 40, "blackfish": 40, "pike": 30, "shrimp": 200, "crab": 60, "frog": 80,
        "tadpole": 80, "water_strider": 100,
    }
    POPULATION_ALIASES = {
        "insect": "insects",
        "night_moth": "night_moths",
        "rabbit": "rabbits",
        "fox": "foxes",
    }
    PREY_RESERVE = {
        "insect": 18, "night_moth": 14, "bee": 6, "spider": 4,
        "rabbit": 10, "mouse": 8, "bird": 6, "sparrow": 14, "parrot": 4, "duck": 3,
        "deer": 4, "frog": 16,
        "small_fish": 8, "minnow": 16, "carp": 4, "shrimp": 10, "tadpole": 8, "water_strider": 8,
    }
    PREDATOR_APPETITE = {
        "fox": 2.5, "wolf": 2.2, "snake": 1.3, "bird": 1.2, "sparrow": 1.0, "eagle": 1.8, "owl": 1.6,
        "spider": 0.9, "blackfish": 2.1, "pike": 1.35, "large_fish": 1.7, "catfish": 1.6, "crab": 1.1,
        "kingfisher": 1.2,
    }

    PLANT_SPECIES = [
        "grass", "bush", "flower", "moss",
        "tree", "vine", "cactus", "berry", "mushroom", "fern",
        "apple_tree", "cherry_tree", "grape_vine", "strawberry",
        "blueberry", "orange_tree", "watermelon",
    ]
    LAND_ANIMAL_SPECIES = [
        "insect", "night_moth", "rabbit", "fox", "deer", "mouse", "bird", "snake", "bee",
        "eagle", "owl", "duck", "swan", "sparrow", "parrot", "kingfisher",
        "wolf", "spider",
        "magpie", "crow", "woodpecker", "hummingbird",
        "squirrel", "hedgehog", "bat", "raccoon",
        "bear", "wild_boar", "badger", "raccoon_dog",
        "skunk", "opossum", "coati", "armadillo",
    ]
    AMPHIBIOUS_ANIMAL_SPECIES = ["frog"]
    ALL_ANIMAL_SPECIES = LAND_ANIMAL_SPECIES + AMPHIBIOUS_ANIMAL_SPECIES
    AQUATIC_SPECIES = [
        "algae", "seaweed", "plankton", "small_fish", "minnow", "carp", "catfish",
        "large_fish", "pufferfish", "shrimp", "crab", "tadpole", "water_strider",
        "blackfish", "pike",
    ]
    AQUATIC_PRODUCERS = {"algae", "seaweed", "plankton"}
    AQUATIC_CONSUMERS = {"small_fish", "minnow", "carp", "shrimp", "tadpole", "water_strider", "pufferfish"}
    AQUATIC_PREDATORS = {"catfish", "large_fish", "blackfish", "pike", "crab"}
    LAND_PREY = {
        "insect", "night_moth", "rabbit", "mouse", "deer", "bird", "sparrow", "duck", "frog",
        "bee", "squirrel", "hedgehog", "bat", "raccoon", "raccoon_dog",
        "opossum", "armadillo", "magpie", "crow", "woodpecker", "parrot",
        "hummingbird",
    }
    LAND_PREDATORS = {"fox", "wolf", "snake", "spider", "eagle", "owl", "bear", "wild_boar", "badger", "skunk", "coati"}
    AMPHIBIOUS_SPECIES = {"frog", "duck", "swan"}
    FISH_SPECIES = {"small_fish", "minnow", "large_fish", "carp", "catfish", "blackfish", "pike"}
    
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
        self._spatial_offset_cache: Dict[int, List[Tuple[int, int]]] = {}
        self._entity_cells: Dict[str, Tuple[str, Tuple[int, int]]] = {}
        self._stats_cache: Optional[Dict] = None
        self._stats_cache_tick: int = -1
        self._migration_cooldowns: Dict[str, int] = {}
        self._latest_species_counts: Optional[Dict[str, int]] = None
        self._latest_gender_counts: Optional[Dict[str, Dict[str, int]]] = None
        self._latest_diet_counts: Optional[Dict[str, int]] = None
        self._nearby_plant_cache: Dict[Tuple[int, int, int, int], List[Plant]] = {}
        self._nearby_creature_cache: Dict[Tuple[int, int, int, int], List[Creature]] = {}
        self._nearby_aquatic_cache: Dict[Tuple[int, int, int, int], List[AquaticCreature]] = {}
        self._microhabitat_patch_cache: Dict[Tuple[int, int, int, int, Tuple[str, ...]], List[MicrohabitatPatch]] = {}
        self._microhabitat_value_cache: Dict[Tuple[int, int, int, int, Tuple[str, ...]], float] = {}
        self._nearby_aquatic_count_cache: Dict[Tuple[int, int, int, int, Tuple[str, ...]], Dict[str, int]] = {}
        self._water_candidate_cache: Dict[Tuple[int, int, int], List[Tuple[int, int]]] = {}
        self._adjacent_water_score_cache: Dict[Tuple[int, int, int, int], float] = {}
        self.microhabitats: List[MicrohabitatPatch] = []
        self._microhabitat_index: Dict[Tuple[int, int], List[MicrohabitatPatch]] = defaultdict(list)
        
        self._init_population()
        self._rebuild_spatial_indices()
        self._rebuild_microhabitat_resources()
        self._latest_species_counts = self._get_species_counts()
        
    def _load_config(self, path: str = None, config: dict = None) -> dict:
        if config is not None:
            return config
        if path:
            with open(path, 'r') as f:
                return yaml.safe_load(f)
        return {}

    def _resolve_initial_population(self) -> Dict[str, int]:
        """归一化初始种群配置，兼容新旧键名并补齐缺失物种。"""
        configured = dict(self.config.get("initial_population", {}))
        normalized = dict(self.DEFAULT_INITIAL_POPULATION)
        for key, value in configured.items():
            normalized[key] = value
            alias_target = self.POPULATION_ALIASES.get(key)
            if alias_target:
                normalized[alias_target] = value

        for alias, canonical in self.POPULATION_ALIASES.items():
            if alias in configured and canonical not in configured:
                normalized[canonical] = configured[alias]
            if canonical in configured and alias not in configured:
                normalized[alias] = configured[canonical]

        for species in self.ALL_ANIMAL_SPECIES + self.AQUATIC_SPECIES + self.PLANT_SPECIES:
            normalized.setdefault(species, 0)
        return normalized

    def _init_population(self):
        """初始化所有生物"""
        initial = self._resolve_initial_population()
        
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

        for _ in range(initial.get("night_moths", 12)):
            pos = self._random_water_adjacent_position() or self._random_land_position()
            if pos:
                self.animals.append(NightMoth(pos))
            
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
            pos = self._random_amphibious_position()
            if pos:
                self.animals.append(Duck(pos))
            
        for _ in range(initial.get("swan", 3)):
            pos = self._random_water_position() or self._random_amphibious_position()
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
        for _ in range(initial.get("frog", 8)):
            pos = self._random_amphibious_position()
            if pos:
                self.animals.append(Frog(pos))

        for _ in range(initial.get("tadpole", 8)):
            pos = self._random_water_position_for_body_type({"lake_shallow", "river_channel"})
            if pos:
                self.aquatic_creatures.append(Tadpole(pos))

        for _ in range(initial.get("water_strider", 10)):
            pos = self._random_water_position_for_body_type({"lake_shallow", "river_channel"})
            if pos:
                self.aquatic_creatures.append(WaterStrider(pos))
            
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

    def _random_amphibious_position(self) -> Optional[Tuple[int, int]]:
        """随机两栖友好位置，优先湿地边缘，其次浅水或陆地。"""
        return (
            self._random_water_adjacent_position()
            or self._random_water_position_for_body_type({"river_channel", "lake_shallow"})
            or self._random_land_position()
        )

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

    def _microhabitat_cell_for(self, position: Tuple[int, int]) -> Tuple[int, int]:
        cell_size = max(2, self._spatial_cell_size)
        return (position[0] // cell_size, position[1] // cell_size)

    def _seasonal_resource_pulse(self, kind: str) -> float:
        season = self.environment.season
        weather_value = self.environment.weather
        weather = weather_value.value if hasattr(weather_value, "value") else str(weather_value)
        hour = self.environment.hour
        pulse = 1.0
        if kind == "nectar_patch":
            if season == "spring":
                pulse *= 1.48
            elif season == "summer":
                pulse *= 1.28
            elif season == "winter":
                pulse *= 0.65
            if weather in {"rainy", "stormy"}:
                pulse *= 0.84
        elif kind in {"canopy_roost", "night_roost"}:
            if season in {"spring", "summer"}:
                pulse *= 1.18
            if kind == "night_roost" and (hour >= 18 or hour < 6):
                pulse *= 1.42
            elif kind == "night_roost":
                pulse *= 0.92
        elif kind == "shrub_shelter":
            if season in {"spring", "summer"}:
                pulse *= 1.18
            if weather in {"rainy", "foggy"}:
                pulse *= 1.06
        elif kind == "wetland_patch":
            if season == "spring":
                pulse *= 1.12
            elif season == "winter":
                pulse *= 0.78
            if weather in {"rainy", "stormy"}:
                pulse *= 1.08
        elif kind == "riparian_perch":
            if season in {"spring", "summer"}:
                pulse *= 1.18
            if weather in {"rainy", "stormy"}:
                pulse *= 1.08
        elif kind == "night_swarm":
            if season in {"spring", "summer"}:
                pulse *= 1.32
            elif season == "winter":
                pulse *= 0.58
            if hour >= 18 or hour < 6:
                pulse *= 1.38
            else:
                pulse *= 0.72
            if weather in {"rainy", "stormy"}:
                pulse *= 0.82
        elif kind == "canopy_forage":
            if season in {"summer", "autumn"}:
                pulse *= 1.24
            elif season == "winter":
                pulse *= 0.76
            if weather in {"rainy", "foggy"}:
                pulse *= 1.04
        elif kind == "shore_hatch":
            if season in {"spring", "summer"}:
                pulse *= 1.30
            elif season == "winter":
                pulse *= 0.70
            if hour in {5, 6, 7, 17, 18, 19}:
                pulse *= 1.34
            if weather in {"rainy", "foggy"}:
                pulse *= 1.12
        return max(0.45, min(1.6, pulse))

    def _add_microhabitat_patch(self, kind: str, position: Tuple[int, int], capacity: float):
        seasonal_multiplier = self._seasonal_resource_pulse(kind)
        patch = MicrohabitatPatch(
            kind=kind,
            position=position,
            capacity=capacity,
            available=capacity * seasonal_multiplier,
            seasonal_multiplier=seasonal_multiplier,
        )
        self.microhabitats.append(patch)
        self._microhabitat_index[self._microhabitat_cell_for(position)].append(patch)

    def _rebuild_microhabitat_resources(self):
        previous_state = {
            (patch.kind, patch.position): (
                patch.available / max(0.1, patch.capacity * max(0.45, patch.seasonal_multiplier)),
                patch.occupancy,
            )
            for patch in self.microhabitats
        }
        self.microhabitats = []
        self._microhabitat_index = defaultdict(list)
        canopy_species = {"tree", "apple_tree", "cherry_tree", "orange_tree"}
        shrub_species = {"bush", "berry", "blueberry", "strawberry", "grape_vine"}
        nectar_species = {"flower", "berry", "blueberry", "strawberry"}
        wetland_species = {"moss", "fern"}
        canopy_forage_species = {"tree", "apple_tree", "cherry_tree", "orange_tree", "berry", "blueberry"}

        for plant in self.plants:
            if not plant.alive:
                continue
            size = max(0.8, getattr(plant, "size", 1.0))
            if plant.species in canopy_species:
                self._add_microhabitat_patch("canopy_roost", plant.position, 1.2 * size)
                self._add_microhabitat_patch("night_roost", plant.position, 1.0 * size)
                self._add_microhabitat_patch("canopy_forage", plant.position, 0.8 * size)
            if plant.species in shrub_species:
                self._add_microhabitat_patch("shrub_shelter", plant.position, 0.9 * size)
            if plant.species in nectar_species:
                self._add_microhabitat_patch("nectar_patch", plant.position, 0.8 * size)
                self._add_microhabitat_patch("night_swarm", plant.position, 0.55 * size)
            if plant.species in wetland_species:
                self._add_microhabitat_patch("wetland_patch", plant.position, 0.9 * size)
                self._add_microhabitat_patch("night_swarm", plant.position, 0.5 * size)
            if plant.species in canopy_forage_species and plant.species not in canopy_species:
                self._add_microhabitat_patch("canopy_forage", plant.position, 0.6 * size)

            if plant.species in canopy_species.union(shrub_species):
                x, y = plant.position
                near_water = False
                for dx in range(-1, 2):
                    for dy in range(-1, 2):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.width and 0 <= ny < self.height and self.environment.is_water(nx, ny):
                            near_water = True
                            break
                    if near_water:
                        break
                if near_water:
                    self._add_microhabitat_patch("riparian_perch", plant.position, 0.85 * size)
                    self._add_microhabitat_patch("shore_hatch", plant.position, 0.55 * size)

        for aquatic in self.aquatic_creatures:
            if aquatic.alive and aquatic.species in {"water_strider", "tadpole"}:
                self._add_microhabitat_patch("wetland_patch", aquatic.position, 0.6)
                self._add_microhabitat_patch("night_swarm", aquatic.position, 0.35)
                self._add_microhabitat_patch("shore_hatch", aquatic.position, 0.5)

        for patch in self.microhabitats:
            ratio, occupancy = previous_state.get((patch.kind, patch.position), (1.0, 0.0))
            patch.available = min(
                patch.capacity * patch.seasonal_multiplier,
                max(0.0, patch.capacity * patch.seasonal_multiplier * ratio),
            )
            patch.occupancy = min(patch.capacity, max(0.0, occupancy))

    def _update_microhabitat_resources(self):
        for patch in self.microhabitats:
            target = patch.capacity * patch.seasonal_multiplier
            recovery_multiplier = 1.0
            if patch.kind in {"canopy_roost", "night_roost"}:
                recovery_multiplier = 1.22
            elif patch.kind in {"nectar_patch", "shrub_shelter"}:
                recovery_multiplier = 1.28
            elif patch.kind == "riparian_perch":
                recovery_multiplier = 1.18
            elif patch.kind == "wetland_patch":
                recovery_multiplier = 0.92
            elif patch.kind == "night_swarm":
                recovery_multiplier = 1.25
            elif patch.kind == "canopy_forage":
                recovery_multiplier = 1.15
            elif patch.kind == "shore_hatch":
                recovery_multiplier = 1.20
            recovery_rate = max(0.04, target * 0.06 * recovery_multiplier)
            patch.available = min(target, patch.available + recovery_rate)
            patch.occupancy = max(0.0, patch.occupancy - max(0.03, patch.capacity * 0.04))

    def get_microhabitat_patches(
        self,
        kinds=None,
        position: Optional[Tuple[int, int]] = None,
        radius: int = 4,
    ) -> List[MicrohabitatPatch]:
        if isinstance(kinds, str):
            kinds = (kinds,)
            normalized_kinds = kinds
            kind_filter = {kinds[0]}
        elif kinds is None:
            normalized_kinds = tuple()
            kind_filter = None
        else:
            normalized_kinds = tuple(sorted(kinds))
            kind_filter = set(normalized_kinds)

        if position is None:
            patches = self.microhabitats
        else:
            cache_key = (self.tick_count, position[0], position[1], radius, normalized_kinds)
            cached = self._microhabitat_patch_cache.get(cache_key)
            if cached is not None:
                return cached
            cell_x, cell_y = self._microhabitat_cell_for(position)
            cell_radius = max(1, (radius + self._spatial_cell_size - 1) // self._spatial_cell_size)
            offsets = self._spatial_offset_cache.get(cell_radius)
            if offsets is None:
                offsets = [(dx, dy) for dx in range(-cell_radius, cell_radius + 1) for dy in range(-cell_radius, cell_radius + 1)]
                self._spatial_offset_cache[cell_radius] = offsets
            patches = []
            get_bucket = self._microhabitat_index.get
            patches_extend = patches.extend
            for dx, dy in offsets:
                bucket = get_bucket((cell_x + dx, cell_y + dy))
                if bucket:
                    patches_extend(bucket)

        result = []
        result_append = result.append
        px = py = None
        if position is not None:
            px, py = position
        for patch in patches:
            if kind_filter and patch.kind not in kind_filter:
                continue
            if position is not None:
                dist = abs(patch.position[0] - px) + abs(patch.position[1] - py)
                if dist > radius:
                    continue
            result_append(patch)
        if position is not None:
            self._microhabitat_patch_cache[cache_key] = result
        return result

    def get_local_microhabitat_value(self, position: Tuple[int, int], kinds, radius: int = 4) -> float:
        if isinstance(kinds, str):
            normalized_kinds = (kinds,)
        else:
            normalized_kinds = tuple(sorted(kinds))
        cache_key = (self.tick_count, position[0], position[1], radius, normalized_kinds)
        cached = self._microhabitat_value_cache.get(cache_key)
        if cached is not None:
            return cached
        patches = self.get_microhabitat_patches(kinds=kinds, position=position, radius=radius)
        value = 0.0
        for patch in patches:
            dist = abs(patch.position[0] - position[0]) + abs(patch.position[1] - position[1])
            occupancy_penalty = max(0.35, 1.0 - patch.occupancy / max(0.1, patch.capacity))
            value += (patch.available * occupancy_penalty) / max(1.0, dist + 1.0)
        self._microhabitat_value_cache[cache_key] = value
        return value

    def consume_microhabitat(self, kinds, position: Tuple[int, int], amount: float, radius: int = 3) -> float:
        patches = self.get_microhabitat_patches(kinds=kinds, position=position, radius=radius)
        patches.sort(key=lambda patch: abs(patch.position[0] - position[0]) + abs(patch.position[1] - position[1]))
        remaining = amount
        consumed = 0.0
        for patch in patches:
            if remaining <= 0:
                break
            take = min(remaining, patch.available)
            patch.available -= take
            consumed += take
            remaining -= take
        if consumed > 0:
            self._microhabitat_value_cache = {}
        return consumed

    def occupy_microhabitat(self, species: str, kinds, position: Tuple[int, int], amount: float = 0.2, radius: int = 2) -> float:
        patches = self.get_microhabitat_patches(kinds=kinds, position=position, radius=radius)
        patches.sort(
            key=lambda patch: (
                -(patch.available - patch.occupancy),
                abs(patch.position[0] - position[0]) + abs(patch.position[1] - position[1]),
            )
        )
        occupied = 0.0
        for patch in patches:
            free_space = max(0.0, patch.capacity - patch.occupancy)
            if free_space <= 0:
                continue
            take = min(amount - occupied, free_space)
            patch.occupancy += take
            occupied += take
            if occupied >= amount:
                break
        if occupied > 0:
            self._microhabitat_value_cache = {}
        return occupied
    
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
        offsets = self._spatial_offset_cache.get(radius)
        if offsets is None:
            offsets = [(dx, dy) for dx in range(-radius, radius + 1) for dy in range(-radius, radius + 1)]
            self._spatial_offset_cache[radius] = offsets
        px, py = position
        nearby = []
        nearby_append = nearby.append
        get_bucket = index.get
        max_dist = range_
        abs_fn = abs
        for dx, dy in offsets:
            bucket = get_bucket((cell_x + dx, cell_y + dy))
            if not bucket:
                continue
            for entity in bucket:
                if not entity.alive:
                    continue
                ex, ey = entity.position
                if abs_fn(ex - px) + abs_fn(ey - py) <= max_dist:
                    nearby_append(entity)
        return nearby
    
    def _get_species_counts(self) -> Dict[str, int]:
        species_counts = {sp: 0 for sp in self.PLANT_SPECIES + self.ALL_ANIMAL_SPECIES + self.AQUATIC_SPECIES}
        species_counts.update(Counter(p.species for p in self.plants if p.alive))
        species_counts.update(Counter(a.species for a in self.animals if a.alive))
        species_counts.update(Counter(a.species for a in self.aquatic_creatures if a.alive))
        return species_counts

    def _compute_ecosystem_actors(self, species_counts: Dict[str, int]) -> Dict[str, float]:
        canopy_cover = (
            species_counts.get("tree", 0)
            + species_counts.get("apple_tree", 0)
            + species_counts.get("cherry_tree", 0)
            + species_counts.get("orange_tree", 0)
        )
        shrub_cover = (
            species_counts.get("bush", 0)
            + species_counts.get("berry", 0)
            + species_counts.get("blueberry", 0)
            + species_counts.get("strawberry", 0)
            + species_counts.get("grape_vine", 0)
        )
        bloom_abundance = (
            species_counts.get("flower", 0)
            + species_counts.get("berry", 0)
            + species_counts.get("blueberry", 0)
            + species_counts.get("strawberry", 0)
        )
        wetland_support = (
            species_counts.get("moss", 0)
            + species_counts.get("fern", 0)
            + species_counts.get("water_strider", 0)
            + species_counts.get("tadpole", 0)
        )
        aerial_insect_supply = (
            species_counts.get("insect", 0)
            + species_counts.get("night_moth", 0) * 0.8
            + species_counts.get("bee", 0)
            + species_counts.get("spider", 0) * 0.4
        )
        nocturnal_insect_supply = species_counts.get("night_moth", 0) + species_counts.get("insect", 0) * 0.35 + wetland_support * 0.35 + bloom_abundance * 0.15
        aquatic_mid_pressure = (
            species_counts.get("minnow", 0)
            + species_counts.get("small_fish", 0)
            + species_counts.get("carp", 0)
        )
        shoreline_hatch = species_counts.get("water_strider", 0) * 0.55 + species_counts.get("tadpole", 0) * 0.35 + wetland_support * 0.2
        return {
            "canopy_cover": canopy_cover,
            "shrub_cover": shrub_cover,
            "bloom_abundance": bloom_abundance,
            "wetland_support": wetland_support,
            "aerial_insect_supply": aerial_insect_supply,
            "nocturnal_insect_supply": nocturnal_insect_supply,
            "aquatic_mid_pressure": aquatic_mid_pressure,
            "shoreline_hatch": shoreline_hatch,
        }
    
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
        self._latest_species_counts = None
        self._latest_gender_counts = None
        self._latest_diet_counts = None
        self._nearby_plant_cache = {}
        self._nearby_creature_cache = {}
        self._nearby_aquatic_cache = {}
        self._microhabitat_patch_cache = {}
        self._microhabitat_value_cache = {}
        self._nearby_aquatic_count_cache = {}
        self._adjacent_water_score_cache = {}

    def _get_gender_counts(self) -> Dict[str, Dict[str, int]]:
        gender_counts: Dict[str, Dict[str, int]] = defaultdict(lambda: {"male": 0, "female": 0, "pregnant": 0})
        for creature in self.animals:
            if not creature.alive:
                continue
            stats = gender_counts[creature.species]
            gender = getattr(creature, "gender", None)
            if gender == Gender.MALE or gender == "male":
                stats["male"] += 1
            elif gender == Gender.FEMALE or gender == "female":
                stats["female"] += 1
            if getattr(creature, "pregnant", False):
                stats["pregnant"] += 1
        for creature in self.aquatic_creatures:
            if not creature.alive:
                continue
            gender = getattr(creature, "gender", None)
            if gender not in {"male", "female"} and not getattr(creature, "pregnant", False):
                continue
            stats = gender_counts[creature.species]
            if gender == "male":
                stats["male"] += 1
            elif gender == "female":
                stats["female"] += 1
            if getattr(creature, "pregnant", False):
                stats["pregnant"] += 1
        return gender_counts

    def _get_diet_counts(self) -> Dict[str, int]:
        counts = {"herbivore": 0, "carnivore": 0, "omnivore": 0}
        for creature in self.animals:
            if not creature.alive:
                continue
            diet = getattr(creature, "diet", None)
            if diet in counts:
                counts[diet] += 1
        return counts

    def _can_spawn_land_animal(self, species: str, position: Tuple[int, int]) -> bool:
        x, y = position
        if species in self.AMPHIBIOUS_SPECIES:
            return self.environment.is_land(x, y) or self.environment.is_water(x, y)
        return self.environment.is_land(x, y)

    def get_species_count(self, species: str) -> int:
        if self._latest_species_counts is None:
            self._latest_species_counts = self._get_species_counts()
        return self._latest_species_counts.get(species, 0)

    def get_gender_count(self, species: str, gender: str) -> int:
        if self._latest_gender_counts is None:
            self._latest_gender_counts = self._get_gender_counts()
        return self._latest_gender_counts.get(species, {}).get(gender, 0)

    def get_diet_count(self, diet: str) -> int:
        if self._latest_diet_counts is None:
            self._latest_diet_counts = self._get_diet_counts()
        return self._latest_diet_counts.get(diet, 0)

    def get_sustainable_population(self, species: str) -> int:
        """扣除保底种群后的可持续可捕食数量。"""
        reserve = self.PREY_RESERVE.get(species, 0)
        return max(0, self.get_species_count(species) - reserve)

    def get_predation_chance(self, predator_species: str, prey_species: str, hunger: float = 50.0) -> float:
        """根据猎物剩余量和捕食者数量动态限制捕食强度，防止食物链被打穿。"""
        species_counts = self._latest_species_counts or self._get_species_counts()
        prey_count = species_counts.get(prey_species, 0)
        predator_count = max(1, species_counts.get(predator_species, 0))
        reserve = self.PREY_RESERVE.get(prey_species, 2)
        if prey_count <= reserve:
            return 0.0

        surplus = prey_count - reserve
        appetite = self.PREDATOR_APPETITE.get(predator_species, 1.4)
        scarcity = surplus / max(1.0, predator_count * appetite)
        hunger_factor = max(0.75, min(1.3, hunger / 55.0 if hunger > 0 else 0.9))

        if scarcity < 0.2 and hunger < 65:
            return 0.0
        if scarcity < 0.35:
            return min(0.28, (0.10 + scarcity * 0.35) * hunger_factor)

        return max(0.18, min(0.98, (0.16 + min(1.0, scarcity) * 0.74) * hunger_factor))

    def _apply_population_pressure(self, species_counts: Dict[str, int]):
        """按营养级和关键物种数量给出生存/繁殖阻尼。"""
        land_prey_total = sum(species_counts.get(sp, 0) for sp in self.LAND_PREY)
        aquatic_producer_total = sum(species_counts.get(sp, 0) for sp in self.AQUATIC_PRODUCERS)
        aquatic_consumer_total = sum(species_counts.get(sp, 0) for sp in self.AQUATIC_CONSUMERS)
        actors = self._compute_ecosystem_actors(species_counts)

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
                elif count <= 8 and species_counts.get("grass", 0) + species_counts.get("bush", 0) > 40:
                    hunger_mult *= 0.88
                    reproduction_mult *= 1.32
            elif species == "mouse":
                if count > 24:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.84
                elif count <= 8 and species_counts.get("insect", 0) + species_counts.get("berry", 0) > 18:
                    hunger_mult *= 0.86
                    reproduction_mult *= 1.26
            elif species == "fox":
                if count <= 4 and land_prey_total > 35:
                    hunger_mult *= 0.88
                    reproduction_mult *= 1.28
                elif count > 8:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.76
            elif species == "wolf":
                if count <= 3 and species_counts.get("deer", 0) + species_counts.get("rabbit", 0) > 18:
                    hunger_mult *= 0.90
                    reproduction_mult *= 1.20
                elif count > 5:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.78
            elif species == "bird":
                if count <= 4 and species_counts.get("insect", 0) + species_counts.get("bee", 0) > 20:
                    hunger_mult *= 0.84
                    reproduction_mult *= 1.24
                elif count > 10:
                    hunger_mult *= 1.06
                    reproduction_mult *= 0.84
            elif species == "sparrow":
                if count <= 10 and species_counts.get("insect", 0) + species_counts.get("grass", 0) + species_counts.get("berry", 0) > 34:
                    hunger_mult *= 0.70
                    reproduction_mult *= 1.52
                elif count > 16:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.84
            elif species == "kingfisher":
                if count <= 2 and species_counts.get("small_fish", 0) + species_counts.get("minnow", 0) + species_counts.get("shrimp", 0) > 18:
                    hunger_mult *= 0.76
                    reproduction_mult *= 1.34
                if actors["shoreline_hatch"] >= 12:
                    hunger_mult *= 0.90
                    reproduction_mult *= 1.08
                elif count > 4:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.82
            elif species == "night_moth":
                if count > 180:
                    hunger_mult *= 1.14
                    reproduction_mult *= 0.46
                elif count > 120:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.62
                elif count <= 40 and actors["bloom_abundance"] >= 20 and actors["wetland_support"] >= 12:
                    hunger_mult *= 0.92
                    reproduction_mult *= 1.08
            elif species == "deer":
                if count <= 3 and species_counts.get("grass", 0) + species_counts.get("bush", 0) + species_counts.get("fern", 0) > 32:
                    hunger_mult *= 0.90
                    reproduction_mult *= 1.18
            elif species == "frog":
                if count <= 5 and species_counts.get("insect", 0) + species_counts.get("plankton", 0) > 32:
                    hunger_mult *= 0.80
                    reproduction_mult *= 1.36
                elif count > 14:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.84
                if actors["wetland_support"] >= 18:
                    hunger_mult *= 0.90
                    reproduction_mult *= 1.10
                if actors["shoreline_hatch"] >= 14:
                    hunger_mult *= 0.94
                if count > 20:
                    reproduction_mult *= 0.78
            elif species == "eagle":
                if count <= 2 and land_prey_total > 24:
                    hunger_mult *= 0.88
                    reproduction_mult *= 1.18
                elif count > 4:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.80
            elif species == "owl":
                if count <= 2 and species_counts.get("mouse", 0) + species_counts.get("bat", 0) + species_counts.get("bird", 0) + species_counts.get("sparrow", 0) + species_counts.get("night_moth", 0) > 18:
                    hunger_mult *= 0.82
                    reproduction_mult *= 1.24
                if count <= 2 and actors["canopy_cover"] >= 8:
                    hunger_mult *= 0.90
                    reproduction_mult *= 1.10
                if actors["nocturnal_insect_supply"] >= 14:
                    hunger_mult *= 0.92
                    reproduction_mult *= 1.06
                elif count > 4:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.80
            elif species == "hummingbird":
                if count <= 4 and species_counts.get("flower", 0) + species_counts.get("berry", 0) + species_counts.get("blueberry", 0) > 16:
                    hunger_mult *= 0.68
                    reproduction_mult *= 1.50
                if actors["bloom_abundance"] >= 12 and actors["shrub_cover"] >= 8:
                    hunger_mult *= 0.88
                    reproduction_mult *= 1.10
                if actors["bloom_abundance"] >= 18:
                    hunger_mult *= 0.92
            elif species == "woodpecker":
                if count <= 3 and species_counts.get("insect", 0) + species_counts.get("bee", 0) + species_counts.get("spider", 0) > 20:
                    hunger_mult *= 0.84
                    reproduction_mult *= 1.24
                if actors["canopy_cover"] >= 12:
                    hunger_mult *= 0.92
            elif species == "magpie":
                if count <= 4 and species_counts.get("insect", 0) + species_counts.get("mouse", 0) + species_counts.get("berry", 0) > 18:
                    hunger_mult *= 0.88
                    reproduction_mult *= 1.16
                if actors["canopy_cover"] >= 12 and actors["shrub_cover"] >= 8:
                    hunger_mult *= 0.94
            elif species == "crow":
                if count <= 3 and species_counts.get("insect", 0) + species_counts.get("mouse", 0) + species_counts.get("frog", 0) > 16:
                    hunger_mult *= 0.88
                    reproduction_mult *= 1.18
                if actors["canopy_cover"] >= 12:
                    hunger_mult *= 0.94
            elif species == "squirrel":
                if count <= 5 and species_counts.get("tree", 0) + species_counts.get("bush", 0) + species_counts.get("berry", 0) > 14:
                    hunger_mult *= 0.68
                    reproduction_mult *= 1.42
                if actors["canopy_cover"] >= 12:
                    hunger_mult *= 0.86
                    reproduction_mult *= 1.08
                if actors["canopy_cover"] >= 10 and actors["shrub_cover"] >= 8:
                    hunger_mult *= 0.90
                if actors["canopy_cover"] >= 18:
                    reproduction_mult *= 1.06
            elif species == "bat":
                if count <= 4 and species_counts.get("insect", 0) + species_counts.get("night_moth", 0) + species_counts.get("bee", 0) > 18:
                    hunger_mult *= 0.68
                    reproduction_mult *= 1.42
                if count <= 2 and actors["canopy_cover"] >= 8 and actors["nocturnal_insect_supply"] >= 10:
                    hunger_mult *= 0.78
                    reproduction_mult *= 1.18
                if actors["canopy_cover"] >= 10 and actors["nocturnal_insect_supply"] >= 14:
                    hunger_mult *= 0.86
                    reproduction_mult *= 1.12
                if actors["nocturnal_insect_supply"] >= 24:
                    hunger_mult *= 0.92
            elif species == "bear":
                if count <= 2 and land_prey_total > 28:
                    hunger_mult *= 0.90
                    reproduction_mult *= 1.10
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
                    reproduction_mult *= 1.32
                elif count > 28:
                    hunger_mult *= 1.22
                    reproduction_mult *= 0.50
                elif count > 18:
                    hunger_mult *= 1.18
                    reproduction_mult *= 0.62
                if actors["aquatic_mid_pressure"] > 36:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.82
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
                elif count > 9:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.78
                if species_counts.get("minnow", 0) + species_counts.get("small_fish", 0) < 6:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.90
            elif species == "pike":
                if count <= 2 and aquatic_consumer_total > 18:
                    hunger_mult *= 0.86
                    reproduction_mult *= 1.22
                elif count <= 4 and aquatic_consumer_total > 24:
                    hunger_mult *= 0.92
                    reproduction_mult *= 1.08
                elif count > 5:
                    hunger_mult *= 1.18
                    reproduction_mult *= 0.62
                if count > 18:
                    hunger_mult *= 1.12
                    reproduction_mult *= 0.48
                if species_counts.get("minnow", 0) < 4:
                    hunger_mult *= 1.10
                    reproduction_mult *= 0.88
            elif species == "catfish":
                if count <= 3 and aquatic_consumer_total > 18:
                    hunger_mult *= 0.94
                    reproduction_mult *= 1.10
                elif count <= 5 and aquatic_consumer_total > 24:
                    hunger_mult *= 0.94
                    reproduction_mult *= 1.04
                elif count > 4:
                    hunger_mult *= 1.20
                    reproduction_mult *= 0.58
                if count > 24:
                    hunger_mult *= 1.12
                    reproduction_mult *= 0.42
                if actors["aquatic_mid_pressure"] < 14:
                    hunger_mult *= 1.08
                    reproduction_mult *= 0.84
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
                elif count > 4:
                    hunger_mult *= 1.16
                    reproduction_mult *= 0.64

            return hunger_mult, reproduction_mult

        for collection in (self.plants, self.animals, self.aquatic_creatures):
            for entity in collection:
                if entity.alive and hasattr(entity, "apply_ecology_modifiers"):
                    hunger_mult, reproduction_mult = modifiers(entity.species)
                    entity.apply_ecology_modifiers(hunger_mult, reproduction_mult)

    def _maybe_recolonize_species(self, species_counts: Dict[str, int]):
        """关键控制物种的低密度自然迁入，避免生态链永久断裂。"""
        if self.tick_count < 24 or self.tick_count % 8 != 0:
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
                "species": "eagle",
                "domain": "land",
                "max_count": 1,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["bird", "sparrow", "rabbit", "duck"]) >= 14,
                "chance": 0.12,
                "position": self._random_edge_land_position,
                "message": "一只老鹰沿山脊与林缘迁入",
                "cooldown": 120,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_animals(pos, 10)
                    if a.species in {"bird", "sparrow", "rabbit", "duck"} and a.alive
                ]) >= 3,
            },
            {
                "species": "owl",
                "domain": "land",
                "max_count": 2,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["mouse", "bat", "bird", "sparrow", "night_moth"]) >= 14,
                "chance": 0.22,
                "position": self._random_edge_land_position,
                "message": "一只猫头鹰借林带夜间迁入",
                "cooldown": 84,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_animals(pos, 10)
                    if a.species in {"mouse", "bat", "bird", "sparrow", "night_moth"} and a.alive
                ]) >= 3 and self.get_local_microhabitat_value(pos, {"night_roost", "canopy_roost", "night_swarm"}, radius=6) >= 0.12,
            },
            {
                "species": "night_moth",
                "domain": "land",
                "max_count": 28,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["flower", "berry", "blueberry", "strawberry", "moss", "fern"]) >= 18,
                "chance": 0.62 if weather in {"sunny", "cloudy", "foggy"} else 0.46,
                "position": self._random_water_adjacent_position,
                "message": "一群夜飞蛾沿湿地和花丛边缘迁入",
                "cooldown": 14,
                "habitat_check": lambda pos: len([
                    p for p in self.get_nearby_plants(pos, 5)
                    if p.species in {"flower", "berry", "blueberry", "strawberry", "moss", "fern", "bush"} and p.alive
                ]) >= 4 and self.get_local_microhabitat_value(pos, {"night_swarm", "nectar_patch", "shrub_shelter"}, radius=5) >= 0.12,
            },
            {
                "species": "sparrow",
                "domain": "land",
                "max_count": 10,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["insect", "grass", "flower", "berry"]) >= 30,
                "chance": 0.65,
                "position": self._random_edge_land_position,
                "message": "一小群麻雀沿农田与林缘迁入",
                "cooldown": 20,
                "habitat_check": lambda pos: len([
                    p for p in self.get_nearby_plants(pos, 6)
                    if p.species in {"grass", "flower", "berry", "strawberry", "blueberry", "bush", "tree"} and p.alive
                ]) >= 4,
            },
            {
                "species": "kingfisher",
                "domain": "land",
                "max_count": 10,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["small_fish", "minnow", "shrimp", "tadpole", "water_strider"]) >= 18,
                "chance": 0.52 if weather in {"rainy", "stormy"} else 0.42,
                "position": self._random_water_adjacent_position,
                "message": "一只翠鸟沿溪岸与湖岸林带迁入",
                "cooldown": 24,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_aquatic(pos, 6)
                    if a.species in {"small_fish", "minnow", "shrimp", "tadpole", "water_strider"} and a.alive
                ]) >= 3 and len([
                    p for p in self.get_nearby_plants(pos, 5)
                    if p.species in {"bush", "tree", "berry", "apple_tree", "cherry_tree"} and p.alive
                ]) >= 2 and self.get_local_microhabitat_value(pos, {"riparian_perch", "shore_hatch"}, radius=5) >= 0.12,
            },
            {
                "species": "hummingbird",
                "domain": "land",
                "max_count": 18,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["flower", "berry", "blueberry", "strawberry"]) >= 18,
                "chance": 0.62,
                "position": self._random_edge_land_position,
                "message": "一只蜂鸟沿开花灌丛和林缘迁入",
                "cooldown": 22,
                "habitat_check": lambda pos: len([
                    p for p in self.get_nearby_plants(pos, 5)
                    if p.species in {"flower", "berry", "blueberry", "strawberry", "bush"} and p.alive
                ]) >= 4 and self.get_local_microhabitat_value(pos, {"nectar_patch", "shrub_shelter"}, radius=5) >= 0.10,
            },
            {
                "species": "squirrel",
                "domain": "land",
                "max_count": 16,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["tree", "bush", "berry", "mushroom"]) >= 18,
                "chance": 0.58,
                "position": self._random_edge_land_position,
                "message": "一只松鼠沿树林边缘迁入",
                "cooldown": 24,
                "habitat_check": lambda pos: len([
                    p for p in self.get_nearby_plants(pos, 5)
                    if p.species in {"tree", "bush", "berry", "apple_tree", "cherry_tree", "orange_tree"} and p.alive
                ]) >= 3 and self.get_local_microhabitat_value(pos, {"canopy_roost", "canopy_forage"}, radius=5) >= 0.10,
            },
            {
                "species": "bat",
                "domain": "land",
                "max_count": 14,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["insect", "night_moth", "bee", "spider"]) >= 24,
                "chance": 0.60,
                "position": self._random_edge_land_position,
                "message": "几只蝙蝠借夜色沿林带迁入",
                "cooldown": 20,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_animals(pos, 6)
                    if a.species in {"insect", "night_moth", "bee", "spider"} and a.alive
                ]) >= 4 and len([
                    p for p in self.get_nearby_plants(pos, 5)
                    if p.species in {"tree", "bush", "apple_tree", "cherry_tree"} and p.alive
                ]) >= 2 and self.get_local_microhabitat_value(pos, {"night_roost", "canopy_roost", "night_swarm"}, radius=5) >= 0.12,
            },
            {
                "species": "frog",
                "domain": "land",
                "max_count": 12,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["insect", "plankton", "water_strider"]) >= 24,
                "chance": 0.44 if weather in {"rainy", "stormy"} else 0.34,
                "position": self._random_water_adjacent_position,
                "message": "几只青蛙顺着湿地边缘回到水岸",
                "cooldown": 18,
                "habitat_check": lambda pos: len([
                    a for a in self.get_nearby_aquatic(pos, 5)
                    if a.species in {"plankton", "water_strider", "tadpole"} and a.alive
                ]) >= 2 and self.get_local_microhabitat_value(pos, {"wetland_patch", "riparian_perch", "shore_hatch"}, radius=5) >= 0.10,
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
                "max_count": 20,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["plankton", "algae", "water_strider"]) >= 48,
                "chance": 0.48 if weather in {"rainy", "stormy"} else 0.34,
                "position": lambda: self._random_inflow_water_position_for_body_type({"river_channel", "lake_shallow"}),
                "message": "一小群米诺鱼顺着河道和浅湖连通带迁入",
                "cooldown": 24,
                "habitat_check": lambda pos: self.environment.get_water_body_type(pos[0], pos[1]) in {"river_channel", "lake_shallow"} and len([
                    a for a in self.get_nearby_aquatic(pos, 6)
                    if a.species in {"plankton", "algae", "water_strider"} and a.alive
                ]) >= 3,
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
                "max_count": 2,
                "food_min": sum(species_counts.get(sp, 0) for sp in ["carp", "small_fish", "minnow", "frog"]) >= 20,
                "chance": 0.20 if weather in {"rainy", "stormy"} else 0.15,
                "position": lambda: self._random_inflow_water_position_for_body_type({"river_channel", "lake_shallow"}),
                "message": "一条狗鱼沿河道迁入了该水域",
                "cooldown": 72,
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
        self._latest_species_counts = species_counts
        self._apply_population_pressure(species_counts)
        
        # 获取生物数量用于环境更新
        plant_count = sum(1 for p in self.plants if p.alive)
        fish_count = sum(1 for a in self.aquatic_creatures if a.alive and a.species in self.FISH_SPECIES)
        
        # 更新环境
        self.environment.update(plant_count, fish_count)
        self._update_microhabitat_resources()
        
        # 记录上一轮的物种数量
        self.previous_counts = species_counts
        
        # 更新陆地植物
        for plant in self.plants:
            plant.update(self)
        self.plants = [p for p in self.plants if p.alive]
        self._rebuild_microhabitat_resources()
        
        # 更新陆地动物
        for animal in self.animals:
            animal.update(self)
        self.animals = [a for a in self.animals if a.alive]
        
        # 更新水生生物
        for aquatic in self.aquatic_creatures:
            aquatic.execute_behavior(self)
        self.aquatic_creatures = [a for a in self.aquatic_creatures if a.alive]
        self._rebuild_spatial_indices()

        current_counts = self._get_species_counts()
        self._latest_species_counts = current_counts
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
            "insect": Insect, "night_moth": NightMoth, "rabbit": Rabbit, "fox": Fox, "deer": Deer,
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
        if species in animal_classes and self._allow_spawn(species, current_count, "land", manual=manual) and self._can_spawn_land_animal(species, position):
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
        key = (self.tick_count, position[0], position[1], range_)
        cached = self._nearby_creature_cache.get(key)
        if cached is not None:
            return cached
        nearby = self._query_spatial_index(self._animal_index, position, range_)
        self._nearby_creature_cache[key] = nearby
        return nearby
        
    def get_nearby_plants(self, position: Tuple[int, int], range_: int) -> List[Plant]:
        """获取附近植物"""
        key = (self.tick_count, position[0], position[1], range_)
        cached = self._nearby_plant_cache.get(key)
        if cached is not None:
            return cached
        nearby = self._query_spatial_index(self._plant_index, position, range_)
        self._nearby_plant_cache[key] = nearby
        return nearby
        
    def get_nearby_animals(self, position: Tuple[int, int], range_: int) -> List[Animal]:
        """获取附近动物"""
        return self.get_nearby_creatures(position, range_)
    
    def get_nearby_aquatic(self, position: Tuple[int, int], range_: int) -> List[AquaticCreature]:
        """获取附近水生生物"""
        key = (self.tick_count, position[0], position[1], range_)
        cached = self._nearby_aquatic_cache.get(key)
        if cached is not None:
            return cached
        nearby = self._query_spatial_index(self._aquatic_index, position, range_)
        self._nearby_aquatic_cache[key] = nearby
        return nearby

    def count_nearby_aquatic_species(self, position: Tuple[int, int], range_: int, species_filter) -> Dict[str, int]:
        """按物种统计附近水生生物数量，避免先构造完整对象列表。"""
        if not species_filter:
            return {}
        if isinstance(species_filter, str):
            target_species = {species_filter}
        else:
            target_species = set(species_filter)
        if not target_species:
            return {}
        normalized_species = tuple(sorted(target_species))
        cache_key = (self.tick_count, position[0], position[1], range_, normalized_species)
        cached = self._nearby_aquatic_count_cache.get(cache_key)
        if cached is not None:
            return cached

        cell_x, cell_y = self._cell_for(position)
        radius = max(1, (range_ + self._spatial_cell_size - 1) // self._spatial_cell_size)
        offsets = self._spatial_offset_cache.get(radius)
        if offsets is None:
            offsets = [(dx, dy) for dx in range(-radius, radius + 1) for dy in range(-radius, radius + 1)]
            self._spatial_offset_cache[radius] = offsets

        px, py = position
        max_dist = range_
        counts: Dict[str, int] = defaultdict(int)
        get_bucket = self._aquatic_index.get
        abs_fn = abs

        for dx, dy in offsets:
            bucket = get_bucket((cell_x + dx, cell_y + dy))
            if not bucket:
                continue
            for entity in bucket:
                if not entity.alive or entity.species not in target_species:
                    continue
                ex, ey = entity.position
                if abs_fn(ex - px) + abs_fn(ey - py) <= max_dist:
                    counts[entity.species] += 1

        result = dict(counts)
        self._nearby_aquatic_count_cache[cache_key] = result
        return result

    def get_water_candidate_positions(self, position: Tuple[int, int], radius: int) -> List[Tuple[int, int]]:
        """缓存局部水域候选格，减少水生移动时的重复枚举。"""
        cache_key = (position[0], position[1], radius)
        cached = self._water_candidate_cache.get(cache_key)
        if cached is not None:
            return cached

        px, py = position
        positions: List[Tuple[int, int]] = []
        offsets = self._spatial_offset_cache.get(radius)
        if offsets is None:
            offsets = [(dx, dy) for dx in range(-radius, radius + 1) for dy in range(-radius, radius + 1)]
            self._spatial_offset_cache[radius] = offsets
        is_water = self.environment.is_water
        width = self.width
        height = self.height
        positions_append = positions.append
        for dx, dy in offsets:
            if dx == 0 and dy == 0:
                continue
            if abs(dx) + abs(dy) > radius + 1:
                continue
            x = max(0, min(px + dx, width - 1))
            y = max(0, min(py + dy, height - 1))
            if is_water(x, y):
                positions_append((x, y))
        positions.sort(key=lambda pos: abs(pos[0] - px) + abs(pos[1] - py))
        self._water_candidate_cache[cache_key] = positions[:8]
        return self._water_candidate_cache[cache_key]

    def get_adjacent_water_score(self, position: Tuple[int, int], radius: int = 1) -> float:
        """缓存局部邻接水域强度，供两栖边缘移动等高频逻辑复用。"""
        cache_key = (self.tick_count, position[0], position[1], radius)
        cached = self._adjacent_water_score_cache.get(cache_key)
        if cached is not None:
            return cached

        px, py = position
        score = 0.0
        is_water = self.environment.is_water
        width = self.width
        height = self.height
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                if dx == 0 and dy == 0:
                    continue
                tx, ty = px + dx, py + dy
                if 0 <= tx < width and 0 <= ty < height and is_water(tx, ty):
                    score += 1.2
        self._adjacent_water_score_cache[cache_key] = score
        return score
        
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
        raw_gender_stats = self._latest_gender_counts or self._get_gender_counts()
        self._latest_gender_counts = raw_gender_stats
        gender_stats = {
            species: {"males": stats["male"], "females": stats["female"], "pregnant": stats["pregnant"]}
            for species, stats in raw_gender_stats.items()
            if stats["male"] + stats["female"] > 0
        }
            
        env_summary = self.environment.get_environment_summary()
        actors = self._compute_ecosystem_actors(species_counts)
        microhabitat_summary = {}
        for patch in self.microhabitats:
            stats = microhabitat_summary.setdefault(patch.kind, {"capacity": 0.0, "available": 0.0, "occupancy": 0.0, "count": 0})
            stats["capacity"] += patch.capacity
            stats["available"] += patch.available
            stats["occupancy"] += patch.occupancy
            stats["count"] += 1
        microhabitat_summary = {
            kind: {
                "count": values["count"],
                "capacity": round(values["capacity"], 2),
                "available": round(values["available"], 2),
                "occupied": round(values["occupancy"], 2),
            }
            for kind, values in microhabitat_summary.items()
        }
        
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
            "ecosystem_health": self.balance.get_ecosystem_health({"species": species_counts, "tick": self.tick_count}),
            "alerts": [str(a) for a in self.active_alerts],
            "recommendations": self.balance.get_recommendations({"species": species_counts, "tick": self.tick_count}),
            "butterfly_events": [str(e) for e in self.balance.get_butterfly_events(5)],
            "grass_protection": self.balance.grass_protection_factor,
            "environment": env_summary,
            "actors": actors,
            "microhabitats": microhabitat_summary,
        }
        self._stats_cache_tick = self.tick_count
        return self._stats_cache

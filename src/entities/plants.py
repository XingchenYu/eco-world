"""
植物基类 - 带种子传播和发芽系统
"""

from typing import Tuple, List, Optional
import random
from ..core.creature import Creature, BehaviorState


def _get_plant_class_by_species(species: str):
    """Resolve plant classes lazily without self-imports."""
    class_name = {
        "grass": "Grass",
        "bush": "Bush",
        "flower": "Flower",
        "moss": "Moss",
        "tree": "Tree",
        "vine": "Vine",
        "cactus": "Cactus",
        "berry": "Berry",
        "mushroom": "Mushroom",
        "fern": "Fern",
        "apple_tree": "AppleTree",
        "cherry_tree": "CherryTree",
        "grape_vine": "GrapeVine",
        "strawberry": "Strawberry",
        "blueberry": "Blueberry",
        "orange_tree": "OrangeTree",
        "watermelon": "Watermelon",
    }.get(species)
    return globals().get(class_name)


class Seed:
    """种子类"""
    
    def __init__(self, species: str, position: Tuple[int, int], parent_plant):
        self.species = species
        self.position = list(position)
        self.parent = parent_plant
        self.age = 0
        self.germination_time = random.randint(5, 15)  # 发芽时间
        self.viability = 1.0  # 活力
        self.alive = True
        
    def update(self, ecosystem) -> Optional['Plant']:
        """更新种子状态，返回发芽后的植物"""
        if not self.alive:
            return None
            
        self.age += 1
        self.viability -= 0.01  # 活力随时间降低
        
        if self.viability <= 0:
            self.alive = False
            return None
            
        # 检查是否发芽
        if self.age >= self.germination_time:
            return self._germinate(ecosystem)
            
        return None
        
    def _germinate(self, ecosystem) -> Optional['Plant']:
        """发芽"""
        if ecosystem.environment.is_water(self.position[0], self.position[1]):
            self.alive = False
            return None
            
        # 创建幼苗
        plant_class = self._get_plant_class()
        if plant_class:
            plant = plant_class(tuple(self.position))
            plant.size = 0.3  # 幼苗较小
            plant.age = 0
            self.alive = False
            return plant
        return None
        
    def _get_plant_class(self):
        """获取植物类"""
        return _get_plant_class_by_species(self.species)


class Plant(Creature):
    """植物基类 - 带种子系统"""
    
    def __init__(
        self,
        species: str,
        position: Tuple[int, int],
        max_age: int = 100,
        growth_rate: float = 0.02,
        spread_radius: int = 3
    ):
        super().__init__(
            species=species,
            position=position,
            max_age=max_age,
            hunger_rate=0,
            reproduction_rate=growth_rate,
            speed=0,
            vision_range=0
        )
        self.growth_rate = growth_rate
        self.spread_radius = spread_radius
        self.size = 1.0
        self.nutrition_value = 20.0
        self._ecosystem_ref = None
        
        # 种子系统
        self.seeds: List[Seed] = []  # 已产生的种子
        self.seed_production_rate = 0.05  # 种子产生概率
        self.max_seeds = 5  # 最大种子数
        self.has_seeds = False  # 是否有种子
        self.seed_cooldown = 0  # 种子产生冷却
        
    def execute_behavior(self, ecosystem):
        """植物行为：生长 + 种子传播"""
        if not self.alive:
            return
            
        self._ecosystem_ref = ecosystem
        
        # 生长
        self.size = min(3.0, self.size + self.growth_rate)
        self.nutrition_value = self.size * 10

        # 轻量接入植物竞争：避免高密度植物无限叠加。
        PlantCompetition.compete_for_space(self, ecosystem)
        for other in ecosystem.get_nearby_plants(self.position, 2):
            if other.id == self.id or not other.alive:
                continue
            if self.size >= other.size:
                PlantCompetition.compete_for_light(self, other, ecosystem)
            PlantCompetition.compete_for_water(self, other, ecosystem)
        
        # 种子冷却
        if self.seed_cooldown > 0:
            self.seed_cooldown -= 1
            
        # 产生种子
        if self.can_produce_seeds() and random.random() < self.seed_production_rate:
            self.produce_seed(ecosystem)
            
        # 更新现有种子
        self._update_seeds(ecosystem)
            
    def can_produce_seeds(self) -> bool:
        """是否可以产生种子"""
        return (
            self.size >= 2.0 and
            self.age >= self.max_age * 0.3 and
            self.seed_cooldown == 0 and
            len(self.seeds) < self.max_seeds
        )
        
    def produce_seed(self, ecosystem) -> Optional[Seed]:
        """产生种子"""
        if not self.can_produce_seeds():
            return None
            
        # 种子落在植物附近
        dx = random.randint(-self.spread_radius, self.spread_radius)
        dy = random.randint(-self.spread_radius, self.spread_radius)
        
        seed_pos = (
            max(0, min(self.position[0] + dx, ecosystem.width - 1)),
            max(0, min(self.position[1] + dy, ecosystem.height - 1))
        )
        
        seed = Seed(self.species, seed_pos, self)
        self.seeds.append(seed)
        self.has_seeds = True
        self.seed_cooldown = 10
        
        ecosystem.balance.record_causal_event(
            cause=f"{self.species}产生种子",
            effect=f"{self.species}种子+1",
            impact=0.08,
            tick=ecosystem.tick_count
        )
        
        return seed
        
    def _update_seeds(self, ecosystem):
        """更新种子状态"""
        new_plants = []
        remaining_seeds = []
        
        for seed in self.seeds:
            plant = seed.update(ecosystem)
            if plant:
                new_plants.append(plant)
            elif seed.alive:
                remaining_seeds.append(seed)
                
        self.seeds = remaining_seeds
        self.has_seeds = len(self.seeds) > 0
        
        # 将发芽的植物添加到生态系统
        for plant in new_plants:
            ecosystem.add_plant_directly(plant)
            
    def spread(self, ecosystem):
        """旧式扩散（保留兼容）"""
        pass
        
    def can_reproduce(self) -> bool:
        return self.can_produce_seeds()
        
    def be_eaten(self, amount: float = 1.0) -> float:
        protection_factor = 1.0
        if self._ecosystem_ref:
            protection_factor = self._ecosystem_ref.balance.grass_protection_factor
            
        effective_amount = amount * protection_factor
        nutrition = min(self.nutrition_value, effective_amount * 10)
        self.size -= effective_amount
        self.health -= effective_amount * 30
        
        if self.size <= 0 or self.health <= 0:
            self.die()
            
        return nutrition


class Grass(Plant):
    """草 - 快速生长，风力传播种子"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="grass",
            position=position,
            max_age=100,
            growth_rate=0.03,
            spread_radius=2
        )
        self.emoji = "🌿"
        self.color = (34, 139, 34)
        self.seed_production_rate = 0.06  # 降低种子产生率
        
    def produce_seed(self, ecosystem) -> Optional[Seed]:
        """草的种子风力传播，带数量上限"""
        if not self.can_produce_seeds():
            return None
        
        # 🔄 添加上限控制：草数量不超过 300
        current_grass = len([g for g in ecosystem.plants if g.species == "grass" and g.alive])
        max_grass = 300
        
        if current_grass >= max_grass:
            return None  # 达到上限，不再产生种子
            
        # 风力传播，距离更远
        wind_direction = random.choice(['N', 'S', 'E', 'W'])
        wind_strength = random.randint(1, 4)
        
        dx, dy = 0, 0
        if wind_direction == 'N':
            dy = -wind_strength
        elif wind_direction == 'S':
            dy = wind_strength
        elif wind_direction == 'E':
            dx = wind_strength
        else:
            dx = -wind_strength
            
        seed_pos = (
            max(0, min(self.position[0] + dx, ecosystem.width - 1)),
            max(0, min(self.position[1] + dy, ecosystem.height - 1))
        )
        
        seed = Seed(self.species, seed_pos, self)
        self.seeds.append(seed)
        self.has_seeds = True
        self.seed_cooldown = 10
        
        return seed


class Bush(Plant):
    """灌木 - 生长慢，动物传播种子"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="bush",
            position=position,
            max_age=150,
            growth_rate=0.015,
            spread_radius=3
        )
        self.emoji = "🌳"
        self.color = (60, 100, 60)
        self.nutrition_value = 40
        self.provides_shelter = True
        self.seed_production_rate = 0.03  # 灌木产种慢
        
    def be_eaten(self, amount: float = 0.5) -> float:
        """被吃时可能传播种子（动物传播）"""
        nutrition = super().be_eaten(min(amount, 0.5))
        
        # 被吃时有几率传播种子
        if random.random() < 0.1 and self.has_seeds and self.seeds:
            # 选择一个种子传播到远处
            seed = random.choice(self.seeds)
            seed.position = [
                max(0, min(self.position[0] + random.randint(-5, 5), self._ecosystem_ref.width - 1 if self._ecosystem_ref else self.position[0])),
                max(0, min(self.position[1] + random.randint(-5, 5), self._ecosystem_ref.height - 1 if self._ecosystem_ref else self.position[1]))
            ]
            
        return nutrition


class Flower(Plant):
    """花 - 昆虫传播，需要传粉者"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="flower",
            position=position,
            max_age=50,
            growth_rate=0.04,
            spread_radius=1
        )
        self.emoji = "🌸"
        self.color = (255, 182, 193)
        self.nutrition_value = 5
        self.attracts_pollinators = True
        self.pollinated = False  # 是否被传粉
        self.seed_production_rate = 0.06
        
    def produce_seed(self, ecosystem) -> Optional[Seed]:
        """花需要被传粉才能产生种子"""
        if not self.can_produce_seeds():
            return None
            
        # 如果没有被传粉，不能产生种子
        if not self.pollinated:
            # 检查附近是否有蜜蜂帮助传粉
            nearby_bees = [a for a in ecosystem.animals if a.species == "bee"]
            for bee in nearby_bees:
                dist = abs(bee.position[0] - self.position[0]) + abs(bee.position[1] - self.position[1])
                if dist <= 3:
                    self.pollinated = True
                    break
                    
        if not self.pollinated:
            return None
            
        # 传粉成功，产生种子
        seed = super().produce_seed(ecosystem)
        if seed:
            self.pollinated = False  # 重置传粉状态
            
        return seed


class Moss(Plant):
    """苔藓 - 孢子传播，只在水边"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="moss",
            position=position,
            max_age=80,
            growth_rate=0.02,
            spread_radius=1
        )
        self.emoji = "🍀"
        self.color = (50, 120, 50)
        self.nutrition_value = 8
        self.seed_production_rate = 0.04
        
    def produce_seed(self, ecosystem) -> Optional[Seed]:
        """苔藓孢子传播，需要水边"""
        if not self.can_produce_seeds():
            return None
            
        # 检查是否在水边
        has_water = False
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                x = self.position[0] + dx
                y = self.position[1] + dy
                if 0 <= x < ecosystem.width and 0 <= y < ecosystem.height and ecosystem.environment.is_water(x, y):
                    has_water = True
                    break
                    
        if not has_water:
            return None
            
        return super().produce_seed(ecosystem)
        
    def execute_behavior(self, ecosystem):
        """苔藓冬季生长更快"""
        if ecosystem.environment.season == "winter":
            self.growth_rate = 0.03
            self.seed_production_rate = 0.06
        else:
            self.growth_rate = 0.02
            self.seed_production_rate = 0.04
        super().execute_behavior(ecosystem)


# ==================== 新增植物种类 ====================

class Tree(Plant):
    """大树 - 最高大，提供庇护所，生长最慢"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="tree",
            position=position,
            max_age=300,
            growth_rate=0.005,  # 生长最慢
            spread_radius=5
        )
        self.emoji = "🌲"
        self.color = (34, 100, 34)  # 深绿色
        self.size = 2.0  # 初始较大
        self.nutrition_value = 100
        self.provides_shelter = True
        self.canopy_size = 3  # 树冠大小
        self.seed_production_rate = 0.02
        
        # 竞争优势
        self.shade_tolerance = 0.9  # 耐阴性
        self.root_depth = 2  # 根系深度
        
    def provide_shade(self, ecosystem):
        """提供树荫，影响周围植物"""
        for dx in range(-self.canopy_size, self.canopy_size + 1):
            for dy in range(-self.canopy_size, self.canopy_size + 1):
                x, y = self.position[0] + dx, self.position[1] + dy
                if 0 <= x < ecosystem.width and 0 <= y < ecosystem.height:
                    # 树荫减少阳光
                    distance = abs(dx) + abs(dy)
                    shade_factor = max(0, 1.0 - distance * 0.2)
                    # 可以记录到环境影响
                    

class Vine(Plant):
    """藤蔓 - 攀援植物，需要支撑"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="vine",
            position=position,
            max_age=60,
            growth_rate=0.05,  # 生长快
            spread_radius=4
        )
        self.emoji = "🌿"
        self.color = (0, 128, 0)
        self.nutrition_value = 15
        self.seed_production_rate = 0.08
        self.climbing = False  # 是否正在攀爬
        self.host_plant = None  # 支撑植物
        
    def find_support(self, ecosystem):
        """寻找支撑物（树或灌木）"""
        nearby = ecosystem.get_nearby_plants(self.position, 3)
        for plant in nearby:
            if plant.species in ["tree", "bush"] and plant.size >= 1.5:
                self.climbing = True
                self.host_plant = plant
                return True
        self.climbing = False
        return False
        
    def execute_behavior(self, ecosystem):
        """藤蔓生长行为"""
        self.find_support(ecosystem)
        
        if self.climbing:
            # 攀爬时生长更快，营养更多
            self.growth_rate = 0.07
            self.nutrition_value = 25
        else:
            # 地面生长较慢
            self.growth_rate = 0.03
            self.nutrition_value = 10
            
        super().execute_behavior(ecosystem)


class Cactus(Plant):
    """仙人掌 - 耐旱，有刺防御"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="cactus",
            position=position,
            max_age=120,
            growth_rate=0.01,
            spread_radius=2
        )
        self.emoji = "🌵"
        self.color = (34, 139, 34)
        self.nutrition_value = 30
        self.has_spines = True  # 有刺防御
        self.water_storage = 50  # 水分储存
        self.seed_production_rate = 0.03
        
    def be_eaten(self, amount: float = 0.5) -> float:
        """有刺防御，被吃时伤害捕食者"""
        # 检查捕食者是否能吃带刺植物
        # 这里需要通过 ecosystem 传入捕食者信息
        # 简化处理：30%概率刺伤捕食者
        
        if random.random() < 0.3:
            # 刺伤捕食者，减少其健康
            # 这个信息需要通过某种方式传递
            pass
            
        return super().be_eaten(min(amount, 0.3))  # 刺也减少了被吃的量
        
    def execute_behavior(self, ecosystem):
        """仙人掌耐旱机制"""
        soil = ecosystem.environment.get_soil(self.position[0], self.position[1])
        drought = (
            ecosystem.environment.weather in {"sunny", "stormy"} and
            soil is not None and soil.moisture < 0.25
        )
        if drought:
            self.water_storage -= 1
            if self.water_storage > 0:
                self.growth_rate = 0.005  # 干旱时仍能生长
            else:
                self.health -= 5  # 水分耗尽，健康下降
        else:
            # 正常天气补充水分
            self.water_storage = min(50, self.water_storage + 2)
            
        super().execute_behavior(ecosystem)


class Berry(Plant):
    """浆果灌木 - 果实吸引动物"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="berry",
            position=position,
            max_age=80,
            growth_rate=0.02,
            spread_radius=3
        )
        self.emoji = "🫐"
        self.color = (75, 0, 130)  # 紫色
        self.nutrition_value = 50  # 营养价值高
        self.has_fruit = False
        self.fruit_count = 0
        self.seed_production_rate = 0.05
        
    def produce_fruit(self):
        """产生浆果"""
        if self.size >= 1.5 and self.age > 20:
            self.has_fruit = True
            self.fruit_count = random.randint(3, 8)
            
    def be_eaten(self, amount: float = 1.0) -> float:
        """浆果被吃，吸引动物传播种子"""
        if self.has_fruit and self.fruit_count > 0:
            self.fruit_count -= 1
            if self.fruit_count <= 0:
                self.has_fruit = False
            # 浆果营养更高
            return 60
            
        nutrition = super().be_eaten(amount)
        
        # 动物吃浆果时帮助传播种子
        if random.random() < 0.4:
            self.pollinated = True
            
        return nutrition
        
    def execute_behavior(self, ecosystem):
        """浆果灌木行为"""
        # 季节性结果
        if ecosystem.environment.season == "summer":
            self.produce_fruit()
            
        super().execute_behavior(ecosystem)


class Mushroom(Plant):
    """蘑菇 - 菌类，生长快，寿命短"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="mushroom",
            position=position,
            max_age=20,  # 寿命短
            growth_rate=0.1,  # 生长快
            spread_radius=2
        )
        self.emoji = "🍄"
        self.color = (139, 69, 19)
        self.nutrition_value = 25
        self.toxic = random.random() < 0.3  # 30%概率有毒
        self.seed_production_rate = 0.15
        
    def be_eaten(self, amount: float = 1.0) -> float:
        """蘑菇可能有毒"""
        if self.toxic:
            # 有毒蘑菇，返回负营养或特殊效果
            # 简化处理：返回0，捕食者可能生病
            return -10  # 负营养，表示有毒
        return super().be_eaten(amount)
        
    def execute_behavior(self, ecosystem):
        """蘑菇喜欢潮湿阴暗环境"""
        # 在树荫下或潮湿环境生长更快
        self.growth_rate = 0.1
        nearby_trees = [p for p in ecosystem.plants 
                       if p.species == "tree" and p.alive]
        for tree in nearby_trees:
            dist = abs(tree.position[0] - self.position[0]) + \
                   abs(tree.position[1] - self.position[1])
            if dist <= 3:
                self.growth_rate = 0.15  # 有树荫生长更快
                break
        super().execute_behavior(ecosystem)


class Fern(Plant):
    """蕨类 - 古老植物，喜阴湿"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="fern",
            position=position,
            max_age=100,
            growth_rate=0.025,
            spread_radius=2
        )
        self.emoji = "🌿"
        self.color = (0, 100, 0)
        self.nutrition_value = 15
        self.seed_production_rate = 0.04
        self.spore_production = 0.06  # 孢子繁殖
        
    def execute_behavior(self, ecosystem):
        """蕨类在潮湿环境生长更好"""
        if ecosystem.environment.weather == "rainy":
            self.growth_rate = 0.04
            self.spore_production = 0.1
        else:
            self.growth_rate = 0.025
            self.spore_production = 0.06
            
        super().execute_behavior(ecosystem)


# ==================== 果类植物 ====================

class AppleTree(Plant):
    """苹果树 - 大型果树，果实丰富"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="apple_tree",
            position=position,
            max_age=200,
            growth_rate=0.008,
            spread_radius=4
        )
        self.emoji = "🍎"
        self.color = (34, 139, 34)
        self.size = 2.5
        self.nutrition_value = 80
        self.provides_shelter = True
        self.has_fruit = False
        self.fruit_count = 0
        self.fruit_season = "autumn"
        self.seed_production_rate = 0.03
        
    def produce_fruit(self, ecosystem):
        if ecosystem.environment.season == self.fruit_season and self.size >= 2.0:
            self.has_fruit = True
            self.fruit_count = random.randint(10, 25)
            
    def be_eaten(self, amount: float = 1.0) -> float:
        if self.has_fruit and self.fruit_count > 0:
            self.fruit_count -= 1
            if self.fruit_count <= 0:
                self.has_fruit = False
            return 100
        return super().be_eaten(amount)
        
    def execute_behavior(self, ecosystem):
        self.produce_fruit(ecosystem)
        super().execute_behavior(ecosystem)


class CherryTree(Plant):
    """樱桃树 - 春季开花结果"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="cherry_tree",
            position=position,
            max_age=150,
            growth_rate=0.01,
            spread_radius=3
        )
        self.emoji = "🍒"
        self.color = (255, 182, 193)
        self.size = 1.8
        self.nutrition_value = 60
        self.has_fruit = False
        self.fruit_count = 0
        self.blooming = False
        self.seed_production_rate = 0.04
        
    def execute_behavior(self, ecosystem):
        if ecosystem.environment.season == "spring":
            self.blooming = True
            if self.size >= 1.5:
                self.has_fruit = True
                self.fruit_count = random.randint(15, 40)
        else:
            self.blooming = False
        super().execute_behavior(ecosystem)
        
    def be_eaten(self, amount: float = 1.0) -> float:
        if self.has_fruit and self.fruit_count > 0:
            self.fruit_count -= 1
            if self.fruit_count <= 0:
                self.has_fruit = False
            return 70
        return super().be_eaten(amount)


class GrapeVine(Plant):
    """葡萄藤 - 攀援果树"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="grape_vine",
            position=position,
            max_age=80,
            growth_rate=0.04,
            spread_radius=5
        )
        self.emoji = "🍇"
        self.color = (128, 0, 128)
        self.nutrition_value = 50
        self.has_fruit = False
        self.grape_clusters = 0
        self.climbing = False
        self.seed_production_rate = 0.06
        
    def find_support(self, ecosystem):
        nearby = ecosystem.get_nearby_plants(self.position, 3)
        for plant in nearby:
            if plant.species in ["tree", "apple_tree", "cherry_tree"] and plant.size >= 1.5:
                self.climbing = True
                return True
        self.climbing = False
        return False
        
    def execute_behavior(self, ecosystem):
        self.find_support(ecosystem)
        if self.climbing:
            self.growth_rate = 0.06
            if ecosystem.environment.season == "summer":
                self.has_fruit = True
                self.grape_clusters = random.randint(5, 15)
        else:
            self.growth_rate = 0.02
            self.has_fruit = False
        super().execute_behavior(ecosystem)
        
    def be_eaten(self, amount: float = 1.0) -> float:
        if self.has_fruit and self.grape_clusters > 0:
            self.grape_clusters -= 1
            if self.grape_clusters <= 0:
                self.has_fruit = False
            return 60
        return super().be_eaten(amount)


class Strawberry(Plant):
    """草莓 - 地面小型果实"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="strawberry",
            position=position,
            max_age=30,
            growth_rate=0.05,
            spread_radius=2
        )
        self.emoji = "🍓"
        self.color = (255, 0, 0)
        self.nutrition_value = 30
        self.has_fruit = False
        self.fruit_count = 0
        self.seed_production_rate = 0.12
        
    def execute_behavior(self, ecosystem):
        if ecosystem.environment.season in ["summer", "autumn"] and self.size >= 1.0:
            self.has_fruit = True
            self.fruit_count = random.randint(3, 10)
        else:
            self.has_fruit = False
        super().execute_behavior(ecosystem)
        
    def be_eaten(self, amount: float = 1.0) -> float:
        if self.has_fruit and self.fruit_count > 0:
            self.fruit_count -= 1
            return 40
        return super().be_eaten(amount)


class Blueberry(Plant):
    """蓝莓灌木 - 小型浆果"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="blueberry",
            position=position,
            max_age=60,
            growth_rate=0.03,
            spread_radius=2
        )
        self.emoji = "🫐"
        self.color = (0, 0, 139)
        self.nutrition_value = 45
        self.has_fruit = False
        self.fruit_count = 0
        self.seed_production_rate = 0.08
        
    def execute_behavior(self, ecosystem):
        if ecosystem.environment.season == "summer" and self.size >= 1.2:
            self.has_fruit = True
            self.fruit_count = random.randint(8, 20)
        else:
            self.has_fruit = False
        super().execute_behavior(ecosystem)
        
    def be_eaten(self, amount: float = 1.0) -> float:
        if self.has_fruit and self.fruit_count > 0:
            self.fruit_count -= 1
            if self.fruit_count <= 0:
                self.has_fruit = False
            return 50
        return super().be_eaten(amount)


class OrangeTree(Plant):
    """橙子树 - 冬季果实"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="orange_tree",
            position=position,
            max_age=180,
            growth_rate=0.009,
            spread_radius=4
        )
        self.emoji = "🍊"
        self.color = (255, 165, 0)
        self.size = 2.2
        self.nutrition_value = 70
        self.provides_shelter = True
        self.has_fruit = False
        self.fruit_count = 0
        self.seed_production_rate = 0.03
        
    def execute_behavior(self, ecosystem):
        if ecosystem.environment.season == "winter" and self.size >= 2.0:
            self.has_fruit = True
            self.fruit_count = random.randint(8, 18)
        else:
            self.has_fruit = False
        super().execute_behavior(ecosystem)
        
    def be_eaten(self, amount: float = 1.0) -> float:
        if self.has_fruit and self.fruit_count > 0:
            self.fruit_count -= 1
            if self.fruit_count <= 0:
                self.has_fruit = False
            return 80
        return super().be_eaten(amount)


class Watermelon(Plant):
    """西瓜 - 大型果实"""
    
    def __init__(self, position: Tuple[int, int]):
        super().__init__(
            species="watermelon",
            position=position,
            max_age=40,
            growth_rate=0.06,
            spread_radius=3
        )
        self.emoji = "🍉"
        self.color = (0, 128, 0)
        self.nutrition_value = 90
        self.has_fruit = False
        self.fruit_count = 0
        self.seed_production_rate = 0.05
        
    def execute_behavior(self, ecosystem):
        if ecosystem.environment.season == "summer" and self.size >= 1.5:
            self.has_fruit = True
            self.fruit_count = random.randint(1, 3)
        else:
            self.has_fruit = False
        super().execute_behavior(ecosystem)
        
    def be_eaten(self, amount: float = 1.0) -> float:
        if self.has_fruit and self.fruit_count > 0:
            self.fruit_count -= 1
            if self.fruit_count <= 0:
                self.has_fruit = False
            return 120
        return super().be_eaten(amount)


# ==================== 植物竞争机制 ====================

class PlantCompetition:
    """植物竞争 - 阳光、水分、空间"""
    
    @staticmethod
    def compete_for_light(taller_plant, shorter_plant, ecosystem):
        """
        光竞争：高植物遮挡低植物
        """
        distance = abs(taller_plant.position[0] - shorter_plant.position[0]) + \
                   abs(taller_plant.position[1] - shorter_plant.position[1])
        
        if distance <= 2:  # 距离足够近
            # 高植物影响低植物的生长
            shade_factor = taller_plant.size / max(1, shorter_plant.size)
            if shade_factor > 1.5:  # 显著遮挡
                shorter_plant.growth_rate *= 0.7  # 生长减慢
                shorter_plant.health -= 1  # 健康下降
                
    @staticmethod
    def compete_for_water(plant1, plant2, ecosystem):
        """
        水分竞争：根系竞争
        """
        # 检查是否有重叠的根系范围
        root_range1 = getattr(plant1, 'root_depth', 1)
        root_range2 = getattr(plant2, 'root_depth', 1)
        
        distance = abs(plant1.position[0] - plant2.position[0]) + \
                   abs(plant1.position[1] - plant2.position[1])
        
        if distance <= (root_range1 + root_range2):
            # 根系重叠，竞争水分
            if plant1.size > plant2.size:
                plant2.health -= 1
            else:
                plant1.health -= 1
                
    @staticmethod
    def compete_for_space(plant, ecosystem) -> bool:
        """
        空间竞争：检查是否有足够空间生长
        """
        nearby = ecosystem.get_nearby_plants(plant.position, 2)
        
        if len(nearby) > 5:  # 周围植物太多
            plant.growth_rate *= 0.8  # 生长受限
            return False
        return True

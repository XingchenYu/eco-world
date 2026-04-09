"""
动物基类 - 可移动的生物，带性别和繁殖系统
"""

from typing import Tuple, List, Optional
import random
from enum import Enum
from ..core.creature import Creature, BehaviorState
from .competition import Competition, Defense


class Gender(Enum):
    MALE = "male"
    FEMALE = "female"


class Animal(Creature):
    """动物基类 - 带性别和动态繁殖系统"""
    
    def __init__(
        self,
        species: str,
        position: Tuple[int, int],
        max_age: int,
        hunger_rate: float,
        reproduction_rate: float,
        speed: float = 2.0,
        vision_range: int = 5,
        diet: str = "herbivore",
        gender: Gender = None
    ):
        super().__init__(
            species=species,
            position=position,
            max_age=max_age,
            hunger_rate=hunger_rate,
            reproduction_rate=reproduction_rate,
            speed=speed,
            vision_range=vision_range
        )
        self.diet = diet
        self.emoji = "🐾"
        self.color = (139, 69, 19)
        
        # 性别系统
        self.gender = gender if gender else random.choice([Gender.MALE, Gender.FEMALE])
        
        # 繁殖系统
        self.can_mate = False
        self.mate_cooldown = 0
        self.pregnant = False
        self.pregnancy_timer = 0
        self.pregnancy_duration = 10
        self.mating_partner = None
        self.maturity_age = max_age * 0.15
        self.dominance = 1.0
        self.forms_groups = False
        self.has_camouflage = False
        self.camouflage_skill = 0.0
        self.can_counter_attack = False
        self.counter_strength = 0.0
        
        # 🔄 基于食物种群的动态繁殖
        self.food_population_factor = 1.0  # 食物种群因子
        self.last_prey_count = 0  # 上一次检查时的猎物数量
        self.check_interval = 0  # 检查间隔
        self._local_query_cache = {}
        self._predator_species_cache = None

    def _reset_local_query_cache(self):
        self._local_query_cache = {}

    def _cached_nearby_plants(self, ecosystem, range_: int):
        key = ("plants", self.position[0], self.position[1], range_)
        cached = self._local_query_cache.get(key)
        if cached is None:
            cached = ecosystem.get_nearby_plants(self.position, range_)
            self._local_query_cache[key] = cached
        return cached

    def _cached_nearby_animals(self, ecosystem, range_: int):
        key = ("animals", self.position[0], self.position[1], range_)
        cached = self._local_query_cache.get(key)
        if cached is None:
            cached = ecosystem.get_nearby_animals(self.position, range_)
            self._local_query_cache[key] = cached
        return cached

    def _cached_nearby_creatures(self, ecosystem, range_: int):
        key = ("creatures", self.position[0], self.position[1], range_)
        cached = self._local_query_cache.get(key)
        if cached is None:
            cached = ecosystem.get_nearby_creatures(self.position, range_)
            self._local_query_cache[key] = cached
        return cached

    def _cached_nearby_aquatic(self, ecosystem, range_: int):
        key = ("aquatic", self.position[0], self.position[1], range_)
        cached = self._local_query_cache.get(key)
        if cached is None:
            cached = ecosystem.get_nearby_aquatic(self.position, range_)
            self._local_query_cache[key] = cached
        return cached

    def _predator_species(self):
        if self._predator_species_cache is None:
            self._predator_species_cache = set(self.get_predators())
        return self._predator_species_cache

    def get_cover_plant_species(self) -> List[str]:
        return []

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def preferred_microhabitat_kinds(self) -> List[str]:
        kinds = []
        if self.prefers_canopy_cover():
            kinds.extend(["canopy_roost", "night_roost"])
        if self.prefers_shrub_cover():
            kinds.extend(["shrub_shelter", "nectar_patch"])
        if self.prefers_water_edge_cover():
            kinds.extend(["riparian_perch", "wetland_patch"])
        return kinds

    def breeding_microhabitat_kinds(self) -> List[str]:
        return self.preferred_microhabitat_kinds()

    def breeding_patch_threshold(self) -> float:
        if self.prefers_canopy_cover():
            return 0.28
        if self.prefers_shrub_cover() or self.prefers_water_edge_cover():
            return 0.22
        return 0.0

    def microhabitat_foraging_profile(self):
        return None

    def prefers_water_edge_cover(self) -> bool:
        return False

    def prefers_canopy_cover(self) -> bool:
        return False

    def prefers_shrub_cover(self) -> bool:
        return False

    def _cover_score(self, plant, ecosystem) -> float:
        score = 1.0
        if getattr(plant, "size", 1.0) >= 1.5:
            score += 0.3
        canopy_species = {"tree", "apple_tree", "cherry_tree", "orange_tree"}
        shrub_species = {"bush", "berry", "blueberry", "strawberry", "grape_vine"}
        if self.prefers_canopy_cover() and plant.species in canopy_species:
            score += 0.35
        if self.prefers_shrub_cover() and plant.species in shrub_species:
            score += 0.35
        if self.prefers_water_edge_cover():
            x, y = plant.position
            water_score = ecosystem.get_adjacent_water_score((x, y), radius=1) if hasattr(ecosystem, "get_adjacent_water_score") else 0.0
            if water_score > 0:
                score += 0.15
        distance = abs(plant.position[0] - self.position[0]) + abs(plant.position[1] - self.position[1])
        score -= distance * 0.04
        return score

    def seek_habitat(self, ecosystem, radius: Optional[int] = None) -> bool:
        microhabitat_kinds = self.preferred_microhabitat_kinds()
        if microhabitat_kinds and hasattr(ecosystem, "get_microhabitat_patches"):
            search_radius = radius or max(5, self.vision_range + 1)
            patches = ecosystem.get_microhabitat_patches(
                kinds=microhabitat_kinds,
                position=self.position,
                radius=search_radius,
            )
            patches = [
                patch for patch in patches
                if patch.available > 0.08 and patch.occupancy < patch.capacity * 0.95
            ]
            if patches:
                target_patch = max(
                    patches,
                    key=lambda patch: (patch.available - patch.occupancy) / max(
                        1,
                        abs(patch.position[0] - self.position[0]) + abs(patch.position[1] - self.position[1]),
                    ),
                )
                self.move_towards(target_patch.position, ecosystem)
                return True

        habitat_species = self.get_habitat_plant_species()
        if not habitat_species:
            return False
        search_radius = radius or max(5, self.vision_range + 1)
        nearby_plants = ecosystem.get_nearby_plants(self.position, search_radius)
        habitats = [
            plant for plant in nearby_plants
            if plant.alive and plant.species in habitat_species
        ]
        if not habitats:
            return False
        target = max(habitats, key=lambda plant: self._cover_score(plant, ecosystem))
        if self._cover_score(target, ecosystem) < 0.95:
            return False
        self.move_towards(target.position, ecosystem)
        return True

    def habitat_recovery_bonus(self, ecosystem) -> float:
        habitat_species = set(self.get_habitat_plant_species())
        bonus = 0.0
        matching = []
        if habitat_species:
            nearby_plants = self._cached_nearby_plants(ecosystem, max(3, self.vision_range // 2 + 1))
            matching = [plant for plant in nearby_plants if plant.alive and plant.species in habitat_species]
            bonus += min(0.18, len(matching) * 0.03)
        if self.prefers_canopy_cover():
            canopy_count = sum(1 for p in matching if p.species in {"tree", "apple_tree", "cherry_tree", "orange_tree"})
            bonus += min(0.12, canopy_count * 0.03)
            if hasattr(ecosystem, "get_local_microhabitat_value"):
                bonus += min(0.18, ecosystem.get_local_microhabitat_value(self.position, {"canopy_roost", "night_roost"}, radius=4) * 0.05)
        if self.prefers_shrub_cover():
            shrub_count = sum(1 for p in matching if p.species in {"bush", "berry", "blueberry", "strawberry", "grape_vine"})
            bonus += min(0.12, shrub_count * 0.03)
            if hasattr(ecosystem, "get_local_microhabitat_value"):
                bonus += min(0.16, ecosystem.get_local_microhabitat_value(self.position, {"shrub_shelter", "nectar_patch"}, radius=4) * 0.05)
        if self.prefers_water_edge_cover():
            water_edge_hits = 0
            for plant in matching:
                water_score = ecosystem.get_adjacent_water_score(plant.position, radius=1) if hasattr(ecosystem, "get_adjacent_water_score") else 0.0
                if water_score > 0:
                    water_edge_hits += 1
                if water_edge_hits >= 2:
                    break
            if water_edge_hits:
                bonus += min(0.10, water_edge_hits * 0.05)
            if hasattr(ecosystem, "get_local_microhabitat_value"):
                bonus += min(0.14, ecosystem.get_local_microhabitat_value(self.position, {"riparian_perch", "wetland_patch"}, radius=4) * 0.05)
        return min(0.28, bonus)

    def find_cover(self, ecosystem, radius: Optional[int] = None) -> bool:
        cover_species = self.get_cover_plant_species()
        if not cover_species:
            return False
        search_radius = radius or max(4, self.vision_range)
        nearby_plants = self._cached_nearby_plants(ecosystem, search_radius)
        shelter = [
            plant for plant in nearby_plants
            if plant.alive and plant.species in cover_species and getattr(plant, "provides_shelter", False)
        ]
        if not shelter:
            return False
        target = max(shelter, key=lambda plant: self._cover_score(plant, ecosystem))
        self.move_towards(target.position, ecosystem)
        return True
        
    def update_reproduction_from_food(self, ecosystem):
        """🔄 根据食物来源数量动态调整繁殖率"""
        self.check_interval += 1
        
        # 每5轮检查一次食物种群
        if self.check_interval < 5:
            return
            
        self.check_interval = 0
        species_counts = ecosystem._latest_species_counts if hasattr(ecosystem, "_latest_species_counts") and ecosystem._latest_species_counts else None

        def species_count(species: str) -> int:
            if species_counts is not None:
                return species_counts.get(species, 0)
            if hasattr(ecosystem, "get_species_count"):
                return ecosystem.get_species_count(species)
            return len([a for a in ecosystem.animals if a.species == species and a.alive])

        def diet_count(diet: str) -> int:
            if hasattr(ecosystem, "get_diet_count"):
                return ecosystem.get_diet_count(diet)
            return sum(1 for a in ecosystem.animals if hasattr(a, "diet") and a.diet == diet and a.alive)
        
        # 获取食物来源数量
        if self.diet == "herbivore":
            # 食草动物：检查植物数量
            if species_counts is not None and hasattr(ecosystem, "PLANT_SPECIES"):
                food_count = sum(species_counts.get(sp, 0) for sp in ecosystem.PLANT_SPECIES)
            else:
                food_count = len([p for p in ecosystem.plants if p.alive])
            # 理想食物数量（相对于自身数量）
            ideal_food = 3  # 每个食草动物需要3株植物
            animal_count = diet_count("herbivore")
            
        elif self.diet == "carnivore":
            # 捕食者：检查猎物数量
            prey_species = self.get_prey_species() if hasattr(self, 'get_prey_species') else []
            if hasattr(ecosystem, "get_sustainable_population"):
                food_count = sum(ecosystem.get_sustainable_population(sp) for sp in prey_species)
            else:
                food_count = sum(species_count(sp) for sp in prey_species)
            ideal_food = 2  # 每个捕食者需要2个猎物
            animal_count = diet_count("carnivore")
            
        else:  # omnivore
            # 杂食：综合计算
            if species_counts is not None and hasattr(ecosystem, "PLANT_SPECIES"):
                plant_count = sum(species_counts.get(sp, 0) for sp in ecosystem.PLANT_SPECIES)
            else:
                plant_count = len([p for p in ecosystem.plants if p.alive])
            prey_species = self.get_prey_species() if hasattr(self, 'get_prey_species') else []
            if hasattr(ecosystem, "get_sustainable_population"):
                prey_count = sum(ecosystem.get_sustainable_population(sp) for sp in prey_species)
            else:
                prey_count = sum(species_count(sp) for sp in prey_species)
            food_count = plant_count + prey_count * 2  # 猎物价值更高
            ideal_food = 4
            animal_count = diet_count("omnivore")
            
        # 计算食物充足度
        if animal_count > 0:
            food_per_animal = food_count / animal_count
            # 食物充足度 = 实际食物/理想食物，限制在0.1-1.5
            self.food_population_factor = max(0.1, min(1.5, food_per_animal / ideal_food))
        else:
            self.food_population_factor = 1.0
            
        # 更新动态繁殖率
        self.reproduction_rate = self.base_reproduction_rate * self.ecology_reproduction_multiplier * self.food_population_factor
        
        # 记录
        self.last_prey_count = food_count
        
    def execute_behavior(self, ecosystem):
        """动物行为逻辑 - 动态繁殖"""
        if not self.alive:
            return
        self.ecosystem = ecosystem
        self._reset_local_query_cache()

        habitat_bonus = self.habitat_recovery_bonus(ecosystem)
        if habitat_bonus > 0:
            self.hunger = max(0, self.hunger - habitat_bonus * 0.8)
            self.health = min(100, self.health + habitat_bonus * 0.5)
            if hasattr(ecosystem, "consume_microhabitat"):
                resource_kinds = set()
                if self.prefers_canopy_cover():
                    resource_kinds.update({"canopy_roost", "night_roost"})
                if self.prefers_shrub_cover():
                    resource_kinds.update({"shrub_shelter", "nectar_patch"})
                if self.prefers_water_edge_cover():
                    resource_kinds.update({"riparian_perch", "wetland_patch"})
                if resource_kinds:
                    if self.hunger >= 24 or self.health < 65:
                        ecosystem.consume_microhabitat(resource_kinds, self.position, min(0.08, habitat_bonus * 0.5), radius=3)
                    if hasattr(ecosystem, "occupy_microhabitat"):
                        ecosystem.occupy_microhabitat(self.species, resource_kinds, self.position, amount=min(0.10, habitat_bonus * 0.45 + 0.03), radius=2)

        resource_profile = self.microhabitat_foraging_profile()
        if resource_profile and hasattr(ecosystem, "consume_microhabitat"):
            min_hunger = resource_profile.get("min_hunger", 12.0)
            hour_window = resource_profile.get("hours")
            hour = getattr(ecosystem.environment, "hour", None)
            hour_ok = True
            if hour_window and hour is not None:
                start, end = hour_window
                hour_ok = (start <= hour < end) if start < end else (hour >= start or hour < end)
            if self.hunger >= min_hunger and hour_ok:
                consumed = ecosystem.consume_microhabitat(
                    resource_profile["kinds"],
                    self.position,
                    resource_profile.get("amount", 0.12),
                    radius=resource_profile.get("radius", 3),
                )
                if consumed > 0:
                    self.hunger = max(0, self.hunger - consumed * resource_profile.get("hunger_relief", 8.0))
                    self.health = min(100, self.health + consumed * resource_profile.get("health_gain", 1.5))
            
        # 更新繁殖状态
        self._update_reproduction_state()
        
        # 🔄 根据食物种群动态调整繁殖率
        self.update_reproduction_from_food(ecosystem)
            
        # 优先级：逃跑 > 觅食 > 求偶/繁殖 > 闲逛
        if self.check_danger(ecosystem):
            self.behavior_state = BehaviorState.ESCAPING
            self.escape(ecosystem)
        elif self.hunger > 40:  # 饥饿阈值提高，优先觅食
            self.behavior_state = BehaviorState.FORAGING
            self.forage(ecosystem)
        elif self._should_seek_mate():
            self.behavior_state = BehaviorState.MATING
            self.seek_mate(ecosystem)
        elif self.pregnant and self.pregnancy_timer >= self.pregnancy_duration:
            self._give_birth(ecosystem)
        else:
            self.behavior_state = BehaviorState.IDLE
            self.wander(ecosystem)
            
    def _update_reproduction_state(self):
        """更新繁殖状态"""
        # 冷却期递减
        if self.mate_cooldown > 0:
            self.mate_cooldown -= 1
            
        # 检查是否可以交配
        self.can_mate = (
            self.age >= self.maturity_age and
            self.health > 60 and
            self.hunger < 40 and
            self.mate_cooldown == 0
        )
        
        # 怀孕计时
        if self.pregnant:
            self.pregnancy_timer += 1
            
    def _should_seek_mate(self) -> bool:
        """是否应该寻找配偶"""
        ecosystem = getattr(self, "ecosystem", None)
        breeding_kinds = self.breeding_microhabitat_kinds()
        if ecosystem is not None and breeding_kinds and hasattr(ecosystem, "get_local_microhabitat_value"):
            patch_support = ecosystem.get_local_microhabitat_value(self.position, breeding_kinds, radius=4)
            if patch_support < self.breeding_patch_threshold():
                return False
        return (
            self.can_mate and
            not self.pregnant and
            self.gender == Gender.FEMALE  # 雌性主动寻找
        )
        
    def _can_mate_with(self, other: 'Animal') -> bool:
        """是否可以与另一只动物交配"""
        return (
            other.alive and
            other.species == self.species and
            other.gender == Gender.MALE and
            other.can_mate and
            other.mate_cooldown == 0
        )
        
    def seek_mate(self, ecosystem):
        """寻找配偶 - 放宽条件"""
        # 先检查视野内
        nearby = ecosystem.get_nearby_animals(self.position, self.vision_range)
        
        # 找同种雄性
        potential_mates = [a for a in nearby if self._can_mate_with(a)]
        
        if potential_mates:
            # 找最近的
            closest = min(potential_mates, key=lambda m:
                abs(m.position[0] - self.position[0]) + abs(m.position[1] - self.position[1]))
                
            self.move_towards(closest.position, ecosystem)
            
            # 到达后交配（放宽距离到2格）
            dist = abs(closest.position[0] - self.position[0]) + abs(closest.position[1] - self.position[1])
            if dist <= 2 and Competition.mating_competition(closest, self, ecosystem):
                self._mate_with(closest, ecosystem)
        else:
            # 视野内没有，检查整个地图是否有同类雄性
            all_males = [a for a in ecosystem.animals 
                        if a.species == self.species 
                        and a.gender == Gender.MALE 
                        and a.alive 
                        and a.can_mate]
            
            if all_males:
                # 向最近的雄性移动
                closest = min(all_males, key=lambda m:
                    abs(m.position[0] - self.position[0]) + abs(m.position[1] - self.position[1]))
                self.move_towards(closest.position, ecosystem)
            else:
                self.wander(ecosystem)
                
    def _mate_with(self, partner: 'Animal', ecosystem):
        """与配偶交配"""
        self.mating_partner = partner
        
        # 雌性怀孕
        if self.gender == Gender.FEMALE:
            self.pregnant = True
            self.pregnancy_timer = 0
            
        # 双方进入冷却期（缩短）
        self.mate_cooldown = 12
        partner.mate_cooldown = 12
        
        ecosystem.balance.record_causal_event(
            cause=f"{self.species}交配",
            effect=f"{self.species}可能繁殖",
            impact=0.15,
            tick=ecosystem.tick_count
        )
        
        ecosystem.log_event(f"{self.id} mated with {partner.id}")
        
    def _give_birth(self, ecosystem):
        """产仔 - 动态计算食物因子"""
        if not self.pregnant:
            return

        species_counts = ecosystem._latest_species_counts if hasattr(ecosystem, "_latest_species_counts") and ecosystem._latest_species_counts else None

        def species_count(species: str) -> int:
            if species_counts is not None:
                return species_counts.get(species, 0)
            if hasattr(ecosystem, "get_species_count"):
                return ecosystem.get_species_count(species)
            return len([a for a in ecosystem.animals if a.species == species and a.alive])

        def diet_count(diet: str) -> int:
            if hasattr(ecosystem, "get_diet_count"):
                return ecosystem.get_diet_count(diet)
            return sum(1 for a in ecosystem.animals if hasattr(a, "diet") and a.diet == diet and a.alive)
        
        # 🔄 计算食物因子
        if self.diet == "herbivore":
            # 食草动物：检查植物数量
            if species_counts is not None and hasattr(ecosystem, "PLANT_SPECIES"):
                food_count = sum(species_counts.get(sp, 0) for sp in ecosystem.PLANT_SPECIES)
            else:
                food_count = len([p for p in ecosystem.plants if p.alive])
            food_factor = max(0.2, min(1.5, food_count / max(1, diet_count("herbivore")) / 2))
        elif self.diet == "carnivore":
            # 捕食者：检查猎物数量
            prey_species = self.get_prey_species() if hasattr(self, 'get_prey_species') else []
            if hasattr(ecosystem, "get_sustainable_population"):
                food_count = sum(ecosystem.get_sustainable_population(sp) for sp in prey_species)
            else:
                food_count = sum(species_count(sp) for sp in prey_species)
            food_factor = max(0.1, min(1.5, food_count / max(1, diet_count("carnivore")) / 3))
        else:  # omnivore
            # 杂食动物
            if species_counts is not None and hasattr(ecosystem, "PLANT_SPECIES"):
                food_count = sum(species_counts.get(sp, 0) for sp in ecosystem.PLANT_SPECIES)
            else:
                food_count = len([p for p in ecosystem.plants if p.alive])
            food_factor = max(0.2, min(1.5, food_count / max(1, diet_count("omnivore")) / 2))
        
        # 🔄 计算天敌压力（食草动物）
        predator_pressure = 1.0
        if hasattr(self, 'get_predators'):
            predator_count = sum(species_count(sp) for sp in self.get_predators())
            predator_pressure = max(0.3, 1.0 - predator_count * 0.05)

        patch_factor = 1.0
        preferred_kinds = self.breeding_microhabitat_kinds()
        if preferred_kinds and hasattr(ecosystem, "get_local_microhabitat_value"):
            patch_value = ecosystem.get_local_microhabitat_value(self.position, preferred_kinds, radius=4)
            patch_factor = max(0.2, min(1.4, patch_value))
            if patch_value < self.breeding_patch_threshold():
                self.pregnant = False
                self.pregnancy_timer = 0
                self.mate_cooldown = max(self.mate_cooldown, 8)
                return
            
        # 产下后代（数量由环境决定）
        base_litter = random.randint(1, 3)
        litter_size = max(1, min(5, int(base_litter * food_factor * predator_pressure * patch_factor)))
        
        for _ in range(litter_size):
            offspring_pos = (
                self.position[0] + random.randint(-2, 2),
                self.position[1] + random.randint(-2, 2)
            )
            offspring_pos = (
                max(0, min(offspring_pos[0], ecosystem.width - 1)),
                max(0, min(offspring_pos[1], ecosystem.height - 1))
            )
            ecosystem.spawn_animal(self.species, offspring_pos, is_offspring=True)
            
        # 重置怀孕状态
        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 30  # 产后更长冷却期
        
        ecosystem.balance.record_causal_event(
            cause=f"{self.species}产仔",
            effect=f"{self.species}+{litter_size}",
            impact=0.2,
            tick=ecosystem.tick_count
        )
        
        ecosystem.log_event(f"{self.id} gave birth to {litter_size} offspring")
        
    def check_danger(self, ecosystem) -> bool:
        if self.diet == "carnivore":
            return False
        predators = self._predator_species()
        if not predators:
            return False
        nearby = self._cached_nearby_creatures(ecosystem, self.vision_range)
        for creature in nearby:
            if creature.species in predators:
                return True
        return False
        
    def get_predators(self) -> List[str]:
        return []
        
    def escape(self, ecosystem):
        predators_set = self._predator_species()
        if not predators_set:
            return
        nearby = self._cached_nearby_creatures(ecosystem, self.vision_range)
        predators = [c for c in nearby if c.species in predators_set]
        
        if predators:
            closest = min(predators, key=lambda p: 
                abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
            if hasattr(self, "defend_against_predator"):
                outcome = self.defend_against_predator(closest, ecosystem)
                if outcome in {"camouflaged", "group_defense", "escaped", "counter_attacked", "sprayed", "curled"}:
                    return
            elif Defense.group_defense(self, closest, ecosystem):
                return
            elif Defense.camouflage_check(self, ecosystem):
                return
            elif Defense.counter_attack(self, closest, ecosystem):
                return
            elif Defense.escape_behavior(self, closest, ecosystem):
                return
            
            dx = self.position[0] - closest.position[0]
            dy = self.position[1] - closest.position[1]
            target = (
                self.position[0] + int(dx * 2),
                self.position[1] + int(dy * 2)
            )
            self.move_towards(target, ecosystem)

        if getattr(self, 'can_hide', False):
            self.find_cover(ecosystem, radius=max(6, self.vision_range + 1))
            
    def forage(self, ecosystem):
        competition = Competition.food_competition(self, ecosystem)
        if not competition["won"] and random.random() > competition["food_available"]:
            self.wander(ecosystem)
            return

        if self.diet == "herbivore":
            self.find_plant(ecosystem)
        elif self.diet == "carnivore":
            self.find_prey(ecosystem)
        else:
            if random.random() < 0.7:
                self.find_plant(ecosystem)
            else:
                self.find_prey(ecosystem)
            
    def find_plant(self, ecosystem):
        nearby = self._cached_nearby_plants(ecosystem, self.vision_range)
        edible = [p for p in nearby if p.species in self.get_food_sources()]
        
        if edible:
            closest = min(edible, key=lambda p:
                abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                
            self.target = closest.position
            self.move_towards(self.target, ecosystem)
            
            dist = abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1])
            if dist <= 1:
                nutrition = closest.be_eaten()
                self.eat(nutrition)
                ecosystem.log_event(f"{self.id} ate {closest.id}")
                
                ecosystem.balance.record_causal_event(
                    cause=f"{self.species}进食",
                    effect=f"{closest.species}减少",
                    impact=-0.1,
                    tick=ecosystem.tick_count
                )
                
    def get_food_sources(self) -> List[str]:
        return ["grass"]
                
    def find_prey(self, ecosystem):
        nearby = self._cached_nearby_animals(ecosystem, self.vision_range)
        prey_species = self.get_prey_species()
        
        targets = [a for a in nearby if a.species in prey_species and a.alive]
        if hasattr(ecosystem, "get_nearby_aquatic"):
            aquatic_targets = self._cached_nearby_aquatic(ecosystem, self.vision_range)
            targets.extend(
                a for a in aquatic_targets
                if a.species in prey_species and a.alive
            )
        
        if targets:
            scored_targets = []
            for target in targets:
                dist = abs(target.position[0]-self.position[0]) + abs(target.position[1]-self.position[1])
                predation_chance = ecosystem.get_predation_chance(self.species, target.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if predation_chance <= 0.0:
                    continue
                scored_targets.append((predation_chance / max(1, dist), dist, predation_chance, target))
            if not scored_targets:
                self.wander(ecosystem)
                return
            _, _, predation_chance, closest = max(scored_targets, key=lambda item: item[0])
                
            self.target = closest.position
            self.move_towards(self.target, ecosystem)
            
            dist = abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1])
            if dist <= 1 and random.random() < predation_chance:
                self.hunt(closest, ecosystem)
                
    def get_prey_species(self) -> List[str]:
        return []
                
    def hunt(self, prey, ecosystem):
        if hasattr(ecosystem, "get_predation_chance"):
            chance = ecosystem.get_predation_chance(self.species, prey.species, self.hunger)
            if chance <= 0.0 or random.random() > chance:
                return
        prey.die()
        nutrition = 30.0
        self.eat(nutrition)
        ecosystem.log_event(f"{self.id} hunted {prey.id}")
        
        ecosystem.balance.record_causal_event(
            cause=f"{self.species}捕食{prey.species}",
            effect=f"{prey.species}数量-1",
            impact=-0.15,
            tick=ecosystem.tick_count
        )
        
    def can_reproduce(self) -> bool:
        """旧接口兼容"""
        return self.can_mate
        
    def try_mate(self, ecosystem):
        """旧接口兼容"""
        if self._should_seek_mate():
            self.seek_mate(ecosystem)
            
    def wander(self, ecosystem):
        if getattr(self, "can_hide", False) and random.random() < 0.4 and self.find_cover(ecosystem, radius=max(6, self.vision_range + 1)):
            return
        if getattr(self, "can_hide", False) and random.random() < 0.3 and self.seek_habitat(ecosystem, radius=max(6, self.vision_range + 2)):
            return
        if random.random() < 0.3:
            target = (
                self.position[0] + random.randint(-3, 3),
                self.position[1] + random.randint(-3, 3)
            )
            self.move_towards(target, ecosystem)


class Insect(Animal):
    """昆虫 - 数量多，食物链中层，多种天敌"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="insect",
            position=position,
            max_age=35,
            hunger_rate=0.35,
            reproduction_rate=0.25,
            speed=1.5,
            vision_range=3,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🐛"
        self.color = (107, 142, 35)
        self.pregnancy_duration = 4
        self.maturity_age = 3
        self.forms_groups = True
        
    def get_predators(self) -> List[str]:
        return ["fox", "bird", "snake", "sparrow", "owl", "frog", "spider"]  # 多种天敌
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "moss", "fern", "berry"]
    
    def _give_birth(self, ecosystem):
        """昆虫产卵 - 由食物和天敌控制"""
        # 计算食物充足度
        food_count = len([p for p in ecosystem.plants 
                         if p.species in self.get_food_sources() and p.alive])
        current_insect = len([i for i in ecosystem.animals if i.species == "insect" and i.alive])
        food_factor = max(0.2, min(1.5, food_count / (current_insect * 0.5)))
        
        # 计算天敌压力
        predator_count = sum(len([a for a in ecosystem.animals 
                                 if a.species == sp and a.alive]) 
                             for sp in self.get_predators())
        predator_pressure = max(0.1, 1.0 - predator_count * 0.03)
        
        # 🌱 自然繁殖：产卵数量多但受环境控制
        litter_size = max(1, min(8, int(food_factor * predator_pressure * 5)))
        for _ in range(litter_size):
            pos = (self.position[0] + random.randint(-2, 2),
                   self.position[1] + random.randint(-2, 2))
            pos = (max(0, min(pos[0], ecosystem.width - 1)),
                   max(0, min(pos[1], ecosystem.height - 1)))
            ecosystem.spawn_animal("insect", pos, is_offspring=True)
        
        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 4


class NightMoth(Animal):
    """夜间飞蛾 - 夜行飞虫，连接花源、湿地与夜行捕食链。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="night_moth",
            position=position,
            max_age=40,
            hunger_rate=0.25,
            reproduction_rate=0.22,
            speed=2.1,
            vision_range=4,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦋"
        self.color = (160, 150, 110)
        self.pregnancy_duration = 3
        self.maturity_age = 2
        self.is_nocturnal = True
        self.can_hide = True
        self.forms_groups = True

    def get_predators(self) -> List[str]:
        return ["bat", "owl", "spider", "bird"]

    def get_food_sources(self) -> List[str]:
        return ["flower", "berry", "blueberry", "strawberry", "moss", "fern"]

    def get_cover_plant_species(self) -> List[str]:
        return ["flower", "bush", "berry", "blueberry", "strawberry", "fern", "moss"]

    def prefers_shrub_cover(self) -> bool:
        return True

    def prefers_water_edge_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["night_swarm", "nectar_patch", "shrub_shelter"]

    def breeding_patch_threshold(self) -> float:
        return 0.12

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"night_swarm", "nectar_patch", "shrub_shelter"},
            "amount": 0.12,
            "radius": 3,
            "hunger_relief": 8.0,
            "health_gain": 1.0,
            "min_hunger": 8.0,
            "hours": (18, 6),
        }

    def execute_behavior(self, ecosystem):
        hour = ecosystem.environment.hour
        if 18 <= hour or hour < 6:
            self.speed = 2.4
            self.vision_range = 5
        else:
            self.speed = 1.0
            self.vision_range = 2
            if self.seek_habitat(ecosystem, radius=6):
                self.hunger = max(0, self.hunger - 0.35)
        super().execute_behavior(ecosystem)

    def _give_birth(self, ecosystem):
        hour = ecosystem.environment.hour
        if not (18 <= hour or hour < 6):
            self.pregnant = False
            self.pregnancy_timer = 0
            self.mate_cooldown = max(self.mate_cooldown, 4)
            return
        flower_supply = sum(
            1 for p in ecosystem.plants
            if p.species in self.get_food_sources() and p.alive
        )
        current_moths = ecosystem.get_species_count("night_moth") if hasattr(ecosystem, "get_species_count") else len([a for a in ecosystem.animals if a.species == "night_moth" and a.alive])
        food_factor = max(0.28, min(1.9, flower_supply / max(1, current_moths * 0.58)))
        patch_value = ecosystem.get_local_microhabitat_value(self.position, {"night_swarm", "nectar_patch"}, radius=4) if hasattr(ecosystem, "get_local_microhabitat_value") else 0.0
        patch_factor = max(0.58, min(1.6, 0.74 + patch_value * 0.40))
        if current_moths <= 12:
            food_factor = min(2.35, food_factor * 1.34)
            patch_factor = min(1.82, patch_factor * 1.20)
        elif current_moths <= 24:
            food_factor = min(2.12, food_factor * 1.20)
            patch_factor = min(1.72, patch_factor * 1.12)
        elif current_moths <= 40:
            food_factor = min(1.96, food_factor * 1.10)
            patch_factor = min(1.64, patch_factor * 1.06)
        predator_pressure = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([a for a in ecosystem.animals if a.species == sp and a.alive])
            for sp in ["bat", "owl", "bird", "frog", "spider", "kingfisher"]
        )
        predator_factor = max(0.60, 1.0 - predator_pressure * 0.010)
        season = getattr(ecosystem.environment, "season", "spring")
        season_factor = 1.0 if season in {"spring", "summer"} else 0.86 if season == "autumn" else 0.58
        litter_cap = 6 if current_moths <= 12 else 5 if current_moths <= 24 else 4 if current_moths <= 40 else 3
        litter_size = max(1, min(litter_cap, int(food_factor * patch_factor * predator_factor * season_factor * 2.95)))
        for _ in range(litter_size):
            pos = (
                max(0, min(self.position[0] + random.randint(-2, 2), ecosystem.width - 1)),
                max(0, min(self.position[1] + random.randint(-2, 2), ecosystem.height - 1)),
            )
            ecosystem.spawn_animal("night_moth", pos, is_offspring=True)

        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 3


class Rabbit(Animal):
    """兔子 - 食草，重要猎物，繁殖能力强"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="rabbit",
            position=position,
            max_age=50,
            hunger_rate=0.25,
            reproduction_rate=0.12,
            speed=2.8,
            vision_range=7,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🐰"
        self.color = (245, 245, 220)
        self.can_hide = True
        self.pregnancy_duration = 6
        self.forms_groups = True
        
    def get_predators(self) -> List[str]:
        return ["fox", "wolf", "snake", "eagle", "lion", "hyena"]  # 多种天敌
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "bush", "moss", "berry", "fern", "strawberry"]
    
    def _give_birth(self, ecosystem):
        """兔子产仔 - 由食物和天敌控制"""
        # 计算食物充足度
        food_count = len([p for p in ecosystem.plants 
                         if p.species in self.get_food_sources() and p.alive])
        current_rabbit = len([r for r in ecosystem.animals if r.species == "rabbit" and r.alive])
        food_factor = max(0.2, min(1.5, food_count / (current_rabbit * 2)))
        
        # 计算天敌压力
        predator_count = sum(len([a for a in ecosystem.animals 
                                 if a.species == sp and a.alive]) 
                             for sp in self.get_predators())
        predator_pressure = max(0.2, 1.0 - predator_count * 0.08)
        
        # 🌱 自然繁殖：无上限，产仔数量由环境决定
        litter_size = max(1, min(5, int(food_factor * predator_pressure * 4)))
        for _ in range(litter_size):
            offspring_pos = (
                self.position[0] + random.randint(-2, 2),
                self.position[1] + random.randint(-2, 2)
            )
            offspring_pos = (
                max(0, min(offspring_pos[0], ecosystem.width - 1)),
                max(0, min(offspring_pos[1], ecosystem.height - 1))
            )
            ecosystem.spawn_animal(self.species, offspring_pos, is_offspring=True)
                
        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 8  # 短冷却期


class Fox(Animal):
    """狐狸 - 捕食者，控制兔子/昆虫数量"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="fox",
            position=position,
            max_age=70,
            hunger_rate=0.32,
            reproduction_rate=0.045,
            speed=3.2,
            vision_range=8,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🦊"
        self.color = (255, 140, 0)
        self.pregnancy_duration = 12
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "rabbit", "mouse", "bird", "snake", "frog", "duck"]
    
    def _give_birth(self, ecosystem):
        """狐狸产仔 - 由猎物数量控制"""
        if hasattr(ecosystem, "get_sustainable_population"):
            prey_count = sum(ecosystem.get_sustainable_population(sp) for sp in self.get_prey_species())
        else:
            prey_count = sum(len([a for a in ecosystem.animals if a.species == sp and a.alive]) 
                            for sp in self.get_prey_species())
        current_fox = len([f for f in ecosystem.animals if f.species == "fox" and f.alive])
        
        # 猎物充足度
        food_factor = max(0.1, min(1.5, prey_count / (current_fox * 4)))
        recovery_boost = 1.35 if current_fox <= 4 else 1.0
        
        # 🌱 自然繁殖：猎物充足时才产仔
        if prey_count > max(4, current_fox * (2 if current_fox <= 4 else 3)):
            litter_size = max(1, min(3, int(food_factor * recovery_boost * 2)))
            for _ in range(litter_size):
                offspring_pos = (
                    self.position[0] + random.randint(-2, 2),
                    self.position[1] + random.randint(-2, 2)
                )
                offspring_pos = (
                    max(0, min(offspring_pos[0], ecosystem.width - 1)),
                    max(0, min(offspring_pos[1], ecosystem.height - 1))
                )
                ecosystem.spawn_animal(self.species, offspring_pos, is_offspring=True)
                
        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 20
    
    def hunt(self, prey, ecosystem):
        """狐狸捕食 - 有保护机制"""
        prey_species = prey.species
        prey_count = len([a for a in ecosystem.animals if a.species == prey_species and a.alive])
        predation_chance = ecosystem.get_predation_chance(self.species, prey_species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
        if predation_chance <= 0.0:
            return
        
        # 如果猎物太少就不捕食
        min_threshold = {"rabbit": 10, "mouse": 8, "insect": 20, "bird": 5}
        threshold = min_threshold.get(prey_species, 5)
        
        if prey_count < threshold and random.random() < 0.55:
            return
        if random.random() > min(0.92, predation_chance):
            return
            
        prey.die()
        nutrition = {
            "rabbit": 35,
            "mouse": 16,
            "insect": 8,
            "bird": 20,
            "sparrow": 16,
            "snake": 22,
            "frog": 14,
            "duck": 24,
        }.get(prey_species, 20)
        self.eat(nutrition)
        
        ecosystem.balance.record_causal_event(
            cause=f"{self.species}捕食{prey.species}",
            effect=f"{prey.species}数量-1",
            impact=-0.15,
            tick=ecosystem.tick_count
        )


class Deer(Animal):
    """鹿 - 食草/灌木，体型大，狼的天敌"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="deer",
            position=position,
            max_age=120,
            hunger_rate=0.25,
            reproduction_rate=0.04,
            speed=2.5,
            vision_range=8,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦌"
        self.color = (139, 90, 43)
        self.pregnancy_duration = 20
        
    def get_predators(self) -> List[str]:
        return ["wolf", "lion", "hyena"]  # 大型犬科与猫科是鹿的主要天敌
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "bush", "moss", "flower", "berry", "fern"]
    
    def _give_birth(self, ecosystem):
        """鹿产仔 - 由食物和天敌控制数量"""
        # 计算食物充足度
        grass_count = len([p for p in ecosystem.plants 
                          if p.species in self.get_food_sources() and p.alive])
        current_deer = len([d for d in ecosystem.animals if d.species == "deer" and d.alive])
        food_factor = max(0.2, min(1.5, grass_count / (current_deer * 3)))
        
        # 计算天敌压力
        wolf_count = len([w for w in ecosystem.animals if w.species == "wolf" and w.alive])
        predator_pressure = max(0.2, 1.0 - wolf_count * 0.1)
        
        # 产仔数量由环境决定
        litter_size = max(1, min(2, int(food_factor * predator_pressure)))
        for _ in range(litter_size):
            offspring_pos = (
                self.position[0] + random.randint(-2, 2),
                self.position[1] + random.randint(-2, 2)
            )
            offspring_pos = (
                max(0, min(offspring_pos[0], ecosystem.width - 1)),
                max(0, min(offspring_pos[1], ecosystem.height - 1))
            )
            ecosystem.spawn_animal(self.species, offspring_pos, is_offspring=True)
                
        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 35


class Antelope(Animal):
    """羚羊 - 草原群居中型食草动物。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="antelope",
            position=position,
            max_age=95,
            hunger_rate=0.23,
            reproduction_rate=0.055,
            speed=3.2,
            vision_range=9,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦌"
        self.color = (182, 136, 74)
        self.pregnancy_duration = 14
        self.forms_groups = True
        self.herd_channel_bias = 0.0
        self.herd_source_bias = 0.0
        self.route_cycle_bias = 0.0
        self.prosperity_phase_bias = 0.0
        self.collapse_phase_bias = 0.0
        self.surface_water_anchor = 0.0
        self.runtime_anchor_prosperity = 0.0
        self.regional_prosperity = 0.0
        self.regional_collapse_risk = 0.0
        self.regional_stability = 0.0

    def get_predators(self) -> List[str]:
        return ["lion", "hyena", "wolf", "crocodile"]

    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "bush", "berry", "fern"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "berry", "moss", "fern"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_shrub_cover(self) -> bool:
        return True

    def prefers_water_edge_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["shrub_shelter", "riparian_perch"]

    def breeding_patch_threshold(self) -> float:
        return 0.10

    def execute_behavior(self, ecosystem):
        super().execute_behavior(ecosystem)
        if not self.alive:
            return
        self._follow_herd_channel(ecosystem)

    def _follow_herd_channel(self, ecosystem):
        bias = max(
            self.herd_channel_bias,
            self.herd_source_bias * 0.7,
            self.route_cycle_bias * 0.9,
            self.prosperity_phase_bias * 0.85,
            self.surface_water_anchor * 0.95,
            self.runtime_anchor_prosperity * 0.60,
            self.regional_prosperity * 0.55,
            self.regional_stability * 0.40,
        )
        collapse_drag = self.collapse_phase_bias * 0.12 + self.regional_collapse_risk * 0.08
        if bias <= 0.0:
            return
        if self.hunger < max(28, 45 - self.prosperity_phase_bias * 12 + self.collapse_phase_bias * 6) and self.seek_habitat(ecosystem, radius=self.vision_range + 2):
            return
        if hasattr(ecosystem, "_random_water_adjacent_position") and random.random() < max(0.06, min(0.55, 0.18 + bias * 0.20 - collapse_drag)):
            target = ecosystem._random_water_adjacent_position()
            if target:
                self.move_towards(target, ecosystem)


class Zebra(Animal):
    """斑马 - 草原大型群居食草动物。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="zebra",
            position=position,
            max_age=105,
            hunger_rate=0.24,
            reproduction_rate=0.045,
            speed=3.0,
            vision_range=9,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦓"
        self.color = (210, 210, 210)
        self.pregnancy_duration = 16
        self.forms_groups = True
        self.herd_channel_bias = 0.0
        self.herd_source_bias = 0.0
        self.route_cycle_bias = 0.0
        self.prosperity_phase_bias = 0.0
        self.collapse_phase_bias = 0.0
        self.surface_water_anchor = 0.0
        self.runtime_anchor_prosperity = 0.0
        self.regional_prosperity = 0.0
        self.regional_collapse_risk = 0.0
        self.regional_stability = 0.0

    def get_predators(self) -> List[str]:
        return ["lion", "hyena", "crocodile"]

    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "bush", "berry", "fern"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "berry", "moss", "fern"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_shrub_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["shrub_shelter"]

    def breeding_patch_threshold(self) -> float:
        return 0.08

    def execute_behavior(self, ecosystem):
        super().execute_behavior(ecosystem)
        if not self.alive:
            return
        self._follow_herd_channel(ecosystem)

    def _follow_herd_channel(self, ecosystem):
        bias = max(
            self.herd_channel_bias,
            self.herd_source_bias * 0.7,
            self.route_cycle_bias * 0.9,
            self.prosperity_phase_bias * 0.85,
            self.surface_water_anchor * 0.95,
            self.runtime_anchor_prosperity * 0.60,
            self.regional_prosperity * 0.55,
            self.regional_stability * 0.40,
        )
        collapse_drag = self.collapse_phase_bias * 0.12 + self.regional_collapse_risk * 0.08
        if bias <= 0.0:
            return
        if self.hunger < max(30, 48 - self.prosperity_phase_bias * 12 + self.collapse_phase_bias * 6) and self.seek_habitat(ecosystem, radius=self.vision_range + 2):
            return
        if hasattr(ecosystem, "_random_water_adjacent_position") and random.random() < max(0.06, min(0.50, 0.16 + bias * 0.18 - collapse_drag)):
            target = ecosystem._random_water_adjacent_position()
            if target:
                self.move_towards(target, ecosystem)


class Wolf(Animal):
    """狼 - 顶级捕食者，控制鹿的数量"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="wolf",
            position=position,
            max_age=100,
            hunger_rate=0.28,
            reproduction_rate=0.03,
            speed=3.5,  # 比鹿快
            vision_range=12,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🐺"
        self.color = (105, 105, 105)  # 灰色
        self.pregnancy_duration = 18
        
    def get_predators(self) -> List[str]:
        return []  # 狼是顶级捕食者
        
    def get_prey_species(self) -> List[str]:
        return ["deer", "rabbit", "mouse", "fox", "raccoon_dog"]  # 狼捕食大型草食和中小型动物
        
    def hunt(self, prey, ecosystem):
        """狼群捕食策略"""
        prey_species = prey.species
        prey_count = len([a for a in ecosystem.animals if a.species == prey_species and a.alive])
        current_wolf = len([w for w in ecosystem.animals if w.species == "wolf" and w.alive])
        predation_chance = ecosystem.get_predation_chance(self.species, prey_species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
        if predation_chance <= 0.0:
            return
        
        # 如果猎物太少就不捕食（保护机制）
        min_threshold = {"deer": 20, "rabbit": 15, "mouse": 10}
        threshold = min_threshold.get(prey_species, 5)
        
        if prey_count < threshold and random.random() < 0.3:
            return  # 放弃捕食
        if random.random() > min(0.95, predation_chance):
            return  # 放弃捕食
            
        # 正常捕食
        prey.die()
        nutrition = {"deer": 80, "rabbit": 30, "mouse": 15}.get(prey_species, 25)
        self.eat(nutrition)
        
        ecosystem.balance.record_causal_event(
            cause=f"狼捕食{prey.species}",
            effect=f"{prey.species}数量-1",
            impact=-0.2,
            tick=ecosystem.tick_count
        )
        
    def _give_birth(self, ecosystem):
        """狼产仔 - 由猎物数量控制"""
        if hasattr(ecosystem, "get_sustainable_population"):
            prey_count = sum(ecosystem.get_sustainable_population(sp) for sp in self.get_prey_species())
        else:
            prey_count = sum(len([a for a in ecosystem.animals if a.species == sp and a.alive]) 
                            for sp in self.get_prey_species())
        current_wolf = len([w for w in ecosystem.animals if w.species == "wolf" and w.alive])
        
        # 猎物充足度
        food_factor = max(0.1, min(1.5, prey_count / (current_wolf * 5)))
        
        # 猎物充足时才产仔
        if prey_count > current_wolf * 4:
            litter_size = max(1, min(3, int(food_factor * 2)))
            for _ in range(litter_size):
                offspring_pos = (
                    self.position[0] + random.randint(-2, 2),
                    self.position[1] + random.randint(-2, 2)
                )
                offspring_pos = (
                    max(0, min(offspring_pos[0], ecosystem.width - 1)),
                    max(0, min(offspring_pos[1], ecosystem.height - 1))
                )
                ecosystem.spawn_animal(self.species, offspring_pos, is_offspring=True)
                
        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 30


class Mouse(Animal):
    """老鼠 - 食草/昆虫，繁殖极快"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="mouse",
            position=position,
            max_age=40,
            hunger_rate=0.31,
            reproduction_rate=0.23,
            speed=1.8,
            vision_range=4,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐭"
        self.color = (150, 120, 90)
        self.pregnancy_duration = 4
        self.can_hide = True
        self.forms_groups = True
        
    def get_predators(self) -> List[str]:
        return ["fox", "snake", "bird"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "moss", "berry", "mushroom", "strawberry"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "bee", "spider"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "berry", "blueberry", "strawberry", "mushroom", "fern"]

    def prefers_shrub_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["shrub_shelter", "nectar_patch"]

    def breeding_patch_threshold(self) -> float:
        return 0.08

    def _give_birth(self, ecosystem):
        food_count = sum(
            1 for p in ecosystem.plants
            if p.alive and p.species in self.get_food_sources()
        )
        insect_supply = (
            ecosystem.get_species_count("insect")
            + ecosystem.get_species_count("spider")
        ) if hasattr(ecosystem, "get_species_count") else len([
            a for a in ecosystem.animals if a.alive and a.species in {"insect", "spider"}
        ])
        current_mouse = ecosystem.get_species_count("mouse") if hasattr(ecosystem, "get_species_count") else len([
            a for a in ecosystem.animals if a.alive and a.species == "mouse"
        ])
        predator_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([
                a for a in ecosystem.animals if a.alive and a.species == sp
            ])
            for sp in self.get_predators()
        )

        food_factor = max(0.40, min(1.85, (food_count + insect_supply * 1.2) / max(1, current_mouse * 4.0)))
        predator_factor = max(0.55, 1.0 - predator_count * 0.010)
        if current_mouse <= 10:
            food_factor = min(2.0, food_factor * 1.25)
            predator_factor = min(1.08, predator_factor * 1.06)

        litter_size = max(1, min(4, int(food_factor * predator_factor * 2.2)))
        for _ in range(litter_size):
            offspring_pos = (
                max(0, min(self.position[0] + random.randint(-2, 2), ecosystem.width - 1)),
                max(0, min(self.position[1] + random.randint(-2, 2), ecosystem.height - 1))
            )
            ecosystem.spawn_animal("mouse", offspring_pos, is_offspring=True)

        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 6


class Bird(Animal):
    """鸟 - 食昆虫，移动快"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="bird",
            position=position,
            max_age=50,
            hunger_rate=0.28,
            reproduction_rate=0.06,
            speed=4.0,
            vision_range=12,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🐦"
        self.color = (100, 150, 200)
        self.pregnancy_duration = 10
        self.can_hide = True
        self.forms_groups = True
        
    def get_predators(self) -> List[str]:
        return ["fox"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "bee", "spider", "water_strider"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "bush", "apple_tree", "cherry_tree", "orange_tree", "grape_vine"]

    def prefers_canopy_cover(self) -> bool:
        return True
        
    def escape(self, ecosystem):
        self.speed = 5.0
        super().escape(ecosystem)
        self.speed = 4.0


class Snake(Animal):
    """蛇 - 食鼠/昆虫，伏击型"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="snake",
            position=position,
            max_age=70,
            hunger_rate=0.3,
            reproduction_rate=0.05,
            speed=2.0,
            vision_range=5,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🐍"
        self.color = (80, 100, 80)
        self.pregnancy_duration = 12
        
    def get_predators(self) -> List[str]:
        return ["fox"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "rabbit", "frog"]
        
    def execute_behavior(self, ecosystem):
        """蛇伏击模式"""
        if not self.alive:
            return
            
        self.age += 1
        self.hunger += self.hunger_rate
        
        if self.hunger > 50:
            self.health -= (self.hunger - 50) * 0.1
            
        if self.health <= 0 or self.age >= self.max_age:
            self.die()
            return
            
        self._update_reproduction_state()
            
        if self.hunger > 40:
            self.behavior_state = BehaviorState.FORAGING
            self.forage(ecosystem)
        elif self._should_seek_mate():
            self.behavior_state = BehaviorState.MATING
            self.seek_mate(ecosystem)
        elif self.pregnant and self.pregnancy_timer >= self.pregnancy_duration:
            self._give_birth(ecosystem)
        else:
            if random.random() < 0.1:
                self.wander(ecosystem)


class Bee(Animal):
    """蜜蜂 - 食花，帮助传粉"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="bee",
            position=position,
            max_age=25,
            hunger_rate=0.6,
            reproduction_rate=0.1,
            speed=3.0,
            vision_range=6,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🐝"
        self.color = (255, 200, 0)
        self.pregnancy_duration = 3
        
    def get_predators(self) -> List[str]:
        return []
        
    def get_food_sources(self) -> List[str]:
        return ["flower", "berry", "blueberry", "strawberry"]
        
    def find_plant(self, ecosystem):
        """蜜蜂优先找花，帮助传粉"""
        nearby = ecosystem.get_nearby_plants(self.position, self.vision_range)
        flowers = [p for p in nearby if p.species == "flower"]
        
        if flowers:
            closest = min(flowers, key=lambda p:
                abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                
            self.move_towards(closest.position, ecosystem)
            
            dist = abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1])
            if dist <= 1:
                nutrition = closest.be_eaten(0.3)
                self.eat(nutrition)
                
                # 帮助传粉
                if random.random() < 0.3:
                    ecosystem.balance.record_causal_event(
                        cause="蜜蜂传粉",
                        effect="花朵可能产生种子",
                        impact=0.05,
                        tick=ecosystem.tick_count
                    )
                    # 触发花朵产生种子
                    if hasattr(closest, 'produce_seed'):
                        closest.produce_seed(ecosystem)
        else:
            super().find_plant(ecosystem)


# ==================== 扩展鸟类 ====================

class Eagle(Animal):
    """老鹰 - 顶级空中捕食者，可以抓兔子、老鼠、蛇、鹿幼崽"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="eagle",
            position=position,
            max_age=100,
            hunger_rate=0.25,
            reproduction_rate=0.02,
            speed=5.0,  # 飞行最快
            vision_range=15,  # 视野最大
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🦅"
        self.color = (101, 67, 33)  # 深褐色
        self.pregnancy_duration = 25
        self.hunting_altitude = 0  # 飞行高度
        
    def get_predators(self) -> List[str]:
        return []  # 老鹰没有天敌
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "rabbit", "snake", "bird", "duck", "frog", "small_fish"]  # 以中小型陆地/水边猎物为主
        
    def hunt(self, prey, ecosystem):
        """老鹰俯冲捕食"""
        if hasattr(ecosystem, "get_predation_chance"):
            chance = ecosystem.get_predation_chance(self.species, prey.species, self.hunger)
            if chance <= 0.0 or random.random() > min(0.95, chance * 0.95):
                return
        prey.die()
        nutrition = 50.0  # 老鹰捕食获得更多营养
        self.eat(nutrition)
        ecosystem.log_event(f"{self.id} hunted {prey.id}")
        ecosystem.balance.record_causal_event(
            cause=f"老鹰捕食{prey.species}",
            effect=f"{prey.species}数量-1",
            impact=-0.2,
            tick=ecosystem.tick_count
        )
        
    def escape(self, ecosystem):
        """老鹰不逃跑，直接飞走"""
        self.wander(ecosystem)


class Vulture(Animal):
    """秃鹫 - 空中清道夫，围绕尸体和热气流柱活动。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="vulture",
            position=position,
            max_age=90,
            hunger_rate=0.22,
            reproduction_rate=0.028,
            speed=4.6,
            vision_range=16,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🦅"
        self.color = (120, 95, 72)
        self.pregnancy_duration = 18
        self.forms_groups = True
        self.aerial_lane_bias = 0.0
        self.kill_corridor_bias = 0.0
        self.carrion_cycle_bias = 0.0
        self.prosperity_phase_bias = 0.0
        self.collapse_phase_bias = 0.0
        self.carcass_anchor = 0.0
        self.runtime_anchor_prosperity = 0.0
        self.regional_prosperity = 0.0
        self.regional_collapse_risk = 0.0
        self.regional_stability = 0.0

    def get_predators(self) -> List[str]:
        return []

    def get_prey_species(self) -> List[str]:
        return ["rabbit", "night_moth", "frog"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "apple_tree", "cherry_tree", "orange_tree", "bush"]

    def prefers_canopy_cover(self) -> bool:
        return True

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"thermal_column", "open_grazing_range"},
            "amount": 0.08,
            "radius": 4,
            "hunger_relief": 5.5,
            "health_gain": 0.8,
            "min_hunger": 20.0,
        }

    def forage(self, ecosystem):
        if hasattr(ecosystem, "get_local_microhabitat_value"):
            carrion_window = ecosystem.get_local_microhabitat_value(self.position, {"open_grazing_range", "thermal_column"}, radius=5)
            if carrion_window > 0.25 and self.hunger >= 18:
                self.eat(10 + carrion_window * 10)
                if hasattr(ecosystem, "log_event") and random.random() < 0.15:
                    ecosystem.log_event(f"{self.id} circled over a carrion site")

    def execute_behavior(self, ecosystem):
        super().execute_behavior(ecosystem)
        if not self.alive:
            return
        self._track_aerial_lanes(ecosystem)

    def _track_aerial_lanes(self, ecosystem):
        bias = max(
            self.aerial_lane_bias,
            self.kill_corridor_bias * 0.8,
            self.carrion_cycle_bias * 0.92,
            self.prosperity_phase_bias * 0.9,
            self.carcass_anchor * 0.95,
            self.runtime_anchor_prosperity * 0.58,
            self.regional_prosperity * 0.52,
            self.regional_stability * 0.36,
        )
        collapse_drag = self.collapse_phase_bias * 0.10 + self.regional_collapse_risk * 0.07
        if bias <= 0.0:
            return
        if hasattr(ecosystem, "get_microhabitat_patches"):
            patches = ecosystem.get_microhabitat_patches({"thermal_column", "open_grazing_range"}, self.position, radius=self.vision_range)
            patches = [patch for patch in patches if patch.available > 0.05]
            if patches and random.random() < max(0.08, min(0.62, 0.22 + bias * 0.24 - collapse_drag)):
                target = max(
                    patches,
                    key=lambda patch: patch.available / max(
                        1,
                        abs(patch.position[0] - self.position[0]) + abs(patch.position[1] - self.position[1]),
                    ),
                )
                self.move_towards(target.position, ecosystem)
                return
        super().forage(ecosystem)

    def escape(self, ecosystem):
        self.wander(ecosystem)


class Owl(Animal):
    """猫头鹰 - 夜间捕食者，夜视能力强"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="owl",
            position=position,
            max_age=72,
            hunger_rate=0.18,
            reproduction_rate=0.07,
            speed=3.5,
            vision_range=10,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🦉"
        self.color = (102, 51, 0)  # 深棕色
        self.pregnancy_duration = 10
        self.is_nocturnal = True  # 夜行性
        
    def get_predators(self) -> List[str]:
        return ["eagle"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "night_moth", "mouse", "bat", "water_strider", "frog"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "apple_tree", "cherry_tree", "orange_tree"]

    def prefers_canopy_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["night_roost", "canopy_roost"]

    def breeding_patch_threshold(self) -> float:
        return 0.10

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"night_roost", "canopy_roost", "night_swarm"},
            "amount": 0.10,
            "radius": 3,
            "hunger_relief": 7.0,
            "health_gain": 1.0,
            "min_hunger": 16.0,
            "hours": (6, 18),
        }

    def forage(self, ecosystem):
        hour = ecosystem.environment.hour
        if 18 <= hour or hour < 6:
            nearby = self._cached_nearby_creatures(ecosystem, self.vision_range)
            preferred = []
            for creature in nearby:
                if not creature.alive or creature.species not in {"night_moth", "mouse", "bat", "frog", "sparrow", "bird"}:
                    continue
                chance = ecosystem.get_predation_chance(self.species, creature.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if chance <= 0.0:
                    continue
                dist = abs(creature.position[0] - self.position[0]) + abs(creature.position[1] - self.position[1])
                night_bonus = 0.05 if creature.species == "night_moth" else 0.0
                preferred.append((dist, min(0.82, chance + night_bonus), creature))
            if preferred:
                _, attack_chance, target = min(preferred, key=lambda item: item[0])
                self.move_towards(target.position, ecosystem)
                dist = abs(target.position[0] - self.position[0]) + abs(target.position[1] - self.position[1])
                if dist <= 1 and random.random() < attack_chance:
                    self.hunt(target, ecosystem)
                    return
        super().forage(ecosystem)
        
    def execute_behavior(self, ecosystem):
        """猫头鹰夜间活动增强"""
        # 夜间（18:00-06:00）更活跃
        hour = ecosystem.environment.hour
        if 18 <= hour or hour < 6:
            self.speed = 4.0
            self.vision_range = 12
        else:
            self.speed = 2.0
            self.vision_range = 6
            if self.seek_habitat(ecosystem, radius=7):
                self.hunger = max(0, self.hunger - 0.6)
                self.health = min(100, self.health + 0.25)
            
        super().execute_behavior(ecosystem)


class Duck(Animal):
    """鸭子 - 水鸟，可以在陆地和水上活动"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="duck",
            position=position,
            max_age=40,
            hunger_rate=0.35,
            reproduction_rate=0.1,
            speed=2.5,
            vision_range=6,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🦆"
        self.color = (255, 255, 0)  # 黄色
        self.pregnancy_duration = 10
        self.can_swim = True
        
    def get_predators(self) -> List[str]:
        return ["fox", "eagle", "large_fish"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "moss", "berry", "strawberry"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "small_fish", "plankton", "algae", "shrimp", "water_strider", "tadpole"]
        
    def forage(self, ecosystem):
        """鸭子水陆两栖觅食"""
        # 检查是否在水中
        if ecosystem.environment.is_water(self.position[0], self.position[1]):
            # 在水中吃小鱼、浮游生物
            aquatic_prey = ecosystem.get_nearby_aquatic(self.position, 4)
            aquatic_prey = [
                a for a in aquatic_prey
                if a.species in ["small_fish", "plankton", "shrimp", "water_strider", "tadpole"] and a.alive
            ]
            if aquatic_prey:
                closest = min(aquatic_prey, key=lambda a:
                    abs(a.position[0]-self.position[0]) + abs(a.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                    if hasattr(closest, "size"):
                        closest.size -= 0.4
                        if closest.size <= 0:
                            closest.die()
                    else:
                        closest.die()
                    self.eat(18)
                    return
        # 在陆地吃昆虫
        super().forage(ecosystem)
        
    def move_towards(self, target, ecosystem):
        """鸭子可以游泳"""
        if target is None:
            return
        dx = target[0] - self.position[0]
        dy = target[1] - self.position[1]
        steps = min(self.speed, max(abs(dx), abs(dy)))
        if steps == 0:
            return
        move_x = int(dx / max(abs(dx), 1) * min(steps, abs(dx)))
        move_y = int(dy / max(abs(dy), 1) * min(steps, abs(dy)))
        new_x = max(0, min(self.position[0] + move_x, ecosystem.width - 1))
        new_y = max(0, min(self.position[1] + move_y, ecosystem.height - 1))
        self.position = (new_x, new_y)
        if hasattr(ecosystem, "refresh_spatial_entity"):
            ecosystem.refresh_spatial_entity(self)


class Swan(Animal):
    """天鹅 - 优雅的水鸟"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="swan",
            position=position,
            max_age=50,
            hunger_rate=0.3,
            reproduction_rate=0.05,
            speed=2.0,
            vision_range=7,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦢"
        self.color = (255, 255, 255)  # 白色
        self.pregnancy_duration = 12
        self.can_swim = True
        
    def get_predators(self) -> List[str]:
        return ["fox", "eagle"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "seaweed", "algae", "moss", "berry"]
        
    def forage(self, ecosystem):
        """天鹅主要在水中觅食"""
        if ecosystem.environment.is_water(self.position[0], self.position[1]):
            # 吃水生植物
            aquatic_food = ecosystem.get_nearby_aquatic(self.position, 4)
            aquatic_food = [
                a for a in aquatic_food
                if a.species in ["algae", "seaweed", "plankton"] and a.alive
            ]
            if aquatic_food:
                closest = min(aquatic_food, key=lambda a:
                    abs(a.position[0]-self.position[0]) + abs(a.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                    if hasattr(closest, 'size'):
                        closest.size -= 0.5
                        if closest.size <= 0:
                            closest.die()
                    else:
                        closest.die()
                    self.eat(15)
        else:
            super().forage(ecosystem)


class Sparrow(Animal):
    """麻雀 - 小型鸟，数量多"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="sparrow",
            position=position,
            max_age=40,
            hunger_rate=0.18,
            reproduction_rate=0.22,  # 繁殖快
            speed=4.2,
            vision_range=8,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐦"
        self.color = (139, 119, 101)  # 棕灰色
        self.pregnancy_duration = 5
        self.forms_groups = True
        self.can_hide = True
        
    def get_predators(self) -> List[str]:
        return ["snake", "eagle", "owl"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "moss", "berry", "strawberry", "blueberry", "grape_vine"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "bee", "spider"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "tree", "berry", "apple_tree", "cherry_tree", "blueberry", "grape_vine"]

    def prefers_shrub_cover(self) -> bool:
        return True

    def execute_behavior(self, ecosystem):
        if not self.alive:
            return
        self._update_reproduction_state()
        self.update_reproduction_from_food(ecosystem)
        close_predators = [
            creature for creature in ecosystem.get_nearby_creatures(self.position, 4)
            if creature.alive and creature.species in self.get_predators()
        ]
        if close_predators and self.hunger < 40:
            self.behavior_state = BehaviorState.ESCAPING
            self.escape(ecosystem)
        elif self.hunger > 18:
            self.behavior_state = BehaviorState.FORAGING
            self.forage(ecosystem)
        elif self.check_danger(ecosystem):
            self.behavior_state = BehaviorState.ESCAPING
            self.escape(ecosystem)
        elif self._should_seek_mate():
            self.behavior_state = BehaviorState.MATING
            self.seek_mate(ecosystem)
        elif self.pregnant and self.pregnancy_timer >= self.pregnancy_duration:
            self._give_birth(ecosystem)
        else:
            self.behavior_state = BehaviorState.IDLE
            self.wander(ecosystem)

    def forage(self, ecosystem):
        if self.check_danger(ecosystem) and self.find_cover(ecosystem, radius=8):
            return
        insects = [
            a for a in ecosystem.get_nearby_animals(self.position, 5)
            if a.alive and a.species in {"insect", "bee", "spider"}
        ]
        if insects:
            closest_insect = min(insects, key=lambda a: abs(a.position[0]-self.position[0]) + abs(a.position[1]-self.position[1]))
            self.move_towards(closest_insect.position, ecosystem)
            dist = abs(closest_insect.position[0]-self.position[0]) + abs(closest_insect.position[1]-self.position[1])
            if dist <= 2:
                closest_insect.die()
                self.eat(14 if closest_insect.species == "insect" else 11)
                return
        nearby = ecosystem.get_nearby_plants(self.position, self.vision_range)
        preferred = [
            p for p in nearby
            if p.species in ["grass", "flower", "berry", "strawberry", "blueberry", "grape_vine"]
        ]
        if preferred:
            closest = min(preferred, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
            self.move_towards(closest.position, ecosystem)
            dist = abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1])
            if dist <= 1:
                self.eat(closest.be_eaten(0.35))
                return
        super().forage(ecosystem)


class Parrot(Animal):
    """鹦鹉 - 食果实，色彩鲜艳"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="parrot",
            position=position,
            max_age=70,
            hunger_rate=0.25,
            reproduction_rate=0.03,
            speed=2.5,
            vision_range=6,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦜"
        self.color = (255, 0, 0)  # 红色
        self.pregnancy_duration = 15
        
    def get_predators(self) -> List[str]:
        return ["fox", "snake", "eagle"]
        
    def get_food_sources(self) -> List[str]:
        return ["flower", "bush", "grass", "berry", "blueberry", "strawberry", "grape_vine", "cherry_tree"]  # 喜欢花和果实
        
    def forage(self, ecosystem):
        """鹦鹉优先找花和灌木"""
        nearby = ecosystem.get_nearby_plants(self.position, self.vision_range)
        preferred = [
            p for p in nearby
            if p.species in ["flower", "bush", "berry", "blueberry", "strawberry", "grape_vine", "cherry_tree"]
        ]
        
        if preferred:
            closest = min(preferred, key=lambda p:
                abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
            self.move_towards(closest.position, ecosystem)
            dist = abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1])
            if dist <= 1:
                nutrition = closest.be_eaten(0.5)
                self.eat(nutrition)
        else:
            super().forage(ecosystem)


class Kingfisher(Animal):
    """翠鸟 - 捕鱼能手"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="kingfisher",
            position=position,
            max_age=45,
            hunger_rate=0.18,
            reproduction_rate=0.08,
            speed=4.0,
            vision_range=9,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🐦"
        self.color = (0, 191, 255)  # 深天蓝色
        self.pregnancy_duration = 8
        
    def get_predators(self) -> List[str]:
        return ["eagle"]
        
    def get_prey_species(self) -> List[str]:
        return ["small_fish", "minnow", "shrimp", "tadpole", "insect", "water_strider", "frog"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "tree", "apple_tree", "cherry_tree", "berry"]

    def prefers_water_edge_cover(self) -> bool:
        return True

    def prefers_shrub_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["riparian_perch", "shrub_shelter", "shore_hatch"]

    def breeding_patch_threshold(self) -> float:
        return 0.12

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"riparian_perch", "shrub_shelter", "shore_hatch"},
            "amount": 0.12,
            "radius": 3,
            "hunger_relief": 8.5,
            "health_gain": 1.2,
            "min_hunger": 14.0,
        }
        
    def forage(self, ecosystem):
        """翠鸟在水边捕鱼"""
        self.find_cover(ecosystem, radius=6)
        sustainable_minnow = ecosystem.get_sustainable_population("minnow") if hasattr(ecosystem, "get_sustainable_population") else ecosystem.get_species_count("minnow")
        # 寻找水域附近
        found_water = False
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                nx, ny = self.position[0] + dx, self.position[1] + dy
                if 0 <= nx < ecosystem.width and 0 <= ny < ecosystem.height:
                    if ecosystem.environment.is_water(nx, ny):
                        found_water = True
                        # 找水中的猎物
                        aquatic_prey = ecosystem.get_nearby_aquatic((nx, ny), 4)
                        aquatic_prey = [
                            a for a in aquatic_prey
                            if a.species in ["small_fish", "minnow", "shrimp", "tadpole", "water_strider", "frog"] and a.alive
                        ]
                        if aquatic_prey:
                            if sustainable_minnow <= 12:
                                aquatic_prey = [a for a in aquatic_prey if a.species != "minnow"] or aquatic_prey
                            closest = min(aquatic_prey, key=lambda a:
                                abs(a.position[0]-nx) + abs(a.position[1]-ny))
                            # 俯冲捕食
                            chance = ecosystem.get_predation_chance(self.species, closest.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                            if abs(closest.position[0]-nx) + abs(closest.position[1]-ny) <= 3 and random.random() < min(0.82, chance):
                                closest.die()
                                self.eat(25)
                                return
        if not found_water:
            for dy in range(-5, 6):
                for dx in range(-5, 6):
                    nx, ny = self.position[0] + dx, self.position[1] + dy
                    if 0 <= nx < ecosystem.width and 0 <= ny < ecosystem.height and ecosystem.environment.is_water(nx, ny):
                        self.move_towards((nx, ny), ecosystem)
                        return
        if hasattr(ecosystem, "get_local_microhabitat_value") and hasattr(ecosystem, "consume_microhabitat"):
            hatch_value = ecosystem.get_local_microhabitat_value(self.position, {"shore_hatch"}, radius=4)
            if hatch_value >= 0.14:
                consumed = ecosystem.consume_microhabitat({"shore_hatch"}, self.position, 0.12, radius=3)
                if consumed > 0:
                    self.eat(10 + consumed * 8)
                    return
        # 没找到鱼就吃昆虫
        super().forage(ecosystem)

    def wander(self, ecosystem):
        if self.seek_habitat(ecosystem, radius=7):
            return
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                nx, ny = self.position[0] + dx, self.position[1] + dy
                if 0 <= nx < ecosystem.width and 0 <= ny < ecosystem.height and ecosystem.environment.is_water(nx, ny):
                    self.move_towards((nx, ny), ecosystem)
                    return
        super().wander(ecosystem)


class Spider(Animal):
    """蜘蛛 - 控制昆虫数量的重要天敌"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="spider",
            position=position,
            max_age=30,
            hunger_rate=0.4,
            reproduction_rate=0.15,
            speed=1.2,  # 爬行较慢
            vision_range=4,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🕷️"
        self.color = (80, 80, 80)  # 深灰色
        self.pregnancy_duration = 5
        self.maturity_age = 2  # 快速成熟
        
    def get_predators(self) -> List[str]:
        return ["bird", "sparrow"]  # 鸟类吃蜘蛛
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "night_moth", "bee", "water_strider"]  # 专门吃小型节肢动物
        
    def hunt(self, prey, ecosystem):
        """蜘蛛捕食 - 不会过度捕猎"""
        insect_count = len([i for i in ecosystem.animals if i.species == "insect" and i.alive])
        
        # 昆虫太少时保护机制
        if insect_count < 15 and random.random() < 0.3:
            return
            
        prey.die()
        self.eat(10)
        
        ecosystem.balance.record_causal_event(
            cause=f"蜘蛛捕食昆虫",
            effect=f"昆虫数量-1",
            impact=-0.1,
            tick=ecosystem.tick_count
        )
        
    def _give_birth(self, ecosystem):
        """蜘蛛产卵 - 根据昆虫数量控制"""
        insect_count = len([i for i in ecosystem.animals if i.species == "insect" and i.alive])
        current_spider = len([s for s in ecosystem.animals if s.species == "spider" and s.alive])
        
        # 🔄 动态繁殖：昆虫充足时才繁殖
        food_factor = max(0.1, min(1.5, insect_count / (current_spider * 3)))
        
        if insect_count > current_spider * 2:
            litter_size = max(1, min(5, int(food_factor * 3)))
            for _ in range(litter_size):
                pos = (self.position[0] + random.randint(-1, 1),
                       self.position[1] + random.randint(-1, 1))
                pos = (max(0, min(pos[0], ecosystem.width - 1)),
                       max(0, min(pos[1], ecosystem.height - 1)))
                ecosystem.spawn_animal("spider", pos, is_offspring=True)
        
        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 3


# ==================== 扩展鸟类 ====================

class Magpie(Animal):
    """喜鹊 - 杂食鸟类，聪明"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="magpie",
            position=position,
            max_age=40,
            hunger_rate=0.35,
            reproduction_rate=0.08,
            speed=3.5,
            vision_range=7,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐦‍⬛"
        self.color = (30, 30, 30)
        self.pregnancy_duration = 10
        self.can_hide = True
        
    def get_predators(self) -> List[str]:
        return ["fox", "eagle", "owl"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "bush", "berry", "blueberry", "strawberry", "moss"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "bee", "spider", "frog"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "bush", "apple_tree", "cherry_tree"]

    def prefers_canopy_cover(self) -> bool:
        return True


class Crow(Animal):
    """乌鸦 - 杂食，食腐"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="crow",
            position=position,
            max_age=50,
            hunger_rate=0.30,
            reproduction_rate=0.06,
            speed=3.0,
            vision_range=8,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐦‍⬛"
        self.color = (20, 20, 20)
        self.pregnancy_duration = 12
        self.can_hide = True
        
    def get_predators(self) -> List[str]:
        return ["eagle", "owl"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "moss", "berry", "mushroom", "blueberry", "strawberry"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "small_fish", "shrimp", "water_strider"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "bush", "apple_tree", "orange_tree"]

    def prefers_canopy_cover(self) -> bool:
        return True


class Woodpecker(Animal):
    """啄木鸟 - 专门吃昆虫"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="woodpecker",
            position=position,
            max_age=35,
            hunger_rate=0.4,
            reproduction_rate=0.10,
            speed=2.5,
            vision_range=5,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🐦"
        self.color = (139, 69, 19)
        self.pregnancy_duration = 8
        self.can_hide = True
        
    def get_predators(self) -> List[str]:
        return ["fox", "eagle", "owl", "snake"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "bee", "spider"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "apple_tree", "cherry_tree", "orange_tree"]

    def prefers_canopy_cover(self) -> bool:
        return True


class Hummingbird(Animal):
    """蜂鸟 - 最小的鸟，吃花蜜"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="hummingbird",
            position=position,
            max_age=36,
            hunger_rate=0.22,
            reproduction_rate=0.16,
            speed=5.0,
            vision_range=7,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐦"
        self.color = (0, 255, 127)
        self.pregnancy_duration = 4
        self.can_hide = True
        
    def get_predators(self) -> List[str]:
        return ["spider", "snake"]
        
    def get_food_sources(self) -> List[str]:
        return ["flower", "berry", "blueberry", "strawberry"]

    def get_prey_species(self) -> List[str]:
        return ["insect", "bee"]

    def get_cover_plant_species(self) -> List[str]:
        return ["flower", "bush", "berry", "blueberry", "strawberry"]

    def prefers_shrub_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["nectar_patch", "shrub_shelter"]

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"nectar_patch", "shrub_shelter"},
            "amount": 0.16,
            "radius": 3,
            "hunger_relief": 10.0,
            "health_gain": 1.3,
            "min_hunger": 10.0,
            "hours": (6, 18),
        }

    def forage(self, ecosystem):
        if self.find_cover(ecosystem, radius=6) and self.hunger < 30:
            return
        insects = [
            a for a in ecosystem.get_nearby_animals(self.position, 4)
            if a.alive and a.species in {"insect", "bee"}
        ]
        if insects and (self.hunger > 22 or random.random() < 0.35):
            target = min(insects, key=lambda a: abs(a.position[0]-self.position[0]) + abs(a.position[1]-self.position[1]))
            self.move_towards(target.position, ecosystem)
            if abs(target.position[0]-self.position[0]) + abs(target.position[1]-self.position[1]) <= 1:
                target.die()
                self.eat(10)
                return
        nearby = ecosystem.get_nearby_plants(self.position, self.vision_range)
        flowers = [p for p in nearby if p.alive and p.species in {"flower", "berry", "blueberry", "strawberry"}]
        if flowers:
            target = min(flowers, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
            self.move_towards(target.position, ecosystem)
            if abs(target.position[0]-self.position[0]) + abs(target.position[1]-self.position[1]) <= 1:
                self.eat(target.be_eaten(0.28))
                return
        super().forage(ecosystem)


# ==================== 扩展哺乳动物 ====================

class Squirrel(Animal):
    """松鼠 - 吃坚果/植物"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="squirrel",
            position=position,
            max_age=44,
            hunger_rate=0.16,
            reproduction_rate=0.17,
            speed=3.0,
            vision_range=7,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🐿️"
        self.color = (165, 42, 42)
        self.pregnancy_duration = 7
        self.can_hide = True
        self.has_camouflage = True
        self.camouflage_skill = 0.24
        
    def get_predators(self) -> List[str]:
        return ["fox", "eagle", "owl", "snake"]
        
    def get_food_sources(self) -> List[str]:
        return [
            "bush", "flower", "grass", "berry", "blueberry", "strawberry",
            "mushroom", "fern", "apple_tree", "cherry_tree", "orange_tree", "grape_vine"
        ]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "bush", "berry", "apple_tree", "cherry_tree", "orange_tree"]

    def prefers_canopy_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["canopy_roost", "canopy_forage"]

    def breeding_patch_threshold(self) -> float:
        return 0.08

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"canopy_roost", "canopy_forage"},
            "amount": 0.18,
            "radius": 3,
            "hunger_relief": 10.0,
            "health_gain": 1.4,
            "min_hunger": 12.0,
        }

    def wander(self, ecosystem):
        if self.seek_habitat(ecosystem, radius=8):
            return
        super().wander(ecosystem)

    def _give_birth(self, ecosystem):
        if not self.pregnant:
            return

        current_squirrel = ecosystem.get_species_count("squirrel") if hasattr(ecosystem, "get_species_count") else len([
            a for a in ecosystem.animals if a.species == "squirrel" and a.alive
        ])
        food_supply = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([
                p for p in ecosystem.plants if p.species == sp and p.alive
            ])
            for sp in ["tree", "bush", "berry", "blueberry", "strawberry", "mushroom", "fern", "apple_tree", "cherry_tree", "orange_tree", "grape_vine"]
        )
        predator_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([
                a for a in ecosystem.animals if a.species == sp and a.alive
            ])
            for sp in self.get_predators()
        )
        patch_value = ecosystem.get_local_microhabitat_value(
            self.position, {"canopy_roost", "canopy_forage"}, radius=4
        ) if hasattr(ecosystem, "get_local_microhabitat_value") else 0.0
        if patch_value < self.breeding_patch_threshold():
            self.pregnant = False
            self.pregnancy_timer = 0
            self.mate_cooldown = max(self.mate_cooldown, 8)
            return

        food_factor = max(0.45, min(1.7, food_supply / max(1, current_squirrel * 3.0)))
        predator_pressure = max(0.55, 1.06 - predator_count * 0.03)
        patch_factor = max(0.45, min(1.5, patch_value * 1.4))

        low_density = current_squirrel <= 6
        base_litter = random.randint(2, 4) if low_density else random.randint(1, 3)
        litter_cap = 4 if low_density else 3
        litter_size = max(1, min(litter_cap, int(base_litter * food_factor * predator_pressure * patch_factor)))

        for _ in range(litter_size):
            offspring_pos = (
                max(0, min(self.position[0] + random.randint(-2, 2), ecosystem.width - 1)),
                max(0, min(self.position[1] + random.randint(-2, 2), ecosystem.height - 1))
            )
            ecosystem.spawn_animal(self.species, offspring_pos, is_offspring=True)

        self.pregnant = False
        self.pregnancy_timer = 0
        self.mate_cooldown = 22 if low_density else 28

        ecosystem.balance.record_causal_event(
            cause="squirrel产仔",
            effect=f"squirrel+{litter_size}",
            impact=0.2,
            tick=ecosystem.tick_count
        )
        ecosystem.log_event(f"{self.id} gave birth to {litter_size} offspring")


class Hedgehog(Animal):
    """刺猬 - 吃昆虫，有防御"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="hedgehog",
            position=position,
            max_age=40,
            hunger_rate=0.35,
            reproduction_rate=0.08,
            speed=1.5,
            vision_range=4,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🦔"
        self.color = (128, 128, 128)
        self.pregnancy_duration = 10
        
    def get_predators(self) -> List[str]:
        return ["fox", "eagle", "owl"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "spider", "bee", "water_strider", "tadpole"]


class Bat(Animal):
    """蝙蝠 - 夜行性，吃昆虫"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="bat",
            position=position,
            max_age=52,
            hunger_rate=0.20,
            reproduction_rate=0.18,
            speed=4.5,
            vision_range=6,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🦇"
        self.color = (60, 60, 60)
        self.pregnancy_duration = 5
        self.is_nocturnal = True
        self.can_hide = True
        
    def get_predators(self) -> List[str]:
        return ["owl", "eagle"]

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["night_roost", "canopy_roost"]

    def breeding_patch_threshold(self) -> float:
        return 0.12

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"night_roost", "canopy_roost", "night_swarm"},
            "amount": 0.18,
            "radius": 3,
            "hunger_relief": 11.0,
            "health_gain": 1.5,
            "min_hunger": 10.0,
            "hours": (18, 6),
        }
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "night_moth", "spider", "bee", "water_strider"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "bush", "apple_tree", "cherry_tree", "orange_tree"]

    def prefers_canopy_cover(self) -> bool:
        return True


class Crocodile(Animal):
    """鳄鱼 - 水边顶级伏击捕食者。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="crocodile",
            position=position,
            max_age=140,
            hunger_rate=0.16,
            reproduction_rate=0.04,
            speed=1.8,
            vision_range=7,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🐊"
        self.color = (85, 107, 47)
        self.pregnancy_duration = 18
        self.ambush_interval = random.randint(6, 10)
        self._ambush_timer = 0

    def get_predators(self) -> List[str]:
        return []

    def get_prey_species(self) -> List[str]:
        return ["small_fish", "minnow", "carp", "shrimp", "frog", "duck", "swan", "rabbit", "deer"]

    def get_cover_plant_species(self) -> List[str]:
        return ["moss", "fern", "bush", "tree", "berry"]

    def prefers_water_edge_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["wetland_patch", "riparian_perch", "shore_hatch"]

    def breeding_patch_threshold(self) -> float:
        return 0.16

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"wetland_patch", "riparian_perch", "shore_hatch"},
            "amount": 0.10,
            "radius": 3,
            "hunger_relief": 7.5,
            "health_gain": 1.0,
            "min_hunger": 16.0,
        }

    def execute_behavior(self, ecosystem):
        self._ambush_timer += 1
        super().execute_behavior(ecosystem)
        if not self.alive:
            return
        if self._ambush_timer >= self.ambush_interval:
            self._ambush_timer = 0
            self._hold_ambush_position(ecosystem)

    def _hold_ambush_position(self, ecosystem):
        water_score = ecosystem.get_adjacent_water_score(self.position, radius=2) if hasattr(ecosystem, "get_adjacent_water_score") else 0.0
        wetland_value = ecosystem.get_local_microhabitat_value(self.position, {"wetland_patch", "riparian_perch"}, radius=3) if hasattr(ecosystem, "get_local_microhabitat_value") else 0.0
        if water_score <= 0 and wetland_value < 0.08:
            return
        if hasattr(ecosystem, "occupy_microhabitat"):
            ecosystem.occupy_microhabitat(self.species, {"wetland_patch", "riparian_perch"}, self.position, amount=0.18, radius=3)
        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} held an ambush position near the shoreline")

    def execute_behavior(self, ecosystem):
        """蝙蝠夜间活动"""
        hour = ecosystem.environment.hour
        if 18 <= hour or hour < 6:
            self.speed = 5.0
            self.vision_range = 8
        else:
            self.speed = 1.0
            self.vision_range = 3
            if self.seek_habitat(ecosystem, radius=7):
                self.hunger = max(0, self.hunger - 1.1)
                self.health = min(100, self.health + 0.50)
        super().execute_behavior(ecosystem)

    def forage(self, ecosystem):
        hour = ecosystem.environment.hour
        if 18 <= hour or hour < 6:
            nearby = self._cached_nearby_animals(ecosystem, self.vision_range)
            prey = []
            for creature in nearby:
                if not creature.alive or creature.species not in {"night_moth", "insect", "bee", "spider"}:
                    continue
                chance = ecosystem.get_predation_chance(self.species, creature.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if chance <= 0.0:
                    continue
                dist = abs(creature.position[0] - self.position[0]) + abs(creature.position[1] - self.position[1])
                moth_bonus = 0.0
                prey.append((dist, min(0.80, chance + moth_bonus), creature))
            if prey:
                _, attack_chance, target = min(prey, key=lambda item: item[0])
                self.move_towards(target.position, ecosystem)
                dist = abs(target.position[0] - self.position[0]) + abs(target.position[1] - self.position[1])
                if dist <= 1 and random.random() < attack_chance:
                    self.hunt(target, ecosystem)
                    return
        super().forage(ecosystem)


class Raccoon(Animal):
    """浣熊 - 杂食，聪明"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="raccoon",
            position=position,
            max_age=50,
            hunger_rate=0.32,
            reproduction_rate=0.06,
            speed=2.5,
            vision_range=7,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🦝"
        self.color = (100, 100, 100)
        self.pregnancy_duration = 12
        
    def get_predators(self) -> List[str]:
        return ["fox", "wolf", "eagle", "owl"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "bush", "moss", "berry", "blueberry", "strawberry", "mushroom"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "small_fish", "shrimp", "duck", "water_strider"]

"""
水生生物系统 - 扩展鱼类
"""

from typing import Optional, Tuple
import random
from enum import Enum
from ..core.creature import Creature, BehaviorState
from ..core.environment import TerrainType


def _density_factor(current_count: int, soft_capacity: float) -> float:
    """Soft carrying-capacity pressure without hard population caps."""
    if soft_capacity <= 0:
        return 1.0
    occupancy = current_count / soft_capacity
    if occupancy <= 0.6:
        return 1.0
    return max(0.05, 1.0 - (occupancy - 0.6) / 0.8)


class AquaticType(Enum):
    BENTHIC = "benthic"
    PELAGIC = "pelagic"
    SURFACE = "surface"


class AquaticCreature(Creature):
    """水生生物基类 - 动态繁殖"""
    
    def __init__(self, species, position, max_age, hunger_rate, reproduction_rate, speed=1.0, vision_range=3, aquatic_type=AquaticType.PELAGIC):
        super().__init__(species, position, max_age, hunger_rate, reproduction_rate, speed, vision_range)
        self.aquatic_type = aquatic_type
        self.food_population_factor = 1.0
        self.check_interval = 0
        self.color = (30, 144, 255)  # 默认蓝色
        self.emoji = "🐟"
        
    def update_reproduction_from_food(self, ecosystem, food_sources: list = None):
        """根据食物来源数量动态调整繁殖率"""
        self.check_interval += 1
        if self.check_interval < 5:
            return
        self.check_interval = 0
        
        if not food_sources:
            return
            
        # 计算食物数量
        food_count = sum(
            len([a for a in ecosystem.aquatic_creatures if a.species == sp and a.alive])
            for sp in food_sources
        )
        
        # 相对于同类数量
        my_count = len([a for a in ecosystem.aquatic_creatures if a.species == self.species and a.alive])
        
        if my_count > 0:
            food_per_creature = food_count / my_count
            # 食物充足度
            self.food_population_factor = max(0.1, min(1.5, food_per_creature / 2))
        else:
            self.food_population_factor = 1.0
            
        # 更新动态繁殖率
        self.reproduction_rate = self.base_reproduction_rate * self.ecology_reproduction_multiplier * self.food_population_factor
        
    def _is_in_water(self, ecosystem) -> bool:
        return ecosystem.environment.is_water(self.position[0], self.position[1])
    
    def _nearby_species(self, ecosystem, species, range_=None):
        search_range = range_ if range_ is not None else self.vision_range
        nearby = ecosystem.get_nearby_aquatic(self.position, search_range)
        if isinstance(species, str):
            species = {species}
        return [a for a in nearby if a.species in species and a.alive]

    def _water_profile(self, ecosystem):
        return ecosystem.environment.get_water_quality(self.position[0], self.position[1])

    def _shoreline_context(self, ecosystem, position=None):
        x, y = position or self.position
        mud = 0
        sand = 0
        land = 0
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                if dx == 0 and dy == 0:
                    continue
                nx = max(0, min(x + dx, ecosystem.width - 1))
                ny = max(0, min(y + dy, ecosystem.height - 1))
                terrain = ecosystem.environment.terrain.get((ny, nx))
                if terrain == TerrainType.MUD:
                    mud += 1
                elif terrain == TerrainType.SAND:
                    sand += 1
                elif terrain and terrain not in {
                    TerrainType.WATER_SHALLOW,
                    TerrainType.WATER_DEEP,
                    TerrainType.RIVER,
                }:
                    land += 1
        return {"mud": mud, "sand": sand, "land": land}

    def _benthic_refuge_score(self, ecosystem, position=None):
        shoreline = self._shoreline_context(ecosystem, position)
        score = 1.0 + shoreline["mud"] * 0.07 + shoreline["sand"] * 0.03
        if shoreline["land"] >= 2:
            score += 0.05
        return max(0.9, min(1.35, score))

    def _benthic_detritus_factor(self, ecosystem, position=None):
        shoreline = self._shoreline_context(ecosystem, position)
        query_position = position or self.position
        profile = ecosystem.environment.get_water_quality(query_position[0], query_position[1])
        factor = 1.0 + shoreline["mud"] * 0.08 + shoreline["sand"] * 0.04
        if shoreline["land"] >= 2:
            factor += 0.04
        if profile:
            if profile.body_type == "lake_shallow":
                factor += 0.08
            elif profile.body_type == "river_channel":
                factor += 0.04
            if profile.nutrient_load > 0.42:
                factor += min(0.12, (profile.nutrient_load - 0.42) * 0.35)
            if profile.clarity < 0.58:
                factor += min(0.12, (0.58 - profile.clarity) * 0.4)
            if profile.flow_rate < 0.35:
                factor += 0.04
        return max(0.95, min(1.45, factor))

    def _shoreline_predation_penalty(self, ecosystem, prey):
        if getattr(prey, "aquatic_type", None) != AquaticType.BENTHIC:
            return 1.0

        shoreline = prey._shoreline_context(ecosystem) if hasattr(prey, "_shoreline_context") else {"mud": 0, "sand": 0, "land": 0}
        refuge = prey._benthic_refuge_score(ecosystem) if hasattr(prey, "_benthic_refuge_score") else 1.0
        detritus = prey._benthic_detritus_factor(ecosystem) if hasattr(prey, "_benthic_detritus_factor") else 1.0
        profile = ecosystem.environment.get_water_quality(prey.position[0], prey.position[1])

        penalty = 1.0
        penalty *= max(0.46, 1.04 - (refuge - 1.0) * 0.9)
        penalty *= max(0.52, 1.02 - (detritus - 1.0) * 0.55)
        penalty *= max(0.38, 1.0 - shoreline["mud"] * 0.08 - shoreline["sand"] * 0.035)

        if shoreline["land"] >= 2:
            penalty *= 0.95
        if profile:
            if profile.body_type == "lake_shallow":
                penalty *= 0.94
            if profile.clarity < 0.62:
                penalty *= max(0.45, 1.0 - (0.62 - profile.clarity) * 0.9)
            if shoreline["mud"] >= 2 and profile.clarity < 0.55:
                penalty *= 0.72

        return max(0.22, min(1.0, penalty))

    def _habitat_score(self, ecosystem, preferred_body_types=None, min_oxygen=0.0, max_flow=None, min_nutrients=0.0):
        profile = self._water_profile(ecosystem)
        if not profile:
            return 0.7
        score = 1.0
        if preferred_body_types and profile.body_type not in preferred_body_types:
            score *= 0.78
        if profile.oxygen_level < min_oxygen:
            score *= max(0.45, profile.oxygen_level / max(min_oxygen, 0.01))
        if max_flow is not None and profile.flow_rate > max_flow:
            score *= max(0.5, 1.0 - (profile.flow_rate - max_flow))
        if profile.nutrient_load < min_nutrients:
            score *= max(0.55, profile.nutrient_load / max(min_nutrients, 0.01))
        return max(0.35, min(1.25, score))

    def _habitat_score_for_position(
        self,
        ecosystem,
        position,
        preferred_body_types=None,
        min_oxygen=0.0,
        max_flow=None,
        min_nutrients=0.0,
    ):
        profile = ecosystem.environment.get_water_quality(position[0], position[1])
        if not profile:
            return 0.0

        score = 1.0
        if preferred_body_types and profile.body_type not in preferred_body_types:
            score *= 0.78
        if profile.oxygen_level < min_oxygen:
            score *= max(0.45, profile.oxygen_level / max(min_oxygen, 0.01))
        if max_flow is not None and profile.flow_rate > max_flow:
            score *= max(0.5, 1.0 - (profile.flow_rate - max_flow))
        if profile.nutrient_load < min_nutrients:
            score *= max(0.55, profile.nutrient_load / max(min_nutrients, 0.01))
        return max(0.25, min(1.35, score))

    def _candidate_water_positions(self, ecosystem, radius):
        positions = []
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                if dx == 0 and dy == 0:
                    continue
                if abs(dx) + abs(dy) > radius + 1:
                    continue
                x = max(0, min(self.position[0] + dx, ecosystem.width - 1))
                y = max(0, min(self.position[1] + dy, ecosystem.height - 1))
                if ecosystem.environment.is_water(x, y):
                    positions.append((x, y))
        random.shuffle(positions)
        return positions[:18]

    def _score_candidate_position(
        self,
        ecosystem,
        position,
        preferred_body_types=None,
        min_oxygen=0.0,
        max_flow=None,
        min_nutrients=0.0,
        prey_species=None,
        predator_species=None,
    ):
        score = self._habitat_score_for_position(
            ecosystem,
            position,
            preferred_body_types=preferred_body_types,
            min_oxygen=min_oxygen,
            max_flow=max_flow,
            min_nutrients=min_nutrients,
        )

        nearby_aquatic = ecosystem.get_nearby_aquatic(position, max(4, self.vision_range))
        if prey_species:
            prey_count = len([a for a in nearby_aquatic if a.alive and a.species in prey_species])
            score += min(0.45, prey_count * 0.06)
        if predator_species:
            predator_count = len([a for a in nearby_aquatic if a.alive and a.species in predator_species])
            score -= min(0.35, predator_count * 0.08)
        if self.aquatic_type == AquaticType.BENTHIC:
            refuge = self._benthic_refuge_score(ecosystem, position)
            detritus = self._benthic_detritus_factor(ecosystem, position)
            score *= refuge
            score += min(0.28, (detritus - 1.0) * 0.55)

        distance = abs(position[0] - self.position[0]) + abs(position[1] - self.position[1])
        score -= distance * 0.025
        return score

    def swim(
        self,
        ecosystem,
        preferred_body_types=None,
        min_oxygen=0.0,
        max_flow=None,
        min_nutrients=0.0,
        prey_species=None,
        predator_species=None,
    ):
        move_radius = max(2, min(5, int(round(self.speed * 1.8))))
        current_score = self._score_candidate_position(
            ecosystem,
            self.position,
            preferred_body_types=preferred_body_types,
            min_oxygen=min_oxygen,
            max_flow=max_flow,
            min_nutrients=min_nutrients,
            prey_species=prey_species,
            predator_species=predator_species,
        )

        best_position = self.position
        best_score = current_score
        for candidate in self._candidate_water_positions(ecosystem, move_radius):
            candidate_score = self._score_candidate_position(
                ecosystem,
                candidate,
                preferred_body_types=preferred_body_types,
                min_oxygen=min_oxygen,
                max_flow=max_flow,
                min_nutrients=min_nutrients,
                prey_species=prey_species,
                predator_species=predator_species,
            )
            if candidate_score > best_score + 0.03:
                best_position = candidate
                best_score = candidate_score

        should_move = best_position != self.position and random.random() < 0.72
        if should_move:
            self.position = best_position
        elif random.random() < 0.22:
            dx = random.randint(-2, 2)
            dy = random.randint(-2, 2)
            new_x = max(0, min(self.position[0] + dx, ecosystem.width - 1))
            new_y = max(0, min(self.position[1] + dy, ecosystem.height - 1))
            if ecosystem.environment.is_water(new_x, new_y):
                self.position = (new_x, new_y)

        if hasattr(ecosystem, "refresh_spatial_entity"):
            ecosystem.refresh_spatial_entity(self)


# 水生植物
class Algae(AquaticCreature):
    """藻类 - 基础生产者，快速繁殖"""
    def __init__(self, position):
        super().__init__("algae", position, 60, 0, 0.25, 0, 0)  # 繁殖率提高到0.25
        self.size = 1.2  # 初始 size 提高
        self.reproduction_cooldown = 0
        self.color = (0, 128, 0)  # 深绿色
        self.emoji = "🌿"
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile and profile.nutrient_load > 0.75 and profile.clarity < 0.35:
            self.size = max(0.6, self.size - 0.01)
        
        # 生长（阳光影响，但更稳定）
        sunlight = ecosystem.environment.get_sunlight_factor()
        # 生长不再过度依赖阳光（藻类适应性更强）
        growth = 0.03 + 0.02 * sunlight  # 基础生长 + 阳光加成
        self.size = min(3, self.size + growth)
        
        # 🌱 繁殖机制
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        elif self.size >= 1.3 and self.age > 3:  # 降低条件
            water_cells = max(1, len(ecosystem.environment.water_quality))
            current_algae = len([a for a in ecosystem.aquatic_creatures if a.species == "algae" and a.alive])
            density = _density_factor(current_algae, water_cells * 1.2)

            # 获取水质
            water_quality = ecosystem.environment.get_water_quality(self.position[0], self.position[1])
            water_factor = 0.7  # 最低保底
            if water_quality:
                water_factor = max(0.7, water_quality.oxygen_level)
            
            # 繁殖率：不再过度依赖阳光
            # 使用更稳定的繁殖模型
            effective_rate = self.reproduction_rate * water_factor * density
            
            # 🔄 捕食压力越高，繁殖越积极（补偿机制）
            # 获取捕食者数量
            predator_count = len([s for s in ecosystem.aquatic_creatures if s.species == "shrimp" and s.alive])
            reproduction_boost = max(1.0, 1.0 + predator_count * 0.01)
            
            # 阳光充足时繁殖更积极
            if sunlight > 0.3:
                effective_rate *= 1.5
            
            effective_rate *= reproduction_boost
            
            # 🌱 无上限：只要条件满足就繁殖
            if random.random() < effective_rate:
                dx, dy = random.randint(-2, 2), random.randint(-2, 2)
                new_pos = (
                    max(0, min(self.position[0] + dx, ecosystem.width - 1)),
                    max(0, min(self.position[1] + dy, ecosystem.height - 1))
                )
                if ecosystem.environment.is_water(new_pos[0], new_pos[1]):
                    ecosystem.spawn_aquatic("algae", new_pos)
                    self.reproduction_cooldown = 8
                    self.size -= 0.2
        
        if self.age >= self.max_age: self.die()


class Seaweed(AquaticCreature):
    """水草 - 水生植物，稳定繁殖"""
    def __init__(self, position):
        super().__init__("seaweed", position, 90, 0, 0.12, 0, 0)  # 繁殖率0.12
        self.size = 1.5  # 初始size提高
        self.reproduction_cooldown = 0
        self.color = (34, 139, 34)
        self.emoji = "🌿"
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile and profile.flow_rate > 0.65 and random.random() < 0.12:
            self.size = max(0.8, self.size - 0.02)
        
        # 生长（更稳定）
        sunlight = ecosystem.environment.get_sunlight_factor()
        growth = 0.02 + 0.01 * sunlight  # 保底生长
        self.size = min(4, self.size + growth)
        
        # 🌱 繁殖机制
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        elif self.size >= 1.8 and self.age > 8:  # 降低条件
            water_cells = max(1, len(ecosystem.environment.water_quality))
            current_seaweed = len([a for a in ecosystem.aquatic_creatures if a.species == "seaweed" and a.alive])
            density = _density_factor(current_seaweed, water_cells * 0.8)

            water_quality = ecosystem.environment.get_water_quality(self.position[0], self.position[1])
            water_factor = 0.7  # 保底
            if water_quality:
                water_factor = max(0.7, water_quality.oxygen_level)
            
            # 🔄 捕食压力补偿
            predator_count = len([s for s in ecosystem.aquatic_creatures if s.species == "swan" and s.alive])
            reproduction_boost = max(1.0, 1.0 + predator_count * 0.01)
            
            effective_rate = self.reproduction_rate * water_factor * reproduction_boost * density
            if sunlight > 0.3:
                effective_rate *= 1.3
            
            # 🌱 无上限繁殖
            if random.random() < effective_rate:
                dx, dy = random.randint(-3, 3), random.randint(-3, 3)
                new_pos = (
                    max(0, min(self.position[0] + dx, ecosystem.width - 1)),
                    max(0, min(self.position[1] + dy, ecosystem.height - 1))
                )
                if ecosystem.environment.is_water(new_pos[0], new_pos[1]):
                    ecosystem.spawn_aquatic("seaweed", new_pos)
                    self.reproduction_cooldown = 12
        
        if self.age >= self.max_age: self.die()


class Plankton(AquaticCreature):
    """浮游生物 - 基础食物来源，高繁殖率"""
    def __init__(self, position):
        super().__init__("plankton", position, 25, 0.1, 0.5, 0.3, 1)  # 寿命延长到25，繁殖率0.5
        self.color = (200, 200, 200)  # 浅灰色（微小生物）
        self.emoji = "🔬"
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        if not self._is_in_water(ecosystem): self.die(); return
        self.hunger += self.hunger_rate
        if self.age >= self.max_age: self.die(); return
        
        # 🌱 繁殖：浮游生物快速繁殖，捕食压力补偿
        sunlight = ecosystem.environment.get_sunlight_factor()
        water_cells = max(1, len(ecosystem.environment.water_quality))
        current_plankton = len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        density = _density_factor(current_plankton, water_cells * 2.5)
        
        # 🔄 捕食压力补偿
        predator_count = sum(len([c for c in ecosystem.aquatic_creatures 
                                 if c.species == sp and c.alive]) 
                             for sp in ["small_fish", "shrimp", "tadpole"])
        reproduction_boost = max(1.0, 1.0 + predator_count * 0.02)
        
        # 🌱 无上限繁殖
        if self.age > 3 and random.random() < self.reproduction_rate * sunlight * reproduction_boost * density:
            dx, dy = random.randint(-1, 1), random.randint(-1, 1)
            new_pos = (
                max(0, min(self.position[0] + dx, ecosystem.width - 1)),
                max(0, min(self.position[1] + dy, ecosystem.height - 1))
            )
            if ecosystem.environment.is_water(new_pos[0], new_pos[1]):
                ecosystem.spawn_aquatic("plankton", new_pos)
        
        self.swim(ecosystem)


# 鱼类
class SmallFish(AquaticCreature):
    """小鱼 - 中级消费者，吃浮游生物，被多种捕食者捕食"""
    def __init__(self, position, gender=None):
        super().__init__("small_fish", position, 50, 0.25, 0.15, 1.5, 4)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (255, 215, 0)
        self.emoji = "🐟"
        self.predators = ["catfish", "large_fish", "blackfish", "pike", "crab", "kingfisher"]
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile:
            if profile.body_type == "river_channel":
                self.health = min(100, self.health + 0.12)
            elif profile.body_type == "lake_shallow":
                self.health = min(100, self.health + 0.08)
            elif profile.body_type == "lake_deep":
                self.health = min(100, self.health + 0.03)
            elif profile.oxygen_level < 0.42:
                self.health -= 1.2
        if self.hunger > 70: self.health -= 2
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：食物充足度 + 天敌压力
        plankton_count = len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        current_smallfish = len([f for f in ecosystem.aquatic_creatures if f.species == "small_fish" and f.alive])
        
        # 食物因子
        food_factor = max(0.4, min(1.8, plankton_count / max(1, current_smallfish * 1.5)))
        if current_smallfish <= 6:
            food_factor = min(2.0, food_factor * 1.25)
        
        # 天敌压力
        predator_count = sum(len([c for c in ecosystem.aquatic_creatures 
                                 if c.species == sp and c.alive]) 
                             for sp in self.predators)
        predator_pressure = max(0.35, 1.0 - predator_count * 0.04)
        habitat_factor = self._habitat_score(ecosystem, {"river_channel", "lake_shallow"}, min_oxygen=0.55, max_flow=0.95)
        if profile and profile.body_type.startswith("lake"):
            predator_pressure = min(0.92, predator_pressure * 1.18)
            habitat_factor = min(1.35, habitat_factor * 1.12)
        
        # 怀孕逻辑
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 8:
                # 🌱 自然繁殖：无上限，由食物和天敌控制
                offspring = max(1, min(4, int(food_factor * predator_pressure * habitat_factor * 3)))
                for _ in range(offspring):
                    ecosystem.spawn_aquatic("small_fish", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 10
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [f for f in ecosystem.aquatic_creatures 
                    if f.species == "small_fish" and f.gender == 'male' and f.alive]
            spawn_gate = 2 if current_smallfish <= 6 else 3
            if profile and profile.body_type.startswith("lake"):
                spawn_gate = max(1, spawn_gate - 1)
            if males and plankton_count > spawn_gate:
                chance = (0.32 if current_smallfish <= 6 else 0.24) * food_factor * predator_pressure * habitat_factor
                if profile and profile.body_type.startswith("lake"):
                    chance *= 1.12
                if random.random() < chance:
                    self.pregnant = True
        
        # 觅食：以浮游生物为主，也会啃食藻类和追逐水黾幼体
        if self.hunger > 10:
            plankton = self._nearby_species(ecosystem, "plankton", 4)
            if plankton and random.random() < 0.6:
                closest = min(plankton, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < 0.5 * habitat_factor:
                    closest.die()
                    self.eat(18)
            elif random.random() < 0.35:
                fallback = self._nearby_species(ecosystem, {"algae", "water_strider"}, 3)
                if fallback:
                    closest = min(fallback, key=lambda p:
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 3:
                        if hasattr(closest, "size"):
                            closest.size -= 0.25
                            if closest.size <= 0:
                                closest.die()
                            self.eat(8)
                        else:
                            closest.die()
                            self.eat(12)
        
        self.swim(
            ecosystem,
            preferred_body_types={"river_channel", "lake_shallow", "lake_deep"},
            min_oxygen=0.55,
            max_flow=0.95,
            prey_species={"plankton", "algae", "water_strider"},
            predator_species=set(self.predators),
        )


class Minnow(AquaticCreature):
    """米诺鱼 - 河道/浅湖中层小型猎物，缓解高位鱼对虾和小鱼的争食。"""
    def __init__(self, position, gender=None):
        super().__init__("minnow", position, 42, 0.2, 0.16, 1.9, 5)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (135, 206, 235)
        self.emoji = "🐠"
        self.predators = ["catfish", "large_fish", "blackfish", "pike", "crab", "kingfisher"]

    def _schooling_factor(self, ecosystem):
        nearby = self._nearby_species(ecosystem, "minnow", 4)
        return max(1.0, min(1.35, 1.0 + len(nearby) * 0.05))

    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        refuge_factor = self._benthic_refuge_score(ecosystem)
        schooling_factor = self._schooling_factor(ecosystem)
        if profile:
            if profile.body_type == "river_channel":
                self.health = min(100, self.health + 0.18 * refuge_factor)
            elif profile.body_type == "lake_shallow":
                self.health = min(100, self.health + 0.08 * refuge_factor)
            if profile.oxygen_level < 0.48:
                self.health -= 1.4
        if self.hunger > 62: self.health -= 2.5
        if self.health <= 0 or self.age >= self.max_age: self.die(); return

        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1

        plankton_count = len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        algae_count = len([a for a in ecosystem.aquatic_creatures if a.species == "algae" and a.alive])
        shrimp_count = len([s for s in ecosystem.aquatic_creatures if s.species == "shrimp" and s.alive])
        current_minnow = len([m for m in ecosystem.aquatic_creatures if m.species == "minnow" and m.alive])

        food_supply = plankton_count + algae_count * 0.4 + shrimp_count * 0.2
        food_factor = max(0.35, min(2.0, food_supply / max(1, current_minnow * 1.7)))
        if current_minnow <= 10:
            food_factor = min(2.3, food_factor * 1.26)

        predator_count = sum(
            len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in self.predators
        )
        predator_pressure = max(0.42, 1.0 - predator_count * 0.032)
        if profile and profile.body_type == "river_channel":
            predator_pressure = min(1.05, predator_pressure * (1.05 + (schooling_factor - 1.0) * 0.4))
        habitat_factor = self._habitat_score(
            ecosystem,
            {"river_channel", "lake_shallow"},
            min_oxygen=0.56,
            max_flow=0.92,
            min_nutrients=0.26,
        )
        if profile and profile.body_type == "river_channel":
            habitat_factor = min(1.45, habitat_factor * 1.14 * refuge_factor)

        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 7:
                litter_size = max(1, min(4, int(food_factor * predator_pressure * habitat_factor * 3)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("minnow", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 9

        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [m for m in ecosystem.aquatic_creatures if m.species == "minnow" and m.gender == 'male' and m.alive]
            spawn_gate = 4 if current_minnow <= 10 else 7
            if ecosystem.environment.season == "spring":
                spawn_gate = max(3, spawn_gate - 1)
            if males and food_supply > spawn_gate:
                chance = (0.22 if current_minnow <= 10 else 0.16) * food_factor * predator_pressure * habitat_factor
                if ecosystem.environment.season == "spring":
                    chance *= 1.14
                if random.random() < chance:
                    self.pregnant = True

        if self.hunger > 14:
            prey = self._nearby_species(ecosystem, {"plankton", "algae", "water_strider"}, 4)
            if prey:
                closest = min(prey, key=lambda p:
                    abs(p.position[0] - self.position[0]) + abs(p.position[1] - self.position[1]))
                if abs(closest.position[0] - self.position[0]) + abs(closest.position[1] - self.position[1]) <= 4:
                    if hasattr(closest, "size"):
                        closest.size -= 0.22
                        if closest.size <= 0:
                            closest.die()
                        self.eat(9)
                    else:
                        closest.die()
                        self.eat(12)
            elif random.random() < 0.22:
                self.eat(4)

        self.swim(
            ecosystem,
            preferred_body_types={"river_channel", "lake_shallow"},
            min_oxygen=0.56,
            max_flow=0.92,
            min_nutrients=0.26,
            prey_species={"plankton", "algae", "water_strider"},
            predator_species=set(self.predators),
        )


class Carp(AquaticCreature):
    """鲤鱼 - 中型杂食鱼，被黑鱼/大鱼捕食"""
    def __init__(self, position, gender=None):
        super().__init__("carp", position, 70, 0.25, 0.08, 1.8, 5)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (255, 140, 0)
        self.emoji = "🐟"
        self.predators = ["blackfish", "large_fish", "pike"]  # 天敌列表
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile:
            if profile.body_type.startswith("lake") and profile.nutrient_load > 0.45:
                self.health = min(100, self.health + 0.08)
            if profile.flow_rate > 0.7:
                self.health -= 0.8
        if self.hunger > 60: self.health -= 3
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据食物和天敌数量调整
        # 计算食物充足度
        food_count = len([c for c in ecosystem.aquatic_creatures 
                         if c.species in ["plankton", "algae"] and c.alive])
        current_carp = len([c for c in ecosystem.aquatic_creatures 
                           if c.species == "carp" and c.alive])
        food_factor = max(0.25, min(1.8, food_count / max(1, current_carp * 1.5)))
        if current_carp <= 6:
            food_factor = min(2.0, food_factor * 1.3)
        
        # 计算天敌压力
        predator_count = sum(len([c for c in ecosystem.aquatic_creatures 
                                 if c.species == sp and c.alive]) 
                             for sp in self.predators)
        predator_pressure = max(0.4, 1.0 - predator_count * 0.08)  # 天敌越多，繁殖越谨慎
        habitat_factor = self._habitat_score(ecosystem, {"lake_shallow", "lake_deep"}, min_oxygen=0.45, max_flow=0.6, min_nutrients=0.35)
        
        # 怀孕逻辑
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 10:
                # 🌱 自然繁殖：无硬编码上限，由食物和天敌控制
                litter_size = max(1, min(4, int(food_factor * predator_pressure * habitat_factor * 3)))
                for _ in range(litter_size): 
                    ecosystem.spawn_aquatic("carp", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 15
        
        # 受孕
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [c for c in ecosystem.aquatic_creatures 
                    if c.species == "carp" and c.gender == 'male' and c.alive]
            if males and random.random() < (0.065 if current_carp <= 6 else 0.04) * food_factor * predator_pressure * habitat_factor:
                self.pregnant = True
                
        # 觅食
        if self.hunger > 20:
            targets = self._nearby_species(ecosystem, {"plankton", "algae", "shrimp", "seaweed"}, 3)
            if targets:
                closest = min(targets, key=lambda t: 
                    abs(t.position[0]-self.position[0]) + abs(t.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 3 and random.random() < 0.55 * habitat_factor:
                    if hasattr(closest, "size"):
                        closest.size -= 0.4
                        if closest.size <= 0:
                            closest.die()
                        self.eat(14)
                    else:
                        closest.die()
                        self.eat(20)
        self.swim(
            ecosystem,
            preferred_body_types={"lake_shallow", "lake_deep"},
            min_oxygen=0.45,
            max_flow=0.6,
            min_nutrients=0.35,
            prey_species={"plankton", "algae", "shrimp", "seaweed"},
            predator_species=set(self.predators),
        )


class Catfish(AquaticCreature):
    """鲶鱼 - 底栖，吃小鱼/虾，繁殖由猎物数量控制"""
    def __init__(self, position, gender=None):
        super().__init__("catfish", position, 80, 0.30, 0.06, 1.5, 4, AquaticType.BENTHIC)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (139, 69, 19)
        self.emoji = "🐟"

    def _spawning_factor(self, ecosystem):
        profile = self._water_profile(ecosystem)
        factor = self._benthic_detritus_factor(ecosystem)
        if profile:
            if profile.body_type == "river_channel":
                factor += 0.18
            elif profile.body_type == "lake_shallow":
                factor -= 0.14
            elif profile.body_type == "lake_deep":
                factor -= 0.18
            if profile.oxygen_level >= 0.55:
                factor += 0.05
        return max(0.82, min(1.45, factor))
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile:
            if profile.body_type == "lake_deep":
                self.health = min(100, self.health + 0.1)
            elif profile.oxygen_level < 0.45:
                self.health -= 1.0
        if self.hunger > 60: self.health -= 3
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：猎物不足时不繁殖
        prey_count = len([c for c in ecosystem.aquatic_creatures 
                         if c.species in ["small_fish", "minnow", "shrimp", "carp"] and c.alive])
        small_fish_count = len([c for c in ecosystem.aquatic_creatures if c.species == "small_fish" and c.alive])
        current_catfish = len([c for c in ecosystem.aquatic_creatures if c.species == "catfish" and c.alive])
        food_factor = max(0.18, min(1.7, prey_count / max(1, current_catfish * 3.0)))
        spawning_factor = self._spawning_factor(ecosystem)
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 12:
                # 🌱 产仔数量由猎物决定
                litter_size = max(1, min(3, int(food_factor * spawning_factor * 2)))
                for _ in range(litter_size): 
                    ecosystem.spawn_aquatic("catfish", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 18
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [c for c in ecosystem.aquatic_creatures 
                    if c.species == "catfish" and c.gender == 'male' and c.alive]
            # 猎物充足时才受孕
            prey_gate = max(2, int(current_catfish * (0.8 if current_catfish <= 4 else 1.0)))
            if males and prey_count > prey_gate and random.random() < 0.038 * food_factor * spawning_factor:
                self.pregnant = True
                
        if self.hunger > 20:
            minnows = self._nearby_species(ecosystem, "minnow", 3)
            if minnows and prey_count > current_catfish:
                closest = min(minnows, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                    closest.die()
                    self.eat(30)
            else:
                prey_targets = {"shrimp", "carp", "frog", "tadpole"}
                if not profile or profile.body_type == "river_channel" or small_fish_count > max(16, current_catfish * 4):
                    prey_targets.add("small_fish")
                prey = self._nearby_species(ecosystem, prey_targets, 3)
                if prey and prey_count > current_catfish:
                    closest = min(prey, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                        if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                            closest.die()
                            self.eat(24 if closest.species in {"shrimp", "tadpole"} else 32)
        self.swim(
            ecosystem,
            preferred_body_types={"river_channel"},
            min_oxygen=0.58,
            max_flow=0.9,
            prey_species={"carp", "small_fish", "minnow", "frog", "tadpole", "shrimp"},
        )


class LargeFish(AquaticCreature):
    """大鱼 - 顶级水生捕食者，吃鲤鱼/小鱼"""
    def __init__(self, position, gender=None):
        super().__init__("large_fish", position, 80, 0.20, 0.06, 2.0, 6)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (0, 0, 139)
        self.emoji = "🐠"
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile:
            if profile.body_type == "lake_deep":
                self.health = min(100, self.health + 0.1)
            elif profile.body_type == "lake_shallow":
                self.health = min(100, self.health + 0.06)
            if profile.flow_rate > 0.72:
                self.health -= 1.1
        if self.hunger > 70: self.health -= 2
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据猎物数量决定繁殖
        prey_count = len([c for c in ecosystem.aquatic_creatures 
                         if c.species in ["small_fish", "minnow", "carp", "shrimp"] and c.alive])
        current_predator = len([c for c in ecosystem.aquatic_creatures 
                               if c.species == "large_fish" and c.alive])
        
        # 食物充足度：猎物数量相对于捕食者数量
        food_factor = max(0.18, min(1.8, prey_count / max(1, current_predator * 3.4)))
        if current_predator <= 2:
            food_factor = min(2.0, food_factor * 1.35)
        if profile and profile.body_type.startswith("lake"):
            food_factor = min(2.05, food_factor * 1.16)
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 12:
                # 🌱 自然繁殖：产仔数量取决于猎物充足度
                litter_size = max(1, min(3, int(food_factor * 2.4)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("large_fish", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 20
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [c for c in ecosystem.aquatic_creatures 
                    if c.species == "large_fish" and c.gender == 'male' and c.alive]
            # 猎物充足时才繁殖
            prey_gate = max(2, int(current_predator * 1.2))
            conception_rate = (0.06 if current_predator <= 2 else 0.042) * food_factor
            if males and prey_count >= prey_gate and random.random() < conception_rate:
                self.pregnant = True
                
        # 觅食：优先吃鲤鱼（控制鲤鱼数量）
        if self.hunger > 30:
            # 优先捕食鲤鱼
            carp = self._nearby_species(ecosystem, "carp", 6)
            if carp and random.random() < 0.5 and len(carp) > 1:
                closest = min(carp, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 5:
                    closest.die()
                    self.eat(50)
            else:
                # 没有鲤鱼就先吃米诺鱼，再吃其他中层猎物
                minnows = self._nearby_species(ecosystem, "minnow", 4)
                if minnows and prey_count > current_predator:
                    closest = min(minnows, key=lambda p:
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4:
                        closest.die()
                        self.eat(36)
                else:
                    prey = self._nearby_species(ecosystem, {"small_fish", "shrimp", "frog", "tadpole"}, 4)
                    if prey and prey_count > current_predator:
                        closest = min(prey, key=lambda p: 
                            abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                        if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4:
                            if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                                closest.die()
                                self.eat(34 if closest.species in {"shrimp", "tadpole"} else 40)
        self.swim(
            ecosystem,
            preferred_body_types={"lake_deep", "lake_shallow"},
            min_oxygen=0.5,
            max_flow=0.55,
            prey_species={"carp", "small_fish", "minnow", "shrimp", "frog", "tadpole"},
        )


class Blackfish(AquaticCreature):
    """黑鱼 - 鲤鱼的天敌，凶猛捕食者"""
    def __init__(self, position, gender=None):
        super().__init__("blackfish", position, 90, 0.18, 0.04, 2.5, 7)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (20, 20, 20)  # 黑色
        self.emoji = "🐟"

    def _seasonal_metabolism_factor(self, ecosystem):
        season = ecosystem.environment.season
        if season == "winter":
            return 0.82
        if season == "autumn":
            return 0.92
        return 1.0
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        metabolism_factor = self._seasonal_metabolism_factor(ecosystem)
        if metabolism_factor < 1.0:
            self.hunger = max(0, self.hunger - (1.0 - metabolism_factor) * 0.5)
        if profile:
            if profile.body_type.startswith("lake") and profile.depth_factor > 0.7:
                self.health = min(100, self.health + 0.12)
            if profile.flow_rate > 0.65:
                self.health -= 1.3
        if self.hunger > 60: self.health -= 3
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据鲤鱼数量决定繁殖
        carp_count = len([c for c in ecosystem.aquatic_creatures if c.species == "carp" and c.alive])
        small_fish_count = len([c for c in ecosystem.aquatic_creatures if c.species == "small_fish" and c.alive])
        minnow_count = len([c for c in ecosystem.aquatic_creatures if c.species == "minnow" and c.alive])
        current_blackfish = len([c for c in ecosystem.aquatic_creatures if c.species == "blackfish" and c.alive])
        
        # 鲤鱼充足度
        food_factor = max(0.15, min(1.8, (carp_count * 2.0 + small_fish_count * 0.9 + minnow_count * 0.35) / max(1, current_blackfish * 7)))
        if current_blackfish <= 3:
            food_factor = min(2.0, food_factor * 1.58)
        habitat_factor = self._habitat_score(ecosystem, {"lake_deep", "lake_shallow"}, min_oxygen=0.5, max_flow=0.55)
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 15:
                litter_size = max(1, min(4, int(food_factor * habitat_factor * 2)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("blackfish", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 30
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [c for c in ecosystem.aquatic_creatures 
                    if c.species == "blackfish" and c.gender == 'male' and c.alive]
            # 鲤鱼充足时才繁殖
            prey_gate = max(3, current_blackfish * (2 if current_blackfish <= 3 else 3))
            if males and (carp_count * 1.4 + small_fish_count + minnow_count * 0.3) > prey_gate and random.random() < (0.06 if current_blackfish <= 3 else 0.035) * food_factor * habitat_factor:
                self.pregnant = True
                
        # 觅食：专门捕食鲤鱼
        if self.hunger > 25:
            carp = self._nearby_species(ecosystem, "carp", 7)
            local_carp_pressure = len(carp)
            if carp and carp_count > max(2, current_blackfish) and local_carp_pressure >= (2 if current_blackfish <= 3 else 3):
                closest = min(carp, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 6 and random.random() < habitat_factor:
                    closest.die()
                    self.eat(60)  # 鲤鱼营养价值高
            # 没有鲤鱼时也吃小鱼
            elif self.hunger > 35:
                small_fish = self._nearby_species(ecosystem, "small_fish", 5)
                if small_fish and small_fish_count > max(2, current_blackfish):
                    closest = min(small_fish, key=lambda p: 
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < habitat_factor:
                        closest.die()
                        self.eat(35)
                else:
                    minnows = self._nearby_species(ecosystem, "minnow", 5)
                    if minnows and minnow_count > max(4, current_blackfish * 2):
                        closest = min(minnows, key=lambda p: 
                            abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                        if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < habitat_factor * 0.78:
                            closest.die()
                            self.eat(22)
            elif self.hunger > 45:
                fallback = self._nearby_species(ecosystem, {"shrimp", "frog", "tadpole"}, 4)
                if fallback:
                    closest = min(fallback, key=lambda p:
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < habitat_factor * 0.85:
                        if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                            closest.die()
                            self.eat(24 if closest.species == "shrimp" else 28)
        self.swim(
            ecosystem,
            preferred_body_types={"lake_deep", "lake_shallow"},
            min_oxygen=0.5,
            max_flow=0.55,
            prey_species={"carp", "small_fish"},
            predator_species={"large_fish"},
        )


class Pike(AquaticCreature):
    """狗鱼 - 另一种鲤鱼天敌，游速快"""
    def __init__(self, position, gender=None):
        super().__init__("pike", position, 70, 0.22, 0.05, 3.0, 8)  # 游速更快
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (85, 107, 47)  # 深橄榄绿
        self.emoji = "🐟"

    def _river_ambush_factor(self, ecosystem):
        profile = self._water_profile(ecosystem)
        shoreline = self._shoreline_context(ecosystem)
        factor = 1.0
        if profile:
            if profile.body_type == "river_channel":
                factor += 0.18
            elif profile.body_type == "lake_shallow":
                factor += 0.08
            if 0.52 <= profile.flow_rate <= 0.92:
                factor += 0.08
            if profile.oxygen_level >= 0.58:
                factor += 0.06
        factor += min(0.14, shoreline["mud"] * 0.03 + shoreline["sand"] * 0.02)
        return max(0.9, min(1.35, factor))

    def _spawning_factor(self, ecosystem):
        profile = self._water_profile(ecosystem)
        shoreline = self._shoreline_context(ecosystem)
        factor = 1.0
        if ecosystem.environment.season == "spring":
            factor += 0.24
        if profile:
            if profile.body_type == "river_channel":
                factor += 0.22
            elif profile.body_type == "lake_shallow":
                factor -= 0.06
            if profile.depth_factor <= 0.55:
                factor += 0.08
        factor += min(0.16, shoreline["mud"] * 0.035 + shoreline["sand"] * 0.015)
        return max(0.9, min(1.45, factor))
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        ambush_factor = self._river_ambush_factor(ecosystem)
        spawning_factor = self._spawning_factor(ecosystem)
        metabolism_factor = 0.8 if ecosystem.environment.season == "winter" else 0.9 if ecosystem.environment.season == "autumn" else 1.0
        if metabolism_factor < 1.0:
            self.hunger = max(0, self.hunger - (1.0 - metabolism_factor) * 0.55)
        if profile:
            if profile.body_type == "river_channel":
                self.health = min(100, self.health + 0.14 * ambush_factor)
            if profile.depth_factor > 0.75 and profile.oxygen_level < 0.5:
                self.health -= 1.1
            if profile.body_type == "river_channel" and profile.flow_rate <= 0.95:
                self.hunger = max(0, self.hunger - 0.18)
        if self.hunger > 55: self.health -= 4
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖
        core_prey_count = len([c for c in ecosystem.aquatic_creatures 
                              if c.species in ["small_fish", "minnow", "shrimp", "frog", "tadpole"] and c.alive])
        opportunistic_carp = len([c for c in ecosystem.aquatic_creatures
                                 if c.species == "carp" and c.alive])
        small_fish_count = len([c for c in ecosystem.aquatic_creatures if c.species == "small_fish" and c.alive])
        minnow_count = len([c for c in ecosystem.aquatic_creatures if c.species == "minnow" and c.alive])
        current_pike = len([c for c in ecosystem.aquatic_creatures if c.species == "pike" and c.alive])
        food_factor = max(0.18, min(1.9, (minnow_count * 1.45 + small_fish_count * 0.65 + (core_prey_count - minnow_count - small_fish_count) * 0.8 + opportunistic_carp * 0.18) / max(1, current_pike * 5.0)))
        if current_pike <= 3:
            food_factor = min(2.1, food_factor * 1.5)
        habitat_factor = self._habitat_score(ecosystem, {"river_channel", "lake_shallow"}, min_oxygen=0.58, max_flow=0.9)
        breeding_factor = min(1.7, habitat_factor * spawning_factor)
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 12:
                litter_size = max(1, min(4, int(food_factor * breeding_factor * 2)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("pike", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 22
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [c for c in ecosystem.aquatic_creatures 
                    if c.species == "pike" and c.gender == 'male' and c.alive]
            prey_gate = max(2, int(current_pike * (1.2 if current_pike <= 3 else 1.7)))
            conception_rate = (0.078 if current_pike <= 3 else 0.048) * food_factor * breeding_factor
            if males and (minnow_count + small_fish_count * 0.5 + (core_prey_count - minnow_count - small_fish_count) * 0.4) >= prey_gate and random.random() < conception_rate:
                self.pregnant = True
                
        # 觅食：主抓河道米诺鱼与两栖幼体，鲤鱼只作为机会型猎物
        if self.hunger > 30:
            minnows = self._nearby_species(ecosystem, "minnow", 6)
            if minnows and minnow_count > max(3, current_pike):
                closest = min(minnows, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 6 and random.random() < min(1.0, habitat_factor * ambush_factor):
                    closest.die()
                    self.eat(32)
            else:
                prey_targets = {"frog", "tadpole", "shrimp"}
                if not profile or profile.body_type == "river_channel" or small_fish_count > max(18, current_pike * 5):
                    prey_targets.add("small_fish")
                small_fish = self._nearby_species(ecosystem, prey_targets, 6)
                if small_fish and core_prey_count > max(2, current_pike):
                    closest = min(small_fish, key=lambda p: 
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 6 and random.random() < min(1.0, habitat_factor * ambush_factor):
                        if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                            closest.die()
                            self.eat(24 if closest.species in {"tadpole", "shrimp"} else 30)

        if self.hunger > 45:
            carp = self._nearby_species(ecosystem, "carp", 8)
            if carp and len(carp) >= (2 if current_pike <= 3 else 3) and opportunistic_carp > max(8, current_pike * 3):
                closest = min(carp, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 8 and random.random() < min(0.92, habitat_factor * ambush_factor * 0.9):
                    closest.die()
                    self.eat(48)

        if self.hunger > 48:
            fallback = self._nearby_species(ecosystem, {"water_strider", "frog", "shrimp", "minnow"}, 5)
            if fallback:
                closest = min(fallback, key=lambda p:
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 5 and random.random() < min(0.9, habitat_factor * ambush_factor * 0.9):
                    if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                        closest.die()
                        self.eat(18 if closest.species == "water_strider" else 22 if closest.species == "minnow" else 24)
        self.swim(
            ecosystem,
            preferred_body_types={"river_channel"},
            min_oxygen=0.58,
            max_flow=0.9,
            prey_species={"minnow", "small_fish", "frog", "tadpole", "shrimp"},
        )


class Pufferfish(AquaticCreature):
    """河豚 - 有防御能力"""
    def __init__(self, position, gender=None):
        super().__init__("pufferfish", position, 50, 0.35, 0.08, 1.2, 3)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.inflated = False
        self.color = (255, 200, 100)  # 浅黄棕色
        self.emoji = "🐡"
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile:
            if profile.body_type.startswith("lake") and profile.nutrient_load > 0.5:
                self.health = min(100, self.health + 0.08)
            elif profile.flow_rate > 0.55:
                self.health -= 0.8
        if self.hunger > 50: self.health -= 5
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 10:
                for _ in range(random.randint(2, 4)): ecosystem.spawn_aquatic("pufferfish", self.position)
                self.pregnant = False
        if self.hunger > 25:
            algae = self._nearby_species(ecosystem, {"algae", "shrimp", "plankton"}, 2)
            if algae:
                closest = min(algae, key=lambda a: abs(a.position[0]-self.position[0]) + abs(a.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                    if hasattr(closest, "size"):
                        closest.size -= 0.5
                        if closest.size <= 0:
                            closest.die()
                        self.eat(11 if closest.species == "algae" else 9)
                    else:
                        closest.die()
                        self.eat(14)
        self.swim(
            ecosystem,
            preferred_body_types={"lake_shallow", "river_channel"},
            min_oxygen=0.5,
            max_flow=0.75,
            min_nutrients=0.3,
            prey_species={"algae", "plankton", "seaweed"},
            predator_species={"catfish", "crab", "large_fish", "blackfish"},
        )


# 甲壳类
class Shrimp(AquaticCreature):
    """虾 - 依赖藻类的初级消费者"""
    def __init__(self, position):
        super().__init__("shrimp", position, 32, 0.32, 0.1, 1.0, 2, AquaticType.BENTHIC)
        self.reproduction_cooldown = 0
        self.color = (255, 150, 150)  # 浅粉色
        self.emoji = "🦐"
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        refuge_factor = self._benthic_refuge_score(ecosystem)
        detritus_factor = self._benthic_detritus_factor(ecosystem)
        if profile:
            if profile.body_type in {"lake_shallow", "river_channel"} and profile.nutrient_load > 0.4:
                self.health = min(100, self.health + 0.04 * refuge_factor + 0.03 * detritus_factor)
            if profile.oxygen_level < 0.42:
                self.health -= 1.0
        if self.hunger > 60: self.health -= 3
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        # 🔄 动态繁殖：根据藻类数量调整繁殖率
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        algae_count = len([a for a in ecosystem.aquatic_creatures if a.species == "algae" and a.alive])
        plankton_count = len([a for a in ecosystem.aquatic_creatures if a.species == "plankton" and a.alive])
        seaweed_count = len([a for a in ecosystem.aquatic_creatures if a.species == "seaweed" and a.alive])
        minnow_count = len([a for a in ecosystem.aquatic_creatures if a.species == "minnow" and a.alive])
        current_shrimp = len([s for s in ecosystem.aquatic_creatures if s.species == "shrimp" and s.alive])
        
        # 食物充足度因子
        food_supply = (
            algae_count
            + int(plankton_count * 0.55)
            + int(seaweed_count * 0.35)
            + max(0, int((detritus_factor - 1.0) * 24))
        )
        food_factor = max(0.22, min(2.4, food_supply / max(1, current_shrimp * 2.2)))
        if current_shrimp <= 8:
            food_factor = min(2.6, food_factor * 1.48)
        habitat_factor = self._habitat_score(ecosystem, {"lake_shallow", "river_channel"}, min_oxygen=0.5, max_flow=0.75, min_nutrients=0.3)
        forage_factor = min(1.55, habitat_factor * refuge_factor * detritus_factor)
        
        # 🔄 天敌压力
        predator_count = sum(len([c for c in ecosystem.aquatic_creatures 
                                 if c.species == sp and c.alive]) 
                             for sp in ["catfish", "crab", "large_fish", "blackfish", "pike"])
        predator_pressure = max(0.28, 1.0 - predator_count * 0.045)
        predator_pressure = min(1.18, predator_pressure * max(1.0, refuge_factor * 0.78))
        if minnow_count > max(4, current_shrimp):
            predator_pressure = min(1.28, predator_pressure * 1.08)
        
        # 获取水质
        water_quality = ecosystem.environment.get_water_quality(self.position[0], self.position[1])
        water_factor = 1.0
        if water_quality:
            water_factor = water_quality.oxygen_level
        
        # 🌱 无上限繁殖：只要条件满足就繁殖
        threshold = 5 if current_shrimp <= 8 else 8
        if food_supply > threshold and self.reproduction_cooldown == 0:
            detritus_support = 1.0 + min(0.45, (detritus_factor - 1.0) * 1.05 + (refuge_factor - 1.0) * 0.55)
            effective_rate = self.reproduction_rate * food_factor * water_factor * predator_pressure * habitat_factor * detritus_support
            if random.random() < effective_rate:
                ecosystem.spawn_aquatic("shrimp", self.position)
                self.reproduction_cooldown = 3 if current_shrimp <= 8 else 5
        
        # 吃藻类（但不能吃太多）
        if self.hunger > 20 and food_supply > 4:
            algae = self._nearby_species(ecosystem, {"algae", "plankton", "seaweed"}, 2)
            if algae:
                closest = min(algae, key=lambda a: abs(a.position[0]-self.position[0]) + abs(a.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2 and random.random() < forage_factor:
                    # ⚠️ 不直接杀死藻类，只是减少其大小
                    if hasattr(closest, "size"):
                        closest.size -= 0.22 if closest.species == "seaweed" else 0.24 if closest.species == "algae" else 0.18
                    else:
                        closest.die()
                    if hasattr(closest, "size") and closest.size <= 0:
                        closest.die()
                    self.eat(10)
            elif random.random() < max(0.18, (detritus_factor - 1.0) * 0.45):
                self.eat(8)
        
        self.swim(
            ecosystem,
            preferred_body_types={"lake_shallow", "river_channel"},
            min_oxygen=0.5,
            max_flow=0.75,
            min_nutrients=0.3,
            prey_species={"algae", "plankton", "seaweed"},
            predator_species={"catfish", "crab", "large_fish", "blackfish", "pike"},
        )


class Crab(AquaticCreature):
    """螃蟹 - 捕食虾/小鱼"""
    def __init__(self, position, gender=None):
        super().__init__("crab", position, 45, 0.35, 0.06, 1.0, 3, AquaticType.BENTHIC)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (139, 90, 43)
        self.emoji = "🦀"
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        shoreline = self._shoreline_context(ecosystem)
        if profile and profile.body_type == "lake_shallow":
            self.health = min(100, self.health + 0.05)
        if self.hunger > 50: self.health -= 5
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据猎物数量控制产仔
        prey_count = len([c for c in ecosystem.aquatic_creatures 
                         if c.species in ["shrimp", "small_fish", "tadpole", "plankton"] and c.alive])
        current_crab = len([c for c in ecosystem.aquatic_creatures if c.species == "crab" and c.alive])
        food_factor = max(0.1, min(1.5, prey_count / (current_crab * 3)))
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 12:
                # 🌱 产仔数量由食物决定（不再是固定5-15）
                litter_size = max(2, min(8, int(food_factor * 4)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("crab", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 20
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [c for c in ecosystem.aquatic_creatures 
                    if c.species == "crab" and c.gender == 'male' and c.alive]
            if males and prey_count > current_crab and random.random() < 0.02 * food_factor:
                self.pregnant = True
                
        if self.hunger > 25:
            prey = self._nearby_species(ecosystem, {"shrimp", "small_fish", "tadpole", "plankton"}, 3)
            if prey and prey_count > current_crab:
                closest = min(prey, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                    ambush_factor = self._shoreline_predation_penalty(ecosystem, closest)
                    if random.random() < ambush_factor:
                        closest.die()
                        self.eat(16 if closest.species == "plankton" else 25)
        self.swim(ecosystem)


# 两栖动物
class Frog(AquaticCreature):
    """青蛙 - 水陆两栖，吃浮游生物/昆虫"""
    def __init__(self, position, gender=None):
        super().__init__("frog", position, 35, 0.35, 0.08, 1.8, 5)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (76, 175, 80)
        self.emoji = "🐸"
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if self.hunger > 50: self.health -= 5
        profile = self._water_profile(ecosystem) if self._is_in_water(ecosystem) else None
        if profile and profile.body_type == "lake_shallow":
            self.health = min(100, self.health + 0.05)
        elif profile and profile.body_type == "river_channel":
            self.health = min(100, self.health + 0.08)
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据食物数量控制
        plankton_count = len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        insect_count = len([i for i in ecosystem.animals if i.species in {"insect", "bee"} and i.alive])
        food_count = plankton_count + insect_count
        current_frog = len([f for f in ecosystem.animals if f.species == "frog" and f.alive])
        food_factor = max(0.1, min(1.5, food_count / (current_frog * 3)))
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 10:
                litter_size = max(2, min(8, int(food_factor * 5)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("tadpole", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 15
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [f for f in ecosystem.animals if f.species == "frog" and f.gender == 'male' and f.alive]
            if males and food_count > current_frog * 2 and random.random() < 0.03 * food_factor:
                self.pregnant = True
        
        # 水陆两栖觅食
        if self.hunger > 25:
            if self._is_in_water(ecosystem):
                plankton = self._nearby_species(ecosystem, {"plankton", "tadpole", "water_strider"}, 3)
                if plankton and random.random() < 0.3:
                    plankton[0].die()
                    self.eat(10)
            else:
                insects = [a for a in ecosystem.animals if a.species in {"insect", "bee", "spider"} and a.alive]
                if insects:
                    closest = min(insects, key=lambda i: abs(i.position[0]-self.position[0]) + abs(i.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                        closest.die()
                        self.eat(15)
        
        if random.random() < 0.3:
            dx, dy = random.randint(-3, 3), random.randint(-3, 3)
            self.position = (max(0, min(self.position[0]+dx, ecosystem.width-1)), max(0, min(self.position[1]+dy, ecosystem.height-1)))


class Tadpole(AquaticCreature):
    """蝌蚪 - 青蛙幼体，吃藻类"""
    def __init__(self, position):
        super().__init__("tadpole", position, 10, 0.3, 0, 0.8, 2)
        self.color = (50, 50, 50)
        self.emoji = "🐸"
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        if not self._is_in_water(ecosystem): self.die(); return
        profile = self._water_profile(ecosystem)
        if profile and profile.flow_rate > 0.8 and random.random() < 0.15:
            self.health -= 0.8
        
        # 吃藻类和浮游生物
        if self.hunger > 10:
            algae = self._nearby_species(ecosystem, {"algae", "plankton"}, 2)
            if algae and random.random() < 0.2:
                if hasattr(algae[0], "size"):
                    algae[0].size -= 0.2
                    if algae[0].size <= 0:
                        algae[0].die()
                else:
                    algae[0].die()
                self.eat(5)
        
        # 变态发育
        if self.age >= self.max_age:
            self.die()
            if self._is_in_water(ecosystem): ecosystem.spawn_animal("frog", self.position)
            return
        self.swim(ecosystem)


class WaterStrider(AquaticCreature):
    """水黾 - 水面昆虫，吃浮游生物"""
    def __init__(self, position):
        super().__init__("water_strider", position, 20, 0.5, 0.15, 2.0, 3, AquaticType.SURFACE)
        self.color = (100, 100, 100)
        self.emoji = "🦗"
        self.reproduction_cooldown = 0
        
    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        terrain = ecosystem.environment.get_terrain(self.position[0], self.position[1])
        if terrain not in ["water_shallow", "river"]: self.die(); return
        profile = self._water_profile(ecosystem)
        if profile and profile.body_type == "river_channel":
            self.health = min(100, self.health + 0.06)
        if self.age >= self.max_age: self.die(); return
        
        self.hunger += self.hunger_rate
        if self.hunger > 40: self.health -= 3
        if self.health <= 0: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据浮游生物和表层小型生物数量
        plankton_count = len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        current_ws = len([w for w in ecosystem.aquatic_creatures if w.species == "water_strider" and w.alive])
        food_factor = max(0.1, min(1.5, plankton_count / (current_ws * 2)))
        
        if self.age > 5 and self.reproduction_cooldown == 0 and plankton_count > current_ws:
            if random.random() < self.reproduction_rate * food_factor:
                ecosystem.spawn_aquatic("water_strider", self.position)
                self.reproduction_cooldown = 5
        
        # 吃浮游生物和藻类碎屑
        if self.hunger > 15:
            plankton = self._nearby_species(ecosystem, {"plankton", "algae", "tadpole"}, 3)
            if plankton and random.random() < 0.3:
                if hasattr(plankton[0], "size"):
                    plankton[0].size -= 0.2
                    if plankton[0].size <= 0:
                        plankton[0].die()
                else:
                    plankton[0].die()
                self.eat(10)
        
        self.swim(ecosystem)

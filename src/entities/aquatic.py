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
        self._context_cache = {}
        
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
        key = ("profile", ecosystem.tick_count, self.position[0], self.position[1])
        cached = self._context_cache.get(key)
        if cached is None:
            cached = ecosystem.environment.get_water_quality(self.position[0], self.position[1])
            self._context_cache[key] = cached
        return cached

    def _shoreline_context(self, ecosystem, position=None):
        x, y = position or self.position
        key = ("shoreline", ecosystem.tick_count, x, y)
        cached = self._context_cache.get(key)
        if cached is not None:
            return cached
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
        result = {"mud": mud, "sand": sand, "land": land}
        self._context_cache[key] = result
        return result

    def _benthic_refuge_score(self, ecosystem, position=None):
        query_position = position or self.position
        key = ("refuge", ecosystem.tick_count, query_position[0], query_position[1])
        cached = self._context_cache.get(key)
        if cached is not None:
            return cached
        shoreline = self._shoreline_context(ecosystem, position)
        score = 1.0 + shoreline["mud"] * 0.07 + shoreline["sand"] * 0.03
        if shoreline["land"] >= 2:
            score += 0.05
        result = max(0.9, min(1.35, score))
        self._context_cache[key] = result
        return result

    def _benthic_detritus_factor(self, ecosystem, position=None):
        query_position = position or self.position
        key = ("detritus", ecosystem.tick_count, query_position[0], query_position[1])
        cached = self._context_cache.get(key)
        if cached is not None:
            return cached
        shoreline = self._shoreline_context(ecosystem, position)
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
        result = max(0.95, min(1.45, factor))
        self._context_cache[key] = result
        return result

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
        if hasattr(ecosystem, "get_water_candidate_positions"):
            return list(ecosystem.get_water_candidate_positions(self.position, radius))
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
        return positions[:8]

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

        target_species = set()
        if prey_species:
            target_species.update(prey_species)
        if predator_species:
            target_species.update(predator_species)
        if target_species:
            nearby_radius = max(3, min(5, self.vision_range))
            nearby_counts = ecosystem.count_nearby_aquatic_species(position, nearby_radius, target_species)
            if prey_species:
                prey_count = sum(nearby_counts.get(species, 0) for species in prey_species)
                score += min(0.45, prey_count * 0.06)
            if predator_species:
                predator_count = sum(nearby_counts.get(species, 0) for species in predator_species)
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
        candidates = self._candidate_water_positions(ecosystem, move_radius)
        if len(candidates) > 3:
            cheap_scored = []
            for candidate in candidates:
                quick_score = self._habitat_score_for_position(
                    ecosystem,
                    candidate,
                    preferred_body_types=preferred_body_types,
                    min_oxygen=min_oxygen,
                    max_flow=max_flow,
                    min_nutrients=min_nutrients,
                )
                distance = abs(candidate[0] - self.position[0]) + abs(candidate[1] - self.position[1])
                cheap_scored.append((quick_score - distance * 0.02, candidate))
            candidates = [candidate for _, candidate in sorted(cheap_scored, key=lambda item: item[0], reverse=True)[:3]]

        for candidate in candidates:
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
        current_plankton = ecosystem.get_species_count("plankton") if hasattr(ecosystem, "get_species_count") else len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        density = _density_factor(current_plankton, water_cells * 2.5)
        
        # 🔄 捕食压力补偿
        predator_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in ["small_fish", "shrimp", "tadpole"]
        )
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
                self.health = min(100, self.health + 0.05)
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
        plankton_count = ecosystem.get_species_count("plankton") if hasattr(ecosystem, "get_species_count") else len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        current_smallfish = ecosystem.get_species_count("small_fish") if hasattr(ecosystem, "get_species_count") else len([f for f in ecosystem.aquatic_creatures if f.species == "small_fish" and f.alive])
        
        # 食物因子
        food_factor = max(0.4, min(1.8, plankton_count / max(1, current_smallfish * 1.5)))
        if current_smallfish <= 6:
            food_factor = min(2.0, food_factor * 1.25)
        
        # 天敌压力
        predator_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in self.predators
        )
        predator_pressure = max(0.35, 1.0 - predator_count * 0.04)
        habitat_factor = self._habitat_score(ecosystem, {"river_channel", "lake_shallow"}, min_oxygen=0.55, max_flow=0.95)
        if profile and profile.body_type.startswith("lake"):
            predator_pressure = min(0.92, predator_pressure * 1.18)
            habitat_factor = min(1.35, habitat_factor * 1.12)
        elif profile and profile.body_type == "river_channel":
            predator_pressure = max(0.3, predator_pressure * 0.9)
            habitat_factor = max(0.75, habitat_factor * 0.88)
        
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
            preferred_body_types={"lake_shallow", "lake_deep"},
            min_oxygen=0.55,
            max_flow=0.72,
            prey_species={"plankton", "algae", "water_strider"},
            predator_species=set(self.predators),
        )


class Minnow(AquaticCreature):
    """米诺鱼 - 河道/浅湖中层小型猎物，缓解高位鱼对虾和小鱼的争食。"""
    def __init__(self, position, gender=None):
        super().__init__("minnow", position, 42, 0.24, 0.09, 1.9, 5)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (135, 206, 235)
        self.emoji = "🐠"
        self.predators = ["catfish", "large_fish", "blackfish", "pike", "crab", "kingfisher"]

    def _schooling_factor(self, ecosystem):
        nearby = self._nearby_species(ecosystem, "minnow", 4)
        return max(1.0, min(1.28, 1.0 + len(nearby) * 0.04))

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

        plankton_count = ecosystem.get_species_count("plankton") if hasattr(ecosystem, "get_species_count") else len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        algae_count = ecosystem.get_species_count("algae") if hasattr(ecosystem, "get_species_count") else len([a for a in ecosystem.aquatic_creatures if a.species == "algae" and a.alive])
        shrimp_count = ecosystem.get_species_count("shrimp") if hasattr(ecosystem, "get_species_count") else len([s for s in ecosystem.aquatic_creatures if s.species == "shrimp" and s.alive])
        current_minnow = ecosystem.get_species_count("minnow") if hasattr(ecosystem, "get_species_count") else len([m for m in ecosystem.aquatic_creatures if m.species == "minnow" and m.alive])

        food_supply = plankton_count + algae_count * 0.45 + shrimp_count * 0.25
        food_factor = max(0.35, min(1.55, food_supply / max(1, current_minnow * 2.1)))
        if current_minnow <= 6:
            food_factor = min(1.9, food_factor * 1.34)
        elif current_minnow <= 12:
            food_factor = min(1.72, food_factor * 1.18)
        elif current_minnow <= 24:
            food_factor = min(1.58, food_factor * 1.08)

        predator_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in self.predators
        )
        predator_pressure = max(0.42, 1.0 - predator_count * 0.032)
        if profile and profile.body_type == "river_channel":
            predator_pressure = min(1.04, predator_pressure * (1.05 + (schooling_factor - 1.0) * 0.35))
        if current_minnow <= 6:
            predator_pressure = min(1.28, predator_pressure * 1.22)
        elif current_minnow <= 12:
            predator_pressure = min(1.18, predator_pressure * 1.12)
        habitat_factor = self._habitat_score(
            ecosystem,
            {"river_channel", "lake_shallow"},
            min_oxygen=0.56,
            max_flow=0.92,
            min_nutrients=0.26,
        )
        if profile and profile.body_type == "river_channel":
            habitat_factor = min(1.42, habitat_factor * 1.14 * refuge_factor)

        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 7:
                litter_size = max(1, min(2, int(food_factor * predator_pressure * habitat_factor * 2.2)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("minnow", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 10

        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            male_count = ecosystem.get_gender_count("minnow", "male") if hasattr(ecosystem, "get_gender_count") else len([m for m in ecosystem.aquatic_creatures if m.species == "minnow" and m.gender == 'male' and m.alive])
            spawn_gate = 2 if current_minnow <= 8 else 4 if current_minnow <= 16 else 7
            if ecosystem.environment.season == "spring":
                spawn_gate = max(3, spawn_gate - 1)
            if profile and profile.body_type == "river_channel":
                spawn_gate = max(2, spawn_gate - 1)
            if male_count and food_supply > spawn_gate:
                chance = (0.12 if current_minnow <= 6 else 0.095 if current_minnow <= 12 else 0.06 if current_minnow <= 24 else 0.045) * food_factor * predator_pressure * habitat_factor
                if ecosystem.environment.season == "spring":
                    chance *= 1.06
                if profile and profile.body_type == "river_channel":
                    chance *= 1.04
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
        food_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in ["plankton", "algae"]
        )
        current_carp = ecosystem.get_species_count("carp") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "carp" and c.alive])
        food_factor = max(0.25, min(1.8, food_count / max(1, current_carp * 1.5)))
        if current_carp <= 6:
            food_factor = min(2.0, food_factor * 1.3)
        
        # 计算天敌压力
        predator_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in self.predators
        )
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
        super().__init__("catfish", position, 80, 0.37, 0.028, 1.5, 4, AquaticType.BENTHIC)
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
        prey_count = sum(
            ecosystem.get_sustainable_population(sp) if hasattr(ecosystem, "get_sustainable_population") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in ["small_fish", "minnow", "shrimp", "carp"]
        )
        small_fish_count = ecosystem.get_species_count("small_fish") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "small_fish" and c.alive])
        current_catfish = ecosystem.get_species_count("catfish") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "catfish" and c.alive])
        food_factor = max(0.14, min(1.12, prey_count / max(1, current_catfish * 4.2)))
        spawning_factor = self._spawning_factor(ecosystem)
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 12:
                # 🌱 产仔数量由猎物决定
                litter_size = max(1, min(2, int(food_factor * spawning_factor * 1.9)))
                for _ in range(litter_size): 
                    ecosystem.spawn_aquatic("catfish", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 18
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            male_count = ecosystem.get_gender_count("catfish", "male") if hasattr(ecosystem, "get_gender_count") else len([c for c in ecosystem.aquatic_creatures 
                    if c.species == "catfish" and c.gender == 'male' and c.alive])
            # 猎物充足时才受孕
            prey_gate = max(3, int(current_catfish * (0.9 if current_catfish <= 4 else 1.1)))
            if male_count and prey_count > prey_gate and random.random() < 0.018 * food_factor * spawning_factor:
                self.pregnant = True
                
        if self.hunger > 20:
            prey_targets = {"shrimp", "carp", "frog", "tadpole"}
            if (not profile or profile.body_type == "river_channel") and small_fish_count > max(18, current_catfish * 5):
                prey_targets.add("small_fish")
            prey = self._nearby_species(ecosystem, prey_targets, 3)
            if prey and prey_count > current_catfish:
                closest = min(prey, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                chance = ecosystem.get_predation_chance("catfish", closest.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2 and random.random() < min(0.66, chance):
                    if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                        closest.die()
                        self.eat(24 if closest.species in {"shrimp", "tadpole"} else 32)
            elif self.hunger > 38:
                minnows = self._nearby_species(ecosystem, "minnow", 3)
                if minnows and prey_count > current_catfish * 2 and len(minnows) > max(5, current_catfish * 3):
                    closest = min(minnows, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    chance = ecosystem.get_predation_chance("catfish", "minnow", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2 and random.random() < min(0.44, chance):
                        closest.die()
                        self.eat(28)
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
        super().__init__("large_fish", position, 80, 0.26, 0.028, 2.0, 6)
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
        prey_count = sum(
            ecosystem.get_sustainable_population(sp) if hasattr(ecosystem, "get_sustainable_population") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in ["small_fish", "minnow", "carp", "shrimp"]
        )
        current_predator = len([c for c in ecosystem.aquatic_creatures 
                               if c.species == "large_fish" and c.alive])
        
        # 食物充足度：猎物数量相对于捕食者数量
        food_factor = max(0.14, min(1.12, prey_count / max(1, current_predator * 4.4)))
        if current_predator <= 2:
            food_factor = min(1.45, food_factor * 1.10)
        if profile and profile.body_type.startswith("lake"):
            food_factor = min(1.75, food_factor * 1.10)
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 12:
                # 🌱 自然繁殖：产仔数量取决于猎物充足度
                litter_size = max(1, min(2, int(food_factor * 2.0)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("large_fish", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 20
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            males = [c for c in ecosystem.aquatic_creatures 
                    if c.species == "large_fish" and c.gender == 'male' and c.alive]
            # 猎物充足时才繁殖
            prey_gate = max(2, int(current_predator * 1.2))
            conception_rate = (0.024 if current_predator <= 2 else 0.018) * food_factor
            if males and prey_count >= prey_gate and random.random() < conception_rate:
                self.pregnant = True
                
        # 觅食：优先吃鲤鱼（控制鲤鱼数量）
        if self.hunger > 30:
            # 优先捕食鲤鱼
            carp = self._nearby_species(ecosystem, "carp", 6)
            if carp and random.random() < 0.38 and len(carp) > 2:
                closest = min(carp, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                chance = ecosystem.get_predation_chance("large_fish", "carp", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 5 and random.random() < min(0.64, chance):
                    closest.die()
                    self.eat(50)
            else:
                # 没有鲤鱼就先吃米诺鱼，再吃其他中层猎物
                minnows = self._nearby_species(ecosystem, "minnow", 4)
                if minnows and prey_count > current_predator and len(minnows) > max(2, current_predator * 2):
                    closest = min(minnows, key=lambda p:
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    chance = ecosystem.get_predation_chance("large_fish", "minnow", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < min(0.62, chance):
                        closest.die()
                        self.eat(36)
                else:
                    prey = self._nearby_species(ecosystem, {"small_fish", "shrimp", "frog", "tadpole"}, 4)
                    if prey and prey_count > current_predator:
                        closest = min(prey, key=lambda p: 
                            abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                        chance = ecosystem.get_predation_chance("large_fish", closest.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                        if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < min(0.66, chance):
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
        minnow_count = len([c for c in ecosystem.aquatic_creatures if c.species == "minnow" and c.alive])
        profile = self._water_profile(ecosystem)
        metabolism_factor = self._seasonal_metabolism_factor(ecosystem)
        if metabolism_factor < 1.0:
            self.hunger = max(0, self.hunger - (1.0 - metabolism_factor) * 0.5)
        if profile:
            if profile.body_type.startswith("lake") and profile.depth_factor > 0.7:
                self.health = min(100, self.health + 0.12)
            elif profile.body_type == "lake_shallow" and minnow_count > 10:
                self.health = min(100, self.health + 0.06)
            if profile.flow_rate > 0.65:
                self.health -= 1.3
        if self.hunger > 60: self.health -= 3
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据鲤鱼数量决定繁殖
        carp_count = ecosystem.get_species_count("carp") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "carp" and c.alive])
        small_fish_count = ecosystem.get_species_count("small_fish") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "small_fish" and c.alive])
        current_blackfish = ecosystem.get_species_count("blackfish") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "blackfish" and c.alive])
        sustainable_carp = ecosystem.get_sustainable_population("carp") if hasattr(ecosystem, "get_sustainable_population") else carp_count
        sustainable_small = ecosystem.get_sustainable_population("small_fish") if hasattr(ecosystem, "get_sustainable_population") else small_fish_count
        sustainable_minnow = ecosystem.get_sustainable_population("minnow") if hasattr(ecosystem, "get_sustainable_population") else minnow_count
        
        food_factor = max(0.12, min(1.55, (sustainable_carp * 2.0 + sustainable_small * 0.9 + sustainable_minnow * 0.55) / max(1, current_blackfish * 7)))
        if current_blackfish <= 3:
            food_factor = min(1.85, food_factor * 1.42)
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
            male_count = ecosystem.get_gender_count("blackfish", "male") if hasattr(ecosystem, "get_gender_count") else len([c for c in ecosystem.aquatic_creatures 
                    if c.species == "blackfish" and c.gender == 'male' and c.alive])
            # 鲤鱼充足时才繁殖
            prey_gate = max(3, current_blackfish * (2 if current_blackfish <= 3 else 3))
            if male_count and (sustainable_carp * 1.4 + sustainable_small + sustainable_minnow * 0.45) > prey_gate and random.random() < (0.055 if current_blackfish <= 3 else 0.032) * food_factor * habitat_factor:
                self.pregnant = True
                
        # 觅食：专门捕食鲤鱼
        if self.hunger > 25:
            carp = self._nearby_species(ecosystem, "carp", 7)
            local_carp_pressure = len(carp)
            carp_chance = ecosystem.get_predation_chance("blackfish", "carp", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
            if carp and sustainable_carp > max(1, current_blackfish) and local_carp_pressure >= (2 if current_blackfish <= 3 else 3):
                closest = min(carp, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 6 and random.random() < min(habitat_factor, carp_chance):
                    closest.die()
                    self.eat(60)  # 鲤鱼营养价值高
            # 没有鲤鱼时也吃小鱼
            elif self.hunger > 35:
                small_fish = self._nearby_species(ecosystem, "small_fish", 5)
                small_fish_chance = ecosystem.get_predation_chance("blackfish", "small_fish", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if small_fish and sustainable_small > max(1, current_blackfish):
                    closest = min(small_fish, key=lambda p: 
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < min(habitat_factor, small_fish_chance):
                        closest.die()
                        self.eat(35)
                else:
                    minnows = self._nearby_species(ecosystem, "minnow", 5)
                    minnow_chance = ecosystem.get_predation_chance("blackfish", "minnow", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                    if minnows and sustainable_minnow > max(2, current_blackfish * 2):
                        closest = min(minnows, key=lambda p: 
                            abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                        if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < min(habitat_factor * 0.78, minnow_chance):
                            closest.die()
                            self.eat(22)
            elif self.hunger > 45:
                fallback = self._nearby_species(ecosystem, {"shrimp", "frog", "tadpole"}, 4)
                if fallback:
                    closest = min(fallback, key=lambda p:
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    fallback_chance = ecosystem.get_predation_chance("blackfish", closest.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 4 and random.random() < min(habitat_factor * 0.85, fallback_chance):
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
        minnow_count = len([c for c in ecosystem.aquatic_creatures if c.species == "minnow" and c.alive])
        profile = self._water_profile(ecosystem)
        ambush_factor = self._river_ambush_factor(ecosystem)
        spawning_factor = self._spawning_factor(ecosystem)
        metabolism_factor = 0.8 if ecosystem.environment.season == "winter" else 0.9 if ecosystem.environment.season == "autumn" else 1.0
        if metabolism_factor < 1.0:
            self.hunger = max(0, self.hunger - (1.0 - metabolism_factor) * 0.55)
        if profile:
            if profile.body_type == "river_channel":
                self.health = min(100, self.health + 0.14 * ambush_factor)
            elif profile.body_type == "lake_shallow" and minnow_count > 8:
                self.health = min(100, self.health + 0.07 * ambush_factor)
            if profile.depth_factor > 0.75 and profile.oxygen_level < 0.5:
                self.health -= 1.1
            if profile.body_type == "river_channel" and profile.flow_rate <= 0.95:
                self.hunger = max(0, self.hunger - 0.18)
            elif profile.body_type == "lake_shallow":
                self.hunger = max(0, self.hunger - 0.08)
        if self.hunger > 55: self.health -= 4
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖
        core_prey_count = sum((ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])) for sp in ["small_fish", "minnow", "shrimp", "frog", "tadpole"])
        opportunistic_carp = ecosystem.get_species_count("carp") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "carp" and c.alive])
        small_fish_count = ecosystem.get_species_count("small_fish") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "small_fish" and c.alive])
        current_pike = ecosystem.get_species_count("pike") if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == "pike" and c.alive])
        sustainable_minnow = ecosystem.get_sustainable_population("minnow") if hasattr(ecosystem, "get_sustainable_population") else minnow_count
        sustainable_small = ecosystem.get_sustainable_population("small_fish") if hasattr(ecosystem, "get_sustainable_population") else small_fish_count
        sustainable_frog = ecosystem.get_sustainable_population("frog") if hasattr(ecosystem, "get_sustainable_population") else len([c for c in ecosystem.animals if c.species == "frog" and c.alive])
        sustainable_shrimp = ecosystem.get_sustainable_population("shrimp") if hasattr(ecosystem, "get_sustainable_population") else len([c for c in ecosystem.aquatic_creatures if c.species == "shrimp" and c.alive])
        sustainable_tadpole = ecosystem.get_sustainable_population("tadpole") if hasattr(ecosystem, "get_sustainable_population") else len([c for c in ecosystem.aquatic_creatures if c.species == "tadpole" and c.alive])
        sustainable_carp = ecosystem.get_sustainable_population("carp") if hasattr(ecosystem, "get_sustainable_population") else opportunistic_carp
        effective_core = sustainable_minnow + sustainable_small + sustainable_frog + sustainable_shrimp + sustainable_tadpole
        food_factor = max(0.15, min(1.55, (sustainable_minnow * 1.45 + sustainable_small * 0.65 + (effective_core - sustainable_minnow - sustainable_small) * 0.8 + sustainable_carp * 0.18) / max(1, current_pike * 5.0)))
        if current_pike <= 3:
            food_factor = min(1.85, food_factor * 1.38)
        habitat_factor = self._habitat_score(ecosystem, {"river_channel", "lake_shallow"}, min_oxygen=0.58, max_flow=0.9)
        breeding_factor = min(1.75, habitat_factor * spawning_factor)
        if profile and profile.body_type == "lake_shallow" and minnow_count > 10:
            breeding_factor = min(1.9, breeding_factor * 1.12)
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 12:
                litter_size = max(1, min(4, int(food_factor * breeding_factor * 2)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("pike", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 22
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            male_count = ecosystem.get_gender_count("pike", "male") if hasattr(ecosystem, "get_gender_count") else len([c for c in ecosystem.aquatic_creatures 
                    if c.species == "pike" and c.gender == 'male' and c.alive])
            prey_gate = max(3, int(current_pike * (1.4 if current_pike <= 3 else 1.9)))
            conception_rate = (0.038 if current_pike <= 3 else 0.022) * food_factor * breeding_factor
            if male_count and (sustainable_minnow + sustainable_small * 0.5 + (effective_core - sustainable_minnow - sustainable_small) * 0.4) >= prey_gate and random.random() < conception_rate:
                self.pregnant = True
                
        # 觅食：主抓河道米诺鱼与两栖幼体，鲤鱼只作为机会型猎物
        if self.hunger > 30:
            minnows = self._nearby_species(ecosystem, "minnow", 6)
            minnow_chance = ecosystem.get_predation_chance("pike", "minnow", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
            if minnows and sustainable_minnow > max(12, current_pike * 3):
                closest = min(minnows, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 6 and random.random() < min(0.52, habitat_factor * ambush_factor * 0.72, minnow_chance):
                    closest.die()
                    self.eat(32)
            else:
                prey_targets = {"frog", "tadpole", "shrimp"}
                if not profile or profile.body_type == "river_channel" or small_fish_count > max(18, current_pike * 5):
                    prey_targets.add("small_fish")
                small_fish = self._nearby_species(ecosystem, prey_targets, 6)
                if small_fish and effective_core > max(2, current_pike):
                    closest = min(small_fish, key=lambda p: 
                        abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    prey_chance = ecosystem.get_predation_chance("pike", closest.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 6 and random.random() < min(0.9, habitat_factor * ambush_factor, prey_chance):
                        if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                            closest.die()
                            self.eat(24 if closest.species in {"tadpole", "shrimp"} else 30)

        if self.hunger > 45:
            carp = self._nearby_species(ecosystem, "carp", 8)
            if carp and len(carp) >= (2 if current_pike <= 3 else 3) and sustainable_carp > max(4, current_pike * 2):
                closest = min(carp, key=lambda p: 
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                carp_chance = ecosystem.get_predation_chance("pike", "carp", self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 8 and random.random() < min(0.92, habitat_factor * ambush_factor * 0.9, carp_chance):
                    closest.die()
                    self.eat(48)

        if self.hunger > 48:
            fallback = self._nearby_species(ecosystem, {"water_strider", "frog", "shrimp", "minnow"}, 5)
            if fallback:
                closest = min(fallback, key=lambda p:
                    abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                fallback_chance = ecosystem.get_predation_chance("pike", closest.species, self.hunger) if hasattr(ecosystem, "get_predation_chance") else 1.0
                if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 5 and random.random() < min(0.82, habitat_factor * ambush_factor * 0.88, fallback_chance):
                    if random.random() < self._shoreline_predation_penalty(ecosystem, closest):
                        closest.die()
                        self.eat(18 if closest.species == "water_strider" else 22 if closest.species == "minnow" else 24)
        self.swim(
            ecosystem,
            preferred_body_types={"river_channel", "lake_shallow"},
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
        
        algae_count = ecosystem.get_species_count("algae") if hasattr(ecosystem, "get_species_count") else len([a for a in ecosystem.aquatic_creatures if a.species == "algae" and a.alive])
        plankton_count = ecosystem.get_species_count("plankton") if hasattr(ecosystem, "get_species_count") else len([a for a in ecosystem.aquatic_creatures if a.species == "plankton" and a.alive])
        seaweed_count = ecosystem.get_species_count("seaweed") if hasattr(ecosystem, "get_species_count") else len([a for a in ecosystem.aquatic_creatures if a.species == "seaweed" and a.alive])
        minnow_count = ecosystem.get_species_count("minnow") if hasattr(ecosystem, "get_species_count") else len([a for a in ecosystem.aquatic_creatures if a.species == "minnow" and a.alive])
        current_shrimp = ecosystem.get_species_count("shrimp") if hasattr(ecosystem, "get_species_count") else len([s for s in ecosystem.aquatic_creatures if s.species == "shrimp" and s.alive])
        
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
        predator_count = sum(
            ecosystem.get_species_count(sp) if hasattr(ecosystem, "get_species_count") else len([c for c in ecosystem.aquatic_creatures if c.species == sp and c.alive])
            for sp in ["catfish", "crab", "large_fish", "blackfish", "pike"]
        )
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
        super().__init__("frog", position, 50, 0.13, 0.20, 2.2, 6)
        self.gender = gender or random.choice(['male', 'female'])
        self.pregnant = False
        self.pregnancy_timer = 0
        self.reproduction_cooldown = 0
        self.color = (76, 175, 80)
        self.emoji = "🐸"
        self.amphibious = True
        self.predators = {"snake", "fox", "eagle", "owl", "blackfish", "pike"}

    def _move_towards_edge(self, ecosystem, prefer_water: bool):
        best = None
        best_score = -10_000
        for dx in range(-3, 4):
            for dy in range(-3, 4):
                nx = max(0, min(self.position[0] + dx, ecosystem.width - 1))
                ny = max(0, min(self.position[1] + dy, ecosystem.height - 1))
                is_water = ecosystem.environment.is_water(nx, ny)
                if prefer_water and not is_water:
                    continue
                if not prefer_water and is_water:
                    continue
                score = ecosystem.get_adjacent_water_score((nx, ny), radius=1) if hasattr(ecosystem, "get_adjacent_water_score") else 0.0
                score -= (abs(dx) + abs(dy)) * 0.18
                if score > best_score:
                    best_score = score
                    best = (nx, ny)
        if best and best != self.position:
            self.position = best
            if hasattr(ecosystem, "refresh_spatial_entity"):
                ecosystem.refresh_spatial_entity(self)

    def _escape_predators(self, ecosystem) -> bool:
        nearby_land = ecosystem.get_nearby_animals(self.position, 6)
        nearby_water = ecosystem.get_nearby_aquatic(self.position, 6)
        predators = [c for c in nearby_land if c.alive and c.species in self.predators]
        predators.extend(c for c in nearby_water if c.alive and c.species in self.predators)
        if not predators:
            return False

        closest = min(predators, key=lambda p: abs(p.position[0] - self.position[0]) + abs(p.position[1] - self.position[1]))
        aquatic_threat = closest.species in {"blackfish", "pike"}
        self._move_towards_edge(ecosystem, prefer_water=not aquatic_threat)
        dx = self.position[0] - closest.position[0]
        dy = self.position[1] - closest.position[1]
        move_x = 1 if dx >= 0 else -1
        move_y = 1 if dy >= 0 else -1
        self.position = (
            max(0, min(self.position[0] + move_x, ecosystem.width - 1)),
            max(0, min(self.position[1] + move_y, ecosystem.height - 1)),
        )
        if hasattr(ecosystem, "refresh_spatial_entity"):
            ecosystem.refresh_spatial_entity(self)
        return True

    def execute_behavior(self, ecosystem):
        if not self.alive: return
        self.age += 1
        self.hunger += self.hunger_rate
        if self.hunger > 64: self.health -= 3.2
        profile = self._water_profile(ecosystem) if self._is_in_water(ecosystem) else None
        wetland_support = ecosystem.get_local_microhabitat_value(self.position, {"wetland_patch", "riparian_perch"}, radius=4) if hasattr(ecosystem, "get_local_microhabitat_value") else 0.0
        hatch_support = ecosystem.get_local_microhabitat_value(self.position, {"shore_hatch"}, radius=4) if hasattr(ecosystem, "get_local_microhabitat_value") else 0.0
        if profile and profile.body_type == "lake_shallow":
            self.health = min(100, self.health + 0.08)
        elif profile and profile.body_type == "river_channel":
            self.health = min(100, self.health + 0.10)
        if wetland_support > 0:
            self.hunger = max(0, self.hunger - min(1.8, wetland_support * 1.0))
            self.health = min(100, self.health + min(0.8, wetland_support * 0.24))
        if hatch_support > 0:
            self.hunger = max(0, self.hunger - min(0.7, hatch_support * 0.38))
        if self.health <= 0 or self.age >= self.max_age: self.die(); return
        
        if self.reproduction_cooldown > 0:
            self.reproduction_cooldown -= 1
        
        # 🔄 动态繁殖：根据食物数量控制
        plankton_count = ecosystem.get_species_count("plankton") if hasattr(ecosystem, "get_species_count") else len([p for p in ecosystem.aquatic_creatures if p.species == "plankton" and p.alive])
        insect_count = (ecosystem.get_species_count("insect") + ecosystem.get_species_count("bee")) if hasattr(ecosystem, "get_species_count") else len([i for i in ecosystem.animals if i.species in {"insect", "bee"} and i.alive])
        food_count = plankton_count + insect_count + int(hatch_support * 7)
        current_frog = ecosystem.get_species_count("frog") if hasattr(ecosystem, "get_species_count") else len([f for f in ecosystem.animals if f.species == "frog" and f.alive])
        food_factor = max(0.20, min(2.0, food_count / max(1, current_frog * 2.1)))
        if current_frog <= 8:
            food_factor = min(2.35, food_factor * 1.32)
        elif current_frog <= 16:
            food_factor = min(2.05, food_factor * 1.12)
        wetland_factor = max(0.72, min(1.46, 0.78 + wetland_support * 0.72 + hatch_support * 0.12))
        
        if self.pregnant:
            self.pregnancy_timer += 1
            if self.pregnancy_timer >= 10:
                litter_size = max(2, min(7, int(food_factor * wetland_factor * 4.2)))
                for _ in range(litter_size):
                    ecosystem.spawn_aquatic("tadpole", self.position)
                self.pregnant = False
                self.reproduction_cooldown = 12
        
        elif self.gender == 'female' and self.reproduction_cooldown == 0:
            male_count = ecosystem.get_gender_count("frog", "male") if hasattr(ecosystem, "get_gender_count") else len([f for f in ecosystem.animals if f.species == "frog" and f.gender == 'male' and f.alive])
            if male_count and wetland_support >= 0.06 and food_count > max(6, int(current_frog * 1.35)) and random.random() < 0.042 * food_factor * wetland_factor:
                self.pregnant = True

        if self._escape_predators(ecosystem):
            if self.hunger > 36:
                self.eat(3)
            return

        # 水陆两栖觅食
        if self.hunger > 25:
            if self._is_in_water(ecosystem):
                plankton = self._nearby_species(ecosystem, {"plankton", "tadpole", "water_strider", "algae"}, 4)
                if plankton and random.random() < 0.75:
                    target = min(plankton, key=lambda p: abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
                    if hasattr(target, "size"):
                        target.size -= 0.22
                        if target.size <= 0:
                            target.die()
                    else:
                        target.die()
                    self.eat(12 if target.species != "algae" else 8)
            else:
                insects = [a for a in ecosystem.animals if a.species in {"insect", "bee", "spider"} and a.alive]
                if insects:
                    closest = min(insects, key=lambda i: abs(i.position[0]-self.position[0]) + abs(i.position[1]-self.position[1]))
                    self.move_towards(closest.position, ecosystem)
                    if abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1]) <= 2:
                        closest.die()
                        self.eat(15)
                elif random.random() < 0.30:
                    if hatch_support > 0.18 and hasattr(ecosystem, "consume_microhabitat"):
                        consumed = ecosystem.consume_microhabitat({"shore_hatch"}, self.position, 0.08, radius=3)
                        if consumed > 0:
                            self.eat(6)
                        else:
                            self.eat(5)
                    else:
                        self.eat(5)

        if self.hunger > 18 and not self._is_in_water(ecosystem):
            self._move_towards_edge(ecosystem, prefer_water=False)
        elif ecosystem.environment.hour >= 18 or ecosystem.environment.hour < 7:
            self._move_towards_edge(ecosystem, prefer_water=False)
        else:
            self._move_towards_edge(ecosystem, prefer_water=True)

        if random.random() < 0.25:
            dx, dy = random.randint(-2, 2), random.randint(-2, 2)
            self.position = (max(0, min(self.position[0]+dx, ecosystem.width-1)), max(0, min(self.position[1]+dy, ecosystem.height-1)))
            if hasattr(ecosystem, "refresh_spatial_entity"):
                ecosystem.refresh_spatial_entity(self)


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

"""
杂食动物模块 - 新增物种
"""
from typing import Tuple, List
import random
from enum import Enum
from .animals import Animal, Gender


def _social_group_birth(animal: Animal, ecosystem, social_factor: float, stable_label: str, unstable_label: str):
    """将社群稳定度接入产仔规模与产后恢复。"""
    if not animal.pregnant:
        return

    species_counts = (
        ecosystem._latest_species_counts
        if hasattr(ecosystem, "_latest_species_counts") and ecosystem._latest_species_counts
        else None
    )

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

    if animal.diet == "herbivore":
        if species_counts is not None and hasattr(ecosystem, "PLANT_SPECIES"):
            food_count = sum(species_counts.get(sp, 0) for sp in ecosystem.PLANT_SPECIES)
        else:
            food_count = len([p for p in ecosystem.plants if p.alive])
        food_factor = max(0.2, min(1.5, food_count / max(1, diet_count("herbivore")) / 2))
    elif animal.diet == "carnivore":
        prey_species = animal.get_prey_species() if hasattr(animal, "get_prey_species") else []
        if hasattr(ecosystem, "get_sustainable_population"):
            food_count = sum(ecosystem.get_sustainable_population(sp) for sp in prey_species)
        else:
            food_count = sum(species_count(sp) for sp in prey_species)
        food_factor = max(0.1, min(1.5, food_count / max(1, diet_count("carnivore")) / 3))
    else:
        if species_counts is not None and hasattr(ecosystem, "PLANT_SPECIES"):
            food_count = sum(species_counts.get(sp, 0) for sp in ecosystem.PLANT_SPECIES)
        else:
            food_count = len([p for p in ecosystem.plants if p.alive])
        food_factor = max(0.2, min(1.5, food_count / max(1, diet_count("omnivore")) / 2))

    predator_pressure = 1.0
    if hasattr(animal, "get_predators"):
        predator_count = sum(species_count(sp) for sp in animal.get_predators())
        predator_pressure = max(0.3, 1.0 - predator_count * 0.05)

    patch_factor = 1.0
    preferred_kinds = animal.breeding_microhabitat_kinds()
    if preferred_kinds and hasattr(ecosystem, "get_local_microhabitat_value"):
        patch_value = ecosystem.get_local_microhabitat_value(animal.position, preferred_kinds, radius=4)
        patch_factor = max(0.2, min(1.4, patch_value))
        if patch_value < animal.breeding_patch_threshold():
            animal.pregnant = False
            animal.pregnancy_timer = 0
            animal.mate_cooldown = max(animal.mate_cooldown, 8)
            return

    base_litter = random.randint(1, 3)
    litter_size = max(1, min(6, int(round(base_litter * food_factor * predator_pressure * patch_factor * social_factor))))

    for _ in range(litter_size):
        offspring_pos = (
            animal.position[0] + random.randint(-2, 2),
            animal.position[1] + random.randint(-2, 2)
        )
        offspring_pos = (
            max(0, min(offspring_pos[0], ecosystem.width - 1)),
            max(0, min(offspring_pos[1], ecosystem.height - 1))
        )
        ecosystem.spawn_animal(animal.species, offspring_pos, is_offspring=True)

    animal.pregnant = False
    animal.pregnancy_timer = 0
    postpartum_cooldown = max(18, min(36, int(round(30 - (social_factor - 1.0) * 12))))
    animal.mate_cooldown = postpartum_cooldown

    support_label = stable_label if social_factor >= 1.0 else unstable_label

    ecosystem.balance.record_causal_event(
        cause=f"{animal.species}产仔",
        effect=f"{animal.species}+{litter_size} ({support_label})",
        impact=0.2 + max(0.0, social_factor - 1.0) * 0.05,
        tick=ecosystem.tick_count
    )
    ecosystem.log_event(f"{animal.id} gave birth to {litter_size} offspring ({support_label})")


class Bear(Animal):
    """熊 - 大型杂食动物，什么都吃"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="bear",
            position=position,
            max_age=120,
            hunger_rate=0.25,
            reproduction_rate=0.03,
            speed=2.5,
            vision_range=10,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐻"
        self.color = (139, 90, 43)
        self.pregnancy_duration = 20
        self.dominance = 1.5  # 高支配力
        self.hibernating = False
        
    def get_predators(self) -> List[str]:
        return []  # 熊没有天敌
        
    def get_food_sources(self) -> List[str]:
        # 熊吃各种果实和植物
        return ["apple_tree", "cherry_tree", "blueberry", "strawberry", 
                "grape_vine", "orange_tree", "watermelon", "berry",
                "bush", "flower", "moss", "grass", "mushroom", "fern"]
        
    def get_prey_species(self) -> List[str]:
        # 熊也捕食动物
        return ["small_fish", "carp", "rabbit", "mouse", "insect", "frog", "bee", "duck", "swan", "shrimp"]
        
    def execute_behavior(self, ecosystem):
        """熊冬季冬眠"""
        if ecosystem.environment.season == "winter":
            self.hibernating = True
            self.hunger_rate = 0.05  # 冬眠时消耗少
            return  # 冬眠不活动
        else:
            self.hibernating = False
            self.hunger_rate = 0.25
        super().execute_behavior(ecosystem)
        
    def hunt(self, prey, ecosystem):
        """熊捕食"""
        prey.die()
        nutrition = 40
        self.eat(nutrition)


class Beaver(Animal):
    """河狸 - 半水生湿地工程师。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="beaver",
            position=position,
            max_age=65,
            hunger_rate=0.22,
            reproduction_rate=0.05,
            speed=1.6,
            vision_range=5,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦫"
        self.color = (130, 92, 55)
        self.pregnancy_duration = 12
        self.dam_build_interval = random.randint(10, 16)
        self._dam_timer = 0

    def get_predators(self) -> List[str]:
        return ["wolf", "fox", "bear", "eagle"]

    def get_food_sources(self) -> List[str]:
        return [
            "tree", "apple_tree", "cherry_tree", "orange_tree",
            "grass", "moss", "fern", "bush", "berry"
        ]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "apple_tree", "cherry_tree", "orange_tree", "bush", "berry", "moss", "fern"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_water_edge_cover(self) -> bool:
        return True

    def prefers_shrub_cover(self) -> bool:
        return True

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"wetland_patch", "riparian_perch"},
            "amount": 0.10,
            "radius": 3,
            "hunger_relief": 7.0,
            "health_gain": 1.2,
            "min_hunger": 15.0,
        }

    def execute_behavior(self, ecosystem):
        self._dam_timer += 1
        super().execute_behavior(ecosystem)
        if self.alive and self._dam_timer >= self.dam_build_interval:
            self._dam_timer = 0
            self._engineer_habitat(ecosystem)

    def _engineer_habitat(self, ecosystem):
        water_score = ecosystem.get_adjacent_water_score(self.position, radius=2) if hasattr(ecosystem, "get_adjacent_water_score") else 0.0
        wetland_value = ecosystem.get_local_microhabitat_value(self.position, {"wetland_patch", "riparian_perch"}, radius=3) if hasattr(ecosystem, "get_local_microhabitat_value") else 0.0
        if water_score <= 0 and wetland_value < 0.08:
            return

        if hasattr(ecosystem, "get_microhabitat_patches"):
            patches = ecosystem.get_microhabitat_patches({"wetland_patch", "riparian_perch"}, self.position, radius=3)
            for patch in patches[:4]:
                patch.available = min(patch.capacity * max(1.0, patch.seasonal_multiplier), patch.available + 0.18)
                patch.occupancy = min(patch.capacity, patch.occupancy + 0.05)

        # 轻量持久化效果：在水边补植湿地植物，下一轮会转化成稳定微栖位。
        if random.random() < 0.45:
            candidate = ecosystem._random_water_adjacent_position()
            if candidate and abs(candidate[0] - self.position[0]) + abs(candidate[1] - self.position[1]) <= 6:
                plant_species = "moss" if random.random() < 0.6 else "fern"
                ecosystem.spawn_plant(plant_species, candidate, source="natural")

        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} reinforced a wetland corridor")


class Hippopotamus(Animal):
    """河马 - 大型半水生草食动物，连接陆水营养循环。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="hippopotamus",
            position=position,
            max_age=95,
            hunger_rate=0.20,
            reproduction_rate=0.035,
            speed=1.7,
            vision_range=5,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦛"
        self.color = (122, 104, 117)
        self.pregnancy_duration = 20
        self.nutrient_cycle_interval = random.randint(7, 12)
        self._nutrient_timer = 0

    def get_predators(self) -> List[str]:
        return ["crocodile", "lion"]

    def get_food_sources(self) -> List[str]:
        return ["grass", "moss", "fern", "flower", "bush", "reed", "berry"]

    def get_cover_plant_species(self) -> List[str]:
        return ["moss", "fern", "bush", "tree", "berry"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_water_edge_cover(self) -> bool:
        return True

    def breeding_microhabitat_kinds(self) -> List[str]:
        return ["wetland_patch", "shore_hatch", "riparian_perch"]

    def breeding_patch_threshold(self) -> float:
        return 0.18

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"wetland_patch", "shore_hatch"},
            "amount": 0.12,
            "radius": 3,
            "hunger_relief": 8.5,
            "health_gain": 1.3,
            "min_hunger": 14.0,
        }

    def execute_behavior(self, ecosystem):
        self._nutrient_timer += 1
        super().execute_behavior(ecosystem)
        if self.alive and self._nutrient_timer >= self.nutrient_cycle_interval:
            self._nutrient_timer = 0
            self._cycle_nutrients(ecosystem)

    def _cycle_nutrients(self, ecosystem):
        water_score = ecosystem.get_adjacent_water_score(self.position, radius=2) if hasattr(ecosystem, "get_adjacent_water_score") else 0.0
        wetland_value = ecosystem.get_local_microhabitat_value(self.position, {"wetland_patch", "shore_hatch"}, radius=3) if hasattr(ecosystem, "get_local_microhabitat_value") else 0.0
        if water_score <= 0 and wetland_value < 0.08:
            return

        if hasattr(ecosystem, "get_microhabitat_patches"):
            patches = ecosystem.get_microhabitat_patches({"wetland_patch", "shore_hatch"}, self.position, radius=3)
            for patch in patches[:4]:
                patch.available = min(patch.capacity * max(1.0, patch.seasonal_multiplier), patch.available + 0.15)

        if random.random() < 0.35:
            candidate = ecosystem._random_water_adjacent_position()
            if candidate and abs(candidate[0] - self.position[0]) + abs(candidate[1] - self.position[1]) <= 6:
                plant_species = "moss" if random.random() < 0.5 else "fern"
                ecosystem.spawn_plant(plant_species, candidate, source="natural")

        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} enriched a shoreline feeding ground")


class Elephant(Animal):
    """大象 - 巨型工程师植食动物。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="elephant",
            position=position,
            max_age=160,
            hunger_rate=0.24,
            reproduction_rate=0.025,
            speed=1.8,
            vision_range=8,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🐘"
        self.color = (145, 145, 145)
        self.pregnancy_duration = 24
        self.engineer_interval = random.randint(9, 15)
        self._engineer_timer = 0

    def get_predators(self) -> List[str]:
        return []

    def get_food_sources(self) -> List[str]:
        return [
            "grass", "bush", "tree", "apple_tree", "cherry_tree",
            "orange_tree", "berry", "fern", "moss"
        ]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "apple_tree", "cherry_tree", "orange_tree", "bush", "berry"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_canopy_cover(self) -> bool:
        return True

    def prefers_water_edge_cover(self) -> bool:
        return True

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"canopy_forage", "canopy_roost", "riparian_perch"},
            "amount": 0.12,
            "radius": 4,
            "hunger_relief": 8.0,
            "health_gain": 1.1,
            "min_hunger": 16.0,
        }

    def execute_behavior(self, ecosystem):
        self._engineer_timer += 1
        super().execute_behavior(ecosystem)
        if self.alive and self._engineer_timer >= self.engineer_interval:
            self._engineer_timer = 0
            self._engineer_landscape(ecosystem)

    def _engineer_landscape(self, ecosystem):
        nearby_plants = ecosystem.get_nearby_plants(self.position, 3) if hasattr(ecosystem, "get_nearby_plants") else []
        tall_plants = [
            plant for plant in nearby_plants
            if plant.alive and plant.species in {"tree", "apple_tree", "cherry_tree", "orange_tree", "bush", "berry"}
        ]
        if not tall_plants:
            return

        modified = 0
        for plant in tall_plants[:3]:
            plant.health = max(0, plant.health - 18)
            if hasattr(plant, "size"):
                plant.size = max(0.6, plant.size - 0.08)
            modified += 1

        if random.random() < 0.55:
            candidate = ecosystem._random_land_position()
            if candidate and abs(candidate[0] - self.position[0]) + abs(candidate[1] - self.position[1]) <= 6:
                ecosystem.spawn_plant("grass", candidate, source="natural")

        if hasattr(ecosystem, "log_event") and modified:
            ecosystem.log_event(f"{self.id} opened a grazing corridor")


class WhiteRhino(Animal):
    """白犀 - 高防御大型草食动物，偏好草地和泥浴点。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="white_rhino",
            position=position,
            max_age=120,
            hunger_rate=0.22,
            reproduction_rate=0.02,
            speed=1.4,
            vision_range=6,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦏"
        self.color = (120, 120, 120)
        self.pregnancy_duration = 22
        self.defense_rating = 2.8
        self.walllow_interval = random.randint(8, 14)
        self._wallow_timer = 0

    def get_predators(self) -> List[str]:
        return []

    def get_food_sources(self) -> List[str]:
        return ["grass", "bush", "fern", "moss", "flower", "berry"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "berry", "moss", "fern"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_water_edge_cover(self) -> bool:
        return True

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"wetland_patch", "riparian_perch"},
            "amount": 0.08,
            "radius": 3,
            "hunger_relief": 6.5,
            "health_gain": 1.0,
            "min_hunger": 14.0,
        }

    def execute_behavior(self, ecosystem):
        self._wallow_timer += 1
        super().execute_behavior(ecosystem)
        if self.alive and self._wallow_timer >= self.walllow_interval:
            self._wallow_timer = 0
            self._maintain_grazing_patch(ecosystem)

    def _maintain_grazing_patch(self, ecosystem):
        nearby_plants = ecosystem.get_nearby_plants(self.position, 3) if hasattr(ecosystem, "get_nearby_plants") else []
        dense_cover = [
            plant for plant in nearby_plants
            if plant.alive and plant.species in {"bush", "berry", "moss", "fern"}
        ]
        if not dense_cover:
            return

        for plant in dense_cover[:2]:
            plant.health = max(0, plant.health - 14)
            if hasattr(plant, "size"):
                plant.size = max(0.5, plant.size - 0.06)

        if random.random() < 0.45:
            candidate = ecosystem._random_land_position()
            if candidate and abs(candidate[0] - self.position[0]) + abs(candidate[1] - self.position[1]) <= 5:
                ecosystem.spawn_plant("grass", candidate, source="natural")

        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} opened a mud-wallow grazing patch")


class Giraffe(Animal):
    """长颈鹿 - 高层树冠浏览者。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="giraffe",
            position=position,
            max_age=110,
            hunger_rate=0.20,
            reproduction_rate=0.022,
            speed=1.9,
            vision_range=8,
            diet="herbivore",
            gender=gender
        )
        self.emoji = "🦒"
        self.color = (210, 170, 95)
        self.pregnancy_duration = 20
        self.browse_interval = random.randint(7, 12)
        self._browse_timer = 0

    def get_predators(self) -> List[str]:
        return ["crocodile"]

    def get_food_sources(self) -> List[str]:
        return ["tree", "apple_tree", "cherry_tree", "orange_tree", "bush", "berry", "fern"]

    def get_cover_plant_species(self) -> List[str]:
        return ["tree", "apple_tree", "cherry_tree", "orange_tree"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_canopy_cover(self) -> bool:
        return True

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"canopy_forage", "canopy_roost"},
            "amount": 0.10,
            "radius": 4,
            "hunger_relief": 7.0,
            "health_gain": 1.0,
            "min_hunger": 14.0,
        }

    def execute_behavior(self, ecosystem):
        self._browse_timer += 1
        super().execute_behavior(ecosystem)
        if self.alive and self._browse_timer >= self.browse_interval:
            self._browse_timer = 0
            self._shape_canopy(ecosystem)

    def _shape_canopy(self, ecosystem):
        nearby_plants = ecosystem.get_nearby_plants(self.position, 3) if hasattr(ecosystem, "get_nearby_plants") else []
        canopy_plants = [
            plant for plant in nearby_plants
            if plant.alive and plant.species in {"tree", "apple_tree", "cherry_tree", "orange_tree"}
        ]
        if not canopy_plants:
            return

        for plant in canopy_plants[:2]:
            plant.health = max(0, plant.health - 12)
            if hasattr(plant, "size"):
                plant.size = max(0.7, plant.size - 0.05)

        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} pruned the upper canopy")


class Lion(Animal):
    """狮 - 草原群居顶级捕食者。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="lion",
            position=position,
            max_age=105,
            hunger_rate=0.28,
            reproduction_rate=0.028,
            speed=2.4,
            vision_range=9,
            diet="carnivore",
            gender=gender
        )
        self.emoji = "🦁"
        self.color = (197, 150, 73)
        self.pregnancy_duration = 16
        self.pride_interval = random.randint(8, 13)
        self.pride_core_interval = random.randint(11, 17)
        self.takeover_interval = random.randint(15, 22)
        self._pride_timer = 0
        self._pride_core_timer = 0
        self._takeover_timer = 0
        self.forms_groups = True
        self.dominance = 1.9
        self.pride_strength = 0.0
        self.takeover_pressure = 0.0
        self.pride_id = f"pride-{random.randint(1, 6)}"
        self.pride_center = position
        self.pride_stability = 0.0
        self.cycle_expansion_phase = 0.0
        self.cycle_contraction_phase = 0.0

    def get_predators(self) -> List[str]:
        return []

    def get_prey_species(self) -> List[str]:
        return ["rabbit", "deer", "antelope", "zebra", "giraffe", "wild_boar", "hippopotamus"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "berry", "tree", "moss"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_shrub_cover(self) -> bool:
        return True

    def prefers_water_edge_cover(self) -> bool:
        return True

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"shrub_shelter", "riparian_perch"},
            "amount": 0.06,
            "radius": 4,
            "hunger_relief": 4.5,
            "health_gain": 0.9,
            "min_hunger": 18.0,
        }

    def execute_behavior(self, ecosystem):
        self._pride_timer += 1
        self._pride_core_timer += 1
        self._takeover_timer += 1
        self._apply_cycle_phase()
        self._apply_social_stability(ecosystem)
        super().execute_behavior(ecosystem)
        if self.alive and self._pride_timer >= self.pride_interval:
            self._pride_timer = 0
            self._mark_hunt_corridor(ecosystem)
        if self.alive and self._pride_core_timer >= self.pride_core_interval:
            self._pride_core_timer = 0
            self._establish_pride_core(ecosystem)
        if self.alive and self._takeover_timer >= self.takeover_interval:
            self._takeover_timer = 0
            self._contest_male_front(ecosystem)
        self.reproduction_rate *= max(0.75, 0.9 + self.pride_stability * 0.35)
        self.pride_stability = max(0.0, self.pride_stability - 0.015)
        self.pride_strength = max(0.0, self.pride_strength - 0.02)
        self.takeover_pressure = max(0.0, self.takeover_pressure - 0.025)

    def _apply_cycle_phase(self):
        expansion = max(0.0, min(1.0, self.cycle_expansion_phase))
        contraction = max(0.0, min(1.0, self.cycle_contraction_phase))
        if expansion > 0.0:
            self.health = min(getattr(self, "max_health", 100), self.health + expansion * 0.35)
            self.hunger = max(0.0, self.hunger - expansion * 0.7)
            self.mate_cooldown = max(0, self.mate_cooldown - int(expansion * 2))
            self.reproduction_rate *= 1.0 + expansion * 0.08
        if contraction > 0.0:
            self.hunger = min(100.0, self.hunger + contraction * 0.55)
            self.mate_cooldown += int(contraction * 2)
            self.reproduction_rate *= max(0.78, 1.0 - contraction * 0.12)
            self.health = max(0.0, self.health - contraction * 0.18)

    def _apply_social_stability(self, ecosystem):
        lions = [animal for animal in ecosystem.animals if animal.alive and animal.species == "lion"]
        pride_size = sum(1 for animal in lions if getattr(animal, "pride_id", None) == self.pride_id)
        same_hotspot = {
            (getattr(animal, "pride_center", animal.position)[0] // 8, getattr(animal, "pride_center", animal.position)[1] // 8)
            for animal in lions
            if getattr(animal, "pride_id", None) == self.pride_id
        }
        rival_hotspot_overlap = sum(
            1
            for animal in lions
            if getattr(animal, "pride_id", None) != self.pride_id
            and (getattr(animal, "pride_center", animal.position)[0] // 8, getattr(animal, "pride_center", animal.position)[1] // 8) in same_hotspot
        )
        stability = min(1.0, 0.10 * max(0, pride_size - 1) + self.pride_strength * 0.55 - rival_hotspot_overlap * 0.08)
        self.pride_stability = max(0.0, stability)
        if self.pride_stability >= 0.35:
            self.health = min(getattr(self, "max_health", 100), self.health + self.pride_stability * 0.4)
            self.hunger = max(0.0, self.hunger - self.pride_stability * 0.8)
            self.mate_cooldown = max(0, self.mate_cooldown - 1)
        elif rival_hotspot_overlap > 0:
            self.mate_cooldown = max(self.mate_cooldown, 2)

    def _mark_hunt_corridor(self, ecosystem):
        if hasattr(ecosystem, "get_microhabitat_patches"):
            patches = ecosystem.get_microhabitat_patches({"shrub_shelter", "riparian_perch"}, self.position, radius=4)
            for patch in patches[:3]:
                patch.occupancy = min(patch.capacity, patch.occupancy + 0.08)
        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} marked a grassland hunt corridor")

    def _establish_pride_core(self, ecosystem):
        if hasattr(ecosystem, "occupy_microhabitat"):
            ecosystem.occupy_microhabitat(self.species, {"shrub_shelter", "riparian_perch"}, self.position, amount=0.22, radius=3)
        self.pride_center = self.position
        if hasattr(ecosystem, "get_local_microhabitat_value"):
            core_value = ecosystem.get_local_microhabitat_value(self.position, {"shrub_shelter", "riparian_perch"}, radius=4)
            if core_value >= 0.10:
                self.health = min(getattr(self, "max_health", 100), self.health + 0.8)
                self.hunger = max(0.0, self.hunger - 1.8)
                self.pride_strength = min(1.0, self.pride_strength + 0.18)
            else:
                self.pride_strength = min(1.0, self.pride_strength + 0.08)
        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} established a pride core range")

    def _contest_male_front(self, ecosystem):
        if hasattr(ecosystem, "occupy_microhabitat"):
            ecosystem.occupy_microhabitat(self.species, {"shrub_shelter", "riparian_perch"}, self.position, amount=0.16, radius=4)
        self.pride_center = self.position
        if hasattr(ecosystem, "get_microhabitat_patches"):
            patches = ecosystem.get_microhabitat_patches({"shrub_shelter", "riparian_perch"}, self.position, radius=5)
            for patch in patches[:2]:
                patch.occupancy = min(patch.capacity, patch.occupancy + 0.06)
        self.health = max(0.0, self.health - 0.4)
        self.takeover_pressure = min(1.0, self.takeover_pressure + 0.16)
        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} pressed a male takeover front")

    def _give_birth(self, ecosystem):
        social_factor = max(0.65, min(1.35, 0.75 + self.pride_stability))
        _social_group_birth(
            self,
            ecosystem,
            social_factor=social_factor,
            stable_label="stable pride support",
            unstable_label="pride instability",
        )


class Hyena(Animal):
    """鬣狗 - 草原腐食竞争者与机会型捕食者。"""

    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="hyena",
            position=position,
            max_age=90,
            hunger_rate=0.26,
            reproduction_rate=0.034,
            speed=2.2,
            vision_range=8,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐕"
        self.color = (150, 124, 88)
        self.pregnancy_duration = 13
        self.scavenge_interval = random.randint(7, 12)
        self.clan_interval = random.randint(10, 16)
        self.clan_front_interval = random.randint(14, 20)
        self._scavenge_timer = 0
        self._clan_timer = 0
        self._clan_front_timer = 0
        self.forms_groups = True
        self.dominance = 1.5
        self.clan_cohesion = 0.0
        self.clan_front_pressure = 0.0
        self.clan_id = f"clan-{random.randint(1, 7)}"
        self.clan_center = position
        self.clan_stability = 0.0
        self.cycle_expansion_phase = 0.0
        self.cycle_contraction_phase = 0.0

    def get_predators(self) -> List[str]:
        return ["lion"]

    def get_food_sources(self) -> List[str]:
        return ["berry", "bush", "mushroom", "grass"]

    def get_prey_species(self) -> List[str]:
        return ["rabbit", "mouse", "bird", "sparrow", "frog", "night_moth", "antelope"]

    def get_cover_plant_species(self) -> List[str]:
        return ["bush", "berry", "moss", "fern"]

    def get_habitat_plant_species(self) -> List[str]:
        return self.get_cover_plant_species()

    def prefers_shrub_cover(self) -> bool:
        return True

    def prefers_water_edge_cover(self) -> bool:
        return True

    def microhabitat_foraging_profile(self):
        return {
            "kinds": {"shrub_shelter", "riparian_perch"},
            "amount": 0.08,
            "radius": 4,
            "hunger_relief": 5.5,
            "health_gain": 0.9,
            "min_hunger": 16.0,
        }

    def execute_behavior(self, ecosystem):
        self._scavenge_timer += 1
        self._clan_timer += 1
        self._clan_front_timer += 1
        self._apply_cycle_phase()
        self._apply_clan_stability(ecosystem)
        super().execute_behavior(ecosystem)
        if self.alive and self._scavenge_timer >= self.scavenge_interval:
            self._scavenge_timer = 0
            self._scavenge_pressure(ecosystem)
        if self.alive and self._clan_timer >= self.clan_interval:
            self._clan_timer = 0
            self._mark_den_cluster(ecosystem)
        if self.alive and self._clan_front_timer >= self.clan_front_interval:
            self._clan_front_timer = 0
            self._expand_clan_front(ecosystem)
        self.reproduction_rate *= max(0.75, 0.9 + self.clan_stability * 0.32)
        self.clan_stability = max(0.0, self.clan_stability - 0.015)
        self.clan_cohesion = max(0.0, self.clan_cohesion - 0.02)
        self.clan_front_pressure = max(0.0, self.clan_front_pressure - 0.025)

    def _apply_cycle_phase(self):
        expansion = max(0.0, min(1.0, self.cycle_expansion_phase))
        contraction = max(0.0, min(1.0, self.cycle_contraction_phase))
        if expansion > 0.0:
            self.health = min(getattr(self, "max_health", 100), self.health + expansion * 0.30)
            self.hunger = max(0.0, self.hunger - expansion * 0.65)
            self.mate_cooldown = max(0, self.mate_cooldown - int(expansion * 2))
            self.reproduction_rate *= 1.0 + expansion * 0.07
        if contraction > 0.0:
            self.hunger = min(100.0, self.hunger + contraction * 0.5)
            self.mate_cooldown += int(contraction * 2)
            self.reproduction_rate *= max(0.80, 1.0 - contraction * 0.10)
            self.health = max(0.0, self.health - contraction * 0.16)

    def _apply_clan_stability(self, ecosystem):
        hyenas = [animal for animal in ecosystem.animals if animal.alive and animal.species == "hyena"]
        clan_size = sum(1 for animal in hyenas if getattr(animal, "clan_id", None) == self.clan_id)
        same_hotspot = {
            (getattr(animal, "clan_center", animal.position)[0] // 8, getattr(animal, "clan_center", animal.position)[1] // 8)
            for animal in hyenas
            if getattr(animal, "clan_id", None) == self.clan_id
        }
        rival_hotspot_overlap = sum(
            1
            for animal in hyenas
            if getattr(animal, "clan_id", None) != self.clan_id
            and (getattr(animal, "clan_center", animal.position)[0] // 8, getattr(animal, "clan_center", animal.position)[1] // 8) in same_hotspot
        )
        stability = min(1.0, 0.08 * max(0, clan_size - 1) + self.clan_cohesion * 0.55 - rival_hotspot_overlap * 0.07)
        self.clan_stability = max(0.0, stability)
        if self.clan_stability >= 0.35:
            self.health = min(getattr(self, "max_health", 100), self.health + self.clan_stability * 0.35)
            self.hunger = max(0.0, self.hunger - self.clan_stability * 0.7)
            self.mate_cooldown = max(0, self.mate_cooldown - 1)
        elif rival_hotspot_overlap > 0:
            self.mate_cooldown = max(self.mate_cooldown, 2)

    def _scavenge_pressure(self, ecosystem):
        if hasattr(ecosystem, "get_microhabitat_patches"):
            patches = ecosystem.get_microhabitat_patches({"shrub_shelter", "riparian_perch"}, self.position, radius=4)
            for patch in patches[:2]:
                patch.available = min(patch.capacity * max(1.0, patch.seasonal_multiplier), patch.available + 0.10)
        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} intensified scavenging pressure on the grassland edge")

    def _mark_den_cluster(self, ecosystem):
        if hasattr(ecosystem, "occupy_microhabitat"):
            ecosystem.occupy_microhabitat(self.species, {"shrub_shelter", "riparian_perch"}, self.position, amount=0.18, radius=3)
        self.clan_center = self.position
        if hasattr(ecosystem, "get_local_microhabitat_value"):
            den_value = ecosystem.get_local_microhabitat_value(self.position, {"shrub_shelter", "riparian_perch"}, radius=4)
            if den_value >= 0.08:
                self.health = min(getattr(self, "max_health", 100), self.health + 0.6)
                self.hunger = max(0.0, self.hunger - 1.2)
                self.clan_cohesion = min(1.0, self.clan_cohesion + 0.16)
            else:
                self.clan_cohesion = min(1.0, self.clan_cohesion + 0.07)
        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} reinforced a clan den corridor")

    def _expand_clan_front(self, ecosystem):
        if hasattr(ecosystem, "occupy_microhabitat"):
            ecosystem.occupy_microhabitat(self.species, {"shrub_shelter", "riparian_perch"}, self.position, amount=0.14, radius=4)
        self.clan_center = self.position
        if hasattr(ecosystem, "get_microhabitat_patches"):
            patches = ecosystem.get_microhabitat_patches({"shrub_shelter", "riparian_perch"}, self.position, radius=5)
            for patch in patches[:2]:
                patch.available = min(patch.capacity * max(1.0, patch.seasonal_multiplier), patch.available + 0.06)
        self.hunger = max(0.0, self.hunger - 0.6)
        self.clan_front_pressure = min(1.0, self.clan_front_pressure + 0.15)
        if hasattr(ecosystem, "log_event"):
            ecosystem.log_event(f"{self.id} expanded a clan frontier")

    def _give_birth(self, ecosystem):
        social_factor = max(0.65, min(1.40, 0.78 + self.clan_stability))
        _social_group_birth(
            self,
            ecosystem,
            social_factor=social_factor,
            stable_label="stable clan support",
            unstable_label="clan instability",
        )


class WildBoar(Animal):
    """野猪 - 杂食，用鼻子掘食"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="wild_boar",
            position=position,
            max_age=70,
            hunger_rate=0.35,
            reproduction_rate=0.08,
            speed=2.0,
            vision_range=6,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐗"
        self.color = (101, 67, 33)
        self.pregnancy_duration = 12
        self.dominance = 1.2
        self.can_dig = True
        
    def get_predators(self) -> List[str]:
        return ["wolf", "bear"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "bush", "flower", "moss", "berry",
                "strawberry", "blueberry", "mushroom", "fern", "apple_tree", "watermelon"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "tadpole", "shrimp", "water_strider"]
        
    def forage(self, ecosystem):
        """野猪用鼻子掘食"""
        # 优先找果实和块茎
        nearby_plants = ecosystem.get_nearby_plants(self.position, self.vision_range)
        fruits = [p for p in nearby_plants if hasattr(p, 'has_fruit') and p.has_fruit]
        
        if fruits:
            closest = min(fruits, key=lambda p:
                abs(p.position[0]-self.position[0]) + abs(p.position[1]-self.position[1]))
            self.move_towards(closest.position, ecosystem)
            dist = abs(closest.position[0]-self.position[0]) + abs(closest.position[1]-self.position[1])
            if dist <= 1:
                nutrition = closest.be_eaten(1.0)
                self.eat(nutrition)
                # 掘食可能伤害植物
                if random.random() < 0.3:
                    closest.health -= 10
        else:
            super().forage(ecosystem)


class Badger(Animal):
    """獾 - 夜行性杂食动物"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="badger",
            position=position,
            max_age=50,
            hunger_rate=0.32,
            reproduction_rate=0.06,
            speed=1.8,
            vision_range=5,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🦡"
        self.color = (128, 128, 128)
        self.pregnancy_duration = 10
        self.is_nocturnal = True
        self.has_burrow = False
        
    def get_predators(self) -> List[str]:
        return ["wolf", "bear", "eagle"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "berry", "mushroom", "blueberry", "strawberry", "moss"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "bee", "spider", "tadpole", "water_strider"]
        
    def execute_behavior(self, ecosystem):
        """獾夜间活动"""
        hour = ecosystem.environment.hour
        if 18 <= hour or hour < 6:
            self.speed = 2.2
            self.vision_range = 7
        else:
            self.speed = 0.5  # 白天躲在洞穴
            self.vision_range = 2
        super().execute_behavior(ecosystem)


class RaccoonDog(Animal):
    """貉 - 像浣熊的犬科"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="raccoon_dog",
            position=position,
            max_age=45,
            hunger_rate=0.30,
            reproduction_rate=0.10,
            speed=2.0,
            vision_range=6,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐕"
        self.color = (160, 120, 80)
        self.pregnancy_duration = 10
        self.can_swim = True
        
    def get_predators(self) -> List[str]:
        return ["wolf", "bear", "fox"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "berry", "blueberry", "strawberry", "mushroom", "apple_tree"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "small_fish", "shrimp", "tadpole", "water_strider", "bird"]


class Skunk(Animal):
    """臭鼬 - 有臭腺防御"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="skunk",
            position=position,
            max_age=35,
            hunger_rate=0.35,
            reproduction_rate=0.08,
            speed=1.5,
            vision_range=4,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🦨"
        self.color = (0, 0, 0)
        self.pregnancy_duration = 8
        self.defense_rating = 2.0  # 高防御
        self.can_spray = True  # 臭腺
        
    def get_predators(self) -> List[str]:
        return []  # 臭鼬很少有捕食者
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "berry", "mushroom", "strawberry", "blueberry", "moss"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "bee", "spider", "water_strider"]
        
    def defend_against_predator(self, predator, ecosystem):
        """臭鼬喷臭液防御"""
        if random.random() < 0.7:  # 70%成功率
            # 成功防御，捕食者逃跑
            predator.health -= 5
            ecosystem.log_event(f"{self.id} sprayed {predator.id}")
            return "sprayed"
        return "failed"


class Opossum(Animal):
    """负鼠 - 会装死"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="opossum",
            position=position,
            max_age=25,
            hunger_rate=0.40,
            reproduction_rate=0.15,
            speed=1.2,
            vision_range=4,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🐭"
        self.color = (150, 150, 150)
        self.pregnancy_duration = 5
        self.can_play_dead = True
        
    def get_predators(self) -> List[str]:
        return ["wolf", "fox", "owl", "eagle"]
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "berry", "mushroom", "blueberry", "strawberry", "moss"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "spider", "water_strider"]
        
    def check_danger(self, ecosystem) -> bool:
        """负鼠装死躲避捕食者"""
        if random.random() < 0.6:  # 60%成功装死
            return False  # 捕食者忽略
        return super().check_danger(ecosystem)


class Coati(Animal):
    """长鼻浣熊 - 热带杂食动物"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="coati",
            position=position,
            max_age=40,
            hunger_rate=0.32,
            reproduction_rate=0.09,
            speed=2.5,
            vision_range=7,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🦝"
        self.color = (205, 133, 63)
        self.pregnancy_duration = 10
        self.can_climb = True
        
    def get_predators(self) -> List[str]:
        return ["eagle", "snake", "wolf"]
        
    def get_food_sources(self) -> List[str]:
        return ["apple_tree", "cherry_tree", "berry", "strawberry", 
                "grape_vine", "blueberry", "flower", "orange_tree", "watermelon", "mushroom"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "mouse", "frog", "bird", "sparrow", "bee", "spider", "tadpole"]


class Armadillo(Animal):
    """犰狳 - 有装甲外壳"""
    
    def __init__(self, position: Tuple[int, int], gender: Gender = None):
        super().__init__(
            species="armadillo",
            position=position,
            max_age=50,
            hunger_rate=0.28,
            reproduction_rate=0.05,
            speed=1.0,
            vision_range=3,
            diet="omnivore",
            gender=gender
        )
        self.emoji = "🦔"
        self.color = (210, 180, 140)
        self.pregnancy_duration = 12
        self.defense_rating = 2.5  # 很高的防御
        self.has_armor = True
        
    def get_predators(self) -> List[str]:
        return []  # 装甲保护
        
    def get_food_sources(self) -> List[str]:
        return ["grass", "flower", "berry", "mushroom", "fern", "moss"]
        
    def get_prey_species(self) -> List[str]:
        return ["insect", "bee", "spider", "tadpole", "water_strider"]
        
    def defend_against_predator(self, predator, ecosystem):
        """犰狳蜷缩成球"""
        if random.random() < 0.8:  # 80%成功
            return "curled"
        return "failed"

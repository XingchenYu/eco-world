"""
竞争与防御机制模块
实现物种间的竞争、领地争夺、防御行为等
"""

from typing import List, Tuple, Optional
import random
from enum import Enum


class CompetitionType(Enum):
    """竞争类型"""
    FOOD = "food"          # 食物竞争
    TERRITORY = "territory"  # 领地竞争
    MATING = "mating"      # 配偶竞争


class DefenseType(Enum):
    """防御类型"""
    ESCAPE = "escape"      # 逃跑
    COUNTER = "counter"    # 反击
    CAMOUFLAGE = "camouflage"  # 伪装
    GROUP = "group"        # 群体防御
    ARMOR = "armor"        # 装甲防御


class Competition:
    """竞争系统 - 物种间资源争夺"""
    
    @staticmethod
    def food_competition(animal, ecosystem) -> dict:
        """
        食物竞争机制
        同种/异种动物争夺有限食物资源
        
        返回: {
            "competitors": 竞争者数量,
            "food_available": 食物可用性 (0-1),
            "won": 是否赢得竞争
        }
        """
        # 获取附近的竞争者
        nearby = ecosystem.get_nearby_animals(animal.position, animal.vision_range)
        
        # 找出吃相同食物的竞争者
        competitors = []
        for other in nearby:
            if other.alive and other.id != animal.id:
                # 同种竞争（最激烈）
                if other.species == animal.species:
                    competitors.append((other, 1.5))  # 同种竞争系数更高
                # 异种但相同食性
                elif hasattr(other, 'diet') and other.diet == animal.diet:
                    competitors.append((other, 1.0))
        
        if not competitors:
            return {"competitors": 0, "food_available": 1.0, "won": True}
        
        # 计算食物可用性（竞争者越多，食物越少）
        competitor_count = len(competitors)
        food_available = max(0.1, 1.0 - competitor_count * 0.15)
        
        # 竞争判定：基于支配力、体型、健康状况
        animal_score = (
            animal.dominance * 0.4 +
            animal.health / 100 * 0.3 +
            (1.0 if animal.gender.value == "male" else 0.8) * 0.3
        )
        
        won = True
        for competitor, coefficient in competitors:
            other = competitor
            other_score = (
                other.dominance * 0.4 +
                other.health / 100 * 0.3 +
                (1.0 if other.gender.value == "male" else 0.8) * 0.3
            ) * coefficient
            
            if other_score > animal_score and random.random() < 0.7:
                won = False
                break
        
        return {
            "competitors": competitor_count,
            "food_available": food_available,
            "won": won
        }
    
    @staticmethod
    def territory_competition(animal, ecosystem) -> dict:
        """
        领地竞争机制
        同种动物争夺领地
        
        返回: {
            "has_territory": 是否有领地,
            "territory_quality": 领地质量,
            "intruders": 入侵者数量
        }
        """
        # 获取领地内的入侵者
        territory_range = getattr(animal, 'territory_range', 3)
        nearby = ecosystem.get_nearby_animals(animal.position, territory_range)
        
        # 同种入侵者
        intruders = [a for a in nearby if a.species == animal.species and a.id != animal.id]
        
        if not intruders:
            # 没有入侵者，领地安全
            food_in_territory = len(ecosystem.get_nearby_plants(animal.position, territory_range))
            territory_quality = min(1.0, food_in_territory / 10)
            return {
                "has_territory": True,
                "territory_quality": territory_quality,
                "intruders": 0
            }
        
        # 有入侵者，进行领地争夺
        won_all = True
        for intruder in intruders:
            # 领地争夺判定
            defender_bonus = 1.3  # 防守者有主场优势
            animal_score = animal.dominance * defender_bonus + animal.health / 100
            intruder_score = intruder.dominance + intruder.health / 100
            
            if intruder_score > animal_score and random.random() < 0.6:
                won_all = False
                # 领地被入侵，可能受伤
                if random.random() < 0.3:
                    animal.health -= random.randint(5, 15)
        
        return {
            "has_territory": won_all,
            "territory_quality": 0.5 if not won_all else 1.0,
            "intruders": len(intruders)
        }
    
    @staticmethod
    def mating_competition(male, female, ecosystem) -> bool:
        """
        配偶竞争机制
        多个雄性争夺一个雌性
        
        返回: 该雄性是否赢得配偶
        """
        # 获取附近的其他雄性
        nearby = ecosystem.get_nearby_animals(male.position, male.vision_range)
        other_males = [
            a for a in nearby 
            if a.species == male.species 
            and a.gender.value == "male" 
            and a.alive 
            and a.id != male.id
        ]
        
        if not other_males:
            return True  # 没有竞争者
        
        # 进行配偶竞争
        male_score = male.dominance * 0.5 + male.health / 100 * 0.3 + random.random() * 0.2
        
        for competitor in other_males:
            comp_score = competitor.dominance * 0.5 + competitor.health / 100 * 0.3 + random.random() * 0.2
            
            if comp_score > male_score:
                # 输给竞争者
                if random.random() < 0.2:  # 20%概率受伤
                    male.health -= random.randint(3, 10)
                return False
        
        return True  # 赢得配偶


class Defense:
    """防御系统 - 动物的各种防御行为"""
    
    @staticmethod
    def escape_behavior(prey, predator, ecosystem) -> bool:
        """
        逃跑行为
        返回: 是否成功逃跑
        """
        # 逃跑成功率取决于：
        # 1. 速度差异
        # 2. 距离
        # 3. 环境（草丛可以躲藏）
        
        distance = abs(prey.position[0] - predator.position[0]) + \
                   abs(prey.position[1] - predator.position[1])
        
        # 速度优势
        speed_advantage = (prey.speed - predator.speed) / prey.speed
        
        # 距离优势
        distance_advantage = distance / prey.vision_range
        
        # 环境优势（检查附近是否有遮蔽物）
        nearby_plants = ecosystem.get_nearby_plants(prey.position, 2)
        cover_bonus = len([p for p in nearby_plants if p.species in ["bush", "moss"]]) * 0.1
        
        # 计算逃跑成功率
        escape_chance = 0.3 + speed_advantage * 0.3 + distance_advantage * 0.3 + cover_bonus
        
        if random.random() < escape_chance:
            # 成功逃跑，向反方向移动
            dx = prey.position[0] - predator.position[0]
            dy = prey.position[1] - predator.position[1]
            
            # 标准化方向
            if dx != 0 or dy != 0:
                move_x = int(dx / max(abs(dx), 1) * prey.speed)
                move_y = int(dy / max(abs(dy), 1) * prey.speed)
                
                new_x = max(0, min(prey.position[0] + move_x, ecosystem.width - 1))
                new_y = max(0, min(prey.position[1] + move_y, ecosystem.height - 1))
                prey.position = (new_x, new_y)
            
            return True
        
        return False
    
    @staticmethod
    def counter_attack(prey, predator, ecosystem) -> bool:
        """
        反击行为
        某些动物被攻击时会反击
        
        返回: 是否成功反击
        """
        if not getattr(prey, 'can_counter_attack', False):
            return False
        
        # 反击能力
        counter_strength = getattr(prey, 'counter_strength', 0.3)
        
        # 反击判定
        if random.random() < counter_strength:
            # 成功反击，捕食者受伤
            damage = random.randint(5, 15)
            predator.health -= damage
            
            # 记录事件
            ecosystem.log_event(f"{prey.id} counter-attacked {predator.id} for {damage} damage")
            
            return True
        
        return False
    
    @staticmethod
    def camouflage_check(prey, ecosystem) -> bool:
        """
        伪装检查
        某些动物可以伪装躲避捕食者
        
        返回: 是否成功伪装
        """
        if not getattr(prey, 'has_camouflage', False):
            return False
        
        # 伪装成功率取决于环境匹配度
        # 在特定地形上伪装效果更好
        terrain = ecosystem.environment.get_terrain(prey.position[0], prey.position[1])
        
        camouflage_bonus = 0
        if hasattr(prey, 'camouflage_terrain'):
            if terrain in prey.camouflage_terrain:
                camouflage_bonus = 0.6
        
        # 基础伪装成功率
        base_chance = getattr(prey, 'camouflage_skill', 0.3)
        
        return random.random() < (base_chance + camouflage_bonus)
    
    @staticmethod
    def group_defense(prey, predator, ecosystem) -> bool:
        """
        群体防御
        某些动物会群体防御
        
        返回: 是否成功群体防御
        """
        if not getattr(prey, 'forms_groups', False):
            return False
        
        # 获取附近的同类
        nearby = ecosystem.get_nearby_animals(prey.position, prey.vision_range)
        same_species = [a for a in nearby if a.species == prey.species and a.alive]
        
        if len(same_species) < 3:  # 需要至少3个同伴
            return False
        
        # 群体防御成功率随数量增加
        group_size = len(same_species) + 1
        defense_chance = min(0.8, 0.2 + group_size * 0.1)
        
        if random.random() < defense_chance:
            # 成功群体防御，捕食者可能逃跑
            if random.random() < 0.5:
                # 捕食者被吓跑
                ecosystem.log_event(f"{predator.id} scared away by group of {prey.species}")
            return True
        
        return False


# 为 Animal 类添加竞争和防御方法
def apply_competition_and_defense():
    """将竞争和防御方法应用到 Animal 类"""
    
    def check_competition(self, ecosystem):
        """检查竞争状态"""
        food_comp = Competition.food_competition(self, ecosystem)
        territory_comp = Competition.territory_competition(self, ecosystem)
        
        return {
            "food": food_comp,
            "territory": territory_comp
        }
    
    def defend_against_predator(self, predator, ecosystem):
        """综合防御行为"""
        # 1. 尝试伪装
        if Defense.camouflage_check(self, ecosystem):
            return "camouflaged"
        
        # 2. 尝试群体防御
        if Defense.group_defense(self, predator, ecosystem):
            return "group_defense"
        
        # 3. 尝试逃跑
        if Defense.escape_behavior(self, predator, ecosystem):
            return "escaped"
        
        # 4. 尝试反击
        if Defense.counter_attack(self, predator, ecosystem):
            return "counter_attacked"
        
        return "caught"
"""
生物基类 - 动态繁殖率
"""

from abc import ABC, abstractmethod
from typing import Tuple, Optional
from enum import Enum
import random


class BehaviorState(Enum):
    IDLE = "idle"
    FORAGING = "foraging"
    HUNTING = "hunting"
    ESCAPING = "escaping"
    MATING = "mating"
    DEAD = "dead"


class Creature(ABC):
    """生物基类"""
    
    def __init__(
        self,
        species: str,
        position: Tuple[int, int],
        max_age: int,
        hunger_rate: float,
        reproduction_rate: float,
        speed: float = 1.0,
        vision_range: int = 3
    ):
        self.id = f"{species}_{random.randint(10000, 99999)}"
        self.species = species
        self.position = position
        self.age = 0
        self.health = 100.0
        self.hunger = 0.0
        self.max_age = max_age
        self.base_hunger_rate = hunger_rate
        self.hunger_rate = hunger_rate
        self.base_reproduction_rate = reproduction_rate  # 基础繁殖率
        self.reproduction_rate = reproduction_rate
        self.ecology_hunger_multiplier = 1.0
        self.ecology_reproduction_multiplier = 1.0
        self.speed = speed
        self.vision_range = vision_range
        self.behavior_state = BehaviorState.IDLE
        self.target: Optional[Tuple[int, int]] = None
        self.alive = True
        
        # 🔄 动态繁殖系统
        self.food_history = []  # 最近N轮的食物获取记录
        self.food_history_max = 20  # 记录最近20轮
        self.last_food_amount = 0  # 上一轮吃的食物量
        
    def update(self, ecosystem):
        """每个tick更新状态"""
        if not self.alive:
            return
            
        # 年龄增长
        self.age += 1
        
        # 饥饿增加
        self.hunger += self.hunger_rate
        
        # 饥饿导致健康下降
        if self.hunger > 50:
            self.health -= (self.hunger - 50) * 0.1
            
        # 健康或年龄达到上限则死亡
        if self.health <= 0 or self.age >= self.max_age:
            self.die()
            return
            
        # 🔄 更新动态繁殖率
        self._update_reproduction_rate()
        
        # 执行行为
        self.execute_behavior(ecosystem)
        
    def _update_reproduction_rate(self):
        """根据食物获取情况动态调整繁殖率"""
        # 记录上一轮的食物量
        self.food_history.append(self.last_food_amount)
        if len(self.food_history) > self.food_history_max:
            self.food_history = self.food_history[-self.food_history_max:]
            
        # 计算平均食物获取量
        if len(self.food_history) >= 5:
            avg_food = sum(self.food_history) / len(self.food_history)
            
            # 动态调整繁殖率
            # 食物充足（平均饥饿度低）→ 繁殖率提高
            # 食物不足（平均饥饿度高）→ 繁殖率降低
            
            # 使用当前饥饿度作为指标
            hunger_factor = 1.0 - (self.hunger / 100)  # 0-1，越饥饿越低
            health_factor = self.health / 100  # 健康因子
            
            # 综合因子
            dynamic_factor = hunger_factor * health_factor
            
            # 繁殖率 = 基础繁殖率 × 动态因子
            self.reproduction_rate = self.base_reproduction_rate * self.ecology_reproduction_multiplier * max(0.1, dynamic_factor)
        else:
            self.reproduction_rate = self.base_reproduction_rate * self.ecology_reproduction_multiplier
            
        # 重置本轮食物量
        self.last_food_amount = 0

    def apply_ecology_modifiers(self, hunger_multiplier: float = 1.0, reproduction_multiplier: float = 1.0):
        """应用生态系统级别的营养级压力修正。"""
        self.ecology_hunger_multiplier = hunger_multiplier
        self.ecology_reproduction_multiplier = reproduction_multiplier
        self.hunger_rate = self.base_hunger_rate * self.ecology_hunger_multiplier
        self.reproduction_rate = self.base_reproduction_rate * self.ecology_reproduction_multiplier
        
    def record_food(self, amount: float):
        """记录本轮获取的食物"""
        self.last_food_amount += amount
        
    def move_towards(self, target: Tuple[int, int], ecosystem):
        """向目标移动"""
        if target is None:
            return
            
        dx = target[0] - self.position[0]
        dy = target[1] - self.position[1]
        
        # 计算移动步数
        steps = min(self.speed, max(abs(dx), abs(dy)))
        if steps == 0:
            return
            
        # 移动
        move_x = int(dx / max(abs(dx), 1) * min(steps, abs(dx)))
        move_y = int(dy / max(abs(dy), 1) * min(steps, abs(dy)))
        
        new_x = self.position[0] + move_x
        new_y = self.position[1] + move_y
        
        # 边界检查
        new_x = max(0, min(new_x, ecosystem.width - 1))
        new_y = max(0, min(new_y, ecosystem.height - 1))
        
        self.position = (new_x, new_y)
        if hasattr(ecosystem, "refresh_spatial_entity"):
            ecosystem.refresh_spatial_entity(self)
        
    def die(self):
        """死亡"""
        self.alive = False
        self.behavior_state = BehaviorState.DEAD
        
    def eat(self, nutrition: float):
        """进食"""
        self.hunger = max(0, self.hunger - nutrition)
        self.health = min(100, self.health + nutrition * 0.5)
        self.record_food(nutrition)  # 记录食物获取
        
    def can_reproduce(self) -> bool:
        """判断是否可以繁殖 - 使用动态繁殖率"""
        return (
            self.health > 60 and 
            self.hunger < 40 and 
            self.age >= self.max_age * 0.2 and
            random.random() < self.reproduction_rate  # 使用动态繁殖率
        )
        
    def __repr__(self):
        return f"{self.species}[{self.id[:8]}] @ {self.position} | age={self.age} hp={self.health:.0f} hunger={self.hunger:.0f} repro={self.reproduction_rate:.3f}"

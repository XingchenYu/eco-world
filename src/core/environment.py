"""
完整环境系统 - 分层生态系统
"""

import random
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
from enum import Enum


class Weather(Enum):
    """天气类型"""
    SUNNY = "sunny"          # 晴天
    CLOUDY = "cloudy"        # 多云
    RAINY = "rainy"          # 下雨
    STORMY = "stormy"        # 暴风雨
    SNOWY = "snowy"          # 下雪
    FOGGY = "foggy"          # 雾天


class TerrainType(Enum):
    """地形类型"""
    GRASS = "grass"          # 草地
    FOREST = "forest"        # 森林
    ROCK = "rock"            # 岩石
    WATER_SHALLOW = "water_shallow"   # 浅水
    WATER_DEEP = "water_deep"         # 深水
    RIVER = "river"          # 河流
    SAND = "sand"            # 沙地
    MUD = "mud"              # 泥地


@dataclass
class Soil:
    """土壤系统"""
    fertility: float = 0.5      # 肥沃度 0-1
    moisture: float = 0.5       # 湿度 0-1
    depth: float = 1.0          # 土壤深度
    organic_matter: float = 0.3 # 有机质含量
    
    def update(self, weather: Weather, has_plants: bool = True):
        """根据天气更新土壤状态"""
        # 下雨增加湿度
        if weather == Weather.RAINY:
            self.moisture = min(1.0, self.moisture + 0.1)
        elif weather == Weather.SUNNY:
            self.moisture = max(0.1, self.moisture - 0.02)
            
        # 有植物时增加有机质
        if has_plants:
            self.organic_matter = min(1.0, self.organic_matter + 0.001)
            
        # 肥沃度受有机质影响
        self.fertility = 0.3 + self.organic_matter * 0.7


@dataclass
class WaterQuality:
    """水质系统"""
    oxygen_level: float = 0.8   # 含氧量 0-1
    clarity: float = 0.7        # 清洁度 0-1
    temperature: float = 15.0   # 水温
    ph_level: float = 7.0       # 酸碱度
    flow_rate: float = 0.0      # 水流速度 0-1
    depth_factor: float = 0.5   # 深度系数 0-1
    nutrient_load: float = 0.5  # 营养盐负荷 0-1
    body_type: str = "lake_shallow"  # 水体类型
    
    def update(self, air_temperature: float, weather: Weather, has_plants: bool = True, has_fish: bool = False):
        """更新水质"""
        # 河流更接近气温，深湖更稳定。
        thermal_inertia = 0.18 if self.body_type.startswith("river") else 0.08 if self.depth_factor > 0.75 else 0.12
        target_temp = air_temperature - (2.5 if self.depth_factor > 0.75 else 1.0)
        self.temperature = self.temperature * (1 - thermal_inertia) + target_temp * thermal_inertia
        
        # 河流湍动和恶劣天气提升混合作用。
        oxygen_gain = 0.008 + self.flow_rate * 0.035
        if weather in [Weather.RAINY, Weather.STORMY]:
            oxygen_gain += 0.01
        if self.body_type.startswith("river"):
            oxygen_gain += 0.01
        if self.depth_factor > 0.8:
            oxygen_gain -= 0.006
        
        # 水生植物产氧
        if has_plants:
            oxygen_gain += 0.012
            
        # 鱼类消耗氧气
        if has_fish:
            oxygen_gain -= 0.012 if self.depth_factor > 0.75 else 0.008
        self.oxygen_level = max(0.28, min(1.0, self.oxygen_level + oxygen_gain))

        # 清洁度与流速、天气、营养盐共同作用。
        clarity_shift = 0.004 + self.flow_rate * 0.01 - self.nutrient_load * 0.008
        if weather in [Weather.RAINY, Weather.STORMY]:
            clarity_shift -= 0.015 if self.body_type.startswith("river") else 0.008
        self.clarity = max(0.2, min(1.0, self.clarity + clarity_shift))

        # 营养盐在静水更容易累积，河流更容易带走。
        nutrient_shift = 0.003 if self.body_type.startswith("lake") else -0.002
        if weather == Weather.STORMY:
            nutrient_shift += 0.004
        elif weather == Weather.RAINY:
            nutrient_shift += 0.002
        if has_plants:
            nutrient_shift -= 0.002
        self.nutrient_load = max(0.1, min(1.0, self.nutrient_load + nutrient_shift))
            
        # 酸碱度在高营养盐和暴雨条件下轻微波动。
        ph_target = 7.0 - (self.nutrient_load - 0.5) * 0.6
        if weather == Weather.STORMY:
            ph_target -= 0.1
        self.ph_level = max(6.2, min(8.1, self.ph_level * 0.9 + ph_target * 0.1))


@dataclass
class Atmosphere:
    """大气系统"""
    sunlight_intensity: float = 1.0  # 阳光强度 0-2
    air_quality: float = 0.9         # 空气质量 0-1
    co2_level: float = 0.04          # CO2浓度
    wind_speed: float = 0.0          # 风速
    weather: Weather = Weather.SUNNY
    
    def update(self, hour: int, season: str, plant_count: int = 0):
        """更新大气状态"""
        # 阳光随时间变化
        if 6 <= hour <= 18:
            # 白天
            peak_hour = 12
            self.sunlight_intensity = 1.0 - abs(hour - peak_hour) / 12
        else:
            self.sunlight_intensity = 0.1
            
        # 季节影响阳光
        if season == "summer":
            self.sunlight_intensity *= 1.2
        elif season == "winter":
            self.sunlight_intensity *= 0.7
            
        # 植物吸收CO2
        if plant_count > 0:
            self.co2_level = max(0.03, self.co2_level - plant_count * 0.0001)
            self.air_quality = min(1.0, self.air_quality + 0.001)


class Environment:
    """完整环境系统 - 多层生态系统"""
    
    def __init__(self, width: int, height: int):
        self.width = width
        self.height = height
        
        # 地形网格
        self.terrain: Dict[Tuple[int, int], TerrainType] = {}
        
        # 分层系统
        self.atmosphere = Atmosphere()
        self.soil_grid: Dict[Tuple[int, int], Soil] = {}
        self.water_quality: Dict[Tuple[int, int], WaterQuality] = {}
        
        # 环境变量
        self.temperature = 20.0
        self.season = "spring"
        self.day = 0
        self.hour = 0
        
        # 水系
        self.rivers: List[List[Tuple[int, int]]] = []
        self.lakes: List[List[Tuple[int, int]]] = []
        self.water_bodies: Dict[Tuple[int, int], str] = {}
        
        # 生成环境
        self._generate_terrain()
        self._generate_water_bodies()
        self._apply_shoreline_ecotones()
        self._initialize_soil()
        self._initialize_water_quality()
        
    def _generate_terrain(self):
        """生成地形 - 更丰富的地形类型"""
        # 初始化为草地
        for y in range(self.height):
            for x in range(self.width):
                self.terrain[(y, x)] = TerrainType.GRASS
                
        # 生成森林区域
        forest_count = random.randint(2, 5)
        for _ in range(forest_count):
            fx = random.randint(0, self.width - 1)
            fy = random.randint(0, self.height - 1)
            radius = random.randint(3, 6)
            
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    if dx*dx + dy*dy <= radius*radius:
                        nx, ny = fx + dx, fy + dy
                        if 0 <= nx < self.width and 0 <= ny < self.height:
                            self.terrain[(ny, nx)] = TerrainType.FOREST
                            
        # 生成岩石区
        rock_count = random.randint(1, 3)
        for _ in range(rock_count):
            rx = random.randint(0, self.width - 1)
            ry = random.randint(0, self.height - 1)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    nx, ny = rx + dx, ry + dy
                    if 0 <= nx < self.width and 0 <= ny < self.height:
                        if random.random() < 0.7:
                            self.terrain[(ny, nx)] = TerrainType.ROCK
                            
        # 生成沙地区域
        sand_count = random.randint(1, 2)
        for _ in range(sand_count):
            sx = random.randint(0, self.width - 1)
            sy = random.randint(0, self.height - 1)
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    nx, ny = sx + dx, sy + dy
                    if 0 <= nx < self.width and 0 <= ny < self.height:
                        if random.random() < 0.5:
                            self.terrain[(ny, nx)] = TerrainType.SAND
                            
    def _generate_water_bodies(self):
        """生成水系 - 河流和湖泊"""
        # 生成湖泊
        lake_count = random.randint(1, 3)
        for _ in range(lake_count):
            lx = random.randint(3, self.width - 4)
            ly = random.randint(3, self.height - 4)
            
            lake_cells = []
            # 湖泊中心（深水）
            radius = random.randint(2, 4)
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    if dx*dx + dy*dy <= radius*radius:
                        nx, ny = lx + dx, ly + dy
                        if 0 <= nx < self.width and 0 <= ny < self.height:
                            dist = (dx*dx + dy*dy) ** 0.5
                            if dist <= radius * 0.6:
                                self.terrain[(ny, nx)] = TerrainType.WATER_DEEP
                                self.water_bodies[(ny, nx)] = "lake_deep"
                            else:
                                self.terrain[(ny, nx)] = TerrainType.WATER_SHALLOW
                                self.water_bodies[(ny, nx)] = "lake_shallow"
                            lake_cells.append((nx, ny))
                            
            self.lakes.append(lake_cells)
            
        # 生成河流
        river_count = random.randint(1, 2)
        for _ in range(river_count):
            # 河流从一边流向另一边
            start_y = random.randint(0, self.height - 1)
            river_cells = []
            
            x, y = 0, start_y
            while x < self.width:
                self.terrain[(y, x)] = TerrainType.RIVER
                self.water_bodies[(y, x)] = "river_channel"
                river_cells.append((x, y))
                
                # 河流有弯曲
                x += 1
                if random.random() < 0.3:
                    y += random.choice([-1, 1])
                    y = max(0, min(self.height - 1, y))
                    
            self.rivers.append(river_cells)

    def _apply_shoreline_ecotones(self):
        """在河岸和湖岸生成泥地/沙地过渡带。"""
        for (y, x), terrain in list(self.terrain.items()):
            if terrain not in [TerrainType.WATER_SHALLOW, TerrainType.WATER_DEEP, TerrainType.RIVER]:
                continue
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    ny, nx = y + dy, x + dx
                    if not (0 <= nx < self.width and 0 <= ny < self.height):
                        continue
                    neighbor = self.terrain.get((ny, nx), TerrainType.GRASS)
                    if neighbor in [TerrainType.WATER_SHALLOW, TerrainType.WATER_DEEP, TerrainType.RIVER, TerrainType.ROCK]:
                        continue
                    if terrain == TerrainType.RIVER:
                        if random.random() < 0.45:
                            self.terrain[(ny, nx)] = TerrainType.MUD
                    else:
                        if random.random() < 0.25:
                            self.terrain[(ny, nx)] = TerrainType.SAND
                        elif random.random() < 0.55:
                            self.terrain[(ny, nx)] = TerrainType.MUD
            
    def _initialize_soil(self):
        """初始化土壤"""
        for y in range(self.height):
            for x in range(self.width):
                terrain = self.terrain.get((y, x), TerrainType.GRASS)
                
                # 根据地形设置初始土壤属性
                if terrain in [TerrainType.GRASS, TerrainType.FOREST]:
                    fertility = random.uniform(0.5, 0.9)
                    moisture = random.uniform(0.4, 0.7)
                elif terrain == TerrainType.SAND:
                    fertility = random.uniform(0.1, 0.3)
                    moisture = random.uniform(0.1, 0.3)
                elif terrain == TerrainType.MUD:
                    fertility = random.uniform(0.6, 0.8)
                    moisture = random.uniform(0.7, 0.95)
                else:
                    fertility = 0.2
                    moisture = 0.3
                    
                self.soil_grid[(y, x)] = Soil(
                    fertility=fertility,
                    moisture=moisture
                )
                
    def _initialize_water_quality(self):
        """初始化水质"""
        for y in range(self.height):
            for x in range(self.width):
                terrain = self.terrain.get((y, x), TerrainType.GRASS)
                
                if terrain in [TerrainType.WATER_SHALLOW, TerrainType.WATER_DEEP, TerrainType.RIVER]:
                    body_type = self.water_bodies.get((y, x), "lake_shallow")
                    if body_type == "river_channel":
                        oxygen = random.uniform(0.82, 0.98)
                        clarity = random.uniform(0.65, 0.88)
                        flow_rate = random.uniform(0.65, 1.0)
                        depth_factor = random.uniform(0.25, 0.45)
                        nutrient = random.uniform(0.28, 0.55)
                    elif body_type == "lake_deep":
                        oxygen = random.uniform(0.58, 0.82)
                        clarity = random.uniform(0.55, 0.82)
                        flow_rate = random.uniform(0.02, 0.14)
                        depth_factor = random.uniform(0.78, 1.0)
                        nutrient = random.uniform(0.42, 0.7)
                    else:
                        oxygen = random.uniform(0.68, 0.9)
                        clarity = random.uniform(0.5, 0.78)
                        flow_rate = random.uniform(0.08, 0.24)
                        depth_factor = random.uniform(0.35, 0.68)
                        nutrient = random.uniform(0.38, 0.72)
                        
                    self.water_quality[(y, x)] = WaterQuality(
                        oxygen_level=oxygen,
                        clarity=clarity,
                        temperature=self.temperature - 5,
                        flow_rate=flow_rate,
                        depth_factor=depth_factor,
                        nutrient_load=nutrient,
                        body_type=body_type,
                    )
                    
    def update(self, plant_count: int = 0, fish_count: int = 0):
        """更新环境状态"""
        # 时间流逝
        self.hour += 1
        if self.hour >= 24:
            self.hour = 0
            self.day += 1
            
        # 季节变化
        if self.day >= 30:
            self.day = 0
            seasons = ["spring", "summer", "autumn", "winter"]
            idx = seasons.index(self.season)
            self.season = seasons[(idx + 1) % 4]
            
        # 温度随季节变化
        season_temp = {"spring": 20, "summer": 30, "autumn": 15, "winter": 5}
        base_temp = season_temp[self.season]
        self.temperature = base_temp + random.uniform(-5, 5)
        
        # 更新大气
        self.atmosphere.update(self.hour, self.season, plant_count)
        
        # 随机天气变化
        if random.random() < 0.05:
            self._change_weather()
            
        # 更新土壤
        for pos, soil in self.soil_grid.items():
            terrain = self.terrain.get(pos, TerrainType.GRASS)
            has_plants = terrain in [TerrainType.GRASS, TerrainType.FOREST]
            soil.update(self.atmosphere.weather, has_plants)
            
        # 更新水质
        for pos, water in self.water_quality.items():
            water.update(self.temperature, self.atmosphere.weather, plant_count > 0, fish_count > 0)
            
    def _change_weather(self):
        """天气变化"""
        # 季节影响天气概率
        if self.season == "summer":
            weights = [0.5, 0.2, 0.2, 0.1, 0.0, 0.0]  # 夏季多晴
        elif self.season == "winter":
            weights = [0.3, 0.2, 0.1, 0.0, 0.4, 0.0]  # 冬季多雪
        elif self.season == "spring":
            weights = [0.3, 0.3, 0.3, 0.05, 0.0, 0.05]  # 春季多雨
        else:
            weights = [0.4, 0.3, 0.2, 0.05, 0.0, 0.05]
            
        self.atmosphere.weather = random.choices(list(Weather), weights=weights)[0]
        
        # 天气影响风速
        if self.atmosphere.weather == Weather.STORMY:
            self.atmosphere.wind_speed = random.uniform(5, 15)
        elif self.atmosphere.weather in [Weather.RAINY, Weather.SNOWY]:
            self.atmosphere.wind_speed = random.uniform(1, 5)
        else:
            self.atmosphere.wind_speed = random.uniform(0, 2)

    @property
    def weather(self) -> str:
        """Legacy-compatible weather accessor."""
        return self.atmosphere.weather.value
            
    def get_terrain(self, x: int, y: int) -> str:
        """获取地形类型"""
        terrain = self.terrain.get((y, x), TerrainType.GRASS)
        return terrain.value
        
    def get_soil(self, x: int, y: int) -> Optional[Soil]:
        """获取土壤信息"""
        return self.soil_grid.get((y, x))
        
    def get_water_quality(self, x: int, y: int) -> Optional[WaterQuality]:
        """获取水质信息"""
        return self.water_quality.get((y, x))

    def get_water_body_type(self, x: int, y: int) -> Optional[str]:
        """获取水体类型，如 river_channel / lake_shallow / lake_deep。"""
        return self.water_bodies.get((y, x))
        
    def is_water(self, x: int, y: int) -> bool:
        """判断是否是水域"""
        terrain = self.terrain.get((y, x), TerrainType.GRASS)
        return terrain in [TerrainType.WATER_SHALLOW, TerrainType.WATER_DEEP, TerrainType.RIVER]
        
    def is_land(self, x: int, y: int) -> bool:
        """判断是否是陆地"""
        return not self.is_water(x, y)
        
    def get_sunlight_factor(self) -> float:
        """获取阳光因子（影响植物生长）"""
        base = self.atmosphere.sunlight_intensity
        
        # 天气影响
        if self.atmosphere.weather == Weather.CLOUDY:
            base *= 0.7
        elif self.atmosphere.weather in [Weather.RAINY, Weather.FOGGY]:
            base *= 0.5
        elif self.atmosphere.weather == Weather.STORMY:
            base *= 0.3
            
        return base
        
    def get_environment_summary(self) -> Dict:
        """获取环境摘要"""
        water_cells = sum(1 for t in self.terrain.values() 
                        if t in [TerrainType.WATER_SHALLOW, TerrainType.WATER_DEEP, TerrainType.RIVER])
        forest_cells = sum(1 for t in self.terrain.values() if t == TerrainType.FOREST)
        river_cells = sum(1 for t in self.terrain.values() if t == TerrainType.RIVER)
        lake_cells = sum(1 for t in self.terrain.values() if t in [TerrainType.WATER_SHALLOW, TerrainType.WATER_DEEP])
        
        avg_soil_fertility = sum(s.fertility for s in self.soil_grid.values()) / len(self.soil_grid) if self.soil_grid else 0
        avg_water_oxygen = sum(w.oxygen_level for w in self.water_quality.values()) / len(self.water_quality) if self.water_quality else 0
        avg_water_flow = sum(w.flow_rate for w in self.water_quality.values()) / len(self.water_quality) if self.water_quality else 0
        avg_water_nutrients = sum(w.nutrient_load for w in self.water_quality.values()) / len(self.water_quality) if self.water_quality else 0
        
        return {
            "weather": self.atmosphere.weather.value,
            "temperature": round(self.temperature, 1),
            "sunlight": round(self.atmosphere.sunlight_intensity, 2),
            "wind_speed": round(self.atmosphere.wind_speed, 1),
            "air_quality": round(self.atmosphere.air_quality, 2),
            "season": self.season,
            "day": self.day,
            "hour": self.hour,
            "water_coverage": water_cells / (self.width * self.height),
            "river_coverage": river_cells / (self.width * self.height),
            "lake_coverage": lake_cells / (self.width * self.height),
            "forest_coverage": forest_cells / (self.width * self.height),
            "avg_soil_fertility": round(avg_soil_fertility, 2),
            "avg_water_oxygen": round(avg_water_oxygen, 2),
            "avg_water_flow": round(avg_water_flow, 2),
            "avg_water_nutrients": round(avg_water_nutrients, 2),
        }

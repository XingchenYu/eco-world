"""
2D渲染模块 - 美化版生态系统可视化
"""

import pygame
import sys
from typing import Dict, Tuple, List, Optional
import math
import random

from ..core.ecosystem import Ecosystem


class Renderer:
    """美化版渲染器 - 真实地形 + 生物动画"""
    
    def __init__(self, ecosystem: Ecosystem, config: dict = None):
        pygame.init()
        
        self.ecosystem = ecosystem
        self.config = config or {}
        
        # 窗口设置
        self.grid_size = 16  # 格子大小
        self.world_width = ecosystem.width
        self.world_height = ecosystem.height
        
        # 实际像素大小
        self.map_width = self.world_width * self.grid_size
        self.map_height = self.world_height * self.grid_size
        
        # 右侧面板
        self.panel_width = 280
        
        # 底部信息栏
        self.bottom_height = 100
        
        # 总窗口大小
        self.window_width = self.map_width + self.panel_width
        self.window_height = self.map_height + self.bottom_height
        
        self.screen = pygame.display.set_mode((self.window_width, self.window_height))
        pygame.display.set_caption("🌍 EcoWorld - 虚拟生态系统")
        
        # 🎨 颜色方案
        self.terrain_colors = {
            "grass": (76, 153, 0),        # 草地
            "forest": (34, 85, 0),         # 森林
            "rock": (128, 128, 128),       # 岩石
            "water_shallow": (64, 164, 223),  # 浅水
            "water_deep": (25, 100, 180),   # 深水
            "river": (30, 144, 255),        # 河流
            "sand": (238, 214, 175),        # 沙地
            "mud": (139, 90, 43),           # 泥地
        }
        
        # 地形中文名
        self.terrain_names = {
            "grass": "草地", "forest": "森林", "rock": "岩石",
            "water_shallow": "浅水", "water_deep": "深水", "river": "河流",
            "sand": "沙地", "mud": "泥地"
        }
        
        # 植物颜色
        self.plant_colors = {
            "grass": (50, 205, 50),
            "bush": (34, 139, 34),
            "flower": (255, 182, 193),
            "moss": (0, 128, 0),
        }
        
        # 动物颜色
        self.animal_colors = {
            "insect": (139, 69, 19),
            "rabbit": (245, 245, 220),
            "fox": (255, 140, 0),
            "deer": (160, 82, 45),
            "mouse": (150, 120, 90),
            "bird": (70, 130, 180),
            "snake": (85, 107, 47),
            "bee": (255, 215, 0),
            "eagle": (139, 69, 19),
            "owl": (102, 51, 0),
            "duck": (255, 215, 0),
            "swan": (255, 255, 255),
            "sparrow": (165, 42, 42),
            "parrot": (0, 255, 127),
            "kingfisher": (0, 191, 255),
            "frog": (50, 205, 50),
        }
        
        # 水生生物颜色
        self.aquatic_colors = {
            "algae": (0, 128, 0),
            "seaweed": (34, 139, 34),
            "plankton": (200, 200, 200),
            "small_fish": (255, 215, 0),
            "minnow": (135, 206, 235),
            "carp": (255, 140, 0),
            "catfish": (105, 105, 105),
            "large_fish": (70, 130, 180),
            "pufferfish": (255, 228, 181),
            "shrimp": (255, 160, 122),
            "crab": (178, 34, 34),
            "tadpole": (0, 0, 0),
            "water_strider": (47, 79, 79),
        }
        
        # UI颜色
        self.ui_colors = {
            "panel_bg": (25, 25, 35),
            "panel_border": (60, 60, 80),
            "text": (220, 220, 220),
            "text_dim": (120, 120, 120),
            "health_good": (50, 205, 50),
            "health_warning": (255, 200, 50),
            "health_critical": (255, 80, 80),
            "highlight": (100, 149, 237),
        }
        
        # 字体
        try:
            self.font_small = pygame.font.SysFont("Arial", 11)
            self.font_normal = pygame.font.SysFont("Arial", 13)
            self.font_large = pygame.font.SysFont("Arial", 16, bold=True)
            self.font_title = pygame.font.SysFont("Arial", 18, bold=True)
        except:
            self.font_small = pygame.font.Font(None, 14)
            self.font_normal = pygame.font.Font(None, 16)
            self.font_large = pygame.font.Font(None, 20)
            self.font_title = pygame.font.Font(None, 24)
        
        # 动画状态
        self.tick = 0
        self.paused = False
        self.speed = 1
        self.show_panel = True
        
        # 相机/视图
        self.camera_x = 0
        self.camera_y = 0
        
        # 提示信息
        self.notifications = []
        self._terrain_surface = None
        self._terrain_dirty = True
        self._tile_variations = {}
        self._decor_variations = {}
        self._init_render_cache()

    def _init_render_cache(self):
        """初始化静态渲染缓存，避免每帧随机闪烁。"""
        for y in range(self.world_height):
            for x in range(self.world_width):
                seed = x * 97 + y * 131
                rng = random.Random(seed)
                self._tile_variations[(x, y)] = (
                    rng.randint(-5, 5),
                    rng.randint(-5, 5),
                    rng.randint(-5, 5),
                )
                self._decor_variations[(x, y)] = [
                    (rng.randint(-3, 3), rng.randint(-3, 3))
                    for _ in range(3)
                ]
        
    def run(self):
        """主循环"""
        clock = pygame.time.Clock()
        running = True
        
        while running:
            # 事件处理
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    self._handle_key(event.key)
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    self._handle_click(event.pos)
                    
            # 更新
            if not self.paused:
                for _ in range(self.speed):
                    self.ecosystem.update()
            
            self.tick += 1
            
            # 清理过期通知
            self.notifications = [(msg, t) for msg, t in self.notifications if self.tick - t < 120]
            
            # 渲染
            self._render()
            
            pygame.display.flip()
            clock.tick(60)
            
        pygame.quit()
        sys.exit()
        
    def _handle_key(self, key):
        """处理按键"""
        if key == pygame.K_SPACE:
            self.paused = not self.paused
            self._notify("⏸ 已暂停" if self.paused else "▶ 继续运行")
        elif key == pygame.K_EQUALS or key == pygame.K_PLUS:
            self.speed = min(10, self.speed + 1)
            self._notify(f"速度: {self.speed}倍")
        elif key == pygame.K_MINUS:
            self.speed = max(1, self.speed - 1)
            self._notify(f"速度: {self.speed}倍")
        elif key == pygame.K_p:
            self.show_panel = not self.show_panel
        elif key == pygame.K_g:
            pos = self._random_land_pos()
            if pos:
                self.ecosystem.spawn_plant("grass", pos, source="manual")
                self._notify("🌿 添加了草")
        elif key == pygame.K_r:
            pos = self._random_land_pos()
            if pos:
                self.ecosystem.spawn_animal("rabbit", pos, source="manual")
                self._notify("🐰 添加了兔子")
        elif key == pygame.K_f:
            pos = self._random_land_pos()
            if pos:
                self.ecosystem.spawn_animal("fox", pos, source="manual")
                self._notify("🦊 添加了狐狸")
        elif key == pygame.K_i:
            pos = self._random_land_pos()
            if pos:
                self.ecosystem.spawn_animal("insect", pos, source="manual")
                self._notify("🐛 添加了昆虫")
        elif key == pygame.K_a:
            pos = self._random_water_pos()
            if pos:
                self.ecosystem.spawn_aquatic("algae", pos, source="manual")
                self._notify("🟢 添加了藻类")
        elif key == pygame.K_s:
            pos = self._random_water_pos()
            if pos:
                self.ecosystem.spawn_aquatic("small_fish", pos, source="manual")
                self._notify("🐟 添加了小鱼")
        elif key == pygame.K_q:
            pygame.quit()
            sys.exit()
            
    def _handle_click(self, pos):
        """处理鼠标点击"""
        if pos[0] < self.map_width and pos[1] < self.map_height:
            grid_x = pos[0] // self.grid_size
            grid_y = pos[1] // self.grid_size
            
            terrain = self.ecosystem.environment.get_terrain(grid_x, grid_y)
            terrain_name = self.terrain_names.get(terrain, terrain)
            self._notify(f"坐标({grid_x}, {grid_y}) - {terrain_name}")
            
    def _notify(self, message: str):
        """添加通知"""
        self.notifications.append((message, self.tick))
        
    def _random_land_pos(self):
        """随机陆地位置"""
        for _ in range(100):
            x = random.randint(0, self.world_width - 1)
            y = random.randint(0, self.world_height - 1)
            if self.ecosystem.environment.is_land(x, y):
                return (x, y)
        return None
        
    def _random_water_pos(self):
        """随机水域位置"""
        for _ in range(100):
            x = random.randint(0, self.world_width - 1)
            y = random.randint(0, self.world_height - 1)
            if self.ecosystem.environment.is_water(x, y):
                return (x, y)
        return None
        
    def _render(self):
        """渲染画面"""
        # 清屏
        self.screen.fill((20, 20, 30))
        
        # 1. 渲染地形
        self._render_terrain()
        
        # 2. 渲染水生生物（在水下面）
        self._render_aquatic()
        
        # 3. 渲染植物
        self._render_plants()
        
        # 4. 渲染陆地动物
        self._render_animals()
        
        # 5. 渲染右侧面板
        if self.show_panel:
            self._render_side_panel()
            
        # 6. 渲染底部信息栏
        self._render_bottom_bar()
        
        # 7. 渲染通知
        self._render_notifications()
        
    def _render_terrain(self):
        """渲染地形 - 带纹理效果"""
        if self._terrain_surface is None or self._terrain_dirty:
            self._rebuild_terrain_surface()
        self.screen.blit(self._terrain_surface, (0, 0))

    def _rebuild_terrain_surface(self):
        """重建静态地形层。"""
        env = self.ecosystem.environment
        self._terrain_surface = pygame.Surface((self.map_width, self.map_height))

        for y in range(self.world_height):
            for x in range(self.world_width):
                terrain = env.get_terrain(x, y)
                base_color = self.terrain_colors.get(terrain, (76, 153, 0))
                
                # 添加稳定纹理变化，避免每帧闪烁
                vr, vg, vb = self._tile_variations[(x, y)]
                r = base_color[0] + vr
                g = base_color[1] + vg
                b = base_color[2] + vb
                color = (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
                
                rect = pygame.Rect(
                    x * self.grid_size,
                    y * self.grid_size,
                    self.grid_size,
                    self.grid_size
                )
                
                pygame.draw.rect(self._terrain_surface, color, rect)
                
                # 地形装饰
                cx = x * self.grid_size + self.grid_size // 2
                cy = y * self.grid_size + self.grid_size // 2
                decor = self._decor_variations[(x, y)]
                
                if terrain == "forest":
                    # 森林：小树装饰
                    pygame.draw.circle(self._terrain_surface, (20, 60, 0), (cx, cy + 2), 4)
                    pygame.draw.polygon(self._terrain_surface, (0, 100, 0), 
                        [(cx, cy - 4), (cx - 4, cy + 2), (cx + 4, cy + 2)])
                        
                elif terrain == "rock":
                    # 岩石：石头形状
                    pygame.draw.polygon(self._terrain_surface, (100, 100, 100),
                        [(cx, cy - 3), (cx + 4, cy), (cx + 2, cy + 3), 
                         (cx - 2, cy + 3), (cx - 4, cy)])
                         
                elif terrain == "sand":
                    # 沙地：小点装饰
                    for dx, dy in decor[:2]:
                        pygame.draw.circle(self._terrain_surface, (200, 180, 150), 
                            (cx + dx, cy + dy), 1)
                            
                elif terrain in ["water_shallow", "water_deep", "river"]:
                    # 水波纹效果
                    wave_offset = math.sin(self.tick * 0.1 + x * 0.5 + y * 0.3) * 2
                    wave_color = (
                        min(255, base_color[0] + int(wave_offset)),
                        min(255, base_color[1] + int(wave_offset)),
                        min(255, base_color[2] + int(wave_offset))
                    )
                    pygame.draw.circle(self._terrain_surface, wave_color, (cx, cy), 2)

        self._terrain_dirty = False
                    
    def _render_plants(self):
        """渲染植物 - 不同形状和大小"""
        for plant in self.ecosystem.plants:
            if not plant.alive:
                continue
                
            x, y = plant.position
            cx = x * self.grid_size + self.grid_size // 2
            cy = y * self.grid_size + self.grid_size // 2
            
            color = self.plant_colors.get(plant.species, (50, 205, 50))
            size = max(2, int(plant.size * 2))
            
            if plant.species == "grass":
                # 草：多条竖线
                for i in range(-1, 2):
                    sway = ((plant.position[0] * 17 + plant.position[1] * 11 + i * 7 + self.tick) % 3) - 1
                    pygame.draw.line(self.screen, color,
                        (cx + i * 2, cy + 4),
                        (cx + i * 2 + sway, cy - size),
                        1)
                        
            elif plant.species == "bush":
                # 灌木：圆形
                pygame.draw.circle(self.screen, color, (cx, cy), size)
                pygame.draw.circle(self.screen, (color[0] - 20, color[1] - 20, color[2]), 
                    (cx - 2, cy - 2), size - 1)
                    
            elif plant.species == "flower":
                # 花：花瓣形状
                pygame.draw.circle(self.screen, (255, 255, 0), (cx, cy), 2)  # 花心
                for angle in range(0, 360, 60):
                    rad = math.radians(angle + self.tick * 2)
                    px = cx + int(math.cos(rad) * 3)
                    py = cy + int(math.sin(rad) * 3)
                    pygame.draw.circle(self.screen, color, (px, py), 2)
                    
            elif plant.species == "moss":
                # 苔藓：小点群
                for dx, dy in self._decor_variations.get(plant.position, [(-1, 0), (0, 1), (1, -1)]):
                    pygame.draw.circle(self.screen, color, (cx + dx, cy + dy), 1)
                    
            # 显示种子状态
            if hasattr(plant, 'has_seeds') and plant.has_seeds:
                pygame.draw.circle(self.screen, (255, 255, 0), (cx, cy - 5), 2)
                
    def _render_aquatic(self):
        """渲染水生生物"""
        for creature in self.ecosystem.aquatic_creatures:
            if not creature.alive:
                continue
                
            x, y = creature.position
            cx = x * self.grid_size + self.grid_size // 2
            cy = y * self.grid_size + self.grid_size // 2
            
            color = self.aquatic_colors.get(creature.species, (100, 100, 100))
            
            # 根据类型绘制不同形状
            if creature.species in ["algae", "seaweed"]:
                # 水生植物：静态
                size = max(2, int(getattr(creature, 'size', 1) * 2))
                if creature.species == "algae":
                    pygame.draw.circle(self.screen, color, (cx, cy), size)
                else:
                    # 水草：多条竖线
                    for i in range(-1, 2):
                        pygame.draw.line(self.screen, color,
                            (cx + i * 2, cy + 3), (cx + i * 2, cy - size), 2)
                            
            elif creature.species == "plankton":
                # 浮游生物：小点，轻微漂浮
                dx = int(math.sin(self.tick * 0.2 + x) * 2)
                pygame.draw.circle(self.screen, color, (cx + dx, cy), 1)
                
            elif "fish" in creature.species or creature.species in ["minnow", "carp", "catfish", "pufferfish"]:
                # 鱼类：鱼形
                self._draw_fish(cx, cy, color, creature.species)
                
            elif creature.species == "shrimp":
                # 虾：小曲线
                pygame.draw.arc(self.screen, color,
                    (cx - 3, cy - 2, 6, 4), 0, 3.14, 1)
                    
            elif creature.species == "crab":
                # 螃蟹：椭圆+腿
                pygame.draw.ellipse(self.screen, color, (cx - 3, cy - 2, 6, 4))
                pygame.draw.line(self.screen, color, (cx - 4, cy), (cx - 6, cy + 2), 1)
                pygame.draw.line(self.screen, color, (cx + 4, cy), (cx + 6, cy + 2), 1)
                
            elif creature.species == "frog":
                # 青蛙：圆+腿
                pygame.draw.circle(self.screen, color, (cx, cy), 3)
                pygame.draw.circle(self.screen, (0, 0, 0), (cx - 1, cy - 1), 1)
                pygame.draw.circle(self.screen, (0, 0, 0), (cx + 1, cy - 1), 1)
                
            elif creature.species == "tadpole":
                # 蝌蚪：圆+尾巴
                pygame.draw.circle(self.screen, (30, 30, 30), (cx, cy), 2)
                pygame.draw.line(self.screen, (30, 30, 30), (cx, cy), (cx + 3, cy + 2), 1)
                
    def _draw_fish(self, cx, cy, color, species):
        """绘制鱼"""
        # 身体
        pygame.draw.ellipse(self.screen, color, (cx - 4, cy - 2, 8, 4))
        
        # 尾巴
        tail_dir = 1 if self.tick % 20 < 10 else -1
        pygame.draw.polygon(self.screen, color,
            [(cx + 4, cy), (cx + 6, cy - 2 * tail_dir), (cx + 6, cy + 2 * tail_dir)])
            
        # 眼睛
        pygame.draw.circle(self.screen, (255, 255, 255), (cx - 2, cy), 1)
        
    def _render_animals(self):
        """渲染陆地动物"""
        for animal in self.ecosystem.animals:
            if not animal.alive:
                continue
                
            x, y = animal.position
            cx = x * self.grid_size + self.grid_size // 2
            cy = y * self.grid_size + self.grid_size // 2
            
            color = self.animal_colors.get(animal.species, (150, 150, 150))
            
            # 移动动画
            dx = int(math.sin(self.tick * 0.3) * 1) if not self.paused else 0
            
            if animal.species == "insect":
                # 昆虫：小点，快速移动
                pygame.draw.circle(self.screen, color, (cx + dx, cy), 2)
                
            elif animal.species == "rabbit":
                # 兔子：圆耳朵
                pygame.draw.circle(self.screen, color, (cx, cy), 4)  # 身体
                pygame.draw.ellipse(self.screen, color, (cx - 3, cy - 6, 2, 4))  # 左耳
                pygame.draw.ellipse(self.screen, color, (cx + 1, cy - 6, 2, 4))  # 右耳
                
            elif animal.species == "fox":
                # 狐狸：三角耳朵
                pygame.draw.circle(self.screen, color, (cx, cy), 4)
                pygame.draw.polygon(self.screen, color, 
                    [(cx - 3, cy - 4), (cx - 1, cy - 1), (cx - 4, cy - 1)])  # 左耳
                pygame.draw.polygon(self.screen, color,
                    [(cx + 3, cy - 4), (cx + 1, cy - 1), (cx + 4, cy - 1)])  # 右耳
                    
            elif animal.species == "deer":
                # 鹿：大圆+角
                pygame.draw.circle(self.screen, color, (cx, cy), 5)
                pygame.draw.line(self.screen, (100, 60, 30), (cx - 2, cy - 5), (cx - 3, cy - 8), 1)
                pygame.draw.line(self.screen, (100, 60, 30), (cx + 2, cy - 5), (cx + 3, cy - 8), 1)
                
            elif animal.species == "mouse":
                # 老鼠：小椭圆
                pygame.draw.ellipse(self.screen, color, (cx - 3, cy - 2, 6, 4))
                pygame.draw.circle(self.screen, (255, 200, 200), (cx + 2, cy), 1)  # 耳朵
                
            elif animal.species == "bird":
                # 鸟：飞行动画
                wing = int(math.sin(self.tick * 0.3) * 2)
                pygame.draw.circle(self.screen, color, (cx, cy), 3)
                pygame.draw.line(self.screen, color, (cx - 3, cy + wing), (cx - 5, cy + wing), 1)
                pygame.draw.line(self.screen, color, (cx + 3, cy + wing), (cx + 5, cy + wing), 1)
                
            elif animal.species == "snake":
                # 蛇：曲线
                points = []
                for i in range(4):
                    px = cx - 3 + i * 2
                    py = cy + int(math.sin(self.tick * 0.2 + i) * 2)
                    points.append((px, py))
                if len(points) >= 2:
                    pygame.draw.lines(self.screen, color, False, points, 2)
                    
            elif animal.species == "bee":
                # 蜜蜂：黄黑条纹
                pygame.draw.circle(self.screen, color, (cx, cy), 2)
                pygame.draw.circle(self.screen, (0, 0, 0), (cx + 1, cy), 1)
                pygame.draw.circle(self.screen, color, (cx + 2, cy), 1)
                
            elif animal.species == "eagle":
                # 老鹰：大鸟
                wing = int(math.sin(self.tick * 0.2) * 3)
                pygame.draw.circle(self.screen, color, (cx, cy), 4)
                pygame.draw.line(self.screen, color, (cx - 4, cy + wing), (cx - 8, cy + wing - 2), 2)
                pygame.draw.line(self.screen, color, (cx + 4, cy + wing), (cx + 8, cy + wing - 2), 2)
                
            elif animal.species == "owl":
                # 猫头鹰：大眼睛
                pygame.draw.circle(self.screen, color, (cx, cy), 4)
                pygame.draw.circle(self.screen, (255, 255, 0), (cx - 1, cy - 1), 2)
                pygame.draw.circle(self.screen, (255, 255, 0), (cx + 1, cy - 1), 2)
                pygame.draw.circle(self.screen, (0, 0, 0), (cx - 1, cy - 1), 1)
                pygame.draw.circle(self.screen, (0, 0, 0), (cx + 1, cy - 1), 1)
                
            elif animal.species in ["duck", "swan"]:
                # 鸭/天鹅：水鸟
                pygame.draw.ellipse(self.screen, color, (cx - 4, cy - 2, 8, 4))
                pygame.draw.circle(self.screen, color, (cx - 4, cy - 1), 2)
                pygame.draw.polygon(self.screen, (255, 200, 0), 
                    [(cx - 6, cy - 1), (cx - 8, cy), (cx - 6, cy + 1)])
                    
            elif animal.species == "sparrow":
                # 麻雀：小鸟
                pygame.draw.circle(self.screen, color, (cx, cy), 2)
                pygame.draw.line(self.screen, color, (cx - 2, cy), (cx - 4, cy), 1)
                
            elif animal.species == "parrot":
                # 鹦鹉：彩色
                pygame.draw.circle(self.screen, color, (cx, cy), 3)
                pygame.draw.polygon(self.screen, (255, 100, 100), 
                    [(cx - 3, cy), (cx - 5, cy - 1), (cx - 5, cy + 1)])
                    
            elif animal.species == "kingfisher":
                # 翠鸟：蓝绿色
                pygame.draw.circle(self.screen, color, (cx, cy), 3)
                pygame.draw.polygon(self.screen, (255, 150, 0),
                    [(cx + 2, cy), (cx + 5, cy - 1), (cx + 5, cy + 1)])
                    
            # 显示状态指示器
            if hasattr(animal, 'behavior_state'):
                state = animal.behavior_state.value
                if state == "escaping":
                    pygame.draw.circle(self.screen, (255, 0, 0), (cx, cy - 6), 2)
                elif state == "hunting":
                    pygame.draw.circle(self.screen, (255, 165, 0), (cx, cy - 6), 2)
                    
            # 怀孕状态
            if hasattr(animal, 'pregnant') and animal.pregnant:
                pygame.draw.circle(self.screen, (255, 192, 203), (cx, cy + 5), 2)
                
    def _render_side_panel(self):
        """渲染右侧信息面板"""
        panel_x = self.map_width
        panel_rect = pygame.Rect(panel_x, 0, self.panel_width, self.map_height)
        
        # 背景
        pygame.draw.rect(self.screen, self.ui_colors["panel_bg"], panel_rect)
        pygame.draw.line(self.screen, self.ui_colors["panel_border"],
            (panel_x, 0), (panel_x, self.map_height), 2)
            
        y = 10
        stats = self.ecosystem.get_statistics()
        
        # 季节中文名
        season_names = {"spring": "春季", "summer": "夏季", "autumn": "秋季", "winter": "冬季"}
        season_name = season_names.get(stats['season'], stats['season'])
        
        # 天气中文名
        weather_names = {"sunny": "晴天", "cloudy": "多云", "rainy": "雨天", 
                        "stormy": "暴风雨", "snowy": "下雪", "foggy": "雾天"}
        weather_name = weather_names.get(stats['weather'], stats['weather'])
        
        # 标题
        title = self.font_title.render("🌍 生态世界", True, self.ui_colors["text"])
        self.screen.blit(title, (panel_x + 10, y))
        y += 30
        
        # 时间信息
        time_text = f"第{stats['day']}天 | {season_name} | {stats['temperature']:.0f}°C"
        time_surf = self.font_normal.render(time_text, True, self.ui_colors["text"])
        self.screen.blit(time_surf, (panel_x + 10, y))
        y += 20
        
        weather_text = f"🌤 {weather_name} | 阳光: {stats['sunlight']:.0%}"
        weather_surf = self.font_small.render(weather_text, True, self.ui_colors["text_dim"])
        self.screen.blit(weather_surf, (panel_x + 10, y))
        y += 25
        
        # 分隔线
        pygame.draw.line(self.screen, self.ui_colors["panel_border"],
            (panel_x + 10, y), (panel_x + self.panel_width - 10, y))
        y += 10
        
        # 健康度
        health = stats.get("health", 0)
        health_color = self._get_health_color(health)
        
        health_text = self.font_normal.render(f"生态健康度: {health:.0f}", True, health_color)
        self.screen.blit(health_text, (panel_x + 10, y))
        y += 20
        
        # 健康度条
        bar_width = self.panel_width - 30
        pygame.draw.rect(self.screen, (40, 40, 40), (panel_x + 10, y, bar_width, 10))
        pygame.draw.rect(self.screen, health_color, (panel_x + 10, y, int(bar_width * health / 100), 10))
        y += 20
        
        # 分隔线
        pygame.draw.line(self.screen, self.ui_colors["panel_border"],
            (panel_x + 10, y), (panel_x + self.panel_width - 10, y))
        y += 10
        
        # 陆地生物统计
        land_title = self.font_normal.render("🌿 陆地生物", True, self.ui_colors["text"])
        self.screen.blit(land_title, (panel_x + 10, y))
        y += 20
        
        land_species = [
            ("🌿 草", "grass"), ("🌳 灌木", "bush"), ("🌸 花", "flower"),
            ("🐛 昆虫", "insect"), ("🐰 兔子", "rabbit"), ("🦊 狐狸", "fox"),
            ("🦌 鹿", "deer"), ("🐭 老鼠", "mouse"), ("🐦 鸟", "bird"),
        ]
        
        species_counts = stats.get("species", {})
        for emoji_name, key in land_species:
            count = species_counts.get(key, 0)
            if count > 0:
                text = f"{emoji_name}: {count}"
                surf = self.font_small.render(text, True, self.ui_colors["text_dim"])
                self.screen.blit(surf, (panel_x + 15, y))
                y += 15
                
        y += 5
        
        # 水生生物统计
        water_title = self.font_normal.render("🌊 水生生物", True, self.ui_colors["text"])
        self.screen.blit(water_title, (panel_x + 10, y))
        y += 20
        
        water_species = [
            ("🟢 藻类", "algae"), ("🌿 水草", "seaweed"), ("🔬 浮游", "plankton"),
            ("🐟 小鱼", "small_fish"), ("🐠 米诺鱼", "minnow"), ("🦐 虾", "shrimp"), ("🦀 螃蟹", "crab"),
        ]
        
        for emoji_name, key in water_species:
            count = species_counts.get(key, 0)
            if count > 0:
                text = f"{emoji_name}: {count}"
                surf = self.font_small.render(text, True, self.ui_colors["text_dim"])
                self.screen.blit(surf, (panel_x + 15, y))
                y += 15
                
        # 警告信息
        alerts = stats.get("alerts", [])
        if alerts and y < self.map_height - 80:
            pygame.draw.line(self.screen, self.ui_colors["panel_border"],
                (panel_x + 10, y), (panel_x + self.panel_width - 10, y))
            y += 10
            
            alert_title = self.font_normal.render("⚠️ 警告", True, self.ui_colors["health_critical"])
            self.screen.blit(alert_title, (panel_x + 10, y))
            y += 20
            
            for alert in alerts[:3]:
                alert_text = alert[:30] if len(alert) > 30 else alert
                surf = self.font_small.render(alert_text, True, self.ui_colors["health_warning"])
                self.screen.blit(surf, (panel_x + 15, y))
                y += 15
                
    def _render_bottom_bar(self):
        """渲染底部信息栏"""
        bar_y = self.map_height
        bar_rect = pygame.Rect(0, bar_y, self.window_width, self.bottom_height)
        
        pygame.draw.rect(self.screen, self.ui_colors["panel_bg"], bar_rect)
        pygame.draw.line(self.screen, self.ui_colors["panel_border"],
            (0, bar_y), (self.window_width, bar_y), 2)
            
        stats = self.ecosystem.get_statistics()
        
        # 左侧：状态
        status_text = "⏸ 已暂停" if self.paused else f"▶ 运行中: {self.speed}倍速"
        status_color = self.ui_colors["health_warning"] if self.paused else self.ui_colors["health_good"]
        status_surf = self.font_large.render(status_text, True, status_color)
        self.screen.blit(status_surf, (10, bar_y + 10))
        
        tick_text = f"时钟: {stats['tick']}"
        tick_surf = self.font_normal.render(tick_text, True, self.ui_colors["text_dim"])
        self.screen.blit(tick_surf, (10, bar_y + 35))
        
        # 中间：种群数量条形图
        chart_x = 150
        chart_width = self.window_width - 450
        self._draw_population_chart(chart_x, bar_y + 10, chart_width, 60, stats)
        
        # 右侧：控制提示
        controls = [
            "空格: 暂停/继续",
            "+/-: 调整速度",
            "G/R/F/I: 添加陆地生物",
            "A/S: 添加水生生物",
            "Q: 退出"
        ]
        
        for i, ctrl in enumerate(controls):
            surf = self.font_small.render(ctrl, True, self.ui_colors["text_dim"])
            self.screen.blit(surf, (self.window_width - 140, bar_y + 10 + i * 15))
            
    def _draw_population_chart(self, x, y, width, height, stats):
        """绘制种群数量条形图"""
        species_counts = stats.get("species", {})
        
        # 主要物种
        main_species = [
            ("grass", "🌿", (50, 205, 50)),
            ("rabbit", "🐰", (245, 245, 220)),
            ("fox", "🦊", (255, 140, 0)),
            ("algae", "🟢", (0, 128, 0)),
            ("small_fish", "🐟", (255, 215, 0)),
            ("minnow", "🐠", (135, 206, 235)),
        ]
        
        max_count = max((species_counts.get(s[0], 1) for s in main_species), default=1)
        max_count = max(max_count, 10)
        
        bar_width = (width - 20) // len(main_species)
        
        for i, (species, emoji, color) in enumerate(main_species):
            count = species_counts.get(species, 0)
            bar_height = int((count / max_count) * (height - 20))
            
            bx = x + i * bar_width + 5
            
            # 条形
            pygame.draw.rect(self.screen, color, 
                (bx, y + height - bar_height - 15, bar_width - 10, bar_height))
                
            # 数量
            count_surf = self.font_small.render(str(count), True, self.ui_colors["text"])
            self.screen.blit(count_surf, (bx + 2, y + height - bar_height - 28))
            
    def _render_notifications(self):
        """渲染通知消息"""
        y = 10
        for msg, tick in self.notifications[-3:]:
            alpha = max(0, 255 - (self.tick - tick) * 2)
            if alpha > 0:
                surf = self.font_normal.render(msg, True, (255, 255, 255))
                # 背景
                bg_rect = pygame.Rect(10, y, surf.get_width() + 20, 25)
                pygame.draw.rect(self.screen, (50, 50, 70), bg_rect, border_radius=5)
                self.screen.blit(surf, (20, y + 5))
                y += 30
                
    def _get_health_color(self, health: float) -> Tuple[int, int, int]:
        """根据健康度返回颜色"""
        if health >= 70:
            return self.ui_colors["health_good"]
        elif health >= 50:
            return self.ui_colors["health_warning"]
        else:
            return self.ui_colors["health_critical"]

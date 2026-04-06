"""
高级游戏渲染器 - 专业级生态系统可视化
支持：缩放、平移、详细面板、天气效果、动画
"""

import pygame
import sys
import math
import random
from typing import Dict, Tuple, List, Optional
from collections import defaultdict

from ..core.ecosystem import Ecosystem


class AdvancedRenderer:
    """专业级渲染器 - 游戏化生态系统"""
    
    def __init__(self, ecosystem: Ecosystem, config: dict = None):
        pygame.init()
        
        self.ecosystem = ecosystem
        self.config = config or {}
        
        # === 窗口设置 ===
        self.base_grid_size = 20  # 基础格子大小
        self.world_width = ecosystem.width
        self.world_height = ecosystem.height
        
        # 窗口大小（可调整）
        self.window_width = 1400
        self.window_height = 900
        
        # UI布局
        self.sidebar_width = 320
        self.bottom_bar_height = 60
        self.minimap_size = 150
        
        # 创建窗口
        self.screen = pygame.display.set_mode((self.window_width, self.window_height), pygame.RESIZABLE)
        pygame.display.set_caption("🌍 EcoWorld - 虚拟生态系统模拟器")
        
        # === 摄像头系统 ===
        self.zoom = 1.0
        self.min_zoom = 0.5
        self.max_zoom = 3.0
        self.camera_x = 0
        self.camera_y = 0
        self.dragging = False
        self.drag_start = (0, 0)
        self.camera_start = (0, 0)
        
        # === 视觉效果 ===
        self.animation_tick = 0
        self.weather_particles = []
        self.selected_creature = None
        
        # === 游戏状态 ===
        self.tick = 0
        self.paused = False
        self.speed = 1
        self.show_debug = False
        self.show_grid = True
        self.max_notifications = 5
        
        # === 颜色主题 ===
        self._init_colors()
        
        # === 字体 ===
        self._init_fonts()
        
        # === 生物精灵 ===
        self._init_sprites()
        
        # === UI组件 ===
        self.notifications = []
        self.active_tab = "species"  # species, foodchain, events, settings
        
        self._clamp_camera()
        
    def _init_colors(self):
        """初始化颜色主题"""
        # 地形颜色（更自然）
        self.terrain_colors = {
            "grass": (86, 176, 76),
            "forest": (45, 90, 39),
            "rock": (120, 120, 130),
            "water_shallow": (64, 164, 223),
            "water_deep": (25, 80, 150),
            "river": (30, 120, 200),
            "sand": (238, 214, 175),
            "mud": (139, 90, 43),
        }
        
        # 地形纹理颜色（用于细节）
        self.terrain_detail = {
            "grass": [(76, 166, 66), (96, 186, 86), (66, 146, 56)],
            "forest": [(35, 80, 29), (55, 100, 49), (40, 85, 34)],
            "water_shallow": [(54, 144, 203), (74, 174, 233), (44, 134, 183)],
        }
        
        # UI颜色
        self.ui = {
            "bg_dark": (20, 22, 28),
            "bg_medium": (30, 33, 42),
            "bg_light": (40, 44, 55),
            "border": (50, 55, 70),
            "text": (230, 235, 240),
            "text_dim": (140, 150, 165),
            "accent": (72, 165, 255),
            "success": (76, 175, 80),
            "warning": (255, 193, 7),
            "danger": (244, 67, 54),
            "highlight": (100, 149, 237),
        }
        
        # 生物颜色映射（完整版）
        self.creature_colors = {
            # 植物
            "grass": (76, 187, 23),
            "bush": (34, 139, 34),
            "flower": (255, 105, 180),
            "moss": (0, 128, 0),
            "tree": (45, 90, 39),
            "vine": (0, 128, 0),
            "cactus": (34, 139, 34),
            "berry": (123, 45, 180),
            "mushroom": (210, 105, 30),
            "fern": (34, 139, 34),
            # 果类
            "apple_tree": (255, 0, 0),
            "cherry_tree": (255, 182, 193),
            "grape_vine": (128, 0, 128),
            "strawberry": (255, 0, 0),
            "blueberry": (0, 0, 139),
            "orange_tree": (255, 165, 0),
            "watermelon": (0, 128, 0),
            # 杂食动物
            "bear": (101, 67, 33),
            "wild_boar": (128, 128, 128),
            "badger": (128, 128, 128),
            "raccoon_dog": (160, 120, 80),
            "skunk": (0, 0, 0),
            "opossum": (150, 150, 150),
            "coati": (205, 133, 63),
            "armadillo": (210, 180, 140),
            # 食草动物
            "rabbit": (245, 245, 220),
            "deer": (160, 82, 45),
            "squirrel": (165, 42, 42),
            "mouse": (150, 120, 90),
            "bee": (255, 200, 0),
            # 捕食者
            "wolf": (105, 105, 105),
            "fox": (255, 140, 0),
            "snake": (85, 107, 47),
            "spider": (60, 60, 60),
            "hedgehog": (128, 128, 128),
            # 鸟类
            "bird": (135, 206, 235),
            "eagle": (139, 69, 19),
            "owl": (102, 51, 0),
            "duck": (255, 215, 0),
            "swan": (255, 255, 255),
            "sparrow": (165, 42, 42),
            "parrot": (0, 255, 127),
            "kingfisher": (0, 191, 255),
            "magpie": (30, 30, 30),
            "crow": (20, 20, 20),
            "woodpecker": (139, 69, 19),
            "hummingbird": (0, 255, 127),
            # 其他
            "insect": (139, 69, 19),
            "bat": (60, 60, 60),
            "frog": (50, 205, 50),
            # 水生生物
            "algae": (0, 128, 0),
            "seaweed": (34, 139, 34),
            "plankton": (200, 200, 200),
            "small_fish": (255, 215, 0),
            "minnow": (135, 206, 235),
            "carp": (255, 140, 0),
            "catfish": (105, 105, 105),
            "large_fish": (0, 0, 139),
            "pufferfish": (255, 228, 181),
            "blackfish": (20, 20, 20),
            "pike": (85, 107, 47),
            "shrimp": (255, 160, 122),
            "crab": (139, 69, 19),
            "tadpole": (50, 50, 50),
            "water_strider": (100, 100, 100),
        }
        
        # 生物 Emoji
        self.creature_emoji = {
            "grass": "🌿", "bush": "🌳", "flower": "🌸", "moss": "🍀",
            "tree": "🌲", "vine": "🌿", "cactus": "🌵", "berry": "🫐",
            "mushroom": "🍄", "fern": "🌿",
            "apple_tree": "🍎", "cherry_tree": "🍒", "grape_vine": "🍇",
            "strawberry": "🍓", "blueberry": "🫐", "orange_tree": "🍊", "watermelon": "🍉",
            "bear": "🐻", "wild_boar": "🐗", "badger": "🦡", "raccoon_dog": "🐕",
            "skunk": "🦨", "opossum": "🐭", "coati": "🦝", "armadillo": "🦔",
            "rabbit": "🐰", "deer": "🦌", "squirrel": "🐿️", "mouse": "🐭", "bee": "🐝",
            "wolf": "🐺", "fox": "🦊", "snake": "🐍", "spider": "🕷️", "hedgehog": "🦔",
            "bird": "🐦", "eagle": "🦅", "owl": "🦉", "duck": "🦆", "swan": "🦢",
            "sparrow": "🐦", "parrot": "🦜", "kingfisher": "🐦", "magpie": "🐦‍⬛",
            "crow": "🐦‍⬛", "woodpecker": "🐦", "hummingbird": "🐦",
            "insect": "🐛", "bat": "🦇", "frog": "🐸",
            "algae": "🌿", "seaweed": "🌿", "plankton": "🔬",
            "small_fish": "🐟", "minnow": "🐠", "carp": "🐟", "catfish": "🐟", "large_fish": "🐠",
            "pufferfish": "🐡", "blackfish": "🐟", "pike": "🐟",
            "shrimp": "🦐", "crab": "🦀", "tadpole": "🐸", "water_strider": "🦗",
        }
        
    def _init_fonts(self):
        """初始化字体"""
        try:
            # 尝试加载系统中文字体
            self.font_small = pygame.font.SysFont("pingfang", 12)
            self.font_normal = pygame.font.SysFont("pingfang", 14)
            self.font_medium = pygame.font.SysFont("pingfang", 16)
            self.font_large = pygame.font.SysFont("pingfang", 20)
            self.font_title = pygame.font.SysFont("pingfang", 24, bold=True)
        except:
            try:
                self.font_small = pygame.font.SysFont("arial", 12)
                self.font_normal = pygame.font.SysFont("arial", 14)
                self.font_medium = pygame.font.SysFont("arial", 16)
                self.font_large = pygame.font.SysFont("arial", 20)
                self.font_title = pygame.font.SysFont("arial", 24, bold=True)
            except:
                self.font_small = pygame.font.Font(None, 14)
                self.font_normal = pygame.font.Font(None, 16)
                self.font_medium = pygame.font.Font(None, 20)
                self.font_large = pygame.font.Font(None, 24)
                self.font_title = pygame.font.Font(None, 28)
                
    def _init_sprites(self):
        """初始化生物精灵"""
        self.sprites = {}
        # 这里可以加载图片精灵，暂时用颜色绘制
        
    def run(self):
        """主游戏循环"""
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
                    self._handle_mouse_down(event.pos, event.button)
                elif event.type == pygame.MOUSEBUTTONUP:
                    self._handle_mouse_up(event.pos, event.button)
                elif event.type == pygame.MOUSEMOTION:
                    self._handle_mouse_motion(event.pos, event.buttons)
                elif event.type == pygame.MOUSEWHEEL:
                    self._handle_mouse_wheel(event.y)
                elif event.type == pygame.VIDEORESIZE:
                    self._handle_resize(event.w, event.h)
                    
            # 更新游戏状态
            if not self.paused:
                for _ in range(self.speed):
                    self.ecosystem.update()
            
            self.tick += 1
            self.animation_tick += 1
            
            # 更新天气粒子
            self._update_weather_particles()
            
            # 清理过期通知
            self.notifications = [(msg, t) for msg, t in self.notifications if self.tick - t < 180]
            
            # 渲染
            self._render()
            
            pygame.display.flip()
            clock.tick(60)
            
        pygame.quit()
        sys.exit()
        
    def _handle_key(self, key):
        """处理键盘输入"""
        if key == pygame.K_SPACE:
            self.paused = not self.paused
            self._notify("⏸ 已暂停" if self.paused else "▶ 继续运行")
        elif key == pygame.K_EQUALS or key == pygame.K_PLUS or key == pygame.K_KP_PLUS:
            self.speed = min(10, self.speed + 1)
            self._notify(f"⏱️ 速度: {self.speed}x")
        elif key == pygame.K_MINUS or key == pygame.K_KP_MINUS:
            self.speed = max(1, self.speed - 1)
            self._notify(f"⏱️ 速度: {self.speed}x")
        elif key == pygame.K_g:
            self.show_grid = not self.show_grid
        elif key == pygame.K_F1:
            self.active_tab = "species"
            self._notify("📊 物种统计")
        elif key == pygame.K_F2:
            self.active_tab = "foodchain"
            self._notify("🔗 食物链")
        elif key == pygame.K_F3:
            self.active_tab = "events"
            self._notify("📜 事件日志")
        elif key == pygame.K_F4:
            self.active_tab = "settings"
            self._notify("⚙️ 设置")
        elif key == pygame.K_HOME:
            # 重置摄像头
            self.camera_x = 0
            self.camera_y = 0
            self.zoom = 1.0
            self._clamp_camera()
            self._notify("🏠 重置视角")
        elif key == pygame.K_q or key == pygame.K_ESCAPE:
            pygame.quit()
            sys.exit()
            
        # 快捷添加生物
        elif key == pygame.K_1:
            self._spawn_random("grass", "🌿 草")
        elif key == pygame.K_2:
            self._spawn_random("rabbit", "🐰 兔子")
        elif key == pygame.K_3:
            self._spawn_random("fox", "🦊 狐狸")
        elif key == pygame.K_4:
            self._spawn_random("wolf", "🐺 狼")
        elif key == pygame.K_5:
            self._spawn_random("deer", "🦌 鹿")
        elif key == pygame.K_6:
            self._spawn_random("bear", "🐻 熊")
        elif key == pygame.K_7:
            self._spawn_random("apple_tree", "🍎 苹果树")
        elif key == pygame.K_8:
            self._spawn_random("carp", "🐟 鲤鱼")
        elif key == pygame.K_9:
            self._spawn_random("blackfish", "🐟 黑鱼")
            
    def _handle_mouse_down(self, pos, button):
        """处理鼠标按下"""
        if button == 1:  # 左键
            # 检查是否点击在游戏区域
            game_area_width = self.window_width - self.sidebar_width
            if pos[0] < game_area_width:
                # 选择生物
                world_pos = self._screen_to_world(pos)
                self._select_creature_at(world_pos)
            else:
                # 点击侧边栏
                self._handle_sidebar_click(pos)
        elif button == 3:  # 右键 - 拖拽
            self.dragging = True
            self.drag_start = pos
            self.camera_start = (self.camera_x, self.camera_y)
            
    def _handle_mouse_up(self, pos, button):
        """处理鼠标释放"""
        if button == 3:
            self.dragging = False
            
    def _handle_mouse_motion(self, pos, buttons):
        """处理鼠标移动"""
        if self.dragging and buttons[2]:  # 右键拖拽
            dx = pos[0] - self.drag_start[0]
            dy = pos[1] - self.drag_start[1]
            self.camera_x = self.camera_start[0] - dx / self.zoom
            self.camera_y = self.camera_start[1] - dy / self.zoom
            self._clamp_camera()
            
    def _handle_mouse_wheel(self, direction):
        """处理鼠标滚轮 - 缩放"""
        old_zoom = self.zoom
        self.zoom = max(self.min_zoom, min(self.max_zoom, self.zoom + direction * 0.1))
        
        if old_zoom != self.zoom:
            self._clamp_camera()
            self._notify(f"🔍 缩放: {self.zoom:.1f}x")

    def _handle_resize(self, width, height):
        """处理窗口尺寸变化。"""
        self.window_width = max(960, width)
        self.window_height = max(640, height)
        self.sidebar_width = min(360, max(260, self.window_width // 4))
        self.minimap_size = min(180, max(110, self.window_height // 6))
        self.screen = pygame.display.set_mode((self.window_width, self.window_height), pygame.RESIZABLE)
        self._clamp_camera()
        self._notify(f"🪟 窗口: {self.window_width}x{self.window_height}")
            
    def _screen_to_world(self, screen_pos) -> Tuple[int, int]:
        """屏幕坐标转世界坐标"""
        grid_size = max(1, int(self.base_grid_size * self.zoom))
        
        x = int((screen_pos[0] + self.camera_x * grid_size) / grid_size)
        y = int((screen_pos[1] + self.camera_y * grid_size) / grid_size)
        
        return (max(0, min(x, self.world_width - 1)), max(0, min(y, self.world_height - 1)))
        
    def _world_to_screen(self, world_pos) -> Tuple[int, int]:
        """世界坐标转屏幕坐标"""
        grid_size = max(1, int(self.base_grid_size * self.zoom))
        x = int(world_pos[0] * grid_size - self.camera_x * grid_size)
        y = int(world_pos[1] * grid_size - self.camera_y * grid_size)
        return (x, y)

    def _get_game_area_size(self) -> Tuple[int, int]:
        return (
            max(200, self.window_width - self.sidebar_width),
            max(200, self.window_height - self.bottom_bar_height),
        )

    def _get_viewport_world_size(self) -> Tuple[float, float]:
        grid_size = max(1, int(self.base_grid_size * self.zoom))
        game_width, game_height = self._get_game_area_size()
        return (game_width / grid_size, game_height / grid_size)

    def _clamp_camera(self):
        """限制相机不要拖出世界边界。"""
        view_w, view_h = self._get_viewport_world_size()
        max_x = max(0.0, self.world_width - view_w)
        max_y = max(0.0, self.world_height - view_h)
        self.camera_x = min(max(self.camera_x, 0.0), max_x)
        self.camera_y = min(max(self.camera_y, 0.0), max_y)
        
    def _select_creature_at(self, world_pos):
        """选择指定位置的生物"""
        x, y = world_pos
        
        # 检查动物
        for animal in self.ecosystem.animals:
            if animal.position == (x, y) and animal.alive:
                self.selected_creature = animal
                self._notify(f"选中: {self.creature_emoji.get(animal.species, '?')} {animal.species}")
                return
                
        # 检查植物
        for plant in self.ecosystem.plants:
            if plant.position == (x, y) and plant.alive:
                self.selected_creature = plant
                self._notify(f"选中: {self.creature_emoji.get(plant.species, '?')} {plant.species}")
                return
                
        # 检查水生生物
        for aquatic in self.ecosystem.aquatic_creatures:
            if aquatic.position == (x, y) and aquatic.alive:
                self.selected_creature = aquatic
                self._notify(f"选中: {self.creature_emoji.get(aquatic.species, '?')} {aquatic.species}")
                return
                
        self.selected_creature = None
        
    def _handle_sidebar_click(self, pos):
        """处理侧边栏点击"""
        # 检查标签页点击
        sidebar_x = self.window_width - self.sidebar_width
        rel_x = pos[0] - sidebar_x
        rel_y = pos[1]
        
        # 标签页按钮高度
        tab_y = 60
        tab_height = 35
        tabs = ["species", "foodchain", "events", "settings"]
        
        for i, tab in enumerate(tabs):
            tab_start = tab_y + i * tab_height
            if tab_start <= rel_y < tab_start + tab_height:
                self.active_tab = tab
                self._notify(f"切换到: {tab}")
                return
                
    def _spawn_random(self, species, name):
        """随机生成生物"""
        if species in ["algae", "seaweed", "plankton", "small_fish", "minnow", "carp", "catfish",
                       "large_fish", "pufferfish", "blackfish", "pike", "shrimp", "crab",
                       "tadpole", "water_strider"]:
            # 水生生物
            for _ in range(10):
                x = random.randint(0, self.world_width - 1)
                y = random.randint(0, self.world_height - 1)
                if self.ecosystem.environment.is_water(x, y):
                    self.ecosystem.spawn_aquatic(species, (x, y), source="manual")
                    self._notify(f"添加了 {name}")
                    return
        elif species in ["apple_tree", "cherry_tree", "grape_vine", "strawberry",
                        "blueberry", "orange_tree", "watermelon"]:
            # 植物
            for _ in range(10):
                x = random.randint(0, self.world_width - 1)
                y = random.randint(0, self.world_height - 1)
                if self.ecosystem.environment.is_land(x, y):
                    self.ecosystem.spawn_plant(species, (x, y), source="manual")
                    self._notify(f"添加了 {name}")
                    return
        else:
            # 动物
            for _ in range(10):
                x = random.randint(0, self.world_width - 1)
                y = random.randint(0, self.world_height - 1)
                if self.ecosystem.environment.is_land(x, y):
                    self.ecosystem.spawn_animal(species, (x, y), source="manual")
                    self._notify(f"添加了 {name}")
                    return
                    
    def _notify(self, message: str):
        """添加通知"""
        self.notifications.append((message, self.tick))
        
    def _update_weather_particles(self):
        """更新天气粒子效果"""
        weather = getattr(self.ecosystem.environment, 'weather', 'sunny')
        
        # 添加新粒子
        if weather in {'rainy', 'stormy'} and random.random() < (0.5 if weather == 'stormy' else 0.3):
            self.weather_particles.append({
                'x': random.randint(0, max(1, self.window_width - self.sidebar_width)),
                'y': 0,
                'speed': random.randint(7, 13) if weather == 'stormy' else random.randint(5, 10),
                'type': 'rain'
            })
        elif weather == 'snowy' and random.random() < 0.2:
            self.weather_particles.append({
                'x': random.randint(0, max(1, self.window_width - self.sidebar_width)),
                'y': 0,
                'speed': random.randint(1, 3),
                'type': 'snow',
                'drift': random.uniform(-1, 1)
            })
            
        # 更新粒子位置
        new_particles = []
        for p in self.weather_particles:
            p['y'] += p['speed']
            if p['type'] == 'snow':
                p['x'] += p.get('drift', 0)
            if p['y'] < self.window_height:
                new_particles.append(p)
                
        self.weather_particles = new_particles
        
    def _render(self):
        """主渲染函数"""
        # 清屏
        self.screen.fill(self.ui["bg_dark"])
        
        # 渲染游戏区域
        self._render_game_area()
        
        # 渲染侧边栏
        self._render_sidebar()
        
        # 渲染底部状态栏
        self._render_bottom_bar()
        
        # 渲染天气效果
        self._render_weather_effects()
        
        # 渲染通知
        self._render_notifications()
        
    def _render_game_area(self):
        """渲染游戏主区域"""
        game_area_width, game_area_height = self._get_game_area_size()
        
        # 创建游戏表面
        game_surface = pygame.Surface((game_area_width, game_area_height))
        game_surface.fill((40, 44, 52))
        
        # 计算可见范围
        grid_size = max(1, int(self.base_grid_size * self.zoom))
        self._clamp_camera()
        
        start_x = max(0, int(self.camera_x))
        start_y = max(0, int(self.camera_y))
        end_x = min(self.world_width, start_x + game_area_width // grid_size + 2)
        end_y = min(self.world_height, start_y + game_area_height // grid_size + 2)
        
        # 渲染地形
        self._render_terrain(game_surface, start_x, start_y, end_x, end_y, grid_size)
        
        # 渲染植物
        self._render_plants(game_surface, grid_size)
        
        # 渲染动物
        self._render_animals(game_surface, grid_size)
        
        # 渲染水生生物
        self._render_aquatic(game_surface, grid_size)
        
        # 渲染网格（可选）
        if self.show_grid and self.zoom >= 0.8:
            self._render_grid(game_surface, grid_size)
            
        # 渲染选中高亮
        if self.selected_creature:
            self._render_selection(game_surface, grid_size)
            
        # 添加渐变边框
        self._add_border_gradient(game_surface, (60, 65, 80), 3)
        
        # 绘制到主屏幕
        self.screen.blit(game_surface, (0, 0))
        
    def _render_terrain(self, surface, start_x, start_y, end_x, end_y, grid_size):
        """渲染地形"""
        for x in range(start_x, end_x):
            for y in range(start_y, end_y):
                terrain = self.ecosystem.environment.get_terrain(x, y)
                color = self.terrain_colors.get(terrain, (100, 100, 100))
                
                # 添加细节变化
                detail_colors = self.terrain_detail.get(terrain)
                if detail_colors:
                    # 根据位置添加变化
                    variation = (x * 7 + y * 13) % len(detail_colors)
                    color = detail_colors[variation]
                    
                screen_x = int((x - self.camera_x) * grid_size)
                screen_y = int((y - self.camera_y) * grid_size)
                
                # 绘制地形格子
                pygame.draw.rect(surface, color, 
                               (screen_x, screen_y, grid_size, grid_size))
                
                # 水波纹效果
                if terrain in ["water_shallow", "water_deep", "river"]:
                    wave_offset = math.sin(self.animation_tick * 0.05 + x * 0.5 + y * 0.3) * 2
                    wave_color = tuple(max(0, min(255, c + int(wave_offset))) for c in color)
                    pygame.draw.rect(surface, wave_color,
                                   (screen_x, screen_y, grid_size, grid_size))
                    
    def _render_plants(self, surface, grid_size):
        """渲染植物"""
        surface_width, surface_height = surface.get_size()
        for plant in self.ecosystem.plants:
            if not plant.alive:
                continue
                
            screen_x = int((plant.position[0] - self.camera_x) * grid_size)
            screen_y = int((plant.position[1] - self.camera_y) * grid_size)
            
            # 检查是否在屏幕内
            if screen_x < -grid_size or screen_x > surface_width:
                continue
            if screen_y < -grid_size or screen_y > surface_height:
                continue
                
            color = self.creature_colors.get(plant.species, (0, 255, 0))
            
            # 根据大小调整绘制
            size_factor = min(1.5, plant.size / 2) if hasattr(plant, 'size') else 1
            draw_size = int(grid_size * 0.6 * size_factor)
            
            # 绘制植物
            if plant.species in ["tree", "apple_tree", "cherry_tree", "orange_tree"]:
                # 大树
                self._draw_tree(surface, screen_x, screen_y, grid_size, color, plant)
            elif plant.species in ["bush", "berry", "blueberry"]:
                # 灌木
                self._draw_bush(surface, screen_x, screen_y, draw_size, color, plant)
            elif plant.species == "flower":
                # 花
                self._draw_flower(surface, screen_x, screen_y, draw_size, plant)
            elif plant.species == "cactus":
                # 仙人掌
                self._draw_cactus(surface, screen_x, screen_y, draw_size, color)
            elif plant.species == "mushroom":
                # 蘑菇
                self._draw_mushroom(surface, screen_x, screen_y, draw_size, color)
            else:
                # 默认植物
                pygame.draw.circle(surface, color, 
                                 (screen_x + grid_size // 2, screen_y + grid_size // 2),
                                 draw_size // 2)
                                 
    def _draw_tree(self, surface, x, y, grid_size, color, plant):
        """绘制大树"""
        # 树干
        trunk_color = (101, 67, 33)
        trunk_width = grid_size // 4
        trunk_height = grid_size // 2
        pygame.draw.rect(surface, trunk_color, 
                        (x + grid_size // 2 - trunk_width // 2, y + grid_size // 2,
                         trunk_width, trunk_height))
        
        # 树冠
        crown_radius = int(grid_size * 0.4 * (plant.size / 2 if hasattr(plant, 'size') else 1))
        pygame.draw.circle(surface, color,
                         (x + grid_size // 2, y + grid_size // 2),
                         crown_radius)
        
        # 果实
        if hasattr(plant, 'has_fruit') and plant.has_fruit:
            fruit_color = self.creature_colors.get(plant.species, (255, 0, 0))
            for _ in range(min(3, plant.fruit_count if hasattr(plant, 'fruit_count') else 3)):
                fx = x + grid_size // 2 + random.randint(-crown_radius // 2, crown_radius // 2)
                fy = y + grid_size // 2 + random.randint(-crown_radius // 2, crown_radius // 2)
                pygame.draw.circle(surface, fruit_color, (fx, fy), 3)
                
    def _draw_bush(self, surface, x, y, size, color, plant):
        """绘制灌木"""
        # 多个圆形组成灌木
        pygame.draw.circle(surface, color, (x + size // 2, y + size // 2), size // 2)
        pygame.draw.circle(surface, tuple(min(255, c + 20) for c in color), 
                         (x + size // 3, y + size // 3), size // 3)
        pygame.draw.circle(surface, tuple(max(0, c - 20) for c in color),
                         (x + size * 2 // 3, y + size * 2 // 3), size // 3)
        
        # 浆果
        if hasattr(plant, 'has_fruit') and plant.has_fruit:
            berry_color = (100, 50, 150)
            for _ in range(3):
                bx = x + random.randint(2, size - 2)
                by = y + random.randint(2, size - 2)
                pygame.draw.circle(surface, berry_color, (bx, by), 2)
                
    def _draw_flower(self, surface, x, y, size, plant):
        """绘制花"""
        colors = [(255, 182, 193), (255, 105, 180), (255, 20, 147), (255, 255, 0)]
        color = colors[(plant.position[0] + plant.position[1]) % len(colors)]
        
        # 花瓣
        center_x, center_y = x + size // 2, y + size // 2
        petal_size = size // 3
        for angle in range(0, 360, 60):
            rad = math.radians(angle + self.animation_tick)
            px = center_x + int(math.cos(rad) * petal_size)
            py = center_y + int(math.sin(rad) * petal_size)
            pygame.draw.circle(surface, color, (px, py), petal_size // 2)
            
        # 花心
        pygame.draw.circle(surface, (255, 255, 0), (center_x, center_y), petal_size // 3)
        
    def _draw_cactus(self, surface, x, y, size, color):
        """绘制仙人掌"""
        # 主干
        pygame.draw.rect(surface, color, 
                        (x + size // 3, y, size // 3, size))
        # 左枝
        pygame.draw.rect(surface, color,
                        (x, y + size // 3, size // 3, size // 4))
        pygame.draw.rect(surface, color,
                        (x, y + size // 3, size // 4, size // 2))
        # 右枝
        pygame.draw.rect(surface, color,
                        (x + size * 2 // 3, y + size // 2, size // 3, size // 4))
        pygame.draw.rect(surface, color,
                        (x + size * 3 // 4, y + size // 2, size // 4, size // 2))
                        
    def _draw_mushroom(self, surface, x, y, size, color):
        """绘制蘑菇"""
        # 伞盖
        pygame.draw.ellipse(surface, color,
                          (x, y, size, size // 2))
        # 柄
        pygame.draw.rect(surface, (255, 255, 255),
                        (x + size // 3, y + size // 3, size // 3, size // 2))
                        
    def _render_animals(self, surface, grid_size):
        """渲染动物"""
        surface_width, surface_height = surface.get_size()
        for animal in self.ecosystem.animals:
            if not animal.alive:
                continue
                
            screen_x = int((animal.position[0] - self.camera_x) * grid_size)
            screen_y = int((animal.position[1] - self.camera_y) * grid_size)
            
            if screen_x < -grid_size or screen_x > surface_width:
                continue
            if screen_y < -grid_size or screen_y > surface_height:
                continue
                
            color = self.creature_colors.get(animal.species, (255, 0, 0))
            
            # 根据物种类型绘制
            if animal.species in ["bird", "sparrow", "parrot", "magpie", "crow", "woodpecker", "hummingbird"]:
                self._draw_bird(surface, screen_x, screen_y, grid_size, color, animal)
            elif animal.species in ["eagle", "owl"]:
                self._draw_raptor(surface, screen_x, screen_y, grid_size, color, animal)
            elif animal.species in ["duck", "swan"]:
                self._draw_water_bird(surface, screen_x, screen_y, grid_size, color, animal)
            elif animal.species == "bee":
                self._draw_bee(surface, screen_x, screen_y, grid_size, color)
            elif animal.species == "butterfly":
                self._draw_butterfly(surface, screen_x, screen_y, grid_size, color)
            elif animal.species == "spider":
                self._draw_spider(surface, screen_x, screen_y, grid_size, color)
            elif animal.species == "snake":
                self._draw_snake(surface, screen_x, screen_y, grid_size, color, animal)
            elif animal.species in ["bear", "wolf", "fox", "deer", "rabbit"]:
                self._draw_mammal(surface, screen_x, screen_y, grid_size, color, animal)
            else:
                # 默认圆形
                size = int(grid_size * 0.4)
                pygame.draw.circle(surface, color,
                                 (screen_x + grid_size // 2, screen_y + grid_size // 2), size)
                                 
    def _draw_bird(self, surface, x, y, grid_size, color, animal):
        """绘制小鸟"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 3
        
        # 身体
        pygame.draw.ellipse(surface, color, (center_x - size, center_y - size // 2, size * 2, size))
        
        # 翅膀动画
        wing_angle = math.sin(self.animation_tick * 0.2 + animal.position[0]) * 0.3
        wing_y = center_y + int(wing_angle * size)
        pygame.draw.ellipse(surface, tuple(min(255, c + 30) for c in color),
                          (center_x - size, wing_y - size // 3, size // 2, size // 2))
        
        # 头
        pygame.draw.circle(surface, color, (center_x + size // 2, center_y - size // 4), size // 3)
        
        # 喙
        beak_color = (255, 165, 0)
        pygame.draw.polygon(surface, beak_color,
                          [(center_x + size, center_y), 
                           (center_x + size + size // 3, center_y),
                           (center_x + size, center_y + size // 4)])
                           
    def _draw_raptor(self, surface, x, y, grid_size, color, animal):
        """绘制猛禽"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 2
        
        # 翅膀展开
        wing_span = size * 2
        pygame.draw.ellipse(surface, color,
                          (center_x - wing_span, center_y - size // 4, wing_span, size // 2))
        
        # 身体
        pygame.draw.ellipse(surface, color,
                          (center_x - size // 2, center_y - size // 2, size, size))
        
        # 头
        pygame.draw.circle(surface, color, (center_x, center_y - size // 2), size // 3)
        
    def _draw_water_bird(self, surface, x, y, grid_size, color, animal):
        """绘制水鸟"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 3
        
        # 身体
        pygame.draw.ellipse(surface, color,
                          (center_x - size, center_y - size // 2, size * 2, size))
        
        # 脖子（天鹅长脖子）
        neck_length = size if animal.species == "swan" else size // 2
        pygame.draw.line(surface, color, 
                        (center_x - size // 2, center_y - size // 2),
                        (center_x - size // 2, center_y - size // 2 - neck_length), 2)
        
        # 头
        pygame.draw.circle(surface, color,
                         (center_x - size // 2, center_y - size // 2 - neck_length), size // 3)
                         
    def _draw_bee(self, surface, x, y, grid_size, color):
        """绘制蜜蜂"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 4
        
        # 身体（黄黑条纹）
        pygame.draw.ellipse(surface, (255, 200, 0), (center_x - size, center_y - size // 2, size * 2, size))
        pygame.draw.line(surface, (0, 0, 0), (center_x - size // 3, center_y - size // 2),
                        (center_x - size // 3, center_y + size // 2), 2)
        pygame.draw.line(surface, (0, 0, 0), (center_x + size // 3, center_y - size // 2),
                        (center_x + size // 3, center_y + size // 2), 2)
        
        # 翅膀
        wing_y = center_y - size // 2 + int(math.sin(self.animation_tick * 0.5) * 2)
        pygame.draw.ellipse(surface, (200, 200, 255, 100),
                          (center_x - size, wing_y - size, size, size // 2))
                          
    def _draw_butterfly(self, surface, x, y, grid_size, color):
        """绘制蝴蝶"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 3
        
        # 翅膀动画
        wing_angle = math.sin(self.animation_tick * 0.3) * 0.5
        wing_size = int(size * (1 + wing_angle))
        
        # 左翅
        pygame.draw.ellipse(surface, color,
                          (center_x - wing_size, center_y - size // 2, size, size))
        # 右翅
        pygame.draw.ellipse(surface, color,
                          (center_x, center_y - size // 2, size, size))
        # 身体
        pygame.draw.line(surface, (50, 50, 50),
                        (center_x, center_y - size), (center_x, center_y + size), 2)
                        
    def _draw_spider(self, surface, x, y, grid_size, color):
        """绘制蜘蛛"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 4
        
        # 身体
        pygame.draw.circle(surface, color, (center_x, center_y), size)
        pygame.draw.circle(surface, tuple(min(255, c + 30) for c in color),
                         (center_x, center_y - size // 2), size // 2)
        
        # 腿
        for angle in [30, 60, 120, 150]:
            rad = math.radians(angle)
            leg_x = center_x + int(math.cos(rad) * size * 1.5)
            leg_y = center_y + int(math.sin(rad) * size * 1.5)
            pygame.draw.line(surface, color, (center_x, center_y), (leg_x, leg_y), 1)
            pygame.draw.line(surface, color, (center_x, center_y),
                           (center_x - int(math.cos(rad) * size * 1.5),
                            center_y + int(math.sin(rad) * size * 1.5)), 1)
                            
    def _draw_snake(self, surface, x, y, grid_size, color, animal):
        """绘制蛇"""
        size = grid_size // 3
        
        # 身体曲线
        points = []
        for i in range(5):
            offset_x = i * size // 2
            offset_y = int(math.sin(self.animation_tick * 0.1 + i) * size // 2)
            points.append((x + offset_x, y + grid_size // 2 + offset_y))
            
        if len(points) >= 2:
            pygame.draw.lines(surface, color, False, points, 3)
            
        # 头
        if points:
            pygame.draw.circle(surface, color, points[-1], size // 2)
            
    def _draw_mammal(self, surface, x, y, grid_size, color, animal):
        """绘制哺乳动物"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        
        # 根据体型调整大小
        size_factors = {
            "bear": 1.2,
            "wolf": 1.0,
            "fox": 0.8,
            "deer": 1.0,
            "rabbit": 0.6,
        }
        factor = size_factors.get(animal.species, 0.8)
        size = int(grid_size * 0.4 * factor)
        
        # 身体
        pygame.draw.ellipse(surface, color,
                          (center_x - size, center_y - size // 2, size * 2, size))
        
        # 头
        head_x = center_x + size // 2
        pygame.draw.circle(surface, color, (head_x, center_y - size // 4), size // 2)
        
        # 耳朵（兔子）
        if animal.species == "rabbit":
            ear_size = size // 2
            pygame.draw.ellipse(surface, color,
                              (head_x - ear_size // 2, center_y - size - ear_size, ear_size, ear_size * 2))
            pygame.draw.ellipse(surface, color,
                              (head_x + ear_size // 2, center_y - size - ear_size, ear_size, ear_size * 2))
                              
    def _render_aquatic(self, surface, grid_size):
        """渲染水生生物"""
        surface_width, surface_height = surface.get_size()
        for aquatic in self.ecosystem.aquatic_creatures:
            if not aquatic.alive:
                continue
                
            screen_x = int((aquatic.position[0] - self.camera_x) * grid_size)
            screen_y = int((aquatic.position[1] - self.camera_y) * grid_size)
            
            if screen_x < -grid_size or screen_x > surface_width:
                continue
            if screen_y < -grid_size or screen_y > surface_height:
                continue
                
            color = self.creature_colors.get(aquatic.species, (0, 100, 200))
            center_x, center_y = screen_x + grid_size // 2, screen_y + grid_size // 2
            
            if aquatic.species in ["algae", "seaweed"]:
                # 水草
                pygame.draw.ellipse(surface, color,
                                  (center_x - grid_size // 4, center_y - grid_size // 3,
                                   grid_size // 2, grid_size // 1.5))
            elif aquatic.species == "plankton":
                # 浮游生物
                pygame.draw.circle(surface, color, (center_x, center_y), 2)
            elif aquatic.species in ["small_fish", "minnow", "carp", "catfish", "large_fish", "blackfish", "pike"]:
                # 鱼
                self._draw_fish(surface, center_x, center_y, grid_size, color, aquatic)
            elif aquatic.species == "pufferfish":
                # 河豚
                size = grid_size // 3
                pygame.draw.circle(surface, color, (center_x, center_y), size)
                # 斑点
                pygame.draw.circle(surface, (50, 50, 50), (center_x - size // 3, center_y), 1)
                pygame.draw.circle(surface, (50, 50, 50), (center_x + size // 3, center_y), 1)
            elif aquatic.species == "shrimp":
                # 虾
                self._draw_shrimp(surface, center_x, center_y, grid_size, color)
            elif aquatic.species == "crab":
                # 螃蟹
                self._draw_crab(surface, center_x, center_y, grid_size, color)
            elif aquatic.species == "tadpole":
                # 蝌蚪
                pygame.draw.circle(surface, color, (center_x, center_y), grid_size // 5)
                pygame.draw.line(surface, color, (center_x, center_y),
                               (center_x + grid_size // 4, center_y), 2)
            else:
                pygame.draw.circle(surface, color, (center_x, center_y), grid_size // 4)
                
    def _draw_fish(self, surface, x, y, grid_size, color, aquatic):
        """绘制鱼"""
        size = grid_size // 3
        
        # 身体
        pygame.draw.ellipse(surface, color, (x - size, y - size // 2, size * 2, size))
        
        # 尾巴
        tail_points = [(x - size, y), (x - size - size // 2, y - size // 2), (x - size - size // 2, y + size // 2)]
        pygame.draw.polygon(surface, color, tail_points)
        
        # 眼睛
        pygame.draw.circle(surface, (255, 255, 255), (x + size // 2, y - size // 4), size // 4)
        pygame.draw.circle(surface, (0, 0, 0), (x + size // 2, y - size // 4), size // 6)
        
        # 游动动画
        if hasattr(aquatic, 'direction'):
            # 翻转方向
            pass
            
    def _draw_shrimp(self, surface, x, y, grid_size, color):
        """绘制虾"""
        size = grid_size // 4
        
        # 身体（多节）
        for i in range(4):
            segment_x = x - i * size // 2
            segment_y = y + int(math.sin(self.animation_tick * 0.1 + i) * 2)
            pygame.draw.circle(surface, color, (segment_x, segment_y), size // 2)
            
        # 须
        pygame.draw.line(surface, color, (x + size, y - size // 2), (x + size * 2, y - size), 1)
        pygame.draw.line(surface, color, (x + size, y + size // 2), (x + size * 2, y + size), 1)
        
    def _draw_crab(self, surface, x, y, grid_size, color):
        """绘制螃蟹"""
        size = grid_size // 3
        
        # 身体
        pygame.draw.ellipse(surface, color, (x - size, y - size // 2, size * 2, size))
        
        # 螯
        pygame.draw.circle(surface, color, (x - size - size // 2, y - size // 2), size // 2)
        pygame.draw.circle(surface, color, (x + size + size // 2, y - size // 2), size // 2)
        
        # 腿
        for i in range(-2, 3):
            if i != 0:
                pygame.draw.line(surface, color, (x, y + size // 2),
                               (x + i * size // 2, y + size), 2)
                               
    def _render_grid(self, surface, grid_size):
        """渲染网格"""
        grid_color = (50, 55, 65)
        surface_width, surface_height = surface.get_size()
        
        for x in range(0, surface_width, grid_size):
            pygame.draw.line(surface, grid_color, (x, 0), (x, surface_height))
            
        for y in range(0, surface_height, grid_size):
            pygame.draw.line(surface, grid_color, (0, y), (surface_width, y))
            
    def _render_selection(self, surface, grid_size):
        """渲染选中高亮"""
        if not self.selected_creature:
            return
            
        screen_x = int((self.selected_creature.position[0] - self.camera_x) * grid_size)
        screen_y = int((self.selected_creature.position[1] - self.camera_y) * grid_size)
        
        # 选中框
        pygame.draw.rect(surface, (255, 255, 0),
                        (screen_x - 2, screen_y - 2, grid_size + 4, grid_size + 4), 2)
        
        # 闪烁效果
        if self.animation_tick % 30 < 15:
            pygame.draw.rect(surface, (255, 255, 0),
                            (screen_x - 4, screen_y - 4, grid_size + 8, grid_size + 8), 1)
                            
    def _add_border_gradient(self, surface, color, width):
        """添加边框渐变"""
        for i in range(width):
            alpha = 255 - i * (255 // width)
            border_color = tuple(min(255, c + (255 - alpha) // 3) for c in color)
            pygame.draw.rect(surface, border_color, 
                           (i, i, surface.get_width() - i * 2, surface.get_height() - i * 2), 1)
                           
    def _render_sidebar(self):
        """渲染侧边栏"""
        sidebar_x = self.window_width - self.sidebar_width
        sidebar_rect = pygame.Rect(sidebar_x, 0, self.sidebar_width, self.window_height - self.bottom_bar_height)
        
        # 背景
        pygame.draw.rect(self.screen, self.ui["bg_medium"], sidebar_rect)
        pygame.draw.line(self.screen, self.ui["border"], 
                        (sidebar_x, 0), (sidebar_x, self.window_height), 2)
        
        # 标题
        title_surf = self.font_title.render("🌍 EcoWorld", True, self.ui["text"])
        self.screen.blit(title_surf, (sidebar_x + 15, 15))
        
        # 标签页
        self._render_tabs(sidebar_x)
        
        # 内容区域
        if self.active_tab == "species":
            self._render_species_panel(sidebar_x)
        elif self.active_tab == "foodchain":
            self._render_foodchain_panel(sidebar_x)
        elif self.active_tab == "events":
            self._render_events_panel(sidebar_x)
        elif self.active_tab == "settings":
            self._render_settings_panel(sidebar_x)
            
    def _render_tabs(self, sidebar_x):
        """渲染标签页"""
        tabs = [
            ("species", "📊 物种"),
            ("foodchain", "🔗 食物链"),
            ("events", "📜 事件"),
            ("settings", "⚙️ 设置")
        ]
        
        tab_y = 50
        tab_height = 35
        
        for i, (tab_id, tab_name) in enumerate(tabs):
            tab_rect = pygame.Rect(sidebar_x + 5, tab_y + i * tab_height, self.sidebar_width - 10, tab_height - 2)
            
            if tab_id == self.active_tab:
                pygame.draw.rect(self.screen, self.ui["bg_light"], tab_rect, border_radius=5)
                pygame.draw.rect(self.screen, self.ui["accent"], tab_rect, 2, border_radius=5)
            else:
                pygame.draw.rect(self.screen, self.ui["bg_dark"], tab_rect, border_radius=5)
                
            text_surf = self.font_normal.render(tab_name, True, self.ui["text"])
            self.screen.blit(text_surf, (tab_rect.x + 10, tab_rect.y + 8))
            
    def _render_species_panel(self, sidebar_x):
        """渲染物种统计面板"""
        stats = self.ecosystem.get_statistics()
        species = stats.get('species', {})
        
        y = 200
        panel_height = self.window_height - self.bottom_bar_height - y - 10
        
        # 创建滚动区域
        content_y = y
        
        # 分类显示
        categories = [
            ("🌿 植物", ["grass", "bush", "flower", "moss", "tree", "vine", "cactus", "berry", "mushroom", "fern",
                       "apple_tree", "cherry_tree", "grape_vine", "strawberry", "blueberry", "orange_tree", "watermelon"]),
            ("🐾 动物", ["insect", "rabbit", "fox", "deer", "mouse", "bird", "snake", "bee", "frog",
                       "eagle", "owl", "duck", "swan", "sparrow", "parrot", "kingfisher",
                       "wolf", "spider", "magpie", "crow", "woodpecker", "hummingbird",
                       "squirrel", "hedgehog", "bat", "raccoon",
                       "bear", "wild_boar", "badger", "raccoon_dog", "skunk", "opossum", "coati", "armadillo"]),
            ("🐟 水生", ["algae", "seaweed", "plankton", "small_fish", "minnow", "carp", "catfish", "large_fish", "pufferfish",
                       "blackfish", "pike", "shrimp", "crab", "tadpole", "water_strider"])
        ]
        
        for category_name, species_list in categories:
            # 分类标题
            cat_surf = self.font_medium.render(category_name, True, self.ui["accent"])
            self.screen.blit(cat_surf, (sidebar_x + 15, content_y))
            content_y += 25
            
            # 物种列表
            for sp in species_list:
                if content_y > panel_height + y - 30:
                    break
                    
                count = species.get(sp, 0)
                if count > 0:
                    emoji = self.creature_emoji.get(sp, "?")
                    color = self.creature_colors.get(sp, (200, 200, 200))
                    
                    # 物种条目
                    text = f"{emoji} {sp}: {count}"
                    text_surf = self.font_small.render(text, True, self.ui["text"])
                    self.screen.blit(text_surf, (sidebar_x + 25, content_y))
                    
                    # 数量条
                    bar_width = min(100, count)
                    bar_color = self.ui["success"] if count > 10 else self.ui["warning"] if count > 5 else self.ui["danger"]
                    pygame.draw.rect(self.screen, bar_color,
                                   (sidebar_x + 200, content_y + 2, bar_width, 12), border_radius=3)
                    
                    content_y += 20
                    
            content_y += 10
            
    def _render_foodchain_panel(self, sidebar_x):
        """渲染食物链面板"""
        y = 200
        
        # 食物链图示
        title_surf = self.font_medium.render("🔗 食物链关系", True, self.ui["accent"])
        self.screen.blit(title_surf, (sidebar_x + 15, y))
        y += 30
        
        # 显示捕食关系
        relations = [
            ("🐺 狼", "→ 捕食", "🦌 鹿, 🐰 兔子"),
            ("🦊 狐狸", "→ 捕食", "🐰 兔子, 🐛 昆虫"),
            ("🐟 黑鱼", "→ 捕食", "🐟 鲤鱼"),
            ("🐟 狗鱼", "→ 捕食", "🐟 鲤鱼"),
            ("🦅 老鹰", "→ 捕食", "🐦 鸟, 🐰 兔子"),
            ("🐍 蛇", "→ 捕食", "🐛 昆虫, 🐭 老鼠"),
        ]
        
        for predator, arrow, prey in relations:
            text = f"{predator} {arrow} {prey}"
            text_surf = self.font_small.render(text, True, self.ui["text_dim"])
            self.screen.blit(text_surf, (sidebar_x + 20, y))
            y += 25
            
    def _render_events_panel(self, sidebar_x):
        """渲染事件面板"""
        y = 200
        
        title_surf = self.font_medium.render("📜 最近事件", True, self.ui["accent"])
        self.screen.blit(title_surf, (sidebar_x + 15, y))
        y += 30
        
        # 显示最近事件
        events = self.ecosystem.events[-20:] if hasattr(self.ecosystem, 'events') else []
        
        for event in events[-15:]:
            tick = getattr(event, 'tick', 0)
            desc = getattr(event, 'description', 'Unknown event')
            
            text = f"[{tick}] {desc[:30]}"
            text_surf = self.font_small.render(text, True, self.ui["text_dim"])
            self.screen.blit(text_surf, (sidebar_x + 15, y))
            y += 18
            
    def _render_settings_panel(self, sidebar_x):
        """渲染设置面板"""
        y = 200
        
        # 游戏信息
        title_surf = self.font_medium.render("⚙️ 游戏设置", True, self.ui["accent"])
        self.screen.blit(title_surf, (sidebar_x + 15, y))
        y += 35
        
        stats = self.ecosystem.get_statistics()
        
        info_items = [
            f"📅 日期: Day {stats.get('day', 0)}",
            f"🌡️ 季节: {stats.get('season', 'spring')}",
            f"🌤️ 天气: {stats.get('weather', 'sunny')}",
            f"⏱️ Tick: {stats.get('tick', 0)}",
            f"🔍 缩放: {self.zoom:.1f}x",
            f"⏩ 速度: {self.speed}x",
            "",
            "🎮 快捷键:",
            "  1-9: 添加生物",
            "  Space: 暂停/继续",
            "  +/-: 调整速度",
            "  G: 显示网格",
            "  Home: 重置视角",
            "  鼠标滚轮: 缩放",
            "  右键拖拽: 平移",
        ]
        
        for item in info_items:
            text_surf = self.font_small.render(item, True, self.ui["text"])
            self.screen.blit(text_surf, (sidebar_x + 15, y))
            y += 20
            
    def _render_bottom_bar(self):
        """渲染底部状态栏"""
        bar_rect = pygame.Rect(0, self.window_height - self.bottom_bar_height, 
                               self.window_width, self.bottom_bar_height)
        pygame.draw.rect(self.screen, self.ui["bg_medium"], bar_rect)
        pygame.draw.line(self.screen, self.ui["border"],
                        (0, self.window_height - self.bottom_bar_height),
                        (self.window_width, self.window_height - self.bottom_bar_height), 2)
        
        # 统计信息
        stats = self.ecosystem.get_statistics()
        species = stats.get('species', {})
        
        total_plants = sum(species.get(sp, 0) for sp in ["grass", "bush", "flower", "moss", "tree", "vine", "cactus", "berry", "mushroom", "fern"])
        total_animals = sum(1 for a in self.ecosystem.animals if a.alive)
        total_aquatic = sum(1 for a in self.ecosystem.aquatic_creatures if a.alive)
        
        x = 20
        y = self.window_height - self.bottom_bar_height + 10
        
        # 暂停指示
        if self.paused:
            pause_surf = self.font_medium.render("⏸ 已暂停", True, self.ui["warning"])
            self.screen.blit(pause_surf, (x, y))
            x += 100
        
        # 速度
        speed_surf = self.font_normal.render(f"⏩ {self.speed}x", True, self.ui["text"])
        self.screen.blit(speed_surf, (x, y + 2))
        x += 80
        
        # 种群统计
        stat_text = f"🌿 植物: {total_plants}  🐾 动物: {total_animals}  🐟 水生: {total_aquatic}"
        stat_surf = self.font_normal.render(stat_text, True, self.ui["text"])
        self.screen.blit(stat_surf, (x, y + 2))
        
        # 小地图
        self._render_minimap()
        
    def _render_minimap(self):
        """渲染小地图"""
        minimap_x = self.window_width - self.sidebar_width - self.minimap_size - 20
        minimap_y = self.window_height - self.bottom_bar_height - self.minimap_size - 10
        
        # 小地图背景
        pygame.draw.rect(self.screen, self.ui["bg_dark"],
                        (minimap_x - 2, minimap_y - 2, self.minimap_size + 4, self.minimap_size + 4))
        
        # 绘制地形
        scale_x = self.minimap_size / self.world_width
        scale_y = self.minimap_size / self.world_height
        
        for x in range(0, self.world_width, 5):
            for y in range(0, self.world_height, 5):
                terrain = self.ecosystem.environment.get_terrain(x, y)
                color = self.terrain_colors.get(terrain, (100, 100, 100))
                
                px = int(minimap_x + x * scale_x)
                py = int(minimap_y + y * scale_y)
                pygame.draw.rect(self.screen, color, (px, py, 3, 3))
                
        # 绘制动物位置（点）
        for animal in self.ecosystem.animals[:100]:  # 限制数量
            if animal.alive:
                px = int(minimap_x + animal.position[0] * scale_x)
                py = int(minimap_y + animal.position[1] * scale_y)
                color = self.creature_colors.get(animal.species, (255, 255, 255))
                pygame.draw.circle(self.screen, color, (px, py), 1)
                
        # 视野框
        game_area_width, game_area_height = self._get_game_area_size()
        view_w = int(game_area_width / (self.base_grid_size * self.zoom) * scale_x)
        view_h = int(game_area_height / (self.base_grid_size * self.zoom) * scale_y)
        view_x = int(minimap_x + self.camera_x * scale_x)
        view_y = int(minimap_y + self.camera_y * scale_y)
        
        pygame.draw.rect(self.screen, (255, 255, 255), (view_x, view_y, view_w, view_h), 1)
        
    def _render_weather_effects(self):
        """渲染天气效果"""
        for particle in self.weather_particles:
            if particle['type'] == 'rain':
                # 雨滴
                pygame.draw.line(self.screen, (100, 149, 237),
                               (particle['x'], particle['y']),
                               (particle['x'] - 2, particle['y'] + 10), 2)
            elif particle['type'] == 'snow':
                # 雪花
                pygame.draw.circle(self.screen, (255, 255, 255),
                                 (int(particle['x']), int(particle['y'])), 3)
                                 
    def _render_notifications(self):
        """渲染通知消息"""
        y = 10
        
        for message, tick in self.notifications[-self.max_notifications:]:
            alpha = max(0, 255 - (self.tick - tick) * 2)
            
            # 创建带透明度的表面
            text_surf = self.font_normal.render(message, True, (255, 255, 255))
            
            # 背景
            bg_rect = pygame.Rect(10, y, text_surf.get_width() + 20, 25)
            bg_surf = pygame.Surface((bg_rect.width, bg_rect.height), pygame.SRCALPHA)
            pygame.draw.rect(bg_surf, (0, 0, 0, min(200, alpha)), bg_surf.get_rect(), border_radius=5)
            
            self.screen.blit(bg_surf, bg_rect)
            self.screen.blit(text_surf, (20, y + 5))
            
            y += 30

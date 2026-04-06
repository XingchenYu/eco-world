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
        self.sidebar_width = 380
        self.bottom_bar_height = 88
        self.minimap_size = 170
        
        # 创建窗口
        self.screen = pygame.display.set_mode((self.window_width, self.window_height), pygame.RESIZABLE)
        pygame.display.set_caption("生态世界 - 虚拟生态系统模拟器")
        
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
        self.show_microhabitats = True
        self.max_notifications = 5
        
        # === 颜色主题 ===
        self._init_colors()

        # === 字体 ===
        self._init_fonts()

        # === 文案映射 ===
        self._init_labels()

        # === 生物精灵 ===
        self._init_sprites()
        
        # === UI组件 ===
        self.notifications = []
        self.active_tab = "species"  # species, foodchain, events, settings
        self.panel_scrolls = {"species": 0, "foodchain": 0, "events": 0, "settings": 0}
        self.panel_scroll_limits = {"species": 0, "foodchain": 0, "events": 0, "settings": 0}
        self._terrain_cache = None
        self._terrain_cache_key = None
        self._minimap_surface = None
        self._minimap_cache_key = None
        self._entity_shadow_alpha = 85

        self._clamp_camera()
        
    def _init_colors(self):
        """初始化颜色主题"""
        # 地形颜色（偏自然主义）
        self.terrain_colors = {
            "grass": (111, 152, 78),
            "forest": (53, 86, 49),
            "rock": (122, 120, 114),
            "water_shallow": (96, 150, 156),
            "water_deep": (45, 92, 111),
            "river": (63, 121, 137),
            "sand": (184, 164, 124),
            "mud": (110, 88, 60),
        }
        
        # 地形纹理颜色（用于细节）
        self.terrain_detail = {
            "grass": [(103, 146, 70), (121, 160, 88), (95, 134, 64)],
            "forest": [(46, 78, 41), (58, 91, 53), (39, 67, 37)],
            "water_shallow": [(88, 143, 149), (103, 159, 167), (78, 134, 141)],
            "water_deep": [(42, 87, 104), (51, 97, 116), (36, 78, 93)],
            "river": [(58, 115, 130), (71, 129, 143), (48, 102, 117)],
            "sand": [(176, 156, 118), (190, 169, 130), (166, 146, 112)],
            "mud": [(103, 81, 56), (118, 94, 66), (91, 71, 49)],
        }

        # UI颜色
        self.ui = {
            "bg_dark": (27, 29, 24),
            "bg_medium": (39, 43, 35),
            "bg_light": (53, 60, 48),
            "panel": (244, 239, 229),
            "panel_alt": (231, 224, 209),
            "border": (118, 108, 88),
            "text": (40, 35, 27),
            "text_dim": (102, 95, 81),
            "accent": (75, 118, 92),
            "accent_strong": (51, 88, 66),
            "success": (85, 128, 68),
            "warning": (181, 130, 58),
            "danger": (156, 78, 61),
            "highlight": (173, 144, 88),
            "shadow": (22, 24, 20),
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
        preferred = [
            "PingFang SC", "Hiragino Sans GB", "Heiti SC", "Songti SC",
            "Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Source Han Sans SC",
        ]
        font_name = None
        for candidate in preferred:
            if pygame.font.match_font(candidate):
                font_name = candidate
                break

        if font_name:
            self.font_small = pygame.font.SysFont(font_name, 16)
            self.font_normal = pygame.font.SysFont(font_name, 20)
            self.font_medium = pygame.font.SysFont(font_name, 24)
            self.font_large = pygame.font.SysFont(font_name, 30, bold=True)
            self.font_title = pygame.font.SysFont(font_name, 38, bold=True)
        else:
            self.font_small = pygame.font.Font(None, 18)
            self.font_normal = pygame.font.Font(None, 22)
            self.font_medium = pygame.font.Font(None, 26)
            self.font_large = pygame.font.Font(None, 32)
            self.font_title = pygame.font.Font(None, 40)

    def _init_labels(self):
        """初始化中文标签。"""
        self.tab_labels = {
            "species": "生态总览",
            "foodchain": "食物关系",
            "events": "近期事件",
            "settings": "运行信息",
        }
        self.season_labels = {
            "spring": "春季",
            "summer": "夏季",
            "autumn": "秋季",
            "winter": "冬季",
        }
        self.weather_labels = {
            "sunny": "晴朗",
            "cloudy": "多云",
            "rainy": "降雨",
            "stormy": "暴雨",
            "snowy": "降雪",
            "drought": "干旱",
        }
        self.terrain_labels = {
            "grass": "草地",
            "forest": "林地",
            "rock": "岩地",
            "water_shallow": "浅水",
            "water_deep": "深水",
            "river": "河道",
            "sand": "沙地",
            "mud": "泥地",
        }
        self.species_labels = {
            "grass": "草", "bush": "灌木", "flower": "花朵", "moss": "苔藓", "tree": "树木",
            "vine": "藤蔓", "cactus": "仙人掌", "berry": "浆果丛", "mushroom": "蘑菇", "fern": "蕨类",
            "apple_tree": "苹果树", "cherry_tree": "樱桃树", "grape_vine": "葡萄藤", "strawberry": "草莓",
            "blueberry": "蓝莓", "orange_tree": "橙树", "watermelon": "西瓜",
            "bear": "熊", "wild_boar": "野猪", "badger": "獾", "raccoon_dog": "狸", "skunk": "臭鼬",
            "opossum": "负鼠", "coati": "长鼻浣熊", "armadillo": "犰狳", "rabbit": "兔子", "deer": "鹿",
            "squirrel": "松鼠", "mouse": "老鼠", "bee": "蜜蜂", "wolf": "狼", "fox": "狐狸",
            "snake": "蛇", "spider": "蜘蛛", "hedgehog": "刺猬", "bird": "小鸟", "eagle": "老鹰",
            "owl": "猫头鹰", "duck": "鸭", "swan": "天鹅", "sparrow": "麻雀", "parrot": "鹦鹉",
            "kingfisher": "翠鸟", "magpie": "喜鹊", "crow": "乌鸦", "woodpecker": "啄木鸟",
            "hummingbird": "蜂鸟", "insect": "昆虫", "night_moth": "夜飞蛾", "bat": "蝙蝠", "frog": "青蛙",
            "algae": "藻类", "seaweed": "水草", "plankton": "浮游生物", "small_fish": "小鱼",
            "minnow": "米诺鱼", "carp": "鲤鱼", "catfish": "鲶鱼", "large_fish": "大鱼",
            "pufferfish": "河豚", "blackfish": "黑鱼", "pike": "狗鱼", "shrimp": "虾", "crab": "蟹",
            "tadpole": "蝌蚪", "water_strider": "水黾",
        }

    def _label_species(self, species: str) -> str:
        return self.species_labels.get(species, species)

    def _label_weather(self, weather: str) -> str:
        return self.weather_labels.get(weather, weather)

    def _label_season(self, season: str) -> str:
        return self.season_labels.get(season, season)
                
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
            self._notify("🧭 网格已显示" if self.show_grid else "🧭 网格已隐藏")
        elif key == pygame.K_m:
            self.show_microhabitats = not self.show_microhabitats
            self._notify("🌱 微栖息地已显示" if self.show_microhabitats else "🌱 微栖息地已隐藏")
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
        """处理鼠标滚轮 - 侧栏滚动或世界缩放"""
        mouse_x, _ = pygame.mouse.get_pos()
        if mouse_x >= self.window_width - self.sidebar_width:
            current = self.panel_scrolls.get(self.active_tab, 0)
            limit = self.panel_scroll_limits.get(self.active_tab, 0)
            next_scroll = min(limit, max(0, current - direction * 36))
            if next_scroll != current:
                self.panel_scrolls[self.active_tab] = next_scroll
            return
        old_zoom = self.zoom
        self.zoom = max(self.min_zoom, min(self.max_zoom, self.zoom + direction * 0.1))
        
        if old_zoom != self.zoom:
            self._clamp_camera()
            self._notify(f"🔍 缩放: {self.zoom:.1f}x")

    def _handle_resize(self, width, height):
        """处理窗口尺寸变化。"""
        self.window_width = max(960, width)
        self.window_height = max(640, height)
        self.sidebar_width = min(430, max(320, self.window_width // 3))
        self.minimap_size = min(210, max(130, self.window_height // 6))
        self.screen = pygame.display.set_mode((self.window_width, self.window_height), pygame.RESIZABLE)
        self._terrain_cache_key = None
        self._minimap_cache_key = None
        self._clamp_camera()
        self._notify(f"🪟 窗口: {self.window_width}x{self.window_height}")

    def _content_viewport(self, sidebar_x):
        top_y = 206
        height = self.window_height - self.bottom_bar_height - top_y - 18
        rect = pygame.Rect(sidebar_x + 12, top_y, self.sidebar_width - 24, max(120, height))
        return rect

    def _apply_panel_scroll(self, tab: str, content_end_y: int, viewport_rect: pygame.Rect):
        limit = max(0, content_end_y - viewport_rect.height)
        self.panel_scroll_limits[tab] = limit
        self.panel_scrolls[tab] = min(self.panel_scrolls.get(tab, 0), limit)

    def _render_scroll_hint(self, viewport_rect: pygame.Rect, tab: str):
        limit = self.panel_scroll_limits.get(tab, 0)
        if limit <= 0:
            return
        track = pygame.Rect(viewport_rect.right - 6, viewport_rect.y + 6, 4, viewport_rect.height - 12)
        pygame.draw.rect(self.screen, self.ui["panel_alt"], track, border_radius=3)
        scroll = self.panel_scrolls.get(tab, 0)
        thumb_h = max(36, int(track.height * viewport_rect.height / max(viewport_rect.height, viewport_rect.height + limit)))
        thumb_y = track.y + int((track.height - thumb_h) * scroll / max(1, limit))
        thumb = pygame.Rect(track.x, thumb_y, track.width, thumb_h)
        pygame.draw.rect(self.screen, self.ui["accent"], thumb, border_radius=3)
            
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
                self._notify(f"选中：{self.creature_emoji.get(animal.species, '?')} {self._label_species(animal.species)}")
                return
                
        # 检查植物
        for plant in self.ecosystem.plants:
            if plant.position == (x, y) and plant.alive:
                self.selected_creature = plant
                self._notify(f"选中：{self.creature_emoji.get(plant.species, '?')} {self._label_species(plant.species)}")
                return
                
        # 检查水生生物
        for aquatic in self.ecosystem.aquatic_creatures:
            if aquatic.position == (x, y) and aquatic.alive:
                self.selected_creature = aquatic
                self._notify(f"选中：{self.creature_emoji.get(aquatic.species, '?')} {self._label_species(aquatic.species)}")
                return
                
        self.selected_creature = None
        
    def _handle_sidebar_click(self, pos):
        """处理侧边栏点击"""
        # 检查标签页点击
        sidebar_x = self.window_width - self.sidebar_width
        rel_x = pos[0] - sidebar_x
        rel_y = pos[1]
        
        tabs = ["species", "foodchain", "events", "settings"]
        header_y = 104
        tab_gap = 10
        tab_width = (self.sidebar_width - 40 - tab_gap) // 2
        tab_height = 42

        for i, tab in enumerate(tabs):
            row = i // 2
            col = i % 2
            tab_rect = pygame.Rect(
                20 + col * (tab_width + tab_gap),
                header_y + row * (tab_height + 10),
                tab_width,
                tab_height,
            )
            if tab_rect.collidepoint(rel_x, rel_y):
                self.active_tab = tab
                self._notify(f"切换到：{self.tab_labels.get(tab, tab)}")
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
        particle_cap = max(50, (self.window_width - self.sidebar_width) // 6)

        # 添加新粒子
        if weather in {'rainy', 'stormy'} and len(self.weather_particles) < particle_cap and random.random() < (0.22 if weather == 'stormy' else 0.12):
            self.weather_particles.append({
                'x': random.randint(0, max(1, self.window_width - self.sidebar_width)),
                'y': 0,
                'speed': random.randint(7, 13) if weather == 'stormy' else random.randint(5, 10),
                'type': 'rain'
            })
        elif weather == 'snowy' and len(self.weather_particles) < particle_cap // 2 and random.random() < 0.08:
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

        # 渲染微栖息地资源
        self._render_microhabitats(game_surface, grid_size)
        
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
        """渲染地形。"""
        cache_key = (start_x, start_y, end_x, end_y, grid_size)
        if self._terrain_cache_key != cache_key:
            width = surface.get_width()
            height = surface.get_height()
            cached = pygame.Surface((width, height))
            cached.fill((68, 78, 62))
            self._build_terrain_cache(cached, start_x, start_y, end_x, end_y, grid_size)
            self._terrain_cache = cached
            self._terrain_cache_key = cache_key
        surface.blit(self._terrain_cache, (0, 0))

    def _build_terrain_cache(self, surface, start_x, start_y, end_x, end_y, grid_size):
        """构建可见区域地形缓存。"""
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
                
                rect = pygame.Rect(screen_x, screen_y, grid_size, grid_size)
                pygame.draw.rect(surface, color, rect)
                if grid_size >= 12:
                    shadow = tuple(max(0, c - 10) for c in color)
                    highlight = tuple(min(255, c + 8) for c in color)
                    pygame.draw.line(surface, highlight, (rect.x, rect.y), (rect.right, rect.y))
                    pygame.draw.line(surface, shadow, (rect.x, rect.bottom - 1), (rect.right, rect.bottom - 1))
                if terrain in ["water_shallow", "water_deep", "river"] and grid_size >= 10:
                    pygame.draw.arc(
                        surface,
                        tuple(min(255, c + 12) for c in color),
                        rect.inflate(-grid_size // 4, -grid_size // 3),
                        math.pi * 0.1,
                        math.pi * 0.9,
                        1,
                    )
                    
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
                self._draw_tree(surface, screen_x, screen_y, grid_size, color, plant)
            elif plant.species in ["bush", "berry", "blueberry"]:
                self._draw_bush(surface, screen_x, screen_y, draw_size, color, plant)
            elif plant.species == "flower":
                self._draw_flower(surface, screen_x, screen_y, draw_size, plant)
            elif plant.species == "cactus":
                # 仙人掌
                self._draw_cactus(surface, screen_x, screen_y, draw_size, color)
            elif plant.species == "mushroom":
                # 蘑菇
                self._draw_mushroom(surface, screen_x, screen_y, draw_size, color)
            else:
                # 默认植物
                self._draw_ground_plant(surface, screen_x, screen_y, draw_size, color)

    def _draw_shadow(self, surface, center_x, center_y, width, height):
        shadow = pygame.Surface((width, height), pygame.SRCALPHA)
        pygame.draw.ellipse(shadow, (*self.ui["shadow"], self._entity_shadow_alpha), shadow.get_rect())
        surface.blit(shadow, (center_x - width // 2, center_y - height // 2))

    def _shade(self, color, delta):
        return tuple(max(0, min(255, channel + delta)) for channel in color)

    def _draw_ground_plant(self, surface, x, y, size, color):
        center_x = x + size // 2
        center_y = y + size // 2
        self._draw_shadow(surface, center_x, center_y + size // 3, size, max(4, size // 2))
        stem_color = self._shade(color, -30)
        for offset in (-3, 0, 3):
            pygame.draw.line(surface, stem_color, (center_x, center_y + size // 3), (center_x + offset, center_y - size // 3), 2)
        pygame.draw.circle(surface, self._shade(color, 12), (center_x - 2, center_y - size // 5), max(2, size // 4))
        pygame.draw.circle(surface, color, (center_x + 3, center_y - size // 4), max(2, size // 4))
                                 
    def _draw_tree(self, surface, x, y, grid_size, color, plant):
        """绘制大树"""
        center_x = x + grid_size // 2
        center_y = y + grid_size // 2
        self._draw_shadow(surface, center_x, y + grid_size + 4, int(grid_size * 0.9), max(6, grid_size // 3))
        trunk_color = (98, 72, 48)
        trunk_width = grid_size // 4
        trunk_height = grid_size // 2
        pygame.draw.rect(surface, trunk_color, 
                        (center_x - trunk_width // 2, center_y,
                         trunk_width, trunk_height))
        crown_radius = int(grid_size * 0.4 * (plant.size / 2 if hasattr(plant, 'size') else 1))
        pygame.draw.circle(surface, self._shade(color, -18), (center_x + 3, center_y + 3), crown_radius)
        pygame.draw.circle(surface, color, (center_x, center_y), crown_radius)
        pygame.draw.circle(surface, self._shade(color, 12), (center_x - crown_radius // 3, center_y - crown_radius // 3), max(3, crown_radius // 2))
        if hasattr(plant, 'has_fruit') and plant.has_fruit:
            fruit_color = self.creature_colors.get(plant.species, (255, 0, 0))
            for _ in range(min(3, plant.fruit_count if hasattr(plant, 'fruit_count') else 3)):
                fx = center_x + random.randint(-crown_radius // 2, crown_radius // 2)
                fy = center_y + random.randint(-crown_radius // 2, crown_radius // 2)
                pygame.draw.circle(surface, fruit_color, (fx, fy), 3)
                
    def _draw_bush(self, surface, x, y, size, color, plant):
        """绘制灌木"""
        center_x = x + size // 2
        center_y = y + size // 2
        self._draw_shadow(surface, center_x, center_y + size // 2, size + 4, max(4, size // 2))
        pygame.draw.circle(surface, self._shade(color, -16), (center_x + 2, center_y + 2), size // 2)
        pygame.draw.circle(surface, color, (center_x, center_y), size // 2)
        pygame.draw.circle(surface, self._shade(color, 18), (x + size // 3, y + size // 3), size // 3)
        pygame.draw.circle(surface, self._shade(color, -24), (x + size * 2 // 3, y + size * 2 // 3), size // 3)
        if hasattr(plant, 'has_fruit') and plant.has_fruit:
            berry_color = (120, 62, 104)
            for _ in range(3):
                bx = x + random.randint(2, size - 2)
                by = y + random.randint(2, size - 2)
                pygame.draw.circle(surface, berry_color, (bx, by), 2)
                
    def _draw_flower(self, surface, x, y, size, plant):
        """绘制花"""
        colors = [(214, 162, 171), (197, 102, 128), (189, 126, 78), (219, 196, 91)]
        color = colors[(plant.position[0] + plant.position[1]) % len(colors)]
        center_x, center_y = x + size // 2, y + size // 2
        self._draw_shadow(surface, center_x, center_y + size // 3, size, max(4, size // 2))
        pygame.draw.line(surface, (78, 122, 60), (center_x, center_y + size // 2), (center_x, center_y - size // 3), 2)
        petal_size = size // 3
        for angle in range(0, 360, 60):
            rad = math.radians(angle + self.animation_tick)
            px = center_x + int(math.cos(rad) * petal_size)
            py = center_y + int(math.sin(rad) * petal_size)
            pygame.draw.circle(surface, color, (px, py), petal_size // 2)
        pygame.draw.circle(surface, (202, 170, 72), (center_x, center_y), petal_size // 3)
        
    def _draw_cactus(self, surface, x, y, size, color):
        """绘制仙人掌"""
        self._draw_shadow(surface, x + size // 2, y + size, size, max(4, size // 3))
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
        self._draw_shadow(surface, x + size // 2, y + size, size, max(4, size // 3))
        pygame.draw.ellipse(surface, self._shade(color, -8), (x + 1, y + 2, size, size // 2))
        pygame.draw.ellipse(surface, color, (x, y, size, size // 2))
        pygame.draw.rect(surface, (233, 224, 204), (x + size // 3, y + size // 3, size // 3, size // 2))
                        
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
                size = int(grid_size * 0.4)
                center_x = screen_x + grid_size // 2
                center_y = screen_y + grid_size // 2
                self._draw_shadow(surface, center_x, center_y + size, size * 2, max(4, size))
                pygame.draw.circle(surface, color, (center_x, center_y), size)
                                 
    def _draw_bird(self, surface, x, y, grid_size, color, animal):
        """绘制小鸟"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 3
        self._draw_shadow(surface, center_x, center_y + size, size * 2, max(4, size // 2))
        pygame.draw.ellipse(surface, self._shade(color, -18), (center_x - size + 2, center_y - size // 2 + 2, size * 2, size))
        pygame.draw.ellipse(surface, color, (center_x - size, center_y - size // 2, size * 2, size))
        wing_angle = math.sin(self.animation_tick * 0.2 + animal.position[0]) * 0.3
        wing_y = center_y + int(wing_angle * size)
        pygame.draw.ellipse(surface, self._shade(color, 22),
                          (center_x - size, wing_y - size // 3, size // 2, size // 2))
        pygame.draw.circle(surface, color, (center_x + size // 2, center_y - size // 4), size // 3)
        beak_color = (191, 132, 64)
        pygame.draw.polygon(surface, beak_color,
                          [(center_x + size, center_y), 
                           (center_x + size + size // 3, center_y),
                           (center_x + size, center_y + size // 4)])
                           
    def _draw_raptor(self, surface, x, y, grid_size, color, animal):
        """绘制猛禽"""
        center_x, center_y = x + grid_size // 2, y + grid_size // 2
        size = grid_size // 2
        self._draw_shadow(surface, center_x, center_y + size, size * 3, max(6, size // 2))
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
        self._draw_shadow(surface, center_x, center_y + size, size * 2, max(4, size // 2))
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
        self._draw_shadow(surface, center_x, center_y + size, size * 2, max(4, size // 2))
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
        self._draw_shadow(surface, center_x, center_y + size, size * 2, max(4, size // 2))
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
        self._draw_shadow(surface, center_x, center_y + size, size * 2, max(4, size // 2))
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
        points = []
        for i in range(5):
            offset_x = i * size // 2
            offset_y = int(math.sin(self.animation_tick * 0.1 + i) * size // 2)
            points.append((x + offset_x, y + grid_size // 2 + offset_y))
        if points:
            self._draw_shadow(surface, x + size, y + grid_size // 2 + size // 2, size * 3, max(4, size))
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
        self._draw_shadow(surface, center_x, center_y + size, size * 3, max(5, size))
        pygame.draw.ellipse(surface, color,
                          (center_x - size, center_y - size // 2, size * 2, size))
        head_x = center_x + size // 2
        pygame.draw.circle(surface, color, (head_x, center_y - size // 4), size // 2)
        if animal.species == "fox":
            pygame.draw.polygon(surface, self._shade(color, -30), [(head_x - 2, center_y - size), (head_x + size // 6, center_y - size // 2), (head_x - size // 4, center_y - size // 2)])
            pygame.draw.polygon(surface, self._shade(color, -30), [(head_x + size // 3, center_y - size), (head_x + size // 2, center_y - size // 2), (head_x, center_y - size // 2)])
        if animal.species == "deer":
            antler_color = (120, 96, 66)
            pygame.draw.line(surface, antler_color, (head_x, center_y - size // 2), (head_x + size // 3, center_y - size), 2)
            pygame.draw.line(surface, antler_color, (head_x + size // 5, center_y - size // 2), (head_x + size // 2, center_y - size + 2), 2)
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
                self._draw_shadow(surface, center_x, center_y + grid_size // 2, grid_size, max(4, grid_size // 3))
                pygame.draw.ellipse(surface, color, (center_x - grid_size // 4, center_y - grid_size // 3, grid_size // 2, grid_size // 1.5))
            elif aquatic.species == "plankton":
                pygame.draw.circle(surface, color, (center_x, center_y), 2)
            elif aquatic.species in ["small_fish", "minnow", "carp", "catfish", "large_fish", "blackfish", "pike"]:
                self._draw_fish(surface, center_x, center_y, grid_size, color, aquatic)
            elif aquatic.species == "pufferfish":
                size = grid_size // 3
                self._draw_shadow(surface, center_x, center_y + size, size * 2, max(4, size))
                pygame.draw.circle(surface, color, (center_x, center_y), size)
                pygame.draw.circle(surface, (50, 50, 50), (center_x - size // 3, center_y), 1)
                pygame.draw.circle(surface, (50, 50, 50), (center_x + size // 3, center_y), 1)
            elif aquatic.species == "shrimp":
                self._draw_shrimp(surface, center_x, center_y, grid_size, color)
            elif aquatic.species == "crab":
                self._draw_crab(surface, center_x, center_y, grid_size, color)
            elif aquatic.species == "tadpole":
                self._draw_shadow(surface, center_x, center_y + grid_size // 3, grid_size, max(4, grid_size // 3))
                pygame.draw.circle(surface, color, (center_x, center_y), grid_size // 5)
                pygame.draw.line(surface, color, (center_x, center_y),
                               (center_x + grid_size // 4, center_y), 2)
            else:
                pygame.draw.circle(surface, color, (center_x, center_y), grid_size // 4)

    def _render_microhabitats(self, surface, grid_size):
        """渲染微栖息地资源点。"""
        if not self.show_microhabitats or grid_size < 10 or not hasattr(self.ecosystem, "microhabitats"):
            return
        colors = {
            "canopy_roost": (91, 140, 86),
            "night_roost": (88, 98, 138),
            "shrub_shelter": (118, 156, 92),
            "nectar_patch": (224, 148, 104),
            "wetland_patch": (94, 164, 150),
            "riparian_perch": (106, 150, 190),
            "night_swarm": (140, 122, 74),
            "canopy_forage": (150, 172, 92),
            "shore_hatch": (185, 197, 108),
        }
        for patch in self.ecosystem.microhabitats:
            screen_x = int((patch.position[0] - self.camera_x) * grid_size)
            screen_y = int((patch.position[1] - self.camera_y) * grid_size)
            if screen_x < -grid_size or screen_x > surface.get_width():
                continue
            if screen_y < -grid_size or screen_y > surface.get_height():
                continue
            base = colors.get(patch.kind, (180, 180, 180))
            occupancy_ratio = 0 if patch.capacity <= 0 else min(1.0, patch.occupancy / patch.capacity)
            available_ratio = 0 if patch.capacity <= 0 else min(1.0, patch.available / max(0.1, patch.capacity * max(0.45, patch.seasonal_multiplier)))
            radius = max(2, grid_size // 7)
            color = (
                max(30, int(base[0] * (0.7 + available_ratio * 0.3))),
                max(30, int(base[1] * (0.7 + available_ratio * 0.3))),
                max(30, int(base[2] * (0.7 + available_ratio * 0.3))),
            )
            pygame.draw.circle(surface, color, (screen_x + grid_size // 2, screen_y + grid_size // 2), radius)
            if occupancy_ratio > 0.15:
                ring = tuple(max(20, c - 55) for c in color)
                pygame.draw.circle(surface, ring, (screen_x + grid_size // 2, screen_y + grid_size // 2), radius + 2, 1)
                
    def _draw_fish(self, surface, x, y, grid_size, color, aquatic):
        """绘制鱼"""
        size = grid_size // 3
        self._draw_shadow(surface, x, y + size, size * 3, max(4, size))
        body_rect = pygame.Rect(x - size, y - size // 2, size * 2, size)
        pygame.draw.ellipse(surface, self._shade(color, -18), body_rect.move(2, 2))
        pygame.draw.ellipse(surface, color, body_rect)
        pygame.draw.ellipse(surface, self._shade(color, 12), pygame.Rect(x - size // 2, y - size // 3, size, size // 2))
        tail_points = [(x - size, y), (x - size - size // 2, y - size // 2), (x - size - size // 2, y + size // 2)]
        pygame.draw.polygon(surface, color, tail_points)
        pygame.draw.circle(surface, (255, 255, 255), (x + size // 2, y - size // 4), size // 4)
        pygame.draw.circle(surface, (0, 0, 0), (x + size // 2, y - size // 4), size // 6)
            
    def _draw_shrimp(self, surface, x, y, grid_size, color):
        """绘制虾"""
        size = grid_size // 4
        self._draw_shadow(surface, x, y + size, size * 4, max(4, size))
        for i in range(4):
            segment_x = x - i * size // 2
            segment_y = y + int(math.sin(self.animation_tick * 0.1 + i) * 2)
            pygame.draw.circle(surface, color, (segment_x, segment_y), size // 2)
        pygame.draw.line(surface, color, (x + size, y - size // 2), (x + size * 2, y - size), 1)
        pygame.draw.line(surface, color, (x + size, y + size // 2), (x + size * 2, y + size), 1)
        
    def _draw_crab(self, surface, x, y, grid_size, color):
        """绘制螃蟹"""
        size = grid_size // 3
        self._draw_shadow(surface, x, y + size, size * 3, max(4, size))
        pygame.draw.ellipse(surface, color, (x - size, y - size // 2, size * 2, size))
        pygame.draw.circle(surface, color, (x - size - size // 2, y - size // 2), size // 2)
        pygame.draw.circle(surface, color, (x + size + size // 2, y - size // 2), size // 2)
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
        pygame.draw.rect(self.screen, self.ui["panel"], sidebar_rect)
        pygame.draw.line(self.screen, self.ui["border"], (sidebar_x, 0), (sidebar_x, self.window_height), 2)

        title_surf = self.font_title.render("生态世界", True, self.ui["text"])
        subtitle_surf = self.font_small.render("动态食物网与地形环境模拟", True, self.ui["text_dim"])
        self.screen.blit(title_surf, (sidebar_x + 20, 18))
        self.screen.blit(subtitle_surf, (sidebar_x + 22, 62))

        self._render_tabs(sidebar_x)

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
        tabs = ["species", "foodchain", "events", "settings"]
        header_y = 104
        tab_gap = 10
        tab_width = (self.sidebar_width - 40 - tab_gap) // 2
        tab_height = 42

        for i, tab_id in enumerate(tabs):
            row = i // 2
            col = i % 2
            tab_rect = pygame.Rect(
                sidebar_x + 20 + col * (tab_width + tab_gap),
                header_y + row * (tab_height + 10),
                tab_width,
                tab_height,
            )
            if tab_id == self.active_tab:
                pygame.draw.rect(self.screen, self.ui["accent"], tab_rect, border_radius=10)
                text_color = (248, 245, 238)
            else:
                pygame.draw.rect(self.screen, self.ui["panel_alt"], tab_rect, border_radius=10)
                pygame.draw.rect(self.screen, self.ui["border"], tab_rect, 1, border_radius=10)
                text_color = self.ui["text"]

            text_surf = self.font_normal.render(self.tab_labels[tab_id], True, text_color)
            self.screen.blit(text_surf, text_surf.get_rect(center=tab_rect.center))

    def _draw_info_card(self, rect, title, value, tone="accent"):
        pygame.draw.rect(self.screen, self.ui["panel_alt"], rect, border_radius=14)
        pygame.draw.rect(self.screen, self.ui["border"], rect, 1, border_radius=14)
        title_surf = self.font_small.render(title, True, self.ui["text_dim"])
        value_color = self.ui.get(tone, self.ui["accent"])
        value_surf = self.font_large.render(value, True, value_color)
        self.screen.blit(title_surf, (rect.x + 14, rect.y + 10))
        self.screen.blit(value_surf, (rect.x + 14, rect.y + 32))

    def _render_selected_creature_card(self, sidebar_x, y):
        """渲染当前选中生物详情。"""
        if not self.selected_creature or not getattr(self.selected_creature, "alive", False):
            return y

        rect = pygame.Rect(sidebar_x + 18, y, self.sidebar_width - 36, 142)
        pygame.draw.rect(self.screen, self.ui["panel_alt"], rect, border_radius=14)
        pygame.draw.rect(self.screen, self.ui["border"], rect, 1, border_radius=14)
        species = getattr(self.selected_creature, "species", "未知")
        emoji = self.creature_emoji.get(species, "•")
        title = self.font_medium.render(f"{emoji} {self._label_species(species)}", True, self.ui["text"])
        meta = self.font_small.render(f"位置 ({self.selected_creature.position[0]}, {self.selected_creature.position[1]})", True, self.ui["text_dim"])
        self.screen.blit(title, (rect.x + 14, rect.y + 10))
        self.screen.blit(meta, (rect.x + 14, rect.y + 38))

        info_items = [
            ("生命", int(getattr(self.selected_creature, "health", 0))),
            ("饥饿", int(getattr(self.selected_creature, "hunger", 0))),
            ("年龄", int(getattr(self.selected_creature, "age", 0))),
        ]
        bar_y = rect.y + 66
        for index, (label, value) in enumerate(info_items):
            slot_x = rect.x + 14 + index * ((rect.width - 28) // 3)
            self.screen.blit(self.font_small.render(f"{label} {value}", True, self.ui["text"]), (slot_x, bar_y))

        if hasattr(self.selected_creature, "breeding_microhabitat_kinds"):
            patch_labels = {
                "canopy_roost": "树冠位",
                "night_roost": "夜栖位",
                "shrub_shelter": "灌丛位",
                "nectar_patch": "花蜜位",
                "wetland_patch": "湿地位",
                "riparian_perch": "岸栖位",
                "night_swarm": "夜虫群",
                "canopy_forage": "树冠食位",
                "shore_hatch": "近岸羽化带",
            }
            kinds = self.selected_creature.breeding_microhabitat_kinds()
            if kinds:
                patch_text = "繁殖资源：" + " / ".join(patch_labels.get(kind, kind) for kind in kinds)
                self.screen.blit(self.font_small.render(patch_text, True, self.ui["text_dim"]), (rect.x + 14, rect.y + 96))
                if hasattr(self.ecosystem, "get_local_microhabitat_value"):
                    patch_value = self.ecosystem.get_local_microhabitat_value(self.selected_creature.position, kinds, radius=4)
                    support_text = f"局部可用度：{patch_value:.2f}"
                    self.screen.blit(self.font_small.render(support_text, True, self.ui["accent"]), (rect.x + 14, rect.y + 116))
        return rect.bottom + 12
            
    def _render_species_panel(self, sidebar_x):
        """渲染物种统计面板"""
        stats = self.ecosystem.get_statistics()
        species = stats.get('species', {})
        viewport = self._content_viewport(sidebar_x)
        scroll = self.panel_scrolls.get("species", 0)
        previous_clip = self.screen.get_clip()
        self.screen.set_clip(viewport)

        top_y = 206 - scroll
        content_y = top_y + 108
        panel_bottom = self.window_height - self.bottom_bar_height - 18
        card_width = (self.sidebar_width - 52) // 2

        total_plants = sum(species.get(sp, 0) for sp in self.species_labels if sp in {
            "grass", "bush", "flower", "moss", "tree", "vine", "cactus", "berry", "mushroom", "fern",
            "apple_tree", "cherry_tree", "grape_vine", "strawberry", "blueberry", "orange_tree", "watermelon"
        })
        total_animals = sum(1 for animal in self.ecosystem.animals if animal.alive)
        total_aquatic = sum(1 for aquatic in self.ecosystem.aquatic_creatures if aquatic.alive)
        health = stats.get("ecosystem_health", 0)
        self._draw_info_card(pygame.Rect(sidebar_x + 18, top_y, card_width, 86), "生态健康度", f"{health:.0f}", "accent_strong")
        self._draw_info_card(pygame.Rect(sidebar_x + 30 + card_width, top_y, card_width, 86), "存活生物", f"{total_animals + total_aquatic + total_plants}", "success")
        content_y = self._render_selected_creature_card(sidebar_x, content_y)

        apex_species = [
            ("fox", species.get("fox", 0)),
            ("wolf", species.get("wolf", 0)),
            ("eagle", species.get("eagle", 0)),
            ("owl", species.get("owl", 0)),
            ("blackfish", species.get("blackfish", 0)),
            ("pike", species.get("pike", 0)),
        ]
        apex_rect = pygame.Rect(sidebar_x + 18, content_y, self.sidebar_width - 36, 94)
        pygame.draw.rect(self.screen, self.ui["panel_alt"], apex_rect, border_radius=14)
        pygame.draw.rect(self.screen, self.ui["border"], apex_rect, 1, border_radius=14)
        self.screen.blit(self.font_medium.render("顶层控制物种", True, self.ui["accent_strong"]), (apex_rect.x + 14, apex_rect.y + 10))
        row_y = apex_rect.y + 44
        col_x = apex_rect.x + 14
        for idx, (sp, count) in enumerate(apex_species):
            if idx == 3:
                row_y += 24
                col_x = apex_rect.x + 14
            label = f"{self.creature_emoji.get(sp, '•')} {self._label_species(sp)} {count}"
            self.screen.blit(self.font_small.render(label, True, self.ui["text"]), (col_x, row_y))
            col_x += 112
        content_y = apex_rect.bottom + 14

        categories = [
            ("🌿 植物", ["grass", "bush", "flower", "moss", "tree", "vine", "cactus", "berry", "mushroom", "fern",
                       "apple_tree", "cherry_tree", "grape_vine", "strawberry", "blueberry", "orange_tree", "watermelon"]),
            ("🐾 动物", ["insect", "night_moth", "rabbit", "fox", "deer", "mouse", "bird", "snake", "bee", "frog",
                       "eagle", "owl", "duck", "swan", "sparrow", "parrot", "kingfisher",
                       "wolf", "spider", "magpie", "crow", "woodpecker", "hummingbird",
                       "squirrel", "hedgehog", "bat", "raccoon",
                       "bear", "wild_boar", "badger", "raccoon_dog", "skunk", "opossum", "coati", "armadillo"]),
            ("🐟 水生", ["algae", "seaweed", "plankton", "small_fish", "minnow", "carp", "catfish", "large_fish", "pufferfish",
                       "blackfish", "pike", "shrimp", "crab", "tadpole", "water_strider"])
        ]

        summary = {"🌿 植物": total_plants, "🐾 动物": total_animals, "🐟 水生": total_aquatic}
        for category_name, species_list in categories:
            if content_y > panel_bottom - 32:
                break
            count_label = summary.get(category_name, 0)
            cat_surf = self.font_medium.render(f"{category_name}  {count_label}", True, self.ui["accent_strong"])
            self.screen.blit(cat_surf, (sidebar_x + 18, content_y))
            content_y += 34
            for sp in species_list:
                if content_y > panel_bottom - 20 + scroll:
                    break
                count = species.get(sp, 0)
                if count > 0:
                    emoji = self.creature_emoji.get(sp, "?")
                    label = self._label_species(sp)
                    row_rect = pygame.Rect(sidebar_x + 18, content_y - 2, self.sidebar_width - 36, 26)
                    pygame.draw.rect(self.screen, self.ui["panel_alt"], row_rect, border_radius=8)
                    text = f"{emoji} {label}"
                    text_surf = self.font_small.render(text, True, self.ui["text"])
                    count_surf = self.font_small.render(str(count), True, self.ui["text"])
                    self.screen.blit(text_surf, (row_rect.x + 10, row_rect.y + 5))
                    self.screen.blit(count_surf, (row_rect.right - 34, row_rect.y + 5))
                    bar_width = min(126, max(16, count * 3))
                    bar_color = self.ui["success"] if count > 10 else self.ui["warning"] if count > 5 else self.ui["danger"]
                    pygame.draw.rect(self.screen, bar_color, (row_rect.right - 34 - bar_width, row_rect.bottom - 8, bar_width, 4), border_radius=2)
                    content_y += 30
            content_y += 8
        content_end = content_y - top_y + 16
        self.screen.set_clip(previous_clip)
        self._apply_panel_scroll("species", content_end, viewport)
        self._render_scroll_hint(viewport, "species")
            
    def _render_foodchain_panel(self, sidebar_x):
        """渲染食物链面板"""
        viewport = self._content_viewport(sidebar_x)
        scroll = self.panel_scrolls.get("foodchain", 0)
        previous_clip = self.screen.get_clip()
        self.screen.set_clip(viewport)
        y = 210 - scroll
        title_surf = self.font_large.render("关键食物关系", True, self.ui["accent_strong"])
        self.screen.blit(title_surf, (sidebar_x + 18, y))
        y += 42
        relations = [
            ("狼", "控制", "鹿、兔子"),
            ("狐狸", "捕食", "兔子、昆虫、鼠类"),
            ("黑鱼", "压制", "鲤鱼、小鱼"),
            ("狗鱼", "伏击", "米诺鱼、小鱼、虾"),
            ("老鹰", "猎取", "鸟类、兔子"),
            ("蛇", "捕食", "昆虫、鼠类、蛙类"),
        ]
        for predator, arrow, prey in relations:
            box = pygame.Rect(sidebar_x + 18, y, self.sidebar_width - 36, 58)
            pygame.draw.rect(self.screen, self.ui["panel_alt"], box, border_radius=12)
            pygame.draw.rect(self.screen, self.ui["border"], box, 1, border_radius=12)
            top = self.font_normal.render(f"{predator} {arrow}", True, self.ui["text"])
            bottom = self.font_small.render(prey, True, self.ui["text_dim"])
            self.screen.blit(top, (box.x + 14, box.y + 10))
            self.screen.blit(bottom, (box.x + 14, box.y + 34))
            y += 68
        content_end = y - (210 - scroll) + 16
        self.screen.set_clip(previous_clip)
        self._apply_panel_scroll("foodchain", content_end, viewport)
        self._render_scroll_hint(viewport, "foodchain")
            
    def _render_events_panel(self, sidebar_x):
        """渲染事件面板"""
        viewport = self._content_viewport(sidebar_x)
        scroll = self.panel_scrolls.get("events", 0)
        previous_clip = self.screen.get_clip()
        self.screen.set_clip(viewport)
        y = 210 - scroll
        title_surf = self.font_large.render("最近事件", True, self.ui["accent_strong"])
        self.screen.blit(title_surf, (sidebar_x + 18, y))
        y += 42
        events = self.ecosystem.events[-20:] if hasattr(self.ecosystem, 'events') else []
        for event in events[-15:]:
            tick = getattr(event, 'tick', 0)
            desc = getattr(event, 'description', '未知事件')
            row = pygame.Rect(sidebar_x + 18, y, self.sidebar_width - 36, 44)
            pygame.draw.rect(self.screen, self.ui["panel_alt"], row, border_radius=10)
            tick_surf = self.font_small.render(f"Tick {tick}", True, self.ui["accent_strong"])
            text_surf = self.font_small.render(desc[:24], True, self.ui["text"])
            self.screen.blit(tick_surf, (row.x + 12, row.y + 6))
            self.screen.blit(text_surf, (row.x + 12, row.y + 22))
            y += 50
        content_end = y - (210 - scroll) + 16
        self.screen.set_clip(previous_clip)
        self._apply_panel_scroll("events", content_end, viewport)
        self._render_scroll_hint(viewport, "events")
            
    def _render_settings_panel(self, sidebar_x):
        """渲染设置面板"""
        viewport = self._content_viewport(sidebar_x)
        scroll = self.panel_scrolls.get("settings", 0)
        previous_clip = self.screen.get_clip()
        self.screen.set_clip(viewport)
        y = 210 - scroll
        title_surf = self.font_large.render("运行信息", True, self.ui["accent_strong"])
        self.screen.blit(title_surf, (sidebar_x + 18, y))
        y += 44
        stats = self.ecosystem.get_statistics()
        info_items = [
            f"日期：第 {stats.get('day', 0)} 天",
            f"季节：{self._label_season(stats.get('season', 'spring'))}",
            f"天气：{self._label_weather(stats.get('weather', 'sunny'))}",
            f"模拟帧：{stats.get('tick', 0)}",
            f"缩放：{self.zoom:.1f} 倍",
            f"速度：{self.speed} 倍",
            f"栖位叠层：{'开启' if self.show_microhabitats else '关闭'}",
            "",
            "微栖息地：",
            f"树冠位：{stats.get('microhabitats', {}).get('canopy_roost', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('canopy_roost', {}).get('occupied', 0.0):.1f}",
            f"夜栖位：{stats.get('microhabitats', {}).get('night_roost', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('night_roost', {}).get('occupied', 0.0):.1f}",
            f"灌丛位：{stats.get('microhabitats', {}).get('shrub_shelter', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('shrub_shelter', {}).get('occupied', 0.0):.1f}",
            f"花蜜位：{stats.get('microhabitats', {}).get('nectar_patch', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('nectar_patch', {}).get('occupied', 0.0):.1f}",
            f"湿地位：{stats.get('microhabitats', {}).get('wetland_patch', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('wetland_patch', {}).get('occupied', 0.0):.1f}",
            f"岸栖位：{stats.get('microhabitats', {}).get('riparian_perch', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('riparian_perch', {}).get('occupied', 0.0):.1f}",
            f"夜虫群：{stats.get('microhabitats', {}).get('night_swarm', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('night_swarm', {}).get('occupied', 0.0):.1f}",
            f"树冠食位：{stats.get('microhabitats', {}).get('canopy_forage', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('canopy_forage', {}).get('occupied', 0.0):.1f}",
            f"近岸羽化带：{stats.get('microhabitats', {}).get('shore_hatch', {}).get('count', 0)} / 占用 {stats.get('microhabitats', {}).get('shore_hatch', {}).get('occupied', 0.0):.1f}",
            "",
            "图例：",
            "绿点 树冠/灌丛位",
            "橙点 花蜜位",
            "青点 湿地/岸栖位",
            "褐点 夜虫群/树冠食位",
            "黄绿点 近岸羽化带",
            "外环 表示已占位",
            "",
            "操作说明：",
            "1-9 投放常见物种",
            "空格 暂停或继续",
            "+ / - 调整速度",
            "G 显示或隐藏网格",
            "M 显示或隐藏微栖位",
            "Home 重置视角",
            "滚轮 缩放",
            "右键拖拽 平移视角",
        ]
        for item in info_items:
            color = self.ui["text"] if item else self.ui["text_dim"]
            text_surf = self.font_small.render(item, True, color)
            self.screen.blit(text_surf, (sidebar_x + 15, y))
            y += 22
        content_end = y - (210 - scroll) + 16
        self.screen.set_clip(previous_clip)
        self._apply_panel_scroll("settings", content_end, viewport)
        self._render_scroll_hint(viewport, "settings")
            
    def _render_bottom_bar(self):
        """渲染底部状态栏"""
        bar_rect = pygame.Rect(0, self.window_height - self.bottom_bar_height, 
                               self.window_width, self.bottom_bar_height)
        pygame.draw.rect(self.screen, self.ui["panel"], bar_rect)
        pygame.draw.line(self.screen, self.ui["border"],
                        (0, self.window_height - self.bottom_bar_height),
                        (self.window_width, self.window_height - self.bottom_bar_height), 2)
        
        # 统计信息
        stats = self.ecosystem.get_statistics()
        species = stats.get('species', {})
        
        total_plants = sum(species.get(sp, 0) for sp in ["grass", "bush", "flower", "moss", "tree", "vine", "cactus", "berry", "mushroom", "fern"])
        total_animals = sum(1 for a in self.ecosystem.animals if a.alive)
        total_aquatic = sum(1 for a in self.ecosystem.aquatic_creatures if a.alive)
        
        x = 22
        y = self.window_height - self.bottom_bar_height + 16
        
        # 暂停指示
        if self.paused:
            pause_surf = self.font_medium.render("已暂停", True, self.ui["warning"])
            self.screen.blit(pause_surf, (x, y))
            x += 116

        speed_surf = self.font_normal.render(f"速度 {self.speed} 倍", True, self.ui["text"])
        self.screen.blit(speed_surf, (x, y + 2))
        x += 128

        stat_text = f"植物 {total_plants}    动物 {total_animals}    水生 {total_aquatic}    季节 {self._label_season(stats.get('season', 'spring'))}    天气 {self._label_weather(stats.get('weather', 'sunny'))}"
        stat_surf = self.font_normal.render(stat_text, True, self.ui["text"])
        self.screen.blit(stat_surf, (x, y + 2))
        
        # 小地图
        self._render_minimap()
        
    def _render_minimap(self):
        """渲染小地图"""
        minimap_x = self.window_width - self.sidebar_width - self.minimap_size - 20
        minimap_y = self.window_height - self.bottom_bar_height - self.minimap_size - 10
        pygame.draw.rect(self.screen, self.ui["panel_alt"], (minimap_x - 6, minimap_y - 26, self.minimap_size + 12, self.minimap_size + 32), border_radius=14)
        pygame.draw.rect(self.screen, self.ui["border"], (minimap_x - 6, minimap_y - 26, self.minimap_size + 12, self.minimap_size + 32), 1, border_radius=14)
        title = self.font_small.render("地形缩略图", True, self.ui["text"])
        self.screen.blit(title, (minimap_x + 8, minimap_y - 20))

        scale_x = self.minimap_size / self.world_width
        scale_y = self.minimap_size / self.world_height

        minimap_key = (self.minimap_size, self.world_width, self.world_height)
        if self._minimap_cache_key != minimap_key:
            self._minimap_surface = pygame.Surface((self.minimap_size, self.minimap_size))
            for x in range(0, self.world_width, 5):
                for y in range(0, self.world_height, 5):
                    terrain = self.ecosystem.environment.get_terrain(x, y)
                    color = self.terrain_colors.get(terrain, (100, 100, 100))
                    px = int(x * scale_x)
                    py = int(y * scale_y)
                    pygame.draw.rect(self._minimap_surface, color, (px, py, 3, 3))
            self._minimap_cache_key = minimap_key
        self.screen.blit(self._minimap_surface, (minimap_x, minimap_y))

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
                pygame.draw.line(self.screen, (115, 146, 160),
                               (particle['x'], particle['y']),
                               (particle['x'] - 2, particle['y'] + 10), 2)
            elif particle['type'] == 'snow':
                pygame.draw.circle(self.screen, (247, 246, 240),
                                 (int(particle['x']), int(particle['y'])), 3)
                                 
    def _render_notifications(self):
        """渲染通知消息"""
        y = 10
        
        for message, tick in self.notifications[-self.max_notifications:]:
            alpha = max(0, 255 - (self.tick - tick) * 2)
            
            # 创建带透明度的表面
            text_surf = self.font_normal.render(message, True, (245, 242, 236))
            
            # 背景
            bg_rect = pygame.Rect(10, y, text_surf.get_width() + 20, 25)
            bg_surf = pygame.Surface((bg_rect.width, bg_rect.height), pygame.SRCALPHA)
            pygame.draw.rect(bg_surf, (24, 28, 23, min(210, alpha)), bg_surf.get_rect(), border_radius=10)
            
            self.screen.blit(bg_surf, bg_rect)
            self.screen.blit(text_surf, (20, y + 5))
            
            y += 30

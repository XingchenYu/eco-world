"""v4 世界 UI。"""

from __future__ import annotations

import math

import pygame

from src.sim.world_simulation import WorldSimulation


class WorldRenderer:
    """第一版世界地图式可视化界面。"""

    REGION_LAYOUT = {
        "temperate_forest": (0.20, 0.28),
        "temperate_grassland": (0.42, 0.24),
        "wetland_lake": (0.30, 0.56),
        "rainforest_river": (0.52, 0.58),
        "coastal_shelf": (0.77, 0.50),
        "coral_sea": (0.84, 0.76),
    }

    REGION_THEME = {
        "temperate_forest": ((68, 119, 84), (111, 179, 128)),
        "temperate_grassland": ((169, 148, 77), (217, 192, 108)),
        "wetland_lake": ((74, 129, 142), (122, 196, 188)),
        "rainforest_river": ((58, 133, 112), (96, 211, 164)),
        "coastal_shelf": ((68, 122, 176), (106, 173, 228)),
        "coral_sea": ((171, 112, 170), (255, 167, 178)),
    }

    CLIMATE_LABELS = {
        "temperate": "温带",
        "subtropical": "亚热带",
        "tropical": "热带",
        "equatorial": "赤道",
    }

    def __init__(self, simulation: WorldSimulation):
        pygame.init()
        self.simulation = simulation
        self.window_width = 1560
        self.window_height = 940
        self.sidebar_width = 420
        self.header_height = 96
        self.footer_height = 52
        self.speed = 1
        self.paused = False
        self.animation_tick = 0
        self.region_hitboxes: dict[str, pygame.Rect] = {}
        self.clock = pygame.time.Clock()
        self.screen = pygame.display.set_mode((self.window_width, self.window_height), pygame.RESIZABLE)
        pygame.display.set_caption("EcoWorld v4 - 世界地图")

        self.colors = {
            "bg_top": (26, 32, 43),
            "bg_bottom": (14, 18, 27),
            "panel": (245, 240, 231),
            "panel_soft": (227, 220, 205),
            "panel_dark": (33, 42, 56),
            "ink": (43, 38, 31),
            "ink_soft": (108, 98, 86),
            "line": (83, 95, 111),
            "gold": (198, 160, 86),
            "gold_soft": (226, 199, 138),
            "danger": (196, 96, 94),
            "warning": (211, 153, 65),
            "good": (80, 154, 104),
            "water": (65, 107, 147),
            "shadow": (10, 12, 16),
        }

        self.font_small = pygame.font.SysFont("PingFang SC", 16) or pygame.font.Font(None, 18)
        self.font_normal = pygame.font.SysFont("PingFang SC", 20) or pygame.font.Font(None, 22)
        self.font_medium = pygame.font.SysFont("PingFang SC", 26, bold=True) or pygame.font.Font(None, 28)
        self.font_large = pygame.font.SysFont("PingFang SC", 34, bold=True) or pygame.font.Font(None, 36)
        self.font_title = pygame.font.SysFont("PingFang SC", 42, bold=True) or pygame.font.Font(None, 44)

    def run(self) -> None:
        running = True
        while running:
            running = self._handle_events()
            if not self.paused:
                for _ in range(max(1, self.speed)):
                    self.simulation.update()
            self.animation_tick += 1
            self._draw()
            self.clock.tick(30)
        pygame.quit()

    def _handle_events(self) -> bool:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            if event.type == pygame.VIDEORESIZE:
                self.window_width, self.window_height = event.w, event.h
                self.screen = pygame.display.set_mode((event.w, event.h), pygame.RESIZABLE)
            if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                self._handle_mouse_click(event.pos)
            if event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_ESCAPE, pygame.K_q):
                    return False
                if event.key == pygame.K_SPACE:
                    self.paused = not self.paused
                if event.key in (pygame.K_TAB, pygame.K_RIGHT):
                    self.simulation.cycle_active_region(1)
                if event.key == pygame.K_LEFT:
                    self.simulation.cycle_active_region(-1)
                if event.key in (pygame.K_EQUALS, pygame.K_PLUS, pygame.K_KP_PLUS):
                    self.speed = min(8, self.speed + 1)
                if event.key in (pygame.K_MINUS, pygame.K_KP_MINUS):
                    self.speed = max(1, self.speed - 1)
                if pygame.K_1 <= event.key <= pygame.K_6:
                    index = event.key - pygame.K_1
                    region_ids = self.simulation.list_region_ids()
                    if index < len(region_ids):
                        self.simulation.set_active_region(region_ids[index])
        return True

    def _handle_mouse_click(self, position: tuple[int, int]) -> None:
        for region_id, rect in self.region_hitboxes.items():
            if rect.collidepoint(position):
                self.simulation.set_active_region(region_id)
                return

    def _draw(self) -> None:
        overview = self.simulation.get_world_overview()
        stats = self.simulation.get_statistics()

        self._draw_background()
        self._draw_header(overview)
        self._draw_map_panel(overview)
        self._draw_sidebar(stats)
        self._draw_footer(stats)
        pygame.display.flip()

    def _draw_background(self) -> None:
        for y in range(self.window_height):
            blend = y / max(1, self.window_height - 1)
            color = tuple(
                int(self.colors["bg_top"][i] * (1.0 - blend) + self.colors["bg_bottom"][i] * blend)
                for i in range(3)
            )
            pygame.draw.line(self.screen, color, (0, y), (self.window_width, y))

        for index in range(12):
            radius = 180 + index * 26
            alpha = max(8, 48 - index * 3)
            surface = pygame.Surface((radius * 2, radius * 2), pygame.SRCALPHA)
            pygame.draw.circle(surface, (57, 92, 132, alpha), (radius, radius), radius)
            self.screen.blit(surface, (90 - radius, 120 - radius))

    def _draw_header(self, overview: dict) -> None:
        rect = pygame.Rect(18, 16, self.window_width - 36, self.header_height)
        self._draw_shadowed_panel(rect, self.colors["panel_dark"], border_radius=26, shadow_offset=8)

        title = self.font_title.render("阿瑞利亚生态世界", True, (242, 241, 236))
        subtitle = self.font_normal.render(
            f"世界地图模式  ·  Tick {overview['tick']}  ·  已加载 {overview['loaded_regions']}/{overview['total_regions']} 区域",
            True,
            (191, 202, 212),
        )
        badge = self.font_small.render("v4 世界层", True, self.colors["gold_soft"])
        self.screen.blit(title, (42, 30))
        self.screen.blit(subtitle, (46, 68))
        self.screen.blit(badge, (self.window_width - 148, 34))

    def _draw_map_panel(self, overview: dict) -> None:
        rect = pygame.Rect(
            18,
            128,
            self.window_width - self.sidebar_width - 54,
            self.window_height - self.header_height - self.footer_height - 58,
        )
        self._draw_shadowed_panel(rect, self.colors["panel"], border_radius=30, shadow_offset=10)
        self.region_hitboxes = {}

        title = self.font_large.render("世界地图", True, self.colors["ink"])
        subtitle = self.font_small.render("点击区域切换焦点 · 左右方向键切区", True, self.colors["ink_soft"])
        self.screen.blit(title, (rect.x + 24, rect.y + 20))
        self.screen.blit(subtitle, (rect.x + 28, rect.y + 58))

        map_rect = pygame.Rect(rect.x + 18, rect.y + 96, rect.width - 36, rect.height - 132)
        pygame.draw.rect(self.screen, (229, 236, 240), map_rect, border_radius=26)
        self._draw_map_backdrop(map_rect)
        self._draw_region_connections(map_rect, overview)
        self._draw_region_nodes(map_rect, overview)

    def _draw_map_backdrop(self, rect: pygame.Rect) -> None:
        water = pygame.Surface(rect.size, pygame.SRCALPHA)
        pygame.draw.rect(water, (114, 167, 201, 38), water.get_rect(), border_radius=24)
        for index in range(18):
            wave_y = int(rect.height * (0.12 + index * 0.047))
            amplitude = 8 + (index % 3) * 2
            points = []
            for step in range(0, rect.width + 40, 24):
                offset = int(math.sin((step / 80.0) + index) * amplitude)
                points.append((step, wave_y + offset))
            if len(points) >= 2:
                pygame.draw.lines(water, (109, 162, 193, 34), False, points, 2)
        self.screen.blit(water, rect.topleft)

        land_colors = [
            ((113, 164, 108), pygame.Rect(rect.x + 60, rect.y + 70, 290, 190)),
            ((161, 176, 104), pygame.Rect(rect.x + 280, rect.y + 36, 260, 170)),
            ((91, 156, 142), pygame.Rect(rect.x + 170, rect.y + 250, 230, 160)),
            ((83, 148, 112), pygame.Rect(rect.x + 420, rect.y + 230, 270, 220)),
            ((110, 166, 194), pygame.Rect(rect.x + 660, rect.y + 170, 200, 180)),
            ((204, 154, 171), pygame.Rect(rect.x + 730, rect.y + 360, 170, 130)),
        ]
        for color, land_rect in land_colors:
            surface = pygame.Surface(land_rect.size, pygame.SRCALPHA)
            pygame.draw.ellipse(surface, (*color, 110), surface.get_rect())
            self.screen.blit(surface, land_rect.topleft)

    def _draw_region_connections(self, rect: pygame.Rect, overview: dict) -> None:
        region_lookup = {region["id"]: region for region in overview["regions"]}
        for region in overview["regions"]:
            region_obj = self.simulation.world_map.get_region(region["id"])
            if region_obj is None:
                continue
            start = self._region_screen_position(rect, region["id"])
            for connector in region_obj.connectors:
                if connector.target_region_id not in region_lookup:
                    continue
                end = self._region_screen_position(rect, connector.target_region_id)
                is_active_path = region["active"] or connector.target_region_id == overview["active_region_id"]
                color = self.colors["gold"] if is_active_path else (111, 131, 150)
                width = 4 if is_active_path else 2
                mid_x = (start[0] + end[0]) // 2
                curve = [
                    start,
                    (mid_x, start[1] - 24),
                    (mid_x, end[1] + 24),
                    end,
                ]
                pygame.draw.lines(self.screen, color, False, curve, width)

    def _draw_region_nodes(self, rect: pygame.Rect, overview: dict) -> None:
        for region in overview["regions"]:
            center = self._region_screen_position(rect, region["id"])
            theme = self.REGION_THEME.get(region["id"], ((92, 124, 148), (142, 177, 196)))
            self._draw_region_node(rect, center, region, theme)

    def _draw_region_node(
        self,
        map_rect: pygame.Rect,
        center: tuple[int, int],
        region: dict,
        theme: tuple[tuple[int, int, int], tuple[int, int, int]],
    ) -> None:
        pulse = math.sin(self.animation_tick / 18.0) * 0.5 + 0.5
        width = 200 if region["active"] else 176
        height = 108 if region["active"] else 96
        rect = pygame.Rect(0, 0, width, height)
        rect.center = center
        rect.clamp_ip(map_rect.inflate(-40, -40))
        self.region_hitboxes[region["id"]] = rect

        glow_radius = 88 if region["active"] else 64
        glow_surface = pygame.Surface((glow_radius * 2, glow_radius * 2), pygame.SRCALPHA)
        glow_alpha = 90 if region["active"] else 42
        pygame.draw.circle(glow_surface, (*theme[1], glow_alpha + int(20 * pulse)), (glow_radius, glow_radius), glow_radius)
        self.screen.blit(glow_surface, (rect.centerx - glow_radius, rect.centery - glow_radius))

        self._draw_gradient_capsule(rect, theme[0], theme[1], active=region["active"])

        title = self.font_medium.render(region["name"], True, (249, 248, 244))
        climate = self.CLIMATE_LABELS.get(region["climate_zone"], region["climate_zone"])
        meta = self.font_small.render(
            f"{climate} · 繁荣 {region['prosperity']:.2f} · 风险 {region['collapse_risk']:.2f}",
            True,
            (232, 237, 240),
        )
        pressure = region["top_pressures"][0][0] if region["top_pressures"] else "暂无主压"
        pressure_text = self.font_small.render(f"主导压力：{pressure}", True, (226, 214, 186))

        self.screen.blit(title, (rect.x + 16, rect.y + 14))
        self.screen.blit(meta, (rect.x + 16, rect.y + 48))
        self.screen.blit(pressure_text, (rect.x + 16, rect.y + 72))

        badge_rect = pygame.Rect(rect.right - 54, rect.y + 16, 36, 36)
        pygame.draw.circle(self.screen, (249, 243, 219), badge_rect.center, 18)
        number = self.simulation.list_region_ids().index(region["id"]) + 1
        badge = self.font_small.render(str(number), True, self.colors["ink"])
        badge_pos = badge.get_rect(center=badge_rect.center)
        self.screen.blit(badge, badge_pos)

    def _draw_sidebar(self, stats: dict) -> None:
        rect = pygame.Rect(
            self.window_width - self.sidebar_width - 18,
            128,
            self.sidebar_width,
            self.window_height - self.header_height - self.footer_height - 58,
        )
        self._draw_shadowed_panel(rect, self.colors["panel"], border_radius=30, shadow_offset=10)

        active = stats["active_region"]
        top = rect.y + 22
        title = self.font_large.render(active["name"], True, self.colors["ink"])
        sub = self.font_small.render(
            f"{self.CLIMATE_LABELS.get(active['climate_zone'], active['climate_zone'])}生态区 · 焦点区域",
            True,
            self.colors["ink_soft"],
        )
        self.screen.blit(title, (rect.x + 22, top))
        self.screen.blit(sub, (rect.x + 24, top + 40))
        top += 82

        top = self._draw_status_card(rect, top, active)
        top = self._draw_metric_list(rect, top, "生态链重点", self._collect_chain_highlights(stats), max_items=5)
        top = self._draw_metric_bars(rect, top, "关键资源", active["resource_state"], max_items=4, positive=True)
        top = self._draw_metric_bars(rect, top, "风险压力", active["ecological_pressures"], max_items=4, positive=False)
        top = self._draw_metric_bars(rect, top, "社会相位", stats["social_trends"]["phase_scores"], max_items=4, positive=True)
        self._draw_story_panel(rect, top, stats)

    def _draw_status_card(self, rect: pygame.Rect, top: int, active: dict) -> int:
        card = pygame.Rect(rect.x + 18, top, rect.width - 36, 156)
        pygame.draw.rect(self.screen, self.colors["panel_soft"], card, border_radius=22)
        pygame.draw.rect(self.screen, (190, 176, 152), card, width=1, border_radius=22)

        self._draw_bar(card.x + 18, card.y + 28, card.width - 36, "多样性", float(active["health_state"].get("biodiversity", 0.0)), (72, 145, 92))
        self._draw_bar(card.x + 18, card.y + 60, card.width - 36, "韧性", float(active["health_state"].get("resilience", 0.0)), (86, 131, 173))
        self._draw_bar(card.x + 18, card.y + 92, card.width - 36, "繁荣度", float(active["health_state"].get("prosperity", 0.0)), self.colors["gold"])
        self._draw_bar(card.x + 18, card.y + 124, card.width - 36, "衰退风险", float(active["health_state"].get("collapse_risk", 0.0)), self.colors["danger"])
        return card.bottom + 18

    def _draw_metric_list(self, rect: pygame.Rect, top: int, title: str, items: list[str], max_items: int) -> int:
        section_title = self.font_medium.render(title, True, self.colors["ink"])
        self.screen.blit(section_title, (rect.x + 20, top))
        top += 32
        for line in items[:max_items]:
            bullet = self.font_small.render(f"● {line}", True, self.colors["ink_soft"])
            self.screen.blit(bullet, (rect.x + 24, top))
            top += 20
        return top + 10

    def _draw_metric_bars(
        self,
        rect: pygame.Rect,
        top: int,
        title: str,
        mapping: dict,
        max_items: int,
        positive: bool,
    ) -> int:
        section_title = self.font_medium.render(title, True, self.colors["ink"])
        self.screen.blit(section_title, (rect.x + 20, top))
        top += 32
        items = sorted(mapping.items(), key=lambda item: item[1], reverse=True)[:max_items]
        if not items:
            empty = self.font_small.render("无数据", True, self.colors["ink_soft"])
            self.screen.blit(empty, (rect.x + 24, top))
            return top + 30
        for key, value in items:
            color = self.colors["good"] if positive else self.colors["danger"]
            self._draw_bar(rect.x + 20, top, rect.width - 40, key, float(value), color)
            top += 32
        return top + 8

    def _draw_story_panel(self, rect: pygame.Rect, top: int, stats: dict) -> None:
        card = pygame.Rect(rect.x + 18, top, rect.width - 36, max(120, rect.bottom - top - 18))
        pygame.draw.rect(self.screen, self.colors["panel_soft"], card, border_radius=22)
        pygame.draw.rect(self.screen, (190, 176, 152), card, width=1, border_radius=22)

        title = self.font_medium.render("区域播报", True, self.colors["ink"])
        self.screen.blit(title, (card.x + 16, card.y + 16))

        lines = (
            stats["territory"]["narrative_territory"][:1]
            + stats["social_trends"]["narrative_trends"][:2]
            + stats["grassland_chain"]["narrative_chain"][:1]
            + stats["carrion_chain"]["narrative_chain"][:1]
            + stats["wetland_chain"]["narrative_chain"][:1]
        )
        if not lines:
            lines = ["当前区域暂无叙事摘要。"]

        y = card.y + 52
        for line in lines[:5]:
            rendered = self.font_small.render(line[:48], True, self.colors["ink_soft"])
            self.screen.blit(rendered, (card.x + 18, y))
            y += 22

    def _draw_footer(self, stats: dict) -> None:
        rect = pygame.Rect(18, self.window_height - self.footer_height - 10, self.window_width - 36, self.footer_height)
        self._draw_shadowed_panel(rect, self.colors["panel_dark"], border_radius=22, shadow_offset=6)
        chain_hint = self._best_chain_hint(stats)
        text = (
            f"Space 暂停/继续   鼠标点击区域切换   1-6 直选   左右键切区   +/- 速度 {self.speed}x   "
            f"{'已暂停' if self.paused else '模拟运行中'}   当前主线：{chain_hint}"
        )
        rendered = self.font_small.render(text, True, (208, 216, 223))
        self.screen.blit(rendered, (34, rect.y + 16))

    def _draw_bar(self, x: int, y: int, width: int, label: str, value: float, color: tuple[int, int, int]) -> None:
        safe_value = max(0.0, min(1.0, value))
        label_surface = self.font_small.render(f"{label}  {value:.2f}", True, self.colors["ink"])
        self.screen.blit(label_surface, (x, y))
        bar_rect = pygame.Rect(x, y + 16, width, 10)
        fill_rect = pygame.Rect(x, y + 16, int(width * safe_value), 10)
        pygame.draw.rect(self.screen, (209, 202, 191), bar_rect, border_radius=5)
        pygame.draw.rect(self.screen, color, fill_rect, border_radius=5)

    def _draw_shadowed_panel(self, rect: pygame.Rect, color: tuple[int, int, int], border_radius: int, shadow_offset: int) -> None:
        shadow = pygame.Surface((rect.width, rect.height), pygame.SRCALPHA)
        pygame.draw.rect(shadow, (*self.colors["shadow"], 110), shadow.get_rect(), border_radius=border_radius)
        self.screen.blit(shadow, (rect.x + shadow_offset, rect.y + shadow_offset))
        pygame.draw.rect(self.screen, color, rect, border_radius=border_radius)

    def _draw_gradient_capsule(
        self,
        rect: pygame.Rect,
        start: tuple[int, int, int],
        end: tuple[int, int, int],
        active: bool,
    ) -> None:
        surface = pygame.Surface(rect.size, pygame.SRCALPHA)
        for y in range(rect.height):
            blend = y / max(1, rect.height - 1)
            color = tuple(int(start[i] * (1.0 - blend) + end[i] * blend) for i in range(3))
            pygame.draw.line(surface, color, (0, y), (rect.width, y))
        pygame.draw.rect(surface, (255, 255, 255, 24 if active else 10), surface.get_rect(), width=2, border_radius=24)
        self.screen.blit(surface, rect.topleft)

    def _region_screen_position(self, map_rect: pygame.Rect, region_id: str) -> tuple[int, int]:
        rel_x, rel_y = self.REGION_LAYOUT.get(region_id, (0.5, 0.5))
        return (
            int(map_rect.x + map_rect.width * rel_x),
            int(map_rect.y + map_rect.height * rel_y),
        )

    def _collect_chain_highlights(self, stats: dict) -> list[str]:
        highlights: list[str] = []
        highlights.extend(self._top_keys(stats["grassland_chain"]["trophic_scores"], "草原链"))
        highlights.extend(self._top_keys(stats["carrion_chain"]["resource_scores"], "尸体资源链"))
        highlights.extend(self._top_keys(stats["wetland_chain"]["trophic_scores"], "湿地链"))
        highlights.extend(self._top_keys(stats["social_trends"]["phase_scores"], "社会相位"))
        return highlights

    def _top_keys(self, mapping: dict, prefix: str) -> list[str]:
        items = sorted(mapping.items(), key=lambda item: item[1], reverse=True)[:2]
        return [f"{prefix}：{key} {value:.2f}" for key, value in items if value > 0.0]

    def _best_chain_hint(self, stats: dict) -> str:
        candidates = []
        for label, mapping in (
            ("社会趋势", stats["social_trends"]["phase_scores"]),
            ("草原链", stats["grassland_chain"]["trophic_scores"]),
            ("尸体资源链", stats["carrion_chain"]["resource_scores"]),
            ("湿地链", stats["wetland_chain"]["trophic_scores"]),
        ):
            if not mapping:
                continue
            key, value = max(mapping.items(), key=lambda item: item[1])
            candidates.append((value, f"{label} / {key}"))
        if not candidates:
            return "暂无主导链路"
        return max(candidates, key=lambda item: item[0])[1]

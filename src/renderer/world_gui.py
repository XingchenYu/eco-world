"""v4 世界 UI。"""

from __future__ import annotations

import pygame

from src.sim.world_simulation import WorldSimulation


class WorldRenderer:
    """第一版世界层可视化界面。"""

    def __init__(self, simulation: WorldSimulation):
        pygame.init()
        self.simulation = simulation
        self.window_width = 1520
        self.window_height = 920
        self.sidebar_width = 430
        self.header_height = 84
        self.footer_height = 40
        self.card_gap = 18
        self.speed = 1
        self.paused = False
        self.clock = pygame.time.Clock()
        self.screen = pygame.display.set_mode((self.window_width, self.window_height), pygame.RESIZABLE)
        pygame.display.set_caption("EcoWorld v4 - 世界模拟面板")

        self.colors = {
            "bg": (18, 22, 26),
            "panel": (28, 35, 42),
            "panel_alt": (37, 46, 56),
            "card": (34, 44, 54),
            "card_active": (52, 79, 70),
            "border": (85, 103, 117),
            "text": (228, 236, 240),
            "muted": (153, 168, 178),
            "danger": (212, 110, 100),
            "warning": (223, 180, 88),
        }

        self.font_small = pygame.font.SysFont("PingFang SC", 16) or pygame.font.Font(None, 18)
        self.font_normal = pygame.font.SysFont("PingFang SC", 20) or pygame.font.Font(None, 22)
        self.font_medium = pygame.font.SysFont("PingFang SC", 24, bold=True) or pygame.font.Font(None, 26)
        self.font_title = pygame.font.SysFont("PingFang SC", 34, bold=True) or pygame.font.Font(None, 36)

    def run(self) -> None:
        running = True
        while running:
            running = self._handle_events()
            if not self.paused:
                for _ in range(max(1, self.speed)):
                    self.simulation.update()
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

    def _draw(self) -> None:
        self.screen.fill(self.colors["bg"])
        overview = self.simulation.get_world_overview()
        stats = self.simulation.get_statistics()

        self._draw_header(overview)
        self._draw_world_cards(overview)
        self._draw_sidebar(stats)
        self._draw_footer()
        pygame.display.flip()

    def _draw_header(self, overview: dict) -> None:
        header_rect = pygame.Rect(0, 0, self.window_width, self.header_height)
        pygame.draw.rect(self.screen, self.colors["panel"], header_rect)

        title = self.font_title.render("EcoWorld v4 世界总览", True, self.colors["text"])
        subtitle = self.font_normal.render(
            f"{overview['world_name']}  Tick {overview['tick']}  已加载 {overview['loaded_regions']}/{overview['total_regions']} 区域",
            True,
            self.colors["muted"],
        )
        self.screen.blit(title, (24, 16))
        self.screen.blit(subtitle, (28, 52))

    def _draw_world_cards(self, overview: dict) -> None:
        area = pygame.Rect(
            20,
            self.header_height + 16,
            self.window_width - self.sidebar_width - 50,
            self.window_height - self.header_height - self.footer_height - 36,
        )
        pygame.draw.rect(self.screen, self.colors["panel_alt"], area, border_radius=14)

        title = self.font_medium.render("区域地图 / Region Map", True, self.colors["text"])
        self.screen.blit(title, (area.x + 18, area.y + 14))

        cards = overview["regions"]
        columns = 2
        rows = max(1, (len(cards) + columns - 1) // columns)
        card_width = (area.width - self.card_gap * (columns + 1)) // columns
        card_height = max(145, (area.height - 56 - self.card_gap * (rows + 1)) // rows)

        for index, region in enumerate(cards):
            row = index // columns
            col = index % columns
            x = area.x + self.card_gap + col * (card_width + self.card_gap)
            y = area.y + 48 + self.card_gap + row * (card_height + self.card_gap)
            self._draw_region_card(pygame.Rect(x, y, card_width, card_height), region)

    def _draw_region_card(self, rect: pygame.Rect, region: dict) -> None:
        fill = self.colors["card_active"] if region["active"] else self.colors["card"]
        pygame.draw.rect(self.screen, fill, rect, border_radius=14)
        pygame.draw.rect(self.screen, self.colors["border"], rect, width=1, border_radius=14)

        title = self.font_medium.render(region["name"], True, self.colors["text"])
        meta = self.font_small.render(
            f"{region['id']} | {region['climate_zone']} | 种群 {region['species_population']}",
            True,
            self.colors["muted"],
        )
        biomes = self.font_small.render(" / ".join(region["dominant_biomes"][:3]), True, self.colors["muted"])
        health_line = self.font_small.render(
            f"多样性 {region['biodiversity']:.2f}  韧性 {region['resilience']:.2f}  繁荣 {region['prosperity']:.2f}",
            True,
            self.colors["text"],
        )
        risk_line = self.font_small.render(
            f"衰退风险 {region['collapse_risk']:.2f}  连接 {region['connector_count']}  已加载 {'是' if region['loaded'] else '否'}",
            True,
            self.colors["text"],
        )
        self.screen.blit(title, (rect.x + 16, rect.y + 12))
        self.screen.blit(meta, (rect.x + 16, rect.y + 42))
        self.screen.blit(biomes, (rect.x + 16, rect.y + 64))
        self.screen.blit(health_line, (rect.x + 16, rect.y + 96))
        self.screen.blit(risk_line, (rect.x + 16, rect.y + 118))

        pressure_y = rect.y + 144
        for key, value in region["top_pressures"][:3]:
            line = self.font_small.render(f"{key}: {value:.2f}", True, self.colors["warning"])
            self.screen.blit(line, (rect.x + 16, pressure_y))
            pressure_y += 18

    def _draw_sidebar(self, stats: dict) -> None:
        rect = pygame.Rect(
            self.window_width - self.sidebar_width,
            self.header_height,
            self.sidebar_width,
            self.window_height - self.header_height - self.footer_height,
        )
        pygame.draw.rect(self.screen, self.colors["panel"], rect)

        active = stats["active_region"]
        top = rect.y + 18
        self._draw_sidebar_title(rect.x + 18, top, f"焦点区域: {active['name']}")
        top += 36

        top = self._draw_kv_block(rect, top, "健康 / Health", active["health_state"], 5)
        top = self._draw_kv_block(rect, top, "资源 / Resources", active["resource_state"], 5)
        top = self._draw_kv_block(rect, top, "压力 / Pressures", active["ecological_pressures"], 6)
        top = self._draw_kv_block(rect, top, "社会趋势 / Social", stats["social_trends"]["phase_scores"], 4)

        if stats["grassland_chain"]["trophic_scores"]:
            top = self._draw_kv_block(rect, top, "草原链 / Grassland", stats["grassland_chain"]["trophic_scores"], 4)
        if stats["carrion_chain"]["resource_scores"]:
            top = self._draw_kv_block(rect, top, "尸体资源链 / Carrion", stats["carrion_chain"]["resource_scores"], 4)
        if stats["wetland_chain"]["trophic_scores"]:
            top = self._draw_kv_block(rect, top, "湿地链 / Wetland", stats["wetland_chain"]["trophic_scores"], 4)

        narratives = (
            stats["territory"]["narrative_territory"][:1]
            + stats["social_trends"]["narrative_trends"][:2]
            + stats["grassland_chain"]["narrative_chain"][:1]
            + stats["carrion_chain"]["narrative_chain"][:1]
        )
        self._draw_text_block(rect, top, "叙事摘要 / Narrative", narratives[:4])

    def _draw_sidebar_title(self, x: int, y: int, text: str) -> None:
        title = self.font_medium.render(text, True, self.colors["text"])
        self.screen.blit(title, (x, y))

    def _draw_kv_block(self, rect: pygame.Rect, top: int, title: str, mapping: dict, limit: int) -> int:
        if top > rect.bottom - 120:
            return top
        self._draw_sidebar_title(rect.x + 18, top, title)
        top += 28
        items = sorted(mapping.items(), key=lambda item: item[1], reverse=True)[:limit]
        if not items:
            empty = self.font_small.render("无数据", True, self.colors["muted"])
            self.screen.blit(empty, (rect.x + 22, top))
            return top + 26
        for key, value in items:
            color = self.colors["danger"] if "risk" in key or "collapse" in key else self.colors["text"]
            line = self.font_small.render(f"{key}: {float(value):.2f}", True, color)
            self.screen.blit(line, (rect.x + 22, top))
            top += 19
        return top + 10

    def _draw_text_block(self, rect: pygame.Rect, top: int, title: str, lines: list[str]) -> None:
        if top > rect.bottom - 120 or not lines:
            return
        self._draw_sidebar_title(rect.x + 18, top, title)
        top += 28
        for line in lines:
            rendered = self.font_small.render(line[:52], True, self.colors["muted"])
            self.screen.blit(rendered, (rect.x + 22, top))
            top += 19

    def _draw_footer(self) -> None:
        rect = pygame.Rect(0, self.window_height - self.footer_height, self.window_width, self.footer_height)
        pygame.draw.rect(self.screen, self.colors["panel"], rect)
        text = (
            f"Space 暂停/继续  Left/Right/Tab 切区  1-6 直选区域  +/- 速度 {self.speed}x  "
            f"{'已暂停' if self.paused else '运行中'}"
        )
        rendered = self.font_small.render(text, True, self.colors["muted"])
        self.screen.blit(rendered, (18, rect.y + 11))

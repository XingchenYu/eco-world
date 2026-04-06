"""
生态平衡监测系统 - 蝴蝶效应核心（扩展版）
"""

from typing import Dict, List, Optional
from dataclasses import dataclass
from collections import deque


@dataclass
class CausalEvent:
    """因果事件链"""
    tick: int
    cause: str
    effect: str
    impact: float
    chain_id: str
    
    def __str__(self):
        return f"[T{self.tick}] {self.cause} → {self.effect} (影响: {self.impact:+.2f})"


@dataclass
class SpeciesState:
    """物种状态快照"""
    name: str
    count: int
    trend: float
    health_ratio: float
    
    @property
    def health_status(self) -> str:
        if self.health_ratio < 0.2:
            return "critical"
        elif self.health_ratio < 0.5:
            return "warning"
        elif self.health_ratio < 0.8:
            return "stable"
        else:
            return "healthy"


@dataclass
class Alert:
    """生态警告"""
    level: str
    message: str
    tick: int
    species: Optional[str] = None
    recommendation: str = ""
    
    def __str__(self):
        icon = {"info": "ℹ️", "warning": "⚠️", "critical": "🔴", "emergency": "🚨"}.get(self.level, "❓")
        return f"{icon} {self.message}"


class EcoBalance:
    """生态平衡监测器 - 扩展物种"""

    LAND_FOUNDATION = ["grass", "bush", "flower", "moss", "tree", "vine", "fern"]
    FRUIT_PLANTS = ["berry", "apple_tree", "cherry_tree", "grape_vine", "strawberry", "blueberry", "orange_tree", "watermelon"]
    POLLINATORS = ["bee", "hummingbird", "butterfly"]
    LAND_HERBIVORES = ["insect", "rabbit", "deer", "mouse", "squirrel", "duck", "swan", "sparrow", "parrot", "hedgehog"]
    LAND_PREDATORS = ["fox", "wolf", "snake", "spider", "eagle", "owl", "kingfisher", "crow", "magpie", "woodpecker", "bat", "bear", "badger", "raccoon", "raccoon_dog", "skunk", "opossum", "coati", "armadillo"]
    AQUATIC_PRODUCERS = ["algae", "seaweed", "plankton"]
    AQUATIC_CONSUMERS = ["small_fish", "minnow", "carp", "shrimp", "tadpole", "water_strider", "pufferfish"]
    AQUATIC_PREDATORS = ["catfish", "large_fish", "blackfish", "pike", "crab"]
    FOOD_CHAIN = {
        "rabbit": {"eats": ["grass", "flower", "bush", "moss"], "eaten_by": ["fox", "wolf", "snake", "eagle"]},
        "mouse": {"eats": ["grass", "flower", "moss", "berry"], "eaten_by": ["fox", "snake", "owl", "bird"]},
        "deer": {"eats": ["grass", "bush", "moss", "fern"], "eaten_by": ["wolf"]},
        "insect": {"eats": ["grass", "flower"], "eaten_by": ["bird", "spider", "frog", "fox"]},
        "small_fish": {"eats": ["plankton"], "eaten_by": ["catfish", "large_fish", "blackfish", "pike", "kingfisher", "crab"]},
        "minnow": {"eats": ["plankton", "algae", "water_strider"], "eaten_by": ["catfish", "large_fish", "blackfish", "pike", "kingfisher", "crab"]},
        "carp": {"eats": ["plankton", "algae"], "eaten_by": ["blackfish", "large_fish", "pike"]},
        "shrimp": {"eats": ["algae", "plankton", "seaweed"], "eaten_by": ["catfish", "large_fish", "crab", "kingfisher", "pike"]},
    }
    EMOJIS = {
        "grass": "🌿", "bush": "🌳", "flower": "🌸", "moss": "🍀", "tree": "🌲", "berry": "🫐",
        "rabbit": "🐰", "deer": "🦌", "mouse": "🐭", "insect": "🐛", "bee": "🐝", "fox": "🦊",
        "wolf": "🐺", "snake": "🐍", "bird": "🐦", "eagle": "🦅", "owl": "🦉",
        "algae": "🌿", "plankton": "🔬", "small_fish": "🐟", "minnow": "🐠", "carp": "🐟", "shrimp": "🦐",
        "catfish": "🐟", "large_fish": "🐠", "blackfish": "🐟", "pike": "🐟",
    }
    
    def __init__(self, ecosystem_width: int, ecosystem_height: int):
        self.width = ecosystem_width
        self.height = ecosystem_height
        self.max_grass = ecosystem_width * ecosystem_height * 0.3
        self.land_capacity = ecosystem_width * ecosystem_height
        self.water_capacity = max(1, int(self.land_capacity * 0.25))
        
        self.history: Dict[str, deque] = {}
        self.causal_chain: List[CausalEvent] = []
        self.chain_counter = 0
        
        self.active_alerts: List[Alert] = []
        self.alert_history: List[Alert] = []
        
        self.grass_protection_factor = 1.0
        
    def record_snapshot(self, stats: Dict):
        for species, count in stats.get("species", {}).items():
            self.history.setdefault(species, deque(maxlen=100)).append(count)
                
    def calculate_trend(self, species: str, window: int = 20) -> float:
        history = list(self.history.get(species, []))
        if len(history) < 2:
            return 0.0
            
        recent = history[-window:] if len(history) >= window else history
        if len(recent) < 2:
            return 0.0
            
        n = len(recent)
        x_sum = n * (n - 1) / 2
        y_sum = sum(recent)
        xy_sum = sum(i * v for i, v in enumerate(recent))
        x2_sum = sum(i * i for i in range(n))
        
        denominator = n * x2_sum - x_sum * x_sum
        if denominator == 0:
            return 0.0
            
        slope = (n * xy_sum - x_sum * y_sum) / denominator
        
        if len(recent) > 0 and recent[0] > 0:
            return max(-1, min(1, slope / recent[0] * 10))
        return 0.0
        
    def get_species_state(self, stats: Dict) -> Dict[str, SpeciesState]:
        states = {}
        species_counts = stats.get("species", {})
        for species, count in species_counts.items():
            trend = self.calculate_trend(species)
            baseline = max(1, self._soft_target_for_species(species, species_counts))
            health_ratio = count / baseline
            states[species] = SpeciesState(
                name=species,
                count=count,
                trend=trend,
                health_ratio=health_ratio
            )
        return states
    
    def _soft_target_for_species(self, species: str, counts: Dict[str, int]) -> int:
        if species in self.LAND_FOUNDATION:
            return max(4, int(self.land_capacity * 0.015))
        if species in self.FRUIT_PLANTS:
            return max(2, int(self.land_capacity * 0.006))
        if species in self.POLLINATORS:
            return max(3, int(self.land_capacity * 0.004))
        if species in self.LAND_HERBIVORES:
            return max(2, int(sum(counts.get(sp, 0) for sp in self.LAND_FOUNDATION) * 0.12))
        if species in self.LAND_PREDATORS:
            prey_total = sum(counts.get(sp, 0) for sp in self.LAND_HERBIVORES)
            return max(1, int(prey_total * 0.18))
        if species in self.AQUATIC_PRODUCERS:
            return max(5, int(self.water_capacity * 0.35))
        if species in self.AQUATIC_CONSUMERS:
            producer_total = sum(counts.get(sp, 0) for sp in self.AQUATIC_PRODUCERS)
            return max(2, int(producer_total * 0.2))
        if species in self.AQUATIC_PREDATORS:
            consumer_total = sum(counts.get(sp, 0) for sp in self.AQUATIC_CONSUMERS)
            return max(1, int(consumer_total * 0.12))
        return max(1, int(self.land_capacity * 0.003))
    
    def _sum_group(self, counts: Dict[str, int], species_list: List[str]) -> int:
        return sum(counts.get(species, 0) for species in species_list)
    
    def _group_health(self, counts: Dict[str, int], current: int, target: int) -> float:
        if target <= 0:
            return 1.0
        return max(0.0, min(1.0, current / target))
        
    def check_balance(self, stats: Dict) -> List[Alert]:
        alerts = []
        counts = stats.get("species", {})
        tick = stats.get("tick", 0)
        states = self.get_species_state(stats)

        land_foundation = self._sum_group(counts, self.LAND_FOUNDATION)
        fruit_plants = self._sum_group(counts, self.FRUIT_PLANTS)
        pollinators = self._sum_group(counts, [sp for sp in self.POLLINATORS if sp in counts])
        land_herbivores = self._sum_group(counts, self.LAND_HERBIVORES)
        land_predators = self._sum_group(counts, self.LAND_PREDATORS)
        aquatic_producers = self._sum_group(counts, self.AQUATIC_PRODUCERS)
        aquatic_consumers = self._sum_group(counts, self.AQUATIC_CONSUMERS)
        aquatic_predators = self._sum_group(counts, self.AQUATIC_PREDATORS)

        min_land_foundation = max(20, int(self.land_capacity * 0.08))
        if land_foundation < min_land_foundation:
            self.grass_protection_factor = max(0.3, land_foundation / max(1, min_land_foundation))
            alerts.append(Alert(
                level="critical",
                message=f"🌿 陆地基础生产者过少 ({land_foundation} < {min_land_foundation})",
                tick=tick,
                species="grass",
                recommendation="增加植物，或降低食草动物压力"
            ))
        else:
            self.grass_protection_factor = min(1.0, self.grass_protection_factor + 0.01)

        if pollinators < max(3, fruit_plants // 6):
            alerts.append(Alert(
                level="warning",
                message=f"🐝 授粉者偏少，果类植物扩张会受限",
                tick=tick,
                species="bee",
                recommendation="补充蜜蜂或蜂鸟"
            ))

        if land_herbivores > max(10, int(land_foundation * 0.45)):
            alerts.append(Alert(
                level="warning",
                message="🐇 食草压力偏高，陆地植物可能被快速消耗",
                tick=tick,
                species="rabbit",
                recommendation="增加捕食者或补充植物"
            ))
        elif land_herbivores < max(4, int(land_foundation * 0.05)):
            alerts.append(Alert(
                level="info",
                message="🐇 食草动物偏少，陆地食物链中层较弱",
                tick=tick,
                species="rabbit",
                recommendation="适量补充兔子、鹿或鼠类"
            ))

        if land_predators > max(4, int(land_herbivores * 0.7)):
            alerts.append(Alert(
                level="warning",
                message="🦊 陆地捕食者偏多，可能压垮中层猎物",
                tick=tick,
                species="fox",
                recommendation="减少捕食者或补充猎物"
            ))

        min_aquatic_producers = max(10, int(self.water_capacity * 0.18))
        if aquatic_producers < min_aquatic_producers:
            alerts.append(Alert(
                level="critical",
                message="🌊 水生基础生产者过少，水域食物链脆弱",
                tick=tick,
                species="algae",
                recommendation="补充藻类、水草或浮游生物"
            ))
        if aquatic_consumers > max(8, int(aquatic_producers * 1.6)):
            alerts.append(Alert(
                level="warning",
                message="🐟 水生消费者增长过快，生产者恢复会跟不上",
                tick=tick,
                species="small_fish",
                recommendation="增加水生捕食者或降低基础繁殖率"
            ))
        if aquatic_predators > max(4, int(aquatic_consumers * 0.45)):
            alerts.append(Alert(
                level="warning",
                message="🦈 水生捕食压力过高，中层鱼虾可能被快速清空",
                tick=tick,
                species="blackfish",
                recommendation="减少黑鱼/狗鱼/大鱼，或补充中层物种"
            ))

        for anchor in ["grass", "rabbit", "fox", "bee", "algae", "small_fish", "carp"]:
            state = states.get(anchor)
            if not state:
                continue
            min_pop = max(1, int(self._soft_target_for_species(anchor, counts) * 0.15))
            if state.count < min_pop:
                level = "emergency" if state.count == 0 else "critical"
                alerts.append(Alert(
                    level=level,
                    message=f"{self.get_emoji(anchor)} {anchor.upper()} 数量过低！({state.count} < {min_pop})",
                    tick=tick,
                    species=anchor,
                    recommendation=f"建议补充 {anchor}"
                ))
            elif state.trend < -0.35 and state.count < min_pop * 2:
                alerts.append(Alert(
                    level="warning",
                    message=f"{self.get_emoji(anchor)} {anchor} 正在快速减少 (趋势: {state.trend:.1%})",
                    tick=tick,
                    species=anchor,
                    recommendation=f"注意观察 {anchor}"
                ))

        self.active_alerts = alerts
        self.alert_history.extend(alerts)
        
        if len(self.alert_history) > 100:
            self.alert_history = self.alert_history[-100:]
            
        return alerts
        
    def record_causal_event(self, cause: str, effect: str, impact: float, tick: int):
        self.chain_counter += 1
        event = CausalEvent(
            tick=tick,
            cause=cause,
            effect=effect,
            impact=impact,
            chain_id=f"chain_{self.chain_counter}"
        )
        self.causal_chain.append(event)
        
        if len(self.causal_chain) > 50:
            self.causal_chain = self.causal_chain[-50:]
            
        return event
        
    def analyze_cascade(self, species: str, new_count: int, old_count: int, tick: int) -> List[CausalEvent]:
        events = []
        delta = new_count - old_count
        
        if delta == 0:
            return events
            
        if species in self.FOOD_CHAIN:
            chain_info = self.FOOD_CHAIN[species]
            
            if delta > 0 and chain_info.get("eaten_by"):
                for prey in chain_info.get("eats", []):
                    impact = -delta * 0.3
                    event = self.record_causal_event(
                        cause=f"{species}+{delta}",
                        effect=f"{prey}可能减少",
                        impact=impact,
                        tick=tick
                    )
                    events.append(event)
                    
            elif delta < 0 and chain_info.get("eaten_by"):
                for predator in chain_info["eaten_by"]:
                    impact = delta * 0.5
                    event = self.record_causal_event(
                        cause=f"{species}{delta}",
                        effect=f"{predator}可能减少",
                        impact=impact,
                        tick=tick
                    )
                    events.append(event)
                    
        return events
        
    def get_butterfly_events(self, limit: int = 10) -> List[CausalEvent]:
        significant = [e for e in self.causal_chain if abs(e.impact) > 0.1]
        return significant[-limit:]
        
    def get_ecosystem_health(self, stats: Dict) -> float:
        counts = stats.get("species", {})
        land_foundation = self._sum_group(counts, self.LAND_FOUNDATION)
        fruit_plants = self._sum_group(counts, self.FRUIT_PLANTS)
        pollinators = self._sum_group(counts, [sp for sp in self.POLLINATORS if sp in counts])
        land_herbivores = self._sum_group(counts, self.LAND_HERBIVORES)
        land_predators = self._sum_group(counts, self.LAND_PREDATORS)
        aquatic_producers = self._sum_group(counts, self.AQUATIC_PRODUCERS)
        aquatic_consumers = self._sum_group(counts, self.AQUATIC_CONSUMERS)
        aquatic_predators = self._sum_group(counts, self.AQUATIC_PREDATORS)

        components = {
            "land_foundation": self._group_health(counts, land_foundation, int(self.land_capacity * 0.12)),
            "fruit_plants": self._group_health(counts, fruit_plants, int(self.land_capacity * 0.04)),
            "pollinators": self._group_health(counts, pollinators, max(3, fruit_plants // 6)),
            "land_middle": min(1.0, land_foundation / max(1, land_herbivores * 3)) if land_herbivores else 1.0,
            "land_predators": min(1.0, land_herbivores / max(1, land_predators * 2)) if land_predators else 1.0,
            "aquatic_foundation": self._group_health(counts, aquatic_producers, int(self.water_capacity * 0.22)),
            "aquatic_middle": min(1.0, aquatic_producers / max(1, aquatic_consumers)) if aquatic_consumers else 1.0,
            "aquatic_predators": min(1.0, aquatic_consumers / max(1, aquatic_predators * 2)) if aquatic_predators else 1.0,
        }
        weights = {
            "land_foundation": 0.24,
            "fruit_plants": 0.08,
            "pollinators": 0.08,
            "land_middle": 0.18,
            "land_predators": 0.10,
            "aquatic_foundation": 0.16,
            "aquatic_middle": 0.10,
            "aquatic_predators": 0.06,
        }
        score = sum(components[key] * weights[key] for key in weights)
        return max(0, min(100, score * 100))
        
    def get_recommendations(self, stats: Dict) -> List[str]:
        recommendations = []
        counts = stats.get("species", {})
        land_foundation = self._sum_group(counts, self.LAND_FOUNDATION)
        land_herbivores = self._sum_group(counts, self.LAND_HERBIVORES)
        land_predators = self._sum_group(counts, self.LAND_PREDATORS)
        aquatic_producers = self._sum_group(counts, self.AQUATIC_PRODUCERS)
        aquatic_consumers = self._sum_group(counts, self.AQUATIC_CONSUMERS)
        pollinators = self._sum_group(counts, [sp for sp in self.POLLINATORS if sp in counts])
        fruit_plants = self._sum_group(counts, self.FRUIT_PLANTS)

        if land_foundation < max(20, int(self.land_capacity * 0.08)):
            recommendations.append("➕ 补充陆地植物，优先 grass、bush、flower")
        if pollinators < max(3, fruit_plants // 6):
            recommendations.append("➕ 补充 bee 或 hummingbird，提升授粉稳定性")
        if land_predators > max(4, int(land_herbivores * 0.7)):
            recommendations.append("⚠️ 降低陆地捕食者密度，或增加中层猎物")
        if aquatic_producers < max(10, int(self.water_capacity * 0.18)):
            recommendations.append("➕ 补充 algae、seaweed、plankton")
        if aquatic_consumers > max(8, int(aquatic_producers * 1.6)):
            recommendations.append("⚠️ 水生消费者偏多，考虑补充生产者或减少小鱼/鲤鱼")

        return recommendations[:5]
        
    def get_emoji(self, species: str) -> str:
        return self.EMOJIS.get(species, "?")

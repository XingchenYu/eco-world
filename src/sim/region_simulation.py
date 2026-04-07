"""区域模拟兼容层。"""

from typing import Optional

from src.core.ecosystem import Ecosystem
from src.world import Region


class RegionSimulation(Ecosystem):
    """在 v4 过渡阶段，沿用当前 Ecosystem 作为区域模拟内核。"""

    def __init__(self, region: Optional[Region] = None, config_path: str = None, config: dict = None):
        super().__init__(config_path=config_path, config=config)
        self.region = region
        self.region_id = region.region_id if region is not None else "legacy_region"
        self.region_name = region.name if region is not None else "Legacy Region"

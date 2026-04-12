"""
EcoWorld - 虚拟生态系统
主入口文件
"""

import argparse
import yaml
from pathlib import Path

from src.core.ecosystem import Ecosystem
from src.renderer.gui import Renderer
from src.renderer.advanced_gui import AdvancedRenderer
from src.renderer.world_gui import WorldRenderer
from src.sim.world_simulation import build_default_world_simulation


def load_config(config_path: str = None) -> dict:
    """加载配置文件"""
    if config_path is None:
        config_path = Path(__file__).parent.parent / "config.yaml"
    
    try:
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Config file not found: {config_path}, using defaults")
        return {}


def main():
    parser = argparse.ArgumentParser(description="EcoWorld - Virtual Ecosystem")
    parser.add_argument("--config", "-c", type=str, default=None, help="Path to config file")
    parser.add_argument("--width", "-W", type=int, default=None, help="Window width")
    parser.add_argument("--height", "-H", type=int, default=None, help="Window height")
    parser.add_argument("--speed", "-s", type=int, default=1, help="Initial simulation speed")
    parser.add_argument("--headless", action="store_true", help="Run without GUI (for testing)")
    parser.add_argument("--advanced", "-a", action="store_true", help="Use advanced renderer (游戏化界面)")
    parser.add_argument("--classic", action="store_true", help="Use classic renderer (经典界面)")
    parser.add_argument("--world-ui", action="store_true", help="Use v4 world simulation UI (世界面板)")
    
    args = parser.parse_args()
    
    # 加载配置
    config = load_config(args.config)
    
    # 覆盖命令行参数
    if "world" not in config:
        config["world"] = {}
    if args.width is not None:
        config["world"]["width"] = args.width
    if args.height is not None:
        config["world"]["height"] = args.height
    config["world"]["grid_size"] = config.get("world", {}).get("grid_size", 20)
    
    if args.world_ui:
        print("🌐 Initializing EcoWorld v4 world simulation...")
        world_simulation = build_default_world_simulation()
        print(f"   Regions: {len(world_simulation.world_map.regions)}")
        print(f"   World: {world_simulation.world_map.name}")

        if args.headless:
            print("\n🔄 Running v4 world simulation headless...")
            for _ in range(20):
                world_simulation.update()
            stats = world_simulation.get_statistics()
            active_region = stats["active_region"]
            print(
                f"Tick {stats['world_tick']}: "
                f"{active_region['name']} prosperity={active_region['health_state'].get('prosperity', 0.0):.2f}"
            )
            return

        print("\n🗺️ Launching v4 World UI...")
        print("   Controls:")
        print("      Space: Pause/Resume")
        print("      Left/Right/Tab: Switch focus region")
        print("      1-6: Jump to region")
        print("      +/-: Adjust speed")
        print("      Q/ESC: Quit")

        renderer = WorldRenderer(world_simulation)
        renderer.speed = max(1, args.speed)
        renderer.run()
        return

    # 创建生态系统
    print("🌍 Initializing EcoWorld...")
    ecosystem = Ecosystem(config_path=args.config, config=config)
    
    print(f"   World size: {ecosystem.width}x{ecosystem.height}")
    print(f"   Initial population:")
    stats = ecosystem.get_statistics()
    
    total_plants = 0
    total_animals = 0
    total_aquatic = 0
    
    for species, count in stats["species"].items():
        if count > 0:
            print(f"      {species}: {count}")
            if species in ["grass", "bush", "flower", "moss", "tree", "vine", "cactus", "berry", "mushroom", "fern",
                          "apple_tree", "cherry_tree", "grape_vine", "strawberry", "blueberry", "orange_tree", "watermelon"]:
                total_plants += count
            elif species in ["algae", "seaweed", "plankton", "small_fish", "minnow", "carp", "catfish", "large_fish", "pufferfish",
                            "blackfish", "pike", "shrimp", "crab", "tadpole", "water_strider"]:
                total_aquatic += count
            else:
                total_animals += count
    
    print(f"\n   Total: 🌿 {total_plants} plants, 🐾 {total_animals} animals, 🐟 {total_aquatic} aquatic")
    
    if args.headless:
        # 无头模式，仅运行模拟
        print("\n🔄 Running headless simulation...")
        for i in range(100):
            ecosystem.update()
            if i % 10 == 0:
                stats = ecosystem.get_statistics()
                print(f"Tick {i}: Plants={stats['plants']}, Animals={stats['animals']}")
    else:
        # 选择渲染器
        if args.advanced:
            # 高级游戏化界面
            print("\n🎮 Launching Advanced GUI...")
            print("   ═══════════════════════════════")
            print("   🎮 游戏化界面 (专业版)")
            print("   ═══════════════════════════════")
            print("   Controls:")
            print("      🖱️ 鼠标滚轮: 缩放")
            print("      🖱️ 右键拖拽: 平移地图")
            print("      🖱️ 左键点击: 选择生物")
            print("      ⌨️  1-9: 快速添加生物")
            print("      ⌨️  Space: 暂停/继续")
            print("      ⌨️  +/-: 调整速度")
            print("      ⌨️  G: 显示网格")
            print("      ⌨️  Home: 重置视角")
            print("      ⌨️  F1-F4: 切换面板")
            print("      ⌨️  Q/ESC: 退出")
            print("   ═══════════════════════════════")
            
            renderer = AdvancedRenderer(ecosystem, config)
            renderer.speed = max(1, args.speed)
            renderer.run()
        else:
            # 经典界面（默认）
            print("\n🎮 Launching Classic GUI...")
            print("   Controls:")
            print("      Space: Pause/Resume")
            print("      +/-: Adjust speed")
            print("      G/R/F/I: Add Grass/Rabbit/Fox/Insect")
            print("      Q: Quit")
            print("   Tip: Use --advanced or -a for game-style interface")
            
            renderer = Renderer(ecosystem, config)
            renderer.speed = max(1, args.speed)
            renderer.run()


if __name__ == "__main__":
    main()

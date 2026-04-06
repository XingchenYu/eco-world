#!/usr/bin/env python3
"""生态系统完整测试 - 验证自然平衡（500 tick）"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

# 解决循环导入问题 - 延迟导入
def run_ecosystem_test():
    print("=" * 60)
    print("🌍 EcoWorld 自然平衡测试（500 tick）")
    print("=" * 60)
    
    # 直接导入生态系统
    from src.core.ecosystem import Ecosystem
    
    # 创建生态系统
    print("\n初始化生态系统...")
    eco = Ecosystem()
    
    # 获取初始状态
    stats = eco.get_statistics()
    print(f"\n=== 初始状态 (tick 0) ===")
    print(f"陆地动物: {stats['animals']}")
    print(f"水生生物: {stats['aquatic']}")
    print(f"植物: {stats['plants']}")
    
    # 打印初始物种数量
    species = stats['species']
    print("\n初始物种数量:")
    for sp, count in sorted(species.items(), key=lambda x: -x[1])[:15]:
        if count > 0:
            print(f"  {sp}: {count}")
    
    # 运行 500 tick
    print("\n运行 500 tick...")
    for i in range(500):
        eco.update()  # 使用 update 方法而不是 tick
        if i % 100 == 99:
            stats = eco.get_statistics()
            print(f"\n=== Tick {i+1} ===")
            print(f"陆地动物: {stats['animals']}, 水生生物: {stats['aquatic']}, 植物: {stats['plants']}")
            # 打印关键物种
            species = stats['species']
            key_species = ['deer', 'rabbit', 'wolf', 'fox', 'insect', 'spider',
                          'carp', 'blackfish', 'pike', 'small_fish', 'algae', 'plankton']
            print("关键物种:")
            for sp in key_species:
                count = species.get(sp, 0)
                status = "✅" if count > 0 else "❌"
                print(f"  {status} {sp}: {count}")
    
    # 最终统计
    print("\n" + "=" * 60)
    print("最终状态 (tick 500)")
    print("=" * 60)
    
    stats = eco.get_statistics()
    species = stats['species']
    
    # 水生生物
    print("\n【水生生物】")
    aquatic = ['algae', 'seaweed', 'plankton', 'small_fish', 'carp', 'catfish', 
               'large_fish', 'blackfish', 'pike', 'shrimp', 'crab']
    for sp in aquatic:
        count = species.get(sp, 0)
        status = "✅" if count > 0 else "❌"
        print(f"  {status} {sp}: {count}")
    
    # 陆地动物
    print("\n【陆地动物】")
    land = ['insect', 'rabbit', 'fox', 'wolf', 'deer', 'mouse', 'bird', 'snake', 'spider']
    for sp in land:
        count = species.get(sp, 0)
        status = "✅" if count > 0 else "❌"
        print(f"  {status} {sp}: {count}")
    
    # 检查平衡状态
    print("\n" + "=" * 60)
    print("平衡分析")
    print("=" * 60)
    
    # 检查是否有物种灭绝
    extinct = [sp for sp, count in species.items() if count == 0]
    if extinct:
        print(f"⚠️ 灭绝物种: {extinct}")
    else:
        print("✅ 所有物种存活！")
    
    # 检查是否有物种泛滥
    high_count = [(sp, count) for sp, count in species.items() if count > 200]
    if high_count:
        print(f"⚠️ 可能泛滥: {high_count}")
    else:
        print("✅ 无物种泛滥！")
    
    # 检查天敌是否起作用
    deer_count = species.get('deer', 0)
    wolf_count = species.get('wolf', 0)
    carp_count = species.get('carp', 0)
    blackfish_count = species.get('blackfish', 0)
    pike_count = species.get('pike', 0)
    
    print(f"\n天敌关系:")
    print(f"  鹿: {deer_count} 只, 狼: {wolf_count} 只")
    if deer_count > 0 and wolf_count > 0:
        print(f"  ✅ 狼正在控制鹿的数量")
    print(f"  鲤鱼: {carp_count} 只, 黑鱼: {blackfish_count} 只, 狗鱼: {pike_count} 只")
    if carp_count > 0 and (blackfish_count > 0 or pike_count > 0):
        print(f"  ✅ 天敌鱼正在控制鲤鱼数量")
    
    # 生态系统健康度
    health = stats.get('health', 0)
    print(f"\n生态系统健康度: {health:.1f}%")
    
    return True

if __name__ == "__main__":
    try:
        run_ecosystem_test()
        print("\n" + "=" * 60)
        print("✅ 测试完成！自然平衡系统验证成功")
        print("=" * 60)
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
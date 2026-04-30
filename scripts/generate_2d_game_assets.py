#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REGION_DIR = ROOT / "godot" / "assets" / "ui" / "region_maps"
SPRITE_DIR = ROOT / "godot" / "assets" / "ui" / "animal_sprites"
SIZE = (4800, 3200)
BASE_SIZE = (2800, 1700)


def scale(point: tuple[float, float]) -> tuple[float, float]:
    return (point[0] * SIZE[0] / BASE_SIZE[0], point[1] * SIZE[1] / BASE_SIZE[1])


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def blend(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t))


def ellipse(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: tuple[float, float], fill, outline=None, width: int = 1) -> None:
    x, y = center
    rx, ry = radius
    draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=fill, outline=outline, width=width)


def polygon_blob(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: tuple[float, float], fill, seed: int, points: int = 28) -> None:
    rng = random.Random(seed)
    cx, cy = center
    rx, ry = radius
    vertices = []
    for index in range(points):
        angle = math.tau * index / points
        wobble = 0.78 + rng.random() * 0.42
        vertices.append((cx + math.cos(angle) * rx * wobble, cy + math.sin(angle) * ry * wobble))
    draw.polygon(vertices, fill=fill)


def make_ground(base: tuple[int, int, int], far: tuple[int, int, int], seed: int) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGB", SIZE, base)
    px = img.load()
    for y in range(SIZE[1]):
        t = y / SIZE[1]
        row = blend(base, far, t)
        for x in range(SIZE[0]):
            grain = int((rng.random() - 0.5) * 10)
            wave = int(math.sin(x * 0.004 + y * 0.002) * 5)
            px[x, y] = (
                max(0, min(255, row[0] + grain + wave)),
                max(0, min(255, row[1] + grain + wave)),
                max(0, min(255, row[2] + grain)),
            )
    return img.filter(ImageFilter.GaussianBlur(0.35))


def draw_common_landmarks(draw: ImageDraw.ImageDraw, biome: str, seed: int) -> None:
    rng = random.Random(seed)
    waterhole = scale((940, 850))
    carrion = scale((2050, 760))
    predator = scale((2170, 500))

    river = [scale(p) for p in [(230, 1390), (620, 1200), (980, 1040), (1370, 960), (1790, 1030), (2240, 890), (2690, 720)]]
    if biome in {"grassland", "wetland", "forest"}:
        for width, color in [(138, (64, 125, 154, 130)), (78, (95, 162, 188, 190)), (34, (174, 222, 225, 210))]:
            draw.line(river, fill=color, width=width, joint="curve")

    for layer, color in [(1.0, (54, 108, 142, 190)), (0.66, (97, 166, 190, 215)), (0.34, (178, 226, 224, 210))]:
        ellipse(draw, waterhole, (250 * layer, 156 * layer), color)

    polygon_blob(draw, carrion, (155, 90), (106, 73, 55, 92), seed + 18)
    ellipse(draw, carrion, (23, 12), (224, 210, 170, 180))
    draw.line((carrion[0] - 34, carrion[1] - 16, carrion[0] + 36, carrion[1] + 18), fill=(120, 84, 62, 185), width=6)

    ridge = [scale(p) for p in [(1840, 575), (1990, 500), (2190, 475), (2410, 560), (2650, 610)]]
    draw.line(ridge, fill=(103, 96, 82, 150), width=30, joint="curve")
    draw.line(ridge, fill=(211, 198, 160, 115), width=6, joint="curve")
    for _ in range(42):
        x = predator[0] + rng.uniform(-420, 470)
        y = predator[1] + rng.uniform(-180, 210)
        ellipse(draw, (x, y), (rng.uniform(10, 28), rng.uniform(7, 20)), (108, 101, 84, rng.randint(90, 150)))


def draw_grassland(draw: ImageDraw.ImageDraw) -> None:
    rng = random.Random(31)
    for index in range(260):
        center = (rng.randrange(0, SIZE[0]), rng.randrange(0, SIZE[1]))
        radius = (rng.uniform(34, 130), rng.uniform(14, 58))
        color = rng.choice([(139, 157, 74, 72), (176, 154, 78, 62), (98, 126, 67, 70), (205, 181, 100, 48)])
        polygon_blob(draw, center, radius, color, 3100 + index, 18)
    for index in range(34):
        cx, cy = scale((rng.uniform(360, 2500), rng.uniform(450, 1260)))
        draw_tree(draw, (cx, cy), rng, kind="acacia")


def draw_wetland(draw: ImageDraw.ImageDraw) -> None:
    rng = random.Random(42)
    for index in range(90):
        center = (rng.randrange(180, SIZE[0] - 180), rng.randrange(260, SIZE[1] - 220))
        polygon_blob(draw, center, (rng.uniform(55, 170), rng.uniform(25, 82)), (60, 116, 126, rng.randint(58, 105)), 4200 + index, 22)
    for index in range(220):
        x, y = rng.randrange(80, SIZE[0] - 80), rng.randrange(140, SIZE[1] - 80)
        draw.line((x, y + 24, x + rng.uniform(-12, 12), y - rng.uniform(28, 54)), fill=(92, 126, 82, 190), width=rng.randint(3, 6))


def draw_forest(draw: ImageDraw.ImageDraw) -> None:
    rng = random.Random(51)
    for index in range(110):
        cx, cy = rng.randrange(140, SIZE[0] - 140), rng.randrange(150, SIZE[1] - 150)
        polygon_blob(draw, (cx, cy), (rng.uniform(95, 235), rng.uniform(70, 180)), (36, 75, 45, rng.randint(78, 126)), 5100 + index, 24)
    for index in range(130):
        draw_tree(draw, (rng.randrange(120, SIZE[0] - 120), rng.randrange(120, SIZE[1] - 120)), rng, kind="forest")


def draw_coast(draw: ImageDraw.ImageDraw) -> None:
    rng = random.Random(62)
    sea = [(0, SIZE[1]), (0, int(SIZE[1] * 0.68))]
    for x in range(0, SIZE[0] + 320, 320):
        sea.append((x, int(SIZE[1] * (0.61 + math.sin(x * 0.003) * 0.035))))
    sea += [(SIZE[0], SIZE[1])]
    draw.polygon(sea, fill=(67, 139, 178, 205))
    for offset in [0, 55, 110]:
        wave = []
        for x in range(0, SIZE[0] + 80, 80):
            y = int(SIZE[1] * 0.63 + math.sin(x * 0.004 + offset) * 44 + offset)
            wave.append((x, y))
        draw.line(wave, fill=(214, 239, 232, 120), width=12)
    for index in range(44):
        draw_tree(draw, (rng.randrange(120, SIZE[0] - 120), rng.randrange(200, int(SIZE[1] * 0.62))), rng, kind="palm")


def draw_tree(draw: ImageDraw.ImageDraw, center: tuple[float, float], rng: random.Random, kind: str) -> None:
    x, y = center
    if kind == "palm":
        draw.line((x, y + 46, x + 10, y - 20), fill=(107, 82, 48, 210), width=12)
        for angle in [-2.8, -2.2, -1.6, -1.0, -0.45]:
            draw.line((x + 8, y - 20, x + math.cos(angle) * 58, y - 20 + math.sin(angle) * 42), fill=(56, 116, 78, 220), width=9)
        return
    trunk = (95, 68, 42, 210)
    leaf = (62, 105, 56, 218) if kind == "forest" else (78, 121, 67, 210)
    draw.line((x, y + 42, x, y - 16), fill=trunk, width=10)
    ellipse(draw, (x, y - 28), (42, 30), leaf)
    ellipse(draw, (x - 28, y - 18), (35, 24), leaf)
    ellipse(draw, (x + 30, y - 16), (38, 25), leaf)


def generate_region_maps() -> None:
    REGION_DIR.mkdir(parents=True, exist_ok=True)
    configs = {
        "grassland": ((178, 164, 98), (117, 138, 76), draw_grassland),
        "wetland": ((122, 151, 112), (73, 121, 116), draw_wetland),
        "forest": ((74, 105, 66), (39, 73, 45), draw_forest),
        "coast": ((202, 191, 145), (152, 181, 168), draw_coast),
    }
    for index, (name, (base, far, painter)) in enumerate(configs.items()):
        img = make_ground(base, far, 100 + index)
        overlay = Image.new("RGBA", SIZE, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay, "RGBA")
        painter(draw)
        draw_common_landmarks(draw, name, 700 + index)
        img = Image.alpha_composite(img.convert("RGBA"), overlay).filter(ImageFilter.GaussianBlur(0.2))
        img.save(REGION_DIR / f"{name}.png")


def animal_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (360, 240), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img, "RGBA")


def leg(draw: ImageDraw.ImageDraw, x: float, y: float, length: float, color, hoof=(42, 32, 24, 255), width: int = 8) -> None:
    draw.line((x, y, x - 5, y + length * 0.52, x + 4, y + length), fill=color, width=width, joint="curve")
    draw.ellipse((x - 8, y + length - 4, x + 14, y + length + 6), fill=hoof)


def save_sprite(name: str, img: Image.Image) -> None:
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    img.save(SPRITE_DIR / f"{name}.png")


def make_antelope() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (178, 190), (92, 16), (0, 0, 0, 42))
    for x in [120, 154, 202, 236]:
        leg(draw, x, 116, 72, (159, 122, 72, 255), width=7)
    ellipse(draw, (178, 108), (98, 34), (178, 136, 78, 255))
    ellipse(draw, (170, 122), (78, 18), (232, 204, 154, 245))
    ellipse(draw, (264, 82), (34, 24), (175, 135, 82, 255))
    draw.line((238, 91, 252, 71), fill=(170, 130, 78, 255), width=16)
    draw.line((266, 62, 258, 24), fill=(46, 36, 26, 255), width=5)
    draw.line((276, 62, 285, 24), fill=(46, 36, 26, 255), width=5)
    draw.polygon([(294, 82), (326, 91), (292, 100)], fill=(224, 193, 145, 255))
    ellipse(draw, (278, 77), (4, 4), (20, 18, 14, 255))
    draw.line((84, 105, 54, 90), fill=(92, 70, 42, 255), width=5)
    save_sprite("antelope", img)


def make_lion() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (178, 192), (105, 18), (0, 0, 0, 44))
    for x in [118, 154, 210, 246]:
        leg(draw, x, 120, 74, (176, 126, 62, 255), width=9)
    ellipse(draw, (176, 108), (108, 38), (183, 130, 62, 255))
    ellipse(draw, (256, 82), (48, 42), (92, 58, 34, 255))
    ellipse(draw, (275, 84), (30, 24), (190, 136, 75, 255))
    ellipse(draw, (292, 92), (18, 11), (224, 184, 129, 255))
    ellipse(draw, (282, 78), (4, 4), (18, 14, 10, 255))
    draw.line((76, 106, 48, 76), fill=(128, 82, 42, 255), width=8)
    ellipse(draw, (43, 74), (10, 10), (92, 58, 34, 255))
    save_sprite("lion", img)


def make_canid() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (178, 190), (92, 15), (0, 0, 0, 40))
    for x in [118, 152, 204, 238]:
        leg(draw, x, 118, 70, (111, 82, 52, 255), width=7)
    ellipse(draw, (176, 108), (96, 30), (129, 91, 55, 255))
    for spot in [(132, 100, 38, 19), (198, 117, 42, 15), (224, 98, 28, 12)]:
        ellipse(draw, (spot[0], spot[1]), (spot[2], spot[3]), (48, 43, 35, 210))
    ellipse(draw, (260, 82), (35, 23), (122, 86, 52, 255))
    draw.polygon([(285, 82), (326, 89), (286, 101)], fill=(116, 80, 48, 255))
    draw.polygon([(246, 62), (254, 24), (268, 63)], fill=(72, 50, 36, 255))
    draw.line((83, 105, 48, 78), fill=(68, 48, 34, 255), width=7)
    save_sprite("canid", img)


def make_elephant() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (172, 194), (132, 21), (0, 0, 0, 42))
    for x in [104, 148, 205, 250]:
        leg(draw, x, 124, 76, (116, 115, 104, 255), width=17)
    ellipse(draw, (168, 102), (128, 58), (126, 126, 116, 255))
    ellipse(draw, (270, 88), (54, 48), (129, 129, 119, 255))
    ellipse(draw, (246, 91), (28, 36), (101, 102, 94, 230))
    draw.line((302, 102, 322, 146, 310, 176), fill=(108, 107, 98, 255), width=14, joint="curve")
    draw.line((310, 104, 338, 114), fill=(236, 225, 190, 255), width=5)
    draw.line((83, 104, 50, 122), fill=(93, 92, 84, 255), width=7)
    save_sprite("elephant", img)


def make_giraffe() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (180, 198), (100, 15), (0, 0, 0, 42))
    for x in [120, 156, 208, 242]:
        leg(draw, x, 110, 88, (197, 151, 75, 255), width=8)
    ellipse(draw, (176, 98), (95, 29), (206, 158, 76, 255))
    draw.line((238, 82, 268, 24), fill=(199, 153, 74, 255), width=18)
    ellipse(draw, (286, 22), (32, 19), (208, 164, 86, 255))
    for x, y in [(132, 92), (168, 108), (202, 91), (236, 104), (272, 42)]:
        ellipse(draw, (x, y), (13, 9), (107, 72, 38, 220))
    draw.line((280, 5, 278, -12), fill=(68, 48, 32, 255), width=4)
    draw.line((294, 6, 298, -10), fill=(68, 48, 32, 255), width=4)
    save_sprite("giraffe", img)


def make_zebra() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (178, 190), (98, 15), (0, 0, 0, 42))
    for x in [118, 154, 204, 240]:
        leg(draw, x, 116, 72, (225, 221, 204, 255), width=8)
    ellipse(draw, (178, 105), (104, 34), (226, 222, 204, 255))
    for x in range(112, 250, 24):
        draw.line((x, 76, x - 18, 134), fill=(43, 40, 34, 210), width=6)
    ellipse(draw, (266, 78), (35, 22), (226, 222, 204, 255))
    draw.line((240, 84, 258, 66), fill=(226, 222, 204, 255), width=14)
    draw.polygon([(294, 78), (326, 84), (292, 94)], fill=(226, 222, 204, 255))
    draw.line((84, 103, 52, 82), fill=(43, 40, 34, 255), width=7)
    save_sprite("zebra", img)


def make_vulture() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (178, 166), (78, 12), (0, 0, 0, 36))
    draw.polygon([(70, 96), (172, 120), (128, 150)], fill=(74, 67, 55, 245))
    draw.polygon([(186, 120), (300, 92), (230, 154)], fill=(82, 74, 60, 245))
    ellipse(draw, (178, 122), (46, 24), (96, 83, 62, 255))
    ellipse(draw, (224, 105), (22, 18), (177, 145, 104, 255))
    draw.polygon([(242, 104), (268, 109), (243, 116)], fill=(224, 195, 118, 255))
    save_sprite("vulture", img)


def make_crocodile() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (176, 188), (118, 13), (0, 0, 0, 38))
    draw.polygon([(62, 116), (110, 93), (256, 98), (324, 116), (252, 134), (112, 132)], fill=(62, 103, 61, 255))
    draw.polygon([(254, 98), (334, 104), (332, 122), (252, 134)], fill=(74, 120, 71, 255))
    for x in range(108, 256, 22):
        draw.polygon([(x, 94), (x + 9, 80), (x + 20, 96)], fill=(41, 77, 45, 230))
    for x in [118, 156, 210, 250]:
        draw.line((x, 130, x - 20, 154), fill=(49, 86, 51, 255), width=8)
    save_sprite("crocodile", img)


def make_fish() -> None:
    img, draw = animal_canvas()
    ellipse(draw, (178, 128), (78, 35), (83, 145, 169, 255))
    draw.polygon([(98, 128), (50, 94), (58, 160)], fill=(67, 121, 148, 255))
    draw.polygon([(202, 94), (220, 58), (228, 104)], fill=(69, 124, 149, 230))
    ellipse(draw, (235, 120), (7, 7), (16, 26, 30, 255))
    save_sprite("fish", img)


def make_sprites() -> None:
    make_antelope()
    make_lion()
    make_canid()
    make_elephant()
    make_giraffe()
    make_zebra()
    make_vulture()
    make_crocodile()
    make_fish()


def main() -> None:
    generate_region_maps()
    make_sprites()


if __name__ == "__main__":
    main()

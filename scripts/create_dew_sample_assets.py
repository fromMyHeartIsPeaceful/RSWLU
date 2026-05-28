from pathlib import Path
import math
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "IncomingArt" / "BuBuGardenAssets_v1"
GARDEN_DIR = OUT_ROOT / "gardens"
FLOWER_DIR = OUT_ROOT / "flowers" / "dew"
PREVIEW_DIR = OUT_ROOT / "previews"

FLOWER_SIZE = 1024
GARDEN_SIZE = (1600, 1200)


def lerp(a, b, t):
    return int(a * (1 - t) + b * t)


def mix(c1, c2, t):
    return tuple(lerp(c1[i], c2[i], t) for i in range(4))


def rgba(color, alpha=None):
    if len(color) == 4:
        return color
    return (color[0], color[1], color[2], 255 if alpha is None else alpha)


def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    ]
    for path in candidates:
        p = Path(path)
        if p.exists():
            return ImageFont.truetype(str(p), size=size, index=1 if bold and path.endswith(".ttc") else 0)
    return ImageFont.load_default()


def ensure_dirs():
    GARDEN_DIR.mkdir(parents=True, exist_ok=True)
    FLOWER_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)


def blurred_layer(size, draw_fn, blur):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer, "RGBA"))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def ellipse_gradient(size, top, bottom, edge_alpha=1.0):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        ty = y / max(h - 1, 1)
        for x in range(w):
            nx = (x + 0.5 - w / 2) / (w / 2)
            ny = (y + 0.5 - h / 2) / (h / 2)
            dist = nx * nx + ny * ny
            if dist <= 1:
                shade = mix(top, bottom, ty)
                edge = min(1, max(0, (1 - dist) * 5))
                a = int(shade[3] * min(1, 0.72 + edge * 0.28) * edge_alpha)
                px[x, y] = (shade[0], shade[1], shade[2], a)
    return img


def paste_rotated(base, shape, center, angle):
    rotated = shape.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    x = int(center[0] - rotated.width / 2)
    y = int(center[1] - rotated.height / 2)
    base.alpha_composite(rotated, (x, y))


def paste_ellipse(base, center, size, angle, top, bottom, outline=None, highlight=True):
    shape = ellipse_gradient(size, rgba(top), rgba(bottom))
    d = ImageDraw.Draw(shape, "RGBA")
    if highlight:
        d.arc((size[0] * 0.18, size[1] * 0.12, size[0] * 0.82, size[1] * 0.82), 210, 306, fill=(255, 255, 255, 68), width=max(2, size[0] // 24))
    if outline:
        d.ellipse((1, 1, size[0] - 2, size[1] - 2), outline=outline, width=max(2, size[0] // 40))
    paste_rotated(base, shape, center, angle)


def draw_soft_shadow(base, bbox, alpha=42, blur=20):
    def draw_fn(d):
        d.ellipse(bbox, fill=(52, 67, 45, alpha))

    base.alpha_composite(blurred_layer(base.size, draw_fn, blur))


def draw_stem(base, start, end, width=34):
    d = ImageDraw.Draw(base, "RGBA")
    shadow = blurred_layer(
        base.size,
        lambda sd: sd.line((start[0] + 8, start[1] + 4, end[0] + 8, end[1] + 4), fill=(33, 76, 39, 70), width=width + 6),
        7,
    )
    base.alpha_composite(shadow)
    d.line((start[0], start[1], end[0], end[1]), fill=(62, 148, 73, 255), width=width)
    d.line((start[0] - width * 0.16, start[1], end[0] - width * 0.12, end[1]), fill=(154, 208, 112, 130), width=max(3, width // 5))
    d.line((start[0] + width * 0.24, start[1], end[0] + width * 0.14, end[1]), fill=(35, 101, 48, 90), width=max(3, width // 6))


def draw_leaf(base, center, size, angle, bright=False):
    top = (166, 213, 101, 255) if bright else (124, 190, 82, 255)
    bottom = (48, 132, 65, 255) if bright else (44, 118, 58, 255)
    paste_ellipse(base, center, size, angle, top, bottom, outline=(41, 92, 50, 70))
    d = ImageDraw.Draw(base, "RGBA")
    r = math.radians(angle)
    dx = math.cos(r) * size[0] * 0.33
    dy = math.sin(r) * size[0] * 0.33
    d.line((center[0] - dx, center[1] - dy, center[0] + dx, center[1] + dy), fill=(238, 255, 203, 92), width=max(3, size[1] // 12))


def draw_dew(base, center, radius=18, alpha=180):
    d = ImageDraw.Draw(base, "RGBA")
    d.ellipse((center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius), fill=(214, 244, 255, alpha), outline=(255, 255, 255, 130), width=2)
    d.ellipse((center[0] - radius * 0.38, center[1] - radius * 0.48, center[0] - radius * 0.02, center[1] - radius * 0.12), fill=(255, 255, 255, 120))


def flower_canvas():
    return Image.new("RGBA", (FLOWER_SIZE, FLOWER_SIZE), (0, 0, 0, 0))


def add_subject_shadow(base, stage):
    if stage == "seed":
        draw_soft_shadow(base, (370, 650, 655, 730), alpha=28, blur=22)
    elif stage == "sprout":
        draw_soft_shadow(base, (330, 744, 700, 822), alpha=30, blur=26)
    else:
        draw_soft_shadow(base, (300, 790, 730, 876), alpha=34, blur=30)


def make_seed():
    base = flower_canvas()
    add_subject_shadow(base, "seed")
    paste_ellipse(base, (513, 610), (190, 248), -18, (245, 199, 100, 255), (139, 88, 43, 255), outline=(103, 72, 34, 95))
    paste_ellipse(base, (470, 640), (76, 118), -32, (255, 225, 146, 130), (198, 124, 57, 40), highlight=False)
    d = ImageDraw.Draw(base, "RGBA")
    d.arc((440, 492, 572, 686), 288, 60, fill=(255, 239, 176, 155), width=7)
    d.arc((476, 535, 600, 706), 285, 28, fill=(101, 67, 33, 86), width=5)
    d.line((520, 716, 516, 770), fill=(97, 66, 38, 150), width=8)
    d.arc((498, 746, 560, 802), 190, 322, fill=(97, 66, 38, 120), width=5)
    draw_dew(base, (582, 546), 17, 164)
    return base


def make_sprout():
    base = flower_canvas()
    add_subject_shadow(base, "sprout")
    draw_stem(base, (515, 760), (505, 506), width=28)
    draw_leaf(base, (424, 570), (205, 92), -31, bright=True)
    draw_leaf(base, (594, 543), (212, 98), 27, bright=False)
    draw_leaf(base, (474, 680), (142, 62), -25, bright=False)
    d = ImageDraw.Draw(base, "RGBA")
    d.line((505, 506, 501, 468), fill=(117, 190, 82, 250), width=14)
    draw_dew(base, (626, 505), 14, 170)
    draw_dew(base, (414, 536), 12, 140)
    return base


def make_bud():
    base = flower_canvas()
    add_subject_shadow(base, "bud")
    draw_stem(base, (520, 792), (505, 435), width=31)
    draw_leaf(base, (410, 664), (218, 98), -36, bright=False)
    draw_leaf(base, (610, 625), (220, 102), 31, bright=True)
    draw_leaf(base, (468, 746), (150, 68), -21, bright=True)
    paste_ellipse(base, (507, 404), (158, 210), -8, (255, 165, 164, 255), (182, 59, 82, 255), outline=(142, 55, 70, 72))
    paste_ellipse(base, (466, 422), (70, 158), 16, (255, 205, 190, 145), (196, 80, 94, 70), highlight=False)
    paste_ellipse(base, (552, 419), (76, 164), -24, (242, 111, 134, 120), (134, 56, 74, 50), highlight=False)
    d = ImageDraw.Draw(base, "RGBA")
    d.arc((449, 308, 558, 486), 205, 314, fill=(255, 238, 222, 120), width=7)
    draw_dew(base, (561, 351), 13, 160)
    return base


def draw_carnation_petals(base, center):
    rng = random.Random(33)
    palettes = [
        ((255, 184, 184, 255), (218, 75, 100, 255)),
        ((255, 152, 169, 255), (196, 55, 91, 255)),
        ((255, 211, 193, 255), (230, 95, 105, 255)),
        ((244, 120, 151, 255), (169, 51, 86, 255)),
    ]
    for ring, count, radius, petal_size in [(0, 15, 118, (86, 176)), (1, 17, 84, (76, 154)), (2, 13, 47, (66, 132))]:
        for i in range(count):
            angle = i * (360 / count) + (ring * 9) + rng.uniform(-7, 7)
            rad = math.radians(angle)
            cx = center[0] + math.cos(rad) * radius
            cy = center[1] + math.sin(rad) * radius * 0.82
            scale = rng.uniform(0.88, 1.12)
            w = int(petal_size[0] * scale)
            h = int(petal_size[1] * scale)
            top, bottom = palettes[(i + ring) % len(palettes)]
            paste_ellipse(base, (cx, cy), (w, h), angle + 88 + rng.uniform(-8, 8), top, bottom, outline=(154, 51, 78, 42), highlight=True)
    paste_ellipse(base, center, (112, 118), 0, (255, 210, 112, 255), (198, 132, 39, 255), outline=(135, 99, 36, 70))
    d = ImageDraw.Draw(base, "RGBA")
    for i in range(20):
        a = math.radians(i * 18)
        x = center[0] + math.cos(a) * random.Random(i).uniform(13, 42)
        y = center[1] + math.sin(a) * random.Random(i + 5).uniform(10, 34)
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(134, 91, 33, 115))


def make_bloom():
    base = flower_canvas()
    add_subject_shadow(base, "bloom")
    draw_stem(base, (520, 828), (505, 503), width=32)
    draw_leaf(base, (407, 698), (232, 104), -36, bright=False)
    draw_leaf(base, (624, 665), (238, 108), 31, bright=True)
    draw_leaf(base, (464, 792), (158, 70), -20, bright=True)
    flower_shadow = blurred_layer(
        base.size,
        lambda d: d.ellipse((330, 210, 700, 580), fill=(92, 40, 52, 48)),
        18,
    )
    base.alpha_composite(flower_shadow)
    draw_carnation_petals(base, (510, 372))
    draw_dew(base, (650, 270), 14, 145)
    draw_dew(base, (390, 421), 12, 120)
    return base


def make_garden_island():
    base = Image.new("RGBA", GARDEN_SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(base, "RGBA")
    draw_soft_shadow(base, (205, 740, 1385, 1028), alpha=46, blur=34)

    d.ellipse((250, 330, 1350, 940), fill=(91, 151, 83, 255))
    d.ellipse((288, 300, 1312, 842), fill=(158, 207, 117, 255))
    d.ellipse((336, 328, 1268, 784), fill=(205, 232, 152, 255))
    d.ellipse((280, 670, 1320, 960), fill=(93, 132, 71, 255))
    d.ellipse((330, 632, 1270, 866), fill=(126, 172, 87, 255))

    top_glow = blurred_layer(
        GARDEN_SIZE,
        lambda gd: gd.ellipse((360, 280, 1220, 710), fill=(255, 255, 221, 70)),
        26,
    )
    base.alpha_composite(top_glow)
    d = ImageDraw.Draw(base, "RGBA")

    d.ellipse((585, 470, 1015, 710), fill=(151, 216, 230, 225), outline=(232, 255, 245, 140), width=5)
    d.ellipse((620, 492, 980, 666), fill=(92, 184, 218, 160))
    d.arc((630, 498, 972, 656), 205, 330, fill=(255, 255, 255, 128), width=5)

    path = [(320, 660), (490, 586), (642, 620), (800, 585), (958, 622), (1120, 568), (1290, 642)]
    for i in range(len(path) - 1):
        d.line((path[i][0], path[i][1], path[i + 1][0], path[i + 1][1]), fill=(236, 214, 157, 210), width=54)
        d.line((path[i][0], path[i][1], path[i + 1][0], path[i + 1][1]), fill=(255, 245, 194, 165), width=24)

    spots = [
        (415, 477), (520, 396), (665, 386), (800, 392), (940, 386),
        (1088, 410), (1176, 512), (1010, 752), (788, 762), (566, 744),
    ]
    for idx, (x, y) in enumerate(spots):
        d.ellipse((x - 48, y - 22, x + 48, y + 22), fill=(88, 65, 37, 120))
        d.ellipse((x - 42, y - 19, x + 42, y + 16), fill=(130, 91, 48, 205))
        d.ellipse((x - 30, y - 12, x + 34, y + 9), fill=(84, 58, 32, 130))
        if idx % 3 == 0:
            draw_dew(base, (x + 38, y - 26), 9, 128)

    rng = random.Random(8)
    for _ in range(90):
        x = rng.randint(320, 1280)
        y = rng.randint(345, 835)
        if ((x - 800) / 560) ** 2 + ((y - 610) / 290) ** 2 > 1.0:
            continue
        color = rng.choice([(245, 238, 151, 160), (255, 185, 171, 150), (218, 243, 189, 160), (183, 226, 246, 130)])
        r = rng.randint(4, 9)
        d.ellipse((x - r, y - r, x + r, y + r), fill=color)

    for x, y, angle in [(335, 615, -28), (1215, 610, 28), (440, 380, -42), (1135, 360, 40), (720, 310, -8)]:
        draw_leaf(base, (x, y), (122, 50), angle, bright=True)
    return base


def make_preview(images):
    w, h = 2400, 900
    base = Image.new("RGBA", (w, h), (248, 252, 243, 255))
    d = ImageDraw.Draw(base, "RGBA")
    d.rectangle((0, 0, w, h), fill=(248, 252, 243, 255))
    for x in range(0, w, 48):
        d.line((x, 0, x, h), fill=(225, 235, 218, 90), width=1)
    for y in range(0, h, 48):
        d.line((0, y, w, y), fill=(225, 235, 218, 80), width=1)

    title_font = font(54, bold=True)
    label_font = font(34, bold=True)
    small_font = font(24)
    d.text((80, 54), "Dew Garden / Carnation 4 stages", fill=(31, 76, 52, 255), font=title_font)
    d.text((82, 126), "Transparent PNG sample assets, 1024x1024 source each", fill=(102, 120, 101, 255), font=small_font)

    labels = [("seed", "种子"), ("sprout", "小芽"), ("bud", "花苞"), ("bloom", "绽放")]
    for i, (stage, zh) in enumerate(labels):
        x = 95 + i * 575
        card = (x, 205, x + 485, 790)
        d.rounded_rectangle((card[0] + 8, card[1] + 12, card[2] + 8, card[3] + 12), radius=34, fill=(67, 80, 49, 28))
        d.rounded_rectangle(card, radius=34, fill=(255, 255, 255, 225), outline=(220, 232, 214, 255), width=2)
        img = images[stage].resize((420, 420), Image.Resampling.LANCZOS)
        base.alpha_composite(img, (x + 32, 284))
        d.text((x + 34, 712), f"{stage} / {zh}", fill=(44, 101, 57, 255), font=label_font)
    return base.convert("RGB")


def validate(path, size, needs_alpha=True):
    img = Image.open(path)
    if img.size != size:
        raise RuntimeError(f"{path} expected {size}, got {img.size}")
    if needs_alpha:
        if img.mode != "RGBA":
            raise RuntimeError(f"{path} expected RGBA, got {img.mode}")
        corners = [img.getpixel((0, 0)), img.getpixel((size[0] - 1, 0)), img.getpixel((0, size[1] - 1)), img.getpixel((size[0] - 1, size[1] - 1))]
        if any(px[3] != 0 for px in corners):
            raise RuntimeError(f"{path} has non-transparent corners: {corners}")


def main():
    ensure_dirs()
    stages = {
        "seed": make_seed(),
        "sprout": make_sprout(),
        "bud": make_bud(),
        "bloom": make_bloom(),
    }
    for stage, image in stages.items():
        image.save(FLOWER_DIR / f"dew_carnation_{stage}.png", optimize=True)

    garden = make_garden_island()
    garden.save(GARDEN_DIR / "dew_garden_island_unlocked.png", optimize=True)

    preview = make_preview(stages)
    preview.save(PREVIEW_DIR / "preview_dew_carnation_4stages.png", quality=92, optimize=True)

    for stage in stages:
        validate(FLOWER_DIR / f"dew_carnation_{stage}.png", (FLOWER_SIZE, FLOWER_SIZE))
    validate(GARDEN_DIR / "dew_garden_island_unlocked.png", GARDEN_SIZE)
    validate(PREVIEW_DIR / "preview_dew_carnation_4stages.png", (2400, 900), needs_alpha=False)

    print("Wrote sample Dew Garden assets:")
    print(f"- {GARDEN_DIR / 'dew_garden_island_unlocked.png'}")
    for stage in stages:
        print(f"- {FLOWER_DIR / f'dew_carnation_{stage}.png'}")
    print(f"- {PREVIEW_DIR / 'preview_dew_carnation_4stages.png'}")


if __name__ == "__main__":
    main()

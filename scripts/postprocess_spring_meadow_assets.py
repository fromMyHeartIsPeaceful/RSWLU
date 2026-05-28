from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "IncomingArt" / "BuBuGardenAssets_v2"
GARDEN_ID = "spring_meadow"
SOURCE_DIR = ASSET_ROOT / "source" / GARDEN_ID
FLOWER_DIR = ASSET_ROOT / "flowers" / GARDEN_ID
PREVIEW_DIR = ASSET_ROOT / "previews" / GARDEN_ID

STAGES = ["seed", "sprout", "bud", "bloom"]
FLOWERS = [
    {"slug": "snowdrop", "name": "雪滴花", "bloom": "white drooping bell-shaped snowdrop flower with green-tipped petals"},
    {"slug": "crocus", "name": "番红花", "bloom": "purple cup-shaped crocus flower with golden center"},
    {"slug": "primrose", "name": "报春花", "bloom": "round five-petal primrose flower with bright yellow center"},
    {"slug": "forget_me_not", "name": "勿忘我", "bloom": "cluster of tiny blue forget-me-not flowers with yellow dot centers"},
    {"slug": "daisy", "name": "雏菊", "bloom": "white daisy with slim petals and warm yellow center"},
    {"slug": "lily_of_the_valley", "name": "铃兰", "bloom": "arching stem with small white bell flowers and paired green leaves"},
    {"slug": "cornflower", "name": "矢车菊", "bloom": "blue cornflower with fine fringed radial petals"},
    {"slug": "pansy", "name": "三色堇", "bloom": "purple yellow white pansy with clear face-like petal markings"},
    {"slug": "hyacinth", "name": "风信子", "bloom": "upright hyacinth flower spike with many small soft blue-purple blossoms"},
]

TARGET_HEIGHTS = {
    "seed": 410,
    "sprout": 640,
    "bud": 800,
    "bloom": 850,
}
TARGET_MAX_WIDTHS = {
    "seed": 430,
    "sprout": 700,
    "bud": 760,
    "bloom": 800,
}


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


def remove_magenta_key(image):
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if r > 210 and b > 210 and g < 90:
                pixels[x, y] = (r, g, b, 0)
            elif r > 175 and b > 165 and g < 145:
                fade = max(0, min(255, int((g - 72) * 1.8)))
                pixels[x, y] = (r, g, b, min(a, fade))

    alpha = image.getchannel("A").filter(ImageFilter.MinFilter(3))
    image.putalpha(alpha)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
            elif b > 150 and r > 150 and g < 150 and min(r, b) - g > 55:
                pixels[x, y] = (r, g, b, min(a, 90))
    return image


def alpha_bbox(image, threshold=8):
    alpha = image.getchannel("A")
    mask = alpha.point(lambda p: 255 if p > threshold else 0)
    return mask.getbbox()


def normalize_stage(image, stage):
    bbox = alpha_bbox(image)
    if bbox is None:
        raise RuntimeError(f"{stage} has no visible pixels after key removal")
    crop = image.crop(bbox)
    scale = min(TARGET_HEIGHTS[stage] / crop.height, TARGET_MAX_WIDTHS[stage] / crop.width)
    new_size = (max(1, int(crop.width * scale)), max(1, int(crop.height * scale)))
    resized = crop.resize(new_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    x = (1024 - resized.width) // 2
    y = (1024 - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def checkerboard(size, cell=24):
    img = Image.new("RGBA", size, (250, 248, 242, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2 == 0:
                draw.rectangle((x, y, x + cell, y + cell), fill=(240, 236, 226, 255))
    return img


def draw_background(draw, width, height):
    draw.rectangle((0, 0, width, height), fill=(248, 244, 234, 255))
    for x in range(0, width, 48):
        draw.line((x, 0, x, height), fill=(227, 218, 202, 70), width=1)
    for y in range(0, height, 48):
        draw.line((0, y, width, y), fill=(227, 218, 202, 60), width=1)


def make_flower_preview(flower, stage_images):
    preview = Image.new("RGBA", (2400, 900), (248, 244, 234, 255))
    draw = ImageDraw.Draw(preview, "RGBA")
    draw_background(draw, 2400, 900)
    draw.text((80, 50), f"Spring Meadow / {flower['slug']} / {flower['name']}", fill=(52, 45, 35, 255), font=font(54, True))
    draw.text((82, 124), "Watercolor line-art calibration, transparent PNG sources", fill=(120, 105, 85, 255), font=font(24))

    labels = [("seed", "种子"), ("sprout", "小芽"), ("bud", "花苞"), ("bloom", "绽放")]
    for index, (stage, zh) in enumerate(labels):
        left = 95 + index * 575
        top = 205
        card = (left, top, left + 485, top + 585)
        draw.rounded_rectangle((card[0] + 8, card[1] + 10, card[2] + 8, card[3] + 10), radius=34, fill=(80, 66, 44, 26))
        draw.rounded_rectangle(card, radius=34, fill=(255, 253, 247, 238), outline=(225, 212, 190, 255), width=2)
        tile = checkerboard((420, 420), 21)
        art = stage_images[stage].resize((420, 420), Image.Resampling.LANCZOS)
        tile.alpha_composite(art)
        preview.alpha_composite(tile, (left + 32, top + 74))
        draw.text((left + 34, top + 506), f"{stage} / {zh}", fill=(69, 92, 51, 255), font=font(34, True))
    return preview.convert("RGB")


def make_bloom_overview(processed):
    preview = Image.new("RGBA", (2400, 1500), (248, 244, 234, 255))
    draw = ImageDraw.Draw(preview, "RGBA")
    draw_background(draw, 2400, 1500)
    draw.text((80, 54), "Spring Meadow / Bloom overview", fill=(52, 45, 35, 255), font=font(58, True))
    draw.text((82, 132), "Nine ordinary flowers, hand-drawn watercolor line-art v2", fill=(120, 105, 85, 255), font=font(26))
    for index, flower in enumerate(FLOWERS):
        col = index % 3
        row = index // 3
        left = 110 + col * 750
        top = 230 + row * 390
        card = (left, top, left + 620, top + 320)
        draw.rounded_rectangle((card[0] + 8, card[1] + 10, card[2] + 8, card[3] + 10), radius=30, fill=(80, 66, 44, 24))
        draw.rounded_rectangle(card, radius=30, fill=(255, 253, 247, 238), outline=(225, 212, 190, 255), width=2)
        tile = checkerboard((240, 240), 18)
        art = processed[flower["slug"]]["bloom"].resize((240, 240), Image.Resampling.LANCZOS)
        tile.alpha_composite(art)
        preview.alpha_composite(tile, (left + 24, top + 40))
        draw.text((left + 292, top + 78), flower["name"], fill=(52, 45, 35, 255), font=font(38, True))
        draw.text((left + 292, top + 134), flower["slug"], fill=(87, 105, 70, 255), font=font(24))
    return preview.convert("RGB")


def validate(path):
    image = Image.open(path)
    if image.size != (1024, 1024):
        raise RuntimeError(f"{path} expected 1024x1024, got {image.size}")
    if image.mode != "RGBA":
        raise RuntimeError(f"{path} expected RGBA, got {image.mode}")
    corners = [image.getpixel((0, 0))[3], image.getpixel((1023, 0))[3], image.getpixel((0, 1023))[3], image.getpixel((1023, 1023))[3]]
    if corners != [0, 0, 0, 0]:
        raise RuntimeError(f"{path} has non-transparent corners: {corners}")
    bbox = alpha_bbox(image)
    if bbox is None:
        raise RuntimeError(f"{path} has no visible pixels")
    margin = min(bbox[0], bbox[1], 1024 - bbox[2], 1024 - bbox[3])
    if margin < 50:
        raise RuntimeError(f"{path} is too close to edge: bbox={bbox}")
    return bbox


def main():
    FLOWER_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    processed = {}
    report = []
    for flower in FLOWERS:
        slug = flower["slug"]
        processed[slug] = {}
        for stage in STAGES:
            source = SOURCE_DIR / f"{GARDEN_ID}_{slug}_{stage}_source.png"
            if not source.exists():
                raise FileNotFoundError(source)
            normalized = normalize_stage(remove_magenta_key(Image.open(source)), stage)
            out = FLOWER_DIR / f"{GARDEN_ID}_{slug}_{stage}.png"
            normalized.save(out, optimize=True)
            bbox = validate(out)
            processed[slug][stage] = normalized
            report.append(f"{out.relative_to(ROOT)}: 1024x1024 RGBA bbox={bbox}")

        preview = make_flower_preview(flower, processed[slug])
        preview_path = PREVIEW_DIR / f"preview_{GARDEN_ID}_{slug}_4stages.png"
        preview.save(preview_path, quality=92, optimize=True)
        report.append(f"{preview_path.relative_to(ROOT)}: 2400x900 RGB")

    overview = make_bloom_overview(processed)
    overview_path = PREVIEW_DIR / f"preview_{GARDEN_ID}_bloom_overview.png"
    overview.save(overview_path, quality=92, optimize=True)
    report.append(f"{overview_path.relative_to(ROOT)}: 2400x1500 RGB")

    report_path = PREVIEW_DIR / f"validation_{GARDEN_ID}.txt"
    report_path.write_text("\n".join(report) + "\n", encoding="utf-8")
    print("\n".join(report))


if __name__ == "__main__":
    main()

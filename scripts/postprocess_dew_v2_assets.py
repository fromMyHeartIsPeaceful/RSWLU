from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "IncomingArt" / "BuBuGardenAssets_v2"
SOURCE_DIR = ASSET_ROOT / "source"
FLOWER_DIR = ASSET_ROOT / "flowers" / "dew"
PREVIEW_DIR = ASSET_ROOT / "previews"

STAGES = ["seed", "sprout", "bud", "bloom"]
TARGET_HEIGHTS = {
    "seed": 430,
    "sprout": 650,
    "bud": 840,
    "bloom": 900,
}
TARGET_MAX_WIDTHS = {
    "seed": 430,
    "sprout": 660,
    "bud": 720,
    "bloom": 760,
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
                # Remove antialiased magenta fringe; the flower reds have much lower blue.
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
    target_h = TARGET_HEIGHTS[stage]
    target_w = TARGET_MAX_WIDTHS[stage]
    scale = min(target_h / crop.height, target_w / crop.width)
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


def make_preview(stage_images):
    preview = Image.new("RGBA", (2400, 900), (248, 244, 234, 255))
    draw = ImageDraw.Draw(preview, "RGBA")
    for x in range(0, 2400, 48):
        draw.line((x, 0, x, 900), fill=(227, 218, 202, 70), width=1)
    for y in range(0, 900, 48):
        draw.line((0, y, 2400, y), fill=(227, 218, 202, 60), width=1)

    draw.text((80, 50), "Dew Garden / Carnation hand-drawn v2", fill=(52, 45, 35, 255), font=font(54, True))
    draw.text((82, 124), "Watercolor line-art calibration sample, transparent PNG sources", fill=(120, 105, 85, 255), font=font(24))

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


def validate(path, expected=(1024, 1024)):
    image = Image.open(path)
    if image.size != expected:
        raise RuntimeError(f"{path} expected {expected}, got {image.size}")
    if image.mode != "RGBA":
        raise RuntimeError(f"{path} expected RGBA, got {image.mode}")
    corners = [
        image.getpixel((0, 0))[3],
        image.getpixel((expected[0] - 1, 0))[3],
        image.getpixel((0, expected[1] - 1))[3],
        image.getpixel((expected[0] - 1, expected[1] - 1))[3],
    ]
    if corners != [0, 0, 0, 0]:
        raise RuntimeError(f"{path} has non-transparent corners: {corners}")
    bbox = alpha_bbox(image)
    if bbox is None:
        raise RuntimeError(f"{path} has no visible pixels")
    left, top, right, bottom = bbox
    margin = min(left, top, expected[0] - right, expected[1] - bottom)
    if margin < 50:
        raise RuntimeError(f"{path} is too close to edge: bbox={bbox}")
    return bbox


def main():
    FLOWER_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    processed = {}
    report = []
    for stage in STAGES:
        source = SOURCE_DIR / f"dew_carnation_{stage}_source.png"
        if not source.exists():
            raise FileNotFoundError(source)
        keyed = remove_magenta_key(Image.open(source))
        normalized = normalize_stage(keyed, stage)
        out = FLOWER_DIR / f"dew_carnation_{stage}.png"
        normalized.save(out, optimize=True)
        bbox = validate(out)
        processed[stage] = normalized
        report.append(f"{out.relative_to(ROOT)}: 1024x1024 RGBA bbox={bbox}")

    preview = make_preview(processed)
    preview_path = PREVIEW_DIR / "preview_dew_carnation_4stages_v2.png"
    preview.save(preview_path, quality=92, optimize=True)
    report.append(f"{preview_path.relative_to(ROOT)}: 2400x900 RGB")

    report_path = PREVIEW_DIR / "validation_dew_carnation_v2.txt"
    report_path.write_text("\n".join(report) + "\n", encoding="utf-8")

    print("\n".join(report))


if __name__ == "__main__":
    main()

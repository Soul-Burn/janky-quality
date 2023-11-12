import os

from PIL import Image

gfx_path = os.path.expandvars("%programfiles(x86)%/Steam/steamapps/common/Factorio/data/core/graphics")

max_quality = 5
max_quality_modules = 3
bonuses = [0, 1, 2, 3, 5]

qualities = [Image.open(f"quality-{i + 1}.png") for i in range(max_quality)]
quality_modules = [Image.open(f"quality-module-{i + 1}.png") for i in range(max_quality_modules)]
black_background = Image.open(os.path.join(gfx_path, "entity-info-dark-background.png"))
nightvision = Image.open(os.path.join(gfx_path, "color_luts", "nightvision.png"))
day = Image.open(os.path.join(gfx_path, "color_luts", "identity-lut.png"))

for i, q in enumerate(qualities):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    scale = 32
    im.alpha_composite(q.resize((scale, scale)), (0, 64 - scale))
    im.save(f"quality-{i + 1}-overlay.png")

for i, qm in enumerate(quality_modules):
    for j, q in enumerate(qualities):
        im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        im.alpha_composite(black_background, (7, 1))
        im.alpha_composite(qm.resize((32, 32)), (18, 11))
        im.alpha_composite(q.resize((16, 16)), (19, 25))
        im.save(f"quality-module-{i + 1}@{j + 1}-overlay.png")

for i, b in enumerate(bonuses):
    im = Image.blend(nightvision, day, b / max(bonuses))
    im.save(f"nv-quality-{i + 1}.png")

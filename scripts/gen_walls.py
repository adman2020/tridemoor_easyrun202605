#!/usr/bin/env python3
"""Regenerate wall previews with proper contrast."""
from PIL import Image, ImageDraw, ImageFont
import os

src = r"D:\AI\StrideMoor\assets\badges\paojing"
out = r"D:\AI\StrideMoor\assets\badges\paojing"

order = ["气","筑","丹","婴","化","虚","合","乘","真","金","太","罗","道"]
names = ["炼气","筑基","结丹","元婴","化神","练虚","合体","大乘","真仙","金仙","太乙","大罗","道祖"]

for mode, label, title_color, bg_color in [
    ("lit", "点亮版", (255, 215, 0), (28, 25, 40)),
    ("dim", "虚化版", (140, 140, 160), (22, 20, 30)),
]:
    # Use 120px badges
    img_sz = 120
    cell = img_sz + 18
    pad = 6
    margin = 24

    row_w = 5 * cell + 4 * pad
    wall_w = max(4 * cell + 3 * pad + margin * 2, row_w + margin * 2)
    wall_h = 3 * (cell + pad) + margin * 2 + 50

    wall = Image.new("RGBA", (wall_w, wall_h), (*bg_color, 255))
    draw = ImageDraw.Draw(wall)

    fnt_t = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 16)
    fnt_s = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 10)
    fnt_tag = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 8)

    draw.text((wall_w // 2, 10), f"十三境 · 修仙勋章", fill=title_color, font=fnt_t, anchor="mt")
    draw.text((wall_w // 2, 30), f"气筑丹婴 化虚合乘 真金太罗道", fill=(90, 90, 110), font=fnt_tag, anchor="mt")

    for i, (ch, nm) in enumerate(zip(order, names)):
        fname = f"{ch}_{mode}_120.png"
        fpath = os.path.join(src, fname)
        if not os.path.exists(fpath):
            print(f"  MISSING: {fpath}")
            continue

        img = Image.open(fpath)

        if i < 4:  # row 0
            x = (wall_w - (4 * cell + 3 * pad)) // 2 + i * (cell + pad)
            y = margin + 38 + 0 * (cell + pad)
        elif i < 8:  # row 1
            x = (wall_w - (4 * cell + 3 * pad)) // 2 + (i - 4) * (cell + pad)
            y = margin + 38 + 1 * (cell + pad)
        else:  # row 2 - 5 items centered
            x = (wall_w - row_w) // 2 + (i - 8) * (cell + pad)
            y = margin + 38 + 2 * (cell + pad)

        cx = x + cell // 2
        cy = y + cell // 2

        # Subtle gold glow behind each badge cell
        for g in range(4, 0, -1):
            gc = (255, 200, 80, max(0, 3 - g))
            draw.rectangle([x - g, y - g, x + cell + g, y + cell + g], fill=gc)

        # Light card bg
        draw.rectangle([x, y, x + cell, y + cell], fill=(35, 32, 50, 255))

        # Place badge (centered in cell)
        bx = x + (cell - img_sz) // 2
        by = y + (cell - img_sz) // 2 - 2
        # Since images have solid bg, just paste directly
        wall.paste(img, (bx, by), img)

        # Label
        draw.text((x + cell // 2, y + cell - 4), nm, fill=(150, 150, 160), font=fnt_s, anchor="mb")

    path = os.path.join(src, f"wall_{mode}.png")
    wall.save(path)
    kb = os.path.getsize(path) // 1024
    print(f"wall_{mode}.png: {wall.size}, {kb}KB")
    w, h = wall.size
    print(f"  position check - 气 at y={margin+38+0}, 化 at y={margin+38+cell+pad}, 真 at y={margin+38+2*(cell+pad)}")

print("\n✅ Done")

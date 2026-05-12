#!/usr/bin/env python3
"""Resize Doubao badges and create compact wall preview."""
from PIL import Image, ImageDraw, ImageFont
import os, shutil

d = r"D:\AI\StrideMoor\assets\badges\paojing_200"

order = ["气","筑","丹","婴","化","虚","合","乘","真","金","太","罗","道"]
names = ["炼气","筑基","结丹","元婴","化神","练虚","合体","大乘","真仙","金仙","太乙","大罗","道祖"]

# Small individual versions
out_small = r"D:\AI\StrideMoor\assets\badges\paojing_small"
os.makedirs(out_small, exist_ok=True)
for ch in order:
    img = Image.open(os.path.join(d, f"{ch}_120.png"))
    for sz in [80, 100]:
        small = img.resize((sz, sz), Image.LANCZOS)
        small.save(os.path.join(out_small, f"{ch}_{sz}.png"))

print("Small individual badges done")

# Compact wall preview
cell = 118
pad = 8
margin = 20
cols = 4
rows = 4

wall_w = cols * cell + (cols - 1) * pad + margin * 2
wall_h = 3 * (cell + pad) + margin * 2 + 50

wall = Image.new("RGBA", (wall_w, wall_h), (10, 10, 20, 255))
draw = ImageDraw.Draw(wall)

font_t = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 18)
draw.text((wall_w // 2, 8), "十三境 · 修仙勋章", fill=(255, 215, 0), font=font_t, anchor="mt")

for i, (ch, nm) in enumerate(zip(order, names)):
    img = Image.open(os.path.join(d, f"{ch}_120.png"))
    iw = ih = 120
    
    if i < 4:
        x = margin + i * (cell + pad) + (cell - iw) // 2
        y = margin + 35 + 0 * (cell + pad) + (cell - ih) // 2
    elif i < 8:
        x = margin + (i - 4) * (cell + pad) + (cell - iw) // 2
        y = margin + 35 + 1 * (cell + pad) + (cell - ih) // 2
    else:
        row_w = 5 * cell + 4 * pad
        start_x = (wall_w - row_w) // 2
        x = start_x + (i - 8) * (cell + pad) + (cell - iw) // 2
        y = margin + 35 + 2 * (cell + pad) + (cell - ih) // 2
    
    # Small glow
    cx = x + iw // 2
    cy = y + ih // 2
    for g in range(3):
        draw.ellipse([cx-64-g, cy-64-g, cx+64+g, cy+64+g], fill=(255, 215, 0, max(0, 5 - g * 2)))
    
    wall.paste(img, (x, y), img)
    draw.text((cx, y + ih + 2), nm, fill=(130, 130, 140), font=ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 10), anchor="mt")

path = os.path.join(d, "wall_compact.png")
wall.save(path)
print(f"Wall: {wall.size}, {os.path.getsize(path)//1024}KB")

shutil.copy2(path, r"C:\Users\Administered\.openclaw\media\qqbot\wall_compact.png")
print("Copied to qqbot media")

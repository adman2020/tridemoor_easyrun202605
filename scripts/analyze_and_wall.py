#!/usr/bin/env python3
"""Create wall preview from Doubao images and analyze design."""
from PIL import Image, ImageDraw, ImageFont
import os, math

d = r"D:\AI\StrideMoor\assets\badges\paojing"
out = r"D:\AI\StrideMoor\assets\badges\paojing"

# Order: 气筑丹婴化虚合乘真金太罗道
order = ["气","筑","丹","婴","化","虚","合","乘","真","金","太","罗","道"]
names = ["炼气","筑基","结丹","元婴","化神","练虚","合体","大乘","真仙","金仙","太乙","大罗","道祖"]
elements = ["竹叶","石台","葫芦","莲台","祥云","飞剑","八卦","火焰","仙鹤","龙纹","凤凰","星辰","混沌"]

# Load images
imgs = {}
for ch in order:
    path = os.path.join(d, f"{ch}_lit.png")
    if os.path.exists(path):
        imgs[ch] = Image.open(path)
        print(f"  {ch}: {imgs[ch].size}")
    else:
        print(f"  {ch}: NOT FOUND")

# Crop to just the circular badge (remove dark edges), then resize
processed = []
for ch in order:
    img = imgs[ch]
    w, h = img.size
    cx, cy = w // 2, h // 2
    # Find radius - measure from center outward in multiple directions
    max_r = min(w, h) // 2 - 5
    # Use the radius where pixel differs from background
    # Since badges are full-frame, just crop to center square
    sq = min(w, h)
    x0 = (w - sq) // 2
    y0 = (h - sq) // 2
    crop = img.crop((x0, y0, x0 + sq, y0 + sq))
    # Resize to uniform 200x200
    resized = crop.resize((200, 200), Image.LANCZOS)
    processed.append(resized)

# Create wall preview (4+4+5 grid)
cols = 4
rows = 4
cell_w = 220
cell_h = 220
pad = 14
margin = 30
wall_w = cols * cell_w + (cols - 1) * pad + margin * 2
wall_h = 3 * cell_h + 2 * pad + margin * 2 + 60  # extra for header

wall = Image.new("RGBA", (wall_w, wall_h), (10, 10, 20, 255))
draw = ImageDraw.Draw(wall)

# Title
font_title = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 28)
draw.text((wall_w // 2, 14), "十三境 · 修仙勋章", fill=(255, 215, 0, 255), font=font_title, anchor="mt")

font_sub = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 14)
draw.text((wall_w // 2, 48), "气筑丹婴 化虚合乘 真金太罗道", fill=(100, 100, 120, 255), font=font_sub, anchor="mt")

# Place badges in 4+4+5 layout
positions_4x4 = [
    (0,0), (1,0), (2,0), (3,0),   # row 1: 气筑丹婴
    (0,1), (1,1), (2,1), (3,1),   # row 2: 化虚合乘
    (0,2), (1,2), (2,2), (3,2),   # row 3: 真金太罗
]

# 13th badge (道) - center column 1-2, row 3
# Actually let's do 4+4+5
# Row 1: 气筑丹婴 (4)
# Row 2: 化虚合乘 (4)  
# Row 3: 真金太罗道 (5) - centered

positions = []
for i in range(13):
    if i < 4:  # row 0
        x = margin + i * (cell_w + pad)
        y = margin + 65 + 0 * (cell_h + pad)
    elif i < 8:  # row 1
        x = margin + (i - 4) * (cell_w + pad)
        y = margin + 65 + 1 * (cell_h + pad)
    else:  # row 2 - 5 items centered
        row_width = 5 * cell_w + 4 * pad
        start_x = (wall_w - row_width) // 2
        x = start_x + (i - 8) * (cell_w + pad)
        y = margin + 65 + 2 * (cell_h + pad)
    positions.append((x, y))

for i, (ch, nm, el) in enumerate(zip(order, names, elements)):
    x, y = positions[i]
    img = processed[i]
    
    # Draw subtle glow behind
    for g in range(6, 0, -1):
        glow = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.ellipse([cell_w//2 - 80 - g, cell_h//2 - 80 - g, cell_w//2 + 80 + g, cell_h//2 + 80 + g], fill=(255, 215, 0, max(0, 8 - g)))
        wall.paste(glow, (x, y), glow)
    
    # Place badge centered in cell
    bx = x + (cell_w - 200) // 2
    by = y + (cell_h - 200) // 2
    wall.paste(img, (bx, by), img)
    
    # Label
    font_nm = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 16)
    font_el = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 11)
    draw.text((x + cell_w // 2, y + cell_h - 6), f"{nm} · {el}", fill=(160, 160, 170, 200), font=font_el, anchor="mb")

wall.save(os.path.join(out, "wall_preview.png"))
print(f"\nWall saved: {out}/wall_preview.png ({wall.size})")

# Also analyze colors more carefully
print("\n=== Color Palette Analysis ===")
for ch in order:
    img = imgs[ch]
    w, h = img.size
    # Sample border area (at 80% radius)
    cx, cy = w // 2, h // 2
    r = min(w, h) // 2
    
    # Get dominant edge/border color
    colors = {}
    for deg in range(0, 360, 5):
        rad = math.radians(deg)
        for dist in range(int(r * 0.85), int(r * 0.95)):
            px = cx + int(dist * math.cos(rad))
            py = cy + int(dist * math.sin(rad))
            if 0 <= px < w and 0 <= py < h:
                pr, pg, pb, pa = img.getpixel((px, py))
                # Quantize to 32-unit buckets
                key = (pr // 32, pg // 32, pb // 32)
                colors[key] = colors.get(key, 0) + 1
    
    sorted_colors = sorted(colors.items(), key=lambda x: -x[1])[:5]
    print(f"  [{ch}] Top border colors:")
    for (kr, kg, kb), cnt in sorted_colors:
        print(f"    RGB({kr*32},{kg*32},{kb*32}) ~ count={cnt}")

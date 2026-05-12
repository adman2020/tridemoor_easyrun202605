#!/usr/bin/env python3
"""Process all Doubao badges: resize + wall previews."""
from PIL import Image, ImageDraw, ImageFont
import os

src = r"D:\AI\StrideMoor\assets\badges\paojing"
out = r"D:\AI\StrideMoor\assets\badges\paojing"

order = ["气","筑","丹","婴","化","虚","合","乘","真","金","太","罗","道"]
names = ["炼气","筑基","结丹","元婴","化神","练虚","合体","大乘","真仙","金仙","太乙","大罗","道祖"]

# Process all 26 images
for ch in order:
    for mode, suffix in [("lit", "lit"), ("dim", "dim")]:
        path = os.path.join(src, f"{ch}_{suffix}.png")
        if not os.path.exists(path):
            print(f"  MISSING: {path}")
            continue
        
        img = Image.open(path)
        w, h = img.size
        sq = min(w, h)
        x0 = (w - sq) // 2
        y0 = (h - sq) // 2
        crop = img.crop((x0, y0, x0 + sq, y0 + sq))
        
        for sz in [80, 120, 160, 200]:
            resized = crop.resize((sz, sz), Image.LANCZOS)
            fname = f"{ch}_{suffix}_{sz}.png"
            resized.save(os.path.join(src, fname))
        
        orig_kb = os.path.getsize(path) / 1024
        print(f"  {ch}_{suffix}: {w}x{h} ({orig_kb:.0f}KB) → 4 sizes done")

print("\n--- Generating wall previews ---")

# Generate wall for lit and dim
for mode, label, title_color in [
    ("lit", "点亮版", (255, 215, 0)),
    ("dim", "虚化版", (100, 100, 100)),
]:
    # Layout: 4+4+5
    img_sz = 128
    cell = img_sz + 8
    pad = 6
    margin = 20
    
    # Row 3 has 5 items, centered
    row_w = 5 * cell + 4 * pad
    wall_w = max(4 * cell + 3 * pad + margin * 2, row_w + margin * 2)
    wall_h = 3 * (cell + pad) + margin * 2 + 45
    
    wall = Image.new("RGBA", (wall_w, wall_h), (10, 10, 20, 255))
    draw = ImageDraw.Draw(wall)
    
    fnt_t = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 20)
    fnt_s = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 10)
    draw.text((wall_w // 2, 8), f"十三境 · 修仙勋章 ({label})", fill=title_color, font=fnt_t, anchor="mt")
    
    for i, (ch, nm) in enumerate(zip(order, names)):
        fname = f"{ch}_{mode}_128.png"
        fpath = os.path.join(src, fname)
        if not os.path.exists(fpath):
            continue
        img = Image.open(fpath)
        ih = img.size[1]
        
        if i < 4:
            x = (wall_w - (4 * cell + 3 * pad)) // 2
            x += i * (cell + pad) + (cell - img_sz) // 2
            y = margin + 35 + 0 * (cell + pad) + (cell - ih) // 2
        elif i < 8:
            x = (wall_w - (4 * cell + 3 * pad)) // 2
            x += (i - 4) * (cell + pad) + (cell - img_sz) // 2
            y = margin + 35 + 1 * (cell + pad) + (cell - ih) // 2
        else:
            x = (wall_w - row_w) // 2
            x += (i - 8) * (cell + pad) + (cell - img_sz) // 2
            y = margin + 35 + 2 * (cell + pad) + (cell - ih) // 2
        
        cx = x + img_sz // 2
        for g in range(3):
            draw.ellipse([cx - 66 - g, y - 66 - g, cx + 66 + g, y + 66 + g],
                         fill=(255, 215, 0, max(0, 4 - g * 2)))
        wall.paste(img, (x, y), img)
        draw.text((cx, y + ih + 2), nm, fill=(130, 130, 140), font=fnt_s, anchor="mt")
    
    wall.save(os.path.join(src, f"wall_{mode}.png"))
    kb = os.path.getsize(os.path.join(src, f"wall_{mode}.png")) // 1024
    print(f"  wall_{mode}.png: {wall.size}, {kb}KB")

print("\n✅ All done!")

# Summary
print("\n=== File Summary ===")
for ch in order:
    sizes = []
    for mode in ["lit", "dim"]:
        for sz in [80, 120, 128, 160, 200]:
            fname = f"{ch}_{mode}_{sz}.png"
            fpath = os.path.join(src, fname)
            if os.path.exists(fpath):
                sizes.append(f"{mode}_{sz}")
    total_kb = sum(os.path.getsize(os.path.join(src, f"{ch}_{mode}_{sz}.png")) for mode in ["lit","dim"] for sz in [80,120,160] if os.path.exists(os.path.join(src, f"{ch}_{mode}_{sz}.png"))) / 1024
    print(f"  {ch}: {len(sizes)} versions, total ~{total_kb:.0f}KB for 3 sizes")

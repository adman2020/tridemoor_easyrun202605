#!/usr/bin/env python3
"""Generate avatar + badge corner mockup for different realms."""
from PIL import Image, ImageDraw, ImageFont
import os, math

src = r"D:\AI\StrideMoor\assets\badges\paojing"
out = r"D:\AI\StrideMoor\assets\badges\paojing"

# Create a fake avatar (colored circle with a letter)
def make_avatar(size=120, color=(50, 60, 180)):
    img = Image.new("RGBA", (size, size), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([0, 0, size, size], fill=(*color, 255))
    # User initial
    fnt = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", size//2)
    draw.text((size//2, size//2), "韩", fill=(255,255,255), font=fnt, anchor="mm")
    return img

# Badge corner sizes to test (relative to avatar)
BADGE_RATIOS = [0.30, 0.35, 0.40, 0.45]  # badge size / avatar size
AVATAR_SIZE = 160

# Test with different realms
test_realms = ["气", "气", "丹", "丹", "金", "道"]
test_states = ["lit", "dim", "lit", "dim", "lit", "lit"]
badge_sizes = [48, 48, 56, 56, 64, 72]  # various badge sizes

mockups = []
for ch, state, bsz in zip(test_realms, test_states, badge_sizes):
    # Badge
    bpath = os.path.join(src, f"{ch}_{state}_80.png")
    badge = Image.open(bpath).resize((bsz, bsz), Image.LANCZOS)
    
    # Avatar
    import random
    colors = [(50,60,180), (180,60,50), (50,150,80), (180,150,50), (100,50,180), (60,180,180)]
    avatar = make_avatar(AVATAR_SIZE, random.choice(colors))
    
    # Composite: avatar with badge at bottom-right corner
    canvas = Image.new("RGBA", (AVATAR_SIZE, AVATAR_SIZE), (0,0,0,0))
    
    # Avatar
    canvas.paste(avatar, (0, 0))
    
    # Badge overlapping bottom-right
    bx = AVATAR_SIZE - int(bsz * 0.55)
    by = AVATAR_SIZE - int(bsz * 0.55)
    
    # Optional white border ring behind badge
    draw = ImageDraw.Draw(canvas)
    br = int(bsz * 0.55)
    draw.ellipse([bx-2, by-2, bx+br*2+2, by+br*2+2], fill=(255,255,255,180))
    
    canvas.paste(badge, (bx, by), badge)
    mockups.append(canvas)

# Arrange in a row
gap = 10
total_w = AVATAR_SIZE * 6 + gap * 5
h = AVATAR_SIZE + 30
result = Image.new("RGBA", (total_w, h), (15, 15, 30, 255))
draw = ImageDraw.Draw(result)

for i, (canvas, ch, state, bsz) in enumerate(zip(mockups, test_realms, test_states, badge_sizes)):
    x = i * (AVATAR_SIZE + gap)
    result.paste(canvas, (x, 0), canvas)
    # Label
    fnt = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 11)
    label = f"{ch}境 {state} {bsz}px"
    draw.text((x + AVATAR_SIZE//2, AVATAR_SIZE + 6), label, fill=(150,150,160), font=fnt, anchor="mt")

result.save(os.path.join(src, "avatar_mockup.png"))
print(f"Avatar mockup: {result.size}")

# Also create a cleaner single example with dimensions
canvas = Image.new("RGBA", (200, 200), (20, 20, 40, 255))
av = make_avatar(160, (50, 60, 180))
canvas.paste(av, (20, 20))

badge = Image.open(os.path.join(src, "丹_lit_80.png")).resize((64, 64), Image.LANCZOS)
bx, by = 200 - 64 - 8, 200 - 64 - 8
# White ring
draw2 = ImageDraw.Draw(canvas)
draw2.ellipse([bx-3, by-3, bx+64+3, by+64+3], fill=(255,255,255,200))
# Shadow
draw2.ellipse([bx, by, bx+64, by+64], fill=(0,0,0,100))
canvas.paste(badge, (bx, by), badge)

# Dimension arrows
fnt = ImageFont.truetype("C:/Windows/Fonts/simkai.ttf", 9)
draw2.text((100, 0), "← 头像 160px →", fill=(100,100,120), font=fnt, anchor="mt")
draw2.text((150, 115), "64px", fill=(100,100,120), font=fnt, anchor="mm")

canvas.save(os.path.join(src, "avatar_single.png"))
print(f"Single example: {canvas.size}")

import shutil
shutil.copy2(os.path.join(src, "avatar_mockup.png"), r"C:\Users\Administered\.openclaw\media\qqbot\avatar_mockup.png")
shutil.copy2(os.path.join(src, "avatar_single.png"), r"C:\Users\Administered\.openclaw\media\qqbot\avatar_single.png")
print("Copied to qqbot media")

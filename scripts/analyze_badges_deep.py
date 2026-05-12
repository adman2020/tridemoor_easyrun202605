#!/usr/bin/env python3
"""Deep analysis of Doubao badges - shape, colors, design elements."""
from PIL import Image
import os, json

d = r"D:\AI\StrideMoor\assets\badges\paojing"

for f in sorted(os.listdir(d)):
    if not f.endswith(".png"): continue
    img = Image.open(os.path.join(d, f))
    w, h = img.size
    cx, cy = w // 2, h // 2
    ch = f[:-8]  # character name
    
    # Find the badge bounding box (where color differs from background)
    # Check a vertical and horizontal strip through center
    # Non-dark pixels indicate badge area
    
    # Analyze the shape by looking at alpha values and non-background pixels
    # Look at specific scanlines
    print(f"=== {ch} ({w}x{h}) ===")
    
    # Find badge extent horizontally at center
    left_bound = 0
    for x in range(0, cx):
        r, g, b, a = img.getpixel((x, cy))
        if r > 30 or g > 30 or b > 30:
            if left_bound == 0:
                left_bound = x
            break
    
    right_bound = w
    for x in range(w-1, cx, -1):
        r, g, b, a = img.getpixel((x, cy))
        if r > 30 or g > 30 or b > 30:
            right_bound = x
            break
    
    # Find top/bottom bounds
    top_bound = 0
    for y in range(0, cy):
        r, g, b, a = img.getpixel((cx, y))
        if r > 25 or g > 25 or b > 25:
            top_bound = y
            break
    
    bottom_bound = h
    for y in range(h-1, cy, -1):
        r, g, b, a = img.getpixel((cx, y))
        if r > 25 or g > 25 or b > 25:
            bottom_bound = y
            break
    
    badge_w = right_bound - left_bound
    badge_h = bottom_bound - top_bound
    
    print(f"  Badge bounding box: ({left_bound},{top_bound}) to ({right_bound},{bottom_bound}) = {badge_w}x{badge_h}")
    
    # Ratio
    max_dim = max(badge_w, badge_h)
    min_dim = min(badge_w, badge_h)
    print(f"  Aspect ratio: {badge_w/badge_h:.2f}, near-square: {min_dim/max_dim:.2%}")
    
    # Check if round vs petal shape by examining edge pixels at angles
    # Sample at 8 angles
    angles = []
    for deg in range(0, 360, 45):
        rad = __import__("math").radians(deg)
        # Walk inward from edge
        max_r = min(w, h) // 2 - 10
        r_idx = max_r
        for ri in range(max_r, 0, -3):
            px = cx + int(ri * __import__("math").cos(rad))
            py = cy + int(ri * __import__("math").sin(rad))
            if 0 <= px < w and 0 <= py < h:
                pr, pg, pb, pa = img.getpixel((px, py))
                if pr > 50 or pg > 50 or pb > 50:
                    r_idx = ri
                    break
        angles.append(r_idx)
    
    print(f"  Radii at 8 angles: {angles}")
    print(f"  Max radius: {max(angles)}, Min radius: {min(angles)}, Ratio: {min(angles)/max(angles):.2%}")
    
    # Sample color palette (dominant colors)
    # Get center area average
    area_size = 40
    r_sum = g_sum = b_sum = 0
    count = 0
    for x in range(cx-area_size, cx+area_size):
        for y in range(cy-area_size, cy+area_size):
            if 0 <= x < w and 0 <= y < h:
                pr, pg, pb, pa = img.getpixel((x, y))
                r_sum += pr; g_sum += pg; b_sum += pb
                count += 1
    print(f"  Center avg: RGB({r_sum//count},{g_sum//count},{b_sum//count})")
    
    # Edge dominant color
    e_sum_r = e_sum_g = e_sum_b = 0
    e_count = 0
    for deg in range(0, 360, 10):
        rad = __import__("math").radians(deg)
        ri = min(angles[deg//45 if deg%45==0 else deg//45], 
                 angles[(deg+45)//45 if (deg+45)//45 < 8 else 0])
        # Sample just inside
        ri = max(1, ri - 20)
        px = cx + int(ri * __import__("math").cos(rad))
        py = cy + int(ri * __import__("math").sin(rad))
        if 0 <= px < w and 0 <= py < h:
            pr, pg, pb, pa = img.getpixel((px, py))
            e_sum_r += pr; e_sum_g += pg; e_sum_b += pb
            e_count += 1
    print(f"  Edge avg: RGB({e_sum_r//e_count},{e_sum_g//e_count},{e_sum_b//e_count})")
    print()

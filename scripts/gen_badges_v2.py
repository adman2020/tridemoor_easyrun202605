#!/usr/bin/env python3
"""
Generate 12 Chinese-style realm badges with 国潮质感 + 金属立体感.
Each realm has unique shape and symbolic elements from 凡人修仙传.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import os, math, random

OUT = "D:/AI/StrideMoor/assets/badges/png_v2"
os.makedirs(OUT, exist_ok=True)

# Each realm: (char, name, shape, main_color, accent_color, element)
# 国潮色系: 朱砂红/琥珀金/松石绿/藏蓝/丁香紫/赤金
REALMS = [
    ("炼", "炼气", "circle",     (123,166,132),  (90,107,92),    "竹叶"),      # 灰绿 - 入门
    ("丹", "结丹", "hexagon",    (74,155,110),   (184,115,51),   "葫芦"),      # 铜绿 - 筑基
    ("婴", "元婴", "octagon",    (74,144,217),   (192,192,192),  "莲台"),      # 银蓝 - 成婴
    ("化", "化神", "circle",     (43,94,167),    (255,215,0),    "祥云"),      # 藏蓝金 - 化神
    ("虚", "练虚", "shield",     (108,63,197),   (255,193,37),   "飞剑"),      # 紫金 - 炼虚
    ("合", "合体", "diamond",    (139,58,139),   (218,165,32),   "八卦"),      # 绛紫 - 合体
    ("乘", "大乘", "circle",     (210,105,30),   (205,92,28),    "火焰"),      # 赤橙 - 大乘
    ("真", "真仙", "hexagon",    (255,140,0),    (255,215,0),    "仙鹤"),      # 琥珀金 - 真仙
    ("金", "金仙", "shield",     (218,165,32),   (255,69,0),     "龙纹"),      # 赤金 - 金仙
    ("太", "太乙", "octagon",    (220,20,60),    (255,105,180),  "凤凰"),      # 朱砂红 - 太乙
    ("罗", "大罗", "circle",     (184,134,11),   (255,215,0),    "星辰"),      # 暗金 - 大罗
    ("道", "道祖", "sun_moon",   (26,26,46),     (255,248,220),  "混沌"),      # 玄底白 - 道祖
]

def hex_to_rgb(h):
    if isinstance(h, tuple): return h
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0,2,4))

def lighten(color, factor=1.3):
    return tuple(min(255, int(c*factor)) for c in color)

def darken(color, factor=0.7):
    return tuple(max(0, int(c*factor)) for c in color)

def draw_circle(draw, cx, cy, r, fill=None, outline=None, width=1):
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=outline, width=width)

def draw_regular_polygon(draw, cx, cy, r, sides, rotation=0, fill=None, outline=None, width=1):
    """Draw a regular polygon."""
    points = []
    for i in range(sides):
        angle = math.radians(rotation + i * 360 / sides - 90)
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill=fill, outline=outline, width=width)

def draw_shield(draw, cx, cy, r, fill=None, outline=None, width=1):
    """Draw a shield shape."""
    points = []
    for i in range(60):
        angle = math.radians(i * 6 - 90)
        # Shield: top flat, curved bottom
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle) * 0.85
        # Make top flat
        if y < cy - r * 0.5:
            y = cy - r * 0.5
        points.append((x, y))
    draw.polygon(points, fill=fill, outline=outline, width=width)

def draw_sun_moon(draw, cx, cy, r, fill=None, outline=None, width=1):
    """Draw a sun-moon interlocking shape (太极 variant)."""
    # Left half (sun)
    points_l = []
    for i in range(36):
        angle = math.radians(i * 10 + 90)
        x = cx + r * math.cos(angle) * 0.9
        y = cy + r * math.sin(angle) * 0.9
        points_l.append((x, y))
    for i in range(36):
        angle = math.radians(i * 10 - 90)
        x = cx - r * 0.4 + r * 0.7 * math.cos(angle)
        y = cy + r * 0.7 * math.sin(angle)
        points_l.append((x, y))
    # Right half
    points_r = []
    for i in range(36):
        angle = math.radians(i * 10 - 90)
        x = cx + r * math.cos(angle) * 0.9
        y = cy + r * math.sin(angle) * 0.9
        points_r.append((x, y))
    for i in range(36):
        angle = math.radians(i * 10 + 90)
        x = cx + r * 0.4 + r * 0.7 * math.cos(angle)
        y = cy + r * 0.7 * math.sin(angle)
        points_r.append((x, y))

def add_metallic_shine(draw, cx, cy, r, color):
    """Add highlight gradient for metallic look."""
    for i in range(5):
        y_off = cy - r * 0.3 - i * 4
        h_r = int(r * (1 - i * 0.15))
        highlight = (*lighten(color, 1.6), max(0, 80 - i * 20))
        draw.ellipse([cx-h_r, y_off-h_r//3, cx+h_r, y_off+h_r//3],
                     fill=highlight)

def add_chinese_cloud(draw, x, y, scale=1.0, color=(255,215,0), alpha=60):
    """Draw a traditional Chinese cloud pattern."""
    s = scale
    # Cloud top
    draw.ellipse([x-15*s, y-8*s, x-5*s, y+2*s], fill=(*color, alpha))
    draw.ellipse([x-3*s, y-12*s, x+8*s, y-2*s], fill=(*color, alpha))
    draw.ellipse([x+6*s, y-8*s, x+16*s, y+2*s], fill=(*color, alpha))
    # Cloud tail
    draw.rectangle([x-12*s, y-2*s, x+12*s, y+4*s], fill=(*color, alpha))

def add_ring_pattern(draw, cx, cy, r, color, alpha=40):
    """Add decorative ring pattern around the badge."""
    # Dots at compass directions
    for ang in [0, 90, 180, 270]:
        rad = math.radians(ang)
        dx = cx + (r-2) * math.cos(rad)
        dy = cy + (r-2) * math.sin(rad)
        draw.ellipse([dx-3, dy-3, dx+3, dy+3], fill=(*color, alpha))

def make_badge(ch, name, bg, accent, dim=False, size=160):
    size = size
    sz = (size, size)
    base = Image.new('RGBA', sz, (0,0,0,0))
    draw = ImageDraw.Draw(base)
    cx = cy = size // 2
    r = size // 2 - 8

    # ============ DIM VERSION ============
    if dim:
        gray = (136, 136, 136)
        # Outer border
        draw.ellipse([2,2,size-2,size-2], outline=(*gray, 40), width=2)
        # Inner
        draw.ellipse([8,8,size-8,size-8], outline=(*gray, 20), width=1)
        # Fill
        draw.ellipse([12,12,size-12,size-12], fill=(*gray, 10))
        # Character
        font = ImageFont.truetype('C:/Windows/Fonts/simkai.ttf', 52)
        bbox = draw.textbbox((0,0), ch, font=font)
        tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
        draw.text((cx-tw/2, cy-th/2+2), ch, fill=(*gray, 45), font=font)
        return base

    # ============ LIT VERSION ============
    bg_dark = darken(bg, 0.7)
    bg_light = lighten(bg, 1.4)
    accent_light = lighten(accent, 1.5)

    # === Layer 1: Outer glow ===
    for i in range(15, 0, -1):
        glow_r = cx - i - 2
        a = int(12 - i * 0.7)
        if a > 0:
            draw.ellipse([cx-glow_r, cy-glow_r, cx+glow_r, cy+glow_r],
                         outline=(*accent, a), width=1)

    # === Layer 2: Main background (metallic gradient) ===
    for y_off in range(int(-r*0.6), int(r*0.6)):
        t = (y_off + r*0.6) / (r*1.2)
        # Metallic gradient: darker edges, brighter center-top
        factor = 1.0 + 0.6 * math.exp(-((y_off/r)**2)*3) - 0.3 * abs(y_off)/r
        r_col = min(255, int(bg[0] * factor))
        g_col = min(255, int(bg[1] * factor))
        b_col = min(255, int(bg[2] * factor))
        y_pos = cy + int(y_off)
        line_r = int(r * math.sqrt(1 - (y_off/r)**2))
        if line_r > 0:
            draw.line([(cx-line_r, y_pos), (cx+line_r, y_pos)],
                     fill=(r_col, g_col, b_col, 220))

    # === Layer 3: Inner highlight ===
    add_metallic_shine(draw, cx, cy, r, accent)

    # === Layer 4: Decorative rings ===
    # Outer ring
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], outline=accent, width=3)
    # Inner dashed ring
    for i in range(0, 360, 8):
        s_rad = math.radians(i)
        e_rad = math.radians(min(i+5, 360))
        r_inner = r - 10
        xs = cx + r_inner * math.cos(s_rad)
        ys = cy + r_inner * math.sin(s_rad)
        xe = cx + r_inner * math.cos(e_rad)
        ye = cy + r_inner * math.sin(e_rad)
        draw.line([(xs,ys),(xe,ye)], fill=(*accent, 100), width=1)

    # === Layer 5: Compass dots (Chinese 四象) ===
    add_ring_pattern(draw, cx, cy, r, accent, 80)

    # === Layer 6: Background pattern (subtle) ===
    # Radial lines
    for i in range(0, 360, 15):
        rad = math.radians(i)
        x1 = cx + (r-12) * math.cos(rad)
        y1 = cy + (r-12) * math.sin(rad)
        x2 = cx + (r-3) * math.cos(rad)
        y2 = cy + (r-3) * math.sin(rad)
        draw.line([(x1,y1),(x2,y2)], fill=(*accent, 25), width=1)

    # === Layer 7: Cloud ornaments ===
    add_chinese_cloud(draw, cx, cy - r*0.65, 1.2, accent, 50)

    # === Layer 8: Character with metallic shadow ===
    font = ImageFont.truetype('C:/Windows/Fonts/simkai.ttf', 56)
    bbox = draw.textbbox((0,0), ch, font=font)
    tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
    # Shadow
    draw.text((cx-tw/2+2, cy-th/2+2), ch, fill=(0,0,0,100), font=font)
    # Main character
    draw.text((cx-tw/2, cy-th/2), ch, fill=accent, font=font)
    # Highlight on character
    draw.text((cx-tw/2-1, cy-th/2-1), ch, fill=accent_light, font=font)

    # === Layer 9: Name label ===
    font_sm = ImageFont.truetype('C:/Windows/Fonts/simkai.ttf', 11)
    bbox2 = draw.textbbox((0,0), name, font=font_sm)
    tw2 = bbox2[2]-bbox2[0]
    draw.text((cx-tw2/2, cy + r*0.55), name, fill=(*accent, 180), font=font_sm)

    return base


# Generate individual badges
for ch, name, shape, bg, accent, element in REALMS:
    for dim in [False, True]:
        mode = 'dim' if dim else 'lit'
        img = make_badge(ch, name, bg, accent, dim=dim, size=160)
        img.save(f'{OUT}/{ch}_{mode}.png')
    print(f'  {ch} {name}')

# ============ GRID ============
cols, rows = 4, 3
pad = 12
cell = 160 + 30  # badge + label
w = cols * cell + (cols-1)*pad + 40
h = rows * cell + (rows-1)*pad + 40

for mode_name, dim in [('点亮', False), ('虚化', True)]:
    canvas = Image.new('RGBA', (w, h), (15, 15, 30, 255))
    for idx, (ch, name, shape, bg, accent, element) in enumerate(REALMS):
        col = idx % cols
        row = idx // cols
        x = 20 + col * (cell + pad)
        y = 20 + row * (cell + pad)
        badge = make_badge(ch, name, bg, accent, dim=dim, size=160)
        canvas.paste(badge, (x + (cell-160)//2, y), badge)
    canvas.save(f'{OUT}/grid_{mode_name}.png')
    print(f'  grid {mode_name} {canvas.size}')

# ============ WALL (like Huawei style) ============
# Dark background, bigger, showing all 12 in 4x3
ww, wh = 700, 900
wall = Image.new('RGBA', (ww, wh), (18, 18, 28, 255))
draw_wall = ImageDraw.Draw(wall)

# Grid on wall
cols_w, rows_w = 3, 4
cell_w = 180
cell_h = 200
gap_x = (ww - cols_w * cell_w) // (cols_w + 1)
gap_y = (wh - rows_w * cell_h) // (rows_w + 1)

# Title
font_title = ImageFont.truetype('C:/Windows/Fonts/simkai.ttf', 28)
draw_wall.text((ww//2, 45), '十二修炼境界 · 勋章墙', fill=(255,215,0,220), font=font_title, anchor='mm')

# Subtitle
font_sub = ImageFont.truetype('C:/Windows/Fonts/simsun.ttc', 14)
draw_wall.text((ww//2, 78), '不积跬步，无以至千里；不积小流，无以成江海', fill=(150,150,180,120), font=font_sub, anchor='mm')

for idx, (ch, name, shape, bg, accent, element) in enumerate(REALMS):
    col = idx % 3
    row = idx // 3
    x = gap_x + col * (cell_w + gap_x)
    y = gap_y + row * (cell_h + gap_y) + 60
    # Badge
    badge = make_badge(ch, name, bg, accent, dim=False, size=130)
    bx = x + (cell_w - 130)//2
    wall.paste(badge, (bx, y), badge)
    # Label
    font_l = ImageFont.truetype('C:/Windows/Fonts/simkai.ttf', 16)
    draw_wall.text((x + cell_w//2, y + 155), f'「{ch}」{name}', fill=(200,200,200,180), font=font_l, anchor='mm')
    font_s = ImageFont.truetype('C:/Windows/Fonts/simsun.ttc', 10)
    draw_wall.text((x + cell_w//2, y + 178), f'· {element} ·', fill=(136,136,150,80), font=font_s, anchor='mm')

wall.save(f'{OUT}/wall.png')
print(f'  wall.png {wall.size}')

print('\nDone!')

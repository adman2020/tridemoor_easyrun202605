#!/usr/bin/env python3
"""13 realm badges in 国潮仙侠 style (eight-petal lotus shape)."""
import os, math

OUT = "D:/AI/StrideMoor/assets/badges/v3"
os.makedirs(f"{OUT}/svg", exist_ok=True)
os.makedirs(f"{OUT}/png", exist_ok=True)

# 13 realms: (char, name, medal_name, border, bg_top, bg_bot, accent, element, shape_style)
# Colors chosen to match the reference images' progressive palette
REALMS = [
    ("气", "炼气", "气引勋章", "#5A7D5A", "#7BA684", "#3D5C3D", "#9BC4A0", "竹叶", "jade"),
    ("筑", "筑基", "筑仙勋章", "#8B7D5A", "#C4A35A", "#6B5D3A", "#D4C47A", "石台", "copper"),
    ("丹", "结丹", "丹凝勋章", "#B87333", "#4A9B6E", "#2A6B4E", "#6BC48A", "葫芦", "bronze"),
    ("婴", "元婴", "婴生勋章", "#C0C0C0", "#4A90D9", "#2A60A9", "#7AB8F0", "莲台", "silver"),
    ("化", "化神", "化神勋章", "#FFD700", "#2B5EA7", "#1B3E77", "#5A8FE0", "祥云", "gold"),
    ("虚", "练虚", "炼虚勋章", "#FFC125", "#6C3FC5", "#4C2F95", "#9B6EE8", "飞剑", "purple_gold"),
    ("合", "合体", "合元勋章", "#DAA520", "#8B3A8B", "#5B2A5B", "#B55AB5", "八卦", "royal"),
    ("乘", "大乘", "大乘勋章", "#CD5C1C", "#D2691E", "#A2490E", "#E88A45", "火焰", "blaze"),
    ("真", "真仙", "真仙勋章", "#FFD700", "#FF8C00", "#CC6C00", "#FFB347", "仙鹤", "amber"),
    ("金", "金仙", "金仙勋章", "#FF4500", "#DAA520", "#AA8510", "#F0C75E", "龙纹", "radiant"),
    ("太", "太乙", "太乙勋章", "#FF69B4", "#DC143C", "#AC0430", "#FF4D6D", "凤凰", "crimson"),
    ("罗", "大罗", "大罗勋章", "#FFD700", "#B8860B", "#886608", "#D4A847", "星辰", "dark_gold"),
    ("道", "道祖", "道祖勋章", "#FFF8DC", "#1A1A2E", "#0A0A1E", "#E8D5B7", "混沌", "cosmic"),
]

def gen_eight_petal_svg(ch, name, medal, border, bg_t, bg_b, accent, element, style, dim=False, sz=160):
    """Generate SVG for one badge in eight-petal lotus shape."""
    cx = cy = sz // 2
    r = sz // 2 - 4
    
    # Build eight-petal path
    petals = []
    for i in range(8):
        a1 = math.radians(i * 45 - 22.5)
        a2 = math.radians(i * 45)
        a3 = math.radians(i * 45 + 22.5)
        # Outer point
        x1 = cx + r * math.cos(a1)
        y1 = cy + r * math.sin(a1)
        # Control point (bulge)
        bulge = r * 1.08
        xc = cx + bulge * math.cos(a2)
        yc = cy + bulge * math.sin(a2)
        # Next outer point
        x2 = cx + r * math.cos(a3)
        y2 = cy + r * math.sin(a3)
        
        if i == 0:
            petals.append(f"M{x1:.1f},{y1:.1f}")
        petals.append(f"Q{xc:.1f},{yc:.1f} {x2:.1f},{y2:.1f}")
    
    outer_path = " ".join(petals) + " Z"
    
    # Inner petal (inset)
    ri = r - 6
    petals_i = []
    for i in range(8):
        a1 = math.radians(i * 45 - 22.5)
        a2 = math.radians(i * 45)
        a3 = math.radians(i * 45 + 22.5)
        x1 = cx + ri * math.cos(a1)
        y1 = cy + ri * math.sin(a1)
        bulge = ri * 1.06
        xc = cx + bulge * math.cos(a2)
        yc = cy + bulge * math.sin(a2)
        x2 = cx + ri * math.cos(a3)
        y2 = cy + ri * math.sin(a3)
        if i == 0:
            petals_i.append(f"M{x1:.1f},{y1:.1f}")
        petals_i.append(f"Q{xc:.1f},{yc:.1f} {x2:.1f},{y2:.1f}")
    inner_path = " ".join(petals_i) + " Z"
    
    # Decorative dots between petals
    dots = ""
    for i in range(8):
        a = math.radians(i * 45)
        dx = cx + (r + 2) * math.cos(a)
        dy = cy + (r + 2) * math.sin(a)
        if dim:
            dots += f'<circle cx="{dx:.1f}" cy="{dy:.1f}" r="2" fill="#888" opacity="0.2"/>\n  '
        else:
            dots += f'<circle cx="{dx:.1f}" cy="{dy:.1f}" r="2.5" fill="{border}" opacity="0.8"/>\n  '
    
    if dim:
        # DIM version
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {sz} {sz}" width="{sz}" height="{sz}">
  <defs>
    <filter id="dim_shadow"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-color="#000" flood-opacity="0.1"/></filter>
  </defs>
  <path d="{outer_path}" fill="none" stroke="#888" stroke-width="2" opacity="0.25"/>
  <path d="{inner_path}" fill="#666" opacity="0.08"/>
  <path d="{inner_path}" fill="none" stroke="#888" stroke-width="0.8" opacity="0.15"/>
  {dots}
  <text x="{cx}" y="{cy+8}" font-family="KaiTi,STKaiti,serif" font-size="52" font-weight="bold"
        fill="#999" text-anchor="middle" opacity="0.25" filter="url(#dim_shadow)">{ch}</text>
  <text x="{cx}" y="{cy+r-8}" font-family="KaiTi,STKaiti,serif" font-size="8"
        fill="#999" text-anchor="middle" opacity="0.12">{medal}</text>
</svg>'''
    
    # === LIT VERSION ===
    # Bottom decoration elements (cloud, flame, lotus etc.)
    bottom_deco = ""
    if element == "竹叶":
        bottom_deco = f'<path d="M{cx-25},{cy+r-30} Q{cx-5},{cy+r-45} {cx+5},{cy+r-25} Q{cx+15},{cy+r-35} {cx+30},{cy+r-28}" fill="none" stroke="{accent}" stroke-width="1.5" opacity="0.4"/>'
    elif element == "石台":
        bottom_deco = f'<rect x="{cx-20}" y="{cy+r-30}" width="40" height="8" rx="2" fill="{accent}" opacity="0.3"/>'
    elif element == "葫芦":
        bottom_deco = f'<ellipse cx="{cx}" cy="{cy+r-22}" rx="8" ry="12" fill="none" stroke="{accent}" stroke-width="1.5" opacity="0.35"/>'
    elif element == "莲台":
        bottom_deco = f'<path d="M{cx-18},{cy+r-20} Q{cx},{cy+r-35} {cx+18},{cy+r-20}" fill="none" stroke="{accent}" stroke-width="1.5" opacity="0.4"/>'
    elif element == "祥云":
        bottom_deco = f'<path d="M{cx-22},{cy+r-22} Q{cx-12},{cy+r-32} {cx},{cy+r-22} Q{cx+12},{cy+r-32} {cx+22},{cy+r-22}" fill="none" stroke="{accent}" stroke-width="1.5" opacity="0.4"/>'
    elif element == "飞剑":
        bottom_deco = f'<line x1="{cx-15}" y1="{cy+r-15}" x2="{cx+15}" y2="{cy+r-25}" stroke="{accent}" stroke-width="2" opacity="0.4"/>'
    elif element == "八卦":
        bottom_deco = f'<circle cx="{cx}" cy="{cy+r-20}" r="10" fill="none" stroke="{accent}" stroke-width="1" opacity="0.3"/>'
    elif element == "火焰":
        bottom_deco = f'<path d="M{cx-12},{cy+r-15} Q{cx-5},{cy+r-30} {cx},{cy+r-18} Q{cx+5},{cy+r-30} {cx+12},{cy+r-15}" fill="{accent}" opacity="0.25"/>'
    elif element == "仙鹤":
        bottom_deco = f'<path d="M{cx-20},{cy+r-18} Q{cx-8},{cy+r-30} {cx+5},{cy+r-22} Q{cx+15},{cy+r-28} {cx+22},{cy+r-20}" fill="none" stroke="{accent}" stroke-width="1.5" opacity="0.35"/>'
    elif element == "龙纹":
        bottom_deco = f'<path d="M{cx-22},{cy+r-18} C{cx-10},{cy+r-30} {cx+10},{cy+r-30} {cx+22},{cy+r-18}" fill="none" stroke="{accent}" stroke-width="1.5" opacity="0.35"/>'
    elif element == "星辰":
        bottom_deco = f'<circle cx="{cx}" cy="{cy+r-20}" r="3" fill="{accent}" opacity="0.4"/>'
        for i in range(4):
            a = math.radians(i*90 + 45)
            sx = cx + 10*math.cos(a)
            sy = cy+r-20 + 10*math.sin(a)
            bottom_deco += f'<circle cx="{sx:.1f}" cy="{sy:.1f}" r="1.5" fill="{accent}" opacity="0.3"/>'

    # Radial gradient for background
    grad_id = f"bg_{ch}"
    
    # Ornamental effects - subtle particles on higher realms
    particles = ""
    if style in ["gold", "purple_gold", "royal", "blaze", "amber", "radiant", "crimson", "dark_gold", "cosmic"]:
        for i in range(3):
            a = math.radians(i*120 + 15)
            px = cx + (r-10) * math.cos(a)
            py = cy - 15 + (r-15) * math.sin(a)
            particles += f'<circle cx="{px:.1f}" cy="{py:.1f}" r="1.5" fill="{accent}" opacity="0.5"/>\n  '
    
    # Glow effect
    glow = ""
    if style in ["gold", "purple_gold", "royal", "amber", "radiant", "crimson", "dark_gold", "cosmic"]:
        glow = f'<path d="{outer_path}" fill="none" stroke="{border}" stroke-width="4" opacity="0.15" filter="url(#glow_filter)"/>'
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {sz} {sz}" width="{sz}" height="{sz}">
  <defs>
    <radialGradient id="{grad_id}" cx="45%" cy="40%" r="65%">
      <stop offset="0%" stop-color="{bg_t}" stop-opacity="0.95"/>
      <stop offset="60%" stop-color="{bg_t}" stop-opacity="0.9"/>
      <stop offset="100%" stop-color="{bg_b}" stop-opacity="1"/>
    </radialGradient>
    <filter id="g_{ch}">
      <feGaussianBlur stdDeviation="2" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <filter id="glow_filter">
      <feGaussianBlur stdDeviation="6"/>
    </filter>
    <filter id="text_shadow">
      <feDropShadow dx="1" dy="2" stdDeviation="2" flood-color="#000" flood-opacity="0.5"/>
    </filter>
  </defs>
  
  {glow}
  
  <!-- Outer petal border -->
  <path d="{outer_path}" fill="url(#{grad_id})" stroke="{border}" stroke-width="2.5"/>
  
  <!-- Inner petal highlight -->
  <path d="{inner_path}" fill="none" stroke="{accent}" stroke-width="0.8" opacity="0.4"/>
  
  <!-- Inner decorative ring (dashed) -->
  <path d="{inner_path}" fill="none" stroke="{border}" stroke-width="1" stroke-dasharray="3,3" opacity="0.3"/>
  
  <!-- Decorative dots between petals -->
  {dots}
  
  <!-- Particle effects -->
  {particles}
  
  <!-- Bottom decoration element -->
  {bottom_deco}
  
  <!-- Character with shadow and glow -->
  <text x="{cx}" y="{cy+8}" font-family="KaiTi,STKaiti,serif" font-size="56" font-weight="bold"
        fill="{border}" text-anchor="middle" filter="url(#text_shadow)" dominant-baseline="central">{ch}</text>
  
  <!-- Medal name -->
  <text x="{cx}" y="{cy+r-12}" font-family="KaiTi,STKaiti,serif" font-size="9" font-weight="bold"
        fill="{accent}" text-anchor="middle" opacity="0.7" letter-spacing="1">{medal}</text>
</svg>'''


# Generate SVGs
for ch, name, medal, border, bg_t, bg_b, accent, element, style in REALMS:
    for dim in [False, True]:
        mode = "dim" if dim else "lit"
        svg = gen_eight_petal_svg(ch, name, medal, border, bg_t, bg_b, accent, element, style, dim=dim)
        with open(f"{OUT}/svg/{ch}_{mode}.svg", "w", encoding="utf-8") as f:
            f.write(svg)
    print(f"  {ch} {name}")

# Generate preview HTML
chars = [r[0] for r in REALMS]
names = [r[1] for r in REALMS]
medals = [r[2] for r in REALMS]

html = '''<!DOCTYPE html>
<html lang="zh">
<head><meta charset="UTF-8"><title>十三境 · 修仙勋章</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;padding:40px;font-family:KaiTi,STKaiti,serif}
h1{color:#FFD700;text-align:center;font-size:32px;margin-bottom:6px}
.sub{color:#667;text-align:center;font-size:14px;margin-bottom:8px}
.tag{color:#445;text-align:center;font-size:12px;margin-bottom:30px}
.tag span{display:inline-block;margin:0 4px;padding:2px 8px;border:1px solid #445;border-radius:10px;color:#667}
h3{text-align:center;font-size:15px;margin:30px 0 16px}
.lit{color:#FFD700}
.dim{color:#555}
.grid{display:flex;flex-wrap:wrap;gap:14px;justify-content:center;max-width:820px;margin:0 auto}
.card{text-align:center;padding:8px;border-radius:10px;width:152px}
.card.lit{background:rgba(255,215,0,0.04)}
.card.dim{background:rgba(85,85,85,0.04)}
.card svg{width:140px;height:140px}
.card .nm{color:#999;font-size:12px;margin-top:4px}
.card.lit .nm{color:#ccc}
.card .idx{color:#445;font-size:10px;margin-right:3px}
.sep{width:100%;text-align:center;font-size:24px;color:#223;padding:8px 0;letter-spacing:6px}
</style></head>
<body>
<h1>十三境 · 修仙勋章</h1>
<p class="sub">「气筑丹婴化虚合乘真金太罗道」</p>
<p class="tag"><span>引气入体</span> <span>脱胎换骨</span> <span>凝结金丹</span> <span>丹破化婴</span> <span>元神出窍</span> <span>熔炼虚空</span> <span>合体归一</span> <span>渡劫飞升</span> <span>重塑仙体</span> <span>自成领域</span> <span>太乙道果</span> <span>大罗永恒</span> <span>万界巅峰</span></p>

<h3 class="lit">✨ 点亮版</h3>
<div class="grid" id="litGrid"></div>

<div class="sep">—— · ——</div>

<h3 class="dim">🌫️ 虚化版</h3>
<div class="grid" id="dimGrid"></div>

<script>
const R = [
'''
# Add realm data
for ch, name, medal, border, bg_t, bg_b, accent, element, style in REALMS:
    html += f'  ["{ch}","{name}","{medal}","{border}","{bg_t}","{bg_b}","{accent}","{element}","{style}"],\n'

html += '''];
function render(divId, dim) {
  const div = document.getElementById(divId);
  R.forEach((r, i) => {
    const [ch, nm, medal, bo, bt, bb, ac, el, st] = r;
    const el2 = document.createElement('div');
    el2.className = 'card' + (dim ? ' dim' : ' lit');
    // Use SVG object
    const obj = document.createElement('object');
    obj.type = 'image/svg+xml';
    obj.data = `svg/${ch}_${dim?'dim':'lit'}.svg`;
    obj.width = 140;
    obj.height = 140;
    el2.appendChild(obj);
    el2.innerHTML += `<div class="nm"><span class="idx">${i+1}</span>${el} · ${nm}</div>`;
    div.appendChild(el2);
  });
}
render('litGrid', false);
render('dimGrid', true);
</script>
</body>
</html>'''

with open(f"{OUT}/preview.html", "w", encoding="utf-8") as f:
    f.write(html)

print(f"\n✅ Preview: {OUT}/preview.html")
print("✅ SVG files in:", f"{OUT}/svg/")

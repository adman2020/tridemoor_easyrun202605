#!/usr/bin/env python3
"""
13 境界修仙勋章 SVG 生成器 (Doubao 设计规范版)
基于豆包的配色表 + 金属滤镜 + 八瓣花形
"""
import os, math

OUT = "D:/AI/StrideMoor/assets/badges/v4"
os.makedirs(f"{OUT}/svg", exist_ok=True)

# === 配色方案（完全按豆包设计稿） ===
# (char, realm, medal_name, main_color, accent_color, desc)
REALMS = [
    ("气", "炼气", "气引勋章", "#5B8C5A", "#7BA684", "青绿色 · 竹叶意"),
    ("筑", "筑基", "筑仙勋章", "#C4A35A", "#D4B87A", "土金色 · 石台纹"),
    ("丹", "结丹", "丹凝勋章", "#C0392B", "#E74C3C", "朱红色 · 火焰纹"),
    ("婴", "元婴", "婴生勋章", "#DAA520", "#F0C75E", "暖金色 · 幼苗纹"),
    ("化", "化神", "化神勋章", "#5DADE2", "#85C1E9", "冰蓝色 · 云纹"),
    ("虚", "练虚", "炼虚勋章", "#1A5276", "#2E86C1", "深海蓝 · 漩涡纹"),
    ("合", "合体", "合元勋章", "#B7950B", "#D4AC0D", "古铜金 · 交织纹"),
    ("乘", "大乘", "大乘勋章", "#8E44AD", "#AF7AC5", "紫雷色 · 太极纹"),
    ("真", "真仙", "真仙勋章", "#B8860B", "#DAA520", "哑光金 · 符文"),
    ("金", "金仙", "金仙勋章", "#F0E68C", "#FFF8DC", "亮白金 · 光芒"),
    ("太", "太乙", "太乙勋章", "#1ABC9C", "#48C9B0", "深绿金 · 星核"),
    ("罗", "大罗", "大罗勋章", "#D4AC0D", "#F1C40F", "星光金 · 星轨"),
    ("道", "道祖", "道祖勋章", "#A9A9A9", "#D3D3D3", "哑光灰银 · 雾纹"),
]

def make_badge(ch, realm, medal, color, accent, dim=False, sz=200):
    """Generate SVG for one badge with metal emboss + petal shape."""
    cx = cy = sz // 2
    r = sz // 2 - 6  # radius
    ri = r - 8       # inner radius
    
    # === Build eight-petal path ===
    def petal_path(radius, bulge_factor=1.06):
        pts = []
        for i in range(8):
            a1 = math.radians(i * 45 - 22.5)
            a2 = math.radians(i * 45)
            a3 = math.radians(i * 45 + 22.5)
            x1 = cx + radius * math.cos(a1)
            y1 = cy + radius * math.sin(a1)
            bulge = radius * bulge_factor
            xc = cx + bulge * math.cos(a2)
            yc = cy + bulge * math.sin(a2)
            x2 = cx + radius * math.cos(a3)
            y2 = cy + radius * math.sin(a3)
            if i == 0:
                pts.append(f"M{x1:.1f},{y1:.1f}")
            pts.append(f"Q{xc:.1f},{yc:.1f} {x2:.1f},{y2:.1f}")
        return " ".join(pts) + " Z"
    
    outer = petal_path(r, 1.08)
    inner = petal_path(ri, 1.06)
    
    # 8 decorative dots at petal tips
    dots = ""
    for i in range(8):
        a = math.radians(i * 45)
        dx = cx + (r + 3) * math.cos(a)
        dy = cy + (r + 3) * math.sin(a)
        opacity = "0.15" if dim else "0.7"
        fill = "#666" if dim else color
        dots += f'<circle cx="{dx:.1f}" cy="{dy:.1f}" r="2.5" fill="{fill}" opacity="{opacity}"/>\n  '
    
    if dim:
        # === DIM version ===
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {sz} {sz}" width="{sz}px" height="{sz}px">
  <defs>
    <filter id="dim_shadow"><feDropShadow dx="0" dy="1" stdDeviation="1" flood-color="#000" flood-opacity="0.1"/></filter>
  </defs>
  <path d="{outer}" fill="#222" opacity="0.12" stroke="#666" stroke-width="1" opacity="0.15"/>
  <path d="{inner}" fill="none" stroke="#666" stroke-width="0.5" opacity="0.08"/>
  {dots}
  <text x="{cx}" y="{cy+6}" font-family="KaiTi,STKaiti,serif" font-size="60" font-weight="bold"
        fill="#666" text-anchor="middle" opacity="0.2" filter="url(#dim_shadow)">{ch}</text>
  <text x="{cx}" y="{cy+r-6}" font-family="KaiTi,STKaiti,serif" font-size="10"
        fill="#666" text-anchor="middle" opacity="0.1">{medal}</text>
</svg>'''
    
    # === LIT version ===
    light_color = "#ffffff"
    hl = accent  # highlight accent
    
    # Convert hex to RGB for gradients
    def hex_to_rgb(h):
        h = h.lstrip("#")
        return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    
    grad_id = f"grd_{ch}"
    glow_id = f"glw_{ch}"
    
    r_, g_, b_ = hex_to_rgb(color)
    bg_dark = f"rgb({max(0,r_-60)},{max(0,g_-60)},{max(0,b_-60)})"
    bg_mid = color
    bg_light = f"rgb({min(255,r_+40)},{min(255,g_+40)},{min(255,b_+40)})"
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {sz} {sz}" width="{sz}px" height="{sz}px">
  <defs>
    <!-- Background gradient -->
    <radialGradient id="{grad_id}" cx="40%" cy="35%" r="70%">
      <stop offset="0%" stop-color="{hl}" stop-opacity="0.3"/>
      <stop offset="25%" stop-color="{bg_light}" stop-opacity="0.9"/>
      <stop offset="60%" stop-color="{bg_mid}" stop-opacity="0.95"/>
      <stop offset="100%" stop-color="{bg_dark}" stop-opacity="1"/>
    </radialGradient>
    
    <!-- Metal emboss filter for text -->
    <filter id="metal_{ch}">
      <!-- Shadow -->
      <feDropShadow dx="1" dy="2" stdDeviation="2" flood-color="#000" flood-opacity="0.6"/>
      <!-- Bevel/emboss -->
      <feGaussianBlur in="SourceAlpha" stdDeviation="1.5" result="blur"/>
      <feSpecularLighting in="blur" surfaceScale="6" specularConstant="0.9" specularExponent="30" lighting-color="#ffffff" result="spec">
        <fePointLight x="-200" y="-400" z="800"/>
      </feSpecularLighting>
      <feComposite in="spec" in2="SourceAlpha" operator="in" result="specOut"/>
      <feComposite in="SourceGraphic" in2="specOut" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>
    </filter>
    
    <!-- Glow filter for high-realm badges -->
    <filter id="{glow_id}">
      <feGaussianBlur stdDeviation="4" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  
  <!-- Outer glow -->
  <path d="{outer}" fill="none" stroke="{hl}" stroke-width="3" opacity="0.12" filter="url(#{glow_id})"/>
  
  <!-- Main petal body -->
  <path d="{outer}" fill="url(#{grad_id})" stroke="{color}" stroke-width="2.5"/>
  
  <!-- Inner border ring -->
  <path d="{inner}" fill="none" stroke="{hl}" stroke-width="0.8" opacity="0.4"/>
  
  <!-- Inner dashed decorative ring -->
  <path d="{inner}" fill="none" stroke="{color}" stroke-width="1" stroke-dasharray="3,3" opacity="0.25"/>
  
  <!-- Petal-tip dots -->
  {dots}
  
  <!-- Center character with metal emboss -->
  <text x="{cx}" y="{cy+6}" font-family="KaiTi,STKaiti,serif" font-size="68" font-weight="bold"
        fill="{color}" text-anchor="middle" filter="url(#metal_{ch})" dominant-baseline="central">{ch}</text>
  
  <!-- Medal name -->
  <text x="{cx}" y="{cy+r-8}" font-family="KaiTi,STKaiti,serif" font-size="10" font-weight="bold"
        fill="{hl}" text-anchor="middle" opacity="0.6" letter-spacing="1">{medal}</text>
  
  <!-- Top highlight streak -->
  <ellipse cx="{cx}" cy="{cy-r*0.35}" rx="{r*0.35}" ry="{r*0.08}" fill="{hl}" opacity="0.15"/>
</svg>'''


# === Generate all badges ===
for ch, realm, medal, color, accent, desc in REALMS:
    # Lit
    svg_lit = make_badge(ch, realm, medal, color, accent, dim=False)
    with open(f"{OUT}/svg/{ch}_lit.svg", "w", encoding="utf-8") as f:
        f.write(svg_lit)
    # Dim
    svg_dim = make_badge(ch, realm, medal, color, accent, dim=True)
    with open(f"{OUT}/svg/{ch}_dim.svg", "w", encoding="utf-8") as f:
        f.write(svg_dim)
    print(f"  {ch} {realm:　<4} {desc}")

# === Generate preview HTML with all SVGs inline ===
tags = []
for ch, realm, medal, color, accent, desc in REALMS:
    with open(f"{OUT}/svg/{ch}_lit.svg", "r", encoding="utf-8") as f:
        svg = f.read().replace('width="200px"', 'width="170"').replace('height="200px"', 'height="170"')
    tags.append(f'<div class="b"><div class="i">{svg}</div><div class="n">{ch} · {realm}</div><div class="d">{medal}</div></div>')

html = f'''<!DOCTYPE html><html lang="zh"><head>
<meta charset="UTF-8"><title>十三境 · 修仙勋章 v4</title>
<style>
*{{margin:0;padding:0;box-sizing:border-box}}
body{{background:#0a0a14;padding:30px;text-align:center;font-family:KaiTi,STKaiti,serif}}
h1{{color:#FFD700;font-size:28px;margin-bottom:4px;letter-spacing:4px}}
.sub{{color:#667;font-size:13px;margin-bottom:24px;letter-spacing:2px}}
.w{{display:flex;flex-wrap:wrap;gap:14px;justify-content:center;max-width:820px;margin:0 auto}}
.b{{width:170px;padding:10px;background:rgba(255,255,255,0.015);border-radius:12px;text-align:center}}
.b .i{{line-height:0}}
.b .n{{color:#ccc;font-size:15px;margin-top:6px;letter-spacing:1px}}
.b .d{{color:#556;font-size:10px;margin-top:2px}}
.s{{color:#334;padding:20px 0 8px;font-size:18px;letter-spacing:6px}}
</style></head><body>
<h1>✦ 十三境 · 修仙勋章 ✦</h1>
<p class="sub">气筑丹婴化虚合乘真金太罗道 · 凡人修仙传正版排序</p>
<div class="w">{"".join(tags)}</div>
<div class="s">—— · ——</div>
<p style="color:#445;font-size:11px">SVG 金属浮雕 · 豆包设计规范 · 八瓣莲花形</p>
</body></html>'''

with open(f"{OUT}/preview_all.html", "w", encoding="utf-8") as f:
    f.write(html)

print(f"\n✅ 共 {len(REALMS)} 枚勋章")
print(f"✅ SVG: {OUT}/svg/")
print(f"✅ 预览: {OUT}/preview_all.html")

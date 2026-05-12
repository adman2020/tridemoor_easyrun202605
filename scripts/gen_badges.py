#!/usr/bin/env python3
"""Generate 12 Chinese-style realm badges as SVG files."""
import os, math

OUT = "D:/AI/StrideMoor/assets/badges/svg"
os.makedirs(OUT, exist_ok=True)

# Realm definitions: (char, name, bg, border, accent)
REALMS = [
    ("炼", "炼气", "#7BA684", "#5A6B5C", "#A3D4A8"),
    ("丹", "结丹", "#4A9B6E", "#B87333", "#6BC48A"),
    ("婴", "元婴", "#4A90D9", "#C0C0C0", "#7AB8F0"),
    ("化", "化神", "#2B5EA7", "#FFD700", "#5A8FE0"),
    ("虚", "练虚", "#6C3FC5", "#FFC125", "#9B6EE8"),
    ("合", "合体", "#8B3A8B", "#DAA520", "#B55AB5"),
    ("乘", "大乘", "#D2691E", "#CD5C1C", "#E88A45"),
    ("真", "真仙", "#FF8C00", "#FFD700", "#FFB347"),
    ("金", "金仙", "#DAA520", "#FF4500", "#F0C75E"),
    ("太", "太乙", "#DC143C", "#FF69B4", "#FF4D6D"),
    ("罗", "大罗", "#B8860B", "#FFD700", "#D4A847"),
    ("道", "道祖", "#1A1A2E", "#FFF8DC", "#E8D5B7"),
]

def make_lit(ch, name, bg, border, accent, glow=True):
    # 4 compass dots positions
    dots = ""
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        cx = 60 + 48 * math.cos(rad)
        cy = 60 + 48 * math.sin(rad)
        dots += f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="2.5" fill="{border}"/>\n  '

    glow_filter = ""
    if glow:
        glow_filter = """
    <filter id="g">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>"""

    cloud_top = '<path d="M38,18 Q42,14 46,18 Q50,12 54,18 Q58,14 62,18 Q66,12 70,18 L68,22 L40,22 Z" fill="' + border + '" opacity="0.25"/>'
    cloud_bot = '<path d="M38,102 Q42,106 46,102 Q50,108 54,102 Q58,106 62,102 Q66,108 70,102 L68,98 L40,98 Z" fill="' + border + '" opacity="0.25"/>'

    glow_ring = ""
    if glow:
        glow_ring = f'<circle cx="60" cy="60" r="58" fill="none" stroke="{border}" stroke-width="1" opacity="0.15"/>'

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120">
  <defs>
    <radialGradient id="bg" cx="40%" cy="35%" r="65%">
      <stop offset="0%" stop-color="{accent}" stop-opacity="0.95"/>
      <stop offset="60%" stop-color="{bg}" stop-opacity="0.95"/>
      <stop offset="100%" stop-color="{bg}" stop-opacity="1"/>
    </radialGradient>{glow_filter}
  </defs>
  {glow_ring}
  <circle cx="60" cy="60" r="56" fill="none" stroke="{border}" stroke-width="2.5"/>
  {dots}
  <circle cx="60" cy="60" r="48" fill="none" stroke="{border}" stroke-width="1" stroke-dasharray="3,3" opacity="0.6"/>
  <circle cx="60" cy="60" r="44" fill="url(#bg)"/>
  {cloud_top}
  {cloud_bot}
  <text x="60" y="74" font-family="KaiTi,STKaiti,serif" font-size="52"
        font-weight="bold" fill="{border}" text-anchor="middle"
        style="text-shadow:2px 2px 4px rgba(0,0,0,0.6)"
        {('filter="url(#g)"' if glow else '')}>{ch}</text>
  <text x="60" y="108" font-family="KaiTi,STKaiti,serif" font-size="10"
        fill="{border}" text-anchor="middle" opacity="0.7">{name}</text>
</svg>'''


def make_dim(ch, name):
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120">
  <circle cx="60" cy="60" r="56" fill="none" stroke="#888" stroke-width="2.5" opacity="0.2"/>
  <circle cx="60" cy="12" r="2.5" fill="#888" opacity="0.2"/>
  <circle cx="108" cy="60" r="2.5" fill="#888" opacity="0.2"/>
  <circle cx="12" cy="60" r="2.5" fill="#888" opacity="0.2"/>
  <circle cx="60" cy="108" r="2.5" fill="#888" opacity="0.2"/>
  <circle cx="60" cy="60" r="48" fill="none" stroke="#888" stroke-width="1" stroke-dasharray="3,3" opacity="0.2"/>
  <circle cx="60" cy="60" r="44" fill="#666" opacity="0.08"/>
  <path d="M38,18 Q42,14 46,18 Q50,12 54,18 Q58,14 62,18 Q66,12 70,18 L68,22 L40,22 Z" fill="#888" opacity="0.1"/>
  <path d="M38,102 Q42,106 46,102 Q50,108 54,102 Q58,106 62,102 Q66,108 70,102 L68,98 L40,98 Z" fill="#888" opacity="0.1"/>
  <text x="60" y="74" font-family="KaiTi,STKaiti,serif" font-size="52"
        font-weight="bold" fill="#999" text-anchor="middle" opacity="0.25">{ch}</text>
  <text x="60" y="108" font-family="KaiTi,STKaiti,serif" font-size="10"
        fill="#999" text-anchor="middle" opacity="0.15">{name}</text>
</svg>'''


for ch, name, bg, border, accent in REALMS:
    lit = make_lit(ch, name, bg, border, accent)
    dim = make_dim(ch, name)
    with open(f"{OUT}/badge_{ch}_lit.svg", "w", encoding="utf-8") as f:
        f.write(lit)
    with open(f"{OUT}/badge_{ch}_dim.svg", "w", encoding="utf-8") as f:
        f.write(dim)
    print(f"  {ch}  {name}")

print(f"\n24 SVG files -> {OUT}")

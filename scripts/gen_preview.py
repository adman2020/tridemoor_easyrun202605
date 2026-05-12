#!/usr/bin/env python3
"""Generate standalone preview HTML with all 13 realm badges inlined."""
import os

OUT = "D:/AI/StrideMoor/assets/badges/v3"

# Read all SVGs
chunks = []
for ch in ["气","筑","丹","婴","化","虚","合","乘","真","金","太","罗","道"]:
    with open(f"{OUT}/svg/{ch}_lit.svg", "r", encoding="utf-8") as f:
        svg = f.read()
        # Adjust size for preview
        svg = svg.replace('width="160"', 'width="150"').replace('height="160"', 'height="150"')
        chunks.append(svg)

names = ["炼气","筑基","结丹","元婴","化神","练虚","合体","大乘","真仙","金仙","太乙","大罗","道祖"]
elements = ["竹叶","石台","葫芦","莲台","祥云","飞剑","八卦","火焰","仙鹤","龙纹","凤凰","星辰","混沌"]

cards = []
for i, (svg, nm, el) in enumerate(zip(chunks, names, elements)):
    cards.append(f"""<div style="text-align:center;width:160px;padding:8px;background:rgba(255,255,255,0.02);border-radius:12px">
{svg}
<div style="color:#ccc;font-family:KaiTi,STKaiti,serif;font-size:13px;margin-top:4px"><span style="color:#445;font-size:10px">{i+1}</span>{nm}</div>
<div style="color:#555;font-size:10px;font-family:KaiTi,serif;margin-top:2px">· {el} ·</div>
</div>""")

html = f"""<!DOCTYPE html>
<html lang="zh">
<head><meta charset="UTF-8"><title>十三境 · 修仙勋章</title></head>
<body style="background:#0a0a14;padding:30px;margin:0;text-align:center;font-family:KaiTi,STKaiti,serif">
<h1 style="color:#FFD700;font-size:30px;margin-bottom:4px">十三境 · 修仙勋章</h1>
<p style="color:#667;font-size:14px;margin-bottom:24px;letter-spacing:4px">「气筑丹婴化虚合乘真金太罗道」</p>
<p style="color:#445;font-size:11px;margin-bottom:28px">
<span style="border:1px solid #445;border-radius:10px;padding:2px 8px;margin:0 3px">引气入体</span>
<span style="border:1px solid #445;border-radius:10px;padding:2px 8px;margin:0 3px">脱胎换骨</span>
<span style="border:1px solid #445;border-radius:10px;padding:2px 8px;margin:0 3px">凝结金丹</span>
<span style="border:1px solid #445;border-radius:10px;padding:2px 8px;margin:0 3px">丹破化婴</span>
<span style="border:1px solid #445;border-radius:10px;padding:2px 8px;margin:0 3px">元神出窍</span>
</p>
<div style="display:flex;flex-wrap:wrap;gap:16px;justify-content:center;max-width:850px;margin:auto">
{chr(10).join(cards)}
</div>
</body>
</html>"""

with open(f"{OUT}/preview_all.html", "w", encoding="utf-8") as f:
    f.write(html)

print(f"Written: {OUT}/preview_all.html ({len(html)} bytes)")

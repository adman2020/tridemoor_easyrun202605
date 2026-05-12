#!/usr/bin/env python3
"""Analyze the Doubao-generated badge images."""
from PIL import Image
import os

d = r"D:\AI\StrideMoor\assets\badges\paojing"

for f in sorted(os.listdir(d)):
    if not f.endswith(".png"):
        continue
    img = Image.open(os.path.join(d, f))
    w, h = img.size
    cx, cy = w // 2, h // 2

    pts = {
        "center": img.getpixel((cx, cy)),
        "top": img.getpixel((cx, 10)),
        "bottom": img.getpixel((cx, h - 10)),
        "left": img.getpixel((10, cy)),
        "right": img.getpixel((w - 10, cy)),
    }

    corners = {
        "TL": img.getpixel((3, 3)),
        "TR": img.getpixel((w - 3, 3)),
        "BL": img.getpixel((3, h - 3)),
        "BR": img.getpixel((w - 3, h - 3)),
    }

    print(f"[{f[:-8]}] {w}x{h}")
    for k, v in pts.items():
        print(f"  {k}: RGBA{v}")
    print(f"  corners: TL={corners['TL']} TR={corners['TR']} BL={corners['BL']} BR={corners['BR']}")
    print()

#!/usr/bin/env python3
"""
从 assets/images/logo_minimal.png 生成 Android / iOS 应用图标

使用方法:
    cd stride_moor_app
    python ../scripts/generate_app_icons.py
"""

import os
import sys
import json
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("请先安装 Pillow: pip install Pillow")
    sys.exit(1)

# 项目根目录（脚本在 scripts/ 下，项目根在上一级）
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = (SCRIPT_DIR / ".." / "stride_moor_app").resolve()

if not PROJECT_ROOT.exists():
    PROJECT_ROOT = (SCRIPT_DIR / "..").resolve()

SOURCE_IMAGE = PROJECT_ROOT / "assets" / "images" / "logo_minimal.png"
if not SOURCE_IMAGE.exists():
    print(f"错误: 找不到源图标 {SOURCE_IMAGE}")
    sys.exit(1)

print(f"源图标: {SOURCE_IMAGE}")
print(f"项目根目录: {PROJECT_ROOT}")

# ==================== Android ====================
ANDROID_RES = PROJECT_ROOT / "android" / "app" / "src" / "main" / "res"

ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

def generate_android_icons():
    img = Image.open(SOURCE_IMAGE)
    # 确保是 RGBA 模式
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    for folder, size in ANDROID_SIZES.items():
        out_dir = ANDROID_RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)

        # 普通图标
        resized = img.resize((size, size), Image.LANCZOS)
        out_path = out_dir / "ic_launcher.png"
        resized.save(out_path, "PNG")
        print(f"  [OK] {out_path}")

        # 圆形图标（Android 8.0+ adaptive icon fallback）
        out_path_round = out_dir / "ic_launcher_round.png"
        resized.save(out_path_round, "PNG")
        print(f"  [OK] {out_path_round}")

    print("Android 图标生成完成")


# ==================== iOS ====================
IOS_ASSETS = (
    PROJECT_ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
)

IOS_ICONS = [
    {"size": 20, "scale": 2, "idiom": "iphone", "filename": "Icon-App-20x20@2x.png"},
    {"size": 20, "scale": 3, "idiom": "iphone", "filename": "Icon-App-20x20@3x.png"},
    {"size": 29, "scale": 1, "idiom": "iphone", "filename": "Icon-App-29x29@1x.png"},
    {"size": 29, "scale": 2, "idiom": "iphone", "filename": "Icon-App-29x29@2x.png"},
    {"size": 29, "scale": 3, "idiom": "iphone", "filename": "Icon-App-29x29@3x.png"},
    {"size": 40, "scale": 2, "idiom": "iphone", "filename": "Icon-App-40x40@2x.png"},
    {"size": 40, "scale": 3, "idiom": "iphone", "filename": "Icon-App-40x40@3x.png"},
    {"size": 60, "scale": 2, "idiom": "iphone", "filename": "Icon-App-60x60@2x.png"},
    {"size": 60, "scale": 3, "idiom": "iphone", "filename": "Icon-App-60x60@3x.png"},
    {"size": 20, "scale": 1, "idiom": "ipad", "filename": "Icon-App-20x20@1x.png"},
    {"size": 20, "scale": 2, "idiom": "ipad", "filename": "Icon-App-20x20@2x.png"},
    {"size": 29, "scale": 1, "idiom": "ipad", "filename": "Icon-App-29x29@1x.png"},
    {"size": 29, "scale": 2, "idiom": "ipad", "filename": "Icon-App-29x29@2x.png"},
    {"size": 40, "scale": 1, "idiom": "ipad", "filename": "Icon-App-40x40@1x.png"},
    {"size": 40, "scale": 2, "idiom": "ipad", "filename": "Icon-App-40x40@2x.png"},
    {"size": 76, "scale": 1, "idiom": "ipad", "filename": "Icon-App-76x76@1x.png"},
    {"size": 76, "scale": 2, "idiom": "ipad", "filename": "Icon-App-76x76@2x.png"},
    {"size": 83.5, "scale": 2, "idiom": "ipad", "filename": "Icon-App-83.5x83.5@2x.png"},
    {"size": 1024, "scale": 1, "idiom": "ios-marketing", "filename": "Icon-App-1024x1024@1x.png"},
]

IOS_CONTENTS = {
    "images": [
        {"size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@2x.png", "scale": "2x"},
        {"size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@3x.png", "scale": "3x"},
        {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@1x.png", "scale": "1x"},
        {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@2x.png", "scale": "2x"},
        {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@3x.png", "scale": "3x"},
        {"size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@2x.png", "scale": "2x"},
        {"size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@3x.png", "scale": "3x"},
        {"size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@2x.png", "scale": "2x"},
        {"size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@3x.png", "scale": "3x"},
        {"size": "20x20", "idiom": "ipad", "filename": "Icon-App-20x20@1x.png", "scale": "1x"},
        {"size": "20x20", "idiom": "ipad", "filename": "Icon-App-20x20@2x.png", "scale": "2x"},
        {"size": "29x29", "idiom": "ipad", "filename": "Icon-App-29x29@1x.png", "scale": "1x"},
        {"size": "29x29", "idiom": "ipad", "filename": "Icon-App-29x29@2x.png", "scale": "2x"},
        {"size": "40x40", "idiom": "ipad", "filename": "Icon-App-40x40@1x.png", "scale": "1x"},
        {"size": "40x40", "idiom": "ipad", "filename": "Icon-App-40x40@2x.png", "scale": "2x"},
        {"size": "76x76", "idiom": "ipad", "filename": "Icon-App-76x76@1x.png", "scale": "1x"},
        {"size": "76x76", "idiom": "ipad", "filename": "Icon-App-76x76@2x.png", "scale": "2x"},
        {"size": "83.5x83.5", "idiom": "ipad", "filename": "Icon-App-83.5x83.5@2x.png", "scale": "2x"},
        {"size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-App-1024x1024@1x.png", "scale": "1x"},
    ],
    "info": {"author": "xcode", "version": 1},
}

def generate_ios_icons():
    if not IOS_ASSETS.exists():
        print(f"警告: iOS 资源目录不存在 {IOS_ASSETS}，跳过 iOS 图标")
        return

    img = Image.open(SOURCE_IMAGE)
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    IOS_ASSETS.mkdir(parents=True, exist_ok=True)

    for icon in IOS_ICONS:
        px = int(icon["size"] * icon["scale"])
        resized = img.resize((px, px), Image.LANCZOS)
        out_path = IOS_ASSETS / icon["filename"]
        resized.save(out_path, "PNG")
        print(f"  [OK] {out_path}")

    # 更新 Contents.json
    contents_path = IOS_ASSETS / "Contents.json"
    with open(contents_path, "w", encoding="utf-8") as f:
        json.dump(IOS_CONTENTS, f, indent=2, ensure_ascii=False)
    print(f"  [OK] {contents_path}")

    print("iOS 图标生成完成")


if __name__ == "__main__":
    print("=" * 50)
    print("开始生成应用图标...")
    print("=" * 50)
    generate_android_icons()
    print()
    generate_ios_icons()
    print()
    print("全部完成！")

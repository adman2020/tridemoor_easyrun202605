#!/usr/bin/env python3
"""
整理登录/注册页面到 auth/ 目录，并更新 import 路径。
同时运行 flutter analyze 验证编译。
"""
import os
import shutil

BASE = r"D:\AI\StrideMoor\stride_moor_app"
AUTH_DIR = os.path.join(BASE, "lib", "modules", "auth")
PROFILE_DIR = os.path.join(BASE, "lib", "modules", "profile")
ROUTES_FILE = os.path.join(BASE, "lib", "config", "routes.dart")

def main():
    # 1. 创建 auth 目录
    os.makedirs(AUTH_DIR, exist_ok=True)
    print(f"[OK] Directory ensured: {AUTH_DIR}")

    # 2. 移动文件（如果存在）
    for filename in ["login_page.dart", "register_page.dart"]:
        src = os.path.join(PROFILE_DIR, filename)
        dst = os.path.join(AUTH_DIR, filename)
        if os.path.exists(src):
            shutil.move(src, dst)
            print(f"[OK] Moved {filename} -> auth/")
        elif os.path.exists(dst):
            print(f"[SKIP] {filename} already in auth/")
        else:
            print(f"[WARN] {filename} not found in profile/ or auth/")

    # 3. 更新 routes.dart 的 import 路径
    if os.path.exists(ROUTES_FILE):
        with open(ROUTES_FILE, "r", encoding="utf-8") as f:
            content = f.read()

        old_count = content.count("../modules/profile/login_page")
        content = content.replace(
            "import '../modules/profile/login_page.dart';",
            "import '../modules/auth/login_page.dart';"
        )
        content = content.replace(
            "import '../modules/profile/register_page.dart';",
            "import '../modules/auth/register_page.dart';"
        )
        new_count = content.count("../modules/auth/login_page")

        with open(ROUTES_FILE, "w", encoding="utf-8") as f:
            f.write(content)

        if old_count > 0 or new_count > 0:
            print(f"[OK] Updated routes.dart imports (auth/)")
        else:
            print(f"[SKIP] routes.dart imports already correct or not found")
    else:
        print(f"[ERR] routes.dart not found: {ROUTES_FILE}")

    # 4. 运行 flutter analyze
    print("\n[RUN] flutter analyze ...")
    ret = os.system(rf'cd /d "{BASE}" && flutter analyze')
    print(f"\n[Done] flutter analyze exit code: {ret}")

if __name__ == "__main__":
    main()

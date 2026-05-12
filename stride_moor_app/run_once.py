#!/usr/bin/env python3
"""一键完成：创建auth目录 → 移动文件 → 更新import → flutter analyze"""
import os
import shutil

BASE = r"D:\AI\StrideMoor\stride_moor_app"
AUTH = os.path.join(BASE, "lib", "modules", "auth")
PROFILE = os.path.join(BASE, "lib", "modules", "profile")
ROUTES = os.path.join(BASE, "lib", "config", "routes.dart")

os.makedirs(AUTH, exist_ok=True)
print("[1/4] Created lib/modules/auth/")

for f in ["login_page.dart", "register_page.dart"]:
    src, dst = os.path.join(PROFILE, f), os.path.join(AUTH, f)
    if os.path.exists(src):
        shutil.move(src, dst)
        print(f"[2/4] Moved {f} -> auth/")
    elif os.path.exists(dst):
        print(f"[2/4] {f} already in auth/")

with open(ROUTES, "r", encoding="utf-8") as f:
    c = f.read()
c = c.replace("'../modules/profile/login_page.dart'", "'../modules/auth/login_page.dart'")
c = c.replace("'../modules/profile/register_page.dart'", "'../modules/auth/register_page.dart'")
with open(ROUTES, "w", encoding="utf-8") as f:
    f.write(c)
print("[3/4] Updated routes.dart imports")

print("[4/4] Running flutter analyze...\n")
ret = os.system(rf'cd /d "{BASE}" && flutter analyze')
print(f"\nExit code: {ret}")
print("\nDone! 若返回 0 则编译通过。若有错误请把输出贴回给 AI。")

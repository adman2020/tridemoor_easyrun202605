#!/usr/bin/env python3
"""运行 flutter analyze 检查当前代码。"""
import os
import subprocess

BASE = r"D:\AI\StrideMoor\stride_moor_app"

def main():
    # 先检查文件结构
    auth_dir = os.path.join(BASE, "lib", "modules", "auth")
    profile_dir = os.path.join(BASE, "lib", "modules", "profile")
    
    print("=== File check ===")
    for d, label in [(auth_dir, "auth/"), (profile_dir, "profile/")]:
        login = os.path.join(d, "login_page.dart")
        register = os.path.join(d, "register_page.dart")
        print(f"  {label} login_page.dart: {'exists' if os.path.exists(login) else 'missing'}")
        print(f"  {label} register_page.dart: {'exists' if os.path.exists(register) else 'missing'}")
    
    # 运行 flutter analyze
    print("\n=== Running flutter analyze ===")
    result = subprocess.run(
        ["flutter", "analyze"],
        cwd=BASE,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace"
    )
    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)
    print(f"\nExit code: {result.returncode}")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Open the badge preview in Edge."""
import subprocess, os

html = r"D:\AI\StrideMoor\assets\badges\v3\preview_all.html"
url = "file:///" + html.replace("\\", "/")
subprocess.Popen(["cmd", "/c", "start", "msedge", url], shell=True)
print(f"Opening: {url}")

#!/usr/bin/env python3
"""Take screenshot of badge preview with headless Edge."""
from selenium import webdriver
from selenium.webdriver.edge.options import Options
import time, os

html_path = "D:/AI/StrideMoor/assets/badges/v3/preview_all.html"
out_path = "D:/AI/StrideMoor/assets/badges/v3/wall_preview.png"

options = Options()
options.add_argument("--headless")
options.add_argument("--window-size=900,1200")

driver = webdriver.Edge(options=options)
driver.get("file:///" + html_path.replace("\\", "/"))
time.sleep(3)

driver.save_screenshot(out_path)
size = os.path.getsize(out_path)
print(f"Screenshot saved: {out_path} ({size} bytes)")

driver.quit()

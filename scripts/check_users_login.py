#!/usr/bin/env python3
"""Check user login credentials."""
import mysql.connector as mc

db = mc.connect(host="127.0.0.1", port=3308, user="root",
                password="stridemoor_root_2026", database="stridemoor")
c = db.cursor()
c.execute("SELECT nickname, phone, password_hash FROM users LIMIT 20")
for r in c.fetchall():
    pw = r[2]
    pw_show = pw[:30] + "..." if pw else "NONE"
    print(f"  {r[0]:12s}  phone={r[1]:15s}  pw_hash={pw_show}")

# Also check the backend handler for login
db.close()

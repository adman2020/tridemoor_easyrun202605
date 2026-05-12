#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'D:\AI\StrideMoor\wikiloc_honghu.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

old = "tags = '洪湖公园,湖边,平路'"
new = "tags = '[\"洪湖公园\",\"湖边\",\"平路\"]'"
sql = sql.replace(old, new)

with open(r'D:\AI\StrideMoor\wikiloc_honghu.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

print('Fixed')

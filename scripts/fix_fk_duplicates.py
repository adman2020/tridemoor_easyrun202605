#!/usr/bin/env python3
"""Drop duplicate foreign keys from StrideMoor database, keeping only the clean ones."""
import mysql.connector
from collections import defaultdict

DB = dict(host='127.0.0.1', port=3308, user='root',
          password='stridemoor_root_2026', database='stridemoor')
conn = mysql.connector.connect(**DB)
c = conn.cursor()

c.execute("""SELECT TABLE_NAME, CONSTRAINT_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE CONSTRAINT_SCHEMA = %s AND CONSTRAINT_TYPE = 'FOREIGN KEY'
ORDER BY TABLE_NAME, CONSTRAINT_NAME""", (DB['database'],))
fks = c.fetchall()

table_fks = defaultdict(list)
for tbl, fk in fks:
    table_fks[tbl].append(fk)

# Drop FKs that belong to duplicate groups (same referenced columns)
# We'll get column info for each FK
for tbl, constraints in table_fks.items():
    if len(constraints) <= 1:
        continue
    # Get reference info for each FK
    c.execute("""SELECT CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND REFERENCED_TABLE_NAME IS NOT NULL
        ORDER BY CONSTRAINT_NAME, ORDINAL_POSITION""", (DB['database'], tbl))
    refs = c.fetchall()
    
    # Group by (column, referenced_table)
    sig_map = defaultdict(list)
    for con, col, ref_tbl, ref_col in refs:
        sig_map[(col, ref_tbl, ref_col)].append(con)
    
    # For each group with > 1 FK, drop all but one
    for sig, names in sig_map.items():
        if len(names) > 1:
            # Keep the last one, drop the rest
            for fk in names[:-1]:
                try:
                    c.execute(f'ALTER TABLE `{tbl}` DROP FOREIGN KEY `{fk}`')
                    print(f"  Dropped {fk} on {tbl}({sig[0]})")
                except Exception as e:
                    print(f"  Failed to drop {fk}: {e}")

conn.commit()
c.close()
conn.close()
print("Done!")

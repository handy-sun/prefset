#!/usr/bin/env python
import sys
import re

if len(sys.argv) < 2:
    sys.stdout.write('Must give an argument.\n')
    sys.exit(-1)

so_name = sys.argv[1]
idx = so_name.index('.so')

if idx + 3 < len(so_name):
    lcontent = so_name[0 : idx + 3]
    rcontent = so_name[idx + 3:]
    one_group = re.search(r"((.[0-9]+){1})", rcontent).group()
    print(lcontent + one_group)
else:
    print(so_name)


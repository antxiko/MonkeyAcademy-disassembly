#!/usr/bin/env python3
"""Direccion de cada etiqueta: la de la primera instruccion de detras (el ;XXXX
de su linea). Uso: dir_de.py listado.asm ETIQUETA [ETIQUETA...] | /regex"""
import re
import sys

lineas = open(sys.argv[1], encoding="utf-8", errors="replace").read().split("\n")
pides = sys.argv[2:]
for i, l in enumerate(lineas):
    m = re.match(r"^([A-Za-z_]\w*):", l)
    if not m:
        continue
    n = m.group(1)
    if not any(n == p or (p.startswith("/") and re.search(p[1:], n, re.I)) for p in pides):
        continue
    for j in range(i + 1, min(i + 6, len(lineas))):
        d = re.search(r";([0-9a-f]{4})\b", lineas[j])
        if d:
            print("%-32s 0x%s" % (n, d.group(1).upper()))
            break

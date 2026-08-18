#!/usr/bin/env python3
"""Pinta una pantalla completa (tiles + sprites) desde un volcado de la VRAM.

    python3 tools/pantalla.py volcado_vram.bin salida.png [escala]

Repite lo que hace el TMS9918 en SCREEN 2 con sprites de 16x16: la tabla de
nombres de 0x3800 con sus tres tercios, y los atributos de 0x3B00 hasta el
0xD0 que los cierra, en orden inverso de prioridad. Vale para comprobar que
un dibujo reconstruido coincide con lo que se veia.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import PAL, png  # noqa: E402


def pantalla(v):
    W, H = 256, 192
    img = [[(0, 0, 0)] * W for _ in range(H)]
    nt = v[0x3800:0x3B00]
    for r in range(24):
        for c in range(32):
            t = nt[r * 32 + c]; th = r // 8
            pat = v[0x2000 + th * 0x800 + t * 8:0x2000 + th * 0x800 + t * 8 + 8]
            col = v[0x0000 + th * 0x800 + t * 8:0x0000 + th * 0x800 + t * 8 + 8]
            for y in range(8):
                fg, bg = PAL[col[y] >> 4], PAL[col[y] & 15]
                for x in range(8):
                    img[r * 8 + y][c * 8 + x] = fg if (pat[y] >> (7 - x)) & 1 else bg
    sa = v[0x3B00:0x3B80]
    n = 32
    for i in range(32):
        if sa[4 * i] == 0xD0:
            n = i; break
    for i in reversed(range(n)):
        Y, X, P, C = sa[4 * i:4 * i + 4]
        if C & 15 == 0:
            continue
        p = v[0x1800 + (P & 0xFC) * 8:0x1800 + (P & 0xFC) * 8 + 32]
        for y in range(16):
            bits = (p[y] << 8) | p[16 + y]
            for x in range(16):
                if (bits >> (15 - x)) & 1:
                    yy = (Y + 1 + y) & 0xFF; xx = X + x
                    if 0 <= yy < H and 0 <= xx < W:
                        img[yy][xx] = PAL[C & 15]
    return img


def main():
    v = open(sys.argv[1], "rb").read()
    esc = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    img = pantalla(v)
    big = []
    for row in img:
        r = []
        for p in row:
            r += [p] * esc
        big += [r] * esc
    png(256 * esc, 192 * esc, big, sys.argv[2])
    sa = v[0x3B00:0x3B80]
    for i in range(32):
        Y, X, P, C = sa[4 * i:4 * i + 4]
        if Y == 0xD0:
            break
        if Y != 0xE1:
            print(f"sprite {i:2d}: Y={Y:02X} X={X:02X} patron={P:02X} (16x16 n. {P >> 2}) color={C:X}")


if __name__ == "__main__":
    main()

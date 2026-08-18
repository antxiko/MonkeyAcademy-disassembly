#!/usr/bin/env python3
"""Reconstruye la VRAM de Monkey Academy tal como la carga la ROM y la pinta.

    python3 tools/graficos.py monkey.rom work/gfx

Repite, en el mismo orden y con las mismas direcciones, las copias que hace
INIT (0x40AF): los sprites de 0x56BF a 0x1800 (los seis primeros) y OTRA VEZ
a 0x18C0 (los 22, porque COPIA_A_VRAM conserva HL), el espejo bit a bit de
esos 22 (0x4107) a 0x1CC0, y los patrones (0x5156) y colores (0x566B)
descomprimidos con RLE_A_VRAM (0x6C84) en los tres tercios. No inventa nada:
es la lista de `call` de INIT pasada a Python, y se ha cotejado sprite a
sprite con un volcado de la VRAM del emulador. Con eso salen:

    tiles.png     los 256 tiles de cada tercio (patron + color), 32 por fila
    sprites.png   los 64 sprites de 16x16, en blanco sobre negro (el color lo
                  pone el atributo, no el patron)
    sprites_N.png los juegos alternativos de sprites que 0x5F5F carga por
                  0x6044 (N = 1, 2), en 0x1800 y 0x1C00
"""
import os
import struct
import sys
import zlib

ORG = 0x4000
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120), (84, 85, 237), (125, 118, 252),
       (212, 82, 77), (66, 235, 245), (252, 85, 84), (255, 121, 120), (212, 193, 84),
       (230, 206, 128), (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255)]


def png(w, h, px, fn):
    raw = b"".join(b"\x00" + bytes(v for p in row for v in p) for row in px)

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(fn, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class VRAM:
    def __init__(self):
        self.m = bytearray(0x4000)

    def copia(self, rom, src, dst, n):
        self.m[dst:dst + n] = rom[src - ORG:src - ORG + n]

    def rellena(self, dst, n, v):
        self.m[dst:dst + n] = bytes([v]) * n

    def copia_bytes(self, data, dst):
        self.m[dst:dst + len(data)] = data


def rle(rom, a):
    """RLE_A_VRAM (0x6C84): 0 fin; n<0x80 repite n veces el byte siguiente; n>=0x80 copia n&0x7F tal cual."""
    out = bytearray()
    p = a - ORG
    while True:
        n = rom[p]; p += 1
        if n == 0:
            break
        if n & 0x80:
            k = n & 0x7F; out += rom[p:p + k]; p += k
        else:
            out += bytes([rom[p]]) * n; p += 1
    return bytes(out), ORG + p


def espeja_sprites(rom, src, n):
    """ESPEJA_SPRITES (0x4107): n sprites de 16x16 dados la vuelta; la columna
    izquierda pasa a ser la derecha invertida bit a bit, y al reves."""
    out = bytearray()
    for s in range(n):
        izq = rom[src - ORG + s * 32: src - ORG + s * 32 + 16]
        der = rom[src - ORG + s * 32 + 16: src - ORG + s * 32 + 32]
        rev = lambda b: int(f"{b:08b}"[::-1], 2)
        out += bytes(rev(b) for b in der) + bytes(rev(b) for b in izq)
    return bytes(out)


def carga_init(rom):
    """Lo que hace INIT (0x40AF) con la VRAM, en su orden."""
    v = VRAM()
    v.copia(rom, 0x56BF, 0x1800, 0x0C0)      # 40C3
    v.copia(rom, 0x56BF, 0x18C0, 0x2C0)      # 40CF: COPIA_A_VRAM conserva HL, asi que
    #                                          los 22 sprites van OTRA VEZ a partir del 6
    v.copia(rom, 0x597F, 0x1B80, 0x080)      # 40D8
    v.copia(rom, 0x5ABF, 0x1F80, 0x080)      # 40E4 (BC sigue en 0x80)
    v.copia(rom, 0x59FF, 0x1C00, 0x0C0)      # 40ED
    v.copia_bytes(espeja_sprites(rom, 0x56BF, 22), 0x1CC0)   # 4107 + 4130
    pat, fin_pat = rle(rom, 0x5156)
    for t in range(3):
        v.copia_bytes(pat, 0x2000 + t * 0x800)   # 4149-415F
    col, fin_col = rle(rom, 0x566B)
    for t in range(3):
        v.copia_bytes(col, 0x0000 + t * 0x800)   # 4162-4178
    return v, (fin_pat, len(pat)), (fin_col, len(col))


def tile_px(v, tercio, t, esc=2):
    pat = v.m[0x2000 + tercio * 0x800 + t * 8: 0x2000 + tercio * 0x800 + t * 8 + 8]
    col = v.m[0x0000 + tercio * 0x800 + t * 8: 0x0000 + tercio * 0x800 + t * 8 + 8]
    rows = []
    for r in range(8):
        fg, bg = PAL[col[r] >> 4], PAL[col[r] & 15]
        row = []
        for b in range(8):
            row += [fg if (pat[r] >> (7 - b)) & 1 else bg] * esc
        rows += [row] * esc
    return rows


def pinta_tiles(v, fn, esc=2, tercios=(0, 1, 2)):
    W = 32 * 8 * esc + 31
    out = []
    for tercio in tercios:
        for fila in range(8):
            rows = [[(60, 60, 60)] * W for _ in range(8 * esc)]
            for c in range(32):
                t = fila * 32 + c
                px = tile_px(v, tercio, t, esc)
                x0 = c * (8 * esc + 1)
                for r in range(8 * esc):
                    rows[r][x0:x0 + 8 * esc] = px[r]
            out += rows
            out.append([(60, 60, 60)] * W)
        out += [[(255, 0, 0)] * W] * 2
    png(W, len(out), out, fn)


def pinta_sprites(v, fn, esc=2, base=0x1800):
    out = []
    W = 16 * (16 * esc + 1)
    for fila in range(4):
        rows = [[(60, 60, 60)] * W for _ in range(16 * esc)]
        for c in range(16):
            s = fila * 16 + c
            d = v.m[base + s * 32:base + s * 32 + 32]
            for r in range(16):
                bits = (d[r] << 8) | d[16 + r]
                for b in range(16):
                    colr = (255, 255, 255) if (bits >> (15 - b)) & 1 else (0, 0, 0)
                    for dy in range(esc):
                        for dx in range(esc):
                            rows[r * esc + dy][c * (16 * esc + 1) + b * esc + dx] = colr
        out += rows
        out.append([(60, 60, 60)] * W)
    png(W, len(out), out, fn)


def pinta_nombres(v, nombres, fn, esc=2, filas=24):
    """nombres: 32*filas bytes; cada fila cae en su tercio."""
    W = 32 * 8 * esc
    out = []
    for f in range(filas):
        rows = [[(0, 0, 0)] * W for _ in range(8 * esc)]
        for c in range(32):
            t = nombres[f * 32 + c]
            px = tile_px(v, f // 8, t, esc)
            for r in range(8 * esc):
                rows[r][c * 8 * esc:(c + 1) * 8 * esc] = px[r]
        out += rows
    png(W, len(out), out, fn)


def main():
    rom = open(sys.argv[1], "rb").read()
    od = sys.argv[2]
    os.makedirs(od, exist_ok=True)
    v, (fp, lp), (fc, lc) = carga_init(rom)
    print(f"patrones RLE 0x5156 -> acaba en 0x{fp:04X}, {lp} bytes descomprimidos")
    print(f"colores  RLE 0x566B -> acaba en 0x{fc:04X}, {lc} bytes descomprimidos")
    pinta_tiles(v, os.path.join(od, "tiles.png"), tercios=(0,))
    pinta_sprites(v, os.path.join(od, "sprites.png"))
    # los juegos alternativos de 0x6044
    for n in (1, 2):
        p = 0x6044 + n * 4
        a = rom[p - ORG] | rom[p + 1 - ORG] << 8
        b = rom[p + 2 - ORG] | rom[p + 3 - ORG] << 8
        w = VRAM()
        w.m[:] = v.m
        w.copia(rom, a, 0x1800, 0xC0)
        w.copia(rom, b, 0x1C00, 0xC0)
        pinta_sprites(w, os.path.join(od, f"sprites_{n}.png"))
        print(f"juego {n}: 0x{a:04X} -> 0x1800, 0x{b:04X} -> 0x1C00")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Las imagenes de la web, reconstruidas repitiendo lo que hace el cartucho.

    python3 tools/imagenes_web.py monkey.rom docs/imagenes

Nada de aqui es una captura: cada pantalla sale de montar la VRAM con las
mismas rutinas del listado pasadas a Python (los tiles y sprites de INIT por
tools/graficos.py, y encima las listas y tablas concretas), y de pintarla con
tools/pantalla.py, que hace de TMS9918. Lo que produce:

    titulo.png        el titulo: el KONAMI arriba, el dibujo de 0x4CD0 en los
                      tiles 0xB8-0xFF con las bandas de color de 0x4C5F, el
                      "©Konami 1984" y el menu de 0x6B99
    level_select.png  la pantalla de LEVEL SELECT (0x7595)
    fase_N.png        las ocho fases (N = 1..8): plataformas de 0x6705, tarjetas
                      de 0x50AE cerradas, frutas de 0x6806, flores de 0x6B42 y
                      el panel, con la ecuacion de la demo arriba y el mono en
                      el suelo
    tiles.png         los 184 tiles cargados por RLE mas los 12 de 0x5EFF y el
                      titulo, tal como quedan en el primer tercio en el juego
    sprites.png       los 64 sprites como los deja INIT
    tarjetas.png      las diez tarjetas con cifra (0x5040), una metida (solo
                      el canto), una abierta y una a medio bajar
    simbolos.png      los 19 simbolos de la ecuacion (0x7207) en sus tiles
    logo.png          el rotulo del titulo recortado, para la portada
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import ORG, VRAM, carga_init, espeja_sprites, png  # noqa: E402
from pantalla import pantalla  # noqa: E402

W16 = lambda rom, a: rom[a - ORG] | rom[a - ORG + 1] << 8


class Juego:
    """Una VRAM montada por INIT, con lo que le van anadiendo las rutinas."""

    def __init__(self, rom):
        self.rom = rom
        self.v, _, _ = carga_init(rom)
        self.m = self.v.m
        self.m[0x3B00] = 0xD0                      # ESCONDE_SPRITES: ninguno
        self.sprites = []

    # --- las primitivas del cartucho -------------------------------------
    def vpoke(self, de, a):
        self.m[de & 0x3FFF] = a

    def rellena(self, de, n, a):                   # RELLENA_VRAM
        for i in range(n):
            self.m[(de + i) & 0x3FFF] = a

    def copia(self, hl, de, n):                    # COPIA_A_VRAM
        self.m[de:de + n] = self.rom[hl - ORG:hl - ORG + n]

    def lista(self, hl):                           # PINTA_LISTA_TILES (0x48E9)
        p = hl - ORG
        while True:
            de = self.rom[p] | self.rom[p + 1] << 8; p += 2
            while self.rom[p] not in (0xFE, 0xFF):
                self.vpoke(de, self.rom[p]); de += 1; p += 1
            if self.rom[p] == 0xFF:
                return
            p += 1

    def recuadro(self, hl):                        # PINTA_RECUADRO (0x66BB)
        ancho, alto, tile = self.rom[hl - ORG:hl - ORG + 3]
        de = self.rom[hl - ORG + 3] << 8 | self.rom[hl - ORG + 4]
        for f in range(alto):
            self.rellena(de + 32 * f, ancho, tile)

    def bloque(self, hl, d, e, filas, cols):       # PINTA_BLOQUE (0x6906)
        p = hl - ORG
        for f in range(filas):
            for c in range(cols):
                self.vpoke(0x3800 + ((d >> 3) + f) * 32 + (e >> 3) + c, self.rom[p]); p += 1

    def color_fuente(self, a):                     # COLOR_FUENTE (0x4919)
        for t in range(3):
            self.rellena(0x0180 + t * 0x800, 0x180, a)

    def sprite(self, y, x, pat, col):
        self.sprites.append((y, x, pat, col))

    def cierra_sprites(self):
        p = 0x3B00
        for y, x, pat, col in self.sprites:
            self.m[p:p + 4] = bytes([y, x, pat, col]); p += 4
        if p < 0x3B80:
            self.m[p] = 0xD0

    # --- las rutinas del juego -------------------------------------------
    def tiles_ecuacion(self):                      # CARGA_TILES_ECUACION (0x4728)
        for t in range(3):
            self.copia(0x5EFF, 0x25C0 + t * 0x800, 0x60)
            self.rellena(0x05C0 + t * 0x800, 0x30, 0xF4)
            self.rellena(0x05F0 + t * 0x800, 0x30, 0xB0)

    def titulo(self):
        """ESTADO_2_LOGO ya arriba, PREPARA_TITULO, todas las filas de
        TITULO_UNA_FILA y el menu: lo que se ve en el estado 5."""
        # el KONAMI en su sitio final: 0x6C42 con E00E = 0x11 * 0x20 -> 0x3AAA - 0x220 = 0x388A
        de = 0x3AAA - 0x11 * 0x20
        a = 0x16
        for n in (3, 11, 12):
            for i in range(n):
                self.vpoke(de + i, a); a += 1
            de += 0x20
        self.lista(0x6C2C)                         # VIDEO CARTRIDGE (que luego borra 0x4BF0)
        # PREPARA_TITULO
        self.rellena(0x25C0, 0x240, 0)
        self.rellena(0x3966, 0x13, 0)
        for fila, banda in enumerate((0x4C5F, 0x4C67, 0x4C6F)):   # COLORES_TITULO
            for t in range(24):
                self.copia(banda, 0x05C0 + (fila * 24 + t) * 8, 8)
        de = 0x3885; a = 0xB8
        for fila in range(3):
            for i in range(24):
                self.vpoke(de + i, a); a += 1
            de += 0x20
        self.color_fuente(0x70)
        self.rellena(0x0980, 0x80, 0xF0)
        # TITULO_UNA_FILA, 21 veces: 24 bytes por fila de pixel
        for fila in range(21):
            tile_fila, y = divmod(fila, 8)
            for t in range(24):
                self.vpoke(0x25C0 + (tile_fila * 24 + t) * 8 + y, self.rom[0x4CD0 - ORG + fila * 24 + t])
        self.lista(0x6B8B)                         # ©Konami 1984
        self.lista(0x6B99)                         # PLAY SELECT
        self.m[0x3B00] = 0xD0

    def level_select(self, jugador=1):
        """LEVEL_SELECT_PINTA (0x47BA): fondo azul, fuente blanca y 0x7595."""
        self.tiles_ecuacion()
        self.color_fuente(0xF4)
        self.lista(0x75B7)
        self.vpoke(0x3853, 0x30 + jugador)
        self.lista(0x75C0)
        for n in range(5):
            self.lista(0x75D0 + 19 * n)
        self.m[0x3B00] = 0xD0
        return 4                                    # R7 = 4: el fondo azul oscuro

    def marcador(self, fase):
        """PINTA_MARCADOR (0x49B4) y lo que la fase pone encima."""
        f = (fase - 1) & 7
        # PINTA_PLATAFORMAS (0x6685)
        p = W16(self.rom, 0x66F5 + 2 * f) - ORG
        base = self.rom[p] + ((fase >> 1) & 3); p += 1
        while self.rom[p] != 0xFF:
            y, x, n = self.rom[p:p + 3]; p += 3
            self.rellena(0x3800 + (y >> 3) * 32 + (x >> 3), n, base)
        self.recuadro(0x66F0)                       # el panel azul
        self.lista(0x66CC); self.lista(0x66DB); self.lista(0x6B72)
        for i in range(3):                          # el record y los puntos a cero
            self.vpoke(0x38D9 + 2 * i, 0x30); self.vpoke(0x38DA + 2 * i, 0x30)
            self.vpoke(0x3939 + 2 * i, 0x30); self.vpoke(0x393A + 2 * i, 0x30)
        for i in range(3):                          # PINTA_VIDAS: dos vidas de reserva
            self.bloque(0x4AE0 if i < 2 else 0x4AE4, 0x70, 0xC8 + 16 * i, 2, 2)
        self.vpoke(0x3A9A, 0x30 + fase // 10); self.vpoke(0x3A9B, 0x30 + fase % 10)
        for tabla in (0x6B42, 0x6B52, 0x6B62):      # PINTA_FLORES
            self.vpoke(self.rom[tabla - ORG + 2 * f] << 8 | self.rom[tabla - ORG + 2 * f + 1], 0x15)   # el alto primero
        # COLORES_DEL_PANEL (0x665A)
        self.color_fuente(0xF4)
        self.rellena(0x0A00, 0x100, 0xA4); self.rellena(0x0200, 0x100, 0x94); self.rellena(0x1200, 0x100, 0x74)
        # el reloj a 05:00
        self.vpoke(0x387A, 0x30); self.vpoke(0x387B, 0x35); self.vpoke(0x387D, 0x30); self.vpoke(0x387E, 0x30)

    def tarjetas(self, fase, jugador_cifras=None):
        """TARJETAS_DE_LA_FASE (0x4F81) + PINTA_TARJETAS: las diez metidas
        en la plataforma; solo asoma el canto (0x5082) en su (Y, X)."""
        f = (fase - 1) & 7
        p = W16(self.rom, 0x509E + 2 * f) - ORG
        pos = []
        while self.rom[p] != 0xFF:
            pos.append((self.rom[p], self.rom[p + 1])); p += 2
        for y, x in pos:
            self.bloque(0x5082, y, x, 2, 2)          # el canto, bajo la plataforma
        return pos

    def frutas(self, fase):
        """FRUTAS_DE_LA_FASE (0x7E85): los sprites 10-17 y el profesor."""
        f = (fase - 1) & 7
        p = 0x6806 + 32 * f - ORG
        for i in range(8):
            y, x, pat, col = self.rom[p + 4 * i:p + 4 * i + 4]
            self.sprite(y, x, pat, col)
        self.sprite(0x00, 0xC0, 0x00, 0x06); self.sprite(0x00, 0xC0, 0x0C, 0x0F)

    def ecuacion(self, simbolos, x0):
        """Los simbolos ya llegados (GLOBO_LLEGA): bloques de 2x2 de 0x7207 en
        las filas 0-1, desde la X de 0x7325."""
        for i, s in enumerate(simbolos):
            self.bloque(0x7207 + 4 * s, 0x00, x0 + 16 * i, 2, 2)

    def fase(self, n, simbolos, cifra_escondida=None):
        self.tiles_ecuacion()
        self.marcador(n)
        self.tarjetas(n)
        x0 = self.rom[0x7325 - ORG + len(simbolos) - 5]
        self.ecuacion(simbolos, x0)
        self.frutas(n)
        self.sprite(0xA8, 0x08, 0x00, 0x05); self.sprite(0xA8, 0x08, 0x0C, 0x0F)   # el mono
        self.cierra_sprites()
        return 1                                    # R7 = 1: fondo negro


def escala(img, esc):
    big = []
    for row in img:
        r = []
        for p in row:
            r += [p] * esc
        big += [r] * esc
    return big


def guarda(j, fn, esc=2, fondo=None):
    img = pantalla(bytes(j.m))
    if fondo is not None:
        from graficos import PAL
        col = PAL[fondo]
        # el color 0 (transparente) ensena el fondo del registro 7
        img = [[col if p == PAL[0] else p for p in row] for row in img]
    big = escala(img, esc)
    png(256 * esc, 192 * esc, big, fn)


def hoja_tiles(j, fn, esc=3):
    from graficos import pinta_tiles
    pinta_tiles(j.v, fn, esc=esc, tercios=(0,))


def hoja_sprites(rom, fn, esc=3):
    from graficos import pinta_sprites
    v, _, _ = carga_init(rom)
    pinta_sprites(v, fn, esc=esc)


def hoja_tarjetas(rom, fn):
    j = Juego(rom); j.tiles_ecuacion(); j.color_fuente(0xF4)
    for n in range(10):                             # las diez cifras
        j.bloque(0x5040 + 6 * n, 0x10, 0x08 + 24 * n, 3, 2)
    j.bloque(0x5082, 0x40, 0x08, 2, 2)                                            # metida: solo el canto
    j.bloque(0x5040 + 6 * 7, 0x40, 0x30, 3, 2); j.bloque(0x5086, 0x58, 0x30, 2, 2)   # abierta: la cifra y el canto debajo
    j.bloque(0x5040 + 6 * 3 + 2, 0x40, 0x58, 2, 2); j.bloque(0x5082, 0x50, 0x58, 2, 2)   # a medio bajar (c = 1)
    j.m[0x3B00] = 0xD0
    img = pantalla(bytes(j.m))
    img = [row[0:0xF0] for row in img[8:0x70]]
    big = escala(img, 3)
    png(len(img[0]) * 3, len(img) * 3, big, fn)


def hoja_simbolos(rom, fn):
    j = Juego(rom); j.tiles_ecuacion()
    for s in range(19):
        j.bloque(0x7207 + 4 * s, 0x10 + 0x20 * (s // 10), 0x08 + 24 * (s % 10), 2, 2)
    j.m[0x3B00] = 0xD0
    img = pantalla(bytes(j.m))
    img = [row[0:0xF8] for row in img[8:0x48]]
    big = escala(img, 3)
    png(len(img[0]) * 3, len(img) * 3, big, fn)


def main():
    rom = open(sys.argv[1], "rb").read()
    od = sys.argv[2]
    os.makedirs(od, exist_ok=True)
    j = Juego(rom); j.titulo(); guarda(j, os.path.join(od, "titulo.png"))
    j = Juego(rom); r7 = j.level_select(); guarda(j, os.path.join(od, "level_select.png"), fondo=r7)
    demo = [3, 0x0A, 0x12, 0x0E, 5]                 # 3 + ? = 5, la ecuacion de la demo (0x4332)
    for n in range(1, 9):
        j = Juego(rom); j.fase(n, demo)
        guarda(j, os.path.join(od, f"fase_{n}.png"))
    j = Juego(rom); j.tiles_ecuacion(); hoja_tiles(j, os.path.join(od, "tiles.png"))
    hoja_sprites(rom, os.path.join(od, "sprites.png"))
    hoja_tarjetas(rom, os.path.join(od, "tarjetas.png"))
    hoja_simbolos(rom, os.path.join(od, "simbolos.png"))
    # el rotulo del titulo, recortado, para la cabecera de la portada
    j = Juego(rom); j.titulo()
    img = pantalla(bytes(j.m))
    crop = [row[32:232] for row in img[28:60]]
    png(200 * 3, 32 * 3, escala(crop, 3), os.path.join(od, "logo.png"))
    print("hecho:", ", ".join(sorted(os.listdir(od))))


if __name__ == "__main__":
    main()

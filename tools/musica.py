#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `SONIDO_YA` (0x78E7, A = numero; `SONIDO` 0x78DF hace lo mismo
pero solo en partida) y corre `SUENA` (0x796F), que la interrupcion llama cada
cuadro (0x4045).
Uso:  musica.py registros 0x91 [cuadros] | mp3 0x91 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xB0 | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

PIEZAS = [
    P(0x91, "La música del menú", "The menu tune",
      "`ESTADO_18_OPCION` y `LEVEL_SELECT_TECLA`"),
    P(0x93, "La cuenta de READY y la música de fondo",
      "The READY count and the background tune",
      "`READY_CUENTA`; la partida la relanza en 0x44B1"),
    P(0x95, "La tarjeta contra la cifra escondida",
      "The card against the hidden digit", "`TARJETA_COMPARA_CIFRA`"),
    P(0x97, "Los globos", "The balloons", "`GLOBO_MONTA`"),
    P(0x99, "Fase superada", "Stage cleared", "`ESTADO_16_FASE_SUPERADA`"),
    P(0x9B, "La tarjeta llega arriba", "The card reaches the top",
      "`TARJETA_SUBE_LLEGA`; es también la música de fondo cuando el mono "
      "lleva la respuesta"),
    P(0x9D, "Game over", "Game over", "`GAME_OVER`"),
    P(0x9E, "Una pista larga de la tabla", "A long track in the table",
      "ninguna llamada directa: está en la tabla de pistas (0x7A7B)"),
    P(0x9F, "Otra pista larga de la tabla", "Another long track in the table",
      "ninguna llamada directa: está en la tabla de pistas (0x7A7B)"),
]

PAGINA = motor_musica.pagina_basica(
    "`SUENA`, 0x796F, y `SONIDO_YA`, 0x78E7, que le reparte los canales; lo "
    "llama la interrupción en 0x4045",
    "`SUENA`, 0x796F, and `SONIDO_YA`, 0x78E7, which hands it the channels; "
    "the interrupt calls it at 0x4045",
    "C-BIOS MSX1 japonés",
    [("la música del menú (0x91) entera, 518 cuadros",
      "the menu tune (0x91), whole, 518 frames"),
     ("la pista 0x9E entera, 1.405 cuadros, que ninguna rutina pide con un "
      "`ld a` pero está en la tabla",
      "track 0x9E, whole, 1,405 frames, which no routine asks for with an `ld a` but "
      "is in the table")],
    [("Cómo se pide una pieza",
      "`SONIDO_YA` recibe el número en A. Por debajo de 0x91 es un efecto y "
      "usa un solo canal (el C, 0xE026); del 0x91 al 0x9C usa dos canales y "
      "del 0x9D en adelante los tres. El motor no escribe nunca el mezclador "
      "del PSG (registro 7): lo deja el arranque, y aquí se parte de ese "
      "mismo valor, 0xB8. Los 0x9E y 0x9F son pistas de 23 segundos que ninguna "
      "rutina pide con un `ld a`, y la "
      "0xA1, que el juego pide en el título, es en realidad silencio: "
      "dos cuadros y nada que sonar, igual en openMSX.",
      "How a piece is asked for",
      "`SONIDO_YA` takes the number in A. Below 0x91 it is an effect and "
      "uses a single channel (C, 0xE026); from 0x91 to 0x9C it uses two "
      "channels and from 0x9D up all three. The engine never writes the PSG "
      "mixer (register 7): start-up leaves it set, and here it starts from "
      "that same value, 0xB8. Tracks 0x9E and 0x9F last 23 seconds and no "
      "routine asks for them with an `ld a`, and 0xA1, which the game asks for on the title screen, is "
      "really silence: two frames and nothing to play, the same in openMSX.")])

CFG = dict(rom="monkey.rom", org=0x4000, frame=0x796F, pide=0x78E7,
           ram=(0xE010, 0xE02E), hz=60, piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x91, 518, None), (0x9E, 1405, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))

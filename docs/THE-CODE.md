# The code

How the program is put together, with addresses. The names are the ones in
the listing.

## The interrupt is the program

`INTERRUPCION` (0x4038), every frame:

1. acknowledges the VDP interrupt by reading its status;
2. `SUENA` (0x796F), always;
3. `VUELCA_SPRITES` (0x46BA), always;
4. if 0xE005 is zero, sets it, enables interrupts and takes one step:
   `LEE_MANDOS` (0x41A7) from state 7 on and `PASO_DEL_JUEGO` (0x4209);
5. restores everything and returns with `reti`.

`PASO_DEL_JUEGO` counts the clock (0xE003), blinks the 1UP during play, reads
keys 1-5 outside it (`TECLAS_1_A_5`, 0x4678) and dispatches state 0xE000.

## The dispatcher

`DESPACHA` (0x419D) is the `call` followed by a table: `add a,a / pop hl /
call HL_MAS_A / ld e,(hl) / inc hl / ld d,(hl) / ex de,hl / jp (hl)`. The
return address **is** the table of words, so it never returns to the `call`.
Two places use it: 0x4223 with the 20-state table at 0x4226, and 0x602B with
the 11 actor states at 0x602E.

## The twenty states

| | | |
|---|---|---|
| 0 | `ESTADO_0_TITULO` | screen off, sprites and names cleared, music 0xA1 (which is silence) |
| 2 | `ESTADO_2_LOGO` | the KONAMI rises one row every two frames (0x6C42) |
| 3, 4 | wait and `ESTADO_4_TITULO` | the sign, one pixel row at a time (0x4C77) |
| 5 | `ESTADO_5_MENU` | 256 frames of menu |
| 6 | `ESTADO_6_DEMO_MONTA` | wipe, scoreboard and the equation 3 + ? = 5 |
| 1 | `ESTADO_1_GLOBOS` | the balloons rise (0x713D); the same state serves the demo and the game |
| 7 | `ESTADO_7_DEMO` | the demo, with the inputs of the script at 0x4B78 |
| 18 | `ESTADO_18_OPCION` | the chosen option blinks for 0x60 frames |
| 8 | `LEVEL_SELECT` | starts the game the first time, and keys 1-5 |
| 9 | `ESTADO_9_PLAYER_N` | spends the life, and PLAYER n / LEVEL n for 0x65 frames |
| 10 | `ESTADO_10_MONTA_FASE` | cards, a new equation if due, shuffled digits, balloons |
| 11 | `ESTADO_11_READY` | balloons, and READY counting down 15 seconds or until a button |
| 12 | `ESTADO_12_PARTIDA` | the game |
| 13 | `ESTADO_13_VIDA_O_RESUELTA` | life lost or equation solved; GAME OVER with no lives |
| 14, 15 | player swap and decide | |
| 16 | `ESTADO_16_FASE_SUPERADA` | stage + 1 and back to LEVEL SELECT |
| 17, 19 | waits | for the sound to end; 0x80 frames |

States chain through `SIGUIENTE_ESTADO` (0x4661): most end with an `inc
(hl)` on 0xE000. And one trap: `ESTADO_9_PLAYER_N` **spends a life** every
time it is entered, so whoever goes there without having died (equation
solved, 0x6E4A; stage cleared, 0x45C1) adds one first.

## The actors

`MONO_Y_CANGREJOS` (0x4822) passes the controls to 0xE10B, repaints the cards
every eight frames, checks the collision (0x69B0) and calls `ACTOR_PASO`
(0x5F5F) with B = 1 (the monkey) and 2 to 4 (the crabs), the latter between
one and four times per frame depending on the stage.

`ACTOR_PASO` sets IX to the actor's two sprites (0xE0B0 + 8(B−1)) and reads
its record at IX+0x58..0x5F: facing, animation phase, type, state, timer,
load. Before the state, the fruit: `ACTOR_TOCA_FRUTA` (0x6A4F) returns carry,
D and E if one is within 0x16 pixels, and with that the actor picks it up
(jumping), dies or loses a life (if it is in the air). Then the eleven states
of 0x602E:

| | | |
|---|---|---|
| 0 | `ACTOR_ESCONDIDO` | waits and appears at the top centre |
| 1 | `ACTOR_PARADO` | fire jumps, a direction walks |
| 2 | `ACTOR_ANDA` | one pixel, the animation, the floor and the edges |
| 3 | `ACTOR_SALTANDO` | the table at 0x6423; at the top, the card; touching the professor, the delivery |
| 4 | `ACTOR_SUBE_HUECO` | climbs through a gap in the platform above |
| 5 | `ACTOR_SE_HUNDE` | comes down slowly with the card just grabbed |
| 6 | `ACTOR_CAE_ESTADO` | four pixels a frame down to the floor |
| 7 | `ACTOR_SE_DESCUELGA` | the crab crosses the top platform |
| 8 | `ACTOR_TIRA_FRUTA` | the fruit flies off |
| 9 | `CANGREJO_MUERE` | the 500 and back into hiding |
| 10 | `ACTOR_LE_DA_LA_FRUTA` | fright and life lost |

The stage's platforms are the only geometry: `HAY_SUELO` (0x6924) walks the
list of (Y, X, width) at 0x66F5 looking for one at Y + 0x10 that covers the
X, and `HAY_PLATAFORMA_ARRIBA` (0x696B) does the same upwards. There is no
collision map: the table is consulted.

## The cards and the answer

`PINTA_TARJETAS` (0x4EC8) walks the ten at 0xE15A and repaints those with bit
7: the bottom 3 − c rows of a 3×2 block (blank or with the digit,
alternating) and the edge under it. The edge's position comes from
`PINTA_BLOQUE` (0x6906) returning D advanced by as many rows as it painted;
the 8c + Y computed at 0x4F42 stays in A and nobody uses it.

`RESPONDE` (0x7708) starts the blinking, `TARJETA_COMPARA` (0x7796) decides,
and the answer card is sprite 18 driven by the bits of 0xE270 (`TARJETA_PASO`,
0x7834): 4 waits for the card to close, 3 falls, 1 rides on the monkey's
head, 0 rises on its own. The professor (`PROFESOR`, 0x7473) watches the same
bits.

## The equation

`GENERA_ECUACION` (0x6F96) writes symbols into 0xE144 following the level's
script (0x7117) with the BCD arithmetic of 0x6E6E-0x6EDB: add, subtract,
multiply by repeated addition and division done backwards (D × E ÷ D = E).
`ELIGE_INCOGNITA` (0x7253) covers a digit, `MONTA_GLOBOS` (0x7297) prepares
a two-sprite balloon per symbol, off screen at the bottom, and `GLOBOS_SUBEN`
(0x713D) releases them at random one at a time; `GLOBO_LLEGA` (0x71BF) paints
the symbol in 2×2 where each one arrives.

`AZAR` (0x6F0D) mixes the seed at 0xE140 with the R register and with a word
from the system ROM (0x0000-0x3FFF), and remixes with `daa`: the nibbles come
out between 0 and 9, which is what the BCD arithmetic needs.

## The sound

`SONIDO` (0x78DF) starts sound A if a game is on (`SONIDO_YA`, without
checking). 1 to 0x10 are one-channel effects (channel C); 0x91 to 0x9B
two-channel tunes, and from 0x9D three. The table at 0x7A7B gives the first
channel's track and the following words the others', which is why tune
numbers go in twos. Priority is by number: if the channel is playing
something equal or higher, nothing, except 2, which always gets in. `SUENA`
(0x796F) is the player: per channel a note counter, the track, octave, volume
and an envelope of three steps down when the note starts and two at the end.
Effects are volume/period pairs; music is notes in one nibble with the
duration in the other over the period table at 0x7A71.

## What gets painted

`VPOKE` (0x4082) and `RELLENA_VRAM` (0x48AA) are the base; `PINTA_LISTA_TILES`
(0x48E9) walks lists of address + tiles with 0xFE to change place and 0xFF to
end, and every sign is written with it. `PINTA_BLOQUE` (0x6906) paints B×C
tiles at pixel coordinates, `PINTA_RECUADRO` (0x66BB) fills rectangles,
`PIXELS_A_VRAM` (0x6605) turns (Y, X) into a name-table address. `RLE_A_VRAM`
(0x6C84) decompresses the tiles, `ESPEJA_SPRITES` (0x4107) flips 22 sprites
bit by bit, and `TITULO_UNA_FILA` (0x4C77) paints the title sign one pixel
row every eight frames.

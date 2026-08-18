# The cartridge

## The header and the machine

The 16384 bytes begin with `AB`: the BIOS recognises them as a cartridge,
maps them into page 1 (0x4000-0x7FFF) and, once the machine has booted,
calls the header's entry point, **0x40AF**. STATEMENT, DEVICE and TEXT are
zero. The five eight-byte stubs after the header (`pop hl / ld (0),hl /
ret`) are used by nobody: filler for the hooks the header leaves empty.

INIT (0x40AF) disables interrupts, writes `jp 0x4038` into the H.KEYI hook
(0xFD9A), sets the stack at 0xE400, loads video memory, clears the game's
RAM, enables interrupts and sits in a two-byte `jr $` (0x419B). From then on
**the whole game runs inside the interrupt**, one step per frame. 0xE005 is
the lock: if a step takes longer than a frame, the next interrupt plays the
music, flushes the sprites and leaves.

## Video memory

SCREEN 2 with 16×16 sprites (0x488C: R0=02, R1=A2, R2=0E, R3=7F, R4=07,
R5=76, R6=03, R7=E1).

| VRAM | what |
|---|---|
| 0x0000 | tile colours, three identical thirds |
| 0x1800 | the patterns of the 64 sprites |
| 0x2000 | tile patterns, three identical thirds |
| 0x3800 | the name table |
| 0x3B00 | the sprite attributes |

Tiles 0x00-0xB7 come compressed: patterns at 0x5156 (0x515 bytes) and
colours at 0x566B (84 bytes), both with the same RLE (0x6C84: 0 ends;
n < 0x80 repeats the next byte n times; n ≥ 0x80 copies n & 0x7F bytes as
they are). Decompressed they give 1472 bytes each, exactly 184 tiles, and
both blocks end where the next begins. Tiles 0xB8-0xC3 are loaded later by
0x4728 from 0x5EFF: the pieces of the big equation digits that did not fit in
the first block, sharing numbers with the title sign, which is drawn into
tiles 0xB8-0xFF one pixel row at a time (0x4C77).

![The tiles](imagenes/tiles.png)

Of the tiles: 0x00 empty, 0x01-0x04 the card edge, 0x05-0x08 the four
platform bars (one per colour), 0x09-0x0C the red arrow, 0x0D-0x14 the
panel's monkey faces (normal and crying), 0x15 the flower, 0x16-0x2F the big
KONAMI, 0x30-0x5B digits, ©, letters and dash in ASCII, 0x5C-0x5F "key" and
"with" in small type, 0x60 blue, 0x61-0x7A the cards with their digits,
0x7B-0xB7 the big digits and signs.

## The sprites

INIT copies the first six sprites of 0x56BF to 0x1800, and then the 22 of the
same block **again** from 0x18C0, because COPIA_A_VRAM leaves HL as it was
(0x40CF). So VRAM sprite n, for n from 6 to 27, is the cartridge's n − 6:
that is why the monkey is at patterns 0x00 and 0x18, and the crab at 0x30.
The same 22 are mirrored bit by bit (0x4107) into 0x1CC0: the mirror of
sprite k is pattern 0x98 + 4k. Besides, 0x597F (500, 100, banana and grapes)
goes to 0x1B80, 0x59FF (the monkey walking left, drawn separately) to 0x1C00
and 0x5ABF (the big face, the apple and the card) to 0x1F80.

![The sprites](imagenes/sprites.png)

Every character is two overlaid sprites: the body in one colour and the
details in another (the monkey blue and white, the crab red and yellow, the
professor dark red and white). And the game swaps whole blocks depending on
what the monkey carries: 0x6044 points to three sets —normal, with the fruit
on his head (0x5B3F) and with the card held high (0x5BFF)—, and 0x5F80 loads
whichever 0xE10E asks for into 0x1800 and 0x1C00. The balloons (0x5E3F)
overwrite the 500 at 0x1B80 while the equation rises, and the big face of
0x5E7F overwrites the monkey at 0x1800 when the answer is delivered.

The sprite table lives at 0xE0B0 (24 × 4 bytes) and 0x46BA flushes it every
frame **starting from a different one each time** (0xE1B2 goes from 23 down
to 0): the TMS9918's four-sprites-per-line limit rotates and no sprite is the
one that always disappears.

## The RAM map

All in 0xE000-0xE3FF, cleared by INIT. What matters:

| | |
|---|---|
| 0xE000 | the game state, index into the table at 0x4226 |
| 0xE002 | options: bit 4 keyboard, bit 5 two players, bit 6 game on, bit 7 the player |
| 0xE008/9 | the controls, before and now, in joystick format |
| 0xE010 | the three sound channels, 10 bytes each |
| 0xE040 | the high score; 0xE043 and 0xE046 each player's score (BCD, 6 digits) |
| 0xE050 | the player in play: lives, stage, extra life, new equation, solved, time, misses, symbols; 0xE080 the other one's copy |
| 0xE0B0 | the sprite table: 0-1 the monkey, 2-7 the crabs, 8-9 the professor, 10-17 the fruit, 18 the card |
| 0xE108 | the four actors, 8 bytes each, read from their sprite as IX+0x58 |
| 0xE140 | the random seed |
| 0xE142 | the equation's result; 0xE144 the equation in symbols |
| 0xE15A | the ten cards of the stage (Y, X) |
| 0xE1AF | the card the monkey holds (0xFF none) |
| 0xE1B5 / 0xE1C1 | each player's equation; 0xE1CD/E the hidden digit |
| 0xE1E4 / 0xE20E | each player's cards: state and digit |
| 0xE24C | the state of each balloon |
| 0xE260 | the eight fruits: state and counter |
| 0xE270, 0xE276 | the answer's and the professor's flags |

## What it is made of

| | bytes |
|---|---|
| code | 8,962 |
| data | 7,422 |
| unidentified | 0 |

Of the data: 1,472 + 84 of compressed tiles (0x5156, 0x566B), 2,688 of
sprites (0x56BF-0x5F5F), 504 of the title sign (0x4CD0), 1,044 of sound
(0x7A71-0x7E85), 287 of 0xFF filler at the end, and the rest tables and
lists: card positions per stage (0x50AE, 21 bytes each), platforms (0x6705),
fruit (0x6806, 32 bytes per stage), flowers (0x6B42), equation scripts
(0x712B), symbols (0x7207), the text of every sign and the tables of the two
dispatchers.

There are five pieces of code nobody jumps to, seeded into the trace so they
show as what they are: `push iy / ret` at 0x4072, a `ld a,0F0h` at 0x4917
that nobody uses, a list-driven platform painter (0x664F, 0x6624, 0x65F8)
that 0x6685 left without a job, the entry of RLE_A_VRAM that reads the
address ahead of the data (0x6C80), and nine bytes at 0x755C that fall into
0x7565.

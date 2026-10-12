# The music

Everything you hear here comes from running the cartridge's own sound engine (`SUENA`, 0x796F, and `SONIDO_YA`, 0x78E7, which hands it the channels; the interrupt calls it at 0x4045) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the menu tune (0x91), whole, 518 frames;
- track 0x9E, whole, 1,405 frames, which no routine asks for with an `ld a` but is in the table.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`SONIDO_YA` takes the number in A. Below 0x91 it is an effect and uses a single channel (C, 0xE026); from 0x91 to 0x9C it uses two channels and from 0x9D up all three. The engine never writes the PSG mixer (register 7): start-up leaves it set, and here it starts from that same value, 0xB8. Tracks 0x9E and 0x9F last 23 seconds and no routine asks for them with an `ld a`, and 0xA1, which the game asks for on the title screen, is really silence: two frames and nothing to play, the same in openMSX.

## The tunes

**The menu tune** (0x91)

Asked for by `ESTADO_18_OPCION` y `LEVEL_SELECT_TECLA`; lasts 8.6 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=c9b2e19a"></audio>

**The READY count and the background tune** (0x93)

Asked for by `READY_CUENTA`; la partida la relanza en 0x44B1; lasts 6.5 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=55843129"></audio>

**The card against the hidden digit** (0x95)

Asked for by `TARJETA_COMPARA_CIFRA`; lasts 3.6 s.

<audio controls preload="none" src="audio/musica_95.mp3?v=907a2c39"></audio>

**The balloons** (0x97)

Asked for by `GLOBO_MONTA`; lasts 4.3 s.

<audio controls preload="none" src="audio/musica_97.mp3?v=1ec26abe"></audio>

**Stage cleared** (0x99)

Asked for by `ESTADO_16_FASE_SUPERADA`; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_99.mp3?v=c7f403f8"></audio>

**The card reaches the top** (0x9B)

Asked for by `TARJETA_SUBE_LLEGA`; es también la música de fondo cuando el mono lleva la respuesta; lasts 4.3 s.

<audio controls preload="none" src="audio/musica_9B.mp3?v=48aa95fa"></audio>

**Game over** (0x9D)

Asked for by `GAME_OVER`; lasts 3.9 s.

<audio controls preload="none" src="audio/musica_9D.mp3?v=34e7deaa"></audio>

**A long track in the table** (0x9E)

Asked for by ninguna llamada directa: está en la tabla de pistas (0x7A7B); lasts 23.4 s.

<audio controls preload="none" src="audio/musica_9E.mp3?v=096f3c50"></audio>

**Another long track in the table** (0x9F)

Asked for by ninguna llamada directa: está en la tabla de pistas (0x7A7B); lasts 23.4 s.

<audio controls preload="none" src="audio/musica_9F.mp3?v=7c618a0f"></audio>

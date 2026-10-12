# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`SUENA`, 0x796F, y `SONIDO_YA`, 0x78E7, que le reparte los canales; lo llama la interrupción en 0x4045) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música del menú (0x91) entera, 518 cuadros;
- la pista 0x9E entera, 1.405 cuadros, que ninguna rutina pide con un `ld a` pero está en la tabla.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`SONIDO_YA` recibe el número en A. Por debajo de 0x91 es un efecto y usa un solo canal (el C, 0xE026); del 0x91 al 0x9C usa dos canales y del 0x9D en adelante los tres. El motor no escribe nunca el mezclador del PSG (registro 7): lo deja el arranque, y aquí se parte de ese mismo valor, 0xB8. Los 0x9E y 0x9F son pistas de 23 segundos que ninguna rutina pide con un `ld a`, y la 0xA1, que el juego pide en el título, es en realidad silencio: dos cuadros y nada que sonar, igual en openMSX.

## Las músicas

**La música del menú** (0x91)

Lo pide `ESTADO_18_OPCION` y `LEVEL_SELECT_TECLA`; dura 8,6 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=c9b2e19a"></audio>

**La cuenta de READY y la música de fondo** (0x93)

Lo pide `READY_CUENTA`; la partida la relanza en 0x44B1; dura 6,5 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=55843129"></audio>

**La tarjeta contra la cifra escondida** (0x95)

Lo pide `TARJETA_COMPARA_CIFRA`; dura 3,6 s.

<audio controls preload="none" src="../audio/musica_95.mp3?v=907a2c39"></audio>

**Los globos** (0x97)

Lo pide `GLOBO_MONTA`; dura 4,3 s.

<audio controls preload="none" src="../audio/musica_97.mp3?v=1ec26abe"></audio>

**Fase superada** (0x99)

Lo pide `ESTADO_16_FASE_SUPERADA`; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_99.mp3?v=c7f403f8"></audio>

**La tarjeta llega arriba** (0x9B)

Lo pide `TARJETA_SUBE_LLEGA`; es también la música de fondo cuando el mono lleva la respuesta; dura 4,3 s.

<audio controls preload="none" src="../audio/musica_9B.mp3?v=48aa95fa"></audio>

**Game over** (0x9D)

Lo pide `GAME_OVER`; dura 3,9 s.

<audio controls preload="none" src="../audio/musica_9D.mp3?v=34e7deaa"></audio>

**Una pista larga de la tabla** (0x9E)

Lo pide ninguna llamada directa: está en la tabla de pistas (0x7A7B); dura 23,4 s.

<audio controls preload="none" src="../audio/musica_9E.mp3?v=096f3c50"></audio>

**Otra pista larga de la tabla** (0x9F)

Lo pide ninguna llamada directa: está en la tabla de pistas (0x7A7B); dura 23,4 s.

<audio controls preload="none" src="../audio/musica_9F.mp3?v=7c618a0f"></audio>

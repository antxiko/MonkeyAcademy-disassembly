# El código

Cómo está montado el programa, con las direcciones. Los nombres son los del
listado.

## La interrupción es el programa

`INTERRUPCION` (0x4038), en cada fotograma:

1. reconoce la interrupción del VDP leyendo su estado;
2. `SUENA` (0x796F), siempre;
3. `VUELCA_SPRITES` (0x46BA), siempre;
4. si 0xE005 está a cero, lo pone, habilita interrupciones y da un paso:
   `LEE_MANDOS` (0x41A7) a partir del estado 7 y `PASO_DEL_JUEGO` (0x4209);
5. recupera todo y vuelve con `reti`.

`PASO_DEL_JUEGO` cuenta el reloj (0xE003), hace parpadear el 1UP en la
partida, mira las teclas 1-5 fuera de ella (`TECLAS_1_A_5`, 0x4678) y
despacha el estado 0xE000.

## El despachador

`DESPACHA` (0x419D) es el `call` seguido de tabla: `add a,a / pop hl / call
HL_MAS_A / ld e,(hl) / inc hl / ld d,(hl) / ex de,hl / jp (hl)`. La dirección
de retorno **es** la tabla de palabras, así que nunca vuelve al `call`. Lo
usan dos sitios: 0x4223 con la tabla de 20 estados de 0x4226, y 0x602B con la
de 11 estados de actor de 0x602E.

## Los veinte estados

| | | |
|---|---|---|
| 0 | `ESTADO_0_TITULO` | pantalla apagada, sprites y nombres a cero, música 0xA1 (que es silencio) |
| 2 | `ESTADO_2_LOGO` | el KONAMI sube una fila cada dos fotogramas (0x6C42) |
| 3, 4 | espera y `ESTADO_4_TITULO` | el rótulo, fila de pixels a fila de pixels (0x4C77) |
| 5 | `ESTADO_5_MENU` | 256 fotogramas de menú |
| 6 | `ESTADO_6_DEMO_MONTA` | cortinilla, marcador y la ecuación 3 + ? = 5 |
| 1 | `ESTADO_1_GLOBOS` | los globos suben (0x713D); es el mismo estado para la demo y la partida |
| 7 | `ESTADO_7_DEMO` | la demo, con los mandos del guión de 0x4B78 |
| 18 | `ESTADO_18_OPCION` | la opción elegida parpadea 0x60 fotogramas |
| 8 | `LEVEL_SELECT` | arranca la partida la primera vez, y las teclas 1-5 |
| 9 | `ESTADO_9_PLAYER_N` | gasta la vida, y PLAYER n / LEVEL n durante 0x65 fotogramas |
| 10 | `ESTADO_10_MONTA_FASE` | tarjetas, ecuación nueva si toca, cifras barajadas, globos |
| 11 | `ESTADO_11_READY` | globos, y READY con cuenta atrás de 15 segundos o hasta un botón |
| 12 | `ESTADO_12_PARTIDA` | la partida |
| 13 | `ESTADO_13_VIDA_O_RESUELTA` | vida perdida o ecuación resuelta; GAME OVER sin vidas |
| 14, 15 | cambio de jugador y decidir | |
| 16 | `ESTADO_16_FASE_SUPERADA` | fase + 1 y de vuelta al LEVEL SELECT |
| 17, 19 | esperas | a que calle el sonido; 0x80 fotogramas |

Los estados encadenan por `SIGUIENTE_ESTADO` (0x4661): la mayoría acaba con
un `inc (hl)` sobre 0xE000. Y una trampa: `ESTADO_9_PLAYER_N` **gasta una
vida** cada vez que entra, así que quien va a él sin haber muerto (la
ecuación resuelta, 0x6E4A; la fase superada, 0x45C1) le suma una antes.

## Los actores

`MONO_Y_CANGREJOS` (0x4822) pasa los mandos a 0xE10B, repinta las tarjetas
cada ocho fotogramas, mira la colisión (0x69B0) y llama a `ACTOR_PASO`
(0x5F5F) con B = 1 (el mono) y de 2 a 4 (los cangrejos), estos entre una y
cuatro veces por fotograma según la fase.

`ACTOR_PASO` deja en IX los dos sprites del actor (0xE0B0 + 8(B−1)) y lee su
registro en IX+0x58..0x5F: sentido, fase de la animación, tipo, estado,
temporizador, carga. Antes del estado, las frutas: `ACTOR_TOCA_FRUTA`
(0x6A4F) devuelve carry, D y E si alguna está a menos de 0x16 pixels, y con
eso el actor la coge (saltando), se muere o pierde la vida (si va por el
aire). Luego los once estados de 0x602E:

| | | |
|---|---|---|
| 0 | `ACTOR_ESCONDIDO` | espera y aparece arriba en el centro |
| 1 | `ACTOR_PARADO` | disparo salta, dirección anda |
| 2 | `ACTOR_ANDA` | un pixel, la animación, el suelo y los bordes |
| 3 | `ACTOR_SALTANDO` | la tabla de 0x6423; en lo alto, la tarjeta; tocando al profesor, la entrega |
| 4 | `ACTOR_SUBE_HUECO` | trepa por un hueco de la plataforma de arriba |
| 5 | `ACTOR_SE_HUNDE` | baja despacio con la tarjeta recién cogida |
| 6 | `ACTOR_CAE_ESTADO` | cuatro pixels por fotograma hasta el suelo |
| 7 | `ACTOR_SE_DESCUELGA` | el cangrejo cruza la plataforma de arriba |
| 8 | `ACTOR_TIRA_FRUTA` | la fruta sale volando |
| 9 | `CANGREJO_MUERE` | el 500 y a esconderse |
| 10 | `ACTOR_LE_DA_LA_FRUTA` | susto y vida perdida |

Las plataformas de la fase son la única geometría: `HAY_SUELO` (0x6924)
recorre la lista de (Y, X, ancho) de 0x66F5 buscando una a Y + 0x10 que
cubra la X, y `HAY_PLATAFORMA_ARRIBA` (0x696B) hace lo mismo hacia arriba.
No hay mapa de colisiones: se consulta la tabla.

## Las tarjetas y la respuesta

`PINTA_TARJETAS` (0x4EC8) recorre las diez de 0xE15A y repinta las que llevan
el bit 7: las 3 − c filas de abajo de un bloque de 3×2 (en blanco o con la
cifra, alternando) y debajo el canto. La posición del canto sale de que
`PINTA_BLOQUE` (0x6906) devuelve D avanzado tantas filas como pintó; el
8c + Y que calcula 0x4F42 se queda en A y no lo usa nadie.

`RESPONDE` (0x7708) arranca el parpadeo, `TARJETA_COMPARA` (0x7796) decide, y
la tarjeta de la respuesta es el sprite 18 gobernado por los bits de 0xE270
(`TARJETA_PASO`, 0x7834): 4 espera a que la tarjeta se cierre, 3 cae, 1 va en
la cabeza del mono, 0 sube sola. El profesor (`PROFESOR`, 0x7473) mira los
mismos bits.

## La ecuación

`GENERA_ECUACION` (0x6F96) escribe símbolos en 0xE144 siguiendo el guión del
nivel (0x7117) con la aritmética en BCD de 0x6E6E-0x6EDB: suma, resta,
producto por sumas repetidas y la división al revés (D × E ÷ D = E).
`ELIGE_INCOGNITA` (0x7253) tapa una cifra, `MONTA_GLOBOS` (0x7297) prepara un
globo de dos sprites por símbolo, fuera de la pantalla por abajo, y
`GLOBOS_SUBEN` (0x713D) los suelta al azar de uno en uno; `GLOBO_LLEGA`
(0x71BF) pinta el símbolo en 2×2 donde llega cada uno.

`AZAR` (0x6F0D) mezcla la semilla de 0xE140 con el registro R y con una
palabra de la ROM del sistema (0x0000-0x3FFF), y remezcla con `daa`: los
nibbles salen entre 0 y 9, que es lo que la aritmética BCD necesita.

## El sonido

`SONIDO` (0x78DF) arranca el sonido A si hay partida (`SONIDO_YA`, sin
mirarlo). Del 1 al 0x10 son efectos de un canal (el C); del 0x91 al 0x9B
músicas de dos canales, y desde 0x9D de tres. La tabla de 0x7A7B da la pista
del primer canal y las palabras siguientes las de los demás, por eso los
números de música van de dos en dos. La prioridad es por número: si el canal
suena algo igual o mayor, nada, salvo el 2, que siempre entra. `SUENA`
(0x796F) es el reproductor: por canal, un contador de nota, la pista, octava,
volumen y una envolvente de tres pasos abajo al arrancar la nota y dos al
acabar. Los efectos son parejas volumen/periodo; la música, notas de un
nibble con la duración en el otro sobre la tabla de periodos de 0x7A71.

## Lo que se pinta

`VPOKE` (0x4082) y `RELLENA_VRAM` (0x48AA) son la base; `PINTA_LISTA_TILES`
(0x48E9) recorre listas de dirección + tiles con 0xFE para cambiar de sitio y
0xFF de fin, y con eso están escritos todos los rótulos. `PINTA_BLOQUE`
(0x6906) pinta B×C tiles en pixels, `PINTA_RECUADRO` (0x66BB) rellena
rectángulos, `PIXELS_A_VRAM` (0x6605) convierte (Y, X) en dirección de
nombres. `RLE_A_VRAM` (0x6C84) descomprime los tiles, `ESPEJA_SPRITES`
(0x4107) da la vuelta a 22 sprites bit a bit, y `TITULO_UNA_FILA` (0x4C77)
pinta el rótulo del título una fila de pixels cada ocho fotogramas.

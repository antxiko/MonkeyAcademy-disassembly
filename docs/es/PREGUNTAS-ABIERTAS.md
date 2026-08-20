# Preguntas abiertas

Lo que el binario no cierra por sí solo. Todo el cartucho está explicado byte
a byte; esto es lo que queda por medir o por decidir.

## Qué son las ocho listas de 0x67C2

Entre las plataformas y las frutas hay ocho listas de posiciones X acabadas en
0xFF, una por fase, y ninguna instrucción del trazado las apunta. Por su
sitio y su forma parecen un reparto anterior de flores o de frutas que se
quedó sin usar. No se ha encontrado en el trazado ninguna instrucción que
las lea.

## El azar de guiones que se anuló

`GENERA_ECUACION` calcula un desplazamiento al azar de 0 a 7 para elegir
entre varios guiones por nivel y lo descarta con un `xor a`. Las tablas de
desplazamientos que quedan son de un solo byte, así que hoy solo hay un
guión por nivel. Si en algún momento hubo más, o si el `xor a` es lo que
dejó el nivel 5 con su único guión de cinco símbolos, el binario no lo dice.

## Cuánto dura una partida completa

La fase es BCD y `PINTA_FASE` (0x4A24) la devuelve a 0 al llegar a 100, y las
tablas de plataformas, tarjetas y frutas se indexan con (fase − 1) & 7, así
que las ocho fases se repiten. Lo que sube es cuántos cangrejos juegan (uno
hasta la fase 7, dos de la 8 a la 15, los tres desde la 16; 0x4850) y lo poco
que esperan escondidos (desde la 20, un fotograma). Queda por jugar de verdad
hasta ahí para ver si el juego se vuelve injugable antes o si la vuelta a la
fase 0 tiene algún efecto que el código no deja ver. Una medida, por ahora:
una partida de un jugador novato, en los niveles 4 y 5, duró 5 min 37 s desde
el LEVEL SELECT hasta el GAME OVER, con una fase superada y 8.360 puntos
(replay en `work/omsx/partida`).

## Los dos guiones de la demo que no cuadran

`ESTADO_6_DEMO_MONTA` (0x42FF) pone las cifras 2 a 7 en las tarjetas 4 a 9 y
deja las 0 a 3 con la cifra 0, y la cifra escondida es el 2. El guión de
mandos de 0x4B78 lleva la demo a la tarjeta buena, pero no se ha comprobado
qué pasaría si el azar de las frutas o de los cangrejos la desviara: el guión
es fijo y los cangrejos no.

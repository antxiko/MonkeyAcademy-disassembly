# Hallazgos

Lo que ha aparecido al desmontarlo y no se ve jugando. Cada cosa con su
dirección; lo que se ha medido en el emulador, con la medida.

## El `?` nunca va más allá de lo que vale la primera cifra

`ELIGE_INCOGNITA` (0x7253) elige la cifra que se tapa restando un número al
azar de 0 a 15 al **valor** de la primera cifra de la ecuación, y toma eso
como posición. Con un 9 delante el `?` puede caer en cualquiera de las diez
primeras posiciones; con un 1 delante, solo en el primer operando. Medido con
400 ecuaciones del nivel 1 en el emulador: 0 excepciones, 238 de 400 con el
`?` en las dos primeras posiciones y solo 67 en el resultado. La cifra que se
tapa depende de la que se ve.

## Los operandos nunca acaban en 0 ni en 1

`OPERANDO` (0x6F45) repite el azar hasta que las unidades salen entre 2 y 9.
En 400 ecuaciones no hay ni un operando acabado en 0 ni en 1: 3?+7, 82+6,
89+9?… El resultado sí puede.

## La división se genera al revés

Para el nivel 3 (`DIVISION`, 0x6EDE) no se dividen dos números: se eligen D y
E entre 1 y 9, se escribe D × E, el signo de dividir, D, y el resultado es E.
La división es siempre exacta porque se construye desde el cociente. Y el
nivel 5 hace a × ( b + c ) con la multiplicación de 0x6EC1: sumar el número
a sí mismo b − 1 veces, en BCD.

## Un azar de guiones anulado con un `xor a`

`GENERA_ECUACION` (0x6FBC) hace `call AZAR / and 7 / xor a / call HL_MAS_A`:
calcula un desplazamiento al azar de 0 a 7 y lo tira antes de usarlo, así que
cada nivel usa siempre el primer guión de su tabla. La tabla de 0x7117 lleva
un segundo puntero por nivel para esos desplazamientos, y apunta al 0 que
cierra el propio guión.

## Los cinco niveles son cinco guiones de tres a cinco bytes

`0A 0E` (+ =), `0B 0E` (− =), `0D 0E` (÷ =), `0C 0E` (× =) y `0C 10 0A 11 0E`
(× ( + ) =) en 0x712B: eso es todo lo que distingue un nivel de otro. El
resto —qué operandos, cuántas cifras, si hay signo— lo decide el generador
al ver el símbolo. Un `jp z,7117h` para el símbolo 0x0F, que no aparece en
ningún guión, salta a la tabla si alguna vez se diera.

## Los 22 sprites están dos veces en la VRAM

INIT copia 0xC0 bytes de 0x56BF a 0x1800 y luego 0x2C0 a 0x18C0 sin volver a
cargar HL: `COPIA_A_VRAM` (0x4894) lo guarda y lo devuelve. Los seis primeros
sprites quedan en 0-5 y los 22 otra vez en 6-27, y el juego usa los segundos:
el mono es el patrón 0x18, el cangrejo el 0x30. Los patrones 0-5 se pisan
luego con el juego de sprites que toque (0x6044).

## El profesor es el mono del jugador, en rojo

Los sprites 8 y 9 (0x7ED9) tienen los patrones 0x00 y 0x0C del mono con los
colores 6 y 15, y anda con las mismas fases (0x7585, 0x758D). El mono que
trae la respuesta en globo al tercer fallo también es el jugador: los
patrones de trepar espejados (0xC8/0xCC), con los brazos arriba agarrado al
globo, en cyan y rojo claro (0x6D76).

## El canto de la tarjeta se coloca solo

`PINTA_TARJETAS` (0x4F42) calcula `8c + Y` en A —donde tendría que ir el
canto según cuánto ha bajado la tarjeta— y no lo usa: llama a `PINTA_BLOQUE`
con el D que había. Pero como `PINTA_BLOQUE` (0x6906) devuelve D avanzado
tantas filas como ha pintado, el canto cae de todas formas justo debajo de la
tarjeta. El cálculo sobra y el resultado es el correcto.

## Solo el tercer cangrejo salta, y por eso solo él tira frutas

`ACTOR_ANDA_X` (0x616F) solo deja que el tipo 3 ponga el bit 4 —que para un
cangrejo es el disparo— cuando el azar de 0xE140 sale a cero. Como saltar es la única forma de
coger una fruta colgada, la fruta que lleva un cangrejo sigue siempre al
sprite de 0xE0C8 (0x7371): el del actor 4, que es el del tipo 3. El código
lo da por hecho en vez de mirar quién la lleva. Y como el tercer cangrejo no
entra en juego hasta la fase 10 (ver abajo), antes de ella ningún cangrejo
tira nada: en 900 segundos medidos en las fases 1 y 2 no saltó ninguno,
aunque 0xE140 sí salió a cero (9 veces en 592 tiradas).

## El sonido 0xA1 es el silencio

Las tres entradas de 0xA1 en la tabla de 0x7A7B apuntan al mismo byte, un
0xFF en 0x7B1B: tres pistas mudas que callan los tres canales. Es lo que suena
al arrancar el título y cuando el mono va con el profesor. Y el 0xA0 (perder
la vida) entra sobre cualquier cosa pero se apunta como 0x20 (0x7929), así
que después lo pisa lo que venga.

## Los efectos son del mono

`SONIDO_DEL_ACTOR` (0x78F7): un efecto pedido desde un actor solo suena si el
actor es el mono, con una excepción, el 9, el del cangrejo que se muere. Los
pasos, los saltos y las caídas de los cangrejos no suenan.

## Hasta la fase 7 solo hay un cangrejo

`MONO_Y_CANGREJOS` (0x4850) calcula fase/8 + 2 (tope 4) y el bucle de 0x4860
llama a `ACTOR_PASO` con ese número en B, bajando hasta 1; y `ACTOR_PASO`
mueve **al actor número B** (IX = 0xE0B0 + 8·(B−1), 0x5F68). Así que no es
cuántas veces se mueve cada cangrejo, sino cuántos juegan: uno hasta la fase
7, dos en la 8 y la 9, los tres desde la 10. Un fotograma de cada cuatro
(0xE272) solo se mueve el mono. Primero se leyó al revés ("fase/8 + 1 veces
por fotograma"); lo destapó una partida medida: en 1003 fotogramas de la
fase 1, el mono dio 1003 pasos, el primer cangrejo 752 y los otros dos cero.
Esperan escondidos (16 − fase) × 16 + 17 fotogramas hasta la fase 19; desde
la 20, uno (0x6585).

## Al READY se le puede meter prisa

El READY (0x43EE) cuenta 15 segundos en BCD (0xE242) y arranca solo al llegar
a cero, o antes con cualquier botón nuevo. Y el LEVEL SELECT (0x762F) espera
0x0F00 fotogramas —64 segundos— y sigue con el nivel que hubiera.

## El generador de azar lee la BIOS

`AZAR` (0x6F0D) coge una palabra de la ROM del sistema en 0x0000-0x3FFF,
usando la semilla como dirección, y la mezcla con la semilla y con el
registro R. La BIOS hace de tabla de ruido. Y el `daa` de la mezcla deja los
nibbles entre 0 y 9: el azar sale ya en BCD.

## No hay créditos

En el binario no hay iniciales ni nombres: solo el KONAMI grande de los tiles
0x16-0x2F, que sube al arrancar, y el "©Konami 1984" en letra pequeña
(0x3A-0x3F), escrito bajo el título y en el pie del panel.

## Sobras

Un pintador de plataformas por lista (0x664F → 0x6624 → 0x65F8) que hace lo
mismo que 0x6685 y al que no llama nadie; ocho listas de posiciones alineadas
con las ocho fases (0x67C2) que nadie apunta, entre las plataformas y las
frutas; y 287 bytes a 0xFF al final.

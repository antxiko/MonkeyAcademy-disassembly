# Monkey Academy (Konami, 1984, MSX1) — desensamblado comentado

El cartucho de aritmética de Konami para MSX, desmontado byte a byte. Los
16.384 bytes están acotados y explicados: ni un hueco sin justificar, ni un
"bloque de gráficos", ni una tabla adivinada.

📖 **[Documentación completa](https://antxiko.github.io/MonkeyAcademy-disassembly/es/)**

[README in English](README.md)

---

## Qué es esto

*Monkey Academy* es el RC-702, el cartucho de Konami en el que un mono
busca la cifra que falta en una cuenta abriendo tarjetas colgadas de las
plataformas mientras los cangrejos van a por él. Aquí está su código,
comentado, con las herramientas para volver a montarlo y comprobar que lo que
sale es el original.

La máquina mapea los 16 KB en 0x4000-0x7FFF —la página 1—, la BIOS llama al
punto de entrada 0x40AF, y de ahí el programa ya no vuelve: el arranque
escribe un `jp` en el gancho H.KEYI y se mete en un bucle de dos bytes, así
que **el juego entero corre dentro de la interrupción**, un paso por
fotograma. Si un paso tarda más de un fotograma, la interrupción siguiente
toca la música y se va.

## Por qué esto se puede creer

`make` traza el flujo, construye el listado y exige que al ensamblarlo salga
exactamente el original:

```
  ensamblado : 16384 bytes  fdf62cfa...20b16b01
  original   : 16384 bytes  fdf62cfa...20b16b01
OK: reproducible byte a byte
```

Un listado puede reensamblar perfectamente y estar mal —si se leen dibujos
como instrucciones, los bytes no cambian—, así que corren dos comprobaciones
más: ningún rango declarado como datos puede salir como código, y ningún
punto de entrada puede caer dentro de uno.

Los gráficos se comprueban por una tercera vía. `tools/graficos.py`
reconstruye la memoria de vídeo repitiendo las copias del propio cartucho, en
el mismo orden y a las mismas direcciones, y el resultado coincide sprite a
sprite con un volcado de la VRAM del emulador. Y lo que el código dice del
generador de ecuaciones se ha medido: seiscientas ecuaciones muestreadas en
el emulador, en los cinco niveles.

## El juego en cifras

| | |
|---|---|
| bytes de código | 8.962 |
| bytes de datos | 7.422 |
| bytes sin identificar | **0** |
| etiquetas con nombre | 498 |
| comentarios anclados | 997 |
| rangos de datos con explicación | 121 |

## Algunas cosas que han salido

- **La cifra que se tapa depende de la que se ve.** El `?` se coloca restando
  un azar de 0 a 15 al *valor* de la primera cifra de la ecuación (0x7253):
  con un 1 delante nunca sale del primer operando. En 400 ecuaciones medidas,
  cero excepciones y solo 67 con el `?` en el resultado.
- **Los operandos nunca acaban en 0 ni en 1**, y la división se genera al
  revés: se eligen el divisor y el cociente y se escribe su producto delante
  (0x6EDE). Toda la aritmética es BCD, la multiplicación por sumas repetidas.
- **Cinco niveles son cinco guiones** de tres a cinco bytes (0x712B): más,
  menos, dividir, por, y a × ( b + c ). Un azar de guiones alternativos está
  anulado con un `xor a` (0x6FBC).
- **Los 22 sprites están dos veces en la VRAM**, porque la copia conserva HL
  (0x40CF): el juego usa la segunda tanda, y el profesor es el mono del
  jugador en rojo oscuro.
- **Las frutas se tiran unos a otros.** Se cogen saltando, se lanzan con el
  botón por dos parábolas de tabla, y la que va por el aire mata al cangrejo
  (500) o al mono. Solo el tercer cangrejo salta, y por eso solo él tira.
- **El sonido 0xA1 es el silencio**: tres pistas mudas que apuntan al mismo
  0xFF. Y los efectos son del mono: los pasos y saltos de los cangrejos no
  suenan (0x78F7).
- **No hay créditos** en el binario: solo el KONAMI grande que sube al
  arrancar y el ©Konami 1984 en tiles pequeños.

## Cómo empezar

Hacen falta `pasmo`, `z80dasm` y Python 3. La imagen del cartucho **no** se
distribuye aquí: pon la tuya en la raíz como `monkey.rom`, 16384 bytes,
sha256 `fdf62cfa6db239fcaa3614b56263dd58e8797b206663e491588c062220b16b01`.

```sh
make          # traza, construye el listado y lo comprueba todo
make verify   # ensambla y compara con el cartucho
make sanity   # lo que el reensamblado no puede cazar
```

## Licencia y atribución

El juego no es nuestro: *Monkey Academy* es de Konami, y todos los derechos
siguen siendo de sus titulares. Lo que sí es nuestro —las herramientas, los
comentarios y la documentación— se publica con la licencia de `LICENSE`. La
imagen del cartucho no se distribuye. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).

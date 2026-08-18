# Empezar

## Lo que hace falta

`pasmo` y `z80dasm` para ensamblar y desensamblar, y Python 3 para las
herramientas. No hay más dependencias.

El cartucho no se distribuye con este repositorio: hace falta tu propia copia,
con el nombre `monkey.rom` en la raíz del proyecto. Son 16384 bytes exactos
con este sha256:

    fdf62cfa6db239fcaa3614b56263dd58e8797b206663e491588c062220b16b01

Con otro volcado el listado no reensamblará. `make comprueba` lo dice en una
línea.

## Las órdenes

```sh
make          # traza, genera el listado y lo comprueba todo
make verify   # ensambla el listado y compara el sha256 con el cartucho
make sanity   # lo que el reensamblado no puede cazar
make test     # los 17 tests del listado, que no necesitan el cartucho
make web      # las imágenes y estas páginas
```

`make` encadena las cuatro primeras. Si todo va bien, la última línea que
importa es esta:

```
  ensamblado : 16384 bytes  fdf62cfa...20b16b01
  original   : 16384 bytes  fdf62cfa...20b16b01
OK: reproducible byte a byte
```

## Qué hay en cada carpeta

| | |
|---|---|
| `src/monkey.asm` | el listado comentado, generado; no se edita a mano |
| `src/monkey.notes` | las anotaciones: etiquetas, comentarios, cabeceras y rangos de datos, ancladas a direcciones |
| `src/monkey.entries` | los puntos de entrada que el trazado no puede deducir, cada uno con su justificación |
| `src/monkey.nocode` | las zonas que el trazador no debe leer como código |
| `tools/` | el trazador, el generador del listado, las comprobaciones y las herramientas de dibujo |
| `tests/` | 17 tests sobre el listado y las notas |
| `docs/` | esta web |
| `work/` | lo que `make` genera por el camino |

## Cómo se lee el listado

Cada rutina lleva su nombre en mayúsculas y un comentario que dice qué hace y
qué recibe. Los bloques de datos van etiquetados como `DATA_<uso>`, con la
anchura de su estructura, y cada uno tiene una explicación de qué es y de cómo
se sabe. Las direcciones son las reales del cartucho en la página 1:
0x4000-0x7FFF.

Si quieres cambiar algo, tócalo en `src/monkey.notes` y vuelve a hacer
`make`: el listado se regenera y las comprobaciones dicen si sigue en pie.

## Cómo se ha hecho

El trazador (`tools/z80trace.py`) sigue el flujo desde el punto de entrada de
la cabecera y desde lo que se declara en `monkey.entries`: la interrupción y
los destinos de los dos despachadores, que saltan por tabla. Lo que no es
código queda como hueco, y cada hueco se cierra buscando la instrucción que
lo lee (`tools/quien_apunta.py`, `tools/refs.py`) y comprobando el formato
que dice el código que lo consume: los dos bloques RLE se descomprimen y
cierran clavados en el byte que toca, y las listas de tiles se recorren hasta
su 0xFF.

Lo que no se puede leer se mide. `tools/graficos.py` monta la memoria de
vídeo repitiendo las copias de INIT y el resultado coincide sprite a sprite
con un volcado del emulador; el generador de ecuaciones se ha muestreado en
el emulador seiscientas veces para comprobar lo que dice el código sobre él.

## Reproducibilidad

- el ensamblado devuelve el sha256 del cartucho
- ningún rango declarado como datos sale como código en el trazado
- ningún punto de entrada cae dentro de un rango de datos
- los 16384 bytes están asignados: 8962 de código, 7422 de datos, 0 sin
  identificar

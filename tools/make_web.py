#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Ni el rotulo de la cabecera ni la galeria son ilustraciones traidas de fuera, y
tampoco son capturas: salen de repetir, paso a paso, lo que hace el propio
cartucho. tools/imagenes_web.py reconstruye la memoria de video con las copias
de la ROM y luego repite las llamadas que pintan cada cosa; si un rango
estuviera mal etiquetado, la galeria saldria ruido.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras de la portada salen de contar sobre el listado generado, no de
# escribirlas aqui a ojo: 16384 = 8962 + 7422, que es lo que imprime
# tools/presupuesto.py (make sanity). Los rotulos se formatean a partir de
# estos numeros para que no puedan quedarse desfasados por su cuenta.
CODIGO = 8962
DATOS = 7422
FASES = 8                           # las tablas se indexan con (fase - 1) & 7
NIVELES = 5                         # los cinco guiones de 0x712B


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Monkey Academy (1984) — desensamblado comentado",
        aviso="<b>Aquí no hay ni una captura de pantalla.</b> Todas las "
              "imágenes están dibujadas repitiendo lo que hace el cartucho: "
              "se reconstruye la memoria de vídeo con sus mismas copias y "
              "luego se repiten las llamadas que pintan cada cosa. Lo demás "
              "—el listado y las cifras— sale del binario y se reproduce con "
              "<code>make</code>.",
        claim="Un cartucho de 16 KB de 1984, desmontado byte a byte. El "
              "juego entero corre dentro de la interrupción, los cinco "
              "niveles son cinco guiones de tres a cinco bytes, la cifra "
              "que se tapa depende de la que se ve, y las frutas se tiran "
              "unos a otros.",
        ficha=["Konami · <b>1984</b>", "Cartucho <b>RC-702</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>fdf62cfa…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El juego en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(FASES), "fases distintas, que se repiten"),
                (str(NIVELES), "niveles: cinco guiones"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Cada una de estas imágenes es una rutina del cartucho "
                 "repetida fuera de él: los tiles se cargan como los carga la "
                 "ROM y luego se llama a lo que los pinta, con sus mismos "
                 "punteros y sus mismas direcciones de vídeo. Debajo de cada "
                 "pie está la dirección de la rutina que la dibuja.",
        pie_leg="Esto es trabajo de documentación y preservación sobre un "
                "juego de 1984: el código y los gráficos siguen siendo de sus "
                "autores y de Konami, y la imagen del cartucho no se "
                "distribuye.",
    ),
    "en": dict(
        titulo="Monkey Academy (1984) — a commented disassembly",
        aviso="<b>There is not one screenshot here.</b> Every picture is "
              "drawn by repeating what the cartridge does: video memory is "
              "rebuilt with its own copies and then the calls that paint each "
              "thing are replayed. Everything else —the listing and the "
              "numbers— comes from the binary and is reproducible with "
              "<code>make</code>.",
        claim="A 16 KB cartridge from 1984, taken apart byte by byte. The "
              "whole game runs inside the interrupt, the five levels are "
              "five scripts of three to five bytes, the digit that gets "
              "hidden depends on the one you can see, and the fruit gets "
              "thrown back and forth.",
        ficha=["Konami · <b>1984</b>", "An <b>RC-702</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>fdf62cfa…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The game in numbers", h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(FASES), "distinct stages, repeating"),
                (str(NIVELES), "levels: five scripts"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Each of these pictures is a routine of the cartridge "
                 "replayed outside it: the tiles are loaded the way the ROM "
                 "loads them and then whatever paints them is called, with "
                 "its own pointers and its own video addresses. Under each "
                 "caption is the address of the routine that draws it.",
        pie_leg="This is documentation and preservation work on a 1984 game: "
                "the code and artwork still belong to their authors and to "
                "Konami, and the cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("El juego entero corre dentro de la interrupción",
         "<p>INIT escribe <code>jp 0x4038</code> en el gancho H.KEYI y se "
         "queda en un <code>jr $</code> de dos bytes, en 0x419B. Ese bucle "
         "vacío es el programa principal: a partir de ahí todo —el sonido, "
         "los sprites, los mandos y un paso del juego— pasa dentro de la "
         "interrupción, un paso por fotograma, y 0xE005 es el candado que "
         "hace que un paso lento no corte la música.</p>"),
        ("La cifra que se tapa depende de la que se ve",
         "<p>0x7253 elige la posición del <code>?</code> restando un azar de "
         "0 a 15 al <b>valor</b> de la primera cifra de la ecuación. Con un 9 "
         "delante puede caer en cualquiera de las diez primeras posiciones; "
         "con un 1 delante, solo en el primer operando.</p>"
         "<p>Medido en el emulador con 400 ecuaciones del nivel 1: cero "
         "excepciones, 238 con el <code>?</code> en las dos primeras "
         "posiciones y solo 67 en el resultado.</p>"),
        ("Cinco niveles, cinco guiones",
         "<p>Lo único que distingue un nivel de otro son de tres a cinco "
         "bytes en 0x712B: <code>0A 0E</code> (+ =), <code>0B 0E</code> "
         "(− =), <code>0D 0E</code> (÷ =), <code>0C 0E</code> (× =) y "
         "<code>0C 10 0A 11 0E</code> (× ( + ) =). El generador decide el "
         "resto al ver el símbolo, en BCD: la división se construye desde el "
         "cociente y la multiplicación son sumas repetidas.</p>"
         "<p>Y un azar de guiones alternativos está anulado con un "
         "<code>xor a</code> (0x6FBC): siempre el primero.</p>"),
        ("Las frutas se tiran unos a otros",
         "<p>Se cogen saltando contra ellas (100 puntos) y con el botón se "
         "tiran hacia donde se mira, por una de las dos parábolas de "
         "0x742F/0x7451. Una fruta que va por el aire mata lo que toque: al "
         "cangrejo, que enseña un 500, o al mono.</p>"
         "<p>Solo el tercer cangrejo salta (0x616F), así que solo él coge "
         "frutas y las tira, y por eso la fruta que lleva un cangrejo sigue "
         "siempre al sprite de 0xE0C8: el código lo da por hecho.</p>"),
        ("Los 22 sprites están dos veces en la VRAM",
         "<p>INIT copia seis sprites a 0x1800 y luego los 22 a 0x18C0 sin "
         "volver a cargar HL: <code>COPIA_A_VRAM</code> lo conserva. El juego "
         "usa la segunda tanda —el mono es el patrón 0x18, el cangrejo el "
         "0x30— y los seis primeros se pisan luego con el juego de sprites "
         "que toque: normal, con la fruta en la cabeza o con la tarjeta.</p>"
         "<p>El profesor de arriba a la derecha es el mono del jugador en "
         "rojo oscuro, y el que trae la respuesta en globo al tercer fallo, "
         "el mismo mono trepando, espejado, en cyan.</p>"),
        ("El sonido 0xA1 es el silencio",
         "<p>Las tres entradas del 0xA1 en la tabla de pistas apuntan al "
         "mismo 0xFF: tres pistas mudas que callan los tres canales. Y los "
         "efectos son del mono: un actor que no sea el mono solo puede pedir "
         "el 9, el del cangrejo que se muere (0x78F7). Los pasos y saltos de "
         "los cangrejos no suenan.</p>"),
    ],
    "en": [
        ("The whole game runs inside the interrupt",
         "<p>INIT writes <code>jp 0x4038</code> into the H.KEYI hook and "
         "drops into a two-byte <code>jr $</code> at 0x419B. That empty loop "
         "is the main program: from then on everything —the sound, the "
         "sprites, the controls and one step of the game— happens inside the "
         "interrupt, one step per frame, and 0xE005 is the lock that keeps a "
         "slow step from cutting the music.</p>"),
        ("The digit that gets hidden depends on the one you can see",
         "<p>0x7253 picks the position of the <code>?</code> by subtracting "
         "a random 0-15 from the <b>value</b> of the equation's first digit. "
         "With a 9 in front it can land on any of the first ten positions; "
         "with a 1 in front, only in the first operand.</p>"
         "<p>Measured in the emulator with 400 level-1 equations: zero "
         "exceptions, 238 with the <code>?</code> in the first two positions "
         "and only 67 in the result.</p>"),
        ("Five levels, five scripts",
         "<p>All that tells one level from another is three to five bytes at "
         "0x712B: <code>0A 0E</code> (+ =), <code>0B 0E</code> (− =), "
         "<code>0D 0E</code> (÷ =), <code>0C 0E</code> (× =) and "
         "<code>0C 10 0A 11 0E</code> (× ( + ) =). The generator decides the "
         "rest on seeing the symbol, in BCD: division is built from the "
         "quotient and multiplication is repeated addition.</p>"
         "<p>And a random choice of alternative scripts is cancelled with a "
         "<code>xor a</code> (0x6FBC): always the first one.</p>"),
        ("The fruit gets thrown back and forth",
         "<p>You pick it by jumping into it (100 points) and throw it with "
         "the button the way you face, along one of the two arcs at "
         "0x742F/0x7451. A fruit in the air kills whatever it hits: the crab, "
         "which shows a 500, or the monkey.</p>"
         "<p>Only the third crab jumps (0x616F), so only it grabs and throws "
         "fruit, and that is why a fruit carried by a crab always follows the "
         "sprite at 0xE0C8: the code takes it for granted.</p>"),
        ("The 22 sprites are in VRAM twice",
         "<p>INIT copies six sprites to 0x1800 and then the 22 to 0x18C0 "
         "without reloading HL: <code>COPIA_A_VRAM</code> preserves it. The "
         "game uses the second set —the monkey is pattern 0x18, the crab "
         "0x30— and the first six get overwritten by whichever sprite set is "
         "due: normal, fruit on the head, or holding the card.</p>"
         "<p>The professor top right is the player's monkey in dark red, and "
         "the one that brings the answer by balloon on the third miss is the "
         "same monkey climbing, mirrored, in cyan.</p>"),
        ("Sound 0xA1 is silence",
         "<p>The three entries for 0xA1 in the track table point at the same "
         "0xFF: three mute tracks that shut the three channels. And the "
         "effects belong to the monkey: an actor other than the monkey can "
         "only request number 9, the crab dying (0x78F7). Crab footsteps and "
         "jumps make no sound.</p>"),
    ],
}

# La galeria: fichero, pie en castellano, pie en ingles. Cada uno lleva la
# direccion de la rutina que lo dibuja, que es de donde sale la imagen.
GALERIA = [
    ("titulo.png",
     "0x4C77 — el título, pintado fila de pixels a fila de pixels en los "
     "tiles 0xB8-0xFF desde el dibujo de 0x4CD0, con las tres bandas de "
     "color de 0x4C5F; el KONAMI de 0x6C42 y el menú de 0x6B99",
     "0x4C77 — the title, painted one pixel row at a time into tiles "
     "0xB8-0xFF from the drawing at 0x4CD0, with the three colour bands of "
     "0x4C5F; the KONAMI of 0x6C42 and the menu of 0x6B99"),
    ("level_select.png",
     "0x7595 — el LEVEL SELECT: PLAYER n, y las cinco líneas de 0x75D0, "
     "cada una con su tecla. Sale al empezar y tras cada fase superada",
     "0x7595 — LEVEL SELECT: PLAYER n and the five lines of 0x75D0, each "
     "with its key. It comes up at the start and after every stage cleared"),
    ("fase_1.png",
     "0x49B4 — la fase 1: las plataformas de 0x6705, las diez tarjetas de "
     "0x50AE metidas (solo el canto), las frutas de 0x6806, las flores de "
     "0x6B42 y el panel; arriba, la ecuación de la demo en los símbolos de "
     "0x7207",
     "0x49B4 — stage 1: the platforms of 0x6705, the ten cards of 0x50AE "
     "tucked in (edge only), the fruit of 0x6806, the flowers of 0x6B42 and "
     "the panel; on top, the demo's equation in the symbols of 0x7207"),
    ("fase_3.png",
     "0x6685 — la fase 3, con la barra verde: el tile de plataforma es "
     "0x05 + (fase / 2) & 3, cuatro colores que se turnan",
     "0x6685 — stage 3, with the green bar: the platform tile is 0x05 + "
     "(stage / 2) & 3, four colours taking turns"),
    ("fase_6.png",
     "0x6685 — la fase 6, azul. Las ocho fases se indexan con (fase − 1) & 7 "
     "y se repiten; lo que cambia después es la velocidad de los cangrejos",
     "0x6685 — stage 6, blue. The eight stages are indexed by (stage − 1) & 7 "
     "and repeat; what changes afterwards is the crabs' speed"),
    ("fase_8.png",
     "0x6685 — la fase 8, amarilla, la última distinta",
     "0x6685 — stage 8, yellow, the last distinct one"),
    ("tarjetas.png",
     "0x5040 — los diez bloques de 3x2 de las tarjetas con su cifra, y "
     "debajo una metida (solo el canto de 0x5082), una abierta con el canto "
     "debajo, y una a medio bajar",
     "0x5040 — the ten 3x2 card blocks with their digit, and below one tucked "
     "in (only the edge of 0x5082), one open with the edge under it, and one "
     "half way down"),
    ("simbolos.png",
     "0x7207 — los diecinueve símbolos de la ecuación en bloques de 2x2: "
     "las cifras, más, menos, por, dividir, igual, un hueco, los paréntesis "
     "y el interrogante",
     "0x7207 — the nineteen equation symbols in 2x2 blocks: the digits, "
     "plus, minus, times, divide, equals, a blank, the brackets and the "
     "question mark"),
    ("tiles.png",
     "0x5156 — los tiles descomprimidos por RLE en el primer tercio, más los "
     "doce de 0x5EFF en 0xB8-0xC3",
     "0x5156 — the tiles decompressed by RLE in the first third, plus the "
     "twelve of 0x5EFF at 0xB8-0xC3"),
    ("sprites.png",
     "0x40C3 — los 64 sprites tal como los deja INIT: los 22 de 0x56BF dos "
     "veces, sus espejos desde el 38, el mono hacia la izquierda en 32-37 y "
     "la cara, la manzana y la tarjeta en 60-63",
     "0x40C3 — the 64 sprites as INIT leaves them: the 22 of 0x56BF twice, "
     "their mirrors from 38, the monkey facing left at 32-37 and the face, "
     "the apple and the card at 60-63"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    ruta_logo = os.path.join(imgdir, "logo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Monkey Academy (1984)">'
                if os.path.exists(ruta_logo) else "<h1>Monkey Academy (1984)</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

# Monkey Academy (Konami, 1984, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como monkey.rom, y
# `make comprueba` verifica el sha256.

ROM      = monkey.rom
SHA      = fdf62cfa6db239fcaa3614b56263dd58e8797b206663e491588c062220b16b01
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = MONKEY ACADEMY - Konami (1984) - MSX1 - cartucho RC-702 de 16 KB en la pagina 1

# Los arneses de openMSX (tools/omsx_*.tcl) dejan aqui lo que midan; la web no
# los necesita.
OMSX     = $(WORK)/omsx

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Monkey Academy (Konami, RC-702, 1984) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo ""
	@echo " Sin el se puede leer el listado ya generado en $(SRC)/, y los"
	@echo " tests que no dependen del binario siguen pasando."
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/monkey.trace.json: $(ROM) $(SRC)/monkey.entries $(SRC)/monkey.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/monkey.entries \
	        $(WORK)/monkey $(SRC)/monkey.nocode

trace: $(WORK)/monkey.trace.json

listado: $(WORK)/monkey.trace.json $(SRC)/monkey.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/monkey.trace.json \
	        $(SRC)/monkey.notes work/msx.sym $(SRC)/monkey.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/monkey.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/monkey.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/monkey.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/monkey.trace.json $(SRC)/monkey.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/monkey.entries $(SRC)/monkey.notes \
	        $(SRC)/monkey.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/monkey.trace.json $(WORK)/monkey.map $(WORK)/png

.PHONY: all comprueba trace listado verify sanity test clean imagenes web

# ---------------------------------------------------------------------------
# La web
# ---------------------------------------------------------------------------
# Aqui no hacen falta capturas de emulador: todas las imagenes se dibujan
# repitiendo lo que hace el cartucho. tools/graficos.py reconstruye la VRAM con
# las mismas copias que hace la ROM y tools/imagenes_web.py repite encima las
# llamadas concretas que pintan el rotulo, los decorados, la liana, el surtidor,
# los tiles y los sprites.
imagenes: $(ROM)
	@mkdir -p docs/imagenes
	python3 tools/imagenes_web.py $(ROM) docs/imagenes

web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	@touch docs/.nojekyll
	@python3 tools/check_enlaces.py docs

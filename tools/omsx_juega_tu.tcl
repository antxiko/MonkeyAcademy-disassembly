# Juega TU a Monkey Academy, y el arnes graba la partida y apunta lo que pasa.
#
#   - Graba la partida entera (reverse start) y la guarda a disco cada minuto
#     de tiempo REAL y al cerrar la ventana: work/omsx/partida/partida.omr.
#     Con `reverse loadreplay -viewonly` + `reverse goto <s>` se vuelve luego a
#     cualquier instante y se mide alli, sin volver a jugar.
#   - Apunta en work/omsx/partida/partida.log, con el reloj EMULADO delante,
#     cada evento que la web afirma leyendo solo el codigo (hecho-sin-verificar):
#     fruta cogida / tirada, cangrejo muerto por una fruta, el mono alcanzado por
#     una fruta o pillado por un cangrejo, acierto / fallo / tres fallos, fase
#     superada, vida extra, tiempo agotado, GAME OVER, el salto del cangrejo del
#     tipo 3, el tipo 4 de la fase 18; y cada cambio de estado, fase, nivel,
#     vidas, fallos, ecuaciones resueltas y puntos.
#   - Un rotulo OSD en el borde de arriba con el reloj emulado y las variables
#     que importan, para que puedas apuntar el segundo de lo que veas raro.
#   - Una captura de la primera pantalla de cada fase nueva (fase_NN.png).
#
# Arrancar (desde MONKEY_DISAM):
#   openmsx -machine Philips_VG_8020 -cart monkey.rom -script tools/omsx_juega_tu.tcl
# Menu: tecla 3 = 1 PLAYER with KEYBOARD (cursores + espacio); la 1 tambien
# vale, porque se enchufa un joystick de teclado con las mismas teclas.
# LEVEL SELECT: teclas 1 a 5. Cierra la ventana cuando acabes: el replay ya
# esta en disco.
#
# Cada bp esta en el INICIO de una instruccion y dispara UNA vez por evento
# (comprobado en el listado; ver src/monkey.notes en cada direccion).

set DIR [file normalize [file join [file dirname [info script]] .. work omsx partida]]
if {[info script] eq ""} { set DIR "C:/Users/Antxiko/Documents/DES_ASM/MONKEY_DISAM/work/omsx/partida" }
if {[info exists ::env(MK_DIR)]} { set DIR $::env(MK_DIR) }   ;# para probar el arnes en otro sitio
file mkdir $DIR
set LOG [open "$DIR/partida.log" a]
proc say {m} { global LOG; puts $LOG [format "%8.2f %s" [machine_info time] $m]; flush $LOG }
say "ARRANQUE maquina=[machine_info config_name]"

set renderer SDLGL-PP
set throttle on
catch { plug joyporta keyjoystick1 }

# ---------------------------------------------------------------- la grabacion
reverse start
set nsalva 0
proc salva {motivo} {
    global DIR nsalva
    incr nsalva
    if {[catch {reverse savereplay -maxnofextrasnapshots 40 "$DIR/partida.omr"} err]} {
        if {[catch {reverse savereplay "$DIR/partida.omr"} err2]} {
            say "SALVAR_FALLO $motivo: $err / $err2"
            return
        }
    }
    say "SALVADO #$nsalva ($motivo)"
}
proc autoguarda {} { salva "minuto"; after realtime 60 autoguarda }
after realtime 60 autoguarda
after quit { salva "cierre" }

# Los eventos, los procs de lectura y el sondeo, compartidos con el repaso del replay
source [file join [file dirname [info script]] omsx_monkey_eventos.tcl]

# ------------------------------------------------------- el rotulo y las fotos
osd create rectangle fondo -x 0 -y 0 -w 320 -h 22 -rgba 0x00000090 -scaled true
osd create text l1 -x 3 -y 1 -size 8 -rgba 0xffffffff -scaled true
osd create text l2 -x 3 -y 11 -size 8 -rgba 0xffff80ff -scaled true
proc foto {f} {
    global DIR
    catch { screenshot [format "%s/fase_%s.png" $DIR [bcd $f]] }
    say "FOTO fase [bcd $f]"
}

arma_eventos
after time 1 sondea

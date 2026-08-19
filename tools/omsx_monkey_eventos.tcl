# Los eventos de Monkey Academy que se miden en el emulador: procs de lectura
# de la RAM, los bps (uno por evento, en el INICIO de una instruccion) y el
# sondeo de cambios. Lo comparten tools/omsx_juega_tu.tcl (la partida en vivo)
# y tools/omsx_repasa_partida.tcl (el replay), para que midan LO MISMO.
#
# Quien lo usa define antes `say {texto}` (escribe con el reloj emulado
# delante) y, si quiere fotos y guardados, `foto {fase}` y `salva {motivo}`;
# si no, aqui hay unos vacios.
if {[info procs foto] eq ""} { proc foto {f} {} }
if {[info procs salva] eq ""} { proc salva {m} {} }

# ---------------------------------------------------------- lectura de la RAM
proc rd {a} { return [debug read memory $a] }
proc bcd {v} { return [format "%02X" $v] }
proc puntos {} { return [format "%02X%02X%02X" [rd 0xE045] [rd 0xE044] [rd 0xE043]] }
proc tipo_ix {} { return [expr {[rd [expr {[reg IX]+0x5B}]] & 0x0F}] }
proc actor {} { return [format "ix=%04X tipo=%d" [reg IX] [tipo_ix]] }
proc fruta {d} { return [format "fruta=%d est=%02X" $d [rd [expr {0xE260 + 2*$d}]]] }

# ------------------------------------------------------- los eventos por bp
proc arma_eventos {} {
    # Frutas (ACTOR_FRUTAS 0x5FA7): D = indice de la fruta
    debug set_bp 0x5FB9 {} { say "COGE_FRUTA [actor] [fruta [reg D]]" }
    debug set_bp 0x5FEF {} { say "MONO_LE_DA_FRUTA [actor] [fruta [reg D]] mono_est=[rd 0xE10C]" }
    debug set_bp 0x5FF5 {} { say "CANGREJO_MUERE_POR_FRUTA [actor] [fruta [reg D]]" }
    # ACTOR_TIRA_SUELTA 0x6506: la fruta que llevaba echa a volar
    debug set_bp 0x6506 {} { say "TIRA_FRUTA [actor] dir=[format %02X [rd [expr {[reg IX]+0x59}]]]" }
    # El cangrejo del tipo 3 decide saltar (bit 4) cuando el azar E140 sale a cero
    debug set_bp 0x6183 {} { say "TIPO3_SALTA [actor] e140=[format %02X [rd 0xE140]]" }
    # El tipo 4 (desde la fase 18) en el borde: gira si Y = +0x58
    debug set_bp 0x6220 {} { say "TIPO4_BORDE [actor] y=[format %02X [rd [reg IX]]] y58=[format %02X [rd [expr {[reg IX]+0x58}]]]" }
    # Pillado por un cangrejo (MONO_COLISION 0x483F -> 0x4844)
    debug set_bp 0x4844 {} { say "PILLADO_POR_CANGREJO monoY=[format %02X [rd 0xE0B0]] monoX=[format %02X [rd 0xE0B1]]" }
    # Estado 10 del mono: pierde la vida (por fruta o por cangrejo)
    debug set_bp 0x659F {} { say "MONO_PIERDE_VIDA vidas=[rd 0xE050] fase=[bcd [rd 0xE051]] tiempo=[bcd [rd 0xE056]]:[bcd [rd 0xE055]]" }
    # Tiempo a cero (PARTIDA_RELOJ 0x44DF, rama de 0x44E6)
    debug set_bp 0x44E6 {} { say "TIEMPO_AGOTADO vidas=[rd 0xE050] fase=[bcd [rd 0xE051]]" }
    # La respuesta: acierto (0x77B6) / fallo (0x77D5) / tres fallos (0x77E7)
    debug set_bp 0x77B6 {} { say "ACIERTO tarjeta=[rd 0xE239] cifra=[rd 0xE1CD] resueltas=[rd 0xE054] tiempo=[bcd [rd 0xE056]]:[bcd [rd 0xE055]]" }
    debug set_bp 0x77D5 {} { say "FALLO tarjeta=[rd 0xE239] cifra_escondida=[rd 0xE1CD] fallos_antes=[rd 0xE057]" }
    debug set_bp 0x77E7 {} { say "TRES_FALLOS e276->1" }
    # El profesor escribe la cifra en el ? (0x74FA) y la tarjeta llega arriba (0x785C)
    debug set_bp 0x74FA {} { say "PROFESOR_ESCRIBE cifra=[rd 0xE1CD] col=[rd 0xE271]" }
    debug set_bp 0x785C {} { say "TARJETA_LLEGA_ARRIBA" }
    # Fase superada: el reloj a puntos acaba (0x7818) y el estado 16 (0x45BC)
    debug set_bp 0x7818 {} { say "TIEMPO_A_PUNTOS_FIN puntos=[puntos]" }
    debug set_bp 0x45BC {} { say "FASE_SUPERADA fase=[bcd [rd 0xE051]] vidas=[rd 0xE050] puntos=[puntos]" }
    # Vida extra (0x4983) y GAME OVER pintado (0x4541, ya callados los canales)
    debug set_bp 0x4983 {} { say "VIDA_EXTRA vidas_antes=[rd 0xE050] puntos=[puntos] e052=[bcd [rd 0xE052]]" }
    debug set_bp 0x4541 {} { say "GAME_OVER puntos=[puntos] fase=[bcd [rd 0xE051]] record=[format "%02X%02X%02X" [rd 0xE042] [rd 0xE041] [rd 0xE040]]"; salva "game over" }
    # READY arranca (0x4462): empieza a jugarse la ecuacion / la vida
    debug set_bp 0x4462 {} { say "READY_ARRANCA fase=[bcd [rd 0xE051]] nivel=[expr {[rd 0xE153]+1}] vidas=[rd 0xE050] tiempo=[bcd [rd 0xE056]]:[bcd [rd 0xE055]] ecuacion=[ecuacion]" }

}

# La ecuacion en simbolos (E144.., E058 simbolos): 0-9 cifras, 0x0A + 0x0B - 0x0C x
# 0x0D / 0x0E = 0x0F hueco 0x10 ( 0x11 ) 0x12 ? (tabla de tiles de 0x7207)
set SIMB {0 1 2 3 4 5 6 7 8 9 + - x / = _ ( ) ?}
proc ecuacion {} {
    global SIMB
    set s ""
    set n [rd 0xE058]
    if {$n > 13} { set n 13 }
    for {set i 0} {$i < $n} {incr i} {
        set b [rd [expr {0xE144 + $i}]]
        if {$b < 19} { append s [lindex $SIMB $b] } else { append s [format "<%02X>" $b] }
    }
    return $s
}

# ------------------------------------------- el sondeo: cambios y el rotulo
# El rotulo OSD lo crea quien quiera verlo (juega_tu); aqui solo se rellena si existe.
array set ant {}
foreach v {E000 E050 E051 E153 E057 E054 E002} { set ant($v) -1 }
set ant(pts) ""
array set fotos {}
proc sondea {} {
    global ant fotos nsalva
    if {![info exists nsalva]} { set nsalva 0 }
    set e000 [rd 0xE000]; set e050 [rd 0xE050]; set e051 [rd 0xE051]
    set e153 [rd 0xE153]; set e057 [rd 0xE057]; set e054 [rd 0xE054]
    set e002 [rd 0xE002]; set pts [puntos]
    if {$e000 > 19} { after time 0.1 sondea; return }   ;# la RAM aun sin borrar (antes de INIT)
    if {$e000 != $ant(E000)} { say "ESTADO $ant(E000) -> $e000"; set ant(E000) $e000 }
    if {$e051 != $ant(E051)} {
        say "FASE [bcd $ant(E051)] -> [bcd $e051]"; set ant(E051) $e051
    }
    if {$e153 != $ant(E153)} { say "NIVEL -> [expr {$e153+1}]"; set ant(E153) $e153 }
    if {$e050 != $ant(E050)} { say "VIDAS $ant(E050) -> $e050"; set ant(E050) $e050 }
    if {$e057 != $ant(E057)} { say "FALLOS -> $e057"; set ant(E057) $e057 }
    if {$e054 != $ant(E054)} { say "RESUELTAS -> $e054"; set ant(E054) $e054 }
    if {$e002 != $ant(E002)} { say "OPCIONES e002=[format %02X $e002]"; set ant(E002) $e002 }
    if {$pts ne $ant(pts)} { say "PUNTOS $pts"; set ant(pts) $pts }
    # una foto de la primera pantalla de cada fase, ya en la partida (estado 12)
    if {$e000 == 12 && ![info exists fotos($e051)]} {
        set fotos($e051) 1
        after time 1.5 [list foto $e051]
    }
    if {[lsearch [osd info] l1] < 0} { after time 0.1 sondea; return }
    osd configure l1 -text [format "t=%7.1f  est=%2d  fase=%s  nivel=%d  vidas=%d  tiempo=%s:%s  GRABANDO #%d" \
        [machine_info time] $e000 [bcd $e051] [expr {$e153+1}] $e050 [bcd [rd 0xE056]] [bcd [rd 0xE055]] $nsalva]
    osd configure l2 -text [format "puntos=%s  fallos=%d  resueltas=%d  ec=%s  ?=%d" \
        $pts $e057 $e054 [ecuacion] [rd 0xE1CD]]
    after time 0.1 sondea
}

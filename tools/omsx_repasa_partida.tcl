# Repasa una partida grabada (.omr) con los MISMOS eventos que se apuntaron en
# vivo (tools/omsx_monkey_eventos.tcl), a toda velocidad y sin tocar el replay
# (-viewonly): deja repaso.log con el reloj emulado delante de cada evento.
#
# Sirve para dos cosas: comprobar que el replay reproduce lo que se vio (los
# dos logs tienen que coincidir evento a evento) y anadir medidas nuevas sin
# volver a jugar (MK_EXTRA: un tcl mas que se carga tras armar los eventos).
#
#   MK_OMR=<partida.omr> MK_OUT=<dir> [MK_DESDE=<s>] [MK_HASTA=<s>] [MK_EXTRA=<tcl>] \
#     openmsx -script tools/omsx_repasa_partida.tcl
#
# El replay trae su propia maquina (la que grabo), asi que -machine no pinta nada.
# Trampa conocida (memoria medir-en-el-emulador): reproducir un replay desde
# t=0 esta bien con un cartucho (no hay cinta que releer).

set OMR $::env(MK_OMR)
set OUT $::env(MK_OUT)
set DESDE [expr {[info exists ::env(MK_DESDE)] ? $::env(MK_DESDE) : 0}]
set HASTA [expr {[info exists ::env(MK_HASTA)] ? $::env(MK_HASTA) : -1}]
file mkdir $OUT
set LOG [open "$OUT/repaso.log" w]
proc say {m} { global LOG; puts $LOG [format "%8.2f %s" [machine_info time] $m]; flush $LOG }

source [file join [file dirname [info script]] omsx_monkey_eventos.tcl]

set renderer none
after time 0.5 {
    global OMR DESDE HASTA
    reverse loadreplay -viewonly $OMR
    set st [reverse status]
    set fin [dict get $st end]
    if {$HASTA < 0 || $HASTA > $fin} { set HASTA $fin }
    say "REPLAY $OMR maquina=[machine_info config_name] inicio=[dict get $st begin] fin=$fin desde=$DESDE hasta=$HASTA"
    if {$DESDE > 0} { reverse goto $DESDE }
    arma_eventos
    if {[info exists ::env(MK_EXTRA)]} { source $::env(MK_EXTRA) }
    set throttle off
    after time 0.1 sondea
    vigila_fin
}
proc vigila_fin {} {
    global HASTA
    if {[machine_info time] >= $HASTA - 0.05} {
        say "FIN t=[machine_info time]"
        exit 0
    }
    after time 0.5 vigila_fin
}

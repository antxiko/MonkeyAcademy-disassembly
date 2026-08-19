# Arranca la partida en la fase que diga MK_FASE (BCD, p. ej. 0x10 = fase 10).
# Se carga DETRAS de omsx_juega_tu.tcl (usa su `say`). El LEVEL SELECT copia
# los 8 bytes de jugador nuevo (0x47E1 -> E050) en 0x479D-0x47A6; en 0x47A8
# ya estan puestos y se cambia la fase. Sirve para ver lo que no se alcanza
# jugando: los tres cangrejos (desde la 10) y el tipo 4 (desde la 18).
set FASE [expr {[info exists ::env(MK_FASE)] ? $::env(MK_FASE) : 0x10}]
debug set_bp 0x47A8 {} {
    debug write memory 0xE051 $::FASE
    say "FASE_FORZADA [format %02X $::FASE]"
}

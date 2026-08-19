; ==========================================================================
; MONKEY ACADEMY - Konami (1984) - MSX1 - cartucho RC-702 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: La cabecera que lee la BIOS: "AB", INIT=0x40AF
;   y a cero STATEMENT, DEVICE y TEXT. La BIOS mapea el cartucho en la pagina
;   1 (0x4000-0x7FFF) y salta a 0x40AF al terminar de arrancar
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h	; 4000
	defw 040afh,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defb 000h,000h,000h,000h,000h,000h	; 400a

; ----------------------------------------------------------------------
; DATOS cinco_stubs_sin_usar: Cinco veces `pop hl / ld (0),hl / ret` y cuatro
;   `ret`: talones de 8 bytes para los ganchos STATEMENT/DEVICE/TEXT que la
;   cabecera deja a cero. Nadie salta aqui
;   0x4010..0x4038  (40 bytes)
DATA_cinco_stubs_sin_usar:
	defb 0e1h,022h,000h,000h,0c9h,0c9h,0c9h,0c9h	; 4010  ."......
	defb 0e1h,022h,000h,000h,0c9h,0c9h,0c9h,0c9h	; 4018  ."......
	defb 0e1h,022h,000h,000h,0c9h,0c9h,0c9h,0c9h	; 4020  ."......
	defb 0e1h,022h,000h,000h,0c9h,0c9h,0c9h,0c9h	; 4028  ."......
	defb 0e1h,022h,000h,000h,0c9h,0c9h,0c9h,0c9h	; 4030  ."......

; ======================================================================
; CODIGO 0x4038..0x4226  (494 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ######################################################################
; LA INTERRUPCION (gancho H.KEYI). Todo el juego corre aqui dentro:
; INIT la instala y se queda en un jr $ para siempre. Cada fotograma:
; 796F  el sonido, SIEMPRE, aunque el fotograma anterior no acabara
; 46BA  la tabla de sprites a la VRAM, girada
; 41A7  los mandos, solo a partir del estado 7 (demo y partida)
; 4209  el paso del juego, un estado de la tabla de 0x4226
; E005 es el candado: si un paso tarda mas de un fotograma, la
; siguiente interrupcion solo hace sonido y sprites y se va por 4075.
; ######################################################################
; ----------------------------------------------------------------------
INTERRUPCION:		; Guarda todo, reconoce la interrupcion del VDP, sonido y sprites; y si no hay otro paso a medias, un paso del juego
	push af			;4038
	push bc			;4039
	push de			;403a
	push hl			;403b
	push ix		;403c
	exx			;403e
	push bc			;403f
	push de			;4040
	push hl			;4041
	di			;4042
	in a,(099h)		;4043   ; Leer el estado del VDP baja la interrupcion
	call SUENA		;4045
	call VUELCA_SPRITES		;4048
	ld hl,0e005h		;404b   ; E005 distinto de 0: el paso anterior no ha acabado; solo sonido y sprites
	ld a,(hl)			;404e
	or a			;404f
	jr nz,INTERRUPCION_SALE		;4050
	ld (hl),0ffh		;4052
	ei			;4054
	ld a,(0e000h)		;4055   ; Los mandos solo se leen en la demo y en la partida (estados 7 en adelante)
	cp 007h		;4058
	call nc,LEE_MANDOS		;405a
	call PASO_DEL_JUEGO		;405d
	di			;4060
	pop hl			;4061
	pop de			;4062
	pop bc			;4063
	exx			;4064
	pop ix		;4065
	pop hl			;4067
	pop de			;4068
	pop bc			;4069
	xor a			;406a
	ld (0e005h),a		;406b
	pop af			;406e
	ei			;406f
	reti		;4070
SIN_LLAMADAS_4072:		; `push iy / ret`: tres bytes a los que no llega nadie
	push iy		;4072
	ret			;4074
INTERRUPCION_SALE:		; Salida corta cuando el paso anterior sigue a medias: recupera los registros y vuelve
	pop hl			;4075
	pop de			;4076
	pop bc			;4077
	exx			;4078
	pop ix		;4079
	pop hl			;407b
	pop de			;407c
	pop bc			;407d
	pop af			;407e
	ei			;407f
	reti		;4080
VPOKE:		; Escribe A en la VRAM DE (bit 6 de D para escribir; se deja como estaba)
	di			;4082
	push af			;4083
	set 6,d		;4084
	call VDP_DIRECCION		;4086
	res 6,d		;4089
	pop af			;408b
	out (098h),a		;408c
	ei			;408e
RET_:		; Un `ret` suelto: 0x4090 lo llama para dejar respirar al VDP entre la direccion y el dato
	ret			;408f
VPEEK:		; Lee en A el byte de la VRAM DE
	di			;4090
	call VDP_DIRECCION		;4091
	call RET_		;4094
	in a,(098h)		;4097
	ei			;4099
	ret			;409a
VDP_DIRECCION:		; Manda DE al VDP: primero E, luego D (con el bit 6 a 1 si es para escribir; con el 7, un registro)
	ld a,e			;409b
	out (099h),a		;409c
	ld a,d			;409e
	call RET_		;409f
	out (099h),a		;40a2
	ret			;40a4
HL_MAS_A:		; HL = HL + A, sin signo. Es la rutina que usa el despachador
	add a,l			;40a5
	ld l,a			;40a6
	ret nc			;40a7
	inc h			;40a8
	ret			;40a9
DE_MAS_A:		; DE = DE + A, sin signo
	add a,e			;40aa
	ld e,a			;40ab
	ret nc			;40ac
	inc d			;40ad
	ret			;40ae

; ----------------------------------------------------------------------
; ######################################################################
; INIT, el punto de entrada de la cabecera. Deja la maquina montada y
; se para: la interrupcion hace el resto. Lo que carga en la VRAM, y
; que tools/graficos.py repite tal cual:
; 56BF -> 1800 (6 sprites) y OTRA VEZ -> 18C0 (los 22, porque
; COPIA_A_VRAM conserva HL)   597F -> 1B80   5ABF -> 1F80
; 59FF -> 1C00 (0xC0)   y los 22 de 56BF ESPEJADOS -> 1CC0
; Asi el sprite k de la VRAM (patron 4k) es: 0-5 y 6-27 el 0-21 de
; 0x56BF (repetidos), 28-31 el 500/100/platano/uvas, 32-37 el mono
; hacia la izquierda, 38-59 los espejos, 60-63 la cara y la manzana.
; 5156 -> patrones 0x2000/2800/3000 y 566B -> colores 0/800/1000,
; los dos por RLE (0x6C84), 1472 bytes cada uno: los tiles 0x00-0xB7
; ######################################################################
; ----------------------------------------------------------------------
INIT:		; di, im 1, `jp 4038` en H.KEYI (FD9A), pila en E400, registros del VDP y los graficos a la VRAM
	di			;40af
	im 1		;40b0
	ld a,0c3h		;40b2   ; 0xC3 = jp; el gancho H.KEYI queda `jp 4038h`
	ld (0fd9ah),a		;40b4
	ld hl,INTERRUPCION		;40b7
	ld (0fd9bh),hl		;40ba
	ld sp,0e400h		;40bd
	call VDP_REGISTROS		;40c0   ; Los 8 registros del VDP desde 0x488C
	ld hl,056bfh		;40c3   ; Los seis primeros sprites a 0x1800; y como COPIA_A_VRAM deja HL como estaba, los 22 (0x2C0) OTRA VEZ desde 0x18C0: el sprite 6 es el 0, el 12 el 6...
	ld bc,000c0h		;40c6
	ld de,01800h		;40c9
	call COPIA_A_VRAM		;40cc
	ld bc,002c0h		;40cf
	ld de,018c0h		;40d2
	call COPIA_A_VRAM		;40d5
	ld hl,0597fh		;40d8   ; Los cuatro sprites de 0x597F en 0x1B80 (patrones 0x70-0x7C: 500, 100, platano y uvas; aqui van luego los globos)
	ld bc,00080h		;40db
	ld de,01b80h		;40de
	call COPIA_A_VRAM		;40e1
	ld hl,05abfh		;40e4   ; Y los de 0x5ABF en 0x1F80 (patrones 0xF0-0xFC): BC sigue valiendo 0x80
	ld de,01f80h		;40e7
	call COPIA_A_VRAM		;40ea
	ld hl,059ffh		;40ed   ; Los seis de 0x59FF en 0x1C00 (patrones 0x80-0x94): el mono andando hacia la izquierda
	ld bc,000c0h		;40f0
	ld de,01c00h		;40f3
	call COPIA_A_VRAM		;40f6
	di			;40f9
	ld de,056bfh		;40fa
	ld hl,056cfh		;40fd
	ld ix,0e000h		;4100   ; IX = destino en RAM: +0 columna izquierda nueva, +0x10 la derecha
	ld bc,01600h		;4104
ESPEJA_SPRITES:		; Da la vuelta a los 22 sprites de 0x56BF (16x16, 32 bytes) bit a bit en E000, y luego van a 0x1CC0
	push bc			;4107
	ld b,010h		;4108
ESPEJA_SPRITE_FILA:		; Una fila de 16 bits: H = izquierda, L = derecha
	ld a,(de)			;410a   ; DE = columna izquierda de la fila, HL = la derecha (16 bytes mas alla)
	exx			;410b
	ld h,a			;410c
	exx			;410d
	ld a,(hl)			;410e
	exx			;410f
	ld l,a			;4110
	ld b,010h		;4111
ESPEJA_16_BITS:		; Los 16 bits salen por el carry desde el bit alto y entran por la derecha en (IX+0) y (IX+10): invertidos y con las mitades cambiadas
	add hl,hl			;4113
	rr (ix+000h)		;4114
	rr (ix+010h)		;4118
	djnz ESPEJA_16_BITS		;411c
	exx			;411e
	inc hl			;411f
	inc de			;4120
	inc ix		;4121
	djnz ESPEJA_SPRITE_FILA		;4123
	ld c,010h		;4125
	add hl,bc			;4127
	ex de,hl			;4128
	add hl,bc			;4129
	ex de,hl			;412a
	add ix,bc		;412b
	pop bc			;412d
	djnz ESPEJA_SPRITES		;412e
	ld de,01cc0h		;4130   ; Los 22 espejos (0x2C0 bytes) a 0x1CC0: el espejo del sprite k de 0x56BF es el patron 0x98 + 4k
	ld hl,0e000h		;4133
	ld bc,002c0h		;4136
	call COPIA_A_VRAM		;4139
	ld hl,0e000h		;413c   ; Toda la RAM del juego a cero (E000-E3FF)
	ld de,0e001h		;413f
	ld bc,003ffh		;4142
	ld (hl),000h		;4145
	ldir		;4147
	ld de,06000h		;4149   ; Los patrones RLE de 0x5156 en los tres tercios (0x6000/0x6800/0x7000 = escribir en 0x2000/0x2800/0x3000)
	ld hl,05156h		;414c
	push hl			;414f
	call RLE_A_VRAM		;4150
	pop hl			;4153
	ld de,06800h		;4154
	push hl			;4157
	call RLE_A_VRAM		;4158
	pop hl			;415b
	ld de,07000h		;415c
	call RLE_A_VRAM		;415f
	ld de,04000h		;4162   ; Y los colores RLE de 0x566B en 0x0000/0x0800/0x1000
	ld hl,0566bh		;4165
	push hl			;4168
	call RLE_A_VRAM		;4169
	pop hl			;416c
	ld de,04800h		;416d
	push hl			;4170
	call RLE_A_VRAM		;4171
	pop hl			;4174
	ld de,05000h		;4175
	call RLE_A_VRAM		;4178
	call BORRA_PANTALLA		;417b
	ld de,081a2h		;417e   ; R1 = 0xA2: 16K, pantalla apagada, interrupciones, sprites de 16x16
	call VDP_DIRECCION		;4181
	ld a,001h		;4184   ; E005 = 1: la interrupcion no da pasos mientras se acaba de montar
	ld (0e005h),a		;4186
	ld a,007h		;4189   ; R7 del PSG = 0xB8: los tres canales de tono abiertos, ruido cerrado, puerto A de entrada
	out (0a0h),a		;418b
	push hl			;418d
	pop hl			;418e
	ld a,0b8h		;418f
	out (0a1h),a		;4191
	call PSG_PUERTO_JOYSTICK		;4193
	xor a			;4196
	ld (0e005h),a		;4197
	ei			;419a
PARADO:		; Aqui se queda para siempre; la interrupcion hace el juego
	jr PARADO		;419b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL DESPACHADOR de Konami. Se llama con el indice en A y la tabla de
; palabras va PEGADA detras del CALL: el POP HL recoge la direccion de
; retorno, que es la tabla. Dos tablas: 0x4226 (los 20 estados del
; juego) y 0x602E (los 11 estados de un actor). Nunca vuelve al CALL.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
DESPACHA:		; Salta al destino A de la tabla de palabras que va detras del CALL
	add a,a			;419d
	pop hl			;419e   ; La direccion de retorno ES la tabla
	call HL_MAS_A		;419f
	ld e,(hl)			;41a2
	inc hl			;41a3
	ld d,(hl)			;41a4
	ex de,hl			;41a5
	jp (hl)			;41a6

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS MANDOS. Deja en E009 lo pulsado en este fotograma y en E008 lo
; del anterior, siempre en el formato del joystick: bit0 arriba,
; bit1 abajo, bit2 izquierda, bit3 derecha, bit4 disparo (espacio),
; bit5 segundo boton (tecla SELECT). El teclado se lee del PPI a
; pelo (filas 7 y 8 de la matriz) y se recoloca bit a bit para que
; salga igual. Es la rutina que Konami repite tal cual en sus cartuchos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
LEE_MANDOS:		; E009 = ahora, E008 = el fotograma anterior; joystick o teclado segun el bit 4 de E002
	ld a,(0e002h)		;41a7
	bit 4,a		;41aa
	jr nz,LEE_TECLADO		;41ac
	di			;41ae
	call PSG_PUERTO_JOYSTICK		;41af   ; Registro 15 del PSG: el puerto de joystick del jugador que juega
	ld a,00eh		;41b2   ; Registro 14: cuatro direcciones y dos botones
	out (0a0h),a		;41b4
	in a,(0a2h)		;41b6
	cpl			;41b8
	and 03fh		;41b9
	ld d,a			;41bb
	ld bc,057aah		;41bc   ; Fila 7 del teclado (0x57: fila 7, motor de cinta y CAPS apagados)
	out (c),b		;41bf
	out (c),b		;41c1
	in a,(0a9h)		;41c3
	cpl			;41c5
	rra			;41c6   ; SELECT (bit 6 de la fila 7) al bit 5: el segundo boton
	and 020h		;41c7
	or d			;41c9
	ei			;41ca
GUARDA_MANDOS:		; Lo de ahora pasa a E009 y lo que habia baja a E008
	ld hl,0e009h		;41cb
	ld c,(hl)			;41ce
	ld (hl),a			;41cf
	dec hl			;41d0
	ld (hl),c			;41d1
	ret			;41d2
LEE_TECLADO:		; Monta el mismo mapa de bits con las filas 7 (SELECT) y 8 (flechas y espacio) del teclado
	ld bc,057aah		;41d3
	out (c),b		;41d6
	out (c),b		;41d8
	in a,(0a9h)		;41da
	cpl			;41dc
	rrca			;41dd
	and 020h		;41de
	ld e,a			;41e0
	inc b			;41e1   ; Fila 8: espacio, flechas
	out (c),b		;41e2
	out (c),b		;41e4
	in a,(0a9h)		;41e6
	cpl			;41e8
	rrca			;41e9
	rrca			;41ea
	ld b,a			;41eb
	and 004h		;41ec   ; IZQUIERDA al bit 2
	or e			;41ee
	ld c,a			;41ef
	ld a,b			;41f0
	rrca			;41f1
	rrca			;41f2
	ld b,a			;41f3
	and 018h		;41f4   ; DERECHA al bit 3 y ESPACIO al bit 4
	or c			;41f6
	ld c,a			;41f7
	ld a,b			;41f8
	rrca			;41f9
	and 003h		;41fa   ; ARRIBA al bit 0 y ABAJO al bit 1
	or c			;41fc
	jr GUARDA_MANDOS		;41fd
BORRA_PANTALLA:		; Tabla de nombres entera (0x3800, 768 bytes) a cero
	ld de,03800h		;41ff
	ld bc,00300h		;4202
	xor a			;4205
	jp RELLENA_VRAM		;4206

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO DEL JUEGO, cada fotograma. Cuenta el reloj, mira el 1UP que
; parpadea (en la partida) y las teclas 1-5 (fuera de ella), y despacha
; el estado E000 por la tabla de 0x4226:
; 0 arranca el titulo        1 la ecuacion sube en globos
; 2 sube el logotipo KONAMI  3 espera   4 pinta el titulo fila a fila
; 5 menu, espera             6 monta la partida de demostracion
; 7 la demo juega sola       8 LEVEL SELECT (y arranque de partida)
; 9 PLAYER n / LEVEL n      10 monta la fase (ecuacion nueva si toca)
; 11 READY: cuenta atras     12 LA PARTIDA
; 13 vida perdida o ecuacion resuelta   14 cambio de jugador
; 15 espera y decide         16 fase superada   17 espera a que acabe el sonido
; 18 opcion elegida (parpadea)   19 espera y a la partida
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PASO_DEL_JUEGO:		; E003++, el 1UP a partir del estado 11, las teclas 1-5 salvo en el 18, y el estado por la tabla
	ld hl,0e003h		;4209
	inc (hl)			;420c
	ld a,(0e000h)		;420d   ; En el estado 18 (opcion recien elegida) no se leen las teclas
	cp 012h		;4210
	jr z,PASO_TECLAS		;4212
	cp 00bh		;4214
	push af			;4216
	call nc,PARPADEA_1UP		;4217
	pop af			;421a
PASO_TECLAS:		; A partir del estado 1, las teclas 1-5
	cp 001h		;421b
	call nc,TECLAS_1_A_5		;421d
	ld a,(0e000h)		;4220
	call DESPACHA		;4223

; ----------------------------------------------------------------------
; DATOS tabla_de_estados: Los 20 estados del juego (indice E000), destino del
;   despachador de 0x4223
;   0x4226..0x424e  (40 bytes)
DATA_tabla_de_estados:
	defw 0424eh	; 4226  -> ESTADO_0_TITULO
	defw 04284h	; 4228  -> ESTADO_1_GLOBOS
	defw 04296h	; 422a  -> ESTADO_2_LOGO
	defw 042aah	; 422c  -> ESTADO_3_ESPERA
	defw 042c1h	; 422e  -> ESTADO_4_TITULO
	defw 042d5h	; 4230  -> ESTADO_5_MENU
	defw 042e1h	; 4232  -> ESTADO_6_DEMO_MONTA
	defw 04337h	; 4234  -> ESTADO_7_DEMO
	defw 04375h	; 4236  -> ESTADO_8_LEVEL_SELECT
	defw 04378h	; 4238  -> ESTADO_9_PLAYER_N
	defw 043bah	; 423a  -> ESTADO_10_MONTA_FASE
	defw 043eeh	; 423c  -> ESTADO_11_READY
	defw 0448fh	; 423e  -> ESTADO_12_PARTIDA
	defw 04509h	; 4240  -> ESTADO_13_VIDA_O_RESUELTA
	defw 04584h	; 4242  -> ESTADO_14_CAMBIO
	defw 045a0h	; 4244  -> ESTADO_15_DECIDE
	defw 045bch	; 4246  -> ESTADO_16_FASE_SUPERADA
	defw 045d2h	; 4248  -> ESTADO_17_ESPERA_SONIDO
	defw 045ech	; 424a  -> ESTADO_18_OPCION
	defw 0464dh	; 424c  -> ESTADO_19_ESPERA_PARTIDA

; ======================================================================
; CODIGO 0x424e..0x4332  (228 bytes)
; ======================================================================


ESTADO_0_TITULO:		; Musica del titulo (0xA1), pantalla apagada, sprites y nombres a cero, fuente magenta, y el logotipo listo para subir; salta al estado 2
	ld a,0a1h		;424e   ; 0xA1: la musica del titulo, sin mirar el bit 6 de E002 (aun no hay partida)
	call SONIDO_YA		;4250
	ld de,081a2h		;4253   ; R1 = 0xA2: pantalla apagada mientras se limpia
	call VDP_DIRECCION		;4256
	ld de,03b00h		;4259   ; Los 32 atributos de sprite a 0xD0: no se pinta ninguno
	ld bc,00080h		;425c
	ld a,0d0h		;425f
	call RELLENA_VRAM		;4261
	call BORRA_PANTALLA		;4264
	ld a,0d0h		;4267   ; 0xD0: la fuente en magenta sobre transparente
	call COLOR_FUENTE		;4269
	ld a,011h		;426c   ; 17 pasos de subida del logotipo
	ld (0e00ah),a		;426e
	ld hl,00000h		;4271
	ld (0e00eh),hl		;4274
	ld de,081e2h		;4277   ; R1 = 0xE2: pantalla encendida
	call VDP_DIRECCION		;427a
	ld hl,0e000h		;427d   ; Un inc aqui y otro en 0x4661: al estado 2
	inc (hl)			;4280
	jp SIGUIENTE_ESTADO		;4281
ESTADO_1_GLOBOS:		; Suben los globos con la ecuacion (0x713D); al llegar todos, las frutas de la fase, los sprites de juego y al estado 7 (la demo)
	call GLOBOS_SUBEN		;4284
	ret nc			;4287
	ld a,006h		;4288
	ld (0e000h),a		;428a
	call FRUTAS_DE_LA_FASE		;428d
	call SPRITES_DE_JUEGO		;4290
	jp SIGUIENTE_ESTADO		;4293
ESTADO_2_LOGO:		; Cada dos fotogramas sube una fila el KONAMI (0x6C42); al acabar, "VIDEO CARTRIDGE" y 0x80 fotogramas de espera
	ld a,(0e003h)		;4296
	rra			;4299
	ret nc			;429a
	call SUBE_LOGO_KONAMI		;429b
	ret nz			;429e
	ld hl,06c2ch		;429f
	call PINTA_LISTA_TILES		;42a2
	ld a,080h		;42a5
	jp SIGUIENTE_ESTADO_A		;42a7
ESTADO_3_ESPERA:		; Cuando E004 llega a cero, prepara la zona del titulo (0x4BF0) y los cursores del dibujo
	ld hl,0e004h		;42aa
	dec (hl)			;42ad
	ret nz			;42ae
	call PREPARA_TITULO		;42af
	ld hl,025c0h		;42b2
	ld (0e246h),hl		;42b5
	ld hl,00000h		;42b8
	ld (0e248h),hl		;42bb
	jp SIGUIENTE_ESTADO		;42be
ESTADO_4_TITULO:		; Cada 8 fotogramas una fila de pixels del "Monkey Academy" (0x4C77); al acabar, el menu (0x6B99) y espera 256 fotogramas
	ld a,(0e003h)		;42c1
	and 007h		;42c4
	ret nz			;42c6
	call TITULO_UNA_FILA		;42c7
	ret c			;42ca
	ld hl,06b99h		;42cb
	call PINTA_LISTA_TILES		;42ce
	xor a			;42d1
	jp SIGUIENTE_ESTADO_A		;42d2
ESTADO_5_MENU:		; Cuando E004 llega a cero, E00B = 0 y a montar la demo
	ld hl,0e004h		;42d5
	dec (hl)			;42d8
	ret nz			;42d9
	xor a			;42da
	ld (0e00bh),a		;42db
	jp SIGUIENTE_ESTADO_50		;42de
ESTADO_6_DEMO_MONTA:		; Cortinilla, tiles de la ecuacion en 0xB8, jugador 1, fase 1 y el marcador; ecuacion 93+25 fija, tarjetas 2-7, y los globos
	call CORTINILLA		;42e1
	ret p			;42e4   ; La cortinilla devuelve P mientras le quedan columnas
	call CARGA_TILES_ECUACION		;42e5
	ld hl,0e002h		;42e8
	res 7,(hl)		;42eb   ; Jugador 1
	call MONTA_DEMO		;42ed
	ld hl,00500h		;42f0   ; Cinco minutos
	ld (0e055h),hl		;42f3
	ld hl,0e056h		;42f6
	call PINTA_RELOJ		;42f9
	call TARJETAS_DE_LA_FASE		;42fc
	ld b,006h		;42ff   ; Las tarjetas 4 a 9 de la demo llevan las cifras 2, 3, 4, 5, 6 y 7 (las 0-3 se quedan con el 0 de la RAM)
	ld hl,0e1edh		;4301
	ld a,002h		;4304
DEMO_TARJETAS_BUCLE:		; Las seis cifras 2-7 a las tarjetas 4-9
	ld (hl),a			;4306
	inc hl			;4307
	inc hl			;4308
	inc a			;4309
	djnz DEMO_TARJETAS_BUCLE		;430a
	xor a			;430c
	ld (0e1b2h),a		;430d
	ld a,005h		;4310   ; Cinco simbolos, los de 0x4332, a la ecuacion del 1P (E1B5)
	ld (0e058h),a		;4312
	ld hl,04332h		;4315
	ld de,0e1b5h		;4318
	ld bc,00005h		;431b
	ldir		;431e
	ld a,002h		;4320   ; La cifra escondida es el 2
	ld (0e1cdh),a		;4322
	call MONTA_GLOBOS		;4325
	xor a			;4328   ; Estado 0 mas el inc de 0x4661: al estado 1, la subida de los globos
	ld (0e000h),a		;4329
	ld (0e276h),a		;432c
	jp SIGUIENTE_ESTADO		;432f

; ----------------------------------------------------------------------
; DATOS ecuacion_de_la_demo: Los cinco simbolos de la ecuacion de la demo: 3 +
;   ? = 5 (0x0A es +, 0x12 el ?, 0x0E el =); la cifra escondida, el 2, va en
;   E1CD
;   0x4332..0x4337  (5 bytes)
DATA_ecuacion_de_la_demo:
	defb 003h,00ah,012h,00eh,005h	; 4332

; ======================================================================
; CODIGO 0x4337..0x43b5  (126 bytes)
; ======================================================================


ESTADO_7_DEMO:		; La demo: si el profesor ya va con la respuesta (bit 3 de E276) solo eso; si no, frutas, respuesta, tarjetas y el guion de 0x4B78. Al acabar, al titulo
	ld a,(0e276h)		;4337
	bit 3,a		;433a   ; Bit 3 de E276: la respuesta ha llegado arriba, no hay mas que hacer
	jr z,DEMO_JUEGA		;433c
	call FASE_RESUELTA_BAILE		;433e
	ret nc			;4341
	ld a,001h		;4342
	ld (0e00bh),a		;4344
	jr DEMO_ACABA		;4347
DEMO_JUEGA:		; El paso de la demo: profesor, tarjeta, flecha, frutas, tarjeta que se abre y el guion
	call PROFESOR		;4349
	call TARJETA_PASO		;434c
	call FLECHA_ROJA		;434f
	call FRUTAS_PASO		;4352
	ld a,(0e238h)		;4355   ; E238 distinto de 0: hay una tarjeta abriendose
	or a			;4358
	call nz,TARJETA_PARPADEA		;4359
	call DEMO_GUION		;435c
DEMO_ACABA:		; Si E00B: sprites fuera, 0x50 fotogramas y al titulo
	ld hl,0e00bh		;435f   ; E00B: el guion se ha acabado (0xFF) o la ronda ha terminado (1)
	xor a			;4362
	or (hl)			;4363
	ret z			;4364
	call ESCONDE_SPRITES		;4365
	ld a,050h		;4368   ; 0x50 fotogramas y vuelta al estado 0
	ld (0e004h),a		;436a
	xor a			;436d
	ld (0e00bh),a		;436e
	ld (0e000h),a		;4371
	ret			;4374
ESTADO_8_LEVEL_SELECT:		; Al LEVEL SELECT (0x4747), que tambien arranca la partida
	jp LEVEL_SELECT		;4375
ESTADO_9_PLAYER_N:		; Espera a que calle el sonido; borra todo, gasta una vida, marcador, tiempo, y el recuadro PLAYER n / LEVEL n durante 0x65 fotogramas
	ld a,(0e026h)		;4378   ; Los canales B (E01C) y C (E026) callados
	ld b,a			;437b
	ld a,(0e01ch)		;437c
	or b			;437f
	ret nz			;4380
	call ESCONDE_SPRITES		;4381
	call BORRA_PANTALLA		;4384
	ld hl,0e050h		;4387   ; La vida se gasta aqui: por eso 0x6E4A la devuelve antes de venir
	dec (hl)			;438a
	ld a,001h		;438b   ; R7 = 1: fondo negro
	call VDP_R7		;438d
	ld a,0f4h		;4390   ; 0xF4: la fuente en blanco sobre azul oscuro (el panel)
	call COLOR_FUENTE		;4392
	call PINTA_MARCADOR		;4395
	call RELOJ_MINIMO		;4398
	ld hl,0e056h		;439b
	call PINTA_RELOJ		;439e
	ld hl,043b5h		;43a1   ; El recuadro azul de 11x5 en la fila 10, columna 8
	call PINTA_RECUADRO		;43a4
	ld hl,06c23h		;43a7   ; "PLAYER" y el numero del jugador
	call PLAYER_N		;43aa
	call PINTA_LEVEL		;43ad   ; "LEVEL n" debajo
	ld a,065h		;43b0
	jp SIGUIENTE_ESTADO_A		;43b2

; ----------------------------------------------------------------------
; DATOS recuadro_player: Rectangulo para 0x66BB: 11 columnas x 5 filas del
;   tile 0x60 (azul) en la VRAM 0x3948 (fila 10, columna 8). Es el fondo del
;   PLAYER n / LEVEL n y del GAME OVER
;   0x43b5..0x43ba  (5 bytes)
DATA_recuadro_player:
	defb 00bh,005h,060h,039h,048h	; 43b5

; ======================================================================
; CODIGO 0x43ba..0x447d  (195 bytes)
; ======================================================================


ESTADO_10_MONTA_FASE:		; Cuando E004 llega a cero: marcador, tiempo, tarjetas de la fase (0x4F81) y, si toca, la ecuacion nueva (0x6F96), la cifra escondida (0x7253) y las cifras barajadas (0x4FCC); luego los globos y al READY
	ld hl,0e004h		;43ba
	dec (hl)			;43bd
	ret nz			;43be
	call PINTA_MARCADOR		;43bf
	ld hl,0e056h		;43c2
	call PINTA_RELOJ		;43c5
	call TARJETAS_DE_LA_FASE		;43c8
	ld a,(0e053h)		;43cb   ; E053: hace falta ecuacion nueva (la primera del turno, o al resolver la anterior)
	or a			;43ce
	jr z,MONTA_FASE_GLOBOS		;43cf
	di			;43d1
	call GENERA_ECUACION		;43d2
	call ELIGE_INCOGNITA		;43d5
	call ECUACION_AL_JUGADOR		;43d8
	ei			;43db
	call BARAJA_CIFRAS		;43dc
MONTA_FASE_GLOBOS:		; Los globos, el sonido 1 y al READY
	call MONTA_GLOBOS		;43df
	ld a,001h		;43e2   ; Sonido 1: la ecuacion arranca
	call SONIDO		;43e4
	xor a			;43e7
	ld (0e1b2h),a		;43e8
	jp SIGUIENTE_ESTADO_A		;43eb
ESTADO_11_READY:		; Primero suben los globos (0x713D); despues el recuadro READY con la cuenta atras 15..0 en segundos, o hasta que se pulse un boton
	ld a,(0e241h)		;43ee
	or a			;43f1
	jr nz,READY_CUENTA		;43f2
	ld a,(0e01ch)		;43f4
	or a			;43f7
	call GLOBOS_SUBEN		;43f8
	ret nc			;43fb
	ld de,01b80h		;43fc   ; Los cuatro sprites de 0x597F vuelven a 0x1B80 (los globos ya no hacen falta)
	ld hl,0597fh		;43ff
	ld bc,00040h		;4402
	di			;4405
	call COPIA_A_VRAM		;4406
	ei			;4409
	call SPRITES_DE_JUEGO		;440a
	call FRUTAS_DE_LA_FASE		;440d
	xor a			;4410   ; E00C = 0, E241 = 1: fase de la cuenta atras
	ld (0e00ch),a		;4411
	inc a			;4414
	ld (0e241h),a		;4415
	ld a,015h		;4418   ; 15 segundos, en BCD
	ld (0e242h),a		;441a
	ld hl,0447dh		;441d   ; El recuadro azul de 7x4 en la fila 11, columna 10, y "READY"
	call PINTA_RECUADRO		;4420
	ld hl,04482h		;4423
	call PINTA_LISTA_TILES		;4426
	ld b,001h		;4429
	ld hl,0e242h		;442b   ; El 15 en la fila 12, columna 12
	ld de,039ach		;442e
	jp PINTA_BYTES_BCD		;4431
READY_CUENTA:		; Cada 64 fotogramas resta uno (BCD); un boton nuevo o el cero arrancan
	ld hl,0e242h		;4434
	ld a,(hl)			;4437
	or a			;4438
	jp z,READY_ARRANCA		;4439
	ld hl,0e008h		;443c   ; Lo pulsado ahora y no antes
	ld a,(hl)			;443f
	inc hl			;4440
	xor (hl)			;4441
	and (hl)			;4442
	push af			;4443
	ld a,093h		;4444   ; Sin boton nuevo: se mantiene la musica del READY (0x93)
	call z,SONIDO		;4446
	ld a,(0e003h)		;4449
	and 03fh		;444c
	jr nz,READY_CUENTA_FIN		;444e
	ld hl,0e242h		;4450
	ld a,(hl)			;4453
	sub 001h		;4454
	daa			;4456
	ld (hl),a			;4457
	ld b,001h		;4458
	ld de,039ach		;445a
	call PINTA_BYTES_BCD		;445d
READY_CUENTA_FIN:		; Con boton nuevo (NZ) arranca; si no, sigue contando
	pop af			;4460
	ret z			;4461
READY_ARRANCA:		; Borra el recuadro (0x448A), esconde los sprites y al estado 12
	xor a			;4462
	ld (0e1b2h),a		;4463
	ld (0e241h),a		;4466
	ld hl,0448ah		;4469
	call PINTA_RECUADRO		;446c
	ld a,0e1h		;446f
	ld de,03b00h		;4471
	ld bc,00080h		;4474
	call RELLENA_VRAM		;4477
	jp SIGUIENTE_ESTADO_A		;447a

; ----------------------------------------------------------------------
; DATOS recuadro_ready: Rectangulo para 0x66BB: 7 columnas x 4 filas del tile
;   0x60 en 0x396A (fila 11, columna 10)
;   0x447d..0x4482  (5 bytes)
DATA_recuadro_ready:
	defb 007h,004h,060h,039h,06ah	; 447d

; ----------------------------------------------------------------------
; DATOS rotulo_ready: "READY" en la fila 12, columna 11 (lista de tiles para
;   0x48E9; el numero lo pone 0x4A4F en la 0x39AC)
;   0x4482..0x448a  (8 bytes)
DATA_rotulo_ready:
	defb 08bh,039h,052h,045h,041h,044h,059h,0ffh	; 4482  .9READY.

; ----------------------------------------------------------------------
; DATOS borra_recuadro_ready: El mismo rectangulo con el tile 0 para borrarlo
;   0x448a..0x448f  (5 bytes)
DATA_borra_recuadro_ready:
	defb 007h,004h,000h,039h,06ah	; 448a

; ======================================================================
; CODIGO 0x448f..0x4637  (424 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA PARTIDA (estado 12), cada fotograma. Si se esta descontando el
; tiempo (E23C) solo eso. Si no: el profesor con la respuesta, la
; musica de fondo, el hundimiento, las frutas, la respuesta, las
; tarjetas, el mono y los cangrejos (0x4822), y el reloj. Al morir o
; al resolver, al estado 13; con la fase superada, al 16.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_12_PARTIDA:		; El paso de la partida
	ld a,(0e23ch)		;448f
	or a			;4492   ; E23C: la fase esta acabada y el tiempo se convierte en puntos
	jp nz,TIEMPO_A_PUNTOS		;4493
	call FASE_RESUELTA_BAILE		;4496
	ld a,(0e01ch)		;4499   ; Con el canal B callado se relanza la musica: 0x9B si el mono lleva la respuesta (E108 = 0x33), 0xA1 si va con el profesor (0x88), 0x93 si no
	or a			;449c
	jr nz,PARTIDA_PASO		;449d
	ld d,09bh		;449f
	ld a,(0e108h)		;44a1
	cp 033h		;44a4
	jr z,PARTIDA_MUSICA		;44a6
	ld d,0a1h		;44a8
	cp 088h		;44aa
	jr z,PARTIDA_MUSICA		;44ac
	ld d,093h		;44ae
PARTIDA_MUSICA:		; Relanza la musica D
	ld a,d			;44b0
	call SONIDO		;44b1
PARTIDA_PASO:		; Profesor, respuesta, tarjetas, frutas, mono y cangrejos, y el reloj
	call PROFESOR_PASO		;44b4   ; Cangrejos hundidos, frutas, la respuesta que sube, tarjetas, y el mono
	call PROFESOR		;44b7
	call TARJETA_PASO		;44ba
	call FRUTAS_PASO		;44bd
	call FLECHA_ROJA		;44c0
	ld a,(0e238h)		;44c3
	or a			;44c6
	call nz,TARJETA_PARPADEA		;44c7
	call MONO_Y_CANGREJOS		;44ca
	ld a,(0e056h)		;44cd   ; Con menos de 10 segundos, el aviso 0x0C cada fotograma
	or a			;44d0
	jr nz,PARTIDA_RELOJ		;44d1
	ld a,(0e055h)		;44d3
	sub 010h		;44d6
	jr nc,PARTIDA_RELOJ		;44d8
	ld a,00ch		;44da
	call SONIDO		;44dc
PARTIDA_RELOJ:		; Tiempo a cero: se pierde la vida
	ld hl,(0e055h)		;44df   ; Tiempo a cero: se pierde la vida (E00C = 1), sonido 0xA0, cara de susto y el reloj vuelve a 05:00
	ld a,l			;44e2
	or h			;44e3
	jr nz,PARTIDA_DECIDE		;44e4
	inc a			;44e6
	ld (0e00ch),a		;44e7
	ld a,0a0h		;44ea
	call SONIDO		;44ec
	call CARA_DE_SUSTO		;44ef
	ld hl,00500h		;44f2
	ld (0e055h),hl		;44f5
PARTIDA_DECIDE:		; E00C al 13, E00D al 16, si no sigue en el 12
	ld hl,0e00ch		;44f8   ; E00C: al estado 13; E00D: al 16; si no, sigue
	xor a			;44fb
	cp (hl)			;44fc
	jp nz,SIGUIENTE_ESTADO		;44fd
	inc hl			;4500
	cp (hl)			;4501
	ret z			;4502
	ld a,010h		;4503
	ld (0e000h),a		;4505
	ret			;4508
ESTADO_13_VIDA_O_RESUELTA:		; Suelta la tarjeta, esconde los cangrejos, restaura los sprites del mono; sin vidas, GAME OVER; si no, al 17 (o al 14 con dos jugadores)
	ld a,0ffh		;4509
	ld (0e1afh),a		;450b
	call ESCONDE_CANGREJOS		;450e
	xor a			;4511
	ld (0e00ch),a		;4512
	di			;4515
	ld hl,056bfh		;4516   ; Los sprites del mono (0x56BF) y de los cangrejos (0x59FF) vuelven a su sitio
	ld de,01800h		;4519
	ld bc,000c0h		;451c
	call COPIA_A_VRAM		;451f
	ld hl,059ffh		;4522
	ld de,01c00h		;4525
	call COPIA_A_VRAM		;4528
	ei			;452b
	ld a,(0e050h)		;452c   ; E050 = 0: se acabaron las vidas
	or a			;452f
	jr nz,SIGUE_O_CAMBIA		;4530
GAME_OVER:		; Espera a que callen los tres canales; sonido 0x9D, "GAME OVER" y "PLAYER n" en el recuadro azul, y al estado 14 tras 0x50 fotogramas
	ld a,(0e012h)		;4532
	ld b,a			;4535
	ld a,(0e01ch)		;4536
	or b			;4539
	ld b,a			;453a
	ld a,(0e026h)		;453b
	or b			;453e
	jr nz,GAME_OVER		;453f
	call ESCONDE_SPRITES		;4541
	ld a,09dh		;4544
	call SONIDO		;4546
	ld hl,066ebh		;4549
	call PINTA_RECUADRO		;454c
	ld hl,043b5h		;454f
	call PINTA_RECUADRO		;4552
	ld hl,06c17h		;4555
	call PLAYER_N		;4558
	ld a,00eh		;455b   ; Estado 14 mas el inc de 0x465E: al 15
	ld (0e000h),a		;455d
	xor a			;4560
	jp SIGUIENTE_ESTADO_A		;4561
SIGUE_O_CAMBIA:		; Con vidas: si el otro jugador tambien tiene, al estado 14 (cambio); si no, al 17 y luego al 9
	ld a,(0e080h)		;4564
	or a			;4567
	jp nz,SIGUIENTE_ESTADO		;4568
	ld a,008h		;456b   ; El estado 17 vuelve al 8 (E24A) y de ahi al 9: PLAYER n de nuevo
	ld (0e24ah),a		;456d
	ld a,011h		;4570
	ld (0e000h),a		;4572
	ret			;4575
ESCONDE_CANGREJOS:		; Los sprites 2 a 7 (E0B8-E0CF) fuera de la pantalla (Y = 0xE1)
	ld hl,0e0b8h		;4576
	ld de,0e0b9h		;4579
	ld bc,00017h		;457c
	ld (hl),0e1h		;457f
	ldir		;4581
	ret			;4583
ESTADO_14_CAMBIO:		; Intercambia E050-E06F con E080-E09F, cambia el bit 7 de E002 (el jugador) y su puerto de joystick, y al 17 con E24A = 8
	ld hl,0e050h		;4584
	ld de,0e080h		;4587
	ld b,020h		;458a
	call INTERCAMBIA		;458c
	ld hl,0e002h		;458f
	ld a,(hl)			;4592
	xor 080h		;4593
	ld (hl),a			;4595
	call PSG_PUERTO_JOYSTICK		;4596
	ld a,008h		;4599
	ld (0e24ah),a		;459b
	jr AL_ESTADO_17		;459e
ESTADO_15_DECIDE:		; Cuando E004 llega a cero: si el otro jugador tiene vidas, al 14 (cambio); si no, se acabo la partida (bit 6 de E002 a cero) y al titulo
	ld hl,0e004h		;45a0
	dec (hl)			;45a3
	ret nz			;45a4
	ld a,(0e080h)		;45a5
	or a			;45a8
	ld a,00eh		;45a9
	jr nz,DECIDE_ESTADO		;45ab
	ld hl,0e002h		;45ad
	res 6,(hl)		;45b0
	ld a,050h		;45b2
	ld (0e004h),a		;45b4
	xor a			;45b7
DECIDE_ESTADO:		; E000 = A
	ld (0e000h),a		;45b8
	ret			;45bb
ESTADO_16_FASE_SUPERADA:		; Sonido 0x99, devuelve la vida que gastara el 9, fase + 1, y al 17 con E24A = 7 (que acaba en el 8: LEVEL SELECT otra vez)
	ld a,099h		;45bc
	call SONIDO		;45be
	ld hl,0e050h		;45c1
	inc (hl)			;45c4
	inc hl			;45c5
	inc (hl)			;45c6
	ld a,007h		;45c7
	ld (0e24ah),a		;45c9
AL_ESTADO_17:		; E000 = 17
	ld a,011h		;45cc
	ld (0e000h),a		;45ce
	ret			;45d1
ESTADO_17_ESPERA_SONIDO:		; Cuando callan los tres canales: estado = E24A, sprites a cero, 0x50 fotogramas y el inc de 0x465C
	ld a,(0e012h)		;45d2
	ld b,a			;45d5
	ld a,(0e01ch)		;45d6
	or b			;45d9
	ld b,a			;45da
	ld a,(0e026h)		;45db
	or b			;45de
	ret nz			;45df
	ld a,(0e24ah)		;45e0
	ld (0e000h),a		;45e3
	call ESCONDE_SPRITES		;45e6
	jp SIGUIENTE_ESTADO_50		;45e9
ESTADO_18_OPCION:		; La primera vez pinta el menu limpio (0x470D) y suena 0x91; luego 0x60 fotogramas parpadeando la linea elegida, y al 8
	ld a,(0e13ch)		;45ec
	or a			;45ef
	jr nz,OPCION_PARPADEA		;45f0
	ld de,03800h		;45f2   ; Pantalla en blanco: el menu vuelve a pintarse sin el titulo
	ld bc,00300h		;45f5
	xor a			;45f8
	call RELLENA_VRAM		;45f9
	call PINTA_MENU		;45fc
	ld a,060h		;45ff
	ld (0e004h),a		;4601
	ld a,091h		;4604
	call SONIDO		;4606
	ld hl,0e13ch		;4609
	inc (hl)			;460c
	ret			;460d
OPCION_PARPADEA:		; La linea elegida se ve o no segun el bit 3 de E004; a cero, al estado 8
	ld hl,0e004h		;460e
	dec (hl)			;4611
	jr z,$+41		;4612
	ld a,(hl)			;4614   ; Bit 3 de E004: la linea se ve o no
	and 008h		;4615
	jp nz,PINTA_MENU_TEXTO		;4617
	ld a,(0e002h)		;461a   ; Opcion 0-3 de E002 (bits 4-5) a su fila: 1P joystick 16, 1P teclado 20, 2P joystick 18, 2P teclado 22
	rra			;461d
	rra			;461e
	rra			;461f
	rra			;4620
	and 003h		;4621
	ld hl,04637h		;4623
	call HL_MAS_A		;4626
	ld a,(hl)			;4629
	ld de,03a00h		;462a   ; 0x3A00 es la fila 16; se borran los 32 tiles de la fila
	call DE_MAS_A		;462d
	ld bc,00020h		;4630
	xor a			;4633
	jp RELLENA_VRAM		;4634

; ----------------------------------------------------------------------
; DATOS fila_de_cada_opcion: Desplazamiento en la VRAM de la linea del menu de
;   cada opcion: 0x00 (fila 16), 0x80 (fila 20), 0x40 (fila 18), 0xC0 (fila
;   22), indexado por los bits 4-5 de E002
;   0x4637..0x463b  (4 bytes)
DATA_fila_de_cada_opcion:
	defb 000h,080h,040h,0c0h	; 4637

; ======================================================================
; CODIGO 0x463b..0x46b2  (119 bytes)
; ======================================================================


OPCION_AL_8:		; Al estado 8 con la pantalla en blanco y los tiles de la ecuacion cargados
	ld a,008h		;463b
	ld (0e000h),a		;463d
	ld de,03800h		;4640
	ld bc,00300h		;4643
	xor a			;4646
	call RELLENA_VRAM		;4647
	jp CARGA_TILES_ECUACION		;464a
ESTADO_19_ESPERA_PARTIDA:		; Cuando E004 llega a cero, al 12 y a mirar E00C/E00D
	ld hl,0e004h		;464d
	dec (hl)			;4650
	xor a			;4651
	cp (hl)			;4652
	ret nz			;4653
	ld a,00ch		;4654
	ld (0e000h),a		;4656
	jp PARTIDA_DECIDE		;4659
SIGUIENTE_ESTADO_50:		; E004 = 0x50 y al estado siguiente
	ld a,050h		;465c
SIGUIENTE_ESTADO_A:		; E004 = A y al estado siguiente
	ld (0e004h),a		;465e
SIGUIENTE_ESTADO:		; E000++
	ld hl,0e000h		;4661
	inc (hl)			;4664
	ret			;4665
PLAYER_N:		; La lista HL ("PLAYER") y el numero del jugador (bit 7 de E002) en la fila 11, columna 17
	call PINTA_LISTA_TILES		;4666
	ld a,(0e002h)		;4669
	rlca			;466c
	and 001h		;466d
	add a,031h		;466f
	ld de,03971h		;4671
	call VPOKE		;4674
	ret			;4677

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS TECLAS 1-5. Se miran en cada fotograma salvo en el estado 18.
; Fila 0 del teclado, bits 1-5 = teclas 1-5; E23D las de ahora y E23E
; las de antes (el LEVEL SELECT las lee de ahi). En los estados 0-7
; (titulo y demo) la tabla de 0x46B2 convierte 1-4 en las opciones
; de E002: 1=0x40 un jugador con joystick, 2=0x60 dos, 3=0x50 uno con
; teclado, 4=0x70 dos con teclado; y al estado 18. Con dos teclas a la
; vez, o la 5, no vale (0).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
TECLAS_1_A_5:		; Guarda en E23D/E23E las teclas 1-5; en el titulo y la demo, 1-4 eligen la opcion y pasan al estado 18
	ld a,050h		;4678   ; Fila 0 del teclado (0x50: fila 0, CAPS apagado)
	out (0aah),a		;467a
	out (0aah),a		;467c
	in a,(0a9h)		;467e
	cpl			;4680
	and 03eh		;4681
	rra			;4683
	ld hl,0e23dh		;4684
	ld d,(hl)			;4687
	ld (hl),a			;4688
	inc hl			;4689
	ld (hl),d			;468a
	ld h,a			;468b
	ld a,(0e000h)		;468c   ; A partir del estado 8 solo se guardan
	cp 008h		;468f
	ret nc			;4691
	ld a,h			;4692   ; Indice = teclas - 1: 0, 1, 3, 7 son una sola tecla
	dec a			;4693
	cp 008h		;4694
	ret nc			;4696
	ld hl,046b2h		;4697
	call HL_MAS_A		;469a
	ld a,(hl)			;469d
	or a			;469e
	ret z			;469f
	ld (0e002h),a		;46a0
	ld a,012h		;46a3
	ld (0e000h),a		;46a5
	ld a,050h		;46a8
	ld (0e004h),a		;46aa
	call ESCONDE_SPRITES		;46ad
	pop hl			;46b0   ; Se come el retorno al despachador: este fotograma no da paso
	ret			;46b1

; ----------------------------------------------------------------------
; DATOS opcion_por_tecla: Las opciones de E002 indexadas por (teclas - 1):
;   tecla 1 = 0x40, 2 = 0x60, 4 = 0x50, 8 = 0x70; el resto 0 (no vale)
;   0x46b2..0x46ba  (8 bytes)
DATA_opcion_por_tecla:
	defb 040h,060h,000h,050h,000h,000h,000h,070h	; 46b2  @`.P...p

; ======================================================================
; CODIGO 0x46ba..0x47e1  (295 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA TABLA DE SPRITES A LA VRAM, cada fotograma. Los sprites de E0B0
; se vuelcan a 0x3B00 empezando por uno distinto cada vez (E1B2 baja
; de 0x17 a 0, o de 0x12 fuera del READY): asi la prioridad y el
; limite de cuatro por linea del TMS9918 van rotando y ninguno
; desaparece siempre. 24 sprites en el READY (los globos), 19 si no.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
VUELCA_SPRITES:		; E0B0.. a 0x3B00 girados E1B2 posiciones
	di			;46ba
	ld hl,0e1b2h		;46bb
	dec (hl)			;46be
	jp p,VUELCA_SPRITES_DESDE		;46bf
	ld (hl),017h		;46c2
	ld a,(0e000h)		;46c4   ; En el READY (estado 11) giran 24 sprites (0x60 bytes); si no, 19 (0x4C)
	cp 00bh		;46c7
	jr z,VUELCA_SPRITES_DESDE		;46c9
	ld (hl),012h		;46cb
VUELCA_SPRITES_DESDE:		; Desde el sprite E1B2 x 4
	ld a,(hl)			;46cd
	add a,a			;46ce
	add a,a			;46cf
	ld b,a			;46d0
	ld c,a			;46d1
	ld hl,0e0b0h		;46d2
	call HL_MAS_A		;46d5
	ld de,07b00h		;46d8
	call VDP_DIRECCION		;46db
VUELCA_SPRITES_COLA:		; Desde el sprite E1B2 hasta el final
	ld a,(hl)			;46de
	out (098h),a		;46df
	inc c			;46e1
	ld a,(0e000h)		;46e2
	cp 00bh		;46e5
	ld a,060h		;46e7
	jr z,VUELCA_SPRITES_HASTA		;46e9
	ld a,04ch		;46eb
VUELCA_SPRITES_HASTA:		; Hasta 0x60 (READY) o 0x4C bytes
	cp c			;46ed
	inc hl			;46ee
	jr nz,VUELCA_SPRITES_COLA		;46ef
	ld hl,0e0b0h		;46f1
VUELCA_SPRITES_CABEZA:		; Y luego los del principio hasta llegar a el
	ld a,b			;46f4
	or a			;46f5
	jr z,VUELCA_SPRITES_FIN		;46f6
	ld a,(hl)			;46f8
	out (098h),a		;46f9
	inc hl			;46fb
	djnz VUELCA_SPRITES_CABEZA		;46fc
VUELCA_SPRITES_FIN:		; Listo
	ret			;46fe
ESCONDE_SPRITES:		; E0B0-E0FB (19 sprites) a 0xE1: fuera de la pantalla
	ld hl,0e0b0h		;46ff
	ld de,0e0b1h		;4702
	ld bc,0004ch		;4705
	ld (hl),0e1h		;4708
	ldir		;470a
	ret			;470c
PINTA_MENU:		; El titulo entero de golpe (0x4BF0 y todas las filas de 0x4C77) y el menu de 0x6B99
	call PREPARA_TITULO		;470d
	ld hl,025c0h		;4710
	ld (0e246h),hl		;4713
	ld hl,00000h		;4716
	ld (0e248h),hl		;4719
PINTA_MENU_FILAS:		; Todas las filas del titulo de golpe
	call TITULO_UNA_FILA		;471c
	jr c,PINTA_MENU_FILAS		;471f
PINTA_MENU_TEXTO:		; Solo el texto del menu (PLAY SELECT y las cuatro opciones)
	ld hl,06b99h		;4721
	call PINTA_LISTA_TILES		;4724
	ret			;4727
CARGA_TILES_ECUACION:		; Los 12 tiles de 0x5EFF a 0xB8-0xC3 en los tres tercios (cifras de la ecuacion que faltaban en 0x5156) y sus colores: 6 blancos sobre azul y 6 amarillos
	ld hl,05effh		;4728   ; 0x65C0 = escribir en 0x25C0: los patrones 0xB8-0xC3
	ld de,065c0h		;472b
	ld bc,00060h		;472e
	call COPIA_TRES_TERCIOS		;4731
	ld de,045c0h		;4734   ; Colores 0x45C0 = 0x05C0: los de 0xB8-0xBD blancos sobre azul oscuro
	ld bc,00030h		;4737
	ld a,0f4h		;473a
	call COLOR_TRES_TERCIOS		;473c
	ld de,045f0h		;473f   ; Y los de 0xBE-0xC3 amarillo claro sobre transparente (las cifras grandes)
	ld a,0b0h		;4742
	jp COLOR_TRES_TERCIOS		;4744

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL LEVEL SELECT (estado 8), gobernado por los bits de E152:
; bit 7  la cortinilla ya paso   bit 6  esperando la tecla 1-5
; bit 4 / bit 3  la linea elegida parpadea (0x7670)
; La primera vez (E00D = 0) arranca la partida: puntos a cero, vidas
; y fase de 0x47E1, y la copia para el 2P. Tras cada fase superada
; (E00D = 1) se vuelve aqui: se puede cambiar de nivel.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
LEVEL_SELECT:		; Cortinilla; arranca la partida si no habia; pinta PLAYER n / LEVEL SELECT y espera la tecla
	ld a,(0e152h)		;4747
	add a,a			;474a
	jr c,LEVEL_SELECT_BITS		;474b
	call CORTINILLA		;474d
	ret p			;4750
	ld hl,0e152h		;4751
	set 7,(hl)		;4754
	ret			;4756
LEVEL_SELECT_BITS:		; Cortinilla ya pasada: los bits 4, 6 y 3
	bit 4,a		;4757   ; Bit 4: parpadea la linea
	jp nz,LEVEL_LINEA_PARPADEA		;4759
	add a,a			;475c   ; Bit 6: esperando la tecla
	jp c,LEVEL_SELECT_ESPERA		;475d
	ld a,(0e152h)		;4760
	bit 3,a		;4763   ; Bit 3: parpadea la linea
	jp nz,LEVEL_LINEA_PARPADEA		;4765
	call CORTINILLA		;4768
	ret p			;476b
	ld a,(0e00dh)		;476c   ; E00D: viene de superar una fase; la partida ya esta en marcha
	or a			;476f
	jr nz,LEVEL_SELECT_PINTA		;4770
	ld a,020h		;4772
	ld (0e1b3h),a		;4774
	xor a			;4777
	ld (0e152h),a		;4778
	ld a,(0e002h)		;477b   ; Bit 7 de E002: es el turno del 2P, sus datos ya estan puestos
	bit 7,a		;477e
	jr nz,LEVEL_SELECT_PINTA		;4780
	ld a,091h		;4782   ; 0x91: la musica del menu
	call SONIDO		;4784
	ld hl,0e043h		;4787   ; Puntos, record de la partida y todo lo demas hasta E142 a cero
	ld de,0e044h		;478a
	ld bc,00100h		;478d
	ld (hl),000h		;4790
	ldir		;4792
	ld a,020h		;4794
	ld (0e1b3h),a		;4796
	xor a			;4799
	ld (0e152h),a		;479a
	ld hl,047e1h		;479d   ; Vidas, fase, tiempo... de 0x47E1
	ld de,0e050h		;47a0
	ld bc,00008h		;47a3
	ldir		;47a6
	ld a,(0e002h)		;47a8
	bit 5,a		;47ab   ; Con dos jugadores, la misma copia para el 2P
	jr z,LEVEL_SELECT_PINTA		;47ad
	ld hl,0e050h		;47af
	ld de,0e080h		;47b2
	ld bc,00020h		;47b5
	ldir		;47b8
LEVEL_SELECT_PINTA:		; Fuente blanca, fondo azul (R7 = 4), el texto de 0x7595, 0x0F00 fotogramas de espera y a esperar la tecla
	ld a,020h		;47ba
	ld (0e1b3h),a		;47bc
	ld a,0f4h		;47bf
	call COLOR_FUENTE		;47c1
	ld a,004h		;47c4   ; R7 = 4: fondo azul oscuro
	call VDP_R7		;47c6
	call PINTA_LEVEL_SELECT		;47c9
	ld hl,00f00h		;47cc
	ld (0e23fh),hl		;47cf
	ld hl,0e152h		;47d2
	set 6,(hl)		;47d5
LEVEL_SELECT_ESPERA:		; 0x762F: con la tecla pulsada (carry) pasa a parpadear
	call LEVEL_SELECT_TECLA		;47d7
	ret nc			;47da
	ld hl,0e152h		;47db
	set 3,(hl)		;47de
	ret			;47e0

; ----------------------------------------------------------------------
; DATOS jugador_nuevo: Los 8 bytes de E050 al empezar: 3 vidas, fase 1, E052 =
;   0 (la primera vida extra al pasar de 10000), ecuacion nueva (E053 = 1), 0
;   resueltas, tiempo 05:00 (E055 = 00, E056 = 05), 0 fallos
;   0x47e1..0x47e9  (8 bytes)
DATA_jugador_nuevo:
	defb 003h,001h,000h,001h,000h,000h,005h,000h	; 47e1  ........

; ======================================================================
; CODIGO 0x47e9..0x488c  (163 bytes)
; ======================================================================


SPRITES_DE_JUEGO:		; Los cuatro sprites del mono (0x56BF) a 0x1800; la tabla de sprites (0x4B04) a E0B0 y los cuatro actores (0x4B24) a E108; el mono en Y = 0xA8; a partir de la fase 18 el cangrejo 1 es del tipo 4 y patrulla la segunda plataforma
	ld hl,056bfh		;47e9
	ld de,01800h		;47ec
	ld bc,00080h		;47ef
	di			;47f2
	call COPIA_A_VRAM		;47f3
	ei			;47f6
	ld hl,04b04h		;47f7
	ld de,0e0b0h		;47fa
	ld bc,00020h		;47fd
	ldir		;4800
	ld de,0e108h		;4802
	ld c,020h		;4805
	ldir		;4807
	ld a,0a8h		;4809   ; El mono, en el suelo (Y = 0xA8)
	ld (0e0b0h),a		;480b
	ld (0e0b4h),a		;480e
	ld a,(0e051h)		;4811   ; Fase 18 en adelante (BCD): el primer cangrejo es del tipo 4 (0x44) y patrulla la segunda plataforma (E110 = 0x38, la Y a la que da la vuelta)
	cp 018h		;4814
	ret c			;4816
	ld a,038h		;4817
	ld (0e110h),a		;4819
	ld a,044h		;481c
	ld (0e113h),a		;481e
	ret			;4821

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL MONO Y LOS CANGREJOS, cada fotograma de partida. Los mandos van
; a E10B (nibble alto: bit4 disparo, bit5 boton 2, bit6 izquierda,
; bit7 derecha, en el mismo formato que el guion de la demo). Cada 8
; fotogramas repinta las tarjetas. Si un cangrejo pilla al mono
; (0x69B0), cara de susto y estado 10. Y luego 0x5F5F por actor, del
; ultimo al primero: la fase dice CUANTOS juegan (un cangrejo hasta la
; 7, dos en la 8 y la 9, los tres desde la 10), y un fotograma de cada
; cuatro solo se mueve el mono. Medido en una partida (2026-08-19).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
MONO_Y_CANGREJOS:		; El reloj, los mandos a E10B, las tarjetas cada 8 fotogramas, la colision y un paso de cada actor
	call RELOJ		;4822
	ld a,(0e009h)		;4825   ; Izquierda, derecha y los dos botones (bits 2-5) suben al nibble alto
	and 03ch		;4828
	ld b,a			;482a
	add a,a			;482b
	add a,a			;482c
	add a,a			;482d
	add a,a			;482e
	or b			;482f
	and 0f0h		;4830
	ld (0e10bh),a		;4832
	ld a,(0e003h)		;4835
	and 007h		;4838
	jr nz,MONO_COLISION		;483a
	call PINTA_TARJETAS		;483c
MONO_COLISION:		; La colision con los cangrejos y, si no, el paso de los actores
	call COLISION_CANGREJOS		;483f   ; 0x69B0 devuelve carry si no hay colision
	jr c,MONO_ACTORES		;4842
	call CARA_DE_SUSTO		;4844   ; Le han pillado: cara de susto y estado 10 del mono (el mismo que cuando le da una fruta)
	ld hl,0e10ch		;4847
	ld (hl),00ah		;484a
MONO_ACTORES:		; Cuantos actores se mueven este fotograma (E272 cuenta los fotogramas)
	ld hl,0e272h		;484c
	inc (hl)			;484f
	ld a,(0e051h)		;4850   ; CUANTOS actores juegan: A = fase(BCD)/8 + 2, tope 4 (el mono y 1, 2 o 3 cangrejos); el bucle de 0x4860 llama a 0x5F5F con B = A..1 y B es el NUMERO de actor. Medido: en las fases 1-2 solo anda el cangrejo 1
	rra			;4853
	rra			;4854
	rra			;4855
	inc a			;4856
	and 01fh		;4857
	cp 004h		;4859
	jr nc,ACTORES_PASO_4		;485b
	and 003h		;485d
	inc a			;485f
ACTORES_PASO:		; Un paso de los actores A..1 (B baja con el djnz y es el numero de actor de 0x5F5F); con E272 & 3 == 0 (un fotograma de cada cuatro) solo el mono
	ld b,a			;4860
	ld a,(hl)			;4861
	and 003h		;4862
	jr nz,ACTORES_BUCLE		;4864
	ld b,001h		;4866
ACTORES_BUCLE:		; Un paso del actor B, y el anterior, hasta el mono (B = 1)
	call ACTOR_PASO		;4868
	djnz ACTORES_BUCLE		;486b
	ret			;486d
ACTORES_PASO_4:		; Los cuatro actores (fase 16 en adelante)
	ld a,004h		;486e
	jr ACTORES_PASO		;4870
VDP_R7:		; Registro 7 = A (color de fondo y borde)
	ld d,087h		;4872
	ld e,a			;4874
	di			;4875
	call VDP_DIRECCION		;4876
	ei			;4879
	ret			;487a
VDP_REGISTROS:		; Los 8 registros del VDP desde la tabla de 0x488C
	ld hl,0488ch		;487b
	ld b,008h		;487e
	ld d,080h		;4880
VDP_REGISTROS_BUCLE:		; Registro por registro (D = 0x80 + n)
	ld e,(hl)			;4882
	di			;4883
	call VDP_DIRECCION		;4884
	inc hl			;4887
	inc d			;4888
	djnz VDP_REGISTROS_BUCLE		;4889
	ret			;488b

; ----------------------------------------------------------------------
; DATOS registros_vdp: R0-R7 de arranque: 02 (SCREEN 2), A2 (16K, pantalla
;   apagada, interrupciones, sprites 16x16), 0E (nombres en 0x3800), 7F
;   (colores en 0x0000), 07 (patrones en 0x2000), 76 (atributos en 0x3B00), 03
;   (patrones de sprites en 0x1800), E1 (fondo negro)
;   0x488c..0x4894  (8 bytes)
DATA_registros_vdp:
	defb 002h,0a2h,00eh,07fh,007h,076h,003h,0e1h	; 488c  .....v..

; ======================================================================
; CODIGO 0x4894..0x4ae0  (588 bytes)
; ======================================================================


COPIA_A_VRAM:		; BC bytes desde HL a la VRAM DE (con di; el que llama pone ei)
	di			;4894
	set 6,d		;4895
	call VDP_DIRECCION		;4897
	res 6,d		;489a
COPIA_A_VRAM_YA:		; Sin poner la direccion: el VDP ya apunta
	push hl			;489c
	push bc			;489d
COPIA_A_VRAM_BUCLE:		; Byte a byte al puerto 0x98
	ld a,(hl)			;489e
	out (098h),a		;489f
	inc hl			;48a1
	dec bc			;48a2
	ld a,b			;48a3
	or c			;48a4
	jr nz,COPIA_A_VRAM_BUCLE		;48a5
	pop bc			;48a7
	pop hl			;48a8
	ret			;48a9
RELLENA_VRAM:		; BC bytes de A en la VRAM DE
	push af			;48aa
	push hl			;48ab
	push bc			;48ac
	di			;48ad
	ld h,a			;48ae
	set 6,d		;48af
	call VDP_DIRECCION		;48b1
	res 6,d		;48b4
RELLENA_VRAM_BUCLE:		; El mismo byte BC veces
	ld a,h			;48b6
	out (098h),a		;48b7
	dec bc			;48b9
	ld a,b			;48ba
	or c			;48bb
	jr nz,RELLENA_VRAM_BUCLE		;48bc
	pop bc			;48be
	pop hl			;48bf
	pop af			;48c0
	ret			;48c1
CORTINILLA:		; Un paso de la cortinilla: borra una columna entera (24 filas) de izquierda a derecha y de derecha a izquierda a la vez; devuelve M al acabar, P mientras
	ld d,038h		;48c2
	ld hl,0e004h		;48c4
	ld b,018h		;48c7
	bit 6,(hl)		;48c9   ; Bit 6 de E004: fotograma par (columna de la izquierda) o impar (la de la derecha)
	jr nz,CORTINILLA_IMPAR		;48cb
	ld a,01fh		;48cd
	sub (hl)			;48cf
	ld e,a			;48d0
	set 6,(hl)		;48d1
	jr CORTINILLA_COLUMNA		;48d3
CORTINILLA_IMPAR:		; Fotograma impar: la columna de la derecha (E004 baja)
	res 6,(hl)		;48d5
	dec (hl)			;48d7
	ret m			;48d8
	ld e,(hl)			;48d9
CORTINILLA_COLUMNA:		; Los 24 tiles de una columna a cero
	xor a			;48da
	call VPOKE		;48db
	ld a,020h		;48de
	ex de,hl			;48e0
	call HL_MAS_A		;48e1
	ex de,hl			;48e4
	djnz CORTINILLA_COLUMNA		;48e5
	xor a			;48e7
	ret			;48e8
PINTA_LISTA_TILES:		; Lista de HL: dos bytes de VRAM y tiles seguidos; 0xFE cambia de direccion, 0xFF acaba
	ld e,(hl)			;48e9
	inc hl			;48ea
	ld d,(hl)			;48eb
	inc hl			;48ec
PINTA_LISTA_SIGUE:		; El bucle de tiles con DE ya puesto
	ld a,(hl)			;48ed
	inc hl			;48ee
	ld b,a			;48ef
	inc b			;48f0
	ret z			;48f1
	inc b			;48f2
	jr z,PINTA_LISTA_TILES		;48f3
	call VPOKE		;48f5
	inc de			;48f8
	jr PINTA_LISTA_SIGUE		;48f9
INTERCAMBIA:		; B bytes de HL con los de DE (los datos de los dos jugadores)
	ld c,(hl)			;48fb
	ld a,(de)			;48fc
	ld (hl),a			;48fd
	ld a,c			;48fe
	ld (de),a			;48ff
	inc hl			;4900
	inc de			;4901
	djnz INTERCAMBIA		;4902
	ret			;4904
PSG_PUERTO_JOYSTICK:		; Registro 15 del PSG = 0x8F, o 0xCF (bit 6) para el puerto 2 si juega el 2P
	ld a,00fh		;4905
	out (0a0h),a		;4907
	ld a,08fh		;4909
	ld hl,0e002h		;490b
	bit 7,(hl)		;490e
	jr z,PSG_R15		;4910
	set 6,a		;4912
PSG_R15:		; Al registro 15
	out (0a1h),a		;4914
	ret			;4916
SIN_LLAMADAS_COLOR_F0:		; `ld a,0F0h` y cae en COLOR_FUENTE: la fuente en blanco sobre transparente, que nadie pide
	ld a,0f0h		;4917
COLOR_FUENTE:		; Los colores de los tiles 0x30-0x5F (cifras y letras) = A en los tres tercios
	ld de,00180h		;4919
	ld bc,00180h		;491c
COLOR_TRES_TERCIOS:		; BC bytes de A en la VRAM DE y en los dos tercios siguientes
	push af			;491f
	call RELLENA_VRAM		;4920
	ld a,d			;4923
	add a,008h		;4924
	ld d,a			;4926
	pop af			;4927
	push af			;4928
	call RELLENA_VRAM		;4929
	ld a,d			;492c
	add a,008h		;492d
	ld d,a			;492f
	pop af			;4930
	jp RELLENA_VRAM		;4931
COPIA_TRES_TERCIOS:		; BC bytes de HL en la VRAM DE y en los dos tercios siguientes
	call COPIA_A_VRAM		;4934
	ld a,d			;4937
	add a,008h		;4938
	ld d,a			;493a
	call COPIA_A_VRAM		;493b
	ld a,d			;493e
	add a,008h		;493f
	ld d,a			;4941
	jp COPIA_A_VRAM		;4942

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS PUNTOS. CDE en BCD (seis cifras) se suman a los del jugador que
; juega; en la demo no. Vida extra al pasar de cada 20000 (E052 son las
; decenas de millar del siguiente), y el record de paso.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
SUMA_PUNTOS:		; CDE (BCD) a E043 (1P) o E046 (2P); solo con partida en marcha (bit 6 de E002)
	ld a,(0e002h)		;4945
	add a,a			;4948   ; Bit 6 al carry: sin partida (la demo) no se suman
	ret p			;4949
	ld hl,0e043h		;494a
	jr nc,SUMA_PUNTOS_BCD		;494d
	ld l,046h		;494f   ; Bit 7 al carry: E046 para el 2P
SUMA_PUNTOS_BCD:		; La suma en BCD de las tres parejas
	ld a,(hl)			;4951
	add a,e			;4952
	daa			;4953
	ld (hl),a			;4954
	ld e,a			;4955
	inc l			;4956
	ld a,(hl)			;4957
	adc a,d			;4958
	daa			;4959
	ld (hl),a			;495a
	ld d,a			;495b
	jr nc,SUMA_PUNTOS_ALTO		;495c
	inc hl			;495e
	ld a,(hl)			;495f
	adc a,c			;4960
	daa			;4961
	ld (hl),a			;4962
	jr nc,VIDA_EXTRA		;4963
	ld bc,09999h		;4965   ; Mas de 999999: se clava el record en 999999
	ld (0e040h),bc		;4968
	ld (0e041h),bc		;496c
	jp PINTA_RECORD		;4970
SUMA_PUNTOS_ALTO:		; Al byte alto para la vida extra
	inc hl			;4973
VIDA_EXTRA:		; Cuando las decenas de millar de los puntos (E045) superan E052: una vida mas, se pintan, sonido 0x10 y E052 += 2. E052 arranca en 0: la primera a los 10000, luego cada 20000 (30000, 50000...). Medido: vida extra con 010260
	ld a,(0e052h)		;4974
	cp (hl)			;4977
	push de			;4978
	push hl			;4979
	jr nc,RECORD		;497a
	add a,002h		;497c   ; La siguiente, 20000 mas alla
	daa			;497e
	jr nc,VIDA_EXTRA_DA		;497f
	ld a,0ffh		;4981
VIDA_EXTRA_DA:		; La siguiente ya apuntada: una vida mas
	ld (0e052h),a		;4983
	ld hl,0e050h		;4986
	inc (hl)			;4989
	call PINTA_VIDAS		;498a
	pop hl			;498d
	ld a,010h		;498e
	call SONIDO		;4990
	jr RECORD_MIRA		;4993
RECORD:		; Si los puntos superan el record, se copian y se pinta
	pop hl			;4995
RECORD_MIRA:		; Compara los puntos con el record, byte a byte
	ld a,(0e042h)		;4996
	ld b,(hl)			;4999
	sub (hl)			;499a
	ex de,hl			;499b
	pop de			;499c
	jr c,RECORD_NUEVO		;499d
	jr nz,PINTA_PUNTOS		;499f
	push hl			;49a1
	ld hl,(0e040h)		;49a2
	sbc hl,de		;49a5
	pop hl			;49a7
	jr nc,PINTA_PUNTOS		;49a8
RECORD_NUEVO:		; Los puntos pasan a ser el record
	ld (0e040h),de		;49aa
	ld a,b			;49ae
	ld (0e042h),a		;49af
	jr PINTA_RECORD		;49b2
PINTA_MARCADOR:		; La pantalla de juego entera: plataformas de la fase, panel azul, TIME, HI, STAGE, 1UP (y 2UP), record, puntos, vidas, fase, flores, y las tablas de sprites y actores
	call BORRA_PANTALLA		;49b4
	call PINTA_PLATAFORMAS		;49b7   ; Las plataformas de la fase (0x6685)
	ld hl,066f0h		;49ba   ; El panel azul: 7 columnas x 22 filas del tile 0x60 desde la fila 2, columna 25
	call PINTA_RECUADRO		;49bd   ; "TIME" y "00:00", el Konami de abajo, y HI / STAGE / 1UP
	ld hl,066cch		;49c0
	call PINTA_LISTA_TILES		;49c3
	ld hl,066dbh		;49c6
	call PINTA_LISTA_TILES		;49c9
	ld hl,06b72h		;49cc
	call PINTA_LISTA_TILES		;49cf
	ld a,(0e002h)		;49d2
	bit 5,a		;49d5   ; Con dos jugadores, "2UP" y sus puntos
	jr z,PINTA_MARCADOR_RESTO		;49d7
	ld hl,06b85h		;49d9
	call PINTA_LISTA_TILES		;49dc
	ld a,(0e002h)		;49df
	xor 080h		;49e2
	call PINTA_PUNTOS_DE		;49e4
PINTA_MARCADOR_RESTO:		; Vidas, fase, flores, sprites y colores
	call PINTA_VIDAS		;49e7   ; Vidas, fase, flores
	call PINTA_FASE		;49ea
	call PINTA_FLORES		;49ed
	ld hl,04b04h		;49f0
	ld de,0e0b0h		;49f3
	ld bc,00020h		;49f6
	ldir		;49f9
	ld de,0e108h		;49fb
	ld c,020h		;49fe
	ldir		;4a00
	call COLORES_DEL_PANEL		;4a02   ; Colores del panel (0x665A) y R7 = 1
PINTA_RECORD:		; El record en la fila 6, columna 25
	ld hl,0e042h		;4a05
	ld de,038d9h		;4a08
	call PINTA_3_BYTES_BCD		;4a0b
PINTA_PUNTOS:		; Los puntos del jugador que juega
	ld a,(0e002h)		;4a0e
PINTA_PUNTOS_DE:		; Los puntos del jugador del bit 7 de A: 1P en la fila 9, 2P en la 12, columna 25
	ld de,03939h		;4a11
	ld hl,0e045h		;4a14
	add a,a			;4a17
	jr nc,PINTA_3_BYTES_BCD		;4a18
	ld e,099h		;4a1a
	ld hl,0e048h		;4a1c
PINTA_3_BYTES_BCD:		; Seis cifras (HL apunta al byte alto)
	ld b,003h		;4a1f
	jp PINTA_BYTES_BCD		;4a21
PINTA_FASE:		; E051 (BCD, y si llega a 100 vuelve a 0) en la fila 20, columna 26
	ld de,03a9ah		;4a24
	ld hl,0e051h		;4a27
	sub a			;4a2a
	ex af,af'			;4a2b
	ld a,(hl)			;4a2c
	cp 064h		;4a2d   ; Fase 100 (0x64 en binario, aunque E051 es BCD): vuelta a 0
	jr c,FASE_DECENAS		;4a2f
	sub a			;4a31
	ld (hl),a			;4a32
FASE_DECENAS:		; Cuenta las decenas restando 10
	sub 00ah		;4a33
	jr c,FASE_UNIDADES		;4a35
	ex af,af'			;4a37
	inc a			;4a38
	ex af,af'			;4a39
	jr FASE_DECENAS		;4a3a
FASE_UNIDADES:		; Las unidades y las decenas juntas
	add a,00ah		;4a3c
	and 00fh		;4a3e
	ld h,a			;4a40
	ex af,af'			;4a41
	add a,a			;4a42
	add a,a			;4a43
	add a,a			;4a44
	add a,a			;4a45
	and 0f0h		;4a46
	or h			;4a48
	ld hl,0e1b0h		;4a49
	ld (hl),a			;4a4c
	ld b,001h		;4a4d
PINTA_BYTES_BCD:		; B bytes BCD desde HL hacia abajo, dos cifras cada uno, en la VRAM DE
	ld a,(hl)			;4a4f
	push af			;4a50
	and 00fh		;4a51
	or 030h		;4a53
	ld c,a			;4a55
	pop af			;4a56
	and 0f0h		;4a57
	rra			;4a59
	rra			;4a5a
	rra			;4a5b
	rra			;4a5c
	or 030h		;4a5d
	call VPOKE		;4a5f
	inc de			;4a62
	ld a,c			;4a63
	call VPOKE		;4a64
	dec hl			;4a67
	inc de			;4a68
	djnz PINTA_BYTES_BCD		;4a69
	ret			;4a6b
PARPADEA_1UP:		; Cada 32 fotogramas: "1UP" (fila 8) o "2UP" (fila 11) sobre los puntos del jugador que juega, alternando con el azul
	ld a,(0e003h)		;4a6c
	ld bc,(0e002h)		;4a6f
	ld b,a			;4a73
	ld a,01fh		;4a74
	and b			;4a76
	ret nz			;4a77
	ld de,0391ah		;4a78
	ld a,c			;4a7b
	ld c,050h		;4a7c
	ld h,031h		;4a7e   ; '1' 'U' 'P'
	bit 7,a		;4a80
	jr z,PARPADEA_1UP_MIRA		;4a82
	ld de,0397ah		;4a84
	inc h			;4a87
PARPADEA_1UP_MIRA:		; Lee lo que hay en la VRAM: letras o azul
	ld l,055h		;4a88
	di			;4a8a
	call VDP_DIRECCION		;4a8b
	call RET_2		;4a8e
	in a,(098h)		;4a91   ; Si esta el azul (0x60), letras; si estan las letras, azul
	ei			;4a93
	cp 060h		;4a94
	jr z,PARPADEA_1UP_PINTA		;4a96
	ld a,060h		;4a98
	ld h,a			;4a9a
	ld l,a			;4a9b
	ld c,a			;4a9c
PARPADEA_1UP_PINTA:		; Los tres tiles
	ld a,h			;4a9d
	call VPOKE		;4a9e
	inc de			;4aa1
	ld a,l			;4aa2
	call VPOKE		;4aa3
	ld a,c			;4aa6
	inc de			;4aa7
	call VPOKE		;4aa8
RET_2:		; Otro `ret` suelto de espera para el VDP
	ret			;4aab
PINTA_VIDAS:		; Hasta tres caras de mono de 2x2 (0x4AE0) en la fila 14, columna 25; las que no hay, azul
	ld de,070c8h		;4aac
	ld a,(0e050h)		;4aaf
	ld c,a			;4ab2
	ld b,003h		;4ab3
	ld hl,04ae0h		;4ab5
PINTA_VIDAS_UNA:		; Cada hueco: cara o azul, y 16 pixels a la derecha
	dec c			;4ab8
	jp p,PINTA_VIDA_BLOQUE		;4ab9
	ld hl,04ae4h		;4abc
PINTA_VIDA_BLOQUE:		; El bloque de 2x2 del hueco
	push bc			;4abf
	ld bc,00202h		;4ac0
	push hl			;4ac3
	push de			;4ac4
	call PINTA_BLOQUE		;4ac5
	pop de			;4ac8
	pop hl			;4ac9
	pop bc			;4aca
	ld a,010h		;4acb
	add a,e			;4acd
	ld e,a			;4ace
	djnz PINTA_VIDAS_UNA		;4acf
	ret			;4ad1
PINTA_FALLOS:		; Los fallos (E057) como caras de 2x2 (0x4AE8) en la fila 17, columna 25
	ld de,088c8h		;4ad2
	ld a,(0e057h)		;4ad5
	ld c,a			;4ad8
	ld b,003h		;4ad9
	ld hl,04ae8h		;4adb
	jr PINTA_VIDAS_UNA		;4ade

; ----------------------------------------------------------------------
; DATOS cara_de_vida: El bloque de 2x2 tiles de una vida (0x0D 0x0F / 0x0E
;   0x10): la cara del mono
;   0x4ae0..0x4ae4  (4 bytes)
DATA_cara_de_vida:
	defb 00dh,00fh,00eh,010h	; 4ae0

; ----------------------------------------------------------------------
; DATOS hueco_azul: Cuatro tiles 0x60: el hueco de una vida que ya no esta
;   0x4ae4..0x4ae8  (4 bytes)
DATA_hueco_azul:
	defb 060h,060h,060h,060h	; 4ae4

; ----------------------------------------------------------------------
; DATOS cara_de_fallo: El bloque de 2x2 de un fallo (0x11 0x13 / 0x12 0x14):
;   la cara del mono llorando
;   0x4ae8..0x4aec  (4 bytes)
DATA_cara_de_fallo:
	defb 011h,013h,012h,014h	; 4ae8

; ======================================================================
; CODIGO 0x4aec..0x4b04  (24 bytes)
; ======================================================================


MONTA_DEMO:		; Fase 1, guion de la demo desde el principio, fuente blanca, colores del panel y el marcador entero
	ld hl,0e051h		;4aec
	ld (hl),001h		;4aef
	xor a			;4af1
	ld (0e1b0h),a		;4af2
	ld (0e1b1h),a		;4af5
	ld a,0f4h		;4af8
	call COLOR_FUENTE		;4afa
	call COLORES_DEL_PANEL		;4afd
	call PINTA_MARCADOR		;4b00
	ret			;4b03

; ----------------------------------------------------------------------
; DATOS sprites_iniciales: Los ocho primeros atributos de sprite (Y, X,
;   patron, color) para E0B0: el mono (patrones 0x00 azul y 0x0C blanco) y los
;   tres cangrejos (0x30 rojo y 0x3C amarillo), todos escondidos (Y = 0xE1) en
;   X = 8
;   0x4b04..0x4b24  (32 bytes)
DATA_sprites_iniciales:
	defb 0e1h,008h,000h,005h	; 4b04
	defb 0e1h,008h,00ch,00fh	; 4b08
	defb 0e1h,008h,030h,008h	; 4b0c
	defb 0e1h,008h,03ch,00bh	; 4b10
	defb 0e1h,008h,030h,008h	; 4b14
	defb 0e1h,008h,03ch,00bh	; 4b18
	defb 0e1h,008h,030h,008h	; 4b1c
	defb 0e1h,008h,03ch,00bh	; 4b20

; ----------------------------------------------------------------------
; DATOS actores_iniciales: Los cuatro registros de actor de E108: mono (tipo
;   0), cangrejos de tipo 1, 2 y 3 (0x41, 0x82, 0x43: el bit 6/7 es la
;   direccion) con temporizadores 0x20, 0x40, 0x60 antes de salir
;   0x4b24..0x4b44  (32 bytes)
DATA_actores_iniciales:
	defb 000h,000h,000h,000h,001h,000h,000h,000h	; 4b24  ........
	defb 000h,000h,000h,041h,000h,020h,000h,000h	; 4b2c  ...A. ..
	defb 000h,000h,000h,082h,000h,040h,000h,000h	; 4b34  .....@..
	defb 000h,000h,000h,043h,000h,060h,000h,000h	; 4b3c  ...C.`..

; ======================================================================
; CODIGO 0x4b44..0x4b78  (52 bytes)
; ======================================================================


DEMO_GUION:		; Cada 8 fotogramas el byte siguiente de 0x4B78 a E10B (los mandos de la demo); 0xFF acaba (E00B = 0xFF); y un paso de cada actor
	ld hl,0e1b0h		;4b44
	ld a,(hl)			;4b47
	and 007h		;4b48
	jr nz,DEMO_RELOJ		;4b4a
	ex de,hl			;4b4c
	ld a,(0e1b1h)		;4b4d
	ld hl,04b78h		;4b50
	call HL_MAS_A		;4b53
	ld a,(hl)			;4b56
	cp 0ffh		;4b57
	jr z,DEMO_FIN_GUION		;4b59
	ld (0e10bh),a		;4b5b
	ex de,hl			;4b5e
	inc (hl)			;4b5f
	inc hl			;4b60
DEMO_RELOJ:		; El reloj de la demo (E1B0)
	inc (hl)			;4b61
	ld a,(0e003h)		;4b62
	and 007h		;4b65
	jr nz,DEMO_ACTORES		;4b67
	call PINTA_TARJETAS		;4b69
DEMO_ACTORES:		; Un paso de los actores
	ld b,001h		;4b6c
DEMO_ACTORES_BUCLE:		; Los cuatro
	call ACTOR_PASO		;4b6e
	djnz DEMO_ACTORES_BUCLE		;4b71
	ld a,b			;4b73
DEMO_FIN_GUION:		; E00B = 0 (sigue) o 0xFF (se acabo el guion)
	ld (0e00bh),a		;4b74
	ret			;4b77

; ----------------------------------------------------------------------
; DATOS guion_de_la_demo: Los mandos de la demo, uno cada 8 fotogramas, en el
;   formato de E10B: 0x80 derecha, 0x40 izquierda, 0x10 disparo, 0x20 boton 2,
;   0x50/0x90 con salto; 0xFF fin
;   0x4b78..0x4bf0  (120 bytes)
DATA_guion_de_la_demo:
	defb 080h,080h,080h,080h,010h,080h,080h,080h,080h,080h,080h,080h,010h,010h,010h,010h	; 4b78  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 4b88  ................
	defb 080h,080h,010h,010h,010h,010h,080h,080h,040h,010h,040h,040h,040h,040h,040h,010h	; 4b98  ........@.@@@@@.
	defb 010h,010h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,040h,040h,050h,050h	; 4ba8  ............@@PP
	defb 050h,050h,040h,040h,040h,040h,010h,010h,010h,010h,010h,000h,000h,000h,000h,020h	; 4bb8  PP@@@@......... 
	defb 000h,000h,000h,000h,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,080h	; 4bc8  .... ...........
	defb 080h,080h,080h,090h,090h,090h,090h,090h,080h,080h,090h,090h,090h,090h,090h,080h	; 4bd8  ................
	defb 080h,010h,010h,010h,010h,000h,000h,0ffh	; 4be8  ........

; ======================================================================
; CODIGO 0x4bf0..0x4c5f  (111 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL TITULO "Monkey Academy" es un dibujo de 192x21 pixels (0x4CD0)
; que se pinta fila a fila en los patrones de los tiles 0xB8-0xFF
; (24 tiles por fila, tres filas), con las tres bandas de color de
; 0x4C5F. Los tiles se colocan en las filas 4-6 desde la columna 5.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PREPARA_TITULO:		; Patrones 0xB8-0xFF a cero, la fila 11 limpia, los colores del titulo, los tiles 0xB8.. colocados en las filas 4-6 y la fuente en cyan
	ld de,025c0h		;4bf0
	ld bc,00240h		;4bf3
	xor a			;4bf6
	call RELLENA_VRAM		;4bf7
	ld de,03966h		;4bfa   ; 19 tiles de la fila 11 desde la columna 6 (donde iba VIDEO CARTRIDGE)
	ld bc,00013h		;4bfd
	xor a			;4c00
	call RELLENA_VRAM		;4c01
	call COLORES_TITULO		;4c04
	ld de,03885h		;4c07   ; Fila 4, columna 5: los tiles 0xB8, 0xB9... 24 por fila, tres filas
	ld a,0b8h		;4c0a
	ld c,000h		;4c0c
TITULO_FILA_TILES:		; Una fila de 24 tiles seguidos
	ld b,018h		;4c0e
TITULO_FILA_TILE:		; Uno
	call VPOKE		;4c10
	inc a			;4c13
	inc de			;4c14
	djnz TITULO_FILA_TILE		;4c15
	ex de,hl			;4c17
	ld d,a			;4c18
	ld a,008h		;4c19
	call HL_MAS_A		;4c1b
	ex de,hl			;4c1e
	inc c			;4c1f
	ld a,c			;4c20
	cp 003h		;4c21
	ld a,h			;4c23
	jr nz,TITULO_FILA_TILES		;4c24
	ld a,070h		;4c26   ; 0x70: la fuente en cyan (el menu)
	call COLOR_FUENTE		;4c28
	ld de,00980h		;4c2b   ; Colores 0x0980 = 0x0180 en el segundo tercio: los tiles 0x30-0x3F blancos sobre transparente
	ld bc,00080h		;4c2e
	ld a,0f0h		;4c31
	call RELLENA_VRAM		;4c33
	ret			;4c36
COLORES_TITULO:		; Los colores de los tiles 0xB8-0xFF: una banda de 8 bytes distinta por fila de tiles (0x4C5F, 0x4C67, 0x4C6F)
	di			;4c37
	ld de,045c0h		;4c38
	call VDP_DIRECCION		;4c3b
	di			;4c3e
	ld hl,04c5fh		;4c3f
	call COLORES_TITULO_FILA		;4c42
	ld hl,04c67h		;4c45
	call COLORES_TITULO_FILA		;4c48
	ld hl,04c6fh		;4c4b
COLORES_TITULO_FILA:		; 24 tiles con la misma banda de 8 bytes
	ld b,018h		;4c4e
COLORES_TITULO_TILE:		; Los 8 bytes de un tile
	ld d,h			;4c50
	ld e,l			;4c51
	push bc			;4c52
	ld b,008h		;4c53
COLORES_TITULO_BYTE:		; Un byte de color
	ld a,(de)			;4c55
	out (098h),a		;4c56
	inc de			;4c58
	djnz COLORES_TITULO_BYTE		;4c59
	pop bc			;4c5b
	djnz COLORES_TITULO_TILE		;4c5c
	ret			;4c5e

; ----------------------------------------------------------------------
; DATOS bandas_del_titulo: Tres bandas de 8 colores por fila de tiles: 20 20
;   F0 80 80 F0 20 20 (verde, blanco, rojo), 20 20 F0 80 80 F0 20 20 y 20 20
;   20 20 20 20 20 20 (verde). Es el rayado del rotulo
;   0x4c5f..0x4c77  (24 bytes)
DATA_bandas_del_titulo:
	defb 020h,020h,0f0h,080h,080h,0f0h,020h,020h	; 4c5f    ....  
	defb 0f0h,020h,020h,0f0h,080h,080h,0f0h,020h	; 4c67  .  .... 
	defb 020h,0f0h,020h,020h,020h,020h,020h,020h	; 4c6f   .      

; ======================================================================
; CODIGO 0x4c77..0x4cd0  (89 bytes)
; ======================================================================


TITULO_UNA_FILA:		; Una fila de 24 bytes del dibujo de 0x4CD0 a los 24 tiles de la fila en curso; carry mientras quede dibujo, y "©Konami 1984" (0x6B8B) al acabar
	ld de,(0e246h)		;4c77
	ld bc,(0e248h)		;4c7b
	ld hl,04cd0h		;4c7f
	add hl,bc			;4c82
	ld b,018h		;4c83
TITULO_UNA_FILA_BYTE:		; Un byte del dibujo a un tile, y 8 mas alla
	ld a,(hl)			;4c85
	call VPOKE		;4c86
	inc hl			;4c89
	ld a,008h		;4c8a
	ex de,hl			;4c8c
	call HL_MAS_A		;4c8d
	push hl			;4c90
	push bc			;4c91
	ld bc,0d7fch		;4c92   ; Al llegar a 0x2804 (el final del tile 0xFF mas uno) se ha acabado el dibujo
	add hl,bc			;4c95
	pop bc			;4c96
	pop hl			;4c97
	jr c,TITULO_ACABADO		;4c98
	ex de,hl			;4c9a
	djnz TITULO_UNA_FILA_BYTE		;4c9b
	ld bc,(0e248h)		;4c9d
	ld a,018h		;4ca1
	add a,c			;4ca3
	ld c,a			;4ca4
	jr nc,TITULO_FILA_SIGUIENTE		;4ca5
	inc b			;4ca7
TITULO_FILA_SIGUIENTE:		; La fila de pixel siguiente
	ld (0e248h),bc		;4ca8
	inc de			;4cac   ; Fila de pixel siguiente; si se pasa del tile, salta a la fila de tiles siguiente (24 tiles mas alla)
	ld a,e			;4cad
	and 007h		;4cae
	jr z,TITULO_FILA_DE_TILES_SIGUIENTE		;4cb0
	ld hl,(0e246h)		;4cb2
	inc hl			;4cb5
	ld (0e246h),hl		;4cb6
	scf			;4cb9
	ret			;4cba
TITULO_FILA_DE_TILES_SIGUIENTE:		; Se paso del tile: 24 tiles mas alla
	ex de,hl			;4cbb
	ld a,l			;4cbc
	sub 008h		;4cbd
	ld l,a			;4cbf
	jr nc,TITULO_CURSOR		;4cc0
	dec h			;4cc2
TITULO_CURSOR:		; Guarda el cursor y devuelve carry (queda dibujo)
	ld (0e246h),hl		;4cc3
	scf			;4cc6
	ret			;4cc7
TITULO_ACABADO:		; "©Konami 1984" debajo y NC
	ld hl,06b8bh		;4cc8
	call PINTA_LISTA_TILES		;4ccb
	or a			;4cce
	ret			;4ccf

; ----------------------------------------------------------------------
; DATOS dibujo_del_titulo: "Monkey Academy": 21 filas de 24 bytes (192 pixels
;   de ancho), un bit por pixel, tal como se pinta en los patrones 0xB8-0xFF
;   0x4cd0..0x4ec8  (504 bytes)
DATA_dibujo_del_titulo:
	defb 0f0h,01eh,000h,000h,000h,01ch,000h,000h,000h,000h,000h,000h,003h,0e0h,000h,000h,000h,001h,0c0h,000h,000h,000h,000h,000h	; 4cd0  ........................
	defb 0f8h,03eh,000h,000h,000h,01ch,000h,000h,000h,000h,000h,000h,003h,0e0h,000h,000h,000h,001h,0c0h,000h,000h,000h,000h,000h	; 4ce8  .>......................
	defb 0fch,07eh,000h,000h,000h,01ch,000h,000h,000h,000h,000h,000h,007h,0f0h,000h,000h,000h,001h,0c0h,000h,000h,000h,000h,000h	; 4d00  .~......................
	defb 0feh,0feh,000h,000h,000h,01ch,000h,000h,000h,000h,000h,000h,007h,0f0h,000h,000h,000h,001h,0c0h,000h,000h,000h,000h,000h	; 4d18  ........................
	defb 0ffh,0feh,007h,080h,000h,01ch,000h,000h,000h,000h,000h,000h,00fh,078h,003h,080h,000h,001h,0c0h,000h,000h,000h,000h,000h	; 4d30  .............x..........
	defb 0ffh,0feh,01fh,0e1h,0dch,01ch,078h,01eh,00fh,01eh,000h,000h,00fh,078h,00fh,0c7h,0f0h,03dh,0c1h,0e0h,000h,000h,078h,0f0h	; 4d48  ......x......x...=....x.
	defb 0f7h,0deh,03fh,0f1h,0ffh,01ch,0f0h,07fh,08fh,01eh,000h,000h,00eh,038h,01fh,0c7h,0f8h,0ffh,0c7h,0f8h,0e7h,038h,078h,0f0h	; 4d60  ..?..........8.......8x.
	defb 0f3h,09eh,03ch,0f1h,0ffh,09dh,0e0h,073h,087h,01ch,000h,000h,01eh,03ch,01ch,040h,078h,0ffh,0c7h,038h,0ffh,0fch,038h,0e0h	; 4d78  ..<....s.....<.@x..8..8.
	defb 0f1h,01eh,078h,079h,0e7h,09fh,0c0h,0e1h,0c7h,0bch,000h,000h,01fh,0fch,038h,000h,039h,0e3h,0ceh,01ch,0f7h,0deh,03dh,0e0h	; 4d90  ..xy..........8.9.....=.
	defb 0f0h,01eh,078h,079h,0c3h,09fh,080h,0ffh,0c3h,0b8h,000h,000h,01fh,0fch,038h,007h,0f9h,0c1h,0cfh,0fch,0e3h,08eh,01dh,0c0h	; 4da8  ..xy..........8.........
	defb 0f0h,01eh,078h,079h,0c3h,09fh,080h,0ffh,0c3h,0f8h,000h,000h,03fh,0feh,038h,00fh,0f9h,0c1h,0cfh,0fch,0e3h,08eh,01fh,0c0h	; 4dc0  ..xy........?.8.........
	defb 0f0h,01eh,078h,079h,0c3h,09fh,0c0h,0e0h,003h,0f8h,000h,000h,03ch,01eh,038h,00eh,039h,0c1h,0ceh,000h,0e3h,08eh,01fh,0c0h	; 4dd8  ..xy........<.8.9.......
	defb 0f0h,01eh,03ch,0f1h,0c3h,09dh,0e0h,0f0h,041h,0f0h,000h,000h,03ch,01eh,01ch,04eh,039h,0e3h,0cfh,004h,0e3h,08eh,00fh,080h	; 4df0  ..<.....A...<..N9.......
	defb 0f0h,01eh,03fh,0f1h,0c3h,09ch,0f0h,07fh,0c1h,0f0h,000h,000h,078h,00eh,01fh,0cfh,0f8h,0ffh,0c7h,0fch,0e3h,08eh,00fh,080h	; 4e08  ..?.........x...........
	defb 0f0h,01eh,01fh,0e1h,0c3h,09ch,078h,07fh,0c0h,0e0h,000h,000h,078h,00fh,00fh,0cfh,0f8h,0ffh,0c7h,0fch,0e3h,08eh,007h,000h	; 4e20  ......x.....x...........
	defb 0f0h,01eh,007h,081h,0c3h,09ch,03ch,01fh,080h,0e0h,000h,000h,0f8h,00fh,083h,087h,0bch,03dh,0c1h,0f8h,0e3h,08eh,007h,000h	; 4e38  ......<..........=......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,001h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,00eh,000h	; 4e50  ........................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,001h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,00eh,000h	; 4e68  ........................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,003h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,01eh,000h	; 4e80  ........................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,003h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,01ch,000h	; 4e98  ........................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,007h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,03ch,000h	; 4eb0  ......................<.

; ======================================================================
; CODIGO 0x4ec8..0x5040  (376 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS TARJETAS. Diez por fase, en las posiciones (Y, X) de la tabla
; de 0x509E; cada jugador tiene las suyas en E1E4 (o E20E): dos
; bytes por tarjeta, el estado y la cifra. El estado: bits 0-1
; cuanto ha bajado (0-3), bit 4 se esta abriendo o cerrando, bit 6
; ya abierta del todo, bit 7 hay que repintarla. La tarjeta esta metida
; en la plataforma y solo asoma su canto (el 2x2 de 0x5082); al tirar
; de ella baja: se pintan las 3 - c filas de abajo del bloque de 3x2
; (en blanco, 0x507C, o con la cifra, 0x5040 + 6n) desde Y, y el canto
; justo debajo, porque PINTA_BLOQUE deja D avanzado tantas filas como
; pinto (el 8c + Y que calcula 0x4F42 se queda en A y no se usa).
; Mientras baja alterna el bloque en blanco y el de la cifra, y con el
; bit 4 el canto es el de 0x5086 (blanco y las dos rayas).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PINTA_TARJETAS:		; Recorre las tarjetas de E15A (0xFF fin); las que llevan el bit 7 se repintan en su fase de apertura y avanzan un paso
	ld b,000h		;4ec8
PINTA_TARJETA:		; La tarjeta B
	ld a,b			;4eca   ; B x 2: la pareja (Y, X) de la tarjeta en E15A
	sla a		;4ecb
	ld hl,0e15ah		;4ecd
	call HL_MAS_A		;4ed0
	ld a,(hl)			;4ed3
	cp 0ffh		;4ed4   ; 0xFF cierra la lista de la fase
	ret z			;4ed6
	push bc			;4ed7
	call TARJETAS_DEL_JUGADOR		;4ed8   ; HL = las tarjetas del jugador (E1E4 o E20E); B x 2 es la suya
	ld a,b			;4edb
	add a,a			;4edc
	call HL_MAS_A		;4edd
	ld a,(hl)			;4ee0
	pop bc			;4ee1
	bit 7,a		;4ee2   ; Bit 7: hay que repintarla
	jp z,TARJETA_SIGUIENTE		;4ee4
	ld c,a			;4ee7   ; C = el estado de la tarjeta
	ld a,(0e000h)		;4ee8
	cp 00ah		;4eeb
	jr z,PINTA_TARJETA_BLOQUE		;4eed
	ld a,00ah		;4eef   ; Fuera del estado 10 (montar la fase) suena el 0x0A al moverse
	call SONIDO		;4ef1
PINTA_TARJETA_BLOQUE:		; Elige el bloque: cifra o cerrada
	ld a,c			;4ef4
	push hl			;4ef5
	inc hl			;4ef6
	ld a,(hl)			;4ef7   ; El byte siguiente es su cifra: x 2 en la tabla de punteros 0x508A
	sla a		;4ef8
	ld hl,0508ah		;4efa
	call HL_MAS_A		;4efd
	ld e,(hl)			;4f00
	inc hl			;4f01
	ld d,(hl)			;4f02
	ex de,hl			;4f03   ; HL = el bloque de 3x2 de la cifra
	bit 4,c		;4f04   ; Bit 4 a cero: el bloque en blanco de 0x507C
	jr nz,PINTA_TARJETA_POS		;4f06
	ld hl,0507ch		;4f08
PINTA_TARJETA_POS:		; Su posicion (Y, X) y su estado
	push bc			;4f0b   ; Tres pushes: BC, el bloque dos veces (uno para el bloque, otro para el canto)
	push hl			;4f0c
	push hl			;4f0d
	ld a,b			;4f0e
	add a,a			;4f0f
	ld hl,0e15ah		;4f10
	call HL_MAS_A		;4f13
	ld d,(hl)			;4f16   ; D = Y, E = X de la tarjeta
	inc hl			;4f17
	ld e,(hl)			;4f18
	pop hl			;4f19
	call TARJETAS_DEL_JUGADOR		;4f1a
	ld a,b			;4f1d
	add a,a			;4f1e
	call HL_MAS_A		;4f1f
	ld a,(hl)			;4f22   ; C = cuanto ha bajado (0-3): HL = el bloque + 2C, o sea sin sus C primeras filas
	and 00fh		;4f23
	ld c,a			;4f25
	add a,a			;4f26
	pop hl			;4f27
	call HL_MAS_A		;4f28
	ld a,003h		;4f2b   ; A = 3 - C filas que asoman; ninguna si esta metida
	sub c			;4f2d
	jr nz,TARJETA_ASOMA		;4f2e
TARJETA_CANTO:		; Debajo de lo pintado (D ya va avanzado), el canto: 0x5082 o, con el bit 4, 0x5086
	ld a,b			;4f30   ; De nuevo el estado, por el bit 4: canto normal (0x5082) o abierto (0x5086)
	add a,a			;4f31
	call TARJETAS_DEL_JUGADOR		;4f32
	call HL_MAS_A		;4f35
	bit 4,(hl)		;4f38
	ld hl,05082h		;4f3a
	jr z,TARJETA_CANTO_PINTA		;4f3d
	ld hl,05086h		;4f3f
TARJETA_CANTO_PINTA:		; El bloque de 2x2 en (D, E); el 8c + D de A no se usa
	ld a,c			;4f42   ; 8C + Y en A, que nadie usa: PINTA_BLOQUE va con el D que trae, ya avanzado
	add a,a			;4f43
	add a,a			;4f44
	add a,a			;4f45
	add a,d			;4f46
	ld bc,00202h		;4f47   ; 2x2 en (D, E)
	call PINTA_BLOQUE		;4f4a
	jr TARJETA_AVANZA		;4f4d
TARJETA_ASOMA:		; Las 3 - c filas de abajo del bloque, desde Y; D queda debajo
	push bc			;4f4f   ; B = filas, C = 2 columnas, en (Y, X); PINTA_BLOQUE deja D debajo
	ld b,a			;4f50
	ld c,002h		;4f51
	call PINTA_BLOQUE		;4f53
	pop bc			;4f56
	jr TARJETA_CANTO		;4f57
TARJETA_AVANZA:		; Un paso mas: cambia el bit 4 (por eso alterna blanco y cifra) y baja o sube c segun el bit 6; al llegar al tope (0 abriendose, 3 cerrandose) se para: fuera los bits 7 y 6, cambia el 4
	pop bc			;4f59   ; HL = el estado de la tarjeta (el push de 0x4F0D)
	pop hl			;4f5a
	ld a,(hl)			;4f5b   ; A = cuanto ha bajado; el tope es 0 con el bit 4 y 3 sin el
	and 00fh		;4f5c
	bit 4,(hl)		;4f5e
	ld d,000h		;4f60   ; Con el bit 4 el tope es 0 (abierta del todo); sin el, 3 (metida)
	jr nz,TARJETA_AVANZA_MIRA		;4f62
	ld d,003h		;4f64
TARJETA_AVANZA_MIRA:		; Si ya esta en el tope
	cp d			;4f66
	jr z,TARJETA_AVANZA_TOPE		;4f67
	ld a,(hl)			;4f69   ; Cambia el bit 4 (por eso alterna blanco y cifra); si queda a 1 sube uno, y si el bit 6 esta a cero baja uno: neto -1 abriendose, +1 cerrandose
	xor 010h		;4f6a
	bit 4,a		;4f6c
	jr z,TARJETA_AVANZA_PASO		;4f6e
	inc a			;4f70
TARJETA_AVANZA_PASO:		; Un paso: abriendose baja (+1), cerrandose sube (-1)
	bit 6,a		;4f71
	jr nz,TARJETA_AVANZA_GUARDA		;4f73
	dec a			;4f75
TARJETA_AVANZA_GUARDA:		; El estado nuevo
	ld (hl),a			;4f76
	jr TARJETA_SIGUIENTE		;4f77
TARJETA_AVANZA_TOPE:		; Llego al tope: bits 7 y 6 fuera, bit 4 cambia
	ld a,(hl)			;4f79   ; En el tope: fuera bits 7 y 6, cambia el 4: 0x13 metida, 0x40 abierta
	xor 0d0h		;4f7a
	ld (hl),a			;4f7c
TARJETA_SIGUIENTE:		; La siguiente
	inc b			;4f7d
	jp PINTA_TARJETA		;4f7e
TARJETAS_DE_LA_FASE:		; Las 10 posiciones de la fase ((E051-1) & 7 de 0x509E) a E15A, todas metidas y por pintar (0xC3: al pintarlas pasan a 0x13), pintadas, y el mono sin tarjeta
	ld a,(0e051h)		;4f81   ; (Fase - 1) & 7: la lista de la fase, 21 bytes a E15A
	dec a			;4f84
	and 007h		;4f85
	add a,a			;4f87
	ld hl,0509eh		;4f88
	call HL_MAS_A		;4f8b
	ld e,(hl)			;4f8e
	inc hl			;4f8f
	ld d,(hl)			;4f90
	ex de,hl			;4f91
	ld de,0e15ah		;4f92
	ld bc,00015h		;4f95
	ldir		;4f98
	call TARJETAS_DEL_JUGADOR		;4f9a   ; Las diez del jugador: estado 0xC3 (por pintar, boca abajo, metida) sin tocar la cifra
	ld b,00ah		;4f9d
TARJETAS_CERRADAS_BUCLE:		; Las diez a 0xC3
	ld (hl),0c3h		;4f9f   ; 0xC3: metida (c = 3), con los bits 7 y 6; el primer pintado la deja en 0x13
	inc hl			;4fa1
	inc hl			;4fa2
	djnz TARJETAS_CERRADAS_BUCLE		;4fa3
	call PINTA_TARJETAS		;4fa5   ; Se pintan (y pasan a 0x13)
	ld a,0ffh		;4fa8   ; El mono no lleva ninguna
	ld (0e1afh),a		;4faa
	ret			;4fad
COGE_TARJETA:		; El mono coge la tarjeta A: si llevaba otra la deja (bit 7 para repintarla) y apunta la nueva en E1AF
	push af			;4fae   ; D = la tarjeta nueva; si E1AF ya tenia una, esa se marca para repintar (se cierra)
	ld d,a			;4faf
	ld hl,0e1afh		;4fb0
	ld a,0ffh		;4fb3
	ld b,(hl)			;4fb5
	cp (hl)			;4fb6
	jr z,COGE_TARJETA_PRIMERA		;4fb7
	ld a,b			;4fb9
	add a,a			;4fba
	call TARJETAS_DEL_JUGADOR		;4fbb
	call HL_MAS_A		;4fbe
	set 7,(hl)		;4fc1
	ld a,d			;4fc3
	ld (0e1afh),a		;4fc4
	pop af			;4fc7
	ret			;4fc8
COGE_TARJETA_PRIMERA:		; Sin tarjeta anterior: solo apunta la nueva
	ld (hl),d			;4fc9
	pop af			;4fca
	ret			;4fcb
BARAJA_CIFRAS:		; Las diez cifras en E1CF, empezando por una al azar; 64 barajadas al azar; y a las tarjetas del jugador (E1E4 o E20E) con estado 0x13, cifra a cifra
	call AZAR		;4fcc   ; La primera cifra al azar (nibble bajo, 0-9)
	ld a,(0e140h)		;4fcf   ; Empieza por una cifra al azar y sigue en orden 0-9
	and 00fh		;4fd2
	ld hl,0e1cfh		;4fd4
	ld b,00ah		;4fd7
BARAJA_ORDEN:		; Las diez cifras en orden desde la primera
	ld (hl),a			;4fd9   ; Y las diez seguidas en orden, dando la vuelta en el 9
	inc hl			;4fda
	inc a			;4fdb
	cp 00ah		;4fdc
	jr nz,BARAJA_ORDEN_SIGUE		;4fde
	xor a			;4fe0
BARAJA_ORDEN_SIGUE:		; La siguiente
	djnz BARAJA_ORDEN		;4fe1
	ld b,040h		;4fe3   ; 64 barajadas
BARAJA_VUELTA:		; Una barajada: la primera cifra a una posicion al azar
	push bc			;4fe5
	call AZAR		;4fe6
	ld a,(0e140h)		;4fe9
	ld c,a			;4fec   ; Suma de los dos nibbles del azar en BCD; el nibble bajo, y 9 si sale 0: la posicion (1-9)
	and 00fh		;4fed
	srl c		;4fef
	srl c		;4ff1
	srl c		;4ff3
	srl c		;4ff5
	add a,c			;4ff7
	daa			;4ff8
	and 00fh		;4ff9
	jr nz,BARAJA_MUEVE		;4ffb
	ld a,009h		;4ffd
BARAJA_MUEVE:		; La mueve
	ld b,000h		;4fff   ; Mueve la primera cifra a esa posicion: las de en medio suben una
	ld c,a			;5001
	ld hl,0e1cfh		;5002
	ld a,(hl)			;5005
	push af			;5006
	push hl			;5007
	pop de			;5008
	inc hl			;5009
	ldir		;500a
	pop af			;500c
	ld (de),a			;500d
	pop bc			;500e
	djnz BARAJA_VUELTA		;500f
	call TARJETAS_DEL_JUGADOR		;5011   ; Las diez tarjetas del jugador: estado 0x13 (metida) y su cifra detras
	push hl			;5014
	push hl			;5015
	pop de			;5016
	inc de			;5017
	ld bc,00011h		;5018
	ld (hl),013h		;501b
	ldir		;501d
	pop hl			;501f
	ld de,0e1cfh		;5020
	ld b,00ah		;5023
	inc hl			;5025
BARAJA_A_TARJETAS:		; Las diez cifras a las tarjetas del jugador
	ld a,(de)			;5026
	ld (hl),a			;5027
	inc hl			;5028
	inc hl			;5029
	inc de			;502a
	djnz BARAJA_A_TARJETAS		;502b
	ret			;502d
TARJETAS_DEL_JUGADOR:		; HL = E1E4 para el 1P, E20E (0x2A mas alla) para el 2P
	push af			;502e   ; Bit 7 de E002 al carry: el 2P tiene las suyas 0x2A mas alla (E20E)
	ld a,(0e002h)		;502f
	ld hl,0e1e4h		;5032
	rl a		;5035
	jr nc,TARJETAS_DEL_JUGADOR_FIN		;5037
	ld a,02ah		;5039
	call HL_MAS_A		;503b
TARJETAS_DEL_JUGADOR_FIN:		; Listo
	pop af			;503e
	ret			;503f

; ----------------------------------------------------------------------
; DATOS tarjetas_con_cifra: Diez bloques de 3x2 tiles, uno por cifra 0-9: la
;   fila de arriba es 61 61 (el borde blanco de la tarjeta) y las dos de abajo
;   la cifra en azul sobre blanco (tiles 0x62-0x7A). 0x508A los apunta
;   0x5040..0x507c  (60 bytes)
DATA_tarjetas_con_cifra:
	defb 061h,061h,063h,064h,066h,065h	; 5040
	defb 061h,061h,067h,068h,061h,069h	; 5046
	defb 061h,061h,06ah,0bah,06ch,06dh	; 504c
	defb 061h,061h,0b8h,0bah,0b9h,0bbh	; 5052
	defb 061h,061h,070h,068h,071h,072h	; 5058
	defb 061h,061h,073h,074h,075h,06fh	; 505e
	defb 061h,061h,073h,074h,076h,06fh	; 5064
	defb 061h,061h,077h,078h,079h,07ah	; 506a
	defb 061h,061h,0bch,0bah,0bdh,0bbh	; 5070
	defb 061h,061h,073h,06bh,075h,06fh	; 5076

; ----------------------------------------------------------------------
; DATOS tarjeta_en_blanco: El bloque de 3x2 en blanco (seis 0x61): la tarjeta
;   sin cifra, que alterna con la de la cifra mientras baja
;   0x507c..0x5082  (6 bytes)
DATA_tarjeta_en_blanco:
	defb 061h,061h,061h,061h,061h,061h	; 507c

; ----------------------------------------------------------------------
; DATOS canto_de_tarjeta: El bloque de 2x2 del canto de la tarjeta: 01 02 / 00
;   00 (la curva roja que asoma bajo la plataforma cuando esta metida, y que
;   baja con ella)
;   0x5082..0x5086  (4 bytes)
DATA_canto_de_tarjeta:
	defb 001h,002h,000h,000h	; 5082

; ----------------------------------------------------------------------
; DATOS canto_abierta: El canto con el bit 4: 61 61 / 03 04 (blanco y las dos
;   rayas)
;   0x5086..0x508a  (4 bytes)
DATA_canto_abierta:
	defb 061h,061h,003h,004h	; 5086

; ----------------------------------------------------------------------
; DATOS punteros_a_cifras: Diez punteros a los bloques de 0x5040, uno por
;   cifra
;   0x508a..0x509e  (20 bytes)
DATA_punteros_a_cifras:
	defw 05040h	; 508a  -> DATA_tarjetas_con_cifra
	defw 05046h	; 508c
	defw 0504ch	; 508e
	defw 05052h	; 5090
	defw 05058h	; 5092
	defw 0505eh	; 5094
	defw 05064h	; 5096
	defw 0506ah	; 5098
	defw 05070h	; 509a
	defw 05076h	; 509c

; ----------------------------------------------------------------------
; DATOS punteros_a_tarjetas: Ocho punteros a las posiciones de las tarjetas de
;   cada fase ((fase - 1) & 7)
;   0x509e..0x50ae  (16 bytes)
DATA_punteros_a_tarjetas:
	defw 050aeh	; 509e  -> DATA_posiciones_de_tarjetas
	defw 050c3h	; 50a0
	defw 050d8h	; 50a2
	defw 050edh	; 50a4
	defw 05102h	; 50a6
	defw 05117h	; 50a8
	defw 0512ch	; 50aa
	defw 05141h	; 50ac

; ----------------------------------------------------------------------
; DATOS posiciones_de_tarjetas: Ocho fases x 21 bytes: diez pares (Y, X) en
;   pixels y 0xFF; las tarjetas cuelgan en Y = 0x18, 0x50 y 0x88 (las filas 3,
;   10 y 17, bajo cada plataforma)
;   0x50ae..0x5156  (168 bytes)
DATA_posiciones_de_tarjetas:
	defb 018h,028h,018h,048h,018h,0a8h,050h,008h,050h,030h,050h,048h,088h,010h,088h,078h,088h,0b0h,088h,040h,0ffh	; 50ae  .(.H..P.P0PH...x...@.
	defb 018h,010h,018h,028h,018h,060h,018h,090h,018h,0a8h,050h,030h,050h,068h,050h,0a8h,088h,030h,088h,058h,0ffh	; 50c3  ...(.`....P0PhP..0.X.
	defb 018h,020h,018h,058h,018h,080h,050h,010h,050h,028h,050h,0b0h,088h,020h,088h,060h,088h,0b8h,018h,098h,0ffh	; 50d8  . .X..P.P(P.. .`.....
	defb 018h,038h,018h,090h,018h,0a8h,050h,010h,050h,068h,050h,0a8h,088h,010h,088h,078h,088h,098h,018h,050h,0ffh	; 50ed  .8....P.PhP....x...P.
	defb 018h,008h,018h,060h,018h,0a8h,050h,028h,050h,070h,050h,0b8h,088h,028h,088h,088h,088h,0b0h,088h,010h,0ffh	; 5102  ...`..P(PpP..(.......
	defb 018h,010h,018h,070h,018h,090h,050h,020h,050h,090h,050h,0a8h,088h,010h,088h,030h,088h,098h,018h,038h,0ffh	; 5117  ...p..P P.P....0...8.
	defb 018h,010h,018h,038h,018h,050h,018h,090h,050h,008h,050h,0b8h,088h,010h,088h,040h,088h,080h,018h,0a8h,0ffh	; 512c  ...8.P..P.P....@.....
	defb 018h,030h,018h,048h,018h,078h,018h,0a0h,050h,010h,050h,0a0h,088h,048h,088h,078h,088h,0b8h,088h,010h,0ffh	; 5141  .0.H.x..P.P..H.x.....

; ----------------------------------------------------------------------
; DATOS patrones_rle: Los patrones de los tiles 0x00-0xB7 comprimidos (0x515
;   bytes; 1472 al descomprimir con 0x6C84): n<0x80 repite n veces el byte
;   siguiente, n>=0x80 copia n&0x7F bytes, 0 fin. Van a los tres tercios
;   0x5156..0x566b  (1301 bytes)
DATA_patrones_rle:
	defb 008h,000h,004h,0ffh,084h,0c0h,0e0h,07fh,03fh,004h,0ffh,084h,003h,007h,0feh,0fch	; 5156  ........?.......
	defb 084h,0c0h,0e0h,07fh,03fh,004h,000h,084h,003h,007h,0feh,0fch,004h,000h,020h,0ffh	; 5166  ....?......... .
	defb 086h,001h,003h,007h,00fh,01fh,03fh,004h,007h,08ch,00fh,00fh,01fh,01fh,018h,010h	; 5176  ......?.........
	defb 000h,080h,0c0h,0e0h,0f0h,0f8h,004h,0c0h,0ceh,0e0h,0e0h,0f0h,0f0h,030h,010h,001h	; 5186  .............0..
	defb 007h,01fh,03bh,020h,060h,0c6h,0c6h,0c0h,0e0h,071h,034h,032h,031h,01ch,007h,080h	; 5196  ..; `....q421...
	defb 0e0h,0f8h,0dch,084h,006h,063h,063h,003h,007h,08eh,02ch,04ch,08ch,038h,0e0h,000h	; 51a6  .....cc...,L.8..
	defb 060h,070h,038h,01ch,00eh,007h,003h,003h,007h,00eh,01ch,038h,070h,060h,000h,000h	; 51b6  `p8........8p`..
	defb 006h,00eh,01ch,038h,070h,0e0h,0c0h,0c0h,0e0h,070h,038h,01ch,00eh,006h,000h,03ch	; 51c6  ...8p....p8....<
	defb 0e7h,0e7h,07eh,03ch,010h,0d6h,07ch,00eh,000h,082h,007h,00fh,006h,000h,082h,0f8h	; 51d6  ..~<..|.........
	defb 0f0h,004h,03eh,004h,03fh,090h,01fh,03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h	; 51e6  ..>.?..?........
	defb 080h,000h,000h,000h,03eh,03eh,005h,000h,083h,01fh,07fh,0fbh,005h,000h,083h,00fh	; 51f6  ....>>..........
	defb 0cfh,0efh,005h,000h,083h,078h,0fch,0bch,005h,000h,083h,03fh,07fh,0f3h,005h,000h	; 5206  .....x.....?....
	defb 083h,087h,0c7h,0c7h,005h,000h,083h,0bch,0feh,0dfh,005h,000h,08dh,078h,0fch,0bch	; 5216  .............x..
	defb 060h,0f0h,0f0h,060h,000h,0f0h,0f0h,0f0h,03fh,03fh,006h,03eh,090h,0f8h,0fch,0feh	; 5226  `..`....??.>....
	defb 07fh,03fh,01fh,00fh,007h,03eh,03eh,03eh,07eh,0fch,0fch,0f8h,0e0h,005h,0f1h,083h	; 5236  .?...>>>~.......
	defb 0fbh,07fh,01fh,006h,0efh,082h,0cfh,00fh,008h,01eh,088h,0e1h,003h,03fh,0f1h,0e1h	; 5246  .............?..
	defb 0f3h,07fh,01eh,008h,0e7h,008h,08fh,008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h	; 5256  ................
	defb 0f1h,0e0h,010h,0c8h,068h,0c8h,028h,010h,0e0h,08bh,000h,01ch,022h,063h,063h,063h	; 5266  ....h.(....."ccc
	defb 022h,01ch,000h,018h,038h,004h,018h,0edh,07eh,000h,03eh,063h,003h,00eh,03ch,070h	; 5276  "...8...~.>c..<p
	defb 07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh,000h,00eh,01eh,036h,066h,066h,07fh	; 5286  ..>c...c>...6ff.
	defb 006h,000h,07fh,060h,07eh,063h,003h,063h,03eh,000h,03eh,063h,060h,07eh,063h,063h	; 5296  ...`~c.c>.>c`~cc
	defb 03eh,000h,07fh,063h,006h,00ch,018h,018h,018h,000h,03eh,063h,063h,03eh,063h,063h	; 52a6  >..c......>cc>cc
	defb 03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh,01eh,021h,04ch,050h,050h,04ch,021h	; 52b6  >.>cc?.c>.!LPPL!
	defb 01eh,001h,033h,0b7h,0beh,0bch,0bch,03fh,037h,0c0h,080h,000h,01fh,0dbh,0dbh,0dbh	; 52c6  ..3....?7.......
	defb 09fh,000h,000h,000h,079h,06ch,06dh,06dh,06dh,000h,000h,000h,0e7h,036h,0f6h,0b6h	; 52d6  ....ylmmm....6..
	defb 0f6h,000h,000h,003h,0f0h,004h,0dbh,004h,000h,081h,07eh,004h,000h,0c1h,01ch,036h	; 52e6  ..........~....6
	defb 063h,063h,07fh,063h,063h,000h,07eh,063h,063h,07eh,063h,063h,07eh,000h,03eh,063h	; 52f6  cc.cc.~cc~cc~.>c
	defb 060h,060h,060h,063h,03eh,000h,03ch,026h,023h,023h,023h,026h,03ch,000h,03fh,030h	; 5306  ```c>.<&###&<.?0
	defb 030h,03eh,030h,030h,03fh,000h,07fh,060h,060h,07eh,060h,060h,060h,000h,03eh,063h	; 5316  0>00?..``~```.>c
	defb 060h,067h,063h,063h,03fh,000h,063h,063h,063h,07fh,063h,063h,063h,000h,03ch,005h	; 5326  `gcc?.ccc.ccc.<.
	defb 018h,083h,03ch,000h,01fh,004h,006h,08bh,066h,03ch,000h,063h,066h,06ch,078h,07ch	; 5336  ..<.....f<.cflx|
	defb 06eh,067h,000h,006h,060h,093h,07fh,000h,063h,077h,07fh,07fh,06bh,063h,063h,000h	; 5346  ng..`...cw..kcc.
	defb 063h,073h,07bh,07fh,06fh,067h,063h,000h,03eh,005h,063h,0a3h,03eh,000h,07eh,063h	; 5356  cs{.ogc.>.c.>.~c
	defb 063h,063h,07eh,060h,060h,000h,03eh,063h,063h,063h,06fh,066h,03dh,000h,07eh,063h	; 5366  cc~``.>cccof=.~c
	defb 063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh,000h,07eh,006h	; 5376  cb|fc.>c`>.c>.~.
	defb 018h,081h,000h,006h,063h,082h,03eh,000h,004h,063h,0a7h,036h,01ch,008h,000h,063h	; 5386  ....c.>..c.6...c
	defb 063h,06bh,06bh,07fh,077h,022h,000h,063h,076h,03ch,01ch,01eh,037h,063h,000h,066h	; 5396  ckk.w".cv<..7c.f
	defb 066h,07eh,03ch,018h,018h,018h,000h,07fh,007h,00eh,01ch,038h,070h,07fh,000h,024h	; 53a6  f~<........8p..$
	defb 024h,024h,006h,000h,08eh,040h,049h,05ah,073h,052h,059h,000h,000h,000h,092h,052h	; 53b6  $$...@IZsRY....R
	defb 0ceh,002h,0dch,090h,000h,000h,002h,000h,08ah,0aah,0aah,0dah,000h,000h,008h,048h	; 53c6  ...............H
	defb 0eeh,04ah,04ah,06ah,008h,000h,008h,0ffh,08ch,000h,018h,018h,000h,000h,018h,018h	; 53d6  .JJj............
	defb 000h,0ffh,0ffh,0f8h,0f0h,004h,0f3h,084h,0ffh,0ffh,01fh,00fh,008h,0cfh,084h,00fh	; 53e6  ................
	defb 01fh,0ffh,0ffh,004h,0f3h,082h,0f0h,0f8h,005h,0ffh,082h,0feh,0fch,005h,0ffh,00ch	; 53f6  ................
	defb 03fh,004h,0ffh,083h,0f8h,0f0h,0f3h,005h,0ffh,094h,01fh,00fh,0cfh,0cfh,0cfh,00fh	; 5406  ?...............
	defb 0fch,0f8h,0f1h,0f3h,0f0h,0f0h,0ffh,0ffh,03fh,0ffh,0ffh,0ffh,00fh,00fh,005h,0ffh	; 5416  ........?.......
	defb 08bh,0f3h,0f0h,0f8h,0ffh,0ffh,00fh,0cfh,0cfh,0cfh,00fh,01fh,005h,0ffh,088h,0feh	; 5426  ................
	defb 0fch,0f8h,0f1h,0e3h,0c7h,0c0h,0c0h,005h,0ffh,086h,03fh,007h,007h,03fh,03fh,03fh	; 5436  ..........?..???
	defb 004h,0ffh,09ch,0f8h,0f0h,0f3h,0f3h,0f3h,0f0h,0ffh,0ffh,01fh,01fh,0ffh,0ffh,0ffh	; 5446  ................
	defb 01fh,0f8h,0ffh,0ffh,0f3h,0f0h,0f8h,0ffh,0ffh,0f0h,0f3h,0f3h,0f3h,0f0h,0f8h,004h	; 5456  ................
	defb 0ffh,082h,0f0h,0f0h,006h,0ffh,087h,00fh,00fh,0cfh,0cfh,08fh,09fh,0ffh,005h,0feh	; 5466  ................
	defb 084h,0ffh,0ffh,01fh,03fh,004h,07fh,0f2h,0ffh,0ffh,007h,01fh,038h,070h,073h,0f3h	; 5476  ....?.......8ps.
	defb 0f3h,0f3h,0e0h,0f8h,01ch,00eh,0ceh,0cfh,0cfh,0cfh,0f3h,0f3h,0f3h,073h,070h,038h	; 5486  .............sp8
	defb 01fh,007h,0cfh,0cfh,0cfh,0ceh,00eh,01ch,0f8h,0e0h,007h,01fh,03eh,07ch,07fh,0ffh	; 5496  ............>|..
	defb 0ffh,0ffh,0e0h,0f8h,03ch,03eh,03eh,03fh,03fh,03fh,0ffh,0ffh,0ffh,07fh,07fh,03fh	; 54a6  ....<>>???.....?
	defb 01fh,007h,03fh,03fh,03fh,03eh,03eh,03ch,0f8h,0e0h,007h,01fh,038h,070h,073h,0ffh	; 54b6  ..???>><....8ps.
	defb 0ffh,0ffh,0e0h,0f8h,01ch,00eh,0ceh,0cfh,0cfh,00fh,0fch,0f8h,0f1h,073h,070h,030h	; 54c6  .............sp0
	defb 01fh,007h,03fh,0ffh,0ffh,0feh,00eh,00ch,0f8h,0e0h,0ffh,0ffh,0ffh,073h,070h,038h	; 54d6  ..?..........sp8
	defb 01fh,007h,00fh,0cfh,0cfh,0ceh,00eh,01ch,0f8h,0e0h,0f8h,007h,01fh,03fh,07eh,07ch	; 54e6  .............?~|
	defb 0f8h,0f1h,0e3h,0c7h,0c0h,0c0h,07fh,07fh,03fh,01fh,007h,03fh,007h,007h,03eh,03eh	; 54f6  ........?..?..>>
	defb 03ch,0f8h,0e0h,007h,01fh,038h,070h,073h,0f3h,0f3h,0f0h,0e0h,0f8h,01ch,01eh,0feh	; 5506  <....8ps........
	defb 0ffh,0ffh,01fh,0f8h,0ffh,0ffh,073h,070h,038h,01fh,007h,0f0h,0f3h,0f3h,073h,070h	; 5516  ......sp8.....sp
	defb 030h,01fh,007h,007h,01fh,030h,070h,07fh,0ffh,0ffh,0ffh,0e0h,0f8h,00ch,00eh,0ceh	; 5526  0....0p.........
	defb 0cfh,08fh,09fh,0ffh,0feh,0feh,07eh,07eh,03eh,01fh,007h,01fh,03fh,07fh,07eh,07eh	; 5536  ......~~>...?.~~
	defb 07ch,0f8h,0e0h,007h,01fh,03eh,07eh,07eh,0feh,0feh,0e0h,0e0h,0f8h,07ch,07eh,07eh	; 5546  |....>~~.....|~~
	defb 07fh,07fh,007h,0e0h,0feh,0feh,07eh,07eh,03eh,01fh,007h,007h,07fh,07fh,07eh,07eh	; 5556  ......~~>.....~~
	defb 07ch,0f8h,0e0h,0f8h,007h,01fh,03fh,07fh,07fh,0ffh,0ffh,0e0h,0e0h,0f8h,0fch,0feh	; 5566  |.....?.........
	defb 0feh,0ffh,0ffh,007h,0e0h,0ffh,0ffh,07fh,07fh,03fh,01fh,007h,007h,0ffh,0ffh,0feh	; 5576  .........?......
	defb 0feh,0fch,0f8h,0e0h,007h,01fh,03fh,07fh,067h,0f3h,0f9h,0fch,0e0h,0f8h,0fch,0feh	; 5586  ......?.g.......
	defb 0e6h,0cfh,09fh,03fh,0feh,0fch,0f9h,073h,067h,03fh,01fh,007h,07fh,03fh,09fh,0ceh	; 5596  ...?...sg?...?..
	defb 0e6h,0fch,0f8h,0e0h,007h,01fh,03fh,07eh,07eh,0ffh,0ffh,0c0h,0e0h,0f8h,0fch,07eh	; 55a6  ......?~~......~
	defb 07eh,0ffh,0ffh,003h,0c0h,0ffh,0ffh,07eh,07eh,03fh,01fh,007h,003h,0ffh,0ffh,07eh	; 55b6  ~......~~?.....~
	defb 07eh,0fch,0f8h,0e0h,007h,01fh,03fh,07fh,07fh,0e0h,0e0h,0ffh,0e0h,0f8h,0fch,0feh	; 55c6  ~.....?.........
	defb 0feh,007h,007h,0ffh,0ffh,0e0h,0e0h,07fh,07fh,03fh,01fh,007h,096h,0ffh,007h,007h	; 55d6  .........?......
	defb 0feh,0feh,0fch,0f8h,0e0h,007h,01fh,03fh,07eh,07eh,0feh,0ffh,0ffh,0e0h,0f8h,0fch	; 55e6  .......?~~......
	defb 07eh,07eh,07fh,004h,0ffh,0eeh,0feh,07eh,07eh,03fh,01fh,007h,0ffh,0ffh,07fh,07eh	; 55f6  ~~.....~~?.....~
	defb 07eh,0fch,0f8h,0e0h,007h,01fh,03fh,07eh,07ch,0fdh,0fdh,0fdh,0e0h,0f8h,03ch,07eh	; 5606  ~.....?~|.....<~
	defb 0feh,0ffh,0ffh,0ffh,0fdh,0fdh,0fdh,07ch,07eh,03fh,01fh,007h,0ffh,0ffh,0ffh,0feh	; 5616  .......|~?......
	defb 07eh,03ch,0f8h,0e0h,007h,01fh,03ch,07eh,07fh,0ffh,0ffh,0ffh,0e0h,0f8h,0fch,07eh	; 5626  ~<....<~.......~
	defb 03eh,0bfh,0bfh,0bfh,0ffh,0ffh,0ffh,07fh,07eh,03ch,01fh,007h,0bfh,0bfh,0bfh,03eh	; 5636  >.......~<.....>
	defb 07eh,0fch,0f8h,0e0h,007h,018h,030h,073h,073h,0ffh,0ffh,0ffh,0e0h,018h,00ch,0ceh	; 5646  ~.....0ss.......
	defb 0ceh,0cfh,09fh,03fh,0feh,0feh,0ffh,07fh,07eh,03eh,01eh,007h,07fh,07fh,0ffh,0feh	; 5656  ...?....~>......
	defb 07eh,07ch,078h,0e0h,000h	; 5666

; ----------------------------------------------------------------------
; DATOS colores_rle: Los colores de los mismos tiles, en el mismo formato (84
;   bytes; 1472 al descomprimir)
;   0x566b..0x56bf  (84 bytes)
DATA_colores_rle:
	defb 008h,000h,004h,0f0h,004h,090h,004h,0f0h,004h,090h,010h,090h,0a0h,000h,080h,090h	; 566b  ................
	defb 0f0h,060h,080h,090h,0f0h,000h,020h,030h,0f0h,0c0h,020h,030h,0f0h,000h,040h,070h	; 567b  .`.... 0.. 0..@p
	defb 0f0h,050h,040h,070h,0f0h,000h,0a0h,0b0h,0f0h,0a0h,0a0h,0b0h,0f0h,020h,090h,020h	; 568b  .P@p......... . 
	defb 014h,020h,094h,085h,0f0h,0f8h,0f8h,0f0h,0f0h,003h,0c0h,078h,0f0h,078h,0f0h,078h	; 569b  . .........x.x.x
	defb 0f0h,078h,0f0h,070h,0f0h,078h,0f4h,060h,0f4h,078h,0b0h,078h,0b0h,078h,0b0h,078h	; 56ab  .x.p.x.`.x.x.x.x
	defb 0b0h,008h,0b0h,000h	; 56bb

; ----------------------------------------------------------------------
; DATOS sprites_espejables: Los 22 sprites de 16x16 (32 bytes: columna
;   izquierda y derecha) que INIT copia a 0x1800 (los 6 primeros), a 0x18C0
;   (los 22: patrones 0x18-0x6C) y espeja en 0x1CC0 (0x98-0xEC), todos mirando
;   a la derecha: 0-2 el mono andando y 3-5 sus detalles blancos, 6-8 el
;   cangrejo y 9-11 sus ojos, 12-13 el mono trepando y 14-15 sus detalles,
;   16-17 la cara de susto, 18-19 el mono tirando la fruta, 20-21 el cangrejo
;   tirandola
;   0x56bf..0x597f  (704 bytes)
DATA_sprites_espejables:
	defb 003h,00eh,03ch,07ch,04ch,074h,066h,03fh,01dh,00bh,00ah,04ah,03dh,00fh,018h,000h,0c0h,000h,040h,000h,000h,000h,000h,080h,0e0h,070h,0f0h,0f0h,0e0h,0c0h,0c0h,000h	; 56bf  ..<|Ltf?...J=.....@......p......
	defb 007h,01ch,078h,0f8h,098h,0e8h,0cch,07fh,07fh,0ffh,04fh,00fh,01fh,00eh,000h,000h,080h,000h,080h,000h,000h,000h,004h,01ch,0f8h,0f0h,0f0h,0f8h,0fch,01ch,000h,000h	; 56df  ..x.......O.....................
	defb 000h,007h,01ch,078h,0f8h,098h,0e8h,0cch,07fh,01fh,07fh,0ffh,01fh,01fh,000h,000h,000h,080h,000h,080h,000h,000h,000h,000h,000h,0e0h,0fch,0fch,0c0h,0e0h,0f0h,000h	; 56ff  ...x............................
	defb 000h,001h,003h,003h,033h,00bh,019h,000h,000h,000h,000h,000h,000h,000h,000h,01eh,000h,0a0h,0a0h,0f8h,0fch,0fch,0fch,078h,000h,000h,000h,000h,000h,000h,000h,0f0h	; 571f  ....3..................x........
	defb 000h,003h,007h,007h,067h,017h,033h,000h,000h,000h,080h,080h,000h,010h,010h,018h,000h,040h,040h,0f0h,0f8h,0f8h,0f8h,0e2h,000h,000h,002h,002h,002h,002h,000h,000h	; 573f  ....g.3..........@@.............
	defb 000h,000h,003h,007h,007h,067h,017h,033h,000h,000h,000h,000h,080h,020h,020h,030h,000h,000h,040h,040h,0f0h,0f8h,0f8h,0f8h,0f0h,000h,002h,000h,000h,008h,008h,010h	; 575f  .....g.3.....  0..@@............
	defb 01eh,038h,03ch,038h,030h,030h,014h,012h,00bh,067h,09fh,06dh,09eh,06eh,097h,020h,078h,01ch,03ch,01ch,00ch,00ch,028h,048h,0d0h,0e6h,0f9h,0b6h,079h,0f6h,0e8h,004h	; 577f  .8<800...g.m.n. x.<...(H....y...
	defb 000h,000h,070h,0e0h,0f0h,0e0h,0c0h,060h,024h,017h,00fh,0bfh,05ch,0bbh,05fh,0afh,000h,01ch,00eh,01fh,00fh,007h,006h,00ch,090h,0a0h,0ceh,0f1h,0eeh,071h,0eeh,0d1h	; 579f  ..p....`$...\._..............q..
	defb 000h,038h,070h,0f8h,0f0h,0e0h,060h,030h,009h,005h,073h,08fh,074h,08eh,077h,08bh,000h,000h,00eh,007h,00fh,007h,003h,006h,024h,0e8h,0f0h,03dh,00ah,01dh,0fah,0f5h	; 57bf  .8p...`0..s.t.w.........$..=....
	defb 000h,000h,000h,000h,006h,006h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,060h,060h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 57df  ....................``..........
	defb 000h,000h,000h,000h,000h,000h,00ch,00ch,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h	; 57ff  ................................
	defb 000h,000h,000h,000h,000h,000h,003h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,030h,030h,000h,000h,000h,000h,000h,000h,000h,000h	; 581f  ......................00........
	defb 00eh,03ch,07dh,0cdh,0ebh,0dbh,077h,037h,09fh,07fh,03fh,07fh,07fh,070h,000h,000h,080h,000h,080h,000h,000h,000h,080h,000h,0c0h,080h,000h,000h,000h,000h,000h,000h	; 583f  .<}...w7..?..p..................
	defb 001h,001h,000h,030h,010h,020h,000h,000h,000h,000h,000h,000h,080h,080h,080h,080h,000h,040h,040h,0f0h,0f8h,0f8h,0f8h,070h,000h,000h,000h,000h,000h,000h,000h,000h	; 585f  ...0. ...........@@....p........
	defb 00fh,03ch,078h,078h,0d8h,0ech,0ech,07fh,01fh,01eh,00eh,007h,07eh,03eh,000h,000h,080h,040h,0b8h,000h,000h,000h,000h,000h,0c0h,000h,000h,000h,000h,000h,000h,000h	; 587f  .<xx........~>...@..............
	defb 000h,003h,007h,007h,027h,013h,013h,000h,000h,000h,000h,000h,001h,040h,040h,0c0h,008h,048h,040h,0f0h,0f8h,0f8h,0f8h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; 589f  ....'........@@..H@.............
	defb 000h,03fh,060h,0c0h,0c0h,0c0h,0e0h,030h,01ch,0ffh,0ffh,05fh,00fh,03fh,046h,003h,000h,000h,000h,000h,000h,000h,000h,010h,070h,0e0h,0f0h,0f8h,0f8h,0bch,01ch,00ch	; 58bf  .?`....0..._.?F.........p.......
	defb 000h,000h,01fh,039h,03dh,03fh,01fh,04fh,0c3h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,000h,060h,0e0h,048h,048h,080h,000h,000h,002h,002h,042h,0c2h,080h	; 58df  ...9=?.O............`.HH.....B..
	defb 003h,00eh,03ch,07ch,04ch,074h,076h,03fh,01fh,04fh,04fh,02fh,01fh,03fh,020h,000h,0c0h,010h,058h,038h,070h,0e0h,0e0h,0c0h,0e0h,0f0h,0f0h,0f0h,0e0h,0c0h,0c0h,000h	; 58ff  ..<|Ltv?.OO/.? ...X8p...........
	defb 000h,001h,003h,003h,033h,00bh,018h,000h,000h,000h,000h,000h,000h,000h,040h,030h,008h,0a8h,0a0h,0c0h,08ch,01ch,01ch,038h,000h,000h,000h,000h,000h,000h,000h,0f0h	; 591f  ....3.........@0.......8........
	defb 000h,038h,060h,078h,070h,060h,030h,012h,00bh,067h,09eh,06ch,09eh,06eh,097h,020h,0e0h,030h,078h,0f8h,018h,008h,008h,048h,0d0h,0e6h,079h,036h,079h,076h,0e9h,004h	; 593f  .8`xp`0..g.l.n. .0x....H..y6yv..
	defb 000h,000h,000h,000h,000h,006h,006h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,060h,060h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 595f  .....................``.........

; ----------------------------------------------------------------------
; DATOS sprites_500_y_frutas: Cuatro sprites que van a 0x1B80 (patrones
;   0x70-0x7C): el "500", el "100", el platano y las uvas. 0x1B80 se pisa con
;   los globos (0x5E3F) y se restaura desde aqui
;   0x597f..0x59ff  (128 bytes)
DATA_sprites_500_y_frutas:
	defb 000h,0f9h,0fbh,0fbh,0c3h,0c3h,0c3h,0c3h,0fbh,0fbh,01bh,01bh,01bh,01bh,0fbh,0f9h,000h,08ch,0deh,05ah,05ah,05ah,05ah,05ah,05ah,05ah,05ah,05ah,05ah,05ah,0deh,08ch	; 597f  ...................ZZZZZZZZZZZ..
	defb 0e0h,0f0h,0f0h,0f8h,079h,039h,039h,039h,039h,039h,039h,079h,0f9h,0f0h,0f0h,0e0h,07ch,0feh,0feh,0ffh,0efh,0ceh,0ceh,0ceh,0ceh,0ceh,0ceh,0efh,0ffh,0feh,0feh,07ch	; 599f  ....y999999y....|..............|
	defb 000h,000h,000h,000h,000h,000h,000h,000h,001h,003h,00fh,0fch,0fbh,077h,02fh,007h,000h,07ch,010h,018h,018h,02ch,06ch,0ech,0dch,0bch,07ch,0f8h,0f8h,0f0h,0e0h,080h	; 59bf  .............w/..|...,l...|.....
	defb 000h,001h,000h,000h,00dh,00dh,036h,036h,01bh,01bh,00dh,00dh,006h,006h,003h,003h,000h,0c0h,080h,080h,0b0h,0b0h,0d8h,0d8h,060h,060h,0b0h,0b0h,0c0h,0c0h,000h,000h	; 59df  ......66................``......

; ----------------------------------------------------------------------
; DATOS sprites_mono_izquierda: Seis sprites que van a 0x1C00 (patrones
;   0x80-0x94): el mono andando hacia la izquierda (tres fases y sus
;   detalles), dibujado aparte en vez de espejado
;   0x59ff..0x5abf  (192 bytes)
DATA_sprites_mono_izquierda:
	defb 003h,000h,002h,000h,000h,000h,000h,001h,007h,00eh,00fh,00fh,007h,003h,003h,000h,0c0h,070h,03ch,03eh,032h,02eh,066h,0fch,0b8h,0d0h,050h,052h,0bch,0f0h,018h,000h	; 59ff  .................p<>2.f...PR....
	defb 001h,000h,001h,000h,000h,000h,020h,038h,01fh,00fh,00fh,01fh,03fh,038h,000h,000h,0e0h,038h,01eh,01fh,019h,017h,033h,0feh,0feh,0ffh,0f2h,0f0h,0f8h,070h,000h,000h	; 5a1f  ...... 8....?8...8....3......p..
	defb 000h,001h,000h,001h,000h,000h,000h,000h,000h,007h,03fh,03fh,003h,007h,00fh,000h,000h,070h,038h,01eh,01fh,019h,017h,033h,0feh,0f8h,0feh,0ffh,0f8h,0f8h,000h,000h	; 5a3f  ..........??.....p8....3........
	defb 000h,005h,005h,01fh,03fh,03fh,03fh,01eh,000h,000h,000h,000h,000h,000h,000h,00fh,000h,080h,0c0h,0c0h,0cch,0d0h,098h,000h,000h,000h,000h,000h,000h,000h,000h,078h	; 5a5f  ....???........................x
	defb 000h,002h,002h,00fh,01fh,01fh,01fh,047h,000h,000h,040h,040h,040h,040h,000h,000h,000h,0c0h,0e0h,0e0h,0e6h,0e8h,0cch,000h,000h,000h,001h,001h,000h,008h,008h,018h	; 5a7f  .......G..@@@@..................
	defb 000h,000h,002h,002h,00fh,01fh,01fh,01fh,00fh,000h,040h,000h,000h,010h,010h,008h,000h,000h,0c0h,0e0h,0e0h,0e6h,0e8h,0cch,000h,000h,000h,000h,001h,004h,004h,00ch	; 5a9f  ..........@.....................

; ----------------------------------------------------------------------
; DATOS sprites_cara_manzana_tarjeta: Cuatro sprites que van a 0x1F80
;   (patrones 0xF0-0xFC): la cara grande del mono de frente y sus detalles
;   (0xF0/0xF4: el profesor cuando le llevan la respuesta), la manzana (0xF8)
;   y la tarjeta de la respuesta vista de canto (0xFC)
;   0x5abf..0x5b3f  (128 bytes)
DATA_sprites_cara_manzana_tarjeta:
	defb 000h,000h,007h,00fh,019h,010h,038h,028h,018h,034h,034h,038h,058h,068h,030h,000h,000h,000h,0e0h,0f0h,098h,008h,01ch,014h,018h,02ch,02ch,01ch,01ah,016h,00ch,000h	; 5abf  ......8(.448Xh0..........,,.....
	defb 000h,000h,000h,000h,006h,00fh,005h,015h,007h,003h,002h,003h,001h,004h,004h,070h,000h,000h,000h,000h,060h,0f0h,0a0h,0a8h,0e0h,0c0h,040h,0c0h,080h,020h,020h,00eh	; 5adf  ...............p....`.....@..  .
	defb 000h,000h,000h,000h,001h,001h,00fh,01fh,03bh,037h,037h,037h,03bh,03fh,01fh,00fh,000h,000h,040h,080h,080h,000h,0e0h,0f0h,0f8h,0f8h,0f8h,0f8h,0f8h,0f8h,0f0h,0e0h	; 5aff  ........;777;?....@.............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,07fh,07fh,07fh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0feh,0feh,0feh,000h,000h,000h	; 5b1f  ................................

; ----------------------------------------------------------------------
; DATOS sprites_mono_con_fruta: Juego 1 del mono (E10E = 1): seis sprites que
;   0x5F5F carga en 0x1800 cuando lleva una fruta en la cabeza (los brazos
;   arriba), tres fases y sus detalles
;   0x5b3f..0x5bff  (192 bytes)
DATA_sprites_mono_con_fruta:
	defb 003h,01eh,03ch,07ch,05ch,07eh,06eh,03fh,01fh,00fh,00fh,04fh,03fh,00fh,018h,000h,0c0h,000h,040h,000h,000h,000h,000h,080h,0e0h,0f0h,0f0h,0f0h,0e0h,0c0h,0c0h,000h	; 5b3f  ..<|\~n?...O?.....@.............
	defb 003h,01eh,03ch,07ch,05ch,07eh,06eh,03fh,01fh,00fh,0cfh,06fh,01fh,00eh,000h,000h,0c0h,000h,040h,000h,000h,000h,000h,080h,0e0h,0f0h,0f0h,0f8h,0fch,01ch,000h,000h	; 5b5f  ..<|\~n?...o......@.............
	defb 003h,01eh,03ch,07ch,05ch,07eh,06eh,03fh,01fh,00fh,0cfh,07fh,00fh,00fh,000h,000h,0c0h,000h,040h,000h,000h,000h,000h,080h,0e0h,0f0h,0f0h,0f0h,0e0h,0f0h,078h,000h	; 5b7f  ..<|\~n?..........@...........x.
	defb 070h,001h,003h,003h,023h,001h,011h,000h,000h,000h,000h,000h,000h,000h,000h,01eh,000h,0a0h,0a0h,0f8h,0fch,0fch,0fch,078h,000h,000h,000h,000h,000h,000h,000h,0f0h	; 5b9f  p...#..................x........
	defb 070h,001h,003h,003h,023h,001h,011h,000h,000h,000h,000h,000h,000h,010h,010h,018h,000h,0a0h,0a0h,0f8h,0fch,0fch,0fch,078h,000h,000h,002h,002h,002h,002h,000h,000h	; 5bbf  p...#..................x........
	defb 070h,001h,003h,003h,023h,001h,011h,000h,000h,000h,000h,000h,000h,010h,010h,018h,000h,0a0h,0a0h,0f8h,0fch,0fch,0fch,078h,000h,000h,000h,000h,004h,004h,004h,008h	; 5bdf  p...#..................x........

; ----------------------------------------------------------------------
; DATOS sprites_mono_con_tarjeta: Juego 2 del mono (E10E = 2): con la tarjeta
;   de la respuesta en alto, para 0x1800
;   0x5bff..0x5cbf  (192 bytes)
DATA_sprites_mono_con_tarjeta:
	defb 003h,00eh,03ch,07ch,04ch,074h,066h,03fh,01dh,00fh,007h,007h,006h,00fh,018h,000h,0c0h,000h,040h,000h,000h,000h,000h,080h,0e0h,070h,000h,000h,000h,0c0h,0c0h,000h	; 5bff  ..<|Ltf?..........@......p......
	defb 007h,01ch,078h,0f8h,098h,0e8h,0cch,07fh,01fh,03fh,038h,018h,01ch,00fh,000h,000h,080h,000h,080h,000h,000h,000h,000h,000h,0c0h,0e0h,000h,000h,000h,0f0h,03ch,000h	; 5c1f  ..x......?8...................<.
	defb 000h,003h,00eh,03ch,07ch,04ch,074h,066h,03fh,01fh,007h,003h,001h,00fh,000h,000h,000h,0c0h,000h,040h,000h,000h,000h,000h,080h,0f8h,080h,080h,0c0h,0f8h,07ch,000h	; 5c3f  ...<|Ltf?..........@..........|.
	defb 000h,001h,003h,003h,033h,00bh,019h,000h,000h,000h,000h,000h,000h,000h,000h,01eh,000h,0a0h,0a0h,0f8h,0fch,0fch,0fch,078h,000h,000h,000h,000h,000h,000h,000h,0f0h	; 5c5f  ....3..................x........
	defb 000h,003h,007h,007h,067h,017h,033h,000h,000h,000h,000h,000h,000h,010h,010h,018h,000h,040h,040h,0f0h,0f8h,0f8h,0f8h,0e0h,000h,000h,000h,000h,000h,002h,002h,004h	; 5c7f  ....g.3..........@@.............
	defb 000h,000h,001h,003h,003h,033h,00bh,019h,000h,000h,000h,000h,000h,010h,010h,018h,000h,000h,0a0h,0a0h,0f8h,0fch,0fch,0fch,070h,000h,000h,000h,000h,002h,002h,004h	; 5c9f  .....3..................p.......

; ----------------------------------------------------------------------
; DATOS sprites_mono_con_fruta_izquierda: Los seis del juego 1 mirando a la
;   izquierda, para 0x1C00
;   0x5cbf..0x5d7f  (192 bytes)
DATA_sprites_mono_con_fruta_izquierda:
	defb 003h,000h,002h,000h,000h,000h,000h,001h,007h,00fh,00fh,00fh,007h,003h,003h,000h,0c0h,078h,03ch,03eh,03ah,07eh,076h,0fch,0f8h,0f0h,0f0h,0f2h,0fch,0f0h,018h,000h	; 5cbf  .................x<>:~v.........
	defb 003h,000h,002h,000h,000h,000h,000h,001h,007h,00fh,00fh,01fh,03fh,038h,000h,000h,0c0h,078h,03ch,03eh,03ah,07eh,076h,0fch,0f8h,0f8h,0f3h,0f6h,0f8h,070h,000h,000h	; 5cdf  ............?8...x<>:~v......p..
	defb 003h,000h,002h,000h,000h,000h,000h,001h,007h,00fh,00fh,00fh,007h,00fh,01eh,000h,0c0h,078h,03ch,03eh,03ah,07eh,076h,0fch,0f8h,0f0h,0f3h,0feh,0f0h,0f0h,000h,000h	; 5cff  .................x<>:~v.........
	defb 000h,005h,005h,01fh,03fh,03fh,03fh,01eh,000h,000h,000h,000h,000h,000h,000h,00fh,00eh,080h,0c0h,0c0h,0c4h,080h,088h,000h,000h,000h,000h,000h,000h,000h,000h,078h	; 5d1f  ....???........................x
	defb 000h,005h,005h,01fh,03fh,03fh,03fh,01eh,000h,000h,040h,040h,040h,040h,000h,000h,00eh,080h,0c0h,0c0h,0c4h,080h,088h,000h,000h,000h,000h,000h,000h,008h,008h,018h	; 5d3f  ....???...@@@@..................
	defb 000h,005h,005h,01fh,03fh,03fh,03fh,01eh,000h,000h,000h,000h,000h,020h,020h,010h,00eh,080h,0c0h,0c0h,0c4h,080h,088h,000h,000h,000h,000h,000h,000h,008h,008h,018h	; 5d5f  ....???......  .................

; ----------------------------------------------------------------------
; DATOS sprites_mono_con_tarjeta_izquierda: Los seis del juego 2 mirando a la
;   izquierda, para 0x1C00
;   0x5d7f..0x5e3f  (192 bytes)
DATA_sprites_mono_con_tarjeta_izquierda:
	defb 003h,000h,002h,000h,000h,000h,000h,001h,007h,00fh,000h,000h,000h,003h,003h,000h,0c0h,070h,03ch,03eh,032h,02eh,066h,0fch,0f8h,0f0h,0e0h,0e0h,060h,0f0h,018h,000h	; 5d7f  .................p<>2.f.....`...
	defb 001h,000h,001h,000h,000h,000h,000h,000h,003h,007h,000h,000h,000h,01fh,03ch,000h,0e0h,038h,01eh,01fh,019h,017h,033h,0feh,0f8h,0fch,01ch,038h,038h,0f0h,000h,000h	; 5d9f  ..............<..8....3....88...
	defb 000h,003h,000h,002h,000h,000h,000h,000h,001h,007h,001h,001h,003h,00fh,01eh,000h,000h,0c0h,070h,03ch,03eh,032h,02eh,066h,0fch,0f8h,0e0h,0c0h,080h,0f0h,000h,000h	; 5dbf  ..................p<>2.f........
	defb 000h,005h,005h,01fh,03fh,03fh,03fh,01eh,000h,000h,000h,000h,000h,000h,000h,00fh,000h,080h,0c0h,0c0h,0cch,0d0h,098h,000h,000h,000h,000h,000h,000h,000h,000h,078h	; 5ddf  ....???........................x
	defb 000h,002h,002h,00fh,01fh,01fh,01fh,007h,000h,000h,000h,000h,000h,040h,040h,020h,000h,0c0h,0e0h,0e0h,0e6h,0e8h,0cch,000h,000h,000h,000h,000h,000h,008h,008h,018h	; 5dff  .............@@ ................
	defb 000h,000h,005h,005h,01fh,03fh,03fh,03fh,00eh,000h,000h,000h,000h,020h,020h,010h,000h,000h,080h,0c0h,0c0h,0cch,0d0h,098h,000h,000h,000h,000h,000h,008h,008h,018h	; 5e1f  .....???.....  .................

; ----------------------------------------------------------------------
; DATOS sprites_globo: Dos sprites (a 0x1B80, patrones 0x70 y 0x74): el globo
;   que sube con cada simbolo de la ecuacion, y el que lleva la respuesta al
;   profesor
;   0x5e3f..0x5e7f  (64 bytes)
DATA_sprites_globo:
	defb 003h,00fh,01fh,03bh,037h,077h,077h,07fh,07fh,077h,077h,03bh,03fh,01fh,01fh,00fh,0c0h,0f0h,0f8h,0fch,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0fch,0fch,0f8h,0f8h,0f0h	; 5e3f  ...;7ww..ww;?...................
	defb 007h,003h,001h,002h,002h,004h,004h,002h,002h,001h,001h,000h,000h,001h,001h,002h,0e0h,0c0h,080h,0c0h,0e0h,000h,000h,000h,000h,000h,000h,080h,080h,000h,000h,000h	; 5e5f  ................................

; ----------------------------------------------------------------------
; DATOS sprites_mono_contento: Cuatro sprites que 0x7532 carga en 0x1800
;   (patrones 0x00-0x0C) cuando la respuesta llega al profesor: la cara del
;   mono de frente en dos fases (0x00 y 0x08) con sus detalles (0x04 y 0x0C);
;   el mono y el profesor bailan con ellos (0x6DFC)
;   0x5e7f..0x5eff  (128 bytes)
DATA_sprites_mono_contento:
	defb 007h,00fh,019h,028h,028h,010h,008h,068h,03ch,03fh,01eh,00ch,00ch,01eh,01ch,000h,0e0h,0f0h,098h,014h,014h,008h,010h,016h,03ch,0fch,078h,030h,030h,078h,038h,000h	; 5e7f  ...((..h<?..............<.x00x8.
	defb 000h,000h,006h,017h,015h,08dh,0c7h,006h,003h,000h,001h,003h,003h,001h,000h,038h,000h,000h,060h,0e8h,0a8h,0b1h,0e3h,060h,0c0h,000h,080h,0c0h,0c0h,080h,000h,01ch	; 5e9f  ...............8..`....`........
	defb 000h,007h,00fh,019h,028h,028h,010h,008h,038h,07ch,07fh,06ch,00ch,01eh,01ch,000h,000h,0e0h,0f0h,098h,014h,014h,008h,010h,01ch,03eh,0feh,036h,030h,078h,038h,000h	; 5ebf  ....((..8|.l.............>.60x8.
	defb 000h,000h,000h,006h,017h,015h,00dh,007h,007h,003h,000h,003h,0c3h,001h,000h,038h,000h,000h,000h,060h,0e8h,0a8h,0b0h,0e0h,0e0h,0c0h,000h,0c0h,0c3h,080h,000h,01ch	; 5edf  ...............8...`............

; ----------------------------------------------------------------------
; DATOS tiles_de_la_ecuacion: Doce patrones de 8 bytes para los tiles
;   0xB8-0xC3 (0x4728 los carga en el menu): los trozos de las cifras grandes
;   de la ecuacion que no cabian en 0x5156 (0xC0/0xC1 aparecen en el 2, el 3,
;   el 8 y el signo de dividir)
;   0x5eff..0x5f5f  (96 bytes)
DATA_tiles_de_la_ecuacion:
	defb 0ffh,0ffh,0f8h,0f0h,0f3h,0ffh,0ffh,0fch	; 5eff  ........
	defb 0fch,0ffh,0ffh,0f3h,0f0h,0f8h,0ffh,0ffh	; 5f07  ........
	defb 0ffh,0ffh,01fh,00fh,0cfh,0cfh,0cfh,01fh	; 5f0f  ........
	defb 01fh,0cfh,0cfh,0cfh,00fh,01fh,0ffh,0ffh	; 5f17  ........
	defb 0ffh,0ffh,0f8h,0f0h,0f3h,0f3h,0f3h,0f8h	; 5f1f  ........
	defb 0f8h,0f3h,0f3h,0f3h,0f0h,0f8h,0ffh,0ffh	; 5f27  ........
	defb 007h,01fh,038h,070h,073h,0ffh,0ffh,0fch	; 5f2f  ..8ps...
	defb 0fch,0ffh,0ffh,073h,070h,038h,01fh,007h	; 5f37  ...sp8..
	defb 0e0h,0f8h,01ch,00eh,0ceh,0cfh,0cfh,01fh	; 5f3f  ........
	defb 01fh,0cfh,0cfh,0ceh,00eh,01ch,0f8h,0e0h	; 5f47  ........
	defb 007h,01fh,038h,070h,073h,0f3h,0f3h,0f8h	; 5f4f  ..8ps...
	defb 0f8h,0f3h,0f3h,073h,070h,038h,01fh,007h	; 5f57  ...sp8..

; ======================================================================
; CODIGO 0x5f5f..0x602e  (207 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ######################################################################
; UN PASO DE UN ACTOR. B = 1 el mono, 2-4 los cangrejos. IX apunta a
; sus dos sprites (E0B0 + 8(B-1)) y IX+0x58.. a su registro de E108
; (+0x5B tipo y sentido, +0x5C estado, +0x5D temporizador...). Primero
; el boton de responder (0x7708), luego el juego de sprites del mono
; si ha cambiado (E10E), luego las frutas: si toca una colgada en
; pleno salto se la lleva en la cabeza (el mono, 100 puntos; tambien el
; cangrejo que salta); si le da una que va por el aire, el mono pierde
; la vida (estado 10) y el cangrejo se muere (500 puntos, estado 9):
; las frutas se tiran unos a otros. Y por fin el estado por 0x602E:
; 0 escondido, esperando       1 parado (o con la respuesta)
; 2 andando                    3 saltando
; 4 subiendo por un hueco      5 hundiendose despacio
; 6 cayendo                    7 el cangrejo se descuelga de arriba
; 8 tira la fruta que lleva    9 el cangrejo se muere (500)
; 10 al mono le ha dado una fruta
; ######################################################################
; ----------------------------------------------------------------------
ACTOR_PASO:		; Un paso del actor B (1 el mono, 2-4 los cangrejos)
	push bc			;5f5f   ; B se recupera al final de cada estado con el pop bc
	ld a,(0e10ch)		;5f60   ; Con el mono hundiendose (estado 5) no se puede responder
	cp 005h		;5f63
	call nz,RESPONDE		;5f65
	dec b			;5f68   ; IX = sus dos sprites; el registro del actor esta 0x58 mas alla
	ld a,b			;5f69
	add a,a			;5f6a
	add a,a			;5f6b
	add a,a			;5f6c
	ld hl,0e0b0h		;5f6d
	call HL_MAS_A		;5f70
	push hl			;5f73   ; IX = E0B0 + 8 (B - 1): el primer sprite del actor
	pop ix		;5f74
	ld a,(0e273h)		;5f76   ; E10E: el juego de sprites que pide el mono; E273 el que esta cargado
	ld d,a			;5f79
	ld a,(0e10eh)		;5f7a
	cp d			;5f7d
	jr z,ACTOR_FRUTAS		;5f7e
CARGA_SPRITES_MONO:		; Los dos bloques de 0xC0 del juego E10E (tabla 0x6044) a 0x1800 y 0x1C00
	ld (0e273h),a		;5f80
	add a,a			;5f83
	add a,a			;5f84
	ld hl,06044h		;5f85
	call HL_MAS_A		;5f88
	ld e,(hl)			;5f8b
	inc hl			;5f8c
	ld d,(hl)			;5f8d
	inc hl			;5f8e
	push hl			;5f8f
	ex de,hl			;5f90
	ld de,01800h		;5f91
	ld bc,000c0h		;5f94
	di			;5f97
	call COPIA_A_VRAM		;5f98
	pop hl			;5f9b
	ld e,(hl)			;5f9c
	inc hl			;5f9d
	ld d,(hl)			;5f9e
	ex de,hl			;5f9f
	ld de,01c00h		;5fa0
	call COPIA_A_VRAM		;5fa3
	ei			;5fa6
ACTOR_FRUTAS:		; Si el actor toca una fruta (0x6A4F): E = 1 quieta (colgada o en el suelo), 0 en el aire (cae o vuela); D su indice
	call ACTOR_TOCA_FRUTA		;5fa7   ; Carry: toca alguna; D = cual, E = 1 quieta / 0 en el aire
	jp nc,ACTOR_DESPACHA		;5faa
	ld a,e			;5fad   ; E = 0: la fruta va por el aire
	or a			;5fae
	jr z,ACTOR_FRUTA_LE_DA		;5faf
	ld a,(ix+05ch)		;5fb1   ; Solo saltando (estado 3) se coge una fruta quieta
	cp 003h		;5fb4
	jp nz,ACTOR_DESPACHA		;5fb6
	ld (ix+05eh),e		;5fb9   ; +0x5E = 1: el mono va cargado con ella
	ld a,d			;5fbc
	add a,a			;5fbd
	ld hl,0e260h		;5fbe   ; HL = el estado de esa fruta en E260
	call HL_MAS_A		;5fc1
	ld d,00ch		;5fc4   ; 0x0C si es el mono (bits 2 y 3: la lleva en la cabeza), 0x44 si es un cangrejo (bit 6: la ha tirado el)
	ld a,(ix+05bh)		;5fc6
	and 00fh		;5fc9
	jr z,ACTOR_FRUTA_MARCA		;5fcb
	ld d,044h		;5fcd
ACTOR_FRUTA_MARCA:		; La fruta pasa a llevarla el actor
	ld a,(hl)			;5fcf
	or d			;5fd0
	ld (hl),a			;5fd1
	ld a,(ix+05bh)		;5fd2   ; Un cangrejo que la coge no suma nada
	and 00fh		;5fd5
	jr nz,ACTOR_DESPACHA		;5fd7
	ld a,007h		;5fd9   ; El mono: sonido 7 y 100 puntos
	call SONIDO		;5fdb
	ld de,00100h		;5fde
	ld c,000h		;5fe1
	call SUMA_PUNTOS		;5fe3
	jr ACTOR_DESPACHA		;5fe6
ACTOR_FRUTA_LE_DA:		; Una fruta en el aire le da: el mono pierde la vida (estado 10); el cangrejo se muere
	ld a,(ix+05bh)		;5fe8
	and 00fh		;5feb
	jr nz,CANGREJO_MUERE_POR_FRUTA		;5fed
	ld (ix+05ch),00ah		;5fef
	jr ACTOR_DESPACHA		;5ff3
CANGREJO_MUERE_POR_FRUTA:		; La fruta se da por gastada (0x80), su sprite pasa a ser el "500" blanco, sonido 9, 500 puntos, y el cangrejo al estado 9 durante 0x20 fotogramas
	ld a,d			;5ff5
	add a,a			;5ff6   ; D x 2: la pareja [estado, contador] de la fruta
	push af			;5ff7
	ld hl,0e260h		;5ff8
	call HL_MAS_A		;5ffb
	ld (hl),080h		;5ffe   ; 0x80: fruta gastada, ya no la toca nadie
	pop af			;6000
	add a,a			;6001   ; Y x 4: sus cuatro bytes de atributo en E0D8 (+2 es el patron)
	ld hl,0e0dah		;6002
	call HL_MAS_A		;6005
	ld (ix+059h),h		;6008   ; +0x59/+0x5A guardan el puntero al sprite de la fruta, para esconderlo al acabar
	ld (ix+05ah),l		;600b
	ld (hl),070h		;600e   ; Patron 0x70 (el "500") en blanco (0x0F)
	inc hl			;6010
	ld (hl),00fh		;6011
	ld a,009h		;6013
	call SONIDO		;6015
	ld de,00500h		;6018
	ld c,000h		;601b
	call SUMA_PUNTOS		;601d
	ld (ix+05ch),009h		;6020   ; Estado 9 durante 0x20 fotogramas
	ld (ix+05dh),020h		;6024
ACTOR_DESPACHA:		; El estado del actor (+0x5C) por la tabla de 0x602E
	ld a,(ix+05ch)		;6028
	call DESPACHA		;602b

; ----------------------------------------------------------------------
; DATOS tabla_de_estados_del_actor: Los 11 estados de un actor (indice
;   IX+0x5C), destino del despachador de 0x602B
;   0x602e..0x6044  (22 bytes)
DATA_tabla_de_estados_del_actor:
	defw 06050h	; 602e  -> ACTOR_ESCONDIDO
	defw 06081h	; 6030  -> ACTOR_PARADO
	defw 0610ah	; 6032  -> ACTOR_ANDA
	defw 06244h	; 6034  -> ACTOR_SALTANDO
	defw 062d6h	; 6036  -> ACTOR_SUBE_HUECO
	defw 0643bh	; 6038  -> ACTOR_SE_HUNDE
	defw 0645bh	; 603a  -> ACTOR_CAE_ESTADO
	defw 064bah	; 603c  -> ACTOR_SE_DESCUELGA
	defw 064eah	; 603e  -> ACTOR_TIRA_FRUTA
	defw 0656bh	; 6040  -> CANGREJO_MUERE
	defw 0659fh	; 6042  -> ACTOR_LE_DA_LA_FRUTA

; ----------------------------------------------------------------------
; DATOS juegos_de_sprites_del_mono: Tres pares de punteros (0x1800, 0x1C00),
;   indice E10E: 0 el mono normal (0x56BF, 0x59FF), 1 (0x5B3F, 0x5CBF), 2 con
;   la tarjeta de la respuesta (0x5BFF, 0x5D7F)
;   0x6044..0x6050  (12 bytes)
DATA_juegos_de_sprites_del_mono:
	defw 056bfh,059ffh	; 6044  -> DATA_sprites_espejables DATA_sprites_mono_izquierda
	defw 05b3fh,05cbfh	; 6048  -> DATA_sprites_mono_con_fruta DATA_sprites_mono_con_fruta_izquierda
	defw 05bffh,05d7fh	; 604c  -> DATA_sprites_mono_con_tarjeta DATA_sprites_mono_con_tarjeta_izquierda

; ======================================================================
; CODIGO 0x6050..0x6423  (979 bytes)
; ======================================================================


ACTOR_ESCONDIDO:		; Estado 0: fuera de la pantalla mientras +0x5D cuenta (uno cada dos fotogramas); al llegar a cero aparece arriba, en el centro (Y = 0x10, X = 0x60) y se descuelga (estado 7)
	ld (ix+000h),0e1h		;6050   ; Los dos sprites fuera de la pantalla
	ld (ix+004h),0e1h		;6054
	ld a,(ix+05dh)		;6058   ; +0x5D a cero: le toca aparecer
	or a			;605b
	jr z,ACTOR_APARECE		;605c
	ld a,(0e003h)		;605e   ; Cuenta solo en los fotogramas impares
	rra			;6061
	jr c,ACTOR_ESCONDIDO_CUENTA		;6062
	pop bc			;6064
	ret			;6065
ACTOR_ESCONDIDO_CUENTA:		; Uno menos
	dec (ix+05dh)		;6066
	pop bc			;6069
	ret			;606a
ACTOR_APARECE:		; Aparece arriba en el centro y se descuelga
	ld (ix+000h),010h		;606b   ; Y = 0x10 (encima de la plataforma de arriba), X = 0x60 (el centro)
	ld (ix+001h),060h		;606f
	ld (ix+004h),010h		;6073
	ld (ix+005h),060h		;6077
	ld (ix+05ch),007h		;607b   ; Estado 7: se descuelga
	pop bc			;607f
	ret			;6080
ACTOR_PARADO:		; Estado 1: si el mono ya ha entregado la respuesta (E108 = 0x33), borra la flecha y esconde a los cangrejos; si no, disparo = salto, y con direccion, a andar
	ld a,(ix+058h)		;6081   ; 0x33 en E108: la respuesta esta entregada, el mono ya no juega
	cp 033h		;6084
	jr z,RESPUESTA_ENTREGADA		;6086
	ld d,(ix+05bh)		;6088   ; Bits 6-7 de +0x5B: hacia donde va
	ld a,d			;608b   ; Nibble bajo a cero: es el mono
	and 00fh		;608c
	jr nz,ACTOR_PARADO_BIT4		;608e
	ld a,(0e002h)		;6090   ; El mono, con partida en marcha: disparo recien pulsado (E008/E009)
	bit 6,a		;6093
	jr z,ACTOR_PARADO_BIT4		;6095
	ld hl,0e008h		;6097   ; E008 = antes, E009 = ahora: pulsado ahora y no antes
	ld a,(hl)			;609a
	inc hl			;609b
	and (hl)			;609c
	xor (hl)			;609d
	and 010h		;609e   ; Bit 4: el disparo
	jr z,ACTOR_ANDA_SI_HAY		;60a0
ACTOR_PARADO_BIT4:		; Los cangrejos y la demo: el bit 4 es el disparo
	bit 4,d		;60a2   ; Los cangrejos y la demo: bit 4 de +0x5B
	jr z,ACTOR_ANDA_SI_HAY		;60a4
	ld a,(0e238h)		;60a6   ; Con una tarjeta abriendose (E238) no se salta
	or a			;60a9
	jr nz,ACTOR_ANDA_SI_HAY		;60aa
ACTOR_SALTA:		; Arranca el salto: sonido 4, fase 0; con direccion y sitio (X entre 0x0C y 0xB4), sube por el hueco (estado 4); si no, salto vertical (3)
	ld a,(ix+05eh)		;60ac   ; Con carga (bit 0 de +0x5E) el disparo tira la fruta
	rra			;60af   ; Bit 0 de +0x5E: va cargado con una fruta; el boton la tira (estado 8)
	jr c,ACTOR_CARGADO_TIRA		;60b0
	ld a,004h		;60b2
	call SONIDO		;60b4
	ld (ix+05ah),000h		;60b7   ; Fase del salto a cero
	ld a,d			;60bb   ; Bits 6-7 de +0x5B: hacia donde mira; sin ninguno, salto vertical (3)
	and 0c0h		;60bc
	ld e,a			;60be
	ld d,003h		;60bf
	jr z,ACTOR_ESTADO_D		;60c1
	add a,a			;60c3   ; Bit 7 al carry: hacia la derecha
	jr nc,ACTOR_SALTA_IZQ		;60c4
	ld a,(ix+001h)		;60c6   ; A menos de 0xB4 hay sitio para subir por el hueco (estado 4)
	cp 0b4h		;60c9
	jr nc,ACTOR_ESTADO_D		;60cb
	ld d,004h		;60cd
ACTOR_ESTADO_D:		; +0x59 = la direccion si la hay, y el estado D
	ld a,e			;60cf   ; La direccion, si la hay, a +0x59
	or a			;60d0
	jr z,ACTOR_ESTADO_D_PON		;60d1
	ld (ix+059h),a		;60d3
ACTOR_ESTADO_D_PON:		; El estado D
	ld (ix+05ch),d		;60d6
	pop bc			;60d9
	ret			;60da
ACTOR_SALTA_IZQ:		; Lo mismo hacia la izquierda
	ld a,(ix+001h)		;60db   ; Hacia la izquierda: hace falta X >= 0x0C
	cp 00ch		;60de
	jr c,ACTOR_ESTADO_D		;60e0
	ld d,004h		;60e2
	jr ACTOR_ESTADO_D		;60e4
ACTOR_ANDA_SI_HAY:		; Sin disparo: con direccion, a andar (estado 2)
	ld a,d			;60e6   ; Sin disparo: con direccion a andar (2), sin ella nada
	ld d,002h		;60e7
	and 0c0h		;60e9
	jr nz,ACTOR_ESTADO_D_PON		;60eb
	pop bc			;60ed
	ret			;60ee
ACTOR_CARGADO_TIRA:		; Con la fruta encima no salta: la tira (estado 8 durante 0x10 fotogramas)
	ld (ix+05ch),008h		;60ef   ; Estado 8 (tirar) durante 0x10 fotogramas
	ld (ix+05dh),010h		;60f3
	pop bc			;60f7
	ret			;60f8
RESPUESTA_ENTREGADA:		; Borra la flecha roja (2x2 en la fila 6, columna 23) y esconde a los cangrejos
	ld hl,078dbh		;60f9   ; El bloque vacio de 2x2 borra la flecha roja (fila 6, columna 23)
	ld de,030b8h		;60fc
	ld bc,00202h		;60ff
	call PINTA_BLOQUE		;6102
	call ESCONDE_CANGREJOS		;6105
	pop bc			;6108
	ret			;6109
ACTOR_ANDA:		; Estado 2: tres pasos por delante; disparo salta; sin direccion se para; con ella avanza un pixel con la animacion de 0x65C3 (derecha) o 0x65D3 (izquierda) y suena el paso cada 4
	ld (ix+05fh),003h		;610a   ; Tres pasos antes de que un cangrejo se plantee girar
	ld d,(ix+05bh)		;610e
	ld a,d			;6111
	and 00fh		;6112
	jr nz,ACTOR_ANDA_BIT4		;6114
	ld a,(0e002h)		;6116
	bit 6,a		;6119
	jr z,ACTOR_ANDA_BIT4		;611b
	ld hl,0e008h		;611d   ; El disparo recien pulsado salta
	ld a,(hl)			;6120
	inc hl			;6121
	and (hl)			;6122
	xor (hl)			;6123
	and 010h		;6124
	jr nz,ACTOR_SALTA		;6126
	jr ACTOR_ANDA_MIRA		;6128
ACTOR_ANDA_BIT4:		; Bit 4: salta
	bit 4,d		;612a   ; Para un cangrejo el disparo es el bit 4 de +0x5B
	jp nz,ACTOR_SALTA		;612c
ACTOR_ANDA_MIRA:		; Con direccion sigue; sin ella se para
	ld a,d			;612f   ; Sin direccion (bits 6-7): a parado (1)
	and 0c0h		;6130
	jr nz,ACTOR_ANDA_PASO		;6132
	ld d,001h		;6134   ; Sin direccion: parado (estado 1)
	jr ACTOR_ESTADO_D_PON		;6136
ACTOR_ANDA_PASO:		; Un pixel hacia el lado con la animacion
	ld (ix+059h),d		;6138
	ld hl,065c3h		;613b   ; Hacia la derecha: la tabla de 0x65C3 y E = +1
	ld e,001h		;613e
	add a,a			;6140
	jr c,ACTOR_ANDA_MUEVE		;6141
	ld hl,065d3h		;6143   ; Hacia la izquierda: la de 0x65D3 y E = -1
	ld e,0ffh		;6146
ACTOR_ANDA_MUEVE:		; X mas o menos uno
	call ACTOR_BC		;6148   ; B = Y, C = X; la X nueva
	ld a,c			;614b
	add a,e			;614c
	ld c,a			;614d
	and 003h		;614e   ; Cada cuatro pixels suena el paso (3)
	jr nz,ACTOR_ANDA_SUELO		;6150
	ld a,003h		;6152
	call SONIDO		;6154
ACTOR_ANDA_SUELO:		; La animacion y el suelo
	call ACTOR_ANIMACION		;6157   ; Los dos patrones de la fase de andar (X / 4 & 3)
	call HAY_SUELO		;615a   ; Carry: no hay suelo debajo
	jr c,ACTOR_SIN_SUELO		;615d
	ld a,c			;615f   ; X entre 8 y 0xB8: dentro
	cp 008h		;6160   ; X entre 8 y 0xB8: dentro de la pantalla de juego
	jr c,ACTOR_BORDE_IZQ		;6162
	cp 0b9h		;6164
	jr nc,ACTOR_BORDE_DER		;6166
ACTOR_ANDA_X:		; X nueva a los dos sprites; el cangrejo del tipo 3, cuando el azar (E140) sale a cero, se pone el bit 4: para el, el disparo
	ld (ix+001h),c		;6168   ; La X a los dos sprites
	ld (ix+005h),c		;616b
	pop bc			;616e
	ld a,d			;616f   ; El mono (tipo 0) acaba aqui; de los cangrejos, solo el tipo 3 sigue
	and 00fh		;6170
	ret z			;6172
	cp 003h		;6173
	ret nz			;6175
	call AZAR		;6176   ; Solo cuando E140 sale exactamente 0: se pone el bit 4 (saltara en cuanto este parado)
	ld a,(0e140h)		;6179   ; Solo cuando E140 sale a cero: se pone el bit 4 (saltara)
	or a			;617c
	ret nz			;617d
	ld a,(ix+05bh)		;617e
	and 00fh		;6181
	or 010h		;6183
	ld (ix+05bh),a		;6185
	ld (ix+05ah),000h		;6188
	ret			;618c
ACTOR_SIN_SUELO:		; Sin suelo debajo: el mono y el tipo 1 se caen (estado 6); los tipos 2 y 3 lo piensan (0x6205)
	ld a,(ix+05bh)		;618d   ; Tipos 2 y 3 (y 4) lo piensan; el mono y el tipo 1 caen
	ld d,a			;6190
	and 00fh		;6191
	cp 002h		;6193
	jr nc,CANGREJO_LO_PIENSA		;6195
ACTOR_CAE:		; Un pixel mas alla del borde y a caer (estado 6) con el sonido 5
	ld a,006h		;6197   ; Un pixel mas alla del borde: 6 hacia la derecha (bit 7), -6 (0xFA) hacia la izquierda
	bit 7,d		;6199
	jr nz,ACTOR_CAE_LADO		;619b
	ld a,0fah		;619d
ACTOR_CAE_LADO:		; El pixel de mas alla del borde
	add a,c			;619f
	ld c,a			;61a0
	ld (ix+05ch),006h		;61a1   ; Estado 6 (caer) con el sonido 5
	ld a,005h		;61a5
	call SONIDO		;61a7
	jr ACTOR_ANDA_X		;61aa
ACTOR_BORDE_DER:		; Borde derecho: el cangrejo da la vuelta (bits 6-7 de +0x5B); el mono se queda
	ld a,d			;61ac   ; El mono no da la vuelta: se queda en el borde
	and 00fh		;61ad
	jr z,ACTOR_RETROCEDE		;61af
	ld a,0c0h		;61b1   ; Bits 6-7 al reves: el cangrejo cambia de sentido
	xor (ix+05bh)		;61b3
	ld (ix+05bh),a		;61b6
	pop bc			;61b9
	ret			;61ba
ACTOR_RETROCEDE:		; Deshace el pixel
	ld a,e			;61bb   ; Deshace el pixel que se habia movido
	neg		;61bc
	add a,c			;61be
	ld c,a			;61bf
	jr ACTOR_ANDA_X		;61c0
ACTOR_BORDE_IZQ:		; Borde izquierdo: el cangrejo da la vuelta si no esta en el suelo (Y < 0xA8); en el suelo se marcha por la izquierda (estado 0, a esperar)
	ld a,d			;61c2
	and 00fh		;61c3
	jr z,ACTOR_RETROCEDE		;61c5
	ld a,b			;61c7   ; Y = 0xA8: en el suelo; por encima da la vuelta como en el borde derecho
	cp 0a8h		;61c8
	jr c,ACTOR_BORDE_DER		;61ca
	call CANGREJO_SUELTA_FRUTA		;61cc   ; En el suelo se marcha por la izquierda: suelta la fruta y a esperar escondido
	ld (ix+05ch),000h		;61cf
	call CANGREJO_ESPERA		;61d3
	pop bc			;61d6
	ret			;61d7
CANGREJO_SUELTA_FRUTA:		; Si iba cargado (bit 0 de +0x5E) busca la fruta 8 pixels por encima (0x6A55) y la hace desaparecer con el
	ld a,(ix+05eh)		;61d8   ; Bit 0 de +0x5E: va cargado
	rra			;61db
	ret nc			;61dc
	ld a,(ix+000h)		;61dd
	ld h,a			;61e0
	push hl			;61e1
	sub 008h		;61e2   ; Mira 8 pixels por encima de su Y (donde va la fruta que lleva)
	ld (ix+000h),a		;61e4
	call TOCA_FRUTA_SIN_TARJETA		;61e7
	pop hl			;61ea
	ld (ix+000h),h		;61eb
	ret nc			;61ee
	ld a,d			;61ef
	add a,a			;61f0
	push af			;61f1
	ld hl,0e260h		;61f2
	call HL_MAS_A		;61f5
	ld (hl),000h		;61f8   ; La fruta a estado 0 y su sprite fuera (Y = 0xE1)
	pop af			;61fa
	add a,a			;61fb
	ld hl,0e0d8h		;61fc
	call HL_MAS_A		;61ff
	ld (hl),0e1h		;6202
	ret			;6204
CANGREJO_LO_PIENSA:		; Los tipos 2 y 3 al borde: el 4 (0x44, desde la fase 18) da la vuelta si esta en la altura de +0x58 (0x38: la segunda plataforma) y si no se deja caer; los demas caen o dan la vuelta al azar
	cp 004h		;6205   ; Tipo 4: el de la fase 18
	jr z,CANGREJO_44		;6207
	call AZAR		;6209
	ld a,(0e140h)		;620c   ; El bit 0 del azar decide: cae o gira
	rra			;620f
	jr c,ACTOR_CAE		;6210
CANGREJO_GIRA:		; Cambia de sentido sin caer (estado 4 = sube por el hueco)
	ld (ix+059h),d		;6212   ; Girar sin caer es el estado 4 (subir por el hueco) hacia el otro lado
	ld (ix+05ch),004h		;6215
	ld (ix+05ah),000h		;6219
	jp ACTOR_ANDA_X		;621d
CANGREJO_44:		; El de la fase 18: da la vuelta si su Y es la de +0x58 (0x38, la segunda plataforma), si no cae
	ld a,(ix+058h)		;6220   ; +0x58 = 0x38: la Y de la segunda plataforma; a esa altura gira, si no cae
	cp b			;6223
	jr z,CANGREJO_GIRA		;6224
	jp ACTOR_CAE		;6226
ACTOR_ANIMACION:		; Los dos patrones de la fase de andar (X/4 & 3) de la tabla HL (+8 para los cangrejos)
	ld a,c			;6229   ; (X & 0x0C) / 2: dos bytes por fase, cuatro fases
	and 00ch		;622a
	rra			;622c
	call HL_MAS_A		;622d
	ld a,d			;6230
	and 00fh		;6231
	jr z,ACTOR_ANIMACION_PON		;6233
	ld a,008h		;6235   ; Los cangrejos, ocho bytes mas alla (su tabla va detras)
	call HL_MAS_A		;6237
ACTOR_ANIMACION_PON:		; Los dos patrones
	ld a,(hl)			;623a
	ld (ix+002h),a		;623b
	inc hl			;623e
	ld a,(hl)			;623f
	ld (ix+006h),a		;6240
	ret			;6243
ACTOR_SALTANDO:		; Estado 3: si el mono lleva la respuesta y toca al profesor (0x6ADB), entregada (E108 = 0x33). Sube y baja con la tabla de 0x6423; en lo alto (paso 11) coge la tarjeta si la hay (0x6A1F); al ultimo paso (23) al estado 6
	call TOCA_AL_PROFESOR		;6244   ; NC: el mono lleva la tarjeta y toca al profesor
	jr c,ACTOR_SALTO_PASO		;6247
	ld hl,0e270h		;6249   ; Bit 0 de E270: la tarjeta sube sola; E108 = 0x33; y los sprites normales
	set 0,(hl)		;624c
	ld (ix+058h),033h		;624e
	ld (ix+05eh),000h		;6252
ACTOR_SALTO_PASO:		; Un paso del salto
	call ACTOR_BC		;6256
	ld a,(ix+05ah)		;6259   ; Bit 7 de +0x5A: ya va por la tabla
	add a,a			;625c   ; Bit 7 de +0x5A: la bajada; si no, los primeros 8 pasos suben 4 pixels cada uno
	jr c,ACTOR_SALTO_TABLA		;625d
	and 01eh		;625f   ; Los pasos pares hasta el 8: cuatro pixels arriba cada uno
	cp 008h		;6261   ; Al octavo paso, empieza la tabla (bit 7)
	jr z,ACTOR_SALTO_TABLA_EMPIEZA		;6263
	ld a,b			;6265
	sub 004h		;6266
	ld b,a			;6268
ACTOR_SALTO_Y:		; Y nueva a los dos sprites y un paso mas
	ld (ix+000h),b		;6269   ; La Y nueva a los dos sprites
	ld (ix+004h),b		;626c
	inc (ix+05ah)		;626f
	pop bc			;6272
	ret			;6273
ACTOR_SALTO_TABLA_EMPIEZA:		; Al octavo paso empieza la tabla
	ld (ix+05ah),080h		;6274   ; Del octavo paso en adelante, la tabla (bit 7)
	xor a			;6278
ACTOR_SALTO_TABLA:		; El desplazamiento del paso (+0x5A/2) de 0x6423; el 23 aterriza (estado 6); el 11 (lo alto) mira la tarjeta
	or a			;6279   ; Indice = +0x5A / 2 (un paso de tabla cada dos fotogramas)
	rra			;627a
	ld d,a			;627b
	ld hl,06423h		;627c
	call HL_MAS_A		;627f
	ld a,(hl)			;6282
	add a,b			;6283
	ld b,a			;6284
	ld a,d			;6285   ; El paso 23 es el suelo; el 11 lo alto
	cp 017h		;6286
	jr z,ACTOR_ATERRIZA		;6288
	cp 00bh		;628a
	jr nz,ACTOR_SALTO_Y		;628c
	call HAY_TARJETA_ENCIMA		;628e   ; Carry: no hay tarjeta encima
	jr c,ACTOR_SALTO_Y		;6291
	call TILE_A_PIXELS		;6293   ; D = fila x 8 (menos 7 filas), E = columna x 8; con la segunda mitad del canto, 8 pixels menos
	dec a			;6296
	jr z,BUSCA_TARJETA_ENTRA		;6297
	ld a,e			;6299
	sub 008h		;629a
	ld e,a			;629c
BUSCA_TARJETA_ENTRA:		; Recorre E15A desde el principio
	ld h,0ffh		;629d   ; H cuenta las tarjetas; IY recorre E15A desde el principio
	ld iy,0e158h		;629f
BUSCA_TARJETA:		; Busca en E15A la tarjeta que cuelga en (D, E) y la coge (0x4FAE): repintar y estado 5 (se hunde con ella)
	inc iy		;62a3
	inc iy		;62a5
	ld a,(iy+000h)		;62a7
	cp 0ffh		;62aa   ; 0xFF: fin de la lista, no era ninguna
	jr z,ACTOR_SALTO_Y		;62ac
	inc h			;62ae
	cp d			;62af   ; Misma Y y misma X que la tarjeta H
	jr nz,BUSCA_TARJETA		;62b0
	ld a,(iy+001h)		;62b2
	cp e			;62b5
	jr nz,BUSCA_TARJETA		;62b6
	ld a,h			;62b8
	push bc			;62b9
	call COGE_TARJETA		;62ba   ; La coge (E1AF = H, y suelta la anterior)
	add a,a			;62bd
	call TARJETAS_DEL_JUGADOR		;62be
	call HL_MAS_A		;62c1
	set 7,(hl)		;62c4   ; Bit 7: repintarla (empieza a bajar)
	ld a,005h		;62c6   ; Estado 5: bajar con ella
	pop bc			;62c8
	jr ACTOR_SALTO_ACABA		;62c9
ACTOR_ATERRIZA:		; Estado 6 (cayendo) con +0x5A = 0xFF
	ld a,006h		;62cb   ; Estado 6 (cayendo) con la fase a 0xFF
ACTOR_SALTO_ACABA:		; Estado A con +0x5A = 0xFF
	ld (ix+05ah),0ffh		;62cd
	ld (ix+05ch),a		;62d1
	jr ACTOR_SALTO_Y		;62d4
ACTOR_SUBE_HUECO:		; Estado 4: sube por un hueco de la plataforma de arriba trepando (patrones 0x65E3/0x65E5); si no hay hueco, salto corto y vuelta
	ld (ix+05fh),003h		;62d6   ; Tres pasos antes de girar, como al andar
	ld a,(ix+059h)		;62da   ; Bit 7 de +0x59 al carry: hacia la derecha (0x65E3); si no, hacia la izquierda (0x65E5)
	ld hl,065e3h		;62dd
	add a,a			;62e0
	jr c,ACTOR_HUECO_PATRONES		;62e1
	ld hl,065e5h		;62e3
ACTOR_HUECO_PATRONES:		; Los patrones de trepar en el primer paso
	and 00eh		;62e6   ; Solo en el primer paso (bits 1-3 a cero) se ponen los patrones de trepar
	jr nz,ACTOR_HUECO_FASE		;62e8
	ld a,(hl)			;62ea
	ld (ix+002h),a		;62eb
	inc hl			;62ee
	ld a,(hl)			;62ef
	ld (ix+006h),a		;62f0
ACTOR_HUECO_FASE:		; Bit 7 baja, bit 6 cae, si no sube
	ld a,(ix+05ah)		;62f3   ; Bit 7 de +0x5A: bajando por la tabla; bit 6: cayendo recto
	add a,a			;62f6
	jp c,ACTOR_HUECO_BAJA		;62f7
	add a,a			;62fa
	jr c,ACTOR_HUECO_CAE		;62fb
	ld a,(ix+05ah)		;62fd   ; En los seis primeros pasos, el mono sin mando (bits 4-7 de +0x5B a cero) se planta
	and 00fh		;6300
	cp 006h		;6302
	jr nc,ACTOR_HUECO_SUBE		;6304
	ld a,(ix+05bh)		;6306
	ld d,a			;6309
	and 00fh		;630a
	jr nz,ACTOR_HUECO_SUBE		;630c
	bit 4,d		;630e
	jr nz,ACTOR_HUECO_SUBE		;6310
ACTOR_HUECO_PARA:		; Se queda con el bit 7: baja
	ld (ix+05ah),080h		;6312   ; 0x80: se acabo la subida, a bajar por la tabla
	pop bc			;6316
	ret			;6317
ACTOR_HUECO_SUBE:		; Un paso mas arriba
	inc (ix+05ah)		;6318   ; Un paso mas; en el 15 se planta
	ld a,(ix+05ah)		;631b
	and 00fh		;631e
	cp 00fh		;6320
	jr z,ACTOR_HUECO_PARA		;6322
	ld a,(ix+000h)		;6324   ; Cuatro pixels arriba
	sub 004h		;6327
	ld (ix+000h),a		;6329
	ld (ix+004h),a		;632c
	ld a,(ix+059h)		;632f   ; Y un pixel al lado segun +0x59 (bit 7: derecha)
	add a,a			;6332
	ld a,001h		;6333
	jr c,ACTOR_HUECO_X		;6335
	ld a,0ffh		;6337
ACTOR_HUECO_X:		; La X con el desplazamiento
	add a,(ix+001h)		;6339
	cp 008h		;633c   ; La X entre 8 y 0xB8
	jr nc,ACTOR_HUECO_X_MIN		;633e
	ld a,008h		;6340
ACTOR_HUECO_X_MIN:		; X = 8 como poco
	cp 0b8h		;6342
	jr c,ACTOR_HUECO_X_PON		;6344
	ld a,0b8h		;6346
ACTOR_HUECO_X_PON:		; X a los dos sprites y mira la plataforma de arriba
	ld (ix+001h),a		;6348
	ld (ix+005h),a		;634b
	ld a,(ix+000h)		;634e   ; La plataforma que busca: 0x18 por encima, y 6 pixels hacia donde va (0xFA = -6)
	sub 018h		;6351
	ld b,a			;6353
	ld a,(ix+059h)		;6354
	ld c,006h		;6357
	add a,a			;6359
	jr c,ACTOR_HUECO_MIRA_ARRIBA		;635a
	ld c,0fah		;635c
ACTOR_HUECO_MIRA_ARRIBA:		; Con la X mas o menos 6
	ld a,(ix+001h)		;635e
	add a,c			;6361
	ld c,a			;6362
	call HAY_PLATAFORMA_ARRIBA		;6363   ; Carry: la hay, y se sube (0x63D9); si no, se planta
	jp c,ACTOR_HUECO_SUELO		;6366
	jr ACTOR_HUECO_PARA		;6369
ACTOR_HUECO_CAE:		; Cae recto (4 pixels, alineado) moviendose un pixel al lado
	ld a,(ix+000h)		;636b   ; Cuatro pixels abajo, alineado a cuatro
	add a,004h		;636e
	and 0fch		;6370
	ld (ix+000h),a		;6372
	ld (ix+004h),a		;6375
	ld a,(ix+059h)		;6378   ; Un pixel al lado, entre 8 y 0xB8
	add a,a			;637b
	ld a,001h		;637c
	jr c,ACTOR_HUECO_CAE_X		;637e
	ld a,0ffh		;6380
ACTOR_HUECO_CAE_X:		; La X al caer
	add a,(ix+001h)		;6382
	cp 008h		;6385
	jr nc,ACTOR_HUECO_CAE_X_MIN		;6387
	ld a,008h		;6389
ACTOR_HUECO_CAE_X_MIN:		; Como poco 8
	cp 0b8h		;638b
	jr c,ACTOR_HUECO_CAE_X_PON		;638d
	ld a,0b8h		;638f
ACTOR_HUECO_CAE_X_PON:		; A los dos sprites
	ld (ix+001h),a		;6391
	ld (ix+005h),a		;6394
	jr ACTOR_HUECO_SUELO		;6397
ACTOR_HUECO_BAJA:		; La bajada por la tabla de 0x6423 moviendose un pixel al lado; en el paso 0x18 deja de bajar y en el 0x12 cae recto
	ld a,(ix+059h)		;6399   ; Un pixel al lado por fotograma
	add a,a			;639c
	ld a,001h		;639d
	jr c,ACTOR_HUECO_BAJA_X		;639f
	ld a,0ffh		;63a1
ACTOR_HUECO_BAJA_X:		; La X al bajar por la tabla
	add a,(ix+001h)		;63a3
	ld (ix+001h),a		;63a6
	ld (ix+005h),a		;63a9
	ld a,(ix+05ah)		;63ac   ; El desplazamiento de la tabla del salto (indice en los bits 0-5)
	and 03fh		;63af
	ld hl,06423h		;63b1
	call HL_MAS_A		;63b4
	ld a,(ix+000h)		;63b7
	add a,(hl)			;63ba
	ld (ix+000h),a		;63bb
	ld (ix+004h),a		;63be
	inc (ix+05ah)		;63c1
	ld a,(ix+05ah)		;63c4   ; En el paso 0x18 deja de bajar por la tabla (bit 7 fuera)
	and 03fh		;63c7
	cp 018h		;63c9
	jr c,ACTOR_HUECO_BAJA_PASO		;63cb
	res 7,(ix+05ah)		;63cd
ACTOR_HUECO_BAJA_PASO:		; En el paso 0x12, a caer recto
	cp 012h		;63d1   ; Del paso 0x12 en adelante cae recto (bit 6)
	jr c,ACTOR_HUECO_SUELO		;63d3
	set 6,(ix+05ah)		;63d5
ACTOR_HUECO_SUELO:		; Con suelo debajo (0x6924): parado (estado 1) o cayendo (6) si se salio de la pantalla; los patrones de andar
	call ACTOR_BC		;63d9   ; D = 1 (parado) si hay suelo
	call HAY_SUELO		;63dc
	ld d,001h		;63df
	jr nc,ACTOR_HUECO_SUELO_PATRONES		;63e1
	ld a,c			;63e3   ; Sin suelo: fuera de la pantalla se recoloca y cae (6); si no, sigue
	cp 008h		;63e4
	jp c,ACTOR_HUECO_TOPE_IZQ		;63e6
	cp 0b8h		;63e9
	jr nc,ACTOR_HUECO_TOPE_DER		;63eb
	jr ACTOR_HUECO_SALE		;63ed
ACTOR_HUECO_TOPE_IZQ:		; X = 8 y a caer
	ld a,008h		;63ef
ACTOR_HUECO_TOPE:		; X al tope y a caer (6)
	ld (ix+001h),a		;63f1
	ld (ix+005h),a		;63f4
	ld d,006h		;63f7
	jr ACTOR_HUECO_SUELO_PATRONES		;63f9
ACTOR_HUECO_TOPE_DER:		; X = 0xB8 y a caer
	ld a,0b8h		;63fb
	jr ACTOR_HUECO_TOPE		;63fd
ACTOR_HUECO_SUELO_PATRONES:		; Con suelo: los patrones de andar segun el sentido
	ld a,(ix+059h)		;63ff   ; Con sentido (bits 6-7 de +0x59) los patrones de andar; sin el, se quedan
	ld c,a			;6402
	and 00fh		;6403
	jr nz,ACTOR_HUECO_FIN		;6405
	ld a,c			;6407
	add a,a			;6408
	ld hl,065c3h		;6409
	jr c,ACTOR_HUECO_SUELO_PON		;640c
	ld hl,065d3h		;640e
ACTOR_HUECO_SUELO_PON:		; Los patrones
	ld a,(hl)			;6411
	ld (ix+002h),a		;6412
	inc hl			;6415
	ld a,(hl)			;6416
	ld (ix+006h),a		;6417
ACTOR_HUECO_FIN:		; +0x5A = 0 y el estado D
	ld (ix+05ah),000h		;641a   ; Fase a cero y el estado D
	ld (ix+05ch),d		;641e
ACTOR_HUECO_SALE:		; Fuera
	pop bc			;6421
	ret			;6422

; ----------------------------------------------------------------------
; DATOS arco_del_salto: Los 24 desplazamientos verticales del salto (uno por
;   cada dos fotogramas): -3 -3 -3 -2 -1 -1 -1 0 -1 0 -1 0 (sube) 0 1 0 1 0 1
;   1 1 2 3 3 3 (baja); el paso 11 es lo alto y el 23 el suelo
;   0x6423..0x643b  (24 bytes)
DATA_arco_del_salto:
	defb 0fdh,0fdh,0fdh,0feh,0ffh,0ffh,0ffh,000h,0ffh,000h,0ffh,000h	; 6423  ............
	defb 000h,001h,000h,001h,000h,001h,001h,001h,002h,003h,003h,003h	; 642f  ............

; ======================================================================
; CODIGO 0x643b..0x65c3  (392 bytes)
; ======================================================================


ACTOR_SE_HUNDE:		; Estado 5: cada 8 fotogramas baja 4 pixels hasta tocar suelo (0x6924); entonces parado (1). Es el mono bajando con la tarjeta recien cogida
	ld a,(0e003h)		;643b   ; Cada ocho fotogramas
	and 007h		;643e
	jr nz,ACTOR_SE_HUNDE_FIN		;6440
	ld a,(ix+000h)		;6442   ; Cuatro pixels abajo
	add a,004h		;6445
	ld (ix+000h),a		;6447
	ld (ix+004h),a		;644a
	call ACTOR_BC		;644d
	call HAY_SUELO		;6450   ; Con suelo debajo, parado (1)
	jr c,ACTOR_SE_HUNDE_FIN		;6453
	ld (ix+05ch),001h		;6455
ACTOR_SE_HUNDE_FIN:		; Fuera
	pop bc			;6459
	ret			;645a
ACTOR_CAE_ESTADO:		; Estado 6: baja 4 pixels (alineado a 4) hasta el suelo; el cangrejo elige entonces sentido al azar y el mono se queda parado
	ld a,(ix+000h)		;645b   ; Cuatro pixels abajo, alineado a cuatro
	add a,004h		;645e
	and 0fch		;6460
	ld (ix+000h),a		;6462
	ld (ix+004h),a		;6465
	call ACTOR_BC		;6468
	call HAY_SUELO		;646b   ; Sin suelo sigue cayendo
	jr nc,ACTOR_CAE_SUELO		;646e
	pop bc			;6470
	ret			;6471
ACTOR_CAE_SUELO:		; Con suelo: parado (1); el cangrejo elige sentido
	ld (ix+05ch),001h		;6472   ; Con suelo: parado (1)
	ld a,(ix+05bh)		;6476
	ld e,a			;6479
	and 00fh		;647a   ; Los cangrejos salen andando hacia la derecha (bit 7)... o hacia la izquierda si sale impar
	jr z,ACTOR_CAE_MONO		;647c
	or 080h		;647e   ; El cangrejo sale hacia la derecha (bit 7)...
	ld (ix+05bh),a		;6480
	ld e,a			;6483
	call AZAR		;6484   ; ...o hacia la izquierda si el azar sale impar (bits 6-7 al reves)
	ld a,(0e140h)		;6487
	and 001h		;648a
	jr z,ACTOR_CAE_MONO		;648c
	ld a,0c0h		;648e
	xor e			;6490
	ld (ix+05bh),a		;6491
	pop bc			;6494
	ret			;6495
ACTOR_CAE_MONO:		; El mono: cada tres pasos de caida, si no esta en el suelo (Y = 0xA8), mira si hay una fruta 0x18 por debajo (0x6A5B) y la descuelga (bit 0 de E260: cae)
	dec (ix+05fh)		;6496   ; Cada tres pasos de caida
	jr nz,ACTOR_CAE_FIN		;6499
	ld a,b			;649b   ; En el suelo (Y = 0xA8) no mira
	cp 0a8h		;649c
	jr z,ACTOR_CAE_FIN		;649e
	ld a,018h		;64a0   ; Mira 0x18 pixels por debajo de su Y
	add a,b			;64a2
	push bc			;64a3
	ld (ix+000h),a		;64a4
	call TOCA_ALGUNA_FRUTA		;64a7
	pop bc			;64aa
	ld (ix+000h),b		;64ab
	ld a,d			;64ae
	add a,a			;64af
	ld hl,0e260h		;64b0   ; La fruta que hay ahi pasa a caer (bit 0)
	call HL_MAS_A		;64b3
	set 0,(hl)		;64b6
ACTOR_CAE_FIN:		; Fuera
	pop bc			;64b8
	ret			;64b9
ACTOR_SE_DESCUELGA:		; Estado 7: cada 4 fotogramas baja un pixel mientras el tile bajo el sprite no sea vacio (esta cruzando la plataforma de arriba); en el vacio, a caer (estado 6)
	ld hl,0e274h		;64ba   ; Cada cuatro fotogramas
	inc (hl)			;64bd
	ld a,(hl)			;64be
	and 003h		;64bf
	jr z,ACTOR_SE_DESCUELGA_PIXEL		;64c1
	pop bc			;64c3
	ret			;64c4
ACTOR_SE_DESCUELGA_PIXEL:		; Un pixel abajo y mira el tile
	inc (ix+000h)		;64c5   ; Un pixel abajo
	ld a,(ix+000h)		;64c8
	ld (ix+004h),a		;64cb
	ld d,a			;64ce
	ld a,(ix+001h)		;64cf
	ld e,a			;64d2
	call PIXELS_A_VRAM		;64d3   ; El tile bajo el sprite: distinto de cero es la plataforma; cero, ya la ha cruzado y cae (6)
	di			;64d6
	call VDP_DIRECCION		;64d7
	call RET_3		;64da
	in a,(098h)		;64dd
	ei			;64df
	cp 000h		;64e0
	jr nz,ACTOR_SE_DESCUELGA_FIN		;64e2
	ld (ix+05ch),006h		;64e4
ACTOR_SE_DESCUELGA_FIN:		; Fuera
	pop bc			;64e8
RET_3:		; `ret` de espera para el VDP
	ret			;64e9
ACTOR_TIRA_FRUTA:		; Estado 8: la fruta que lleva (E260 con 0x0C el mono, 0x04 el cangrejo) sale volando (bit 1) hacia donde mira (bit 5). El mono se queda +0x5D fotogramas con los brazos de tirar (los sprites 18-19 de 0x56BF: 0x60/0x64, o sus espejos 0xE0/0xE4) y vuelve a estar parado (1); el cangrejo con los suyos (20-21: 0x68/0x6C, o 0xE8/0xEC)
	ld b,008h		;64ea   ; Ocho frutas; busca la que lleva: 0x0C el mono, 0x04 un cangrejo
	ld hl,0e260h		;64ec
	ld d,00ch		;64ef   ; 0x0C: la lleva el mono; 0x04: un cangrejo
	ld a,(ix+05bh)		;64f1
	and 00fh		;64f4
	jr z,ACTOR_TIRA_BUSCA		;64f6
	ld d,004h		;64f8
ACTOR_TIRA_BUSCA:		; Busca la fruta que lleva
	ld a,(hl)			;64fa
	and 00ch		;64fb
	cp d			;64fd
	jr z,ACTOR_TIRA_SUELTA		;64fe
	inc hl			;6500
	inc hl			;6501
	djnz ACTOR_TIRA_BUSCA		;6502
	jr ACTOR_TIRA_POSE		;6504
ACTOR_TIRA_SUELTA:		; La fruta a volar
	set 1,(hl)		;6506   ; Bit 1: vuela; fuera los bits 2, 3 y 5; el bit 5 dice hacia donde (bit 7 de +0x59, derecha)
	ld a,(hl)			;6508
	and 0d3h		;6509
	ld (hl),a			;650b
	ld a,(ix+059h)		;650c
	add a,a			;650f
	jr nc,ACTOR_TIRA_POSE		;6510
	set 5,(hl)		;6512
ACTOR_TIRA_POSE:		; El mono con los brazos de tirar mientras cuenta
	ld a,(ix+05bh)		;6514   ; El cangrejo va por CANGREJO_TIRA
	and 00fh		;6517
	jr nz,CANGREJO_TIRA		;6519
	dec (ix+05dh)		;651b   ; Mientras cuenta +0x5D, la pose de tirar: 0x60/0x64 hacia la derecha, 0xE0/0xE4 hacia la izquierda
	jr z,ACTOR_TIRA_FIN		;651e
	ld a,(ix+059h)		;6520
	add a,a			;6523
	ld bc,06064h		;6524
	jr c,ACTOR_TIRA_PATRONES		;6527
	ld bc,0e0e4h		;6529
ACTOR_TIRA_PATRONES:		; Los dos patrones
	ld (ix+002h),b		;652c
	ld (ix+006h),c		;652f
	pop bc			;6532
	ret			;6533
ACTOR_TIRA_FIN:		; El mono vuelve a estar parado (estado 1) con sus patrones (0x00/0x0C o 0x80/0x8C) y sin carga
	ld bc,0000ch		;6534   ; Se acabo: los patrones de parado (0x00/0x0C o 0x80/0x8C)
	ld a,(ix+059h)		;6537
	add a,a			;653a
	jr c,ACTOR_TIRA_PARADO		;653b
	ld bc,0808ch		;653d
ACTOR_TIRA_PARADO:		; Parado (1) y sin carga
	ld (ix+05ch),001h		;6540   ; Parado (1) y sin carga
	ld (ix+05eh),000h		;6544
	jr ACTOR_TIRA_PATRONES		;6548
CANGREJO_TIRA:		; El cangrejo, con los patrones 0xE8/0xEC (o 0x68/0x6C) mientras cuenta
	dec (ix+05dh)		;654a   ; El cangrejo: 0xE8/0xEC hacia la derecha, 0x68/0x6C hacia la izquierda
	jr z,CANGREJO_TIRA_FIN		;654d
	ld a,(ix+059h)		;654f
	add a,a			;6552
	ld bc,0e8ech		;6553
	jr c,ACTOR_TIRA_PATRONES		;6556
	ld bc,0686ch		;6558
	jr ACTOR_TIRA_PATRONES		;655b
CANGREJO_TIRA_FIN:		; Y a estar parado con 0x30/0x3C (o 0xB0/0xBC)
	ld bc,0303ch		;655d   ; Y de vuelta a los suyos, 0x30/0x3C o 0xB0/0xBC
	ld a,(ix+059h)		;6560
	add a,a			;6563
	jr c,ACTOR_TIRA_PARADO		;6564
	ld bc,0b0bch		;6566
	jr ACTOR_TIRA_PARADO		;6569
CANGREJO_MUERE:		; Estado 9: cuando acaba +0x5D, esconde el "500" (el sprite de la fruta que lo mato, +0x59/+0x5A), vuelve a esconderse (estado 0) a esperar segun la fase (0x6585), y la fruta que llevara desaparece
	pop bc			;656b   ; B recuperado antes: este estado no pasa por ACTOR_DESPACHA al volver
	dec (ix+05dh)		;656c
	ret nz			;656f
	ld h,(ix+059h)		;6570   ; El puntero al sprite del "500" (guardado en +0x59/+0x5A, apuntaba al patron): dos menos es su Y
	ld l,(ix+05ah)		;6573
	dec hl			;6576
	dec hl			;6577
	ld (hl),0e1h		;6578
	ld (ix+05ch),000h		;657a   ; Escondido (0) a esperar lo que diga la fase
	call CANGREJO_ESPERA		;657e
	call CANGREJO_SUELTA_FRUTA		;6581
	ret			;6584
CANGREJO_ESPERA:		; +0x5D = cuanto espera escondido: (16 - fase) x 16 + 17 fotogramas hasta la fase 19; desde la 20, uno
	ld a,(0e051h)		;6585   ; Fases 1-19: (16 - fase) x 16 + 17; desde la 20 (0x20 en BCD), 1
	cp 020h		;6588
	jr nc,CANGREJO_ESPERA_1		;658a
	neg		;658c
	add a,a			;658e
	add a,a			;658f
	add a,a			;6590
	add a,a			;6591
	and 070h		;6592
	add a,010h		;6594
	inc a			;6596
CANGREJO_ESPERA_PON:		; +0x5D = A
	ld (ix+05dh),a		;6597
	ret			;659a
CANGREJO_ESPERA_1:		; Desde la fase 20: un fotograma
	ld a,001h		;659b
	jr CANGREJO_ESPERA_PON		;659d
ACTOR_LE_DA_LA_FRUTA:		; Estado 10: sonido 0xA0, cara de susto y se pierde la vida (E00C = 1)
	ld a,0a0h		;659f   ; El sonido de perder la vida
	call SONIDO		;65a1
	call CARA_DE_SUSTO		;65a4
	pop bc			;65a7
	ld a,001h		;65a8
	ld (0e00ch),a		;65aa
	ret			;65ad
CARA_DE_SUSTO:		; Los patrones del mono a 0x58/0x5C (los sprites 16-17 de 0x56BF, la cara de susto) o sus espejos 0xD8/0xDC segun a donde mira
	ld a,(0e109h)		;65ae   ; Bit 7 de E109 (hacia donde miraba el mono): 0x58/0x5C o sus espejos 0xD8/0xDC
	add a,a			;65b1
	ld bc,0585ch		;65b2
	jr c,CARA_DE_SUSTO_PON		;65b5
	ld bc,0d8dch		;65b7
CARA_DE_SUSTO_PON:		; Los patrones al mono
	ld a,b			;65ba
	ld (0e0b2h),a		;65bb
	ld a,c			;65be
	ld (0e0b6h),a		;65bf
	ret			;65c2

; ----------------------------------------------------------------------
; DATOS patrones_andar_derecha: Los patrones de las cuatro fases de andar
;   hacia la derecha, dos sprites por fase: (00,0C) (04,10) (00,0C) (08,14):
;   los sprites 0-2 de 0x56BF con sus detalles 3-5 (o el juego que haya
;   cargado E10E)
;   0x65c3..0x65cb  (8 bytes)
DATA_patrones_andar_derecha:
	defb 000h,00ch	; 65c3
	defb 004h,010h	; 65c5
	defb 000h,00ch	; 65c7
	defb 008h,014h	; 65c9

; ----------------------------------------------------------------------
; DATOS patrones_cangrejo: Las cuatro fases del cangrejo hacia la derecha:
;   (34,40) (30,3C) (34,40) (38,44): los sprites 6-8 de 0x56BF (que en la VRAM
;   son el 12-14) con sus ojos 9-11. Tambien las usa el mono del globo de
;   0x6D86
;   0x65cb..0x65d3  (8 bytes)
DATA_patrones_cangrejo:
	defb 034h,040h	; 65cb
	defb 030h,03ch	; 65cd
	defb 034h,040h	; 65cf
	defb 038h,044h	; 65d1

; ----------------------------------------------------------------------
; DATOS patrones_andar_izquierda: Las cuatro fases hacia la izquierda: (80,8C)
;   (84,90) (80,8C) (88,94): los sprites de 0x59FF, el mono mirando a la
;   izquierda
;   0x65d3..0x65db  (8 bytes)
DATA_patrones_andar_izquierda:
	defb 080h,08ch	; 65d3
	defb 084h,090h	; 65d5
	defb 080h,08ch	; 65d7
	defb 088h,094h	; 65d9

; ----------------------------------------------------------------------
; DATOS patrones_cangrejo_izquierda: Las cuatro fases del cangrejo hacia la
;   izquierda: (B4,C0) (B0,BC) (B4,C0) (B8,C4): los espejos de los sprites
;   6-11 de 0x56BF
;   0x65db..0x65e3  (8 bytes)
DATA_patrones_cangrejo_izquierda:
	defb 0b4h,0c0h	; 65db
	defb 0b0h,0bch	; 65dd
	defb 0b4h,0c0h	; 65df
	defb 0b8h,0c4h	; 65e1

; ----------------------------------------------------------------------
; DATOS patrones_trepar: Los dos patrones de trepar por el hueco: (48,4C)
;   hacia la derecha, (C8,CC) hacia la izquierda (los sprites 12 y 14 de
;   0x56BF, con los brazos arriba, y sus espejos)
;   0x65e3..0x65e7  (4 bytes)
DATA_patrones_trepar:
	defb 048h,04ch	; 65e3
	defb 0c8h,0cch	; 65e5

; ======================================================================
; CODIGO 0x65e7..0x66cc  (229 bytes)
; ======================================================================


TILE_A_PIXELS:		; D = (fila - 7) x 8, E = columna x 8: de la posicion de un tile a los pixels de la tarjeta que cuelga ahi
	push af			;65e7
	ld a,d			;65e8
	sub 038h		;65e9
	ld d,a			;65eb
	ex de,hl			;65ec
	add hl,hl			;65ed
	add hl,hl			;65ee
	add hl,hl			;65ef
	ld a,h			;65f0
	add a,a			;65f1
	add a,a			;65f2
	add a,a			;65f3
	ld h,a			;65f4
	ex de,hl			;65f5
	pop af			;65f6
	ret			;65f7
SIN_LLAMADAS_TILE_EN_PIXELS:		; Pone el tile A en los pixels (D, E). Solo la llama 0x6624, y a esa nadie: un pintador de plataformas que quedo sin usar (0x664F -> 0x6624 -> aqui)
	push hl			;65f8
	push de			;65f9
	push bc			;65fa
	call PIXELS_A_VRAM		;65fb
	call VPOKE		;65fe
	pop bc			;6601
	pop de			;6602
	pop hl			;6603
	ret			;6604
PIXELS_A_VRAM:		; DE = 0x3800 + (D / 8) x 32 + E / 8: la direccion en la tabla de nombres del tile que cae en los pixels (D, E)
	push af			;6605
	ld a,d			;6606
	rra			;6607
	rra			;6608
	rra			;6609
	rra			;660a
	rr e		;660b
	rra			;660d
	rr e		;660e
	rra			;6610
	rr e		;6611
	and 003h		;6613
	add a,038h		;6615
	ld d,a			;6617
	pop af			;6618
	ret			;6619
DENTRO_DE:		; Carry si |H - L| >= B: H y L son dos coordenadas y B la distancia; NC si estan a menos de B
	push bc			;661a
	ld a,h			;661b
	sub l			;661c
	jr c,DENTRO_DE_FIN		;661d
	ld c,a			;661f
	ld a,b			;6620
	sub c			;6621
DENTRO_DE_FIN:		; Fuera
	pop bc			;6622
	ret			;6623
SIN_LLAMADAS_TRAMO:		; B tiles seguidos de C desde (D, E), 8 pixels a la derecha cada uno
	push de			;6624
	push bc			;6625
	ld d,(hl)			;6626
	inc hl			;6627
	ld e,(hl)			;6628
	inc hl			;6629
	ld b,(hl)			;662a
SIN_LLAMADAS_TRAMO_BUCLE:		; Un tile
	ld a,c			;662b
	di			;662c
	call SIN_LLAMADAS_TILE_EN_PIXELS		;662d
	ei			;6630
	ld a,008h		;6631
	add a,e			;6633
	ld e,a			;6634
	djnz SIN_LLAMADAS_TRAMO_BUCLE		;6635
	pop bc			;6637
	pop de			;6638
	ret			;6639
RELLENA_RECTANGULO:		; L filas de C tiles del byte A desde la VRAM DE (una fila cada 32)
	push bc			;663a
	ld b,000h		;663b
	ld c,h			;663d
RELLENA_RECTANGULO_FILA:		; Una fila
	ld h,a			;663e
	call RELLENA_VRAM		;663f
	ex de,hl			;6642
	ld a,020h		;6643
	call HL_MAS_A		;6645
	ex de,hl			;6648
	dec l			;6649
	ld a,h			;664a
	jr nz,RELLENA_RECTANGULO_FILA		;664b
	pop bc			;664d
	ret			;664e
SIN_LLAMADAS_LISTA_DE_TRAMOS:		; Recorre una lista de (Y, X, ancho) hasta 0xFF pintando el tile C. Nadie la llama: 0x6685 hace lo mismo con las plataformas de la fase
	ld c,(hl)			;664f
SIN_LLAMADAS_LISTA_BUCLE:		; Un tramo
	inc hl			;6650
	ld a,(hl)			;6651
	cp 0ffh		;6652
	ret z			;6654
	call SIN_LLAMADAS_TRAMO		;6655
	jr SIN_LLAMADAS_LISTA_BUCLE		;6658
COLORES_DEL_PANEL:		; R7 = 1, la fuente blanca sobre azul, y los colores de los tiles 0x40-0x5F: amarillo sobre azul en el segundo tercio (0x0A00), rojo sobre azul en el primero (0x0200) y cyan sobre azul en el tercero (0x1200): TIME, HI y STAGE de distinto color
	ld a,001h		;665a
	call VDP_R7		;665c
	ld a,0f4h		;665f
	call COLOR_FUENTE		;6661
	ld de,00a00h		;6664
	ld bc,00100h		;6667
	ld a,0a4h		;666a
	call RELLENA_VRAM		;666c
	ld de,00200h		;666f
	ld bc,00100h		;6672
	ld a,094h		;6675
	call RELLENA_VRAM		;6677
	ld de,01200h		;667a
	ld bc,00100h		;667d
	ld a,074h		;6680
	jp RELLENA_VRAM		;6682
PINTA_PLATAFORMAS:		; Las plataformas de la fase (0x66F5 -> lista de Y, X, ancho hasta 0xFF) con el tile base mas (fase / 2) & 3: cuatro colores
	ld a,(0e051h)		;6685
	dec a			;6688
	and 007h		;6689
	add a,a			;668b
	ld de,066f5h		;668c
	call DE_MAS_A		;668f
	ex de,hl			;6692
	ld e,(hl)			;6693
	inc hl			;6694
	ld d,(hl)			;6695
	ex de,hl			;6696
	ld a,(hl)			;6697
	exx			;6698
	ld d,a			;6699
	ld a,(0e051h)		;669a
	rra			;669d
	and 003h		;669e
	add a,d			;66a0
	exx			;66a1
PINTA_PLATAFORMA:		; Una: la posicion a VRAM (0x6605) y C tiles
	push af			;66a2
	inc hl			;66a3
	ld a,(hl)			;66a4
	cp 0ffh		;66a5
	jr z,PINTA_PLATAFORMAS_FIN		;66a7
	ld d,(hl)			;66a9
	inc hl			;66aa
	ld e,(hl)			;66ab
	call PIXELS_A_VRAM		;66ac
	inc hl			;66af
	ld c,(hl)			;66b0
	ld b,000h		;66b1
	pop af			;66b3
	call RELLENA_VRAM		;66b4
	jr PINTA_PLATAFORMA		;66b7
PINTA_PLATAFORMAS_FIN:		; Fuera
	pop af			;66b9
	ret			;66ba
PINTA_RECUADRO:		; Cinco bytes en HL: ancho, alto, tile, y la VRAM en dos bytes (el alto delante); y a 0x663A
	push hl			;66bb
	ld d,(hl)			;66bc
	inc hl			;66bd
	ld e,(hl)			;66be
	inc hl			;66bf
	ld a,(hl)			;66c0
	inc hl			;66c1
	push de			;66c2
	ld d,(hl)			;66c3
	inc hl			;66c4
	ld e,(hl)			;66c5
	pop hl			;66c6
	call RELLENA_RECTANGULO		;66c7
	pop hl			;66ca
	ret			;66cb

; ----------------------------------------------------------------------
; DATOS rotulo_time: "TIME" en la fila 2, columna 26, y "00:00" (0x62 es el
;   tile de los dos puntos) en la 3
;   0x66cc..0x66db  (15 bytes)
DATA_rotulo_time:
	defb 05ah,038h,054h,049h,04dh,045h,0feh,07ah,038h,030h,030h,062h,030h,030h,0ffh	; 66cc  Z8TIME.z800b00.

; ----------------------------------------------------------------------
; DATOS rotulo_konami_panel: El "©Konami" (tiles 0x3A-0x3F) en la fila 22,
;   columna 25, y "1984" en la 23
;   0x66db..0x66eb  (16 bytes)
DATA_rotulo_konami_panel:
	defb 0d9h,03ah,03ah,03bh,03ch,03dh,03eh,03fh,0feh,0fah,03ah,031h,039h,038h,034h,0ffh	; 66db  .::;<=>?..:1984.

; ----------------------------------------------------------------------
; DATOS recuadro_game_over: Rectangulo para 0x66BB: 24 filas x 25 columnas del
;   tile 0 desde 0x3800: borra toda la zona de juego para el GAME OVER
;   0x66eb..0x66f0  (5 bytes)
DATA_recuadro_game_over:
	defb 019h,018h,000h,038h,000h	; 66eb

; ----------------------------------------------------------------------
; DATOS recuadro_del_panel: Rectangulo para 0x66BB: 7 columnas x 22 filas del
;   tile 0x60 (azul) desde 0x3859 (fila 2, columna 25): el panel de la
;   derecha; la columna 24 y las filas 0-1 quedan negras
;   0x66f0..0x66f5  (5 bytes)
DATA_recuadro_del_panel:
	defb 007h,016h,060h,038h,059h	; 66f0

; ----------------------------------------------------------------------
; DATOS punteros_a_plataformas: Ocho punteros a las plataformas de cada fase
;   ((fase - 1) & 7)
;   0x66f5..0x6705  (16 bytes)
DATA_punteros_a_plataformas:
	defw 06705h	; 66f5  -> DATA_plataformas_por_fase
	defw 06719h	; 66f7
	defw 0672dh	; 66f9
	defw 06744h	; 66fb
	defw 0675bh	; 66fd
	defw 06772h	; 66ff
	defw 06789h	; 6701
	defw 067a6h	; 6703

; ----------------------------------------------------------------------
; DATOS plataformas_por_fase: Ocho listas: el tile base (5, para las cuatro
;   barras 5-8) y las plataformas como (Y, X, ancho en tiles) hasta 0xFF; la
;   primera es siempre el suelo (0xB8) y la segunda la de arriba (0x10)
;   0x6705..0x67c2  (189 bytes)
DATA_plataformas_por_fase:
	defb 005h,0b8h,008h,018h,010h,008h,01fh,048h,008h,00fh,048h,0a0h,005h,080h,008h,009h	; 6705  .......H..H.....
	defb 080h,070h,00bh,0ffh,005h,010h,008h,01fh,048h,008h,008h,048h,068h,00ch,080h,008h	; 6715  .p......H..Hh...
	defb 00fh,080h,0a0h,005h,0b8h,008h,018h,0ffh,005h,010h,008h,01fh,0b8h,008h,018h,048h	; 6725  ...............H
	defb 008h,00bh,048h,080h,009h,080h,008h,007h,080h,060h,004h,080h,0a0h,005h,0ffh,005h	; 6735  ..H......`......
	defb 010h,008h,01fh,0b8h,008h,018h,048h,008h,003h,048h,040h,007h,048h,098h,006h,080h	; 6745  ......H..H@.H...
	defb 008h,007h,080h,060h,00dh,0ffh,005h,010h,008h,01fh,0b8h,008h,018h,048h,008h,006h	; 6755  ...`.........H..
	defb 048h,050h,006h,048h,098h,006h,080h,008h,00ah,080h,078h,00ah,0ffh,005h,010h,008h	; 6765  HP.H......x.....
	defb 01fh,0b8h,008h,018h,048h,008h,00ah,048h,078h,00ah,080h,008h,007h,080h,060h,003h	; 6775  ....H..Hx.....`.
	defb 080h,098h,006h,0ffh,005h,010h,008h,01fh,0b8h,008h,018h,048h,008h,007h,048h,058h	; 6785  ...........H..HX
	defb 003h,048h,088h,008h,080h,008h,004h,080h,040h,004h,080h,078h,003h,080h,0b0h,003h	; 6795  .H......@..x....
	defb 0ffh,005h,010h,008h,01fh,0b8h,008h,018h,048h,008h,003h,048h,038h,003h,048h,068h	; 67a5  ........H..H8.Hh
	defb 003h,048h,0a0h,005h,080h,008h,005h,080h,048h,003h,080h,078h,003h	; 67b5  .H......H..x.

; ----------------------------------------------------------------------
; DATOS sobras_67C2: Ocho listas de X (Y fija por fila) acabadas en 0xFF,
;   alineadas con las ocho fases: 38 58 70 A0 A8 38... Nadie las apunta:
;   sobras de un reparto de flores o frutas anterior
;   0x67c2..0x6806  (68 bytes)
DATA_sobras_67C2:
	defb 080h,0a8h,004h,0ffh,038h,058h,070h,0a0h,0a8h,038h,0ffh,000h,070h,060h,0a8h,020h	; 67c2  ....8Xp..8..p`. 
	defb 0a8h,070h,0ffh,000h,038h,098h,0a8h,030h,0a8h,078h,0ffh,000h,038h,050h,070h,098h	; 67d2  .p..8..0.x..8Pp.
	defb 0a8h,088h,0ffh,000h,038h,018h,070h,090h,0a8h,050h,0ffh,000h,038h,038h,0a8h,078h	; 67e2  ....8.p..P..88.x
	defb 0a8h,0a8h,0ffh,000h,038h,0a8h,0a8h,038h,0a8h,0a8h,0ffh,000h,070h,0b8h,0a8h,028h	; 67f2  ....8..8....p..(
	defb 0a8h,068h,0ffh,000h	; 6802

; ----------------------------------------------------------------------
; DATOS frutas_por_fase: Ocho fases x 8 frutas x (Y, X, patron, color): los
;   sprites 10-17 que 0x7E85 copia a E0D8. Cuelgan en Y = 0x18, 0x50 y 0x88;
;   0xF8 rojo es la manzana, 0x78 amarillo el platano, 0x7C magenta las uvas
;   0x6806..0x6906  (256 bytes)
DATA_frutas_por_fase:
	defb 018h,008h,0f8h,006h	; 6806
	defb 018h,068h,07ch,00dh	; 680a
	defb 050h,020h,078h,00ah	; 680e
	defb 050h,068h,0f8h,006h	; 6812
	defb 050h,0b8h,078h,00ah	; 6816
	defb 088h,028h,07ch,00dh	; 681a
	defb 088h,090h,078h,00ah	; 681e
	defb 050h,0a0h,0f8h,006h	; 6822
	defb 018h,040h,078h,00ah	; 6826
	defb 018h,078h,0f8h,006h	; 682a
	defb 050h,008h,07ch,00dh	; 682e
	defb 050h,080h,0f8h,006h	; 6832
	defb 050h,098h,078h,00ah	; 6836
	defb 088h,048h,0f8h,006h	; 683a
	defb 088h,0b0h,07ch,00dh	; 683e
	defb 088h,010h,078h,00ah	; 6842
	defb 018h,008h,0f8h,006h	; 6846
	defb 018h,038h,078h,00ah	; 684a
	defb 088h,070h,07ch,00dh	; 684e
	defb 050h,038h,07ch,00dh	; 6852
	defb 050h,098h,0f8h,006h	; 6856
	defb 088h,010h,0f8h,006h	; 685a
	defb 088h,0a0h,078h,00ah	; 685e
	defb 088h,030h,07ch,00dh	; 6862
	defb 018h,010h,078h,00ah	; 6866
	defb 018h,070h,0f8h,006h	; 686a
	defb 050h,040h,07ch,00dh	; 686e
	defb 050h,058h,078h,00ah	; 6872
	defb 088h,030h,078h,00ah	; 6876
	defb 088h,068h,07ch,00dh	; 687a
	defb 088h,0b0h,0f8h,006h	; 687e
	defb 050h,0b8h,07ch,00dh	; 6882
	defb 018h,030h,0f8h,006h	; 6886
	defb 018h,098h,07ch,00dh	; 688a
	defb 050h,018h,07ch,00dh	; 688e
	defb 050h,050h,0f8h,006h	; 6892
	defb 050h,0a0h,078h,00ah	; 6896
	defb 088h,040h,078h,00ah	; 689a
	defb 088h,0a0h,07ch,00dh	; 689e
	defb 018h,070h,078h,00ah	; 68a2
	defb 018h,028h,078h,00ah	; 68a6
	defb 018h,050h,0f8h,006h	; 68aa
	defb 018h,0a0h,07ch,00dh	; 68ae
	defb 050h,038h,07ch,00dh	; 68b2
	defb 050h,0b8h,0f8h,006h	; 68b6
	defb 088h,068h,078h,00ah	; 68ba
	defb 088h,0b8h,07ch,00dh	; 68be
	defb 050h,008h,0f8h,006h	; 68c2
	defb 018h,068h,0f8h,006h	; 68c6
	defb 018h,020h,078h,00ah	; 68ca
	defb 050h,020h,078h,00ah	; 68ce
	defb 050h,058h,0f8h,006h	; 68d2
	defb 050h,088h,07ch,00dh	; 68d6
	defb 088h,050h,078h,00ah	; 68da
	defb 088h,0b8h,0f8h,006h	; 68de
	defb 050h,0a8h,07ch,00dh	; 68e2
	defb 018h,008h,0f8h,006h	; 68e6
	defb 018h,060h,078h,00ah	; 68ea
	defb 050h,0b8h,0f8h,006h	; 68ee
	defb 050h,040h,07ch,00dh	; 68f2
	defb 050h,070h,07ch,00dh	; 68f6
	defb 088h,020h,078h,00ah	; 68fa
	defb 088h,0a8h,0f8h,006h	; 68fe
	defb 018h,020h,07ch,00dh	; 6902

; ======================================================================
; CODIGO 0x6906..0x6a0f  (265 bytes)
; ======================================================================


PINTA_BLOQUE:		; B filas x C columnas de tiles desde HL en los pixels (D, E)
	push bc			;6906
	push de			;6907
PINTA_BLOQUE_TILE:		; Un tile
	push bc			;6908
	push de			;6909
	call PIXELS_A_VRAM		;690a
	ld a,(hl)			;690d
	call VPOKE		;690e
	pop de			;6911
	pop bc			;6912
	ld a,e			;6913
	add a,008h		;6914
	ld e,a			;6916
	inc hl			;6917
	dec c			;6918
	jr nz,PINTA_BLOQUE_TILE		;6919
	pop de			;691b
	ld a,d			;691c
	add a,008h		;691d
	ld d,a			;691f
	pop bc			;6920
	djnz PINTA_BLOQUE		;6921
	ret			;6923
HAY_SUELO:		; NC si en la fase hay una plataforma justo debajo de (B, C): a Y + 0x10 y con X entre su principio y su fin (0x661A con el ancho x 8 + 4)
	push de			;6924
	push bc			;6925
	ld a,(0e051h)		;6926
	dec a			;6929
	and 007h		;692a
	add a,a			;692c
	ld de,066f5h		;692d
	call DE_MAS_A		;6930
	ex de,hl			;6933
	ld e,(hl)			;6934
	inc hl			;6935
	ld d,(hl)			;6936
	ex de,hl			;6937
	inc hl			;6938
	ld a,b			;6939
	add a,010h		;693a
	ld b,a			;693c
HAY_SUELO_BUSCA:		; Recorre las plataformas de la fase
	ld a,(hl)			;693d
	cp 0ffh		;693e
	jr z,HAY_SUELO_NO		;6940
	and 0f8h		;6942
	cp b			;6944
	jr z,HAY_SUELO_X		;6945
	inc hl			;6947
	inc hl			;6948
HAY_SUELO_SIGUIENTE:		; La plataforma siguiente
	inc hl			;6949
	jr HAY_SUELO_BUSCA		;694a
HAY_SUELO_X:		; Misma fila: la X del actor mas 10 contra el tramo
	ld a,c			;694c
	add a,00ah		;694d
	ld d,a			;694f
	inc hl			;6950
	ld e,(hl)			;6951
	inc hl			;6952
	ld a,(hl)			;6953
	add a,a			;6954
	add a,a			;6955
	add a,a			;6956
	add a,004h		;6957
	push bc			;6959
	ld b,a			;695a
	ex de,hl			;695b
	call DENTRO_DE		;695c
	ex de,hl			;695f
	pop bc			;6960
	jr c,HAY_SUELO_SIGUIENTE		;6961
	or a			;6963
	pop bc			;6964
	pop de			;6965
	ret			;6966
HAY_SUELO_NO:		; Carry: no hay
	scf			;6967
	pop bc			;6968
	pop de			;6969
	ret			;696a
HAY_PLATAFORMA_ARRIBA:		; Carry si hay una plataforma a menos de 0x11 pixels por encima de (B, C) que cubra la X (mas 11): para saber si se puede subir por ahi
	push bc			;696b
	ld a,(0e051h)		;696c
	dec a			;696f
	and 007h		;6970
	add a,a			;6972
	ld hl,066f5h		;6973
	call HL_MAS_A		;6976
	ld e,(hl)			;6979
	inc hl			;697a
	ld d,(hl)			;697b
	inc de			;697c
HAY_PLATAFORMA_ARRIBA_BUSCA:		; Una plataforma
	ld a,(de)			;697d
	cp 0ffh		;697e
	jr z,HAY_PLATAFORMA_ARRIBA_NO		;6980
	ld l,a			;6982
	ld a,b			;6983
	add a,00fh		;6984
	ld h,a			;6986
	push bc			;6987
	ld b,011h		;6988
	call DENTRO_DE		;698a
	pop bc			;698d
	jr nc,HAY_PLATAFORMA_ARRIBA_X		;698e
	inc de			;6990
	inc de			;6991
HAY_PLATAFORMA_ARRIBA_SIGUIENTE:		; La siguiente
	inc de			;6992
	jr HAY_PLATAFORMA_ARRIBA_BUSCA		;6993
HAY_PLATAFORMA_ARRIBA_X:		; Misma altura: la X
	inc de			;6995
	ld a,(de)			;6996
	ld l,a			;6997
	ld a,c			;6998
	add a,00bh		;6999
	ld h,a			;699b
	push bc			;699c
	inc de			;699d
	ld a,(de)			;699e
	add a,a			;699f
	add a,a			;69a0
	add a,a			;69a1
	add a,006h		;69a2
	ld b,a			;69a4
	call DENTRO_DE		;69a5
	pop bc			;69a8
	jr c,HAY_PLATAFORMA_ARRIBA_SIGUIENTE		;69a9
	pop bc			;69ab
	ret			;69ac
HAY_PLATAFORMA_ARRIBA_NO:		; Carry: no hay
	scf			;69ad
	pop bc			;69ae
	ret			;69af

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA COLISION CON LOS CANGREJOS. NC si un cangrejo vivo (estado ni 0
; ni 9) esta a menos de 16 pixels en X y de (0x6A0F + 16) en Y del
; mono; carry si no. No se mira si el mono esta atontado (10) o ya ha
; entregado la respuesta (0x33).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
COLISION_CANGREJOS:		; Carry si ningun cangrejo toca al mono
	push bc			;69b0
	ld a,(0e10ch)		;69b1
	cp 00ah		;69b4
	jr z,COLISION_NO		;69b6
	ld a,(0e108h)		;69b8
	cp 033h		;69bb
	jr z,COLISION_NO		;69bd
	ld ix,0e0b0h		;69bf
	ld d,(ix+000h)		;69c3
	ld e,(ix+001h)		;69c6
	exx			;69c9
	ld b,003h		;69ca
	ld de,00008h		;69cc
	add ix,de		;69cf
COLISION_SIGUIENTE:		; Los tres, ocho bytes cada uno
	exx			;69d1
	ld a,(ix+05ch)		;69d2
	or a			;69d5
	jr z,COLISION_OTRO		;69d6
	cp 009h		;69d8
	jr nz,COLISION_MIRA		;69da
COLISION_OTRO:		; El cangrejo siguiente
	exx			;69dc
	add ix,de		;69dd
	djnz COLISION_SIGUIENTE		;69df
	exx			;69e1
COLISION_NO:		; Carry: ninguno
	scf			;69e2
	pop bc			;69e3
	ret			;69e4
COLISION_MIRA:		; X a menos de 16 y Y a menos de (0x6A0F[tipo] + 16)
	ld a,e			;69e5
	add a,008h		;69e6
	ld h,a			;69e8
	ld l,(ix+001h)		;69e9
	ld b,010h		;69ec
	call DENTRO_DE		;69ee
	jr c,COLISION_OTRO		;69f1
	ld hl,06a0fh		;69f3
	ld a,(ix+05bh)		;69f6
	and 00fh		;69f9
	call HL_MAS_A		;69fb
	ld a,(hl)			;69fe
	add a,010h		;69ff
	ld b,a			;6a01
	ld a,d			;6a02
	add a,(hl)			;6a03
	ld h,a			;6a04
	ld l,(ix+000h)		;6a05
	call DENTRO_DE		;6a08
	jr c,COLISION_OTRO		;6a0b
	pop bc			;6a0d
	ret			;6a0e

; ----------------------------------------------------------------------
; DATOS holgura_por_tipo: Dieciseis veces 8: la holgura vertical de la
;   colision por tipo de actor (todos igual)
;   0x6a0f..0x6a1f  (16 bytes)
DATA_holgura_por_tipo:
	defb 008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h	; 6a0f  ................

; ======================================================================
; CODIGO 0x6a1f..0x6b42  (291 bytes)
; ======================================================================


HAY_TARJETA_ENCIMA:		; Carry si NO hay tarjeta: el mono (tipo 0), sin tarjeta suelta (E0F8 = 0xE1), mira el tile a (Y + 7, X + 8): 1 o 2 son las dos mitades del canto (0x5082) de una tarjeta metida
	push bc			;6a1f
	ld a,(0e0f8h)		;6a20
	cp 0e1h		;6a23
	jr nz,HAY_TARJETA_ENCIMA_NO		;6a25
	ld a,(ix+05bh)		;6a27
	and 00fh		;6a2a
	jr nz,HAY_TARJETA_ENCIMA_NO		;6a2c
	ld a,b			;6a2e
	add a,007h		;6a2f
	ld d,a			;6a31
	ld a,c			;6a32
	add a,008h		;6a33
	ld e,a			;6a35
	call PIXELS_A_VRAM		;6a36
	call VPEEK		;6a39
	cp 001h		;6a3c
	pop bc			;6a3e
	ret z			;6a3f
	cp 002h		;6a40
	ret z			;6a42
	scf			;6a43
	ret			;6a44
HAY_TARJETA_ENCIMA_NO:		; Carry: no
	pop bc			;6a45
	scf			;6a46
	ret			;6a47
ACTOR_BC:		; B = Y, C = X del actor
	ld b,(ix+000h)		;6a48
	ld c,(ix+001h)		;6a4b
	ret			;6a4e
ACTOR_TOCA_FRUTA:		; Si el mono ya entrego la respuesta no mira; con +0x5E = 2 (lleva la tarjeta) tampoco; si no, 0x6A5B
	ld a,(0e108h)		;6a4f
	cp 033h		;6a52
	ret z			;6a54
TOCA_FRUTA_SIN_TARJETA:		; Con la tarjeta (2) no
	ld a,(ix+05eh)		;6a55
	cp 002h		;6a58
	ret z			;6a5a
TOCA_ALGUNA_FRUTA:		; Recorre los 8 sprites de fruta (E0D8): carry y D = indice, E = 1 (quieta) o 0 (en el aire) si alguna esta a menos de 0x16 pixels en las dos coordenadas y no esta gastada (bit 7); a un cangrejo no le da la que tiro el (bit 6)
	push bc			;6a5b
	ld b,000h		;6a5c
	exx			;6a5e
	ld de,0e0d8h		;6a5f
TOCA_FRUTA_BUCLE:		; Una fruta
	call ACTOR_BC		;6a62
	ld hl,00b0bh		;6a65
	add hl,bc			;6a68
	ld b,h			;6a69
	ld c,l			;6a6a
	ld a,(de)			;6a6b
	ld l,a			;6a6c
	inc de			;6a6d
	ld h,b			;6a6e
	ld b,016h		;6a6f
	call DENTRO_DE		;6a71
	jr c,TOCA_SIGUIENTE_FRUTA		;6a74
	ld a,(de)			;6a76
	ld l,a			;6a77
	ld h,c			;6a78
	ld b,016h		;6a79
	call DENTRO_DE		;6a7b
	jr c,TOCA_SIGUIENTE_FRUTA		;6a7e
	ld hl,0e260h		;6a80
	exx			;6a83
	ld a,b			;6a84
	exx			;6a85
	add a,a			;6a86
	call HL_MAS_A		;6a87
	ld a,(hl)			;6a8a
	bit 7,a		;6a8b
	jr nz,TOCA_SIGUIENTE_FRUTA		;6a8d
	and 003h		;6a8f
	jr nz,TOCA_FRUTA_EN_EL_AIRE		;6a91
	exx			;6a93
	ld d,b			;6a94
	ld e,001h		;6a95
	scf			;6a97
	pop bc			;6a98
	ret			;6a99
TOCA_FRUTA_EN_EL_AIRE:		; En el aire: al cangrejo no le da la que tiro el (bit 6)
	ld a,(ix+05bh)		;6a9a
	and 00fh		;6a9d
	jr z,TOCA_FRUTA_EN_EL_AIRE_SI		;6a9f
	bit 6,(hl)		;6aa1
	jr nz,TOCA_SIGUIENTE_FRUTA		;6aa3
TOCA_FRUTA_EN_EL_AIRE_SI:		; D = indice, E = 0
	exx			;6aa5
	ld d,b			;6aa6
	ld e,000h		;6aa7
	scf			;6aa9
	pop bc			;6aaa
	ret			;6aab
TOCA_SIGUIENTE_FRUTA:		; La siguiente de las ocho
	inc de			;6aac
	inc de			;6aad
	inc de			;6aae
	exx			;6aaf
	inc b			;6ab0
	ld a,b			;6ab1
	cp 008h		;6ab2
	exx			;6ab4
	jr nz,TOCA_FRUTA_BUCLE		;6ab5
	or a			;6ab7
	exx			;6ab8
	pop bc			;6ab9
	ret			;6aba
TOCA_LA_TARJETA_CAIDA:		; NC si el mono, sin cargar (E10E = 0), esta a la altura exacta de la tarjeta caida (E0F8) y a menos de 16 pixels en X
	ld a,(0e10eh)		;6abb
	or a			;6abe
	jr nz,TOCA_TARJETA_NO		;6abf
	ld hl,0e0b0h		;6ac1
	ld de,0e0f8h		;6ac4
	ld b,(hl)			;6ac7
	ld a,(de)			;6ac8
	cp b			;6ac9
	jr nz,TOCA_TARJETA_NO		;6aca
	inc hl			;6acc
	inc de			;6acd
	ld a,008h		;6ace
	add a,(hl)			;6ad0
	ld h,a			;6ad1
	ld a,(de)			;6ad2
	ld l,a			;6ad3
	ld b,010h		;6ad4
	jp DENTRO_DE		;6ad6
TOCA_TARJETA_NO:		; Carry: no
	scf			;6ad9
	ret			;6ada
TOCA_AL_PROFESOR:		; NC si el mono con la tarjeta (E10E = 2) esta a menos de 0x20 pixels del profesor (E0D0) en Y y en X + 12
	ld a,(0e10eh)		;6adb
	cp 002h		;6ade
	jr nz,TOCA_PROFESOR_NO		;6ae0
	ld hl,0e0b0h		;6ae2
	ld de,0e0d0h		;6ae5
	ld a,(hl)			;6ae8
	push hl			;6ae9
	ld h,a			;6aea
	ld a,(de)			;6aeb
	ld l,a			;6aec
	ld b,020h		;6aed
	call DENTRO_DE		;6aef
	pop hl			;6af2
	ret c			;6af3
	inc hl			;6af4
	inc de			;6af5
	ld a,00ch		;6af6
	add a,(hl)			;6af8
	ld h,a			;6af9
	ld a,(de)			;6afa
	ld l,a			;6afb
	ld b,020h		;6afc
	jp DENTRO_DE		;6afe
TOCA_PROFESOR_NO:		; Carry: no
	scf			;6b01
	ret			;6b02
PINTA_FLORES:		; Las tres flores (tile 0x15) de la fase, una por tabla (0x6B42, 0x6B52, 0x6B62), con la VRAM escrita con el byte alto delante
	ld a,(0e051h)		;6b03
	dec a			;6b06
	and 007h		;6b07
	add a,a			;6b09
	ld hl,06b42h		;6b0a
	call HL_MAS_A		;6b0d
	ld d,(hl)			;6b10
	inc hl			;6b11
	ld e,(hl)			;6b12
	ld a,015h		;6b13
	call VPOKE		;6b15
	ld a,(0e051h)		;6b18
	dec a			;6b1b
	and 007h		;6b1c
	add a,a			;6b1e
	ld hl,06b52h		;6b1f
	call HL_MAS_A		;6b22
	ld d,(hl)			;6b25
	inc hl			;6b26
	ld e,(hl)			;6b27
	ld a,015h		;6b28
	call VPOKE		;6b2a
	ld a,(0e051h)		;6b2d
	dec a			;6b30
	and 007h		;6b31
	add a,a			;6b33
	ld hl,06b62h		;6b34
	call HL_MAS_A		;6b37
	ld d,(hl)			;6b3a
	inc hl			;6b3b
	ld e,(hl)			;6b3c
	ld a,015h		;6b3d
	jp VPOKE		;6b3f

; ----------------------------------------------------------------------
; DATOS flores_1: La VRAM de la primera flor de cada fase, ocho parejas con el
;   byte alto delante (0x3908 = fila 8, columna 8)
;   0x6b42..0x6b52  (16 bytes)
DATA_flores_1:
	defb 039h,008h	; 6b42
	defb 039h,012h	; 6b44
	defb 039h,006h	; 6b46
	defb 039h,015h	; 6b48
	defb 039h,0e7h	; 6b4a
	defb 039h,014h	; 6b4c
	defb 039h,00ch	; 6b4e
	defb 039h,008h	; 6b50

; ----------------------------------------------------------------------
; DATOS flores_2: La segunda, igual
;   0x6b52..0x6b62  (16 bytes)
DATA_flores_2:
	defb 039h,0e3h	; 6b52
	defb 039h,0e5h	; 6b54
	defb 039h,015h	; 6b56
	defb 039h,0f2h	; 6b58
	defb 039h,0f6h	; 6b5a
	defb 039h,0e4h	; 6b5c
	defb 039h,0e9h	; 6b5e
	defb 039h,0eah	; 6b60

; ----------------------------------------------------------------------
; DATOS flores_3: La tercera, igual
;   0x6b62..0x6b72  (16 bytes)
DATA_flores_3:
	defb 03ah,0d4h	; 6b62
	defb 03ah,0d4h	; 6b64
	defb 03ah,0ceh	; 6b66
	defb 03ah,0c5h	; 6b68
	defb 03ah,0d0h	; 6b6a
	defb 03ah,0cch	; 6b6c
	defb 03ah,0cfh	; 6b6e
	defb 039h,0f6h	; 6b70

; ----------------------------------------------------------------------
; DATOS rotulos_del_panel: "HI" en la fila 5, columna 26; "STAGE" en la 19,
;   columna 25; "1UP" en la 8, columna 26
;   0x6b72..0x6b85  (19 bytes)
DATA_rotulos_del_panel:
	defb 0bah,038h,048h,049h,0feh,079h,03ah,053h,054h,041h,047h,045h,0feh,01ah,039h,031h	; 6b72  .8HI.y:STAGE..91
	defb 055h,050h,0ffh	; 6b82

; ----------------------------------------------------------------------
; DATOS rotulo_2up: "2UP" en la fila 11, columna 26
;   0x6b85..0x6b8b  (6 bytes)
DATA_rotulo_2up:
	defb 07ah,039h,032h,055h,050h,0ffh	; 6b85

; ----------------------------------------------------------------------
; DATOS rotulo_konami_1984: "©Konami 1984" (tiles 0x3A-0x3F) en la fila 8,
;   columna 11, bajo el titulo
;   0x6b8b..0x6b99  (14 bytes)
DATA_rotulo_konami_1984:
	defb 00bh,039h,03ah,03bh,03ch,03dh,03eh,03fh,000h,031h,039h,038h,034h,0ffh	; 6b8b  .9:;<=>?.1984.

; ----------------------------------------------------------------------
; DATOS menu_play_select: "PLAY SELECT" en la fila 13 y las cuatro opciones en
;   las filas 16, 18, 20 y 22 desde la columna 4: "1-key 1PLAYER  with
;   JOYSTICK"... (0x40 es el guion, 0x5C-0x5D "key" y 0x5E-0x5F "with")
;   0x6b99..0x6c17  (126 bytes)
DATA_menu_play_select:
	defb 0abh,039h,050h,04ch,041h,059h,000h,053h,045h,04ch,045h,043h,054h,0feh,004h,03ah	; 6b99  .9PLAY.SELECT..:
	defb 031h,040h,05ch,05dh,000h,031h,050h,04ch,041h,059h,045h,052h,000h,000h,05eh,05fh	; 6ba9  1@\].1PLAYER..^_
	defb 000h,04ah,04fh,059h,053h,054h,049h,043h,04bh,0feh,044h,03ah,032h,040h,05ch,05dh	; 6bb9  .JOYSTICK.D:2@\]
	defb 000h,032h,050h,04ch,041h,059h,045h,052h,053h,000h,05eh,05fh,000h,04ah,04fh,059h	; 6bc9  .2PLAYERS.^_.JOY
	defb 053h,054h,049h,043h,04bh,0feh,084h,03ah,033h,040h,05ch,05dh,000h,031h,050h,04ch	; 6bd9  STICK..:3@\].1PL
	defb 041h,059h,045h,052h,000h,000h,05eh,05fh,000h,04bh,045h,059h,042h,04fh,041h,052h	; 6be9  AYER..^_.KEYBOAR
	defb 044h,0feh,0c4h,03ah,034h,040h,05ch,05dh,000h,032h,050h,04ch,041h,059h,045h,052h	; 6bf9  D..:4@\].2PLAYER
	defb 053h,000h,05eh,05fh,000h,04bh,045h,059h,042h,04fh,041h,052h,044h,0ffh	; 6c09  S.^_.KEYBOARD.

; ----------------------------------------------------------------------
; DATOS rotulo_game_over: "GAME OVER" en la fila 13, columna 9 (0x60 azul en
;   medio); sigue con "PLAYER"
;   0x6c17..0x6c23  (12 bytes)
DATA_rotulo_game_over:
	defb 0a9h,039h,047h,041h,04dh,045h,060h,04fh,056h,045h,052h,0feh	; 6c17  .9GAME`OVER.

; ----------------------------------------------------------------------
; DATOS rotulo_player: "PLAYER" en la fila 11, columna 10 (el numero lo pone
;   0x4666)
;   0x6c23..0x6c2c  (9 bytes)
DATA_rotulo_player:
	defb 06ah,039h,050h,04ch,041h,059h,045h,052h,0ffh	; 6c23  j9PLAYER.

; ----------------------------------------------------------------------
; DATOS rotulo_video_cartridge: "- VIDEO CARTRIDGE -" en la fila 11, columna 6
;   0x6c2c..0x6c42  (22 bytes)
DATA_rotulo_video_cartridge:
	defb 066h,039h,040h,000h,056h,049h,044h,045h,04fh,000h,043h,041h,052h,054h,052h,049h	; 6c2c  f9@.VIDEO.CARTRI
	defb 044h,047h,045h,000h,040h,0ffh	; 6c3c

; ======================================================================
; CODIGO 0x6c42..0x6cc2  (128 bytes)
; ======================================================================


SUBE_LOGO_KONAMI:		; Una fila mas arriba: pinta las tres filas del KONAMI (3, 11 y 12 tiles desde 0x16) desde la columna 10 y borra la de debajo; E00A cuenta las que faltan
	ld hl,(0e00eh)		;6c42
	ld de,00020h		;6c45
	add hl,de			;6c48
	ld (0e00eh),hl		;6c49
	ex de,hl			;6c4c
	or a			;6c4d
	ld hl,03aaah		;6c4e   ; La fila de arriba: 0x3AAA (fila 21, columna 10) menos lo que ha subido
	sbc hl,de		;6c51
	ex de,hl			;6c53
	ld a,016h		;6c54
	ld b,003h		;6c56
	call PINTA_TILES_SEGUIDOS		;6c58
	ld b,00bh		;6c5b
	call PINTA_TILES_SEGUIDOS		;6c5d
	ld b,00ch		;6c60
	call PINTA_TILES_SEGUIDOS		;6c62
	ld bc,0000ch		;6c65
	xor a			;6c68
	call RELLENA_VRAM		;6c69
	ld hl,0e00ah		;6c6c
	dec (hl)			;6c6f
	ret			;6c70
PINTA_TILES_SEGUIDOS:		; B tiles consecutivos desde A en la VRAM DE y baja una fila
	push de			;6c71
PINTA_TILES_SEGUIDOS_BUCLE:		; Uno
	call VPOKE		;6c72
	inc de			;6c75
	inc a			;6c76
	djnz PINTA_TILES_SEGUIDOS_BUCLE		;6c77
	pop de			;6c79
	ld hl,00020h		;6c7a
	add hl,de			;6c7d
	ex de,hl			;6c7e
	ret			;6c7f
SIN_LLAMADAS_RLE_CON_DIRECCION:		; Entrada a RLE_A_VRAM que lee la direccion de la VRAM delante de los datos, como en otros cartuchos de Konami; aqui nadie la usa
	ld e,(hl)			;6c80
	inc hl			;6c81
	ld d,(hl)			;6c82
	inc hl			;6c83
RLE_A_VRAM:		; Descomprime HL en la VRAM DE: 0 fin; n<0x80 repite n veces el byte siguiente; n>=0x80 copia n&0x7F bytes tal cual
	di			;6c84
	call VDP_DIRECCION		;6c85
RLE_SIGUIENTE:		; El bucle
	ld a,(hl)			;6c88
	inc hl			;6c89
	or a			;6c8a
	ret z			;6c8b
	bit 7,a		;6c8c
	jr nz,RLE_TAL_CUAL		;6c8e
	ld b,a			;6c90
	ld a,(hl)			;6c91
	inc hl			;6c92
RLE_REPITE:		; B veces el mismo byte
	out (098h),a		;6c93
	nop			;6c95
	nop			;6c96
	djnz RLE_REPITE		;6c97
	jr RLE_SIGUIENTE		;6c99
RLE_TAL_CUAL:		; A&0x7F bytes seguidos
	res 7,a		;6c9b
	ld c,a			;6c9d
	ld b,000h		;6c9e
	call COPIA_A_VRAM_YA		;6ca0
	add hl,bc			;6ca3
	jr RLE_SIGUIENTE		;6ca4
FLECHA_ROJA:		; Mientras el mono lleva la tarjeta (bit 1 de E270): cada 8 fotogramas la flecha de 2x2 (0x6CC2) o nada en la fila 6, columna 23
	ld a,(0e270h)		;6ca6
	bit 1,a		;6ca9
	ret z			;6cab
	ld a,(0e003h)		;6cac
	and 008h		;6caf
	ld hl,06cc2h		;6cb1
	jr nz,FLECHA_ROJA_PINTA		;6cb4
	ld hl,078dbh		;6cb6
FLECHA_ROJA_PINTA:		; El bloque de 2x2 en la fila 6, columna 23
	ld bc,00202h		;6cb9
	ld de,030b8h		;6cbc
	jp PINTA_BLOQUE		;6cbf

; ----------------------------------------------------------------------
; DATOS flecha_roja: El bloque de 2x2 de la flecha que apunta al profesor: 09
;   0B / 0A 0C
;   0x6cc2..0x6cc6  (4 bytes)
DATA_flecha_roja:
	defb 009h,00bh,00ah,00ch	; 6cc2

; ======================================================================
; CODIGO 0x6cc6..0x6d76  (176 bytes)
; ======================================================================


RELOJ:		; Cada 64 fotogramas un segundo menos (BCD, los minutos en E056), y se pinta
	ld hl,0e056h		;6cc6
	ld c,(hl)			;6cc9
	dec hl			;6cca
	ld a,(hl)			;6ccb
	or c			;6ccc
	ret z			;6ccd
	ld a,(0e003h)		;6cce
	and 03fh		;6cd1
	ret nz			;6cd3
RELOJ_RESTA:		; Un segundo menos: de 00 pasa a 59 y un minuto menos
	ld a,(hl)			;6cd4
	and a			;6cd5
	jr nz,RELOJ_RESTA_DAA		;6cd6
	ld a,060h		;6cd8
	dec c			;6cda
RELOJ_RESTA_DAA:		; Un segundo menos en BCD
	dec a			;6cdb
	daa			;6cdc
	ld (hl),a			;6cdd
	inc hl			;6cde
	ld (hl),c			;6cdf
PINTA_RELOJ:		; Minutos y segundos en la fila 3, columna 26 (con los dos puntos en medio)
	ld b,001h		;6ce0
	ld de,0387ah		;6ce2
	call PINTA_BYTES_BCD		;6ce5
	ld b,001h		;6ce8
	inc de			;6cea
	call PINTA_BYTES_BCD		;6ceb
	ret			;6cee
RELOJ_MINIMO:		; Si queda menos de 0:30, se pone en 0:30
	ld hl,0e056h		;6cef
	xor a			;6cf2
	cp (hl)			;6cf3
	ret nz			;6cf4
	dec hl			;6cf5
	ld a,030h		;6cf6
	cp (hl)			;6cf8
	ret c			;6cf9
	ld (hl),a			;6cfa
	ret			;6cfb
RESPUESTA_REVELADA:		; Se acabo la ecuacion sin acertar: fallos a cero, se pierde la vida (E00C), ecuacion nueva (E053), los sprites del 500 vuelven, sonido 2 y al estado 19 con 0x80 fotogramas
	xor a			;6cfc
	ld (0e057h),a		;6cfd
	inc a			;6d00
	ld (0e00ch),a		;6d01
	ld (0e053h),a		;6d04
	ld hl,0597fh		;6d07
	ld de,01b80h		;6d0a
	ld bc,00040h		;6d0d
	di			;6d10
	call COPIA_A_VRAM		;6d11
	ei			;6d14
	ld a,002h		;6d15
	call SONIDO		;6d17
	ld a,012h		;6d1a
	ld (0e000h),a		;6d1c
	ld a,080h		;6d1f
	ld (0e004h),a		;6d21
	jp SIGUIENTE_ESTADO		;6d24
PROFESOR_PASO:		; Segun E276: bit 0 monta el globo con la respuesta, bit 1 lo lleva bajo el ?, bit 2 lo sube y escribe la cifra
	ld a,(0e276h)		;6d27
	and a			;6d2a
	ret z			;6d2b
	pop hl			;6d2c
	rra			;6d2d
	jr c,GLOBO_MONTA		;6d2e
	rra			;6d30
	jr c,$+85		;6d31
	rra			;6d33
	jp c,GLOBO_SUBE		;6d34
	ret			;6d37
GLOBO_MONTA:		; Con el canal C callado: esconde a los cangrejos, pone en E0B8 los cuatro sprites de 0x6D76 (un mono agarrado a un globo, fuera por la izquierda), carga los globos en 0x1B80, E108 = 0x88 y sonido 0x97
	ld a,(0e026h)		;6d38
	or a			;6d3b
	ret nz			;6d3c
	ld hl,0e0b8h		;6d3d
	ld de,0e0b9h		;6d40
	ld bc,00017h		;6d43
	ld (hl),0e1h		;6d46
	ldir		;6d48
	ld hl,06d76h		;6d4a
	ld de,0e0b8h		;6d4d
	ld bc,00010h		;6d50
	ldir		;6d53
	ld hl,05e3fh		;6d55
	ld de,01b80h		;6d58
	ld bc,00040h		;6d5b
	di			;6d5e
	call COPIA_A_VRAM		;6d5f
	ei			;6d62
	ld a,(0e276h)		;6d63
	xor 003h		;6d66
	ld (0e276h),a		;6d68
	ld a,088h		;6d6b
	ld (0e108h),a		;6d6d
	ld a,097h		;6d70
	call SONIDO		;6d72
	ret			;6d75

; ----------------------------------------------------------------------
; DATOS sprites_del_globo: Cuatro atributos: dos sprites de un mono con los
;   brazos arriba (los espejos 0xC8/0xCC de trepar, en cyan y rojo claro: otro
;   mono agarrado al globo) en Y = 0xA8 y dos del globo (0x70/0x74, rojo
;   oscuro) encima, todos en X = 0xFD (entran por la izquierda)
;   0x6d76..0x6d86  (16 bytes)
DATA_sprites_del_globo:
	defb 0a8h,0fdh,0cbh,007h	; 6d76
	defb 0a8h,0fdh,0cfh,009h	; 6d7a
	defb 088h,0fdh,070h,006h	; 6d7e
	defb 098h,0fdh,074h,006h	; 6d82

; ======================================================================
; CODIGO 0x6d86..0x7117  (913 bytes)
; ======================================================================


GLOBO_ANDA:		; Los cuatro sprites avanzan un pixel por fotograma hasta la columna del ? (E271 - 13), animando el mono con las fases de 0x65CB; al llegar, bit 2
	ld a,(0e271h)		;6d86
	add a,0f3h		;6d89
	ld hl,0e0b9h		;6d8b
	cp (hl)			;6d8e
	ld a,(hl)			;6d8f
	jr z,GLOBO_YA_ESTA		;6d90
	ld b,004h		;6d92
GLOBO_ANDA_PIXEL:		; Un pixel a la derecha los cuatro sprites
	inc (hl)			;6d94
	inc hl			;6d95
	inc hl			;6d96
	inc hl			;6d97
	inc hl			;6d98
	djnz GLOBO_ANDA_PIXEL		;6d99
	ld a,(0e003h)		;6d9b
	and 018h		;6d9e
	ld hl,065cbh		;6da0
	srl a		;6da3
	srl a		;6da5
	call HL_MAS_A		;6da7
	ld a,(hl)			;6daa
	ld de,0e0bah		;6dab
	ld (de),a			;6dae
	inc hl			;6daf
	ld a,(hl)			;6db0
	ld de,0e0beh		;6db1
	ld (de),a			;6db4
	ret			;6db5
GLOBO_YA_ESTA:		; E276: fuera el bit 1, dentro el 2: a subir
	ld a,(0e276h)		;6db6
	xor 006h		;6db9
	ld (0e276h),a		;6dbb
	ret			;6dbe
GLOBO_SUBE:		; El globo (sprites 4 y 5) sube un pixel por fotograma hasta arriba; entonces se esconde, se escribe la cifra escondida (E1CD) sobre el ? con los bloques de 0x7207, sonido 2 y 0x6CFC
	ld hl,0e0c0h		;6dbf
	xor a			;6dc2
	cp (hl)			;6dc3
	jr z,GLOBO_ARRIBA		;6dc4
	dec (hl)			;6dc6
	ld hl,0e0c4h		;6dc7
	dec (hl)			;6dca
	ret			;6dcb
GLOBO_ARRIBA:		; Se esconde y se escribe la cifra
	ld (hl),0e1h		;6dcc
	inc hl			;6dce
	inc hl			;6dcf
	inc hl			;6dd0
	inc hl			;6dd1
	ld (hl),0e1h		;6dd2
	ld d,a			;6dd4
	ld a,(0e271h)		;6dd5
	add a,0f3h		;6dd8
	ld e,a			;6dda
	ld a,(0e002h)		;6ddb
	ld hl,0e1cdh		;6dde
	rla			;6de1
	jr nc,GLOBO_ESCRIBE		;6de2
	inc hl			;6de4
GLOBO_ESCRIBE:		; El bloque de 2x2 de la cifra escondida
	ld a,(hl)			;6de5
	ld hl,07207h		;6de6
	add a,a			;6de9
	add a,a			;6dea
	call HL_MAS_A		;6deb
	ld bc,00202h		;6dee
	call PINTA_BLOQUE		;6df1
	ld a,002h		;6df4
	call SONIDO		;6df6
	jp RESPUESTA_REVELADA		;6df9
FASE_RESUELTA_BAILE:		; Con el bit 3 de E276: cada 16 fotogramas alterna los colores del mono y del profesor (los del bit 4) hasta que el nibble alto llega a 0x10; entonces la ecuacion cuenta (0x6E32)
	ld a,(0e276h)		;6dfc
	bit 3,a		;6dff
	ret z			;6e01
	pop de			;6e02
	ld a,(0e003h)		;6e03
	and 00fh		;6e06
	ret nz			;6e08
	ld a,(0e276h)		;6e09
	and 0f0h		;6e0c
	cp 010h		;6e0e
	jr z,ECUACION_RESUELTA		;6e10
	and 010h		;6e12   ; Bit 4 a 1: patrones 0x08 y color 0x0C; a 0: 0x00 y 0x04
	srl a		;6e14
	ld c,a			;6e16
	set 2,c		;6e17
	ld b,002h		;6e19
	ld hl,0e0b2h		;6e1b
BAILE_COLORES:		; Patron y color a los dos
	ld (hl),a			;6e1e
	inc hl			;6e1f
	inc hl			;6e20
	inc hl			;6e21
	inc hl			;6e22
	ld (hl),c			;6e23
	ld hl,0e0d2h		;6e24
	djnz BAILE_COLORES		;6e27
	ld a,(0e276h)		;6e29
	sub 010h		;6e2c
	ld (0e276h),a		;6e2e
	ret			;6e31
ECUACION_RESUELTA:		; En la partida (bit 6 de E002): banderas a cero, ecuacion nueva, vida devuelta (el estado 9 la gasta), una resuelta mas; a las tres, fase superada: al estado 12 con E23C (el tiempo a puntos)
	ld a,(0e002h)		;6e32
	scf			;6e35   ; En la demo (sin bit 6) vuelve con carry al que llamo a 0x4337
	bit 6,a		;6e36
	push de			;6e38
	ret z			;6e39
	pop de			;6e3a
	xor a			;6e3b
	ld (0e270h),a		;6e3c
	ld (0e057h),a		;6e3f
	ld (0e108h),a		;6e42
	ld a,001h		;6e45
	ld (0e053h),a		;6e47
	ld hl,0e050h		;6e4a   ; El estado 9 gasta una vida al entrar: se devuelve antes
	inc (hl)			;6e4d
	ld hl,0e054h		;6e4e
	inc (hl)			;6e51
	ld a,003h		;6e52
	cp (hl)			;6e54
	ld a,008h		;6e55   ; Menos de tres: al estado 9 (PLAYER n) por 0x4661
	ld (0e000h),a		;6e57
	jp nz,SIGUIENTE_ESTADO		;6e5a
	ld (hl),000h		;6e5d   ; Tres: E054 = 0, estado 12 con E23C = 1 (descuenta el tiempo), y la vida devuelta se retira porque no pasa por el 9
	ld a,00ch		;6e5f
	ld (0e000h),a		;6e61
	ld a,001h		;6e64
	ld (0e23ch),a		;6e66
	ld hl,0e050h		;6e69
	dec (hl)			;6e6c
	ret			;6e6d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA ARITMETICA. El resultado vive en E142 (unidades y decenas, BCD) y
; E143 (centenas). Suma, resta y multiplicacion por sumas repetidas,
; todo con DAA. Un acarreo o un prestamo cambian el bit 0 de E152: es
; el signo, y 0x70B1 lo pinta como un menos delante del resultado.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
SUMA_A_MAS_B:		; E142 = A + B (BCD); E143 = 0 mas el acarreo
	push hl			;6e6e
	ld hl,0e143h		;6e6f
	ld (hl),000h		;6e72
	dec hl			;6e74
	ld (hl),a			;6e75
	jr SUMA_B_BUCLE		;6e76
SUMA_B:		; E142/E143 += B
	push hl			;6e78
	ld hl,0e142h		;6e79
SUMA_B_BUCLE:		; La suma con DAA y el signo si se desborda
	ld a,(hl)			;6e7c
	add a,b			;6e7d
	daa			;6e7e
	ld (hl),a			;6e7f
	inc hl			;6e80
	ld a,(hl)			;6e81
	adc a,000h		;6e82
	daa			;6e84
	ld (hl),a			;6e85
	ld a,(0e152h)		;6e86
	jr nc,SUMA_B_FIN		;6e89
	xor 001h		;6e8b
	ld (0e152h),a		;6e8d
SUMA_B_FIN:		; Fuera
	pop hl			;6e90
	ret			;6e91
RESTA_A_MENOS_B:		; E142 = A - B (BCD); si presta, el signo (bit 0 de E152)
	push hl			;6e92
	ld hl,0e143h		;6e93
	ld (hl),000h		;6e96
	dec hl			;6e98
	ld (hl),a			;6e99
	jr RESTA_B_BUCLE		;6e9a
RESTA_B:		; E142/E143 -= B
	push hl			;6e9c
	ld hl,0e142h		;6e9d
RESTA_B_BUCLE:		; La resta con DAA y el signo si presta
	ld a,(hl)			;6ea0
	sub b			;6ea1
	daa			;6ea2
	ld (hl),a			;6ea3
	inc hl			;6ea4
	ld a,(hl)			;6ea5
	sbc a,000h		;6ea6
	daa			;6ea8
	ld (hl),a			;6ea9
	ld a,(0e152h)		;6eaa
	jr nc,RESTA_B_FIN		;6ead
	xor 001h		;6eaf
	ld (0e152h),a		;6eb1
RESTA_B_FIN:		; Fuera
	pop hl			;6eb4
	ret			;6eb5
MULTIPLICA_A_POR_B:		; E142 = A x B (BCD): A sumado B - 1 veces
	push hl			;6eb6
	push de			;6eb7
	ld hl,0e143h		;6eb8
	ld (hl),000h		;6ebb
	dec hl			;6ebd
	ld (hl),a			;6ebe
	jr MULTIPLICA_ENTRA		;6ebf
MULTIPLICA_POR_B:		; E142/E143 x B, sumandose a si mismo B - 1 veces
	push hl			;6ec1
	push de			;6ec2
	ld hl,0e142h		;6ec3
MULTIPLICA_ENTRA:		; B = 1: nada que sumar
	ld a,001h		;6ec6
	cp b			;6ec8
	jr z,MULTIPLICA_FIN		;6ec9
	ld a,(hl)			;6ecb
	ld c,a			;6ecc
	dec b			;6ecd
MULTIPLICA_BUCLE:		; Una suma mas
	ld a,(hl)			;6ece
	add a,c			;6ecf
	daa			;6ed0
	ld (hl),a			;6ed1
	inc hl			;6ed2
	ld a,(hl)			;6ed3
	adc a,000h		;6ed4
	daa			;6ed6
	ld (hl),a			;6ed7
	dec hl			;6ed8
	djnz MULTIPLICA_BUCLE		;6ed9
MULTIPLICA_FIN:		; Fuera
	pop de			;6edb
	pop hl			;6edc
	ret			;6edd
DIVISION:		; Para el signo de dividir: D y E al azar (1-9), se escribe D x E, el signo, D, y el resultado es E: siempre exacta
	call AZAR		;6ede
	ld a,(0e140h)		;6ee1
	and 00fh		;6ee4
	jr z,DIVISION		;6ee6
	ld d,a			;6ee8
DIVISION_E:		; E al azar (1-9)
	call AZAR		;6ee9
	ld a,(0e141h)		;6eec
	and 00fh		;6eef
	jr z,DIVISION_E		;6ef1
	ld b,a			;6ef3
	ld e,a			;6ef4
	ld a,d			;6ef5
	call MULTIPLICA_A_POR_B		;6ef6   ; D x E a E142
	ld a,(0e142h)		;6ef9   ; El dividendo (D x E), el signo de dividir del guion, y el divisor D
	call ESCRIBE_NUMERO		;6efc
	call ESCRIBE_DEL_GUION		;6eff
	ld a,d			;6f02
	call ESCRIBE_NUMERO		;6f03
	ld a,e			;6f06   ; El resultado es E
	ld (0e142h),a		;6f07
	jp ECUACION_SEGUNDO_SIGNO		;6f0a
AZAR:		; Semilla de 16 bits en E140/E141: se mezcla, se suma el registro R, se lee una palabra de la ROM en 0x0000-0x3FFF (la BIOS) y se remezcla con DAA. Los nibbles de E140 salen entre 0 y 9
	push hl			;6f0d
	push bc			;6f0e
	push af			;6f0f
	ld hl,(0e140h)		;6f10
	ld a,h			;6f13
	xor l			;6f14
	rlc a		;6f15
	ld l,a			;6f17
	sra h		;6f18
	sra l		;6f1a
	ld a,r		;6f1c   ; El registro R del Z80: la parte que no se puede predecir
	add a,l			;6f1e
	ld l,a			;6f1f
	ld a,h			;6f20
	adc a,000h		;6f21
	and 03fh		;6f23
	ld h,a			;6f25
	ld c,(hl)			;6f26   ; Una palabra de la BIOS (H queda entre 0 y 0x3F) como tabla de ruido
	inc hl			;6f27
	ld h,(hl)			;6f28
	ld l,c			;6f29
	ld a,h			;6f2a
	and 077h		;6f2b
	ld h,a			;6f2d
	ld a,(0e140h)		;6f2e
	add a,h			;6f31
	daa			;6f32
	ld h,a			;6f33
	ld a,l			;6f34
	and 077h		;6f35
	ld l,a			;6f37
	ld a,(0e140h)		;6f38
	add a,l			;6f3b
	daa			;6f3c
	ld l,a			;6f3d
	ld (0e140h),hl		;6f3e
	pop af			;6f41
	pop bc			;6f42
	pop hl			;6f43
	ret			;6f44
OPERANDO:		; Un numero al azar de dos cifras BCD (E140) con las unidades entre 2 y 9, escrito en la ecuacion; B se lo queda
	call AZAR		;6f45
	ld a,(0e140h)		;6f48
	ld b,a			;6f4b
	and 00fh		;6f4c
	cp 002h		;6f4e
	ld a,b			;6f50
	jr c,OPERANDO		;6f51
ESCRIBE_NUMERO:		; Escribe A (BCD, dos cifras) detras de HL: las decenas si no son cero y las unidades; E058 cuenta los simbolos
	ld b,a			;6f53
	and a			;6f54
	ret z			;6f55
	and 00fh		;6f56
	ld c,a			;6f58
	ld a,b			;6f59
	srl a		;6f5a
	srl a		;6f5c
	srl a		;6f5e
	srl a		;6f60
	inc hl			;6f62
	ld (hl),a			;6f63
	call UN_SIMBOLO_MAS		;6f64
	and a			;6f67
	jr z,ESCRIBE_UNIDADES		;6f68
	inc hl			;6f6a
	call UN_SIMBOLO_MAS		;6f6b
ESCRIBE_UNIDADES:		; Las unidades
	ld (hl),c			;6f6e
	ret			;6f6f
LEE_GUION:		; A = el simbolo del guion (E150) sin avanzar
	push hl			;6f70
	ld hl,(0e150h)		;6f71
	ld a,(hl)			;6f74
	pop hl			;6f75
	ret			;6f76
ESCRIBE_DEL_GUION:		; Copia el simbolo del guion detras de HL y avanza
	push hl			;6f77
	ld hl,(0e150h)		;6f78
	ld a,(hl)			;6f7b
	inc hl			;6f7c
	ld (0e150h),hl		;6f7d
	pop hl			;6f80
	inc hl			;6f81
	ld (hl),a			;6f82
UN_SIMBOLO_MAS:		; E058++
	push hl			;6f83
	ld hl,0e058h		;6f84
	inc (hl)			;6f87
	pop hl			;6f88
	ret			;6f89
OPERANDO_1_CIFRA:		; Un numero al azar de una cifra (1-9), escrito
	call AZAR		;6f8a
	ld a,(0e140h)		;6f8d
	and 00fh		;6f90
	jr z,OPERANDO_1_CIFRA		;6f92
	jr ESCRIBE_NUMERO		;6f94

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL GENERADOR DE ECUACIONES. Los simbolos: 0-9 las cifras, 0x0A +,
; 0x0B -, 0x0C x, 0x0D dividir, 0x0E =, 0x10 (, 0x11 ), 0x12 el ?,
; 0x13 nada. Cada nivel tiene su guion en 0x7117:
; nivel 1  A + B = R          nivel 2  A - B = R (con signo si
; nivel 3  (D x E) / D = E     sale negativo: 89 - 99 = -10)
; nivel 4  A x b = R           nivel 5  a x ( b + c ) = R
; A y B son de dos cifras BCD (unidades 2-9); en el x, B se queda
; con las unidades; en el nivel 5 todo es de una cifra. El resultado
; se escribe con sus cifras y luego 0x7253 tapa una cifra al azar con
; el ?. La eleccion al azar del guion (and 7) esta anulada con un
; `xor a`: siempre el primero. Comprobado con 600 ecuaciones
; muestreadas en el emulador (work/omsx/ecuaciones*.log).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
GENERA_ECUACION:		; Trece huecos, el guion del nivel del jugador y los operandos al azar; el resultado en E142/E143 y en la ecuacion
	ld hl,0e144h		;6f96
	ld (hl),013h		;6f99
	ld de,0e145h		;6f9b
	ld bc,0000ch		;6f9e
	ldir		;6fa1
	xor a			;6fa3
	ld (0e152h),a		;6fa4
	call NIVEL_DEL_JUGADOR		;6fa7   ; El nivel del jugador (E153/E154) elige la entrada de 0x7117
	ld a,(hl)			;6faa
	ld hl,07117h		;6fab
	add a,a			;6fae
	add a,a			;6faf
	call HL_MAS_A		;6fb0
	ld e,(hl)			;6fb3
	inc hl			;6fb4
	ld d,(hl)			;6fb5
	inc hl			;6fb6
	ld b,(hl)			;6fb7
	inc hl			;6fb8
	ld a,(hl)			;6fb9
	ld h,a			;6fba
	ld l,b			;6fbb
	call AZAR		;6fbc   ; El azar & 7 iba a elegir entre ocho desplazamientos... y el `xor a` lo deja siempre en el primero (0)
	and 007h		;6fbf
	xor a			;6fc1
	call HL_MAS_A		;6fc2
	ld a,(hl)			;6fc5
	ex de,hl			;6fc6
	call HL_MAS_A		;6fc7
	ld (0e150h),hl		;6fca
	call NIVEL_DEL_JUGADOR		;6fcd
	ld a,(hl)			;6fd0
	cp 004h		;6fd1   ; El nivel 5 va aparte
	jr z,ECUACION_NIVEL_5		;6fd3
	xor a			;6fd5
	ld (0e058h),a		;6fd6
	ld hl,00000h		;6fd9
	ld (0e142h),hl		;6fdc
	ld hl,0e143h		;6fdf   ; HL = E143: los simbolos se escriben desde E144
	call LEE_GUION		;6fe2
	cp 00fh		;6fe5   ; 0x0F no aparece en ningun guion: este salto a la tabla no se da nunca
	jp z,07117h		;6fe7
	cp 00dh		;6fea   ; El signo de dividir se genera al reves: del resultado a los operandos
	jp z,DIVISION		;6fec
	call OPERANDO		;6fef
	ld e,b			;6ff2
	call ESCRIBE_DEL_GUION		;6ff3
	push af			;6ff6
	push de			;6ff7
	call OPERANDO		;6ff8
	pop de			;6ffb
	pop af			;6ffc
	cp 00ch		;6ffd   ; Multiplicar: el segundo operando de una cifra
	jr z,MULTIPLICA		;6fff
	cp 00bh		;7001   ; Restar
	ld a,e			;7003
	jr z,ECUACION_RESTA		;7004
	call SUMA_A_MAS_B		;7006
	jr ECUACION_SEGUNDO_SIGNO		;7009
ECUACION_RESTA:		; A - B
	call RESTA_A_MENOS_B		;700b
ECUACION_SEGUNDO_SIGNO:		; Tras el segundo operando: si viene el =, al resultado; si otro signo (mas o menos), un tercer operando
	call ESCRIBE_DEL_GUION		;700e
	cp 00eh		;7011
	jp z,ECUACION_SIGNO		;7013
	push af			;7016
	call OPERANDO		;7017
	pop af			;701a
	cp 00bh		;701b
	jr z,ECUACION_RESTA_C		;701d
	call SUMA_B		;701f
	jr ECUACION_TERCERO_FIN		;7022
ECUACION_RESTA_C:		; Menos el tercero
	call RESTA_B		;7024
ECUACION_TERCERO_FIN:		; El = y al signo
	call ESCRIBE_DEL_GUION		;7027
	jp ECUACION_SIGNO		;702a
MULTIPLICA:		; El segundo operando pierde las decenas (se queda con las unidades, un simbolo menos) y A x b
	ld a,b			;702d
	and 0f0h		;702e
	jr z,MULTIPLICA_B		;7030
	push hl			;7032
	ld hl,0e058h		;7033
	dec (hl)			;7036
	pop hl			;7037
	ld a,(hl)			;7038
	dec hl			;7039
	ld (hl),a			;703a
MULTIPLICA_B:		; E142 = A x (b & 0x0F)
	ld a,b			;703b
	and 00fh		;703c
	ld b,a			;703e
	ld a,e			;703f
	call MULTIPLICA_A_POR_B		;7040
	jr ECUACION_SEGUNDO_SIGNO		;7043
ECUACION_NIVEL_5:		; a x ( b + c ) = R con las tres cifras al azar (1-9); si b + c da 0 se repite; el resultado a x (b + c) en E142/E143
	xor a			;7045
	ld (0e058h),a		;7046
	ld hl,00000h		;7049
	ld (0e142h),hl		;704c
	ld hl,0e143h		;704f
	call OPERANDO_1_CIFRA		;7052
	ld b,002h		;7055
NIVEL_5_GUION:		; Dos simbolos del guion
	call ESCRIBE_DEL_GUION		;7057   ; Los dos simbolos del guion: x y (
	djnz NIVEL_5_GUION		;705a
	call OPERANDO_1_CIFRA		;705c
	ld d,b			;705f
	call ESCRIBE_DEL_GUION		;7060
	push af			;7063
	call OPERANDO_1_CIFRA		;7064
	pop af			;7067
	cp 00ah		;7068   ; El tercer simbolo: + (o -, con signo)
	ld a,d			;706a
	jr z,NIVEL_5_SUMA		;706b
	call RESTA_A_MENOS_B		;706d
	ld a,(0e152h)		;7070
	bit 0,a		;7073
	jr z,NIVEL_5_MIRA_CERO		;7075
	push hl			;7077
	ld hl,(0e142h)		;7078
	xor a			;707b
	sub l			;707c
	daa			;707d
	ld l,a			;707e
	ld a,000h		;707f
	sbc a,h			;7081
	daa			;7082
	ld h,a			;7083
	ld (0e142h),hl		;7084
	pop hl			;7087
	jr NIVEL_5_MIRA_CERO		;7088
NIVEL_5_SUMA:		; b + c
	call SUMA_A_MAS_B		;708a
NIVEL_5_MIRA_CERO:		; Cero: otra
	ld a,(0e142h)		;708d   ; Suma cero: otra ecuacion
	or a			;7090
	jp z,GENERA_ECUACION		;7091
	ld a,(0e144h)		;7094   ; Y por a (E144)
	ld b,a			;7097
	call MULTIPLICA_POR_B		;7098
	ld b,002h		;709b   ; ) y =
NIVEL_5_CIERRA:		; ) y =
	call ESCRIBE_DEL_GUION		;709d
	djnz NIVEL_5_CIERRA		;70a0
	ld a,(0e152h)		;70a2
	bit 0,a		;70a5
	jr z,ECUACION_RESULTADO		;70a7
	inc hl			;70a9
	ld (hl),00bh		;70aa
	call UN_SIMBOLO_MAS		;70ac
	jr ECUACION_RESULTADO		;70af
ECUACION_SIGNO:		; Con el bit 0 de E152 (negativo): un menos delante del resultado y E142/E143 = 0 - E142/E143
	ld a,(0e152h)		;70b1
	bit 0,a		;70b4
	jr z,ECUACION_RESULTADO		;70b6
	inc hl			;70b8
	ld (hl),00bh		;70b9
	call UN_SIMBOLO_MAS		;70bb
	push hl			;70be
	ld hl,(0e142h)		;70bf
	xor a			;70c2
	sub l			;70c3
	daa			;70c4
	ld l,a			;70c5
	ld a,000h		;70c6
	sbc a,h			;70c8
	daa			;70c9
	ld h,a			;70ca
	ld (0e142h),hl		;70cb
	pop hl			;70ce
ECUACION_RESULTADO:		; Las centenas (si hay), y las dos cifras (o una, o el 0)
	ld a,(0e143h)		;70cf
	call ESCRIBE_NUMERO		;70d2
	ld a,b			;70d5
	and a			;70d6
	jr nz,RESULTADO_3_CIFRAS		;70d7
	ld a,(0e142h)		;70d9
	and a			;70dc
	jr nz,RESULTADO_2_CIFRAS		;70dd
	inc hl			;70df
	ld (hl),000h		;70e0
	jp UN_SIMBOLO_MAS		;70e2
RESULTADO_3_CIFRAS:		; Con centenas: decenas y unidades siempre
	ld a,(0e142h)		;70e5
	ld b,a			;70e8
	srl a		;70e9
	srl a		;70eb
	srl a		;70ed
	srl a		;70ef
	inc hl			;70f1
	ld (hl),a			;70f2
	ld a,b			;70f3
	and 00fh		;70f4
	inc hl			;70f6
	ld (hl),a			;70f7
	ld hl,0e058h		;70f8
	inc (hl)			;70fb
	inc (hl)			;70fc
	ret			;70fd
RESULTADO_2_CIFRAS:		; Sin centenas: las decenas si no son cero, y las unidades
	ld b,a			;70fe
	srl a		;70ff
	srl a		;7101
	srl a		;7103
	srl a		;7105
	and a			;7107
	jr z,RESULTADO_UNIDADES		;7108
	inc hl			;710a
	ld (hl),a			;710b
	call UN_SIMBOLO_MAS		;710c
RESULTADO_UNIDADES:		; Las unidades
	ld a,b			;710f
	and 00fh		;7110
	inc hl			;7112
	ld (hl),a			;7113
	jp UN_SIMBOLO_MAS		;7114

; ----------------------------------------------------------------------
; DATOS tabla_de_guiones: Cinco entradas de dos punteros (una por nivel): el
;   guion de la ecuacion y la tabla de desplazamientos (que es el 0 que cierra
;   el guion). El `jp z,7117h` de 0x6FE7 no salta nunca
;   0x7117..0x712b  (20 bytes)
DATA_tabla_de_guiones:
	defw 0712bh,0712dh	; 7117  -> DATA_guiones_de_ecuacion 0x712d
	defw 0712eh,07130h	; 711b
	defw 07131h,07133h	; 711f
	defw 07134h,07136h	; 7123
	defw 07137h,0713ch	; 7127

; ----------------------------------------------------------------------
; DATOS guiones_de_ecuacion: Los cinco guiones, acabados en 0: 0A 0E (A + B
;   =), 0B 0E (A - B =), 0D 0E (dividir), 0C 0E (A x b =) y 0C 10 0A 11 0E (a
;   x ( b + c ) =)
;   0x712b..0x713d  (18 bytes)
DATA_guiones_de_ecuacion:
	defb 00ah,00eh,000h,00bh,00eh,000h,00dh,00eh,000h,00ch,00eh,000h,00ch,010h,00ah,011h	; 712b  ................
	defb 00eh,000h	; 713b

; ======================================================================
; CODIGO 0x713d..0x7207  (202 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS GLOBOS. La ecuacion entra en globos que suben desde abajo, uno
; detras de otro y en orden al azar, hasta Y = 0x10; al llegar, el
; globo desaparece y el simbolo se pinta en tiles de 2x2 (0x7207) en
; las filas 0-1. Cada globo son dos sprites (0x70/0x74, de 0x5E3F)
; en E0B8 + 8n; E24C + n es su estado: 0 espera, 1 sube, 2 llego,
; 0xFF cierra la lista. E24B cuenta los llegados y E058 cuantos son.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
GLOBOS_SUBEN:		; Un pixel arriba cada globo en marcha; al llegar a 0x10 su simbolo se pinta; suelta el siguiente al azar; carry cuando estan todos
	ld b,000h		;713d
GLOBO_SIGUIENTE:		; Recorre E24C hasta 0xFF
	ld hl,0e24ch		;713f
	ld a,b			;7142
	call HL_MAS_A		;7143
	ld a,0ffh		;7146
	cp (hl)			;7148
	jr z,GLOBOS_SUELTA_OTRO		;7149
	ld a,001h		;714b   ; Estado 1: sube (los dos sprites)
	cp (hl)			;714d
	jr nz,GLOBO_OTRO		;714e
	ld hl,0e0b8h		;7150
	ld a,b			;7153
	add a,a			;7154
	add a,a			;7155
	add a,a			;7156
	call HL_MAS_A		;7157
	dec (hl)			;715a
	ld a,004h		;715b
	call HL_MAS_A		;715d
	dec (hl)			;7160
	ld a,010h		;7161   ; A Y = 0x10 ha llegado
	cp (hl)			;7163
	call z,GLOBO_LLEGA		;7164
GLOBO_OTRO:		; El siguiente globo
	inc b			;7167
	jr GLOBO_SIGUIENTE		;7168
GLOBOS_SUELTA_OTRO:		; Si faltan por soltar (E24B < E058) y el ultimo suelto ya paso de 8 pixels, suelta uno al azar de los que esperan (0)
	ld hl,0e24bh		;716a
	ld a,(0e058h)		;716d
	cp (hl)			;7170
	jr z,GLOBOS_TODOS		;7171
	ld a,(0e258h)		;7173   ; E258: el ultimo que se solto; hasta que no lleva 8 pixels no sale otro
	ld hl,0e0b8h		;7176
	add a,a			;7179
	add a,a			;717a
	add a,a			;717b
	call HL_MAS_A		;717c
	ld a,(hl)			;717f
	and 007h		;7180
	ret nz			;7182
GLOBO_AL_AZAR:		; Un indice al azar menor que E058, y desde ahi el primer globo en espera (dando la vuelta)
	call AZAR		;7183
	ld a,(0e140h)		;7186
	and 00fh		;7189
	ld hl,0e058h		;718b
	cp (hl)			;718e
	jr nc,GLOBO_AL_AZAR		;718f
	ld hl,0e24ch		;7191
	call HL_MAS_A		;7194
GLOBO_BUSCA_LIBRE:		; El primer estado 0 desde HL, con vuelta al principio en el 0xFF
	ld a,0ffh		;7197
	cp (hl)			;7199
	jr nz,GLOBO_BUSCA_LIBRE_MIRA		;719a
	ld hl,0e24ch		;719c
GLOBO_BUSCA_LIBRE_MIRA:		; Estado 0?
	xor a			;719f
	cp (hl)			;71a0
	jr z,GLOBO_SUELTA		;71a1
	inc hl			;71a3
	jr GLOBO_BUSCA_LIBRE		;71a4
GLOBO_SUELTA:		; Estado 1 y uno mas soltado
	ld (hl),001h		;71a6
	ld hl,0e24bh		;71a8
	inc (hl)			;71ab
	and a			;71ac
	ret			;71ad
GLOBOS_TODOS:		; Todos soltados: carry si todos han llegado (2), NC si queda alguno subiendo
	ld hl,0e24ch		;71ae
GLOBOS_TODOS_MIRA:		; Recorre hasta 0xFF: todos en 2?
	ld a,0ffh		;71b1
	cp (hl)			;71b3
	scf			;71b4
	jr z,GLOBOS_TODOS_FIN		;71b5
	ld a,002h		;71b7
	cp (hl)			;71b9
	inc hl			;71ba
	jr z,GLOBOS_TODOS_MIRA		;71bb
	and a			;71bd
GLOBOS_TODOS_FIN:		; Fuera
	ret			;71be
GLOBO_LLEGA:		; Esconde los dos sprites, pinta el simbolo (de la ecuacion del jugador, E1B5 o E1C1) en 2x2 donde estaba el globo, apunta la columna del ? (E271) y sonido 2
	push bc			;71bf
	push bc			;71c0
	ld (hl),0e1h		;71c1   ; Los dos sprites del globo a Y = 0xE1; DE = donde estaba el de arriba
	dec hl			;71c3
	dec hl			;71c4
	dec hl			;71c5
	ld e,(hl)			;71c6
	dec hl			;71c7
	ld d,(hl)			;71c8
	ld (hl),0e1h		;71c9
	ld a,(0e002h)		;71cb
	rl a		;71ce
	ld hl,0e1b5h		;71d0
	jr nc,GLOBO_LLEGA_SIMBOLO		;71d3
	ld hl,0e1c1h		;71d5
GLOBO_LLEGA_SIMBOLO:		; El simbolo B de la ecuacion del jugador
	ld a,b			;71d8
	call HL_MAS_A		;71d9
	ld a,(hl)			;71dc
	push af			;71dd
	cp 012h		;71de   ; El simbolo 0x12 es el ?: su X mas 13 queda en E271 para el profesor
	jr nz,GLOBO_LLEGA_PINTA		;71e0
	ld a,e			;71e2
	add a,00dh		;71e3
	ld (0e271h),a		;71e5
GLOBO_LLEGA_PINTA:		; El bloque de 2x2 y estado 2
	pop af			;71e8
	ld hl,07207h		;71e9
	add a,a			;71ec
	add a,a			;71ed
	call HL_MAS_A		;71ee
	ld bc,00202h		;71f1
	call PINTA_BLOQUE		;71f4
	ld hl,0e24ch		;71f7
	pop bc			;71fa
	ld a,b			;71fb
	call HL_MAS_A		;71fc
	ld (hl),002h		;71ff
	pop bc			;7201
	ld a,002h		;7202
	jp SONIDO		;7204

; ----------------------------------------------------------------------
; DATOS tiles_de_los_simbolos: Diecinueve bloques de 2x2 tiles, uno por
;   simbolo: 0-9 las cifras grandes amarillas, + - x dividir =, un hueco
;   (0x0F), ( ) y el ? (tiles 0x7B-0xB7 mas 0xBE-0xC3 de 0x5EFF)
;   0x7207..0x7253  (76 bytes)
DATA_tiles_de_los_simbolos:
	defb 07bh,07ch,07dh,07eh	; 7207
	defb 07fh,080h,081h,082h	; 720b
	defb 083h,0c0h,085h,086h	; 720f
	defb 0beh,0c0h,0bfh,0c1h	; 7213
	defb 089h,080h,08ah,08bh	; 7217
	defb 08ch,08dh,08eh,088h	; 721b
	defb 08ch,08dh,08fh,088h	; 721f
	defb 090h,091h,092h,093h	; 7223
	defb 0c2h,0c0h,0c3h,0c1h	; 7227
	defb 08ch,084h,08eh,088h	; 722b
	defb 094h,095h,096h,097h	; 722f
	defb 098h,099h,09ah,09bh	; 7233
	defb 09ch,09dh,09eh,09fh	; 7237
	defb 0a0h,0a1h,0a2h,0a3h	; 723b
	defb 0a4h,0a5h,0a6h,0a7h	; 723f
	defb 0a8h,0a9h,0aah,0abh	; 7243
	defb 0ach,0adh,0aeh,0afh	; 7247
	defb 0b0h,0b1h,0b2h,0b3h	; 724b
	defb 0b4h,0b5h,0b6h,0b7h	; 724f

; ======================================================================
; CODIGO 0x7253..0x7325  (210 bytes)
; ======================================================================


ELIGE_INCOGNITA:		; Tapa una cifra de la ecuacion con el ? y guarda la cifra en E1CD (1P) o E1CE (2P): la posicion es (primera cifra - azar 0..15), asi que nunca va mas alla de lo que VALE la primera cifra (medido en 400 ecuaciones: 0 excepciones; con un 1 delante el ? cae siempre en el primer operando, y solo 1 de cada 6 veces cae en el resultado)
	ld hl,0e144h		;7253
	call AZAR		;7256
	ld a,(0e140h)		;7259
	and 00fh		;725c
	ld b,a			;725e
	ld a,(hl)			;725f   ; La posicion sale de restar el azar a la PRIMERA cifra de la ecuacion (su valor, no su sitio); negativa, se repite
	sub b			;7260
	jr c,ELIGE_INCOGNITA		;7261
	call HL_MAS_A		;7263
	ld a,(hl)			;7266   ; Tiene que caer en una cifra (0-9), no en un signo
	cp 00ah		;7267
	jr nc,ELIGE_INCOGNITA		;7269
	ld (hl),012h		;726b
	ld hl,0e002h		;726d
	bit 7,(hl)		;7270
	ld hl,0e1cdh		;7272
	jr z,ELIGE_INCOGNITA_GUARDA		;7275
	inc hl			;7277
ELIGE_INCOGNITA_GUARDA:		; La cifra al jugador
	ld (hl),a			;7278
	ret			;7279
ECUACION_AL_JUGADOR:		; Copia los E058 simbolos de E144 a la ecuacion del jugador (E1B5 o E1C1) y apaga E053
	ld a,(0e002h)		;727a
	rl a		;727d
	ld de,0e1b5h		;727f
	jr nc,ECUACION_AL_JUGADOR_COPIA		;7282
	ld de,0e1c1h		;7284
ECUACION_AL_JUGADOR_COPIA:		; Los E058 simbolos
	ld hl,0e144h		;7287
	ld a,(0e058h)		;728a
	ld b,000h		;728d
	ld c,a			;728f
	ldir		;7290
	xor a			;7292
	ld (0e053h),a		;7293
	ret			;7296
MONTA_GLOBOS:		; Sprites a 0xE1; para cada simbolo dos sprites de globo (0x70 y 0x74, uno bajo otro, Y = 0xC8/0xD8, fuera por abajo) en la X de 0x7325 y un color al azar de 0x732E; los globos de 0x5E3F a 0x1B80; estados a 0 y 0xFF, y suelta el primero al azar
	ld hl,0e0b0h		;7297
	ld de,0e0b1h		;729a
	ld (hl),0e1h		;729d
	ld bc,0005fh		;729f
	ldir		;72a2
	ld hl,0e24bh		;72a4
	ld (hl),001h		;72a7
	ld a,(0e058h)		;72a9
	ld b,a			;72ac
	sub 005h		;72ad   ; 0x7325 + (simbolos - 5): la X del primer globo segun cuantos son, para centrarlos
	ld hl,07325h		;72af
	call HL_MAS_A		;72b2
	ld a,(hl)			;72b5
	ld hl,0e0b8h		;72b6
MONTA_GLOBO:		; Un simbolo: dos sprites y 16 pixels a la derecha
	push bc			;72b9
	ld b,002h		;72ba
	ld c,070h		;72bc
	call AZAR		;72be
	push af			;72c1
	push hl			;72c2
	ld a,(0e140h)		;72c3
	and 00fh		;72c6
	ld hl,0732eh		;72c8
	call HL_MAS_A		;72cb
	ld d,(hl)			;72ce
	pop hl			;72cf
	pop af			;72d0
MONTA_GLOBO_SPRITE:		; Uno de los dos
	push af			;72d1   ; El de arriba en Y = 0xC8 y el de abajo en 0xD8 (bit 2 del patron)
	ld a,c			;72d2
	rl a		;72d3
	rl a		;72d5
	and 010h		;72d7
	add a,0c8h		;72d9
	ld (hl),a			;72db
	pop af			;72dc
	inc hl			;72dd
	ld (hl),a			;72de
	inc hl			;72df
	ld (hl),c			;72e0
	inc hl			;72e1
	ld (hl),d			;72e2
	inc hl			;72e3
	set 2,c		;72e4
	djnz MONTA_GLOBO_SPRITE		;72e6
	add a,010h		;72e8
	pop bc			;72ea
	djnz MONTA_GLOBO		;72eb
	ld de,01b80h		;72ed
	ld bc,00040h		;72f0
	ld hl,05e3fh		;72f3
	call COPIA_A_VRAM		;72f6
	ld a,(0e058h)		;72f9
	ld c,a			;72fc
	ld b,000h		;72fd
	ld hl,0e24ch		;72ff
	ld de,0e24dh		;7302
	ld (hl),000h		;7305
	ldir		;7307
	ld (hl),0ffh		;7309
GLOBO_PRIMERO:		; Un indice al azar menor que E058 arranca (estado 1) y se apunta en E258
	call AZAR		;730b
	ld a,(0e140h)		;730e
	and 00fh		;7311
	ld hl,0e058h		;7313
	cp (hl)			;7316
	jr nc,GLOBO_PRIMERO		;7317
	ld hl,0e24ch		;7319
	ld (0e258h),a		;731c
	call HL_MAS_A		;731f
	ld (hl),001h		;7322
	ret			;7324

; ----------------------------------------------------------------------
; DATOS x_del_primer_globo: La X del primer globo segun cuantos simbolos tenga
;   la ecuacion (5 a 13): 0x38 0x38 0x38 0x28 0x28 0x18 0x08 0x00 0x00, para
;   que la ecuacion salga centrada
;   0x7325..0x732e  (9 bytes)
DATA_x_del_primer_globo:
	defb 038h,038h,038h,028h,028h,018h,008h,000h,000h	; 7325  888((....

; ----------------------------------------------------------------------
; DATOS colores_de_globos: Dieciseis colores para los globos, elegidos al
;   azar: azul, rojo claro, blanco, verde oscuro, cyan, amarillo...
;   0x732e..0x733e  (16 bytes)
DATA_colores_de_globos:
	defb 004h,009h,00fh,00ch,007h,009h,004h,00ah,009h,00ah,00fh,00ah,007h,004h,00ch,007h	; 732e  ................

; ======================================================================
; CODIGO 0x733e..0x742f  (241 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS OCHO FRUTAS de la fase (sprites 10-17, E0D8). Cada una lleva en
; E260 dos bytes: el estado y un contador. El estado: bit 0 cae, bit 1
; vuela (la han tirado), bits 2-3 la lleva alguien en la cabeza (el 3
; el mono, solo el 2 el cangrejo), bit 5 hacia donde vuela, bit 6 la
; tiro un cangrejo, bit 7 ya no esta. Colgada o en el suelo vale 0.
; Se cogen saltando, se tiran con el boton, y la que va por el aire
; mata al cangrejo (500) o al mono.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
FRUTAS_PASO:		; Un paso de cada una de las ocho
	ld b,000h		;733e
FRUTAS_BUCLE:		; Una fruta
	push bc			;7340
	call FRUTA_PASO		;7341
	pop bc			;7344
	inc b			;7345
	ld a,008h		;7346
	cp b			;7348
	jr nz,FRUTAS_BUCLE		;7349
	ret			;734b
FRUTA_PASO:		; La fruta B: E25C su sprite, E25E su estado; y segun el bit que tenga
	ld a,b			;734c
	sla a		;734d
	push af			;734f
	sla a		;7350
	ld hl,0e0d8h		;7352
	call HL_MAS_A		;7355
	ld (0e25ch),hl		;7358
	pop af			;735b
	ld hl,0e260h		;735c
	call HL_MAS_A		;735f
	ld (0e25eh),hl		;7362
	ld a,(hl)			;7365   ; Bit 0: cae; bit 1: vuela; bit 2: la lleva alguien
	rr a		;7366
	jr c,FRUTA_CAE		;7368
	rr a		;736a
	jr c,FRUTA_VUELA		;736c
	rr a		;736e
	ret nc			;7370
	ld hl,0e0b0h		;7371   ; Bit 3: la lleva el mono (E0B0); si no, el cangrejo de E0C8 (el tipo 3, el unico que salta)
	rr a		;7374
	jr c,FRUTA_EN_LA_CABEZA		;7376
	ld hl,0e0c8h		;7378
FRUTA_EN_LA_CABEZA:		; 16 pixels por encima de quien la lleva
	ld a,(hl)			;737b
	sub 010h		;737c
	inc hl			;737e
	ld b,(hl)			;737f
	ld hl,(0e25ch)		;7380
	ld (hl),a			;7383
	inc hl			;7384
	ld (hl),b			;7385
	ret			;7386
FRUTA_CAE:		; Sonido 6; con suelo debajo (0x6924) se para (estado 0) o desaparece si venia volando (bit 1); si no, dos pixels mas abajo
	ld a,006h		;7387
	call SONIDO		;7389
	ld hl,(0e25ch)		;738c
	ld b,(hl)			;738f
	inc hl			;7390
	ld c,(hl)			;7391
	call HAY_SUELO		;7392
	jr c,FRUTA_CAE_2		;7395
	ld hl,(0e25eh)		;7397
	bit 1,(hl)		;739a
	ld (hl),000h		;739c
	inc hl			;739e
	ld (hl),001h		;739f
	ret z			;73a1
	ld hl,(0e25ch)		;73a2
	ld (hl),0e1h		;73a5
	ret			;73a7
FRUTA_CAE_2:		; Dos pixels
	ld hl,(0e25ch)		;73a8
	inc (hl)			;73ab
	inc (hl)			;73ac
	ret			;73ad
FRUTA_VUELA:		; Sonido 8; fuera de la pantalla (X < 8 o >= 0xC0) desaparece; en el nibble alto del contador 8 mira si hay suelo (rebota o sigue); y el paso de la parabola
	ld a,008h		;73ae
	call SONIDO		;73b0
	ld hl,(0e25ch)		;73b3
	inc hl			;73b6
	ld a,(hl)			;73b7
	cp 0c0h		;73b8
	jr nc,FRUTA_VUELA_FUERA		;73ba
	cp 008h		;73bc
	jr nc,FRUTA_VUELA_SUELO		;73be
FRUTA_VUELA_FUERA:		; Fuera de la pantalla: desaparece
	dec hl			;73c0
	ld (hl),0e1h		;73c1
	ld hl,(0e25eh)		;73c3
	ld (hl),000h		;73c6
	inc hl			;73c8
	ld (hl),001h		;73c9
	ret			;73cb
FRUTA_VUELA_SUELO:		; En el octavo paso: hay suelo?
	ld hl,(0e25eh)		;73cc
	inc hl			;73cf
	ld a,(hl)			;73d0
	and 0f0h		;73d1
	cp 080h		;73d3   ; En el octavo paso del vuelo, si hay suelo cambia de parabola (bit 0 del contador); si no, se le quita el bit 0
	jr nz,FRUTA_VUELA_PASO		;73d5
	ld a,(hl)			;73d7
	and 00fh		;73d8
	ld (hl),a			;73da
	ld hl,(0e25ch)		;73db
	ld b,(hl)			;73de
	inc hl			;73df
	ld c,(hl)			;73e0
	call HAY_SUELO		;73e1
	jr nc,FRUTA_VUELA_SIN_SUELO		;73e4
	ld hl,(0e25eh)		;73e6
	ld a,(hl)			;73e9
	xor 001h		;73ea
	ld (hl),a			;73ec
	ret			;73ed
FRUTA_VUELA_SIN_SUELO:		; Sin suelo: la parabola baja
	ld hl,(0e25eh)		;73ee
	inc hl			;73f1
	res 0,(hl)		;73f2
FRUTA_VUELA_PASO:		; Parabola 0x742F (bit 0 del contador) o 0x7451, la segunda mitad si va hacia la izquierda (bit 5): (dY, dX) del paso (nibble alto del contador) y un paso mas
	ld de,(0e25eh)		;73f4
	inc de			;73f8
	ld a,(de)			;73f9
	ld hl,0742fh		;73fa
	and 001h		;73fd
	jr nz,FRUTA_VUELA_SENTIDO		;73ff
	ld hl,07451h		;7401
FRUTA_VUELA_SENTIDO:		; Hacia la izquierda: la segunda mitad de la tabla
	dec de			;7404
	ld a,(de)			;7405
	bit 5,a		;7406
	jr z,FRUTA_VUELA_MUEVE		;7408
	ld a,011h		;740a
	call HL_MAS_A		;740c
FRUTA_VUELA_MUEVE:		; (dY, dX) del paso
	inc de			;740f
	ld a,(de)			;7410
	and 0f0h		;7411
	srl a		;7413
	srl a		;7415
	srl a		;7417
	call HL_MAS_A		;7419
	ld b,(hl)			;741c
	inc hl			;741d
	ld c,(hl)			;741e
	ld hl,(0e25ch)		;741f
	ld a,(hl)			;7422
	add a,b			;7423
	ld (hl),a			;7424
	inc hl			;7425
	ld a,(hl)			;7426
	add a,c			;7427
	ld (hl),a			;7428
	ld a,010h		;7429
	ex de,hl			;742b
	add a,(hl)			;742c
	ld (hl),a			;742d
	ret			;742e

; ----------------------------------------------------------------------
; DATOS parabola_baja: Dos tandas de ocho pares (dY, dX) y 0xFF: hacia la
;   derecha (0, -4)... no: dX = -4 (0xFC) es hacia la izquierda y +4 hacia la
;   derecha; dY 0 0 1 1 2 3 4 5: la fruta sale recta y cae
;   0x742f..0x7451  (34 bytes)
DATA_parabola_baja:
	defb 000h,0fch	; 742f
	defb 000h,0fch	; 7431
	defb 001h,0fch	; 7433
	defb 001h,0fch	; 7435
	defb 002h,0fch	; 7437
	defb 003h,0fch	; 7439
	defb 004h,0fch	; 743b
	defb 005h,0fch	; 743d
	defb 0ffh,000h	; 743f
	defb 004h,000h	; 7441
	defb 004h,001h	; 7443
	defb 004h,001h	; 7445
	defb 004h,002h	; 7447
	defb 004h,003h	; 7449
	defb 004h,004h	; 744b
	defb 004h,005h	; 744d
	defb 004h,0ffh	; 744f

; ----------------------------------------------------------------------
; DATOS parabola_alta: Las otras dos tandas: dY -5 -2 -1 0 0 1 2 5 con dX -2
;   (o +2): sube y luego cae
;   0x7451..0x7473  (34 bytes)
DATA_parabola_alta:
	defb 0fbh,0feh	; 7451
	defb 0feh,0feh	; 7453
	defb 0ffh,0feh	; 7455
	defb 000h,0feh	; 7457
	defb 000h,0feh	; 7459
	defb 001h,0feh	; 745b
	defb 002h,0feh	; 745d
	defb 005h,0feh	; 745f
	defb 0ffh,0fbh	; 7461
	defb 002h,0feh	; 7463
	defb 002h,0ffh	; 7465
	defb 002h,000h	; 7467
	defb 002h,000h	; 7469
	defb 002h,001h	; 746b
	defb 002h,002h	; 746d
	defb 002h,005h	; 746f
	defb 002h,0ffh	; 7471

; ======================================================================
; CODIGO 0x7473..0x7585  (274 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL PROFESOR (sprites 8 y 9, E0D0), arriba a la derecha. Pasea entre
; X = 0xB8 y 0xE8 (bit 6 de E270 el sentido). Cuando el mono coge la
; tarjeta buena (bit 1) se planta en 0xB8 con la cara grande; cuando
; le llega (bit 2) la lleva andando hasta el ?, la escribe (0x7207),
; vuelve a su sitio y el mono y el se ponen a bailar (E276 = 0x88).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PROFESOR:		; Un paso del profesor segun E270
	ld a,(0e270h)		;7473
	ld hl,0e0d0h		;7476
	bit 2,a		;7479
	jr nz,PROFESOR_LLEVA		;747b
	inc hl			;747d
	bit 1,a		;747e
	jr nz,PROFESOR_ESPERA		;7480
	ld a,(0e003h)		;7482   ; Cada dos fotogramas un pixel
	and 001h		;7485
	ret nz			;7487
	ld a,0b8h		;7488   ; En 0xB8 o 0xE8 da la vuelta (bit 6 de E270)
	cp (hl)			;748a
	jr z,PROFESOR_DA_VUELTA		;748b
	ld a,0e8h		;748d
	cp (hl)			;748f
	jr nz,PROFESOR_ANDA		;7490
PROFESOR_DA_VUELTA:		; Cambia el bit 6
	ld a,(0e270h)		;7492
	xor 040h		;7495
	ld (0e270h),a		;7497
PROFESOR_ANDA:		; Un pixel y los patrones segun el sentido
	ld a,(0e270h)		;749a   ; Hacia la izquierda: X - 1 y los patrones de 0x758D; hacia la derecha: X + 1 y los de 0x7585
	rla			;749d
	rla			;749e
	ld a,(hl)			;749f
	dec a			;74a0
	ld de,0758dh		;74a1
	jr nc,PROFESOR_X		;74a4
	inc a			;74a6
	inc a			;74a7
	ld de,07585h		;74a8
PROFESOR_X:		; La X a los dos sprites y la animacion (0x7565)
	ld (hl),a			;74ab
	ld (0e0d5h),a		;74ac
	ex de,hl			;74af
	ld a,040h		;74b0
	ld (0e004h),a		;74b2
	jp PROFESOR_ANIMACION		;74b5
PROFESOR_ESPERA:		; Con la tarjeta en marcha: vuelve a 0xB8 y se queda con la cara grande (0xF0/0xF4)
	ld de,0e0d5h		;74b8
	ld a,0b8h		;74bb
	cp (hl)			;74bd
	jr z,PROFESOR_CARA_GRANDE		;74be
	dec (hl)			;74c0
	ex de,hl			;74c1
	dec (hl)			;74c2
	ld hl,0758dh		;74c3
	jp PROFESOR_ANIMACION		;74c6
PROFESOR_CARA_GRANDE:		; Los patrones 0xF0 y 0xF4 (la cara de 0x5ABF)
	dec hl			;74c9
	inc hl			;74ca
	inc hl			;74cb
	ld (hl),0f0h		;74cc
	ex de,hl			;74ce
	inc hl			;74cf
	ld (hl),0f4h		;74d0
	dec hl			;74d2
	dec hl			;74d3
	ret			;74d4
PROFESOR_LLEVA:		; Con la tarjeta entregada: anda hasta la columna del ? (E271) y espera E004; entonces escribe la cifra escondida en el ? (0x7207), sonido 0x0D, bit 5, y esconde la tarjeta
	ld a,(0e270h)		;74d5
	inc hl			;74d8
	bit 5,a		;74d9
	jr nz,PROFESOR_VUELVE		;74db
	ld a,(0e271h)		;74dd
	cp (hl)			;74e0
	jr nz,PROFESOR_VUELVE		;74e1
	add a,0f3h		;74e3
	ld e,a			;74e5
	dec hl			;74e6
	ld d,(hl)			;74e7
	ld hl,0e004h		;74e8
	dec (hl)			;74eb
	xor a			;74ec
	cp (hl)			;74ed
	pop hl			;74ee
	ret nz			;74ef
	ld a,(0e002h)		;74f0   ; La cifra escondida del jugador (E1CD/E1CE) en bloque de 2x2 sobre el ?
	ld hl,0e1cdh		;74f3
	rla			;74f6
	jr nc,PROFESOR_ESCRIBE		;74f7
	inc hl			;74f9
PROFESOR_ESCRIBE:		; La cifra escondida en el ?
	ld a,(hl)			;74fa
	ld hl,07207h		;74fb
	add a,a			;74fe
	add a,a			;74ff
	call HL_MAS_A		;7500
	ld bc,00202h		;7503
	call PINTA_BLOQUE		;7506
	ld a,00dh		;7509
	call SONIDO		;750b
	ld a,(0e270h)		;750e
	set 5,a		;7511
	ld (0e270h),a		;7513
	ld a,0e1h		;7516
	ld hl,0e0f8h		;7518
	ld (hl),a			;751b
	inc hl			;751c
	ld (hl),a			;751d
	ret			;751e
PROFESOR_VUELVE:		; Vuelve hacia la derecha; en 0xB8 carga las caras de 0x5E7F en 0x1800, pone a los dos con ella (0x08/0x0C) y arranca el baile (E276 = 0x88)
	dec (hl)			;751f
	ld hl,0e0d5h		;7520
	dec (hl)			;7523
	ld a,0b8h		;7524
	cp (hl)			;7526
	pop de			;7527
	ld hl,0758dh		;7528
	jr nz,PROFESOR_ANIMACION		;752b
	ld a,088h		;752d
	ld (0e276h),a		;752f
	ld hl,05e7fh		;7532
	ld de,01800h		;7535
	ld bc,00080h		;7538
	di			;753b
	call COPIA_A_VRAM		;753c
	ei			;753f
	ld hl,0e0b2h		;7540
	ld (hl),008h		;7543
	inc hl			;7545
	inc hl			;7546
	inc hl			;7547
	inc hl			;7548
	ld (hl),00ch		;7549
	ld hl,0e0d2h		;754b
	ld (hl),008h		;754e
	inc hl			;7550
	inc hl			;7551
	inc hl			;7552
	inc hl			;7553
	ld (hl),00ch		;7554
	ld a,088h		;7556
	ld (0e276h),a		;7558
	ret			;755b
SIN_LLAMADAS_755C:		; `dec (hl) / ld hl,0E0D4h / dec (hl) / pop hl / ld hl,758Dh`: nueve bytes a los que no salta nadie y que caen en PROFESOR_ANIMACION; parecen un resto de la vuelta del profesor (0x751F hace lo mismo)
	dec (hl)			;755c
	ld hl,0e0d4h		;755d
	dec (hl)			;7560
	pop hl			;7561
	ld hl,0758dh		;7562
PROFESOR_ANIMACION:		; Los dos patrones de la fase (fotograma / 4 & 3) de la tabla HL; con la tarjeta entregada, la tarjeta (E0F9) va con el
	ld a,(0e003h)		;7565
	and 00ch		;7568
	srl a		;756a
	call HL_MAS_A		;756c
	ld a,(hl)			;756f
	ld (0e0d2h),a		;7570
	inc hl			;7573
	ld a,(hl)			;7574
	ld (0e0d6h),a		;7575
	ld a,(0e270h)		;7578
	bit 2,a		;757b
	ret z			;757d
	ld a,(0e0d1h)		;757e
	ld (0e0f9h),a		;7581
	ret			;7584

; ----------------------------------------------------------------------
; DATOS patrones_profesor_derecha: Las cuatro fases del profesor hacia la
;   derecha: (18,24) (1C,28) (18,24) (20,2C): el mono andando (los sprites
;   6-11 de la VRAM, que son el 0-5 de 0x56BF)
;   0x7585..0x758d  (8 bytes)
DATA_patrones_profesor_derecha:
	defb 018h,024h	; 7585
	defb 01ch,028h	; 7587
	defb 018h,024h	; 7589
	defb 020h,02ch	; 758b

; ----------------------------------------------------------------------
; DATOS patrones_profesor_izquierda: Las cuatro hacia la izquierda: (98,A4)
;   (9C,A8) (98,A4) (A0,AC): los espejos del mono andando
;   0x758d..0x7595  (8 bytes)
DATA_patrones_profesor_izquierda:
	defb 098h,0a4h	; 758d
	defb 09ch,0a8h	; 758f
	defb 098h,0a4h	; 7591
	defb 0a0h,0ach	; 7593

; ======================================================================
; CODIGO 0x7595..0x75b7  (34 bytes)
; ======================================================================


PINTA_LEVEL_SELECT:		; "PLAYER n" en la fila 2, "LEVEL SELECT" en la 6 y las cinco lineas "LEVEL n --- n-key" en las filas 9, 11, 13, 15 y 17
	ld hl,075b7h		;7595
	call PINTA_LISTA_TILES		;7598
	ld a,(0e002h)		;759b
	rlc a		;759e
	and 001h		;75a0
	add a,031h		;75a2
	ld de,03853h		;75a4
	call VPOKE		;75a7
	ld hl,075c0h		;75aa
	ld b,006h		;75ad
LEVEL_SELECT_LINEAS:		; Las seis listas
	push bc			;75af
	call PINTA_LISTA_TILES		;75b0
	pop bc			;75b3
	djnz LEVEL_SELECT_LINEAS		;75b4
	ret			;75b6

; ----------------------------------------------------------------------
; DATOS rotulo_player_arriba: "PLAYER" en la fila 2, columna 12 (el numero en
;   la 19)
;   0x75b7..0x75c0  (9 bytes)
DATA_rotulo_player_arriba:
	defb 04ch,038h,050h,04ch,041h,059h,045h,052h,0ffh	; 75b7  L8PLAYER.

; ----------------------------------------------------------------------
; DATOS rotulo_level_select: "LEVEL  SELECT" en la fila 6, columna 10
;   0x75c0..0x75d0  (16 bytes)
DATA_rotulo_level_select:
	defb 0cah,038h,04ch,045h,056h,045h,04ch,000h,000h,053h,045h,04ch,045h,043h,054h,0ffh	; 75c0  .8LEVEL..SELECT.

; ----------------------------------------------------------------------
; DATOS lineas_de_nivel: Cinco listas de 19 bytes: "LEVEL 1 --- 1-key" en la
;   fila 9, columna 8, y las de 2 a 5 en las filas 11, 13, 15 y 17
;   0x75d0..0x762f  (95 bytes)
DATA_lineas_de_nivel:
	defb 028h,039h,04ch,045h,056h,045h,04ch,000h,031h,000h,040h,040h,040h,000h,031h,040h,05ch,05dh,0ffh	; 75d0  (9LEVEL.1.@@@.1@\].
	defb 068h,039h,04ch,045h,056h,045h,04ch,000h,032h,000h,040h,040h,040h,000h,032h,040h,05ch,05dh,0ffh	; 75e3  h9LEVEL.2.@@@.2@\].
	defb 0a8h,039h,04ch,045h,056h,045h,04ch,000h,033h,000h,040h,040h,040h,000h,033h,040h,05ch,05dh,0ffh	; 75f6  .9LEVEL.3.@@@.3@\].
	defb 0e8h,039h,04ch,045h,056h,045h,04ch,000h,034h,000h,040h,040h,040h,000h,034h,040h,05ch,05dh,0ffh	; 7609  .9LEVEL.4.@@@.4@\].
	defb 028h,03ah,04ch,045h,056h,045h,04ch,000h,035h,000h,040h,040h,040h,000h,035h,040h,05ch,05dh,0ffh	; 761c  (:LEVEL.5.@@@.5@\].

; ======================================================================
; CODIGO 0x762f..0x765f  (48 bytes)
; ======================================================================


LEVEL_SELECT_TECLA:		; Mantiene la musica del menu; descuenta la espera (E23F, 0x0F00 fotogramas); con la tecla 1-5 recien pulsada, el nivel (0x765F) al jugador; carry si ya esta decidido
	ld a,(0e024h)		;762f
	or a			;7632
	jr nz,LEVEL_SELECT_ESPERA_CUENTA		;7633
	ld a,091h		;7635
	call SONIDO		;7637
LEVEL_SELECT_ESPERA_CUENTA:		; La espera y las teclas
	ld hl,(0e23fh)		;763a   ; Sin espera: se queda el nivel que hubiera
	ld a,l			;763d
	or h			;763e
	jr z,LEVEL_SELECT_DECIDIDO		;763f
	dec hl			;7641
	ld (0e23fh),hl		;7642
	ld hl,0e23eh		;7645   ; Lo pulsado ahora y no antes
	ld a,(hl)			;7648
	dec hl			;7649
	and (hl)			;764a
	xor (hl)			;764b
	cp 011h		;764c
	ret nc			;764e
	ld hl,0765fh		;764f
	call HL_MAS_A		;7652
	ld a,(hl)			;7655
	cp 0ffh		;7656
	ret z			;7658
	call NIVEL_DEL_JUGADOR		;7659
	ld (hl),a			;765c
LEVEL_SELECT_DECIDIDO:		; Carry
	scf			;765d
	ret			;765e

; ----------------------------------------------------------------------
; DATOS nivel_por_tecla: El nivel (0-4) segun el mapa de bits de las teclas
;   1-5 (1, 2, 4, 8, 16); 0xFF si no es una sola tecla
;   0x765f..0x7670  (17 bytes)
DATA_nivel_por_tecla:
	defb 0ffh,000h,001h,0ffh,002h,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h	; 765f  .................

; ======================================================================
; CODIGO 0x7670..0x7700  (144 bytes)
; ======================================================================


LEVEL_LINEA_PARPADEA:		; Cada 4 fotogramas: la linea del nivel elegido se pinta o se borra (0x20 veces); al acabar, al estado 9; con dos jugadores, primero el LEVEL SELECT del 2P
	ld a,(0e003h)		;7670
	and 003h		;7673
	ret nz			;7675
	ld hl,0e1b3h		;7676
	dec (hl)			;7679
	jr z,LEVEL_LINEA_FIN		;767a
	ld a,(hl)			;767c
	and 001h		;767d
	call NIVEL_DEL_JUGADOR		;767f
	ld a,(hl)			;7682
	ld hl,075d0h		;7683
	jr z,LEVEL_LINEA_BORRA		;7686
	call HL_MAS_19A		;7688
	jp PINTA_LISTA_TILES		;768b
LEVEL_LINEA_BORRA:		; Los 16 tiles de la linea a cero
	call HL_MAS_19A		;768e
	xor a			;7691
	ld bc,00010h		;7692
	ld e,(hl)			;7695
	inc hl			;7696
	ld d,(hl)			;7697
	jp RELLENA_VRAM		;7698
LEVEL_LINEA_FIN:		; Al estado 9 (o al 2P)
	ld a,(0e00dh)		;769b
	or a			;769e
	jp nz,LEVEL_AL_ESTADO_9		;769f
	ld hl,0e002h		;76a2   ; Con dos jugadores y el turno del 1P: cambia al 2P y repite el LEVEL SELECT
	bit 5,(hl)		;76a5
	jp z,SIGUIENTE_ESTADO_50		;76a7
	bit 7,(hl)		;76aa
	jr nz,LEVEL_YA_LOS_DOS		;76ac
	set 7,(hl)		;76ae
	ld hl,0e152h		;76b0
	ld (hl),000h		;76b3
	ld a,050h		;76b5
	ld (0e004h),a		;76b7
	ret			;76ba
LEVEL_YA_LOS_DOS:		; Vuelve al 1P
	res 7,(hl)		;76bb
LEVEL_AL_ESTADO_9:		; Fase superada y banderas a cero, y al 9
	xor a			;76bd
	ld (0e00dh),a		;76be
	ld (0e152h),a		;76c1
	jp SIGUIENTE_ESTADO_50		;76c4
HL_MAS_19A:		; HL += A x 19: la linea A de 0x75D0
	ld c,a			;76c7
	sla c		;76c8
	ld b,c			;76ca
	add a,b			;76cb
	sla c		;76cc
	sla c		;76ce
	sla c		;76d0
	add a,c			;76d2
	call HL_MAS_A		;76d3
	ret			;76d6
NIVEL_DEL_JUGADOR:		; HL = E153 (1P) o E154 (2P)
	push af			;76d7
	ld a,(0e002h)		;76d8
	ld hl,0e153h		;76db
	bit 7,a		;76de
	jr z,NIVEL_DEL_JUGADOR_FIN		;76e0
	inc hl			;76e2
NIVEL_DEL_JUGADOR_FIN:		; Fuera
	pop af			;76e3
	ret			;76e4
PINTA_LEVEL:		; "LEVEL" en la fila 13, columna 10, y el nivel del jugador mas uno
	ld hl,07700h		;76e5
	call PINTA_LISTA_TILES		;76e8
	ld a,(0e002h)		;76eb
	bit 7,a		;76ee
	ld hl,0e153h		;76f0
	jr z,PINTA_LEVEL_NUMERO		;76f3
	inc hl			;76f5
PINTA_LEVEL_NUMERO:		; El nivel mas uno
	ld de,039b1h		;76f6
	ld a,(hl)			;76f9
	add a,031h		;76fa
	call VPOKE		;76fc
	ret			;76ff

; ----------------------------------------------------------------------
; DATOS rotulo_level: "LEVEL" en la fila 13, columna 10
;   0x7700..0x7708  (8 bytes)
DATA_rotulo_level:
	defb 0aah,039h,04ch,045h,056h,045h,04ch,0ffh	; 7700  .9LEVEL.

; ======================================================================
; CODIGO 0x7708..0x782c  (292 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; RESPONDER. El segundo boton (SELECT), o el 0x20 del guion en la
; demo, con una tarjeta cogida (E1AF): la tarjeta parpadea 5 veces
; (E238) y luego se compara su cifra con la escondida (E1CD/E1CE).
; Acierto: 500 puntos, sonido 0x95 y el bit 4 de E270 (la tarjeta se
; cierra y cae al suelo para que el mono la lleve). Fallo: una cara
; llorando mas (E057), sonido 0x0E; a la tercera, E276 = 1 y otro
; mono trae la respuesta en globo (0x6D27).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
RESPONDE:		; Con el boton (o el 0x20 de la demo), si no salta ni hay otra abriendose: arranca el parpadeo de la tarjeta cogida
	ld a,(0e002h)		;7708
	bit 6,a		;770b
	jr nz,RESPONDE_PARTIDA		;770d
	ld a,(0e10bh)		;770f   ; La demo: el 0x20 del guion
	cp 020h		;7712
	ret nz			;7714
	jr RESPONDE_TARJETA		;7715
RESPONDE_PARTIDA:		; En la partida: sin saltar, sin otra tarjeta, y el segundo boton
	ld a,(0e10ch)		;7717   ; Saltando (estado 3) no; ni con otra tarjeta en marcha
	cp 003h		;771a
	ret z			;771c
	ld a,(0e238h)		;771d
	or a			;7720
	ret nz			;7721
	ld hl,0e008h		;7722   ; El segundo boton recien pulsado
	ld a,(hl)			;7725
	inc hl			;7726
	xor (hl)			;7727
	and (hl)			;7728
	bit 5,a		;7729
	ret z			;772b
RESPONDE_TARJETA:		; Sin tarjeta cogida (0xFF) nada; sonido 0x0B, su indice a E239, su posicion (Y, X) a E23A/E23B y cinco parpadeos
	ld hl,0e1afh		;772c
	ld a,0ffh		;772f
	cp (hl)			;7731
	ret z			;7732
	ld a,00bh		;7733
	call SONIDO		;7735
	ld a,(hl)			;7738
	ld (0e239h),a		;7739
	push af			;773c
	ld a,(0e051h)		;773d
	dec a			;7740
	and 007h		;7741
	add a,a			;7743
	ld hl,0509eh		;7744
	call HL_MAS_A		;7747
	ld e,(hl)			;774a
	inc hl			;774b
	ld d,(hl)			;774c
	ex de,hl			;774d
	pop af			;774e
	add a,a			;774f
	call HL_MAS_A		;7750
	ld d,(hl)			;7753
	inc hl			;7754
	ld e,(hl)			;7755
	ld (0e23ah),de		;7756
	ld a,005h		;775a
	ld (0e238h),a		;775c
	ret			;775f
TARJETA_PARPADEA:		; Cada 4 fotogramas: la tarjeta en blanco (0x782C) o con su cifra (0x508A); al acabar, la comparacion
	ld a,(0e003h)		;7760
	and 003h		;7763
	ret nz			;7765
	ld hl,0e238h		;7766
	dec (hl)			;7769
	xor a			;776a
	cp (hl)			;776b
	jr z,TARJETA_COMPARA		;776c
	ld a,(hl)			;776e
	ld hl,0782ch		;776f
	rra			;7772
	jr nc,TARJETA_PARPADEA_PINTA		;7773
	ld a,(0e239h)		;7775
	add a,a			;7778
	call TARJETAS_DEL_JUGADOR		;7779
	call HL_MAS_A		;777c
	inc hl			;777f
	ld a,(hl)			;7780
	add a,a			;7781
	ld hl,0508ah		;7782
	call HL_MAS_A		;7785
	ld e,(hl)			;7788
	inc hl			;7789
	ld d,(hl)			;778a
	ex de,hl			;778b
TARJETA_PARPADEA_PINTA:		; El bloque de 3x2 en la posicion de la tarjeta
	ld de,(0e23ah)		;778c
	ld bc,00302h		;7790
	jp PINTA_BLOQUE		;7793
TARJETA_COMPARA:		; Acierto: sonido 0x95, 500 puntos, bit 4 de E270 y la tarjeta por repintar; fallo: E057++, sonido 0x0E, las caras, y a los tres E276 = 1
	ld hl,0e1cdh		;7796
	ld a,(0e002h)		;7799
	bit 7,a		;779c
	jr z,TARJETA_COMPARA_CIFRA		;779e
	inc hl			;77a0
TARJETA_COMPARA_CIFRA:		; La cifra de la tarjeta contra la escondida
	push hl			;77a1
	ld a,(0e239h)		;77a2
	add a,a			;77a5
	call TARJETAS_DEL_JUGADOR		;77a6
	call HL_MAS_A		;77a9
	ld (0e243h),hl		;77ac
	inc hl			;77af
	ld a,(hl)			;77b0
	ld c,a			;77b1
	pop hl			;77b2
	cp (hl)			;77b3
	jr nz,TARJETA_FALLO		;77b4
	ld a,095h		;77b6
	call SONIDO		;77b8
	ld de,00500h		;77bb
	ld c,000h		;77be
	call SUMA_PUNTOS		;77c0
	ld hl,0e270h		;77c3
	set 4,(hl)		;77c6
	ld a,(0e1afh)		;77c8
	add a,a			;77cb
	call TARJETAS_DEL_JUGADOR		;77cc
	call HL_MAS_A		;77cf
	set 7,(hl)		;77d2
	ret			;77d4
TARJETA_FALLO:		; Un fallo mas
	ld hl,0e057h		;77d5
	inc (hl)			;77d8
	ld a,00eh		;77d9
	call SONIDO		;77db
	push hl			;77de
	call PINTA_FALLOS		;77df
	pop hl			;77e2
	ld a,003h		;77e3
	cp (hl)			;77e5
	ret nz			;77e6
	ld a,001h		;77e7
	ld (0e276h),a		;77e9
	ret			;77ec
TIEMPO_A_PUNTOS:		; Fase acabada: cada 4 fotogramas un segundo menos y 10 puntos mas (sonido 0x0F); a cero, el reloj a 05:00, fase superada (E00D) y al estado 16
	ld hl,0e004h		;77ed
	ld a,(hl)			;77f0
	or a			;77f1
	jr z,TIEMPO_A_PUNTOS_PASO		;77f2
	dec (hl)			;77f4
	ret			;77f5
TIEMPO_A_PUNTOS_PASO:		; Cada 4 fotogramas
	ld a,(0e003h)		;77f6
	and 003h		;77f9
	ret nz			;77fb
	ld hl,(0e055h)		;77fc
	ld a,h			;77ff
	or l			;7800
	jr z,TIEMPO_AGOTADO		;7801
	ld hl,0e056h		;7803
	ld c,(hl)			;7806
	dec hl			;7807
	call RELOJ_RESTA		;7808
	ld de,00010h		;780b
	ld c,000h		;780e
	call SUMA_PUNTOS		;7810
	ld a,00fh		;7813
	jp SONIDO		;7815
TIEMPO_AGOTADO:		; 05:00, E23C = 0, E00D = 1, estado 16
	ld hl,00500h		;7818
	ld (0e055h),hl		;781b
	xor a			;781e
	ld (0e23ch),a		;781f
	inc a			;7822
	ld (0e00dh),a		;7823
	ld a,010h		;7826
	ld (0e000h),a		;7828
	ret			;782b

; ----------------------------------------------------------------------
; DATOS tarjeta_en_blanco_3x2: Seis tiles 0x61: la tarjeta en blanco de 3x2
;   con la que parpadea
;   0x782c..0x7834  (8 bytes)
DATA_tarjeta_en_blanco_3x2:
	defb 061h,061h,061h,061h,061h,061h,061h,061h	; 782c  aaaaaaaa

; ======================================================================
; CODIGO 0x7834..0x78db  (167 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA TARJETA DE LA RESPUESTA (sprite 18, E0F8, patron 0xFC amarillo),
; segun los bits de E270: 4 espera a que la tarjeta se cierre y la
; suelta, 3 cae hasta el suelo, 1 el mono la lleva en la cabeza,
; 0 sube sola hasta el profesor. Sin ninguno, mira si el mono la
; recoge del suelo.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
TARJETA_PASO:		; Un paso de la tarjeta de la respuesta
	ld a,(0e270h)		;7834
	rra			;7837
	jr c,TARJETA_SUBE		;7838
	rra			;783a
	jr c,TARJETA_EN_CABEZA		;783b
	rra			;783d
	rra			;783e
	jr c,TARJETA_CAE		;783f
	rra			;7841
	jr c,TARJETA_SE_SUELTA		;7842
	call TOCA_LA_TARJETA_CAIDA		;7844   ; Sin bits: si el mono la toca en el suelo (0x6ABB), la coge: bit 1 y los sprites con la tarjeta (E10E = 2)
	ret c			;7847
	ld hl,0e270h		;7848
	set 1,(hl)		;784b
	ld hl,0e10eh		;784d
	ld (hl),002h		;7850
	ret			;7852
TARJETA_SUBE:		; Bit 0: un pixel arriba hasta Y = 0; entonces bit 2, 500 puntos y sonido 0x9B
	ld hl,0e0f8h		;7853
	xor a			;7856
	cp (hl)			;7857
	jr z,TARJETA_SUBE_LLEGA		;7858
	dec (hl)			;785a
	ret			;785b
TARJETA_SUBE_LLEGA:		; Arriba: bit 2, 500 puntos y sonido 0x9B
	ld hl,0e270h		;785c
	res 0,(hl)		;785f
	set 2,(hl)		;7861
	ld de,00500h		;7863
	ld c,000h		;7866
	call SUMA_PUNTOS		;7868
	ld a,09bh		;786b
	call SONIDO		;786d
	ret			;7870
TARJETA_EN_CABEZA:		; Bit 1: en la posicion del mono
	ld hl,0e0b0h		;7871
	ld b,(hl)			;7874
	inc hl			;7875
	ld c,(hl)			;7876
	ld hl,0e0f8h		;7877
	ld (hl),b			;787a
	inc hl			;787b
	ld (hl),c			;787c
	ret			;787d
TARJETA_CAE:		; Bit 3: un pixel abajo hasta el suelo (0x6924); entonces bit 3 fuera y el mono sin tarjeta cogida (E1AF = 0xFF)
	ld hl,0e0f8h		;787e
	ld b,(hl)			;7881
	inc hl			;7882
	ld c,(hl)			;7883
	call HAY_SUELO		;7884
	jr nc,TARJETA_CAE_SUELO		;7887
	ld hl,0e0f8h		;7889
	inc (hl)			;788c
	ret			;788d
TARJETA_CAE_SUELO:		; En el suelo: soltada
	ld hl,0e270h		;788e
	res 3,(hl)		;7891
	ld a,0ffh		;7893
	ld (0e1afh),a		;7895
	ret			;7898
TARJETA_SE_SUELTA:		; Bit 4: espera a que la tarjeta cogida este cerrada (0x13), repintando; entonces bit 4 -> bit 3, borra la tarjeta de la pantalla y pone el sprite en su sitio
	ld a,(0e1afh)		;7899
	add a,a			;789c
	call TARJETAS_DEL_JUGADOR		;789d
	call HL_MAS_A		;78a0
	ld a,(hl)			;78a3
	cp 013h		;78a4
	jr z,TARJETA_SE_SUELTA_YA		;78a6
	pop hl			;78a8
	jp PINTA_TARJETAS		;78a9
TARJETA_SE_SUELTA_YA:		; Cerrada: la suelta
	ld hl,0e270h		;78ac
	ld a,(hl)			;78af
	xor 018h		;78b0
	ld (hl),a			;78b2
	ld a,(0e1afh)		;78b3
	add a,a			;78b6
	ld hl,0e15ah		;78b7
	call HL_MAS_A		;78ba
	ld d,(hl)			;78bd
	inc hl			;78be
	ld e,(hl)			;78bf
	push de			;78c0
	ld bc,00202h		;78c1
	ld hl,078dbh		;78c4
	call PINTA_BLOQUE		;78c7
	pop de			;78ca
	ld hl,0e0f8h		;78cb
	ld (hl),d			;78ce
	inc hl			;78cf
	ld (hl),e			;78d0
	ld a,0ffh		;78d1
	ld (0e1afh),a		;78d3
	inc a			;78d6
	ld (0e238h),a		;78d7
	ret			;78da

; ----------------------------------------------------------------------
; DATOS bloque_vacio: Cuatro tiles 0: el bloque de 2x2 vacio (borra la flecha,
;   la tarjeta suelta y el hueco de la percha)
;   0x78db..0x78df  (4 bytes)
DATA_bloque_vacio:
	defb 000h,000h,000h,000h	; 78db

; ======================================================================
; CODIGO 0x78df..0x7a71  (402 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ARRANCAR UN SONIDO (A = numero). Del 1 al 0x10 son efectos de un
; canal (el C); del 0x91 al 0x9B musicas de dos canales (A y B) y del
; 0x9D en adelante de tres. La tabla de 0x7A7B da el puntero de la
; pista del primer canal y los siguientes son las palabras que le
; siguen (por eso los numeros de musica van de dos en dos). Prioridad:
; si el canal ya suena algo igual o mayor, nada (salvo el 2, que
; siempre entra); el 0xA0 (perder la vida) entra sobre todo pero se
; apunta como 0x20, y el 0xA1 son tres pistas mudas: callar todo.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
SONIDO:		; Arranca el sonido A si hay partida en marcha (bit 6 de E002)
	push hl			;78df
	ld hl,0e002h		;78e0
	bit 6,(hl)		;78e3
	pop hl			;78e5
	ret z			;78e6
SONIDO_YA:		; Arranca el sonido A sin mirar nada (D = 0: con prioridad)
	di			;78e7
	push hl			;78e8
	push de			;78e9
	push bc			;78ea
	push af			;78eb
	ld d,000h		;78ec
	call SONIDO_ARRANCA		;78ee
	pop af			;78f1
	pop bc			;78f2
	pop de			;78f3
	pop hl			;78f4
	ei			;78f5
	ret			;78f6
SONIDO_DEL_ACTOR:		; Un efecto pedido desde un actor: los cangrejos solo pueden pedir el 9; los demas son del mono
	cp 009h		;78f7
	jr z,SONIDO_CANALES		;78f9
	ld b,a			;78fb
	ld a,(ix+05bh)		;78fc
	and 00fh		;78ff
	ret nz			;7901
	ld a,b			;7902
	jr SONIDO_CANALES		;7903
SONIDO_ARRANCA:		; Los menores de 0x20 pasan por el filtro del actor; reparte los canales y apunta las pistas
	cp 020h		;7905
	jr c,SONIDO_DEL_ACTOR		;7907
SONIDO_CANALES:		; B canales desde HL: 1 desde E026 (efectos), 2 desde E012 (musicas 0x91-0x9B), 3 (0x9D en adelante)
	ld b,002h		;7909
	ld hl,0e012h		;790b
	cp 091h		;790e
	jr c,SONIDO_UN_CANAL		;7910
	cp 09dh		;7912
	jr c,SONIDO_PRIORIDAD		;7914
	inc b			;7916
	jr SONIDO_PRIORIDAD		;7917
SONIDO_UN_CANAL:		; Un canal, el C (E026)
	dec b			;7919
	ld hl,0e026h		;791a
SONIDO_PRIORIDAD:		; D = 1 (desde el bucle) no mira; si no, contra el numero que suena en el canal
	dec d			;791d
	jr z,SONIDO_PISTAS		;791e
	cp (hl)			;7920
	jr z,SONIDO_IGUAL		;7921
	jr c,SONIDO_IGUAL		;7923
	cp 0a0h		;7925   ; 0xA0 se apunta como 0x20: entra sobre todo y luego lo pisa cualquiera
	jr nz,SONIDO_PISTAS		;7927
	and 07fh		;7929
SONIDO_PISTAS:		; Indice = numero & 0x3F en la tabla de 0x7A7B; una palabra por canal seguida
	ld c,a			;792b
	and 03fh		;792c
	add a,a			;792e
	ld de,07a7bh		;792f
	ex de,hl			;7932
	call HL_MAS_A		;7933
	ex de,hl			;7936
SONIDO_CANAL:		; Arranca un canal: 1 fotograma, duracion 1, el numero, y el puntero de la tabla; y al siguiente canal (10 bytes mas alla)
	dec hl			;7937
	dec hl			;7938
	ld (hl),001h		;7939
	inc hl			;793b
	ld (hl),001h		;793c
	inc hl			;793e
	ld a,c			;793f
	ld (hl),a			;7940
	inc hl			;7941
	ld a,(de)			;7942
	ld (hl),a			;7943
	inc hl			;7944
	inc de			;7945
	ld a,(de)			;7946
	ld (hl),a			;7947
	ld a,008h		;7948
	call HL_MAS_A		;794a
	inc de			;794d
	djnz SONIDO_CANAL		;794e
SONIDO_IGUAL:		; El mismo numero: solo el 2 se repite
	cp 002h		;7950
	jr z,SONIDO_PISTAS		;7952
	ret			;7954
SONIDO_REPITE:		; 0xFE n en la pista: vuelve a arrancar el mismo sonido n veces (0xFF, siempre); despues se apaga
	inc hl			;7955
	ld a,(hl)			;7956
	inc a			;7957
	jr z,SONIDO_REARRANCA		;7958
	inc (ix+009h)		;795a
	dec a			;795d
	cp (ix+009h)		;795e
	jp z,CANAL_APAGA		;7961
SONIDO_REARRANCA:		; Otra vez desde el principio, sin prioridad
	ld a,(ix+002h)		;7964
	push bc			;7967
	ld d,001h		;7968
	call SONIDO_ARRANCA		;796a
	pop bc			;796d
	ret			;796e

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL REPRODUCTOR, en cada interrupcion (aunque el juego vaya atrasado).
; Tres canales de 10 bytes desde E010: +0 lo que queda de nota, +1 la
; duracion, +2 el numero (0 = libre), +3/+4 la pista, +5 octava, +6
; volumen de arranque, +7 volumen en curso, +8 la envolvente, +9 las
; repeticiones. Para cada canal ocupado descuenta la nota y, si acabo,
; lee el siguiente evento de su pista. Dos formatos segun el bit 7:
; EFECTO: [0x2n duracion n] vp pp -> volumen v, periodo 0xppp
; MUSICA: [0xFD oo] ln -> l duracion (tabla 0x7AC3), n nota 0-11 en
; la octava de 0x7A71 bajada oo&7 octavas, 12 silencio;
; oo>>3 es el volumen de arranque
; 0xFE n repite n veces (0xFF siempre), 0xFF apaga el canal.
; La musica lleva envolvente: la nota arranca al volumen v y baja tres
; pasos en tres fotogramas, se mantiene, y baja dos mas al acabar.
; Es el reproductor que Konami repite en sus cartuchos, con otras direcciones.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
SUENA:		; Un fotograma de los tres canales (IX = E010, +10 por canal; C = registro de periodo)
	ld c,001h		;796f
	ld ix,0e010h		;7971
	exx			;7975
	ld b,003h		;7976
	ld de,0000ah		;7978
SUENA_CANAL:		; Siguiente canal
	exx			;797b
	ld a,(ix+002h)		;797c
	or a			;797f
	call nz,SUENA_PASO		;7980
	inc c			;7983
	inc c			;7984
	exx			;7985
	add ix,de		;7986
	djnz SUENA_CANAL		;7988
	ret			;798a
SUENA_PASO:		; Musica (bit 7) por 79E5; efecto: descuenta y, a cero, siguiente evento
	jp m,MUSICA_PASO		;798b
	dec (ix+000h)		;798e
	ret nz			;7991
SIGUIENTE_EVENTO:		; Lee la pista: 0xFE repite, 0xFF apaga, musica por 7A10, efecto aqui
	ld l,(ix+003h)		;7992
	ld h,(ix+004h)		;7995
	ld a,(hl)			;7998
	cp 0feh		;7999
	jr z,SONIDO_REPITE		;799b
	jr nc,CANAL_APAGA		;799d
	bit 7,(ix+002h)		;799f
	jp nz,MUSICA_EVENTO		;79a3
	and 0f0h		;79a6
	cp 020h		;79a8
	jr nz,EFECTO_EVENTO		;79aa
	ld a,(hl)			;79ac
	and 00fh		;79ad
	ld (ix+001h),a		;79af
	inc hl			;79b2
EFECTO_EVENTO:		; Nibble alto volumen, nibble bajo y byte siguiente el periodo
	ld a,(hl)			;79b3
	and 0f0h		;79b4
	ld b,a			;79b6
	xor (hl)			;79b7
	ld d,a			;79b8
	inc hl			;79b9
	ld e,(hl)			;79ba
	inc hl			;79bb
	ld (ix+003h),l		;79bc
	ld (ix+004h),h		;79bf
	ex de,hl			;79c2
	call PSG_PERIODO		;79c3
	ld a,b			;79c6
	rrca			;79c7
	rrca			;79c8
	rrca			;79c9
	rrca			;79ca
	and 00fh		;79cb
NOTA_ARRANCA:		; H = volumen; +0 = duracion, +8 = duracion + 3 (la envolvente); y al PSG
	ld h,a			;79cd
	ld a,(ix+001h)		;79ce
	ld (ix+000h),a		;79d1
	add a,003h		;79d4
	ld (ix+008h),a		;79d6
	jr PSG_VOLUMEN		;79d9
CANAL_APAGA:		; Numero 0 y volumen 0
	xor a			;79db
	ld (ix+009h),a		;79dc
	ld (ix+002h),a		;79df
	ld h,a			;79e2
	jr PSG_VOLUMEN		;79e3
MUSICA_PASO:		; Descuenta la nota; envolvente: tres pasos abajo al principio, dos al final
	dec (ix+000h)		;79e5
	jr z,SIGUIENTE_EVENTO		;79e8
	dec (ix+008h)		;79ea
	ld a,(ix+008h)		;79ed
	cp (ix+000h)		;79f0
	jr nz,ENVOLVENTE_ARRANQUE		;79f3
	cp 003h		;79f5
	jr c,VOLUMEN_BAJA		;79f7
	ret			;79f9
ENVOLVENTE_ARRANQUE:		; Los tres primeros fotogramas: baja
	dec (ix+008h)		;79fa
VOLUMEN_BAJA:		; Un paso menos, sin pasar de cero
	ld a,(ix+007h)		;79fd
	dec a			;7a00
	ret m			;7a01
	ld (ix+007h),a		;7a02
	ld h,a			;7a05
PSG_VOLUMEN:		; Registro 8/9/10 (segun C) = H
	ld a,c			;7a06
	rrca			;7a07
	add a,088h		;7a08
	out (0a0h),a		;7a0a
	ld a,h			;7a0c
	out (0a1h),a		;7a0d
	ret			;7a0f
MUSICA_EVENTO:		; 0xFD: octava (bits 0-2) y volumen (bits 3-7); luego la nota
	cp 0fdh		;7a10
	jr nz,MUSICA_NOTA		;7a12
	inc hl			;7a14
	ld a,(hl)			;7a15
	and 007h		;7a16
	ld (ix+005h),a		;7a18
	xor (hl)			;7a1b
	rrca			;7a1c
	rrca			;7a1d
	rrca			;7a1e
	ld (ix+006h),a		;7a1f
	inc hl			;7a22
	ld a,(hl)			;7a23
MUSICA_NOTA:		; Nibble bajo la nota, alto el indice de duracion; 12 es silencio (no repone el volumen)
	and 00fh		;7a24
	ld b,a			;7a26
	xor (hl)			;7a27
	inc hl			;7a28
	ld (ix+003h),l		;7a29
	ld (ix+004h),h		;7a2c
	rrca			;7a2f
	rrca			;7a30
	rrca			;7a31
	rrca			;7a32
	ld hl,07ac3h		;7a33
	call HL_MAS_A		;7a36
	ld a,(hl)			;7a39
	ld (ix+001h),a		;7a3a
	ld a,b			;7a3d
	sub 00ch		;7a3e
	ld (ix+007h),a		;7a40
	jr z,MUSICA_PERIODO		;7a43
	ld a,(ix+006h)		;7a45
	ld (ix+007h),a		;7a48
MUSICA_PERIODO:		; Periodo de la nota por 0x7A71, doblado tantas veces como octavas
	call NOTA_ARRANCA		;7a4b
	ld a,b			;7a4e
	ld hl,07a71h		;7a4f
	call HL_MAS_A		;7a52
	ld l,(hl)			;7a55
	ld h,000h		;7a56
	ld a,(ix+005h)		;7a58
	or a			;7a5b
	jr z,PSG_PERIODO		;7a5c
	ld b,a			;7a5e
MUSICA_OCTAVA:		; Una octava mas abajo por vuelta
	add hl,hl			;7a5f
	djnz MUSICA_OCTAVA		;7a60
PSG_PERIODO:		; Registros C y C-1 = HL (periodo)
	ld a,c			;7a62
	out (0a0h),a		;7a63
	ld a,h			;7a65
	out (0a1h),a		;7a66
	dec c			;7a68
	ld a,c			;7a69
	out (0a0h),a		;7a6a
	ld a,l			;7a6c
	out (0a1h),a		;7a6d
	inc c			;7a6f
	ret			;7a70

; ----------------------------------------------------------------------
; DATOS periodos_de_notas: Los periodos del PSG de Do6 a La6 (106, 100, 95,
;   89, 84, 80, 75, 71, 67, 63); La#6 y Si6 (60, 56) son los dos bytes
;   siguientes, que a la vez son la entrada 0 de la tabla de punteros
;   0x7a71..0x7a7b  (10 bytes)
DATA_periodos_de_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh	; 7a71  jd_YTPKGC?

; ----------------------------------------------------------------------
; DATOS tabla_de_sonidos: 36 punteros de pista, indice = numero del sonido &
;   0x3F, con los canales seguidos: 1-16 los efectos, 17-18 la musica del menu
;   (0x91), 19-20 la de la partida y el READY (0x93), 21-22 el acierto (0x95),
;   23-24 el mono del globo (0x97), 25-26 la fase superada (0x99), 27-28 la
;   respuesta camino del profesor (0x9B), 29-31 el GAME OVER (0x9D), 32 la
;   vida perdida (0xA0, con 33-34 mudos) y 33-35 el 0xA1, que calla los tres
;   canales (las tres apuntan al 0xFF de 0x7B1B). La entrada 0 (0x383C) no es
;   un puntero: son las dos ultimas notas de la tabla de periodos
;   0x7a7b..0x7ac3  (72 bytes)
DATA_tabla_de_sonidos:
	defw 0383ch	; 7a7b
	defw 07d61h	; 7a7d  -> DATA_efecto_1
	defw 07d49h	; 7a7f  -> DATA_efecto_2
	defw 07c5ch	; 7a81  -> DATA_efecto_3
	defw 07c50h	; 7a83  -> DATA_efecto_4
	defw 07beah	; 7a85  -> DATA_efecto_5_y_6
	defw 07beah	; 7a87  -> DATA_efecto_5_y_6
	defw 07db7h	; 7a89  -> DATA_efecto_7
	defw 07dc0h	; 7a8b  -> DATA_efecto_8
	defw 07dceh	; 7a8d  -> DATA_efecto_9
	defw 07c40h	; 7a8f  -> DATA_efecto_0A
	defw 07c6ah	; 7a91  -> DATA_efecto_0B
	defw 07c91h	; 7a93  -> DATA_efecto_0C
	defw 07d41h	; 7a95  -> DATA_efecto_0D
	defw 07c72h	; 7a97  -> DATA_efecto_0E
	defw 07ca5h	; 7a99  -> DATA_efecto_0F
	defw 07cadh	; 7a9b  -> DATA_efecto_10
	defw 07cbfh	; 7a9d  -> DATA_musica_menu_canal_a
	defw 07cf9h	; 7a9f  -> DATA_musica_menu_canal_b
	defw 07b68h	; 7aa1  -> DATA_musica_partida_canal_a
	defw 07ba9h	; 7aa3  -> DATA_musica_partida_canal_b
	defw 07bfah	; 7aa5  -> DATA_acierto_canal_a
	defw 07c0eh	; 7aa7  -> DATA_acierto_canal_b
	defw 07e2ch	; 7aa9  -> DATA_mono_del_globo_canal_a
	defw 07e72h	; 7aab  -> DATA_mono_del_globo_canal_b
	defw 07afbh	; 7aad  -> DATA_fase_superada_canal_a
	defw 07ad2h	; 7aaf  -> DATA_fase_superada_canal_b
	defw 07e4ch	; 7ab1  -> DATA_respuesta_sube_canal_a
	defw 07deeh	; 7ab3  -> DATA_respuesta_sube_canal_b
	defw 07b1ch	; 7ab5  -> DATA_game_over_canal_a
	defw 07b30h	; 7ab7  -> DATA_game_over_canal_b
	defw 07b46h	; 7ab9  -> DATA_game_over_canal_c
	defw 07c22h	; 7abb  -> DATA_vida_perdida
	defw 07b1bh	; 7abd
	defw 07b1bh	; 7abf
	defw 07b1bh	; 7ac1

; ----------------------------------------------------------------------
; DATOS duraciones_de_notas: Las 15 duraciones en fotogramas que elige el
;   nibble alto de cada nota: 3, 6, 8, 9, 12, 16, 18, 21, 24, 30, 32, 42, 48,
;   44, 4
;   0x7ac3..0x7ad2  (15 bytes)
DATA_duraciones_de_notas:
	defb 003h,006h,008h,009h,00ch,010h,012h,015h,018h,01eh,020h,02ah,030h,02ch,004h	; 7ac3  .......... *0,.

; ----------------------------------------------------------------------
; DATOS fase_superada_canal_b: Sonido 0x99 (fase superada), canal B
;   0x7ad2..0x7afb  (41 bytes)
DATA_fase_superada_canal_b:
	defb 0fdh,062h,0cch,040h,014h,047h,01bh,04ch,01bh,04ch,017h,042h,015h,049h,0fdh,061h	; 7ad2  .b.@.G.L.L.B.I.a
	defb 010h,044h,012h,06ch,044h,015h,047h,015h,044h,010h,04ch,089h,017h,015h,014h,012h	; 7ae2  .D.lD.G.D.L.....
	defb 010h,0fdh,062h,01bh,0fdh,061h,060h,0cch,0ffh	; 7af2  ..b..a`..

; ----------------------------------------------------------------------
; DATOS fase_superada_canal_a: Sonido 0x99, canal A. Su 0xFF final, en 0x7B1B,
;   es ademas la pista muda del 0xA1 (los tres canales) y de los canales B y C
;   del 0xA0
;   0x7afb..0x7b1c  (33 bytes)
DATA_fase_superada_canal_a:
	defb 0fdh,063h,0cch,090h,010h,0fdh,064h,097h,017h,0fdh,063h,092h,012h,0fdh,064h,099h	; 7afb  .c....d...c...d.
	defb 019h,0fdh,063h,090h,010h,0fdh,064h,097h,017h,0fdh,063h,092h,012h,060h,060h,0cch	; 7b0b  ..c...d...c..``.
	defb 0ffh	; 7b1b

; ----------------------------------------------------------------------
; DATOS game_over_canal_a: Sonido 0x9D (GAME OVER), canal A
;   0x7b1c..0x7b30  (20 bytes)
DATA_game_over_canal_a:
	defb 0fdh,069h,0cch,064h,014h,043h,044h,085h,084h,017h,017h,047h,085h,019h,019h,04bh	; 7b1c  .i.d.CD....G...K
	defb 0fdh,068h,060h,0ffh	; 7b2c

; ----------------------------------------------------------------------
; DATOS game_over_canal_b: Sonido 0x9D, canal B
;   0x7b30..0x7b46  (22 bytes)
DATA_game_over_canal_b:
	defb 0fdh,069h,0cch,060h,010h,0fdh,06ah,04bh,0fdh,069h,040h,080h,080h,012h,012h,042h	; 7b30  .i.`..jK.i@....B
	defb 080h,015h,015h,047h,067h,0ffh	; 7b40

; ----------------------------------------------------------------------
; DATOS game_over_canal_c: Sonido 0x9D, canal C
;   0x7b46..0x7b68  (34 bytes)
DATA_game_over_canal_c:
	defb 0fdh,063h,0cch,060h,010h,0fdh,064h,04bh,0fdh,063h,040h,0fdh,064h,085h,0fdh,063h	; 7b46  .c.`..dK.c@.d..c
	defb 080h,0fdh,064h,01bh,01bh,0fdh,063h,042h,080h,010h,010h,0fdh,064h,04bh,0fdh,063h	; 7b56  ..d...cB....dK.c
	defb 064h,0ffh	; 7b66

; ----------------------------------------------------------------------
; DATOS musica_partida_canal_a: Sonido 0x93: la musica de la partida y del
;   READY, canal A; se relanza cada vez que el canal B calla
;   0x7b68..0x7ba9  (65 bytes)
DATA_musica_partida_canal_a:
	defb 0fdh,062h,017h,019h,0fdh,061h,040h,08ch,0fdh,062h,017h,019h,0fdh,061h,040h,08ch	; 7b68  .b...a@..b...a@.
	defb 0fdh,062h,017h,019h,0fdh,061h,040h,0fdh,062h,017h,017h,01ch,017h,017h,01ch,047h	; 7b78  .b...a@.b......G
	defb 08ch,017h,019h,0fdh,061h,040h,08ch,0fdh,062h,017h,019h,0fdh,061h,040h,08ch,0fdh	; 7b88  ....a@..b...a@..
	defb 062h,017h,019h,0fdh,061h,040h,0fdh,062h,015h,015h,01ch,015h,015h,01ch,045h,08ch	; 7b98  b...a@.b......E.
	defb 0ffh	; 7ba8

; ----------------------------------------------------------------------
; DATOS musica_partida_canal_b: Sonido 0x93, canal B
;   0x7ba9..0x7bea  (65 bytes)
DATA_musica_partida_canal_b:
	defb 0fdh,05bh,042h,055h,049h,040h,049h,045h,049h,040h,049h,043h,047h,0fdh,05ch,04ah	; 7ba9  .[BUI@IEI@ICG.\J
	defb 0fdh,05bh,047h,043h,047h,0fdh,05ch,04ah,0fdh,05bh,047h,042h,045h,0fdh,05ch,049h	; 7bb9  .[GCG.\J.[GBE.\I
	defb 0fdh,05bh,045h,042h,045h,0fdh,05ch,049h,0fdh,05bh,045h,0fdh,05ch,04ah,0fdh,05bh	; 7bc9  .[EBE.\I.[E.\J.[
	defb 042h,0fdh,05ch,045h,0fdh,05bh,042h,0fdh,05ch,04ah,0fdh,05bh,042h,0fdh,05ch,045h	; 7bd9  B.\E.[B.\J.[B.\E
	defb 0ffh	; 7be9

; ----------------------------------------------------------------------
; DATOS efecto_5_y_6: Sonidos 5 (el mono cae) y 6 (la fruta cae): la misma
;   pista
;   0x7bea..0x7bfa  (16 bytes)
DATA_efecto_5_y_6:
	defb 023h,0d0h,08eh,0e0h,0a0h,0f0h,0a9h,0e0h,0beh,0d0h,0d5h,0d0h,0f2h,0b0h,0feh,0ffh	; 7bea  #...............

; ----------------------------------------------------------------------
; DATOS acierto_canal_a: Sonido 0x95 (respuesta acertada), canal A
;   0x7bfa..0x7c0e  (20 bytes)
DATA_acierto_canal_a:
	defb 0fdh,071h,020h,020h,020h,024h,024h,024h,027h,027h,027h,054h,027h,057h,0fdh,070h	; 7bfa  .q   $$$'''T'W.p
	defb 020h,0c0h,0cch,0ffh	; 7c0a

; ----------------------------------------------------------------------
; DATOS acierto_canal_b: Sonido 0x95, canal B
;   0x7c0e..0x7c22  (20 bytes)
DATA_acierto_canal_b:
	defb 0fdh,062h,027h,027h,027h,0fdh,061h,020h,020h,020h,024h,024h,024h,050h,024h,054h	; 7c0e  .b'''.a   $$$P$T
	defb 027h,0c7h,0cch,0ffh	; 7c1e

; ----------------------------------------------------------------------
; DATOS vida_perdida: Sonido 0xA0 (se pierde la vida: el tiempo, un cangrejo,
;   la fruta caida), canal A; los otros dos van mudos
;   0x7c22..0x7c40  (30 bytes)
DATA_vida_perdida:
	defb 024h,0d0h,060h,0d0h,080h,0d0h,0a0h,0d0h,0c0h,0d0h,0e0h,0d1h,000h,0d1h,050h,0d1h	; 7c22  $.`...........P.
	defb 0a0h,0d1h,0f0h,0d2h,050h,0d2h,0a0h,0d2h,0f0h,0d3h,050h,0d3h,0a0h,0ffh	; 7c32  ....P.....P...

; ----------------------------------------------------------------------
; DATOS efecto_0A: Sonido 0x0A: la tarjeta que se abre o se cierra
;   0x7c40..0x7c50  (16 bytes)
DATA_efecto_0A:
	defb 024h,0c0h,06ah,0c0h,05fh,0c0h,054h,0c0h,050h,0c0h,047h,0c0h,03fh,0c0h,038h,0ffh	; 7c40  $.j._.T.P.G.?.8.

; ----------------------------------------------------------------------
; DATOS efecto_4: Sonido 4: el salto
;   0x7c50..0x7c5c  (12 bytes)
DATA_efecto_4:
	defb 022h,0d0h,07fh,0e0h,070h,0d0h,077h,0c0h,062h,0a0h,058h,0ffh	; 7c50  "...p.w.b.X.

; ----------------------------------------------------------------------
; DATOS efecto_3: Sonido 3: el paso al andar
;   0x7c5c..0x7c6a  (14 bytes)
DATA_efecto_3:
	defb 021h,0d0h,090h,0b0h,088h,028h,000h,000h,021h,0d0h,080h,0b0h,078h,0ffh	; 7c5c  !....(..!...x.

; ----------------------------------------------------------------------
; DATOS efecto_0B: Sonido 0x0B: el boton de responder
;   0x7c6a..0x7c72  (8 bytes)
DATA_efecto_0B:
	defb 022h,0f0h,0beh,0f0h,0a0h,0f0h,07fh,0ffh	; 7c6a  ".......

; ----------------------------------------------------------------------
; DATOS efecto_0E: Sonido 0x0E: el fallo
;   0x7c72..0x7c91  (31 bytes)
DATA_efecto_0E:
	defb 027h,0d0h,0beh,0d0h,0d5h,0d0h,0beh,0d0h,0f0h,0d0h,0feh,0d0h,0f0h,0d1h,040h,0d1h	; 7c72  '.............@.
	defb 053h,0d1h,040h,0d1h,07dh,0d1h,0a6h,0d1h,07dh,02fh,0d1h,098h,0d1h,098h,0ffh	; 7c82  S.@.}...}/.....

; ----------------------------------------------------------------------
; DATOS efecto_0C: Sonido 0x0C: el aviso de que quedan menos de diez segundos
;   0x7c91..0x7ca5  (20 bytes)
DATA_efecto_0C:
	defb 021h,0e0h,070h,0c0h,070h,0b0h,023h,000h,000h,024h,0e0h,070h,0c0h,070h,0e0h,070h	; 7c91  !.p.p.#..$.p.p.p
	defb 02ah,000h,000h,0ffh	; 7ca1

; ----------------------------------------------------------------------
; DATOS efecto_0F: Sonido 0x0F: cada segundo que se convierte en puntos
;   0x7ca5..0x7cad  (8 bytes)
DATA_efecto_0F:
	defb 021h,0d0h,0beh,0d0h,097h,0d0h,0beh,0ffh	; 7ca5  !.......

; ----------------------------------------------------------------------
; DATOS efecto_10: Sonido 0x10: la vida extra
;   0x7cad..0x7cbf  (18 bytes)
DATA_efecto_10:
	defb 024h,0c1h,01dh,0e0h,0d5h,0e0h,0a9h,0e0h,08eh,0c1h,01dh,0e0h,0d5h,0e0h,0a9h,0e0h	; 7cad  $...............
	defb 08eh,0ffh	; 7cbd

; ----------------------------------------------------------------------
; DATOS musica_menu_canal_a: Sonido 0x91 (el menu y el LEVEL SELECT), canal A
;   0x7cbf..0x7cf9  (58 bytes)
DATA_musica_menu_canal_a:
	defb 0fdh,061h,0e2h,047h,0e6h,047h,05bh,052h,0e2h,047h,0e6h,047h,05bh,057h,0ebh,0fdh	; 7cbf  .a.G.G[R.G.G[W..
	defb 060h,042h,0e1h,040h,0fdh,061h,0e9h,046h,0e9h,046h,0e4h,044h,0e6h,044h,0a2h,0e2h	; 7ccf  `B.@.a.F.F.D.D..
	defb 047h,0e6h,047h,05bh,052h,0e2h,047h,0e6h,047h,05bh,057h,0ebh,0fdh,060h,042h,0e1h	; 7cdf  G.G[R.G.G[W..`B.
	defb 040h,0fdh,061h,0e9h,046h,0e4h,046h,087h,0dch,0ffh	; 7cef  @.a.F.F...

; ----------------------------------------------------------------------
; DATOS musica_menu_canal_b: Sonido 0x91, canal B
;   0x7cf9..0x7d41  (72 bytes)
DATA_musica_menu_canal_b:
	defb 0fdh,05bh,0ech,057h,0fdh,05ah,052h,0fdh,05bh,057h,0fdh,05ah,052h,0fdh,05bh,059h	; 7cf9  .[.W.ZR.[W.ZR.[Y
	defb 0fdh,05ah,054h,0fdh,05bh,059h,0fdh,05ah,054h,052h,056h,052h,059h,0fdh,05bh,057h	; 7d09  .ZT.[Y.ZTRVRY.[W
	defb 0fdh,05ah,052h,052h,056h,0fdh,05bh,057h,0fdh,05ah,052h,0fdh,05bh,057h,0fdh,05ah	; 7d19  .ZRRV.[W.ZR.[W.Z
	defb 052h,0fdh,05bh,059h,0fdh,05ah,054h,0fdh,05bh,059h,0fdh,05ah,054h,052h,056h,052h	; 7d29  R.[Y.ZT.[Y.ZTRVR
	defb 059h,057h,052h,0fdh,05bh,057h,04ch,0ffh	; 7d39  YWR.[WL.

; ----------------------------------------------------------------------
; DATOS efecto_0D: Sonido 0x0D: el profesor escribe la cifra (se repite 4
;   veces)
;   0x7d41..0x7d49  (8 bytes)
DATA_efecto_0D:
	defb 022h,0f0h,070h,022h,000h,000h,0feh,004h	; 7d41  ".p"....

; ----------------------------------------------------------------------
; DATOS efecto_2: Sonido 2: un simbolo se coloca (y el mono del globo lo
;   revela); es el unico que se relanza sobre si mismo
;   0x7d49..0x7d61  (24 bytes)
DATA_efecto_2:
	defb 021h,0f0h,0a0h,0e0h,0ach,0d0h,0b3h,0c0h,0c9h,0b0h,0feh,0a0h,0d5h,090h,0feh,080h	; 7d49  !...............
	defb 0d5h,070h,0c0h,060h,0b8h,050h,0b0h,0ffh	; 7d59  .p.`.P..

; ----------------------------------------------------------------------
; DATOS efecto_1: Sonido 1: la ecuacion arranca (el mas largo de los efectos)
;   0x7d61..0x7db7  (86 bytes)
DATA_efecto_1:
	defb 022h,0c2h,01dh,0c2h,05dh,0e1h,0fdh,0e2h,03bh,0e1h,0e0h,0e2h,01dh,0e1h,0c5h,0e1h	; 7d61  "...]...;.......
	defb 0fdh,0e1h,094h,0e1h,0ach,0c1h,07dh,0c1h,094h,0e1h,067h,0e1h,07dh,0f1h,053h,0f1h	; 7d71  ......}...g.}.S.
	defb 067h,0e1h,040h,0e1h,053h,0c1h,02eh,0c1h,040h,0e1h,01dh,0e1h,02eh,0e1h,00dh,0e1h	; 7d81  g.@.S...@.......
	defb 01dh,0e0h,0feh,0e1h,00dh,0c0h,0f0h,0c0h,0e2h,0e0h,0feh,0e0h,0d5h,0c0h,0f0h,0c0h	; 7d91  ................
	defb 0beh,0e0h,0d5h,0e0h,0b3h,0e0h,0c9h,0e0h,0a9h,0c0h,0beh,0c0h,0a0h,0c0h,0b3h,0b0h	; 7da1  ................
	defb 097h,0c0h,0a9h,0a0h,08eh,0ffh	; 7db1

; ----------------------------------------------------------------------
; DATOS efecto_7: Sonido 7: el mono descuelga una fruta (dos veces)
;   0x7db7..0x7dc0  (9 bytes)
DATA_efecto_7:
	defb 022h,0d0h,0a9h,0d0h,08eh,0d0h,06ah,0feh,002h	; 7db7  ".....j..

; ----------------------------------------------------------------------
; DATOS efecto_8: Sonido 8: la fruta vuela
;   0x7dc0..0x7dce  (14 bytes)
DATA_efecto_8:
	defb 021h,0c0h,070h,0b0h,050h,0d0h,070h,0c0h,090h,0d0h,070h,0b0h,050h,0ffh	; 7dc0  !.p.P.p...p.P.

; ----------------------------------------------------------------------
; DATOS efecto_9: Sonido 9: el cangrejo se come la fruta y muere
;   0x7dce..0x7dee  (32 bytes)
DATA_efecto_9:
	defb 021h,0e0h,080h,0f0h,078h,0f0h,070h,0f0h,068h,0f0h,080h,0f0h,0e0h,0f1h,040h,0f1h	; 7dce  !...x.p.h.....@.
	defb 0a0h,0f2h,000h,0f2h,060h,0f2h,0c0h,0f3h,010h,0f3h,070h,0f3h,0a0h,0f3h,0e0h,0ffh	; 7dde  ....`.....p.....

; ----------------------------------------------------------------------
; DATOS respuesta_sube_canal_b: Sonido 0x9B (la tarjeta sube hasta el
;   profesor), canal B
;   0x7dee..0x7e2c  (62 bytes)
DATA_respuesta_sube_canal_b:
	defb 0fdh,062h,027h,02bh,027h,02bh,026h,0fdh,061h,020h,0fdh,062h,026h,0fdh,061h,020h	; 7dee  .b'+'+&.a .b&.a 
	defb 0fdh,062h,027h,02bh,027h,02bh,029h,0fdh,061h,020h,0fdh,062h,026h,0fdh,061h,020h	; 7dfe  .b'+'+).a .b&.a 
	defb 0fdh,062h,027h,02bh,027h,02bh,026h,0fdh,061h,020h,0fdh,062h,026h,0fdh,061h,020h	; 7e0e  .b'+'+&.a .b&.a 
	defb 0fdh,062h,027h,02bh,027h,02bh,026h,0fdh,061h,020h,0fdh,062h,05bh,0ffh	; 7e1e  .b'+'+&.a .b[.

; ----------------------------------------------------------------------
; DATOS mono_del_globo_canal_a: Sonido 0x97 (el mono trae la respuesta en
;   globo), canal A
;   0x7e2c..0x7e4c  (32 bytes)
DATA_mono_del_globo_canal_a:
	defb 0fdh,061h,049h,0e7h,025h,027h,029h,029h,059h,027h,027h,057h,029h,0fdh,060h,020h	; 7e2c  .aI.%'))Y''W).` 
	defb 050h,0fdh,061h,049h,0e7h,025h,027h,029h,029h,059h,027h,02ah,049h,0e7h,0a5h,0ffh	; 7e3c  P.aI.%'))Y'*I...

; ----------------------------------------------------------------------
; DATOS respuesta_sube_canal_a: Sonido 0x9B, canal A
;   0x7e4c..0x7e72  (38 bytes)
DATA_respuesta_sube_canal_a:
	defb 0fdh,069h,027h,027h,057h,029h,029h,059h,04bh,0fdh,068h,0e0h,022h,0fdh,069h,027h	; 7e4c  .i''W))YK.h.".i'
	defb 046h,0e7h,029h,022h,027h,027h,057h,029h,029h,059h,04bh,0fdh,068h,0e0h,022h,0fdh	; 7e5c  F.)"''W))YK.h.".
	defb 069h,027h,029h,026h,057h,0ffh	; 7e6c

; ----------------------------------------------------------------------
; DATOS mono_del_globo_canal_b: Sonido 0x97, canal B
;   0x7e72..0x7e85  (19 bytes)
DATA_mono_del_globo_canal_b:
	defb 0fdh,06ah,055h,055h,055h,055h,054h,054h,054h,054h,055h,055h,055h,055h,054h,054h	; 7e72  .jUUUUTTTTUUUUTT
	defb 055h,055h,0ffh	; 7e82

; ======================================================================
; CODIGO 0x7e85..0x7ed9  (84 bytes)
; ======================================================================


FRUTAS_DE_LA_FASE:		; Las 8 frutas de la fase ((fase - 1) & 7 de 0x6806) a los sprites 10-17; la tarjeta escondida y amarilla (0xFC); los ocho estados a (0, 1); el profesor (0x7ED9) a los sprites 8-9; y las banderas, los fallos y la tarjeta cogida a cero
	ld a,(0e051h)		;7e85
	dec a			;7e88
	and 007h		;7e89
	ld h,000h		;7e8b
	ld l,a			;7e8d
	add hl,hl			;7e8e
	add hl,hl			;7e8f
	add hl,hl			;7e90
	add hl,hl			;7e91
	add hl,hl			;7e92
	ld bc,06806h		;7e93
	add hl,bc			;7e96
	ld de,0e0d8h		;7e97
	ld bc,00020h		;7e9a
	ldir		;7e9d
	ld hl,0e0f8h		;7e9f
	ld (hl),0e1h		;7ea2
	inc hl			;7ea4
	ld (hl),0e1h		;7ea5
	ld b,008h		;7ea7
	ld hl,0e260h		;7ea9
FRUTAS_ESTADOS:		; Los ocho estados a (0, 1)
	ld (hl),000h		;7eac
	inc hl			;7eae
	ld (hl),001h		;7eaf
	inc hl			;7eb1
	djnz FRUTAS_ESTADOS		;7eb2
	ld hl,0e0fah		;7eb4
	ld (hl),0fch		;7eb7
	inc hl			;7eb9
	ld (hl),00ah		;7eba
	ld de,0e0d0h		;7ebc
	ld hl,07ed9h		;7ebf
	ld bc,00008h		;7ec2
	ldir		;7ec5
	xor a			;7ec7
	ld (0e270h),a		;7ec8
	ld (0e238h),a		;7ecb
	ld (0e276h),a		;7ece
	ld (0e057h),a		;7ed1
	dec a			;7ed4
	ld (0e1afh),a		;7ed5
	ret			;7ed8

; ----------------------------------------------------------------------
; DATOS sprites_del_profesor: Los dos atributos del profesor: Y = 0, X = 0xC0,
;   patrones 0x00 (rojo oscuro) y 0x0C (blanco): el mismo mono del jugador, en
;   rojo
;   0x7ed9..0x7ee1  (8 bytes)
DATA_sprites_del_profesor:
	defb 000h,0c0h,000h,006h	; 7ed9
	defb 000h,0c0h,00ch,00fh	; 7edd

; ----------------------------------------------------------------------
; DATOS relleno_final: 287 bytes a 0xFF hasta el final del cartucho
;   0x7ee1..0x8000  (287 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ee1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ef1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f01  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f11  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f21  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f31  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f41  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f51  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f61  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f71  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f81  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f91  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fa1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fb1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fc1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fd1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fe1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ff1  ...............

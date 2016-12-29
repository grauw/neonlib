;
; VDP command
;
VDPCommand_STOP: equ 00H
VDPCommand_POINT: equ 40H
VDPCommand_PSET: equ 50H
VDPCommand_SRCH: equ 60H
VDPCommand_LINE: equ 70H
VDPCommand_LMMV: equ 80H
VDPCommand_LMMM: equ 90H
VDPCommand_LMCM: equ 0A0H
VDPCommand_LMMC: equ 0B0H
VDPCommand_HMMV: equ 0C0H
VDPCommand_HMMM: equ 0D0H
VDPCommand_YMMM: equ 0E0H
VDPCommand_HMMC: equ 0F0H
VDPCommand_IMP: equ 00H
VDPCommand_AND: equ 01H
VDPCommand_OR: equ 02H
VDPCommand_XOR: equ 03H
VDPCommand_NOT: equ 04H
VDPCommand_TIMP: equ 08H
VDPCommand_TAND: equ 09H
VDPCommand_TOR: equ 0AH
VDPCommand_TXOR: equ 0BH
VDPCommand_TNOT: equ 0CH

VDPCommand: MACRO ?sx, ?sy, ?dx, ?dy, ?nx, ?ny, ?color, ?argument, ?command
	sx:
		dw ?sx
	sy:
		dw ?sy
	dx:
		dw ?dx
	dy:
		dw ?dy
	nx:
		dw ?nx
	ny:
		dw ?ny
	color:
		db ?color
	argument:
		db ?argument
	command:
		db ?command
	ENDM

; ix = this
; Modifies: af, bc, hl
VDPCommand_Execute:
	push ix
	pop hl
	jp VDPCommand_Execute_HL

; ix = this
; Modifies: af, bc, hl
VDPCommand_Execute_IY:
	push iy
	pop hl
	jp VDPCommand_Execute_HL

; ix = this
; Modifies: af, bc, hl
VDPCommand_Execute_HL: PROC
	ld c,VDP_PORT_3
	ld a,32
	di
	out (VDP_PORT_1),a
	ld a,17 | 128
	ei
	out (VDP_PORT_1),a
WaitReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | 128
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rra
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | 128
	ei
	out (VDP_PORT_1),a
	jr c,WaitReady
	REPT 15
	outi
	ENDM
	ret
	ENDP

; ix = this
VDPCommand_WaitReady:
	call VDPCommand_IsReady
	jr c,VDPCommand_WaitReady
	ret

; f <- c: not ready (CE=1)
; ix = this
; Modifies: af
VDPCommand_IsReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | 128
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rra
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | 128
	ei
	out (VDP_PORT_1),a
	ret

; hl = source
; bc = byte count
; ix = this
; Modifies: af, bc, de, hl
VDPCommand_Transfer_IY: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld d,b
	ld b,c
	ld c,VDP_PORT_3
	ld a,44 | 128
	di
	out (VDP_PORT_1),a
	ld a,17 | 128
	ei
	out (VDP_PORT_1),a
Loop:
	otir
	dec d
	jr nz,Loop
	ret
	ENDP

; ix = this
VDPCommand_WaitTransferReady:
	call VDPCommand_IsTransferReady
	jr nc,VDPCommand_WaitTransferReady
	ret

; f <- c: ready (TR=1)
; ix = this
; Modifies: af
VDPCommand_IsTransferReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | 128
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rla
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | 128
	ei
	out (VDP_PORT_1),a
	ret

; ix = VDP command
VDPCommand_ExecuteWrapSX: PROC
	ld l,(ix + VDPCommand.sx)
	ld h,(ix + VDPCommand.sy)
	ld e,(ix + VDPCommand.dx)
	ld d,(ix + VDPCommand.dy)
	ld c,(ix + VDPCommand.nx)
	ld b,(ix + VDPCommand.ny)
	ld a,l
	add a,c
	jr c,SplitX
ExecuteX:
	ld a,h
	add a,b
	jr c,SplitY
ExecuteY:
	exx
	push ix
	pop hl
	call VDPCommand_Execute_HL
	exx
	ret
SplitX:
	jr z,ExecuteX
	ld (ix + VDPCommand.nx),a
	ld a,e
	sub l
	ld (ix + VDPCommand.dx),a
	ld (ix + VDPCommand.sx),0
	call ExecuteX
	xor a
	sub l
	ld (ix + VDPCommand.nx),a
	ld (ix + VDPCommand.dx),e
	ld (ix + VDPCommand.sx),l
	call ExecuteX
	ld (ix + VDPCommand.nx),c
	ret
SplitY:
	jr z,ExecuteY
	ld (ix + VDPCommand.ny),a
	ld a,d
	sub h
	ld (ix + VDPCommand.sy),a
	ld (ix + VDPCommand.dy),0
	call ExecuteY
	xor a
	sub h
	ld (ix + VDPCommand.ny),a
	ld (ix + VDPCommand.dy),d
	ld (ix + VDPCommand.sy),h
	call ExecuteY
	ld (ix + VDPCommand.ny),b
	ret
	ENDP

; ix = VDP command
VDPCommand_ExecuteWrapDX: PROC
	ld l,(ix + VDPCommand.sx)
	ld h,(ix + VDPCommand.sy)
	ld e,(ix + VDPCommand.dx)
	ld d,(ix + VDPCommand.dy)
	ld c,(ix + VDPCommand.nx)
	ld b,(ix + VDPCommand.ny)
	ld a,e
	add a,c
	jr c,SplitX
ExecuteX:
	ld a,d
	add a,b
	jr c,SplitY
ExecuteY:
	exx
	push ix
	pop hl
	call VDPCommand_Execute_HL
	exx
	ret
SplitX:
	jr z,ExecuteX
	ld (ix + VDPCommand.nx),a
	ld (ix + VDPCommand.dx),0
	ld a,l
	sub e
	ld (ix + VDPCommand.sx),a
	call ExecuteX
	xor a
	sub e
	ld (ix + VDPCommand.nx),a
	ld (ix + VDPCommand.dx),e
	ld (ix + VDPCommand.sx),l
	call ExecuteX
	ld (ix + VDPCommand.nx),c
	ret
SplitY:
	jr z,ExecuteY
	ld (ix + VDPCommand.ny),a
	ld (ix + VDPCommand.dy),0
	ld a,h
	sub d
	ld (ix + VDPCommand.sy),a
	call ExecuteY
	xor a
	sub d
	ld (ix + VDPCommand.ny),a
	ld (ix + VDPCommand.dy),d
	ld (ix + VDPCommand.sy),h
	call ExecuteY
	ld (ix + VDPCommand.ny),b
	ret
	ENDP

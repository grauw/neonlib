;
; Aligned memory byte reader
;
Reader: MACRO
	; iy = this
	; a <- value
	Read_IY:
		ld a,(0)
	address: equ $ - 2
		inc (iy + Reader.address + 0)
		ret nz
		jp Reader_Read_IY.Continue
	bufferEnd:
		db 0
	supplier:
		dw System_ThrowException
	_size:
	ENDM

; de = buffer supplier (de = last read address, de <- buffer start, hl <- buffer size)
; ix = this
; ix <- this
Reader_Construct:
	ld (ix + Reader.supplier + 0),e
	ld (ix + Reader.supplier + 1),d
	ld (ix + Reader.address + 0),0FFH
	ld (ix + Reader.address + 1),000H
	ld (ix + Reader.bufferEnd),000H
	ret

; iy = this
; a <- value
; Modifies: f
Reader_Read_IY: PROC
	jp iy
Continue:
	push af
	ld a,(iy + Reader.address + 1)
	inc a
	cp (iy + Reader.bufferEnd)
	jr nc,SupplyPending
	ld (iy + Reader.address + 1),a
	pop af
	ret
SupplyPending:
	jr nz,SupplyBuffer
	ld (iy + Reader.address + 1),a
	ld (iy + Reader.address + 0),0FFH  ; supply pending
	pop af
	ret
SupplyBuffer:
	pop af
	call Reader_SupplyBuffer_IY
	jp iy
	ENDP

; iy = this
Reader_SupplyBuffer_IY:
	push bc
	push de
	push hl
	ld e,(iy + Reader.address + 0)
	ld d,(iy + Reader.address + 1)
	ld l,(iy + Reader.supplier + 0)
	ld h,(iy + Reader.supplier + 1)
	call System_JumpHL
	call Reader_SetBuffer_IY
	pop hl
	pop de
	pop bc
	ret

; de = buffer start
; hl = buffer size
; iy = this
Reader_SetBuffer_IY:
	ld (iy + Reader.address + 0),e
	ld (iy + Reader.address + 1),d
	add hl,de
	ld (iy + Reader.bufferEnd),h
	ld a,l
	and a
	ret z
	jp System_ThrowException

; iy = this
; de <- value
Reader_ReadWord_IY:
	call Reader_Read_IY
	ld e,a
	call Reader_Read_IY
	ld d,a
	ret

; iy = this
; de <- value
Reader_ReadWordBE_IY:
	call Reader_Read_IY
	ld d,a
	call Reader_Read_IY
	ld e,a
	ret

; iy = this
; dehl <- value
Reader_ReadDoubleWord_IY:
	call Reader_Read_IY
	ld l,a
	call Reader_Read_IY
	ld h,a
	call Reader_Read_IY
	ld e,a
	call Reader_Read_IY
	ld d,a
	ret

; iy = reader
; dehl <- value
Reader_ReadDoubleWordBE_IY:
	call Reader_Read_IY
	ld d,a
	call Reader_Read_IY
	ld e,a
	call Reader_Read_IY
	ld h,a
	call Reader_Read_IY
	ld l,a
	ret

; Read block to buffer
; bc = byte count requested
; de = destination
; iy = this
; bc <- byte count (<= bytes requested)
; de <- updated
; Modifies: af, hl
Reader_ReadBlock_IY: PROC
	push bc
Loop:
	push bc
	call Reader_ReadBlockDirect_IY
	ld a,b
	or c
	jr z,NoMoreBytes
	push bc
	call System_FastLDIR
	pop bc
	pop hl
	and a
	sbc hl,bc
	ld c,l
	ld b,h
	jr nz,Loop
	pop bc
	ret
NoMoreBytes:
	pop bc
	pop hl
	sbc hl,bc
	ld c,l
	ld b,h
	ret
	ENDP

; Read block directly from buffer
; bc = byte count requested
; iy = this
; bc <- byte count (<= bytes requested)
; hl <- source address
; Modifies: af
Reader_ReadBlockDirect_IY: PROC
	ld a,(iy + Reader.address + 1)
	cp (iy + Reader.bufferEnd)
	call nc,Reader_SupplyBuffer_IY  ; supply pending
	ld l,(iy + Reader.address + 0)
	ld h,(iy + Reader.address + 1)
	push hl
	add hl,bc
	jr c,Overflow
	ld a,h
	cp (iy + Reader.bufferEnd)
	jr nc,Overflow
	ld (iy + Reader.address + 0),l
	ld (iy + Reader.address + 1),h
	pop hl
	ret
Overflow:
	pop bc
	ld l,0
	ld h,(iy + Reader.bufferEnd)
	ld (iy + Reader.address + 0),0FFH  ; supply pending
	ld (iy + Reader.address + 1),h
	and a
	sbc hl,bc
	ld a,l
	ld l,c
	ld c,a
	ld a,h
	ld h,b
	ld b,a
	ret
	ENDP

; bc = nr of bytes to skip
; iy = this
; Modifies: af, bc, hl
Reader_Skip_IY: PROC
	ld a,c
	or b
	ret z
Loop:
	push bc
	call Reader_ReadBlockDirect_IY
	pop hl
	and a
	sbc hl,bc
	ret z
	ld c,l
	ld b,h
	jr nc,Loop
	jp System_ThrowException
	ENDP

; debc = nr of bytes to skip
; iy = this
; Modifies: af, bc, hl
Reader_Skip32_IY: PROC
	ld a,c
	or b
	call nz,Reader_Skip_IY
	inc de
Loop:
	dec de
	ld a,e
	or d
	ret z
	ld bc,8000H
	call Reader_Skip_IY
	ld bc,8000H
	call Reader_Skip_IY
	jr Loop
	ENDP

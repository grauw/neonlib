;
; Memory buffer reader
;
Reader: MACRO
	; iy = this
	; a <- value
	Read_IY:
		ld a,(0)
	bufferPosition: equ $ - 2
		inc (iy + Reader.bufferPosition)
		ret nz
		jp Reader_Read_IY.Continue

	bufferStart:
		db 0
	bufferEnd:
		db 0
	filler:
		dw System_ThrowException
	_size:
	ENDM

; hl = buffer start
; bc = buffer size
; de = buffer filler
; ix = this
; ix <- this
Reader_Construct:
	ld a,l  ; check if buffer is 256-byte aligned
	or c
	call nz,System_ThrowException
	ld (ix + Reader.bufferStart),h
	ld (ix + Reader.filler),e
	ld (ix + Reader.filler + 1),d
	add hl,bc
	ld (ix + Reader.bufferEnd),h
	ld (ix + Reader.bufferPosition),0FFH  ; fill pending
	ld (ix + Reader.bufferPosition + 1),h
	ret

; iy = this
; a <- value
; Modifies: f
Reader_Read_IY: PROC
	jp iy
Continue:
	push af
	ld a,(iy + Reader.bufferPosition + 1)
	inc a
	ld (iy + Reader.bufferPosition + 1),a
	cp (iy + Reader.bufferEnd)
	jr nc,FillPending
	pop af
	ret
FillPending:
	jr nz,FinishBlock
	ld (iy + Reader.bufferPosition),0FFH  ; fill pending
	pop af
	ret
FinishBlock:
	pop af
	call Reader_FinishBlock_IY
	jp iy
	ENDP

; iy = this
Reader_FinishBlock_IY:
	push bc
	push de
	push hl
	call Reader_FillBuffer_IY
	pop hl
	pop de
	pop bc
	ld (iy + Reader.bufferPosition),0
	ld a,(iy + Reader.bufferStart)
	ld (iy + Reader.bufferPosition + 1),a
	ret

; The filler is called with bc = byte count, de = buffer start
; iy = this
; Modifies: af, bc, de, hl
Reader_FillBuffer_IY:
	ld e,0
	ld d,(iy + Reader.bufferStart)
	ld c,0
	ld a,(iy + Reader.bufferEnd)
	sub d
	ld b,a
	ld l,(iy + Reader.filler)
	ld h,(iy + Reader.filler + 1)
	jp hl

; bc = byte count
; de = buffer start
; iy = this
Reader_DefaultFiller:
	ret

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
	ld a,(iy + Reader.bufferPosition + 1)
	cp (iy + Reader.bufferEnd)
	call nc,Reader_FinishBlock_IY  ; fill pending
	ld l,(iy + Reader.bufferPosition)
	ld h,(iy + Reader.bufferPosition + 1)
	push hl
	add hl,bc
	jr c,Overflow
	ld a,h
	cp (iy + Reader.bufferEnd)
	jr nc,Overflow
	ld (iy + Reader.bufferPosition),l
	ld (iy + Reader.bufferPosition + 1),h
	pop hl
	ret
Overflow:
	pop bc
	ld l,0
	ld h,(iy + Reader.bufferEnd)
	ld (iy + Reader.bufferPosition),0FFH  ; fill pending
	ld (iy + Reader.bufferPosition + 1),h
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
Loop:
	ld a,c
	or b
	ret z
	push bc
	call Reader_ReadBlockDirect_IY
	pop hl
	and a
	sbc hl,bc
	call c,System_ThrowException
	ld c,l
	ld b,h
	jp Loop
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
	jp Loop
	ENDP

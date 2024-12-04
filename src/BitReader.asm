;
; Aligned memory bit reader
;
BitReader: MACRO
	super:
		Reader
	bits:
		db 0
	_size:
	ENDM

; de = buffer supplier (de = last read address, bc <- byte count, de <- read address)
; ix = this
; ix <- this
BitReader_Construct:
	call Reader_Construct
	ld (ix + BitReader.bits),0
	ret

; iy = this
; f <- c: bit
; Modifies: none
BitReader_Read_IY:
	srl (iy + BitReader.bits)
	ret nz  ; return if sentinel bit is still present
	push bc
	ld c,a
	call Reader_Read_IY
	scf  ; set sentinel bit
	rra
	ld (iy + BitReader.bits),a
	ld a,c
	pop bc
	ret

; iy = this
; c <- inline bit reader state
BitReader_PrepareReadInline_IY:
	ld c,(iy + BitReader.bits)
	ret

; iy = this
; c = inline bit reader state
BitReader_FinishReadInline_IY:
	ld (iy + BitReader.bits),c
	ret

; c = inline bit reader state
; iy = this
; c <- inline bit reader state
; f <- c: bit
; Modifies: a
BitReader_ReadInline_IY: MACRO
	srl c
	call z,BitReader_ReadInline_NextByte_IY  ; if sentinel bit is shifted out
	ENDM

; iy = this
; c <- inline bit reader state
; f <- c: bit
; Modifies: a
BitReader_ReadInline_NextByte_IY:
	call Reader_Read_IY
	scf  ; set sentinel bit
	rra
	ld c,a
	ret

; iy = this
; c = inline bit reader state
; c <- inline bit reader state
; f <- c: bit
; Modifies: b
BitReader_ReadInline_B_IY: MACRO
	srl c
	call z,BitReader_ReadInline_B_NextByte_IY  ; if sentinel bit is shifted out
	ENDM

; iy = this
; c <- inline bit reader state
; f <- c: bit
; Modifies: b
BitReader_ReadInline_B_NextByte_IY:
	ld b,a
	call Reader_Read_IY
	scf  ; set sentinel bit
	rra
	ld c,a
	ld a,b
	ret

; c = inline bit reader state
; a <- value
; c <- inline bit reader state
; Modifies: b
BitReader_ReadInline_1_IY:
	xor a
	BitReader_ReadInline_B_IY
	rla
	ret

BitReader_ReadInline_2_IY:
	xor a
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rla
	rla
	ret

BitReader_ReadInline_3_IY:
	xor a
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rla
	rla
	rla
	ret

BitReader_ReadInline_4_IY:
	xor a
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rla
	rla
	rla
	rla
	ret

BitReader_ReadInline_5_IY:
	xor a
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	rra
	rra
	rra
	ret

BitReader_ReadInline_6_IY:
	xor a
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	rra
	rra
	ret

BitReader_ReadInline_7_IY:
	xor a
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	rra
	ret

BitReader_ReadInline_8_IY:
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	BitReader_ReadInline_B_IY
	rra
	ret

; b = nr of bits to read (1-8)
; iy = this
; a <- value
; Modifies: af, bc
BitReader_Read_N_IY: PROC
	ld c,1
	xor a
Loop:
	call BitReader_Read_IY
	jr nc,Zero
	add a,c
Zero:
	rlc c
	djnz Loop
	ret
	ENDP

; iy = this
BitReader_Align_IY:
	ld (iy + BitReader.bits),0
	ret

;
; Memory and slot-related routines
;
Memory_GetSlot:
	ld a,h
	sub 64
	jp c,Memory_GetSlotPage0
	sub 64
	jp c,Memory_GetSlotPage1
	sub 64
	jp c,Memory_GetSlotPage2
	jp Memory_GetSlotPage3

Memory_GetSlotPage0:
	in a,(0A8H)
	and 00000011B
	ld c,a
	ld b,0
	ld hl,EXPTBL
	add hl,bc
	ld c,a
	ld a,(hl)
	and 80H
	or c
	ld c,a
	inc hl  ; move to SLTTBL
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	and 00000011B
	rlca
	rlca
	or c
	ret

Memory_GetSlotPage1:
	in a,(0A8H)
	and 00001100B
	rrca
	rrca
	ld c,a
	ld b,0
	ld hl,EXPTBL
	add hl,bc
	ld c,a
	ld a,(hl)
	and 80H
	or c
	ld c,a
	inc hl  ; move to SLTTBL
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	and 00001100B
	or c
	ret

Memory_GetSlotPage2:
	in a,(0A8H)
	and 00110000B
	rrca
	rrca
	rrca
	rrca
	ld c,a
	ld b,0
	ld hl,EXPTBL
	add hl,bc
	ld c,a
	ld a,(hl)
	and 80H
	or c
	ld c,a
	inc hl  ; move to SLTTBL
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	and 00110000B
	rrca
	rrca
	or c
	ret

Memory_GetSlotPage3:
	in a,(0A8H)
	and 11000000B
	rlca
	rlca
	ld c,a
	ld b,0
	ld hl,EXPTBL
	add hl,bc
	ld c,a
	ld a,(hl)
	and 80H
	or c
	ld c,a
	inc hl  ; move to SLTTBL
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	and 11000000B
	rrca
	rrca
	rrca
	rrca
	or c
	ret

;
; Prepares a slot selection.
;
; a = slot ID formatted FxxxSSPP
; h = memory page
; bc <- prepared slot id (1) (b: primary value, c: SLTTBL LSB)
; de <- prepared slot id (2) (d: secondary’s primary value, e: secondary value)
; hl <- SLTTBL entry
; Modifies: af, bc, de, hl
;
Memory_PrepareSlot: PROC
	bit 7,h
	jr nz,Page23
	bit 6,h
	jp z,Memory_PrepareSlotPage0
	jp Memory_PrepareSlotPage1
Page23:
	bit 6,h
	jp z,Memory_PrepareSlotPage2
	call System_ThrowException
	ENDP

;
; Prepares a slot selection in page 0.
;
; a = slot ID formatted FxxxSSPP
; bc <- prepared slot id (1) (b: primary value, c: SLTTBL LSB)
; de <- prepared slot id (2) (d: secondary’s primary value, e: secondary value)
; hl <- SLTTBL entry
; Modifies: af, bc, de, hl
;
Memory_PrepareSlotPage0: PROC
	and a
	jp m,Expanded
	call Expanded
	ld a,d
	and 00111111B  ; writing to 0FFFFH in slot 0 should be safe
	ld d,a
	ld a,(SLTTBL)
	ld e,a
	ld c,SLTTBL & 0FFH
	ret
Expanded:
	ld c,a
	and 00001100B
	rrca
	rrca
	ld e,a
	ld a,c
	and 00000011B
	ld b,a
	rrca
	rrca
	or b
	ld d,a
	ld h,SLTTBL >> 8
	ld a,SLTTBL & 0FFH
	add a,b
	ld l,a
	in a,(0A8H)
	ld c,a
	and 00111100B
	or d
	ld d,a
	ld a,c
	and 11111100B
	or b
	ld b,a
	ld a,(hl)
	and 11111100B
	or e
	ld e,a
	ld c,l
	ret
	ENDP

;
; Prepares a slot selection in page 1.
;
; a = slot ID formatted FxxxSSPP
; bc <- prepared slot id (1) (b: primary value, c: SLTTBL LSB)
; de <- prepared slot id (2) (d: secondary’s primary value, e: secondary value)
; hl <- SLTTBL entry
; Modifies: af, bc, de, hl
;
Memory_PrepareSlotPage1: PROC
	and a
	jp m,Expanded
	call Expanded
	ld a,d
	and 00111111B  ; writing to 0FFFFH in slot 0 should be safe
	ld d,a
	ld a,(SLTTBL)
	ld e,a
	ld c,SLTTBL & 0FFH
	ret
Expanded:
	ld c,a
	and 00001100B
	ld e,a
	ld a,c
	and 00000011B
	ld c,a
	rlca
	rlca
	ld b,a
	rlca
	rlca
	rlca
	rlca
	or b
	ld d,a
	ld h,SLTTBL >> 8
	ld a,SLTTBL & 0FFH
	add a,c
	ld l,a
	in a,(0A8H)
	ld c,a
	and 00110011B
	or d
	ld d,a
	ld a,c
	and 11110011B
	or b
	ld b,a
	ld a,(hl)
	and 11110011B
	or e
	ld e,a
	ld c,l
	ret
	ENDP

;
; Prepares a slot selection in page 2.
;
; a = slot ID formatted FxxxSSPP
; bc <- prepared slot id (1) (b: primary value, c: SLTTBL LSB)
; de <- prepared slot id (2) (d: secondary’s primary value, e: secondary value)
; hl <- SLTTBL entry
; Modifies: af, bc, de, hl
;
Memory_PrepareSlotPage2: PROC
	and a
	jp m,Expanded
	call Expanded
	ld a,d
	and 00111111B  ; writing to 0FFFFH in slot 0 should be safe
	ld d,a
	ld a,(SLTTBL)
	ld e,a
	ld c,SLTTBL & 0FFH
	ret
Expanded:
	ld c,a
	and 00001100B
	rlca
	rlca
	ld e,a
	ld a,c
	and 00000011B
	ld c,a
	rlca
	rlca
	rlca
	rlca
	ld b,a
	rlca
	rlca
	or b
	ld d,a
	ld h,SLTTBL >> 8
	ld a,SLTTBL & 0FFH
	add a,c
	ld l,a
	in a,(0A8H)
	ld c,a
	and 00001111B
	or d
	ld d,a
	ld a,c
	and 11001111B
	or b
	ld b,a
	ld a,(hl)
	and 11001111B
	or e
	ld e,a
	ld c,l
	ret
	ENDP

;
; Sets a slot in the page specified by h.
; The current interrupt enabled state is preserved.
;
; a = slot ID formatted FxxxSSPP
; h = memory page
; Modifies: af, bc, de, hl
;
Memory_SetSlot:
	push hl
	call Memory_PrepareSlot
	pop hl
	bit 7,h
	jp nz,Memory_SetPreparedSlot
	bit 6,h
	jp nz,Memory_SetPreparedSlot
	jp Memory_SetPreparedSlotPage0

; a = slot ID formatted FxxxSSPP
; Modifies: af, bc, de, hl
Memory_SetSlotPage0:
	ld h,00H
	jp Memory_SetSlot

; a = slot ID formatted FxxxSSPP
; Modifies: af, bc, de, hl
Memory_SetSlotPage1:
	ld h,40H
	jp Memory_SetSlot

; a = slot ID formatted FxxxSSPP
; Modifies: af, bc, de, hl
Memory_SetSlotPage2:
	ld h,80H
	jp Memory_SetSlot

;
; Sets a prepared slot selection.
; The current interrupt enabled state is preserved.
; The original slot layout can be restored by invoking this method again.
; Note, primary slots will be set to the state they were in when prepared.
;
; bc = Prepared slot id (1)
; de = Prepared slot id (2)
; bc <- Prepared slot id (1) to restore
; de <- Prepared slot id (2) to restore
; Modifies: af, bc, de, hl
;
Memory_SetPreparedSlot:
	push bc
	ld hl,0FFFFH
	ld c,0A8H
	call System_CheckEIState
	di
	in a,(0A8H)  ; be careful not to modify p/v flag
	out (c),d
	ld (hl),e
	out (c),b
	pop bc
	ld h,SLTTBL >> 8
	ld l,c
	ld b,a
	ld a,(hl)
	ld (hl),e
	ld e,a
	ret po
	ei
	ret

	SECTION TPA_PAGE1

;
; Sets a prepared slot selection in page 0.
; See SetPreparedSlot.
;
Memory_SetPreparedSlotPage0:
	push bc
	ld hl,0FFFFH
	ld c,0A8H
	call Memory_CheckEIState_Page1
	di
	in a,(0A8H)  ; be careful not to modify p/v flag
	out (c),d
	ld (hl),e
	out (c),b
	pop bc
	ld h,SLTTBL >> 8
	ld l,c
	ld b,a
	ld a,(hl)
	ld (hl),e
	ld e,a
	ret po
	ei
	ret

; f: pe <- interrupts enabled
; Modifies: af
Memory_CheckEIState_Page1:
	xor a
	push af
	pop af
	ld a,r
	ret pe
	dec sp
	dec sp
	pop af
	sub 1
	sbc a,a
	and 1
	ret

	ENDS

;
; Reads a byte from a slot.
; The current interrupt enabled state is preserved.
;
; a = slot ID
; hl = address
; a <- value
; Modifies: af, af', bc, de, hl
;
Memory_ReadSlot:
	push hl
	call Memory_PrepareSlot
	pop hl
	bit 7,h
	jp nz,Memory_ReadPreparedSlot
	bit 6,h
	jp nz,Memory_ReadPreparedSlot
	jp Memory_ReadPreparedSlotPage0

;
; Reads a byte from a prepared slot.
; The current interrupt enabled state is preserved.
;
; de = prepared slot id (2)
; hl = address
; a <- value
; Modifies: af, af', bc, de, hl
;
Memory_ReadPreparedSlot:
	ld c,0A8H
	call System_CheckEIState
	ex af,af'
	di
	in b,(c)
	out (c),d
	ld a,(0FFFFH)
	cpl
	ex af,af'
	ld a,e
	ld (0FFFFH),a
	ld a,(hl)
	ex af,af'
	ld (0FFFFH),a
	out (c),b
	ex af,af'
	ret po
	ei
	ret

	SECTION TPA_PAGE1

;
; Reads a byte from a prepared slot in page 0.
; See ReadPreparedSlot.
;
Memory_ReadPreparedSlotPage0:
	ld c,0A8H
	call System_CheckEIState
	ex af,af'
	di
	in b,(c)
	out (c),d
	ld a,(0FFFFH)
	cpl
	ex af,af'
	ld a,e
	ld (0FFFFH),a
	ld a,(hl)
	ex af,af'
	ld (0FFFFH),a
	out (c),b
	ex af,af'
	ret po
	ei
	ret

	ENDS

;
; Writes a byte to a slot.
; The current interrupt enabled state is preserved.
;
; a = slot ID
; c = value
; hl = address
; Modifies: af, af', bc, de, hl
;
Memory_WriteSlot:
	push bc
	push hl
	call Memory_PrepareSlot
	pop hl
	pop bc
	bit 7,h
	jp nz,Memory_WritePreparedSlot
	bit 6,h
	jp nz,Memory_WritePreparedSlot
	jp Memory_WritePreparedSlotPage0

;
; Writes a byte to a prepared slot.
; The current interrupt enabled state is preserved.
;
; c = value
; de = prepared slot id (2)
; hl = address
; Modifies: af, af', bc, de, hl
;
Memory_WritePreparedSlot:
	call System_CheckEIState
	ld a,c
	ld c,0A8H
	ex af,af'
	di
	in b,(c)
	out (c),d
	ld a,(0FFFFH)
	cpl
	ld d,a
	ld a,e
	ld (0FFFFH),a
	ex af,af'
	ld (hl),a
	ld a,d
	ld (0FFFFH),a
	out (c),b
	ret po
	ei
	ret

	SECTION TPA_PAGE1

;
; Writes a byte to a prepared slot in page 0.
; See WritePreparedSlot.
;
Memory_WritePreparedSlotPage0:
	call System_CheckEIState
	ld a,c
	ld c,0A8H
	ex af,af'
	di
	in b,(c)
	out (c),d
	ld a,(0FFFFH)
	cpl
	ld d,a
	ld a,e
	ld (0FFFFH),a
	ex af,af'
	ld (hl),a
	ld a,d
	ld (0FFFFH),a
	out (c),b
	ret po
	ei
	ret

	ENDS

	SECTION RAM

;
; Executes an inter-slot call.
; The current interrupt enabled state is preserved.
;
; iyh = slot ID
; ix = address
; Modifies: af', bc', de', hl'
;
Memory_CallSlot: PROC
	ex af,af'
	exx
	ld a,ixh
	ld h,a
	and 11000000B
	ld a,iyh
	jp z,Page0
	call Memory_PrepareSlot
	call Memory_SetPreparedSlot
	push bc
	push de
	exx
	ex af,af'
	call JumpIX
	ex af,af'
	exx
	pop de
	pop bc
	call Memory_SetPreparedSlot
	exx
	ex af,af'
	ret

	SECTION TPA_PAGE1
Page0:
	call Memory_PrepareSlot
	call Memory_SetPreparedSlotPage0
	push bc
	push de
	exx
	ex af,af'
	call JumpIX
	ex af,af'
	exx
	pop de
	pop bc
	call Memory_SetPreparedSlotPage0
	exx
	ex af,af'
	ret
JumpIX:
	jp ix
	ENDS
	ENDP

	ENDS

;
; Search all slots and subslots for a match.
; Invoke Continue to continue searching where a previous search left off.
;
; hl = detection routine (receives a = slot ID, can modify all)
; f <- c: found
; a <- slot number
; Modifies: af, bc, de
;
Memory_SearchSlots: PROC
	ld a,0
PrimaryLoop:
	ex de,hl
	ld hl,EXPTBL
	ld b,0
	ld c,a
	add hl,bc
	ld a,(hl)
	ex de,hl
	and 10000000B
	or c
SecondaryLoop:
	push af
	push hl
	call System_JumpHL
	pop hl
	jp c,Found
	pop af
Continue:
	add a,00000100B
	jp p,NextPrimary
	bit 4,a
	jp z,SecondaryLoop
NextPrimary:
	inc a
	and 00000011B
	ret z  ; not found
	jp PrimaryLoop
Found:
	pop af
	scf
	ret
	ENDP

;
; Match a string in a slot.
;
; a = slot
; bc = string length
; de = string
; hl = address
; f <- c: found
; Modifies: f, bc, de, hl
;
Memory_MatchSlotString: PROC
	push af
	push bc
	push de
	call RDSLT
	pop de
	pop bc
	ex de,hl
	cpi
	jr nz,NotFound
	jp po,Found
	inc de
	ex de,hl
	pop af
	jp Memory_MatchSlotString
Found:
	pop af
	scf
	ret
NotFound:
	pop af
	and a
	ret
	ENDP

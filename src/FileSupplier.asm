;
; Buffered sequential-access file supplier
;
FileSupplier: MACRO
	Supply:
		ld b,0FFH
	fileHandle: equ $ - 1
		ld de,0000H
	bufferStart: equ $ - 2
		ld hl,0000H
	bufferSize: equ $ - 2
		jp FileSupplier_Supply
	_size:
	ENDM

; b = file handle
; de = buffer start
; hl = buffer size
; ix = this
; ix <- this
FileSupplier_Construct:
	ld a,e
	or l
	call nz,System_ThrowException  ; buffer not 256-byte aligned
	ld (ix + FileSupplier.fileHandle),b
	ld (ix + FileSupplier.bufferStart + 1),d
	ld (ix + FileSupplier.bufferSize + 1),h
	ret

; b = file handle
; de = buffer start
; hl = buffer size
; bc <- byte count
; de <- buffer start
; hl <- buffer size
; Modifies: af
FileSupplier_Supply:
	push de
	push hl
	call DOS_ReadFromFileHandle
	call DOS_TerminateIfError
	push hl
	call DOS_ConsoleStatus  ; allow ctrl-c
	pop bc
	pop hl
	pop de
	ret

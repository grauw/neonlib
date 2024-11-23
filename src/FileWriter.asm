;
; Buffered sequential-access file writer
;
FileWriter: MACRO
	super: Writer
	fileHandle:
		db 0FFH
	_size:
	ENDM

; de = file path
; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
FileWriter_Construct: PROC
	push de
	ld de,FileWriter_WriteToFile
	call Writer_Construct
	pop de
	ld a,(de)
	cp 0FFH  ; file info block?
	ld a,00000010B  ; write only
	ld b,0
	call CreateOrOpenFileHandle
	call DOS_TerminateIfError
	ld (ix + FileWriter.fileHandle),b
	ret
CreateOrOpenFileHandle:
	jp nz,DOS_CreateFileHandle
	push af
	push ix
	ld ixl,e
	ld ixh,d
	ld a,(ix + FileInfoBlock.fileSize + 0)
	or (ix + FileInfoBlock.fileSize + 1)
	or (ix + FileInfoBlock.fileSize + 2)
	or (ix + FileInfoBlock.fileSize + 3)
	call nz,System_ThrowException
	pop ix
	pop af
	jp DOS_OpenFileHandle
	ENDP

; ix = this
; ix <- this
FileWriter_Destruct:
	ld b,(ix + FileWriter.fileHandle)
	call DOS_CloseFileHandle
	jp DOS_TerminateIfError

; bc = byte count
; de = buffer start
; ix = this
; Modifies: af, bc, de, hl
FileWriter_WriteToFile:
	push bc
	call DOS_ConsoleStatus  ; allow ctrl-c
	pop hl
	ld b,(ix + FileWriter.fileHandle)
	call DOS_WriteToFileHandle
	call DOS_TerminateIfError
	jp DOS_ConsoleStatus  ; allow ctrl-c

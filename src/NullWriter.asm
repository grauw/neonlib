;
; Buffered null file writer
;
NullWriter: MACRO
	super: Writer
	_size:
	ENDM

; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
NullWriter_Construct:
	ld de,NullWriter_Flush
	jp Writer_Construct

; ix = this
; ix <- this
NullWriter_Destruct: equ Writer_Destruct
;	jp Writer_Destruct

; bc = byte count
; de = buffer start
; ix = this
NullWriter_Flush: equ DOS_ConsoleStatus
;	jp DOS_ConsoleStatus  ; allow ctrl-c

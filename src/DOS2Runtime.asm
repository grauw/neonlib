;
; DOS2 runtime
;
DOS2Runtime: MACRO ?main
	Entry:
		call DOS_IsDOS2
		ld hl,DOS2Runtime_dos2Required
		jp c,System_PrintLn

		ld hl,DOS_Terminate
		call System_SetTerminateHandler

		jp ?main
	ENDM

;
DOS2Runtime_dos2Required:
	db "MSX-DOS 2 is required.",13,10,0

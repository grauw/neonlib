;
; Top-level application program class
;
Application_Main:
	ld hl,Application_welcome
	call System_Print

	call DOS_IsDOS2
	ld hl,Application_dos2RequiredError
	jp c,Application_TerminateWithError

	call Application_CheckStack

	ld ix,Heap_main
	call Heap_Construct

	ld hl,Application_testing
	call System_Print

	call MemoryTest_Test
	call HeapTest_Test
	call ClassTest_Test
	call WriterTest_Test

	ld hl,Application_success
	call System_Print
	ret

; Check if the stack is well above the heap
Application_CheckStack:
	ld hl,-(HEAP + HEAP_SIZE + STACK_SIZE)
	add hl,sp
	ld hl,Application_insufficientTPAError
	jp nc,Application_TerminateWithError
	ret

; a <- DOS error code
Application_CheckDOSError:
	and a
	ret z
Application_TerminateWithDOSError:
	ld b,a
	ld de,Application_explainBuffer
	call DOS_ExplainErrorCode
	ld hl,Application_explainBuffer
	call System_Print
	call System_PrintCrLf
	jp DOS_Terminate

; hl <- message
Application_TerminateWithError:
	call System_Print
	jp DOS_Terminate

;
Application_welcome:
	db "Neon MSX library by Grauw",13,10,10,0

Application_testing:
	db "Running tests...",13,10,0

Application_success:
	db "Success!",13,10,0

Application_dos2RequiredError:
	db "MSX-DOS 2 is required.",13,10,0

Application_insufficientTPAError:
	db "Insufficient TPA space.",13,10,0

	SECTION RAM

Application_explainBuffer:
	ds 64,0

	ENDS

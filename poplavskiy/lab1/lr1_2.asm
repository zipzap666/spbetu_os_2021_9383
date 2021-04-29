ASTACK SEGMENT STACK
	DW 0100h DUP(?)
ASTACK ENDS

DATA SEGMENT
;ДАННЫЕ
    PC 				db 'Type PC: PC', 13, 10 ,'$'
    PC_XT 			db 'Type PC: PC/XT', 13, 10, '$'
    AT 				db 'Type PC: AT', 13, 10, '$'
    PS2_1 			db 'Type PC: PS2 модель 30', 10, 13, '$'
    PS2_2 			db 'Type PC: PS2 модель 50 or 60', 10, 13, '$'
    PS2_3 			db 'Type PC: PS2 модель 80', 10, 13, '$'
    PCjr 			db 'Type PC: PCjr',10, 13, '$'
    PC_CONVERTIBLE	db 'Type PC: PC Convertible',10, 13, '$'
    VERS 			db 'Version MS DOS:  .  ', 10, 13, '$'
    OEM 			db 'OEM serial number:    ', 10, 13, '$'
    USER			db 'User serial number:       ', 10, 13, '$'
DATA ENDS


CODE SEGMENT 
	ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:ASTACK
;ПРОЦЕДУРЫ
START: JMP BEGIN
TETR_TO_HEX PROC NEAR
		and 	AL,0Fh
		cmp 	AL,09
		jbe 	NEXT
		add 	AL,07
NEXT: 	add 	AL,30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR		;байт в AL переводится в два символа шестн. числа в AX
		push 	CX
		mov 	AH,AL
		call 	TETR_TO_HEX
		xchg 	AL,AH
		mov 	CL,4
		shr 	AL,CL
		call 	TETR_TO_HEX 	;в AL старшая цифра
		pop 	CX 				;в AH младшая
		ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR ;перевод в 16 с/с 16-ти разрядного числа, в AX - число, DI - адрес последнего символа
		push	BX
		mov		BH,AH
		call	BYTE_TO_HEX
		mov		[DI],AH
		dec		DI
		mov		[DI],AL
		dec		DI
		mov		AL,BH
		xor		AH,AH
		call	BYTE_TO_HEX
		mov		[DI],AH
		dec		DI
		mov		[DI],AL
		pop		BX
		ret
WRD_TO_HEX		ENDP

BYTE_TO_DEC PROC NEAR 	  ; перевод байта в 10с/с, SI - адрес поля младшей цифры
		push	AX        ; AL содержит исходный байт
		push 	CX
		push 	DX
		xor 	AH,AH
		xor 	DX,DX
		mov 	CX,10
loop_bd: div 	CX
		or 		DL,30h
		mov 	[SI],DL
		dec 	SI
		xor 	DX,DX
		cmp 	AX,10
		jae 	loop_bd
		cmp 	AL,00h
		je 		end_l
		or 		AL,30h
		mov 	[SI],AL
end_l:  pop 	DX
		pop 	CX
		pop		AX
		ret
BYTE_TO_DEC ENDP

PRINT PROC NEAR			;печать сообщения на экран
		push 	AX
		mov 	AH, 09h
		int 	21h
		pop 	AX
		ret
PRINT ENDP

TYPE_PC PROC NEAR 	;получение типа ПК
		push	DS
		mov		BX,0F000H
		mov		DS,BX
		sub     AX,AX
		mov		AH,DS:[0FFFEH]
		pop		DS
		ret
TYPE_PC ENDP

PRINT_TYPE_PC PROC NEAR	;вывод типа ПК
		push 	AX
		push	BX
		push	DI

		mov 	DX, OFFSET PC
		cmp 	AH, 0FFh
		je 		print_msg  

		mov 	DX, OFFSET PC_XT
		cmp 	AH, 0FEh
		je 		print_msg

		mov 	DX, OFFSET PC_XT
		cmp 	AH, 0FBh
		je 		print_msg

		mov 	DX, OFFSET AT
		cmp 	AH, 0FCh
		je 		print_msg

		mov 	DX, OFFSET PS2_1
		cmp 	AH, 0FAh
		je 		print_msg

		mov 	DX, OFFSET PS2_2
		cmp 	AH, 0FCh
		je 		print_msg

		mov 	DX, OFFSET PS2_3
		cmp 	AH, 0F8h
		je 		print_msg

		mov 	DX, OFFSET PCjr
		cmp 	AH, 0FDh
		je 		print_msg

		mov 	DX, OFFSET PC_CONVERTIBLE
		cmp 	AH, 0F9h
		je 		print_msg

		mov		AL,AH
		call 	BYTE_TO_HEX
		mov     DX, AX

	print_msg:
		call PRINT
		pop 	DI
		pop		BX
		pop		AX
		ret
PRINT_TYPE_PC ENDP

VERSION_DOS PROC NEAR
		push	AX
		push	SI
		mov 	SI, OFFSET VERS
		add 	SI, 10h
		call 	BYTE_TO_DEC
		add		SI, 3h
		mov		AL, AH
		call	BYTE_TO_DEC
		mov		DX, OFFSET VERS
		call	PRINT
		pop 	SI
		pop		AX
		ret
VERSION_DOS ENDP

OEM_NUM PROC NEAR
		push	AX
		push	BX
		push	SI
		mov		AL, BH
		mov 	SI, OFFSET OEM
		add		SI, 15h
		call	BYTE_TO_DEC
		mov		DX, OFFSET OEM
		call	PRINT
		pop		SI
		pop		BX
		pop		AX
		ret
OEM_NUM ENDP

USER_NUM PROC NEAR
		push 	CX
		push 	DI
		push 	AX

		mov 	DI, OFFSET USER
		add 	DI, 19h
		mov 	AX, CX
		call 	WRD_TO_HEX
		mov		AL, BL
		mov 	DI, OFFSET USER
		add		DI, 14h
		call	BYTE_TO_HEX
		mov		[DI], AX
		mov 	DX, OFFSET USER
		call	PRINT
		pop 	AX
		pop 	DI
		pop 	CX
  		ret

USER_NUM ENDP

BEGIN:
	mov 		AX, DATA
	mov 		DS, AX
	mov 		BX, DS
	call		TYPE_PC
	call		PRINT_TYPE_PC
	mov 		AH, 30h
	int 		21h
	call		VERSION_DOS
	call		OEM_NUM
	call		USER_NUM
	xor 		AL, AL
	mov 		AH, 4Ch
	int 		21h
CODE ENDS
END START





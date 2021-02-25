AStack    SEGMENT  STACK
    DW 128 DUP(?)
AStack    ENDS


DATA SEGMENT
    pc db 'IBM PC type: PC',0dh,0ah,'$'
    pc_xt db 'IBM PC type: PC/XT',0dh,0ah,'$'
    at db 'IBM PC type: AT',0dh,0ah,'$'
    ps2_30 db 'IBM PC type: PS2 model 30',0dh,0ah,'$'
    ps2_50_60 db 'IBM PC type: PS2 model 30 or 50',0dh,0ah,'$'
    ps2_80 db 'IBM PC type: PS2 model 80',0dh,0ah,'$'
    pcjr db 'IBM PC type: PCjr',0dh,0ah,'$'
    pc_convertible db 'IBM PC type: PC Convertible',0dh,0ah,'$'
    unknown db 'IBM PC type:    ',0dh,0ah,'$'
    version db 'Version:  . ',0dh,0ah,'$'
    oem db 'OEM:             ',0dh,0ah,'$'
    user_serial_number db 'User serial number:       ',0dh,0ah,'$'
DATA ENDS


CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack


BYTE_TO_DEC PROC near
	PUSH AX
    PUSH CX
    PUSH DX
    XOR AH,AH
    XOR DX,DX
    MOV CX,10
loop_bd:
    DIV CX
    OR DL,30h
    MOV [SI],DL
    DEC SI
    XOR DX,DX
    CMP AX,10
    JAE loop_bd
    CMP AL,00h
    JE end_l
    OR AL,30h
    MOV [SI],AL
end_l: 
    POP DX
    POP CX
	POP AX
    RET
BYTE_TO_DEC ENDP


TETR_TO_HEX PROC near
    AND AL,0Fh
    CMP AL,09
    JBE NEXT
    ADD AL,07
    NEXT: add AL,30h
    RET
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC near
    PUSH CX
    MOV AH,AL
    CALL TETR_TO_HEX
    XCHG AL,AH
    MOV CL,4
    SHR AL,CL
    CALL TETR_TO_HEX 
    POP CX 
    RET
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC near
    PUSH BX
    MOV BH,AH
    CALL BYTE_TO_HEX
    MOV [DI],AH
    DEC DI
    MOV [DI],AL
    DEC DI
    MOV AL,BH
    CALL BYTE_TO_HEX
    MOV [DI],AH
    DEC DI
    MOV [DI],AL
    POP BX
    RET
WRD_TO_HEX ENDP


Main PROC FAR
    MOV ax, DATA
    MOV ds, ax

    XOR ax,ax
    MOV ax,0f000h
    MOV es,ax
    MOV al,es:[0fffeh]

    CMP al,0ffh
    JE label_pc
    CMP al,0feh
    JE label_pc_xt
    CMP al,0fbh
    JE label_pc_xt
    CMP al,0fch
    JE label_at
    CMP al,0fah
    JE label_ps2_30
    CMP al,0fch
    JE label_ps2_50_60
    CMP al,0f8h
    JE label_ps2_80
    CMP al,0fdh
    JE label_pcjr
    CMP al,0f9h
    JE label_pc_convertible
    JNE label_unknown

label_pc:
    MOV dx,offset pc
    JMP print_ibm_pc_version
label_pc_xt:
    MOV dx,offset pc_xt
    JMP print_ibm_pc_version
label_at:
    MOV dx,offset at
    JMP print_ibm_pc_version
label_ps2_30:
    MOV dx,offset ps2_30  
    JMP print_ibm_pc_version
label_ps2_50_60:
    MOV dx,offset ps2_50_60
    JMP print_ibm_pc_version
label_ps2_80:
    MOV dx,offset ps2_80
    JMP print_ibm_pc_version
label_pcjr:
    MOV dx,offset pcjr
    JMP print_ibm_pc_version
label_pc_convertible:
    MOV dx,offset pc_convertible
    JMP print_ibm_pc_version
label_unknown:
    CALL BYTE_TO_HEX
    MOV di, offset unknown+13
    MOV [di], ax
    MOV dx,offset unknown


print_ibm_pc_version:
    MOV ah,09h
    INT 21h

    XOR bx, bx
    XOR ax, ax
    MOV ah, 30h
    INT 21h

    MOV si, offset version+9
    CALL BYTE_TO_DEC

    MOV al, ah
    MOV si, offset version+11
    CALL BYTE_TO_DEC

    MOV dx, offset version
    MOV ah,09h
    INT 21h

    MOV al, bh
    MOV si, offset oem+7
    CALL BYTE_TO_DEC
    
    MOV dx, offset oem
    MOV ah,09h
    INT 21h

    MOV al, bl
    CALL BYTE_TO_HEX

    MOV di, offset user_serial_number+20
    MOV [di], ax

    MOV ax, cx
    MOV di, offset user_serial_number+25
    CALL WRD_TO_HEX

    MOV dx, offset user_serial_number
    MOV ah,09h
    INT 21h

exit:
    XOR al,al
    MOV ah,4ch
    INT 21h

Main ENDP
CODE ENDS
END Main
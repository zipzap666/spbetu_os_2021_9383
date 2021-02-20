AStack SEGMENT STACK
    dw 256 DUP(?)   ; 1 килобайт
AStack ENDS

DATA SEGMENT

PCTYPE db 'The type of your PC is: PC', 0dh, 0ah, '$'
PCXTTYPE db 'The type of your PC is: PC/XT', 0dh, 0ah, '$'
ATTYPE db 'The type of your PC is: AT', 0dh, 0ah, '$'
PS230TYPE db 'The type of your PC is: PS2 model 30', 0dh, 0ah, '$'
PS25060TYPE db 'The type of your PC is: PS2 model 50 or 60', 0dh, 0ah, '$'
PS280TYPE db 'The type of your PC is: PS2 model 80', 0dh, 0ah, '$'
PCJRTYPE db 'The type of your PC is: PCjr', 0dh, 0ah, '$'
PCCTYPE db 'The type of your PC is: PC Convertible', 0dh, 0ah, '$'
DOS_VERSION_GREETINGS db 'Your DOS version: $'
DOS_OEM_GREETINGS db 'Your OEM number: $'
DOS_SERIAL_GREETINGS db 'Your serial number: $'
DEC_NUMBER db '     $'
SERIAL_NUMBER db '        $'
NEWLINE db 0dh, 0ah, '$'
ERROR_REIMPLEMENT db 'ERROR BUT IMPLEMENT ERROR HANDLER!', 0dh, 0ah, '$'

DATA ENDS


CODE SEGMENT
    ASSUME cs:CODE, ds:DATA, ss:AStack


TETR_TO_HEX proc near
    and al, 0fh
    cmp al, 09
    jbe next
    add al, 07

next:
    add al, 30h
    ret

TETR_TO_HEX endp

BYTE_TO_HEX proc near
    push cx
    mov ah, al
    call TETR_TO_HEX
    xchg al, ah
    mov cl, 4
    shr al, cl
    call TETR_TO_HEX
    pop cx
    ret
BYTE_TO_HEX endp

WRD_TO_HEX proc near
    push bx
    mov bh, ah
    call BYTE_TO_HEX
    mov [di], ah
    dec di
    mov [di], al
    dec di
    mov al, bh
    call BYTE_TO_HEX
    mov [di], ah
    dec di
    mov [di], al
    pop bx
    ret
WRD_TO_HEX endp


; Пишет al в DEC_NUMBER
BYTE_TO_WRD proc near

    push ax
    push cx
    push dx
    push di

    mov cx, 0
    mov dx, 0
    mov di, offset DEC_NUMBER
    loop_label: 
        cmp ax, 0 
        je write_to_str       
          
        mov bx, 10         
        div bx 
                      
        push dx

        inc cx
        xor dx,dx 
        jmp loop_label

    write_to_str:
        cmp cx, 0 
        je byte_to_wrd_exit

        pop dx
        add dx, 48 

        mov [di], dx

        dec cx 

        jmp write_to_str 

    byte_to_wrd_exit:
        inc di
        mov byte ptr [di], '$'       ; закрываем строчку
        pop di
        pop dx
        pop cx
        pop ax
        ret


BYTE_TO_WRD endp

PRINT_NEWLINE proc near

    push ax
    push dx

    mov dx, offset NEWLINE
    mov ah, 9h
    int 21h

    pop dx
    pop ax

    ret

PRINT_NEWLINE endp

PRINT_PC_TYPE proc near

    mov ax, 0f000h
    mov es, ax
    mov di, 0fffeh
    mov bl, es:[di]

    ; PC - 0xff
    cmp bl, 0ffh
    je pc_write_dx

    ; PC/XT - 0xfe, 0xfb
    cmp bl, 00feh
    je pcxt_write_dx
    cmp bl, 00fbh
    je pcxt_write_dx

    ; AT - 0xfc
    cmp bl, 0fch
    je at_write_dx

    ; PS2 model 30
    cmp bl, 0fah
    je ps230_write_dx

    ; PS2 model 50 or 60
    cmp bl, 0fch
    je ps25060_write_dx

    ; PS2 model 80
    cmp bl, 0f8h
    je ps280_write_dx

    ; PCjr
    cmp bl, 0fdh
    je pcjr_write_dx

    ; PC Convertible
    cmp bl, 0fdh
    je pcc_write_dx

    ; al to hex string, string ptr in dx
    mov dx, offset ERROR_REIMPLEMENT
    jmp print_type


pc_write_dx:
    mov dx, offset PCTYPE
    jmp print_type

pcxt_write_dx:
    mov dx, offset PCXTTYPE
    jmp print_type

at_write_dx:
    mov dx, offset ATTYPE
    jmp print_type

ps230_write_dx:
    mov dx, offset PS230TYPE
    jmp print_type

ps25060_write_dx:
    mov dx, offset PS25060TYPE
    jmp print_type

ps280_write_dx:
    mov dx, offset PS280TYPE
    jmp print_type

pcjr_write_dx:
    mov dx, offset PCJRTYPE
    jmp print_type

pcc_write_dx:
    mov dx, offset PCCTYPE
    ; тут можно было бы и без jmp print_type, но это чревато ошибками при 
    ; добавлении новых типов компуктеров
    jmp print_type

print_type:
    ; string ptr в dx
    mov ah, 9
    int 21h

print_pc_type_exit:
    ret

PRINT_PC_TYPE endp

PRINT_DOS_VERSION proc near

    push ax
    push bx
    push cx
    push dx

    ; DOS VERSION
    mov dx, offset DOS_VERSION_GREETINGS
    mov ah, 9h
    int 21h

    mov ah, 30h
    int 21h
    ; оставляем только al
    and ax, 0ffh
    call BYTE_TO_WRD

    mov dx, offset DEC_NUMBER
    mov ah, 9h
    int 21h

    ; print "."
    mov dl, '.'
    mov ah, 02h
    int 21h

    ; оставляем только ah
    and ax, 0ff00h
    call BYTE_TO_WRD

    mov dx, offset DEC_NUMBER
    mov ah, 9h
    int 21h

    call PRINT_NEWLINE

    ; OEM
    mov dx, offset DOS_OEM_GREETINGS
    mov ah, 9h
    int 21h

    push bx         ; сохраняем bx, потому что в bl тоже есть нужная информация
    and bx, 0ff00h  ; оставляем только bh
    mov ax, bx      ; заносим в ax для процедуры BYTE_TO_WRD
    call BYTE_TO_WRD

    ; и печатаем
    mov dx, offset DEC_NUMBER
    mov ah, 9h
    int 21h
    pop bx          ; восстанавливаемся

    call PRINT_NEWLINE

    ; SERIAL
    mov dx, offset DOS_SERIAL_GREETINGS
    mov ah, 9h
    int 21h

    ; cx в SERIAL_NUMBER
    mov di, offset SERIAL_NUMBER
    add di, 5                       ; ????????????????????????????
    mov ax, cx
    call WRD_TO_HEX

    ; в al и ah коды символов цифр числа из bl
    mov al, bl
    call BYTE_TO_HEX
    sub di, 2
    mov [di], ax
    
    ; выводим номер
    mov dx, offset SERIAL_NUMBER
    mov ah, 9h
    int 21h

print_dos_version_exit:
    pop dx
    pop cx
    pop bx
    pop ax

    ret

PRINT_DOS_VERSION endp



Main proc far
    mov ax, DATA
    mov ds, ax    

    call PRINT_PC_TYPE
    call PRINT_DOS_VERSION

    ; выход в DOS
    xor al, al
    mov ah, 4ch
    int 21h
Main endp


CODE  ENDS
        END Main
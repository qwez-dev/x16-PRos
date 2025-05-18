[BITS 16]
[ORG 900h]

start:
    call clear_screen
    mov si, title_msg
    call print_string
    mov si, help_msg
    call print_string
    call print_newline

key_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x1B    ; ESC
    je exit_program
    
    cmp al, 'z'
    je play_C_low
    cmp al, 'x'
    je play_D_low
    cmp al, 'c'
    je play_E_low
    cmp al, 'v'
    je play_F_low
    cmp al, 'b'
    je play_G_low
    cmp al, 'n'
    je play_A_low
    cmp al, 'm'
    je play_B_low
    
    cmp al, 'a'
    je play_C
    cmp al, 's'
    je play_D
    cmp al, 'd'
    je play_E
    cmp al, 'f'
    je play_F
    cmp al, 'g'
    je play_G
    cmp al, 'h'
    je play_A
    cmp al, 'j'
    je play_B
    cmp al, 'k'
    je play_C_high
    
    cmp al, 'q'
    je play_C_highest
    cmp al, 'w'
    je play_D_highest
    cmp al, 'e'
    je play_E_highest
    cmp al, 'r'
    je play_F_highest
    cmp al, 't'
    je play_G_highest
    cmp al, 'y'
    je play_A_highest
    cmp al, 'u'
    je play_B_highest
    cmp al, 'i'
    je play_C_super_high
    
    jmp key_loop

; ------ Low notes (zxcvbnm) ------
play_C_low:
    mov ax, 18242   ; C (Do)
    jmp play_note
play_D_low:
    mov ax, 16252   ; D (Re)
    jmp play_note
play_E_low:
    mov ax, 14478   ; E (Mi)
    jmp play_note
play_F_low:
    mov ax, 13666   ; F (Fa)
    jmp play_note
play_G_low:
    mov ax, 12174   ; G (Sol)
    jmp play_note
play_A_low:
    mov ax, 10846   ; A (La)
    jmp play_note
play_B_low:
    mov ax, 9662    ; B (Si)
    jmp play_note

; ------ Medium notes (asdfghjk) ------
play_C:
    mov ax, 9121    ; C (Do)
    jmp play_note
play_D:
    mov ax, 8126    ; D (Re)
    jmp play_note
play_E:
    mov ax, 7239    ; E (Mi)
    jmp play_note
play_F:
    mov ax, 6833    ; F (Fa)
    jmp play_note
play_G:
    mov ax, 6087    ; G (Sol)
    jmp play_note
play_A:
    mov ax, 5423    ; A (La)
    jmp play_note
play_B:
    mov ax, 4831    ; B (Si)
    jmp play_note
play_C_high:
    mov ax, 4560    ; C (Do)
    jmp play_note

; ------ High notes (qwertyui) ------
play_C_highest:
    mov ax, 2280    ; C (Do)
    jmp play_note
play_D_highest:
    mov ax, 2032    ; D (Re)
    jmp play_note
play_E_highest:
    mov ax, 1810    ; E (Mi)
    jmp play_note
play_F_highest:
    mov ax, 1708    ; F (Fa)
    jmp play_note
play_G_highest:
    mov ax, 1522    ; G (Sol)
    jmp play_note
play_A_highest:
    mov ax, 1356    ; A (La)
    jmp play_note
play_B_highest:
    mov ax, 1208    ; B (Si)
    jmp play_note
play_C_super_high:
    mov ax, 1140    ; C (Do)
    jmp play_note

; ------ Playing note ------
play_note:
    mov dx, 250
    call set_frequency
    call on_pc_speaker
    call delay_ms
    call off_pc_speaker
    jmp key_loop

exit_program:
    int 0x19

; ------ IO functions ------
clear_screen:
    mov ax, 0x12
    int 0x10
    ret

print_string:
    mov ah, 0x0E
    mov bl, 0x0F
.print_char:
    lodsb 
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret
    
print_newline:
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A 
    int 0x10
    ret

; ------ PC Speaker functions ------
on_pc_speaker:
    pusha
    in al, 0x61
    or al, 0x03
    out 0x61, al
    popa
    ret

off_pc_speaker:
    pusha
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    popa
    ret

set_frequency:
    push ax
    mov al, 0xB6
    out 0x43, al
    pop ax
    out 0x42, al
    mov al, ah
    out 0x42, al
    ret

delay_ms:
    pusha
    mov ax, dx
    mov cx, 1000
    mul cx
    mov cx, dx
    mov dx, ax
    mov ah, 0x86
    int 0x15
    popa
    ret

; ------ Data section ------
title_msg db 0xC9, 51 dup(0xCD), 0xBB, 10, 13
          db 0xBA, '     PRos piano v0.1  |  Uses PC speaker           ', 0xBA, 10, 13
          db 0xC0, 51 dup(0xCD), 0xBC, 10, 13, 0

help_msg  db 0xC9, 51 dup(0xCD), 0xBB, 10, 13
          db 0xBA, '  Use keyboard keys to play notes across 3 octaves ', 0xBA, 10, 13
          db 0xC3, 51 dup(0xC4), 0xB4, 10, 13
          db 0xBA, '  Low octave:  Z X C V B N M                       ', 0xBA, 10, 13
          db 0xBA, '  Mid octave:  A S D F G H J K                     ', 0xBA, 10, 13
          db 0xBA, '  High octave: Q W E R T Y U I                     ', 0xBA, 10, 13
          db 0xC3, 51 dup(0xC4), 0xB4, 10, 13
          db 0xBA, '  Press ESC to quit                                ', 0xBA, 10, 13
          db 0xC0, 51 dup(0xCD), 0xBC, 10, 13, 0

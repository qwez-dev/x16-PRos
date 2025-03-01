[BITS 16]
[ORG 7c00h]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    call set_video_mode

    mov bl, 0x01
    mov cx, 2000
    mov di, 0xB800
    rep stosw
    
    mov ah, 0x02
    mov al, 4        
    mov ch, 0         
    mov dh, 0        
    mov cl, 2       
    mov bx, 500h     
    int 0x13         

    jc disk_error     

    jmp 500h       

disk_error:
    mov si, error_message
    mov di, 0xB800
    call print_string
    jmp $             

set_video_mode:
    mov ax, 0x03
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.print_char:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .print_char
.done:
    ret

error_message db "Disk read error.", 13, 10, 0

times 510 - ($ - $$) db 0
dw 0xAA55


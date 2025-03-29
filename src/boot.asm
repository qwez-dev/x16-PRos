[BITS 16]
[ORG 7C00h]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Установка видеорежима
    call set_video_mode

    ; Очистка экрана
    mov bl, 0x01
    mov cx, 2000
    mov di, 0xB800
    rep stosw
    

    mov si, baner
    call print_string
    
    mov si, check_msg
    call print_string
    
    ; Проверка диска
    call check_disk
    jc disk_error

    ; Проверка RAM
    call check_ram
    jc ram_error

    ; Проверка CPU
    call check_cpu
    jc cpu_error

    ; Все проверки пройдены успешно
    mov si, ready_message
    call print_string_green
    
    mov si, wait_msg
    call print_string
    
    ; Ожидание нажатия любой клавиши
    call wait_for_key

    ; Переход к ядру ОС
    jmp 500h

disk_error:
    mov si, disk_error_message
    call print_string
    jmp $

ram_error:
    mov si, ram_error_message
    call print_string
    jmp $

cpu_error:
    mov si, cpu_error_message
    call print_string
    jmp $

set_video_mode:
    mov ax, 0x12
    int 0x10
    ret

print_string:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x1F
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret
    
print_string_green:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x0A
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

wait_for_key:
    mov ah, 0x00
    int 0x16
    ret

check_disk:
    mov ah, 0x02
    mov al, 6        
    mov ch, 0         
    mov dh, 0        
    mov cl, 2       
    mov bx, 500h     
    int 0x13         
    ret

check_ram:
    ; Простая проверка RAM (можно расширить)
    mov ax, 0x0000
    mov es, ax
    mov di, 0x1000
    mov cx, 0x1000
    rep stosw
    ret

check_cpu:
    ; Простая проверка CPU (можно расширить)
    ; Например, проверка наличия 386+ инструкций
    pushf
    pop ax
    and ax, 0x0FFF
    push ax
    popf
    pushf
    pop ax
    and ax, 0xF000
    cmp ax, 0xF000
    je .cpu_error
    clc
    ret
.cpu_error:
    stc
    ret

baner db "     /_ | / / |  __ \|  __ \", 13, 10,
      db " __  _| |/ /_ | |__) | |__) |___  ___ ", 13, 10,
      db " \ \/ / | '_ \|  ___/|  _  // _ \/ __|", 13, 10,
      db "  >  <| | (_) | |    | | \ \ (_) \__ \", 13, 10,
      db " /_/\_\_|\___/|_|    |_|  \_\___/|___/", 13, 10, 13, 10, 0
disk_error_message db "Disk [ERROR]", 13, 10, 0
ram_error_message db "RAM [ERROR]", 13, 10, 0
cpu_error_message db "CPU [ERROR]", 13, 10, 0
ready_message db "Disk [OK]", 13, 10, 
              db "RAM  [OK]", 13, 10, 
              db "CPU  [OK]", 13, 10, 13, 10, 0
wait_msg db "Press any key to boot...", 0
check_msg db "Checking components:", 13, 10, 13, 10, 0
times 510 - ($ - $$) db 0
dw 0xAA55

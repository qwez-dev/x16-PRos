[BITS 16]
[ORG 0x8000] 

SCREEN_WIDTH    equ 80
SCREEN_HEIGHT   equ 25
GAME_WIDTH      equ 30
GAME_HEIGHT     equ 18
GAME_LEFT       equ 25
GAME_TOP        equ 5
PLAYER_CHAR     equ 0xDB
ASTEROID_CHAR   equ 0xB1
MAX_ASTEROIDS   equ 10
ASTEROID_SPEED  equ 1
VIDEO_MEM       equ 0xB800

section .data
    player_x        dw 50
    player_y        dw 18
    player_x_old    dw 50
    player_y_old    dw 18
    asteroid_x      times MAX_ASTEROIDS dw 0
    asteroid_y      times MAX_ASTEROIDS dw 0
    asteroid_x_old  times MAX_ASTEROIDS dw 0
    asteroid_y_old  times MAX_ASTEROIDS dw 0
    asteroid_active times MAX_ASTEROIDS db 0
    score           dw 0
    score_old       dw 0xFFFF
    game_over       db 0
    random_seed     dw 1234
    tick_counter    db 0
    first_draw      db 1
    exit_flag       db 0    ; Флаг для выхода
    
    title_msg       db 'SPACE ARCADE', 0
    score_msg       db 'Score: ', 0
    game_over_msg   db 'GAME OVER! Press any key to quit', 0
    author_msg      db 'By: Qwez', 0
    controls_msg    db 'ESC - quit, Arrows - move', 0
    
section .text
start:
    pusha
    
    ; Установка текстового режима 80x25
    mov ax, 0x0003
    int 0x10
    
    ; Отключение курсора
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10
    
    mov ax, VIDEO_MEM
    mov es, ax
    
    ; Инициализация генератора случайных чисел
    xor ax, ax
    int 0x1A
    mov [random_seed], dx
    
    ; Установка начальной позиции игрока
    mov ax, GAME_LEFT
    add ax, GAME_WIDTH/2
    mov [player_x], ax
    mov [player_x_old], ax
    
    mov ax, GAME_TOP
    add ax, GAME_HEIGHT-2
    mov [player_y], ax
    mov [player_y_old], ax
    
    call init_asteroids
    call draw_static_elements

game_loop:
    cmp byte [exit_flag], 1
    je .exit_game
    
    cmp byte [game_over], 1
    je game_over_screen
    
    mov cx, 2
    call delay
    
    call check_keyboard
    
    inc byte [tick_counter]
    cmp byte [tick_counter], ASTEROID_SPEED
    jl .skip_asteroid_update
    
    mov byte [tick_counter], 0
    call update_asteroids
    call check_collisions
    
.skip_asteroid_update:
    call update_screen
    jmp game_loop

.exit_game:
    ; Восстанавливаем видеорежим как в референсе
    mov ax, 0x12
    int 0x10
    ret

game_over_screen:
    mov ax, 0x0003
    int 0x10
    
    mov dh, 12
    mov dl, 22
    call set_cursor
    
    mov si, game_over_msg
    mov bl, 0x0C    
    call print_string_color
    
    mov dh, 14
    mov dl, 34
    call set_cursor
    
    mov si, score_msg
    call print_string
    mov ax, [score]
    call print_number
    
    mov ah, 0x00
    int 0x16
    
    ; Устанавливаем флаг выхода
    mov byte [exit_flag], 1
    jmp game_loop

init_asteroids:
    mov di, asteroid_active
    mov cx, MAX_ASTEROIDS
    xor al, al
    rep stosb
    
    mov cx, MAX_ASTEROIDS
    xor di, di
.init_loop:
    mov word [asteroid_x_old + di], 0
    mov word [asteroid_y_old + di], 0
    add di, 2
    loop .init_loop
    ret

check_keyboard:
    mov ah, 0x01
    int 0x16
    jz .no_key
    
    mov ah, 0x00
    int 0x16
    
    cmp ah, 0x4B        ; Стрелка влево
    je .move_left
    cmp ah, 0x4D        ; Стрелка вправо
    je .move_right
    cmp ah, 0x48        ; Стрелка вверх
    je .move_up
    cmp ah, 0x50        ; Стрелка вниз
    je .move_down
    cmp al, 0x1B        ; ESC
    je .escape_pressed
    jmp .done
    
.escape_pressed:
    mov byte [exit_flag], 1
    jmp .done
    
.move_left:
    mov ax, [player_x]
    cmp ax, GAME_LEFT+1
    jle .done
    mov [player_x_old], ax
    dec word [player_x]
    jmp .done
    
.move_right:
    mov ax, [player_x]
    cmp ax, GAME_LEFT+GAME_WIDTH-2
    jge .done
    mov [player_x_old], ax
    inc word [player_x]
    jmp .done
    
.move_up:
    mov ax, [player_y]
    cmp ax, GAME_TOP+1
    jle .done
    mov [player_y_old], ax
    dec word [player_y]
    jmp .done
    
.move_down:
    mov ax, [player_y]
    cmp ax, GAME_TOP+GAME_HEIGHT-2
    jge .done
    mov [player_y_old], ax
    inc word [player_y]
    jmp .done
    
.done:
.no_key:
    ret

update_asteroids:
    call random
    and ax, 0x0F
    cmp ax, 2
    jg .update_existing
    
    mov cx, MAX_ASTEROIDS
    mov di, 0
.find_inactive:
    cmp byte [asteroid_active + di], 0
    je .spawn_asteroid
    inc di
    loop .find_inactive
    jmp .update_existing
    
.spawn_asteroid:
    mov byte [asteroid_active + di], 1
    
    call random
    xor dx, dx
    mov cx, GAME_WIDTH-2
    div cx
    add dx, GAME_LEFT+1
    
    mov si, di
    shl si, 1
    mov [asteroid_x + si], dx
    mov [asteroid_x_old + si], dx
    
    mov word [asteroid_y + si], GAME_TOP+1
    mov word [asteroid_y_old + si], GAME_TOP+1
    
.update_existing:
    mov cx, MAX_ASTEROIDS
    mov di, 0
.move_loop:
    cmp byte [asteroid_active + di], 0
    je .next_asteroid
    
    mov si, di
    shl si, 1
    
    mov ax, [asteroid_y + si]
    mov [asteroid_y_old + si], ax
    inc word [asteroid_y + si]
    
    mov ax, [asteroid_y + si]
    cmp ax, GAME_TOP+GAME_HEIGHT-1
    jl .next_asteroid
    
    ; Стираем астероид перед деактивацией
    push ax
    push bx
    push di
    
    mov ax, [asteroid_y_old + si]
    mov bx, 160
    mul bx
    mov bx, [asteroid_x + si]
    shl bx, 1
    add ax, bx
    mov di, ax
    mov ax, 0x0720
    stosw
    
    pop di
    pop bx
    pop ax
    
    mov byte [asteroid_active + di], 0
    inc word [score]
    
.next_asteroid:
    inc di
    cmp di, MAX_ASTEROIDS
    jl .move_loop
    ret

check_collisions:
    mov cx, MAX_ASTEROIDS
    mov di, 0
.check_loop:
    cmp byte [asteroid_active + di], 0
    je .next_asteroid
    
    mov si, di
    shl si, 1
    mov ax, [asteroid_x + si]
    mov dx, [asteroid_y + si]
    
    cmp ax, [player_x]
    jne .next_asteroid
    cmp dx, [player_y]
    jne .next_asteroid
    
    mov byte [game_over], 1
    ret
    
.next_asteroid:
    inc di
    cmp di, MAX_ASTEROIDS
    jl .check_loop
    ret

draw_static_elements:
    ; Очистка экрана
    xor di, di
    mov cx, 2000
    mov ax, 0x0720
    rep stosw
    
    ; Заголовок
    mov di, 0*160 + 33*2
    mov si, title_msg
    mov ah, 0x0E
    call draw_string_video
    
    ; Метка счета
    mov di, 2*160 + 35*2
    mov si, score_msg
    mov ah, 0x0A
    call draw_string_video
    
    ; Автор
    mov di, 24*160 + 1*2
    mov si, author_msg
    mov ah, 0x0B
    call draw_string_video
    
    ; Управление
    mov di, 24*160 + 50*2
    mov si, controls_msg
    mov ah, 0x0F
    call draw_string_video
    
    ; Рисуем границы
    call draw_game_border
    
    mov byte [first_draw], 0
    ret

update_screen:
    ; Обновляем счет если изменился
    mov ax, [score]
    cmp ax, [score_old]
    je .skip_score
    
    mov [score_old], ax
    mov di, 2*160 + 42*2
    call draw_number_video
    
.skip_score:
    ; Стираем старую позицию игрока
    mov ax, [player_y_old]
    cmp ax, [player_y]
    jne .erase_player
    mov ax, [player_x_old]
    cmp ax, [player_x]
    je .skip_player_erase
    
.erase_player:
    mov ax, [player_y_old]
    mov bx, 160
    mul bx
    mov bx, [player_x_old]
    shl bx, 1
    add ax, bx
    mov di, ax
    mov ax, 0x0720
    stosw
    
.skip_player_erase:
    ; Рисуем игрока в новой позиции
    mov ax, [player_y]
    mov bx, 160
    mul bx
    mov bx, [player_x]
    shl bx, 1
    add ax, bx
    mov di, ax
    mov ax, 0x0A00 | PLAYER_CHAR
    stosw
    
    ; Обновляем астероиды
    mov cx, MAX_ASTEROIDS
    xor si, si
.asteroid_loop:
    ; Стираем старую позицию если активен
    cmp byte [asteroid_active + si], 0
    je .next_asteroid
    
    mov bx, si
    shl bx, 1
    
    ; Стираем старую позицию
    mov ax, [asteroid_y_old + bx]
    push bx
    mov bx, 160
    mul bx
    pop bx
    push bx
    mov bx, [asteroid_x_old + bx]
    shl bx, 1
    add ax, bx
    mov di, ax
    mov ax, 0x0720
    stosw
    pop bx
    
    ; Рисуем в новой позиции
    mov ax, [asteroid_y + bx]
    push bx
    mov bx, 160
    mul bx
    pop bx
    push bx
    mov bx, [asteroid_x + bx]
    shl bx, 1
    add ax, bx
    mov di, ax
    mov ax, 0x0C00 | ASTEROID_CHAR
    stosw
    pop bx
    
    ; Обновляем старые координаты
    mov ax, [asteroid_x + bx]
    mov [asteroid_x_old + bx], ax
    mov ax, [asteroid_y + bx]
    mov [asteroid_y_old + bx], ax
    
.next_asteroid:
    inc si
    loop .asteroid_loop
    
    mov ax, [player_x]
    mov [player_x_old], ax
    mov ax, [player_y]
    mov [player_y_old], ax
    
    ret

draw_game_border:
    ; Верхняя граница
    mov di, GAME_TOP*160 + GAME_LEFT*2
    mov cx, GAME_WIDTH
    mov ax, 0x0B3D
.top_loop:
    stosw
    loop .top_loop
    
    ; Нижняя граница
    mov di, (GAME_TOP+GAME_HEIGHT)*160 + GAME_LEFT*2
    mov cx, GAME_WIDTH
    mov ax, 0x0B3D
.bottom_loop:
    stosw
    loop .bottom_loop
    
    ; Боковые границы
    mov cx, GAME_HEIGHT-1
    mov di, (GAME_TOP+1)*160 + GAME_LEFT*2
.side_loop:
    mov ax, 0x0BBA
    stosw
    add di, (GAME_WIDTH-2)*2
    mov ax, 0x0BBA
    stosw
    add di, 160 - GAME_WIDTH*2
    loop .side_loop
    
    ret

draw_string_video:
    ; ah = атрибут
.loop:
    lodsb
    or al, al
    jz .done
    stosw
    jmp .loop
.done:
    ret

draw_number_video:
    ; ax = число, di = позиция
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov bx, 10
    mov cx, 0
    
    test ax, ax
    jnz .divide_loop
    mov al, '0'
    mov ah, 0x0A
    stosw
    jmp .done
    
.divide_loop:
    test ax, ax
    jz .print_digits
    
    xor dx, dx
    div bx
    
    push dx
    inc cx
    jmp .divide_loop
    
.print_digits:
    test cx, cx
    jz .done
    
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x0A
    stosw
    
    dec cx
    jmp .print_digits
    
.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

set_cursor:
    mov bh, 0
    mov ah, 0x02
    int 0x10
    ret

print_string_color:
    mov ah, 0x09
    mov bh, 0
    mov cx, 1
.loop:
    lodsb
    cmp al, 0
    je .done
    
    int 0x10
    
    inc dl
    call set_cursor
    
    mov ah, 0x09
    jmp .loop
.done:
    ret

print_string:
    mov ah, 0x0E
    mov bh, 0
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

print_number:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    mov cx, 0
    
    test ax, ax
    jnz .divide_loop
    mov al, '0'
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .done
    
.divide_loop:
    test ax, ax
    jz .print_digits
    
    xor dx, dx
    div bx
    
    push dx
    inc cx
    jmp .divide_loop
    
.print_digits:
    test cx, cx
    jz .done
    
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    
    dec cx
    jmp .print_digits
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

random:
    push dx
    mov ax, [random_seed]
    mov dx, 8405h
    mul dx
    add ax, 1
    mov [random_seed], ax
    pop dx
    ret

delay:
    push ax
    push cx
    push dx
.delay_loop:
    push cx
    mov ah, 0x00
    int 0x1A
    mov bx, dx
.wait_loop:
    mov ah, 0x00
    int 0x1A
    cmp dx, bx
    je .wait_loop
    pop cx
    loop .delay_loop
    pop dx
    pop cx
    pop ax
    ret

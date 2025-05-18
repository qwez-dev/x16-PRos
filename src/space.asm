[BITS 16]
[ORG 900h] 

SCREEN_WIDTH    equ 80
SCREEN_HEIGHT   equ 25
GAME_WIDTH      equ 30
GAME_HEIGHT     equ 18
GAME_LEFT       equ 25
GAME_TOP        equ 5
PLAYER_CHAR     equ 0xDB                      ; Символ игрока
ASTEROID_CHAR   equ 0xB1                      ; Символ астероида
MAX_ASTEROIDS   equ 10                        ; Максимальное количество астероидов
ASTEROID_SPEED  equ 1                         ; Скорость астероидов
VIDEO_MEM       equ 0xB800                    ; Адрес видеопамяти

section .data
    player_x        dw 50                     ; Позиция игрока по X
    player_y        dw 18                     ; Позиция игрока по Y
    asteroid_x      times MAX_ASTEROIDS dw 0  ; Позиции астероидов по X
    asteroid_y      times MAX_ASTEROIDS dw 0  ; Позиции астероидов по Y
    asteroid_active times MAX_ASTEROIDS db 0  ; Активные астероиды
    score           dw 0                      ; Счет игры
    game_over       db 0                      ; Флаг окончания игры
    random_seed     dw 1234                   ; Зерно для генератора случайных чисел
    tick_counter    db 0                      ; Счетчик тиков
    
    title_msg       db 'SPACE ARCADE', 0
    score_msg       db 'Score: ', 0
    game_over_msg   db 'GAME OVER! Press any key to quit', 0
    author_msg      db 'By: Qwez', 0
    controls_msg    db 'ESC - quit, Arrows - move', 0
    
section .text
start:
    mov ax, 0x12
    int 0x10

    mov ax, VIDEO_MEM    ; Установка видеопамяти
    mov es, ax
    
    xor ax, ax           ; Инициализация генератора случайных чисел
    int 0x1A
    mov [random_seed], dx
    
    mov ax, GAME_LEFT    ; Установка начальной позиции игрока
    add ax, GAME_WIDTH/2
    mov [player_x], ax
    
    mov ax, GAME_TOP
    add ax, GAME_HEIGHT-2
    mov [player_y], ax
    
    call init_asteroids  ; Инициализация астероидов

game_loop:
    cmp byte [game_over], 1    ; Проверка окончания игры
    je game_over_screen
    
    mov cx, 1                  ; Задержка
    call delay
    
    call check_keyboard        ; Проверка клавиатуры
    
    inc byte [tick_counter]    ; Обновление счетчика тиков
    cmp byte [tick_counter], ASTEROID_SPEED
    jl .skip_asteroid_update
    
    mov byte [tick_counter], 0
    call update_asteroids      ; Обновление астероидов
    call check_collisions      ; Проверка столкновений
    
.skip_asteroid_update:
    call draw_screen           ; Отрисовка экрана
    jmp game_loop

game_over_screen:
    mov ax, 0x0003             ; Очистка экрана
    int 0x10
    
    mov dh, 12                 ; Установка курсора
    mov dl, 22
    call set_cursor
    
    mov si, game_over_msg      ; Вывод сообщения "Игра окончена"
    mov bl, 0x0C    
    call print_string_color
    
    mov dh, 14                 ; Установка курсора
    mov dl, 34
    call set_cursor
    
    mov si, score_msg          ; Вывод счета
    call print_string
    mov ax, [score]
    call print_number
    
    mov ah, 0x00               ; Ожидание нажатия клавиши
    int 0x16
    
    int 0x19                   ; Перезагрузка

init_asteroids:
    mov di, asteroid_active    ; Деактивация всех астероидов
    mov cx, MAX_ASTEROIDS
    xor al, al
    rep stosb
    ret

check_keyboard:
    mov ah, 0x01               ; Проверка наличия нажатия клавиши
    int 0x16
    jz .no_key
    
    mov ah, 0x00               ; Получение кода клавиши
    int 0x16
    
    cmp ah, 0x4B               ; Стрелка влево
    je .move_left
    cmp ah, 0x4D               ; Стрелка вправо
    je .move_right
    cmp ah, 0x48               ; Стрелка вверх
    je .move_up
    cmp ah, 0x50               ; Стрелка вниз
    je .move_down
    cmp al, 0x1B               ; ESC - выход
    je .quit_to_os
    jmp .done
    
.move_left:
    mov ax, [player_x]         ; Проверка границы слева
    cmp ax, GAME_LEFT+1
    jle .done
    dec word [player_x]        ; Смещение игрока влево
    jmp .done
    
.move_right:
    mov ax, [player_x]         ; Проверка границы справа
    cmp ax, GAME_LEFT+GAME_WIDTH-2
    jge .done
    inc word [player_x]        ; Смещение игрока вправо
    jmp .done
    
.move_up:
    mov ax, [player_y]         ; Проверка верхней границы
    cmp ax, GAME_TOP+1
    jle .done
    dec word [player_y]        ; Смещение игрока вверх
    jmp .done
    
.move_down:
    mov ax, [player_y]         ; Проверка нижней границы
    cmp ax, GAME_TOP+GAME_HEIGHT-2
    jge .done
    inc word [player_y]        ; Смещение игрока вниз
    jmp .done
    
.quit_to_os:
    int 0x19                   ; Перезагрузка
    
.done:
.no_key:
    ret

update_asteroids:
    call random                ; Генерация случайного числа
    and ax, 0x0F
    cmp ax, 2
    jg .update_existing
    
    mov cx, MAX_ASTEROIDS      ; Поиск неактивного астероида
    mov di, 0
.find_inactive:
    cmp byte [asteroid_active + di], 0
    je .spawn_asteroid
    inc di
    loop .find_inactive
    jmp .update_existing
    
.spawn_asteroid:
    mov byte [asteroid_active + di], 1  ; Активация астероида
    
    call random                ; Генерация случайной X-позиции
    xor dx, dx
    mov cx, GAME_WIDTH-2
    div cx
    add dx, GAME_LEFT+1
    
    mov si, di
    shl si, 1
    mov [asteroid_x + si], dx
    
    mov word [asteroid_y + si], GAME_TOP+1  ; Установка Y-позиции вверху игрового поля
    
.update_existing:
    mov cx, MAX_ASTEROIDS      ; Обновление всех активных астероидов
    mov di, 0
.move_loop:
    cmp byte [asteroid_active + di], 0
    je .next_asteroid
    
    mov si, di
    shl si, 1
    inc word [asteroid_y + si]  ; Смещение астероида вниз
    
    mov ax, [asteroid_y + si]
    cmp ax, GAME_TOP+GAME_HEIGHT-1  ; Проверка нижней границы
    jl .next_asteroid
    
    mov byte [asteroid_active + di], 0  ; Деактивация астероида
    inc word [score]                    ; Увеличение счета
    
.next_asteroid:
    inc di
    cmp di, MAX_ASTEROIDS
    jl .move_loop
    ret

check_collisions:
    mov cx, MAX_ASTEROIDS       ; Проверка столкновений со всеми астероидами
    mov di, 0
.check_loop:
    cmp byte [asteroid_active + di], 0
    je .next_asteroid
    
    mov si, di
    shl si, 1
    mov ax, [asteroid_x + si]   ; Позиция астероида
    mov dx, [asteroid_y + si]
    
    cmp ax, [player_x]          ; Сравнение с позицией игрока
    jne .next_asteroid
    cmp dx, [player_y]
    jne .next_asteroid
    
    mov byte [game_over], 1     ; Установка флага окончания игры
    ret
    
.next_asteroid:
    inc di
    cmp di, MAX_ASTEROIDS
    jl .check_loop
    ret

draw_screen:
    mov ax, 0x0003              ; Очистка экрана
    int 0x10
    
    mov dh, 0                   ; Установка курсора для заголовка
    mov dl, 33
    call set_cursor
    
    mov si, title_msg           ; Вывод заголовка
    mov bl, 0x0E
    call print_string_color
    
    mov dh, 2                   ; Установка курсора для счета
    mov dl, 35
    call set_cursor
    
    mov si, score_msg           ; Вывод счета
    mov bl, 0x0A
    call print_string_color
    
    mov ax, [score]
    call print_number
    
    mov dh, SCREEN_HEIGHT-1     ; Установка курсора для имени автора
    mov dl, 1
    call set_cursor
    
    mov si, author_msg          ; Вывод имени автора
    mov bl, 0x0B
    call print_string_color
    
    mov dh, SCREEN_HEIGHT-1     ; Установка курсора для управления
    mov dl, 50
    call set_cursor
    
    mov si, controls_msg        ; Вывод управления
    mov bl, 0x0F
    call print_string_color
    
    call draw_game_border       ; Отрисовка границы игрового поля
    
    mov dh, [player_y]          ; Установка курсора на позицию игрока
    mov dl, [player_x]
    call set_cursor
    
    mov al, PLAYER_CHAR         ; Отрисовка игрока
    mov bl, 0x0A
    mov cx, 1
    mov ah, 0x09
    int 0x10
    
    mov cx, MAX_ASTEROIDS       ; Отрисовка всех астероидов
    mov di, 0
.draw_asteroid_loop:
    cmp byte [asteroid_active + di], 0
    je .next_asteroid
    
    mov si, di
    shl si, 1
    
    mov dh, [asteroid_y + si]   ; Установка курсора на позицию астероида
    mov dl, [asteroid_x + si]
    call set_cursor
    
    mov al, ASTEROID_CHAR       ; Отрисовка астероида
    mov bl, 0x0C
    mov cx, 1
    mov ah, 0x09
    int 0x10
    
.next_asteroid:
    inc di
    cmp di, MAX_ASTEROIDS
    jl .draw_asteroid_loop
    
    ret

draw_game_border:
    mov dh, GAME_TOP            ; Установка курсора для верхней границы
    mov dl, GAME_LEFT
    call set_cursor
    
    mov cx, GAME_WIDTH          ; Отрисовка верхней границы
    mov al, '='
    mov bl, 0x0B
.top_loop:
    push cx
    mov cx, 1
    mov ah, 0x09
    int 0x10
    
    inc dl
    call set_cursor
    
    pop cx
    loop .top_loop
    
    mov dh, GAME_TOP+GAME_HEIGHT  ; Установка курсора для нижней границы
    mov dl, GAME_LEFT
    call set_cursor
    
    mov cx, GAME_WIDTH          ; Отрисовка нижней границы
    mov al, '='
    mov bl, 0x0B
.bottom_loop:
    push cx
    mov cx, 1
    mov ah, 0x09
    int 0x10
    
    inc dl
    call set_cursor
    
    pop cx
    loop .bottom_loop
    
    mov dh, GAME_TOP+1          ; Отрисовка боковых границ
.side_loop:
    cmp dh, GAME_TOP+GAME_HEIGHT
    jge .done
    
    mov dl, GAME_LEFT           ; Левая граница
    call set_cursor
    
    mov al, 0xBA
    mov bl, 0x0B
    mov cx, 1
    mov ah, 0x09
    int 0x10
    
    mov dl, GAME_LEFT+GAME_WIDTH-1  ; Правая граница
    call set_cursor
    
    mov al, 0xBA
    mov bl, 0x0B
    mov cx, 1
    mov ah, 0x09
    int 0x10
    
    inc dh
    jmp .side_loop
.done:
    ret

set_cursor:                     ; Установка позиции курсора
    mov bh, 0
    mov ah, 0x02
    int 0x10
    ret

print_string_color:             ; Вывод строки с цветом
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

print_string:                   ; Вывод строки
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

print_number:                   ; Вывод числа
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    mov cx, 0
    
    test ax, ax                 ; Проверка на ноль
    jnz .divide_loop
    mov al, '0'
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .done
    
.divide_loop:                   ; Разделение числа на цифры
    test ax, ax
    jz .print_digits
    
    xor dx, dx
    div bx
    
    push dx
    inc cx
    jmp .divide_loop
    
.print_digits:                  ; Вывод цифр
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

random:                         ; Генератор псевдослучайных чисел
    push dx
    mov ax, [random_seed]
    mov dx, 8405h
    mul dx
    add ax, 1
    mov [random_seed], ax
    pop dx
    ret

delay:                          ; Функция задержки
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

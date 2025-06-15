[BITS 16]
[ORG 0x8000]

start:
    mov ax, 0600h
    mov bh, 0x0F
    xor cx, cx
    mov dx, 184Fh
    int 10h
    
    mov ax, 0x03
    int 0x10

    mov ah, 0x01
    mov ch, 0x00
    mov cl, 0x07
    int 0x10

    mov dl, 0
    mov dh, 24
    call set_cursor_pos

    mov bp, msg
    mov cx, 80
    call print_message

    mov dl, 0 
    mov dh, 0
    call set_cursor_pos

    mov bp, helper
    mov cx, 80
    call print_message
    
option_loop:
    mov ah, 10h
    int 16h

    cmp ah, 3Bh
    jz load_text
    cmp al, 0Dh
    jz print_text
    jmp option_loop

load_text:
    ; Clear filename buffer
    mov di, filename
    mov cx, 12
    mov al, 0
    rep stosb

    ; Prompt for filename
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, load_prompt
    mov cx, 22
    call print_message3

    ; Get filename input
    mov di, filename
    mov cx, 0
    call get_filename_input
    jc .no_filename

    ; Load file using OS file system
    mov ax, filename
    mov bx, string
    mov cx, 512
    call fs_load_file
    jc .load_failed
    mov word [file_size], bx  ; Save file size
    mov si, bx                ; Set si to file size for editing

    ; Clear editing area (lines 3 to 22)
    mov ax, 0600h
    mov bh, 0x0F
    mov cx, 0300h             ; Start at line 3, column 0
    mov dx, 164Fh             ; End at line 22, column 79
    int 10h

    ; Display loaded text
    mov dl, 0
    mov dh, 3
    call set_cursor_pos
    mov bp, string
    mov cx, bx
    call print_message2

    ; Set cursor to end of text
    mov ax, bx
    mov bx, string
    mov cx, 0
    mov dl, 0
    mov dh, 3
.calculate_cursor:
    cmp cx, ax
    je .set_cursor
    mov al, [bx]
    inc bx
    inc cx
    cmp al, 0x0D
    jne .check_lf
    mov dl, 0
    inc dh
    inc cx
    inc bx
    jmp .calculate_cursor
.check_lf:
    cmp al, 0x0A
    je .next_line
    inc dl
    cmp dl, 80
    jb .calculate_cursor
    mov dl, 0
    inc dh
    jmp .calculate_cursor
.next_line:
    mov dl, 0
    inc dh
    jmp .calculate_cursor
.set_cursor:
    mov si, cx                ; Update si to file size
    call set_cursor_pos
    jmp command_loop

.load_failed:
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, load_failed_msg
    mov cx, 16
    call print_message3
    mov ah, 00h
    int 16h
    jmp .clear_prompt

.no_filename:
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, no_filename_msg
    mov cx, 16
    call print_message3
    mov ah, 00h
    int 16h

.clear_prompt:
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, clear_msg
    mov cx, 80
    call print_message3
    mov dl, 0
    mov dh, 3
    call set_cursor_pos
    jmp command_loop

print_text:
    xor dx, dx
    add dh, 3
    call set_cursor_pos
    mov si, 0

command_loop:
    mov ah, 10h
    int 16h

    cmp al, 1Bh
    jz esc_exit
    cmp al, 0Dh
    jz new_line
    cmp ah, 0Eh
    jz delete_symbol
    cmp ah, 3Ch
    jz save_text

    cmp si, 510               ; Reserve space for CR+LF
    jge command_loop

    mov [string + si], al
    inc si
    mov ah, 09h
    mov bx, 0004h
    mov bl, 0x0F
    mov cx, 1
    int 10h

    add dl, 1
    call set_cursor_pos
    jmp command_loop

new_line:
    cmp si, 510               ; Reserve space for CR+LF
    jge command_loop
    mov byte [string + si], 0x0D
    inc si
    mov byte [string + si], 0x0A
    inc si
    add dh, 1
    xor dl, dl
    call set_cursor_pos
    jmp command_loop

save_text:
    ; Clear filename buffer
    mov di, filename
    mov cx, 12
    mov al, 0
    rep stosb

    ; Prompt for filename
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, save_prompt
    mov cx, 22
    call print_message3

    ; Get filename input
    mov di, filename
    mov cx, 0
    call get_filename_input
    jc .no_filename

    ; Save file using OS file system
    mov ax, filename
    mov bx, string
    mov cx, si
    call fs_write_file
    jc .save_failed

    ; Display success message
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, saved_msg
    mov cx, 10
    call print_message3
    jmp .save_done

.save_failed:
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, save_failed_msg
    mov cx, 16
    call print_message3

.save_done:
    mov ah, 00h
    int 16h
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, clear_msg
    mov cx, 80
    call print_message3

    mov dl, 0
    mov dh, 3
    call set_cursor_pos
    jmp command_loop

.no_filename:
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, no_filename_msg
    mov cx, 16
    call print_message3
    mov ah, 00h
    int 16h
    mov dl, 0
    mov dh, 23
    call set_cursor_pos
    mov bp, clear_msg
    mov cx, 80
    call print_message3
    mov dl, 0
    mov dh, 3
    call set_cursor_pos
    jmp command_loop

delete_symbol:
    cmp si, 0
    je command_loop
    cmp dl, 0
    jne .delete_char
    cmp dh, 3
    jz command_loop
    sub dh, 1
    mov dl, 79
    ; Check if previous character is LF
    mov bx, si
    sub bx, 1
    cmp byte [string + bx], 0x0A
    je .delete_crlf
    jmp .update_cursor

.delete_char:
    sub dl, 1
    ; Check if previous character is LF
    mov bx, si
    sub bx, 1
    cmp byte [string + bx], 0x0A
    je .delete_crlf
    jmp .update_cursor

.delete_crlf:
    cmp si, 1
    je command_loop
    sub si, 1
    cmp byte [string + si - 1], 0x0D
    jne command_loop
    dec si
    sub dl, 1
    cmp dl, 0
    jne .update_cursor
    cmp dh, 3
    jz command_loop
    sub dh, 1
    mov dl, 79

.update_cursor:
    call set_cursor_pos
    mov al, 20h
    mov [string + si], al
    mov ah, 09h
    mov bx, 0004h
    mov bl, 0x0F
    mov cx, 1
    int 10h
    dec si
    jmp command_loop

esc_exit:
    mov ax, 0x12
    int 0x10
    ret

print_message:
    mov bl, 0x1F
    mov ax, 1301h
    int 10h
    ret
    
print_message2:
    mov bl, 0x0F
    mov ax, 1301h
    pusha
    mov si, bp
    mov cx, 0
.print_loop:
    cmp cx, [file_size]
    je .done
    lodsb
    cmp al, 0x0D
    je .handle_cr
    cmp al, 0x0A
    je .handle_lf
    mov ah, 0Eh
    mov bl, 0x0F
    int 10h
    inc cx
    mov ah, 03h
    xor bh, bh
    int 10h
    inc dl
    cmp dl, 80
    jb .print_loop
    mov dl, 0
    inc dh
    mov ah, 02h
    int 10h
    jmp .print_loop
.handle_cr:
    inc cx
    lodsb
    cmp al, 0x0A
    jne .print_loop
.handle_lf:
    inc cx
    mov dl, 0

    mov ah, 02h
    xor bh, bh
    int 10h
    mov dl, 0
    inc dh
    int 10h
    jmp .print_loop
.done:
    popa
    ret
    
print_message3:
    mov bl, 0x02
    mov ax, 1301h
    int 10h
    ret
    
print_string:
    mov ah, 0Eh
.print_char:
    lodsb
    or al, al
    jz .done
    int 10h
    jmp .print_char
.done:
    ret
    
set_cursor_pos:
    mov ah, 2h
    xor bh, bh
    int 10h
    ret

get_filename_input:
    pusha
.get_filename:
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    je .filename_done
    cmp al, 08h
    je .handle_backspace
    cmp cx, 11
    jge .get_filename
    stosb
    mov ah, 0Eh
    mov bl, 0x0F
    int 10h
    inc cx
    jmp .get_filename

.handle_backspace:
    cmp cx, 0
    je .get_filename
    dec di
    dec cx
    mov al, 08h
    mov ah, 0Eh
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h
    jmp .get_filename

.filename_done:
    mov byte [di], 0
    cmp cx, 0
    je .no_filename
    popa
    clc
    ret

.no_filename:
    popa
    stc
    ret

; --- Included OS Functions ---

string_string_length:
    pusha
    mov bx, ax
    mov cx, 0
.more:
    cmp byte [bx], 0
    je .done
    inc bx
    inc cx
    jmp .more
.done:
    mov word [.tmp_counter], cx
    popa
    mov ax, [.tmp_counter]
    ret
.tmp_counter dw 0

string_string_uppercase:
    pusha
    mov si, ax
.more:
    cmp byte [si], 0
    je .done
    cmp byte [si], 'a'
    jb .noatoz
    cmp byte [si], 'z'
    ja .noatoz
    sub byte [si], 20h
    inc si
    jmp .more
.noatoz:
    inc si
    jmp .more
.done:
    popa
    ret

int_filename_convert:
    pusha
    mov si, ax
    call string_string_length
    cmp ax, 14
    jg .failure
    cmp ax, 0
    je .failure
    mov dx, ax
    mov di, .dest_string
    mov cx, 0
.copy_loop:
    lodsb
    cmp al, '.'
    je .extension_found
    stosb
    inc cx
    cmp cx, dx
    jg .failure
    jmp .copy_loop
.extension_found:
    cmp cx, 0
    je .failure
    cmp cx, 8
    je .do_extension
.add_spaces:
    mov byte [di], ' '
    inc di
    inc cx
    cmp cx, 8
    jl .add_spaces
.do_extension:
    lodsb
    cmp al, 0
    je .failure
    stosb
    lodsb
    cmp al, 0
    je .failure
    stosb
    lodsb
    cmp al, 0
    je .failure
    stosb
    mov byte [di], 0
    popa
    mov ax, .dest_string
    clc
    ret
.failure:
    popa
    stc
    ret
.dest_string times 13 db 0

fs_file_exists:
    call string_string_uppercase
    call int_filename_convert
    push ax
    call string_string_length
    cmp ax, 0
    je .failure
    pop ax
    push ax
    call fs_read_root_dir
    pop ax
    mov di, disk_buffer
    call fs_get_root_entry
    ret
.failure:
    pop ax
    stc
    ret

fs_load_file:
    pusha
    mov si, ax
    call string_string_length
    cmp ax, 0
    je .failure
    mov word [.location], bx
    mov word [.size], cx
    call string_string_uppercase
    call int_filename_convert
    jc .failure
    mov word [.filename], ax
    call fs_file_exists
    jc .failure
    mov word ax, [.filename]
    call fs_get_root_entry
    mov word bx, [.location]
    mov word ax, [di+28]
    mov word [.bytes], ax
    mov word ax, [di+26]
    cmp ax, 0
    je .finished
    mov word [.cluster], ax
.read_loop:
    mov word ax, [.cluster]
    add ax, 31
    call fs_convert_l2hts
    mov bx, ds
    mov es, bx
    mov word bx, [.location]
    mov ah, 2
    mov al, 1
    pusha
.read_loop_inner:
    popa
    pusha
    stc
    int 13h
    jnc .read_ok
    call fs_reset_floppy
    jnc .read_loop_inner
    popa
    jmp .failure
.read_ok:
    popa
    mov word ax, [.bytes]
    cmp ax, 512
    jb .last_bytes
    sub word [.bytes], 512
    add word [.location], 512
    call fs_read_fat
    mov word ax, [.cluster]
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    mov si, disk_buffer
    add si, ax
    mov ax, word [ds:si]
    or dx, dx
    jz .even
.odd:
    shr ax, 4
    jmp .read_loop_cont
.even:
    and ax, 0FFFh
.read_loop_cont:
    mov word [.cluster], ax
    cmp ax, 0FF8h
    jae .finished
    jmp .read_loop
.last_bytes:
    mov word [.bytes], ax
.finished:
    mov word bx, [.bytes]
    popa
    mov word [es:bx], ax
    clc
    ret
.failure:
    popa
    stc
    ret
.cluster dw 0
.bytes dw 0
.filename dw 0
.location dw 0
.size dw 0

fs_remove_file:
    pusha
    call string_string_uppercase
    call int_filename_convert
    push ax
    clc
    call fs_read_root_dir
    mov di, disk_buffer
    pop ax
    call fs_get_root_entry
    jc .failure
    mov ax, word [es:di+26]
    mov word [.cluster], ax
    mov byte [di], 0E5h
    inc di
    mov cx, 0
.clean_loop:
    mov byte [di], 0
    inc di
    inc cx
    cmp cx, 31
    jl .clean_loop
    call fs_write_root_dir
    call fs_read_fat
    mov di, disk_buffer
.more_clusters:
    mov word ax, [.cluster]
    cmp ax, 0
    je .nothing_to_do
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    mov si, disk_buffer
    add si, ax
    mov ax, word [ds:si]
    or dx, dx
    jz .even
.odd:
    push ax
    and ax, 000Fh
    mov word [ds:si], ax
    pop ax
    shr ax, 4
    jmp .calculate_cluster_cont
.even:
    push ax
    and ax, 0F000h
    mov word [ds:si], ax
    pop ax
    and ax, 0FFFh
.calculate_cluster_cont:
    mov word [.cluster], ax
    cmp ax, 0FF8h
    jae .end
    jmp .more_clusters
.end:
    call fs_write_fat
    jc .failure
.nothing_to_do:
    popa
    clc
    ret
.failure:
    popa
    stc
    ret
.cluster dw 0

fs_create_file:
    clc
    call string_string_uppercase
    call int_filename_convert
    pusha
    push ax
    call fs_file_exists
    jnc .exists_error
    mov di, disk_buffer
    mov cx, 224
.next_entry:
    mov byte al, [di]
    cmp al, 0
    je .found_free_entry
    cmp al, 0E5h
    je .found_free_entry
    add di, 32
    loop .next_entry
.exists_error:
    pop ax
    popa
    stc
    ret
.found_free_entry:
    pop si
    mov cx, 11
    rep movsb
    sub di, 11
    mov byte [di+11], 0
    mov byte [di+12], 0
    mov byte [di+13], 0
    mov byte [di+14], 0C6h
    mov byte [di+15], 07Eh
    mov byte [di+16], 0
    mov byte [di+17], 0
    mov byte [di+18], 0
    mov byte [di+19], 0
    mov byte [di+20], 0
    mov byte [di+21], 0
    mov byte [di+22], 0C6h
    mov byte [di+23], 07Eh
    mov byte [di+24], 0
    mov byte [di+25], 0
    mov byte [di+26], 0
    mov byte [di+27], 0
    mov byte [di+28], 0
    mov byte [di+29], 0
    mov byte [di+30], 0
    mov byte [di+31], 0
    call fs_write_root_dir
    jc .failure
    popa
    clc
    ret
.failure:
    popa
    stc
    ret

fs_read_fat:
    pusha
    mov ax, 1
    call fs_convert_l2hts
    mov si, disk_buffer
    mov bx, ds
    mov es, bx
    mov bx, si
    mov ah, 2
    mov al, 9
    pusha
.read_fat_loop:
    popa
    pusha
    stc
    int 13h
    jnc .fat_done
    call fs_reset_floppy
    jnc .read_fat_loop
    popa
    jmp .read_failure
.fat_done:
    popa
    popa
    clc
    ret
.read_failure:
    popa
    stc
    ret

fs_write_fat:
    pusha
    mov ax, 1
    call fs_convert_l2hts
    mov si, disk_buffer
    mov bx, ds
    mov es, bx
    mov bx, si
    mov ah, 3
    mov al, 9
    stc
    int 13h
    jc .write_failure
    popa
    clc
    ret
.write_failure:
    popa
    stc
    ret

fs_read_root_dir:
    pusha
    mov ax, 19
    call fs_convert_l2hts
    mov si, disk_buffer
    mov bx, ds
    mov es, bx
    mov bx, si
    mov ah, 2
    mov al, 14
    pusha
.read_root_dir_loop:
    popa
    pusha
    stc
    int 13h
    jnc .root_dir_finished
    call fs_reset_floppy
    jnc .read_root_dir_loop
    popa
    jmp .read_failure
.root_dir_finished:
    popa
    popa
    clc
    ret
.read_failure:
    popa
    stc
    ret

fs_write_root_dir:
    pusha
    mov ax, 19
    call fs_convert_l2hts
    mov si, disk_buffer
    mov bx, ds
    mov es, bx
    mov bx, si
    mov ah, 3
    mov al, 14
    stc
    int 13h
    jc .write_failure
    popa
    clc
    ret
.write_failure:
    popa
    stc
    ret

fs_get_root_entry:
    pusha
    mov word [.filename], ax
    mov cx, 224
    mov ax, 0
.to_next_root_entry:
    xchg cx, dx
    mov word si, [.filename]
    mov cx, 11
    rep cmpsb
    je .found_file
    add ax, 32
    mov di, disk_buffer
    add di, ax
    xchg dx, cx
    loop .to_next_root_entry
    popa
    stc
    ret
.found_file:
    sub di, 11
    mov word [.tmp], di
    popa
    mov word di, [.tmp]
    clc
    ret
.filename dw 0
.tmp dw 0

fs_reset_floppy:
    push ax
    push dx
    mov ax, 0
    mov dl, [bootdev]
    stc
    int 13h
    pop dx
    pop ax
    ret

fs_convert_l2hts:
    push bx
    push ax
    mov bx, ax
    mov dx, 0
    div word [SecsPerTrack]
    add dl, 01h
    mov cl, dl
    mov ax, bx
    mov dx, 0
    div word [SecsPerTrack]
    mov dx, 0
    div word [Sides]
    mov dh, dl
    mov ch, al
    pop ax
    pop bx
    mov dl, [bootdev]
    ret

fs_write_file:
    pusha
    mov si, ax
    call string_string_length
    cmp ax, 0
    je near .failure
    mov ax, si
    call string_string_uppercase
    call int_filename_convert
    jc near .failure
    mov word [.filesize], cx
    mov word [.location], bx
    mov word [.filename], ax
    call fs_file_exists
    jc .create_new_file
    call fs_remove_file
    jc .failure
.create_new_file:
    pusha
    mov di, .free_clusters
    mov cx, 128
.clean_free_loop:
    mov word [di], 0
    inc di
    inc di
    loop .clean_free_loop
    popa
    mov ax, cx
    mov dx, 0
    mov bx, 512
    div bx
    cmp dx, 0
    jg .add_a_bit
    jmp .carry_on
.add_a_bit:
    add ax, 1
.carry_on:
    mov word [.clusters_needed], ax
    mov word ax, [.filename]
    call fs_create_file
    jc near .failure
    mov word bx, [.filesize]
    cmp bx, 0
    je near .finished
    call fs_read_fat
    mov si, disk_buffer + 3
    mov bx, 2
    mov word cx, [.clusters_needed]
    mov dx, 0
.find_free_cluster:
    lodsw
    and ax, 0FFFh
    jz .found_free_even
.more_odd:
    inc bx
    dec si
    lodsw
    shr ax, 4
    or ax, ax
    jz .found_free_odd
.more_even:
    inc bx
    jmp .find_free_cluster
.found_free_even:
    push si
    mov si, .free_clusters
    add si, dx
    mov word [si], bx
    pop si
    dec cx
    cmp cx, 0
    je .finished_list
    inc dx
    inc dx
    jmp .more_odd
.found_free_odd:
    push si
    mov si, .free_clusters
    add si, dx
    mov word [si], bx
    pop si
    dec cx
    cmp cx, 0
    je .finished_list
    inc dx
    inc dx
    jmp .more_even
.finished_list:
    mov cx, 0
    mov word [.count], 1
.chain_loop:
    mov word ax, [.count]
    cmp word ax, [.clusters_needed]
    je .last_cluster
    mov di, .free_clusters
    add di, cx
    mov word bx, [di]
    mov ax, bx
    mov dx, 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    mov si, disk_buffer
    add si, ax
    mov ax, word [ds:si]
    or dx, dx
    jz .even
.odd:
    and ax, 000Fh
    mov di, .free_clusters
    add di, cx
    mov word bx, [di+2]
    shl bx, 4
    add ax, bx
    mov word [ds:si], ax
    inc word [.count]
    inc cx
    inc cx
    jmp .chain_loop
.even:
    and ax, 0F000h
    mov di, .free_clusters
    add di, cx
    mov word bx, [di+2]
    add ax, bx
    mov word [ds:si], ax
    inc word [.count]
    inc cx
    inc cx
    jmp .chain_loop
.last_cluster:
    mov di, .free_clusters
    add di, cx
    mov word bx, [di]
    mov ax, bx
    mov dx, 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    mov si, disk_buffer
    add si, ax
    mov ax, word [ds:si]
    or dx, dx
    jz .even_last
.odd_last:
    and ax, 000Fh
    add ax, 0FF80h
    jmp .finito
.even_last:
    and ax, 0F000h
    add ax, 0FF8h
.finito:
    mov word [ds:si], ax
    call fs_write_fat
    mov cx, 0
.save_loop:
    mov di, .free_clusters
    add di, cx
    mov word ax, [di]
    cmp ax, 0
    je near .write_root_entry
    pusha
    add ax, 31
    call fs_convert_l2hts
    mov word bx, [.location]
    mov ah, 3
    mov al, 1
    stc
    int 13h
    popa
    add word [.location], 512
    inc cx
    inc cx
    jmp .save_loop
.write_root_entry:
    call fs_read_root_dir
    mov word ax, [.filename]
    call fs_get_root_entry
    mov word ax, [.free_clusters]
    mov word [di+26], ax
    mov word cx, [.filesize]
    mov word [di+28], cx
    mov byte [di+30], 0
    mov byte [di+31], 0
    call fs_write_root_dir
.finished:
    popa
    clc
    ret
.failure:
    popa
    stc
    ret
.filesize dw 0
.cluster dw 0
.count dw 0
.location dw 0
.clusters_needed dw 0
.filename dw 0
.free_clusters times 128 dw 0

; --- Data Section ---

msg db 'PRos writer v0.2                                                               ', 13, 10, 0
helper db 'ENTER - start typing     F1 - load text     F2 - save text     ESC - quit       ', 13, 10, 0
saved_msg db 'Text saved!', 13, 10, 0
save_prompt db 'Enter filename to save: ', 0
load_prompt db 'Enter filename to load: ', 0
save_failed_msg db 'Failed to save file', 0
load_failed_msg db 'Failed to load file', 0
no_filename_msg db 'No filename entered', 0
clear_msg db '                                                                                ', 0
filename times 12 db 0
string times 512 db 0
disk_buffer times 8192 db 0
file_size dw 0
bootdev db 0
Sides dw 2
SecsPerTrack dw 18
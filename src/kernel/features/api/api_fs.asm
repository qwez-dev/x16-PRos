; ==================================================================
; x16-PRos - Kernel File System API (Interrupt-Driven)
; Copyright (C) 2025 PRoX2011
;
; Provides file system functions via INT 0x22
; Function codes in AH:
;   0x00: Initialize file system (resets floppy)
;   0x01: Get file list (AX = buffer, returns BX = size low, CX = size high, DX = file count)
;   0x02: Load file (AX = filename, CX = load position, returns BX = file size)
;   0x03: Write file (AX = filename, BX = buffer, CX = size)
;   0x04: Check if file exists (AX = filename)
;   0x05: Create empty file (AX = filename)
;   0x06: Remove file (AX = filename)
;   0x07: Rename file (AX = old name, BX = new name)
;   0x08: Get file size (AX = filename, returns BX = size)
; Preserves all registers unless specified in function description
; Sets carry flag (CF) on error
; ==================================================================

[BITS 16]

; -----------------------------
; Initialize the file system API (sets up INT 0x22 and resets floppy)
; IN  : None
; OUT : None
; Preserves: All registers
api_fs_init:
    pusha
    push es
    ; Set up INT 0x22 in IVT
    xor ax, ax
    mov es, ax
    mov word [es:0x22*4], int22_handler ; Offset
    mov word [es:0x22*4+2], cs          ; Segment
    ; Reset floppy
    mov ax, 0
    call fs_reset_floppy
    pop es
    popa
    ret

; -----------------------------
; INT 0x22 Handler
; IN  : AH = Function code, other registers per function (AX, BX, CX for parameters)
; OUT : Per function (e.g., BX, CX, DX for get_file_list; BX for load_file, get_file_size)
; Preserves: All registers unless specified in function
int22_handler:
    pusha
    pushf                       ; Save flags (for carry flag)
    cmp ah, 0x00
    je .init
    cmp ah, 0x01
    je .get_file_list
    cmp ah, 0x02
    je .load_file
    cmp ah, 0x03
    je .write_file
    cmp ah, 0x04
    je .file_exists
    cmp ah, 0x05
    je .create_file
    cmp ah, 0x06
    je .remove_file
    cmp ah, 0x07
    je .rename_file
    cmp ah, 0x08
    je .get_file_size
    stc                         ; Unknown function, set carry
    jmp .done

.init:
    mov ax, 0
    call fs_reset_floppy
    jc .error
    jmp .done

.get_file_list:
    mov word [.tmp_ax], ax      ; Save buffer pointer
    call fs_get_file_list
    mov word [.tmp_bx], bx      ; Save total size (low word)
    mov word [.tmp_cx], cx      ; Save total size (high word)
    mov word [.tmp_dx], dx      ; Save file count
    jmp .done

.load_file:
    mov word [.tmp_ax], ax      ; Save filename
    mov word [.tmp_cx], cx      ; Save load position
    call fs_load_file
    mov word [.tmp_bx], bx      ; Save file size
    jmp .done

.write_file:
    mov word [.tmp_ax], ax      ; Save filename
    mov word [.tmp_bx], bx      ; Save buffer
    mov word [.tmp_cx], cx      ; Save size
    call fs_write_file
    jmp .done

.file_exists:
    mov word [.tmp_ax], ax      ; Save filename
    call fs_file_exists
    jmp .done

.create_file:
    mov word [.tmp_ax], ax      ; Save filename
    call fs_create_file
    jmp .done

.remove_file:
    mov word [.tmp_ax], ax      ; Save filename
    call fs_remove_file
    jmp .done

.rename_file:
    mov word [.tmp_ax], ax      ; Save old name
    mov word [.tmp_bx], bx      ; Save new name
    call fs_rename_file
    jmp .done

.get_file_size:
    mov word [.tmp_ax], ax      ; Save filename
    call fs_get_file_size
    mov word [.tmp_bx], bx      ; Save file size
    jmp .done

.error:
    stc                         ; Set carry on error
.done:
    ; Restore return values
    mov bx, word [.tmp_bx]
    mov cx, word [.tmp_cx]
    mov dx, word [.tmp_dx]
    popf                        ; Restore flags (including carry)
    popa
    iret

; Temporary storage for register values
.tmp_ax dw 0
.tmp_bx dw 0
.tmp_cx dw 0
.tmp_dx dw 0

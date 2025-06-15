[BITS 16]
[ORG 0x8000]

start:
    mov ah, 0x01
    mov si, hello_msg
    int 0x21
    ret

hello_msg db 'Hello, PRos!', 10, 13, 0
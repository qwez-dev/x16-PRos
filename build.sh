# ==================================================================
# x16-PRos -- The x16-PRos build script for Linux
# Copyright (C) 2025 PRoX2011
# ==================================================================

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

print_msg() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

check_error() {
    if [ $? -ne 0 ]; then
        print_msg "$RED" "Error: $1"
        exit 1
    fi
}

mkdir bin
mkdir disk_img

print_msg "$NC" ""

print_msg "$GREEN" "========== Starting x16-PRos build... =========="

print_msg "$NC" ""

print_msg "$BLUE" "Compiling bootloader (boot.asm)..."
nasm -f bin src/bootloader/boot.asm -o bin/BOOT.BIN
check_error "Bootloader compilation failed"

print_msg "$BLUE" "Compiling kernel (kernel.asm)..."
nasm -f bin src/kernel/kernel.asm -o bin/KERNEL.BIN
check_error "Kernel compilation failed"

print_msg "$BLUE" "Creating disk image..."
dd if=/dev/zero of=disk_img/x16pros.img bs=512 count=2880
check_error "Disk image creation failed"

print_msg "$BLUE" "Formatting disk image..."
mkfs.fat -F 12 disk_img/x16pros.img
check_error "Disk formatting failed"

print_msg "$BLUE" "Writing bootloader to disk..."
dd if=bin/BOOT.BIN of=disk_img/x16pros.img conv=notrunc
check_error "Bootloader writing failed"

print_msg "$BLUE" "Copying kernel to disk..."
mcopy -i disk_img/x16pros.img bin/KERNEL.BIN ::/
check_error "Kernel copy failed"

print_msg "$NC" ""

print_msg "$BLUE" "Compiling programs pakage..."
# ---------------- PROGRAMS -------------------

# Hello, PRos
nasm -f bin programs/hello.asm -o bin/HELLO.BIN
mcopy -i disk_img/x16pros.img bin/HELLO.BIN ::/

# Writer
nasm -f bin programs/write.asm -o bin/WRITER.BIN
mcopy -i disk_img/x16pros.img bin/WRITER.BIN ::/

# Barchart
nasm -f bin programs/barchart.asm -o bin/BCHART.BIN
mcopy -i disk_img/x16pros.img bin/BCHART.BIN ::/

# Brainf
nasm -f bin programs/brainf.asm -o bin/BRAINF.BIN
mcopy -i disk_img/x16pros.img bin/BRAINF.BIN ::/

# Calc
nasm -f bin programs/calc.asm -o bin/CALC.BIN
mcopy -i disk_img/x16pros.img bin/CALC.BIN ::/

# Memory
nasm -f bin programs/memory.asm -o bin/MEMORY.BIN
mcopy -i disk_img/x16pros.img bin/MEMORY.BIN ::/

# Mine
nasm -f bin programs/mine.asm -o bin/MINE.BIN
mcopy -i disk_img/x16pros.img bin/MINE.BIN ::/

# Piano
nasm -f bin programs/piano.asm -o bin/PIANO.BIN
mcopy -i disk_img/x16pros.img bin/PIANO.BIN ::/

# Snake
nasm -f bin programs/snake.asm -o bin/SNAKE.BIN
mcopy -i disk_img/x16pros.img bin/SNAKE.BIN ::/

# Space
nasm -f bin programs/space.asm -o bin/SPACE.BIN
mcopy -i disk_img/x16pros.img bin/SPACE.BIN ::/

# Procentages
nasm -f bin programs/procentc.asm -o bin/PROCENTC.BIN
mcopy -i disk_img/x16pros.img bin/PROCENTC.BIN ::/

# ----------------------------------------------


# ---------------- TEXT FILES ----------------

mcopy -i disk_img/x16pros.img LICENSE.TXT ::/
mcopy -i disk_img/x16pros.img ABOUT.TXT ::/

# --------------------------------------------

print_msg "$NC" ""

print_msg "$YELLOW" "Disk contents:"
mdir -i disk_img/x16pros.img ::/

print_msg "$NC" ""
print_msg "$GREEN" "========== Build completed successfully! =========="

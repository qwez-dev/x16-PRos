GREEN='\033[32m'
NC='\033[0m'

LOGO='
██╗  ██╗ ██╗ ██████╗       ██████╗ ██████╗  ██████╗ ███████╗
╚██╗██╔╝███║██╔════╝       ██╔══██╗██╔══██╗██╔═══██╗██╔════╝
 ╚███╔╝ ╚██║███████╗ █████╗██████╔╝██████╔╝██║   ██║███████╗
 ██╔██╗  ██║██╔═══██╗╚════╝██╔═══╝ ██╔══██╗██║   ██║╚════██║
██╔╝ ██╗ ██║╚██████╔╝      ██║     ██║  ██║╚██████╔╝███████║
╚═╝  ╚═╝ ╚═╝ ╚═════╝       ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
____________________________________________________________
'

echo -e "${GREEN}Compiling the bootloader${NC}"
nasm -f bin src/boot.asm -o bin/boot.bin

echo -e "${GREEN}Compiling the kernel and programs${NC}"
nasm -f bin src/kernel.asm -o bin/kernel.bin
nasm -f bin src/write.asm -o bin/write.bin
nasm -f bin src/brainf.asm -o bin/brainf.bin
nasm -f bin src/barchart.asm -o bin/barchart.bin
nasm -f bin src/snake.asm -o bin/snake.bin
nasm -f bin src/calc.asm -o bin/calc.bin
nasm -f bin src/disk-tools.asm -o bin/disk-tools.bin
nasm -f bin src/mine.asm -o bin/mine.bin
nasm -f bin src/memory.asm -o bin/memory.bin
nasm -f bin src/space.asm -o bin/space.bin
nasm -f bin src/piano.asm -o bin/piano.bin

echo -e "${GREEN}Creating a disk image${NC}"
dd if=/dev/zero of=disk_img/x16pros.img bs=512 count=50

dd if=bin/boot.bin of=disk_img/x16pros.img conv=notrunc
dd if=bin/kernel.bin of=disk_img/x16pros.img bs=512 seek=1 conv=notrunc
dd if=bin/write.bin of=disk_img/x16pros.img bs=512 seek=10 conv=notrunc 
dd if=bin/brainf.bin of=disk_img/x16pros.img bs=512 seek=13 conv=notrunc 
dd if=bin/barchart.bin of=disk_img/x16pros.img bs=512 seek=16 conv=notrunc
dd if=bin/snake.bin of=disk_img/x16pros.img bs=512 seek=17 conv=notrunc
dd if=bin/calc.bin of=disk_img/x16pros.img bs=512 seek=19 conv=notrunc
dd if=bin/disk-tools.bin of=disk_img/x16pros.img bs=512 seek=21 conv=notrunc
dd if=bin/ILM.BIN of=disk_img/x16pros.img bs=512 seek=26 conv=notrunc
dd if=bin/mine.bin of=disk_img/x16pros.img bs=512 seek=35 conv=notrunc
dd if=bin/memory.bin of=disk_img/x16pros.img bs=512 seek=36 conv=notrunc
dd if=bin/space.bin of=disk_img/x16pros.img bs=512 seek=37 conv=notrunc
dd if=bin/piano.bin of=disk_img/x16pros.img bs=512 seek=40 conv=notrunc
echo -e "${GREEN}Done.${NC}"

echo -e "${GREEN}${LOGO}${NC}"

echo -e "${GREEN}Launching QEMU...${NC}"
qemu-system-i386 -audiodev pa,id=snd0 -machine pcspk-audiodev=snd0 -hda disk_img/x16pros.img

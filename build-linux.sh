echo "Compiling the bootloader"
nasm -f bin boot.asm -o bin/boot.bin

echo "Compiling the kernel"
nasm -f bin kernel.asm -o bin/kernel.bin

echo "Creating a disk image"
dd if=/dev/zero of=disk_img/x16pros.img bs=512 count=16

dd if=bin/boot.bin of=disk_img/x16pros.img conv=notrunc
dd if=bin/kernel.bin of=disk_img/x16pros.img bs=512 seek=1 conv=notrunc
echo "Done."

qemu-system-i386 -hda disk_img/x16pros.img

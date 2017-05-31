nasm -o boot.bin boot.asm
nasm -o os.bin os.asm
dd if=boot.bin of=disk.img bs=512 count=1 conv=notrunc
dd if=os.bin of=disk.img seek=1 bs=512 count=5 conv=notrunc

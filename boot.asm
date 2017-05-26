    org 07c00h 
    jmp short LABEL_START
    nop
    OSCodeSec           db 5

    BS_OEMName          db 'ForrestY'
    BPB_BytePerSec      dw 512          ;每个扇区的大小
    BPB_SecPerClus      db 1            ;每个簇的扇区数
    BPB_RsvdSecCnt      dw 5            ;Boot记录占用多少扇区
    BPB_NumFATs         db 1            ;FAT个数
    BPB_RootEntCnt      dw 224          ;根目录文件最大值
    BPB_TotSec16        dw 2880         ;逻辑扇区总数
    BPB_Media           db 0xf0         ;媒体描述符
    BPB_FATSz16         dw 9            ;每个FAT扇区数
    BPB_SecPerTrk       dw 18           ;每磁道扇区数
    BPB_NumHeads        dw 2            ;磁头数
    BPB_HiddSec         dd 0            ;隐藏扇区数
    BPB_TotSec32        dd 0            ;如果wTotalSectorCount是0，由这个值记录扇区数
    BS_DrvNum           db 0            ;中断13的驱动器号
    BS_Reserved1        db 0
    BS_BootSig          db 29h          ;扩展引导标记（29h）
    BS_VolID            dd 0            ;卷序列号
    BS_VolLab           db 'Tinix0.01  ';卷标，必须11字节
    BS_FileSysType      db 'FAT12   '   ;文件系统类型，必须8字节


BaseOfStack equ 07c00h

LABEL_START:

    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack
    ; call DispStr
    mov ax, 900h
    mov es, ax
    mov bx, 100h
    mov ax, 1   
    mov cl, OSCodeSec
    call ReadSector
    jmp 900h:100h

repeat:
    hlt
    jmp repeat  

DispStr:
    mov ax, BootMessage
    mov bp, ax
    mov cx, 16
    mov ax, 1301h
    mov bx, 000ch
    mov dl, 0
    int 10h
    ret

ReadSector: ;ax 扇区号  cl 读取的扇区数 es:bx 内存位置
    push bp
    mov bp, sp
    sub esp, 2
    mov byte [bp - 2], cl
    push bx
    mov bl, [BPB_SecPerTrk]
    div bl
    inc ah
    mov cl, ah
    mov dh, al
    shr al, 1
    mov ch, al
    and dh, 1
    pop bx
    mov dl, [BS_DrvNum]
.GoOnReading:
    mov ah, 2
    mov al, byte [bp - 2]
    int 13h 
    jc .GoOnReading
    add esp, 2
    pop bp
    ret 

BootMessage: db "Hello, OS world!"
    times 510-($-$$) db 0
    dw 0xaa55
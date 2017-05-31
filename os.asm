
org 0100h
jmp main

StartSecOfFAT equ 6         ;从0开始编号
SizeOfDir     equ 14
SizeOfFAT     equ 9
BIOS_IO_Read  equ 02h
BIOS_IO_Write equ 03h

%macro print_string 2
    mov ah, 03h
    mov bh, [CurrentPage]
    int 10h
    mov ax, %1
    mov bp, ax
    mov ax, 1301h
    mov bl, 008h
    mov bh, [CurrentPage]
    mov cx, %2
    int 10h
    mov al, dh
    add dx, %2
    mov dh, al
    mov ah, 02h
    mov bh, [CurrentPage]
    int 10h

%endmacro


;%1:ah %2:dh %3:ch %4:cl %5:al %6:buff %7:jump_if_success
%macro BIOS_IO 7
    xor di, di
%%retry_IO:
    mov ah, %1
    mov dh, %2
    mov dl, 0
    mov ch, %3
    mov cl, %4
    mov al, %5
    mov bx, %6
    int 13h
    jnc %7
    inc di
    cmp di, 5
    je %%error_IO

    mov ah, 00h
    mov dl, 0
    int 13h
    jmp %%retry_IO
%%error_IO:
    print_string error_msg_io, error_msg_io_len


%endmacro

%macro seek_file_name 1

xor si, si
mov bx, oneSecBuff
%%seek_name_loop:
    %%compare_char_loop:
        xor di, di

        mov ah, [%1+di]
        cmp ah, [bx+di]

        jne %%not_match

        inc di
        cmp di, 11
        jne %%compare_char_loop

    mov dx, [bx+file.fstClust]

    jmp %%found

%%not_match:
    add bx, 32
    inc si
    cmp si, 16
    jl %%seek_name_loop
    mov al, 0
    jmp %%end

%%found:
    mov eax, [bx+file.fileSize]
    mov [fileSize], eax
    mov al, 1

%%end:

%endmacro



data:
command times 30 db 0
CurrentPage db 0
FAT times 512 db 0
oneSecBuff times 512 db 0
fileContent times 512 db 0
currentDirSec times 3 db 0
fileSize dd 0


msg:
prompt db 'CMD>'
promptLen equ $-prompt
error_msg_io db 'io error' 
error_msg_io_len equ $-error_msg_io
file_found_msg db 'file found'
file_found_msg_len equ $-file_found_msg
file_not_found_msg db 'file_not_found'
file_not_found_msg_len equ $-file_not_found_msg

fatContent:
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
res times 510-($-fatContent) db 0
magic dw 0xaa55


struc file
    .name       resb 12
    .attr       resb 1
    .resv       resb 10
    .wrtTime    resb 2
    .wrtDate    resb 2
    .fstClust   resb 2
    .fileSize   resb 4
endstruc






; ax 簇号
workout:
    add ax, StartSecOfFAT+SizeOfFAT+14
    mov bl, 18
    div bl
    inc ah
    mov cl, ah
    mov dh, al
    shr al, 1
    mov ch, al
    and dh, 1
    ret


move_to_new_line:
    mov ah, 03h                     ;获取光标状态
    mov bh, [CurrentPage]           ;dh 行号，dl 列号，bh 页号
    int 10h

    xor dl, dl
    inc dh                          ;换行
    cmp dh, 25
    jne not_go_to_next_page
    xor dh, dh
    mov bh, [CurrentPage]
    inc bh
    mov [CurrentPage], bh
    mov ah, 05h
    mov al, bh
    int 10h
not_go_to_next_page:
    mov ah, 02h                     ;设定光标位置
    mov bh, [CurrentPage]
    int 10h

    ret

find_file_name:
    seek_file_name command+2
    ret



exe_write:
    call find_file_name
    cmp al, 0
    je touch

touch:


open:
    

read_command:
    mov di, 30
    clear_command_buff:
        dec di
        mov byte [command+di], 0
        cmp di, 0
        jnz clear_command_buff
    get_key:
        mov ah, 00h
        int 16h
        mov [command+di], al
        inc di

        cmp al, 00dh                    ;读到回车开始执行
        je exe_return

        mov ah, 0eh                     ;打印最近输入的字符
        mov bh, [CurrentPage]
        mov bl, 07h
        mov cx, 1
        int 10h

        cmp di, 30                      ;若缓冲区满了，开始执行
        je exe_command
        jmp get_key

    exe_return:
        call move_to_new_line

    exe_command:

        print_string command, di
        
        call move_to_new_line
        ; mov al, byte [command]
        ; cmp al, 'h'
        ; je exe_help
        ; cmp al, 'f'
        ; je exe_format
        ; cmp al, 'o'
        ; je exe_open
        ; cmp al, 'r'
        ; je exe_read
        ; cmp al, 'w'
        ; je exe_write
        ; cmp al, 's'
        ; je exe_seek
        ; cmp al, 'c'
        ; je exe_close
        ; cmp al, 'm'
        ; je exe_mkidr
        ; cmp al, 'd'
        ; je exe_deldir
        ; cmp al, 'e'
        ; je exe_exist
        ; cmp al, 'q'
        ; je exe_quit

    ret

     
    

main:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov sp, 100h
    
    mov ax, 0007h           ;设定显示模式为文本模式
    int 10h
    
    ; mov ax, 0700h           ;清屏
    ; mov cx, 0000h
    ; mov dx, 5050h
    ; int 10h


    ; mov ah, 01h             ;光标复位至左上角
    ; mov cx, 0007h
    ; int 10h

    mov dh, 0
    mov ch, 0
    mov cl, 16
    mov byte [currentDirSec], dh
    mov byte [currentDirSec+1], ch
    mov byte [currentDirSec+2], cl
    BIOS_IO BIOS_IO_Read, dh, ch, cl, 1, oneSecBuff, mainloop
    

mainloop:
    print_string prompt, promptLen
    call read_command
    jmp mainloop

    







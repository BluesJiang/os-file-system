;------------
move_to_next_ch:
    push dx
    push ax
    push bx
    
    mov ah, 03h                     ;获取光标状态
    mov bh, 0                       ;dh 行号，bl 列号，bh 页号
    int 10h
    
    inc dl                          ;光标列向右移一格
    cmp dl, 80                      ;是否超过80行
    jne move_to_next_ch_non_return
    call move_to_new_line
    jmp move_to_next_ch_end
move_to_next_ch_non_return:
    mov ah, 02h                     ;设定光标位置
    int 10h
move_to_next_ch_end:
    pop bx
    pop ax
    pop dx
    ret
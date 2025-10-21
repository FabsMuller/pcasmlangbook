;ASCII Organ

        code    segment
        org     100h
        assume  cs:code

timer   equ     42h
speaker equ     61h

start:  call    getkey          ; store key pressed in AL
        cmp     al,1bh          ; escape?
        jne     skip
        int     20h
skip:   call    beep            ; if not escape, beep according to
        jmp     start           ; value in AL, and return

getkey: mov     ah,7            ; prepare for interrupt
        int     21h             ; execute DOS function 7
        ret			; return with key in AL

beep:   mov     bl,al           ; store key in BL
        mov     al,0b6h         ; prepare timer for
        out     timer+1,al      ; accepting new division
        mov     al,0            ; send 0 as LSB
        out     timer,al        ; of the new divisor
        mov     al,bl           ; and key value
        out     timer,al        ; like MSB
        mov     al,4fh          ; start sound by linking the
        out     speaker,al      ; speaker and timer
        mov     cx,0ffffh       ; pause
        rep     lodsw           ; while the note is played
        mov     al,4dh          ; stop by cutting the connection
        out     speaker,al      ; between speaker and timer
        mov     ah,2            ; prepare for DOS output function
        mov     dl,0eh          ; (out) character to send
        int     21h             ; symbol of the note to the screen
        ret

code    ends
        end     start

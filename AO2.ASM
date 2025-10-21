; ASCII Organ II (Version 2: bypasses DOS)

timer   equ     42h
speaker equ     61h
sponmsk equ     4fh
spofmsk equ     4ch
settim  equ     0b6h
termkey equ     1
keyport equ     60h

doscall macro   x
        mov     ah,x
        int     21h
        endm

pout    macro   x,y
        mov     al,y
        out     x,al
        endm

code    segment
        org     100h
        assume  cs:code

start:  jmp     begin           ; bypasses variable storage

;---- Variable storage ----

msg     db      'Attention: <ESC> to quit$'

oldvect dd      0               ; define double word (4 bytes)
                                ; for storage...
; Start of Program

begin:  mov     dx,offset msg
        doscall 9
        sub     ax,ax           ; establish addressing area
        mov     ds,ax           ; interupt vector
        mov     si,9*4          ; mov si,36
        mov     cx,4
        mov     di,offset oldvect
        cld                     ; in precaution
        rep     movsb
        push    cs              ; set DS = CS
        pop     ds
        mov     dx,offset kbdintarget
        mov     al,9             ; make interrupt 9 point
        doscall 25h              ; to kbdintarget
        mov     dx,offset lastin + 5
        int     27h             ; end, make resident

; execute with each stroke of a key

kbdintarget:
        sti                     ; timer interrupt
        push    ax              ; save ax
        in      al,keyport      ; read key 
        cmp     al,80h          ; key > 80h?
        jnb     exit            ; if yes, jump... 
        cmp     al,termkey      ; <esc> key?
        je      lastime         ; if yes, jump...
        push    ax              ; store key
        pout    timer+1,settim
        sub     al,al           ; let AL = 0
        out     timer,al        ; send divisor, LSB first
        pop     ax              ; MSB of divisor=value of key
        out     timer,al        ; timer controls tone 
        pout    speaker,sponmsk  ; play note

        mov     ax,2000h        ; wait loop
repeat: dec     ax
        jne     repeat

        pout    speaker,spofmsk
        jmp     exit

lastime:                        ; resume keyboard vector
        push    ds              ; store all registers in stack
        push    es              ; 
        push    si              ; 
        push    di
        push    cx
        push    cs
        pop     ds              ; let DS = CS
        sub     ax,ax           ; establish addressing area
        mov     es,ax           ; interrupt vector
        mov     di,9*4          ; move program storage
        mov     si,offset oldvect ; into int. vector area
        mov     cx,4
        cld                    
        rep	movsb		; return former keyboard interrupt
        pop     cx		; vector and registers
        pop     di              ; in order opposite of push...
        pop     si 
        pop     es     
        pop     ds 

exit:   pop     ax
lastin: jmp     [oldvect]       ; jump former rout. keyb. int.

code    ends
        end     start

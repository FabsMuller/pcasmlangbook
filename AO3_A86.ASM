; ASCII Organ III

timer   equ     42h
speaker equ     61h
sponmsk equ     4fh
spofmsk equ     4ch
settim  equ     0b6h
keyport equ     60h

doscall macro                ; the definition and parameters have 
        mov     ah,#1          ; been changed to work with A86
        int     21h               ; see A12.DOC for details.
#em

pout    macro                   ; the definition and parameters have
        mov     al,#2            ; been changed to work with A86.
        out     #1,al
#em

code    segment
        org     100h
        assume  cs:code,ds:code

start:  jmp     begin           ; bypass variable storage

;----- Music data -----

song    db      17,4,16,4,15,4,16,4,17,4,17,4,17,8
        db      16,4,16,4,16,8,17,4,19,4,19,8
        db      17,4,16,4,15,4,16,4,17,4,17,4,17,4
        db      17,4,16,4,16,4,17,4,16,4,15,4

;----- Timer divisor data (Pitch) ------

;               C-1  D-2  E-3  F-4  G-5  A-6  B-7  C-8  D-9  E-10 F-11
divsors dw 0000,9121,8126,7239,6833,6088,5423,4832,4560,4063,3620,3417
;               G-12 A-13 B-14 C-15 D-16 E-17 F-18 G-19 A-20 B-21 C-22
        dw      3044,2712,2416,2280,2031,1810,1708,1522,1356,1208,1140
;               D-23 E-24 F-25 G-26 A-27 B-28
        dw      1016, 905, 854, 761, 678, 604

;----- Variables ------

notecnt dw      0                               ; counter for notes played
beatcnt dw      0                               ; counter for beats
tbtn    dw      0                               ; n beats

;----- Initialize ------

begin:  mov     al, [song+1]                    ; length of first note
        cbw
        mov     tbtn,ax
        call    playnot                         ; begin first note
        mov     dx,offset target1c
        mov     al,1ch                          ; get timer interrupt
        doscall 25h
        mov     dx,offset lbyte+1
        int     27h                             ; end, make resident

;----- target for interrupt 1Ch ------

target1c:
        push    cs                      ; synchronize execution time
        pop     ds     
        inc     beatcnt 
        mov     ax,tbtn     
        cmp     ax,beatcnt              ; end of note?
        je      in2                     ; yes, jump next note
        iret                            ; no...
in2:    cmp     notecnt,(offset divsors - offset song) / 2
        jne     in3                     ; if not equal continue
        mov     byte ptr target1c,0cfh
        iret

; to play following note

in3:    push    si                      ; store ds,dx,ax
        inc     notecnt                 ; advance to next note
        mov     beatcnt,0               ; reset beatcount=0
        mov     si,notecnt
        shl     si,1                    ; 2 elements for each note
        mov     al,[si+offset song+1]   ; duration of the note
        cbw
        mov     tbtn,ax
        call    playnot
        pop     si
        iret

playnot: mov     si,notecnt
        shl     si,1
        mov     al,[si+offset song]     ; AL = number of note
        or      al,al                   ; force pointers
        jnz     pn1                     ; note 0 is a pause
        pout    speaker,spofmsk
        ret
pn1:    cbw                             ; AH in one byte
        mov     si,ax
        shl     si,1                    ; divisor table
        pout    timer+1,settim
        mov     ax,[si+offset divsors]
        out     timer,al
        mov     al,ah
        out     timer,al
        pout    speaker,sponmsk
lbyte:  ret

code    ends
        end     start

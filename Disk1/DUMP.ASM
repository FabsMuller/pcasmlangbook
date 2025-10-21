; DUMP.ASM: Dump Utility

; ------Macros--------------------------

doscall macro   x
        mov     ah,x
        int     21h
        endm

outchar macro   x
        mov     dl,x
        doscall 2
        endm

code    segment
        org     100h
        assume  cs:code,ds:code
start:  jmp     begin

; ------Variables----------------------

fcount  dw      0
eofflag db      0
fnfmsg  db      'File not Found$'
hexchar db      '0123456789ABCDEF'

; ----- main loop -------------

begin:  mov     dx,5ch          ; fcb prepared by DOS
        doscall 0fh             ; open file
        cmp     al,0ffh         ; if ffh then 
        jne     d1              ; file not found
        mov     dx,offset fnfmsg
        doscall 9               ; display message
        jmp     exit            ; end

; if file is present begin by reading 
; data in DTA at offset 80h

d1:     mov     dx,5ch
        doscall 14h             ; read data block (128 bytes)
        cmp     al,1            ; if end of file
        je      exit            ; end
        cmp     al,3            ; if partial block
        jne     d2              ; display file and end
        inc     eofflag         
d2:     call    outrec          ; display 128 bytes of DTA
        cmp     eofflag,1       ; EOF?
        jne     d1              ; if not, jump to top
exit:   int     20h

outrec  proc    near
        mov     bp,80h          ; bp points to beginning of DTA
or1:    call    outcnt
        call    outhex
        call    outasci
        outchar 13
        outchar 10
        add     bp,16           ; position base pointer
        add     fcount,16       ; and file counter
        cmp     bp,100h         ; finished after 128 bytes 
        jne     or1
        outchar 13
        outchar 10
        ret
outrec  endp

outcnt  proc    near		; outcnt displays the memory address
        mov     ax,fcount       ; in hex as MSB LSB:
        mov     al,ah           ; switch for display
        call    outbyte 
        mov     ax,fcount  
        call    outbyte
        outchar ':'             ; separate with :
        outchar ' '
        ret
outcnt  endp

outhex  proc    near		; outhex displays a hex dump
        mov     si,0  
oh1:    mov     al,[bp+si]      ; read byte
        call    outbyte         ; and display
        outchar ' '
        inc     si
        cmp     si,8            ; add extra space between 
        jne     oh2             ; bytes 7 and 8 for clarity
        outchar ' '
oh2:    cmp     si,16           ; if si = 16 then return
        jne     oh1
        outchar ' '             ; separate with a space
        ret
outhex  endp

outasci proc    near		; outasci displays the ASCII characters
        mov     si,0            ; prepare oa1 loop
oa1:    mov     dl,[bp+si]      ; read character
        and     dl,7fh          ; set MSB = 0
        cmp     dl,20h          ; if char can be printed then 
        jae     oa2             ; jump to oa2
        mov     dl,'.'		; else print .
oa2:    doscall 2               ; print character
        inc     si              
        cmp     si,16		; when performed 16 times, end
        jne     oa1
        ret
outasci endp

outbyte proc    near		; output char. to screen
        mov     bx,offset hexchar
        push    ax 
        and     al,0f0h    
        mov     cl,4     
        rol     al,cl  
        xlat   			; translate into hex
        mov     dl,al  
        doscall 2		; display
        pop     ax   
        and     al,0fh
        xlat			; translate into hex
        mov     dl,al
        doscall 2		; display
        ret
outbyte endp

code    ends
        end     start

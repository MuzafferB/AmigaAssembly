
; Lesson 8h2.s        8*8 scrolltext routine, which only uses bplcon1
;            to scroll. Original by Lorenzo Di Gaetano.

SECTION    SysInfo,CODE

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

START:

;    Point the bitplanes in the copperlist

MOVE.L    #screen,d0    ; put the bitplane address in d0
LEA    BPLPOINTERS,A1    ; pointers in COPPERLIST
move.w    d0,6(a1)    ; copy the LOW word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)	; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)		; Disable AGA

clr.w    ContaScroll    ; Reset the scroll counter
bsr.w    Print        ; Print the first time

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
Beq.S    Waity2

bsr.s    Scroll        ; Routine scrolls the text to the left
; with bplcon1, and every 16 pixels it reprints
; 2 characters (8*2=16 pixels) further on
; resetting bplcon1 -> SCROLLING!!!

btst	#6,$bfe001	; mouse premuto?
bne.s	mouse
rts

*****************************************************************************
; Routine that decides whether to scroll with bplcon1, or reprint the entire text
; 2 characters (16 pixels) further to the left (this 1 time every 16, of course)
*****************************************************************************

Scroll:
tst.b    Scrolling    ; Have we scrolled as far as possible with bplcon1?
bne.s    ThenAdd    ; If not, continue subtracting

; Otherwise, start again from $FF and reprint the text 2 characters forward!

addq.w    #2,ContaScroll    ; 2 characters forward -> 16 pixels forward
move.b    #$FF,Scrolling    ; Reset bplcon1
bsr.s    Print        ; and reprint the ScrollText 2 characters forward
rts            ; forward, i.e. 2*8=16 pixels forward.

ThenAdd:
sub.b    #$11,Scrolling    ; 1 pixel to the left with bplcon1
rts

*****************************************************************************
; 8*8 print routine modified for scrolling
*****************************************************************************

Print:
lea    Screen+(42*192),a0    ; Address where to print
lea    ScrollText(PC),a1    ; Scrolltext address (ascii)
moveq    #42-1,d2		; Number of characters to print
moveq    #0,d0
move.w    ContaScroll(PC),d0    ; Offset from the start of ScrollText
add.l    d0,a1            ; Find the character in the scrolltext
Print line:
sub.l    a2,a2        ; reset a2
moveq    #0,d1
move.b    (a1)+,d1
cmp.b    #$ff,d1        ; ScrollText end flag?
bne.s    DoNotRestart    ; If not yet, continue
clr.w    ScrollCounter    ; Otherwise, restart from the beginning of the ScrollText
Don't Restart:
sub.b    #$20,d1
lsl.w    #3,d1        ; multiply by 8
move.l    d1,a2
add.l    #Fonts,a2    ; find the character in the font
move.b    (a2)+,(a0)
move.b    (a2)+,42(a0)	; 42 to compensate for dfstart and then go
move.b    (a2)+,42*2(a0)    ; beyond the screen
move.b    (a2)+,42*3(a0)
move.b    (a2)+,42*4(a0)
move.b    (a2)+,42*5(a0)
move.b    (a2)+,42*6(a0)
move.b    (a2)+,42*7(a0)
addq.w    #1,a0        ; next character
dbra    d2,Printriga
rts

ContaScroll:
dc.w    0



ScrollText:
dc.b    ‘ ’
dc.b    ‘THIS TEXT IS MOVED WITH THE BPLCON1 REGISTER:’
DC.B    ‘ AFTER MOVING IT BY 16 PIXELS, IT IS RESET,’
DC.B    ‘ AND INSTEAD OF POINTING TO THE NEXT WORD OF THE IMAGE, THE TE’
DC.B	‘STO IS REPRINTED ON THE SCREEN 2 LETTERS LATER.’
DC.B    ‘THE AUTHOR, LORENZO DI GAETANO, (The Amiga Dj) MADE THIS’
dc.b    ‘ ROUTINE WITH ONLY THE KNOWLEDGE OF DISK 1 OF THE COURSE.’
dc.b    "... GO AMIGA!!! ‘
DC.B    ’
dc.b    $FF    ; End scrolltext flag

even

; Font 8x8

Fonts:
incbin    ‘nice.fnt’

;****************************************************************************

SECTION    GRAPHIC,DATA_C


COPPERLIST:
dc.w $08e,$2c81 ; Here are the standard registers
dc.w $090,$2cc1
dc.w $092,$0038
dc.w $094,$00d0
dc.w    $102,0
dc.w $104,0
dc.w $108,2            ;2 to skip the empty image
dc.w $10a,2

bplpointers:
dc.w $e0,$0000,$e2,$0000 ; Pointers to bitplanes

dc.w $100,%0001001000000000 ; Bplcon0 2 colours

dc.w    $180,$000
dc.w    $182,$888

; Any image could go here...

dc.w    $eb07,$fffe    ; Here begins the copperlist for 
; scrolling.
dc.w $092,$0030    ; To hide the scroll error
dc.w $094,$00d0

dc.w $104,0
dc.w $108,0
dc.w $10a,0
dc.w $102        ; bplcon1
dc.b	$00
Scrolling:
dc.b    $FF
dc.w    $182,$200
dc.w    $ec07,$FFFe
dc.w    $182,$400
dc.w    $ed07,$fffe
dc.w    $182,$600
dc.w $ee07,$fffe
dc.w $182,$800
dc.w $ef07,$fffe
dc.w $182,$a00
dc.w $f007,$fffe
dc.w $182,$d00
dc.w    $f107,$fffe
dc.w    $182,$a00
dc.w    $f207,$fffe
dc.w    $182,$800
dc.w    $f307,$fffe

dc.w    $182,$000    ; Copper effects...
dc.w    $180,$001
dc.w    $108,-84
dc.w    $10a,-84
dc.w    $f4ff,$fffe
dc.w    $180,$003
dc.w    $f5ff,$fffe
dc.w    $180,$005
dc.w    $f6ff,$fffe
dc.w    $180,$007
dc.w    $f7ff,$fffe
dc.w    $180,$009
dc.w    $f8ff,$fffe
dc.w    $180,$00b
dc.w    $f8ff,$fffe
dc.w    $180,$00c
dc.w    $f9ff,$fffe
dc.w    $180,$00f
dc.w    $faff,$fffe
dc.w    $180,$00f
dc.w    $fbff,$fffe
dc.w    $180,$000
dc.w    $108,0
dc.w    $10a,0
dc.w    $ffff,$fffe    ; End copperlist

;****************************************************************************

Section	Bitplanozzo,bss_C

Schermo:
ds.b	42*256

end

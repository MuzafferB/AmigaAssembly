
; Lesson9c3.s    BLITTATA with negative module.
;        Left key to execute the blit, right to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:
;    Point to the ‘empty’ PIC

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

Wait:
btst    #6,$bfe001    ; wait for the left mouse button to be pressed
bne.s    Wait

btst    #6,2(a5) ; dmaconr
WBlit:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit
;     __
;     /\ \
;     / \ \
;     / /\ \ \
;     / / /\ \ \
;     / / /__\_\ \
;    / / /________\
;    \/___________/        ; the following 2 registers will be explained
; below:

move.w    #$ffff,$44(a5)	; bltafwm - channel A mask, first word
move.w    #$ffff,$46(a5)    ; bltalwm - channel A mask, second word

move.w    #$09f0,$40(a5)    ; bltcon0 - channels A and D enabled, 
; MINTERMS=$f0, i.e. copy from A to D

move.w    #$0000,$42(a5)        ; bltcon1 - we will explain this later

move.w    #2*(20-8),$66(a5)    ; BLTDMOD - as usual.

move.w    #-16,$64(a5)        ; BLTAMOD - the figure is 8 words wide
; (16 bytes): to return to the beginning
; we put the negative module.

move.l    #random_figure,$50(a5)    ; bltapt - source figure address

; The destination address depends on the X,Y position where we want
; to draw the first pixel of the figure. The rules of the lesson apply
; In this case, X=32 and Y=4.

move.l    #bitplane+(4*20+32/16)*2,$54(a5)    ; bltdpt - dest. ind.
move.w    #64*10+8,$58(a5)        ; bltsize - height 10 lines,
; width 8 words.

mouse:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

rts


;*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200    ; bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;*****************************************************************************

; This is the ‘figure’ that is copied into the BITPLANE with a bleat:

Random_figure:
dc.w $1111,$1010,$2044,$235a
dc.w $18f0,$97ff,$ca54,$90a2


SECTION PLANEVUOTO,BSS_C

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

;*****************************************************************************

In this example, we have a single-line figure that we need to copy
starting from a certain line on the screen, 10 times, each time moving down
one line. Of course, we could simply do a loop of 10 blits,
changing the destination address each time. However, it is possible to do this with
a single blit by setting a negative value to the source module.
As you know, the value of the modulus is added to the address contained
in the pointer register each time the blitter finishes blitting a line.
Normally, a positive value is placed in the modulus, which allows the blitter
to ‘skip’ words that do not belong to the rectangle, moving on to the next line.
 However, if the modulus has a negative value, it will ‘go back’
the address contained in the pointer register. In particular, if the blitten
is L words wide, blitting a line will increase the value contained in the pointer
by 2*L (because the pointer counts bytes, and 1 word = 2 bytes).
If we put the value -2*L in the module, we will return the pointer
exactly to the beginning of the line. In this example, we do just that
with the source, rereading the same line each time. For the destination,
 however, we behave normally, and therefore the 10 lines are written
one below the other.
If you remember, we achieved a similar effect with the bitplane modules,
setting them to -40, obtaining an infinite ‘lengthening’ of the first line,
but only at the display level. In this case, with the blitter, it is
actually in MEMORY that we rewrite the same line several times.


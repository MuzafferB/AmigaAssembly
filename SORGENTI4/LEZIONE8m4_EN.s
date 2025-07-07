
; Lesson8m4.s - Point printing routine (plot), used in a loop to
;         calculate y=a*x*x, i.e. parabolas

Section    dotta,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup1.s’    ; with this include I save myself from
; rewriting it every time!
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper and bitplane DMA enabled
;         -----a-bcdefghij


START:
;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

lea    bitplane,a0    ; Address of the bitplane where to print

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L	4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.s    CalcolaParabola    ; y=a*x*x

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
Finished:
btst    #6,$bfe001    ; mouse pressed?
bne.s    Finished
rts            ; exit

;     ______
;     / \
;     / oo \
;     \___()___/
;     / ¬\
;     \________/
;     / ¬\
;     __\________/__
;    (_____/ \_____)CNT

;    Y=a*x*x, coeff*d0*d0=d1

CalculateParabola:
Addq.W    #1,Miox        ; Increment X
move.w    Miox(PC),d1
Mulu.w    d1,d1        ; x*x
Mulu.w    Coeff(PC),d1    ; y=a*x*x
lsr.w    #8,d1		; divide Y by 256 to ‘widen’

cmp.w    #256,MioY    ; are we below the screen?
bhi.s    Restart        ; if so, we only have 1 screen!!! let's start again
cmp.w    #319-160,MioX    ; are we at the far right of the screen?
ble.s    NotFinished
Restart:
addq.w    #1,Coeff    ; Add 1 to the coefficient of the parabola
cmp.w    #3,Coeff    ; Have we already done 2 parabolas?
beq.s    Finished        ; If so, let's get out!
move.w    #-160,Miox    ; And restart from X= -160 for the new parabola
rts            ; Nothing to plot this time.

Unfinished:
move.w    d1,MioY

; Let's plot the point:

move.w    Miox(PC),d0    ; X coordinate
add.w    #160,d0        ; move forward by 160, since I calculate
; from -160 to +160, which I have to normalise to
; coordinates 0 to 320... this way I have
; moved the parabola to the right.
move.w    Mioy(PC),d1    ; Y coordinate
bsr.s    plotPIX        ; print the point at coord. X=d0, Y=d1

rts


MioX:
dc.w    -160    ; start from -160 to ‘centre’ the parabola.
MioY:
dc.w    0

Coeff:
dc.w    1

*****************************************************************************
;            Point plotting routine (dots)
*****************************************************************************

;    PlotPIX input parameters:
;
;    a0 = Destination bitplane address
;    d0.w = X coordinate (0-319)
;    d1.w = Y coordinate (0-255)

LargSchermo    equ    40    ; Screen width in bytes.

PlotPIX:
move.w    d0,d2        ; Copy the X coordinate to d2
lsr.w    #3,d0        ; Meanwhile, find the horizontal offset
; by dividing the X coordinate by 8.
mulu.w    #screen width,d1
add.w    d1,d0        ; Add vertical offset to horizontal offset

and.w    #%111,d2    ; Select only the first 3 bits of X
; (actually, this would be the remainder of the division
; by 8, done previously)
not.w    d2

bset.b    d2,(a0,d0.w)    ; Sets bit d2 of the byte d0 bytes away
; from the start of the screen.
rts

*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0	; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,$24    ; BplCon2 - All sprites above the bitplanes
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$1af    ; colour1 - TEXT

dc.w    $FFFF,$FFFE    ; End of copperlist


*****************************************************************************

SECTION	MIOPLANE,BSS_C

BITPLANE:
ds.b	40*256	; un bitplane lowres 320x256

end

The most important change here is that we have ‘moved’ the parabola to the
right, also ‘revealing’ the negative part that rises:

**
*     *
*     *
*     0    *
ZERO

As you can see from the diagram, with X less than zero, the curve is reversed,
or specular, well... So, to see it, just start with an x of -160 and
go up to +160. Then we ‘move’ everything to the right by 160, centring the
parabola, with a simple ADD.W #160,d0. -160 becomes 0 and +160 becomes 320.


In this example, we have also inserted a coefficient for which
we multiply x*x, obtaining two parabolas, one “wider”
than the other.

A final note: to make the parabola more “visible” and less dotted,
the Y coordinate is divided by 256 with an LSR #8.

lsr.w    #8,d1        ; divide Y by 256 to ‘widen’

As you know, you can divide or multiply by powers of 2 using lsr and
lsl, even if it is not exactly ‘equal’ to a MULU or DIVU. In this case,
 however, it works well enough...

P.S: From this listing onwards, the PlotPIX routine will be without the mega comments
from the previous listings... there's no point in lengthening the source code like that!

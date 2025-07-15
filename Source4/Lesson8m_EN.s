
; Lesson 8m.s - Point printing routine (plot), used in a loop to
;        draw a line.

Section    dotta,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup1.s’    ; with this include I don't have to
; rewrite it every time!
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper and bitplane DMA enabled
;         -----a-bcdefghij

Coeff    equ    1    ; Angular coefficient, m

START:
;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

lea    bitplane,a0    ; Address of the bitplane where to print

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L	#$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

;    Y=m*x, or rather m*x=y, i.e. Coeff*d0=d1

Addq.W    #1,Miox        ; Increment X
move.w    Miox(PC),d1
Mulu.w    #Coeff,d1    ; Y=m*x
cmp.w    #255,d1        ; are we at the bottom of the screen?
bhi.s    Finished
move.w    Miox(PC),d0    ; X

bsr.s    plotPIX        ; print the point at coord. X=d0, Y=d1

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
Finished:
btst    #6,$bfe001    ; mouse pressed?
bne.s    Finished
rts            ; exit

MioX:
dc.w    0

*****************************************************************************
;            Point (dots) plot routine
*****************************************************************************

;    PlotPIX input parameters:
;
;	a0 = Destination bitplane address
;    d0.w = X coordinate (0-319)
;    d1.w = Y coordinate (0-255)

LargSchermo    equ    40    ; Screen width in bytes.

;     _____
;     / ¯¬~°\
;     _/ \ / \_
;     (/_(¯\ /¯)_\)
;     / / ¯° °¯ \ \
;    / __(___)__ \
;    \ (l_T_|_T_|) /
;     \ \_T_T_T_/ /
;     \_ ¯ ¯ ¯ _/ xCz
;     `-------'

PlotPIX:
move.w    d0,d2        ; Copy the X coordinate to d2


; Find the horizontal offset, i.e. the X

lsr.w    #3,d0        ; Meanwhile, find the horizontal offset,
; dividing the X coordinate by 8. Since the
; screen is made up of bits, we know that a
; horizontal line is 320 pixels wide, i.e.
; 320/8=40 bytes. Since the X coordinate
; ranges from 0 to 320, i.e. in bits, we must
; convert it to bytes by dividing it by 8.
; This gives us the byte within which
; to set our bit.

; Now we find the vertical offset, i.e. the Y:

mulu.w    #screen width,d1    ; multiply the width of a line by the
; number of lines, finding the
; vertical offset from the start of the screen

; Finally, we find the offset from the start of the screen of the byte where the
; point (i.e. the bit), which we will set with the BSET instruction:

add.w    d1,d0    ; Adds the vertical offset to the horizontal offset

; Now we have in d0 the offset, in bytes, from the beginning of the screen to find
; the byte where the point to be set is located. We then have to choose which
; of the 8 bits of the byte to set.

; Now we find which bit of the byte we need to set:

and.w    #%111,d2    ; Select only the first 3 bits of X, i.e.
; the offset in the byte,
; obtaining in d2 the bit to be set
; (actually it would be the remainder of the division
; by 8, done previously)

not.w    d2        ; appropriately noted

; Now we have in d0 the offset from the beginning of the screen to find the byte,
; in d2 the number of bits to set within that bit, and in a0
; the address of the bitplane. With a single instruction we can set the bit:

bset.b    d2,(a0,d0.w)    ; Sets bit d2 of the byte d0 bytes away
; from the start of the screen.
rts            ; Exit.

*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
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

SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    40*256    ; a lowres 320x256 bitplane

end

We use a loop to draw a line. We know that the ‘formula’ for a line is
y=m*x, where m is a number, called the angular coefficient, which determines, among other things, the slope of the line itself. For those who are not familiar with mathematics, here is a brief explanation of what happens: if we have X = 0, we obtain Y by multiplying X by m, which is defined here with an EQU at the beginning
of the listing.
Let's assume that Coeff = 1: X = 0
-> Y=Coeff*X, i.e. 1*0, i.e. 0
Therefore, X=0 and Y=0 
Let's assume that Coeff = 1:

X = 0    -> Y=Coeff*X, i.e. 1*0, i.e. 0

Therefore, X=0 and Y=0

In the loop, we increment X by 1. Here's what happens in the next loop:

X = 1    -> Y= 1*1, i.e. 1

then...

X = 2    -> Y=2

In short, Y is always equal to X, because we multiply it by Coeff=1.
This results in the following line:

11
22
33
44
55
66
77
88
...

Is it clear why it is at 45 degrees? Try changing the Coeff by setting it to
2, for example. In this case, here is what happens:

X = 0    -> Y=Coeff*X, i.e. 2*0, i.e. 0
X = 1    -> Y= 2*1, i.e. 2
X = 2    -> Y= 2*2, i.e. 4
X = 3    -> Y= 2*3, i.e. 6
X = 4    -> Y= 2*4, i.e. 8
X = 5    -> Y= 2*5, i.e. 10

The resulting line will be:

12

24

36

48

510


That is, further to the left, and not continuous. There are ‘gaps’ between one point and
another because we are only working with whole numbers, and values, for example,
between 2 and 3 leave a ‘void’. We will see later that there are many ways to
use numbers in ‘emulated floating point’ even without math coprocessors,
for example to perform calculations in 3D.

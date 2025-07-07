
; Lesson 8n.s - Point printing routine (plot), optimised by pre-calculating
;        multiples of 40 in a table, removing the multiplication
;        in the PlotPix routine, which takes the correct value from the
;        table each time.

Section    dotta,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup1.s’    ; with this include I save myself from
; rewriting it every time!
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000	; copper and bitplane DMA enabled
;         -----a-bcdefghij

LargSchermo    equ    40    ; Screen width in bytes.

START:
;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

; PRECALCULATE A TABLE WITH MULTIPLES OF 40, i.e. the screen width
; to avoid multiplying for each plot.

lea    MulTab,a0    ; Address space of 256 words where to write
; the multiples of 40...
moveq    #0,d0        ; Let's start from 0...
move.w    #256-1,d7    ; Number of multiples of 40 needed
PreCalcLoop
move.w    d0,(a0)+    ; Save the current multiple
add.w    #LargSchermo,d0    ; Add screen width, next multiple
dbra    d7,PreCalcLoop    ; Create the entire MulTab

; Point to the copy...

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Let's start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

move.w    #160,d0        ; X coordinate
move.w    #128,d1		; Y coordinate
lea    bitplane,a0    ; Address of the bitplane where to print in a0
lea    MulTab,a1    ; Address of the table with the multiples of the
; screen width precalculated in a1

bsr.s    PlotPIXP    ; prints the point at coord. X=d0, Y=d1

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts            ; exit

*****************************************************************************
; Optimised dot plotting routine
*****************************************************************************

;    PlotPIXP input parameters:
;
;    a0 = Destination bitplane address
;    a1 = Address of the table with precalculated multiples of 40
;    d0.w = X coordinate (0-319)
;    d1.w = Y coordinate (0-255)

;     ________________
;     _____/ \_____ __ _
;    | _/ \_ || || |
;    | \ ______ ______ / || || |
;    | _\ \ ___\ /___ / /_ || || |
;    | /¯ \/ ` ` \/ ¯\ || || |
;    | ¯\_ /| |\ _/¯ || || |
;	| \ ¯¯ ¯¯ /zO! || || |
;    | \_.--.--.--._/ || || |
;    ` `| | | |` || || |
;    __/\__ | | | | || || |
;    \ +O / | | | | || || |
;    / --_\ | | | | || || |
;    ¯¯\/_ ____| | | |_________||__||_|
;     `--`--`--`

PlotPIXP:
move.w    d0,d2        ; Copy the X coordinate to d2
lsr.w    #3,d0        ; Meanwhile, find the horizontal offset
; by dividing the X coordinate by 8.

; ** START OF MODIFICATION: here are the two original instructions:
;
;    mulu.w    #largschermo,d1
;    add.w    d1,d0        ; Add the vertical offset to the horizontal one
;
; and those without MULU:

; Now we find the vertical offset, i.e. the Y, taking the correct value
; precalculated from the Multab table, whose address is in a1

add.w    d1,d1        ; We multiply the Y by 2, finding the offset
; from the table of multiples, in fact each
; multiple is a word, i.e. 2 bytes. Now, if
; for example, the coordinate was 0, we take
; the first value in the table, which is zero.
; If it is 3, then we take the third value
; in the table, which is, however, in the sixth
; byte, since we have to skip 2 bytes, 1
; word, for each value in the table.
add.w    (a1,d1.w),d0    ; Add the correct vertical offset,
; taken from the table, to the horizontal offset

; ** END OF MODIFICATION

and.w    #%111,d2    ; Select only the first 3 bits of X (rest)
not.w    d2

bset.b    d2,(a0,d0.w)    ; Set bit d2 of the byte distant d0 bytes
; from the beginning of the screen.
rts

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

SECTION	MIOPLANE,BSS_C

BITPLANE:
ds.b	40*256	; un bitplane lowres 320x256

; Table containing the precalculated multiples of the screen width
; to eliminate multiplication in the PlotPIX routine, increasing its
; speed.

SECTION    Precalc,bss

MulTab:
ds.w    256

end

With this listing, we will give a brief introduction to the lesson on
optimisation. In fact, we will ‘TABLE’ a multiplication. This operation is
very common in the code of the fastest demos or in 3D games.
Our pixel printing routine works very well, but it contains a
VERY SLOW multiplication. We absolutely must remove it. Since it is not a 
multiplication by a power of 2, we cannot replace it with an LSL as
we cleverly did in the print routine in Lesson8b.s.
But the ways of coding are endless. Consider the situation we have:

mulu.w    #largschermo,d1
add.w    d1,d0        ; Add vertical offset to horizontal

Screen width in this case is 40. In d1 we have a different value each time,
depending on Y, but we know that it can range from 0 to 255 at most.
So there are 256 possible results, depending on which of the 256
possible values of Y, i.e. d1. These 256 results, if we give
an increasing number from 0 to 245 each time, would be:

0,40,80,120,160,200    i.e.    40*0.40*1.40*2.40*3.40*4....

Let's imagine that we ‘prepare’ all these 256 possible results in a
previously cleared space:

MulTab:
ds.w    256

To create the table of multiples of 40, a very simple loop is sufficient:

lea    MulTab,a0    ; Address of the 256-word space where to write
; the multiples of 40...
moveq    #0,d0        ; Let's start from 0...
move.w    #256-1,d7    ; Number of multiples of 40 needed
PreCalcLoop
move.w    d0,(a0)+    ; Save the current multiple
add.w	#LargSchermo,d0    ; add larghschermo, next multiple
dbra    d7,PreCalcLoop    ; Create the entire MulTab

Now we have the table with the ‘results’ ready. But how do we ‘take’
the right result from the table every time? At the input we have the
Y coordinate, i.e. a number from 0 to 255. If Y is zero, just take the first value
of the table, i.e. the word $0000. If, on the other hand, y=1, we must take the
second value of the table, which is 2 bytes from its beginning,
given that its values are words. Similarly, if we wanted to take the
right result for coord. Y = 50, the result would be the fiftieth
word in the table, i.e. 100 bytes away. Doesn't all this
suggest the solution? To calculate the offset, i.e. the distance from the beginning
of the table, just multiply Y by 2! And since you can multiply
by 2 with a:

add.w    d1,d1

We still don't need to multiply. Now in d1 we have the offset from the beginning
of the table; we need to “take” it and add it to d0. This can be done
with a single operation:

add.w    (a1,d1.w),d0    ; We add the correct vertical offset,
; taken from the table, to the horizontal offset

Having the address of the MulTab table in a1.

We will find this ‘tabulation’ system more and more often in listings
that perform many calculations.

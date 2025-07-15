
; Lesson 8g.s - Parallax ‘floor’ test - 10 levels.

*****************************************************************************
*    PARALLAX 0.5    Copyright © 1994 by Federico ‘GONZO’ Stango     *
*			Modified by Fabio Ciucci             *
*****************************************************************************

SECTION MAINPROGRAM,CODE ; Code section: anywhere in memory

; Include ‘DaWorkBench.s’ ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %100000111000000    ; only copper and bitplane DMA
;         -----a-bcdefghij

;    a: Blitter Nasty
;    b: Bitplane DMA     (If not set, sprites will also disappear)
;	c: Copper DMA
;    d: Blitter DMA
;    e: Sprite DMA
;    f: Disk DMA
;    g-j: Audio 3-0 DMA

START:
move.l    #PARALLAXPIC,d0        ; Load Pic address in d0
lea    BPLPointers,a1		; Address of pointers to planes
moveq    #5-1,d1            ; NumPiani-1 for DBRA
move.w    #40*56,d2        ; Bit per plane in d2
bsr.w    PointBpls        ; Call the PointBpls subroutine

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #MyCopList,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

MainLoop:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.s    ParallaxFX        ; Jump to the ‘Parallax’ subroutine

MOVE.L    #$1ff00,d1    ; bits for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001        ; LMB pressed?
bne.s    MainLoop        ; If ‘NO’, restart
rts

******************************************************************************
*             Part dedicated to subroutines         *
******************************************************************************

; This is the parallax routine. It works in a very simple way,
; in fact, it only modifies the values of the 10 BPLCON1 ($dff102) placed one
; below the other with WAIT in the ‘floor’ area. Well, we have already
; seen in previous lessons how to make a figure ‘waver’
; using a copperlist with many BPLCON1 ($dff102), which can
; move the screen to the right by a maximum of 15 pixels, with the value
; $FF, while with $00 the movement is zero. Now, if instead of waving a
; figure, we want to make it look like it scrolls infinitely, the problem
; that arises is that we can only scroll the figure by a maximum of 15
; pixels, and 15 pixels are not infinite. We could also make a figure one kilometre wide
; in memory and scroll using bplpointers, but
; that would not be economical. So we need to create a scroll that looks infinite,
; to the right, with a figure only 320 pixels wide. The “trick” is this: if
; the figure in question is made up of equal “blocks” 16 pixels wide each
; we can trick the eye by hiding the fact that we are only moving 15
pixels and then “start again” from zero. In fact, all you need is a “tile” a certain number of pixels wide, for example 16, repeated across the entire screen, to simulate
continuous scrolling. All you have to do is move everything one pixel at a time to the right until the last “tile” on the right has left the edge and “entered” it again.
continuous scrolling. All you have to do is move everything one pixel at a time
to the right until the last “tile” on the right has left the
edge and a whole one has “entered” from the left edge: instead of jumping
; at the sixteenth pixel, which is impossible due to the BPLCON1 limitation,
; just ‘move back’ 15 pixels, start from zero, and the situation
; will be the same as if you had moved one
; pixel forward: the last tile on the right would have disappeared completely
; and the first one on the left would have ‘entered’ completely. To make levels
; that scroll at different speeds, just make sure that each of these
; levels are moved, the first every 25 frames, the second every 16, and
; so on, until the last ones, which must not only move every frame, but
; also move 2 or 4 pixels at a time to go faster than 50Hz.
; To count how many frames each level has been scrolled
, counters are used that are incremented every frame, then
a CMP is used to check if the correct number of frames has been waited for.
PxCounter1,2... are the counters, Parallax1,2... are the BPLCON1 in COPLIST


;     .=============.
;     /st! \
;    ____ ___/_________________\___ ____
;    \ (/ \) /
;     \_______________________________/
;     \__/ ______ ______ \__/
;     /_\ ¬----/ \----¬ /_\
;     \/\\_ (_______) _//\/
;     \__/ _______________ \__/
;     / /\| | | | | |/\ \
;     \ `-^-^-^-^-“ /
;     \_____ _____/
;     `---------”

ParallaxFX:
para1:
addq.b    #01,PxCounter1    ; Increment Parallax Counter 1
cmpi.b    #25,PxCounter1    ; Speed counter = 25?
bne.s    Para2        ; Not yet 25 frames...
clr.b    PxCounter1    ; 25 frames passed! Reset the counter
cmp.b    #$ff,Parallax1    ; Have we reached the maximum scroll value?
 (15 pixels to the right)
beq.s    riazzera1    ; If so, we have to start again from zero!
add.b    #$11,Parallax1    ; if not, move level 1
bra.s    para2
riazzera1:
clr.b    Parallax1    ; start again from zero with the scroll
Para2:
addq.b    #$01,PxCounter2    ; Increment Parallax Counter 2
cmpi.b    #16,PxCounter2    ; Speed counter = 16?
bne.s    Para3        ; (Comments would be similar to Para1)
clr.b    PxCounter2
cmp.b    #$ff,Parallax2
beq.s    reset2
add.b    #$11,Parallax2    ; move parallax level 2
bra.s    para3
reset2:
clr.b    Parallax2
Para3:
addq.b    #$01,PxCounter3	; Increment Parallax Counter 3
cmpi.b    #10,PxCounter3    ; Speed counter = 10?
bne.s    Para4
clr.b    PxCounter3
cmp.b    #$ff,Parallax3
beq.s    reset3
add.b    #$11,Parallax3	; move the parallax level 3
bra.s    para4
riazzera3:
clr.b    Parallax3
Para4:
addq.b    #01,PxCounter4    ; Increment the Parallax Counter 4
cmpi.b    #5,PxCounter4    ; Speed counter = 5?
bne.s	Para5
clr.b    PxCounter4
cmp.b    #$ff,Parallax4
beq.s    reset4
add.b    #$11,Parallax4    ; move parallax level 4
bra.s    para5
reset4:
clr.b    Parallax4
Para5:
addq.b    #$01,PxCounter5    ; Increment the Parallax Counter 5
cmpi.b    #4,PxCounter5    ; Speed counter = 4?
bne.s    Para6
clr.b    PxCounter5
cmp.b    #$ff,Parallax5
beq.s    reset5
add.b    #$11,Parallax5    ; move the parallax level 5
bra.s    para6
reset5:
clr.b    Parallax5
Para6:
addq.b    #$01,PxCounter6    ; Increment the Parallax Counter 6
cmpi.b	#3,PxCounter6    ; Speed counter = 3?
bne.s    Para7
clr.b    PxCounter6
cmp.b    #$ff,Parallax6
beq.s    reset6
add.b    #$11,Parallax6    ; move the parallax level 6
bra.s    para7
riazzera6:
clr.b    Parallax6
Para7:
addq.b    #$01,PxCounter7    ; Increment the Parallax Counter 7
cmpi.b    #2,PxCounter7    ; Speed counter = 2?
bne.s    Para8
clr.b    PxCounter7
cmp.b    #$ff,Parallax7
beq.s    riazzera7
add.b    #$11,Parallax7	; move the parallax level 7
bra.s    Para8
riazzera7:
clr.b    Parallax7
; NOTE THAT PARA8, PARA9, PARA10 MUST
; BE EXECUTED EVERY FRAME, THEREFORE
Para8:                ; A DELAY COUNTER IS REQUIRED!
cmp.b    #$ff,Parallax8    ; Have we reached the maximum scroll?
bne.s	NonRiazzera8
clr.b    Parallax8    ; reset parallax8
bra.s    para9
NonRiazzera8:
add.b    #$11,Parallax8    ; move parallax level 8
Para9:
cmp.b    #$ee,Parallax9    ; Have we reached maximum scroll?
; The maximum is $ee and not $ff because this
; level must trigger in steps of 2 every
; frame, so: 00,22,44,66,88,aa,cc,ee
bne.s	NonRiazzera9
clr.b    Parallax9    ; reset parallax9
bra.s    Para10
NonRiazzera9:
add.b    #$22,Parallax9    ; move parallax level 9 (2 pixels!)
Para10:
cmp.b    #$cc,Parallax10	; Have we reached the maximum scroll?
; The maximum is $cc and not $ff because this
; level must trigger in steps of 4 every
; frame, so: 00,44,88,cc
bne.s    NonRiazzera10
clr.b    Parallax10    ; reset parallax10
bra.s	ParaFinito
NonRiazzera10:
add.b    #$44,Parallax10    ; move the parallax level 10 (4 pixels)
ParaFinito:
rts

; The variables used to count the delays for the first 7 levels, which must
; be moved once every 25,16,10 etc. frames.

PxCounter1:    dc.b    $00
PxCounter2:    dc.b    $00
PxCounter3:    dc.b    $00
PxCounter4:    dc.b    $00
PxCounter5:    dc.b    $00
PxCounter6:    dc.b    $00
PxCounter7:    dc.b    $00
even

; Subroutine to point the bitplanes...

************* d0=Picture address        | d2=Number of bits per plane
* PointBpls * d1=NumPiani-1 for the DBRA        |
************* a1=Address of pointers to planes    |
PointBpls:
move.w    d0,6(a1)    ; .w low in the correct .w of the CopperList
swap    d0        ; Swap the 2 .w of d0
move.w    d0,2(a1)    ; .w high in the correct .w of the CopperList
swap    d0		; Put d0 back in place
add.l    d2,d0        ; Add bitplane length to d0 - next bitp.
addq.w    #8,a1        ; address of the next bplpointers
dbra    d1,PointBpls    ; Restart the cycle
rts

*****************************************************************************
SECTION    PROGDATA,DATA_C        ; Data: This goes in CHIPRAM     *
*****************************************************************************

MyCopList:
dc.w    $8e,$2c91    ; DiwStrt (video window made
; starting 16 pixels further to the right to
; cover the horror (ahem, error)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; BplMod1
dc.w    $10a,0        ; BplMod2
dc.w    $100,$200    ; No Bitplanes...

Rainbow:
dc.w    $180,$a9c
dc.w    $eb07,$fffe
dc.w    $180,$bad
dc.w    $ed07,$fffe
dc.w    $180,$cbe
dc.w    $ef07,$fffe
dc.w	$180,$dce
dc.w    $f107,$fffe
dc.w    $180,$ede
dc.w    $f307,$fffe
dc.w    $180,$fef

dc.w    $f407,$fffe    ; wait

dc.w    $100,%0101001000000000    ; LowRes 32Colours

BPLPointers:
dc.w    $e0,$0000,$e2,$0000    ;first     bitplane
dc.w    $e4,$0000,$e6,$0000    ;second bitplane
dc.w    $e8,$0000,$ea,$0000	;third bitplane
dc.w    $ec,$0000,$ee,$0000
dc.w    $f0,$0000,$f2,$0000

dc.w    $0180
Colours:
dc.w	$fff,$182,$f10,$184,$f21,$186,$f42
dc.w	$188,$f53,$18a,$f63,$18c,$f74,$18e,$f85
dc.w	$190,$f96,$192,$fa6,$194,$fb7,$196,$fb8
dc.w	$198,$fc9,$19a,$f21,$19c,$f10,$19e,$f00
dc.w    $1a0,$eff,$1a2,$eff,$1a4,$dff,$1a6,$dff
dc.w    $1a8,$cff,$1aa,$bef,$1ac,$bef,$1ae,$adf
dc.w    $1b0,$9df,$1b2,$9cf,$1b4,$8bf,$1b6,$7bf
dc.w    $1b8,$7af,$1ba,$69f,$1bc,$68f,$1be,$57f


; HERE IS THE PART OF THE COPPERLIST RESPONSIBLE FOR THE PARALLEL:

dc.w    $f507,$fffe    ; Wait line $f5
dc.w    $180,$f52    ; Colour0 - orange background to ‘blend in’
; with the figure

dc.w    $102        ; BPLCON1
dc.b    $00        ; high byte, not used
Parallax1:
dc.b    $00        ; low byte, scroll value!!!!

dc.w    $f607,$fffe    ; wait
dc.w    $102        ; BPLCON1
dc.b    $00        ; etc., for each ‘level’
Parallax2:
dc.b    $00

dc.w    $f807,$fffe
dc.w    $102    ; BPLCON1
dc.b    $00
Parallax3:
dc.b    $00

dc.w    $fb07,$fffe
dc.w    $102    ; BPLCON1
dc.b    $00
Parallax4:
dc.b    $00

dc.w    $ff07,$fffe
dc.w    $102	; BPLCON1
dc.b    $00
Parallax5:
dc.b    $00

dc.w    $ffdf,$fffe    ; to bypass the $FF line

dc.w    $0407,$fffe
dc.w    $102	; BPLCON1
dc.b    $00
Parallax6:
dc.b    $00

dc.w    $0b07,$fffe
dc.w    $102    ; BPLCON1
dc.b    $00
Parallax7:
dc.b    $00

dc.w    $1207,$fffe
dc.w    $102    ; BPLCON1
dc.b    $00
Parallax8:
dc.b    $00

dc.w    $1a07,$fffe
dc.w    $102    ; BPLCON1
dc.b    $00
Parallax9:
dc.b    $00

dc.w    $2307,$fffe
dc.w    $102    ; BPLCON1
dc.b    $00
Parallax10:
dc.b    $00

dc.w    $2c07,$fffe
dc.w    $180,$f30

dc.w    $FFFF,$FFFE    ; End CopList

; The image is 320 pixels wide and 56 high, with 5 bitplanes (32 colours)

PARALLAXPIC:
incbin    ‘Lava320*56*5.Raw’    ; Include the image.

END

This little listing was done by my student ‘Gonzo’ after reading
LESSON 5. He called me asking how to do a parallax, and I replied
promptly that once he had read lesson 5 he would be able to do one,
 even though there was no specific listing. As you can see, he understood
how to do it. However, there is a small error that can be easily removed, namely the fact that
the classic ‘scroll error’ occurs in the first 16 pixels on the left. The
image is only 320 pixels wide, so when he moves the various parallax levels,
 he also moves the left side of the level in question. To
see the error, return the DiwStart to normal levels, which in this listing
has been modified to “plug” the problem:

dc.w    $8e,$2c91	; DiwStrt (video window made
; start 16 pixels further to the right to
; cover the horror, er, error)

Replace it with the standard $2c81 and you will notice the damage on the left.
To permanently solve the problem, just do as we did for the
scroll of a figure larger than the screen: you need to redraw the figure
of the floor, making it 16 pixels wider, i.e. 336 pixels, which means
we need to add an extra ‘tile’.
 At this point, point to the figure, remembering this ‘widening’, acting just as in the case
of the “giant” scroll, leaving the error in the 16 pixels ‘off screen’
on the left.
This is just a basis for a parallax floor. 
You could also make
a smoother scroll, line by line, calculating it with mathematical precision
using a table, and you could also change the palette for each
level to blend the colours more. If you feel like adding
parallax clouds, mountains and birds, please send me
your work!

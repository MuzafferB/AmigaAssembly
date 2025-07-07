
; Lesson 9h4.s    Disappearance of an image by scrolling to the right
;        using shift + BLTALWM mask.
;        Right click to perform the bleed, left click to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0        ; + LENGTH OF A PLANE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1        ; if not, wait

bsr.s    Scroll        ; execute the scroll routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts


;******************************************************************************
; This routine gradually makes an image disappear
; by scrolling it to the right
;******************************************************************************

;     .----------.
;     ¦
;     |
;     |
;     | ¯¯¯ --- |
;     _l___ ___|_
;     / _¬\ / _ ¬\
;     _/ ( °/--\° ) \_
;    /¬\_____/¯¯¯¯\_____/¬\
;    \ ____(_,____,_)____ /
;     \_\ `----------' /_/
;     \\___ ___//
;     \__`------'__/
;     | ¯¯¯¯ | xCz
;     `--------'

Scroll:
move.w    #160-1,d7    ; The loop must be executed once for each pixel
; the image is 160 pixels wide (10 words)

; In this example, we copy an image onto itself, but shift it
; continuously by one pixel, so that it scrolls.
; Therefore, the source and destination addresses are the same

ScorriLoop:

; Wait for the vblank so that the image scrolls one pixel with each
; frame.

WaitWblank:
CMP.b    #$ff,$dff006        ; vhposr - wait for line 255
bne.s    WaitWblank
Wait:
CMP.b    #$ff,$dff006        ; vhposr - still line 255?
beq.s    Wait

move.l    #bitplane+((20*50)+64/16)*2,d0        ; source and
; destination

moveq    #3-1,d5            ; repeat for each plane
PlaneLoop:
btst    #6,2(a5)    ; dmaconr - wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #$19f00000,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
; with a pixel shift

move.l    #$fffffffe,$44(a5)    ; BLTAFWM and BLTALWM
; BLTAFWM = $ffff - pass everything
; BLTALWM = $fffe = %1111111111111110
;     clear the last bit

; load the pointers

move.l    d0,$50(a5)            ; bltapt - source
move.l    d0,$54(a5)            ; bltdpt - destination

; the module is calculated as usual

move.l    #$00140014,$64(a5)        ; bltamod and bltdmod
move.w    #(20*64)+160/16,$58(a5)		; bltsize
; height 20 lines
; width 160 pixels (= 10 words)

add.l    #40*256,d0            ; point to the next plane
dbra    d5,PlaneLoop

dbra    d7,ScorriLoop            ; repeat for each pixel

btst    #6,$02(a5)    ; dmaconr - wait for the blitter to finish
waitblit2:
btst    #6,$02(a5)
bne.s    waitblit2
rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w	$92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; MODULE VALUE = 0
dc.w    $10a,0		; BOTH MODULES AT THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232	; color5
dc.w    $018c,$777    ; color6
dc.w    $018e,$444    ; color7

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

BITPLANE:
incbin    ‘assembler2:sorgenti6/amiga.raw’
; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.
end

;****************************************************************************

In this example we see a new effect. We will make an image disappear from the
screen by scrolling it to the right and deleting the pixels that reach
a certain horizontal position. This effect is achieved using the
blitter by combining shifting and masking. The scrolling to the right
is achieved naturally by shifting. The image is read from the
screen (it is not stored in another buffer) through channel A,
shifted by one pixel and rewritten to the screen in the same position.
The source and destination coincide perfectly. The mask of the
first word allows all bits to pass through. The mask of the last word, on the other hand,
takes on the value %1111111111111110 and therefore deletes the rightmost bit.
If we did not use this trick, the pixels coming out of the rightmost word
would re-enter the leftmost word one line below (we
discussed this during the explanation of the shift). Since we are using an interleaved screen,
 the bottom line belongs to a different plane, and
if the pixels move from one plane to another, chaos ensues.
Try to see this by setting BLTALWM to $ffff.
Thanks to the mask, this does not happen, because the mask is applied to the
data read BEFORE the shift is made.
So the bit that should come out on the right is reset by the mask.
A bleed done in this way shifts the image one pixel to the right.
By repeating the bleed as many times as there are pixels in
the width of the image (in our case 160), we obtain a complete disappearance
of the image.
It is possible to move the image faster by using a
shift value greater than 1. In this case, however, the mask must also be modified
so that it deletes all the pixels that the shift would cause to come out.
For example, using a shift of 4 pixels, the mask must delete the 4 pixels
furthest to the right, otherwise they would be left out.
Furthermore, since the image scrolls faster, it is necessary to repeat
the routine fewer times to make it disappear completely.
In the case of a shift of 4 pixels, 160/4=40 iterations
of the routine are necessary.
Try changing the speed yourself by trying other shift values,
for example 2.8 or 3.

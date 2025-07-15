
; Lesson 9m2.s    Disappearance of an image by scrolling to the left
;        Right click to execute the bleed, left click to exit.

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
MOVEQ	#3-1,D1        ; number of bitplanes (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
; HERE IS THE DIFFERENCE COMPARED
; TO NORMAL IMAGES!!!!!!
ADD.L    #40,d0        ; + LENGTH OF A LINE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1        ; if not, wait

bsr.s	Scroll        ; execute the scrolling routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts


;****************************************************************************
; This routine gradually makes an image disappear
; by scrolling it to the left
;****************************************************************************

;     ___________ ))
;     (( / ¬\
;     / ___ --- \
;     \¬\____ ____/ /
;     / ( ·T. ) / ))
;    (( / ¯¯!¯¯ /
;     / _ (_ _) /
;     \ ( ¬ `-'_/ ))
;    (( \ /
;     \______/ xCz

Scroll:
move.w    #160-1,d7    ; the loop must be executed once for each pixel
; the image is 160 pixels wide (10 words)

; In this example, we copy an image onto itself, but shift it
; continuously by one pixel, so that it scrolls.
; Therefore, the source and destination addresses are the same.
; To shift to the left, we use the descending mode, and therefore
; we point to the last word of the image:

move.l    #bitplane+((20*3*(50+20))+(64+160)/16-1)*2,d0    ; source ind. and
; destination

ScrollLoop:

; Wait for the vblank so that the image scrolls one pixel per
; frame.

WaitWblank:
CMP.b    #$ff,$dff006        ; wait for line 255
bne.s    WaitWblank
Wait:
CMP.b    #$ff,$dff006        ; still line 255?
beq.s    Wait

btst    #6,2(a5)        ; wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #$19f00002,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
; in descending order with shift
; (to the left) by one pixel

move.l    #$ffff7fff,$44(a5)    ; BLTAFWM and BLTALWM
; BLTAFWM = $ffff - pass everything
; BLTALWM = $7fff = %0111111111111111
; clear the leftmost bit
; load the pointers

move.l    d0,$50(a5)            ; bltapt - source
move.l    d0,$54(a5)            ; bltdpt - destination

; the module is calculated as usual

move.l #00140014,$64(a5)        ; bltamod and bltdmod
move.w    #(3*20*64)+160/16,$58(a5)    ; bltsize
; height 20 lines and 3 planes
; width 160 pixels (= 10 words)

dbra    d7,ScorriLoop            ; repeat for each pixel

btst    #6,$02(a5)        ; wait for the blitter to finish
waitblit2:
btst    #6,$02(a5)
bne.s    waitblit2
rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

; HERE IS A DIFFERENCE COMPARED TO
; THE NORMAL IMAGES!!!!!!
dc.w    $108,80        ; MODULE VALUE = 2*20*(3-1)= 80
dc.w    $10a,80        ; BOTH MODULES HAVE THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist


BITPLANE:
incbin    ‘assembler2:sources6/amiga.rawblit’
; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.
end

;****************************************************************************

In this example, we reproduce the effect seen in lesson9h4.s, except that
we scroll to the left. To shift to the left,
we must use the blitter in descending mode. The blitter always
copies an image onto itself (source and destination addresses are the same)
but the shift is to the left. We must mask the leftmost word
to delete the leftmost column of pixels. In descending mode, the
leftmost word is masked by BLTALWM. To delete the leftmost column of
pixels, we must set BLTALWM to the value %0111111111111111
which clears the leftmost bit and lets the others pass.
Note the difference with lesson 9h4 where we masked the rightmost bit instead
.


; Lesson 9l1.s    copy a rectangle between two overlapping areas
;        Right click to execute the blit, left click to exit.

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
; HERE IS THE DIFFERENCE COMPARED
; TO NORMAL IMAGES!!!!!!
ADD.L    #40,d0        ; + LENGTH OF A LINE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Let's point our COP
move.w    d0,$88(a5)        ; Let's start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1        ; if not, wait

bsr.s    copy        ; execute the copy routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts


; ************************ THE COPY ROUTINE ****************************
; a rectangle with width=160 and height=20 is copied
; from coordinates X1=64, Y1=50 (source)
; to coordinates X2=64, Y2=40 (destination)
; note that the source and destination overlap, and the destination
; is higher, therefore at a lower address.
;****************************************************************************

;     _______________
;     / _ ¬\
;     / / ¡__ \
;     / / O|o \ \
;     / \__l__/ \
;    / (___) \
;	\ (° /
;     \_____________________/
;     T T
;     _l____|_
;     | _ _ |
;     |_| |_|
;     (_)--^-(_)
;     T T T xCz
;    ........ l__|_|__
;     (____)__)

copy:

; Load the source and destination addresses into 2 registers

move.l    #bitplane+((20*3*50)+64/16)*2,d0    ; source ind.
move.l    #bitplane+((20*3*40)+64/16)*2,d2    ; destination ind.

btst    #6,2(a5)        ; wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
move.l	#$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM pass everything

; load pointers

move.l    d0,$50(a5)        ; bltapt
move.l    d2,$54(a5)        ; bltdpt

move.l #00140014,$64(a5)    ; bltamod and bltdmod 

move.w    #(3*20*64)+160/16,$58(a5)    ; bltsize
; height 20 lines and 3 planes
; width 160 pixels (= 10 words)

btst    #6,$02(a5)        ; wait for the blitter to finish
waitblit2:
btst    #6,$02(a5)
bne.s    waitblit2
rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

; HERE IS A DIFFERENCE COMPARED
; TO THE NORMAL IMAGES!!!!!!
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

;****************************************************************************

BITPLANE:
incbin    ‘assembler2:sorgenti6/amiga.rawblit’
; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.
end

;****************************************************************************

In this example, we copy a rectangle between two overlapping areas. Since
the destination address is lower than the source address (on the
screen, the destination is higher), we can safely
use the techniques we have used so far (copying a rectangle on
an interleaved screen). In fact, the routines in this example are identical to
those seen in the example lesson9g2.s.


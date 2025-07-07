
; Lesson 9g2.s    BLITTATA, in which we copy a rectangle from one point
;        to another on the same screen in INTERLEAVED format
;        Left key to execute the blit, right to exit.

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
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
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
; to coordinates X2=80, Y2=190 (destination)

;     _
;     /¬\
;     / \
;     __ /__ __\ __
;     .--\/-/ `°u°' \-\/--.
;     | / T¯¯¬ \ |
;     | / ` \ |
;     | /_____________\ |
;     | _ _ |
;     | | | |
;     l____| l____|
;     (____)----^----(____)
;     T T T xCz
;     ___l______|______|___
;    `----------^----------'

copy:

; Load the source and destination addresses into 2 registers
; NOTE THE DIFFERENCE FROM THE NORMAL CASE: WHEN CALCULATING THE OFFSET
; OF THE Y LINE, ALSO MULTIPLY BY THE NUMBER OF PLANES (i.e. 3)
; the formula is OFFSET=(Y*(NUMBER OF WORDS PER LINE)*(NUMBER OF PLANES))*2

move.l    #bitplane+((20*3*50)+64/16)*2,d0    ; source ind.
; note the factor *3!
move.l    #bitplane+((20*3*190)+80/16)*2,d2    ; destination ind.
; note the factor *3!

btst    #6,2(a5)    ; wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
move.l	#$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later

; load pointers
move.l    d0,$50(a5)    ; bltapt
move.l    d2,$54(a5)    ; bltdpt

; these 2 instructions set the source and destination modules
; THERE ARE NO DIFFERENCES FROM THE NORMAL CASE:
; the module is calculated according to the formula (H-L)*2 (H is the width of the
; bitplane in words and L is the width of the image, also in words)
; which we saw in class, (20-160/16)*2=20

move.w    #(20-160/16)*2,$64(a5)    ; bltamod
move.w    #(20-160/16)*2,$66(a5)    ; bltdmod

; also note that since the 2 registers have consecutive addresses, you can
; use a single instruction instead of two (remember that 20=$14):
; move.l #$00140014,$64(a5)    ; bltamod and bltdmod 

; NOTE THE DIFFERENCE FROM THE NORMAL CASE: IN THE SIZE
; OF THE BLITT, THE HEIGHT OF THE IMAGE IS MULTIPLIED BY THE NUMBER
; OF BITPLANES

move.w    #(3*20*64)+160/16,$58(a5)    ; bltsize
; height 20 lines and 3 planes
; width 160 pixels (= 10 words)

btst    #6,$02(a5)    ; wait for the blitter to finish
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

In this example, we display an image in interleaved format and copy
a piece of it from one point to another on the screen. This is the same program
as in the lesson9f1.s example, but in interleaved format.
We recommend that you examine this example by comparing it with lesson9f1.s.
As we saw in the lesson, the interleaved format allows us to
copy using a single blit. For this reason, the ‘Copy’ routine
(which is the routine that performs the copy) has no loops, unlike
the routine of the same name in lesson9f1.s.
Some values loaded into the blitter registers are different:

1) When calculating the address, to obtain the offset between the first word of the
Y line and the start of the bitplane, you must multiply Y by the number of
bitplanes, as well as by the size of the line; as for
X, however, there are no differences.

2) The height of the blitter is equal to the height of the image multiplied by
the number of bitplanes; as for the width, however, there are no
differences.

Also with regard to the other registers, in particular the module,
there are no differences.

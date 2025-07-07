
; Lesson 10a2.s    BLITTATA, in which we copy a drawing by inverting a bitplane
;        Right click to execute the blit, left click to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE1,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #2-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0    ; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

; copy the image normally

lea    FiguraPlane1,a0        ; copy the first plane
lea	BITPLANE1,a1
bsr.s    copy

lea    FigurePlane2,a0        ; copy second plane
lea    BITPLANE2,a1
bsr.s    copy

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1

; copy the image inverting the first bitplane

lea    FigurePlane1,a0
lea    BITPLANE1+14,a1
bsr.s    CopiaInversa        ; copy the first plane inverting it

lea    FigurePlane2,a0
lea    BITPLANE2+14,a1
bsr.s    copy            ; copy second plane normally

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:
rts

;****************************************************************************
; This routine copies the figure on the screen.
; It takes as parameters
; A0 - source address
; A1 - destination address
;****************************************************************************

Copy:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$ffffffff,$44(a5)    ; masks
move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 (use A+D)
; normal copy
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #34,$66(a5)        ; BLTDMOD (40-6=34)
move.l    a0,$50(a5)		; BLTAPT source pointer
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w    #(64*25)+3,$58(a5)    ; BLTSIZE (start the blitter!)
; width 3 words
rts                ; height 25 lines

;****************************************************************************
; This routine copies the image on the screen, inverting it
; i.e. it turns 1 into 0 and 0 into 1.
;
; A0 - source address
; A1 - destination address
;****************************************************************************

;     _ _
;     __/ \_/ \
;     / \_ oo_/
;     / \/_
;     ____/_ ___ ____o
;     ___/ \\ \\ UU

CopyInverse:
btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

move.l    #$ffffffff,$44(a5)    ; masks
move.l    #$090f0000,$40(a5)    ; BLTCON0 and BLTCON1
; copy by inverting the bits, i.e.
; D=NOT A
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #34,$66(a5)        ; BLTDMOD (40-6=34)
move.l    a0,$50(a5)        ; BLTAPT source pointer
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w	#(64*25)+3,$58(a5)    ; BLTSIZE (start blitter!)
; width 3 words
rts                ; height 25 lines

;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0		; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$2200    ; bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w    $e0,$0000,$e2,$0000    ;first     bitplane
dc.w    $e4,$0000,$e6,$0000

dc.w    $0180,$000    ; colour0
dc.w    $0182,$aaa    ; colour1
dc.w    $0184,$55f    ; colour2
dc.w    $0186,$f80    ; colour3

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

FiguraPlane1:
dc.w	$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$c000,$0000,$0003,$c000
dc.w	$0000,$0003,$c000,$0000,$0003,$c000,$0000,$0003,$c000,$0000
dc.w	$0003,$c000,$0000,$0003,$c000,$0000,$0003,$c000,$0000,$0003
dc.w	$c25c,$3bbb,$bb83,$c354,$22aa,$a283,$c2d4,$22bb,$b303,$c254
dc.w	$22a2,$2283,$c25c,$3ba2,$3a83,$c000,$0000,$0003,$c000,$0000
dc.w	$0003,$c000,$0000,$0003,$c000,$0000,$0003,$c000,$0000,$0003
dc.w    $c000,$0000,$0003,$c000,$0000,$0003,$c000,$0000,$0003,$ffff
dc.w    $ffff,$ffff,$ffff,$ffff,$ffff

FigurePlane2:
dc.w    $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
dc.w    $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
dc.w	$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
dc.w    $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
dc.w	$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
dc.w    $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
dc.w	$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff
dc.w	$ffff,$ffff,$ffff,$ffff,$ffff

;****************************************************************************

SECTION	bitplane,BSS_C
BITPLANE1:
ds.b	40*256
BITPLANE2:
ds.b    40*256

end

;****************************************************************************

In this example, we see an application of the NOT logical operation.
We have a drawing on the screen, which could represent a button.
Now suppose we want to draw the same button, but inverting the
colours to simulate pressing it.
One method is to swap the colours in the copperlist.
However, this swaps the colours across the entire screen, so if
we want to have two buttons at the same time, one with normal colours and
the other with inverted colours, this technique is not suitable.
So we just need to modify the bitplanes that make up the image.
The button is drawn with colours 2 and 3.
To swap the colours, we need to change colour 2 to 3 and vice versa.
Pixels coloured with colour 2:
You have colour 2 when plane 1 is set to 0 and plane 2 is set to 1.
You have colour 3 when plane 1 is set to 1 and plane 2 is set to 1.
Since both colours have plane 2 set to 1, we only need to change
plane 1.
If we invert all the bits in plane 1 (i.e. we change all 0s to 1s
and all 1s to 0s), we will swap colours 2 and 3.
Bit inversion is the logical NOT operation that we can perform with the
blitter using an appropriate minterm. If we use channel A to read,
we must set output D to 1 every time the input is 0 and vice versa.
This is achieved by setting all minterms corresponding to combinations
with A=0 to 1, i.e. (as you can see from the table in the lesson) with
LF=$0F.

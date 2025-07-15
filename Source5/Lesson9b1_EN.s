
; Lesson9b1.s    BLITTATA, in which we copy 8 words into a zeroed bitplane.
;        Left key to execute the blit, right to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


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
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

Wait:
btst	#6,$bfe001    ; wait for the left mouse button to be pressed
bne.s    Wait

btst.b    #6,2(a5) ; dmaconr
WBlit:
btst.b    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit

;     |\/\/\/|
;     | |
;     | |
;     | (o)(o)
;     c _)
;     | ,___|
;     | /
;     /____\
;    / \        ; the following 2 registers will be explained
; below:

move.w    #$ffff,$44(a5)    ; bltafwm - mask channel A, first word
move.w    #$ffff,$46(a5)    ; bltalwm - mask channel A, second word

move.w    #$09f0,$40(a5)    ; bltcon0 - channels A and D enabled, 
; MINTERMS=$f0, i.e. copy from A to D
move.w	#$0000,$42(a5)        ; bltcon1 - we will explain this later
move.l    #random_figure,$50(a5)    ; bltapt - source figure address

; the destination address depends on the X,Y position where we want to
; draw the first pixel of the figure. The rules of the lesson apply
; In this case, X=32 and Y=4.

move.l    #bitplane+(4*20+32/16)*2,$54(a5)    ; bltdpt - dest. ind.
move.w    #64*1+8,$58(a5)            ; bltsize - height 1 line,
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

;****************************************************************************

; This is the ‘figure’ that is copied into the BITPLANE with a bleed:

Figura_a_caso:	
dc.w	$1111,$1010,$2044,$235a
dc.w	$18f0,$97ff,$ca54,$90a2

;****************************************************************************

SECTION	PLANEVUOTO,BSS_C

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

;***************************************************************************

In this example, we copy a memory area with the blitter.
More precisely, we read 8 words (considering them as a rectangle
8 words wide and one line high) starting from the address identified
by the label ‘Figura_a_caso:’ and rewrite them starting from the address
identified by the label ‘BITPLANE:’, which, as can be understood from the name of the
label, is the address of a memory area containing a bitplane.
In reality, we copy them to BITPLANE+offset, i.e. offset from the starting corner.
Therefore, the data we copy is displayed on the screen.
To perform a copy operation, it is necessary to use 2 DMA channels,
 one for reading and one for writing. In this case, we use channel
A for reading and, obviously, D for writing. Therefore, only these two channels
are enabled by setting the corresponding bits in the BLTCON0 register to 1.
To tell the blitter to copy from channel A to channel
D, you need to set the byte containing the MINTERMS to the value $f0.
Try changing the position where the figure is drawn by changing
the destination address of the blitter. Apply the rules seen in the
lesson.


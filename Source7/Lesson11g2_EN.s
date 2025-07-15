
; Lesson 11g2.s - Using the copper feature to request 8 horizontal pixels
; to perform a ‘MOVE’.

Section    coppuz,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; salva interrupt, dma eccetera.
*****************************************************************************

; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %100000101000000    ; copper DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:
BSR.W    MAKE_IT        ; Prepare the copperlist

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA
MOUSE:
BTST    #$06,$BFE001    ; Wait for mouse press
BNE.S	MOUSE
RTS

*************************************************************************
* This routine creates a copperlist with 52 COLOR0 registers for    *
* Line, so that, given that each move of the copperlist takes 8    *
* pixels (lowres) of time to be executed, colour0 is    *
* changed 52 times HORIZONTALLY in 8 lowres pixel increments    *
*************************************************************************

;	 .:::::.
;	 ¦:::·:::¦
;     |· ·|
;    C| _ _ l)
;    / _°(_)°_ \
;    \_\_____/_/
;     l_`---'_!
;     `-----'xCz


LINSTART    EQU    $8021fffe    ; Change ‘$80’ to start at
; another vertical line.
LINUM        EQU    25*3        ; Number of lines to draw.

MAKE_IT:
lea    CopBuf,a1    ; Address space in copperlist
move.l    #LINSTART,d0    ; First ‘wait’
move.w    #LINUM-1,d1    ; Number of lines to make
move.w    #$180,d3    ; Word for colour register 0 in coplist
move.l    #$01000000,d4    ; Value to ‘add’ to the wait to make it wait
; for the next line.
colcon1:
lea    cols(pc),a0    ; Address of table with colours in a0
move.w    #52-1,d2    ; 52 colours per line
move.l    d0,(a1)+    ; Put WAIT in copperlist
colcon2:
move.w    d3,(a1)+    ; Put the COLOR0 register ($180)
move.w    (a0)+,(a1)+	; Set the value of COLOR0 (from the table)
dbra    d2,colcon2    ; Execute an entire line
add.l    d4,d0        ; Make the line below wait (+$01000000)
dbra    d1,colcon1    ; Repeat for the number of lines to be done
rts


;    Table with the 52 colours of a horizontal line.

cols:
dc.w    $26F,$27E,$28D,$29C,$2AB,$2BA,$2C9,$2D8,$2E7,$2F6
dc.w    $4E7,$6D8,$8C9,$ABA,$CAA,$D9A,$E8A,$F7A,$F6B,$F5C
dc.w	$D6D,$B6E,$96F,$76F,$56F,$36F,$26F,$27E,$28D,$29C
dc.w	$2AB,$2BA,$2C9,$2D8,$2E7,$2F6,$4E7,$6D8,$8C9,$ABA
dc.w	$CAA,$D9A,$E8A,$F7A,$F6B,$F5C,$D6D,$B6E,$96F,$76F
dc.w	$56F,$36F

*****************************************************************************

section    coppa,data_C

COPLIST:
DC.W    $100,$200    ; BplCon0 - no bitplanes
DC.W    $180,$003    ; Colour0 - blue
CopBuf:
dcb.w    (52*2)*LINUM+(2*linum),0    ; Space for the copperlist.
DC.W    $180,$003    ; Colour0 - blue
dc.w    $ffff,$fffe    ; End copperlist

END

In this case, we have made the effect more ‘colourful’, nothing special.

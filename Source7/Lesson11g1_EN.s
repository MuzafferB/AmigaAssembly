
; Lesson 11g1.s - Using the copper feature to request 8 horizontal pixels
; to perform a ‘MOVE’.

Section    HorizCop,CODE

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

MOVE.W	#DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA
MOUSE:
BTST    #$06,$BFE001    ; Wait for mouse press
BNE.S    MOUSE
RTS

*************************************************************************
* This routine creates a copperlist with 40 COLOR0 registers for    *
* Line, so that, given that each move of the copperlist takes 8    *
* pixels (lowres) of time to be executed, colour0 is    *
* changed 40 times HORIZONTALLY in 8 lowres pixel increments    *
*************************************************************************

;     .:::::.
;     ¦:::·:::¦
;     |· ¯ ¯ ·|
;     C| ° ° l)
;     /__ (_) __\
;    / \ \___/ / \
;    \__\_ _/__/
;     \_`---'_/xCz
;     ¯¯¯¯¯

LINSTART    EQU    $A041fffe    ; Change ‘$a0’ to start at
; another vertical line.
LINUM        EQU    25        ; Number of lines to make.

MAKE_IT:
lea    CopBuf,a1
move.l    #LINSTART,d0    ; First ‘wait’
move.w    #LINUM-1,d1    ; Number of lines to make
colcon1:
lea    cols(pc),a0	; Address of the colour table in a0
move.w    #39-1,d2    ; 39 colours per line
move.l    d0,(a1)+    ; Put WAIT in copperlist
colcon2:
move.w    #$0180,(a1)+    ; Set the COLOR0 register
move.w    (a0)+,(a1)+    ; Set the value of COLOR0 (from the table)
dbra    d2,colcon2    ; Execute an entire line
add.l    #01000000,d0    ; Make the line below ‘wait’
dbra    d1,colcon1	; repeat for the number of lines to be done
rts


;    Table with the 39 colours of a horizontal line.

cols:
dc.w    $000,$111,$222,$333,$444,$555,$666,$777
dc.w    $888,$999,$aaa,$bbb,$ccc,$ddd,$eee,$fff
dc.w    $fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff
dc.w	$eee,$ddd,$ccc,$bbb,$aaa,$999,$888,$777
dc.w	$666,$555,$444,$333,$222,$111,$000

*****************************************************************************

section    coppa,data_C

COPLIST:
DC.W    $100,$200    ; BplCon0 - no bitplanes
DC.W    $180,$003    ; Colour0 - blue
CopBuf:
dcb.w    80*LINUM,0    ; Space where the copperlist will be created.

DC.W    $180,$003    ; Colour0 - blue
dc.w    $ffff,$fffe    ; End of copperlist

END

This listing shows how, by placing a row of COLOUR0 (or any other
MOVE of WAIT), it takes a certain amount of time to execute each one, namely
8 lowres pixels. In fact, if you set the resolution to hires, this does not change,
and you can talk about ‘16’ hires pixels... but it is useless. If you want, you can
measure the width of a horizontal ‘shot’ with a ruler and you will notice
that it is always the same. In addition to being useful for effects such as PLASMI
or the one seen in this example, it is a limitation in the sense that if you
want to change the entire palette on each line, it takes ‘some time’ and it
would not change completely until halfway through the line or even on the line below.



; Lesson 9g1.s    Displaying an INTERLEAVED image
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
; HERE IS THE FIRST DIFFERENCE COMPARED
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

mouse:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:
rts

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

; HERE IS THE SECOND DIFFERENCE COMPARED
; TO NORMAL IMAGES!!!!!!
dc.w    $108,80        ; MODULE VALUE = 2*20*(3-1)= 80
dc.w    $10a,80        ; BOTH MODULES HAVE THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w $0180,$000; colour0
dc.w $0182,$475; colour1
dc.w $0184,$fff; colour2
dc.w $0186,$ccc; colour3
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

In this example, we display an image in interleaved format
(or rawblit, as KEFCON calls it). It is the same image, but
we had to convert it to interleaved format, so we use a different file
.
As we already mentioned in the lesson, to display images in this
format, you need to change two things compared to normal images:
1) When pointing to the bitplanes, you need to calculate the addresses of the
various bitplanes that are ‘distant’ from each other by a single row, and not by all the rows
of the bitplane;
2) the bitplane modules are not equal to 0, but are used to ‘skip’ the rows of the
other bitplanes. They are calculated using the formula we have seen:

MODULE=2*L*(N-1)     Where L is the width of the bitplane expressed in words
and N is the number of bitplanes

In our case, the bitplanes are 20 words wide (320/16) or 40 bytes,
and the number of bitplanes is 3. You can find the difference 1) in the first
lines of the listing, in the loop that points to the bitplanes in the copperlist, and
difference 2) in the copperlist instructions that load the value of the
module into BPL1MOD and BPL2MOD.


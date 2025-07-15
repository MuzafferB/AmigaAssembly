
; Lesson 9m1.s    Example of using masks with the descending mode
; press the right and left mouse buttons alternately to see
; various blits with different masks.


SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:
;    Point to the ‘empty’ PIC

MOVE.L	#BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

; prepare parameters

move.w    #$ffff,d0        ; mask first word (further to the right)
; pass all bits
move.w    #$ffff,d1        ; mask last word (most left)
; pass all bits
move.l    #bitplane+7*40+6,a0    ; destination address
bsr.w    Copy

mouse2:
btst    #2,$dff016        ; right mouse button pressed?
bne.s    mouse2

; prepare parameters

moveq    #0000,d0        ; mask first word
; clear everything
move.w    #ffff,d1        ; mask last word
; pass all bits
move.l    #bitplane+37*40+6,a0    ; destination address
bsr.s    Copy
mouse3:
btst    #6,$bfe001        ; mouse pressed?
bne.s    mouse3

; prepare parameters

move.w    #%1010101010101010,d0    ; mask first word
; one bit yes and one bit no
move.w    #%0000000000000001,d1	; mask last word
; only rightmost bit
move.l    #bitplane+67*40+6,a0    ; destination address
bsr.s    Copy

mouse4:
btst    #2,$dff016        ; right mouse button pressed?
bne.s    mouse4

; prepare parameters

move.w    #$0000,d0        ; first word mask
; clear everything
move.w    #$0000,d1        ; last word mask
; clear everything
move.l    #bitplane+97*40+6,a0    ; destination address
bsr.s    Copy

mouse5:
btst    #6,$bfe001        ; mouse pressed?
bne.s    mouse5

; prepare parameters

move.w    #%1111000011110000,d0    ; mask first word
; 4 bits yes and 4 no
move.w    #%0000011010011100,d1	; mask last word
; only bits 2, 3, 4, 7, 9 and 10 are passed
move.l    #bitplane+127*40+6,a0    ; destination address
bsr.s    Copy

mouse6:
btst    #2,$dff016        ; right mouse button pressed?
bne.s    mouse6

; prepare parameters

move.w    #%0000000001111111,d0    ; first word mask
; clear the 9 bits furthest to the left
move.w    #%1111111000000000,d1	; mask last word
; delete the 9 bits furthest to the right
move.l    #bitplane+157*40+6,a0    ; destination address
bsr.s    Copy

mouse:
btst    #6,$bfe001
bne.s    mouse

rts

;****************************************************************************
; This routine copies the figure on the screen in descending order
; Takes as parameters
; A0 - destination address
; D0 - first word mask
; D1 - last word mask
;****************************************************************************

;     _/\________
;     \__¯ ¯ ¯ ¯¬\
;     (_--' \-,
;     /¬\ _)
;     __(©__) /
;    (. ___ /
;     ¯T_____/ / (
;     l_T / ¯\
;     / / \
;     .______/ /\ u \
;     l_ _/ \ \
;     `------' T ·
;     xCz ¦
;     :
;     .

Copy:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.w    d0,$44(a5)        ; BLTAFWM loads the parameter
move.w    d1,$46(a5)        ; BLTALWM loads the parameter
move.w    #$09f0,$40(a5)        ; BLTCON0 (use A+D)
move.w    #$0002,$42(a5)		; BLTCON1 descending mode
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #34,$66(a5)        ; BLTDMOD (40-6=34)
move.l    #figure+7*6-2,$50(a5)    ; BLTAPT (fixed to the source figure)
; point to the last word of the figure
; because of the descending mode
move.l    a0,$54(a5)        ; BLTDPT load the parameter
move.w    #(64*7)+3,$58(a5)    ; BLTSIZE (start the blitter!)
; width 3 words
rts                ; height 7 lines (1 plane)

;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
dc.w    $100,$1200    ; bplcon0 - 1 bitplane Lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; Let's define the figure in binary, which is 3 words wide and 7 lines high

Figure:
;         0123456789012345 0123456789012345 0123456789012345
dc.w	%1111111111000000,%0000001111000000,%0000001111111111
dc.w	%1111111111000000,%0000111111110000,%0000001111111111
dc.w	%1111111111000000,%0011111111111100,%0000001111111111
dc.w	%1111111111111111,%1111111111111111,%1111111111111111
dc.w	%1111111111000000,%0011111111111100,%0000001111111111
dc.w	%1111111111000000,%0000111111110000,%0000001111111111
dc.w	%1111111111000000,%0000001111000000,%0000001111111111

;****************************************************************************

SECTION	PLANEVUOTO,BSS_C	

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

;****************************************************************************

This example is almost identical to the example in lesson9h1.s. The only difference
is that the copy is done in descending order. By blitting in this way
the first word of each row is the row that appears furthest to the right on the screen,
and the last is the word that appears furthest to the left. Therefore, unlike 
what happens when using the ascending mode, the mask of the first word
(contained in BLTAFWM) is applied to the rightmost word and the mask
of the last word (BLTALWM) to the leftmost word.
When you run the program, you will see how the masks are applied in an
inverted manner compared to the example lesson9h1.s.

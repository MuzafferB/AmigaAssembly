
; Lesson 9e1.s        * SHIFTING * of the blitter.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


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
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

moveq    #0,d4            ; horizontal coordinate to 0

Loop
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10800,d2    ; line to wait for = $108
Waity1
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
Beq.S    Waity2

;     ...........
;    .· ... ... :
;    |.· _ ·· _ ·.|
;    l_ ¯_¯ ¯_¯ |
;     | (°),.(°) T
;     | _________ |
;     | \_l_l_/ |
;     l___`---“___|xCz
;     `------”

move.w    d4,d5    ; current horizontal coordinate in d5

and.w    #000f,d5    ; Select the first 4 bits because they must be
; inserted into the channel A shifter
lsl.w    #8,d5        ; the 4 bits are moved to the high nibble
lsl.w    #4,d5        ; of the word... (8+4 = 12-bit shift!)
or.w    #$09f0,d5    ; ...just right to fit into the BLTCON0 register
; Here we put $f0 in the minterms for copying from
; source A to destination D and
; obviously enable channels A+D with $0900 (bit 8
; for D and 11 for A). That is, $09f0 + shift.

addq.w    #1,d4        ; Add 1 to the horizontal coordinate to
; move 1 pixel to the right next time

btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.w    #$ffff,$44(a5)        ; BLTAFWM we'll explain this later
move.w    #$ffff,$46(a5)        ; BLTALWM we'll explain this later
move.w    d5,$40(a5)        ; BLTCON0 (use A+D) - in the register
; we've put the shift! (bits 12,13
; 14 and 15, i.e. high nibble!)
move.w    #$0000,$42(a5)		; BLTCON1 will be explained later
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #38,$66(a5)        ; BLTDMOD (40-2=38)
move.l    #figure,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    #bitplane,$54(a5)    ; BLTDPT (screen lines)
move.w    #(64*6)+1,$58(a5)    ; BLTSIZE (start blitter!)
; the figure is 1 word wide and
; 6 lines high
btst    #6,$bfe001        ; mouse pressed?
bne.s    loop

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

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
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; Here is the fish... 16 pixels wide (1 word) and 6 lines high.

Figura:
dc.w	%1000001111100000
dc.w	%1100111111111000
dc.w	%1111111111101100
dc.w	%1111111111111110
dc.w	%1100111111111000
dc.w	%1000001111100000

;****************************************************************************

SECTION	PLANEVUOTO,BSS_C	

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

;****************************************************************************

In this example, you can see how the shift works. We have a figure that is
1 word wide and 6 lines high.
This figure is always blitted to the same destination address, i.e.
the same address is always put in BLTDPT ($dff054).
Each time, however, the shift value in BLTCON0 is increased by 1.
In this way, the figure moves 1 pixel to the right each time.
Note the phenomenon described in the lesson: the bits that are shifted
out of the word re-enter on the left in the next word.
In our case, this is not good, because the fish's mouth comes out on the right and
re-enters on the left, behind the tail.
In the next example, we will see how to solve this problem.


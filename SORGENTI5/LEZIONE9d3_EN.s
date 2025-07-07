
; Lesson 9d3.s    BLIT TO THE RIGHT, in 1-word increments (without using shift)


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
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

lea    bitplane,a0        ; destination
moveq    #50-1,d7        ; Number of moves to the right
MoveLoop:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10800,d2    ; line to wait for = $108
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
Beq.S    Waity2

btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

;    Screen clearing

move.w    #$0100,$40(a5)        ; BLTCON0 - turns on only channel D,
; this causes the clearing of the
; DESTINATION, since there is no
; source!!!
move.w    #$0000,$42(a5)		; BLTCON1 - we'll explain this later
move.w    #$0000,$66(a5)        ; BLTDMOD = 0
move.l    #bitplane,$54(a5)    ; BLTDPT - destination = bitplane
move.w    #(64*256)+20,$58(a5)    ; BLTSIZE - height 256 lines, width 20 w.
; clear the ENTIRE SCREEN, in fact
; there are 256 lines (64*256) and
; there are 40 bytes per line (20 words)

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

;     ..........
;    .· .. ... :
;    |.· _·· _ ·.|
;    l ¯_ _¯ |
;	| (º),(º) |
;    | \_______/ |
;    | |-+-+-| |
;    l__`-^-^-“__|xCz
;     `-------”

move.w    #$ffff,$44(a5)        ; BLTAFWM explained later
move.w    #$ffff,$46(a5)        ; BLTALWM we'll explain this later
move.w    #$09f0,$40(a5)        ; BLTCON0 (use A+D)
move.w    #$0000,$42(a5)        ; BLTCON1 we'll explain this later
move.w    #0,$64(a5)		; BLTAMOD (=0)
move.w    #36,$66(a5)        ; BLTDMOD (40-4=36)
move.l    #figure,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.w    #(64*6)+2,$58(a5)    ; BLTSIZE (start blitter!)
; now, we will blitter a figure of
; 2 words X 6 lines with a single
; blittered by the modules appropriately
; set correctly for the screen.

addq.w    #2,a0            ; change the address, pointing to
; the next word for the next
; blitter. The image moves forward
; by 16 pixels
dbra    d7,moveloop

mouse:

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

btst    #6,2(a5) ; dmaconr
WBlit3:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit3

rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
dc.w    $100,$1200    ; bplcon0 - 1 bitplane Lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; Let's define the figure in binary, which is 16 bits wide, i.e. 2 words, and
; 6 lines high

Figure:
dc.l    %00000000000000000000110001100000
dc.l	%00000000000000000011000110000000
dc.l	%00000000000000001100011000000000
dc.l	%00000110000000110001100000000000
dc.l	%00000001100011000110000000000000
dc.l	%00000000011100011000000000000000

;****************************************************************************

SECTION    PLANEVUOTO,BSS_C

BITPLANE:
ds.b    40*256        ; bitplane reset lowres

end

;****************************************************************************

This example is similar to lesson9d2.s, except that we move to the right instead
of down. The shift is done by changing the destination address
we are blitting to, moving one word at a time. This is equivalent
to moving 16 pixels at a time (yuck!).


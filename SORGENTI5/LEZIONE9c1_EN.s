
; Lesson9c1.s    FIRST BLIT WITH HEIGHT GREATER THAN 1 AND MODULES
;        Left key to execute the blit, right key to exit.

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
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

Wait:
btst    #6,$bfe001    ; wait for the left mouse button to be pressed
bne.s    Wait

btst.b    #6,2(a5) ; dmaconr
WBlit:
btst.b    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit

;     /\ /\
;    .--/ \/ \---.
;     \ /
;    ._> (o)(o <__.
;     \ _C /
;     / /____, ) \
;	'----\ /----`
;     oooo
;     / \

move.w    #$ffff,$44(a5)        ; BLTAFWM we will explain this later
move.w    #$ffff,$46(a5)        ; BLTALWM we will explain this later
move.w    #$09f0,$40(a5)		; BLTCON0 (use A+D)
move.w    #$0000,$42(a5)        ; BLTCON1 we will explain this later
move.w    #0,$64(a5)        ; BLTAMOD =0 because the
; source rectangle has consecutive lines
; in memory.

move.w    #36,$66(a5)        ; BLTDMOD 40-4=36 the destination rectangle
; is inside a
; bitplane 20 words wide, or 40
; bytes. The blitted rectangle
; is 2 words wide, or 4 bytes.
; The value of the module is given by the
; difference between the widths

move.l    #figure,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    #bitplane,$54(a5)    ; BLTDPT (lines of the screen)
move.w    #(64*6)+2,$58(a5)    ; BLTSIZE (start the blitter!)
; now, we will blitter a figure of
; 2 words X 6 lines with a single
; blitter with the modules appropriately
; set for the screen.
mouse:
btst    #2,$16(a5)    ; right mouse button pressed?
bne.s    mouse

btst.b    #6,2(a5) ; dmaconr
WBlit2:
btst.b    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

rts

;*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200    ; bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;*****************************************************************************

; Let's define the figure in binary, which is 16 bits wide, i.e. 2 words, and
; 6 lines high. Note that the lines are arranged consecutively in memory.

Figure:
dc.l    %00000000000000000000110001100000    ; line 1
dc.l    %00000000000000000011000110000000	; linea 2
dc.l	%00000000000000001100011000000000
dc.l	%00000110000000110001100000000000
dc.l	%00000001100011000110000000000000
dc.l	%00000000011100011000000000000000	; linea 6

;*****************************************************************************

SECTION	PLANEVUOTO,BSS_C

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

*****************************************************************************

In this example, you can see how to copy a rectangle.
First, note once again the formula to use to write
the dimensions of the rectangle in BLTSIZE. Then pay close attention to how
the modules are calculated. As for the source, which starts at the
label ‘Figure’, the lines of the rectangle are arranged consecutively in
memory. Therefore, the module value for the source (channel A) is 0.
As for the destination, since we have to copy the
rectangle into a bitplane that is wider than the rectangle in question,
the lines are not consecutive in memory and we must specify a module value
calculated using the formulas seen in the lesson.


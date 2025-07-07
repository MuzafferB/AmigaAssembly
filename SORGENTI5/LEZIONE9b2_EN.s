
; Lesson 9b2.s    SINGLE-LINE BLITTATE LOOP

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

; The destination address, which varies each time, is stored in A0.
 The initial address is calculated to display the figure at
line Y=3 starting from the pixel with X=0

lea    bitplane+(3*20+0/16)*2,a0    ; destination address
move.w    #200-1,d7            ; number of loops = 200

BlitLoop:
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

btst.b    #6,2(a5) ; dmaconr
WBlit:
btst.b    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit

;     (####)
;     (#######)
;     (#########)
; (#########)
; (#########)
; (#########)
; (#########)
; (o)(o)(##)
; ,_c (##)
; /____, (##)
; \ (#)
;     | |
;     oooooo
;     / \

move.w    #$ffff,$44(a5)        ; BLTAFWM we will explain this later
move.w    #$ffff,$46(a5)        ; BLTALWM we will explain this later
move.w    #$05CC,$40(a5)        ; BLTCON0 (makes a copy from B to D)
move.w    #$0000,$42(a5)        ; BLTCON1 will be explained later
move.w    #$0000,$62(a5)        ; BLTBMOD will be explained later
move.w    #$0000,$66(a5)        ; BLTDMOD will be explained later
move.l    #figure,$4c(a5)        ; BLTBPT (fixed to the source figure)
move.l    a0,$54(a5)        ; BLTDPT (variable destination a0)
move.w    #64*1+10,$58(a5)    ; BLTSIZE (start blitter!)
; now, instead of 8 words, as in the
; previous example, we blit 10 words

add.w    #40,a0            ; let's go blit to the next
; line in the next loop.
dbra    d7,blitloop

mouse:
btst    #6,$bfe001    ; mouse pressed?
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

*****************************************************************************

SECTION	Figura_da_blittare,DATA_C

Figura:
dc.w	$8888,$aaaa,$cccc,$f0f0
dc.w	$ffff,$6666,$eeee,$5555
dc.w	$2222,$dddd

*****************************************************************************

SECTION	PLANEVUOTO,BSS_C	

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

*****************************************************************************

This example is a variation of the example in lesson9b1.s
Note how, by changing the destination address, the data is copied
to different areas of the screen. Each blit is done one line lower than
the previous one. This is achieved by always adding 40 (=number
of bytes per line) to the destination address.

Note something very important: before EVERY blit, ALWAYS wait for
the blitter to finish the previous blit, using the Wblit loop.

In this example, we used channel B as the source channel.
Consequently, we use the BLTBPT and BLTBMOD registers instead of BLTAPT and
BLTAMOD; furthermore, the value written in BLTCON0 is different, because we have to
activate channel B instead of channel A (so bit 11 is 0 and bit 10
is 1) and because we have to set the MINTERMS to the value $CC, which defines
a copy from channel B to channel D.


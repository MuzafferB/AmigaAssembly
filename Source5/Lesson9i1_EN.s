
; Lesson9i1.s    Fish again! But even smarter!

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

moveq    #0,d1            ; horizontal coordinate to 0
move.w    #(320-32)-1,d7        ; moves 320 pixels MINUS the actual width
; of the BOB, so that
; its first pixel on the left
; stops when the one on the right reaches
; the end of the screen.
Loop:
cmp.b    #$ff,$6(a5)    ; VHPOSR - wait for line $ff
bne.s    loop
Wait:
cmp.b    #$ff,$6(a5)    ; still line $ff?
beq.s    Wait

;     _____________
;     \____ _ ____/
;    (¯T¯¯(·X.)¯¯T¯)
;	 ¯T _ ¯u¯ _ T¯
;     _| `-^---“ |_
;    |¬| ¯¯¯ |¬|
;    | l_________| |
;    |__l `-o-” |__|
;    (__) (__)
;     T_________T
;     T¯ _ ¯T xCz
;     __l___l___l__
;    (______X______)

lea    bitplane,a0    ; destination in a0
move.w    d1,d0
and.w    #000f,d0    ; select the first 4 bits because they must
; be inserted in the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #09f0,d0    ; ...just enough to fit into the BLTCON0 register
move.w    d1,d2
lsr.w    #3,d2        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d2    ; exclude bit 0
add.w    d2,a0        ; add to the bitplane address, finding
; the correct destination address
addq.w    #1,d1        ; add 1 to the horizontal coordinate

btst    #6,2(a5) ; dmaconr
WBlit1:
btst	#6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1


; Now, as explained in the theory, we take the opportunity to write the values
; in ADJACENT registers with a single “move.l”

move.l    #$01000000,$40(a5)    ; BLTCON0 + BLTCON1
move.w    #0000,$66(a5)        ; BLTDMOD
move.l    #bitplane,$54(a5)    ; BLTDPT
move.w    #(64*256)+20,$58(a5)	; try removing this line
; and the screen will not be cleared,
; so the fish will leave a ‘trail’

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

move.l    #$ffff0000,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word


move.w    d0,$40(a5)        ; BLTCON0 (use A+D)
move.w    #$0000,$42(a5)        ; BLTCON1 (no special mode)
move.l    #$fffe0024,$64(a5)    ; BLTAMOD=$fffe=-2 go back
; to the beginning of the line.
; BLTDMOD=40-4=36=$24 as usual
move.l    #figure,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.w    #(64*6)+2,$58(a5)    ; BLTSIZE (start blitter!)
; blitter 2 words, the second of
; which is cleared by the mask
; to allow shifting

btst    #6,$bfe001        ; mouse pressed?
beq.s    quit

dbra    d7,loop

Quit:
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

dc.w    $100,$1200    ; BplCon0 - 1 bitplane LowRes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; The little fish: this time we only store the words we are interested in
; the null word is created by the mask.

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

This example is a modification of the example in lesson9e3.s which, as we
explained in the lesson, allows us to avoid wasting memory on the
extra word column. In fact, our figure is only one
word wide. Nevertheless, we perform 2-word wide blits. To reset
the second word (i.e. the last one in the row), we set BLTALWM to $0000.
We then have the problem that the source pointer (channel A)
moves one word too far. To move it back, we set the source module
(BLTAMOD) to $fffe=-2.

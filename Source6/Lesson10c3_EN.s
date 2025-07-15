
; Lesson 10c3.s    Reflector effect
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #FIGURA,d0    ; point to the figure
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0    ; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

move.l    #BITPLANE4,d0    ; points the bitplane where it is drawn
move.w    d0,6(a1)    ; the mask
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse2:

Loop:
cmp.b    #$ff,$6(a5)    ; VHPOSR - wait for line $ff
bne.s    loop
Wait:
cmp.b    #$ff,$6(a5)    ; still line $ff?
beq.s    Wait

bsr.s    ClearScreen    ; clear screen
bsr.w	MoveMask    ; move spotlight position
bsr.s    Spotlight    ; effect routine

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts

;***************************************************************************
; This routine clears the portion of the screen affected by the blit
;***************************************************************************

ClearScreen:
lea    BITPLANE4+100*40,a1    ; address of area to be cleared (plane4)

btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$01000000,$40(a5)    ; BLTCON0 + BLTCON1. Clear
move.w	#$0000,$66(a5)
move.l	a1,$54(a5)
move.w	#(64*39)+20,$58(a5)
rts

;*****************************************************************************
; This routine performs the reflector effect.
; Simply, the mask is drawn on bitplane 4
;*****************************************************************************

;     ___________
;     / \
;     /\ \
;     / /\____________)____
;     \/:/\___ ___/\ \
;     \/ ___ \_/ ___ \ \
;     ( / o) ( o\ )____/
;     \\__/ /Y\ \__//
;     (___/(_n_)\___)
;     __//\ _ _ _ _ /\\__
;     /==\\_Y Y Y Y Y_//==\
;     / `-| | | | |-“ \
;    / `-^-^-^-” \

Reflector:
lea    BITPLANE4+100*40,a1    ; destination index

move.w    MaskX(PC),d0 ; reflector position
move.w    d0,d2        ; copy
and.w    #000f,d0    ; select the first 4 bits because they must be
; inserted into the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #09F0,d0    ; ...correct to be inserted into the BLTCON0 register
; note LF=$F0 (i.e. copy A to D)
lsr.w    #3,d2        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d2    ; exclude bit 0 of
add.w    d2,a1        ; add to the bitplane address, finding
; the correct destination address

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

move.l    #$ffffffff,$44(a5)    ; masks
move.w    d0,$40(a5)        ; BLTCON0
move.w    #0000,$42(a5)        ; BLTCON1 ascending mode
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #32,$66(a5)        ; BLTDMOD (40-8=32)

move.l    #Mask,$50(a5)    ; BLTAPT source pointer
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w    #(64*39)+4,$58(a5)    ; BLTSIZE (start blitter!)
; width 4 words
; height 39 lines

rts

;*****************************************************************************
; This routine reads the horizontal coordinate from a table
; and stores it in the MASCHERAX variable
;*****************************************************************************

MoveMask:
ADDQ.L    #2,TABXPOINT        ; Point to the next word
MOVE.L    TABXPOINT(PC),A0    ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0     ; Are we at the last word of the TAB?
BNE.S    NOBSTARTX        ; not yet? then continue
MOVE.L    #TABX-2,TABXPOINT     ; Start pointing from the first word-2
NOBSTARTX:
MOVE.W    (A0),MascheraX        ; copy the value to the variable
rts

MascheraX:
dc.w    0    ; current mask position
TABXPOINT:
dc.l    TABX    ; pointer to the table

; mask position table

TABX:
DC.W    $12,$16,$19,$1D,$21,$25,$28,$2C,$30,$34
DC.W    $37,$3B,$3F,$43,$46,$4A,$4E,$51,$55,$58
DC.W	$5C,$60,$63,$67,$6A,$6E,$71,$74,$78,$7B
DC.W	$7F,$82,$85,$89,$8C,$8F,$92,$95,$98,$9C
DC.W    $9F,$A2,$A5,$A8,$AA,$AD,$B0,$B3,$B6,$B8
DC.W    $BB,$BE,$C0,$C3,$C5,$C8,$CA,$CC,$CF,$D1
DC.W    $D3,$D5,$D8,$DA,$DC,$DE,$E0,$E1,$E3,$E5
DC.W    $E7,$E8,$EA,$EC,$ED,$EE,$F0,$F1,$F2,$F4
DC.W	$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FB,$FC,$FD
DC.W    $FD,$FE,$FE,$FF,$FF,$FF,$100,$100,$100,$100
DC.W    $100,$100,$100,$100,$FF,$FF,$FF,$FE,$FE,$FD
DC.W    $FD,$FC,$FB,$FB,$FA,$F9,$F8,$F7,$F6,$F5
DC.W    $F4,$F2,$F1,$F0,$EE,$ED,$EC,$EA,$E8,$E7
DC.W    $E5,$E3,$E1,$E0,$DE,$DC,$DA,$D8,$D5,$D3
DC.W    $D1,$CF,$CC,$CA,$C8,$C5,$C3,$C0,$BE,$BB
DC.W    $B8,$B6,$B3,$B0,$AD,$AA,$A8,$A5,$A2,$9F
DC.W	$9C,$98,$95,$92,$8F,$8C,$89,$85,$82,$7F
DC.W	$7B,$78,$74,$71,$6E,$6A,$67,$63,$60,$5C
DC.W	$58,$55,$51,$4E,$4A,$46,$43,$3F,$3B,$37
DC.W	$34,$30,$2C,$28,$25,$21,$1D,$19,$16,$12
FINETABX:

;*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w	$92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$4200    ; bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;primo	 bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000
dc.w $ec,$0000,$ee,$0000

Colours:
dc.w	$0180,$000	; colours from 0-7 all dark. In this way
; the parts of the figure where
; the mask is not drawn are
; coloured darker
dc.w    $0182,$011    ; colour1
dc.w    $0184,$223    ; colour2
dc.w    $0186,$122	; colour3
dc.w    $0188,$112    ; colour4
dc.w    $018a,$011    ; colour5
dc.w    $018c,$112    ; colour6
dc.w    $018e,$011    ; colour7

dc.w    $0190,$000    ; colours 8-15 contain the palette
dc.w    $0192,$475
dc.w	$0194,$fff
dc.w	$0196,$ccc
dc.w	$0198,$999
dc.w	$019a,$232
dc.w	$019c,$777
dc.w	$019e,$444

dc.w	$FFFF,$FFFE	; Fine della copperlist

;*****************************************************************************

; here is the drawing, 320 pixels wide, 256 lines high and made up of 3 planes

Figure:
incbin    ‘amiga.raw’

;*****************************************************************************

; This is the mask. It is a figure formed by a single bitplane,
; 39 lines high and 4 words wide

Mask:
dc.l    $00007fc0,$00000000,$0003fff8,$00000000,$000ffffe,$00000000
dc.l	$001fffff,$00000000,$007fffff,$c0000000,$00ffffff,$e0000000
dc.l	$01ffffff,$f0000000,$03ffffff,$f8000000,$03ffffff,$f8000000
dc.l	$07ffffff,$fc000000,$0fffffff,$fe000000,$0fffffff,$fe000000
dc.l	$1fffffff,$ff000000,$1fffffff,$ff000000,$1fffffff,$ff000000
dc.l	$3fffffff,$ff800000,$3fffffff,$ff800000,$3fffffff,$ff800000
dc.l    $3fffffff,$ff800000,$3fffffff,$ff800000,$3fffffff,$ff800000
dc.l    $3fffffff,$ff800000,$3fffffff,$ff800000,$3fffffff,$ff800000
dc.l	$1fffffff,$ff000000,$1fffffff,$ff000000,$1fffffff,$ff000000
dc.l	$0fffffff,$fe000000,$0fffffff,$fe000000,$07ffffff,$fc000000
dc.l	$03ffffff,$f8000000,$03ffffff,$f8000000,$01ffffff,$f0000000
dc.l	$00ffffff,$e0000000,$007fffff,$c0000000,$001fffff,$00000000
dc.l	$000ffffe,$00000000,$0003fff8,$00000000,$00007fc0,$00000000

;*****************************************************************************

; here is the fourth bitplane, where the mask is drawn.

SECTION    bitplane,BSS_C
BITPLANE4:
ds.b    40*256

end

;*****************************************************************************

In this example, we create a ‘reflector’ effect with the help of a
mask bitplane. The technique is as follows. We have a drawing consisting
of 3 bitplanes 320 pixels wide and 256 lines high. To create the effect,
we use a ‘mask’, which is a drawing of a circle formed by a single
bitplane. This mask is drawn and moved to a fourth bitplane,
as if it were a bob. Since it is drawn on a bitplane separate from the
figure, we don't have to worry about the background. This is basically
the same trick used in lesson9i4.s, the example of the bob with the fake background.
 This time, however, to achieve the reflector effect, we set
the colours in the registers differently: the 3-colour palette of the figure,
i.e. the values we would normally write in the COLOR00-COLOR07 registers,
are now written in the COLOR08-COLOR15 registers. Instead, the
COLOR00-COLOR07 registers are all set to darker (or black). In this way,
the pixels of the image where the fourth bitplane is set
to 0 all appear darker (we could also have blackened them all); on the
contrary, the pixels of the image where the fourth
bitplane is set to 1 (i.e. corresponding to the mask) appear
with the correct colours.
This technique is very fast but, as in the example in lesson9i4.s, it has
one disadvantage: we use 4 bitplanes for an 8-colour image.
In the next example, we will see how to avoid this problem.
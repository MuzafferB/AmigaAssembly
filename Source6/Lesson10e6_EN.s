
; Lesson 10e6.s    Optimised version of lesson 10c4.s (Reflector effect)
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE1,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #5-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0	; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5

; here the blitter is definitely stopped because it has completed startup
; so we can safely set the registers.
; The following registers are always used with the same values, so
; we initialise them once and for all at the beginning of the programme.

move.l    #$ffffffff,$44(a5)    ; BLTAFWM/BLTALWM
move.w    #$0000,$42(a5)        ; BLTCON1 ascending mode
move.l    #$00200000,$62(a5)    ; BLTBMOD (40-8=32=$20)
; BLTAMOD (=0)

MOVE.W	#DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse2:

Loop:
cmp.b    #$ff,$6(a5) ; VHPOSR - wait for line $ff
bne.s    loop
Wait:
cmp.b    #$ff,$6(a5) ; still line $ff?
beq.s    Wait

bsr.s    ClearScreen    ; clear screen
bsr.w    MoveMask    ; move reflector position
bsr.s    Reflector    ; effect routine

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts

;***************************************************************************
; This routine clears the portion of the screen affected by the blit
;***************************************************************************

ClearScreen:
moveq    #5-1,d7            ; 5 bit planes
lea    BITPLANE1+100*40,a1    ; address of area to be cleared (plane1)

move.w    #(64*39)+20,d5        ; value to write in BLTSIZE
; we put it in D5 to optimise
; writing

btst    #6,2(a5)         ; dmaconr
WBlit1a:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit1a            ; before modifying the registers

move.w    #$0100,$40(a5)        ; BLTCON0. Deletion
move.w    #$0000,$66(a5)        ; BLTDMOD these 2 registers are used
; with different values in the
; Reflector routine, so they must be
; reinitialised each time
; however, it is only necessary to do this
; once, outside the loop.

ClearLoop:
btst    #6,2(a5)         ; dmaconr
WBlit1b:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit1b            ; before blitting

move.l    a1,$54(a5)
move.w    d5,$58(a5)        ; write BLTSIZE
; the value has been previously
; written in D5

add.l    #256*40,a1        ; next plane address
dbra    d7,Clearloop
rts

;*****************************************************************************
; This routine creates the mirror effect. An
; AND operation is performed between the figure and a mask
;*****************************************************************************

;     |\_._/| |,\__/| |\__/,|
 
;     | o o | | o o| |o o |
;     ( T ) ( T ) ( T )
;     .^`-^-“^. .^`--^”^. .^`^--“^.
;     `. ; .” `. ; .“ `. ; .”
 
;     | | | | | | | | | | | | | | |
;     ((_((|))_)) ((_((|))_)) ((_((|))_))

Reflector:
moveq    #5-1,d7            ; 5 bit planes
lea    Figure+40,a0        ; figure index
lea	BITPLANE1+100*40,a1    ; destination ind.

move.w    MaskX(PC),d0 ; reflector position
move.w    d0,d2        ; copy
and.w    #$000f,d0	; select the first 4 bits because they must be
; inserted into the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #$0dc0,d0    ; ...just right to fit into the BLTCON0 register
; note LF=$C0 (i.e. AND between A and B)
lsr.w    #3,d2        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d2    ; exclude bit 0 of
add.w    d2,a0		; add to the bitplane address, finding
; the correct address in the figure
add.w    d2,a1        ; add to the bitplane address, finding
; the correct destination address

move.l    #Mask,a2        ; value to be written in BLTAPT
; (mask pointer)
; we put it in A2 to optimise
; the writing

move.w    #(64*39)+4,d5        ; value to be written in BLTSIZE
; we put it in D5 to optimise
; the writing

btst    #6,2(a5)         ; dmaconr
WBlit2a:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit2a            ; before modifying the registers

move.w    #32,$66(a5)        ; BLTDMOD (40-8=32)
move.w    d0,$40(a5)        ; BLTCON0 these 2 registers are used
; with different values in the
; ClearScreen routine, so they must be
; reinitialised each time
; however, it is only necessary to do this
; once, outside the loop.

Drawloop:
btst    #6,2(a5)         ; dmaconr
WBlit2b:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit2b            ; before blitting

move.l    a2,$50(a5)		; BLTAPT mask pointer
; the value has been previously
; written to A2
move.l    a0,$4c(a5)        ; BLTBPT figure pointer
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w    d5,$58(a5)        ; write BLTSIZE
; the value has been previously
; written in D5

add.w    #56*40,a0        ; next plane pointer figure
add.w    #256*40,a1        ; next plane pointer destination
dbra    d7,Drawloop
rts

;*****************************************************************************
; This routine reads the horizontal coordinate from a table
; and stores it in the variable MASCHERAX
;*****************************************************************************

MoveMask:
ADDQ.L    #2,TABXPOINT        ; Point to the next word
MOVE.L    TABXPOINT(PC),A0    ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0     ; Are we at the last word of TAB?
BNE.S	NOBSTARTX        ; not yet? then continue
MOVE.L    #TABX-2,TABXPOINT     ; Start pointing again from the first word-2
NOBSTARTX:
MOVE.W    (A0),MascheraX        ; copy the value to the variable
rts

MaskX:
dc.w    0    ; current mask position
TABXPOINT:
dc.l    TABX    ; pointer to the table

; mask position table

TABX:
DC.W    $12,$16,$19,$1D,$21,$25,$28,$2C,$30,$34
DC.W	$37,$3B,$3F,$43,$46,$4A,$4E,$51,$55,$58
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
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0		; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$5200    ; bplcon0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000
dc.w $ec,$0000,$ee,$0000
dc.w $f0,$0000,$f2,$0000

Colours:
dc.w	$180,0,$182,$f10,$184,$f21,$186,$f42
dc.w	$188,$f53,$18a,$f63,$18c,$f74,$18e,$f85
dc.w	$190,$f96,$192,$fa6,$194,$fb7,$196,$fb8
dc.w	$198,$fc9,$19a,$f21,$19c,$f10,$19e,$f00
dc.w	$1a0,$eff,$1a2,$eff,$1a4,$dff,$1a6,$dff
dc.w    $1a8,$cff,$1aa,$bef,$1ac,$bef,$1ae,$adf
dc.w    $1b0,$9df,$1b2,$9cf,$1b4,$8bf,$1b6,$7bf
dc.w    $1b8,$7af,$1ba,$69f,$1bc,$68f,$1be,$57f

dc.w	$FFFF,$FFFE	; Fine della copperlist

;*****************************************************************************

; here is the design, 320 pixels wide, 56 lines high and consisting of 5 planes

Figure:
incbin    lava320*56*5.raw

;*****************************************************************************

; This is the mask. It is a figure made up of a single bitplane,
; 39 lines high and 4 words wide

Mask:
dc.l    $00007fc0,$00000000,$0003fff8,$00000000,$000ffffe,$00000000
dc.l	$001fffff,$00000000,$007fffff,$c0000000,$00ffffff,$e0000000
dc.l	$01ffffff,$f0000000,$03ffffff,$f8000000,$03ffffff,$f8000000
dc.l	$07ffffff,$fc000000,$0fffffff,$fe000000,$0fffffff,$fe000000
dc.l	$1fffffff,$ff000000,$1fffffff,$ff000000,$1fffffff,$ff000000
dc.l    $3fffffff,$ff800000,$3fffffff,$ff800000,$3fffffff,$ff800000
dc.l    $3fffffff,$ff800000,$3fffffff,$ff800000,$3fffffff,$ff800000
dc.l    $3fffffff,$ff800000,$3fffffff,$ff800000,$3fffffff,$ff800000
dc.l	$1fffffff,$ff000000,$1fffffff,$ff000000,$1fffffff,$ff000000
dc.l	$0fffffff,$fe000000,$0fffffff,$fe000000,$07ffffff,$fc000000
dc.l	$03ffffff,$f8000000,$03ffffff,$f8000000,$01ffffff,$f0000000
dc.l	$00ffffff,$e0000000,$007fffff,$c0000000,$001fffff,$00000000
dc.l	$000ffffe,$00000000,$0003fff8,$00000000,$00007fc0,$00000000

;*****************************************************************************

SECTION	bitplane,BSS_C
BITPLANE1:
ds.b	40*256
BITPLANE2:
ds.b    40*256
BITPLANE3:
ds.b    40*256
BITPLANE4:
ds.b    40*256
BITPLANE5:
ds.b    40*256

end

;*****************************************************************************

This example is the optimised version of lesson10c4.s. The optimisations
are explained in the listing.


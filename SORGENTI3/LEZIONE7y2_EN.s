
; lesson7y2.s    vertical bars

;     In this example, we use two sprites to make vertical bars.

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)	; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

;    Point to the ‘empty’ PIC

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

;    DO NOT point to the sprite!!!!!!!!!!!!!!!!!!!!

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    MoveSprite    ; Moves sprites 0 and 1 horizontally, but
; acting on the MOVE of the COPPERLIST, given
; that we display them through the direct registers
;.

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr    -$19e(a6)    ; Close library
rts

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:
dc.l    0

OldCop:
dc.l    0

; This routine moves the sprites by acting on the copperlist, modifying
; the value bar1 that is loaded into the SPRxPOS register, i.e.
; the byte of the X position, entering the coordinates already established
; in the TABX table

MuoviSprite:
ADDQ.L	#2,TABXPOINT     ; Point to the next byte
MOVE.L    TABXPOINT(PC),A0 ; address contained in loong TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTART    ; Not yet? Then continue
MOVE.L    #TABX-2,TABXPOINT ; Start pointing to the first long again
NOBSTART:
MOVE.w    (A0),d1

add.w    #128,D1        ; 128 - to centre the sprite.
btst.l    #0,D1        ; low bit of the X coordinate reset?
beq.s    BitLowZERO
bset.b    #0,bar1_b    ; Set the low bit of the bar
bra.s    PlaceCoords

BitLowZERO:
bclr.b    #0,bar1_b    ; Reset the low bit of the bar
PlaceCoords:
lsr.w    #1,D1		; SHIFT, i.e. move 1 bit to the right

move.b    D1,bar1        ; Place the value XX in the position byte

ADDQ.L    #2,TABXPOINT2     ; Point to the next byte
MOVE.L    TABXPOINT2(PC),A0 ; address contained in loong TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTART2    ; not yet? then continue
MOVE.L    #TABX-2,TABXPOINT2 ; Start pointing from the first long again
NOBSTART2:
MOVE.w    (A0),d1
add.w    #128,D1        ; 128 - to centre the sprite.
btst.l    #0,D1        ; low bit of the X coordinate reset?
beq.s    BitBassoZERO2
bset.b    #0,bar2_b    ; Set the low bit of the bar
bra.s    PlaceCoords2

BitLowZERO2:
bclr.b    #0,bar2_b    ; Reset the low bit of the bar
PlaceCoords2:
lsr.w    #1,D1        ; SHIFT, i.e. move 1 bit to the right

move.b    D1,bar2        ; Place the value XX in the position byte
rts

TABXPOINT:
dc.l    TABX-2

TABXPOINT2:            ; the pointer for the second sprite is different
dc.l    TABX+40-2

; Table with precalculated X coordinates of the sprite.

TABX:
incbin    ‘XCOORDINATEK.TAB’

FINETABX:

SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w $100,%0001001000000000 ; bit 12 on!! 1 lowres bitplane

BPLPOINTERS:
dc.w $e0,0,$e2,0 ; first bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$FF0    ; colour17, i.e. COLOUR1 of sprite0 - YELLOW
dc.w    $1A4,$a00    ; colour18, i.e. COLOUR2 of sprite0 - RED
dc.w    $1A6,$F70    ; colour19, i.e. COLOUR3 of sprite0 - ORANGE


dc.w    $2c07,$fffe    ; WAIT - wait for the top edge

dc.w    $140        ; SPR0POS
dc.b    0        ; vertical position (not used)
bar1:    dc.b 0        ; horizontal position
dc.w    $142        ; SPR0CTL
dc.b    0        ; VSTOP (not used)
bar1_b:    dc.b    0
		; fourth control byte: bit 0 is used, which is the low bit of the horizontal position
;

dc.w    $146,$0e70    ; SPR0DATB
dc.w    $144,$03c0    ; SPR0DATA - activates the sprite

dc.w    $148        ; SPR1POS
dc.b    0
bar2:    dc.b    0        ; horizontal position
dc.w    $14a        ; SPR1CTL
dc.b    0
bar2_b:    dc.b    0
dc.w    $14e,$3e7c    ; SPR1DATB
dc.w    $14c,$0ff0;db0	
; SPR1DATA - activates the sprite


dc.w    $FFFF,$FFFE    ; End of the copperlist



SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end


Note that since the columns are as high as the entire screen, it is not necessary
to write to the SPRxCTL registers to disable sprites.

Insert this piece of copperist just before ‘dc.w $FFFF,$FFFE’ to
add a touch of colour to the listing. (Amiga+b+c+i)

dc.w    $5407,$fffe    ; WAIT
dc.w    $1A2,$FaF    ; colour17	; purple tone
dc.w    $1A4,$703    ; colour18
dc.w    $1A6,$F0a    ; colour19
dc.w    $6807,$fffe    ; WAIT
dc.w    $1A2,$aFa    ; colour17    ; green tone
dc.w    $1A4,$050    ; colour18
dc.w    $1A6,$0a0    ; colour19
dc.w    $7c07,$fffe    ; WAIT
dc.w    $1A2,$0FF    ; colour17    ; blue tone
dc.w    $1A4,$00d    ; colour18
dc.w    $1A6,$07F    ; colour 19
dc.w    $9007,$fffe    ; WAIT
dc.w    $1A2,$eee    ; colour 17    ; grey tone
dc.w    $1A4,$444    ; colour 18
dc.w    $1A6,$888    ; colour 19

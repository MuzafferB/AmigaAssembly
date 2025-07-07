
; Lesson 7p.s - example of application of the universal routine:
;     4 SPRITES IN 4 COLOURS PLACED SIDE BY SIDE TO FORM A FIGURE
;        64 PIXELS WIDE.
;         USING TWO PRE-ESTABLISHED TABLES OF VALUES (i.e. vertical
;        and horizontal coordinates).

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
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

;    Point to 4 sprites


MOVE.L    #MIOSPRITE,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE1,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE2,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE3,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!


Mouse1:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    Mouse1

bsr.w    MoveSprites    ; moves all sprites

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s	Wait

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse1

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop


move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr    -$19e(a6)    ; Closelibrary
rts

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:
dc.l    0

OldCop:
dc.l    0


; This routine reads the coordinates of sprite 0 from the table, moves it
; using the Universal routine we saw in lesson 7m, and then moves
; the other sprites as well. The other sprites will have the same vertical coordinate
; as the first one and will be placed side by side, 16 pixels apart.
; the horizontal position of sprite 1 is 16 pixels to the right of sprite 0
; the horizontal position of sprite 2 is 16 pixels to the right of sprite 1
; the horizontal position of sprite 3 is 16 pixels to the right of sprite 2

MoveSprites:
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L	TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S    NOBSTARTY    ; not yet? then continue
MOVE.L    #TABY-1,TABYPOINT ; Start pointing from the first byte again
NOBSTARTY:
moveq    #0,d4        ; Clear d4
MOVE.b    (A0),d4        ; Copy the byte from the table to d4
; so that it can be found by the
; universal

ADDQ.L    #1,TABXPOINT
MOVE.L    TABXPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-1,A0
BNE.S    NOBSTARTX
MOVE.L    #TABX-1,TABXPOINT
NOBSTARTX:
moveq    #0,d3		; reset d3
MOVE.b    (A0),d3    ; set the table value in d3

moveq    #15,d2        ; sprite height: it is the same for
; all 4, so we put it in d2
; once and for all!

lea    MIOSPRITE,A1    ; sprite address 0
move.w    d4,d0        ; put the coordinates in the registers
move.w    d3,d1
bsr.w    UniMuoviSprite    ; executes the universal routine that positions
; the sprite

lea    MIOSPRITE1,A1    ; sprite address 1
add.w	#16,d3        ; sprite 1 16 pixels to the right of sprite 0
move.w    d4,d0        ; put the coordinates in the registers
move.w    d3,d1
bsr.w    UniMuoviSprite    ; execute the universal routine that positions
; the sprite

lea    MIOSPRITE2,A1	; sprite address 2
add.w    #16,d3        ; sprite 2 16 pixels to the right of sprite 1
move.w    d4,d0        ; put the coordinates in the registers
move.w    d3,d1
bsr.w    UniMoveSprite    ; execute the universal routine that positions
; the sprite

lea    MIOSPRITE3,A1    ; sprite address 3
add.w	#16,d3        ; sprite 3 16 pixels to the right of sprite 2
move.w    d4,d0        ; put the coordinates in the registers
move.w    d3,d1
bsr.w    UniMoveSprite    ; execute the universal routine that positions
; the sprite
rts


TABYPOINT:
dc.l    TABY-1        ; NOTE: the values in the table here are bytes,
; so we work with an ADDQ.L #1,TABYPOINT
; and not #2 as when they are words or with #4
; as when they are longwords.
TABXPOINT:
dc.l    TABX-1        ; NOTE: the values in the table here are bytes

; Table with precalculated Y coordinates of the sprite.
; Note that the Y position for the sprite to enter the video window
; must be between $0 and $ff, because the $2c offset is added
; by the routine. If you are not using overscan screens, i.e. no longer than
; 255 lines, you can use a table of dc.b values (from $00 to $FF)

TABY:
incbin    ‘ycoordinatok.tab’    ; 200 values .B
FINETABY:


; Table with precalculated X coordinates of the leftmost sprite.
; This table contains real values, without the offsets that are added
; automatically by the universal routine.
; Since the 4 sprites together form a 64-pixel wide figure, the
; leftmost sprite can vary its horizontal position between 0 and 
; 319-64=255. This allows us to use bytes instead of words for this table
; as well
; The table is always made with
; IS
; beg>0
; end>360
; amount>300
; amp>255/2
; y_offset>255/2
; multiplier>1

TABX:
DC.B    $80,$83,$86,$88,$8B,$8E,$90,$93,$95,$98,$9B,$9D,$A0,$A2,$A5,$A8
DC.B    $AA,$AD,$AF,$B1,$B4,$B6,$B9,$BB,$BD,$C0,$C2,$C4,$C6,$C9,$CB,$CD
DC.B	$CF,$D1,$D3,$D5,$D7,$D9,$DB,$DC,$DE,$E0,$E2,$E3,$E5,$E7,$E8,$EA
DC.B    $EB,$EC,$EE,$EF,$F0,$F1,$F2,$F4,$F5,$F6,$F6,$F7,$F8,$F9,$FA,$FA
DC.B    $FB,$FB,$FC,$FC,$FD,$FD,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FD
DC.B    $FD,$FD,$FC,$FC,$FB,$FB,$FA,$FA,$F9,$F8,$F7,$F6,$F6,$F5,$F4,$F2
DC.B	$F1,$F0,$EF,$EE,$EC,$EB,$EA,$E8,$E7,$E5,$E3,$E2,$E0,$DE,$DC,$DB
DC.B	$D9,$D7,$D5,$D3,$D1,$CF,$CD,$CB,$C9,$C6,$C4,$C2,$C0,$BD,$BB,$B9
DC.B    $B6,$B4,$B1,$AF,$AD,$AA,$A8,$A5,$A2,$A0,$9D,$9B,$98,$95,$93,$90
DC.B	$8E,$8B,$88,$86,$83,$80,$7E,$7B,$78,$76,$73,$70,$6E,$6B,$69,$66
DC.B	$63,$61,$5E,$5C,$59,$56,$54,$51,$4F,$4D,$4A,$48,$45,$43,$41,$3E
DC.B	$3C,$3A,$38,$35,$33,$31,$2F,$2D,$2B,$29,$27,$25,$23,$22,$20,$1E
DC.B	$1C,$1B,$19,$17,$16,$14,$13,$12,$10,$0F,$0E,$0D,$0C,$0A,$09,$08
DC.B	$08,$07,$06,$05,$04,$04,$03,$03,$02,$02,$01,$01,$01,$00,$00,$00
DC.B	$00,$00,$00,$00,$00,$01,$01,$01,$02,$02,$03,$03,$04,$04,$05,$06
DC.B	$07,$08,$08,$09,$0A,$0C,$0D,$0E,$0F,$10,$12,$13,$14,$16,$17,$19
DC.B	$1B,$1C,$1E,$20,$22,$23,$25,$27,$29,$2B,$2D,$2F,$31,$33,$35,$38
DC.B	$3A,$3C,$3E,$41,$43,$45,$48,$4A,$4D,$4F,$51,$54,$56,$59,$5C,$5E
DC.B	$61,$63,$66,$69,$6B,$6E,$70,$73,$76,$78,$7B,$7E
FINETABX:



; Universal sprite positioning routine.

;
;    Input parameters for UniMoveSprite:
;
;    a1 = Sprite address
;    d0 = Vertical position Y of the sprite on the screen (0-255)
;    d1 = Horizontal position X of the sprite on the screen (0-320)
;    d2 = Height of the sprite
;

UniMoveSprite:
; vertical positioning
ADD.W    #$2c,d0        ; add the offset of the start of the screen

; a1 contains the address of the sprite
MOVE.b    d0,(a1)        ; copy the byte to VSTART
btst.l    #8,d0
beq.s    NonVSTARTSET
bset.b    #2,3(a1)    ; Set bit 8 of VSTART (number > $FF)
bra.s    ToVSTOP
NonVSTARTSET:
bclr.b    #2,3(a1)    ; Clear bit 8 of VSTART (number < $FF)
ToVSTOP:
ADD.w    D2,D0		; Add the sprite height to
; determine the final position (VSTOP)
move.b    d0,2(a1)    ; Move the correct value to VSTOP
btst.l    #8,d0
beq.s    NonVSTOPSET
bset.b    #1,3(a1)    ; Set bit 8 of VSTOP (number > $FF)
bra.w    VstopFIN
NonVSTOPSET:
bclr.b    #1,3(a1)    ; Reset bit 8 of VSTOP (number < $FF)
VstopFIN:

; horizontal positioning
add.w    #128,D1        ; 128 - to centre the sprite.
btst    #0,D1        ; low bit of X coordinate reset?
beq.s    BitBassoZERO
bset    #0,3(a1)    ; Set the low bit of HSTART
bra.s    PlaceCoords

BitBassoZERO:
bclr    #0,3(a1)    ; Reset the low bit of HSTART
PlaceCoords:
lsr.w    #1,D1        ; SHIFT, i.e. move 1 bit to the right
; the value of HSTART, to ‘transform’ it into
; the value to be placed in the HSTART byte, without
; the low bit.
move.b    D1,1(a1)    ; We place the value XX in the HSTART byte
rts


SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w    $12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0001001000000000    ; bit 12 on!! 1 lowres bitplane

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

;    PIC palette

dc.w    $180,$000    ; colour0	; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

;    SPRITE palette

dc.w    $1A2,$800    ; colour17
dc.w    $1A4,$d00    ; colour18
dc.w    $1A6,$cc0    ; colour19

; the colours for sprites 2 and 3 are the same as for sprites 0 and 1
dc.w    $1AA,$800    ; colour21
dc.w    $1AC,$d00    ; colour22
dc.w    $1AE,$cc0    ; colour23

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here are the sprites: OBVIOUSLY in CHIP RAM! **********

MIOSPRITE:                ; length 15 lines
incbin    ‘Largesprite0.raw’

MIOSPRITE1:                ; length 15 lines
incbin    ‘Largesprite1.raw’

MIOSPRITE2:                ; length 15 lines
incbin    ‘Largesprite2.raw’

MIOSPRITE3:                ; length 15 lines
incbin    ‘Largesprite3.raw’


SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

In this listing, we use 4 sprites with 4 colours to create a
64-pixel-wide figure. The sprites are aligned horizontally. Therefore, they
all have the same vertical position, while horizontally they are 16 pixels
apart from each other.
From the tables we read the position of the first sprite, while for the others
we use the same vertical coordinate and add 16 pixels to
the horizontal one each time.
Note the convenience of having a universal routine: to move the sprites
we always use the same routine, only each time we put a different
address in a1 and different coordinates in registers d0 and d1. In this case
the height is always the same, so we do not change d2. However, if we
needed to move sprites of different heights, there would be no problem;
we would just need to change d2 and always use the same universal routine.
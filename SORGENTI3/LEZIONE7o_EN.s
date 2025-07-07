
; Lesson 7o.s - example of application of the universal routine:
;        two sprites moved by the same routine


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

MOVE.L	#BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

;    Point to the sprite

MOVE.L    #MIOSPRITE,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

addq.l    #8,a1            ; pointer to sprite 1
MOVE.L    #MIOSPRITE2,d0        ; sprite address in d0
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$aa,$dff006    ; Line $aa?
bne.s    mouse

btst    #2,$dff016
beq.s    wait
bsr.w    MoveSprite    ; Move sprite 0

Wait:
cmpi.b    #$aa,$dff006    ; line $aa?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

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


; This routine reads the actual coordinates of the sprites from the two tables.
; That is, the X coordinate varies from 0 to 320 and the Y coordinate from 0 to 256 (without overscan).
; Since we are not using overscan in this example, the Y coordinate table
; is a byte table. The X coordinate table, on the other hand, is made
; of words because it must also contain values greater than 256.
; However, this routine does not position the sprite directly. It simply
; lets the universal routine do it, communicating the
; coordinates via registers d0 and d1

MoveSprite:
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L    TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S    NOBSTARTY    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT ; Start pointing to the first byte again
NOBSTARTY:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the table byte, i.e. the
; Y coordinate in d0 so that it can be
; found by the universal routine

ADDQ.L    #2,TABXPOINT     ; Point to the next word
MOVE.L    TABXPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last word of the TAB?
BNE.S    NOBSTARTX    ; Not yet? Then continue
MOVE.L    #TABX-2,TABXPOINT ; Start pointing to the first word-2 again
NOBSTARTX:
moveq    #0,d1        ; reset d1
MOVE.w    (A0),d1        ; set the table value, i.e.
; the X coordinate in d1

lea    MIOSPRITE,a1    ; address of the sprite in A1
moveq    #13,d2        ; height of the sprite in d2

bsr.w    UniMuoviSprite ; executes the universal routine that positions
; the sprite
; second sprite

ADDQ.L    #1,TABYPOINT2     ; Point to the next byte
MOVE.L    TABYPOINT2(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S    NOBSTARTY2    ; Not yet? Then continue
MOVE.L	#TABY-1,TABYPOINT2 ; Start pointing to the first byte again
NOBSTARTY2:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the table byte, i.e. the
; Y coordinate in d0 so that it can be
; found by the universal routine

ADDQ.L	#2,TABXPOINT2     ; Point to the next word
MOVE.L    TABXPOINT2(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last word of the TAB?
BNE.S    NOBSTARTX2    ; Not yet? Then continue
MOVE.L	#TABX-2,TABXPOINT2 ; Start pointing to the first word-2
NOBSTARTX2:
moveq    #0,d1        ; reset d1
MOVE.w    (A0),d1        ; set the table value, i.e.
; the X coordinate in d1

lea    MIOSPRITE2,a1    ; address of the sprite in A1
moveq    #8,d2        ; height of the sprite in d2

bsr.w    UniMuoviSprite ; executes the universal routine that positions
; the sprite
rts

; pointers to the tables of the first sprite

TABYPOINT:
dc.l    TABY-1
TABXPOINT:
dc.l    TABX-2

; pointers to the tables of the second sprite

TABYPOINT2:
dc.l    TABY+40-1
TABXPOINT2:
dc.l    TABX+96-2

; Table with precalculated Y coordinates of the sprite.
TABY:
incbin    ‘ycoordinatok.tab’    ; 200 values .B
FINETABY:

; Table with precalculated X coordinates of the sprite.
TABX:
incbin    ‘xcoordinatok.tab’    ; 150 values .W
FINETABX:

; Universal routine for positioning sprites.

;
;    Input parameters for UniMuoviSprite:
;
;    a1 = Sprite address
;    d0 = vertical position Y of the sprite on the screen (0-255)
;    d1 = horizontal position X of the sprite on the screen (0-320)
;    d2 = height of the sprite
;

UniMuoviSprite:
; vertical positioning
ADD.W    #$2c,d0        ; add the offset of the start of the screen

; a1 contains the sprite address
MOVE.b    d0,(a1)        ; copy the byte to VSTART
btst.l    #8,d0
beq.s    NonVSTARTSET
bset.b    #2,3(a1)    ; Set bit 8 of VSTART (number > $FF)
bra.s    ToVSTOP
NonVSTARTSET:
bclr.b    #2,3(a1)    ; Reset bit 8 of VSTART (number < $FF)
ToVSTOP:
ADD.w    D2,D0        ; Add the height of the sprite to
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
bclr    #0,3(a1)	; Reset the low bit of HSTART
PlaceCoords:
lsr.w    #1,D1        ; SHIFT, i.e. move 1 bit to the right
; the value of HSTART, to ‘transform’ it into
; the value to be placed in the HSTART byte, without
; the low bit.
move.b    D1,1(a1)	; Set the value XX in the HSTART byte
rts


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
dc.w    $100,%0001001000000000    ; bit 12 on!! 1 lowres bitplane

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$F00    ; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w    $1A4,$0F0    ; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w    $1A6,$FF0	
; colour19, i.e. COLOUR3 of sprite0 - YELLOW

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE:        ; length 13 lines
dc.b $50    ; Vertical position of sprite start (from $2c to $f2)
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
dc.b $5d    ; $50+13=$5d    ; vertical position of sprite end
dc.b $00
dc.w    %0000000000000000,%0000110000110000 ; Binary format for modifications
dc.w    %0000000000000000,%0000011001100000
dc.w	%0000000000000000,%0000001001000000
dc.w	%0000000110000000,%0011000110001100 ;BINARY 00=COLOUR 0 (TRANSPARENT)
dc.w    %0000011111100000,%0110011111100110 ;BINARY 10=COLOUR 1 (RED)
dc.w    %0000011111100000,%1100100110010011 ;BINARY 01=COLOUR 2 (GREEN)
dc.w	%0000110110110000,%1111100110011111 ;BINARIO 11=COLORE 3 (GIALLO)
dc.w	%0000011111100000,%0000011111100000
dc.w	%0000011111100000,%0001111001111000
dc.w	%0000001111000000,%0011101111011100
dc.w	%0000000110000000,%0011000110001100
dc.w	%0000000000000000,%1111000000001111
dc.w    %0000000000000000,%1111000000001111
dc.w    0,0    ; 2 words set to zero define the end of the sprite.


MIOSPRITE2:        ; length 8 lines
VSTART2:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART2:
dc.b $60+(14*2)    ; Horizontal position (from $40 to $d8)
VSTOP2:
dc.b $68    ; $60+8=$68    ; vertical end.
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000111001111
dc.w	%0011111111111100,%1100001000100011
dc.w	%0111111111111110,%1000000000100001
dc.w	%0111111111111110,%1000000111000001
dc.w	%0011111111111100,%1100001000000011
dc.w    %0000111111110000,%1111001111101111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite


SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256		; reset bitplane lowres

end

In this example, we show the versatility of the UniMuoviSprite routine.
We have two sprites of different shapes and heights, and both are moved on the 
screen by the routine. In fact, the Muovisprite routine reads the
coordinates of the sprites from the tables and then calls the
UniMuoviSprite routine for each of the sprites. Note how each time the MuoviSprite routine puts
the address of the sprite (which is obviously different for the two
sprites) in the a1 register. Furthermore, since the two sprites have different heights, before calling
UnMuoviSprite, a different value is put in d2 each time, i.e. the
height of each sprite.
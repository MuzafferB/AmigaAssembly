
; Lesson 7n.s - example of application of the universal routine:
;        a bouncing sprite


SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1	; Lib name
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

;    Point to the sprite

MOVE.L    #MIOSPRITE,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088		; START COP
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

move.l	OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr    -$19e(a6)	; Close library
rts

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:
dc.l    0

OldCop:
dc.l    0

; This routine changes the sprite coordinates by adding a constant speed
; both vertically and horizontally. Furthermore, when the sprite touches
; one of the edges, the routine reverses the direction.
; To understand this routine, you need to know that the ‘NEG’ instruction
; is used to convert a positive number to a negative number and vice versa.

MoveSprite:
move.w    sprite_y(PC),d0    ; read the old position
add.w    speed_y(PC),d0	; add speed
btst    #15,d0        ; if bit 15 is set, the number has
; become negative. Has it become negative?
beq.s    no_touch_top    ; if >0, it's OK
neg.w    speed_y        ; if <0, we have touched the top edge
; then reverse the direction
bra.s	MoveSprite    ; recalculate the new position

no_touch_top:
cmp.w    #243,d0    ; when the position is 256-13=243, the sprite
; touches the bottom edge
blo.s    no_touch_bottom
neg.w    speed_y        ; if the sprite touches the lower edge,
; reverse the speed
bra.s    MoveSprite    ; recalculate the new position

no_touch_below:
move    d0,sprite_y    ; update the position
posiz_x:
move.w    sprite_x(PC),d1	; read the old position
add.w    speed_x(PC),d1    ; add the speed
btst    #15,d0        ; if bit 15 is set, the number has
; become negative. Has it become negative?
beq.s    no_touch_left
neg.w    speed_x        ; if <0, it touches the left: reverse the direction
bra.s    posiz_x        ; recalculate new horizontal position

no_touch_left:
cmp.w    #304,d1	; when the position is 320-16=304, the sprite
; touches the right edge
blo.s    no_touch_right
neg.w    speed_x        ; if it touches the right, reverse the direction
bra.s    posiz_x        ; recalculate new horizontal position

no_touch_right:
move.w    d1,sprite_x    ; update position

lea    miosprite,a1    ; sprite address
moveq    #13,d2        ; sprite height
bsr.s    UniMuoviSprite ; executes the universal routine that positions
; the sprite
rts

SPRITE_Y:
DC.W    10    ; sprite position
SPRITE_X:
DC.W    0
SPEED_Y:
dc.w    -4        ; sprite speed
SPEED_X:
dc.w    3

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
ADD.w    D2,D0        ; Add the sprite height to
; determine the final position (VSTOP)
move.b    d0,2(a1)    ; Move the correct value to VSTOP
btst.l    #8,d0
beq.s    NonVSTOPSET
bset.b    #1,3(a1)	; Set bit 8 of VSTOP (number > $FF)
bra.w    VstopFIN
NonVSTOPSET:
bclr.b    #1,3(a1)    ; Clear bit 8 of VSTOP (number < $FF)
VstopFIN:

; horizontal positioning
add.w    #128,D1		; 128 - to centre the sprite.
btst    #0,D1        ; low bit of the X coordinate reset?
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
dc.w    $102,0		; BplCon1
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
dc.w    $1A6,$FF0    ; colour19, i.e. COLOUR3 of sprite0 - YELLOW

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
dc.w    %0000110110110000,%1111100110011111 ;BINARIO 11=COLORE 3 (GIALLO)
dc.w	%0000011111100000,%0000011111100000
dc.w	%0000011111100000,%0001111001111000
dc.w	%0000001111000000,%0011101111011100
dc.w	%0000000110000000,%0011000110001100
dc.w	%0000000000000000,%1111000000001111
dc.w	%0000000000000000,%1111000000001111
dc.w    0,0    ; 2 words set to zero define the end of the sprite.


SECTION    PLANEVUOTO,BSS_C    ; The bitplane we use, set to zero,
; because in order to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; lowres reset bitplane

end

In this example, we show a different way of moving sprites without
using tables.
In this example, our sprite moves in a straight line, with constant speed
for both the horizontal and vertical positions.
The speed is simply a number contained in a memory location,
which is added each time to the position previously occupied by the sprite,
 thus calculating the new position.
If the speed is a positive number, the position of the sprite will increase each time,
 moving it to the right (or down in the case of Y).
If the speed is a negative number, the position of the sprite will decrease each time,
 moving it to the left (or up in the case of Y).
When the sprite touches one of the edges, it is necessary to reverse the direction
in which it is moving. To do this, simply change the sign of the
speed, i.e. change it from positive to negative or vice versa.
This is done by the NEG instruction, which changes the sign of a number
contained in a register or memory location.
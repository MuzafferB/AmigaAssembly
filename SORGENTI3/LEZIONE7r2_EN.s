
; Lesson 7r2.s    A SPRITE MOVED WITH THE MOUSE THAT REACHES THE RIGHT EDGE



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

;    Point to the sprite

MOVE.L    #MIOSPRITE,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

move.b    $dff00a,mouse_y
move.b    $dff00b,mouse_x

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    ReadMouse    ; this reads the mouse
move.w    sprite_y(pc),d0 ; prepares the parameters for the routine
move.w    sprite_x(pc),d1 ; universal
lea    miosprite,a1    ; sprite address
moveq    #13,d2        ; sprite height
bsr.w    UniMuoviSprite    ; call the universal routine

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)	; Enable
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

; This routine reads the mouse and updates the values contained in the
; variables sprite_x and sprite_y

ReadMouse:
move.b    $dff00a,d1    ; JOY0DAT vertical mouse position
move.b    d1,d0        ; copy to d0
sub.b    mouse_y(PC),d0    ; subtract old mouse position
beq.s    no_vert        ; if the difference = 0, the mouse is stationary
ext.w    d0        ; transforms the byte into a word
; (see at the end of the listing)
add.w    d0,sprite_y    ; modifies the sprite position
no_vert:
move.b    d1,mouse_y    ; saves the mouse position for next time

move.b    $dff00b,d1    ; horizontal mouse position
move.b    d1,d0        ; copy to d0
sub.b    mouse_x(PC),d0    ; subtract old position
beq.s    no_oriz        ; if the difference = 0, the mouse is stationary
ext.w    d0		; convert byte to word
; (see end of listing)
add.w    d0,sprite_x    ; change sprite position
no_oriz
move.b    d1,mouse_x    ; save mouse position for next time
RTS

SPRITE_Y:    dc.w    0    ; the Y position of the sprite is stored here
SPRITE_X:    dc.w    0    ; the X of the sprite is stored here
MOUSE_Y:    dc.b    0    ; the Y of the mouse is stored here
MOUSE_X:    dc.b    0    ; the X of the mouse is stored here




; Universal sprite positioning routine.

;
;	Input parameters of UniMuoviSprite:
;
;    a1 = Sprite address
;    d0 = Vertical position Y of the sprite on the screen (0-255)
;    d1 = Horizontal position X of the sprite on the screen (0-320)
;    d2 = Height of the sprite
;

UniMuoviSprite:
; Vertical positioning
ADD.W    #$2c,d0        ; add the offset of the start of the screen

; a1 contains the address of the sprite
MOVE.b    d0,(a1)        ; copy the byte to VSTART
btst.l    #8,d0
beq.s    NonVSTARTSET
bset.b    #2,3(a1)	; Set bit 8 of VSTART (number > $FF)
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
btst    #0,D1        ; low bit of the X coordinate reset?
beq.s    BitBassoZERO
bset    #0,3(a1)    ; Set the low bit of HSTART
bra.s    PlaceCoords

BitBassoZERO:
bclr    #0,3(a1)    ; Reset the low bit of HSTART
PlaceCoords:
lsr.w    #1,D1        ; SHIFT, i.e. move 1 bit to the right
; the value of HSTART, to ‘transform’ it into
; the value to be placed in the HSTART byte, i.e. without
; the low bit.
move.b    D1,1(a1)    ; Set the value XX in the HSTART byte
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
dc.w $e0,0,$e2,0    ;first bitplane

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
VSTART:
dc.b $50    ; Vertical position of sprite start (from $2c to $f2)
HSTART:
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP:
dc.b $5d	; $50+13=$5d    ; vertical position of sprite end
VHBITS:
dc.b $00    ; bit

dc.w    %0000000000000000,%0000110000110000 ; Formato binario per modifiche
dc.w	%0000000000000000,%0000011001100000
dc.w	%0000000000000000,%0000001001000000
dc.w    %0000000110000000,%0011000110001100 ;BINARY 00=COLOUR 0 (TRANSPARENT)
dc.w    %0000011111100000,%0110011111100110 ;BINARY 10=COLOUR 1 (RED)
dc.w    %0000011111100000,%1100100110010011 ;BINARY 01=COLOUR 2 (GREEN)
dc.w    %0000110110110000,%1111100110011111 ;BINARY 11=COLOUR 3 (YELLOW)
dc.w    %0000011111100000,%0000011111100000
dc.w	%0000011111100000,%0001111001111000
dc.w	%0000001111000000,%0011101111011100
dc.w	%0000000110000000,%0011000110001100
dc.w	%0000000000000000,%1111000000001111
dc.w    %0000000000000000,%1111000000001111
dc.w    0,0    ; 2 words set to zero define the end of the sprite.


SECTION    PLANEVUOTO,BSS_C    ; The zeroed bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; zeroed bitplane lowres

end

In this example we move a sprite with the mouse so as to reach
the right edge and not have problems with a possible vertical overscan.

If we want to reach the right edge, we must use a word for the
horizontal position of the sprite. However, the mouse provides us with
coordinates in byte form. So we use the following method:
we store the sprite coordinates and the coordinates provided
by the mouse separately. 
Each time we execute LeggiMouse, we read new
coordinates and compare them with the old ones. We calculate the difference between the
old and new mouse coordinates and add this difference to the
coordinates of the sprite. This way, it doesn't matter that when
the mouse position exceeds 255, it returns to 0, because all that matters is
the difference between the new and old coordinates. Remember that if
a byte takes a value from 128 to 255, when we use it in an addition or 
subtraction, it is considered a negative number in two's complement.
So if the old coordinate is 255, and the new one is 1, the
difference 255 (=$ff) is considered -1. Therefore, 1-(-1)=2.
This number 2 is added to the x coordinate of the sprite and, since it is
positive, it causes a shift to the right.
If, on the other hand, the difference had been negative, adding it to the x coordinate
of the sprite would have caused a shift to the left.
However, there is one detail that needs to be paid close attention to. When
we calculate the difference between the mouse coordinates, we are working with two
bytes. Therefore, the difference will still be one byte. We then add this byte
to the sprite coordinate, which is a word. This causes a problem.
Before adding, we need to convert the byte into a word.
This conversion is done by the EXT instruction, which converts a byte
contained in a register into a word. Let's see how this instruction works.
There are two cases:
The byte contains a positive number, e.g. 5. EXT converts it as follows:

Content before EXT    Content after EXT
$XX05                $0005
(XX indicates any number)

In fact, 5 in word format is written as $0005

The byte contains a negative number, e.g. -5. EXT transforms it as follows:
Remembering that -5 in byte format is written as $FB

Content before EXT    Content after EXT
$XXFB                $FFFB
(XX indicates any number)

In fact, -5 in word format is written as $FFFB.

In practice, EXT takes bit 7 of a register (the bit that indicates the sign)
and copies it to bits 8 to 15.
Although it is not used in this example, please note that to convert a word
into a long word, the EXT instruction is always used, only in .L format:

EXT.L d0    ; converts a word into a long word

The conversion takes place in the same way.

The same applies to vertical positions, and
in fact the routine is identical.

To position the sprite on the screen, we use the universal routine again,
which we already have ready. You will realise that even the routines that
manage mouse and joystick readings can be used in any
program that manages the joystick and mouse. In fact, game and demo programmers
reuse most of the routines.

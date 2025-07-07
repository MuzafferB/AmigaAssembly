
; Lesson 7r1.s    A SPRITE MOVED WITH THE MOUSE

;        NOTE: This routine can only handle
;         255 lines horizontally, not all 320.


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

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    ReadMouse    ; this reads the mouse
moveq    #0,d0        ; clear d0
moveq    #0,d1        ; clear d1

; prepare the parameters for the universal routine

move.b    sprite_y(pc),d0 ; sprite coordinates
move.b    sprite_x(pc),d1
lea    miosprite,a1    ; sprite address
moveq    #13,d2        ; sprite height
bsr.s    UniMuoviSprite    ; call the universal routine

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080	; Point to the system cop
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

; This routine reads the mouse and updates the values contained in the
; variables sprite_x and sprite_y

ReadMouse:
move.b    $dff00a,d0 ; JOY0DAT vertical mouse position
move.b    d0,sprite_y    ; change sprite position

move.b    $dff00b,d0    ; JOY0DAT+1 horizontal mouse position
move.b    d0,sprite_x    ; change sprite position
RTS

SPRITE_Y:    dc.b    0    ; the Y position of the sprite is stored here
SPRITE_X:    dc.b    0    ; the X position of the sprite is stored here




; Universal routine for positioning sprites.

;
;    Input parameters for UniMuoviSprite:
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
move.b    D1,1(a1)    ; We place the value XX in the HSTART byte
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

dc.w $1A2,$F00; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w $1A4,$0F0; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w $1A6,$FF0; colour19, i.e. COLOUR3 of sprite0 - YELLOW

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE:        ; length 13 lines
VSTART:
dc.b $50    ; Vertical position of sprite start (from $2c to $f2)
HSTART:
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP:
dc.b $5d    ; $50+13=$5d    ; Vertical position of sprite end
VHBITS:
dc.b $00    ; bit

dc.w    %0000000000000000,%0000110000110000 ; Binary format for modifications
dc.w    %0000000000000000,%0000011001100000
dc.w    %0000000000000000,%0000001001000000
dc.w    %0000000110000000,%0011000110001100 ;BINARY 00=COLOUR 0 (TRANSPARENT)
dc.w    %0000011111100000,%0110011111100110 ;BINARY 10=COLOUR 1 (RED)
dc.w    %0000011111100000,%1100100110010011 ;BINARY 01=COLOUR 2 (GREEN)
dc.w    %0000110110110000,%1111100110011111 ;BINARIO 11=COLORE 3 (GIALLO)
dc.w	%0000011111100000,%0000011111100000
dc.w	%0000011111100000,%0001111001111000
dc.w	%0000001111000000,%0011101111011100
dc.w	%0000000110000000,%0011000110001100
dc.w	%0000000000000000,%1111000000001111
dc.w	%0000000000000000,%1111000000001111
dc.w	0,0	; 2 words set to zero define the end of the sprite.


SECTION    PLANEVUOTO,BSS_C    ; The bitplane we use, set to zero,
; because in order to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; bitplane set to zero lowres

end

In this example, we move a sprite with the mouse.
To position the sprite on the screen, we use our universal routine,
which we already have ready, saving us a bit of work.
The LeggiMouse routine, on the other hand, detects the mouse status and
consequently updates the sprite coordinates that are stored
in two memory locations: SPRITE_X and SPRITE_Y.

The mouse is read separately for the horizontal and
vertical positions. The JOY0DAT register can be considered as a pair of
bytes. The byte at address JOY0DAT (=$dff00a) handles the vertical position
, while the byte at address JOY0DAT+1 (=$dff00b) handles
the horizontal position. In each byte, we read a number ranging
from 0 to 255, which varies depending on the mouse movements:

up - $dff00a decreases
down - $dff00a increases
left - $dff00b decreases
right - $dff00b increases

In this example, we use the numbers we read from the mouse directly
as the sprite's coordinates.
You can immediately see how this simple method has a “small” problem:
the numbers we read from the mouse range from 0 to 255, while the horizontal coordinates
range from 0 to 320. Therefore, with this method, the sprite cannot
reach the right edge of the screen. Furthermore, the same problem would
arise for the vertical coordinates if we used an overscan screen
.
How can we solve this? We will see in the next example.

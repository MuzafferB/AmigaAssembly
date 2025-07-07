
; Lesson 7a.s        DISPLAYING A SPRITE


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
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080    ; Point to the system COP
move.w    d0,$dff088        ; start the old COP

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

dc.w    $180,$000    ; colour0	; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$F00    ; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w    $1A4,$0F0	; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w    $1A6,$FF0    ; colour19, i.e. COLOUR3 of sprite0 - YELLOW

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE:        ; length 13 lines
VSTART:
dc.b $30    ; Vertical position of sprite start (from $2c to $f2)
HSTART:
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP:
dc.b $3d    ; $30+13=$3d    ; vertical position of sprite end
dc.b $00
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
ds.b    40*256        ; zeroed lowres bitplane

end

This is the first sprite we check in the course. You can easily
define your own by changing its two planes, which in this listing are
defined in binary; the colour resulting from the various binary overlays
can be guessed by reading the comment next to the sprite.
The colours of sprite 0 are defined by the COLOR 17, 18 and 19 registers:

dc.w    $1A2,$F00    ; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w    $1A4,$0F0    ; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w    $1A6,$FF0    ; colour19, i.e. COLOUR3 of sprite0 - YELLOW

To change the position of the sprite, modify its first bytes:

MIOSPRITE:        ; length 13 lines
VSTART:
dc.b $30    ; Vertical position of sprite start (from $2c to $f2)
HSTART:
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP:
dc.b $3d    ; $30+13=$3d    ; vertical position of the end of the sprite
dc.b $00

Just remember these two things:

1) The top left corner of the screen is not position $00,$00
because the screen with overscan can be wider; in the case of a
normal width screen, the initial horizontal position (HSTART) can
range from $40 to $d8, otherwise the sprite is ‘cut off’ or goes completely outside
the visible screen. Similarly, the initial vertical position, i.e.
VSTART, must be selected starting from $2c, i.e. from the beginning of the
video window defined in DIWSTART (which here is $2c81).
 
To position the sprite on the 320x256 screen, for example at the central coordinates
160,128, you must take into account that the first coordinate at the top left
is $40,$2c instead of 0,0, so you must add $40 to the X coordinate and $2c
to the Y coordinate.
In fact, $40+160, $2c+128 correspond to the coordinate 160,128 of a
320x256 non-overscan screen.
Since we do not yet have control of the horizontal position at the 1
pixel level, but every 2 pixels, we must add not 160, but 160/2 at the beginning to
find the centre of the screen:

HSTART:
dc.b $40+(160/2)    ; positioned at the centre of the screen

The same applies to other horizontal coordinates, for example position 50:

dc.b $40+(50/2)

Later on, we will see how to position 1 pixel at a time horizontally.

2) The horizontal position can be varied on its own to move a sprite to the right or left,
 while if you want to move the sprite up or down,
 you need to act on two bytes each time, namely VSTART and VSTOP, i.e. the
vertical start and end positions of the sprite. In fact, while the width of
a sprite is always 16, once the horizontal start position
the end position is always 16 pixels to the right. As for the
vertical length, which can be set as desired, it must be defined by communicating
the start and end positions each time, so if we want to move the
sprite up, we must subtract 1 from both VSTART and VSTOP, while if we want to
move it down, we must add 1 to both.
For example, if you want to change VSTART to $55, to determine VSTOP
you will need to add the length of the sprite (which is 13 lines high) to
VSTART, so $55+13=$62.

Move the sprite to various positions on the screen to check if you have
understood or if you only think you have understood.
Don't forget that HSTART moves 2 pixels each time and not 1
pixel as it might seem.

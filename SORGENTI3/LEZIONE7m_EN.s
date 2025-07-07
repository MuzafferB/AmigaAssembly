
; Lesson 7m.s    Positioning sprites using a universal routine
; This example shows a universal routine for moving sprites that
; takes into account all the bits of the horizontal and vertical positions of the sprites.
; It also automatically adds the offsets (128 for the horizontal coordinates
; and $2c for the vertical ones).
; This way, the coordinates in the tables can be the real ones,
; i.e. from 0 to 320 for horizontal coordinates and from 0 to 256 for
; vertical coordinates


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

;    Point to the sprite

MOVE.L    #MIOSPRITE,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080	; our COP
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

btst	#6,$bfe001    ; mouse pressed?
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


;    To move the sprite correctly, first we read the tables to
;    find out what positions the sprite should take, then we communicate these
;    positions, as well as the address and height of the sprites, to the routine
;    UniMuoviSprite, via registers a1,d0,d1,d2

MoveSprite:
bsr.s    ReadTables    ; Reads the X and Y positions from the tables,
; putting the address of the sprite in register a1
; the Y position in d0, the X position in d1
; and the height of the sprite in d2.

;
;    Input parameters of UniMoveSprite:
;
;    a1 = Address of the sprite
;    d0 = Vertical position Y of the sprite on the screen (0-255)
;    d1 = Horizontal position X of the sprite on the screen (0-320)
;    d2 = Height of the sprite
;

bsr.w    UniMuoviSprite ; executes the universal routine that positions
; the sprite
rts




; This routine reads the actual coordinates of the sprites from the two tables.
; That is, the X coordinate varies from 0 to 320 and the Y coordinate from 0 to 256 (without overscan).
; Since we are not using overscan in this example, the Y coordinate table
; is a byte table. The X coordinate table, on the other hand, is made
; of words because it must also contain values greater than 256.
; However, this routine does not position the sprite directly. It simply
; leaves this to the universal routine, communicating the
; coordinates via registers d0 and d1

ReadTables:
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L    TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L	#FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S    NOBSTARTY    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT ; Start pointing to the first byte again
NOBSTARTY:
moveq    #0,d0        ; Clear d0
MOVE.b	(A0),d0        ; copy the table byte, i.e. the
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

lea    MIOSPRITE,a1    ; sprite address in A1
moveq    #13,d2        ; sprite height in d2
rts


TABYPOINT:
dc.l    TABY-1        ; NOTE: the table values here are bytes,
; so we work with an ADDQ.L #1,TABYPOINT
; and not #2 as when they are words or with #4
; as when they are longwords.
TABXPOINT:
dc.l    TABX-2        ; NOTE: the values in the table here are words,

; Table with precalculated Y coordinates of the sprite.
; Note that the Y position for the sprite to enter the video window
; must be between $0 and $ff, because the $2c offset is added
; by the routine. If you are not using overscan screens, i.e. screens no longer than
; 255 lines, you can use a table of values dc.b (from $00 to $FF)


; How to recreate the table:

; BEG> 0
; END> 360
; AMOUNT> 200
; AMPLITUDE> $f0/2
; YOFFSET> $f0/2
; SIZE (B/W/L)> b
; MULTIPLIER> 1


TABY:
incbin    ‘ycoordinatok.tab’    ; 200 values .B
FINETABY:

; Table with precalculated X coordinates of the sprite. This table contains
; the REAL values of the screen coordinates, not the ‘halved’ values for
; the two-pixel jerky scrolling we have seen so far.
; In fact, the table contains bytes no larger than 304 and no
; smaller than zero.

TABX:
incbin    ‘xcoordinatok.tab’    ; 150 values .W
FINETABX:




; Universal sprite positioning routine.
; This routine changes the position of the sprite whose address is
; contained in register a1 and whose height is contained in register d2,
; and positions the sprite at the Y and X coordinates contained respectively in
; registers d0 and d1.
; Before calling this routine, you must put the address of the
; sprite in register a1, its height in register d2, the Y coordinate in
; register d0, and the X coordinate in register d1

; This procedure is called ‘passing parameters’.
; Note that this routine modifies registers d0 and d1.

;
;    Input parameters of UniMuoviSprite:
;
;    a1 = Address of the sprite
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
bset.b    #1,3(a1)    ; Set bit 8 of VSTOP (number > $FF)
bra.w    VstopFIN
NonVSTOPSET:
bclr.b    #1,3(a1)    ; Clear bit 8 of VSTOP (number < $FF)
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

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$F00    ; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w    $1A4,$0F0    ; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w    $1A6,$FF0    ; colour19, i.e. COLOUR3 of sprite0 
- YELLOW

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE:        ; length 13 lines
dc.b $50    ; Vertical position of sprite start (from $2c to $f2)
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
dc.b $5d    ; $50+13=$5d    ; vertical position of sprite end
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

In this lesson, we present a universal routine for moving sprites,
called ‘UniMuoviSprite’.
This routine takes care of all aspects of sprite positioning,
correctly manages all position bits, and also adds offsets
so that the actual coordinates of the sprites can be stored in the tables
.
This routine works with any sprite. In fact, the sprite address
is not fixed, but is read from the a1 register.
This means that:

VSTART is located at the address contained in a1

HSTART is located in the following byte, i.e. at the address contained in a1 +1

VSTOP is located 2 bytes after, i.e. at the address contained in a1 +2

the fourth byte is located 3 bytes after, i.e. at the address contained in a1 +3.

UniMuoviSprite accesses these bytes by means of indirect addressing
to the register with displacement:

to access VSTART, use (a1)
to access HSTART, use 1(a1)
to access VSTOP, use 2(a1)
to access the fourth control byte, use 3(a1)

The height of the sprite is also not fixed, but is contained in register d2.
In this way, the routine can be used to move sprites of different
heights. Furthermore, this routine does not read the coordinates directly
from the table, but takes them from registers d0 and d1.

Who puts the data in these registers? Another routine takes care of this
‘LeggiTabelle’ (Read Tables), which takes the coordinates from the tables, puts them in registers
d0 and d1, and executes the routine ‘UniMuoviSprite’ (Move Sprite). In practice, we have divided
the tasks between the two routines, as if they were two employees. The routine
‘Leggitabelle’ performs its task, then says: "Hey routine UniMUoviSprite,
here's the sprite to move, I'll send you the address in register a1.
I'll send you the height of the sprite in d2.
Here are the coordinates, I'll send them to you through registers d0 and d1.
You know what to do!‘
The ’UniMuoviSprite‘ routine receives the address of the sprite and the coordinates and
puts them in the correct bytes of the sprite.
The “sending” of coordinates through registers is called ’parameter passing
."
The division of tasks is very convenient. Suppose we want to
move a sprite using a table for the Y coordinates and a
separate ADDQ/AUBQ continuous increment and decrement routine for the X coordinates, so as to
create a sprite that always moves from left to right but oscillates
up and down.
Since the universal routine we have just seen takes the coordinates from the
registers, without caring whether this data came from a table,
we can use it again as it is in this listing, without having to
modify it at all.
Furthermore, since it takes the address of the sprite from one register and its
height from another, it can be used for any sprite.
From now on, for every other example on sprites, we will therefore always use the
routine ‘UniMuoviSprite’, without having to modify it each time.

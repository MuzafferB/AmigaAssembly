
; Lesson 7f.s	DISPLAYING ALL 8 SPRITES OF THE AMIGA
;        This listing verifies that the 8 sprites have
;        the same palette in pairs, i.e. sprite 0 has the same
;        colours as sprite 1, sprite 2 has the same as sprite 3
;        and so on. It also checks that in the case of
;        two sprites overlapping, the one with the lower number
;        takes precedence over the one with the higher number, so that sprite 0
;        appears above all the others and sprite 7 can be covered
;        by all the others, while sprite 3 covers sprites 4, 5 and 6
;		and is covered by sprites 0, 1, and 2
;        Pressing the left mouse button causes the sprites to overlap and
;        the overlap priorities to be noted. Right-click
;        to exit.

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6		; Execbase
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

;    Point to the sprites

MOVE.L    #MIOSPRITE0,d0        ; address of the sprite in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L	#MIOSPRITE1,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE2,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE3,d0        ; address of the sprite in d0
addq.w	#8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE4,d0        ; address of the sprite in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE5,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE6,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE7,d0        ; address of the sprite in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
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

MOVEQ    #$60,d0        ; Initial HSTART coordinate
ADDQ.B    #(10/2),d0    ; distance to next sprite
; (note that the HSTART byte works on
; pixels 2 by 2, so to move 10
; pixels just add 5 to HSTART!
MOVE.B    d0,HSTART1
ADDQ.B    #(10/2),d0    ; distance to next sprite
MOVE.B    d0,HSTART2
ADDQ.B    #(10/2),d0    ; distance to next sprite
MOVE.B    d0,HSTART3
ADDQ.B    #(10/2),d0    ; distance to next sprite
MOVE.B    d0,HSTART4
ADDQ.B    #(10/2),d0    ; distance to next sprite
MOVE.B    d0,HSTART5
ADDQ.B    #(10/2),d0    ; distance to next sprite
MOVE.B    d0,HSTART6
ADDQ.B    #(10/2),d0    ; distance to next sprite
MOVE.B    d0,HSTART7

Right mouse button:
btst    #2,$dff016
bne.s    Right mouse button

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

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
dc.w    $13e,0

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

dc.w    $1A2,$F00	; colour17, - COLOUR1 of sprites0/1 -RED
dc.w    $1A4,$0F0    ; colour18, - COLOUR2 of sprites0/1 -GREEN
dc.w    $1A6,$FF0    ; colour19, - COLOUR3 of sprites0/1 -YELLOW

dc.w	$1AA,$FFF    ; colour21, - COLOUR1 of sprites 2/3 - WHITE
dc.w    $1AC,$0BD    ; colour22, - COLOUR2 of sprites 2/3 - WATER
dc.w    $1AE,$D50    ; colour23, - COLOUR3 of sprites 2/3 - ORANGE

dc.w    $1B2,$00F    ; colour25, - COLOUR1 of sprites 4/5 -BLUE
dc.w    $1B4,$F0F    ; colour26, - COLOUR2 of sprites 4/5 -PURPLE
dc.w    $1B6,$BBB	; color27, - COLOUR3 of sprites 4/5 -GREY

dc.w    $1BA,$8E0    ; color29, - COLOUR1 of sprites 6/7 -GREEN CH.
dc.w    $1BC,$a70    ; colour30, - COLOUR2 of sprites 6/7 -BROWN
dc.w    $1BE,$d00    ; colour31, - COLOUR3 of sprites 6/7 -RED SC.

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here are the sprites: OBVIOUSLY in CHIP RAM! ************

; reference table to define colours:


; for sprites 0 and 1
;BINARY 00=COLOUR 0 (TRANSPARENT)
;BINARY 10=COLOUR 1 (RED)
;BINARY 01=COLOUR 2 (GREEN)
;BINARY 11=COLOUR 3 (YELLOW)

MIOSPRITE0:        ; length 13 lines
VSTART0:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART0:
dc.b $60    ; Horizontal position (from $40 to $d8)
VSTOP0:
dc.b $68    ; $60+13=$6d    ; vertical end.
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001110001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000010001000001
dc.w	%0111111111111110,%1000010001000001
dc.w	%0011111111111100,%1100010001000011
dc.w	%0000111111110000,%1111001110001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite


MIOSPRITE1:        ; length 13 lines
VSTART1:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART1:
dc.b $60+14    ; Horizontal position (from $40 to $d8)
VSTOP1:
dc.b $68    ; $60+13=$6d    ; vertical end.
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000010001111
dc.w	%0011111111111100,%1100000110000011
dc.w	%0111111111111110,%1000000010000001
dc.w	%0111111111111110,%1000000010000001
dc.w	%0011111111111100,%1100000010000011
dc.w	%0000111111110000,%1111000111001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

; for sprites 2 and 3
;BINARY 00=COLOUR 0 (TRANSPARENT)
;BINARY 10=COLOUR 1 (WHITE)
;BINARY 01=COLOUR 2 (WATER)
;BINARY 11=COLOUR 3 (ORANGE)

MIOSPRITE2:        ; length 13 lines
VSTART2:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART2:
dc.b $60+(14*2)    ; Horizontal position (from $40 to $d8)
VSTOP2:
dc.b $68    ; $60+13=$6d    ; vertical end.
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000111001111
dc.w	%0011111111111100,%1100001000100011
dc.w	%0111111111111110,%1000000000100001
dc.w	%0111111111111110,%1000000111000001
dc.w	%0011111111111100,%1100001000000011
dc.w	%0000111111110000,%1111001111101111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

MIOSPRITE3:        ; length 13 lines
VSTART3:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART3:
dc.b $60+(14*3)    ; Horizontal position (from $40 to $d8)
VSTOP3:
dc.b $68    ; $60+13=$6d    ; Vertical end.
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111101111
dc.w	%0011111111111100,%1100000000100011
dc.w	%0111111111111110,%1000000111100001
dc.w	%0111111111111110,%1000000000100001
dc.w	%0011111111111100,%1100000000100011
dc.w	%0000111111110000,%1111001111101111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

; for sprites 4 and 5
;BINARY 00=COLOUR 0 (TRANSPARENT)
;BINARY 10=COLOUR 1 (BLUE)
;BINARY 01=COLOUR 2 (PURPLE)
;BINARY 11=COLOUR 3 (GREY)

MIOSPRITE4:        ; length 13 lines
VSTART4:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART4:
dc.b $60+(14*4)    ; Horizontal position (from $40 to $d8)
VSTOP4:
dc.b $68    ; $60+13=$6d	; fine verticale.
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001001001111
dc.w	%0011111111111100,%1100001001000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111000001001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

MIOSPRITE5:        ; length 13 lines
VSTART5:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART5:
dc.b $60+(14*5)    ; Horizontal position (from $40 to $d8)
VSTOP5:
dc.b $68    ; $60+13=$6d    ; vertical end.
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100001000000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111001111001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

; for sprites 6 and 7
;BINARY 00=COLOUR 0 (TRANSPARENT)
;BINARY 10=COLOUR 1 (LIGHT GREEN)
;BINARY 01=COLOUR 2 (BROWN)
;BINARY 11=COLOUR 3 (DARK RED)

MIOSPRITE6:        ; length 13 lines
VSTART6:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART6:
dc.b $60+(14*6)    ; Horizontal position (from $40 to $d8)
VSTOP6:
dc.b $68    ; $60+13=$6d    ; Vertical end.
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100001000000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000001001000001
dc.w	%0011111111111100,%1100001001000011
dc.w	%0000111111110000,%1111001111001111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0	; fine sprite

MIOSPRITE7:		; length 13 lines
VSTART7:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART7:
dc.b $60+(14*7)    ; Horizontal position (from $40 to $d8)
VSTOP7:
dc.b $68    ; $60+13=$6d    ; vertical end.
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100000001000011
dc.w	%0111111111111110,%1000000001000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111000001001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

In this listing, all 8 sprites are ‘pointed’ to, which have the
number in the drawing to make their arrangement clearer.
As explained in the theory, the 8 sprites have 4 distinct colour palettes,
so adjacent sprites share the same palette:

dc.w    $1A2,$F00    ; colour17, - COLOUR1 of sprites0/1 -RED
dc.w    $1A4,$0F0    ; colour18, - COLOUR2 of sprites0/1 -GREEN
dc.w    $1A6,$FF0    ; colour19, - COLOUR3 of sprites0/1 -YELLOW

dc.w    $1AA,$FFF    ; colour21, - COLOUR1 of sprites 2/3 -WHITE
dc.w    $1AC,$0BD    ; colour22, - COLOUR2 of sprites 2/3 -WATER
dc.w    $1AE,$D50	; colour23, - COLOUR3 of sprites 2/3 -ORANGE

dc.w    $1B2,$00F    ; colour25, - COLOUR1 of sprites 4/5 -BLUE
dc.w    $1B4,$F0F	; color26, - COLOUR2 of sprites 4/5 - PURPLE
dc.w    $1B6,$BBB    ; color27, - COLOUR3 of sprites 4/5 - GREY

dc.w    $1BA,$8E0    ; color29, - COLOUR1 of sprites 6/7 -GREEN CH.
dc.w    $1BC,$a70    ; color30, - COLOUR2 of sprites 6/7 -BROWN
dc.w    $1BE,$d00    ; color31, - COLOUR3 of sprites 6/7 -RED SC.

Note that colours Color16, Color20, Color24 and Color28 are not used by
sprites, they are skipped, as they would correspond to colour0 of the sprite,
the TRANSPARENT one, which is not a colour, but a ‘HOLE’ that takes on
the colour of the underlying bitplanes (or sprites).
Each sprite has its own VSTART, HSTART and VSTOP. Let's look at SPRITE2, for example:

MIOSPRITE2:        ; length 13 lines
VSTART2:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART2:
dc.b $60+(14*2)    ; Horizontal position (from $40 to $d8)
VSTOP2:
dc.b $68    ; $60+13=$6d    ; Vertical end.
dc.b $00

Each sprite is initially spaced apart from the others by adding (14*x)
to the HSTART values. After pressing the left mouse button,
all HSTART values except the first one are changed so that the sprites overlap and
their display priorities are determined.

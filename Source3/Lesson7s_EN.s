
; Lesson 7s.s    DISPLAYING 16 SPRITES

;    This listing shows how to reuse sprites.
;    Pressing the left mouse button changes the position of the sprites.
;    Right mouse button to exit.

SECTION    CiriCop,CODE

Start:
move.l	4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop


MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

;    Point to the sprites

MOVE.L    #MIOSPRITE0,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE1,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE2,d0        ; address of the sprite in d0
addq.w	#8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE3,d0        ; address of the sprite in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE4,d0        ; address of the sprite in d0
addq.w	#8,a1            ; next SPRITEPOINTERS
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
MOVE.L	#MIOSPRITE7,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

; sprite positions
MOVE.B    #$2C+50,VSTART0
MOVE.B    #$2C+50+8,VSTOP0
MOVE.B    #$2C+50,VSTART1
MOVE.B    #$2C+50+8,VSTOP1
MOVE.B    #$2C+50,VSTART2
MOVE.B    #$2C+50+8,VSTOP2
MOVE.B    #$2C+50,VSTART3
MOVE.B    #$2C+50+8,VSTOP3
MOVE.B    #$2C+50,VSTART4
MOVE.B    #$2C+50+8,VSTOP4
MOVE.B    #$2C+50,VSTART5
MOVE.B    #$2C+50+8,VSTOP5
MOVE.B    #$2C+50,VSTART6
MOVE.B    #$2C+50+8,VSTOP6
MOVE.B    #$2C+50,VSTART7
MOVE.B    #$2C+50+8,VSTOP7

; from here the ‘reused’ sprites begin
MOVE.B    #$2C+90,VSTART8
MOVE.B    #$2C+90+8,VSTOP8
MOVE.B    #$2C+90,VSTART9
MOVE.B	#$2C+90+8,VSTOP9
MOVE.B	#$2C+90,VSTART10
MOVE.B	#$2C+90+8,VSTOP10
MOVE.B	#$2C+90,VSTART11
MOVE.B	#$2C+90+8,VSTOP11
MOVE.B	#$2C+90,VSTART12
MOVE.B	#$2C+90+8,VSTOP12
MOVE.B	#$2C+90,VSTART13
MOVE.B	#$2C+90+8,VSTOP13
MOVE.B	#$2C+90,VSTART14
MOVE.B	#$2C+90+8,VSTOP14
MOVE.B	#$2C+90,VSTART15
MOVE.B	#$2C+90+8,VSTOP15


move.l	#COPPERLIST,$dff080	; nostra COP
move.w	d0,$dff088		; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

Mouse1:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse1

; sets new vertical positions

MOVE.B    #$2C+10,VSTART0
MOVE.B    #$2C+10+8,VSTOP0
MOVE.B    #$2C+10+8*1,VSTART1
MOVE.B    #$2C+10+8*1+8,VSTOP1
MOVE.B    #$2C+10+8*2,VSTART2
MOVE.B    #$2C+10+8*2+8,VSTOP2
MOVE.B    #$2C+10+8*3,VSTART3
MOVE.B    #$2C+10+8*3+8,VSTOP3
MOVE.B    #$2C+10+8*4,VSTART4
MOVE.B    #$2C+10+8*4+8,VSTOP4
MOVE.B    #$2C+10+8*5,VSTART5
MOVE.B    #$2C+10+8*5+8,VSTOP5
MOVE.B    #$2C+10+8*6,VSTART6
MOVE.B    #$2C+10+8*6+8,VSTOP6
MOVE.B    #$2C+10+8*7,VSTART7
MOVE.B    #$2C+10+8*7+8,VSTOP7

; from here the ‘reused’ sprites begin

MOVE.B	#$2C+10+20,VSTART8
MOVE.B	#$2C+10+20+8,VSTOP8
MOVE.B	#$2C+10+20+8*1,VSTART9
MOVE.B	#$2C+10+20+8*1+8,VSTOP9
MOVE.B	#$2C+10+20+8*2,VSTART10
MOVE.B	#$2C+10+20+8*2+8,VSTOP10
MOVE.B	#$2C+10+20+8*3,VSTART11
MOVE.B	#$2C+10+20+8*3+8,VSTOP11
MOVE.B	#$2C+10+20+8*4,VSTART12
MOVE.B	#$2C+10+20+8*4+8,VSTOP12
MOVE.B	#$2C+10+20+8*5,VSTART13
MOVE.B	#$2C+10+20+8*5+8,VSTOP13
MOVE.B	#$2C+10+20+8*6,VSTART14
MOVE.B	#$2C+10+20+8*6+8,VSTOP14
MOVE.B    #$2C+10+20+8*7,VSTART15
MOVE.B    #$2C+10+20+8*7+8,VSTOP15

Mouse2:
btst    #2,$dff016
bne.s    Mouse2


move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr	-$19e(a6)    ; Close library
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
dc.w    $12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0		; Bpl2Mod

; 5432109876543210
dc.w    $100,%0001001000000000

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$F00    ; colour17, - COLOUR1 of sprites0/1 -RED
dc.w    $1A4,$0F0    ; colour18, - COLOUR2 of sprites0/1 -GREEN
dc.w    $1A6,$FF0    ; colour19, - COLOUR3 of sprites0/1 
-YELLOW

dc.w    $1AA,$FFF    ; colour21, - COLOUR1 of sprites 2/3 -WHITE
dc.w    $1AC,$0BD    ; colour22, - COLOUR2 of sprites 2/3 -WATER
dc.w    $1AE,$D50    ; colour23, - COLOUR3 of sprites 2/3 -ORANGE

dc.w    $1B2,$00F    ; colour25, - COLOUR1 of sprites 4/5 -BLUE
dc.w    $1B4,$F0F    ; colour26, - COLOUR2 of sprites 4/5 -PURPLE
dc.w    $1B6,$BBB	; colour27, - COLOUR3 of sprites 4/5 -GREY

dc.w    $1BA,$8E0    ; colour29, - COLOUR1 of sprites 6/7 -GREEN CH.
dc.w    $1BC,$a70    ; colour30, - COLOUR2 of sprites 6/7 -BROWN
dc.w    $1BE,$d00    ; color31, - COLOUR3 of sprites 6/7 -RED SC.

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
dc.b 0
HSTART0:
dc.b $40+12+0*20
VSTOP0:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001110001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000010001000001
dc.w	%0111111111111110,%1000010001000001
dc.w	%0011111111111100,%1100010001000011
dc.w	%0000111111110000,%1111001110001111
dc.w	%0000001111000000,%0111110000111110
VSTART8:
dc.b $0
HSTART8:
dc.b $40+20+0*12
VSTOP8:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001110001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000001110000001
dc.w	%0111111111111110,%1000010001000001
dc.w	%0011111111111100,%1100010001000011
dc.w	%0000111111110000,%1111001110001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite


MIOSPRITE1:        ; length 13 lines
VSTART1:
dc.b $0
HSTART1:
dc.b $40+12+1*20
VSTOP1:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000010001111
dc.w	%0011111111111100,%1100000110000011
dc.w	%0111111111111110,%1000000010000001
dc.w	%0111111111111110,%1000000010000001
dc.w	%0011111111111100,%1100000010000011
dc.w	%0000111111110000,%1111000111001111
dc.w	%0000001111000000,%0111110000111110
VSTART9:
dc.b $0
HSTART9:
dc.b $40+20+1*12
VSTOP9:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001110001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000001110000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111001110001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

; for sprites 2 and 3
;BINARY 00=COLOUR 0 (TRANSPARENT)
;BINARY 10=COLOUR 1 (WHITE)
;BINARY 01=COLOUR 2 (WATER)
;BINARY 11=COLOUR 3 (ORANGE)

MIOSPRITE2:        ; length 13 lines
VSTART2:
dc.b $0
HSTART2:
dc.b $40+12+2*20
VSTOP2:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000111001111
dc.w	%0011111111111100,%1100001000100011
dc.w	%0111111111111110,%1000000000100001
dc.w	%0111111111111110,%1000000111000001
dc.w	%0011111111111100,%1100001000000011
dc.w	%0000111111110000,%1111001111101111
dc.w	%0000001111000000,%0111110000111110
VSTART10:
dc.b $0
HSTART10:
dc.b $40+20+2*12
VSTOP10:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000000001111
dc.w	%0011111111111100,%1100010011100011
dc.w	%0111111111111110,%1000110010100001
dc.w	%0111111111111110,%1000010010100001
dc.w	%0011111111111100,%1100111011100011
dc.w	%0000111111110000,%1111000000001111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0	; end sprite

MIOSPRITE3:        ; length 13 lines
VSTART3:
dc.b $0
HSTART3:
dc.b $40+12+3*20
VSTOP3:
dc.b 0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111101111
dc.w	%0011111111111100,%1100000000100011
dc.w	%0111111111111110,%1000000111100001
dc.w	%0111111111111110,%1000000000100001
dc.w	%0011111111111100,%1100000000100011
dc.w	%0000111111110000,%1111001111101111
dc.w	%0000001111000000,%0111110000111110
VSTART11:
dc.b $0
HSTART11:
dc.b $40+20+3*12
VSTOP11:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000000001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000110011000001
dc.w	%0111111111111110,%1000010001000001
dc.w	%0011111111111100,%1100111011100011
dc.w	%0000111111110000,%1111000000001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

; for sprites 4 and 5
;BINARY 00=COLOUR 0 (TRANSPARENT)
;BINARY 10=COLOUR 1 (BLUE)
;BINARY 01=COLOUR 2 (PURPLE)
;BINARY 11=COLOUR 3 (GREY)

MIOSPRITE4:        ; length 13 lines
VSTART4:
dc.b $0
HSTART4:
dc.b $40+12+4*20
VSTOP4:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001001001111
dc.w	%0011111111111100,%1100001001000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111000001001111
dc.w	%0000001111000000,%0111110000111110
VSTART12:
dc.b $0
HSTART12:
dc.b $40+20+4*12
VSTOP12:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000000001111
dc.w	%0011111111111100,%1100010011000011
dc.w	%0111111111111110,%1000110001000001
dc.w	%0111111111111110,%1000010010000001
dc.w	%0011111111111100,%1100111011100011
dc.w	%0000111111110000,%1111000000001111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0	; end sprite

MIOSPRITE5:        ; length 13 lines
VSTART5:
dc.b $0
HSTART5:
dc.b $40+12+5*20
VSTOP5:
dc.b $0
dc.b $0
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100001000000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111001111001111
dc.w	%0000001111000000,%0111110000111110
VSTART13:
dc.b $0
HSTART13:
dc.b $40+20+5*12
VSTOP13:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000000001111
dc.w	%0011111111111100,%1100010011100011
dc.w	%0111111111111110,%1000110001100001
dc.w	%0111111111111110,%1000010000100001
dc.w	%0011111111111100,%1100111011000011
dc.w    %0000111111110000,%1111000000001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

; for sprites 6 and 7
;BINARY 00=COLOUR 0 (TRANSPARENT)
;BINARY 10=COLOUR 1 (LIGHT GREEN)
;BINARY 01=COLOUR 2 (BROWN)
;BINARY 11=COLOUR 3 (DARK RED)

MIOSPRITE6:        ; length 13 lines
VSTART6:
dc.b $0
HSTART6:
dc.b $40+12+6*20
VSTOP6:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100001000000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000001001000001
dc.w	%0011111111111100,%1100001001000011
dc.w	%0000111111110000,%1111001111001111
dc.w	%0000001111000000,%0111110000111110
VSTART14:
dc.b $0
HSTART14:
dc.b $40+20+6*12
VSTOP14:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000000001111
dc.w	%0011111111111100,%1100010000100011
dc.w	%0111111111111110,%1000110010100001
dc.w	%0111111111111110,%1000010011100001
dc.w	%0011111111111100,%1100111001000011
dc.w	%0000111111110000,%1111000000001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

MIOSPRITE7:        ; length 13 lines
VSTART7:
dc.b 0
HSTART7:
dc.b $40+12+7*20
VSTOP7:
dc.b $0
dc.b $0
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100000001000011
dc.w	%0111111111111110,%1000000001000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111000001001111
dc.w	%0000001111000000,%0111110000111110
VSTART15:
dc.b $0
HSTART15:
dc.b $40+20+7*12
VSTOP15:
dc.b $0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000000001111
dc.w	%0011111111111100,%1100010011100011
dc.w	%0111111111111110,%1000110011000001
dc.w	%0111111111111110,%1000010000100001
dc.w	%0011111111111100,%1100111011100011
dc.w    %0000111111110000,%1111000000001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

SECTION    PLANEVUOTO,BSS_C
BITPLANE:
ds.b    40*256

end

This listing shows how to reuse sprites multiple times on the
same screen. In the example, each sprite is used twice.
Sprite 0 is reused to draw sprite 8.
Sprite 1 is reused to draw sprite 9.
Sprite 2 is reused to draw sprite 10.
Sprite 3 is reused to draw sprite 11.
Sprite 4 is reused to draw sprite 12.
Sprite 5 is reused to draw sprite 13.
Sprite 6 is reused to draw sprite 14.
Sprite 7 is reused to draw sprite 15.

Note that when a sprite is used a second time, it is
positioned on the screen BELOW the last line of the sprite
displayed during its first use.
 This is due to a specific hardware limitation. In fact, between one use of a sprite and the next,
it is necessary to leave AT LEAST one empty row.

The VSTART byte of sprite 8 must be GREATER than VSTOP of sprite 0
The VSTART byte of sprite 9 must be GREATER than VSTOP of sprite 1
The VSTART byte of sprite 10 must be GREATER than VSTOP of sprite 2
The VSTART byte of sprite 11 must be GREATER than VSTOP of sprite 3
The VSTART byte of sprite 12 must be GREATER than VSTOP of sprite 4
The VSTART byte of sprite 13 must be GREATER than VSTOP of sprite 5
The VSTART byte of sprite 14 must be GREATER than VSTOP of sprite 6
The VSTART byte of sprite 15 must be GREATER than VSTOP of sprite 7

Reusing a sprite does not change the colour registers assigned to it
assigned to it.
In the example, you can see that a ‘reused’ sprite has the same
colours as the ‘original’ ones. However, since the sprites are positioned
at different heights on the screen, nothing prevents us from changing the values of the
colour registers between one use and another using the copper. You can do this
as an exercise.

; Lesson 7v1.s    SPRITE AND PLAYFIELD PRIORITIES
;        This listing shows the priorities between sprites
;        and playfields. Sprites cross four lines
;        on the screen. Each time they cross a line
;        the priorities are changed using the copperlist.

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

;    Point to the PIC using the usual method

MOVE.L    #PIC,d0
LEA    BPLPOINTERS,A1
MOVEQ    #3-1,D1
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP

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
MOVE.L    #MIOSPRITE3,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE4,d0        ; sprite address in d0
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
MOVE.L    #MIOSPRITE7,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
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

bsr.s    MoveSprites    ; Moves sprites down

Wait1:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s	Wait1


btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse


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

; this routine moves the 8 sprites down:
; the sprites are moved once every other time. For this
; the flag variable is used. Each time the routine is executed
; the variable is changed with the not instruction:
; if it is 0, it is set to $ffff
; if it is $ffff, it is set to 0
; if the variable changes from 0 to $ffff, the sprites are not moved
; All sprites have the same height

Move sprites:
not.w    flag
bne.w    exit

; move sprite 0

addq.w    #1,height
cmp.w    #300,height
blo.s    no_border    ; has it reached the bottom border?
move.w    #$2c,height    ; if so, put it back at the top

no_bordo:
move.w    height(PC),d0

CLR.B    VHBITS0        ; reset bits 8 of the vertical positions
MOVE.b    d0,VSTART0    ; copy bits 0 to 7 to VSTART
BTST.l    #8,D0        ; is the position greater than 255?
BEQ.S    NOBIGVSTART    ; if not, go further, because the bit has already been 
; reset with CLR.b VHBITS

BSET.b    #2,VHBITS0    ; otherwise, set bit 8 of the vertical starting position to 1
; NOBIGVSTART: ADDQ.W    #8,D0        ; add the length of the sprite to ; determine the final position (VSTOP)
NOBIGVSTART:
ADDQ.W    #8,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,VSTOP0    ; Move bits 0 to 7 in VSTOP
BTST.l    #8,D0        ; is the position greater than 255?
BEQ.S    NOBIGVSTOP    ; if not, go further because the bit has already been 
; reset with CLR.b VHBITS

BSET.b    #1,VHBITS0    ; otherwise set bit 8 of the
vertical end position of the sprite
NOBIGVSTOP:

; copy the height to the other sprites

move.b    vstart0,vstart1    ; copy vstart
move.w    vstop0,vstop1    ; copy VSTOP and VHBITS

move.b    vstart0,vstart2    ; copy vstart
move.w    vstop0,vstop2	; copy VSTOP and VHBITS

move.b    vstart0,vstart3    ; copy vstart
move.w    vstop0,vstop3    ; copy VSTOP and VHBITS

move.b    vstart0,vstart4    ; copy vstart
move.w    vstop0,vstop4	; copy VSTOP and VHBITS

move.b    vstart0,vstart5    ; copy vstart
move.w    vstop0,vstop5    ; copy VSTOP and VHBITS

move.b    vstart0,vstart6    ; copy vstart
move.w    vstop0,vstop6    ; copy VSTOP and VHBITS

move.b    vstart0,vstart7    ; copy vstart
move.w    vstop0,vstop7    ; copy VSTOP and VHBITS

exit:
rts

height:
dc.w    $2c
flag:
dc.w    0


SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; bit 12 on!! 3 low-resolution bitplanes

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first bitplane
dc.w $e4,0,$e6,0
dc.w $e8,0,$ea,0

dc.w    $180,$000    ; colour0	; black background
dc.w    $182,$ff0
dc.w    $184,$800
dc.w    $186,$0f0
dc.w    $188,$ff0
dc.w    $18a,$f00
dc.w    $18c,$0f0
dc.w    $18e,$0f0

dc.w    $1A2,$F00    ; colour17, - COLOUR1 of sprites0/1 -RED
dc.w    $1A4,$0F0	; colour18, - COLOUR2 of sprites0/1 -GREEN
dc.w    $1A6,$FF0    ; colour19, - COLOUR3 of sprites0/1 -YELLOW

dc.w	$1AA,$FFF    ; colour21, - COLOUR1 of sprites 2/3 - WHITE
dc.w    $1AC,$0BD    ; colour22, - COLOUR2 of sprites 2/3 - WATER
dc.w    $1AE,$D50    ; colour23, - COLOUR3 of sprites 2/3 -ORANGE

dc.w    $1B2,$00F    ; colour25, - COLOUR1 of sprites 4/5 -BLUE
dc.w    $1B4,$F0F    ; colour26, - COLOUR2 of sprites 4/5 -PURPLE
dc.w    $1B6,$BBB	; color27, - COLOUR3 of sprites 4/5 -GREY

dc.w    $1BA,$8E0	; color29, - COLOUR1 of sprites 6/7 -GREEN CH.
dc.w    $1BC,$a70    ; color30, - COLOUR2 of sprites 6/7 -BROWN
dc.w    $1BE,$d00    ; color31, - COLOUR3 of sprites 6/7 -RED SC.

; from here begin the instructions that change the priority
; you can see that since we are working with a normal playfield (not in dual playfield mode
;), the priority code is the same for even bit planes
; and for odd bit planes: for example, the value $0009, which is the first value
; written in BPLCON2:
;
; 5432109876543210
; $0009=%0000000000001001 you can see that:
;
; in bits 0 to 2, %001 is written
; in bits 3 to 5, %001 is written, as we said.
;
; you can check that the same applies to all other values that
; are written in BPLCON2


dc.w    $104,$0000    ; BPLCON2 - at the beginning all sprites below

dc.w    $7007,$fffe    ; WAIT - wait for the end of the range
dc.w    $104,$0009    ; BPLCON2 - sprites 0,1 above and
; sprites 2,3,4,5,6,7 below

dc.w    $a007,$fffe    ; WAIT - wait for the end of the range
dc.w    $104,$0012    ; BPLCON2 - sprites 0,1,2,3 above and
; sprites 4,5,6,7 below

dc.w    $d007,$fffe    ; WAIT - wait for the end of the range
dc.w    $104,$001b    ; BPLCON2 - sprites 0,1,2,3,4,5 above and
; sprites 6,7 below

dc.w    $ff07,$fffe    ; WAIT - wait for the end of the range
dc.w    $104,$0024    ; BPLCON2 - all sprites above

dc.w    $FFFF,$FFFE    ; End of copperlist

;     543210
; NOTE:    $0 = %000000 - all sprites below
;    $9 = %001001 - sprites 0,1 above,     2,3,4,5,6,7 below
;    $12 = %010010 - sprites 0,1,2,3 above,      4,5,6,7 below
;    $1b = %011011 - sprites 0,1,2,3,4,5 above,     6,7 below
;    $24 = %100100 - all sprites above

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
dc.b $68    ; $60+13=$6d    ; Vertical end.
VHBITS0
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001110001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000010001000001
dc.w	%0111111111111110,%1000010001000001
dc.w	%0011111111111100,%1100010001000011
dc.w	%0000111111110000,%1111001110001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite


MIOSPRITE1:        ; length 13 lines
VSTART1:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART1:
dc.b $60+14    ; Horizontal position (from $40 to $d8)
VSTOP1:
dc.b $68    ; $60+13=$6d    ; vertical end.
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000010001111
dc.w	%0011111111111100,%1100000110000011
dc.w	%0111111111111110,%1000000010000001
dc.w	%0111111111111110,%1000000010000001
dc.w	%0011111111111100,%1100000010000011
dc.w	%0000111111110000,%1111000111001111
dc.w	%0000001111000000,%0111110000111110
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
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000111001111
dc.w	%0011111111111100,%1100001000100011
dc.w	%0111111111111110,%1000000000100001
dc.w	%0111111111111110,%1000000111000001
dc.w	%0011111111111100,%1100001000000011
dc.w	%0000111111110000,%1111001111101111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

MIOSPRITE3:        ; length 13 lines
VSTART3:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART3:
dc.b $60+(14*3)    ; Horizontal position (from $40 to $d8)
VSTOP3:
dc.b $68    ; $60+13=$6d    ; vertical end.
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111101111
dc.w	%0011111111111100,%1100000000100011
dc.w	%0111111111111110,%1000000111100001
dc.w	%0111111111111110,%1000000000100001
dc.w	%0011111111111100,%1100000000100011
dc.w	%0000111111110000,%1111001111101111
dc.w    %0000001111000000,%0111110000111110
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
dc.b $68    ; $60+13=$6d    ; Vertical end.
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001001001111
dc.w	%0011111111111100,%1100001001000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w    %0000111111110000,%1111000001001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

MIOSPRITE5:        ; length 13 lines
VSTART5:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART5:
dc.b $60+(14*5)    ; Horizontal position (from $40 to $d8)
VSTOP5:
dc.b $68    ; $60+13=$6d	; fine verticale.
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100001000000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111001111001111
dc.w    %0000001111000000,%0111110000111110
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
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

MIOSPRITE7:        ; length 13 lines
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
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite

SECTION    PLANEVUOTO,BSS_C    ; The bitplane we use

PIC:
incbin    ‘priorita.raw’    ; the drawing

end

In this listing we show how to change the priorities of the sprites with respect to
the playfields. First of all, we note that the sprites always appear above
the zero colour. For the other colours, the priority is controlled by the
BPLCON2 register. It is possible to control the priority individually for even
and odd planes. This is very important when using dual playfield mode
.
 When, as in this example, normal mode is used instead,
 the same priority levels are set for both even and odd planes.
 To see what the priority levels are, refer to the lesson.

To change the priority level several times on the same screen, we use
the copper, which allows us to change the priority when the sprites are
between one range and another. Here are the values for $dff104 (BPLCON2):

543210
$0 = %000000 - all sprites below
$9 = %001001 - sprites 0,1 above,     2,3,4,5,6,7 below
$12 = %010010 - sprites 0,1,2,3 above,      4,5,6,7 below
$1b = %011011 - sprites 0,1,2,3,4,5 above,     6,7 below
$24 = %100100 - all sprites above

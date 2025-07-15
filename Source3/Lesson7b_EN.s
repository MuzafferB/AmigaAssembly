
; Lesson 7b.s    DISPLAYING A SPRITE - RIGHT KEY TO MOVE IT


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

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088		; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

btst    #2,$dff016    ; Right mouse button pressed?
bne.s    Wait        ; if not, skip the routine that moves the sprite

bsr.s    MoveSprite    ; Move sprite 0 to the right

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

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

; This routine moves the sprite to the right by acting on its HSTART byte, i.e.
; the byte of its X position. Note that it moves 2 pixels each time


MoveSprite:
addq.b    #1,HSTART    ; (like writing addq.b #1,MIOSPRITE+1)
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

You can easily move the sprite, try these changes to the
MoveSprite routine:


subq.b    #1,HSTART    ; Move the sprite to the left

*

ADDQ.B    #1,VSTART    ; \ move the sprite down
ADDQ.B    #1,VSTOP    ; / (you must act on both VSTART and VSTOP!)

*
SUBQ.B    #1,VSTART    ; \ move the sprite up
SUBQ.B    #1,VSTOP    ; / (you must act on both VSTART and VSTOP!)

*

ADDQ.B    #1,HSTART    ;\
ADDQ.B    #1,VSTART    ; \ move diagonally down-right
ADDQ.B    #1,VSTOP    ; /

*

SUBQ.B    #1,HSTART    ;\
ADDQ.B	#1,VSTART    ; \ move diagonally down-left
ADDQ.B    #1,VSTOP    ; /

*

ADDQ.B    #1,HSTART    ;\
SUBQ.B    #1,VSTART    ; \ move diagonally up-right
SUBQ.B    #1,VSTOP    ; /

*

SUBQ.B    #1,HSTART    ;\
SUBQ.B    #1,VSTART    ; \ move diagonally up-left
SUBQ.B    #1,VSTOP    ; /

*

Then try changing the added/subtracted value to make more unusual trajectories
.

SUBQ.B    #3,HSTART    ;\
SUBQ.B    #1,VSTART    ; \ move diagonally up-far left
SUBQ.B    #1,VSTOP    ; /

Etc. Etc.


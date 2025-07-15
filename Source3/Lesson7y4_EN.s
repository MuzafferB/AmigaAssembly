
; Lesson 7y4.s    - Landscape made with only 2 sprites!

; This example shows how it is possible to generate an entire 
;    screen using the sprite registers directly


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

;    DO NOT point to the sprite!!!!!!!!!!!!!!!!!!!!


move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
btst    #6,$bfe001    ; mouse pressed?
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
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0001001000000000    ; bit 12 on!! 1 lowres bitplane

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w $01ba,$0fff        ; colour 29
dc.w $01bc,$0aaa        ; colour 30
dc.w $01be,$0753        ; colour 31

; for convenience, we use symbols. Remember that you can define a symbol
; or EQUATE in two ways, namely, as in this case, by entering the name of the
; symbol you want to create without spaces, followed by an = and the value
; that the symbol should represent, or in the same way, but with the
; symbol EQU instead of =.

spr6pos        = $170
spr6data    = $174
spr6datb    = $176
spr7pos        = $178
spr7data    = $17c
spr7datb	= $17e

; line $50
dc.w    $5025,$fffe
dc.w    spr6data,$0,spr6datb,$0,spr7data,$f000,spr7datb,$0
dc.w    spr6pos,$40,spr7pos,$48,$504b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$505b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$506b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$507b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$508b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$509b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$50ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$50bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$50cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$50db,$fffe

; line $51
dc.w    $5125,$fffe
dc.w    spr6data,$0001,spr6datb,$0000,spr7data,$b800,spr7datb,$4000
dc.w    spr6pos,$40,spr7pos,$48,$514b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$515b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$516b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$517b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$518b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$519b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$51ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$51bb,$fffe
dc.w	spr6pos,$c0,spr7pos,$c8,$51cb,$fffe
dc.w	spr6pos,$d0,spr7pos,$d8,$51db,$fffe

; line $52
dc.w    $5225,$fffe
dc.w    spr6data,$0003,spr6datb,$0000,spr7data,$bc00,spr7datb,$4000
spr6pos,$40,spr7pos,$48,$524b,$fffe
spr6pos,$50,spr7pos,$58,$525b,$fffe
spr6pos,$60,spr7pos,$68,$526b,$fffe
spr6pos,$70,spr7pos,$78,$527b,$fffe	
spr6pos,$70,spr7pos,$78,$527b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$528b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$529b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$52ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$52bb,$fffe
dc.w	spr6pos,$c0,spr7pos,$c8,$52cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$52db,$fffe

; line $53
dc.w    $5325,$fffe
dc.w	spr6data,$0002,spr6datb,$0001,spr7data,$ec00,spr7datb,$1200
dc.w	spr6pos,$40,spr7pos,$48,$534b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$535b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$536b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$537b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$538b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$539b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$53ab,$fffe
spr6pos,$b0,spr7pos,$b8,$53bb,$fffe
spr6pos,$c0,spr7pos,$c8,$53cb,$fffe
spr6pos,$d0,spr7pos,$d8,$53db,$fffe

; line $54
dc.w    $5425,$fffe
dc.w    spr6data,$0007,spr6datb,$0000,spr7data,$2b00,spr7datb,$d400
dc.w    spr6pos,$40,spr7pos,$48,$544b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$545b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$546b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$547b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$548b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$549b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$54ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$54bb,$fffe
dc.w	spr6pos,$c0,spr7pos,$c8,$54cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$54db,$fffe

; line $55
dc.w    $5525,$fffe
dc.w    spr6data,$001c,spr6datb,$0003,spr7data,$e780,spr7datb,$1800
dc.w    spr6pos,$40,spr7pos,$48,$554b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$555b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$556b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$557b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$558b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$559b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$55ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$55bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$55cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$55db,$fffe

; line $56
dc.w    $5625,$fffe
dc.w    spr6data,$803e,spr6datb,$0001,spr7data,$9ac1,spr7datb,$6500
dc.w    spr6pos,$40,spr7pos,$48,$564b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$565b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$566b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$567b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$568b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$569b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$56ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$56bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$56cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$56db,$fffe

; line $57
dc.w    $5725,$fffe
dc.w	spr6data,$c079,spr6datb,$0006,spr7data,$b6e7,spr7datb,$4910
dc.w	spr6pos,$40,spr7pos,$48,$574b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$575b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$576b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$577b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$578b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$579b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$57ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$57bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$57cb,$fffe
dc.w	spr6pos,$d0,spr7pos,$d8,$57db,$fffe

; line $58
dc.w    $5825,$fffe
dc.w    spr6data,$c07f,spr6datb,$0048,spr7data,$fff6,spr7datb,$2009
dc.w    spr6pos,$40,spr7pos,$48,$584b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$585b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$586b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$587b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$588b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$589b,$fffe
spr6pos,$a0,spr7pos,$a8,$58ab,$fffe
spr6pos,$b0,spr7pos,$b8,$58bb,$fffe
spr6pos,$c0,spr7pos,$c8,$58cb,$fffe
spr6pos,$d0,spr7pos,$d8,$58db,$fffe	
spr6pos,$d0,spr7pos,$d8,$58db,$fffe

; line $59
dc.w    $5925,$fffe
dc.w    spr6data,$e06f,spr6datb,$0096,spr7data,$7eaf,spr7datb,$a150
dc.w    spr6pos,$40,spr7pos,$48,$594b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$595b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$596b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$597b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$598b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$599b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$59ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$59bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$59cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$59db,$fffe

; line $5a
dc.w    $5a25,$fffe
dc.w	spr6data,$61ed,spr6datb,$9013,spr7data,$dfff,spr7datb,$6cab
dc.w    spr6pos,$40,spr7pos,$48,$5a4b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$5a5b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$5a6b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$5a7b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$5a8b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$5a9b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$5aab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$5abb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$5acb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$5adb,$fffe

; line $5b
dc.w    $5b25,$fffe
dc.w    spr6data,$db9f,spr6datb,$72ed,spr7data,$ffff,spr7datb,$dbee
dc.w	spr6pos,$40,spr7pos,$48,$5b4b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$5b5b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$5b6b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$5b7b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$5b8b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$5b9b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$5bab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$5bbb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$5bcb,$fffe
dc.w	spr6pos,$d0,spr7pos,$d8,$5bdb,$fffe

; line $5c
dc.w    $5c25,$fffe
dc.w    spr6data,$ffff,spr6datb,$cfbf,spr7data,$ffff,spr7datb,$ff3f
spr6pos,$40,spr7pos,$48,$5c4b,$fffe
spr6pos,$50,spr7pos,$58,$5c5b,$fffe
spr6pos,$60,spr7pos,$68,$5c6b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$5c7b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$5c8b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$5c9b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$5cab,$fffe
spr6pos,$b0,spr7pos,$b8,$5cbb,$fffe
spr6pos,$c0,spr7pos,$c8,$5ccb,$fffe
spr6pos,$d0,spr7pos,$d8,$5cdb,$fffe

; line $5d
spr6	$5d25,$fffe
dc.w    spr6data,$ffff,spr6datb,$ffff,spr7data,$ffff,spr7datb,$feff
spr6pos,$40,spr7pos,$48,$5d4b,$fffe
spr6pos,$50,spr7pos,$58,$5d5b,$fffe
spr6pos,$60,spr7pos,$68,$5d6b,$fffe
spr6pos,$70,spr7pos,$78,$5d7b,$fffe
spr6pos,$80,spr7pos,$88,$5d8b,$fffe
spr6pos,$90,spr7pos,$98,$5d9b,$fffe	
spr6pos,$90,spr7pos,$98,$5d9b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$5dab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$5dbb,$fffe
dc.w	spr6pos,$c0,spr7pos,$c8,$5dcb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$5ddb,$fffe

; copper instructions to disable sprites
dc.w    $5107,$fffe        ; wait for start of line
dc.w    $172,0            ; spr6ctl
dc.w    $17a,0            ; spr7ctl

dc.w    $FFFF,$FFFE    ; End of copperlist


SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

As you can see, it is possible to display a sprite more than twice on the
same line, provided you know how to program in assembler.
In this example, we use 2 sprites (6 and 7), displaying them 10 times each per
line, for a total of 16*20=320 pixels per line.
In practice, we cover the entire screen. The idea is the same as in the
, i.e. to change the values of the sprite registers with the
copper. This time, however, in addition to changing the position, we also change the shape of the sprites on each
line by modifying the values of the SPRxDATA
and SPRxDATB registers, so as to form a landscape. For simplicity, our
landscape is 14 lines high, but you could fill the screen!
Each line of the copperlist is done in this way:

; line $50
dc.w    $5025,$fffe
dc.w    spr6data,$0,spr6datb,$0,spr7data,$f000,spr7datb,$0
dc.w    spr6pos,$40,spr7pos,$48,$504b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$505b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$506b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$507b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$508b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$509b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$50ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$50bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$50cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$50db,$fffe

In this case, we have taken the part of the copperlist relating to line $50.
Let's look at the meaning of all the instructions:

dc.w    $5025,$fffe    ; WAIT

The first instruction is used to wait for the electronic brush to reach
the horizontal position $25 of the current line.

dc.w    spr6data,$0,spr6datb,$0,spr7data,$f000,spr7datb,$0

These instructions are used to set the values of the DATA registers for this line,
 which determine the shape of the sprite.

dc.w    spr6pos,$40,spr7pos,$48,$504b,$fffe

These instructions are used to change the positions of the sprites.
They work as in the previous example. First, the positions of the sprites are updated
, and then we wait for the two sprites to be displayed.
At this point, we repeat 10 groups of copper instructions like this, which
in turn modify the positions of the sprites and wait with WAITs that
separate the displayed sprites by 16 horizontal pixels ($4b, $5b, $6b...).
For example, we find

dc.w    spr6pos,$50,spr7pos,$58,$505b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$506b,$fffe

We divide a line into the 3 commands it contains:

dc.w    spr6pos,$50    ; determines the position of sprite6
dc.w    spr7pos,$58    ; determines the position of sprite7
dc.w    $505b,$fffe    ; WAIT - wait 16 pixels ahead.

And so on.
After 10 groups like this, we have drawn an entire row. At this point, all we have to do
is repeat everything we did for row $50 for
all the other rows of the landscape. Obviously, for each row we will have a
different value in the SPRxDATx registers, which will determine a different shape for
the sprite.

Of course, to generate such long and complex copperlists,
special ‘GeneraCopperlist’ routines are written, but due to their complexity,
they have not yet been included in the course. The important thing in this listing is to understand
the mechanism of reusing sprites by acting directly on the registers with
the copperlist.



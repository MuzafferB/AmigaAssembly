
; Lesson7y5.s    - Landscape made with only 2 sprites that scroll

; This example shows how it is possible to generate an entire
;    screen using the registers of 2 sprites (6 and 7)
; The screen is also ‘scrolled’


SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

;    Point to an ‘empty’ bitplane 

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
cmpi.b    #$aa,$dff006    ; Line $aa?
bne.s    mouse

bsr.w    MoveLandscape    ; Scrolls the landscape

Wait:
cmpi.b    #$aa,$dff006    ; line $aa?
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


; This routine scrolls the data of the sprites that form the landscape

MoveLandscape:
moveq    #14-1,d0    ; number of lines
lea    SpriteShape,a0    ; address of the first sprite data
PaeLoop:

; scrolls plane A of the sprites

move.w    (a0),d1        ; reads the value of spr6data
swap    d1        ; puts it in the upper word of the register
move.w    8(a0),d1    ; reads the value of spr7data

ror.l    #1,d1        ; scrolls the bits of the sprite shape
move.w    d1,8(a0)    ; writes the value of spr7data
swap    d1        ; swaps the words in the register
move.w    d1,(a0)        ; writes the value of spr6data

; scrolls sprite plane B

move.w    4(a0),d1    ; reads value of spr6datb
swap    d1        ; puts it in the upper word of the register
move.w    12(a0),d1    ; reads value of spr7datb

ror.l    #1,d1        ; scrolls the bits of the sprite shape
move.w    d1,12(a0)    ; writes the value of spr7datb
swap    d1        ; swaps the words in the register
move.w    d1,4(a0)    ; writes the value of spr6datb

add.w    #140,a0        ; next line of the landscape
dbra    d0,PaeLoop

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

dc.w    $01ba,$0fff        ; colour 29
dc.w	$01bc,$0aaa        ; colour 30
dc.w    $01be,$0753        ; colour 31

; for convenience, we use symbols

spr6pos        = $170
spr6data    = $174
spr6datb    = $176
spr7pos        = $178
spr7data    = $17c
spr7datb    = $17e

; line $50 - (copper instructions for a line are 140 bytes long)

dc.w    $5025,$fffe    ; Wait
dc.w    spr6data
SpriteForm:            ; From this label we will make the offsets to
dc.w    $0        ; reach all the other sprxdat
dc.w    spr6datb
dc.w    $0
dc.w    spr7data
dc.w    $f000
dc.w    spr7datb
dc.w    $0
dc.w    spr6pos,$40,spr7pos,$48,$504b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$505b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$506b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$507b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$508b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$509b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$50ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$50bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$50cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$50db,$fffe

; line $51
dc.w    $5125,$fffe
dc.w    spr6data,$0001,spr6datb,$0000,spr7data,$b800,spr7datb,$4000
dc.w    spr6pos,$40,spr7pos,$48,$514b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$515b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$516b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$517b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$518b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$519b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$51ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$51bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$51cb,$fffe
dc.w	spr6pos,$d0,spr7pos,$d8,$51db,$fffe

; linea $52
dc.w	$5225,$fffe
dc.w	spr6data,$0003,spr6datb,$0000,spr7data,$bc00,spr7datb,$4000
dc.w	spr6pos,$40,spr7pos,$48,$524b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$525b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$526b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$527b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$528b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$529b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$52ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$52bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$52cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$52db,$fffe

; line $53
dc.w    $5325,$fffe
dc.w    spr6data,$0002,spr6datb,$0001,spr7data,$ec00,spr7datb,$1200
dc.w    spr6pos,$40,spr7pos,$48,$534b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$535b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$536b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$537b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$538b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$539b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$53ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$53bb,$fffe
dc.w	spr6pos,$c0,spr7pos,$c8,$53cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$53db,$fffe

; line $54
dc.w	$5425,$fffe
dc.w	spr6data,$0007,spr6datb,$0000,spr7data,$2b00,spr7datb,$d400
dc.w	spr6pos,$40,spr7pos,$48,$544b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$545b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$546b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$547b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$548b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$549b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$54ab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$54bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$54cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$54db,$fffe

; line $55
dc.w    $5525,$fffe
dc.w    spr6data,$001c,spr6datb,$0003,spr7data,$e780,spr7datb,$1800
dc.w    spr6pos,$40,spr7pos,$48,$554b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$555b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$556b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$557b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$558b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$559b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$55ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$55bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$55cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$55db,$fffe

; line $56
dc.w    $5625,$fffe
dc.w    spr6data,$803e,spr6datb,$0001,spr7data,$9ac1,spr7datb,$6500
dc.w    spr6pos,$40,spr7pos,$48,$564b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$565b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$566b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$567b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$568b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$569b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$56ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$56bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$56cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$56db,$fffe

; line $57
dc.w    $5725,$fffe
dc.w    spr6data,$c079,spr6datb,$0006,spr7data,$b6e7,spr7datb,$4910
dc.w    spr6pos,$40,spr7pos,$48,$574b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$575b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$576b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$577b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$578b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$579b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$57ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$57bb,$fffe
dc.w	spr6pos,$c0,spr7pos,$c8,$57cb,$fffe
dc.w	spr6pos,$d0,spr7pos,$d8,$57db,$fffe

; line $58
dc.w    $5825,$fffe
dc.w    spr6data,$c07f,spr6datb,$0048,spr7data,$fff6,spr7datb,$2009
dc.w    spr6pos,$40,spr7pos,$48,$584b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$585b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$586b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$587b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$588b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$589b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$58ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$58bb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$58cb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$58db,$fffe

; line $59
dc.w    $5925,$fffe
dc.w    spr6data,$e06f,spr6datb,$0096,spr7data,$7eaf,spr7datb,$a150
dc.w    spr6pos,$40,spr7pos,$48,$594b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$595b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$596b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$597b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$598b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$599b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$59ab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$59bb,$fffe
dc.w	spr6pos,$c0,spr7pos,$c8,$59cb,$fffe
dc.w	spr6pos,$d0,spr7pos,$d8,$59db,$fffe

; line $5a
dc.w    $5a25,$fffe
dc.w    spr6data,$61ed,spr6datb,$9013,spr7data,$dfff,spr7datb,$6cab
dc.w    spr6pos,$40,spr7pos,$48,$5a4b,$fffe
spr6pos,$50,spr7pos,$58,$5a5b,$fffe
spr6pos,$60,spr7pos,$68,$5a6b,$fffe
spr6pos,$70,spr7pos,$78,$5a7b,$fffe
spr6pos,$80,spr7pos,$88,$5a8b,$fffe	
spr6pos,$80,spr7pos,$88,$5a8b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$5a9b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$5aab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$5abb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$5acb,$fffe
spr6pos,$d0,spr7pos,$d8,$5adb,$fffe

; line $5b
dc.w    $5b25,$fffe
dc.w    spr6data,$db9f,spr6datb,$72ed,spr7data,$ffff,spr7datb,$dbee
dc.w    spr6pos,$40,spr7pos,$48,$5b4b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$5b5b,$fffe
dc.w    spr6pos,$60,spr7pos,$68,$5b6b,$fffe
dc.w    spr6pos,$70,spr7pos,$78,$5b7b,$fffe
dc.w    spr6pos,$80,spr7pos,$88,$5b8b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$5b9b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$5bab,$fffe
dc.w	spr6pos,$b0,spr7pos,$b8,$5bbb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$5bcb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$5bdb,$fffe

; line $5c
dc.w    $5c25,$fffe
dc.w    spr6data,$ffff,spr6datb,$cfbf,spr7data,$ffff,spr7datb,$ff3f
dc.w    spr6pos,$40,spr7pos,$48,$5c4b,$fffe
dc.w    spr6pos,$50,spr7pos,$58,$5c5b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$5c6b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$5c7b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$5c8b,$fffe
dc.w	spr6pos,$90,spr7pos,$98,$5c9b,$fffe
dc.w	spr6pos,$a0,spr7pos,$a8,$5cab,$fffe
dc.w    spr6pos,$b0,spr7pos,$b8,$5cbb,$fffe
dc.w    spr6pos,$c0,spr7pos,$c8,$5ccb,$fffe
dc.w    spr6pos,$d0,spr7pos,$d8,$5cdb,$fffe

; line $5d
dc.w    $5d25,$fffe
dc.w    spr6data,$ffff,spr6datb,$ffff,spr7data,$ffff,spr7datb,$feff
dc.w	spr6pos,$40,spr7pos,$48,$5d4b,$fffe
dc.w	spr6pos,$50,spr7pos,$58,$5d5b,$fffe
dc.w	spr6pos,$60,spr7pos,$68,$5d6b,$fffe
dc.w	spr6pos,$70,spr7pos,$78,$5d7b,$fffe
dc.w	spr6pos,$80,spr7pos,$88,$5d8b,$fffe
dc.w    spr6pos,$90,spr7pos,$98,$5d9b,$fffe
dc.w    spr6pos,$a0,spr7pos,$a8,$5dab,$fffe
spr6pos,$b0,spr7pos,$b8,$5dbb,$fffe
spr6pos,$c0,spr7pos,$c8,$5dcb,$fffe
spr6pos,$d0,spr7pos,$d8,$5ddb,$fffe

; copper instructions to disable sprites

dc.w    $5e07,$fffe        ; wait for start of line
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

In this example, we scroll the landscape created with sprites.
To do this, we cannot use the BPLCON1 register, which we used
to scroll the bitplanes, because it has no effect on sprites.
To scroll the landscape, we need to scroll all the pixels that make it up.
 In this case, it is very useful that the landscape
is always made up of the same figure that repeats horizontally
every 32 pixels.
In fact, the landscape consists of 2 sprites 
(16 pixels each) that
repeat themselves identically throughout the row. To scroll the entire landscape,
we simply need to scroll the pixels that make up the shape of the 2 sprites.
However, these pixels are written to the registers
SPR6DATA, SPR6DATB, SPR7DATA and SPR7DATB with each new row of the landscape.
So we will have to scroll the contents of these registers
found in the copperlist. At the address FormaSprite in the copperlist
we can find the data that is written in SPR6DATA in the first line of the 
landscape. Respectively 4, 8 and 12 bytes later, there is the content of the registers
SPR6DATB, SPR7DATA and SPR7DATB, also in the first row.
By scrolling through the contents of our registers in all 14 rows of the
landscape, we will have achieved our goal.

Let's now see how to scroll, for example to the right

We already know an instruction that scrolls the pixels of a memory location
or a register of the 68000, the LSR. This instruction scrolls
the bits to the right and inserts bits with a value of 0 on the left.
For example:

move.b #%00100101,d0
lsr.b #3,d0

After these instructions, d0 will contain the value %00000100
In our case, this is not good, because the bits with a value of 0 that enter from the
left produce a ‘hole’ in the sprite that gets bigger and bigger, until
it completely erases the figure.

What we need is an instruction that shifts the bits to the
right, but brings back to the left the bits that have gone to the right.
In other words, it rotates the bits within the register.
This instruction exists and is called ROR (‘ROtate Right’).
Let's look at an example:

move.b #%00100101,d0
ror.b #3,d0

After these instructions, d0 will contain the value %10100100. In practice, the 3
bits that were on the right before the ROR have returned from the left,
following the path shown below:

bit: 7 6 5 4 3 2 1 0
-----------------
| | | | | | | | |
-----------------
-> --> --> -->
| | direction of scrolling.
<-- <-- <-- <-

The ‘MoveLandscape’ routine uses a ROR instruction to scroll
the pixels. Note that the contents of the SPR6DATA register and the contents of
SPR7DATA are placed in the same register and are rotated
together, so that the bits that exit SPR6DATA on the left enter SPR7DATA on the right
and the bits that exit SPR7DATA on the left enter SPR6DATA on the right
SPR6DATA.
The same operation is repeated for the contents of registers 
SPR6DATB and SPR7DATB, which make up the second layer of sprites.

To better understand the difference between LSR and ROR, try
replacing LSR with ROR in the ‘MoveLandscape’ routine.
You will see that this is not exactly what we wanted!

Of course, in addition to ROR, there is an instruction for rotating bits to the
left, called ROL (‘ROtate Left’), which works in exactly the
same way. You can safely replace ROR with it and you will see the landscape
scroll in the opposite direction.

In theory, with only 2 sprites you could fill the entire screen, starting
with the clouds at the top, then the mountains, the prairie and the trees in the foreground,
and you could even make the various levels of the
parallax move at different speeds, i.e. the ‘distant’ mountains more slowly, the prairie at medium speed,
and the trees in the foreground quickly. All this would require a huge copperlist
and the routine to move everything would be very slow, which is one of the
reasons why parallaxes of this kind are made with bitplanes, which
are more colourful and faster to move. However, if anyone dared to say that
the Amiga only has 8 small sprites, you could show them the parallax screen
made with sprites superimposed on a 4096-colour HAM drawing,
 and you would still have 6 sprites left over to make stars and a few
spaceships. If you then ran a hundred BOBs with the
blitter in the middle... maybe you wouldn't understand anything anymore, but it would be interesting.

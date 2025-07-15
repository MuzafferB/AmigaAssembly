
; Lesson 7w1.s    COLLISION BETWEEN SPRITES


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
MOVEQ    #2-1,D1
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP

;    Point to the sprite

LEA    SpritePointers,a1    ; Pointers in copperlist
MOVE.L    #MIOSPRITE0,d0        ; sprite address in d0
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
add.l    #16,a1

MOVE.L    #MIOSPRITE2,d0        ; sprite address in d0
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

bsr.s    MoveSprite0    ; Move the plane
bsr.s    MoveSprite1    ; Move the missile towards the plane
bsr.s    CheckColl    ; Check for collision and take action

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; Mouse pressed?
bne.s    mouse

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

; This routine moves the aircraft sprite in a straight line to the left
; 2 pixels at a time, acting on its HSTART

MoveSprite0:
subq.b    #1,HSTART0
rts

;    -        -        -		-

; This routine moves the missile. It only does so if the plane is close enough
; to hit it. The plane is within range when its HSTART is at $b0.
; If you want to save the plane, try launching the missile at position
; $AA, i.e. too early, or at position $c1, i.e. too late.

MoveSprite1:
cmp.b    #$b0,HSTART0    ; Is the aircraft within range?
bhi.s    not_in_range    ; do not launch if the aircraft is too far to the right
subq.b    #1,VSTART2    ; raise the missile by acting on both
subq.b    #1,VSTOP2	; VSTART and VSTOP
not_on_target:
rts

;    -        -        -

; This routine checks for collisions. If there is one, it deletes
; the two sprites, resetting the relevant pointers in the copperlist

CheckColl:
move.w    $dff00e,d0    ; reads CLXDAT ($dff00e)
; reading this register also causes
; it to be deleted, so it is best to
; copy it to d0 and test on d0
btst.l    #9,d0
beq.s    no_coll        ; if there is no collision, jump

MOVEQ    #0,d0         ; otherwise, clear the sprites
LEA    SpritePointers,a1 ; sprite pointer 0
move.w    d0,6(a1)     ; reset sprite pointer 0 in the copperlist
move.w    d0,2(a1)
add.w    #16,a1        ; sprite pointer 2
move.w    d0,6(a1)    ; reset sprite pointer 2 in copperlist
move.w    d0,2(a1)
no_coll:
rts


SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w    $12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,$0024    ; BplCon2 - Sprites in front of the bitplanes
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0010001000000000    ; bit 13 on!! 2 lowres bitplanes

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane
dc.w $e4,0,$e6,0    ;first     bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$005    ; colour1    ; colour 1 of the bitplane
dc.w    $184,$a40    ; colour1    ; colour 2 of the bitplane
dc.w    $186,$f80    ; colour1    ; colour 3 of the bitplane

dc.w    $1A2,$06f    ; colour17, i.e. COLOUR1 of sprite0
dc.w    $1A4,$0c0    ; colour18, i.e. COLOUR2 of sprite0
dc.w    $1A6,$0c0    ; colour19, i.e. COLOUR3 of sprite0

dc.w    $1AA,$444    ; colour21, i.e. COLOUR1 of sprite2
dc.w    $1AC,$888    ; colour22, i.e. COLOUR2 of sprite2
dc.w    $1AE,$0c0    ; colour23, i.e. COLOUR3 of sprite2

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE0:        ; length 6 lines
VSTART0:
dc.b 180    ; Vertical position of sprite start (from $2c to $f2)
HSTART0:
dc.b $d8    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP0:
dc.b 186    ; 180+6=186
VHBITS:
dc.b $00
dc.w    $0008,$0000
dc.w    $1818,$0000
dc.w    $2C28,$1010
dc.w    $7FF8,$0000
dc.w    $3FC0,$0000
dc.w    $01F0,$0000
dc.w    $0000,$0000

MIOSPRITE2:        ; length 16 lines
VSTART2:
dc.b 224    ; Vertical position of sprite start (from $2c to $f2)
HSTART2:
dc.b $86    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP2:
dc.b 240
dc.b 0
dc.w    $0200,$0000
dc.w    $0200,$0000
dc.w    $0200,$0000
dc.w    $0000,$0200
dc.w    $0000,$0700
dc.w    $0000,$0700
dc.w    $0500,$0200
dc.w    $0200,$0500
dc.w    $0500,$0200
dc.w    $0200,$0500
dc.w    $1540,$0200
dc.w    $0200,$1DC0
dc.w    $0000,$1FC0
dc.w    $0000,$1740
dc.w    $0500,$0200
dc.w    $0000,$0000
dc.w    $0000,$0000

;    Launch ramp figure

PIC:
incbin    ‘paesaggio.raw’

end

In this example, we see how to detect a collision between two sprites.
We have two objects that collide. Note that for the two objects we have used
sprites 0 and 2, i.e. two sprites belonging to two different groups.
This fact allows us, as we have already seen, to use
two different palettes for the two objects, but it is also necessary in order to
exploit the collision between sprites. In fact, it is only possible to detect
collisions between sprites belonging to different pairs, and not between sprites
belonging to the same pair. To detect a collision, simply check
the status of a bit in the CLXDAT register, as we have already seen in the lesson.

When the collision bit is 1, then the collision has actually occurred.
 Our example simply deletes the two
sprites, clearing the corresponding pointers in the copperlist. You can improve 
the example by adding a nice explosion. It's very simple. First
draw a sprite representing an explosion and add it to the
source (make sure it goes in the SECTION that goes in the CHIP memory).
Then modify the ChekColl routine: when a collision is detected,
 replace the instructions

MOVEQ    #0,d0        ; otherwise delete the sprites
LEA    SpritePointers,a1    ; sprite pointer 0
move.w    d0,6(a1)    ; reset sprite pointer 0 in the copperlist
move.w    d0,2(a1)

with the instructions

MOVE.L    #SPRITE_ESPLOSIONE,d0    ; explosion sprite address
LEA    SpritePointers,a1    ; sprite pointer 0
move.w    d0,6(a1)    ; modify sprite pointer 0 in copperlist
swap    d0
move.w    d0,2(a1)

This way, instead of deleting the sprite, you will replace the
airplane drawing with the explosion drawing. You will also need to be careful
to copy the bytes that control the position of the airplane (VSTART0,HSTART0)
to the corresponding bytes that control the explosion sprite. You should be able to do this
by now. Just pay a little attention
to VSTOP: if the explosion drawing has a different height than the
airplane, you can't just copy VSTOP, you'll have to adjust it.
Nothing difficult, though.

In this example, we deliberately made the two sprites follow very
simple trajectories (straight lines) to better show the collision mechanism.
 You can try replacing the two routines that move the sprites
with one of the routines that use tables that we used in the other examples.

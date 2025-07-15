
; Lesson7w2.s    COLLISION BETWEEN ODD SPRITES
; In this example, we will see how to detect collisions between odd sprites.
; This time, there are two missiles chasing the plane, and one of the two is an
; odd sprite.
; If you run the program, you will see that the missile on the right does not
; work.
; Want to fix it? Read the final comment!


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

add.l    #16,a1            ; sprite pointer 2
MOVE.L    #MIOSPRITE2,d0        ; sprite address in d0
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

add.l    #8,a1            ; sprite pointer 3
MOVE.L    #MIOSPRITE3,d0        ; sprite address in d0
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080	; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    MoveSprite0    ; Move the plane
bsr.s    MoveSprite2    ; Move missile 1 towards the plane
bsr.s    MoveSprite3    ; Move missile 2 towards the plane
bsr.w    CheckColl    ; Check for collision and take action

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

; This routine moves the aircraft sprite in a straight line 2 pixels at a time

MoveSprite0:
subq.b    #1,HSTART0
rts


; This routine moves the missile. It only does so if the plane is close enough
; to hit it.

MoveSprite2:
cmp.b    #$b0,HSTART0
bhi.s    non_a_tiro2    ; do not start if the plane is too far to the right
subq.b    #1,VSTART2
subq.b    #1,VSTOP2
not_shooting2:
rts


; This routine moves the missile. It only does so if the plane is close enough
; to hit it.

MoveSprite3:
cmp.b    #$d0,HSTART0
bhi.s    not_shooting3	; do not start if the aircraft is too far to the right
subq.b    #1,VSTART3
subq.b    #1,VSTOP3
not_shooting3:
rts

; This routine checks for collisions. If there is one, it deletes
; the two sprites that collided, resetting the relevant pointers in the
; copperlist. To distinguish which of the two missiles hit the plane,
; the positions are checked. In fact, in this example, the missiles
; can only hit the plane from below; therefore, if a missile is
; higher than the plane, it CANNOT have hit it. In this way, we can
; understand which of the two missiles hit the plane.

CheckColl:
move.w    $dff00e,d0    ; reads CLXDAT ($dff00e)
; reading this register also causes
; it to be deleted, so it is best to
; copy it to d0 and test on d0
btst.l    #9,d0
beq.s    no_coll        ; if there is no collision, jump

MOVEQ    #0,d0         ; otherwise, delete the aircraft
LEA    SpritePointers,a1 ; sprite pointer 0
move.w    d0,6(a1)     ; reset sprite pointer 0 in copperlist
move.w    d0,2(a1)

; now we need to figure out which of the two missiles hit the plane.
; check the height of the missile furthest to the right: if it is higher
; it did NOT hit the plane, otherwise it was the one that hit it

move.b    VSTART0,d1    ; reads the height of the plane
cmp.b    VSTART3,d1    ; compares it with the height of the missile on the right
bhi.s    spr2_coll    ; if the plane is lower
; (so VSTART0 is GREATER than VSTART3)
; the collision is caused by sprite 2

LEA    SpritePointer3,a1 ; otherwise delete sprite 3
move.w    d0,6(a1)     ; reset sprite pointer 3 in copperlist
move.w    d0,2(a1)
bra.s    no_coll

spr2_coll:
LEA    SpritePointer2,a1 ; delete sprite 2
move.w    d0,6(a1)     ; reset sprite pointer 2 in copperlist
move.w    d0,2(a1)
no_coll:
rts



SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0
SpritePointer2:
dc.w    $128,0,$12a,0
SpritePointer3:
dc.w    $12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

; 5432109876543210
dc.w    $98,%0000000000000000    ; CLXCON $dff098

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,$0024    ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0010001000000000    ; 2 lowres bitplanes

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane
dc.w $e4,0,$e6,0    ;first     bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$005    ; colour1	; colour 1 of the bitplane
dc.w    $184,$a40    ; colour1    ; colour 2 of the bitplane
dc.w    $186,$f80    ; colour1    ; colour 3 of the bitplane

dc.w    $1A2,$06f    ; colour17, i.e. COLOUR1 of sprite0
dc.w	$1A4,$0c0    ; colour18, i.e. COLOUR2 of sprite0
dc.w    $1A6,$0c0    ; colour19, i.e. COLOUR3 of sprite0

dc.w    $1AA,$444    ; colour21, i.e. COLOUR1 of sprite2
dc.w    $1AC,$888	; color22, i.e. COLOR2 of sprite2
dc.w    $1AE,$0c0    ; color23, i.e. COLOR3 of sprite2

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

MIOSPRITE3:        ; length 16 lines
VSTART3:
dc.b 224    ; Vertical position of sprite start (from $2c to $f2)
HSTART3:
dc.b $a6    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP3:
dc.b 240
dc.b 0
dc.w    $0200,$0000
dc.w    $0200,$0000
dc.w    $0200,$0000
dc.w    $0000,$0200
dc.w    $0000,$0700
dc.w	$0000,$0700
dc.w	$0500,$0200
dc.w	$0200,$0500
dc.w	$0500,$0200
dc.w	$0200,$0500
dc.w	$1540,$0200
dc.w	$0200,$1DC0
dc.w	$0000,$1FC0
dc.w	$0000,$1740
dc.w	$0500,$0200
dc.w	$0000,$0000
dc.w    $0000,$0000

;    launch ramp figure

PIC:
incbin    ‘paesaggio.raw’

end

As we saw in the lesson, the CLXDAT register allows us to detect
collisions between groups of sprites and not between individual sprites. In this example
, we will see how to solve the problem. Remember that while collisions between
even sprites (i.e. sprites 0, 2, 4, 6) are always disabled, those between odd sprites
(1, 3, 5, 7) must be enabled using control bits in the
CLXCON register ($dff098). Each odd sprite has its own control bit
and can therefore be enabled independently of the others. If you try to
run our example, you will notice that the missile on the far right does not work.
This is because the missile on the far right is an odd sprite
(sprite 3) and is disabled. In fact, in the copperlist you can find
the instruction:
; 5432109876543210
dc.w    $98,%0000000000000000

This disables all odd sprites for collisions (for the precise meaning
of all the bits, see the lesson). To enable sprite 3,
bit 13 must be set to 1, i.e. the copper instruction must be modified as follows:

; 5432109876543210
dc.w    $98,%0010000000000000

Try running the example, and you will see that the missile now works!

Another problem with collisions is that the CLXDAT register reveals collisions
between groups of sprites, not between individual sprites. In our example, there are
two missiles that belong to the same group. So when there is a 
collision, we cannot know which of the two missiles hit the plane by reading
the CLXDAT register. To do this, the most common method is to check the
positions of the sprites. In this particularly simple example, just
check whether the rightmost sprite is above the plane or not,
as explained in more detail in the comment to the CheckColl routine.
In more complex situations with sprites moving in multiple directions,
 it is necessary to perform more accurate checks, based on both vertical
and horizontal positions. However, the principle is always the same.

You can verify that our routine always identifies the correct missile
by changing the starting position of the rightmost sprite.
The initial value of HSTART3 is $a6 and ensures that the missile hits
the aircraft. Replace $a6 with $b6. If you run the example, you will see that the missile
is too far to the right and will therefore miss the aircraft. But don't worry! 
The second one will still hit the target!

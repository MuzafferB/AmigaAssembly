
; Lesson 7x1.s    COLLISION BETWEEN SPRITE AND PLAYFIELD
;        In this example, there is a sprite that crosses rectangles
;        of different colours. When the sprite touches a certain
;        colour, a detector lights up.

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

;    Point to the sprite

LEA    SpritePointers,a1    ; Pointers in copperlist
MOVE.L    #MIOSPRITE0,d0        ; sprite address in d0
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
add.l    #16,a1

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b	#$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    MoveSprite0    ; Move the plane
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

; This routine moves the sprite in a straight line 2 pixels at a time

MoveSprite0:
subq.b    #1,HSTART0
rts


; This routine checks for collisions.
; If there is one, it ‘turns on’ the collision detector.
; The detector is simply a rectangle coloured with COLOUR 7.
; By changing the value assumed by the COLOR07 register in the copperlist,
; the detector is turned on (red) or off (grey).

CheckColl:
move.w    $dff00e,d0    ; reads CLXDAT ($dff00e)
; reading this register also causes
; it to be deleted, so it is best to
; copy it to d0 and test on d0
move.w    d0,d7
btst.l    #1,d0        ; bit 1 indicates a collision between sprite 0
; and the playfield
beq.s    no_coll        ; if there is no collision, jump

si_coll:
move.w    #$f00,detect_collision ; ‘turns on’ the detector (COLOR07)
; modifying the copperlist (red)
bra.s    exitColl        ; exit

no_coll:
move.w    #$555,detect_collision ; ‘turns off’ the detector (COLOR07)
; modifying the copperlist (grey)
exitColl:
rts



SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0


; This is the CLXCON register (controls detection mode)

; bits 0 to 5 are the values that must be assumed by the planes
; bits 6 to 11 indicate which planes are enabled for collisions
; bits 12 to 15 indicate which of the odd sprites are enabled
; for collision detection.
;5432109876543210
dc.w    $98,%0000000111000011    ; CLXCON

; These values indicate that planes 1, 2 and 3 are active for collisions, and
; that a collision is signalled when the sprite overlaps a pixel
; that has:    plane 1 = 1
;         plane 2 = 1
;        plane 3 = 0


dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1

dc.w    $104,$0024    ; BplCon2 - puts all sprites in front of the
; playfield

dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,0,$e2,0
dc.w $e4,0,$e6,0
dc.w $e8,0,$ea,0

; bitplane colours
dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$620
dc.w    $184,$fff
dc.w    $186,$e00
dc.w	$188,$808
dc.w    $18a,$f4a
dc.w    $18c,$aaa
dc.w    $18e    ; colour07 - the value loaded in this register is
; written by the ChekColl routine depending on whether
; a collision occurs or not.
detect_collision:
dc.w    0	; AT THIS POINT the CheckColl routine modifies
; the copper list by writing the correct colour.

; sprite colours
dc.w    $1A2,$00f    ; colour17, i.e. COLOUR1 of sprite0
dc.w    $1A4,$0c0    ; colour18, i.e. COLOUR2 of sprite0
dc.w    $1A6,$0c0    ; colour19, i.e. COLOUR3 of sprite0

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE0:        ; length 6 lines
VSTART0:
dc.b 200    ; Vertical position of sprite start (from $2c to $f2)
HSTART0:
dc.b $d8    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP0:
dc.b 206    ; 200+6=206
VHBITS:
dc.b $00
dc.w	$0008,$0000
dc.w	$1818,$0000
dc.w	$2C28,$1010
dc.w	$7FF8,$0000
dc.w	$3FC0,$0000
dc.w    $01F0,$0000
dc.w    $0000,$0000

PIC:
incbin    ‘collpic.raw’

end

In this example, we show how to detect collisions between sprites and plafields.
As we have already seen in the lesson, the two registers CLXDAT and CLXCON are used.
CLXDAT is simply used to determine whether a collision has occurred and is
used in exactly the same way as in the case of a collision between two sprites (except that, obviously,
a different bit is used). The use of CLXCON, on the other hand, is more complex. Let's take a closer look
at our example. We have written the following in the copper list:

;5432109876543210
dc.w    $98,%0000000111000011    ; CLXCON

Bits 6 to 11 indicate which planes are enabled for collisions. In
our example, planes 1, 2, and 3 (the planes displayed). Bits
0 to 5 indicate the values that must be assumed by the planes for
a collision to occur. In our example, a collision occurs if the 3 enabled planes
assume the following values: plane 3 = 0, plane 2 = 1, plane 1 = 1,
i.e. the sequence %011=3. The collision between the sprite
and colour 3 is detected. Note that the values that planes 4, 5 and 6 must take
are irrelevant as they are disabled.

Now modify the copper list as follows:
;5432109876543210
dc.w    $98,%0000000111000010    ; CLXCON

Now planes 1, 2 and 3 are always enabled, but the value they must take
is equal to the sequence %010, i.e. colour 2. You can check this by running
the program. It works the same way for other colours.

What if we want to detect collisions with more than 2 colours?
In some cases, this can be done by not enabling all the planes displayed.
Modify the copper list as follows:
;5432109876543210
dc.w    $98,%0000000110000010    ; CLXCON

Unlike before, we have enabled collision detection
only for planes 2 and 3. This means that the value of plane 1 has no effect
on collision detection. It is only necessary that:
plane 3 = 0 and plane 2 = 1. Since this occurs for both the binary sequence
%010 and the sequence %011, both will result in a
collision. In this way, the collision will occur for colour 2 (%010)
and colour 3 (%011).

Let's look at another example. Modify the copper list as follows:
;5432109876543210
dc.w    $98,%0000000001000001    ; CLXCON

Now only plane 1 is enabled, and the collision occurs when
plane 1 = 1. This happens for all odd colours. In fact, we have:

%001    colour 1
%011    colour 3
%101    colour 5
%111    colour 7

In all four of these combinations, plane 1 is 1.

Everything we have said also applies if the number of planes
displayed is not 3.

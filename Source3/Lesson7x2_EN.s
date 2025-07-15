
; lesson7x2.s     - Sprite collisions in Dual Playfield mode
; In this example, we show collisions between a sprite and the two playfields.
; The sprite moves from top to bottom. If a collision is detected,
; the background colour is changed (red or green depending on what is
; colliding).

SECTION	CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

; Use 2 planes for each playfield

;    Point the PICs

MOVE.L    #PIC1,d0    ; point playfield 1
LEA    BPLPOINTERS1,A1
MOVEQ    #2-1,D1
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP

MOVE.L    #PIC2,d0    ; point to playfield 2
LEA    BPLPOINTERS2,A1
MOVEQ    #2-1,D1
POINTBP2:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP2

;    Point to the sprite

MOVE.L    #MIOSPRITE0,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

move.w    #$0024,$dff104    ; BPLCON2
; with this value, all sprites are
; above both playfields

wait1:
cmp.b    #$ff,$dff006    ; Line 255?
bne.s    wait1
wait11:
cmp.b    #$ff,$dff006    ; Still line 255?
beq.s    wait11

btst    #6,$bfe001
beq.s    exit

bsr.s    MoveSprite    ; Move the sprite down
bsr.w    CheckColl    ; Check for collision and take action

bra.s    wait1

exit    move.l    OldCop(PC),$dff080    ; Point to the system cop
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

; This routine moves sprite 0 down one pixel every 2 frames
; A flag is used.

MoveSprite:
not.w    flag
beq.s    EndMoveSprite

addq.w    #1,height
cmp.w    #300,height    ; Has it reached the bottom edge?
blo.s    no_edge
move.w    #$2c,height    ; If so, put the sprite back at the top
no_edge:
move.w    height(PC),d0
CLR.B	VHBITS0        ; reset bit 8 of the vertical positions
MOVE.b    d0,VSTART0    ; copy bits 0 to 7 to VSTART
BTST.l    #8,D0        ; is the position greater than 255?
BEQ.S    NOBIGVSTART    ; if not, go further, because the bit has already been
; reset with CLR.b VHBITS

BSET.b    #2,VHBITS0    ; otherwise set bit 8 of the
; vertical starting position
NOBIGVSTART:
ADDQ.w    #8,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,VSTOP0    ; Move bits 0 to 7 in VSTOP
BTST.l    #8,D0        ; Is the position greater than 255?
BEQ.S    NOBIGVSTOP    ; If not, go ahead, because the bit has already been
; reset with CLR.b VHBITS
BSET.b	#1,VHBITS0    ; otherwise set bit 8 of the vertical position
; of the sprite end
NOBIGVSTOP:
EndMoveSprite:
rts


; This routine checks for collisions.
; If so, change the background colour by modifying the value assumed by the COLOR00 register, red or green, in the copper
; list.

CheckColl:
move.w    $dff00e,d0    ; reads CLXDAT ($dff00e)
; reading this register also causes
; it to be cleared, so it is best to
; copy it to d0 and test d0
btst.l    #1,d0        ; bit 1 indicates collision between sprite 0
; and playfield 1
beq.s    no_coll1        ; if there is no collision, jump

move.w    #$f00,detect_collision ; ‘turns on’ the detector (colour0)
; modifying the copperlist (red)
bra.s    exitColl        ; exit

no_coll1:
btst.l    #5,d0        ; bit 5 indicates collision between sprite 0
; and playfield 2
beq.s    no_coll2        ; if there is no collision, jump
move.w    #$0f0,detect_collision ; ‘turns on’ the detector (colour0)
; modifying the copperlist (green)
bra.s    exitColl        ; exit

no_coll2:
move.w    #000,detect_collision ; ‘turns off’ the detector (colour0)
; modifying the copperlist (black)
exitColl:
rts

flag:
dc.w    0
height:
dc.w    $2c


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
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0100011000000000    ; bit 10 on = dual playfield
; use 4 planes = 4 colours per playfield

BPLPOINTERS1:
dc.w $e0,0,$e2,0    ;first bitplane playfield 1 (BPLPT1)
dc.w $e8,0,$ea,0    ;second bitplane playfield 1 (BPLPT3)


BPLPOINTERS2:
dc.w $e4,0,$e6,0    ;first bitplane playfield 2 (BPLPT2)
dc.w $ec,0,$ee,0    ;second bitplane playfield 2 (BPLPT4)

; This is the CLXCON register (controls detection mode)

; bits 0 to 5 are the values that must be assumed by the planes
; bits 6 to 11 indicate which planes are enabled for collisions
; bits 12 to 15 indicate which of the odd sprites are enabled
; for collision detection.

;5432109876543210
dc.w    $98,%0000001111001011    ; CLXCON

; These values indicate that planes 1, 2, 3, and 4 are active for collisions.
; A collision with playfield 1 is signalled when the sprite overlaps
; a pixel that has:    plane 1 = 1 (bit 0)
;         plane 3 = 0 (bit 2)
; i.e. with colour 1 of playfield 1

; a collision with playfield 2 is reported when the sprite overlaps
; a pixel that has:    plane 2 = 1 (bit 1)
;         plane 4 = 1 (bit 3)
; i.e. with colour 3 of playfield 2


dc.w    $180 ; COLOR00
detect_collision:
dc.w    0    ; AT THIS POINT the CheckColl routine modifies
; the copper list by writing the correct colour.

; playfield 1 palette
dc.w    $182,$005    ; colours from 0 to 7
dc.w    $184,$a40
dc.w    $186,$f80
dc.w    $188,$f00
dc.w    $18a,$0f0
dc.w    $18c,$00f
dc.w    $18e,$080


; playfield palette 2
dc.w    $192,$367    ; colours from 9 to 15
dc.w    $194,$0cc     ; colour 8 is transparent, do not set
dc.w    $196,$a0a
dc.w    $198,$242
dc.w    $19a,$282
dc.w    $19c,$861
dc.w    $19e,$ff0


dc.w    $1A2,$F00    ; sprite palette
dc.w    $1A4,$0F0
dc.w    $1A6,$FF0

dc.w    $1AA,$FFF
dc.w    $1AC,$0BD
dc.w    $1AE,$D50

dc.w    $1B2,$00F
dc.w    $1B4,$F0F
dc.w    $1B6,$BBB

dc.w    $1BA,$8E0
dc.w    $1BC,$a70
dc.w    $1BE,$d00

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The two playfields

PIC1:    incbin    ‘colldual1.raw’
PIC2:    incbin    ‘colldual2.raw’

; ************ Here is the sprite: OBVIOUSLY in CHIP RAM! ************
MIOSPRITE0:
VSTART0:
dc.b $2c
HSTART0:
dc.b $80
VSTOP0:
dc.b $2c+8
VHBITS0
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001110001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000010001000001
dc.w	%0111111111111110,%1000010001000001
dc.w	%0011111111111100,%1100010001000011
dc.w	%0000111111110000,%1111001110001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0


end

This example shows how collisions between sprites and playfields
on a screen (dualplayfield) work. 
Collisions with the two playfields are controlled independently using two different bits of the CLXDAT register.
In our example (using sprite 0), bit 1 controls collisions with
playfield 1 (odd planes) and bit 5 controls collisions with playfield 2
(even planes).
As for the CLXCON register, everything works as in the case of a normal screen
:
bits 0 to 5 are the values that must be assumed by the planes
bits 6 to 11 indicate which planes are enabled for collisions
bits 12 to 15 indicate which of the odd sprites are enabled
for collision detection.
It is always possible to disable some planes to detect more colours
at the same time, as we showed in the lesson7w2 example.
You can try this by changing the value assigned to CLXCON in the copperlist.

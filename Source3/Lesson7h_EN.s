
; Lesson 7h.s    4 SPRITES WITH 16 COLOURS IN ATTACHED MODE MOVING ON THE SCREEN
;         USING TWO PRE-SET VALUE TABLES (i.e. vertical
;        and horizontal coordinates).
;        ** NOTE ** To view the programme and exit, press:
;		LEFT KEY, RIGHT KEY, LEFT KEY, RIGHT KEY.

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

;	Point to the 8 sprites, which when ATTACHED will form 4 sprites with 16 colours.
;    Sprites 1,3,5,7, the odd ones, must have bit 7 of the
;    second word set to 1.


MOVE.L    #MIOSPRITE0,d0        ; address of the sprite in d0
LEA	SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE1,d0        ; address of the sprite in d0
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
MOVE.L	#MIOSPRITE6,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE7,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

; Set the ATTACCHED bits

bset    #7,MIOSPRITE1+3        ; Set the ATTACCHED bit to
; sprite 1. By removing this instruction
; the sprites are not ATTACCHED, but
; two 3-colour sprites are superimposed.

bset    #7,MIOSPRITE3+3
bset    #7,MIOSPRITE5+3
bset	#7,MIOSPRITE7+3

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

;    Let's create a difference in position in the pointers to the tables between the
;    4 sprites to make them move differently from each other.

MOVE.L    #TABX+55,TABXPOINT0
MOVE.L    #TABX+86,TABXPOINT1
MOVE.L    #TABX+130,TABXPOINT2
MOVE.L	#TABX+170,TABXPOINT3
MOVE.L    #TABY-1,TABYPOINT0
MOVE.L    #TABY+45,TABYPOINT1
MOVE.L    #TABY+90,TABYPOINT2
MOVE.L    #TABY+140,TABYPOINT3


Mouse1:
bsr.w    MoveSprites    ; Waits for a frame, moves the sprites and
; returns.

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse1

MOVE.L    #TABX+170,TABXPOINT0
MOVE.L	#TABX+130,TABXPOINT1
MOVE.L    #TABX+86,TABXPOINT2
MOVE.L    #TABX+55,TABXPOINT3
MOVE.L    #TABY-1,TABYPOINT0
MOVE.L    #TABY+45,TABYPOINT1
MOVE.L    #TABY+90,TABYPOINT2
MOVE.L    #TABY+140,TABYPOINT3

Mouse2:
bsr.w    MoveSprites    ; Waits for a frame, moves the sprites and
; returns.

btst    #2,$dff016    ; Right mouse button pressed?
bne.s    mouse2

; SPRITES IN SINGLE FILE

MOVE.L    #TABX+30,TABXPOINT0
MOVE.L    #TABX+20,TABXPOINT1
MOVE.L    #TABX+10,TABXPOINT2
MOVE.L	#TABX-1,TABXPOINT3
MOVE.L    #TABY+30,TABYPOINT0
MOVE.L    #TABY+20,TABYPOINT1
MOVE.L    #TABY+10,TABYPOINT2
MOVE.L    #TABY-1,TABYPOINT3

Mouse3:
bsr.w    MoveSprites    ; Waits for a frame, moves the sprites and
; returns.

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse3

; DRUNK SPRITES FOR THE SCREEN

MOVE.L    #TABX+220,TABXPOINT0
MOVE.L    #TABX+30,TABXPOINT1
MOVE.L    #TABX+102,TABXPOINT2
MOVE.L    #TABX+5,TABXPOINT3
MOVE.L    #TABY-1,TABYPOINT0
MOVE.L    #TABY+180,TABYPOINT1
MOVE.L    #TABY+20,TABYPOINT2
MOVE.L    #TABY+100,TABYPOINT3


Mouse4:
bsr.w    MoveSprites    ; Waits for a frame, moves the sprites and
; returns.

btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse4

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


; This routine executes the individual sprite movement routines
; and also includes the frame wait loop for timing.

MoveSprites:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    MoveSprites

bsr.s    MoveSpriteX0    ; Move sprite 0 horizontally
bsr.w    MoveSpriteX1    ; Move sprite 1 horizontally
bsr.w    MoveSpriteX2    ; Move sprite 2 horizontally
bsr.w    MoveSpriteX3	; Move sprite 3 horizontally
bsr.w    MoveSpriteY0    ; Move sprite 0 vertically
bsr.w    MoveSpriteY1    ; Move sprite 1 vertically
bsr.w    MoveSpriteY2    ; Move sprite 2 vertically
bsr.w    MoveSpriteY3    ; Move sprite 3 vertically

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

rts        ; Return to MOUSE loop


; ********************* HORIZONTAL MOVEMENT ROUTINES *******************

; These routines move the sprite by acting on its HSTART byte, i.e.
; the byte of its X position, entering coordinates already established
; in the TABX table (horizontal scrolling in 2-pixel increments rather than 1)

; For sprite0 ATTACCHED: (i.e. Sprite0+Sprite1)

MoveSpriteX0:
ADDQ.L    #1,TABXPOINT0     ; Point to the next byte
MOVE.L    TABXPOINT0(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-1,A0 ; Are we at the last longword of the TAB?
BNE.S	NOBSTARTX0    ; Not yet? Then continue
MOVE.L    #TABX-1,TABXPOINT0 ; Start pointing to the first byte-1 again
NOBSTARTX0:
MOVE.b    (A0),MIOSPRITE0+1 ; Copy the byte from the table to HSTART0
MOVE.b    (A0),MIOSPRITE1+1 ; copy the byte from the table to HSTART1
rts

TABXPOINT0:
dc.l    TABX+55        ; NOTE: the table values are bytes



; For sprite1 ATTACCHED: (i.e. Sprite2+Sprite3)

MoveSpriteX1:
ADDQ.L    #1,TABXPOINT1     ; Point to the next byte
MOVE.L    TABXPOINT1(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-1,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTARTX1    ; Not yet? Then continue
MOVE.L    #TABX-1,TABXPOINT1 ; Start pointing from the first byte-1 again
NOBSTARTX1:
MOVE.b	(A0),MIOSPRITE2+1 ; copy the byte from the table to HSTART2
MOVE.b    (A0),MIOSPRITE3+1 ; copy the byte from the table to HSTART3
rts

TABXPOINT1:
dc.l    TABX+86        ; NOTE: the values in the table are bytes



; For sprite2 ATTACCHED: (i.e. Sprite4+Sprite5)

MoveSpriteX2:
ADDQ.L    #1,TABXPOINT2     ; Point to the next byte
MOVE.L    TABXPOINT2(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-1,A0 ; Are we at the last longword of TAB?
BNE.S    NOBSTARTX2    ; Not yet? Then continue
MOVE.L    #TABX-1,TABXPOINT2 ; Start pointing to the first byte-1 again
NOBSTARTX2:
MOVE.b	(A0),MIOSPRITE4+1 ; copy the byte from the table to HSTART4
MOVE.b    (A0),MIOSPRITE5+1 ; copy the byte from the table to HSTART5
rts

TABXPOINT2:
dc.l    TABX+130    ; NOTE: the table values are bytes



; For sprite3 ATTACCHED: (i.e. Sprite6+Sprite7)

MoveSpriteX3:
ADDQ.L    #1,TABXPOINT3     ; Point to the next byte
MOVE.L    TABXPOINT3(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-1,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTARTX3    ; Not yet? Then continue
MOVE.L    #TABX-1,TABXPOINT3 ; Start pointing from the first byte-1 again
NOBSTARTX3:
MOVE.b    (A0),MIOSPRITE6+1 ; copy the byte from the table to HSTART6
MOVE.b    (A0),MIOSPRITE7+1 ; copy the byte from the table to HSTART7
rts

TABXPOINT3:
dc.l    TABX+170    ; NOTE: the values in the table are bytes

; ********************* VERTICAL MOVEMENT ROUTINES *******************

; These routines move the sprite up and down by acting on its bytes
; VSTART and VSTOP, i.e. the bytes of its start and end Y position,
; entering coordinates already established in the TABY table

; For sprite0 ATTACCHED: (i.e. Sprite0+Sprite1)

MoveSpriteY0:
ADDQ.L    #1,TABYPOINT0     ; Point to the next byte
MOVE.L	TABYPOINT0(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last longword of the TAB?
BNE.S	NOBSTARTY0    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT0 ; Start pointing to the first byte (-1) again
NOBSTARTY0:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the byte from the table to d0
MOVE.b    d0,MIOSPRITE0    ; copy the byte to VSTART0
MOVE.b    d0,MIOSPRITE1    ; copy the byte to VSTART1
ADD.B    #15,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,MIOSPRITE0+2	; Move the correct value to VSTOP0
move.b    d0,MIOSPRITE1+2    ; Move the correct value to VSTOP1
rts

TABYPOINT0:
dc.l    TABY-1        ; NOTE: the values in the table are bytes



; For sprite1 ATTACHED: (i.e. Sprite2+Sprite3)

MoveSpriteY1:
ADDQ.L    #1,TABYPOINT1     ; Point to the next byte
MOVE.L    TABYPOINT1(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTARTY1    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT1 ; Start pointing to the first byte (-1) again
NOBSTARTY1:
moveq    #0,d0		; Clear d0
MOVE.b    (A0),d0        ; Copy the byte from the table to d0
MOVE.b    d0,MIOSPRITE2    ; Copy the byte to VSTART2
MOVE.b    d0,MIOSPRITE3    ; Copy the byte to VSTART3
ADD.B	#15,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,MIOSPRITE2+2    ; Move the correct value to VSTOP2
move.b    d0,MIOSPRITE3+2    ; Move the correct value to VSTOP3
rts

TABYPOINT1:
dc.l    TABY+45        ; NOTE: the table values are bytes



; For sprite2 ATTACCHED: (i.e. Sprite4+Sprite5)

MoveSpriteY2:
ADDQ.L    #1,TABYPOINT2	 ; Point to the next byte
MOVE.L    TABYPOINT2(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last longword of TAB?
BNE.S    NOBSTARTY2    ; Not yet? Then continue
MOVE.L	#TABY-1,TABYPOINT2 ; Start pointing to the first byte (-1)
NOBSTARTY2:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the byte from the table to d0
MOVE.b    d0,MIOSPRITE4    ; Copy the byte to VSTART4
MOVE.b    d0,MIOSPRITE5    ; copy the byte to VSTART5
ADD.B    #15,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,MIOSPRITE4+2    ; Move the correct value to VSTOP4
move.b    d0,MIOSPRITE5+2    ; Move the correct value to VSTOP5
rts

TABYPOINT2:
dc.l    TABY+90        ; NOTE: the values in the table are bytes



; For sprite3 ATTACCHED: (i.e. Sprite5+Sprite6)

MoveSpriteY3:
ADDQ.L    #1,TABYPOINT3     ; Point to the next byte
MOVE.L    TABYPOINT3(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTARTY3    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT3 ; Start pointing to the first byte (-1) again
NOBSTARTY3:
moveq    #0,d0        ; Clear d0
MOVE.b	(A0),d0        ; copy the byte from the table to d0
MOVE.b    d0,MIOSPRITE6    ; copy the byte to VSTART6
MOVE.b    d0,MIOSPRITE7    ; copy the byte to VSTART7
ADD.B    #15,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,MIOSPRITE6+2    ; Move the correct value to VSTOP6
move.b    d0,MIOSPRITE7+2    ; Move the correct value to VSTOP7
rts

TABYPOINT3:
dc.l    TABY+140    ; NOTE: the table values are bytes



; Table with precalculated X coordinates of the sprite.

TABX:
incbin    ‘XCOORDINAT.TAB’    ; 334 values
FINETABX:


; Table with precalculated Y coordinates of the sprite.

TABY:
incbin    ‘YCOORDINAT.TAB’    ; 200 values
FINETABY:


SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
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

;    PIC palette

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

;    Palette of attached SPRITES

dc.w    $1A2,$FFC	; colour17, COLOUR 1 for attached sprites
dc.w    $1A4,$EEB    ; colour18, COLOUR 2 for attached sprites
dc.w    $1A6,$CD9    ; colour19, COLOUR 3 for attached sprites
dc.w    $1A8,$AC8	; colour20, COLOUR 4 for attached sprites
dc.w    $1AA,$8B6    ; colour21, COLOUR 5 for attached sprites
dc.w    $1AC,$6A5    ; colour22, COLOUR 6 for attached sprites
dc.w    $1AE,$494	; colour 23, COLOUR 7 for attached sprites
dc.w    $1B0,$384    ; colour 24, COLOUR 7 for attached sprites
dc.w    $1B2,$274    ; colour 25, COLOUR 9 for attached sprites
dc.w	$1B4,$164    ; colour26, COLOUR 10 for attached sprites
dc.w	$1B6,$154    ; colour27, COLOUR 11 for attached sprites
dc.w    $1B8,$044    ; colour28, COLOUR 12 for attached sprites
dc.w    $1BA,$033    ; colour29, COLOUR 13 for attached sprites
dc.w	$1BC,$012    ; colour30, COLOUR 14 for attached sprites
dc.w    $1BE,$001    ; colour31, COLOUR 15 for attached sprites

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here are the sprites: OBVIOUSLY in CHIP RAM! **********

MIOSPRITE0:                ; length 15 lines
incbin    ‘Sprite16Col.EVEN’

MIOSPRITE1:                ; length 15 lines
incbin    ‘Sprite16Col.ODD’

MIOSPRITE2:                ; length 15 lines
incbin    ‘Sprite16Col.EVEN’

MIOSPRITE3:                ; length 15 lines
incbin    ‘Sprite16Col.ODD’

MIOSPRITE4:                ; length 15 lines
incbin    ‘Sprite16Col.EVEN’

MIOSPRITE5:                ; length 15 lines
incbin    ‘Sprite16Col.ODD’

MIOSPRITE6:                ; length 15 lines
incbin    ‘Sprite16Col.EVEN’

MIOSPRITE7:                ; length 15 lines
incbin	‘Sprite16Col.ODD’


SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

This listing shows all 4 sprites ATTACHED in 16 colours.
The sprites have been saved (including the control words) in files,
using the ‘WB’ command. This is to save space in the listing and to
reuse the attached sprite in other listings and several times in the same
listing. In fact, the same sprite (divided into EVEN and ODD SPRITES) is
used for all four sprites.
As for the movement of the sprites, each one has an
, with a pointer to the X and Y tables.
In this way, by starting the movement from different phases (i.e. different points
in the table) in each sprite, the most varied movements are generated.
However, the two tables X and Y are the same for all routines; between one
routine and another, only the starting position of the pointer changes, so
while one sprite starts from position X,Y, another starts from position
X+n, Y+n, creating sprites further ahead and further behind in the curve (IN THE CASE
OF THE ‘SINGLE FILE’), or seemingly random trajectories.
A special feature of the structure of the routines in this listing is worth noting
: since we have to wait for the left and right keys to be pressed several times
to change the movement of the sprites before exiting, it would have been
necessary to rewrite the two loops that wait for the $FF line of the
electronic pen and all 8 ‘BSR move sprite’ commands each time:

; wait for line $FF
; bsr move sprite
; wait for left mouse

; change the trajectory of the sprites

; wait for line $FF
; bsr move sprite
; wait for right mouse button

; change the trajectory of the sprites

; wait for line $FF
; bsr move sprite
; wait for left mouse button

; change the trajectory of the sprites

; wait for line $FF
; bsr move sprite
; wait for right mouse button

To save lines of listing, one solution is to include the
loop that waits for the electronic brush for timing in the
BSR muovisprite subroutine:

; This routine executes the individual sprite movement routines
; and also includes the frame wait loop for timing.

MoveSprites:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    MoveSprites

bsr.s	MoveSpriteX0    ; Move sprite 0 horizontally
bsr.w    MoveSpriteX1    ; Move sprite 1 horizontally
bsr.w    MoveSpriteX2    ; Move sprite 2 horizontally
bsr.w    MoveSpriteX3    ; Move sprite 3 horizontally
bsr.w	MoveSpriteY0    ; Move sprite 0 vertically
bsr.w    MoveSpriteY1    ; Move sprite 1 vertically
bsr.w    MoveSpriteY2    ; Move sprite 2 vertically
bsr.w    MoveSpriteY3    ; Move sprite 3 vertically

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

rts        ; Return to the MOUSE loop

This way, you just have to wait for the mouse button to be pressed. If it is not
pressed, execute MoveSprite:


Mouse1:
bsr.w	MoveSprites    ; Wait for a frame, move the sprites and
; return.

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse1

MOVE.L    #TABX+170,TABXPOINT0    ; Change the trajectory of the sprites
...

Mouse2:
bsr.w    MoveSprites    ; Waits for a frame, moves the sprites and
; returns.

btst    #2,$dff016    ; Right mouse button pressed?
bne.s    mouse2

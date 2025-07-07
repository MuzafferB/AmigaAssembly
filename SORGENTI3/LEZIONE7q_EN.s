
; Lesson 7q.s    A SPRITE MOVED WITH THE JOYSTICK


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

btst    #7,$bfe001    ; FIRE button pressed?
bne.s    NonFuoco    ; if not, skip the following instruction
move.w    #$f00,$dff180    ; if yes, set COLOR0 to RED
NonFuoco:

bsr.s    LeggiJoyst    ; this reads the joystick
move.w    sprite_y(pc),d0 ; prepare the parameters for the routine
move.w    sprite_x(pc),d1 ; universal
lea    miosprite,a1    ; sprite address
moveq    #13,d2        ; sprite height
bsr.w    UniMuoviSprite    ; call the universal routine

Wait:
cmpi.b	#$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088		; start the old cop

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

; This routine reads the joystick and updates the values contained in the
; variables sprite_x and sprite_y

LeggiJoyst:
MOVE.w    $dff00c,D3    ; JOY1DAT
BTST.l    #1,D3        ; bit 1 tells us if we are going right
BEQ.S    NODESTRA    ; if it is zero, we do not go right
ADDQ.w    #1,SPRITE_X    ; if it is 1, move the sprite one pixel
BRA.S    CHECK_Y        ; go to Y control
NODESTRA:
BTST.l    #9,D3        ; bit 9 tells us whether to go left
BEQ.S    CHECK_Y        ; if it is zero, do not go left
SUBQ.W    #1,SPRITE_X    ; if it is 1, move the sprite
CHECK_Y:
MOVE.w    D3,D2        ; copy the value of the register
LSR.w    #1,D2        ; shift the bits one place to the right
EOR.w    D2,D3        ; perform the exclusive OR. Now we can test
BTST.l    #8,D3        ; test if it goes up
BEQ.S    NOALTO        ; if not, check if it goes down
SUBQ.W    #1,SPRITE_Y    ; if the sprite moves
BRA.S    ENDJOYST
NOALTO:
BTST.l    #0,D3        ; test if it goes down
BEQ.S    ENDJOYST    ; if not, finish
ADDQ.W    #1,SPRITE_Y    ; if the sprite moves
ENDJOYST:
RTS

SPRITE_Y:    dc.w    0    ; the Y of the sprite is stored here
SPRITE_X:    dc.w    0    ; the X of the sprite is stored here



; Universal sprite positioning routine.

;
;    Input parameters for UniMuoviSprite:
;
;    a1 = Sprite address
;    d0 = Vertical position Y of the sprite on the screen (0-255)
;    d1 = Horizontal position X of the sprite on the screen (0-320)
;    d2 = Height of the sprite
;

UniMoveSprite:
; vertical positioning
ADD.W    #$2c,d0        ; add the offset of the start of the screen

; a1 contains the address of the sprite
MOVE.b    d0,(a1)        ; copy the byte to VSTART
btst.l    #8,d0
beq.s    NonVSTARTSET
bset.b    #2,3(a1)    ; Set bit 8 of VSTART (number > $FF)
bra.s    ToVSTOP
NonVSTARTSET:
bclr.b    #2,3(a1)    ; Clear bit 8 of VSTART (number < $FF)
ToVSTOP:
ADD.w    D2,D0        ; Add the sprite height to
; determine the final position (VSTOP)
move.b    d0,2(a1)    ; Move the correct value to VSTOP
btst.l    #8,d0
beq.s    NonVSTOPSET
bset.b    #1,3(a1)    ; Set bit 8 of VSTOP (number > $FF)
bra.w    VstopFIN
NonVSTOPSET:
bclr.b    #1,3(a1)    ; Reset bit 8 of VSTOP (number < $FF)
VstopFIN:

; horizontal positioning
add.w    #128,D1		; 128 - to centre the sprite.
btst    #0,D1        ; low bit of the X coordinate reset?
beq.s    BitBassoZERO
bset    #0,3(a1)    ; Set the low bit of HSTART
bra.s    PlaceCoords

BitBassoZERO:
bclr    #0,3(a1)    ; Reset the low bit of HSTART
PlaceCoords:
lsr.w    #1,D1        ; SHIFT, i.e. move 1 bit to the right
; the value of HSTART, to ‘transform’ it into
; the value to be placed in the HSTART byte, without
; the low bit.
move.b    D1,1(a1)    ; We place the value XX in the HSTART byte
rts



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

dc.w $1A2,$F00; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w $1A4,$0F0; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w $1A6,$FF0; colour19, i.e. COLOUR3 of sprite0 - YELLOW

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE:        ; length 13 lines
VSTART:
dc.b $50    ; Vertical position of sprite start (from $2c to $f2)
HSTART:
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP:
dc.b $5d    ; $50+13=$5d    ; vertical position of sprite end
VHBITS:
dc.b $00    ; bit

dc.w    %0000000000000000,%0000110000110000 ; Binary format for modifications
dc.w    %0000000000000000,%0000011001100000
dc.w    %0000000000000000,%0000001001000000
dc.w    %0000000110000000,%0011000110001100 ;BINARY 00=COLOUR 0 (TRANSPARENT)
dc.w    %0000011111100000,%0110011111100110 ;BINARY 10=COLOUR 1 (RED)
dc.w    %0000011111100000,%1100100110010011 ;BINARY 01=COLOUR 2 (GREEN)
dc.w    %0000110110110000,%1111100110011111 ;BINARIO 11=COLORE 3 (GIALLO)
dc.w	%0000011111100000,%0000011111100000
dc.w	%0000011111100000,%0001111001111000
dc.w	%0000001111000000,%0011101111011100
dc.w	%0000000110000000,%0011000110001100
dc.w	%0000000000000000,%1111000000001111
dc.w	%0000000000000000,%1111000000001111
dc.w	0,0    ; 2 words reset define the end of the sprite.


SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

In this example, we move a sprite with the joystick.
The easiest thing is to detect whether the FIRE button is pressed, in fact, all you need is
a BTST #7,$bfe001, similar to the left mouse button, which is bit 6.
To position the sprite on the screen, we use our universal routine,
which we already have ready, saving us a bit of work.
The Leggijoyst routine, on the other hand, detects the status of the joystick and
consequently updates the coordinates of the sprite, which are stored
in two memory locations: SPRITE_X and SPRITE_Y. To read the joystick
, we need to use the EOR instruction which, as we saw in the lesson,
 performs an EXCLUSIVE OR operation between the bits of two registers.
In fact, the joystick is read via the JOY1DAT register. To find out
whether the joystick lever has been pressed to the right or left, you just need to know
the status of bits 1 and 9. For the other directions, it is a little more complicated.
In fact, to find out whether the joystick lever has been pushed upwards, you need to
calculate the EXCLUSIVE OR between bit 8 and bit 9 of the JOY1DAT register.
Since these two bits are located on the same register, first copy the
register to two data registers of the 68000, for example D2 and D3. Then SHIFT
(i.e. move) the bits of one of the two data registers to the right.
In this way, bit 9 of the data register is moved to position 8.
Since the register we SHIFTED contained a copy of JOY1DAT,
after the SHIFT, bit 8 of the data register will be equal to bit 9 of JOY1DAT.
In the non-SHIFTED register, however, bit 8 is equal to bit 8 of JOY1DAT.
Now, by performing the EOR between the two registers, in position 8 there will be the EOR
between bit 8 of the JOY1DAT register and bit 9 of the JOY1DAT register. This is exactly
what we needed to know if we have to move the sprite upwards.
As for the down direction, we must calculate the EXCLUSIVE OR between bits 0 and 1
in the same way as for the up direction.

You can try varying the speed of the sprite. In the LeggiJoyst routine,
 when it is detected that the lever has been moved in a certain direction,
 the sprite is moved by 1 pixel with an ADDQ #1,xxx
(or with a SUBQ #1,xxx) . If you enter values greater than 1 instead of 1, the sprite
will move faster.
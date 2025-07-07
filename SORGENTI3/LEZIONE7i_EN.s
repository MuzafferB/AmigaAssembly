
; Lesson 7i.s    HORIZONTAL SCROLLING OF A SPRITE IN 1-PIXEL STEPS
;        RATHER THAN 2 PIXELS AT A TIME. THIS WAY, THE SCROLL
;        NO LONGER IS JERKY.


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

;    Point to the sprite

MOVE.L    #MIOSPRITE,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
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

bsr.s    MoveSpriteX    ; Move sprite 0 horizontally (SMOOTH)
bsr.w    MoveSpriteY    ; Move sprite 0 vertically

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

; This routine moves the sprite by acting on its HSTART byte and on bit 0 of the
; fourth control byte, i.e. on the low bit of the HSTART value. In this
; way, horizontal scrolling proceeds in 1-pixel increments instead of 2,
; thus doubling the fluidity of horizontal movement and eliminating the jerkiness
; seen in the previous examples. The part of the routine that ‘transforms’
; the value of the real coordinate into byte hstart+low bit can be used
; in all listings that move sprites, among other things with an add.w #128,d0 there is
; already the addition of the offset from the beginning of the video, so the value to be given
; to the input routine is the real X coordinate of the LOWRES screen, for
; if we put 0, the sprite is positioned on the left side of the screen, if
; we put 160, it is positioned in the centre, with 320 it is positioned on the last pixel
; on the right of the screen.

MoveSpriteX:
ADDQ.L    #2,TABXPOINT     ; Point to the next word
MOVE.L    TABXPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last word of TAB?
BNE.S    NOBSTARTX    ; not yet? then continue
MOVE.L    #TABX-2,TABXPOINT ; Start pointing to the first word again-2
NOBSTARTX:
moveq    #0,d0        ; reset d0
MOVE.w    (A0),d0        ; place the table value in d0
add.w    #128,D0        ; 128 - to centre the sprite.
btst    #0,D0		; low bit of the X coordinate reset?
beq.s    BitBassoZERO
bset    #0,MIOSPRITE+3    ; Set the low bit of HSTART
bra.s    PlaceCoords

BitBassoZERO:
bclr    #0,MIOSPRITE+3    ; Reset the low bit of HSTART
PlaceCoords:
lsr.w    #1,D0        ; SHIFT, i.e. move the value of HSTART 1 bit to the right
; to ‘transform’ it into
; the value to be placed in the HSTART byte, i.e. without
; the low bit.
move.b    D0,HSTART    ; Place the value XX in the HSTART byte
rts

TABXPOINT:
dc.l    TABX-2        ; NOTE: the values in the table here are words,

; Table with precalculated X coordinates of the sprite. This table contains
; the ACTUAL values of the screen coordinates, not the values ‘halved’ for
; the two-pixel jerky scrolling we have seen so far.
; Since the possible values are greater than 256, the size of a byte is exceeded,
; so the table is composed of WORDS, which can contain such
; values. The ‘MoveSpriteX’ routine is responsible for retrieving the WORD from the
table and dividing the number into LOWER BITS for scrolling 1 pixel
instead of 2, and into the other 8 bits, which handle the ‘2-pixel jumps’,
i.e. the HSTART byte that we have used alone until now.
; Note that the X position for the sprite to enter the video window
; must be between 0 and 320, i.e. the actual position within
; the screen, the offset from the start of the video of 128 (i.e. $40*2) is
; added by the routine.
; It should also be remembered that the sprite is 16 pixels wide and that the
; X coordinate refers to its left corner, so if we give coordinates
; greater than 320-16, i.e. greater than 304, the sprite will be partially
; outside the screen.
; In fact, the table contains bytes no larger than 304 and no
smaller than zero.


; Here's how to get the table:

;             ___304
; DEST> tabx     / \ 152 (304/2)
; BEG> 0         \___/ 0
; END> 360
; AMOUNT> 150
; AMPLITUDE> 304/2 ; amplitude is both above and below zero, so
; we need to make half above zero and half below,
; i.e. we divide the AMPLITUDE by 2
; YOFFSET> 304/2    ; and move everything up to transform -152 into 0
; SIZE (B/W/L)> w
; MULTIPLIER> 1

TABX:
incbin    ‘xcoordinatok.tab’    ; 150 values .W
FINETABX:

; This routine moves the sprite up and down by acting on its bytes
; VSTART and VSTOP, i.e. the bytes of its start and end Y position,
; entering the coordinates already established in the TABY table

MuoviSpriteY:
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L	TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTARTY    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT ; Start pointing to the first byte (-1) again
NOBSTARTY:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the byte from the table to d0
MOVE.b    d0,VSTART    ; Copy the byte to VSTART
ADD.B    #13,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,VSTOP    ; Move the correct value to VSTOP
rts

TABYPOINT:
dc.l    TABY-1        ; NOTE: the values in the table here are bytes,
; so we work with an ADDQ.L #1,TABYPOINT
; and not #2 as when they are words or with #4
; as when they are longwords.

; Table with precalculated Y coordinates of the sprite.
; Note that the Y position for the sprite to enter the video window
; must be between $2c and $f2, in fact in the table there are bytes no
; larger than $f2 and no smaller than $2c.

TABY:
dc.b	$8E,$91,$94,$97,$9A,$9D,$A0,$A3,$A6,$A9,$AC,$AF ; ondeggio
dc.b	$B2,$B4,$B7,$BA,$BD,$BF,$C2,$C5,$C7,$CA,$CC,$CE ; 200 values
dc.b    $D1,$D3,$D5,$D7,$D9,$DB,$DD,$DF,$E0,$E2,$E3,$E5
dc.b    $E6,$E7,$E9,$EA,$EB,$EC,$EC,$ED,$EE,$EE,$EF,$EF
dc.b    $EF,$EF,$F0,$EF,$EF,$EF,$EF,$EE,$EE,$ED,$EC,$EC
dc.b    $EB,$EA,$E9,$E7,$E6,$E5,$E3,$E2,$E0,$DF,$DD,$DB
dc.b    $D9,$D7,$D5,$D3,$D1,$CE,$CC,$CA,$C7,$C5,$C2,$BF
dc.b    $BD,$BA,$B7,$B4,$B2,$AF,$AC,$A9,$A6,$A3,$A0,$9D
dc.b	$9A,$97,$94,$91,$8E,$8B,$88,$85,$82,$7F,$7C,$79
dc.b	$76,$73,$70,$6D,$6A,$68,$65,$62,$5F,$5D,$5A,$57
dc.b	$55,$52,$50,$4E,$4B,$49,$47,$45,$43,$41,$3F,$3D
dc.b	$3C,$3A,$39,$37,$36,$35,$33,$32,$31,$30,$30,$2F
dc.b	$2E,$2E,$2D,$2D,$2D,$2D,$2C,$2D,$2D,$2D,$2D,$2E
dc.b	$2E,$2F,$30,$30,$31,$32,$33,$35,$36,$37,$39,$3A
dc.b	$3C,$3D,$3F,$41,$43,$45,$47,$49,$4B,$4E,$50,$52
dc.b	$55,$57,$5A,$5D,$5F,$62,$65,$68,$6A,$6D,$70,$73
dc.b    $76,$79,$7C,$7F,$82,$85,$88,$8b
FINETABY:


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
dc.w    $100,%0001001000000000    ; bit 12 on!! 1 lowres bitplane

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$F00    ; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w    $1A4,$0F0    ; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w    $1A6,$FF0    ; colour19, i.e. COLOUR3 of sprite0 - YELLOW

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here is the sprite: OBVIOUSLY it must be in CHIP RAM! ************

MIOSPRITE:        ; length 13 lines
VSTART:
dc.b $50    ; Vertical position of sprite start (from $2c to $f2)
HSTART:
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP:
dc.b $5d    ; $50+13=$5d    ; vertical position of sprite end
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


SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

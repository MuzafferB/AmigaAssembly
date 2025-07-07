
; Lesson 7z.s    ANIMATION (6 FRAMES) OF AN ATTACHED SPRITE


SECTION    CiriCop,CODE

Start:
move.l    4.w,a6		; Execbase
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

;    Point to sprites 0 and 1, which when ATTACHED will form a single sprite
;    with 16 colours. Sprite 1, the odd one, must have bit 7 of the
;    second word set to 1.

MOVE.L    FRAMETAB(PC),d0        ; address of the sprite in d0
LEA	SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #$44,d0        ; the odd sprite is 44 bytes later!
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

; P.S: no need to set bit 7, it is already set in the sprite in this case

move.l	#COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    Animation
bsr.w    MoveSprites    ; Move sprites

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

; This routine animates the sprites, moving the frame addresses
; so that each time the first one in the table goes to the last place,
; while the others all move one place towards the first one

Animation:
addq.b    #1,ContaAnim ; these three instructions ensure that the
cmp.b    #2,ContaAnim ; frame is changed once
bne.s    NonCambiare ; yes and no.
clr.b    ContaAnim
LEA    FRAMETAB(PC),a0 ; frame table
MOVE.L    (a0),d0        ; saves the first address in d0
MOVE.L    4(a0),(a0)    ; moves the other 5 addresses backwards
MOVE.L    4*2(a0),4(a0)    ; These instructions ‘rotate’ the addresses
MOVE.L    4*3(a0),4*2(a0) ; of the table.
MOVE.L    4*4(a0),4*3(a0)
MOVE.L    4*5(a0),4*4(a0)
MOVE.L    d0,4*5(a0)	; put the former first address in sixth place

MOVE.L    FRAMETAB(PC),d0        ; address of the sprite in d0
LEA    SpritePointers,a1    ; Even sprite pointer
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #$44,d0        ; the odd sprite is 44 bytes after the even one
addq.w    #8,a1        ; POINTER of the odd sprite
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
Do not change:
rts

CountAnim:
dc.w    0

; This is the address table for the even sprite frames,
; which also provides access to the corresponding odd sprites to be attached. The addresses
; in the table are ‘rotated’ within the table by the
Animation routine, so that the first in the list is the first time
frame1, the next time Frame2, then 3,4,5,6 and again the
; first, cyclically. In this way, you just need to take the address at the
; beginning of the table each time after the ‘shuffle’ to get the
; addresses of the frames in sequence.

FRAMETAB:
DC.L    Frame1
DC.L    Frame2
DC.L    Frame3
DC.L    Frame4
DC.L    Frame5
DC.L    Frame6


; This routine reads the actual coordinates of the sprites from the two tables.
; Since the sprites are attached, they both have the same coordinates.

MoveSprites:
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L    TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S	NOBSTARTY    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT ; Start pointing to the first byte again
NOBSTARTY:
moveq    #0,d3        ; Clear d3
MOVE.b    (A0),d3        ; Copy the table byte, i.e. the
; Y coordinate in d3

ADDQ.L    #2,TABXPOINT     ; Point to the next word
MOVE.L    TABXPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last word of the TAB?
BNE.S    NOBSTARTX    ; Not yet? Then continue
MOVE.L    #TABX-2,TABXPOINT ; Start pointing again from the first word-2
NOBSTARTX:
moveq    #0,d4        ; reset d4
MOVE.w    (A0),d4        ; set the table value, i.e.
; the X coordinate in d4

MOVE D3,D0 ; Y coordinate in d0
MOVE D4,D1 ; X coordinate in d1
moveq    #15,d2        ; height of the sprite in d2
MOVE.L    FRAMETAB(PC),a1	; sprite address in A1

bsr.w    UniMuoviSprite ; executes the universal routine that positions
; the even sprite

MOVE.W    D3,D0        ; Y coordinate in d0
MOVE.W    D4,D1        ; X coordinate in d1
moveq    #15,d2		; height of the sprite in d2
LEA    $44(a1),a1    ; address of the odd sprite in A1
; the odd sprite is $44 bytes after the
; even one
bsr.w    UniMuoviSprite ; executes the universal routine that positions
; the odd sprite
rts


TABYPOINT:
dc.l	TABY-1        ; NOTE: the values in the table here are bytes,
; so we work with an ADDQ.L #1,TABYPOINT
; and not #2 as when they are words or with #4
; as when they are longwords.
TABXPOINT:
dc.l    TABX-2        ; NOTE: the values in the table here are words,

; Table with precalculated Y coordinates of the sprite.

TABY:
incbin    ‘ycoordinatok.tab’    ; 200 values .B
FINETABY:

; Table with precalculated X coordinates of the sprite.

TABX:
incbin    ‘xcoordinatok.tab’    ; 150 values .W
FINETABX:



; Universal routine for positioning sprites.

;
;    Input parameters for UniMuoviSprite:
;
;    a1 = Address of the sprite
;    d0 = Vertical position Y of the sprite on the screen (0-255)
;    d1 = horizontal position X of the sprite on the screen (0-320)
;    d2 = height of the sprite
;

UniMuoviSprite:
; vertical positioning
ADD.W    #$2c,d0        ; add the offset of the start of the screen

; a1 contains the address of the sprite
MOVE.b    d0,(a1)        ; copy the byte to VSTART
btst.l    #8,d0
beq.s    NonVSTARTSET
bset.b    #2,3(a1)    ; Set bit 8 of VSTART (number > $FF)
bra.s    ToVSTOP
NonVSTARTSET:
bclr.b    #2,3(a1)    ; Reset bit 8 of VSTART (number < $FF)
ToVSTOP:
ADD.w    D2,D0        ; Add the height of the sprite to
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
add.w    #128,D1        ; 128 - to centre the sprite.
btst    #0,D1        ; low bit of the X coordinate reset?
beq.s	BitLowZERO
bset    #0,3(a1)    ; Set the low bit of HSTART
bra.s    PlaceCoords

BitLowZERO:
bclr    #0,3(a1)    ; Reset the low bit of HSTART
PlaceCoords:
lsr.w    #1,D1        ; SHIFT, i.e. move 1 bit to the right
; the value of HSTART, to ‘transform’ it into
; the value to be placed in the HSTART byte, without
; the low bit.
move.b    D1,1(a1)    ; Set the value XX in the HSTART byte
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
dc.w    $94,$d0		; DdfStop
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

;	Palette of attached SPRITES

dc.w    $1A2,$FFC    ; colour 17, COL 1 for sprite att.
dc.w    $1A4,$DEA    ; colour 18, COL 2 for sprite att.
dc.w    $1A6,$AC7    ; colour 19, COL 3 for sprite att.
dc.w    $1A8,$7B6    ; colour 20, COL 4 for attached sprite
dc.w    $1AA,$494    ; colour21, COL 5 for sprite att.
dc.w    $1AC,$284    ; colour22, COL 6 for sprite att.
dc.w    $1AE,$164    ; colour23, COL 7 for sprite att.
dc.w    $1B0,$044	
; colour 24, COL 7 for sprite att.
dc.w    $1B2,$023    ; colour 25, COL 9 for sprite att.
dc.w    $1B4,$001    ; colour 26, COL 10 for sprite att.
dc.w    $1B6,$F80    ; colour27, COL 11 for sprite att.
dc.w    $1B8,$C40    ; colour28, COL 12 for sprite att.
dc.w	$1BA,$820    ; colour29, COL 13 for sprite att.
dc.w    $1BC,$500    ; colour30, COL 14 for sprite att.
dc.w    $1BE,$200    ; colour31, COL 15 for sprite att.

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here are the sprites: OBVIOUSLY in CHIP RAM! **********


Frame 1:        ; length 15 lines, $44 bytes
dc.w $0000,$0000
dc.w $0580,$0040,$07c0,$0430,$0d68,$0d18,$1fac,$1b9c
dc.w $3428,$3818,$068e,$993c,$d554,$1390,$729e,$b6d8
dc.w $5556,$9390,$96b0,$e972,$406c,$7c60,$5bc4,$5fc8
dc.w $0970,$0908,$0bc0,$0030,$0600,$01c0
dc.w 0,0
Frame 1b:        ; length 15 lines
dc.w $0000,$0080
dc.w $07c0,$0000,$1bf0,$0380,$32f8,$0380,$607c,$0380
dc.w $43f8,$0384,$e3fc,$0382,$efec,$7ffe,$cfe4,$7ffe
dc.w $efec,$7ffe,$fff0,$038e,$7fe0,$039c,$5c40,$23bc
dc.w $0a80,$37f8,$0380,$1ff0,$0000,$07c0
dc.w 0,0

Fotogramma2:
dc.w $0000,$0000
dc.w $0580,$0040,$05c0,$0430,$0ee8,$0e98,$1dac,$1b9c
dc.w $34e8,$3ad8,$560e,$993c,$f5e8,$3318,$d252,$1690
dc.w $3a96,$c7d0,$95b8,$ea32,$41ec,$78e0,$5e44,$5e48
dc.w $0470,$0408,$0ec0,$0030,$0600,$01c0
dc.w 0,0
Frame 2b:
dc.w $0000,$0080
dc.w $07c0,$0000,$1bf0,$0180,$3178,$01c0,$607c,$01c0
dc.w $4138,$01c4,$e3fc,$7382,$cff8,$7f86,$efe0,$fffe
dc.w $ffec,$0ffe,$ffc8,$07fe,$7ff8,$071c,$5940,$27bc
dc.w $0a00,$3ff8,$0e00,$1ff0,$0000,$07c0
dc.w 0,0

Fotogramma3:
dc.w $0000,$0000
dc.w $0580,$0040,$04c0,$0430,$0e68,$0e18,$3dfc,$1bec
dc.w $25c8,$0bd8,$7b2e,$ba3c,$d068,$1798,$6642,$82b0
dc.w $32d6,$c690,$9490,$eb12,$49bc,$78b0,$4d6c,$4d60
dc.w $1870,$0808,$0ec0,$0030,$0600,$01c0
dc.w 0,0
Fotogramma3b:
dc.w $0000,$0080
dc.w $07c0,$0000,$1bf0,$0000,$31f8,$0060,$601c,$20f0
dc.w $7038,$30e4,$c5dc,$7de2,$eff8,$3fc6,$fff0,$0fce
dc.w $fff0,$07ee,$ffe8,$07fe,$77c8,$0f7c,$5358,$3ebc
dc.w $1400,$3ff8,$0c00,$1ff0,$0000,$07c0
dc.w 0,0

Fotogramma4:
dc.w $0000,$0000
dc.w $0580,$0040,$04c0,$0430,$1678,$0608,$357c,$1764
dc.w $0968,$0968,$122e,$91bc,$c7e8,$0398,$6242,$86b0
dc.w $3256,$c790,$93b0,$f032,$786c,$5b60,$7354,$4748
dc.w $1870,$0808,$0ac0,$0030,$0600,$01c0
dc.w 0,0
Fotogramma4b:
dc.w $0000,$0080
dc.w $07c0,$0000,$1bf0,$0000,$39f8,$1830,$689c,$3c78
dc.w $7698,$3ef4,$efdc,$1fe2,$fff8,$0fc6,$fff0,$07ce
dc.w $fff0,$0fee,$efc0,$1ffe,$6798,$3cfc,$7f30,$38fc
dc.w $1820,$37f8,$0000,$1ff0,$0000,$07c0
dc.w 0,0

Fotogramma5:
dc.w $0000,$0000
dc.w $0580,$0040,$04c0,$0030,$0e68,$0218,$172c,$1714
dc.w $3ca8,$3ca0,$0116,$9810,$cf10,$09d0,$64e2,$8290
dc.w $30d6,$d7b0,$8a50,$c992,$782c,$5b20,$7be4,$4fe8
dc.w $0830,$0808,$0ae0,$0010,$0600,$01c0
dc.w 0,0
Frame 5b:
dc.w $0000,$0080
dc.w $07c0,$0000,$1ff0,$0400,$3df8,$0c00,$68fc,$0e08
dc.w $4358,$0f3c,$e7ec,$077e,$f7e8,$07fe,$fff0,$07ee
dc.w $eff0,$1fce,$f7f0,$3fee,$67c0,$3cfc,$7f10,$30fc
dc.w $0870,$37f8,$0060,$1ff0,$0000,$07c0
dc.w 0,0

Fotogramma6:
dc.w $0000,$0000
dc.w $0580,$0040,$07c0,$0430,$0e68,$0a18,$1b2c,$1b1c
dc.w $3428,$3c18,$0696,$9910,$cf5c,$0d98,$7492,$92d0
dc.w $50b6,$97d0,$ab70,$c8b2,$602c,$5e20,$5bc4,$5fc8
dc.w $0850,$0848,$0ae0,$0010,$0600,$01c0
dc.w 0,0
Frame 6b:
dc.w $0000,$0080
dc.w $07c0,$0000,$1bf0,$0300,$35f8,$0700,$64fc,$0700
dc.w $43f8,$0784,$e3ec,$03be,$f3e4,$03fe,$efee,$1ffe
dc.w $eff0,$7fee,$f7f0,$3fce,$7fe0,$21dc,$5e00,$21fc
dc.w $08a0,$37f8,$00e0,$1ff0,$0000,$07c0
dc.w 0,0


SECTION    PLANEVUOTO,BSS_C    ; The zeroed bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; zeroed bitplane lowres

end

In this example, we show how to create an animated sprite, following the
technique explained in the lesson.
The figure we are animating is made up of a pair of ‘attached’ sprites.
In practice, therefore, there are two sprites that we are animating.
For each sprite, we have six frames. For now, let's consider only the first
sprite. Each frame is stored in a sprite structure.
Each time the sprite is redrawn, the ‘animation’ routine
uses a different frame, i.e. a different sprite structure.
The routine manages a table with the addresses of the various
sprite structures, and each time it is executed, it moves the addresses
within the table so that they all rotate and end up
at the beginning of the table.
In practice, there is nothing new, because we are dealing with a table
of addresses instead of a table of values. Furthermore, the 6 addresses are
‘rotated’ within the table itself, i.e. for each frame, the first
address is placed in the place of the last, the second in the place of the first, the
third in place of the second, and so on, in a similar way to the rotation
we have already seen for colours in copperlist in Lesson 3e.s.
The address at the top of the table is loaded into the sprite pointer
and used as the frame for the sprite.
To avoid repeating this work for the second sprite (the
odd one to be attached to the first), each frame of each ‘second sprite’ is
placed in memory immediately after the corresponding frame of the first sprite,
so that from the address of the frame of the first sprite (even) we can
trace back to the address of the corresponding second sprite (odd) to be attached
to the first simply with:

lea $44(a0),a1

This adds the length of the frame to the address of the first sprite's frame,
 obtaining the address of the second frame (odd).

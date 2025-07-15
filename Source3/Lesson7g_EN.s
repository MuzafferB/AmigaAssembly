
; Lesson 7g.s    A 16-COLOUR SPRITE IN ATTACHED MODE MOVING ON THE SCREEN
;         USING TWO PRE-SET VALUE TABLES (i.e. vertical
;        and horizontal coordinates).


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

;    Point to sprites 0 and 1, which when ATTACHED will form a single sprite
;    with 16 colours. Sprite 1, the odd one, must have bit 7 of the
;    second word set to 1.

MOVE.L	#MIOSPRITE0,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE1,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

bset    #7,MIOSPRITE1+3		; Set the attached bit to
; sprite 1. By removing this instruction
; the sprites are not ATTACHED, but
; two 3-colour sprites are superimposed.

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088		; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    MoveSpriteX    ; Move sprite 0 horizontally
bsr.w    MoveSpriteY    ; Move sprite 0 vertically

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

; This routine moves the sprite by acting on its HSTART byte, i.e.
; the byte of its X position, entering coordinates already established
; in the TABX table. (2 pixel increments at a time)

MoveSpriteX:
ADDQ.L	#1,TABXPOINT     ; Point to the next byte
MOVE.L    TABXPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-1,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTARTX    ; Not yet? Then continue
MOVE.L    #TABX-1,TABXPOINT ; Start pointing to the first byte-1 again
NOBSTARTX:
MOVE.b    (A0),MIOSPRITE0+1 ; copy the byte from the table to HSTART0
MOVE.b    (A0),MIOSPRITE1+1 ; copy the byte from the table to HSTART1
rts

TABXPOINT:
dc.l    TABX-1        ; NOTE: the values in the table are bytes

; Table with precalculated X coordinates of the sprite.

TABX:
incbin    ‘XCOORDINAT.TAB’    ; 334 values
FINETABX:


; This routine moves the sprite up and down by acting on its bytes
; VSTART and VSTOP, i.e. the bytes of its start and end Y position,
; entering the coordinates already established in the TABY table

MoveSpriteY:
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L    TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last longword of TAB?
BNE.S    NOBSTARTY    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT ; Start pointing to the first byte (-1) again
NOBSTARTY:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the byte from the table to d0
MOVE.b	d0,MIOSPRITE0    ; copy the byte to VSTART0
MOVE.b    d0,MIOSPRITE1    ; copy the byte to VSTART1
ADD.B    #15,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,MIOSPRITE0+2    ; Move the correct value to VSTOP0
move.b    d0,MIOSPRITE1+2    ; Move the correct value to VSTOP1
rts

TABYPOINT:
dc.l    TABY-1        ; NOTE: the table values are bytes

; Table with precalculated Y coordinates of the sprite.

TABY:
incbin	‘YCOORDINAT.TAB’    ; 200 values
FINETABY:


SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

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
dc.w $e0,0,$e2,0    ;first bitplane

;    PIC palette

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

;    Attached SPRITE palette

dc.w    $1A2,$FFC    ; colour17, COLOUR 1 for attached sprites
dc.w    $1A4,$EEB    ; colour18, COLOUR 2 for attached sprites
dc.w    $1A6,$CD9    ; colour19, COLOUR 3 for attached sprites
dc.w    $1A8,$AC8	; colour20, COLOUR 4 for attached sprites
dc.w    $1AA,$8B6    ; colour21, COLOUR 5 for attached sprites
dc.w    $1AC,$6A5	; colour22, COLOUR 6 for attached sprites
dc.w    $1AE,$494    ; colour23, COLOUR 7 for attached sprites
dc.w    $1B0,$384    ; colour24, COLOUR 7 for attached sprites
dc.w    $1B2,$274	; color25, COLOUR 9 for attached sprites
dc.w    $1B4,$164    ; color26, COLOUR 10 for attached sprites
dc.w    $1B6,$154    ; color27, COLOUR 11 for attached sprites
dc.w	$1B8,$044    ; colour28, COLOUR 12 for attached sprites
dc.w    $1BA,$033    ; colour29, COLOUR 13 for attached sprites
dc.w    $1BC,$012    ; colour30, COLOUR 14 for attached sprites
dc.w    $1BE,$001	; colour31, COLOUR 15 for attached sprites

dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here are the sprites: OBVIOUSLY in CHIP RAM! **********

MIOSPRITE0:        ; length 15 lines
VSTART0:
dc.b $00    ; Vertical position of sprite start (from $2c to $f2)
HSTART0:
dc.b $00    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP0:
dc.b $00    ; vertical position of sprite end
dc.b $00

dc.w $0380,$0650,$04e8,$07d0,$0534,$1868,$1e5c,$1636 ; dati dello
dc.w $377e,$5514,$43a1,$1595,$0172,$1317,$6858,$5035 ; sprite 0
dc.w $318c,$0c65,$7453,$27c9,$5ece,$5298,$0bfe,$2c32
dc.w $005c,$13c4,$0be8,$0c18,$03e0,$03e0

dc.w	0,0    ; 2 words set to zero define the end of the sprite.



MIOSPRITE1:        ; length 15 lines
VSTART1:
dc.b $00    ; Vertical position of sprite start (from $2c to $f2)
HSTART1:
dc.b $00    ; Horizontal position of sprite start (from $40 to $d8)
VSTOP1:
dc.b $00    ; $50+13=$5d    ; Vertical position of sprite end
dc.b $00    ; Set bit 7 to attach sprites 0 and 1.

dc.w $0430,$07f0,$0fc8,$0838,$0fe4,$101c,$39f2,$200e ; data of the
dc.w $58f2,$600e,$5873,$600f,$5cf1,$600f,$1ff3,$600f ; sprite 1
dc.w $4fe3,$701f,$47c7,$783f,$6286,$7d7e,$300e,$3ffe
dc.w $1c3c,$1ffc,$0ff8,$0ff8,$03e0,$03e0

dc.w	0,0    ; 2 words set to zero define the end of the sprite.


SECTION    PLANEVUOTO,BSS_C    ; The bitplane we use, set to zero,
; because in order to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; bitplane set to zero lowres

end

Apart from the new ATTACCHED bit for making a 16-colour sprite instead of
two 4-colour sprites, there are a couple of things to note:
1) The X and Y tables have been saved with the ‘WB’ command and are loaded
with incbin, so that the tables can be loaded from the various
lists that require them, as long as they are on the disk!
2) The labels VSTART0, VSTART1, HSTART0, HSTART1, etc. are no longer used to
move the sprite. The labels remain in their place in the sprite in this
listing, but it is more convenient to ‘reach’ the control bytes like this:

MIOSPRITE    ; For VSTART
MIOSPRITE+1	; For HSTART
MIOSPRITE+2    ; For VSTOP

This way, you can simply start the sprite with:

MIOSPRITE:
DC.W    0,0
..data...

Without dividing the two words into single bytes, each with a LABEL that lengthens
the listing.
To set bit 7 of word 2 of SPRITE1, that of ATTACCHED,
this instruction was sufficient:

bset    #7,MIOSPRITE1+3

Otherwise, we could have set it ‘manually’ in the fourth byte:

MIOSPRITE1:
VSTART1:
dc.b $00
HSTART1:
dc.b $00
VSTOP1:
dc.b $00
dc.b %10000000        ; or dc.b $80 ($80=%10000000)

If all 8 sprites are to be used, this saves a lot of labels and
space. It would be even better to put the sprite address in an Ax register
and execute the offsets from that register:

lea    MIOSPRITE,a0
MOVE.B    #yy,(a0)    ; For VSTART
MOVE.B    #xx,1(A0)    ; For HSTART
MOVE.B    #y2,2(A0)    ; For VSTOP

Defining a 16-colour sprite in binary becomes problematic.
Therefore, you need to use a drawing program, just remember to
use a 16-colour screen and draw sprites no wider than 16
pixels. Once you have saved the 16-colour PIC (or a smaller BRUSH with the
sprite) in IFF format, converting it with IFFCONVERTER is as easy as
converting a figure.

NOTE: BRUSH refers to a piece of a figure of variable size.

Here's how you can convert a sprite with KEFCON:

1) Load the IFF file, which must be 16 colours
2) You must select only the sprite. To do this, press the right mouse button,
then position the cursor on the upper left corner of the future sprite and press
the left mouse button. Moving the mouse will display a grid that, coincidentally,
is divided into 16-pixel wide strips. You can still check the width
and length of the selected block. To include the sprite correctly,
keep in mind that you must pass through the edge of the sprite with the
rectangle selection “strip”. The last line included in the rectangle is the one that
passes through the border strip, not the one inside the strip:

<----- 16 pixels ----->

|========####========| /\
|| ########     || ||
|| ############ || ||
|| ################ || ||
||##################|| ||
###################### ||
###################### Sprite length, maximum 256 pixels
###################### ||
||##################|| ||
|| ################ || ||
|| ############ || ||
|| ######## || ||
|========####========| \/


If the sprite is smaller than 16 pixels, you must leave a blank margin on
both sides, or on one side only, so that the width of the block is always 16.

Once you have selected the sprite inside the rectangle, save it as
SPRITE16 if it is a 16-colour sprite, or as SPRITE4 if it is a
four-colour sprite. The sprite is saved in ‘dc.b’, i.e. in TEXT format, which
you can include in the listing with the ‘I’ command in Asmone or by loading it into another
text buffer and copying it with Amiga+b+c+i.

Here's how KEFCON saves the attached sprite (16 colours):

dc.w $0000,$0000
dc.w $0380,$0650,$04e8,$07d0,$0534,$1868,$1e5c,$1636
dc.w $377e,$5514,$43a1,$1595,$0172,$1317,$6858,$5035
dc.w $318c,$0c65,$7453,$27c9,$5ece,$5298,$0bfe,$2c32
dc.w $005c,$13c4,$0be8,$0c18,$03e0,$03e0
dc.w 0,0

dc.w $0000,$0000
dc.w $0430,$07f0,$0fc8,$0838,$0fe4,$101c,$39f2,$200e
dc.w $58f2,$600e,$5873,$600f,$5cf1,$600f,$1ff3,$600f
dc.w $4fe3,$701f,$47c7,$783f,$6286,$7d7e,$300e,$3ffe
dc.w $1c3c,$1ffc,$0ff8,$0ff8,$03e0,$03e0
dc.w 0,0

As you can see, these are the two sprites with the two control words
set to zero, the data in hexadecimal format and the two FINE SPRITE words set to zero.
Just put the two labels ‘MIOSPRITE0:’ and ‘MIOSPRITE1:’ at the beginning of the two
sprites, then work with MIOSPRITE+x to reach the bytes of the 
coordinates. No other LABELS need to be added. The only detail is that
you need to set the ATTACCHED bit with a BSET #7,MIOSPRITE+3 or
directly in the sprite:

MIOSPRITE1:
dc.w $0000,$0080    ; $80, i.e. %10000000 -> ATTACHED!
dc.w $0430,$07f0,$0fc8,$0838,$0fe4,$101c,$39f2,$200e
...

If you want to draw and convert 4-colour sprites, there is no problem
because only one sprite is saved and you don't need to set the bit!

As for the sprite colour palette, you need to save them from
KEFCON after saving SPRITE16 or SPRITE4, with the COPPER option, just
like for normal figures. The problem is that the palette is saved
as a 16-COLOUR FIGURE, and not as a SPRITE.
Here's how KEFCON saves the palette:

dc.w $0180,$0000,$0182,$0ffc,$0184,$0eeb,$0186,$0cd9
dc.w $0188,$0ac8,$018a,$08b6,$018c,$06a5,$018e,$0494
dc.w $0190,$0384,$0192,$0274,$0194,$0164,$0196,$0154
dc.w $0198,$0044,$019a,$0033,$019c,$0012,$019e,$0001

The colours are correct, but the colour registers refer to the first 16 colours
and not the last 16. Just rewrite them ‘by hand’ in the correct colour registers:

dc.w    $1A2,$FFC    ; colour17, COLOUR 1 for attached sprites
dc.w	$1A4,$EEB    ; colour18, COLOUR 2 for attached sprites
dc.w    $1A6,$CD9    ; colour19, COLOUR 3 for attached sprites
dc.w    $1A8,$AC8    ; colour20, COLOUR 4 for attached sprites
dc.w	$1AA,$8B6    ; colour21, COLOUR 5 for attached sprites
dc.w    $1AC,$6A5    ; colour22, COLOUR 6 for attached sprites
dc.w    $1AE,$494    ; colour23, COLOUR 7 for attached sprites
dc.w    $1B0,$384	; colour24, COLOUR 7 for attached sprites
dc.w    $1B2,$274    ; colour25, COLOUR 9 for attached sprites
dc.w    $1B4,$164    ; colour26, COLOUR 10 for attached sprites
dc.w    $1B6,$154	; colour27, COLOUR 11 for attached sprites
dc.w    $1B8,$044    ; colour28, COLOUR 12 for attached sprites
dc.w    $1BA,$033    ; colour29, COLOUR 13 for attached sprites
dc.w    $1BC,$012	; color30, COLOUR 14 for attached sprites
dc.w    $1BE,$001    ; color31, COLOUR 15 for attached sprites

Note that in $1a2 you need to copy the colour in $182, in $1a4 the one in $184
and so on.

Try replacing the 16-colour sprite in this listing with one of your own,
with your own colour palette, and also convert one to 4 colours to
replace the one from the previous lessons. This will serve as a test!!!

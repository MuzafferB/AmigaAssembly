
; Lesson 7y3.s    TWO USES OF A SPRITE ON THE SAME LINE

; This example shows how it is possible to reuse a sprite
; twice on the same line by accessing the registers directly


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

;    DO NOT point to the sprite!!!!!!!!!!!!!!!!!!!!

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
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


SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
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
dc.w    $182,$123    ; colour1	; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$FF0    ; colour17, i.e. COLOUR1 of sprite0 - YELLOW
dc.w    $1A4,$a00    ; colour18, i.e. COLOUR2 of sprite0 - RED
dc.w    $1A6,$F70    ; colour19, i.e. COLOUR3 of sprite0 - ORANGE

; ---> insert the piece of copperlist shown at the bottom of the comment here

dc.w    $4007,$fffe    ; wait for line $40, horizontal position 7
dc.w    $140,$0060	; SPR0POS - horizontal position
dc.w    $142,$0000    ; SPR0CTL
dc.w    $146,$0e70    ; SPR0DATB
dc.w    $144,$03c0    ; SPR0DATA - activate the sprite

dc.w    $4087,$fffe    ; wait for line $40, horizontal position 87
dc.w    $140,$00a0    ; SPR0POS - horizontal position

; same for line $41
dc.w    $4107,$fffe    ; wait horizontal position 07
dc.w    $140,$0060    ; spr0pos

dc.w    $4187,$fffe    ; wait horizontal position 87
dc.w    $140,$00a0    ; spr0pos

; same for line $42
dc.w    $4207,$fffe    ; wait
dc.w    $140,$0060    ; spr0pos

dc.w    $4287,$fffe    ; wait... etc.
dc.w    $140,$00a0

; same for line $43
dc.w    $4307,$fffe
dc.w    $140,$0060

dc.w    $4387,$fffe
dc.w    $140,$00a0

; same for line $44
dc.w    $4407,$fffe
dc.w    $140,$0060

dc.w    $4487,$fffe
dc.w    $140,$00a0

; same for line $45
dc.w    $4507,$fffe
dc.w    $140,$0060

dc.w    $4587,$fffe
dc.w    $140,$00a0

; same for line $46
dc.w    $4607,$fffe
dc.w    $140,$0060

dc.w    $4687,$fffe
dc.w    $140,$00a0

; same for line $47
dc.w    $4707,$fffe
dc.w    $140,$0060

dc.w    $4787,$fffe
dc.w    $140,$00a0

; same for line $48
dc.w	$4807,$fffe
dc.w    $140,$0060

dc.w    $4887,$fffe
dc.w    $140,$00a0

; same for line $49
dc.w    $4907,$fffe
dc.w    $140,$0060

dc.w    $4987,$fffe
dc.w    $140,$00a0

; same for line $4a
dc.w    $4a07,$fffe
dc.w    $140,$0060

dc.w    $4a87,$fffe
dc.w    $140,$00a0

; same for line $4b
dc.w    $4b07,$fffe
dc.w    $140,$0060

dc.w    $4b87,$fffe
dc.w    $140,$00a0

; same for line $4c
dc.w    $4c07,$fffe
dc.w    $140,$0060

dc.w    $4c87,$fffe
dc.w    $140,$00a0

; same for line $4d
dc.w    $4d07,$fffe
dc.w    $140,$0060

dc.w    $4d87,$fffe
dc.w    $140,$00a0

; same for line $4e
dc.w    $4e07,$fffe
dc.w    $140,$0060

dc.w    $4e87,$fffe
dc.w    $140,$00a0

; same for line $4f
dc.w    $4f07,$fffe
dc.w    $140,$0060

dc.w    $4f87,$fffe
dc.w    $140,$00a0

dc.w    $5007,$fffe    ; wait for line $50
dc.w    $142,$0000    ; SPR0CTL - ‘turns off’ the sprite

dc.w    $FFFF,$FFFE	; End of copperlist



SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because in order to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

Manipulating the registers directly also makes it possible to draw a sprite
twice on the same line, i.e. draw it in two different
horizontal positions. 
The trick makes use of the copper and its ability to wait
until the electronic brush has reached a certain position on the
video. First, we wait with the copper for the first line of the screen where
we want to draw the sprite. In the example, we wait for line $40 by putting
in the copperlist:

dc.w    $4007,$fffe    ; wait for line $40, horizontal position 7

Then load the SPR0CTL, SPRDATB and SPRDAT registers:

dc.w    $142,$0000    ; SPR0CTL
dc.w    $146,$0e70    ; SPR0DATB
dc.w    $144,$03c0    ; SPR0DATA - activates the sprite

And we put the first value of the horizontal position in SPRxPOS:

dc.w    $140,$0060    ; SPR0POS - horizontal position

At this point, wait for the electronic brush to pass this horizontal position
so that the sprite is drawn.

dc.w    $4087,$fffe    ; wait for line $40, horizontal position 87

In the example, the horizontal position of the sprite is $60. By waiting
for position $87, we can be fairly sure that the sprite has been
drawn. In fact, when the electronic brush has passed the horizontal position,
 the sprite has actually been drawn.

Once this has happened, the second horizontal position is written
to SPRxPOS.

dc.w    $140,$00a0    ; SPR0POS - horizontal position

In this way, the sprite will also be drawn in the second
horizontal position. At this point, we have drawn the same sprite twice
on one line. To draw the two sprites on the following lines,
simply repeat all the steps described above.
For example, for line $41, we write

; the same for line $41
dc.w    $4107,$fffe
dc.w    $140,$0060

dc.w    $4187,$fffe
dc.w    $140,$00a0

which is the same as line $40, except that we keep SPR0DATA
SPR0DATB and SPR0CTL constant in order to keep the shape of the sprite constant.
If desired, these registers can be varied to change the shape of the sprite
between one line and another.

To disable sprites, simply write any value in 
SPL0CTL, like this:

dc.w    $5007,$fffe    ; wait for line $50
dc.w    $142,$0000    ; SPR0CTL - ‘turns off’ the sprite


If you really want to go overboard, you can also change the palette horizontally
between the first bar and the second, so that you can reuse the same
line in different colours. Try inserting this copperlist in the
point indicated with:

; ---> insert the piece of copperlist shown at the bottom of the comment here

In the copperlist of the listing. Basically, we replace the final part that
deals with displaying the sprite. (Amiga+b+c+i to copy the text)


dc.w    $4007,$fffe    ; wait for line $40, horizontal position 7
dc.w    $140,$0060    ; SPR0POS - horizontal position
dc.w    $142,$0000    ; SPR0CTL
dc.w    $146,$0e70    ; SPR0DATB
dc.w    $144,$03c0    ; SPR0DATA - activate the sprite

dc.w    $4087,$fffe    ; wait for line $40, horizontal position 87
dc.w    $1A2,$aFa    ; colour17	; green tone
dc.w    $1A4,$050    ; colour18
dc.w    $1A6,$0a0    ; colour19
dc.w    $140,$00a0    ; SPR0POS - horizontal position

; line $41
dc.w    $4107,$fffe    ; wait horizontal position 07
dc.w    $1A2,$FF0    ; colour17    ; orange tone
dc.w    $1A4,$a00    ; colour18
dc.w    $1A6,$F70    ; colour19
dc.w    $140,$0060    ; spr0pos
dc.w    $4187,$fffe    ; wait horizontal position 87
dc.w    $1A2,$aFa    ; colour17    ; green tone
dc.w	$1A4,$050    ; colour18
dc.w    $1A6,$0a0    ; colour19
dc.w    $140,$00a0    ; spr0pos
; line $42
dc.w    $4207,$fffe    ; wait horizontal position 07
dc.w	$1A2,$FF0    ; colour17    ; orange tone
dc.w    $1A4,$a00    ; colour18
dc.w    $1A6,$F70    ; colour19
dc.w    $140,$0060	; spr0pos
dc.w    $4287,$fffe    ; wait horizontal position 87
dc.w    $1A2,$aFa    ; colour17    ; green tone
dc.w    $1A4,$050    ; colour18
dc.w    $1A6,$0a0    ; colour19
dc.w    $140,$00a0    ; spr0pos
; line $43
dc.w    $4307,$fffe    ; wait horizontal position 07
dc.w    $1A2,$FF0    ; colour17    ; orange tone
dc.w    $1A4,$a00    ; colour18
dc.w    $1A6,$F70    ; colour 19
dc.w    $140,$0060    ; spr0pos
dc.w    $4387,$fffe    ; wait horizontal position 87
dc.w    $1A2,$aFa    ; colour 17    ; green tone
dc.w    $1A4,$050	; colour18
dc.w    $1A6,$0a0    ; colour19
dc.w    $140,$00a0    ; spr0pos
; line $44
dc.w    $4407,$fffe    ; wait horizontal position 07
dc.w    $1A2,$FF0    ; colour17    ; orange tone
dc.w    $1A4,$a00    ; colour18
dc.w    $1A6,$F70    ; colour19
dc.w    $140,$0060    ; spr0pos
dc.w    $4487,$fffe    ; wait horizontal position 87
dc.w    $1A2,$aFa    ; colour17	; green tone
dc.w    $1A4,$050    ; colour18
dc.w    $1A6,$0a0    ; colour19
dc.w    $140,$00a0    ; spr0pos
; line $45
dc.w    $4507,$fffe    ; wait horizontal position 07
dc.w    $1A2,$FF0    ; colour17    ; orange tone
dc.w    $1A4,$a00    ; colour18
dc.w    $1A6,$F70    ; colour19
dc.w    $140,$0060    ; spr0pos
dc.w    $4587,$fffe    ; wait horizontal position 87
dc.w    $1A2,$aFa    ; colour17    ; green tone
dc.w    $1A4,$050    ; colour18
dc.w    $1A6,$0a0    ; colour19
dc.w    $140,$00a0    ; spr0pos

dc.w    $4607,$fffe    ; wait for line $46
dc.w    $142,$0000    ; SPR0CTL - ‘turns off’ the sprite
dc.w    $ffff,$fffe    ; end copperlist

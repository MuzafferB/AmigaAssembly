
; Lesson7y1.s    A SPRITE DISPLAYED BY WRITING DIRECTLY TO THE REGISTERS
;        (WITHOUT DMA)
; This example shows a sprite obtained by using the registers directly
; . The sprite is displayed in two different
;    horizontal positions, similar to reuse.


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
LEA	BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

;    DO NOT point to the sprite!!!!!!!!!!!!!!!!!!!!

move.l    #COPPERLIST,$dff080	; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr    -$19e(a6)    ; Close library
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
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w    $12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0001001000000000    ; bit 12 on!! 1 lowres bitplane

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first bitplane

dc.w    $180,$000    ; colour0    ; black background
dc.w    $182,$123    ; colour1    ; colour 1 of the bitplane, which
; in this case is empty,
; so it does not appear.

dc.w    $1A2,$FF0    ; colour17, i.e. COLOUR1 of sprite0 - YELLOW
dc.w    $1A4,$a00    ; colour18, i.e. COLOUR2 of sprite0 - RED
dc.w    $1A6,$F70    ; colour19, i.e. COLOUR3 of sprite0 - ORANGE


dc.w    $4007,$fffe    ; wait for line $40
dc.w    $140,$0080    ; SPR0POS - horizontal position
dc.w    $142,$0000    ; SPR0CTL
dc.w    $146,$0e70    ; SPR0DATB
dc.w    $144,$03c0    ; SPR0DATA - activates the sprite

dc.w    $6007,$fffe    ; wait for line $60
dc.w    $142,$0000    ; SPR0CTL - ‘turns off’ the sprite
 

dc.w    $140,$00a0    ; SPR0POS - new horizontal position
dc.w    $146,$2ff4    ; SPR0DATB
dc.w    $8007,$fffe    ; wait for line $80
dc.w    $144,$13c8    ; SPR0DATA - activate the sprite

dc.w    $b407,$fffe    ; wait for line $b4
dc.w    $142,$0000    ; SPR0CTL - ‘turns off’ the sprite 

dc.w    $FFFF,$FFFE    ; End of copperlist



SECTION    PLANEVUOTO,BSS_C    ; The reset bitplane we use,
; because to see the sprites
; it is necessary that there are bitplanes
; enabled
BITPLANE:
ds.b    40*256        ; reset bitplane lowres

end

In this example, we see how to use a sprite by directly manipulating the
SPRxPOS, SPRxCTL, SPRxDATA, SPRxDATB registers.
First, note that we do NOT point the sprite in the copperlist. In fact,
moreover, the sprite structure does NOT exist in the chip memory. In fact, this
structure is used by the DMA, which, when used, basically just
copies the data from the structure to the SPRxPOS, SPRxCTL, SPRxDATA,
SPRxDATB registers. If we write the data directly to those registers, we don't
need the DMA. Let's see in detail how to use the registers.
The position of the sprite is written in SPRxPOS. The content of this
register is basically the same as the first control word of the
sprite structure that we use with the DMA. The difference, however, is that VSTART
does not affect the vertical position of the sprites. Sprites are
activated by writing to the SPRxDATA register. Once activated, a
sprite is drawn on every line, at the horizontal position we
wrote in SPRxPOS, and it always has the same ‘shape’ for every line.
The ‘shape’ of the sprite is written in the two registers SPRxDATB and SPRxDATA,
 which work exactly like the pairs of words that describe the shape
of the sprite in the structure used with the DMA. The most significant bits
are contained in SPRxDATB and the least significant in SPRxDATA. These two
registers are reused for each line. Therefore, if you want the
shape of the sprite to change from one row to another, you must modify the
two SPRxDATx registers for each row.
The SPRxCTL register, on the other hand, has the same content as the second control word of the
structure. Here too, the vertical position is useless
. In practice, the only bits in the entire register that have any
meaning are bit 0, which is the low bit of HSTART, and bit 7, which
is used to ‘attach’ sprites. Writing to the SPRxCTL register also
disables the sprite.

Using sprites without DMA is very inconvenient because you have to change SPRxDATx at
every line. In fact, it is not usually used. However, it can be
advantageous if you want a sprite that is the same for
every line: basically, to make columns. In this case, it is not
necessary to change SPRxDATx at each line, because what you want is
for the sprite to have the same shape at each line. Furthermore, with this
method, we save a lot of memory: if we had to make a sprite column 
100 lines high with the DMA, we would be forced to use a structure
100 longwords long, excluding the control words!

The procedure for making a column with sprites without DMA is therefore
as follows:
1) Write the correct values in SPRxPOS, SPRxCTL and SPRxDATB
2) Wait for the vertical position where you want the sprite to start
.
3) Write the value of SPRxDATA. At this point, the sprite will be
drawn, always the same on every line.
4) Wait for the vertical position where you want the sprite to end.
5)
Write any value in SPRxCTL

As we do in this example, it is possible to display multiple columns at 
different heights by repeating the procedure described above several times 
in the same copperlist. You could also change the palette between
columns.

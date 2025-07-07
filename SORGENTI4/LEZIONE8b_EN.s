
; Lesson8b.s - Using universal startup for an example that is
;        a fusion of Lesson7o.s sprites and the
;        print routine from Lesson 6.


Section    UseStartup,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup1.s’    ; with this include I save myself from
; rewriting it every time!
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110100000    ; copper and bitplane DMA enabled
;		 -----a-bcdefghij

;    a: Blitter Nasty (We're not interested in this for now, let's leave it at zero)
;    b: Bitplane DMA     (If not set, the sprites will also disappear)
;    c: Copper DMA     (If set to zero, the copperlist will not be executed either)
;    d: Blitter DMA     (We don't need this for now, let's set it to zero)
;    e: Sprite DMA     (Setting this to zero only makes the 8 sprites disappear)
;    f: Disk DMA     (We don't need this for now, let's set it to zero)
;    g-j: Audio 3-0 DMA (Let's set this to zero to mute the Amiga)

; MAIN PROGRAM - remember that the DMA channels are all reset

START:
;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

;    Point all sprites to the null sprite

MOVE.L    #SpriteNullo,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
MOVEQ    #8-1,d1            ; all 8 sprites
NulLoop:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
addq.w    #8,a1
dbra    d1,NulLoop

;    Point to the sprite

MOVE.L	#MIOSPRITE,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

addq.w    #8,a1            ; pointer to sprite 1
MOVE.L	#MIOSPRITE2,d0        ; sprite address in d0
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)		; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L	4(A5),D0 ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.s    PrintCharacter    ; Print one character at a time
bsr.w    MoveSprite    ; Move sprites 0 and 1

MOVE.L    #$1ff00,d1    ; bits for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts            ; exit

*****************************************************************************
;            Print routine
*****************************************************************************

PRINTcharacter:
MOVE.L    PointTEXT(PC),A0 ; Address of text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
CMP.B    #$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s    NotEndLine    ; If no, do not go to the next line

ADD.L    #40*7,PuntaBITPLANE    ; GO TO THE NEXT LINE
ADDQ.L    #1,PuntaTesto        ; first character of the next line
; (skip ZERO)
move.b    (a0)+,d2        ; first character of the next line
; (skip ZERO)

NonFineRiga:
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
LSL.W    #3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 " ‘
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ’ ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ ‘
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ’ "
MOVE.B	(A2)+,40*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 " "

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
RTS


PuntaTesto:
dc.l    TEXT

BitplanePointer:
dc.l    BITPLANE

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
; 1234567890123456789012345678901234567890
dc.b    “ ”,0 ; 1
dc.b    “ This listing uses channels ”,0 ; 2
dc.b    “ ”,0 ; 3
dc.b	“ DMA of COPPER, BITPLANE and ”,0 ; 4
dc.b    “ ”,0 ; 5
dc.b    “ SPRITE, try not to ”,0 ; 6
dc.b    “ ”,0 ; 7
dc.b    “ enable them one by one and you will see ”,0 ; 8
dc.b	“ ”,0 ; 9
dc.b    “ the sprites will disappear, then the text ”,0 ; 10
dc.b    “ ”,0 ; 11
dc.b    “ and also the copper shades! ”,$FF ; 12

EVEN

*****************************************************************************
;    Sprite routines
*****************************************************************************

MoveSprite:
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L    TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S    NOBSTARTY    ; Not yet? Then continue
MOVE.L	#TABY-1,TABYPOINT ; Start pointing to the first byte again
NOBSTARTY:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the table byte, i.e. the
; Y coordinate in d0 so that it can be
; found by the universal routine

ADDQ.L    #2,TABXPOINT     ; Point to the next word
MOVE.L    TABXPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last word of the TAB?
BNE.S    NOBSTARTX    ; not yet? then continue
MOVE.L    #TABX-2,TABXPOINT ; Start pointing again from the first word-2
NOBSTARTX:
moveq    #0,d1        ; reset d1
MOVE.w    (A0),d1        ; set the value of the table, i.e.
; the X coordinate in d1

lea    MIOSPRITE,a1    ; address of the sprite in A1
moveq    #13,d2        ; height of the sprite in d2

bsr.w    UniMuoviSprite ; executes the universal routine that positions
; the sprite
; second sprite

ADDQ.L    #1,TABYPOINT2     ; Point to the next byte
MOVE.L    TABYPOINT2(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S    NOBSTARTY2    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT2 ; Start pointing to the first byte again
NOBSTARTY2:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the table byte, i.e. the
; Y coordinate in d0 so that it
; can be found by the universal routine

ADDQ.L    #2,TABXPOINT2     ; Point to the next word
MOVE.L	TABXPOINT2(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last word of the TAB?
BNE.S    NOBSTARTX2    ; Not yet? Then continue
MOVE.L    #TABX-2,TABXPOINT2 ; Start pointing to the first word-2 again
NOBSTARTX2:
moveq    #0,d1        ; reset d1
MOVE.w    (A0),d1        ; set the table value, i.e.
; the X coordinate in d1

lea    MIOSPRITE2,a1    ; address of the sprite in A1
moveq    #8,d2		; height of the sprite in d2

bsr.w    UniMuoviSprite ; executes the universal routine that positions
; the sprite
rts

; pointers to the tables of the first sprite

TABYPOINT:
dc.l    TABY-1
TABXPOINT:
dc.l    TABX-2

; pointers to the tables of the second sprite

TABYPOINT2:
dc.l    TABY+40-1
TABXPOINT2:
dc.l    TABX+96-2

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
;	Input parameters of UniMuoviSprite:
;
;    a1 = Sprite address
;    d0 = Vertical position Y of the sprite on the screen (0-255)
;    d1 = Horizontal position X of the sprite on the screen (0-320)
;    d2 = Height of the sprite
;

UniMuoviSprite:
; Vertical positioning
ADD.W    #$2c,d0        ; add the offset of the start of the screen

; a1 contains the address of the sprite
MOVE.b    d0,(a1)        ; copy the byte to VSTART
btst.l    #8,d0
beq.s    NonVSTARTSET
bset.b    #2,3(a1)	; Set bit 8 of VSTART (number > $FF)
bra.s    ToVSTOP
NonVSTARTSET:
bclr.b    #2,3(a1)    ; Clear bit 8 of VSTART (number < $FF)
ToVSTOP:
ADD.w    D2,D0		; Add the sprite height to
; determine the final position (VSTOP)
move.b    d0,2(a1)    ; Move the correct value to VSTOP
btst.l    #8,d0
beq.s    NonVSTOPSET
bset.b    #1,3(a1)    ; Set bit 8 of VSTOP (number > $FF)
bra.w    VstopFIN
NonVSTOPSET:
bclr.b    #1,3(a1)    ; Clear bit 8 of VSTOP (number < $FF)
VstopFIN:

; horizontal positioning
add.w    #128,D1		; 128 - to centre the sprite.
btst    #0,D1        ; low bit of the X coordinate reset?
beq.s    BitBassoZERO
bset    #0,3(a1)    ; Set the low bit of HSTART
bra.s    PlaceCoords

BitBassoZERO:
bclr	#0,3(a1)    ; Reset the low bit of HSTART
PlaceCoords:
lsr.w    #1,D1        ; SHIFT, i.e. move the value of HSTART 1 bit to the right
; to ‘transform’ it into
; the value to be placed in the HSTART byte, without
; the low bit.
move.b    D1,1(a1)    ; We place the value XX in the HSTART byte
rts

*****************************************************************************

;    The 8x8 character FONT copied to CHIP by the CPU and not by the blitter,
;    so it can also be in fast RAM. In fact, that would be better!

FONT:
incbin    ‘assembler2:sorgenti4/nice.fnt’

*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w    $12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,$24    ; BplCon2 - All sprites above the bitplanes
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$19a    ; colour1 - TEXT

dc.w    $1A2,$F00    ; colour17, i.e. COLOUR1 of sprite0 - RED
dc.w    $1A4,$0F0    ; colour18, i.e. COLOUR2 of sprite0 - GREEN
dc.w    $1A6,$FF0    ; colour19, i.e. COLOUR3 of sprite0 - YELLOW

;    Copperlist shading

dc.w    $5007,$fffe    ; WAIT line $50
dc.w    $180,$001    ; colour0
dc.w    $5207,$fffe    ; WAIT line $52
dc.w    $180,$002    ; colour0
dc.w    $5407,$fffe	; WAIT line $54
dc.w    $180,$003    ; colour0
dc.w    $5607,$fffe    ; WAIT line $56
dc.w    $180,$004    ; colour0
dc.w    $5807,$fffe	; WAIT line $58
dc.w    $180,$005    ; colour0
dc.w    $5a07,$fffe    ; WAIT line $5a
dc.w    $180,$006    ; colour0
dc.w    $5c07,$fffe    ; WAIT line $5c
dc.w    $180,$007    ; colour0
dc.w    $5e07,$fffe    ; WAIT line $5e
dc.w    $180,$008    ; colour0
dc.w    $6007,$fffe	; WAIT line $60
dc.w    $180,$009    ; colour0
dc.w    $6207,$fffe    ; WAIT line $62
dc.w    $180,$00a    ; colour0


dc.w    $FFFF,$FFFE    ; End of copperlist


; ************ Here are the sprites: OBVIOUSLY they must be in CHIP RAM! ********

SpriteNullo:            ; Null sprite to point to in copperlist
dc.l    0,0,0,0        ; in any unused pointers


MIOSPRITE:        ; length 13 lines
dc.b $50    ; Vertical position of sprite start (from $2c to $f2)
dc.b $90    ; Horizontal position of sprite start (from $40 to $d8)
dc.b $5d	; $50+13=$5d    ; vertical position of sprite end
dc.b $00
dc.w    %0000000000000000,%0000110000110000 ; Binary format for modifications
dc.w    %0000000000000000,%0000011001100000
dc.w    %0000000000000000,%0000001001000000
dc.w    %0000000110000000,%0011000110001100 ;BINARY 00=COLOUR 0 (TRANSPARENT)
dc.w    %0000011111100000,%0110011111100110 ;BINARY 10=COLOUR 1 (RED)
dc.w    %0000011111100000,%1100100110010011 ;BINARY 01=COLOUR 2 (GREEN)
dc.w    %0000110110110000,%1111100110011111 ;BINARY 11=COLOUR 3 (GIALLO)
dc.w	%0000011111100000,%0000011111100000
dc.w	%0000011111100000,%0001111001111000
dc.w	%0000001111000000,%0011101111011100
dc.w	%0000000110000000,%0011000110001100
dc.w	%0000000000000000,%1111000000001111
dc.w	%0000000000000000,%1111000000001111
dc.w    0,0    ; 2 words reset define the end of the sprite.


MIOSPRITE2:        ; length 8 lines
VSTART2:
dc.b $60    ; Vertical position (from $2c to $f2)
HSTART2:
dc.b $60+(14*2)    ; Horizontal position (from $40 to $d8)
VSTOP2:
dc.b $68    ; $60+8=$68    ; vertical end.
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000111001111
dc.w	%0011111111111100,%1100001000100011
dc.w	%0111111111111110,%1000000000100001
dc.w	%0111111111111110,%1000000111000001
dc.w	%0011111111111100,%1100001000000011
dc.w	%0000111111110000,%1111001111101111
dc.w	%0000001111000000,%0111110000111110
dc.w    0,0    ; end sprite


*****************************************************************************

SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    40*256    ; a lowres 320x256 bitplane

end

This listing shows two optimisations of routines already seen.
One is the one discussed in Lesson 8, i.e. waiting for the vertical line
:

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

Please note that the maximum line you can wait for is $138. If you wait for
$139 or beyond, the routine will freeze because that value never occurs.

The other optimisation, which may have gone unnoticed, is:

MULU.W    #8,d2

Which has been transformed into:

LSL.W    #3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; the characters being 8 pixels high

In the PRINT routine. Well, moving 3 bits to the left corresponds to
multiplying by 8, just as moving 1 bit to the left means multiplying
by 2 and moving 2 bits to the left means multiplying by 4.
This is because binary facilitates multiplication and division by
powers of 2. Let's look at an example:

5 * 8 = 40

Let's see it in binary:

%00000101 * %00001000 = %00101000

As you can see, the result, 40, is the same as 5, but with the bits shifted
3 positions to the left. We will see many of these tricks later on to
speed up the code; the most important thing to remember is that
multiplication and division are VERY SLOW, so getting rid of them
by replacing them with something else is very useful.

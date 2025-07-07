
; Lesson 6r.s    SUMMARY OF LESSON 6 - VARIOUS ROUTINES FROM THE LESSON
;        COMBINED TOGETHER + MUSICAL ROUTINE

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANETESTO-2,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

MOVE.L    #BITPLANEGRIGLIA-2,d0
LEA    BPLPOINTERS2,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106		; Disable AGA

bsr.w    grid3    ; Make the chessboard on BITPLANEGRIGLIA

bsr.w    mt_init        ; Initialise music routine

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    PrintCharacter    ; Print one character at a time
bsr.w    MEGAScrolla    ; Scroll the 640
; pixel wide screen on one of 320
bsr.w    Bounce    ; Bounce the TEXT bitplane
bsr.w    mt_music    ; Play music

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

bsr.w    mt_end        ; End music routine

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

;************************************************************************
;*    Print one character at a time on a 640-pixel wide screen    *
;************************************************************************

PRINTcharacter:
MOVE.L    PointTEXT(PC),A0 ; Address of text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
CMP.B    #$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s    NotEndLine    ; If no, do not go to the next line

ADD.L    #80*7,PointerBITPLANE	; GO TO NEW LINE
ADDQ.L    #1,TextPointer        ; first character of line after
; (skip ZERO)
move.b    (a0)+,d2        ; first character of line after
; (skip ZERO)

NotEndLine:
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; as the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,80(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,80*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,80*3(A3)    ; print LINE 4 ‘ ’
MOVE.B	(A2)+,80*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,80*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,80*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,80*7(A3)    ; print LINE 8 ‘ ’

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
RTS


TextPointer:
dc.l    TEXT

BitplanePointer:
dc.l    BITPLANETEXT

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 80
TEXT:
dc.b    ‘ THIS DEMO SUMMARISES THE LESSON’
dc.b    ‘AND 6 BECAUSE IT CONTAINS BOTH THE ’,0
dc.b    ‘ ’
dc.b    ‘ ’,0
dc.b    ‘ CHARACTER PRINTING ROUTINE’
dc.b    ‘I OF 8x8 PIXELS, BOTH THE SCROLL ’,0
dc.b    ‘ ’
dc.b    ‘ ’,0
dc.b    ‘ HORIZONTAL VIA THE BPLCON1’
dc.b    ‘ ($dff102) AND THE BPLPOINTERS, BOTH ’,0
dc.b	‘ ’
dc.b    ‘ ’,0
dc.b    ‘ THE USE OF A TABLE OF PREDEFINED VALUES’
dc.b    ‘ FOR MOVEMENT ’,0
dc.b    ‘ ’
dc.b	‘ ’,0
dc.b    ‘ VERTICAL OSCILLATOR OF THIS
dc.b    ’TEXT. ‘,0
dc.b    ’ ‘
dc.b    ’ ‘,0
dc.b    ’ THE PLAYFIELD WHERE THIS TEXT IS PRINTED‘
dc.b    ’HAS THE DIMENSIONS ",0
dc.b	‘ ’
dc.b    ‘ ’,0
dc.b    ‘ OF A HIRES SCREEN, I.E. 64’
dc.b    ‘0 PIXELS WIDE BY 256 ’,0
dc.b    ‘ ’
dc.b    ‘ ’,0
dc.b    " HIGH, AND IS MOVED BOTH ‘
dc.b    ’HORIZONTALLY AND VERTICALLY, ‘,0
dc.b    ’ ‘
dc.b    ’ ‘,0
dc.b    ’ WHILE THE BITPLANE CONTAINING‘
dc.b    ’AND THE GRID IS MOVED ONLY ",0
dc.b	‘ ’
dc.b    ‘ ’,0
dc.b    ‘ HORIZONTALLY. THE SCROLL IS
dc.b    ’VERTICAL, BEING DETERMINED BY A ‘,0
dc.b    ’ ‘
dc.b    ’ ‘,0
dc.b    ’ TABLE, HAS VARIABLE SPEED"
dc.b    ‘AND, WHILE THE HORIZONTAL SCROLL IS’,0
dc.b    ‘ ’
dc.b    ‘ ’,0
dc.b    ‘ ALWAYS 2 PIXELS PER FRAME’
dc.b    ‘BUT. ’,$FF



EVEN

;************************************************************************
;* Scrolls 320 pixels to the right and left (Lesson 6o.s)    *
;************************************************************************

; NOTE: Modified to also act on the GRID bitplane

MEGAScrolla:
addq.w    #1,ContaVolte    ; Mark one more execution
cmp.w    #160,ContaVolte    ; Are we at 160? Then we have scrolled 320
; pixels, since we execute the
; RIGHT or LEFT routine twice every FRAME to go at
; double speed
bne.S    MoveAgain    ; If not yet, move again
BCHG.B    #1,DestSinFlag    ; If we are at 160, however, change direction
CLR.w	CountTimes    ; of scrolling and reset ‘CountTimes’
rts

MoveAgain:
BTST    #1,DestSinFlag    ; Should we go right or left?
BEQ.S    GoLeft
bsr.s    Right        ; Scroll one pixel to the right
bsr.s    Right        ; Scroll one pixel to the right
; (2 pixels per frame, therefore double speed)
rts

GoLeft:
bsr.s    Left    ; Scroll one pixel to the left
bsr.s    Left    ; Scroll one pixel to the left
; (2 pixels per frame, therefore double speed)
rts

; This word counts how many times we have moved to the right or left

CountTimes:
DC.W	0

; When bit 1 of DestSinFlag is ZERO, the routine scrolls left; if
; it is 1, it scrolls right.

DestSinFlag:
DC.W    0

; This routine scrolls a bitplane to the right by acting on BPLCON1 and
; pointers to bitplanes in copperlist. MIOBPCON1 is the byte of BPLCON1.

Right:
CMP.B    #$ff,MIOBPCON1    ; have we reached the maximum scroll? (15)
BNE.s    CON1ADDA    ; if not, scroll forward by 1
; with BPLCON1

LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; $dff0e0 is currently pointing and we point it to d0
move.w    6(a1),d0

LEA    BPLPOINTERS2,A2    ; With these 4 instructions we retrieve from
move.w    2(a2),d1	; copperlist the address where swap is pointing
swap    d1        ; currently $dff0e4 and we point it to d0
move.w    6(a2),d1

subq.l    #2,d0        ; points 16 bits further back (the PIC scrolls
; 16 pixels to the right) - TEXT

subq.l    #2,d1        ; points 16 bits back (the PIC scrolls
; to the right by 16 pixels) - GRID

clr.b    MIOBPCON1    ; resets the hardware scroll BPLCON1 ($dff102)
; in fact, we have ‘jumped’ 16 pixels with the
; bitplane pointer, now we have to start
; from scratch with $dff102 to move
; one pixel to the right at a time.

;    Point to the TEXT bitplane

move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)	; copy the HIGH word of the plane address

;    Point to the GRID bitplane

move.w    d1,6(a2)    ; copy the LOW word of the plane address
swap	d1        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d1,2(a2)    ; copy the HIGH word of the plane address

rts

CON1ADDA:
add.b    #$11,MIOBPCON1	; scroll forward by 1 pixel
rts

;    Routine that moves to the left in a similar way:

Left:
TST.B    MIOBPCON1    ; have we reached the minimum scroll? (00)
BNE.s    CON1SUBBA    ; if not, scroll back by 1
; with BPLCON1

LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; $dff0e0 is currently pointing and we point it to d0
move.w    6(a1),d0

LEA    BPLPOINTERS2,A2    ; With these 4 instructions we retrieve from
move.w    2(a2),d1    ; copperlist the address where it is pointing
swap    d1        ; currently $dff0e4 and we point it to d0
move.w    6(a2),d1

addq.l    #2,d0        ; points 16 bits further (the PIC scrolls
; 16 pixels to the left) - TEXT

addq.l    #2,d1        ; points 16 bits further (the PIC scrolls
; 16 pixels to the left) - GRID

move.b    #$FF,MIOBPCON1    ; hardware scroll to 15 - BPLCON1 ($dff102)

;    Point to the TEXT bitplane

move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address

;    Point to the GRID bitplane

move.w    d1,6(a2)    ; copy the LOW word of the plane address
swap; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w d1,2(a2); copy the HIGH word of the plane address

rts

CON1SUBBA:
sub.b	#$11,MIOBPCON1	; scorri indietro di 1 pixel
rts


;************************************************************************
;* Oscillates UP/DOWN using a table (Lesson 6m.s)    *
;************************************************************************

Bounce:
LEA    BPLPOINTERS,A1    ; With these 4 instructions we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; $dff0e0 is currently pointing and we point it to d0
move.w    6(a1),d0

ADDQ.L    #4,RIMTABPOINT    ; Point to the next longword
MOVE.L    RIMTABPOINT(PC),A0 ; address contained in long RIMTABPOINT
; copied to a0
CMP.L	#FINERIMBALZTAB-4,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTART2        ; Not yet? Then continue
MOVE.L    #RIMBALZTAB-4,RIMTABPOINT ; Start pointing to the first longword again
NOBSTART2:
MOVE.l    (A0),d1        ; copy the long from the table to d1

sub.l    d1,d0        ; subtract the value currently taken from the
; table, scrolling the figure UP or DOWN.

LEA	BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ    #1,D1        ; number of bitplanes -1 (here there are 3)
POINTBP2:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #80*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1		; go to the next bplpointers in COP
;    dbra    d1,POINTBP2    ; Repeat D1 times POINTBP (D1=number of bitplanes)
rts


RIMTABPOINT:            ; This longword ‘POINTS’ to RIMBALZTAB, i.e.
dc.l    RIMBALZTAB-4    ; contains the address of RIMBALZTAB. It will hold
; the address of the last long ‘read’ inside
; the table. (here it starts from RIMORTAB-4 in
; as Blinking starts with an ADDQ.L #4,C..
; it is used to ‘balance’ the first instruction.

;    The table with the ‘precalculated’ bounce values

RIMBALZTAB:
dc.l    0,0,80,80,80,80,80,80,80,80,80             ; at the top
dc.l    80,80,2*80,2*80
dc.l    2*80,2*80,2*80,2*80,2*80            ; accelerate
dc.l    3*80,3*80,3*80,3*80,3*80
dc.l    3*80,3*80,3*80,3*80,3*80
dc.l	2*80,2*80,2*80,2*80,2*80; decelerate
dc.l    2*80,2*80,80,80
dc.l    80,80,80,80,80,80,80,80,80,0,0,0,0,0,0,0; in fondo
dc.l	-80,-80,-80,-80,-80,-80,-80,-80,-80
dc.l	-80,-80,-2*80,-2*80
dc.l	-2*80,-2*80,-2*80,-2*80,-2*80
dc.l    -3*80,-3*80,-3*80,-3*80,-3*80            ; accelerate
dc.l    -3*80,-3*80,-3*80,-3*80,-3*80
dc.l    -2*80,-2*80,-2*80,-2*80,-2*80            ; decelerate
dc.l	-2*80,-2*80,-80,-80
dc.l	-80,-80,-80,-80,-80,-80,-80,-80,-80,0,0,0,0,0	; in cima
FINERIMBALZTAB:

;************************************************************************
;* makes a chessboard with squares of 16 pixels on each side (Lesson 6q.s)    *
;************************************************************************

GRID3:
READ    BITPLANEGRIGLIA,a0    ; Destination bitplane address

MOVEQ    #8-1,d0		; 8 pairs of 16-pixel squares
; 8*2*16=256 complete screen fill
MakePair3:
move.l    #(20*16)-1,d1    ; 20 longwords to fill 1 line (640 pixels)
; 16 lines to fill
DoONE3:
move.l    #%11111111111111110000000000000000,(a0)+
; square length at 1 = 16 pixels
; square reset = 16 pixels
dbra    d1,DoONE3        ; do 16 lines #.#.#.#.#.#.#.#.#.#

move.l    #(20*16)-1,d1    ; 20 lingwords to fill 1 line (640 pixels)
; 16 lines to fill
DoMORE3:
move.l    #%00000000000000001111111111111111,(a0)+
; length of reset square = 16
; square at 1 = 16 pixels
dbra    d1,DoMore3		; make 8 lines .#.#.#.#.#.#.#.#.

DBRA    d0,FaiCoppia3         ; make 8 pairs of squares
; #.#.#.#.#.#.#.#.#.
rts                 ; .#.#.#.#.#.#.#.#.

; **************************************************************************
; *        ROUTINE THAT PLAYS SOUNDTRACKER/PROTRACKER MUSIC     *
; **************************************************************************

include    ‘music.s’    ; routine 100% working on all Amigas


SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

dc.w    $8e,$2c81    ; DiwStrt
dc.w    $90,$2cc1	; DiwStop
dc.w    $92,$30        ; DdfStart (modified for SCROLL)
dc.w    $94,$d0        ; DdfStop
dc.w    $102        ; BplCon1
dc.b    0        ; unused ‘high’ byte of $dff102
MIOBPCON1:
dc.b	0; ‘low’ byte used of $dff102
dc.w    $104,0; BplCon2
dc.w    $108,40-2; Bpl1Mod (40 for the wide figure 640, the -2
dc.w    $10a,40-2	; Bpl2Mod (to balance DDFSTART

; 5432109876543210
dc.w    $100,%0010001000000000    ; bit 12 - 1 LOWRES bitplane

BPLPOINTERS:
dc.w $e0,0,$e2,0    ; first bitplane
BPLPOINTERS2:
dc.w $e4,0,$e6,0    ; second bitplane

dc.w    $180,$113    ; colour0 - DARK SQUARE
dc.w    $182,$bb5	; colour1 - TEXT+dark square
dc.w    $184,$225    ; colour2 - LIGHT SQUARE
dc.w    $186,$bb5    ; colour3 - TEXT+light square

dc.w    $FFFF,$FFFE    ; End of copperlist


;    The 8x8 character FONT

FONT:
incbin    ‘metal.fnt’
;    incbin    ‘normal.fnt’
;    incbin    ‘nice.fnt’

; **************************************************************************
; *                PROTRACKER MUSIC             *
; **************************************************************************

mt_data:
incbin	‘mod.purple-shades’


SECTION	MIOPLANE,BSS_C

BITPLANEGRIGLIA:
ds.b	80*256	; un bitplane 640x256


ds.b    80*100
BITPLANETESTO:
ds.b    80*256    ; a 640x256 bitplane


end

Sometimes putting together routines with little effect generates a nice result.


; Lesson 6a.s    LET'S PRINT ONE OF THE CHARACTERS ON THE SCREEN!!!

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0    ; put the PIC address in d0,
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

bsr.w    print        ; Print a word on the screen

mouse:
btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts            ; EXIT THE PROGRAM

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

;    Routine that prints 8x8 pixel characters

TEXT:
dc.b    “A”    ; the text to be printed. Here just an ‘A’, i.e. $41

EVEN    ; align to even address


PRINT:
LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0),D2        ; Next character in d2
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THE
; OF THE SPACE (which is $20) in $00, that
; OF THE ASTERISK ($21) in $01...
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L	#FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ‘ ’
MOVE.B	(A2)+,40*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

RTS



SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8E,$2c81	; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$19a    ; colour1 - TEXT


dc.w $FFFF,$FFFE ; End of copperlist

;    The 8x8 character FONT

FONT:
incbin ‘nice.fnt’ ; without ALT characters

SECTION    MIOPLANE,BSS_C    ; The BSS SECTIONS must consist of
; only ZEROS!!! Use DS.b to define
; how many zeros the section contains.

BITPLANE:
ds.b    40*256    ; a low-resolution 320x256 bitplane

end

An ‘A’ has appeared on our monitor!!! In the upper left corner.
You can change the word to be printed, but it's not a big change to print
a “B” instead of an ‘A’.

* CHANGE 1:

Try printing only half the character, i.e. its first 4 lines:


MOVE.B    (A2)+,(A3)    ; prints LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; prints LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; prints LINE 3 ‘ ’
MOVE.B	(A2)+,40*3(A3)    ; prints LINE 4 ‘ ’
;    MOVE.B    (A2)+,40*4(A3)    ; prints LINE 5 ‘ ’
;    MOVE.B    (A2)+,40*5(A3)    ; prints LINE 6 ‘ ’
;    MOVE.B	(A2)+,40*6(A3)    ; print LINE 7 ‘ ’
;    MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

Each line is one byte, i.e. 8 BITS

12345678

...###.. line    1 - 8 bits, 1 byte
..#...#. 2
..#...#. 3
..#####. 4
..#...#. 5
..#...#. 6
..#...#. 7........
 8

* CHANGE 2:

Try removing EVEN from the string:

dc.b    ‘A’

When assembling the ASMONE, you will get the error: ‘Word at ODD address’, i.e.
‘ODD ADDRESS!!’. Just put the zero back in place or add EVEN.


* CHANGE 3:

To change the position of the ‘A’, simply change the destination of the PRINT:

PRINT:
LEA    TEXT(PC),A0
LEA    BITPLANE+(40*120),A3 ; Destination address

This will print 120 lines lower, in the centre of the screen.
To move the character forward, just add some bytes:

LEA    BITPLANE+19+(40*120),A3 ; Destination address

This moves it forward by 19 bytes, and it is printed at the twentieth
byte, halfway across the screen (which is 40 bytes).

* CHANGE 4:

Let's try to display the character in a bitplane in HIRES: To do this
make the following changes:

In the routine, since the hires screen is 80 bytes wide per line instead of 40:

MOVE.B    (A2)+,(A3)    ; prints LINE 1 of the character
MOVE.B    (A2)+,80(A3)	; print LINE 2 ‘ ’
MOVE.B    (A2)+,80*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,80*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,80*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,80*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,80*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,80*7(A3)    ; print LINE 8 ‘ ’

In the copperlist: set BIT 15 in BPLCON0, activating HIRES

; 5432109876543210
dc.w    $100,%1001001000000000    ; 1 bitplane HIRES 640x256

And modify the DDFSTART/DDFSTOP for the HIRES screen, otherwise the first lines on the left will be ‘CUT’.
If you do not modify these two registers, the ‘A’ will not be displayed if it is on the left edge.
Finally, in the SECTION BSS:

dc.w    $92,$003c    ; Normal HIRES DdfStart
dc.w    $94,$00d4    ; Normal HIRES DdfStop

Finally, in SECTION BSS: we need to enlarge the BITPLANE!

ds.b    80*256    ; a 640x256 hires bitplane

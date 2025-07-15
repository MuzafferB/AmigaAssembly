
; Lesson 6b.s    LET'S PRINT A LINE OF TEXT ON THE SCREEN!!!

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
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

bsr.w    print        ; Print a line of text on the screen

mouse:
btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)    ; Closelibrary - close graphics library
rts            ; EXIT PROGRAM

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

;    Routine that prints 8x8 pixel characters

PRINT:
LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
MOVEQ    #40-1,D0    ; NUMBER OF COLUMNS PER LINE: 40 (i.e. the number
; of characters in a line).
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20) into $00, that
; OF THE ASTERISK ($21) into $01...
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L	#FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

; PRINT THE CHARACTER LINE BY LINE

MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 " ‘
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ’ ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ ‘
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ’ ‘
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ’ ‘
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ’ ‘
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ’ "

ADDQ.w    #1,A3        ; A3+1, move forward 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (40) CHARACTERS PER LINE

RTS


; number of characters per line: 40
TEXT:     ;		 1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b    “ FIRST LINE On the screen! 123 test ”

EVEN



SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
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
; incbin ‘metal.fnt’ ; Wide character
; incbin ‘normal.fnt’ ; Similar to kickstart 1.3 characters
incbin ‘nice.fnt’ ; Narrow character

SECTION    MIOPLANE,BSS_C    ; The BSS SECTIONS must consist of
; only ZEROS!!! Use DS.b to define
; how many zeros the section contains.

BITPLANE:
ds.b    40*256    ; a low-resolution 320x256 bitplane

end

You can write many things in a single line. To print 40 characters, just
run a DBRA cycle, here called PRINTCHAR2:

MOVEQ    #40-1,D0    ; NUMBER OF COLUMNS PER LINE: 40
PRINTCHAR2:

Since each character is one byte ‘wide’, there can be 40
characters in LOWRES, or 80 in HIRES. Before repeating the cycle to print
the next character, there is an ADD that moves to the next byte, i.e. to the
next position where the adjacent character is to be printed:

ADDQ.w    #1,A3        ; A1+1, we move forward 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (40) CHARACTERS PER LINE

You can choose between 3 different fonts, just remove and insert the ; at the incbin
to load the one you want.

If you want to view the line in high resolution, make the changes as in
Lesson 6a.s. In addition, you can ‘lengthen’ the text up to 80 characters.
In this case, you must change the PRINTCHAR loop to MOVEQ #80-1,d0.
You can also write the text in two lines per row:

dc.b    “ FIRST LINE On the screen! 123 test ” 0-40
dc.b    “ I'm still on the first high-resolution line!! ” 41-80

dc.b    " SECOND LINE!..........................‘
dc.b    ’........................................‘

dc.b    ’ THIRD LINE!...... etc.


; Lesson 6h.s    PRINTING VARIOUS LINES OF TEXT * IN 3 COLOURS * ACTIVATING THE
;        SECOND BITPLANE, ON WHICH WE WRITE THE TEXT2.

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;     POINT OUR BITPLANES

MOVE.L    #BITPLANE,d0	; put the address of bitplane1 in d0
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address

MOVE.L    #BITPLANE2,d0    ; put the address of bitplane 2 in d0
LEA    BPLPOINTERS2,A1    ; pointers in COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address

move.l    #COPPERLIST,$dff080    ; Let's point our COP
move.w    d0,$dff088        ; Let's start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
bsr.w    print        ; Print the lines of text on the screen

LEA    TEXT2(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE2,A3    ; Address of the destination bitplane in a3
bsr.w    print        ; Print the lines of text on the screen

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

PRINT:
MOVEQ    #23-1,D3	; NUMBER OF LINES TO PRINT: 23
PRINTRIGA:
MOVEQ    #40-1,D0    ; NUMBER OF COLUMNS PER LINE: 40
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
SUB.B    #$20,D2        ; REMOVE 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; as the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 " ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ ‘
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ’ ‘
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ’ "
MOVE.B	(A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

ADDQ.w    #1,A3        ; A1+1, advance 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (40) CHARACTERS PER LINE

ADD.W    #40*7,A3    ; GO TO THE NEXT LINE

DBRA    D3,PRINTRIGA    ; MAKE D3 LINES

RTS


; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b    “ FIRST LINE (only in text1) ” ; 1
dc.b    “ ” ; 2
dc.b    “ /\ / ” ; 3
dc.b    “ / \/ ” ; 4
dc.b    “ ” ; 5
dc.b    “ SIXTH LINE (both bitplanes)” ; 6
dc.b    “ ” ; 7
dc.b    “ ” ; 8
dc.b    “FABIO CIUCCI INTERNATIONAL” ; 9
dc.b    “ ” ; 10
dc.b    “ 1 4 6 89 !@ $ ^& () +| =- ]{ ” ; 11
dc.b    “ ” ; 12
dc.b    “ LA A I G N T C OBLITERATION ” ; 15
dc.b    “ ” ; 25
dc.b    “ ” ; 16
dc.b    “ In the middle of the journey of our life ” ; 17
dc.b    “ ” ; 18
dc.b    “ I found myself in a dark forest ” ; 19
dc.b    “ ” ; 20
dc.b    “ THAT WAS THE RIGHT PATH ” ; 21
dc.b	“ ” ; 22
dc.b    “ AHI Quanto a DIR QUAL ERA... ” ; 23
dc.b    “ ” ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26
dc.b    “ ” ; 27

EVEN

; number of characters per line: 40
TEXT2:     ;         1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b    “ ” ; 1
dc.b    “ SECOND LINE (only in text2) ” ; 2
dc.b    “ /\ / ” ; 3
dc.b    “ / \/ ” ; 4
dc.b    “ ” ; 5
dc.b    “ SIXTH LINE (both bitplanes)” ; 6
dc.b    “ ” ; 7
dc.b    “ ” ; 8
dc.b    “FABIO COMMUNICATION INTERNATIONAL” ; 9
dc.b    “ ” ; 10
dc.b    “ 1234567 90 @#$%^&*( _+|\=-[]{} ” ; 11
dc.b    “ ” ; 12
dc.b    “ LA PALINGENETICA B I E A I N ” ; 15
dc.b    “ ” ; 25
dc.b    “ ” ; 16
dc.b    “ Nel del cammin di vita ” ; 17
dc.b    “ ” ; 18
dc.b    “ Mi pEr UnA oScuRa ” ; 19
dc.b    “ ” ; 20
dc.b    “ THAT THE WAY WAS LOST ” ; 21
dc.b    “ ” ; 22
dc.b    “ AHI How much to WHAT WAS... ” ; 23
dc.b    “ ” ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26
dc.b    “ ” ; 27

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
dc.w    $100,%0010001000000000    ; 2 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
BPLPOINTERS2:
dc.w $e4,$0000,$e6,$0000    ;second bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$19a    ; colour1 - TEXT first bitplane
dc.w    $0184,$f62	; colour2 - TEXT second bitplane
dc.w    $0186,$1e4    ; colour3 - TEXT first+second bitplane

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

FONT:
;    incbin    ‘metal.fnt’    ; Wide font
;    incbin    ‘normal.fnt’    ; Similar to kickstart 1.3 fonts
incbin    ‘nice.fnt’    ; Narrow font

SECTION    MIOPLANE,BSS_C    ; In CHIP

BITPLANE:
ds.b    40*256    ; a low-resolution bitplane 320x256
BITPLANE2:
ds.b    40*256    ; a low-resolution bitplane 320x256

end

To create 3-colour text (4 with the background), all we had to do was activate another
bitplane and print text2, modified so that some words were missing
to create different colours in the overlap. Even by making words ‘missing’
from the text of the first bitplane, the colour changes, as only the
second bitplane remains. To print both texts, the same print routine is used,
but with a small modification: the first two instructions, which retrieve the
addresses of the text to be printed and the destination bitplane, have been removed,
so that the routine can be used to print any text
previously loaded into a0 in the bitplane previously loaded into a3:


LEA	TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
bsr.w    print        ; Prints the lines of text on the screen

LEA    TEXT2(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE2,A3    ; Address of the destination bitplane in a3
bsr.w    print        ; Prints the lines of text on the screen

In this way, the print routine can be used to print any
text on any bitplane, and not always TEXT: in BITPLANE:!
The first ‘bsr.w print’ prints as in the previous listings, while the second bsr.w
prints TEXT2: in BITPLANE2:.
From the overlap of the two bitplanes, depending on whether the character is only in the
first bitplane, only in the second, or in both, one of the three colours is displayed (the fourth is the background)
dc.w    $0180,$000    ; color0 - BACKGROUND

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$19a    ; colour1 - FIRST BITPLANE TEXT (BLUE)
dc.w    $0184,$f62    ; colour2 - SECOND BITPLANE TEXT (ORANGE)
dc.w    $0186,$1e4    ; colour3 - TEXT first+second bitplane (GREEN)

To see the situation of the two biplanes more clearly, try moving the
second bitplane up by 5 pixels:

MOVE.L    #BITPLANE2+(40*5),d0

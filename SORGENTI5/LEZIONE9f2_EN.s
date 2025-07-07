
; Lesson 9f2.s    Writing characters with the blitter

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

;    Point to the ‘empty’ PIC
MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ	#2-1,D1        ; number of bitplanes (here there are 2)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0    ; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
bsr.w    Print        ; Prints the lines of text on the screen

LEA    TEXT2(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE2,A3    ; Address of the destination bitplane in a3
bsr.w    Print        ; Print the lines of text on the screen

mouse:
btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

rts


;***************************************************************************
;    Routine that prints 16x20 pixel wide characters
;
;    A0 = points to the map containing the characters to be printed
;    A3 = points to the bitplane on which to print
;***************************************************************************

;    ........................
;    : .______. :
;    : l_ _ ¬l xCz ¦
;    ¦ C©)(®) ·) |
;    | l¯C. T . |
;    | __¯¯¯¯) l ::. |
;    | (__¯¯¯¯__) ::::. |
;    ¦ __T¯¯T__ ::::::. |
;    `---/ `--“ \---------”
;     ¯¯¯¯¯¬¯¯¯¯

PRINT:
MOVEQ    #10-1,D3    ; NUMBER OF LINES TO PRINT: 10

PRINTRIGA:
MOVEQ    #20-1,D0    ; NUMBER OF COLUMNS PER LINE: 20

PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
SUB.B	#$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER, IN
; ORDER TO TRANSFORM, FOR EXAMPLE, THE
; SPACE (which is $20) into $00, the
; ASTERISK ($21) into $01...
ADD.L    D2,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 2,
; because each character is 16 pixels wide.
; This way we find the offset.
MOVE.L    D2,A2

ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

btst    #6,$02(a5)    ; wait for the blitter to finish
waitblit:
btst    #6,$02(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)    ; BLTCON0: copy from A to D
move.l    #$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later

move.l    a2,$50(a5)	; BLTAPT: font address (source A)
move.l    a3,$54(a5)    ; BLTDPT; bitplane address (destination D)
move    #120-2,$64(a5)    ; BLTAMOD: font module
move    #40-2,$66(a5)    ; BLTDMOD: bit plane module
move    #(20<<6)+1,$58(a5) ; BLTSIZE: 16 pixels, i.e. 1 word wide
; * 20 lines high. Note that to
; shift 20, the handy
; symbol <<, which shifts to the left.
; (20<<6) is equivalent to (20*64).

ADDQ.w    #2,A3        ; A3+2, move forward 16 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2	; PRINT D0 (20) CHARACTERS PER LINE

ADD.W    #40*19,A3    ; GO TO THE NEXT LINE
; move down 19 lines.

DBRA    D3,PRINTRIGA    ; PRINT D3 LINES
RTS



; Warning! Only these characters are available in the font:
;
; !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ

; number of characters per line: 20
TEXT:     ; 11111111112
;12345678901234567890
dc.b    “ FIRST LINE OF TEXT 1 ” ; 1
dc.b    “ ” ; 2
dc.b    “ / / ” ; 3
dc.b    “ / / ” ; 4
dc.b    “ ” ; 5
dc.b    “S S A R G ” ; 6
dc.b    “ ” ; 7
dc.b    “ ” ; 8
dc.b    “FABIO CIUCCI ” ; 9
dc.b    “ ” ; 10

EVEN


; number of characters per line: 20
TEXT2:     ; 11111111112
;12345678901234567890
dc.b    “ ” ; 1
dc.b    “SECOND LINE OF TEXT 2” ; 2
dc.b    “ / / ” ; 3
dc.b    “ / / ” ; 4
dc.b    “ ” ; 5
dc.b    “SESTA RIGA ” ; 6
dc.b    “ ” ; 7
dc.b    “ ” ; 8
dc.b    “F B O C U C ” ; 9
dc.b    “ AMIGA RULEZ ” ; 10

EVEN

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$2200    ; bplcon0 - 2 bitplane lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
BPLPOINTERS2:
dc.w $e4,0,$e6,0    ;second bitplane

dc.w    $180,$000    ; colour0 - BACKGROUND
dc.w    $182,$19a    ; colour1 - TEXT first bitplane
dc.w    $184,$f62    ; colour2 - TEXT second bitplane
dc.w    $186,$1e4    ; colour3 - TEXT first+second bitplane

dc.w	$FFFF,$FFFE	; Fine della copperlist


;****************************************************************************

; The 16x20 character FONT is stored here. IN CHIP RAM, because it is
; copied with the blitter, not with the processor!

FONT:
incbin    ‘assembler2:sorgenti6/font16x20.raw’

;****************************************************************************

SECTION    PLANEVUOTO,BSS_C

BITPLANE:
ds.b    40*256        ; bitplane reset lowres
BITPLANE2:
ds.b    40*256        ; bitplane reset lowres

end

;****************************************************************************

In this example, we use the blitter to print characters on the screen.
Ten lines of 20 characters each are printed.
The source is a font consisting of a single bitplane.
The destination screen, on the other hand, consists of 2 bitplanes: this way
we have 3 colours available for the characters (i.e. colours 1, 2 and 3,
because colour 0 is used for the background).
To print a character with colour 1, we copy it only to bitplane 1; to
print it with colour 2, we copy it only to bitplane 2; and to print it with
colour 3, we copy it to both bitplanes.
We did something similar in Lesson 6h.s using the 8x8 font.
Printing takes place one bitplane at a time. The text to be printed is contained
in two ASCII ‘maps’ (one per bitplane) labelled TEXT and TEXT2.
Each ‘map’ or ASCII page will be converted byte by byte in the offset from
to be added to the font address to know which character to print.
 
The work is done by the Print routine, which is called once for
each bitplane.
The routine consists of two nested loops (one inside the other).
The inner loop prints a line of characters from left to right.
The outer loop repeats the inner loop 10 times, thus printing 10
lines in total.
Let's now examine in detail how the blitting takes place.
Let's use a 60-character 16*20 font.
The font is contained in an ‘invisible’ bitplane (because we do not make
the BPLxPT point to it) 960 pixels wide and 20 lines high, in which
all 60 characters side by side (in fact, 60*16=960) in
this order (ASCII):

!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ

The Font16x20.iff file is present, which is the original font image.
Please note that the characters after the sixtieth are missing:

[\]^_`abcdefghijklmnopqrstuvwxyz{|}~

If you want lowercase letters and other symbols, create your own font and a
routine that can read it. Make your own ‘standard’.
Since the fonts are 1 word wide (16 pixels) and 20 lines high, this will be the
size of the bitmap. The modules are calculated using the usual formula.
The source bitplane is 60 words wide (i.e. 960 pixels, i.e. 120 bytes)
and therefore the source module is 2*(60-1)=120-2=118.
The destination bitplane is 20 words wide (i.e. 320 pixels, i.e. 40 bytes)
and therefore the source module is worth 2*(20-1)=40-2=38.
Let's see how the pointers are managed. The pointer to the destination varies
with each blit to draw the character in a different position on the
screen, proceeding from left to right and from top to bottom.
The mechanism is the same as we saw in the example in lesson9c2.s.
The pointer to the source, on the other hand, must always point to the character to be
printed. The source bitplane data is organised as follows:

ADDRESS	CONTENT
FONT        first line (16 pixels, therefore 1 word) of the character “ ”
FONT+2         first line of the character “!”
FONT+4     first line of the character “"”

.
.
.
FONT+120     first row of the character “Z”
FONT+122     second row of the character “ ”
FONT+124     second row of the character “!”
.
.
.

FONT+2282     last row of the character “ ”
FONT+2284     last row of the character “!”
.
FONT+2398     last line of the character “Z”


The routine reads the ASCII code of the character to be printed from the map
and calculates the address from it. The method is very similar to the one we saw
in lesson 6 when we did the same thing with the processor.
From the ASCII code, we can obtain the distance of the character from the beginning of the
font. To do this, we first subtract 32 (i.e. the ASCII code for space) from the ASCII code of the character we are going to print, because the first character of the font
is space. At this point, we proceed differently from the method used in lesson
6. In fact, the font in lesson 6 was drawn “vertically”, i.e.:


!
"
#

etc.

>
?
@
A
B
C
D
E
F
G

etc.

In that case, to calculate the address, we had to multiply the ASCII code
(minus 32) by the amount of memory occupied by a character.
In this case, however, the font is drawn “horizontally”, since we
are interested in the address of the first word of the character to be drawn, we will have to
multiply the ASCII code (minus 32) by the amount of memory occupied
by the FIRST LINE of each character, since the first line of the character
we are interested in is stored AFTER the first line of the characters that
precede it but BEFORE all the other lines (unlike in lesson
6, where all the lines of a character were stored before the
next character). Since a line occupies 2 bytes (1 word = 16 pixels)
we have to multiply by 2, which we can do with a simple ADD,
saving us a slow MULU.

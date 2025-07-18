
; Lesson 6c2b.s    LET'S PRINT SEVERAL LINES OF TEXT ON THE SCREEN!!!
;        - with EASILY EDITABLE binary font!!

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

MOVE.L	#BITPLANE,d0    ; put the PIC address in d0,
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address

move.l    #COPPERLIST,$dff080    ; Point our COP
move.w    d0,$dff088		; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

bsr.w    print        ; Print the lines of text on the screen

mouse:
btst    #6,$bfe001	; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)	; Closelibrary - close the graphics library
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
LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
MOVEQ    #25-1,D3    ; NUMBER OF LINES TO BE PRINTED: 25
PRINTRIGA:
MOVEQ    #40-1,D0    ; NUMBER OF COLUMNS PER LINE: 40
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
MULU.W	#8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2	; FIND THE DESIRED CHARACTER IN THE FONT...

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B	(A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

ADDQ.w    #1,A3        ; A1+1, advance 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (40) CHARACTERS PER LINE

ADD.W    #40*7,A3    ; START NEW LINE

DBRA    D3,PRINTRIGA	; MAKE D3 LINES

RTS

;            CHARACTERS AVAILABLE IN THE FONT:
;
;     !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ
;
;        CHARACTERS NOT IN THE FONT, DO NOT USE:
;
;     [\]^_`abcdefghijklmnopqrstuvwxyz{|}~
;
;
; NOTE: the character ‘@’ prints a smiley face... why not?

; number of characters per line: 40
TEXT:                             ;40 characters
dc.b    ‘ ’ ; 1
dc.b    ‘ ’ ; 2
dc.b    ‘ ’ ; 3
dc.b    ‘ ’ ; 4
dc.b    ‘ ’ ; 5
dc.b    ‘ ’ ; 6
dc.b    ‘ ’ ; 7
dc.b    ‘ ’ ; 8
dc.b	‘ ’ ; 9
dc.b    ‘ ’ ; 10
dc.b    ‘ ’ ; 11
dc.b    ‘ ’ ; 12
dc.b    ‘ ’ ; 15
dc.b    ‘ ’ ; 25
dc.b    ‘ ’ ; 16
dc.b    ‘ ’ ; 17
dc.b    ‘ ’ ; 18
dc.b	‘ ’ ; 19
dc.b    ‘ ’ ; 20
dc.b    ‘ ’ ; 21
dc.b    ‘ ’ ; 22
dc.b    ‘ ’ ; 23
dc.b    ‘ ’ ; 24
dc.b    ‘ ’ ; 25
dc.b	‘ ’ ; 26
dc.b    ‘ ’ ; 27

EVEN

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w	$94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$345    ; colour0 - BACKGROUND
dc.w    $0182,$bdf    ; colour1 - TEXT

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

;    characters: !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ
;    ATTENTION! The following characters are not available: [\]^_`abcdefghijklmnopqrstuvwxyz{|}~

; TIP: To scroll down, use the down cursor + SHIFT and do one
; page at a time!!!

FONT:
; “ ”
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “!”
dc.b    %00011000
dc.b    %00011000
dc.b    %00011000
dc.b    %00011000
dc.b    %00011000
dc.b    %00000000
dc.b    %00011000
dc.b    %00000000
; '
dc.b    %00011011
dc.b    %00011011
dc.b    %00011011
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “#”
dc.b    %00010100
dc.b    %00010100
dc.b    %00010100
dc.b    %01111111
dc.b    %00010100
dc.b    %00010100
dc.b    %00010100
dc.b    %00000000
; “$”
dc.b    %00001000
dc.b    %00011110
dc.b    %00100000
dc.b    %00011100
dc.b    %00000010
dc.b    %00111100
dc.b    %00001000
dc.b    %00000000
; “%”
dc.b    %00000001
dc.b    %00110011
dc.b    %00110110
dc.b    %00001100
dc.b    %00011000
dc.b    %00110110
dc.b    %01100110
dc.b    %00000000
; “&”
dc.b    %00011000
dc.b    %00100100
dc.b    %00011000
dc.b    %00011001
dc.b    %00100110
dc.b    %00111110
dc.b    %00011001
dc.b    %00000000
; ‘'’
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %000000
; ‘(’
dc.b    %00001100
dc.b    %0001100
dc.b    %001100
dc.b    %001100
dc.b    %00110000
dc.b    %00011000
dc.b    %00001100
dc.b    %00000000
; ‘)’
dc.b    %00110000
dc.b    %00011000
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00011000
dc.b    %00110000
dc.b    %00000000
; ‘*’
dc.b    %01100011
dc.b    %00110110
dc.b    %00011100
dc.b    %01111111
dc.b    %00011100
dc.b    %00110110
dc.b    %01100011
dc.b    %00000000
; “+”
dc.b    %00000000
dc.b    %00011000
dc.b    %00011000
dc.b    %01111110
dc.b    %00011000
dc.b    %00011000
dc.b	%00000000
dc.b	%00000000
; ‘,’
dc.b	%00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00011000
dc.b    %00011000
dc.b    %00110000
dc.b    %00000000
; ‘-’
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %01111110
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; ‘.’
dc.b
dc.b
dc.b
dc.b
dc.b
dc.b    %00011000
dc.b    %00011000
dc.b    %00000000
; ‘/’
dc.b    %00000001
dc.b    %00000011
dc.b    %00000110
dc.b	%00001100
dc.b	%00011000
dc.b	%00110000
dc.b	%01100000
dc.b	%00000000
; “0”
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %00000000
dc.b    %01100011
dc.b    %01100011
dc.b	%01111111
dc.b    %00000000
; “1”
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000000
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000000
; “2”
dc.b    %01111111
dc.b    %00000000
dc.b    %00000011
dc.b    %01111111
dc.b    %01100000
dc.b    %01100000
dc.b    %01111111
dc.b    %00000000
; “3”
dc.b    %01111111
dc.b    %00000000
dc.b    %00000011
dc.b    %00011111
dc.b    %00000011
dc.b    %00000011
dc.b    %01111111
dc.b    %00000000
; “4”
dc.b    %01100011
dc.b    %01100011
dc.b    %01100000
dc.b    %01111111
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000000
; “5”
dc.b    %01111111
dc.b    %00000000
dc.b    %01100000
dc.b	%01111111
dc.b    %00000011
dc.b    %00000011
dc.b    %01111111
dc.b    %00000000
; “6”
dc.b    %01111111
dc.b    %00000000
dc.b    %01100000
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %01111111
dc.b    %00000000
; “7”
dc.b    %01111111
dc.b    %00000000
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000000
; “8”
dc.b    %01111111
dc.b    %00000011
dc.b    %01100011
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %01111111
dc.b    %00000000
; “9”
dc.b    %01111111
dc.b    %00000011
dc.b    %01100011
dc.b    %01111111
dc.b    %00000011
dc.b	%00000011
dc.b	%01111111
dc.b    %00000000
; “:”
dc.b    %00000000
dc.b    %00001100
dc.b    %00001100
dc.b    %00000000
dc.b    %00000000
dc.b	%00001100
dc.b    %00001100
dc.b    %00000000
; “;”
dc.b    %00000000
dc.b    %00001100
dc.b    %00001100
dc.b    %00000000
dc.b    %00001100
dc.b    %00001100
dc.b    %00011000
dc.b    %00000000
; ‘<’
dc.b    %00000110
dc.b    %00001100
dc.b    %00011000
dc.b    %00110000
dc.b    %00011000
dc.b    %00001100
dc.b    %00000110
dc.b    %00000000
; ‘=’
dc.b	%00000000
dc.b	%00000000
dc.b	%01111110
dc.b	%00000000
dc.b	%01111110
dc.b	%00000000
dc.b	%00000000
dc.b	%00000000
; ‘>’
dc.b    %00011000
dc.b    %00001100
dc.b    %00000110
dc.b    %00000011
dc.b    %00000110
dc.b    %00001100
dc.b    %00110000
dc.b    %00000000
; “?”
dc.b    %01111111
dc.b	%00000000
dc.b    %00000011
dc.b    %00001111
dc.b    %00001100
dc.b    %00000000
dc.b    %00001100
dc.b    %00000000
; ‘@’
dc.b    %00000000    ; smile
dc.b    %11100111
dc.b    %11100111
dc.b    %00000000
dc.b    %00010000
dc.b    %00011000
dc.b	%10000001
dc.b    %01111110
; ‘A’
dc.b    %00111110
dc.b    %00111110
dc.b    %01111111
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %01111111
dc.b    %01111111
; ‘B’
dc.b    %01111110
dc.b    %01111110
dc.b    %01111111
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %01111110
dc.b    %01111110
; “C”
dc.b    %00111111
dc.b    %00111111
dc.b    %01111111
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
; “D”
dc.b    %01111110
dc.b    %01111110
dc.b    %01111111
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
; “E”
dc.b    %01111111
dc.b	%01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %01100000
dc.b    %01100000
dc.b    %01111000
dc.b    %01111000
; “F”
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %01100000
dc.b    %01100000
dc.b    %01111000
dc.b    %01111000
; “G”
dc.b    %01111110
dc.b    %01111110
dc.b    %01111111
dc.b    %01111111
dc.b    %01100000
dc.b    %01100000
dc.b    %01101111
dc.b    %01101111
; “H”
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
; “I”
dc.b    %00111111
dc.b    %00111111
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
; “J”
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
dc.b    %00000011
; “K”
dc.b	%01100011
dc.b	%01100011
dc.b	%01100111
dc.b	%01100111
dc.b    %01101110
dc.b    %01101110
dc.b    %01111100
dc.b    %01111100
; “L”
dc.b    %01100000
dc.b	%01100000
dc.b	%01100000
dc.b	%01100000
dc.b	%01100000
dc.b	%01100000
dc.b    %01100000
dc.b    %01100000
; “M”
dc.b    %01100011
dc.b    %01100011
dc.b    %01110111
dc.b    %01110111
dc.b    %01110111
dc.b    %01111111
dc.b    %01101011
dc.b    %00001000
; “N”
dc.b    %01100011
dc.b    %01100011
dc.b    %01110011
dc.b    %01110011
dc.b    %01111011
dc.b    %01111011
dc.b	%01101111
dc.b	%01101111
; “O”
dc.b    %00111110
dc.b    %00111110
dc.b    %01111111
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
; “P”
dc.b    %01111110
dc.b    %01111110
dc.b    %01111111
dc.b    %01111111
dc.b	%01100011
dc.b	%01100011
dc.b	%01111111
dc.b	%01111111
; “Q”
dc.b    %00111110
dc.b    %00111110
dc.b    %01111111
dc.b    %01111111
dc.b    %01100011
dc.b    %01100011
dc.b    %01101011
dc.b    %01101011
; “R”
dc.b    %01111110
dc.b    %01111110
dc.b	%01111111
dc.b	%01111111
dc.b	%01100011
dc.b	%01100011
dc.b	%01111111
dc.b	%01111111
; “S”
dc.b	%00111111
dc.b	%00111111
dc.b	%01111111
dc.b	%01111111
dc.b    %01100000
dc.b    %01100000
dc.b    %00111110
dc.b    %00111110
; “T”
dc.b    %00111111
dc.b    %00111111
dc.b    %00111111
dc.b    %00111111
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
; “U”
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
; “V”
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01110111
dc.b    %01110111
; “W”
dc.b    %01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b    %01100011
dc.b    %01101011
dc.b    %01101011
; “X”
dc.b    %01100011
dc.b    %01100011
dc.b    %01110111
dc.b	%01110111
dc.b    %00111110
dc.b    %00111110
dc.b    %00011100
dc.b    %00011100
; “Y”
dc.b    %01100011
dc.b    %01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%00110111
dc.b	%00110111
dc.b	%00111110
dc.b	%00111110
; “Z”
dc.b    %01111111    ;58
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %00001110
dc.b    %00001110
dc.b    %00011100
dc.b    %00011100
; “ ”
dc.b    %00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “ ”
dc.b    %00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “ ”
dc.b    %00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b	%00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “ ”
dc.b    %00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “ ”
dc.b	%00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “ ”
dc.b    %00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “a”
dc.b    %01111111    ;65
dc.b	%01111111
dc.b	%01111111
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b    %00000000
; “b”
dc.b    %01111111    ;66
dc.b	%01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01111111
dc.b    %01111111
dc.b    %01111110
dc.b    %01111110
; “c”
dc.b    %01100000    ;67
dc.b    %01100000
dc.b    %01100000
dc.b    %01111111
dc.b    %01111111
dc.b    %00111111
dc.b    %00111111
dc.b    %00000000
; “d”
dc.b    %01100011    ;68
dc.b    %01100011
dc.b    %01100011
dc.b    %01111111
dc.b	%01111111
dc.b	%01111110
dc.b	%01111110
dc.b	%00000000
; “e”
dc.b	%01111000	;69
dc.b	%01100000
dc.b    %01100000
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %00000000
; “f”
dc.b    %01111000    ;70
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %00000000
; “g”
dc.b    %01101111	;71
dc.b	%01100011
dc.b	%01100011
dc.b	%01111111
dc.b	%01111111
dc.b	%00111110
dc.b	%00111110
dc.b	%00000000
; “h”
dc.b	%01111111	;72
dc.b	%01111111
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%00000000
; “i”
dc.b	%00001100	;73
dc.b	%00001100
dc.b	%00001100
dc.b	%00001100
dc.b	%00001100
dc.b	%00111111
dc.b	%00111111
dc.b	%00000000
; “j”
dc.b	%00000011	;74
dc.b    %00000011
dc.b    %00000011
dc.b    %00110011
dc.b    %00110011
dc.b    %00011110
dc.b    %00011110
dc.b    %00000000
; “k”
dc.b    %01111100    ;75
dc.b    %01111100
dc.b    %01111100
dc.b    %01101110
dc.b    %01101110
dc.b    %01100111
dc.b    %01100111
dc.b    %00000000
; “l”
dc.b    %01100000    ;76
dc.b	%01100000
dc.b	%01100000
dc.b	%01111111
dc.b	%01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %00000000
; “m”
dc.b    %01101011    ;77
dc.b    %01101011
dc.b    %01101011
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b	%01100011
dc.b    %00000000
; “n”
dc.b    %01101111    ;78
dc.b    %01100111
dc.b    %01100111
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %00000000
; “o”
dc.b    %01100011    ;79
dc.b	%01100011
dc.b    %01100011
dc.b    %01111111
dc.b    %01111111
dc.b    %00111110
dc.b    %00111110
dc.b    %00000000
; “p”
dc.b    %01111110    ;80
dc.b    %01111110
dc.b    %01111110
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %01100000
dc.b    %00000000
; “q”
dc.b    %01101011    ;81
dc.b    %01100111
dc.b    %01100111
dc.b    %01111111
dc.b    %01111111
dc.b    %00111110
dc.b    %00111110
dc.b    %00000000
; “r”
dc.b    %01111110    ;82
dc.b    %01111110
dc.b    %01111110
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %01100011
dc.b    %00000000
; “s”
dc.b    %00011110    ;83
dc.b    %00000011
dc.b    %00000011
dc.b    %01111111
dc.b    %01111111
dc.b    %01111110
dc.b    %01111110
dc.b    %00000000
; “t”
dc.b    %00001100    ;84
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00001100
dc.b    %00000000
; “u”
dc.b    %01100011    ;85
dc.b	%01100011
dc.b	%01100011
dc.b	%01111111
dc.b	%01111111
dc.b	%00111111
dc.b	%00111110
dc.b    %00000000
; “v”
dc.b    %01111111    ;86
dc.b    %00111110
dc.b    %00111110
dc.b    %00011100
dc.b    %00011100
dc.b    %00001000
dc.b    %00001000
dc.b    %00000000
; “w”
dc.b    %01111111    ;87
dc.b    %01101011
dc.b    %01101011
dc.b    %01111111
dc.b    %01111111
dc.b    %00111110
dc.b    %00111110
dc.b    %00000000
; “x”
dc.b    %00011100	;88
dc.b	%00111110
dc.b	%00111110
dc.b	%01110111
dc.b	%01110111
dc.b	%01100011
dc.b	%01100011
dc.b	%00000000
; “y”
dc.b	%00011100	;89
dc.b	%00011100
dc.b	%00011100
dc.b	%01111000
dc.b	%01111000
dc.b    %01110000
dc.b    %01110000
dc.b    %00000000
; “z”
dc.b    %00111000    ;90
dc.b    %00111000
dc.b    %00111000
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %01111111
dc.b    %00000000
; “ ”
dc.b    %00000000    ;91
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; '
dc.b    %00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
; “ ”
dc.b    %00000000    ;
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000
dc.b    %00000000






;
; lowercase characters are missing... if you have the patience to draw them, go ahead
! Or you can draw little pictures to put together...
;

SECTION	MIOPLANE,BSS_C    ; The BSS SECTIONS must be made up of
; only ZEROS!!! Use DS.b to define
; how many zeros the section contains.

BITPLANE:
ds.b    40*256    ; a lowres 320x256 bitplane

end

This listing is the same as Lesson6c.s, but the font is ‘HANDMADE’, in fact
instead of loading it, it is in the listing in the form of dc.b in binary

;12345678
; ‘A’
dc.b    %01111111    ;1
dc.b	%00000011    ;2
dc.b    %01100011    ;3
dc.b    %01111111    ;4
dc.b    %01100011    ;5
dc.b    %01100011    ;6
dc.b    %01100011	;7
dc.b    %00000000    ;8

This, for example, is the letter ‘A’. Be careful not to use lowercase characters in the
text, because they are not in the font, as whoever created it must have got tired
of the capital letter ‘Z’. In reality, there weren't even many symbols
such as ‘*;<>=’ and I added them myself. Now it will also be clearer how
the font is made! And you will guess that to make a 16x16 font you have to do this:


;1234567890123456
; ‘A’
dc.w	%0000111111111100	;1
dc.w	%0011111111111111	;2
dc.w    %0011110000001111
dc.w    %0011110000001111
dc.w    %0011110000001111
dc.w	%0011110000001111	;6
dc.w	%0011111111111111	;7
dc.w	%0011111111111111	;8
dc.w	%0011110000001111	;9
dc.w	%0011110000001111	;10
dc.w	%0011110000001111	;11
dc.w	%0011110000001111    ;12
dc.w    %0011110000001111    ;13
dc.w    %0011110000001111    ;14
dc.w    %0000000000000000    ;15
dc.w    %0000000000000000    ;16

But it's better to draw it and convert it to RAW!

In this listing, I recommend changing the FONT, adding drawings and
strange symbols. You could make your own personal FONT!

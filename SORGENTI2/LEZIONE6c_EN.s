
; Lesson 6c.s    LET'S PRINT SEVERAL LINES OF TEXT ON THE SCREEN!!!

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea	GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0    ; put the PIC address in d0,
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
move.w    d0,6(a1)	; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address

move.l    #COPPERLIST,$dff080    ; Let's point our COP
move.w    d0,$dff088        ; Let's start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

bsr.w    print        ; Print the lines of text on the screen

mouse:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system COP
move.w    d0,$dff088        ; start the old COP

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
LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
MOVEQ    #23-1,D3    ; NUMBER OF LINES TO PRINT: 23
PRINTRIGA:
MOVEQ    #40-1,D0    ; NUMBER OF COLUMNS PER LINE: 40
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B	(A0)+,D2    ; Next character in d2
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), in $01...
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 " ‘
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ’ ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ ‘
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ’ ‘
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ’ ‘
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ’ ‘
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ’ "

ADDQ.w    #1,A3        ; A1+1, move forward 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (40) CHARACTERS PER LINE

ADD.W    #40*7,A3    ; GO TO THE NEXT LINE

DBRA    D3,PRINTRIGA    ; MAKE D3 LINES

RTS


; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b    “ FIRST LINE ” ; 1
dc.b    “ SECOND LINE ” ; 2
dc.b    ' /\ / “ ; 3
dc.b    ” / \/ “ ; 4
dc.b    ” ' ; 5
dc.b    “ SIXTH LINE ” ; 6
dc.b    “ ” ; 7
dc.b    “ ” ; 8
dc.b    “FABIO CIUCCI COMMUNICATION INTERNATIONAL” ; 9
dc.b    “ ” ; 10
dc.b    “ 1234567890 !@#$%^&*()_+|\=-[]{} ” ; 11
dc.b    “ ” ; 12
dc.b    “ THE PALINGENETIC OBLITERATION ” ; 15
dc.b    “ ” ; 25
dc.b    “ ” ; 16
dc.b    “ In the middle of the journey of our life ” ; 17
dc.b    “ ” ; 18
dc.b    “ I found myself in a dark forest ” ; 19
dc.b    “ ” ; 20
dc.b    “ WHO HAD LOST THE RIGHT PATH ” ; 21
dc.b    “ ” ; 22
dc.b    “ AHI Quanto a DIR QUAL ERA... ” ; 23
dc.b    “ ” ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26
dc.b    “ ” ; 27

EVEN



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

dc.w $6c07,$fffe Shading on text line 9
dc.w    $182,$451    ; line 1 of the character
dc.w    $6d07,$fffe
dc.w    $182,$671    ; line 2
dc.w    $6e07,$fffe
dc.w    $182,$891    ; line 3
dc.w    $6f07,$fffe
dc.w    $182,$ab1    ; line 4
dc.w    $7007,$fffe
dc.w    $182,$781    ; line 5
dc.w    $7107,$fffe
dc.w    $182,$561    ; line 6
dc.w    $7207,$fffe
dc.w    $182,$451    ; line 7, the last one because 8 is reset
;     to create spacing between lines

dc.w    $7307,$fffe
dc.w    $182,$19a    ; normal colour

dc.w    $8c07,$fffe    ; Shading on text line 11
dc.w    $182,$516    ; line 1 of the character
dc.w    $8d07,$fffe
dc.w    $182,$739    ; line 2
dc.w    $8e07,$fffe
dc.w    $182,$95b    ; line 3
dc.w    $8f07,$fffe
dc.w    $182,$c6f    ; line 4
dc.w    $9007,$fffe
dc.w    $182,$84a    ; line 5
dc.w    $9107,$fffe
dc.w    $182,$739    ; line 6
dc.w    $9207,$fffe
dc.w    $182,$517	; line 7, the last one because line 8 is reset


dc.w    $9307,$fffe
dc.w    $182,$19a    ; normal colour

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

FONT:
incbin    ‘metal.fnt’    ; Wide font
;    incbin    ‘normal.fnt’    ; Similar to kickstart 1.3 fonts
;    incbin    ‘nice.fnt’    ; Narrow font

SECTION    MIOPLANE,BSS_C    ; The BSS SECTIONS must consist of
; only ZEROS!!! DS.b is used to define
; how many zeros the section contains.

BITPLANE:
ds.b    40*256    ; a low-resolution 320x256 bitplane

end


As you may have noticed, the fact that the font is single-colour does not prevent you from
changing the colour of each line with copper WAIT commands!
To write many lines one below the other, all you need to do is ‘GO TO THE NEXT LINE’ and
print the following line, for a number of times specified in D3

ADD.W    #40*7,A3    ; GO TO THE NEXT LINE
DBRA    D3,PRINTRIGA    ; DO D3 LINES

NOTE: to go to the next line, you need to go down 7 lines. By LINE, I mean TEXT LINE,
 8 pixels high, by line I mean the actual VIDEO LINE.

That's why you need an ‘ADD.W #40*7,A3’ to go to the next line:

The problem may arise from the impression that you are already at the address in
a3 on the last line of the character just printed, so you would think
that you just need to move forward by 1 to get to the next text line, but
in reality, A3 always contains only the address of the first line of characters
in fact, the other 7 lines are printed using OFFSET:

MOVE.B    (A2)+,(A3)    ; prints LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; prints LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; prints LINE 3 ‘ ’
MOVE.B    (A2)+,40*3(A3)    ; prints LINE 4 ‘ ’
MOVE.B    (A2)+,40*4(A3)    ; prints LINE 5 ‘ ’
MOVE.B    (A2)+,40*5(A3)    ; prints LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)    ; prints LINE 7 ‘ ’
MOVE.B	(A2)+,40*7(A3)    ; print LINE 8 ‘ ’

But register A3 always points to the first line. In fact, every time a character is
printed, it advances to the next character by adding 8 bits,
i.e. 1 byte, to the address in A3, which then points to the first line of the
next character:

ADDQ.w	#1,A3        ; A1+1, we advance by 8 bits (NEXT CHARACTER)

At this point, to print that ‘next character’, simply re-execute the
routine with the addressing distances (OFFSET).
Let's see what happens when we have printed the last character on the
right, i.e. the last one in a line: in A3 we have the address of the first line
of the last character in question, after the instructions that print by
the offset from A3, there is the instruction that triggers A3 to the next 8 bits, in
this case triggering the start of the second line. This is why, to
take A3 to the first line of the next line, you only need to go down 7 lines and
not 8, because we were already at the start of the second line.


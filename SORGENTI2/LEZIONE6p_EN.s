
; Lesson 6p.s    PRINT THE SCREEN ONE CHARACTER PER FRAME

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

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.s    PrintCharacter    ; Print one character at a time

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; Mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

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


;    This routine is a kind of hybrid between the normal PRINT routine
;    and the TABLE routine. In fact, we use TEXT in a similar way
;    to a table, taking a value only every FRAME
;    and printing it.
 On the other hand, we also need to save the address in the bitplane of the last position reached in the print, in order to print the
;    character following the previous one. To maintain the address of the character in the text and the point in the bitplane
;    where we have arrived between one frame and another, two longword POINTERS are used:
;
;
; TextPointer:
;    dc.l    TEXT
;
; BitplanePointer:
;    dc.l    BITPLANE
;
;    Each time the routine is executed, a single character is printed
;    and both the TEXT pointer is updated with an
;	ADDQ.L #1 which moves it to the next character (since a character is
;    one byte long), and the BITPLANE pointer, since each character
;    has its own place in the bitplane.
;    The first problem is that every 40 characters you have to ‘GO TO THE NEXT LINE’,
;    i.e. add 40*7 to the BITPLANE pointer. To solve this
;    it was enough to add a ZERO at the end of each line of text and
;    instructions that check if the byte to be printed is zero: if
;    it is zero, then it means that we are at the end of the line,
;    so 40*7 is added to the bitplane pointer and 1 to the text pointer
;    to skip the zero and point to the first character of the next line.
;    The second problem is that once the end of the text is reached
;    you have to stop printing characters. By convention, ending
;    the line with $FF instead of $00 indicates the end of the text. Just
;    check if the byte to be read is $FF and exit without printing and
;    without advancing the PUNTATESTO pointer, so that every time
;    PRINTcarattere is executed after printing the entire text, we exit
;    without performing any operations, as the character is always $FF.
;    NOTE: you can ‘invent’ various ‘special’ numbers to insert into the
;    text for various functions, as long as they are not numbers between $20
;    and $80, i.e. between the bytes dedicated to characters.

PRINTcharacter:
MOVE.L	PuntaTESTO(PC),A0 ; Address of the text to be printed in a0
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
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 " ‘
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ’ ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ ‘
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ’ ‘
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ’ ‘
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ’ ‘
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ’ "

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
RTS


TextPointer:
dc.l    TEXT

BitplanePointer:
dc.l    BITPLANE

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:     ;		 111111111122222222223333333334
dc.b    “ FIRST LINE ”,0 ; 1
dc.b    “ SECOND LINE ”,0 ; 2
dc.b    “ /\ / ”,0 ; 3
dc.b    “ / \/ ”,0 ; 4
dc.b    “ ”,0 ; 5
dc.b    “ SIXTH LINE ”,0 ; 6
dc.b    “ ”,0 ; 7
dc.b    “ ”,0 ; 8
dc.b    “FABIO CIUCCI COMMUNICATION INTERNATIONAL”,0 ; 9
dc.b    “ ”,0 ; 10
dc.b    “ 1234567890 !@#$%^&*()_+|\=-[]{} ”,0 ; 11
dc.b    “ ”,0 ; 12
dc.b    “ THE PALINGENETIC OBLITERATION ”,0 ; 15
dc.b    “ ”,0 ; 16
dc.b    “ ”,0 ; 17
dc.b    “ In the middle of the journey of our life ”,0 ; 18
dc.b    “ ”,0 ; 19
dc.b    “ I found myself in a dark forest ”,0 ; 20
dc.b    “ ”,0 ; 21
dc.b    “ THAT THE RIGHT PATH WAS LOST ”,0 ; 22
dc.b    “ ”,0 ; 23
dc.b    “ AHI How to tell which was... ”,$FF ; 24 END


EVEN



SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1	; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$19a    ; colour1 - TEXT

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

FONT:
incbin    ‘metal.fnt’
;    incbin    ‘normal.fnt’
;    incbin    ‘nice.fnt’


SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    40*256    ; a lowres bitplane 320x256

end

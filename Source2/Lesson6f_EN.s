
; Lesson 6f.s        WRITING ‘ABOVE’ A FIGURE

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1	; Address of the name of the library to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;    Point the bitplanes in the copperlist - first the PIC

MOVE.L    #PIC,d0        ; put the PIC address in d0, in
; this case we point 50
; lines further so as to make the image ‘GO UP’.
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1		; go to the next bplpointers in COP
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=number of bitplanes)

;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0    ; put the PIC address in d0,
LEA	BPLPOINTERS2,A1 ; pointers in COPPERLIST (plane 4!)
move.w d0,6(a1) ; copy the LOWER word of the plane address
swap d0 ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w	#$c00,$dff106        ; Disable AGA

bsr.w    print        ; Print the lines of text on the screen
; in HIRES
mouse:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:

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

;    Routine that prints 8x8 pixel characters (on LOWRES screen)

PRINT:
LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
MOVEQ    #23-1,D3    ; NUMBER OF LINES TO BE PRINTED: 23
PRINTRIGA:
MOVEQ    #40-1,D0    ; NUMBER OF COLUMNS PER LINE: 40 (lores)
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 " ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ ‘
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ’ ‘
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ’ "
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

ADDQ.w    #1,A3        ; A1+1, advance 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (40) CHARACTERS PER LINE

ADD.W    #40*7,A3    ; GO TO THE NEXT LINE

DBRA    D3,PRINTRIGA    ; MAKE D3 LINES

RTS


; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b    “ ” ; 1
dc.b    “ SECOND LINE ” ; 2
dc.b    “ /\ / ” ; 3
dc.b    “ / \/ ” ; 4
dc.b    “ ” ; 5
dc.b    “ SIXTH LINE ” ; 6
dc.b    “ ” ; 7
dc.b    “ ” ; 8
dc.b    “FABIO CIUCCI COMMUNICATION INTERNATIONAL” ; 9
dc.b    “ ” ; 10
dc.b    “ 1234567890 !@#$%^&*()_+|\=-[]{} ” ; 11
dc.b    “ ” ; 12
dc.b    “ -=- THE PALINGENETIC OBLITERATION -=- ” ; 13
dc.b    ‘ ## OF THE TRANSCENDENTAL SELF THAT IS ## ’ ; 14
dc.b    “ /// IMMEDIATE AND FUTURE \\\ ” ; 15
dc.b    “ In the middle of the journey of our life ” ; 16
dc.b    “ ” ; 17
dc.b    “ I found myself in a dark forest ” ; 18
dc.b    “ ” ; 19
dc.b    “ WHO HAD LOST THE RIGHT PATH ” ; 20
dc.b    “ ” ; 21
dc.b    “ AHI How to tell where it was... ” ; 22
dc.b    “ ” ; 23
dc.b    “ ” ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26

EVEN



SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8e,$2c81	; DiwStrt	(registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0100001000000000    ; bit 14 - 4 bitplanes, 16 colours

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000	;third bitplane
BPLPOINTERS2:
dc.w $ec,$0000,$ee,$0000    ;fourth bitplane

dc.w    $180,$000    ; colour0 ; colours of the figure slightly attenuated
dc.w    $182,$354    ; colour1
dc.w    $184,$678    ; colour2
dc.w    $186,$567    ; colour3
dc.w    $188,$455    ; colour4
dc.w    $18a,$121    ; colour5
dc.w    $18c,$455    ; colour6
dc.w    $18e,$233    ; colour7

dc.w    $190,$d6e    ; colour8    ; The colours of the text:
dc.w    $192,$d6e    ; colour9	
; in fact, all the various
dc.w    $194,$d6e    ; color10    ; overlaps would form
dc.w    $196,$d6e    ; color11    ; another 8 colours, which we
dc.w    $198,$d6e    ; color12	; we define all as equal
dc.w    $19a,$d6e    ; colour13
dc.w    $19c,$d6e    ; colour14
dc.w    $19e,$d6e    ; colour15

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

FONT:
incbin    ‘metal.fnt’    ; Wide font
;    incbin    ‘normal.fnt’    ; Similar to kickstart 1.3 fonts
;    incbin    ‘nice.fnt’    ; Narrow font

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,

SECTION    MIOPLANE,BSS_C    ; in CHIP

BITPLANE:
ds.b    40*256    ; a 320x256 lores bitplane

end

In this example, we have added bitplane 4, on which the text is written.
With the fourth bitplane, we go from 8 colours to 16, so to keep
the text the same colour in any situation where it overlaps with
the other 3 bitplanes, all eight ‘new’ colours must be the same as
the text colour.
If, on the other hand, the new 8 colours are similar to the first eight, but lighter, you can
achieve a ‘TRANSPARENCY’ effect. In fact, every time the text plane
overlaps the other 3, it displays a colour for each pixel of the characters
similar to that of the figure but, precisely, lighter, and the illusion of
‘TRANSPARENCY’ occurs automatically.
Try replacing the palette of the last colours with this one:

dc.w    $190,$454    ; color8    ; The colours of the text:
dc.w    $192,$7a8    ; color9	; in this case we form
dc.w    $194,$eef    ; color10    ; 8 different colours for the
dc.w    $196,$cde    ; color11    ; 8 possibilities for
dc.w    $198,$aab    ; color12	; overlay - if you notice
dc.w    $19a,$786    ; colour13    ; they are similar to the first 8,
dc.w    $19c,$9aa    ; colour14    ; but much brighter
dc.w    $19e,$789    ; colour15    ; to create ‘TRANSPARENCY’

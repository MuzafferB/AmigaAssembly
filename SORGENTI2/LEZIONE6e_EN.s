
; Lesson 6e.s        OVERLAPPING OF TWO IDENTICAL BITPLANES, BUT ONE SHIFTED
;            ONE LINE DOWN, TO SIMULATE A SHADED FONT

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;    Point the bitplanes in copperlist

MOVE.L    #BITPLANE,d0    ; put the address of the bitplane in d0
LEA    BPLPOINTERS,A1    ; pointers in COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address

; NOTE THE -80!!!!

MOVE.L    #BITPLANE-80,d0    ; put the address of the bitplane -80 in d0
; i.e. a line BELOW! *******
LEA	BPLPOINTERS2,A1    ; pointers in COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)	; copy the HIGH word of the plane address

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106		; Disable AGA

bsr.w    print        ; Print the lines of text on the screen
; in HIRES
mouse:
btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

move.l    OldCop(PC),$dff080	; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr	-$19e(a6)    ; Closelibrary - close the graphics library
rts            ; EXIT THE PROGRAM

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0	; of the graphics library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

;    Routine that prints 8x8 pixel characters (on HIRES screen)

PRINT:
LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
MOVEQ    #25-1,D3    ; NUMBER OF LINES TO PRINT: 25
PRINTRIGA:
MOVEQ    #80-1,D0    ; NUMBER OF COLUMNS PER LINE: 80 (hires!)
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
MOVE.B    (A2)+,80(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,80*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,80*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,80*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,80*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,80*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,80*7(A3)    ; print LINE 8 ‘ ’

ADDQ.w    #1,A3        ; A1+1, move forward 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (80) CHARACTERS PER LINE

ADD.W    #80*7,A3	; START NEW LINE

DBRA    D3,PRINTRIGA    ; MAKE D3 LINES

RTS


; number of characters per line: 80, so 2 of these from 40!
TEXT:     ;         1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b    “ FIRST LINE IN HIRES 640 PIXELS WIDE” ; 1a \ FIRST LINE
dc.b    “GHEZZA! -- -- -- ALWAYS THE FIRST LINE” ; 1b /
dc.b    “ SECOND LINE ” ; 2 \ SECOND LINE
dc.b    “STILL SECOND LINE ” ; /
dc.b    “ /\ / ” ; 3
dc.b    “ ” ;
dc.b    “ / \/ ” ; 4
dc.b    “ ” ;
dc.b    “ ” ; 5
dc.b    “ ” ;
dc.b    “ SIXTH LINE ” ; 6
dc.b    “ END OF SIXTH LINE ” ;
dc.b    “ ” ; 7
dc.b    “ ” ;
dc.b    “ ” ; 8
dc.b    “ ” ;
dc.b    “FABIO CIUCCI COMMUNICATION INTERNATIONAL” ; 9
dc.b    “ MARKETING TRUST TRADEMARK COPYRIGHTED ” ;
dc.b    “ ” ; 10
dc.b    “ ” ;
dc.b    “ 1234567890 !@#$%^&*()_+|\=-[]{} ” ; 11
dc.b    “ TECHNICAL TRANSMISSION TESTS ” ;
dc.b    “ ” ; 12
dc.b    “ ” ;
dc.b    “ THE PALINGENETIC OBLITERATION OF THE ; 13
dc.b    ‘'TRANSCENDENTAL SELF THAT IDENTIFIES ITSELF ’ ;
dc.b    ” ' ; 14
dc.b    “ ” ;
dc.b    “ ” ; 15
dc.b    “ ” ;
dc.b    “ In the middle of the journey of our life ” ; 16
dc.b    “ ” ;
dc.b    “ ” ; 17
dc.b    “ ” ;
dc.b    “ I found myself in a dark forest ” ; 18
dc.b    “ ” ;
dc.b    “ ” ; 19
dc.b    “ ” ;
dc.b    “ THAT THE RIGHT PATH WAS LOST ” ; 20
dc.b    “ ” ;
dc.b    “ ” ; 21
dc.b    “ ” ;
dc.b    ' AHI How to tell which one it was.... “ ; 22
dc.b    ” ' ;
dc.b    “ ” ; 23
dc.b    “ ” ;
dc.b    “ ” ; 24
dc.b    “ ” ;
dc.b    “ C:\>_ ” ; 25
dc.b    “ ” ;
dc.b    “ ” ; 26
dc.b    “ ” ;

EVEN



SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w    $8e,$2c81    ; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$003c    ; DdfStart HIRES
dc.w    $94,$00d4	; DdfStop HIRES
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%1010001000000000    ; bit 13 - 2 bitplanes, 4 HIRES colours

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
BPLPOINTERS2:
dc.w $e4,$0000,$e6,$0000    ;second bitplane

dc.w    $180,$103    ; colour0 - BACKGROUND
dc.w    $182,$fff    ; colour1 - plane 1 normal position, this is
; the part that ‘protrudes’ at the top.
dc.w    $184,$345    ; colour2 - plane 2 (offset at the bottom)
dc.w    $186,$abc    ; colour3 - both planes - overlay

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

FONT:
incbin    ‘metal.fnt’    ; Wide character
;    incbin    ‘normal.fnt’    ; Similar to kickstart 1.3 characters
;    incbin    ‘nice.fnt’    ; Narrow character


SECTION    MIOPLANE,BSS_C    ; The BSS SECTIONS must be made up of
; only ZEROS!!! Use DS.b to define
; how many zeros the section contains.

;    This is why ‘ds.b 80’ is needed:
;    MOVE.L    #BITPLANE-80,d0    ; in d0 we put the address of bitplane -80
;                ; i.e. a line BELOW! *******

ds.b    80    ; the line that ‘shows up’
BITPLANE:
ds.b    80*256    ; a HIres 640x256 bitplane

end

Here's a ‘trick’ to make our writing look nicer: just activate the
second bitplane and superimpose it on the first one, but move it one line lower,
so as to create this situation:

...###..			...111..    ; 1 = colour1 (light)
..#...#.    ...###..    ..12221.    ; 2 = colour2 (dark)
..#...#.    ..#...#.    ..3...3.    ; 3 = colour3 (medium)
..#####. + ..#...#. =    ..31113.
..#...#.    ..#####.    ..32223.
..#...#.    ..#...#.    ..3...3.
..#...#.    ..#...#.    ..3...3.
........    ..#...#.    ..2...2.
........

dc.w    $180,$103    ; colour0 - BACKGROUND
dc.w    $182,$fff    ; colour1 - plane 1 normal position, this is
; the part that “protrudes” at the top.
dc.w    $184,$345    ; colour2 - plane 2 (offset at the bottom)
dc.w    $186,$abc    ; colour3 - both planes - overlap

The overlap of identical but offset bitplanes is often used to simulate
‘relief’ or ‘thickness’ effects

To accentuate this effect, it is often offset by one pixel laterally
as well. Try this:

dc.w    $102,$10    ; BplCon1 - plane 2 one pixel to the right

On small fonts, this may reduce legibility, but on larger surfaces
it can be useful to offset to the right as well:

......
.:::::#
.:::::#
.:::::#
######


; Lesson 6o.s        ROLLING RIGHT AND LEFT OF A PLAYFIELD LARGER
;            THAN THE SCREEN (here 640 pixels wide)
;            Right key to lock the scroll

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

; Warning! To ‘centre’ the image, you need to point 2 bytes further back
; by scrolling the PIC forward by 16 pixels, because the image starts
; 16 pixels further back thanks to DDFSTART (the ‘covered’ area where
; the display error to be hidden occurs).

MOVE.L    #BITPLANE-2,d0    ; in d0 we put the address of bitplane -2,
; i.e. -16 pixels, as the ‘first’ 16 pixels
; are “covered” and we have to ‘skip’ them,
; moving the PIC forward by 16
pixels
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g. 1234 > 3412)
move.w    d0,2(a1)	; copy the HIGH word of the plane address

bsr.w    print        ; Print the lines of text on the playfield
; 640 pixels wide (80 bytes per line)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

btst    #2,$dff016    ; Right button?
beq.w    Wait        ; If yes, do not scroll

bsr.w	MEGAScrolla    ; Horizontal scrolling of a wide figure
; 640 pixels in a 320-pixel wide screen.

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

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

; The Megascrolla routine is only used to execute the routine already seen
; ‘Right:’ 320 times, after which the ‘Left:’ routine is executed 320 times to
; return the figure to its initial position, at which point the cycle restarts, etc.
; To keep track of the number of times ‘Right:’ or
; ‘Left:’ has been executed, use the word “Contavolte” (count) to which ‘1’ is added every FRAME;
; since the video screen is 320 pixels wide and the figure in memory is 640 pixels wide,
; to scroll it, you will need to move 320 pixels:
;
; At the beginning:
;     _______________________________
;    |        |        |
;    | video screen |        |
;    | <- 320 -> |        |
;    |        |        |
;    | <- image in memory 640 -> |
;    |        |        |
;    |        |        |
;     -------------------------------
;
; When we have scrolled 320 pixels to the right:
;     _______________________________
;    |        |        |
;    |         | video screen |
;    |        | <- 320 -> |
;    |        |        |
;    | <- image in memory 640 -> |
;    |        |        |
;    |        |        |
;     -------------------------------
;
; Then another 320 pixels to the left and we return to see the first 320 pixels
; of the 640-pixel-wide image.
; Bit 1 of the DestSinFlag word indicates whether it is necessary to
; go to the right or to the left. To change the value of the bit from
; ZERO to ONE or from ONE to ZERO, the BCHG instruction is used, i.e. BIT CHANGE,
; already seen in another listing.

MEGAScrolla:
addq.w    #1,ContaVolte    ; Mark one more execution
cmp.w    #320,ContaVolte    ; Are we at 320?
bne.S    MuoviAncora    ; If not yet, move again
BCHG.B    #1,DestSinFlag    ; If we are at 320, change direction
CLR.w    CountTimes    ; of scrolling and reset ‘CountTimes’
rts

MoveAgain:
BTST    #1,DestSinFlag    ; Should we go right or left?
BEQ.S    GoLeft
bsr.s    Right        ; Scroll one pixel to the right
rts

GoLeft:
bsr.s    Left    ; Scroll one pixel to the left
rts

; This word counts how many times we have moved to the right or left

CountTimes:
DC.W    0

; When bit 1 of DestSinFlag is ZERO, the routine scrolls left; if
; it is 1, it scrolls right.

DestSinFlag:
DC.W    0

; This routine scrolls a bitplane to the right by acting on BPLCON1 and on
; pointers to bitplanes in copperlist. MIOBPCON1 is the byte of BPLCON1.

Right:
CMP.B    #$ff,MIOBPCON1    ; have we reached the maximum scroll? (15)
BNE.s    CON1ADDA    ; if not, scroll forward by 1
; with BPLCON1

LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; $dff0e0 is currently pointing and we point it to d0
move.w    6(a1),d0

subq.l    #2,d0        ; points 16 bits further back (the PIC scrolls
; to the right by 16 pixels)
clr.b	MIOBPCON1    ; reset the hardware scroll BPLCON1 ($dff102)
; in fact, we have ‘jumped’ 16 pixels with the
; bitplane pointer, now we have to start
; from scratch with $dff102 to move
; one pixel at a time to the right.

move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address
rts

CON1ADDA:
add.b	#$11,MIOBPCON1    ; scroll forward by 1 pixel
rts

;    Routine that moves to the left in a similar way:

Left:
TST.B    MIOBPCON1    ; have we reached the minimum scroll? (00)
BNE.s    CON1SUBBA    ; if not, scroll back by 1
; with BPLCON1

LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where it is currently pointing
swap    d0        ; $dff0e0 and we point it to d0
move.w    6(a1),d0

addq.l    #2,d0        ; point 16 bits further (the PIC scrolls
; 16 pixels to the left)
move.b    #$FF,MIOBPCON1    ; hardware scroll to 15 - BPLCON1 ($dff102)

move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
rts

CON1SUBBA:
sub.b    #$11,MIOBPCON1    ; scroll back 1 pixel
rts



;    Routine that prints 8x8 pixel characters (on HIRES screen)

PRINT:
LEA    TEXT(PC),A0    ; Address of the text to be printed in a0
LEA    BITPLANE,A3    ; Address of the destination bitplane in a3
MOVEQ    #25-1,D3    ; NUMBER OF LINES TO BE PRINTED: 25
PRINTRIGA:
MOVEQ    #80-1,D0    ; NUMBER OF COLUMNS PER LINE: 80 (hires!)
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
SUB.B	#$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER, IN
; ORDER TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; as the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,80(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,80*2(A3)	; print LINE 3 ‘ ’
MOVE.B    (A2)+,80*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,80*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,80*5(A3)    ; print LINE 6 " ‘
MOVE.B    (A2)+,80*6(A3)    ; print LINE 7 ’ ‘
MOVE.B    (A2)+,80*7(A3)    ; print LINE 8 ’ "

ADDQ.w    #1,A3        ; A1+1, move forward 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (80) CHARACTERS PER LINE

ADD.W    #80*7,A3    ; START A NEW LINE

DBRA    D3,PRINTRIGA    ; MAKE D3 LINES

RTS


; number of characters per line: 80, so 2 of these from 40!
TEXT:     ;         111111111122222222223333333334
;	 1234567890123456789012345678901234567890
dc.b    “ FIRST LINE IN HIRES 640 PIXELS WIDE” ; 1a \ FIRST LINE
dc.b    'GHEZZA! -- -- -- ALWAYS THE FIRST LINE' ; 1b /
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
dc.b    “ THE PALINGENETIC OBLITERATION OF THE ” ; 13
dc.b    ‘“TRANSCENDENTAL I THAT IDENTIFIES ITSELF ’ ;
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
dc.b    ' AHI How to tell which was... “ ; 22
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
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8e,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$30        ; DdfStart (modified for SCROLL)
dc.w    $94,$d0        ; DdfStop
dc.w    $102        ; BplCon1
dc.b    0        ; unused ‘high’ byte of $dff102
MIOBPCON1:
dc.b    0        ; used ‘low’ byte of $dff102
dc.w    $104,0        ; BplCon2
dc.w    $108,40-2    ; Bpl1Mod (40 for the wide figure 640, the -2
dc.w    $10a,40-2    ; Bpl2Mod (to balance the DDFSTART

; 5432109876543210
dc.w    $100,%0001001000000000    ; bit 12 - 1 bitplane LOWRES

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first    bitplane

dc.w    $180,$103    ; colour0 - BACKGROUND
dc.w    $182,$4ff    ; colour1 - TEXT

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

FONT:
;    incbin    ‘metal.fnt’
;    incbin    ‘normal.fnt’
incbin    ‘nice.fnt’


SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b	80*256    ; a bitplane 640x256 wide (like HIRES)

end

In this listing, the only real change is that we scroll a figure
larger than the screen instead of one 320 pixels wide.
First of all, when the screen is in LOWRES with normal DDFSTART/STOP values
the ‘automatic’ module is 40, i.e. the image is considered to be made up of
lines of 40 bytes. If, on the other hand, we have a 640-pixel wide image in memory,
as in this case, we need to change the module. In fact, the fact that the
image in memory is larger is irrelevant to the Copper, which displays
a LOWRES screen with a module of 40 as usual. However, we can change
the module using the BPL1MOD and BPL2MOD registers: the module is added to the
current module, which is 40, so all we need is:

dc.w    $108,40        ; Bpl1Mod (40 for the 640-wide image)
dc.w    $10a,40        ; Bpl2Mod

To ‘skip’ the 40 bytes that are ‘out of view’ at the end of each line of 320 pixels (40 bytes),
 continuing the display from the beginning of the
following line:

40 bytes     40 bytes (skipped each time with module = 40)
_______________________________
|        |        |
| video screen |        |
| <- 320 -> |        |
|        |        |
| <- image in memory 640 -> |
|        |        |
|        |        |
-------------------------------

Now, having displayed the right side of the 640-pixel wide figure on a
320-pixel wide screen SIMPLY by setting the modules to 40, we must make the
same change as in the Lesson 6n example to ‘hide’ the first 16 pixels
where the display error occurs due to scrolling.
We must then start the screen 16 pixels earlier by modifying the DDFSTART:

dc.w    $92,$30            ; DDFSTART = $30 (screen starting
; 16 pixels earlier, extending to
; 42 bytes per line, 336 pixels
; wide, but the DIWSTART ‘hides’
; these first 16 pixels with the error.

And, since we have enlarged the screen by making it ‘wrap’ every 42
bytes instead of 40, it is necessary to balance by subtracting 2 from the modules, which
in our case were at 40, and will go to 38:

dc.w    $108,40-2	; Bpl1Mod (40 for the 640 wide figure, the -2
dc.w    $10a,40-2    ; Bpl2Mod (to balance the DDFSTART

Ultimately, this type of scroll cannot be considered “difficult”; the only
difficulty lies in remembering to set MODULES/DDFSTART/BITPLANE ADDRESS correctly.
 In fact, there is also another “new feature” compared to Lesson 6n.s:

; Warning! To ‘centre’ the image, you need to point 2 bytes further back
; by scrolling the PIC forward by 16 pixels, the figure actually starts
; 16 pixels further back thanks to DDFSTART (the ‘covered’ area where
; the display error to be hidden occurs).

MOVE.L    #BITPLANE-2,d0    ; in d0 we put the address of bitplane -2,
; i.e. -16 pixels, as the ‘first’ 16 pixels
; are “covered” and we have to ‘skip’ them,
; moving the PIC forward by 16
; pixels

In fact, we have ‘hidden’ the first 16 pixels, so we would hide the first 2
characters of the text (8 pixels each * 2 = 16 pixels). Instead, by ‘moving’ the figure
forward by 16 pixels, we can also see the first 16 pixels correctly and the figure
appears centred, not shifted to the left by 16 pixels as in Lesson 6n.s.
Try removing the -2 from ‘MOVE.L #BITPLANE-2,d0’ and put a ; at the
routine

;    bsr.w    MEGAScrolla

so that you have a STILL image and you will notice that the first 16 pixels are missing, and
there are 2 more on the right, i.e. the image starts 16 pixels earlier than normal
To verify this, let's ‘uncover’ the first 16 pixels:

dc.w    $8e,$2c71    ; DiwStrt ($81-16=$71)

There are the first 16 pixels that ‘disappeared’! Put the -2 back and remove the ;
from the routine, leaving the first 16 pixels “uncovered”, and you will see how the
fatal scroll error occurs silently “behind the scenes”.

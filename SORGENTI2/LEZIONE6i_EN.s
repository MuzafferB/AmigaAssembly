
; Lesson 6i.s    3-COLOUR TEXT WITH A FLASHING COLOUR OBTAINED USING
;        A PRE-SET RGB COLOUR TABLE.


SECTION    CiriCop,CODE    ; NOTE: I have removed some initial comments to
; save space!

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

MOVE.L    #BITPLANE2,d0    ; where to point
LEA    BPLPOINTERS2,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

LEA    TEXT(PC),A0    ; text to print
LEA    BITPLANE,A3    ; destination
bsr.w    print        ; Print

LEA    TEXT2(PC),A0    ; text to print
LEA	BITPLANE2,A3    ; destination
bsr.w    print        ; Print

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

btst    #2,$dff016    ; right button?
beq.s    wait

bsr.w    Flash    ; Flashes Colour2 in copperlist

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

;    Flashing routine that uses a TABLE of shades already
;    ready. The TABLE is nothing more than a series of words containing
;    the various RGB values that COLOR1 will have to assume in the various frames.
;    This routine copies the next word in the table each time
;    it is executed, and once it reaches the last word of the TABLE,
;    i.e. 1 word (2 bytes) before the FINECOLORTAB label, it starts
;    reading the table from the beginning, for example:
;
;    dc.w    1,3,5,7,9,8,6,4,2,1    ; our ‘mini’ table
;
;    During the various frames, the words will be copied, ad infinitum, in
;    this order:
;
;    1,3,5,7,9,8,6,4,2,1,1,3,5,7,9,8,6,4,2,1,1,3,5,7,9,8,6,4,2,1....
;
;    The address of the last word read is kept in the long COLTABPOINT

Blinking:
ADDQ.L    #2,COLTABPOINT    ; Point to the next word
MOVE.L    COLTABPOINT(PC),A0 ; address contained in long COLTABPOINT
; copied to a0
CMP.L    #FINECOLORTAB-2,A0 ; Have we reached the last word of the TAB?
BNE.S    NOBSTART2        ; Not yet? Then continue
MOVE.L    #COLORTAB-2,COLTABPOINT    ; Start pointing to the first word again
NOBSTART2:
MOVE.W    (A0),COLOUR1    ; copy the word from the table to the colour COP
rts


COLTABPOINT:            ; This longword ‘POINTS’ to COLORTAB, i.e.
dc.l    COLORTAB-2    ; contains the address of COLORTAB. It will hold
; the address of the last word ‘read’ inside
; the table. (here it starts from COLORTAB-2 in
; as Blinking starts with an ADDQ.L #2,C..
; this is used to ‘balance’ the first instruction.

;    The table with the ‘precalculated’ values of the colour0 flashing

COLORTAB:
dc.w    $000,$000,$001,$011,$011,$011,$012,$012	; inizio SCURO
dc.w	$022,$022,$022,$023,$023
dc.w	$033,$033,$034
dc.w	$044,$044
dc.w	$045,$055,$055
dc.w	$056,$056,$066,$066,$066
dc.w	$167,$167,$177,$177,$177,$177,$177
dc.w	$278,$278,$278,$288,$288,$288,$288,$288
dc.w	$389,$389,$399,$399,$399,$399
dc.w	$39a, $39a, $3aa, $3aa, $3aa
dc.w    $3ab, $3bb, $3bb, $3bb
dc.w    $4bc, $4cc, $4cc, $4cc
dc.w    $4cd,$4cd,$4dd,$4dd,$4dd
dc.w    $5de,$5de,$5ee,$5ee,$5ee,$5ee
dc.w    $6ef,$6ff,$6ff,$7ff,$7ff,$8ff,$8ff,$9ff    ; ,maximum CLEAR
dc.w    $5ee,$5ee,$5ee,$5de,$5de,$5de
dc.w    $4dd,$4dd,$4dd,$4cd,$4cd
dc.w    $4cc,$4cc,$4cc,$4bc
dc.w    $3cb,$3bb,$3bb
dc.w	$3ba,$3aa,$3aa
dc.w	$3a9,$399,$399
dc.w    $298,$288
dc.w    $187,$177
dc.w    $076,$066
dc.w    $065,$055
dc.w    $054,$044
dc.w    $034
dc.w    $022
dc.w    $011
dc.w    $000            ; DARK again
FINECOLORTAB:

;    Routine that prints 8x8 pixel characters

PRINT:
MOVEQ    #23-1,D3    ; NUMBER OF LINES TO PRINT: 23
PRINTRIGA:
MOVEQ    #40-1,D0	; NUMBER OF COLUMNS PER LINE: 40
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER
MULU.W    #8,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 " ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ ‘
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ’ ‘
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ’ ‘
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ’ ‘
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ’ "

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
dc.b	“ ” ; 7
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
dc.b    “ THAT THE RIGHT PATH WAS ” ; 21
dc.b    “ ” ; 22
dc.b    ' AHI How RIGHT IT WAS... “ ; 23
dc.b    ” ' ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26
dc.b    “ ” ; 27

EVEN

; number of characters per line: 40
TEXT2:     ;         1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b	“ ” ; 1
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
dc.b    “ OH, HOW IT WAS... ” ; 23
dc.b    “ ” ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26
dc.b	“ ” ; 27

EVEN


SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0		; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0010001000000000    ; 2 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane
BPLPOINTERS2:
dc.w $e4,0,$e6,0    ;second bitplane

dc.w    $180,$000    ; colour0 - BACKGROUND
dc.w    $182
COLOUR1:
dc.w    $000        ; colour1 - first bitplane TEXT (blue)
dc.w    $184,$f62    ; colour2 - TEXT second bitplane (orange)
dc.w    $186,$1e4    ; colour3 - TEXT first+second bitplane (green)

dc.w    $FFFF,$FFFE    ; End of copperlist

;    The 8x8 character FONT

FONT:
incbin    ‘metal.fnt’
;    incbin    ‘normal.fnt’
;    incbin    ‘nice.fnt’

SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    40*256    ; lowres 320x256
BITPLANE2:
ds.b    40*256    ; lowres 320x256

end

By using predetermined or ‘precalculated’ values, you can achieve
much better movement or colour blending effects than by
using ADD and SUB alone.
The only ‘novelty’ is the programming technique of the “Flash” routine, which
reads the values to be put in ‘COLOUR1’ from a table, in which a
POINTER to the last word read is used, i.e. a LONGWORD containing the address
of that word in the table. Note that a:

COLTABPOINT:
dc.l    COLORTAB

is like a

COLTABPOINT:
DC.L    0

After a MOVE.L #COLORTAB,COLTABPOINT, a longword is assembled that
contains the address of the label in question. In this routine there is a

dc.l    COLORTAB-2

But this is only to read the first word the first time, since the
routine begins with:

Flashing:
ADDQ.L    #2,COLTABPOINT    ; Point to the next word

COLTABPOINT must contain the beginning of the first word-2, at least after the
first ADDQ.L #2 at the first jsr, the first word is copied and not the second.
Subsequently, the longword COLTABPOINT will be increased by 2 each time, i.e.
the address it contains will be that of the various words, until it
reaches the last word, which begins 2 bytes before the end of the
table:


; we are at this address when we read the last word...
dc.w    $0000            ; DARK again
FINECOLORTAB:

At this point, with a:

MOVE.L    #COLORTAB,COLTABPOINT    ; Start pointing from the first word again

the label COLTABPOINT returns to contain the address of the first word.

You can use this routine by changing the table for many purposes,
for example to make a sprite jump or wave.

Try replacing the table with this:

COLORTAB:
dc.w    $26F,$27E,$28D,$29C,$2AB,$2BA,$2C9,$2D8,$2E7,$2F6
dc.w    $4E7,$6D8,$8C9,$ABA,$CAA,$D9A,$E8A,$F7A,$F6B,$F5C
dc.w    $D6D,$B6E,$96F,$76F,$56F,$36F
FINECOLORTAB:

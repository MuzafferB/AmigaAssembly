
; Lesson 6m.s    ‘BOUNCE’ EFFECT USING A TABLE


SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

;    Point to the PIC

MOVE.L    #PIC,d0        ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0    ; + bitplane length
addq.w    #8,a1
dbra    d1,POINTBP

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

bsr.w    Bounce    ; Makes the PIC ‘bounce’ using a
pre-set table.

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

; This time we use a table containing the values to be subtracted from the
; bitplane pointers to simulate a ‘bounce’ of the figure, instead of an
; obvious UP-DOWN movement with add.l #40 and sub.l #40. To do this, we simply
; create a table with the values to be subtracted from the pointer, which
; are clearly multiples of 40, where 2*40 indicates that 2 lines are skipped,
; while 3*40 indicates that 3 are skipped at a time:
;
;    dc.l    40,40,2*40,2*40    ; example...
;
; To return to the initial position once you reach the bottom of the screen
; you need to add what was subtracted from the bitplane pointers, therefore,
; since there is a subtraction in the routine:
;
;    sub.l    d1,d0    ; subtract the value of the table (d1) from the address
;            ; that is pointing to the bplpointer
;
; how do we ADD with a SUB?? Simple! Just SUBTRACT negative numbers
;!!! How much is 10-(-1)? It's 11!!! So the table contains
; negative numbers after reaching ‘the bottom’:
;
;    dc.l    -8*40,-6*40,-5*40        ; let's go back up
;
; a sub.l #-8*40 is like an add.l #8*40.
; Remember, however, that negative numbers keep “the sign” on the highest bit?
; So a -40 is $FFFFFFd8, which is why the values in the table are
; in LONGWORD and not in WORD, to contain negative numbers.
; In fact, a:
;
; dc.w -40
;
; is not assembled, due to an error; you must use .l for negative numbers.
;
; Having used .L values, you must remember this in the routine:
;
; ADDQ.L #4,RIMTABPOINT
; FINERIMBALZTAB-4
; dc.l RIMBALZTAB-4
;
; and not
;
; ADDQ.L #2,RIMTABPOINT
; FINERIMBALZTAB-2
; dc.l RIMBALZTAB-2
;
; As for the actual move, there is nothing new:
; we retrieve the address from BPLPOINTERS, perform the SUB with the value read
; in the table and repoint the new address.

Bounce:
LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; $dff0e0 is currently pointing and we point it to d0
move.w    6(a1),d0

ADDQ.L    #4,RIMTABPOINT    ; Point to the next longword
MOVE.L    RIMTABPOINT(PC),A0 ; address contained in long RIMTABPOINT
; copied to a0
CMP.L    #FINERIMBALZTAB-4,A0 ; Are we at the last longword of the TAB?
BNE.S    NOBSTART2        ; Not yet? Then continue
MOVE.L    #RIMBALZTAB-4,RIMTABPOINT ; Start pointing to the first longword again
NOBSTART2:
MOVE.l    (A0),d1        ; Copy the longword from the table to d1

sub.l    d1,d0        ; subtract the value currently taken from the
; table, scrolling the figure UP or DOWN.

LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP2:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1        ; go to the next bplpointers in the COP
dbra    d1,POINTBP2    ; Repeat POINTBP D1 times (D1=number of bitplanes)
rts


RIMTABPOINT:            ; This longword ‘POINTS’ to RIMBALZTAB, i.e.
dc.l    RIMBALZTAB-4    ; contains the address of RIMBALZTAB. It will hold
; the address of the last long ‘read’ inside
; the table. (here it starts from RIMORTAB-4 in
; as Flashing starts with an ADDQ.L #4,C..
; this is used to ‘balance’ the first instruction.

;    The table with the ‘precalculated’ values of the bounce

RIMBALZTAB:
dc.l	0,0,0,0,0,0,40,40,40,40,40,40,40,40,40 		; scendiamo
dc.l	40,40,2*40,2*40
dc.l	2*40,2*40,2*40,2*40,2*40
dc.l	3*40,3*40,3*40,3*40,3*40,4*40,4*40,4*40,5*40,5*40
dc.l    6*40,8*40                    ; at the bottom
dc.l    -8*40,-6*40,-5*40				; risaliamo
dc.l	-5*40,-4*40,-4*40,-4*40,-3*40,-3*40,-3*40,-3*40,-3*40
dc.l	-2*40,-2*40,-2*40,-2*40,-2*40
dc.l	-2*40,-2*40,-40,-40
dc.l	-40,-40,-40,-40,-40,-40,-40,-40,-40,0,0,0,0,0	; siamo in cima
FINERIMBALZTAB:


SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000    ;third bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist


dcb.b    80*40,0    ; space cleared for bitplane scrolling

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,

end

Programming a demo or a game also means creating a myriad of tables.
The one used in this listing could be useful for making a little man jump
in a platform game; poorly programmed games using unsuitable languages
often suffer more from unnatural movements than
from slowness or other issues. Imagine that the protagonist of a platform game jumps
up with an add and suddenly, when he reaches the top, he drops with a sub.
The effect would be terribly ugly. Even the swaying movements of the
aliens in a shooter game matter a lot, and they are the result of tables.
To complicate matters, clever programmers create a number of
tables just for the character's jump, and depending on the character's movement
or the time the button is pressed, they make the jump curve
according to the right table, or they add values to those in the
base table, or they mix the values of many tables. In extreme cases such as
pinball games, you really need to create a routine that calculates bounces and
gravity, but this does not exclude the routine from having tables inside it;
However, in a pinball game, only the ball moves (the pinball screen
can be moved by changing the bitplane pointers), and you can waste
time calculating the movement, whereas in other types of games, tables are used.
Learn how to use the routine that reads the values from the table and use it to
modify previous examples, for example, to make the copper bars move
in a strange, oscillating way.

Try replacing the table with this one: it causes an oscillatory ‘fluctuation’
instead of a bounce. (use Amiga+b+c+i)


RIMBALZTAB:
dc.l    0,0,40,40,40,40,40,40,40,40,40             ; at the top
dc.l    40,40,2*40,2*40
dc.l    2*40,2*40,2*40,2*40,2*40            ; accelerate
dc.l    3*40,3*40,3*40,3*40,3*40
dc.l    3*40,3*40,3*40,3*40,3*40
dc.l	2*40,2*40,2*40,2*40,2*40			; deceleriamo
dc.l	2*40,2*40,40,40
dc.l	40,40,40,40,40,40,40,40,40,0,0,0,0,0,0,0	; in fondo
dc.l	-40,-40,-40,-40,-40,-40,-40,-40,-40
dc.l	-40,-40,-2*40,-2*40
dc.l	-2*40,-2*40,-2*40,-2*40,-2*40
dc.l    -3*40,-3*40,-3*40,-3*40,-3*40            ; accelerate
dc.l    -3*40,-3*40,-3*40,-3*40,-3*40
dc.l	-2*40,-2*40,-2*40,-2*40,-2*40			; deceleriamo
dc.l	-2*40,-2*40,-40,-40
dc.l	-40,-40,-40,-40,-40,-40,-40,-40,-40,0,0,0,0,0	; in cima
FINERIMBALZTAB:


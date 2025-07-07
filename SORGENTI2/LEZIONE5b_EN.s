
; Lesson 5b.s    MOVING A FIGURE TO THE RIGHT AND LEFT WITH $dff102

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea	GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;     POINT OUR BITPLANES

MOVE.L    #PIC,d0        ; put the PIC address in d0,
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

;

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue

bsr.s    MoveCopper    ; scroll the image to the right with $dff102
; and to the left (maximum 16 pixels), here
; the word COMMODORE

btst    #2,$dff016    ; if the right key is pressed, jump
beq.s    Wait        ; the scroll routine, blocking it

bsr.w    MoveCopper2    ; scrolls the figure to the right with $dff102
; and to the left (maximum 16 pixels), here
; the word AMIGA

Wait
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If so, don't continue, wait!

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, go back to mouse:

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

;    This routine moves the ‘COMMODORE’ text, acting on MIOCON1

MoveCopper:
TST.B    FLAG        ; Do we need to move forward or backward? If
; FLAG is zero (i.e. TST checks
; BEQ)
; then we jump to FORWARD, if instead it is $FF
; (i.e. this TST is not checked)
; we continue moving backward (with subs)
beq.w    FORWARD
cmpi.b    #$00,MIOCON1    ; we have reached the normal position, i.e.
; all back?
beq.s    MoveForward    ; if yes, we must move forward!
sub.b    #$11,MIOCON1    ; subtract 1 from the bitplane scroll
rts            ; odd ($ff,$ee,$dd,$cc,$bb,$aa,$99....)

MoveForward:
clr.b    FLAG		; Resetting FLAG, at TST.B FLAG the BEQ
rts            ; will jump to the FORWARD routine, and
; the figure will move forward (to the right)

FORWARD:
cmpi.b    #$ff,MIOCON1    ; have we reached the maximum scroll forward
; i.e. $FF? ($f even and $f odd)
beq.s    MettiIndietro    ; if so, we must go back
add.b    #$11,MIOCON1    ; add 1 to the bitplane scroll
; even and odd ($11,$22,$33,$44 etc..)
rts

MettiIndietro:
move.b    #$ff,FLAG	; When the FLAG label is not zero,
rts            ; it means we have to move backwards
; to the left

;    This byte is a FLAG, i.e. it is used to indicate whether to move forwards or
;    backwards.

FLAG:
dc.b    0,0

;************************************************************************

;    This routine moves the word ‘AMIGA’ by acting on MIACON1

MoveCopper2:
TST.B    FLAG2        ; Should we move forward or backward?
beq.w    FORWARD2
cmpi.b	#$00,MIACON1    ; have we reached the normal position?
beq.s    MoveForward2    ; if so, we must move forward!
sub.b    #$11,MIACON1    ; subtract 1 from the bitplane scroll
rts            ; ($ff,$ee,$dd,$cc,$bb,$aa,$99....)

MoveForward2:
clr.b    FLAG2        ; Resetting FLAG, at TST.B FLAG the BEQ
rts            ; will jump to the AVANTI routine

AVANTI2:
cmpi.b    #$ff,MIACON1    ; have we reached the maximum scroll in
; forward, i.e. $FF? ($f even and $f odd)
beq.s    MoveBack2    ; if so, we must go back
add.b    #$11,MIACON1    ; add 1 to the bitplane scroll
; even and odd ($11,$22,$33,$44 etc..)
rts

MoveBack2:
move.b    #$ff,FLAG2    ; When the FLAG label is not zero,
rts            ; it means we have to go back.

Finished2:
rts

;    This byte is a FLAG, i.e. it is used to indicate whether to go forward or
;    backward.

FLAG2:
dc.b    0,0


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

dc.w    $102        ; BplCon1 - THE REGISTER
dc.b    $00		; BplCon1 - THE UNUSED BYTE!!!
MIOCON1:
dc.b    $00        ; BplCon1 - THE USED BYTE!!!

dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210    ; BPLCON0:
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)
; 3 low-resolution bitplanes, no lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane - BPL0PT
dc.w $e4,$0000,$e6,$0000    ;second bitplane - BPL1PT
dc.w $e8,$0000,$ea,$0000    ;third bitplane - BPL2PT

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $7007,$fffe    ; Wait until below the word ‘COMMODORE’

dc.w    $102        ; BplCon1 - THE REGISTER
dc.b    $00        ; BplCon1 - THE UNUSED BYTE!!!
MIACON1:
dc.b    $ff		; BplCon1 - THE BYTE USED!!!


dc.w    $FFFF,$FFFE    ; End of the copperlist

;    figure

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

This example was obtained by copying the Muovicopper routine and changing
its labels by adding a 2 to ‘rename’ it, so as not to rewrite
it all.
 Often, to add similar routines, we copy the relevant piece with Amiga+b+c+i, then change the name of the labels. As
for the copperlist, it was enough to add another $dff102, whose name
MIACON1, after a WAIT $7007, i.e. under the Commodore logo, so that
it acts on the part of the figure below, which is the ‘AMIGA’ logo.
To create the ‘DISCORDANCE’ of movement, whereby one part goes to the right
when the other goes to the left and vice versa, it was sufficient to start the loop
from $FF instead of $00, i.e. from position 15, so that the two cycles
Muovicopper and Muovicopper2 continue from the two opposite positions.

dc.w    $102        ; BplCon1 - THE REGISTER
dc.b    $00        ; BplCon1 - THE UNUSED BYTE!!!
MIOCON1:
dc.b    $00        ; BplCon1 - THE BYTE USED!!!

...

dc.w    $102        ; BplCon1 - THE REGISTER
dc.b    $00        ; BplCon1 - THE BYTE NOT USED!!!
MIACON1:
dc.b    $ff        ; BplCon1 - THE BYTE USED!!!

Try changing the MIACON1 byte: instead of $ff, try $55 and $aa or other
values, and it will be clearer.

Right-clicking only locks the second $102.
Try changing the Wait to make the scroll difference occur in other
positions, for example:


dc.w    $a007,$fffe

This ‘divides’ the image in the middle of the word ‘AMIGA’.

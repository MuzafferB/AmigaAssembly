
; Lesson 5d.s    MOVING A FIGURE UP AND DOWN BY MODIFYING THE
;        POINTERS TO THE PITPLANES IN THE COPPERLIST PLUS MOVING
;        RIGHT AND LEFT USING $dff102 (BPLCON0)

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
jsr    -$198(a6)	; OpenLibrary
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

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse		; If not, don't continue


bsr.w    MoveCopper    ; scrolls the figure up and down
; one line at a time, changing the
; pointers to the bitplanes in copperlist

btst    #2,$dff016    ; if the right key is pressed, jump
beq.s    Wait        ; the scroll routine, blocking it

bsr.w    MoveCopper2    ; scrolls the figure to the right
; and to the left (maximum 15 pixels)

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If yes, don't go on, wait!

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, go back to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)    ; Closelibrary - close graphics lib
rts            ; EXIT PROGRAM

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0


;    This routine moves the figure up and down, acting on the
;    pointers to the bitplanes in copperlist (using the label BPLPOINTERS)
;    The structure is similar to that of Lesson3d.s

MuoviCopper:
LEA    BPLPOINTERS,A1    ; With these 4 instructions we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; $dff0e0 is currently pointing and place it
move.w    6(a1),d0    ; in d0
TST.B    SuGiu        ; Do we need to go up or down?
beq.w    VAIGIU
cmp.l    #PIC-(40*30),d0    ; are we high enough?
beq.s    MettiGiu    ; if so, we are at the top and need to go down
sub.l    #40,d0        ; subtract 40, i.e. 1 line
bra.s	Finished

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
bra.s    Finito        ; will jump to the VAIGIU routine

VAIGIU:
cmpi.l    #PIC+(40*30),d0    ; have we gone LOW enough?
beq.s    MettiSu        ; if so, we are at the bottom and we have to go back up
add.l    #40,d0        ; Add 40, i.e. 1 line
bra.s    finished

MettiSu:
move.b    #$ff,SuGiu    ; When the SuGiu label is not zero,
rts            ; it means we have to go back up.

Finito:                ; POINT THE BITPLANE POINTERS
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP2:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1		; go to the next bplpointers in COP
dbra    d1,POINTBP2    ; Repeat D1 times POINTBP (D1=number of bitplanes)
rts

;    This byte, indicated by the label SuGiu, is a FLAG.

SuGiu:
dc.b    0,0

;***************************************************************************
MoveCopper2:
TST.B    FLAG        ; Should we move forward or backward?
beq.w    FORWARD
cmpi.b    #$00,MIOCON1    ; Have we reached the normal position?
beq.s    MoveForward    ; if so, we must move forward!
sub.b    #$11,MIOCON1    ; subtract 1 from the bitplane scroll
rts

MoveForward:
clr.b    FLAG        ; Resetting FLAG, at TST.B FLAG the BEQ
rts            ; will jump to the AVANTI routine

AVANTI:
cmpi.b    #$ff,MIOCON1    ; have we reached the maximum scroll forward
; i.e. $FF? ($f even and $f odd)
beq.s    MettiIndietro    ; if so, we must go back
add.b    #$11,MIOCON1	; add 1 to the bitplane scroll
rts

MettiIndietro:
move.b    #$ff,FLAG    ; When the FLAG label is not zero,
rts            ; it means we have to go back

;    This byte is a FLAG, i.e. it is used to indicate whether to go forward or
;    backward.

FLAG:
dc.b    0,0


SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w    $13e,$0000

dc.w    $8e,$2c81    ; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop

dc.w    $102        ; BplCon1 - THE REGISTER
dc.b    $00        ; BplCon1 - THE BYTE NOT USED!!!
MIOCON1:
dc.b    $00        ; BplCon1 - THE BYTE USED!!!

dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0		; Bpl2Mod

; 5432109876543210    ; BPLCON0:
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)
; 3 low-resolution bitplanes, non-lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane - BPL0PT
dc.w $e4,$0000,$e6,$0000    ;second bitplane - BPL1PT
dc.w $e8,$0000,$ea,$0000    ;third     bitplane - BPL2PT

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7
dc.w    $FFFF,$FFFE    ; End of copperlist

;    figure

dcb.b    40*30,0            ; zeroed space

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

dcb.b    40*30,0            ; space reset

end

Nothing new, just the previous sources from
Lesson 5

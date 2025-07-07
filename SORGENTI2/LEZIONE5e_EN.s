
; Lesson 5e.s    HALVING THE HEIGHT OF A FIGURE BY MODIFYING THE MODULES

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
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
move.w    d0,2(a1)    ; copy the UPPER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1        ; go to the next bplpointers in the COP
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=number of bitplanes)
;
move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue
frame:
cmpi.b    #$fe,$dff006    ; Are we at line 254? (must repeat the loop!)
bne.s    frame        ; If not yet, do not continue
frame2:
cmpi.b    #$fd,$dff006    ; Are we on line 253?
bne.s    frame2        ; If not yet, do not continue
frame3:
cmpi.b    #$fc,$dff006    ; Are we on line 252?
bne.s    frame3
frame4:
cmpi.b    #$fb,$dff006    ; Are we at line 251?
bne.s    frame4

btst    #2,$dff016    ; if the right key is pressed, jump
beq.s	NonMuovere    ; the scroll routine, blocking it

bsr.s    MuoviCopper    ; Module routine

NonMuovere
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts            ; EXIT THE PROGRAM

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

; With this routine, we add or subtract 40 from the module registers to
; shorten the figure. I have kept the labels from the previous example to
; save time.

MoveCopper:
TST.B    UpDown        ; Do we need to go up or down?
beq.w    VAIGIU
tst.w    MOD1        ; Are we at the normal module value? (ZERO)
beq.s    MettiGiu    ; if so, we must increase the value
sub.w    #40,MOD1    ; subtract 40, i.e. 1 line, causing
; the figure to scroll DOWN (enlarging it)
sub.w    #40,MOD2    ; subtract 40 from module 2
rts

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
rts            ; will jump to the VAIGIU routine

VAIGIU:
cmpi.w    #40*20,MOD1    ; have we halved enough?
beq.s    MettiSu        ; if so, we must return the pic to normal
add.w    #40,MOD1    ; Add 40, i.e. 1 line, by
; scrolling the figure UP (halving it)
add.w    #40,MOD2    ; Add 40 to the module 2
rts

MettiSu:
move.b    #$ff,SuGiu    ; When the SuGiu label is not zero,
rts            ; it means we have to go back up.


;    This byte, indicated by the SuGiu label, is a FLAG.

SuGiu:
dc.b    0,0


SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w    $8e,$2c81    ; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108
MOD1:
dc.w    0        ; Bpl1Mod
dc.w    $10a
MOD2:
DC.W    0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)
; 3 lowres bitplanes, no lace
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

;    figure


PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes
end

To make it ‘cleaner’, I should have put a wait under the figure
to remove the “impurities” that can be seen at the bottom, i.e. the bytes
in memory after the figure and the bitplanes that ‘pop up’ under the first and
second. But the main purpose is to explain the function of the modules.
The routine is executed once every 4 frames to slow it down.
The code is in the attached file.

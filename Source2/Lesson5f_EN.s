
; Lesson 5f.s    ‘MELTING’ OR ‘FLOOD’ EFFECT MADE WITH NEGATIVE MODULES

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
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

btst    #2,$dff016    ; if the right key is pressed, jump
beq.s    Wait        ; the scroll routine, blocking it

bsr.w    Flood        ; Moves a wait up and down followed
; by a -40 module, which causes the FLOOD effect

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If so, don't go on, wait!

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

; Effect definable as ‘Molten metal’, obtained with modules -40

Flood:
TST.B    SuGiu        ; Do we need to go up or down?
beq.w    VAIGIU
cmp.b    #$30,FWAIT	; have we gone HIGH enough?
beq.s    MettiGiu    ; if so, we are at the top and must go down
subq.b    #1,FWAIT    ; scroll UP
rts

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
rts

GO DOWN:
cmp.b    #$f0,FWAIT    ; have we gone low enough?
beq.s    PutUp        ; if yes, we are at the bottom and must go back up
addq.b    #1,FWAIT    ; scroll UP
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

dc.w	$8e,$2c81	; DiwStrt	(registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)
; 3 lowres bitplanes, non-lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000	;second bitplane
dc.w $e8,$0000,$ea,$0000    ;third     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w $0184,$fff; colour2
dc.w $0186,$ccc; colour3
dc.w $0188,$999; colour4
dc.w $018a,$232; colour5
dc.w $018c,$777; colour6
dc.w    $018e,$444    ; colour7

FWAIT:
dc.w    $3007,$FFFE    ; WAIT preceding the negative module
dc.w    $108,-40
dc.w    $10a,-40

dc.w    $FFFF,$FFFE    ; End of copperlist

;    figure

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

Note that -40 is assembled as $ffd8 (try with a ‘?-40’).
Try blocking the routine with the right mouse button and you will see that the last line is
‘extended’ to the end of the screen.
We have verified that with a negative module of -40, the copper does not advance,
in fact it goes forward 40 and back 40. But if we set the module to -80,
what happens??? It reads backwards!!! In fact, it reads and displays 40 bytes, then
goes back 80 bytes, going to the beginning of the previous line, which is
displayed, after which it jumps to the previous line, and so on. This system
is the most commonly used for MIRROR effects, which are so frequent on the Amiga precisely
because all you need to do is put a couple of copper instructions:

dc.w    $108,-80
dc.w    $10a,-80

Try changing the two -40s in the modules in this example to two -80s, and the
“MIRROR” will appear, although this time the problem is that
something above the image is also displayed (moving backwards).
A curiosity: you will notice that in the first line of the ‘DIRT’ that appears after
the mirrored image there is a movement that affects the pixels: this is the
wait in the copperlist that we change every frame! In fact, what is in memory
before our image? The copperlist! So, proceeding backwards
in the reading (module -80), what will be displayed? The bytes of the copperlist,
then what comes before.

If we increase the negativity, we will obtain increasingly flattened mirror images.
In fact, the same effect as the positive modules occurs, but in reverse.

dc.w    $108,-40*3
dc.w    $10a,-40*3

For the mirrored figure halved, etc.

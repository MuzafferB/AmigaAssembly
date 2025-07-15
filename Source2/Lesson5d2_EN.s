
; Lesson 5d2.s    MOVING A FIGURE UP AND DOWN BY MODIFYING THE
;        POINTERS TO THE PITPLANES IN THE COPPERLIST + DISTORTION EFFECT
;        OBTAINED WITH $dff102 (bplcon1)

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
move.w    d0,6(a1)    ; copy the LOW word of the plane address
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

btst    #2,$dff016    ; if the right button is pressed, jump
beq.s    Wait        ; the scroll routine, blocking it


bsr.w    MoveCopper    ; scrolls the figure up and down
; one line at a time, changing the
; pointers to the bitplanes in copperlist

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If yes, don't go on, wait!

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


;    This routine moves the figure up and down, acting on the
;    pointers to the bitplanes in copperlist (via the label BPLPOINTERS)
;    The structure is similar to that of Lesson3d.s

MuoviCopper:
LEA    BPLPOINTERS,A1    ; With these 4 instructions we retrieve from
move.w	2(a1),d0    ; copperlist the address where it is pointing
swap    d0        ; currently $dff0e0 and we place it
move.w    6(a1),d0    ; in d0 - the opposite of the routine that
; points to the bitplanes! Here, instead of putting
; the address, we take it!!!

TST.B    SuGiu        ; Do we need to go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then we jump to VAIGIU, if instead it is at $FF
; (i.e. this TST is not verified)
; we continue going up (doing subs)
beq.w	VAIGIU
cmp.l    #PIC-(40*30),d0    ; are we low enough?
beq.s    MettiGiu    ; if so, we are at the bottom and must go back up
sub.l    #40,d0        ; subtract 40, i.e. 1 line, causing
; the figure to scroll DOWN
bra.s	Finished

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
bra.s    Finito        ; will jump to the VAIGIU routine

VAIGIU:
cmpi.l    #PIC+(40*30),d0    ; are we high enough?
beq.s    MettiSu        ; if so, we are at the bottom and we have to go back up
add.l    #40,d0        ; Add 40, i.e. 1 line, by
; scrolling the figure UP
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
addq.w	#8,a1        ; go to the next bplpointers in COP
dbra    d1,POINTBP2    ; Repeat D1 times POINTBP (D1=number of bitplanes)
rts


;    This byte, indicated by the label SuGiu, is a FLAG.

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

;    MIRROR EFFECT (which could be sold as a ‘texture map’ effect)

dc.w    $7007,$fffe
dc.w    $180,$004    ; Colour0
dc.w    $102,$011    ; bplcon1
dc.w    $7307,$fffe
dc.w    $180,$006    ; Color0
dc.w    $102,$022    ; bplcon1
dc.w    $7607,$fffe
dc.w    $180,$008	; Color0
dc.w    $102,$033    ; bplcon1
dc.w    $7b07,$fffe
dc.w    $180,$00a    ; Color0
dc.w    $102,$044    ; bplcon1
dc.w    $8307,$fffe
dc.w    $180,$00c    ; Colour0
dc.w    $102,$055    ; bplcon1
dc.w    $9007,$fffe
dc.w    $180,$00e    ; Colour0
dc.w    $102,$066	; bplcon1
dc.w    $9607,$fffe
dc.w    $180,$00f    ; Colour0
dc.w    $102,$077    ; bplcon1
dc.w    $9a07,$fffe
dc.w    $180,$00e    ; Colour0
dc.w    $a007,$fffe
dc.w    $180,$00c    ; Colour0
dc.w    $102,$066    ; bplcon1
dc.w    $ad07,$fffe
dc.w    $180,$00a    ; Colour0
dc.w    $102,$055    ; bplcon1
dc.w    $b507,$fffe
dc.w    $180,$008    ; Colour0
dc.w    $102,$044    ; bplcon1
dc.w    $ba07,$fffe
dc.w    $180,$006    ; Color0
dc.w    $102,$033    ; bplcon1
dc.w    $bd07,$fffe
dc.w    $180,$004    ; Color0
dc.w    $102,$022    ; bplcon1
dc.w    $bf07,$fffe
dc.w    $180,$001    ; Colour0

dc.w    $FFFF,$FFFE    ; End of copperlist

;    figure

dcb.b    40*98,0        ; space cleared

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

dcb.b    40*30,0        ; space reset

end

By changing only the copperlist of the example Lesson5c.s, we were able to obtain
this effect of ‘wrapping the figure around a cylinder’, which is not very
convincing, but at least it is very easy and quick to do. In fact, just
put the $dff102 in progressive order in the waits: 1,2,3,4 to create the first
distortion to the right:

+++++++++++++
+++++++++++++
+++++++++++++
+++++++++++++

then, once you reach the middle, just decrease by one each time until you return to zero.

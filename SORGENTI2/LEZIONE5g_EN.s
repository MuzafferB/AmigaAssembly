
; Lesson 5g.s    MOVING A FIGURE UP AND DOWN BY MODIFYING THE
;        POINTERS TO THE PITPLANES IN THE COPPERLIST + MIRROR EFFECT
;        OBTAINED WITH NEGATIVE MODULES (-40*2, -40*3, -40*4...)

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
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L	#40*256,d0    ; + bitplane length -> next bitplane
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

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, go back to mouse:

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
	

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of the graphics.library

OldCop:            ; Here goes the address of the old system COP
dc.l    0


;    This routine moves the figure up and down, acting on the
;    pointers to the bitplanes in copperlist (via the BPLPOINTERS label)
;    The structure is similar to that of Lesson3d.s

MuoviCopper:
LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where it is pointing
swap    d0		; currently $dff0e0 and place it
move.w    6(a1),d0    ; in d0 - the opposite of the routine that
; points to the bitplanes! Here, instead of putting
; the address, we take it!!!

TST.B    SuGiu        ; Do we need to go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then we jump to VAIGIU, if instead it is at $FF
; (i.e. this TST is not verified)
; we continue going up (doing subs)
beq.w    VAIGIU
cmp.l    #PIC-(40*18),d0    ; are we low enough?
beq.s	MettiGiu    ; if so, we are at the bottom and we have to go back up
sub.l    #40,d0        ; subtract 40, i.e. 1 line, making
; the figure scroll DOWN
bra.s    Finito

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
bra.s    Finito        ; will jump to the VAIGIU routine

VAIGIU:
cmpi.l	#PIC+(40*130),d0    ; are we high enough?
beq.s    MettiSu        ; if so, we are at the bottom and must go back up
add.l    #40,d0        ; Add 40, i.e. 1 line, causing
; the figure to move UP
bra.s    Finished

MettiSu:
move.b	#$ff,SuGiu    ; When the SuGiu label is not zero,
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


SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w    $8e,$2c81    ; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0	; DdfStop
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

; MIRROR EFFECT (which could be sold as a ‘texture map’ effect)

dc.w    $b007,$fffe
dc.w    $180,$004    ; Colour0
dc.w    $108,-40*7    ; Bpl1Mod - mirror halved 5 times
dc.w    $10a,-40*7    ; Bpl2Mod
dc.w    $b307,$fffe
dc.w    $180,$006	; Colour0
dc.w    $108,-40*6    ; Bpl1Mod - mirror halved 4 times
dc.w    $10a,-40*6    ; Bpl2Mod
dc.w    $b607,$fffe
dc.w    $180,$008	; Colour0
dc.w    $108,-40*5    ; Bpl1Mod - mirror halved 3 times
dc.w    $10a,-40*5    ; Bpl2Mod
dc.w    $bb07,$fffe
dc.w    $180,$00a    ; Color0
dc.w    $108,-40*4
dc.w    $10a,-40*4
dc.w    $c307,$fffe
dc.w    $180,$00c
dc.w    $108,-40*3	; Bpl1Mod - mirror halved
dc.w    $10a,-40*3    ; Bpl2Mod
dc.w    $d007,$fffe
dc.w    $180,$00e    ; Color0
dc.w    $108,-40*2    ; Bpl1Mod - normal mirror
dc.w    $10a,-40*2    ; Bpl2Mod
dc.w    $d607,$fffe
dc.w    $180,$00f    ; Colour0
dc.w    $108,-40	; Bpl1Mod - FLOOD, repeated lines for
dc.w    $10a,-40    ; Bpl2Mod - central enlargement effect
dc.w    $da07,$fffe
dc.w    $180,$00e    ; Color0
dc.w    $108,-40*2	; Bpl1Mod - normal mirror
dc.w    $10a,-40*2    ; Bpl2Mod
dc.w    $e007,$fffe
dc.w    $180,$00c    ; Color0
dc.w    $108,-40*3    ; Bpl1Mod - halved mirror
dc.w    $10a,-40*3    ; Bpl2Mod
dc.w    $ed07,$fffe
dc.w    $180,$00a    ; Color0
dc.w    $108,-40*4	; Bpl1Mod - mirror halved twice
dc.w    $10a,-40*4    ; Bpl2Mod
dc.w    $f507,$fffe
dc.w    $180,$008    ; Color0
dc.w    $108,-40*5    ; Bpl1Mod - mirror halved 3 times
dc.w    $10a,-40*5    ; Bpl2Mod
dc.w    $fa07,$fffe
dc.w    $180,$006    ; Colour0
dc.w    $108,-40*6	; Bpl1Mod - mirror halved 4 times
dc.w    $10a,-40*6    ; Bpl2Mod
dc.w    $fd07,$fffe
dc.w    $180,$004    ; Color0
dc.w    $108,-40*7    ; Bpl1Mod - mirror halved 5 times
dc.w    $10a,-40*7    ; Bpl2Mod
dc.w    $ff07,$fffe
dc.w    $180,$002    ; Color0
dc.w    $108,-40    ; freeze the image to avoid displaying
dc.w    $10a,-40    ; the bytes before the RAW

dc.w    $FFFF,$FFFE    ; End of the copperlist

;    figure

dcb.b    40*98,0        ; space reset

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

dcb.b    40*30,0        ; space reset

end

In this example, by placing negative modules to create mirroring that is always
more ‘HALVED’, it was possible to simulate “wrapping” of the mirrored image
on a roughly ‘curved’ surface. By arranging the modules well,
 you can generate ZOOM or MAGNIFYING GLASS effects, as well as
cylindrical distortion like this example, especially if you enhance the effect
with colours (in this case with a shade of blue).
The source is the same as in Lesson 5c.s, the only change is in the copperlist.
To add realism to the ‘wrapping around a cylinder’ effect,
you can simulate a curvature with $dff102 (bplcon1), as already seen in
the listing Lesson5d2.s. Replace the copperlist in the example with this one, which
is a fusion with the one in Lesson5d2.s.

- Remember that to remove the old part of the copperlist, you can use
the Amiga+b option to select it and Amiga+x to cut it once selected,
while to copy this part of the copperlist above, select it with Amiga+b,
then Amiga+c to copy, position yourself in the right place in the copperlist and
insert it with Amiga+i.


dc.w    $b007,$fffe
dc.w    $180,$004    ; Color0
dc.w    $102,$011    ; bplcon1
dc.w    $108,-40*7    ; Bpl1Mod - mirrored 5 times
dc.w    $10a,-40*7    ; Bpl2Mod
dc.w    $b307,$fffe
dc.w    $180,$006    ; Colour0
dc.w    $102,$022    ; bplcon1
dc.w    $108,-40*6	; Bpl1Mod - mirrored 4 times
dc.w    $10a,-40*6    ; Bpl2Mod
dc.w    $b607,$fffe
dc.w    $180,$008    ; Color0
dc.w    $102,$033    ; bplcon1
dc.w    $108,-40*5    ; Bpl1Mod - mirror halved 3 times
dc.w    $10a,-40*5    ; Bpl2Mod
dc.w    $bb07,$fffe
dc.w    $180,$00a    ; Color0
dc.w    $102,$044    ; bplcon1
dc.w    $108,-40*4    ; Bpl1Mod - mirror halved twice
dc.w    $10a,-40*4	; Bpl2Mod
dc.w    $c307,$fffe
dc.w    $180,$00c    ; Color0
dc.w    $102,$055    ; bplcon1
dc.w    $108,-40*3    ; Bpl1Mod - mirror halved
dc.w    $10a,-40*3	; Bpl2Mod
dc.w    $d007,$fffe
dc.w    $180,$00e    ; Colour0
dc.w    $102,$066    ; bplcon1
dc.w    $108,-40*2    ; Bpl1Mod - normal mirror
dc.w    $10a,-40*2	; Bpl2Mod
dc.w    $d607,$fffe
dc.w    $180,$00f    ; Colour0
dc.w    $102,$077    ; bplcon1
dc.w    $108,-40    ; Bpl1Mod - FLOOD, repeated lines for
dc.w    $10a,-40	; Bpl2Mod - central enlargement effect
dc.w    $da07,$fffe
dc.w    $180,$00e    ; Colour0
dc.w    $102,$066    ; bplcon1
dc.w    $108,-40*2    ; Bpl1Mod - normal mirror
dc.w    $10a,-40*2    ; Bpl2Mod
dc.w    $e007,$fffe
dc.w    $180,$00c    ; Color0
dc.w    $102,$055	; bplcon1
dc.w    $108,-40*3    ; Bpl1Mod - halved mirror
dc.w    $10a,-40*3    ; Bpl2Mod
dc.w    $ed07,$fffe
dc.w    $180,$00a    ; Color0
dc.w    $102,$044	; bplcon1
dc.w    $108,-40*4    ; Bpl1Mod - mirror halved twice
dc.w    $10a,-40*4    ; Bpl2Mod
dc.w    $f507,$fffe
dc.w    $180,$008    ; Color0
dc.w	$102,$033	; bplcon1
dc.w	$108,-40*5
	
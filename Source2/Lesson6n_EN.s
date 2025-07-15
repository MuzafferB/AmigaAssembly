
; Lesson 6n.s    HORIZONTAL SCROLLING GREATER THAN 16 PIXELS, using BPLCON1
;        and BITPLANE POINTERS - RIGHT KEY TO MOVE LEFT

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6		; Execbase
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

btst    #2,$dff016    ; Right button pressed?
beq.s    GoLeft    ; if yes, go left!

bsr.w    Right        ; Moves the pic to the right by modifying
; the bplcon1 and bitplane pointers
bra.s    Wait

GoLeft:
bsr.w    Left    ; Moves the picture to the left.

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l	OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

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

; This routine scrolls a bitplane to the right by acting on BPLCON1 and on the
; pointers to the bitplanes in copperlist. MIOBPCON1 is the BPLCON1 byte.

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
clr.b    MIOBPCON1    ; resets the hardware scroll BPLCON1 ($dff102)
; in fact, we have ‘jumped’ 16 pixels with the
; bitplane pointer, now we have to start
; from scratch with $dff102 to move
; one pixel at a time to the right.

LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP2:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1        ; go to the next bplpointers in the COP
dbra    d1,POINTBP2    ; Repeat POINTBP times D1 (D1=number of bitplanes)
rts

CON1ADDA:
add.b    #$11,MIOBPCON1    ; scroll forward 1 pixel
rts

;    Routine that moves to the left in a similar way:

Left:
TST.B    MIOBPCON1    ; have we reached the minimum scroll? (00)
BNE.s    CON1SUBBA	; if not, scroll back 1
; with BPLCON1

LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where it is currently pointing
swap    d0        ; currently $dff0e0 and we point it to d0
move.w    6(a1),d0

addq.l    #2,d0        ; point 16 bits further (the PIC scrolls
; 16 pixels to the left)
move.b    #$FF,MIOBPCON1    ; hardware scroll to 15 - BPLCON1 ($dff102)

LEA    BPLPOINTERS,A1    ; pointers in COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP3:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1        ; go to the next bplpointers in the COP
dbra    d1,POINTBP3    ; Repeat POINTBP times D1 (D1=number of bitplanes)
rts

CON1SUBBA:
sub.b	#$11,MIOBPCON1    ; scroll back 1 pixel
rts


SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w	$8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102        ; BplCon1
dc.b    0        ; unused ‘high’ byte of $dff102
MIOBPCON1:
dc.b    0        ; used ‘low’ byte of $dff102
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
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
dc.w    $0188,$999	; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist


dcb.b    80*40,0    ; space cleared for bitplane scrolling

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,

dcb.b    40,0

end

The jerky display error on the left edge of the screen is horrible,
eh?
Removing it is not difficult, just change two little things, let's see how and why: the reason for this problem lies in the fact that
when moving the image without informing the DMA channels, we find them ‘unprepared’ and
they do not have time to read the first 16 pixels on the left properly.
What can we do to avoid this? Nothing.
However, we can make the mess happen outside the “visible screen”.
Remember DIWSTART and DIWSTOP? They determine the size of the window
where the data is displayed. It is clear that if we start the window
16 pixels further to the right, the problem is “plugged”:

dc.w    $8E,$2c91    ; DiwStrt ($81+16=$91)

Try changing the value and run the listing again. Even though
we have “plugged” the error, we now have a 304-pixel wide screen
instead of 320, and it is also off-centre!
But the DDFSTART and DDFSTOP registers come to our aid! These registers
also deal with the size of the video window, but in a different way.
 In fact, while DIWSTART/DIWSTOP is like a black card with
a resizable slot, as we can see in the figure below,

#####################
#####################
#####        #####
#####    figure #####
#####        #####
#####        #####
#####        #####
#####        #####
#####        #####
#####################
#####################

if we change the DDFSTART/STOP, we change the length of a video line.
For example, if we lengthen the screen by 16 pixels, making it
336 pixels per line, i.e. 42 bytes instead of 40, we will have to display an
image that is exactly 42 pixels wide per line.
The OVERSCAN mode, which enlarges the viewable image beyond the normal 320x256
or 640x256, is obtained with DDFSTART/STOP, remembering, of course, to
also ‘enlarge’ the window with DIWSTART/DISTOP.
Let's go back to the problem: we need to make sure that the 16-pixel error
is outside our view. Just start the screen with DDFSTART
16 pixels earlier, ending at the same position, and leave the
DIWSTART/DIWSTOP values normal, so we always see 320x256 pixels, but the
video window is actually 336 pixels wide and the error is occurring outside
our view. However, the figure becomes 42 bytes wide, so we have to
balance those 2 bytes (16 pixels) each line. How do we do this each line
(which now occurs at pixel 42) go back 2 to display the
line correctly? In short, to make the numbers add up? Just subtract 2 from the current module.
 In our case, with the module at ZERO, just put -2.
To start the screen 16 pixels earlier, you need to modify the DATA FETCH START (DDFSTRT) as follows
:

dc.w    $92,$30            ; DDFSTART = $30 (screen starts
; 16 pixels earlier, extending to
; 42 bytes per line, 336 pixels
; wide, but DIWSTART “hides”
; these first 16 pixels with the error.


dc.w    $108,-2            ; MODULES = -2, we must ‘skip’ the
dc.w    $10a,-2            ; first 16 pixels of each line
; making them read twice.


Make this change and put the DIWSTART back in place:

dc.w    $8E,$2c81    ; DiwStrt

Now the scroll is PERFECT. There is just one detail: increasing
the size of the video window using OVERSCAN cancels sprite 7,
i.e. the last sprite.

P.S: If you want to take a peek at the error that continues to exist in
OVERSCAN outside the window, start DIWSTART 16 pixels earlier:

dc.w    $8E,$2c71    ; DiwStrt

It's still there!!!! But no one can see it now.

See how easy it was to fix the error? Just start the DDFSTART (at $30) 16 pixels earlier
and subtract 2 from the value of the modules.

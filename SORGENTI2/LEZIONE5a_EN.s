
; Lesson 5a.s    MOVING A FIGURE TO THE RIGHT AND LEFT WITH $dff102

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

bsr.s    MoveCopper    ; scroll the figure to the right with $dff102
; and to the left (maximum 16 pixels)

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

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of the graphics library

OldCop:            ; Here goes the address of the old system COP
dc.l    0

;    This routine is similar to the one in Lesson3d.s, in this case
;    we modify the value of the scroll register BPLCON1 $dff102 to
;    scroll the figure forwards and backwards.
;    Since it is possible to act separately on even and odd bitplanes
;    to move all bitplanes we must move them
;    simultaneously: $0011,$0022,$0033 instead of $0001,$0002,$0003, which
;    would only move the odd bitplanes (1,3,5), or $0010,$0020,$0030, which
;    would only move the even bitplanes (2,4,6).
;    Try ‘=c 102’ to see the bits of $dff102

MoveCopper:
TST.B    FLAG        ; Should we move forward or backward? If
; FLAG is zero (i.e. TST checks
; BEQ)
; then we jump to AVANTI, if instead it is at $FF
; (i.e. if this TST is not verified)
; we continue moving backwards (with subs)
beq.w    AVANTI
cmpi.b    #$00,MIOCON1    ; we have reached the normal position, i.e.
; all backwards?
beq.s    MoveForward    ; if so, we must move forward!
sub.b    #$11,MIOCON1    ; subtract 1 from the bitplane scroll
rts            ; odd ($ff,$ee,$dd,$cc,$bb,$aa,$99....)
; going to the LEFT
MoveForward:
clr.b    FLAG        ; Resetting FLAG, at TST.B FLAG the BEQ
rts            ; will jump to the FORWARD routine, and
; the figure will move forward (to the right)

FORWARD:
cmpi.b    #$ff,MIOCON1    ; we have reached the maximum scroll in
; forward, i.e. $FF? ($f even and $f odd)
beq.s    PutBackward    ; if so, we must go back
add.b    #$11,MIOCON1    ; add 1 to the bitplane scroll
; even and odd ($11,$22,$33,$44 etc..)
rts            ; GOING RIGHT

MoveBack:
move.b    #$ff,FLAG    ; When the FLAG label is not zero,
rts            ; it means we have to go back
; to the left

;    This byte is a FLAG, i.e. it is used to indicate whether to go forward or
;    backward.

FLAG:
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


dc.w    $102        ; BplCon1 - THE REGISTER
dc.b    $00        ; BplCon1 - THE UNUSED BYTE!!!
MIOCON1:
dc.b    $00        ; BplCon1 - THE USED BYTE!!!


dc.w    $104,0		; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210    ; BPLCON0:
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)
; 3 lowres bitplanes, no lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane - BPL0PT
dc.w $e4,$0000,$e6,$0000    ;second bitplane - BPL1PT
dc.w $e8,$0000,$ea,$0000    ;third bitplane - BPL2PT

dc.w $0180,$000; colour0
dc.w $0182,$475; colour1
dc.w $0184,$fff; colour2
dc.w $0186,$ccc; colour3
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

Moving the screen forward by 16 pixels on the Amiga is a piece of cake! Just
change one byte, the one in $dff102, and you're done. On other
computer graphics systems such as the PC MSDOS, however, you have to modify the entire
figure and ‘move’ it, with lots of instructions that slow everything down.
In addition, you can move the even and odd planes separately
to easily create parallax effects. Just scroll the background, made up of the odd bitplanes, more slowly
and the foreground, made up of the even bitplanes, more quickly.
It's no coincidence that to create parallax on a PC, you need to use very complicated and slow routines.
Let's check that it's possible to scroll the even and odd bitplanes separately with these two modifications.
Let's check that it is possible to scroll the even and odd bitplanes separately
with these two changes; to scroll ONLY the EVEN bitplanes (here there is only 2),
 change these instructions


sub.b    #$11,MIOCON1    ; subtract 1 from the bitplane scroll

cmpi.b    #$ff,MIOCON1    ; we have reached the maximum scroll in

add.b    #$11,MIOCON1    ; add 1 to the bitplane scroll
; even and odd ($11,$22,$33,$44 etc..)

in this way:


sub.b    #$10,MIOCON1	; only the EVEN planes!

cmpi.b    #$f0,MIOCON1

add.b    #$10,MIOCON1

You will notice that only one bitplane moves, the 2, while the first and third
remain in place. When moving, bitplane 2 remains ‘uncovered’,
i.e. it loses its overlap with the other two, showing its ‘TRUE FACE’
and taking on COLOUR2, which is $FFF in the copperlist as you can see,
in fact it is white. It takes on colour2 because when bitplane 2 moves, it
is ‘alone’ with the background, i.e.: %010, with bitplanes 1 and 3 reset to zero.
The binary number %010 is equivalent to 2, so its colour will be determined by
colour register 2, $dff184. Change its value in the copperlist and
you will see that bitplane 2 “alone” is controlled by that
register:

dc.w    $0184,$fff    ; colour2

In fact, if you put, for example, a $ff0, it will turn yellow. On the other hand, the figure
remains ‘HOLED’ in the points where bitplane2 ‘GOES AWAY’. You can see this better
by pressing the right mouse button to stop scrolling: in particular, the holes
can be seen where WHITE appears, i.e. where there was only bitplane2 without
overlaps. In other cases, instead of forming a HOLE, the colour changes.

To scroll only the ODD bitplanes (1 and 3 in our figure),
modify the routine as follows:

subq.b    #$01,MIOCON1    ; only the ODD planes!

cmpi.b    #$0f,MIOCON1

addq.b    #$01,MIOCON1

In this case, bitplane 2, the only even one, remains stationary, and planes
1 and 3, the odd ones, move.
With these examples, you have also been able to verify the method of overlapping
bitplanes to display different colours.


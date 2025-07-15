
; Lesson 3c.s    ; BAR THAT GOES DOWN MADE WITH COPPER'S MOVE&WAIT
; (TO MAKE IT GO DOWN, USE THE RIGHT MOUSE BUTTON)

SECTION    SECONDCOP,CODE    ; also works in Fast

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary, EXEC routine that opens
; the libraries and outputs the base address
; of the library from which to calculate
; the addressing distances (Offset)
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the system copperlist
;
move.l    #COPPERLIST,$dff080    ; COP1LC - Point to our COP
move.w    d0,$dff088        ; COPJMP1 - Start the COP

mouse:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we on line 255?
bne.s    mouse        ; If not, don't continue

btst    #2,$dff016    ; POTINP - Is the right mouse button pressed?
bne.s    Wait        ; If not, do not execute Muovicopper

bsr.s    MuoviCopper    ; The first movement on the screen!!!!!
; This subroutine lowers WAIT!
; and is executed once every video screen
; in fact bsr.s Muovicopper causes
; the routine named Muovicopper to be executed,
; at the end of which, with RTS, the 68000
; returns here to execute the Wait routine,
; and so on.


Wait:            ; if we are still at the $ff line we
; waited for before, do not continue.

cmpi.b    #$ff,$dff006    ; are we still at $FF? If so, wait for the
beq.s    Wait        ; next line ($00), otherwise MoveCopper is
; re-executed. This problem only occurs for
; very short routines that can be
; executed in less than ‘one line of the electronic brush
;’, called ‘raster line’: the
; mouse cycle: wait for the $FF line, then
; execute MoveCopper, but if it is executed too
; quickly, we always find ourselves at the $FF line
; and when we return to the mouse, at line $FF
; we are already there, and MoveCopper is re-executed,
; so the routine is executed more than once
; per FRAME!!! Especially on A4000!
; this check avoids the problem by waiting
; for the next line, so when returning to the mouse:
; to reach line $ff, you need
; the classic fiftieth of a second.
; NOTE: All monitors and televisions
; draw the screen at the same speed,
; while from computer to computer,
; the processor speed may vary. This is why
; that a timed program with $dff006
; runs at the same speed on an A500 and
; an A4000. Timing will be
; discussed in more detail later, for now
; just worry about understanding the copper and
; how it works.


btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, go back to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
; (libraries must be opened and closed!!!)
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts

;
;    This small routine lowers the copper wait by increasing it.
;    In fact, the first time it is executed, it will change the
;
;    dc.w    $2007,$FFFE    ; wait for line $20
;
;    in:
;
;    dc.w    $2107,$FFFE	; wait for line $21! (then $22, $23, etc.)
;
;    NOTE: once the maximum value for a byte has been reached, i.e. $FF,
;     if you execute another ADDQ.B #1,BARRA, it starts again from 0,
; until it returns to $ff and so on.

Muovicopper:
addq.b    #1,BARRA    ; WAIT 1 changed, the bar goes down 1 line
rts

; Try changing this ADDQ to SUBQ and the bar will go up!!!!

; Try changing the addq/subq #1,BARRA to #2, #3 or more and the speed
; will increase, since each FRAME the wait will move by 2, 3 or more lines.
; (if the number is greater than 8, use ADD.B instead of ADDQ.B)


;    DATA...


GfxName:
dc.b    ‘graphics.library’,0,0    ; NOTE: to put characters in memory
; always use dc.b
; and put them between ‘’, or “”

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0


;    GRAPHICS DATA...


SECTION    GRAPHIC,DATA_C    ; This command causes the operating system to load
; this segment of data
; into CHIP RAM, which is mandatory
; The copperlists MUST be in CHIP RAM!

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - no bitplanes, only background.

dc.w    $180,$004    ; COLOR0 - Start the cop with the colour DARK BLUE

BAR:
dc.w    $7907,$FFFE    ; WAIT - wait for line $79

dc.w    $180,$600    ; COLOR0 - start the red area: red at 6

dc.w    $FFFF,$FFFE    ; END OF COPPERLIST

end


Ahh! I forgot to put the (PC) in ‘lea GfxName,a1’, but now it's there.
Anyone who noticed that it could be added gets a gold star.
In this programme, a movement synchronised with the
electronic brush is performed, causing the bar to descend smoothly.

NOTE1: In this listing, the structure of the cycle may be confused with the mouse test
plus the electronic brush position test; what
you need to understand is that the routines, or subroutines, found between
the mouse loop: and the wait loop: are executed once every video frame:
try replacing bsr.s Muovicopper with the subroutine itself,
without the final RTS, of course:

mouse:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we at line 255?
bne.s    mouse        ; If not, do not continue

;    bsr.s    MuoviCopper    ; A routine executed every frame
;                ; (For fluidity)

addq.b    #1,BARRA    ; WAIT 1 changed, the bar goes down 1 line

Wait:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we at line 255?
beq.s	Wait        ; If so, don't continue, wait for the
; next line, otherwise MoveCopper is
; re-executed

In this case, the result does not change because instead of executing ADDQ as a
subroutine, we execute it directly, and perhaps in this case it is even more
convenient; but when the subroutines are longer, it is better to use several BSRs to
find your way around. For example, if you duplicate the bsr.s Muovicopper, the routine will be
executed twice per frame, and will double the speed:

bsr.s    MuoviCopper    ; A routine executed every frame
bsr.s    MuoviCopper    ; A routine executed every frame

The usefulness of subroutines lies precisely in the greater clarity of the program.
Imagine if our routines to be placed between mouse: and wait: were
thousands of lines long! The sequence of events would appear less clear. Instead,
 if we call each routine by name, everything will appear easier.

*

To lower the bar, simply change the COPPERLIST, specifically
in this example, the WAIT is changed in its first byte, i.e. the one
that defines the vertical line to wait for:

BAR:
dc.w    $2007,$FFFE    ; WAIT - wait for line $20
dc.w    $180,$600    ; COLOR0 - start the red zone: red at 6

By putting a label on that byte, you can change that byte by acting on the
label itself, in this case BAR.

CHANGES:
Try changing the colour instead of the wait: just put a label
where you want in the copperlist and you can change whatever you want.
Put a bar on the colour like this:

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - no bitplanes, only background.

dc.w    $180,$004    ; COLOUR0 - Start the copy with the colour DARK BLUE

;;;;BAR:            ; ** CANCEL THE OLD LABEL with ;;
dc.w    $7907,$FFFE    ; WAIT - wait for line $79

dc.w    $180        ; COLOUR0
BAR:                ; ** SET THE NEW LABEL TO THE COLOUR VALUE.
dc.w    $600    ; start the red area: red at 6

dc.w    $FFFF,$FFFE    ; END OF THE COPPERLIST

You will obtain a variation in the intensity of the red, because we are changing the
first byte to the left of the colour: $0RGB, i.e. $0R, i.e. RED!!!!

Now try acting on the entire WORD of the colour: change the routine as follows:

addq.w    #1,BAR    ; instead of .b, we operate on .w
rts

Try it and you will see that the colours follow each other irregularly, because
they are the result of the increasing number: $601,$602... $631,$632... generating
colours in no particular order.

NOTE:    the dc.w command stores bytes, words or longs in memory,
so you can get the same result by writing:

dc.w    $180,$600    ; Colour0

or:

dc.w    $180    ; Register Colour0
dc.w    $600    ; value of colour0

There are no syntax problems as with MOVE.


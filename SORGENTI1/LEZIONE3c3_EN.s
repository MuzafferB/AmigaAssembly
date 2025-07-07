
; Lesson3c3.s    ; BAR THAT MOVES DOWN USING COPPER'S MOVE&WAIT
; (TO MOVE IT DOWN, USE THE RIGHT MOUSE BUTTON)


SECTION    SfumaCop,CODE    ; Fast is also fine

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary, EXEC routine that opens
; the libraries and outputs the
; base address of the library from which to calculate
; the addressing distances (Offset)
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the system copperlist
;
move.l    #COPPERLIST,$dff080    ; COP1LC - Point to our COP
move.w    d0,$dff088        ; COPJMP1 - Start the COP
mouse:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we at line 255?
bne.s    mouse        ; If not, don't continue

btst    #2,$dff016    ; POTINP - Is the right mouse button pressed?
bne.s    Wait        ; If not, don't execute Muovicopper

bsr.s    MoveCopper    ; 1-frame timed routine

Wait:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we at line 255?
beq.s    Wait        ; If yes, do not continue, wait for the
; next line, otherwise MoveCopper is
; re-executed

btst	#6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

move.l    OldCop(PC),$dff080    ; COP1LC - Point to the system cop
move.w    d0,$dff088        ; COPJMP1 - Start the cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
; (libraries must be opened and closed!!!)
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts


;    This routine moves a bar consisting of 10 waits down

MuoviCopper:
cmpi.b    #$fa,BARRA10    ; have we reached line $fa?
beq.s	Finished        ; if so, we are at the bottom and do not continue
addq.b    #1,BARRA    ; WAIT 1 changed
addq.b    #1,BARRA2    ; WAIT 2 changed
addq.b    #1,BARRA3    ; WAIT 3 changed
addq.b    #1,BARRA4    ; WAIT 4 changed
addq.b    #1,BARRA5    ; WAIT 5 changed
addq.b    #1,BARRA6    ; WAIT 6 changed
addq.b    #1,BARRA7    ; WAIT 7 changed
addq.b    #1,BARRA8    ; WAIT 8 changed
addq.b    #1,BARRA9    ; WAIT 9 changed
addq.b    #1,BARRA10	; WAIT 10 changed
Finished:
rts

; From here we put the data...


GfxName:
dc.b    ‘graphics.library’,0,0    ; NOTE: to put characters in memory
; always use dc.b
; and put them between ‘’, or “”

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of the graphics.library

OldCop:            ; Here goes the address of the old system COP
dc.l    0


; Here is the COPPERLIST, pay attention to the BARRA labels!!!!


SECTION    CoppyMagic,DATA_C ; The copperlists MUST be in CHIP RAM!

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - background colour only
dc.w    $180,$000    ; COLOR0 - Start the copy with the colour BLACK

BAR:
dc.w    $7907,$FFFE    ; WAIT - wait for line $79
dc.w    $180,$300    ; COLOR0 - start the red bar: red at 3
BAR2:
dc.w    $7a07,$FFFE    ; WAIT - next line
dc.w    $180,$600	; COLOUR0 - red at 6
BAR 3:
dc.w    $7b07,$FFFE
dc.w    $180,$900    ; red at 9
BAR 4:
dc.w    $7c07,$FFFE
dc.w    $180,$c00    ; red at 12
BAR5:
dc.w    $7d07,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
BAR6:
dc.w    $7e07,$FFFE
dc.w    $180,$c00    ; red at 12
BAR7:
dc.w    $7f07,$FFFE
dc.w    $180,$900    ; red at 9
BAR8:
dc.w    $8007,$FFFE
dc.w    $180,$600    ; red at 6
BAR9:
dc.w    $8107,$FFFE
dc.w    $180,$300    ; red at 3
BAR 10:
dc.w    $8207,$FFFE
dc.w    $180,$000    ; colour BLACK

dc.w    $FFFF,$FFFE    ; END OF COPPERLIST


end

To lower the bar, simply change the COPPERLIST, in particular
in this example, the various WAITs that make up the bar are changed in
their first byte, i.e. the one that defines the vertical line to wait for:

BAR:
dc.w    $7907,$FFFE    ; WAIT - wait for line $79
dc.w    $180,$300	; COLOR0 - start the red bar: red at 3
BAR:
dc.w    $7a07,$FFFE    ; next line
dc.w    $180,$600    ; red at 6
...

By putting a label on that byte, you can change that byte by acting on the
label itself, in this case BAR.

*******************************************************************************

I recommend making many changes, even random ones, to
familiarise yourself with COPPER: Here are a few suggestions:

CHANGE 1: try putting ; at the first 5 ADDQ.b like this:

;    addq.b    #1,BARRA    ; WAIT 1 changed
;    addq.b    #1,BARRA2    ; WAIT 2 changed
;    addq.b    #1,BARRA3	; WAIT 3 changed
;    addq.b    #1,BARRA4    ; WAIT 4 changed
;    addq.b    #1,BARRA5    ; WAIT 5 changed
addq.b    #1,BARRA6    ; WAIT 6 changed
addq.b    #1,BARRA7    ; WAIT 7 changed
....

You will get the ‘CURTAIN FALLS’ effect, in fact the descent starts like this
from the middle of the bar, and, since the last colour is valid until it
is changed, in this case the last colour before the wait of the lower part
of the bar that goes to the bottom is RED, so it looks like the bar
extends to the bottom of the screen. Remove the ; and let's move on to modification 2.

MODIFICATION 2: To get a ‘ZOOM’ effect, modify as follows: (use Amiga+b+c+i)

addq.b    #1,BAR
addq.b    #2,BAR2
addq.b    #3,BAR3
addq.b    #4,BARRA4
addq.b    #5,BARRA5
addq.b    #6,BARRA6
addq.b    #7,BARRA7
addq.b    #8,BARRA8
addq.b    #8,BARRA9
addq.b    #8,BARRA10

Do you understand why the bar expands? Because instead of going down
together, the waits have different “speeds”, so the lower ones move away
from the higher ones.


MODIFICATION 3: This time we will “expand” the bar not downwards, as in the
previous case, but centrally:

subq.b    #5,BAR
subq.b    #4,BAR2
subq.b    #3,BAR3
subq.b    #2,BAR4
subq.b    #1,BAR5
addq.b    #1,BAR6
addq.b    #2,BAR7
addq.b    #3,BAR8
addq.b    #4,BAR9
addq.b    #5,BARRA10

In fact, we changed the first 5 addq to subq, so the upper part
of the bar in this case rises instead of falling, and rises in a similar way
to the previous ‘zoom’, in fact the ‘speeds’ are 5,4,3,2,1,
while the 5 addq do the same for the lower part.


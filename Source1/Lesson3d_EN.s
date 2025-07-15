
; Lesson 3d.s    BAR THAT GOES UP AND DOWN MADE WITH COPPER'S MOVE&WAIT

;    In this listing, a label is used as a FLAG, i.e. as a
;    signal to indicate whether the bar should go up
;    or down. Carefully analyse how this
;    programme works, as it is the first in the course that may present problems
;    in terms of conditional loops.


SECTION    CiriCop,CODE    ; Fast is also fine

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to be opened in a1
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
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we at line 255?
bne.s    mouse        ; If not, don't continue

bsr.s	MoveCopper    ; A routine that moves the bar up and down

Wait:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we at line 255?
beq.s    Wait        ; If yes, do not continue, wait for the
; next line, otherwise MoveCopper is
; re-executed

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

move.l    OldCop(PC),$dff080    ; COP1LC - Point to the system cop
move.w    d0,$dff088		; COPJMP1 - start the cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
; (libraries must be opened and closed!!!)
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts

;
;
;
;


MoveCopper:
LEA    BARRA,a0
TST.B    SuGiu        ; Should we go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then we jump to VAIGIU, if instead it is at $FF
; (i.e. if this TST is not verified)
; we continue going up (doing subq)
beq.w    VAIGIU
cmpi.b    #$82,8*9(a0)    ; have we reached line $82?
beq.s    MettiGiu    ; if so, we are at the top and we have to go down
subq.b    #1,(a0)
subq.b    #1,8(a0)    ; now we change the other waits: the distance
subq.b    #1,8*2(a0)	; between one wait and the next is 8 bytes
subq.b    #1,8*3(a0)
subq.b    #1,8*4(a0)
subq.b    #1,8*5(a0)
subq.b    #1,8*6(a0)
subq.b    #1,8*7(a0)    ; here we have to modify all 9 waits of the
subq.b    #1,8*8(a0)    ; red bar each time to make it go up!
subq.b    #1,8*9(a0)
rts

MettiGiu:
clr.b    SuGiu		; Resetting SuGiu, at TST.B SuGiu the BEQ
rts            ; will jump to the VAIGIU routine, and
; the bar will drop

VAIGIU:
cmpi.b    #$fc,8*9(a0)    ; have we reached line $fc?
beq.s	MettiSu        ; if so, we are at the bottom and we have to go back up
addq.b    #1,(a0)
addq.b    #1,8(a0)    ; now we change the other waits: the distance
addq.b    #1,8*2(a0)    ; between one wait and another is 8 bytes
addq.b    #1,8*3(a0)
addq.b    #1,8*4(a0)
addq.b    #1,8*5(a0)
addq.b    #1,8*6(a0)
addq.b    #1,8*7(a0)    ; here we have to modify all 9 waits of the
addq.b    #1,8*8(a0)    ; red bar each time to make it go down!
addq.b    #1,8*9(a0)
rts

PutUp:
move.b    #$ff,SuGiu    ; When the SuGiu label is not zero,
rts            ; it means we have to go back up.


;    This byte, indicated by the SuGiu label, is a FLAG, i.e. a
;    flag (in jargon), in fact once it is at $ff and another time it is at
;    $00, depending on the direction to follow (up or down!). It is just
;    like a flag, which when lowered ($00) indicates that we must
;    go down and when it is raised ($FF) we must go up. In fact,
;    a comparison of the line reached is performed to check whether
;    we have reached the top or the bottom, and if we have, we change
;    direction (with clr.b SuGiu or move.b #$ff,Sugiu)

SuGiu:
dc.b    0,0

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

SECTION    GRAPHIC,DATA_C    ; This command causes the operating system to load
; this segment of data
; into CHIP RAM, which is mandatory
; The copperlists MUST be in CHIP RAM!

COPPERLIST:
dc.w    $100,$200    ; BPLCON0
dc.w    $180,$000    ; COLOR0 - Start the cop with the colour BLACK
dc.w    $4907,$FFFE    ; WAIT - Wait for line $49 (73)
dc.w    $180,$001	; COLOR0 - very dark blue
dc.w    $4a07,$FFFE    ; WAIT - line 74 ($4a)
dc.w    $180,$002    ; slightly more intense blue
dc.w    $4b07,$FFFE    ; line 75 ($4b)
dc.w    $180,$003    ; lighter blue
dc.w    $4c07,$FFFE    ; next line
dc.w    $180,$004    ; lighter blue
dc.w    $4d07,$FFFE    ; next line
dc.w    $180,$005    ; lighter blue
dc.w    $4e07,$FFFE	; next line
dc.w    $180,$006    ; blue at 6
dc.w    $5007,$FFFE    ; skip 2 lines: from $4e to $50, i.e. from 78 to 80
dc.w    $180,$007    ; blue at 7
dc.w    $5207,$FFFE    ; 2 lines
dc.w    $180,$008    ; blue at 8
dc.w    $5507,$FFFE    ; jump 3 lines
dc.w    $180,$009    ; blue at 9
dc.w    $5807,$FFFE    ; jump 3 lines
dc.w    $180,$00a    ; blue at 10
dc.w    $5b07,$FFFE    ; jump 3 lines
dc.w    $180,$00b    ; blue at 11
dc.w    $5e07,$FFFE    ; jump 3 lines
dc.w    $180,$00c    ; blue at 12
dc.w    $6207,$FFFE    ; jump 4 lines
dc.w    $180,$00d    ; blue at 13
dc.w    $6707,$FFFE	; jump 5 lines
dc.w    $180,$00e    ; blue at 14
dc.w    $6d07,$FFFE    ; jump 6 lines
dc.w    $180,$00f    ; blue at 15
dc.w    $780f,$FFFE    ; line $78
dc.w    $180,$000    ; colour BLACK

BAR:
dc.w    $7907,$FFFE    ; wait for line $79
dc.w    $180,$300    ; start red bar: red at 3
dc.w    $7a07,$FFFE	; next line
dc.w    $180,$600    ; red at 6
dc.w    $7b07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $7c07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $7d07,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
dc.w    $7e07,$FFFE
dc.w    $180,$c00	; red at 12
dc.w    $7f07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $8007,$FFFE
dc.w    $180,$600    ; red at 6
dc.w    $8107,$FFFE
dc.w    $180,$300    ; red at 3
dc.w    $8207,$FFFE
dc.w    $180,$000    ; colour BLACK

dc.w    $fd07,$FFFE	; wait for line $FD
dc.w    $180,$00a    ; blue intensity 10
dc.w    $fe07,$FFFE    ; next line
dc.w    $180,$00f    ; blue maximum intensity (15)
dc.w    $FFFF,$FFFE    ; END OF COPPERLIST


end

Now the bar moves up and down, using a label that indicates
whether we are going up or down: if the SuGiu label is reset,
the instructions that lower the bar are executed; if it is not reset,
the instructions that raise it are executed. 
At the beginning, the label is at zero,
then the ADDQ instructions are executed, which make it go down until, once
it reaches the bottom, the SuGiu label is written with a $FF, then
in the following cycles, when the TST.b SuGiu, the 
series of SUBQs that raise it are executed until it reaches the top, at which point
the SuGiu label is reset, then the ADDQs that lower it are executed again, and so on.
With this routine, you can easily check the effects of the changes: Try putting a ; on the instructions that wait for the $FF line with $dff006: mouse: cmpi.b    #$ff,$dff
With this routine, you can clearly see the effects of the changes:
Try putting a ; on the instructions that wait for the $FF line with $dff006:

mouse:
cmpi.b    #$ff,$dff006    ; VHPOSR
;    bne.s    mouse        ; If not yet, do not continue

bsr.s    MoveCopper

Wait:
cmpi.b    #$ff,$dff006    ; VHPOSR
;    beq.s    Wait


This way we lose synchronisation with the video, and the bar goes
crazy, try running it like this!!! As you may have noticed, you don't even
have time to see its movement! Especially if you have an
Amiga 1200 or a faster computer.
Now we will make the bar move slower by executing it once every
two frames instead of once per frame: make this change:
(Also remove the ‘Wait:’ loop)

mouse:
cmpi.b    #$ff,$dff006    ; Are we on line 255?
;    bne.s    mouse        ; If not, don't go on

frame:
cmpi.b    #$fe,$dff006    ; Are we on line 254? (it has to go back!)
bne.s    frame        ; If not yet, do not continue

bsr.s    MoveCopper

;Wait:    ; removed, there is no longer any risk...
;    cmpi.b    #$ff,$dff006
;    beq.s    Wait    

In this case, two frames of time are lost. In fact, when the electronic brush
reaches line $ff, i.e. 255, the first loop is passed,
and the frame loop is entered, which waits for it to reach line 254!!!
! To get there, however, it must reach the end, start again from the beginning and reach 254,
so in total 2 frames are expected, i.e. 2 complete brush strokes.
In fact, by executing the modified listing, you will notice that the speed is
halved. To make it go even slower, you can lose 3 frames:

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't go on
frame:
cmpi.b    #$fe,$dff006    ; Are we at line 254? (it must repeat the cycle!)
bne.s    frame        ; If not yet, do not continue
frame2:
cmpi.b    #$fd,$dff006    ; Are we at line 253? (it must repeat the cycle!)
bne.s    frame2        ; If not yet, do not continue
bsr.s    MoveCopper
...

Using the same method, this time when we reach line 254, we ask it
to go to line 253, which costs another whole frame.

To check which line you have reached, when you exit by pressing the MOUSE
key, try pressing ‘M BAR’, and you will see the last value that WAIT had.


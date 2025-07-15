
; Lesson3c4.s    ; BAR THAT MOVES DOWN USING COPPER'S MOVE&WAIT
; (TO MOVE IT DOWN, USE THE RIGHT MOUSE BUTTON)

;    In this listing, a real
;    gradient bar composed of 10 waits is moved down, so you are acting on 10 waits!
;    The difference with Lesson3c3.s lies in the use of a single label
;    BAR instead of 10 labels, thanks to the addressing distance.

SECTION    RedBar,CODE    ; Fast is also fine

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary, EXEC routine that opens
; the libraries and outputs the
; base address of the library from which to take the
; addressing distances (Offset)
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the system copperlist
;
move.l    #COPPERLIST,$dff080	; COP1LC - Point to our COP
move.w    d0,$dff088        ; COPJMP1 - Start the COP
mouse:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we on line 255?
bne.s    mouse        ; If not, do not continue

btst    #2,$dff016    ; POTINP - Right mouse button pressed?
bne.s    Wait        ; If not, do not execute Muovicopper

bsr.s    MuoviCopper    ; Increasingly difficult

Wait:
cmpi.b    #$ff,$dff006    ; VHPOSR - Are we at line 255?
beq.s    Wait        ; If yes, do not continue, wait for the
; next line, otherwise MoveCopper is
; re-executed

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

move.l    OldCop(PC),$dff080    ; COP1LC - Point to the system cop
move.w    d0,$dff088        ; COPJMP1 - Start the cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - Re-enable multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
; (libraries must be opened and closed!!!)
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts


;    This routine moves a bar composed of 10 waits

MuoviCopper:
LEA	BARRA,a0    ; put the address of BARRA in a0:
cmpi.b    #$fc,8*9(a0)    ; have we reached line $fc?
beq.s    Finished        ; if so, we are at the end and do not continue
addq.b    #1,(a0)        ; WAIT 1 changed (indirect without distance)
addq.b    #1,8(a0)    ; now we change the other waits: the distance
addq.b    #1,8*2(a0)    ; between one wait and another is 8 bytes, in fact
addq.b    #1,8*3(a0)    ; dc.w $xx07,$FFFE,$180,$xxx is a long.
addq.b    #1,8*4(a0)    ; so if from the address of the first wait
addq.b    #1,8*5(a0)    ; we make an addressing distance of
addq.b    #1,8*6(a0)    ; 8, we modify the following dc.w $xx07,$fffe.
addq.b    #1,8*7(a0)    ; here we have to modify all 9 waits of the
addq.b    #1,8*8(a0)    ; red bar each time to make it go down!
addq.b    #1,8*9(a0)    ; last wait! (the BARRA10 of the previous source)
Finished:
rts    ; P.S: With this RTS, we return to the MOUSE cycle that waits
; for the timing.

;    NOTE: ‘*’ means ‘multiplied’, ‘/’ means “divided”

; data

GfxName:
dc.b    ‘graphics.library’,0,0    ; NOTE: to store
; characters in memory, always use dc.b
; and put them between ‘’, or “”

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

SECTION    GRAPHIC,DATA_C    ; The copperlists MUST be in CHIP RAM!

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - no bitplanes
dc.w    $180,$000    ; COLOR0 - Start the cop with the colour BLACK

BAR:
dc.w    $7907,$FFFE    ; WAIT - wait for line $79
dc.w    $180,$300    ; COLOUR0 - start the red bar: red at 3
dc.w    $7a07,$FFFE    ; WAIT - next line
dc.w    $180,$600    ; COLOR0 - red at 6
dc.w    $7b07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $7c07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $7d07,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
dc.w    $7e07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $7f07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $8007,$FFFE
dc.w    $180,$600    ; red at 6
dc.w    $8107,$FFFE
dc.w    $180,$300    ; red at 3
dc.w    $8207,$FFFE
dc.w    $180,$000    ; colour BLACK

dc.w    $FFFF,$FFFE    ; END OF COPPERLIST


end

To lower the bar, simply change the COPPERLIST, in particular
in this example, the various WAITs that make up the bar are changed in
their first byte, i.e. the one that defines the vertical line to wait for:

BAR:
dc.w    $7907,$FFFE    ; WAIT - wait for line $79
dc.w    $180,$300    ; COLOUR0 - start the red bar: red at 3
dc.w    $7a07,$FFFE    ; next line
dc.w    $180,$600    ; red at 6
...

By putting a label on that byte, you can change that byte by acting on the
label itself, in this case BARRA. However, the bar in question is made up
of 9 wait+colour0, so to ‘move’ it you have to change all 9
waits, while the colour0 (dc.w $180,$xxx) found under the waits remain
unchanged. To reach all 9 WAITs, instead of putting a LABEL
on all of them, it is faster to load the address of the first one into a register and
change the others by making addressing distances:

MoveCopper:
LEA    BARRA,a0
cmpi.b    #$fc,8*9(a0)    ; let's check the last wait, the one that
beq.s    Finito        ; defines the lower part of the bar.
addq.b    #1,(a0)        ; change BARRA:
addq.b    #1,8(a0)    ; change byte 2 long after BARRA:
addq.b    #1,8*2(a0)    ; change byte 4 long after BARRA:
addq.b	#1,8*3(a0)    ; change byte 6 long after...
addq.b    #1,8*4(a0)
addq.b    #1,8*5(a0)
addq.b    #1,8*6(a0)
addq.b    #1,8*7(a0)
addq.b    #1,8*8(a0)
addq.b    #1,8*9(a0)
Finished:
rts

NOTE: Try doing a ‘D MoveCopper’, and you will see that the 8*2,8*3 etc.
are assembled as:

ADDQ.B    #1,$8(A0)
ADDQ.B	#1,$10(A0)
ADDQ.B    #1,$18(A0)
ADDQ.B    #1,$20(A0)
ADDQ.B    #1,$28(A0)

That is, with the result of 8*2 (i.e. 16, or $10), of 8*3 ($18)...

As a final change, try changing the $fc in the line

cmpi.b    #$fc,8*9(a0)

By entering lower values, you will see that the bar drops to the
line you specify.


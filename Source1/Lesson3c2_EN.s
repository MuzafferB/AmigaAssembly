
; Lesson3c2.s    ; BAR THAT MOVES DOWN USING COPPER'S MOVE&WAIT
; (TO MOVE IT DOWN, USE THE RIGHT MOUSE BUTTON)

; Added a check for when the line is reached to stop scrolling


SECTION    MaremmaCop,CODE    ; also works in Fast

Start:
	move.l    4.w,a6        ; Execbase in a6
	jsr    -$78(a6)    		; Disable - stops multitasking
	lea    GfxName(PC),a1   ; Address of the name of the lib to open in a1
	jsr    -$198(a6)    	; OpenLibrary, EXEC routine that opens
							; the libraries and outputs the
							; base address of the library from which to calculate
							; the addressing distances (Offset)
	move.l    d0,GfxBase    ; save the GFX base address in GfxBase
	move.l    d0,a6
	move.l    $26(a6),OldCop    ; save the address of the system copperlist
	move.l    #COPPER,$dff080   ; COP1LC - Point to our COP
	move.w    d0,$dff088        ; COPJMP1 - Start the COP


mouse:
	cmpi.b    #$ff,$dff006  ; VHPOSR - Are we at line 255?
	bne.s    mouse          ; If not, don't continue
 
	btst    #2,$dff016    	; POTINP - Is the right mouse button pressed?
	bne.s    Wait        	; If not, do not execute MoveCopper

	bsr.s    MoveCopper     ; This subroutine lowers WAIT!
							; and is executed once per video screen
Wait:
	cmpi.b    #$ff,$dff006  ; VHPOSR - Are we at line 255?
	beq.s    Wait        	; If yes, do not continue, wait for the
							; next line, otherwise MoveCopper is
							; re-executed

	btst    #6,$bfe001    ; left mouse button pressed?
	bne.s    mouse        ; if not, return to mouse:

	move.l    OldCop(PC),$dff080    ; COP1LC - Point to the system cop
	move.w    d0,$dff088        	; COPJMP1 - Start the cop

	move.l    4.w,a6        ; Execbase in A6
	jsr    -$7e(a6)    		; Enable - re-enable Multitasking
	move.l    gfxbase(PC),a1    ; Base of the library to close
								; (libraries must be opened and closed!!!)
	jsr    -$19e(a6)    ; Closelibrary - close the graphics library
	rts

;
;	This small routine decreases the copper wait by increasing it,
;    in fact, the first time it is executed, it will change the
;
;    dc.w    $2007,$FFFE    ; WAIT - wait for line $20
;
;    in:
;
;    dc.w    $2107,$FFFE    ; WAIT - wait for line $21!
;
;    and so on, up to the specified maximum, in this case $fc
;

MoveCopper:
	cmpi.b    #$fc,BAR    ; have we reached line $fc?
	beq.s    Finished     ; if so, we are at the end and do not continue
	addq.b    #1,BAR	  ; WAIT 1 changed, the bar goes down 1 line

Finished:
	rts

;    In this case, if BAR: has reached the value $fc, skip addq
;    P.S: for now, you cannot reach the final part of the
;    screen after $FF. I will explain why and how to do this later.

GfxName:
	dc.b    ‘graphics.library’,0,0  ; NOTE: to put characters in memory
									; always use dc.b
									; and put them between ‘’, or “”

GfxBase:         ; Here goes the base address for the Offsets
	dc.l    0    ; of the graphics.library

OldCop:          ; This is where the address of the old system COP goes
	dc.l    0

	SECTION    MyCoppy,DATA_C    ; The copperlists MUST be in CHIP RAM!

COPPER:
	dc.w    $100,$200    ; BPLCON0 - no bitplanes, only background.

	dc.w    $180,$004    ; COLOR0 - Start the cop with DARK BLUE

BAR:
	dc.w    $7907,$FFFE    ; WAIT - wait for line $79

	dc.w    $180,$600      ; COLOR0 - start the red area: red at 6

	dc.w    $FFFF,$FFFE    ; END OF COPPERLIST

	END

As a modification, try changing the $fc of the line

	cmpi.b    #$fc,BARRA

Put different values and you will see that the bar goes down to the
line you specify.


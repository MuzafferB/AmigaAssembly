
; Lesson 3g.s    ROLLING RIGHT AND LEFT USING COPPER WAIT


	SECTION    CiriCop,CODE

Start:
	move.l    4.w,a6        ; Execbase in a6
	jsr    -$78(a6)			; Disable - stops multitasking
	lea    GfxName(PC),a1   ; Address of the name of the lib to be opened in a1
	jsr    -$198(a6)    	; OpenLibrary, EXEC routine that opens
							; the libraries and outputs the base address
							; of the library from which to calculate
							; the addressing distances (Offset)
	move.l    d0,GfxBase    ; save the GFX base address in GfxBase
	move.l    d0,a6
	move.l    $26(a6),OldCop    ; save the address of the system copperlist
	;
	move.l	#COPPERLIST,$dff080  ; Point to our COP
	move.w    d0,$dff088         ; Start the COP

mouse:
	cmpi.b    #$ff,$dff006   ; Are we at line 255?
	bne.s    mouse       	 ; If not, do not continue

	bsr.w    CopperLeftRight   ; Right/left scrolling routine

Wait:
	cmpi.b    #$ff,$dff006  ; Are we at line 255?
	beq.s    Wait        	; If yes, don't go on, wait for the
							; next line, otherwise MoveCopper is
							; re-executed

	btst    #6,$bfe001    ; Left mouse button pressed?
	bne.s    mouse        ; If not, return to mouse:

	move.l    OldCop(PC),$dff080  ; Point to the system cop
	move.w    d0,$dff088       	  ; Start the cop

	move.l    4.w,a6
	jsr    -$7e(a6)    			; Enable - re-enable Multitasking
	move.l    GfxBase(PC),a1    ; Base of the library to close
								; (libraries must be opened and closed!!!)
	jsr    -$19e(a6)    		; Closelibrary - close the graphics library
	rts


; Instead of acting on the first byte to the left of the wait, i.e.
; the one that determines the Y position, lowering or raising the waits with
; the following colours, this routine acts on the second byte, the X one, generating a
; shift to the right and left, regulated by two flags similar to SuGiu, which
; we have already seen, in this case called RightFlag and LeftFlag,
; where the number of times the GoRight or GoLeft routine has been
; executed is stored, to limit the shift (i.e. to decide how far to go 
; forward before returning back): in fact, every time the routine
;GoRight is executed, the ‘grey bar’ moves to the right, so we have to
;stop it when it reaches the opposite edge of the screen, in this case
;when it has been executed 85 times, after which we make it go back
;by executing the GoLeft routine 85 more times, which returns it to
;its initial position, and the cycle restarts to continue until we press
;the mouse button.
; PLEASE NOTE THAT THIS ROUTINE EITHER GOES TO GoRight OR GoLeft, NOT
; BOTH: IF GoRight IS EXECUTED, THEN IT RETURNS TO THAT
; ROUTINE TO THE MOUSE LOOP:, THE SAME FOR GoLeft. IF THE GoRight AND
; GoLeft IS FINISHED (AFTER 2*85 FRAMES), RETURN TO THE ‘MOUSE’ CYCLE FROM THE RTS
; OF THE CopperLeftRight ROUTINE directly, after resetting the 2 flags.


CopperLeftRight:
	CMPI.W    #85,RightFlag ; GoRight executed 85 times?
	BNE.S     GoRight       ; if not yet, re-execute it
							; if it has already been executed 85
							; times, continue below

	CMPI.W    #85,LeftFlag  ; GoLeft executed 85 times?
	BNE.S     GoLeft        ; if not yet, re-execute it

	CLR.W    RightFlag   	; the LEFT routine has been executed
	CLR.W	 LeftFlag    	; 85 times, so at this point the
							; grey bar has returned and the
							; right-left cycle is finished, so we reset
							; the two flags and exit: at the next FRAME
							; GoRight will be executed again, after 85 frames
							; GoLeft 85 times for 85 frames, etc.
	RTS            			; RETURN TO THE LOOP mouse


GoRight:            		; this routine moves the bar to the RIGHT
	addq.b    #2,CopBar     ; add 2 to the X coordinate of the wait
	addq.w    #1,RightFlag 	; mark that we have executed another time
							; GoRight: RightFlag contains the number
							; of times we have executed GoRight.
	RTS            			; RETURN TO THE LOOP mouse


GoLeft:            			; this routine moves the bar to the LEFT
	subq.b    #2,CopBar     ; subtract 2 from the X coordinate of the wait
	addq.w    #1,LeftFlag 	; Add 1 to the number of times
							; GoLeft has been executed.
	RTS            			; RETURN TO THE LOOP mouse


RightFlag:       ; This word keeps track of the number of times
	dc.w    0    ; GoRight has been executed

LeftFlag:        ; This word keeps track of the number of times
	dc.w 0    	 ; GoLeft has been executed


; data to save the system copperlist.

GfxName:
	dc.b    "graphics.library",0,0

GfxBase:        ; This is where the base address for the Offsets goes
	dc.l    0   ; of the graphics.library

OldCop:         ; This is where the address of the old system COP goes
	dc.l    0

	SECTION    GRAPHIC,DATA_C

COPPERLIST:
	dc.w    $100,$200   ; BPLCON0
	dc.w    $180,$000   ; COLOR0 - Start the copy with the colour BLACK


	dc.w    $9007,$fffe ; wait for the start of line $90
	dc.w    $180,$AAA   ; COLOUR grey

						; Here we have ‘BROKEN’ the first WORD of WAIT $9031 into 2 bytes in order to
						; put a label (CopBar) to indicate the second byte, i.e. $31 (LA XX)

	dc.b    $90         ; POSITION YY of WAIT (first byte of WAIT)
CopBar:
	dc.b    $31         ; POSITION XX of WAIT (which we change!!!)
	dc.w    $fffe       ; wait - (will be $9033,$FFFE - $9035,$FFFE....)

	dc.w    $180,$700	; RED colour, which will start from positions
						; increasingly to the right, preceded by
						; grey, which will advance accordingly.
	dc.w    $9107,$fffe ; wait, which we do not change (Start of line $91)
	dc.w    $180,$000   ; which is used to change the colour to BLACK
						; on the line following the bar.

	;    As you can see, for line $90, two waits are needed, one to wait for the start
	;    of the line (07) and one, the one we modify (31), to define
	;    at which point on the line to change colour, i.e. to change from yellow, which is
	;    present at position 07, to red, which starts after the position
	;    taken by the wait we change.
	
	dc.w    $FFFF,$FFFE    ; END OF COPPERLIST

	END

Nice, huh? This effect is often used to make
bar equalizers in music. However, horizontal movement using wait has
some limitations, as only odd values can be given, which is why
we usually wait for line yy07,$fffe and not yy08,$fffe. 
As a result, you
can scroll in increments of 2 pixels at a time minimum: 7,9,$b,$d,$f,$11,$13....
or every 4 pixels, or 8, keeping the number odd, or you
risk blowing up the Amiga. Note: the maximum value of XX is $e1.
As modifications, I can only recommend adding 4 or 8 instead of
2 to change the speed. In this case, remember to also modify the
maximum number of times you execute the routine:


CMPI.W    #85/2,RightFlag   ; 85 times /2, i.e. ‘divided by 2’
BNE.S    GoRight
CMPI.W    #85/2,LeftFlag    ; 85/2, i.e. 42 times
BNE.S    GoLeft        		; if not yet, run it again
....

addq.b    #4,(a0)        	; add 4....
....

Or for an addq.b #8,a0:

CMPI.W    #85/4,RightFlag   ; 85 times /4, i.e. 21


if you are sadistic, try putting an addq.b #1,(a0), creating XX waits
even even ones..... in the best case scenario, the screen will flash when
the disparity occurs (in fact, the screen ‘turns off’ when an inexperienced programmer
puts a wait with XX equal), or if you wait for a strange value,
 sometimes you can generate a total computer freeze, a kind of
‘GURU MEDITATION’ of the Copper. So be careful!!!!
In particular, I can point out some special even coordinates that
instead of just making the screen disappear, they really mess up the
copper, forcing you to reset. (at least on the Amiga 1200 where I tried them)

	dc.w    $79DC,$FFFE     ; $dc = 220! even and particularly ACID!
							; drives the copper crazy, but does not block
							; the 68000, so you can continue to
							; work ‘blind’, without seeing anything

	dc.w    $0100,$FFFE     ; this one BLOCKS everything, you can't
							; even exit the programme, you have to
							; reset

	dc.w    $0300,$FFFE     ; Another total block...


These ‘ERRORS’ can be useful if you want to protect programs:
if the disk is copied incorrectly or the password is not entered correctly,
if you immediately point a copperlist with these crazy waits
the computer will BLOCK worse than with a 68000 guru, and any Action Replay
or other cartridges will be disabled and unusable. Or you could
use them as self-destruction, who knows if putting many errors in a row
could PHYSICALLY damage the computer???

NOTE: You can achieve an effect like this by modifying the example Lesson3c.s
which moves a wait down simply by modifying the routine:


MoveCopper:
	cmpi.b    #$fc,BAR    ; have we reached line $fc?
	beq.s    Finished     ; if so, we are at the bottom and do not continue
	addq.b    #1,BAR      ; WAIT 1 changed, the bar goes down 1 line
Finished:
	rts

In this way, by changing the position XX instead of YY (BAR+1), and
moving it forward by 2 instead of 1 at a time (ODD numbers!), without
forgetting that the maximum value is $e1, to be replaced by $fc

MoveCopper:
	cmpi.b    #$e1,BAR+1   ; have we reached column $fc?
	beq.s    Finished        ; if so, we are at the bottom and do not continue
	addq.b    #2,BAR+1     ; WAIT 1 changed, the bar advances by 2
Finished:
	rts

You will see the first line move to the right instead of down. To
highlight the effect, you can ‘ISOLATE’ line $79 by turning the screen dark blue
from the following line, i.e. $7a, by adding these 2
lines before the end of the copperlist:

	dc.w    $7a07,$FFFE   ; wait for line $79
	dc.w    $180,$004     ; start the red zone: red at 6

In lesson 3g, the difficulty perhaps lies more in the routine that makes
the bar go back and forth rather than in the fact that we are operating on position
XX rather than on the YY position. In fact, the last lessons you have covered
have some 68000 routines that are not too simple, but which are essential
for generating effects with the copper, and therefore for understanding the copper 
itself. In Lesson 4, however, the 68000 routines will be even simpler than those
in this lesson 3, as we will explain how to display static images.
If you do not fully understand how the routines in the
last lessons work, proceed with Lesson 4 and try to understand them
when you are further along in the course, at which point you will certainly
be more familiar with the routines. Lesson 3h.s is an extension of
Lesson 3g.s.

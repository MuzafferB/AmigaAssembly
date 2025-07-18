
; Lesson3f.s     BAR BELOW THE $FF LINE

;    This listing is identical to Lesson3d.s, except
;    that the bar is below the $FF line, which
;    we have never crossed.

	SECTION    CiriCop,CODE

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
	move.l    $26(a6),OldCop    	; save the address of the system copperlist
	move.l    #COPPERLIST,$dff080   ; Point to our COP
	move.w    d0,$dff088        	; Start the COP
	mouse:
	cmpi.b    #$ff,$dff006  ; Are we at line 255?
	bne.s    mouse        	; If not, don't continue

	bsr.s    MoveCopper     ; Routine that exploits WAIT masking

Wait:
	cmpi.b    #$ff,$dff006  ; Are we at line 255?
	beq.s    Wait        	; If yes, don't go ahead, wait for the
							; next line, otherwise MoveCopper is
							; re-executed

	btst    #6,$bfe001    ; left mouse button pressed?
	bne.s    mouse        ; if not, go back to mouse:

	move.l    OldCop(PC),$dff080    ; Point to the system cop
	move.w    d0,$dff088        	; start the cop

	move.l    4.w,a6
	jsr    -$7e(a6)    			; Enable - re-enable Multitasking
	move.l    gfxbase(PC),a1    ; Base of the library to be closed
								; (libraries must be opened and closed!!!)
	jsr    -$19e(a6)    		; Closelibrary - close the graphics library
	rts

; The MuoviCopper routine is the same, only the values of the
; maximum height that can be reached, i.e. $0a, and the bottom of the screen, $2c, have changed.

MoveCopper:
	LEA    BAR,a0
	TST.B    UpDown      ; Do we need to move up or down? If UpDown is
						; reset (i.e. TST checks BEQ)
						; then we jump to GoDown, if instead it is at $FF
						; (i.e. this TST is not checked)
						; we continue going up (doing subq)
	beq.w    GoDown
	cmpi.b    #$0a,(a0)     ; have we reached line $0a+$ff? (265)
	beq.s    PutDown    	; if so, we are at the top and we have to go down
	subq.b    #1,(a0)
	subq.b    #1,8(a0)    	; now let's change the other waits: the distance
	subq.b    #1,8*2(a0)    ; between one wait and another is 8 bytes
	subq.b    #1,8*3(a0)
	subq.b    #1,8*4(a0)
	subq.b    #1,8*5(a0)
	subq.b    #1,8*6(a0)
	subq.b    #1,8*7(a0)    ; here we have to modify all 9 waits of the
	subq.b    #1,8*8(a0)    ; red bar each time to make it go up!
	subq.b    #1,8*9(a0)
	rts

PutDown:
	clr.b    UpDown     ; Resetting UpDown, at TST.B UpDown the BEQ
	rts            		; will jump to the GoDown routine, and
						; the bar will go down

GoDown:
	cmpi.b    #$2c,8*9(a0)  ; have we reached line $2c?
	beq.s    PutUp       	; if so, we are at the end and we have to go back up
	addq.b    #1,(a0)
	addq.b    #1,8(a0)    	; now we change the other waits: the distance
	addq.b    #1,8*2(a0)    ; between one wait and another is 8 bytes
	addq.b	#1,8*3(a0)
	addq.b    #1,8*4(a0)
	addq.b    #1,8*5(a0)
	addq.b    #1,8*6(a0)
	addq.b    #1,8*7(a0)    ; here we have to modify all 9 waits of the
	addq.b    #1,8*8(a0)    ; red bar each time to make it go down!
	addq.b    #1,8*9(a0)
	rts

PutUp:
	move.b    #$ff,UpDown    ; When the UpDown label is not zero,
	rts           			; it means we have to go back up.

	;    This byte, indicated by the UpDown label, is a FLAG, i.e. a
	;    flag (in jargon), in fact once it is at $ff and another time it is at
	;    $00, depending on the direction to follow (up or down!). It is just
	;    like a flag, which when lowered ($00) indicates that we must
	;	 go down and when it is raised ($FF) we have to go up. In fact,
	;	 a comparison of the line reached is performed to check whether
	;	 we have reached the top or the bottom, and if we have, we change
	;	 the direction (with clr.b UpDown or move.b #$ff,UpDown)

UpDown:
	dc.b    0,0

GfxName:
	dc.b    "graphics.library",0,0
	
GfxBase:        ; Here goes the base address for the Offsets
	dc.l    0   ; of the graphics.library

OldCop:         ; Here goes the address of the old system COP
	dc.l    0

	SECTION    GRAPHIC,DATA_C

COPPERLIST:
	dc.w    $100,$200    	; BPLCON0
	dc.w    $180,$000    	; COLOR0 - Start the cop with the colour BLACK

	dc.w    $2c07,$FFFE  	; WAIT - a small fixed green bar
	dc.w    $180,$010    	; COLOR0
	dc.w    $2d07,$FFFE  	; WAIT
	dc.w    $180,$020    	; COLOR0
	dc.w    $2e07,$FFFE
	dc.w    $180,$030
	dc.w    $2f07,$FFFE
	dc.w    $180,$040
	dc.w    $3007,$FFFE
	dc.w    $180,$030
	dc.w    $3107,$FFFE
	dc.w    $180,$020
	dc.w    $3207,$FFFE
	dc.w    $180,$010
	dc.w    $3307,$FFFE
	dc.w    $180,$000

	dc.w    $ffdf,$fffe     ; WARNING! WAIT AT THE END OF THE $FF LINE!
							; The waits after this are below the
							; $FF line and start again from $00!!

	dc.w    $0107,$FFFE		; a fixed green bar BELOW the $FF line!
	dc.w    $180,$010
	dc.w    $0207,$FFFE
	dc.w    $180,$020
	dc.w    $0307,$FFFE
	dc.w    $180,$030
	dc.w    $0407,$FFFE
	dc.w    $180,$040
	dc.w    $0507,$FFFE
	dc.w    $180,$030
	dc.w    $0607,$FFFE
	dc.w    $180,$020
	dc.w    $0707,$FFFE
	dc.w    $180,$010
	dc.w    $0807,$FFFE
	dc.w    $180,$000

BAR:
	dc.w    $0907,$FFFE     ; wait for line $79
	dc.w    $180,$300    	; start the red bar: red at 3
	dc.w    $0a07,$FFFE  	; next line
	dc.w    $180,$600    	; red at 6
	dc.w    $0b07,$FFFE
	dc.w    $180,$900    	; red at 9
	dc.w    $0c07,$FFFE
	dc.w    $180,$c00    	; red at 12
	dc.w    $0d07,$FFFE
	dc.w    $180,$f00    	; red at 15 (maximum)
	dc.w    $0e07,$FFFE
	dc.w    $180,$c00    	; red at 12
	dc.w    $0f07,$FFFE
	dc.w    $180,$900    	; red at 9
	dc.w    $1007,$FFFE
	dc.w    $180,$600    	; red at 6
	dc.w    $1107,$FFFE
	dc.w    $180,$300    	; red at 3
	dc.w    $1207,$FFFE
	dc.w    $180,$000    	; colour BLACK

	dc.w    $FFFF,$FFFE    	; END OF COPPERLIST


	END

MIRACLE! We have put coloured bars under the flickering $FF line!
All you need to do is enter the command:

dc.w    $ffdf,$fffe

And start again from $0107,$fffe to wait in the lower part of the screen.
This is because, as you know, a byte only contains 255 values, i.e. up to
$FF, so to wait for a line above $ff, just get there
with $FFdf,$FFFE, then the numbering starts again from 0, up to where the
visible screen reaches, towards $30. Note that the American television standard
NTSC standard only goes up to line $FF, or slightly more in overscan, so
Americans cannot see the bottom of the screen on their televisions, but
this does not matter to us, because the Amiga is mainly used in Europe, where
the PAL standard is used; in fact, demos and games are almost always in PAL. In some
cases, programmers make NTSC versions of the game exclusively for
distribution in the USA.

NOTE: For now, we have only been able to wait with $DFF006 for a line between
$01 and $FF; I will explain later how to wait with $dffxxx for a
line after $FF correctly.


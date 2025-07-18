
; Lesson 3h.s    ROLLING RIGHT AND LEFT USING COPPER WAIT

	SECTION    CiriCop,CODE

Start:
	move.l    4.w,a6        ; Execbase in a6
	jsr    -$78(a6)    		; Disable - stops multitasking
	lea    GfxName(PC),a1   ; Address of the name of the lib to open in a1
	jsr    -$198(a6)		; OpenLibrary, EXEC routine that opens
							; the libraries and outputs the
							; base address of the library from which to calculate
							; the addressing distances (Offset)
	move.l    d0,GfxBase    ; save the GFX base address in GfxBase
	move.l    d0,a6
	move.l    $26(a6),OldCop    	; save the address of the system copperlist
	move.l    #COPPERLIST,$dff080   ; Point to our COP
	move.w    d0,$dff088        	; Start the COP
	
mouse:
	cmpi.b    #$ff,$dff006      ; Are we at line 255?
	bne.s    mouse        		; If not, don't continue

	bsr.w    CopperLeftRight    ; Right/left scrolling routine

Wait:
	cmpi.b    #$ff,$dff006    	; Are we at line 255?
	beq.s    Wait        		; If yes, don't continue, wait for the
								; next line, otherwise MoveCopper is
								; re-executed

	btst    #6,$bfe001    ; Left mouse button pressed?
	bne.s    mouse        ; if not, go back to mouse:

	move.l    OldCop(PC),$dff080    ; Point to the system cop
	move.w    d0,$dff088        	; start the cop

	move.l    4.w,a6
	jsr    -$7e(a6)    			; Enable - re-enable Multitasking
	move.l    GfxBase(PC),a1    ; Base of the library to be closed
								; (libraries must be opened and closed!!!)
	jsr    -$19e(a6)    		; Closelibrary - close the graphics library
	rts

	; The routine is the same as in LESSON3g.s, the only difference is that it acts on
	; 29 waits instead of 1 using a DBRA loop that changes a wait, jumps to the next wait
	; changes the wait, jumps to the next wait, and so on.

CopperLeftRight:
	CMPI.W    #85,RightFlag		; GoRight executed 85 times?
	BNE.S    GoRight        	; if not yet, re-execute
								; if it has already been executed 85
								; times, continue below

	CMPI.W    #85,LeftFlag    	; GoLeft executed 85 times?
	BNE.S    GoLeft				; if not yet, run it again

	CLR.W    RightFlag    		; the GoLeft routine has been executed
	CLR.W    LeftFlag    		; 85 times, so at this point the grey bar
								; has returned and the
								; right-left cycle is finished, so we reset
								; the two flags and exit: at the next FRAME
								; GoRight will be executed again, after 85 frames
								; GoLeft 85 times for 85 frames, etc.
	RTS            				; BACK TO THE LOOP mouse


GoRight:           			; this routine moves the bar to the RIGHT
	lea    CopBar+1,A0    	; Put the address of the first value in A0
							; XX of the first wait, which is located
							; 1 byte after CopBar
	move.w    #29-1,D2    	; we need to change 29 waits (we use a DBRA)
RightLoop:
	addq.b    #2,(a0)       ; add 2 to the X coordinate of the wait
	ADD.W	#16,a0        	; go to the next wait to be changed
	dbra    D2,RightLoop    ; cycle executed d2 times
	addq.w    #1,RightFlag  ; mark that we have executed another time
							; GoRight: RightFlag contains the number
							; of times we have executed GoRight.
	RTS            			; RETURN TO THE LOOP mouse


GoLeft:           			; this routine moves the bar to the LEFT
	lea    CopBar+1,A0
	move.w    #29-1,D2    	; we must change 29 waits
LeftLoop:
	subq.b	#2,(a0)         ; subtract 2 from the X coordinate of the wait
	ADD.W    #16,a0         ; go to the next wait to be changed
	dbra    D2,LeftLoop     ; cycle executed d2 times
	addq.w    #1,LeftFlag   ; Add 1 to the number of times that
							; GoLeft has been executed.
	RTS            			; RETURN TO THE LOOP mouse

; Pay attention to one thing: we change 1 wait every 2, not all
; the waits. We only change half of them because, unlike when we
; scroll a bar up and down, where 1 wait per line is enough
;
;    dc.w    $YY07,$FFFE    ; wait line YY, start of line (07)
;    dc.w    $180,$0RGB    ; colour
;    dc.w    $YY07,$FFFE    ; wait line YY, start of line (07)
;    ...
;
; In this case, we need to put 2 waits for each line, i.e. one at the beginning
; of the line and another that scrolls right and left on that line:
;
;    dc.w    $YY07,$FFFE    ; wait line YY, start line (07)
;    dc.w    $180,$0RGB    ; colour GREY
;    dc.w    $YYXX,$FFFE    ; wait line YY, at the horizontal position
;                ; that we decide, advancing the
;                ; GREY on the RED.
;    dc.w    $180,$0RGB    ; RED
;


RightFlag:       ; This word keeps track of the number of times
	dc.w    0    ; GoRight has been executed

LeftFlag:        ; This word keeps track of the number of times
	dc.w 0    	 ; GoLeft has been executed

; Data to save the system copperlist.

GfxName:
	dc.b    "graphics.library",0,0

GfxBase:        ; This is where the base address for the Offsets goes
	dc.l    0   ; of the graphics.library

OldCop:         ; This is where the address of the old system COP goes
	dc.l    0

	SECTION    GRAPHIC,DATA_C

COPPERLIST:
	dc.w    $100,$200    ; BPLCON0
	dc.w    $180,$000    ; COLOR0 - Start the copy with the colour BLACK

	dc.w    $2c07,$FFFE  ; WAIT - a small fixed green bar
	dc.w    $180,$010    ; COLOR0
	dc.w    $2d07,$FFFE  ; WAIT
	dc.w    $180,$020    ; COLOR0
	dc.w    $2e07,$FFFE  ; WAIT
	dc.w    $180,$030	 ; COLOR0
	dc.w    $2f07,$FFFE  ; WAIT
	dc.w    $180,$040    ; COLOR0
	dc.w    $3007,$FFFE
	dc.w    $180,$030
	dc.w	$3107,$FFFE
	dc.w	$180,$020
	dc.w	$3207,$FFFE
	dc.w	$180,$010
	dc.w	$3307,$FFFE
	dc.w	$180,$000


	dc.w    $9007,$fffe  ; wait for the start of the line
	dc.w    $180,$000  	 ; grey at minimum, i.e. BLACK!!!
CopBar:
	dc.w    $9031,$fffe  ; wait, we're changing ($9033,$9035,$9037...)
	dc.w    $180,$100    ; red colour, which will start from positions
						 ; increasingly to the right, preceded by
						 ; grey, which will advance accordingly.
	dc.w    $9107,$fffe  ; wait, don't change (start of line)
	dc.w    $180,$111    ; GREY colour (starts from the start of the line to
	dc.w    $9131,$fffe  ; at this WAIT, which we will change....
	dc.w    $180,$200    ; after which RED begins

;    we continue saving space, observe the diagram:

; note: with ‘dc.w $1234’ we put 1 word in memory, with ‘dc.w $1234,$1234’
; we store 2 consecutive words, i.e. the longword ‘dc.l $12341234’
; which we could have stored with a ‘dc.b $12,$34,$12,$34’, so
; we can also store 8 or more words with a single dc.w line!
; for example, line 3 could be rewritten with dc.l as follows:
;    dc.l    $9207fffe,$1800222,$9231fffe,$1800300	i.e.:
;    dc.l    $9207fffe,$01800222,$9231fffe,$01800300    with the *INITIAL* zeros
; pay attention to the initial zeros! I write a dc.w $0180 as dc.w $180
; simply for convenience, but the zero exists, keep that in mind!
; To clarify, line 3 complete with initial zeros would be:
;    dc.w    $9207,$fffe,$0180,$0222,$9231,$fffe,$0180,$0300 (1 word =$xxxx)
; Ultimately, the ‘useless’ leading zeros in .b, .w, .l are OPTIONAL.

;     FIXED WAITS (then grey) - WAITS TO BE CHANGED (followed by red)

	dc.w    $9207,$fffe,$180,$222,$9231,$fffe,$180,$300 ; line 3
	dc.w    $9307,$fffe,$180,$333,$9331,$fffe,$180,$400 ; line 4
	dc.w    $9407,$fffe,$180,$444,$9431,$fffe,$180,$500 ; line 5
	dc.w    $9507,$fffe,$180,$555,$9531,$fffe,$180,$600 ; ....
	dc.w	$9607,$fffe,$180,$666,$9631,$fffe,$180,$700
	dc.w	$9707,$fffe,$180,$777,$9731,$fffe,$180,$800
	dc.w	$9807,$fffe,$180,$888,$9831,$fffe,$180,$900
	dc.w	$9907,$fffe,$180,$999,$9931,$fffe,$180,$a00
	dc.w	$9a07,$fffe,$180,$aaa,$9a31,$fffe,$180,$b00
	dc.w	$9b07,$fffe,$180,$bbb,$9b31,$fffe,$180,$c00
	dc.w    $9c07,$fffe,$180,$ccc,$9c31,$fffe,$180,$d00
	dc.w	$9d07,$fffe,$180,$ddd,$9d31,$fffe,$180,$e00
	dc.w	$9e07,$fffe,$180,$eee,$9e31,$fffe,$180,$f00
	dc.w	$9f07,$fffe,$180,$fff,$9f31,$fffe,$180,$e00
	dc.w	$a007,$fffe,$180,$eee,$a031,$fffe,$180,$d00
	dc.w	$a107,$fffe,$180,$ddd,$a131,$fffe,$180,$c00
	dc.w	$a207,$fffe,$180,$ccc,$a231,$fffe,$180,$b00
	dc.w    $a307,$fffe,$180,$bbb,$a331,$fffe,$180,$a00
	dc.w    $a407,$fffe,$180,$aaa,$a431,$fffe,$180,$900
	dc.w    $a507,$fffe,$180,$999,$a531,$fffe,$180,$800
	dc.w	$a607,$fffe,$180,$888,$a631,$fffe,$180,$700
	dc.w	$a707,$fffe,$180,$777,$a731,$fffe,$180,$600
	dc.w	$a807,$fffe,$180,$666,$a831,$fffe,$180,$500
	dc.w	$a907,$fffe,$180,$555,$a931,$fffe,$180,$400
	dc.w    $aa07,$fffe,$180,$444,$aa31,$fffe,$180,$300
	dc.w    $ab07,$fffe,$180,$333,$ab31,$fffe,$180,$200
	dc.w    $ac07,$fffe,$180,$222,$ac31,$fffe,$180,$100
	dc.w    $ad07,$fffe,$180,$111,$ad31,$fffe,$180,$000
	dc.w    $ae07,$fffe,$180,$000

;     FIXED WAITS (then grey) - WAITS TO BE CHANGED (followed by red)
;
;	As you can see, each line requires two waits, one to wait for the start of the line and one, which we modify, to define at which point;    of the line to change colour, i.e. to switch from grey, which is
;    present at position 07, to red, which starts after the position
;    assumed by the wait we are changing.
;
	dc.w    $fd07,$FFFE	
; wait for line $FD
	dc.w    $180,$00a    ; blue intensity 10
	dc.w    $fe07,$FFFE  ; next line
	dc.w    $180,$00f    ; maximum blue intensity (15)
	dc.w    $FFFF,$FFFE  ; END OF COPPERLIST

	END


Last little thing: if you are still unclear about the initial zeros
discussed earlier, here are some ‘correct’ and ‘incorrect’ conversions:

dc.b    1,2    =    dc.w    $0102    i.e.    dc.w    $102

dc.b    42,$2    =    dc.w    $2a02    (42 decimal = $2a Hex)

dc.b    12,$2,$12,41 = dc.w $c02,$1229 = dc.l $c021229

dc.b    12,$22,0 = dc.w $000c,$2200 = dc.w $c,$2200 = dc.l $c2200

dc.w    1,2,3,432 = dc.l $00010002,$000301b0 = dc.l $10002,$301b0

dc.l    $1234567=    dc.b    1,$23,$45,$67

dc.l    $2342    =    dc.b    0,0,$23,$42

dc.l    4    =    dc.b    0,0,0,4

Pay attention to the last example:

a dc.l 4 in memory becomes $00000004, a dc.b 4 becomes $04
so while the 04 in dc.l is preceded by 3 bytes $00,
in the case of dc.b 4, the 4 is positioned in the first place, which is
completely different in ASSEMBLER, even though we are always talking
about a 4!!!!


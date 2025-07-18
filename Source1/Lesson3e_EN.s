
; Lesson 3e.s    Scrolling effect of a faded background


;    Routine executed once every 3 frames


	SECTION    CiriCop,CODE    ; also works in Fast

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
	move.l    #MYCOPPER,$dff080  ; Point to our COP
	move.w    d0,$dff088         ; Start the COP
	
mouse:
	cmpi.b    #$ff,$dff006  ; Are we at line 255?
	bne.s    mouse        	; If not, don't continue

frame:
	cmpi.b    #$fe,$dff006   ; Are we at line 254? (must repeat the loop!)
	bne.s    frame       	 ; If not yet, don't go on

frame2:
	cmpi.b    #$fd,$dff006  ; Are we at line 253? (must repeat the cycle!)
	bne.s    frame2        	; If not yet, don't go on

	bsr.s    ScrollColours   ; A so-called RASTER BAR!

	btst    #6,$bfe001    ; Left mouse button pressed?
	bne.s    mouse        ; If not, go back to mouse:

	move.l    OldCop(PC),$dff080    ; Point to the system cop
	move.w    d0,$dff088       		; Start the cop

	move.l	4.w,a6
	jsr    -$7e(a6)    			; Enable - re-enable Multitasking
	move.l    GfxBase(PC),a1    ; Base of the library to close
								; (libraries must be opened and closed!!!)
	jsr    -$19e(a6)    		; Closelibrary - close the graphics library
	rts

;    This routine scrolls through the 14 colours of our green copperlist
;    to simulate a continuous upward scroll, as
;    if we were looking through a slit and seeing an unlimited series
;    of shaded bars scrolling by. In practice, it moves the colours each time by copying them,
;    starting by copying the second into the first, the third into the second, and so on,
;    as if we had a row of coloured balls in a row: suppose you
;    take the second one and put it in place of the first, which you put
;    in your pocket, creating a “hole”: you continue by moving all the balls
;	 one by one from one place: the third in place of the second, the fourth
; 	 in place of the third, and so on, until you reach the
;	 fourteenth (the last one), which you move to where the thirteenth was,
;	 creating the “hole” that was previously in place of the first.
;    To fill this hole, take the first ball from your pocket
;    and put it in place of the fourteenth (note the last instruction
;    which is ‘move.w col1,col14’, i.e. after ‘sliding’
;    the “hole” from the first position to the fourteenth, we ‘fill’ it
;    with the first ball, creating a cycle of continuity (infinite!) like
;    the sliding of a bicycle chain:
;
;	 >>>>>>>>>>>>>>>>>>>>>	
;	^ 		      v
;	 <<<<<<<<<<<<<<<<<<<<
;
;    but without the lower part of the chain: simply when a
;    link in the chain (a colour) reaches the end (v), it is
;    copied to the first position (^), making the cycle
;    infinite:
;
;	 >>>>>>>>>>>>>>>>>>>>>	
;	^ 		      v
;
;    In fact, to interrupt the routine, simply delete any
;    of the instructions that copy: try, for example, putting a ;
;    at the first one: (move.w col2,col1) and you will see that it scrolls only
;    once, after which the colours end, as "A LINK IN THE
;	 CHAIN", which no longer provides the previous colour.

ScrollColours:
	move.w    col2,col1    ; col2 copied to col1
	move.w    col3,col2    ; col3 copied to col2
	move.w    col4,col3    ; col4 copied to col3
	move.w    col5,col4    ; col5 copied to col4
	move.w    col6,col5    ; col6 copied to col5
	move.w    col7,col6    ; col7 copied to col6
	move.w    col8,col7    ; col8 copied to col7
	move.w    col9,col8    ; col9 copied to col8
	move.w    col10,col9   ; col10 copied to col9
	move.w    col11,col10  ; col11 copied to col10
	move.w    col12,col11  ; col12 copied to col11
	move.w    col13,col12  ; col13 copied to col12
	move.w    col14,col13  ; col14 copied to col13
	move.w    col1,col14   ; col1 copied to col14
	rts

GfxName:
	dc.b    "graphics.library",0,0
	

GfxBase:        ; Here goes the base address for the Offsets
	dc.l    0    ; of the graphics.library

OldCop:            ; Here goes the address of the old system COP
	dc.l    0

;=========== Copperlist ==========================

	section    cop,data_C

MYCOPPER:
	dc.w    $100,$200   	; BPLCON0 - screen without bitplanes, only the
							; background colour $180 is visible.

	DC.W    $180,$000   	; COLOR0 - start with BLACK

	dc.w    $9a07,$fffe    	; wait for line 154 ($9a in hexadecimal)
	dc.w    $180        	; COLOR0 REGISTER
	col1:
	dc.w    $0f0			; COLOUR 0 VALUE (to be modified)
	dc.w    $9b07,$fffe 	; wait for line 155 (will not be modified)
	dc.w    $180        	; COLOUR0 REGISTER (will not be modified)
	col2:
	dc.w    $0d0			; COLOUR 0 VALUE (will be modified)
	dc.w    $9c07,$fffe    	; wait for line 156 (not modified, etc.)
	dc.w    $180        	; COLOUR REGISTER 0
	col3:
	dc.w    $0b0        	; COLOUR 0 VALUE
	dc.w     $9d07,$fffe    ; wait for line 157
	dc.w    $180        	; COLOUR REGISTER 0
	col4:
	dc.w    $090        	; COLOUR VALUE 0
	dc.w    $9e07,$fffe    	; wait for line 158
	dc.w    $180			; COLOUR REGISTER0
	col5:
	dc.w    $070        	; COLOUR VALUE 0
	dc.w    $9f07,$fffe    	; wait for line 159
	dc.w    $180        	; COLOUR REGISTER0
	col6:
	dc.w    $050			; COLOUR 0 VALUE
	dc.w    $a007,$fffe    	; wait for line 160
	dc.w    $180        	; COLOUR REGISTER 0
	col7:
	dc.w    $030        	; COLOUR 0 VALUE
	dc.w    $a107,$fffe     ; wait for line 161
	dc.w    $180        	; colour0... (now you understand the comments,
	col8:                	; I can stop putting them here!)
	dc.w    $030
	dc.w    $a207,$fffe     ; line 162
	dc.w    $180
	col9:
	dc.w    $050
	dc.w    $a307,$fffe     ; line 163
	dc.w    $180
	col10:
	dc.w    $070
	dc.w    $a407,$fffe     ; line 164
	dc.w    $180
	col11:
	dc.w    $090
	dc.w    $a507,$fffe     ; line 165
	dc.w    $180
	col12:
	dc.w    $0b0
	dc.w    $a607,$fffe     ; line 166
	dc.w    $180
	col13:
	dc.w    $0d0
	dc.w    $a707,$fffe     ; line 167
	dc.w    $180
	col14:
	dc.w    $0f0
	dc.w     $a807,$fffe    ; line 168

	dc.w     $180,$0000     ; Let's decide on BLACK for the part
							; of the screen under the effect

	DC.W $FFFF,$FFFE    	; End of Copperlist

	END

CHANGES: Try adding this command at the end of the
‘Scrollcolors’ routine, and you will get a colour change (add 1 to the
RED component)

add.w #$100,col13

Then try changing the value of add to obtain different colour variations.
 Clearly, this is a somewhat approximate system for creating shades,
but it can be useful for making sure you have understood the routine.

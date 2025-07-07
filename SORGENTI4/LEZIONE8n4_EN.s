
; Lesson 8n4.s - Routine for printing points (plot) on different planes,
;         used to print a drawing (the coordinates are read
;         from a table that you can write by hand or in other ways)
;
; Author:    Lorenzo Di Gaetano    ( The Amiga Dj )
;

SECTION    Powerplot,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup1.s’    ; with this include I save myself from
; rewriting it every time!
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000	; copper and bitplane DMA enabled
;         -----a-bcdefghij


START:
move.l    #Bitplanes,d0
lea    Bplpointers,a1
moveq    #3-1,d1
Pointbp:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
add.l    #40*256,d0
add.w    #8,a1
dbra    d1,pointbp

lea    $dff000,a5
move.w    #DMASET,$96(a5)
move.l    #coplist,$80(a5)    ; point to cop
move.l    d0,$88(a5)

move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

; PRINT ‘CIAO’

move.w    #(256-1),d7    ; (Number of Data/2)-1    -> number of dots!
Loop:
bsr.w    WaitBlank    ; Wait for line 255 to synchronise
move.l    POINT(PC),a2    ; current coordinate in tab from pointer
addq.l    #2,POINT    ; Move pointer to next coord.
; for next loop. (next point!)
moveq    #0,d0
moveq    #0,d1
move.b    (a2)+,d0    ; X coordinate
move.b    (a2)+,d1    ; Y coordinate
moveq    #6,d2        ; colour = 6 (white)
lea    Bitplanes,a0	; Destination planes
bsr.w    Plot        ; Print the point
; a0 = Bitplanes address
; d0 = X coordinate
; d1 = Y coordinate
; d2 = Pixel colour
dbra    d7,loop        ; execute d7 times, then print d7 points!

; PRINT ‘AMIGA’

move.w    #(53-1),d7    ; (Data Number/2)-1
Loop2:
bsr.w    WaitBlank    ; Wait for line 255 to synchronise
move.l	POINT(PC),a2    ; current coordinate in tab from pointer
addq.l    #2,POINT    ; Move pointer to next coordinates
; for next loop. (next point!)
moveq    #0,d0
moveq    #0,d1
move.b    (a2)+,d0    ; X coordinate
move.b    (a2)+,d1    ; Y coordinate
moveq    #2,d2        ; colour = 2 (green)
lea    Bitplanes,a0    ; Destination planes
bsr.w    Plot        ; Print the point
dbra    d7,loop2    ; Execute d7 times, then print d7 points!

; PRINT ‘LIVES’

move.w    #(45-1),d7	; (Number of Data/2)-1
Loop3:
bsr.w    WaitBlank    ; Wait for line 255 to synchronise
move.l    POINT(PC),a2    ; current coordinate in tab from pointer
addq.l    #2,POINT    ; Move pointer to next coord.
; for the next loop. (next point!)
moveq    #0,d0
moveq    #0,d1
move.b    (a2)+,d0    ; X coordinate
move.b    (a2)+,d1    ; Y coordinate
moveq    #4,d2        ; colour = 4 (yellow)
lea    Bitplanes,a0    ; Destination planes
bsr.w    Plot        ; Print the point
dbra    d7,loop3    ; Execute d7 times, then print d7 points!

; PRINT ‘T’

move.w    #(56-1),d7    ; (Data Number/2)-1
Loop4:
bsr.s    WaitBlank    ; Wait for line 255 to synchronise
move.l    POINT(PC),a2    ; current coordinate in tab from pointer
addq.l    #2,POINT    ; Move pointer to next coordinates
; for next loop. (next point!)
moveq	#0,d0
moveq    #0,d1
move.b    (a2)+,d0    ; X coordinate
move.b    (a2)+,d1    ; Y coordinate
moveq    #1,d2        ; colour = 1 (Red)
lea	Bitplanes,a0    ; Destination planes
bsr.w    Plot        ; Print the point
dbra    d7,loop4    ; execute d7 times, then print d7 points!

; PRINT ‘A’

move.w    #(45-1),d7    ; (Data Number/2)-1
Loop5:
bsr.s    WaitBlank    ; Wait for line 255 to synchronise
move.l    POINT(PC),a2    ; current coordinate in tab from pointer
addq.l    #2,POINT    ; Move pointer to next coordinates
; for next loop. (next point!)
moveq    #0,d0
moveq    #0,d1
move.b    (a2)+,d0    ; X coordinate
move.b    (a2)+,d1    ; Y coordinate
moveq    #7,d2        ; colour = 7 (Purple)
lea    Bitplanes,a0    ; Destination planes
bsr.s    Plot        ; Print the point
dbra    d7,loop5    ; execute d7 times, then print d7 points!

; PRINT ‘D’

move.w    #(53-1),d7	; (Number of Data/2)-1
Loop6:
bsr.s    WaitBlank    ; Wait for line 255 to synchronise
move.l    POINT(PC),a2    ; current coordinate in tab from pointer
addq.l    #2,POINT    ; Move pointer to next coord.
; for next loop. (next point!)
moveq    #0,d0
moveq    #0,d1
move.b    (a2)+,d0    ; X coordinate
move.b    (a2)+,d1    ; Y coordinate
moveq    #5,d2        ; colour = 5 (blue)
lea    Bitplanes,a0    ; Destination planes
bsr.s    Plot        ; Print the point
dbra    d7,loop6    ; execute d7 times, then print d7 points!


mouse:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse
rts

*****************************************************************************
;		Routine che attende la linea 255
*****************************************************************************

WaitBlank:
MOVE.L	#$1ff00,d1	; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L	D2,D0		; aspetta la linea $12c+1
BEQ.S	Aspetta
RTS

*****************************************************************************
;----------------------------------------------------------------------------
; Plotpix routine with colour management, up to 8 bitplanes (aga)
; by Lorenzo ‘TAD’ Di Gaetano 1995
;
; Input parameters:
;
; a0 = Bitplane address
; d0.w = X coordinate
; d1.w = Y coordinate
; d2.b = Pixel colour
;----------------------------------------------------------------------------
*****************************************************************************

;     .....
;     __\ oO/__
;     / _ \./ _ \
;    /\/| " |\/\
;    \ \|_____|/ /
;     \ \_(_)_| /
;     \\\ \
;     / \/ \
;     \____\____/
;    (_____\_____)eD
;

Plot:
movem.l    d0-d7/a0-a6,-(SP)
mulu.w    #40,d1			; Multiply Y by 40
; thus obtaining the vertical offset
move.w    d0,d3            ; Save X in d3
lsr.w    #3,d0            ; Divide x by 8 in order to
; find the horizontal offset.
add.w    d0,d1            ; Add the vertical and
horizontal offsets to find
the global offset.
move.l    d1,a1            ; Save d1 in a1
add.l    a0,a1            ; Add the offset to the address
of the bitplanes, finding the
right byte to operate on.

and.l    #%0000000000001111,d3    ; Select the 3 low bits to
; find the right bit to set
not.w    d3            ; Invert it

; At this point we have:
;
; in a1, the address of the byte where we need to do the bset (on the first plane)
; in d3, the bit to set
; in d2, the colour number

; Now we need to set the bits of the right planes to get the colour in d2!

moveq    #3-1,d4            ; Number of possible bitplanes...
moveq    #0,d5            ; d5 (bit counter) reset
Colorloop:
move.l    a1,a2            ; Save a1 (plane1) in a2
move.l    d5,d6            ; and d5 (bit counter) in d6, to
; calculate the offset
; from the first bitplane.
btst.l    d5,d2            ; Here's the trick. We test the bits
; that make up the colour value
; in order to set the corresponding
; bits of the various bitplanes!
beq.s    Jump            ; Bit reset, then jump.
; If set, continue,
; setting the bit in the right plane!
mulu.w    #40*256,d6        ; In d6 we have the number of the
; bitplane under examination, we multiply it
; by the size of the bitplane
; to find its exact address.
add.l    d6,a2            ; Add the offset to plane 1
bset.b    d3,(a2)            ; And finally draw the pixel
; in the right plane.
Skip:
addq.b    #1,d5            ; Next bit to test to find
; which planes to do the bset on!
dbra    d4,Colorloop        ; Repeat loop
movem.l    (SP)+,d0-d7/a0-a6
rts

; Pointer to the table

POINT:
dc.l    TAB

; Table with coordinates, in the format: X,Y point1, X,Y, point2, X,Y....
; Note that the coordinates are in bytes, therefore from 0 to 255, so
; the X coordinate cannot go up to 320... if you wanted to reach
an X coordinate greater than 255, you could make the table in words.

TAB:
dc.b    130,106,129,106,128,106,127,106,126,106,125,107,124,107,124,108
dc.b	123,108,122,109,121,109,121,110,120,110,120,111,120,112,119,113
dc.b	119,114,119,115,118,115,118,116,118,117,118,118,117,118,117,119
dc.b	117,120,116,121,116,122,116,123,116,124,116,125,115,126,115,127
dc.b	115,128,115,129,115,130,115,131,115,132,115,133,115,134,115,135
dc.b	116,135,116,136,116,137,116,138,117,138,117,139,117,140,118,140
dc.b	119,140,119,141,120,141,120,142,121,142,122,142,122,143,123,143
dc.b	124,143,125,143,126,143,127,143,128,143,129,143,130,143,131,143
dc.b	131,142,132,142,132,141,133,141,133,140,134,140,134,139,134,138
dc.b	134,137,135,136,135,135,135,134,135,133,135,132,135,131,135,130
dc.b	135,129,135,120,136,130,136,131,136,132,136,133,136,134,136,135
dc.b	136,136,136,137,136,138,136,139,136,140,137,141,137,142,138,142
dc.b	138,143,139,143,140,143,140,144,141,144,142,144,143,144,144,144
dc.b	144,143,145,143,145,142,146,141,146,140,146,139,147,138,147,137
dc.b	148,136,148,135,149,135,149,134,149,133,149,132,149,131,149,130
dc.b	149,129,149,128,149,127,150,127,150,126,151,126,151,125,152,125
dc.b	153,125,154,125,155,125,156,125,157,125,157,126,158,126,159,126
dc.b	160,127,160,128,161,128,162,129,162,130,162,131,162,132,162,133
dc.b	162,134,162,135,162,136,162,137,161,138,161,139,160,140,160,141
dc.b	159,142,159,143,158,143,157,143,156,143,155,143,154,143,154,142
dc.b	153,142,152,142,152,141,151,141,150,141,150,140,150,139,150,138
dc.b	149,138,149,137,149,136,163,129,163,130,163,131,163,132,163,133
dc.b	163,134,163,135,163,136,163,137,163,138,163,139,163,140,164,141
dc.b	164,142,165,142,166,142,167,142,168,142,169,142,169,141,170,141
dc.b	170,140,171,140,171,139,172,139,173,138,173,137,174,137,174,136
dc.b	174,135,174,134,174,133,174,132,174,131,175,130,175,129,175,128
dc.b	176,128,176,127,176,126,177,125,177,124,178,124,178,123,179,122
dc.b	180,122,181,122,182,122,183,122,184,122,185,122,186,123,187,124
dc.b	188,125,188,126,188,127,188,128,188,129,188,130,188,131,188,132
dc.b	188,133,188,134,188,135,188,136,187,137,187,138,186,138,186,139
dc.b	185,140,185,141,184,141,183,142,182,142,181,142,180,142,179,142
dc.b	178,142,177,142,176,141,175,141,175,140,174,140,174,139,174,138
dc.b	107,155,107,154,107,153,107,152,108,151,109,151,110,152,110,153
dc.b	110,154,110,155,108,154,109,154,112,155,112,154,112,153,112,152
dc.b	112,151,115,151,115,152,115,153,115,154,115,155,113,152,114,152
dc.b	117,151,117,152,117,153,117,154,117,155,122,151,121,151,120,151
dc.b	119,152,119,153,119,154,120,155,121,155,122,155,122,154,122,153
dc.b	121,153,124,155,124,154,124,153,124,152,125,151,126,151,127,152
dc.b	127,153,127,154,127,155,125,154,126,154,131,151,131,152,131,153
dc.b	131,154,131,155,132,155,133,155,135,151,135,152,135,153,135,154
dc.b	135,155,137,151,137,152,137,153,137,154,138,155,139,154,139,153
dc.b	139,152,139,151,141,151,141,152,141,153,141,154,141,155,142,151
dc.b	143,151,142,153,142,155,143,155,148,151,147,151,146,151,145,152
dc.b	146,153,147,153,148,154,147,155,146,155,145,155,151,151,151,152
dc.b	151,153,151,155
dc.b	163,155,162,155,161,156,160,156,159,157,159,156,159,155,159,154
dc.b	159,153,159,152,159,151,160,151,161,151,162,151,163,151,164,151
dc.b	165,151,166,151,167,151,168,151,169,151,170,151,171,151
dc.b	171,152,171,153
dc.b	171,154,171,155,171,156,171,157,170,156,169,156,168,155,167,155
dc.b	167,156,167,157,168,158,168,159,168,160,168,161,169,162,169,163
dc.b	168,163,167,163,166,163,165,163,164,163,163,163,162,163,161,163
dc.b	161,162,162,161,162,160,162,159,162,158,163,157,163,156,176,151
dc.b	177,151,178,151,178,152,179,153,179,154,179,155,180,156,180,157
dc.b	180,158,181,159,181,160,181,161,182,162,182,163,181,163,180,163
dc.b	179,163,179,162,179,161,178,161,177,161,176,161,175,161,175,162
dc.b	175,163,174,163,173,163,172,163,172,162,173,161,173,160,173,159
dc.b	174,158,174,157,174,156,175,155,175,154,175,153,176,152,177,156
dc.b	177,157,178,158,177,158,176,158,185,151,186,151,187,151,188,151
dc.b	189,151,190,151,191,151,192,151,193,152,194,153,194,154,194,155
dc.b	194,156,194,157,194,158,194,159,194,160,194,161,193,162,192,163
dc.b	191,163,190,163,189,163,188,163,187,163,186,163,185,162,185,161
dc.b	185,160,186,160,186,159,186,158,186,157,186,156,186,155,186,154
dc.b	185,154,185,153,185,152,189,154,190,154,191,155,191,156,191,157
dc.b	191,158,191,159,190,160,189,160,189,159,189,158,189,157,189,156
dc.b	189,155

*****************************************************************************
;				Copperlist
*****************************************************************************

SECTION    Powercopper,DATA_C

Coplist:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0	; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,$24    ; BplCon2 - All sprites above the bitplanes
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

bplpointers:
dc.w    $e0,0,$e2,0    ; plane1
dc.w    $e4,0,$e6,0    ; plane2
dc.w    $e8,0,$ea,0    ; plane3

; 5432109876543210
dc.w    $100,%0011001000000000    ; 3 bitplanes LOWRES 320x256

dc.w    $180,$0000    ; colour0 - Black
dc.w    $182,$0f00    ; colour1 - Red
dc.w    $184,$00f0    ; colour2 - Green
dc.w    $186,$000f    ; color3 - Blue
dc.w    $188,$0ff0    ; color4 - Yellow
dc.w    $18a,$00ff    ; color5 - Light blue
dc.w    $18c,$0fff    ; color6 - White
dc.w    $18e,$0f0f    ; color7 - Purple

dc.w	$ffff,$fffe	; Fine della Copperlist

*****************************************************************************

SECTION	MIOPLANE,BSS_C

Bitplanes:
ds.b    (40*256)*3

end

Have you seen how hard this course reader works? I don't even have time
to finish a lesson before he sends me his printouts!!!

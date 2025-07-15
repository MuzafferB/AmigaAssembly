
; Lesson 8n3.s - Optimised point printing routine (plot).
;         A table is used to “move” a point. Right-click
;         to leave a “trail” behind the point.

Section    dotta,CODE

;	Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup1.s’    ; with this include I save myself from
; rewriting it every time!
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000	; copper and bitplane DMA enabled
;         -----a-bcdefghij

LargSchermo    equ    40    ; Screen width in bytes.

START:
;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

; PRECALCULATE A TABLE WITH MULTIPLES OF 40, i.e. the screen width
; to avoid multiplying for each plot.

lea    MulTab,a0    ; Address space of 256 words where to write
; the multiples of 40...
moveq    #0,d0        ; Let's start from 0...
move.w    #256-1,d7    ; Number of multiples of 40 needed
PreCalcLoop
move.w    d0,(a0)+    ; Save the current multiple
add.w    #LargSchermo,d0    ; Add screen width, next multiple
dbra    d7,PreCalcLoop    ; Create the entire MulTab

; Point to the copy...

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w	#0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

lea    bitplane,a0    ; Address of the bitplane where to print in a0
lea    MulTab,a1    ; Address of the table with the multiples of the
; screen width precalculated in a1

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w    ReadTables    ; Reads the X and Y positions from the tables

move.w    MyX(PC),d0    ; X coordinate
move.w    MyY(PC),d1    ; Y coordinate

bsr.w    PlotPIXP    ; prints the point at coord. X=d0, Y=d1

btst    #2,$16(a5)    ; right mouse button pressed?
beq.s    Do not delete

move.w    MioXold(PC),d0    ; old X coordinate to be deleted
move.w    MioYold(PC),d1    ; old Y coordinate

bsr.w    ErasePIXP	; reset the point at coordinates X=d0, Y=d1

DoNotDelete:
move.w    MyX(PC),MyXold ; prepare the coordinates of the point to be deleted
move.w    MyY(PC),MyYold ; after

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts            ; exit



MioX:
dc.w    0
MioY:
dc.w    0
MioXold:
dc.w    0
MioYold:
dc.w    0


*****************************************************************************
; Optimised dot plot routine
*****************************************************************************

;    PlotPIXP input parameters:
;
;    a0 = Destination bitplane address
;    a1 = Address of the table with precalculated multiples of 40
;    d0.w = X coordinate (0-319)
;	d1.w = Y coordinate (0-255)

;     .....
;     __\ oO/__
;     / _ \./ _ \
;    /\/| " |\/\
;    \ \|_____|/ /
;     \ \_(_)_| /
;     \\\ \
;     / \/ \
;     \____\____/
;	(_____\_____)eD
;

PlotPIXP:
move.w    d0,d2        ; Copy the X coordinate to d2
lsr.w    #3,d0        ; Meanwhile, find the horizontal offset
; by dividing the X coordinate by 8.
add.w    d1,d1		; Multiply Y by 2, finding the offset
add.w    (a1,d1.w),d0    ; vertical offset + horizontal offset
and.w    #%111,d2    ; Select only the first 3 bits of X (rest)
not.w    d2        ; note
bset.b    d2,(a0,d0.w)    ; Set bit d2 of the byte distant d0 bytes
; from the beginning of the screen.
rts

; Routine that DELETES a pixel. Just replace BCLR with BSET.

ErasePIXP:
move.w    d0,d2        ; Copy the X coordinate to d2
lsr.w    #3,d0        ; Meanwhile, find the horizontal offset
; by dividing the X coordinate by 8.
add.w    d1,d1        ; Multiply Y by 2 to find the offset
add.w    (a1,d1.w),d0    ; vertical offset + horizontal offset
and.w	#%111,d2    ; Select only the first 3 bits of X (rest)
not.w    d2        ; note
bclr.b    d2,(a0,d0.w)    ; reset bit d2 of the byte distant d0 bytes
; from the beginning of the screen.
rts

*****************************************************************************

ReadTables:
move.l    a0,-(SP)    ; save a0 in the stack
ADDQ.L    #1,TABYPOINT     ; Point to the next byte
MOVE.L	TABYPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABY-1,A0 ; Are we at the last byte of TAB?
BNE.S    NOBSTARTY    ; Not yet? Then continue
MOVE.L    #TABY-1,TABYPOINT ; Start pointing to the first byte again
NOBSTARTY:
moveq    #0,d0        ; Clear d0
MOVE.b    (A0),d0        ; Copy the table byte, i.e. the
; Y coordinate in d0 so that it can be
; found by the universal routine

ADDQ.L    #2,TABXPOINT     ; Point to the next word
MOVE.L	TABXPOINT(PC),A0 ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0 ; Are we at the last word of the TAB?
BNE.S    NOBSTARTX    ; Not yet? Then continue
MOVE.L    #TABX-2,TABXPOINT ; Start pointing to the first word-2 again
NOBSTARTX:
moveq    #0,d1        ; reset d1
MOVE.w    (A0),d1        ; set the table value, i.e.
; the X coordinate in d1
move.w    d0,MioY        ; save the coordinates
move.w    d1,MioX
move.l	(sp)+,a0    ; retrieve a0 from the stack
rts


TABYPOINT:
dc.l    TABY-1        ; NOTE: the values in the table here are bytes
TABXPOINT:
dc.l    TABX-2        ; NOTE: the values in the table here are words

; Table with Y coordinates

TABY:
incbin    ‘ycoordinatok.tab’    ; 200 values .B
FINETABY:

; Table with X coordinates

TABX:
incbin    ‘xcoordinatok.tab’    ; 150 values .W
FINETABX:

*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:

dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w	$92,$0038	; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,$24    ; BplCon2 - All sprites above the bitplanes
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0		; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$1af    ; colour1 - TEXT

dc.w    $FFFF,$FFFE    ; End of copperlist


*****************************************************************************

SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    40*256    ; a lowres 320x256 bitplane

; Table containing the precalculated multiples of the screen width
; to eliminate multiplication in the PlotPIX routine, increasing its
; speed.

SECTION    Precalc,bss

MulTab:
ds.w    256

end

In this example, we have simply added the routine that reads the X and Y coordinates from the two
tables, as for sprites. As you can see, it is
also useful for point routines. By creating more complex tables and routines,
 you can obtain various waves.

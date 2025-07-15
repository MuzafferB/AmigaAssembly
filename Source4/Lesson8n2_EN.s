
; Lesson 8n2.s - Optimised plot printing routine.
;         The speed of this routine is tested in comparison with the
;         non-optimised routine. Press the RIGHT mouse button to
;         run the optimised routine, otherwise the normal routine will run.
;         Section

Section    dotta,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup1.s’    ; this include saves me from
; rewriting it every time!
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper and bitplane DMA enabled
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
move.w    d0,$88(a5)		; Let's start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

lea    bitplane,a0	; Address of the bitplane where to print in a0
lea    MulTab,a1    ; Address of the table with the multiples of
; screen width precalculated in a1

mouse:
bsr.s    Coordinates    ; loop of coordinates for the entire screen
move.w    MioX(PC),d0    ; X coordinate
move.w	MioY(PC),d1    ; Y coordinate

btst    #2,$16(a5)    ; Right mouse button pressed?
beq.s    Optimised
btst.b    #1,FaiSfai    ; Reset or set?
bne.s    Sfai
bsr.s    PlotPIX		; print the point at coord. X=d0, Y=d1
bra.s    OkPlottato
Sfai:
bsr.s    ErasePIX    ; reset the point at coord. X=d0, Y=d1
bra.s    OkPlottato

Optimised:
btst.b    #1,FaiSfai    ; Reset or Set?
bne.s    SfaiP
bsr.w    PlotPIXP    ; print the point at coordinates X=d0, Y=d1
bra.s    OkPlottato
SfaiP:
bsr.w    ErasePIXP    ; reset the point at coordinates X=d0, Y=d1
OkPlottato:
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts            ; exit



MioX:
dc.w    0
MioY:
dc.w    0
FaiSfai:
dc.w    0

;         ___
;         /_ -\
;         ( ¢ ¢ )
;         \ ° /
;         /¯\¬/¯\
;         / Y ·
;        · `

; Routine that continuously prints and clears the entire screen one
; point at a time.

Coordinates:
addq.w    #1,MioX        ; next pixel on the line
cmp.w    #320,MioX    ; last pixel on this line?
beq.s    EndLine    ; if so, start the one below!
rts            ; otherwise, do this point!

EndLine:
clr.w    MyX        ; start again from the beginning of the line
addq.w    #1,MyY        ; to the line below...
cmp.w    #256,MyY    ; Have we finished the screen? Last line?
beq.s    ChangeStart
rts

ChangeStart:
bchg.b    #1,DoDo    ; Change the write/clear status
clr.w    MyX        ; and start again from coordinate X=0
clr.w    MyY        ; Y=0
rts

*****************************************************************************
;        Normal dot plot routine
*****************************************************************************

;    PlotPIX input parameters:
;
;    a0 = Destination bitplane address
;    d0.w = X coordinate (0-319)
;    d1.w = Y coordinate (0-255)


PlotPIX:
move.w    d0,d2        ; Copy the X coordinate to d2
lsr.w	#3,d0        ; Meanwhile, find the horizontal offset,
; dividing the X coordinate by 8.
mulu.w    #screen width,d1
add.w    d1,d0        ; Add the vertical offset to the horizontal offset

and.w    #%111,d2    ; Select only the first 3 bits of X (rest)
not.w    d2

bset.b    d2,(a0,d0.w)    ; Set bit d2 of the byte d0 bytes away
; from the start of the screen.
rts

; Routine that DELETES a pixel. Just replace BCLR with BSET.

ErasePIX:
move.w    d0,d2		; Copy the X coordinate to d2
lsr.w    #3,d0        ; Meanwhile, find the horizontal offset by
; dividing the X coordinate by 8.
mulu.w    #screen width,d1
add.w    d1,d0        ; Add the vertical offset to the horizontal one

and.w    #%111,d2    ; Select only the first 3 bits of X (rest)
not.w    d2

bclr.b    d2,(a0,d0.w)    ; Clear bit d2 of the byte distant d0 bytes
; from the beginning of the screen.
rts

*****************************************************************************
; Optimised dot plotting routine
*****************************************************************************

;    PlotPIXP input parameters:
;
;    a0 = Destination bitplane address
;    a1 = Address of the table with precalculated multiples of 40
;    d0.w = X coordinate (0-319)
;    d1.w = Y coordinate (0-255)

PlotPIXP:
move.w    d0,d2        ; Copy the X coordinate to d2
lsr.w    #3,d0        ; Meanwhile, find the horizontal offset
; by dividing the X coordinate by 8.
add.w    d1,d1        ; Multiply Y by 2 to find the offset
add.w    (a1,d1.w),d0    ; vertical offset + horizontal offset
and.w    #%111,d2    ; Select only the first 3 bits of X
not.w    d2        ; note
bset    d2,(a0,d0.w)    ; Set bit d2 of the byte d0 bytes away
; from the start of the screen.
rts

; Routine that DELETES a pixel. Just replace BCLR with BSET.

ErasePIXP:
move.w    d0,d2        ; Copy the X coordinate to d2
lsr.w    #3,d0		; Meanwhile, find the horizontal offset,
; dividing the X coordinate by 8.
add.w    d1,d1        ; Multiply Y by 2, finding the offset
add.w    (a1,d1.w),d0    ; vertical offset + horizontal offset
and.w    #%111,d2    ; Select only the first 3 bits of X
not.w    d2        ; note
bclr    d2,(a0,d0.w)    ; reset bit d2 of the byte distant d0 bytes
; from the beginning of the screen.
rts

*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
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

SECTION	MIOPLANE,BSS_C

BITPLANE:
ds.b	40*256	; a lowres bitplane 320x256

; Table containing the precalculated multiples of the screen width
; to eliminate multiplication in the PlotPIX routine, increasing its
; speed.

SECTION    Precalc,bss

MulTab:
ds.w    256

end

This listing is intended as a test to verify whether the routine
without multiplication is actually faster. To this end, the entire screen is drawn
and then erased with ‘ErasePIX’, which is nothing more than the normal routine
with BCLR instead of BSET. Normally, the non-optimised routine is executed
; holding down the right mouse button executes the optimised one.
Depending on the computer and the presence of fast RAM, the difference will be
different. For example, if the table goes to CHIP RAM instead of FAST RAM, the
speed gained is less. For example, on the 68040, the multiplications are
much faster than on previous processors, to the point that if you
run this listing without fastram and with the caches disabled, the routine without multiplication is slower,
 since it has to access the table in CHIP
RAM. However, those who have an A4000 also have fast RAM, so don't worry. Furthermore, on 68030
or lower, removing a multiplication is always a good idea.

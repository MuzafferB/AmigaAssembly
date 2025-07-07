
; Lesson 10g1.s    BLITTATA, in which we draw striped rectangles on the screen
;        Right click to execute the blittata, left click to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

****************** ***********************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L	#BITPLANE1,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #1-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L	#40*256,d0    ; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106 (a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

; parameters for drawing routine

move.w    #16,d0            ; X upper left vertex
move.w    #10,d1            ; Y upper left vertex
move.w	#48,d2            ; width
move.w    #20,d3            ; height
move.w    #$aaaa,d4        ; drawing ‘pattern’
bsr.s    BlitRett        ; execute the drawing routine

mouse1:
btst    #2,$dff016	; right mouse button pressed?
bne.s    mouse1

; parameters for drawing routine

move.w    #64,d0            ; X upper left vertex
move.w    #70,d1            ; Y upper left vertex
move.w    #32,d2            ; width
move.w	#40,d3            ; height
move.w    #$8FF1,d4        ; drawing ‘pattern’
bsr.s    BlitRett        ; execute the drawing routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts

;****************************************************************************
; This routine draws a rectangle on the screen.
;
; D0 - X coordinate of the upper left corner
; D1 - Y coordinate of the upper left corner
; D2 - rectangle width in pixels
; D3 - rectangle height
; D4 - ‘pattern’ with which to draw a rectangle
;*************************************** *************************************

;     |\__/,| (`\
;     |o o |__ _) )
;     _.( T ) ` /
;     n n._ ((_ `^--‘ /_< \
;     <’ _ }=- `` `-‘(((/ (((/
;     `’ ’

BlitRett:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

; calculate the blitter's starting address

lea    bitplane1,a1    ; bitplane address
mulu.w    #40,d1        ; Y offset
add.l    d1,a1        ; add to address
lsr.w    #3,d0        ; divide X by 8
and.w    #$fffe,d0	; make it even
add.w    d0,a1        ; add to the bitplane address, finding
; the correct destination address

; calculate blitter module

lsr.w    #3,d2        ; divide the width by 8
and.w    #$fffe,d2    ; reset bit 0 (make it even)
move.w    #40,d5        ; screen width in bytes
sub.w    d2,d5        ; module=screen width-rectangle width

; calculate blitted size

lsl.w    #6,d3        ; height by 64
lsr.w    #1,d2        ; width in pixels divided by 16
; i.e. width in words
or    d2,d3        ; put the dimensions together

; load the registers

move.l    #$01f00000,$40(a5)    ; BLTCON0 and BLTCON1
; use ONLY channel D
; LF=$F0 (copy from A to D)
; ascending mode

move.w    d4,$74(a5)        ; BLTADAT
move.w    d5,$66(a5)        ; BLTDMOD
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w    d3,$58(a5)        ; BLTSIZE (start blitter!)

rts

;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200    ; bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$aaa    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;****** **********************************************************************

SECTION	bitplane,BSS_C

BITPLANE1:
ds.b	40*256

;*************************** *************************************************

end

In this example, we use the blitter to draw rectangles with a
‘pattern’, i.e. with a repeating graphic motif.
We use a parametric routine, which draws a rectangle knowing the
coordinates of the upper left corner and the dimensions (width and height)
of the rectangle. To simplify the routine, the width and X position
of the corner are approximated to multiples of 16.
The ‘pattern’ is also passed as a parameter in a register. In this way,
 with a single routine we can draw all the ‘patterns’ we want.

The drawing is done by a blitter that activates
only channel D, but copies the contents of the BLTADAT register to the output.
The same LF value used in normal copying from A
to D must be used, but channel A must not be activated. Therefore, the value to be written in
BLTCON0 is $01F0, i.e. LF=$F0 (copy from A to D) and only channel D is active.
The value of the ‘pattern’ to be copied to the output is written in the
BLTADAT register.


; Lesson 10p.s    Filling a polygon with lines with a slope < 45 degrees
;        Right click to select, left click to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:
;    Point to the ‘empty’ PIC

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

bsr.w    InitLine    ; initialise line mode

move.w    #$ffff,d0    ; continuous line
bsr.w    SetPattern    ; define pattern

move.w    #34,d0        ; x1 
move.w    #25,d1        ; y1
move.w    #130,d2		; x2
move.w    #80,d3        ; y2
lea    bitplane,a0
bsr.w    Drawline

move.w    #220,d0        ; x1
move.w    #25,d1        ; y1
move.w    #140,d2        ; x2
move.w    #80,d3		; y2
lea    bitplane,a0
bsr.s    Drawline

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1

move.w    #0,d0            ; inclusive
move.w    #0,d1			; CARRYIN=0
lea	bitplane+180*40+30,a0
bsr.s	Fill

mouse2:
btst	#6,$bfe001	; mouse premuto?
bne.s	mouse2


rts


;****************************************************************************
; This routine copies a rectangle of the screen from a fixed position
; to an address specified as a parameter. The rectangle of the screen that
; is copied completely encloses the two lines.
; During copying, filling is also performed. The type of filling
; is specified by the parameters.
; The parameters are:
; A0 - destination address
; D0 - if 0, perform inclusive fill, otherwise perform exclusive fill
; D1 - if 0, perform FILL_CARRYIN=0, otherwise FILL_CARRYIN=1
;****************************************************************************

;     (‘`-“”-/’).___..--“”"`-._
;     `6_ 6 ) `-. ( ).`-.__.`)
;     (_Y_.)“ ._ ) `._ `. ``-..-”
;     _..`--“_..-_/ /--'_.” ,“
;    (il),-”' (li),' ((!.-'

Fill:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.w    #$09f0,$40(a5)        ; BLTCON0 normal copy

tst.w    d0            ; head D0 to decide the type of fill
bne.s    fill_exclusive
move.w    #$000a,d2        ; value of BLTCON1: set the bits of
; inclusive fill and descending mode
bra.s    test_fill_carry

exclusive_fill:
move.w    #0012,d2        ; BLTCON1 value: set the bits for
; exclusive fill and descending mode

test_fill_carry:
tst.w    d1            ; check D1 to see if it needs to set
; the FILL_CARRYIN bit

beq.s    fatto_bltcon1        ; if D1=0, jump..
bset    #2,d2            ; otherwise, set bit 2 of D2

fatto_bltcon1:
move.w    d2,$42(a5)        ; BLTCON1

move.w    #14,$64(a5)        ; BLTAMOD width 13 words (40-26=14)
move.w    #14,$66(a5)        ; BLTDMOD (40-26=14)

move.l    #bitplane+80*40+28,$50(a5)
; BLTAPT (fixed to the source rectangle)
; the source rectangle encloses
; the entire 2 lines.
; we point to the last word of the rectangle
; because of the descending mode

move.l    a0,$54(a5)		; BLTDPT loads the parameter
move.w    #(64*56)+13,$58(a5)    ; BLTSIZE (start the blitter!)
; width 13 words
; height 56 lines (1 plane)
rts

;****************************************************************************

;******************************************************************************
; This routine draws the line. It takes as parameters the
; end points of the line P1 and P2, and the address of the bitplane on which to draw it.
; D0 - X1 (X coordinate of P1)
; D1 - Y1 (Y coordinate of P1)
; D2 - X2 (X coordinate of P2)
; D3 - Y2 (Y coordinate of P2)
; A0 - bitplane address
;******************************************************************************

Drawline:

* octant selection

sub.w    d0,d2        ; D2=X2-X1
bmi.s    DRAW4        ; if negative, skip; otherwise, D2=DiffX
sub.w    d1,d3        ; D3=Y2-Y1
bmi.s    DRAW2        ; if negative, skip, otherwise D3=DiffY
cmp.w    d3,d2        ; compare DiffX and DiffY
bmi.s    DRAW1        ; if D2<D3, skip..
; .. otherwise D3=DY and D2=DX
moveq    #$10,d5        ; octal code
bra.s    DRAWL
DRAW1:
exg.l    d2,d3        ; swap D2 and D3, so that D3=DY and D2=DX
moveq	#$00,d5        ; octal code
bra.s    DRAWL
DRAW2:
neg.w    d3        ; makes D3 positive
cmp.w    d3,d2        ; compares DiffX and DiffY
bmi.s    DRAW3        ; if D2<D3 skip..
; .. otherwise D3=DY and D2=DX
moveq    #$18,d5        ; octal code
bra.s    DRAWL
DRAW3:
exg.l    d2,d3        ; swap D2 and D3, so that D3=DY and D2=DX
moveq    #$04,d5        ; octal code
bra.s    DRAWL
DRAW4:
neg.w    d2        ; makes D2 positive
sub.w    d1,d3        ; D3=Y2-Y1
bmi.s    DRAW6		; if negative, jump, otherwise D3=DiffY
cmp.w    d3,d2        ; compare DiffX and DiffY
bmi.s    DRAW5        ; if D2<D3, jump...
; ... otherwise D3=DY and D2=DX
moveq    #$14,d5        ; octal code
bra.s    DRAWL
DRAW5:
exg.l    d2,d3        ; swap D2 and D3, so that D3=DY and D2=DX
moveq    #$08,d5        ; octane code
bra.s    DRAWL
DRAW6:
neg.w    d3        ; makes D3 positive
cmp.w    d3,d2        ; compare DiffX and DiffY
bmi.s    DRAW7        ; if D2<D3 skip..
; .. otherwise D3=DY and D2=DX
moveq    #$1c,d5        ; octal code
bra.s    DRAWL
DRAW7:
exg.l    d2,d3        ; swap D2 and D3, so that D3=DY and D2=DX
moveq    #$0c,d5        ; octal code

; When execution reaches this point, we have:
; D2 = DX
; D3 = DY
; D5 = octal code

DRAWL:
mulu.w    #40,d1        ; Y offset
add.l    d1,a0        ; adds the Y offset to the address

move.w    d0,d1        ; copies the X coordinate
and.w    #$000F,d0    ; selects the 4 lowest bits of X..
ror.w    #4,d0        ; .. and moves them to bits 12 to 15
or.w    #$0B4A,d0    ; with an OR I get the value to write
; in BLTCON0. With this LF value ($4A)
; lines are drawn in EOR with the background.

lsr.w    #4,d1        ; deletes the 4 low bits of X
add.w    d1,d1        ; obtains the X offset in bytes
add.w    d1,a0        ; adds the X offset to the address

move.w    d2,d1        ; copies DX to D1
addq.w    #1,d1        ; D1=DX+1
lsl.w    #$06,d1        ; calculates in D1 the value to put in BLTSIZE
addq.w	#2,d1        ; adds the width, equal to 2 words

lsl.w    #$02,d3        ; D3=4*DY
add.w    d2,d2        ; D2=2*DX

btst    #$06,$02(a5)
WaitLine:
btst    #$06,$02(a5)    ; wait for blitter to stop
bne.s    WaitLine

move.w    d3,$62(a5)    ; BLTBMOD=4*DY
sub.w    d2,d3		; D3=4*DY-2*DX
move.w    d3,$52(a5)    ; BLTAPTL=4*DY-2*DX

; prepare value to write to BLTCON1
or.w    #$0001,d5    ; set bit 0 (activate line mode)
tst.w    d3
bpl.s    OK1        ; if 4*DY-2*DX>0 skip..
or.w    #$0040,d5    ; otherwise set the SIGN bit
OK1:
move.w    d0,$40(a5)    ; BLTCON0
move.w    d5,$42(a5)    ; BLTCON1
sub.w    d2,d3        ; D3=4*DY-4*DX
move.w    d3,$64(a5)    ; BLTAMOD=4*DY-4*DX
move.l    a0,$48(a5)    ; BLTCPT - screen address
move.l    a0,$54(a5)    ; BLTDPT - screen address
move.w    d1,$58(a5)    ; BLTSIZE
rts


;******************************************************************************
; This routine sets the blitter registers that must not be
; changed between lines
;******************************************************************************

InitLine
btst    #6,2(a5) ; dmaconr
WBlit_Init:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    Wblit_Init

moveq    #-1,d5
move.l    d5,$44(a5)        ; BLTAFWM/BLTALWM = $FFFF
move.w    #$8000,$74(a5)        ; BLTADAT = $8000
move.w    #40,$60(a5)        ; BLTCMOD = 40
move.w    #40,$66(a5)        ; BLTDMOD = 40
rts

;******************************************************************************
; This routine defines the pattern to be used to draw
; the lines. In practice, it simply sets the BLTBDAT register.
; D0 - contains the line pattern
;******************************************************************************
SetPattern
btst    #6,2(a5) ; dmaconr
WBlit_Set:
btst	#6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    Wblit_Set

move.w    d0,$72(a5)    ; BLTBDAT = line pattern
rts


;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200    ; Bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w    $e0,$0000,$e2,$0000	;first bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

Section	IlMioPlane,bss_C

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

;****************************************************************************

In this example, the area to be filled is delimited by lines with a slope
less than 45 degrees. As we explained in the lesson, under these conditions
the filling is not done correctly.
To solve this problem, we need to use a special way of
drawing lines, as we will see in the next example.

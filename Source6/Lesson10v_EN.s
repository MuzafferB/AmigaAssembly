
; Lesson 10v.s    Rotating polygon.
;        Left button to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:
;	Puntiamo la PIC ‘vuota’

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W	#DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

move.w    #$ffff,d0    ; continuous line
bsr.w	SetPattern    ; defines pattern

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0	; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1

bsr.w    ClearScreen    ; clears the screen

bsr.w    MovePoints    ; changes the coordinates of the points

bsr.w    InitLine    ; initialises line mode

; draws the line between points 1 and 2

move.w	Point1(pc),d0
move.w    Point1+2(pc),d1
move.w    Point2(pc),d2
move.w    Point2+2(pc),d3
lea    bitplane,a0
bsr.w    Drawline

; draw the line between points 2 and 3

move.w    Point2(pc),d0
move.w    Point2+2(pc),d1
move.w    Point3(pc),d2
move.w    Point3+2(pc),d3
lea    bitplane,a0
bsr.w    Drawline

; draw the line between points 3 and 4

move.w    Point3(pc),d0
move.w    Point3+2(pc),d1
move.w    Point4(pc),d2
move.w    Point4+2(pc),d3
lea    bitplane,a0
bsr.w    Drawline

; draw the line between points 4 and 1

move.w    Point4(pc),d0
move.w    Point4+2(pc),d1
move.w    Point1(pc),d2
move.w    Point1+2(pc),d3
lea    bitplane,a0
bsr.w    Drawline

moveq    #0,d0
moveq    #0,d1
lea    bitplane+178*40-2,a0
bsr.w	Fill

btst    #6,$bfe001    ; mouse pressed?
bne.w    mouse
rts

;***************************************************************************
; This routine reads the coordinates of the various points from a table and
; stores them in the appropriate variables.
;***************************************************************************

;     _
;     _/\/¯/
;     \___/
;     / \
;     / o O \
;     (_______)
;     _| / \ |_
;     / |(___)| \
;     / l_____| \
;    Y | U | Y
;	| ¦ l___| ¦ .|
;    | ¡ ¡ :|
;    l__|-------l__|
;     | .|
;     | ¡ :|
;     | ¦ ·|
;     | ¦ |
;    .-`----·----'-.
;    ¡_____| l_____¡bHe

MovePoints:
ADDQ.L	#2,TABXPOINT        ; Point to the next word
MOVE.L    TABXPOINT(PC),A0    ; address contained in long TABXPOINT
; copied to a0
CMP.L    #FINETABX-2,A0     ; Are we at the last word of the TAB?
BNE.S	NOBSTARTX        ; Not yet? Then continue
MOVE.L    #TABX-2,TABXPOINT     ; Start pointing to the first word-2 again
NOBSTARTX:
MOVE.W	(A0),Point1        ; copy the value of the coordinate
; of point 1 into the appropriate variable

LEA    50(A0),A0        ; Coordinate of the next point
CMP.L    #FINETABX-2,A0         ; Are we at the last word of the TAB?
BLE.S	NOBSTARTX2        ; no, then read
SUB.L    #FINETABX-TABX,A0     ; otherwise, go back to the
; table
NOBSTARTX2:
MOVE.W    (A0),Point2        ; copy the value of the coordinate
; of point 2 to the appropriate variable

LEA    50(A0),A0        ; Coordinate of the next point
CMP.L    #FINETABX-2,A0         ; Are we at the last word of the TAB?
BLE.S    NOBSTARTX3        ; no, then read
SUB.L    #FINETABX-TABX,A0     ; otherwise go back to the
; table
NOBSTARTX3:
MOVE.W    (A0),Point3        ; copy the value of the coordinate
; of point 3 to the appropriate variable

LEA    50(A0),A0        ; Coordinate of the next point
CMP.L    #FINETABX-2,A0         ; Are we at the last word of the TAB?
BLE.S	NOBSTARTX4        ; no, then read
SUB.L    #FINETABX-TABX,A0     ; otherwise, go back to
; table
NOBSTARTX4:
MOVE.W    (A0),Point4        ; copy the value of the coordinate
; of point 4 to the appropriate variable

ADDQ.L	#2,TABYPOINT        ; Point to the next word
MOVE.L    TABYPOINT(PC),A0    ; address contained in long TABYPOINT
; copied to a0
CMP.L    #FINETABY-2,A0     ; Are we at the last word of the TAB?
BNE.S    NOBSTARTY        ; Not yet? Then continue
MOVE.L    #TABY-2,TABYPOINT     ; Start pointing again from the first word-2
NOBSTARTY:
MOVE.W    (A0),Point1+2        ; copy the value of the coordinate
; of point 1 into the appropriate variable

LEA    50(A0),A0        ; Coordinate of the next point
CMP.L    #FINETABY-2,A0	 	; Are we at the last word of the TAB?
BLE.S    NOBSTARTY2        ; no, then read
SUB.L    #FINETABY-TABY,A0     ; otherwise go back to the
; table
NOBSTARTY2:
MOVE.W    (A0),Point2+2        ; copy the value of the coordinate
; of point 2 to the appropriate variable

LEA    50(A0),A0        ; Coordinate of the next point
CMP.L    #FINETABY-2,A0         ; Are we at the last word of the TAB?
BLE.S    NOBSTARTY3        ; no, then read
SUB.L    #FINETABY-TABY,A0     ; otherwise, return to the
; table
NOBSTARTY3:
MOVE.W    (A0),Point3+2        ; copy the value of the coordinate
; of point 3 to the appropriate variable

LEA	50(A0),A0        ; Coordinate of the next point
CMP.L    #FINETABY-2,A0         ; Are we at the last word of the TAB?
BLE.S    NOBSTARTY4        ; no, then read
SUB.L    #FINETABY-TABY,A0     ; otherwise, go back to the
; table
NOBSTARTY4:
MOVE.W    (A0),Point4+2        ; copy the value of the coordinate
; of point 4 into the appropriate variable
rts

TABXPOINT:
dc.l    TABX    ; pointer to the X table

; X position table

TABX:
DC.W    $00D2,$00D2,$00D1,$00D1,$00D0,$00CF,$00CE,$00CD,$00CB,$00C9
DC.W	$00C8,$00C6,$00C3,$00C1,$00BF,$00BC,$00B9,$00B7,$00B4,$00B1
DC.W	$00AE,$00AB,$00A8,$00A5,$00A2,$009E,$009B,$0098,$0095,$0092
DC.W	$008F,$008C,$0089,$0087,$0084,$0081,$007F,$007D,$007A,$0078
DC.W	$0077,$0075,$0073,$0072,$0071,$0070,$006F,$006F,$006E,$006E
DC.W	$006E,$006E,$006F,$006F,$0070,$0071,$0072,$0073,$0075,$0077
DC.W	$0078,$007A,$007D,$007F,$0081,$0084,$0087,$0089,$008C,$008F
DC.W	$0092,$0095,$0098,$009B,$009E,$00A2,$00A5,$00A8,$00AB,$00AE
DC.W	$00B1,$00B4,$00B7,$00B9,$00BC,$00BF,$00C1,$00C3,$00C6,$00C8
DC.W    $00C9,$00CB,$00CD,$00CE,$00CF,$00D0,$00D1,$00D1,$00D2,$00D2

FINETABX:

TABYPOINT:
dc.l    TABY    ; pointer to table Y

TABY:
DC.W    $0081,$0084,$0087,$008A,$008D,$0090,$0093,$0096,$0098,$009B
DC.W	$009E,$00A0,$00A2,$00A5,$00A7,$00A8,$00AA,$00AC,$00AD,$00AE
DC.W	$00AF,$00B0,$00B0,$00B1,$00B1,$00B1,$00B1,$00B0,$00B0,$00AF
DC.W	$00AE,$00AD,$00AC,$00AA,$00A8,$00A7,$00A5,$00A2,$00A0,$009E
DC.W	$009B,$0098,$0096,$0093,$0090,$008D,$008A,$0087,$0084,$0081
DC.W	$007D,$007A,$0077,$0074,$0071,$006E,$006B,$0068,$0066,$0063
DC.W	$0060,$005E,$005C,$0059,$0057,$0056,$0054,$0052,$0051,$0050
DC.W	$004F,$004E,$004E,$004D,$004D,$004D,$004D,$004E,$004E,$004F
DC.W	$0050,$0051,$0052,$0054,$0056,$0057,$0059,$005C,$005E,$0060
DC.W	$0063,$0066,$0068,$006B,$006E,$0071,$0074,$0077,$007A,$007D
FINETABY:

; The coordinates of the polygon points are stored here

Point1:    dc.w    100,20
Point2:    dc.w    200,20
Point3:    dc.w    200,40
Point4:    dc.w    100,40


;****************************************************************************
; This routine copies a screen rectangle from a fixed position
; to an address specified as a parameter. The screen rectangle that
; is copied completely encloses the 2 lines.
; During copying, filling is also performed. The type of filling
; is specified by the parameters.
; The parameters are:
; A0 - address of the rectangle to be filled
; D0 - if 0, then perform inclusive fill, otherwise perform exclusive fill
; D1 - if 0, then perform FILL_CARRYIN=0, otherwise FILL_CARRYIN=1
;****************************************************************************

Fill:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.w    #$09f0,$40(a5)        ; BLTCON0 normal copy

tst.w    d0            ; check D0 to decide the type of fill
bne.s    fill_exclusive
move.w	#$000a,d2        ; BLTCON1 value: set the bits of the
; inclusive fill and descending mode
bra.s    test_fill_carry

fill_esclusivo:
move.w    #$0012,d2		; BLTCON1 value: set the bits for
; exclusive fill and descending mode

test_fill_carry:
tst.w    d1            ; check D1 to see if
; the FILL_CARRYIN bit

beq.s    fatto_bltcon1        ; if D1=0, jump..
bset    #2,d2            ; otherwise set bit 2 of D2

fatto_bltcon1:
move.w    d2,$42(a5)        ; BLTCON1

move.w    #0,$64(a5)        ; BLTAMOD width 20 words (40-40=0)
move.w    #0,$66(a5)        ; BLTDMOD (40-40=0)

move.l    a0,$50(a5)        ; BLTAPT - address to the rectangle
; the source rectangle encloses
; the entire polygon
; we point to the last word of the rectangle
; because of the descending mode

move.l    a0,$54(a5)		; BLTDPT - rectangle address
move.w    #(64*100)+20,$58(a5)    ; BLTSIZE (start blitter!)
; width 20 words
rts                ; height 100 lines (1 plane)


;******************************************************************************
; This routine draws the line. It takes as parameters the
; endpoints of the line P1 and P2, and the address of the bitplane on which to draw it.
; D0 - X1 (X coordinate of P1)
; D1 - Y1 (Y coordinate of P1)
; D2 - X2 (coord. X of P2)
; D3 - Y2 (coord. Y of P2)
; A0 - bitplane address
;******************************************************************************

; constants

DL_Fill        =    1        ; 0=NOFILL / 1=FILL

IFEQ DL_Fill
DL_MInterns = $CA
ELSE
DL_MInterns = $4A
ENDC


DrawLine:
sub.w d1,d3 ; D3=Y2-Y1

IFNE DL_Fill
beq.s .end ; horizontal lines are not needed for filling
ENDC

bgt.s .y2gy1 ; skip if positive...
exg d0,d2 ; ...otherwise swap the points
add.w d3,d1 ; put the smaller Y in D1
neg.w d3	; D3=DY
.y2gy1:
mulu.w    #40,d1        ; Y offset
add.l    d1,a0
moveq    #0,d1        ; D1 index in the octant table
sub.w    d0,d2        ; D2=X2-X1
bge.s    .xdpos        ; skip if positive..
addq.w    #2,d1        ; ..otherwise move the index
neg.w    d2        ; and make the difference positive
.xdpos:
moveq    #$f,d4        ; mask for the 4 low bits
and.w    d0,d4        ; select them in D4

IFNE    DL_Fill        ; these instructions are assembled
; only if DL_Fill=1
move.b    d4,d5        ; calculate the number of bits to invert
not.b    d5        ; (BCHG numbers the bits in reverse order    
ENDC

lsr.w    #3,d0        ; X offset:
; Align to byte (used for BCHG)
add.w    d0,a0        ; add to address
; note that even if the address
; is odd, it does nothing because
; the blitter does not take into account the
; least significant bit of BLTxPT

ror.w    #4,d4        ; D4 = shift value A
or.w    #$B00+DL_MInterns,d4	; adds the appropriate
; Minterm (OR or EOR)
swap    d4        ; value of BLTCON0 in the high word

cmp.w    d2,d3        ; compares DiffX and DiffY
bge.s    .dygdx        ; jumps if >=0..
addq.w    #1,d1		; otherwise set bit 0 of the index
exg    d2,d3        ; and swap the Diff
.dygdx:
add.w    d2,d2        ; D2 = 2*DiffX
move.w    d2,d0        ; copy to D0
sub.w    d3,d0		; D0 = 2*DiffX-DiffY
addx.w    d1,d1        ; multiply the index by 2 and
; simultaneously add the flag
; X which is 1 if 2*DiffX-DiffY<0
; (set by sub.w)
move.b	Oktants(PC,d1.w),d4    ; reads the octant
swap    d2            ; BLTBMOD value in high word
move.w    d0,d2            ; low word D2=2*DiffX-DiffY
sub.w    d3,d2			; low word D2=2*DiffX-2*DiffY
moveq    #6,d1            ; shift and test value for
; the blitter wait 

lsl.w    d1,d3        ; calculates the value of BLTSIZE
add.w    #$42,d3

lea    $52(a5),a1	; A1 = BLTAPTL address
; writes some registers
; consecutively with 
; MOVE #XX,(Ax)+

btst    d1,2(a5)    ; waits for the blitter
.wb:
btst    d1,2(a5)
bne.s    .wb

IFNE DL_Fill        ; this instruction is assembled
; only if DL_Fill=1
bchg d5,(a0)        ; Inverts the first bit of the line
ENDC

move.l d4,$40(a5)    ; BLTCON0/1
move.l d2,$62(a5)	; BLTBMOD and BLTAMOD
move.l    a0,$48(a5)    ; BLTCPT
move.w    d0,(a1)+    ; BLTAPTL
move.l    a0,(a1)+    ; BLTDPT
move.w    d3,(a1)        ; BLTSIZE
.end:
rts

;ÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂ; if we want to execute lines for the fill, the octal code sets bit
; SING to 1 through the constant SML

IFNE    DL_Fill
SML        =     2
ELSE
SML        =    0
ENDC

; octant table

Oktants:
dc.b    SML+1,SML+1+$40
dc.b    SML+17,SML+17+$40
dc.b	SML+9,SML+9+$40
dc.b    SML+21,SML+21+$40

;******************************************************************************
; This routine sets the blitter registers that must not be
; changed between one line and another
;******************************************************************************

InitLine:
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

SetPattern:
btst    #6,2(a5) ; dmaconr
WBlit_Set:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    Wblit_Set

move.w    d0,$72(a5)    ; BLTBDAT = line pattern
rts

;****************************************************************************
; Questa routine cancella lo schermo mediante il blitter.
;****************************************************************************

ClearScreen:
move.l    #bitplane+78*40,a0    ; address of area to be cleared

btst    #6,2(a5)
WBlit3:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit3

move.l	#$01000000,$40(a5)    ; BLTCON0 and BLTCON1: Clear
move.w    #$0000,$66(a5)        ; BLTDMOD=0
move.l    a0,$54(a5)        ; BLTDPT
move.w    #(64*100)+20,$58(a5)    ; BLTSIZE (start the blitter!)
; clear the entire screen
rts


;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0		; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
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

In this example, we create a rotating polygon.
The polygon is made up of 4 points whose position is modified at each
frame by reading it from a precalculated table. This technique involves a large
waste of memory. Later in the course, we will see how to calculate the coordinates
of the points using mathematical formulas.
To draw the polygon, simply draw the sides and fill them in. Before
drawing, it is obviously necessary to clear the screen
with the blitter.
The area of the screen to be cleared and the area to be filled have been calculated
so as to always include the entire polygon.

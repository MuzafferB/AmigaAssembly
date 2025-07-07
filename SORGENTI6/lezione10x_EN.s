
; Lesson 10x.s    Morphing effect!!!!!!! Coded by Executor/RAM JAM

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:
lea    $dff000,a5		; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w	#0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1

bsr.w    SwapBuffer    ; this routine swaps the 2 buffers

bsr.w    ClearScreen    ; clears the drawing buffer

bsr.w    DO_IT		; line drawing routine
bsr.w    DO_ANIM        ; routine that manages the animation
 

moveq    #0,d0            ; exclusive
moveq    #0,d1            ; CARRYIN=0
move.l    draw_buffer(pc),a0
bsr.w    FILL            ; fill drawing buffer

bsr.w    MORPH        ; calculate the next frame

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts


;******************************************************************************
; This routine draws the line. It takes as parameters the
; endpoints of the line P1 and P2, and the address of the bitplane on which to draw it.
; D0 - X1 (X coordinate of P1)
; D1 - Y1 (Y coordinate of P1)
; D2 - X2 (X coordinate of P2)
; D3 - Y2 (Y coordinate of P2)
; A0 - bitplane address
;******************************************************************************

; constants

DL_Fill        =    1    ; 0=NOFILL / 1=FILL

IFEQ	DL_Fill
DL_MInterns    =    $CA
ELSE
DL_MInterns    =    $4A
ENDC


DrawLine:
sub.w    d1,d3    ; D3=Y2-Y1

IFNE    DL_Fill
beq.s    .end    ; horizontal lines are not needed for filling 
ENDC

bgt.s    .y2gy1    ; skip if positive..
exg    d0,d2    ; ..otherwise swap the points
add.w    d3,d1    ; put the smaller Y in D1
neg.w    d3    ; D3=DY
.y2gy1:
mulu.w    #40,d1		; Y offset
add.l    d1,a0
moveq    #0,d1        ; D1 index in the octane table
sub.w    d0,d2        ; D2=X2-X1
bge.s    .xdpos        ; skip if positive..
addq.w    #2,d1		; ..otherwise move the index
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
; Align to byte (needed for BCHG)
add.w    d0,a0        ; add to address
; note that even if the address
; is odd, it does nothing because
; the blitter does not take into account the
; least significant bit of BLTxPT

ror.w    #4,d4		; D4 = shift value A
or.w    #$B00+DL_MInterns,d4    ; adds the appropriate
; Minterm (OR or EOR)
swap    d4        ; value of BLTCON0 in the high word

cmp.w    d2,d3        ; compares DiffX and DiffY
bge.s    .dygdx        ; skip if >=0..
addq.w    #1,d1        ; otherwise set bit 0 of the index
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
move.w    d0,d2			; low word D2=2*DiffX-DiffY
sub.w    d3,d2            ; low word D2=2*DiffX-2*DiffY
moveq    #6,d1            ; shift and test value for
; the blitter wait 

lsl.w    d1,d3		; calculate the value of BLTSIZE
add.w    #$42,d3

lea    $52(a5),a1    ; A1 = BLTAPTL address
; write some registers
; consecutively with 
; MOVE #XX,(Ax)+

btst    d1,2(a5)    ; wait for the blitter
.wb:
btst    d1,2(a5)
bne.s    .wb

IFNE    DL_Fill        ; this instruction is assembled
; only if DL_Fill=1
bchg    d5,(a0)        ; Inverts the first bit of the line
ENDC

move.l    d4,$40(a5)    ; BLTCON0/1
move.l    d2,$62(a5)    ; BLTBMOD and BLTAMOD
move.l    a0,$48(a5)	; BLTCPT
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
dc.b    SML+9,SML+9+$40
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

moveq	#-1,d5
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
btst	#6,2(a5) ; dmaconr
WBlit_Set:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    Wblit_Set

move.w    d0,$72(a5)    ; BLTBDAT = line pattern
rts


;****************************************************************************
; This routine swaps the two buffers by swapping the addresses in
; the VIEW_BUFFER and DRAW_BUFFER variables.
; It also updates the instructions in the copperlist that load the
; BPLxPT registers so that they point to the new buffer to be displayed.
;****************************************************************************

SwapBuffer:
move.l    draw_buffer(pc),d0        ; swaps the contents
move.l    view_buffer(pc),draw_buffer    ; of the variables
move.l    d0,view_buffer            ; d0 contains the address
; of the new buffer
; to be displayed

; update the copperlist pointing to the bitplanes of the new buffer to be displayed

LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
rts

; pointers to the 2 buffers

view_buffer:    dc.l    BITPLANE1    ; buffer displayed
draw_buffer:    dc.l    BITPLANE1b    ; drawing buffer

;****************************************************************************
; This routine clears the screen using the blitter.
; the screen address is read from the DRAW_BUFFER variable
;****************************************************************************

ClearScreen:
move.l	draw_buffer(pc),a0    ; drawing buffer address

btst    #6,2(a5)
WBlit3:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit3

move.l    #$01000000,$40(a5)    ; BLTCON0 and BLTCON1: Clear
move.w    #0000,66(a5)        ; BLTDMOD=0
move.l    a0,54(a5)        ; BLTDPT
move.w    (64*256)+20,58(a5)	; BLTSIZE (start blitter!)
; clear entire screen
rts

;****************************************************************************
; This routine copies a rectangle of the screen from a fixed position
; to an address specified as a parameter. The screen rectangle that
; is copied completely encloses the two lines.
; During copying, filling is also performed. The type of
; filling is specified by the parameters.
; The parameters are:
; A0 - address of the rectangle to be filled
; D0 - if 0, perform inclusive fill, otherwise perform exclusive fill
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
move.w    #000a,d2        ; value of BLTCON1: set the bits of
; inclusive fill and descending mode
bra.s    test_fill_carry

exclusive fill:
move.w    #0012,d2        ; BLTCON1 value: set the bits for
; exclusive fill and descending mode

test_fill_carry:
tst.w    d1			; check D1 to see if it needs to set
; the FILL_CARRYIN

beq.s    fatto_bltcon1        ; if D1=0, skip..
bset    #2,d2            ; otherwise, set bit 2 of D2

fatto_bltcon1:
move.w    d2,$42(a5)        ; BLTCON1

move.w    #0,$64(a5)        ; BLTAMOD width 20 words (40-40=0)
move.w    #0,$66(a5)        ; BLTDMOD (40-40=0)

lea    40*256-2(a0),a0        ; point to the last word of the rectangle
; because of the descending mode

move.l    a0,$50(a5)        ; BLTAPT - address to the rectangle
; the source rectangle encloses
; the entire polygon

move.l    a0,$54(a5)		; BLTDPT - rectangle address
move.w    #(64*256)+20,$58(a5)    ; BLTSIZE (start blitter!)
; width 20 words
; height 256 lines (1 plane)
rts

******************************************************************************
; This routine calculates the points that make up an intermediate frame.
; The morph is created as follows: for each point, the
; relative coordinates are taken in the starting frame (source) and in the destination frame
; (destination) and the differences are calculated. These differences are the distance
; (along the X and Y axes, respectively) that the point must travel to
; go from its position in the starting frame to its position in the arrival frame.
; This distance must be travelled in a variable number of frames, which
; is stored in the MAXSTEP variable. Dividing the distance by the 
; number of frames, we obtain the amount of space that the point must
; travel in each frame. Multiplying this amount by the number of
; frames drawn and adding the starting position gives us the
; current position of the point.
; The formula for calculating the value of the X coordinate in the current frame
; is therefore as follows:

; Current_X = Starting_X + (Arrival_X - Starting_X) * Current_Frame / Number_of_frames.

; The formula for Y is the same. The coordinates X_arrival and X_start are
; stored in the data of each frame, while Current_frame and Number_frames are
; stored in the variables STEP and MAXSTEP, respectively. These formulas
; are applied by the ‘MORPH’ routine to the coordinates of all the points that
; make up a frame.
******************************************************************************

;     _./\._
;     \ __ /
;     ·\/ \
;     /_____\
;     ·¯ ¯·
;     \ o O /
;     ( ^ )
;     _`---'_
;     / ¯ ¯ \
;    / __ __ \
;    \__/---\__/
;     | . |
;     _|__¦__|_
;    /____l____\bHe

MORPH:
moveq    #24-1,d7    ; 24 points per frame

move.l    MAXSTEP(PC),d5    ; d5 = total number of intermediate frames

move.l    STEP(PC),d6    ; d6 = current frame counter

lea	POINTS(PC),a2    ; A2 = points vector
move.l    SOURFRM(PC),a0
move.l    (a0),a0        ; A0 = starting frame
move.l	DESTFRM(PC),a1
move.l    (a1),a1        ; A1 = destination frame

; Calculate the coordinates of the intermediate frame points

ProcX:
moveq    #0,d0
move.w	(a1)+,d0    ; d0 = x1
sub.w    (a0),d0        ; d0 = x1-x0
muls.w    d6,d0        ; d0 = (x1-x0)·d6
divs.w    d5,d0		; d0 = (x1-x0)·d6/d5
add.w    (a0)+,d0    ; d0 = x0+(x1-x0)·d6/d5
ProcY:
moveq    #0,d1
move.w	(a1)+,d1    ; d1 = y1
sub.w    (a0),d1        ; d1 = y1-y0
muls.w    d6,d1        ; d1 = (y1-y0)·d6
divs.w    d5,d1        ; d1 = (y1-y0)·d6/d5
add.w	(a0)+,d1    ; d1 = y0+(y1-y0)·d6/d5

move.w    d0,(a2)+    ; store intermediate frame coordinates
move.w    d1,(a2)+

dbra    d7,ProcX    ; Execute for all points
addq.l    #1,STEP        ; increase current frame counter
rts


*****************************************************************************
; Routine that manages the animation
*****************************************************************************

DO_ANIM:
tst.l    FX        ; head counter
bne.s    DO_AM        ; if not 0, skip..

move.l    SCRIPT(PC),a0    ; ..otherwise read the address of the point
; of the animation where we are.
AT:
tst.l    (a0)
bne.s    DO_X
tst.l    4(a0)
bne.s    DO_X        ; if the pointers to the frames are not 0
; skip.. 

RESTART:
lea	STORY(PC),a0    ; otherwise restart the animation from the beginning
bra.s    AT

DO_X:
move.l    (a0)+,SOURFRM    ; read new source frame
move.l    (a0)+,DESTFRM    ; read new destination frame
move.l    (a0)+,MAXSTEP    ; new number of intermediate frames
move.l    MAXSTEP(PC),FX    ; copy it to the counter
move.l    a0,SCRIPT    ; store animation arrival point
move.l    #1,STEP        ; initialise intermediate frame counter
DO_AM:
subq.l    #1,FX        ; decrement counter
rts


****************************************************************************
; This routine draws the lines that form the current frame
****************************************************************************

DO_IT:
lea    POINTS(PC),a3    ; current frame point vector
moveq    #24-1,d7    ; 24 points for each frame
bsr.w    InitLine    ; initialise line mode

move.w    #$ffff,d0    ; continuous line
bsr.w    SetPattern    ; defines pattern

move.l    (a3),-(a7)    ; stores coordinates at the first point
AnimLoop:
movem.w    (a3)+,d0-d1	; read coordinates of i-th point
movem.w    (a3),d2-d3    ; read coordinates of (i+1)-th point
tst.w    d7
bne.s    NoLast        ; if we are not at the last point, skip..
movem.w    (a7)+,d2-d3    ; ..otherwise, last point = first point
NoLast:
move.l    draw_buffer(pc),a0    ; drawing buffer ind.
bsr.w    DrawLine        ; draw line
dbra    d7,AnimLoop
rts

**************************
; Variables
**************************

; Pointer to the current phase of the animation

SCRIPT:    dc.l    STORY

; counter to signal the transition from one phase to another

FX:    dc.l    0

; number of intermediate frames between the source and destination

MAXSTEP:    dc.l    200

; current intermediate frame number

STEP:        dc.l	1

; source frame address

SOURFRM:    dc.l    FRM1

; destination frame address

DESTFRM:	dc.l    FRM2

; Animation: each phase has a source frame, a destination frame, and 
; the morphing time, i.e. the number of intermediate frames that must
; be generated. For example, the first phase goes from frame FRM1 to frame FRM2
; in 24 intermediate frames.

STORY:
dc.l    FRM1,FRM2,24
dc.l    FRM2,FRM3,24
dc.l    FRM3,FRM4,24
dc.l    FRM4,FRM5,24
dc.l    FRM5,FRM6,24
dc.l    FRM6,FRM7,24
dc.l    FRM7,FRM8,24
dc.l    FRM8,FRM9,24
dc.l    FRM9,FRM10,24
dc.l	FRM10,FRM11,24
dc.l	FRM11,FRM12,24
dc.l	FRM12,FRM13,24
dc.l	FRM13,FRM14,24
dc.l	FRM14,FRM15,24
dc.l	FRM15,FRM16,12
dc.l    FRM16,FRM17,12
dc.l    FRM17,FRM18,24
dc.l    FRM18,FRM19,24
dc.l    FRM19,FRM20,24
dc.l    FRM20,FRM21,24
dc.l    FRM21,FRM22,24
dc.l    FRM22,FRM23,24
dc.l	FRM23,FRM23,48
dc.l	FRM23,FRM24,24
dc.l	FRM24,FRM25,24
dc.l	FRM25,FRM26,24
dc.l	FRM26,FRM27,24
dc.l	FRM27,FRM26,24
dc.l	FRM26,FRM27,24
dc.l	FRM27,FRM26,24
dc.l	FRM26,FRM27,24
dc.l	FRM27,FRM28,24
dc.l	FRM28,FRM29,24
dc.l	FRM29,FRM30,96
dc.l	FRM30,FRM31,24
dc.l	FRM31,FRM32,24
dc.l	FRM32,FRM31,24

dc.l    0,0            ; end

; Vector containing the coordinates of the intermediate frame

POINTS:
dcb.b    24*4,0

***************************************************************************
; Frame data: for each frame there are the X and Y coordinates of the points
; that form it.
***************************************************************************

FRAMES:
FRAME1:
dc.w	$13F,$7E,$13F,$AE,$13F,$FF,$11C,$FF,$DA,$FF,$A5
dc.w	$FF,$87,$FF,$6E,$FF,$4A,$FF,$2E,$FF,$13,$FF,0,$FF
dc.w	0,$C8,0,$B6,0,$A5,0,$82,0,$38,0,0,$15,0,$7E,0,$95
dc.w	0,$DF,0,$13F,0,$13F,$37
FRAME2:
dc.w	$C9,$68,$C7,$76,$C2,$82,$BA,$8D,$AF,$95,$A3,$9A
dc.w	$96,$9B,$88,$9A,$7C,$95,$71,$8D,$69,$82,$64,$76
dc.w	$63,$68,$64,$5B,$69,$4F,$71,$44,$7C,$3C,$88,$37
dc.w	$96,$35,$A3,$37,$AF,$3C,$BA,$44,$C2,$4F,$C7,$5B
FRAME3:
dc.w	$13F,$6F,$C7,$76,$C2,$82,$BA,$8D,$AF,$95,$A3,$9A
dc.w	$95,$FF,$88,$9A,$7C,$95,$71,$8D,$69,$82,$64,$76,0
dc.w	$69,$64,$5B,$69,$4F,$71,$44,$7C,$3C,$88,$37,$94,0
dc.w	$A3,$37,$AF,$3C,$BA,$44,$C2,$4F,$C7,$5B
FRAME4:
dc.w	$13F,$6A,$6E,$4F,$69,$5B,$61,$66,$56,$6E,$4A,$73
dc.w	$9D,$FF,$2F,$73,$23,$6E,$18,$66,$10,$5B,11,$4F,0
dc.w	$82,11,$34,$10,$28,$18,$1D,$23,$15,$2F,$10,$9A,0
dc.w	$4A,$10,$56,$15,$61,$1D,$69,$28,$6E,$34
FRAME5:
dc.w	$13F,$5A,$123,$BF,$11E,$CB,$116,$D6,$10B,$DE,$FF
dc.w	$E3,$86,$FF,$E4,$E3,$D8,$DE,$CD,$D6,$C5,$CB,$C0
dc.w	$BF,0,$77,$C0,$A4,$C5,$98,$CD,$8D,$D8,$85,$E4,$80
dc.w	$84,0,$FF,$80,$10B,$85,$116,$8D,$11E,$98,$123,$A4
FRAME6:
dc.w	$13F,$8F,$128,$5A,$123,$66,$11B,$71,$110,$79,$104
dc.w	$7E,$86,$FF,$E9,$7E,$DD,$79,$D2,$71,$CA,$66,$C5
dc.w	$5A,0,$75,$C5,$3F,$CA,$33,$D2,$28,$DD,$20,$E9,$1B
dc.w	$91,0,$104,$1B,$110,$20,$11B,$28,$123,$33,$128
dc.w	$3F
FRAME7:
dc.w	$13F,$7A,$75,$BE,$70,$CA,$68,$D5,$5D,$DD,$51,$E2
dc.w	$A7,$FF,$36,$E2,$2A,$DD,$1F,$D5,$17,$CA,$12,$BE,0
dc.w	$72,$12,$A3,$17,$97,$1F,$8C,$2A,$84,$36,$7F,$A1,0
dc.w	$51,$7F,$5D,$84,$68,$8C,$70,$97,$75,$A3
FRAME8:
dc.w    $9D,$77,$C7,$7F,$C2,$8B,$9E,$7B,$AF,$9E,$A3,$A3
dc.w    $9A,$7C,$88,$A3,$7C,$9E,$97,$7B,$69,$8B,$64,$7F
dc.w	$96,$78,$64,$64,$69,$58,$96,$74,$7B,$46,$88,$40
dc.w	$9A,$73,$A3,$40,$AF,$45,$9B,$75,$C2,$58,$C7,$64
FRAME9:
dc.w	$B7,$87,$111,$98,$106,$B2,$B9,$8F,$DD,$DA,$C4,$E5
dc.w	$B0,$91,$8A,$E5,$70,$DA,$AA,$8F,$47,$B2,$3D,$98
dc.w	$A8,$88,$3D,$5E,$47,$44,$A8,$81,$6E,$1D,$8A,$11
dc.w	$B0,$7E,$C4,$11,$DD,$1B,$B3,$83,$106,$44,$111,$5E
FRAME10:
dc.w    $AE,$86,$C4,$89,$C1,$8F,$AF,$87,$B7,$98,$B1,$9B
dc.w	$AD,$87,$A5,$9B,$9F,$98,$AC,$87,$95,$8F,$93,$89
dc.w	$AC,$86,$93,$7C,$95,$76,$AC,$84,$9E,$6D,$A5,$6A
dc.w	$AD,$84,$B1,$6A,$B7,$6C,$AE,$85,$C1,$76,$C4,$7C
FRAME11:
dc.w    $F4,$7F,$EB,$8E,$E0,$A3,$E1,$C2,$BF,$C1,$AB,$CB
dc.w    $9B,$D2,$87,$CB,$72,$C1,$52,$C9,$52,$A3,$4A,$8E
dc.w	$49,$85,$4A,$68,$52,$55,$56,$3D,$6F,$37,$87,$2E
dc.w	$9C,$27,$AB,$2E,$BF,$34,$E3,$3D,$E0,$55,$EB,$68
FRAME12:
dc.w	$118,$EE,$E6,$F0,$D4,$BB,$91,$7E,$C4,$3C,$B9,$2E
dc.w	$7B,$2D,$8F,$FE,$6C,$E8,$6B,$A9,$66,$74,$5F,$43
dc.w	$56,$1F,$3A,$60,$39,$45,$48,12,$79,9,$A2,9,$D6
dc.w	$11,$EB,$25,$EB,$38,$E9,$63,$A7,$7F,$EB,$AB
FRAME13:
dc.w	$BA,$A5,$80,$9A,$81,$77,$C3,$7A,$CB,$38,$C0,$2A
dc.w	$82,$29,$70,$B5,$69,$F9,$52,$F7,$35,$F6,$37,$C6
dc.w	$36,$82,$41,$5C,$40,$41,$4F,8,$80,5,$A9,5,$DD,13
dc.w	$F2,$21,$F2,$34,$EE,$5C,$E8,$F6,$C6,$FB
FRAME14:
dc.w	$D2,$A6,$D5,$85,$D7,$26,$B1,$1D,$A1,$49,$96,$1E
dc.w	$7B,$24,$66,$B2,$79,$F8,$62,$F6,$52,$EB,$49,$C7
dc.w	$4A,$A5,$50,$77,$59,$40,$5F,7,$90,4,$B9,4,$ED,12
dc.w	$102,$20,$102,$33,$FE,$5B,$F8,$F5,$D6,$FA
FRAME15:
dc.w    $E0,$BA,$E3,$99,$E5,$3A,$CC,$33,$B6,$2F,$85,$31
dc.w	$62,$39,$46,$5B,$36,$5C,$32,$5D,$38,$1D,$70,$15
dc.w	$99,$12,$C0,$10,$E6,15,$107,$12,$11D,$18,$11C,$73
dc.w	$10C,$E1,$8E,$DE,$55,$CB,$5A,$87,$72,$61,$8D,$BF
FRAME16:
dc.w	$D9,$94,$5F,$90,$60,$78,$D4,$72,$D7,$53,$B5,$35
dc.w	$85,$35,$58,$4F,$57,$DE,$35,$D3,$43,$35,$54,$24
dc.w	$7C,$15,$B7,15,$CF,$1C,$ED,$3E,$F5,$61,$F3,$86
dc.w	$F3,$B7,$F5,$DD,$103,$EC,$D7,$EB,$D9,$CE,$D8,$BB
FRAME17:
dc.w	$CF,$F4,$C4,$F4,$D0,$77,$D4,$40,$A6,$2B,$93,$56
dc.w	$7C,$2E,$62,$48,$5E,$F8,$35,$CE,$4D,$2E,$56,$1D
dc.w	$66,15,$76,10,$8B,8,$A0,10,$B4,14,$DE,$1D,$F4,$47
dc.w    $F7,$63,$F5,$AC,$F3,$C9,$EB,$DB,$DE,$EC
FRAME18:
dc.w    $CA,$F7,$C6,$F0,$BC,$F2,$A9,$F0,$95,$F4,$8A,$F3
dc.w	$7D,$F4,$72,$F3,$68,$F7,$3F,$CD,$57,$2D,$60,$1C
dc.w	$70,14,$80,9,$95,7,$AA,9,$BE,13,$DD,$2C,$E6,$5B
dc.w    $E7,$7F,$DD,$BA,$DC,$D3,$DA,$E3,$D0,$EE
FRAME19:
dc.w	$C8,$EB,$BF,$DD,$B6,$C4,$A9,$F0,$91,$CC,$8A,$F3
dc.w	$7D,$F4,$5C,$86,0,$8B,0,$62,$5F,$6E,$5F,$19,$70
dc.w	14,$88,$21,$95,7,$A7,$25,$BE,13,$E8,$67,$13F,$5E
dc.w    $13F,$8C,$E6,$7E,$DC,$D3,$DA,$E3,$D0,$EE
FRAME20:
dc.w    $A1,$A6,$AE,$FF,$78,$FF,$8C,$A7,$8A,$98,$7F,$8F
dc.w	$6E,$8A,$5C,$86,0,$90,0,$64,$5F,$6E,$79,$7D,$88
dc.w	$6B,$82,0,$AB,0,$9C,$70,$B2,$7B,$E8,$67,$13F,$5F
dc.w	$13F,$8D,$E6,$7E,$AC,$97,$A8,$98,$A0,$99
FRAME21:
dc.w	$54,$D5,$AE,$FF,$78,$FF,$53,$EA,$42,$D4,$2B,$D1
dc.w	$3A,$BB,$3A,$B4,0,$90,0,$64,$45,$AC,$52,$B1,$56
dc.w	$AB,$82,0,$AB,0,$61,$A8,$56,$BB,$62,$BA,$13F,$5F
dc.w    $13F,$8D,$D4,$AE,$86,$B9,$69,$C0,$4E,$CE
FRAME22:
dc.w    $B8,$66,$AE,$FF,$78,$FF,$AB,$60,$AD,$4F,$B0,$47
dc.w    $9D,$52,$97,$57,0,$90,0,$64,$91,$4D,$A0,$43,$A7
dc.w	$2B,$82,0,$AB,0,$B3,$27,$BE,$36,$DB,$57,$13F,$5F
dc.w	$13F,$8D,$CF,$63,$C8,$5C,$C2,$54,$BC,$45
FRAME23:
dc.w	$A6,$96,$A6,$B5,$8A,$B5,$7D,$B5,$63,$B5,$3E,$B5
dc.w	$25,$B5,0,$B5,0,$90,0,$64,0,$5D,0,$3D,0,$2F,0,0
dc.w	$A6,0,$A6,$27,$A6,$36,$A6,$48,$A6,$52,$A6,$5C,$A6
dc.w	$62,$A6,$68,$A6,$78,$A6,$84
FRAME24:
dc.w	$AF,$A8,$BD,$BB,$E6,$7E,$EF,$86,$E0,$BB,$C2,$F5
dc.w	$A4,$F9,$59,$F8,$41,$A1,$24,$4F,$2E,$42,$3B,$49
dc.w	$57,$88,$5B,$10,$6F,$10,$79,$77,$8B,3,$96,3,$9F
dc.w	$11,$9A,$78,$BF,$18,$D0,$1E,$CE,$31,$AD,$8D
FRAME25:
dc.w	$B4,$AB,$BD,$BB,$BB,$93,$CF,$90,$D4,$C1,$C2,$F5
dc.w	$A4,$F9,$59,$F8,$41,$A1,$39,$81,$42,$78,$50,$77
dc.w	$57,$88,$5A,$68,$75,$62,$79,$77,$8B,3,$96,3,$9F
dc.w	$11,$9A,$78,$A2,$69,$B2,$69,$B5,$6D,$B4,$8D
FRAME26:
dc.w	$D6,$4A,$D1,$4B,$C8,$4C,$B9,$52,$A1,$5F,$9C,$63
dc.w	$90,$5C,$82,$56,$79,$51,$6B,$4D,$5D,$4C,$56,$44
dc.w	$5E,$43,$71,$44,$80,$4A,$8B,$51,$94,$5A,$9D,$53
dc.w	$A6,$59,$B4,$4D,$C0,$46,$CF,$42,$D7,$42,$E2,$44
FRAME27:
dc.w	$DB,$68,$CD,$6C,$C1,$6C,$B5,$68,$A3,$5D,$9B,$5D
dc.w	$95,$65,$8B,$6A,$81,$6B,$7B,$6B,$68,$66,$63,$5D
dc.w	$75,$62,$81,$63,$88,$62,$93,$5B,$96,$58,$9F,$51
dc.w	$A8,$57,$B2,$5D,$BC,$63,$C8,$64,$D6,$62,$E2,$60
FRAME28:
dc.w	$BB,$7B,$BA,$8C,$AE,$A3,$9F,$B8,$77,$E3,$4C,$FC
dc.w	$7E,$D1,$98,$B4,$AB,$9A,$B0,$8D,$B1,$7B,$AC,$64
dc.w	$9F,$5C,$93,$48,$92,$35,$92,$20,$9C,13,$AC,8,$BE
dc.w	13,$C8,$1D,$CE,$36,$CE,$48,$C5,$5C,$BC,$65
FRAME29:
dc.w	$BA,$57,$C6,$64,$D0,$7D,$D4,$A9,$D9,$C9,$108,$D7
dc.w	$D7,$D1,$D2,$CC,$C6,$82,$BF,$6B,$B2,$5F,$9D,$52
dc.w	$8D,$57,$76,$54,$65,$46,$55,$37,$4D,$21,$55,$11
dc.w	$65,6,$7B,9,$91,$17,$A0,$24,$A7,$37,$A9,$46
FRAME30:
dc.w    $C1,$66,$D3,$58,$10B,$A5,$106,$6A,$BD,$3A,$10E
dc.w	$17,$C7,$3D,$10B,$64,$114,$BA,$D3,$63,$C4,$6F,$97
dc.w	$85,$94,$92,$83,$A3,$74,$A8,$5F,$AC,$4B,$A9,$43
dc.w	$9B,$43,$8C,$51,$7E,$63,$72,$74,$6E,$8A,$6F,$93
dc.w	$76
FRAME31:
dc.w	$D4,$39,$EF,$61,$106,$5A,$11A,$56,$110,$62,$EB
dc.w	$6F,$E6,$BF,$DD,$B6,$DA,$70,$BF,$6E,$8E,$6D,$74
dc.w	$6C,$64,$BB,$55,$B2,$67,$6C,$52,$70,$3E,$6D,$60
dc.w	$59,$36,$50,$44,$42,$56,$36,$67,$32,$7D,$33,$A1
dc.w	$32
FRAME32:
dc.w	$D2,$98,$F0,$C2,$F7,$BA,$108,$B2,$109,$BB,$EC,$D0
dc.w	$E0,$FF,$D7,$FE,$D0,$CA,$BD,$D6,$8D,$D5,$75,$CD
dc.w    $6F,$FE,$64,$FF,$68,$CD,$53,$D1,$3C,$BE,$61,$BA
dc.w    $3D,$BA,$45,$A3,$57,$97,$68,$93,$7B,$9A,$9F,$A4

; frame addresses

FRM1:    dc.l    FRAME1        ; FRAMES+24*4*0
FRM2:    dc.l    FRAME2        ; FRAMES+24*4*1
FRM3:    dc.l    FRAME3        ; FRAMES+24*4*2
FRM4:    dc.l    FRAME4        ; FRAMES+24*4*3
FRM5:    dc.l    FRAME5        ; FRAMES+24*4*4
FRM6:    dc.l    FRAME6        ; FRAMES+24*4*5
FRM7:    dc.l    FRAME7        ; FRAMES+24*4*6
FRM8:    dc.l    FRAME8        ; FRAMES+24*4*7
FRM9:    dc.l    FRAME9        ; FRAMES+24*4*8
FRM10:    dc.l	FRAME10        ; FRAMES+24*4*9
FRM11:    dc.l    FRAME11        ; FRAMES+24*4*10
FRM12:    dc.l    FRAME12        ; FRAMES+24*4*11
FRM13:    dc.l    FRAME13		; FRAMES+24*4*12
FRM14:    dc.l    FRAME14        ; FRAMES+24*4*13
FRM15:    dc.l    FRAME15        ; FRAMES+24*4*14
FRM16:    dc.l    FRAME16		; FRAMES+24*4*15
FRM17:    dc.l    FRAME17        ; FRAMES+24*4*16
FRM18:    dc.l    FRAME18        ; FRAMES+24*4*17
FRM19:    dc.l	FRAME19        ; FRAMES+24*4*18
FRM20:    dc.l    FRAME20        ; FRAMES+24*4*19
FRM21:    dc.l    FRAME21        ; FRAMES+24*4*20
FRM22:    dc.l    FRAME22		; FRAMES+24*4*21
FRM23:    dc.l    FRAME23        ; FRAMES+24*4*22
FRM24:    dc.l    FRAME24        ; FRAMES+24*4*23
FRM25:    dc.l    FRAME25		; FRAMES+24*4*24
FRM26:    dc.l    FRAME26        ; FRAMES+24*4*25
FRM27:    dc.l    FRAME27        ; FRAMES+24*4*26
FRM28:    dc.l    FRAME28        ; FRAMES+24*4*27
FRM29:    dc.l    FRAME29        ; FRAMES+24*4*28
FRM30:    dc.l    FRAME30        ; FRAMES+24*4*29
FRM31:    dc.l	FRAME31        ; FRAMES+24*4*30
FRM32:    dc.l    FRAME32        ; FRAMES+24*4*31

;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0		; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200    ; Bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w    $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$44b    ; colour0
dc.w    $0182,$f88    ; colour1
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

SECTION	bitplane,BSS_C
; buffer 1

BITPLANE1:
ds.b	40*256

; buffer 2

BITPLANE1b:
ds.b	40*256

end

;****************************************************************************

In this example, we present a routine that performs an animation using
a morph effect.
 This is one of the main techniques used by the legendary ‘State of the art’ of Spaceballs, perhaps the most famous demo ever
made.
Let's see how this technique is achieved. Each frame of the animation is
created using a single filled polygon. To draw the polygon,
 we need to trace its edges and then fill it with the blitter. The first of
these tasks is performed by the ‘DO_IT’ routine and the second by the
‘FILL’ routine. To create the animation, simply change the shape of the polygon
at each frame, which is done by changing the X and Y coordinates of all its
vertices. If we stored the coordinates of all the points for all the frames,
we would use up a HUGE amount of memory. So let's use a smarter method
: we only store a few frames, and calculate the
by morphing between two of the frames we have stored.
The animation is therefore divided into several phases, during which
the morph between a source frame and a destination frame is performed in a certain
number of frames. When the destination frame is reached, we move on to
a new phase, changing the source frame, destination frame and number of frames
used by the morph. The animation phases
are stored in sequence
starting from the ‘STORY’ address, and the transition from one phase to another is
managed by the ‘DO_ANIM’ routine.

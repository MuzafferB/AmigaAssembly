
; Lesson 10t2.s    Optimised line tracing routine

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
MOVE.W	#DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

bsr.w    InitLine    ; initialise line mode

move.w    #$ffff,d0    ; continuous line
bsr.w    SetPattern    ; defines pattern

move.w    #100,d0        ; x1
move.w    #100,d1        ; y1
move.w    #220,d2        ; x2
move.w    #120,d3        ; y2
lea    bitplane,a0
bsr.s    Drawline

move.w    #$f0f0,d0    ; dashed line
bsr.w    SetPattern    ; defines pattern

move.w    #300,d0        ; x1
move.w    #200,d1        ; y1
move.w    #240,d2        ; x2
move.w	#90,d3        ; y2
lea    bitplane,a0
bsr.s    Drawline

move.w    #$4444,d0    ; dashed line
bsr.w    SetPattern    ; defines pattern

move.w    #210,d0        ; x1
move.w    #24,d1		; y1
move.w    #68,d2        ; x2
move.w    #50,d3        ; y2
lea    bitplane,a0
bsr.s    Drawline

mouse:
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts


;******************************************************************************
; This routine draws the line. It takes as parameters the
; endpoints of the line P1 and P2, and the address of the bitplane on which to draw it.
; D0 - X1 (X coordinate of P1)
; D1 - Y1 (Y coordinate of P1)
; D2 - X2 (coordinate X of P2)
; D3 - Y2 (coordinate Y of P2)
; A0 - bitplane address
;******************************************************************************

;     .---. .-----------
;     / \ __ / ------
;     / / \(oo)/ -----
;     ////// “ \/ ` ---
;     //// / // : : ---
;     // / / /` ”--
;    // //..\\
;    -----------UU----UU-----
;     “//||\\`
;     ”'``

; constants

DL_Fill        =    0        ; 0=NOFILL / 1=FILL

IFEQ    DL_Fill
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
neg.w    d3	; D3=DY
.y2gy1:
mulu.w    #40,d1        ; Y offset
add.l    d1,a0
moveq    #0,d1        ; D1 index in the octave table
sub.w    d0,d2        ; D2=X2-X1
bge.s    .xdpos        ; skip if positive..
addq.w    #2,d1        ; ..otherwise move the index
neg.w    d2        ; and make the difference positive
.xdpos:
moveq    #$f,d4        ; mask for the 4 low bits
and.w    d0,d4        ; select them in D4

IFNE    DL_Fill		; these instructions are assembled
; only if DL_Fill=1
move.b    d4,d5        ; calculate the number of bits to invert
not.b    d5        ; (BCHG numbers the bits in reverse order    
ENDC

lsr.w    #3,d0        ; X offset:
; Align to byte (used for BCHG)
add.w    d0,a0        ; adds to address
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
addq.w    #1,d1        ; otherwise set bit 0 of the index
exg    d2,d3        ; and swap the Diff
.dygdx:
add.w    d2,d2        ; D2 = 2*DiffX
move.w    d2,d0        ; copy to D0
sub.w    d3,d0        ; D0 = 2*DiffX-DiffY
addx.w    d1,d1        ; multiply the index by 2 and
; at the same time add the flag
; X which is 1 if 2*DiffX-DiffY<0
; (set by sub.w)
move.b    Oktants(PC,d1.w),d4    ; reads the octant
swap    d2            ; BLTBMOD value in high word
move.w    d0,d2            ; low word D2=2*DiffX-DiffY
sub.w    d3,d2            ; low word D2=2*DiffX-2*DiffY
moveq    #6,d1            ; shift and test value for
; the blitter wait
 

lsl.w    d1,d3        ; calculates the value of BLTSIZE
add.w    #$42,d3

lea    $52(a5),a1    ; A1 = BLTAPTL address
; writes some registers
; consecutively with 
; MOVE #XX,(Ax)+

btst    d1,2(a5)	; wait for the blitter
.wb:
btst    d1,2(a5)
bne.s    .wb

IFNE    DL_Fill        ; this instruction is assembled
; only if DL_Fill=1
bchg    d5,(a0)		; Inverts the first bit of the line
ENDC

move.l    d4,$40(a5)    ; BLTCON0/1
move.l    d2,$62(a5)    ; BLTBMOD and BLTAMOD
move.l    a0,$48(a5)    ; BLTCPT
move.w    d0,(a1)+	; BLTAPTL
move.l    a0,(a1)+    ; BLTDPT
move.w    d3,(a1)        ; BLTSIZE
.end:
rts

;нннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннннн
; if we want to execute lines for the fill, the octant code sets the bit
; SING to 1 through the constant SML

IFNE    DL_Fill
SML        =     2
ELSE
SML        =    0
ENDC

; octant table

Oktants:
dc.b	SML+1,SML+1+$40
dc.b	SML+17,SML+17+$40
dc.b	SML+9,SML+9+$40
dc.b	SML+21,SML+21+$40

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
move.w	#40,$66(a5)		; BLTDMOD = 40
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

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200    ; Bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w    $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

Section	IlMioPlane,bss_C

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

;****************************************************************************

In this example, we present an optimised routine for drawing
lines. The main feature of this routine is that the octet codes
are contained in a table. Depending on the positions of the points, the routine calculates the index of the correct octet in the table.
In addition to this, the routine employs many 68000 optimisations.
This routine contains assembler directives for conditional assembly. Depending on the value of the DL_Fill constant, some parts of the routine are assembled or not. In this way, it is possible to combine several parts of the routine into a single source.
This routine contains assembler directives for conditional assembly.
 Depending on the value of the DL_Fill constant, some parts of the routine are assembled
or not. In this way, it is possible to combine
the code for both the normal version and the line-fill version in a single source.
By setting DL_Fill=0, the normal routine is assembled
, while setting DL_Fill=1 assembles the line-fill version.
To see this, look at the code
produced in the two cases (using the ASMONE D command).

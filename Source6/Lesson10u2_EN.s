
; Lesson10u2.s Effect with lines
;        Right click to see other effects, left click to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup1.s’    ; Save Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

bsr.w    InitLine    ; initialise line mode

move.w    #$ffff,d0    ; continuous line
bsr.w	SetPattern    ; defines pattern

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S	Waity1

bsr.w    SwapBuffer    ; this routine swaps the 2 buffers

bsr.w    ClearScreen    ; clears the screen

btst    #2,$dff016    ; right mouse button pressed?
bne.s    Don'tChange    ; if not, skip...
bsr.s    ChangeParameters    ; ...otherwise change the line parameters
Don'tChange:

bsr.w    MovePoints    ; modify the coordinates of the points of the first
; line


move.w    IndexX1(pc),d4    ; read the indexes of the first line
move.w    IndexX2(pc),d5
move.w    IndexY1(pc),d6
move.w    IndexY2(pc),d7

move.w    NumLines(pc),d0

LineLoop:

; draw the line

movem.l    d0-d7,-(a7)    ; save the registers
move.w    CoordX1(pc),d0	; reads the coordinates of the points
move.w    CoordY1(pc),d1
move.w    CoordX2(pc),d2
move.w    CoordY2(pc),d3
move.l    draw_buffer(pc),a0
bsr.w    Drawline
movem.l    (a7)+,d0-d7	; reread the registers

bsr.w    NextLine

dbra    d0,LineLoop    ; repeat for each line

btst    #6,$bfe001    ; mouse pressed?
bne.w    mouse

rts


;***************************************************************************
; This routine changes the parameter values.
; The values changed are: ‘NumLines’, the 4 ‘Index’ values, the 4 “Add” values, and the 4 ‘NextAdd’ values
; The new values are contained in a special table.
; Since all the values to be changed are consecutive in memory, you can
; use a single copy loop
;***************************************************************************

;     _ _
;     . __/ V \__ ..
;     . /___ : ___\ ::
;     .: _/____\_/____\_ ::
;	:::/¯ ¬(@:)_(@:)) ¯\:::
;    _::\_ __/¯/_\¯\__ _/:::
;     ::·\:| . : . |:/ ::::
;     .:.¯:_|_|_|_:¯.::::·
;     ·::( V_V_V ):::·
;     \| |/

ChangeParameters:
move.l    PointerParam(pc),a0    ; pointer to new values
lea    NumLines(pc),a1        ; pointer to variables

moveq    #13-1,d0        ; number of values to change
ChangeLoop:
move.w    (a0)+,(a1)+		; copy loop
dbra    d0,ChangeLoop

cmp.l    #EndParam,a0        ; are we at the end of the table?
blo.s    NoRestart        ; if not, skip...
lea    TabParam(pc),a0        ; ...otherwise, start again from the beginning

NoRestart:
move.l    a0,PointerParam        ; store the pointer

; wait for the mouse button to be released

Waitmouse:
btst    #2,$dff016        ; right mouse button pressed?
beq.s    Waitmouse        ; if yes, wait

rts

; pointer to the parameter table

PointerParam:    dc.l    TabParam

; Parameter table
; you can try specifying parameters yourself. The parameters (except the first one)
; MUST be EVEN numbers

TabParam:
dc.w	$3a,0,$40,0,$40,2,2,2,2,8,8,$10,$10
dc.w	$32,0,$80,0,$80,2,2,4,4,$7e,$80,$7e,$80

dc.w	$3A,0,0,0,0,-2,2,4,4,$7e,$7e,$7e,$7e

dc.w	$38,0,$68,0,$68,2,2,4,4,8,8,10,10
dc.w	$28,$64,0,0,0,6,4,4,2,6,6,4,8
dc.w	$3A,$40,$40,$40,$40,2,2,2,8,2,2,4,4
dc.w	$39,2,0,$68,0,-2,2,4,4,8,8,10,10

dc.w	$27,$64,0,0,0,8,4,4,2,4,2,2,4
dc.w	$3A,0,$40,0,$40,2,2,4,4,4,4,$104,$104
FineParam:

;***************************************************************************
; This routine reads the coordinates of the vertices of the lines
; following the first one from tables and stores them in the appropriate variables.
; Reading from tables is performed by indirect addressing
; with an index. To move within the tables, we modify the indexes
; (which are words) instead of the pointers (longwords). This allows us to
; avoid going outside the table with a simple AND that keeps
; the index within the range 0 - 512 (in fact, the tables are composed
; of 256 word values (512 bytes).
; The indices of the previous coordinates are stored
; in registers D4, D5, D6, D7
; The values to be added to the index to move from one line to another are
; stored in appropriate variables.
;***************************************************************************

NextLine:
lea	TabX(pc),a0

; coordinata X1

add.w	NextAddX1(pc),d4	; modifies the index to point
; to the new coordinate
and.w    #$1FF,d4        ; keeps the index within the
; table
move.w    0(a0,d4.w),CoordX1    ; copies the coordinate from the table
; to the variable

; coordinate X2

add.w    NextAddX2(pc),d5    ; change the index to point
; to the new coordinate
and.w    #$1FF,d5        ; keep the index within the
; table
move.w    0(a0,d5.w),CoordX2    ; copy the coordinate from the table
; to the variable


lea    TabY(pc),a0

; Y1 coordinate

add.w    NextAddY1(pc),d6    ; modifies the index to point
; the new coordinate
and.w    #$1FF,d6        ; keeps the index within the
; table
move.w    0(a0,d6.w),CoordY1    ; copies the coordinate from the table
; into the variable
; coordinate Y2

add.w    NextAddY2(pc),d7	; modifies the index to point
; to the new coordinate
and.w    #$1FF,d7        ; keeps the index within the
; table
move.w    0(a0,d7.w),CoordY2    ; copies the coordinate from the table
; to the variable
rts

;***************************************************************************
; This routine reads the coordinates of the various points from tables and
; stores them in the appropriate variables.
; Reading from tables is done by indirect addressing
; with an index. To move within the tables, we modify the indexes
; (which are words) instead of the pointers (longwords). This allows us to
; avoid going outside the table with a simple AND that keeps
; the index within the range 0 - 512 (in fact, the tables are composed
; of 256 word values (512 bytes).
;***************************************************************************

MovePoints:
lea    TabX(pc),a0

; X1 coordinate

move.w    indexX1(pc),d0        ; index of the previous coordinate
add.w    addX1(pc),d0        ; modifies the index to point
; to the new coordinate
and.w	#$1FF,d0        ; keeps the index within the
; table
move.w    d0,indiceX1        ; stores the index
move.w    0(a0,d0.w),d1        ; reads the coordinate from the table
move.w    d1,CoordX1        ; copies the coordinate to the variable

; X2 coordinate

move.w    indexX2(pc),d0        ; index of the previous coordinate
add.w    addX2(pc),d0        ; modifies the index to point
; to the new coordinate
and.w    #$1FF,d0		; keeps the index within the
; table
move.w    d0,indexX2        ; stores the index
move.w    0(a0,d0.w),d1        ; reads the coordinate from the table
move.w    d1,CoordX2        ; copies the coordinate to the variable

lea    TabY(pc),a0

; Y1 coordinate

move.w    indexY1(pc),d0        ; index of the previous coordinate
add.w    addY1(pc),d0        ; modifies the index to point
; to the new coordinate
and.w    #$1FF,d0        ; keeps the index within the
; table
move.w    d0,indexY1		; stores the index
move.w    0(a0,d0.w),d1        ; reads the coordinate from the table
move.w    d1,CoordY1        ; copies the coordinate to the variable

; coordinate Y2

move.w    indexY2(pc),d0        ; index of the previous coordinate
add.w    addY2(pc),d0        ; modifies the index to point
; to the new coordinate
and.w    #$1FF,d0        ; keeps the index within the
; table
move.w    d0,indexY2		; stores the index
move.w    0(a0,d0.w),d1        ; reads the coordinate from the table
move.w    d1,CoordY2        ; copies the coordinate to the variable
rts

; this table contains the X coordinates

TabX:
DC.W    $00A2,$00A6,$00A9,$00AD,$00B1,$00B4,$00B8,$00BB,$00BF,$00C3
DC.W	$00C6,$00CA,$00CD,$00D1,$00D4,$00D8,$00DB,$00DE,$00E2,$00E5
DC.W	$00E8,$00EC,$00EF,$00F2,$00F5,$00F8,$00FB,$00FE,$0101,$0103
DC.W	$0106,$0109,$010B,$010E,$0110,$0113,$0115,$0117,$011A,$011C
DC.W	$011E,$0120,$0122,$0123,$0125,$0127,$0128,$012A,$012B,$012D
DC.W	$012E,$012F,$0130,$0131,$0132,$0133,$0133,$0134,$0135,$0135
DC.W	$0135,$0136,$0136,$0136,$0136,$0136,$0136,$0135,$0135,$0135
DC.W	$0134,$0133,$0133,$0132,$0131,$0130,$012F,$012E,$012D,$012B
DC.W	$012A,$0128,$0127,$0125,$0123,$0122,$0120,$011E,$011C,$011A
DC.W	$0117,$0115,$0113,$0110,$010E,$010B,$0109,$0106,$0103,$0101
DC.W	$00FE,$00FB,$00F8,$00F5,$00F2,$00EF,$00EC,$00E8,$00E5,$00E2
DC.W	$00DE,$00DB,$00D8,$00D4,$00D1,$00CD,$00CA,$00C6,$00C3,$00BF
DC.W	$00BB,$00B8,$00B4,$00B1,$00AD,$00A9,$00A6,$00A2,$009E,$009A
DC.W	$0097,$0093,$008F,$008C,$0088,$0085,$0081,$007D,$007A,$0076
DC.W	$0073,$006F,$006C,$0068,$0065,$0062,$005E,$005B,$0058,$0054
DC.W	$0051,$004E,$004B,$0048,$0045,$0042,$003F,$003D,$003A,$0037
DC.W	$0035,$0032,$0030,$002D,$002B,$0029,$0026,$0024,$0022,$0020
DC.W	$001E,$001D,$001B,$0019,$0018,$0016,$0015,$0013,$0012,$0011
DC.W	$0010,$000F,$000E,$000D,$000D,$000C,$000B,$000B,$000B,$000A
DC.W	$000A,$000A,$000A,$000A,$000A,$000B,$000B,$000B,$000C,$000D
DC.W	$000D,$000E,$000F,$0010,$0011,$0012,$0013,$0015,$0016,$0018
DC.W	$0019,$001B,$001D,$001E,$0020,$0022,$0024,$0026,$0029,$002B
DC.W	$002D,$0030,$0032,$0035,$0037,$003A,$003D,$003F,$0042,$0045
DC.W	$0048,$004B,$004E,$0051,$0054,$0058,$005B,$005E,$0062,$0065
DC.W	$0068,$006C,$006F,$0073,$0076,$007A,$007D,$0081,$0085,$0088
DC.W	$008C,$008F,$0093,$0097,$009A,$009E

; questa tabella contiene le coordinate Y

TabY:
DC.W	$0080,$0083,$0086,$0088,$008B,$008E,$0090,$0093,$0096,$0098
DC.W	$009B,$009E,$00A0,$00A3,$00A5,$00A8,$00AA,$00AD,$00AF,$00B2
DC.W	$00B4,$00B6,$00B9,$00BB,$00BD,$00BF,$00C2,$00C4,$00C6,$00C8
DC.W	$00CA,$00CC,$00CE,$00D0,$00D1,$00D3,$00D5,$00D7,$00D8,$00DA
DC.W    $00DB,$00DD,$00DE,$00DF,$00E1,$00E2,$00E3,$00E4,$00E5,$00E6
DC.W	$00E7,$00E8,$00E9,$00E9,$00EA,$00EB,$00EB,$00EC,$00EC,$00EC
DC.W    $00ED,$00ED,$00ED,$00ED,$00ED,$00ED,$00ED,$00ED,$00EC,$00EC
DC.W	$00EC,$00EB,$00EB,$00EA,$00E9,$00E9,$00E8,$00E7,$00E6,$00E5
DC.W	$00E4,$00E3,$00E2,$00E1,$00DF,$00DE,$00DD,$00DB,$00DA,$00D8
DC.W	$00D7,$00D5,$00D3,$00D1,$00D0,$00CE,$00CC,$00CA,$00C8,$00C6
DC.W	$00C4,$00C2,$00BF,$00BD,$00BB,$00B9,$00B6,$00B4,$00B2,$00AF
DC.W	$00AD,$00AA,$00A8,$00A5,$00A3,$00A0,$009E,$009B,$0098,$0096
DC.W	$0093,$0090,$008E,$008B,$0088,$0086,$0083,$0080,$007E,$007B
DC.W	$0078,$0076,$0073,$0070,$006E,$006B,$0068,$0066,$0063,$0060
DC.W	$005E,$005B,$0059,$0056,$0054,$0051,$004F,$004C,$004A,$0048
DC.W	$0045,$0043,$0041,$003F,$003C,$003A,$0038,$0036,$0034,$0032
DC.W	$0030,$002E,$002D,$002B,$0029,$0027,$0026,$0024,$0023,$0021
DC.W	$0020,$001F,$001D,$001C,$001B,$001A,$0019,$0018,$0017,$0016
DC.W	$0015,$0015,$0014,$0013,$0013,$0012,$0012,$0012,$0011,$0011
DC.W	$0011,$0011,$0011,$0011,$0011,$0011,$0012,$0012,$0012,$0013
DC.W	$0013,$0014,$0015,$0015,$0016,$0017,$0018,$0019,$001A,$001B
DC.W	$001C,$001D,$001F,$0020,$0021,$0023,$0024,$0026,$0027,$0029
DC.W	$002B,$002D,$002E,$0030,$0032,$0034,$0036,$0038,$003A,$003C
DC.W	$003F,$0041,$0043,$0045,$0048,$004A,$004C,$004F,$0051,$0054
DC.W	$0056,$0059,$005B,$005E,$0060,$0063,$0066,$0068,$006B,$006E
DC.W	$0070,$0073,$0076,$0078,$007B,$007E


; The coordinates of the vertices of the line are stored here

CoordX1:    dc.w    0
CoordY1:    dc.w    0
CoordX2:    dc.w    0
CoordY2:    dc.w    0

; The number of lines drawn is stored here

NumLines:    dc.w    10

; The indices within the table are stored here for each coordinate

IndexX1:    dc.w    20
IndexY1:    dc.w    50
IndexX2:    dc.w    30
IndexY2:    dc.w    40

; Here are stored for each coordinate the values to be added to each frame
; to the indexes of the table for the vertices of the first line

addX1:    dc.w    4
addY1:    dc.w    -6
addX2:    dc.w    -2
addY2:    dc.w    2

; Here, the values to be added to the indices
; of the table for the vertices of the subsequent lines are stored for each coordinate

NextaddX1:    dc.w    10
NextaddY1:    dc.w	14
NextaddX2:	dc.w	6
NextaddY2:	dc.w	-4

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

DL_Fill        =    0        ; 0=NOFILL / 1=FILL

IFEQ    DL_Fill
DL_MInterns    =	$CA
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
mulu.w    #40,d1		; offset Y
add.l    d1,a0
moveq    #0,d1        ; D1 index in the octal table
sub.w    d0,d2        ; D2=X2-X1
bge.s    .xdpos        ; skip if positive..
addq.w    #2,d1        ; ..otherwise move the index
neg.w    d2        ; and make the difference positive
.xdpos:
moveq    #$f,d4        ; mask for the 4 low bits
and.w    d0,d4		; select them in D4

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
; the blitter does not take into account
; the least significant bit of BLTxPT

ror.w    #4,d4        ; D4 = shift value A
or.w    #$B00+DL_MInterns,d4    ; adds the appropriate
; Minterm (OR or EOR)
swap    d4		; value of BLTCON0 in the high word

cmp.w    d2,d3        ; compare DiffX and DiffY
bge.s    .dygdx        ; jump if >=0..
addq.w    #1,d1        ; otherwise set bit 0 of the index
exg    d2,d3        ; and swap the Diff
.dygdx:
add.w    d2,d2		; D2 = 2*DiffX
move.w    d2,d0        ; copy to D0
sub.w    d3,d0        ; D0 = 2*DiffX-DiffY
addx.w    d1,d1        ; multiply the index by 2 and
; at the same time add the flag
; X which is 1 if 2*DiffX-DiffY<0
; (set by sub.w)
move.b    Oktants(PC,d1.w),d4	; reads the octant
swap    d2            ; BLTBMOD value in upper word
move.w    d0,d2            ; lower word D2=2*DiffX-DiffY
sub.w    d3,d2            ; lower word D2=2*DiffX-2*DiffY
moveq    #6,d1            ; shift and test value for
; the blitter wait 

lsl.w    d1,d3        ; calculates the BLTSIZE value
add.w    #$42,d3

lea    $52(a5),a1	; A1 = BLTAPTL address
; writes some registers
; consecutively with 
; MOVE #XX,(Ax)+

btst    d1,2(a5)    ; waits for the blitter
.wb:
btst    d1,2(a5)
bne.s    .wb

IFNE    DL_Fill        ; this instruction is assembled
; only if DL_Fill=1
bchg    d5,(a0)        ; Inverts the first bit of the line
ENDC

move.l    d4,$40(a5)    ; BLTCON0/1
move.l    d2,$62(a5)    ; BLTBMOD and BLTAMOD
move.l    a0,$48(a5)    ; BLTCPT
move.w    d0,(a1)+    ; BLTAPTL
move.l    a0,(a1)+    ; BLTDPT
move.w    d3,(a1)        ; BLTSIZE
.end:
rts

;
; if we want to execute lines for the fill, the octal code sets the
; SING bit to 1 through the SML constant

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
btst	#6,2(a5) ; dmaconr - wait for the blitter to finish
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
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    Wblit_Set

move.w    d0,$72(a5)    ; BLTBDAT = line pattern
rts


;****************************************************************************
; This routine clears the screen using the blitter.
;****************************************************************************

ClearScreen:
move.l    draw_buffer(pc),a0    ; address of area to be cleared

btst    #6,2(a5)
WBlit3:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit3

move.l    #$01000000,$40(a5)    ; BLTCON0 and BLTCON1: Clear
move.w	#$0000,$66(a5)        ; BLTDMOD=0
move.l    a0,$54(a5)        ; BLTDPT
move.w    #(64*256)+20,$58(a5)    ; BLTSIZE (start the blitter!)
; clear the entire screen
rts

;****************************************************************************
; This routine swaps the two buffers by swapping the addresses in
; the VIEW_BUFFER and DRAW_BUFFER variables.
; It also updates the copperlist instructions that load the
; BPLxPT registers so that they point to the new buffer to be displayed.
;****************************************************************************

SwapBuffer
move.l    draw_buffer(pc),d0        ; swaps the contents
move.l    view_buffer(pc),draw_buffer    ; of the variables
move.l    d0,view_buffer            ; in d0 there is the address
; of the new buffer
; to be displayed

; update the copperlist pointing to the bitplanes of the new buffer to be displayed

LEA    BPLPOINTERS,A1	; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
rts


; pointers to the 2 buffers

view_buffer:    dc.l    BITPLANE    ; buffer displayed
draw_buffer:    dc.l    BITPLANEb	; buffer di disegno

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

Section    IlMioPlane,bss_C

; buffer 1

BITPLANE:
ds.b    40*256        ; bitplane reset lowres

; buffer 2

BITPLANEb:
ds.b    40*256        ; bitplane reset lowres

end

;****************************************************************************

In this example, we add more lines to the lesson10h1.s program
to create more complex effects. The lines following the first one are
drawn using the values read from the table as coordinates.
To calculate the new coordinates, the values are added to the indexes of the values
at each line. These values are contained in the ‘NextAdd’ variables.
Furthermore, by pressing the right button, all the values
of the variables can be changed. In this way, new effects can be obtained simply
by changing the parameters.

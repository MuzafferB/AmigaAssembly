
; Lesson 11g6.s - Using the copper feature to request 8 horizontal pixels
;         to perform a ‘MOVE’.

SECTION    copfantasia,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %100000101000000    ; only copper DMA

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

NUMLINES    =    80


START:
MOVE.L    #$5001FFFE,D2    ; $50 = first vertical line
BSR.W    MAKE_IT        ; make it copper!

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$0e000,d2    ; line to wait for = $e0
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $e0
BNE.S    Waity1

BTST    #2,$16(a5)    ; right button pressed?
BEQ.s    Block

BSR.w    FantaCop    ; scroll colours...

Block:
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

rts

*****************************************************************************
*        Routine that creates the copperlist for the effect         *
*****************************************************************************

;     ____________
;     \ /
;     \________/
;     | ._|_
;     ____|o \
;     ___(°__|___)___
;     \_/ (___)/\\_/
;     / \_____/ \\
;    _/ \______\\_
;    \_______________/g®m


MAKE_IT:
LEA    COPBUF,A0        ; Copper buffer address
MOVEQ    #NUMLINES-1,D6        ; Number of lines...
MAIN0:
LEA    COLORS(PC),A1        ; Colour table...
MOVEQ    #32-1,D7        ; Number
MOVE.L	D2,(A0)+        ; Set WAIT
MOVE.L    #$01800505,(A0)+    ; colour0
COP0:
MOVE.W    #$0180,(A0)+    ; COLOR0 register
MOVE.W    (A1)+,(A0)+    ; colour0 value taken from the table
DBRA    d7,COP0         ; Draw a line with 32 colour0...
MOVE.L    #$01800505,(A0)+ ; Set a COLOUR0
ADDI.L    #$01020000,D2    ; Wait 1 line below and 2 further ahead
; to create the ‘diagonal’.
DBRA    d6,MAIN0    ; Draw all the lines
RTS

; Colour table

COLORS:
DC.W    $100,$101,$202,$303,$404,$505,$606,$707
DC.W    $808,$909,$A0A,$B0B,$C0C,$D0D,$E0E,$F0F
DC.W    $F0F,$E0E,$D0D,$C0C,$B0B,$A0A,$909,$808
DC.W	$707,$606,$505,$404,$303,$202,$101,$100

*****************************************************************************
*        Routine that cycles the colours of the effect             *
*****************************************************************************

;     __
;     (((________.
;     \_____.---|
;     ____ |---|
;     ___(°__||---|__
;     / ___ )__/_ /
;    /______)\ _/_/
;     \___\ /\
;     \__/g®m


FantaCop:
LEA    COPBUF+8,A0    ; Address of first colour to cycle
MOVEQ    #NUMLINES-1,D6    ; number of lines to draw
MOVE1:
MOVE.W    2(A0),D0    ; Save the first colour in d0
MOVE0:
MOVE.W    2(A0),-2(A0)        ; copy the 32 colours of the line
MOVE.W	6(A0),2(A0)        ; ‘back’ one place.
MOVE.W    6+4(A0),2+4(A0)
MOVE.W    6+4*2(A0),2+4*2(A0)
MOVE.W    6+4*3(A0),2+4*3(A0)
MOVE.W	6+4*4(A0),2+4*4(A0)
MOVE.W	6+4*5(A0),2+4*5(A0)
MOVE.W	6+4*6(A0),2+4*6(A0)
MOVE.W	6+4*7(A0),2+4*7(A0)
MOVE.W	6+4*8(A0),2+4*8(A0)
MOVE.W	6+4*9(A0),2+4*9(A0)
MOVE.W	6+4*10(A0),2+4*10(A0)
MOVE.W	6+4*11(A0),2+4*11(A0)
MOVE.W	6+4*12(A0),2+4*12(A0)
MOVE.W	6+4*13(A0),2+4*13(A0)
MOVE.W	6+4*14(A0),2+4*14(A0)
MOVE.W	6+4*15(A0),2+4*15(A0)
MOVE.W	6+4*16(A0),2+4*16(A0)
MOVE.W	6+4*17(A0),2+4*17(A0)
MOVE.W	6+4*18(A0),2+4*18(A0)
MOVE.W	6+4*19(A0),2+4*19(A0)
MOVE.W	6+4*20(A0),2+4*20(A0)
MOVE.W	6+4*21(A0),2+4*21(A0)
MOVE.W	6+4*22(A0),2+4*22(A0)
MOVE.W	6+4*23(A0),2+4*23(A0)
MOVE.W	6+4*24(A0),2+4*24(A0)
MOVE.W	6+4*25(A0),2+4*25(A0)
MOVE.W	6+4*26(A0),2+4*26(A0)
MOVE.W	6+4*27(A0),2+4*27(A0)
MOVE.W	6+4*28(A0),2+4*28(A0)
MOVE.W	6+4*29(A0),2+4*29(A0)
MOVE.W    6+4*30(A0),2+4*30(A0)
MOVE.W    6+4*31(A0),2+4*31(A0)
lea    4*32(a0),A0    ; point to the next line
MOVE.W    D0,-(A0)    ; put the first saved colour as the last
; so as not to interrupt the cycle.
lea    14(a0),A0    ; skip the ‘external’ wait+move
DBRA    d6,MOVE1    ; execute all lines
RTS

*****************************************************************************

SECTION    COPPY,DATA_C

COPLIST:
dc.w    $100,$200    ; bplcon0 - no bitplanes.
COPBUF:
ds.b    NUMLINES*12+numlines*$20*4 ; space for the effect.
dc.w    $ffff,$fffe        ; end copperlist

end



; Lesson 11h.s    Using COP2LC ($dff084) to make a dynamic copperlist,
;        i.e. a copperlist in which each frame alternates between two copperlists
;        designed to ‘increase’ the credibility of a shade.
;        Right-click to see the difference!

SECTION    DynaCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup2.s’ ; Save Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
;	 POINT OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

;    Point all sprites to the null sprite

MOVE.L	#SpriteNullo,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
MOVEQ    #8-1,d1            ; all 8 sprites
NulLoop:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap d0
addq.w #8,a1
dbra d1,NulLoop

bsr.w InitCops ; Create the 2 copperlists to be ‘swapped’

lea $dff000,a6
MOVE.W	#DMASET,$96(a6)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a6)    ; Point to our COP
move.w    d0,$88(a6)        ; Start the COP
move.w    #0,$1fc(a6)		; Disable AGA
move.w    #$c00,$106(a6)        ; Disable AGA
move.w    #$11,$10c(a6)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L	#$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

btst    #2,$16(a6)    ; right mouse button pressed?
beq.s    NonSwappare    ; If yes, do not swap (what a mess!)

movem.l	CoppPointer1(PC),d0-d1    ; Put the addresses
; of the 2 copperlists in d0 and a1
move.l    d0,CoppPointer2        ; Swap their order...
move.l    d1,CoppPointer1        ; ...
move.w    d1,Cop2lcl        ; And point the other copperlist2 as
swap    d1            ; the next one to jump to with
move.w    d1,Cop2lch        ; COPJMP2 ($dff08a)
nonSwappare:

bsr.w    PrintCarattere    ; Print one character at a time

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts            ; exit


CoppPointer1:
dc.l    ColInt1
CoppPointer2:
dc.l    ColInt2

*****************************************************************************
* Routine that creates the 2 copperslists that must be displayed     *
* alternatively pointing them in COP2LC and starting them with COPJMP2 *
*****************************************************************************

;     _________________
;     / \
;     \ ___ ___ /
;    __\ (__) (__) /__
;    \__\___ ` ' ___/__/
;     \ \...../ /
;     \_______/g®m


COLSTART    EQU    $660    ; Starting colour = yellow
COLTENDENZA    EQU    $001    ; Trend (value added each wait)

InitCops:
move.l    #$4407fffe,d0    ; Wait - starts from horizontal line $44
move.l    #$1800000,d1    ; Colour0
move.w    #COLSTART,d2    ; Starting colour
move.w    #COLTENDENZA,d3    ; Destination trend ($001/$010/$100)
moveq    #2-1,d5        ; 2 Copperlists to do
lea    ColInt1,a1    ; First Copperlist
makecop:
move.w    d2,d1        ; Copy colstart to d1 (in $180xxxx!)
move.l    d0,(a1)+    ; Put WAIT in coplist
move.l    d1,(a1)+    ; Put $180xxxx (colour0) in coplist
add.l    #05000000,d0    ; wait 5 lines lower the next time
move.l    d0,(a1)+    ; put wait
move.l    d1,(a1)+    ; put $180xxxx (colour0)
add.l    #05000000,d0    ; wait 5 lines lower
move.w    d2,d4        ; copy colstart to d4
and.w    #00f,d4    ; Select only the BLUE component
cmp.w    #00f,d4    ; is it at maximum?
beq.S    endcop        ; If yes, endcop!
move.w    d2,d4        ; Otherwise, let's see the green:
and.w    #$0f0,d4    ; select only the green component.
cmp.w    #$0f0,d4    ; Is it at maximum?
beq.S    endcop        ; If yes, endcop!
move.w    d2,d4
and.w    #$f00,d4    ; Select only the RED component
cmp.w    #$f00,d4    ; Is it at maximum?
beq.S    endcop        ; If yes, ENDCOP!
add.w    d3,d2		; Add COLTENDENZA to COLORSTART
bra.S    makecop        ; And continue...
endcop:
move.l    #$fffffffe,d0    ; End copperlist in d0
move.w    d2,d1        ; Copy COLORSTART to d1
move.l    d0,(a1)+    ; End copperlist
move.l    #$4907fffe,d0
move.l    #$1800000,d1
move.w    #COLSTART,d2
move.w    #COLTENDENZA,d3
lea    ColInt2,a1
dbf    d5,makecop
rts


*****************************************************************************
;			Routine di Print
*****************************************************************************

PRINTcarattere:
movem.l	d2/a0/a2-a3,-(SP)
MOVE.L    PuntaTESTO(PC),A0 ; Address of text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
CMP.B    #$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s    NotEndLine    ; If no, do not go to the next line

ADD.L    #40*7,PuntaBITPLANE    ; GO TO THE NEXT LINE
ADDQ.L    #1,PuntaTesto        ; first character of the next line
; (skip ZERO)
move.b    (a0)+,d2        ; first character of the next line
; (skip ZERO)

NonFineRiga:
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
LSL.W    #3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; as the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)	; PRINT LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; PRINT LINE 3 ‘ ’
MOVE.B    (A2)+,40*3(A3)    ; PRINT LINE 4 ‘ ’
MOVE.B    (A2)+,40*4(A3)    ; PRINT LINE 5 " ‘
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ’ ‘
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ’ ‘
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ’ "

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
movem.l    (SP)+,d2/a0/a2-a3
RTS


PuntaTesto:
dc.l	TEXT

BitplanePointer:
dc.l    BITPLANE

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
; 1234567890123456789012345678901234567890
dc.b    “ ”,0 ; 1
dc.b    “ This listing uses COP2LC ”,0 ; 2
dc.b    “ ”,0 ; 3
dc.b    “ ($dff084) to jump, at a ”,0 ; 4
dc.b    “ ”,0 ; 5
dc.b    “ certain video line, to another ”,0 ; 6
dc.b    “ ”,0 ; 7
dc.b    “ copperlist. At the end of this ”,0 ; 8
dc.b    “ ”,0 ; 9
dc.b    “ always restart the ”,0 ; 10
dc.b    “ ”,0 ; 11
dc.b    “ copperlist 1 (in $dff180). Therefore ”,0 ; 12
dc.b	“ ”,0 ; 13
dc.b    “ just change the cop2 to which ”,0 ; 14
dc.b    “ ”,0 ; 15
dc.b    “ point each frame, for DynamiCop! ”,0 ; 16
dc.b    “ ”,0 ; 17
dc.b    “ The right key stops the exchange. ”,$FF ; 18

EVEN

;    The 8x8 character FONT (copied to CHIP by the CPU and not by the blitter,
;    so it can also be in fast RAM. In fact, that would be better!

FONT:
incbin    ‘assembler2:sorgenti4/nice.fnt’

****************************************************************************

Section	copperDynamic,data_C

copperlist:
SpritePointers:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $180,COLSTART    ; COLOR0 - ‘start’ colour
dc.w    $182,$FF0    ; colour1 - WRITING

;    dc.w    $2ce1,$fffe    ; Wait at least Y=$2c X=$d7

dc.w    $84        ; COP2LCH register (copper address 2!)
COP2LCH:
dc.w    0
dc.w    $86        ; COP2LCL register
COP2LCL:
dc.w    0

dc.w    $8a,$000    ; COPJMP2 - start copperlist 2

****************************************************************************

; spazio per la copperlist 1

ColInt1:
dcb.l	2*60,0

****************************************************************************

; spazio per la copperlist 2

ColInt2:
dcb.l	2*60,0


*****************************************************************************

SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    40*256    ; a low-resolution bitplane 320x256

SpriteNullo:            ; Null sprite to point to in the copperlist
ds.l    4        ; in any unused pointers

END

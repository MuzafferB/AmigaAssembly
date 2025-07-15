
; Lesson 11h3.s    - PRECALCULATED copper effect!!! 50 copper lists precalculated
;         and displayed in sequence using COP2LC ($dff084).

SECTION    BarrexPrecalc,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001010000000    ; only copper DMA

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
bsr.w    precalcop    ; Routine that precalculates 50 copperlists to
; make a complete ‘loop’ of the effect

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enables bitplane, copper
; and sprites.

move.l    #OURCOPPER,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12000,d2    ; line to wait for = $120
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $120
BNE.S    Waity1

btst    #2,$dff016    ; right button pressed?
beq.s    Mouse2        ; if yes, do not execute SwappaCoppero

bsr.w    SwappaCoppero    ; Point to the next copperlist for
; the correct ‘animation’ of the effect.

mouse2:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12000,d2    ; line to wait for = $120
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $120
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts


******************************************************************************
; SWAP routine for precalculated copperlists.. (an animation!!!)
******************************************************************************

;     \||||/
;     (·)(·)
;     ___\ \/ /___
;     (_ \__/ _)
;     / . \
;     / |Stz!\_ \
;    (_____| ___(_____)
;     (___) (___)
;     ¡ \_ ¡
;     |_ | _|
;     | ; |
;     | | |
;     __(____|____)__
;    (_______:_______)


SwappaCoppero:
MOVE.L    copbufpunt(PC),D0
lea    coppajumpa,a0    ; pointer addresses to cop2 in coplist
MOVE.W    D0,6(A0)    ; point to the current frame
SWAP    D0
MOVE.W    D0,2(A0)
ADD.L    #(lines*8)+AGGIUNTE,COPBUFPUNT    ; point to the NEXT COP
MOVE.L    copbufpunt(PC),D0
cmp.l    #finebuffoni,d0        ; Are we at the last copper?
bne.w    NonRibuffona        ; If not, ok
move.l    #copbuf1,copbufpunt    ; otherwise start again from the first!
NonRibuffona:
rts

******************************************************************************
;         precalculation routine for the copper effect
******************************************************************************

;    /\____/\
;    \(O..O)/
;     (----)
;     TTTT Mo!

LINEE        equ    211
AGGIUNTE	equ    20    ; LENGTH OF PARTS ADDED AT THE BOTTOM...
NUMBUFCOPPERI    equ    50    ; number of frames/copperlist!!!

PrecalCop:

; Now let's create the copperlists.

lea    copbuf1,a0        ; Address of buffers where to do cops
move.w	#NUMBER OF COOPERLISTS-1,d7    ; number of copperlists to precalculate
FaiBuf:
bsr.w    FaiCopp1        ; Make a copperlist
add.w    #(lines*8)+ADDITIONS,a0    ; point to the next one
dbra    d7,FaiBuf        ; make all the frames

; Now we ‘fill’ them, as if we were executing the effect in real time.

move.w    #NUMBUFCOPPERI-1,d7    ; number of cops to ‘fill’
lea    copbuf1,a0        ; address of first precalculated copper
ribuf:
BSR.s    changecop    ; call the routine that changes the copper
add.w    #(lines*8)+ADDITIONS,a0 ; jump to the next one to fill
dbra    d7,riBuf    ; fill all copperlists


; Finally, point the copperlists to the pointers in copperlist!!!

MOVE.L    #copbuf1,D0    ; first copper2 ‘frame’
lea    coppajumpa,a0    ; pointer to the end of copper1
MOVE.W    D0,6(A0)    ; point to...
SWAP    D0
MOVE.W    D0,2(A0)

MOVE.L    #ourcopper,D0    ; copper1 START
lea    coppajumpa2,a0    ; pointer to the end of the ‘final piece’
MOVE.W    D0,6(A0)    ; to which copper2 jumps.
SWAP    D0
MOVE.W    D0,2(A0)
rts

******************************************************************************
; routine che crea una copperlist
******************************************************************************

FaiCopp1:
move.l	a0,-(SP)
MOVE.L    #$2c07fffe,d1    ; copper wait instruction, which starts
; waiting at line $2c
MOVE.L    #$1800000,d2    ; $dff180 = colour 0 for the copper
MOVE.w    #LINEE-1,d0    ; number of lines for the loop
MOVEQ    #$000,d3    ; colour to set = black
coploop:
MOVE.L    d1,(a0)+    ; Set WAIT
MOVE.L    d2,(a0)+    ; Set $180 (colour0) to BLACK
ADD.L    #$01000000,d1	; Wait for WAIT 1 line after
DBRA    d0,coploop    ; repeat until the end of the lines
move.l    finPunt(PC),d0    ; final piece, to which all copper2
; used as frames jump.
MOVE.w    #$82,(A0)+    ; FINAL PART to point to - COP1LC
move.w    d0,(a0)+
swap    d0
MOVE.w    #$80,(A0)+
move.w    d0,(a0)+
move.l    #$880000,(a0)+    ; COPJMP1 - jump to the final piece, which
; will then re-establish copper1 as the first cop!
move.l	(SP)+,a0
rts

CopBufPunt:
dc.l	copbuf1
FinPunt:
dc.l	pezzofinale

******************************************************************************
; routine che cambia i colori in una copperlist
******************************************************************************

changecop:
move.l    a0,-(SP)    ; save a0 in the stack
MOVE.w    #LINEE-1,d0    ; number of lines for the loop
MOVE.L    PuntatoreTABCol(PC),a1    ; start of the colour table in a1
move.l    a1,TemporaryPointer    ; saved in TemporaryPointer
moveq    #0,d1            ; reset d1
LoopLines:
move.w    (a1)+,6(a0)    ; copy the colour from the table to the copperlist
addq.w    #8,a0        ; next colour0 in copperlist
addq.b    #1,d1        ; note the length of the sub-bar in d1
cmp.b    #9,d1        ; end of sub-bar?
bne.s    WaitForSubBar

MOVE.L    TemporaryPointer(PC),a1
addq.w    #2,a1            ; point to the next colour
cmp.l    #FINETABColBarra,PuntatTemporaneo    ; are we at the end of the tab?
bne.s    NonRipartire        ; if not, go to NonRipartire
lea    TABColoriBarra(pc),a1    ; otherwise, start again from the first colour!
Don't Restart:
move.l    a1,TemporaryPoint    ; and save the value in TemporaryPoint
moveq    #0,d1            ; reset d1
WaitUnderBar:
dbra d0,LoopLines    ; draw all lines

addq.l    #2,TABColPointer         ; next colour
cmp.l    #FINETABColBar+2,TABColPointer ; are we at the end of the
; colour table?
bne.s EndRoutine             ; if not, exit, otherwise...
move.l #TABColoriBarra,PuntatoreTABCol     ; start again from the first value of
; TABColoriBarra
FineRoutine:
move.l    (SP)+,a0    ; retrieve a0 from the stack
rts

;    Table with the RGB values of the colours. In this case, they are shades of BLUE

TABColoriBarra:
dc.w	$000,$001,$002,$003,$004,$005,$006,$007
dc.w	$008,$009,$00A,$00B,$00C,$00D,$00D,$00E
dc.w	$00E,$00F,$00F,$00F,$00E,$00E,$00D,$00D
dc.w	$00C,$00B,$00A,$009,$008,$007,$006,$005
dc.w	$004,$003,$002,$001,$000,$000,$000,$000
dcb.w	10,$000
FINETABColBarra:
dc.w	$000,$001,$002,$003,$004,$005,$006,$007    ; these values are needed
dc.w    $008,$009,$00A,$00B,$00C,$00D,$00D,$00E ; for the sub-bars
dc.w	$00E,$00F,$00F,$00F,$00E,$00E,$00D,$00D
dc.w	$00C,$00B,$00A,$009,$008,$007,$006,$005
dc.w	$004,$003,$002,$001,$000,$000,$000,$000


PuntatTemporaneo:
dc.l	TABColoriBarra

PuntatoreTABCol:
DC.L	TABColoriBarra

***************************************************************************

SECTION    GRAPH,DATA_C

ourcopper:
Copper2:
dc.w    $180,$000    ; Colour0 - black
dc.w    $100,$200    ; BplCon0 - no bitplanes

; here you can put spritepointers, colours, bplpointers, etc.


coppajumpa:
dc.w    $84        ; COP2LCh
DC.W    0
dc.w    $86        ; COP2LCl
DC.W    0
DC.W    $8a,0        ; COPJMP2 - start cop2 (frame)

* * * * * *

pezzofinale:            ; this piece jumps copper2 to its
dc.w    $ffdf,$fffe    ; end, every frame of animation...
dc.w	$0107,$fffe
dc.w	$180,$010
dc.w	$0207,$fffe
dc.w	$180,$020
dc.w	$0307,$fffe
dc.w	$180,$030
dc.w	$0507,$fffe
dc.w	$180,$040
dc.w	$0707,$fffe
dc.w	$180,$050
dc.w	$0907,$fffe
dc.w	$180,$060
dc.w	$0c07,$fffe
dc.w	$180,$070
dc.w $0f07,$fffe
dc.w $180,$080
dc.w    $1207,$fffe
dc.w    $180,$090
dc.w    $1607,$fffe
dc.w    $180,$0a0
dc.w    $1a07,$fffe
dc.w	$180,$0b0
dc.w    $1f07,$fffe
dc.w    $180,$0c0
dc.w    $2607,$fffe
dc.w    $180,$0d0
dc.w    $2c07,$fffe
dc.w    $180,$0e0

coppajumpa2:
dc.w    $80    ; COP1lc to restart the copperlist from ourcopper
DC.W    0
dc.w    $82    ; COP2Lcl
DC.W    0
dc.w    $FFFF,$FFFE    ; End of copperlist
finepezzofinale:


section bufcopperi,bss_C

copcols:
copbuf1:
ds.b ((lines*8)+ADDITIONS)*NUMBER OF COPPER	; 50 copperlist!
finebuffoni:

end

If you precalculate the copper effect, the multiplications, the coordinates of the
3D vectors, the music... you can make a demo that leaves the processor free
to do at least one non-precalculated effect!!!! HAHAHAHA!

Note that from copper1 you jump to copper2, at the end of which you jump
to the ‘final piece’ copper, which points back to copper1 as the starting copper!
So we jump the copper twice, and not once as in Lesson 11h.s.

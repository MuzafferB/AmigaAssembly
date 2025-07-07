
; Lesson 11g5.s - Using the copper feature to request 8 horizontal pixels
;         to perform a ‘MOVE’.
;         Right click to lower the “string”.

SECTION    String,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA only

WaitDisk    EQU    30    ; 50-150 when saving (as appropriate)

START:
bsr.w    FaiCopper    ; Create the copperlist...

lea    $dff000,a6
MOVE.W    #DMASET,$96(a6)        ; DMACON - enable bitplane, copper
; and sprites.

move.l	#COPLIST,$80(a6)    ; Point to our COP
move.w    d0,$88(a6)        ; Start the COP
move.w    #0,$1fc(a6)        ; Disable AGA
move.w    #$c00,$106(a6)        ; Disable AGA
move.w    #$11,$10c(a6)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

btst    #2,$16(a6)    ; right mouse button pressed?
bne.s    Don'tGoDown
addq.b    #1,WaitLine    ; If yes, move everything down!
Don'tGoDown:

bsr.w    MoveCopper    ; roll the string...

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


********************************
;    Routine that creates the copperlist. To make a complete horizontal line
;    you need 52 MOVE of the copper. In this case we take
;    alternatively 32 MOVE per colour, so they do not finish an
;    exact line, but the 2 colours ‘cross’ at different horizontal points
;    . This creates a ‘weaving’ effect.
******************************************************************************
;     ______________
;     / \
;     ..::;::.. / HaI CaPiTo?! \
;     ¡ ________) \_ ______________/
;     l_`--°'\°¬) / /
;     /______·)¯\ \/
;    ( \±±±±±) /
;     \________/
;     T____T xCz

NumberOfInterlacing    EQU    8
CopperSize    EQU    NumberOfInterlacing*(32*2)


FaiCopper:
LEA    CopBuf,A0        ; Buffer address in CopList
MOVEQ    #NumberOfInterlacing-1,D6    ; number of interlacing
MAIN0:
LEA    COLORS1(PC),A1    ; COLORS1 tab
MOVEQ    #32-1,D7    ; 32 colour0 for colours from COLORS1
COP0:
MOVE.W    #$0180,(A0)+    ; COLOR0 register
MOVE.W    (A1)+,(A0)+    ; colour value from the COLORS1 table
DBRA    d7,COP0        ; draw the entire ‘line’ (not just one complete line...)
LEA    COLORS2(PC),A1    ; COLORS2 table
MOVEQ    #32-1,D7    ; 32 colour0 for colours from COLORS2
COP1:
MOVE.W    #$0180,(A0)+    ; COLOR0 register
MOVE.W    (A1)+,(A0)+    ; colour value from table COLORS2
DBRA    d7,COP1        ; draw the entire ‘line’ (not 1 whole...)
DBRA    d6,MAIN0    ; Draw all the ‘interlacing’.
RTS


COLORS1:
DC.W    $003,$001,$002,$003,$004,$005,$006,$007
DC.W    $008,$009,$00A,$00B,$00C,$00D,$00E,$10F
DC.W	$10F,$00E,$00D,$00C,$00B,$00A,$009,$008
DC.W	$007,$006,$005,$004,$003,$002,$001,$003

COLORS2:
DC.W	$010,$010,$020,$030,$040,$050,$060,$070
DC.W	$080,$090,$0A0,$0B0,$0C0,$0D0,$0E0,$0F0
DC.W	$0F0,$0E0,$0D0,$0C0,$0B0,$0A0,$090,$080
DC.W	$070,$060,$050,$040,$030,$020,$010,$010


******************************************************************************
; Routine che ‘rotea’ i colori...
******************************************************************************

;     _
;     _( )_
;    (_-O-_)
;     (_)

MoveCopper:
LEA	CopBuf,A0    ; Buffer in copperlist
MOVE.w    #IngombroCopEf-1,D7
move.w    #(IngombroCopEf*4)-2,d6    ; offset to find the last colour
MOVE.W    0(A0,D6.W),D0    ; last colour in d0 (a0+offset!)
MOVE.W    D6,D5
SUBQ.W    #4,D5        ; previous colour offset in d5
SYNC0:
MOVE.W    0(A0,D5.W),0(A0,D6.W)    ; previous colour in the one ‘after’
SUBQ.W    #4,D6            ; calculate next colour offset
SUBQ.W    #4,D5            ; calculate next colour offset
dbra    d7,SYNC0        ; Execute for the entire ‘node’
MOVE.W    D0,2(A0) ; set the last colour, which we saved, as
; the first colour, so as not to interrupt the cycle.
RTS

******************************************************************************

section	coop,data_C

COPLIST:
DC.W	$100,$200	; BplCon0 - no bitplanes
DC.W	$180,$003	; Colour0 - dark blue
WaitLine:
DC.W    $4001,$FFFE    ; Wait line $40.
CopBuf:
DCB.L    IngombroCopEf,0 ; Space for the cop effect
DC.W    $180,3        ; Colour0 - dark blue
DC.w    $ffff,$fffe    : End of Copperlist

END

Another use of the peculiarity of copper moves, whereby each one causes
an 8-pixel forward “jump”. You can see that the entire effect is
composed solely of dozens of COLOR0s placed in succession, so you just need to
change the wait that precedes them to move “everything” down.

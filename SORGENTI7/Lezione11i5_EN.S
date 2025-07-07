
; Lesson11i5.s - A modification to the usual bar....

; Right click to lower the bar; you could make a table to
; make it bounce up and down

SECTION    Coppex,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001010000000	; solo copper DMA

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BEQ.S    Wait

btst    #2,$dff016    ; right mouse button?
bne.s    Don't lower
cmp.b    #$c0,HorizontalCoord    ; bar already low enough?
bhi.s    Don't lower
addq.b    #1,HorizontalCoord

Don't lower:
bsr.s    CoolRaster

btst	#6,$bfe001	; mouse premuto?
bne.s	mouse
rts

*****************************************************************************
;	routine principale
*****************************************************************************

CoolRaster:
ADDQ.W	#2,OrizzCoord
BSR.S	CoolEffetto
BSR.S	ScorriColori	; fai scorrere i colori della tab
rts


*****************************************************************************
;    Routine for scrolling the colours of the red part of the effect
;    the colours are scrolled directly in ColorTab1
*****************************************************************************

ScorriColori:
LEA    ColorTab1(PC),A0
MOVE.W    (A0),30*2(A0)        ; save the first colour at the bottom
LEA    ColorTab1+2(PC),A1    ; address of second colour
MOVEQ    #31-1,D1        ; 30 colours to ‘move’
ScorriTAB:
MOVE.W    (A1)+,(A0)+        ; colour 2 in colour 1, colour 3 in
DBRA    D1,ScorriTAB        ; colour 2 etc.
RTS

*****************************************************************************

;     _ ____ ____ _
;     \ /
;     .:::::::::: ::::::::::.
;    ( ::: + + ::: )
;     `:::::::::: ::::::::::'
;     /__ / \\ __\
;     \_\ (_____) /_/
;     _/ \_ ___ _/ \_
;     | V V |
;     /|\ /|\
;     ||| |||
;

CoolEffect:
LEA    CopperBuffer1,A0
LEA    ColorTab1(PC),A1    ; colour table 1
LEA    ColorTab2(PC),A2    ; colour table 2

MOVEQ    #29-1,D0    ; 29 lines for the effect
MOVE.W    HorizontalCoord(PC),D1    ; current horizontal wait and vertical in d1
WRITEBOTHLINES:
MOVE.W    D1,(A0)+	; put it in copperlist
MOVE.W    #$FFFE,(A0)+    ; followed by $FFFE
MOVE.W    #$0180,(A0)+    ; Colour0
MOVE.W    (A1)+,(A0)+    ; put the colour from tab1
ADD.W    #$0020,D1    ; move the wait 20 steps forward
MOVE.W    D1,(A0)+    ; and put it in copperlist
MOVE.W    #$FFFE,(A0)+    ; followed by $FFFE
MOVE.W    #$0180,(A0)+    ; colour0
MOVE.W    (A2)+,(A0)+    ; put the colour from tab2
ADD.W	#$0020,D1    ; move the wait 20 steps forward
DBRA    D0,WRITEBOTHLINES
RTS


;    Red gradient table

ColorTab1:    ; 30 RGB values for colour0 in copperlist

dc.W	$100,$200,$300
dc.W	$400,$500,$600,$700,$800,$900,$A00,$B00,$C00,$D00,$E00,$F00
dc.W     $E00,$D00,$C00,$B00,$A00,$900,$800,$700,$600,$500,$400,$300
dc.W    $200,$100,$101



;    Grey gradient table

ColorTab2:    ; 30 RGB values for colour 0 in copperlist

dc.W    $000
dc.W    $111,$222,$333,$444,$555,$666,$777,$888,$999,$AAA,$BBB,$CCC
dc.W	$DDD,$EEE,$DDD,$CCC,$BBB
dc.W    $AAA,$999,$888,$777,$666,$555,$444,$333,$222,$111,$000
dc.w    $000

;    This is the initial wait

OrizzCoord:
dc.W $3A07


*****************************************************************************
;	Copperlist
*****************************************************************************

SECTION    COP,DATA_C

COPPERLIST:
dc.w    $100,$200    ; bplcon0 - no bitplanes
DC.W    $0180,$0000    ; colour0 black
DC.W    $2B07,$FFFE    ; line wait $2b
CopperBuffer1:
dcb.W    29*8,0

dc.W    $0180,$000    ; colour0 black


dc.w    $d007,$fffe    ; Wait line $d0
dc.w    $180,$035
dc.w    $d207,$fffe    ; Wait line $d0
dc.w    $180,$047
dc.w    $d607,$fffe    ; Wait line $d0
dc.w    $180,$059

dc.W    $FFFF,$FFFE    ; end of copperlist

end


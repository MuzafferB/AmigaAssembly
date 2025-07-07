
; Lesson 11h4.s    BAR THAT GOES UP AND DOWN USING WAIT MASKING

;    This listing is identical to Lesson 3d.s, except for
;    a trick that allows us to move the entire bar
;    with a single instruction!!!! The trick is in the COPPERLIST!


SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001010000000    ; only copper DMA

WaitDisk    EQU    30    ; 50-150 on saving (depending on the case)

START:
lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

btst    #2,$dff016    ; right button pressed?
beq.s    Mouse2        ; if yes, do not execute MoveCopper

bsr.s    MoveCopper    ; Routine that exploits WAIT masking

mouse2:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts

*****************************************************************************

MoveCopper:
TST.B    SuGiu        ; Should we go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then jump to VAIGIU, if instead it is at $FF
; (if this TST is not verified)
; we continue going up (doing subq)
beq.w    VAIGIU
cmpi.b    #$34,BARRA    ; have we reached line $34?
beq.s    MettiGiu    ; if so, we are at the top and we have to go down
subq.b    #1,BARRA
rts

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
rts            ; will jump to the VAIGIU routine, and
; the bar will descend

VAIGIU:
cmpi.b    #$77,BARRA    ; have we reached line $77?
beq.s    MettiSu        ; if so, we are at the bottom and we have to go back up
addq.b    #1,BARRA
rts

MettiSu:
move.b    #$ff,SuGiu    ; When the SuGiu label is not zero,
rts            ; it means we have to go back up.

Finished:
rts


;    This byte, indicated by the label SuGiu, is a FLAG, i.e. a
;    flag (in jargon)

SuGiu:
dc.b	0,0


*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $100,$200
dc.w    $180,$000    ; Start copying with the colour BLACK

dc.w    $2c07,$FFFE    ; a small fixed green bar
dc.w    $180,$010
dc.w    $2d07,$FFFE
dc.w    $180,$020
dc.w    $2e07,$FFFE
dc.w    $180,$030
dc.w    $2f07,$FFFE
dc.w    $180,$040
dc.w    $3007,$FFFE
dc.w    $180,$030
dc.w    $3107,$FFFE
dc.w    $180,$020
dc.w    $3207,$FFFE
dc.w    $180,$010
dc.w    $3307,$FFFE
dc.w    $180,$000

;     /\ __ __ ______ __ __ /\ Mo!
;    _// \/ ____ _ _ ____ \/ \\_
;    \(_ \ \(O/ \O)/ / _)/
;     \/ _)/ _/\ \(_ \/
;     /_ __ ии\ ______ \
;    ( (_____/\ _____/ | | |\ \
;     \__________ \/ \_|_|_|_|_) )
;     \ _______________/
;     \/

BAR:
dc.w    $3407,$FFFE    ; wait for line $79 (NORMAL WAIT!)
; this wait is the ‘BOSS’ of the waits
; masked below, in fact they follow it
; like henchmen: if this wait
; goes down by 1, all the masked waits
; below go down by 1, and so on.

dc.w    $180,$300    ; start the red bar: red at 3

dc.w    $00E1,$80FE    ; This pair of copper instructions, which
dc.w    $0007,$80FE    ; instead of ending with $FFFE end
; with $80FE, can basically be translated
; as: ‘WAIT FOR THE NEXT LINE’, in this
; case the line following the BAR wait:.
; In fact, $00E180fE waits for the end of the
; line (at the right edge of the screen), which
; triggers the copper at the line following
; its horizontal position 0001 (the
; left edge of the screen). At this
; point, to ‘align’, we wait for position
; 0007 like the other waits.

dc.w    $180,$600    ; red at 6

dc.w    $00E1,$80FE    ; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH the Wait at Y ‘masked’

dc.w    $180,$900    ; red at 9

dc.w    $00E1,$80FE    ; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH Wait at Y ‘masked’

dc.w    $180,$c00    ; red at 12

dc.w    $00E1,$80FE	; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH Wait at Y ‘masked’

dc.w    $180,$f00    ; red at 15 (maximum)

dc.w    $00E1,$80FE    ; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH Wait at Y ‘masked’

dc.w    $180,$c00    ; red at 12

dc.w    $00E1,$80FE    ; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE	; WITH Wait masked at Y

dc.w    $180,$900    ; red at 9

dc.w    $00E1,$80FE    ; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH Wait masked at Y

dc.w    $180,$600    ; red at 6

dc.w    $00E1,$80FE    ; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH Wait at Y ‘masked’

dc.w    $180,$300    ; red at 3

dc.w    $00E1,$80FE    ; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH Wait at Y ‘masked’

dc.w    $180,$000    ; colour BLACK


dc.w    $fd07,$FFFE    ; wait for line $FD
dc.w    $180,$00a    ; blue intensity 10
dc.w    $fe07,$FFFE    ; next line
dc.w    $180,$00f    ; blue intensity maximum (15)
dc.w    $FFFF,$FFFE    ; END OF COPPERLIST


end

In this example, we saved quite a few MOVE commands: By changing only 1
BYTE per frame, we can scroll an entire bar! This is thanks to
‘masking the y of the wait’. In practice, the usefulness lies in the fact that
by putting these 2 masked waits:

dc.w    $00E1,$80FE	; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH the Wait at Y ‘masked’

We go to the line following the last wait $FFFE defined, and by adding
other pairs of $80fe, we can ‘stick’ many lines to the first wait.
However, despite everything, this is a little-used trick, as it has some
limitations; for example, it does not work for lines above 127 ($7f)
approximately. Try changing the maximum line that can be reached:

VAIGIU:
cmpi.b    #$77,BARRA    ; have we reached line $77?

by putting a nice $f0, and you will notice that once the $80 line is passed, the bar
flattens and becomes a line.
The Y coordinate must go from $00 to $7f, because we can only mask 6
bits. Better than nothing, though!!!

So, we can say that masking works in the upper part of the
screen from $00 to $7f approximately, and below the NTSC area, i.e. after $FFDF,$FFFE.


; Lesson skip3
;        Left key to exit.

SECTION    bau,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001010000000	; copper,bitplane,blitter DMA

Waitdisk    EQU    10

START:

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)		; Disable AGA

move.l    #copperloop,$84(a5)    ; load the loop address
; in COP2LC

mouse:
bsr.s    ChangeCopper

; note the double synchronisation check
; necessary because moveCopper requires LESS than ONE raster line on 68020+

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for the end of line $130 (304)
BEQ.S    Waity2

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:
rts

*****************************************************************************
* Questa routine cicla i colori nella copperlist
*****************************************************************************

ChangeCopper:
add.w    #$010,green    ; increase brightness
and.w    #$0f0,green    ; avoid carry to red component

add.w    #$111,white    ; increase brightness
cmp.w    #$fff,white    ; avoid carry
bls.s    no_reset
move.w    #$000,white    ; start again from black
no_reset

add.w    #$100,red    ; increase brightness
and.w    #$f00,red    ; avoid carry

rts

*****************************************************************************

SECTION	MY_COPPER,CODE_C

COPPERLIST:

; bar 1
dc.l $01800111
dc.l $2901fffe
dc.l $01800a0a
dc.l $2a01fffe
dc.l $0180011f
dc.l $2b01fffe
dc.l $01800000

dc.w    $9007,$FFFE    ; wait for line $30

copperloop:            ; the loop starts here
dc.w    $180
green:    dc.w    $080        ; green colour

dc.w    $806b,$00fe    ; wait for first third of screen
dc.w    $180
white    dc.w    $888        ; white

dc.w    $80a5,$00fe    ; wait for second third of screen

dc.w    $180
red    dc.w    $800    ; red

dc.w    $80e1,$00FE    ; wait for end of line

dc.w    $e001,$ff01    ; SKIP to line $60
dc.w    $8a,0        ; writes in COPJMP2 - jumps to the beginning of the loop

dc.w    $180,$000
dc.w $FFDF,$FFFE    ; wait for line 255

; bar 2
dc.l $01800000
dc.l $1401fffe
dc.l $0180011f
dc.l $1501fffe
dc.l $01800a0a
dc.l $1601fffe
dc.l $01800111

dc.w    $FFFF,$FFFE    ; End of copperlist

end

This example shows a use of copperloops.
We want to change COLOR0 three times within a raster line and
we want to repeat the same colours on each line. It is very convenient to use
a copperloop. The waits within the loop have their vertical positions
masked, so that they work on each raster line.
To change the colours, we only need to modify three copper instructions.
If we didn't use the copperloop, we would have to repeat the 3 changes for each raster line.
 Since the effect goes from line $90 to $e0, we have a total of
$e0-$90=$50=80 raster lines.
Thanks to the copperloop, we are 80 times faster!!!



; Lesson 11i1.s    - Full-screen colour scrolling PAL

SECTION    Scorricol,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’		; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %100000101000000    ; copper DMA only

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
BSR.w    MAKECOP        ; Make the copperlist

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #MYCOP,$80(a5)        ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1

btst    #2,$16(a5)    ; right button pressed?
beq.s    Mouse2        ; if yes, do not execute ColorScrollPAL

bsr.s    ColorScrollPAL        ; Colour scrolling

mouse2:
MOVE.L    #$1ff00,d1    ; bits for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts

*****************************************************************************
;    Routine that creates the copperlist
*****************************************************************************

;     .__ _ __..... . . .
;    -\-'_ \\// _`-/-- - - -
;     \(-)____(-)/// / / /
;     -'_/V‘’V\_`- _ _ _
;     \ \ /__ _ _ _
;     \ \,,/__ _ _ _
;     \/-Mo!

MakeCop:
lea    MYCOP,a0        ; Address of the copperlist to be created
move.l    #$1f07fffe,d0        ; WAIT instruction, first line $1f
; i.e. start WAIT
move.l    #$0007fffe,d1        ; Last NTSC line for the Copperlist
; i.e. final WAIT
bsr.w    FaiColors        ; Do this part of the Copperlist
; from $1f to $ff, i.e. the NTSC part

move.l    #$ffdffffe,(a0)+	; Special wait to wait for the end
; of the NTSC zone.
move.l    #0007fffe,d0        ; First line of the PAL zone (WAIT)
; i.e. start WAIT
move.l    #3707fffe,d1        ; Last line at the bottom of the screen
; i.e. final WAIT
bsr.s	FaiColors2        ; Do the PAL part of the copperlist
move.l    #$fffffffe,(a0)+    ; End of the copperlist
rts


*****************************************************************************
; Subroutine that creates the copperlist - enter the address of the
; copperlist in a0, the first wait in d0, and the last one to be done in d1
*****************************************************************************

;     _ _ _ ___
;    (( _ \--/ _ ) )
;    \_\(°/__\°)/_/
;     \-“_/VV\_`-/
;     \\_\” `/_/
;     \ \\..//
;     \ `\/'

FaiColors:
lea    ColorTabel(PC),a1    ; Colour table address
FaiColors2:
move.l    d0,(a0)+        ; Enter WAIT in coplist
move.w    #$0180,(a0)+        ; Enter the COLOR0 register
move.w    (a1)+,(a0)+        ; And the colour from the table
cmp.l    #ColorTabelEnd,a1    ; Are we at the last colour in the table?
bne.s    labelok            ; Not yet? Then don't restart
lea    ColorTabel(PC),a1    ; Otherwise, restart from the first colour
labelok:
addi.l    #$01000000,d0        ; Increment the Y position of WAIT
cmp.l    d0,d1			; Have we reached the last wait?
bne.s    FaiColors2        ; If not, draw another line
rts


*****************************************************************************
; Routine that moves the colours
*****************************************************************************

;     \ /
;     oO
;     \__/

ColorScrollPAL:
move.l    PuntatorecolTab(PC),a0    ; PuntatorecolTab in a0
lea    MYCOP+6,a1        ; Address of the first colour in copper
move.l	#225-1,d0        ; 225 colours to move in the NTSC area
bsr.s    scroll            ; Scroll the NTSC part of the screen
addq.w    #4,a1            ; skip the special WAIT at the end
; of the NTSC area ($FFDFFFFE)
moveq    #54-1,d0		; 54 colours to move in the PAL area
bsr.s    scroll            ; Scroll the PAL part of the screen

lea.l    PuntatorecolTab(PC),a0    ; PuntatorecolTab in a0
addq.l    #2,(a0)            ; Advance one colour for the next
; execution of the routine
cmp.l	#ColorTabelEnd,(a0)    ; have we reached the last colour
; in the table?
bne.s    Don't Restart        ; If not, exit the routine
move.l #ColorTabel,(a0)        ; Otherwise, restart from the beginning
; of the table
Don't Restart:
rts

*****************************************************************************
;    Subroutine that moves colours; the number of colours must be entered in d0,
;    the address of the colour table in a0 and the colours in coplist in a1
*****************************************************************************

scroll:
move.w    (a0)+,(a1)        ; copy the colour from the table to the
; copperlist
cmp.l    #ColorTabelEnd,a0    ; Have we copied the last colour
; from the table?
bne.s    okay            ; If not, continue
lea	ColorTabel(PC),a0    ; ColorTabel in a0 - start again from the first
; colour in the table
okay:
addq.w    #8,a1            ; Go to the next colour in copperlist
dbra    d0,scroll        ; d0 = number of colours to enter
rts


;    Table with RGB colours

ColorTabel:
dc.w	$000,$100,$200,$300,$400,$500,$600,$700
dc.w	$800,$900,$a00,$b00,$c00,$d00,$e00,$f00
dc.w	$e00,$d00,$c00,$b00,$a00,$900,$800,$700
dc.w	$600,$500,$400,$300,$200,$100,$000,$010
dc.w	$020,$030,$040,$050,$060,$070,$080,$090
dc.w	$0a0,$0b0,$0c0,$0d0,$0e0,$0f0,$0e0,$0d0
dc.w	$0c0,$0b0,$0a0,$090,$080,$070,$060,$050
dc.w	$040,$030,$020,$010,$000,$001,$002,$003
dc.w	$004,$005,$006,$007,$008,$009,$00a,$00b
dc.w	$00c,$00d,$00e,$00f,$00e,$00d,$00c,$00b
dc.w	$00a,$009,$008,$007,$006,$005,$004,$003
dc.w	$002,$001
ColorTabelEnd:

;    This is the pointer to the ColorTabel table

PuntatorecolTab:
dc.l    ColorTabel+2

*****************************************************************************
;    Copperlist created entirely by the MAKECOP routine; this way
;    you only need to make a BSS section!
*****************************************************************************

Section    Copperlist,bss_C

MYCOP:
ds.b    225*8    ; space for the PAL zone
ds.b    4    ; space for $FFDFFFFE
ds.b    55*8    ; space for the NTSC zone
ds.b    4    ; space for the end of the copperlist $FFDFFFFE

end

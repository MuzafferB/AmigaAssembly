
; Lesson skip2
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

move.l    #copperloop,d0
move    d0,cpptr1+6
swap    d0
move    d0,cpptr1+2

move.l    #copperloop2,d0
move    d0,cpptr2+6
swap    d0
move    d0,cpptr2+2

mouse:

bsr    MoveCopper

moveq    #20-1,d7

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
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Waity2

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:

rts

MoveCopper:
lea    copperloop,a0

move.w    6(a0),d0

moveq    #7-1,d1
.loop    move.w    14(a0),6(a0)
addq.l    #8,a0
dbra    d1,.loop

move.w    d0,6(a0)

lea    copperloop2,a0

move.w    6(a0),d0

moveq    #7-1,d1
moveLoop2
move.w    14(a0),6(a0)
addq.l    #8,a0
dbra    d1,moveLoop2

move.w    d0,6(a0)
rts

SECTION    MY_COPPER,CODE_C

COPPERLIST:

; bar 1
dc.l $01800111
dc.l $2901fffe
dc.l $01800a0a
dc.l $2a01fffe
dc.l $0180011f
dc.l $2b01fffe
dc.l $01800000

dc.w    $3007,$FFFE    ; wait for line $30

cpptr1
dc.w    $084,0
dc.w    $086,0

copperloop            ; this loop is executed above 
dc.w    $0007,$07fe    ; line $80. All WAITs have
dc.w    $180,$080    ; the most significant bit of the vertical position
dc.w    $0107,$07fe    ; is 0
dc.w    $180,$0a0
dc.w    $0207,$07fe    ; WAIT at line 2 with the most significant bit at 0
dc.w    $180,$0c0
dc.w    $0307,$07fe
dc.w    $180,$0e0
dc.w    $0407,$07FE
dc.w    $180,$0c0
dc.w    $0507,$07FE
dc.w    $180,$0a0
dc.w    $0607,$07FE
dc.w    $180,$080
dc.w    $0707,$07FE
dc.w    $180,$088
dc.w    $00e1,$00FE
dc.w    $8007,$ffff
dc.w    $8a,0

cpptr2
dc.w    $084,0
dc.w    $086,0

copperloop2            ; this loop is executed below 
dc.w    $8007,$07fe    ; line $80. All WAITs have
dc.w    $180,$080    ; the most significant bit of the vertical position
dc.w    $8107,$07fe    ; set to 1
dc.w    $180,$0a0
dc.w    $8207,$07fe    ; WAIT at line 2 with the most significant bit set to 1
dc.w    $180,$0c0
dc.w    $8307,$07fe
dc.w    $180,$0e0
dc.w    $8407,$07FE
dc.w    $180,$0c0
dc.w    $8507,$07FE
dc.w    $180,$0a0
dc.w    $8607,$07FE
dc.w    $180,$080
dc.w    $8707,$07FE
dc.w    $180,$088
dc.w    $80e1,$00FE
dc.w    $b007,$ffff
dc.w    $8a,0

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

This example shows the need to use two copper loops due to
the impossibility of masking the most significant bit of the vertical position.
 We use two loops that are absolutely identical, except for the
value of the most significant bit of WAIT, which is 0 for the loop executed
above line $80 and 1 in the other.
The need to use two loops naturally forces us to vary the address
contained in COP2LC, which must always be the address of the correct loop.
 Since COP2LC must be loaded in synchronisation with the video,
we do this using the copper. We load COP2LC in exactly the same
way as the other pointer registers (BPLxPT, SPRxPT, etc.) via the
copperlist. BEFORE entering a loop, the loop address is written
to COP2LC.
Note that since we are using two loops, the processor routine must rotate the
colours in both loops. Despite this, this technique is always advantageous
compared to the technique that does not use loops: in this example
we achieve the effect from line $30 to $b0, for a total of 128 lines,
which with the ‘traditional’ technique would require 128 iterations of the routine
that cycles the colours. Thanks to the loops, we can get by with 16 iterations (8 for each
loop), thus going 8 times faster.


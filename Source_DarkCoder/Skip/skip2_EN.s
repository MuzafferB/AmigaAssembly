************************************
* /\/\ *
* / \ *
* / /\/\ \ O R B_I D *
* / / \ \ / / *
* / / __\ \ / / *
* ¯¯ \ \¯¯/ / I S I O N S *
* \ \/ / *
* \ / *
* \/ *
* Feel the DEATH inside! *
************************************
* Coded by: *
* The Dark Coder / Morbid Visions *
************************************

; comments at the end of the source

SECTION    DK,code

incdir    ‘/Include/’
include    MVstartup.s        ; Startup code: takes
; control of the system and calls
; the START routine: setting
; A5=$DFF000

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA


START:
move    #DMASET,dmacon(a5)
move.l    #COPPERLIST,cop1lc(a5)
move    d0,copjmp1(a5)

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

; note the double check on synchronisation
; necessary because moveCopper requires LESS than ONE raster line on 68030
move.l    #$1ff00,d1    ; bit for selection via AND
move.l    #$13000,d2    ; line to wait for = $130, i.e. 304
.Waity1
move.l    vposr(a5),d0    ; vposr and vhposr
and.l    d1,d0        ; select only the vertical position bits
cmp.l    d2,d0        ; wait for line $130 (304)
bne.s    .waity1

.Waity2
move.l    vposr(a5),d0
and.l    d1,d0
cmp.l    d2,d0
beq.s    .waity2

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:

rts

********************************
* This routine cycles the colours in the copperlist

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
dbra    d1,move loop2

move.w    d0,6(a0)
rts

SECTION    MY_COPPER,CODE_C

COPPERLIST:

; bar 1
dc.l $01800111
dc.l $2907fffe
dc.l $01800080
dc.l $01800a0a
dc.l $2a07fffe
dc.l $0180011f
dc.l $2b07fffe
dc.l $01800000

dc.w    $3007,$FFFE    ; wait for line $30

cpptr1
dc.w    $084,0
dc.w    $086,0

copperloop            ; this loop is executed above 
dc.w    $0007,$87fe    ; line $80. All WAITs have
dc.w    $180,$080    ; the most significant bit of the vertical position
dc.w    $0107,$87fe    ; set to 0
dc.w    $180,$0a0
dc.w    $0207,$87fe    ; WAIT at line 2 with the most significant bit set to 0
dc.w    $180,$0c0
dc.w    $0307,$87fe
dc.w    $180,$0e0
dc.w    $0407,$87FE
dc.w    $180,$0c0
dc.w    $0507,$87FE
dc.w    $180,$0a0
dc.w    $0607,$87FE
dc.w    $180,$080
dc.w    $0707,$87FE
dc.w    $180,$088
dc.w    $00e1,$80FE
dc.w    $8007,$ffff
dc.w    $8a,0

cpptr2
dc.w    $084,0
dc.w    $086,0

copperloop2            ; this loop is executed below 
dc.w    $8007,$87fe    ; line $80. All WAITs have
dc.w    $180,$080    ; the most significant bit of the vertical position
dc.w    $8107,$87fe    ; is set to 1
dc.w    $180,$0a0
dc.w    $8207,$87fe    ; WAIT at line 2 with the most significant bit set to 1
dc.w    $180,$0c0
dc.w    $8307,$87fe
dc.w    $180,$0e0
dc.w    $8407,$87FE
dc.w    $180,$0c0
dc.w    $8507,$87FE
dc.w    $180,$0a0
dc.w    $8607,$87FE
dc.w    $180,$080
dc.w    $8707,$87FE
dc.w    $180,$088
dc.w    $80e1,$80FE
dc.w    $b007,$ffff
dc.w    $8a,0

dc.w    $180,$000
dc.w    $FFDF,$FFFE    ; wait for line 255

; bar 2
dc.l $01800000
dc.l $1407fffe
dc.l $0180011f
dc.l $1507fffe
dc.l $01800a0a
dc.l $1607fffe
dc.l $01800111

dc.w    $FFFF,$FFFE    ; End of copperlist

END

This example shows the need to use two copper loops due to
the impossibility of masking the most significant bit of the vertical position.
 We use two loops that are absolutely identical, except for the
value of the most significant bit of WAIT, which is 0 for the loop executed
above line $80 and 1 in the other.
The need to use two loops naturally forces us to vary the address
contained in COP2LC, which must always be the address of the correct loop.
 Since COP2LC must be loaded in synchronisation with the video,
we do this using the copper.
 We load COP2LC in exactly the same way as the other pointer registers (BPLxPT, SPRxPT, etc.) via the copperlist.
BEFORE entering a loop, the loop address is written to COP2LC.
Note that since we use two loops, the processor routine must rotate the colours in both loops.
Note that since we are using 2 loops, the processor routine must rotate the
colours in both loops. Despite this, this technique is always
advantageous over the technique that does not use loops: in this example
we achieve the effect from line $30 to $b0, for a total of 128 lines,
which with the ‘traditional’ technique would require 128 iterations of the routine
that cycles the colours. Thanks to the loops, we get by with 16 iterations (8 for each
loop), thus going 8 times faster.

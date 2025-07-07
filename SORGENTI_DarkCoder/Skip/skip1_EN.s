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

move.l    #copperloop,cop2lc(a5)    ; loads the loop address
; into COP2LC

mouse:

bsr    MoveCopper

; note the double synchronisation check
; necessary because MoveCopper requires LESS than ONE raster line on 68030
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

btst    #6,$bfe001        ; wait for mouse button
bne.s    mouse

rts

************************************************
* This routine cycles the colours in the copperlist
MoveCopper:
lea    copperloop,a0

move.w    6(a0),d0

moveq    #7-1,d1        ; only 8 colours are cycled
.loop    move.w    14(a0),6(a0)
addq.l    #8,a0
dbra    d1,.loop

move.w    d0,6(a0)
rts

SECTION    COPPER,DATA_C

COPPERLIST:

; bar 1
dc.l $01800111
dc.l $2907fffe
dc.l $01800a0a
dc.l $2a07fffe
dc.l $0180011f
dc.l $2b07fffe
dc.l $01800000

dc.w    $3007,$FFFE    ; wait for line $30

copperloop:            ; the loop starts here
dc.w    $0007,$87fe    ; wait for line 0 to start - since
; bits 3 to 7 of the vertical position are masked
; this wait will wait for all
; lines that have bits 0 to 2 set to zero
; i.e. lines $30, $38, $40, $48, etc.
dc.w    $180, $080
dc.w    $0107,$87fe    ; wait for line start 1 - since
; bits 3 to 7 of the vertical position
; are masked, this wait will wait for all
; lines that have bits 0 to 2 set to %001
; i.e. lines $31, $39, $41, $49, etc.
dc.w    $180, $0a0
dc.w    $0207, $87fe
dc.w    $180, $0c0
dc.w    $0307, $87fe
dc.w    $180, $0e0
dc.w    $0407,$87FE
dc.w    $180,$0c0
dc.w    $0507,$87FE
dc.w    $180,$0a0
dc.w    $0607,$87FE
dc.w    $180,$080
dc.w    $0707,$87FE
dc.w    $180,$088
dc.w    $00e1,$80FE    ; wait for the end of the last line of the loop
; this instruction is necessary, because
; if the WAIT on line 0 is executed
; before the end of line 7, it does not block

dc.w    $6007,$ffff    ; SKIP to line $60
dc.w    $8a,0        ; writes to COPJMP2 - jumps to the beginning of the loop

dc.w    $180,$000
dc.w $FFDF,$FFFE    ; wait for line 255

; bar 2
dc.l $01800000
dc.l $1407fffe
dc.l $0180011f
dc.l $1507fffe
dc.l $01800a0a
dc.l $1607fffe
dc.l $01800111

dc.w    $FFFF,$FFFE    ; End of copperlist

end

This example shows a use of copperloops. We want to create a copperlist
that changes COLOR00 on every raster line. As you learned in the first
lessons of the course, it is sufficient to write a copperlist that does a wait
on every line followed by a coppermove in the COLOR00 register.
 For example, if we want to change COLOR00 from line $30 to line $60, we must write
the following instructions in the copperlist:

dc.w    $3007,$fffe    ; wait for line $30
dc.w    $180,$345    ; write to colour00
dc.w    $3107,$fffe    ; wait for line $31
dc.w    $180,$456    ; write to colour00

.
.

dc.w    $6007,$fffe    ; wait for line $60
dc.w    $180,$000    ; write to colour00

This piece of copperlist occupies 4 words for each raster line, for a
total of 8*($60-$30)=384 bytes. If we want to scroll the colours, we must
use a 68000 routine that reads all the colours and rewrites them, such as the
MuoviCopper routine in this example. This routine will have to perform one iteration for
each raster line, in our case therefore $30=48 iterations.
If the colours to be written in COLOR00 are all different, this is the only method
possible. However, if the colours are not different but repeat after a while, it is
possible to use a copperloop. In our example, we want to repeat a
sequence of 8 colours. Since our effect goes from line $30 to $60
(48 lines), this means that we repeat the same sequence 6 times. We can 
therefore write a copperloop that repeats the 8 colours and make it repeat
from lines $30 to $60. The loop (which you can see in the listing) occupies
 
4 words for each colour it writes, plus 3 other instructions that each occupy
2 words (the WAIT until the end of the last line, the SKIP and the one
that writes in COPJMP2), for a total of 8*4+3*2=38 words or 56 bytes,
compared to the 384 of the copperlist without loops. Furthermore, the routine that cycles the
colours only has to perform 8 iterations compared to 48 in the “traditional” case,
meaning it runs about 6 times faster.
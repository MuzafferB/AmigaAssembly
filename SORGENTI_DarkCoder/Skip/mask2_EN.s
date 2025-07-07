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

* WARNING:
; This source is based on Lesson 11h4.s from Randy's Course
; It shows how to mask vertical positions
; across the ENTIRE screen. Comments at the end of the source
; Credits for the original source go to Randy - RJ
; Hey Randy, I hope you don't mind me improving your work!
; Friendship RULEZ! :)))) (The Dark Coder)

SECTION    DK,code
incdir    ‘/include/’
include    MVstartup.s        ; Startup code: takes
; control of the system and calls
; the START routine: setting
; A5=$DFF000

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA only

START:
lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enables bitplane, copper
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
ANDI.L	D1,D0        ; Select only the bits of the vertical position
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
move    PosBar(pc),d0    ; reads Bar position

tst.b    SuGiu        ; Should we go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then jump to VAIGIU, if instead it is at $FF
; (i.e. this TST is not checked)
; continue going up (doing subq)
beq.w    VAIGIU

cmp    #$34,d0        ; compare with the upper limit
sne    SuGiu        ; set the flag accordingly

; update the bar position in the variable and in CLIST
move    PosBarra(pc),d0
subq    #1,d0
move    d0,PosBarra
move.b    d0,Barra    ; writes low byte in the copperlist

; the second WAIT 255 must be activated when the last line of the
; bar is at line $FE, i.e. when PosBarra=$fe-8
cmp    #$fe-8,d0
bne.s    .NoAttiva2        ; if the bar starts to cross
move.b    #$ff,Attendi255_2    ; line 255 enables the second WAIT 255
bra.s    .change            ; skips the check of line $100
.NoAttiva2

; the first WAIT 255 must be activated when the first line of the
; bar is at line $ff
cmp    #$ff,d0
bne.s    .NoDisattiva1        ; if the ENTIRE bar has crossed 
move.b	#$00,Wait255_1    ; line 255, deactivate the first WAIT 255
.NoDeactivate1

.change
move    #$7f,d0
bsr    AdjustClist

move    #$ff,d0
bsr    AdjustClist

rts

VAIGIU:
cmp    #$114,d0    ; compare with the lower limit
seq    SuGiu        ; set the flag accordingly

; update bar position in the variable and in CLIST
move    PosBarra(pc),d0
addq    #1,d0
move    d0,PosBarra
move.b    d0,Barra    ; writes low byte in copperlist

; the second WAIT 255 must be disabled when the last line of the
; bar is at line $FF, i.e. when PosBarra=$ff-8
cmp    #$ff-8,d0
bne.s    .NoDisable2    ; if the bar starts to cross line
move.b    #0,Wait255_2    ; 255 disable the second WAIT 255
bra.s    .change        ; skip line $100 check
.NoDisable2

; the first WAIT 255 must be activated when the first line of the
; bar is at line $100
cmp    #$100,d0
bne.s	.NoActivate1        ; if the ENTIRE bar has crossed 
move.b    #ff,Wait255_1    ; line 255, activate the first WAIT 255
.NoActivate1

.change
move    #80,d0
bsr    AdjustClist

move    #100,d0
bsr    AdjustClist

rts


Finished:
rts

; variables
PosBarra    dc.w    $34    ; bar position
SuGiu:        dc.b    0    ; direction flag


*******************************
* Routine that corrects the CLIST
* D0 - target line, i.e. the line that delimits the entry into a different
* area of the screen.

cnop    0,4
AdjustClist
move    PosBarra(pc),d1    ; first bar line coordinate
move    d1,d2

addq    #8,d2        ; last bar line position (there are 9 lines)
cmp    d0,d2        ; compare with target line
blo.s    .exit        ; if less, the bar is ALL
; above the target line

sub    d1,d0        ; subtract the position from the target line
blo.s    .exit        ; if D1>D0, the bar is ALL
; below the target line

; otherwise, the difference tells us
; which line of the bar has the same position
; as the target line.

; D0 indicates the order number of the WAIT to be modified:
; multiply by 12, offset between 2 WAIT
asl    #2,d0
move    d0,d1
add    d0,d0
add    d1,d0

lea    PrimaWaitMascherata,a0
bchg    #7,(a0,d0.w)

.exit
rts

*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$100,$200
dc.w    $180,$000    ; Start copy with BLACK colour

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
dc.w	$3107,$FFFE
dc.w	$180,$020
dc.w	$3207,$FFFE
dc.w	$180,$010
dc.w	$3307,$FFFE
dc.w	$180,$000

Wait255_1:
dc.w    $00E1,$FFFE    ; wait for line 255

BAR:
dc.w    $3407,$FFFE    ; wait for line $79 (NORMAL WAIT!)
; this wait is the ‘BOSS’ of the
; following masked waits, in fact they follow it
; like henchmen: if this wait
; goes down by 1, all the masked waits
; below it go down by 1, and so on.

dc.w    $180,$300    ; start the red bar: red at 3

FirstMaskedWait:
dc.w    $00E1,$80FE    ; This WAIT waits for the end of a line.
; It is a WAIT with a masked vertical position.
Since this
; instruction must be executed AFTER line
; $80, the high bit (not maskable)
; must be set to 1.

dc.w    $0001,$FFFE    ; this WAIT is a ‘useless’ instruction
; in fact, it never blocks the copper.
; Its purpose is to make
; the copper lose a little time so that
; the following CMOVE is executed when
; the electronic brush has started the
; next line.

dc.w    $180,$600    ; red at 6

dc.w    $00E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; useless WAIT that slows down the copper

dc.w    $180,$900    ; red at 9

dc.w    $00E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT unnecessary, slows down the copper

dc.w    $180,$c00    ; red at 12

dc.w    $00E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT unnecessary, slows down copper

dc.w    $180,$f00    ; red at 15 (maximum)

dc.w    $00E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; useless WAIT that slows down the copper

dc.w    $180,$c00    ; red at 12

dc.w    $00E1,$80FE	; wait for end of line
dc.w    $0001,$FFFE    ; WAIT useless, slows down the copper

dc.w    $180,$900    ; red at 9

dc.w    $00E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE	; WAIT unnecessary, slows down the copper

dc.w    $180,$600    ; red at 6

dc.w    $00E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT unnecessary, slows down the copper

dc.w    $180,$300    ; red at 3

dc.w    $00E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT useless, slows down copper

dc.w    $180,$000    ; colour BLACK

Wait255_2:
dc.w    $FFE1,$FFFE    ; wait for line 255

dc.w    $2007,$FFFE    ; wait for line $FD
dc.w    $180,$00a    ; blue intensity 10
dc.w    $2107,$FFFE    ; next line
dc.w    $180,$00f    ; blue intensity maximum (15)

dc.w    $FFFF,$FFFE    ; END OF COPPERLIST

end

In this example, we show how to use vertical position masking
across the ENTIRE screen. We have the usual bar, which this time
moves across the entire screen. As we know, to use WAIT with Y masked,
 bit 8 of the specified position must be set to the same value as the
vertical position where we want the instruction to be executed.
For convenience, we will refer to lines
0 to $7F as zone 1 of the screen, lines $80 to $FF as zone 2, and lines $100 onwards as zone 3.

If we have dynamic copperlists such that a masked WAIT can
be executed at any position on the screen, the only option
is to modify the masked WAITs ‘on the fly’. As we said
in skip1.s, compared to Randy's code, we replaced the masked WAIT
DC.W $0007,$80FE with simple and NOT masked WAIT
DC.W $0001,$FFFE, which do the same thing. In this way, we have halved
the number of masked WAITs present in the CLIST and, consequently,
the number of changes to be made! In our case, in fact, we only need to modify
WAITs that wait for the end of a line. When we have to wait for the
end of a line in zones 1 or 3, we must have DC.W $00E1,$80FE, while in the
case where we are waiting in zone 2, we need DC.W $80E1,$80FE.
Therefore, we must set bit 8 of this instruction appropriately.

The more attentive among you will immediately ask, ‘But why bother
using masked WAIT if we have to modify the CLIST anyway?’.
This observation is correct. In fact, as you will remember, this effect can
also be achieved with unmasked WAIT, and the advantage of unmasked WAIT
is precisely that you do not have to modify ALL WAIT at every
frame. However, the changes to be made to unmasked WAIT are much
less. In fact, it is necessary to invert bit 8 of the vertical position
of a WAIT ONLY when that WAIT passes from zone 1 to zone 2 (or vice versa)
or when it passes from zone 2 to zone 3 (or vice versa), which only happens
occasionally. Furthermore, if, as in this case, the bar moves by 1
single row each frame, it is clear that of all the WAITs that make up the
bar, at most ONE WAIT will pass from one zone to another. In summary,
if we use unmasked WAITs, we must modify
ALL WAITs AT EVERY frame. With unmasked WAITs, on the other hand, we modify
ONE WAIT in VERY FEW frames. It is therefore clear that unmasked WAITs
are still very advantageous.

Let's see how this works in practice. As mentioned, every time a WAIT passes
from one zone to another, we must change a bit, i.e. we can simply
invert it. In the transition from zone 2 to zone 3, we have an additional problem:
the WAIT instruction that waits for line 255.

Let's first see how to modify the WAITs. All modifications are handled
by a single routine that works in all cases, to which the ‘target’ line is passed as a
parameter, i.e. the line that determines the transition from one
zone to another. This routine determines the POSSIBLE transition of one of the
WAIT instructions above the target line and consequently inverts the state of bit 8 of Y.
Note that if we GO DOWN from zone 1 to zone 2, the target line is $80,
because as soon as a WAIT is executed on line $80, its bit must
be set to 1. If, on the other hand, we GO UP from zone 2 to zone 1, the target line
becomes $7F, because as soon as a WAIT is executed on line $80, its
bit must be set to 0.
Obviously, at each iteration, our routine (AdjustClist) must be
executed twice, once to check the transition from zone 1 to zone 2
(or vice versa if we go in the opposite direction) and once to check the
transition from zone 2 to zone 3 (or vice versa if we go in the opposite direction).

It could be argued that having to execute this routine twice could
negate the advantage of having to make fewer changes to the CLIST (compared
to the case of unmasked WAITs), but this is not the case: in fact, this routine
has a fixed execution cost, while in the case of unmasked WAITs
the number of changes to be made is equal to the number of lines that make up the
bar: think of a bar 60 lines high!
Furthermore, the routine is very short and is executed in CACHE (if there is one) and makes
(if necessary) only one access to the CHIP (the modification of the clist), while
in the unmasked case, each modification of a WAIT is an access to the CHIP.

As mentioned, the transition from zone 2 to zone 3 poses another problem.
In the copperlist, there is a WAIT that waits for line $FF (255).
It is clear that if our bar is higher, this WAIT must
be executed AFTER the bar instructions, while it must be executed
before if the bar is in zone 3. To solve this problem
, we use two WAITs that wait for this line, one before and one after the bar instructions
,
 and enable them one at a time. How do we disable
and enable a WAIT? Simple, just change it by setting the Y position to 0
instead of 255 to disable it, and set it back to 255 to enable it.
Note that when the bar is partly in zone 2 and partly in
zone 3, neither of the two WAITs should be enabled, because the row wait
255 is performed by the WAITs from the bar itself. Therefore (in the event that
the bar moves from zone 2 to 3), when the bar is in zones 1 and 2, the first WAIT
is disabled and the second enabled. When the last line of the
bar is at line $FF, the WAIT after the bar is disabled.
As long as the bar is between the two zones, both waits remain
disabled, and when the first line of the bar is at line $100, the
first WAIT is enabled. If you go up, these actions occur
in reverse order.
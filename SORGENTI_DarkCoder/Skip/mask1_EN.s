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
; greater than $80. Comments at the end of the source
; Credits for the original source go to Randy - RJ
; Hey Randy, I hope you don't mind me improving your work!
; Friendship RULEZ! :)))) (The Dark Coder)

SECTION    DK,code
incdir    ‘/include/’
include    ‘MVstartup.s’        ; Startup code: takes
; control of the system and calls
; the START routine: setting
; A5=$DFF000

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA only

START:
lea    $dff000,a5
move    #DMASET,dmacon(a5)    ; DMACON - enables bitplane, copper
; and sprites.

move.l    #COPPERLIST,cop1lc(a5)    ; Point to our COP
move    d0,copjmp1(a5)        ; Start the COP

mouse:

; note the double check on synchronisation
; necessary because muovicopper requires LESS than ONE rasterline on 68030
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

btst    #2,potinp(a5)    ; right button pressed?
beq.s    .noMove    ; if yes, do not execute MoveCopper
bsr.s    MoveCopper    ; Routine that exploits WAIT masking
.noMove

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts

*****************************************************************************

MoveCopper:
tst.b    UpDown        ; Should we go up or down? If UpDown is
; reset, (i.e. TST checks BEQ)
; then jump to VAIGIU, if instead it is at $FF
; (i.e. if this TST is not verified)
; continue going up (doing subq)
beq.w    VAIGIU
cmp.b    #$80,BARRA    ; have we reached line $80?
sne    SuGiu        ; if so, we are at the top and must go down
; In Randy's code there was a Beq that jumped
; to a piece of code that reset the flag.
; Using Scc is faster and
; saves memory. It is advisable to always use
; Scc to alter flags
subq.b    #1,BARRA
rts

VAIGIU:
cmp.b    #$F0,BARRA    ; have we reached line $F0?
seq    SuGiu        ; if so, we are at the bottom and must go back up
; Here too, we have replaced Randy's BEQ
with a SEQ
addq.b    #1,BARRA
rts

SuGiu:    dc.b    0    ; direction flag


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


BAR:
dc.w    $8407,$FFFE    ; wait for line $79 (NORMAL WAIT!)
; this wait is the ‘BOSS’ of the waits
; the following masked waits follow it
; like henchmen: if this wait
; goes down by 1, all the masked waits
; below it go down by 1, and so on.

dc.w    $180,$300    ; start the red bar: red at 3

dc.w    $80E1,$80FE    ; This WAIT waits for the end of a line.
; It is a WAIT with a
; masked vertical position. Since this
; instruction must be executed AFTER the line
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

dc.w    $80E1,$80FE	; wait for end of line
dc.w    $0001,$FFFE    ; useless WAIT that slows down the copper

dc.w    $180,$900    ; red at 9

dc.w    $80E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; useless WAIT that slows down the copper

dc.w    $180,$c00    ; red at 12

dc.w    $80E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT unnecessary, slows down copper

dc.w    $180,$f00    ; red at 15 (maximum)

dc.w    $80E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; useless WAIT that slows down the copper

dc.w    $180,$c00    ; red at 12

dc.w    $80E1,$80FE	; wait for end of line
dc.w    $0001,$FFFE    ; WAIT unnecessary, slows down copper

dc.w    $180,$900    ; red at 9

dc.w    $80E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT unnecessary, slows down copper

dc.w    $180,$600    ; red at 6

dc.w    $80E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT useless, slows down the copper

dc.w    $180,$300    ; red at 3

LastEndLine:
dc.w    $80E1,$80FE    ; wait for end of line
dc.w    $0001,$FFFE    ; WAIT unnecessary, slows down the copper

dc.w    $180,$000    ; colour BLACK

dc.w    $fd07,$FFFE    ; wait for line $FD
dc.w    $180,$00a    ; blue intensity 10
dc.w    $fe07,$FFFE    ; next line
dc.w    $180,$00f    ; blue maximum intensity (15)

dc.w    $FFFF,$FFFE    ; END OF COPPERLIST

end

In Randy's lesson 11h4.s, he shows how to create a
bar with copper using WAIT with masked vertical position,
a technique that speeds up the copperlist update compared
to when WAIT with unmasked vertical positions is used.

The source code also states that it is impossible to use this technique
in vertical positions between $80 and $FF. We quote directly from
the comment in lesson11h4.s:

‘Therefore, we can say that masking works in the upper part of the
screen from $00 to $7f approximately, and below the NTSC area, i.e. after $FFDF,$FFFE.’

Well, this is false!!!
As we also explain in the article ‘More Advanced Copper’ in this
issue of Infamia, it is entirely possible to use masking in positions
between $80 and $FF with a very simple trick. The problem, in fact,
arises from the fact that the highest bit of the vertical position of the copper
is not maskable, and is therefore used by the copper to compare the
position specified in WAIT (or SKIP) and the position of the electronic brush
.
In the source file lesson11h4.s of his course, Randy uses WAIT with the 7 low bits
of the vertical position masked to wait for the end of a line.
The WAITs that Randy uses are DC.W $00E1,$80FE, which have bit 8
of the vertical position to wait for (i.e. bit 15 of the first WORD)
set to 0. If such a WAIT is executed when the electronic brush
is at a vertical position with bit 8 set to 0 
(i.e. less than $80
or greater than $FF), since the 8 bits have the same value and the other bits
of the vertical position are disabled, the horizontal position is taken into account,
 and therefore the WAIT waits for the end of the line as desired.
If, on the other hand, such a WAIT is executed when the electronic brush is
in a vertical position with bit 8 set to 1 (i.e. greater than or
equal to $80 and less than or equal to $FF), since bit 8 of the vertical position
of the electronic brush is greater than bit 8 of the position specified in the
WAIT, the copper considers the position specified by the WAIT to be less than that
of the electronic brush and does NOT wait for the end of the line.
How, then, can we wait for the end of a line whose vertical position has
bit 8 set to 1? It's very simple, using a WAIT composed as follows:

DC.W $80E1,$80FE

This WAIT differs from the one used by Randy because it has bit 8 of the
vertical position set to 1. In this way, if it is executed when the
electronic brush is at a vertical position with bit 8 set
to 1, with the 8 bits having the same value and since the other bits of the vertical position
are disabled, the horizontal position is taken into account, and
therefore the WAIT waits for the end of the line as desired.
Using WAIT of this type, we can apply the technique described
in the lesson11h4.s source to move the bar in the lines between
$80 and $FF. Note, however, that WAIT of this type does NOT work in rows
with bit 8 of the vertical position set to 0. In fact, if executed in
such rows, since bit 8 of the vertical position of the electronic brush
is less than bit 8 of the position specified in WAIT, the copper considers the
position specified by WAIT to be greater than that of the electronic brush and
therefore REMAINS STUCK ON WAIT until the electronic brush
reaches a row with bit 8 set to 1 ($80) or the copperlist restarts
from the beginning. Therefore, with the WAIT used in this source, we can move the
bar ONLY in rows between $80 and $FF. Try it for yourself.

So how do we move a bar across the ENTIRE screen?
We will see this in the example ‘mask2.s’. In the meantime, note that in
our copperlist we have another difference compared to Randy's.
 Randy uses a pair of WAIT:

dc.w    $00E1,$80FE	; WAIT FOR THE NEXT LINE
dc.w    $0007,$80FE    ; WITH the Wait at Y ‘masked’

The first WAIT waits for the end of a line. However, as you know, on the
screen a line physically begins when the copper has already reached the
position $7, so if after the first WAIT there was immediately a Copper MOVE that changes
COLOR00, you would see the colour change on the right edge of the screen
(try it again to see for yourself). This is why the second WAIT is necessary, which
waits for position $7. Note, however, that it takes very little time for the copper to
move from position $E1 to position $7 of the following line. Therefore,
 to avoid this undesirable effect, another solution can be adopted:
insert a copper instruction that does nothing, for example a WAIT (NOT masked) that waits for position 0,0 and is therefore always passed, between the WAIT that waits for the end of the line and the CMOVE that changes
COLOR00, insert a copper instruction that does nothing, for example a WAIT (NOT
masked) that waits for position 0,0 and is therefore always passed.
Even though the instruction is useless, the copper has to waste a little time
to execute it, and this loss of time is sufficient for the
electronic brush to reach position $7 in the meantime, so that the CMOVE in
COLOR00 is executed in a position that avoids the
colour change defect at the right edge. In this example, we have adopted this
technique, so instead of Randy's DC.W $0007,$80FE, we have put
simple, unmasked WAITs on line 0, i.e. DC.W $0001,$FFFE.
Why did we do this? You will find out in the example ‘mask2.s’!!!!
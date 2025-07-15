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
DMASET    EQU    %100000101000000    ; copper,bitplane,blitter DMA


START:

move    #DMASET,dmacon(a5)
move.l    #COPPERLIST,cop1lc(a5)
move    d0,copjmp1(a5)

move.l    #copperloop,cop2lc(a5)    ; load the loop address
; in COP2LC

mouse:

bsr    ChangeCopper

moveq    #3-1,d7
WaitFrame
; note the double check on synchronisation
; necessary because the move copper requires LESS than ONE raster line on 68030
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

dbra    d7,WaitFrame

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:

rts

****************************************************
* This routine moves the flag and changes the colours

CambiaCopper:

move.b    PosBandiera(pc),d0

tst.b    PosFlag
beq.s    Low

subq.b    #1,d0
cmp.b    #$81,d0
bra.s    Move        ; Bcc instructions do not alter the CC

Low    addq.b    #1,d0
cmp.b    #$bf,d0

Move
shs    PosFlag        ; head limits (both! ;)
move.b    d0,PosFlag
lsl    #8,d0
move.b    #$07,d0
move    d0,Start
add    #$4000,d0
move    d0,End

tst.b    FadeFlag
beq.s	FadeIn

FadeOut
sub    #$010,green+2    ; increase brightness
cmp    #$080,green+2
sne    FadeFlag    ; if we are at minimum, go to FadeIn

sub    #$111,white+2    ; increase brightness
sub    #$100,red+2    ; increase brightness
rts

FadeIn
add    #$010,green+2    ; increase brightness
cmp    #$0f0,green+2    ; if at maximum, go to FadeOut
seq    FadeFlag

add    #$111,white+2    ; increase brightness
add    #$100,red+2    ; increase brightness

rts

* Position of the first line of the flag
; The flag must remain between lines $80 and $ff, so being $40 high
; the position must vary between lines $80 and $bf
PosFlag    dc.b    $a0
PosFlag		dc.b	0
FadeFlag	dc.b	0

SECTION	MY_COPPER,CODE_C

*************************************************************************
* Copper Macros by The Dark Coder / Morbid Visions
* vers. 3 SE / 16-07-96 / for ASM One 1.29
* this is a reduced version of the copper macros used by Morbid Visions
* created specifically for the sources published on Infamia.
* The complete version (integrated with the other standard MV macros) has
* additional error checking and allows the use of the Blitter
* Finished Disable bit. Anyone interested can contact The Dark Coder.

* format
* CMOVE immediate value, destination hardware register
* WAIT Hpos,Vpos[,Hena,Vena]
* SKIP Hpos,Vpos[,Hena,Vena]
* CSTOP

* Note: Hpos,Vpos are copper coordinates, Hena, Vena are mask values
* of the copper position, optional (if not specified,
* Hena=$fe and Vena=$7f are assumed)

cmove:    macro
dc.w     [\2&$1fe]
dc.w    \1
endm

wait:    macro
dc.w    [\2<<8]+[\1&$fe]+1
ifeq    narg-2
dc.w    $fffe
endc    
ifeq    narg-4
dc.w    $8000+[[\4&$7f]<<8]+[\3&$fe]
endc
endm

skip:    macro
dc.w    [\2<<8]+[\1&$fe]+1
ifeq    narg-2
dc.w    $fffe
endc
ifeq    narg-4
dc.w    $8000+[[\4&$7f]<<8]+[\3&$fe]+1
endc
endm


cstop:    macro
dc.w    $ffff
dc.w    $fffe
endm


* start copperlist
COPPERLIST:

; bar 1
cmove    $111,color00
wait    $7,$29
cmove    $a0a,color00
wait	$7,$2a
cmove    $11f,color00
wait    $7,$2b
cmove    $000,color00

Start:
wait    $7,$80

copperloop:            ; the loop starts here

green:    cmove    $080,color00    ; green colour. The RGB value to be loaded into the
; register is located at address ‘green+2’
; because it is the second word of the instruction
; copper

wait    $6b,$80,$fe,0    ; wait for the first third of the screen
; (the y's are masked)

white:    cmove    $888,color00    ; white. Change to ‘white+2’
wait    $a5,$80,$fe,0    ; wait for second third of screen

red:    cmove    $800,color00    ; red. Change to ‘red+2’
wait    $e0,$80,$fe,0    ; wait for end of line

End:
skip    0,$c0,0,$7f    ; SKIP to line $c0
; (the x's are masked)

cmove    0,copjmp2    ; writes to COPJMP2 - jumps to the beginning of the loop

cmove    $000,color00
wait    220,255

; bar 2
wait    $7,$14
cmove    $11f,color00
wait    $7,$15
cmove    $a0a,color00
wait    $7,$16
cmove    $111,color00

cstop            ; End of copperlist

end

This example shows a significant optimisation achieved through the use
of copperloops.
We have a flag that changes colour and moves up and down.
To draw the flag, COLOR00 must be changed three times within a
raster line and the same colours must be repeated on each line. It is very convenient to use
a copperloop. The waits within the loop have their vertical positions
masked so that they work on every raster line without being
modified.
To change the colours, only 3 copper instructions need to be modified.
Furthermore, to move the flag vertically, simply modify the
wait position of the WAIT preceding the loop and the SKIP ending the
loop. In total, therefore, we only have five changes to make in memory.

If we did not use either the copper loop or the masked WAITs, we would have to modify
the three CMOVE (copper move) and three WAIT instructions at each raster line to wait for the
various positions. Since the flag is 64 lines high, we would have a total of
64*6=384 memory locations to modify.

As you can also see, and as mentioned in the article on Infamia,
this source defines and uses macros to define the
copper instructions. In this way, you get (in my opinion)
cleaner sources and reduce the likelihood of making mistakes when writing
copper lists. For example, compare the part of the copper list that generates
the coloured bar at the top of this source with the identical piece generated
with DC.W in the skip1.s and skip2.s examples. The version in this source is
immediately understandable even at a quick glance and is much more
elegant and tidy.
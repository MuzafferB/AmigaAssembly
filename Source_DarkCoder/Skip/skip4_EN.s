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
DMASET    EQU    %1000001010000000    ; copper,bitplane,blitter DMA


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
; necessary because moveCopper requires LESS than ONE raster line on 68030
move.l    #$1ff00,d1    ; bit for selection via AND
move.l    #$13000,d2    ; line to wait for = $130, i.e. 304
.Waity1
move.l    vposr(a5),d0	; vposr and vhposr
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

ChangeCopper:

move.b    FlagPosition(pc),d0

tst.b    FlagPosition
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
beq.s    FadeIn

FadeOut
sub    #$010,green+2    ; increase brightness
cmp    #$080,green+2
sne    FadeFlag    ; if we are at minimum, go to FadeIn

sub    #$0100,red+2    ; increase brightness
rts

FadeIn
add    #$010,green+2    ; increase brightness
cmp    #$0f0,green+2	; if we are at maximum, go to FadeOut
seq    FadeFlag

add    #$100,red+2    ; increase brightness

rts

* Position of the first line of the flag
; The flag must remain between lines $80 and $ff, so being $40 high
; the position must vary between lines $80 and $bf
FlagPosition    dc.b    $a0
FlagPosition        dc.b    0
FadeFlag    dc.b    0

SECTION    MY_COPPER,CODE_C

*************************************************************************
* Copper Macros by The Dark Coder / Morbid Visions
* vers. 3 SE / 16-07-96 / for ASM One 1.29
* this is a reduced version of the copper macros used by Morbid Visions
* created specifically for the source code published on Infamia.
* The full version (integrated with the other standard MV macros) has
* additional error checking and allows the use of the Blitter
* Finished Disable bit. Anyone interested can contact The Dark Coder.

* format
* CMOVE immediate value, destination hardware register
* WAIT Hpos,Vpos[,Hena,Vena]
* SKIP Hpos,Vpos[,Hena,Vena]
* CSTOP

* Note: Hpos,Vpos are copper coordinates, Hena, Vena are the mask values
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
wait    $7,$2a
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

wait    $1e-4,$80,$3e,0    ; wait for first part
; the y's are completely masked
; the 2 most significant bits
; of the x's are masked.
 In this way, the loop is repeated 4 times per line.

red:    cmove    $0800,color00        ; red. Change to ‘red+2’
wait    $3e-20,$80,$3e,0    ; second colour change


End:
skip    $0,$c0,$0,$7f    ; SKIP to line $c0
; (the x bits are masked)

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

This example shows a copper loop that repeats several times during the
same line, thanks to the use of WAIT with (PARTIALLY) masked
X coordinates.
This is a variation of the skip3.s example, in which we have
a ‘flag’ formed by 2 colours that repeat horizontally.
The body of the loop consists of only 2 CMOVE, one for each different
colour used. By masking the two most significant bits of the horizontal position
of the WAIT, the cycle is repeated 4 times for each
line, similar to what we saw for the vertical positions.
To have a loop that repeats twice for each row, simply mask
only the most significant bit of the horizontal positions of the WAITs.
Note that it is very difficult to obtain loops that repeat more than
four times, because the WAITs would have to wait for horizontal positions
so close to each other that the copper would not even have time to execute
a single instruction.

Note that to have colour bands of the same size,
 you must adjust the horizontal wait positions of the
WAITs appropriately to compensate for the fact that when the copper ‘exits’ the wait
in the first WAIT of the loop, it immediately executes the following CMOVE $xx,COLOR00, while
when it ‘exits’ the wait in the second WAIT, it must execute the SKIP and the
CMOVE $0,COPJMP2 before returning to execute CMOVE $yy,COLOR00 at the beginning
of the loop. 

Note that this type of copper usage is similar to that used
to generate plasmas. In the case of plasmas, WAIT and CMOVE are not used
and are executed continuously. In the case of plasmas, each colour change
corresponds to a different CMOVE. In this case, however, many colour changes
are performed using a single CMOVE. The disadvantage is that, of course,
the ‘bands’ generated by the same CMOVE cannot have different colours,
but there is the complementary advantage that only one
write to memory is needed to change their colour. In this example, only two copper instructions are modified at each frame
. If we did not use WAIT with masked horizontal positions
,
 we would have to use eight CMOVE to change all the colours in
a row and, consequently, we would have to modify all eight at each frame.
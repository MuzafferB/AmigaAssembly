*************************************************************
; HELIX - coded by Dan Phillips 19 Jan 93
;
; Modified by Randy/Ram Jam in 1995
*****************************************************************************

;    Use joystick to move Helix!

Section BITPLANEolljelly,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’    ; save interrupt, dma etc.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper, bitplane DMA enabled

WaitDisk    EQU    10    ; 50-150 on save (depending on the case)

PlaneSize:    equ    40*256        ; 10240

START:

; Point to our 3 bitplanes:

move.l    #BitMap,d0    ; Bitplane address
move.w    d0,onelo
swap    d0
move.w    d0,onehi
swap    d0
add.l    #PlaneSize,d0
move.w    d0,twolo
swap    d0
move.w    d0,twohi
swap    d0
add.l    #PlaneSize,d0
move.w    d0,thrlo
swap    d0
move.w    d0,thrhi

; Set the variables

move.w    #1,RotationSpeed
move.w    #3,Tightness

; Point to the Copperlist

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$0d000,d2    ; line to wait for = $d0
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $d0
BNE.S    Waity1

MOVEM.L    D0-D7/A0-A6,-(SP)

bsr.s    Joystick
bsr.w    MakeHelix        ;make new data & draw it 

MOVEM.L    (SP)+,D0-D7/A0-A6

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$0d000,d2    ; line to wait for = $d0
Wait:
MOVE.L    4(A5),D0	; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $d0
BEQ.S    Wait

btst    #6,$bfe001    ; Mouse pressed?
bne.s    mouse
rts            ; exit


******************************************************************************
; Routine that reads the joystick and changes the effect values, as it
; modifies the 2 variables RotationSpeed and Tightness
******************************************************************************

Joystick:
bsr.w    ReadJoystick    ; Read the joystick
move.w    StickX(PC),d0    ; right/left = 1/-1
move.w    RotationSpeed(PC),d1    ; Current speed
add.w    d0,d1        ; add right/left value, i.e. +1
; if right, -1 if left
move.w    d1,d0
bpl.s    poa
neg.w    d0
poa:
cmpi.w    #360,d0        ; Have we reached 360?
bcc.s    toobig		; If not, ok
move.w    d1,RotationSpeed ; Otherwise, stay at 360, it's the maximum!
toobig:
addq.w    #1,slow        ; slow down the speed variation a little
cmp.w    #3,slow        ; have we reached 3?
bne.s    too		; If not, wait
clr.w    slow        ; reset the var slow

move.w    StickY(PC),d0    ; up/down = -1/1
move.w    Tightness(PC),d1
add.w    d0,d1        ; add Y value from the joy

move.w    d1,d0
bpl.s    pos
neg.w    d0
pos:
cmpi.w    #360,d0        ; are we at maximum?
bcc.s    too
move.w    d1,Tightness    ; if you remain at 360
too:
rts

slow:    dc.w    0

;---------------------- subroutine that reads the joystick --------------------
;
; On output, the StickX and StickY variables indicate the direction right/left or
; up/down: if up, StickY=-1, if down, StickY=1
; if right, StickX=1, if left, StickX=-1.
; In addition, Fire=0 or 1 if the fire button is pressed.

ReadJoystick:
move.w    #0,Fire
btst    #7,$bfe001    ; Fire button pressed?
bne.s    nofire        ; If not, continue
move.b    #1,Fire        ; Otherwise, Fire=1
nofire:
clr.w    StickX        ; Reset variables
clr.w    StickY
move.w    $dff00c,d3    ; joy1dat in d3
move.w    d3,d1
lsr.w    #1,d1
eor.w    d3,d1
btst.l    #0,d1    ; down?
bne.s    jback    ; If yes, StickY=1
btst.l    #8,d1
bne.s    jforward
bra.s    jx

jback:
move.w    #1,StickY    ; Down, StickY=1
bra.s    jx

jforward:
move.w    #-1,StickY    ; Up, StickY=-1

; Check right-left

jx:
btst.l    #9,d3
beq.s    jon3
move.w    #-1,StickX    ; Left, StickX=-1
rts

jon3:
btst.l    #1,d3
beq.s    jon4
move.w    #1,StickX    ; Right, StickX=1
jon4:
rts

StickX:
dc.w    0
StickY:
dc.w    0
Fire:
dc.w    0

******************************************************************************
; Routine that moves the effect across the screen
******************************************************************************

CenterOfScreen:    equ    160

ElementSize:    equ    4    ;size of each entry


MakeHelix:
lea    SaveArray,a6
moveq    #0,d7            ;counter
move.w    AngleTop(PC),d0
add.w    RotationSpeed(PC),d0
bpl.s    ok
addi.w    #360,d0
bra.s    cont

ok:
cmpi.w    #360,d0
bcs.s    cont
subi.w    #360,d0
cont:
move.w    d0,AngleTop
move.w    d0,CurrentAngle

doit:
tst.l    (a6)
beq.s    skip
move.l    (a6),a0
clr.l (a0)
lea PlaneSize(a0),a0
clr.l (a0)
lea PlaneSize(a0),a0
clr.l (a0)
skip:
move.w CurrentAngle(PC),d0
add.w Tightness(PC),d0

bpl.s    ok2
addi.w    #360,d0
bra.s    cont2
ok2:
cmpi.w    #360,d0
bcs.s    cont2
subi.w    #360,d0
cont2:
move.w    d0,CurrentAngle
bsr.s    Cosine            ;find x co.
addi.w    #CenterOfScreen,d0
move.w    d0,xvalue        ;save this for now

;draw it
lea    BitMap,a0
move.w    d7,d0        ;work out which line
move.w    d7,d1
asl.w    #5,d0        ;x 40
asl.w    #3,d1
add.w    d1,d0
adda.w    d0,a0

move.w    xvalue(PC),d0
asr.w    #4,d0        ;x/16
move.w    d0,d1        ;save this
asl.w    #1,d0        ;convert to bytes
adda.w    d0,a0
move.l    a0,(a6)        ;save this while we're here

move.w    xvalue(PC),d0
asl.w    #4,d1
sub.w    d1,d0        ;shift value

moveq    #2,d2
lea    BobData,a1
next:
moveq    #0,d1
move.w    (a1)+,d1
swap    d1
lsr.l    d0,d1        ;just like the blitter!
move.l    d1,(a0)        ;draw it
lea    PlaneSize(a0),a0
dbf    d2,next

addq.w	#ElementSize,a6
addq.w    #1,d7
cmpi.w    #150,d7
bne.w    doit
rts

xvalue:        dc.w    0
CurrentAngle:    dc.w    0
AngleTop:    dc.w	0
Tightness:    dc.w    0
RotationSpeed:    dc.w    0

Cosine:                ;d0 angle, returns cos in d0
move.l    a6,-(SP)
bsr.w    sok
move.l    (SP)+,a6
rts

sok:
lea    CosTable(PC),a6
cmpi.w    #90,d0
bcc.s    gt90
asl.w    #1,d0        ;< 90
move.w    0(a6,d0.w),d0
rts

gt90:
cmpi.w    #180,d0
bcc.s    gt180
move.w    #180,d1        ;90 < a < 180
sub.w    d0,d1
move.w    d1,d0
asl.w    #1,d0
move.w    0(a6,d0.w),d0
neg.w    d0
rts

gt180:
cmpi.w    #270,d0
bcc.s    gt270

subi.w    #180,d0        ;180 < a < 270
asl.w    #1,d0
move.w    0(a6,d0.w),d0
neg.w    d0
rts

gt270:
move.w    #360,d1        ;270 < a <360
sub.w    d0,d1
move.w    d1,d0
asl.w	#1,d0
move.w	0(a6,d0.w),d0
rts


BobData:
dc.w	$cccc,$3c3c,$03fc

CosTable:
dc.w	100,100,100,100,100,100,99,99,99,99,98,98,98,97,97,97
dc.w	96,96,95,95,94,93,93,92,91,91,90,89,88,87,87,86,85,84
dc.w	83,82,81,80,79,78,77,75,74,73,72,71,69,68,67,66,64,63
dc.w	62,60,59,57,56,54,53,52,50,48,47,45,44,42,41,39,37,36
dc.w	34,33,31,29,28,26,24,22,21,19,17,16,14,12,10,9,7,5,3,2,0

******************************************************************************
;				COPPERLIST
******************************************************************************

section	cop,data_C
CopperList:
dc.w    $108,0        ; bpl1mod
dc.w    $10a,0        ; bpl2mod
dc.w    $92,$38        ; ddfstrt
dc.w    $94,$d0        ; ddfstop
dc.w    $8e,$2c81	; diwstrt
dc.w    $90,$2cc1    ; diwstop
dc.w    $102,0        ; bplcon1
dc.w    $104,0        ; bplcon2
dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes (8 colours)

dc.w    $e0    ; bpl0pth
onehi:
dc.w    0
dc.w    $e2    ; bpl0ptl
onelo:
dc.w    0
dc.w    $e4    ; bpl1pth
twohi:
dc.w    0
dc.w    $e6    ; bpl1ptl
twolo:
dc.w	0
dc.w    $e8    ; bpl2pth
thrhi:
dc.w    0
dc.w    $ea    ; bpl2ptl
thrlo:
dc.w    0

dc.w    $180,$000	; colour0
dc.w    $182,$fff    ; colour1
dc.w    $184,$ddd    ; colour2
dc.w    $186,$bbb    ; colour3
dc.w    $188,$999    ; colour4
dc.w    $18a,$777    ; colour5
dc.w    $18c,$555    ; colour6
dc.w    $18e,$333    ; colour7

dc.w    $ffff,$fffe    ; End of copperlist

******************************************************************************
;				BITPLANES
******************************************************************************

section	bitmap,bss_C

BitMap:
ds.b	PlaneSize*3


******************************************************************************

section	bufferozzo,bss

SaveArray:
ds.b	256*ElementSize	;256 lines

END
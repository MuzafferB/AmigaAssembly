
; Lesson11i2.s    - ‘Pseudoparallasse’ bars

SECTION    ParaCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %100000101000000    ; copper DMA only

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
bsr.w    WriteWaits    ; Create the 2 copperlists...

lea    $dff000,a6
MOVE.W    #DMASET,$96(a6)        ; DMACON - enables bitplane, copper
; and sprites.

move.l    #KOPLIST1,$80(a6)    ; Point to our COP
move.w    d0,$88(a6)		; Start the COP
move.w    #0,$1fc(a6)        ; Disable AGA
move.w    #$c00,$106(a6)        ; Disable AGA
move.w    #$11,$10c(a6)        ; Disable AGA

mouse:
bsr.w    waitvb                ; Wait for vertical blank
move.l    #koplist2,$dff080
move.l    #koplist1Waits+6,print        ; start cop
move.l    #koplist1Waits+6+(8*200),a5    ; end cop
bsr.w    cleacop                ; clear the copperlist
bsr.w    makeBeams            ; draw the bars

bsr.w    waitvb                ; Wait for vertical blank
move.l    #koplist1,$dff080
move.l    #koplist2Waits+6,print        ; start copy
move.l    #koplist2Waits+6+(8*200),a5    ; end copy
bsr.w    cleacop                ; clear the copperlist
bsr.w    makeBeams            ; draw the bars

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts            ; exit

*****************************************************************************
;    Routine that creates the 2 copperlists
*****************************************************************************

;    __/\__
;    \(Oo)/
;    /_()_\
;     \/

WriteWaits:
lea    koplist1waits,a1
lea    koplist2waits,a2
move.l    #$2c07ff00,d0    ; Wait (first line $2c)
move.l    #$01800000,d2    ; Colour0
move.w    #200-1,d1    ; Number of waits (200 for the NTSC area)
WWLoop:
move.l    d0,(a1)+    ; Wait in coplist 1
move.l    d0,(a2)+    ; Wait in coplist 2

move.l    d2,(a1)+    ; Colour0 in coplist1
move.l    d2,(a2)+    ; Colour0 in coplist2
add.l    #$01000000,d0    ; Wait 1 line below
dbra    d1,WWLoop
RTS

*****************************************************************************
;    Routine that ‘cleans’ the background
*****************************************************************************

;    __/\__
;    \[oO]/
;    /_--_\
;     \/

CleaCop:
move.l    print(PC),a0    ; current copper
moveq    #$001,d0	; Background colour
move.w    #(200/4)-1,d1    ; number of waits
Clealoop:
move.w    d0,(a0)        ; reset
move.w    d0,8(a0)    ;...
move.w    d0,8*2(a0)
move.w    d0,8*3(a0)
lea    8*4(a0),a0
dbra    d1,Clealoop    ; repeat 200/4 times, because it clears 4
rts            ; words per loop! (faster!)

*****************************************************************************
;	Routine che attende il vblank
*****************************************************************************

;    __/\__
;    \-OO-/
;    /_\/_\
;     \/

Waitvb:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$0ff00,d2    ; line to wait for = $FF
Waity1:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $FF
BNE.S    Waity1
Wait:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $FF
BEQ.S    Wait
RTS

*****************************************************************************
;	Routine che modifica le copperlist
*****************************************************************************

;	__/\__
;	\(OO)/
;	/_==_\
;	 \/

MakeBeams:
lea    beam01(pc),a1    ; colour tab bar 1
move.l    beam01x(pc),d0    ; the x...
moveq    #10,d1        ; the distance between 1 and the other
bsr.w    writebeam

lea    beam02(PC),a1    ; colour tab bar 2
move.l    beam02x(PC),d0    ; the x...
moveq    #25,d1        ; the distance between 1 and the other
bsr.w    writebeam

lea    beam03(PC),a1    ; colour tab bar 2
move.l    beam03x(PC),d0    ; the x...
moveq    #55,d1        ; the distance between 1 and the other
bsr.w    writebeam

; BEAM01x goes down by 1 every 2 frames.

subq.b    #1,timer01x    ; 1 frame every 2.
bne.s    Non01x        ; frame passed? (timer1x=0?)
move.b    #2,timer01x    ; reset 2 frames

addq.l    #1,beam01x    ; Decrease Beam01x by 1
cmp.l    #8+10,beam01x    ; are we at the bottom?
bne.s    Non01x
clr.l    beam01x		; If so, restart!
Non01x:

; BEAM02x goes down by 1 every frame.

addq.l    #1,beam02x    ; decrease beam02x by 1
cmp.l    #16+25,beam02x    ; are we at the bottom?
bmi.s    NONON2
clr.l    beam02x        ; if so, restart
NONON2:

; BEAM03x decreases by 2 every frame.

addq.l    #2,beam03x    ; Decrease beam03x by 2

cmp.l    #16+55,beam03x    ; are we at the bottom
bmi.s    NONON3

clr.l    beam03x        ; if restart.
NONON3:
RTS

timer01x:
dc.b    2

even

print:        dc.l    koplist1Waits+6        ; Current copper

beam01x:    dc.l 10
beam02x:    dc.l 5
beam03x:    dc.l 2


*****************************************************************************
;    Routine that ‘writes’ the bars
*****************************************************************************
;    lea    beam01(pc),a1    ; Beam01 colour table
;    move.l    beam01x(pc),d0    ; the x...
;    moveq    #10,d1		; the distance between 1 and the other

;    __/\__
;    \ $$ /
;    /_()_\
;     \/

WriteBeam:
move.l    print(PC),a0    ; current copper address
move.l    a1,a2        ; colour table address in a1 and a2
lsl.w	#3,d0        ; X * 8
lsl.w    #3,d1        ; Distance between bars * 8
add.w    d0,a0        ; find offset (x*8)
WBLoop2:
move.l    a2,a1        ; colour table
WBLoop:
tst.w    (a1)        ; colour table finished?
beq.s    EndOfBeam    ; if yes, exit!
move.w    (a1)+,(a0)    ; Copy the colour from the table to the copybar
addq.w    #8,a0        ; go to the next colour0
cmp.l    a5,a0        ; end of the copperlist?
bmi.s    WBloop        ; if not yet, insist
EndOfBeam:
add.w    d1,a0        ; once a bar is finished, make another one
; below: add the distance * 8 to
; find where the next bar begins
cmp.l    a5,a0        ; and check that we are not outside the copper
bmi.s    WBloop2        ; If we are not outside, we can go!
RTS


; Colour table for the ‘furthest’ and slowest bars (blue)

Beam01:
dc.w    $003
dc.w    $005
dc.w    $007
dc.w    $009
dc.w    $00a
dc.w    $007
dc.w    $005
dc.w    $003
dc.w    0

; Colour table for intermediate bars (green)

Beam02:
dc.w    $001
dc.w    $001

dc.w    $010
dc.w    $020
dc.w    $030
dc.w    $040
dc.w    $050
dc.w    $060
dc.w    $070
dc.w    $060
dc.w    $050
dc.w    $040
dc.w    $030
dc.w    $020
dc.w    $010

dc.w    $001
dc.w    0

; Colour table for ‘near’ bars (orange)

Beam03:
dc.w    $110
dc.w    $320
dc.w    $520
dc.w    $730
dc.w    $940
dc.w    $b50
dc.w    $d60
dc.w    $f70
dc.w    $f60
dc.w    $b50
dc.w    $940
dc.w    $730
dc.w    $520
dc.w    $420
dc.w    $320
dc.w    $210
dc.w	$110
dc.w	0


*****************************************************************************

SECTION	koplists,DATA_C

; Prima copper

koplist1:
dc.w	$180,$666	; Color0
dc.w    $100,$200    ; bplcon0 - no bitplanes
koplist1waits:
dcb.w    4*200,0        ; Space for the effect
dc.w    $180,$666    ; Color0
dc.w $ffff,$fffe    ; End of the copperlist

; Second copper, swapped with the first for a sort of ‘double buffering’
; for copperlist, to eliminate the possibility of not being able to write in
; time in colour0 to prevent the writing itself from being ‘noticed’.

koplist2:
dc.w    $180,$666	; Colour0
dc.w    $100,$200    ; bplcon0 - no bitplanes
koplist2waits:
dcb.w    4*200,0        ; Space for the effect.
dc.w    $180,$666    ; Colour0
dc.w $ffff,$fffe    ; End of copperlist

end

This listing has the peculiarity of having ‘double coppering’, i.e.
writing on one copper while displaying another written before, in order
to avoid ‘noticing’ the slower writing on the screen. You could also
use the COP2LC+COPJMP2 system to swap copperlists.

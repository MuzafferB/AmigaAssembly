
; Lesson11i4.s - Original shadow/ELECTRON effect modified.

; PRESS THE RIGHT KEY TO CHANGE THE TONE OF THE SHADOWS...

SECTION    Barrex,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA only

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

range        equ    20
NumeroLinee    equ    257

START:

bsr.w    initcopbuf    ; Prepare the copperlist

lea    $dff000,a6
MOVE.W    #DMASET,$96(a6)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COP,$80(a6)        ; Point our COP
move.w    d0,$88(a6)        ; Start the COP
move.w    #0,$1fc(a6)        ; Disable AGA
move.w    #$c00,$106(a6)		; Disable AGA
move.w    #$11,$10c(a6)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Wait:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BEQ.S    Wait

bsr.w    copmove        ; main effect - colour fading
bsr.w    cycle        ; scrolls (cycles) the colours

btst.b    #2,$dff016        ; right mouse button pressed?
bne.s    Don't change mask
move.w    6(a6),ColourMask    ; VHPOSR - set a random value
move.b    7(a6),d0        ; HPOSR
and.w    #%011001110011,ColourMask

Don'tChangeMask:
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

rts


*****************************************************************
; This routine makes the colours ‘flow’ from the centre towards the edges
*****************************************************************

;     ####
;     :00:
;     |--|
;     ___¯||¯___
;     _/ _¯\/¯_ \_
;     \___| |___/
;     __/ _| | \_/_
;     /\ |______\ \
;     "| \
;     | V |
;     | | |
;     | | |
;     :/__|__|
;     __| |__
;    *******************

Chiarostep:
dc.w    10

cycle:
lea    copbuf+6+8,a0        ; first colour at the top
lea    copbuf+6-8+[256*8],a1    ; last colour at the bottom

moveq     #128-1,d0    ; number of cycles
cycleloop:
subq.w    #01,count    ; each ‘chiarostep’ lighten the colour.
bne.s    gocycle
add.w    #$101,(a0)    ; lighten colour 1 every 10
move.w	ChiaroStep(PC),count
gocycle:
move.w     (a0),-8(a0)    ; scroll up the top part
move.w     (a0),8(a1)    ; scroll down the bottom part
addq.w    #8,a0
subq.w    #8,a1
dbra    d0,cycleloop
rts

count:
dc.w	10

***************************************************************
; Questa routine sfuma i colori
***************************************************************

copmove:
lea    copbuf+6+[128*8],a1    ; half screen
smooth:
move.w     OldColour(pc),d0
move.w     NewColourRandom(pc),d1
cmp.w    d0,d1            ; old colour equal to new?
beq.s    newcol		; then take a new colour ‘at random’

subq.w    #01,counter    ; counter = 0?
beq.s    gosmooth    ; if it “fades”...
bra.s    draw        ; otherwise just put it.

; ‘fading’ of colours - simply add and subtract the components, nothing
; special.

gosmooth:
move.w    #range,counter 

move.w     d0,d2
move.w     d1,d3
and.w    #$000f,d2    ; only bli component
and.w    #$000f,d3
cmp.w    d2,d3
beq.s    blueready
bgt.s    addblue
subblue:
sub.w    #0001,d0    ; - blue
bra.s    blueready
addblue:
add.w    #0001,d0    ; + blue
blueready:
move.w     d0,d2
move.w     d1,d3
and.w    #$00f0,d2    ; green component only
and.w    #$00f0,d3
cmp.w    d2,d3
beq.s    greenready
bgt.s    addgreen
subgreen:
sub.w    #$0010,d0    ; - green
bra.s    greenready
addgreen:
add.w    #$0010,d0    ; + green
greenready:
move.w     d0,d2
move.w     d1,d3
and.w    #$0f00,d2    ; only red component
and.w    #$0f00,d3
cmp.w    d2,d3
beq.s    redready
bgt.s    addred
subred:
sub.w    #0100,d0    ; - red
bra.s    redready
addred:
add.w    #0100,d0    ; + red
redready:
move.w     d0,OldColour
draw:
move.w     d0,(a1)
rts

;-----------------------------------------------------------------------------
; Takes a random colour by messing up the horizontal position of the
; electronic brush. It's not a great routine, but it works for
; getting ‘pseudo-random’ values.
;----------------------------------------------------------------------------

newcol:
move.w     NewRandomColour(pc),OldColour        

move.b     $05(a6),d1    ; $dff006 - for RANDOM colour...
muls.w    #$71,d1
eor.w    #$ed,d1
muls.w    $06(a6),d1    ; $dff006 - for RANDOM colour
and.w    ColourMask(PC),d1    ; selects only the colour mask bits
move.w     d1,NewRandomColour

cmp.w     OldColour(pc),d1
bne.w    smooth
add.b    #08,NewColourRandom
bra.w    smooth


ColourMask:
dc.w    $012

OldColour:        dc.w    0
ColoreNewCaso:	dc.w	0
counter:	dc.w	range

************************************************************* initcopbuf
;	crea la copperlist
************************************************************* initcopbuf

initcopbuf:
lea    copbuf,a0
move.l     #$29e1fffe,d0    ; first line wait

move.w     #NumberOfLines-1,d1
coploop:
move.l     d0,(a0)+        ; put the wait
move.l     #$01800000,(a0)+    ; colour0
add.l    #$01000000,d0        ; wait one line below
dbra    d1,coploop
rts

*************************************************************** coplist
;				COPPERLIST
*************************************************************** coplist

section    gfx,data_C

cop:
dc.w    $100,$200    ; bplcon0 - no bitplanes
copbuf:
ds.b    NumberOfLines*8    ; space for the copper effect

dc.w    $ffff,$fffe    ; End of the copperlist
end

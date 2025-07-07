
; Lesson9f3.s        In this listing, a 16*15 pixel figure, with 2
;            bitplanes, is repeatedly blitted until
;            it fills the screen (320*256 lowres 2 bitplanes).
; The timing with Wblank ensures that
; only one tile is blitted per frame.

section    bau,code

; Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:
;    Point to the first bitplane

MOVE.L    #BitPlane1,d0    ; where to point
LEA    BPLPOINTER1,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

;    Point to the second bitplane

MOVE.L    #BitPlane2,d0    ; where to point
LEA    BPLPOINTER2,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)	; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)		; Disable AGA

bsr.s    fillmem            ; fill the screen with ‘bricks’
; with the blitter.
mouse:
btst    #6,$bfe001        ; head to the left mouse button
bne.s    mouse
rts                ; exit

;     .---^---^---.
;     | |
;     | |
;     | ¯¯¯ --- |
;     _| ___ ___ l_
;    /__ `°(___)°' __\
;    \ \_/\_____/\_/ /
;     \____`---'____/
;     T`-----'T
;     l_______| xCz

fillmem:
lea    Bitplane1,a0    ; first bitplane
lea    Bitplane2,a1    ; second bitplane
lea    gfxdata1,a3    ; fig. plane 1
lea    gfxdata2,a4    ; fig. plane 2

btst    #6,2(a5) ; dmaconr
WBlit1:
btst	#6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later
move.w    #0,$64(a5)        ; BLTAMOD = 0
move.w    #38,$66(a5)        ; BLTDMOD (40-2=38), in fact each
; ‘tile’ is 16 pixels wide,
; i.e. 2 bytes, which we must subtract
; from the total width of a line,
; i.e. 40, and the result is 40-2=38!
move.w    #$0000,$42(a5)        ; BLTCON1 - we will explain this later
move.w    #$09f0,$40(a5)        ; BLTCON0 (use A+D)

moveq    #16-1,d7        ; 16 rows of blocks to reach
; vertically to the bottom, in fact
; the tiles are 15 pixels high,
; plus 1 of ‘spacing’ between one and
; the other, below each one, makes a
; footprint of 16 pixels per tile,
; therefore 256/16=16 tiles.
DoAllLines:
moveq    #20-1,d6        ; 20 blocks per line (row), in fact,
; since the tiles are 16
; pixels wide, i.e. 2 bytes, it follows that
; there can be 320/16=20 per
; horizontal line.
DoOneLineLoop:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10800,d2    ; line to wait for = $108
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
Beq.S    Waity2

; Blit the first bitplane of a tile

move.l    a0,$54(a5)        ; BLTDPT - destination (bitpl 1)
move.l    a3,$50(a5)        ; BLTAPT - source (fig1)
move.w    #(15*64)+1,$58(a5)    ; BLTSIZE - height 15 words,
; width 1 word
; To Make the First Bitplane

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

; Blit the second bitplane of a tile

move.l    a1,$54(a5)        ; BLTDPT - destination (bitpl 2)
move.l    a4,$50(a5)        ; BLTAPT - source (fig2)
move.w    #(15*64)+1,$58(a5)	; BLTSIZE - height 15 words,
; width 1 word
; To Make the First Bitplane

btst    #6,2(a5) ; dmaconr
WBlit3:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit3

addq.w    #2,a0    ; skip 1 word (16 pixels) in bitplane 1, triggering
; ‘forward’ for the next tile
addq.w    #2,a1    ; jump 1 word (16 pixels) in bitplane 2
dbra    d6,FaiUnaRigaLoop    ; and cycle until
; all 20 tiles
; in a row have been blitted.

lea	15*40(a0),a0    ; jump 15 lines in bitplane 1. Since
; we have already incremented a0 by
; addq #2,a0, we have already jumped an entire line
; before arriving here. For each loop,
; therefore, 16 lines are skipped, leaving
; a ‘strip’ between one tile and another
of blank background between one tile and the next, since the tiles
are only 15 pixels high.
lea    15*40(a1),a1    ; skip 15 lines in bitplane 2
dbra    d7,DoAllLines    ; do all 16 lines

rts

;******************************************************************************

section	cop,data_C

copperlist
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w $100,$2200		; BPLCON0 - 2 lowres bitplanes

dc.w $180,$000    ; Colour0
dc.w $182,$FED    ; Colour1
dc.w $184,$33a    ; Colour2
dc.w $186,$888    ; Colour3

BPLPOINTER1:
dc.w $e0,0,$e2,0    ;first     bitplane
BPLPOINTER2:
dc.w $e4,0,$e6,0    ;second bitplane

dc.l    $ffff,$fffe    ; end of copperlist

******************************************************************************

;    Figure, composed of 2 biplanes. width = 1 word, height = 15 lines

gfxdata1:
dc.w    %1111111111111100
dc.w	%1111111111111100
dc.w	%1100000000001100
dc.w	%1101111111111100
dc.w	%1101111111111100
dc.w	%1101111111011100
dc.w	%1101110011011100
dc.w	%1101110111011100
dc.w	%1101111111011100
dc.w	%1101111111011100
dc.w	%1101100000011100
dc.w	%1101111111111100
dc.w	%1111111111111100
dc.w	%1111111111111100
dc.w	%0000000000000000

gfxdata2:
dc.w	%0000000000000010
dc.w	%0111111111111110
dc.w	%0111111111110110
dc.w	%0111111111110110
dc.w	%0111000000010110
dc.w	%0111011111110110
dc.w	%0111011101110110
dc.w	%0111011101110110
dc.w	%0111010001110110
dc.w	%0111011111110110
dc.w	%0111011111110110
dc.w	%0111111111110110
dc.w	%0100000000000110
dc.w	%0111111111111110
dc.w	%1111111111111110

;******************************************************************************

section	gnippi,bss_C

bitplane1:
ds.b	40*256
bitplane2:
ds.b	40*256

end

;******************************************************************************

This example is a variation of the example in lesson9c2.s.
This time we have a 2-plane screen.
Our tiles are also made up of 2 planes.
The routine that performs the ‘tiling’ of the screen has the same
structure as the one in the example in lesson9c2.s, except that 2
copies are made: the first bitplane of the tile on the first bitplane of the screen and
the second bitplane of the tile on the second bitplane of the screen.
Also, just to make it more interesting, we have slowed down the routine
by adding a Vertical Blank wait loop.
In this way, the tiles are copied one every Vertical Blank, and it is
possible to see the order in which they are copied.

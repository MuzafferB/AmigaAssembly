
; Lesson 9g3.s    More tiles, but this time with an INTERLEAVED screen
;        The timing with Wblank ensures that
;        only one ROW is blitted per frame.
;        Left click to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup1.s’    ; Save Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:
MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #2-1,D1        ; number of bitplanes (here there are 2)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
; HERE IS THE DIFFERENCE COMPARED
; TO NORMAL IMAGES!!!!!!
ADD.L    #40,d0        ; + LENGTH OF A LINE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Let's point our COP
move.w    d0,$88(a5)        ; Let's start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)		; Disable AGA

bsr.s    fillmem        ; run the ‘tiling’ routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts

*****************************************************************************
; Routine che esegue la piastrellatura
*****************************************************************************

;     ________
;     (___ ___)
;     (¡ (°)(°) ¡)
;     `| ¯(··)¯ |“
;     | /¬¬\ | xCz
;     l__¯¯¯¯__!
;     ___T¯¯¯¯T___
;     / `----” ¬\
;    · ·

fillmem:
lea    Bitplane,a0    ; bitplanes
lea    gfxdata,a3    ; figure index

btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later
move.w    #0,$64(a5)        ; BLTAMOD = 0
move.w    #38,$66(a5)        ; BLTDMOD (40-2=38), in fact each
; ‘tile’ is 16 pixels wide,
; i.e. 2 bytes, which we must subtract
; from the total width of a line,
; i.e. 40, and the result is 40-2=38!
move.w    #$0000,$42(a5)		; BLTCON1 - we will explain this later
move.w    #09f0,$40(a5)        ; BLTCON0 (use A+D)

moveq    #16-1,d7		; 16 rows of blocks to get
; vertically to the bottom, in fact
; the tiles are 15 pixels high,
; plus 1 of ‘spacing’ between one and
; the other, below each one, makes a
; total of 16 pixels per tile,
; therefore 256/16=16 tiles.
DoAllLines:
moveq    #20-1,d6        ; 20 blocks per line (row), in fact,
; since the tiles are 16
; pixels wide, i.e. 2 bytes, it follows that
; there can be 320/16=20 per
; horizontal line.

; wait for the vblank once every line drawn.
WaitWblank:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10800,d2    ; line to wait for = $108
Waity1:
MOVE.L	4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
Beq.S    Waity2

FaiUnaRigaLoop:

; Blit the first bitplane of a tile

move.l    a0,$54(a5)        ; BLTDPT - destination (bitpl 1)
move.l    a3,$50(a5)        ; BLTAPT - source (fig1)
move.w    #(2*15*64)+1,$58(a5)    ; BLTSIZE - height: 2 planes
; 15 lines high
; 1 word wide

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2


addq.w    #2,a0    ; skip 1 word (16 pixels) in bitplane 1, triggering
; ‘forward’ for the next tile
dbra    d6,FaiUnaRigaLoop    ; and cycle until
; all 20 tiles
; in a row have been blitted.

lea    40+2*15*40(a0),a0
; By repeatedly using ADDQ #2,A0, we have incremented
; the pointer a0 until it exceeds the last word
; of line 0, plane 1. We have now reached
; the first word of line 0, plane 2.
; Now we want to move to the first word
; of line 16, plane 1. We must therefore
; add 40 to A0 to move to the first
; word of line 1, plane 1, and then 2*15*40
; to move where we want.

dbra    d7,FaiTutteLeRighe    ; do all 16 lines
rts

*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

; HERE IS A DIFFERENCE COMPARED TO
; THE NORMAL IMAGES!!!!!!
dc.w    $108,40        ; MODULE VALUE = 2*20*(2-1)= 40
dc.w    $10a,40        ; BOTH MODULES HAVE THE SAME VALUE.

dc.w    $100,$2200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000

dc.w $180,$000    ; Colour0
dc.w $182,$FED    ; Colour1
dc.w $184,$33a    ; Colour2
dc.w $186,$888    ; Colour3

dc.w    $FFFF,$FFFE    ; End of copperlist

;    Figure, composed of 2 biplanes. width = 1 word, height = 15 lines

**************************************************************************
; Tile figure

; This is the same figure as in the example lezioine9f3.s, except that there
; it was in normal format. To put it in interleaved format,
; the lines have been ‘mixed up’.

gfxdata:
dc.w    %1111111111111100    ; line 0, plane 1
dc.w    %0000000000000010    ; line 0, plane 2
dc.w    %1111111111111100	; line 1, plane 1
dc.w    %0111111111111110    ; line 1, plane 2
dc.w    %1100000000001100    ; line 3, plane 1
dc.w    %0111111111110110	; row 3, plane 2
dc.w    %1101111111111100
dc.w    %0111111111110110
dc.w    %1101111111111100
dc.w    %0111000000010110
dc.w	%1101111111011100
dc.w	%0111011111110110
dc.w	%1101110011011100
dc.w	%0111011101110110
dc.w	%1101110111011100
dc.w	%0111011101110110
dc.w	%1101111111011100
dc.w	%0111010001110110
dc.w	%1101111111011100
dc.w	%0111011111110110
dc.w	%1101100000011100
dc.w	%0111011111110110
dc.w	%1101111111111100
dc.w	%0111111111110110
dc.w	%1111111111111100
dc.w	%0100000000000110
dc.w	%1111111111111100
dc.w	%0111111111111110
dc.w    %0000000000000000    ; line 15, plane 1
dc.w    %1111111111111110    ; line 15, plane 2

*****************************************************************************

section	gnippi,bss_C

bitplane:
ds.b	2*40*256	; 2 bitplanes

end

*****************************************************************************

In this example, we find the tiles again, this time in interleaved format.
First, note how the tile figure is arranged in memory.
In the example lesson9f3.s, we had two separate bitplanes.
Here, however, the lines are mixed together.
As for the routine, the tiles are copied with a single
blit, whereas in lesson9f3.s we had to do one blit for each bitplane.
The height of the blit is equal to the product of the height of the figure
(15 lines) and the number of bitplanes (2), as we explained in the lesson.
The calculation of the destination address is also (naturally) different
(the source is fixed and therefore always remains the same). The tiles on the
same row are always spaced one word apart, as is logical since
the interleaved pattern differs only in the arrangement of the rows.
The difference is found after the inner loop, when we have reached the end
of a horizontal row of tiles and must start the next one.
If we indicate with Y the row at which we start bleeting, we must move
to row Y+16.
In the internal loop, we increase the pointer by 2 each time, moving
one word to the right. At the end of the loop, we find ourselves immediately after
the last word of the current line, i.e. on the first word of plane 2
of line Y. First, we must move to plane 1 of line Y+1,
adding 40 (number of bytes occupied by ONE plane of ONE line).
At this point, we need to move down another 15 lines.
Since a plane of one line occupies 40 bytes, and we have 2 planes for each
line, we need to add 2*15*40.
Of course, we can add both quantities at once
by doing a LEA 40+15*2*40(A1),A1.

Let's summarise the situation with the following figure:

- At the beginning of the internal loop, the pointer points to the word indicated with (0).
- At the end of the internal loop, the pointer points to the word indicated with (1).
- Adding 40, the pointer points to the word indicated by (2).
- Adding 2*40*15, we move down 15 lines and the pointer points to
the word indicated by (3), which is the word we wanted.
(There are 2*40 bytes between each line; if we had added only 2*40
,
 we would have moved from word (2) to word (2')).

line Y plane 1    | (0) | | | . . . | |
line Y plane 2	| (1) | | | . . . | |
line Y+1 plane 1    | (2) | | | . . . | | \
line Y+1 plane 2    | | | | . . . | | |
line Y+1 plane 1    | (2') | | | . . . | | |
line Y+1 plane 2    | | | | . . . | | |
|.
 |
| 15 lines.
 |
|.
 |
|
/
line Y+16 plane 1    | (3) | | | . . . | |
line Y+16 plane 2    | | | | . . . | |


; Lesson 9c2.s        In this listing, a 16*15 pixel image, with
; only one bitplane, is repeatedly blitted until
; it fills the screen (320*256 lowres 1 bitplane).

section    bau,code

;	Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup1.s’    ; Save Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:
;    Point to the first bitplane

MOVE.L    #BitPlane1,d0    ; where to point
LEA    BPLPOINTER1,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

bsr.s    fillmem            ; fill the screen with ‘bricks’
; with the blitter.
mouse:
btst    #6,$bfe001        ; check the left mouse button
bne.s    mouse

rts                ; exit


;*****************************************************************************
; This routine fills the screen with tiles.
 
;*****************************************************************************

;     .-----------.
;     | ¬ |
;     | |
;     | ___ |
;     _j / __\ l_
;     /,_ / \ __ _,\
;    .\¬| / \__¬ |¬/....
;     ¯l_\_o__/° )_|¯ :
;     / ¯._.¯¯ \ :
;    .--\_ -^---^- _/--. :
;    | `---------“ | :
;    | T ° T | :
;    | `-.--.--.-” | .:
;    l_____| | l_____j
;     T `--^--' T
;     l___________|
;     / _ T
;     / T | xCz
;     _\______|____l_
;    (________X______)

fillmem:
lea    Bitplane1,a0    ; destination bitplane address
lea    gfxdata1,a3    ; fig. tile 16*15

btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$ffffffff,$44(a5)    ; BLTAFWM/LWM - we will explain these later
move.w    #0,$64(a5)        ; BLTAMOD = 0, because the
; tile image is NOT contained within
; a larger screen and therefore
; the lines that compose it are
; consecutive in memory.
move.w    #38,$66(a5)		; BLTDMOD (40-2=38), because each
; ‘tile’ is 16 pixels wide,
; i.e. 2 bytes, which we must subtract
; from the total width of a line,
; i.e. 40, and the result is 40-2=38!
move.w    #$0000,$42(a5)        ; BLTCON1 - no special modes
move.w    #$09f0,$40(a5)        ; BLTCON0 (use A+D)

moveq    #16-1,d2		; 16 rows of tiles to reach
; vertically to the bottom, in fact
; the tiles are 15 pixels high,
; plus 1 of ‘spacing’ between one and
; the other, below each one, makes a
; total of 16 pixels per tile,
; therefore 256/16=16 tiles.
DoAllLines:
moveq    #20-1,d0        ; 20 tiles per line (row),
; in fact, since the tiles are
; 16 pixels wide, i.e. 2 bytes,
; it follows that there can be
; 320/16=20 per horizontal line.
DoOneLineLoop:
move.l    a0,$54(a5)        ; BLTDPT - destination (bitpl 1)
move.l    a3,$50(a5)        ; BLTAPT - source (fig1)
move.w    #(15*64)+1,$58(a5)    ; BLTSIZE - height 15 words,
; width 1 word (16 pix.)
btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

addq.w    #2,a0    ; skip 1 word (16 pixels) in bitplane 1, triggering
; ‘forward’ for the next tile

dbra    d0,FaiUnaRigaLoop    ; and cycle until
; all 20 tiles
; in a row have been blitted.

lea    15*40(a0),a0    ; skip 15 lines in bitplane 1. Since
; we have already incremented a0 by
; addq #2,a0, we have already skipped an
; entire line before arriving here. For each loop,
; therefore, 16 lines are skipped, leaving
; a ‘strip’ of blank background between one tile and the next
; since the tiles
; are only 15 pixels high.
dbra    d2,FaiTutteLeRighe    ; do all 16 lines
rts    

;*****************************************************************************

section	cop,data_C

copperlist
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w	$92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w $100,$1200        ; BPLCON0 - 1 lowres bitplane

dc.w $180,$126    ; Colour0
dc.w $182,$0a0    ; Colour1

BPLPOINTER1:
dc.w $e0,0,$e2,0    ;first bitplane

dc.l    $ffff,$fffe    ; end of copperlist

;*****************************************************************************

;    Figure, composed of 1 biplane. width = 1 word, height = 15 lines

gfxdata1:
dc.w    %1111111111111100    ; 1
dc.w    %1111111111111100    ; 2
dc.w    %1100000000001100	; 3
dc.w	%1100000000001100
dc.w	%1100011110001100
dc.w	%1100111111001100
dc.w	%1100110011001100
dc.w	%1100110011001100
dc.w	%1100111111001100
dc.w	%1100011110001100
dc.w	%1100000000001100
dc.w    %1100000000001100
dc.w    %1111111111111100
dc.w    %1111111111111100
dc.w    %0000000000000000    ; 15

section	gnippi,bss_C

bitplane1:
ds.b	40*256

end

;*****************************************************************************

In this example, we use a small figure (16 pixels wide and 15 lines high)
as a ‘tile’ to ‘tile’ the screen. In practice, we copy the source figure
many times to cover the entire screen. Since the
screen is 320 pixels wide and the tile is 16, we draw
320/16=20 tiles. The screen is 256 pixels high and the
tile is 15 pixels high. Since we leave a row of empty pixels between two rows of
tiles, there are 256/(15+1)=16 tiles in each column.
Each tile is copied using a blit. The dimensions of the
blit are 1 word (16 pixels) in width and 15 rows in height.
The source module is 0, because the source does NOT belong to
a screen, and the rows that make up the tile pattern are
arranged consecutively in memory. The destination, on the other hand, is inside a
screen 20 words wide, and therefore the module is calculated according to the formula
seen in the lesson.
The instructions that execute the bitmap are located within two loops,
 one inside the other. The inner loop repeats the bitmap 20 times,
so as to draw a horizontal row of tiles. The outer loop
repeats the inner loop 16 times, so as to draw a total of
16 rows of tiles. Between one bleed and another, 
the destination address naturally varies so that the tile is drawn each time
in a different place on the screen. For this reason, we will place the pointer 
to the destination in a register that we will modify during the routine.
In the inner loop, we draw the tiles that form a horizontal row one at a time.
 Then, after drawing a tile, we must move the
pointer to the destination of a word to the right, i.e. we must make it
point to the next word in memory. This is equivalent to adding 2
to the address (one word = 2 bytes). This way, when we reach the last
iteration of the internal loop, the pointer to the destination points to the last 
word of the row. After printing the tile (which is the last
in the horizontal row), 2 is added to the pointer again, making it point
to the first word of the next row. Instead, we want to start printing
another row of tiles. Since a row of tiles is 16 lines high,
we need to draw the next row 16 lines below the one
we just finished. However, as we said, our pointer points
one line below the current one. Therefore, we must make it point 
another 15 lines lower. This is equivalent to adding 15*40 to the address,
because each line occupies 40 bytes (20 words), which is done at each
iteration of the outer loop.


Before starting the first iteration of the inner loop
the pointer points here.

|
V

line Y        | | | |
line Y+1    | | | |
..
         ^
|

after the last iteration of the internal cycle
the pointer points to this word.

To print the new row, it must point to THIS word
To get it there, we must move it down 15 lines
adding 40 for each line.

|
V

row Y+16    | | | |





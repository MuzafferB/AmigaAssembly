
; Lesson 9h3.s    Let's display an image one column of pixels at a time
;        Right click to execute the blit, left click to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA	BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0        ; + LENGTH OF A PLANE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1        ; if not, wait

bsr.s    Show        ; run the routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts


; ************************ THE ROUTINE THAT DISPLAYS THE FIGURE *******************

;     .øØØØØØø.
;     |¤¯_ _¬¤|
;     _|___ ___|_
;     (_| (·T.) l_)
;     / ¯(_)¯ \
;     /____ _ ____\
;	 // Y Y \\
;     //__/\_____/\__\\ xCz
;    (_________________)

Display:

; initial pointer values

lea    picture,a0        ; point to the beginning of the figure
lea    bitplane,a1        ; point to the beginning of the first bitplane

moveq    #20-1,d7        ; execute for each ‘column’ of words.
; the screen is 20 words wide, so
; there are 20 columns.

DoAllWords:
moveq    #16-1,d6        ; 16 pixels for each word.
move.w    #%1000000000000000,d0    ; value of the mask at the start of the
; internal loop. Only passes the
; leftmost pixel of the word.
DoOneWord:

; wait for the vblank so as to draw a column of pixels at each
; frame.

WaitWblank:
CMP.b    #$ff,$dff006        ; vhposr - wait for line 255
bne.s    WaitWblank
Wait:
CMP.b    #$ff,$dff006        ; vhposr - still line 255?
beq.s    Wait

moveq    #3-1,d5            ; repeat for each plane

move.l    a0,a2            ; copy the pointers to 2 other registers
move.l    a1,a3            ; this is because inside the loop
; that draws the various planes, they must
; be modified to point from one plane
; to another.

MakeAPlane:
btst    #6,2(a5)        ; wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
move.w    #$ffff,$44(a5)        ; BLTAFWM - passes all bits
move.w    d0,$46(a5)        ; Load the mask value into
; the BLTALWM
; register load the pointers

move.l    a2,$50(a5)        ; bltapt
move.l    a3,$54(a5)        ; bltdpt

; For both the source and destination, we bleak a word belonging
; to a 20-word wide screen. The module is therefore 2*(20-1)=38=$26.
; Since the two registers have consecutive addresses, a single
; instruction can be used instead of two:

move.l #$00260026,$64(a5)	; bltamod and bltdmod 

; we bleak a ‘column’ of words 256 lines high (the entire screen)

move.w    #(256*64)+1,$58(a5)    ; bltsize
; height 256 lines
; width 1 word

lea    40*256(a2),a2        ; point to the next source plane
lea    40*256(a3),a3        ; point to the next destination plane

dbra    d5,FaiUnPlane        ; repeat for all planes

asr.w    #1,d0            ; calculate the mask for the next
; blit. Each time, pass one
; more bit than the previous time
; .

dbra    d6,FaiUnaWord        ; repeat for all pixels

addq.w    #2,a0            ; point to the next word
addq.w	#2,a1            ; point to the next word

dbra    d7,DoAllWords    ; repeat for all words

btst    #6,$02(a5)    ; dmaconr - wait for the blitter to finish
waitblit2:
btst    #6,$02(a5)
bne.s    waitblit2

rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0		; BplCon2
dc.w    $108,0        ; MODULE VALUE = 0
dc.w    $10a,0        ; BOTH MODULES AT THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

PICTURE:
incbin    ‘assembler2:sorgenti6/amiga.raw’
; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.

;****************************************************************************

section	gnippi,bss_C

bitplane:
ds.b	40*256	; 3 bitplanes
ds.b	40*256
ds.b	40*256
end

;****************************************************************************

In this example, we see a new effect obtained thanks to a mask.
We draw an image on the screen one column of pixels at a time, starting
from the right. In practice, we have to copy the image onto the screen one ‘column’
of pixels at a time. However, the minimum width of a blit is one
word, equal to 16 pixels. Therefore, if we simply copied the image, we could only
copy groups of 16 pixels. Fortunately, however, there are masks.
By making blits one word wide, both masks apply to the
blitted word. However, we only need one, for example BLTALWM (it would
be the same if we used BLTAFWM). The trick is this:
we copy the same 1-word column 16 times, each time in the same position
on the screen, and each time we change the mask so that we see one
more column of pixels.
In practice, the first time we make the copy with the mask set to
%1000000000000000 so that only the first column of pixels is visible.
The second blit occurs in the same position as the previous one, thus
overwriting what we drew the first time. As a mask, we use
the value %1100000000000000, so that only the first 2 columns
of pixels are visible. The third time, we use %1110000000000000 as the mask and draw
the first 3 columns of pixels, and so on. The 16th time, we use 
%1111111111111111 as a mask so that we draw all 16 columns of pixels
that make up the word column. At this point, we need to start drawing
the first column of pixels of the next word column, so we move
one word to the right, both in the source and in the destination, and start again
with the mask set to %1000000000000000. Since our blits are
only one word wide, we will not overwrite the previous word column, which 
therefore remains drawn.
Note how the mask values are obtained. At the beginning,
the starting value (%1000000000000000) is placed in register D0. This register
is copied to BLTALWM, so that the first bleed only passes
the first column of pixels. After the bleed, an ASR #1,D0 is executed.
This instruction, as you know, shifts the contents of register D0 to the right.
 Furthermore (unlike LSR), it preserves the sign, i.e.
it inserts a bit from the left with the same value as the bit
furthest to the left (i.e. the sign bit) before the shift. In this case,
the sign bit is 1, so another 1 is inserted from the left. In this way, 
the D0 register takes on the value %1100000000000000. This value is used
as a mask for the second bit shift, and then another ASR is executed
which brings D0 to the value %1110000000000000. This mechanism is repeated
at each iteration, generating all the values of the mask.
For further clarification on ASR, please refer to lesson 6800000000000000000000000000000000000000000000

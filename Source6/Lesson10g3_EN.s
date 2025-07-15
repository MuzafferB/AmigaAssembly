
; Lesson 10g3.s    Curtain effect
;        Right click to view the image, left click to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
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
move.l	#COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1        ; if not, wait

moveq    #16-1,d6	; repeat for each column of pixels

move.w    #%1000000000000000,d5    ; mask value at the beginning.
; Passes only the pixel furthest
; to the left of the word.

MostraLoop:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L	D2,D0        ; wait for line $130
BNE.S    Waity1

bsr.s    BlitAnd        ; draw the figure

asr.w    #1,d5            ; calculate the mask for the next
; bitmap. Pass one
; more bit each time than the
; previous time.

dbra    d6,ShowLoop


mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

moveq    #16-1,d6    ; repeat for each column of pixels
ClearLoop:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L	D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130
BNE.S    Waity2

lsr.w    #1,d5            ; calculate the mask for the next
; bitmap. Pass one
; more bit each time than the
; previous time.

bsr.s	BlitAnd			; disegna la figura

dbra	d6,CancellaLoop

fine:
rts


;****************************************************************************
; This routine performs an AND between a figure read through channel A
; and a constant value loaded into BLTBDAT. The result is drawn
; on the screen.
; D5 - contains the constant value (mask) to be loaded into BLTBDAT
;****************************************************************************

;     ____
;     .“_ _`.
;     |/ \/ \|
;     || oo ||
;     || ||
;     _|\_/\_/|_
;    (|-.____.-|)
;     `._ -- _.”
;     |_ _|
;     `'

BlitAnd:
lea    bitplane+100*40+4,a0    ; destination pointer in a0
lea    figure,a1        ; source pointer

moveq    #3-1,d7            ; repeat for each plane
PlaneLoop:
btst    #6,2(a5)
WBlit2:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit2

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word


move.w    d5,$72(a5)        ; writes mask to BLTBDAT
move.l    #$09C00000,$40(a5)    ; BLTCON0 uses channels A and D
;     D=A AND B
; BLTCON1 (no special mode)
move.l    #00000004,$64(a5)    ; BLTAMOD=0
; BLTDMOD=40-36=4 as usual

move.l    a1,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.w    #(64*45)+18,$58(a5)    ; BLTSIZE (start the blitter!)

lea    2*18*45(a1),a1        ; point to the next source plane
; each plane is 18 words wide and
; 45 lines high

lea    40*256(a0),a0        ; point to the next destination plane
dbra    d7,PlaneLoop

rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; MODULE VALUE 0
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
dc.w    $0188,$999	
; color4
dc.w    $018a,$232    ; color5
dc.w    $018c,$777    ; color6
dc.w    $018e,$444    ; color7

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; These are the data that make up the bob figure.
; The bob is in normal format, 288 pixels wide (18 words)
; 45 lines high and made up of 3 bitplanes

Figure:
incbin    copmon.raw

;****************************************************************************

section	gnippi,bss_C

BITPLANE:
ds.b	40*256	; 3 bitplanes
ds.b	40*256
ds.b	40*256

end

;****************************************************************************

In this example, we will create a ‘curtain’ effect, i.e. we will draw a figure
as if it were a Venetian blind being opened or closed. It is easier to
look at it than to understand what it is by rereading the explanation!
This effect is achieved using a technique similar to that used
in the lesson9h3.s example to draw an image one column at a time.
To achieve the effect, we perform an AND operation between the figure and a mask value
that selects only certain columns of pixels. Unlike the example in
lesson9h3, we cannot use BLTAFWM/BLTALWM to contain the mask
because we need to apply the mask to all the words in the figure, not
just the first and last ones. To do this, we perform an AND operation between channel
A and channel B, keep channel B disabled, and use BLTBDAT as the
mask.
The mask is varied so as to progressively show the entire
image, and then varied again so as to gradually erase
the entire image.

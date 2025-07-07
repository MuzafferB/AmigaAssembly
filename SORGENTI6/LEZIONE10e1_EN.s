
; Lesson 10e1.s    Normal blitting with copper monitor
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

********************************** *******************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ	#3-1,D1        ; number of bitplanes (here there are 3)
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
move.l    #COPPERLIST,$80 (a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

move.w    #0,ogg_x
move.w    #0,ogg_y

mouse:

addq.w    #1,ogg_y
cmp.w    #130,ogg_y
beq.s    end

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$0f400,d2    ; line to wait for = $F4
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $F4
BNE.S    Waity1

;     \\\|||///
;     . =======
;    / \| O O |
;    \ / \`___'/
;     # _| |_
;    (#) ( )
;     #\//|* *|\\
;     #\/( * )/
;     # =====
;     # ( U )
;     # || ||
;    .#---‘| |`----.
;    `#----’ `-----'

move.w    #$f00,$180(a5)        ; change the background colour
bsr.s    DrawObject        ; draw the bob

btst    #6,2(a5)
WBlit_coppermonitor:
btst    #6,2(a5)     ; wait for the blitter to finish
bne.s    wblit_coppermonitor

move.w    #$000,$180(a5)        ; restore the black background

bra.s    mouse

end:
rts


;****************************** **********************************************
; This routine draws the BOB at the coordinates specified in the variables
; X_OGG and Y_OGG.
;****************************************************************************

DrawObject:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line consists of
; 40 bytes
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d0    ; X coordinate
move.w    d0,d1        ; copy
and.w    #000f,d0    ; select the first 4 bits because they must
; be inserted in the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #$09f0,d0    ; ...just enough to fit into the BLTCON0 register
lsr.w    #3,d1        ; (equivalent to a division by 8)
; round to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; x e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1    ; exclude bit 0 of
add.w    d1,a0		; add to the bitplane address, finding
; the correct destination address

lea    figure,a1    ; source pointer
moveq    #3-1,d7        ; repeat for each plane
PlaneLoop:
btst    #6,2(a5)
WBlit2:
btst    #6,2(a5)		 ; wait for the blitter to finish
bne.s    wblit2

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word


move.w    d0,$40(a5)        ; BLTCON0 (use A+D)
move.w    #0000,$42(a5)        ; BLTCON1 (no special mode)
move.l    #00000004,$64(a5)    ; BLTAMOD=0
; BLTDMOD=40-36=4 as usual

move.l    a1,$50(a5)        ; BLTAPT (fixed to the source image)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.w    #(64*45)+18,$58(a5)	; BLTSIZE (start blitter!)

lea    2*18*45(a1),a1        ; point to the next source plane
; each plane is 18 words wide and
; 45 lines high

lea    40*256(a0),a0        ; point to the next destination plane
dbra    d7,PlaneLoop

rts

OGG_Y:        dc.w    0    ; the Y of the object is stored here
OGG_X:        dc.w    0    ; the X of the object is stored here
MOUSE_Y:    dc.b    0    ; the Y of the mouse is stored here
MOUSE_X:    dc.b    0    ; the X of the mouse is stored here

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; MODULE VALUE 0
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
dc.w    $0188,$999	; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist

;******************************* *********************************************

; These are the data that make up the bob figure.
; The bob is in normal format, 288 pixels wide (18 words)
; 45 lines high and made up of 3 bitplanes

Figure:
incbin    copmon.raw

;*********** *****************************************************************

section	gnippi,bss_C

BITPLANE:
ds.b    40*256    ; 3 bitplanes
ds.b    40*256
ds.b    40*256

end

;****************************************************************************

In this example, we use the blitter to copy a rectangle
18 words wide, 45 lines high and consisting of 3 bitplanes in normal format
(so 3 separate blits are required). Using the ‘copper monitor’
we measure the speed of the operation. The copy starts when the electronic brush
reaches line $f4. At this point, just before starting
the copy, we change COLOUR 0. When the copy is finished, we return the background
to its initial colour (black).
You can see from this routine how the size of the blit
affects the speed: try changing the width and/or height and
observe the results. The ‘copper monitor’ is handy, isn't it?

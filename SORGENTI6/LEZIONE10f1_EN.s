
; Lesson 10f1.s    Many BOBs with a ‘fake’ background. There is an “error” to fix!
;        Left click to exit.

SECTION    bau,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


; edge constants.

Lowest_Floor    equ    200    ; bottom edge
Right_Side    equ    287    ; right edge    

START:

; point the bitplanes
MOVE.L    #BITPLANE1,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0    ; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

;    Point to the fourth bitplane (the background)

LEA    BPLPOINTERS,A0        ; COP pointers
move.l    #FakeBackground,d0        ; background address
move.w    d0,30(a0)        ; the background is bitplane 4
swap    d0
move.w    d0,26(a0)        ; write high word

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W	#DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L	#$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0		; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w    ClearScreen        ; clear the screen

lea    Object_1,a4        ; address of first object
moveq    #6-1,d6			; 6 objects

Ogg_loop:
bsr.s    MoveObject        ; moves the bob
bsr.w    DrawObject        ; draws the bob

addq.l    #8,a4            ; points to the next object

dbra    d6,Ogg_loop

btst    #6,2(a5)
WBlit_coppermonitor:
btst    #6,2(a5)
bne.s    WBlit_coppermonitor

move.w    #$aaa,$180(a5)        ; copper monitor: grey colour

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:

rts


;****************************************************************************
; This routine moves a bob, checking that it does not go beyond the edges
; A4 - points to the data structure containing the position and speed
; of the bob
;****************************************************************************

MoveObject:
move.w    (a4),d0            ; X position
move.w    2(a4),d1        ; Y position
move.w    4(a4),d2        ; dx (X speed)
move.w	6(a4),d3        ; dy (Y speed)
add.w    d2,d0            ; x = x + dx
add.w    d3,d1            ; y = y + dy

btst    #15,d1            ; check upper edge (Y=0)
beq.s    UO_NoBounce4        ; if Y is negative...
neg.w    d1            ; ... bounce
neg.w    d3            ; reverse direction of movement
UO_NoBounce4:

cmp.w	#Lowest_Floor,d1    ; check lower edge
blt.s    UO_NoBounce1

neg.w    d3            ; change the sign of the velocity dy
; reversing the direction of motion
move.w	#Lowest_Floor,d1    ; restart from the edge
UO_NoBounce1:

cmp.w    #Right_Side,d0        ; check right edge
blt.s    UO_NoBounce2        ; if it passes the right edge...
sub.w	#Right_Side,d0        ; distance from the edge
neg.w    d0            ; reverse the distance
add.w    #Right_Side,d0        ; add edge coordinate
neg.w    d2            ; reverse direction of motion
UO_NoBounce2:
btst    #15,d0            ; check left edge (X=0)
beq.s    UO_NoBounce3        ; if X is negative...
neg.w    d0            ; .. bounce
neg.w    d2            ; reverse direction of movement
UO_NoBounce3:
move.w    d0,(a4)            ; update position and speed
move.w	d1,2(a4)
move.w	d2,4(a4)
move.w	d3,6(a4)

rts


;****************************************************************************
; This routine draws a BOB.
; A4 - points to the data structure containing the position and speed
; of the bob
;****************************************************************************

;     |\__/,| (`\
;     _.|o o |_ ) )
;     ---(((---(((---------

DrawObject:
lea    BITPLANE1,a0    ; bitplane address
move.w    2(a4),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line occupies 40 bytes

add.l    d0,a0        ; add Y offset

move.w    (a4),d0        ; X coordinate
move.w    d0,d1        ; copy
and.w    #000f,d0    ; select the first 4 bits because they must
; be inserted in the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #$0FCA,d0    ; ...just right to fit into the BLTCON0 register
lsr.w    #3,d1        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; x e.g.: a 16 as a coordinate becomes
; byte 2
and.l    #$0000fffe,d1	; exclude bit 0 of the
add.l    d1,a0        ; add the X offset, finding the address
; of the destination

lea    Ball_Bob,a1        ; pointer to the figure
lea    Ball_Mask,a2        ; pointer to the mask
moveq    #3-1,d7            ; bitplane counter

DrawLoop:
btst #6,2(a5)
WBlit2:
btst	#6,2(a5)
bne.s    WBlit2

move.w    d0,$40(a5)        ; BLTCON0 - write shift value
move.w    d0,d1            ; copy BLTCON0 value,
and.w    #$f000,d1        ; select shift value..
move.w    d1,$42(a5)        ; and write it to BLTCON1 (for channel B)

move.l    #$ffff0000,$44(a5)    ; BLTAFWM and BLTLWM

move.w    #$FFFE,$64(a5)        ; BLTAMOD
move.w    #$FFFE,$62(a5)        ; BLTBMOD

move.w    #40-6,$66(a5)        ; BLTDMOD
move.w    #40-6,$60(a5)        ; BLTCMOD

move.l    a2,$50(a5)        ; BLTAPT - mask pointer
move.l    a1,$4c(a5)        ; BLTBPT - figure pointer
move.l    a0,$48(a5)        ; BLTCPT - background pointer
move.l    a0,$54(a5)		; BLTDPT - bitplane pointer

move.w    #(31*64)+3,$58(a5)    ; BLTSIZE - height 31 lines
; width 3 words (48 pixels).

add.l    #4*31,a1        ; next image plane address
add.l	#40*256,a0        ; address of next destination plane
dbra    d7,DrawLoop



rts


;****************************************************************************
; This routine clears the screen using the blitter.
;****************************************************************************

ClearScreen:
moveq    #3-1,d7            ; 3 bitplanes
lea    BITPLANE1,a0        ; screen address

canc_loop:
btst    #6,2(a5)
WBlit3:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit3

move.l    #$01000000,$40(a5)    ; BLTCON0 and BLTCON1: Clear
move    #$0000,$66(a5)        ; BLTDMOD=0
move.l    a0,$54(a5)		; BLTDPT
move.w    #(64*256)+20,$58(a5)    ; BLTSIZE (start blitter !)
; clear entire screen

add.l    #40*256,a0        ; next plane destination address
dbra    d7,canc_loop
rts


; object data
; these are the data structures that contain the speed and position of the bobs.
; each data structure consists of 4 words containing, in order:
; X POSITION, Y POSITION, X SPEED, Y SPEED

Object_1:
dc.w	32,53        ; x / y - position
dc.w    -3,1        ; dx / dy - speed

Object_2:
dc.w    132,62        ; x / y - position
dc.w    2,-1        ; dx / dy - speed

Object_3:
dc.w    232.42        ; x / y - position
dc.w    3.1        ; dx / dy - speed

Object_4:
dc.w    2.20        ; x / y - position
dc.w    -5.1        ; dx / dy - speed

Object_5:
dc.w    60,80        ; x / y - position
dc.w    6,1        ; dx / dy - speed

Object_6:
dc.w    50,75        ; x / y - position
dc.w    -5,1        ; dx / dy - speed

;****************************************************************************

SECTION	MY_COPPER,CODE_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0		; BplCon1
dc.w    $104,0        ; BplCon2

dc.w    $108,0        ; MODULE
dc.w    $10a,0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000
dc.w $ec,$0000,$ee,$0000

dc.w    $180,$000    ; color0 - background
dc.w    $190,$000

dc.w    $182,$0A0            ; colours from 1 to 7
dc.w    $184,$040
dc.w    $186,$050
dc.w    $188,$061
dc.w    $18A,$081
dc.w    $18C,$020
dc.w    $18E,$6F8

dc.w    $192,$0A0        ; colours from 9 to 15
dc.w    $194,$040        ; these are the same values
dc.w    $196,$050        ; loaded into registers 1 to 7
dc.w    $198,$061
dc.w    $19a,$081
dc.w    $19c,$020
dc.w    $19e,$6F8

dc.w    $190,$345    ; colour 8 - 1 pixel of the background

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

dc.w    $8007,$fffe    ; wait for line $80
dc.w    $100,$4200    ; bplcon0 - 4 lowres bitplanes
; activate bitplane 4 (background)

; this space displays the background

dc.w    $e007,$fffe    ; wait for line $e0
dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; Figura Bob
Ball_Bob:
DC.W $0000,$0000,$0000,$0000,$0000,$0000,$003F,$8000	; plane 1
DC.W $00C1,$E000,$017C,$E000,$02FE,$3000,$05FF,$5400
DC.W $07FF,$1800,$0BFE,$AC00,$03FF,$1A00,$0BFE,$AC00
DC.W $11FF,$1A00,$197D,$2C00,$0EAA,$1A00,$1454,$DC00
DC.W $0E81,$3800,$0154,$F400,$02EB,$F000,$015F,$D000
DC.W $00B5,$A000,$002A,$8000,$0000,$0000,$0000,$0000
DC.W $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
DC.W $0000,$0000,$0000,$0000,$0000,$0000

DC.W $000F,$E000,$007F,$FC00,$01FF,$FF00,$03FF,$FF80	; plane 2
DC.W $07C1,$FFC0,$0F00,$FFE0,$1E00,$3FF0,$3C40,$5FF8
DC.W $3CE0,$1FF8,$7840,$2FFC,$7800,$1FFC,$7800,$2FFC
DC.W $F800,$1FFE,$F800,$2FFE,$FE00,$1FFE,$FC00,$DFFE
DC.W $FE81,$3FFE,$FF54,$FFFE,$FFEB,$FFFE,$7FFF,$FFFC
DC.W $7FFF,$FFFC,$7FFF,$FFFC,$3FFF,$FFF8,$3FFF,$FFF8
DC.W $1FFF,$FFF0,$0FFF,$FFE0,$07FF,$FFC0,$03FF,$FF80
DC.W $01FF,$FF00,$007F,$FC00,$000F,$E000

DC.W $000F,$E000,$007F,$FC00,$01E0,$7F00,$0380,$0F80	; plane 3
DC.W $073E,$0AC0,$0CFF,$0560,$198F,$C2F0,$3347,$A0B8
DC.W $32EB,$E158,$6647,$D0AC,$660B,$E05C,$4757,$D0AC
DC.W $C7AF,$E05E,$A7FF,$D02E,$C1FF,$E05E,$A3FF,$202E
DC.W $D17E,$C05E,$E0AB,$002E,$D014,$005E,$6800,$00AC
DC.W $7000,$02DC,$7400,$057C,$2800,$0AF8,$3680,$55F8
DC.W $1D54,$AAF0,$0EAB,$55E0,$0754,$ABC0,$03EB,$FF80
DC.W $01FE,$FF00,$007F,$FC00,$000F,$E000

; Bob mask
Ball_MASK:
DC.W $000F,$E000,$007F,$FC00,$01FF,$FF00,$03FF,$FF80
DC.W $07FF,$FFC0,$0FFF,$FFE0,$1FFF,$FFF0,$3FFF,$FFF8
DC.W $3FFF,$FFF8,$7FFF,$FFFC,$7FFF,$FFFC,$7FFF,$FFFC
DC.W $FFFF,$FFFE,$FFFF,$FFFE,$FFFF,$FFFE,$FFFF,$FFFE
DC.W $FFFF,$FFFE,$FFFF,$FFFE,$FFFF,$FFFE,$7FFF,$FFFC
DC.W $7FFF,$FFFC,$7FFF,$FFFC,$3FFF,$FFF8,$3FFF,$FFF8
DC.W $1FFF,$FFF0,$0FFF,$FFE0,$07FF,$FFC0,$03FF,$FF80
DC.W $01FF,$FF00,$007F,$FC00,$000F,$E000


;****************************************************************************

; Sfondo 320 * 100 1 Bitplane, raw normale.

SfondoFinto:
incbin	‘sfondo320*100.raw’

;****************************************************************************

SECTION	bitplane,BSS_C
BITPLANE1:
ds.b	40*256
BITPLANE2:
ds.b	40*256
BITPLANE3:
ds.b	40*256

end

;****************************************************************************

In this example, we see six bobs moving on a background.
We use the fake background trick. However, since the six bobs are all drawn
in the same planes, we still have to blend them using the
bitplane mask and ‘cookie cut’ technique, otherwise they would not overlap
correctly. The fake background technique allows us to avoid
saving and restoring the background, since the background is made up
of only zeros. To delete the bobs drawn in the old positions, it is 
therefore sufficient to delete the planes dedicated to the bobs before starting 
to redraw them.
To move and draw the bobs, we use parametric routines that are
able to handle all the bobs we want. Instead of passing the parameters
through the CPU registers, we use ‘data structures’, i.e.
we collect the speed and position data of each bob in contiguous addresses,
always following the same order. The address of the data structure is “passed” to the routines through the 
A4 register. In this way, the routines
know that the bob data is located at the address pointed to by A4 and at the
subsequent addresses.
As you can see when you run it, this programme does not draw the bobs correctly.
 For an explanation of the problem and the solution, see the
lesson.

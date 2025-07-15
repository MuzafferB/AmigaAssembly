
; Lesson9i4.s    BOB with ‘fake’ background
;        Left button to exit.

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
move.w    d0,30(a0)		; the background is bitplane 4
swap    d0
move.w    d0,26(a0)        ; write high word

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w	#$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
bsr.s    MoveObject        ; move the bob
bsr.w    DrawObject        ; draw the bob


MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w    DeleteObject        ; delete the bob from the old
; position

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:

rts


;****************************************************************************
; This routine moves the bob, checking that it does not go beyond the edges
;****************************************************************************

MoveObject:
move.w    ogg_x(pc),d0        ; X position
move.w    ogg_y(pc),d1        ; Y position
move.w    vel_x(pc),d2        ; dx (X speed)
move.w    vel_y(pc),d3        ; dy (Y speed)
add.w    d2,d0            ; x = x + dx
add.w    d3,d1            ; y = y + dy
addq.w    #1,d3            ; adds gravity
; (increases speed)
cmp.w    #Lowest_Floor,d1	; check lower edge
blt.s    UO_NoBounce1

subq.w    #1,d3            ; remove speed increase
neg.w    d3            ; change speed sign dy
; reversing the direction of motion
move.w    #Lowest_Floor,d1    ; restart from the edge
UO_NoBounce1:

cmp.w    #Right_Side,d0        ; check right edge
blt.s    UO_NoBounce2        ; if it crosses the right edge...
sub.w    #Right_Side,d0        ; distance from the edge
neg.w    d0            ; reverse the distance
add.w	#Right_Side,d0        ; add edge coordinate
neg.w    d2            ; reverse direction of movement
UO_NoBounce2:
btst    #15,d0            ; check left edge (X=0)
beq.s    UO_NoBounce3        ; if X is negative...
neg.w    d0            ; ... bounce
neg.w    d2            ; reverse direction of movement
UO_NoBounce3:
move.w    d0,ogg_x        ; update position and speed
move.w    d1,ogg_y
move.w	d2,vel_x
move.w	d3,vel_y

rts


;****************************************************************************
; This routine draws the BOB at the coordinates specified in the variables
; X_OGG and Y_OGG. The BOB and the screen are in normal format (not interleaved)
; and the formulas for this format are used in calculating the
; values to be written to the blitter registers. In addition, the
; technique of masking the last word of the BOB seen in lesson
;****************************************************************************

;     ,-^---^-.
;     _/ -- -- \_
;     l_ /¯¯T¯¯\ _|
;     (¯T \_°|°_/ T¯)
;     ¯T _ ¯u¯ _ T¯
;     _| l_____| |_
;     |¬| ¯¬¯ |¬|
;    xCz l_________| l

DrawObject:
lea    BITPLANE1,a0    ; bitplane address
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line occupies 40 bytes

add.l    d0,a0        ; add Y offset

move.w    ogg_x(pc),d0    ; X coordinate
move.w    d0,d1		; copy
and.w    #$000f,d0    ; select the first 4 bits because they must
; be inserted into the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #$09f0,d0    ; ...just enough to fit into the BLTCON0 register
lsr.w    #3,d1        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.l    #0000fffe,d1    ; exclude bit 0 of
add.l    d1,a0        ; add the X offset, finding the address
; of the destination

move.l    a0,DestinationAddress        ; store the address of the
; destination for the
; deletion routine

lea    Ball_Bob,a1        ; pointer to the figure
moveq    #3-1,d7            ; bitplane counter

DrawLoop:
btst    #6,2(a5)
WBlit2:
btst    #6,2(a5)
bne.s    WBlit2

move.w    d0,$40(a5)		; BLTCON0 - write shift value
move.w    #$0000,$42(a5)        ; BLTCON1 - ascending mode
move.l    #$ffff0000,$44(a5)    ; BLTAFWM and BLTLWM
move.w    #$FFFE,$64(a5)		; BLTAMOD
move.w    #40-6,$66(a5)        ; BLTDMOD
move.l    a1,$50(a5)        ; BLTAPT - figure pointer
move.l    a0,$54(a5)        ; BLTDPT - bitplanes pointer

move.w    #(31*64)+3,$58(a5)    ; BLTSIZE - height 31 lines
; width 3 words (48 pixels).

add.l    #4*31,a1        ; next image plane address
add.l    #40*256,a0        ; next destination plane address

dbra    d7,DrawLoop
rts


;****************************************************************************
; This routine clears the BOB using the blitter. The clearing
; is done on the rectangle enclosing the bob
;****************************************************************************

ClearObject:
moveq    #3-1,d7            ; 3 bitplanes
move.l    ObjectAddress(PC),a0    ; reread the destination address

canc_loop:
btst    #6,2(a5)
WBlit3:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit3

move.l    #$01000000,$40(a5)    ; BLTCON0 and BLTCON1: Clear
move    #$0022,$66(a5)        ; BLTDMOD=40-6=34=$22
move.l    a0,$54(a5)		; BLTDPT
move.w    #(64*31)+3,$58(a5)    ; BLTSIZE (start blitter !)
; clear the rectangle surrounding
; the BOB

add.l    #40*256,a0        ; next plane destination address
dbra    d7,canc_loop
rts


; object data

IndirizzoOgg:
dc.l    0    ; this variable contains the address of the
; destination

ogg_x:    dc.w    32        ; X position
ogg_y:    dc.w    50        ; Y position
vel_x:    dc.w    -3        ; X speed
vel_y:    dc.w    1        ; Y speed

;****************************************************************************

SECTION    MY_COPPER,CODE_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

dc.w    $108,0        ; MODULE
dc.w    $10a,0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000
dc.w $ec,$0000,$ee,$0000

dc.w	$180,$000	; colour0 - background
dc.w    $190,$000

dc.w    $182,$0A0            ; colours 1 to 7
dc.w    $184,$040
dc.w    $186,$050
dc.w    $188,$061
dc.w	$18A,$081
dc.w    $18C,$020
dc.w    $18E,$6F8

dc.w    $192,$0A0            ; colours 9 to 15
dc.w    $194,$040			; these are the same values
dc.w    $196,$050            ; loaded into registers 1 to 7
dc.w    $198,$061
dc.w    $19a,$081
dc.w    $19c,$020
dc.w    $19e,$6F8

dc.w    $190,$345    ; colour 8 - 1 pixel of the background

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

dc.w    $8007,$fffe    ; wait for line $80
dc.w    $100,$4200    ; bplcon0 - 4 lowres bitplanes
; activate bitplane 4 (background)

; the part of the background is displayed in this space

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

DC.W $000F,$E000,$007F,$FC00,$01FF,$FF00,$03FF,$FF80    ; plane 2
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

;****************************************************************************

; Sfondo 320 * 100 1 Bitplane, raw normale.

SfondoFinto:
incbin	‘assembler2:sorgenti6/sfondo320*100.raw’

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

In this example, we will see a bob moving on a background. The effect is
achieved, however, with a trick that greatly limits performance. The trick is
as follows: we use 4 bitplanes, the first 3 to draw the bob and the fourth
for the background. The background and the bob therefore have separate planes.
To make the bob appear above the background, we ensure that the bitplane
of the background does not influence the colours of the bob. Let's consider, for example, a
pixel of the bob formed by taking plane 1=0, plane 2=1, plane 3=1.
As this pixel moves, it overlaps many bits of plane 4.
When it is located at a bit set to 0, the 4 planes will form
the combination plane 1=0, plane 2=1, plane 3=1, plane 4=0, which defines
colour 6. When it is located at a bit set to 1,
the combination plane 1=0, plane 2=1, plane 3=1, plane 4=1, which
defines colour 14. Therefore, the colours of the bob change depending on the
background area they pass through. We would like the bob to always appear
the same when passing over the background. We can simulate this effect
in a very simple way by making the colours contained in the colour registers
the same, differing only in the background bits. Returning to the example, if
we put the same RGB value in both the COLOR06 and COLOR14 registers, whatever
the value of the plane 4 bit, our pixel will always appear the
same colour. Doing the same for all the other registers (i.e. setting
COLOR01 = COLOR09, COLOR02=COLOR10, COLOR03=COLOR11, etc.), we will solve
the problem. The “transparent” part of the bob is the one with the 3 planes set to 0,
which displays colour 0 or colour 8 depending on the value of the bit in plane
4. By keeping these 2 colours different, it is possible to display the background:
the bits at 0 in the background will appear as colour 0, while those at 1 will appear
as colour 8. To understand what happens, try putting values other than those in COLOR09-15 in the
COLOR01-07 registers: you will immediately discover
the trick. This technique has the disadvantage of “wasting” some colours.
In fact, we are forced to write the same RGB values in some registers,
reducing the number of colours that can be displayed. In this example, we use 4
bitplanes, but we can only use 8 colours for the bob and 2 for the background.
We therefore waste 6 colours. If we used 3 planes for the bob and 2 for the background,
we could display 8+4=12 colours, compared to the 32 normally allowed by 5
bitplanes. As you can see, this technique is not ideal either.
But don't worry, sooner or later we'll manage to make a proper bob!
In the meantime, note a few things in this listing:
1) We use the (already seen) BLTLWM trick at 0 to save the
word column to the right of the bob;
2) We use a NON-interleaved screen to separate the background planes and
the bob planes.
3) In the previous examples, we calculate the address of the bob's destination,
both in the drawing routine and in the clearing routine. In reality, between
the drawing and the subsequent clearing, the bob does not change position (it only does so
AFTER erasure), so the calculation is always the same and
could be done only once. In this example, we do just that:
the calculation is done in the DrawObject routine and is stored
in the ObjectAddress variable. The erasure routine simply rereads
the result from the variable and uses it.

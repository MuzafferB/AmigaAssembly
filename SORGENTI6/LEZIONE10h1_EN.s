
; Lesson 10h1.s    Collision between BOB and background using the blitter's ZERO flag.
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000    ; copper,bitplane,blitter DMA


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
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:

bsr.s    MoveObject        ; move the bob
bsr.w    CheckCollision    ; check and report any
; collisions between the bob and the background

bsr.w    SaveBackground        ; save the background
bsr.w    DrawObject        ; draw the bob

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w	RestoreBackground    ; restore the background

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:

rts


;****************************************************************************
; This routine moves the bob on the screen.
;****************************************************************************

MoveObject
addq.w    #1,ogg_y    ; move the bob down
cmp.w    #256-11,ogg_y    ; has it reached the bottom edge?
bls.s	EndMove    ; if not, end
clr.w    ogg_y        ; otherwise, start again from the top
EndMove
rts

;***************************************************************************
; This routine draws the BOB at the coordinates specified in the variables
; X_OGG and Y_OGG.
;****************************************************************************

;     ||||||||
;     | = = |
;    @| O O |@
;     | () |
;     ((\__/))
;     ((()))
;     ))((
;     ()

DrawObject:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line consists of
; 40 bytes
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d0    ; X coordinate
move.w    d0,d1        ; copy
and.w    #$000f,d0    ; select the first 4 bits because they go
; be inserted into the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
move.w    d0,d2

or.w    #$0FCA,d0    ; ...just enough to fit into the BLTCON0 register
lsr.w    #3,d1        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (and therefore also to bytes)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1    ; exclude bit 0 of
add.w    d1,a0        ; add to the bitplane address, finding
; the correct destination address

lea    figure,a1    ; source pointer
moveq    #3-1,d7        ; repeat for each plane
PlaneLoop:
btst    #6,2(a5)
WBlit2:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit2

move.l    #$ffff0000,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word


move.w    d0,$40(a5)        ; BLTCON0 (use A+D)
move.w    d2,$42(a5)        ; BLTCON1 (no special mode)
move.l    #$0022fffe,$60(a5)
move.l	#$fffe0022,$64(a5)    ; BLTAMOD=$fffe=-2 go back
; to the beginning of the line.
; BLTDMOD=40-6=34=$22 as usual
move.l    #Mask,$50(a5)    ; BLTAPT (fixed to the source image)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.l    a0,$48(a5)        ; BLTCPT (screen lines)
move.l    a1,$4c(a5)
move.w    #(64*11)+3,$58(a5)    ; BLTSIZE (start blitter!)

lea    4*11(a1),a1        ; points to the next source plane
; each plane is 2 words wide and
; 11 lines high

lea    40*256(a0),a0        ; points to the next destination plane
dbra    d7,PlaneLoop

rts

;****************************************************************************
; This routine copies the background rectangle that will be overwritten by
; BOB into a buffer
;****************************************************************************

SaveBackground:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line consists of
; 40 bytes
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d1    ; X coordinate
lsr.w    #3,d1        ; (equivalent to a division by 8)
; round to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1	; exclude bit 0 of the
add.w    d1,a0        ; add to the bitplane address, finding
; the correct destination address

lea    Buffer,a1    ; destination address
moveq    #3-1,d7        ; repeat for each plane
PlaneLoop2:
btst    #6,2(a5) ; dmaconr
WBlit3:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit3

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything


move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.l    #$00220000,$64(a5)    ; BLTAMOD=40-4=36=$24
; BLTDMOD=0 in the buffer
move.l    a0,$50(a5)        ; BLTAPT - source index
move.l    a1,$54(a5)        ; BLTDPT - buffer
move.w    #(64*11)+3,$58(a5)    ; BLTSIZE (start the blitter!)

lea    40*256(a0),a0        ; points to the next source plane
lea    6*11(a1),a1        ; points to the next destination plane
; each blit is 3 words wide and
; 11 lines high
dbra    d7,PlaneLoop2

rts

;****************************************************************************
; This routine copies the contents of the buffer into the screen rectangle
; that contained it before the BOB was drawn. This also
; clears the BOB from its old position.
;****************************************************************************

RestoreBackground:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line consists of
; 40 bytes
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d1    ; X coordinate
lsr.w    #3,d1        ; (equivalent to a division by 8)
; round to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (and therefore also to bytes)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1    ; exclude bit 0 of
add.w    d1,a0        ; add to the bitplane address, finding
; the correct destination address

lea    Buffer,a1    ; source address
moveq    #3-1,d7        ; repeat for each plane
PlaneLoop3:
btst    #6,2(a5)     ; dmaconr
WBlit4:
btst    #6,2(a5)     ; wait for the blitter to finish
bne.s    wblit4

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything


move.l    #09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.l    #00000022,$64(a5)    ; BLTAMOD=0 (buffer)
; BLTDMOD=40-6=34=$22
move.l    a1,$50(a5)        ; BLTAPT (buffer)
move.l    a0,$54(a5)        ; BLTDPT (screen)
move.w    #(64*11)+3,$58(a5)    ; BLTSIZE (start blitter!)

lea    40*256(a0),a0        ; point to the next destination plane
lea    6*11(a1),a1        ; point to the next source plane
; each blitter is 3 words wide and
; 11 lines high
dbra    d7,PlaneLoop3
rts

OGG_Y:        dc.w    0    ; the Y of the object is stored here
OGG_X:        dc.w    100    ; the X of the object is stored here


;****************************************************************************
; This routine checks for collisions
;****************************************************************************

CheckCollision

lea    bitplane,a0    ; bitplane address a0
move.w	ogg_y(pc),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line consists of
; 40 bytes
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d0    ; X coordinate
move.w    d0,d1        ; copy
and.w    #$000f,d0    ; select the first 4 bits because they must
; be inserted in the channel A shifter
lsl.w    #8,d0        ; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
move.w    d0,d2

or.w    #0AA0,d0    ; ...correct to be inserted into the BLTCON0 register
; only channels A and C are active (not D)
; performs an AND between A and C

lsr.w    #3,d1        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; x e.g.: a 16 as a coordinate becomes
; byte 2
and.w	#$fffe,d1    ; exclude bit 0 of the
add.w    d1,a0        ; add to the bitplane address, finding
; the correct destination address

; wait for the blitter to finish before modifying the registers
btst    #6,2(a5)
WBlit_coll:
btst    #6,2(a5)
bne.s    wblit_coll

lea    Mask,a1    ; collision mask pointer
moveq    #3-1,d7        ; repeat for each plane
CollLoop:

move.l    #$ffff0000,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word


move.w    d0,$40(a5)        ; BLTCON0
; only channels A and C are active
; (not D). Performs an AND between A and C
move.w    #$0000,$42(a5)        ; BLTCON1 (no special mode)
move.w    #$0022,$60(a5)        ; BLTCMOD=40-6=34=$22
move.w    #$fffe,$64(a5)        ; BLTAMOD=$fffe=-2 go back
; to the beginning of the line.
move.l    a1,$50(a5)        ; BLTAPT (fixed to the source image)
move.l    a0,$48(a5)        ; BLTCPT (position on the screen)
move.w    #(64*11)+3,$58(a5)    ; BLTSIZE (start the blitter!)

lea    40*256(a0),a0        ; point to the next plane on the screen

btst    #6,2(a5)
WBlit_coll2:
btst    #6,2(a5)        ; wait for the blitter to finish
bne.s    wblit_coll2        ; before testing the ZERO flag

btst    #5,2(a5)        ; check the ZERO flag.
beq.s
	SiColl            ; If the flag is not zero, there has been a collision, report it.
; Otherwise, check the next plane

dbra    d7,CollLoop        ; if no collision occurs for any plane
; exit the loop

NoColl
move.w    #$000,$180(a5)    ; no collisions occurred:
; black screen
bra.s    EndColl        ; jump to the end of the routine

SiColl    move    #$F00,$180(a5)    ; a collision was detected:
; red screen

EndColl
rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; MODULE VALUE = 0
dc.w    $10a,0        ; BOTH MODULES AT THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; These are the data that make up the bob figure.
; The bob is in normal format, 32 pixels wide (2 words)
; 11 lines high and made up of 3 bitplanes

Figure:    dc.l    $007fc000    ; plane 1
dc.l    $03fff800
dc.l    $07fffc00
dc.l    $0ffffe00
dc.l    $1fe07f00
dc.l    $1fe07f00
dc.l    $1fe07f00
dc.l    $0ffffe00
dc.l    $07fffc00
dc.l    $03fff800
dc.l    $007fc000

dc.l    $00000000    ; plane 2
dc.l    $007fc000
dc.l    $03fff800
dc.l    $07fffc00
dc.l    $0fe07e00
dc.l    $0fe07e00
dc.l    $0fe07e00
dc.l	$07fffc00
dc.l    $03fff800
dc.l    $007fc000
dc.l    $00000000

dc.l    $007fc000    ; plane 3
dc.l    $03803800
dc.l    $04000400
dc.l    $081f8200
dc.l    $10204100
dc.l    $10204100
dc.l    $10204100
dc.l    $081f8200
dc.l    $04000400
dc.l    $03803800
dc.l    $007fc000

Mask:
dc.l    $007fc000
dc.l    $03fff800
dc.l    $07fffc00
dc.l    $0ffffe00
dc.l    $1fe07f00
dc.l	$1fe07f00
dc.l	$1fe07f00
dc.l	$0ffffe00
dc.l	$07fffc00
dc.l	$03fff800
dc.l	$007fc000

;****************************************************************************

BITPLANE:
incbin    ‘amiga.raw’        ; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.

;****************************************************************************

SECTION    BUFFER,BSS_C

; This is the buffer in which we save the background each time.
; It has the same dimensions as a blitter: height 11, width 3 words
; 3 bitplanes

Buffer:
ds.w    11*3*3

end

;****************************************************************************

In this example, we show how to detect collisions between the bob and the background.
To detect collisions, we use the blitter's Zero flag. The technique is as follows
: we perform a blit that does an AND between the bob mask and the
background, but without writing the result to the output. If the AND operation
operation returns a result of zero for all bits of the blit, the Zero flag
assumes a value of 1. The fact that the AND operation returned a result of 0
means that in no case does a bit of the mask coincide with one of the
background, so there is no collision.
If, on the other hand, at least one bit of the mask coincides with one of the background, it means
that a collision has occurred. In this case, since the AND operation between
these two bits results in 1, the ZERO flag will take the value 0, and from this
we can understand that there has been a collision.
Note that while we have a mask for the bob, this is not the case for the background.
This forces us to check for collisions between the bob mask
and all the planes in the figure. If we had the background mask, we
could test for collision with a single bit comparison between the masks.
Do this as an exercise.
Also note that before testing the Zero flag, it is necessary to wait for the
bit comparison to finish.

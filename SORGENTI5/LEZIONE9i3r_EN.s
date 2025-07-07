
; Lesson9i3r.s    BOB rawblit with background restoration.
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
; HERE IS THE FIRST DIFFERENCE COMPARED
; TO NORMAL IMAGES!!!!!!
ADD.L    #40,d0        ; + LENGTH OF A LINE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:

bsr.w    ReadMouse        ; read coordinates
bsr.s    CheckCoordinates    ; prevent bob from leaving the screen
bsr.w	SaveBackground        ; save background
bsr.s    DrawObject        ; draw bob

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L	4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w    RestoreBackground    ; restore background

btst    #6,$bfe001        ; left mouse button pressed?
bne.s    mouse            ; if not, return to mouse:

rts


;****************************************************************************
; This routine ensures that the bob's coordinates always remain
; within the screen.
;****************************************************************************

CheckCoordinates:
tst.w    ogg_x        ; check X
bpl.s    NoMinX        ; check left edge
clr.w    ogg_x        ; if X is negative, set X=0
bra.s    checkY    ; goes to check Y

NoMinX:
cmp.w    #319-32,ogg_x    ; checks the right edge. In X_OGG
; the coordinate of the left edge
; of the bob is stored. If it has reached
; 319-32, then the right edge has reached
; coordinate 319
bls.s    checkY    ; if it is less, everything is fine, check Y
move.w    #319-32,ogg_x    ; otherwise, set the coordinate on the edge.

checkY:
tst.w    ogg_y        ; check top edge
bpl.s    NoMinY        ; if positive, check bottom
clr.w    ogg_y        ; otherwise set Y=0
bra.s    EndCheck    ; and exit

NoMinY:
cmp.w    #255-11,ogg_y    ; check the bottom edge. In Y_OGG
; the coordinate of the top edge of the bob is stored.
If it has reached
; Y=255-11, then the bottom edge has reached
; the coordinate Y=255
bls.s	EndCheck    ; if it is less, everything is fine, check Y
move.w    #255-11,ogg_y    ; otherwise set the coordinate on the edge.
EndCheck:
rts

;***************************************************************************
; This routine draws the BOB at the coordinates specified in the variables
; X_OGG and Y_OGG. The BOB and the screen are in interleaved format, and therefore
; the formulas related to this format are used in calculating the
; values to be written in the blitter registers. In addition, the
; technique of masking the last word of the BOB seen in lesson
;****************************************************************************

;     /·
;     //
;     ¦.:.:.:.:. //
;     | -_ _- ¦ //
;     _| / \ | //
;    (_l ( © ø )| //
;    / ___¯(_)¯ |//
;    \ ¬ _____!/
;     \____/ T //
;     |__|//
;     (___/
;     C__)
;     /`--“\
;     /_/ \_\
;     (,,) (,,)
;     ¯T____T¯
;     / _ \
;     \__\ \ xCz
;     / X___\__
;     (__/ `-----”

DrawObject:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #3*40,d0    ; calculate address: each line consists of
; 3 planes of 40 bytes each
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d0    ; X coordinate
move.w    d0,d1        ; copy
and.w    #$000f,d0    ; select the first 4 bits because they
; must be inserted into the shifter of channel A
lsl.w    #8,d0		; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #$09f0,d0    ; ...just right to fit into the BLTCON0 register
lsr.w    #3,d1        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; on the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1    ; exclude bit 0 of
add.w    d1,a0        ; add to the bitplane address, finding
; the correct destination address

btst    #6,2(a5)
WBlit2:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit2

move.l    #$ffff0000,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word


move.w    d0,$40(a5)        ; BLTCON0 (uses A+D)
move.w    #$0000,$42(a5)        ; BLTCON1 (no special mode)
move.l    #$fffe0022,$64(a5)    ; BLTAMOD=$fffe=-2 go back
; to the beginning of the line.
; BLTDMOD=40-6=34=$22 as usual
move.l    #figure,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.w    #(64*11*3)+3,$58(a5)    ; BLTSIZE (start blitter!)

rts

;****************************************************************************
; This routine copies the background rectangle that will be overwritten by
; BOB into a buffer
;****************************************************************************

SaveBackground:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #3*40,d0    ; calculate address: each line consists of
; 3 planes of 40 bytes each
add.w    d0,a0		; add to the starting address

move.w    ogg_x(pc),d1    ; X coordinate
lsr.w    #3,d1        ; (equivalent to a division by 8)
; round to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (and therefore also to bytes)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1    ; exclude bit 0 of
add.w    d1,a0        ; add to the address of the bitplane, finding
; the correct destination address
btst	#6,2(a5) ; dmaconr
WBlit3:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit3

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything


move.l    #09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.l    #00220000,$64(a5)    ; BLTAMOD=40-4=36=$24
; BLTDMOD=0 in the buffer
move.l    a0,$50(a5)        ; BLTAPT - source ind.
move.l    #Buffer,$54(a5)        ; BLTDPT - buffer
move.w    #(64*11*3)+3,$58(a5)    ; BLTSIZE (start blitter!)
rts

;****************************************************************************
; This routine copies the contents of the buffer into the screen rectangle
; that contained it before the BOB was drawn. This also
; deletes the BOB from its old position.
;****************************************************************************

RestoreBackground:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #3*40,d0    ; calculate address: each line consists of
; 3 planes of 40 bytes each
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d1    ; X coordinate
lsr.w    #3,d1		; (equivalent to a division by 8)
; round to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; x e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1	; exclude bit 0 of the
add.w    d1,a0        ; add to the bitplane address, finding
; the correct destination address

btst    #6,2(a5)     ; dmaconr
WBlit4:
btst    #6,2(a5)     ; wait for the blitter to finish
bne.s    wblit4

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything


move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.l	#$00000022,$64(a5)    ; BLTAMOD=0 (buffer)
; BLTDMOD=40-6=34=$22
move.l    #Buffer,$50(a5)        ; BLTAPT (buffer)
move.l    a0,$54(a5)        ; BLTDPT (screen)
move.w    #(64*11*3)+3,$58(a5)    ; BLTSIZE (start blitter!)
rts

;****************************************************************************
; This routine reads the mouse and updates the values contained in
; the OGG_X and OGG_Y variables
;****************************************************************************

ReadMouse:
move.b    $dff00a,d1    ; JOY0DAT vertical mouse position
move.b    d1,d0        ; copy to d0
sub.b    mouse_y(PC),d0    ; subtract old mouse position
beq.s    no_vert        ; if the difference = 0, the mouse is stationary
ext.w    d0        ; convert the byte to a word
; (see end of listing)
add.w    d0,ogg_y    ; modify object position

no_vert:
move.b    d1,mouse_y    ; save mouse position for next time

move.b    $dff00b,d1    ; horizontal mouse position
move.b    d1,d0        ; copy to d0
sub.b    mouse_x(PC),d0    ; subtract old position
beq.s    no_oriz        ; if the difference = 0, the mouse is stationary
ext.w    d0        ; convert the byte to a word
; (see end of listing)
add.w    d0,ogg_x    ; change object position
no_oriz
move.b    d1,mouse_x    ; save mouse position for next time
RTS

OGG_Y:        dc.w    0    ; the Y position of the object is stored here
OGG_X:        dc.w    0    ; the X position of the object is stored here
MOUSE_Y:    dc.b    0    ; the Y position of the mouse is stored here
MOUSE_X:    dc.b    0    ; the X position of the mouse is stored here

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

; HERE IS THE SECOND DIFFERENCE COMPARED
; NORMAL IMAGES!!!!!!
dc.w    $108,80        ; MODULE VALUE = 2*20*(3-1)= 80
dc.w    $10a,80        ; BOTH MODULES HAVE THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w $0180,$000; colour0
dc.w $0182,$475; colour1
dc.w $0184,$fff; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444	; color7

dc.w	$FFFF,$FFFE	; Fine della copperlist

;****************************************************************************

; These are the data that make up the bob figure.
; The bob is in interleaved format, 32 pixels wide (2 words)
; 11 lines high and made up of 3 bitplanes

Figure:    dc.l    $007fc000,$00000000,$007fc000
dc.l	$03fff800,$007fc000,$03803800
dc.l	$07fffc00,$03fff800,$04000400
dc.l	$0ffffe00,$07fffc00,$081f8200
dc.l	$1fe07f00,$0fe07e00,$10204100
dc.l	$1fe07f00,$0fe07e00,$10204100
dc.l	$1fe07f00,$0fe07e00,$10204100
dc.l	$0ffffe00,$07fffc00,$081f8200
dc.l	$07fffc00,$03fff800,$04000400
dc.l	$03fff800,$007fc000,$03803800
dc.l	$007fc000,$00000000,$007fc000

;****************************************************************************

BITPLANE:
incbin    ‘assembler2:sources6/amiga.rawblit’
; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.

;****************************************************************************

SECTION    BUFFER,BSS_C

; This is the buffer in which we save the background each time.
; It has the same dimensions as a blited image: height 11, width 3 words
; 3 bitplanes

Buffer:
ds.w    11*3*3

end

;****************************************************************************

This example is the rawblit version of lesson9i3.s.
Compare the differences in the formulas for calculating the values to be written
in the blitter registers.

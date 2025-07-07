
; Lesson9i2.s    BOB in colour
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
MOVEQ    #3-1,D1		; number of bitplanes (here there are 3)
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
move.l    #COPPERLIST,$80(a5)	; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
bsr.w    ReadMouse        ; Read coordinates
bsr.s    CheckCoordinates    ; prevent bob from leaving the screen
bsr.s    DrawObject        ; draw bob

MOVE.L	#$1ff00,d1    ; bit for selection via AND
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
; This routine ensures that the bob's coordinates always remain
; within the screen.
;****************************************************************************

CheckCoordinates:
tst.w    ogg_x        ; check X
bpl.s    NoMinX        ; check left edge
clr.w    ogg_x        ; if X is negative, set X=0
bra.s    checkY    ; goes to check Y

NoMinX:
cmp.w    #319-32,ogg_x    ; Check the right edge. In X_OGG
; the coordinate of the left edge of the bob is stored.
If it has reached
319-32, then the right edge has reached
the coordinate 319.
bls.s    checkY    ; If it is less, everything is fine, check Y
move.w    #319-32,ogg_x    ; otherwise set the coordinate on the edge.

checkY:
tst.w    ogg_y        ; check top edge
bpl.s    NoMinY        ; if positive, check bottom
clr.w    ogg_y        ; otherwise set Y=0
bra.s    EndCheck    ; and exit

NoMinY:
cmp.w    #255-11,ogg_y    ; check the bottom edge. In Y_OGG
; the coordinate of the
; top edge of the bob is stored. If it has reached
; Y=255-11, then the lower edge has reached
; the coordinate Y=255
bls.s    EndCheck    ; if it is less, everything is fine, check Y
move.w    #255-11,ogg_y    ; otherwise set the coordinate on the edge.
EndControlla:
rts

;****************************************************************************
; This routine draws the BOB at the coordinates specified in the variables
; X_OGG and Y_OGG. The BOB and the screen are in normal format, and therefore
; the formulas related to this format are used in calculating the
; values to be written in the blitter registers. In addition, the
; technique of masking the last word of the BOB seen in the lesson is used.
;****************************************************************************

;     _
;     /_\---.
;     _//_\ __|
;     C/ ( °\°/l)
;     / (___)|
;    (_ ° _____!
;     `---“|,|_
;     /¯” ` |
;     //T· ·T|
;     \\l ° |l
;     (__) (_¯)
;     |¯¬¯|¯ xCz
;     l__Tl__
;     (____)_)

DrawObject:
lea    bitplane,a0    ; destination in a0
move.w    ogg_y(pc),d0    ; Y coordinate
mulu.w    #40,d0        ; calculate address: each line consists of
; 40 bytes
add.w    d0,a0        ; add to the starting address

move.w    ogg_x(pc),d0    ; X coordinate
move.w    d0,d1        ; copy
and.w    #000f,d0    ; select the first 4 bits because they must be
; inserted into the shifter of channel A
lsl.w    #8,d0		; the 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word...
or.w    #$09f0,d0    ; ...just right to fit into the BLTCON0 register
lsr.w	#3,d1        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d1	; exclude bit 0 of the
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
move.w    #$0000,$42(a5)        ; BLTCON1 (no special mode)
move.l    #$fffe0022,$64(a5)    ; BLTAMOD=$fffe=-2 go back
; to the beginning of the line.
; BLTDMOD=40-6=34=$22 as usual
move.l    a1,$50(a5)        ; BLTAPT (fixed to the source image)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.w    #(64*11)+3,$58(a5)    ; BLTSIZE (start blitter!)

lea    4*11(a1),a1        ; point to next source plane
; each plane is 2 words wide and
; 11 lines

lea    40*256(a0),a0        ; points to the next destination plane
dbra    d7,PlaneLoop

rts

;*****************************************************************************
; This routine clears the BOB using the blitter. The clearing
; is done on the rectangle that encloses the bob, which is 6 lines high and 3 words wide
;****************************************************************************

DeleteObject:
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
and.w    #$fffe,d1	; exclude bit 0 of
add.w    d1,a0        ; add to the bitplane address, finding
; the correct destination address

moveq    #3-1,d7        ; repeat for each plane
PlaneLoop2:
btst    #6,2(a5)
WBlit3:
btst    #6,2(a5)     ; wait for the blitter to finish
bne.s    wblit3

move.l    #$01000000,$40(a5)    ; BLTCON0 and BLTCON1: Clear
move.w    #0022,$66(a5)        ; BLTDMOD=40-6=34=$22
move.l    a0,$54(a5)        ; BLTDPT
move.w	#(64*11)+3,$58(a5)    ; BLTSIZE (start blitter!)
; clear the rectangle surrounding
; the BOB

lea    40*256(a0),a0        ; point to the next destination plane
dbra    d7,PlaneLoop2

rts

*****************************************************************************
; This routine reads the mouse and updates the values contained in
; the OGG_X and OGG_Y variables
;****************************************************************************

LeggiMouse:
move.b    $dff00a,d1    ; JOY0DAT vertical mouse position
move.b    d1,d0        ; copy to d0
sub.b    mouse_y(PC),d0    ; subtract old mouse position
beq.s    no_vert		; if the difference = 0, the mouse is stationary
ext.w    d0        ; convert the byte to a word
; (see end of listing)
add.w    d0,ogg_y    ; change object position

no_vert:
move.b    d1,mouse_y    ; save mouse position for next time

move.b    $dff00b,d1    ; horizontal mouse position
move.b    d1,d0        ; copy to d0
sub.b    mouse_x(PC),d0    ; subtract old position
beq.s    no_oriz		; if the difference = 0, the mouse is stationary
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
dc.w    $108,0		; MODULE VALUE 0
dc.w    $10a,0        ; BOTH MODULES AT THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w	$0188,$999    ; colour4
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
dc.l    $07fffc00
dc.l    $03fff800
dc.l    $007fc000
dc.l    $00000000

dc.l    $007fc000    ; plane 3
dc.l    $03803800
dc.l    $04000400
dc.l    $081f8200
dc.l    $10204100
dc.l    $10204100
dc.l	$10204100
dc.l	$081f8200
dc.l	$04000400
dc.l	$03803800
dc.l	$007fc000

;****************************************************************************

BITPLANE:
incbin    ‘assembler2:sources6/amiga.raw’
; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.
end

;****************************************************************************

In this example we have a colour BOB that moves across the screen controlled
by the mouse. There is a background image on the screen. The interleaved format is used.
 For the BOB we use the technique of masking the last word, which
we already used in the lesson9i1.s example. The programme consists of 4
routines that are called cyclically. The ‘LeggiMouse’ routine is the same
used in lesson7. It reads the BOB coordinates from the mouse and stores them in the
variables X_OGG and Y_OGG. The ‘CheckCoordinates’ routine is used to prevent
the BOB from leaving the screen. The ‘DrawObject’ routine is the routine that
draws the BOB on the screen, and is similar to those already seen before. Note
that this routine overwrites the background when it draws. Once
the BOB has been drawn, the program waits for the next vertical blank
 to allow the image with the BOB in its current position to be displayed. After the
vertical blank, the ‘ClearObject’ routine is called, which deletes the BOB
from its current position. This routine deletes the rectangle containing the BOB using the
blitter. Empty space appears in place of the BOB.
The main loop then restarts, reading the
new coordinates, checking and drawing the BOB in its new position.
The major ‘flaw’ of this program is that the BOB deletes the parts of the
background it passes over.

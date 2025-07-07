
; Lesson 10m1.s    Universal Bob Routine
;        Left key to exit.

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
MOVEQ    #2-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0    ; + bitplane length (here it is 256 lines high)
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

; parameters for SalvaSfondo routine

move.w    ogg_x(pc),d0        ; X position
move.w	ogg_y(pc),d1        ; Y position
move.w    #32,d2            ; X size
move.w    #30,d3            ; Y size
bsr.w    SalvaSfondo        ; save the background

; parameters for UniBob routine

move.l    Frametab(pc),a0        ; sets the pointer to the frame
; to be drawn in A0
lea    2*4*30(a0),a1        ; pointer to the mask in A1
move.w    ogg_x(pc),d0        ; X position
move.w    ogg_y(pc),d1        ; Y position
move.w    #32,d2            ; X size
move.w    #30,d3            ; Y size
bsr.w    UniBob            ; draw the bob with the
; universal

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0
BNE.S    Waity1

; parameters for the RestoreBackground routine

move.w    ogg_x(pc),d0        ; X position
move.w    ogg_y(pc),d1        ; Y position
move.w    #32,d2            ; X size
move.w    #30,d3            ; Y size
bsr.w    RestoreBackground    ; restores the background

bsr.s    MoveObject    ; move the object on the screen
bsr.s    Animation    ; move the frames in the table

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse
rts


;****************************************************************************
; Questa routine muove il bob sullo schermo.
;****************************************************************************

MoveObject:
addq.w    #1,ogg_x    ; move bob down
cmp.w    #320-32,ogg_x    ; has it reached the bottom edge?
bls.s    EndMove    ; if not, end
clr.w    ogg_x        ; otherwise, start again from the top
EndMove
rts

;****************************************************************************
; This routine creates the animation, moving the frame addresses
; so that each time the first one in the table goes to the last place,
; while the others all move one place towards the first one
;****************************************************************************

Animation:
addq.b    #1,ContaAnim ; these three instructions ensure that the
cmp.b    #4,ContaAnim ; frame is changed once
bne.s    NonCambiare ; yes and 3 no.
clr.b    ContaAnim
LEA    FRAMETAB(PC),a0 ; frame table
MOVE.L    (a0),d0        ; save the first address in d0
MOVE.L    4(a0),(a0)    ; move the other addresses backwards
MOVE.L    4*2(a0),4(a0)    ; These instructions ‘rotate’ the addresses
MOVE.L    4*3(a0),4*2(a0) ; in the table.
MOVE.L    d0,4*3(a0)    ; put the former first address in the eighth place

Do not change:
rts

CountAnim:
dc.w    0

; This is the frame address table. The addresses
; in the table are ‘rotated’ within the table by the
Animation routine, so that the first in the list is the first time
frame1, the next time Frame2, then 3, 4 and again the
first, cyclically. This way, you just need to take the address at
the beginning of the table each time after the ‘shuffle’ to get the
frame addresses in sequence.

FRAMETAB:
DC.L    Frame1
DC.L    Frame2
DC.L    Frame3
DC.L    Frame4

; BOB position variables

OGG_Y:        dc.w    100    ; the Y of the object is stored here
OGG_X:        dc.w    50    ; the X of the object is stored here

;***************************************************************************
; This is the universal routine for drawing bobs of arbitrary shape and size
;. All parameters are passed via registers.
; The routine works on a normal screen
;
; A0 - bob figure address
; A1 - bob mask address
; D0 - X coordinate of the upper left vertex
; D1 - Y coordinate of the upper left vertex
; D2 - rectangle width in pixels
; D3 - rectangle height
;****************************************************************************

;     ___ Oo .:/
;     (___)o_o ,,///;, ,;/
;     //====--//(_) o:::::::;;///
;     \\ ^ >::::::::;;\\\
;     “”\\\\\“" ”;\

UniBob:

; calculate blitter start address

lea    bitplane,a2    ; bitplane address
mulu.w    #40,d1        ; Y offset
add.l    d1,a2        ; add to address
move.w    d0,d6        ; copy X
lsr.w    #3,d0        ; divide X by 8
and.w    #$fffe,d0    ; make it even
add.w    d0,a2        ; add to the bitplane address, finding
; the correct destination address

and.w    #$000f,d6    ; select the first 4 bits of X because
; they must be inserted into the shifter of channels A and B
lsl.w    #8,d6        ; the 4 bits are moved to the high nibble
lsl.w    #4,d6        ; of the word. This is the value of BLTCON1

move.w    d6,d5        ; copy to calculate the value of BLTCON0 
or.w    #$0FCA,d5    ; values to put in BLTCON0

; calculate the offset between the planes in the figure
lsr.w    #3,d2		; divide the width by 8
and.w    #$fffe,d2    ; reset bit 0 (make even)
move.w    d2,d0        ; copy width divided by 8
mulu    d3,d2        ; multiply by the height

; blitter module calculation

addq.w    #2,d0        ; the blitted image is one word wider 
move.w    #40,d4        ; screen width in bytes
sub.w    d0,d4        ; module=screen width-rectangle width

; calculate blitted size

lsl.w    #6,d3        ; height by 64
lsr.w    #1,d0        ; width in pixels divided by 16
; i.e. width in words
or    d0,d3        ; put the dimensions together

; initialise the registers that remain constant
btst    #6,2(a5)
WBlit_u1:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit_u1

move.l    #$ffff0000,$44(a5)	; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word

move.w    d6,$42(a5)        ; BLTCON1 - shift value
; no special mode

move.w    d5,$40(a5)        ; BLTCON0 - shift value
; cookie-cut

move.l    #$fffefffe,$62(a5)    ; BLTBMOD and BLTAMOD=$fffe=-2 return
; back to the beginning of the line.

move.w    d4,$60(a5)        ; BLTCMOD calculated value
move.w    d4,$66(a5)        ; BLTDMOD calculated value

moveq    #2-1,d7            ; repeat for each plane
PlaneLoop:
btst    #6,2(a5)
WBlit_u2:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit_u2


move.l    a1,$50(a5)        ; BLTAPT (mask)
move.l    a2,$54(a5)        ; BLTDPT (screen lines)
move.l    a2,$48(a5)        ; BLTCPT (screen lines)
move.l    a0,$4c(a5)        ; BLTBPT (bob figure)
move.w    d3,$58(a5)        ; BLTSIZE (start blitter!)

add.l    d2,a0            ; point to the next source plane

lea    40*256(a2),a2        ; point to the next destination plane
dbra    d7,PlaneLoop

rts

;****************************************************************************
; This routine copies the background rectangle that will be overwritten by
; BOB into a buffer. The routine handles a bob of arbitrary size.
; If you use this routine for bobs of different sizes, make sure
; that the buffer can contain the maximum size bob!
; The position and size of the rectangle are parameters
;
; D0 - X coordinate of the upper left corner
; D1 - Y coordinate of the upper left corner
; D2 - rectangle width in pixels
; D3 - rectangle height
;****************************************************************************

SaveBackground:
; calculate the starting address of the blitter

lea    bitplane,a1    ; bitplane address
mulu.w    #40,d1        ; Y offset
add.l    d1,a1        ; add to address
lsr.w    #3,d0		; divide X by 8
and.w    #$fffe,d0    ; make it even
add.w    d0,a1        ; add to the bitplane address, finding
; the correct destination address

; calculate the offset between the planes in the figure
lsr.w    #3,d2		; divide the width by 8
and.w    #$fffe,d2    ; reset bit 0 (make even)
addq.w	#2,d2        ; the blitter is 1 word wider
move.w    d2,d0        ; copy width divided by 8
mulu    d3,d0        ; multiply by height

; blitter module calculation
move.w    #40,d4        ; screen width in bytes
sub.w    d2,d4		; module=screen width-rectangle width

; calculate blitted size
lsl.w    #6,d3        ; height by 64
lsr.w    #1,d2        ; width in pixels divided by 16
; i.e. width in words
or    d2,d3        ; put the dimensions together

lea	Buffer,a2    ; destination address
moveq    #2-1,d7        ; repeat for each plane
PlaneLoop2:
btst    #6,2(a5) ; dmaconr
WBlit3:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit3

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything

move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.w    d4,$64(a5)        ; BLTAMOD calculated value
move.w    #$0000,$66(a5)		; BLTDMOD=0 in the buffer
move.l    a1,$50(a5)        ; BLTAPT - source index
move.l    a2,$54(a5)		; BLTDPT - buffer
move.w    d3,$58(a5)        ; BLTSIZE (start blitter!)

lea    40*256(a1),a1        ; point to next source plane
add.l    d0,a2            ; point to next destination plane

dbra    d7,PlaneLoop2

rts

;****************************************************************************
; This routine copies the contents of the buffer into the screen rectangle
; that contained it before the BOB was drawn. This also
; deletes the BOB from its old position. The routine handles a bob of
; arbitrary size.
; If you use this routine for bobs of different sizes, make sure
; that the buffer can contain the maximum size bob!
; The position and size of the rectangle are parameters
;
; D0 - X coordinate of the upper left corner
; D1 - Y coordinate of the upper left corner
; D2 - rectangle width in pixels
; D3 - rectangle height
;****************************************************************************

RestoreBackground:
; calculate blitter start address

lea    bitplane,a1    ; bitplane address
mulu.w    #40,d1		; Y offset
add.l    d1,a1        ; add to address
lsr.w    #3,d0        ; divide X by 8
and.w    #$fffe,d0    ; make it even
add.w    d0,a1        ; add to the bitplane address, finding
; the correct destination address

; calculate offset between planes in the figure
lsr.w    #3,d2        ; divide width by 8
and.w    #$fffe,d2    ; reset bit 0 (make even)
addq.w    #2,d2        ; the blitter is 1 word wider
move.w    d2,d0		; copy width divided by 8
mulu    d3,d0        ; multiply by height

; calculate blitter module
move.w    #40,d4        ; screen width in bytes
sub.w    d2,d4        ; module=screen width-rectangle width

; calculate blitted size
lsl.w    #6,d3        ; height by 64
lsr.w    #1,d2        ; width in pixels divided by 16
; i.e. width in words
or    d2,d3        ; put dimensions together

lea    Buffer,a2	; destination address
moveq    #2-1,d7        ; repeat for each plane
PlaneLoop3:
btst    #6,2(a5) ; dmaconr
WBlit4:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit4

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything

move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.w    d4,$66(a5)		; BLTDMOD calculated value
move.w    #$0000,$64(a5)        ; BLTAMOD=0 in buffer
move.l    a2,$50(a5)        ; BLTAPT - buffer
move.l    a1,$54(a5)		; BLTDPT - screen
move.w    d3,$58(a5)        ; BLTSIZE (start blitter!)

lea    40*256(a1),a1        ; point to next destination plane
add.l    d0,a2            ; point to next source plane

dbra    d7,PlaneLoop3

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
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0		; Bpl2Mod

dc.w	$100,$2200	; bplcon0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane
dc.w $e4,$0000,$e6,$0000

dc.w    $180,$000    ; colour0
dc.w    $182,$00b    ; colour1
dc.w    $184,$cc0    ; colour2
dc.w    $186,$b00    ; colour3

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************
; Questi sono i frames che compongono l'animazione

Frame1:
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
dc.l	$00000000,$00000000,$00000000,$00000000,$03ffff80,$03ffff80
dc.l	$03ffff80,$03ffff80,$03ffff80,$03ffff80,$03ffff80,$03ffff80
dc.l	$03ffff80,$03ffff80,$00000000,$00000000,$00000000,$00000000
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
dc.l	$00010000,$00038000,$0007c000,$000fe000,$001ff000,$003ff800
dc.l	$007ffc00,$00fffe00,$01ffff00,$03ffff80,$03ffff80,$03ffff80
dc.l	$03ffff80,$03ffff80,$03ffff80,$03ffff80,$03ffff80,$03ffff80
dc.l	$03ffff80,$03ffff80,$03ffff80,$01ffff00,$00fffe00,$007ffc00
dc.l	$003ff800,$001ff000,$000fe000,$0007c000,$00038000,$00010000
; maschera
dc.l	$00010000,$00038000,$0007c000,$000fe000,$001ff000,$003ff800
dc.l	$007ffc00,$00fffe00,$01ffff00,$03ffff80,$03ffff80,$03ffff80
dc.l	$03ffff80,$03ffff80,$03ffff80,$03ffff80,$03ffff80,$03ffff80
dc.l	$03ffff80,$03ffff80,$03ffff80,$01ffff00,$00fffe00,$007ffc00
dc.l	$003ff800,$001ff000,$000fe000,$0007c000,$00038000,$00010000


Frame2:
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00300000
dc.l	$00780000,$00fc0000,$01fe0000,$03ff0000,$07ff8000,$0fffc000
dc.l	$07ffe000,$03fff000,$01fff800,$00fffc00,$007ffe00,$003fff00
dc.l	$001fff80,$000fff00,$0007fe00,$0003fc00,$0001f800,$0000f000
dc.l	$00006000,$00000000,$00000000,$00000000,$00000000,$00000000
dc.l	$00000000,$00000000,$00000000,$00000000,$001fffc0,$003fffc0
dc.l	$007fffc0,$00ffffc0,$01ffffc0,$03ffffc0,$07ffffc0,$0fffffc0
dc.l	$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0
dc.l	$0fffff80,$0fffff00,$0ffffe00,$0ffffc00,$0ffff800,$0ffff000
dc.l	$0fffe000,$00000000,$00000000,$00000000,$00000000,$00000000

dc.l	$00000000,$00000000,$00000000,$00000000,$001fffc0,$003fffc0
dc.l	$007fffc0,$00ffffc0,$01ffffc0,$03ffffc0,$07ffffc0,$0fffffc0
dc.l	$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0
dc.l	$0fffff80,$0fffff00,$0ffffe00,$0ffffc00,$0ffff800,$0ffff000
dc.l	$0fffe000,$00000000,$00000000,$00000000,$00000000,$00000000

Frame3:
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$003ff000
dc.l	$003ff000,$003ff000,$003ff000,$003ff000,$003ff000,$003ff000
dc.l	$003ff000,$003ff000,$003ff000,$003ff000,$003ff000,$003ff000
dc.l	$003ff000,$003ff000,$003ff000,$003ff000,$003ff000,$003ff000
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$007ff800
dc.l	$00fffc00,$01fffe00,$03ffff00,$07ffff80,$0fffffc0,$1fffffe0
dc.l	$3ffffff0,$7ffffff8,$fffffffc,$7ffffff8,$3ffffff0,$1fffffe0
dc.l	$0fffffc0,$07ffff80,$03ffff00,$01fffe00,$00fffc00,$007ff800
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000

dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$007ff800
dc.l	$00fffc00,$01fffe00,$03ffff00,$07ffff80,$0fffffc0,$1fffffe0
dc.l	$3ffffff0,$7ffffff8,$fffffffc,$7ffffff8,$3ffffff0,$1fffffe0
dc.l	$0fffffc0,$07ffff80,$03ffff00,$01fffe00,$00fffc00,$007ff800
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000

Frame4:
dc.l	$00000000,$00000000,$00000000,$00000000,$00006000,$0000f000
dc.l	$0001f800,$0003fc00,$0007fe00,$000fff00,$001fff80,$003fff00
dc.l	$007ffe00,$00fffc00,$01fff800,$03fff000,$07ffe000,$0fffc000
dc.l	$07ff8000,$03ff0000,$01fe0000,$00fc0000,$00780000,$00300000
dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
dc.l	$00000000,$00000000,$00000000,$00000000,$0fffe000,$0ffff000
dc.l    $0ffff800,$0ffffc00,$0ffffe00,$0fffff00,$0fffff80,$0fffffc0
dc.l    $0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0
dc.l	$07ffffc0,$03ffffc0,$01ffffc0,$00ffffc0,$007fffc0,$003fffc0
dc.l	$001fffc0,$00000000,$00000000,$00000000,$00000000,$00000000

dc.l	$00000000,$00000000,$00000000,$00000000,$0fffe000,$0ffff000
dc.l	$0ffff800,$0ffffc00,$0ffffe00,$0fffff00,$0fffff80,$0fffffc0
dc.l	$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0,$0fffffc0
dc.l	$07ffffc0,$03ffffc0,$01ffffc0,$00ffffc0,$007fffc0,$003fffc0
dc.l	$001fffc0,$00000000,$00000000,$00000000,$00000000,$00000000

;****************************************************************************

; This is the buffer in which we save the background each time.
; It has the same dimensions as a blitted image: height 30, width 3 words
; 2 bitplanes

Buffer:
ds.w    30*3*2

; The bitplane contains a 1-plane 320*100 image
BITPLANE:

; plane 1
ds.b    40*56            ; 56 lines
incbin    ‘background320*100.raw’    ; 100 lines
ds.b    40*100            ; 100 lines

ds.b    40*256            ; plane 2

;****************************************************************************

end

In this example, we present a universal routine for drawing bobs.
The routine handles bobs of variable sizes. The position, size
and addresses of the bob's shape and mask are passed as
parameters. Based on the parameters, all the values
to be written to the blitter registers are calculated using the formulas seen previously.
Consequently, the background save and restore routines
have also been modified to handle rectangles of arbitrary size.
 Make sure that the save buffer used by these
routines is large enough to contain the rectangle.
Using these routines, it is possible to create an animated bob in combination
with the animation routine seen in the example lesson10l1.s (cyclic animation
).
Note that the background image only partially occupies the screen, which
is otherwise cleared.


; Lesson 10m2.s    Universal Bob Routine - INTERLEAVED version
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
MOVEQ    #2-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40,d0        ; + line length
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W	#DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:

; parameters for SalvaSfondo routine

move.w    ogg_x(pc),d0        ; X position
move.w    ogg_y(pc),d1        ; Y position
move.w    #32,d2            ; X size
move.w    #30,d3            ; Y size
bsr.w    SalvaSfondo		; save background

; parameters for UniBob routine

move.l    Frametab(pc),a0        ; set pointer to frame
; to be drawn in A0
lea    2*4*30(a0),a1        ; pointer to mask in A1
move.w    ogg_x(pc),d0        ; X position
move.w    ogg_y(pc),d1        ; Y position
move.w    #32,d2            ; X size
move.w    #30,d3            ; Y size
bsr.w    UniBob            ; draw the bob with the routine
; universal

MOVE.L    #$1ff00,d1	; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0
BNE.S    Waity1

; parameters for the RestoreBackground routine

move.w    ogg_x(pc),d0        ; X position
move.w    ogg_y(pc),d1        ; Y position
move.w    #32,d2            ; X size
move.w    #30,d3            ; Y size
bsr.w    RestoreBackground    ; restore background

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
MOVE.L	(a0),d0        ; save the first address in d0
MOVE.L    4(a0),(a0)    ; move the other addresses back
MOVE.L    4*2(a0),4(a0)    ; These instructions ‘rotate’ the addresses
MOVE.L    4*3(a0),4*2(a0) ; in the table.
MOVE.L    d0,4*3(a0)    ; put the former first address in the eighth place

DoNotChange:
rts

CountAnim:
dc.w    0

; This is the frame address table. The addresses
; in the table are ‘rotated’ within the table by the
; Animation routine, so that the first in the list is the first time
; frame1, the next time Frame2, then 3, 4 and again the
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
OGG_X:        dc.w    10    ; the X of the object is stored here

;***************************************************************************
; This is the universal routine for drawing bobs of arbitrary shape and size
;. All parameters are passed via registers.
; The routine works on an INTERLEAVED screen
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
mulu.w	#2*40,d1    ; calculate address: each line consists of
; 2 planes of 40 bytes each
add.l    d1,a2        ; add to address
move.w    d0,d6        ; copy X
lsr.w    #3,d0        ; divide X by 8
and.w    #$fffe,d0    ; make it even
add.w    d0,a2        ; add to the bitplane address, finding
; the correct destination address

and.w    #$000f,d6	; select the first 4 bits of X because
; they must be inserted into the shifter of channels A and B
lsl.w    #8,d6        ; the 4 bits are moved to the high nibble
lsl.w    #4,d6        ; of the word. This is the value of BLTCON1

move.w    d6,d5        ; copy to calculate the value of BLTCON0
or.w    #$0FCA,d5    ; values to put in BLTCON0

; blitter module calculation

lsr.w    #3,d2        ; divide the width by 8
and.w    #$fffe,d2    ; reset bit 0 (make it even)
addq.w    #2,d2		; the blitter is a wider word 
move.w    #40,d4        ; screen width in bytes
sub.w    d2,d4        ; module=screen width-rectangle width

; calculate blitted size

mulu    #2,d3        ; multiply height by number of planes
; (for interleaved screen)
; in this case, since we have 2 planes
; you could use asl, but in general
; (e.g. 3 planes) you must use mulu

lsl.w    #6,d3        ; height by 64
lsr.w    #1,d2        ; width in pixels divided by 16
; i.e. width in words
or    d2,d3        ; put the dimensions together

; initialise the registers
btst    #6,2(a5)
WBlit_u1:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit_u1

move.l    #$ffff0000,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $0000 clears the last word

move.w    d6,$42(a5)        ; BLTCON1 - shift value
; no special mode

move.w    d5,$40(a5)        ; BLTCON0 - shift value
; cookie-cut

move.l    #$fffefffe,$62(a5)    ; BLTBMOD and BLTAMOD=$fffe=-2 return
; back to the beginning of the line.

move.w    d4,$60(a5)        ; BLTCMOD calculated value
move.w    d4,$66(a5)        ; BLTDMOD calculated value

move.l    a1,$50(a5)        ; BLTAPT (mask)
move.l    a2,$54(a5)		; BLTDPT (screen lines)
move.l    a2,$48(a5)        ; BLTCPT (screen lines)
move.l    a0,$4c(a5)        ; BLTBPT (bob figure)
move.w    d3,$58(a5)        ; BLTSIZE (start blitter!)

rts

;****************************************************************************
; This routine copies the background rectangle that will be overwritten by
; BOB into a buffer. The routine handles a bob of arbitrary size.
; If you use this routine for bobs of different sizes, make sure
; that the buffer can hold the largest bob!
; The position and size of the rectangle are parameters
;
; D0 - X coordinate of the upper left vertex
; D1 - Y coordinate of the upper left vertex
; D2 - rectangle width in pixels
; D3 - rectangle height
;****************************************************************************

SaveBackground:
; calculate blitter start address

lea    bitplane,a1    ; bitplane address
mulu.w    #2*40,d1    ; calculate address: each line consists of
; 2 planes of 40 bytes each
add.l    d1,a1        ; add to address
lsr.w    #3,d0		; divide X by 8
and.w    #$fffe,d0    ; make it even
add.w    d0,a1        ; add to the bitplane address, finding
; the correct destination address

; blitter module calculation
lsr.w    #3,d2        ; divide the width by 8
and.w    #$fffe,d2    ; reset bit 0 (make even)
addq.w    #2,d2		; the blitter is 1 word wider
move.w    #40,d4        ; screen width in bytes
sub.w    d2,d4        ; module=screen width-rectangle width

; calculate blitter size
mulu    #2,d3        ; multiply height by number of planes
; (for interleaved screen)
; in this case, since we have 2 planes
; you could use asl, but in general
; (e.g. 3 planes) you must use mulu
lsl.w    #6,d3        ; height for 64
lsr.w    #1,d2        ; width in pixels divided by 16
; i.e. width in words
or    d2,d3        ; put the dimensions together

lea    Buffer,a2    ; destination address

btst    #6,2(a5) ; dmaconr
WBlit3:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit3

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything

move.l	#$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.w    d4,$64(a5)        ; BLTAMOD calculated value
move.w    #$0000,$66(a5)        ; BLTDMOD=0 in the buffer
move.l    a1,$50(a5)        ; BLTAPT - source index
move.l    a2,$54(a5)        ; BLTDPT - buffer
move.w    d3,$58(a5)        ; BLTSIZE (start blitter!)

rts

;****************************************************************************
; This routine copies the contents of the buffer into the screen rectangle
; that contained it before the BOB was drawn. This also
; deletes the BOB from its old position. The routine handles a bob of
; arbitrary size.
; If you use this routine for bobs of different sizes, make sure
; that the buffer can contain the largest bob!
; The position and size of the rectangle are parameters
;
; D0 - X coordinate of the upper left corner
; D1 - Y coordinate of the upper left corner
; D2 - rectangle width in pixels
; D3 - rectangle height
;****************************************************************************

RestoreBackground:
; calculate blitter start address

lea    bitplane,a1	; bitplane address
mulu.w    #2*40,d1    ; calculate address: each row consists of
; 2 planes of 40 bytes each
add.l    d1,a1        ; add to address
lsr.w    #3,d0        ; divide X by 8
and.w    #$fffe,d0    ; make it even
add.w    d0,a1        ; add to the bitplane address, finding
; the correct destination address

; blitter module calculation
lsr.w	#3,d2        ; divide the width by 8
and.w    #$fffe,d2    ; reset bit 0 (make even)
addq.w    #2,d2        ; the blitted image is 1 word wider
move.w	#40,d4        ; screen width in bytes
sub.w    d2,d4        ; module=screen width-rectangle width

; calculate blitted size
mulu    #2,d3        ; multiply height by number of planes
; (for interleaved screen)
; in this case, since we have 2 planes
; we could use asl, but in general
(e.g. 3 planes) you must use mulu
lsl.w    #6,d3        ; height for 64
lsr.w    #1,d2        ; width in pixels divided by 16
; i.e. width in words
or    d2,d3        ; put the dimensions together

lea    Buffer,a2    ; destination address

btst    #6,2(a5) ; dmaconr
WBlit4:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit4

move.l    #$ffffffff,$44(a5)    ; BLTAFWM = $ffff passes everything
; BLTALWM = $ffff passes everything

move.l    #09f00000,$40(a5)    ; BLTCON0 and BLTCON1 copy from A to D
move.w    d4,$66(a5)        ; BLTDMOD calculated value
move.w    #0000,$64(a5)        ; BLTAMOD=0 in buffer
move.l    a2,$50(a5)        ; BLTAPT - buffer
move.l    a1,$54(a5)        ; BLTDPT - screen
move.w    d3,$58(a5)		; BLTSIZE (via al blitter !)

rts


;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,40        ; Bpl1Mod
dc.w    $10a,40        ; Bpl2Mod

dc.w    $100,$2200    ; bplcon0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000

dc.w    $180,$000    ; colour0
dc.w    $182,$00b    ; colour1
dc.w    $184,$cc0    ; colour2
dc.w    $186,$b00    ; colour3

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************
; These are the frames that make up the animation

Frame1:

dc.l    $00000000,$00020000
dc.l    $00000000,$00070000
dc.l    $00000000,$000f8000
dc.l	$00000000,$001fc000
dc.l	$00000000,$003fe000
dc.l	$00000000,$007ff000
dc.l	$00000000,$00fff800
dc.l	$00000000,$01fffc00
dc.l	$00000000,$03fffe00
dc.l	$00000000,$07ffff00
dc.l	$07ffff00,$07ffff00
dc.l	$07ffff00,$07ffff00
dc.l	$07ffff00,$07ffff00
dc.l	$07ffff00,$07ffff00
dc.l	$07ffff00,$07ffff00
dc.l	$07ffff00,$07ffff00
dc.l    $07ffff00,$07ffff00
dc.l    $07ffff00,$07ffff00
dc.l    $07ffff00,$07ffff00
dc.l    $07ffff00,$07ffff00
dc.l	$00000000,$07ffff00
dc.l	$00000000,$03fffe00
dc.l	$00000000,$01fffc00
dc.l	$00000000,$00fff800
dc.l	$00000000,$007ff000
dc.l	$00000000,$003fe000
dc.l	$00000000,$001fc000
dc.l	$00000000,$000f8000
dc.l	$00000000,$00070000
dc.l	$00000000,$00020000

; mask
dc.l    $00020000
dc.l    $00020000
dc.l    $00070000
dc.l    $00070000
dc.l    $000f8000
dc.l    $000f8000
dc.l    $001fc000
dc.l    $001fc000
dc.l    $003fe000
dc.l    $003fe000
dc.l    $007ff000
dc.l    $007ff000
dc.l    $00fff800
dc.l    $00fff800
dc.l    $01fffc00
dc.l    $01fffc00
dc.l    $03fffe00
dc.l    $03fffe00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l    $07ffff00
dc.l	$07ffff00
dc.l	$03fffe00
dc.l	$03fffe00
dc.l	$01fffc00
dc.l	$01fffc00
dc.l	$00fff800
dc.l	$00fff800
dc.l	$007ff000
dc.l    $007ff000
dc.l    $003fe000
dc.l    $003fe000
dc.l    $001fc000
dc.l    $001fc000
dc.l    $000f8000
dc.l    $000f8000
dc.l	$00070000
dc.l	$00070000
dc.l	$00020000
dc.l	$00020000

Frame2:
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$001fffc0
dc.l	$00300000,$003fffc0
dc.l	$00780000,$007fffc0
dc.l	$00fc0000,$00ffffc0
dc.l	$01fe0000,$01ffffc0
dc.l	$03ff0000,$03ffffc0
dc.l	$07ff8000,$07ffffc0
dc.l	$0fffc000,$0fffffc0
dc.l	$07ffe000,$0fffffc0
dc.l	$03fff000,$0fffffc0
dc.l    $01fff800,$0fffffc0
dc.l    $00fffc00,$0fffffc0
dc.l    $007ffe00,$0fffffc0
dc.l    $003fff00,$0fffffc0
dc.l    $001fff80,$0fffff80
dc.l    $000fff00,$0fffff00
dc.l    $0007fe00,$0ffffe00
dc.l	$0003fc00,$0ffffc00
dc.l	$0001f800,$0ffff800
dc.l	$0000f000,$0ffff000
dc.l	$00006000,$0fffe000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000

dc.l	$00000000
dc.l	$00000000
dc.l $00000000
dc.l $00000000
dc.l $00000000
dc.l $00000000
dc.l $00000000
dc.l $00000000
dc.l $001fffc0
dc.l    $001fffc0
dc.l    $003fffc0
dc.l    $003fffc0
dc.l    $007fffc0
dc.l    $007fffc0
dc.l    $00ffffc0
dc.l    $00ffffc0
dc.l    $01ffffc0
dc.l    $01ffffc0
dc.l    $03ffffc0
dc.l    $03ffffc0
dc.l    $07ffffc0
dc.l    $07ffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l $0fffffc0
dc.l $0fffffc0
dc.l $0fffffc0
dc.l $0fffffc0
dc.l $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffff80
dc.l    $0fffff80
dc.l    $0fffff00
dc.l    $0fffff00
dc.l    $0ffffe00
dc.l    $0ffffe00
dc.l    $0ffffc00
dc.l    $0ffffc00
dc.l    $0ffff800
dc.l    $0ffff800
dc.l    $0ffff000
dc.l    $0ffff000
dc.l    $0fffe000
dc.l    $0fffe000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000

Frame3:

dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$003ff000,$007ff800
dc.l	$003ff000,$00fffc00
dc.l	$003ff000,$01fffe00
dc.l    $003ff000,$03ffff00
dc.l    $003ff000,$07ffff80
dc.l    $003ff000,$0fffffc0
dc.l    $003ff000,$1fffffe0
dc.l    $003ff000,$3ffffff0
dc.l    $003ff000,$7ffffff8
dc.l    $003ff000,$fffffffc
dc.l    $003ff000,$7ffffff8
dc.l    $003ff000,$3ffffff0
dc.l	$003ff000,$1fffffe0
dc.l	$003ff000,$0fffffc0
dc.l	$003ff000,$07ffff80
dc.l	$003ff000,$03ffff00
dc.l	$003ff000,$01fffe00
dc.l	$003ff000,$00fffc00
dc.l	$003ff000,$007ff800
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000

dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l $00000000
dc.l $00000000
dc.l $007ff800
dc.l $007ff800
dc.l $00fffc00
dc.l $00fffc00
dc.l    $01fffe00
dc.l    $01fffe00
dc.l    $03ffff00
dc.l    $03ffff00
dc.l    $07ffff80
dc.l    $07ffff80
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $1fffffe0
dc.l    $1fffffe0
dc.l    $3ffffff0
dc.l    $3ffffff0
dc.l    $7ffffff8
dc.l    $7ffffff8
dc.l    $fffffffc
dc.l    $fffffffc
dc.l    $7ffffff8
dc.l    $7ffffff8
dc.l    $3ffffff0
dc.l    $3ffffff0
dc.l    $1fffffe0
dc.l    $1fffffe0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $07ffff80
dc.l    $07ffff80
dc.l    $03ffff00
dc.l    $03ffff00
dc.l    $01fffe00
dc.l    $01fffe00
dc.l    $00fffc00
dc.l    $00fffc00
dc.l    $007ff800
dc.l    $007ff800
dc.l    $00000000
dc.l $00000000
dc.l $00000000
dc.l $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000

Frame4:

dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00006000,$0fffe000
dc.l	$0000f000,$0ffff000
dc.l	$0001f800,$0ffff800
dc.l	$0003fc00,$0ffffc00
dc.l	$0007fe00,$0ffffe00
dc.l	$000fff00,$0fffff00
dc.l	$001fff80,$0fffff80
dc.l    $003fff00,$0fffffc0
dc.l    $007ffe00,$0fffffc0
dc.l    $00fffc00,$0fffffc0
dc.l    $01fff800,$0fffffc0
dc.l	$03fff000,$0fffffc0
dc.l	$07ffe000,$0fffffc0
dc.l	$0fffc000,$0fffffc0
dc.l	$07ff8000,$07ffffc0
dc.l	$03ff0000,$03ffffc0
dc.l	$01fe0000,$01ffffc0
dc.l	$00fc0000,$00ffffc0
dc.l	$00780000,$007fffc0
dc.l	$00300000,$003fffc0
dc.l	$00000000,$001fffc0
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l	$00000000,$00000000
dc.l    $00000000,$00000000

dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $0fffe000
dc.l    $0fffe000
dc.l    $0ffff000
dc.l    $0ffff000
dc.l    $0ffff800
dc.l    $0ffff800
dc.l    $0ffffc00
dc.l    $0ffffc00
dc.l    $0ffffe00
dc.l    $0ffffe00
dc.l    $0fffff00
dc.l    $0fffff00
dc.l    $0fffff80
dc.l    $0fffff80
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $0fffffc0
dc.l    $07ffffc0
dc.l    $07ffffc0
dc.l    $03ffffc0
dc.l    $03ffffc0
dc.l    $01ffffc0
dc.l    $01ffffc0
dc.l    $00ffffc0
dc.l    $00ffffc0
dc.l    $007fffc0
dc.l    $007fffc0
dc.l    $003fffc0
dc.l    $003fffc0
dc.l    $001fffc0
dc.l    $001fffc0
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l    $00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000
dc.l	$00000000

;****************************************************************************

SECTION    bitplane,BSS_C

; This is the buffer in which we save the background each time.
; It has the same dimensions as a blited image: height 30, width 3 words
; 2 bitplanes

Buffer:
ds.w    30*3*2

BITPLANE:

; 2 planes 
ds.b	40*256
ds.b	40*256

;****************************************************************************

end

In this example, we show the rawblit version of the universal routine
for drawing bobs. The programme is identical to lesson10m1.s, except
that a rawblit screen is used and, as you know, the formulas for calculating the values to be written in the registers are slightly different.
the formulas for calculating the values to be written in the registers change slightly.
Even though we are not using a background image in this case, the routines
still perform the save and restore operations. You can draw
your own background image (in rawblit version) and insert it without modifying
the source code!

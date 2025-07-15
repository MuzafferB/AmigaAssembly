
; Sprite animation to make ‘magic’ stars
; Original version: Author unknown
; Fixed version: Randy/Ram Jam

SECTION    stars6,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110100000    ; copper,bitplane,sprites

Waitdisk    EQU    10

START:

; Point the biplane to zero

MOVE.L    #PLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERSTELL,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Let's start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $010
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $010
Beq.S    Waity2

btst    #2,$16(A5)    ; Right button pressed?
beq.s    NonStell

bsr.s    Stellozze

NonStell:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse
rts

*****************************************************************************
; Routine that points to the right sprites to create the ‘magic stars’ effect
*****************************************************************************

WaitTime    =    2    ; 0 = max speed

Stellozze:
MOVEQ    #8-1,D0        ; number of sprites: 8
LEA    SpritePosXYTab(PC),A0    ; This address is used for two
; tables: with positive offsets,
; you access the table of
; XY positions in ‘control words’ format,
; while with negative offsets,
; you access the table used to make
; the random-like animation

LEA    COPSPR,A1    ; pointers to sprites in COPPERLIST
FaiUnoSpriteLoop:

; Let's slow down the execution a little...

SUBQ.B    #1,-8(A0,D0.W)    ; subtract 1 from the wait time
BPL.S    NonAncZero    ; not = 0 yet?
MOVE.B    #WaitTime,-8(A0,D0.W)    ; reset the wait time

; Now let's cycle the values and frames from the anitab

MOVEQ    #0,D1
MOVEQ    #0,D2
MOVE.B    -16(A0,D0.W),D1    ; val1
MOVE.B    -24(A0,D0.W),D2    ; val2
ADDQ.W    #1,D1        ; val1+1
CMP.B    #13,D1        ; are we at 13? (maximum frame)
BLT.S	NonMax1        ; if not yet, OK
MOVEQ    #0,D1        ; if yes, start again from zero
ADDQ.W    #1,D2
CMP.B    #45,D2        ; Are we at 45? (maximum pair of words of
; SpritePosXYTab control)
BLT.S    NonMax2        ; if not yet, OK
MOVEQ    #0,D2        ; yes?, start again from zero! (or we go out of tab)
NonMax2:
MOVE.B    D2,-24(A0,D0.W)    ; save the value (current XY position from tab)
NonMax1:
MOVE.B    D1,-16(A0,D0.W)	; save the value

; Now we need to find the right frame (sprite)

MULU.W    #68,D1        ; current frame * length 1 frame,
; and we get the offset from the start of the
; right spriteanim
MOVE.W    D0,D3        ; current sprite number in d3
MULU.W	#13*68,D3    ; * length 1 spriteanim = offset for the
; correct spriteanim
ADD.L    #AnimSprites-2,D1 ; frame offset + AnimSprites address
ADD.L    D3,D1        ; + sprite anim offset = correct address!!!

; We have the address of the correct sprite in d1... but we need to change
; its X and Y position (HSTART/VSTART), taking these values from the
; SpritePosXYTab table, which already contains them in the form of 2 control words
; ready to use. In d2 we have the value to take from the table... d2*4 for the offset!

MOVE.L    D1,A2        ; copy the address of the correct sprite to a2
ADD.W    D2,D2        ;\ d2*4, in fact each element of the table
ADD.W    D2,D2        ;/ is 2 words long (4 bytes)
MOVE.L    0(A0,D2.W),(A2) ; SpritePosXYTab + offset ok in the 2 words of
; control of the right sprite.

; Now we have in d1 the address of the right sprite to point to.... let's point to it!

MOVE.W    D0,D3        ; current sprite number in d3...
ASL.W    #3,D3        ; d3 * 8, to find the offset from the first
; pointer in the copperlist, in fact each
; pointer occupies 8 bytes.....
MOVE.W    D1,6(A1,D3.W)    ; points to high word address sprite in cop,
; in fact: a1(first pointer)+d3(offset from
SWAP    D1        ; (first pointer)=correct pointer address!
MOVE.W    D1,2(A1,D3.W)    ; points to lower word
NonAncZero:
DBRA    D0,FaiUnoSpriteLoop
RTS



; 24 bytes (3*8)

Anitab:
dc.b    34,8,28,41,19,16,42,26    ; table with mixed values for
dc.b    0,7,7,1,6,7,11,4    ; to allow ‘similar’ animation
dc.b    1,1,0,0,2,2,2,1		; random stars.
SpritePosXYTab:
DC.W    $2770,$3600,$434B,$5200,$7F43,$8E00    ; table with words
DC.W    $874B,$9600,$8655,$9500,$6F62,$7E00    ; control with the
DC.W    $4362,$5200,$416C,$5000,$6060,$6F00    ; various X Y positions
DC.W    $6569,$7400,$6B66,$7A00,$4A70,$5900    ; for sprites.
DC.W    $646F,$7300,$3978,$4800,$577D,$6600    ; note: 45 pairs
DC.W	$6078,$6F00,$3687,$4500,$3891,$4700
DC.W	$438B,$5200,$538D,$6200,$5D87,$6C00
DC.W	$2C91,$3B00,$2E96,$3D00,$4F92,$5E00
DC.W	$5E96,$6D00,$3A9A,$4900,$39A1,$4800
DC.W	$46A8,$5500,$599E,$6800,$61A2,$7000
DC.W	$5AA5,$6900,$43AB,$5200,$44B3,$5300
DC.W	$65B0,$7400,$4FB8,$5E00,$6DBC,$7C00
DC.W	$28B8,$3700,$33BE,$4200,$3EC4,$4D00
DC.W	$49CA,$5800,$49BB,$5800,$72BF,$8100
DC.W	$7CC5,$8B00,$82D5,$9100,$86CE,$9500

*****************************************************************************

section    copper,data_C

COPPERSTELL:
dc.w    $8e,$2c81    ; diwstart
dc.w    $90,$2cc1    ; diwstop
dc.w    $92,$38        ; ddfstart
dc.w    $94,$d0        ; ddfstop

COPSPR:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0,$12a,0,$12c,0,$12e,0
dc.w	$130,0,$132,0,$134,0,$136,0,$138,0,$13a,0,$13c,0,$13e,0

dc.w    $108,0    ; bpl1mod
dc.w    $10a,0    ; bpl2mod
dc.w    $102,0    ; bplcon1
dc.w    $104,0    ; bplcon2

BPLPOINTERS:
dc.w    $e0,0,$e2,0    ; plane 1

dc.w    $100,$1200    ; bplcon0 - 1 plane lowres

dc.w    $180,0        ; colour0 - black
dc.w    $182,$fff    ; colour1 - white

DC.W    $180,$000,$182,$000

; Sprite colours - from colour17 to colour31

DC.W    $1A2,$F00,$1A4,$A00,$1A6,$600
DC.W    $1A8,$000,$1AA,$0F0,$1AC,$0A0
DC.W	$1AE,$060,$1B0,$000,$1B2,$00F
DC.W	$1B4,$00A,$1B6,$006,$1B8,$000
DC.W	$1BA,$FFF,$1BC,$AAA,$1BE,$666

dc.w	$ffff,$fffe	; fine copperlist

*****************************************************************************

; 68*13*8    i.e. 68 bytes per frame * 13 frames * 8 spriteanim

dc.w    0    ; write here too! the high word... that's all
; offset by 1 word... don't ask me why!
AnimSprites:
incbin    ‘spranim1’    ; 13 frames
incbin    “spranim2”    ; 13 frames
incbin    ‘spranim3’	; 13 frames
incbin    ‘spranim4’    ; 13 frames
incbin    ‘spranim5’    ; 13 frames
incbin    ‘spranim6’    ; 13 frames
incbin    “spranim7”    ; 13 frames
incbin    ‘spranim8’    ; 13 frames

; ****************************************************************************

section    graphics,bss_C

plane:
ds.b    40*256    ; 1 low-resolution plane ‘black’ as background.

end


; lesson7x3.s    - Collisions between playfields in Dual Playfield mode
; In this example, we show collisions between the two playfields.
; Playfield 1 moves from top to bottom.
; If colour 3 of playfield 1 overlaps colour 1 of playfield 2
; a collision is detected and the background colour is changed

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

; Use 2 planes for each playfield

;    Point to the PICs

MOVE.L    #PIC1,d0    ; point to playfield 1
LEA    BPLPOINTERS1,A1
MOVEQ    #2-1,D1
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP

MOVE.L    #PIC2,d0    ; point to playfield 2
LEA    BPLPOINTERS2,A1
MOVEQ    #2-1,D1
POINTBP2:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP2

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

move.w    #$0024,$dff104    ; BPLCON2
; with this value, all sprites are
; above both playfields

wait1:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    wait1
wait11:
cmpi.b    #$ff,$dff006    ; Still Line 255?
beq.s    wait11

btst    #6,$bfe001
beq.s    exit

bsr.s    MoveCopper    ; Moves playfield 1
bsr.w    CheckColl    ; Checks for collision and takes action

bra.s    wait1

exit    move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr    -$19e(a6)    ; Close library
rts

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:
dc.l    0

OldCop:
dc.l    0


; This routine moves a playfield down. It is the same as in lesson 5
; except that we only move playfield 1, i.e. only the odd bitplanes. 

MoveCopper:
LEA    BPLPOINTERS1,A1    ; With these 4 instructions we retrieve from
move.w	2(a1),d0    ; copperlist the address where it is pointing
swap    d0        ; currently $dff0e0 and we place it
move.w    6(a1),d0    ; in d0 - the opposite of the routine that
; points to the bitplanes! Here, instead of putting
; the address, we take it!!!

TST.B	SuGiu        ; Do we need to go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then we jump to VAIGIU, if instead it is at $FF
; (i.e. if this TST is not verified)
; we continue going up (doing subs)
beq.w    VAIGIU
cmp.l    #PIC1-(40*90),d0    ; Are we high enough?
beq.s    MettiGiu    ; If so, we are at the top and must go down
sub.l    #40,d0        ; Subtract 40, i.e. 1 line, causing
; the figure to scroll DOWN
bra.s    Finito

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
bra.s    Finito        ; will jump to the VAIGIU routine

VAIGIU:
cmpi.l    #PIC1+(40*30),d0    ; have we gone LOW enough?
beq.s    MettiSu        ; if so, we are at the bottom and we have to go back up
add.l    #40,d0        ; Add 40, i.e. 1 line, by
; scrolling UP the figure
bra.s    finished

MettiSu:
move.b    #$ff,SuGiu    ; When the SuGiu label is not zero,
rts            ; it means we have to go back up.

Finito:                ; POINT THE BITPLANE POINTERS
LEA    BPLPOINTERS1,A1    ; pointers in the COPPERLIST
MOVEQ    #1,D1        ; number of bitplanes -1 (there are 2 here)
POINTBP3:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)	; copy the HIGH word of the plane swap address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w	#8,a1        ; go to the next bplpointers in COP
dbra    d1,POINTBP3    ; Repeat POINTBP times D1 (D1=number of bitplanes)
rts


;    This byte, indicated by the label SuGiu, is a FLAG.

SuGiu:
dc.b    0,0


; This routine checks for collisions.
; If there is one, it changes the background colour
; by modifying the value assumed by the COLOR00 register in the copper list.

CheckColl:
move.w    $dff00e,d0    ; reads CLXDAT ($dff00e)
; reading this register also causes
; it to be deleted, so it is best to
; copy it to d0 and test d0
btst.l    #0,d0        ; bit 0 indicates a collision between playfields
beq.s    no_coll        ; if there is no collision, jump

move.w	#$f00,detect_collision ; ‘turns on’ the detector (colour0)
; modifying the copperlist (red)
bra.s    ExitColl

no_coll:
move.w    #$000,detect_collision ; ‘turns off’ the detector (colour0)
; modifying the copperlist (black)
ExitColl:
rts

flag:
dc.w    0
height:
dc.w    $2c



SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0100011000000000    ; bit 10 on = dual playfield
; use 4 planes = 4 colours per playfield

BPLPOINTERS1:
dc.w $e0,0,$e2,0    ;first bitplane playfield 1 (BPLPT1)
dc.w $e8,0,$ea,0    ;second bitplane playfield 1 (BPLPT3)


BPLPOINTERS2:
dc.w $e4,0,$e6,0    ;first bitplane playfield 2 (BPLPT2)
dc.w $ec,0,$ee,0    ;second bitplane playfield 2 (BPLPT4)

; This is the CLXCON register (controls the detection mode)

; bits 0 to 5 are the values that must be assumed by the planes
; bits 6 to 11 indicate which planes are enabled for collisions
; bits 12 to 15 indicate which of the odd sprites are enabled
; for collision detection.

;5432109876543210
dc.w    $98,%0000001111000111    ; CLXCON

; Planes 1,2,3,4 are active for collisions (bits 6,7,8,9).
; A collision between playfields is signalled when they overlap
; a pixel that has:    plane 1 = 1 (bit 0)
;         plane 3 = 1 (bit 2)
; i.e. with colour 3 of playfield 1
; and a pixel that has:    plane 2 = 1 (bit 1)
;         plane 4 = 0 (bit 3)
; i.e. with colour 1 of playfield 2


dc.w    $180 ; COLOR00
detect_collision:
dc.w    0    ; AT THIS POINT the CheckColl routine modifies
; the copper list by writing the correct colour.

; playfield 1 palette
dc.w    $182,$005    ; colours from 0 to 7
dc.w    $184,$a40
dc.w    $186,$f80
dc.w    $188,$f00
dc.w    $18a,$0f0
dc.w    $18c,$00f
dc.w    $18e,$080


; playfield palette 2
dc.w    $192,$367	; colours from 9 to 15
dc.w    $194,$0cc     ; colour 8 is transparent, do not set
dc.w    $196,$a0a
dc.w    $198,$242
dc.w    $19a,$282
dc.w    $19c,$861
dc.w    $19e,$ff0

dc.w    $FFFF,$FFFE    ; End of copperlist

dcb.b    40*90,0    ; this space set to zero is needed because when we move
; to view lower and higher, we exit
the PIC1 area and display what is
before and after the PIC itself, which would cause
scattered bytes of noise to be displayed.
By putting zero bytes at that point,
$0000 is displayed, which is the background colour.

PIC1:    incbin    ‘colldual1.raw’
dcb.b    40*30,0    ; see above

PIC2:    incbin    ‘colldual2.raw’

end

In this example, we show the collision between two playfields. The mechanism is
the same as for collisions between sprites. The CLXCON register is used to
indicate which planes are active for collision detection. As
usual, it is possible to indicate which planes are active and what values
they must take for the collision to be detected.
In the example, we detect collisions between colour 3 of playfield 1 and colour 1 
of playfield 2. If you modify the copperlist by changing the value of CLXCON,
you can reveal other types of collision. For example, try this:

dc.w    $98,%0000001111000110	; CLXCON

Planes 1, 2, 3, and 4 are active for collisions (bits 6, 7, 8, and 9).
A collision between playfields is reported when they overlap
a pixel that has:    plane 1 = 0 (bit 0)
plane 3 = 1 (bit 2)
i.e., colour 2 of playfield 1
and a pixel that has:    plane 2 = 1 (bit 1)
plane 4 = 0 (bit 3)
i.e. colour 1 of playfield 2

You can detect collisions between multiple colours by disabling some planes.
Example:

dc.w    $98,%0000001011000011    ; CLXCON

Planes 1, 2 and 4 are active for collisions (bits 6, 7 and 9).
As for playfield 2, both planes are active, therefore
pixels that have the following will be considered:    plane 2 = 1 (bit 1)
plane 4 = 0 (bit 3)
i.e. colour 1 of playfield 2

As for playfield 1, only plane 1 is enabled
and the value of plane 3 is irrelevant.
Both pixels that have:    plane 0 = 1 (bit 0)
plane 3 = 0 (bit 2)
and pixels that have:     plane 0 = 1 (bit 0)
plane 3 = 1 (bit 2)

That is, both colour 1 of playfield 1 and colour 3
of playfield 1 are considered.

For the actual detection, a CLXDAT bit is used as usual.
In this case, it is bit 0. If it is 1, there is a collision between the colours 
specified with CLXCON, otherwise there is no collision.

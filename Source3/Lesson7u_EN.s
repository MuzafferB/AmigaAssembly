
; lesson7u.s - EXAMPLE Double Playfield
; This is a simple example of dual playfield mode.
; The two playfields are displayed. Pressing the right button changes
; the priority of the two playfields. Left to exit
; Pay attention to the copperlist, because the main differences between
Dual Playfield mode and normal mode are in the BPLPOINTERS and colours.


SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

;    Point to the PICs

MOVE.L    #PIC1,d0    ; point to playfield 1
LEA    BPLPOINTERS1,A1
MOVEQ    #3-1,D1
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L	#40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP

MOVE.L    #PIC2,d0    ; point to playfield 2
LEA    BPLPOINTERS2,A1
MOVEQ    #3-1,D1
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

mouse1:
btst    #2,$dff016    ; mouse pressed?
bne.s    mouse2

bchg.b    #6,BPLCON2    ; swap priority by acting on bit 6
; of $dff104

mouse2:
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse1

move.l    OldCop(PC),$dff080    ; Point to the system cop
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


SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w    $12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w    $134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w    $13e,0


dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1

dc.w    $104        ; BplCon2
dc.b    0
BPLCON2:
dc.b    0		; priority between playfields: bit 6

dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0110011000000000    ; bit 10 on = dual playfield
; use 6 planes = 8 colours per playfield

BPLPOINTERS1:
dc.w $e0,0,$e2,0    ;first bitplane playfield 1 (BPLPT1)
dc.w $e8,0,$ea,0    ;second bitplane playfield 1 (BPLPT3)
dc.w $f0,0,$f2,0    ;third bitplane playfield 1 (BPLPT5)


BPLPOINTERS2:
dc.w $e4,0,$e6,0    ;first bitplane playfield 2 (BPLPT2)
dc.w $ec,0,$ee,0    ;second bitplane playfield 2 (BPLPT4)
dc.w $f4,0,$f6,0    ;third bitplane playfield 2 (BPLPT6)

dc.w    $180,$0f0    ; palette playfield 1
dc.w    $182,$005    ; colours from 0 to 7
dc.w    $184,$a40
dc.w    $186,$f80
dc.w    $188,$f00
dc.w    $18a,$0f0
dc.w    $18c,$00f
dc.w    $18e,$080

; palette playfield 2
dc.w    $192,$367    ; colours from 9 to 15
dc.w    $194,$0cc     ; colour 8 is transparent, do not set
dc.w    $196,$a0a
dc.w    $198,$242
dc.w    $19a,$282
dc.w    $19c,$861
dc.w    $19e,$ff0

dc.w    $FFFF,$FFFE    ; End of copperlist

;    Here are the figures for the 2 playfields

PIC1:    incbin    ‘dual1.raw’
PIC2:    incbin    ‘dual2.raw’

end

This is a simple example of using dual-playfield mode. To 
display a dual playfield screen, you perform more or less the same
operations. Just keep in mind that when pointing the bit planes, the 
odd ones point to one playfield and the even ones to the other. Therefore, 
two separate routines are usually used, and even in the copperlist the odd bit planes are 
separated from the even ones. As for colours, each playfield has its own 
palette. Colours 0 and 8 act as transparent, i.e. they allow you to see what is 
below, in the same way as the transparent sprites.
 However, colour 0 also acts as a background, in the sense that in areas of the screen where both
playfields are transparent, colour 0 is ALWAYS displayed, 
regardless of the priority of the two playfields. For this reason, 
colour 0 must always be set, while it is useless to set colour 8.
The priority of the two playfields is controlled by bit 6 of the BPLCON2 register
($dff104): if the bit is 0, playfield 1 appears above playfield 2, and vice versa if the 
bit is 1.

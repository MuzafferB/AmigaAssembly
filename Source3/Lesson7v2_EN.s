
; lesson7v2.s - Sprites in Dual Playfield mode
; In this example, we show the various priority levels for sprites
; with respect to the two playfields. The sprites move from top to bottom.
; Each time they reach the bottom edge, they start again from the top with a
; different priority level. Wait for the program to end.

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

MOVE.L	#PIC1,d0    ; point to playfield 1
LEA    BPLPOINTERS1,A1
MOVEQ    #3-1,D1
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
MOVEQ    #3-1,D1
POINTBP2:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0
addq.w    #8,a1
dbra    d1,POINTBP2

;    Point to the sprites

MOVE.L    #MIOSPRITE0,d0        ; sprite address in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE1,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE2,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE3,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE4,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE5,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L	#MIOSPRITE6,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
MOVE.L    #MIOSPRITE7,d0        ; sprite address in d0
addq.w    #8,a1            ; next SPRITEPOINTERS
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088		; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

lea    PriList(PC),a0    ; a0 points to the list of priority values

move.w    #$0000,$dff104	; BPLCON2
; with this value, all sprites are
; below both playfields

wait1:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    wait1

bsr.s    MoveSprites    ; Moves sprites down

wait2:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    wait2

cmp.w    #250,height    ; have the sprites reached the bottom edge?
blo.s    wait1    ; no, keep moving them

move.w    #$2c,height    ; yes. Put the sprites back at the top
cmp.l    #EndPriList,a0    ; have we finished the priority values?
beq.s    exit        ; if yes, exit.
move.w    (a0)+,$dff104    ; if not, put the next value in BPLCON2
bra.s    wait1


exit    move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

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

; This routine moves the 8 sprites down one pixel at a time
; All sprites have the same height

MoveSprites:

; move sprite 0

addq.w    #1,height
move.w    height(PC),d0

CLR.B    VHBITS0        ; clear bit 8 of the vertical positions
MOVE.b    d0,VSTART0    ; copy bits 0 to 7 to VSTART
BTST.l    #8,D0        ; is the position greater than 255?
BEQ.S    NOBIGVSTART    ; if not, go further, because the bit has already been
; reset with CLR.b VHBITS

BSET.b    #2,VHBITS0    ; otherwise set bit 8 of the
; starting vertical position

NOBIGVSTART:
ADDQ.W    #8,D0        ; Add the length of the sprite to
; determine the final position (VSTOP)
move.b    d0,VSTOP0	; Move bits 0 to 7 to VSTOP
BTST.l    #8,D0        ; Is the position greater than 255?
BEQ.S    NOBIGVSTOP    ; If not, go further, because the bit has already been 
; reset with CLR.b VHBITS

BSET.b    #1,VHBITS0    ; otherwise set bit 8 of the vertical position
; of the sprite end to 1
NOBIGVSTOP:

; copy the height to the other sprites

move.b    vstart0,vstart1    ; copy vstart
move.w    vstop0,vstop1    ; copy VSTOP and VHBITS

move.b    vstart0,vstart2    ; copy vstart
move.w    vstop0,vstop2    ; copy VSTOP and VHBITS

move.b    vstart0,vstart3    ; copy vstart
move.w    vstop0,vstop3    ; copy VSTOP and VHBITS

move.b    vstart0,vstart4	; copy vstart
move.w    vstop0,vstop4    ; copy VSTOP and VHBITS

move.b    vstart0,vstart5    ; copy vstart
move.w    vstop0,vstop5    ; copy VSTOP and VHBITS

move.b    vstart0,vstart6    ; copy vstart
move.w    vstop0,vstop6    ; copy VSTOP and VHBITS

move.b    vstart0,vstart7    ; copy vstart
move.w    vstop0,vstop7    ; copy VSTOP and VHBITS

EndMuovisprites:
rts

height:
dc.w    $2c

; This is the list of priority values. You can change it as you wish.
; However, after the last value there must be the label EndPriList
; These values will be written in BPLCON2. Note that unlike
; the example in lesson7w1.s, here we are using a dual playfield screen, and
; therefore we can use a different priority level for each playfield
;
; Remember that the priorities among sprites are fixed and in descending order
;: sprite 0 has the highest priority, 7 the lowest.

PriList:
dc.w    $0008    ; %001000 - with this value, the priorities are:
; playfield 1 (above everything)
; sprites 0 and 1
; playfield 2
; sprites 2,3,4,5,6,7 (below everything)

dc.w    $0010    ; %010000 - with this value, the priorities are:
; playfield 1 (above everything)
; sprite 0,1,2,3
; playfield 2
; sprite 4,5,6,7 (below everything)

dc.w    $0018    ; %011000 - with this value, the priorities are:
; playfield 1 (above everything)
; sprite 0,1,2,3,4,5
; playfield 2
; sprite 6,7 (below everything)

dc.w    $0020    ; %100000 - with this value, the priorities are:
; playfield 1 (above everything)
; sprite 0,1,2,3,4,5,6,7
; playfield 2

dc.w    $0021    ; %100001 - with this value, the priorities are:
; sprite 0 and 1 (above everything)
; playfield 1
; sprite 2,3,4,5,6,7
; playfield 2 (below everything)

dc.w    $0022    ; %100010 - with this value, the priorities are:
; sprite 0,1,2,3 (above everything)
; playfield 1
; sprite 4,5,6,7
; playfield 2 (below everything)

dc.w    $0023    ; %100011 - with this value, the priorities are:
; sprite 0,1,2,3,4,5 (above everything)
; playfield 1
; sprite 6,7
; playfield 2 (below everything)

dc.w    $0024    ; %100100 - with this value, the priorities are:
; sprite 0,1,2,3,4,5,6,7 (above everything)
; playfield 1
; playfield 2 (below everything)
EndPriList:



SECTION    GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0


dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop

;    we have removed BPLCON2 from the Copperlist, since we vary it
;    with the processor ‘manually’.

dc.w    $102,0        ; BplCon1
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

dc.w    $180,$110    ; playfield palette 1
dc.w    $182,$005    ; colours from 0 to 7
dc.w    $184,$a40
dc.w    $186,$f80
dc.w    $188,$f00
dc.w	$18a,$0f0 
dc.w    $18c,$00f
dc.w    $18e,$080


; playfield palette 2
dc.w    $192,$367    ; colours from 9 to 15
dc.w    $194,$0cc     ; colour 8 is transparent, do not set
dc.w    $196,$a0a
dc.w    $198,$242
dc.w    $19a,$282
dc.w    $19c,$861
dc.w    $19e,$ff0


dc.w    $1A2,$F00    ; sprite palette
dc.w    $1A4,$0F0
dc.w    $1A6,$FF0

dc.w    $1AA,$FFF
dc.w    $1AC,$0BD
dc.w    $1AE,$D50

dc.w    $1B2,$00F
dc.w    $1B4,$F0F
dc.w    $1B6,$BBB

dc.w    $1BA,$8E0
dc.w    $1BC,$a70
dc.w    $1BE,$d00

dc.w    $FFFF,$FFFE    ; End of copperlist


;    The two playfields


PIC1:    incbin    ‘dual1.raw’
PIC2:    incbin    ‘dual2.raw’

; ************ Here are the sprites: OBVIOUSLY in CHIP RAM! ************
MIOSPRITE0:
VSTART0:
dc.b $60
HSTART0:
dc.b $60
VSTOP0:
dc.b $68
VHBITS0
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001110001111
dc.w	%0011111111111100,%1100010001000011
dc.w	%0111111111111110,%1000010001000001
dc.w	%0111111111111110,%1000010001000001
dc.w	%0011111111111100,%1100010001000011
dc.w	%0000111111110000,%1111001110001111
dc.w    %0000001111000000,%0111110000111110
dc.w    0,0


MIOSPRITE1:
VSTART1:
dc.b $60
HSTART1:
dc.b $60+14
VSTOP1:
dc.b $68
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000010001111
dc.w	%0011111111111100,%1100000110000011
dc.w	%0111111111111110,%1000000010000001
dc.w	%0111111111111110,%1000000010000001
dc.w	%0011111111111100,%1100000010000011
dc.w	%0000111111110000,%1111000111001111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0

MIOSPRITE2:
VSTART2:
dc.b $60
HSTART2:
dc.b $60+(14*2)
VSTOP2:
dc.b $68
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111000111001111
dc.w	%0011111111111100,%1100001000100011
dc.w	%0111111111111110,%1000000000100001
dc.w	%0111111111111110,%1000000111000001
dc.w	%0011111111111100,%1100001000000011
dc.w	%0000111111110000,%1111001111101111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0

MIOSPRITE3:
VSTART3:
dc.b $60
HSTART3:
dc.b $60+(14*3)
VSTOP3:
dc.b $68
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111101111
dc.w	%0011111111111100,%1100000000100011
dc.w	%0111111111111110,%1000000111100001
dc.w	%0111111111111110,%1000000000100001
dc.w	%0011111111111100,%1100000000100011
dc.w	%0000111111110000,%1111001111101111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0


MIOSPRITE4:
VSTART4:
dc.b $60
HSTART4:
dc.b $60+(14*4)
VSTOP4:
dc.b $68
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001001001111
dc.w	%0011111111111100,%1100001001000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111000001001111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0

MIOSPRITE5:
VSTART5:
dc.b $60
HSTART5:
dc.b $60+(14*5)
VSTOP5:
dc.b $68
dc.b $00
dc.w    %0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100001000000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111001111001111
dc.w	%0000001111000000,%0111110000111110
dc.w    0.0

MIOSPRITE6:
VSTART6:
dc.b $60
HSTART6:
dc.b $60+(14*6)
VSTOP6:
dc.b $68
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100001000000011
dc.w	%0111111111111110,%1000001111000001
dc.w	%0111111111111110,%1000001001000001
dc.w	%0011111111111100,%1100001001000011
dc.w	%0000111111110000,%1111001111001111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0

MIOSPRITE7:
VSTART7:
dc.b $60
HSTART7:
dc.b $60+(14*7)
VSTOP7:
dc.b $68
dc.b $00
dc.w	%0000001111000000,%0111110000111110
dc.w	%0000111111110000,%1111001111001111
dc.w	%0011111111111100,%1100000001000011
dc.w	%0111111111111110,%1000000001000001
dc.w	%0111111111111110,%1000000001000001
dc.w	%0011111111111100,%1100000001000011
dc.w	%0000111111110000,%1111000001001111
dc.w	%0000001111000000,%0111110000111110
dc.w	0,0

end

This example shows how sprite priorities work with
a dual playfield screen. You can set a different priority level for each playfield
.
For this example, we used a list of priority values.
A list is basically a series of values, like a TABLE.
With an address register (in this case a0), we point to the first value with
the instruction:

lea PriList(PC),a0

Each time a value is read, the a0 register is moved to point to
the next value, using indirect addressing with post-increment,
i.e.:

move.w    (a0)+,$dff104    ; We put the value in BPLCON2

When we reach the last value, a0 is made to point to the
memory address following the last value. This address is the value of the
label EndPriList. When a0 becomes equal to EndPriList, we have
reached the end of the list, and therefore exit the program.

You can change the values in the list, experimenting with various priority levels.
For example, if you try $0011, you will see sprites 0 and 1 above both playfields, sprites 2 and 3 above playfield 2 and below playfield 1, while the other sprites will be below both playfields.
NOTE: In this example, we change the priority by writing directly to the $dff104 (BPLCON2) register. This was made possible by removing the definition of this register from the copperlist, i.e. the line

NOTE: In this example, we change the priority by writing directly to the
register $dff104 (BPLCON2). This was made possible by removing the
definition of this register from the copperlist, i.e. the line:

dc.w    $104,0    ; BPLCON2

If you try to put this copper instruction back in its place, the effect will be cancelled, precisely because the copperlist is executed every frame
and with it BPLCON2 is reset.
You can therefore decide to modify certain registers with the copperlist and certain others directly with the processor, but I recommend modifying them with the copper when possible, since you can synchronise the moment and the line better.
You can therefore decide to modify certain registers with the copperlist
and certain others directly with the processor, but I recommend
modifying them with copper when possible, as you can better synchronise
the appropriate moment and video line for accessing the register.

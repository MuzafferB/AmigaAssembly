
; Lesson11l7.s        8 sprites attached (therefore 4 at 16 colours) used,
; or rather ‘reused’ 128 times per line.

SECTION    MegaRiuso,CODE

; Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110100000    ; copper,bitplane,sprites
;         -----a-bcdefghij

Waitdisk    EQU    30

NumeroLinee    =    128
LungSpr        =    NumberOfLines*8

START:

; Point the sprites

MOVE.L    #SpritesBuffer,d0
LEA    SPRITEPOINTERS,A1
MOVEQ    #8-1,D1            ;num of sprites = 8
POINTB:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
add.l    #LungSpr,d0        ;length of sprite
addq.w    #8,a1
dbra    d1,POINTB        ;Repeat D1 times

; Point the biplane to zero

MOVE.L	#PLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

bsr.s    CreaSprites    ; routine that creates the 4 attached sprites,
; i.e. all 8 sprites, made from
; 128 reuses of 1 line each!

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enables bitplane, copper
; and sprites.

move.l    #COPPER,$80(a5)        ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $010
BNE.S    Waity1

btst    #2,$16(A5)    ; Right button pressed?
beq.s    NonOndegg

bsr.w    OndeggiaSpriteS    ; wiggle the 8 reused sprites

NonOndegg:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse
rts

; ****************************************************************************
; Routine that creates the 8 sprites (i.e. 4 attached) in the ‘SpritesBuffer’.
; Note that the attached sprites are in turn placed side by side in pairs,
; so as to obtain 2 bars 16*2=32 pixels wide, with 16 colours.
; First of all, remember that each sprite can be ‘reused’,
; i.e. ‘under’ a sprite, after the end of the sprite, you can
; put another sprite, provided that its vertical starting position
; leaves 1 line ‘empty’. Here we use this fact extensively,
; in fact, each reuse of the sprite is 1 line, so we get a
; vertical strip (16 pixels wide) made up of many “sprites” one line high
; separated by an ‘empty’ line. To fill the 256 vertical lines of the
; screen, we use each sprite 128 times! But at least we can
; ‘curve’ that line as much as we want, since each strip has its
; own independent HSTART (horizontal position).
;
; Let's recall the structure of a sprite:
;
;VSTART:
;    dc.b xx        ; Vertical position (from $2c to $f2)
;HSTART:
;    dc.b xx+(xx)    ; Horizontal position (from $40 to $d8)
;VSTOP:
;    dc.b xx        ; Vertical end.
;    dc.b $00    ; Special byte: bit 7 for ATTACHED!!
;    dc.l	XXXXX    ; sprite bitplane (drawing!) here 1 line
;    dc.w    0,0    ; 2 words reset to FINE SPRITE, which we put here
;            ; never... so here there will already be the VSTART and
;            ; VSTOP of the next sprite!
;
; 4 bytes -> control words + 4 bytes -> figure (1 strip)
; 4*2= 8 -> length of one sprite; 8*128 = 1024, length of 1 sprite.
; let's reuse each sprite 128 times: 2 lines per sprite = 256 lines!
;
; ****************************************************************************

; 1024 bytes (8*128) a sprite

CreateSprites:
lea    SpritesBuffer,A0 ; destination
move.l    #%10000000,D5    ; bit 7 set - for attachment in sprite+3
moveq    #$2c,D0        ; VSTART - start from $2c
CreateLoop:
move.b    d0,(A0)        ; set vstart to the 8 sprites
move.b    d0,LungSpr(A0)    ; 2 (each sprite is 2400 bytes long)
move.b    d0,LungSpr*2(A0)    ; 3
move.b    d0,LungSpr*3(A0)    ; 4
move.b    d0,LungSpr*4(A0)    ; 5
move.b    d0,LungSpr*5(A0)    ; 6
move.b    d0,LungSpr*6(A0)    ; 7
move.b    d0,LungSpr*7(A0)    ; 8

move.l    d0,D1
addq.w    #1,D1        ; VSTART 1 line below -> let's use it as VSTOP

move.b    d1,2(A0)		; set vstop to the 8 sprites
move.b    d1,LungSpr+2(A0)    ; 2 (each sprite is 2400 bytes long)
move.b    d1,(LungSpr*2)+2(A0)    ; 3
move.b    d1,(LungSpr*3)+2(A0)    ; 4
move.b    d1,(LungSpr*4)+2(A0)    ; 5
move.b    d1,(LungSpr*5)+2(A0)    ; 6
move.b    d1,(LungSpr*6)+2(A0)    ; 7
move.b    d1,(LungSpr*7)+2(A0)    ; 8

; Set the bits attached to the 8 sprites

move.b    d5,3(A0)        ; put the spec byte to the 8 sprites
move.b    d5,LungSpr+3(A0)    ; 2 (each sprite is 2400 bytes long)
move.b    d5,(LungSpr*2)+3(A0)    ; 3
move.b    d5,(LungSpr*3)+3(A0)    ; 4
move.b    d5,(LungSpr*4)+3(A0)    ; 5
move.b    d5,(LungSpr*5)+3(A0)    ; 6
move.b    d5,(LungSpr*6)+3(A0)    ; 7
move.b    d5,(LungSpr*7)+3(A0)    ; 8

addq.w    #4,A0            ; skip the 2 control words
; and go to the sprite plane!

move.l    #$55553333,(A0)        ; 1 \ put the shaded line
move.l	#$0f0f00ff,LungSpr(A0)    ; 2 / attach 1!

move.l    #$aaaacccc,LungSpr*2(A0)    ; 3 \ attach 2!
move.l    #$f0f0ff00,LungSpr*3(A0)    ; 4 /

move.l    #$55553333,LungSpr*4(A0)    ; 5 \ attached 3!
move.l    #$0f0f00ff,LungSpr*5(A0)    ; 6 /

move.l    #$aaaacccc,LungSpr*6(A0)    ; 7 \ attached 4!
move.l    #$f0f0ff00,LungSpr*7(A0)    ; 8 /

addq.w    #4,A0            ; skip the 2 plane words,
; to go to the next
; 2 control words, since
; there are no 2 words reset
; at the end of the sprite.

cmp.b    #%10000110,D5    ; are we below the $FF line?
beq.s    SiamoSottoFF
addq.b    #2,D0        ; vstart 2 lines below for the next
; reuse of the sprite. Since each
; sprite is 1 line high, and between one
; use and another it is necessary to leave
; a blank line, we add 2.
bne.w    CreaLoop    ; have we reached $fe+2 = $00?
; If so, set the high bit of
; vstart and vstop. Otherwise, continue

move.b    #%10000110,D5    ; %10000110 -> set the 2 high bits of vstart
; and vstop to go below the $FF line
subq.b    #2,D0		; go back 1 step...

SiamoSottoFF:
addq.b    #2,D0        ; vstart 2 lines below...
cmpi.b    #$2c,D0        ; are we at position $FF+$2c?
bne.w    CreaLoop    ; if not yet, continue!
rts

; ****************************************************************************

; Parameters for ‘IS’

; BEG> 0
; END> 360
; AMOUNT> 250
; AMPLITUDE> $20
; YOFFSET> $20
; SIZE (B/W/L)> b
; MULTIPLIER> 1

SinTabHstarts:
dc.B    $20,$21,$22,$23,$24,$24,$25,$26,$27,$28,$28,$29,$2A,$2B,$2B,$2C
dc.B	$2D,$2E,$2E,$2F,$30,$30,$31,$32,$32,$33,$34,$34,$35,$36,$36,$37
dc.B	$37,$38,$38,$39,$39,$3A,$3A,$3B,$3B,$3C,$3C,$3C,$3D,$3D,$3D,$3E
dc.B	$3E,$3E,$3F,$3F,$3F,$3F,$3F,$40,$40,$40,$40,$40,$40,$40,$40,$40
dc.B	$40,$40,$40,$40,$40,$40,$3F,$3F,$3F,$3F,$3F,$3E,$3E,$3E,$3D,$3D
dc.B	$3D,$3C,$3C,$3C,$3B,$3B,$3A,$3A,$39,$39,$38,$38,$37,$37,$36,$36
dc.B	$35,$34,$34,$33,$32,$32,$31,$30,$30,$2F,$2E,$2E,$2D,$2C,$2B,$2B
dc.B	$2A,$29,$28,$28,$27,$26,$25,$24,$24,$23,$22,$21,$20,$20,$1F,$1E
dc.B	$1D,$1C,$1C,$1B,$1A,$19,$18,$18,$17,$16,$15,$15,$14,$13,$12,$12
dc.B	$11,$10,$10,$0F,$0E,$0E,$0D,$0C,$0C,$0B,$0A,$0A,$09,$09,$08,$08
dc.B	$07,$07,$06,$06,$05,$05,$04,$04,$04,$03,$03,$03,$02,$02,$02,$01
dc.B	$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
dc.B	$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04
dc.B	$04,$05,$05,$06,$06,$07,$07,$08,$08,$09,$09,$0A,$0A,$0B,$0C,$0C
dc.B	$0D,$0E,$0E,$0F,$10,$10,$11,$12,$12,$13,$14,$15,$15,$16,$17,$18
dc.B	$18,$19,$1A,$1B,$1C,$1C,$1D,$1E,$1F,$20
FinTab:

TabLength    = FinTab-SinTabHstarts

OndeggiaSpriteS:
addq.b    #1,Barra1OffSalv
moveq    #0,D0
move.b    Barra1OffSalv(pc),D0
cmp.w	#TabLength, D0        ; are we at maximum offset?
bne.s    DoNotRestartO1
clr.b    Bar1OffSalv        ; restart from the beginning
DoNotRestartO1:
addq.b    #2,Bar2OffSalv
moveq    #0,D0
move.b    Bar2OffSave(pc),D0
cmp.w    #TabLength,D0
bne.s    DoNotRestartO2
clr.b    Bar2OffSave        ; restart from the beginning
DoNotRestartO2:
moveq    #0,D1
moveq    #0,D2
moveq    #0,D3
moveq    #0,D4
moveq    #0,D5
lea    SpritesBuffer,A0    ; first sprite address
lea    SinTabHstarts(PC),A1
move.b    Barra1OffSalv(pc),D0
move.b    Barra2OffSalv(pc),D2
move.b	0(A1,D0.w),D5    ; from sintab second Barra1OffSalv
OndeggiaLoop:
move.b    0(A1,D0.w),D3    ; from sintab - for bar 1
move.b    0(A1,D2.w),D4    ; from sintab - for bar 2

; modify everything

add.b    D4,D3    ; bar 1
sub.b    D5,D3    ; 

add.b    D5,D4    ; bar 2

add.b    #105,D3    ; centre bar 1
add.b    #75,D4    ; centre bar 2

; Modify the HSTART (horizontal position) of the 8 sprites

; ** First Bar

move.b    D3,1(A0)        ; sprite 1
move.b    D3,LungSpr+1(A0)    ; 2

; now the sprite attached to the same bar, but side by side (16 pixels later)

addq.w    #8,D3            ; add 8, i.e. 16 pixels, since
; HSTART adds 2 each time.
move.b    D3,(LungSpr*2)+1(A0)    ; 3
move.b    D3,(LungSpr*3)+1(A0)    ; 4

; ** Second bar

move.b    D4,(LungSpr*4)+1(A0)    ; 5
move.b    D4,(LungSpr*5)+1(A0)    ; 6

addq.w    #8,D4            ; adda 8, i.e. 16 pixels, given that
; HSTART adda 2 each time.
move.b    D4,(LungSpr*6)+1(A0)    ; 7
move.b    D4,(LungSpr*7)+1(A0)    ; 8

addq.w    #1,D2        ; next offset - bar 2...
cmpi.w    #TabLunghezz,D2    ; are we at the maximum?
bne.s    Nonrestart2
moveq    #0,D2        ; reread from the first value...
Nonrestart2:
addq.w    #1,D0        ; next offset - bar 1
cmp.w    #TabLunghezz,D0    ; are we at the maximum?
bne.s    Nonrestart1
moveq    #0,D0        ; reread from the first value
Nonrestart1:
addq.w    #8,A0        ; skip to the next reuse of sprite

cmpa.l    #SpritesBuffer+LungSpr,a0 ; are we done?
bne.s    OndeggiaLoop
rts

Barra1OffSalv:
dc.w	0
Barra2OffSalv:
dc.w	0


; ****************************************************************************
;				COPPERLIST
; ****************************************************************************

section    baucoppe,data_c

COPPER:
dc.w    $8e,$2c81    ; diwstart
dc.w    $90,$2cc1    ; diwstop
dc.w    $92,$38        ; ddfstart
dc.w    $94,$d0        ; ddfstop

SPRITEPOINTERS:
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

; Sprite colours (attached) - from colour17 to colour31

dc.w	$1a2,$010,$1a4,$020,$1a6,$030
dc.w	$1a8,$140,$1aa,$250,$1ac,$360,$1ae,$470
dc.w	$1b0,$580,$1b2,$690,$1b4,$7a0,$1b6,$8b0
dc.w	$1b8,$9c0,$1ba,$ad0,$1bc,$be0,$1be,$cf0

dc.w	$ffff,$fffe	; fine copperlist

; ****************************************************************************

section	grafica,bss_C

SpritesBuffer:
DS.B    LungSpr*8    ; 1024 bytes per sprite megareused

; ****************************************************************************

plane:
ds.b    40*256    ; 1 lowres ‘black’ plane as background.

END

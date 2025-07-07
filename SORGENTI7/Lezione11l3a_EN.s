
; Lesson 11l3a.s - move a pic up/down - right/left

SECTION    coplanes,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

scr_bytes    = 40    ; Number of bytes per horizontal line.
; From this, the screen width is calculated
; by multiplying the bytes by 8: normal screen 320/8=40
; E.g. for a screen 336 pixels wide, 336/8=42
; example widths:
; 264 pixels = 33 / 272 pixels = 34 / 280 pixels = 35
; 360 pixels = 45 / 368 pixels = 46 / 376 pixels = 47
; ... 640 pixels = 80 / 648 pixels = 81 ...

scr_h        = 256    ; Screen height in lines
scr_x        = $81    ; Screen start, position XX (normal $xx81) (129)
scr_y        = $2c    ; Screen start, position YY (normal $2cxx) (44)
scr_res        = 1    ; 2 = HighRes (640*xxx) / 1 = LowRes (320*xxx)
scr_lace	= 0    ; 0 = non-interlace (xxx*256) / 1 = interlace (xxx*512)
ham        = 1    ; 0 = non-ham / 1 = ham
scr_bpl        = 6    ; Number of bitplanes

; parameters calculated automatically

scr_w        = scr_bytes*8        ; screen width
scr_size    = scr_bytes*scr_h    ; screen size in bytes
BPLC0    = ((scr_res&2)<<14)+(scr_bpl<<12)+$200+(scr_lace<<2)+(ham<<11)
DIWS	= (scr_y<<8)+scr_x
DIWSt	= ((scr_y+scr_h/(scr_lace+1))&255)<<8+(scr_x+scr_w/scr_res)&255
DDFS	= (scr_x-(16/scr_res+1))/2
DDFSt	= DDFS+(8/scr_res)*(scr_bytes/2-scr_res)


START:

; Point to the PIC

LEA    bplpointers,A0
MOVE.L    #LOGO+40*40,d0    ; logo address (slightly lowered)
MOVEQ	#6-1,D7        ; 6 bitplanes HAM.
pointloop:
MOVE.W    D0,6(A0)
SWAP    D0
MOVE.W    D0,2(A0)
SWAP    D0
ADDQ.w    #8,A0
ADD.L    #176*40,D0    ; plane length
DBRA    D7,pointloop

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w	#$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L	4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S	Waity1

bsr.w    sugiu        ; move down and up
bsr.w    lefrig        ; move right and left

MOVE.L    #$1ff00,d1    ; bits for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; Mouse pressed?
bne.s    mouse
rts            ; exit


*****************************************************************************
;    LOGO ROUTINE ON DOWN (moves the bplpointers forward or backward
;                 nothing special
*****************************************************************************

;     _________________
;     \ /
;     \_____________/_
;	 | \___________/
;     |__ .. _:
;     | \_____/ :
;     __`---------'__
;    ./ \.
;    | _ _ |
;    | | | |

SuGiuFlag:
DC.W    0

SUGIU:
LEA    BPLPOINTERS,A1	; get the address currently pointed to in
move.w    2(a1),d0    ; bitplanes and put it in d0
swap    d0
move.w    6(a1),d0

BTST.b    #1,SuGiuFlag        ; should I go up or down?
BEQ.S    GIUT

; GO UP

SUT:
MOVE.L    SUGIUTABP(PC),A0 ; table with multiples of 40 (of the module)
SUBQ.L    #2,SUGIUTABP     ; take the ‘previous’ value
CMPA.L    #SUGIUTAB+4,A0
BNE.S    NOBSTART
BCHG.B	#1,SuGiuFlag        ; if finished, change direction (go down)
ADDQ.L    #2,SUGIUTABP    ; to balance
NOBSTART:
BRA.s    NOBEND

; GO DOWN

GIUT:
MOVE.L    SUGIUTABP(PC),A0 ; table with multiples of 40
ADDQ.L    #2,SUGIUTABP     ; take the value ‘after’
CMPA.L    #SUGIUTABEND-4,A0
BNE.S    NOBEND
BCHG.B    #1,SuGiuFlag        ; if finished, change direction
NOBEND:
moveq    #0,d1
MOVE.w    (A0),D1        ; value from table in d1
BTST.b    #1,SuGiuFlag
BEQ.S    GIU
SU:
add.l    d1,d0        ; if I go UP, I add it
BRA.S    MOVLOG
DOWN:
sub.l    d1,d0        ; if I go DOWN, subtract it
MOVLOG:
LEA    BPLPOINTERS,A1    ; and point to the new address
MOVEQ    #6-1,D1        ; number of bitplanes -1 (ham 6 bitplanes)
APOINTB:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
add.l    #176*40,d0    ; length of a bitplane
addq.w    #8,a1
dbra    d1,APOINTB        ;Repeat D1 times (D1=number of bitplanes)
NOMOVE:
rts

SUGIUTABP:
dc.l    SuGiuTab

; table with the number of bytes to skip... naturally they are multiples of 40,
; i.e. the length of a line.

SuGiuTab:
dc.w	0*40,0*40,0*40,1*40,0*40,0*40,1*40,0*40,1*40
dc.w	0*40,0*40,1*40,0*40,1*40,0*40,1*40,1*40,0*40
dc.w	0*40,0*40,1*40,0*40,1*40,0*40,1*40,0*40,0*40
dc.w	0*40,1*40,1*40,0*40,1*40,0*40,1*40,1*40,1*40
dc.w	1*40,0*40,1*40,1*40,1*40,1*40,0*40
dc.w	1*40,0*40,1*40,0*40,1*40,0*40,0*40,1*40,0*40
dc.w	0*40,1*40,0*40,1*40,0*40,0*40,1*40,0*40,0*40
SuGiuTabEnd:

*****************************************************************************
;    LEFT LOGO ROUTINE (uses bplcon1, nothing special)
*****************************************************************************

;     ____
;    ____/____\_____
;    _)_ _ ______/
;    \_(·)(·)(¥__\%
;     \(___ ¯ //
;     \V V\_____/ st!
;      ¯¯¯¯¯¯¯¯

DestSinFlag:
DC.W    0

LefRig:
BTST.b    #1,DestSinFlag    ; should I go right or left?
BEQ.S    ScrolRight
ScrolLeft:
MOVE.L    LefRigTABP(PC),A0    ; table with values for bplcon1
SUBQ.L    #2,LefRigTABP        ; go left
CMPA.L    #LefRigTAB+4,A0        ; end of table?
BNE.S    NOBSTART2        ; if not yet, continue
BCHG.B    #1,DestSinFlag        ; Otherwise, change direction
ADDQ.L    #2,LefRigTABP        ; to balance
NOBSTART2:
BRA.s    NOBEND2

ScrollRight:
MOVE.L    LefRigTABP(PC),A0    ; value table for bplcon1
ADDQ.L    #2,LefRigTABP        ; go right
CMPA.L    #LefRigEND-4,A0        ; end of table?
BNE.S    NOBEND2            ; If not yet, continue
BCHG.B    #1,DestSinFlag        ; Otherwise change direction
NOBEND2:
MOVE.w    (A0),CON1        ; put the value in bplcon1 in the
NOMOVE2:                ; Copperlist
rts

LefRigTABP:
dc.l    LefRigTab

; These are values suitable for bplcon1 ($dff102) to scroll right/left.

LefRigTab:
dc.w    0,0,0,0,0,0,0,$11,$11,$11,$11,$11
dc.w	$22,$22,$22,$22,$22
dc.w	$33,$33,$33
dc.w	$44,$44
dc.w	$55,$55,$55
dc.w	$66,$66,$66,$66,$66
dc.w	$77,$77,$77,$77,$77,$77,$77
dc.w	$88,$88,$88,$88,$88,$88,$88,$88
dc.w	$99,$99,$99,$99,$99,$99
dc.w	$aa,$aa,$aa,$aa,$aa
dc.w    $bb,$bb,$bb,$bb
dc.w    $cc,$cc,$cc,$cc
dc.w	$dd,$dd,$dd,$dd,$dd
dc.w	$ee,$ee,$ee,$ee,$ee,$ee
dc.w	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
LefRigEnd:


******************************************************************************
;		COPPERLIST:
******************************************************************************

Section    MioCoppero,data_C    

COPPERLIST:
dc.w    $8e,DIWS    ; DiwStrt
dc.w    $90,DIWSt    ; DiwStop
dc.w    $92,DDFS    ; DdfStart
dc.w    $94,DDFSt    ; DdfStop

dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0		; Bpl2Mod

BPLPOINTERS:
dc.w $e0,0,$e2,0        ;first      bitplane
dc.w $e4,0,$e6,0        ;second ‘
dc.w $e8,0,$ea,0        ;third ’
dc.w $ec,0,$ee,0        ;fourth ‘
dc.w $f0,0,$f2,0        ;fifth ’
dc.w $f4,0,$f6,0        ;sixth "

dc.w    $180,0    ; Colour0 black


dc.w    $100,BPLC0    ; BplCon0 - 320*256 HAM


dc.w $180,$0000,$182,$134,$184,$531,$186,$443
dc.w $188,$0455,$18a,$664,$18c,$466,$18e,$973
dc.w $190,$0677,$192,$886,$194,$898,$196,$a96
dc.w $198,$0ca6,$19a,$9a9,$19c,$bb9,$19e,$dc9
dc.w $1a0,$0666

dc.w    $102    ; bplcon1
CON1:
dc.w    0

dc.w    $9707,$FFFE    ; wait line $97
dc.w    $100,$200    ; no bitplanes
dc.w    $180,$110    ; colour0
dc.w    $9807,$FFFE    ; wait
dc.w    $180,$120    ; colour0
dc.w    $9a07,$FFFE
dc.w    $180,$130
dc.w    $9b07,$FFFE
dc.w    $180,$240
dc.w    $9c07,$FFFE
dc.w    $180,$250
dc.w    $9d07,$FFFE
dc.w    $180,$370
dc.w    $9e07,$FFFE
dc.w    $180,$390
dc.w	$9f07,$FFFE
dc.w	$180,$4b0
dc.w	$a007,$FFFE
dc.w	$180,$5d0
dc.w	$a107,$FFFE
dc.w	$180,$4a0
dc.w	$a207,$FFFE
dc.w	$180,$380
dc.w	$a307,$FFFE
dc.w	$180,$360
dc.w	$a407,$FFFE
dc.w	$180,$240
dc.w	$a507,$FFFE
dc.w	$180,$120
dc.w $a607,$FFFE
dc.w $180,$110
DC.W $A70F,$FFFE
DC.W $180,$000

dc.w $FFFF,$FFFE ; End of copperlist


SECTION LOGO,CODE_C

LOGO:
incbin ‘amiet.raw’ ; 6 bitplanes * 176 lines * 40 bytes (HAM)

END

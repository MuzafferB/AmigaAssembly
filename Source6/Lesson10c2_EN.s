
; Lesson 10c2.s    BLITTATA, in which we construct the mask of a drawing
;        Right click to execute the blitting, left click to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE1,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L	#40*256,d0    ; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w	#$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

; copy the image normally

lea    FiguraPlane1,a0        ; copy the first plane
lea    BITPLANE1,a1
bsr.s    copy

lea    FigurePlane2,a0        ; copy second plane
lea    BITPLANE2,a1
bsr.s    copy

lea    FigurePlane3,a0        ; copy third plane
lea    BITPLANE3,a1
bsr.s    copy

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1

; copy first bitplane

lea    FigurePlane1,a0
lea    FigurePlane2,a1
lea    FigurePlane3,a2
lea    BITPLANE1+14,a3
bsr.s    BlitOR        ; performs an OR between the planes of the figure
; and copies the result
mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:
rts

;****************************************************************************
; This routine copies the figure on the screen.
;
; A0 - source address
; A1 - destination address
;****************************************************************************

Copy:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$ffffffff,$44(a5)    ; masks
move.l    #$09f00000,$40(a5)    ; BLTCON0 and BLTCON1 (use A+D)
; normal copy
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #34,$66(a5)        ; BLTDMOD (40-6=34)
move.l    a0,$50(a5)        ; BLTAPT source pointer
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w    #(64*42)+3,$58(a5)    ; BLTSIZE (start blitter!)
; width 3 words
rts                ; height 42 lines

;****************************************************************************
; This routine performs an OR between the 3 channels A, B and C.
;
; A0 - channel A address
; A1 - channel B address
; A2 - channel C address
; A3 - destination address
;****************************************************************************

;     _____
;     (_____)
;     ,,,
;     __n____________.|o o|.____________n__
;    == _o_| | - | |_o_ ==
;     ¯¯ . | ____ |\ O /| ____ | ¯¯
;	 |__/ \ ||`*'|| / \_#| :
;     : | || || | `:
;     . |#._______| .
;     ! | o |
;     ( )
;     | U |
;     : ! :

BlitOR:
btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

move.l    #$FFFFFFFF,$44(a5)    ; BLTFWM and BLTLWM
move.l    #$0FFE0000,$40(a5)    ; BLTCON0 and BLTCON1
; activate all channels
; perform an OR between A, B and C
; D=A OR B OR C
move.w    #0,$60(a5)        ; BLTCMOD (=0)
move.w    #0,$62(a5)        ; BLTBMOD (=0)
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #34,$66(a5)        ; BLTDMOD (40-6=34)
move.l    a0,$48(a5)        ; BLTCPT source pointer
move.l    a1,$4c(a5)		; BLTBPT destination pointer
move.l    a2,$50(a5)        ; BLTAPT destination pointer
move.l    a3,$54(a5)        ; BLTDPT destination pointer
move.w    #(64*42)+3,$58(a5)	; BLTSIZE (via blitter!)
; width 3 words
rts                ; height 42 lines

;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$3200    ; bplcon0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $180,$000    ; colour0
dc.w    $182,$aaa    ; colour1
dc.w    $184,$b00    ; colour2
dc.w    $186,$080    ; colour3
dc.w    $188,$24c
dc.w    $18a,$eb0
dc.w	$18c,$b52
dc.w	$18e,$0cc

dc.w	$FFFF,$FFFE	; Fine della copperlist

;****************************************************************************

; This is the figure

FigurePlane1:
dc.l    $ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l	$ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l	$ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l    $ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,$3fffff80
dc.l    $3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l    $3fff,$ff800000,0

FigurePlane2:
dc.l    $3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l    $3fff,$ff800000,$3fffff80,$3fff,$ff800000,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0

FigurePlane3:
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l	$ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l	$ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$ffffff80
dc.l	$ffffffff,$ff80ffff,$ffffff80,$ffffffff,$ff80ffff,$ffffff80
dc.l	$f000ffff,$ff80f000,$ffffff80,$f000ffff,$ff80f000,$ffffff80
dc.l	$f000ffff,$ff80f000,$ffffff80,$f000ffff,$ff80f000,$ffffff80
dc.l	$f000ffff,$ff80f000,$ffffff80,$f000ffff,$ff80f000,$ffffff80
dc.l	$ffffffff,$ff800000,0

;****************************************************************************

SECTION	bitplane,BSS_C

BITPLANE1:
ds.b	40*256
BITPLANE2:
ds.b	40*256
BITPLANE3:
ds.b	40*256

;****************************************************************************

end

In this example, we use the blitter to construct the mask of a figure,
using a technique different from that used in lesson 10c1.s.
This time, we perform a single blit, using all channels.
Since our figure has 3 bitplanes, we can read them simultaneously
through channels A, B and C and write the OR through channel D.
This is the first example in which we activate all the blitter channels
simultaneously. Note that bits 8 to 11 of BLTCON0 are
all set to 1. The value of LF is calculated in the usual way, setting
i.e. setting to 1 all minterms corresponding to input combinations that have
A=1 or B=1 or C=1. Of course, there are 7 combinations
(the only one not included is the one with A=0, B=0 and C=0).
Note that this technique, unlike the one seen in lesson 10c1.s,
 can only be applied if the figure has 3 bitplanes.


; Lesson 10c1.s    BLITTATA, in which we construct the mask of a drawing
;        Alternate mouse buttons to see the blits

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*********************** ******************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
************************************************************************* ****

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
ADD.L    #40*256,d0    ; + bitplane length (here it is 256 lines high)
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

; copy the image normally

lea    FigurePlane1,a0        ; copy the first plane
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
lea    BITPLANE1+14,a1
bsr.s    BlitOR        ; performs an OR between plane 1 of the figure
; and the destination (empty)

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

lea    FiguraPlane2,a0
lea    BITPLANE1+14,a1
bsr.s    BlitOR        ; performs an OR between plane 2 of the figure
; and the destination (plane 1 of the figure)
mouse3:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse3

lea    FiguraPlane3,a0
lea    BITPLANE1+14,a1
bsr.s    BlitOR        ; performs an OR between plane 3 of the figure
; and the destination (plane 1 OR 2 of the figure)
mouse4:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse4
rts

;****************************** **********************************************
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
move.l    a1,$54 (a5)        ; BLTDPT destination pointer
move.w    #(64*42)+3,$58(a5)    ; BLTSIZE (start blitter!)
; width 3 words
rts                ; height 42 lines

;*************************************************************** *************
; This routine performs an OR between the source and the destination.
; It uses channels B, C and D. The source is read through channel C.
; The destination is read from channel B and then rewritten through channel D.
; As a result, channels B and D have the same module and the same starting addresses
; .
;
; Parameters:
;
; A0 - source address
; A1 - destination address
;****************************************************************************

;     _____
;     (_____)
;     ,,,
;     __n____________.|o o|.____________n__
;    == _o_| | - | |_o_ ==
;     ¯¯ . | ____ |\ O /| ____ | ¯¯
;     |__/ \ ||`*'|| / \_#| :
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

move.l    #$07EE0000,$40 (a5)    ; BLTCON0 and BLTCON1
; performs an OR between B and C
; D=B OR C
move.w    #0,$60(a5)        ; BLTCMOD (=0)
move.w    #34,$66(a5)        ; BLTDMOD (40-6=34)
move.w    #34,$62(a5)        ; BLTBMOD (40-6=34)
move.l    a0,$48(a5)        ; BLTCPT source pointer
move.l    a1,$4c(a5)        ; BLTBPT destination pointer
move.l    a1,$54 (a5)        ; BLTDPT destination pointer
move.w    #(64*42)+3,$58(a5)    ; BLTSIZE (start blitter!)
; width 3 words
rts                ; height 42 lines

;******************************************* *********************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0		; Bpl2Mod

dc.w    $100,$3200    ; bplcon0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $180,$000    ; colour0
dc.w    $182,$aaa    ; colour1
dc.w    $184,$b00    ; colour2
dc.w    $186,$080	; color3
dc.w    $188,$24c
dc.w    $18a,$eb0
dc.w    $18c,$b52
dc.w    $18e,$0cc

dc.w    $FFFF,$FFFE    ; End of copperlist

;******************************************* *********************************

; This is the figure

FigurePlane1:
dc.l    $ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l    $ffffc000,$ffff,$c0000000,$ffffc000, $ffff,$c0000000
dc.l    $ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l	$ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l    $3fff,$ff800000,0

FigurePlane2:
dc.l    $3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l    $3fff, $ff800000,$3fffff80,$3fff,$ff800000,$3fffff80
dc.l	$3fff,$ff800000,$3fffff80,$3fff,$ff800000,0
dc.l	0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l    0,0,0

FigurePlane3:
dc.l    0,0,0,0,0,0
dc.l    0,0,0,0,0,0
dc.l	0,0,0,0,0,0
dc.l	0,0,0,0,0,0
dc.l	$ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$c0000000
dc.l    $ffffc000,$ffff,$c0000000,$ffffc000,$ffff,$ffffff80
dc.l    $ffffffff,$ff80ffff,$ffffff80,$ffffffff,$ff80ffff,$ffffff80
dc.l    $f000ffff,$ff80f000,$ffffff80,$f000ffff,$ff80f000,$ffffff80
dc.l	$f000ffff,$ff80f000,$ffffff80,$f000ffff,$ff80f000,$ffffff80
dc.l	$f000ffff,$ff80f000,$ffffff80,$f000ffff,$ff80f000,$ffffff80
dc.l	$ffffffff,$ff800000,0

;**************************************************** ************************

SECTION    bitplane,BSS_C

BITPLANE1:
ds.b    40*256
BITPLANE2:
ds.b    40*256
BITPLANE3:
ds.b    40*256

end

;***************** ***********************************************************

In this example, we use the blitter to construct the mask of a figure,
i.e. its ‘shadow’. To do this, we need to perform an OR operation between the bit
planes of the figure. In this example, we perform this operation
one step at a time. First, we perform an OR between the first bit plane
of the figure and the destination where we will draw the mask.
Since the destination is empty at the beginning, this step is equivalent to
a simple copy of the first plane of the figure. As a second step,
 we perform the OR between the second plane and the destination. Since the destination
contains the first plane, we are essentially performing the OR between plane 1 and plane 2.
As a third step, we perform the OR between plane 3 and the destination. Since the
destination contains the OR of plane 1 and plane 2, the result will be
the OR of all 3 planes. If we had a figure with more than 3 planes,
we would have to repeat this same procedure for the other planes as well.
The bleed occurs using 3 channels. The planes in the figure are read
through channel C. The destination, on the other hand, is read through channel
B and then rewritten through channel D. The LF value is calculated to
perform the OR of channels B and C.

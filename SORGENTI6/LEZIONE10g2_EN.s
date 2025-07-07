
; Lesson 10g2.s    Example of OR between one enabled channel and one disabled channel
;        Right click to execute the bleed, left click to exit.

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
MOVEQ    #1-1,D1        ; number of bitplanes
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

lea    Figure,a0
lea    BITPLANE1+20,a1
bsr.s    copy        ; execute copy figure 2

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1        ; if not, do not delete

bsr.s    BlitOR        ; perform OR between the 2 figures

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:
rts


;****************************************************************************
; This routine copies the figure on the screen.
; It takes as parameters
; A0 - source address
; A1 - destination address
;****************************************************************************

Copy:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$ffffffff,$44(a5)	; masks
move.l    #09f00000,$40(a5)    ; BLTCON0 and BLTCON1 (use A+D)
; normal copy
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #30,$66(a5)        ; BLTDMOD (40-10=30)
move.l    a0,$50(a5)        ; BLTAPT source pointer
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w    #(64*71)+5,$58(a5)    ; BLTSIZE (start blitter!)
; width 5 words
rts                ; height 71 lines

;****************************************************************************
; This routine performs an OR between a figure read through channel B
; and the constant value contained in BLTADAT
;****************************************************************************

;     |\__/,| (`\
;     |_ _ |.--.) )
;     ( T ) /
;     (((^_(((/(((_>

BlitOR:
btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

move.l    #$ffffffff,$44(a5)    ; masks
move.l    #$05fc0000,$40(a5)    ; BLTCON0 and BLTCON1
; use channels B and D
; perform OR between A and B (LF=$FC)
move.w    #0,$62(a5)        ; BLTBMOD (=0)
move.w    #30,$66(a5)        ; BLTDMOD (40-10=30)
move.w    #$CCCC,$74(a5)        ; OR value in BLTADAT 

move.l    #Figure,$4c(a5)        ; BLTBPT source pointer
move.l    #BITPLANE1+100*40+10,$54(a5)    ; BLTDPT dest pointer
move.w    #(64*71)+5,$58(a5)    ; BLTSIZE (start blitter!)
; width 5 words
rts                ; height 71 lines

;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200    ; bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$aaa    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

Figure:
dc.w    $ffff,$ffff,$ffff,$ffff,$fe00,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,$3800,0,0
dc.w	0,$0003,$ff80,0,0,0,$001f,$fff0,0,0
dc.w    0,$01ff,$ffff,0,0,0,$0fff,$ffff,$e000,0
dc.w    0,$ffff,$ffff,$fe00,0,$0007,$ffff,$ffff,$ffc0,0
dc.w    $007f,$ffff,$ffff,$fffc,0,$03ff,$ffff,$ffff,$ffff,$8000
dc.w    $3fff,$ffff,$ffff,$ffff,$f800,$7fff,$ffff,$ffff,$ffff,$fc00
dc.w	$3fff,$ffff,$ffff,$ffff,$f800,$03ff,$ffff,$ffff,$ffff,$8000
dc.w    $007f,$ffff,$ffff,$fffc,0,$0007,$ffff,$ffff,$ffc0,0
dc.w    0,$ffff,$ffff,$fe00,0,0,$0fff,$ffff,$e000,0
dc.w	0,$01ff,$ffff,0,0,0,$001f,$fff0,0,0
dc.w	0,$0003,$ff80,0,0,0,0,$3800,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,0,0,0,0,0
dc.w	0,0,0,0,0,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	$8000,0,0,0,$0200,$8000,0,0,0,$0200
dc.w	$ffff,$ffff,$ffff,$ffff,$fe00

;****************************************************************************

SECTION	bitplane,BSS_C
BITPLANE1:
ds.b	40*256

end

;****************************************************************************

In this example, we perform an OR between a figure read through channel B
and a constant value contained in the BLTADAT register.
To do this, we keep channels B and D enabled, and program the LF byte
so that an OR is performed between sources A and B.

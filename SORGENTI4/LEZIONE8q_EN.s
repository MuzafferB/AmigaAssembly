
; Lesson 8q.s Using pics with the palette saved at the bottom (BEHIND).
;        Left button to ‘colour’, right button to exit.

SECTION    Behind,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

START:
;    point to the figure

MOVE.L    #Logo1,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #4-1,D1        ; number of bitplanes (here there are 4)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap d0
ADD.L #40*84,d0 ; + bitplane length (here it is 84 lines high)
addq.w #8,a1
dbra d1,POINTBP


MOVE.W #DMASET,$96(a5) ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA


mouse:
btst.b    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse

;     |||||
;    _____.oOo_/o_O\_oOo.____.

Colour points:
lea    logo1+(40*84*4),a0    ; in a0 palette address after pic,
; obtainable by adding the length
; of the bitplanes at the beginning of the
; pic: the colours remain!
lea    CopColors+2,a1	; Colour register address in coplist
moveq    #16-1,d0    ; Number of colours
MettiLoop2:
move.w    (a0)+,(a1)    ; Copy colour from palette to coplist
addq.w    #4,a1        ; Jump to next colour register
dbra    d0,mettiloop2    ; Do all colours

mouse2:
btst.b	#2,$dff016	; Mouse destro premuto?
bne.s	mouse2

rts

*****************************************************************************
;            Copper List
*****************************************************************************
section    copper,data_c        ; Chip data

Copperlist:
dc.w    $8E,$2c81    ; DiwStrt - window start
dc.w    $90,$2cc1    ; DiwStop - window stop
dc.w    $92,$38        ; DdfStart - data fetch start
dc.w    $94,$d0        ; DdfStop - data fetch stop
dc.w    $102,0        ; BplCon1 - scroll register
dc.w    $104,0        ; BplCon2 - priority register
dc.w    $108,0        ; Bpl1Mod - odd pl module
dc.w    $10a,0        ; Bpl2Mod - even pl module

; 5432109876543210
dc.w    $100,%0100001000000000    ; BPLCON0 - 4 low-resolution planes (16 colours)

; Bitplane pointers

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000	;third bitplane
dc.w $ec,$0000,$ee,$0000    ;fourth bitplane

; the first 16 colours are for the LOGO

CopColors:
dc.w $180,0,$182,0,$184,0,$186,0	; Now they are reset, it will be the
dc.w $188,0,$18a,0,$18c,0,$18e,0    ; routine to copy the values
dc.w $190,0,$192,0,$194,0,$196,0    ; from the bottom of the pic.
dc.w $198,0,$19a,0,$19c,0,$19e,0

;    Let's add some shading for the scenery...

dc.w    $8007,$fffe    ; Wait - $2c+84=$80
dc.w    $100,$200    ; bplcon0 - no bitplanes
dc.w    $180,$003    ; colour0
dc.w    $8207,$fffe    ; wait
dc.w    $180,$005    ; colour0
dc.w    $8507,$fffe    ; wait
dc.w    $180,$007    ; colour0
dc.w    $8a07,$fffe    ; wait
dc.w    $180,$009    ; colour0
dc.w    $9207,$fffe    ; wait
dc.w    $180,$00b    ; colour0

dc.w    $9e07,$fffe    ; wait
dc.w    $180,$999    ; colour0
dc.w    $a007,$fffe    ; wait
dc.w    $180,$666    ; colour0
dc.w    $a207,$fffe    ; wait
dc.w    $180,$222    ; colour0
dc.w    $a407,$fffe    ; wait
dc.w    $180,$001    ; colour0

dc.l    $ffff,$fffe    ; End of copperlist


*****************************************************************************
;				DISEGNO
*****************************************************************************

section    gfxstuff,data_c

; Drawing 320 pixels wide, 84 high, with 4 bitplanes (16 colours).

Logo1:
incbin    “logo320*84*16c.raw”

end

The usefulness of putting the palette in .raw files becomes apparent when you have to manage
many figures, for example in adventure games or slideshows.
For example, in my ‘World of Manga’ I used this system, with AGA figures
saved from the AGA iffconverter with the 24-bit palette at the bottom.


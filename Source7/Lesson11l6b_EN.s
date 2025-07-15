
; Lesson 11l6b.s    Interlaced mode management routine (640x512)
;            which reads bit 15 (LOF) of VPOSR ($dff004).
;            Pressing the right key does not execute this routine,
;            and you will notice that sometimes the even lines remain
;            odd lines remain in ‘pseudo-non lace’.

SECTION    Interlacing,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

WaitDisk    EQU    30

scr_bytes    = 40    ; Number of bytes for each horizontal line.
; From this, the screen width is calculated
; by multiplying the bytes by 8: normal screen 320/8=40
; E.g. for a screen 336 pixels wide, 336/8=42
; example widths:
; 264 pixels = 33 / 272 pixels = 34 / 280 pixels = 35
; 360 pixels = 45 / 368 pixels = 46 / 376 pixels = 47
; ... 640 pixels = 80 / 648 pixels = 81 ...

scr_h        = 256    ; Screen height in lines
scr_x        = $81	; Start of screen, position XX (normal $xx81) (129)
scr_y        = $2c    ; Start of screen, position YY (normal $2cxx) (44)
scr_res        = 1    ; 2 = HighRes (640*xxx) / 1 = LowRes (320*xxx)
scr_lace    = 1    ; 0 = non-interlace (xxx*256) / 1 = interlace (xxx*512)
ham        = 0    ; 0 = non-ham / 1 = ham
scr_bpl        = 4    ; Number of bitplanes

; parameters calculated automatically

scr_w        = scr_bytes*8        ; screen width
scr_size    = scr_bytes*scr_h    ; screen size in bytes
BPLC0    = ((scr_res&2)<<14)+(scr_bpl<<12)+$200+(scr_lace<<2)+(ham<<11)
DIWS	= (scr_y<<8)+scr_x
DIWSt	= ((scr_y+scr_h/(scr_lace+1))&255)<<8+(scr_x+scr_w/scr_res)&255
DDFS    = (scr_x-(16/scr_res+1))/2
DDFSt    = DDFS+(8/scr_res)*(scr_bytes/2-scr_res)


START:
;    point to the figure

MOVE.L    #Logo1,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #4-1,D1        ; number of bitplanes (here there are 4)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L	#40*84,d0    ; + bitplane length (here it is 84 lines high)
addq.w    #8,a1
dbra    d1,POINTBP


MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$01000,d2    ; line to wait for = $000
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
Beq.S    Waity2

btst    #2,$16(A5)    ; Right button pressed?
beq.s    NonLaceint

bsr.s    laceint        ; Routine that points to even or odd lines
; each frame depending on the LOF bit for
; interlacing
NonLaceint:
btst.b    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse
rts

******************************************************************************
; INTERLACE ROUTINE - Checks the LOF (Long Frame) bit to see if
; even or odd lines should be displayed, and points accordingly.
******************************************************************************

LACEINT:
MOVE.L    #Logo1,D0    ; Bitplane address
btst.b    #15-8,4(A5)    ; VPOSR LOF bit?
Beq.S	MakeOdd    ; If so, move to the odd lines
ADD.L    #40,D0        ; Or add the length of one line,
; starting the display from the
; second: display even lines!
MakeOdd:
LEA    BPLPOINTERS,A1    ; PLANE POINTERS IN COPLIST
MOVEQ    #4-1,D7        ; NUMBER OF BITPLANES -1
LACELOOP:
MOVE.W    D0,6(A1)    ; Point to the figure
SWAP    D0
MOVE.W    D0,2(A1)
SWAP    D0
ADD.L	#40*84,D0    ; Bitplane length
ADDQ.w    #8,A1        ; Next pointers
DBRA    D7,LACELOOP
RTS

*****************************************************************************
;            Copper List
*****************************************************************************
section    copper,data_c        ; Chip data

Copperlist:
dc.w    $8e,DIWS    ; DiwStrt
dc.w    $90,DIWSt	; DiwStop
dc.w    $92,DDFS    ; DdfStart
dc.w    $94,DDFSt    ; DdfStop

dc.w    $102,0        ; BplCon1 - scroll register
dc.w    $104,0        ; BplCon2 - priority register
dc.w    $108,40		; Bpl1Mod - \ INTERLACE: length of a line
dc.w    $10a,40        ; Bpl2Mod - / to skip even or odd lines

; Bitplane pointers

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000    ;third bitplane
dc.w $ec,$0000,$ee,$0000    ;fourth bitplane

;         ; 5432109876543210
;    dc.w    $100,%0100001000000100    ; BPLCON0 - 4 low-resolution planes (16 colours)
;                    ; INTERLACED (bit 2!)

dc.w    $100,BPLC0    ; BplCon0 - calculated automatically


; the first 16 colours are for the LOGO

dc.w $180,$000,$182,$fff,$184,$200,$186,$310
dc.w $188,$410,$18a,$620,$18c,$841,$18e,$a73
dc.w $190,$b95,$192,$db6,$194,$dc7,$196,$111
dc.w $198,$222,$19a,$334,$19c,$99b,$19e,$446

;    Let's add some nuances to the scenery...

dc.w    $5607,$fffe    ; Wait - $2c+84=$80
dc.w    $100,$204    ; bplcon0 - no bitplanes, MA BIT LACE SET!
dc.w    $8007,$fffe    ; wait
dc.w    $180,$003    ; colour0
dc.w    $8207,$fffe    ; wait
dc.w    $180,$005    ; colour0
dc.w    $8507,$fffe    ; wait
dc.w    $180,$007	; colour0
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
incbin    “assembler2:sorgenti4/logo320*84*16c.raw”

end

Did you notice that ALL the bplcon0 of the copperlist must have bit 2,
the interlace bit, set? In fact, if the last BPLCON0 did not have the
bit set, even if the others did, the screen would not be
interlaced!

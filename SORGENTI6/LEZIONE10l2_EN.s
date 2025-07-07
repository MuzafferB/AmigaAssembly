
; Lesson10l2.s    ‘Forward/backward’ animation with the blitter
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1	; COP pointers
MOVEQ    #2-1,D1        ; number of bitplanes
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
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:

MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0
BNE.S    Waity1

bsr.s    Animation    ; move the frames in the table
move.l    Frametab(pc),a0    ; Draw the first frame of the table    
bsr.w    DrawFrame    ; draw the frame

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse
rts


;****************************************************************************
; This routine creates the animation by moving the frame addresses.
; The addresses scroll forward or backward depending on the direction
; of the animation.
;****************************************************************************

Animation:
addq.b    #1,ContaAnim ; these three instructions ensure that the
cmp.b    #10,ContaAnim ; frame is changed once
bne.w    NonCambiare ; yes and 9 no.
clr.b    ContaAnim

tst.b    Direction    ; checks direction flag
beq.s    Forward        ; if flag=0, goes forward

LEA    FRAMETAB(PC),a0 ; frame table
MOVE.L    4*4(a0),d0    ; saves the last address in d0

MOVE.L    4*3(a0),4*4(a0)    ; move the other addresses forward
MOVE.L    4*2(a0),4*3(a0)    ; These instructions ‘rotate’ the addresses
MOVE.L    4(a0),4*2(a0)     ; in the table.
MOVE.L    (a0),4(a0)
MOVE.L    d0,(a0)        ; put the former last address in the first place

CMP.L    #FRAME1,(a0)    ; do we have the first frame at the beginning?
BNE.S    BackAgain    ; no, keep going backwards
CLR.B    Direction    ; yes, you have to change direction
BackAgain:
BRA.S    Don'tChange

Forward:    LEA    FRAMETAB(PC),a0 ; frame table
MOVE.L    (a0),d0        ; save the first address in d0

MOVE.L    4(a0),(a0)    ; move the other addresses backwards
MOVE.L    4*2(a0),4(a0)	; These instructions ‘rotate’ the addresses
MOVE.L    4*3(a0),4*2(a0) ; of the table.
MOVE.L    4*4(a0),4*3(a0)
MOVE.L    d0,4*4(a0)    ; put the former first address in the eighth place

CMP.L	#FRAME5,(A0)    ; do we have the first frame at the top?
BNE.S    AncoraAvanti    ; no, keep going backwards
MOVE.B    #-1,Direzione    ; yes, you need to change direction
AncoraAvanti:

NonCambiare:
rts

; flag indicating the direction of the animation
Direzione:
dc.b    0

AnimCount:
dc.b    0

; This is the frame address table. The addresses
; in the table are ‘rotated’ within the table by the
; Animation routine, so that the first in the list is the first time
; frame1, the next time Frame2, then 3, 4, 5 and again the
; first, cyclically. This way, you just need to take the address at
; the beginning of the table each time after the ‘shuffle’ to get the
; frame addresses in sequence.

FRAMETAB:
DC.L    Frame1
DC.L    Frame2
DC.L    Frame3
DC.L    Frame4
DC.L    Frame5


;****************************************************************************
; This routine copies an animation frame to the screen.
; The position on the screen and the dimensions of the frames are constant
; A0 - source address
;****************************************************************************

;     ,-~~-.___.
;     / ()=(() \
;     ( | 0
;     \_,\, ,----“
;     ##XXXxxxxxxx
;     / ---”~;
;     / /~|-
;     =( ~~ |
;     /~~~~~~~~~~~~~~~~~~~~~\
;	 /_______________________\
;     /_________________________\
;    /___________________________\
;     |____________________|
;     |____________________| W<
;     |____________________|
;     | |

DrawFrame:
moveq    #2-1,d7            ; number of planes
lea    bitplane+80*40+6,a1    ; destination address

DrawLoop:
btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

move.l    #$ffffffff,$44(a5)    ; masks
move.l	#09f00000,$40(a5)    ; BLTCON0 and BLTCON1 (use A+D)
; normal copy
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #32,$66(a5)        ; BLTDMOD (40-8=32)
move.l    a0,$50(a5)        ; BLTAPT source pointer
move.l    a1,$54(a5)        ; BLTDPT destination pointer
move.w    #(64*55)+4,$58(a5)	; BLTSIZE (start blitter!)
; width 4 words
; height 55 lines

lea    2*4*55(a0),a0        ; point to next source plane
; each plane is 4 words wide and
; 55 lines high

lea    40*256(a1),a1		; punta al prossimo plane destinazione

dbra	d7,DisegnaLoop

rts

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

dc.w    $100,$2200    ; bplcon0

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000

dc.w    $180,$000    ; colour0
dc.w    $182,$00b    ; colour1
dc.w    $184,$cc0    ; colour2
dc.w    $186,$b00    ; colour3

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************
; Questi sono i frames che compongono l'animazione

Frame1:
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l    $003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l    $01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l    $07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l    $1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l	$3fffffcf,$fffff800,$7fffff87,$fffffc00,$7fffff03,$fffffc00
dc.l	$7ffffe01,$fffffc00,$fffffc00,$fffffe00,$fffff800,$7ffffe00
dc.l    $fffff000,$3ffffe00,$ffffff87,$fffffe00,$ffffff87,$fffffe00
dc.l    $ffffff87,$fffffe00,$ffffff87,$fffffe00,$ffffff87,$fffffe00
dc.l    $ffffff87,$fffffe00,$ffffff87,$fffffe00,$ffffff87,$fffffe00
dc.l    $7fffff87,$fffffc00,$7fffff87,$fffffc00,$7fffff87,$fffffc00
dc.l	$3fffff87,$fffff800,$3fffff87,$fffff800,$3fffffff,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l    $07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l    $01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l	$07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l    $1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffcf,$fffff800
dc.l    $3fffffb7,$fffff800,$7fffff7b,$fffffc00,$7ffffefd,$fffffc00
dc.l    $7ffffdfe,$fffffc00,$fffffbff,$7ffffe00,$fffff7ff,$bffffe00
dc.l	$ffffefff,$dffffe00,$ffffe078,$1ffffe00,$ffffff7b,$fffffe00
dc.l    $ffffff7b,$fffffe00,$ffffff7b,$fffffe00,$ffffff7b,$fffffe00
dc.l    $ffffff7b,$fffffe00,$ffffff7b,$fffffe00,$ffffff7b,$fffffe00
dc.l    $7fffff7b,$fffffc00,$7fffff7b,$fffffc00,$7fffff7b,$fffffc00
dc.l    $3fffff7b,$fffff800,$3fffff7b,$fffff800,$3fffff03,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l	$07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000


Frame2:
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l	$07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l	$1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l	$3fffffff,$fffff800,$7fffffff,$fffffc00,$7fffffff,$fffffc00
dc.l    $7fffff80,$3ffffc00,$ffffffc0,$3ffffe00,$ffffffe0,$3ffffe00
dc.l    $fffffff0,$3ffffe00,$ffffffe0,$3ffffe00,$ffffffc0,$3ffffe00
dc.l	$ffffff82,$3ffffe00,$ffffff07,$3ffffe00,$fffffe0f,$bffffe00
dc.l	$fffffc1f,$fffffe00,$fffff83f,$fffffe00,$fffff07f,$fffffe00
dc.l    $7fffe0ff,$fffffc00,$7ffff1ff,$fffffc00,$7ffffbff,$fffffc00
dc.l    $3fffffff,$fffff800,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l	$07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l    $01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l	$07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l	$1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $3fffffff,$fffff800,$7fffffff,$fffffc00,$7ffffe00,$1ffffc00
dc.l    $7ffffe7f,$dffffc00,$ffffff3f,$dffffe00,$ffffff9f,$dffffe00
dc.l	$ffffffcf,$dffffe00,$ffffff9f,$dffffe00,$ffffff3f,$dffffe00
dc.l	$fffffe7d,$dffffe00,$fffffcf8,$dffffe00,$fffff9f2,$5ffffe00
dc.l	$fffff3e7,$1ffffe00,$ffffe7cf,$9ffffe00,$ffffcf9f,$fffffe00
dc.l	$7fff9f3f,$fffffc00,$7fffce7f,$fffffc00,$7fffe4ff,$fffffc00
dc.l	$3ffff1ff,$fffff800,$3ffffbff,$fffff800,$3fffffff,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l	$07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000


Frame3:
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l    $003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l    $01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l    $07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l    $1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $3fffffff,$fffff800,$7fffffff,$fffffc00,$7ffffffd,$fffffc00
dc.l    $7ffffffc,$fffffc00,$fffffffc,$7ffffe00,$fffffffc,$3ffffe00
dc.l	$fffffffc,$1ffffe00,$ffff8000,$0ffffe00,$ffff8000,$07fffe00
dc.l	$ffff8000,$07fffe00,$ffff8000,$0ffffe00,$fffffffc,$1ffffe00
dc.l    $fffffffc,$3ffffe00,$fffffffc,$7ffffe00,$fffffffc,$fffffe00
dc.l    $7ffffffd,$fffffc00,$7fffffff,$fffffc00,$7fffffff,$fffffc00
dc.l    $3fffffff,$fffff800,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l    $07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l    $07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l    $1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $3fffffff,$fffff800,$7ffffff9,$fffffc00,$7ffffffa,$fffffc00
dc.l    $7ffffffb,$7ffffc00,$fffffffb,$bffffe00,$fffffffb,$dffffe00
dc.l    $ffff0003,$effffe00,$ffff7fff,$f7fffe00,$ffff7fff,$fbfffe00
dc.l    $ffff7fff,$fbfffe00,$ffff7fff,$f7fffe00,$ffff0003,$effffe00
dc.l    $fffffffb,$dffffe00,$fffffffb,$bffffe00,$fffffffb,$7ffffe00
dc.l    $7ffffffa,$fffffc00,$7ffffff9,$fffffc00,$7fffffff,$fffffc00
dc.l    $3fffffff,$fffff800,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l	$1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l	$07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000


Frame4:
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l    $07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l    $1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $3fffffff,$fffff800,$7ffffbff,$fffffc00,$7ffff1ff,$fffffc00
dc.l	$7fffe0ff,$fffffc00,$fffff07f,$fffffe00,$fffff83f,$fffffe00
dc.l	$fffffc1f,$fffffe00,$fffffe0f,$bffffe00,$ffffff07,$3ffffe00
dc.l    $ffffff82,$3ffffe00,$ffffffc0,$3ffffe00,$ffffffe0,$3ffffe00
dc.l    $fffffff0,$3ffffe00,$ffffffe0,$3ffffe00,$ffffffc0,$3ffffe00
dc.l    $7fffff80,$3ffffc00,$7fffffff,$fffffc00,$7fffffff,$fffffc00
dc.l	$3fffffff,$fffff800,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l	$07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l	$07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l	$1fffffff,$fffff000,$3fffffff,$fffff800,$3ffffbff,$fffff800
dc.l    $3ffff1ff,$fffff800,$7fffe4ff,$fffffc00,$7fffce7f,$fffffc00
dc.l	$7fff9f3f,$fffffc00,$ffffcf9f,$fffffe00,$ffffe7cf,$9ffffe00
dc.l	$fffff3e7,$1ffffe00,$fffff9f2,$5ffffe00,$fffffcf8,$dffffe00
dc.l	$fffffe7d,$dffffe00,$ffffff3f,$dffffe00,$ffffff9f,$dffffe00
dc.l    $ffffffcf,$dffffe00,$ffffff9f,$dffffe00,$ffffff3f,$dffffe00
dc.l    $7ffffe7f,$dffffc00,$7ffffe00,$1ffffc00,$7fffffff,$fffffc00
dc.l	$3fffffff,$fffff800,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l	$1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l	$07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000


Frame5:
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l    $07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l    $1fffffff,$fffff000,$3fffffff,$fffff800,$3fffffc3,$fffff800
dc.l    $3fffffc3,$fffff800,$7fffffc3,$fffffc00,$7fffffc3,$fffffc00
dc.l    $7fffffc3,$fffffc00,$ffffffc3,$fffffe00,$ffffffc3,$fffffe00
dc.l    $ffffffc3,$fffffe00,$ffffffc3,$fffffe00,$ffffffc3,$fffffe00
dc.l    $ffffffc3,$fffffe00,$ffffffc3,$fffffe00,$ffffffc3,$fffffe00
dc.l	$fffff800,$1ffffe00,$fffffc00,$3ffffe00,$fffffe00,$7ffffe00
dc.l	$7fffff00,$fffffc00,$7fffff81,$fffffc00,$7fffffc3,$fffffc00
dc.l    $3fffffe7,$fffff800,$3fffffff,$fffff800,$3fffffff,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l    $07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000
dc.l	$000003ff,$80000000,$00001fff,$f0000000,$0000ffff,$fe000000
dc.l	$0003ffff,$ff800000,$0007ffff,$ffc00000,$001fffff,$fff00000
dc.l	$003fffff,$fff80000,$007fffff,$fffc0000,$00ffffff,$fffe0000
dc.l	$01ffffff,$ffff0000,$03ffffff,$ffff8000,$07ffffff,$ffffc000
dc.l	$07ffffff,$ffffc000,$0fffffff,$ffffe000,$1fffffff,$fffff000
dc.l    $1fffffff,$fffff000,$3fffff81,$fffff800,$3fffffbd,$fffff800
dc.l    $3fffffbd,$fffff800,$7fffffbd,$fffffc00,$7fffffbd,$fffffc00
dc.l    $7fffffbd,$fffffc00,$ffffffbd,$fffffe00,$ffffffbd,$fffffe00
dc.l    $ffffffbd,$fffffe00,$ffffffbd,$fffffe00,$ffffffbd,$fffffe00
dc.l    $ffffffbd,$fffffe00,$ffffffbd,$fffffe00,$fffff03c,$0ffffe00
dc.l    $fffff7ff,$effffe00,$fffffbff,$dffffe00,$fffffdff,$bffffe00
dc.l    $7ffffeff,$7ffffc00,$7fffff7e,$fffffc00,$7fffffbd,$fffffc00
dc.l    $3fffffdb,$fffff800,$3fffffe7,$fffff800,$3fffffff,$fffff800
dc.l    $1fffffff,$fffff000,$1fffffff,$fffff000,$0fffffff,$ffffe000
dc.l    $07ffffff,$ffffc000,$07ffffff,$ffffc000,$03ffffff,$ffff8000
dc.l	$01ffffff,$ffff0000,$00ffffff,$fffe0000,$007fffff,$fffc0000
dc.l	$003fffff,$fff80000,$001fffff,$fff00000,$0007ffff,$ffc00000
dc.l	$0003ffff,$ff800000,$0000ffff,$fe000000,$00001fff,$f0000000
dc.l	$000003ff,$80000000

;****************************************************************************

SECTION	bitplane,BSS_C

BITPLANE:
ds.b	40*256		; 2 bitplanes
ds.b	40*256

;****************************************************************************

end

In this example, we show a ‘forward/backward’ animation created
with the blitter. The animation consists of 5 frames. These frames
are first shown from the first to the last and then immediately afterwards
in reverse order until returning to the first.
The order is therefore as follows: 1-2-3-4-5-4-3-2-1-2-3- etc.
To achieve this order, we have an animation routine which, based on
the status of a flag, scrolls the addresses in the table forwards or
backwards. When the first or last frame reaches the first
position in the table, the flag status is inverted, causing
the animation direction to reverse.
The drawing routine is identical to that in lesson10l1.s.

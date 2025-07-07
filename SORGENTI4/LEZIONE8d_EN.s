
; A FADE routine (i.e. fade) from and to BLACK. ROUTINE NO. 2
; Press the left and right keys

SECTION    Fade1,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA
;         -----a-bcdefghij

;    a: Blitter Nasty
;    b: Bitplane DMA	 (If not set, sprites will also disappear)
;    c: Copper DMA
;    d: Blitter DMA
;    e: Sprite DMA
;    f: Disk DMA
;    g-j: Audio 3-0 DMA

START:
;    point to the figure

MOVE.L    #Logo1,d0    ; where to point
LEA	BPLPOINTERS,A1    ; COP pointers
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


mouse1:
btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse1

clr.w    FaseDelFade    ; reset frame number

mouse2:
CMP.b    #$ff,$dff006    ; line 255
bne.s    mouse2
Wait1:
CMP.b    #$ff,$dff006    ; line 255
beq.s    Wait1

bsr.w    FadeIN        ; Fade!!!

btst    #2,$dff016    ; mouse pressed?
bne.s    mouse2

move.w    #16,FadePhase    ; start from frame 16

mouse3:
CMP.b    #$ff,$dff006    ; line 255
bne.s    mouse3
Wait2:
CMP.b    #$ff,$dff006    ; line 255
beq.s    Wait2

bsr.w    FadeOUT    ; Fade!!!

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse3

rts


*****************************************************************************
;	Routines che aspettano e richiamano Fade al momento giusto
*****************************************************************************

FadeIn:
cmp.w	#17,FaseDelFade
beq.s    FinitoFadeIn
moveq    #0,d0
move.w    FaseDelFade(PC),d0
moveq    #15-1,d7        ; D7 = Number of colours
lea    TabColoriPic(PC),a0    ; A0 = colour table address
; of the figure to be ‘dissolved’
lea    CopColors+6,a1        ; A1 = colour address in copperlist
; note that it starts from COLOUR1 and
; not from colour0, as colour0
; is =$000 and remains so.
bsr.s    Fade
addq.w    #1,FaseDelFade    ; sets the phase to be performed next time
FinitoFadeIn:
rts


FadeOut:
tst.w    FadePhase    ; have we passed the last phase? (16)?
beq.s    FinitoOut
subq.w    #1,FadePhase    ; set the phase to be performed next time
moveq    #0,d0
move.w    FadePhase(PC),d0
moveq    #15-1,d7        ; D7 = Number of colours
lea    TabColoriPic(PC),a0    ; A0 = colour table address
; of the figure to be ‘dissolved’
lea    CopColors+6,a1        ; A1 = colour address in copperlist
; note that it starts from COLOR1 and
; not from colour 0, as colour 0
; is = $000 and remains so.
bsr.s    Fade
FinitoOut:
rts

FaseDelFade:        ; current phase of the fade (0-16)
dc.w    0

*****************************************************************************
*        Routine for Fade In/Out from and to BLACK (version 2)     *
* Input:                                 *
*                                     *
* d7 = Number of colours-1                             *
* a0 = Address of table with the colours of the figure			 *
* a1 = Address of first colour in copperlist                 *
* d0 = Fade time, multiplier - for example, with d0=0 the screen     *
*    is completely white, with d0=8 we are halfway through the fade and with d0=16     *
*    we are at full colour; therefore, there are 17 phases, from 0 to 16.	 *
*    To do a fade IN, from white to colour, you must give each *
*    call to the routine a value of d0 increasing from 0 to 16 *
*    For a fade OUT, you must start from d0=16 to d0=0 *
*									 *
* The FADE process is to multiply each R, G, B *
* component of the colour by a Multiplier, ranging from 0 for BLACK (x*0=0) to 16 for *
* normal colours, since the colour is then divided by 16,     *
* multiplying a colour by 16 and dividing it again simply leaves it the same. *
*
*****************************************************************************

;     . .-~\
;     / `-“\.” `- :
;     | / `._
;     | | .-. {
;     \ | `-“ `.
;     . \ | /
;    ~-.`. \| .-~_
;     `.\-.\ .-~ \
;     `-”/~~ -.~ /
;     .-~/|`-._ /~~-.~ -- ~
;     / | \ ~- . _\

Fade:
;    Calculate the BLUE component

MOVE.W	(A0),D4        ; Put the colour from the colour table in d4
AND.W    #$00f,D4    ; Select only the blue component ($RGB->$00B)
MULU.W    D0,D4        ; Multiply by the fade phase (0-16)
ASR.W    #4,D4        ; shift 4 BITS to the right, i.e. division by 16
AND.W    #$00f,D4    ; Select only the BLUE component
MOVE.W    D4,D5        ; Save the BLUE component in d5

;    Calculate the GREEN component

MOVE.W    (A0),D4        ; Put the colour from the colour table in d4
AND.W    #$0f0,D4    ; Select only the green component ($RGB->$0G0)
MULU.W    D0,D4        ; Multiply by the fade phase (0-16)
ASR.W	#4,D4        ; shift 4 BITS to the right, i.e. division by 16
AND.W    #$0f0,D4    ; Select only the GREEN component
OR.W    D4,D5        ; Save the green component together with the BLUE one

;    Calculate the RED component

MOVE.W    (A0)+,D4    ; read the colour from the table
; and point a0 to the next colour.
AND.W    #$f00,D4    ; Select only the red component ($RGB->$R00)
MULU.W    D0,D4        ; Multiply by the fade phase (0-16)
ASR.W	#4,D4        ; shift 4 BITS to the right, i.e. divide by 16
AND.W    #$f00,D4    ; Select only the red component ($RGB->$R00)
OR.W    D4,D5        ; Save the RED colour together with the BLUE and GREEN

MOVE.W    D5,(A1)		; And put the final $0RGB colour in the copperlist
addq.w    #4,a1        ; next colour in the copperlist
DBRA    D7,Fade        ; do all colours
rts


; $180, colour0, is $000, so it doesn't change! The table starts from colour1

TabColoriPic:
dc.w $fff,$200,$310,$410,$620,$841,$a73
dc.w $b95,$db6,$dc7,$111,$222,$334,$99b,$446


*****************************************************************************
;            Copper List
*****************************************************************************
section    copper,data_c        ; Chip data

Copperlist:
dc.w    $8E,$2c81    ; DiwStrt - window start
dc.w    $90,$2cc1    ; DiwStop - window stop
dc.w    $92,$38        ; DdfStart - data fetch start
dc.w    $94,$d0		; DdfStop - data fetch stop
dc.w    $102,0        ; BplCon1 - scroll register
dc.w    $104,0        ; BplCon2 - priority register
dc.w    $108,0        ; Bpl1Mod - odd pl module
dc.w    $10a,0        ; Bpl2Mod - even pl module

; 5432109876543210
dc.w    $100,%0100001000000000    ; BPLCON0 - 4 low-resolution planes (16 colours)

; Bitplane pointers

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000	;third bitplane
dc.w $ec,$0000,$ee,$0000    ;fourth bitplane

; the first 16 colours are for the LOGO

CopColors:
dc.w $180,0,$182,0,$184,0,$186,0
dc.w $188,0,$18a,0,$18c,0,$18e,0
dc.w $190,0,$192,0,$194,0,$196,0
dc.w $198,0,$19a,0,$19c,0,$19e,0

;	dc.w $180,$000,$182,$fff,$184,$200,$186,$310
;	dc.w $188,$410,$18a,$620,$18c,$841,$18e,$a73
;	dc.w $190,$b95,$192,$db6,$194,$dc7,$196,$111
;	dc.w $198,$222,$19a,$334,$19c,$99b,$19e,$446

;    Let's add some shading to the scenery...

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
dc.w    $180,$666	; colour0
dc.w    $a207,$fffe    ; wait
dc.w    $180,$222    ; colour0
dc.w    $a407,$fffe    ; wait
dc.w    $180,$001    ; colour0

dc.l	$ffff,$fffe	; Fine della copperlist


*****************************************************************************
;				DISEGNO
*****************************************************************************

section    gfxstuff,data_c

; Drawing 320 pixels wide, 84 high, with 4 bitplanes (16 colours).

Logo1:
incbin    “logo320*84*16c.raw”

end

This routine works exactly like the previous one, but does not write the
colour word one byte at a time. This routine lends itself more to modifications
to make it AGA. In fact, we will see it “AGhizzAta” in the lesson on AGA.
The discussion of the multiplication and division of the R, G, B components
will be extended to one byte for each R, G, B component.

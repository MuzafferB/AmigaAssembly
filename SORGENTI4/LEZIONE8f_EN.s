
; A FADE routine (i.e. fade) from and to ANY COLOUR
; Press the left and right keys alternately to see the various
; uses of the routine and to exit

SECTION    Fade1,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU    %1000001110000000    ; only copper and bitplane DMA
;         -----a-bcdefghij

;    a: Blitter Nasty
;    b: Bitplane DMA     (If not set, sprites will also disappear)
;    c: Copper DMA
;    d: Blitter DMA
;    e: Sprite DMA
;    f: Disk DMA
;    g-j: Audio 3-0 DMA

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
ADD.L    #40*84,d0    ; + bitplane length (here it is 84 lines high)
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

;    ********** first fade: from BLACK to colours *********

mouse2:
CMP.b    #$ff,$dff006    ; line 255
bne.s    mouse2
Wait1:
CMP.b    #$ff,$dff006    ; line 255
beq.s    Wait1

lea    Cstart1-2,a1    ; Start colour table
lea    Cend1-2,a2    ; End colour table
bsr.w    dofade        ; Fade!!!


btst    #2,$dff016    ; mouse pressed?
bne.s    mouse2

clr.w    FadePhase        ; reset frame number

;    ********** second fade: from colours to BLACK *********

mouse3:
CMP.b    #$ff,$dff006    ; line 255
bne.s    mouse3
Wait2:
CMP.b    #$ff,$dff006    ; line 255
beq.s    Wait2

lea    Cstart2-2,a1    ; Start-colour-table
lea    Cend2-2,a2    ; End-colour-table
bsr.w    dofade        ; Fade!!!


btst	#6,$bfe001    ; mouse pressed?
bne.s    mouse3

clr.w    FadePhase        ; reset frame number

;    ********** third fade: from WHITE to colours *********

mouse4:
CMP.b    #$ff,$dff006	; line 255
bne.s    mouse4
Wait3:
CMP.b    #$ff,$dff006    ; line 255
beq.s    Wait3

lea    Cstart3-2,a1    ; Start-colour-table
lea    Cend3-2,a2    ; End-colour-table
bsr.w    dofade        ; Fade!!!


btst    #2,$dff016    ; mouse pressed?
bne.s    mouse4

clr.w    FaseDelFade        ; reset frame number

;    ********** fourth fade: change COLOURS to other different colours! *********

mouse5:
CMP.b    #$ff,$dff006    ; line 255
bne.s    mouse5
Wait4:
CMP.b    #$ff,$dff006    ; line 255
beq.s    Wait4

lea    Cstart4-2,a1    ; Start-colour-table
lea    Cend4-2,a2    ; End-colour-table
bsr.w    dofade        ; Fade!!!


btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse5

clr.w    FadePhase        ; reset frame number

;    ********** fifth fade: change COLOURS to other colours! *********

mouse6:
CMP.b    #$ff,$dff006    ; line 255
bne.s    mouse6
Wait5:
CMP.b    #$ff,$dff006    ; line 255
beq.s    Wait5

lea    Cstart5-2,a1    ; Start-colour-table
lea    Cend5-2,a2    ; End-colour-table
bsr.w    dofade        ; Fade!!!

btst    #2,$dff016    ; mouse pressed?
bne.s    mouse6

rts


*****************************************************************************
*    Routine for Fade In/Out from and to any colour!         *
* Input:								 *
*
* d6 = Number of colours-1 *
* a1 = Address of table1 with the colours of the figure (source) *
* a2 = Address of table2 with the colours of the figure (destination) *
* a0 = Address of first colour in copperlist *
* label FaseDelFade used as d0 for previous routines, *
* = Fade time, multiplier, but in this case it must be reset to zero *
* simply to start a new fade *
*									 *
* The routine is more complex than the previous ones, and *
* to be honest, I don't even remember exactly how it works. *
* Read my old comments, but all you need to know is how to use it *
*
*****************************************************************************

;     .--._.--.
;     ( O O )
;     / . . \
;     .`._______.“.
;     /( \_/ )\
;     _/ \ \ / / \_
;     .~ ` \ \ / / ” ~.
;     { -. \ V / .- }
;    _ _`. \ | | / .“_ _ 
;    >_ _} | | | {_ _<
 
;     /. - ~ ,_-” .^. `-_, ~ - .\
;     “-”|/ \|`-`

dofade:
cmp.w    #17,FaseDelFade    ; Have we passed the last phase? (16)?
beq.s    FadeFinito
lea    CopColors+2,a0    ; Copper
move.w    #15-1,d6    ; No. colours
bsr.w    fade2        ; Do fading!
FadeFinito:
rts

; Uses d0-d6/a0-a2

fade2:
f2main:
addq.w    #4,a0    ; go to the next colour register in copperlist
addq.w    #2,a1    ; go to the next colour in the source colour table
addq.w    #2,a2    ; same for the destination colour table
move.w    (a0),d0        ; colour from copperlist to d0
move.w (a2),d1        ; destination tab colour in d1
cmp.w d0,d1        ; are they the same?
beq.w NextColour        ; if yes, go to the next colour
move.w	FadePhase(PC),d4    ; fade phase in d4 (0-16)
clr.w    FinalColour        ; reset the final colour

;    BLUE

move.w    (a1),d0        ; current colour of the source table in d0
move.w    (a2),d2        ; destination table colour in d2
and.l    #$00f,d0    ; select only BLUE from the source tab colour
and.l    #$00f,d2    ; same for the destination tab colour
cmp.w    d2,d0        ; are the source and destination BLU the same?
bhi.b    SubtractD2    ; if d2>d0, FadCh1a
beq.b	SubtractD2    ; if they are the same, subtract d2
sub.w    d0,d2        ; if d2<d0, subtract d0 from d2!
bra.b	Sub
SubtractD2:
sub.w    d2,d0        ; otherwise subtract d2 from d0!
bra.b    Sub2

Sub:
move.w    d2,d0
Sub2:
moveq    #16,d1
bsr.w    dodivu
and.w    #$00f,d1    ; select only BLUE
move.w    (a1),d0        ; current colour of the source tab in d0
move.w    (a2),d2        ; destination tab colour in d2
and.w    #$00f,d0    ; select only BLUE from the source tab colour
and.w    #$00f,d2    ; same for the destination tab colour
cmp.w    d0,d2		; are the source and destination BLU the same?
bhi.b    SumD1        ; if d0>d2, add d1 to d0
beq.b    OkBlu        ; if they are the same, OK
sub.w    d1,d0        ; d0=d0-d1
bra.b    OkBlu
SumD1:
add.w    d1,d0        ; d0=d0+d1
OkBlu:
move.w    d0,FinalColour    ; Save the final BLUE

; GREEN

move.w    (a1),d0        ; current colour of the source tab in d0
move.w    (a2),d2        ; destination tab colour in d2
and.l    #$0f0,d0    ; select only GREEN from the source tab colour
and.l    #$0f0,d2    ; same for the destination tab colour
cmp.w    d2,d0		; are the source and destination GREEN the same?
bhi.b    SubtractD2v    ; if d2>d0, FadCh1a
beq.b    SubtractD2v    ; if they are the same, subtract d2
sub.w    d0,d2        ; if d2<d0, subtract d0 from d2!
bra.b	SubFattov
SubtractD2v:
sub.w    d2,d0        ; otherwise subtract d2 from d0!
bra.b    SubFatto2v

SubFattov:
move.w    d2,d0
SubFatto2v:
moveq    #16,d1
bsr.w    dodivu
and.w    #$0f0,d1    ; select only GREEN
move.w    (a1),d0        ; current colour of the source tab in d0
move.w    (a2),d2        ; destination tab colour in d2
and.w    #$0f0,d0	; select only GREEN from the source tab colour
and.w    #$0f0,d2    ; same for the destination tab colour
cmp.w    d0,d2        ; are the source and destination GREEN colours the same?
bhi.b    SumD1v    ; if d0>d2, add d1 to d0
beq.b	OkGREEN        ; if they are the same, ok
sub.w    d1,d0        ; d0=d0-d1
bra.b    OkGREEN
SumD1v:
add.w    d1,d0        ; d0=d0+d1
OkGREEN:
or.w    d0,FinalColour    ; with OR, set the green component

;    RED

move.w    (a1),d0        ; current colour of the source tab in d0
move.w    (a2),d2        ; destination tab colour in d2
and.l    #$f00,d0    ; select only RED from the source tab colour
and.l    #$f00,d2	; same for destination tab colour
cmp.w    d2,d0        ; are source and destination RED the same?
bhi.b    SubtractD2r    ; if d2>d0, FadCh1a
beq.b	SubtractD2r    ; if they are the same, subtract d2
sub.w    d0,d2        ; if d2<d0, subtract d0 from d2!
bra.b    SubFactor
SubtractD2r:
sub.w    d2,d0        ; otherwise subtract d2 from d0!
bra.b    SubFactor2r

Subfactor:
move.w    d2,d0
Subfactor2r:
moveq    #16,d1
bsr.w    dodivu
and.w    #$f00,d1    ; select only RED
move.w    (a1),d0        ; current colour of the source tab in d0
move.w	(a2),d2        ; destination tab colour in d2
and.w    #$f00,d0    ; select only RED from the source tab colour
and.w    #$f00,d2    ; same for the destination tab colour
cmp.w    d0,d2		; are the source and destination RED colours the same?
bhi.b    SumD1r    ; if d0>d2, add d1 to d0
beq.b    OkRED        ; if they are the same, OK
sub.w    d1,d0        ; d0=d0-d1
bra.b    OkRED
SumD1r:
add.w    d1,d0        ; d0=d0+d1
OkRED:
or.w    d0,FinalColour    ; with OR, set the red component

;    Put the colour in the copperlist!

move.w    FinalColour(PC),(a0)    ; and put the final colour in copper!

NextColour:
dbra    d6,f2main    ; repeat for each colour

addq.w    #1,FadePhase    ; set the phase to be done next time
nocrs:
rts

***
*    Input -> D0 = Numerator
*         D1 = Denominator    (16)
*         D4 = * multiplication factor
*
* Output -> D1 = Result
***

DoDivu:
divu.w    d1,d0    ; division by 16, cannot be optimised with lsr
move.l    d0,d1
swap    d1
move.l    #$31000,d2    ;$10003 (65539) divu 16
moveq    #0,d3
move.w    d1,d3
mulu.w    d3,d2
move.w    d2,d1

and.l    #$ffff,d1
mulu.w    d4,d1        ; multiply by the fade phase
swap    d1
mulu.w    d4,d0		; multiply by the fade phase
add.w    d0,d1
and.l    #$ffff,d1
rts

FaseDelFade:        ; current fade phase (0-16)
dc.w    0

;    The final colour is saved in this label each time

ColoreFinale:
dc.w    0

; ---

Cstart1:
dcb.w    15,0    ; start from black
Cend1:
dc.w $fff,$200,$310,$410,$620,$841,$a73		; e arriviamo ai colori
dc.w $b95,$db6,$dc7,$111,$222,$334,$99b,$446
;=----------

Cstart2:
dc.w $fff,$200,$310,$410,$620,$841,$a73        ; let's start with the colours
dc.w $b95,$db6,$dc7,$111,$222,$334,$99b,$446
Cend2:
dcb.w    15,0            ; and finish with black
;=----------

Cstart3:
dcb.w    15,$FFF    ; start with WHITE
Cend3:
dc.w $fff,$200,$310,$410,$620,$841,$a73		; and we arrive at the colours
dc.w $b95,$db6,$dc7,$111,$222,$334,$99b,$446
;=----------

Cstart4:
dc.w $fff,$200,$310,$410,$620,$841,$a73        ; let's start with the colours
dc.w $b95,$db6,$dc7,$111,$222,$334,$99b,$446
Cend4:
dc.w $fff,$020,$031,$041,$062,$184,$3a7		; and we get colours
dc.w $5b9,$6db,$7dc,$111,$222,$433,$b99,$644    ; different! (green tone)
;=----------

Cstart5:
dc.w $fff,$020,$031,$041,$062,$184,$3a7		; let's start with colours
dc.w $5b9,$6db,$7dc,$111,$222,$433,$b99,$644    ; different! (green tone)
Cend5:
dc.w $fff,$002,$013,$014,$026,$148,$37a		; and others
dc.w $59b,$6bd,$7cd,$111,$222,$334,$99b,$446    ; different! (blue tone)
;=----------


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
dc.w    $94,$d0        ; DdfStop - data fetch stop
dc.w	$102,0        ; BplCon1 - scroll register
dc.w    $104,0        ; BplCon2 - priority register
dc.w    $108,0        ; Bpl1Mod - odd pl module
dc.w    $10a,0        ; Bpl2Mod - even pl module

; 5432109876543210
dc.w    $100,%0100001000000000    ; BPLCON0 - 4 low-resolution planes (16 colours)

; Bitplane pointers

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000    ;third bitplane
dc.w $ec,$0000,$ee,$0000    ;fourth bitplane

; the first 16 colours are for LOGO

CopColors:
dc.w $180,0,$182,0,$184,0,$186,0
dc.w $188,0,$18a,0,$18c,0,$18e,0
dc.w $190,0,$192,0,$194,0,$196,0
dc.w $198,0,$19a,0,$19c,0,$19e,0

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
dc.w    $180,$666    ; colour0
dc.w    $a207,$fffe    ; wait
dc.w    $180,$222    ; colour0
dc.w    $a407,$fffe    ; wait
dc.w    $180,$001    ; colour0

dc.l    $ffff,$fffe    ; End of copperlist


*****************************************************************************
;                DESIGN
*****************************************************************************

section    gfxstuff,data_c

; Design 320 pixels wide, 84 high, with 4 bitplanes (16 colours).

Logo1:
incbin    “logo320*84*16c.raw”

end

Here is a routine that ‘transforms’ colours as we want.
The principle of operation is more complex than a normal fade, so
just understand how to use it. If you want to fry your brain,
however, I have added some comments.

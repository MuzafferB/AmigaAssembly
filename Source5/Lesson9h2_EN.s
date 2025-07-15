
; Lesson 9h2.s    BLITTATA, in which we copy a rectangle (in a normal pic)
;        not aligned with a word, using masks to ‘fill in’.
;        Pressing the right mouse button performs the ‘dirty’ blitting
;        Then, pressing the left mouse button performs the correct blitting
;		and finally pressing the right button again exits.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*256,d0        ; + LENGTH OF A PLANE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse1:
btst    #2,$dff016        ; right mouse button pressed?
bne.s    mouse1            ; if not, wait

; First Blit, with masks that also allow unwanted data to pass
;

lea    bitplane+((20*170)+80/16)*2,a0        ; destination ind.
move.w    #ffff,d0                ; pass everything
move.w    #ffff,d1                ; pass everything
bsr.s    copy

mouse2:
btst    #6,$bfe001	; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

; Second bit, thanks to the masks only the 
; letter ‘I’

is copied. lea    bitplane+((20*170)+160/16)*2,a0        ; destination ind.
move.w	#%0000000000001111,d0    ; pass the 4 bits furthest to the right
move.w    #%1111000000000000,d1    ; pass the 4 bits furthest to the left
bsr.s    copy

mouse3:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse3        ; if not, wait

rts

;****************************************************************************
; This routine copies the figure on the screen.
;
; A0 - destination address
; D0.w - first word mask
; D1.w - last word mask
;****************************************************************************

;     ___________
;     (_____ _____)
;     /(_o(___)O_)\
;    / ___________ \
;    \ \____l____/ /|
;    |\_`---“---'_/ |
;    | `---------” |
;    | T xCz T |
;    l__| l__|
;    (__)---^----(__)
;     T T |
;     _l____l_____|_
;    (______X_______)

copy:

lea    bitplane+((20*78)+128/16)*2,a1    ; fixed source address

moveq    #3-1,d7        ; repeat for each plane
PlaneLoop:
btst    #6,2(a5)    ; wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)	; BLTCON0 and BLTCON1 - copy from A to D

; load parameters into masks
move.w    d0,$44(a5)        ; BLTAFWM mask on the left
move.w    d1,$46(a5)        ; BLTALWM mask on the right

; load pointers

move.l    a1,$50(a5)        ; bltapt - source 
move.l    a0,$54(a5)        ; bltdpt - destination

move.l #$00240024,$64(a5)    ; bltamod and bltdmod 

move.w    #(60*64)+2,$58(a5)	; bltsize
; height 60 lines
; width 2 words

lea    40*256(a1),a1        ; point to the next source plane
lea    40*256(a0),a0        ; point to the next destination plane

dbra    d7,PlaneLoop

btst    #6,$02(a5)	; aspetta che il blitter finisca
waitblit2:
btst	#6,$02(a5)
bne.s	waitblit2
rts

;****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0		; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

; NORMAL IMAGES!!!!!!
dc.w    $108,0        ; MODULE VALUE = 0
dc.w    $10a,0		; BOTH MODULES AT THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777	; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

BITPLANE:
incbin    ‘assembler2:sorgenti6/amiga.raw’
; here we load the image in
; RAW format converted with KEFCON.
end

;****************************************************************************

In this example, we highlight how, by using masks
,
 it is possible to extract ‘pieces’ of an image by deleting unwanted parts.
 In this case, we want to copy only the letter ‘I’ from the
word Amiga. This letter is contained in a rectangle 2 words wide.
However, the rectangle also contains pieces of other letters.
The first blit is performed with the masks set to $ffff, i.e.
set so that all pixels are passed.
As you can see, pieces of other letters are also copied.
The second blit, on the other hand, has the masks set to appropriate values
so that only the pixels that form the letter ‘I’ are passed.


; Lesson 9h3r.s    Let's display an image one column of pixels at a time
;        Right click to execute the blit, left click to exit.
;        Note: image in RAWBLIT (or interleaved, if you prefer).

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
MOVEQ	#3-1,D1        ; number of bitplanes (here there are 3)
POINTBP:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
; HERE IS THE DIFFERENCE COMPARED
; TO NORMAL IMAGES!!!!!!
ADD.L    #40,d0        ; + LENGTH OF A LINE !!!!!
addq.w    #8,a1
dbra    d1,POINTBP

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1        ; if not, wait

bsr.s    Show        ; run the routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts


; ************************ THE ROUTINE THAT DISPLAYS THE FIGURE *******************

;     .øØØØØØø.
;     |¤¯_ _¬¤|
;     _|___ ___|_
;     (_| (·T.) l_)
;     / ¯(_)¯ \
;     /____ _ ____\
;     // Y Y \\
;     //__/\_____/\__\\ xCz
;    (_________________)

Show:

; initial pointer values

lea    picture,a0        ; points to the beginning of the figure
lea    bitplane,a1        ; points to the beginning of the first bitplane

moveq    #20-1,d7        ; execute for each ‘column’ of words.
; the screen is 20 words wide, so
; there are 20 columns.

DoAllWords:
moveq    #16-1,d6        ; 16 pixels for each word.
move.w    #%1000000000000000,d0    ; value of the mask at the beginning of the
; internal loop. Only passes the
; leftmost pixel of the word.
DoOneWord:

; wait for vblank so as to draw a column of pixels at each
; frame.

WaitWblank:
CMP.b    #$ff,$dff006        ; vhposr - wait for line 255
bne.s    WaitWblank
Wait:
CMP.b    #$ff,$dff006        ; vhposr - still line 255?
beq.s    Wait

btst    #6,2(a5)    ; dmaconr - wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #09f00000,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
move.w    #ffff,$44(a5)        ; BLTAFWM - pass all bits
move.w    d0,$46(a5)		; Load the mask value into the
; BLTALWM
; register load pointers

move.l    a0,$50(a5)        ; bltapt
move.l    a1,$54(a5)        ; bltdpt

; For both the source and destination, we bleak a word belonging
; to a 20-word wide screen. The module is therefore 2*(20-1)=38=$26.
; Since the two registers have consecutive addresses, a single
; instruction can be used instead of two:

move.l #$00260026,$64(a5)    ; bltamod and bltdmod 

; we bleed a ‘column’ of words 256 lines high (the entire screen)

move.w    #(3*256*64)+1,$58(a5)    ; bltsize
; height 256 lines of 3 planes
; width 1 word

asr.w    #1,d0            ; calculate the mask for the next
; bli. Pass one
; more bit each time than the
; previous time.

dbra    d6,FaiUnaWord        ; repeat for all pixels

addq.w    #2,a0            ; point to the next word
addq.w	#2,a1            ; point to the next word

dbra    d7,DoAllWords    ; repeat for all words

btst    #6,$02(a5)    ; dmaconr - wait for the blitter to finish
waitblit2:
btst    #6,$02(a5)
bne.s    waitblit2

rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0		; BplCon1
dc.w    $104,0        ; BplCon2

; HERE IS A DIFFERENCE COMPARED
; TO THE NORMAL IMAGES!!!!!!
dc.w    $108,80        ; MODULE VALUE = 2*20*(3-1)= 80
dc.w    $10a,80        ; BOTH MODULES HAVE THE SAME VALUE.

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0180,$000	; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

PICTURE:
incbin    ‘assembler2:sorgenti6/amiga.rawblit’
; here we load the image in
; RAWBLIT (or interleaved) format,
; converted with KEFCON.

;****************************************************************************

section	gnippi,bss_C

bitplane:
ds.b	40*256	; 3 bitplanes
ds.b	40*256
ds.b	40*256
end

;****************************************************************************

This example is the rawblit version of lesson9h3.s.
Compare the differences in the formulas for calculating the values to be written
in the blitter registers.

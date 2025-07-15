
; Lesson9f1.s    BLITTATA, in which we copy a rectangle from one point
;        to another on the same screen
;        Left key to execute the blit, right to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
MOVEQ    #3-1,D1        ; number of bitplanes (here there are 3)
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

mouse1:
btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1		; if not, do not delete

bsr.s    copy        ; execute the copy routine

mouse2:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse2        ; if not, return to mouse2:

rts

; ************************ THE COPY ROUTINE ****************************

; a rectangle with width=160 and height=20
; from coordinates X1=64, Y1=50 (source)
; to coordinates X2=80, Y2=190 (destination)

;     . , _ .
;     ¦\_|/_/l
;     /¯/¬\/¬\¯\
;     /_( ©( ® )_\
;    l/_¯\_/\_/¯_\\
;    / T (____) T \\
;    \/\___/\__/ //
;    (_/ __ T|
;     l (. ) |l\
;     \ ¯¯ // /
;     \______//¯¯
;     __Tl___Tl xCz
;     C____(____)

copy:

; Load the source and destination addresses into 2 variables

move.l    #bitplane+((20*50)+64/16)*2,d0    ; source address
move.l    #bitplane+((20*190)+80/16)*2,d2    ; destination address

; Blit loop
moveq	#3-1,d1        ; repeat for all bit planes
copy_loop:
btst    #6,2(a5)    ; wait for the blitter to finish
waitblit:
btst    #6,2(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)	; bltcon0 and BLTCON1 - copy from A to D
move.l    #$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later

; load pointers

move.l    d0,$50(a5)    ; bltapt
move.l    d2,$54(a5)    ; bltdpt

; These two instructions set the source and destination modules
; note that since the source and destination are within the same
; screen, the module is the same.
; The module is calculated according to the formula (H-L)*2 (H is the width of the
; bitplane in words and L is the width of the image, also in words)
; which we saw in class, (20-160/16)*2=20

move.w    #(20-160/16)*2,$64(a5)    ; bltamod
move.w    #(20-160/16)*2,$66(a5)    ; bltdmod

; Note also that since the two registers have consecutive addresses,
; you can use a single instruction instead of two (remember that 20=$14):
; move.l #$00140014,$64(a5)    ; bltamod and bltdmod 

move.w    #(20*64)+160/16,$58(a5)        ; bltsize
; height 20 lines
; width 160 pixels (= 10 words)

; Update the variables containing the addresses to make them point
; to the following bitplanes
 

add.l    #40*256,d2    ; destination address of next plane 
add.l    #40*256,d0    ; source address of next plane

dbra    d1,copia_loop

btst    #6,$02(a5)    ; wait for the blitter to finish
waitblit2:
btst    #6,$02(a5)
bne.s	waitblit2
rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$3200    ; bplcon0 - 1 bitplane lowres

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
dc.w $e4,$0000,$e6,$0000
dc.w $e8,$0000,$ea,$0000

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999	; color4
dc.w    $018a,$232    ; color5
dc.w    $018c,$777    ; color6
dc.w    $018e,$444    ; color7

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

BITPLANE:
incbin	‘assembler2:sorgenti6/amiga.raw’	; qua carichiamo la figura

end

;****************************************************************************

In this example, we use the blitter to copy an image consisting of 3 bitplanes.
Note how the loop in which the blits are performed is structured.
The source and destination addresses are loaded into two data registers
of the processor, which are used as variables. At each iteration, they are
modified to point to the next bitplane. For this, we use the formula

ADDRESS2 = ADDRESS1+2*H*V

which we saw in class. In our example, V=256 (the number of rows)
and H=20 (the width of the screen in words).

In this example, the source and destination of the blitting are contained
in the same screen. For this reason, the module is the same for both,
and is calculated according to the usual formula.

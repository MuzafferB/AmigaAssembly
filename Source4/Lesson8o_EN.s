
; Lesson 8o.s    8 high bars 13*2 lines each that bounce.
;        Right click to disable background cleaning.

SECTION    Bars,CODE

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %100000101000000    ; only copper DMA
;         -----a-bcdefghij

;    a: Blitter Nasty
;    b: Bitplane DMA     (If not set, sprites also disappear)
;    c: Copper DMA
;    d: Blitter DMA
;	e: Sprite DMA
;    f: Disk DMA
;    g-j: Audio 3-0 DMA

START:
BSR.s    INITCOPPER        ; Create the copperlist with a routine

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10800,d2    ; line to wait for = $108
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $108
BNE.S    Waity1

btst    #2,$16(a5)    ; Right mouse button pressed?
beq.s    SaltaPulizia    ; If yes, do not ‘clean’

BSR.s    CLRCOPPER    ; ‘Clear’ the copper background

SkipCleaning:
BSR.s    DOBARS        ; Make the bars

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

rts

*************************************************************************
*    BARRE COL COPPER - instructions:                    *
*
*    BSR.s INITCOPPER ; run before pointing to the Copperlist to *
*             ; create the copperlist (made of WAIT and COLOR0)*
*
*	BSR.s CLRCOPPER     ; run to delete the old bars    *
*             ; ‘blackening’ all COLOR0s in the copperlist    *
*             ; NOTE: you can change the background colour*
*             ; by changing the equate SFONDO = $xxx        *
*
*	BSR.s DOBARS     ; Display the bars    by calling PUTBARS    *
*                                    *
*************************************************************************

coplines    =    100    ; number of copperlist lines to make for
; the bar effect.
SFONDO        =    $004    ; ‘Background’ colour


;     /¯¯¯¯¯¯¯¯¯¯\
;     .~ ~.
;     | · \/ : |
;     | |_____||___| |
;    .--./ ___ \/ __\.-.
;    |~\/ ( o~\></o~)\~|
;    `c( ¯¯¯_/ \¯¯ )'
;     /\ ( ( )¯) /\
;     / .'___~\_/~___ \
;     \ {IIIII[]II:· /
;     \ \::. // /
;     \ \::::.// /
;     \ \\IIII]_/
;     \ ¯¯¯¯ )
;     \ ¯¯¯¯¯/
;     ¯~~~~¯¯

; INITCOPPER creates the copperlist part with many WAIT and COLOR0 in succession

INITCOPPER:
lea    barcopper,a0    ; Address where to create the copperlist
move.l    #$3001fffe,d1    ; First wait: line $30 - WAIT in d1
move.l    #$01800000,d2    ; COLOR0 in d2
move.w #coplines-1,d0	; number of copper lines
initloop:
move.l    d1,(a0)+    ; set WAIT
move.l    d2,(a0)+    ; set COLOR0
add.l    #02000000,d1    ; next wait, wait 2 lines lower
dbra    d0,initloop
rts

; CLRCOPPER ‘cleans’ the copper effect, turning all
;     the COLOR0 values in the copperlist (or rather the BACKGROUND colour) BLACK ($000)

CLRCOPPER:
lea    barcopper,a0    ; Address of WAIT/COLOR0 in copperlit
move.w    #coplines-1,d0    ; number of lines
MOVE.W    #BACKGROUND,d1    ; RGB background colour
clrloop:
move.w    d1,6(a0)    ; Change this Colour 0
addq.w    #8,a0        ; next Colour0 in copperlist
dbra     d0,clrloop
rts

; DOBARS ‘scrolls’ the coloured bars, one by one,
;     calling the PUTBAR subroutine for each bar

DOBARS:
lea    bar1(PC),a0
move.l    barpos1(PC),d0
bsr.s    putbar
move.l     d0,barpos1
lea bar2(PC),a0
move.l barpos2(PC),d0
bsr.s putbar
move.l d0,barpos2
lea bar3(PC),a0
move.l barpos3(PC),d0
bsr.s putbar
move.l d0,barpos3
lea    bar4(PC),a0
move.l    barpos4(PC),d0
bsr.s    putbar
move.l     d0,barpos4
lea    bar5(PC),a0
move.l    barpos5(PC),d0
bsr.s    putbar
move.l     d0,barpos5
lea	bar6(PC),a0
move.l    barpos6(PC),d0
bsr.s    putbar
move.l     d0,barpos6
lea    bar7(PC),a0
move.l    barpos7(PC),d0
bsr.s    putbar
move.l     d0,barpos7
lea    bar8(PC),a0
move.l    barpos8(PC),d0
bsr.s    putbar
move.l     d0,barpos8
rts

;    Subroutine, input:
;    a0 = BARx address, i.e. the colours of the bar
;    d0 = BARx position

putbar:
lsl.l    #1,d0        ; move barpos 1 bit to the left
lea    poslist(PC),a1    ; table address with positions in a1
add.l    d0,a1        ; add barpos to a1, finding the right
; position value in poslist
cmp.b    #$ff,(a1)    ; are we at the last value of poslist?
bne.s    putbar1        ; if not, do not start again
moveq    #0,d0
lea    poslist,a1    ; if yes, start again
putbar1:
moveq    #0,d2
move.b    (a1),d2        ; value from the POSLIST table
lsl.l    #3,d2        ; shift left by 3 bits (multiply by 8)
lea    barcopper,a2	; address bars in copperlist
add.l    d2,a2        ; add value taken from poslist and
; multiplied by 8, i.e. find in a2
; the address of the correct wait where
; my bar should be
moveq    #13-1,d4    ; Each bar is 14 lines high
putloop:
move.w    (a0)+,6(a2)    ; copy the colour of the bar from BARx to
; dc.w $180,xxx in copperlit
addq.w    #8,a2        ; go to the next colour0 value
dbra    d4,putloop    ; and repeat 14 times to make the whole bar

lsr.l    #1,d0        ; move the barpos to the right by 1 bit
addq.l    #1,d0        ; and add 1 for the next cycle.
rts


; These are the positions of the bars relative to each other. As you can see
; they are placed one after the other, and they follow each other in this order.

barpos1:    dc.l 0
barpos2:    dc.l 4
barpos3:    dc.l 8
barpos4:    dc.l 12
barpos5:    dc.l 16
barpos6:    dc.l 20
barpos7:    dc.l 24
barpos8:    dc.l 28


; These are the 8 bars, i.e. the 13 RGB colours that make up each one
; of them. For example, Bar1 is BLUE, Bar2 is GREY, etc.

; colours: RGB, RGB, RGB, RGB, RGB, RGB, RGB, RGB, RGB, RGB, RGB, RGB, RGB
bar1:
DC.W $002,$004,$006,$008,$00a,$00c,$00f,$00c,$00a,$008,$006,$004,$002
bar2:
DC.W $222,$444,$666,$888,$aaa,$ccc,$fff,$ccc,$aaa,$888,$666,$444,$222
bar3:
DC.W $200,$400,$600,$800,$a00,$c00,$f00,$c00,$a00,$800,$600,$400,$200
bar4:
DC.W $020,$040,$060,$080,$0a0,$0c0,$0f0,$0c0,$0a0,$080,$060,$040,$020
bar5:
DC.W $012,$024,$036,$048,$05a,$06c,$07f,$06c,$05a,$048,$036,$024,$012
bar6:
DC.W $202,$404,$606,$808,$a0a,$c0c,$f0f,$c0c,$a0a,$808,$606,$404,$202
bar7:
DC.W $210,$420,$630,$840,$a50,$c60,$f70,$c80,$a70,$860,$650,$440,$230
bar8:
DC.W $220,$440,$660,$880,$aa0,$cc0,$ff0,$cc0,$aa0,$880,$660,$440,$220



; This is the table (or list) of vertical positions that
; the coloured bars can take. It ends with the value $FF.
; As an indication, this table is made by ‘IS’ with these parameters:
; BEG>0
; END>180
; AMOUNT>150
; AMPLITUDE>85
; YOFFSET>0
; SIZE (B/W/L)>B
; MULTIPLIER>1

poslist:
DC.B    $01,$03,$04,$06,$08,$0A,$0C,$0D,$0F,$11,$13,$14,$16,$18,$19,$1B
DC.B	$1D,$1E,$20,$22,$23,$25,$27,$28,$2A,$2B,$2D,$2E,$30,$31,$33,$34
DC.B	$35,$37,$38,$3A,$3B,$3C,$3D,$3F,$40,$41,$42,$43,$44,$45,$46,$47
DC.B	$48,$49,$4A,$4B,$4C,$4D,$4D,$4E,$4F,$4F,$50,$51,$51,$52,$52,$53
DC.B	$53,$53,$54,$54,$54,$54,$55,$55,$55,$55,$55,$55,$55,$55,$55,$55
DC.B	$54,$54,$54,$54,$53,$53,$53,$52,$52,$51,$51,$50,$4F,$4F,$4E,$4D
DC.B	$4D,$4C,$4B,$4A,$49,$48,$47,$46,$45,$44,$43,$42,$41,$40,$3F,$3D
DC.B	$3C,$3B,$3A,$38,$37,$35,$34,$33,$31,$30,$2E,$2D,$2B,$2A,$28,$27
DC.B	$25,$23,$22,$20,$1E,$1D,$1B,$19,$18,$16,$14,$13,$11,$0F,$0D,$0C
DC.B	$0A,$08,$06,$04,$03,$01

DC.b	$FF	; fine della tabella

even

*************************************************************************
;	Copperlist
*************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
dc.w    $100,$200    ; 0 bitplanes

barcopper:            ; Here the copperlist will be constructed for
dcb.w    coplines*4,0    ; the bar effect - in this case
; 400 words are needed. (coplines=100)

DC.W    $ffdf,$fffe
dc.w    $0107,$FFFE
dc.w    $180,$222    ; Colour0 grey

dc.w    $FFFF,$FFFE    ; End of copperlist

end

This listing shows how you can ‘build’ long but
regular copperlists using routines. Later on, we will see how often the most
spectacular effects hide copperlists that are kilometres long.

Recommended changes: to make everything look more ‘flattened’, make each line wait
instead of every two lines. Just change INITCOPPER:

add.l    #01000000,d1    ; next wait, wait 1 line lower

Now the bars are 13 lines high, not 13*2 lines!
You can also wait every 3 lines, but this will take you too far down.
Try it anyway:

add.l    #$03000000,d1    ; next wait, wait 3 lines lower

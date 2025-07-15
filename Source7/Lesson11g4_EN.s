
; Lesson11g4.s    - Horizontal colour scrolling effect with Copper

SECTION    Supercar,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA only

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

btst    #2,$dff016    ; right button pressed?
beq.s    Mouse2        ; if yes, do not execute Linecop

bsr.s    LineCop        ; ‘supercar’ effect

mouse2:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts

; This routine cyclically inputs the colours from the table to the two lines
; formed by 54 ‘dc.w $1800000’. The effect is possible because each time
; the copper reads an instruction, consisting of 2 words, the time needed
; to read the next one corresponds to 4 pixels per word, i.e.
; 8 pixels for each complete instruction. Doing a calculation, on a screen
; 320 pixels wide, you can change the colour horizontally 40 times, in fact
; 320/8=40. In this case, we start from the vertical overscan position,
; i.e. outside the edges of the monitor (the wait is dc.w $2901,$FFFE), and we arrive
; outside the right edge on the other side. In theory, we would do 54*8=432 pixels
; in width (monitor permitting). Note that we are referring to 8 pixels
; LOWRES, in the case of HIRES the size remains unchanged, and will appear as
; 16 pixels hires, of course.

;     /////////
;     / /_____________________
;     / ___ __// \
;     / ______// eY! fig sta rutin! \
;     _/ / ® \©\\_ _____________________/
;    (_ \____/_/ / /
;     \ _ \ \/
;     \/ (·__)
;     / |
;     /_____ (o)|
;     T T`----'
;     l_! xCz

LineCop:
lea    ColourTable(PC),a0
lea    EndColourTable(PC),a3
lea    EffInCop,a1    ; Horizontal bar address 1
lea    EffInCop2,a2    ; Horizontal bar address 2
moveq    #54-1,d3    ; Number of horizontal colours
addq.l	#2,ColBarraAltOffset    ; Lower bar - scroll colours
; to the left
subq.l    #2,ColBarraBassOffset    ; Upper bar - scroll colours
; to the right
move.l    ColBarraAltOffset(PC),d0    ; Start Offset (1)
add.l    d0,a0        ; find the right colour in the colour table
; according to the current offset
cmp.w    #-1,(a0)    ; are we at the end of the table? (indicated
; with a dc.w -1)
bne.s    CSalta        ; if not, continue
clr.l    ColBarraAltOffset    ; otherwise start again
lea    ColourTable(PC),a0    ; from the first colour
CSalta:
move.l    ColBarLowerOffset(PC),d1    ; Start Offset (2)
sub.l    d1,a3                ; find the right colour
cmp.w    #-1,-(a3)        ; are we at the end of the table
bne.s	SetColours        ; if not, continue
move.l    #EndColourTable-ColourTable,ColBarLowerOffset ; otherwise
; restart from the end of the
; table (since this bar
; scrolls backwards!)
lea    EndColourTable-2(PC),a3
SetColours:
addq.w    #2,a1		; skip dc.w $180
addq.w    #2,a2        ; skip dc.w $180
move.w    (a0)+,(a1)+    ; Enter the colour in coplist (bar1)
move.w    (a3),(a2)+    ; Enter the colour in bar 2

cmp.w    #-1,(a0)    ; are we at the end of the colour table? (bar1)
bne.s    NonFine        ; if not, continue
lea     ColourTable(PC),a0    ; otherwise, start again (bar1)
NonFine:
cmp.w    #-1,-(a3)    ; are we at the beginning of the colour table? (bar2)
bne.s    NonFine2    ; if not, continue
lea     FineTabColori-2(PC),a3    ; otherwise, start again from the end (bar2)
NonFine2:
dbra    d3,MettiColori
rts

*** *** *** *** *** *** *** *** *** ***


ColBarraAltOffset:
dc.l    0

ColBarraBassOffset:
dc.l    0



; NOTE: to indicate the end (and the beginning) of the table, it is checked
;    if dc.w -1 has been reached.

dc.w     -1    ; end of table
TabellaColori:
DC.W	$F0F,$F0E,$F0D,$F0C,$F0B,$F0A,$F09,$F08,$F07,$F06
DC.W	$F05,$F04,$F03,$F02,$F01,$F00,$F10,$F20,$F30,$F40
DC.W	$F50,$F60,$F70,$F80,$F90,$FA0,$FB0,$FC0,$FD0,$FE0
DC.W    $FF0,$EF0,$DF0,$CF0,$BF0,$AF0,$9F0,$8F0,$7F0,$6F0
DC.W	$5F0,$4F0,$3F0,$2F0,$1F0,$0F0,$0F1,$0F2,$0F3,$0F4
DC.W    $0F5,$0F6,$0F7,$0F8,$0F9,$0FA,$0FB,$0FC,$0FD,$0FE
DC.W    $0FF,$0EF,$0DF,$0CF,$0BF,$0AF,$09F,$08F,$07F,$06F
DC.W	$05F,$04F,$03F,$02F,$01F,$00F,$10F,$20F,$30F,$40F
DC.W    $50F,$60F,$70F,$80F,$90F,$A0F,$B0F,$C0F,$D0F,$E0F
EndColourTable:
dc.w    -1    ; end table


section CList,code_c

CopperList:
dc.w    $100,$200    ; BPLCON0 - 0 bitplanes
dc.w    $180,$000    ; Colour0 black

dc.w    $2901,$FFFE    ; Wait line $29
EffInCop2:
dcb.l    54,$1800000    ; 54 Colour0 in succession, which in increments of 8
; pixels forward each time fill the
; line entirely

dc.w    $2a01,$FFFE    ; Wait line $2a
dc.w    $180,$000    ; Colour0 black


dc.w    $FFDF,$FFFE    ; Special wait to go to PAL zone

dc.w    $2A01,$FFFE    ; Wait for line $2a+$ff
EffInCop:
dcb.l    54,$1800000    ; 54 Colour0 in succession, which in increments of 8
; pixels forward each time fill the
; line entirely

dc.w    $2B07,$FFFE    ; Wait line $ff+$2b
dc.w    $180,$000    ; Colour0 black

dc.w    $FFFF,$FFFE    ; End copperlist

end

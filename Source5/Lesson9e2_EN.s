
; Lesson 9e2.s        SHIFTING WITH a 2-word object (one reset)

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


START:
;    Point to the ‘empty’ PIC

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

moveq    #0,d4            ; horizontal coordinate to 0

Loop:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10800,d2    ; line to wait for = $108
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
Beq.S    Waity2

;
;
;
;
;
;
;
;
;
;     / \ l_l_|/ /
;     / \ \ / /
;     __/ _/\ \/\__/ /
;     / ¬`----'¯¯\______/
;     / __ __ \
;    / / T \

move.w    d4,d5    ; current horizontal coordinate in d5

and.w    #000f,d5    ; Select the first 4 bits because they must be
; inserted into the channel A shifter
lsl.w    #8,d5        ; the 4 bits are moved to the high nibble
lsl.w    #4,d5        ; of the word... (8+4 = 12-bit shift!) 
or.w    #$09f0,d5    ; ...just right to fit into the BLTCON0 register
; Here we put $f0 in the minterms for copying from
; source A to destination D and
; obviously enable channels A+D with $0900 (bit 8
; for D and 11 for A). That is, $09f0 + shift.

addq.w    #1,d4        ; Add 1 to the horizontal coordinate to
; move 1 pixel to the right next time

move.w    #$ffff,$44(a5)        ; BLTAFWM will be explained later
move.w    #$ffff,$46(a5)        ; BLTALWM will be explained later
move.w    d5,$40(a5)        ; BLTCON0 (use A+D) - in the register
; we have put the shift! (bits 12,13
; 14 and 15, i.e. high nibble!)
move.w    #$0000,$42(a5)        ; BLTCON1 will be explained later
move.w    #0,$64(a5)        ; BLTAMOD (=0)
move.w    #36,$66(a5)        ; BLTDMOD (40-4=36)
move.l    #figure,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    #bitplane,$54(a5)    ; BLTDPT (screen lines)
move.w    #(64*6)+2,$58(a5)    ; BLTSIZE (start the blitter!)
; we bleed 2 words, the second of
; which is null to allow
; the shift
btst    #6,$bfe001        ; mouse pressed?
bne.s    loop

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

rts

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$1200

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; here's the fish... this time we have a second word reset for each line
; dimensions: 32*6

Figure:
dc.w    %1000001111100000,%000000000000000
dc.w	%1100111111111000,%000000000000000
dc.w	%1111111111101100,%000000000000000
dc.w	%1111111111111110,%000000000000000
dc.w	%1100111111111000,%000000000000000
dc.w	%1000001111100000,%000000000000000

;****************************************************************************

SECTION	PLANEVUOTO,BSS_C	

BITPLANE:
ds.b	40*256		; bitplane azzerato lowres

end

;****************************************************************************

In this example, we move a figure to the right one pixel at a time
with the shift, using a word reset to zero to the right of each line to
improve the effect compared to Lesson9e1.s
Since we never increment the destination address, the figure moves
only using the blitter's shifter.
In this way, it is possible to move a maximum of 15 pixels, since 15 is the
maximum shift value allowed.
After reaching 15, the shift value (which is obtained by taking the 4 least significant bits
of the figure's position) returns to 0 and therefore
the figure will return to its starting position to start moving again.
To do a ‘serious’ scroll, for every 15 pixels of scrolling obtained with the
shift, you would need to trigger the image by 16 pixels by adding 2 to the
destination, and restarting with the shift at zero, and so on, in a similar way to
what we saw for scrolling with bplcon1 ($dff102) and bplpointers in copperlist.


; Lesson 9e3.s    Complete horizontal shift with shift + change of
;        destination position (2-byte increments = 16 pixels)

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

moveq    #0,d1            ; Horizontal coordinate at 0
move.w    #(320-32)-1,d7        ; Move 320 pixels MINUS the actual width
; of the BOB, so that
; its first pixel on the left
; stops when the one on the right reaches
; the end of the screen.
Loop:
cmp.b    #$ff,$6(a5)    ; VHPOSR - wait for line $ff
bne.s    loop
Wait:
cmp.b    #$ff,$6(a5)    ; still line $ff?
beq.s    Wait

;     \\ ,\\ /, ,,//
;     \\\\\X///////
;     \¬¯___ __/
;     _;=( ©)(®_)
;     (, _ ¯T¯ \¬\
;     T /\ “ ,)/
;     |(”/\_____/__
;     l_¯ ¬\
;     _T¯¯¯T¯¯¯¯¯¯¯
;     /¯¯¬l___¦¯¯¬\
;	/___, ° ,___\
;    ¯/¯/¯ °__T\¬\¯
;    ( \___/ '\ \ \
;     \_________) \ \
;     l_____ \ \ \
;     / ___¬T¯ \ \
;     / _/ \ l_ ) \
;     \ ¬\ \ \ ())))
;     __\__\ \ ) ¯¯¯
;     (______) \/\ xCz
;     / /
;     (_/

lea    bitplane,a0    ; destination in a0
move.w    d1,d0
and.w    #000f,d0    ; Select the first 4 bits because they must be
; inserted into the channel A shifter
lsl.w    #8,d0        ; The 4 bits are moved to the high nibble
lsl.w    #4,d0        ; of the word... (8+4= 12-bit shift)
or.w    #$09f0,d0    ; ...just right to fit into the BLTCON0 register
; Here we put $f0 in the minterms for copying from
; source A to destination D and enable
; obviously channels A+D with $0900 (bit 8
; for D and 11 for A). That is, $09f0 + shift.
move.w    d1,d2
lsr.w    #3,d2        ; (equivalent to a division by 8)
; rounds to multiples of 8 for the pointer
; to the screen, i.e. to odd addresses
; (also to bytes, therefore)
; e.g.: a 16 as a coordinate becomes
; byte 2
and.w    #$fffe,d2    ; exclude bit 0
add.w    d2,a0        ; Add to the bitplane address, finding
; the correct destination address
addq.w    #1,d1        ; Add 1 to the horizontal coordinate

btst    #6,2(a5) ; dmaconr
WBlit1:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit1

; now, as explained in the theory, we take the opportunity to make a
; modification: we write the values in ADJACENT registers with a single “move.l”

move.l    #$01000000,$40(a5)    ; BLTCON0 + BLTCON1
move.w    #$0000,$66(a5)
move.l    #bitplane,$54(a5)
move.w    #(64*256)+20,$58(a5)    ; try removing this line
; and the screen will not be cleared,
; so the fish will leave a ‘trail’

btst    #6,2(a5) ; dmaconr
WBlit2:
btst    #6,2(a5) ; dmaconr - wait for the blitter to finish
bne.s    wblit2

move.l    #$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later
move.w    d0,$40(a5)        ; BLTCON0 (use A+D)
move.w    #0000,$42(a5)        ; BLTCON1 (no special mode)
move.l    #00000024,$64(a5)    ; BLTAMOD (=0) + BLTDMOD (=40-4=36=$24)
move.l    #figure,$50(a5)        ; BLTAPT (fixed to the source figure)
move.l    a0,$54(a5)        ; BLTDPT (screen lines)
move.w    #(64*6)+2,$58(a5)    ; BLTSIZE (start the blitter!)
; blit 2 words, the second of
; which is null to allow
; the shift

btst    #6,$bfe001        ; mouse pressed?
beq.s    quit

dbra    d7,loop

Quit:
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

dc.w    $100,$1200    ; BplCon0 - 1 bitplane LowRes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$eee    ; colour1
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; Il pesciolino:

Figura:
dc.w	%1000001111100000,0
dc.w	%1100111111111000,0
dc.w	%1111111111101100,0
dc.w	%1111111111111110,0
dc.w	%1100111111111000,0
dc.w	%1000001111100000,0

;****************************************************************************

SECTION    PLANEVUOTO,BSS_C

BITPLANE:
ds.b    40*256        ; bitplane reset lowres

end

;****************************************************************************

In this example, we move our figure by an arbitrary number of pixels.
The horizontal coordinate of the figure is stored in D1. This coordinate
is divided by 8 in order to calculate the memory address of the word
to which it belongs. The 4 least significant bits of the coordinate, on the other hand,
are the shift value, as explained in the lesson.


; Lesson 10i2.s    1-pixel sine scroller
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup1.s’    ; Save Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:

MOVE.L    #BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers

move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0

lea    $dff000,a5		; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w	#0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

lea    text(pc),a0        ; point to the scrolltext

mouse:
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

bsr.s    printchar    ; routine that prints the new characters
bsr.s    Scorri        ; execute the scrolling routine

bsr.w    ClearScreen    ; clear the screen
bsr.w    Sine        ; execute the sine scroll

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse2:
rts

;****************************************************************************
; This routine prints a character. The character is printed in an
; invisible part of the screen.
; A0 points to the text to be printed.
;****************************************************************************

PRINTCHAR:
subq.w    #1,counter    ; decrease the counter by 1
bne.s    NoPrint        ; if it is not 0, do not print,
move.w    #16,counter    ; otherwise, reset the counter

MOVEQ    #0,D2		; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
bne.s    noreset        ; If it is not 0, print it,
lea    text(pc),a0    ; otherwise restart the text from the beginning
MOVE.B    (A0)+,D2    ; First character in d2
noreset
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), in $01...
ADD.L    D2,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 2,
; because each character is 16 pixels wide
MOVE.L	D2,A2

ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

btst    #6,$02(a5)    ; dmaconr - wait for the blitter to finish
waitblit:
btst    #6,$02(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)    ; BLTCON0: copy from A to D
move.l    #$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later

move.l    a2,$50(a5)            ; BLTAPT: font address
move.l    #buffer+40,$54(a5)        ; BLTDPT: bitplane address
; fixed, outside the
; visible part of the screen.
move    #120-2,$64(a5)            ; BLTAMOD: font module
move	#42-2,$66(a5)            ; BLTDMOD: bit plane module
move    #(20<<6)+1,$58(a5)         ; BLTSIZE: font 16*20
NoPrint:
rts

counter
dc.w    16

;****************************************************************************
; This routine scrolls the text to the left
;****************************************************************************

Scroll:

; The source and destination addresses are the same.
; We shift to the left, then use the descending mode.

move.l    #buffer+((21*20)-1)*2,d0    ; source and
; destination
ScorriLoop:
btst    #6,2(a5)        ; wait for the blitter to finish
waitblit2:
btst    #6,2(a5)
bne.s    waitblit2

move.l    #$19f00002,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
; with a shift of one pixel

move.l    #$ffff7fff,$44(a5)    ; BLTAFWM and BLTALWM
; BLTAFWM = $ffff - pass everything
; BLTALWM = $7fff = %0111111111111111
; clear the leftmost bit

; load the pointers

move.l    d0,$50(a5)            ; bltapt - source
move.l    d0,$54(a5)            ; bltdpt - destination

; let's scroll an image across the entire screen, then
; the module is reset.

move.l    #$00000000,$64(a5)        ; bltamod and bltdmod 
move.w	#(20*64)+21,$58(a5)        ; bltsize
; height 20 lines, width 21
rts                    ; words (entire screen)


;****************************************************************************
; This routine creates the sine-scroll effect. Be careful with BLTALWM, because
; it is the register where we select the vertical ‘slice’ or ‘strip’
; to operate on each time. This is where the differences with the 2-pixel sine lie!
;****************************************************************************

;     ,-~~-.___.
;     / | “ \
;    ( ) 0
;     \_/-, ,----”
;     ==== //
;     / \-'~; /~~~(O)
;     / __/~| / |
;    =( _____| (_________| W<

Sine:
lea    buffer,a2        ; pointer to the buffer containing
; the scrolltext
lea    bitplane,a1        ; pointer to the destination

move.l    SinusPtr(pc),a3        ; address of the first sine value (*42)
subq.w    #2,a3            ; modify the first value
cmp.l	#Sinustab,a3        ; if we are at the beginning of the table
bhs.s    nostartptr        ; start again from the end
lea    EndSinustab(pc),a3
nostartptr:
move.l    a3,SinusPtr        ; store first value used

move.w    #8000,d5        ; initial mask value
moveq    #20-1,d6        ; repeat for all words in the screen
FaiUnaWord:
moveq    #16-1,d7        ; 1-pixel routine. For each word
; there are 16 ‘slices’ of 1 pixel

DoOneColumn:
move.w    (a3)+,d0        ; reads a value from the table
cmp.l    #EndSinustab,a3        ; if we are at the end of the table
blo.s    nostartsine        ; start again from the beginning
lea    sinustab(pc),a3
nostartsine:
move.l    a1,a4            ; copy bitplane address
add.w    d0,a4            ; add Y coordinate

btst    #6,2(a5)    ; dmaconr - wait for the blitter to finish
waitblit_sine:
btst    #6,2(a5)
bne.s    waitblit_sine

move.w    #$ffff,$44(a5)        ; BLTAFWM
move.w    d5,$46(a5)        ; BLTALWM - contains the mask that
; selects the ‘slices’ of scrolltext

move.l    #$0bfa0000,$40(a5)    ; BLTCON0/BLTCON1 - activates A, C, D
; D=A OR C

move.w    #$0028,$60(a5)        ; BLTCMOD=42-2=$28
move.l    #$00280028,$64(a5)	; BLTAMOD=42-2=$28
; BLTDMOD=42-2=$28

move.l    a2,$50(a5)        ; BLTAPT (to buffer)
move.l    a4,$48(a5)        ; BLTCPT (to screen)
move.l    a4,$54(a5)        ; BLTDPT (to screen)
move.w    #(64*20)+1,$58(a5)    ; BLTSIZE (blits a rectangle
; 20 lines high and 1 word wide)

ror.w    #1,d5            ; move to the next ‘slice’
; go right and after the last ‘slice’
; of a word, start again from the first
; of the following word.
; to scroll 1 pixel at a time
; each ‘slice’ is 1 pixel wide

dbra    d7,FaiUnaColonna

addq.w    #2,a2            ; point to the next word
addq.w    #2,a1            ; point to the next word
dbra    d6,FaiUnaWord
rts

; This is the text. End with 0. The font used only has
; capital letters, be careful!

text:
dc.b    ‘ HERE'S HOW TO SCROLL... THE FONT IS 16*20 PIXELS!...’
dc.b    " THE SCROLL IS SMOOTH...",0
even

;****************************************************************************
; This routine clears the screen using the blitter.
; Only the part of the screen on which the text scrolls is cleared:
; from line 130 to line 193
;****************************************************************************

ClearScreen:
btst    #6,2(a5)
WBlit3:
btst    #6,2(a5)         ; wait for the blitter to finish
bne.s    wblit3

move.l    #$01000000,$40(a5)    ; BLTCON0 and BLTCON1: Clear
move    #0000,$66(a5)        ; BLTDMOD=0
move.l    #bitplane+42*130,$54(a5)    ; BLTDPT
move.w    #(64*63)+20,$58(a5)	; BLTSIZE (start blitter!)
; clear from line 130
; to line 193
rts

;***************************************************************************

; this pointer contains the address of the first value to be read from the
; table

SinusPtr:    dc.l    Sinustab

; This is the table containing the values of the vertical positions
; of the scrolltext. The positions are already multiplied by 42, so
; they can be added directly to the BITPLANE address

Sinustab:
DC.W    $189C,$18C6,$18F0,$191A,$1944,$196E,$1998,$19C2,$19C2,$19EC
DC.W	$1A16,$1A40,$1A6A,$1A6A,$1A94,$1ABE,$1ABE,$1AE8,$1B12,$1B12
DC.W	$1B3C, $1B3C, $1B66,$1B66,$1B90,$1B90,$1BBA,$1BBA,$1BBA,$1BBA
DC.W	$1BE4,$1BE4,$1BE4,$1BE4,$1BE4,$1BE4,$1BE4,$1BE4,$1BE4,$1BE4
DC.W	$1BBA,$1BBA,$1BBA,$1BBA,$1B90,$1B90,$1B66,$1B66,$1B3C,$1B3C
DC.W	$1B12,$1B12,$1AE8,$1ABE,$1ABE,$1A94,$1A6A,$1A6A,$1A40,$1A16
DC.W	$19EC,$19C2,$19C2,$1998,$196E,$1944,$191A,$18F0,$18C6,$189C
DC.W	$189C,$1872,$1848,$181E,$17F4,$17CA,$17A0,$1776,$1776,$174C
DC.W	$1722,$16F8,$16CE,$16CE,$16A4,$167A,$167A,$1650,$1626,$1626
DC.W	$15FC,$15FC,$15D2,$15D2,$15A8,$15A8,$157E,$157E,$157E,$157E
DC.W	$1554,$1554,$1554,$1554,$1554,$1554,$1554,$1554,$1554,$1554
DC.W	$157E,$157E,$157E,$157E,$15A8,$15A8,$15D2,$15D2,$15FC,$15FC
DC.W	$1626,$1626,$1650,$167A,$167A,$16A4,$16CE,$16CE,$16F8,$1722
DC.W	$174C,$1776,$1776,$17A0,$17CA,$17F4,$181E,$1848,$1872,$189C
EndSinustab:

;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

dc.w    $108,2        ; The bitplane is 42 bytes wide, but only 40
; bytes are visible, so the module
; value is 42-40=2
;    dc.w    $10a,2        ; We use only one bitplane, so BPLMOD2
; is not necessary

dc.w    $100,$1200    ; bplcon0 - 1 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$f50    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; Qui e` memorizzato il FONT di caratteri 16x20

FONT:
incbin	‘font16x20.raw’

;****************************************************************************

SECTION    PLANEVUOTO,BSS_C

BITPLANE:
ds.b    42*256        ; bitplane reset lowres

Buffer:
ds.b    42*20        ; invisible buffer where the text is scrolled
; end
end

;****************************************************************************

In this example, we see a 1-pixel sine scroll. If you look closely
at the edges of the letters, you will notice that the sine wave is much less jagged.
The ‘Sine’ routine is very similar to the one in lesson10i1.s. The differences
are that we now have “slices” that are one pixel wide, which
means that there are 16 ‘slices’ in a word instead of 8, and that, of course,
the mask must rotate 1 pixel at a time instead of 2.
Also note that we are using a different sine table. In fact, if we had
used the same one, the sine wave would have been narrower.
To make the scroller a little more varied, we read the values in the table
each time starting from a different value. To do this, we use a pointer to
the first value to be read, which is modified each time it is read.

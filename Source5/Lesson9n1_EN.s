
; Lesson 9n1.s    Ladies and gentlemen, SCROLLTEXT!!!!!
;        Left key to exit.

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA


START:

MOVE.L	#BITPLANE,d0    ; where to point
LEA    BPLPOINTERS,A1    ; COP pointers

move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0

lea    $dff000,a5        ; CUSTOM REGISTER in a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
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

bsr.s    printchar        ; routine that prints the new characters
bsr.s    Scorri            ; execute the scrolling routine

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
move.w    #16,counter    ; otherwise yes; reinitialise the counter

MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
bne.s    noreset        ; If it is not 0, print it,
lea    text(pc),a0    ; otherwise, restart the text from the beginning
MOVE.B    (A0)+,D2    ; First character in d2
noreset
SUB.B	#$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER, IN
; ORDER TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), to $01...
ADD.L    D2,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 2,
; because each character is 16 pixels wide
MOVE.L    D2,A2

ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

btst    #6,$02(a5)    ; wait for the blitter to finish
waitblit:
btst    #6,$02(a5)
bne.s    waitblit

move.l    #$09f00000,$40(a5)	; BLTCON0: copy from A to D
move.l    #$ffffffff,$44(a5)    ; BLTAFWM and BLTALWM will be explained later

move.l    a2,$50(a5)            ; BLTAPT: font address
move.l    #bitplane+50*42+40,$54(a5)	; BLTDPT: bitplane address
; fixed, outside the
; visible part of the screen.
move    #120-2,$64(a5)            ; BLTAMOD: font module
move    #42-2,$66(a5)			; BLTDMOD: bit planes module
move    #(20<<6)+1,$58(a5)         ; BLTSIZE: font 16*20
NoPrint:
rts

counter
dc.w    16

;****************************************************************************
; Questa routine fa scorrere il testo verso sinistra
;****************************************************************************

;
;
;
; и и. д:.:.:.:.:.:.д . и . . и .
; ░ и и| |.и . . и и
; . ии. | __ | и
; и и. | / ` | .ии. ░
; и | ,___ ___ | .и и
;	░ | ____ / \| и .
;     .иии. l/ o\/░ /l
;     ░ (»\____/\___/ ») ░
;     T (____) T
;     l j xCz
;     \___ O ____/
;     `---'

Scroll:

; The source and destination addresses are the same.
; Shift left, then use the descending mode.

move.l    #bitplane+((21*(50+20))-1)*2,d0        ; source and
; destination
ScrollLoop:
btst    #6,2(a5)		; wait for the blitter to finish
waitblit2:
btst    #6,2(a5)
bne.s    waitblit2

move.l    #$19f00002,$40(a5)    ; BLTCON0 and BLTCON1 - copy from A to D
; with a pixel shift

move.l    #$ffff7fff,$44(a5)    ; BLTAFWM and BLTALWM
; BLTAFWM = $ffff - pass everything
; BLTALWM = $7fff = %0111111111111111
; clear the leftmost bit

; load the pointers

move.l    d0,$50(a5)            ; bltapt - source
move.l    d0,$54(a5)            ; bltdpt - destination

; scroll an image across the entire screen, then
; the module is reset.

move.l    #$00000000,$64(a5)        ; bltamod and bltdmod
move.w	#(20*64)+21,$58(a5)        ; bltsize
; height 20 lines, width 21
rts                    ; words (entire screen)

; This is the text. It ends with 0. The font used only has
; capital letters, be careful!

text:
dc.b	‘HERE IS FINALLY THE SCROLLTEXT THAT EVERYONE WAS WAITING FOR’
dc.b    ‘ THE FONT IS 16*20 PIXELS!...’
dc.b    ‘ THE SCROLL RUNS SMOOTHLY...’,0


;****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w	$92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2

dc.w    $108,2        ; The bitplane is 42 bytes wide, but only 40
; bytes are visible, so the module
; is worth 42-40=2
;    dc.w    $10a,2        ; We use only one bitplane, so BPLMOD2
; is not necessary

dc.w    $100,$1200    ; bplcon0 - 1 lowres bitplanes

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0

; these copperlist instructions change colour 1 every 2 lines

dc.w    $5e01,$fffe    ; first scrolltext line
dc.w    $0182,$f50    ; colour1
dc.w    $6001,$fffe
dc.w    $0182,$d90
dc.w    $6201,$fffe
dc.w	$0182,$dd0
dc.w	$6401,$fffe
dc.w	$0182,$5d2
dc.w	$6601,$fffe
dc.w	$0182,$2f4
dc.w	$6801,$fffe
dc.w	$0182,$0d7
dc.w	$6a01,$fffe
dc.w	$0182,$0dd
dc.w	$6c01,$fffe
dc.w	$0182,$07d
dc.w	$6e01,$fffe
dc.w	$0182,$22f
dc.w    $7001,$fffe
dc.w    $0182,$40d
dc.w    $7201,$fffe
dc.w    $0182,$80d

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

; Qui e` memorizzato il FONT di caratteri 16x20

FONT:
incbin	‘assembler2:sorgenti6/font16x20.raw’

;****************************************************************************

SECTION	PLANEVUOTO,BSS_C

BITPLANE:
ds.b	42*256		; bitplane azzerato lowres

end

;****************************************************************************

In this example, we present one of the most classic demo effects:
scroll text. This is text that scrolls across the screen from right
to left, and usually contains greetings sent
by the demo authors to other demo coders. How do you create
scroll text? You might think of printing all the text on a bitplane
larger than the visible screen and then scrolling the bitplane. This
technique has the disadvantage of taking up a lot of memory, because it requires
a bitplane that contains all the text.
We use another technique based on the blitter, for which you only need
a bitplane just 16 pixels wide (1 word) wider than the visible area.
We therefore have a column of one word invisible to the right of the screen.
Let's suppose we print a character in the invisible part of the bitplane and
at the same time scroll the bitplane to the left using the
blitter. As you can imagine, the character moves one pixel
at a time to the left.
Note that the pointers to the bitplanes always remain fixed.
When the character is completely visible, which happens after 16
shifts of 1 pixel, since the character is 16 pixels wide, we can print
the next character in the invisible part of the screen.
Characters that reach the left edge are deleted by the blitter mask
.
In practice, the effect is achieved using two routines.
The first, ‘Printchar’, prints the characters on the screen.
Printing must only take place when the previously printed character has
become completely visible, so as to avoid overlapping the two
characters.
Since each character is 16 pixels wide and the text scrolls one pixel at a
time, printing must essentially take place every 16 times the routine is
called.
For this purpose, a counter is used which is decremented each time the routine is called.
When it reaches 0, the character is printed and the counter
is reset to 16. The actual printing is a simple copy using the
blitter (used in ascending mode) in the manner we are familiar with.
The ‘Scorri’ routine is responsible for scrolling the text using the
to the left (i.e. in descending mode) as we saw
in the example in lesson9m2.s. Since the characters are 20 lines high,
the entire text occupies a ‘strip’ of the screen 20 lines high.
It is necessary to scroll this entire ‘strip’, i.e. a rectangle 20 lines high
rows and as wide as the entire bitplane (including, of course, the
INVISIBLE part, so that the characters scroll in the visible part).
The mask of the last word deletes the characters that reach
the left edge.
We have used a screen consisting of 1 bitplane, and the colours are obtained
using the copper (otherwise, how clever would we be?).

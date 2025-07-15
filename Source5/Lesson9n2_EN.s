
; Lesson9n2.s    More scroll text! The one in the intro of disc 1!
;        Left key to exit.

Section    BigScroll,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup1.s’    ; Save Copperlist Etc.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET	EQU    %1000001111000000    ; blitter, copper, bitplane DMA

START:

;     POINT OUR BITPLANE

MOVE.L    #BITPLANE+100*44,d0    ; bitplane
LEA    BPLPOINTERS,A1
MOVEQ	#3-1,D1            ; number of bitplanes
POINTB:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
addi.l    #44*256,d0        ; + LENGTH OF A PLANE !!!!!
addq.w    #8,a1
dbra    d1,POINTB

bsr.s    makecolors        ; Apply effect in copperlist

lea    $dff000,a6
MOVE.W    #DMASET,$96(a6)		; DMACON - enable dma
move.l    #COPPERLIST,$80(a6)    ; Point our COP
move.w    d0,$88(a6)        ; Start the COP
move.w    #0,$1fc(a6)        ; Disable AGA
move.w    #$c00,$106(a6)        ; Disable AGA
move.w    #$11,$10c(a6)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A6),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w    MainScroll    ; scroll management routine

BTST.B    #6,$bfe001    ; mouse button pressed?
BNE.s    mouse
rts

;*****************************************************************************
; this routine creates a colour gradient in the copperlist
; basically, there is some empty space in the copperlist that is
; filled by this routine, which inserts the correct copper instructions.
; We will see many of these routines in Lesson11.txt
;*****************************************************************************

MAKECOLORS:
lea    scol,a0        ; Address where to modify copperlist
lea    coltab,a1    ; colour table 1
lea    coltab2,a2    ; colour table 2
move.l    #$a807,d1    ; starting line = $A0
moveq    #63,d0        ; number of lines
col1:
move.w    d1,(a0)+    ; create WAIT instruction
move.w    #$fffe,(a0)+

move.w    #$0182,(a0)+    ; instruction that modifies COLOR01
move.w    (a1)+,(a0)+
move.w    #$018E,(a0)+    ; instruction that modifies COLOR07
move.w    (a2)+,(a0)+

add.w    #$100,d1    ; next line
dbra    d0,col1
rts

coltab:
dc.w    $00,$11,$22,$33,$44,$55,$66,$77,$88,$99
dc.w    $aa,$bb,$cc,$dd,$ee,$ff,$ff,$ee,$dd,$cc
dc.w	$bb,$aa,$99,$88,$77,$66,$55,$44,$33,$22
dc.w	$11,$00
dc.w	$000,$110,$220,$330,$440,$550,$660,$770,$880,$990
dc.w	$aa0,$bb0,$cc0,$dd0,$ee0,$ff0,$ff0,$ee0,$dd0,$cc0
dc.w	$bb0,$aa0,$990,$880,$770,$660,$550,$440,$330,$220
dc.w	$110,$000
dc.w	$000,$101,$202,$303,$404,$505,$606,$707,$808,$909
dc.w	$a0a,$b0b,$c0c,$d0d,$e0e,$f0f,$f0f,$e0e,$d0d,$c0c
dc.w	$b0b,$a0a,$909,$808,$707,$606,$505,$404,$303,$202
dc.w	$101,$000,0,0

coltab2:
dc.w	$000,$101,$202,$303,$404,$505,$606,$707,$808,$909
dc.w	$a0a,$b0b,$c0c,$d0d,$e0e,$f0f,$f0f,$e0e,$d0d,$c0c
dc.w	$b0b,$a0a,$909,$808,$707,$606,$505,$404,$303,$202
dc.w	$101,$000,0,0
dc.w	$000,$011,$022,$033,$044,$055,$066,$077,$088,$099
dc.w	$0aa,$0bb,$0cc,$0dd,$0ee,$0ff,$0ff,$0ee,$0dd,$0cc
dc.w	$0bb,$0aa,$099,$088,$077,$066,$055,$044,$033,$022
dc.w	$011,$000
dc.w	$000,$110,$220,$330,$440,$550,$660,$770,$880,$990
dc.w	$aa0,$bb0,$cc0,$dd0,$ee0,$ff0,$ff0,$ee0,$dd0,$cc0
dc.w	$bb0,$aa0,$990,$880,$770,$660,$550,$440,$330,$220
dc.w	$110,$000

;*****************************************************************************
;         MAIN SCROLLTEXT ROUTINE
;*****************************************************************************

MainScroll:
lea    $dff000,a6
btst.b    #10,$16(a6)        ; right key pressed?
beq.s    SaltaScroll        ; if yes, move the text vertically
; without scrolling it

move.l noscroll(pc),d0        ; scroll counter
subq.l #1,d0            ; decrement the counter
bmi.s do_scrolling        ; if negative, scroll
move.l d0,noscroll        ; otherwise, just move the text
bra.s	SaltaScroll

do_scrolling:                ; scroll
clr.l    noscroll        ; reset counter

bsr.w    PrintChar        ; print new character
bsr.s    DoScroll        ; scroll text

SaltaScroll:
bsr.s    Drawscroll        ; call the routine that draws
; the text on the screen

lea    sinustab(PC),a0        ; these instructions rotate the values
lea    4(a0),a1        ; of the position table
move.l	(a0),d0            ; vertical scrolltext positions
copysinustab:
move.l    (a1)+,(a0)+
cmpi.l    #$ffff,(a1)        ; End of table flag? If not yet,
bne.s    copysinustab        ; continue moving...
move.l    d0,(a0)			; At the end, put the first value in
rts                ; bottom!

;*****************************************************************************
; This routine performs the actual scrolling. Note that to
; set the scroll speed, the label ‘speedlogic’ is used, which is
; nothing more than the value to be entered in BLTCON0, which, depending on the various
; speeds, has a different shift value.
;*****************************************************************************

;     _____________
;     / --- ____ ¬\
;     _/ ¬____,¬_____-'\_
;    (_ ¬(°T..(°)_¬ _)
;     T`-- ¯____¯ __,¬ T
;     l_ ,-¬/----\-` !
;     \__ /______\-¯¯¬/
;     | `------“ T¯ xCz
;     `-----------”

DoScroll:
lea    BITPLANE+2,a0    ; Source (16 pixels ahead)
lea    BITPLANE,a1    ; Dest (start... then <- by 16 pixels!)
moveq    #3-1,d7        ; Number of blits = 3 for 3 planes
BlittaLoop1:
btst    #6,2(a6)    ; dmaconr - waitblit
bltx:
btst    #6,2(a6)    ; dmaconr - waitblit
bne.s    bltx

moveq    #0,d1
move.w    d1,$42(a6)        ; BLTCON1
move.l    d1,$64(a6)        ; BLTAMOD, BLTDMOD
moveq	#-1,d1            ; $FFFFFFFF
move.l    d1,$44(a6)        ; BLTAFWM, BLTALWM
move.w    speedlogic(PC),$40(a6)    ; BLTCON0 (sets scroll speed
; via shift)

btst    #6,2(a6)	; dmaconr - waitblit
blt23:
btst    #6,2(a6)    ; dmaconr - waitblit
bne.s    blt23

move.l    a0,$50(a6)        ; BLTAPT
move.l    a1,$54(a6)        ; BLTDPT
move.w    #(32*64)+22,$58(a6)    ; BLTSIZE

add.w    #32*44,a0    ; next source plane
add.w    #32*44,a1    ; next destination plane

dbra    d7,BlittaLoop1
rts

;*****************************************************************************
; this routine draws the scroll text on the screen at a vertical position
; that varies according to the values of a sine wave (i.e. a nice SIN TAB!).
; Note that instead of copying it with blitted lenses, we could have done it in a
; more ‘economical’ and ‘Amiga-friendly’ way by changing only the pointers to the bitplanes,
; doing the same job with a few moves. However, this is a source
; dedicated to blitting, so let's use bitmap!
;*****************************************************************************

Drawscroll:
lea    BITPLANE,a0        ; source pointer
lea    sinustab(pc),a5        ; sine table
move.l    (a5),d4            ; read Y coordinate
; (the first in the table)
lea    BITPLANE+(112*44),a5    ; destination address
add.l    d4,a5            ; add Y coordinate

btst    #6,2(a6)		; wait for the blitter to stop
blt1e:                    ; before modifying the registers
btst    #6,2(a6)
bne.s    blt1e

moveq	#-1,d1
move.l    d1,$44(a6)        ; BLATLWM, BLTAFWM
moveq    #0,d1
move.l    d1,$64(a6)        ; BLTAMOD/BLTDMOD
move.l    #$09f00000,$40(a6)	; BLTCON0 - normal copy

moveq    #3-1,d7            ; Number of planes
copialoopa:
btst    #6,2(a6)        ; wait for the blitter to stop
blt1f:
btst    #6,2(a6)
bne.s    blt1f

move.l    a0,$50(a6)        ; BLTAPT
move.l    a5,$54(a6)        ; BLTDPT
move.w    #32*64+22,$58(a6)    ; BLTSIZE - copyscroll

add.w    #32*44,a0        ; next source plane
add.w    #256*44,a5		; next destination plane

dbra    d7,copialoopa
rts

; This table contains the offsets for the Y coordinates to move the scroll up and
; down.

sinustab:
dc.l    0,44,88,132,176,220,264,308,352,396
dc.l	440,484,528,572,616,660,704,748,792
dc.l	836,880,924,968,1012,1056,1100,1144,1188,1232
dc.l	1276,1276,1232
dc.l	1188,1144,1100,1056,1012,968,924,880,836,792,748,704
dc.l	660,616,572,528,484,440,396,352,308
dc.l	264,220,176,132,88,44,0
sinusend:
dc.l	0
dc.l	$ffff	; flag di fine tabella


;*****************************************************************************
; This routine prints the new characters. Note that in the text there are
; also some FLAGS, in this case numbers from 1 to 5, which change the
; scroll speed. This changes the shift value to be put in
; bltcon0, as well as the number of characters to be printed each frame (it is clear
; that at supersonic speed more characters need to be printed per frame!).
Another detail to note is that the system used to build the
font is different from those seen so far. In fact, the font
 nothing more than a 320*200 screen with 8 colours, with the characters placed
; next to each other and one row below the other. This makes it easier
; to design your own font, but requires a different routine to find the
; font. In fact, you need to create a table containing the offsets from the beginning
of the font for each character, and depending on the ASCII value we need to
print, take the corresponding value from the table to find
the position of the character in question. This may seem complex, but
since the characters in the font are in ASCII order, you will see that it is
very easy to write the table with the offsets!
;
 The font is also available in .iff format, to make the system clearer and make it easier to design a new font.
;*****************************************************************************

PrintChar:
tst.w    textctr        ; if the counter is positive, do not print
bne.w    noPrint
move.l    textptr(PC),a0    ; read the character to be printed
moveq    #0,d0
move.b    (a0)+,d0
cmp.l    #textend,textptr    ; are we at the end of the text?
bne.s    noend
lea    scrollmsg(PC),a0    ; if we start again from the beginning!
move.b    (a0)+,d0        ; character in d0
noend:
cmp.b    #1,d0            ; FLAG 1? Then speed = 1
bne.s    nots1
move.w    #32,scspeed        ; initial value of textctr
move.w	#$f9f0,speedlogic    ; value of BPLCON0
move.b    (a0)+,d0        ; next character in d0
bra.s    contscroll
nots1:
cmpi.b    #2,d0            ; FLAG 2? Then speed = 2
bne.s    nots2
move.w    #16,scspeed
move.w    #$e9f0,speedlogic    ; value of BPLCON0
move.b    (a0)+,d0
bra.s    contscroll
nots2:
cmpi.b    #3,d0            ; FLAG 3? Then speed = 3
bne.s    nots3
move.w    #8,scspeed
move.w    #$c9f0,speedlogic    ; value of BPLCON0
move.b    (a0)+,d0
bra.s    contscroll
nots3:
cmpi.b    #4,d0            ; FLAG 4? Then speed = 4
bne.s    nots4
move.w    #4,scspeed
move.w    #$89f0,speedlogic    ; value of BPLCON0
move.b    (a0)+,d0
bra.s    contscroll
nots4:
cmpi.b	#5,d0            ; Flag 5? Then speed = 5
bne.s    contscroll
move.w    #2,scspeed
move.w    #$19f0,speedlogic    ; value of BPLCON0
move.b    (a0)+,d0

; Here, after checking the flags, the character is printed. Note how
; the character is found using the table with the offsets.

contscroll:
move.l    a0,textptr    ; saves the pointer to the next character
subi.b    #$20,d0		; ascii - 20 = the first character is a space
lsl.w    #2,d0        ; multiply by 4 to find the address in the table,
; given that each value in the table is .L (4 bytes)
lea    addresses(PC),a0
move.l    0(a0,d0.w),a0    ; copy the character address, taken
; from the table.

btst    #6,2(a6)    ; dmaconr - waitblit
blt30:
btst	#6,2(a6)    ; dmaconr - waitblit
bne.s    blt30

moveq    #-1,d1
move.l    d1,$44(a6)         ; BLTALWM, BLTAFWM
move.l    #$09F00000,$40(a6)    ; BLTCON0/1 - normal copy
move.l    #$00240028,$64(a6)    ; BLTAMOD = 36, BLTDMOD = 40

lea    BITPLANE+40,a1		; destination pointer
moveq    #3-1,d7            ; number of bitplanes
CopyCharL:

btst    #6,2(a6)    ; dmaconr - waitblit
blt31:
btst    #6,2(a6)	; dmaconr - waitblit
bne.s    blt31

move.l    a0,$50(a6)        ; BLTAPT (character in font)
move.l    a1,$54(a6)        ; BLTDPT (bitplane)
move.w    #32*64+2,$58(a6)	; BLTSIZE

add.w    #32*44,a1    ; next destination bitplane
lea    40*200(a0),a0	; 1 bitplane of the pic containing the font

dbra    d7,copycharL

move.w    scspeed(PC),textctr    ; initial value of the print counter
noPrint:
subq.w    #1,textctr    ; decrement the counter indicating when
; to print
endPrint:
rts

; variables

textptr:     dc.l    scrollmsg    ; pointer to the character to be printed

textctr:     dc.w    0        ; counter indicating when to print
noscroll:     dc.l    0        ; counter indicating when to scroll

scspeed:     dc.w    0        ; initial value of the counter that
; indicates when to print
; varies depending on the speed

speedlogic:     dc.w    0        ; value of BLTCON0
; varies depending on the speed
; because the shift value varies

;*****************************************************************************
; This table contains a series of font addresses, which indicate the
; position of the ASCII characters in the font itself: for example, the first is
; Bigf without any other offsets, in fact the first character found in the font
; is the space, which is also the first in ASCII. The second (which in ASCII is
; the exclamation mark !) is at bigf+4, because the ! in the font is in
; second place, i.e. 4 bytes (32 pixels) after the first, each
; character being 32 pixels wide (and high).
; Since the font is in a 320*200 figure, there can only be
10 characters per horizontal row, so characters 11 to 20
must be in a row below, those from 22 to 30 below that, and
so on.
;*****************************************************************************

addresses:
dc.l BigF    ; first character: ‘ ’
dc.l BigF+4    ; second character: ‘!’
dc.l BigF+8
dc.l BigF+12,BigF+16,BigF+20,BigF+24,BigF+28,BigF+32,BigF+36

; second row of characters in the font: start from 1280, i.e. 32*40, because
; you need to skip the 32 lines of the first row of characters

dc.l BigF+1280        ; eleventh character: "
dc.l BigF+1284
dc.l BigF+1288
dc.l BigF+1292
dc.l BigF+1296,BigF+1300,BigF+1304,BigF+1308,BigF+1312,BigF+1316

; third row of characters in the font

dc.l BigF+2560,BigF+2564,BigF+2568,BigF+2572,BigF+2576,BigF+2580
dc.l BigF+2584,BigF+2588,BigF+2592,BigF+2596
; quarta
dc.l BigF+3840,BigF+3844,BigF+3848,BigF+3852,BigF+3856,BigF+3860
dc.l BigF+3864,BigF+3868,BigF+3872,BigF+3876
; quinta
dc.l BigF+5120,BigF+5124,BigF+5128,BigF+5132,BigF+5136,BigF+5140
dc.l BigF+5144,BigF+5148,BigF+5152,BigF+5156
; sesta
dc.l BigF+6400,BigF+6404,BigF+6408,BigF+6412,BigF+6416,BigF+6420
dc.l BigF+6424,BigF+6428,BigF+6432,BigF+6436



;*****************************************************************************
; Here is the text: by entering 1,2,3,4 you can change the scroll speed
;*****************************************************************************

scrollmsg:
dc.b 4,‘AMIGA EXPERT TEAM’,1,‘ ’,3
dc.b ‘ THE NEW ITALIAN GROUP OF ADVANCED AMIGA USERS ’,2
dc.b ‘ ’,3
dc.b ‘ IF YOU WANT TO GET IN TOUCH WITH AMIGA ENTHUSIASTS ’,2
dc.b ‘WHO USE IT FOR MUSIC, GRAPHICS, PROGRAMMING OR OTHER PURPOSES,’
dc.b ‘WHETHER FOR HOBBY OR WORK, WRITE TO: (RIGHT MOUSE BUTTON TO STOP)’,1
dc.b ‘MIRKO LALLI - VIA VECCHIA ARETINA 64 - 52020 LATERINA STAZIONE - ’,2
dc.b ‘AREZZO - ’,3
dc.b ‘ CREDITS FOR THIS DEMO: ’,1
dc.b ‘ASSEMBLER PROGRAMMING AND GRAPHICS BY FABIO CIUCCI -’,2
dc.b ‘ MUSIC TAKEN FROM A PD LIBRARY ’,3
dc.b "-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-‘,4
dc.b ’=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-=+=-"
dc.b ‘ ’
textend:

; Note: Another CLUB for Amiga is APU: for information tel. 081/5700434
;                             081/7314158
; Thursday-Friday 7pm-10pm

******************************************************************************
;		COPPERLIST:
******************************************************************************

section	copper,data_c

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0		; BplCon1
dc.w    $104,$24    ; BplCon2 - All sprites above the bitplanes
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
dc.w    $100,$200    ; BplCon0 - no bitplanes

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$1af    ; colour1 - TEXT

dc.w    $9707,$FFFE    ; WAIT - draw the bar at the top
dc.w    $180,$110    ; Color0
dc.w	$9807,$FFFE	; wait....
dc.w	$180,$120
dc.w	$9a07,$FFFE
dc.w	$180,$130
dc.w	$9b07,$FFFE
dc.w	$180,$240
dc.w	$9c07,$FFFE
dc.w	$180,$250
dc.w	$9d07,$FFFE
dc.w	$180,$370
dc.w	$9e07,$FFFE
dc.w	$180,$390
dc.w    $9f07,$FFFE
dc.w    $180,$4b0
dc.w    $a007,$FFFE
dc.w    $180,$5d0
dc.w    $a107,$FFFE
dc.w    $180,$4a0
dc.w    $a207,$FFFE
dc.w    $180,$380
dc.w    $a307,$FFFE
dc.w    $180,$360
dc.w    $a407,$FFFE
dc.w	$180,$240
dc.w	$a507,$FFFE
dc.w	$180,$120
dc.w	$a607,$FFFE
dc.w	$180,$110

dc.w	$A707,$FFFE
dc.w	$180,$000

BPLPOINTERS:
dc.w $e0,0,$e2,0    ; first bitplane
dc.w $e4,0,$e6,0    ; second bitplane
dc.w $e8,0,$ea,0    ; third bitplane

dc.w    $100,$3200    ; bplcon0 - 3 lowres bitplanes

dc.w $108,4        ; bpl1mod - skip the 4 bytes where
dc.w $10a,4        ; bpl2mod - would print the text...
; Remember that the screen is 44 bytes wide
; in reality, to leave on the far right,
; outside the visible area, what should not be
; seen. All scrolltext does this.

dc.w    $180,$000    ; colours
dc.w    $182,$111
dc.w    $184,$233
dc.w    $186,$555
dc.w    $188,$778
dc.w    $18a,$aab
dc.w    $18c,$fff
dc.w    $18e,$fff

scol:
DCB.w    6*64,0        ; space for colour shades generated
; by the ‘makecolors’ routine

dc.w    $EE07,$fffe
dc.w    $180,$004

dc.w    $184,$023,$186,$118		; Colori piu' ‘blu’
dc.w	$188,$25b,$18a,$38e,$18c,$acf

dc.w	$182,$550	; this part of copperlist
dc.w    $18e,$155    ; creates the mirror effect, you should know
dc.w    $108,-84    ; how!
dc.w    $10A,-84
dc.w    $F307,$fffe

dc.w    $182,$440
dc.w    $18e,$144
dc.w    $108,-172
dc.w    $10A,-172
dc.w    $108,-84
dc.w    $10A,-84
dc.w    $180,$004
dc.w    $F407,$fffe
dc.w    $182,$330
dc.w    $18e,$133
dc.w    $108,-172
dc.w    $10A,-172
dc.w    $180,$005
dc.w    $F607,$fffe
dc.w    $182,$220
dc.w	$18e,$123
dc.w	$108,-84
dc.w	$10A,-84
dc.w	$180,$006
dc.w	$FA07,$fffe
dc.w	$182,$110
dc.w	$18e,$012
dc.w	$108,-172
dc.w	$10A,-172
dc.w	$180,$007
dc.w	$FD07,$fffe
dc.w	$182,$110
dc.w    $18e,$011
dc.w    $108,-84
dc.w    $10A,-84
dc.w    $180,$008
dc.w    $ffdf,$fffe
dc.w    $0107,$fffe
dc.w    $0407,$fffe
dc.w    $182,$001
dc.w    $18e,$011
dc.w    $108,-172
dc.w    $10A,-172
dc.w	$180,$009
dc.w	$0607,$fffe
dc.w	$182,$002
dc.w	$18e,$111
dc.w	$108,-84
dc.w	$10A,-84
dc.w	$180,$00A
dc.w	$0A07,$fffe
dc.w	$182,$003
dc.w	$18e,$101
dc.w	$108,-172
dc.w	$10A,-172
dc.w	$180,$00B
dc.w	$0D07,$fffe
dc.w	$182,$004
dc.w	$18e,$202
dc.w	$108,-84
dc.w	$10A,-84
dc.w	$180,$00e

dc.w	$1307,$fffe
dc.w	$100,$200	; no bitplanes

dc.w    $FFFF,$FFFE    ; End copperlist

;*****************************************************************************

; Here is the font, which is in a 320*200 image with 3 bitplanes (8 colours)

BigF:
incbin    ‘font4’

;*****************************************************************************

SECTION	BUFY,BSS_C

BITPLANE:
ds.b	3*44*256	; spazio per 3 bitplanes

END

In this listing we see another example of scrolltext, more sophisticated
than the previous one. This is the scroll routine used in the AMIGAET intro
by Fabio Ciucci. In this programme, the scrolltext moves up and down.
 To achieve this effect, two buffers are used for the text.
In the first (invisible) buffer, the characters are printed and the text is scrolled.
From here, the text is copied to the other buffer (which is the visible one) at
a vertical position that varies from one frame to another according to a table.
The second buffer is never deleted because during the copy from the first
buffer to the second, some ‘clean’ (zeroed) lines are also copied, which
delete the part of the old text that is not overwritten by the
new one. To save memory, the two buffers have been combined into one
(at the BITPLANE address) with a size of 320*256 at 3 planes.
This is possible because in reality a screen only 180 lines high is used.
 In fact, the display of the bitplanes is activated by the copperlist
only starting from line $A7 of the display.
Another peculiarity of this listing is that part of the copperlist
is generated by a processor routine, the ‘makecolors’.
The topic of copperlists generated by the processor (and by the blitter!)
will be covered in a future lesson. For now, just take a look at it.

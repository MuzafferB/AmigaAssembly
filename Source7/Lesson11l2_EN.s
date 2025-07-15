
; Lesson11l2.s - Change 3 out of 4 colours (2 bitplanes) for each line.

SECTION    coplanes,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

scr_bytes    = 40    ; Number of bytes for each horizontal line.
; From this, the screen width is calculated
; by multiplying the bytes by 8: normal screen 320/8=40
; E.g. for a screen 336 pixels wide, 336/8=42
; example widths:
; 264 pixels = 33 / 272 pixels = 34 / 280 pixels = 35
; 360 pixels = 45 / 368 pixels = 46 / 376 pixels = 47
; ... 640 pixels = 80 / 648 pixels = 81 ...

scr_h        = 256    ; Screen height in lines
scr_x        = $81    ; Screen start, position XX (normal $xx81) (129)
scr_y        = $2c    ; Screen start, position YY (normal $2cxx) (44)
scr_res        = 1    ; 2 = HighRes (640*xxx) / 1 = LowRes (320*xxx)
scr_lace    = 0    ; 0 = non-interlace (xxx*256) / 1 = interlace (xxx*512)
ham        = 0    ; 0 = non-ham / 1 = ham
scr_bpl        = 2    ; Number of bitplanes

; parameters calculated automatically

scr_w		= scr_bytes*8        ; screen width
scr_size    = scr_bytes*scr_h    ; screen size in bytes
BPLC0    = ((scr_res&2)<<14)+(scr_bpl<<12)+$200+(scr_lace<<2)+(ham<<11)
DIWS	= (scr_y<<8)+scr_x
DIWSt	= ((scr_y+scr_h/(scr_lace+1))&255)<<8+(scr_x+scr_w/scr_res)&255
DDFS	= (scr_x-(16/scr_res+1))/2
DDFSt    = DDFS+(8/scr_res)*(scr_bytes/2-scr_res)


START:

; Point the planes

MOVE.L    #Bitplane1,d0
LEA    PLANES,a0
MOVEQ    #2-1,d7        ; 2 bitplanes
PLOOP:
move.w    d0,6(a0)
swap    d0
move.w    d0,2(a0)
swap    d0
add.l    #40*256,d0
addq.w    #8,a0
dbra    d7,ploop

lea    $dff000,a5
MOVE.W	#DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #LISTE,$80(a5)        ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

bsr.s    CreateCopper    ; create the copperlist

LEA    TEXT(PC),A0    ; text to print
LEA    BITPLANE1,A3    ; destination
bsr.w    print        ; Print

LEA    TEXT2(PC),A0    ; text to print
LEA    BITPLANE2,A3    ; destination
bsr.w    print        ; Print

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0		; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0		; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BEQ.S    Wait

BSR.w    RASTERMAGIC    ; copy from tables in copperlist
BSR.w    CYCLEBLU    ; cycle the blue tab (downwards)
BSR.w	CYCLERED    ; cycles the red tab (upwards)
BSR.w    CYCLEGREEN    ; cycles the green tab (upwards)

btst.b    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts

*****************************************************************************
; This routine creates the copperlist
*****************************************************************************

;     _____
;     / _/
;     /_____\
;     _ \ o.O /
;    / )________\_-_/_________
;    \__/ _ Y _ /__
;     _/______/ : \_____/__ \
;     _/ : \_ .--(_/
;     \_____:_____/.
;     / ___ :\ :
;     / | :..:
;     _/ | \
;     _\________| \_
;     (__________l_________/_ _ _
;     (___________))

CreateCopper:
LEA    CopperEffyz,A1
MOVE.l    #$180,d2    ; col 0
MOVE.l    #$182,d3    ; col 1
MOVE.l    #$186,d4    ; col 3
MOVEQ    #-2,D5        ; $FFFE    ; wait command
MOVE.W    #$0100,d6    ; WAIT ADD: 0107FFFE, 0207FFFE....
MOVE.W    #$2C07,D1    ; start line
MOVEQ    #7-1,D7        ; Num. loops
AGAIN:
LEA    ColTabBlu(PC),A0
LEA    ColTabRosso(PC),A2
LEA    ColTabVerde(PC),A3

REPT    28        ; number of lines: 28*d7
MOVE.W    D1,(A1)+    ; line to wait...
MOVE.W    d5,(A1)+    ; $FFFE wait command
MOVE.W    d2,(A1)+    ; col register 0
MOVE.W    (A0)+,(A1)+    ; col value from blue tab
MOVE.W    d3,(A1)+    ; col register 1
MOVE.W    (A2)+,(A1)+    ; col value from red tab
MOVE.W    d4,(A1)+    ; col register 3
MOVE.W    (A3)+,(A1)+    ; col value from green tab
ADD.W    d6,D1        ; Wait one line below
ENDR

DBRA    D7,AGAIN
RTS

*****************************************************************************

;     __ ___
;         (______)
;         __||||||__
;         (__________)
;		 | |
;         _ __ |
;         (.(._) (((
;         (__ __ __)
;         ./ \ |
;    magic!     `----( \ |
;         __ \____/ /\__
;         / /__\___/__\ \
;        / __ o __ ì g®m


RASTERMAGIC:
LEA    CopperEffyz,A1
MOVEQ    #7-1,D7        ; Num. loops
AGAIN2:
LEA    ColTabBlu(PC),A0
LEA    ColTabRosso(PC),A2
LEA    ColTabVerde(PC),A3

REPT    28        ; number of lines: 28*d7
addq.w    #2+4,a1        ; skip wait and colour register 0
MOVE.W    (A0)+,(A1)+    ; colour value from blue tab
addq.w    #2,a1        ; skip colour register 1
MOVE.W	(A2)+,(A1)+    ; col value from red tab
addq.w    #2,a1        ; skip col register 3
MOVE.W    (A3)+,(A1)+    ; col value from green tab
ADD.W    d6,D1        ; Wait one line below
ENDR

DBRA    D7,AGAIN2
RTS

*****************************************************************************

;     _))_
;     ./ \.
;     | |
;     \_ __/ |
;     (-(--) |
;    (__ __ (((
;     /__ \ __)
; Ue'.. __) \ | g®m
;	 (_____/ |

CYCLEBLU:
LEA    ColTabBlu+54(PC),A0
LEA    ColTabBlu+52(PC),A1
MOVE.W    ColTabBlu+54(PC),D1    ; save the last colour

REPT    27
MOVE.W    (A1),(A0)    ; cycle2
SUBQ.W     #2,A0
SUBQ.W    #2,A1
ENDR

MOVE.W    D1,ColTabBlu    ; Put back the last one 
RTS

*****************************************************************************

CYCLERED:
LEA    ColTabRed(PC),A0
LEA    ColTabRed+2(PC),A1
MOVE.W    (A0),56(A0)

REPT    29        ; cycle 2
MOVE.W    (A1)+,(A0)+
ENDR

RTS

CYCLEGREEN:
LEA    ColTabGreen(PC),A0
LEA    ColTabGreen+2(PC),A1
MOVE.W    (A0),56(A0)

REPT    29        ; cycle 3
MOVE.W    (A1)+,(A0)+
ENDR

RTS		

ColTabBlu:
DC.W	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
DC.W	15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0,0,0,0

ColTabRosso:
DC.W	$100,$200,$300,$400,$500,$600,$700,$800,$900
DC.W	$A00,$B00,$C00,$D00,$E00,$F00,$F00,$E00,$C00
DC.W	$B00,$A00,$900,$800,$700,$600,$500,$400,$300
DC.W	$200,$100,0,0,0,0

ColTabVerde:
DC.W	$010,$020,$030,$040,$050,$060,$070,$080,$090
DC.W	$0A0,$0B0,$0C0,$0D0,$0E0,$0F0,$0F0,$0E0,$0D0,$0C0
DC.W	$0B0,$0A0,$090,$080,$070,$060,$050,$040,$030,$020
DC.W	$010,0,0,0,0


*****************************************************************************
;    Routine that prints 8x8 pixel characters
*****************************************************************************

PRINT:
MOVEQ    #23-1,D3    ; NUMBER OF LINES TO PRINT: 23
PRINTRIGA:
MOVEQ    #40-1,D0    ; NUMBER OF COLUMNS PER LINE: 40
PRINTCHAR2:
MOVEQ    #0,D2        ; Clear d2
MOVE.B	(A0)+,D2    ; Next character in d2
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER
LSL.W    #3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 " ‘
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ’ ‘
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ’ "
MOVE.B    (A2)+,40*4(A3)	; print LINE 5 ‘ ’
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

ADDQ.w    #1,A3        ; A1+1, move forward 8 bits (NEXT CHARACTER)

DBRA    D0,PRINTCHAR2    ; PRINT D0 (40) CHARACTERS PER LINE

ADD.W    #40*7,A3    ; GO TO THE NEXT LINE

DBRA    D3,PRINTRIGA    ; MAKE D3 LINES

RTS


; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
;	 1234567890123456789012345678901234567890
dc.b    “ FIRST LINE (only in text1) ” ; 1
dc.b    “ ” ; 2
dc.b    ' /\ / # # “ ; 3
dc.b    ” / \/ # # “ ; 4
dc.b    ” # # “ ; 5
dc.b    ” SIXTH LINE (both bitplanes)“ ; 6
dc.b    ” ' ; 7
dc.b    “ ” ; 8
dc.b    “FABIO CIUCCI INTERNATIONAL” ; 9
dc.b    “ ” ; 10
dc.b    “ 1 4 6 89 !@ $ ^& () +| =- ]{ ” ; 11
dc.b    “ ” ; 12
dc.b    “ LA A I G N T C OBLITERATION ” ; 15
dc.b    “ ” ; 25
dc.b    “ ” ; 16
dc.b    “ In the middle of the journey of our life ” ; 17
dc.b    “ ” ; 18
dc.b    “ I found myself in a dark forest ” ; 19
dc.b    “ ” ; 20
dc.b    “ THAT WAS THE RIGHT PATH ” ; 21
dc.b    “ ” ; 22
dc.b    “ AHI Quanto a DIR QUAL ERA... ” ; 23
dc.b    “ ” ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26
dc.b    “ ” ; 27

EVEN

; number of characters per line: 40
TEXT2:     ;         1111111111222222222233333333334
;     1234567890123456789012345678901234567890
dc.b    “ ” ; 1
dc.b    “ SECOND LINE (only in text2) ” ; 2
dc.b    “ /\ / ## ” ; 3
dc.b    “ / \/ ## ” ; 4
dc.b    “ ## ” ; 5
dc.b    “ SIXTH LINE (both bitplanes)” ; 6
dc.b    “ ” ; 7
dc.b    “ ” ; 8
dc.b    “FABIO COMMUNICATION INTERNATIONAL” ; 9
dc.b    “ ” ; 10
dc.b    ' 1234567 90 @#$%^&*( _+|\=-[]{} “ ; 11
dc.b    ” ' ; 12
dc.b    “ LA PALINGENETICA B I E A I N ” ; 15
dc.b    “ ” ; 25
dc.b    “ ” ; 16
dc.b    “ Nel del cammin di vita ” ; 17
dc.b    “ ” ; 18
dc.b    “ I was lost in darkness ” ; 19
dc.b    “ ” ; 20
dc.b    “ THAT THE WAY WAS LOST ” ; 21
dc.b    “ ” ; 22
dc.b    “ OH, how it was... ” ; 23
dc.b	“ ” ; 24
dc.b    “ ” ; 25
dc.b    “ ” ; 26
dc.b    “ ” ; 27

EVEN

;    The 8x8 character FONT is copied to CHIP by the CPU and not by the blitter,
;    so it can also be in fast RAM. In fact, that would be better!

FONT:
incbin	‘assembler2:sorgenti4/nice.fnt’

*****************************************************************************

SECTION    COP,DATA_C

LISTE:
dc.w    $8e,DIWS    ; DiwStrt
dc.w    $90,DIWSt    ; DiwStop
dc.w    $92,DDFS    ; DdfStart
dc.w    $94,DDFSt	; DdfStop

dc.w    $102,$0        ; Bplcon1
dc.w    $104,$0        ; Bplcon2
dc.w    $108,$0        ; Bpl1mod
dc.w    $10a,$0        ; Bpl2mod
PLANES:
DC.W    $E0,0,$E2,0,$E4,0,$E6,0
dc.w    $100,BPLC0    ; Bplcon0 - 2 lowres bitplanes
DC.W    $184,$fff    ; colour2 yellow (fixed)
CopperEffyz:
DCB.W    28*8*7        ; Space for the effect
DC.W    $FFFF,$FFFE

*****************************************************************************

SECTION    BPLBUF,BSS_C

Bitplane1:
ds.b    40*256
Bitplane2:
ds.b    40*256

END

Did you notice the Italian flag? We always give recognition to
foreigners! They're no match for us!


; Lesson 11l4.s     - Figure wiggle obtained by changing each line
;         pointers to bitplanes, plus the colour0 gradient
;         moves upwards.

Section BITPLANEolljelly,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; salva interrupt, dma eccetera.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper, bitplane, blitter DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

scr_bytes    = 40    ; Number of bytes per horizontal line.
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
scr_lace    = 0	; 0 = non-interlace (xxx*256) / 1 = interlace (xxx*512)
ham        = 0    ; 0 = non-ham / 1 = ham
scr_bpl        = 1    ; Number of bitplanes

; parameters calculated automatically

scr_w        = scr_bytes*8		; screen width
scr_size    = scr_bytes*scr_h    ; screen size in bytes
BPLC0    = ((scr_res&2)<<14)+(scr_bpl<<12)+$200+(scr_lace<<2)+(ham<<11)
DIWS    = (scr_y<<8)+scr_x
DIWSt	= ((scr_y+scr_h/(scr_lace+1))&255)<<8+(scr_x+scr_w/scr_res)&255
DDFS	= (scr_x-(16/scr_res+1))/2
DDFSt	= DDFS+(8/scr_res)*(scr_bytes/2-scr_res)


START:
bsr.s    SetCop        ; Create the copperlist

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPER,$80(a5)		; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w    PrintCharacter    ; Print one character at a time
BSR.w    SystemCopy    ; Copy values from tables to copy
BSR.W    RotateTabOndegg    ; Rotate values in the wobble table
BSR.W    RotateTabColori    ; Rotate the colour table

MOVE.L    #$1ff00,d1    ; bits for selection via AND
MOVE.L	#$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001    ; Mouse pressed?
bne.s    mouse
rts            ; exit

;***************************************************************************
; This routine creates the copperlist and enters the first values
;***************************************************************************

;     ° o·
;    ___ _))) . °
;    \ -\_/ (_.) ·°
;     \- ___)o·
;     /-/`-----'
;     ¯¯ g®m

SETCOP:
LEA    COPPER1,A0    ; Copper effect address
MOVE.L    ADRCOL1(PC),A2    ; Pointer to colour table
MOVE.L	#$2c07FFFE,D7 ; Wait (first line $30)
MOVE.L    #BITPLANE,D0 ; Bitplane address
LEA    TABOSC(PC),A1 ; Wavetable
MOVEQ    #39-1,D5 ; Number of table values usable for this
; effect. (note: it is not easy to understand
; how many lines the effect is actually long,
; because you need to calculate that each of these
; loops can repeat the line several times.
DoEffect:
MOVE.B    (A1)+,D6    ; Put next ripple value in d6
TST.B	D6        ; Do we need to cut the line already?
BNE.S    RipuntaLinea    ; If not, point it...
ADDI.L    #40,D0        ; Or add the length of 1 line - point
; to the next line of the bitplane
DBRA    D5,FaiEffetto    ; And continue the loop
BRA.w    FineEffetto

RipuntaLinea:
MOVE.L    D7,(A0)+    ; Put Wait in coplist
SWAP    D0        ; swap the plane address
MOVE.W    #$E0,(A0)+    ; BPL1PTH
MOVE.W    D0,(A0)+    ; point to the high word
SWAP    D0        ; swap the plane address again
MOVE.W    #$E2,(A0)+    ; BPL1PTL
MOVE.W    D0,(A0)+    ; point to the low word
TST.W    (A2)        ; end colour tab?
BNE.S    SETCOP2        ; If not yet, OK
MOVE.L	ADRCOL2(PC),A2    ; Otherwise: colour tab -> restart
SETCOP2:
MOVE.W    #$180,(A0)+    ; colour register 0
MOVE.W    (A2)+,(A0)+    ; value of colour 0
ADDI.L    #$01000000,D7    ; Wait one line below
BCC.S    SETCOP3        ; Have we reached $FF? If not, ok,
MOVE.L    #$FFDFFFFE,(A0)+ ; Otherwise, end ntsc zone ($FF)
MOVE.L    #$0011FFFE,D7     ; And we need to put these 2 waits.
SETCOP3:
SUBQ.B	#1,D6    ; Subtract the value of ‘line repeat’ taken from
; TABOSC.
TST.B    D6    ; Have we repeated the line enough times?
BNE.S    RipuntaLinea    ; If not, repeat it

ADDI.L    #40,D0        ; Otherwise, point 1 line lower
DBRA    D5,FaiEffetto    ; and let's continue the effect.

FineEffetto:
MOVE.L    #$01000200,(A0)+    ; Set bplcon0 = no bitplanes
MOVE.L    #$FFFFFFFE,(A0)+    ; Set the end of the copperlist
RTS

;****************************************************************************
; This routine rotates the colours in the colour table!
;****************************************************************************

;     ______________
;     \ \__/ / 
;     \__________/
;     __|______|__
;    __(\___)(___/)__
;    \_\ \/ /_/
;     \ \____/ /
;     \______/ g®m
;

RotateColourTable:
LEA	COLORSTAB(PC),A0    ; colour table
MOVE.W    (A0)+,D0        ; Save the first colour in d0
RotateColourTable2:
TST.W    (A0)        ; end of table?
BNE.S    RotateColourTable1        ; If not, ok
MOVE.W    D0,-2(A0)	; otherwise put the first colour as the last
RTS

RoteaTabColori1:
MOVE.W    (A0)+,-4(A0)    ; Move (rotate) the colour ‘backwards’
BRA.S    RoteaTabColori2

;***************************************************************************
; This routine rotates the values in the ‘TABOSC’ table
;***************************************************************************

RoteaTabOndegg:
LEA    TABOSC(PC),A0    ; Table address
MOVEQ    #63-1,D7    ; Number of values in the table
MOVE.B    (A0),D0        ; Save the first value in d0
RoteaTabOndegg1:
MOVE.B    1(A0),(A0)+    ; Move the values ‘back’.
DBRA    D7,RoteaTabOndegg1
MOVE.B	D0,-1(A0)	; Rimetti il primo valore come ultimo
RTS

;***************************************************************************

ADRCOL1:
DC.L	COLORSTAB
ADRCOL2:
DC.L	COLORSTAB

COLORSTAB:
DC.W    $FC9,$EC9,$DC9,$CC9,$CB9,$CA9,$C99,$C9A,$C9B,$C9C
DC.W    $C9D,$C9E,$C9F,$B9F,$A9F,$99F,$9AF,$9BF,$9CF,$ACF
DC.W    $BCF,$CCF,$DCF,$ECF,$FCF,$FBF,$FAF,$F9F,$F9E,$F9D
DC.W	$F9C,$E9C,$D9C,$C9C,$CAC,$CBC,$CCC,$CDC,$CEC,$CFC
DC.W    $CFB,$CFA,$CF9,$BF9,$AF9,$9F9,$9FA,$9FB,$9FC,$AFC
DC.W    $BFC,$CFC,$DFC,$EFC,$FFC,$FEC,$FDC,$FCC,$FCB,$FCA
DC.W    0    ; zero ends the table

;***************************************************************************
; The routine is nothing more than SETCOP without the parts that write the registers
; and the waits: only what is necessary is written.
; This routine acts on the copperlist, which redefines the
; pointers to the bitplanes at each line. By reading from a table, it knows how many times to repeat each line of the
; pic, i.e. how many times to repoint it. If, for example, the table
; there are the values 1,2,3, then it will point to the first line in the first line
; of the screen (once), then it will point to the second line twice, and the third
; line three times. Here is a ‘little drawing’:
;
; line1
; line2
; line2
; line3
; line 3
; line 3
;
; Note that the figure gets longer...
;***************************************************************************

;     /) ________ (\
;    (__/ \__)
;     / ___ ___ \
;     \ \°_)(_°/ /
;	 \__ `' __/
;     / \
;     \(‘’‘’)/g®m
;     ¯ ¯

Cop System:
LEA    COPPER1,A0    ; Copper effect address
MOVE.L    ADRCOL1(PC),A2    ; Pointer to colour table
MOVE.L    #$2c07FFFE,D7    ; Wait (first line $30)
MOVE.L    #BITPLANE,D0    ; Bitplane address
LEA    TABOSC(PC),A1    ; Wavetable
MOVEQ	#39-1,D5    ; Number of table values usable for this
; effect. (note: it is not easy to understand
; how many lines the effect is actually long,
; because you need to calculate that each of these
; loops can repeat the line several times.
DoEffect2:
MOVE.B    (A1)+,D6    ; Put next wobble value in d6
TST.B    D6        ; Do we need to cut the line already?
BNE.S    RepointLine2    ; If not, let's point it...
ADDI.L	#40,D0        ; Or add the length of 1 line - point
; to the next line of the bitplane
DBRA    D5,FaiEffetto2    ; And continue the loop
BRA.w    FineEffetto2

RipuntaLinea2:
addq.w    #6,a0        ; Skip WAIT and BPL1PTH
SWAP    D0        ; swap the plane address
MOVE.W    D0,(A0)+    ; point to the high word
SWAP    D0        ; swap the plane address again
addq.w    #2,a0        ; skip BPL1PTL
MOVE.W    D0,(A0)+    ; point to the low word
TST.W	(A2)        ; end of colour tab?
BNE.S    SETCOP22    ; If not yet, OK
MOVE.L    ADRCOL2(PC),A2    ; Otherwise: colour tab -> restart
SETCOP22:
addq.w    #2,a0        ; skip colour register 0
MOVE.W    (A2)+,(A0)+    ; value of colour0
ADDI.L    #$01000000,D7    ; Wait one line below
BCC.S    SETCOP32    ; Have we reached $FF? If not, ok,
addq.w    #4,a0        ; Skip FFDFFFFE
MOVE.L    #$0011FFFE,D7     ; And you need to put these 2 waits.
SETCOP32:
SUBQ.B    #1,D6    ; Subtract the value of ‘line repeat’ taken from
; TABOSC.
TST.B    D6    ; Have we repeated the line enough times?
BNE.S    RepointLine2    ; If not, repoint it, repeating it

ADDI.L    #40,D0        ; Otherwise, point 1 line lower
DBRA    D5,PerformEffect2    ; and let's continue the effect.

EndEffect2:
RTS

;********************************************************************

; Tab with 64 values .byte. Indicates how many lines the same line must be repeated
; For example, where there is a value 2, the line is repeated 2 times,
; i.e. it is doubled in height.

TABOSC:
DC.B	1,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9
DC.B	9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2
DC.B	2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9
DC.B	9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,1

EVEN

*****************************************************************************
;			Routine di Print
*****************************************************************************

PRINTcharacter:
movem.l    d2/a0/a2-a3,-(SP)
MOVE.L    PuntaTESTO(PC),A0 ; Address of the text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B	(A0)+,D2    ; Next character in d2
CMP.B    #$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s    NotEndLine    ; If no, do not go to the next line

ADD.L    #40*7,PointerBITPLANE    ; GO TO THE NEXT LINE
ADDQ.L	#1,TextPointer        ; first character of line after
; (skip ZERO)
move.b    (a0)+,d2        ; first character of line after
; (skip ZERO)

NotEndOfLine:
SUB.B    #$20,D2		; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER, IN
; ORDER TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
LSL.W	#3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L	PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B	(A2)+,40*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

ADDQ.L	#1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
movem.l    (SP)+,d2/a0/a2-a3
RTS


PuntaTesto:
dc.l    TEXT

BitplanePointer:
dc.l    BITPLANE

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
; 1234567890123456789012345678901234567890
dc.b    ' * * * * * * * * * * * * * * * * * “,0 ; 1
dc.b    ” * MAMMA MIA MI BALLA * “,0 ; 2
dc.b    ” * LO SCHERMO * “,0 ; 3
dc.b    ” * * * * * * * * * * * * * * * * * ',$FF ; 4

EVEN

;    The 8x8 character FONT copied to CHIP by the CPU and not by the blitter,
;    so it can also be in fast RAM. In fact, that would be better!

FONT:
incbin    ‘assembler2:sorgenti4/nice.fnt’

;********************************************************************
;				COPPERLIST
;********************************************************************

section	cooppera,data_C

COPPER:
dc.w	$8e,DIWS	; DiwStrt
dc.w	$90,DIWSt	; DiwStop
dc.w    $92,DDFS    ; DdfStart
dc.w    $94,DDFSt    ; DdfStop
dc.w    $100,BPLC0    ; BplCon0
dc.w    $108,0        ; bpl1mod
dc.w    $10a,0        ; bpl2mod
DC.w    $182,$000    ; Colour1 (text) - BLACK
COPPER1:
DCB.b    4000,0    ; Warning! The length of the effect depends
; on the TABOSC table and is not easy to calculate...
DC.L    $FFFFFFFE

;********************************************************************
;	Il bitplane
;********************************************************************
section	bitplane,bss_C

BITPLANE:
ds.b    40*320

end

We saw a similar effect earlier by changing the modules, now by changing
the bplpointers instead. This system is slower than the one with modules if
you have to change the pointers of many bitplanes every line, but each plane
could be defined differently to go its own way,
whereas the bplmod involves all even and/or odd planes.
A special feature of this source is that the values of the tables for the planes
and colours are not ‘rotated’ by rereading them from the cop and moving them, but
by rotating the values in the tables themselves, so that it is sufficient to copy each time from
the table to the copperlist, after the table has been ‘rotated’.
This system is faster than others when you have fast RAM, because
if you had to read the value from the copperlist and rewrite it later or
backwards, you would have to access the CHIP RAM twice, with the associated ‘delays’,
whereas in our case we access the table in FAST, with minimal time loss
, and write only once per colour/plane in CHIP. On computers such as the
A4000, the only slowdown is caused by reading/writing to CHIP RAM,
so the speed of the routine execution doubles.
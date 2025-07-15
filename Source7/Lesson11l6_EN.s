
; Lesson 11l6.s        Interlaced mode management routine (640x512)
;            which reads bit 15 (LOF) of VPOSR ($dff004).
;            Pressing the right button does not execute this routine,
;            and you will notice that sometimes the even lines or
;            the odd lines remain in ‘pseudo-non lace’.

SECTION    Interlace,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

WaitDisk    EQU    30

scr_bytes    = 80    ; Number of bytes per horizontal line.
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
scr_res        = 2    ; 2 = HighRes (640*xxx) / 1 = LowRes (320*xxx)
scr_lace	= 1    ; 0 = non-interlace (xxx*256) / 1 = interlace (xxx*512)
ham        = 0    ; 0 = non-ham / 1 = ham
scr_bpl        = 1    ; Number of bitplanes

; parameters calculated automatically

scr_w        = scr_bytes*8        ; screen width
scr_size    = scr_bytes*scr_h    ; screen size in bytes
BPLC0    = ((scr_res&2)<<14)+(scr_bpl<<12)+$200+(scr_lace<<2)+(ham<<11)
DIWS	= (scr_y<<8)+scr_x
DIWSt	= ((scr_y+scr_h/(scr_lace+1))&255)<<8+(scr_x+scr_w/scr_res)&255
DDFS	= (scr_x-(16/scr_res+1))/2
DDFSt	= DDFS+(8/scr_res)*(scr_bytes/2-scr_res)


START:

;    Point the bitplanes in copperlist

MOVE.L    #BITPLANE,d0    ; put the bitplane address in d0
LEA    BPLPOINTERS,A1    ; pointers in COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address


MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$01000,d2    ; line to wait for = $010
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $010
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $010
Beq.S    Waity2

btst    #2,$16(A5)	; Right button pressed?
beq.s    NonLaceint

bsr.s    laceint        ; Routine that points to even or odd lines
; each frame depending on the LOF bit for
; interlacing
NonLaceint:
bsr.w    PrintCarattere    ; Print one character at a time

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

rts

******************************************************************************
; INTERLACE ROUTINE - Checks the LOF (Long Frame) bit to see whether
; even or odd lines should be displayed, and points accordingly.
******************************************************************************

LACEINT:
MOVE.L    #BITPLANE,D0    ; Bitplane address
btst.b    #15-8,4(A5)    ; VPOSR LOF bit?
Beq.S	MakeOdd    ; If yes, move to the odd lines
ADD.L    #scr_bytes,D0        ; Or add the length of a line,
; starting the display from the
; second: display even lines!
MakeOdd:
LEA    BPLPOINTERS,A1    ; PLANE POINTERS IN COPLIST
MOVE.W	D0,6(A1)    ; Point to the figure
SWAP    D0
MOVE.W    D0,2(A1)
RTS

*****************************************************************************
;            Print routine
*****************************************************************************

PRINTcharacter:
MOVE.L    PointTEXT(PC),A0 ; Address of text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
CMP.B    #$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s    NotEndLine    ; If no, do not go to the next line

ADD.L    #scr_bytes*7,PuntaBITPLANE    ; GO TO NEW LINE
ADDQ.L    #1,PuntaTesto        ; first character of the line after
; (skip ZERO)
move.b    (a0)+,d2        ; first character of the line after
; (skip ZERO)

NonFineRiga:
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), into $01...
LSL.W    #3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; as the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,scr_bytes(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,scr_bytes*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,scr_bytes*3(A3)    ; print LINE 4 " ‘
MOVE.B    (A2)+,scr_bytes*4(A3)    ; print LINE 5 ’ ‘
MOVE.B    (A2)+,scr_bytes*5(A3)    ; print LINE 6 ’ ‘
MOVE.B    (A2)+,scr_bytes*6(A3)    ; print LINE 7 ’ "
MOVE.B    (A2)+,scr_bytes*7(A3)    ; print LINE 8 ‘ ’

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
RTS

TextPointer:
dc.l    TEXT

BitplanePointer:
dc.l    BITPLANE

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
; 1234567890123456789012345678901234567890
dc.b    ' What small writing! You can't even read it ; 1
dc.b    “never mind... but it's in 640x512! ”,0 ; 1b
;
dc.b    “Try pressing the right mouse button and you'll ; 2
dc.b    'see what the coders see ”,0 ; 2b
;
dc.b    ‘don't know how interlacing works, hah’ ; 3
dc.b    ‘aha! It's simple, isn't it? ’,0 ; 3b
;
dc.b    “Program, make some demos or some games, it's the most creative thing you can do in the world today. ” ; 4
dc.b    " ; 4b
;
dc.b    “you can do in the modern world. ” ; 5
dc.b    “ ”,$FF ; 5b - END

EVEN


;    The 8x8 character FONT.

FONT:
incbin    ‘assembler2:sources4/nice.fnt’

******************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8e,DIWS	; DiwStrt
dc.w	$90,DIWSt	; DiwStop
dc.w	$92,DDFS	; DdfStart
dc.w    $94,DDFSt    ; DdfStop

dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,80        ; Bpl1Mod \ INTERLACE: module = line length!
dc.w    $10a,80        ; Bpl2Mod / to skip them (even or odd)

; 5432109876543210
;    dc.w    $100,%1001001000000100    ; 1 bitplane, HIRES LACE 640x512
;                    ; note bit 2 set for LACE!!

dc.w    $100,BPLC0    ; BplCon0 -> let's calculate automatically!


BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane

dc.w    $180,$226    ; colour0 - BACKGROUND
dc.w    $182,$0b0    ; colour1 - plane 1 normal position, this is
; the part that ‘protrudes’ at the top.

dc.w    $FFFF,$FFFE    ; End of copperlist

******************************************************************************

SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    scr_bytes*scr_h    ; 80*512 one bitplane Hires int. 640x512

end

Note that the automatic calculation system for
diwstart/stop etc. has been used. However, for interlace, remember to
set the module to ‘scr_bytes’, in this case 80.

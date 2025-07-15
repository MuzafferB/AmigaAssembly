
; Lesson 11m2.s - Using the level 2 interrupt ($68) to read the
;         codes of the keys pressed on the keyboard.
;         In this case, we also decode the key read
;         by transforming it into the corresponding ASCII character.

Section    InterruptKey,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup2.s’    ; save interrupt, dma, etc.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper, bitplane and DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:

;    Point the bitplanes in copperlist

MOVE.L    #BITPLANE,d0    ; put the bitplane address in d0
LEA    BPLPOINTERS,A1    ; pointers in COPPERLIST
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address

move.l    BaseVBR(PC),a0     ; In a0, the value of VBR

MOVE.L    #MioInt68KeyB,$68(A0)    ; Routine for the internal keyboard level 2
move.l    #MioInt6c,$6c(a0)    ; I put my internal routine level 3

MOVE.W    #DMASET,$96(a5)		; DMACON - enables bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_init		; initialise the music routine
movem.l    (SP)+,d0-d7/a0-a6

; 5432109876543210
move.w    #%1100000000101000,$9a(a5) ; INTENA - enable only VERTB
; level 3 and level 2
Mouse:
btst    #6,$bfe001
bne.s    mouse

bsr.w    mt_end         ; end of replay!
rts             ; exit

even

*****************************************************************************
*    INTERRUPT ROUTINE $68 (level 2) - KEYBOARD management
*****************************************************************************

;03    PORTS    2 ($68)    Input/Output Ports and timers, connected to the INT2 line

MioInt68KeyB:    ; $68
movem.l d0/a0,-(sp)    ; save the registers used in the stack
lea    $dff000,a0    ; custom register for offset

MOVE.B    $BFED01,D0    ; Ciaa icr - in d0 (reading the icr also causes
; it to be reset, so the int is
; ‘cancelled’ as in intreq).
BTST.l    #7,D0    ; IR bit (interrupt cia authorised), reset?
BEQ.s	NonKey    ; if yes, exit
BTST.l    #3,D0    ; SP bit (keyboard interrupt), reset?
BEQ.s    NonKey    ; if yes, exit

MOVE.W    $1C(A0),D0    ; INTENAR in d0
BTST.l    #14,D0        ; Master enable bit reset?
BEQ.s    NonKey        ; If yes, interrupts not active!
AND.W    $1E(A0),D0    ; INREQR - only the bits
; that are set in both INTENA and INTREQ
; remain set in d1, so as to be sure that the interrupt
; that occurred was enabled.
btst.l    #3,d0        ; INTREQR - PORTS?
beq.w	NonKey        ; If not, then exit!

; After the checks, if we are here it means that we have to take the character!

moveq    #0,d0
move.b    $bfec01,d0    ; CIAA sdr (serial data register - connected
; to the keyboard - contains the byte sent by
; the keyboard chip) READ THE CHAR!

bsr.s    convertichar    ; Convert the character to ASCII

; Now we have to tell the keyboard that we have taken the data!

bset.b    #6,$bfee01    ; CIAA cra - sp ($bfec01) output, in order to
; lower the KDAT line to confirm that
; we have received the character.

st.b    $bfec01        ; $FF in $bfec01 - ue'! I received the data!

; Here we need to put a routine that waits 90 microseconds because the
; KDAT line must remain low long enough to be ‘understood’ by all
; types of keyboards. For example, you can wait for 3 or 4 raster lines.

moveq    #4-1,d0	; Number of lines to wait for = 4 (in practice 3 plus
; the fraction we are in at the start)
waitlines:
move.b    6(a0),d1    ; $dff006 - current vertical line in d1
stepline:
cmp.b    6(a0),d1    ; are we still on the same line?
beq.s    stepline    ; if waiting
dbra    d0,waitlines    ; ‘waiting’ line, wait d0-1 lines

; Now that we have waited, we can return $bfec01 to input mode...

bclr.b    #6,$bfee01    ; CIAA cra - sp (bfec01) input again.

NonKey:        ; 3210
move.w    #%1000,$9c(a0)    ; INTREQ remove request, int executed!
movem.l (sp)+,d0/a0    ; restore registers from stack
rte

*****************************************************************************
*    INTERRUPT ROUTINE $6c (level 3) - VERTB and COPER used.     *
*****************************************************************************

;06    BLIT    3 ($6c)    If the blitter has finished a blit, set to 1
;05    VERTB	3 ($6c)    Generated every time the electronic brush is
;            at line 00, i.e. at the beginning of each vertical blank.
;04    COPER    3 ($6c)    Can be set with copper to generate it at a certain
;            video line. Just request it after a certain WAIT.

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, reset?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.s    PrintaChar        ; Print the character
bsr.w    mt_music        ; play the music
movem.l    (SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
nointVERTB:
NointCOPER:
NoBLIT:         ;6543210
move.w    #%1110000,$dff09c ; INTREQ - clear BLIT,VERTB and COPER requests
rte    ; exit from COPER/BLIT/VERTB int


*****************************************************************************
; SubRoutine che converte il carattere in ASCII
*****************************************************************************

ConvertiChar:
movem.l	d1-d2/a0,-(SP)

; data received bit: 6 5 4 3 2 1 0 7
; bit 7 is 1 if the key is released

not.b    d0            ;not touched is transmitted
lsr.b    #1,d0            ;and rotated to the left
bcs.b    Key_up

cmp.b    #$60,d0            ;left shift
blo.b    To_Ascii
bset    d0,Control_Key
bra.b    exit

Key_up:
cmp.b    #$60,d0            ;left shift
blo.b    exit
bclr    d0,Control_Key
bra.b	exit

;    bit    7 6 5 4 3 2 1 0
; Amiga Alt Ctrl caps shift
; r l r l lock r l

to_ascii:
move.b    Control_Key(PC),d1
beq.b    Get_Char
move.b    d1,d2
and.b    #%00000111,d1
beq.b    tst_alt
add.w    #$68,d0
bra.b    Get_Char
tst_alt:
and.b    #%00110000,d2
;    beq    ....
add.w    #$68*2,d0
Get_Char:
lea    Raw_2_Ascii(pc),a0
move.b    (a0,d0.w),d0
move.b    d0,ascii_char
clr.b    received    ; the data is ready!
exit:
movem.l    (SP)+,d1-d2/a0
rts

*****************************************************************************

PrintaChar:
tst.b	received	; Dato ricevuto?
bne.s	NonPremuto
st.b	received
moveq	#0,d0
move.b    ascii_char(pc),d0
cmp.b    #-1,d0
beq.b    NotValid ; it was a special character such as help, tab, etc.
bsr.s    PrintD0 ; otherwise print the character on the screen
NotValid:
NotPressed:
rts

Control_Key:    dc.b	0
ascii_char:    dc.b    0
received:     dc.b    -1
contariga:    dc.b    0

even

*****************************************************************************
; Print routine for the character in d0
*****************************************************************************

PRINTAd0:
movem.l    a2-a3,-(SP)

SUB.B    #$20,D0        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), in $00, that
; OF THE ASTERISK ($21), in $01...
LSL.W    #3,D0        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D0,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

cmp.b    #80,ContaRiga    ; 80 characters printed?
bne.s    NonFine
add.l    #80*7,PuntaBitplane    ; Go to new line
clr.b    ContaRiga
NonFine:
MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B	(A2)+,80(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,80*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,80*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,80*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,80*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,80*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,80*7(A3)    ; print LINE 8 ‘ ’

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.B	#1,ContaRiga

movem.l    (SP)+,a2-a3
RTS

PuntaBitplane:
dc.l    BITPLANE


; ASCII conversion table. Easily modifiable for Italian
or other keyboards.

raw_2_ascii:
dc.b    “`”
dc.b    “1”
dc.b    “2”
dc.b    “3”
dc.b    “4”
dc.b    “5”
dc.b    “6”
dc.b    “7”
dc.b    “8”
dc.b    “9”
dc.b    “0”
dc.b	“-”
dc.b    “=”
dc.b    “\”
dc.b    -1    ;<<<<<<<<<<<<<<
dc.b    “0”    ;numeric keypad
dc.b    “q”
dc.b    “w”
dc.b	“e”
dc.b    “r”
dc.b    “t”
dc.b    “y”
dc.b    “u”
dc.b    “i”
dc.b    “o”
dc.b    “p”
dc.b    “[”
dc.b    “]”
dc.b    -1    ;<<<<<<<<<<<<<<<<<
dc.b    “1”
dc.b    “2”
dc.b    “3”
dc.b    “a”
dc.b    “s”
dc.b    “d”
dc.b    “f”
dc.b    “g”
dc.b    “h”
dc.b    “j”
dc.b    “k”
dc.b	“l”
dc.b    “;”
dc.b 39
dc.b    -1    ;not used
dc.b    -1    ;<<<<<<<<<<<<<<<<<<<<
dc.b    “4”
dc.b    “5”
dc.b    “6”
dc.b    “<”
dc.b    “z”
dc.b    “x”
dc.b    “c”
dc.b    “v”
dc.b    “b”
dc.b    “n”
dc.b    “m”
dc.b    “,”
dc.b    '.“
dc.b    ”/'
dc.b    -1    ;<<<<<<<<<<<<<<<<<<
dc.b    “.”
dc.b    “7”
dc.b    “8”
dc.b    “9”
dc.b    “ ”    ;space
dc.b    -1    ;back space
dc.b    -1	;tab
dc.b    -1    ;return    keypad
dc.b    -1    ;return
dc.b    -1    ;esc
dc.b    -1    ;del
dc.b    -1    ;<<<<<<<<<
dc.b    -1    ;<<<<<<<<<
dc.b    -1	;<<<<<<<<<
dc.b    “-”
dc.b    -1    ;<<<<<<<<<
dc.b    -1    ;up
dc.b    -1    ;down
dc.b    -1	;dx
dc.b    -1    ;sx
dc.b    -1    ;f1
dc.b    -1    ;f2
dc.b    -1    ;f3
dc.b    -1    ;f4
dc.b    -1    ;f5
dc.b    -1    ;f6
dc.b    -1    ;f7
dc.b -1 ;f8
dc.b -1 ;f9
dc.b -1 ;f10
dc.b “(”
dc.b	“)”
dc.b    “/”
dc.b    “*”
dc.b    “+”
dc.b    -1    ;help
dc.b    -1    ;lshift
dc.b    -1    ;rshift
dc.b    -1    ;caps lock
dc.b    -1    ;ctrl
dc.b    -1	;lalt
dc.b    -1    ;ralt
dc.b    -1    ;lamiga
dc.b    -1    ;ramiga

dc.b    “~”    ;shift-tati
dc.b    “!”
dc.b    “@”
dc.b    “#”
dc.b	“$”
dc.b    “%”
dc.b    “^”
dc.b    “&”
dc.b    “*”
dc.b    “(”
dc.b    “)”
dc.b    “_”
dc.b    “+”
dc.b    “|”
dc.b    -1    ;<<<<<<<<<<<<<<
dc.b    “0”	;numeric keypad
dc.b    “Q”
dc.b    “W”
dc.b    “E”
dc.b    “R”
dc.b    “T”
dc.b    “Y”
dc.b    “U”
dc.b    “I”
dc.b    “O”
dc.b    “P”
dc.b    '{“
dc.b    ”}'
dc.b    -1    ;<<<<<<<<<<<<<<<<<
dc.b    “1”    ;keypad
dc.b    “2”    ;keypad
dc.b    “3”    ;keypad
dc.b    “A”
dc.b    “S”
dc.b	“D”
dc.b    “F”
dc.b    “G”
dc.b    “H”
dc.b    “J”
dc.b	“K”
dc.b    “L”
dc.b    “:”
dc.b “"”
dc.b    -1    ;not used
dc.b    -1    ;<<<<<<<<<<<<<<<<<<<<
dc.b    “4”    ;keypad
dc.b    “5”    ;keypad
dc.b	“6”    ;keypad
dc.b    “>”
dc.b    “Z”
dc.b    “X”
dc.b    “C”
dc.b    “V”
dc.b    “B”
dc.b    “N”
dc.b    “M”
dc.b    “<”
dc.b    “>”
dc.b	“?”
dc.b    -1    ;<<<<<<<<<<<<<<<<<<
dc.b    “.”    ;keypad
dc.b    “7”    ;keypad
dc.b    “8”    ;keypad
dc.b    “9”    ;keypad
dc.b    “ ”    ;space
dc.b    -1    ;back space
dc.b    -1    ;tab
dc.b    -1	;return keypad
dc.b    -1    ;return
dc.b    -1    ;esc
dc.b    -1    ;del
dc.b    -1    ;<<<<<<<<<
dc.b    -1    ;<<<<<<<<<
dc.b    -1    ;<<<<<<<<<
dc.b    “-”
dc.b    -1    ;<<<<<<<<<
dc.b    -1    ;up
dc.b    -1    ;down
dc.b    -1    ;dx
dc.b    -1    ;sx
dc.b    -1    ;f1
dc.b    -1    ;f2
dc.b    -1    ;f3
dc.b    -1    ;f4
dc.b    -1	;f5
dc.b    -1    ;f6
dc.b    -1    ;f7
dc.b    -1    ;f8
dc.b    -1	;f9
dc.b    -1    ;f10
dc.b    “(”
dc.b    “)”
dc.b    “/”
dc.b    “*”
dc.b    “+”
dc.b    -1    ;help
dc.b -1; lshift
dc.b -1; rshift
dc.b -1; caps lock
dc.b -1; ctrl
dc.b -1; lalt
dc.b -1; ralt
dc.b -1	
;lamiga
dc.b    -1    ;ramiga

dc.b    “`”    ;alt-tati
dc.b    “¹”
dc.b    “²”
dc.b    “³”
dc.b    “¢”
dc.b    “¼”
dc.b    “½”
dc.b    “¾”
dc.b	“·”
dc.b    “«”
dc.b    “»”
dc.b    “-”
dc.b    “=”
dc.b    “\”
dc.b    -1    ;<<<<<<<<<<<<<<
dc.b    “0”    ;numeric keypad
dc.b    “å”
dc.b    “°”
dc.b “©”
dc.b “®”
dc.b “þ”
dc.b “¤”
dc.b “µ”
dc.b “¡”
dc.b “ø”
dc.b “¶”
dc.b “[”
dc.b “]”
dc.b -1	;<<<<<<<<<<<<<<<<<
dc.b    “1”    ;keypad
dc.b    “2”    ;keypad
dc.b    “3”    ;keypad
dc.b    “æ”
dc.b    “ß”
dc.b    “ð”
dc.b    “”
dc.b    “”
dc.b    “”
dc.b	“”
dc.b    “”
dc.b    “£”
dc.b    “;”
dc.b 39
dc.b    “ù”    ;not used
dc.b    -1    ;<<<<<<<<<<<<<<<<<<<<
dc.b    “4”    ;keypad
dc.b    “5”    ;keypad
dc.b    “6”	;keypad
dc.b    “<”
dc.b    “±”
dc.b    “×”
dc.b    “ç”
dc.b    “ª”
dc.b    “º”
dc.b    “­”
dc.b    “¸”
dc.b    “,”
dc.b    “.”
dc.b    “/”
dc.b    -1	;<<<<<<<<<<<<<<<<<<
dc.b    “.”    ;keypad
dc.b    “7”    ;keypad
dc.b    “8”    ;keypad
dc.b    “9”    ;keypad
dc.b    “ ”    ;space
dc.b	-1    ;back space
dc.b    -1    ;tab
dc.b    -1    ;return    keypad
dc.b    -1    ;return
dc.b    “›”    ;esc
dc.b    -1    ;del
dc.b    -1    ;<<<<<<<<<
dc.b    -1    ;<<<<<<<<<
dc.b    -1	;<<<<<<<<<
dc.b    “-”
dc.b    -1    ;<<<<<<<<<
dc.b    -1    ;up
dc.b    -1    ;down
dc.b    -1    ;dx
dc.b    -1    ;sx
dc.b    -1    ;f1
dc.b    -1    ;f2
dc.b    -1	;f3
dc.b    -1    ;f4
dc.b    -1    ;f5
dc.b    -1    ;f6
dc.b    -1    ;f7
dc.b    -1    ;f8
dc.b    -1    ;f9
dc.b    -1    ;f10
dc.b    “[”
dc.b    “]”
dc.b    “/”
dc.b    “*”
dc.b    “+”
dc.b    -1    ;help
dc.b    -1    ;lshift
dc.b    -1    ;rshift
dc.b    -1    ;caps lock
dc.b    -1    ;ctrl
dc.b	-1    ;lalt
dc.b    -1    ;ralt
dc.b    -1    ;lamiga
dc.b    -1    ;ramiga

even

;    The 8x8 character FONT.

FONT:
incbin    ‘assembler2:sorgenti4/nice.fnt’

*****************************************************************************
;	Routine di replay del protracker/soundtracker/noisetracker
;
include	‘assembler2:sorgenti4/music.s’
*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8e,$2c81    ; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$003c    ; DdfStart HIRES
dc.w    $94,$00d4    ; DdfStop HIRES
dc.w    $102,0        ; BplCon1
dc.w    $104,0		; BplCon2
dc.w    $108,0        ; Bpl1Mod \ INTERLACE: module = line length!
dc.w    $10a,0        ; Bpl2Mod / to skip them (even or odd)

; 5432109876543210
dc.w    $100,%1001001000000000    ; 1 bitplane, HIRES 640x256

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $180,$226    ; colour0 - BACKGROUND
dc.w    $182,$0c0    ; colour1 - plane 1 normal position, this is
; the part that ‘protrudes’ at the top.

dc.w    $FFFF,$FFFE    ; End of copperlist

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l	mt_data1

mt_data1:
incbin	‘assembler2:sorgenti4/mod.fairlight’

;********************************************************************
;	Il bitplane
;********************************************************************
section	bitplane,bss_C

BITPLANE:
ds.b	80*320

end

You could create a utility, or a program that requires you to enter
the name or other data, or one that responds to you as if it were a
person... it's up to you!


; Lesson 8r.s        Processor and chipset recognition routines
; (AGA or normal).
; (But what does Sysinfo do for us?!)

SECTION    SysInfo,CODE

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001110000000	; only copper and bitplane DMA

START:

;    Point the bitplanes in copperlist

MOVE.L    #BITPLANE,d0    ; put the bitplane address in d0
LEA    BPLPOINTERS,A1    ; pointers in COPPERLIST
move.w    d0,6(a1)	; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address

; NOTE THE -80!!!! (to cause the ‘depth’ effect

MOVE.L    #BITPLANE-80,d0    ; in d0 we put the address of the bitplane -80
; i.e. a line BELOW! *******
LEA    BPLPOINTERS2,A1    ; pointers in the COPPERLIST
move.w    d0,6(a1)	; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address

bsr.s    CpuDetect    ; Check which CPU is present, and change
; the text appropriately if it is not a 68000
; base.
bsr.w    FpuDetect    ; Check if a floating point coprocessor
; (Floating
; Point Unit) is present.
bsr.w    AgaDetect    ; Check if the AGA chipset is present.

MOVE.W    #DMASET,$96(a5)        ; DMACON - enables bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA


mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10800,d2    ; line to wait for = $108
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $108
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $108
Beq.S	Waity2

bsr.w    PrintCharacter    ; Print one character at a time

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

rts

;*****************************************************************************
;            PROCESSOR DETECTION ROUTINE
;
; Both this routine and the one that checks for the presence of the FPU use a
; special byte of the operating system, which is located $129 bytes after the
; value found in $4, i.e. execBase+$129.
;
;	AttnFlags (i.e. byte $129(a6), where a6 is execBase)
;
; bit    CPU or FPU
;
;    0    68010 (or 68020/30/40)
;    1    68020 (or 68030/40)
;    2    68030 (or 68040)            [V37+]
;    3    68040                 [V37+]
;    4    68881 FPU fitted (or 68882)
;    5    68882 FPU fitted        [V37+]
;	6    68040 FPU fitted        [V37+]
;
;*****************************************************************************

;     /\ ___. /\
;     / \ ______ __ / |_________ / \NoS!
;     / \ \_ \/ \ / | / / \_ ___ _/\__
;	 // \ / \ /_____| ____/___./ \ _ _ _ ø¶ /
;     // \/ \ / \/ | \__ | \\ /_)(_\
;     / \ \/ \ | 7 | \ \/
;    /____________\____/_____/\______j___________j__________\

CpuDetect:
LEA    CpuType(PC),A1
move.l    4.w,a6        ; ExecBase in a6

; note: the 68030/40 is not recognised by kickstart 1.3 or lower, but
; it is assumed that anyone with a 68020+ also has kickstart 2.0 or higher!

btst.b    #3,$129(a6)    ; Attnflags - a 68040?
BNE.S    M68040
btst.b    #2,$129(a6);d0    ; Attnflags - a 68030?
BNE.S	M68030
btst.b    #1,$129(a6);d0    ; Attnflags - a 68020?
BNE.S    M68020
btst.b    #0,$129(a6);d0    ; Attnflags - a 68010?
BNE.S    M68010
M68000:
BRA.S    PROCDONE    ; a 68000! leave the “68000” text

M68010:
MOVE.W    #“10”,(a1)    ; change “68000” to “68010”
BRA.S    PROCDONE

M68020:
MOVE.W    #“20”,(a1)    ; change “68000” to “68020”
BRA.S    PROCDONE

M68030:
MOVE.W    #“30”,(a1)    ; change “68000” to “68030”
BRA.S	PROCDONE

M68040:
MOVE.W	#“40”,(a1)	; cambia “68000” in “68040”


PROCDONE:
rts

;*****************************************************************************
;            COPROCESSOR DETECTION ROUTINE
;*****************************************************************************

; Now check if a math coprocessor (FPU) is present

FPUDetect:
LEA	FpuType(PC),a1    ; coprocessor (FPU) text string
move.l    4.w,a6        ; Execbase (To access the AttnFlags byte)
btst.b    #3,$129(a6)    ; if it is a 68040, the coprocessor is included!
BNE.S    FpuPresent
btst.b    #4,$129(a6);d0    ; 68881? -> FPU detected!
BNE.S    FpuPresent
btst.b    #5,$129(a6);d0    ; 68882? -> FPU detected!
BNE.S    FpuPresent
BRA.S    FpuNotPresent    ; NO FPU! Oh well...

FpuPresent:
MOVE.L    #“FOUN”,(A1)+    ; If present, write FOUND!
MOVE.B    #“D”,(A1)+
FpuNotPresent:
rts

;*****************************************************************************
;     AGA CHIPSET DETECTION ROUTINE (never fails!)
;*****************************************************************************

AgaDetect:
LEA    $DFF000,A5
MOVE.W    $7C(A5),D0    ; DeniseID (or LisaID AGA)
MOVEQ    #100,D7        ; Check 100 times (for safety, given
; that the old Denise gives random values)
DENLOOP:
MOVE.W	$7C(A5),D1    ; Denise ID (or LisaID AGA)
CMP.B    d0,d1        ; Same value?
BNE.S    NOTAGA        ; Not the same value: Denise OCS!
DBRA    D7,DENLOOP
BTST.L    #2,d0        ; BIT 2 reset=AGA. Is AGA present?
BNE.S    NOTAGA        ; No?
LEA    Chipset(PC),A1    ; YES!
MOVE.L    #“AGA ”,(A1)+    ; Put AGA in place of NORMAL...
MOVE.W    #“ ”,(A1)+
LEA    Message(PC),A1 ; And congratulate them on the presence of AGA
MOVE.L    #“Great”,(A1)+
MOVE.L    #“de! ”,(A1)+
MOVE.L    #“One ”,(A1)+
MOVE.L    #“macc”,(A1)+
MOVE.L    #“hina”,(A1)+
MOVE.L    #“ AGA”,(A1)+
MOVE.L    #“!!! ”,(A1)+
MOVE.L    #“ ”,(A1)+
MOVE.L    #“ ”,(A1)+
MOVE.L    #“ ”,(A1)
NOTAGA:                ; not AGA... OCS/ECS... well...
rts            ; Then leave a message telling them to buy it!

*****************************************************************************
;            Print routine
*****************************************************************************

PRINTcharacter:
MOVE.L    PointTEXT(PC),A0 ; Address of text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B	(A0)+,D2    ; Next character in d2
CMP.B    #$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s    NotEndLine    ; If not, do not go to the next line

ADD.L    #80*7,PuntaBITPLANE    ; GO TO THE NEXT LINE
ADDQ.L    #1,PuntaTesto        ; first character of the line after
; (skip ZERO)
move.b    (a0)+,d2        ; first character of the line after
; (skip ZERO)

NonFineRiga:
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20) into $00, that
; OF THE ASTERISK ($21) into $01...
LSL.W    #3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; as the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B	(A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,80(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,80*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,80*3(A3)	; print LINE 4 ‘ ’
MOVE.B    (A2)+,80*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,80*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,80*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,80*7(A3)    ; print LINE 8 ‘ ’

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
RTS


PuntaTesto:
dc.l    TEXT

PuntaBitplane:
dc.l    BITPLANE

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
; 1234567890123456789012345678901234567890
dc.b    “ Loading Randy Operating System 1.02,” ; 1
dc.b    “ please wait... ”,0 ; 1b
;
dc.b    “ ” ; 2
dc.b    “ ”,0 ; 2b
;
dc.b    ' Testing HARWARE... “ ; 3
dc.b    ” ',0 ; 3b
;
dc.b    “ Testing KickStart... ” ; 4
dc.b    “ ”,0 ; 4b
;
dc.b    “ Done. ” ; 5
dc.b    “ ”,0 ; 5b
;
dc.b    “ ” ; 6
dc.b    “ ”,0 ; 6b
;
dc.b    “ PROCESSOR (CPU): 680”
CpuType:
dc.b    “00 ” ; 7
dc.b    “ ”,0 ; 7b
;
dc.b    “ MATH COPROCESSOR: ”
FpuType:
dc.b	“NONE ” ; 8
dc.b    “ ”,0 ; 8b
;
dc.b    “ GRAPHIC CHIPSET: ”
Chipset:
dc.b    “NORMAL ” ; 9
dc.b    “ ”,0 ; 9b
;
dc.b    “ ” ; 10
dc.b    “ ”,0 ; 10b
;
dc.b    “ ”
Message:
dc.b    “Buy an AGA machine! ” ; 11
dc.b    “ ”,$FF ; 11b
;

EVEN


;    The 8x8 character FONT is copied to CHIP by the CPU and not by the blitter,
;    so it can also be stored in fast RAM. In fact, that would be better!

FONT:
incbin    ‘assembler2:sorgenti4/nice.fnt’

******************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8e,$2c81    ; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$003c    ; DdfStart HIRES
dc.w    $94,$00d4    ; DdfStop HIRES
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%1010001000000000    ; bit 13 - 2 bitplanes, 4 HIRES colours

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane
BPLPOINTERS2:
dc.w $e4,$0000,$e6,$0000    ;second bitplane

dc.w    $180,$103	; colour0 - BACKGROUND
dc.w    $182,$fff    ; colour1 - plane 1 normal position, this is
; the part that ‘protrudes’ at the top.
dc.w    $184,$345    ; colour2 - plane 2 (offset at the bottom)
dc.w    $186,$abc    ; colour3 - both planes - overlay

dc.w    $FFFF,$FFFE    ; End of copperlist

******************************************************************************

SECTION    MIOPLANE,BSS_C    ; The BSS SECTIONS must be made up of
; only ZEROS!!! DS.b is used to define
; how many zeros the section contains.

;    This is why ‘ds.b 80’ is needed:
;    MOVE.L    #BITPLANE-80,d0    ; in d0 we put the address of the bitplane -80
;                ; i.e. a line BELOW! *******

ds.b    80    ; the line that ‘pops up’
BITPLANE:
ds.b	80*256    ; a HIres 640x256 bitplane

end

As you can see, we change the text before it is printed, nothing amazing.
To find out which processor and chipset are in the computer, just consult
the relevant bits of the operating system and $dff07c. Anyway, it's quite impressive
to show a detection at the beginning of production!!!
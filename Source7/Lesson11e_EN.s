
; Lesson 11e.s - Using COPER and VERTB level 3 interrupts ($6c).
;         In this case, we redefine all interrupts, just
;         to give you an idea of how it's done.

Section    Interrupt,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup2.s’    ; save interrupts, dma, etc.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:
move.l    BaseVBR(PC),a0     ; In a0 the value of VBR

MOVE.L    #NOINT1,$64(A0)        ; ‘Empty’ interrupt
MOVE.L    #NOINT2,$68(A0)        ; empty int
move.l    #MioInt6c,$6c(a0)    ; set my int. level 3 routine.
MOVE.L    #NOINT4,$70(A0)        ; empty int
MOVE.L    #NOINT5,$74(A0)        ; ‘ ’
MOVE.L    #NOINT6,$78(A0)        ; ‘ ’

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)	; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)		; Disable AGA

movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_init        ; initialise the music routine
movem.l    (SP)+,d0-d7/a0-a6

; 5432109876543210
move.w    #%1111111111111111,$9a(a5) ; INTENA - enable ALL
; interrupts!

mouse:
btst    #6,$bfe001    ; Mouse pressed? (the processor executes this
bne.s    mouse        ; loop in user mode, and every vertical blank
; as well as every WAIT of the raster line $a0
; interrupts it to play the music!).

bsr.w    mt_end        ; end of replay!

rts            ; exit


*****************************************************************************
*    INTERRUPT ROUTINE $64 (level 1)
*****************************************************************************

;    .:·.·...·..
;     ·::::::::::.
;     ·::::::::::
;     ( _____·:::
;     \____` ::|
;     _(° _) ·l
;     / ¯¯¯ .)
;     / ¯T
;    / ,_ ___ _j
;    ¯¯¬ l____\ \
;     ¬\\ \ xCz
;    __________) \
;    \_ _____ \
;     `------' \___)

;02    SOFT    1 ($64)    Reserved for interrupts initialised via software.
;01    DSKBLK    1 ($64)    End of transfer of a data block from the disk.
;00    TBE    1 ($64)    Serial port UART transmission buffer EMPTY.

NOINT1:    ; $64
btst.b    #0,$dff01f    ; INTREQR - TBE?
beq.w    NoTBE
; tbe routines
NoTBE:
btst.b    #1,$dff01f    ; INTREQR - DSKBLK?
beq.w    NoDSKBLK
; DSKBLK routines
NoDSKBLK:
btst.b    #2,$dff01f    ; INTREQR - SOFT?
beq.w    NoSOFT
; SOFT routines
NoSOFT:
; 210
move.w    #%111,$dff09c    ; INTREQ - soft,dskblk,serial port tbe
rte

*****************************************************************************
*	ROUTINE IN INTERRUPT $68 (livello 2)
*****************************************************************************

;	 .:::::::::.
;     ¦:· ·:¦
;     |' `|
;     | , |
;     | ¯¯ `-- |
;     _! __ __ |
;     (C \ ( °)(o ) |
;     7 /\ ¯(__)¯ _!
;     / / \______/\\
;    / \_______l__//
;	\ \:::::::::\\ xCz
;     \ \:::::::::\\
;     \___¯¯¯¯¯¯¯¯¯¯/
;     `---------'

;03    PORTS    2 ($68)    Input/Output Ports and timers, connected to the INT2 line

NOINT2:    ; $68
btst.b    #3,$dff01f    ; INTREQR - PORTS?
beq.w    NoPORTS
; PORTS routines
NoPORTS:
move.l    d0,-(sp)    ; save d0
move.b    $bfed01,d0    ; CIAA icr - is it a keyboard interrupt?
and.b    #$8,d0
beq.w    NoKeyboard
; Routines for reading the keyboard
NoKeyboard:
move.l    (sp)+,d0    ; restore d0
; 3210
move.w    #%1000,$dff09c    ; INTREQ - ports
rte

*****************************************************************************
*    INTERRUPT ROUTINE $6c (level 3) - uses VERTB and COPER.     *
*****************************************************************************
;     __________________
;     __/ _______________/
;    ( . ¬(___©)\©_T
;     \_, \ |
;     T C. )|
;     l____________ _ |
;     T l__¬_!
;     | (_) T`-“
;     l__ ¦ xCz
;     `-----”

;06    BLIT    3 ($6c)	If the blitter has finished a blit, it is set to 1
;05    VERTB    3 ($6c)    Generated every time the electronic brush is
;            at line 00, i.e. at the beginning of each vertical blank.
;04    COPER    3 ($6c)    Can be set with copper to generate it at a certain
;            video line. Just request it after a certain WAIT.

MioInt6c:
btst.b    #6,$dff01f    ; INTREQR - BLIT?
beq.w    NoBLIT
; BLIT routines
NoBLIT:
btst.b    #5,$dff01f	; INTREQR - is bit 5, VERTB, reset?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play the music
movem.l	(SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
nointVERTB:
btst.b    #4,$dff01f    ; INTREQR - COPER reset?
beq.s    NointCOPER    ; if so, it is not an int COPER!
move.w    #$F00,$dff180    ; int COPER, then COLOR0 = RED
NointCOPER:
;6543210
move.w    #%1110000,$dff09c ; INTREQ - clear BLIT,VERTB and COPER
rte    ; exit from COPER/BLIT/VERTB

*****************************************************************************
*	INTERRUPT ROUTINE $70 (level 4)
*****************************************************************************

;     _/\__/\_
;     _/ '_ _`¬\_
;     (/ (¤)(¤) \)
;     / _ ¯··¯ _ \
;    / ¯Y¯¯Y¯ \
;    \____ “ ` ____/
;     `--------” xCz

;10    AUD3    4 ($70)    Reading of a block of data from audio channel 3 finished.
;09    AUD2    4 ($70)    Reading of a block of data from audio channel 2 finished.
;08    AUD1    4 ($70)    Reading of a block of data from audio channel 1 finished.
;07    AUD0    4 ($70)    Reading of a block of data from audio channel 0 finished.

NOINT4: ; $70
BTST.b    #7,$dff01f    ; INTREQR - AUD0?
BEQ.W    NoAUD0
; aud0 routines
NoAUD0:
BTST.b    #8-7,$dff01e    ; INTREQR - AUD1? note: $dff01e and not $dff01f
;          because the bit is >7!
BEQ.W	NoAUD1
; aud1 routines
NoAUD1:
BTST.b    #9-7,$dff01e    ; INTREQR - AUD2?
Beq.W    NoAUD2
; aud2 routines
NoAUD2:
BTST.b    #10-7,$dff01e    ; INTREQR - AUD3?
Beq.W	NoAUD3
; routines aud3
NoAUD3:
; 09876543210
MOVE.W	#%11110000000,$DFF09C	; aud0,aud1,aud2,aud3
RTE

*****************************************************************************
*    ROUTINE IN INTERRUPT $74 (level 5)
*****************************************************************************

;     .:::::.
;     ¦:·_ _!
;     ! (°T°)
;    ( , ¯,\\
;     \`---¯/
;     `---' xCz

;12    DSKSYN    5 ($74)    Generated if the DSKSYNC register matches the data
;            read from the disk in the drive. Used for hardware loaders.
;11    RBF    5 ($74)    UART receive buffer for the serial port FULL.


NOINT5: ; $74
BTST.b    #12-7,$dff01e    ; INTREQR - DSKSYN?
BEQ.W    NoDSKSYN
; dsksyn routines
NoDSKSYN:
BTST.b    #11-7,$dff01e    ; INTREQR - RBF?
BEQ.W    NoRBF
; rbf routines
NoRBF:
; 2109876543210
MOVE.W    #%1100000000000,$DFF09C    ; serial port rbf, dsksyn
rte

*****************************************************************************
*    ROUTINE IN INTERRUPT $78 (level 6)                 *
*****************************************************************************

;     ......
;    ¡·¸ ,·:¦
;    | °u°. )
;    l_`--'_!
;     `----'xCz

;14    INTEN    6 ($78)
;13    EXTER    6 ($78)    External interrupt, connected to INT6 + TOD CIAB line

NOINT6: ; $78
tst.b    $bfdd00        ; CIAB icr - reset interrupt timer
BTST.b    #14-7,$dff01e	; INTREQR - INTEN?
BEQ.W    NoINTEN
; inten routines
NoINTEN:
BTST.b    #13-7,$dff01e    ; INTREQR - EXTER?
BEQ.W    NoEXTER
; exter routines
NoEXTER:
; 432109876543210
MOVE.W    #%110000000000000,$DFF09C ; INTREQ - external int + ciab
rte

*****************************************************************************
;    Protracker/soundtracker/noisetracker replay routine
;
include	‘assembler2:sorgenti4/music.s’
*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$100,$200	; BPLCON0 - no bitplanes
dc.w    $180,$00e    ; colour0 BLUE
dc.w    $a007,$fffe    ; WAIT - wait for line $a0
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt, which
; acts on colour0 with a ‘MOVE.W’.
dc.w	$FFFF,$FFFE	; Fine della copperlist

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l    mt_data1

mt_data1:
incbin    ‘assembler2:sorgenti4/mod.fairlight’

end

We have redefined all interrupts. This can be a starting point
for creating an ‘operating system’, but I do not recommend it!

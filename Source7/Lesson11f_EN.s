
; Lesson 11f.s - Using COPER and VERTB level 3 interrupts ($6c).
;         In this case, we redefine all interrupts, just
;         to give you an idea of how it's done.
;         The difference with Lesson 11e.s is ‘formal’; in fact,
;		 the Amiga ROM standard for interrupts. If you want to
;         follow the label exactly, do as in this example.

Section    Interrupt,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup2.s’    ; save interrupts, DMA, etc.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %100000101000000    ; copper DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:
move.l    BaseVBR(PC),a0     ; In a0 the value of VBR

MOVE.L	#NOINT1,$64(A0)        ; ‘Empty’ interrupt
MOVE.L    #NOINT2,$68(A0)        ; Empty int
move.l    #MioInt6c,$6c(a0)    ; Set my level 3 int routine.
MOVE.L    #NOINT4,$70(A0)		; empty int
MOVE.L    #NOINT5,$74(A0)        ; ‘ ’
MOVE.L    #NOINT6,$78(A0)        ; ‘ ’

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l	#COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

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

;    .-==-.
;    | __ |
;    C °° )
;    | C. |
;    | __ |
;    |(__)|xCz
;    `----'

;02    SOFT    1 ($64)    Reserved for interrupts initialised via software.
;01    DSKBLK	1 ($64)    End of transfer of a data block from the disk.
;00    TBE    1 ($64)    Serial port transmission UART buffer EMPTY.

NOINT1:    ; $64
movem.l    d0-d7/a0-a6,-(SP)
LEA    $DFF000,A0
MOVE.W    $1C(A0),D1
BTST.l    #14,D1        ; Master enable bit reset?
BEQ.s    NoInts1        ; If yes, interrupts not active!
AND.W    $1E(A0),D1    ; INREQR - only the bits that are set in both INTENA and INTREQ remain set in d1
; in order to ensure that the interrupt
that occurred was enabled.
btst.l    #0,d1        ; TBE?
beq.w    NoTBE
; tbe routines
NoTBE:
btst.l    #1,d1        ; DSKBLK?
beq.w    NoDSKBLK
; DSKBLK routines
NoDSKBLK:
btst.l    #2,d1        ; INTREQR - SOFT?
beq.w    NoSOFT
; SOFT routines
NoSOFT:
NoInts1:    ; 210
move.w    #%111,$dff09c    ; INTREQ - soft,dskblk,serial port tbe
movem.l    (SP)+,d0-d7/a0-a6
rte

*****************************************************************************
*    ROUTINE IN INTERRUPT $68 (level 2)
*****************************************************************************

;     ... 
;     : ·:
;     : :
;     ____¦,.,l____
;     /·.·.· .·.·.\
;     _/ _____ _____ \_
;     C/_ (° C °) \).
;     \ \_____________/ /-“
;     \ \___l_____/ /xCz
;     ____ \__`-------'__/ _____
;     / ¯¯ `---------” ¯¯ ¬\
;     / ·
;    ·

;03 PORTS 2 ($68) Input/Output Ports and timers, connected to the INT2 line

NOINT2: ; $68
movem.l d0-d7/a0-a6,-(SP)
LEA $DFF000,A0 ; custom in A0
MOVE.W    $1C(A0),D1    ; INTENAR in d1
BTST.l    #14,D1        ; Master enable bit reset?
BEQ.s    NoInts2        ; If yes, interrupts not active!
AND.W    $1E(A0),D1    ; INREQR - only the bits that are set in both INTENA and INTREQ remain set in d1
; this is to ensure that the interrupt
; was enabled.
; that occurred was enabled.

btst.l    #3,d1        ; INTREQR - PORTS?
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
NoInts2:    ; 3210
move.w    #%1000,$dff09c    ; INTREQ - ports
movem.l	(SP)+,d0-d7/a0-a6
rte

*****************************************************************************
*    INTERRUPT ROUTINE $6c (level 3) - uses VERTB and COPER.     *
*****************************************************************************

;     _.--._ _
;    | _ .| (_)
;    | \__| ||
;    |______| ||
;    .-`--'-. ||
;    | | | |\__l|
;    |_| |__|__|_))
;     ||_| | ||
;     |(_) |
;     | |
;     |____|__
;     |______/g®m


;06    BLIT    3 ($6c)    If the blitter has finished a blit, set to 1
;05    VERTB    3 ($6c)    Generated every time the electronic brush is
;            at line 00, i.e. at the beginning of each vertical blank.
;04    COPER    3 ($6c)    Can be set with copper to generate it at a certain
;            video line. Just request it after a certain WAIT.

MioInt6c:
movem.l    d0-d7/a0-a6,-(SP)
LEA    $DFF000,A0    ; custom in A0
MOVE.W    $1C(A0),D1    ; INTENAR in d1
BTST.l    #14,D1        ; Master enable bit reset?
BEQ.s    NoInts3        ; If yes, interrupts are not active!
AND.W    $1E(A0),D1    ; INREQR - only the bits that are set in both INTENA and INTREQ remain set in d1
; this is to ensure that the interrupt
that occurred was enabled.
; beq.w ; routines BLIT NoBLIT: btst.l    #5,d1
; INTREQR - bit 5, VERTB,		
; INTREQR - BLIT?
beq.w    NoBLIT
; BLIT routines
NoBLIT:
btst.l    #5,d1        ; INTREQR - is bit 5, VERTB, reset?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play the music
movem.l    (SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
nointVERTB:
btst.l    #4,d1		; INTREQR - COPER reset?
beq.s    NointCOPER    ; if yes, it's not a COPER int!
move.w    #$F00,$dff180    ; COPER int, then COLOR0 = RED
NointCOPER:
NoInts3:     ;6543210
move.w    #%1110000,$dff09c ; INTREQ - clear BLIT,VERTB,COPER request
movem.l    (SP)+,d0-d7/a0-a6
rte    ; exit from COPER/BLIT int

*****************************************************************************
*    INTERRUPT ROUTINE $70 (level 4)
*****************************************************************************

;     .:::::.
;     ¦:::·:::¦
;     |· ·|
;    C| ¬ - l)
;     ¡_°(_)°_|
;     |\_____/|
;     l__`-'__!
;     `---'xCz

;10    AUD3    4 ($70)    Reading of a block of data from audio channel 3 finished.
;09    AUD2    4 ($70)    Reading of a block of data from audio channel 2 finished.
;08    AUD1    4 ($70)    Reading of a block of data from audio channel 1 finished.
;07    AUD0    4 ($70)    Reading of a block of data from audio channel 0 finished.

NOINT4: ; $70
movem.l    d0-d7/a0-a6,-(SP)
LEA    $DFF000,A0    ; custom in A0
MOVE.W    $1C(A0),D1    ; INTENAR in d1
BTST.l    #14,D1        ; Master enable bit reset?
BEQ.s    NoInts4        ; If yes, interrupts not active!
AND.W    $1E(A0),D1    ; INREQR - only the bits that are set in both INTENA and INTREQ remain set in d1
; in order to ensure that the interrupt
; that occurred was enabled.
; routines aud0
BTST.l    #7,d1        ; INTREQR - AUD0?
BEQ.W    NoAUD0
; aud0 routines
NoAUD0:
BTST.l    #8,d1        ; INTREQR - AUD1?
BEQ.W    NoAUD1
; aud1 routines
NoAUD1:
BTST.l    #9,d1        ; INTREQR - AUD2?
Beq.W    NoAUD2
; aud2 routines
NoAUD2:
BTST.l    #10,d1        ; INTREQR - AUD3?
Beq.W    NoAUD3
; aud3 routines
NoAUD3:
NoInts4:	; 09876543210
MOVE.W	#%11110000000,$DFF09C	; aud0,aud1,aud2,aud3
movem.l	(SP)+,d0-d7/a0-a6
RTE

*****************************************************************************
*    ROUTINE IN INTERRUPT $74 (level 5)
*****************************************************************************

;     .:::::.
;     ¦:::·:::¦
;     |· - - ·|
;    C| q p l)
;     | (_) |
;     |\_____/|
;     l__ ¬__!
;     `---'xCz

;12    DSKSYN    5 ($74)    Generated if the DSKSYNC register matches the data
;            read from the disk in the drive. Used for hardware loaders.
;11    RBF    5 ($74)    UART receive buffer of the serial port FULL.


NOINT5: ; $74
movem.l    d0-d7/a0-a6,-(SP)
LEA    $DFF000,A0    ; custom in A0
MOVE.W    $1C(A0),D1    ; INTENAR in d1
BTST.l    #14,D1        ; Master enable bit reset?
BEQ.s    NoInts5        ; If yes, interrupts not active!
AND.W    $1E(A0),D1    ; INREQR - only the bits that are set in both INTENA and INTREQ remain set in d1
; this is to ensure that the interrupt
that occurred was enabled.
; BTST.l    #12,d1
BTST.l    #12,d1        ; INTREQR - DSKSYN?
BEQ.W    NoDSKSYN
; dsksyn routines
NoDSKSYN:
BTST.l    #11,d1        ; INTREQR - RBF?
BEQ.W    NoRBF
; rbf routines
NoRBF:
NoInts5:    ; 2109876543210
MOVE.W    #%1100000000000,$DFF09C    ; serial port rbf, dsksyn
movem.l    (SP)+,d0-d7/a0-a6
rte

*****************************************************************************
*    ROUTINE IN INTERRUPT $78 (level 6)                 *
*****************************************************************************

;     .:::::.
;     ¦:::·:::¦
;     |· - - ·|
;    C| O p l)
;    / _ (_) _ \
;    \_\_____/_/
;     l_\___/_!
;     `-----'xCz

;14    INTEN    6 ($78)
;13    EXTER    6 ($78)    External interrupt, connected to the INT6 + TOD CIAB line

NOINT6: ; $78
movem.l    d0-d7/a0-a6,-(SP)
tst.b    $bfdd00        ; CIAB icr - reset interrupt timer
LEA    $DFF000,A0    ; custom in A0
MOVE.W    $1C(A0),D1    ; INTENAR in d1
BTST.l    #14,D1        ; Master enable bit reset?
BEQ.s    NoInts6        ; If yes, interrupts not active!
AND.W    $1E(A0),D1    ; INREQR - only the bits that are set in both INTENA and INTREQ remain set in d1
; to ensure that the interrupt that occurred was enabled.
; to ensure that the interrupt
; that occurred was enabled.
BTST.l    #14,d1        ; INTREQR - INTEN?
BEQ.W    NoINTEN
; inten routines
NoINTEN:
BTST.l    #13,d1        ; INTREQR - EXTER?
BEQ.W    NoEXTER
; exter routines
NoEXTER:
NoInts6:    ; 432109876543210
MOVE.W    #%110000000000000,$DFF09C ; INTREQ - external int + ciab
movem.l    (SP)+,d0-d7/a0-a6
rte

*****************************************************************************
;	Routine di replay del protracker/soundtracker/noisetracker
;
include	‘assembler2:sorgenti4/music.s’
*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - no bitplanes
dc.w    $180,$00e    ; colour0 BLUE
dc.w	$a007,$fffe    ; WAIT - wait for line $a0
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt,
; which acts on colour0 with a ‘MOVE.W’.
dc.w    $FFFF,$FFFE    ; End of copperlist

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l	mt_data1

mt_data1:
incbin	‘assembler2:sorgenti4/mod.yellowcandy’

end

As you can see, this ‘version’ uses all the tricks
used by the operating system interrupts:

LEA    $DFF000,A0    ; custom in A0
MOVE.W    $1C(A0),D1    ; INTENAR in d1
BTST.l    #14,D1		; Master enable bit reset?
BEQ.s    NoInts1        ; If yes, interrupt not active!
AND.W    $1E(A0),D1    ; INREQR - only the bits that are set in both INTENA and INTREQ remain set in d1
; in order to ensure that the interrupt
; that occurred was enabled.
btst.l    #0,d1
btst.l    #0,d1        ; TBE?
...

In practice, a further check is made on the validity of the interrupt,
checking whether the bit set in INTREQR is also set in INTENAR, i.e.
whether it is enabled. In reality, if an interrupt is disabled with the
appropriate register, i.e. INTENA ($dff09a), it should not continue to work.
However, it may be that the hardware is not perfect. If you find any strange
incompatibilities in your interrupt, do this check as well, who knows
if ‘disabled’ interrupts are being executed!

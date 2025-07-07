
; Lesson 11m1.s - Using the level 2 interrupt ($68) to read the
;         codes of the keys pressed on the keyboard.
;         PRESS SPACE TO EXIT

Section    InterruptKey,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup2.s’    ; save interrupt, dma, etc.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %100000101000000    ; copper DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:
move.l    BaseVBR(PC),a0     ; In a0 the value of VBR

MOVE.L	#MioInt68KeyB,$68(A0)    ; Routine for int. keyboard level 2
move.l    #MioInt6c,$6c(a0)    ; I put my int. routine level 3

; 76543210
move.b    #%01111111,$bfed01	; CIAAICR - Disable all IRQ CIAs
move.b    #%10001000,$bfed01    ; CIAAICR - Enable only the SP IRQ CIA

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_init        ; Initialise the music routine
movem.l    (SP)+,d0-d7/a0-a6

; 5432109876543210
move.w    #%1100000000101000,$9a(a5) ; INTENA - enable only VERTB
; of level 3 and level 2

WaitSpace:
move.b    ActualKey(PC),d0 ; Get the code of the last key pressed.
move.b    d0,Color0+1    ; Set the code of the current character as
; color0... just for testing..
cmp.b    #$40,d0        ; SPACE BAR PRESSED? (enough with the mouse!)
bne.s    WaitSpace

bsr.w    mt_end         ; end of replay!
move.b    #%10011111,$bfed01 ; CIAAICR - Re-enable all CIA IRQs
rts             ; exit

; Variable where the current character is saved

ActualKey:
dc.b    0

even

*****************************************************************************
*    ROUTINE IN INTERRUPT $68 (level 2) - KEYBOARD management
*****************************************************************************

;03    PORTS    2 ($68)    Input/Output Ports and timers, connected to the INT2 line

MioInt68KeyB:    ; $68
movem.l d0/a0,-(sp)	; save the registers used in the stack
lea    $dff000,a0    ; custom reg. for offset

MOVE.B    $BFED01,D0    ; Ciaa icr - in d0 (reading the icr also causes
; it to be reset, so the int is
; ‘cancelled’ as in intreq).
BTST.l    #7,D0    ; IR bit (interrupt cia authorised), reset?
BEQ.s    NonKey    ; if yes, exit
BTST.l    #3,D0    ; SP bit (keyboard interrupt), reset?
BEQ.s    NonKey    ; if yes, exit

MOVE.W    $1C(A0),D0    ; INTENAR in d0
BTST.l    #14,D0        ; Master enable bit reset?
BEQ.s    NonKey        ; If yes, interrupt not active!
AND.W    $1E(A0),D0    ; INREQR - only the bits
; that are set in both INTENA and INTREQ
; remain set in d1, so as to ensure that the interrupt
; that occurred was enabled.
btst.l    #3,d0        ; INTREQR - PORTS?
beq.w    NonKey        ; If not, then exit!

; After the checks, if we are here, it means we have to take the character!

moveq    #0,d0
move.b    $bfec01,d0    ; CIAA sdr (serial data register - connected
; to the keyboard - contains the byte sent by
; the keyboard chip) READ THE CHAR!

; we have the char in d0, let's “work” on it...

NOT.B    D0        ; adjust the value by inverting the bits
ROR.B    #1,D0        ; and returning the sequence to 76543210.
move.b    d0,ActualKey    ; save the character

; Now we have to tell the keyboard that we have taken the data!

bset.b    #6,$bfee01    ; CIAA cra - sp ($bfec01) output, in order to
; lower the KDAT line to confirm that
; we have received the character.

st.b    $bfec01        ; $FF in $bfec01 - ue'! I received the data!

; Here we need to put a routine that waits 90 microseconds because the
; KDAT line must remain low long enough to be ‘understood’ by all
; types of keyboards. For example, you can wait for 3 or 4 raster lines.

moveq    #4-1,d0    ; Number of lines to wait for = 4 (in practice 3 plus
; the fraction we are in at the start)
waitlines:
move.b    6(a0),d1    ; $dff006 - current vertical line in d1
stepline:
cmp.b    6(a0),d1    ; are we still on the same line?
beq.s    stepline    ; if waiting
dbra    d0,waitlines    ; ‘expected’ line, wait d0-1 lines

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
;05    VERTB    3 ($6c)    Generated every time the electronic brush is
;            at line 00, i.e. at the beginning of each vertical blank.
;04    COPER    3 ($6c)    Can be set with copper to generate it at a certain
;            video line. Just request it after a certain WAIT.

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, reset?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play the music
movem.l    (SP)+,d0-d7/a0-a6	; retrieve the registers from the stack
nointVERTB:
NointCOPER:
NoBLIT:         ;6543210
move.w    #%1110000,$dff09c ; INTREQ - clear BLIT,VERTB and COPER requests
rte    ; exit COPER/BLIT/VERTB interrupt

*****************************************************************************
;	Routine di replay del protracker/soundtracker/noisetracker
;
include	‘assembler2:sorgenti4/music.s’
*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - no bitplanes
dc.w    $180
Color0:
dc.w    $000        ; color0 - will be changed depending on the key
dc.w    $FFFF,$FFFE    ; End of copperlist

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l	mt_data1

mt_data1:
incbin	‘assembler2:sorgenti4/mod.fairlight’

end

By entering the keyboard code byte in colour0, you can clearly see that
when a key is PRESSED, bit 7 is reset, while when it is
RELEASED, this bit is set: in fact, when you press a key, the colour
is darker than when you release it, as the high bit of green is reset.

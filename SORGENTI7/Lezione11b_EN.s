
; Lesson 11b.s - First use of the new startup2.s and an interrupt.

Section    FirstInterrupt,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; salva interrupt, dma eccetera.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA enabled

WaitDisk    EQU    30    ; 50-150 to save (depending on the case)

START:
move.l    BaseVBR(PC),a0     ; In a0 the value of VBR
move.l    #MioInt6c,$6c(a0)    ; I put my rout. int. level 3.

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Let's point our COP
move.w    d0,$88(a5)        ; Let's start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_init        ; initialise the music routine
movem.l    (SP)+,d0-d7/a0-a6

move.w    #$c020,$9a(a5)    ; INTENA - enable interrupt ‘VERTB’ of the
; level 3 ($6c), the one generated
; once per frame (at line $00).

mouse:
btst    #6,$bfe001    ; Mouse pressed? (the processor executes this
bne.s    mouse        ; loop in user mode, and each vertical blank
; interrupts it to play the music!).

bsr.w    mt_end        ; end of replay!

rts            ; exit

*****************************************************************************
*    INTERRUPT ROUTINE $6c (level 3) - only VERTB used.
*****************************************************************************
;     ..,..,.,
;     /~‘’~“”~‘’~\
;     /_____ ¸_____)
;     _) ¬(_° \°_)
;    ( __ (__) \
;     \ \___ _____, /
;     \__ Y ____/xCz
;     `-----'

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, reset?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)	; save the registers in the stack
bsr.w    mt_music        ; play the music
movem.l    (SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
nointVERTB:     ;6543210
move.w    #%1110000,$dff09c ; INTREQ - clear request BLIT,COPER,VERTB
; since the 680x0 does not clear it by itself!!!
rte    ; exit from int COPER/BLIT/VERTB

*****************************************************************************
;	Routine di replay del protracker/soundtracker/noisetracker
;
include	‘assembler2:sorgenti4/music.s’
*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - no bitplanes
dc.w    $180,$00e    ; colour0 BLUE
dc.w    $FFFF,$FFFE    ; End of copperlist

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l    mt_data1

mt_data1:
incbin    ‘assembler2:sorgenti4/mod.yellowcandy’

end

If we did not set the VERTB interrupt of level 3 ($6c), this listing
would end in a single loop:

mouse:
btst    #6,$bfe001    ; Mouse pressed? (the processor executes this
bne.s    mouse        ; loop in user mode, and each vertical blank
; interrupts it to play the music!).

Instead, the processor works in ‘multitasking’ mode, blocking the loop every time
the electronic brush reaches line $00, executing MT_MUSIC and returning
to execute the sterile loop.
Instead of this simple mouse wait loop, we could have put in a
fractal calculation routine, which could take several seconds,
during which the music would play ‘simultaneously’ and synchronised,
without disturbing the fractal calculation, slowing it down only as much as necessary
to play the music every frame.

Note the two EQUATE commands at the beginning of the program, one for turning on the DMAs,
which we already know, and the new one:

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

This ‘waits’ a little before taking control of the hardware.
To calculate the expected time, consider 50 as 1 second, since
Vblank is used, which goes to the ‘quarter’. So 150 is 3 seconds.
However, if your programme is a fairly large and compressed file,
it will take a second or two to decompress, so you can
leave it at a low value. If, on the other hand, you saved the file uncompressed and
ran it from a floppy disk, the execution would start before the drive light
went out, and once in five times, DOS would go
into total coma. To avoid this, always calculate that between decompression and
time lost with the ‘waitdisk’ loop, the program starts at least 3 seconds
after the end of loading.


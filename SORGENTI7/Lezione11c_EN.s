
; Lesson 11c.s - Using COPER and VERTB interrupts at level 3 ($6c).

Section    Interrupt,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; salva interrupt, dma eccetera.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:
move.l    BaseVBR(PC),a0     ; In a0 the value of VBR
move.l    #MioInt6c,$6c(a0)    ; I put my rout. int. level 3.

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_init        ; initialise the music routine
movem.l    (SP)+,d0-d7/a0-a6

move.w    #$c030,$9a(a5)    ; INTENA - enable interrupts ‘VERTB’ and ‘COPER’
; of level 3 ($6c)

mouse:
btst    #6,$bfe001    ; Mouse pressed? (the processor executes this
bne.s    mouse        ; loop in user mode, and every vertical blank
; as well as every WAIT of the raster line $a0
; interrupts it to play the music!).

bsr.w    mt_end        ; end of replay!

rts            ; exit

*****************************************************************************
*    INTERRUPT ROUTINE $6c (level 3) - uses VERTB and COPER.
*****************************************************************************

;    ,;)))(((;,
;    ¦“__ __`¦
;    |,-. ,-.l
;    ( © )( © )
;    ¡`-'_)`-”¡
;    | ___ |
;    l__ ¬ __!
;     T`----“T xCz
;     ” `

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, zeroed?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play music
movem.l    (SP)+,d0-d7/a0-a6    ; retrieve registers from stack
nointVERTB:
btst.b    #4,$dff01f    ; INTREQR - COPER reset?
beq.s    NointCOPER    ; if yes, it is not an int COPER!
move.w    #$F00,$dff180    ; int COPER, then COLOR0 = RED
NointCOPER:
;6543210
move.w    #%1110000,$dff09c ; INTREQ - BLIT and COPER request gate
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
dc.w    $a007,$fffe    ; WAIT - wait for line $a0
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt,
; which acts on colour0 with a ‘MOVE.W’.
dc.w    $FFFF,$FFFE    ; End of copperlist

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l    mt_data1

mt_data1:
incbin    ‘assembler2:sorgenti4/mod.yellowcandy’

end

This time we also used the copper interrupt, called COPER,
which is useful for performing operations on a certain video line.
From the copperlist, you can also access the INTREQ register ($dff09c),
and in this case, all we do is set bit 4, COPER, together with
bit 15 Set/Clr.
In this case, we have only put a "MOVE.W #$f00,$dff180", which is not a
great routine, but consider its usefulness if there are many things to do,
and it is not worth wasting time comparing the vertical blank with a processor loop
in user mode...

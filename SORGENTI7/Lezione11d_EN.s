
; Lesson 11d.s - Using COPER and VERTB interrupts at level 3 ($6c).

Section    Interrupt,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; salva interrupt, dma eccetera.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %100000101000000    ; copper DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:
move.l    BaseVBR(PC),a0     ; In a0 the value of VBR
move.l    #MioInt6c,$6c(a0)    ; I put my rout. int. level 3.

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
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
*    INTERRUPT ROUTINE $6c (level 3) - VERTB and COPER used.
*****************************************************************************
;     ______________
;     ¡¯ ¬\
;     | ______ _______)
;     _| /¯ © \ / ø ¬\|_
;     C,l \____/_\____/|.)
;     `-| ___ \ ___ |-'
;     | _/ , \ \_ |
;     |_ ` _ ¯--“_ ” ! xCz
;     _j \ ¯¯¯¯¯¯¬ /
;    /¯ \__ ¯¯¯ __/¯¯¯\
;     `-----'

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, reset?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play the music
movem.l	(SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
nointVERTB:
btst.b    #4,$dff01f    ; INTREQR - COPER reset?
beq.s    NointCOPER    ; if yes, it is not a COPER int!
addq.b    #1,Current
cmp.b	#6,Current
bne.s    Vabene
clr.b    Current    ; restart from zero
VaBene:
move.b    Current(PC),d0
cmp.b    #1,d0
beq.s    Col1
cmp.b    #2,d0
beq.s    Col2
cmp.b    #3,d0
beq.s	Col3
cmp.b    #4,d0
beq.s    Col4
cmp.b    #5,d0
beq.s    Col5
Col0:
move.w    #$300,$dff180    ; COLOUR0
bra.s    Coloured
Col1:
move.w    #$d00,$dff180    ; COLOUR0
bra.s    Coloured
Col2:
move.w    #$f31,$dff180    ; COLOR0
bra.s    Coloured
Col3:
move.w    #$d00,$dff180    ; COLOR0
bra.s    Coloured
Col4:
move.w    #$a00,$dff180    ; COLOR0
bra.s	Colorato
Col5:
move.w	#$500,$dff180	; COLOR0
Colorato:
NointCOPER:
;6543210
move.w	#%1110000,$dff09c ; INTREQ - clear BLIT,COPER,VERTB
; since the 680x0 does not clear it by itself!!!
rte    ; exit from int COPER/BLIT/VERTB

Current:
dc.w    0

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
dc.w    $a207,$fffe    ; WAIT - wait for line $a2
dc.w    $9c,$8010    ;
 WAIT - wait for line $a4
dc.w    $a407,$fffe    ; INTREQ - Request a COPER interrupt, which acts on colour0 with a ‘MOVE.W’.
dc.w    $9c,$8010    ;
 
WAIT - wait for line $a4
 
INTREQ - Request a COPER interrupt, which
; acts on colour0 with a ‘MOVE.W’.
dc.w    $a607,$fffe    ; WAIT - wait for line $a6
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt, which
; acts on colour0 with a ‘MOVE.W’.
dc.w    $a807,$fffe    ; WAIT - wait for line $a8
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt, which
; acts on colour0 with a ‘MOVE.W’.
dc.w    $aa07,$fffe    ; WAIT - wait for line $aa
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt, which
; acts on colour0 with a ‘MOVE.W’.

dc.w    $FFFF,$FFFE    ; End of copperlist

*****************************************************************************
;                MUSIC
*****************************************************************************

mt_data:
dc.l	mt_data1

mt_data1:
incbin	‘assembler2:sorgenti4/mod.yellowcandy’

end

In this example, we see how it is possible to call the interrupt on different
lines, and how a different routine can be executed each time, through
the use of a counter, the label ‘Current’, which keeps track of the routine
to be executed at each call. If this order is changed, removing a
routine, the routines will ‘cycle’. Try, for example, making
this change:

nointVERTB:
btst.b    #4,$dff01f    ; INTREQR - COPER reset?
beq.s    NointCOPER    ; if yes, it is not a COPER interrupt!
addq.b    #1,Current
cmp.b    #5,Current    ; ** CHANGE ** -> 5, not 6!!!!!!!!!

This way you will see a colour scroll. Since there are only a few, the effect is
a little too fast, but think of how useful it would be if you changed
the entire 32-colour palette for each interrupt, and did something else as well!
Not to mention the fact that you can also do something in the ‘user’ routine,
which here only does a sterile cycle waiting for the mouse to be pressed.
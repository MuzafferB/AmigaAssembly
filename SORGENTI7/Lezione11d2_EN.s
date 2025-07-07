
; Lesson 11d2.s - Using COPER and VERTB interrupts at level 3 ($6c).
;         This time, we will cycle the palette. Right-click
;         the mouse to temporarily block the routine.

Section    Interrupt,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup2.s’    ; save interrupt, dma, etc.
*****************************************************************************


; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper and bitplane DMA enabled

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

START:

; Point to the PIC

MOVE.L    #PICTURE2,d0
LEA    BPLPOINTERS2,A1
MOVEQ    #5-1,D1            ; number of bitplanes
POINTBT2:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
add.l    #34*40,d0        ; length of the bitplane
addq.w    #8,a1
dbra    d1,POINTBT2	; Repeat D1 times (D1=number of bitplanes)

; Point to our level 3 int

move.l    BaseVBR(PC),a0     ; In a0, the value of VBR
move.l    #MioInt6c,$6c(a0)    ; I put my level 3 int routine.

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

;     ,,,,;;;;;;;;;;;;;;;;;;;;;,
;     ,;;;;;;;;;;“”''“”'';;;;;;;;;;;;,
;     ;| \ “;;”
;     ;| _______ ______, )
;     _| _________ ________/
;     / T ¬/ ¬©) \ / ¬©) \¯¡
;    ( C| \_______/ \______/ |
;     \_j ______ \ ____ |
;     `| / \ \ l
;     | / (, _/ \ /
;     | _ __________ /
;     | '\ --------¬ /
;     | \_____________/
;     | __, T
;     l________________! xCz

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, reset?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play the music
movem.l    (SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
move.w    #$20,$dff09c    ; INTREQ - int executed, clear request
; since the 680x0 does not clear it by itself!!!
rte    ; Exit from int VERTB

nointVERTB:
btst.b    #4,$dff01f    ; INTREQR - COPER cleared?
beq.s	NointCOPER    ; if yes, it's not an int COPER!
movem.l    d0-d7/a0-a6,-(SP)    ; save registers to stack
bsr.w    ColorCicla        ; Cycle picture colours
movem.l    (SP)+,d0-d7/a0-a6    ; retrieve registers from stack

NointCOPER:
;6543210
move.w    #%1010000,$dff09c ; INTREQ - clear BLIT and COPER request
rte    ; exit from COPER/BLIT int


*****************************************************************************
*    Routine that ‘cycles’ the colours of the entire palette.         *
*    This routine cycles the first 15 colours separately from the second *
*    block of colours. It works like the ‘RANGE’ in Dpaint. *
*****************************************************************************

;    The ‘cont’ counter is used to wait 3 frames before
;    executing the cont routine. In practice, it ‘slows down’ the execution

cont:
dc.w    0

ColorCicla:
btst.b    #2,$dff016    ; Right mouse button pressed?
beq.s    NotYet    ; If yes, exit
addq.b    #1,cont
cmp.b    #3,cont        ; Act once every 3 frames only
bne.s    NotYet    ; Are we not at the third yet? Exit!
clr.b    cont        ; We are at the third, reset the counter

; Rotate the first 15 colours backwards

lea    cols+2,a0    ; Address of the first colour of the first group
move.w    (a0),d0        ; Save the first colour in d0
moveq    #15-1,d7    ; 15 colours to ‘rotate’ in the first group
cloop1:
move.w    4(a0),(a0)    ; Copy the colour forward to the one before
addq.w    #4,a0        ; jump to the next colour to ‘move backwards’
dbra    d7,cloop1    ; repeat d7 times
move.w    d0,(a0)        ; Set the first saved colour as the last.

; Rotate the second 15 colours forwards

lea    cole-2,a0    ; Address of the last colour in the second group
move.w    (a0),d0        ; Save the last colour in d0
moveq    #15-1,d7	; Another 15 colours to be ‘rotated’ separately
cloop2:
move.w    -4(a0),(a0)    ; Copy the colour back to the next one
subq.w    #4,a0        ; jump to the previous colour to be ‘moved forward’
dbra    d7,cloop2    ; repeat d7 times
move.w    d0,(a0)        ; Set the last saved colour as the first
NotYet:
rts


*****************************************************************************
;    Protracker/soundtracker/noisetracker replay routine
;
include    ‘assembler2:sources4/music.s’
*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w	$92,$0038	; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w    $100,$200    ; BPLCON0 - no bitplanes
dc.w    $180,$00e    ; colour0 BLUE

dc.w    $b807,$fffe    ; WAIT - wait for line $b8
dc.w    $9c,$8010	; INTREQ - Request a COPER interrupt, which
; acts on the 32 colours of the palette.

dc.w    $b907,$fffe    ; WAIT - wait for line $b9
BPLPOINTERS2:
dc.w $e0,0,$e2,0        ;first      bitplane
dc.w $e4,0,$e6,0        ;second ‘
dc.w $e8,0,$ea,0        ;third     ’
dc.w $ec,0,$ee,0        ;fourth     ‘
dc.w $f0,0,$f2,0        ;fifth     ’

dc.w    $100,%0101001000000000	; BPLCON0 - 5 bitplanes LOWRES

; The palette, which will be ‘rotated’ into 2 groups of 16 colours.

cols:
dc.w $180,$040,$182,$050,$184,$060,$186,$080    ; green tone
dc.w $188,$090,$18a,$0b0,$18c,$0c0,$18e,$0e0
dc.w $190,$0f0,$192,$0d0,$194,$0c0,$196,$0a0
dc.w $198,$090,$19a,$070,$19c,$060,$19e,$040

dc.w $1a0,$029,$1a2,$02a,$1a4,$13b,$1a6,$24b	; tono blu
dc.w $1a8,$35c,$1aa,$36d,$1ac,$57e,$1ae,$68f
dc.w $1b0,$79f,$1b2,$68f,$1b4,$58e,$1b6,$37e
dc.w $1b8,$26d,$1ba,$15d,$1bc,$04c,$1be,$04c
cole:

dc.w    $da07,$fffe	; WAIT - wait for line $da
dc.w    $100,$200    ; BPLCON0 - disable bitplanes
dc.w    $180,$00e    ; colour0 BLUE

dc.w    $FFFF,$FFFE    ; End of copperlist


*****************************************************************************
;         DRAWING 320*34 with 5 bitplanes (32 colours)
*****************************************************************************

PICTURE2:
INCBIN	‘pic320*34*5.raw’

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l    mt_data1

mt_data1:
incbin    ‘assembler2:sorgenti4/mod.fuck the bass’

end

In this example, the palette was changed just one line before the drawing.
In fact, you just need to change it one line before!
In the meantime, various tasks can be performed with the processor, but we will be
sure that the colours have changed each time at line $b9.
Another thing to note is that although the interrupt occurs every frame,
using a ‘counter’ it is possible to execute the routine once every
3 frames. So we have seen that it is possible to put multiple routines
and multiple interrupts in the same copperlist, on different lines, in Lesson 11d.s.
Just make sure that the routine for that line is executed each time.
Now let's see that we can execute some of these routines once
every X frames, so we can do anything!
Remember, however, that each interrupt takes a little time for the jumps
that need to be made.

A note: the two numbers are from the Fidonet AmigaLink BBS in Grosseto.
This is a ‘piece’ of the small demo I made for the sysop of this BBS.
I'm listed as “Fabio Ciucci”, but I rarely call, for reasons that have to do with
galactic phone bills. Until there is free Internet access in all
cities, it will be difficult for coders to exchange files via modem. Better to use email!

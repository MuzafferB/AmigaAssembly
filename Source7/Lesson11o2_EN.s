
; Lesson 11o2.s Loading a data file using dos.library
;         Press the left button to load, right to exit

Section DosLoad,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup2.s’    ; save interrupt, dma, etc.
*****************************************************************************

; With DMASET, we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper, bitplane DMA enabled

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
dbra    d1,POINTBT2    ; Repeat D1 times (D1=number of bitplanes)

; Point to the PIC that will be loaded (now it is just an empty buffer)

LEA    bplpointers,A0
MOVE.L    #LOGO+40*40,d0    ; logo address (slightly lowered)
MOVEQ    #6-1,D7        ; 6 HAM bitplanes.
pointloop:
MOVE.W    D0,6(A0)
SWAP    D0
MOVE.W    D0,2(A0)
SWAP    D0
ADDQ.w    #8,A0
ADD.L    #176*40,D0    ; plane length
DBRA    D7,pointloop


; Point to our level 3 int

move.l    BaseVBR(PC),a0     ; In a0 the value of VBR
move.l    oldint6c(PC),crappyint    ; For DOS LOAD - we will jump to oldint
move.l    #MioInt6c,$6c(a0)    ; I put my level 3 int. rout.

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_init		; initialise the music routine
movem.l    (SP)+,d0-d7/a0-a6

move.w    #$c020,$9a(a5)    ; INTENA - enable interrupt ‘VERTB’
; of level 3 ($6c)

mouse:
btst    #6,$bfe001    ; Mouse pressed? (the processor executes this
bne.s    mouse        ; loop in user mode, and every vertical blank
; as well as every WAIT of the raster line $a0
; interrupts it to play the music!).

bsr.w    DosLoad        ; Load a file legally with dos.lib
; while we are displaying our
; copperlist and executing our interrupt
TST.L    ErrorFlag
bne.s    ErrorLoad    ; File not loaded? Let's not use it then!

mouse2:
btst    #2,$dff016    ; Mouse pressed? (the processor executes this
bne.s    mouse2        ; loop in user mode, and every vertical blank

ErrorLoad:
bsr.w    mt_end        ; end of replay!

rts            ; exit

*****************************************************************************
*    INTERRUPT ROUTINE $6c (level 3) - VERTB and COPER used.
*****************************************************************************

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, zeroed?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play the music
bsr.w    ColorCicla        ; Cycle the colours of the pic
movem.l	(SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
NointVERTB:
move.w    #$70,$dff09c    ; INTREQ - int executed, clear the request
; since the 680x0 does not clear it by itself!!!
rte            ; Exit from int VERTB

*****************************************************************************
*    Routine that ‘cycles’ the colours of the entire palette.         *
*    This routine cycles the first 15 colours separately from the second *
*    second block of colours. It works like the ‘RANGE’ in Dpaint. *
*****************************************************************************

;    The ‘cont’ counter is used to wait 3 frames before
;    executing the cont routine. In practice, it ‘slows down’ the execution

cont:
dc.w    0

ColorCicla:
addq.b    #1,cont
cmp.b    #3,cont		; Act once every 3 frames only
bne.s    NotYet    ; Not at the third yet? Exit!
clr.b    cont        ; We are at the third, reset the counter

; Rotate the first 15 colours backwards

lea    cols+2,a0	; Address of the first colour of the first group
move.w    (a0),d0        ; Save the first colour in d0
moveq    #15-1,d7    ; 15 colours to ‘rotate’ in the first group
cloop1:
move.w    4(a0),(a0)    ; Copy the colour forward to the previous one
addq.w    #4,a0        ; Jump to the next colour to be ‘rotated backwards’
dbra    d7,cloop1    ; Repeat d7 times
move.w    d0,(a0)        ; Set the first colour saved as the last one.

; Rotate the second 15 colours forwards

lea    cole-2,a0    ; Address of the last colour in the second group
move.w    (a0),d0        ; Save the last colour in d0
moveq    #15-1,d7    ; Another 15 colours to ‘rotate’ separately
cloop2:
move.w    -4(a0),(a0)    ; Copy the colour back to the next one
subq.w    #4,a0        ; jump to the previous colour to be ‘moved forward’
dbra    d7,cloop2    ; repeat d7 times
move.w    d0,(a0)        ; Set the last saved colour as the first
NotYet:
rts


*****************************************************************************
; Routine that loads a file while we are typing in the metal.
*****************************************************************************

DosLoad:
bsr.w    PreparaLoad    ; Restore multitasking and set load interrupt

moveq    #5,d1        ; number of frames to wait
bsr.w    AspettaBlanks    ; wait 5 frames

bsr.s    LoadFile    ; Load the file with dos.library
move.l    d0,ErrorFlag    ; Save the success or error status

; note: now we have to wait for the disk drive motor, or the
; poor Hard Disk or CD-ROM light to turn off before blocking everything, or we will cause
; a spectacular system crash.

move.w    #150,d1        ; number of frames to wait
bsr.w    WaitBlanks    ; wait 150 frames

bsr.w    AfterLoad    ; Disable multitasking and reset interrupts
rts

ErrorFlag:
dc.l    0

*****************************************************************************
; Routine that loads a file of a specified length and with a specified name
;. You must enter the entire path!
*****************************************************************************

LoadFile:
move.l    #filename,d1    ; address with string ‘file name + path’
MOVE.L	#$3ED,D2    ; AccessMode: MODE_OLDFILE - File that already exists
; and can therefore be read.
MOVE.L    DosBase(PC),A6
JSR    -$1E(A6)    ; LVOOpen - ‘Open’ the file
MOVE.L    D0,FileHandle    ; Save its handle
BEQ.S	ErrorOpen    ; If d0 = 0 then there is an error!

; Load the file

MOVE.L    D0,D1        ; FileHandle in d1 for Read
MOVE.L    #buffer,D2    ; Destination address in d2
MOVE.L    #42240,D3    ; File length (EXACT!)
MOVE.L    DosBase(PC),A6
JSR    -$2A(A6)    ; LVORead - read the file and copy it to the buffer
cmp.l    #-1,d0        ; Error? (here indicated with -1)
beq.s    ErroreRead

; Let's close it

MOVE.L    FileHandle(pc),D1 ; FileHandle in d1
MOVE.L    DosBase(PC),A6
JSR    -$24(A6)    ; LVOClose - close the file.

; Please note that if you do not CLOSE the file, other programs will not
; be able to access it (you will not be able to delete or move it).

moveq    #0,d0    ; Signal success
rts

; Here are the painful notes, in case of error:

ErrorRead:
MOVE.L    FileHandle(pc),D1 ; FileHandle in d1
MOVE.L    DosBase(PC),A6
JSR    -$24(A6)    ; LVOClose - close the file.
ErrorOpen:
moveq    #-1,d0    ; signal failure
rts


FileHandle:
dc.l	0

; Text string, ending with a 0, which d1 must point to before
; opening dos.lib. It is best to enter the entire path.

Filename:
dc.b    ‘assembler2:sorgenti7/amiet.raw’,0    ; path+filename
even

*****************************************************************************
; Interrupt routine to be placed during loading. The routines that
; will be placed in this interrupt will also be executed during
; loading, whether from floppy disk, hard disk, or CD-ROM.
; PLEASE NOTE THAT WE ARE USING THE COPER INTERRUPT, NOT THE VBLANK INTERRUPT,
; THIS IS BECAUSE DURING LOADING FROM DISK, ESPECIALLY UNDER KICK 1.3,
; THE VERTB INTERRUPT IS NOT STABLE, so much so that the music would jump.
; Instead, if we put ‘$9c,$8010’ in our copperlist, we can be sure
that this routine will only be executed once per frame.
*****************************************************************************

myint6cLoad:
btst.b    #4,$dff01f    ; INTREQR - is bit 4, COPER, reset?
beq.s    nointL        ; If so, it is not a ‘true’ int COPER!
move.w    #%10000,$dff09c    ; If not, this is the right time to remove the req!
movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_music    ; Play music
movem.l    (SP)+,d0-d7/a0-a6
nointL:
dc.w    $4ef9        ; hexadecimal value of JMP
Crappyint:
dc.l    0        ; Address to jump to, to be AUTOMODIFIED...
; WARNING: the self-modifying code should not
; be used. However, if you call
; ClearMyCache before and after, it works!

*****************************************************************************
; Routine that restores the operating system, except for the copperlist, and
; also sets our own $6c interrupt, which then jumps to the system one.
; Note that during loading, the interrupt is handled by the ‘COPER’ int
*****************************************************************************

PreparaLoad:
LEA    $DFF000,A5        ; Base of CUSTOM registers for Offsets
MOVE.W    $2(A5),OLDDMAL        ; Save the old DMACON status
MOVE.W	$1C(A5),OLDINTENAL    ; Save the old status of INTENA
MOVE.W    $1E(A5),OLDINTREQL    ; Save the old status of INTREQ
MOVE.L    #$80008000,d0        ; Prepare the high bit mask
OR.L    d0,OLDDMAL		; Set bit 15 of the saved values
OR.W    d0,OLDINTREQL        ; of the registers, so that they can be restored.

bsr.w    ClearMyCache

MOVE.L    #$7FFF7FFF,$9A(a5)    ; DISABLE INTERRUPTS & INTREQS

move.l    BaseVBR(PC),a0     ; In a0 the value of VBR
move.l    OldInt64(PC),$64(a0) ; Sys int liv1 saved (softint,dskblk)
move.l    OldInt68(PC),$68(a0) ; Sys int liv2 saved (I/O,ciaa,int2)
move.l    #myint6cLoad,$6c(a0) ; Int which then jumps to that of sys.
 
move.l    OldInt70(PC),$70(a0) ; Sys int liv4 saved (audio)
move.l    OldInt74(PC),$74(a0) ; Sys int liv5 saved (rbf,dsksync)
move.l    OldInt78(PC),$78(a0) ; Sys int liv6 saved (exter,ciab,inten)

MOVE.W    #%1000001001010000,$96(A5) ; Enable blit and disk for security
MOVE.W    OLDINTENA(PC),$9A(A5)    ; INTENA STATUS
MOVE.W	OLDINTREQ(PC),$9C(A5)    ; INTREQ
move.w    #$c010,$9a(a5)        ; we must be sure that COPER
; (interrupt via copperlist) is ON!

move.l    4.w,a6
JSR    -$7e(A6)    ; Enable
JSR    -$8a(a6)    ; Permit

MOVE.L    GfxBase(PC),A6
jsr    -$E4(A6)    ; Wait for the end of any blitting
JSR    -$E4(A6)    ; WaitBlit
jsr    -$1ce(a6)    ; DisOwnBlitter, the operating system can now
; use the blitter again
; (in kick 1.3 this is needed to load from disk)
MOVE.L    4.w,A6
SUBA.L    A1,A1        ; NULL task - find this task
JSR    -$126(A6)    ; findtask (Task(name) in a1, -> d0=task)
MOVE.L    D0,A1        ; Task in a1
MOVEQ    #0,D0        ; Priority in d0 (-128, +127) - NORMAL
; (To allow the drives to breathe)
JSR    -$12C(A6)    ;_LVOSetTaskPri (d0=priority, a1=task)
rts

OLDDMAL:
dc.w    0
OLDINTENAL:        ; Old INTENA status
dc.w    0
OLDINTREQL:        ; Old INTREQ status
DC.W    0

*****************************************************************************
; Routine that closes the operating system and resets our interrupt
*****************************************************************************

AfterLoad:
MOVE.L    4.w,A6
SUBA.L    A1,A1        ; NULL task - find this task
JSR    -$126(A6)    ; findtask (Task(name) in a1, -> d0=task)
MOVE.L    D0,A1        ; Task in a1
MOVEQ    #127,D0        ; Priority in d0 (-128, +127) - MAXIMUM
JSR    -$12C(A6)    ;_LVOSetTaskPri (d0=priority, a1=task)

JSR    -$84(a6)    ; Forbid
JSR    -$78(A6)    ; Disable

MOVE.L    GfxBase(PC),A6
jsr    -$1c8(a6)    ; OwnBlitter, which gives us exclusive access to the blitter
; preventing its use by the operating system.
jsr	-$E4(A6)    ; WaitBlit - Waits for the end of each blit
JSR    -$E4(A6)    ; WaitBlit

bsr.w    ClearMyCache

LEA    $dff000,a5        ; Custom base for offsets
WaitF:
MOVE.L    4(a5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
AND.L    #$1ff00,D0    ; Select only the bits of the vertical position
CMP.L    #$12d00,D0    ; wait for line $12d to prevent
BEQ.S    WaitF    ; turning off the DMA causes flickering

MOVE.L    #$7FFF7FFF,$9A(A5)    ; DISABLE INTERRUPTS & INTREQS

; 5432109876543210
MOVE.W    #%0000010101110000,d0    ; DISABLE DMA

btst    #8-8,olddmal    ; test bitplane
beq.s	NoPlanesA
bclr.l    #8,d0        ; do not turn off planes
NoPlanesA:
btst    #5,olddmal+2    ; test sprite
beq.s    NoSpritez
bclr.l    #5,d0        ; do not turn off sprite
NoSpritez:
MOVE.W    d0,$96(A5) ; DISABLE DMA

move.l    BaseVBR(PC),a0        ; In a0 the value of VBR
move.l    #MioInt6c,$6c(a0)    ; I put my rout. int. level 3.
MOVE.W    OLDDMAL(PC),$96(A5)    ; Restore the old DMA status
MOVE.W    OLDINTENAL(PC),$9A(A5)    ; INTENA STATUS
MOVE.W    OLDINTREQL(PC),$9C(A5)    ; INTREQ
rts

*****************************************************************************
; This routine waits for D1 frames. Every 50 frames, 1 second passes.
;
; d1 = number of frames to wait for
;
*****************************************************************************

WaitBlanks:
LEA    $DFF000,A5    ; CUSTOM REG for OFFSETS
WBLAN1xb:
MOVE.w    #$80,D0
WBLAN1bxb:
CMP.B    6(A5),D0    ; vhposr
BNE.S    WBLAN1bxb
WBLAN2xb:
CMP.B    6(A5),D0    ; vhposr
Beq.S    WBLAN2xb
DBRA    D1,WBLAN1xb
rts

*****************************************************************************
;	Routine di replay del protracker/soundtracker/noisetracker
;
include	‘assembler2:sorgenti4/music.s’
*****************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0	; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

BPLPOINTERS:
dc.w $e0,0,$e2,0		;first bitplane
dc.w $e4,0,$e6,0        ;second
dc.w $e8,0,$ea,0        ;third
dc.w $ec,0,$ee,0        ;fourth
dc.w $f0,0,$f2,0		;fifth ‘
dc.w $f4,0,$f6,0        ;sixth ’

dc.w    $180,0    ; Colour0 black


;5432109876543210
dc.w    $100,%0110101000000000    ; bplcon0 - 320*256 HAM!

dc.w $180,$0000,$182,$134,$184,$531,$186,$443
dc.w $188,$0455,$18a,$664,$18c,$466,$18e,$973
dc.w $190,$0677,$192,$886,$194,$898,$196,$a96
dc.w $198,$0ca6,$19a,$9a9,$19c,$bb9,$19e,$dc9
dc.w $1a0,$0666

dc.w    $9707,$FFFE    ; wait line $97

dc.w	$100,$200    ; BPLCON0 - no bitplanes
dc.w    $180,$00e    ; colour0 BLUE

dc.w    $b907,$fffe    ; WAIT - wait for line $b9
BPLPOINTERS2:
dc.w $e0,0,$e2,0        ;first      bitplane
dc.w $e4,0,$e6,0        ;second "
dc.w $e8,0,$ea,0        ;third	 ‘
dc.w $ec,0,$ee,0        ;fourth     ’
dc.w $f0,0,$f2,0        ;fifth     "

dc.w    $100,%0101001000000000    ; BPLCON0 - 5 bitplanes LOWRES

; The palette, which will be ‘rotated’ in 2 groups of 16 colours.

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

dc.w    $da07,$fffe    ; WAIT - wait for line $da
dc.w    $100,$200    ; BPLCON0 - disable bitplanes
dc.w    $180,$00e    ; colour0 BLUE

dc.w    $ff07,$fffe    ; WAIT - wait for line $ff
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt, to
; play the music (even while we are
; loading with dos.library).

dc.w    $FFFF,$FFFE    ; End of copperlist


*****************************************************************************
;         DESIGN 320*34 with 5 bitplanes (32 colours)
*****************************************************************************

PICTURE2:
INCBIN	‘pic320*34*5.raw’

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l    mt_data1

mt_data1:
incbin    ‘assembler2:sorgenti4/mod.fairlight’

******************************************************************************
; Buffer where the image is loaded from disk (or hard disk) using doslib
**************************************************************

section    mioplanaccio,bss_C

buffer:
LOGO:
ds.b    6*40*176    ; 6 bitplanes * 176 lines * 40 bytes (HAM)


end

In this example, we load the logo, which appears immediately above. If you load it
from a floppy disk, you will notice that it appears plane by plane, in pieces, because it loads
a little at a time! It would be better to load it into a separate buffer, then
display it all together once loading is complete.
The key thing about loading is that the time waited after loading,
before closing everything, is sufficient. Otherwise, it's game over!
In Interrupt, the colour routine is not executed, only the music routine
,
 but at least you can see the time it waits “for safety”.
Since this time has to be waited for anyway, it would be smart to do a
fade or some routine that wastes time doing something nice before
closing everything, at least you've waited for the time, but not without using it!


; Lesson 11o3.s Loading a data file using dos.library
;         Note: you don't need to know the length of the file!
;         Press the left button to load, right to exit

Section DosLoad,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; salva interrupt, dma eccetera.
*****************************************************************************

; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper,bitplane DMA enabled

WaitDisk    EQU    30    ; 50-150 to save (depending on the case)

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
addq.w	#8,a1
dbra    d1,POINTBT2    ; Repeat D1 times (D1=number of bitplanes)

; Point to an empty buffer, which will always remain empty...

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

move.l    BaseVBR(PC),a0     ; In a0, the value of VBR
move.l    oldint6c(PC),crappyint    ; For DOS LOAD - we will jump to oldint
move.l    #MioInt6c,$6c(a0)    ; I put my level 3 int rout.

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

movem.l    d0-d7/a0-a6,-(SP)
bsr.w	mt_init        ; initialise the music routine
movem.l    (SP)+,d0-d7/a0-a6

move.w    #$c020,$9a(a5)    ; INTENA - enable interrupt ‘VERTB’
; of level 3 ($6c)

mouse:
btst    #6,$bfe001	; Mouse pressed? (the processor executes this
bne.s    mouse        ; loop in user mode, and every vertical blank
; as well as every WAIT of the raster line $a0
; interrupts it to play the music!).


lea    FileName1(PC),a0     ; Name of the file to load
lea    Buffile1(PC),a1		; In which label do I save the address
; of the file loaded into memory
lea    Size1(PC),a2    ; In which label do I save the size
moveq    #2,d0            ; Type of destination memory: CHIP RAM!

bsr.w DosLoad2 ; Load a file legally with dos.lib
while we are viewing our
copperlist and executing our interrupt.
; First define ‘TypeOfMem’ with “2” for CHIP
; or ‘1’ for PUBLIC, and the other parameters.
TST.B    d1        ; Have we allocated memory to be freed?
beq.s    NonFreeMemare    ; d1=0, then not allocated
st.b	FreeMema1    ; If so, set FreeMema1
NonFreeMemare
TST.L    d0        ; Check for errors...
bne.s    ErroreLoad    ; File not loaded? Let's not use it then!
; d0=0, then everything is fine

; Now let's point to the loaded image:

LEA    bplpointers,A0
move.l    Buffile1(PC),d0 ; address of the loaded file
ADD.L    #40*40,d0    ; logo slightly lowered (let's centre it...)
MOVEQ    #6-1,D7        ; 6 bitplanes HAM.
pointloop2:
MOVE.W    D0,6(A0)
SWAP    D0
MOVE.W    D0,2(A0)
SWAP    D0
ADDQ.w    #8,A0
ADD.L    #176*40,D0    ; plane length
DBRA    D7,pointloop2

ErrorLoad:
mouse2:
btst    #2,$dff016    ; Mouse pressed? (the processor executes this
bne.s    mouse2        ; loop in user mode, and every vertical blank

bsr.w    mt_end        ; end of replay!

; ALWAYS REMEMBER TO FREE ALL ALLOCATED MEMORY!
; But also don't call FreeMem if we haven't actually allocated
; memory, or you'll get super guru meditation - software failure - various messes.

tst.b    FreeMema1    ; there was an error beforeAllocMem?
beq.s    NotAllocated1    ; if so, don't do FreeMem!

move.l    Size1(PC),d0 ; Size of the block in bytes
move.l    Buffile1(PC),a1 ; Address of the allocated memory block
move.l    4.w,a6
jsr    -$d2(a6)    ; FreeMem
NotAllocated1:
rts            ; exit


; Variables used to save the size and address of the file to
; be used and deallocated at the end

Buffile1:
dc.l    0
Size1:
dc.l    0
FreeMema1:
dc.l    0

*****************************************************************************
*    INTERRUPT ROUTINE $6c (level 3) - used VERTB and COPER.
*****************************************************************************

MioInt6c:
btst.b    #5,$dff01f    ; INTREQR - is bit 5, VERTB, zeroed?
beq.s    NointVERTB        ; If so, it is not a ‘true’ int VERTB!
movem.l    d0-d7/a0-a6,-(SP)    ; save the registers in the stack
bsr.w    mt_music        ; play the music
bsr.w    ColorCicla        ; Cycle the colours of the pic
movem.l    (SP)+,d0-d7/a0-a6    ; retrieve the registers from the stack
NointVERTB:
move.w    #$70,$dff09c    ; INTREQ - int executed, clear the request
; since the 680x0 does not clear it by itself!!!
rte            ; Exit from int VERTB

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
addq.b    #1,cont
cmp.b    #3,cont        ; Act once every 3 frames only
bne.s    NotYet    ; Not at the third yet? Exit!
clr.b    cont        ; We are at the third, reset the counter

; Rotate the first 15 colours backwards

lea    cols+2,a0    ; Address of the first colour of the first group
move.w    (a0),d0        ; Save the first colour in d0
moveq    #15-1,d7    ; 15 colours to ‘rotate’ in the first group
cloop1:
move.w	4(a0),(a0)    ; Copy the colour forward to the one before
addq.w    #4,a0        ; jump to the next colour to be ‘rotated backwards’
dbra    d7,cloop1    ; repeat d7 times
move.w    d0,(a0)        ; Set the first saved colour as the last.

; Forward rotation of the second 15 colours

lea    cole-2,a0    ; Address of the last colour in the second group
move.w    (a0),d0        ; Save the last colour in d0
moveq    #15-1,d7    ; Another 15 colours to be ‘rotated’ separately
cloop2:
move.w    -4(a0),(a0)    ; Copy the colour back to the next one
subq.w    #4,a0        ; jump to the previous colour to be ‘moved forward’
dbra    d7,cloop2    ; repeat d7 times
move.w    d0,(a0)        ; Set the last saved colour as the first
NotYet:
rts


*****************************************************************************
; Routine that loads a file while we are typing on the metal.
;
; Input parameters:
;
; a0    = Address of the string with the name of the file to load
; a1    = Address of the label (.L) where to save the file address
; a2	= Address of the label (.L) where to save the file length
;
; Output parameters:
;
; d0.l    = If = 0, there are no problems; if = -1, there has been an error
; d1.b    = If = 0, we have not executed AllocMem; if = 1, we must execute FreeMem!
;
*****************************************************************************

DosLoad2:
movem.l    d2-d7/a3-a6,-(SP)
move.l    a0,FileName     ; Name of the file to load
move.l    a1,DestinazLoad	; In which label do I save the address
move.l    a2,SalvGrandezz    ; In which label do I save the file size
move.l    d0,TypeOfMem    ; Type of destination memory: CHIP RAM!

bsr.w    PreparaLoad    ; Restore multitask and set interrupt load

moveq	#5,d1        ; number of frames to wait
bsr.w    WaitBlanks    ; wait 5 frames

bsr.s    LoadFile2    ; Load the file with dos.library, of
; any ‘unknown’ length.
move.l    d0,ErrorFlag    ; Save the success or error status

; note: now we must wait for the disk drive motor, or the
; poor Hard Disk or CD-ROM light to turn off before blocking everything, or we will cause
; a spectacular system crash.

move.w    #150,d1        ; number of frames to wait
bsr.w    WaitBlanks    ; wait 150 frames

bsr.w    AfterLoad    ; Disable multitasking and reset interrupts
move.l    ErrorFlag(PC),d0 ; set the error/success flag
moveq	#0,d1
move.b    FreeMemFlag(PC),d1 ; set the freemem flag to be done
clr.b    FreeMemFlag     ; reset it (unallocated) for the next time
movem.l    (SP)+,d2-d7/a3-a6
rts

ErrorFlag:
dc.l    0

*****************************************************************************
; Routine that loads a file of any ‘unknown’ length into a
; CHIP or PUBLIC memory buffer, allocated with AllocMem.
; First define ‘TypeOfMem’ with “2” for CHIP RAM or ‘1’ for PUBLIC.
; On exit, d0=0 if successful, or -1 if there were problems.
*****************************************************************************

; “”~``
; ( o o )
;+-.oooO--(_)--Oooo.---------------------------------------------------------+
;|                                     |
;| Oooo     SORRY IF THE ROUTINE IS A LITTLE MESSY |
;| ( ) Oooo.                  |
;+----\ (----( )-----------------------------------------------------------+
; \_) ) /
; (_/

CaricaFile2:
move.l    filename(PC),d1    ; address with string ‘file name + path’
MOVE.L    #$3ED,D2    ; AccessMode: MODE_OLDFILE - File that already exists
; and can therefore be read.
MOVE.L    DosBase(PC),A6
JSR    -$1E(A6)    ; LVOOpen - ‘Open’ the file
MOVE.L    D0,FileHandle    ; Save its handle
BEQ.W    ErrorOpen    ; If d0 = 0 then there is an error!

; Now let's lock the file so we can examine it

move.l    filename(pc),d1    ; file name
moveq	#-2,d2        ; AccessMode = ACCESS_READ
jsr    -$54(a6)    ; lock the file
move.l    d0,filelock    ; Save the pointer to the file lock
beq.w    ErroreLock    ; d0 = 0? Then error!

; Allocate memory for the FileInfoBlock of Examine()

move.l    #$104,d0    ; Block size in bytes
move.l    #1,d1        ; Memory type: public
move.l    4.w,a6
jsr    -$c6(a6)    ; Allocmem
move.l    d0,FibAdr    ; Start address of the allocated memory block
beq.s    ErrorAtFib    ; d0=0? Then error!

; Now we examine the file to find out its length

move.l    FileLock(PC),d1	; lock ptr in d1 for examine
move.l    FibAdr(PC),d2    ; File Info Block for examine
MOVE.L    DosBase(PC),A6
jsr    -$66(a6)    ; examine fills the fib buffer ($104 bytes)
; with info about the file (name, dir/file, size, date)
tst.l	d0        ; Problems with Examine?
beq.s    Examine error
move.l    FibAdr(pc),a0
move.l    $7c(a0),d3    ; size offset (length)
move.l    d3,SizeFile

; Now we can also free the memory used for the FileInfoBlock

bsr.w    FreeFib

; Allocate memory for the file

move.l    SizeFile(PC),d0     ; Block size in bytes
move.l    TypeOfMem(PC),d1 ; Memory type
move.l    4.w,a6
jsr    -$c6(a6)    ; Allocmem
move.l    d0,FileAdr    ; Start address of the allocated memory block
beq.s    ErroreAllFile    ; d0=0? Then error!

; Let's make a copy of the file address for ourselves and freemem

move.l    DestinazLoad(PC),a0
move.l    d0,(a0)
move.l    SalvGrandezz(PC),a0    ; and let's also save the length
move.l    SizeFile(PC),(a0)

st.b    FreeMemFlag    ; Let's remember to do the freemem

; Load the file into the allocated memory block:

MOVE.L    FileHandle(PC),D1 ; FileHandle in d1 for Read
MOVE.L    FileAdr(PC),D2    ; Destination address in d2
MOVE.L    SizeFile(PC),D3    ; File length (EXACT!)
MOVE.L DosBase(PC),A6
JSR -$2A(A6) ; LVORead - read the file and copy it to the buffer
cmp.l #-1,d0 ; Error? (here indicated with -1)
beq.s ErrorRead

; Unlock the file

bsr.s    UnlockFile

; And close it

bsr.s    CloseFile

; Be careful that if you do not CLOSE the file, other programs will not
; be able to access it (you will not be able to delete or move it).

moveq    #0,d0    ; signals total success!
rts


; Here is a compilation of possible errors:


ExamineError:
bsr.s    FreeFib
AllFileError:
FibError:
bsr.s    UnlockFile
LockError:
bsr.s    CloseFile
ErrorOpen:
moveq    #-1,d0        ; signals the error
rts

ErrorRead:
bsr.s    UnlockFile
bsr.s    CloseFile
st.b    FreeMemFlag    ; Remember to do freemem
moveq    #-1,d0        ; Signals the error
rts

; Routines called from multiple locations:

CloseFile:
MOVE.L DosBase(PC),A6
MOVE.L FileHandle(pc),D1 ; FileHandle in d1
JSR -$24(A6) ; LVOClose - close the file.
rts

UnlockFile:
MOVE.L    DosBase(PC),A6
move.l    FileLock(PC),d1    ; lock ptr in d1 to unlock
jsr    -$5a(a6)    ; Unlock the file
rts

FreeFib:
move.l    4.w,a6
move.l    #$104,d0    ; Block size in bytes
move.l    FibAdr(PC),a1    ; Address of allocated memory block
jsr    -$d2(a6)    ; FreeMem
rts

SaveSize:
dc.l	0
DestinationLoad:
dc.l    0
FileHandle:
dc.l    0
TypeOfMem:
dc.l    0
FileName:
dc.l    0
FileLock:
dc.l    0
FibAdr:
dc.l    0
FileSize:
dc.l    0
FileAdr
dc.l    0
FreeMemFlag:
dc.l    0

; Text string, ending with a 0, which d1 must point to before
; opening dos.lib. It is best to enter the entire path.


Filename1:
dc.b	‘assembler3:sorgenti7/amiet.raw’,0    ; path+filename
even

*****************************************************************************
; Interrupt routine to be placed during loading. The routines that
; will be placed in this interrupt will also be executed during
; loading, whether from floppy disk, hard disk, or CD-ROM.
; NOTE THAT WE ARE USING THE COPER INTERRUPT, NOT THE VBLANK INTERRUPT,
; THIS IS BECAUSE DURING LOADING FROM DISK, ESPECIALLY UNDER KICK 1.3,
; THE VERTB INTERRUPT IS NOT STABLE, so much so that the music would have jerks.
; Instead, if we put a ‘$9c,$8010’ in our copperlist, we are sure
; that this routine will be executed only once per frame.
*****************************************************************************

myint6cLoad:
btst.b    #4,$dff01f    ; INTREQR - is bit 4, COPER, reset?
beq.s    nointL        ; If so, it is not a ‘true’ int COPER!
move.w    #%10000,$dff09c    ; If not, this is the right time to remove the req!
movem.l    d0-d7/a0-a6,-(SP)
bsr.w    mt_music	; Play music
movem.l    (SP)+,d0-d7/a0-a6
nointL:
dc.w    $4ef9        ; hexadecimal value of JMP
Crappyint:
dc.l    0        ; Address to jump to, to be AUTOMODIFIED...
; WARNING: the automodifying code should not
; be used. However, if you call a
; ClearMyCache before and after, it works!

*****************************************************************************
; Routine that restores the operating system, except for the copperlist, and
; sets our own $6c interrupt, which then jumps to the system interrupt.
; Note that during loading, the interrupt is handled by the ‘COPER’ int
*****************************************************************************

PreparaLoad:
LEA    $DFF000,A5        ; Base of CUSTOM registers for Offsets
MOVE.W    $2(A5),OLDDMAL        ; Save the old DMACON status
MOVE.W    $1C(A5),OLDINTENAL    ; Save the old INTENA status
MOVE.W	$1E(A5),OLDINTREQL    ; Save the old status of INTREQ
MOVE.L    #$80008000,d0        ; Prepare the high bit mask
OR.L	d0,OLDDMAL        ; Set bit 15 of the saved values
OR.W    d0,OLDINTREQL        ; of the registers, so that they can be restored.

bsr.w    ClearMyCache

MOVE.L    #$7FFF7FFF,$9A(a5)    ; DISABLE INTERRUPTS & INTREQS

move.l    BaseVBR(PC),a0     ; In a0 the value of VBR
move.l    OldInt64(PC),$64(a0) ; Sys int liv1 saved (softint,dskblk)
move.l    OldInt68(PC),$68(a0) ; Sys int liv2 saved (I/O,ciaa,int2)
move.l    #myint6cLoad,$6c(a0) ; Int which then jumps to that of sys.
move.l    OldInt70(PC),$70(a0) ; Sys int liv4 saved (audio)
move.l	OldInt74(PC),$74(a0) ; Sys int liv5 saved (rbf,dsksync)
move.l    OldInt78(PC),$78(a0) ; Sys int liv6 saved (exter,ciab,inten)

MOVE.W    #%1000001001010000,$96(A5) ; Enable blit and disk for safety
MOVE.W    OLDINTENA(PC),$9A(A5)    ; INTENA STATUS
MOVE.W    OLDINTREQ(PC),$9C(A5)    ; INTREQ
move.w    #$c010,$9a(a5)        ; we must be sure that COPER
; (interrupt via copperlist) is ON!

move.l    4.w,a6
JSR    -$7e(A6)    ; Enable
JSR    -$8a(a6)    ; Permit

MOVE.L	GfxBase(PC),A6
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
MOVEQ    #127,D0        ; Priority in d0 (-128, +127) - MAX
JSR    -$12C(A6)    ;_LVOSetTaskPri (d0=priority, a1=task)

JSR    -$84(a6)    ; Forbid
JSR    -$78(A6)    ; Disable

MOVE.L    GfxBase(PC),A6
jsr    -$1c8(a6)    ; OwnBlitter, which gives us exclusive access to the blitter
; preventing its use by the operating system.
jsr    -$E4(A6)    ; WaitBlit - Waits for the end of each blit
JSR    -$E4(A6)    ; WaitBlit

bsr.w    ClearMyCache

LEA    $dff000,a5        ; Custom base for offsets
WaitF:
MOVE.L    4(a5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
AND.L    #$1ff00,D0    ; Select only the bits of the vertical position
CMP.L    #$12d00,D0    ; wait for line $12d to prevent
BEQ.S    WaitF    ; turning off the DMAs causes flickering

MOVE.L    #$7FFF7FFF,$9A(A5)    ; DISABLE INTERRUPTS & INTREQS

; 5432109876543210
MOVE.W    #%0000010101110000,d0    ; DISABLE DMA

btst    #8-8,olddmal    ; test bitplane
beq.s    NoPlanesA
bclr.l    #8,d0        ; do not turn off planes
NoPlanesA:
btst    #5,olddmal+2    ; test sprite
beq.s    NoSpritez
bclr.l    #5,d0        ; do not turn off sprite
NoSpritez:
MOVE.W    d0,$96(A5) ; DISABLE DMA

move.l    BaseVBR(PC),a0        ; In a0 the value of VBR
move.l	#MioInt6c,$6c(a0)    ; set my level 3 int. routine.
MOVE.W    OLDDMAL(PC),$96(A5)    ; Restore old DMA status
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
include	‘assembler3:sorgenti4/music.s’
*****************************************************************************

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

BPLPOINTERS:
dc.w $e0,0,$e2,0        ;first      bitplane
dc.w $e4,0,$e6,0        ;second ‘
dc.w $e8,0,$ea,0        ;third ’
dc.w $ec,0,$ee,0        ;fourth ‘
dc.w $f0,0,$f2,0        ;fifth ’
dc.w $f4,0,$f6,0        ;sixth "

dc.w    $180,0    ; Color0 black


;5432109876543210
dc.w	$100,%0110101000000000    ; bplcon0 - 320*256 HAM!

dc.w $180,$0000,$182,$134,$184,$531,$186,$443
dc.w $188,$0455,$18a,$664,$18c,$466,$18e,$973
dc.w $190,$0677,$192,$886,$194,$898,$196,$a96
dc.w $198,$0ca6,$19a,$9a9,$19c,$bb9,$19e,$dc9
dc.w $1a0,$0666

dc.w    $9707,$FFFE    ; wait line $97

dc.w    $100,$200    ; BPLCON0 - no bitplanes
dc.w    $180,$00e    ; colour0 BLUE

dc.w	$b907,$fffe    ; WAIT - wait for line $b9
BPLPOINTERS2:
dc.w $e0,0,$e2,0        ;first      bitplane
dc.w $e4,0,$e6,0        ;second "
dc.w $e8,0,$ea,0        ;third     ‘
dc.w $ec,0,$ee,0        ;fourth     ’
dc.w $f0,0,$f2,0        ;fifth     "

dc.w    $100,%0101001000000000	; BPLCON0 - 5 bitplanes LOWRES

; The palette, which will be ‘rotated’ into 2 groups of 16 colours.

cols:
dc.w $180,$040,$182,$050,$184,$060,$186,$080    ; green tone
dc.w $188,$090,$18a,$0b0,$18c,$0c0,$18e,$0e0
dc.w $190,$0f0,$192,$0d0,$194,$0c0,$196,$0a0
dc.w $198,$090,$19a,$070,$19c,$060,$19e,$040

dc.w $1a0,$029,$1a2,$02a,$1a4,$13b,$1a6,$24b    ; blue tone
dc.w $1a8,$35c,$1aa,$36d,$1ac,$57e,$1ae,$68f
dc.w $1b0,$79f,$1b2,$68f,$1b4,$58e,$1b6,$37e
dc.w $1b8,$26d,$1ba,$15d,$1bc,$04c,$1be,$04c
cole:

dc.w	$da07,$fffe	; WAIT - wait for line $da
dc.w    $100,$200    ; BPLCON0 - disable bitplanes
dc.w    $180,$00e    ; colour0 BLUE

dc.w    $ff07,$fffe    ; WAIT - wait for line $ff
dc.w    $9c,$8010    ; INTREQ - Request a COPER interrupt, for
; playing music (even while
; loading with dos.library).

dc.w    $FFFF,$FFFE    ; End of copperlist


*****************************************************************************
; 		DISEGNO 320*34 a 5 bitplanes (32 colori)
*****************************************************************************

PICTURE2:
INCBIN	‘pic320*34*5.raw’

*****************************************************************************
;				MUSICA
*****************************************************************************

mt_data:
dc.l	mt_data1

mt_data1:
incbin	‘assembler3:sorgenti7/Mod.Prova’

******************************************************************************
; Buffer that remains empty, here it is only used as ‘black’ before loading.
; We could also have simply disabled the bitplanes and activated them
; only when the image was loaded, to save this zeroed space!
******************************************************************************

section    mioplanaccio,bss_C

buffer:
LOGO:
ds.b	6*40*176    ; 6 bitplanes * 176 lines * 40 bytes (HAM)


end

This listing locks the file, EXAMINES it to get its length, allocates the
memory with AllocMem, loads it, and finally frees the memory block
with FreeMem. Please note the attention paid to the various possibilities
of error, so as not to execute FreeMem when nothing has been allocated, and
so as not to use the file when it has not been loaded correctly. You must ALWAYS
check everything and prepare routines for possible failures.
The routine has been made more parametric, so you can specify the file name and the type of memory required each
time. Just make sure that if
you want to load multiple files, you don't get confused with the various FreeMem calls at the end!
Here is an example where we load two files:

; First file:

lea    FileName1(PC),a0     ; Name of the file to load
lea    Buffile1(PC),a1        ; In which label do I save the address
; of the file loaded into memory
lea	Grandezz1(PC),a2    ; In which label do I save the size
moveq    #2,d0            ; Type of destination memory: CHIP RAM!

bsr.w    DosLoad2    ; Load a file legally with dos.lib
; while we are viewing our
; copperlist and executing our interrupt
; First define ‘TypeOfMem’ with ‘2’ for CHIP
; or ‘1’ for PUBLIC, and the other parameters.
TST.B    d1        ; Have we allocated memory to be freed?
beq.s    NonFreeMemare    ; d1=0, then not allocated
st.b	FreeMema1    ; If yes, set FreeMema1
NonFreeMemare
TST.L    d0        ; Check for errors...
bne.s    ErroreLoad    ; File not loaded? Don't use it then!
; d0=0, then everything is fine
....

; Second file:

lea    FileName2(PC),a0     ; Name of the file to load
lea    Buffile2(PC),a1        ; In which label do I save the address
; of the file loaded into memory
lea    Grandezz2(PC),a2    ; In which label do I save the size
moveq    #2,d0            ; Type of destination memory: CHIP RAM!

bsr.w DosLoad2 ; Load a file legally with dos.lib
; while we are viewing our
; copperlist and executing our interrupt
; First define ‘TypeOfMem’ with “2” for CHIP
; or ‘1’ for PUBLIC, and the other parameters.
TST.B d1 ; Have we allocated memory to be freed?
beq.s    NonFreeMemare2    ; d1=0, then not allocated
st.b    FreeMema2    ; If yes, set FreeMema1
NonFreeMemare2
TST.L    d0        ; Check for errors...
bne.s    ErroreLoad2    ; File not loaded? Let's not use it then!
...            ; d0=0, then everything is fine


And finally, we will have to do 2 FreeMem:

tst.b    FreeMema1    ; Was there an error before AllocMem?
beq.s    NonEraAllocata1    ; If so, do not do FreeMem!

move.l    Size1(PC),d0 ; Size of the block in bytes
move.l    Buffile1(PC),a1 ; Address of the allocated memory block
move.l    4.w,a6
jsr    -$d2(a6)    ; FreeMem
NotAllocated1:

tst.b    FreeMema2    ; Was there an error before AllocMem?
beq.s    NotAllocated2    ; If so, do not perform FreeMem!

move.l    Size2(PC),d0 ; Size of the block in bytes
move.l    Buffile2(PC),a1 ; Address of the allocated memory block
move.l    4.w,a6
jsr    -$d2(a6)    ; FreeMem
NotAllocated2:

rts            ; exit


Of course, you can change the routine as you wish, or make the one that loads files with a specified length parametric... do as you like, but
be careful not to make any mistakes!

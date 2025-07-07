**************************************************************
; 680X0 & AGA STARTUP BY FABIO CIUCCI - Complexity level 2
**************************************************************

MAINCODE:
movem.l    d0-d7/a0-a6,-(SP)    ; Save registers to stack
move.l    4.w,a6            ; ExecBase in a6
LEA    DosName(PC),A1        ; Dos.library
JSR    -$198(A6)        ; OldOpenlib
MOVE.L    D0,DosBase
BEQ.w    EXIT3            ; If zero, exit! Error!
LEA    GfxName(PC),A1        ; Name of library to open
JSR    -$198(A6)        ; OldOpenLibrary - open the library
MOVE.L    d0,GfxBase
BEQ.w    EXIT2            ; If yes, exit! Error!
LEA    IntuiName(PC),A1    ; Intuition.library
JSR    -$198(A6)        ; OldOpenlib
MOVE.L    D0,IntuiBase
BEQ.w    EXIT1            ; If zero, exit! Error!

MOVE.L    d0,A0
CMP.W    #39,$14(A0)     ; Version 39 or higher? (kick3.0+)
BLT.s    OldIntui
BSR.w    ResetSpritesV39 ; if kick3.0+ then reset sprites
OldIntui:

; Save colour0

MOVE.L    IntuiBase(PC),A6
move.l    $3c(a6),a0    ; Ib_FirstScreen (Screen in ‘foreground!’)
LEA    $2c(A0),A0    ; vp = A pointer to a ViewPort structure.
move.l    a0,VPfirstScreen
move.l    4(a0),a0    ; colormap = the colormap of this viewport
MOVEQ    #0,D0        ; entry - we want colour 0! (background)
MOVE.L    GfxBase(PC),A6
JSR    -$246(A6)    ; GetRGB4 - get the value of colour0
; from the screen's ColorMap (-1 if error!)
move.w    d0,SavedColor0

; And let's blacken it!

move.l    VPfirstScreen(PC),a0
LEA    colore0(PC),A1    ; colour $0RGB
MOVEQ    #1,D0        ; count - only the background colour to change
JSR    -$C0(A6)    ; LoadRGB4

; Reset the screen (with black background colour!)

MOVE.L    $22(A6),WBVIEW    ; Save the current system WBView
SUB.L    A1,A1        ; View null to reset the video mode
JSR    -$DE(A6)    ; Load null View - video mode reset
SUB.L    A1,A1        ; View null
JSR    -$DE(A6)    ; LoadView (twice to be on the safe side...)
JSR    -$10E(A6)    ; WaitOf ( These two calls to WaitOf )
JSR    -$10E(A6)    ; WaitOf ( used to reset the interlace )
JSR    -$10E(A6)    ; Two more, go!
JSR    -$10E(A6)

bsr.w    InputOff    ; Disables intuition input (i.e. no longer
; reads the mouse and keyboard)

MOVE.L    4.w,A6
SUB.L	A1,A1        ; NULL task - find this task
JSR    -$126(A6)    ; findtask (Task(name) in a1, -> d0=task)
MOVE.L    D0,A1        ; Task in a1
move.l    d0,ThisTask
MOVE.L    $B8(A1),pr_Win    ; At this offset is the address
; of the window from which
; the programme was loaded and which is needed by
; DOS to know where to open the Reqs.
MOVE.L    #-1,$B8(A1)    ; By setting it to -1, DOS does not open Reqs
; In fact, if there were errors opening
; files with dos.lib, the system
; would try to open a requester, but with
; the blitter disabled (OwnBlit), it
; would not be able to draw it, blocking everything!
MOVEQ    #-1,D0        ; Priority in d0 (-128, +127) - waiting
JSR	-$12C(A6)    ; LVOSetTaskPri (d0=priority, a1=task)

LEA    $DFF006,A5    ; VhPosr
lea    $bfe001,a4
moveq    #6,d2
MOVE.w    #$dd,D0        ; Line to wait for
MOVE.w    #WaitDisk,D1    ; How long to wait.... (To make sure that
WaitaLoop:            ; disk drives or Hard Disk have finished).
btst.b    d2,(a4)        ; btst #6,$bfe001 -> wait for left mouse
beq.s    SkippaWait
CMP.B    (A5),D0
BNE.S    WaitaLoop
Wait2:
CMP.B    (A5),D0
Beq.s    Wait2
dbra    D1,WaitaLoop
SkippaWait:
btst.b    d2,(a4)        ; btst #6,$bfe001 -> let go of the left mouse button!
beq.s    SkippaWait


MOVE.L    4.w,A6
move.l    thistask(PC),a1    ; Task in a1
MOVEQ    #127,D0        ; Priority in d0 (-128, +127) - MAXIMUM!
JSR	-$12C(A6)    ; LVOSetTaskPri (d0=priority, a1=task)

MOVE.L    GfxBase(PC),A6
jsr    -$1c8(a6)    ; OwnBlitter, which gives us exclusive access to the blitter
; preventing its use by the operating system.
jsr    -$E4(A6)	; WaitBlit - Waits for the end of each blitter
JSR    -$E4(A6)    ; WaitBlit

move.l    4.w,a6        ; ExecBase in A6
JSR    -$84(a6)    ; FORBID - Disables multitasking
JSR    -$78(A6)    ; DISABLE - Also disables operating system interrupts
;

bsr.w    HEAVYINIT    ; Now you can execute the part that operates
; on the hardware registers

move.l    4.w,a6        ; ExecBase in A6
JSR    -$7E(A6)    ; ENABLE - Enables System Interrupts
JSR    -$8A(A6)    ; PERMIT - Enable multitasking

move.l    thistask(PC),a1    ; Task in a1
MOVE.L    pr_Win(PC),$B8(A1) ; restore the window address
MOVEQ    #0,D0		 ; Priority in d0 (-128, +127) - NORMAL
JSR    -$12C(A6)     ; LVOSetTaskPri (d0=priority, a1=task)

MOVE.L    GfxBase(PC),A6    ; GfxBase in A6
jsr    -$E4(A6)    ; Wait for the end of any blitting
JSR    -$E4(A6)    ; WaitBlit
jsr    -$1ce(a6)    ; DisOwnBlitter, the operating system can now
; use the blitter again

MOVE.L    IntuiBase(PC),A0
CMP.W    #39,$14(A0)    ; V39+?
BLT.s    Very old
BSR.w    RestoreSprites
Very old:

; Restore Color0

MOVE.L    GfxBase(PC),A6    ; GfxBase in A6
move.l    VPfirstScreen(PC),a0
LEA    Savedcolour0(PC),A1 ; original colour0
MOVEQ    #1,D0        ; count - only the background colour to be changed
MOVE.L    GfxBase(PC),A6
JSR    -$C0(a6)    ; LoadRGB4 - old colour0

MOVE.L    WBVIEW(PC),A1    ; Old WBVIEW in A1
JSR    -$DE(A6)    ; loadview - restore the old View
JSR    -$10E(A6)    ; WaitOf (Reset any interlace)
JSR    -$10E(A6)    ; WaitOf
MOVE.W    #$11,$DFF10C    ; This does not restore it by itself..!
MOVE.L    $26(a6),$dff080    ; COP1LC - Point to the old system copper1
MOVE.L    $32(a6),$dff084    ; COP2LC - Point to the old system copper2

bsr.w    InputOn        ; Restore intuition input

MOVE.L    IntuiBase(PC),A6
JSR    -$186(A6)    ; _LVORethinkDisplay - Redraw the entire
; display, including ViewPorts and any
; interlace or multisync modes.
MOVE.L    A6,A1        ; IntuiBase in a1 to close the library
move.l    4.w,a6        ; ExecBase in A6
jsr    -$19E(a6)    ; CloseLibrary - intuition.library CLOSED
EXIT1:
MOVE.L	GfxBase(PC),A1    ; GfxBase in A1 to close the library
jsr    -$19E(a6)    ; CloseLibrary - graphics.library CLOSED
EXIT2:
MOVE.L    DosBase(PC),A1    ; DosBase in A1 to close the library
jsr    -$19E(a6)    ; CloseLibrary - dos.library CLOSED
EXIT3:
movem.l    (SP)+,d0-d7/a0-a6 ; Restore the old register values
RTS             ; Return to ASMONE or Dos/WorkBench

pr_Win:
dc.l    0
colore0:
dc.w    $012
SavedColor0:
dc.w	0
VPfirstScreen:
dc.l	0
ThisTask:
dc.l	0
*******************************************************************************
;	Resetta la risoluzione degli sprite ‘legalmente’
*******************************************************************************

ResettaSpritesV39:
MOVE.L	IntuiBase(PC),A6
LEA    Workbench(PC),A0 ; Workbench screen name (for lock) in a0
JSR    -$1FE(A6)    ; _LVOLockPubScreen - ‘lock’ the screen
; (whose name is in a0).
MOVE.L    D0,LockedScreen
BEQ.s	ScreenError
MOVE.L    D0,A0        ; Screen structure in a0
MOVE.L    $30(A0),A0    ; sc_ViewPort+vp_ColorMap: in a0 we now have
; the screen's ColorMap structure, which we
; need (in a0) to execute a ‘video_control’
; of the graphics.library.
LEA    GETVidCtrlTags(PC),A1    ; In a1, the TagList for the routine
; ‘Video_control’ - the request
; we make to this routine is
; VTAG_SPRITERESN_GET, i.e. to know
; the current resolution of the sprites.
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; Video_Control (in a0 the cm and in a1 the tags)
; returns to the taglist, in the long
; ‘resolution’, the current resolution of the
; sprites on that screen.

; Now we also save the resolution of any ‘foreground’ screen,
; for example, the assembler screen:

MOVE.L    IntuiBase(PC),A6
move.l    $3c(a6),a0    ; Ib_FirstScreen (Screen in ‘foreground!’)
MOVE.L    $30(A0),A0    ; structure sc_ViewPort+vp_ColorMap in a0
LEA    GETVidCtrlTags2(PC),A1    ; In a1 the TagList GET
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; Video_Control (in a0 the cm and in a1 the tags)

; Now we ask the VideoControl routine to set the resolution.
; SPRITERESN_140NS -> i.e. lowres!

MOVE.L    SchermoWBLocckato(PC),A0
MOVE.L    $30(A0),A0    ; structure sc_ViewPort+vp_ColorMap in a0
LEA    SETVidCtrlTags(PC),A1    ; TagList that resets the sprites.
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; video_control... resets the sprites!

move.L    IntuiBase(PC),A6
move.l    $3c(a6),a0    ; Ib_FirstScreen - ‘fishes’ the screen in
; foreground (e.g. ASMONE)
move.L    $30(A0),A0    ; structure sc_ViewPort+vp_ColorMap in a0
LEA    SETVidCtrlTags(PC),A1    ; TagList that resets the sprites.
move.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; video_control... resets the sprites!

move.L    SchermoWBLocckato(PC),A0
move.L    IntuiBase(PC),A6
JSR    -$17A(A6)    ; _LVOMakeScreen - the screen must be redrawn
move.l    $3c(a6),a0    ; Ib_FirstScreen - ‘fishes’ the screen in
; the foreground (e.g. ASMONE)
JSR    -$17A(A6)    ; _LVOMakeScreen - the screen must be redrawn
; to ensure reset: i.e.
; call MakeScreen, followed by...
JSR    -$186(A6)    ; _LVORethinkDisplay - which redraws the entire
; display, including ViewPorts and any
ScreenError:            ; interlace or multisync modes.
RTS

; Now we need to reset the sprites to the starting resolution.

ResetSprites:
MOVE.L    ScreenWBLocked(PC),D0 ; Screen structure address
BEQ.S    DidNotWork     ; If = 0, then too bad...
MOVE.L    D0,A0
MOVE.L    OldResolution(PC),OldResolution2 ; Restore old resolution.
LEA    SETOldVidCtrlTags(PC),A1
MOVE.L    $30(A0),A0    ; Screen ColorMap structure
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; _LVOVideoControl - Reset resolution

; Now the foreground screen (if any)...

MOVE.L    IntuiBase(PC),A6
move.l    $3c(a6),a0    ; Ib_FirstScreen - ‘fishes’ the screen in
; foreground (e.g. ASMONE)
MOVE.L    OldResolutionP(PC),OldResolution2 ; Restore old resolution.
LEA    SETOldVidCtrlTags(PC),A1
MOVE.L    $30(A0),A0    ; Screen ColorMap structure
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; _LVOVideoControl - Reset resolution

move.L    IntuiBase(PC),A6
move.L    ScreenWBLocked(PC),A0
JSR    -$17A(A6)    ; RethinkDisplay - ‘rethink’ the display
move.l    $3c(a6),a0    ; Ib_FirstScreen - screen in foreground
JSR    -$17A(A6)    ; RethinkDisplay - ‘rethink’ the display
MOVE.L	ScreenWBLocked(PC),A1
SUB.L    A0,A0        ; null
move.L    IntuiBase(PC),A6
JSR    -$204(A6)    ; _LVOUnlockPubScreen - and ‘unlock’ the
DidNotWork:        ; workbench screen.
RTS

LockedScreen:
dc.l    0

; This is the structure for using Video_Control. The first long is used to
; CHANGE (SET) the sprite resolution or to find out (GET) the old one.

GETVidCtrlTags:
dc.l    $80000032    ; GET
OldResolution:
dc.l    0    ; Sprite resolution: 0=ECS, 1=lowres, 2=hires, 3=shres
dc.l    0,0,0    ; 3 zeros for TAG_DONE (end the TagList)

GETVidCtrlTags2:
dc.l    $80000032    ; GET
OldResolutionP:
dc.l    0    ; Sprite resolution: 0=ECS, 1=lowres, 2=hires, 3=shres
dc.l    0,0,0    ; 3 zeros for TAG_DONE (end the TagList)

SETVidCtrlTags:
dc.l    $80000031    ; SET
dc.l    1    ; Sprite resolution: 0=ECS, 1=lowres, 2=hires, 3=shres
dc.l    0,0,0	
; 3 zeros for TAG_DONE (end TagList)

SETOldVidCtrlTags:
dc.l    $80000031    ; SET
OldResolution2:
dc.l    0    ; Sprite resolution: 0=ECS, 1=lowres, 2=hires, 3=shres
dc.l    0,0,0    ; 3 zeros for TAG_DONE (terminate TagList)

; WorkBench screen name

Workbench:
dc.b    “Workbench”,0

; *****************************************************************************
; THIS ROUTINE BLOCKS INTUITION BY CREATING A MESSAGE-PORT AT A LEVEL
; HIGHER THAN THAT OF INTUITION, SO THAT ALL MESSAGES
; RELATED TO INTUITION ARE SENT TO THIS MESSAGE-PORT (DOING NOTHING).
; *****************************************************************************

InputOFF:
LEA    INPUTMPORT(PC),A1    ; port to create
BSR.w    CREATEPORT
CMP.L    #-1,D0
BEQ.w    INTUIERROR
MOVE.L    #INPUTMPORT,inputioST    ; MN_REPLYPORT+inputio
LEA    INPUTDEVICE(PC),A0    ; DevName: input.device
MOVEQ    #0,D0            ; Unit Number
LEA    INPUTIO(PC),A1        ; iORequest block to initialise
MOVEQ    #0,D1            ; flags: none
MOVE.L    4.w,A6
JSR    -$1BC(A6)        ; OpenDevice - initialise inputio
TST.L    D0            ; If d0=0, no error
BNE.S    INTUITIONON1        ; Otherwise, exit in despair

; Now our input handler must have higher priority than
; intuition, which has priority 50. Just set the priority to 51!

MOVE.B    #51,LN_PRI     ; Priority of our input handler = 51
CLR.L    IS_DATA         ; IS_DATA of the input handler = 0
MOVE.L    #READINPUT,IS_CODE ; As code, only moveq #0,d0 & rts.
MOVE.W	#9,IO_COMMAND     ; command: ND_ADDHANDLER
MOVE.L    #INPUTHANDLER,IO_DATA
LEA    INPUTIO(PC),A1    ; iOrequest
MOVE.L    4.w,A6
JSR    -$1C8(A6)    ; DoIo
RTS

; Routine that we put in our input handler... doesn't do much, eh!?

READINPUT:
MOVEQ    #0,D0        ; we don't pass input to Intuition
RTS

; *****************************************************************************
; Routine that restores Intuition input/output
; *****************************************************************************

InputON:
TST.B    InputErrFlag    ; error in InputOFF?
BNE.S    ExitInputON	; if so, nothing to do here
MOVE.W    #10,IO_COMMAND    ; command: IND_REMHANDLER (remove handler)
MOVE.L    #INPUTHANDLER,IO_DATA
LEA    INPUTIO(PC),A1    ; iORequest
MOVE.L    4.w,A6
JSR    -$1C8(A6)    ; DoIo
LEA    INPUTIO(PC),A1    ; iORequest
MOVE.L    4.w,A6
JSR    -$1C2(A6)    ; CloseDevice
INTUITIONON1:
LEA    INPUTMPORT(PC),A1
BSR.s    FREEUPPORT
INTUIERROR:
MOVE.B    #$FF,InputErrFlag    ; marks the error
ExitInputON:
RTS

InputErrFlag:
dc.w    0

; a1=address of port. If d0=-1, then there is an error

CREATEPORT:
MOVE.L    A1,-(SP)
MOVEQ    #-1,D0        ; SignalNum -1 (any)
MOVE.L    4.w,A6
JSR    -$14A(A6)    ; AllocSignal
MOVEQ    #-1,D1
CMP.L    D1,D0        ; Error?
BEQ.S    FREEUPPORT1
MOVE.L    (SP),A0        ; Port in a0
MOVE.B    #0,9(A0)    ; LN_PRI
MOVE.B    #4,8(A0)	; NT_MSGPORT, LN_TYPE
MOVE.B    #0,14(A0)    ; PA_SIGNAL, MP_FLAGS
MOVE.B    D0,15(A0)    ; MP_SIGBIT
SUBA.L    A1,A1
MOVE.L    4.w,A6
JSR    -$126(A6)    ; FindTask (find this task)
MOVE.L    (SP),A1
MOVE.L    D0,$10(A1)    ; d0,MP_SIGTASK
LEA    $14(A1),A0    ; MP_MSGLIST,a0
MOVE.L    A0,(A0)        ; NEWLIST a0
ADDQ.L	#4,(A0)        ; 
CLR.L    4(A0)        ;
MOVE.L    A0,8(A0)    ;
CREATEPORTEXIT:
MOVE.L    (SP)+,D0
RTS

; a1=address of port

FREEUPPORT:
MOVE.L    A1,-(SP)
MOVE.B    15(A1),D0    ; MP_SIGBIT,d0 (SignalNum)
MOVE.L    4.w,A6
JSR    -$150(A6)    ; FreeSignal
FREEUPPORT1:
MOVE.L    (SP)+,A1
RTS

INPUTMPORT:
ds.b    34    ; MP_SIZE

INPUTIO:
ds.b    14
inputioST:
ds.b    14
IO_COMMAND:
ds.b    12
IO_DATA:
ds.b    8

INPUTHANDLER:
ds.b    9
LN_PRI:
ds.b    5
IS_DATA:
dc.l    0
IS_CODE:
dc.l    0

INPUTDEVICE:
dc.b    “input.device”,0,0

******************************************************************************
;    From here onwards, you can operate directly on the hardware
******************************************************************************

HEAVYINIT:
LEA    $DFF000,A5        ; Base of CUSTOM registers for Offsets
MOVE.W    $2(A5),OLDDMA        ; Save the old DMACON status
MOVE.W    $1C(A5),OLDINTENA    ; Save the old INTENA status
MOVE.W    $10(A5),OLDADKCON    ; Save the old ADKCON status
MOVE.W	$1E(A5),OLDINTREQ    ; Save the old status of INTREQ
MOVE.L    #$80008000,d0        ; Prepare the mask of the high bits
; to be set in the words where
; the registers were saved
OR.L    d0,OLDDMA    ; Set bit 15 of all saved values
OR.L    d0,OLDADKCON    ; of the hardware registers, essential for
; putting these values back into the registers.

MOVE.L    #$7FFF7FFF,$9A(a5)    ; DISABLE INTERRUPTS & INTREQS
MOVE.L    #0,$144(A5)        ; SPR0DAT - kill the pointer!
MOVE.W    #$7FFF,$96(a5)        ; DISABLE DMA
MOVE.L    #0,$144(A5)

move.l    4.w,a6        ; ExecBase in a6
btst.b    #0,$129(a6)    ; Check if we are on a 68010 or higher
beq.s    IntOK        ; It's a 68000! So the base is always zero.
lea    SuperCode(PC),a5 ; Routine to be executed in supervisor
jsr    -$1e(a6)    ; LvoSupervisor - execute the routine
bra.s    IntOK        ; We have the VBR value, let's continue...

;**********************SUPERVISOR CODE for 68010+ **********************
SuperCode:
dc.l     $4e7a9801    ; Movec Vbr,A1 (instruction 68010+).
; It is in hexadecimal because not all
; assemblers assemble movec.
move.l    a1,BaseVBR	; Label where to save the VBR value
RTE            ; Return from exception
;*****************************************************************************

BaseVBR:        ; If not modified, it remains zero! (for 68000).
dc.l    0

IntOK:
move.l    BaseVBR(PC),a0     ; In a0 the value of VBR
move.l    $64(a0),OldInt64 ; Sys int liv 1 saved (softint,dskblk)
move.l    $68(a0),OldInt68 ; Sys int liv 2 saved (I/O,ciaa,int2)
move.l    $6c(a0),OldInt6c ; Sys int liv 3 saved (coper,vblanc,blit)
move.l    $70(a0),OldInt70 ; Sys int liv 4 saved (audio)
move.l	$74(a0),OldInt74 ; Sys int liv 5 saved (rbf,dsksync)
move.l    $78(a0),OldInt78 ; Sys int liv 6 saved (exter,ciab,inten)

bsr.w    ClearMyCache

lea    $dff000,a5    ; Custom register in a5
bsr.w	START        ; Run the programme.

bsr.w    ClearMyCache

LEA    $dff000,a5    ; Custom base for offsets
MOVE.W    #$8240,$96(a5)    ; dmacon - enable blit
BTST.b    #6,2(a5)    ; WaitBlit via hardware...
Wblittez:
BTST.b    #6,2(a5)
BNE.S    Wblittez

MOVE.W    #$7FFF,$96(A5)        ; DISABLE ALL DMAs
MOVE.L    #$7FFF7FFF,$9A(A5)	; DISABLE INTERRUPTS & INTREQS
MOVE.W    #$7fff,$9E(a5)        ; Disable ADKCON bits

move.l    BaseVBR(PC),a0     ; In a0, the value of VBR
move.l    OldInt64(PC),$64(a0) ; Sys int liv1 saved (softint,dskblk)
move.l    OldInt68(PC),$68(a0) ; Sys int liv2 saved (I/O,ciaa,int2)
move.l    OldInt6c(PC),$6c(a0) ; Sys int liv3 saved (coper,vblanc,blit)
move.l    OldInt70(PC),$70(a0) ; Sys int liv4 saved (audio)
move.l    OldInt74(PC),$74(a0) ; Sys int liv5 saved (rbf,dsksync)
move.l    OldInt78(PC),$78(a0) ; Sys int liv6 saved (exter,ciab,inten)

MOVE.W    OLDADKCON(PC),$9E(A5)    ; ADKCON
MOVE.W    OLDDMA(PC),$96(A5)	; Restore old DMA status
MOVE.W    OLDINTENA(PC),$9A(A5)    ; INTENA STATUS
MOVE.W    OLDINTREQ(PC),$9C(A5)    ; INTREQ
RTS

;    Data saved from startup

WBVIEW:            ; WorkBench View address
DC.L	0
GfxName:
dc.b    “graphics.library”,0,0
IntuiName:
dc.b    “intuition.library”,0
DosName:
dc.b    ‘dos.library’,0
GfxBase:        ; Pointer to the Graphics Library Base
dc.l    0
IntuiBase:        ; Pointer to the base of the Intuition Library
dc.l    0
DosBase:        ; Pointer to the base of the Dos Library
dc.l    0
OLDDMA:            ; Old DMACON status
dc.w    0
OLDINTENA:        ; Old INTENA status
dc.w    0
OLDADKCON:        ; Old ADKCON status
DC.W    0
OLDINTREQ:        ; Old INTREQ status
DC.W    0

; Old system interrupts

OldInt64:
dc.l    0
OldInt68:
dc.l    0
OldInt6c:
dc.l    0
OldInt70:
dc.l    0
OldInt74:
dc.l	0
OldInt78:
dc.l    0

; Routine to call in case of self-modifying code, modification of tables
; in fast RAM, loading from disk, etc.

ClearMyCache:
movem.l    d0-d7/a0-a6,-(SP)
move.l    4.w,a6
MOVE.W    $14(A6),D0    ; lib version
CMP.W    #37,D0        ; is it V37+? (kick 2.0+)
blo.s    nocaches    ; If kick1.3, the problem is that it can't
; even know if it's a 68040, so
; it's risky... and hopefully some
; idiot who has a 68020+ on a kick1.3
; also has the caches disabled!
jsr    -$27c(a6)    ; cache cleaR U (for load, modifications, etc.)
nocaches:
movem.l    (sp)+,d0-d7/a0-a6
rts

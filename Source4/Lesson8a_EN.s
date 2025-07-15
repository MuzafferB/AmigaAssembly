
; Lesson 8a.s - The universal startup, to study DMA channels

; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper and bitplane DMA enabled
;		 -----a-bcdefghij

;    a: Blitter Nasty (Not relevant for now, leave it at zero)
;    b: Bitplane DMA     (If not set, sprites will also disappear)
;    c: Copper DMA     (If set to zero, the copperlist will not be executed)
;    d: Blitter DMA     (Not important for now, let's set it to zero)
;    e: Sprite DMA     (Setting it to zero only makes the 8 sprites disappear)
;    f: Disk DMA     (Not important for now, let's set it to zero)
;    g-j: Audio 3-0 DMA (Let's set it to zero to mute the Amiga)

******************************************************************************
; 680X0 & AGA STARTUP BY FABIO CIUCCI - Complexity level 1
******************************************************************************

MAINCODE:
movem.l    d0-d7/a0-a6,-(SP)    ; Save the registers to the stack
move.l    4.w,a6            ; ExecBase in a6
LEA    GfxName(PC),A1        ; Name of library to open
JSR    -$198(A6)        ; OldOpenLibrary - open the lib
MOVE.L    d0,GFXBASE        ; Save GfxBase in a label
BEQ.w    EXIT2            ; If yes, exit without executing the code
LEA    IntuiName(PC),A1    ; Intuition.lib
JSR    -$198(A6)        ; Openlib
MOVE.L    D0,IntuiBase
BEQ.w    EXIT1            ; If zero, exit! Error!

MOVE.L    IntuiBase(PC),A0
CMP.W    #39,$14(A0)    ; version 39 or higher? (kick3.0+)
BLT.s    OldIntui
BSR.w    ResetSpritesV39
OldIntui:

MOVE.L    GfxBase(PC),A6
MOVE.L    $22(A6),WBVIEW    ; Save the current system WBView

SUBA.L    A1,A1        ; Null view to reset the video mode
JSR    -$DE(A6)    ; Load null View - video mode reset
SUBA.L    A1,A1        ; Null View
JSR    -$DE(A6)	; LoadView (twice for safety...)
JSR    -$10E(A6)    ; WaitOf ( These two calls to WaitOf )
JSR    -$10E(A6)    ; WaitOf ( are used to reset the interlace )
JSR    -$10E(A6)    ; Two more, come on!
JSR    -$10E(A6)

MOVEA.L    4.w,A6
SUBA.L    A1,A1        ; NULL task - find this task
JSR    -$126(A6)    ; findtask (d0=task, FindTask(name) in a1)
MOVEA.L    D0,A1        ; Task in a1
MOVEQ    #127,D0        ; Priority in d0 (-128, +127) - MAXIMUM!
JSR    -$12C(A6)    ;_LVOSetTaskPri (d0=priority, a1=task)

MOVE.L    GfxBase(PC),A6
jsr    -$1c8(a6)    ; OwnBlitter, which gives us exclusive access to the blitter
; preventing its use by the operating system.
jsr    -$E4(A6)    ; WaitBlit - Waits for the end of each blit
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

SUBA.L    A1,A1        ; NULL task - find this task
JSR    -$126(A6)    ; findtask (d0=task, FindTask(name) in a1)
MOVEA.L	D0,A1        ; Task in a1
MOVEQ    #0,D0        ; Priority in d0 (-128, +127) - NORMAL
JSR    -$12C(A6)    ;_LVOSetTaskPri (d0=priority, a1=task)

MOVE.W    #$8040,$DFF096    ; enable blit
BTST.b    #6,$dff002    ; WaitBlit...
Wblittez:
BTST.b    #6,$dff002
BNE.S    Wblittez

MOVE.L	GFXBASE(PC),A6    ; GFXBASE in A6
jsr    -$E4(A6)    ; Wait for the end of any blitting
JSR    -$E4(A6)    ; WaitBlit
jsr    -$1ce(a6)    ; DisOwnBlitter, the operating system can now
; use the blitter again
MOVE.L    IntuiBase(PC),A0
CMP.W    #39,$14(A0)    ; V39+?
BLT.s    Very old
BSR.w    PutSpritesBack
Very old:

MOVE.L    GFXBASE(PC),A6    ; GFXBASE in A6
MOVE.L	$26(a6),$dff080    ; COP1LC - Point to the old system copper1
MOVE.L    $32(a6),$dff084    ; COP2LC - Point to the old system copper2
JSR    -$10E(A6)    ; WaitOf ( Reset any interlace)
JSR    -$10E(A6)    ; WaitOf
MOVE.L    WBVIEW(PC),A1    ; Old WBVIEW in A1
JSR    -$DE(A6)    ; loadview - restore the old View
JSR    -$10E(A6)    ; WaitOf ( Reset any interlace)
JSR    -$10E(A6)	; WaitOf
MOVE.W    #$11,$DFF10C    ; This does not restore it by itself..!
MOVE.L    $26(a6),$dff080    ; COP1LC - Point to the old system copper1
MOVE.L    $32(a6),$dff084    ; COP2LC - Points to the old system copper2
moveq    #100,d7
RipuntLoop:
MOVE.L    $26(a6),$dff080    ; COP1LC - Points to the old system copper1
move.w    d0,$dff088
dbra    d7,RipuntLoop    ; Just to be safe...

MOVEA.L    IntuiBase(PC),A6
JSR    -$186(A6)    ; _LVORethinkDisplay - Redraw the entire
; display, including ViewPorts and any
; interlace or multisync modes.
MOVE.L    a6,A1        ; IntuiBase in a1 to close the library
move.l    4.w,a6		; ExecBase in A6
jsr    -$19E(a6)    ; CloseLibrary - intuition.library CLOSED
Exit1:
MOVE.L	GfxBase(PC),A1    ; GfxBase in a1 to close the library
jsr    -$19E(a6)    ; CloseLibrary - graphics.library CLOSED
Exit2:
movem.l    (SP)+,d0-d7/a0-a6 ; Restore the old register values
RTS			 ; Torna all'ASMONE o al Dos/WorkBench

*******************************************************************************
;	Resetta la risoluzione degli sprite ‘legalmente’
*******************************************************************************

ResettaSpritesV39:
LEA    Workbench(PC),A0 ; Workbench screen name in a0
MOVE.L    IntuiBase(PC),A6
JSR    -$1FE(A6)    ; _LVOLockPubScreen - ‘lock’ the screen
; (whose name is in a0).
MOVE.L    D0,LockedScreen
BEQ.s    ScreenError
MOVE.L    D0,A0        ; Screen structure in a0
MOVE.L    $30(A0),A0    ; sc_ViewPort+vp_ColorMap: in a0 we now have
; the ColorMap structure of the screen, which we
; need (in a0) to execute a ‘video_control’
; of the graphics.library.
LEA    GETVidCtrlTags(PC),A1    ; In a1 the TagList for the routine
; ‘Video_control’ - the request we
; make to this routine is
; VTAG_SPRITERESN_GET, i.e. to know
; the current resolution of the sprites.
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; Video_Control (in a0 the cm and in a1 the tags)
; returns to the taglist, in the long
; ‘resolution’, the current resolution of the
; sprites on that screen.

; Now we ask the VideoControl routine to set the resolution.
; SPRITERESN_140NS -> i.e. lowres!

MOVE.L    SchermoWBLocckato(PC),A0
MOVE.L    $30(A0),A0    ; structure sc_ViewPort+vp_ColorMap in a0
LEA    SETVidCtrlTags(PC),A1    ; TagList that resets the sprites.
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; video_control... resets the sprites!

; Now we also reset any ‘foreground’ screen, for example the
; assembler screen:

MOVE.L    IntuiBase(PC),A6
move.l    $3c(a6),a0    ; Ib_FirstScreen (Screen in ‘foreground!’)
MOVE.L    $30(A0),A0    ; structure sc_ViewPort+vp_ColorMap in a0
LEA    GETVidCtrlTags2(PC),A1    ; In a1 the TagList GET
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; Video_Control (in a0 the cm and in a1 the tags)

MOVEA.L    IntuiBase(PC),A6
move.l    $3c(a6),a0    ; Ib_FirstScreen - ‘fishes’ the screen in
; foreground (e.g. ASMONE)
MOVEA.L    $30(A0),A0    ; structure sc_ViewPort+vp_ColorMap in a0
LEA	SETVidCtrlTags(PC),A1    ; TagList that resets the sprites.
MOVEA.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; video_control... resets the sprites!

MOVEA.L    SchermoWBLocckato(PC),A0
MOVEA.L    IntuiBase(PC),A6
JSR    -$17A(A6)    ; _LVOMakeScreen - the screen must be redrawn
move.l    $3c(a6),a0    ; Ib_FirstScreen - ‘fishes’ the screen in
; the foreground (e.g. ASMONE)
JSR    -$17A(A6)	; _LVOMakeScreen - the screen must be redrawn
; to be sure of the reset: i.e.
; call MakeScreen, followed by...
JSR    -$186(A6)    ; _LVORethinkDisplay - which redraws the entire
; display, including ViewPorts and any
ErroreSchermo:            ; interlace or multisync modes.
RTS

; Now we need to reset the sprites to the starting resolution.

RimettiSprites:
MOVE.L    SchermoWBLocckato(PC),D0 ; Screen structure address
BEQ.S    NonAvevaFunzionato     ; If = 0, then too bad...
MOVE.L    D0,A0
MOVE.L    OldResolution(PC),OldResolution2 ; Reset old resolution.
LEA    SETOldVidCtrlTags(PC),A1
MOVE.L    $30(A0),A0    ; Screen ColorMap structure
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; _LVOVideoControl - Reset resolution

; Now the foreground screen (if any)...

MOVE.L    IntuiBase(PC),A6
move.l    $3c(a6),a0    ; Ib_FirstScreen - ‘fishes’ the foreground screen
(e.g. ASMONE)
MOVE.L    OldResolutionP(PC),OldResolution2 ; Restore old resolution.
LEA    SETOldVidCtrlTags(PC),A1
MOVE.L    $30(A0),A0    ; Screen ColorMap structure
MOVE.L    GfxBase(PC),A6
JSR    -$2C4(A6)    ; _LVOVideoControl - Reset resolution

MOVEA.L    SchermoWBLocckato(PC),A0
MOVEA.L    IntuiBase(PC),A6
JSR    -$17A(A6)    ; RethinkDisplay - ‘rethink’ the display
move.l    $3c(a6),a0    ; Ib_FirstScreen - screen in foreground
JSR    -$17A(A6)    ; RethinkDisplay - ‘rethink’ the display
MOVE.L    ScreenWBLocked(PC),A1
SUB.L    A0,A0        ; null
MOVEA.L    IntuiBase(PC),A6
JSR    -$204(A6)    ; _LVOUnlockPubScreen - and ‘unlock’ the
NonAvevaFunzionato:        ; workbench screen.
RTS

SchermoWBLocckato:
dc.l    0

; This is the structure for using Video_Control. The first long is used to
; CHANGE (SET) the resolution of the sprites or to find out (GET) the old one.

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
dc.l    0,0,0    ; 3 zeros for TAG_DONE (end TagList)

SETOldVidCtrlTags:
dc.l    $80000031    ; SET
OldResolution2:
dc.l    0    ; Sprite resolution: 0=ECS, 1=lowres, 2=hires, 3=shres
dc.l    0,0,0    ; 3 zeros for TAG_DONE (end the TagList)

; WorkBench screen name

Workbench:
dc.b    “Workbench”,0

******************************************************************************
;    From here onwards, you can operate directly on the hardware
******************************************************************************

HEAVYINIT:
LEA    $DFF000,A5        ; Base of CUSTOM registers for Offsets
MOVE.W    $2(A5),OLDDMA        ; Save the old DMACON status
MOVE.W    $1C(A5),OLDINTENA	; Save the old status of INTENA
MOVE.W    $10(A5),OLDADKCON    ; Save the old status of ADKCON
MOVE.W    $1E(A5),OLDINTREQ    ; Save the old status of INTREQ
MOVE.L	#80008000,d0        ; Prepare the high bit mask
; to be set in the words where
; the registers were saved
OR.L    d0,OLDDMA    ; Set bit 15 of all saved values
OR.L    d0,OLDADKCON    ; of the hardware registers, essential for
; putting these values back into the registers.

MOVE.L    #$7FFF7FFF,$9A(a5)    ; DISABLE INTERRUPTS & INTREQS
MOVE.L    #0,$144(A5)        ; SPR0DAT - kill the pointer!
MOVE.W    #$7FFF,$96(a5)		; DISABLE DMA

bsr.s    START            ; Run the program.

LEA    $dff000,a5        ; Custom base for offsets
MOVE.W    #$7FFF,$96(A5)        ; DISABLE ALL DMA
MOVE.L    #$7FFF7FFF,$9A(A5)    ; DISABLE INTERRUPTS & INTREQS
MOVE.W    #$7fff,$9E(a5)        ; Disable ADKCON bits
MOVE.W    OLDADKCON(PC),$9E(A5)    ; ADKCON 
MOVE.W    OLDDMA(PC),$96(A5)    ; Restore old DMA status
MOVE.W    OLDINTENA(PC),$9A(A5)    ; INTENA STATUS
MOVE.W    OLDINTREQ(PC),$9C(A5)    ; INTREQ
RTS

;    Data saved from startup

WBVIEW:            ; WorkBench View address
DC.L    0
GfxName:
dc.b    “graphics.library”,0,0
IntuiName:
dc.b    “intuition.library”,0

GfxBase:        ; Pointer to the Graphics Library Base
dc.l    0
IntuiBase:        ; Pointer to the base of the Intuition Library
dc.l    0
OLDDMA:            ; Old DMACON status
dc.w    0
OLDINTENA:        ; Old INTENA status
dc.w    0
OLDADKCON:        ; Old ADKCON status
DC.W    0
OLDINTREQ:		; Old INTREQ status
DC.W    0

START:
;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane and copper

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
btst    #6,$bfe001
bne.s    mouse
rts


Section    CopProva,data_C

COPPERLIST:
dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane LOWRES 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$19a    ; colour1 - TEXT

;    copperlist shading

dc.w    $5007,$fffe    ; WAIT line $50
dc.w    $180,$001    ; colour0
dc.w    $5207,$fffe    ; WAIT line $52
dc.w    $180,$002    ; colour0
dc.w    $5407,$fffe    ; WAIT line $54
dc.w    $180,$003    ; colour0
dc.w    $5607,$fffe    ; WAIT line $56
dc.w    $180,$004    ; colour0
dc.w    $5807,$fffe    ; WAIT line $58
dc.w    $180,$005    ; colour0
dc.w    $5a07,$fffe    ; WAIT line $5a
dc.w    $180,$006    ; colour0
dc.w    $5c07,$fffe    ; WAIT line $5c
dc.w    $180,$007    ; colour0
dc.w    $5e07,$fffe    ; WAIT line $5e
dc.w    $180,$008    ; colour0
dc.w    $6007,$fffe    ; WAIT line $60
dc.w    $180,$009    ; colour0
dc.w    $6207,$fffe    ; WAIT line $62
dc.w    $180,$00a    ; colour0

dc.w    $FFFF,$FFFE    ; End of copperlist

;    With the dcb command, we draw a random pattern for the bitplane

BITPLANE:
dcb.l    10240/4,$FF00FF00

end

There are two details that are not included in the lesson: the first is that there is
a routine that resets the video mode of the sprites, in case the kickstart is
3.0 or higher.
The second detail is that an instruction has been added to those
already present to disable AGA:

move.w    #$11,$10c(a5)		; Disable AGA

In reality, this instruction is also almost superfluous, because it is almost never
out of place, but here too, safety should not be neglected.

Try turning off the dma channels of the bitplanes and copper, one by one.
You will notice that turning off only the bitplane channel makes the bar pattern disappear,
 and disabling the copper also removes the shading.
Try also disabling only bit 9, the general switch, and you will see
that even if the other bits are enabled, everything turns off.
There is no point in trying to reset bit 15!
